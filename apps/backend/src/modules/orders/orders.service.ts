import {
  BadRequestException,
  ForbiddenException,
  Injectable,
  NotFoundException,
} from '@nestjs/common';
import {
  FulfillmentType,
  NotificationType,
  OrderItemAvailability,
  OrderStatus,
  PaymentMethod,
  PaymentStatus,
  Prisma,
} from '@prisma/client';
import { PrismaService } from '@/prisma/prisma.service';
import { InventoryService } from '@/modules/inventory/inventory.service';
import { DeliveryService } from '@/modules/delivery/delivery.service';
import { NotificationsService } from '@/modules/notifications/notifications.service';
import { paginate } from '@/common/dto/pagination.dto';
import { AuthUser } from '@/common/decorators/current-user.decorator';
import { canTransition } from './order-state-machine';
import {
  AdvanceStatusDto,
  CheckoutDto,
  QueryOrdersDto,
  RejectOrderDto,
  RequestConfirmationDto,
} from './dto/order.dto';

const ORDER_INCLUDE = {
  items: true,
  address: true,
  statusHistory: { orderBy: { createdAt: 'asc' } },
  user: { select: { id: true, fullName: true, phone: true, email: true } },
} satisfies Prisma.OrderInclude;

function effectivePrice(price: Prisma.Decimal, discount: Prisma.Decimal | null): number {
  const p = Number(price);
  const d = discount == null ? null : Number(discount);
  return d != null && d > 0 && d < p ? d : p;
}

@Injectable()
export class OrdersService {
  constructor(
    private readonly prisma: PrismaService,
    private readonly inventory: InventoryService,
    private readonly delivery: DeliveryService,
    private readonly notifications: NotificationsService,
  ) {}

  // ── Checkout ────────────────────────────────────────────────────────────
  async checkout(userId: string, dto: CheckoutDto) {
    const cartItems = await this.prisma.cartItem.findMany({
      where: { userId },
      include: { product: true },
    });
    if (cartItems.length === 0) throw new BadRequestException('Cart is empty');

    for (const ci of cartItems) {
      if (!ci.product.isActive) {
        throw new BadRequestException(`"${ci.product.nameAr}" is no longer available`);
      }
    }

    let deliveryFee = 0;
    let distanceMeters: number | null = null;
    let etaMinutes: number | null = null;
    let addressId: string | null = null;

    if (dto.fulfillmentType === FulfillmentType.DELIVERY) {
      const address = await this.prisma.address.findFirst({
        where: { id: dto.addressId, userId },
      });
      if (!address) throw new BadRequestException('Delivery address not found');
      const quote = await this.delivery.quote(address.latitude, address.longitude);
      if (!quote.withinRange) {
        throw new BadRequestException('Delivery address is outside the delivery range');
      }
      deliveryFee = quote.fee;
      distanceMeters = quote.distanceMeters;
      etaMinutes = quote.etaMinutes;
      addressId = address.id;
    }

    const items = cartItems.map((ci) => {
      const unitPrice = effectivePrice(ci.product.price, ci.product.discountPrice);
      return {
        productId: ci.productId,
        nameAr: ci.product.nameAr,
        nameEn: ci.product.nameEn,
        unitPrice: new Prisma.Decimal(unitPrice),
        quantity: ci.quantity,
        lineTotal: new Prisma.Decimal(+(unitPrice * ci.quantity).toFixed(2)),
      };
    });
    const subtotal = items.reduce((sum, i) => sum + Number(i.lineTotal), 0);
    const total = +(subtotal + deliveryFee).toFixed(2);

    const order = await this.prisma.$transaction(async (tx) => {
      const created = await tx.order.create({
        data: {
          orderNumber: await this.nextOrderNumber(tx),
          userId,
          status: OrderStatus.SUBMITTED,
          fulfillmentType: dto.fulfillmentType,
          paymentMethod: dto.paymentMethod ?? PaymentMethod.COD,
          paymentStatus: PaymentStatus.PENDING,
          addressId,
          subtotal: new Prisma.Decimal(subtotal.toFixed(2)),
          deliveryFee: new Prisma.Decimal(deliveryFee),
          discountTotal: new Prisma.Decimal(0),
          total: new Prisma.Decimal(total),
          distanceMeters,
          etaMinutes,
          customerNote: dto.customerNote,
          items: { create: items },
          statusHistory: {
            create: { status: OrderStatus.SUBMITTED, changedBy: userId, note: 'Order submitted' },
          },
        },
        include: ORDER_INCLUDE,
      });
      await tx.cartItem.deleteMany({ where: { userId } });
      return created;
    });

    await this.notifyCustomer(order.userId, NotificationType.ORDER_SUBMITTED, order.orderNumber);
    return order;
  }

