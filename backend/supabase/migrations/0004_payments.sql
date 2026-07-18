-- 0004_payments.sql
-- Church hubs (CVendor devices), the BLE ingest audit trail, and the MPESA leg.

-- ---------------------------------------------------------------------------
-- church_hubs
-- ---------------------------------------------------------------------------
-- One logical hub per church. Several deacons may register CVendor installs
-- under the same church; they all attach to this one hub, so every offering in
-- that congregation routes to the same place regardless of who is on duty.
create table public.church_hubs (
  id              uuid primary key default gen_random_uuid(),
  church_id       uuid not null references public.churches (id) on delete cascade,
  name            text not null,
  status          hub_status not null default 'offline',
  -- Hubs authenticate to the backend with this credential. Only the digest is
  -- stored -- a database leak must not yield a working hub credential.
  api_key_hash    text not null,
  api_key_prefix  text not null,  -- first 8 chars, so a deacon can identify their key
  last_heartbeat_at timestamptz,
  last_upload_at  timestamptz,
  app_version     text,
  is_active       boolean not null default true,
  created_at      timestamptz not null default now(),
  updated_at      timestamptz not null default now(),

  constraint hubs_name_not_blank check (length(btrim(name)) > 0),
  constraint hubs_api_key_prefix_len check (length(api_key_prefix) = 8)
);

-- Exactly one hub per church: the "shared hub" rule from the spec, enforced in
-- the schema rather than trusted to application code.
create unique index hubs_church_key on public.church_hubs (church_id);
create unique index hubs_api_key_hash_key on public.church_hubs (api_key_hash);
create index hubs_status_idx on public.church_hubs (status);

create trigger hubs_set_updated_at
  before update on public.church_hubs
  for each row execute function public.tg_set_updated_at();

-- Deferred from 0003: contributions.hub_id could not reference this table
-- until it existed.
alter table public.contributions
  add constraint contributions_hub_id_fkey
  foreign key (hub_id) references public.church_hubs (id) on delete set null;

create index contributions_hub_idx on public.contributions (hub_id);

-- ---------------------------------------------------------------------------
-- hub_operators
-- ---------------------------------------------------------------------------
-- The deacons who run a hub. These are real interactive logins, so they hang
-- off Supabase Auth.
create table public.hub_operators (
  id         uuid primary key references auth.users (id) on delete cascade,
  hub_id     uuid not null references public.church_hubs (id) on delete cascade,
  church_id  uuid not null references public.churches (id) on delete cascade,
  full_name  text not null,
  phone      text,
  is_active  boolean not null default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),

  constraint hub_operators_phone_e164 check (
    phone is null or public.is_valid_msisdn(phone)
  )
);

create index hub_operators_hub_idx on public.hub_operators (hub_id);
create index hub_operators_church_idx on public.hub_operators (church_id);

create trigger hub_operators_set_updated_at
  before update on public.hub_operators
  for each row execute function public.tg_set_updated_at();

-- ---------------------------------------------------------------------------
-- bluetooth_payloads
-- ---------------------------------------------------------------------------
-- Append-only record of every packet a hub uploaded, verified or not. This is
-- the forensic trail: if a giver disputes a charge, or someone floods the hub
-- with forged packets, the evidence is here. Rejected packets are retained
-- deliberately -- they are the attack signal.
create table public.bluetooth_payloads (
  id               uuid primary key default gen_random_uuid(),
  hub_id           uuid not null references public.church_hubs (id) on delete restrict,
  church_id        uuid not null references public.churches (id) on delete restrict,
  -- Claimed by the packet header, resolved against public.devices during
  -- verification. Not a FK: a forged packet may name a device that does not
  -- exist, and we still want the rejected row on file.
  device_uuid      uuid not null,
  -- Client UUID doubling as the idempotency key across the whole pipeline.
  idempotency_key  uuid not null,
  -- The packet exactly as received: base64 ciphertext under the church key.
  ciphertext       text not null,
  -- Detached signature over the ciphertext, made by the device private key.
  signature        text not null,
  -- Monotonic replay counter asserted against devices.last_counter.
  counter          bigint not null,
  -- Single-use nonce from the challenge-response handshake with the hub.
  nonce            text not null,
  status           payload_status not null default 'received',
  rejection_reason text,
  contribution_id  uuid references public.contributions (id) on delete set null,
  byte_size        integer,
  received_at      timestamptz not null default now(),
  verified_at      timestamptz,
  created_at       timestamptz not null default now(),

  constraint payloads_counter_non_negative check (counter >= 0),
  constraint payloads_rejection_reason_present check (
    (status = 'rejected') = (rejection_reason is not null)
  )
);

