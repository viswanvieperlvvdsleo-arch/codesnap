-- People directory: authenticated profiles, server-owned snap state/counts,
-- and least-privilege Data API access.

create index if not exists followers_following_id_idx
  on public.followers (following_id);

do $$
begin
  if not exists (
    select 1
    from pg_constraint
    where conrelid = 'public.followers'::regclass
      and conname = 'followers_no_self_snap'
  ) then
    alter table public.followers
      add constraint followers_no_self_snap
      check (follower_id <> following_id);
  end if;
end
$$;

alter table public.profiles enable row level security;
alter table public.followers enable row level security;

drop policy if exists "Profiles are viewable by everyone" on public.profiles;
drop policy if exists "Public profiles read" on public.profiles;
drop policy if exists "Users can insert own profile" on public.profiles;
drop policy if exists "Users can update their own profile" on public.profiles;

create policy "Authenticated users can view profiles"
  on public.profiles
  for select
  to authenticated
  using (true);

create policy "Users can insert their own profile"
  on public.profiles
  for insert
  to authenticated
  with check ((select auth.uid()) = id);

create policy "Users can update their own profile"
  on public.profiles
  for update
  to authenticated
  using ((select auth.uid()) = id)
  with check ((select auth.uid()) = id);

drop policy if exists "Followers viewable by everyone" on public.followers;
drop policy if exists "Users can follow/unfollow" on public.followers;

create policy "Authenticated users can view snaps"
  on public.followers
  for select
  to authenticated
  using (true);

create policy "Users can create their own snaps"
  on public.followers
  for insert
  to authenticated
  with check (
    (select auth.uid()) = follower_id
    and follower_id <> following_id
  );

create policy "Users can remove their own snaps"
  on public.followers
  for delete
  to authenticated
  using ((select auth.uid()) = follower_id);

revoke all on table public.profiles from anon, authenticated;
revoke all on table public.followers from anon, authenticated;
grant select, insert, update on table public.profiles to authenticated;
grant select, insert, delete on table public.followers to authenticated;

create or replace function public.sync_profile_snap_counts()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
declare
  changed_follower uuid;
  changed_following uuid;
begin
  changed_follower := coalesce(new.follower_id, old.follower_id);
  changed_following := coalesce(new.following_id, old.following_id);

  update public.profiles
  set following_count = (
    select count(*)::integer
    from public.followers
    where follower_id = changed_follower
  )
  where id = changed_follower;

  update public.profiles
  set followers_count = (
    select count(*)::integer
    from public.followers
    where following_id = changed_following
  )
  where id = changed_following;

  return coalesce(new, old);
end;
$$;

revoke all on function public.sync_profile_snap_counts() from public, anon, authenticated;

drop trigger if exists sync_profile_snap_counts_trigger on public.followers;
create trigger sync_profile_snap_counts_trigger
after insert or delete on public.followers
for each row execute function public.sync_profile_snap_counts();

update public.profiles p
set followers_count = (
      select count(*)::integer
      from public.followers f
      where f.following_id = p.id
    ),
    following_count = (
      select count(*)::integer
      from public.followers f
      where f.follower_id = p.id
    );

create or replace function public.handle_new_user()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
declare
  requested_username text;
begin
  requested_username := lower(coalesce(
    nullif(trim(new.raw_user_meta_data ->> 'username'), ''),
    nullif(split_part(coalesce(new.email, ''), '@', 1), ''),
    'developer'
  ));
  requested_username := regexp_replace(requested_username, '[^a-z0-9_]+', '_', 'g');

  begin
    insert into public.profiles (id, username, full_name, avatar_url)
    values (
      new.id,
      requested_username,
      coalesce(
        nullif(trim(new.raw_user_meta_data ->> 'full_name'), ''),
        requested_username
      ),
      coalesce(new.raw_user_meta_data ->> 'avatar_url', '')
    )
    on conflict (id) do nothing;
  exception when unique_violation then
    insert into public.profiles (id, username, full_name, avatar_url)
    values (
      new.id,
      requested_username || '_' || left(replace(new.id::text, '-', ''), 12),
      coalesce(
        nullif(trim(new.raw_user_meta_data ->> 'full_name'), ''),
        requested_username
      ),
      coalesce(new.raw_user_meta_data ->> 'avatar_url', '')
    )
    on conflict (id) do nothing;
  end;

  return new;
end;
$$;

revoke all on function public.handle_new_user() from public, anon, authenticated;

insert into public.profiles (id, username, full_name, avatar_url)
select
  u.id,
  lower(coalesce(
    nullif(trim(u.raw_user_meta_data ->> 'username'), ''),
    nullif(split_part(coalesce(u.email, ''), '@', 1), ''),
    'developer'
  )) || '_' || left(replace(u.id::text, '-', ''), 12),
  coalesce(
    nullif(trim(u.raw_user_meta_data ->> 'full_name'), ''),
    nullif(split_part(coalesce(u.email, ''), '@', 1), ''),
    'Developer'
  ),
  coalesce(u.raw_user_meta_data ->> 'avatar_url', '')
from auth.users u
where not exists (
  select 1 from public.profiles p where p.id = u.id
)
on conflict (id) do nothing;

drop view if exists public.people_directory;
create view public.people_directory
with (security_invoker = true)
as
select
  p.id,
  p.username,
  p.full_name,
  p.avatar_url,
  p.bio,
  p.github_handle,
  p.skills,
  p.headline,
  p.department,
  p.location,
  p.created_at,
  p.updated_at,
  p.followers_count as snapped_count,
  p.following_count as snapping_count,
  (
    select count(*)::integer
    from public.posts post
    where post.user_id = p.id
  ) as posts_count,
  exists (
    select 1
    from public.followers f
    where f.follower_id = (select auth.uid())
      and f.following_id = p.id
  ) as is_snapping,
  p.id = (select auth.uid()) as is_self
from public.profiles p;

revoke all on table public.people_directory from public, anon;
grant select on table public.people_directory to authenticated;
