-- 0006_observability.sql
-- Audit trail, activity feed, notifications, and per-user theming.

-- ---------------------------------------------------------------------------
-- audit_logs
-- ---------------------------------------------------------------------------
-- Security-relevant events only: privilege use, identity reveals, key
-- revocations, money-affecting mutations. Append-only and never pruned by the
-- application. Kept distinct from activity_logs so the noisy product feed can
-- be aged out on its own schedule without touching the compliance record.
create table public.audit_logs (
  id            bigint generated always as identity primary key,
  -- Nullable: some events (a rejected payload from an unknown device) have no
  -- authenticated actor.
  actor_id      uuid,
  actor_type    text not null,
  action        text not null,
  entity_type   text not null,
  entity_id     uuid,
  church_id     uuid references public.churches (id) on delete set null,
  -- Structured detail. Must never carry secrets, PINs, or private keys.
  metadata      jsonb not null default '{}'::jsonb,
  ip_address    inet,
  user_agent    text,
  created_at    timestamptz not null default now(),

  constraint audit_actor_type_allowed check (
    actor_type in ('admin', 'treasurer', 'hub_operator', 'hub', 'device', 'system', 'anonymous')
  ),
  constraint audit_action_not_blank check (length(btrim(action)) > 0)
);

create index audit_logs_created_idx on public.audit_logs (created_at desc);
create index audit_logs_actor_idx on public.audit_logs (actor_id, created_at desc);
create index audit_logs_church_idx on public.audit_logs (church_id, created_at desc);
create index audit_logs_entity_idx on public.audit_logs (entity_type, entity_id);
create index audit_logs_action_idx on public.audit_logs (action, created_at desc);

comment on table public.audit_logs is
  'Append-only compliance record. No UPDATE or DELETE policy exists for any role, '
  'including super_admin -- see 0007.';

-- ---------------------------------------------------------------------------
-- identity_reveals
-- ---------------------------------------------------------------------------
-- Every time a super admin resolves a secret giver to a real name, it lands
-- here. The promise made to givers is that only Bahasha can see them; that
-- promise is only worth something if the looking-up is itself on the record.
create table public.identity_reveals (
  id          bigint generated always as identity primary key,
  admin_id    uuid not null references public.admins (id) on delete restrict,
  user_id     uuid not null references public.users (id) on delete restrict,
  church_id   uuid not null references public.churches (id) on delete restrict,
  -- Free-text justification, required by the API before the reveal resolves.
  reason      text not null,
  ip_address  inet,
  created_at  timestamptz not null default now(),

  constraint identity_reveals_reason_substantive check (length(btrim(reason)) >= 10)
);

create index identity_reveals_admin_idx on public.identity_reveals (admin_id, created_at desc);
create index identity_reveals_user_idx on public.identity_reveals (user_id, created_at desc);

-- ---------------------------------------------------------------------------
-- activity_logs
-- ---------------------------------------------------------------------------
-- Operational/product telemetry: hub came online, sync completed, upload
-- retried. Safe to age out.
create table public.activity_logs (
  id          bigint generated always as identity primary key,
  church_id   uuid references public.churches (id) on delete cascade,
  hub_id      uuid references public.church_hubs (id) on delete cascade,
  device_id   uuid references public.devices (id) on delete cascade,
  event_type  text not null,
  severity    text not null default 'info',
  message     text,
  metadata    jsonb not null default '{}'::jsonb,
  created_at  timestamptz not null default now(),

  constraint activity_severity_allowed check (severity in ('debug', 'info', 'warn', 'error')),
  constraint activity_event_type_not_blank check (length(btrim(event_type)) > 0)
);

create index activity_logs_church_created_idx on public.activity_logs (church_id, created_at desc);
create index activity_logs_hub_created_idx on public.activity_logs (hub_id, created_at desc);
create index activity_logs_severity_idx on public.activity_logs (severity, created_at desc)
  where severity in ('warn', 'error');

-- ---------------------------------------------------------------------------
-- notifications
-- ---------------------------------------------------------------------------
-- Dashboard-facing alerts for treasurers and admins.
create table public.notifications (
  id           uuid primary key default gen_random_uuid(),
  -- Recipient is an auth user (treasurer or admin), not a giver.
  recipient_id uuid not null references auth.users (id) on delete cascade,
  church_id    uuid references public.churches (id) on delete cascade,
  title        text not null,
  body         text,
  category     text not null default 'general',
  severity     text not null default 'info',
  action_url   text,
  read_at      timestamptz,
  created_at   timestamptz not null default now(),

  constraint notifications_title_not_blank check (length(btrim(title)) > 0),
  constraint notifications_severity_allowed check (severity in ('info', 'success', 'warn', 'error'))
);

-- Drives the unread badge without scanning read history.
create index notifications_recipient_unread_idx
  on public.notifications (recipient_id, created_at desc) where read_at is null;
create index notifications_recipient_created_idx
  on public.notifications (recipient_id, created_at desc);

-- ---------------------------------------------------------------------------
-- themes
-- ---------------------------------------------------------------------------
-- Per-giver appearance settings. Authored offline on-device and synced up, so
-- that a reinstall restores the look the giver chose. Defaults are the Bahasha
-- Figma palette.
create table public.themes (
  id               uuid primary key default gen_random_uuid(),
  user_id          uuid not null references public.users (id) on delete cascade,
  mode             theme_mode not null default 'system',
  primary_color    text not null default '#231F4F',
  accent_color     text not null default '#89D385',
  background_color text not null default '#D1EFBD',
  font_scale       numeric(3, 2) not null default 1.00,
  updated_at       timestamptz not null default now(),
  created_at       timestamptz not null default now(),

  constraint themes_primary_hex check (primary_color ~* '^#[0-9a-f]{6}$'),
  constraint themes_accent_hex check (accent_color ~* '^#[0-9a-f]{6}$'),
  constraint themes_background_hex check (background_color ~* '^#[0-9a-f]{6}$'),
  -- Bounded so a synced value cannot render the UI unusable.
  constraint themes_font_scale_range check (font_scale between 0.80 and 1.50)
);

create unique index themes_user_key on public.themes (user_id);

create trigger themes_set_updated_at
  before update on public.themes
  for each row execute function public.tg_set_updated_at();

-- ---------------------------------------------------------------------------
-- Audit helper
-- ---------------------------------------------------------------------------
-- Single entry point for writing audit rows from SQL and from the API's
-- service-role connection.
create or replace function public.write_audit_log(
  p_actor_id    uuid,
  p_actor_type  text,
  p_action      text,
  p_entity_type text,
  p_entity_id   uuid default null,
  p_church_id   uuid default null,
  p_metadata    jsonb default '{}'::jsonb,
  p_ip_address  inet default null,
  p_user_agent  text default null
)
returns bigint
language sql
security definer
set search_path = public, pg_temp
as $$
  insert into public.audit_logs (
    actor_id, actor_type, action, entity_type, entity_id,
    church_id, metadata, ip_address, user_agent
  )
  values (
    p_actor_id, p_actor_type, p_action, p_entity_type, p_entity_id,
    p_church_id, coalesce(p_metadata, '{}'::jsonb), p_ip_address, p_user_agent
  )
  returning id;
$$;

revoke all on function public.write_audit_log(uuid, text, text, text, uuid, uuid, jsonb, inet, text) from public;
