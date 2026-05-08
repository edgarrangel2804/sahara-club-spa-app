// Edge Function — send-push-notification
// Recibe { user_id, title, body, data } desde el trigger notify_push de la DB
// Busca el fcm_token del usuario en profiles y envía el push via FCM v1

import { serve } from 'https://deno.land/std@0.177.0/http/server.ts';
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2';

const SUPABASE_URL  = Deno.env.get('SUPABASE_URL')!;
const SERVICE_KEY   = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!;
const SA_JSON       = Deno.env.get('FIREBASE_SERVICE_ACCOUNT')!;
const PROJECT_ID    = 'sahara-club-spa';

const supabase = createClient(SUPABASE_URL, SERVICE_KEY);

serve(async (req) => {
  try {
    const { user_id, title, body, data } = await req.json() as {
      user_id: string;
      title:   string;
      body:    string;
      data?:   Record<string, string>;
    };

    if (!user_id || !title || !body) {
      return new Response(JSON.stringify({ error: 'user_id, title y body son requeridos' }), { status: 400 });
    }

    const { data: profile } = await supabase
      .from('profiles')
      .select('fcm_token')
      .eq('id', user_id)
      .maybeSingle();

    const token = profile?.fcm_token as string | null;
    if (!token) {
      return new Response(JSON.stringify({ sent: 0, reason: 'sin_token' }), { status: 200 });
    }

    const accessToken = await getAccessToken(SA_JSON);
    const { ok } = await sendFcm(accessToken, token, title, body, data ?? {});

    if (ok) {
      try {
        await supabase.from('notifications').insert({ user_id, title, body, data: data ?? {} });
      } catch {}
      return new Response(JSON.stringify({ sent: 1 }), { status: 200 });
    }

    // FCM rechazó el token (UNREGISTERED). saveTokenForCurrentUser() tarda ~2-3 s en guardar
    // el token nuevo (Firebase getToken + escritura a Supabase). Esperamos 4 s antes del re-fetch
    // para darle tiempo al app de actualizar el token en la DB.
    await new Promise((resolve) => setTimeout(resolve, 4000));

    const { data: freshProfile } = await supabase
      .from('profiles')
      .select('fcm_token')
      .eq('id', user_id)
      .maybeSingle();

    const freshToken = freshProfile?.fcm_token as string | null;

    if (freshToken && freshToken !== token) {
      const { ok: retryOk } = await sendFcm(accessToken, freshToken, title, body, data ?? {});
      if (retryOk) {
        try {
          await supabase.from('notifications').insert({ user_id, title, body, data: data ?? {} });
        } catch {}
        return new Response(JSON.stringify({ sent: 1, retried: true }), { status: 200 });
      }
      // El token nuevo también falló — limpiar solo ese token
      try {
        await supabase.from('profiles').update({ fcm_token: null }).eq('id', user_id).eq('fcm_token', freshToken);
      } catch {}
    } else {
      // Token sigue siendo el mismo obsoleto — limpiar condicionalmente para no sobreescribir un token
      // que el app pudiera haber guardado justo entre nuestra lectura y ahora
      try {
        await supabase.from('profiles').update({ fcm_token: null }).eq('id', user_id).eq('fcm_token', token);
      } catch {}
    }

    return new Response(JSON.stringify({ sent: 0 }), { status: 200 });

  } catch (e) {
    console.error('send-push-notification error:', e);
    return new Response(JSON.stringify({ error: String(e) }), { status: 500 });
  }
});

async function sendFcm(
  accessToken: string,
  token: string,
  title: string,
  body: string,
  data: Record<string, string>,
): Promise<{ ok: boolean }> {
  try {
    // El canal siempre es reminders (alerta_push) para push de background y foreground-no-en-chat.
    // Cuando el usuario YA está en el chat, Flutter elige sahara_chat_v3 desde el listener local.
    const channelId = 'sahara_reminders_v3';
    const sound     = 'alerta_push';
    const iosSound  = 'alerta_push.mp3';

    const res = await fetch(
      `https://fcm.googleapis.com/v1/projects/${PROJECT_ID}/messages:send`,
      {
        method: 'POST',
        headers: {
          'Content-Type':  'application/json',
          'Authorization': `Bearer ${accessToken}`,
        },
        body: JSON.stringify({
          message: {
            token,
            notification: { title, body },
            data: Object.fromEntries(
              Object.entries(data).map(([k, v]) => [k, String(v)])
            ),
            android: {
              notification: {
                sound,
                channel_id: channelId,
                notification_priority: 'PRIORITY_HIGH',
              },
              priority: 'HIGH',
            },
            apns: {
              payload: { aps: { sound: iosSound, badge: 1 } },
              headers: { 'apns-priority': '10' },
            },
          },
        }),
      },
    );
    if (!res.ok) console.error('FCM error:', await res.text());
    return { ok: res.ok };
  } catch (e) {
    console.error('sendFcm error:', e);
    return { ok: false };
  }
}

async function getAccessToken(saJsonString: string): Promise<string> {
  const sa  = JSON.parse(saJsonString);
  const now = Math.floor(Date.now() / 1000);

  const header  = { alg: 'RS256', typ: 'JWT' };
  const payload = {
    iss:   sa.client_email,
    scope: 'https://www.googleapis.com/auth/firebase.messaging',
    aud:   'https://oauth2.googleapis.com/token',
    iat:   now,
    exp:   now + 3600,
  };

  const encode = (obj: object) =>
    btoa(JSON.stringify(obj))
      .replace(/\+/g, '-').replace(/\//g, '_').replace(/=+$/, '');

  const unsigned = `${encode(header)}.${encode(payload)}`;

  const pemBody = (sa.private_key as string)
    .replace('-----BEGIN PRIVATE KEY-----', '')
    .replace('-----END PRIVATE KEY-----', '')
    .replace(/\s/g, '');

  const keyBytes  = Uint8Array.from(atob(pemBody), (c) => c.charCodeAt(0));
  const cryptoKey = await crypto.subtle.importKey(
    'pkcs8', keyBytes.buffer,
    { name: 'RSASSA-PKCS1-v1_5', hash: 'SHA-256' },
    false, ['sign'],
  );

  const sigBytes = await crypto.subtle.sign(
    'RSASSA-PKCS1-v1_5', cryptoKey, new TextEncoder().encode(unsigned),
  );

  const sig = btoa(String.fromCharCode(...new Uint8Array(sigBytes)))
    .replace(/\+/g, '-').replace(/\//g, '_').replace(/=+$/, '');

  const tokenRes = await fetch('https://oauth2.googleapis.com/token', {
    method: 'POST',
    headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
    body: `grant_type=urn%3Aietf%3Aparams%3Aoauth%3Agrant-type%3Ajwt-bearer&assertion=${unsigned}.${sig}`,
  });

  const { access_token } = await tokenRes.json();
  return access_token as string;
}
