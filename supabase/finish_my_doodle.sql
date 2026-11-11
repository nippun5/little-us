-- Little Us · Finish My Doodle (additive migration).
-- Run ONCE in Supabase SQL Editor, preferably in a test project first.
-- Doodles are private to a paired home. All access is through authenticated RPCs.
-- No Storage bucket, Realtime channel, currency, or public table policy is needed.

create table if not exists public.couple_doodles (
  id uuid primary key default gen_random_uuid(),
  home_id uuid not null references public.homes(id) on delete cascade,
  starter_id uuid not null references auth.users(id),
  prompt text not null,
  starter_strokes jsonb not null,
  finisher_id uuid references auth.users(id),
  finish_strokes jsonb,
  created_at timestamptz not null default now(),
  finished_at timestamptz,
  constraint doodle_turns_consistent check (
    (finisher_id is null and finish_strokes is null and finished_at is null)
    or (finisher_id is not null and finish_strokes is not null and finished_at is not null)
  ),
  constraint doodle_two_people check (starter_id is distinct from finisher_id)
);

create index if not exists couple_doodles_home_recent
  on public.couple_doodles(home_id, created_at desc);
create unique index if not exists couple_doodles_one_open
  on public.couple_doodles(home_id) where finished_at is null;

alter table public.couple_doodles enable row level security;
revoke all on table public.couple_doodles from public, anon, authenticated;
-- Deliberately no SELECT/INSERT/UPDATE/DELETE policies. RPCs are the only entry point.

-- Validate all vector data before writing. Coordinates are normalized 0..1.
create or replace function public.doodle_valid_strokes(payload jsonb)
returns boolean language plpgsql immutable set search_path = '' as $$
declare
  stroke jsonb;
  point jsonb;
  stroke_count int;
  point_count int;
  total_points int := 0;
begin
  if payload is null or pg_catalog.jsonb_typeof(payload) != 'array'
      or pg_catalog.octet_length(payload::text) > 60000 then
    return false;
  end if;
  stroke_count := pg_catalog.jsonb_array_length(payload);
  if stroke_count < 1 or stroke_count > 60 then return false; end if;

  for stroke in select value from pg_catalog.jsonb_array_elements(payload) loop
    if pg_catalog.jsonb_typeof(stroke) != 'object'
       or stroke->>'c' not in (
         '#455A64','#DE6B83','#628CC4','#60A483','#E6A853','#9475BC'
       )
       or stroke->>'w' not in ('3','5','7')
       or pg_catalog.jsonb_typeof(stroke->'p') != 'array' then
      return false;
    end if;

    point_count := pg_catalog.jsonb_array_length(stroke->'p');
    total_points := total_points + point_count;
    if point_count < 2 or point_count > 160 or total_points > 1400 then
      return false;
    end if;

    for point in select value from pg_catalog.jsonb_array_elements(stroke->'p') loop
      if pg_catalog.jsonb_typeof(point) != 'array'
        or pg_catalog.jsonb_array_length(point) != 2
        or pg_catalog.jsonb_typeof(point->0) != 'number'
        or pg_catalog.jsonb_typeof(point->1) != 'number' then
        return false;
      end if;
      if (point->>0)::numeric < 0 or (point->>0)::numeric > 1
         or (point->>1)::numeric < 0 or (point->>1)::numeric > 1 then
        return false;
      end if;
    end loop;
  end loop;
  return true;
exception when others then
  return false;
end $$;

-- No client needs to call this validation helper directly.
revoke all on function public.doodle_valid_strokes(jsonb)
  from public, anon, authenticated;

create or replace function public.doodle_list()
returns jsonb language plpgsql security definer set search_path = '' as $$
declare
  h public.homes;
  result jsonb;
begin
  if auth.uid() is null then raise exception 'Sign in first'; end if;
  select * into h from public.homes
    where a = auth.uid() or b = auth.uid();
  if not found or h.b is null then
    raise exception 'Pair with your partner to use Finish My Doodle';
  end if;

  select coalesce(pg_catalog.jsonb_agg(pg_catalog.jsonb_build_object(
      'id', d.id,
      'prompt', d.prompt,
      'starter_name', case when d.starter_id = h.a then h.a_name else h.b_name end,
      'is_mine', d.starter_id = auth.uid(),
      'is_finished', d.finished_at is not null,
      'created_at', d.created_at,
      'starter_strokes', d.starter_strokes,
      'finish_strokes', coalesce(d.finish_strokes, '[]'::jsonb)
    ) order by d.created_at desc), '[]'::jsonb)
    into result
    from (
      select * from public.couple_doodles
      where home_id = h.id order by created_at desc limit 40
    ) d;
  return result;
