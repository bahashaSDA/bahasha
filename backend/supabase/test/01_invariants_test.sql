-- 01_invariants_test.sql
--
-- Adversarial tests for the schema's load-bearing guarantees. Each block does
-- something the system must refuse, and fails loudly if the database allows it.
-- Run against a throwaway container (see documentation/guides/testing.md).

\set ON_ERROR_STOP on
\timing off

-- Assertion helper: raises unless the condition holds.
create or replace function pg_temp.assert(p_ok boolean, p_label text)
returns void language plpgsql as $$
begin
  if not p_ok then
    raise exception 'ASSERTION FAILED: %', p_label;
  end if;
  raise notice '  pass: %', p_label;
end;
$$;

-- Runs a statement and asserts it raises. Used for the "must refuse" cases.
create or replace function pg_temp.assert_raises(p_sql text, p_label text)
returns void language plpgsql as $$
begin
  begin
    execute p_sql;
  exception when others then
    raise notice '  pass: % (rejected: %)', p_label, replace(sqlerrm, E'\n', ' ');
    return;
  end;
  raise exception 'ASSERTION FAILED: % -- statement was ALLOWED but must be refused', p_label;
end;
$$;

-- ---------------------------------------------------------------------------
-- Fixtures
-- ---------------------------------------------------------------------------
\echo '=== fixtures ==='

insert into auth.users (id, email) values
  ('11111111-1111-1111-1111-111111111111', 'treasurer.zetech@example.org'),
  ('22222222-2222-2222-2222-222222222222', 'treasurer.jkuat@example.org'),
  ('33333333-3333-3333-3333-333333333333', 'super@bahasha.co.ke'),
  ('44444444-4444-4444-4444-444444444444', 'deacon.zetech@example.org')
on conflict (id) do nothing;

-- Give Zetech a shortcode so it can settle; JKUAT deliberately has none, to
-- prove the "no shortcode, no money" guard below.
update public.churches set mpesa_shortcode = '174379' where slug = 'zetech-university-sda';

insert into public.treasurers (id, church_id, full_name, email) values
  ('11111111-1111-1111-1111-111111111111',
   (select id from public.churches where slug = 'zetech-university-sda'),
   'Zetech Treasurer', 'treasurer.zetech@example.org'),
  ('22222222-2222-2222-2222-222222222222',
   (select id from public.churches where slug = 'jkuat-sda'),
   'JKUAT Treasurer', 'treasurer.jkuat@example.org');

insert into public.admins (id, role, full_name, email) values
  ('33333333-3333-3333-3333-333333333333', 'super_admin', 'Bahasha Super Admin', 'super@bahasha.co.ke');

-- Two givers at Zetech: one giving openly, one giving in secret.
insert into public.users (id, full_name, phone, church_id, membership_status, visibility, client_uuid) values
  ('aaaaaaaa-0000-0000-0000-000000000001', 'Grace Wanjiru', '+254712345678',
   (select id from public.churches where slug = 'zetech-university-sda'),
   'member', 'open',   'cccccccc-0000-0000-0000-000000000001'),
  ('aaaaaaaa-0000-0000-0000-000000000002', 'Peter Otieno',  '+254798765432',
   (select id from public.churches where slug = 'zetech-university-sda'),
   'member', 'secret', 'cccccccc-0000-0000-0000-000000000002');

insert into public.devices (id, user_id, device_uuid, public_key) values
  ('bbbbbbbb-0000-0000-0000-000000000001', 'aaaaaaaa-0000-0000-0000-000000000001',
   'dddddddd-0000-0000-0000-000000000001', 'MCowBQYDK2VwAyEAopenkeyopenkeyopenkeyopenkeyopenkey00='),
  ('bbbbbbbb-0000-0000-0000-000000000002', 'aaaaaaaa-0000-0000-0000-000000000002',
   'dddddddd-0000-0000-0000-000000000002', 'MCowBQYDK2VwAyEAsecretkeysecretkeysecretkeysecretke0=');

-- ---------------------------------------------------------------------------
-- 1. Allocations must sum to the batch total
-- ---------------------------------------------------------------------------
\echo '=== 1. allocation sum integrity ==='

-- The spec's worked example: 1000 + 500 + 200 = 1700. Must commit.
begin;
  insert into public.contributions
    (id, client_uuid, user_id, church_id, device_id, total_amount, visibility_snapshot, device_timestamp)
  values
    ('eeeeeeee-0000-0000-0000-000000000001', 'cccccccc-1111-0000-0000-000000000001',
     'aaaaaaaa-0000-0000-0000-000000000001',
     (select id from public.churches where slug = 'zetech-university-sda'),
     'bbbbbbbb-0000-0000-0000-000000000001', 1700, 'open', now());

  insert into public.contribution_allocations (contribution_id, category_id, amount)
  select 'eeeeeeee-0000-0000-0000-000000000001', id, v.amt
    from (values ('tithe', 1000), ('conference_evangelism', 500), ('church_building', 200)) as v(code, amt)
    join public.contribution_categories c on c.code = v.code and c.church_id is null;
