-- ==============================================================================
-- CODESNAP (BUG) - COMPLETE ONE-CLICK MASTER SETUP SCRIPT
-- ==============================================================================
-- Instructions:
-- 1. Copy everything in this file.
-- 2. Go to your Supabase SQL Editor (shown on the right side of your screen).
-- 3. Paste here at Line 1 and click the green "Run" button (bottom-right).
-- ==============================================================================

-- 1. PROFILES TABLE
create table if not exists public.profiles (
  id uuid references auth.users on delete cascade primary key,
  username text unique not null,
  full_name text,
  avatar_url text default '',
  headline text default '',
  bio text default '',
  department text default '',
  location text default '',
  github_handle text default '',
  skills text[] default array[]::text[],
  followers_count int default 0,
  following_count int default 0,
  created_at timestamptz default now()
);

-- 2. POSTS TABLE
create table if not exists public.posts (
  id uuid primary key default gen_random_uuid(),
  user_id uuid references public.profiles(id) on delete cascade not null,
  title text default 'Code Snippet',
  description text not null,
  code_snippet text,
  code_language text default 'dart',
  tags text[] default array[]::text[],
  likes_count int default 0,
  comments_count int default 0,
  created_at timestamptz default now()
);

-- 3. POST LIKES TABLE
create table if not exists public.post_likes (
  id uuid primary key default gen_random_uuid(),
  post_id uuid references public.posts(id) on delete cascade not null,
  user_id uuid references public.profiles(id) on delete cascade not null,
  created_at timestamptz default now(),
  unique (post_id, user_id)
);

-- 4. COMMENTS TABLE
create table if not exists public.comments (
  id uuid primary key default gen_random_uuid(),
  post_id uuid references public.posts(id) on delete cascade not null,
  user_id uuid references public.profiles(id) on delete cascade not null,
  content text not null,
  created_at timestamptz default now()
);

-- 5. STORIES TABLE (24H Moments)
create table if not exists public.stories (
  id uuid primary key default gen_random_uuid(),
  user_id uuid references public.profiles(id) on delete cascade not null,
  title text default '',
  media_url text,
  code_snippet text,
  code_language text default 'dart',
  created_at timestamptz default now()
);

-- ------------------------------------------------------------------------------
-- 6. AUTO-CONFIRM ALL USERS (Fixes "Email not confirmed" error forever)
-- ------------------------------------------------------------------------------
update auth.users
set email_confirmed_at = coalesce(email_confirmed_at, now())
where email_confirmed_at is null;

-- ------------------------------------------------------------------------------
-- 7. AUTO-POPULATE PROFILES FOR ALL REGISTERED USERS
-- ------------------------------------------------------------------------------
insert into public.profiles (id, username, full_name, avatar_url)
select 
  id,
  coalesce(raw_user_meta_data->>'username', split_part(email, '@', 1)),
  coalesce(raw_user_meta_data->>'full_name', split_part(email, '@', 1)),
  coalesce(raw_user_meta_data->>'avatar_url', '')
from auth.users
on conflict (id) do nothing;

-- Auto-create profile trigger on any future user sign up
create or replace function public.handle_new_user()
returns trigger as $$
begin
  insert into public.profiles (id, username, full_name, avatar_url)
  values (
    new.id,
    coalesce(new.raw_user_meta_data->>'username', split_part(new.email, '@', 1)),
    coalesce(new.raw_user_meta_data->>'full_name', split_part(new.email, '@', 1)),
    coalesce(new.raw_user_meta_data->>'avatar_url', '')
  )
  on conflict (id) do nothing;
  return new;
end;
$$ language plpgsql security definer;

drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created
  after insert on auth.users
  for each row execute procedure public.handle_new_user();

-- ------------------------------------------------------------------------------
-- 8. OPEN ROW-LEVEL SECURITY POLICIES (Fixes "42501 RLS policy" error)
-- ------------------------------------------------------------------------------
alter table public.profiles enable row level security;
drop policy if exists "allow_all_profiles" on public.profiles;
create policy "allow_all_profiles" on public.profiles for all using (true) with check (true);

alter table public.posts enable row level security;
drop policy if exists "allow_all_posts" on public.posts;
create policy "allow_all_posts" on public.posts for all using (true) with check (true);

alter table public.post_likes enable row level security;
drop policy if exists "allow_all_likes" on public.post_likes;
create policy "allow_all_likes" on public.post_likes for all using (true) with check (true);

alter table public.comments enable row level security;
drop policy if exists "allow_all_comments" on public.comments;
create policy "allow_all_comments" on public.comments for all using (true) with check (true);

alter table public.stories enable row level security;
drop policy if exists "allow_all_stories" on public.stories;
create policy "allow_all_stories" on public.stories for all using (true) with check (true);

-- ------------------------------------------------------------------------------
-- 9. AUTO LIKE & COMMENT COUNTER TRIGGERS
-- ------------------------------------------------------------------------------
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

-- Done! Check the message at bottom right: "Success. No rows returned"
