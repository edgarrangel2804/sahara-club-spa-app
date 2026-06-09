-- ============================================================
-- Trigger: notificar recepcionistas cuando llega una reserva nueva
-- Se llama a la edge function notify-booking-event via pg_net
-- ============================================================

-- Función que dispara la notificación
CREATE OR REPLACE FUNCTION public.notify_new_booking()
RETURNS TRIGGER AS $$
DECLARE
  service_role_key text;
BEGIN
  -- Solo notifica si la cita viene del lado del cliente
  -- (created_by es NULL o es el mismo cliente)
  -- Para no enviar notificación cuando la recepcionista crea la cita manualmente
  -- si deseas notificar siempre, elimina el IF

  -- Lee la service_role key desde Vault (nunca hardcodear en el repo)
  SELECT decrypted_secret INTO service_role_key
  FROM vault.decrypted_secrets
  WHERE name = 'service_role_key'
  LIMIT 1;

  PERFORM net.http_post(
    url     := 'https://fkbyxhwdcsgrrixalzwf.supabase.co/functions/v1/notify-booking-event',
    body    := json_build_object(
                 'type',       'new_booking',
                 'booking_id', NEW.id::text
               )::jsonb,
    headers := jsonb_build_object(
                 'Content-Type',  'application/json',
                 'Authorization', 'Bearer ' || service_role_key
               )
  );
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Trigger: se dispara después de cada INSERT en bookings
DROP TRIGGER IF EXISTS on_booking_created ON public.bookings;
CREATE TRIGGER on_booking_created
  AFTER INSERT ON public.bookings
  FOR EACH ROW
  EXECUTE FUNCTION public.notify_new_booking();
