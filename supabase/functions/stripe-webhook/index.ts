// Edge Function — stripe-webhook
// Listens for Stripe checkout.session.completed and marks the order as paid.
// order_items are already created at checkout time; this just updates the status.

import { serve } from 'https://deno.land/std@0.177.0/http/server.ts';
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2';
import {
  loadActiveStripeSettings,
  DEFAULT_BRANCH_ID,
} from '../_shared/stripe_settings.ts';

const SUPABASE_URL = Deno.env.get('SUPABASE_URL')!;
const SERVICE_KEY  = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!;
const supabase     = createClient(SUPABASE_URL, SERVICE_KEY);

async function verifyStripeSignature(body: string, sig: string, secret: string): Promise<boolean> {
  const encoder = new TextEncoder();
  const parts     = sig.split(',');
  const timestamp = parts.find(p => p.startsWith('t='))?.split('=')[1];
  const v1        = parts.find(p => p.startsWith('v1='))?.split('=')[1];
  if (!timestamp || !v1) return false;

  const payload = `${timestamp}.${body}`;
  const key = await crypto.subtle.importKey(
    'raw', encoder.encode(secret), { name: 'HMAC', hash: 'SHA-256' }, false, ['sign'],
  );
  const signatureBuffer = await crypto.subtle.sign('HMAC', key, encoder.encode(payload));
  const computed = Array.from(new Uint8Array(signatureBuffer))
    .map(b => b.toString(16).padStart(2, '0')).join('');
  return computed === v1;
}

serve(async (req) => {
  const body = await req.text();
  const sig  = req.headers.get('stripe-signature') ?? '';

  // Load webhook secret from DB
  const stripeSettings = await loadActiveStripeSettings(supabase, DEFAULT_BRANCH_ID);
  const webhookSecret  = stripeSettings?.webhookSecret ?? '';

  if (webhookSecret) {
    const valid = await verifyStripeSignature(body, sig, webhookSecret);
    if (!valid) return new Response('Invalid signature', { status: 400 });
  }

  let event: Record<string, unknown>;
  try {
    event = JSON.parse(body);
  } catch {
    return new Response('Invalid JSON', { status: 400 });
  }

  if (event.type !== 'checkout.session.completed') {
    return new Response(JSON.stringify({ received: true }), {
      headers: { 'Content-Type': 'application/json' },
    });
  }

  const sessionObj = (event.data as Record<string, unknown>).object as Record<string, unknown>;
  const sessionId  = sessionObj.id as string;

  const { data: order } = await supabase
    .from('orders')
    .select('id')
    .eq('stripe_session_id', sessionId)
    .single();

  if (!order) {
    console.error('Order not found for session', sessionId);
    return new Response(JSON.stringify({ received: true, warning: 'order not found' }), {
      headers: { 'Content-Type': 'application/json' },
    });
  }

  await supabase
    .from('orders')
    .update({ status: 'paid', paid_at: new Date().toISOString() })
    .eq('id', order.id);

  return new Response(JSON.stringify({ received: true, order_id: order.id }), {
    headers: { 'Content-Type': 'application/json' },
  });
});
