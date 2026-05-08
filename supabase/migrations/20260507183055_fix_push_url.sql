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
    edge_url        text := 'https://fkbyxhwdcsgrrixalzwf.supabase.co/functions/v1/send-push-notification';
    service_role_key text;
BEGIN
    SELECT decrypted_secret INTO service_role_key
    FROM vault.decrypted_secrets
    WHERE name = 'service_role_key'
    LIMIT 1;

    IF service_role_key IS NULL THEN
        RAISE WARNING 'service_role_key no encontrada en Vault. Push abortado.';
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
