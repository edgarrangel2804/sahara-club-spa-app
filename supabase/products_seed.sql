-- Tabla de productos
CREATE TABLE IF NOT EXISTS products (
  id            UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name          TEXT NOT NULL,
  description   TEXT,
  price         NUMERIC(10,2) NOT NULL,
  type          TEXT CHECK (type IN ('service','physical','digital')) NOT NULL,
  image         TEXT,
  duration      INT,
  stock         INT,
  category      TEXT,
  active        BOOLEAN DEFAULT TRUE,
  display_order INT DEFAULT 0,
  created_at    TIMESTAMPTZ DEFAULT NOW()
);

ALTER TABLE products ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Anyone reads active products" ON products;
CREATE POLICY "Anyone reads active products" ON products
  FOR SELECT USING (active = true);

-- ── MASAJES ──────────────────────────────────────────────────────────────────
INSERT INTO products (name, description, price, type, duration, category, display_order) VALUES
('Sahara Soul',          'Masaje de reset profundo para cuerpo y mente',                        1089, 'service', 60,  'masajes', 1),
('Sahara Soul',          'Masaje de reset profundo para cuerpo y mente',                        1590, 'service', 90,  'masajes', 2),
('Sahara Soul',          'Masaje de reset profundo para cuerpo y mente',                        1970, 'service', 120, 'masajes', 3),
('Amazing Experience',   'Experiencia exclusiva con Jochebed',                                  1777, 'service', 90,  'masajes', 4),
('La Magia de Sentir',   'Reconecta con tu cuerpo a través del tacto consciente',               555,  'service', 30,  'masajes', 5),
('La Magia de Sentir',   'Reconecta con tu cuerpo a través del tacto consciente',               1111, 'service', 60,  'masajes', 6),
('La Magia de Sentir',   'Reconecta con tu cuerpo a través del tacto consciente',               1680, 'service', 90,  'masajes', 7),
('Caricia al Corazón',   'Masaje de calma y conexión emocional',                                950,  'service', 60,  'masajes', 8),
('Raíces de Calma',      'Ancla tu energía y libera la tensión acumulada',                      950,  'service', 60,  'masajes', 9),
('Ritual Cráneo Facial', 'Alivio de tensión desde la cabeza hasta el rostro',                   950,  'service', 60,  'masajes', 10),
('Descarga Consciente',  'Liberación profunda de tensión muscular y mental',                    1265, 'service', 60,  'masajes', 11),
('Descarga Consciente',  'Liberación profunda de tensión muscular y mental',                    1777, 'service', 90,  'masajes', 12),
('Linfa en Movimiento',  'Drenaje linfático para depurar y revitalizar',                        999,  'service', 60,  'masajes', 13),
('Calor que Abraza',     'Masaje con piedras calientes de basalto',                             1380, 'service', 60,  'masajes', 14),
('Calor que Abraza',     'Masaje con piedras calientes de basalto',                             1999, 'service', 90,  'masajes', 15),
('Creando Vida',         'Masaje prenatal seguro y reconfortante',                              999,  'service', 60,  'masajes', 16);

-- ── EXPERIENCIAS CORPORALES ───────────────────────────────────────────────────
INSERT INTO products (name, description, price, type, duration, category, display_order) VALUES
('Descanso Sagrado',           'Ritual de descanso total cuerpo y mente',                      1499, 'service', 90,  'corporales', 20),
('Descanso Sagrado',           'Ritual de descanso total cuerpo y mente',                      1799, 'service', 120, 'corporales', 21),
('Alma en Paz',                'Reconecta con tu calma interior',                              1222, 'service', 60,  'corporales', 22),
('Welcome to the Oasis',       'Pack de 3 sesiones — bienvenida al spa',                       2999, 'service', 60,  'corporales', 23),
('Welcome to the Oasis',       'Pack de 3 sesiones — bienvenida al spa',                       4299, 'service', 90,  'corporales', 24),
('Metodología Sahara Ritual',  'Programa de 6 sesiones de transformación',                     5499, 'service', 60,  'corporales', 25),
('Relajación Personalizada',   'Sesión a medida según tus necesidades',                        0,    'service', 60,  'corporales', 26);