  // ── Queries ──────────────────────────────────────────────────────────────
  async listForCustomer(userId: string, query: QueryOrdersDto) {
    const where: Prisma.OrderWhereInput = { userId, ...(query.status ? { status: query.status } : {}) };
    return this.paginatedList(where, query);
  }

  async listForStaff(query: QueryOrdersDto) {
    const where: Prisma.OrderWhereInput = query.status ? { status: query.status } : {};
    return this.paginatedList(where, query);
  }

  /** Orders awaiting staff action (review queue). */
  reviewQueue() {
    return this.prisma.order.findMany({
      where: { status: { in: [OrderStatus.SUBMITTED, OrderStatus.UNDER_REVIEW] } },
      orderBy: { submittedAt: 'asc' },
      include: ORDER_INCLUDE,
    });
  }

  async getForCustomer(userId: string, id: string) {
    const order = await this.prisma.order.findFirst({ where: { id, userId }, include: ORDER_INCLUDE });
    if (!order) throw new NotFoundException('Order not found');
    return order;
  }

  async getForStaff(id: string) {
    const order = await this.prisma.order.findUnique({ where: { id }, include: ORDER_INCLUDE });
    if (!order) throw new NotFoundException('Order not found');
    return order;
  }

  // ── Employee actions ───────────────────────────────────────────────────────
  async startReview(orderId: string, actor: AuthUser) {
    const order = await this.getForStaff(orderId);
    this.assertTransition(order.status, OrderStatus.UNDER_REVIEW);
    const updated = await this.transition(orderId, OrderStatus.UNDER_REVIEW, actor.id, {
      reviewedBy: { connect: { id: actor.id } },
    });
    await this.notifyCustomer(order.userId, NotificationType.ORDER_UNDER_REVIEW, order.orderNumber);
    return updated;
  }

  async approve(orderId: string, actor: AuthUser) {
    const order = await this.getForStaff(orderId);
    this.assertTransition(order.status, OrderStatus.APPROVED);

    // Decrement stock for all available items atomically.
    await this.prisma.$transaction(async (tx) => {
      for (const item of order.items) {
        if (item.availability === OrderItemAvailability.AVAILABLE) {
          await this.inventory.adjust(
            {
              productId: item.productId,
              type: 'SOLD',
              quantityDelta: -item.quantity,
              reason: `Order ${order.orderNumber}`,
              actorId: actor.id,
            },
            tx,
          );
        }
      }
      await tx.order.update({
        where: { id: orderId },
        data: {
          status: OrderStatus.APPROVED,
          reviewedBy: { connect: { id: actor.id } },
          approvedAt: new Date(),
          statusHistory: { create: { status: OrderStatus.APPROVED, changedBy: actor.id } },
        },
      });
    });

    await this.notifyCustomer(order.userId, NotificationType.ORDER_APPROVED, order.orderNumber);
    return this.getForStaff(orderId);
  }

  async reject(orderId: string, dto: RejectOrderDto, actor: AuthUser) {
    const order = await this.getForStaff(orderId);
    this.assertTransition(order.status, OrderStatus.REJECTED);
    const updated = await this.transition(orderId, OrderStatus.REJECTED, actor.id, {
      reviewedBy: { connect: { id: actor.id } },
      rejectionReason: dto.reason,
    });
    await this.notifyCustomer(order.userId, NotificationType.ORDER_REJECTED, order.orderNumber, dto.reason);
    return updated;
  }

