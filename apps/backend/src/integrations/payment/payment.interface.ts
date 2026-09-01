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

export interface ChargeResult extends PaymentStatusResult {
  /** Currency the gateway actually charged in. */
  currency: string;
}

export interface PaymentProvider {
  /**
   * Client-side key the mobile SDK uses to tokenise a card. Safe to hand to the
   * app — it can only create charges, never read or refund them.
   */
  readonly publishableKey: string;
  createPayment(input: CreatePaymentInput): Promise<CreatePaymentResult>;
  getPayment(reference: string): Promise<PaymentStatusResult>;
  /**
   * Reads a single charge the client created itself. Distinct from getPayment,
   * which resolves references as invoices.
   */
  getCharge(paymentId: string): Promise<ChargeResult>;
  /** Validates an inbound webhook using the gateway's shared secret. */
  verifyWebhook(secretToken: string | undefined): boolean;
}
