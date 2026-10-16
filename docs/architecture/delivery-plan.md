# Delivery plan – locked from Product Definition v1.1

## Boundaries

**In scope (Part I §20):** Nigeria + Benin · EN/FR UI · one account buys and sells · profiles & reputation · create/edit/archive/sell Listings · 1–8 images · categories · search, filters, sorting · favorites · internal text chat · Offers & counter-offers · Deals · online mode · offline meetup mode · online payment integration (provider abstraction) · 6-digit handover code · basic disputes · two-party confirmation · 1–5 star ratings · admin moderation · responsive web.

**Out of scope (Part I §21):** Vitto delivery/drivers · logistics tracking · auctions/bidding · subscriptions · promoted Listings · AI recommendations/moderation · advanced KYC · automated dispute resolution · voice/video calls, voice notes, file sharing in chat · social features · auto-translation · currency conversion · native Android/iOS release · Next.js storefront.

**Production gates:** no live money until DEC-05 and DEC-06 are approved and provider/legal confirmation is on file. Online flow is built and tested against the mock adapter and provider sandboxes only.

## Milestones (acceptance-driven, not calendar-driven)

| Gate | Scope | Done means | Status |
|------|-------|-----------|--------|
| M0 | Repo, docs, Flutter shell, Supabase skeleton, CI | Everyone can clone/build/test; rules and open decisions visible | **In progress** |
| M1 | Auth, profile, country, locale | Register once, sign in, choose en/fr, create profile | Next |
| M2 | Categories, Listings, images, discovery, favorites | One User lists; another discovers via filters | |
| M3 | Conversations, realtime chat, Offers/counters | Two users exchange messages and structured Offers | Needs DEC-03, DEC-12 |
| M4 | Atomic Offer acceptance → Deal, mode selection | One reserved Listing / Deal under race | Needs DEC-04, DEC-11 |
| M5 | Offline confirmation, handover code, disputes, reports, ratings | Offline happy path + dispute fallback + ratings | Needs DEC-07, DEC-13 |
| M6 | PaymentAdapter, Paystack sandbox, FedaPay feasibility, ledger, payout gate | Verified sandbox payment, no premature payout | Needs provider sandbox keys; live needs DEC-05/06/16 |
| M7 | Admin ops, FR QA, security, hardening | All AT-01…AT-20 pass, gates signed | |

First demonstrable slice: register → create Listing → find Listing → chat → offer → accept → Deal.

## Repository status after this scaffold

- `apps/vitto_app` – Flutter Web shell with routes for every Part II §28.2 screen (placeholders), EN/FR l10n, country config, money formatting, canonical status enums.
- `supabase/migrations` – 000001 extensions, 000002 profiles/categories/admin with RLS. Later migrations are written per milestone.
- `supabase/functions/_shared` – error/response contract and `PaymentAdapter` interface + mock.
- `.github` – CI (format, analyze, test, build web, migration lint), templates, CODEOWNERS placeholder.
