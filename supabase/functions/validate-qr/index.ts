// Edge Function — validate-qr
// Validates an order_item by ID and marks it as redeemed.

import { serve } from 'https://deno.land/std@0.177.0/http/server.ts';
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2';

const SUPABASE_URL = Deno.env.get('SUPABASE_URL')!;
const SERVICE_KEY  = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!;

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
};

serve(async (req) => {
  if (req.method === 'OPTIONS') return new Response('ok', { headers: corsHeaders });

  try {
    const { order_item_id, staff_id, action } = await req.json() as {
      order_item_id: string;
      staff_id?: string;
      action: 'validate' | 'redeem';
    };

    if (!order_item_id) {
      return new Response(
        JSON.stringify({ error: 'order_item_id requerido' }),
        { status: 400, headers: { ...corsHeaders, 'Content-Type': 'application/json' } },
      );
    }

    const supabase = createClient(SUPABASE_URL, SERVICE_KEY);

    // Fetch the item with its order
    const { data: item, error } = await supabase
      .from('order_items')
      .select(`
        id, product_name, product_type, unit_price, quantity, currency,
        redeemed_at, redeemed_by, created_at,
        order:orders(id, customer_name, customer_email, status, created_at)
      `)
      .eq('id', order_item_id)
      .single();

    if (error || !item) {
      return new Response(
        JSON.stringify({ valid: false, error: 'Código no encontrado.' }),
        { status: 404, headers: { ...corsHeaders, 'Content-Type': 'application/json' } },
      );
    }

    const order = (item.order as Record<string, unknown>[] | Record<string, unknown>);
    const orderData = Array.isArray(order) ? order[0] : order;

    // Check order is paid
    if (orderData?.status !== 'paid') {
      return new Response(
        JSON.stringify({ valid: false, error: 'El pago no ha sido confirmado.', item }),
        { status: 200, headers: { ...corsHeaders, 'Content-Type': 'application/json' } },
      );
    }

    // Already redeemed?
    if (item.redeemed_at) {
      return new Response(
        JSON.stringify({
          valid: false,
          already_redeemed: true,
          redeemed_at: item.redeemed_at,
          item,
          order: orderData,
        }),
        { headers: { ...corsHeaders, 'Content-Type': 'application/json' } },
      );
    }

    // If action is validate only, return without redeeming
    if (action === 'validate') {
      return new Response(
        JSON.stringify({ valid: true, item, order: orderData }),
        { headers: { ...corsHeaders, 'Content-Type': 'application/json' } },
      );
    }

    // Redeem it
    const { error: redeemErr } = await supabase
      .from('order_items')
      .update({ redeemed_at: new Date().toISOString(), redeemed_by: staff_id ?? null })
      .eq('id', order_item_id);

    if (redeemErr) {
      return new Response(
        JSON.stringify({ error: 'No se pudo canjear el código.' }),
        { status: 500, headers: { ...corsHeaders, 'Content-Type': 'application/json' } },
      );
    }

    return new Response(
      JSON.stringify({ valid: true, redeemed: true, item, order: orderData }),
      { headers: { ...corsHeaders, 'Content-Type': 'application/json' } },
    );

  } catch (err) {
    return new Response(
      JSON.stringify({ error: 'Error interno.' }),
      { status: 500, headers: { ...corsHeaders, 'Content-Type': 'application/json' } },
    );
  }
});
