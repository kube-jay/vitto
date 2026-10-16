# Try Vitto on your computer

## Start it (the easy way)

1. Open **Docker Desktop** and wait until it says *Engine running*.
2. In File Explorer, open `D:\Vitto Project` and **double-click `start-vitto.cmd`**.
   - From a cmd window instead: `cd /d "D:\Vitto Project"` then `start-vitto.cmd`.
   - Always run it from the project folder (double-clicking does that for you).
3. Wait for the black window to finish. Your browser opens at **http://localhost:5000**.
4. **Keep the black window open** while you use Vitto. Close it to stop the website.

When you are done for the day, double-click **`stop-vitto.cmd`** to stop the backend (your test data is kept).

| Situation | What to run |
|-----------|-------------|
| Normal start | `start-vitto.cmd` |
| You pulled new code from GitHub | `start-vitto.cmd rebuild` |
| You want fresh demo data (deletes everything you created) | `start-vitto.cmd reset` |
| Stop everything | `stop-vitto.cmd` |

## Test accounts

Password for all of them: `VittoTest123!`

| Email | Who |
|-------|-----|
| ada.ng@vitto.test | Seller in Nigeria – already has 2 Listings (iPhone, sofa) |
| chidi.ng@vitto.test | Buyer in Nigeria |
| koffi.bj@vitto.test | User in Benin (app in French) |
| admin@vitto.test | Admin |

You can also create your own account with "Create account". The confirmation email does not really get sent; open **http://127.0.0.1:54324** to read it and click the link.

## Walkthrough: one purchase from start to finish

A sale needs two people, so use **two browser windows**: a normal window and a private window (Chrome: Ctrl+Shift+N, Edge: Ctrl+Shift+P). Each window can be signed in as a different person.

**Window A = Chidi (buyer)**, **Window B = Ada (seller)**.

1. **A – find and offer.** Sign in as Chidi. Search "iphone", open the iPhone 12, tap **Make an offer**, type `290000`, **Send offer**. You land in the chat with your offer card showing *Pending*.
2. **B – respond.** Sign in as Ada. Open **Inbox** (bottom bar) → the iPhone conversation. On Chidi's offer tap **Accept** (or **Counter** with another price; then Chidi accepts in window A). After accepting, the Deal page opens.
3. **Either window – choose how to finish.** On the Deal page pick **Pay online** (or **Meet in person**, see below).
4. **A – pay.** Open the Deal (Profile → My Deals, or the banner in the chat). Tap **Pay ₦…**. A *Test payment* box appears; tap **Simulate success**. No real money moves.
5. **A – give the code.** Tap **Show my confirmation code** and confirm. A 6-digit code appears for 15 minutes.
6. **B – enter the code.** On Ada's Deal page, type the 6 digits and tap **Confirm handover**. The Deal becomes *Completed*.
7. **Both – rate.** Each side gives 1–5 stars. Ratings show on the public profiles.
8. **Admin (optional).** Sign in as admin@vitto.test → Profile → **Admin** → *Payments & payouts* → **Release payout**.

**Meet in person instead of paying online:** at step 3 choose **Meet in person**; then in both windows tap **I confirm the exchange happened**. When both have confirmed, the Deal completes and you can rate each other.

**Other things to try:** post your own Listing with photos (**Sell**), switch language (the 文A icon), favorites (heart), "Problem with confirmation" and "Report a problem" on a paid Deal, and the Admin area (suspend a Listing, resolve a dispute).

## For developers

```bash
npx supabase@2.121.0 test db                 # 62 database/RLS tests (AT-01..AT-17)
npx deno@2 test supabase/functions           # payment adapter tests
py scripts/smoke_online_flow.py              # full online Deal over the real API
cd apps/vitto_app && flutter test            # app tests
```

Hot reload instead of the built version: `cd apps/vitto_app` then `flutter run -d chrome --web-port 5000 --dart-define=SUPABASE_URL=http://127.0.0.1:54321 --dart-define=SUPABASE_PUBLISHABLE_KEY=sb_publishable_ACJWlzQHlZjBrEguHvfOxg_3BJgxAaH`. The publishable key is the fixed default of every local Supabase stack, not a secret. Database UI (Studio): http://127.0.0.1:54323.