-- The replay wall. A given device may use a given counter exactly once, ever.
-- Even if an attacker replays a byte-perfect packet with a valid signature,
-- this index refuses the second insert.
create unique index payloads_device_counter_key
  on public.bluetooth_payloads (device_uuid, counter);
-- Nonces are single-use across the deployment.
create unique index payloads_nonce_key on public.bluetooth_payloads (nonce);
create index payloads_hub_received_idx on public.bluetooth_payloads (hub_id, received_at desc);
create index payloads_church_received_idx on public.bluetooth_payloads (church_id, received_at desc);
create index payloads_idempotency_idx on public.bluetooth_payloads (idempotency_key);
-- Powers the abuse dashboard; partial so the common (verified) rows stay out.
create index payloads_rejected_idx
  on public.bluetooth_payloads (church_id, received_at desc) where status = 'rejected';

comment on table public.bluetooth_payloads is
  'Append-only. Never UPDATE a ciphertext or signature -- rejected rows are evidence.';

-- ---------------------------------------------------------------------------
-- transactions
-- ---------------------------------------------------------------------------
-- The MPESA leg. One row per STK Push attempt, so a contribution retried after
-- a timeout keeps a full attempt history rather than overwriting itself.
create table public.transactions (
  id                  uuid primary key default gen_random_uuid(),
  contribution_id     uuid not null references public.contributions (id) on delete restrict,
  church_id           uuid not null references public.churches (id) on delete restrict,
  -- Snapshotted from the payload: the number actually billed. Kept here so the
  -- financial record stands alone even if the user row later changes.
  msisdn              text not null,
  amount              numeric(12, 2) not null,
  attempt             integer not null default 1,
  status              transaction_status not null default 'initiated',
  -- Daraja correlation ids, returned by the STK Push call.
  merchant_request_id text,
  checkout_request_id text,
  -- Populated by the callback on success.
  mpesa_receipt_number text,
  transaction_date    timestamptz,
  result_code         integer,
  result_desc         text,
  -- Verbatim callback body. Non-negotiable for reconciliation against
  -- Safaricom statements when a figure is disputed.
  raw_callback        jsonb,
  initiated_at        timestamptz not null default now(),
  completed_at        timestamptz,
  created_at          timestamptz not null default now(),
  updated_at          timestamptz not null default now(),

  constraint transactions_amount_positive check (amount > 0),
  constraint transactions_amount_whole check (amount = trunc(amount)),
  constraint transactions_msisdn_e164 check (public.is_valid_msisdn(msisdn)),
  constraint transactions_attempt_positive check (attempt >= 1),
  constraint transactions_completed_consistency check (
    (status in ('succeeded', 'failed', 'timeout', 'reversed')) = (completed_at is not null)
  ),
  -- A success is meaningless without the receipt that proves it.
  constraint transactions_receipt_on_success check (
    status <> 'succeeded' or mpesa_receipt_number is not null
  )
);

-- Callbacks arrive keyed by checkout_request_id and Safaricom will redeliver.
-- Unique so a redelivered callback updates the one row instead of forking it.
create unique index transactions_checkout_request_key
  on public.transactions (checkout_request_id) where checkout_request_id is not null;
create unique index transactions_receipt_key
  on public.transactions (mpesa_receipt_number) where mpesa_receipt_number is not null;
create unique index transactions_contribution_attempt_key
  on public.transactions (contribution_id, attempt);
create index transactions_church_created_idx on public.transactions (church_id, created_at desc);
create index transactions_status_idx on public.transactions (status)
  where status in ('initiated', 'pushed');

create trigger transactions_set_updated_at
  before update on public.transactions
  for each row execute function public.tg_set_updated_at();

-- ---------------------------------------------------------------------------
-- Guard: never push money for a church with nowhere to settle it
-- ---------------------------------------------------------------------------
create or replace function public.tg_assert_church_has_shortcode()
returns trigger
language plpgsql
as $$
declare
  v_shortcode text;
begin
  select mpesa_shortcode into v_shortcode
    from public.churches
   where id = new.church_id;

  if v_shortcode is null then
    raise exception
      'church % has no mpesa_shortcode; refusing to create a transaction', new.church_id
      using errcode = 'check_violation';
  end if;

  return new;
end;
$$;

create trigger transactions_require_church_shortcode
  before insert on public.transactions
  for each row execute function public.tg_assert_church_has_shortcode();
