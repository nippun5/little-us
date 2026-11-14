// Little Us: server-only FCM HTTP v1 sender.
// Database Webhook: INSERT on public.push_outbox, x-little-us-hook header.
// Deploy with --no-verify-jwt; the webhook's dedicated random secret is checked
// BEFORE any privileged data is accessed. Do not expose that secret in Flutter.

import { createClient } from 'npm:@supabase/supabase-js@2';
import { notificationForKind, webhookEventId, isUnregisteredFcmToken } from './logic.mjs';

type ServiceAccount = {
  project_id: string;
  client_email: string;
  private_key: string;
  token_uri?: string;
};

type PushEvent = {
  id: string;
  kind: string;
  recipient_id: string;
  source_id: string;
};

const encoder = new TextEncoder();

async function safeEqual(actual: string | null, expected: string): Promise<boolean> {
  if (!actual || expected.length < 32) return false;
  const [a, b] = await Promise.all([
    crypto.subtle.digest('SHA-256', encoder.encode(actual)),
    crypto.subtle.digest('SHA-256', encoder.encode(expected)),
  ]);
  const aa = new Uint8Array(a);
  const bb = new Uint8Array(b);
  let difference = 0;
  for (let i = 0; i < aa.length; i++) difference |= aa[i] ^ bb[i];
  return difference === 0;
}

