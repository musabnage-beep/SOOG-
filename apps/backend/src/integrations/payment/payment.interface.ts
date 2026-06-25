export const PAYMENT_PROVIDER = Symbol('PAYMENT_PROVIDER');

export interface CreatePaymentInput {
  orderId: string;
  orderNumber: string;
  /** Amount in SAR major units (e.g. 149.50). */
  amount: number;
  description: string;
  /** URL the gateway redirects the customer to after the hosted payment page. */
  callbackUrl: string;
  customerName?: string;
  customerEmail?: string;
}

export interface CreatePaymentResult {
  /** Gateway payment/invoice identifier — persisted on the order as paymentRef. */
  reference: string;
  /** Hosted payment page the customer is redirected to. */
  redirectUrl: string;
}

export type GatewayPaymentStatus = 'pending' | 'paid' | 'failed';

export interface PaymentStatusResult {
  reference: string;
  status: GatewayPaymentStatus;
  /** Amount in SAR major units as reported by the gateway. */
  amount: number;
}

export interface PaymentProvider {
  createPayment(input: CreatePaymentInput): Promise<CreatePaymentResult>;
  getPayment(reference: string): Promise<PaymentStatusResult>;
  /** Validates an inbound webhook using the gateway's shared secret. */
  verifyWebhook(secretToken: string | undefined): boolean;
}
