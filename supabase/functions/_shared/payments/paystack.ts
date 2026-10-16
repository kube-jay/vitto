// Nigeria (NGN) via Paystack hosted checkout. Sandbox first; live use is
// gated by DEC-05/DEC-06. Paystack split payments are NOT used as "escrow".

import type {
  CheckoutSession,
  DealSnapshot,
  PaymentAdapter,
  ProviderEvent,
  VerifiedPayment,
  VerifiedPaymentStatus,
} from "./adapter.ts";
import { hmacSha512Hex, timingSafeEqual } from "./mock.ts";

const API = "https://api.paystack.co";

export class PaystackPaymentAdapter implements PaymentAdapter {
  readonly provider = "paystack";

  constructor(
    private readonly secretKey: string,
    private readonly returnUrl: (dealId: string) => string,
    private readonly fetchFn: typeof fetch = fetch,
  ) {}

  private async call(path: string, init: RequestInit = {}) {
    const res = await this.fetchFn(`${API}${path}`, {
      ...init,
      headers: {
        authorization: `Bearer ${this.secretKey}`,
        "content-type": "application/json",
      },
    });
    const body = await res.json().catch(() => ({}));
    if (!res.ok || body.status !== true) {
      throw new Error(`paystack ${path} failed: ${res.status}`);
    }
    return body.data;
  }

  async initialize(
    deal: DealSnapshot,
    idempotencyKey: string,
  ): Promise<CheckoutSession> {
    if (deal.currency !== "NGN") {
      throw new Error("Paystack adapter is NGN only");
    }
    const reference = `vitto-${deal.dealId}-${idempotencyKey}`.slice(0, 100);
    const data = await this.call("/transaction/initialize", {
      method: "POST",
      body: JSON.stringify({
        email: deal.buyerEmail,
        amount: deal.amountMinor, // kobo
        currency: "NGN",
        reference,
        callback_url: this.returnUrl(deal.dealId),
        metadata: { deal_id: deal.dealId },
      }),
    });
    return {
      provider: this.provider,
      reference: data.reference,
      checkoutUrl: data.authorization_url,
    };
  }

  async verify(reference: string): Promise<VerifiedPayment> {
    const data = await this.call(
      `/transaction/verify/${encodeURIComponent(reference)}`,
    );
    const status: VerifiedPaymentStatus = data.status === "success"
      ? "successful"
      : ["failed", "abandoned", "reversed"].includes(data.status)
      ? "failed"
      : "pending";
    return {
      provider: this.provider,
      reference: data.reference,
      status,
      amountMinor: Number(data.amount),
      currency: data.currency,
      providerTimestamp: data.paid_at ?? undefined,
    };
  }

  async parseWebhook(
    rawBody: Uint8Array,
    headers: Headers,
  ): Promise<ProviderEvent> {
    const given = headers.get("x-paystack-signature") ?? "";
    const expected = await hmacSha512Hex(this.secretKey, rawBody);
    if (!timingSafeEqual(given, expected)) throw new Error("invalid signature");
    const event = JSON.parse(new TextDecoder().decode(rawBody));
    return {
      provider: this.provider,
      // Paystack events carry no event id; transaction id + type is unique.
      eventId: `${event.event}:${event.data?.id}`,
      eventType: String(event.event),
      reference: String(event.data?.reference),
    };
  }
}
