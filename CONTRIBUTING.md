# How to make a change to Vitto

A short guide for everyone on the team.

## The big picture

```
your computer ──► GitHub (branch + pull request) ──► teammate reviews ──► merge into main
                                                                              │
                                              automatic, ~10 minutes          ▼
                                              test site updates: https://meek-mermaid-09a8b3.netlify.app
```

- **`main` is the official version.** Whatever is on `main` is what runs on the test site.
- Nobody changes `main` directly. Every change arrives through a **pull request (PR)**, which means "here is my change, please check it".
- When a PR is **merged**, GitHub updates the test site automatically: database, payment functions and website. You don't touch Supabase or Netlify yourself.

## What you need

| You want to… | You need |
|---|---|
| Fix text, docs or a translation | A GitHub account, invited to the repo. That's all. |
| Change the app and try it first | A GitHub account, plus the tools in the README ("Try it on your computer"): Git, Docker Desktop, Node.js, Flutter, Python |
| Manage Supabase / Netlify / deploy keys | Only the project owner. Everyone else never needs these accounts. |

## A. Small change in the browser (text, docs, translations)

1. Open the file on https://github.com/kube-jay/vitto. English/French texts are in `apps/vitto_app/l10n/app_en.arb` and `app_fr.arb`.
2. Click the **pencil icon** (Edit) and make your change.
3. Click **Commit changes…** → choose **"Create a new branch… and start a pull request"** → **Propose changes** → **Create pull request**.
4. Ask a teammate to review (see section C).

## B. Real change on your computer

Do this once: `git clone https://github.com/kube-jay/vitto.git`

Then, for **every** change:

```bash
git switch main
git pull
git switch -c my-short-change-name
```

The last line makes your own branch. Use a name like `fix-offer-button` or `feat-VT-032-phone`.

1. **Make the change.** Edit the files yourself, or open the folder in Claude Code (or another AI tool) and describe what you want. It reads [AGENTS.md](AGENTS.md) and follows the project rules.
2. **Try it locally:** `start-vitto.cmd rebuild` (Windows), then check it at http://localhost:5000.
3. **Save and send it:**

   ```bash
   git add -A
   git commit -m "Short description of what you changed"
   git push -u origin my-short-change-name
   ```

4. Git prints a link (`https://github.com/kube-jay/vitto/pull/new/...`). Open it and click **Create pull request**. In the description, say what you changed and how you tested it.
5. Wait for the automatic checks on the PR. Green ✓ means good. If one turns red ✗, click it to see why, fix it, then commit and push again. The PR updates by itself.

> Prefer buttons to commands? **GitHub Desktop** (https://desktop.github.com) does the same steps: *Current branch → New branch*, *Commit*, *Push*, *Create Pull Request*.

## C. Reviewing a teammate's change

1. Open the PR on GitHub → **Files changed** tab and read what changed.
2. If you can, run it: `git fetch`, `git switch their-branch-name`, then `start-vitto.cmd rebuild`.
3. Click **Review changes** → **Approve**, or **Request changes** with a comment.
4. When it's approved and all checks are green, click **Merge pull request** (choose *Squash and merge*), then **Delete branch**.
5. About 10 minutes later the change is live on the test site. Watch progress under **Actions → Deploy staging**.

## Rules

- **Never work directly on `main`.** One task = one branch = one PR.
- **Run `git pull` on `main` before starting** something new, so you have everyone's latest work.
- **Database changes:** never edit an existing file in `supabase/migrations/`. Add a new file with the next number (e.g. `000011_my_change.sql`). Those changes reach the shared test database automatically.
- **Never put passwords or secret keys in the code.** The automatic scanner blocks them.
- **Bug fixes and polish** need one reviewer. **Product changes** (new features, different rules) must be agreed by A, B and C first and written in [docs/decisions/decision-register.md](docs/decisions/decision-register.md).
- **If something breaks after a merge:** open the merged PR on GitHub and click **Revert**. That creates a PR that undoes it; merge that.
