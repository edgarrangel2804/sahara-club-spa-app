// Edge Function — send-booking-reminders (FCM v1 API)
// Cron jobs configurados en pg_cron:
//   sahara-reminder-vispera : 0 1 * * *   (8 PM México CDT)
//   sahara-reminder-2h      : 0 * * * *   (cada hora, busca citas en 2h)

import { serve } from 'https://deno.land/std@0.177.0/http/server.ts';
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2';

const SUPABASE_URL  = Deno.env.get('SUPABASE_URL')!;
const SERVICE_KEY   = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!;
// JSON completo de la cuenta de servicio de Firebase (como string)
const SA_JSON       = Deno.env.get('FIREBASE_SERVICE_ACCOUNT')!;
const PROJECT_ID    = 'sahara-club-spa';

const supabase = createClient(SUPABASE_URL, SERVICE_KEY);

serve(async (req) => {
  try {
    const { type } = await req.json() as { type: 'day_before' | 'two_hours' };

    const now = new Date();
    let bookings: any[] = [];

    if (type === 'day_before') {
      const tomorrow = new Date(now);
      tomorrow.setDate(tomorrow.getDate() + 1);
      const dateStr = tomorrow.toISOString().split('T')[0];

      const { data, error } = await supabase
        .from('bookings')
        .select(`id, booking_date, booking_time, service_name, services(name),
                 client:profiles!bookings_client_id_fkey(id, full_name)`)
        .eq('booking_date', dateStr)
        .in('status', ['scheduled', 'confirmed']);

      if (error) throw error;
      bookings = data ?? [];

    } else if (type === 'two_hours') {
      const target = new Date(now.getTime() + 2 * 60 * 60 * 1000);
      const dateStr = target.toISOString().split('T')[0];
      const hh = String(target.getUTCHours()).padStart(2, '0');
      const mm = String(target.getUTCMinutes()).padStart(2, '0');
      const timeStr = `${hh}:${mm}:00`;

      const { data, error } = await supabase
        .from('bookings')
        .select(`id, booking_date, booking_time, service_name, services(name),
                 client:profiles!bookings_client_id_fkey(id, full_name)`)
        .eq('booking_date', dateStr)
        .eq('booking_time', timeStr)
        .in('status', ['scheduled', 'confirmed']);

      if (error) throw error;
      bookings = data ?? [];
    } else {
      return new Response(JSON.stringify({ error: 'type inválido' }), { status: 400 });
    }

    if (bookings.length === 0) {
      return new Response(JSON.stringify({ sent: 0, bookings: 0 }), { status: 200 });
    }

    const accessToken = await getAccessToken(SA_JSON);
    let sent = 0;

    for (const booking of bookings) {
      const clientId = booking.client?.id;
      if (!clientId) continue;

      const serviceName = booking.services?.name ?? booking.service_name ?? 'tu cita';
      const dateLabel   = formatDate(booking.booking_date);
      const timeLabel   = (booking.booking_time as string)?.substring(0, 5) ?? '';

      const { title, body } = type === 'day_before'
        ? {
            title: '✨ Tu cita es mañana — Sahara Club Spa',
            body:  `${serviceName} · ${dateLabel} a las ${timeLabel}. ¡Te esperamos!`,
          }
        : {
            title: '⏰ Tu cita empieza en 2 horas',
            body:  `${serviceName} a las ${timeLabel}. Recuerda llegar 10 min antes.`,
          };

      const { data: tokens } = await supabase
        .from('device_tokens')
        .select('token')
        .eq('user_id', clientId);

      if (!tokens?.length) continue;

      for (const { token } of tokens) {
        const ok = await sendFcmV1(accessToken, token, title, body, {
          type, booking_id: booking.id,
        });
        if (ok) {
          sent++;
          await supabase.from('notification_log').insert({
            user_id: clientId, booking_id: booking.id,
            type, title, body, status: 'sent',
          });
        }
      }
    }

    return new Response(JSON.stringify({ sent }), { status: 200 });

  } catch (e) {
    console.error(e);
    return new Response(JSON.stringify({ error: String(e) }), { status: 500 });
  }
});

// ── FCM v1 ────────────────────────────────────────────────────────────────────

async function sendFcmV1(
  accessToken: string,
  token: string,
  title: string,
  body: string,
  data: Record<string, string>,
): Promise<boolean> {
  try {
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
            data,
            android: {
              notification: {
                sound:                'alerta_push',
                channel_id:           'sahara_reminders_v3',
                notification_priority: 'PRIORITY_HIGH',
              },
              priority: 'HIGH',
            },
            apns: {
              payload: { aps: { sound: 'alerta_push.mp3', badge: 1 } },
              headers: { 'apns-priority': '10' },
            },
          },
        }),
      },
    );
    if (!res.ok) {
      const err = await res.text();
      console.error('FCM error:', err);
    }
    return res.ok;
  } catch (e) {
    console.error('sendFcmV1 error:', e);
    return false;
  }
}

// ── OAuth2 con Service Account ────────────────────────────────────────────────

async function getAccessToken(saJsonString: string): Promise<string> {
  const sa = JSON.parse(saJsonString);
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

  // Importar clave privada RSA
  const pemKey = sa.private_key as string;
  const pemBody = pemKey
    .replace('-----BEGIN PRIVATE KEY-----', '')
    .replace('-----END PRIVATE KEY-----', '')
    .replace(/\s/g, '');
  const keyBytes = Uint8Array.from(atob(pemBody), (c) => c.charCodeAt(0));

  const cryptoKey = await crypto.subtle.importKey(
    'pkcs8', keyBytes.buffer,
    { name: 'RSASSA-PKCS1-v1_5', hash: 'SHA-256' },
    false, ['sign'],
  );

  const signatureBytes = await crypto.subtle.sign(
    'RSASSA-PKCS1-v1_5',
    cryptoKey,
    new TextEncoder().encode(unsigned),
  );

  const signature = btoa(String.fromCharCode(...new Uint8Array(signatureBytes)))
    .replace(/\+/g, '-').replace(/\//g, '_').replace(/=+$/, '');

  const jwt = `${unsigned}.${signature}`;

  // Intercambiar JWT por access token
  const tokenRes = await fetch('https://oauth2.googleapis.com/token', {
    method: 'POST',
    headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
    body: `grant_type=urn%3Aietf%3Aparams%3Aoauth%3Agrant-type%3Ajwt-bearer&assertion=${jwt}`,
  });

  const tokenData = await tokenRes.json();
  return tokenData.access_token as string;
}

// ── Helpers ───────────────────────────────────────────────────────────────────

function formatDate(dateStr: string): string {
  const months = ['ene','feb','mar','abr','may','jun','jul','ago','sep','oct','nov','dic'];
  const [, month, day] = dateStr.split('-').map(Number);
  return `${day} de ${months[month - 1]}`;
}
