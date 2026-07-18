-- 0005_staff_and_access.sql
-- Interactive humans: church treasurers and Bahasha platform admins.
-- Both hang off Supabase Auth; givers deliberately do not (see 0002).

-- ---------------------------------------------------------------------------
-- treasurers
-- ---------------------------------------------------------------------------
create table public.treasurers (
  id         uuid primary key references auth.users (id) on delete cascade,
  church_id  uuid not null references public.churches (id) on delete restrict,
  full_name  text not null,
  email      citext not null,
  phone      text,
  is_active  boolean not null default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),

  constraint treasurers_full_name_not_blank check (length(btrim(full_name)) > 0),
  constraint treasurers_email_format check (email ~ '^[^@\s]+@[^@\s]+\.[^@\s]+$'),
  constraint treasurers_phone_e164 check (phone is null or public.is_valid_msisdn(phone))
);

create unique index treasurers_email_key on public.treasurers (email);
create index treasurers_church_idx on public.treasurers (church_id) where is_active;

create trigger treasurers_set_updated_at
  before update on public.treasurers
  for each row execute function public.tg_set_updated_at();

-- ---------------------------------------------------------------------------
-- admins
-- ---------------------------------------------------------------------------
-- Bahasha platform staff. super_admin is the only role that may resolve a
-- secret giver's identity; every such read is logged (see 0006).
create table public.admins (
  id         uuid primary key references auth.users (id) on delete cascade,
  role       admin_role not null default 'support',
  full_name  text not null,
  email      citext not null,
  is_active  boolean not null default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),

  constraint admins_full_name_not_blank check (length(btrim(full_name)) > 0),
  constraint admins_email_format check (email ~ '^[^@\s]+@[^@\s]+\.[^@\s]+$')
);

create unique index admins_email_key on public.admins (email);
create index admins_role_idx on public.admins (role) where is_active;

create trigger admins_set_updated_at
  before update on public.admins
  for each row execute function public.tg_set_updated_at();

-- ---------------------------------------------------------------------------
-- Authorisation helpers
-- ---------------------------------------------------------------------------
-- These back every RLS policy in 0007. They are security definer so that a
-- policy can consult the staff tables without the caller needing rights on
-- them -- otherwise the policies would recurse into their own tables.
--
-- search_path is pinned on each: a security definer function with a mutable
-- search_path is a privilege-escalation hole.

create or replace function public.auth_is_super_admin()
returns boolean
language sql
stable
security definer
set search_path = public, pg_temp
as $$
  select exists (
    select 1 from public.admins
     where id = auth.uid()
       and role = 'super_admin'
       and is_active
  );
$$;

create or replace function public.auth_is_admin()
returns boolean
language sql
stable
security definer
set search_path = public, pg_temp
as $$
  select exists (
    select 1 from public.admins
     where id = auth.uid()
       and is_active
  );
$$;

-- The church a treasurer may see. Null for everyone else.
create or replace function public.auth_treasurer_church_id()
returns uuid
language sql
stable
security definer
set search_path = public, pg_temp
as $$
  select church_id from public.treasurers
   where id = auth.uid()
     and is_active;
$$;

-- The church a deacon's hub belongs to. Null for everyone else.
create or replace function public.auth_operator_church_id()
returns uuid
language sql
stable
security definer
set search_path = public, pg_temp
as $$
  select church_id from public.hub_operators
   where id = auth.uid()
     and is_active;
$$;

-- Single predicate for "may this caller read this church's finances".
create or replace function public.auth_can_read_church(p_church_id uuid)
returns boolean
language sql
stable
security definer
set search_path = public, pg_temp
as $$
  select public.auth_is_admin()
      or public.auth_treasurer_church_id() = p_church_id
      or public.auth_operator_church_id() = p_church_id;
$$;

revoke all on function public.auth_is_super_admin() from public;
revoke all on function public.auth_is_admin() from public;
revoke all on function public.auth_treasurer_church_id() from public;
revoke all on function public.auth_operator_church_id() from public;
revoke all on function public.auth_can_read_church(uuid) from public;

grant execute on function public.auth_is_super_admin() to authenticated;
grant execute on function public.auth_is_admin() to authenticated;
grant execute on function public.auth_treasurer_church_id() to authenticated;
grant execute on function public.auth_operator_church_id() to authenticated;
grant execute on function public.auth_can_read_church(uuid) to authenticated;
