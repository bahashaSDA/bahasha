-- 00_supabase_shim.sql
--
-- TEST FIXTURE ONLY -- never applied to a Supabase project.
--
-- Supabase ships an `auth` schema, an `auth.uid()` helper, and the anon /
-- authenticated / service_role roles as part of the platform. Stock Postgres
-- does not. This file recreates just enough of that surface for the migrations
-- in ../migrations to be executed and exercised against a plain Postgres
-- container in CI, so RLS policies are tested rather than assumed.
--
-- The behaviour mirrors Supabase's real implementation: auth.uid() reads the
-- `sub` claim out of the request.jwt.claims GUC, which is how the Supabase
-- connection pooler propagates the caller's identity into the session.

create schema if not exists auth;

create table if not exists auth.users (
  id            uuid primary key default gen_random_uuid(),
  email         text,
  created_at    timestamptz not null default now()
);

-- Mirrors supabase/postgres: reads the JWT claims GUC set per request.
create or replace function auth.uid()
returns uuid
language sql
stable
as $$
  select nullif(
    coalesce(
      current_setting('request.jwt.claim.sub', true),
      (nullif(current_setting('request.jwt.claims', true), '')::jsonb ->> 'sub')
    ),
    ''
  )::uuid;
$$;

create or replace function auth.role()
returns text
language sql
stable
as $$
  select coalesce(
    current_setting('request.jwt.claim.role', true),
    (nullif(current_setting('request.jwt.claims', true), '')::jsonb ->> 'role'),
    'anon'
  );
$$;

-- Platform roles. NOLOGIN: tests reach them with SET ROLE, exactly as the
-- Supabase pooler does.
do $$
begin
  if not exists (select 1 from pg_roles where rolname = 'anon') then
    create role anon nologin noinherit;
  end if;
  if not exists (select 1 from pg_roles where rolname = 'authenticated') then
    create role authenticated nologin noinherit;
  end if;
  if not exists (select 1 from pg_roles where rolname = 'service_role') then
    create role service_role nologin noinherit bypassrls;
  end if;
end
$$;

grant usage on schema public to anon, authenticated, service_role;
grant usage on schema auth to anon, authenticated, service_role;
grant select on auth.users to authenticated, service_role;
