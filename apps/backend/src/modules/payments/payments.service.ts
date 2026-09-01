import {
  BadRequestException,
  Inject,
  Injectable,
  Logger,
  NotFoundException,
  UnauthorizedException,
} from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { NotificationType, Order, PaymentMethod, PaymentStatus } from '@prisma/client';
import { PrismaService } from '@/prisma/prisma.service';
import { NotificationsService } from '@/modules/notifications/notifications.service';
import { PAYMENT_PROVIDER, PaymentProvider } from '@/integrations/payment/payment.interface';

@Injectable()
export class PaymentsService {
  private readonly logger = new Logger('PAYMENT');

  constructor(
    private readonly prisma: PrismaService,
    private readonly notifications: NotificationsService,
    private readonly config: ConfigService,
    @Inject(PAYMENT_PROVIDER) private readonly provider: PaymentProvider,
  ) {}

  /** Loads an order that belongs to the customer and is still awaiting a card payment. */
  private async findPayableOrder(userId: string, orderId: string) {
    const order = await this.prisma.order.findFirst({ where: { id: orderId, userId } });
    if (!order) throw new NotFoundException('Order not found');
    if (order.paymentMethod !== PaymentMethod.CARD) {
      throw new BadRequestException('Order is not a card payment');
    }
    if (order.paymentStatus === PaymentStatus.PAID) {
      throw new BadRequestException('Order is already paid');
    }
    if (order.status === 'CANCELLED' || order.status === 'REJECTED') {
      throw new BadRequestException('Order can no longer be paid');
    }
    return order;
  }

  /**
   * Everything the in-app SDK needs to charge the card itself. The publishable
   * key can only create charges, so handing it to the app is safe; the resulting
   * charge is still verified server-side by `confirmCharge`.
   */
  async session(userId: string, orderId: string) {
    const order = await this.findPayableOrder(userId, orderId);
    const publishableKey = this.provider.publishableKey;
    if (!publishableKey) {
      throw new BadRequestException('In-app payments are not configured');
    }
    return {
      publishableKey,
      amount: Math.round(Number(order.total) * 100),
      currency: 'SAR',
      description: `ALDIAFAH order ${order.orderNumber}`,
      orderNumber: order.orderNumber,
    };
  }

  /**
   * Confirms a charge the app created with the publishable key. The client is
   * never trusted: we re-read the charge from the gateway and check the amount,
   * the currency and that no other order already claimed it.
   */
  async confirmCharge(userId: string, orderId: string, paymentId: string) {
    // The webhook may have won the race, so a paid order is a success here, not
    // the "already paid" error the customer would otherwise see after paying.
    const known = await this.prisma.order.findFirst({ where: { id: orderId, userId } });
    if (known?.paymentStatus === PaymentStatus.PAID) {
      return {
        orderId: known.id,
        orderNumber: known.orderNumber,
        paymentStatus: known.paymentStatus,
      };
    }

    const order = await this.findPayableOrder(userId, orderId);

    const claimed = await this.prisma.order.findFirst({
      where: { paymentRef: paymentId, id: { not: order.id } },
    });
    if (claimed) throw new BadRequestException('Payment already used for another order');

    const charge = await this.provider.getCharge(paymentId);
    if (charge.currency !== 'SAR') throw new BadRequestException('Unexpected payment currency');
    if (Math.round(charge.amount * 100) !== Math.round(Number(order.total) * 100)) {
      throw new BadRequestException('Payment amount does not match the order');
    }

    if (charge.status === 'paid') {
      await this.markPaid(order, paymentId);
    } else if (charge.status === 'failed') {
      await this.markFailed(order);
    } else {
      throw new BadRequestException('Payment is not settled yet');
    }

    const updated = await this.prisma.order.findUnique({ where: { id: order.id } });
    return {
      orderId: updated!.id,
      orderNumber: updated!.orderNumber,
      paymentStatus: updated!.paymentStatus,
    };
  }

  /** Customer starts an online (card) payment; returns the hosted payment page URL. */
  async initiate(userId: string, orderId: string) {
    const order = await this.findPayableOrder(userId, orderId);

    const base = this.config.get<string>(
      'PAYMENT_CALLBACK_URL',
      'http://localhost:3000/api/payments/callback',
    );
    const callbackUrl = `${base}${base.includes('?') ? '&' : '?'}order=${order.id}`;

    const result = await this.provider.createPayment({
      orderId: order.id,
      orderNumber: order.orderNumber,
      amount: Number(order.total),
      description: `ALDIAFAH order ${order.orderNumber}`,
      callbackUrl,
    });

    await this.prisma.order.update({
      where: { id: order.id },
      data: { paymentRef: result.reference, paymentStatus: PaymentStatus.PENDING },
    });

    return { reference: result.reference, redirectUrl: result.redirectUrl };
  }

