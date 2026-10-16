# Delivery plan – locked from Product Definition v1.1

## Boundaries

**In scope (Part I §20):** Nigeria + Benin · EN/FR UI · one account buys and sells · profiles & reputation · create/edit/archive/sell Listings · 1–8 images · categories · search, filters, sorting · favorites · internal text chat · Offers & counter-offers · Deals · online mode · offline meetup mode · online payment integration (provider abstraction) · 6-digit handover code · basic disputes · two-party confirmation · 1–5 star ratings · admin moderation · responsive web.

**Out of scope (Part I §21):** Vitto delivery/drivers · logistics tracking · auctions/bidding · subscriptions · promoted Listings · AI recommendations/moderation · advanced KYC · automated dispute resolution · voice/video calls, voice notes, file sharing in chat · social features · auto-translation · currency conversion · native Android/iOS release · Next.js storefront.

**Team setup:** A/B/C roles are not split yet; everyone works across all areas. GitHub handles go into CODEOWNERS later.

**Production gates:** no live money until DEC-05 and DEC-06 are approved and provider/legal confirmation is on file. Online flow is built and tested against the mock adapter and provider sandboxes only.

## Milestones (acceptance-driven, not calendar-driven)

| Gate | Scope | Status (2026-10-16) |
|------|-------|---------------------|
| M0 | Repo, docs, Flutter shell, Supabase, CI | Done |
| M1 | Auth (email + password, confirmed email), profile, country, locale | Built |
| M2 | Categories, Listings, 1–8 images, search/filters/sort, favorites | Built |
| M3 | Conversations, realtime chat, Offers / counters / cancel | Built |
| M4 | Atomic Offer acceptance → Deal, online/offline choice | Built; race tested (AT-06) |
| M5 | Offline confirmations, handover code, confirmation problem, disputes, reports, ratings | Built |
| M6 | PaymentAdapter, mock checkout, Paystack adapter, ledger, payout gate | Built in mock mode; Paystack needs sandbox keys; FedaPay is a stub (DEC-16) |
| M7 | Admin console, FR, security tests | Admin built; launch hardening open (below) |

## Verified

- 62 database tests (RLS + every state transition, AT-01..AT-17)
- 7 payment-adapter tests (signatures, amount mapping)
- `scripts/smoke_online_flow.py`: full online Deal over the real local API
- 14 Flutter tests (EN/FR switch, phone width, auth guard, money, statuses)
- Manual browser check: browse, search, Listing page, offer dialog, live offer card and chat

## Open before production launch

- DEC-05 fees and DEC-06 custody/payout approval (live money stays off until then)
- Paystack sandbox keys; FedaPay access (DEC-16)
- Real Terms / Privacy text after legal review (placeholders in app)
- DEC-01/02 optional verification badge and phone display (VT-032)
- Hosted staging project, domain, monitoring/alerts, backups + restore drill (VT-035)
- Browser E2E suite across devices (VT-036) and a full manual French QA pass (VT-033)
- Admin MFA before live financial operations
