-- A submission may only reference the current user's team in the same event.
drop policy if exists "Users submit their own Arena projects"
  on public.arena_submissions;
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

drop policy if exists "Users update their own Arena submissions"
  on public.arena_submissions;
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

