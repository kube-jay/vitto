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
3. In Netlify: your site → **Deploys** → drag the opened `netlify` folder (`apps/vitto_app/build/netlify`) onto the page. (New site: https://app.netlify.com/drop.)
4. Note the site address, e.g. `https://vitto-xyz.netlify.app`.

The local version (`start-vitto.cmd`) is built into a different folder and is not affected.

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

## Automatic deploys (recommended)

Once this is set up, **every change merged into `main` updates the test site by itself**: database, payment functions and website. Nobody needs Supabase or Netlify access just to ship a change. The workflow is [.github/workflows/deploy-staging.yml](../../.github/workflows/deploy-staging.yml). It only runs after the normal checks (CI) pass.

It needs **two keys**, added once by the account owner.

### 1. Create the two keys

| Key name | Where to create it |
|----------|--------------------|
| `SUPABASE_ACCESS_TOKEN` | https://supabase.com/dashboard/account/tokens → **Generate new token** → name it `github-deploy` → copy it (it is shown only once) |
| `NETLIFY_AUTH_TOKEN` | https://app.netlify.com/user/applications#personal-access-tokens → **New access token** → name it `github-deploy`, choose an expiry → copy it |

These are real passwords for your accounts. Paste them only into GitHub (step 2), never into chat, email or code.

### 2. Store them in GitHub

1. Open https://github.com/kube-jay/vitto/settings/environments → **New environment** → name it exactly `staging` → **Configure environment**.
2. Under **Environment secrets** click **Add environment secret** twice:
   - Name `SUPABASE_ACCESS_TOKEN`, value = the Supabase token.
   - Name `NETLIFY_AUTH_TOKEN`, value = the Netlify token.
3. Optional but recommended: under **Deployment branches and tags** choose *Selected branches* and add `main`, so only official code can use these keys.

### 3. Try it

Open https://github.com/kube-jay/vitto/actions → **Deploy staging** → **Run workflow** → **Run workflow**. After ~5 minutes all steps should be green and the site is updated. From then on it runs by itself after every merge.

If the keys are missing, the workflow does not fail; it just skips and shows *"Staging deploy skipped: Missing secret(s)"*.

## Updating the site by hand (if automatic deploys are not set up)

- Database changes: `npx supabase@2.121.0 db push`
- Payment function changes: `npx supabase@2.121.0 functions deploy`
- App changes: `build-for-netlify.cmd`, then drag the `netlify` folder into Netlify again
