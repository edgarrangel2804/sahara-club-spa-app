-- ============================================================
-- SAHARA CLUB SPA - Push Notifications
-- Triggers para notificaciones automáticas vía FCM
-- IMPORTANTE: Actualiza edge_url con la URL de tu proyecto Supabase
-- ============================================================

-- ============================================================
-- FUNCIÓN RPC: Enviar push notification (usa Vault para el token)
-- ============================================================

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
    edge_url        text := 'https://TU_PROJECT_ID.supabase.co/functions/v1/send-push-notification';
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

-- ============================================================
-- TRIGGER: Nueva reservación / cambio de estado
-- ============================================================

CREATE OR REPLACE FUNCTION public.handle_booking_push()
RETURNS TRIGGER AS $$
DECLARE
    creator_id      uuid;
    creator_role    text;
    client_name     text;
    therapist_name  text;
    date_str        text;
    time_str        text;
    service_name    text;
    rec             RECORD;
BEGIN
    creator_id := auth.uid();

    IF creator_id IS NULL THEN
        creator_role := 'admin';
    ELSE
        SELECT role INTO creator_role FROM public.profiles WHERE id = creator_id;
    END IF;

    SELECT full_name INTO client_name    FROM public.profiles WHERE id = NEW.client_id;
    SELECT full_name INTO therapist_name FROM public.profiles WHERE id = NEW.therapist_id;
    SELECT name     INTO service_name    FROM public.services  WHERE id = NEW.service_id;

    date_str := to_char(NEW.booking_date, 'DD/MM/YYYY');
    time_str := substring(NEW.booking_time::text from 1 for 5);

    -- NUEVA RESERVACIÓN
    IF (TG_OP = 'INSERT') THEN

        -- Cliente crea su reservación → notificar terapeuta + recepcionistas
        IF creator_role = 'client' THEN
            PERFORM public.notify_push(
                NEW.therapist_id,
                'Nueva reservación',
                client_name || ' — ' || service_name || ' ' || date_str || ' ' || time_str,
                jsonb_build_object('type', 'booking', 'id', NEW.id)
            );
            FOR rec IN SELECT id FROM public.profiles WHERE role = 'receptionist' LOOP
                PERFORM public.notify_push(
                    rec.id,
                    'Nueva reservación',
                    client_name || ' — ' || service_name || ' ' || date_str || ' ' || time_str,
                    jsonb_build_object('type', 'booking', 'id', NEW.id)
                );
            END LOOP;

        -- Recepcionista crea → notificar cliente + terapeuta
        ELSIF creator_role = 'receptionist' THEN
            PERFORM public.notify_push(
                NEW.client_id,
                'Reservación confirmada',
                'Tu sesión de ' || service_name || ' el ' || date_str || ' a las ' || time_str,
                jsonb_build_object('type', 'booking', 'id', NEW.id)
            );
            IF NEW.therapist_id != creator_id THEN
                PERFORM public.notify_push(
                    NEW.therapist_id,
                    'Nueva reservación asignada',
                    client_name || ' — ' || service_name || ' ' || date_str || ' ' || time_str,
                    jsonb_build_object('type', 'booking', 'id', NEW.id)
                );
            END IF;

        -- Terapeuta crea → notificar cliente + recepcionistas
        ELSIF creator_role = 'therapist' THEN
            PERFORM public.notify_push(
                NEW.client_id,
                'Reservación confirmada',
                'Tu sesión de ' || service_name || ' el ' || date_str || ' a las ' || time_str,
                jsonb_build_object('type', 'booking', 'id', NEW.id)
            );
            FOR rec IN SELECT id FROM public.profiles WHERE role = 'receptionist' LOOP
                PERFORM public.notify_push(
                    rec.id,
                    'Nueva reservación',
                    client_name || ' — ' || service_name || ' ' || date_str || ' ' || time_str,
                    jsonb_build_object('type', 'booking', 'id', NEW.id)
                );
            END LOOP;

        -- Admin crea → notificar a todos los involucrados
        ELSIF creator_role = 'admin' THEN
            PERFORM public.notify_push(
                NEW.client_id,
                'Reservación agendada',
                'Tu sesión de ' || service_name || ' el ' || date_str || ' a las ' || time_str,
                jsonb_build_object('type', 'booking', 'id', NEW.id)
            );
            IF NEW.therapist_id != creator_id THEN
                PERFORM public.notify_push(
                    NEW.therapist_id,
                    'Nueva reservación asignada',
                    client_name || ' — ' || service_name || ' ' || date_str || ' ' || time_str,
                    jsonb_build_object('type', 'booking', 'id', NEW.id)
                );
            END IF;
        END IF;

    -- CAMBIO DE ESTADO
    ELSIF (TG_OP = 'UPDATE') THEN
        IF OLD.status != NEW.status THEN
            IF NEW.status = 'confirmed' THEN
                PERFORM public.notify_push(
                    NEW.client_id,
                    'Reservación confirmada ✓',
                    'Tu sesión de ' || service_name || ' el ' || date_str || ' a las ' || time_str || ' está confirmada',
                    jsonb_build_object('type', 'booking', 'id', NEW.id)
                );
            ELSIF NEW.status = 'cancelled' THEN
                PERFORM public.notify_push(
                    NEW.client_id,
                    'Reservación cancelada',
                    'Tu sesión del ' || date_str || ' a las ' || time_str || ' fue cancelada',
                    jsonb_build_object('type', 'booking', 'id', NEW.id)
                );
                PERFORM public.notify_push(
                    NEW.therapist_id,
                    'Reservación cancelada',
                    client_name || ' canceló su sesión del ' || date_str,
                    jsonb_build_object('type', 'booking', 'id', NEW.id)
                );
            ELSIF NEW.status = 'completed' THEN
                PERFORM public.notify_push(
                    NEW.client_id,
                    '¡Gracias por visitarnos!',
                    'Esperamos que hayas disfrutado tu sesión. ¡Te esperamos pronto en Sahara Club!',
                    jsonb_build_object('type', 'booking_completed', 'id', NEW.id)
                );
            END IF;
        END IF;
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

