-- Store feed and story media as files instead of large base64 database values.
alter table public.profiles
  add column if not exists headline text default '',
  add column if not exists department text default '',
  add column if not exists location text default '',
  add column if not exists updated_at timestamptz default now();

insert into storage.buckets (
  id,
  name,
  public,
  file_size_limit,
  allowed_mime_types
)
values (
  'post-media',
  'post-media',
  true,
  26214400,
  array[
    'image/jpeg',
    'image/png',
    'image/webp',
    'image/gif',
    'video/mp4',
    'video/webm',
    'video/quicktime'
  ]::text[]
)
on conflict (id) do update set
  public = excluded.public,
  file_size_limit = excluded.file_size_limit,
  allowed_mime_types = excluded.allowed_mime_types;

drop policy if exists "Public can view post media" on storage.objects;
create policy "Public can view post media"
on storage.objects for select
to public
using (bucket_id = 'post-media');

drop policy if exists "Users can upload own post media" on storage.objects;
create policy "Users can upload own post media"
on storage.objects for insert
to authenticated
with check (
  bucket_id = 'post-media'
  and (storage.foldername(name))[1] = auth.uid()::text
);

drop policy if exists "Users can update own post media" on storage.objects;
create policy "Users can update own post media"
on storage.objects for update
to authenticated
using (
  bucket_id = 'post-media'
  and (storage.foldername(name))[1] = auth.uid()::text
)
with check (
  bucket_id = 'post-media'
  and (storage.foldername(name))[1] = auth.uid()::text
);

drop policy if exists "Users can delete own post media" on storage.objects;
create policy "Users can delete own post media"
on storage.objects for delete
to authenticated
using (
  bucket_id = 'post-media'
  and (storage.foldername(name))[1] = auth.uid()::text
);
