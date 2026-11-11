-- Little Us / Same Thought. Apply to an EXISTING Supabase project after schema.sql.
-- 5 rounds, 15 seconds per answer, 3 second reveal; no hearts awarded.
-- All game state/answers are private tables; authenticated clients use only RPCs.

create table if not exists public.st_matches (
  id uuid primary key default gen_random_uuid(),
  home_id uuid not null references public.homes(id) on delete cascade,
  status text not null default 'lobby' check (status in ('lobby','active','finished','cancelled')),
  phase text not null default 'lobby' check (phase in ('lobby','answer','reveal','done')),
  category_a text, category_b text,
  ready_a boolean not null default false,
  ready_b boolean not null default false,
  seen_a timestamptz, seen_b timestamptz,
  round_no integer not null default 0 check(round_no between 0 and 5),
  score integer not null default 0 check(score between 0 and 5),
  phase_ends_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);
create unique index if not exists st_one_active_match_per_home on public.st_matches(home_id)
  where status in ('lobby','active');
create index if not exists st_matches_home on public.st_matches(home_id,created_at desc);

create table if not exists public.st_rounds (
  match_id uuid not null references public.st_matches(id) on delete cascade,
  round_no integer not null check (round_no between 1 and 5),
  category text not null,
  letter text not null check (length(letter)=1),
  a_answer text, b_answer text,
  matched boolean,
  primary key(match_id,round_no)
);

create table if not exists public.st_words (
  category text not null,
  letter text not null,
  word text not null,
  primary key(category,letter,word),
  check (word = lower(trim(word)) and left(word,1)=lower(letter))
);
create table if not exists public.st_prompts (
  category text not null,
  letter text not null check(length(letter)=1),
  primary key(category,letter)
);

-- Handpicked letters guarantee at least five distinct prompts when both choose same category.
-- Add more words to the bank at any time. This first edition is English-only.
with bank(category,letter,words) as (values
 ('Animals','C','cat,cow,camel,crocodile,cheetah,cougar,crab,chicken,chinchilla'),
 ('Animals','D','dog,deer,dolphin,donkey,duck,dingo,dragonfly,dove'),
 ('Animals','B','bear,bat,beaver,buffalo,bird,butterfly,bison,baboon'),
 ('Animals','F','fox,frog,flamingo,ferret,fish,falcon,fly'),
 ('Animals','H','horse,hamster,hippo,hedgehog,hyena,hawk,hare'),
 ('Food','P','pizza,pasta,peach,pear,pineapple,pancake,popcorn,potato,pudding,pie'),
 ('Food','C','cake,carrot,cheese,cookie,chocolate,cherry,chicken,cucumber,corn,curry'),
 ('Food','B','banana,bread,burger,biscuit,blueberry,broccoli,bagel,bacon,brownie'),
 ('Food','S','sushi,sandwich,soup,salad,steak,strawberry,spinach,spaghetti,salmon'),
 ('Food','M','mango,muffin,mushroom,melon,milkshake,macaroni,meatball,mochi'),
 ('Countries','I','india,iceland,indonesia,ireland,italy,iran,iraq,israel'),
 ('Countries','C','canada,china,chile,colombia,cuba,croatia,cambodia,cameroon,cyprus'),
 ('Countries','B','brazil,belgium,bhutan,bangladesh,bolivia,bulgaria,bahrain,botswana'),
 ('Countries','N','nepal,norway,nigeria,namibia,netherlands,nicaragua,niger,nauru'),
 ('Countries','S','spain,sweden,switzerland,singapore,sri lanka,slovakia,slovenia,sudan,serbia,senegal'),
 ('Colors','B','blue,black,beige,brown,burgundy,bronze,blush,baby blue'),
 ('Colors','G','green,gold,gray,grey,ginger,granite'),
 ('Colors','P','pink,purple,peach,plum,periwinkle,pearl'),
 ('Colors','R','red,rose,ruby,rust,raspberry'),
 ('Colors','S','silver,scarlet,salmon,sage,sand,sky blue,slate'),
 ('Jobs','D','doctor,dentist,driver,designer,dancer,developer,director,detective'),
 ('Jobs','P','pilot,plumber,painter,photographer,professor,pharmacist,paramedic,programmer'),
 ('Jobs','T','teacher,tailor,technician,therapist,translator,trainer,tutor'),
 ('Jobs','A','artist,architect,actor,accountant,astronaut,author,attorney'),
 ('Jobs','C','chef,cleaner,cashier,carpenter,coach,counselor,comedian,chemist')
), prompts as (
 insert into public.st_prompts(category,letter)
 select category,letter from bank on conflict do nothing returning 1
)
insert into public.st_words(category,letter,word)
select bank.category,bank.letter,trim(w.word)
from bank cross join lateral unnest(string_to_array(bank.words,',')) as w(word)
on conflict do nothing;

