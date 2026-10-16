alter table public.workspace_projects
  add column if not exists runtime_mode text not null default 'auto',
  add column if not exists runtime_metadata jsonb not null default '{}'::jsonb,
  add column if not exists session_config jsonb not null default '{}'::jsonb,
  add column if not exists last_runtime_session_id text,
  add column if not exists last_run_at timestamptz;

alter table public.workspace_projects
  drop constraint if exists workspace_projects_runtime_mode_check,
  drop constraint if exists workspace_projects_runtime_metadata_object_check,
  drop constraint if exists workspace_projects_session_config_object_check;

alter table public.workspace_projects
  add constraint workspace_projects_runtime_mode_check
    check (runtime_mode in ('auto', 'local_windows', 'cloud')),
  add constraint workspace_projects_runtime_metadata_object_check
    check (jsonb_typeof(runtime_metadata) = 'object'),
  add constraint workspace_projects_session_config_object_check
    check (jsonb_typeof(session_config) = 'object');
