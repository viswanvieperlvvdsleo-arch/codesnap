alter table public.note_documents
  add column if not exists cover_storage_path text;

insert into storage.buckets (
  id,
  name,
  public,
  file_size_limit,
  allowed_mime_types
)
values (
  'note-covers',
  'note-covers',
  true,
  8388608,
  array['image/jpeg', 'image/png', 'image/webp']
)
on conflict (id) do update
set public = excluded.public,
    file_size_limit = excluded.file_size_limit,
    allowed_mime_types = excluded.allowed_mime_types;

drop policy if exists "Public can view note covers" on storage.objects;
create policy "Public can view note covers"
on storage.objects
for select
to anon, authenticated
using (bucket_id = 'note-covers');

drop policy if exists "Users can upload own note covers" on storage.objects;
create policy "Users can upload own note covers"
on storage.objects
for insert
to authenticated
with check (
  bucket_id = 'note-covers'
  and (storage.foldername(name))[1] = (select auth.uid())::text
);

drop policy if exists "Users can replace own note covers" on storage.objects;
create policy "Users can replace own note covers"
on storage.objects
for update
to authenticated
using (
  bucket_id = 'note-covers'
  and owner_id = (select auth.uid())::text
)
with check (
  bucket_id = 'note-covers'
  and owner_id = (select auth.uid())::text
);

drop policy if exists "Users can delete own note covers" on storage.objects;
create policy "Users can delete own note covers"
on storage.objects
for delete
to authenticated
using (
  bucket_id = 'note-covers'
  and owner_id = (select auth.uid())::text
);
