// Re-checks a pending Payment with the provider (buyer refreshed, webhook
// late or lost). Never infers success from a browser redirect.

import { AppError, handler, readJson, requireUuid } from "../_shared/http.ts";
import { adminClient, rpcError, userContext } from "../_shared/supabase.ts";
import { adapterByProvider } from "../_shared/payments/registry.ts";

Deno.serve(handler(async (req) => {
  const { client } = await userContext(req);
  const body = await readJson<{ deal_id?: string }>(req);
  const dealId = requireUuid(body.deal_id, "deal_id");

  // RLS: participants (and admins) only.
  const { data: payments } = await client.from("payments")
    .select("provider, provider_reference, status")
    .eq("deal_id", dealId).order("created_at", { ascending: false });
  const pending = (payments ?? []).find((p) => p.status === "pending");
  if (!pending) {
    return { status: payments?.[0]?.status ?? "none", changed: false };
  }
  if (pending.provider === "mock") {
    return { status: "pending", changed: false };
  }

  let verified;
  try {
    verified = await adapterByProvider(pending.provider).verify(
      pending.provider_reference,
    );
  } catch (err) {
    if (err instanceof AppError) throw err;
    console.error(err);
    throw new AppError("provider_unavailable", "Provider unavailable");
  }

  const { data, error } = await adminClient().rpc("payment_apply_verified", {
    p_provider: pending.provider,
    p_reference: verified.reference,
    p_status: verified.status,
    p_amount_minor: verified.amountMinor,
    p_currency: verified.currency,
  });
  if (error) rpcError(error);
  return { status: verified.status, changed: true, result: data };
}));
