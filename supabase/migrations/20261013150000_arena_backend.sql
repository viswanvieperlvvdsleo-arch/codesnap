-- Persistent Arena events, teams, votes, submissions, and bookmarks.
-- Public event/team data is readable, while every write is tied to auth.uid().

create table if not exists public.arena_events (
  id uuid primary key default gen_random_uuid(),
  owner_id uuid not null references public.profiles(id) on delete cascade,
  title text not null check (char_length(btrim(title)) between 1 and 160),
  description text not null default '' check (char_length(description) <= 5000),
  course text not null default 'Community',
  branch text not null default 'Global',
  section text not null default 'A',
  year text not null default extract(year from now())::text,
  deadline timestamptz not null,
  prize_pool text not null default '₹10,000',
  event_type text not null default 'Hackathon'
    check (event_type in ('Hackathon', 'Bounty', 'Challenge', 'Showdown')),
  status text not null default 'LIVE'
    check (status in ('LIVE', 'VOTING', 'UPCOMING', 'ENDED')),
  tags text[] not null default '{}',
  starter_code text,
  teams_count integer not null default 0 check (teams_count >= 0),
  submission_count integer not null default 0 check (submission_count >= 0),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.arena_teams (
  id uuid primary key default gen_random_uuid(),
  event_id uuid not null references public.arena_events(id) on delete cascade,
  owner_id uuid not null references public.profiles(id) on delete cascade,
  team_name text not null check (char_length(btrim(team_name)) between 1 and 100),
  project_title text not null default 'New challenger',
  growth_update text not null default 'Registered in the Arena.',
  member_handles text[] not null default '{}',
  member_avatars text[] not null default '{}',
  repo_url text,
  demo_url text,
  votes_count integer not null default 0 check (votes_count >= 0),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (event_id, owner_id)
);

create table if not exists public.arena_votes (
  event_id uuid not null references public.arena_events(id) on delete cascade,
  team_id uuid not null references public.arena_teams(id) on delete cascade,
  voter_id uuid not null references public.profiles(id) on delete cascade,
  created_at timestamptz not null default now(),
  primary key (event_id, voter_id)
);

create table if not exists public.arena_submissions (
  id uuid primary key default gen_random_uuid(),
  event_id uuid not null references public.arena_events(id) on delete cascade,
  team_id uuid references public.arena_teams(id) on delete set null,
  user_id uuid not null references public.profiles(id) on delete cascade,
  repo_url text not null check (char_length(btrim(repo_url)) between 1 and 2048),
  demo_url text check (demo_url is null or char_length(demo_url) <= 2048),
  summary text not null default '' check (char_length(summary) <= 5000),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (event_id, user_id)
);

create table if not exists public.arena_bookmarks (
  event_id uuid not null references public.arena_events(id) on delete cascade,
  user_id uuid not null references public.profiles(id) on delete cascade,
  created_at timestamptz not null default now(),
  primary key (event_id, user_id)
);

create index if not exists arena_events_deadline_idx
  on public.arena_events (deadline desc);
create index if not exists arena_events_created_at_idx
  on public.arena_events (created_at desc);
create index if not exists arena_teams_event_id_idx
  on public.arena_teams (event_id, created_at);
create index if not exists arena_votes_team_id_idx
  on public.arena_votes (team_id);
create index if not exists arena_submissions_event_id_idx
  on public.arena_submissions (event_id);
create index if not exists arena_events_owner_id_idx
  on public.arena_events (owner_id);
create index if not exists arena_teams_owner_id_idx
  on public.arena_teams (owner_id);
create index if not exists arena_votes_voter_id_idx
  on public.arena_votes (voter_id);
create index if not exists arena_submissions_team_id_idx
  on public.arena_submissions (team_id);
create index if not exists arena_submissions_user_id_idx
  on public.arena_submissions (user_id);
create index if not exists arena_bookmarks_user_id_idx
  on public.arena_bookmarks (user_id);

alter table public.arena_events enable row level security;
alter table public.arena_teams enable row level security;
alter table public.arena_votes enable row level security;
alter table public.arena_submissions enable row level security;
alter table public.arena_bookmarks enable row level security;

grant select on public.arena_events, public.arena_teams to anon, authenticated;
grant insert, update, delete on public.arena_events, public.arena_teams to authenticated;
grant select, insert, update, delete on public.arena_votes,
  public.arena_submissions, public.arena_bookmarks to authenticated;

drop policy if exists "Arena events are publicly readable" on public.arena_events;
create policy "Arena events are publicly readable"
  on public.arena_events for select to anon, authenticated using (true);
drop policy if exists "Users host their own Arena events" on public.arena_events;
create policy "Users host their own Arena events"
  on public.arena_events for insert to authenticated
  with check ((select auth.uid()) = owner_id);
drop policy if exists "Hosts update their Arena events" on public.arena_events;
create policy "Hosts update their Arena events"
  on public.arena_events for update to authenticated
  using ((select auth.uid()) = owner_id)
  with check ((select auth.uid()) = owner_id);
drop policy if exists "Hosts delete their Arena events" on public.arena_events;
create policy "Hosts delete their Arena events"
  on public.arena_events for delete to authenticated
  using ((select auth.uid()) = owner_id);

drop policy if exists "Arena teams are publicly readable" on public.arena_teams;
create policy "Arena teams are publicly readable"
  on public.arena_teams for select to anon, authenticated using (true);
drop policy if exists "Users register their own Arena team" on public.arena_teams;
create policy "Users register their own Arena team"
  on public.arena_teams for insert to authenticated
  with check ((select auth.uid()) = owner_id);
drop policy if exists "Team owners update their Arena team" on public.arena_teams;
create policy "Team owners update their Arena team"
  on public.arena_teams for update to authenticated
  using ((select auth.uid()) = owner_id)
  with check ((select auth.uid()) = owner_id);
drop policy if exists "Team owners delete their Arena team" on public.arena_teams;
create policy "Team owners delete their Arena team"
  on public.arena_teams for delete to authenticated
  using ((select auth.uid()) = owner_id);

drop policy if exists "Users read their own Arena votes" on public.arena_votes;
create policy "Users read their own Arena votes"
  on public.arena_votes for select to authenticated
  using ((select auth.uid()) = voter_id);
drop policy if exists "Users cast their own Arena votes" on public.arena_votes;
create policy "Users cast their own Arena votes"
  on public.arena_votes for insert to authenticated
  with check (
    (select auth.uid()) = voter_id
    and exists (
      select 1 from public.arena_teams t
      where t.id = team_id and t.event_id = arena_votes.event_id
    )
  );
drop policy if exists "Users change their own Arena votes" on public.arena_votes;
create policy "Users change their own Arena votes"
  on public.arena_votes for update to authenticated
  using ((select auth.uid()) = voter_id)
  with check (
    (select auth.uid()) = voter_id
    and exists (
      select 1 from public.arena_teams t
      where t.id = team_id and t.event_id = arena_votes.event_id
    )
  );
drop policy if exists "Users remove their own Arena votes" on public.arena_votes;
create policy "Users remove their own Arena votes"
  on public.arena_votes for delete to authenticated
  using ((select auth.uid()) = voter_id);

drop policy if exists "Users read permitted Arena submissions" on public.arena_submissions;
create policy "Users read permitted Arena submissions"
  on public.arena_submissions for select to authenticated
  using (
    (select auth.uid()) = user_id
    or exists (
      select 1 from public.arena_events e
      where e.id = event_id and e.owner_id = (select auth.uid())
    )
  );
drop policy if exists "Users submit their own Arena projects" on public.arena_submissions;
create policy "Users submit their own Arena projects"
  on public.arena_submissions for insert to authenticated
  with check (
    (select auth.uid()) = user_id
    and (
      team_id is null
      or exists (
        select 1 from public.arena_teams t
        where t.id = team_id
          and t.event_id = arena_submissions.event_id
          and t.owner_id = (select auth.uid())
      )
    )
  );
drop policy if exists "Users update their own Arena submissions" on public.arena_submissions;
create policy "Users update their own Arena submissions"
  on public.arena_submissions for update to authenticated
  using ((select auth.uid()) = user_id)
  with check (
    (select auth.uid()) = user_id
    and (
      team_id is null
      or exists (
        select 1 from public.arena_teams t
        where t.id = team_id
          and t.event_id = arena_submissions.event_id
          and t.owner_id = (select auth.uid())
      )
    )
  );
drop policy if exists "Users delete their own Arena submissions" on public.arena_submissions;
create policy "Users delete their own Arena submissions"
  on public.arena_submissions for delete to authenticated
  using ((select auth.uid()) = user_id);

drop policy if exists "Users manage their own Arena bookmarks" on public.arena_bookmarks;
create policy "Users manage their own Arena bookmarks"
  on public.arena_bookmarks for all to authenticated
  using ((select auth.uid()) = user_id)
  with check ((select auth.uid()) = user_id);

create or replace function public.refresh_arena_team_count()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
declare target_event uuid;
begin
  target_event := case when tg_op = 'DELETE' then old.event_id else new.event_id end;
  update public.arena_events
  set teams_count = (
    select count(*)::integer from public.arena_teams where event_id = target_event
  ), updated_at = now()
  where id = target_event;
  return coalesce(new, old);
end;
$$;

create or replace function public.refresh_arena_vote_count()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
declare old_team uuid;
declare new_team uuid;
begin
  old_team := case when tg_op in ('UPDATE', 'DELETE') then old.team_id else null end;
  new_team := case when tg_op in ('INSERT', 'UPDATE') then new.team_id else null end;
  if old_team is not null then
    update public.arena_teams
    set votes_count = (select count(*)::integer from public.arena_votes where team_id = old_team),
        updated_at = now()
    where id = old_team;
  end if;
  if new_team is not null and new_team is distinct from old_team then
    update public.arena_teams
    set votes_count = (select count(*)::integer from public.arena_votes where team_id = new_team),
        updated_at = now()
    where id = new_team;
  end if;
  return coalesce(new, old);
end;
$$;

create or replace function public.refresh_arena_submission_count()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
declare target_event uuid;
begin
  target_event := case when tg_op = 'DELETE' then old.event_id else new.event_id end;
  update public.arena_events
  set submission_count = (
    select count(*)::integer from public.arena_submissions where event_id = target_event
  ), updated_at = now()
  where id = target_event;
  return coalesce(new, old);
end;
$$;

revoke all on function public.refresh_arena_team_count() from public, anon, authenticated;
revoke all on function public.refresh_arena_vote_count() from public, anon, authenticated;
revoke all on function public.refresh_arena_submission_count() from public, anon, authenticated;

drop trigger if exists arena_team_count_after_change on public.arena_teams;
create trigger arena_team_count_after_change
after insert or delete on public.arena_teams
for each row execute function public.refresh_arena_team_count();

drop trigger if exists arena_vote_count_after_change on public.arena_votes;
create trigger arena_vote_count_after_change
after insert or update or delete on public.arena_votes
for each row execute function public.refresh_arena_vote_count();

drop trigger if exists arena_submission_count_after_change on public.arena_submissions;
create trigger arena_submission_count_after_change
after insert or delete on public.arena_submissions
for each row execute function public.refresh_arena_submission_count();

