-- 0015_payments_validated.sql
-- A "validated" flag so a church's payment credentials are only trusted for real
-- giving AFTER a successful test push. Entering a mistyped key can't then
-- silently fail live contributions -- the treasurer must prove it works first.
--
-- Set false whenever credentials change; set true on a successful test STK Push.

alter table public.churches
  add column if not exists payments_validated boolean not null default false;

comment on column public.churches.payments_validated is
  'True only after a successful test STK Push confirmed the church''s credentials. '
  'Reset to false whenever the paybill/passkey/app credentials are changed.';

-- Re-assert the safe public column grant (mirrors 0007/0013/0014); the flag
-- itself is fine to expose, but re-granting keeps the secret columns excluded.
revoke select on public.churches from anon, authenticated;
grant select (id, name, slug, city, county, latitude, longitude, public_key, is_active)
  on public.churches to anon, authenticated;
