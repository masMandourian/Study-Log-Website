# STUDYLOG
A dark, responsive study accountability website with a study timer, manual study logs, goals, weekly reports, and a private-by-link read-only public page.

## Your free setup
- **Website hosting:** GitHub Pages (free)
- **Database and authentication:** Supabase Free
- **Domain:** Free GitHub Pages address (`https://YOUR-USERNAME.github.io/studylog/`)

Your Supabase project URL and browser-safe publishable key are already filled into `config.js`.

## 1. Publish with GitHub Pages
1. Sign in at https://github.com/ and create a new **public** repository named `studylog` (public repositories work with GitHub Pages on the free plan).
2. Extract this ZIP file on your computer.
3. Open the `studylog` folder inside the extracted folder.
4. Upload these files to the **root** of the GitHub repository: `index.html`, `styles.css`, `app.js`, `config.js`, and `supabase-schema.sql`. You may also upload this README.
5. In the repository, open **Settings → Pages**.
6. Under **Build and deployment**, choose **Deploy from a branch**, select `main` and `/(root)`, then save.
7. Wait for GitHub Pages to publish. Your site address will be shown on the Pages settings screen.

## 2. Configure Supabase authentication URLs
After GitHub Pages gives you the website URL:
1. Open Supabase → **Authentication → URL Configuration**.
2. Set **Site URL** to your GitHub Pages website URL.
3. Add that same URL to **Redirect URLs**. You can also add `http://localhost:8000/**` for local testing.
4. Save changes.

If email confirmation is enabled, signing up sends a confirmation email. Confirm it before signing in. The confirmation link must return to your published site, which is why the URL configuration matters.

## 3. Create your account
1. Open your published website.
2. Choose **Create an account**.
3. Enter your email, password, and display name.
4. Confirm your email if Supabase asks you to, then sign in.
5. Set your daily and weekly goals and start the timer or add a manual log.
6. Use **Share progress** to copy your read-only sharing link for family and friends.

## 4. Local testing (optional)
A local web server is needed because the app uses JavaScript modules. From this folder, run:

```bash
python -m http.server 8000
```

Then open http://localhost:8000. Add `http://localhost:8000/**` to Supabase Redirect URLs if you test account confirmation locally.

## Privacy and security
- The `sb_publishable_...` key in `config.js` is designed to be public in browser apps. It is not an admin key.
- Never put a Supabase `service_role` or secret key in any website file or GitHub repository.
- Database access is restricted by Row Level Security. Public viewers receive only the fields returned by the `get_public_dashboard` database function.
- Anyone who has your personal share URL can view the public progress page and study logs. Treat that link like a password. It does not let visitors edit records or reveal your email.
- Do not store sensitive personal information in study notes if you plan to share your page.

## Included features
- Email/password sign-up and sign-in.
- Persistent timer (survives refreshes and tab changes in the same browser).
- Timer-based and manual study logs with subject, notes, and question count.
- Daily and weekly study goals.
- Weekly chart, weekly report, and subject-time breakdown.
- Public read-only sharing page.

## Troubleshooting
- **"Almost ready" / configuration message:** check that `config.js` is in the repository root beside `index.html` and contains your project URL and publishable key.
- **Email confirmation doesn't return to the site:** check Supabase Authentication → URL Configuration and add your exact GitHub Pages URL to Redirect URLs.
- **Sign-up works but profile is missing:** confirm the SQL schema ran successfully in the same Supabase project.
- **Share link unavailable:** confirm the SQL script created `get_public_dashboard(text)` and that the `share` query parameter is intact.

Supabase and GitHub Pages free tiers have limits and are subject to their providers' terms.

## Updating an existing STUDYLOG deployment

For the editable study logs, free-text subjects, and customizable named countdown, upload the updated site files to the root of your existing GitHub repository (overwrite the existing files). Then run `migration-goal-countdown.sql` once in Supabase SQL Editor. This adds `goal_name` and `goal_date` to your profile and updates the read-only sharing RPC so viewers can see the countdown.

The countdown is fully customizable: choose any title and any target date. The public sharing page displays it too. Study subjects are now free text rather than a fixed dropdown. Existing logs can be edited from the Recent sessions list.
