-- Little us / Supabase migration. Run once in the SQL editor of a NEW project.
-- All content is accessed through narrowly scoped authenticated RPC functions.
create table public.homes (
 id uuid primary key default gen_random_uuid(),
 a uuid not null references auth.users(id), b uuid references auth.users(id),
 a_name text not null, b_name text,
 invite text not null unique default replace(gen_random_uuid()::text,'-',''),
 invite_expires timestamptz not null default now()+interval '7 days',
 coins integer not null default 60 check(coins>=0),
 theme text not null default 'peach', owned text[] not null default array['peach'],
 reunion date, check(a is distinct from b)
);
create table public.notes (
 id uuid primary key default gen_random_uuid(),
 home_id uuid not null references public.homes on delete cascade,
 author_id uuid not null references auth.users(id), author text not null,
 body text not null check(length(body) between 1 and 500),
 created_at timestamptz not null default now()
);
create table public.rounds (
 home_id uuid not null references public.homes on delete cascade,
 day date not null,
 a_answers integer[], a_guesses integer[], b_answers integer[], b_guesses integer[],
 rewarded boolean not null default false, primary key(home_id,day)
);
create index notes_home_time on public.notes(home_id,created_at desc);
create index homes_a on public.homes(a);
create index homes_b on public.homes(b);
alter table public.homes enable row level security;
alter table public.notes enable row level security;
alter table public.rounds enable row level security;
revoke all on public.homes,public.notes,public.rounds from anon,authenticated;
-- No table policies: no client may read answers or mutate balances directly.

create function public.get_home() returns jsonb language plpgsql security definer set search_path='' as $$
declare h public.homes; is_a boolean; ns jsonb; rs jsonb;
begin
 if auth.uid() is null then raise exception 'Sign in first'; end if;
 select * into h from public.homes where a=auth.uid() or b=auth.uid();
 if not found then return jsonb_build_object('home',null,'day',(now() at time zone 'UTC')::date); end if;
 is_a:=h.a=auth.uid();
 select coalesce(jsonb_agg(to_jsonb(n)-'home_id'-'author_id' order by n.created_at desc),'[]'::jsonb) into ns from (select * from public.notes where home_id=h.id order by created_at desc limit 100) n;
 select coalesce(jsonb_agg(jsonb_build_object(
  'day',r.day,'submitted',case when is_a then r.a_answers is not null else r.b_answers is not null end,
  'complete',r.rewarded,
  'mine',case when is_a then r.a_answers else r.b_answers end,
  'guesses',case when is_a then r.a_guesses else r.b_guesses end,
  'partner',case when r.rewarded then case when is_a then r.b_answers else r.a_answers end end,
  'partner_guesses',case when r.rewarded then case when is_a then r.b_guesses else r.a_guesses end end
 ) order by r.day desc),'[]'::jsonb) into rs from (select * from public.rounds where home_id=h.id order by day desc limit 30) r;
 return jsonb_build_object('home',to_jsonb(h),'notes',ns,'rounds',rs,'day',(now() at time zone 'UTC')::date);
end $$;

create function public.create_home(display_name text) returns void language plpgsql security definer set search_path='' as $$
begin
 if auth.uid() is null then raise exception 'Sign in first'; end if;
 perform pg_catalog.pg_advisory_xact_lock(pg_catalog.hashtextextended(auth.uid()::text,0));
 if length(trim(display_name)) not between 1 and 30 then raise exception 'Use a name between 1 and 30 characters'; end if;
 if exists(select 1 from public.homes where a=auth.uid() or b=auth.uid()) then raise exception 'You already have a home'; end if;
 insert into public.homes(a,a_name) values(auth.uid(),trim(display_name));
end $$;
create function public.join_home(invite text,display_name text) returns void language plpgsql security definer set search_path='' as $$
declare h public.homes;
begin
 if auth.uid() is null then raise exception 'Sign in first'; end if;
 perform pg_catalog.pg_advisory_xact_lock(pg_catalog.hashtextextended(auth.uid()::text,0));
 if length(trim(display_name)) not between 1 and 30 then raise exception 'Use a name between 1 and 30 characters'; end if;
 if exists(select 1 from public.homes where a=auth.uid() or b=auth.uid()) then raise exception 'Leave your current home first'; end if;
 select * into h from public.homes where homes.invite=trim(join_home.invite) and invite_expires>now() for update;
 if not found or h.b is not null then raise exception 'Invite is invalid, expired, or already used'; end if;
 update public.homes set b=auth.uid(),b_name=trim(display_name),invite=replace(gen_random_uuid()::text,'-',''),invite_expires=now() where id=h.id;
end $$;
create function public.renew_invite() returns void language plpgsql security definer set search_path='' as $$
begin
 update public.homes set invite=replace(gen_random_uuid()::text,'-',''),invite_expires=now()+interval '7 days' where a=auth.uid() and b is null;
 if not found then raise exception 'No unpaired home found'; end if;
