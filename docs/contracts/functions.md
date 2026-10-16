# Server contract

Status: **implemented** (M2–M7 backend). B owns this file; A/C review changes. No agent may invent an endpoint not listed here.

All Offer / Deal / confirmation / rating / admin transitions are transactional Postgres functions called through the Data API (`supabase.rpc(...)`), per ENG-07. Edge Functions are used only where a payment provider or a server secret is involved.

## Errors

Postgres functions raise `exception '<code>'` (SQLSTATE `P0001`); the finer reason, when there is one, is in `detail` (for example `fixed_price`, `offer_pending`, `already_rated`, `offer_expired`, `payout_not_eligible`). Edge Functions return:

```json
{ "data": { }, "requestId": "uuid" }
{ "error": { "code": "invalid_state", "message": "...", "details": {} }, "requestId": "uuid" }
```

Codes: `unauthenticated | forbidden | validation_error | conflict | listing_not_available | invalid_state | payment_pending | provider_unavailable | rate_limited | internal_error`

## Database functions (authenticated users)

| Function | Caller | Effect |
|----------|--------|--------|
| `listing_set_status(p_listing_id, p_status)` | owner | draft→active (needs ≥1 image), active→archived, archived→active, draft→archived |
| `search_listings(p_query, p_country, p_region, p_category, p_min_price, p_max_price, p_condition, p_negotiable, p_sort)` | anyone | active Listings only; accent-insensitive prefix search; also callable by anon |
| `start_conversation(p_listing_id)` → uuid | buyer | creates or returns the buyer's Conversation |
| `offer_create(p_conversation_id, p_amount_minor)` | buyer | pending Offer, 48 h TTL; one pending per Conversation; fixed price must equal price (DEC-03) |
| `offer_respond(p_offer_id, p_action accept\|reject\|counter, p_counter_amount_minor)` → jsonb | Offer recipient | accept locks the Listing, reserves it, creates one Deal, expires competing Offers |
| `offer_cancel(p_offer_id)` | proposer | pending → cancelled |
| `deal_select_mode(p_deal_id, p_mode online\|offline)` | participant | DEC-11; blocked once a payment is pending/successful or someone confirmed |
| `deal_confirm_offline(p_deal_id)` | participant | completes when both confirmed |
| `deal_handover_code(p_deal_id)` → `{code, expires_at}` | buyer | after payment; 15 min, hashed server-side |
| `deal_confirm_online(p_deal_id, p_code)` → `{ok, error?, attempts_left?}` | seller | 5 attempts per code; success completes the Deal and makes the Payout eligible |
| `deal_report_confirmation_problem(p_deal_id, p_note)` | seller | asks buyer "Did you receive the item?" |
| `deal_buyer_answer(p_deal_id, p_received, p_note)` | buyer | yes → completed; no → disputed + Report |
| `deal_raise_dispute(p_deal_id, p_reason, p_details)` | participant | paid/awaiting_handover → disputed + Report |
| `deal_cancel(p_deal_id, p_reason)` | participant | DEC-07 matrix; Listing back to active |
| `rating_submit(p_deal_id, p_stars, p_comment)` | participant | completed Deals only, once per side |
| `current_user_is_admin()` → boolean | anyone signed in | UI hint only |
| `admin_list_users`, `admin_set_user_suspension`, `admin_set_listing_suspension`, `admin_update_report`, `admin_resolve_dispute`, `admin_hide_rating` | admin | every call audited in `audit_logs` |

## Database functions (service role only)

| Function | Used by |
|----------|---------|
| `payment_record_initialized(...)` | `payment-initialize` |
| `payment_apply_verified(p_provider, p_reference, p_status, p_amount_minor, p_currency, p_event_id, p_event_type)` | webhooks, reconcile, mock checkout. Idempotent per event id; amount/currency must match the Deal snapshot; never creates a Payout |
| `payout_record(p_deal_id, p_status, p_provider_reference, p_error)` | `payout-request`; refuses unless the Deal is completed and the Payout eligible |

## Edge Functions

| Function | Auth | Input | Result |
|----------|------|-------|--------|
| `payment-initialize` | buyer JWT | `deal_id, idempotency_key` | `{mode, provider, reference, checkout_url}` |
| `payment-mock-complete` | buyer JWT, `PAYMENT_MODE=mock` only | `reference, outcome` | simulates the provider verdict |
| `payment-webhook-paystack` | Paystack HMAC-SHA512 signature | raw body | 200 / 401 / 500 (retry) |
| `payment-reconcile` | participant JWT | `deal_id` | re-verifies a pending payment with the provider |
| `payout-request` | admin JWT | `deal_id` | mock: marks paid; live: refused until DEC-06 and `PAYOUTS_ENABLED=true` |

Environment: `PAYMENT_MODE` (`mock` default, `sandbox`, `live`), `LIVE_PAYMENTS_APPROVED`, `PAYOUTS_ENABLED`, `PAYSTACK_SECRET_KEY`, `APP_BASE_URL`, `ALLOWED_ORIGINS`.

Internal Payment statuses: `initialized, pending, successful, failed, refunded`.
Internal Payout statuses: `not_eligible, eligible, requested, paid, failed, reversed`.