function base64url(bytes: Uint8Array): string {
  let value = '';
  for (const byte of bytes) value += String.fromCharCode(byte);
  return btoa(value).replace(/=/g, '').replace(/\+/g, '-').replace(/\//g, '_');
}

async function oauthAccessToken(service: ServiceAccount): Promise<string> {
  const privateKeyBytes = atob(service.private_key
    .replace(/-----BEGIN PRIVATE KEY-----|-----END PRIVATE KEY-----|\s/g, ''));
  const key = await crypto.subtle.importKey(
    'pkcs8', Uint8Array.from(privateKeyBytes, x => x.charCodeAt(0)),
    { name: 'RSASSA-PKCS1-v1_5', hash: 'SHA-256' }, false, ['sign'],
  );
  const now = Math.floor(Date.now() / 1000);
  const uri = service.token_uri || 'https://oauth2.googleapis.com/token';
  const head = base64url(encoder.encode(JSON.stringify({ alg: 'RS256', typ: 'JWT' })));
  const body = base64url(encoder.encode(JSON.stringify({
    iss: service.client_email,
    scope: 'https://www.googleapis.com/auth/firebase.messaging',
    aud: uri, iat: now, exp: now + 3600,
  })));
  const unsigned = `${head}.${body}`;
  const signature = await crypto.subtle.sign('RSASSA-PKCS1-v1_5', key, encoder.encode(unsigned));
  const assertion = `${unsigned}.${base64url(new Uint8Array(signature))}`;
  const response = await fetch(uri, {
    method: 'POST',
    headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
    body: new URLSearchParams({
      grant_type: 'urn:ietf:params:oauth:grant-type:jwt-bearer', assertion,
    }),
  });
  if (!response.ok) throw new Error(`OAuth token request failed: ${response.status}`);
  const data = await response.json();
  if (typeof data.access_token !== 'string') throw new Error('No OAuth token returned');
  return data.access_token;
}

async function fcmSend(
  service: ServiceAccount, accessToken: string, token: string, event: PushEvent,
): Promise<{ ok: boolean; unregistered: boolean }> {
  const notification = notificationForKind(event.kind);
  if (!notification) return { ok: false, unregistered: false };
  const response = await fetch(
    `https://fcm.googleapis.com/v1/projects/${encodeURIComponent(service.project_id)}/messages:send`,
    {
      method: 'POST',
      headers: {
        Authorization: `Bearer ${accessToken}`,
        'Content-Type': 'application/json',
      },
      body: JSON.stringify({
        message: {
          token,
          notification,
          data: { kind: event.kind, source_id: event.source_id },
          android: { priority: 'high' },
          apns: {
            headers: { 'apns-push-type': 'alert', 'apns-priority': '10' },
            payload: { aps: { sound: 'default' } },
          },
        },
      }),
    },
  );
  if (response.ok) return { ok: true, unregistered: false };
  const body = await response.json().catch(() => ({}));
  // Do not log tokens, private message data, or service credentials.
  console.warn(`FCM send returned ${response.status}`);
  return { ok: false, unregistered: isUnregisteredFcmToken(body) };
}

Deno.serve(async (request) => {
  if (request.method !== 'POST') return new Response('Method not allowed', { status: 405 });
  const expected = Deno.env.get('PUSH_WEBHOOK_SECRET') || '';
  if (!await safeEqual(request.headers.get('x-little-us-hook'), expected)) {
    return new Response('Unauthorized', { status: 401 });
  }
  let payload: unknown;
  try { payload = await request.json(); } catch {
    return new Response('Invalid JSON', { status: 400 });
  }
  const id = webhookEventId(payload);
  if (!id) return new Response('Ignored event', { status: 200 });

  const url = Deno.env.get('SUPABASE_URL');
  const role = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY');
  const accountJson = Deno.env.get('FIREBASE_SERVICE_ACCOUNT_JSON');
  if (!url || !role || !accountJson) {
    console.error('Push sender missing required server-side configuration');
    return new Response('Server configuration incomplete', { status: 500 });
  }
  const admin = createClient(url, role, {
    auth: { autoRefreshToken: false, persistSession: false },
  });
  const { data: claimed, error: claimError } = await admin.rpc('push_claim', { p_id: id });
  if (claimError) {
    console.error('Failed to claim notification event');
    return new Response('Claim failed', { status: 500 });
  }
  if (!claimed) return new Response('Already processed', { status: 200 });
  const event = claimed as PushEvent;

  const complete = async (status: string, error: string | null = null) => {
    const { error: updateError } = await admin.from('push_outbox')
      .update({ status, error, processed_at: new Date().toISOString() })
      .eq('id', id);
    if (updateError) console.error('Could not record push delivery outcome');
  };

  try {
    if (!notificationForKind(event.kind)) {
      await complete('skipped');
      return new Response('Unsupported notification', { status: 200 });
    }
    const cutoff = new Date(Date.now() - 90 * 24 * 3600 * 1000).toISOString();
    const { data: devices, error: readError } = await admin.from('push_devices')
      .select('token').eq('user_id', event.recipient_id)
      .gte('updated_at', cutoff).limit(20);
    if (readError) throw new Error('Device token lookup failed');
    if (!devices?.length) {
      await complete('skipped');
      return new Response('No opted-in devices', { status: 200 });
    }
    const service = JSON.parse(accountJson) as ServiceAccount;
    if (!service.project_id || !service.client_email || !service.private_key) {
      throw new Error('Incomplete Firebase service account');
    }
    const accessToken = await oauthAccessToken(service);
    let delivered = 0;
    let failures = 0;
    for (const device of devices) {
      const result = await fcmSend(service, accessToken, device.token, event);
      if (result.ok) delivered++;
      else if (result.unregistered) {
        await admin.from('push_devices').delete().eq('token', device.token)
          .eq('user_id', event.recipient_id);
      } else failures++;
    }
    // No immediate automatic retries on partial success: avoid duplicate pushes.
    await complete(delivered > 0 ? 'sent' : (failures ? 'failed' : 'skipped'),
      failures ? `${failures} device delivery failure(s)` : null);
    return new Response(JSON.stringify({ ok: delivered > 0, devices: devices.length }), {
      status: 200, headers: { 'Content-Type': 'application/json' },
    });
  } catch (error) {
    console.error('Push delivery failed:', String(error).slice(0, 160));
    await complete('failed', 'Delivery failed; see Edge Function logs');
    return new Response('Delivery failed', { status: 500 });
  }
});