commit;
select pg_temp.assert(
  (select count(*) from public.contributions where id = 'eeeeeeee-0000-0000-0000-000000000001') = 1,
  'balanced 1700 contribution commits');

-- Same shape, but the lines sum to 1699. Must be refused.
--
-- The constraint is DEFERRABLE INITIALLY DEFERRED, so it only fires at COMMIT.
-- assert_raises cannot help here: PL/pgSQL forbids BEGIN/COMMIT inside EXECUTE,
-- so wrapping this in the generic helper caught PL/pgSQL's own complaint and
-- reported a pass without ever testing the constraint. Instead this runs the
-- inserts inside a subtransaction and forces the deferred trigger to fire early
-- with SET CONSTRAINTS ALL IMMEDIATE -- which is a real check, at the real
-- constraint, with the real error.
create or replace function pg_temp.try_unbalanced()
returns text language plpgsql as $$
begin
  insert into public.contributions
    (id, client_uuid, user_id, church_id, device_id, total_amount, visibility_snapshot, device_timestamp)
  values
    ('eeeeeeee-0000-0000-0000-000000000009', 'cccccccc-1111-0000-0000-000000000009',
     'aaaaaaaa-0000-0000-0000-000000000001',
     (select id from public.churches where slug = 'zetech-university-sda'),
     'bbbbbbbb-0000-0000-0000-000000000001', 1700, 'open', now());

  insert into public.contribution_allocations (contribution_id, category_id, amount)
  select 'eeeeeeee-0000-0000-0000-000000000009', id, 1699
    from public.contribution_categories where code = 'tithe' and church_id is null;

  set constraints all immediate;
  return 'ALLOWED';
exception when others then
  return 'REJECTED: ' || replace(sqlerrm, E'\n', ' ');
end;
$$;

do $$
declare v_result text;
begin
  v_result := pg_temp.try_unbalanced();
  if v_result not like 'REJECTED:%' then
    raise exception 'ASSERTION FAILED: unbalanced allocations were ALLOWED (%)', v_result;
  end if;
  -- Prove it tripped the *sum* check, not some incidental error.
  if v_result not like '%does not match%' then
    raise exception 'ASSERTION FAILED: unbalanced allocations rejected for the WRONG reason: %', v_result;
  end if;
  raise notice '  pass: unbalanced allocations (1699 vs 1700) are refused (%)', v_result;
end;
$$;

-- ---------------------------------------------------------------------------
-- 2. Idempotency: the same packet uploaded twice must not double-charge
-- ---------------------------------------------------------------------------
\echo '=== 2. idempotency ==='

select pg_temp.assert_raises($sql$
  insert into public.contributions
    (client_uuid, user_id, church_id, device_id, total_amount, visibility_snapshot, device_timestamp)
  values
    ('cccccccc-1111-0000-0000-000000000001', 'aaaaaaaa-0000-0000-0000-000000000001',
     (select id from public.churches where slug = 'zetech-university-sda'),
     'bbbbbbbb-0000-0000-0000-000000000001', 1700, 'open', now());
$sql$, 'replayed client_uuid for same user is refused');

-- ---------------------------------------------------------------------------
-- 3. Money hygiene
-- ---------------------------------------------------------------------------
\echo '=== 3. money constraints ==='

select pg_temp.assert_raises($sql$
  insert into public.contributions
    (client_uuid, user_id, church_id, device_id, total_amount, visibility_snapshot, device_timestamp)
  values (gen_random_uuid(), 'aaaaaaaa-0000-0000-0000-000000000001',
     (select id from public.churches where slug = 'zetech-university-sda'),
     'bbbbbbbb-0000-0000-0000-000000000001', 0, 'open', now());
$sql$, 'zero-amount contribution is refused');

select pg_temp.assert_raises($sql$
  insert into public.contributions
    (client_uuid, user_id, church_id, device_id, total_amount, visibility_snapshot, device_timestamp)
  values (gen_random_uuid(), 'aaaaaaaa-0000-0000-0000-000000000001',
     (select id from public.churches where slug = 'zetech-university-sda'),
     'bbbbbbbb-0000-0000-0000-000000000001', -500, 'open', now());
$sql$, 'negative contribution is refused');