end $$;

create or replace function public.doodle_start(
  p_prompt text, p_strokes jsonb
) returns uuid language plpgsql security definer set search_path = '' as $$
declare
  h public.homes;
  new_id uuid;
begin
  if auth.uid() is null then raise exception 'Sign in first'; end if;
  -- Serialize starts for a home, even when both partners tap Send simultaneously.
  select * into h from public.homes
    where a = auth.uid() or b = auth.uid() for update;
  if not found or h.b is null then raise exception 'Pair with your partner first'; end if;

  if p_prompt is null or p_prompt not in (
    'Draw half an animal',
    'Start a funny monster',
    'Invent our dream pet',
    'Draw a mysterious object',
    'Begin a silly portrait',
    'Make a magical creature'
  ) then raise exception 'Choose a valid prompt'; end if;
  if not public.doodle_valid_strokes(p_strokes) then
    raise exception 'Drawing is empty or too large';
  end if;
  if exists (select 1 from public.couple_doodles
      where home_id = h.id and finished_at is null) then
    raise exception 'There is already a doodle waiting for its second artist';
  end if;
  if (select pg_catalog.count(*) from public.couple_doodles
      where home_id = h.id) >= 40 then
    raise exception 'Your gallery is full. Remove an older doodle first';
  end if;

  insert into public.couple_doodles (home_id, starter_id, prompt, starter_strokes)
  values (h.id, auth.uid(), p_prompt, p_strokes)
  returning id into new_id;
  return new_id;
end $$;

create or replace function public.doodle_finish(
  p_id uuid, p_strokes jsonb
) returns void language plpgsql security definer set search_path = '' as $$
declare
  h public.homes;
  d public.couple_doodles;
begin
  if auth.uid() is null then raise exception 'Sign in first'; end if;
  select * into h from public.homes
    where a = auth.uid() or b = auth.uid();
  if not found or h.b is null then raise exception 'Pair with your partner first'; end if;
  if not public.doodle_valid_strokes(p_strokes) then
    raise exception 'Drawing is empty or too large';
  end if;

  select * into d from public.couple_doodles
    where id = p_id and home_id = h.id for update;
  if not found then raise exception 'Doodle not found'; end if;
  if d.starter_id = auth.uid() then
    raise exception 'Only your partner can finish your doodle';
  end if;
  if d.finished_at is not null then raise exception 'Already finished'; end if;

  update public.couple_doodles set
    finisher_id = auth.uid(), finish_strokes = p_strokes, finished_at = now()
  where id = d.id;
end $$;

create or replace function public.doodle_delete(p_id uuid)
returns void language plpgsql security definer set search_path = '' as $$
declare
  h public.homes;
  d public.couple_doodles;
begin
  if auth.uid() is null then raise exception 'Sign in first'; end if;
  select * into h from public.homes
    where a = auth.uid() or b = auth.uid();
  if not found then raise exception 'No home found'; end if;
  select * into d from public.couple_doodles
    where id = p_id and home_id = h.id for update;
  if not found then raise exception 'Doodle not found'; end if;
  if d.finished_at is null and d.starter_id <> auth.uid() then
    raise exception 'Only the starter can remove an unfinished doodle';
  end if;
  delete from public.couple_doodles where id = d.id;
end $$;

-- Functions are called from Flutter with the signed-in user's JWT.
revoke all on function public.doodle_list() from public, anon;
revoke all on function public.doodle_start(text, jsonb) from public, anon;
revoke all on function public.doodle_finish(uuid, jsonb) from public, anon;
revoke all on function public.doodle_delete(uuid) from public, anon;
grant execute on function public.doodle_list() to authenticated;
grant execute on function public.doodle_start(text, jsonb) to authenticated;
grant execute on function public.doodle_finish(uuid, jsonb) to authenticated;
grant execute on function public.doodle_delete(uuid) to authenticated;
