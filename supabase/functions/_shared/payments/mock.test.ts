// Run with: deno test supabase/functions/_shared
import { assertEquals, assertRejects } from "jsr:@std/assert@1";
import { hmacSha512Hex, MockPaymentAdapter } from "./mock.ts";

const deal = {
  dealId: "d1",
  buyerId: "u1",
  buyerEmail: "buyer@test.vitto",
  amountMinor: 150000,
  currency: "NGN" as const,
};

Deno.test("checkout starts pending and is idempotent", async () => {
  const a = new MockPaymentAdapter();
  const s1 = await a.initialize(deal, "k1");
  const s2 = await a.initialize(deal, "k1");
  assertEquals(s1.reference, s2.reference);
  assertEquals((await a.verify(s1.reference)).status, "pending");
});

Deno.test("only provider-side settlement marks payment successful", async () => {
  const a = new MockPaymentAdapter();
  const s = await a.initialize(deal, "k1");
  a.settle(s.reference);
  const v = await a.verify(s.reference);
  assertEquals(v.status, "successful");
  assertEquals(v.amountMinor, 150000);
  assertEquals(v.currency, "NGN");
});

Deno.test("webhook with wrong signature is rejected (AT-11)", async () => {
  const a = new MockPaymentAdapter("secret");
  const body = new TextEncoder().encode(
    JSON.stringify({
      id: 1,
      event: "charge.success",
      data: { reference: "r" },
    }),
  );
  await assertRejects(() =>
    a.parseWebhook(body, new Headers({ "x-mock-signature": "bad" }))
  );
  const sig = await hmacSha512Hex("secret", body);
  const ev = await a.parseWebhook(
    body,
    new Headers({ "x-mock-signature": sig }),
  );
  assertEquals(ev.reference, "r");
});
