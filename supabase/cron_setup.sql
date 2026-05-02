-- Cron job 1: recordatorio noche anterior (8 PM hora México CDT = 01:00 UTC)
SELECT cron.schedule(
  'sahara-reminder-vispera',
  '0 1 * * *',
  $$
  SELECT net.http_post(
    url     := 'https://fkbyxhwdcsgrrixalzwf.supabase.co/functions/v1/send-booking-reminders',
    body    := '{"type":"day_before"}'::jsonb,
    headers := '{"Content-Type":"application/json","Authorization":"Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImZrYnl4aHdkY3NncnJpeGFsendmIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc3NzU3MTcyNiwiZXhwIjoyMDkzMTQ3NzI2fQ.Q5XTR7Ax2HK9-foP1tRf1wrP_uQWoWfNlAESIRkz00U"}'::jsonb
  )
  $$
);

-- Cron job 2: recordatorio 2 horas antes (corre cada hora en punto)
SELECT cron.schedule(
  'sahara-reminder-2h',
  '0 * * * *',
  $$
  SELECT net.http_post(
    url     := 'https://fkbyxhwdcsgrrixalzwf.supabase.co/functions/v1/send-booking-reminders',
    body    := '{"type":"two_hours"}'::jsonb,
    headers := '{"Content-Type":"application/json","Authorization":"Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImZrYnl4aHdkY3NncnJpeGFsendmIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc3NzU3MTcyNiwiZXhwIjoyMDkzMTQ3NzI2fQ.Q5XTR7Ax2HK9-foP1tRf1wrP_uQWoWfNlAESIRkz00U"}'::jsonb
  )
  $$
);
