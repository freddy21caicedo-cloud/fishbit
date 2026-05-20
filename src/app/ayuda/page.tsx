'use client';

import { useState, useMemo, useEffect } from 'react';
import { motion, AnimatePresence } from 'framer-motion';
import { 
  BookOpen, 
  Search, 
  MessageCircle, 
  PlayCircle, 
  HelpCircle,
  ChevronRight,
  ChevronDown,
  Lightbulb,
  ShieldCheck,
  LifeBuoy,
  X,
  CheckCircle,
  AlertTriangle,
  Clock,
  Send,
  Loader2,
  Sparkles,
  Compass,
  ArrowRight,
  TrendingUp,
  Settings,
  Package,
  Layers,
  DollarSign
} from 'lucide-react';

// Categories definitions
const categories = [
  { id: 1, title: 'Dashboard y Vistas', icon: BookOpen, color: '#0d9488', bg: 'rgba(13, 148, 136, 0.05)', count: '3 Guías' },
  { id: 2, title: 'Registro de Datos', icon: PlayCircle, color: '#3b82f6', bg: 'rgba(59, 130, 246, 0.05)', count: '3 Guías' },
  { id: 3, title: 'Módulos Avanzados', icon: Lightbulb, color: '#f59e0b', bg: 'rgba(245, 158, 11, 0.05)', count: '3 Guías' },
  { id: 4, title: 'Ajustes y Seguridad', icon: ShieldCheck, color: '#8b5cf6', bg: 'rgba(139, 92, 246, 0.05)', count: '3 Guías' },
];

// Content blocks structure
interface ContentBlock {
  type: 'heading-3' | 'paragraph' | 'list' | 'alert';
  text?: string;
  items?: string[];
  alertType?: 'tip' | 'warning' | 'note';
  alertTitle?: string;
}

interface Article {
  id: string;
  categoryId: number;
  title: string;
  summary: string;
  blocks: ContentBlock[];
}

