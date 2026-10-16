# Toolchain

Pinned for the MVP (record changes here via PR):

| Tool | Version |
|------|---------|
| Flutter | 3.35.6 stable |
| Dart | 3.9.2 |
| Node | 22.x (for `npx supabase`) |
| Supabase CLI | via `npx supabase@latest` until pinned in VT-003 |
| Docker Desktop | required for local Supabase |

## Checks every developer runs

```bash
cd apps/vitto_app
flutter pub get
dart format --output=none --set-exit-if-changed .
flutter analyze
flutter test
flutter build web
```

```bash
npx supabase start
npx supabase db reset
```

Run the app against local Supabase:

```bash
flutter run -d chrome --dart-define=SUPABASE_URL=http://127.0.0.1:54321 --dart-define=SUPABASE_PUBLISHABLE_KEY=<publishable key printed by supabase start>
```

Without `--dart-define` values the app starts in offline demo mode (no backend calls).
