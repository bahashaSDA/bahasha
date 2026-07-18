# Bahasha Database — ERD & Design Notes

The full schema lives in [`backend/supabase/migrations`](../../backend/supabase/migrations).
This document explains the shape and the non-obvious decisions. It is verified
against real Postgres by
[`backend/supabase/test`](../../backend/supabase/test) — 30 schema invariants and
14 ingest/settlement tests.

## Entity relationships

```mermaid
erDiagram
    churches ||--o{ users : "belongs to"
    churches ||--o{ contribution_categories : "may scope"
    churches ||--|| church_hubs : "has one"
    churches ||--o{ treasurers : "employs"
    churches ||--o{ contributions : "receives"

    users ||--o{ devices : "enrols"
    users ||--o{ contributions : "gives"

    devices ||--o{ contributions : "signs"

    church_hubs ||--o{ hub_operators : "run by (deacons)"
    church_hubs ||--o{ bluetooth_payloads : "uploads"
    church_hubs ||--o{ contributions : "relays"

    contributions ||--|{ contribution_allocations : "splits into"
    contributions ||--o{ transactions : "settled by (attempts)"
    contributions ||--o| bluetooth_payloads : "originates from"

    contribution_categories ||--o{ contribution_allocations : "categorises"

    admins ||--o{ identity_reveals : "performs"
    users  ||--o{ identity_reveals : "subject of"
    users  ||--|| themes : "customises"

    auth_users ||--o| treasurers : "is"
    auth_users ||--o| admins : "is"
    auth_users ||--o| hub_operators : "is"

    churches {
        uuid id PK
        text name
        text slug UK
        text mpesa_shortcode "null until onboarded"
        text public_key "BLE encryption target"
        bool is_active
    }
    users {
        uuid id PK
        text full_name
        text phone "E.164"
        uuid church_id FK
        enum membership_status
        enum visibility "open | secret (live pref)"
        uuid client_uuid UK "offline reconcile"
    }
    devices {
        uuid id PK
        uuid user_id FK
        uuid device_uuid UK
        text public_key "trust anchor"
        bigint last_counter "replay wall"
        bool is_revoked
    }
    contributions {
        uuid id PK
        uuid client_uuid "idempotency key"
        uuid user_id FK
        uuid church_id FK
        numeric total_amount
        enum status
        enum visibility_snapshot "frozen at giving time"
    }
    contribution_allocations {
        uuid id PK
        uuid contribution_id FK
        uuid category_id FK
        numeric amount "sum == parent total (enforced)"
    }
    transactions {
        uuid id PK
        uuid contribution_id FK
        text msisdn "billed number"
        numeric amount
        int attempt "per-contribution history"
        enum status
        text mpesa_receipt_number UK
        jsonb raw_callback "reconciliation record"
    }
    bluetooth_payloads {
        uuid id PK
        uuid hub_id FK
        uuid device_uuid "not FK: forgeries kept"
        text ciphertext "forensic"
        text signature
        bigint counter
        text nonce UK
        enum status
    }
```

*`auth_users` is Supabase's `auth.users`; staff tables key off it. Givers do
**not** — they authenticate by device signature, not by login.*

## Load-bearing design decisions

### Anonymity is snapshotted, not live
`users.visibility` is the member's current preference. Analytics **never** reads
it. Each contribution freezes `visibility_snapshot` at giving time. Without this,
a member switching to "Give Openly" would retroactively expose every past secret
gift. Enforced by masking views + RLS; tested in `01_invariants_test.sql`.

### Allocations must sum to the total
A deferred constraint trigger asserts `sum(allocations) == total_amount` at
commit, from both sides (child insert and parent update). Charging one figure
and crediting another is the worst possible bug in a giving system.

### One hub per church
A unique index on `church_hubs.church_id`. Multiple deacons registering under a
church all attach to that one hub, so every offering routes to the same place.

### No shortcode, no money
A `BEFORE INSERT` trigger on `transactions` refuses any transaction for a church
with a null `mpesa_shortcode`. A fresh environment physically cannot move money
until a real paybill is configured — which is why the seed leaves shortcodes
null rather than using a placeholder.

### Replay defence is in the database
`bluetooth_payloads` has unique indexes on `(device_uuid, counter)` and on
`nonce`. Even a byte-perfect replay with a valid signature fails to insert.
Cryptography proves authenticity; the database proves freshness.

### The audit trail is immutable
`audit_logs` and `identity_reveals` have SELECT-only RLS for admins and **no**
UPDATE or DELETE policy for anyone, including super admin. Every reveal of a
secret giver's identity is itself logged, with a mandatory justification.

## Indexing

Every foreign key used in a hot read path is indexed; analytics breakdowns
(church × visibility × time, church × received_at) have composite indexes;
"in-flight" states (`pending`, `processing`, `rejected`) use partial indexes so
the common rows stay out of them. See each migration for the specific set.

## Row Level Security

RLS is enabled and FORCED on every table. The Express API uses the service-role
key (bypasses RLS by design — it performs signature verification no client may
do); the treasurer dashboard connects with the anon key and is fully governed by
the policies in `0007_rls.sql`. A bug in the API must not become a data breach,
so RLS is defence in depth, not the only defence.
