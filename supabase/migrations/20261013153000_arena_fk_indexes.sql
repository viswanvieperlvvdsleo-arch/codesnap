-- Cover Arena foreign keys used by ownership checks and user-scoped reads.
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

