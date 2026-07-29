-- 0018_avatar_storage.sql
-- Profile photos for givers: a Supabase Storage bucket to hold the images, and
-- a column on users to remember each giver's chosen photo URL.
--
-- The mobile app lets a giver pick a photo (shown immediately from local
-- storage); when online it uploads to this bucket and stores the public URL
-- here. Infra + data only — no backend request logic changes.

-- The column that remembers a giver's avatar.
alter table public.users
  add column if not exists avatar_url text;

comment on column public.users.avatar_url is
  'Public URL of the giver''s profile photo in the avatars storage bucket.';

-- A public-read bucket for avatars (profile photos are not sensitive).
insert into storage.buckets (id, name, public)
values ('avatars', 'avatars', true)
on conflict (id) do nothing;

-- Anyone may read an avatar (public bucket); writes are performed server-side
-- with the service role, so no public insert/update/delete policy is granted.
drop policy if exists "avatars public read" on storage.objects;
create policy "avatars public read"
  on storage.objects for select
  using (bucket_id = 'avatars');
