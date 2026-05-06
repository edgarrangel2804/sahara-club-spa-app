-- ============================================================
-- SAHARA CLUB SPA — Seed completo de servicios (tabla public.services)
-- Reemplaza los 8 servicios placeholder del schema inicial
-- con el catálogo real del spa según PDF de precios.
-- ============================================================

-- Borrar placeholders del schema inicial (solo si no hay bookings reales)
DELETE FROM public.services
WHERE name IN (
  'Masaje Relajante', 'Masaje de Tejido Profundo', 'Masaje con Piedras Calientes',
  'Facial Hidratante', 'Facial Antiedad', 'Exfoliación Corporal',
  'Envoltura Tonificante', 'Ritual Sahara Completo'
);

-- ── MASAJES ───────────────────────────────────────────────────────────────────
INSERT INTO public.services (name, description, category, duration_min, price, display_order) VALUES
  ('Sahara Soul',            'Masaje de reset profundo para cuerpo y mente',                          'Masajes', 60,  1089.00, 100),
  ('Sahara Soul',            'Masaje de reset profundo para cuerpo y mente',                          'Masajes', 90,  1590.00, 101),
  ('Sahara Soul',            'Masaje de reset profundo para cuerpo y mente',                          'Masajes', 120, 1970.00, 102),
  ('Amazing Experience',     'Experiencia exclusiva con la terapeuta Jochebed',                       'Masajes', 90,  1777.00, 103),
  ('La Magia de Sentir',     'Reconecta con tu cuerpo a través del tacto consciente',                 'Masajes', 30,  555.00,  104),
  ('La Magia de Sentir',     'Reconecta con tu cuerpo a través del tacto consciente',                 'Masajes', 60,  1111.00, 105),
  ('La Magia de Sentir',     'Reconecta con tu cuerpo a través del tacto consciente',                 'Masajes', 90,  1680.00, 106),
  ('Caricia al Corazón',     'Masaje de calma y conexión emocional profunda',                         'Masajes', 60,  950.00,  107),
  ('Raíces de Calma',        'Ancla tu energía y libera la tensión acumulada',                        'Masajes', 60,  950.00,  108),
  ('Ritual Cráneo Facial',   'Alivio de tensión desde la cabeza hasta el rostro',                     'Masajes', 60,  950.00,  109),
  ('Descarga Consciente',    'Liberación profunda de tensión muscular y mental',                      'Masajes', 60,  1265.00, 110),
  ('Descarga Consciente',    'Liberación profunda de tensión muscular y mental',                      'Masajes', 90,  1777.00, 111),
  ('Linfa en Movimiento',    'Drenaje linfático para depurar y revitalizar el cuerpo',                'Masajes', 60,  999.00,  112),
  ('Calor que Abraza',       'Masaje con piedras calientes de basalto volcánico',                     'Masajes', 60,  1380.00, 113),
  ('Calor que Abraza',       'Masaje con piedras calientes de basalto volcánico',                     'Masajes', 90,  1999.00, 114),
  ('Creando Vida',           'Masaje prenatal seguro, consciente y reconfortante',                    'Masajes', 60,  999.00,  115);

-- ── EXPERIENCIAS CORPORALES ───────────────────────────────────────────────────
INSERT INTO public.services (name, description, category, duration_min, price, display_order) VALUES
  ('Descanso Sagrado',             'Ritual de descanso total para cuerpo y mente',                   'Corporales', 90,  1499.00, 200),
  ('Descanso Sagrado',             'Ritual de descanso total para cuerpo y mente',                   'Corporales', 120, 1799.00, 201),
  ('Alma en Paz',                  'Reconecta con tu calma interior en profundidad',                 'Corporales', 60,  1222.00, 202),
  ('Welcome to the Oasis (x3)',    'Pack de 3 sesiones — bienvenida al spa',                         'Corporales', 60,  2999.00, 203),
  ('Welcome to the Oasis (x3)',    'Pack de 3 sesiones — bienvenida al spa',                         'Corporales', 90,  4299.00, 204),
  ('Metodología Sahara Ritual',    'Programa de 6 sesiones de transformación corporal',               'Corporales', 60,  5499.00, 205),
  ('Relajación Personalizada',     'Sesión a medida diseñada según tus necesidades',                 'Corporales', 60,  0.00,    206);

