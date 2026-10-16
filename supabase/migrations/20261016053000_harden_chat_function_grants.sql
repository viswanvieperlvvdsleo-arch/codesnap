-- Keep privileged chat helpers inaccessible to anonymous clients.
-- The direct-conversation RPC remains available only to signed-in users.

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
  select auth.uid() is not null and exists (
    select 1
    from public.conversation_participants participant
    where participant.conversation_id = target_conversation_id
      and participant.user_id = auth.uid()
  );
$$;

revoke all on function public.is_conversation_participant(uuid, uuid)
  from public, anon;
grant execute on function public.is_conversation_participant(uuid, uuid)
  to authenticated;

revoke all on function public.get_or_create_direct_conversation(uuid)
  from public, anon;
grant execute on function public.get_or_create_direct_conversation(uuid)
  to authenticated;

revoke all on function public.touch_conversation_from_message()
  from public, anon, authenticated;
