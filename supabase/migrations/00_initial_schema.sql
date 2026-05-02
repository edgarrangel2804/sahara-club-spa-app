-- ============================================================
-- SAHARA CLUB SPA - Schema Inicial
-- Basado en Clinica del Puerto, adaptado para spa
-- ============================================================

-- ============================================================
-- TIPOS / ENUMS
-- ============================================================

CREATE TYPE user_role AS ENUM ('client', 'therapist', 'receptionist', 'admin');

CREATE TYPE booking_status AS ENUM ('scheduled', 'confirmed', 'completed', 'cancelled', 'no_show');

CREATE TYPE payment_status AS ENUM ('pending', 'paid', 'refunded', 'failed');

CREATE TYPE membership_status AS ENUM ('active', 'inactive', 'expired', 'cancelled');

CREATE TYPE therapist_specialty AS ENUM (
  'massage',
  'facial',
  'body_treatment',
  'nail_care',
  'hair_removal',
  'hydrotherapy',
  'general'
);

-- ============================================================
-- PROFILES (Identidad central de usuarios)
-- ============================================================

CREATE TABLE public.profiles (
  id              uuid REFERENCES auth.users NOT NULL PRIMARY KEY,
  full_name       text,
  phone           text,
  avatar_url      text,
  role            user_role DEFAULT 'client',
  specialty       therapist_specialty,        -- Solo para terapeutas
  bio             text,                        -- Bio del terapeuta
  is_active       boolean DEFAULT true,
  fcm_token       text,                        -- Token FCM para push notifications
  created_at      timestamptz DEFAULT now(),
  updated_at      timestamptz DEFAULT now()
);

ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can see their own profile"
  ON public.profiles FOR SELECT
  USING (auth.uid() = id);

CREATE POLICY "Staff can see all profiles"
  ON public.profiles FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM public.profiles
      WHERE id = auth.uid()
      AND role IN ('therapist', 'receptionist', 'admin')
    )
  );

CREATE POLICY "Users can update their own profile"
  ON public.profiles FOR UPDATE
  USING (auth.uid() = id);

CREATE POLICY "Admins can manage all profiles"
  ON public.profiles FOR ALL
  USING (
    EXISTS (
      SELECT 1 FROM public.profiles
      WHERE id = auth.uid() AND role = 'admin'
    )
  );

-- ============================================================
-- CLIENT_PROFILES (Ficha del cliente - reemplaza historia clínica)
-- ============================================================

CREATE TABLE public.client_profiles (
  id                    uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  client_id             uuid REFERENCES public.profiles(id) NOT NULL UNIQUE,
  -- Datos de salud relevantes para el spa
  skin_type             text,                  -- seca, grasa, mixta, sensible, normal
  known_allergies       text,
  medical_conditions    text,                  -- condiciones que afecten tratamientos
  is_pregnant           boolean DEFAULT false,
  -- Preferencias
  preferred_pressure    text,                  -- suave, media, fuerte (masajes)
  preferred_therapist   uuid REFERENCES public.profiles(id),
  preferred_schedule    text,
  notes                 text,                  -- notas generales del cliente
  -- Consentimiento
  consent_treatment     boolean DEFAULT false,
  consent_data          boolean DEFAULT false,
  signature_url         text,
  -- Contacto de emergencia
  emergency_name        text,
  emergency_phone       text,
  emergency_relation    text,
  created_at            timestamptz DEFAULT now(),
  updated_at            timestamptz DEFAULT now()
);

ALTER TABLE public.client_profiles ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Clients can see their own profile"
  ON public.client_profiles FOR SELECT
  USING (auth.uid() = client_id);

CREATE POLICY "Staff can see all client profiles"
  ON public.client_profiles FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM public.profiles
      WHERE id = auth.uid()
      AND role IN ('therapist', 'receptionist', 'admin')
    )
  );

CREATE POLICY "Clients can update their own profile"
  ON public.client_profiles FOR ALL
  USING (auth.uid() = client_id);

