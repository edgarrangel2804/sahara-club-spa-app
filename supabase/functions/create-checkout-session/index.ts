// Edge Function — create-checkout-session
// Creates a Stripe Checkout Session from a cart and returns the hosted URL.
// Required env vars: STRIPE_SECRET_KEY, SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY

import { serve } from 'https://deno.land/std@0.177.0/http/server.ts';
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2';

const STRIPE_KEY = Deno.env.get('STRIPE_SECRET_KEY')!;
const SUPABASE_URL = Deno.env.get('SUPABASE_URL')!;
const SERVICE_KEY = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!;

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
};

interface CartItem {
  product_id: string;
  name: string;
  description?: string;
  unit_price: number;
  currency?: string;
  quantity: number;
  image_url?: string;
  product_type: string;
  category_key?: string;
}

interface RequestBody {
  customer_name: string;
  customer_email: string;
  customer_phone?: string;
  notes?: string;
  success_url?: string;
  cancel_url?: string;
  items: CartItem[];
}

serve(async (req) => {
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders });
  }

  try {
    if (!STRIPE_KEY) {
      return new Response(
        JSON.stringify({ error: 'Stripe no configurado. Contacta soporte.' }),
        { status: 500, headers: { ...corsHeaders, 'Content-Type': 'application/json' } },
      );
    }

    const body: RequestBody = await req.json();
    const { customer_name, customer_email, customer_phone, notes, items } = body;

    if (!items?.length) {
      return new Response(
        JSON.stringify({ error: 'El carrito está vacío.' }),
        { status: 400, headers: { ...corsHeaders, 'Content-Type': 'application/json' } },
      );
    }

    if (!customer_email) {
      return new Response(
        JSON.stringify({ error: 'Se requiere un correo electrónico.' }),
        { status: 400, headers: { ...corsHeaders, 'Content-Type': 'application/json' } },
      );
    }

    const successUrl = body.success_url ||
      `${SUPABASE_URL.replace('supabase.co', 'saharaclubspa.mx')}/checkout/success?session_id={CHECKOUT_SESSION_ID}`;
    const cancelUrl = body.cancel_url ||
      `${SUPABASE_URL.replace('supabase.co', 'saharaclubspa.mx')}/checkout/cancel`;

    // ── Build Stripe form-encoded body ────────────────────────────────────────
    const params = new URLSearchParams();
    params.append('mode', 'payment');
    params.append('success_url', successUrl);
    params.append('cancel_url', cancelUrl);
    params.append('customer_email', customer_email);
    params.append('locale', 'es');
    params.append('payment_method_types[]', 'card');

    if (customer_name) params.append('metadata[customer_name]', customer_name);
    if (customer_phone) params.append('metadata[customer_phone]', customer_phone);
    if (notes) params.append('metadata[notes]', notes);

    items.forEach((item, i) => {
      const currency = (item.currency ?? 'mxn').toLowerCase();
      const unitAmount = Math.round(item.unit_price * 100);

      params.append(`line_items[${i}][price_data][currency]`, currency);
      params.append(`line_items[${i}][price_data][product_data][name]`, item.name);

      if (item.description) {
        params.append(
          `line_items[${i}][price_data][product_data][description]`,
          item.description.substring(0, 500),
        );
      }
      if (item.image_url) {
        params.append(`line_items[${i}][price_data][product_data][images][0]`, item.image_url);
      }
      params.append(
        `line_items[${i}][price_data][product_data][metadata][product_id]`,
        item.product_id ?? '',
      );
      params.append(
        `line_items[${i}][price_data][product_data][metadata][product_type]`,
        item.product_type,
      );
      params.append(`line_items[${i}][price_data][unit_amount]`, unitAmount.toString());
      params.append(`line_items[${i}][quantity]`, item.quantity.toString());
    });

    // ── Call Stripe ────────────────────────────────────────────────────────────
    const stripeRes = await fetch('https://api.stripe.com/v1/checkout/sessions', {
      method: 'POST',
      headers: {
        'Authorization': `Bearer ${STRIPE_KEY}`,
        'Content-Type': 'application/x-www-form-urlencoded',
      },
      body: params.toString(),
    });

    const session = await stripeRes.json();

    if (!stripeRes.ok) {
      console.error('Stripe error:', session);
      return new Response(
        JSON.stringify({ error: session.error?.message ?? 'Error al crear sesión de pago.' }),
        { status: 400, headers: { ...corsHeaders, 'Content-Type': 'application/json' } },
      );
    }

    // ── Persist order in DB ────────────────────────────────────────────────────
    const supabase = createClient(SUPABASE_URL, SERVICE_KEY);
    const { data: order } = await supabase
      .from('orders')
      .insert({
        stripe_session_id: session.id,
        customer_email,
        customer_name: customer_name ?? '',
        customer_phone: customer_phone ?? '',
        notes: notes ?? '',
        status: 'pending',
        total_amount: items.reduce((s, it) => s + it.unit_price * it.quantity, 0),
        currency: (items[0]?.currency ?? 'mxn').toLowerCase(),
        items: items,
      })
      .select('id')
      .single();

    return new Response(
      JSON.stringify({
        checkout_url: session.url,
        session_id: session.id,
        order_id: order?.id ?? session.id,
      }),
      { headers: { ...corsHeaders, 'Content-Type': 'application/json' } },
    );

  } catch (err) {
    console.error('Unexpected error:', err);
    return new Response(
      JSON.stringify({ error: 'Error interno del servidor.' }),
      { status: 500, headers: { ...corsHeaders, 'Content-Type': 'application/json' } },
    );
  }
});