alter table public.st_matches enable row level security;
alter table public.st_rounds enable row level security;
alter table public.st_prompts enable row level security;
alter table public.st_words enable row level security;
revoke all on public.st_matches,public.st_rounds,public.st_prompts,public.st_words from public,anon,authenticated;

-- Only used internally by SECURITY DEFINER RPCs. It is deliberately not executable by clients.
create or replace function public.st_progress(p_id uuid) returns void
language plpgsql security definer set search_path = '' as $$
declare
 m public.st_matches;
 c text; chosen_letter text; n integer; r public.st_rounds;
begin
 select * into m from public.st_matches where id=p_id for update;
 if not found then return; end if;
 if m.status='lobby' and m.ready_a and m.ready_b
    and m.category_a is not null and m.category_b is not null
    and m.seen_a > clock_timestamp()-interval '8 seconds'
    and m.seen_b > clock_timestamp()-interval '8 seconds' then
   for n in 1..5 loop
     c := case when n % 2 = 1 then m.category_a else m.category_b end;
     select p.letter into chosen_letter from public.st_prompts p
     where p.category=c and not exists (
       select 1 from public.st_rounds r0 where r0.match_id=p_id
         and r0.category=c and r0.letter=p.letter)
     order by random() limit 1;
     if chosen_letter is null then raise exception 'Not enough prompts for category %',c; end if;
     insert into public.st_rounds(match_id,round_no,category,letter)
     values (p_id,n,c,chosen_letter);
   end loop;
   update public.st_matches set status='active',phase='answer',round_no=1,
     phase_ends_at=clock_timestamp()+interval '15 seconds',updated_at=clock_timestamp()
     where id=p_id;
   return;
 end if;
 if m.status <> 'active' or m.phase_ends_at > clock_timestamp() then return; end if;
 if m.phase='answer' then
   select * into r from public.st_rounds where match_id=p_id and round_no=m.round_no;
   update public.st_rounds set matched=(r.a_answer is not null and r.b_answer is not null
     and r.a_answer=r.b_answer) where match_id=p_id and round_no=m.round_no;
   update public.st_matches set phase='reveal',
     score=score+case when r.a_answer is not null and r.a_answer=r.b_answer then 1 else 0 end,
     phase_ends_at=clock_timestamp()+interval '3 seconds',updated_at=clock_timestamp()
     where id=p_id;
 elsif m.phase='reveal' then
   if m.round_no=5 then
     update public.st_matches set status='finished',phase='done',phase_ends_at=null,
       updated_at=clock_timestamp() where id=p_id;
   else
     update public.st_matches set round_no=m.round_no+1,phase='answer',
       phase_ends_at=clock_timestamp()+interval '15 seconds',updated_at=clock_timestamp()
       where id=p_id;
   end if;
 end if;
end $$;
revoke all on function public.st_progress(uuid) from public,anon,authenticated;

create or replace function public.st_join_or_create() returns uuid
language plpgsql security definer set search_path = '' as $$
declare h public.homes; m public.st_matches;
begin
 if auth.uid() is null then raise exception 'Sign in to play'; end if;
 select * into h from public.homes where (a=auth.uid() or b=auth.uid()) for update;
 if not found or h.b is null then raise exception 'Pair with your partner first'; end if;
 select * into m from public.st_matches
   where home_id=h.id and status in ('lobby','active') for update;
 if found and m.updated_at < clock_timestamp()-interval '30 minutes' then
   update public.st_matches set status='cancelled',phase='done' where id=m.id;
   m.id:=null;
 end if;
 if m.id is null then
   insert into public.st_matches(home_id) values(h.id) returning * into m;
 end if;
 return m.id;
end $$;