CREATE POLICY "Admins can manage all client profiles"
  ON public.client_profiles FOR ALL
  USING (
    EXISTS (
      SELECT 1 FROM public.profiles
      WHERE id = auth.uid() AND role = 'admin'
    )
  );

-- ============================================================
-- SERVICES (Catálogo de servicios/rituales del spa)
-- ============================================================

CREATE TABLE public.services (
  id              uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  name            text NOT NULL,
  description     text,
  category        text NOT NULL,              -- masajes, faciales, corporales, etc.
  duration_min    integer NOT NULL,           -- duración en minutos
  price           numeric(10,2) NOT NULL,
  image_url       text,
  is_active       boolean DEFAULT true,
  display_order   integer DEFAULT 0,
  created_at      timestamptz DEFAULT now()
);

ALTER TABLE public.services ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Everyone can view active services"
  ON public.services FOR SELECT
  USING (is_active = true);

CREATE POLICY "Admins can manage services"
  ON public.services FOR ALL
  USING (
    EXISTS (
      SELECT 1 FROM public.profiles
      WHERE id = auth.uid() AND role = 'admin'
    )
  );

-- Servicios iniciales del spa
INSERT INTO public.services (name, description, category, duration_min, price, display_order) VALUES
  ('Masaje Relajante', 'Masaje corporal completo con aceites esenciales para liberar tensiones.', 'masajes', 60, 850.00, 1),
  ('Masaje de Tejido Profundo', 'Técnica de presión profunda para aliviar contracturas musculares.', 'masajes', 75, 1050.00, 2),
  ('Masaje con Piedras Calientes', 'Ritual de relajación con piedras volcánicas calientes.', 'masajes', 90, 1200.00, 3),
  ('Facial Hidratante', 'Limpieza profunda e hidratación intensiva para todo tipo de piel.', 'faciales', 60, 750.00, 4),
  ('Facial Antiedad', 'Tratamiento reafirmante con ácido hialurónico y colágeno.', 'faciales', 75, 950.00, 5),
  ('Exfoliación Corporal', 'Renovación de la piel con exfoliante natural de sales del Mar Muerto.', 'corporales', 45, 650.00, 6),
  ('Envoltura Tonificante', 'Tratamiento reafirmante con barro y algas marinas.', 'corporales', 75, 900.00, 7),
  ('Ritual Sahara Completo', 'Experiencia completa: masaje + facial + envoltura. El ritual definitivo.', 'rituales', 180, 2500.00, 8);

-- ============================================================
-- MEMBERSHIP_PLANS (Planes de membresía)
-- ============================================================

CREATE TABLE public.membership_plans (
  id                  uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  name                text NOT NULL,
  description         text,
  price_monthly       numeric(10,2) NOT NULL,
  sessions_per_month  integer NOT NULL,        -- sesiones incluidas al mes
  includes            text[],                  -- lista de beneficios
  discount_pct        numeric(5,2) DEFAULT 0,  -- descuento en servicios adicionales
  image_url           text,
  icon                text,
  is_active           boolean DEFAULT true,
  display_order       integer DEFAULT 0,
  created_at          timestamptz DEFAULT now()
);

ALTER TABLE public.membership_plans ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Everyone can view active plans"
  ON public.membership_plans FOR SELECT
  USING (is_active = true);

CREATE POLICY "Admins can manage plans"
  ON public.membership_plans FOR ALL
  USING (
    EXISTS (
      SELECT 1 FROM public.profiles
      WHERE id = auth.uid() AND role = 'admin'
    )
  );

