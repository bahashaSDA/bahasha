# Deployment Guide

Three managed platforms, one per tier. Nothing here requires a server you patch.

## Database — Supabase

1. Create a project (region closest to Kenya, e.g. `eu-central-1`).
2. Grab the values listed in [setup.md](setup.md) §1.
3. Apply the schema from your machine (or CI):
   ```bash
   cd backend && npm run db:migrate
   ```
   Prefer CI for production so the applied migration set is auditable. The
   runner records applied files in `schema_migrations`, so redeploys are safe.
4. Confirm RLS: Supabase → Authentication → Policies should show policies on
   every table. The API uses the service-role key and bypasses RLS by design;
   the dashboard uses the anon key and is governed by these policies.

## Backend — Render

The blueprint is [`backend/render.yaml`](../../backend/render.yaml).

1. New → Blueprint → connect the repo. Render reads `render.yaml`.
2. Fill every `sync: false` secret in the dashboard (see the file's comments).
   `CORS_ORIGINS` must be the exact dashboard origin — no wildcard (the config
   layer rejects a wildcard in production).
3. `DARAJA_CALLBACK_URL` must be
   `https://<your-service>.onrender.com/api/v1/mpesa/callback/<DARAJA_CALLBACK_SECRET>`
   and registered as the callback URL in your Daraja app.
4. Deploy. Health check is `/health/live`; readiness (`/health`) confirms DB
   reachability.

### Going live with Daraja

- The config layer refuses to boot if `NODE_ENV=production` while
  `DARAJA_ENV=sandbox`, so you cannot accidentally run live traffic against the
  sandbox.
- Complete Safaricom's Go-Live (production shortcode, passkey, IP allowlisting
  of Render's egress IPs for the callback).
- Pair the callback path secret with a Safaricom source-IP allowlist at the
  platform edge; the secret path alone is a stopgap, not the whole defence.

## Dashboard — Vercel

1. Import the repo, root directory `treasurer-dashboard`.
2. Environment: `NEXT_PUBLIC_SUPABASE_URL`, `NEXT_PUBLIC_SUPABASE_ANON_KEY`,
   and `NEXT_PUBLIC_API_BASE_URL` (the Render backend). Only the **anon** key
   goes to the browser — never the service-role key.
3. Deploy. Add the resulting origin to the backend's `CORS_ORIGINS`.

## Mobile apps — Play Store

1. `bahasha-mobile` and `cvendor-mobile` build as Android app bundles:
   ```bash
   flutter build appbundle --release
   ```
2. Sign with an upload key (`android/key.properties`, gitignored).
3. Point the app at the production API base URL via `--dart-define`.

## Post-deploy checklist

See [production-checklist.md](production-checklist.md).
