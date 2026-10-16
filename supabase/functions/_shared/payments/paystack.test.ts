import { assertEquals, assertRejects } from "jsr:@std/assert@1";
import { PaystackPaymentAdapter } from "./paystack.ts";
import { hmacSha512Hex } from "./mock.ts";

const fakeFetch = (body: unknown, status = 200): typeof fetch => () =>
  Promise.resolve(new Response(JSON.stringify(body), { status }));

Deno.test("verify maps Paystack success with amount in kobo", async () => {
  const a = new PaystackPaymentAdapter(
    "sk_test_x",
    (id) => `http://app/deals/${id}`,
    fakeFetch({
      status: true,
      data: {
        status: "success",
        reference: "r1",
        amount: 150000,
        currency: "NGN",
      },
    }),
  );
  const v = await a.verify("r1");
  assertEquals(v.status, "successful");
  assertEquals(v.amountMinor, 150000);
});

Deno.test("abandoned checkout is failed, not successful", async () => {
  const a = new PaystackPaymentAdapter(
    "sk_test_x",
    () => "",
    fakeFetch({
      status: true,
      data: { status: "abandoned", reference: "r", amount: 1, currency: "NGN" },
    }),
  );
  assertEquals((await a.verify("r")).status, "failed");
});

Deno.test("webhook signature is checked over the raw body", async () => {
  const a = new PaystackPaymentAdapter("sk_test_secret", () => "");
  const body = new TextEncoder().encode(JSON.stringify({
    event: "charge.success",
    data: { id: 42, reference: "r1" },
  }));
  await assertRejects(() =>
    a.parseWebhook(body, new Headers({ "x-paystack-signature": "nope" }))
  );
  const sig = await hmacSha512Hex("sk_test_secret", body);
  const ev = await a.parseWebhook(
    body,
    new Headers({ "x-paystack-signature": sig }),
  );
  assertEquals(ev.eventId, "charge.success:42");
  assertEquals(ev.reference, "r1");
});

Deno.test("Paystack adapter refuses non-NGN deals", async () => {
  const a = new PaystackPaymentAdapter("sk_test_x", () => "");
  await assertRejects(() =>
    a.initialize({
      dealId: "d",
      buyerId: "b",
      buyerEmail: "e@x",
      amountMinor: 1,
      currency: "XOF",
    }, "k")
  );
});
