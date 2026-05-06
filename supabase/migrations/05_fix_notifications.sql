-- ============================================================
-- 1. Guardar service_role_key en Vault (upsert seguro)
-- ============================================================
DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM vault.secrets WHERE name = 'service_role_key') THEN
    PERFORM vault.create_secret(
      'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImZrYnl4aHdkY3NncnJpeGFsendmIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc3NzU3MTcyNiwiZXhwIjoyMDkzMTQ3NzI2fQ.Q5XTR7Ax2HK9-foP1tRf1wrP_uQWoWfNlAESIRkz00U',
      'service_role_key'
    );
  ELSE
    UPDATE vault.secrets
    SET secret = extensions.pgp_sym_encrypt(
      'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImZrYnl4aHdkY3NncnJpeGFsendmIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc3NzU3MTcyNiwiZXhwIjoyMDkzMTQ3NzI2fQ.Q5XTR7Ax2HK9-foP1tRf1wrP_uQWoWfNlAESIRkz00U',
      (SELECT decrypted_secret FROM vault.decrypted_secrets WHERE name = 'service_role_key' LIMIT 1)
    )
    WHERE name = 'service_role_key';
  END IF;
END $$;

-- ============================================================
-- 2. Corregir la URL en notify_push: reemplaza el placeholder
--    TU_PROJECT_ID con el project ref real
-- ============================================================
CREATE OR REPLACE FUNCTION public.notify_push(
  target_user_id uuid,
  title          text,
  body           text,
  data_payload   jsonb DEFAULT '{}'::jsonb
)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  edge_url         text := 'https://fkbyxhwdcsgrrixalzwf.supabase.co/functions/v1/send-push-notification';
  service_role_key text;
BEGIN
  SELECT decrypted_secret INTO service_role_key
  FROM vault.decrypted_secrets
  WHERE name = 'service_role_key'
  LIMIT 1;

  IF service_role_key IS NULL THEN
    RAISE WARNING 'notify_push: service_role_key no encontrada en Vault';
    RETURN;
  END IF;

  IF target_user_id IS NULL THEN
    RETURN;
  END IF;

  PERFORM net.http_post(
    url     := edge_url,
    headers := jsonb_build_object(
      'Content-Type',  'application/json',
      'Authorization', 'Bearer ' || service_role_key
    ),
    body    := jsonb_build_object(
      'user_id', target_user_id,
      'title',   title,
      'body',    body,
      'data',    data_payload
    ),
    timeout_milliseconds := 5000
  );
END;
$$;

-- ============================================================
-- 3. Eliminar el trigger duplicado on_booking_created y su
--    función notify_new_booking (handle_booking_push ya cubre
--    ese caso con más detalle)
-- ============================================================
DROP TRIGGER IF EXISTS on_booking_created ON public.bookings;
DROP FUNCTION IF EXISTS public.notify_new_booking();