-- ── FACIALES ─────────────────────────────────────────────────────────────────
INSERT INTO products (name, description, price, type, duration, category, display_order) VALUES
('Sahara Soul Facial',         'Facial de reinicio profundo para tu piel',                     1190, 'service', 90,  'faciales', 30),
('Sahara Soul Deluxe',         'Versión premium del facial Sahara Soul',                       1450, 'service', 90,  'faciales', 31),
('Sahara Soul Glowy',          'Facial de luminosidad y efecto glow',                          1799, 'service', 120, 'faciales', 32),
('Sahara Lum',                 'Iluminación y uniformización del tono',                        1550, 'service', 90,  'faciales', 33),
('Baño de Luz',                'Tratamiento express de luminosidad',                           888,  'service', 60,  'faciales', 34),
('Linfa en Movimiento Facial', 'Drenaje linfático para el rostro',                            699,  'service', 30,  'faciales', 35),
('Neuro Yoga Facial',          'Técnicas neuro-musculares de rejuvenecimiento',                999,  'service', 60,  'faciales', 36),
('Neuro Sculpt Yoga Facial',   'Escultura facial con técnica neuro-muscular',                  1299, 'service', 90,  'faciales', 37),
('Pre & Post operatorio facial','Cuidado especializado antes y después de cirugía',             999,  'service', 60,  'faciales', 38);

-- ── TECNOLOGÍA FACIAL ─────────────────────────────────────────────────────────
INSERT INTO products (name, description, price, type, duration, category, display_order) VALUES
('Radiofrecuencia',            'Reafirmación y lifting no invasivo',                           999,  'service', 45,  'tecnologia_facial', 40),
('Ultrasonido',                'Penetración profunda de activos cosméticos',                   999,  'service', 45,  'tecnologia_facial', 41),
('Fotorejuvenecimiento',       'Renovación celular con luz intensa pulsada',                   950,  'service', 30,  'tecnologia_facial', 42),
('Máscara LED',                'Cromoterapia facial con luz LED',                              555,  'service', 30,  'tecnologia_facial', 43);

-- ── EXPERIENCIAS FACIALES COMBINADAS ──────────────────────────────────────────
INSERT INTO products (name, description, price, type, duration, category, display_order) VALUES
('The Facial Experience',      'Experiencia facial completa e inmersiva',                      2599, 'service', 150, 'faciales_combo', 50),
('Metodología Sahara Facial',  'Programa de 4 sesiones de transformación facial',              4850, 'service', 60,  'faciales_combo', 51),
('Glow Personalizado',         'Tratamiento facial a medida según tu piel',                   0,    'service', 60,  'faciales_combo', 52);

-- ── MOLDEO CONSCIENTE ────────────────────────────────────────────────────────
INSERT INTO products (name, description, price, type, duration, category, display_order) VALUES
('Transformación Total',       '1 sesión de moldeo corporal consciente',                      1500, 'service', 90,  'moldeo', 60),
('Transformación Total x4',    'Paquete de 4 sesiones de moldeo corporal',                    5700, 'service', 90,  'moldeo', 61),
('Transformación Total x8',    'Paquete de 8 sesiones de moldeo corporal',                    11400,'service', 90,  'moldeo', 62),
('Transformación Total x12',   'Paquete de 12 sesiones de moldeo corporal',                   17100,'service', 90,  'moldeo', 63),
('Transformación Total x20',   'Paquete de 20 sesiones de moldeo corporal',                   27000,'service', 90,  'moldeo', 64),
('Pre & Post operatorio corporal','1 sesión de recuperación especializada',                   999,  'service', 60,  'moldeo', 65),
('Pre & Post operatorio x5',   'Paquete de 5 sesiones de recuperación',                       4450, 'service', 60,  'moldeo', 66),
('Pre & Post operatorio x10',  'Paquete de 10 sesiones de recuperación',                      8999, 'service', 60,  'moldeo', 67),
('Metodología Corporal',       'Programa personalizado a tu medida',                          0,    'service', 60,  'moldeo', 68);

