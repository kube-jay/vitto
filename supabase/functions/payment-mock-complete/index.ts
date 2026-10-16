// Local/dev only (PAYMENT_MODE=mock): stands in for the provider confirming
// or failing a checkout, so the full online flow can be tested without
// money. The ledger update goes through the same server function a real
// verified webhook uses.

import { AppError, handler, readJson } from "../_shared/http.ts";
import { adminClient, rpcError, userContext } from "../_shared/supabase.ts";
import { paymentMode } from "../_shared/payments/registry.ts";

Deno.serve(handler(async (req) => {
  if (paymentMode() !== "mock") {
    throw new AppError("forbidden", "Only available in mock payment mode");
  }
  const { user, client } = await userContext(req);
  const body = await readJson<{ reference?: string; outcome?: string }>(req);
  if (typeof body.reference !== "string" || !body.reference) {
    throw new AppError("validation_error", "reference is required");
  }
  const outcome = body.outcome === "failed" ? "failed" : "successful";

  const { data: payment } = await client.from("payments")
    .select("provider, provider_reference, amount_minor, currency, deal_id")
    .eq("provider", "mock").eq("provider_reference", body.reference)
    .maybeSingle();
  if (!payment) throw new AppError("forbidden", "Unknown payment");
  const { data: deal } = await client.from("deals").select("buyer_id")
    .eq("id", payment.deal_id).single();
  if (deal?.buyer_id !== user.id) {
    throw new AppError("forbidden", "Only the buyer pays");
  }

  const { data, error } = await adminClient().rpc("payment_apply_verified", {
    p_provider: "mock",
    p_reference: payment.provider_reference,
    p_status: outcome,
    p_amount_minor: payment.amount_minor,
    p_currency: payment.currency,
    p_event_id: `mock-${crypto.randomUUID()}`,
    p_event_type: outcome === "successful" ? "charge.success" : "charge.failed",
  });
  if (error) rpcError(error);
  return data;
}));
