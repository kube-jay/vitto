# Vitto

Bilingual (English / French) responsive web marketplace for Nigeria (NGN) and Benin (XOF).
One User account can both buy and sell physical products.

**Core flow:** LISTING → CHAT → OFFER → DEAL → ONLINE/OFFLINE TRANSACTION → CONFIRMATION → RATING

- Product contract: [docs/product/VITTO_MVP_Product_Definition_v1.1.docx](docs/product/VITTO_MVP_Product_Definition_v1.1.docx)
- Agent rules: [AGENTS.md](AGENTS.md)
- Decisions awaiting A/B/C sign-off: [docs/decisions/decision-register.md](docs/decisions/decision-register.md)
- Build plan and milestones: [docs/architecture/delivery-plan.md](docs/architecture/delivery-plan.md)

## Layout

```
apps/vitto_app/   Flutter Web app (Riverpod, go_router, gen_l10n)
supabase/         config, SQL migrations, Edge Functions (TypeScript/Deno), RLS tests, seed
docs/             product, architecture, contracts, decisions, runbooks, qa
.github/          CI, CODEOWNERS, issue/PR templates
scripts/          reproducible local tasks
```

## Run it locally

**Quick start on Windows:** open Docker Desktop, then double-click `start-vitto.cmd`.

Full guide with test accounts: [docs/runbooks/local-dev.md](docs/runbooks/local-dev.md). Toolchain versions: [docs/runbooks/toolchain.md](docs/runbooks/toolchain.md).

```bash
cd apps/vitto_app
flutter pub get
flutter analyze
flutter test
flutter run -d chrome
```

Backend (requires Docker Desktop running):

```bash
npx supabase@2.121.0 start
npx supabase@2.121.0 db reset
python scripts/seed_demo_listings.py
```

Copy `.env.example` to `.env` (ignored) and fill dev values. Never commit secrets.
