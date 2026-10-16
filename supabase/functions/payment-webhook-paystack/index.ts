// Paystack webhook (public; no user JWT). Trust comes from the HMAC
// signature over the raw body AND a server-to-server verify call; the
// webhook payload alone is never treated as proof of payment.

import { adminClient } from "../_shared/supabase.ts";
import { adapterFor } from "../_shared/payments/registry.ts";

Deno.serve(async (req) => {
  if (req.method !== "POST") return new Response(null, { status: 405 });
  const raw = new Uint8Array(await req.arrayBuffer());

  let adapter;
  let event;
  try {
    adapter = adapterFor("NGN");
    event = await adapter.parseWebhook(raw, req.headers);
  } catch (err) {
    console.warn("paystack webhook rejected", String(err));
    return new Response(null, { status: 401 });
  }

  if (!event.eventType.startsWith("charge.")) {
    return new Response(null, { status: 200 });
  }

  try {
    const verified = await adapter.verify(event.reference);
    const { data, error } = await adminClient().rpc("payment_apply_verified", {
      p_provider: "paystack",
      p_reference: verified.reference,
      p_status: verified.status,
      p_amount_minor: verified.amountMinor,
      p_currency: verified.currency,
      p_event_id: event.eventId,
      p_event_type: event.eventType,
    });
    if (error) throw error;
    console.info("paystack webhook", { event: event.eventId, result: data });
    return new Response(null, { status: 200 });
  } catch (err) {
    // 5xx makes Paystack retry; processing is idempotent.
    console.error("paystack webhook processing failed", err);
    return new Response(null, { status: 500 });
  }
});