  /**
   * Customer redirect target after the hosted payment page. We never trust the
   * query string — payment is reconciled by re-querying the gateway.
   */
  async confirmCallback(orderId: string) {
    const order = await this.prisma.order.findUnique({ where: { id: orderId } });
    if (!order) throw new NotFoundException('Order not found');
    if (order.paymentStatus === PaymentStatus.PAID) {
      return { orderId: order.id, orderNumber: order.orderNumber, paymentStatus: order.paymentStatus };
    }

    // Only ever reconcile against the reference we stored ourselves. The gateway
    // appends its own `id` to the redirect, but that is the payment id and the
    // provider looks references up as invoices.
    const ref = order.paymentRef ?? undefined;
    if (!ref) throw new BadRequestException('Missing payment reference');

    const status = await this.provider.getPayment(ref);
    if (status.status === 'paid') {
      await this.markPaid(order, ref);
    } else if (status.status === 'failed') {
      await this.markFailed(order);
    }

    const updated = await this.prisma.order.findUnique({ where: { id: order.id } });
    return {
      orderId: updated!.id,
      orderNumber: updated!.orderNumber,
      paymentStatus: updated!.paymentStatus,
    };
  }

  /** Gateway server-to-server webhook (source of truth in production). */
  async handleWebhook(body: Record<string, unknown>) {
    const secretToken = typeof body.secret_token === 'string' ? body.secret_token : undefined;
    if (!this.provider.verifyWebhook(secretToken)) {
      throw new UnauthorizedException('Invalid webhook signature');
    }

    const data = (body.data ?? {}) as Record<string, unknown>;
    const gatewayStatus = typeof data.status === 'string' ? data.status : undefined;

    // `paymentRef` holds the *invoice* id, but a payment_* event carries the
    // *payment* id in `data.id` and the invoice it belongs to in `data.invoice_id`.
    // Match on either so both invoice and payment events reconcile.
    const references = [data.invoice_id, data.id].filter(
      (value): value is string => typeof value === 'string' && value.length > 0,
    );
    if (references.length === 0) {
      this.logger.warn('Webhook received without a payment reference');
      return { received: true };
    }

    const order = await this.resolveWebhookOrder(references, data);
    if (!order) {
      this.logger.warn(`Webhook for unknown payment reference ${references.join(', ')}`);
      return { received: true };
    }

    if (gatewayStatus === 'paid') {
      await this.markPaid(order, order.paymentRef ?? references[0]);
    } else if (gatewayStatus === 'failed') {
      await this.markFailed(order);
    }
    return { received: true };
  }

  /**
   * A charge the app created in-app has no invoice, and we only learn its id
   * when the app reports back — so a dropped confirmation would leave a paid
   * order stuck. The SDK stamps the order id into the charge metadata, which
   * lets the webhook reconcile on its own. Metadata comes from the client, so
   * that path only counts when the charged amount matches the order exactly.
   */
  private async resolveWebhookOrder(references: string[], data: Record<string, unknown>) {
    const byRef = await this.prisma.order.findFirst({
      where: { paymentRef: { in: references } },
    });
    if (byRef) return byRef;

    const metadata = (data.metadata ?? {}) as Record<string, unknown>;
    const orderId = typeof metadata.order_id === 'string' ? metadata.order_id : undefined;
    if (!orderId) return null;

    const order = await this.prisma.order.findUnique({ where: { id: orderId } });
    if (!order) return null;

    const halalas = typeof data.amount === 'number' ? data.amount : -1;
    if (halalas !== Math.round(Number(order.total) * 100)) {
      this.logger.warn(`Webhook amount ${halalas} does not match order ${order.orderNumber}`);
      return null;
    }
    return order;
  }

  private async markPaid(order: Order, reference: string) {
    if (order.paymentStatus === PaymentStatus.PAID) return;
    await this.prisma.order.update({
      where: { id: order.id },
      data: { paymentStatus: PaymentStatus.PAID, paidAt: new Date(), paymentRef: reference },
    });
    this.logger.log(`Order ${order.orderNumber} marked PAID (ref=${reference})`);
    await this.notifications.notify({
      userId: order.userId,
      type: NotificationType.PAYMENT_RECEIVED,
      title: 'Payment received',
      body: `Payment for order ${order.orderNumber} was received.`,
      payload: { orderNumber: order.orderNumber },
      email: true,
    });
  }

  private async markFailed(order: Order) {
    if (order.paymentStatus === PaymentStatus.PAID) return;
    await this.prisma.order.update({
      where: { id: order.id },
      data: { paymentStatus: PaymentStatus.FAILED },
    });
    await this.notifications.notify({
      userId: order.userId,
      type: NotificationType.PAYMENT_FAILED,
      title: 'Payment failed',
      body: `Payment for order ${order.orderNumber} could not be completed.`,
      payload: { orderNumber: order.orderNumber },
    });
  }
}
