-- ==============================================================================
-- CODESNAP (BUG) - COMPLETE SAFE IDEMPOTENT SQL SCHEMA
-- Run this in Supabase SQL Editor. Safe to run multiple times!
-- ==============================================================================

-- 1. PROFILES (Extends Supabase auth.users)
create table if not exists public.profiles (
  id uuid references auth.users on delete cascade primary key,
  username text unique not null,
  full_name text,
  avatar_url text,
  bio text default '',
  github_handle text default '',
  skills text[] default array[]::text[],
  followers_count int default 0,
  following_count int default 0,
  created_at timestamptz default now()
);

-- Auto-create profile trigger on Supabase Auth Sign-Up
create or replace function public.handle_new_user()
returns trigger as $$
begin
  insert into public.profiles (id, username, full_name, avatar_url)
  values (
    new.id,
    coalesce(new.raw_user_meta_data->>'username', split_part(new.email, '@', 1)),
    coalesce(new.raw_user_meta_data->>'full_name', split_part(new.email, '@', 1)),
    coalesce(new.raw_user_meta_data->>'avatar_url', 'https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=150')
  )
  on conflict (id) do nothing;
  return new;
end;
$$ language plpgsql security definer;

drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created
  after insert on auth.users
  for each row execute procedure public.handle_new_user();

-- 2. POSTS (Feed with code snippets, tags, likes, comments)
create table if not exists public.posts (
  id uuid primary key default gen_random_uuid(),
  user_id uuid references public.profiles(id) on delete cascade not null,
  title text,
  description text not null,
  code_snippet text,
  code_language text default 'dart',
  tags text[] default array[]::text[],
  likes_count int default 0,
  comments_count int default 0,
  created_at timestamptz default now()
);

-- 3. POST LIKES (Unique like per user with auto-increment counter trigger)
create table if not exists public.post_likes (
  id uuid primary key default gen_random_uuid(),
  post_id uuid references public.posts(id) on delete cascade not null,
  user_id uuid references public.profiles(id) on delete cascade not null,
  created_at timestamptz default now(),
  unique (post_id, user_id)
);

create or replace function public.handle_post_like_counter()
returns trigger as $$
begin
  if (TG_OP = 'INSERT') then
    update public.posts set likes_count = likes_count + 1 where id = new.post_id;
    return new;
  elsif (TG_OP = 'DELETE') then
    update public.posts set likes_count = greatest(0, likes_count - 1) where id = old.post_id;
    return old;
  end if;
  return null;
end;
$$ language plpgsql security definer;

drop trigger if exists on_post_like_change on public.post_likes;
create trigger on_post_like_change
  after insert or delete on public.post_likes
  for each row execute procedure public.handle_post_like_counter();

-- 4. COMMENTS
create table if not exists public.comments (
  id uuid primary key default gen_random_uuid(),
  post_id uuid references public.posts(id) on delete cascade not null,
  user_id uuid references public.profiles(id) on delete cascade not null,
  content text not null,
  created_at timestamptz default now()
);

create or replace function public.handle_post_comment_counter()
returns trigger as $$
begin
  if (TG_OP = 'INSERT') then
    update public.posts set comments_count = comments_count + 1 where id = new.post_id;
    return new;
  elsif (TG_OP = 'DELETE') then
    update public.posts set comments_count = greatest(0, comments_count - 1) where id = old.post_id;
    return old;
  end if;
  return null;
end;
$$ language plpgsql security definer;

drop trigger if exists on_post_comment_change on public.comments;
create trigger on_post_comment_change
  after insert or delete on public.comments
  for each row execute procedure public.handle_post_comment_counter();

-- 5. STORIES (24h Ephemeral Stories)
create table if not exists public.stories (
  id uuid primary key default gen_random_uuid(),
  user_id uuid references public.profiles(id) on delete cascade not null,
  title text not null,
  code_snippet text,
  code_language text default 'dart',
  media_url text,
  views_count int default 0,
  created_at timestamptz default now()
);