-- Planes iniciales
INSERT INTO public.membership_plans (name, description, price_monthly, sessions_per_month, includes, discount_pct, display_order) VALUES
  ('Oasis', 'Ideal para empezar tu rutina de bienestar.', 1200.00, 2,
    ARRAY['2 sesiones de masaje relajante al mes', 'Acceso a sala de relajación', '10% de descuento en servicios adicionales'],
    10.00, 1),
  ('Sahara', 'La membresía más popular del club.', 2200.00, 4,
    ARRAY['4 sesiones a elegir al mes', 'Facial mensual incluido', '15% de descuento en productos', 'Acceso ilimitado a zona húmeda'],
    15.00, 2),
  ('Royal', 'La experiencia definitiva sin límites.', 3800.00, 8,
    ARRAY['8 sesiones premium al mes', 'Ritual Sahara Completo mensual', '25% de descuento en todos los servicios', 'Terapeuta personal asignado', 'Acceso VIP a eventos exclusivos'],
    25.00, 3);

-- ============================================================
-- CLIENT_MEMBERSHIPS (Membresías activas de clientes)
-- ============================================================

CREATE TABLE public.client_memberships (
  id              uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  client_id       uuid REFERENCES public.profiles(id) NOT NULL,
  plan_id         uuid REFERENCES public.membership_plans(id) NOT NULL,
  status          membership_status DEFAULT 'active',
  start_date      date NOT NULL DEFAULT CURRENT_DATE,
  end_date        date,
  sessions_used   integer DEFAULT 0,
  sessions_total  integer NOT NULL,
  auto_renew      boolean DEFAULT true,
  created_at      timestamptz DEFAULT now(),
  updated_at      timestamptz DEFAULT now()
);

ALTER TABLE public.client_memberships ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Clients can see their own membership"
  ON public.client_memberships FOR SELECT
  USING (auth.uid() = client_id);

CREATE POLICY "Staff can see all memberships"
  ON public.client_memberships FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM public.profiles
      WHERE id = auth.uid()
      AND role IN ('receptionist', 'admin')
    )
  );

CREATE POLICY "Admins can manage memberships"
  ON public.client_memberships FOR ALL
  USING (
    EXISTS (
      SELECT 1 FROM public.profiles
      WHERE id = auth.uid() AND role = 'admin'
    )
  );

-- ============================================================
-- BOOKINGS (Reservaciones - reemplaza appointments)
-- ============================================================

CREATE TABLE public.bookings (
  id                    uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  client_id             uuid REFERENCES public.profiles(id) NOT NULL,
  therapist_id          uuid REFERENCES public.profiles(id) NOT NULL,
  service_id            uuid REFERENCES public.services(id) NOT NULL,
  membership_id         uuid REFERENCES public.client_memberships(id), -- si aplica membresía
  booking_date          date NOT NULL,
  booking_time          time NOT NULL,
  duration_min          integer NOT NULL,
  status                booking_status DEFAULT 'scheduled',
  cabin                 text,                  -- cabina asignada
  price                 numeric(10,2),         -- precio cobrado (puede diferir del servicio)
  session_notes         text,                  -- notas post-sesión del terapeuta
  client_notes          text,                  -- notas/peticiones del cliente
  created_by            uuid REFERENCES public.profiles(id),
  created_at            timestamptz DEFAULT now(),
  updated_at            timestamptz DEFAULT now()
);

ALTER TABLE public.bookings ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Clients can see their own bookings"
  ON public.bookings FOR SELECT
  USING (auth.uid() = client_id);

CREATE POLICY "Therapists can see their assigned bookings"
  ON public.bookings FOR SELECT
  USING (auth.uid() = therapist_id);

CREATE POLICY "Receptionist can see all bookings"
  ON public.bookings FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM public.profiles
      WHERE id = auth.uid()
      AND role IN ('receptionist', 'admin')
    )
  );

CREATE POLICY "Staff can create bookings"
  ON public.bookings FOR INSERT
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM public.profiles
      WHERE id = auth.uid()
      AND role IN ('client', 'therapist', 'receptionist', 'admin')
    )
  );

CREATE POLICY "Admins can manage all bookings"
  ON public.bookings FOR ALL
  USING (
    EXISTS (
      SELECT 1 FROM public.profiles
      WHERE id = auth.uid() AND role = 'admin'
    )
  );

