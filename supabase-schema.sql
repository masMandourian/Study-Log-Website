-- STUDYLOG database setup
-- Run this entire script in Supabase Dashboard -> SQL Editor -> New query.

create table if not exists public.profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  display_name text not null default 'Student',
  share_token text not null unique default replace(gen_random_uuid()::text, '-', ''),
  daily_goal_minutes integer not null default 120 check (daily_goal_minutes between 30 and 960),
  weekly_goal_minutes integer not null default 840 check (weekly_goal_minutes between 60 and 6000),
  created_at timestamptz not null default now()
);

create table if not exists public.study_sessions (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  subject text not null default 'Other' check (char_length(subject) <= 60),
  start_time timestamptz not null,
  end_time timestamptz not null,
  duration_minutes integer not null check (duration_minutes between 1 and 1440),
  notes text not null default '' check (char_length(notes) <= 500),
  questions_completed integer not null default 0 check (questions_completed between 0 and 10000),
  created_at timestamptz not null default now(),
  constraint valid_session_time check (end_time > start_time)
);

create index if not exists study_sessions_user_start_idx on public.study_sessions(user_id, start_time desc);

-- Create a profile automatically when someone signs up.
create or replace function public.handle_new_user()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
begin
  insert into public.profiles (id, display_name)
  values (new.id, coalesce(nullif(new.raw_user_meta_data ->> 'display_name', ''), split_part(new.email, '@', 1)));
  return new;
end;
$$;

drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created
after insert on auth.users
for each row execute procedure public.handle_new_user();

alter table public.profiles enable row level security;
alter table public.study_sessions enable row level security;

-- Owners can only see and change their own profile and sessions.
drop policy if exists "Owners can read own profile" on public.profiles;
create policy "Owners can read own profile" on public.profiles for select to authenticated using (auth.uid() = id);
drop policy if exists "Owners can update own profile" on public.profiles;
create policy "Owners can update own profile" on public.profiles for update to authenticated using (auth.uid() = id) with check (auth.uid() = id);

drop policy if exists "Owners can read own sessions" on public.study_sessions;
create policy "Owners can read own sessions" on public.study_sessions for select to authenticated using (auth.uid() = user_id);
drop policy if exists "Owners can insert own sessions" on public.study_sessions;
create policy "Owners can insert own sessions" on public.study_sessions for insert to authenticated with check (auth.uid() = user_id);
drop policy if exists "Owners can update own sessions" on public.study_sessions;
create policy "Owners can update own sessions" on public.study_sessions for update to authenticated using (auth.uid() = user_id) with check (auth.uid() = user_id);
drop policy if exists "Owners can delete own sessions" on public.study_sessions;
create policy "Owners can delete own sessions" on public.study_sessions for delete to authenticated using (auth.uid() = user_id);

-- The public share page can call this function with a secret share token.
-- It returns only display name, goals, and study log fields; it never returns email or user id.
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
  select * into owner_profile
  from public.profiles
  where share_token = p_share_token;

  if not found then
    return jsonb_build_object('error', 'not_found');
  end if;

  select coalesce(jsonb_agg(jsonb_build_object(
    'id', s.id,
    'subject', s.subject,
    'start_time', s.start_time,
    'end_time', s.end_time,
    'duration_minutes', s.duration_minutes,
    'notes', s.notes,
    'questions_completed', s.questions_completed
  ) order by s.start_time desc), '[]'::jsonb)
  into session_data
  from (
    select * from public.study_sessions
    where user_id = owner_profile.id
    order by start_time desc
  ) s;

  return jsonb_build_object(
    'profile', jsonb_build_object(
      'display_name', owner_profile.display_name,
      'daily_goal_minutes', owner_profile.daily_goal_minutes,
      'weekly_goal_minutes', owner_profile.weekly_goal_minutes
    ),
    'sessions', session_data
  );
end;
$$;

revoke all on function public.get_public_dashboard(text) from public;
grant execute on function public.get_public_dashboard(text) to anon, authenticated;

-- Do not grant anon table access. Public visitors receive data only through the RPC above.
grant select, update on public.profiles to authenticated;
grant select, insert, update, delete on public.study_sessions to authenticated;