// Help articles dataset (Oriented strictly to how the app wo// Help articles dataset (Oriented strictly to how the app works)
const articles: Article[] = [
  {
    id: 'art-1',
    categoryId: 1,
    title: 'Guía de navegación del Dashboard',
    summary: 'Aprende a interpretar el mapa visual de estanques, las tarjetas interactivas de estadísticas y los controles del gráfico.',
    blocks: [
      { type: 'paragraph', text: 'El Dashboard principal de FishBit es el centro de control reactivo de tu finca, diseñado para darte visibilidad completa en tiempo real.' },
      { type: 'heading-3', text: '1. Mapa Operativo de Estanques (PondsGrid)' },
      { type: 'list', items: [
        'El panel muestra dinámicamente cada estanque de la tabla `estanques` que se encuentre en estado \'Con Peces\'.',
        'Cada tarjeta evalúa en tiempo real las últimas mediciones de la tabla `water_quality`. Su borde se colorea de acuerdo a su estado de salud: Verde (óptimo), Amarillo (parámetro en advertencia) o Rojo (alarma crítica).',
        'Interactividad de aislamiento: Al hacer clic en un estanque específico, el Dashboard filtra automáticamente los datos del TrendsChart y aísla los cálculos en el HarvestEstimator para ese estanque individual.'
      ]},
      { type: 'heading-3', text: '2. Tarjetas de Estadísticas Globales y Flip FCR' },
      { type: 'list', items: [
        'Los StatCards de la parte superior consolidan las columnas `current_biomass_kg`, `consumo_alimento_acumulado_kg`, `current_count` y existencias de bodega desde `inventory` y `estanques`.',
        'La tarjeta de Conversión Alimenticia (FCR) cuenta con una animación flip 3D premium. Al hacer clic sobre ella, gira 180° para revelar el desglose detallado del FCR calculado para cada estanque de forma individual, cruzando alimentación y biomasa.'
      ]},
      { type: 'heading-3', text: '3. Gráfico de Tendencias Cronológicas (TrendsChart)' },
      { type: 'list', items: [
        'Te permite analizar visualmente las tablas históricas de `water_quality`, `mortality`, `biometrias` y `alimentacion_diaria`.',
        'Filtro de Parámetros: Usa el selector superior para cambiar entre Oxígeno Disuelto, pH, Temperatura, Consumo, Mortalidad o Peso Promedio.',
        'Rango Temporal: Pestañas interactivas de 7D (últimos 7 días), 30D (últimos 30 días) o Ciclo (histórico completo del lote activo).'
      ]}
    ]
  },
  {
    id: 'art-2',
    categoryId: 1,
    title: 'Cómo cambiar entre Unidades Productivas',
    summary: 'Instrucciones para navegar entre múltiples fincas o concesiones asociadas a tu cuenta de FishBit.',
    blocks: [
      { type: 'paragraph', text: 'FishBit organiza la información de forma aislada y segura mediante el ID de la Unidad Productiva activa.' },
      { type: 'heading-3', text: 'Mecánica de Cambio de Finca:' },
      { type: 'list', items: [
        'Haz clic en el selector de Fincas ubicado en el menú lateral o en la esquina superior del Dashboard.',
        'Al seleccionar otra unidad, la aplicación almacena el ID de la finca seleccionada en la clave `active_unit_id` de tu almacenamiento local (`localStorage`).',
        'Inmediatamente, la aplicación refresca todas las consultas a Supabase, filtrando las tablas de `estanques`, `pond_species`, `inventory`, `unit_settings` y `transfers` con una cláusula `.eq(\'unit_id\', activeUnitId)` para asegurar un aislamiento completo.'
      ]},
      { type: 'alert', alertType: 'note', alertTitle: 'Ajustes e Identificadores', text: 'Cada finca posee su propio registro en la tabla `unit_settings` y `units`, lo que te permite manejar diferentes umbrales biológicos y límites de almacén por separado según la geolocalización o plan de la finca.' }
    ]
  },
  {
    id: 'art-3',
    categoryId: 1,
    title: 'Mapa Interactivo y Semáforo de Estanques',
    summary: 'Entiende cómo el semáforo inteligente de FishBit diagnostica la urgencia de tus estanques en tiempo real.',
    blocks: [
      { type: 'paragraph', text: 'La cuadrícula de estanques (PondsGrid) en el Dashboard central utiliza un sistema de semaforización automática que evalúa las últimas lecturas registradas.' },
      { type: 'heading-3', text: 'Fórmulas Matemáticas de Semaforización:' },
      { type: 'paragraph', text: 'El semáforo evalúa las últimas lecturas de la tabla `water_quality` contra los valores de la tabla `unit_settings` (columna JSONB `thresholds`) mediante la función `evaluateHealthState` aplicando los siguientes rangos de tolerancia:' },
      { type: 'list', items: [
        'Oxígeno Disuelto (mg/L): Estado Crítico (Rojo) si O₂ < `oxygenMin` o O₂ > `oxygenMax`. Estado Advertencia (Amarillo) si O₂ < `oxygenMin` + 0.5 o O₂ > `oxygenMax` - 0.5. Verde si es óptimo.',
        'Temperatura (°C): Estado Crítico (Rojo) si T < `tempMin` o T > `tempMax`. Estado Advertencia (Amarillo) si T < `tempMin` + 1.0 o T > `tempMax` - 1.0.',
        'Nivel de pH: Estado Crítico (Rojo) si pH < `phMin` o pH > `phMax`. Estado Advertencia (Amarillo) si pH < `phMin` + 0.3 o pH > `phMax` - 0.3.',
        'Mortalidad Excedida: Si el porcentaje acumulado de mortalidad en el lote supera el parámetro `mortalityMax`, la tarjeta se marcará automáticamente en color Rojo.'
      ]},
      { type: 'alert', alertType: 'warning', alertTitle: 'Peculiaridad de Filtros', text: 'Cuando seleccionas un estanque en el PondsGrid, toda la interfaz (gráficos, finanzas, biomasa) se aislará para ese estanque. Haz clic en "Ver Todo" en la esquina superior del grid para re-establecer la vista general de la finca.' }
    ]
  },
  {
    id: 'art-4',
    categoryId: 2,
    title: 'Cómo registrar Calidad del Agua y Biometrías',
    summary: 'Aprende a ingresar lecturas de sensores y reportes de muestreo de peso a la base de datos de la app.',
    blocks: [
      { type: 'paragraph', text: 'El registro oportuno de parámetros en FishBit garantiza que las alarmas del sistema y los cálculos metabólicos en los estanques sean correctos.' },
      { type: 'heading-3', text: '1. Calidad del Agua (Sensores)' },
      { type: 'list', items: [
        'Ve a la pestaña \'Registros\' y pulsa el botón \'Nueva Medición\'. Selecciona el estanque.',
        'Los parámetros de Oxígeno disuelto (mg/L), pH y Temperatura (°C) se guardan directamente en la tabla de Supabase `water_quality`.',
        'La aplicación también admite el registro de parámetros físico-químicos avanzados como `alkalinity`, `ammonia_mg_l`, `nitrite_mg_l` y `nitrate_mg_l` para control biológico profundo.'
      ]},
      { type: 'heading-3', text: '2. Muestreos de Peso (Biometrías)' },
      { type: 'list', items: [
        'Accede a la pestaña \'Biometrías\', selecciona el estanque sembrado y registra el peso promedio de la muestra en gramos.',
        'La app inserta un nuevo registro en la tabla `biometrias`. Inmediatamente, ejecuta un trigger que actualiza el valor de `current_biomass_kg` en la tabla `estanques` y `pond_species`, calculándolo como: `(current_count * peso_promedio_gramos) / 1000`.'
      ]},
      { type: 'alert', alertType: 'tip', alertTitle: 'Consejo de Muestreo', text: 'Registra biometrías cada 14 días para que el estimador de cosecha cuente con un peso base real y proyecte con un margen de error menor al 3%.' }
    ]
  },
  {
    id: 'art-5',
    categoryId: 2,
    title: 'Registro de Alimentación, Mortalidad y Traslados',
    summary: 'Flujo digital para descontar existencias de pienso en almacén, registrar bajas y gestionar el traslado de biomasas.',
    blocks: [
      { type: 'paragraph', text: 'Esta sección te enseña a documentar los eventos cotidianos de alimentación, bajas de población y movimientos de biomasa interna.' },
      { type: 'heading-3', text: '1. Raciones de Alimento Diario' },
      { type: 'list', items: [
        'En la pestaña \'Alimentación\', selecciona el estanque, introduce los kilogramos suministrados y el tipo de pienso.',
        'La app inserta el registro en la tabla `alimentacion_diaria`. A nivel de inventario, debita automáticamente esa cantidad exacta de la columna `current_stock` en la tabla `inventory` para el producto concentrado seleccionado.',
        'También acumula de forma automática el peso en la columna `consumo_alimento_acumulado_kg` y el costo económico en `costo_alimento_acumulado` dentro de la fila del estanque en `estanques`.'
      ]},
      { type: 'heading-3', text: '2. Registro de Bajas (Mortalidad)' },
      { type: 'list', items: [
        'En el formulario rápido de mortalidad, selecciona el estanque e introduce el número de peces muertos.',
        'Al guardar, se inserta una fila en `mortality` y se resta directamente de la columna `current_count` del estanque en `estanques` y de su respectivo registro en `pond_species`, recalculando la tasa de mortalidad acumulada en el acto.'
      ]},
      { type: 'heading-3', text: '3. Traslados de Peces (Transfers) y Reversión Crítica' },
      { type: 'list', items: [
        'Al realizar un traslado, la aplicación registra el movimiento en la tabla `transfers`, descontando población, biomasa y costos proporcionales del estanque de origen e incrementándolos en el de destino.',
        '**Mecanismo de Reversión**: Si cometes un error, puedes presionar "Revertir Traslado" en la bitácora. La app validará que el estanque destino posea la población suficiente y procederá a establecer la columna `revertido = true`.',
        'Durante la reversión, se restauran íntegramente las columnas de `current_count`, `current_biomass_kg`, `costo_alevinos_acumulado`, `consumo_alimento_acumulado_kg`, `costo_alimento_acumulado` y el lote original `current_batch_id` al estanque de origen, mientras que se restan del estanque de destino, eliminando los registros de especies en `pond_species` si su conteo llega a cero.'
      ]}
    ]
  },
  {
    id: 'art-6',
    categoryId: 2,
    title: 'Registro de Siembra e Inicio de Lote',
    summary: 'Configura las bases de tu ciclo productivo ingresando los datos iniciales de tus alevines.',
    blocks: [
      { type: 'paragraph', text: 'Iniciar un lote correctamente en FishBit permite que los algoritmos de proyección estimen el crecimiento de forma óptima.' },
      { type: 'heading-3', text: '1. Flujo de Transacción de Siembra' },
      { type: 'list', items: [
        'Dirígete al módulo \'Siembra\', pulsa \'Nueva Siembra\' y selecciona un estanque con estado \'Vacío\'.',
        'Ingresa el número total de alevines, su peso promedio inicial en gramos y la especie. La app insertará un registro cabecera en `siembras` y sus correspondientes desgloses en `siembra_details`.',
        'El sistema descontará la cantidad del lote de alevines de la tabla `inventory` (categoría \'alevinos\').',
        'Al guardar la siembra, el estanque actualizará su estado automáticamente de \'Vacío\' a \'Con Peces\'.'
      ]},
      { type: 'heading-3', text: '2. Estimación Automatizada de Costos por Factura' },
      { type: 'list', items: [
        'En lugar de solicitarte ingresar costos estimados a mano, FishBit consulta la tabla `invoice_items` filtrando por la categoría \'alevinos\' y la unidad actual.',
        'Calcula el costo promedio ponderado unitario del alevino (`costoTotal / cantidadTotal`) registrado en tus facturas de compra previas del almacén.',
        'Multiplica este costo promedio unitario por la cantidad sembrada y actualiza automáticamente la columna `costo_alevinos_acumulado` del estanque en `estanques`.'
      ]},
      { type: 'heading-3', text: '3. Formato del Batch ID (Identificador de Lote)' },
      { type: 'paragraph', text: 'Para fines de trazabilidad biológica y financiera, la aplicación genera un código de lote exclusivo bajo el formato exacto: `LOTE-YYMMDD-[SPEC]-[POND]`. Por ejemplo, una siembra de Tilapia en el Estanque 1 el 20 de mayo de 2026 generará el identificador `LOTE-260520-TIL-ESTANQUE1` (o `POLI` en caso de registrar un policultivo).' }
    ]
  },
  {
    id: 'art-7',
    categoryId: 3,
    title: 'Cálculo del FCR/ICA en la app',
    summary: 'Aprende cómo funciona el indicador de conversión alimenticia calculado por FishBit.',
    blocks: [
      { type: 'paragraph', text: 'El Factor de Conversión Alimenticia (FCR) o Índice de Conversión Alimenticia (ICA) determina cuántos kilogramos de alimento se necesitan para producir un kilogramo de carne de pescado.' },
      { type: 'heading-3', text: 'Fórmulas del Algoritmo FCR' },
      { type: 'list', items: [
        'FCR Global de Finca: Se calcula consolidando toda la biomasa y alimento consumido de la finca: `globalFCR = totalFeedConsumptionKg / totalBiomassKg` en la finca activa.',
        'FCR Específico por Estanque: Calculado de manera reactiva en el flip de la tarjeta como: `pondFCR = pondFoodAccumulated / pondBiomassKg` para el estanque seleccionado.'
      ]},
      { type: 'heading-3', text: 'Rangos de Clasificación en Panel (StatCard):' },
      { type: 'list', items: [
        'FCR < 1.5: Clasificado como "Óptimo" (Verde). Representa una asimilación excelente del alimento sin desperdicios.',
        'FCR entre 1.5 y 1.8: Clasificado como "Normal" (Amarillo). Rango estándar comercial.',
        'FCR >= 1.8: Clasificado como "Alto" (Rojo/Alarma). Alerta de sobrealimentación, alimento flotando sin consumir, o subestimación de biomasa.'
      ]}
    ]
  },
  {
    id: 'art-8',
    categoryId: 3,
    title: 'Gestión de Inventario y Almacén',
    summary: 'Configura las alertas de almacén y asocia los alimentos con la dosificación diaria de tus peces.',
    blocks: [
      { type: 'paragraph', text: 'El módulo de Almacén de FishBit te ayuda a monitorizar el alimento concentrado disponible para evitar parones nutricionales en el engorde.' },
      { type: 'heading-3', text: '1. Ingreso de Mercancías por Factura' },
      { type: 'list', items: [
        'Toda entrada de inventario en la bodega física se registra a través del modal de facturas, insertando registros en la tabla `invoices` y sus filas en `invoice_items`.',
        'Cada ítem se debe categorizar de manera estricta bajo las siguientes etiquetas del sistema: \'alimento\', \'alevinos\', \'farmacia\', \'insumos\', o \'agrícola\'.',
        'Las facturas actualizan el inventario global (`inventory`) sumando las cantidades y el flete proporcional.'
      ]},
      { type: 'heading-3', text: '2. Alarmas de Stock de Seguridad' },
      { type: 'paragraph', text: 'El sistema compara diariamente la columna `current_stock` contra el límite establecido en la clave `inventoryMin` de la tabla `unit_settings`. Si la cantidad remanente de sacos cae por debajo de este límite, el componente del almacén dispara automáticamente una alarma visual roja y bloquea raciones superiores en alimentación para salvaguardar el inventario.' }
    ]
  },
  {
    id: 'art-9',
    categoryId: 3,
    title: 'Finanzas y Proyecciones de Cosecha',
    summary: 'Aprende cómo el estimador financiero calcula el ROI de tus estanques y proyecta las ganancias.',
    blocks: [
      { type: 'paragraph', text: 'El módulo de \'Finanzas\' consolida todos los egresos (compra de alevines, bolsas de alimento consumidas y mano de obra/mantenimientos) y los cruza con las proyecciones de biomasa.' },
      { type: 'heading-3', text: '1. Fórmulas de Proyección de Crecimiento (HarvestEstimator)' },
      { type: 'paragraph', text: 'La app calcula el peso promedio actual en gramos mediante: `(biomass_kg * 1000) / count`. A partir de allí, estima los días restantes de engorde aplicando curvas de crecimiento diarias específicas:' },
      { type: 'list', items: [
        'Especie Tilapia: Crecimiento diario de 2.5g si el pez pesa < 100g. Sube a 3.8g/día si el peso es >= 100g.',
        'Especie Trucha: Crecimiento diario de 3.0g si el pez pesa < 100g. Sube a 4.5g/día si el peso es >= 100g.',
        'Otras Especies (Default): Tasa lineal estándar de 3.2g por día.',
        'Fórmula de Cosecha: `díasRestantes = (pesoComercialObjetivo - pesoPromedioActual) / tasaCrecimientoDiario`.'
      ]},
      { type: 'heading-3', text: '2. Estructura de Cálculos Financieros y ROI' },
      { type: 'list', items: [
        'Egresos Totales: Suma directa de las columnas acumuladas en el estanque: `costo_alevinos_acumulado + costo_alimento_acumulado`.',
        'Ingresos Proyectados: Multiplica la biomasa estimada al momento de la cosecha por el precio de mercado por kg según la especie registrado en la configuración de venta.',
        'Retorno de Inversión (ROI): Utilidad Neta proyectada dividida por el costo total acumulado del lote.'
      ]}
    ]
  },
  {
    id: 'art-10',
    categoryId: 4,
    title: 'Configurar Umbrales de Alerta de sensores',
    summary: 'Pasos en la app para definir los rangos ideales que activan el semáforo y notificaciones del sistema.',
    blocks: [
      { type: 'paragraph', text: 'Para que el semáforo visual de tus estanques (PondsGrid) y el panel de notificaciones del Dashboard detecten anomalías, debes indicarle a la app cuáles son tus rangos de operación ideales.' },
      { type: 'heading-3', text: 'Persistencia de Configuración de Umbrales:' },
      { type: 'list', items: [
        'Accede al módulo de \'Configuración\' -> pestaña \'Umbrales de Calidad de Agua\'.',
        'Los cambios de los controles deslizantes actualizan la tabla `unit_settings` en la columna JSONB `thresholds`, reescribiendo los valores de `oxygenMin`, `oxygenMax`, `tempMin`, `tempMax`, `phMin`, `phMax` y `mortalityMax`.',
        'Propagación en caliente: Al guardar la configuración, todas las mediciones futuras y las alertas activas del Dashboard se recalculan en milisegundos bajo la nueva parametrización.'
      ]}
    ]
  },
  {
    id: 'art-11',
    categoryId: 4,
    title: 'Roles y Accesos de Personal',
    summary: 'Aprende qué acciones puede realizar cada miembro de tu equipo en la aplicación.',
    blocks: [
      { type: 'paragraph', text: 'FishBit protege tus registros financieros y configuraciones operativas mediante controles estrictos de seguridad basados en roles de la tabla `profiles`:' },
      { type: 'heading-3', text: 'Jerarquía de Roles de Usuario y Redirecciones de Interfaz:' },
      { type: 'list', items: [
        'Propietario / Administrador: Acceso completo a toda la app. Es el único rol autorizado para visualizar el componente de `FinanceSummary` en el Dashboard y la pestaña de facturación y ventas en Finanzas.',
        'Técnico Especialista: Puede visualizar gráficos de tendencias, registrar muestreos físicos, dosificación de alimento y tratamientos. Tiene bloqueado el acceso a resúmenes monetarios. En su lugar, el sistema le muestra automáticamente la tarjeta `FeedInventorySummary` para control biológico y de insumos en el Dashboard.',
        'Operario de Campo: Rol restringido a registro rápido en terreno. Puede ingresar lecturas diarias de sensores y consumo diario desde el móvil. La aplicación oculta automáticamente los menús de configuración general y de finanzas.'
      ]}
    ]
  },
  {
    id: 'art-12',
    categoryId: 4,
    title: 'Monitoreo de Mantenimiento y Tratamientos Sanitarios',
    summary: 'Planifica tareas operativas e ingresa aditivos químicos controlando el tiempo de carencia en la app.',
    blocks: [
      { type: 'paragraph', text: 'Los módulos avanzados de tratamiento y mantenimiento previenen fallos mecánicos y garantizan que coseches productos libres de residuos químicos.' },
      { type: 'heading-3', text: '1. Mantenimiento Preventivo de Estanques y Equipos' },
      { type: 'list', items: [
        'Al completar las listas de tareas sanitarias en el panel de Mantenimiento (como lavado, secado al sol o reparación), la app inserta una bitácora en la tabla `mantenimiento_logs`.',
        'Los insumos utilizados se cargan a la tabla `mantenimiento_logs` asociando su tipo ("Encalado", "Maleza", "Diques", "Plagas") y se descuentan de forma automática del inventario de categorías \'insumos\' o \'agrícola\'.'
      ]},
      { type: 'heading-3', text: '2. Registro de Tratamientos y Tiempo de Carencia (Withdrawal Period)' },
      { type: 'list', items: [
        'Cuando registras la adición de fármacos, desinfectantes o aditivos de farmacia, el sistema inserta filas en `tratamientos` y sus detalles de dosis aplicadas en `tratamiento_details` vinculándose a inventarios de categoría \'farmacia\' e \'insumos\'.',
        '**Candado de Tiempo de Carencia**: Si digitas un tiempo de carencia en días, la aplicación bloquea visualmente el estanque con un candado amarillo en la interfaz de usuario.',
        'Este candado impide automáticamente que el estanque pueda ser comercializado o seleccionado para proyecciones de venta en el módulo financiero hasta que la cuenta regresiva cronológica alcance cero, garantizando total inocuidad alimentaria.'
      ]}
    ]
  }
];

