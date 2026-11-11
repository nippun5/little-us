// Offline PostgreSQL-semantic tests using the project's existing PGlite dependency.
// Run from the repository's supabase directory: node same_thought_test.mjs
import { readFileSync } from 'node:fs';
import assert from 'node:assert/strict';
import { PGlite } from '@electric-sql/pglite';

const db = new PGlite();
const ids = {
  a: 'aaaaaaaa-aaaa-4aaa-aaaa-aaaaaaaaaaaa',
  b: 'bbbbbbbb-bbbb-4bbb-bbbb-bbbbbbbbbbbb',
  outsider: 'cccccccc-cccc-4ccc-cccc-cccccccccccc',
  home: 'dddddddd-dddd-4ddd-dddd-dddddddddddd',
};

const sql = (query, params = []) => db.query(query, params);
const one = async (query, params = []) => (await sql(query, params)).rows[0];
const as = async (userId) => sql(`select set_config('request.jwt.claim.sub',$1,false)`, [userId]);
const call = async (fn, args = [], types = []) => {
  const ph = args.map((_, i) => `$${i + 1}${types[i] ? `::${types[i]}` : ''}`).join(',');
  const result = await sql(`select public.${fn}(${ph}) as value`, args);
  return result.rows[0].value;
};
const shouldFail = async (work, message) => {
  let failed = false;
  try { await work(); } catch { failed = true; }
  assert.equal(failed, true, message);
};

await db.exec(`
  create role anon; create role authenticated;
  create schema auth;
  create table auth.users (id uuid primary key);
  create function auth.uid() returns uuid language sql stable as $$
    select nullif(current_setting('request.jwt.claim.sub',true),'')::uuid;
  $$;
  create schema realtime;
  create table realtime.messages (topic text,extension text);
  create function realtime.topic() returns text language sql stable as $$
    select current_setting('realtime.topic',true);
  $$;
  create table public.homes (
    id uuid primary key default gen_random_uuid(),
    a uuid not null references auth.users(id),
    b uuid references auth.users(id)
  );
`);
await sql('insert into auth.users(id) values($1),($2),($3)', [ids.a, ids.b, ids.outsider]);
await sql('insert into public.homes(id,a,b) values ($1,$2,$3)', [ids.home,ids.a,ids.b]);
await db.exec(readFileSync(new URL('./same_thought.sql', import.meta.url), 'utf8'));

await as(ids.a);
const match = await call('st_join_or_create');
assert.ok(match);
await as(ids.b);
assert.equal(await call('st_join_or_create'), match, 'both partners join same match');
await as(ids.outsider);
await shouldFail(() => call('st_join_or_create'), 'outsider cannot join a home');
await shouldFail(() => call('st_state',[match],['uuid']), 'outsider cannot view state');
await shouldFail(() => call('st_submit',[match,1,'cat'],['uuid','integer','text']), 'outsider cannot submit');
assert.equal(await call('st_topic_allowed',[`same-thought:${match}`],['text']),false,'outsider cannot listen');
await as(ids.a);
assert.equal(await call('st_topic_allowed',[`same-thought:${match}`],['text']),true,'partner can listen');
await call('st_choose_category',[match,'Animals'],['uuid','text']);
await as(ids.b);
await call('st_choose_category',[match,'Food'],['uuid','text']);
await as(ids.a);
await shouldFail(() => call('st_choose_category',[match,'Nonexistent'],['uuid','text']), 'invalid category');
await call('st_set_ready',[match,true],['uuid','boolean']);
await as(ids.b);
await call('st_set_ready',[match,true],['uuid','boolean']);
let bView = await call('st_state',[match],['uuid']);
assert.equal(bView.status,'active');
assert.equal(bView.round_no,1);
assert.equal(bView.phase,'answer');
assert.equal(bView.category,'Animals');
assert.ok(bView.deadline && bView.server_now);
const wordRow = await one('select word from public.st_words where category=$1 and letter=$2 order by word limit 1',
  [bView.category,bView.letter]);
assert.ok(wordRow.word);
const word = wordRow.word;
await as(ids.a);
await shouldFail(() => call('st_submit',[match,1,'silly invalid word'],['uuid','integer','text']), 'invalid word rejected');
await call('st_submit',[match,1,`  ${word.toUpperCase()}  `],['uuid','integer','text']);
await shouldFail(() => call('st_submit',[match,1,word],['uuid','integer','text']), 'duplicate answer rejected');
await as(ids.b);
bView = await call('st_state',[match],['uuid']);
assert.equal(bView.partner_submitted,true);
assert.equal(bView.partner_answer,null,'guess never leaks before reveal');
assert.equal(bView.my_answer,null);
await call('st_submit',[match,1,word],['uuid','integer','text']);
bView = await call('st_state',[match],['uuid']);
assert.equal(bView.phase,'reveal');
assert.equal(bView.score,1);
assert.equal(bView.matched,true);
assert.equal(bView.partner_answer,word);
await shouldFail(() => call('st_submit',[match,1,word],['uuid','integer','text']), 'late answer rejected');

// Force time to pass in a disposable DB so we can test the whole match quickly.
for (let n = 1; n <= 5; n++) {
  if (n > 1) {
    bView = await call('st_state',[match],['uuid']);
    assert.equal(bView.round_no,n);
    assert.equal(bView.phase,'answer');
    assert.equal(bView.category,n % 2 === 1 ? 'Animals':'Food');
    await sql(`update public.st_matches set phase_ends_at=clock_timestamp()-interval '1 second' where id=$1`,[match]);
    bView = await call('st_state',[match],['uuid']);
    assert.equal(bView.phase,'reveal');
    assert.equal(bView.matched,false,'unanswered round scores zero');
  }
  await sql(`update public.st_matches set phase_ends_at=clock_timestamp()-interval '1 second' where id=$1`,[match]);
  bView = await call('st_state',[match],['uuid']);
}
assert.equal(bView.status,'finished');
assert.equal(bView.score,1);
assert.equal(bView.recap.length,5);
assert.equal(bView.recap.filter(r => r.matched).length,1);

await as(ids.a);
const match2 = await call('st_join_or_create');
assert.notEqual(match2,match,'new match after finished');
await as(ids.b);
assert.equal(await call('st_join_or_create'),match2);
await call('st_cancel',[match2],['uuid']);
assert.equal((await call('st_state',[match2],['uuid'])).status,'cancelled');
await as(ids.outsider);
await shouldFail(() => call('st_cancel',[match],['uuid']), 'outsider cannot cancel');
const p = await one(`select has_table_privilege('authenticated', 'public.st_rounds','select') as allowed`);
assert.equal(p.allowed,false, 'raw answer table cannot be read by authenticated users');

console.log('Same Thought backend tests passed: pairing, secret answers, validation, score, 5 rounds, timeout, replay, cancel, outsider protection, raw-table privacy.');
await db.close();
