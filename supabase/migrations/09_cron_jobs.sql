-- ============================================================
-- 09_cron_jobs.sql
-- Programa recordatorios automáticos de citas vía pg_cron
-- ============================================================

DO $$
DECLARE
  _svc_key  text := 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImZrYnl4aHdkY3NncnJpeGFsendmIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc3NzU3MTcyNiwiZXhwIjoyMDkzMTQ3NzI2fQ.Q5XTR7Ax2HK9-foP1tRf1wrP_uQWoWfNlAESIRkz00U';
  _base_url text := 'https://fkbyxhwdcsgrrixalzwf.supabase.co/functions/v1/send-booking-reminders';
  _hdr      text;
  _sql_day  text;
  _sql_2h   text;
BEGIN
  _hdr := '{"Content-Type":"application/json","Authorization":"Bearer ' || _svc_key || '"}';

  _sql_day :=
    'SELECT net.http_post(' ||
    'url:=''' || _base_url || ''',' ||
    'body:=''{"type":"day_before"}''::jsonb,' ||
    'headers:=''' || _hdr || '''::jsonb);';

  _sql_2h :=
    'SELECT net.http_post(' ||
    'url:=''' || _base_url || ''',' ||
    'body:=''{"type":"two_hours"}''::jsonb,' ||
    'headers:=''' || _hdr || '''::jsonb);';

  -- Eliminar jobs previos usando la función (no acceso directo a cron.job)
  BEGIN
    PERFORM cron.unschedule('sahara-reminder-vispera');
  EXCEPTION WHEN OTHERS THEN
    NULL;
  END;

  BEGIN
    PERFORM cron.unschedule('sahara-reminder-2h');
  EXCEPTION WHEN OTHERS THEN
    NULL;
  END;

  -- Víspera: 01:00 UTC diario (≈ 8 PM CDT / Ensenada México)
  PERFORM cron.schedule('sahara-reminder-vispera', '0 1 * * *', _sql_day);
  -- 2 horas antes: cada hora en punto
  PERFORM cron.schedule('sahara-reminder-2h', '0 * * * *', _sql_2h);

  RAISE NOTICE 'pg_cron jobs registrados correctamente';

EXCEPTION WHEN OTHERS THEN
  RAISE NOTICE 'pg_cron no disponible, registrar manualmente: %', SQLERRM;
END;
$$;
