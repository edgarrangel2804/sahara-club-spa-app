-- ============================================================
-- 08_notification_tables.sql
-- Tables required by notification Edge Functions + pg_cron jobs
-- ============================================================

-- ── device_tokens (multi-device FCM registry) ─────────────────────────────────

CREATE TABLE IF NOT EXISTS public.device_tokens (
  id          uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id     uuid REFERENCES public.profiles(id) ON DELETE CASCADE NOT NULL,
  token       text NOT NULL,
  platform    text NOT NULL DEFAULT 'android',
  created_at  timestamptz DEFAULT now(),
  updated_at  timestamptz DEFAULT now(),
  UNIQUE(user_id, token)
);

ALTER TABLE public.device_tokens ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users manage their own device tokens"
  ON public.device_tokens FOR ALL
  USING  (auth.uid() = user_id)
  WITH CHECK (auth.uid() = user_id);

-- ── notifications (log por notify-booking-event) ──────────────────────────────

CREATE TABLE IF NOT EXISTS public.notifications (
  id          uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id     uuid REFERENCES public.profiles(id) ON DELETE CASCADE,
  title       text,
  body        text,
  data        jsonb DEFAULT '{}',
  read        boolean DEFAULT false,
  created_at  timestamptz DEFAULT now()
);

ALTER TABLE public.notifications ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can read their own notifications"
  ON public.notifications FOR SELECT
  USING (auth.uid() = user_id);

CREATE POLICY "Users can mark notifications read"
  ON public.notifications FOR UPDATE
  USING (auth.uid() = user_id);

-- ── notification_log (log por send-booking-reminders) ────────────────────────

CREATE TABLE IF NOT EXISTS public.notification_log (
  id          uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id     uuid REFERENCES public.profiles(id) ON DELETE CASCADE,
  booking_id  uuid REFERENCES public.bookings(id) ON DELETE SET NULL,
  type        text,
  title       text,
  body        text,
  status      text DEFAULT 'sent',
  created_at  timestamptz DEFAULT now()
);

ALTER TABLE public.notification_log ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Admins can read notification log"
  ON public.notification_log FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM public.profiles
      WHERE id = auth.uid() AND role = 'admin'
    )
  );

-- ── pg_cron: booking reminders ────────────────────────────────────────────────
-- Builds job SQL via string concatenation so no $$ appears inside DO $$...$$

DO $$
DECLARE
  _svc_key  text := 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImZrYnl4aHdkY3NncnJpeGFsendmIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc3NzU3MTcyNiwiZXhwIjoyMDkzMTQ3NzI2fQ.Q5XTR7Ax2HK9-foP1tRf1wrP_uQWoWfNlAESIRkz00U';
  _base_url text := 'https://fkbyxhwdcsgrrixalzwf.supabase.co/functions/v1/send-booking-reminders';
  _hdr      text;
  _sql_day  text;
  _sql_2h   text;
BEGIN
  -- Remove existing schedules so re-running is idempotent
  DELETE FROM cron.job WHERE jobname IN ('sahara-reminder-vispera', 'sahara-reminder-2h');

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

  -- Víspera: 01:00 UTC diario (≈ 8 PM CDT / Ensenada México)
  PERFORM cron.schedule('sahara-reminder-vispera', '0 1 * * *', _sql_day);
  -- 2 horas antes: cada hora en punto
  PERFORM cron.schedule('sahara-reminder-2h', '0 * * * *', _sql_2h);

EXCEPTION WHEN OTHERS THEN
  RAISE NOTICE 'pg_cron setup skipped: %', SQLERRM;
END;
$$;
