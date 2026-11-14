/** Only these four safe, generic strings go into push notifications. */
export const templates = Object.freeze({
  fridge_note: {
    title: 'A little note for you 💌',
    body: 'Your partner left a new note on the fridge.',
  },
  same_thought: {
    title: 'Want to play together? 💕',
    body: 'Your person invited you to Same Thought.',
  },
  doodle_started: {
    title: 'A doodle needs you 🎨',
    body: 'Your partner started a drawing for you to finish.',
  },
  doodle_finished: {
    title: 'Your doodle is finished ✨',
    body: 'Your partner completed your drawing.',
  },
});

export function notificationForKind(kind) {
  return Object.hasOwn(templates, kind) ? templates[kind] : null;
}

export function webhookEventId(payload) {
  if (payload?.schema !== 'public' || payload?.table !== 'push_outbox'
    || payload?.type !== 'INSERT') return null;
  const id = payload?.record?.id;
  return typeof id === 'string' &&
    /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i.test(id)
    ? id : null;
}

export function isUnregisteredFcmToken(error) {
  return error?.error?.details?.some?.((x) => x?.errorCode === 'UNREGISTERED') === true;
}
