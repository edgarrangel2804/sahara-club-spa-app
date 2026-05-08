CREATE OR REPLACE FUNCTION public.notify_push(
    target_user_id  uuid,
    title           text,
    body            text,
    data_payload    jsonb DEFAULT '{}'::jsonb
)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    edge_url text := 'https://fkbyxhwdcsgrrixalzwf.supabase.co/functions/v1/send-push-notification';
    anon_key text := 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImZrYnl4aHdkY3NncnJpeGFsendmIiwicm9sZSI6ImFub24iLCJpYXQiOjE3Nzc1NzE3MjYsImV4cCI6MjA5MzE0NzcyNn0.IJ2nDtgBPkbY8CRDmGGJTvE6kELrY0sp3_F9yseZP9Q';
BEGIN
    PERFORM net.http_post(
        url     := edge_url,
        headers := jsonb_build_object(
            'Content-Type',  'application/json',
            'Authorization', 'Bearer ' || anon_key
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