select pg_temp.assert_raises($sql$
  insert into public.contributions
    (client_uuid, user_id, church_id, device_id, total_amount, visibility_snapshot, device_timestamp)
  values (gen_random_uuid(), 'aaaaaaaa-0000-0000-0000-000000000001',
     (select id from public.churches where slug = 'zetech-university-sda'),
     'bbbbbbbb-0000-0000-0000-000000000001', 100.50, 'open', now());
$sql$, 'fractional shillings refused (Daraja takes integers only)');

select pg_temp.assert_raises($sql$
  insert into public.users (full_name, phone, church_id, membership_status, client_uuid)
  values ('Bad Number', '0712345678',
    (select id from public.churches where slug = 'zetech-university-sda'), 'member', gen_random_uuid());
$sql$, 'non-E.164 phone refused (07.. must be normalised at the API edge)');

-- ---------------------------------------------------------------------------
-- 4. No shortcode, no money
-- ---------------------------------------------------------------------------
\echo '=== 4. settlement guard ==='

insert into public.contributions
  (id, client_uuid, user_id, church_id, device_id, total_amount, visibility_snapshot, device_timestamp)
values
  ('eeeeeeee-0000-0000-0000-000000000002', 'cccccccc-1111-0000-0000-000000000002',
   'aaaaaaaa-0000-0000-0000-000000000002',
   (select id from public.churches where slug = 'zetech-university-sda'),
   'bbbbbbbb-0000-0000-0000-000000000002', 500, 'secret', now());
insert into public.contribution_allocations (contribution_id, category_id, amount)
select 'eeeeeeee-0000-0000-0000-000000000002', id, 500
  from public.contribution_categories where code = 'welfare' and church_id is null;

-- JKUAT has no shortcode configured; a transaction against it must be refused.
select pg_temp.assert_raises($sql$
  insert into public.transactions (contribution_id, church_id, msisdn, amount)
  values ('eeeeeeee-0000-0000-0000-000000000002',
     (select id from public.churches where slug = 'jkuat-sda'), '+254798765432', 500);
$sql$, 'transaction for a church with no mpesa_shortcode is refused');

-- Zetech has one, so this must succeed.
insert into public.transactions (contribution_id, church_id, msisdn, amount, checkout_request_id)
values ('eeeeeeee-0000-0000-0000-000000000002',
   (select id from public.churches where slug = 'zetech-university-sda'),
   '+254798765432', 500, 'ws_CO_TEST_0001');
select pg_temp.assert(
  (select count(*) from public.transactions where checkout_request_id = 'ws_CO_TEST_0001') = 1,
  'transaction for a configured church succeeds');

select pg_temp.assert_raises($sql$
  update public.transactions set status = 'succeeded', completed_at = now()
   where checkout_request_id = 'ws_CO_TEST_0001';
$sql$, 'marking a transaction succeeded without an MPESA receipt is refused');

-- ---------------------------------------------------------------------------
-- 5. BLE replay protection
-- ---------------------------------------------------------------------------
\echo '=== 5. replay protection ==='

insert into public.church_hubs (id, church_id, name, api_key_hash, api_key_prefix)
values ('ffffffff-0000-0000-0000-000000000001',
  (select id from public.churches where slug = 'zetech-university-sda'),
  'Zetech Hub', 'hash_placeholder_not_a_real_key', 'bhk_1234');

insert into public.bluetooth_payloads
  (hub_id, church_id, device_uuid, idempotency_key, ciphertext, signature, counter, nonce)
values ('ffffffff-0000-0000-0000-000000000001',
  (select id from public.churches where slug = 'zetech-university-sda'),
  'dddddddd-0000-0000-0000-000000000001', gen_random_uuid(), 'ct1', 'sig1', 1, 'nonce-0001');

select pg_temp.assert_raises($sql$
  insert into public.bluetooth_payloads
    (hub_id, church_id, device_uuid, idempotency_key, ciphertext, signature, counter, nonce)
  values ('ffffffff-0000-0000-0000-000000000001',
    (select id from public.churches where slug = 'zetech-university-sda'),
    'dddddddd-0000-0000-0000-000000000001', gen_random_uuid(), 'ct1', 'sig1', 1, 'nonce-0002');
$sql$, 'replayed (device_uuid, counter) is refused');

select pg_temp.assert_raises($sql$
  insert into public.bluetooth_payloads
    (hub_id, church_id, device_uuid, idempotency_key, ciphertext, signature, counter, nonce)
  values ('ffffffff-0000-0000-0000-000000000001',
    (select id from public.churches where slug = 'zetech-university-sda'),
    'dddddddd-0000-0000-0000-000000000002', gen_random_uuid(), 'ct2', 'sig2', 5, 'nonce-0001');
$sql$, 'reused nonce is refused');

