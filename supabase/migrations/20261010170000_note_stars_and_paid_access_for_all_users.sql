alter table public.note_documents
  add column if not exists star_count integer not null default 0
  check (star_count >= 0);

create table if not exists public.note_document_stars (
  document_id uuid not null
    references public.note_documents(id) on delete cascade,
  user_id uuid not null
    references auth.users(id) on delete cascade,
  created_at timestamptz not null default now(),
  primary key (document_id, user_id)
);

create index if not exists note_document_stars_user_id_idx
  on public.note_document_stars (user_id);

alter table public.note_document_stars enable row level security;

grant select, insert, delete
  on table public.note_document_stars
  to authenticated;
grant select
  on table public.note_document_stars
  to anon;

create policy "Users can read own note stars"
on public.note_document_stars
for select
to authenticated
using ((select auth.uid()) = user_id);

create policy "Users can star notes"
on public.note_document_stars
for insert
to authenticated
with check ((select auth.uid()) = user_id);

create policy "Users can unstar notes"
on public.note_document_stars
for delete
to authenticated
using ((select auth.uid()) = user_id);

create schema if not exists private;
revoke all on schema private from public, anon, authenticated;

create or replace function private.sync_note_document_star_count()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
begin
  if tg_op = 'INSERT' then
    update public.note_documents
    set star_count = star_count + 1
    where id = new.document_id;
    return new;
  end if;

  if tg_op = 'DELETE' then
    update public.note_documents
    set star_count = greatest(0, star_count - 1)
    where id = old.document_id;
    return old;
  end if;

  return null;
end;
$$;

revoke all
  on function private.sync_note_document_star_count()
  from public, anon, authenticated;

create trigger sync_note_document_star_count
after insert or delete on public.note_document_stars
for each row
execute function private.sync_note_document_star_count();

update public.note_documents d
set star_count = (
  select count(*)::integer
  from public.note_document_stars s
  where s.document_id = d.id
);

drop policy if exists "Authorized users can read note PDFs"
  on storage.objects;
create policy "Authorized users can read note PDFs"
on storage.objects
for select
to authenticated
using (
  bucket_id = 'notes-pdfs'
  and exists (
    select 1
    from public.note_documents d
    where d.preview_storage_path = name
       or (
         d.storage_path = name
         and (
           not d.is_paid
           or exists (
             select 1
             from public.note_purchases p
             where p.document_id = d.id
               and p.user_id = (select auth.uid())
               and p.status = 'completed'
           )
         )
       )
  )
);
