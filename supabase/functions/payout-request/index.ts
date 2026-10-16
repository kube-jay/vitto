// Admin releases a seller Payout for a completed online Deal. Payment and
// Payout are separate events; the database refuses unless the Payout is
// eligible (completed, not disputed). Real payouts stay disabled until
// DEC-06 (custody/delayed settlement) is approved.

import { AppError, handler, readJson, requireUuid } from "../_shared/http.ts";
import { adminClient, rpcError, userContext } from "../_shared/supabase.ts";
import { paymentMode } from "../_shared/payments/registry.ts";

Deno.serve(handler(async (req) => {
  const { client } = await userContext(req);
  const { data: isAdmin } = await client.rpc("current_user_is_admin");
  if (isAdmin !== true) throw new AppError("forbidden", "Admins only");

  const body = await readJson<{ deal_id?: string }>(req);
  const dealId = requireUuid(body.deal_id, "deal_id");
  const admin = adminClient();

  if (paymentMode() !== "mock" && Deno.env.get("PAYOUTS_ENABLED") !== "true") {
    throw new AppError(
      "provider_unavailable",
      "Provider payouts are disabled until DEC-06 is approved",
    );
  }

  // Mock: the provider accepts and settles immediately.
  const reference = `mock-payout-${dealId}`;
  const requested = await admin.rpc("payout_record", {
    p_deal_id: dealId,
    p_status: "requested",
    p_provider_reference: reference,
  });
  if (requested.error) rpcError(requested.error);
  const paid = await admin.rpc("payout_record", {
    p_deal_id: dealId,
    p_status: "paid",
    p_provider_reference: reference,
  });
  if (paid.error) rpcError(paid.error);

  await admin.from("audit_logs").insert({
    action: "payout_paid",
    target_kind: "deal",
    target_id: dealId,
    metadata: { reference, mode: paymentMode() },
  });
  return paid.data;
}));
