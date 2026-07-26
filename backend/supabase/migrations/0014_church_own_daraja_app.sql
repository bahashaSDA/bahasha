-- 0014_church_own_daraja_app.sql
-- Optional per-church Daraja API app credentials (guaranteed 0% model).
--
-- With these set, a church's STK Push runs on THAT church's OWN Daraja app
-- (their consumer key/secret) initiating into their own paybill — which
-- Safaricom always allows, needs no aggregator, and costs no percentage. When
-- absent, the platform (Bahasha) Daraja app is used instead. Both are payment
-- secrets, so both are AES-256-GCM encrypted at rest and never returned to any
-- client.

alter table public.churches
  add column if not exists mpesa_consumer_key_encrypted text,
  add column if not exists mpesa_consumer_secret_encrypted text;

comment on column public.churches.mpesa_consumer_key_encrypted is
  'AES-256-GCM ciphertext of the church''s own Daraja Consumer Key (optional). '
  'Server-only; never returned to clients.';

-- Re-assert the safe column grant (mirrors 0007/0013) so the new secret columns
-- are never selectable by anon/authenticated.
revoke select on public.churches from anon, authenticated;
grant select (id, name, slug, city, county, latitude, longitude, public_key, is_active)
  on public.churches to anon, authenticated;
