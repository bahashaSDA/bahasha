-- 0007_rls.sql
-- Row Level Security. Deny by default; grant narrowly.
--
-- Threat model this file defends against:
--   1. A treasurer of church A reading church B's finances.
--   2. A treasurer resolving a *secret* giver to a name or phone number.
--   3. A deacon (hub operator) reading giving analytics at all.
--   4. Any authenticated caller mutating the financial record from the client.
--   5. Anyone, including super_admin, editing or deleting the audit trail.
--
-- Note on trust boundaries: the Express API connects with the service_role key,
-- which bypasses RLS by design -- it does signature verification and Daraja
-- calls that no client may perform. RLS is what protects the treasurer
-- dashboard's *direct* Supabase connection, and is defence in depth for
-- everything else. A bug in the API must not become a data breach.

alter table public.churches                enable row level security;
alter table public.users                   enable row level security;
alter table public.devices                 enable row level security;
alter table public.contribution_categories enable row level security;
alter table public.contributions           enable row level security;
alter table public.contribution_allocations enable row level security;
alter table public.church_hubs             enable row level security;
alter table public.hub_operators           enable row level security;
alter table public.bluetooth_payloads      enable row level security;
alter table public.transactions            enable row level security;
alter table public.treasurers              enable row level security;
alter table public.admins                  enable row level security;
alter table public.audit_logs              enable row level security;
alter table public.identity_reveals        enable row level security;
alter table public.activity_logs           enable row level security;
alter table public.notifications           enable row level security;
alter table public.themes                  enable row level security;

-- Force RLS even for the tables' owner, so a mistakenly-owner-ish connection
-- does not silently sail past every policy below.
alter table public.users              force row level security;
alter table public.contributions      force row level security;
alter table public.transactions       force row level security;
alter table public.audit_logs         force row level security;
alter table public.identity_reveals   force row level security;

-- ---------------------------------------------------------------------------
-- churches
-- ---------------------------------------------------------------------------
-- The church list is public by design: the mobile apps fetch it before anyone
-- has registered or authenticated. Only non-sensitive columns are exposed --
-- see the column grants at the foot of this file.
create policy churches_select_public
  on public.churches for select
  to anon, authenticated
  using (is_active);

create policy churches_admin_all
  on public.churches for all
  to authenticated
  using (public.auth_is_super_admin())
  with check (public.auth_is_super_admin());

-- ---------------------------------------------------------------------------
-- users
-- ---------------------------------------------------------------------------
-- No treasurer policy exists here, deliberately. Treasurers reach member data
-- only through v_church_members below, which masks secret givers. Granting
-- SELECT on this table to treasurers would defeat the entire anonymity model.
create policy users_super_admin_read
  on public.users for select
  to authenticated
  using (public.auth_is_super_admin());

-- ---------------------------------------------------------------------------
-- devices
-- ---------------------------------------------------------------------------
create policy devices_super_admin_read
  on public.devices for select
  to authenticated
  using (public.auth_is_super_admin());

-- ---------------------------------------------------------------------------
-- contribution_categories
-- ---------------------------------------------------------------------------
-- Readable unauthenticated: the app needs the category list at first launch,
-- offline-first, before any registration has happened.
create policy categories_select_public
  on public.contribution_categories for select
  to anon, authenticated
  using (is_active);

create policy categories_admin_all
  on public.contribution_categories for all
  to authenticated
  using (public.auth_is_super_admin())
  with check (public.auth_is_super_admin());

-- ---------------------------------------------------------------------------
-- contributions
-- ---------------------------------------------------------------------------
-- Treasurers may read their own church's giving rows. This is safe: the row
-- carries user_id but a treasurer cannot join it to a name, because they hold
-- no SELECT on public.users. Amounts and categories are theirs to see; who
-- gave secretly is not.
create policy contributions_treasurer_read
  on public.contributions for select
  to authenticated
  using (public.auth_treasurer_church_id() = church_id);

create policy contributions_admin_read
  on public.contributions for select
  to authenticated
  using (public.auth_is_admin());

-- No INSERT/UPDATE/DELETE policy for any role. Contributions originate from a
-- signature-verified BLE payload processed by the API under service_role.
-- There is no legitimate path for a client to write one.

-- ---------------------------------------------------------------------------
-- contribution_allocations
-- ---------------------------------------------------------------------------
create policy allocations_read_via_parent
  on public.contribution_allocations for select
  to authenticated
  using (
    exists (
      select 1 from public.contributions c
       where c.id = contribution_id
         and (public.auth_is_admin() or public.auth_treasurer_church_id() = c.church_id)
    )
  );

-- ---------------------------------------------------------------------------
-- transactions
-- ---------------------------------------------------------------------------
-- msisdn lives on this table, so a blanket treasurer SELECT would leak the
-- phone number of a secret giver. Treasurers are held to the masked view
-- v_church_transactions instead.
create policy transactions_admin_read
  on public.transactions for select
  to authenticated
  using (public.auth_is_admin());