create or replace function public.st_choose_category(p_match uuid,p_category text) returns void
language plpgsql security definer set search_path = '' as $$
declare m public.st_matches; h public.homes;
begin
 select * into m from public.st_matches where id=p_match for update;
 if not found or m.status<>'lobby' then raise exception 'Category selection is closed'; end if;
 select * into h from public.homes where id=m.home_id and (a=auth.uid() or b=auth.uid());
 if not found then raise exception 'Not a member of this match'; end if;
 if not exists(select 1 from public.st_prompts where category=p_category)
 then raise exception 'Unknown category'; end if;
 if h.a=auth.uid() then
   update public.st_matches set category_a=p_category,ready_a=false,ready_b=false,
     seen_a=clock_timestamp(),updated_at=clock_timestamp() where id=p_match;
 else
   update public.st_matches set category_b=p_category,ready_a=false,ready_b=false,
     seen_b=clock_timestamp(),updated_at=clock_timestamp() where id=p_match;
 end if;
end $$;

create or replace function public.st_set_ready(p_match uuid,p_ready boolean) returns void
language plpgsql security definer set search_path = '' as $$
declare m public.st_matches; h public.homes;
begin
 select * into m from public.st_matches where id=p_match for update;
 if not found or m.status<>'lobby' then raise exception 'Lobby is closed'; end if;
 select * into h from public.homes where id=m.home_id and (a=auth.uid() or b=auth.uid());
 if not found then raise exception 'Not a member of this match'; end if;
 if m.category_a is null or m.category_b is null then raise exception 'Both must choose a category'; end if;
 if h.a=auth.uid() then
   update public.st_matches set ready_a=p_ready,seen_a=clock_timestamp(),updated_at=clock_timestamp() where id=p_match;
 else
   update public.st_matches set ready_b=p_ready,seen_b=clock_timestamp(),updated_at=clock_timestamp() where id=p_match;
 end if;
 perform public.st_progress(p_match);
end $$;

create or replace function public.st_submit(p_match uuid,p_round integer,p_word text) returns void
language plpgsql security definer set search_path = '' as $$
declare m public.st_matches; h public.homes; r public.st_rounds; answer text;
begin
 select * into m from public.st_matches where id=p_match for update;
 if not found then raise exception 'Match not found'; end if;
 select * into h from public.homes where id=m.home_id and (a=auth.uid() or b=auth.uid());
 if not found then raise exception 'Not a member of this match'; end if;
 perform public.st_progress(p_match);
 select * into m from public.st_matches where id=p_match;
 if m.status<>'active' or m.phase<>'answer' or p_round<>m.round_no
   or m.phase_ends_at <= clock_timestamp() then raise exception 'This round is closed'; end if;
 select * into r from public.st_rounds where match_id=p_match and round_no=p_round;
 answer:=lower(trim(regexp_replace(coalesce(p_word,''),'[[:space:]]+',' ','g')));
 if length(answer) not between 1 and 32 or answer !~ '^[a-z][a-z -]*$'
   or left(answer,1)<>lower(r.letter) then raise exception 'Start with the given letter (English letters only)'; end if;
 if not exists(select 1 from public.st_words where category=r.category and letter=r.letter and word=answer)
 then raise exception 'Word not in the current word bank. Try another word.'; end if;
 if h.a=auth.uid() then
   if r.a_answer is not null then raise exception 'Your answer is already locked'; end if;
   update public.st_rounds set a_answer=answer where match_id=p_match and round_no=p_round;
 else
   if r.b_answer is not null then raise exception 'Your answer is already locked'; end if;
   update public.st_rounds set b_answer=answer where match_id=p_match and round_no=p_round;
 end if;
 -- Early reveal: both answers are locked. The trigger is the server, not the client.
 if exists(select 1 from public.st_rounds where match_id=p_match and round_no=p_round
   and a_answer is not null and b_answer is not null) then
   update public.st_matches set phase_ends_at=clock_timestamp() where id=p_match;
   perform public.st_progress(p_match);
 end if;
end $$;

