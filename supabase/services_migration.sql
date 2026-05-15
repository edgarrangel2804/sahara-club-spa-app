-- ─────────────────────────────────────────────────────────────────────────────
-- services_migration.sql
-- Adds tagline and price_on_quote columns to the services table,
-- then populates taglines for existing services.
-- Safe to re-run: uses ADD COLUMN IF NOT EXISTS + WHERE clause UPDATEs.
-- NOTE: Does NOT add duration_options/package_options JSONB — the DB already
--       uses a flat row-per-duration structure which the mobile app reads directly.
-- ─────────────────────────────────────────────────────────────────────────────

-- 1. Add new columns ───────────────────────────────────────────────────────────
ALTER TABLE services ADD COLUMN IF NOT EXISTS tagline        TEXT;
ALTER TABLE services ADD COLUMN IF NOT EXISTS price_on_quote BOOLEAN NOT NULL DEFAULT false;

-- 2. Mark price-on-quote services ─────────────────────────────────────────────
UPDATE services SET price_on_quote = true
WHERE name IN (
  'Relajación Personalizada',
  'Metodología Corporal',
  'Glow Personalizado',
  'Squad of the Bride',
  'Share Love',
  'Sahara House'
) AND price = 0;

-- 3. Populate taglines ─────────────────────────────────────────────────────────
-- Uses name + category to match existing rows exactly.

-- ── Masajes ───────────────────────────────────────────────────────────────────
UPDATE services SET tagline = 'El masaje de la casa.'
  WHERE name = 'Sahara Soul' AND category = 'Masajes';

UPDATE services SET tagline = 'Un método propio. Un encuentro completo con el cuerpo.'
  WHERE name = 'Amazing Experience' AND category = 'Masajes';

UPDATE services SET tagline = 'Cuando el cuerpo habla, la terapeuta escucha.'
  WHERE name = 'La Magia de Sentir' AND category = 'Masajes';

UPDATE services SET tagline = 'El masaje que abre la puerta emocional.'
  WHERE name = 'Caricia al Corazón' AND category = 'Masajes';

UPDATE services SET tagline = 'Cuando descansas las extremidades, descansa el sistema nervioso.'
  WHERE name = 'Raíces de Calma' AND category = 'Masajes';

UPDATE services SET tagline = 'Liberar la mente, creando espacio interno.'
  WHERE name = 'Ritual Cráneo Facial' AND category = 'Masajes';

UPDATE services SET tagline = 'Fuerza con presencia. Profundidad con cuidado.'
  WHERE name = 'Descarga Consciente' AND category = 'Masajes';

UPDATE services SET tagline = 'Drenar para sanar. Mover para vivir.'
  WHERE name = 'Linfa en Movimiento' AND category = 'Masajes';

UPDATE services SET tagline = 'El poder del calor consciente.'
  WHERE name = 'Calor que Abraza' AND category = 'Masajes';

UPDATE services SET tagline = 'Sostener a quien sostiene vida.'
  WHERE name = 'Creando Vida' AND category = 'Masajes';

-- ── Corporales ────────────────────────────────────────────────────────────────
UPDATE services SET tagline = 'Drenar primero. Descansar después.'
  WHERE name = 'Descanso Sagrado' AND category = 'Corporales';

UPDATE services SET tagline = 'Cuando el calor y la calma se encuentran.'
  WHERE name = 'Alma en Paz' AND category = 'Corporales';

UPDATE services SET tagline = 'La bienvenida a un cuerpo relajado.'
  WHERE name = 'Welcome to the Oasis (x3)' AND category = 'Corporales';

UPDATE services SET tagline = 'Una experiencia. Cinco momentos. Un antes y un después.'
  WHERE name = 'Metodología Sahara Ritual' AND category = 'Corporales';

UPDATE services SET tagline = 'Tu cuerpo. Tu ritmo. Tu experiencia.'
  WHERE name = 'Relajación Personalizada' AND category = 'Corporales';

-- ── Faciales ──────────────────────────────────────────────────────────────────
UPDATE services SET tagline = 'El facial de la casa.'
  WHERE name = 'Sahara Soul Facial' AND category = 'Faciales';

UPDATE services SET tagline = 'Limpieza profunda + tecnología consciente.'
  WHERE name = 'Sahara Soul Deluxe' AND category = 'Faciales';

UPDATE services SET tagline = 'Glow total · Piel renovada.'
  WHERE name = 'Sahara Soul Glowy' AND category = 'Faciales';

UPDATE services SET tagline = 'Iluminar, unificar, revitalizar.'
  WHERE name = 'Sahara Lum' AND category = 'Faciales';

UPDATE services SET tagline = 'La piel también se alimenta de luz.'
  WHERE name = 'Baño de Luz' AND category = 'Faciales';

UPDATE services SET tagline = 'Drenar, desinflamar, revitalizar.'
  WHERE name = 'Linfa en Movimiento Facial' AND category = 'Faciales';

UPDATE services SET tagline = 'Liberar el rostro también libera la mente.'
  WHERE name = 'Neuro Yoga Facial' AND category = 'Faciales';

UPDATE services SET tagline = 'Conciencia + firmeza.'
  WHERE name = 'Neuro Sculpt Yoga Facial' AND category = 'Faciales';

UPDATE services SET tagline = 'Acompañamiento terapéutico.'
  WHERE name = 'Pre & Post operatorio facial' AND category = 'Faciales';

