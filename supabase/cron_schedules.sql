-- Ejecutar en Supabase SQL Editor después de habilitar pg_cron desde
-- Dashboard → Database → Extensions → pg_cron
--
-- Reemplaza:
--   <project-ref>  → tu project ref de Supabase (ej: fkbyxhwdcsgrrixalzwf)
--   <service-key>  → tu service_role key (Dashboard → Settings → API)

-- Recordatorio noche anterior (8 PM UTC — ajusta si tu zona es diferente)
SELECT cron.schedule(
  'sahara-reminder-8pm',
  '0 20 * * *',
  $$
  SELECT net.http_post(
    url     := 'https://fkbyxhwdcsgrrixalzwf.supabase.co/functions/v1/send-booking-reminders',
    body    := '{"type":"day_before"}'::jsonb,
    headers := '{"Content-Type":"application/json","Authorization":"Bearer <service-key>"}'::jsonb
  )
  $$
);

-- Recordatorio 2 horas antes (corre cada hora en punto)
SELECT cron.schedule(
  'sahara-reminder-2h',
  '0 * * * *',
  $$
  SELECT net.http_post(
    url     := 'https://fkbyxhwdcsgrrixalzwf.supabase.co/functions/v1/send-booking-reminders',
    body    := '{"type":"two_hours"}'::jsonb,
    headers := '{"Content-Type":"application/json","Authorization":"Bearer <service-key>"}'::jsonb
  )
  $$
);