end $$;
create function public.add_note(body text) returns void language plpgsql security definer set search_path='' as $$
declare h public.homes;
begin
 select * into h from public.homes where a=auth.uid() or b=auth.uid() for update;
 if not found then raise exception 'No home found'; end if;
 if length(trim(body)) not between 1 and 500 then raise exception 'Notes must be 1–500 characters'; end if;
 if (select count(*) from public.notes where home_id=h.id)>=100 then raise exception 'Your fridge has 100 notes. Remove a note to make space.'; end if;
 insert into public.notes(home_id,author_id,author,body) values(h.id,auth.uid(),case when h.a=auth.uid() then h.a_name else h.b_name end,trim(body));
end $$;
create function public.remove_note(note_id uuid) returns void language plpgsql security definer set search_path='' as $$
begin
 delete from public.notes n using public.homes h where n.id=note_id and n.home_id=h.id and (h.a=auth.uid() or h.b=auth.uid());
end $$;
create function public.set_reunion(target date) returns void language plpgsql security definer set search_path='' as $$
begin
 if target is null or target < (now() at time zone 'UTC')::date-1 or target > (now() at time zone 'UTC')::date+3651 then raise exception 'Choose a valid future date'; end if;
 update public.homes set reunion=target where a=auth.uid() or b=auth.uid();
 if not found then raise exception 'No home found'; end if;
end $$;
create function public.decorate(item text) returns void language plpgsql security definer set search_path='' as $$
declare h public.homes; cost integer;
begin
 cost:=case item when 'peach' then 0 when 'lilac' then 60 when 'mint' then 60 when 'rose' then 90 else null end;
 if cost is null then raise exception 'Unknown decoration'; end if;
 select * into h from public.homes where a=auth.uid() or b=auth.uid() for update;
 if not found then raise exception 'No home found'; end if;
 if item=any(h.owned) then update public.homes set theme=item where id=h.id;
 else
  if h.coins<cost then raise exception 'Complete more rounds to earn hearts'; end if;
  update public.homes set coins=coins-cost,owned=array_append(owned,item),theme=item where id=h.id;
 end if;
end $$;
create function public.submit_round(round_day date,answers integer[],guesses integer[]) returns void language plpgsql security definer set search_path='' as $$
declare h public.homes; r public.rounds;
begin
 if round_day is distinct from (now() at time zone 'UTC')::date then raise exception 'A new day has started. Refresh your home and play the new round.'; end if;
 if answers is null or guesses is null or cardinality(answers)<>3 or cardinality(guesses)<>3
 or array_ndims(answers)<>1 or array_ndims(guesses)<>1
 or exists(select 1 from unnest(answers||guesses) v where v is null or v<0 or v>3) then raise exception 'Answer all three questions and guesses'; end if;
 select * into h from public.homes where a=auth.uid() or b=auth.uid() for update;
 if not found or h.b is null then raise exception 'Pair with your person first'; end if;
 insert into public.rounds(home_id,day) values(h.id,round_day) on conflict do nothing;
 select * into r from public.rounds where home_id=h.id and day=round_day;
 if h.a=auth.uid() then
  if r.a_answers is not null then raise exception 'Your answers are already saved'; end if;
  update public.rounds set a_answers=answers,a_guesses=guesses where home_id=h.id and day=round_day;
 else
  if r.b_answers is not null then raise exception 'Your answers are already saved'; end if;
  update public.rounds set b_answers=answers,b_guesses=guesses where home_id=h.id and day=round_day;
 end if;
 update public.rounds set rewarded=true where home_id=h.id and day=round_day and a_answers is not null and b_answers is not null and not rewarded;
 if found then update public.homes set coins=coins+30 where id=h.id; end if;
end $$;
create function public.leave_home() returns void language plpgsql security definer set search_path='' as $$
begin
 if auth.uid() is null then raise exception 'Sign in first'; end if;
 delete from public.homes where a=auth.uid() or b=auth.uid();
end $$;
create function public.delete_my_account() returns void language plpgsql security definer set search_path='' as $$
begin
 if auth.uid() is null then raise exception 'Sign in first'; end if;
 delete from public.homes where a=auth.uid() or b=auth.uid();
 delete from auth.users where id=auth.uid();
end $$;
-- PostgreSQL grants EXECUTE to PUBLIC by default: remove it explicitly.
revoke all on function public.get_home(), public.create_home(text), public.join_home(text,text), public.renew_invite(), public.add_note(text), public.remove_note(uuid), public.set_reunion(date), public.decorate(text), public.submit_round(date,integer[],integer[]), public.leave_home(), public.delete_my_account() from public,anon;
grant execute on function public.get_home(), public.create_home(text), public.join_home(text,text), public.renew_invite(), public.add_note(text), public.remove_note(uuid), public.set_reunion(date), public.decorate(text), public.submit_round(date,integer[],integer[]), public.leave_home(), public.delete_my_account() to authenticated;
