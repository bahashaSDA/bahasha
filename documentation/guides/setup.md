# Setup Guide — Backend

## Prerequisites

- Node.js ≥ 20.11
- A Supabase project (free tier is fine to start)
- Safaricom Daraja credentials (sandbox to develop; production to go live)
- Docker (optional — only for running the SQL test suite locally)

## 1. Configure environment

```bash
cd backend
cp .env.example .env
```

Fill in `.env`. Every variable is documented inline. The config layer
(`src/config/env.ts`) validates on boot and **refuses to start** on any missing,
malformed, or still-placeholder value.

| Variable                     | Where to find it                                                    |
|------------------------------|---------------------------------------------------------------------|
| `SUPABASE_URL`               | Project Settings → API → Project URL (the origin, not `/rest/v1`)   |
| `SUPABASE_SERVICE_ROLE_KEY`  | Project Settings → API → `service_role` secret (server-only!)       |
| `SUPABASE_ANON_KEY`          | Project Settings → API → `anon` public                              |
| `SUPABASE_JWT_SECRET`        | Project Settings → API → JWT Settings → JWT Secret                  |
| `DATABASE_URL`               | Project Settings → Database → Connection string → URI (direct)      |
| `DARAJA_*`                   | developer.safaricom.co.ke → your app                                |
| `DARAJA_CALLBACK_SECRET`     | generate: `node -e "console.log(require('crypto').randomBytes(32).toString('hex'))"` |
| `HUB_API_KEY_SECRET`         | generate the same way                                               |

> **Never** commit `.env`, paste it into chat/tickets, or expose the
> service-role key to any client. If a secret leaks, rotate it — these move real
> money.

## 2. Install and migrate

```bash
npm install
npm run db:migrate     # applies backend/supabase/migrations/*.sql to DATABASE_URL
```

`db:migrate` is incremental and idempotent: it records applied files in
`schema_migrations` and only runs new ones. For a clean dev rebuild:

```bash
npm run db:migrate -- --reset   # DROPs the public schema first (blocked in production)
```

After migrating, your Supabase project has all tables, RLS policies, the four
launch churches, and the twelve contribution categories.

## 3. Run

```bash
npm run dev            # tsx watch, pretty logs
# or
npm run build && npm start
```

Verify:

```bash
curl http://localhost:8080/health        # { "status": "ok", "database": "ok", ... }
curl http://localhost:8080/api/v1/churches
```

## 4. Configure a church's MPESA shortcode

A church cannot receive money until its paybill is set (enforced by a DB
trigger). As a super admin, set `churches.mpesa_shortcode` for each live church.
Until then, ingest still verifies and records contributions but marks them
pending settlement.

## 5. Register a church hub (deacon device)

Hubs authenticate with an API key. Mint one for a church, store only its hash:

```sql
-- Generate a key like bhk_<43 url-safe base64 chars> in your admin tooling,
-- then insert its HMAC (see src/lib/crypto.ts hashHubKey) — never the plaintext.
```

The admin API for hub provisioning is part of the admin surface; the plaintext
key is shown to the deacon exactly once.

## Troubleshooting

| Symptom                                             | Cause / fix                                                        |
|-----------------------------------------------------|--------------------------------------------------------------------|
| Boot exits: "Invalid environment configuration"     | A required `.env` value is missing or still a placeholder.         |
| `/health` → "Could not find the table 'public.…'"   | Migrations not applied. Run `npm run db:migrate`.                  |
| `/health` → "Invalid path specified in request URL" | `SUPABASE_URL` includes `/rest/v1/`. Use the bare project origin.  |
| Daraja "not configured" in logs                     | `DARAJA_*` unset — expected in early dev; contributions stay pending. |
| Migrations fail to connect                          | `DATABASE_URL` is the placeholder or wrong password. Reset it in Supabase. |
