import 'spa_service.dart';

final List<SpaService> allServices = [
  // ─── MASAJES ───────────────────────────────────────────────────────────────
  SpaService(
    id: 'sahara-soul-masaje',
    name: 'Sahara Soul',
    tagline: 'El masaje de la casa.',
    description:
        'El ritual que abrió la puerta entre cuerpo y alma. Un masaje de pies a cabeza diseñado para llevar al cuerpo a un estado de descanso real. A través de maniobras envolventes, respiración consciente y un ritmo terapéutico profundo, aquí el cuerpo aprende a soltar. Ideal para quien necesita pausar, regular y volver a habitarse.',
    category: ServiceCategory.masajes,
    durations: [
      ServiceDuration(minutes: 60, price: 1089),
      ServiceDuration(minutes: 90, price: 1590),
      ServiceDuration(minutes: 120, price: 1970),
    ],
  ),
  SpaService(
    id: 'amazing-experience',
    name: 'Amazing Experience',
    tagline: 'Un método propio. Un encuentro completo con el cuerpo.',
    description:
        'Creado por Jochebed. Aquí se le escucha, se le abraza y se le devuelve calma. Cada toque tiene un propósito: recordarle que ya no tiene que sostener nada. Un masaje que recorre todo el cuerpo con presencia, cuidado y sentido. En este espacio, el cuerpo entiende que todo está bien.',
    category: ServiceCategory.masajes,
    durations: [
      ServiceDuration(minutes: 90, price: 1777),
    ],
  ),
  SpaService(
    id: 'magia-de-sentir',
    name: 'La Magia de Sentir',
    tagline: 'Cuando el cuerpo habla, la terapeuta escucha.',
    description:
        'Este masaje nace de la capacidad desarrollada en Sahara Club de palpar el cuerpo y leer la emoción. La terapeuta siente, escucha y responde a lo que el cuerpo necesita en ese momento. No sigue una secuencia fija: sigue la sabiduría corporal del paciente. Ideal para dolores localizados, sobrecargas emocionales o momentos de transición.',
    category: ServiceCategory.masajes,
    durations: [
      ServiceDuration(minutes: 30, price: 555),
      ServiceDuration(minutes: 60, price: 1111),
      ServiceDuration(minutes: 90, price: 1680),
    ],
  ),
  SpaService(
    id: 'caricia-corazon',
    name: 'Caricia al Corazón',
    tagline: 'El masaje que abre la puerta emocional.',
    description:
        'Un ritual profundo enfocado en pectorales, brazos, manos y cuello. Estimula ganglios linfáticos, libera el pecho, activa y relaja el timo, centro inmunológico y emocional. Este masaje toca fibras más allá del músculo. Muchas personas liberan emociones sin saber por qué. Es un espacio para sentir, soltar y permitir.',
    category: ServiceCategory.masajes,
    durations: [
      ServiceDuration(minutes: 60, price: 950),
    ],
  ),
  SpaService(
    id: 'raices-de-calma',
    name: 'Raíces de Calma',
    tagline: 'Cuando descansas las extremidades, descansa el sistema nervioso.',
    description:
        'Brazos, manos, piernas y pies concentran terminaciones nerviosas y carga emocional. Este masaje profundo libera tensión acumulada, mejora la circulación y devuelve sensación de ligereza y presencia. Ideal para personas con estrés mental, sobrecarga laboral o cansancio crónico.',
    category: ServiceCategory.masajes,
    durations: [
      ServiceDuration(minutes: 60, price: 950),
    ],
  ),
  SpaService(
    id: 'ritual-craneo-facial',
    name: 'Ritual Cráneo Facial',
    tagline: 'Liberar la mente, creando espacio interno.',
    description:
        'Un masaje enfocado en cráneo, rostro y cuello que libera tensiones profundas del sistema nervioso central. Al relajar la musculatura superior y las fascias craneales, se crea un efecto de vacío mental, claridad y descanso profundo. Ideal para quienes viven con la mente acelerada.',
    category: ServiceCategory.masajes,
    durations: [
      ServiceDuration(minutes: 60, price: 950),
    ],
  ),
  SpaService(
    id: 'descarga-consciente',
    name: 'Descarga Consciente',
    tagline: 'Fuerza con presencia. Profundidad con cuidado.',
    description:
        'Para cuerpos que necesitan ir más profundo. Un masaje intenso, firme y sostenido, con ventosas y trabajo corporal consciente. No es suave. Es preciso. El cuerpo se siente más liviano.',
    category: ServiceCategory.masajes,
    durations: [
      ServiceDuration(minutes: 60, price: 1265),
      ServiceDuration(minutes: 90, price: 1777),
    ],
  ),
  SpaService(
    id: 'linfa-movimiento-masaje',
    name: 'Linfa en Movimiento',
    tagline: 'Drenar para sanar. Mover para vivir.',
    description:
        'Un drenaje linfático consciente que activa ganglios, estimula el sistema inmune y apoya procesos de depuración física y emocional. A través de movimientos rítmicos y respiración guiada, el cuerpo entra en un estado de ligereza, desinflamación y renovación interna.',
    category: ServiceCategory.masajes,
    durations: [
      ServiceDuration(minutes: 60, price: 999),
    ],
  ),
  SpaService(
    id: 'calor-que-abraza',
    name: 'Calor que Abraza',
    tagline: 'El poder del calor consciente.',
    description:
        'A través de piedras calientes y movimientos circulares, el calor penetra el tejido muscular, relaja profundamente y mejora la circulación. El cuerpo se rinde. La mente se apaga. Ideal para tensiones profundas y necesidad de contención.',
    category: ServiceCategory.masajes,
    durations: [
      ServiceDuration(minutes: 60, price: 1380),
      ServiceDuration(minutes: 90, price: 1999),
    ],
  ),
  SpaService(
    id: 'creando-vida',
    name: 'Creando Vida',
    tagline: 'Sostener a quien sostiene vida.',
    description:
        'Masaje prenatal. Un masaje amoroso y seguro para mamás embarazadas. Enfocado en espalda baja, caderas, brazos y drenaje de piernas. Ayuda a liberar tensión, mejorar la circulación y crear un espacio de descanso y conexión profunda con el cuerpo y el bebé.',
    category: ServiceCategory.masajes,
    durations: [
      ServiceDuration(minutes: 60, price: 999),
    ],
  ),

  // ─── EXPERIENCIAS CORPORALES COMBINADAS ───────────────────────────────────
  SpaService(
    id: 'descanso-sagrado',
    name: 'Descanso Sagrado',
    tagline: 'Drenar primero. Descansar después.',
    description:
        'Una combinación de Linfa en Movimiento y Sahara Soul. Primero activamos el sistema linfático; después llevamos al cuerpo a un descanso profundo. El resultado: sensación de limpieza interna, ligereza y paz sostenida.',
    category: ServiceCategory.experienciasCorporales,
    durations: [
      ServiceDuration(minutes: 90, price: 1499),
      ServiceDuration(minutes: 120, price: 1799),
    ],
  ),
  SpaService(
    id: 'alma-en-paz',
    name: 'Alma en Paz',
    tagline: 'Cuando el calor y la calma se encuentran.',
    description:
        'Una experiencia que combina Sahara Soul con piedras calientes. Relajación profunda, contención emocional y una sensación de paz que permanece más allá de la sesión. Un regalo para el cuerpo… y para el alma.',
    category: ServiceCategory.experienciasCorporales,
    durations: [
      ServiceDuration(minutes: 60, price: 1222),
    ],
  ),
  SpaService(
    id: 'welcome-oasis',
    name: 'Welcome to the Oasis',
    tagline: 'La bienvenida a un cuerpo relajado.',
    description:
        'Un paquete de tres masajes diseñados para acompañar al cuerpo en su proceso natural de liberación y descanso. Cada sesión cada tres semanas o cada mes. Primer masaje: profundo y liberador. Segundo: más fluido y placentero. Tercero: descanso total. Ideal para quienes llegan por primera vez a Sahara Club.',
    category: ServiceCategory.experienciasCorporales,
    durations: [
      ServiceDuration(minutes: 60, price: 2999),
      ServiceDuration(minutes: 90, price: 4299),
    ],
  ),
  SpaService(
    id: 'metodologia-sahara-corporal',
    name: 'Metodología Sahara · Ritual de Relajación Profunda',
    tagline: 'Una experiencia. Cinco momentos. Un antes y un después.',
    description:
        'La metodología insignia de Sahara Club. Un ritual de 6 sesiones: Caricia al Corazón (60min) → Amazing Experience (90min) → Ritual Cráneo Facial (60min) → Raíces de Calma (60min) → Alma en Paz (60min) → Tu masaje favorito (60min). No es una suma de tratamientos. Es una metodología que transforma la forma en la que habitas tu cuerpo.',
    category: ServiceCategory.experienciasCorporales,
    durations: [
      ServiceDuration(minutes: 0, price: 5499),
    ],
  ),
  SpaService(
    id: 'relajacion-personalizada',
    name: 'Relajación Personalizada',
    tagline: 'Tu cuerpo. Tu ritmo. Tu experiencia.',
    description:
        'Un acompañamiento diseñado completamente a tu medida. Elegimos juntos los masajes, la frecuencia y el tiempo, respetando lo que tu cuerpo necesita. En Sahara Club, no hay una sola forma correcta.',
    category: ServiceCategory.experienciasCorporales,
    priceOnQuote: true,
  ),

  // ─── FACIALES ──────────────────────────────────────────────────────────────
  SpaService(
    id: 'sahara-soul-facial',
    name: 'Sahara Soul',
    tagline: 'El facial de la casa.',
    description:
        'Regreso a la piel · Limpieza consciente. Ritual de limpieza profunda que devuelve a la piel su equilibrio natural. Incluye mascarillas de autor Sahara elaboradas con algas y activos 100% naturales, libres de químicos y disruptores hormonales. Cada sesión se adapta a lo que tu piel necesita hoy.',
    category: ServiceCategory.faciales,
    durations: [
      ServiceDuration(minutes: 90, price: 1190),
    ],
  ),
  SpaService(
    id: 'sahara-soul-deluxe',
    name: 'Sahara Soul Deluxe',
    tagline: 'Limpieza profunda + tecnología consciente.',
    description:
        'Parte de la base del Sahara Soul y se eleva integrando tecnología estética seleccionada con intención. Incluye: limpieza profunda, mascarilla personalizada, ultrasonido y/o radiofrecuencia. La piel se siente limpia, firme, luminosa y profundamente cuidada.',
    category: ServiceCategory.faciales,
    durations: [
      ServiceDuration(minutes: 105, price: 1450),
    ],
  ),
  SpaService(
    id: 'sahara-soul-glowy',
    name: 'Sahara Soul Glowy',
    tagline: 'Glow total · Piel renovada.',
    description:
        'Facial mega completo que combina: limpieza profunda con tecnología hydrafacial, ultrasonido, radiofrecuencia, máscara LED, rodillo frío y mascarilla Sahara. Diseñado para renovar, hidratar, oxigenar y dar luminosidad inmediata. Ideal para eventos o cambios de estación.',
    category: ServiceCategory.faciales,
    durations: [
      ServiceDuration(minutes: 120, price: 1799),
    ],
  ),
  SpaService(
    id: 'sahara-lum',
    name: 'Sahara Lum',
    tagline: 'Iluminar, unificar, revitalizar.',
    description:
        'Facial enfocado en piel apagada, manchitas leves y tono disparejo. Incluye limpieza ligera y trabajo con luz y fotorejuvenecimiento. No profundiza en extracción. Su intención es iluminar y dar frescura al rostro.',
    category: ServiceCategory.faciales,
    durations: [
      ServiceDuration(minutes: 90, price: 1550),
    ],
  ),
  SpaService(
    id: 'bano-de-luz',
    name: 'Baño de Luz',
    tagline: 'La piel también se alimenta de luz.',
    description:
        'Facial donde la protagonista es la energía lumínica. La piel recibe un baño de diferentes frecuencias de luz que estimulan regeneración, equilibrio y calma. Se complementa con mascarilla personalizada. Ideal para pieles estresadas, sensibles o desvitalizadas.',
    category: ServiceCategory.faciales,
    durations: [
      ServiceDuration(minutes: 60, price: 888),
    ],
  ),
  SpaService(
    id: 'linfa-movimiento-facial',
    name: 'Linfa en Movimiento Facial',
    tagline: 'Drenar, desinflamar, revitalizar.',
    description:
        'Drenaje linfático facial consciente que activa ganglios, mejora circulación y reduce inflamación. Aporta ligereza al rostro, mejora el contorno y oxigena tejidos. Ideal para bolsas, retención de líquidos y rostro inflamado.',
    category: ServiceCategory.faciales,
    durations: [
      ServiceDuration(minutes: 30, price: 699),
    ],
  ),
  SpaService(
    id: 'neuro-yoga-facial',
    name: 'Neuro Yoga Facial',
    tagline: 'Liberar el rostro también libera la mente.',
    description:
        'Protocolo de movimientos suaves, respiración guiada y presencia corporal para liberar tensión facial asociada a emociones y creencias. Trabajamos rostro completo con enfoque en ojos, mandíbula y frente. Impacto interno y externo.',
    category: ServiceCategory.faciales,
    durations: [
      ServiceDuration(minutes: 60, price: 999),
    ],
  ),
  SpaService(
    id: 'neuro-sculpt-yoga-facial',
    name: 'Neuro Sculpt Yoga Facial',
    tagline: 'Conciencia + firmeza.',
    description:
        'Integra Neuro Yoga Facial con electroestimulación y ultrasonido o radiofrecuencia. Primero soltamos la tensión. Después esculpimos. Ideal para quien busca relajación profunda y mayor firmeza sin perder naturalidad.',
    category: ServiceCategory.faciales,
    durations: [
      ServiceDuration(minutes: 90, price: 1299),
    ],
  ),
  SpaService(
    id: 'pre-post-operatorio-facial',
    name: 'Pre & Post Operatorio Facial',
    tagline: 'Acompañamiento terapéutico.',
    description:
        'Trabajo enfocado en fascia, linfa y circulación para apoyar procesos de recuperación antes y después de procedimientos estéticos. Ayuda a desinflamar, drenar y acelerar procesos de regeneración.',
    category: ServiceCategory.faciales,
    durations: [
      ServiceDuration(minutes: 60, price: 999),
    ],
  ),

  // ─── TECNOLOGÍA FACIAL ─────────────────────────────────────────────────────
  SpaService(
    id: 'radiofrecuencia-facial',
    name: 'Radiofrecuencia',
    tagline: 'Estimula colágeno y firmeza.',
    description: 'Aplicación individual de radiofrecuencia facial que estimula la producción de colágeno y mejora la firmeza de la piel.',
    category: ServiceCategory.tecnologiaFacial,
    durations: [ServiceDuration(minutes: 45, price: 999)],
  ),
  SpaService(
    id: 'ultrasonido-facial',
    name: 'Ultrasonido Facial',
    tagline: 'Apoya procesos de reafirmación.',
    description: 'Aplicación individual de ultrasonido facial para apoyar procesos de reafirmación de la piel.',
    category: ServiceCategory.tecnologiaFacial,
    durations: [ServiceDuration(minutes: 45, price: 999)],
  ),
  SpaService(
    id: 'fotorejuvenecimiento',
    name: 'Fotorejuvenecimiento',
    tagline: 'Mejora tono y textura.',
    description: 'Aplicación de fotorejuvenecimiento en facial y escote. Mejora el tono y la textura de la piel.',
    category: ServiceCategory.tecnologiaFacial,
    durations: [ServiceDuration(minutes: 30, price: 950)],
  ),
  SpaService(
    id: 'mascara-led',
    name: 'Máscara LED',
    tagline: 'Regeneración y calma.',
    description: 'Aplicación individual de máscara LED para estimular la regeneración celular y calmar la piel.',
    category: ServiceCategory.tecnologiaFacial,
    durations: [ServiceDuration(minutes: 30, price: 555)],
  ),

  // ─── EXPERIENCIAS FACIALES COMBINADAS (como parte de metodología facial) ──
  SpaService(
    id: 'the-facial-experience',
    name: 'The Facial Experience',
    tagline: 'La experiencia facial más completa de Sahara.',
    description:
        'Liberar · Activar · Regenerar. Un ritual que integra Neuro Yoga Facial con Sahara Soul Deluxe. Primero liberamos tensión muscular y emocional del rostro. Después aplicamos tecnología, activos y luz para potenciar al máximo la absorción y los resultados.',
    category: ServiceCategory.tecnologiaFacial,
    durations: [ServiceDuration(minutes: 165, price: 2599)],
  ),
  SpaService(
    id: 'metodologia-sahara-facial',
    name: 'Metodología Sahara Facial',
    tagline: 'Experiencia signature de cuidado continuo.',
    description:
        'No es un solo facial. Es un método de cuidado progresivo, una vez al mes por 4 meses. Incluye: Neuro Yoga Facial, Sahara Soul Deluxe, Sahara Glowy y Neuro Yoga Sculpt. Se acompaña con guía para casa.',
    category: ServiceCategory.tecnologiaFacial,
    durations: [ServiceDuration(minutes: 0, price: 4850)],
  ),
  SpaService(
    id: 'glow-personalizado',
    name: 'Glow Personalizado',
    tagline: 'Tu piel · Tu necesidad · Tu ritual.',
    description:
        'Una experiencia facial diseñada completamente a tu medida. Después de una breve evaluación, integramos los faciales y tecnologías que mejor respondan a tu piel en ese momento.',
    category: ServiceCategory.tecnologiaFacial,
    priceOnQuote: true,
  ),

  // ─── MOLDEO CONSCIENTE ─────────────────────────────────────────────────────
  SpaService(
    id: 'transformacion-total',
    name: 'Transformación Total',
    tagline: 'Drenar · Activar · Reorganizar · Moldear con amor.',
    description:
        'Cada sesión integra tecnología estética + trabajo manual + respiración consciente. Combina: drenaje linfático consciente, maderoterapia corporal, 30 min de aparatología localizada y respiración guiada. No busca "quitar". Busca enseñarle al cuerpo a reorganizarse.',
    category: ServiceCategory.moldeoConsciente,
    packages: [
      SessionPackage(sessions: 1, price: 1500),
      SessionPackage(sessions: 4, price: 5700),
      SessionPackage(sessions: 8, price: 11400),
      SessionPackage(sessions: 12, price: 17100),
      SessionPackage(sessions: 16, price: 22800),
      SessionPackage(sessions: 20, price: 27000),
    ],
  ),
  SpaService(
    id: 'pre-post-operatorio-corporal',
    name: 'Pre & Post Operatorio Corporal',
    tagline: 'Acompañamiento terapéutico.',
    description:
        'Trabajo enfocado en fascia, linfa y circulación para apoyar procesos antes y después de procedimientos estéticos. Ayuda a desinflamar, drenar, disminuir molestias y acelerar recuperación.',
    category: ServiceCategory.moldeoConsciente,
    packages: [
      SessionPackage(sessions: 1, price: 999),
      SessionPackage(sessions: 5, price: 4450),
      SessionPackage(sessions: 10, price: 8999),
    ],
  ),
  SpaService(
    id: 'metodologia-corporal-personalizada',
    name: 'Metodología Corporal Personalizada',
    tagline: 'Protocolo a tu medida.',
    description:
        'Después de una evaluación, diseñamos un protocolo corporal personalizado integrando: trabajo manual, tecnologías, respiración consciente y frecuencia ideal.',
    category: ServiceCategory.moldeoConsciente,
    priceOnQuote: true,
  ),

  // ─── TECNOLOGÍA CORPORAL ───────────────────────────────────────────────────
  SpaService(
    id: 'lipolaser',
    name: 'Lipoláser',
    tagline: 'Estimulación localizada.',
    description: 'Apoya la movilización de grasa localizada de forma no invasiva. Ideal para zonas específicas donde se busca apoyar procesos de moldeo.',
    category: ServiceCategory.tecnologiaCorporal,
    durations: [ServiceDuration(minutes: 50, price: 850)],
  ),
  SpaService(
    id: 'cavitacion',
    name: 'Cavitación',
    tagline: 'Movilización de tejido.',
    description: 'Tecnología que apoya la descomposición de grasa localizada y mejora textura de la piel.',
    category: ServiceCategory.tecnologiaCorporal,
    durations: [ServiceDuration(minutes: 50, price: 899)],
  ),
  SpaService(
    id: 'ultrasonido-corporal',
    name: 'Ultrasonido Corporal',
    tagline: 'Reafirmación y moldeo.',
    description: 'Apoya procesos de firmeza y reorganización del tejido.',
    category: ServiceCategory.tecnologiaCorporal,
    durations: [ServiceDuration(minutes: 50, price: 899)],
  ),
  SpaService(
    id: 'radiofrecuencia-corporal',
    name: 'Radiofrecuencia Corporal',
    tagline: 'Firmeza y elasticidad.',
    description: 'Estimula producción de colágeno, mejora tono y calidad de piel.',
    category: ServiceCategory.tecnologiaCorporal,
    durations: [ServiceDuration(minutes: 50, price: 999)],
  ),
  SpaService(
    id: 'body-sculpt',
    name: 'Body Sculpt',
    tagline: 'Estimulación muscular.',
    description: 'Electroestimulación que activa músculo, tonifica y fortalece.',
    category: ServiceCategory.tecnologiaCorporal,
    durations: [ServiceDuration(minutes: 50, price: 1299)],
  ),
  SpaService(
    id: 'maderoterapia',
    name: 'Maderoterapia',
    tagline: 'Técnica manual de origen ancestral.',
    description:
        'Utiliza instrumentos de madera diseñados para activar circulación, movilizar tejido adiposo y favorecer el drenaje linfático.',
    category: ServiceCategory.tecnologiaCorporal,
    durations: [ServiceDuration(minutes: 60, price: 999)],
  ),

  // ─── EXPERIENCIAS FUSIONADAS ───────────────────────────────────────────────
  SpaService(
    id: 'sahara-day-spa',
    name: 'Sahara Day Spa',
    tagline: 'Rostro y cuerpo en equilibrio.',
    description:
        'Una experiencia que combina Sahara Soul Masaje y Sahara Soul Facial. Relaja el cuerpo, limpia la piel y devuelve sensación de balance general. Ideal para una pausa consciente o como primera experiencia Sahara.',
    category: ServiceCategory.experienciasFusionadas,
    durations: [ServiceDuration(minutes: 150, price: 2080)],
  ),
  SpaService(
    id: 'luz-en-movimiento',
    name: 'Luz en Movimiento',
    tagline: 'Drenar · Regenerar · Iluminar.',
    description:
        'Combina Linfa en Movimiento Corporal con Baño de Luz Facial. Apoya la desinflamación, activa la circulación y estimula la regeneración celular. El cuerpo se siente ligero. El rostro se ve luminoso.',
    category: ServiceCategory.experienciasFusionadas,
    durations: [ServiceDuration(minutes: 90, price: 1499)],
  ),
  SpaService(
    id: 'calma-para-el-alma',
    name: 'Calma para el Alma',
    tagline: 'Soltar · Sentir · Suavizar.',
    description:
        'Integra Raíces de Calma, Caricia al Corazón y Neuro Yoga Facial. Libera tensión de extremidades, abre el pecho y suaviza el rostro. Ideal para estrés emocional, sensibilidad y necesidad de contención.',
    category: ServiceCategory.experienciasFusionadas,
    durations: [ServiceDuration(minutes: 120, price: 2099)],
  ),
  SpaService(
    id: 'liberacion-de-raiz',
    name: 'Liberación de Raíz',
    tagline: 'Fuerza consciente.',
    description:
        'Combina Descarga Consciente, ventosas y maderoterapia para activar circulación y liberar capas profundas de tensión. Ideal para cuerpos cargados, rigidez muscular o sensación de estancamiento.',
    category: ServiceCategory.experienciasFusionadas,
    durations: [ServiceDuration(minutes: 120, price: 2250)],
  ),
  SpaService(
    id: 'volver-a-mi',
    name: 'Volver a Mí',
    tagline: 'Descanso profundo + iluminación.',
    description:
        'Integra Calor que Abraza, Baño de Luz Roja Corporal y Sahara Glowy. Lleva al cuerpo a un estado profundo de relajación y al rostro la luminosidad total. Ideal cuando necesitas regresar a ti.',
    category: ServiceCategory.experienciasFusionadas,
    durations: [ServiceDuration(minutes: 180, price: 3999)],
  ),
  SpaService(
    id: 'glow-and-flow',
    name: 'Glow & Flow',
    tagline: 'Cuerpo ligero · Rostro relajado · Luz total.',
    description:
        'Diseñada para antes de un evento. Integra Transformación Total (drenaje + maderoterapia + aparatología) + Neuro Yoga Facial + Baño de Luz Facial. Cuerpo más ligero. Rostro relajado. Piel luminosa.',
    category: ServiceCategory.experienciasFusionadas,
    durations: [ServiceDuration(minutes: 150, price: 2499)],
  ),
  SpaService(
    id: 'feel-in-love',
    name: 'Feel In Love',
    tagline: 'Experiencia en pareja.',
    description:
        'Masaje en pareja Sahara Soul, masaje cráneo facial, incluye copa de vino y chocolates. Un espacio para conectar, relajarse y compartir.',
    category: ServiceCategory.experienciasFusionadas,
    durations: [
      ServiceDuration(minutes: 60, price: 2399),
      ServiceDuration(minutes: 90, price: 3499),
    ],
  ),
  SpaService(
    id: 'bride-to-be',
    name: 'Bride to Be',
    tagline: 'Antes del sí.',
    description:
        'Combina Sahara Soul Masaje, Linfa en Movimiento y Neuro Yoga Facial. Deja el cuerpo ligero y el rostro relajado y luminoso. Ideal para futuras novias.',
    category: ServiceCategory.experienciasFusionadas,
    durations: [ServiceDuration(minutes: 120, price: 1999)],
  ),
  SpaService(
    id: 'squad-of-the-bride',
    name: 'Squad of the Bride',
    tagline: 'Celebración privada.',
    description:
        'Experiencia diseñada a la medida para grupos de 4 hasta 16 personas. Opción de cerrar el spa para el grupo.',
    category: ServiceCategory.experienciasFusionadas,
    priceOnQuote: true,
  ),
  SpaService(
    id: 'vuelta-al-sol',
    name: 'Vuelta al Sol',
    tagline: 'Cumpleaños consciente · 1 persona.',
    description:
        'Incluye Sahara Soul Masaje, Neuro Yoga Facial, Mascarilla Sahara y meditación guiada para iniciar un nuevo año.',
    category: ServiceCategory.experienciasFusionadas,
    durations: [ServiceDuration(minutes: 150, price: 2499)],
  ),
  SpaService(
    id: 'share-love',
    name: 'Share Love',
    tagline: 'Celebrar la amistad.',
    description:
        'Una experiencia para venir con amigas o amigos a celebrar el arte de existir y apapacharse. Se diseña a la medida combinando masajes y faciales.',
    category: ServiceCategory.experienciasFusionadas,
    priceOnQuote: true,
  ),
  SpaService(
    id: 'mind-body-reset',
    name: 'Mind & Body Reset',
    tagline: 'Respirar · Sentir · Descansar.',
    description:
        'La experiencia inicia en Soulab con respiración consciente y meditación guiada. Continúa en Sahara Club con Sahara Soul Masaje. Diseñado para regular el sistema nervioso, soltar carga mental y llevar al cuerpo a descanso profundo.',
    category: ServiceCategory.experienciasFusionadas,
    durations: [ServiceDuration(minutes: 120, price: 1799)],
  ),
  SpaService(
    id: 're-nacer',
    name: 'RE-NACER',
    tagline: 'Respiración · Cuerpo · Recuperación.',
    description:
        'Tres fases: 1. Soulab – respiración consciente y meditación. 2. Sahara Club – masaje corporal. 3. Motus – sauna infrarrojo y tina de agua fría. Un reset que trabaja desde adentro hacia afuera.',
    category: ServiceCategory.experienciasFusionadas,
    durations: [ServiceDuration(minutes: 180, price: 2599)],
  ),

  // ─── SAHARA HOUSE ──────────────────────────────────────────────────────────
  SpaService(
    id: 'sahara-house',
    name: 'Sahara House',
    tagline: 'Hospedaje + experiencias de bienestar.',
    description:
        'Quédate con nosotros. Espacios de hospedaje para 1 hasta 10 personas. Ideales para escapadas de descanso, celebraciones conscientes, retiros personales y experiencias privadas. Combina tu estancia con masajes, faciales, rituales y experiencias Sahara.',
    category: ServiceCategory.saharaHouse,
    priceOnQuote: true,
  ),
];

List<SpaService> getServicesByCategory(ServiceCategory category) =>
    allServices.where((s) => s.category == category).toList();
