// Edge Function — notify-booking-event
// Maneja 3 tipos de notificaciones:
//   new_booking        → push a todas las recepcionistas activas
//   booking_confirmed  → push al cliente cuya cita fue confirmada
//   therapist_assigned → push al terapeuta asignado a la cita

import { serve } from 'https://deno.land/std@0.177.0/http/server.ts';
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2';

const SUPABASE_URL = Deno.env.get('SUPABASE_URL')!;
const SERVICE_KEY  = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!;
const SA_JSON      = Deno.env.get('FIREBASE_SERVICE_ACCOUNT')!;
const PROJECT_ID   = 'sahara-club-spa';

const supabase = createClient(SUPABASE_URL, SERVICE_KEY);

serve(async (req) => {
  try {
    const { type, booking_id } = await req.json() as {
      type: 'new_booking' | 'booking_confirmed' | 'therapist_assigned';
      booking_id: string;
    };

    if (!booking_id) {
      return new Response(JSON.stringify({ error: 'booking_id requerido' }), { status: 400 });
    }

    // ── Obtener datos completos de la cita ────────────────────────────────────
    const { data: booking, error: bookingErr } = await supabase
      .from('bookings')
      .select(`
        id, booking_date, booking_time, therapist_id,
        services(name),
        client:profiles!bookings_client_id_fkey(id, full_name, fcm_token),
        therapist:staff!bookings_therapist_id_fkey(id, full_name)
      `)
      .eq('id', booking_id)
      .single();

    if (bookingErr || !booking) {
      console.error('Error obteniendo cita:', bookingErr);
      return new Response(JSON.stringify({ error: 'Cita no encontrada' }), { status: 404 });
    }

    const serviceName = (booking.services as any)?.name ?? 'Servicio';
    const dateLabel   = formatDate(booking.booking_date as string);
    const timeLabel   = (booking.booking_time as string)?.substring(0, 5) ?? '';
    const clientName  = (booking.client as any)?.full_name ?? 'Cliente';

    const accessToken = await getAccessToken(SA_JSON);
    let sent = 0;

    // ── CASO 1: nueva reserva → notificar a todas las recepcionistas ──────────
    if (type === 'new_booking') {
      const { data: receptionists } = await supabase
        .from('profiles')
        .select('id, fcm_token')
        .eq('role', 'receptionist')
        .eq('is_active', true)
        .not('fcm_token', 'is', null);

      if (!receptionists?.length) {
        return new Response(JSON.stringify({ sent: 0, message: 'Sin recepcionistas con token' }), { status: 200 });
      }

      const title = '📅 Nueva reserva — Sahara Club Spa';
      const body  = `${clientName} reservó ${serviceName} para el ${dateLabel} a las ${timeLabel}`;

      for (const r of receptionists) {
        if (!r.fcm_token) continue;
        const ok = await sendFcm(accessToken, r.fcm_token, title, body, {
          type: 'new_booking',
          booking_id,
        });
        if (ok) {
          sent++;
          await logNotification(r.id, booking_id, type, title, body);
        }
      }
    }

    // ── CASO 2: cita confirmada → notificar al cliente ────────────────────────
    else if (type === 'booking_confirmed') {
      const client = booking.client as any;
      if (!client?.fcm_token) {
        return new Response(
          JSON.stringify({ sent: 0, message: 'Cliente sin token FCM registrado' }),
          { status: 200 },
        );
      }

      const therapistName = (booking.therapist as any)?.full_name;
      const therapistPart = therapistName ? ` con ${therapistName.split(' ')[0]}` : '';

      const title = '✅ Tu cita fue confirmada — Sahara Club Spa';
      const body  = `${serviceName}${therapistPart} · ${dateLabel} a las ${timeLabel}. ¡Te esperamos!`;

      const ok = await sendFcm(accessToken, client.fcm_token, title, body, {
        type: 'booking_confirmed',
        booking_id,
      });
      if (ok) {
        sent++;
        await logNotification(client.id, booking_id, type, title, body);
      }
    }

    // ── CASO 3: terapeuta asignado → notificar al terapeuta ──────────────────
    else if (type === 'therapist_assigned') {
      const therapist = booking.therapist as any;
      const therapistId = therapist?.id ?? (booking as any).therapist_id;
      if (!therapistId) {
        return new Response(
          JSON.stringify({ sent: 0, message: 'Cita sin terapeuta asignado' }),
          { status: 200 },
        );
      }

      // FCM token is stored in profiles (therapists with a mobile app account).
      const { data: therapistProfile } = await supabase
        .from('profiles')
        .select('fcm_token')
        .eq('id', therapistId)
        .maybeSingle();

      if (!therapistProfile?.fcm_token) {
        return new Response(
          JSON.stringify({ sent: 0, message: 'Terapeuta sin token FCM registrado' }),
          { status: 200 },
        );
      }

      const title = '📋 Nueva cita asignada — Sahara Club Spa';
      const body  = `${clientName} · ${serviceName} · ${dateLabel} a las ${timeLabel}`;

      const ok = await sendFcm(accessToken, therapistProfile.fcm_token, title, body, {
        type: 'therapist_assigned',
        booking_id,
      });
      if (ok) {
        sent++;
        await logNotification(therapistId, booking_id, type, title, body);
      }
    } else {
      return new Response(JSON.stringify({ error: 'type inválido' }), { status: 400 });
    }

    return new Response(JSON.stringify({ sent }), { status: 200 });

  } catch (e) {
    console.error('notify-booking-event error:', e);
    return new Response(JSON.stringify({ error: String(e) }), { status: 500 });
  }
});

// ── Helpers ───────────────────────────────────────────────────────────────────

async function logNotification(
  userId: string, bookingId: string,
  type: string, title: string, body: string,
) {
  try {
    await supabase.from('notifications').insert({
      user_id: userId,
      title,
      body,
      data: { type, booking_id: bookingId },
    });
  } catch (e) {
    console.error('logNotification error:', e);
  }
}

async function sendFcm(
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
    console.error('sendFcm error:', e);
    return false;
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

function formatDate(dateStr: string): string {
  const months = ['ene','feb','mar','abr','may','jun','jul','ago','sep','oct','nov','dic'];
  const [, month, day] = dateStr.split('-').map(Number);
  return `${day} de ${months[month - 1]}`;
}
