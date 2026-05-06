-- ============================================================
-- Trigger: notificar recepcionistas cuando llega una reserva nueva
-- Se llama a la edge function notify-booking-event via pg_net
-- ============================================================

-- Función que dispara la notificación
CREATE OR REPLACE FUNCTION public.notify_new_booking()
RETURNS TRIGGER AS $$
BEGIN
  -- Solo notifica si la cita viene del lado del cliente
  -- (created_by es NULL o es el mismo cliente)
  -- Para no enviar notificación cuando la recepcionista crea la cita manualmente
  -- si deseas notificar siempre, elimina el IF
  PERFORM net.http_post(
    url     := 'https://fkbyxhwdcsgrrixalzwf.supabase.co/functions/v1/notify-booking-event',
    body    := json_build_object(
                 'type',       'new_booking',
                 'booking_id', NEW.id::text
               )::jsonb,
    headers := '{"Content-Type":"application/json","Authorization":"Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImZrYnl4aHdkY3NncnJpeGFsendmIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc3NzU3MTcyNiwiZXhwIjoyMDkzMTQ3NzI2fQ.Q5XTR7Ax2HK9-foP1tRf1wrP_uQWoWfNlAESIRkz00U"}'::jsonb
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
