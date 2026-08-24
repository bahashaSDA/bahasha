-- 0019_home_church_membership.sql
-- Auto member/visitor classification + free-text home church.
--
-- A giver now states their HOME church as free text (not every church is listed).
-- The church they GIVE to is the hub's church (the hub authenticates with its own
-- API key). At ingest the backend compares the two and snapshots, on the
-- contribution itself, whether the giver was a member or a visitor of the
-- collecting church — so the dashboard's member/visitor metric is per-gift and
-- correct even for visitors giving away from home.

-- Users: a home church may be unlisted, so church_id is now optional and the
-- fixed membership_status is superseded by the per-contribution snapshot.
alter table public.users alter column church_id drop not null;
alter table public.users alter column membership_status drop not null;
alter table public.users add column if not exists home_church_name text;

comment on column public.users.home_church_name is
  'Free-text home church the giver typed at registration; used to classify each '
  'gift as member/visitor against the collecting (hub) church.';

-- Contributions: snapshot the giver''s home church and the computed membership
-- for THIS collecting church, so analytics never depends on mutable user state.
alter table public.contributions add column if not exists home_church_snapshot text;
alter table public.contributions add column if not exists membership_snapshot membership_status;

-- Rebuild the ingest RPC to accept and store the home church + membership.
drop function if exists public.ingest_contribution(uuid, uuid, uuid, uuid, uuid, text, text, bigint, text, numeric, giving_visibility, timestamptz, jsonb);

create function public.ingest_contribution(
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
  p_allocations      jsonb,
  p_home_church      text default null,
  p_membership       membership_status default null
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
  select id into v_device_id
    from public.devices
   where device_uuid = p_device_uuid
     and not is_revoked
   for update;

  if v_device_id is null then
    raise exception 'device % not found or revoked', p_device_uuid using errcode = 'no_data_found';
  end if;

  update public.devices
     set last_counter = p_counter, last_seen_at = now()
   where id = v_device_id and last_counter < p_counter;

  get diagnostics v_rows = row_count;
  if v_rows = 0 then
    raise exception 'replayed or stale counter % for device %', p_counter, p_device_uuid using errcode = 'check_violation';
  end if;

  insert into public.contributions (
    id, client_uuid, user_id, church_id, device_id, hub_id,
    total_amount, status, visibility_snapshot, device_timestamp,
    home_church_snapshot, membership_snapshot
  ) values (
    v_contribution_id, p_idempotency_key, p_user_id, p_church_id, v_device_id, p_hub_id,
    p_total_amount, 'pending', p_visibility, p_device_timestamp,
    p_home_church, p_membership
  );

  insert into public.bluetooth_payloads (
    hub_id, church_id, device_uuid, idempotency_key, ciphertext, signature,
    counter, nonce, status, verified_at, contribution_id, byte_size
  ) values (
    p_hub_id, p_church_id, p_device_uuid, p_idempotency_key, p_ciphertext, p_signature,
    p_counter, p_nonce, 'processed', now(), v_contribution_id, length(p_ciphertext)
  );

  for v_alloc in select * from jsonb_array_elements(p_allocations)
  loop
    select id into v_category_id
      from public.contribution_categories
     where code = (v_alloc->>'category_code')
       and is_active
       and (church_id = p_church_id or church_id is null)
     order by (church_id = p_church_id) desc
     limit 1;

    if v_category_id is null then
      raise exception 'unknown contribution category: %', (v_alloc->>'category_code') using errcode = 'foreign_key_violation';
    end if;

    insert into public.contribution_allocations (contribution_id, category_id, amount)
    values (v_contribution_id, v_category_id, (v_alloc->>'amount')::numeric);

    v_alloc_sum := v_alloc_sum + (v_alloc->>'amount')::numeric;
  end loop;

  if v_alloc_sum <> p_total_amount then
    raise exception 'allocation sum % does not match total %', v_alloc_sum, p_total_amount using errcode = 'check_violation';
  end if;

  return v_contribution_id;
end;
$$;

revoke all on function public.ingest_contribution(uuid, uuid, uuid, uuid, uuid, text, text, bigint, text, numeric, giving_visibility, timestamptz, jsonb, text, membership_status) from public, anon, authenticated;
grant execute on function public.ingest_contribution(uuid, uuid, uuid, uuid, uuid, text, text, bigint, text, numeric, giving_visibility, timestamptz, jsonb, text, membership_status) to service_role;

-- Dashboard: report the per-contribution membership snapshot (not the mutable
-- user field). Not masked for secret givers — member/visitor is an aggregate
-- fact about the gift, not an identifying detail.
create or replace function public.get_church_contributions()
returns table (
  id uuid,
  church_id uuid,
  total_amount numeric,
  status contribution_status,
  visibility_snapshot giving_visibility,
  received_at timestamptz,
  processed_at timestamptz,
  giver_name text,
  giver_phone text,
  membership_status membership_status,
  giver_pseudonym text
)
language sql
stable
security definer
set search_path = public, extensions, pg_temp
as $$
  select
    c.id,
    c.church_id,
    c.total_amount,
    c.status,
    c.visibility_snapshot,
    c.received_at,
    c.processed_at,
    case when c.visibility_snapshot = 'open' or public.auth_is_super_admin()
         then u.full_name else 'Anonymous giver' end,
    case when c.visibility_snapshot = 'open' or public.auth_is_super_admin()
         then u.phone else null end,
    coalesce(c.membership_snapshot, u.membership_status),
    case when c.visibility_snapshot = 'secret'
         then 'G-' || upper(substr(encode(digest(u.id::text || c.church_id::text, 'sha256'), 'hex'), 1, 8))
         else null end
  from public.contributions c
  join public.users u on u.id = c.user_id
  where public.auth_is_admin() or public.auth_treasurer_church_id() = c.church_id
  order by c.received_at desc;
$$;

revoke all on function public.get_church_contributions() from public, anon;
grant execute on function public.get_church_contributions() to authenticated;