-- One hub per church, even if several deacons register.
select pg_temp.assert_raises($sql$
  insert into public.church_hubs (church_id, name, api_key_hash, api_key_prefix)
  values ((select id from public.churches where slug = 'zetech-university-sda'),
    'Second Zetech Hub', 'another_hash', 'bhk_5678');
$sql$, 'a second hub for the same church is refused');

-- ---------------------------------------------------------------------------
-- 6. RLS: the anonymity guarantee
-- ---------------------------------------------------------------------------
\echo '=== 6. RLS + anonymity ==='

-- NOTE: SET LOCAL is a no-op outside a transaction block (psql autocommits
-- each statement), which silently left the session as the owning superuser and
-- made these assertions test nothing. Session-level SET is correct here. Claims
-- are set before SET ROLE so the GUC write happens while still privileged.

-- --- as the Zetech treasurer -------------------------------------------------
reset role;
set request.jwt.claims = '{"sub":"11111111-1111-1111-1111-111111111111","role":"authenticated"}';
set role authenticated;

select pg_temp.assert(
  (select count(*) from public.v_church_contributions) = 2,
  'Zetech treasurer sees both Zetech contributions');

select pg_temp.assert(
  (select giver_name from public.v_church_contributions
    where id = 'eeeeeeee-0000-0000-0000-000000000001') = 'Grace Wanjiru',
  'open giver name IS visible to their treasurer');

select pg_temp.assert(
  (select giver_name from public.v_church_contributions
    where id = 'eeeeeeee-0000-0000-0000-000000000002') = 'Anonymous giver',
  'SECRET giver name is NOT visible to their treasurer');

select pg_temp.assert(
  (select giver_phone from public.v_church_contributions
    where id = 'eeeeeeee-0000-0000-0000-000000000002') is null,
  'SECRET giver phone is NOT visible to their treasurer');

select pg_temp.assert(
  (select giver_pseudonym from public.v_church_contributions
    where id = 'eeeeeeee-0000-0000-0000-000000000002') like 'G-%',
  'secret giver gets a stable pseudonym instead of a name');

-- The direct route to the same data must be shut, or the view is theatre.
select pg_temp.assert(
  (select count(*) from public.users) = 0,
  'treasurer cannot read public.users directly (RLS denies all rows)');

select pg_temp.assert(
  (select count(*) from public.transactions) = 0,
  'treasurer cannot read public.transactions directly (msisdn would leak)');

select pg_temp.assert(
  (select msisdn from public.v_church_transactions where mpesa_receipt_number is null limit 1) is null,
  'secret giver msisdn is null even in the masked transaction view');

-- --- as the JKUAT treasurer: cross-church isolation --------------------------
reset role;
set request.jwt.claims = '{"sub":"22222222-2222-2222-2222-222222222222","role":"authenticated"}';
set role authenticated;

select pg_temp.assert(
  (select count(*) from public.v_church_contributions) = 0,
  'JKUAT treasurer sees ZERO Zetech contributions');

select pg_temp.assert(
  (select count(*) from public.contributions) = 0,
  'JKUAT treasurer sees zero Zetech rows on the base table too');

-- --- as an anonymous caller --------------------------------------------------
reset role;
set request.jwt.claims = '';
set role anon;

select pg_temp.assert(
  (select count(*) from public.churches) = 4,
  'anon CAN read the church list (needed at first launch)');

select pg_temp.assert(
  (select count(*) from public.contribution_categories) = 12,
  'anon CAN read the 12 categories (needed offline-first)');

select pg_temp.assert_raises(
  'select count(*) from public.contributions',
  'anon CANNOT read contributions');

select pg_temp.assert_raises(
  'select count(*) from public.users',
  'anon CANNOT read users');

-- --- as the super admin ------------------------------------------------------
reset role;
set request.jwt.claims = '{"sub":"33333333-3333-3333-3333-333333333333","role":"authenticated"}';
set role authenticated;

select pg_temp.assert(
  (select count(*) from public.v_church_contributions) = 2,
  'super admin sees every church');

select pg_temp.assert(
  (select giver_name from public.v_church_contributions
    where id = 'eeeeeeee-0000-0000-0000-000000000002') = 'Peter Otieno',
  'super admin CAN resolve a secret giver (the documented exception)');

select pg_temp.assert(
  (select msisdn from public.v_church_transactions where checkout_request_id is not null limit 1)
    = '+254798765432',
  'super admin sees the full msisdn');

-- Even a super admin must not be able to rewrite history.
select pg_temp.assert_raises(
  $sql$ delete from public.audit_logs $sql$,
  'super admin CANNOT delete audit logs');

select pg_temp.assert_raises(
  $sql$ update public.audit_logs set action = 'tampered' $sql$,
  'super admin CANNOT update audit logs');

reset role;
\echo ''
\echo '=== ALL INVARIANTS HELD ==='
