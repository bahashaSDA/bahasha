-- 0013_church_payment_config.sql
-- Per-church MPESA payment credentials for self-service onboarding.
--
-- Direct-to-church settlement means each church initiates its STK Push against
-- its OWN paybill, which needs that paybill's Lipa Na M-Pesa Online passkey.
-- The passkey is a payment secret, so it is stored ENCRYPTED at rest (AES-256-GCM
-- with a server-side key; the ciphertext here is useless without it) and is
-- never exposed to any client — not even the treasurer who entered it.
--
-- mpesa_shortcode already exists on churches (0002). This adds the encrypted
-- passkey and a timestamp of when payments were last configured.

alter table public.churches
  add column if not exists mpesa_passkey_encrypted text,
  add column if not exists payments_configured_at timestamptz;

comment on column public.churches.mpesa_passkey_encrypted is
  'AES-256-GCM ciphertext of the paybill Lipa Na M-Pesa Online passkey. '
  'Written and read only by the API under service_role; never returned to clients.';

-- Tighten the public column grant so the encrypted passkey can never leak to
-- anon/authenticated clients reading the church list. Re-grant the safe columns
-- explicitly (mirrors 0007), pointedly excluding the two payment secrets.
revoke select on public.churches from anon, authenticated;
grant select (id, name, slug, city, county, latitude, longitude, public_key, is_active)
  on public.churches to anon, authenticated;
