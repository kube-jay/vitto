# Vitto

Bilingual (English / French) web marketplace for Nigeria (NGN) and Benin (XOF). One account can both buy and sell physical products.

**Core flow:** LISTING → CHAT → OFFER → DEAL → ONLINE / OFFLINE → CONFIRMATION → RATING

## TL;DR – where we are

- **The whole MVP flow works on a local computer, in test mode.** That covers sign-up, posting Listings with photos, search and filters, favorites, in-app chat, price Offers and counter-offers, Deals, paying online *or* meeting in person, the 6-digit handover code, disputes, reports, 1–5 star ratings and an admin area. Everything is in English and French.
- **Payments are simulated.** The Pay button shows a "Test payment" box and no money moves. A Paystack (Nigeria) connector is written but not plugged in. Benin (FedaPay) is a placeholder.
- **Automatic checks:** 62 database tests cover every rule in the spec's acceptance list (AT-01 to AT-17), alongside payment and app tests. A script also completes a full online purchase end to end.
- **Not online yet.** It runs on each person's own computer only; there is no shared website.
- **Built with** Flutter Web (the app), Supabase (database, login, photo storage and live chat) and GitHub.
- **We decided** to adopt every recommended answer in the decision register except two: fees (DEC-05) and who holds buyer money (DEC-06) stay blocked until a lawyer and the payment provider confirm. See [docs/decisions/decision-register.md](docs/decisions/decision-register.md).

## Try it on your computer

### 1. Install these once

| Tool | Get it | Check it works |
|------|--------|----------------|
| Git | https://git-scm.com/downloads | `git --version` |
| Docker Desktop | https://www.docker.com/products/docker-desktop/ | open it, wait for "Engine running" |
| Node.js 22 (LTS) | https://nodejs.org | `node --version` |
| Flutter 3.35 | https://docs.flutter.dev/get-started/install (Web only is enough) | `flutter --version` |
| Python 3 | https://www.python.org/downloads (tick "Add to PATH") | `py --version` (Windows) |

### 2. Get the code

```bash
git clone https://github.com/kube-jay/vitto.git
```

### 3. Start it

**Windows:** open Docker Desktop and wait for *Engine running*. Then open the `vitto` folder and **double-click `start-vitto.cmd`**.

- The first start downloads about 2–3 GB and builds the app, which takes 5–15 minutes. Later starts take under a minute.
- When it's ready your browser opens at **http://localhost:5000**. Keep the black window open while you use it.
- To stop, double-click `stop-vitto.cmd`. After you `git pull` new code, run `start-vitto.cmd rebuild`.

**Mac / Linux:** there's no one-click script yet. From the `vitto` folder, run:

```bash
npx supabase@2.121.0 start
python3 scripts/seed_demo_listings.py
cd apps/vitto_app
flutter build web --release --pwa-strategy=none --dart-define=SUPABASE_URL=http://127.0.0.1:54321 --dart-define=SUPABASE_PUBLISHABLE_KEY=sb_publishable_ACJWlzQHlZjBrEguHvfOxg_3BJgxAaH
cd ../..
python3 scripts/serve_web.py 5000
```

On a Mac, port 5000 is often taken by *AirPlay Receiver*. Turn it off in System Settings → General → AirDrop & Handoff.

### 4. Log in and play

Every test account uses the password **`VittoTest123!`**:

| Email | Who |
|-------|-----|
| ada.ng@vitto.test | Seller in Nigeria (already has demo Listings) |
| chidi.ng@vitto.test | Buyer in Nigeria |
| koffi.bj@vitto.test | User in Benin (French) |
| admin@vitto.test | Admin |

**A full sale:**

1. Open a normal browser window as **Chidi** and a private window (Ctrl+Shift+N) as **Ada**.
2. As Chidi, find the iPhone, tap **Make an offer**, then send it.
3. As Ada, open **Inbox**, then **Accept**.
4. Choose **Pay online**.
5. As Chidi, tap **Pay**, then **Simulate success**, then **Show my confirmation code**.
6. As Ada, type the code. The Deal is now completed, and both of you can rate each other.

**Useful local pages while it runs:**
- Database viewer (Supabase Studio): http://127.0.0.1:54323
- Emails the app "sends": http://127.0.0.1:54324

More detail: [docs/runbooks/local-dev.md](docs/runbooks/local-dev.md).

**Putting it online** (Supabase Cloud + Netlify): [docs/runbooks/hosting.md](docs/runbooks/hosting.md).

## What's left for a complete MVP

| # | Item | Who / what it needs | Rough size |
|---|------|---------------------|-----------|
| 1 | Team click-through of every screen (seller side, Deal screens, admin, French, phone) and fixing what we find | Everyone | a few days |
| 2 | Shared online test site so nobody needs a local setup | A free Supabase account + hosting/domain | ~1 day after accounts exist |
| 3 | Real Paystack test payments (Nigeria) | Paystack test key (`sk_test_…`) | a few days |
| 4 | Benin payments (FedaPay) | FedaPay access, DEC-16 | unknown until access |
| 5 | Fees and holding buyer money (DEC-05, DEC-06) | Business decision + provider and legal confirmation | outside engineering, **start now** |
| 6 | Real Terms and Privacy text | Legal review for Nigeria and Benin | outside engineering |
| 7 | Optional verification badge and public phone number (DEC-01/02) | Already decided | ~2–3 days |
| 8 | Launch hardening: monitoring, backups, admin two-factor login, automated browser tests | Engineering | ~1 week |

Taken together, the features are built, but the product isn't ready to launch. Taking real money depends on items 3–6.

## For developers

```
apps/vitto_app/   Flutter Web app (Riverpod, go_router, gen_l10n)
supabase/         SQL migrations, database rules and tests, Edge Functions (payments), seed data
docs/             product spec, decisions, contracts, runbooks
scripts/          demo data, smoke test, local web server
.github/          CI, issue/PR templates
```

- Rules for anyone (or any AI tool) changing code: [AGENTS.md](AGENTS.md)
- Product spec: [docs/product/VITTO_MVP_Product_Definition_v1.1.docx](docs/product/VITTO_MVP_Product_Definition_v1.1.docx)
- Server functions: [docs/contracts/functions.md](docs/contracts/functions.md)
- Plan and status: [docs/architecture/delivery-plan.md](docs/architecture/delivery-plan.md)
- Tests: `npx supabase@2.121.0 test db`, `npx deno@2 test supabase/functions`, `cd apps/vitto_app && flutter test`

Never commit secrets. `.env.example` lists variable names only.
