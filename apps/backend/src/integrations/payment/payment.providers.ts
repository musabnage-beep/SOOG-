import { Injectable, Logger } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import {
  ChargeResult,
  CreatePaymentInput,
  CreatePaymentResult,
  GatewayPaymentStatus,
  PaymentProvider,
  PaymentStatusResult,
} from './payment.interface';

/** Anything the gateway has not settled yet stays pending, never paid. */
function mapGatewayStatus(status: string): GatewayPaymentStatus {
  if (status === 'paid') return 'paid';
  if (status === 'failed') return 'failed';
  return 'pending';
}

/**
 * Dev payment provider: no real gateway. It "settles" instantly by redirecting
 * the customer back to the callback URL with a paid marker, so the full payment
 * flow is exercisable locally without credentials.
 */
@Injectable()
export class ConsolePaymentProvider implements PaymentProvider {
  private readonly logger = new Logger('PAYMENT');
  readonly publishableKey = 'pk_test_dev';

  async createPayment(input: CreatePaymentInput): Promise<CreatePaymentResult> {
    const reference = `dev_${input.orderId}`;
    this.logger.log(
      `[DEV-PAY] order=${input.orderNumber} amount=${input.amount} SAR ref=${reference}`,
    );
    const sep = input.callbackUrl.includes('?') ? '&' : '?';
    return {
      reference,
      redirectUrl: `${input.callbackUrl}${sep}status=paid&id=${reference}`,
    };
  }

  async getPayment(reference: string): Promise<PaymentStatusResult> {
    return { reference, status: 'paid', amount: 0 };
  }

  async getCharge(paymentId: string): Promise<ChargeResult> {
    return { reference: paymentId, status: 'paid', amount: 0, currency: 'SAR' };
  }

  verifyWebhook(): boolean {
    return true;
  }
}

interface MoyasarInvoice {
  id: string;
  status: string;
  amount: number;
  url: string;
}

interface MoyasarPayment {
  id: string;
  status: string;
  amount: number;
  currency: string;
}

/**
 * Production payment provider via Moyasar (KSA) using the Invoices API.
 * Supports mada, Apple Pay, Visa and Mastercard through a hosted payment page.
 * Auth is HTTP Basic with the secret key as the username and an empty password.
 * Amounts are sent in halalas (SAR * 100).
 */
@Injectable()
export class MoyasarPaymentProvider implements PaymentProvider {
  private readonly logger = new Logger('PAYMENT');
  private readonly baseUrl = 'https://api.moyasar.com/v1';
  private readonly authHeader: string;
  private readonly webhookSecret: string;
  readonly publishableKey: string;

  constructor(config: ConfigService) {
    const secretKey = config.getOrThrow<string>('MOYASAR_SECRET_KEY');
    this.authHeader = `Basic ${Buffer.from(`${secretKey}:`).toString('base64')}`;
    this.webhookSecret = config.get<string>('MOYASAR_WEBHOOK_SECRET', '');
    this.publishableKey = config.get<string>('MOYASAR_PUBLISHABLE_KEY', '');
  }

  async createPayment(input: CreatePaymentInput): Promise<CreatePaymentResult> {
    const res = await fetch(`${this.baseUrl}/invoices`, {
      method: 'POST',
      headers: { Authorization: this.authHeader, 'Content-Type': 'application/json' },
      body: JSON.stringify({
        amount: Math.round(input.amount * 100),
        currency: 'SAR',
        description: input.description,
        callback_url: input.callbackUrl,
        metadata: { order_id: input.orderId, order_number: input.orderNumber },
      }),
    });
    if (!res.ok) {
      const text = await res.text();
      this.logger.error(`Moyasar create invoice failed (${res.status}): ${text}`);
      throw new Error(`Payment provider error: ${res.status}`);
    }
    const invoice = (await res.json()) as MoyasarInvoice;
    return { reference: invoice.id, redirectUrl: invoice.url };
  }

  async getPayment(reference: string): Promise<PaymentStatusResult> {
    const res = await fetch(`${this.baseUrl}/invoices/${reference}`, {
      headers: { Authorization: this.authHeader },
    });
    if (!res.ok) {
      this.logger.error(`Moyasar fetch invoice failed (${res.status}) for ${reference}`);
      throw new Error(`Payment provider error: ${res.status}`);
    }
    const invoice = (await res.json()) as MoyasarInvoice;
    return {
      reference: invoice.id,
      status: mapGatewayStatus(invoice.status),
      amount: invoice.amount / 100,
    };
  }

  async getCharge(paymentId: string): Promise<ChargeResult> {
    const res = await fetch(`${this.baseUrl}/payments/${paymentId}`, {
      headers: { Authorization: this.authHeader },
    });
    if (!res.ok) {
      this.logger.error(`Moyasar fetch payment failed (${res.status}) for ${paymentId}`);
      throw new Error(`Payment provider error: ${res.status}`);
    }
    const payment = (await res.json()) as MoyasarPayment;
    return {
      reference: payment.id,
      status: mapGatewayStatus(payment.status),
      amount: payment.amount / 100,
      currency: payment.currency,
    };
  }

  verifyWebhook(secretToken: string | undefined): boolean {
    if (!this.webhookSecret) return true;
    return secretToken === this.webhookSecret;
  }
}