CREATE POLICY "Receptionist can update bookings"
  ON public.bookings FOR UPDATE
  USING (
    EXISTS (
      SELECT 1 FROM public.profiles
      WHERE id = auth.uid()
      AND role IN ('receptionist', 'admin')
    )
  );

CREATE POLICY "Therapist can add session notes"
  ON public.bookings FOR UPDATE
  USING (auth.uid() = therapist_id);

-- ============================================================
-- PAYMENTS (Pagos)
-- ============================================================

CREATE TABLE public.payments (
  id              uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  client_id       uuid REFERENCES public.profiles(id) NOT NULL,
  booking_id      uuid REFERENCES public.bookings(id),
  membership_id   uuid REFERENCES public.client_memberships(id),
  amount          numeric(10,2) NOT NULL,
  status          payment_status DEFAULT 'pending',
  payment_method  text,                        -- efectivo, tarjeta, transferencia
  reference       text,                        -- referencia de pago
  notes           text,
  created_by      uuid REFERENCES public.profiles(id),
  created_at      timestamptz DEFAULT now()
);

ALTER TABLE public.payments ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Clients can see their own payments"
  ON public.payments FOR SELECT
  USING (auth.uid() = client_id);

CREATE POLICY "Staff can see all payments"
  ON public.payments FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM public.profiles
      WHERE id = auth.uid()
      AND role IN ('receptionist', 'admin')
    )
  );

CREATE POLICY "Staff can create payments"
  ON public.payments FOR INSERT
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM public.profiles
      WHERE id = auth.uid()
      AND role IN ('receptionist', 'admin')
    )
  );

CREATE POLICY "Admins can manage all payments"
  ON public.payments FOR ALL
  USING (
    EXISTS (
      SELECT 1 FROM public.profiles
      WHERE id = auth.uid() AND role = 'admin'
    )
  );

-- ============================================================
-- EXPENSES (Gastos del spa)
-- ============================================================

CREATE TABLE public.expenses (
  id          uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  description text NOT NULL,
  amount      numeric(10,2) NOT NULL,
  category    text NOT NULL,                   -- productos, renta, servicios, personal, etc.
  date        date NOT NULL DEFAULT CURRENT_DATE,
  receipt_url text,
  created_by  uuid REFERENCES public.profiles(id),
  created_at  timestamptz DEFAULT now()
);

ALTER TABLE public.expenses ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Admins can manage expenses"
  ON public.expenses FOR ALL
  USING (
    EXISTS (
      SELECT 1 FROM public.profiles
      WHERE id = auth.uid() AND role = 'admin'
    )
  );

-- ============================================================
-- CHATS (Sistema de mensajería)
-- ============================================================

CREATE TABLE public.chats (
  id              uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  participant_1   uuid REFERENCES public.profiles(id) NOT NULL,
  participant_2   uuid REFERENCES public.profiles(id) NOT NULL,
  created_at      timestamptz DEFAULT now(),
  UNIQUE(participant_1, participant_2)
);

ALTER TABLE public.chats ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Participants can see their chats"
  ON public.chats FOR SELECT
  USING (auth.uid() = participant_1 OR auth.uid() = participant_2);

CREATE POLICY "Users can create chats"
  ON public.chats FOR INSERT
  WITH CHECK (auth.uid() = participant_1 OR auth.uid() = participant_2);

-- ============================================================
-- MESSAGES (Mensajes del chat)
-- ============================================================

CREATE TABLE public.messages (
  id          uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  chat_id     uuid REFERENCES public.chats(id) NOT NULL,
  sender_id   uuid REFERENCES public.profiles(id) NOT NULL,
  content     text NOT NULL,
  read_at     timestamptz,
  created_at  timestamptz DEFAULT now()
);

ALTER TABLE public.messages ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Chat participants can see messages"
  ON public.messages FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM public.chats
      WHERE id = chat_id
      AND (participant_1 = auth.uid() OR participant_2 = auth.uid())
    )
  );

CREATE POLICY "Users can send messages"
  ON public.messages FOR INSERT
  WITH CHECK (auth.uid() = sender_id);

