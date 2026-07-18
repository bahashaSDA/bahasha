-- 0009_ingest_rpcs.sql
-- Transactional RPCs for the ingest and settlement pipeline.
--
-- The backend talks to Postgres over the Supabase SDK, which issues one
-- statement per call and cannot wrap several writes in a single transaction
-- from the client. These SECURITY DEFINER functions do that server-side, so the
-- money-affecting multi-table writes are atomic: a crash mid-way leaves either
-- a complete contribution or nothing, never a half-charge.
--
-- Every function pins search_path (definer-privilege hygiene) and is granted
-- only to service_role -- the backend's identity. No client role can call them.

-- ---------------------------------------------------------------------------
-- ingest_contribution
-- ---------------------------------------------------------------------------
-- Atomically: record the verified BLE packet, create the contribution and its
-- allocations, and advance the device replay counter. Returns the new
-- contribution id.
--
-- Concurrency: the device counter is advanced with a guarded UPDATE (only if
-- the new counter still exceeds the stored one). If two uploads for the same
-- device race past the application-level check, exactly one wins the counter
-- advance; the other raises and is handled by the caller as a duplicate.
create or replace function public.ingest_contribution(
  p_hub_id           uuid,
  p_church_id        uuid,
  p_user_id          uuid,
  p_device_uuid      uuid,
  p_idempotency_key  uuid,
  p_ciphertext       text,
  p_signature        text,
  p_counter          bigint,
  p_nonce            text,
  p_total_amount     numeric,
  p_visibility       giving_visibility,
  p_device_timestamp timestamptz,
  p_allocations      jsonb
)
returns uuid
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
  v_device_id       uuid;
  v_contribution_id uuid := gen_random_uuid();
  v_rows            integer;
  v_alloc           jsonb;
  v_category_id     uuid;
  v_alloc_sum       numeric := 0;
begin
  -- Resolve and lock the device row so the counter check-and-advance is atomic.
  select id into v_device_id
    from public.devices
   where device_uuid = p_device_uuid
     and not is_revoked
   for update;

  if v_device_id is null then
    raise exception 'device % not found or revoked', p_device_uuid
      using errcode = 'no_data_found';
  end if;

  -- Guarded counter advance. If another transaction already moved it past
  -- p_counter, this updates zero rows and we abort -- the packet is a replay.
  update public.devices
     set last_counter = p_counter,
         last_seen_at = now()
   where id = v_device_id
     and last_counter < p_counter;

  get diagnostics v_rows = row_count;
  if v_rows = 0 then
    raise exception 'replayed or stale counter % for device %', p_counter, p_device_uuid
      using errcode = 'check_violation';
  end if;

  -- Create the contribution FIRST: bluetooth_payloads.contribution_id has a FK
  -- to it, so the parent must exist before the packet can reference it. hub
  -- linkage and the visibility snapshot are set here so analytics never depends
  -- on mutable user state.
  insert into public.contributions (
    id, client_uuid, user_id, church_id, device_id, hub_id,
    total_amount, status, visibility_snapshot, device_timestamp
  ) values (
    v_contribution_id, p_idempotency_key, p_user_id, p_church_id, v_device_id, p_hub_id,
    p_total_amount, 'pending', p_visibility, p_device_timestamp
  );

  -- Record the verified packet, now that its contribution_id target exists. A
  -- unique violation on (device_uuid, counter) or nonce surfaces to the caller
  -- as 23505 and is treated as a duplicate.
  insert into public.bluetooth_payloads (
    hub_id, church_id, device_uuid, idempotency_key, ciphertext, signature,
    counter, nonce, status, verified_at, contribution_id, byte_size
  ) values (
    p_hub_id, p_church_id, p_device_uuid, p_idempotency_key, p_ciphertext, p_signature,
    p_counter, p_nonce, 'processed', now(), v_contribution_id, length(p_ciphertext)
  );

  -- Expand the allocation lines, resolving each category code to its id. A
  -- code may be a church-specific category or a global one; prefer the
  -- church-specific match.
  for v_alloc in select * from jsonb_array_elements(p_allocations)
  loop
    select id into v_category_id
      from public.contribution_categories
     where code = (v_alloc->>'category_code')
       and is_active
       and (church_id = p_church_id or church_id is null)
     order by (church_id = p_church_id) desc   -- church-specific first
     limit 1;

    if v_category_id is null then
      raise exception 'unknown contribution category: %', (v_alloc->>'category_code')
        using errcode = 'foreign_key_violation';
    end if;

    insert into public.contribution_allocations (contribution_id, category_id, amount)
    values (v_contribution_id, v_category_id, (v_alloc->>'amount')::numeric);

    v_alloc_sum := v_alloc_sum + (v_alloc->>'amount')::numeric;
  end loop;

  -- Defence in depth: the deferred trigger also asserts this, but failing here
  -- gives a precise error before commit.
  if v_alloc_sum <> p_total_amount then
    raise exception 'allocation sum % does not match total %', v_alloc_sum, p_total_amount
      using errcode = 'check_violation';
  end if;

  return v_contribution_id;
