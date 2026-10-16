# Decision register – VITTO MVP v1.1

States: **PROPOSED** (safe to plan, not signed off) · **BLOCKER** (mock/sandbox only, production cannot launch the capability) · **APPROVED** (accepted by the team).

On 2026-10-16 the team instructed: "use the proposed / recommended methods to create the MVP". Every recommended default below that does not depend on outside parties (providers, lawyers) is therefore **APPROVED**. Individual A/B/C signatures can still be added in the last columns. Never overwrite an approved decision; add a new ADR instead.

| ID | Topic | Adopted rule | State | A | B | C |
|----|-------|--------------|-------|---|---|---|
| DEC-01 | Verification badge | Optional manual verification; badge only after admin approval; not required to list. *Built after launch-critical flows (VT-032).* | APPROVED | | | |
| DEC-02 | Phone number visibility | Optional; user explicitly opts in to public display; chat is canonical. *Built with VT-032.* | APPROVED | | | |
| DEC-03 | Fixed-price behaviour | On a fixed-price Listing the buyer sends a structured Offer equal to the price; counter-offers are not allowed; no cart | APPROVED | | | |
| DEC-04 | Inventory model | One Listing = one physical item = one successful Deal | APPROVED | | | |
| DEC-05 | Fee / commission | No commission charged; who pays provider fees still to be decided | **BLOCKER** (live checkout) | | | |
| DEC-06 | Payment / payout custody | Written provider + legal confirmation of delayed seller settlement (NG and BJ) | **BLOCKER** (live checkout / payout) | | | |
| DEC-07 | Cancellation / refunds | See matrix below | APPROVED | | | |
| DEC-08 | Cross-border | No cross-border Offers; Listing currency fixed by Listing country; no FX | APPROVED | | | |
| DEC-09 | Auth method | Email + password; email must be confirmed before signing in; no social login | APPROVED | | | |
| DEC-10 | Support | Report form + admin in-app queue; no chatbot | APPROVED | | | |
| DEC-11 | Mode-selection interim state | Deal created with `transaction_type = NULL`, status `awaiting_payment`; UI shows "Choose online or offline"; offline → `awaiting_handover` | APPROVED | | | |
| DEC-12 | Offer TTL | Pending Offers expire after 48 hours; the proposer may cancel while pending; one pending Offer per Conversation at a time | APPROVED | | | |
| DEC-13 | Handover code | Buyer generates it after payment is verified; 15 min TTL; 5 wrong attempts lock that code (buyer generates a new one) | APPROVED | | | |
| DEC-14 | Verification documents per country | Data minimisation; list to be defined with counsel | PROPOSED (needed before DEC-01 build) | | | |
| DEC-15 | Unverified sellers | Any registered User with a confirmed email can list; no limits | APPROVED | | | |
| DEC-16 | Benin provider | FedaPay tentative; adapter is a stub until sandbox access is granted | APPROVED (dev) / BLOCKER (live) | | | |
| DEC-17 | Payout recipient verification / reversal | Procedure to be written with the provider | PROPOSED (needed before live payouts) | | | |
| DEC-18 | Dispute evidence retention | Admin may view evidence uploaded by participants; retention period to be set in privacy policy | PROPOSED (needed before launch) | | | |

## DEC-07 cancellation / refund matrix (adopted)

| Deal state | Who may cancel | Effect |
|-----------|----------------|--------|
| `awaiting_payment`, no successful Payment | Buyer or Seller | Deal `cancelled`; Listing back to `active` |
| `awaiting_handover` (offline), before both confirmations | Buyer or Seller | Deal `cancelled`; Listing back to `active` |
| `paid` / `awaiting_handover` (online) | Nobody directly – raise a dispute | Admin decides; refunds are handled manually through the provider dashboard and recorded in the audit log |
| `disputed` | Admin only | Admin records `complete` (payout becomes eligible) or `cancel` (Listing back to `active`, payout not eligible, refund handled manually) |
| `completed` / `cancelled` | Nobody | Final |

Dispute response target: admin reviews within 72 hours (operational target, not enforced in code).

## Engineering decisions (not product changes)

| ID | Decision | Source |
|----|----------|--------|
| ENG-01 | Stack: Flutter Web + Riverpod + go_router + gen_l10n; Supabase (Auth, Postgres, RLS, Realtime, Storage, Edge Functions) | Part II §29 |
| ENG-02 | Prices stored as integer minor units; NGN exponent 2, XOF exponent 0 | Part II §30.1 |
| ENG-03 | Country/currency pairing enforced in DB: NG↔NGN, BJ↔XOF | Part II §30.1 |
| ENG-04 | Admin role stored in a server-only `admin_users` table, never on a user-writable profile column | Part II §33.1 |
| ENG-05 | Payments run with `MockPaymentAdapter` (PAYMENT_MODE=mock) until DEC-05/06 are approved | Part II §34.3, §46 |
| ENG-06 | Brand: white surfaces, dark blue `#0B2D6B` as the only accent, font Onest (SIL OFL). Light theme only. Avito-style layout: 5 phone tabs (Home, Favorites, Sell, Inbox, Profile); My Deals under Profile | Team request, 2026-10-16 |
| ENG-07 | Offer / Deal / confirmation / rating / admin state transitions are implemented as transactional Postgres functions (`security definer`, row locks, called by RPC) instead of Edge Functions. They are still server-side only, and keep the atomicity Part II §29.2 requires. Edge Functions are used where an external provider or secret is involved (payments, payouts) | Part II §29.2, §31.4 |
