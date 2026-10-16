# Server function contract (draft – VT-004)

Status: **DRAFT**. Shapes below follow Part II §34. B owns this file; A/C review before implementation. No agent may invent an endpoint not listed here.

## Envelope

```json
{ "data": { }, "requestId": "uuid" }
{ "error": { "code": "listing_not_available", "message": "...", "details": {} }, "requestId": "uuid" }
```

Error codes: `unauthenticated | forbidden | validation_error | conflict | listing_not_available | invalid_state | payment_pending | provider_unavailable | rate_limited | internal_error`

All functions require a Supabase user JWT unless marked *public*. Mutations accept an `idempotency_key` (UUID) where noted; repeating a key returns the original result.

## Catalogue

| Function | Caller | Input | Result |
|----------|--------|-------|--------|
| `offer-create` | Buyer (non-owner) or Seller countering via `offer-respond` | `listing_id, conversation_id?, amount_minor, idempotency_key` | pending Offer (creates Conversation if absent) |
| `offer-respond` | Offer recipient | `offer_id, action: accept\|reject\|counter, new_amount_minor?` | updated Offer; on `accept` also `deal` |
| `offer-cancel` | Offer proposer | `offer_id` | Offer `cancelled` (pending only) — *pending DEC-12* |
| `deal-select-mode` | Deal participant | `deal_id, mode: online\|offline` | Deal with `transaction_type` set — *pending DEC-11* |
| `payment-initialize` | Buyer | `deal_id, idempotency_key` | `{ checkout_url, reference }` |
| `payment-webhook-paystack` | *public*, signature-verified | raw body + `x-paystack-signature` | 200 / 401 |
| `payment-webhook-fedapay` | *public*, signature-verified | raw body + provider signature header | 200 / 401 |
| `payment-reconcile` | Buyer, Seller or admin | `deal_id` | Payment status after provider verify |
| `deal-handover-code` | Buyer | `deal_id` | `{ code, expires_at }` (code shown only to Buyer) |
| `deal-confirm-online` | Seller | `deal_id, code` | Deal `completed`, Payout eligible |
| `deal-confirm-offline` | Buyer or Seller | `deal_id` | confirmation stored; Deal `completed` when both |
| `deal-confirmation-problem` | Seller | `deal_id, note?` | Buyer prompted "Did you receive the item?" |
| `deal-raise-dispute` | Buyer or Seller | `deal_id, reason, evidence_paths[]` | Deal `disputed`, payout frozen |
| `rating-submit` | Deal participant | `deal_id, stars (1–5), comment?` | Rating (recipient derived server-side) |
| `report-create` | any User | `target_kind, target_id, details` | Report |
| `admin-resolve-dispute` | admin | `deal_id, disposition, notes` | audit entry + Deal status |
| `admin-moderate` | admin | `target_kind (user\|listing), target_id, action (suspend\|restore), reason` | audit entry |
| `payout-request` | admin / system | `deal_id, idempotency_key` | Payout attempt (blocked while `PAYMENT_MODE != live` gates) |

## Transition rules

See Part II §31.2. Summary:

- Accept Offer: Offer `accepted`, Listing `active → reserved`, one Deal with immutable `agreed_amount_minor`; competing pending Offers on that Listing → `expired`. Serialized with a row lock on the Listing.
- Verified payment: Payment `successful`, Deal `awaiting_payment → paid`. **No payout.**
- Online completion: valid code → Deal `completed`, Listing `sold`, Payout row `eligible`.
- Offline completion: both `deal_confirmations` rows → Deal `completed`, Listing `sold`.
- Dispute: Deal → `disputed`; Payout ineligible until admin decision.

Internal Payment statuses (proposed): `initialized, pending, successful, failed, refunded`.
Internal Payout statuses (proposed): `not_eligible, eligible, requested, paid, failed, reversed`.