-- ── Faciales Premium ──────────────────────────────────────────────────────────
UPDATE services SET tagline = 'La experiencia facial más completa de Sahara.'
  WHERE name = 'The Facial Experience' AND category = 'Faciales Premium';

UPDATE services SET tagline = 'Experiencia signature de cuidado continuo.'
  WHERE name = 'Metodología Sahara Facial' AND category = 'Faciales Premium';

UPDATE services SET tagline = 'Tu piel · Tu necesidad · Tu ritual.'
  WHERE name = 'Glow Personalizado' AND category = 'Faciales Premium';

-- ── Moldeo Consciente ─────────────────────────────────────────────────────────
UPDATE services SET tagline = 'Drenar · Activar · Reorganizar · Moldear con amor.'
  WHERE name IN ('Transformación Total','Transformación Total x4','Transformación Total x8',
                 'Transformación Total x12','Transformación Total x16','Transformación Total x20')
    AND category = 'Moldeo Consciente';

UPDATE services SET tagline = 'Acompañamiento terapéutico.'
  WHERE name IN ('Pre & Post operatorio corporal','Pre & Post operatorio x5','Pre & Post operatorio x10')
    AND category = 'Moldeo Consciente';

UPDATE services SET tagline = 'Protocolo a tu medida.'
  WHERE name = 'Metodología Corporal' AND category = 'Moldeo Consciente';

-- ── Tecnología Corporal ───────────────────────────────────────────────────────
UPDATE services SET tagline = 'Estimulación localizada.'
  WHERE name = 'Lipoláser' AND category = 'Tecnología Corporal';

UPDATE services SET tagline = 'Movilización de tejido.'
  WHERE name = 'Cavitación' AND category = 'Tecnología Corporal';

UPDATE services SET tagline = 'Reafirmación y moldeo.'
  WHERE name = 'Ultrasonido Corporal' AND category = 'Tecnología Corporal';

UPDATE services SET tagline = 'Firmeza y elasticidad.'
  WHERE name = 'Radiofrecuencia Corporal' AND category = 'Tecnología Corporal';

UPDATE services SET tagline = 'Estimulación muscular.'
  WHERE name = 'Body Sculpt' AND category = 'Tecnología Corporal';

UPDATE services SET tagline = 'Técnica manual de origen ancestral.'
  WHERE name = 'Maderoterapia' AND category = 'Tecnología Corporal';

-- ── Tecnología Facial ─────────────────────────────────────────────────────────
UPDATE services SET tagline = 'Estimula colágeno y firmeza.'
  WHERE name = 'Radiofrecuencia' AND category = 'Tecnología Facial';

UPDATE services SET tagline = 'Apoya procesos de reafirmación.'
  WHERE name = 'Ultrasonido' AND category = 'Tecnología Facial';

UPDATE services SET tagline = 'Mejora tono y textura.'
  WHERE name = 'Fotorejuvenecimiento' AND category = 'Tecnología Facial';

UPDATE services SET tagline = 'Regeneración y calma.'
  WHERE name = 'Máscara LED' AND category = 'Tecnología Facial';

-- ── Fusionadas ────────────────────────────────────────────────────────────────
UPDATE services SET tagline = 'Rostro y cuerpo en equilibrio.'
  WHERE name = 'Sahara Day Spa' AND category = 'Fusionadas';

UPDATE services SET tagline = 'Drenar · Regenerar · Iluminar.'
  WHERE name = 'Luz en Movimiento' AND category = 'Fusionadas';

UPDATE services SET tagline = 'Soltar · Sentir · Suavizar.'
  WHERE name = 'Calma para el Alma' AND category = 'Fusionadas';

UPDATE services SET tagline = 'Fuerza consciente.'
  WHERE name = 'Liberación de Raíz' AND category = 'Fusionadas';

UPDATE services SET tagline = 'Descanso profundo + iluminación.'
  WHERE name = 'Volver a Mí' AND category = 'Fusionadas';

UPDATE services SET tagline = 'Cuerpo ligero · Rostro relajado · Luz total.'
  WHERE name = 'Glow & Flow' AND category = 'Fusionadas';

UPDATE services SET tagline = 'Experiencia en pareja.'
  WHERE name = 'Feel in Love' AND category = 'Fusionadas';

UPDATE services SET tagline = 'Antes del sí.'
  WHERE name = 'Bride to Be' AND category = 'Fusionadas';

UPDATE services SET tagline = 'Celebración privada.'
  WHERE name = 'Squad of the Bride' AND category = 'Fusionadas';

UPDATE services SET tagline = 'Cumpleaños consciente · 1 persona.'
  WHERE name = 'Vuelta al Sol' AND category = 'Fusionadas';

UPDATE services SET tagline = 'Celebrar la amistad.'
  WHERE name = 'Share Love' AND category = 'Fusionadas';

-- ── Colaboraciones ────────────────────────────────────────────────────────────
UPDATE services SET tagline = 'Respirar · Sentir · Descansar.'
  WHERE name = 'Mind & Body Reset' AND category = 'Colaboraciones';

UPDATE services SET tagline = 'Respiración · Cuerpo · Recuperación.'
  WHERE name = 'RE-NACER' AND category = 'Colaboraciones';

-- ── Sahara House ──────────────────────────────────────────────────────────────
UPDATE services SET tagline = 'Hospedaje + experiencias de bienestar.'
  WHERE name = 'Sahara House' AND category = 'Sahara House';
