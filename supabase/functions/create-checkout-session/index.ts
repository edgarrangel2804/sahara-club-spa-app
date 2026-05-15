// Edge Function — create-checkout-session
// Creates a Stripe Checkout Session from a cart and returns the hosted URL.
// Reads Stripe credentials from stripe_settings table (configured in admin panel).

import { serve } from 'https://deno.land/std@0.177.0/http/server.ts';
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2';
import {
  loadActiveStripeSettings,
  DEFAULT_BRANCH_ID,
  corsHeaders,
} from '../_shared/stripe_settings.ts';

const SUPABASE_URL = Deno.env.get('SUPABASE_URL')!;
const SERVICE_KEY  = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!;

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
  user_id?: string;
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
    const supabase = createClient(SUPABASE_URL, SERVICE_KEY);

    // Load active Stripe settings from DB (configured via admin panel)
    const stripeSettings = await loadActiveStripeSettings(supabase, DEFAULT_BRANCH_ID);
    if (!stripeSettings?.secretKey) {
      return new Response(
        JSON.stringify({ error: 'Stripe no configurado. Ve a Administración → Configuración.' }),
        { status: 500, headers: { ...corsHeaders, 'Content-Type': 'application/json' } },
      );
    }

    const STRIPE_KEY = stripeSettings.secretKey;
    const body: RequestBody = await req.json();
    const { user_id, customer_name, customer_email, customer_phone, notes, items } = body;

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

    const fnBase = `${SUPABASE_URL}/functions/v1/checkout-result`;
    const successUrl = body.success_url ?? `${fnBase}?session_id={CHECKOUT_SESSION_ID}`;
    const cancelUrl  = body.cancel_url  ?? `${fnBase}/cancel`;

    // ── Build Stripe line items ───────────────────────────────────────────────
    const params = new URLSearchParams();
    params.append('mode', 'payment');
    params.append('success_url', successUrl);
    params.append('cancel_url', cancelUrl);
    params.append('customer_email', customer_email);
    params.append('locale', 'es');
    params.append('payment_method_types[]', 'card');

    if (customer_name) params.append('metadata[customer_name]', customer_name);
    if (customer_phone) params.append('metadata[customer_phone]', customer_phone);
    if (notes)          params.append('metadata[notes]', notes);

    items.forEach((item, i) => {
      const currency   = (item.currency ?? 'mxn').toLowerCase();
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
      params.append(`line_items[${i}][price_data][unit_amount]`, unitAmount.toString());
      params.append(`line_items[${i}][quantity]`, item.quantity.toString());
    });

    // ── Call Stripe ───────────────────────────────────────────────────────────
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

    // ── Persist order + order_items in DB ─────────────────────────────────────
    const total = items.reduce((s, it) => s + it.unit_price * it.quantity, 0);
    const currency = (items[0]?.currency ?? 'mxn').toLowerCase();

    const { data: order, error: orderErr } = await supabase
      .from('orders')
      .insert({
        customer_id:    user_id ?? null,
        customer_email,
        customer_name:  customer_name ?? '',
        customer_phone: customer_phone ?? '',
        notes:          notes ?? '',
        status:         'pending',
        subtotal:       total,
        total:          total,
        currency,
        stripe_session_id: session.id,
        checkout_url:      session.url,
      })
      .select('id')
      .single();

    if (orderErr || !order) {
      console.error('Order insert error:', orderErr);
      // Still return checkout URL even if DB insert failed
      return new Response(
        JSON.stringify({ checkout_url: session.url, session_id: session.id, order_id: null }),
        { headers: { ...corsHeaders, 'Content-Type': 'application/json' } },
      );
    }

    // Insert one order_item row per quantity unit so each gets its own QR
    const itemRows = items.flatMap((item) =>
      Array.from({ length: item.quantity }, () => ({
        order_id:            order.id,
        product_id:          item.product_id ?? '',
        product_name:        item.name,
        product_description: item.description ?? '',
        image_url:           item.image_url ?? '',
        quantity:            1,
        unit_price:          item.unit_price,
        total_price:         item.unit_price,
        currency,
        product_type:        item.product_type ?? 'service',
        category_key:        item.category_key ?? '',
      }))
    );

    await supabase.from('order_items').insert(itemRows);

    return new Response(
      JSON.stringify({ checkout_url: session.url, session_id: session.id, order_id: order.id }),
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
