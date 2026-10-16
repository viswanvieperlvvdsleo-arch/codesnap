-- The People directory counts posts by profile. Index that lookup and harden
-- the existing trigger-only counter functions so they are not callable RPCs.

create index if not exists posts_user_id_idx on public.posts (user_id);

alter function public.handle_post_like_counter() set search_path = '';
alter function public.handle_post_comment_counter() set search_path = '';

revoke all on function public.handle_post_like_counter()
  from public, anon, authenticated;
revoke all on function public.handle_post_comment_counter()
  from public, anon, authenticated;
