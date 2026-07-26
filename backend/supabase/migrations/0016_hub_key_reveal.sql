-- 0016_hub_key_reveal.sql
-- Let a treasurer re-view their hub key instead of being forced to regenerate.
--
-- api_key_hash (HMAC digest) stays the authentication credential. We ALSO keep
-- the plaintext key AES-256-GCM encrypted at rest so the owner can copy it again
-- from the dashboard at any time. The security property is preserved: a database
-- leak still yields nothing, because decryption needs PAYMENT_ENCRYPTION_KEY,
-- which lives in the server environment, never in the database.

alter table public.church_hubs
  add column if not exists hub_api_key_encrypted text;

comment on column public.church_hubs.hub_api_key_encrypted is
  'AES-256-GCM ciphertext of the hub API key, so the owning treasurer can '
  're-view it. Server-only; decrypted only for the authorised church owner/admin.';

-- Re-assert the safe column grant (mirrors 0007): the encrypted key and the HMAC
-- digest are both withheld from anon/authenticated. A deacon still reads only
-- their hub's health.
grant select (id, church_id, name, status, last_heartbeat_at, last_upload_at,
              app_version, is_active, created_at)
  on public.church_hubs to authenticated;
