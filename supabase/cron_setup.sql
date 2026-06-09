-- ============================================================
-- cron_setup.sql
-- Programa los recordatorios de citas vía pg_cron.
-- La service_role key NUNCA se hardcodea: se lee desde Vault
-- (secreto 'service_role_key', sembrado en supabase/vault_setup.sql).
-- Versión canónica e idempotente: migración 09_cron_jobs.sql
-- ============================================================

DO $$
DECLARE
  _svc_key  text;
  _base_url text := 'https://fkbyxhwdcsgrrixalzwf.supabase.co/functions/v1/send-booking-reminders';
  _hdr      text;
  _sql_day  text;
  _sql_2h   text;
BEGIN
  -- Lee la service_role key desde Vault (nunca hardcodear en el repo)
  SELECT decrypted_secret INTO _svc_key
  FROM vault.decrypted_secrets
  WHERE name = 'service_role_key'
  LIMIT 1;

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
END;
$$;
