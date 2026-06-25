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

  /** Customer starts an online (card) payment; returns the hosted payment page URL. */
  async initiate(userId: string, orderId: string) {
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
  async confirmCallback(orderId: string, reference: string | undefined) {
    const order = await this.prisma.order.findUnique({ where: { id: orderId } });
    if (!order) throw new NotFoundException('Order not found');
    if (order.paymentStatus === PaymentStatus.PAID) {
      return { orderId: order.id, orderNumber: order.orderNumber, paymentStatus: order.paymentStatus };
    }

    const ref = reference ?? order.paymentRef ?? undefined;
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
    const reference = typeof data.id === 'string' ? data.id : undefined;
    const gatewayStatus = typeof data.status === 'string' ? data.status : undefined;
    if (!reference) {
      this.logger.warn('Webhook received without a payment reference');
      return { received: true };
    }

    const order = await this.prisma.order.findFirst({ where: { paymentRef: reference } });
    if (!order) {
      this.logger.warn(`Webhook for unknown payment reference ${reference}`);
      return { received: true };
    }

    if (gatewayStatus === 'paid') {
      await this.markPaid(order, reference);
    } else if (gatewayStatus === 'failed') {
      await this.markFailed(order);
    }
    return { received: true };
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
