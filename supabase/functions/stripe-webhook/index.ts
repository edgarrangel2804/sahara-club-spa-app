// Edge Function — stripe-webhook
// Listens for Stripe checkout.session.completed, marks order as paid,
// and creates individual order_items rows.

import { serve } from 'https://deno.land/std@0.177.0/http/server.ts';
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2';

const STRIPE_KEY            = Deno.env.get('STRIPE_SECRET_KEY')!;
const STRIPE_WEBHOOK_SECRET = Deno.env.get('STRIPE_WEBHOOK_SECRET')!;
const SUPABASE_URL          = Deno.env.get('SUPABASE_URL')!;
const SERVICE_KEY           = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!;

const supabase = createClient(SUPABASE_URL, SERVICE_KEY);

async function verifyStripeSignature(body: string, sig: string, secret: string): Promise<boolean> {
  const encoder = new TextEncoder();
  const parts = sig.split(',');
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

  // Verify signature if secret is configured
  if (STRIPE_WEBHOOK_SECRET) {
    const valid = await verifyStripeSignature(body, sig, STRIPE_WEBHOOK_SECRET);
    if (!valid) {
      return new Response('Invalid signature', { status: 400 });
    }
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

  const session = event.data as Record<string, unknown>;
  const sessionObj = session.object as Record<string, unknown>;
  const sessionId = sessionObj.id as string;

  // Find the order
  const { data: order, error: orderErr } = await supabase
    .from('orders')
    .select('id, items')
    .eq('stripe_session_id', sessionId)
    .single();

  if (orderErr || !order) {
    console.error('Order not found for session', sessionId);
    return new Response(JSON.stringify({ received: true, warning: 'order not found' }), {
      headers: { 'Content-Type': 'application/json' },
    });
  }

  // Update order status to paid
  await supabase
    .from('orders')
    .update({ status: 'paid' })
    .eq('id', order.id);

  // Create order_items from the stored items JSONB
  const items = (order.items as Record<string, unknown>[]) ?? [];
  if (items.length > 0) {
    const itemRows = items.flatMap((item: Record<string, unknown>) => {
      const qty = (item.quantity as number) ?? 1;
      return Array.from({ length: qty }, () => ({
        order_id:     order.id,
        product_id:   item.product_id as string ?? '',
        product_name: item.name as string ?? '',
        product_type: item.product_type as string ?? 'service',
        unit_price:   item.unit_price as number ?? 0,
        quantity:     1,
        currency:     (item.currency as string ?? 'mxn').toLowerCase(),
        category_key: item.category_key as string ?? '',
        image_url:    item.image_url as string ?? '',
      }));
    });

    await supabase.from('order_items').insert(itemRows);
  }

  return new Response(JSON.stringify({ received: true, order_id: order.id }), {
    headers: { 'Content-Type': 'application/json' },
  });
});