-- ── TECNOLOGÍA CORPORAL ───────────────────────────────────────────────────────
INSERT INTO products (name, description, price, type, duration, category, display_order) VALUES
('Lipoláser',                  'Reducción localizada no invasiva',                             850,  'service', 50,  'tecnologia_corporal', 70),
('Cavitación',                 'Ultrasonido de alta frecuencia para reducción de grasa',       899,  'service', 50,  'tecnologia_corporal', 71),
('Ultrasonido Corporal',       'Penetración profunda de activos en el cuerpo',                 899,  'service', 50,  'tecnologia_corporal', 72),
('Radiofrecuencia Corporal',   'Reafirmación corporal no invasiva',                           999,  'service', 50,  'tecnologia_corporal', 73),
('Body Sculpt',                'Escultura corporal con tecnología avanzada',                   1299, 'service', 50,  'tecnologia_corporal', 74),
('Maderoterapia',              'Moldeo y drenaje con madera terapéutica',                      999,  'service', 60,  'tecnologia_corporal', 75);

-- ── EXPERIENCIAS FUSIONADAS ───────────────────────────────────────────────────
INSERT INTO products (name, description, price, type, duration, category, display_order) VALUES
('Sahara Day Spa',             'Día completo de experiencias spa',                             2080, 'service', 150, 'fusionadas', 80),
('Luz en Movimiento',          'Experiencia fusionada de luz y movimiento',                    1499, 'service', 90,  'fusionadas', 81),
('Calma para el Alma',         'Ritual profundo de calma y renovación',                       2099, 'service', 120, 'fusionadas', 82),
('Liberación de Raíz',         'Liberación energética desde la raíz',                         2250, 'service', 120, 'fusionadas', 83),
('Volver a Mí',                'Retiro express de reconexión personal',                       3999, 'service', 180, 'fusionadas', 84),
('Glow & Flow',                'Brillo y fluidez — experiencia total',                        2499, 'service', 150, 'fusionadas', 85),
('Feel in Love',               'Experiencia romántica para parejas — 60min',                  2399, 'service', 60,  'fusionadas', 86),
('Feel in Love',               'Experiencia romántica para parejas — 90min',                  3499, 'service', 90,  'fusionadas', 87),
('Bride to Be',                'Ritual especial para la novia',                               1999, 'service', 120, 'fusionadas', 88),
('Squad of the Bride',         'Experiencia grupal para el squad de la novia',                0,    'service', 120, 'fusionadas', 89),
('Vuelta al Sol',              'Ritual de renovación y energía solar',                        2499, 'service', 150, 'fusionadas', 90),
('Share Love',                 'Comparte bienestar con quien más quieres',                    0,    'service', 60,  'fusionadas', 91);

-- ── COLABORACIONES ────────────────────────────────────────────────────────────
INSERT INTO products (name, description, price, type, duration, category, display_order) VALUES
('Mind & Body Reset',          'Con Soulab — reset mental y corporal completo',                1799, 'service', 120, 'colaboraciones', 100),
('RE-NACER',                   'Soulab + Sahara + Motus — experiencia de renacimiento',        2599, 'service', 180, 'colaboraciones', 101);

-- ── SAHARA HOUSE ──────────────────────────────────────────────────────────────
INSERT INTO products (name, description, price, type, duration, category, display_order) VALUES
('Sahara House',               'Hospedaje para 1-10 personas con experiencias spa incluidas', 0,    'service', null,'sahara_house', 110);
