-- Run once in Supabase SQL Editor to add the customizable named countdown.
alter table public.profiles
  add column if not exists goal_name text,
  add column if not exists goal_date date;

-- Update the public read-only RPC so shared viewers can see the countdown too.
create or replace function public.get_public_dashboard(p_share_token text)
returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
declare
  owner_profile public.profiles%rowtype;
  session_data jsonb;
begin
  select * into owner_profile from public.profiles where share_token = p_share_token;
  if not found then return jsonb_build_object('error', 'not_found'); end if;
  select coalesce(jsonb_agg(jsonb_build_object(
    'id', s.id, 'subject', s.subject, 'start_time', s.start_time,
    'end_time', s.end_time, 'duration_minutes', s.duration_minutes,
    'notes', s.notes, 'questions_completed', s.questions_completed
  ) order by s.start_time desc), '[]'::jsonb)
  into session_data
  from (select * from public.study_sessions where user_id = owner_profile.id order by start_time desc) s;
  return jsonb_build_object(
    'profile', jsonb_build_object(
      'display_name', owner_profile.display_name,
      'daily_goal_minutes', owner_profile.daily_goal_minutes,
      'weekly_goal_minutes', owner_profile.weekly_goal_minutes,
      'goal_name', owner_profile.goal_name,
      'goal_date', owner_profile.goal_date
    ),
    'sessions', session_data
  );
end;
$$;
revoke all on function public.get_public_dashboard(text) from public;
grant execute on function public.get_public_dashboard(text) to anon, authenticated;
