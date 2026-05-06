// Edge Function — create-reception-client
// Crea un usuario auth + perfil de cliente desde la recepción.
// Requiere service_role para usar la Admin API.

import { serve } from 'https://deno.land/std@0.177.0/http/server.ts';
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2';

const SUPABASE_URL = Deno.env.get('SUPABASE_URL')!;
const SERVICE_KEY  = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!;

const adminClient = createClient(SUPABASE_URL, SERVICE_KEY, {
  auth: { autoRefreshToken: false, persistSession: false },
});

serve(async (req) => {
  if (req.method === 'OPTIONS') {
    return new Response(null, {
      headers: {
        'Access-Control-Allow-Origin': '*',
        'Access-Control-Allow-Headers': 'authorization, content-type',
      },
    });
  }

  try {
    const { full_name, phone, email } = await req.json() as {
      full_name: string;
      phone?: string;
      email?: string;
    };

    if (!full_name?.trim()) {
      return new Response(
        JSON.stringify({ error: 'El nombre es requerido' }),
        { status: 400, headers: { 'Content-Type': 'application/json' } },
      );
    }

    // Generar email único si no se proporcionó uno real
    const authEmail = email?.trim() ||
      `recepcion_${crypto.randomUUID()}@sahara.local`;

    // Crear usuario en auth.users con contraseña aleatoria
    const { data: authData, error: authErr } = await adminClient.auth.admin.createUser({
      email:          authEmail,
      password:       crypto.randomUUID(),
      email_confirm:  true,
    });

    if (authErr || !authData.user) {
      console.error('Error creando auth user:', authErr);
      return new Response(
        JSON.stringify({ error: authErr?.message ?? 'Error creando usuario' }),
        { status: 500, headers: { 'Content-Type': 'application/json' } },
      );
    }

    const userId = authData.user.id;

    // Crear perfil de cliente
    const { data: profile, error: profileErr } = await adminClient
      .from('profiles')
      .upsert({
        id:        userId,
        full_name: full_name.trim(),
        phone:     phone?.trim() ?? null,
        role:      'client',
        is_active: true,
      })
      .select()
      .single();

    if (profileErr) {
      console.error('Error creando perfil:', profileErr);
      // Limpiar el usuario de auth si el perfil falló
      await adminClient.auth.admin.deleteUser(userId);
      return new Response(
        JSON.stringify({ error: profileErr.message }),
        { status: 500, headers: { 'Content-Type': 'application/json' } },
      );
    }

    return new Response(
      JSON.stringify({ client: profile }),
      { status: 200, headers: { 'Content-Type': 'application/json' } },
    );

  } catch (e) {
    console.error('create-reception-client error:', e);
    return new Response(
      JSON.stringify({ error: String(e) }),
      { status: 500, headers: { 'Content-Type': 'application/json' } },
    );
  }
});