create or replace function public.st_state(p_match uuid) returns jsonb
language plpgsql security definer set search_path = '' as $$
declare m public.st_matches; h public.homes; r public.st_rounds; is_a boolean; recap jsonb;
begin
 select * into m from public.st_matches where id=p_match for update;
 if not found then raise exception 'Match not found'; end if;
 select * into h from public.homes where id=m.home_id and (a=auth.uid() or b=auth.uid());
 if not found then raise exception 'Not a member of this match'; end if;
 is_a:=h.a=auth.uid();
 update public.st_matches set seen_a=case when is_a then clock_timestamp() else seen_a end,
   seen_b=case when not is_a then clock_timestamp() else seen_b end where id=p_match;
 perform public.st_progress(p_match);
 select * into m from public.st_matches where id=p_match;
 select * into r from public.st_rounds where match_id=p_match and round_no=m.round_no;
 select coalesce(jsonb_agg(jsonb_build_object(
   'number',rr.round_no,'category',rr.category,'letter',rr.letter,
   'you',case when is_a then rr.a_answer else rr.b_answer end,
   'partner',case when is_a then rr.b_answer else rr.a_answer end,
   'matched',rr.matched) order by rr.round_no),'[]'::jsonb)
 into recap from public.st_rounds rr where rr.match_id=p_match and rr.matched is not null;
 return jsonb_build_object(
  'match_id',m.id,'status',m.status,'phase',m.phase,
  'round_no',m.round_no,'score',m.score,'total_rounds',5,
  'category',r.category,'letter',r.letter,
  'my_category',case when is_a then m.category_a else m.category_b end,
  'partner_category',case when is_a then m.category_b else m.category_a end,
  'my_ready',case when is_a then m.ready_a else m.ready_b end,
  'partner_ready',case when is_a then m.ready_b else m.ready_a end,
  'partner_online',coalesce(case when is_a then m.seen_b else m.seen_a end > clock_timestamp()-interval '7 seconds',false),
  'my_submitted',case when is_a then r.a_answer is not null else r.b_answer is not null end,
  'partner_submitted',case when is_a then r.b_answer is not null else r.a_answer is not null end,
  'my_answer',case when m.phase in ('reveal','done') then case when is_a then r.a_answer else r.b_answer end end,
  'partner_answer',case when m.phase in ('reveal','done') then case when is_a then r.b_answer else r.a_answer end end,
  'matched',case when m.phase in ('reveal','done') then r.matched end,
  'server_now',clock_timestamp(), 'deadline',m.phase_ends_at,
  'recap',recap
 );
end $$;

create or replace function public.st_cancel(p_match uuid) returns void
language plpgsql security definer set search_path = '' as $$
declare m public.st_matches;
begin
 select * into m from public.st_matches where id=p_match for update;
 if not found or not exists (select 1 from public.homes where id=m.home_id
     and (a=auth.uid() or b=auth.uid())) then raise exception 'Not a member of this match'; end if;
 update public.st_matches set status='cancelled',phase='done',phase_ends_at=null,
   updated_at=clock_timestamp() where id=p_match and status in ('lobby','active');
end $$;

-- Restrict private Realtime wake-up events to just the two home members.
-- No guesses, prompts, scores or other game data are sent over Broadcast.
create or replace function public.st_topic_allowed(p_topic text) returns boolean
language sql stable security definer set search_path = '' as $$
 select exists(select 1 from public.st_matches m join public.homes h on h.id=m.home_id
   where p_topic='same-thought:'||m.id::text and (h.a=auth.uid() or h.b=auth.uid()));
$$;

revoke all on function public.st_join_or_create(),public.st_choose_category(uuid,text),
 public.st_set_ready(uuid,boolean),public.st_submit(uuid,integer,text),
 public.st_state(uuid),public.st_cancel(uuid),public.st_topic_allowed(text)
 from public,anon,authenticated;
grant execute on function public.st_join_or_create(),public.st_choose_category(uuid,text),
 public.st_set_ready(uuid,boolean),public.st_submit(uuid,integer,text),
 public.st_state(uuid),public.st_cancel(uuid),public.st_topic_allowed(text)
 to authenticated;

-- Realtime Authorization: do NOT alter realtime.messages RLS (Supabase already owns/enables it).
drop policy if exists st_private_listen on realtime.messages;
create policy st_private_listen on realtime.messages for select to authenticated
using (extension in ('broadcast','presence') and public.st_topic_allowed(realtime.topic()));
drop policy if exists st_private_send on realtime.messages;
create policy st_private_send on realtime.messages for insert to authenticated
with check (extension in ('broadcast','presence') and public.st_topic_allowed(realtime.topic()));
