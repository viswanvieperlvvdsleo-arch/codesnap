-- App-wide realtime, secure direct messaging, chat media/calls, and AI history.

create or replace function public.is_conversation_participant(
  target_conversation_id uuid,
  target_user_id uuid default auth.uid()
)
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select target_user_id is not null and exists (
    select 1
    from public.conversation_participants participant
    where participant.conversation_id = target_conversation_id
      and participant.user_id = target_user_id
  );
$$;

revoke all on function public.is_conversation_participant(uuid, uuid) from public;
grant execute on function public.is_conversation_participant(uuid, uuid) to authenticated;

alter table public.conversations
  add column if not exists kind text not null default 'direct',
  add column if not exists title text,
  add column if not exists avatar_url text,
  add column if not exists created_by uuid references public.profiles(id) on delete set null,
  add column if not exists last_message_at timestamptz;

do $$
begin
  if not exists (
    select 1 from pg_constraint
    where conrelid = 'public.conversations'::regclass
      and conname = 'conversations_kind_check'
  ) then
    alter table public.conversations
      add constraint conversations_kind_check
      check (kind in ('direct', 'group'));
  end if;
end
$$;

alter table public.messages
  add column if not exists message_type text not null default 'text',
  add column if not exists media_path text,
  add column if not exists media_name text,
  add column if not exists media_mime_type text,
  add column if not exists reply_to_message_id uuid references public.messages(id) on delete set null,
  add column if not exists edited_at timestamptz,
  add column if not exists deleted_at timestamptz,
  add column if not exists metadata jsonb not null default '{}'::jsonb;

do $$
begin
  if not exists (
    select 1 from pg_constraint
    where conrelid = 'public.messages'::regclass
      and conname = 'messages_type_check'
  ) then
    alter table public.messages
      add constraint messages_type_check
      check (message_type in ('text', 'code', 'image', 'video', 'audio', 'document', 'system'));
  end if;
end
$$;

create index if not exists messages_conversation_created_idx
  on public.messages(conversation_id, created_at);
create index if not exists conversation_participants_user_idx
  on public.conversation_participants(user_id, conversation_id);

create table if not exists public.message_reactions (
  message_id uuid not null references public.messages(id) on delete cascade,
  user_id uuid not null references public.profiles(id) on delete cascade,
  emoji text not null check (char_length(emoji) between 1 and 24),
  created_at timestamptz not null default now(),
  primary key (message_id, user_id, emoji)
);

create table if not exists public.message_user_flags (
  message_id uuid not null references public.messages(id) on delete cascade,
  user_id uuid not null references public.profiles(id) on delete cascade,
  is_starred boolean not null default false,
  is_pinned boolean not null default false,
  updated_at timestamptz not null default now(),
  primary key (message_id, user_id)
);

create table if not exists public.chat_calls (
  id uuid primary key default gen_random_uuid(),
  conversation_id uuid not null references public.conversations(id) on delete cascade,
  initiator_id uuid not null references public.profiles(id) on delete cascade,
  call_type text not null check (call_type in ('audio', 'video')),
  status text not null default 'ringing'
    check (status in ('ringing', 'accepted', 'declined', 'ended', 'missed')),
  created_at timestamptz not null default now(),
  answered_at timestamptz,
  ended_at timestamptz
);

create index if not exists chat_calls_conversation_created_idx
  on public.chat_calls(conversation_id, created_at desc);