-- ---------------------------------------------------------------------------
-- church_hubs / hub_operators
-- ---------------------------------------------------------------------------
-- api_key_hash is excluded by column grant below; a deacon may see their hub's
-- status, never its credential.
create policy hubs_operator_read
  on public.church_hubs for select
  to authenticated
  using (
    public.auth_operator_church_id() = church_id
    or public.auth_treasurer_church_id() = church_id
  );

create policy hubs_admin_all
  on public.church_hubs for all
  to authenticated
  using (public.auth_is_super_admin())
  with check (public.auth_is_super_admin());

create policy hub_operators_self_read
  on public.hub_operators for select
  to authenticated
  using (id = auth.uid() or public.auth_is_admin());

create policy hub_operators_self_update
  on public.hub_operators for update
  to authenticated
  using (id = auth.uid())
  with check (id = auth.uid() and hub_id = (select hub_id from public.hub_operators where id = auth.uid()));

-- ---------------------------------------------------------------------------
-- bluetooth_payloads
-- ---------------------------------------------------------------------------
-- Ciphertext and signatures are forensic material; only platform staff read
-- them. A deacon sees upload counts through the API, not the raw packets.
create policy payloads_admin_read
  on public.bluetooth_payloads for select
  to authenticated
  using (public.auth_is_admin());

-- ---------------------------------------------------------------------------
-- treasurers / admins
-- ---------------------------------------------------------------------------
create policy treasurers_self_read
  on public.treasurers for select
  to authenticated
  using (id = auth.uid() or public.auth_is_admin());

create policy treasurers_self_update
  on public.treasurers for update
  to authenticated
  using (id = auth.uid())
  -- A treasurer may edit their profile but must not reassign themselves to
  -- another church -- that would be self-service access to someone else's books.
  with check (
    id = auth.uid()
    and church_id = (select t.church_id from public.treasurers t where t.id = auth.uid())
  );

create policy treasurers_admin_all
  on public.treasurers for all
  to authenticated
  using (public.auth_is_super_admin())
  with check (public.auth_is_super_admin());

create policy admins_self_read
  on public.admins for select
  to authenticated
  using (id = auth.uid() or public.auth_is_super_admin());

-- Only a super admin may mint or alter admins, and role changes are audited by
-- the API. No self-update policy: an admin must not promote themselves.
create policy admins_super_admin_all
  on public.admins for all
  to authenticated
  using (public.auth_is_super_admin())
  with check (public.auth_is_super_admin());

-- ---------------------------------------------------------------------------
-- audit_logs / identity_reveals
-- ---------------------------------------------------------------------------
-- SELECT only, for admins only. No INSERT policy (writes go through
-- write_audit_log under service_role), and pointedly no UPDATE or DELETE
-- policy for anyone. An audit trail a super admin can rewrite is not one.
create policy audit_logs_admin_read
  on public.audit_logs for select
  to authenticated
  using (public.auth_is_admin());

create policy identity_reveals_admin_read
  on public.identity_reveals for select
  to authenticated
  using (public.auth_is_super_admin());

-- ---------------------------------------------------------------------------
-- activity_logs
-- ---------------------------------------------------------------------------
create policy activity_logs_church_read
  on public.activity_logs for select
  to authenticated
  using (church_id is not null and public.auth_can_read_church(church_id));

create policy activity_logs_admin_read
  on public.activity_logs for select
  to authenticated
  using (public.auth_is_admin());

-- ---------------------------------------------------------------------------
-- notifications
-- ---------------------------------------------------------------------------
create policy notifications_recipient_read
  on public.notifications for select
  to authenticated
  using (recipient_id = auth.uid());

-- Marking as read is the only client-side mutation permitted.
create policy notifications_recipient_update
  on public.notifications for update
  to authenticated
  using (recipient_id = auth.uid())
  with check (recipient_id = auth.uid());

-- ---------------------------------------------------------------------------
-- themes
-- ---------------------------------------------------------------------------
-- Themes belong to givers, who hold no Supabase session. They sync through the
-- API under service_role. Admin read exists for support triage only.
create policy themes_admin_read
  on public.themes for select
  to authenticated
  using (public.auth_is_admin());

-- ---------------------------------------------------------------------------
-- Masking views
-- ---------------------------------------------------------------------------
-- These run with the definer's rights (security_invoker is off by default), so
-- they can read base tables the caller cannot, and hand back only what the
-- caller has earned. Every one of them is security_barrier: without it the
-- planner may push a caller-supplied WHERE clause underneath the mask and leak
-- the very column being hidden through a timing or error-message side channel.