-- 6. FOLLOWERS (Social connections)
create table if not exists public.followers (
  follower_id uuid references public.profiles(id) on delete cascade not null,
  following_id uuid references public.profiles(id) on delete cascade not null,
  created_at timestamptz default now(),
  primary key (follower_id, following_id)
);

-- 7. CHAT & MESSAGING
create table if not exists public.conversations (
  id uuid primary key default gen_random_uuid(),
  updated_at timestamptz default now(),
  created_at timestamptz default now()
);

create table if not exists public.conversation_participants (
  conversation_id uuid references public.conversations(id) on delete cascade not null,
  user_id uuid references public.profiles(id) on delete cascade not null,
  primary key (conversation_id, user_id)
);

create table if not exists public.messages (
  id uuid primary key default gen_random_uuid(),
  conversation_id uuid references public.conversations(id) on delete cascade not null,
  sender_id uuid references public.profiles(id) on delete cascade not null,
  text text not null,
  code_snippet text,
  code_language text,
  is_read boolean default false,
  created_at timestamptz default now()
);

-- 8. NOTIFICATIONS
create table if not exists public.notifications (
  id uuid primary key default gen_random_uuid(),
  user_id uuid references public.profiles(id) on delete cascade not null,
  actor_id uuid references public.profiles(id) on delete cascade not null,
  type text not null, -- 'like', 'comment', 'follow', 'message'
  title text not null,
  body text,
  reference_id text,
  is_read boolean default false,
  created_at timestamptz default now()
);

-- 9. WORKSPACE & PROJECTS (Cloud sync for files and folders)
create table if not exists public.workspace_projects (
  id uuid primary key default gen_random_uuid(),
  user_id uuid references public.profiles(id) on delete cascade not null,
  name text not null,
  description text default '',
  created_at timestamptz default now(),
  updated_at timestamptz default now()
);

create table if not exists public.workspace_files (
  id uuid primary key default gen_random_uuid(),
  project_id uuid references public.workspace_projects(id) on delete cascade not null,
  path text not null,
  content text default '',
  is_folder boolean default false,
  updated_at timestamptz default now()
);

-- ==============================================================================
-- ROW LEVEL SECURITY (RLS) - Safely drop old policies first so no duplicate error
-- ==============================================================================

alter table public.profiles enable row level security;
alter table public.posts enable row level security;
alter table public.post_likes enable row level security;
alter table public.comments enable row level security;
alter table public.stories enable row level security;
alter table public.followers enable row level security;
alter table public.conversations enable row level security;
alter table public.conversation_participants enable row level security;
alter table public.messages enable row level security;
alter table public.notifications enable row level security;
alter table public.workspace_projects enable row level security;
alter table public.workspace_files enable row level security;

-- Profiles
drop policy if exists "Profiles are viewable by everyone" on public.profiles;
create policy "Profiles are viewable by everyone" on public.profiles for select using (true);

drop policy if exists "Users can update their own profile" on public.profiles;
create policy "Users can update their own profile" on public.profiles for update using (auth.uid() = id);

-- Posts
drop policy if exists "Posts are viewable by everyone" on public.posts;
create policy "Posts are viewable by everyone" on public.posts for select using (true);

drop policy if exists "Users can create their own posts" on public.posts;
create policy "Users can create their own posts" on public.posts for insert with check (auth.uid() = user_id);

drop policy if exists "Users can update their own posts" on public.posts;
create policy "Users can update their own posts" on public.posts for update using (auth.uid() = user_id);

drop policy if exists "Users can delete their own posts" on public.posts;
create policy "Users can delete their own posts" on public.posts for delete using (auth.uid() = user_id);

-- Post Likes
drop policy if exists "Likes are viewable by everyone" on public.post_likes;
create policy "Likes are viewable by everyone" on public.post_likes for select using (true);

drop policy if exists "Authenticated users can like" on public.post_likes;
create policy "Authenticated users can like" on public.post_likes for insert with check (auth.uid() = user_id);

drop policy if exists "Users can unlike" on public.post_likes;
create policy "Users can unlike" on public.post_likes for delete using (auth.uid() = user_id);

