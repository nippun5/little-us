/**
 * Run against a TEST Supabase project with two paired accounts and an unrelated third.
 * Environment variables:
 *   SUPABASE_URL, SUPABASE_ANON_KEY,
 *   TEST_A_EMAIL, TEST_A_PASSWORD, TEST_B_EMAIL, TEST_B_PASSWORD,
 *   TEST_OUTSIDER_EMAIL, TEST_OUTSIDER_PASSWORD
 * `npm install @supabase/supabase-js` once before running.
 * Test doodles are deleted in finally. Never use production accounts.
 */
import assert from 'node:assert/strict';
import { createClient } from '@supabase/supabase-js';

const keys = ['SUPABASE_URL', 'SUPABASE_ANON_KEY', 'TEST_A_EMAIL', 'TEST_A_PASSWORD',
  'TEST_B_EMAIL', 'TEST_B_PASSWORD', 'TEST_OUTSIDER_EMAIL', 'TEST_OUTSIDER_PASSWORD'];
for (const key of keys) if (!process.env[key]) throw new Error(`Missing ${key}`);

async function signedIn(prefix) {
  const client = createClient(process.env.SUPABASE_URL, process.env.SUPABASE_ANON_KEY,
    { auth: { persistSession: false, autoRefreshToken: false } });
  const { error } = await client.auth.signInWithPassword({
    email: process.env[`${prefix}_EMAIL`],
    password: process.env[`${prefix}_PASSWORD`],
  });
  if (error) throw error;
  return client;
}

const [a, b, outsider] = await Promise.all([
  signedIn('TEST_A'), signedIn('TEST_B'), signedIn('TEST_OUTSIDER'),
]);
const prompt = 'Start a funny monster';
const strokes = [{ c: '#455A64', w: 5, p: [[0.1, 0.2], [0.2, 0.3]] }];
let id;

try {
  const outsiderList = await outsider.rpc('doodle_list');
  assert.ok(outsiderList.error, 'Unpaired account should not read doodles');

  const created = await a.rpc('doodle_start', { p_prompt: prompt, p_strokes: strokes });
  assert.ifError(created.error);
  id = created.data;
  assert.match(id, /^[0-9a-f-]{36}$/i);

  const visible = await b.rpc('doodle_list');
  assert.ifError(visible.error);
  const entry = visible.data.find(item => item.id === id);
  assert.ok(entry, 'Partner should see unfinished doodle');
  assert.equal(entry.is_mine, false);
  assert.equal(entry.is_finished, false);
  assert.equal(entry.finish_strokes.length, 0);

  const duplicate = await b.rpc('doodle_start', { p_prompt: prompt, p_strokes: strokes });
  assert.ok(duplicate.error, 'Cannot start a second doodle while one is open');

  const selfFinish = await a.rpc('doodle_finish', { p_id: id, p_strokes: strokes });
  assert.ok(selfFinish.error, 'Starter cannot finish their own doodle');

  const outsiderFinish = await outsider.rpc('doodle_finish', { p_id: id, p_strokes: strokes });
  assert.ok(outsiderFinish.error, 'Outsider cannot finish');

  const invalid = await b.rpc('doodle_finish', { p_id: id,
    p_strokes: [{ c: '#455A64', w: 5, p: [[-10, 0], [0.3, 0.4]] }] });
  assert.ok(invalid.error, 'Reject out-of-bounds geometry');

  const done = await b.rpc('doodle_finish', { p_id: id, p_strokes: strokes });
  assert.ifError(done.error);
  const again = await b.rpc('doodle_finish', { p_id: id, p_strokes: strokes });
  assert.ok(again.error, 'Cannot overwrite finished doodle');

  const updated = await a.rpc('doodle_list');
  assert.ifError(updated.error);
  const finished = updated.data.find(item => item.id === id);
  assert.equal(finished.is_finished, true);
  assert.equal(finished.finish_strokes.length, 1);

  const outsiderDelete = await outsider.rpc('doodle_delete', { p_id: id });
  assert.ok(outsiderDelete.error, 'Outsider cannot delete');
  console.log('PASS: private reads, starter/finisher rules, geometry checks, replay data');
} finally {
  if (id) {
    const result = await a.rpc('doodle_delete', { p_id: id });
    if (result.error) console.warn('Cleanup failed:', result.error.message);
  }
}
