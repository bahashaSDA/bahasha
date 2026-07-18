-- 0002_core_identity.sql
-- Churches, givers, and the devices that sign contribution payloads.

-- ---------------------------------------------------------------------------
-- churches
-- ---------------------------------------------------------------------------
-- Churches are fetched by the mobile apps at runtime so new congregations can
-- be onboarded without shipping an app update.
create table public.churches (
  id             uuid primary key default gen_random_uuid(),
  name           text not null,
  slug           text not null,
  -- Safaricom paybill/till the church's money settles into. Nullable while a
  -- church is being onboarded; enforced before any STK Push (see 0004).
  mpesa_shortcode text,
  city           text,
  county         text,
  latitude       double precision,
  longitude      double precision,
  -- Church-level RSA/ECC public key. Devices encrypt payloads to this key so
  -- that a packet captured off the air is unreadable to anyone but the hub.
  public_key     text,
  is_active      boolean not null default true,
  created_at     timestamptz not null default now(),
  updated_at     timestamptz not null default now(),

  constraint churches_name_not_blank check (length(btrim(name)) > 0),
  constraint churches_slug_format check (slug ~ '^[a-z0-9]+(-[a-z0-9]+)*$'),
  constraint churches_shortcode_format check (
    mpesa_shortcode is null or mpesa_shortcode ~ '^[0-9]{5,7}$'
  ),
  constraint churches_latitude_range check (
    latitude is null or latitude between -90 and 90
  ),
  constraint churches_longitude_range check (
    longitude is null or longitude between -180 and 180
  )
);

create unique index churches_slug_key on public.churches (slug);
create index churches_is_active_idx on public.churches (is_active) where is_active;

create trigger churches_set_updated_at
  before update on public.churches
  for each row execute function public.tg_set_updated_at();

-- ---------------------------------------------------------------------------
-- users
-- ---------------------------------------------------------------------------
-- A giver. Registered once on-device, then synced. Note there is deliberately
-- no auth.users linkage: givers never authenticate interactively. Their
-- identity is proven by the device keypair in public.devices, not a password.
create table public.users (
  id                uuid primary key default gen_random_uuid(),
  full_name         text not null,
  phone             text not null,
  church_id         uuid not null references public.churches (id) on delete restrict,
  membership_status membership_status not null,
  -- Current visibility preference. Toggleable from Account settings; the value
  -- in force at the moment of giving is snapshotted onto the contribution so
  -- that flipping this later cannot retroactively de-anonymise past giving.
  visibility        giving_visibility not null default 'open',
  -- Client-generated id, lets an offline device create a user and reconcile
  -- once it syncs without risking a duplicate row.
  client_uuid       uuid not null,
  registered_at     timestamptz not null default now(),
  last_seen_at      timestamptz,
  created_at        timestamptz not null default now(),
  updated_at        timestamptz not null default now(),

  constraint users_full_name_not_blank check (length(btrim(full_name)) > 0),
  constraint users_phone_e164 check (public.is_valid_msisdn(phone))
);

-- One identity per phone number per church. A person may legitimately give to
-- more than one church, so phone alone is not unique.
create unique index users_phone_church_key on public.users (phone, church_id);
create unique index users_client_uuid_key on public.users (client_uuid);
create index users_church_id_idx on public.users (church_id);
create index users_visibility_idx on public.users (church_id, visibility);

create trigger users_set_updated_at
  before update on public.users
  for each row execute function public.tg_set_updated_at();

comment on column public.users.visibility is
  'Live preference only. Analytics must read contributions.visibility_snapshot, never this column.';

-- ---------------------------------------------------------------------------
-- devices
-- ---------------------------------------------------------------------------
-- The trust anchor of the BLE protocol. Each install generates a keypair,
-- keeps the private key in the platform keystore, and registers the public key
-- here. The backend verifies every payload signature against this table before
-- it will trigger an STK Push -- which is what stops a bystander from crafting
-- a packet carrying someone else's phone number.
create table public.devices (
  id             uuid primary key default gen_random_uuid(),
  user_id        uuid not null references public.users (id) on delete cascade,
  -- Stable per-install identifier, surfaced in the BLE payload header.
  device_uuid    uuid not null,
  -- SPKI DER, base64. Ed25519 by default (see 0004 for the verification path).
  public_key     text not null,
  key_algorithm  text not null default 'ed25519',
  platform       text,
  model          text,
  app_version    text,
  -- Monotonic counter: the backend rejects any payload whose counter is not
  -- strictly greater than the last accepted one. Replay protection that does
  -- not depend on clock accuracy.
  last_counter   bigint not null default 0,
  is_revoked     boolean not null default false,
  revoked_at     timestamptz,
  revoked_reason text,
  registered_at  timestamptz not null default now(),
  last_seen_at   timestamptz,
  created_at     timestamptz not null default now(),
  updated_at     timestamptz not null default now(),

  constraint devices_key_algorithm_allowed check (key_algorithm in ('ed25519', 'ecdsa-p256')),
  constraint devices_public_key_not_blank check (length(btrim(public_key)) > 0),
  constraint devices_last_counter_non_negative check (last_counter >= 0),
  constraint devices_revoked_consistency check (
    (is_revoked and revoked_at is not null) or (not is_revoked and revoked_at is null)
  )
);

create unique index devices_device_uuid_key on public.devices (device_uuid);
create index devices_user_id_idx on public.devices (user_id);
-- Signature verification looks a device up by uuid and requires it live; this
-- partial index keeps that hot path off the revoked rows entirely.
create index devices_active_idx on public.devices (device_uuid) where not is_revoked;

create trigger devices_set_updated_at
  before update on public.devices
  for each row execute function public.tg_set_updated_at();

comment on table public.devices is
  'Device keypairs. A payload is only honoured if signed by a non-revoked device whose '
  'user_id owns the phone number in the payload. Never let the hub vouch for identity.';
