-- 0012_admin_rpc.sql
-- Super Admin surface: network-wide, masked-by-default, with an AUDITED path to
-- resolve anonymous givers. Same SECURITY DEFINER pattern as 0011 (a definer
-- function bypasses RLS on Supabase where a view cannot). Every function guards
-- on auth_is_admin()/auth_is_super_admin(), so a non-admin gets nothing.

-- Per-church rollup for the network overview.
create or replace function public.get_admin_church_summary()
returns table (
  church_id uuid,
  church_name text,
  city text,
  is_active boolean,
  total_given numeric,
  contribution_count bigint,
  completed_count bigint,
  giver_count bigint,
  anonymous_giver_count bigint,
  hub_status hub_status
)
language sql
stable
security definer
set search_path = public, extensions, pg_temp
as $$
  select
    ch.id, ch.name, ch.city, ch.is_active,
    coalesce(sum(c.total_amount) filter (where c.status = 'completed'), 0),
    count(c.id),
    count(c.id) filter (where c.status = 'completed'),
    count(distinct c.user_id),
    count(distinct c.user_id) filter (where c.visibility_snapshot = 'secret'),
    h.status
  from public.churches ch
  left join public.contributions c on c.church_id = ch.id
  left join public.church_hubs h on h.church_id = ch.id
  where public.auth_is_admin()
  group by ch.id, ch.name, ch.city, ch.is_active, h.status
  order by ch.name;
$$;

-- All givers across the network, ALWAYS masked (even to a super admin). Seeing a
-- real identity is a deliberate, logged action via reveal_giver_identity() --
-- never casual browsing. This is what keeps the anonymity promise honest.
create or replace function public.get_admin_givers()
returns table (
  user_id uuid,
  church_id uuid,
  church_name text,
  membership_status membership_status,
  visibility giving_visibility,
  registered_at timestamptz,
  display_name text,
  pseudonym text,
  total_given numeric,
  contribution_count bigint
)
language sql
stable
security definer
set search_path = public, extensions, pg_temp
as $$
  select
    u.id, u.church_id, ch.name, u.membership_status, u.visibility, u.registered_at,
    case when u.visibility = 'open' then u.full_name else 'Anonymous giver' end,
    case when u.visibility = 'secret'
         then 'G-' || upper(substr(encode(digest(u.id::text || u.church_id::text, 'sha256'), 'hex'), 1, 8))
         else null end,
    coalesce(sum(c.total_amount) filter (where c.status = 'completed'), 0),
    count(c.id)
  from public.users u
  join public.churches ch on ch.id = u.church_id
  left join public.contributions c on c.user_id = u.id
  where public.auth_is_super_admin()
  group by u.id, u.church_id, ch.name, u.membership_status, u.visibility, u.registered_at, u.full_name
  order by u.registered_at desc;
$$;

-- The audited unmask. Only a super admin may call it; a substantive reason is
-- required; the reveal is recorded in identity_reveals BEFORE the identity is
-- returned. This is the single sanctioned way to see who an anonymous giver is.
create or replace function public.reveal_giver_identity(p_user_id uuid, p_reason text)
returns table (full_name text, phone text, church_name text)
language plpgsql
security definer
set search_path = public, extensions, pg_temp
as $$
declare
  v_church uuid;
  v_name text;
  v_phone text;
  v_church_name text;
begin
  if not public.auth_is_super_admin() then
    raise exception 'not authorized' using errcode = 'insufficient_privilege';
  end if;
  if length(btrim(coalesce(p_reason, ''))) < 10 then
    raise exception 'a reason of at least 10 characters is required' using errcode = 'check_violation';
  end if;

  select u.church_id, u.full_name, u.phone, ch.name
    into v_church, v_name, v_phone, v_church_name
  from public.users u join public.churches ch on ch.id = u.church_id
  where u.id = p_user_id;

  if not found then
    raise exception 'giver not found' using errcode = 'no_data_found';
  end if;

  insert into public.identity_reveals (admin_id, user_id, church_id, reason)
  values (auth.uid(), p_user_id, v_church, p_reason);

  return query select v_name, v_phone, v_church_name;
end;
$$;

-- The reveal audit trail: who unmasked whom, when, and why.
create or replace function public.get_admin_reveals()
returns table (
  revealed_at timestamptz,
  admin_name text,
  admin_email text,
  giver_church text,
  reason text
)
language sql
stable
security definer
set search_path = public, extensions, pg_temp
as $$
  select ir.created_at, a.full_name, a.email::text, ch.name, ir.reason
  from public.identity_reveals ir
  join public.admins a on a.id = ir.admin_id
  join public.churches ch on ch.id = ir.church_id
  where public.auth_is_super_admin()
  order by ir.created_at desc
  limit 200;
$$;

-- Bluetooth hubs across the network, for the system-health view.
create or replace function public.get_admin_hubs()
returns table (
  hub_id uuid,
  church_name text,
  name text,
  status hub_status,
  last_upload_at timestamptz,
  last_heartbeat_at timestamptz,
  is_active boolean
)
language sql
stable
security definer
set search_path = public, extensions, pg_temp
as $$
  select h.id, ch.name, h.name, h.status, h.last_upload_at, h.last_heartbeat_at, h.is_active
  from public.church_hubs h
  join public.churches ch on ch.id = h.church_id
  where public.auth_is_admin()
  order by ch.name;
$$;

-- Grants: authenticated only; each function self-guards on admin status.
do $$
declare fn text;
begin
  for fn in
    select unnest(array[
      'get_admin_church_summary()',
      'get_admin_givers()',
      'reveal_giver_identity(uuid, text)',
      'get_admin_reveals()',
      'get_admin_hubs()'
    ])
  loop
    execute format('revoke all on function public.%s from public, anon', fn);
    execute format('grant execute on function public.%s to authenticated', fn);
  end loop;
end
$$;