-- ============================================================
-- NOTIFICATIONS (Historial de notificaciones)
-- ============================================================

CREATE TABLE public.notifications (
  id          uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id     uuid REFERENCES public.profiles(id) NOT NULL,
  title       text NOT NULL,
  body        text NOT NULL,
  data        jsonb DEFAULT '{}',
  read_at     timestamptz,
  created_at  timestamptz DEFAULT now()
);

ALTER TABLE public.notifications ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can see their own notifications"
  ON public.notifications FOR SELECT
  USING (auth.uid() = user_id);

CREATE POLICY "Users can update their own notifications"
  ON public.notifications FOR UPDATE
  USING (auth.uid() = user_id);

-- ============================================================
-- REALTIME (habilitar para tablas que necesitan tiempo real)
-- ============================================================

ALTER PUBLICATION supabase_realtime ADD TABLE public.messages;
ALTER PUBLICATION supabase_realtime ADD TABLE public.notifications;
ALTER PUBLICATION supabase_realtime ADD TABLE public.bookings;

-- ============================================================
-- STORAGE (bucket para imágenes)
-- ============================================================

INSERT INTO storage.buckets (id, name, public)
  VALUES ('avatars', 'avatars', true)
  ON CONFLICT DO NOTHING;

INSERT INTO storage.buckets (id, name, public)
  VALUES ('services', 'services', true)
  ON CONFLICT DO NOTHING;

INSERT INTO storage.buckets (id, name, public)
  VALUES ('signatures', 'signatures', false)
  ON CONFLICT DO NOTHING;

-- Storage policies
CREATE POLICY "Avatars are publicly viewable"
  ON storage.objects FOR SELECT
  USING (bucket_id = 'avatars');

CREATE POLICY "Users can upload their own avatar"
  ON storage.objects FOR INSERT
  WITH CHECK (bucket_id = 'avatars' AND auth.uid()::text = (storage.foldername(name))[1]);

CREATE POLICY "Services images are publicly viewable"
  ON storage.objects FOR SELECT
  USING (bucket_id = 'services');

CREATE POLICY "Admins can manage service images"
  ON storage.objects FOR ALL
  USING (
    bucket_id = 'services' AND
    EXISTS (
      SELECT 1 FROM public.profiles
      WHERE id = auth.uid() AND role = 'admin'
    )
  );

CREATE POLICY "Staff can access signatures"
  ON storage.objects FOR SELECT
  USING (
    bucket_id = 'signatures' AND
    EXISTS (
      SELECT 1 FROM public.profiles
      WHERE id = auth.uid()
      AND role IN ('therapist', 'receptionist', 'admin')
    )
  );

-- ============================================================
-- FUNCIÓN: auto-crear perfil al registrarse
-- ============================================================

CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
  INSERT INTO public.profiles (id, full_name, role)
  VALUES (
    NEW.id,
    COALESCE(NEW.raw_user_meta_data->>'full_name', NEW.email),
    COALESCE((NEW.raw_user_meta_data->>'role')::user_role, 'client')
  );
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();

-- ============================================================
-- FUNCIÓN: actualizar updated_at automáticamente
-- ============================================================

CREATE OR REPLACE FUNCTION public.handle_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = now();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER on_profiles_updated
  BEFORE UPDATE ON public.profiles
  FOR EACH ROW EXECUTE FUNCTION public.handle_updated_at();

CREATE TRIGGER on_client_profiles_updated
  BEFORE UPDATE ON public.client_profiles
  FOR EACH ROW EXECUTE FUNCTION public.handle_updated_at();

CREATE TRIGGER on_bookings_updated
  BEFORE UPDATE ON public.bookings
  FOR EACH ROW EXECUTE FUNCTION public.handle_updated_at();

CREATE TRIGGER on_memberships_updated
  BEFORE UPDATE ON public.client_memberships
  FOR EACH ROW EXECUTE FUNCTION public.handle_updated_at();
