# Run Vitto locally

Prerequisites: Docker Desktop running, Node 22, Flutter 3.35.6, Python 3.

## 1. Backend

```bash
npx supabase@2.121.0 start
npx supabase@2.121.0 db reset
python scripts/seed_demo_listings.py
```

- API: http://127.0.0.1:54321 · Studio (database UI): http://127.0.0.1:54323
- Emails (sign-up confirmation, password reset) are caught by Mailpit: http://127.0.0.1:54324
- Payments run in mock mode: the Pay button opens a "Test payment" dialog; no money moves.

## 2. App

```bash
cd apps/vitto_app
flutter build web --release --pwa-strategy=none --dart-define=SUPABASE_URL=http://127.0.0.1:54321 --dart-define=SUPABASE_PUBLISHABLE_KEY=sb_publishable_ACJWlzQHlZjBrEguHvfOxg_3BJgxAaH
cd ../..
python scripts/serve_web.py 5000
```

Open http://localhost:5000. (For hot reload use `flutter run -d chrome --web-port 5000` with the same `--dart-define` flags.)

The publishable key above is the fixed default of every local Supabase stack; it is not a secret. Staging/production keys come from the team secret store.

## 3. Test accounts (local only)

Password for all: `VittoTest123!`

| Email | Role |
|-------|------|
| admin@vitto.test | Admin |
| ada.ng@vitto.test | Nigeria user (has demo Listings) |
| chidi.ng@vitto.test | Nigeria user |
| koffi.bj@vitto.test | Benin user (French) |
| awa.bj@vitto.test | Benin user (French) |
| suspended@vitto.test | Suspended user |

Use two browser profiles (or a normal + private window) to act as buyer and seller at the same time.

## 4. Tests

```bash
npx supabase@2.121.0 test db                 # 62 database/RLS tests (AT-01..AT-17)
npx deno@2 test supabase/functions           # payment adapter tests
python scripts/smoke_online_flow.py          # full online Deal over the real API
cd apps/vitto_app && flutter test            # app tests
```

## Suggested manual walkthrough

1. Chidi: search "iphone" → open Ada's Listing → Make an offer.
2. Ada (other window): Inbox → counter or accept → Deal opens.
3. Either: choose **Pay online**. Chidi: Pay → "Simulate success".
4. Chidi: Show my confirmation code. Ada: enter the code → Deal completed.
5. Both: rate each other. Admin: Admin → Payments → Release payout.
6. Repeat with **Meet in person**: both press "I confirm the exchange happened".