end;
$$;

-- ---------------------------------------------------------------------------
-- record_stk_initiation
-- ---------------------------------------------------------------------------
-- After the STK Push is accepted by Daraja, record the transaction attempt and
-- move the contribution to 'processing'. attempt auto-increments per
-- contribution so a retried push keeps a full attempt history.
create or replace function public.record_stk_initiation(
  p_contribution_id     uuid,
  p_church_id           uuid,
  p_msisdn              text,
  p_amount              numeric,
  p_merchant_request_id text,
  p_checkout_request_id text
)
returns uuid
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
  v_attempt integer;
  v_txn_id  uuid;
begin
  select coalesce(max(attempt), 0) + 1 into v_attempt
    from public.transactions
   where contribution_id = p_contribution_id;

  insert into public.transactions (
    contribution_id, church_id, msisdn, amount, attempt, status,
    merchant_request_id, checkout_request_id
  ) values (
    p_contribution_id, p_church_id, p_msisdn, p_amount, v_attempt, 'pushed',
    p_merchant_request_id, p_checkout_request_id
  )
  returning id into v_txn_id;

  update public.contributions
     set status = 'processing'
   where id = p_contribution_id
     and status = 'pending';

  return v_txn_id;
end;
$$;

-- ---------------------------------------------------------------------------
-- apply_stk_callback
-- ---------------------------------------------------------------------------
-- Called by the MPESA webhook. Idempotent: Safaricom redelivers callbacks, so a
-- second delivery for an already-finalised transaction is a no-op. Matches on
-- checkout_request_id (unique), updates the transaction, and settles the parent
-- contribution to completed/failed.
create or replace function public.apply_stk_callback(
  p_checkout_request_id text,
  p_result_code         integer,
  p_result_desc         text,
  p_mpesa_receipt       text,
  p_amount              numeric,
  p_transaction_date    timestamptz,
  p_raw                 jsonb
)
returns table (contribution_id uuid, outcome text)
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
  v_txn record;
  v_new_status transaction_status;
  v_contribution_status contribution_status;
begin
  select * into v_txn
    from public.transactions
   where checkout_request_id = p_checkout_request_id
   for update;

  if not found then
    -- Unknown checkout id: record nothing, report so the webhook can 200 and
    -- Safaricom stops retrying, but flag it for investigation.
    return query select null::uuid, 'unknown_checkout_request'::text;
    return;
  end if;

  -- Idempotency: already finalised -> acknowledge without re-applying.
  if v_txn.status in ('succeeded', 'failed', 'timeout', 'reversed') then
    return query select v_txn.contribution_id, 'already_finalised'::text;
    return;
  end if;

  if p_result_code = 0 then
    v_new_status := 'succeeded';
    v_contribution_status := 'completed';
  else
    v_new_status := 'failed';
    -- Result code 1032 is the customer cancelling the prompt; distinguish it so
    -- the dashboard can show "cancelled by giver" rather than a hard failure.
    v_contribution_status := case when p_result_code = 1032 then 'cancelled' else 'failed' end;
  end if;

  update public.transactions
     set status               = v_new_status,
         result_code          = p_result_code,
         result_desc          = p_result_desc,
         mpesa_receipt_number = p_mpesa_receipt,
         transaction_date     = p_transaction_date,
         raw_callback         = p_raw,
         completed_at         = now()
   where id = v_txn.id;

  update public.contributions
     set status         = v_contribution_status,
         processed_at   = now(),
         failure_reason = case when p_result_code = 0 then null else p_result_desc end
   where id = v_txn.contribution_id;

  return query select v_txn.contribution_id,
                      case when p_result_code = 0 then 'completed' else 'failed' end;
end;
$$;

-- ---------------------------------------------------------------------------
-- Grants: the backend (service_role) only. No client role may settle money.
-- ---------------------------------------------------------------------------
revoke all on function public.ingest_contribution(uuid, uuid, uuid, uuid, uuid, text, text, bigint, text, numeric, giving_visibility, timestamptz, jsonb) from public, anon, authenticated;
revoke all on function public.record_stk_initiation(uuid, uuid, text, numeric, text, text) from public, anon, authenticated;
revoke all on function public.apply_stk_callback(text, integer, text, text, numeric, timestamptz, jsonb) from public, anon, authenticated;

grant execute on function public.ingest_contribution(uuid, uuid, uuid, uuid, uuid, text, text, bigint, text, numeric, giving_visibility, timestamptz, jsonb) to service_role;
grant execute on function public.record_stk_initiation(uuid, uuid, text, numeric, text, text) to service_role;
grant execute on function public.apply_stk_callback(text, integer, text, text, numeric, timestamptz, jsonb) to service_role;
