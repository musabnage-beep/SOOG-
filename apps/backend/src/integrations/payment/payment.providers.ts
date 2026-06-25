import { Injectable, Logger } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import {
  CreatePaymentInput,
  CreatePaymentResult,
  PaymentProvider,
  PaymentStatusResult,
} from './payment.interface';

/**
 * Dev payment provider: no real gateway. It "settles" instantly by redirecting
 * the customer back to the callback URL with a paid marker, so the full payment
 * flow is exercisable locally without credentials.
 */
@Injectable()
export class ConsolePaymentProvider implements PaymentProvider {
  private readonly logger = new Logger('PAYMENT');

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

  constructor(config: ConfigService) {
    const secretKey = config.getOrThrow<string>('MOYASAR_SECRET_KEY');
    this.authHeader = `Basic ${Buffer.from(`${secretKey}:`).toString('base64')}`;
    this.webhookSecret = config.get<string>('MOYASAR_WEBHOOK_SECRET', '');
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
      status: invoice.status === 'paid' ? 'paid' : invoice.status === 'failed' ? 'failed' : 'pending',
      amount: invoice.amount / 100,
    };
  }

  verifyWebhook(secretToken: string | undefined): boolean {
    if (!this.webhookSecret) return true;
    return secretToken === this.webhookSecret;
  }
}
