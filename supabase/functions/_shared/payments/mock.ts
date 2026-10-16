// In-memory adapter for local development and tests (PAYMENT_MODE=mock).
// Webhooks are signed with HMAC-SHA512 like Paystack, using a test secret.

import type {
  CheckoutSession,
  DealSnapshot,
  PaymentAdapter,
  PayoutRequest,
  PayoutResult,
  ProviderEvent,
  VerifiedPayment,
} from "./adapter.ts";

export async function hmacSha512Hex(
  secret: string,
  body: Uint8Array,
): Promise<string> {
  const key = await crypto.subtle.importKey(
    "raw",
    new TextEncoder().encode(secret),
    { name: "HMAC", hash: "SHA-512" },
    false,
    ["sign"],
  );
  const sig = new Uint8Array(
    await crypto.subtle.sign("HMAC", key, new Uint8Array(body)),
  );
  return Array.from(sig, (b) => b.toString(16).padStart(2, "0")).join("");
}

function timingSafeEqual(a: string, b: string): boolean {
  if (a.length !== b.length) return false;
  let diff = 0;
  for (let i = 0; i < a.length; i++) diff |= a.charCodeAt(i) ^ b.charCodeAt(i);
  return diff === 0;
}

export class MockPaymentAdapter implements PaymentAdapter {
  readonly provider = "mock";
  private readonly payments = new Map<string, VerifiedPayment>();

  constructor(private readonly webhookSecret = "mock-webhook-secret") {}

  initialize(
    deal: DealSnapshot,
    idempotencyKey: string,
  ): Promise<CheckoutSession> {
    const reference = `mock_${deal.dealId}_${idempotencyKey}`;
    if (!this.payments.has(reference)) {
      this.payments.set(reference, {
        provider: this.provider,
        reference,
        status: "pending",
        amountMinor: deal.amountMinor,
        currency: deal.currency,
      });
    }
    return Promise.resolve({
      provider: this.provider,
      reference,
      checkoutUrl: `https://mock.invalid/checkout/${reference}`,
    });
  }

  /** Test helper: simulate the provider settling a payment. */
  settle(reference: string, status: "successful" | "failed" = "successful") {
    const p = this.payments.get(reference);
    if (!p) throw new Error(`unknown reference ${reference}`);
    this.payments.set(reference, { ...p, status });
  }

  verify(reference: string): Promise<VerifiedPayment> {
    const p = this.payments.get(reference);
    if (!p) return Promise.reject(new Error("unknown reference"));
    return Promise.resolve(p);
  }

  async parseWebhook(
    rawBody: Uint8Array,
    headers: Headers,
  ): Promise<ProviderEvent> {
    const given = headers.get("x-mock-signature") ?? "";
    const expected = await hmacSha512Hex(this.webhookSecret, rawBody);
    if (!timingSafeEqual(given, expected)) throw new Error("invalid signature");
    const event = JSON.parse(new TextDecoder().decode(rawBody));
    return {
      provider: this.provider,
      eventId: String(event.id),
      eventType: String(event.event),
      reference: String(event.data?.reference),
    };
  }

  requestPayout(
    req: PayoutRequest,
    idempotencyKey: string,
  ): Promise<PayoutResult> {
    return Promise.resolve({
      provider: this.provider,
      reference: `mock_payout_${req.payoutId}_${idempotencyKey}`,
      status: "requested",
    });
  }
}
