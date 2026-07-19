-- 0011_masking_rpc.sql
-- Masked analytics as SECURITY DEFINER functions (Supabase-correct).
--
-- The v_church_* masking views join public.users, whose rows a treasurer cannot
-- read (only super admins can, protecting anonymity). On a superuser Postgres
-- the definer view bypasses that; on Supabase `postgres` is not a superuser, so
-- a plain view's users-join returns zero rows. A SECURITY DEFINER *function*,
-- however, does bypass RLS on Supabase (verified). So the dashboard reads its
-- data through these functions, which:
--   * run as the owner (bypassing RLS to read users),
--   * scope every row to the caller's own church via auth_treasurer_church_id(),
--   * mask secret givers to a stable pseudonym, revealing real identities only
--     to a super admin.
-- The views remain for local/superuser use and documentation; these functions
-- are what production clients call.

-- Masked contributions for the caller's church (admins: all churches).
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
    case when c.visibility_snapshot = 'open' or public.auth_is_super_admin()
         then u.membership_status else null end,
    case when c.visibility_snapshot = 'secret'
         then 'G-' || upper(substr(encode(digest(u.id::text || c.church_id::text, 'sha256'), 'hex'), 1, 8))
         else null end
  from public.contributions c
  join public.users u on u.id = c.user_id
  where public.auth_is_admin() or public.auth_treasurer_church_id() = c.church_id
  order by c.received_at desc;
$$;

-- Masked church members for the caller's church.
create or replace function public.get_church_members()
returns table (
  id uuid,
  church_id uuid,
  membership_status membership_status,
  visibility giving_visibility,
  registered_at timestamptz,
  full_name text,
  phone text
)
language sql
stable
security definer
set search_path = public, extensions, pg_temp
as $$
  select
    u.id, u.church_id, u.membership_status, u.visibility, u.registered_at,
    case when u.visibility = 'open' or public.auth_is_super_admin() then u.full_name else 'Anonymous giver' end,
    case when u.visibility = 'open' or public.auth_is_super_admin() then u.phone else null end
  from public.users u
  where public.auth_is_super_admin() or public.auth_treasurer_church_id() = u.church_id;
$$;

revoke all on function public.get_church_contributions() from public, anon;
revoke all on function public.get_church_members() from public, anon;
grant execute on function public.get_church_contributions() to authenticated;
grant execute on function public.get_church_members() to authenticated;