-- Members of a church, with secret givers reduced to an opaque token.
create or replace view public.v_church_members
with (security_barrier = true) as
  select
    u.id,
    u.church_id,
    u.membership_status,
    u.visibility,
    u.registered_at,
    case
      when u.visibility = 'open' or public.auth_is_super_admin() then u.full_name
      else 'Anonymous giver'
    end as full_name,
    case
      when u.visibility = 'open' or public.auth_is_super_admin() then u.phone
      else null
    end as phone
  from public.users u
  where public.auth_is_super_admin()
     or public.auth_treasurer_church_id() = u.church_id;

-- Giving rows joined to identity, masked the same way. This is the view the
-- treasurer dashboard's transaction table reads.
create or replace view public.v_church_contributions
with (security_barrier = true) as
  select
    c.id,
    c.church_id,
    c.total_amount,
    c.status,
    c.visibility_snapshot,
    c.received_at,
    c.processed_at,
    case
      when c.visibility_snapshot = 'open' or public.auth_is_super_admin() then u.full_name
      else 'Anonymous giver'
    end as giver_name,
    case
      when c.visibility_snapshot = 'open' or public.auth_is_super_admin() then u.phone
      else null
    end as giver_phone,
    case
      when c.visibility_snapshot = 'open' or public.auth_is_super_admin() then u.membership_status
      else null
    end as membership_status,
    -- Stable per-giver pseudonym. Lets a treasurer see that one anonymous
    -- giver gave twelve times without learning who they are. Salted with the
    -- church id so the same person is not correlatable across congregations.
    case
      when c.visibility_snapshot = 'secret'
        then 'G-' || upper(substr(encode(digest(u.id::text || c.church_id::text, 'sha256'), 'hex'), 1, 8))
      else null
    end as giver_pseudonym
  from public.contributions c
  join public.users u on u.id = c.user_id
  where public.auth_is_admin()
     or public.auth_treasurer_church_id() = c.church_id;

-- Transactions with the MSISDN masked for secret givers and truncated for
-- everyone below super admin. A treasurer reconciling against an MPESA
-- statement needs the last four digits; they do not need the whole number.
create or replace view public.v_church_transactions
with (security_barrier = true) as
  select
    t.id,
    t.contribution_id,
    t.church_id,
    t.amount,
    t.status,
    t.attempt,
    t.mpesa_receipt_number,
    -- Daraja correlation id. Not sensitive, and a treasurer needs it to trace a
    -- disputed payment through a Safaricom statement or a support ticket.
    t.checkout_request_id,
    t.transaction_date,
    t.result_code,
    t.result_desc,
    t.created_at,
    case
      when public.auth_is_super_admin() then t.msisdn
      when c.visibility_snapshot = 'secret' then null
      else '+254' || repeat('*', 5) || right(t.msisdn, 4)
    end as msisdn
  from public.transactions t
  join public.contributions c on c.id = t.contribution_id
  where public.auth_is_admin()
     or public.auth_treasurer_church_id() = t.church_id;

-- ---------------------------------------------------------------------------
-- Grants
-- ---------------------------------------------------------------------------
-- Default-deny at the privilege layer too, so a table added later without a
-- considered grant is unreachable rather than accidentally public.
revoke all on all tables in schema public from anon, authenticated;

-- Church list: only the columns the apps genuinely need. public_key is how a
-- device encrypts to the church and is fine to expose; api keys and shortcodes
-- are not.
grant select (id, name, slug, city, county, latitude, longitude, public_key, is_active)
  on public.churches to anon, authenticated;

grant select (id, church_id, code, name, description, color_hex, sort_order,
              fixed_amount, percentage_hint, is_active)
  on public.contribution_categories to anon, authenticated;

grant select on public.contributions            to authenticated;
grant select on public.contribution_allocations to authenticated;
grant select on public.transactions             to authenticated;
grant select on public.bluetooth_payloads       to authenticated;
grant select on public.activity_logs            to authenticated;
grant select on public.audit_logs               to authenticated;
grant select on public.identity_reveals         to authenticated;
grant select on public.users                    to authenticated;
grant select on public.devices                  to authenticated;
grant select on public.themes                   to authenticated;

-- api_key_hash withheld: a deacon reads their hub's health, never its secret.
grant select (id, church_id, name, status, last_heartbeat_at, last_upload_at,
              app_version, is_active, created_at)
  on public.church_hubs to authenticated;

grant select, update on public.notifications to authenticated;
grant select, update on public.treasurers    to authenticated;
grant select, update on public.hub_operators to authenticated;
grant select on public.admins to authenticated;

grant select on public.v_church_members      to authenticated;
grant select on public.v_church_contributions to authenticated;
grant select on public.v_church_transactions to authenticated;

-- Sequences: nothing client-side inserts, so nothing needs them.
revoke all on all sequences in schema public from anon, authenticated;