  /** Marks items unavailable and asks the customer to confirm continuing without them. */
  async requestConfirmation(orderId: string, dto: RequestConfirmationDto, actor: AuthUser) {
    const order = await this.getForStaff(orderId);
    this.assertTransition(order.status, OrderStatus.CONFIRMATION_REQUIRED);

    const unavailableIds = new Set(dto.unavailableItems.map((i) => i.orderItemId));
    if (unavailableIds.size === 0) throw new BadRequestException('No items marked unavailable');
    if (unavailableIds.size >= order.items.length) {
      throw new BadRequestException('Cannot mark all items unavailable — reject the order instead');
    }

    await this.prisma.$transaction(async (tx) => {
      await tx.orderItem.updateMany({
        where: { orderId, id: { in: [...unavailableIds] } },
        data: { availability: OrderItemAvailability.UNAVAILABLE },
      });
      await tx.order.update({
        where: { id: orderId },
        data: {
          status: OrderStatus.CONFIRMATION_REQUIRED,
          reviewedBy: { connect: { id: actor.id } },
          statusHistory: {
            create: {
              status: OrderStatus.CONFIRMATION_REQUIRED,
              changedBy: actor.id,
              note: dto.note ?? 'Some items are unavailable',
            },
          },
        },
      });
    });

    await this.notifyCustomer(
      order.userId,
      NotificationType.CONFIRMATION_REQUIRED,
      order.orderNumber,
      'Some items are unavailable. Please confirm to continue or cancel.',
    );
    return this.getForStaff(orderId);
  }

  /** Advances an approved order through preparation/delivery statuses. */
  async advanceStatus(orderId: string, dto: AdvanceStatusDto, actor: AuthUser) {
    const order = await this.getForStaff(orderId);
    this.assertTransition(order.status, dto.status);

    const allowed: OrderStatus[] = [
      OrderStatus.PREPARING,
      OrderStatus.READY,
      OrderStatus.OUT_FOR_DELIVERY,
      OrderStatus.DELIVERED,
      OrderStatus.PICKED_UP,
    ];
    if (!allowed.includes(dto.status)) {
      throw new BadRequestException('Use the dedicated endpoint for this status');
    }
    if (dto.status === OrderStatus.OUT_FOR_DELIVERY && order.fulfillmentType !== FulfillmentType.DELIVERY) {
      throw new BadRequestException('Order is pickup, not delivery');
    }
    if (dto.status === OrderStatus.PICKED_UP && order.fulfillmentType !== FulfillmentType.PICKUP) {
      throw new BadRequestException('Order is delivery, not pickup');
    }

    const extra: Prisma.OrderUpdateInput = {};
    if (dto.status === OrderStatus.DELIVERED || dto.status === OrderStatus.PICKED_UP) {
      extra.deliveredAt = new Date();
      // Cash is collected on handover — settle COD orders at this point.
      if (order.paymentMethod === PaymentMethod.COD && order.paymentStatus !== PaymentStatus.PAID) {
        extra.paymentStatus = PaymentStatus.PAID;
        extra.paidAt = new Date();
      }
    }
    const updated = await this.transition(orderId, dto.status, actor.id, extra, dto.note);
    await this.notifyCustomer(order.userId, this.statusNotificationType(dto.status), order.orderNumber);
    return updated;
  }

  // ── Customer actions ───────────────────────────────────────────────────────
  /** Customer confirms a partial order — drops unavailable items, recomputes totals. */
  async confirmPartial(userId: string, orderId: string) {
    const order = await this.getForCustomer(userId, orderId);
    if (order.status !== OrderStatus.CONFIRMATION_REQUIRED) {
      throw new BadRequestException('Order is not awaiting confirmation');
    }

    const available = order.items.filter((i) => i.availability === OrderItemAvailability.AVAILABLE);
    const subtotal = available.reduce((sum, i) => sum + Number(i.lineTotal), 0);
    const total = +(subtotal + Number(order.deliveryFee)).toFixed(2);

    await this.prisma.$transaction(async (tx) => {
      await tx.orderItem.deleteMany({
        where: { orderId, availability: OrderItemAvailability.UNAVAILABLE },
      });
      await tx.order.update({
        where: { id: orderId },
        data: {
          status: OrderStatus.UNDER_REVIEW,
          subtotal: new Prisma.Decimal(subtotal.toFixed(2)),
          total: new Prisma.Decimal(total),
          statusHistory: {
            create: {
              status: OrderStatus.UNDER_REVIEW,
              changedBy: userId,
              note: 'Customer confirmed partial order',
            },
          },
        },
      });
    });
    return this.getForCustomer(userId, orderId);
  }