DROP TRIGGER IF EXISTS on_booking_change_push ON public.bookings;
CREATE TRIGGER on_booking_change_push
    AFTER INSERT OR UPDATE ON public.bookings
    FOR EACH ROW EXECUTE FUNCTION public.handle_booking_push();

-- ============================================================
-- TRIGGER: Nuevo mensaje de chat
-- ============================================================

CREATE OR REPLACE FUNCTION public.handle_new_message_push()
RETURNS TRIGGER AS $$
DECLARE
    chat_record   RECORD;
    sender_name   text;
    receiver_id   uuid;
BEGIN
    SELECT * INTO chat_record FROM public.chats WHERE id = NEW.chat_id;

    IF chat_record.participant_1 = NEW.sender_id THEN
        receiver_id := chat_record.participant_2;
    ELSE
        receiver_id := chat_record.participant_1;
    END IF;

    SELECT full_name INTO sender_name FROM public.profiles WHERE id = NEW.sender_id;

    PERFORM public.notify_push(
        receiver_id,
        sender_name,
        substring(NEW.content from 1 for 100),
        jsonb_build_object('type', 'chat', 'chat_id', NEW.chat_id)
    );

    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

DROP TRIGGER IF EXISTS on_message_insert_push ON public.messages;
CREATE TRIGGER on_message_insert_push
    AFTER INSERT ON public.messages
    FOR EACH ROW EXECUTE FUNCTION public.handle_new_message_push();

-- ============================================================
-- TRIGGER: Membresía por vencer (llamar manualmente o con cron)
-- ============================================================

CREATE OR REPLACE FUNCTION public.notify_memberships_expiring()
RETURNS void AS $$
DECLARE
    rec RECORD;
BEGIN
    FOR rec IN
        SELECT cm.client_id, cm.end_date, mp.name AS plan_name
        FROM public.client_memberships cm
        JOIN public.membership_plans mp ON mp.id = cm.plan_id
        WHERE cm.status = 'active'
          AND cm.end_date = CURRENT_DATE + interval '3 days'
    LOOP
        PERFORM public.notify_push(
            rec.client_id,
            'Tu membresía vence pronto',
            'Tu plan ' || rec.plan_name || ' vence el ' || to_char(rec.end_date, 'DD/MM/YYYY') || '. ¡Renuévala para no perder tus beneficios!',
            jsonb_build_object('type', 'membership_expiring')
        );
    END LOOP;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
