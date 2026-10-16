alter table public.workspace_projects
  add column if not exists git_repo_url text,
  add column if not exists git_branch text,
  add column if not exists git_owner text,
  add column if not exists git_repo_name text;

alter table public.workspace_projects
  drop constraint if exists workspace_projects_git_metadata_complete;

alter table public.workspace_projects
  add constraint workspace_projects_git_metadata_complete check (
    (git_repo_url is null and git_branch is null and git_owner is null and git_repo_name is null)
    or
    (git_repo_url is not null and git_branch is not null and git_owner is not null and git_repo_name is not null)
  );

create unique index if not exists workspace_projects_user_repo_branch_unique
  on public.workspace_projects (
    user_id,
    lower(git_owner),
    lower(git_repo_name),
    git_branch
  )
  where git_owner is not null and git_repo_name is not null;

alter table public.workspace_projects enable row level security;
alter table public.workspace_files enable row level security;

drop policy if exists "Users can manage own projects" on public.workspace_projects;
drop policy if exists "Users can manage own files" on public.workspace_files;

create policy "workspace_projects_select_own"
  on public.workspace_projects for select
  to authenticated
  using ((select auth.uid()) = user_id);

create policy "workspace_projects_insert_own"
  on public.workspace_projects for insert
  to authenticated
  with check ((select auth.uid()) = user_id);

create policy "workspace_projects_update_own"
  on public.workspace_projects for update
  to authenticated
  using ((select auth.uid()) = user_id)
  with check ((select auth.uid()) = user_id);

create policy "workspace_projects_delete_own"
  on public.workspace_projects for delete
  to authenticated
  using ((select auth.uid()) = user_id);

create policy "workspace_files_select_own"
  on public.workspace_files for select
  to authenticated
  using (exists (
    select 1 from public.workspace_projects project
    where project.id = workspace_files.project_id
      and project.user_id = (select auth.uid())
  ));

create policy "workspace_files_insert_own"
  on public.workspace_files for insert
  to authenticated
  with check (exists (
    select 1 from public.workspace_projects project
    where project.id = workspace_files.project_id
      and project.user_id = (select auth.uid())
  ));

create policy "workspace_files_update_own"
  on public.workspace_files for update
  to authenticated
  using (exists (
    select 1 from public.workspace_projects project
    where project.id = workspace_files.project_id
      and project.user_id = (select auth.uid())
  ))
  with check (exists (
    select 1 from public.workspace_projects project
    where project.id = workspace_files.project_id
      and project.user_id = (select auth.uid())
  ));

create policy "workspace_files_delete_own"
  on public.workspace_files for delete
  to authenticated
  using (exists (
    select 1 from public.workspace_projects project
    where project.id = workspace_files.project_id
      and project.user_id = (select auth.uid())
  ));

revoke all on table public.workspace_projects from anon;
revoke all on table public.workspace_files from anon;
revoke all on table public.workspace_projects from authenticated;
revoke all on table public.workspace_files from authenticated;

grant select, insert, update, delete on table public.workspace_projects to authenticated;
grant select, insert, update, delete on table public.workspace_files to authenticated;
