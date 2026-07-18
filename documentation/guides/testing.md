# Testing Guide

The riskiest logic in Bahasha — the money pipeline and the anonymity guarantee —
is tested against **real Postgres** and with **real keypairs**, not mocks.

## Backend unit tests (crypto, phone)

```bash
cd backend
npm test
```

Runs the Vitest suite. `crypto.test.ts` generates genuine Ed25519 and ECDSA
P-256 keypairs, signs the canonical payload bytes, and asserts:

- a genuine signature verifies;
- a signature over a **tampered amount** is rejected;
- a signature from a **different device's key** is rejected;
- malformed signatures and wrong key types are refused without throwing.

If any of these fail, contributions in production would be forgeable or
unverifiable — so they run keypair generation every time.

## Database invariant tests (real Postgres)

These need Docker. They spin up Postgres 15, apply all migrations against a
Supabase-compatible shim, and attack the schema's guarantees.

```bash
# from repo root, with Docker running:
docker run -d --name bahasha-pg -e POSTGRES_PASSWORD=bahasha -e POSTGRES_DB=bahasha \
  -p 55432:5432 postgres:15-alpine

cd backend/supabase
docker exec -i bahasha-pg psql -U postgres -d bahasha < test/00_supabase_shim.sql
for f in migrations/*.sql; do docker exec -i bahasha-pg psql -U postgres -d bahasha -v ON_ERROR_STOP=1 < "$f"; done
docker exec -i bahasha-pg psql -U postgres -d bahasha < test/01_invariants_test.sql
docker exec -i bahasha-pg psql -U postgres -d bahasha < test/02_ingest_rpc_test.sql
```

### `01_invariants_test.sql` (30 assertions)

- allocations must sum to the batch total (deferred constraint, checked at commit);
- idempotency: a replayed `client_uuid` is refused;
- money hygiene: zero/negative/fractional amounts, non-E.164 phones refused;
- **no shortcode, no money** — transactions blocked for unconfigured churches;
- a success without an MPESA receipt is refused;
- replay: duplicate `(device_uuid, counter)` and reused nonces refused;
- one hub per church;
- **anonymity**: a treasurer sees a secret giver as "Anonymous giver" + a stable
  pseudonym, never the name/phone; the direct routes (`users`, `transactions`)
  are RLS-denied; cross-church isolation holds; a super admin can resolve
  identities but **cannot** edit or delete the audit log.

### `02_ingest_rpc_test.sql` (14 assertions)

- the happy path: a signed 1700 payload becomes a contribution + 3 allocations,
  advancing the device counter;
- a replayed counter is refused;
- an unknown category rolls the whole transaction back atomically (counter not
  advanced);
- STK initiation → successful callback settles to `completed` with the receipt;
- a **redelivered** callback is idempotent (no double-settle);
- result `1032` marks `cancelled`, not `failed`;
- an unknown checkout id is handled gracefully.

## Typecheck

```bash
cd backend && npm run typecheck   # strict, noUncheckedIndexedAccess, exactOptionalPropertyTypes
```

## Cleanup

```bash
docker rm -f bahasha-pg
```
