# Put Vitto online (test site): Supabase Cloud + Netlify

Netlify only serves the web pages. The backend (database, login, photos, chat, payment functions) runs on **Supabase Cloud**. Both have free plans.

Payments stay in **mock mode** (no real money) until DEC-05/06 are approved.

## 1. Create the Supabase project (once, in the browser)

1. Sign in at https://supabase.com/dashboard → **New project**.
2. Name `vitto-staging`. Pick a region close to West Africa, e.g. *Europe (Frankfurt/London)*, or *South Africa* if offered.
3. Set a **database password** and keep it in a password manager. It is needed in step 2.
4. When the project is ready, note its **Project ID** (in the project URL: `https://supabase.com/dashboard/project/<project-id>`).

## 2. Send the database and payment functions to the cloud (from the project folder)

```bash
npx supabase@2.121.0 login
npx supabase@2.121.0 link --project-ref <project-id>
npx supabase@2.121.0 db push
npx supabase@2.121.0 functions deploy
```

- `login` opens the browser to approve.
- `link` asks for the database password.
- `db push` creates every table, rule, category and region. It does **not** create the local test accounts.

## 3. Build and upload the website

1. Double-click **`build-for-netlify.cmd`**.
2. Paste the **Project URL** and **Publishable key** when asked. Find them in *Project Settings → API Keys*. Never paste the secret / service_role key.
3. In Netlify: your site → **Deploys** → drag the opened `web` folder onto the page. (New site: https://app.netlify.com/drop.)
4. Note the site address, e.g. `https://vitto-xyz.netlify.app`.

Run `start-vitto.cmd` afterwards as usual; it rebuilds the local version automatically.

## 4. Connect the two (Supabase dashboard)

1. **Authentication → URL Configuration**:
   - Site URL = your Netlify address.
   - Add `https://<your-site>.netlify.app/**` to *Redirect URLs*.
2. **Edge Functions → Secrets** (or run `npx supabase@2.121.0 secrets set ...`):
   - `ALLOWED_ORIGINS=https://<your-site>.netlify.app`
   - `APP_BASE_URL=https://<your-site>.netlify.app`
   - `PAYMENT_MODE=mock`
3. **Email on the free plan** sends only a few emails per hour. For team testing either:
   - turn off *Authentication → Sign In / Providers → Email → Confirm email*, or
   - add your own SMTP (Authentication → Emails → SMTP).
   Turn confirmation back on before real users arrive (DEC-09).

## 5. Make an admin

Sign up on the site with your own email, then in **SQL Editor** run:

```sql
insert into private.admin_users (user_id)
select id from auth.users where email = 'you@example.com';
```

## Updating the site later

- Database changes: `npx supabase@2.121.0 db push`
- Payment function changes: `npx supabase@2.121.0 functions deploy`
- App changes: `build-for-netlify.cmd`, then drag the `web` folder into Netlify again