  /** Customer cancels (only before approval). */
  async cancel(userId: string, orderId: string) {
    const order = await this.getForCustomer(userId, orderId);
    if (!canTransition(order.status, OrderStatus.CANCELLED)) {
      throw new ForbiddenException('Order can no longer be cancelled');
    }
    return this.transition(orderId, OrderStatus.CANCELLED, userId, {}, 'Cancelled by customer');
  }

  // ── Helpers ────────────────────────────────────────────────────────────────
  private async paginatedList(where: Prisma.OrderWhereInput, query: QueryOrdersDto) {
    const [items, total] = await Promise.all([
      this.prisma.order.findMany({
        where,
        orderBy: { createdAt: 'desc' },
        skip: query.skip,
        take: query.limit,
        include: ORDER_INCLUDE,
      }),
      this.prisma.order.count({ where }),
    ]);
    return paginate(items, total, query.page, query.limit);
  }

  private assertTransition(from: OrderStatus, to: OrderStatus) {
    if (!canTransition(from, to)) {
      throw new BadRequestException(`Invalid transition: ${from} → ${to}`);
    }
  }

  private async transition(
    orderId: string,
    status: OrderStatus,
    actorId: string,
    extra: Prisma.OrderUpdateInput = {},
    note?: string,
  ) {
    return this.prisma.order.update({
      where: { id: orderId },
      data: {
        status,
        ...extra,
        statusHistory: { create: { status, changedBy: actorId, note } },
      },
      include: ORDER_INCLUDE,
    });
  }

  private async nextOrderNumber(tx: Prisma.TransactionClient): Promise<string> {
    const count = await tx.order.count();
    const seq = String(count + 1).padStart(6, '0');
    return `ALD-${new Date().getFullYear()}-${seq}`;
  }

  private statusNotificationType(status: OrderStatus): NotificationType {
    const map: Partial<Record<OrderStatus, NotificationType>> = {
      PREPARING: NotificationType.ORDER_PREPARING,
      READY: NotificationType.ORDER_READY,
      OUT_FOR_DELIVERY: NotificationType.ORDER_OUT_FOR_DELIVERY,
      DELIVERED: NotificationType.ORDER_DELIVERED,
      PICKED_UP: NotificationType.ORDER_PICKED_UP,
    };
    return map[status] ?? NotificationType.SYSTEM;
  }

  private async notifyCustomer(
    userId: string,
    type: NotificationType,
    orderNumber: string,
    extra?: string,
  ) {
    const titles: Record<string, string> = {
      ORDER_SUBMITTED: 'Order submitted',
      ORDER_UNDER_REVIEW: 'Order under review',
      CONFIRMATION_REQUIRED: 'Confirmation required',
      ORDER_APPROVED: 'Order approved',
      ORDER_REJECTED: 'Order rejected',
      ORDER_PREPARING: 'Preparing your order',
      ORDER_READY: 'Order ready',
      ORDER_OUT_FOR_DELIVERY: 'Out for delivery',
      ORDER_DELIVERED: 'Order delivered',
      ORDER_PICKED_UP: 'Order picked up',
    };
    await this.notifications.notify({
      userId,
      type,
      title: titles[type] ?? 'Order update',
      body: extra ? `Order ${orderNumber}: ${extra}` : `Order ${orderNumber} — ${titles[type] ?? 'updated'}`,
      payload: { orderNumber },
      email: type === NotificationType.ORDER_APPROVED || type === NotificationType.ORDER_REJECTED,
    });
  }
}
