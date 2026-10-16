// Country payment-provider abstraction (Part II §34.3).
// Payment (buyer pays) and Payout (seller receives) are separate events:
// nothing here may release a payout as a side effect of a payment.

export type Currency = "NGN" | "XOF";

export interface DealSnapshot {
  dealId: string;
  buyerId: string;
  buyerEmail: string;
  amountMinor: number;
  currency: Currency;
}

export interface CheckoutSession {
  provider: string;
  reference: string;
  checkoutUrl: string;
}

export type VerifiedPaymentStatus = "pending" | "successful" | "failed";

export interface VerifiedPayment {
  provider: string;
  reference: string;
  status: VerifiedPaymentStatus;
  amountMinor: number;
  currency: Currency;
  /** Provider's own event/transaction time, stored separately from ours. */
  providerTimestamp?: string;
}

export interface ProviderEvent {
  provider: string;
  eventId: string;
  eventType: string;
  reference: string;
}

export interface PayoutRequest {
  payoutId: string;
  dealId: string;
  amountMinor: number;
  currency: Currency;
  recipientRef: string;
}

export interface PayoutResult {
  provider: string;
  reference: string;
  status: "requested" | "paid" | "failed";
}

export interface RefundResult {
  provider: string;
  reference: string;
  status: "pending" | "refunded" | "failed";
}

export interface PaymentAdapter {
  readonly provider: string;
  initialize(
    deal: DealSnapshot,
    idempotencyKey: string,
  ): Promise<CheckoutSession>;
  /** Server-to-provider verification. Browser redirects are never proof. */
  verify(reference: string): Promise<VerifiedPayment>;
  /** Must reject when the signature over the raw body is invalid. */
  parseWebhook(rawBody: Uint8Array, headers: Headers): Promise<ProviderEvent>;
  requestPayout?(
    req: PayoutRequest,
    idempotencyKey: string,
  ): Promise<PayoutResult>;
  queryPayout?(reference: string): Promise<PayoutResult>;
  refund?(payment: VerifiedPayment, reason: string): Promise<RefundResult>;
}
