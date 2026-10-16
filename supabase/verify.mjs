import {PGlite} from '@electric-sql/pglite';
import fs from 'node:fs';
const db=new PGlite();
await db.exec(`create schema auth;create role anon;create role authenticated;create table auth.users(id uuid primary key);create function auth.uid() returns uuid language sql as $$ select nullif(current_setting('request.jwt.claim.sub',true),'')::uuid $$;grant usage on schema auth to authenticated;grant execute on function auth.uid() to authenticated;`);
await db.exec(fs.readFileSync(new URL('./schema.sql', import.meta.url),'utf8'));
const a='00000000-0000-0000-0000-000000000001',b='00000000-0000-0000-0000-000000000002',c='00000000-0000-0000-0000-000000000003';
await db.exec(`insert into auth.users values ('${a}'),('${b}'),('${c}')`);
async function as(id){await db.exec(`reset role;set request.jwt.claim.sub='${id}';set role authenticated;`);}
async function state(){return (await db.query('select public.get_home() as x')).rows[0].x;}
function ok(c,m){if(!c)throw Error(m);console.log('PASS '+m);}
async function denied(sql,m){try{await db.exec(sql);}catch{console.log('PASS '+m);return;}throw Error('NOT DENIED '+m);}
await as(a);await db.exec(`select public.create_home('Alex')`);let x=await state();const code=x.home.invite;
await denied('select * from public.rounds','direct table access blocked');
await as(b);await db.exec(`select public.join_home('${code}','Jamie')`);
await as(c);ok((await state()).home===null,'outsider has no shared home');await denied(`select public.join_home('${code}','Other')`,'used invitation rejected');
await as(a);await db.exec(`select public.submit_round((now() at time zone 'UTC')::date,array[0,1,2],array[1,2,3]);`);
await as(b);x=await state();ok(x.rounds[0].partner===null,'partner answers hidden before both submit');
await db.exec(`select public.submit_round((now() at time zone 'UTC')::date,array[3,2,1],array[0,0,0]);`);
x=await state();ok(x.home.coins===90 && x.rounds[0].complete,'completion rewards once');ok(x.rounds[0].partner[0]===0,'answers reveal after both finish');
await denied(`select public.submit_round((now() at time zone 'UTC')::date,array[3,2,1],array[0,0,0]);`,'duplicate submission rejected');
await db.exec(`select public.decorate('lilac');select public.decorate('peach');select public.decorate('lilac');`);ok((await state()).home.coins===30,'owned decoration is not charged twice');
await denied(`select public.decorate('rose')`,'insufficient balance protected');
await db.exec(`select public.add_note('Hello');select public.set_reunion(current_date+10);`);ok((await state()).notes.length===1,'notes stored');
await as(c);ok((await state()).notes===undefined,'notes not exposed to outsider');
await as(a);await db.exec('select public.delete_my_account()');await as(b);ok((await state()).home===null,'deletion removes shared home for partner');
await db.exec('reset role');ok((await db.query('select count(*)::int n from public.notes')).rows[0].n===0,'deletion cascades notes');ok((await db.query('select count(*)::int n from public.rounds')).rows[0].n===0,'deletion cascades rounds');ok((await db.query(`select count(*)::int n from auth.users where id='${a}'`)).rows[0].n===0,'account deleted');
await db.close();