-- ── FACIALES ─────────────────────────────────────────────────────────────────
INSERT INTO public.services (name, description, category, duration_min, price, display_order) VALUES
  ('Sahara Soul Facial',            'Facial de reinicio profundo para tu piel',                      'Faciales', 90,  1190.00, 300),
  ('Sahara Soul Deluxe',            'Versión premium del facial Sahara Soul con extras',             'Faciales', 90,  1450.00, 301),
  ('Sahara Soul Glowy',             'Facial de luminosidad intensa con efecto glow',                 'Faciales', 120, 1799.00, 302),
  ('Sahara Lum',                    'Iluminación y uniformización del tono de la piel',              'Faciales', 90,  1550.00, 303),
  ('Baño de Luz',                   'Tratamiento express de luminosidad y frescura',                 'Faciales', 60,  888.00,  304),
  ('Linfa en Movimiento Facial',    'Drenaje linfático específico para el rostro',                   'Faciales', 30,  699.00,  305),
  ('Neuro Yoga Facial',             'Técnicas neuro-musculares para el rejuvenecimiento facial',     'Faciales', 60,  999.00,  306),
  ('Neuro Sculpt Yoga Facial',      'Escultura facial con técnica neuro-muscular avanzada',          'Faciales', 90,  1299.00, 307),
  ('Pre & Post operatorio facial',  'Cuidado especializado antes y después de cirugía facial',       'Faciales', 60,  999.00,  308);

-- ── TECNOLOGÍA FACIAL ─────────────────────────────────────────────────────────
INSERT INTO public.services (name, description, category, duration_min, price, display_order) VALUES
  ('Radiofrecuencia',               'Reafirmación y lifting facial no invasivo',                     'Tecnología Facial', 45, 999.00, 400),
  ('Ultrasonido',                   'Penetración profunda de activos cosméticos',                    'Tecnología Facial', 45, 999.00, 401),
  ('Fotorejuvenecimiento',          'Renovación celular con luz intensa pulsada (IPL)',               'Tecnología Facial', 30, 950.00, 402),
  ('Máscara LED',                   'Cromoterapia facial con tecnología de luz LED',                  'Tecnología Facial', 30, 555.00, 403);

-- ── EXPERIENCIAS FACIALES PREMIUM ────────────────────────────────────────────
INSERT INTO public.services (name, description, category, duration_min, price, display_order) VALUES
  ('The Facial Experience',         'Experiencia facial completa e inmersiva',                       'Faciales Premium', 150, 2599.00, 500),
  ('Metodología Sahara Facial',     'Programa de 4 sesiones de transformación facial',               'Faciales Premium', 60,  4850.00, 501),
  ('Glow Personalizado',            'Tratamiento facial a medida diseñado para tu piel',             'Faciales Premium', 60,  0.00,    502);

-- ── MOLDEO CONSCIENTE ────────────────────────────────────────────────────────
INSERT INTO public.services (name, description, category, duration_min, price, display_order) VALUES
  ('Transformación Total',          '1 sesión de moldeo corporal consciente',                        'Moldeo Consciente', 90, 1500.00,  600),
  ('Transformación Total x4',       'Paquete de 4 sesiones de moldeo corporal',                     'Moldeo Consciente', 90, 5700.00,  601),
  ('Transformación Total x8',       'Paquete de 8 sesiones de moldeo corporal',                     'Moldeo Consciente', 90, 11400.00, 602),
  ('Transformación Total x12',      'Paquete de 12 sesiones de moldeo corporal',                    'Moldeo Consciente', 90, 17100.00, 603),
  ('Transformación Total x16',      'Paquete de 16 sesiones de moldeo corporal',                    'Moldeo Consciente', 90, 22800.00, 604),
  ('Transformación Total x20',      'Paquete de 20 sesiones de moldeo corporal',                    'Moldeo Consciente', 90, 27000.00, 605),
  ('Pre & Post operatorio corporal','1 sesión de recuperación corporal especializada',               'Moldeo Consciente', 60, 999.00,   606),
  ('Pre & Post operatorio x5',      'Paquete de 5 sesiones de recuperación corporal',               'Moldeo Consciente', 60, 4450.00,  607),
  ('Pre & Post operatorio x10',     'Paquete de 10 sesiones de recuperación corporal',              'Moldeo Consciente', 60, 8999.00,  608),
  ('Metodología Corporal',          'Programa corporal personalizado a tu medida',                  'Moldeo Consciente', 60, 0.00,     609);