create table if not exists public.ai_threads (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.profiles(id) on delete cascade,
  title text not null default 'New AI chat',
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.ai_messages (
  id uuid primary key default gen_random_uuid(),
  thread_id uuid not null references public.ai_threads(id) on delete cascade,
  user_id uuid not null references public.profiles(id) on delete cascade,
  role text not null check (role in ('user', 'assistant')),
  content text not null check (char_length(content) between 1 and 100000),
  response_id text,
  metadata jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now()
);

create index if not exists ai_threads_user_updated_idx
  on public.ai_threads(user_id, updated_at desc);
create index if not exists ai_messages_thread_created_idx
  on public.ai_messages(thread_id, created_at);

alter table public.conversations enable row level security;
alter table public.conversation_participants enable row level security;
alter table public.messages enable row level security;
alter table public.message_reactions enable row level security;
alter table public.message_user_flags enable row level security;
alter table public.chat_calls enable row level security;
alter table public.ai_threads enable row level security;
alter table public.ai_messages enable row level security;

drop policy if exists "Users can view participants" on public.conversation_participants;
drop policy if exists "Users can join conversations" on public.conversation_participants;
create policy "Participants can view conversation members"
  on public.conversation_participants for select to authenticated
  using (public.is_conversation_participant(conversation_id));

drop policy if exists "Users can view their conversations" on public.conversations;
create policy "Participants can view conversations"
  on public.conversations for select to authenticated
  using (public.is_conversation_participant(id));

drop policy if exists "Users can send messages" on public.messages;
drop policy if exists "Users can view messages in their conversations" on public.messages;
create policy "Participants can view messages"
  on public.messages for select to authenticated
  using (public.is_conversation_participant(conversation_id));
create policy "Participants can send own messages"
  on public.messages for insert to authenticated
  with check (
    sender_id = auth.uid()
    and public.is_conversation_participant(conversation_id)
  );
create policy "Senders can edit own messages"
  on public.messages for update to authenticated
  using (sender_id = auth.uid() and public.is_conversation_participant(conversation_id))
  with check (sender_id = auth.uid() and public.is_conversation_participant(conversation_id));
create policy "Senders can delete own messages"
  on public.messages for delete to authenticated
  using (sender_id = auth.uid() and public.is_conversation_participant(conversation_id));

create policy "Participants can view reactions"
  on public.message_reactions for select to authenticated
  using (exists (
    select 1 from public.messages message
    where message.id = message_id
      and public.is_conversation_participant(message.conversation_id)
  ));
create policy "Participants can add own reactions"
  on public.message_reactions for insert to authenticated
  with check (user_id = auth.uid() and exists (
    select 1 from public.messages message
    where message.id = message_id
      and public.is_conversation_participant(message.conversation_id)
  ));
create policy "Users can remove own reactions"
  on public.message_reactions for delete to authenticated
  using (user_id = auth.uid());

create policy "Users can view own message flags"
  on public.message_user_flags for select to authenticated
  using (user_id = auth.uid());
create policy "Users can add own message flags"
  on public.message_user_flags for insert to authenticated
  with check (user_id = auth.uid() and exists (
    select 1 from public.messages message
    where message.id = message_id
      and public.is_conversation_participant(message.conversation_id)
  ));
create policy "Users can update own message flags"
  on public.message_user_flags for update to authenticated
  using (user_id = auth.uid()) with check (user_id = auth.uid());
create policy "Users can delete own message flags"
  on public.message_user_flags for delete to authenticated
  using (user_id = auth.uid());

create policy "Participants can view calls"
  on public.chat_calls for select to authenticated
  using (public.is_conversation_participant(conversation_id));
create policy "Participants can start calls"
  on public.chat_calls for insert to authenticated
  with check (initiator_id = auth.uid() and public.is_conversation_participant(conversation_id));
create policy "Participants can update calls"
  on public.chat_calls for update to authenticated
  using (public.is_conversation_participant(conversation_id))
  with check (public.is_conversation_participant(conversation_id));

create policy "Users can view own AI threads"
  on public.ai_threads for select to authenticated using (user_id = auth.uid());
create policy "Users can create own AI threads"
  on public.ai_threads for insert to authenticated with check (user_id = auth.uid());
create policy "Users can update own AI threads"
  on public.ai_threads for update to authenticated
  using (user_id = auth.uid()) with check (user_id = auth.uid());
create policy "Users can delete own AI threads"
  on public.ai_threads for delete to authenticated using (user_id = auth.uid());

create policy "Users can view own AI messages"
  on public.ai_messages for select to authenticated using (user_id = auth.uid());
create policy "Users can create own AI messages"
  on public.ai_messages for insert to authenticated
  with check (
    user_id = auth.uid()
    and exists (
      select 1 from public.ai_threads thread
      where thread.id = thread_id and thread.user_id = auth.uid()
    )
  );

create or replace function public.get_or_create_direct_conversation(other_user_id uuid)
returns uuid
language plpgsql
security definer
set search_path = public
as $$
declare
  current_user_id uuid := auth.uid();
  found_conversation_id uuid;
begin
  if current_user_id is null then
    raise exception 'Authentication required';
  end if;
  if other_user_id is null or other_user_id = current_user_id then
    raise exception 'Choose another account';
  end if;
  if not exists (select 1 from public.profiles where id = other_user_id) then
    raise exception 'Account not found';
  end if;

  select conversation.id into found_conversation_id
  from public.conversations conversation
  join public.conversation_participants mine
    on mine.conversation_id = conversation.id and mine.user_id = current_user_id
  join public.conversation_participants theirs
    on theirs.conversation_id = conversation.id and theirs.user_id = other_user_id
  where conversation.kind = 'direct'
    and (select count(*) from public.conversation_participants participant
         where participant.conversation_id = conversation.id) = 2
  limit 1;

  if found_conversation_id is null then
    insert into public.conversations(kind, created_by, last_message_at)
    values ('direct', current_user_id, now())
    returning id into found_conversation_id;

    insert into public.conversation_participants(conversation_id, user_id)
    values
      (found_conversation_id, current_user_id),
      (found_conversation_id, other_user_id);
  end if;

  return found_conversation_id;
end;
$$;

revoke all on function public.get_or_create_direct_conversation(uuid) from public;
grant execute on function public.get_or_create_direct_conversation(uuid) to authenticated;

create or replace function public.touch_conversation_from_message()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  update public.conversations
  set updated_at = now(), last_message_at = new.created_at
  where id = new.conversation_id;
  return new;
end;
$$;

drop trigger if exists messages_touch_conversation on public.messages;
create trigger messages_touch_conversation
after insert on public.messages
for each row execute function public.touch_conversation_from_message();

insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values (
  'chat-media',
  'chat-media',
  false,
  52428800,
  array[
    'image/jpeg', 'image/png', 'image/gif', 'image/webp',
    'video/mp4', 'video/webm',
    'audio/mpeg', 'audio/mp4', 'audio/wav', 'audio/webm',
    'application/pdf', 'text/plain', 'application/zip'
  ]
)
on conflict (id) do update set
  public = excluded.public,
  file_size_limit = excluded.file_size_limit,
  allowed_mime_types = excluded.allowed_mime_types;

create or replace function public.chat_media_conversation_id(object_name text)
returns uuid
language plpgsql
immutable
set search_path = public, storage
as $$
begin
  return ((storage.foldername(object_name))[1])::uuid;
exception when invalid_text_representation or array_subscript_error then
  return null;
end;
$$;

revoke all on function public.chat_media_conversation_id(text) from public;
grant execute on function public.chat_media_conversation_id(text) to authenticated;

create or replace function public.chat_media_owner_id(object_name text)
returns uuid
language plpgsql
immutable
set search_path = public, storage
as $$
begin
  return ((storage.foldername(object_name))[2])::uuid;
exception when invalid_text_representation or array_subscript_error then
  return null;
end;
$$;

revoke all on function public.chat_media_owner_id(text) from public;
grant execute on function public.chat_media_owner_id(text) to authenticated;

drop policy if exists "Participants can read chat media" on storage.objects;
drop policy if exists "Participants can upload chat media" on storage.objects;
drop policy if exists "Senders can update chat media" on storage.objects;
drop policy if exists "Senders can delete chat media" on storage.objects;
create policy "Participants can read chat media"
  on storage.objects for select to authenticated
  using (
    bucket_id = 'chat-media'
    and public.is_conversation_participant(public.chat_media_conversation_id(name))
  );
create policy "Participants can upload chat media"
  on storage.objects for insert to authenticated
  with check (
    bucket_id = 'chat-media'
    and public.is_conversation_participant(public.chat_media_conversation_id(name))
    and public.chat_media_owner_id(name) = auth.uid()
  );
create policy "Senders can update chat media"
  on storage.objects for update to authenticated
  using (
    bucket_id = 'chat-media'
    and public.chat_media_owner_id(name) = auth.uid()
  )
  with check (
    bucket_id = 'chat-media'
    and public.chat_media_owner_id(name) = auth.uid()
  );
create policy "Senders can delete chat media"
  on storage.objects for delete to authenticated
  using (
    bucket_id = 'chat-media'
    and public.chat_media_owner_id(name) = auth.uid()
  );

do $$
declare
  relation_name text;
begin
  foreach relation_name in array array[
    'profiles', 'posts', 'post_likes', 'comments', 'stories', 'followers',
    'conversations', 'conversation_participants', 'messages',
    'message_reactions', 'message_user_flags', 'chat_calls', 'notifications',
    'workspace_projects', 'workspace_files',
    'note_documents', 'note_purchases', 'note_document_stars',
    'arena_events', 'arena_teams', 'arena_votes', 'arena_submissions', 'arena_bookmarks',
    'ai_threads', 'ai_messages'
  ]
  loop
    if to_regclass('public.' || relation_name) is not null
       and not exists (
         select 1 from pg_publication_tables
         where pubname = 'supabase_realtime'
           and schemaname = 'public'
           and tablename = relation_name
       ) then
      execute format('alter publication supabase_realtime add table public.%I', relation_name);
    end if;
  end loop;
end
$$;
