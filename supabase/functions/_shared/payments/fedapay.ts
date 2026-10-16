// Benin (XOF). DEC-16: FedaPay is tentative and has no sandbox access yet,
// so every call reports the provider as unavailable. Replace with a real
// adapter (VT-028) once credentials and the payout model are confirmed.

import type {
  CheckoutSession,
  PaymentAdapter,
  ProviderEvent,
  VerifiedPayment,
} from "./adapter.ts";

export class ProviderUnavailableError extends Error {}

export class FedaPayPaymentAdapter implements PaymentAdapter {
  readonly provider = "fedapay";

  initialize(): Promise<CheckoutSession> {
    return Promise.reject(
      new ProviderUnavailableError("FedaPay not configured (DEC-16)"),
    );
  }

  verify(): Promise<VerifiedPayment> {
    return Promise.reject(
      new ProviderUnavailableError("FedaPay not configured (DEC-16)"),
    );
  }

  parseWebhook(): Promise<ProviderEvent> {
    return Promise.reject(
      new ProviderUnavailableError("FedaPay not configured (DEC-16)"),
    );
  }
}
