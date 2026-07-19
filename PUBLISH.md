# Publishing Bahasha

Status of each piece and the exact steps to go live.

| Piece | Where | Status |
|---|---|---|
| Database | Supabase | ✅ **Done** — migrations applied, seeded, RLS on |
| Backend | Render | ⬜ Connect repo (steps below) |
| Dashboard | Vercel | ⬜ Connect repo (steps below) |
| Mobile APKs | GitHub Actions → Release | ⬜ Push a tag (steps below) |

First: **push the last local commit** (the CI workflow). The token used earlier
was revoked, so authenticate freshly — install GitHub CLI (`winget install
GitHub.cli` then `gh auth login`), then:

```
git push origin main
```

---

## 1. Database — Supabase ✅ already done

Nothing to run. Your project `ocmpvxcnobpuzehhupvh` has all 21 tables, 19 with
RLS, 9 migrations, 4 churches and 12 categories. If you ever change the schema,
`cd backend && npm run db:migrate` applies new migrations.

---

## 2. Backend — Render

1. https://dashboard.render.com → **New** → **Blueprint**.
2. Connect GitHub, pick **bahashaSDA/bahasha**. Render reads `backend/render.yaml`.
3. It will prompt for every secret marked `sync: false`. Fill them from your
   `backend/.env` (copy the values, don't paste the file):
   - `SUPABASE_URL`, `SUPABASE_SERVICE_ROLE_KEY`, `SUPABASE_ANON_KEY`,
     `SUPABASE_JWT_SECRET`
   - `DATABASE_URL` — **use the Session pooler string** (the eu-west-1 pooler,
     port 5432), same as your `.env`.
   - `CORS_ORIGINS` — set to your Vercel URL once you have it (step 3), e.g.
     `https://bahasha.vercel.app`.
   - `DARAJA_*` — leave the sandbox/placeholder values until you have real
     Safaricom credentials. `HUB_API_KEY_SECRET`, `DARAJA_CALLBACK_SECRET` —
     copy from `.env`.
4. Deploy. When it's live, note the URL, e.g.
   `https://bahasha-backend.onrender.com`.
5. Health check: open `https://<your-url>/health` → should say `"status":"ok"`.

> Note: `NODE_ENV=production` in render.yaml makes the config refuse to boot on
> sandbox Daraja. Until you have real Daraja creds, either keep those as real
> sandbox values or set `NODE_ENV=development` on Render temporarily.

---

## 3. Dashboard — Vercel

1. https://vercel.com/new → import **bahashaSDA/bahasha**.
2. **Root Directory**: set to `treasurer-dashboard`.
3. Environment variables:
   - `NEXT_PUBLIC_SUPABASE_URL` = your Supabase project URL
   - `NEXT_PUBLIC_SUPABASE_ANON_KEY` = your anon key
   - `NEXT_PUBLIC_API_BASE_URL` = the Render URL + `/api/v1`
4. Deploy. Then add the resulting Vercel origin to the backend's `CORS_ORIGINS`
   on Render and redeploy the backend.
5. A treasurer signs in at `/login`. Create treasurer accounts in Supabase →
   Authentication → Users, then add a matching row in the `treasurers` table
   (id = the auth user id, church_id = their church).

---

## 4. Mobile apps — installable APKs

The apps build in the cloud (your local network blocks two Gradle plugin hosts).

1. Push a version tag:
   ```
   git tag v0.1.0
   git push origin v0.1.0
   ```
2. GitHub → **Actions** tab → watch "Build Android APKs" run (~5–8 min).
3. When done, GitHub → **Releases** → **Bahasha v0.1.0**. Download links:
   - `bahasha-arm64.apk` — the member app (most phones)
   - `cvendor-arm64.apk` — the church hub app
4. On your phone: open the release page, tap `bahasha-arm64.apk`, allow "install
   from unknown sources", install.

To make the app talk to your live backend, run the workflow manually instead:
**Actions → Build Android APKs → Run workflow**, and set `api_base_url` to
`https://<your-render-url>/api/v1`. That bakes the backend URL into the build.

> The app is offline-first, so it installs and runs (registration, giving,
> history) even without a backend — but sync and MPESA settlement need the
> Render backend reachable, which is why the manual run with `api_base_url` is
> the one to use for a full end-to-end demo.

---

## Order that works best

1. Push commits + tag → APKs build while you do the rest.
2. Deploy backend on Render → get its URL.
3. Deploy dashboard on Vercel with the Render URL → get its URL.
4. Set `CORS_ORIGINS` on Render to the Vercel URL, redeploy backend.
5. Re-run the APK workflow with `api_base_url` = Render URL for phone-to-backend.
