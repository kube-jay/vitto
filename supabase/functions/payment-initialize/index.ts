// Buyer starts online payment for a Deal (Part I §12). Returns a hosted
// checkout URL; the Flutter app never sees provider secrets and never
// decides whether the payment succeeded.

import { AppError, handler, readJson, requireUuid } from "../_shared/http.ts";
import { adminClient, rpcError, userContext } from "../_shared/supabase.ts";
import { adapterFor, paymentMode } from "../_shared/payments/registry.ts";
import type { Currency } from "../_shared/payments/adapter.ts";

Deno.serve(handler(async (req) => {
  const { user, client } = await userContext(req);
  const body = await readJson<{ deal_id?: string; idempotency_key?: string }>(
    req,
  );
  const dealId = requireUuid(body.deal_id, "deal_id");
  const key = requireUuid(body.idempotency_key, "idempotency_key");

  // RLS: only participants can read the Deal.
  const { data: deal } = await client.from("deals")
    .select(
      "id, buyer_id, status, transaction_type, agreed_amount_minor, currency",
    )
    .eq("id", dealId).maybeSingle();
  if (!deal) throw new AppError("forbidden", "Not a participant");
  if (deal.buyer_id !== user.id) {
    throw new AppError("forbidden", "Only the buyer pays");
  }
  if (
    deal.transaction_type !== "online" || deal.status !== "awaiting_payment"
  ) {
    throw new AppError("invalid_state", "Deal is not awaiting online payment");
  }

  const adapter = adapterFor(deal.currency as Currency);
  let session;
  try {
    session = await adapter.initialize({
      dealId: deal.id,
      buyerId: user.id,
      buyerEmail: user.email ?? "",
      amountMinor: deal.agreed_amount_minor,
      currency: deal.currency,
    }, key);
  } catch (err) {
    console.error(err);
    throw new AppError("provider_unavailable", "Payment provider unavailable");
  }

  const { data: payment, error } = await adminClient().rpc(
    "payment_record_initialized",
    {
      p_deal_id: deal.id,
      p_provider: session.provider,
      p_reference: session.reference,
      p_amount_minor: deal.agreed_amount_minor,
      p_currency: deal.currency,
      p_idempotency_key: key,
      p_checkout_url: session.checkoutUrl,
    },
  );
  if (error) rpcError(error);

  return {
    mode: paymentMode(),
    provider: payment.provider,
    reference: payment.provider_reference,
    checkout_url: paymentMode() === "mock" ? null : payment.checkout_url,
    status: payment.status,
  };
}));
