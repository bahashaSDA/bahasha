-- 0010_masking_view_owner.sql
-- Let the masking views read their base tables on Supabase.
--
-- Context: the v_church_* masking views are NOT security_invoker, so their
-- internal reads run as the view OWNER (postgres). We had put FORCE ROW LEVEL
-- SECURITY on contributions/users/transactions, which subjects even the table
-- owner to RLS. On a superuser Postgres the owner bypasses RLS anyway and the
-- views worked; on Supabase `postgres` is NOT a superuser, so FORCE made the
-- views return zero rows to treasurers.
--
-- Fix: drop FORCE on exactly the three tables the masking views read. The owner
-- (postgres) then bypasses RLS for the view's internal reads -- which is the
-- whole point of a definer view -- while `authenticated`/`anon` callers remain
-- fully subject to RLS (they are not the table owner). A treasurer still cannot
-- read these base tables directly; only the controlled, row-scoping,
-- identity-masking view can. The audit tables keep FORCE (nothing reads them
-- through a definer view, and the extra strictness is worth keeping).
--
-- Idempotent.

alter table public.contributions no force row level security;
alter table public.users         no force row level security;
alter table public.transactions  no force row level security;
