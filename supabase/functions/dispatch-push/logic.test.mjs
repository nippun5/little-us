import test from 'node:test';
import assert from 'node:assert/strict';
import { notificationForKind, webhookEventId, isUnregisteredFcmToken } from './logic.mjs';

test('notification templates never leak message bodies or raw doodles', () => {
  for (const kind of ['fridge_note','same_thought','doodle_started','doodle_finished']) {
    const n = notificationForKind(kind);
    assert.ok(n.title.length && n.body.length);
    assert.ok(!JSON.stringify(n).includes('secret'));
  }
  assert.equal(notificationForKind('custom'), null);
});

test('webhook only accepts an outbox insert with a UUID', () => {
  const event = {schema:'public',table:'push_outbox',type:'INSERT',record:{id:'11111111-1111-4111-8111-111111111111'}};
  assert.equal(webhookEventId(event), event.record.id);
  assert.equal(webhookEventId({...event,table:'notes'}),null);
  assert.equal(webhookEventId({...event,type:'UPDATE'}),null);
  assert.equal(webhookEventId({...event,record:{id:'1 OR TRUE'}}),null);
});

test('only UNREGISTERED deletes a token', () => {
  assert.equal(isUnregisteredFcmToken({error:{details:[{errorCode:'UNREGISTERED'}]}}),true);
  assert.equal(isUnregisteredFcmToken({error:{details:[{errorCode:'INVALID_ARGUMENT'}]}}),false);
  assert.equal(isUnregisteredFcmToken({error:{status:'UNAVAILABLE'}}),false);
});
