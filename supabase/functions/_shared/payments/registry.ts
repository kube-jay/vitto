// Chooses the payment adapter per country/currency and environment.
//
// PAYMENT_MODE=mock     local/dev: in-process mock, no money moves (default)
// PAYMENT_MODE=sandbox  provider test keys
// PAYMENT_MODE=live     refused unless LIVE_PAYMENTS_APPROVED=true, which may
//                       only be set after DEC-05 and DEC-06 are approved.

import type { Currency, PaymentAdapter } from "./adapter.ts";
import { FedaPayPaymentAdapter } from "./fedapay.ts";
import { MockPaymentAdapter } from "./mock.ts";
import { PaystackPaymentAdapter } from "./paystack.ts";
import { AppError } from "../http.ts";

export type PaymentMode = "mock" | "sandbox" | "live";

export function paymentMode(): PaymentMode {
  const mode = (Deno.env.get("PAYMENT_MODE") ?? "mock") as PaymentMode;
  if (!["mock", "sandbox", "live"].includes(mode)) {
    throw new AppError("provider_unavailable", "Invalid PAYMENT_MODE");
  }
  if (mode === "live" && Deno.env.get("LIVE_PAYMENTS_APPROVED") !== "true") {
    throw new AppError(
      "provider_unavailable",
      "Live payments are blocked until DEC-05/DEC-06 are approved",
    );
  }
  return mode;
}

export function adapterFor(currency: Currency): PaymentAdapter {
  const mode = paymentMode();
  if (mode === "mock") return new MockPaymentAdapter();

  const appBase = Deno.env.get("APP_BASE_URL") ?? "http://localhost:5000";
  if (currency === "NGN") {
    const key = Deno.env.get("PAYSTACK_SECRET_KEY");
    if (!key) {
      throw new AppError("provider_unavailable", "Paystack not configured");
    }
    if (mode === "sandbox" && !key.startsWith("sk_test_")) {
      throw new AppError(
        "provider_unavailable",
        "Sandbox mode requires a test key",
      );
    }
    return new PaystackPaymentAdapter(key, (id) => `${appBase}/deals/${id}`);
  }
  return new FedaPayPaymentAdapter();
}

export function adapterByProvider(provider: string): PaymentAdapter {
  if (provider === "mock") return new MockPaymentAdapter();
  if (provider === "paystack") return adapterFor("NGN");
  if (provider === "fedapay") return adapterFor("XOF");
  throw new AppError("validation_error", "Unknown provider");
}