-- ── TECNOLOGÍA CORPORAL ───────────────────────────────────────────────────────
INSERT INTO public.services (name, description, category, duration_min, price, display_order) VALUES
  ('Lipoláser',                     'Reducción localizada no invasiva con láser frío',               'Tecnología Corporal', 50, 850.00,  700),
  ('Cavitación',                    'Ultrasonido de alta frecuencia para reducción de grasa',        'Tecnología Corporal', 50, 899.00,  701),
  ('Ultrasonido Corporal',          'Penetración profunda de activos en zonas corporales',           'Tecnología Corporal', 50, 899.00,  702),
  ('Radiofrecuencia Corporal',      'Reafirmación y tonificación corporal no invasiva',              'Tecnología Corporal', 50, 999.00,  703),
  ('Body Sculpt',                   'Escultura corporal con tecnología de última generación',        'Tecnología Corporal', 50, 1299.00, 704),
  ('Maderoterapia',                 'Moldeo corporal y drenaje con técnica de madera terapéutica',  'Tecnología Corporal', 60, 999.00,  705);

-- ── EXPERIENCIAS FUSIONADAS ───────────────────────────────────────────────────
INSERT INTO public.services (name, description, category, duration_min, price, display_order) VALUES
  ('Sahara Day Spa',                'Día completo de experiencias spa de lujo',                      'Fusionadas', 150, 2080.00, 800),
  ('Luz en Movimiento',             'Experiencia fusionada de luz, energía y movimiento',            'Fusionadas', 90,  1499.00, 801),
  ('Calma para el Alma',            'Ritual profundo de calma, alivio y renovación total',           'Fusionadas', 120, 2099.00, 802),
  ('Liberación de Raíz',            'Liberación energética desde la raíz del cuerpo',                'Fusionadas', 120, 2250.00, 803),
  ('Volver a Mí',                   'Retiro express de reconexión personal profunda',                'Fusionadas', 180, 3999.00, 804),
  ('Glow & Flow',                   'Brillo y fluidez — experiencia sensorial total',                'Fusionadas', 150, 2499.00, 805),
  ('Feel in Love',                  'Experiencia romántica para parejas',                            'Fusionadas', 60,  2399.00, 806),
  ('Feel in Love',                  'Experiencia romántica para parejas',                            'Fusionadas', 90,  3499.00, 807),
  ('Bride to Be',                   'Ritual especial y exclusivo para la novia',                     'Fusionadas', 120, 1999.00, 808),
  ('Squad of the Bride',            'Experiencia grupal para el squad de la novia',                  'Fusionadas', 120, 0.00,    809),
  ('Vuelta al Sol',                 'Ritual de renovación y energía solar profunda',                 'Fusionadas', 150, 2499.00, 810),
  ('Share Love',                    'Comparte bienestar con quien más quieres',                      'Fusionadas', 60,  0.00,    811);

-- ── COLABORACIONES ────────────────────────────────────────────────────────────
INSERT INTO public.services (name, description, category, duration_min, price, display_order) VALUES
  ('Mind & Body Reset',             'Con Soulab — reset mental y corporal completo',                 'Colaboraciones', 120, 1799.00, 900),
  ('RE-NACER',                      'Soulab + Sahara + Motus — experiencia de renacimiento total',   'Colaboraciones', 180, 2599.00, 901);

-- ── SAHARA HOUSE ──────────────────────────────────────────────────────────────
INSERT INTO public.services (name, description, category, duration_min, price, display_order) VALUES
  ('Sahara House',                  'Hospedaje para 1-10 personas con experiencias spa incluidas',   'Sahara House', 480, 0.00, 1000);
