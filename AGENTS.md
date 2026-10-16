# VITTO v1.1 – agent contract

Before coding, read:

1. `docs/product/VITTO_MVP_Product_Definition_v1.1.docx` (Part I = product scope of record; Part II = engineering annex)
2. `docs/contracts/` (database, status and server-function contracts)
3. `docs/decisions/decision-register.md` (DEC-01 … DEC-18 and their approval state)

## Authority order

1. Part I product Sections 1–26 — never override flow, entities, in/out scope or statuses.
2. A/B/C-approved decision register and technical annex.
3. Database schema / API contracts / automated acceptance tests.
4. Source code / agent prompts — cannot introduce product behaviour.

## Hard rules

- Part I is authoritative. Never create Buyer/Seller account roles, carts or orders as replacements for Listing / Offer / Deal.
- Never remove internal chat, structured Offers (incl. counter-offers), offline Deals, the 6-digit handover code, the Payment/Payout distinction, or the completed-Deal rating gate.
- Use the official vocabulary: User, Listing, Category, Favorite, Conversation, Message, Offer, Deal, Payment, Payout, Rating, Report.
- Status names are exact:
  - Listing: `draft, active, reserved, sold, archived, suspended`
  - Offer: `pending, accepted, rejected, countered, expired, cancelled`
  - Deal: `awaiting_payment, paid, awaiting_handover, completed, cancelled, disputed`
- Only work in files listed in the assigned Issue. Do not change SQL schema, product statuses or server contracts without an approved design issue.
- All data must pass RLS / authenticated server authorization. Critical writes (offer acceptance, deal completion, payment, payout) run server-side only.
- No provider secrets or service-role keys in Flutter. No live-money deployment by an agent.
- A decision marked PROPOSED or BLOCKER is not approved. Implement behind mocks/sandbox only, and flag it.
- Out-of-scope features (Part I §21) must not be added.

## Output of every task

Post: changed files, test commands + results, new migration notes, screenshots for UI, remaining risks and PR URL.

Stop and request a human product decision for any conflict or ambiguous rule.
