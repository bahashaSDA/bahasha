-- 0001_extensions_and_enums.sql
-- Foundation: extensions, enumerated domains, and shared trigger helpers.

create extension if not exists "pgcrypto";      -- gen_random_uuid(), digest(), hmac()
create extension if not exists "citext";        -- case-insensitive email

-- pg_stat_statements is deliberately not created here. It requires
-- shared_preload_libraries and is already enabled on Supabase; issuing CREATE
-- EXTENSION for it would make this migration fail on a stock Postgres and buy
-- nothing on Supabase.

-- ---------------------------------------------------------------------------
-- Enumerated types
-- ---------------------------------------------------------------------------

-- How a giver relates to the church they are giving to.
create type membership_status as enum (
  'member',            -- member of the selected church
  'visitor',           -- visiting, not a member anywhere tracked here
  'other_church_member' -- member of a different church
);

-- Visibility of a giver's identity in church-facing analytics.
-- 'open'   -> name and phone visible to that church's treasurers
-- 'secret' -> identity visible only to Bahasha super admins
create type giving_visibility as enum ('open', 'secret');

-- Lifecycle of a contribution batch.
create type contribution_status as enum (
  'pending',    -- accepted from the hub, not yet pushed to Daraja
  'processing', -- STK Push issued, awaiting user PIN / callback
  'completed',  -- callback confirmed payment
  'failed',     -- callback reported failure, or push rejected
  'cancelled',  -- user dismissed the prompt
  'expired'     -- no callback within the STK timeout window
);

-- Lifecycle of the MPESA leg specifically. Kept separate from
-- contribution_status because one contribution may be retried across
-- several STK attempts (each attempt is its own transaction row).
create type transaction_status as enum (
  'initiated',
  'pushed',
  'succeeded',
  'failed',
  'timeout',
  'reversed'
);

-- Ingest state for an encrypted packet received over BLE.
create type payload_status as enum (
  'received',   -- hub uploaded it, signature not yet checked
  'verified',   -- signature + timestamp + nonce all valid
  'rejected',   -- failed verification (see rejection_reason)
  'duplicate',  -- idempotency key already seen
  'processed'   -- promoted into a contribution
);

create type hub_status as enum ('offline', 'online', 'degraded');

create type admin_role as enum ('super_admin', 'support', 'auditor');

create type theme_mode as enum ('light', 'dark', 'system');

-- ---------------------------------------------------------------------------
-- Shared helpers
-- ---------------------------------------------------------------------------

-- Maintains updated_at on any table carrying that column.
create or replace function public.tg_set_updated_at()
returns trigger
language plpgsql
as $$
begin
  new.updated_at := now();
  return new;
end;
$$;

-- Kenyan MSISDN in E.164: +254 followed by 9 digits, first of which is 1 or 7.
-- Safaricom, Airtel and Telkom ranges all fall inside 7xx/1xx.
create or replace function public.is_valid_msisdn(p_phone text)
returns boolean
language sql
immutable
as $$
  select p_phone ~ '^\+254[17][0-9]{8}$';
$$;

comment on function public.is_valid_msisdn(text) is
  'Validates a Kenyan mobile number in strict E.164 form (+254 7XXXXXXXX / +254 1XXXXXXXX). '
  'Normalisation from 07XX / 2547XX happens at the API boundary; the database only stores E.164.';
