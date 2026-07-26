# Bahasha — Security

© 2026 Bahasha. Developed by **calemaley**. All rights reserved.

This document records Bahasha's threat model, the protections in place, and the
findings from an adversarial (black-hat-style) review of the codebase. It is a
fintech-grade giving platform: it moves real money and holds sensitive identity
and payment data, so security is treated as a first-class requirement, not an
afterthought.

## Assets we protect
1. **Money movement** — the STK Push pipeline must never be tricked into
   charging the wrong person or the wrong amount.
2. **Payment credentials** — each church's MPESA passkey / consumer key & secret.
3. **Giver identity** — especially anonymous ("secret") givers.
4. **The audit trail** — records of who saw what.

## Attacker's-eye review — findings & mitigations

| # | Attack tried | Result |
|---|---|---|
| 1 | **PostgREST filter injection** via a crafted church-id URL param (`/churches/<inject>/categories`) | **Fixed.** Every route param that reaches a query is validated as a strict UUID first (`requireUuid`); a UUID cannot carry an injection payload. Verified against `abc,is_active.eq.false`, `1;drop table…`, etc. |
| 2 | **SQL injection** in the ingest/settlement path | **Not possible.** All DB access is parameterized (Supabase SDK / `pg` `$1` bindings). No string-built SQL. |
| 3 | **Forging a contribution** (bill a stranger's phone) over BLE | **Blocked.** Every payload is Ed25519-signed by a registered device; the backend re-verifies the signature over canonical bytes and binds device → user → msisdn before any STK Push. The hub is a relay, never a trust anchor. |
| 4 | **Replaying** a captured BLE packet | **Blocked.** Strictly-increasing per-device counter + single-use nonce, both enforced by unique DB indexes. Byte-perfect replays fail to insert. |
| 5 | **Reading another church's finances** (IDOR) as a treasurer | **Blocked.** RLS on every table + `assertCanManage`/`auth_treasurer_church_id()` scope reads to the caller's own church. Cross-church reads return zero rows (tested). |
| 6 | **De-anonymising a secret giver** | **Blocked.** Analytics read masking functions that never expose secret givers' names/phones; only a super admin can resolve an identity, and **every** reveal is written to an append-only `identity_reveals` log with a mandatory reason. |
| 7 | **Stealing payment secrets** from the database | **Mitigated.** Passkeys/consumer secrets are AES-256-GCM encrypted with a key held only in the server environment; the ciphertext is useless without it. The secret columns are revoked from `anon`/`authenticated` (verified: "permission denied"). Secrets are never returned by any API. |
| 8 | **Tampering with the audit log** (even as super admin) | **Blocked.** `audit_logs`/`identity_reveals` have SELECT-only policies and **no** UPDATE/DELETE policy for any role. |
| 9 | **Brute-forcing a hub API key** | **Blocked.** 43-char high-entropy keys, HMAC-hashed at rest, compared in constant time (`timingSafeEqual`), behind a tight rate limiter. |
| 10 | **Forging an MPESA callback** to mark a payment complete | **Mitigated.** Callback lands on an unguessable secret path checked in constant time; settlement is idempotent and matched by `checkoutRequestId`. Production should add a Safaricom source-IP allow-list at the edge. |
| 11 | **Stealing the treasurer/admin session** | **Mitigated.** Auth is a short-lived Supabase JWT (Bearer, not a cookie → no CSRF surface), verified server-side; role resolved from the staff tables, so a giver's token can't reach the dashboard API. |
| 12 | **Cross-origin abuse** of the API | **Mitigated.** CORS honours an explicit `CORS_ORIGINS` allow-list in any environment; set it to the dashboard origin in production. |
| 13 | **Memory-exhaustion / oversized bodies** | **Mitigated.** JSON body capped at 256 KB; batch ingest capped at 50 payloads; per-route rate limits. |
| 14 | **Leaking secrets in logs** | **Mitigated.** The logger redacts `authorization`, `msisdn`, `phone`, `passkey`, `privateKey`, `serviceRoleKey`, `signature`, `ciphertext`, etc. |
| 15 | **Booting misconfigured** (sandbox creds in prod) | **Blocked.** Config validates at boot and refuses to start on missing/placeholder secrets or sandbox Daraja under `NODE_ENV=production`. |

## Cryptography
- **Ed25519** for device payload signatures (verified Dart↔Node interop).
- **AES-256-GCM** (authenticated) for payment-secret encryption at rest.
- **HMAC-SHA256** for hub API-key hashing.
- Device private keys live in the Android Keystore and never leave the device.

## Dependency posture
- Backend: `npm audit` — **0 vulnerabilities**.
- Dashboard: a `sharp`/`libvips` advisory appears transitively (Next.js image
  optimiser). **Not reachable** — the dashboard uses no `next/image` and
  processes no uploaded images — and `sharp` is already at its latest release.
  Accepted as not-applicable; revisit if image handling is ever added.

## Production hardening checklist
- [ ] Set `NODE_ENV=production` once real Daraja credentials are live.
- [ ] Set `CORS_ORIGINS` to the exact dashboard origin.
- [ ] Add a Safaricom source-IP allow-list in front of the MPESA callback.
- [ ] Rotate `PAYMENT_ENCRYPTION_KEY`, `HUB_API_KEY_SECRET`,
      `DARAJA_CALLBACK_SECRET`, `SUPABASE_JWT_SECRET`; store them in the platform
      secret manager, never in the repo.
- [ ] Enable Supabase point-in-time recovery and restrict the service-role key.
- [ ] Change all seeded demo passwords before launch.

## Reporting
Found something? Contact the Bahasha team (developer: **calemaley**). Please
disclose privately before any public posting.