interface SupportTicket {
  id: string;
  subject: string;
  category: string;
  priority: 'baja' | 'normal' | 'alta' | 'emergencia';
  message: string;
  status: 'abierto' | 'revision' | 'resuelto';
  createdAt: string;
}

export default function AyudaPage() {
  const [searchQuery, setSearchQuery] = useState('');
  const [selectedCategory, setSelectedCategory] = useState<number | 'Todas'>('Todas');
  const [expandedArticle, setExpandedArticle] = useState<string | null>(null);

  // Tickets state
  const [isSupportModalOpen, setIsSupportModalOpen] = useState(false);
  const [ticketSubject, setTicketSubject] = useState('');
  const [ticketCategory, setTicketCategory] = useState('Calidad de Agua');
  const [ticketPriority, setTicketPriority] = useState<'baja' | 'normal' | 'alta' | 'emergencia'>('normal');
  const [ticketMessage, setTicketMessage] = useState('');
  const [isSubmittingTicket, setIsSubmittingTicket] = useState(false);
  const [ticketSuccess, setTicketSuccess] = useState(false);
  const [lastTicketId, setLastTicketId] = useState('');
  const [activeTickets, setActiveTickets] = useState<SupportTicket[]>([]);

  // Interactive Tour Simulator States
  const [activeTourTab, setActiveTourTab] = useState<'dashboard' | 'registros' | 'almacen' | 'finanzas' | 'configuracion'>('dashboard');
  
  // Tour - Dashboard tab simulator states
  const [selectedSimPond, setSelectedSimPond] = useState<1 | 2>(1);
  const [isFcrFlipped, setIsFcrFlipped] = useState(false);
  
  // Tour - Registros tab simulator states
  const [simOxygenValue, setSimOxygenValue] = useState('5.2');
  const [simLogs, setSimLogs] = useState<Array<{ time: string, value: string, status: 'stable' | 'warning' | 'critical' }>>([
    { time: '08:00 AM', value: '5.8 mg/L', status: 'stable' },
    { time: '12:00 PM', value: '4.9 mg/L', status: 'stable' }
  ]);
  const [isSimRegistering, setIsSimRegistering] = useState(false);
  
  // Tour - Almacen tab simulator states
  const [simFeedStock, setSimFeedStock] = useState(150); // kg
  
  // Tour - Finanzas tab simulator states
  const [simAverageWeight, setSimAverageWeight] = useState(250); // grams
  
  // Tour - Configuracion tab simulator states
  const [simMinOxygenThreshold, setSimMinOxygenThreshold] = useState(4.0); // mg/L

  // Load tickets on mount
  useEffect(() => {
    const saved = localStorage.getItem('fishbit_support_tickets');
    if (saved) {
      try {
        setActiveTickets(JSON.parse(saved));
      } catch (e) {
        console.error("Error reading tickets", e);
      }
    }
  }, []);

  // Filter articles reactively
  const filteredArticles = useMemo(() => {
    return articles.filter(art => {
      const matchesSearch = 
        art.title.toLowerCase().includes(searchQuery.toLowerCase()) ||
        art.summary.toLowerCase().includes(searchQuery.toLowerCase()) ||
        art.blocks.some(b => b.text?.toLowerCase().includes(searchQuery.toLowerCase()) || b.items?.some(i => i.toLowerCase().includes(searchQuery.toLowerCase())));
      
      const matchesCategory = selectedCategory === 'Todas' || art.categoryId === selectedCategory;
      
      return matchesSearch && matchesCategory;
    });
  }, [searchQuery, selectedCategory]);

  const handleToggleArticle = (id: string) => {
    setExpandedArticle(prev => prev === id ? null : id);
  };

  const handleOpenModal = () => {
    setTicketSubject('');
    setTicketCategory('Calidad de Agua');
    setTicketPriority('normal');
    setTicketMessage('');
    setTicketSuccess(false);
    setIsSupportModalOpen(true);
  };

  const handleSubmitTicket = (e: React.FormEvent) => {
    e.preventDefault();
    if (!ticketSubject.trim() || !ticketMessage.trim()) return;

    setIsSubmittingTicket(true);
    
    // Simulate Supabase/API request delay
    setTimeout(() => {
      const generatedId = `FB-${Math.floor(1000 + Math.random() * 9000)}`;
      const newTicket: SupportTicket = {
        id: generatedId,
        subject: ticketSubject.trim(),
        category: ticketCategory,
        priority: ticketPriority,
        message: ticketMessage.trim(),
        status: 'abierto',
        createdAt: new Date().toLocaleDateString('es-CO', { day: 'numeric', month: 'short' })
      };

      const updated = [newTicket, ...activeTickets];
      setActiveTickets(updated);
      localStorage.setItem('fishbit_support_tickets', JSON.stringify(updated));

      setLastTicketId(generatedId);
      setIsSubmittingTicket(false);
      setTicketSuccess(true);
    }, 1500);
  };

  const handleDeleteTicket = (id: string, e: React.MouseEvent) => {
    e.stopPropagation();
    const updated = activeTickets.filter(t => t.id !== id);
    setActiveTickets(updated);
    localStorage.setItem('fishbit_support_tickets', JSON.stringify(updated));
  };

  // Simulators handlers
  const handleSimRegister = (e: React.FormEvent) => {
    e.preventDefault();
    const parsedVal = parseFloat(simOxygenValue);
    if (isNaN(parsedVal)) return;

    setIsSimRegistering(true);
    setTimeout(() => {
      let status: 'stable' | 'warning' | 'critical' = 'stable';
      if (parsedVal < 4.0) status = 'critical';
      else if (parsedVal < 4.5) status = 'warning';

      const now = new Date();
      const timeStr = now.toLocaleTimeString('es-CO', { hour: '2-digit', minute: '2-digit', hour12: true });
      
      setSimLogs(prev => [
        { time: timeStr, value: `${parsedVal.toFixed(1)} mg/L`, status },
        ...prev
      ]);
      setIsSimRegistering(false);
    }, 800);
  };

  return (
    <div className="animate-fade-in page-container">
      {/* Header section with reactive search */}
      <header style={{ marginBottom: '3.5rem', textAlign: 'center' }}>
        <div style={{ 
          width: '56px', 
          height: '56px', 
          background: 'linear-gradient(135deg, #0d9488, #10b981)', 
          borderRadius: '16px', 
          display: 'flex', 
          alignItems: 'center', 
          justifyContent: 'center',
          margin: '0 auto 1.5rem',
          color: 'white',
          boxShadow: '0 10px 25px rgba(13, 148, 136, 0.2)'
        }}>
          <LifeBuoy size={32} className="animate-pulse" />
        </div>
        <h1 style={{ fontSize: '2.75rem', fontWeight: 950, marginBottom: '1rem', letterSpacing: '-0.04em' }}>Centro de Ayuda</h1>
        <p style={{ color: 'var(--muted-foreground)', fontWeight: 600, fontSize: '1.1rem', marginBottom: '2.5rem' }}>¿En qué podemos apoyarte con tu producción hoy?</p>
        
        {/* Search engine input */}
        <div style={{ position: 'relative', maxWidth: '650px', margin: '0 auto' }}>
          <Search size={22} style={{ position: 'absolute', left: '1.5rem', top: '50%', transform: 'translateY(-50%)', color: 'var(--muted-foreground)' }} />
          <input 
            id="help-search-input"
            type="text" 
            placeholder="Busca guías, pantallas, botones o alertas de la aplicación..." 
            value={searchQuery}
            onChange={(e) => setSearchQuery(e.target.value)}
            className="premium-input"
            style={{ 
              paddingLeft: '4rem',
              borderRadius: '50px', 
              fontSize: '1.1rem',
              fontWeight: 600,
              boxShadow: 'var(--shadow-md)',
              background: 'var(--card)',
              border: '1px solid var(--border)'
            }}
          />
          {searchQuery && (
            <button 
              id="help-clear-search-btn"
              onClick={() => setSearchQuery('')}
              style={{
                position: 'absolute',
                right: '1.5rem',
                top: '50%',
                transform: 'translateY(-50%)',
                background: 'transparent',
                border: 'none',
                color: 'var(--muted-foreground)',
                cursor: 'pointer',
                display: 'flex',
                alignItems: 'center'
              }}
            >
              <X size={18} />
            </button>
          )}
        </div>
      </header>

      {/* Category selector grid */}
      <div className="responsive-grid-4" style={{ marginBottom: '3.5rem', gap: '1.25rem' }}>
        <motion.div
          id="cat-tab-todas"
          whileHover={{ y: -4, scale: 1.02 }}
          onClick={() => setSelectedCategory('Todas')}
          className="card-premium"
          style={{ 
            padding: '1.5rem', 
            textAlign: 'center', 
            cursor: 'pointer', 
            border: selectedCategory === 'Todas' ? '2px solid #0d9488' : '1px solid var(--border)',
            background: selectedCategory === 'Todas' ? 'rgba(13, 148, 136, 0.05)' : 'var(--card)',
            transition: 'all 0.2s ease'
          }}
        >
          <div style={{ 
            width: '44px', 
            height: '44px', 
            borderRadius: '12px', 
            background: 'rgba(255, 255, 255, 0.05)', 
            color: 'var(--foreground)', 
            display: 'flex', 
            alignItems: 'center', 
            justifyContent: 'center',
            margin: '0 auto 1rem'
          }}>
            <HelpCircle size={22} />
          </div>
          <h3 style={{ fontSize: '0.95rem', fontWeight: 900, marginBottom: '0.2rem' }}>Todas las Guías</h3>
          <span style={{ fontSize: '0.7rem', color: 'var(--muted-foreground)', fontWeight: 800, textTransform: 'uppercase' }}>{articles.length} Artículos</span>
        </motion.div>

        {categories.map((cat) => (
          <motion.div
            id={`cat-tab-${cat.id}`}
            key={cat.id}
            whileHover={{ y: -4, scale: 1.02 }}
            onClick={() => setSelectedCategory(cat.id)}
            className="card-premium"
            style={{ 
              padding: '1.5rem', 
              textAlign: 'center', 
              cursor: 'pointer', 
              border: selectedCategory === cat.id ? `2px solid ${cat.color}` : '1px solid var(--border)',
              background: selectedCategory === cat.id ? cat.bg : 'var(--card)',
              transition: 'all 0.2s ease'
            }}
          >
            <div style={{ 
              width: '44px', 
              height: '44px', 
              borderRadius: '12px', 
              background: cat.bg, 
              color: cat.color, 
              display: 'flex', 
              alignItems: 'center', 
              justifyContent: 'center',
              margin: '0 auto 1rem'
            }}>
              <cat.icon size={22} />
            </div>
            <h3 style={{ fontSize: '0.95rem', fontWeight: 900, marginBottom: '0.2rem' }}>{cat.title}</h3>
            <span style={{ fontSize: '0.7rem', color: 'var(--muted-foreground)', fontWeight: 800, textTransform: 'uppercase' }}>{cat.count}</span>
          </motion.div>
        ))}
      </div>

      {/* NEW: Interactive Simulator Tour of the Application */}
      <section className="card-premium" style={{ marginBottom: '3.5rem', padding: '2.5rem', border: '1px solid var(--border)', overflow: 'hidden' }}>
        <div style={{ display: 'flex', alignItems: 'center', gap: '0.75rem', marginBottom: '1.5rem', flexWrap: 'wrap' }}>
          <div style={{ 
            width: '40px', 
            height: '40px', 
            borderRadius: '10px', 
            background: 'rgba(13, 148, 136, 0.1)', 
            color: '#0d9488', 
            display: 'flex', 
            alignItems: 'center', 
            justifyContent: 'center'
          }}>
            <Compass size={22} className="animate-spin" style={{ animationDuration: '6s' }} />
          </div>
          <div>
            <h2 style={{ fontSize: '1.4rem', fontWeight: 950, letterSpacing: '-0.02em', margin: 0 }}>Tour Interactivo de la Aplicación</h2>
            <p style={{ fontSize: '0.85rem', color: 'var(--muted-foreground)', fontWeight: 600, margin: 0 }}>Haz clic en las pestañas para simular cómo funcionan los módulos principales en FishBit.</p>
          </div>
        </div>

        {/* Tour Tabs Bar */}
        <div style={{ 
          display: 'flex', 
          gap: '0.5rem', 
          borderBottom: '1px solid var(--border)', 
          paddingBottom: '1px', 
          marginBottom: '2rem',
          overflowX: 'auto',
          scrollbarWidth: 'none'
        }}>
          {[
            { id: 'dashboard', label: '💻 Dashboard', color: '#0d9488' },
            { id: 'registros', label: '📝 Registros', color: '#3b82f6' },
            { id: 'almacen', label: '📦 Almacén', color: '#f59e0b' },
            { id: 'finanzas', label: '📈 Finanzas', color: '#10b981' },
            { id: 'configuracion', label: '⚙️ Umbrales', color: '#8b5cf6' }
          ].map(tab => (
            <button
              id={`tour-tab-${tab.id}`}
              key={tab.id}
              onClick={() => setActiveTourTab(tab.id as any)}
              style={{
                background: 'transparent',
                border: 'none',
                borderBottom: activeTourTab === tab.id ? `3px solid ${tab.color}` : '3px solid transparent',
                color: activeTourTab === tab.id ? 'var(--foreground)' : 'var(--muted-foreground)',
                padding: '0.75rem 1.25rem',
                fontSize: '0.9rem',
                fontWeight: 900,
                cursor: 'pointer',
                transition: 'all 0.2s ease',
                whiteSpace: 'nowrap'
              }}
            >
              {tab.label}
            </button>
          ))}
        </div>

        {/* Interactive Sandbox Screens */}
        <div style={{ minHeight: '340px', display: 'flex', flexDirection: 'column', justifyContent: 'center' }}>
          <AnimatePresence mode="wait">
            
            {/* Dashboard simulator screen */}
            {activeTourTab === 'dashboard' && (
              <motion.div
                key="dashboard-tour"
                initial={{ opacity: 0, y: 10 }}
                animate={{ opacity: 1, y: 0 }}
                exit={{ opacity: 0, y: -10 }}
                transition={{ duration: 0.2 }}
                style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: '2rem', alignItems: 'center' }}
                className="responsive-grid-2"
              >
                <div>
                  <h3 style={{ fontSize: '1.15rem', fontWeight: 950, marginBottom: '0.8rem', color: '#0d9488' }}>
                    Semaforización y Gráficos Reactivos
                  </h3>
                  <p style={{ fontSize: '0.9rem', lineHeight: 1.6, color: 'var(--muted-foreground)', fontWeight: 550, marginBottom: '1.25rem' }}>
                    Haz clic en los estanques simulados a la derecha. Verás cómo el borde del estanque y los datos de biomasa/temperatura en la gráfica se actualizan automáticamente basados en el estanque seleccionado.
                  </p>
                  
                  {/* Flip card explanation */}
                  <div style={{ display: 'flex', alignItems: 'center', gap: '0.75rem', padding: '0.85rem 1.25rem', background: 'rgba(255, 255, 255, 0.03)', borderRadius: '12px', border: '1px solid var(--border)' }}>
                    <div style={{ fontSize: '1.25rem' }}>🔄</div>
                    <span style={{ fontSize: '0.8rem', fontWeight: 650, color: 'var(--foreground)' }}>
                      ¿Ves la tarjeta FCR abajo? Presiona <strong>Girar Tarjeta</strong> para simular el flip premium 3D del Dashboard.
                    </span>
                  </div>
                </div>

                <div style={{ display: 'flex', flexDirection: 'column', gap: '1.25rem' }}>
                  {/* Grid simulated ponds */}
                  <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: '1rem' }}>
                    <div 
                      onClick={() => setSelectedSimPond(1)}
                      style={{
                        padding: '1.2rem',
                        borderRadius: '16px',
                        background: 'var(--secondary)10',
                        border: selectedSimPond === 1 ? '2px solid #10b981' : '1px solid var(--border)',
                        boxShadow: selectedSimPond === 1 ? '0 0 15px rgba(16, 185, 129, 0.15)' : 'none',
                        cursor: 'pointer',
                        transition: 'all 0.2s ease',
                        textAlign: 'center'
                      }}
                    >
                      <span style={{ fontSize: '0.75rem', fontWeight: 800, color: 'var(--muted-foreground)', textTransform: 'uppercase' }}>Estanque 01</span>
                      <div style={{ fontSize: '1.2rem', fontWeight: 900, color: 'var(--foreground)', marginTop: '0.25rem' }}>Tilapia Roja</div>
                      <div style={{ fontSize: '0.7rem', color: '#10b981', fontWeight: 900, textTransform: 'uppercase', marginTop: '0.4rem' }}>✓ ESTABLE (5.8 mg/L O₂)</div>
                    </div>

                    <div 
                      onClick={() => setSelectedSimPond(2)}
                      style={{
                        padding: '1.2rem',
                        borderRadius: '16px',
                        background: 'var(--secondary)10',
                        border: selectedSimPond === 2 ? '2px solid #ef4444' : '1px solid var(--border)',
                        boxShadow: selectedSimPond === 2 ? '0 0 15px rgba(239, 68, 68, 0.15)' : 'none',
                        cursor: 'pointer',
                        transition: 'all 0.2s ease',
                        textAlign: 'center'
                      }}
                    >
                      <span style={{ fontSize: '0.75rem', fontWeight: 800, color: 'var(--muted-foreground)', textTransform: 'uppercase' }}>Estanque 02</span>
                      <div style={{ fontSize: '1.2rem', fontWeight: 900, color: 'var(--foreground)', marginTop: '0.25rem' }}>Trucha Arcoíris</div>
                      <div style={{ fontSize: '0.7rem', color: '#ef4444', fontWeight: 900, textTransform: 'uppercase', marginTop: '0.4rem', animation: 'pulse 2s infinite' }}>⚠️ ALARMA (3.2 mg/L O₂)</div>
                    </div>
                  </div>

                  {/* Flipping FCR interactive mockup */}
                  <div style={{ perspective: '1000px', height: '100px' }}>
                    <motion.div
                      animate={{ rotateY: isFcrFlipped ? 180 : 0 }}
                      transition={{ duration: 0.5 }}
                      style={{
                        position: 'relative',
                        width: '100%',
                        height: '100%',
                        transformStyle: 'preserve-3d',
                        cursor: 'pointer'
                      }}
                      onClick={() => setIsFcrFlipped(!isFcrFlipped)}
                    >
                      {/* Front: FCR Global */}
                      <div style={{
                        position: 'absolute',
                        width: '100%',
                        height: '100%',
                        backfaceVisibility: 'hidden',
                        background: 'linear-gradient(135deg, #1e293b, #0f172a)',
                        border: '1px solid var(--border)',
                        borderRadius: '16px',
                        padding: '1rem 1.25rem',
                        display: 'flex',
                        alignItems: 'center',
                        justifyContent: 'space-between'
                      }}>
                        <div>
                          <span style={{ fontSize: '0.7rem', fontWeight: 800, color: '#f59e0b', textTransform: 'uppercase' }}>FCR Promedio Finca</span>
                          <h4 style={{ fontSize: '1.6rem', fontWeight: 950, margin: 0, color: 'white' }}>1.38</h4>
                        </div>
                        <span style={{ fontSize: '0.75rem', color: '#0d9488', fontWeight: 900, background: 'rgba(13, 148, 136, 0.1)', padding: '4px 10px', borderRadius: '20px' }}>
                          Girar Tarjeta
                        </span>
                      </div>

                      {/* Back: Detail by pond */}
                      <div style={{
                        position: 'absolute',
                        width: '100%',
                        height: '100%',
                        backfaceVisibility: 'hidden',
                        transform: 'rotateY(180deg)',
                        background: 'linear-gradient(135deg, #0f172a, #1e293b)',
                        border: '1px solid var(--border)',
                        borderRadius: '16px',
                        padding: '1rem 1.25rem',
                        display: 'flex',
                        flexDirection: 'column',
                        justifyContent: 'center',
                        gap: '0.3rem'
                      }}>
                        <div style={{ display: 'flex', justifyContent: 'space-between', fontSize: '0.75rem', fontWeight: 800 }}>
                          <span style={{ color: 'var(--muted-foreground)' }}>Estanque 01 (Tilapia):</span>
                          <span style={{ color: '#10b981' }}>1.32 (Óptimo)</span>
                        </div>
                        <div style={{ display: 'flex', justifyContent: 'space-between', fontSize: '0.75rem', fontWeight: 800 }}>
                          <span style={{ color: 'var(--muted-foreground)' }}>Estanque 02 (Trucha):</span>
                          <span style={{ color: '#f59e0b' }}>1.45 (Normal)</span>
                        </div>
                      </div>
                    </motion.div>
                  </div>
                </div>
              </motion.div>
            )}

            {/* Registros simulator screen */}
            {activeTourTab === 'registros' && (
              <motion.div
                key="registros-tour"
                initial={{ opacity: 0, y: 10 }}
                animate={{ opacity: 1, y: 0 }}
                exit={{ opacity: 0, y: -10 }}
                transition={{ duration: 0.2 }}
                style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: '2rem', alignItems: 'center' }}
                className="responsive-grid-2"
              >
                <div>
                  <h3 style={{ fontSize: '1.15rem', fontWeight: 950, marginBottom: '0.8rem', color: '#3b82f6' }}>
                    Formulario y Validación de Parámetros
                  </h3>
                  <p style={{ fontSize: '0.9rem', lineHeight: 1.6, color: 'var(--muted-foreground)', fontWeight: 550, marginBottom: '1.25rem' }}>
                    Registra un nivel de Oxígeno en el formulario de la derecha. La app procesará la lectura en tiempo real y la guardará en la lista cronológica inferior, evaluando instantáneamente su estado.
                  </p>
                  
                  <div style={{ display: 'flex', flexDirection: 'column', gap: '0.4rem' }}>
                    <div style={{ display: 'flex', justifyContent: 'space-between', fontSize: '0.75rem', fontWeight: 700 }}>
                      <span>Oxígeno &lt; 4.0 mg/L:</span>
                      <span style={{ color: '#ef4444' }}>🔴 Crítico (Alerta)</span>
                    </div>
                    <div style={{ display: 'flex', justifyContent: 'space-between', fontSize: '0.75rem', fontWeight: 700 }}>
                      <span>Oxígeno &gt;= 4.5 mg/L:</span>
                      <span style={{ color: '#10b981' }}>🟢 Estable</span>
                    </div>
                  </div>
                </div>

                <div style={{ background: 'rgba(255, 255, 255, 0.02)', padding: '1.5rem', borderRadius: '20px', border: '1px solid var(--border)' }}>
                  <form onSubmit={handleSimRegister} style={{ display: 'flex', gap: '0.75rem', marginBottom: '1.25rem' }}>
                    <input 
                      type="number" 
                      step="0.1" 
                      placeholder="Oxígeno (mg/L)" 
                      value={simOxygenValue}
                      onChange={(e) => setSimOxygenValue(e.target.value)}
                      className="premium-input"
                      style={{ fontSize: '0.9rem', padding: '0.6rem 1rem', background: 'var(--card)', border: '1px solid var(--border)', borderRadius: '8px', flex: 1 }}
                      required
                    />
                    <button 
                      type="submit" 
                      disabled={isSimRegistering}
                      style={{ 
                        background: '#3b82f6', 
                        color: 'white', 
                        border: 'none', 
                        borderRadius: '8px', 
                        padding: '0 1.25rem', 
                        fontWeight: 900, 
                        fontSize: '0.8rem',
                        cursor: 'pointer',
                        display: 'flex',
                        alignItems: 'center',
                        justifyContent: 'center',
                        boxShadow: '0 5px 10px rgba(59, 130, 246, 0.2)'
                      }}
                    >
                      {isSimRegistering ? <Loader2 size={14} className="animate-spin" /> : 'Probar'}
                    </button>
                  </form>

                  {/* Logs list representation */}
                  <span style={{ fontSize: '0.65rem', fontWeight: 800, color: 'var(--muted-foreground)', textTransform: 'uppercase', display: 'block', marginBottom: '0.5rem' }}>
                    Últimos Registros del Estanque:
                  </span>
                  <div style={{ display: 'flex', flexDirection: 'column', gap: '0.5rem', maxHeight: '110px', overflowY: 'auto' }}>
                    {simLogs.map((log, idx) => (
                      <div 
                        key={idx} 
                        style={{ 
                          display: 'flex', 
                          justifyContent: 'space-between', 
                          padding: '0.5rem 0.75rem', 
                          background: 'rgba(255, 255, 255, 0.03)', 
                          borderRadius: '8px', 
                          border: '1px solid var(--border)',
                          fontSize: '0.75rem',
                          fontWeight: 700
                        }}
                      >
                        <span style={{ color: 'var(--muted-foreground)' }}>{log.time}</span>
                        <span style={{ color: 'var(--foreground)' }}>{log.value}</span>
                        <span style={{ 
                          color: log.status === 'critical' ? '#ef4444' : log.status === 'warning' ? '#f59e0b' : '#10b981'
                        }}>
                          {log.status === 'critical' ? 'CRÍTICO' : log.status === 'warning' ? 'ADVERTENCIA' : 'ESTABLE'}
                        </span>
                      </div>
                    ))}
                  </div>
                </div>
              </motion.div>
            )}

            {/* Almacen simulator screen */}
            {activeTourTab === 'almacen' && (
              <motion.div
                key="almacen-tour"
                initial={{ opacity: 0, y: 10 }}
                animate={{ opacity: 1, y: 0 }}
                exit={{ opacity: 0, y: -10 }}
                transition={{ duration: 0.2 }}
                style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: '2rem', alignItems: 'center' }}
                className="responsive-grid-2"
              >
                <div>
                  <h3 style={{ fontSize: '1.15rem', fontWeight: 950, marginBottom: '0.8rem', color: '#f59e0b' }}>
                    Debito Automático e Inventario de Seguridad
                  </h3>
                  <p style={{ fontSize: '0.9rem', lineHeight: 1.6, color: 'var(--muted-foreground)', fontWeight: 550, marginBottom: '1.25rem' }}>
                    A medida que los operarios alimentan a los peces en la finca, la app descuenta automáticamente el pienso de la bodega. Simula este proceso presionando **Alimentar 40kg**.
                  </p>
                  
                  {/* Warning trigger indicator */}
                  {simFeedStock < 100 ? (
                    <div style={{
                      padding: '0.85rem 1.25rem',
                      background: 'rgba(239, 68, 68, 0.08)',
                      border: '1px solid rgba(239, 68, 68, 0.2)',
                      borderRadius: '12px',
                      color: '#ef4444',
                      fontSize: '0.75rem',
                      fontWeight: 800,
                      display: 'flex',
                      alignItems: 'center',
                      gap: '0.5rem',
                      animation: 'pulse 2s infinite'
                    }}>
                      <AlertTriangle size={16} />
                      ¡STOCK DE SEGURIDAD EXCEDIDO! Alerta de reabastecimiento enviada.
                    </div>
                  ) : (
                    <div style={{
                      padding: '0.85rem 1.25rem',
                      background: 'rgba(16, 185, 129, 0.08)',
                      border: '1px solid rgba(16, 185, 129, 0.2)',
                      borderRadius: '12px',
                      color: '#10b981',
                      fontSize: '0.75rem',
                      fontWeight: 800,
                      display: 'flex',
                      alignItems: 'center',
                      gap: '0.5rem'
                    }}>
                      <CheckCircle size={16} />
                      Bodega con existencias saludables.
                    </div>
                  )}
                </div>

                <div style={{ background: 'rgba(255, 255, 255, 0.02)', padding: '1.75rem', borderRadius: '20px', border: '1px solid var(--border)', display: 'flex', flexDirection: 'column', gap: '1.25rem' }}>
                  <div>
                    <div style={{ display: 'flex', justifyContent: 'space-between', fontSize: '0.8rem', fontWeight: 900, marginBottom: '0.4rem' }}>
                      <span>Alimento: Tilapia Engorde 32%</span>
                      <span style={{ color: simFeedStock < 100 ? '#ef4444' : '#f59e0b' }}>{simFeedStock} kg / 500 kg</span>
                    </div>
                    {/* Progress bar */}
                    <div style={{ width: '100%', height: '12px', background: 'rgba(255, 255, 255, 0.05)', borderRadius: '6px', overflow: 'hidden' }}>
                      <div 
                        style={{ 
                          width: `${(simFeedStock / 500) * 100}%`, 
                          height: '100%', 
                          background: simFeedStock < 100 ? '#ef4444' : 'linear-gradient(90deg, #f59e0b, #d97706)',
                          transition: 'width 0.3s ease'
                        }}
                      />
                    </div>
                    <span style={{ fontSize: '0.65rem', color: 'var(--muted-foreground)', display: 'block', marginTop: '0.3rem', fontWeight: 700 }}>
                      Mínimo de seguridad configurado: 100 kg.
                    </span>
                  </div>

                  <div style={{ display: 'flex', gap: '0.75rem' }}>
                    <button 
                      onClick={() => setSimFeedStock(prev => Math.max(0, prev - 40))}
                      style={{ 
                        flex: 1,
                        background: 'transparent',
                        border: '1px solid var(--border)',
                        color: 'var(--foreground)',
                        borderRadius: '8px',
                        padding: '0.6rem 0',
                        fontSize: '0.75rem',
                        fontWeight: 900,
                        cursor: 'pointer',
                        transition: 'all 0.2s ease'
                      }}
                      onMouseEnter={(e) => e.currentTarget.style.background = 'var(--secondary)15'}
                      onMouseLeave={(e) => e.currentTarget.style.background = 'transparent'}
                    >
                      Alimentar 40kg
                    </button>
                    <button 
                      onClick={() => setSimFeedStock(400)}
                      style={{ 
                        flex: 1,
                        background: '#f59e0b',
                        border: 'none',
                        color: 'white',
                        borderRadius: '8px',
                        padding: '0.6rem 0',
                        fontSize: '0.75rem',
                        fontWeight: 900,
                        cursor: 'pointer',
                        transition: 'all 0.2s ease',
                        boxShadow: '0 5px 10px rgba(245, 158, 11, 0.2)'
                      }}
                      onMouseEnter={(e) => e.currentTarget.style.transform = 'translateY(-2px)'}
                      onMouseLeave={(e) => e.currentTarget.style.transform = 'translateY(0)'}
                    >
                      Abastecer +250kg
                    </button>
                  </div>
                </div>
              </motion.div>
            )}

            {/* Finanzas simulator screen */}
            {activeTourTab === 'finanzas' && (
              <motion.div
                key="finanzas-tour"
                initial={{ opacity: 0, y: 10 }}
                animate={{ opacity: 1, y: 0 }}
                exit={{ opacity: 0, y: -10 }}
                transition={{ duration: 0.2 }}
                style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: '2rem', alignItems: 'center' }}
                className="responsive-grid-2"
              >
                <div>
                  <h3 style={{ fontSize: '1.15rem', fontWeight: 950, marginBottom: '0.8rem', color: '#10b981' }}>
                    Proyección Financiera e Indicador de Cosecha
                  </h3>
                  <p style={{ fontSize: '0.9rem', lineHeight: 1.6, color: 'var(--muted-foreground)', fontWeight: 550, marginBottom: '1.25rem' }}>
                    Arrastra el control deslizante de peso promedio físico de tus peces en gramos. Observarás cómo el algoritmo estima el aumento de biomasa comercializable y calcula instantáneamente tus utilidades y retorno de inversión en pienso.
                  </p>
                  
                  <div style={{ display: 'flex', alignItems: 'center', gap: '0.5rem', fontSize: '0.75rem', color: 'var(--muted-foreground)', fontWeight: 700 }}>
                    <span>Población Activa:</span>
                    <strong style={{ color: 'var(--foreground)' }}>10,000 peces</strong>
                    <span>• FCR Estimado:</span>
                    <strong style={{ color: 'var(--foreground)' }}>1.35</strong>
                  </div>
                </div>

                <div style={{ background: 'rgba(255, 255, 255, 0.02)', padding: '1.5rem', borderRadius: '20px', border: '1px solid var(--border)', display: 'flex', flexDirection: 'column', gap: '1.2rem' }}>
                  {/* Slider */}
                  <div style={{ display: 'flex', flexDirection: 'column', gap: '0.4rem' }}>
                    <div style={{ display: 'flex', justifyContent: 'space-between', fontSize: '0.75rem', fontWeight: 900 }}>
                      <span>Peso Promedio Registrado (Muestreo)</span>
                      <span style={{ color: '#10b981' }}>{simAverageWeight} g</span>
                    </div>
                    <input 
                      type="range" 
                      min="50" 
                      max="800" 
                      step="10"
                      value={simAverageWeight}
                      onChange={(e) => setSimAverageWeight(parseInt(e.target.value))}
                      style={{ accentColor: '#10b981', cursor: 'pointer' }}
                    />
                  </div>

                  {/* Calculations Grid */}
                  <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: '0.75rem' }}>
                    <div style={{ padding: '0.75rem', background: 'rgba(255, 255, 255, 0.03)', borderRadius: '10px', border: '1px solid var(--border)' }}>
                      <span style={{ fontSize: '0.6rem', color: 'var(--muted-foreground)', fontWeight: 800, textTransform: 'uppercase' }}>Biomasa Total</span>
                      <div style={{ fontSize: '1rem', fontWeight: 950, color: 'white', marginTop: '0.2rem' }}>
                        {(simAverageWeight * 10).toLocaleString('es-CO')} kg
                      </div>
                    </div>
                    <div style={{ padding: '0.75rem', background: 'rgba(255, 255, 255, 0.03)', borderRadius: '10px', border: '1px solid var(--border)' }}>
                      <span style={{ fontSize: '0.6rem', color: 'var(--muted-foreground)', fontWeight: 800, textTransform: 'uppercase' }}>Costo Alimento</span>
                      <div style={{ fontSize: '1rem', fontWeight: 950, color: '#ef4444', marginTop: '0.2rem' }}>
                        ${((simAverageWeight * 10 * 1.35) * 1.2).toLocaleString('es-CO', { maximumFractionDigits: 0 })} USD
                      </div>
                    </div>
                    <div style={{ padding: '0.75rem', background: 'rgba(255, 255, 255, 0.03)', borderRadius: '10px', border: '1px solid var(--border)' }}>
                      <span style={{ fontSize: '0.6rem', color: 'var(--muted-foreground)', fontWeight: 800, textTransform: 'uppercase' }}>Ingreso Proyectado</span>
                      <div style={{ fontSize: '1rem', fontWeight: 950, color: '#10b981', marginTop: '0.2rem' }}>
                        ${(simAverageWeight * 10 * 3.5).toLocaleString('es-CO', { maximumFractionDigits: 0 })} USD
                      </div>
                    </div>
                    <div style={{ padding: '0.75rem', background: 'linear-gradient(135deg, rgba(16, 185, 129, 0.08) 0%, rgba(16, 185, 129, 0.02) 100%)', borderRadius: '10px', border: '1px solid rgba(16, 185, 129, 0.2)' }}>
                      <span style={{ fontSize: '0.6rem', color: '#10b981', fontWeight: 900, textTransform: 'uppercase' }}>Utilidad Estimada</span>
                      <div style={{ fontSize: '1rem', fontWeight: 950, color: '#10b981', marginTop: '0.2rem' }}>
                        ${((simAverageWeight * 10 * 3.5) - ((simAverageWeight * 10 * 1.35) * 1.2)).toLocaleString('es-CO', { maximumFractionDigits: 0 })} USD
                      </div>
                    </div>
                  </div>
                </div>
              </motion.div>
            )}

            {/* Configuracion simulator screen */}
            {activeTourTab === 'configuracion' && (
              <motion.div
                key="configuracion-tour"
                initial={{ opacity: 0, y: 10 }}
                animate={{ opacity: 1, y: 0 }}
                exit={{ opacity: 0, y: -10 }}
                transition={{ duration: 0.2 }}
                style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: '2rem', alignItems: 'center' }}
                className="responsive-grid-2"
              >
                <div>
                  <h3 style={{ fontSize: '1.15rem', fontWeight: 950, marginBottom: '0.8rem', color: '#8b5cf6' }}>
                    Propagación Dinámica de Umbrales
                  </h3>
                  <p style={{ fontSize: '0.9rem', lineHeight: 1.6, color: 'var(--muted-foreground)', fontWeight: 550, marginBottom: '1.25rem' }}>
                    Si cambias los límites de seguridad en la configuración, los estanques de la finca cambiarán su color instantáneamente. Ajusta el deslizador de **Límite Mínimo de Oxígeno** a la derecha para ver este efecto de recálculo dinámico.
                  </p>
                  
                  <div style={{ padding: '0.85rem 1.25rem', background: 'rgba(255, 255, 255, 0.03)', borderRadius: '12px', border: '1px solid var(--border)', fontSize: '0.8rem', fontWeight: 650 }}>
                    💡 <strong>Cómo probar:</strong> Sube el límite mínimo de oxígeno por encima de 4.8 mg/L. Observarás cómo el estanque simulado con lectura física de 4.8 mg/L pasa inmediatamente de badge verde a alarma roja.
                  </div>
                </div>

                <div style={{ background: 'rgba(255, 255, 255, 0.02)', padding: '1.5rem', borderRadius: '20px', border: '1px solid var(--border)', display: 'flex', flexDirection: 'column', gap: '1.25rem' }}>
                  {/* Slider threshold editor */}
                  <div style={{ display: 'flex', flexDirection: 'column', gap: '0.4rem' }}>
                    <div style={{ display: 'flex', justifyContent: 'space-between', fontSize: '0.75rem', fontWeight: 900 }}>
                      <span>Límite Mínimo de Oxígeno (Configuración)</span>
                      <span style={{ color: '#8b5cf6', fontWeight: 'bold' }}>{simMinOxygenThreshold.toFixed(1)} mg/L</span>
                    </div>
                    <input 
                      type="range" 
                      min="3.0" 
                      max="6.0" 
                      step="0.1"
                      value={simMinOxygenThreshold}
                      onChange={(e) => setSimMinOxygenThreshold(parseFloat(e.target.value))}
                      style={{ accentColor: '#8b5cf6', cursor: 'pointer' }}
                    />
                  </div>

                  {/* Simulated Pond Card */}
                  <div style={{
                    padding: '1.25rem',
                    borderRadius: '16px',
                    background: 'var(--card)',
                    border: 4.8 >= simMinOxygenThreshold ? '2px solid #10b981' : '2px solid #ef4444',
                    display: 'flex',
                    flexDirection: 'column',
                    alignItems: 'center',
                    gap: '0.3rem',
                    transition: 'border-color 0.2s ease'
                  }}>
                    <span style={{ fontSize: '0.65rem', fontWeight: 800, color: 'var(--muted-foreground)' }}>ESTANQUE DE PRUEBAS</span>
                    <h4 style={{ fontSize: '1.1rem', fontWeight: 950, margin: 0 }}>Lectura Física: 4.8 mg/L</h4>
                    
                    {4.8 >= simMinOxygenThreshold ? (
                      <span style={{ fontSize: '0.7rem', color: '#10b981', fontWeight: 900, background: 'rgba(16, 185, 129, 0.1)', padding: '3px 10px', borderRadius: '20px', marginTop: '0.2rem' }}>
                        🟢 ESTADO SALUDABLE
                      </span>
                    ) : (
                      <span style={{ fontSize: '0.7rem', color: '#ef4444', fontWeight: 900, background: 'rgba(239, 68, 68, 0.1)', padding: '3px 10px', borderRadius: '20px', marginTop: '0.2rem', animation: 'pulse 1.5s infinite' }}>
                        🔴 ALERTA DE OXÍGENO
                      </span>
                    )}
                  </div>
                </div>
              </motion.div>
            )}

          </AnimatePresence>
        </div>
      </section>

      {/* Main Content Sections: Left: FAQs, Right: Support Systems */}
      <div className="responsive-grid-2" style={{ gap: '2.5rem', alignItems: 'start' }}>
        
        {/* Left Column: Reactive FAQ List */}
        <div>
          <h2 style={{ fontSize: '1.5rem', fontWeight: 950, marginBottom: '1.75rem', display: 'flex', alignItems: 'center', gap: '0.75rem', letterSpacing: '-0.03em' }}>
            <HelpCircle size={26} style={{ color: '#0d9488' }} />
            Preguntas y Guías de Operación
          </h2>

          <div style={{ display: 'flex', flexDirection: 'column', gap: '1rem' }}>
            <AnimatePresence mode="popLayout">
              {filteredArticles.length > 0 ? (
                filteredArticles.map((art, index) => {
                  const isOpen = expandedArticle === art.id;
                  return (
                    <motion.div
                      id={`faq-accordion-${art.id}`}
                      key={art.id}
                      initial={{ opacity: 0, y: 10 }}
                      animate={{ opacity: 1, y: 0 }}
                      exit={{ opacity: 0, y: -10 }}
                      transition={{ duration: 0.2, delay: index * 0.05 }}
                      className="glass"
                      style={{ 
                        borderRadius: '20px', 
                        border: isOpen ? '1px solid #0d9488' : '1px solid var(--border)',
                        overflow: 'hidden',
                        background: isOpen ? 'var(--card)' : 'transparent',
                        transition: 'border-color 0.3s ease, background-color 0.3s ease'
                      }}
                    >
                      {/* Accordion trigger header */}
                      <div 
                        onClick={() => handleToggleArticle(art.id)}
                        style={{ 
                          padding: '1.5rem', 
                          display: 'flex', 
                          justifyContent: 'space-between', 
                          alignItems: 'center',
                          cursor: 'pointer',
                          userSelect: 'none'
                        }}
                      >
                        <div style={{ display: 'flex', flexDirection: 'column', gap: '0.2rem', paddingRight: '1rem' }}>
                          <span style={{ fontWeight: 900, fontSize: '1.05rem', color: isOpen ? 'var(--foreground)' : 'var(--foreground)dd', transition: 'color 0.2s ease' }}>{art.title}</span>
                          <span style={{ fontSize: '0.75rem', color: 'var(--muted-foreground)', fontWeight: 600 }}>{art.summary}</span>
                        </div>
                        <div style={{
                          padding: '0.4rem',
                          background: isOpen ? 'rgba(13, 148, 136, 0.1)' : 'rgba(255, 255, 255, 0.03)',
                          color: isOpen ? '#0d9488' : 'var(--muted-foreground)',
                          borderRadius: '10px',
                          display: 'flex',
                          alignItems: 'center',
                          justifyContent: 'center',
                          transition: 'all 0.2s ease'
                        }}>
                          {isOpen ? <ChevronDown size={18} /> : <ChevronRight size={18} />}
                        </div>
                      </div>

                      {/* Expandable rich content */}
                      <AnimatePresence>
                        {isOpen && (
                          <motion.div
                            initial={{ height: 0 }}
                            animate={{ height: 'auto' }}
                            exit={{ height: 0 }}
                            transition={{ duration: 0.3, ease: 'easeInOut' }}
                            style={{ overflow: 'hidden' }}
                          >
                            <div style={{ 
                                padding: '0 1.5rem 1.5rem 1.5rem', 
                                borderTop: '1px solid var(--border)', 
                                fontSize: '0.9rem', 
                                color: 'var(--foreground)f0',
                                lineHeight: 1.6,
                                display: 'flex',
                                flexDirection: 'column',
                                gap: '1rem'
                            }}>
                              <div style={{ height: '1rem' }}></div>
                              {art.blocks.map((block, bIdx) => {
                                switch (block.type) {
                                  case 'heading-3':
                                    return <h4 key={bIdx} style={{ fontSize: '1rem', fontWeight: 900, color: 'var(--foreground)', marginTop: '0.5rem' }}>{block.text}</h4>;
                                  
                                  case 'paragraph':
                                    return <p key={bIdx} style={{ fontWeight: 550 }}>{block.text}</p>;
                                  
                                  case 'list':
                                    return (
                                      <ul key={bIdx} style={{ paddingLeft: '1.25rem', listStyleType: 'disc', display: 'flex', flexDirection: 'column', gap: '0.4rem' }}>
                                        {block.items?.map((item, iIdx) => (
                                          <li key={iIdx} style={{ fontWeight: 550 }}>{item}</li>
                                        ))}
                                      </ul>
                                    );
                                  
                                  case 'alert':
                                    const isTip = block.alertType === 'tip';
                                    const isWarning = block.alertType === 'warning';
                                    const alertColor = isTip ? '#0d9488' : (isWarning ? '#ef4444' : '#3b82f6');
                                    const alertBg = isTip ? 'rgba(13, 148, 136, 0.06)' : (isWarning ? 'rgba(239, 68, 68, 0.06)' : 'rgba(59, 130, 246, 0.06)');
                                    return (
                                      <div key={bIdx} style={{ 
                                        padding: '1.2rem 1.5rem', 
                                        borderRadius: '16px', 
                                        background: alertBg, 
                                        borderLeft: `4px solid ${alertColor}`,
                                        marginTop: '0.75rem',
                                        display: 'flex',
                                        flexDirection: 'column',
                                        gap: '0.3rem'
                                      }}>
                                        <div style={{ display: 'flex', alignItems: 'center', gap: '0.5rem', color: alertColor, fontWeight: 900, fontSize: '0.75rem', textTransform: 'uppercase', letterSpacing: '0.05em' }}>
                                          {isWarning && <AlertTriangle size={14} />}
                                          {isTip && <Sparkles size={14} />}
                                          {!isWarning && !isTip && <HelpCircle size={14} />}
                                          {block.alertTitle}
                                        </div>
                                        <p style={{ margin: 0, fontSize: '0.85rem', fontWeight: 650, color: 'var(--foreground)' }}>{block.text}</p>
                                      </div>
                                    );
                                  
                                  default:
                                    return null;
                                }
                              })}
                            </div>
                          </motion.div>
                        )}
                      </AnimatePresence>
                    </motion.div>
                  );
                })
              ) : (
                <div style={{ 
                  padding: '3.5rem 2rem', 
                  textAlign: 'center', 
                  border: '1px dashed var(--border)', 
                  borderRadius: '24px',
                  display: 'flex',
                  flexDirection: 'column',
                  alignItems: 'center',
                  gap: '0.8rem'
                }}>
                  <div style={{ fontSize: '2rem' }}>🔍</div>
                  <h3 style={{ fontSize: '1.1rem', fontWeight: 900 }}>Sin resultados</h3>
                  <p style={{ fontSize: '0.85rem', color: 'var(--muted-foreground)', maxWidth: '280px', margin: '0 auto', fontWeight: 600 }}>
                    No encontramos respuestas para "{searchQuery}". Intenta con otras palabras clave como "Oxígeno", "FCR" o "Límite".
                  </p>
                </div>
              )}
            </AnimatePresence>
          </div>
        </div>

        {/* Right Column: Support Action and Tracking */}
        <div style={{ display: 'flex', flexDirection: 'column', gap: '2rem' }}>
          
          {/* Support Banner Call to Action */}
          <div style={{ 
            background: 'linear-gradient(135deg, #0d9488 0%, #065f46 100%)', 
            borderRadius: '32px', 
            padding: '3rem 2.5rem', 
            color: 'white',
            display: 'flex',
            flexDirection: 'column',
            justifyContent: 'center',
            alignItems: 'center',
            textAlign: 'center',
            boxShadow: '0 25px 50px -12px rgba(13, 148, 136, 0.4)'
          }}>
            <div style={{ 
              width: '64px', 
              height: '64px', 
              background: 'rgba(255, 255, 255, 0.15)', 
              borderRadius: '20px', 
              display: 'flex', 
              alignItems: 'center', 
              justifyContent: 'center',
              marginBottom: '1.5rem',
              backdropFilter: 'blur(10px)'
            }}>
              <MessageCircle size={32} />
            </div>
            <h2 style={{ fontSize: '1.75rem', fontWeight: 950, marginBottom: '0.8rem', letterSpacing: '-0.03em' }}>Asistencia Directa</h2>
            <p style={{ opacity: 0.9, marginBottom: '2rem', lineHeight: 1.6, fontWeight: 600, fontSize: '0.95rem', maxWidth: '300px' }}>
              Si no encuentras lo que buscas, nuestro equipo técnico está listo para asistirte en tiempo real.
            </p>
            <button 
              id="btn-talk-expert"
              onClick={handleOpenModal}
              style={{ 
                background: 'white', 
                color: '#0d9488', 
                padding: '1.1rem 2.2rem', 
                borderRadius: '16px', 
                border: 'none', 
                fontWeight: 950, 
                fontSize: '0.95rem',
                cursor: 'pointer',
                boxShadow: '0 12px 24px rgba(0, 0, 0, 0.12)',
                transition: 'all 0.2s ease',
                display: 'flex',
                alignItems: 'center',
                gap: '0.5rem'
              }}
              onMouseEnter={(e) => {
                e.currentTarget.style.transform = 'translateY(-3px)';
                e.currentTarget.style.boxShadow = '0 15px 30px rgba(0, 0, 0, 0.18)';
              }}
              onMouseLeave={(e) => {
                e.currentTarget.style.transform = 'translateY(0)';
                e.currentTarget.style.boxShadow = '0 12px 24px rgba(0, 0, 0, 0.12)';
              }}
            >
              <LifeBuoy size={18} />
              Hablar con un Experto
            </button>
          </div>

          {/* Active Tickets Tracking Card */}
          <div className="card-premium" style={{ padding: '2rem', display: 'flex', flexDirection: 'column', gap: '1.25rem', border: '1px solid var(--border)' }}>
            <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
              <h3 style={{ fontSize: '1.1rem', fontWeight: 950, display: 'flex', alignItems: 'center', gap: '0.5rem', letterSpacing: '-0.02em' }}>
                <Clock size={20} color="#0d9488" />
                Mis Casos Activos
              </h3>
              <span style={{ 
                background: 'rgba(255, 255, 255, 0.05)', 
                color: 'var(--muted-foreground)', 
                fontSize: '0.65rem', 
                padding: '3px 8px', 
                borderRadius: '6px', 
                fontWeight: 800 
              }}>
                {activeTickets.length} Casos
              </span>
            </div>

            <div style={{ display: 'flex', flexDirection: 'column', gap: '0.85rem', maxHeight: '320px', overflowY: 'auto', paddingRight: '2px' }}>
              {activeTickets.length > 0 ? (
                activeTickets.map(ticket => (
                  <div 
                    key={ticket.id}
                    style={{
                      padding: '1rem',
                      borderRadius: '16px',
                      background: 'var(--secondary)15',
                      border: '1px solid var(--border)',
                      display: 'flex',
                      flexDirection: 'column',
                      gap: '0.5rem'
                    }}
                  >
                    <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'flex-start' }}>
                      <span style={{ fontSize: '0.85rem', fontWeight: 900, color: 'var(--foreground)' }}>{ticket.subject}</span>
                      <button 
                        onClick={(e) => handleDeleteTicket(ticket.id, e)}
                        style={{
                          background: 'transparent',
                          border: 'none',
                          color: 'var(--muted-foreground)',
                          cursor: 'pointer',
                          padding: '2px',
                          display: 'flex',
                          alignItems: 'center',
                          justifyContent: 'center'
                        }}
                      >
                        <X size={14} />
                      </button>
                    </div>

                    <div style={{ display: 'flex', flexWrap: 'wrap', gap: '0.4rem', alignItems: 'center', fontSize: '0.65rem', fontWeight: 800 }}>
                      <span style={{ color: 'var(--muted-foreground)' }}>{ticket.id}</span>
                      <span style={{ color: 'var(--muted-foreground)' }}>•</span>
                      <span style={{ color: 'var(--muted-foreground)' }}>{ticket.createdAt}</span>
                      <span style={{ color: 'var(--muted-foreground)' }}>•</span>
                      
                      {/* Priority Tag */}
                      <span style={{ 
                        textTransform: 'uppercase',
                        padding: '2px 6px',
                        borderRadius: '4px',
                        fontSize: '0.55rem',
                        fontWeight: 900,
                        background: ticket.priority === 'emergencia' ? 'rgba(239, 68, 68, 0.1)' : 
                                    ticket.priority === 'alta' ? 'rgba(245, 158, 11, 0.1)' : 'rgba(59, 130, 246, 0.1)',
                        color: ticket.priority === 'emergencia' ? '#ef4444' : 
                               ticket.priority === 'alta' ? '#f59e0b' : '#3b82f6',
                      }}>
                        {ticket.priority}
                      </span>

                      {/* Status Tag */}
                      <span style={{ 
                        textTransform: 'uppercase',
                        padding: '2px 6px',
                        borderRadius: '4px',
                        fontSize: '0.55rem',
                        fontWeight: 900,
                        background: 'rgba(16, 185, 129, 0.1)',
                        color: '#10b981',
                        marginLeft: 'auto'
                      }}>
                        {ticket.status}
                      </span>
                    </div>
                  </div>
                ))
              ) : (
                <div style={{ textAlign: 'center', padding: '2rem 1rem', color: 'var(--muted-foreground)', fontSize: '0.75rem', fontWeight: 600, fontStyle: 'italic' }}>
                  No tienes solicitudes de asistencia activas registradas localmente.
                </div>
              )}
            </div>
          </div>

        </div>

      </div>

      {/* Support Request Modal Overlay */}
      <AnimatePresence>
        {isSupportModalOpen && (
          <div style={{
            position: 'fixed',
            top: 0,
            left: 0,
            right: 0,
            bottom: 0,
            background: 'rgba(5, 20, 25, 0.75)',
            backdropFilter: 'blur(8px)',
            zIndex: 1000,
            display: 'flex',
            alignItems: 'center',
            justifyContent: 'center',
            padding: '1.5rem'
          }}>
            <motion.div
              initial={{ opacity: 0, scale: 0.95 }}
              animate={{ opacity: 1, scale: 1 }}
              exit={{ opacity: 0, scale: 0.95 }}
              className="card-premium"
              style={{
                width: '100%',
                maxWidth: '520px',
                background: 'var(--card)',
                border: '1px solid var(--border)',
                borderRadius: '24px',
                boxShadow: 'var(--shadow-xl)',
                display: 'flex',
                flexDirection: 'column',
                overflow: 'hidden'
              }}
            >
              {/* Modal Header */}
              <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', padding: '1.5rem', borderBottom: '1px solid var(--border)' }}>
                <h3 style={{ fontSize: '1.15rem', fontWeight: 950, display: 'flex', alignItems: 'center', gap: '0.5rem', letterSpacing: '-0.02em' }}>
                  <MessageCircle size={22} color="#0d9488" />
                  Nuevo Caso de Soporte
                </h3>
                <button 
                  id="btn-close-modal"
                  onClick={() => setIsSupportModalOpen(false)}
                  style={{
                    background: 'transparent',
                    border: 'none',
                    color: 'var(--muted-foreground)',
                    cursor: 'pointer',
                    borderRadius: '8px',
                    padding: '0.25rem',
                    display: 'flex',
                    alignItems: 'center',
                    justifyContent: 'center',
                    transition: 'all 0.2s ease'
                  }}
                  onMouseEnter={(e) => e.currentTarget.style.color = '#ef4444'}
                  onMouseLeave={(e) => e.currentTarget.style.color = 'var(--muted-foreground)'}
                >
                  <X size={20} />
                </button>
              </div>

              {/* Modal Content */}
              <div style={{ padding: '1.75rem', display: 'flex', flexDirection: 'column', gap: '1.25rem' }}>
                {!ticketSuccess ? (
                  <form onSubmit={handleSubmitTicket} style={{ display: 'flex', flexDirection: 'column', gap: '1.25rem' }}>
                    
                    {/* Subject field */}
                    <div style={{ display: 'flex', flexDirection: 'column', gap: '0.4rem' }}>
                      <label style={{ fontSize: '0.7rem', fontWeight: 800, color: 'var(--muted-foreground)', textTransform: 'uppercase', letterSpacing: '0.05em' }}>Asunto del Inconveniente</label>
                      <input 
                        id="ticket-subject-input"
                        type="text" 
                        placeholder="Ej: Desviación continua en oxímetro o error de inventario" 
                        required
                        value={ticketSubject}
                        onChange={(e) => setTicketSubject(e.target.value)}
                        className="premium-input"
                        style={{ fontSize: '0.9rem', padding: '0.85rem 1rem', background: 'var(--secondary)15', border: '1px solid var(--border)', borderRadius: '12px' }}
                      />
                    </div>

                    {/* Selector Category and Priority Row */}
                    <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: '1rem' }}>
                      
                      <div style={{ display: 'flex', flexDirection: 'column', gap: '0.4rem' }}>
                        <label style={{ fontSize: '0.7rem', fontWeight: 800, color: 'var(--muted-foreground)', textTransform: 'uppercase', letterSpacing: '0.05em' }}>Categoría</label>
                        <select
                          id="ticket-category-select"
                          value={ticketCategory}
                          onChange={(e) => setTicketCategory(e.target.value)}
                          className="premium-input"
                          style={{ fontSize: '0.85rem', padding: '0.85rem 1rem', background: 'var(--secondary)15', border: '1px solid var(--border)', borderRadius: '12px', cursor: 'pointer' }}
                        >
                          <option value="Calidad de Agua">Calidad de Agua</option>
                          <option value="Alimentación">Alimentación</option>
                          <option value="Finanzas">Finanzas</option>
                          <option value="Técnico / Hardware">Técnico / Hardware</option>
                          <option value="Error de Software">Error de Software</option>
                        </select>
                      </div>

                      <div style={{ display: 'flex', flexDirection: 'column', gap: '0.4rem' }}>
                        <label style={{ fontSize: '0.7rem', fontWeight: 800, color: 'var(--muted-foreground)', textTransform: 'uppercase', letterSpacing: '0.05em' }}>Prioridad</label>
                        <select
                          id="ticket-priority-select"
                          value={ticketPriority}
                          onChange={(e) => setTicketPriority(e.target.value as any)}
                          className="premium-input"
                          style={{ 
                            fontSize: '0.85rem', 
                            padding: '0.85rem 1rem', 
                            background: ticketPriority === 'emergencia' ? 'rgba(239, 68, 68, 0.05)' : 'var(--secondary)15', 
                            border: ticketPriority === 'emergencia' ? '1px solid #ef4444' : '1px solid var(--border)', 
                            color: ticketPriority === 'emergencia' ? '#ef4444' : 'var(--foreground)',
                            borderRadius: '12px', 
                            cursor: 'pointer',
                            fontWeight: ticketPriority === 'emergencia' ? 'bold' : 'normal'
                          }}
                        >
                          <option value="baja" style={{ color: 'var(--foreground)' }}>Baja</option>
                          <option value="normal" style={{ color: 'var(--foreground)' }}>Normal</option>
                          <option value="alta" style={{ color: 'var(--foreground)' }}>Alta</option>
                          <option value="emergencia" style={{ color: '#ef4444', fontWeight: 'bold' }}>⚠️ Emergencia</option>
                        </select>
                      </div>

                    </div>

                    {/* Message / Description */}
                    <div style={{ display: 'flex', flexDirection: 'column', gap: '0.4rem' }}>
                      <label style={{ fontSize: '0.7rem', fontWeight: 800, color: 'var(--muted-foreground)', textTransform: 'uppercase', letterSpacing: '0.05em' }}>Mensaje o Descripción Detallada</label>
                      <textarea
                        id="ticket-message-textarea"
                        placeholder="Por favor describe detalladamente la situación para que un técnico especialista pueda orientarte mejor..."
                        required
                        rows={4}
                        value={ticketMessage}
                        onChange={(e) => setTicketMessage(e.target.value)}
                        className="premium-input"
                        style={{ fontSize: '0.85rem', padding: '0.85rem 1rem', background: 'var(--secondary)15', border: '1px solid var(--border)', borderRadius: '12px', resize: 'none', lineHeight: 1.5 }}
                      />
                    </div>

                    {/* Warning if emergency priority is selected */}
                    {ticketPriority === 'emergencia' && (
                      <div style={{ 
                        padding: '0.85rem 1rem', 
                        background: 'rgba(239, 68, 68, 0.06)', 
                        border: '1px solid rgba(239, 68, 68, 0.2)', 
                        borderRadius: '12px',
                        display: 'flex',
                        gap: '0.6rem',
                        alignItems: 'center'
                      }}>
                        <AlertTriangle size={18} color="#ef4444" className="animate-bounce" />
                        <span style={{ fontSize: '0.75rem', color: '#ef4444', fontWeight: 700 }}>
                          La prioridad de Emergencia alerta directamente al técnico de guardia. Úsala solo para problemas críticos de biomasa.
                        </span>
                      </div>
                    )}

                    {/* Form Buttons */}
                    <div style={{ display: 'flex', justifyContent: 'flex-end', gap: '1rem', marginTop: '0.5rem', borderTop: '1px solid var(--border)', paddingTop: '1.25rem' }}>
                      <button 
                        id="ticket-cancel-btn"
                        type="button" 
                        disabled={isSubmittingTicket}
                        onClick={() => setIsSupportModalOpen(false)}
                        style={{ 
                          padding: '0.75rem 1.5rem', 
                          background: 'transparent', 
                          border: '1px solid var(--border)', 
                          color: 'var(--foreground)', 
                          borderRadius: '10px', 
                          fontWeight: 800, 
                          fontSize: '0.85rem',
                          cursor: 'pointer',
                          transition: 'all 0.2s ease'
                        }}
                        onMouseEnter={(e) => e.currentTarget.style.background = 'var(--secondary)15'}
                        onMouseLeave={(e) => e.currentTarget.style.background = 'transparent'}
                      >
                        Cancelar
                      </button>
                      <button 
                        id="ticket-submit-btn"
                        type="submit" 
                        disabled={isSubmittingTicket}
                        style={{ 
                          padding: '0.75rem 1.75rem', 
                          background: 'linear-gradient(135deg, #0d9488, #065f46)', 
                          border: 'none', 
                          color: 'white', 
                          borderRadius: '10px', 
                          fontWeight: 900, 
                          fontSize: '0.85rem',
                          cursor: 'pointer',
                          transition: 'all 0.2s ease',
                          display: 'flex',
                          alignItems: 'center',
                          gap: '0.5rem',
                          boxShadow: '0 8px 16px rgba(13, 148, 136, 0.2)'
                        }}
                        onMouseEnter={(e) => e.currentTarget.style.transform = 'translateY(-2px)'}
                        onMouseLeave={(e) => e.currentTarget.style.transform = 'translateY(0)'}
                      >
                        {isSubmittingTicket ? (
                          <>
                            <Loader2 size={16} className="animate-spin" />
                            Enviando...
                          </>
                        ) : (
                          <>
                            <Send size={16} />
                            Enviar Solicitud
                          </>
                        )}
                      </button>
                    </div>

                  </form>
                ) : (
                  // Success layout inside modal
                  <div style={{ textAlign: 'center', padding: '2rem 1rem', display: 'flex', flexDirection: 'column', alignItems: 'center', gap: '1.25rem' }}>
                    <div style={{ 
                      width: '64px', 
                      height: '64px', 
                      background: 'rgba(16, 185, 129, 0.1)', 
                      color: '#10b981', 
                      borderRadius: '50%', 
                      display: 'flex', 
                      alignItems: 'center', 
                      justifyContent: 'center'
                    }}>
                      <CheckCircle size={36} />
                    </div>
                    <div>
                      <h4 style={{ fontSize: '1.25rem', fontWeight: 950, marginBottom: '0.5rem', letterSpacing: '-0.02em' }}>¡Solicitud Enviada con Éxito!</h4>
                      <p style={{ fontSize: '0.85rem', color: 'var(--muted-foreground)', fontWeight: 600, maxWidth: '300px', margin: '0 auto', lineHeight: 1.5 }}>
                        Tu caso ha sido registrado bajo el código <strong style={{ color: 'var(--foreground)' }}>{lastTicketId}</strong>.
                      </p>
                    </div>
                    
                    <div style={{ 
                      padding: '1rem 1.5rem', 
                      background: 'var(--secondary)10', 
                      borderRadius: '16px', 
                      border: '1px solid var(--border)',
                      fontSize: '0.75rem',
                      color: 'var(--muted-foreground)',
                      fontWeight: 650,
                      maxWidth: '350px',
                      display: 'flex',
                      alignItems: 'center',
                      gap: '0.5rem'
                    }}>
                      <Clock size={16} color="#0d9488" />
                      <span>Nuestro equipo técnico de guardia ha sido alertado. Tiempo estimado de respuesta: menos de 2 horas.</span>
                    </div>

                    <button 
                      id="ticket-success-ok-btn"
                      onClick={() => setIsSupportModalOpen(false)}
                      style={{ 
                        padding: '0.85rem 2rem', 
                        background: '#0d9488', 
                        border: 'none', 
                        color: 'white', 
                        borderRadius: '12px', 
                        fontWeight: 950, 
                        fontSize: '0.9rem',
                        cursor: 'pointer',
                        boxShadow: '0 8px 16px rgba(13, 148, 136, 0.2)',
                        transition: 'all 0.2s ease',
                        width: '100%',
                        marginTop: '0.5rem'
                      }}
                      onMouseEnter={(e) => e.currentTarget.style.transform = 'translateY(-2px)'}
                      onMouseLeave={(e) => e.currentTarget.style.transform = 'translateY(0)'}
                    >
                      Cerrar y Regresar
                    </button>
                  </div>
                )}
              </div>

            </motion.div>
          </div>
        )}
      </AnimatePresence>

    </div>
  );
}
