-- 02_ingest_rpc_test.sql
-- Exercises the ingest + settlement RPCs from 0009 against real data, including
-- the concurrency-sensitive counter advance and the callback idempotency.
-- Assumes 01_invariants_test.sql fixtures are already loaded in the same DB.

\set ON_ERROR_STOP on

create or replace function pg_temp.assert(p_ok boolean, p_label text)
returns void language plpgsql as $$
begin
  if not p_ok then raise exception 'ASSERTION FAILED: %', p_label; end if;
  raise notice '  pass: %', p_label;
end;
$$;

create or replace function pg_temp.assert_raises(p_sql text, p_label text)
returns void language plpgsql as $$
begin
  begin execute p_sql; exception when others then
    raise notice '  pass: % (rejected: %)', p_label, replace(sqlerrm, E'\n', ' '); return;
  end;
  raise exception 'ASSERTION FAILED: % -- was ALLOWED', p_label;
end;
$$;

\echo '=== ingest RPC: happy path (Grace gives 1700 across 3 categories) ==='

do $$
declare
  v_church uuid := (select id from public.churches where slug = 'zetech-university-sda');
  v_cid uuid;
begin
  v_cid := public.ingest_contribution(
    p_hub_id           => 'ffffffff-0000-0000-0000-000000000001',
    p_church_id        => v_church,
    p_user_id          => 'aaaaaaaa-0000-0000-0000-000000000001',
    p_device_uuid      => 'dddddddd-0000-0000-0000-000000000001',
    p_idempotency_key  => '99999999-0000-0000-0000-000000000001',
    p_ciphertext       => 'BASE64CIPHERTEXT==',
    p_signature        => 'BASE64SIG==',
    p_counter          => 10,
    p_nonce            => 'nonce-ingest-0001',
    p_total_amount     => 1700,
    p_visibility       => 'open',
    p_device_timestamp => now(),
    p_allocations      => '[{"category_code":"tithe","amount":1000},
                            {"category_code":"conference_evangelism","amount":500},
                            {"category_code":"church_building","amount":200}]'::jsonb
  );
  perform pg_temp.assert(v_cid is not null, 'ingest returns a contribution id');
  perform pg_temp.assert(
    (select count(*) from public.contribution_allocations where contribution_id = v_cid) = 3,
    'three allocation lines were created');
  perform pg_temp.assert(
    (select last_counter from public.devices where device_uuid = 'dddddddd-0000-0000-0000-000000000001') = 10,
    'device counter advanced to 10');
  perform pg_temp.assert(
    (select status from public.contributions where id = v_cid) = 'pending',
    'contribution starts pending (awaiting STK)');
  perform pg_temp.assert(
    (select bp.status from public.bluetooth_payloads bp where bp.contribution_id = v_cid) = 'processed',
    'the BLE packet was recorded as processed');
end;
$$;

\echo '=== ingest RPC: replayed counter is refused ==='
select pg_temp.assert_raises($$
  select public.ingest_contribution(
    'ffffffff-0000-0000-0000-000000000001',
    (select id from public.churches where slug = 'zetech-university-sda'),
    'aaaaaaaa-0000-0000-0000-000000000001', 'dddddddd-0000-0000-0000-000000000001',
    '99999999-0000-0000-0000-000000000002', 'ct', 'sig', 10, 'nonce-ingest-0002',
    500, 'open', now(),
    '[{"category_code":"welfare","amount":500}]'::jsonb)
$$, 'counter 10 replayed (not > last 10) is refused');

\echo '=== ingest RPC: unknown category is refused, and rolls back cleanly ==='
select pg_temp.assert_raises($$
  select public.ingest_contribution(
    'ffffffff-0000-0000-0000-000000000001',
    (select id from public.churches where slug = 'zetech-university-sda'),
    'aaaaaaaa-0000-0000-0000-000000000001', 'dddddddd-0000-0000-0000-000000000001',
    '99999999-0000-0000-0000-000000000003', 'ct', 'sig', 11, 'nonce-ingest-0003',
    500, 'open', now(),
    '[{"category_code":"does_not_exist","amount":500}]'::jsonb)
$$, 'unknown category code is refused');

-- The failed insert above must not have advanced the counter (transaction
-- rolled back atomically).
select pg_temp.assert(
  (select last_counter from public.devices where device_uuid = 'dddddddd-0000-0000-0000-000000000001') = 10,
  'failed ingest rolled back: counter still 10, not 11');

\echo '=== settlement RPCs: STK initiation then successful callback ==='

do $$
declare
  v_church uuid := (select id from public.churches where slug = 'zetech-university-sda');
  v_cid uuid := (select id from public.contributions where client_uuid = '99999999-0000-0000-0000-000000000001');
  v_txn uuid;
  v_res record;
begin
  v_txn := public.record_stk_initiation(
    v_cid, v_church, '+254712345678', 1700, 'Merchant-001', 'ws_CO_INGEST_0001');
  perform pg_temp.assert(v_txn is not null, 'STK initiation records a transaction');
  perform pg_temp.assert(
    (select status from public.contributions where id = v_cid) = 'processing',
    'contribution moved to processing after STK push');

  -- Successful callback.
  select * into v_res from public.apply_stk_callback(
    'ws_CO_INGEST_0001', 0, 'The service request is processed successfully.',
    'QGH7XYZ123', 1700, now(), '{"Body":{"stkCallback":{"ResultCode":0}}}'::jsonb);
  perform pg_temp.assert(v_res.outcome = 'completed', 'successful callback settles to completed');
  perform pg_temp.assert(
    (select status from public.contributions where id = v_cid) = 'completed',
    'contribution is completed');
  perform pg_temp.assert(
    (select mpesa_receipt_number from public.transactions where checkout_request_id = 'ws_CO_INGEST_0001') = 'QGH7XYZ123',
    'MPESA receipt was captured');

  -- Redelivered callback must be a no-op (Safaricom retries).
  select * into v_res from public.apply_stk_callback(
    'ws_CO_INGEST_0001', 0, 'redelivery', 'QGH7XYZ123', 1700, now(), '{}'::jsonb);
  perform pg_temp.assert(v_res.outcome = 'already_finalised',
    'redelivered callback is idempotent (no double-settle)');
end;
$$;

\echo '=== settlement RPCs: cancelled prompt (result 1032) ==='
do $$
declare
  v_church uuid := (select id from public.churches where slug = 'zetech-university-sda');
  v_cid uuid := (select id from public.contributions where client_uuid = 'cccccccc-1111-0000-0000-000000000002');
  v_res record;
begin
  perform public.record_stk_initiation(v_cid, v_church, '+254798765432', 500, 'M-002', 'ws_CO_INGEST_0002');
  select * into v_res from public.apply_stk_callback(
    'ws_CO_INGEST_0002', 1032, 'Request cancelled by user', null, null, null,
    '{"Body":{"stkCallback":{"ResultCode":1032}}}'::jsonb);
  perform pg_temp.assert(
    (select status from public.contributions where id = v_cid) = 'cancelled',
    'result 1032 marks the contribution cancelled, not failed');
end;
$$;

\echo '=== settlement RPCs: unknown checkout id is reported, not fatal ==='
do $$
declare v_res record;
begin
  select * into v_res from public.apply_stk_callback(
    'ws_CO_DOES_NOT_EXIST', 0, 'x', 'R', 1, now(), '{}'::jsonb);
  perform pg_temp.assert(v_res.outcome = 'unknown_checkout_request',
    'callback for an unknown checkout id is handled gracefully');
end;
$$;

\echo ''
\echo '=== ALL INGEST/SETTLEMENT TESTS PASSED ==='