-- Comments
drop policy if exists "Comments viewable by everyone" on public.comments;
create policy "Comments viewable by everyone" on public.comments for select using (true);

drop policy if exists "Users can comment" on public.comments;
create policy "Users can comment" on public.comments for insert with check (auth.uid() = user_id);

drop policy if exists "Users can delete own comments" on public.comments;
create policy "Users can delete own comments" on public.comments for delete using (auth.uid() = user_id);

-- Stories
drop policy if exists "Stories viewable by everyone" on public.stories;
create policy "Stories viewable by everyone" on public.stories for select using (true);

drop policy if exists "Users can create stories" on public.stories;
create policy "Users can create stories" on public.stories for insert with check (auth.uid() = user_id);

-- Followers
drop policy if exists "Followers viewable by everyone" on public.followers;
create policy "Followers viewable by everyone" on public.followers for select using (true);

drop policy if exists "Users can follow/unfollow" on public.followers;
create policy "Users can follow/unfollow" on public.followers for all using (auth.uid() = follower_id);

-- Conversations & Participants
drop policy if exists "Users can view their conversations" on public.conversations;
create policy "Users can view their conversations" on public.conversations for select using (
  exists (select 1 from public.conversation_participants where conversation_id = conversations.id and user_id = auth.uid())
);

drop policy if exists "Users can view participants" on public.conversation_participants;
create policy "Users can view participants" on public.conversation_participants for select using (true);

drop policy if exists "Users can join conversations" on public.conversation_participants;
create policy "Users can join conversations" on public.conversation_participants for insert with check (auth.uid() = user_id);

-- Messages
drop policy if exists "Users can view messages in their conversations" on public.messages;
create policy "Users can view messages in their conversations" on public.messages for select using (
  exists (select 1 from public.conversation_participants where conversation_id = messages.conversation_id and user_id = auth.uid())
);

drop policy if exists "Users can send messages" on public.messages;
create policy "Users can send messages" on public.messages for insert with check (auth.uid() = sender_id);

-- Notifications
drop policy if exists "Users can view own notifications" on public.notifications;
create policy "Users can view own notifications" on public.notifications for select using (auth.uid() = user_id);

drop policy if exists "Users can update own notifications" on public.notifications;
create policy "Users can update own notifications" on public.notifications for update using (auth.uid() = user_id);

drop policy if exists "Users can delete own notifications" on public.notifications;
create policy "Users can delete own notifications" on public.notifications for delete using (auth.uid() = user_id);

-- Workspace Projects & Files
drop policy if exists "Users can manage own projects" on public.workspace_projects;
create policy "Users can manage own projects" on public.workspace_projects for all using (auth.uid() = user_id);

drop policy if exists "Users can manage own files" on public.workspace_files;
create policy "Users can manage own files" on public.workspace_files for all using (
  exists (select 1 from public.workspace_projects where id = workspace_files.project_id and user_id = auth.uid())
);

-- ==============================================================================
-- REALTIME WEBSOCKET SUBSCRIPTIONS (Safe publication setup)
-- ==============================================================================
do $$
begin
  if not exists (select 1 from pg_publication_tables where pubname = 'supabase_realtime' and tablename = 'posts') then
    alter publication supabase_realtime add table public.posts;
  end if;
  if not exists (select 1 from pg_publication_tables where pubname = 'supabase_realtime' and tablename = 'comments') then
    alter publication supabase_realtime add table public.comments;
  end if;
  if not exists (select 1 from pg_publication_tables where pubname = 'supabase_realtime' and tablename = 'post_likes') then
    alter publication supabase_realtime add table public.post_likes;
  end if;
  if not exists (select 1 from pg_publication_tables where pubname = 'supabase_realtime' and tablename = 'messages') then
    alter publication supabase_realtime add table public.messages;
  end if;
  if not exists (select 1 from pg_publication_tables where pubname = 'supabase_realtime' and tablename = 'notifications') then
    alter publication supabase_realtime add table public.notifications;
  end if;
end $$;
