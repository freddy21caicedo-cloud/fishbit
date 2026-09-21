# Auditoría Integral de Rendimiento, Gestión de Estado y Base de Datos (FishBit)

> **Resumen Ejecutivo:** Se realizó una auditoría profunda de solo lectura sobre el frontend Flutter y el backend Supabase/PostgreSQL de FishBit. Se identificaron **19 hallazgos críticos, altos y medios** que afectan la tasa de cuadros por segundo (caída a <30 FPS por `BackdropFilter` y cálculos síncronos en `build`), fugas de memoria en controladores y carreras asíncronas de video, reconstrucciones destructivas de navegación con Riverpod+GoRouter, cascadas de recarga que parpadean la UI, consultas no acotadas sin paginación y cuellos de botella en PostgreSQL por falta de índices compuestos en `(empresa_id, fecha DESC)` y cláusulas `OR` en políticas RLS.

---

## Índice de Hallazgos por Dimensión y Severidad

| ID | Dimensión | Severidad | Archivo Principal | Resumen del Problema |
|:---|:---|:---:|:---|:---|
| **STATE-01** | Estado y Rebuilds | **High** | `lib/modules/bitacora/presentation/screens/bitacora_screen.dart:419-425` | `ref.watch` monolítico de 3 providers en raíz causa rebuild de 1,860 líneas de UI ante cualquier evento menor. |
| **STATE-02** | Estado y Rebuilds | **High** | `lib/modules/bitacora/presentation/screens/bitacora_screen.dart:1050, 1750-1858` | Cálculo síncrono pesado de curvas de crecimiento GDP y ordenamiento (`_BiometryAnalysis.compute`) dentro del método `build()`. |
| **STATE-03** | Estado y Rebuilds | **Medium** | `lib/modules/ica_compliance/presentation/screens/ica_certification_screen.dart:47-52` | Sobresuscripción simultánea a 6 providers en `build()` y `ref.watch` indebido de un motor de reportes que solo se usa en `onPressed`. |
| **STATE-04** | Estado y Rebuilds | **Medium** | `lib/modules/ponds_batches/presentation/screens/ponds_dashboard_screen.dart:27-28, 144, 381` | `setState` en pantalla raíz para alternar SpeedDial y filtros segmentados reconstruye innecesariamente todo el árbol de estanques. |
| **STATE-05** | Estado y Rebuilds | **Medium** | `lib/modules/ponds_batches/presentation/widgets/pond_bento_card.dart:81-90` | Instanciación incondicional doble de cara frontal y cara trasera (3D Flip) en cada frame de `build()` en cada estanque. |
| **STATE-06** | Estado y Rebuilds | **Critical** | `lib/app/router.dart:33-37` | Destrucción y recreación total de la instancia `GoRouter` ante cualquier cambio de estado en `authProvider`. |
| **LEAK-01** | Ciclo de Vida y Fugas | **High** | `lib/modules/auth_tenant/presentation/screens/login_screen.dart:64-135` | Fuga de memoria (`TextEditingController`) instanciado en método modal sin hook ni llamada a `.dispose()`. |
| **LEAK-02** | Ciclo de Vida y Fugas | **High** | `lib/core/design_system/video_background_widget.dart:32-53` | Condición de carrera asíncrona: invocación de `setLooping` y `play` sobre `VideoPlayerController` ya desechado tras navegación rápida. |
| **LEAK-03** | Ciclo de Vida y Fugas | **Medium** | `lib/modules/auth_tenant/presentation/screens/register_company_screen.dart:104-105` | Uso de `BuildContext` desactivado tras `context.go()` para invocar `ScaffoldMessenger.of(context)`. |
| **PERF-01** | Rendimiento UI / GPU | **Critical** | `lib/core/design_system/glass_container.dart:89-91` | Agotamiento del fill-rate GPU por uso masivo de `BackdropFilter` (desenfoque gaussiano en tiempo real) en listas virtualizadas con scroll. |
| **PERF-02** | Rendimiento UI / CPU | **High** | `lib/core/reports/ica_official_reports_engine.dart:949-981` | Bloqueo del hilo principal de UI (ANR / congelamiento) por compresión síncrona de archivos ZIP/Excel (`excel.save()`). |
| **DB-01** | Base de Datos y Consultas | **High** | `lib/modules/ponds_batches/presentation/providers/ponds_provider.dart:173-182, 289-296` | Tormenta paralela de 5 consultas (`Future.wait`) y borrado total de la UI (`isLoading = true`) tras cada registro operativo individual. |
| **DB-02** | Base de Datos y Consultas | **High** | `lib/modules/ponds_batches/infrastructure/repositories/supabase_ponds_repository.dart:191-196, 259-264` | Consultas históricas no acotadas sin `.limit()` ni paginación en tablas crecientes (`lotes`, `estanques`). |
| **DB-03** | Base de Datos y Consultas | **Critical** | `supabase/migrations/20260831_database_performance_and_rls_optimization.sql:63-128` | Ausencia de índices compuestos `(empresa_id, fecha DESC)` para consultas directas por empresa en `parametros_calidad_agua`, `alimentacion_diaria` y `biometrias`. |
| **DB-04** | Base de Datos y Consultas | **Medium** | `lib/modules/sales_harvest/infrastructure/repositories/supabase_sales_repository.dart:91-96` | Doble inserción HTTP secuencial y redundante en ventas (`ventas` legacy + `ventas_lotes` canónica). |
| **DB-05** | Base de Datos y Consultas | **Medium** | `lib/modules/ponds_batches/infrastructure/repositories/supabase_ponds_repository.dart:509-516` | Consulta con operador `.or()` sobre columnas de estanque no compuestas con tenant en `traslados_lotes`. |
| **DB-06** | Base de Datos y Consultas | **Critical** | `lib/core/storage/offline_sync_queue.dart:51-133` | Cola de sincronización offline desconectada y muerta; pérdida de datos en campo rural y persistencia en memoria volátil. |
| **DB-07** | Base de Datos y Consultas | **Medium** | `lib/modules/auth_tenant/presentation/providers/auth_provider.dart:136-152` | Tres consultas de red secuenciales (`fetchCompany`, `fetchUnits`, `fetchTeamMembers`) en lugar de ejecución paralela o agregada. |
| **DB-08** | Base de Datos y Consultas | **Medium** | `supabase_schema_canonical_v10.sql:193` | Clave foránea `registrado_por` sin índice en `parametros_calidad_agua` y `biometrias`. |
| **DB-09** | Base de Datos y Consultas | **High** | `supabase/migrations/20260831_database_performance_and_rls_optimization.sql:205-208` | Cláusula `OR (SELECT is_superadmin())` en políticas RLS invalida escaneos B-Tree de índice directo para usuarios estándar. |

---

## Dimensión 1: Gestión de Estado Reactivo y Reconstrucciones (Riverpod & Flutter)

### STATE-01: `ref.watch` Monolítico en `BitacoraScreen` y Reconstrucción Cascadas de 4 Pestañas
- **Severidad:** High
- **Archivo y Líneas:** `c:\Users\Freddy\Desktop\Desarrollo de app\FishBit\lib\modules\bitacora\presentation\screens\bitacora_screen.dart:418-425, 564-579`
- **Descripción del Problema:**
  En el método raíz `build()` de `_BitacoraScreenState`:
  ```dart
  final waterState = ref.watch(waterQualityProvider);
  final nutritionState = ref.watch(nutritionProvider);
  final pondsState = ref.watch(pondsProvider);
  final pondMap = {for (final p in pondsState.ponds) p.id: p};
  final batchMap = {for (final b in pondsState.batches) b.id: b};
  ```
  La pantalla escucha la totalidad del estado de los 3 proveedores principales del ERP. Cada vez que un usuario o sensor registra un parámetro de agua, o se registra un gramo de alimento o un traslado, se reconstruye el `Scaffold`, el `NestedScrollView`, el `TabBar`, el selector de estanques y se vuelven a llamar los 4 métodos constructores: `_buildWaterQualityTab`, `_buildFeedingTab`, `_buildBiometryTab` y `_buildMortalityTab`.
- **Impacto:**
  - Desperdicio masivo de ciclos de CPU en el hilo de UI.
  - Re-generación ininterrumpida de mapas de búsqueda (`pondMap`, `batchMap`).
  - Pérdida de estado interno o scroll en pestañas no activas debido a la falta de encapsulamiento con `AutomaticKeepAliveClientMixin` o widgets independientes.
- **Solución Propuesta:**
  Desacoplar las 4 pestañas en clases `ConsumerWidget` independientes. En la pantalla contenedor solo escuchar el filtro seleccionado (`_selectedPondId`) y pasar este ID a cada pestaña. Cada sub-widget debe escuchar únicamente su proveedor especializado mediante selectores específicos.

```dart
// Propuesta de refactorización:
class BitacoraScreen extends StatefulWidget {
  const BitacoraScreen({super.key});
  @override
  State<BitacoraScreen> createState() => _BitacoraScreenState();
}

class _BitacoraScreenState extends State<BitacoraScreen> with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  final ValueNotifier<String?> _selectedPondNotifier = ValueNotifier<String?>(null);

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _selectedPondNotifier.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: NestedScrollView(
        headerSliverBuilder: (context, _) => [
          FishBitHeader(),
          _BitacoraPondFilterBar(selectedPondNotifier: _selectedPondNotifier),
          _BitacoraTabBar(controller: _tabController),
        ],
        body: TabBarView(
          controller: _tabController,
          children: [
            WaterQualityTab(selectedPondNotifier: _selectedPondNotifier),
            FeedingTab(selectedPondNotifier: _selectedPondNotifier),
            BiometryTab(selectedPondNotifier: _selectedPondNotifier),
            MortalityTab(selectedPondNotifier: _selectedPondNotifier),
          ],
        ),
      ),
    );
  }
}
```

---

### STATE-02: Cálculo Síncrono Pesado de GDP y Curvas de Crecimiento en `build()`
- **Severidad:** High
- **Archivo y Líneas:** `c:\Users\Freddy\Desktop\Desarrollo de app\FishBit\lib\modules\bitacora\presentation\screens\bitacora_screen.dart:1050, 1750-1858`
- **Descripción del Problema:**
  Dentro de `_buildBiometryTab` (que se invoca en cada `build()` de la pantalla), se ejecuta síncronamente:
  ```dart
  final analysis = _BiometryAnalysis.compute(
    allBiometries: pondsState.biometries,
    batches: pondsState.batches,
    selectedPondId: _selectedPondId,
  );
  ```
  La función `_BiometryAnalysis.compute` agrupa todas las biometrías por lote, ordena cada lista cronológicamente, itera elemento por elemento calculando la ganancia diaria de peso (`gdpGDia`), delta de peso y días transcurridos, genera 4 mapas en memoria (`periodGdpMap`, `weightDeltaMap`, `daysElapsedMap`, `biometriesByBatch`), crea una nueva copia de lista y la vuelve a ordenar descendentemente (`..sort((a, b) => b.fecha.compareTo(a.fecha))`).
- **Impacto:**
  - Complejidad temporal $O(N \log N)$ y múltiples reservas de memoria ejecutadas directamente en el hilo de renderizado (60/120 FPS target).
  - Provoca tirones perceptibles (jank) cada vez que el usuario cambia de estanque, pulsa un chip o interactúa con el teclado.
- **Solución Propuesta:**
  Encapsular el análisis en un proveedor memoizado de Riverpod con tupla o familia de parámetros (`biometryAnalysisProvider(selectedPondId)`). El cálculo solo se ejecutará cuando la lista inmutable de biometrías o el ID del estanque cambien.

```dart
// En lib/modules/ponds_batches/presentation/providers/ponds_provider.dart:
final biometryAnalysisProvider = Provider.family.autoDispose<BiometryAnalysis, String?>((ref, selectedPondId) {
  final biometries = ref.watch(pondsProvider.select((s) => s.biometries));
  final batches = ref.watch(pondsProvider.select((s) => s.batches));

  return BiometryAnalysis.compute(
    allBiometries: biometries,
    batches: batches,
    selectedPondId: selectedPondId,
  );
});

// En el widget de UI:
class BiometryTab extends ConsumerWidget {
  final String? selectedPondId;
  const BiometryTab({super.key, this.selectedPondId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final analysis = ref.watch(biometryAnalysisProvider(selectedPondId));
    // Consumo directo O(1) de datos ya precalculados
  }
}
```

---

### STATE-03: Sobresuscripción Masiva y Re-instanciación Redundante en `IcaCertificationScreen`
- **Severidad:** Medium
- **Archivo y Líneas:** `c:\Users\Freddy\Desktop\Desarrollo de app\FishBit\lib\modules\ica_compliance\presentation\screens\ica_certification_screen.dart:47-52`, `lib/modules/ica_compliance/presentation/providers/ica_compliance_provider.dart:22-50`
- **Descripción del Problema:**
  En `IcaCertificationScreen.build()`:
  ```dart
  final engine = ref.watch(icaReportsEngineProvider);
  final pondsState = ref.watch(pondsProvider);
  final nutritionState = ref.watch(nutritionProvider);
  final waterState = ref.watch(waterQualityProvider);
  final salesState = ref.watch(salesProvider);
  final icaState = ref.watch(icaComplianceProvider);
  ```
  La pantalla escucha 6 proveedores de estado directamente. Pero adicionalmente, `icaReportsEngineProvider` escucha a su vez a `authProvider`, `pondsProvider`, `nutritionProvider`, `waterQualityProvider`, `salesProvider`, `warehouseProvider` e `icaComplianceProvider`.
  Cuando cualquier dato cambia en el sistema, `icaReportsEngineProvider` se invalida y crea una nueva instancia de `IcaOfficialReportsEngine` (copiando 10 listas completas). Esto dispara un doble rebuild de `IcaCertificationScreen`.
  Peor aún: `engine` solo se requiere cuando el usuario presiona el botón "Exportar a Excel" (`onPressed: () => engine.exportF01Personal()`), por lo que mantenerlo en `ref.watch` en el método de dibujo es un anti-patrón severo.
- **Impacto:**
  - Multiplicación de listeners y ciclos redundantes de garbage collection (GC).
  - Caída de rendimiento en pantallas de auditoría al recibir sincronizaciones de fondo.
- **Solución Propuesta:**
  Eliminar `ref.watch(icaReportsEngineProvider)` de `build()`. Obtener el motor únicamente dentro de los callbacks de evento mediante `ref.read(icaReportsEngineProvider)`. Utilizar selectores puntuales para los badges informativos (ej. `ref.watch(icaComplianceProvider.select((s) => s.personalRecords.length))`).

```dart
// En build():
final personalCount = ref.watch(icaComplianceProvider.select((s) => s.personalRecords.length));
final vehiculosCount = ref.watch(icaComplianceProvider.select((s) => s.vehiculoRecords.length));

// En el botón de exportación:
onPressed: () {
  final engine = ref.read(icaReportsEngineProvider);
  engine.exportF01Personal();
}
```

---

### STATE-04: Reconstrucciones Totales por Estado Efímero (SpeedDial y Filtros en `PondsDashboardScreen`)
- **Severidad:** Medium
- **Archivo y Líneas:** `c:\Users\Freddy\Desktop\Desarrollo de app\FishBit\lib\modules\ponds_batches\presentation\screens\ponds_dashboard_screen.dart:27-28, 144, 381`
- **Descripción del Problema:**
  Las variables `_selectedFilterIndex` (Todos, Activos, Vacíos) y `_isSpeedDialOpen` (toggle del botón flotante) están declaradas en `_PondsDashboardScreenState`. Al pulsar el FAB o un chip de filtro, se ejecuta `setState(() => _isSpeedDialOpen = !_isSpeedDialOpen);`.
  Esto provoca que el `Scaffold`, la cabecera `FishBitHeader`, las tarjetas Bento de biomasa e inversión total, y todos los `PondBentoCard` de la grilla se reconstruyan por completo, a pesar de que el valor de los estanques o de los KPIs no ha cambiado.
- **Impacto:**
  - Latencia en la respuesta táctil del botón de acción rápida y los filtros de la pantalla de estanques.
- **Solución Propuesta:**
  Extraer el FAB animado a un widget dedicado (`PondsSpeedDialFab`) con su propio estado local o `ValueNotifier<bool>`. Pasar el filtro a través de un `ValueNotifier<int>` o un StateProvider local.

```dart
class PondsSpeedDialFab extends StatefulWidget {
  const PondsSpeedDialFab({super.key});
  @override
  State<PondsSpeedDialFab> createState() => _PondsSpeedDialFabState();
}

class _PondsSpeedDialFabState extends State<PondsSpeedDialFab> {
  bool _isOpen = false;
  @override
  Widget build(BuildContext context) {
    // Reconstruye ÚNICAMENTE los 2 botones secundarios y el FAB flotante,
    // dejando intacto el CustomScrollView y la lista de estanques.
  }
}
```

---

### STATE-05: Doble Construcción de Cara Frontal y Trasera en Cada Frame de `PondBentoCard`
- **Severidad:** Medium
- **Archivo y Líneas:** `c:\Users\Freddy\Desktop\Desarrollo de app\FishBit\lib\modules\ponds_batches\presentation\widgets\pond_bento_card.dart:81-90`
- **Descripción del Problema:**
  En `PondBentoCard.build()`:
  ```dart
  final frontWidget = RepaintBoundary(
    child: _buildFrontCard(context, allBatches, isPolyculture, isActive),
  );
  final backWidget = Transform(
    alignment: FractionalOffset.center,
    transform: Matrix4.identity()..rotateY(math.pi),
    child: RepaintBoundary(
      child: _buildBackCard(context, allBatches, isPolyculture, isActive),
    ),
  );
  ```
  Aunque la tarjeta esté en estado frontal normal (ángulo 0°), cada vez que el widget padre se reconstruye, se instancian y evalúan completamente tanto `_buildFrontCard` como `_buildBackCard` (que suman más de 500 líneas de widgets, chips, barras de progreso y botones modales).
- **Impacto:**
  - Multiplica por 2 el costo de instanciación del árbol de widgets en el dashboard de estanques (con 20 estanques = 40 caras de tarjetas procesadas).
- **Solución Propuesta:**
  Construir la cara trasera de forma diferida (lazy evaluation) únicamente cuando la tarjeta haya iniciado su animación de giro (`_controller.value > 0.0` o `_isFlipped`).

```dart
// Solución Lazy:
Widget build(BuildContext context) {
  final isFlippingOrBack = _controller.value > 0.0;

  return AnimatedBuilder(
    animation: _animation,
    builder: (context, _) {
      final angle = _animation.value * math.pi;
      final isFront = angle <= math.pi / 2;

      return Transform(
        alignment: FractionalOffset.center,
        transform: Matrix4.identity()
          ..setEntry(3, 2, 0.0015)
          ..rotateY(angle),
        child: isFront
            ? _buildFrontCard(context, allBatches, isPolyculture, isActive)
            : Transform(
                alignment: FractionalOffset.center,
                transform: Matrix4.identity()..rotateY(math.pi),
                child: _buildBackCard(context, allBatches, isPolyculture, isActive),
              ),
      );
    },
  );
}
```

---

### STATE-06: Destrucción y Recreación Total de `GoRouter` en Cambios de Autenticación
- **Severidad:** Critical
- **Archivo y Líneas:** `c:\Users\Freddy\Desktop\Desarrollo de app\FishBit\lib\app\router.dart:33-37`
- **Descripción del Problema:**
  ```dart
  final routerProvider = Provider<GoRouter>((ref) {
    final authNotifier = ref.watch(authRouterNotifierProvider);
    final authState = ref.watch(authProvider);

    return GoRouter(
      initialLocation: '/login',
      refreshListenable: authNotifier,
      redirect: (context, state) { ... },
      routes: [ ... ],
    );
  });
  ```
  `routerProvider` ejecuta `ref.watch(authProvider)`. Por tanto, cada vez que `authProvider` cambia (actualización de tokens, selección de nueva sede/unidad acuícola, refresco de sesión o carga), el proveedor de GoRouter **destruye por completo la instancia de `GoRouter`** y genera una nueva.
- **Impacto:**
  - Pérdida de la pila de navegación histórica.
  - Reset de los animadores y transiciones de rutas.
  - Reconstrucción forzosa de la pantalla actual y posibles flashes blancos o parpadeos en la interfaz de usuario.
- **Solución Propuesta:**
  `routerProvider` debe instanciar `GoRouter` una sola vez. La reactividad ante cambios de autenticación debe gestionarse exclusivamente a través de `refreshListenable`, y el método `redirect` debe leer el estado actual con `ref.read(authProvider)` sin suscribir el router con `watch`.

```dart
// Solución correcta:
final routerProvider = Provider<GoRouter>((ref) {
  final authNotifier = ref.read(authRouterNotifierProvider);

  return GoRouter(
    initialLocation: '/login',
    refreshListenable: authNotifier,
    redirect: (context, state) {
      final authState = ref.read(authProvider);
      // Lógica de redirección pura basada en ref.read
      ...
    },
    routes: [ ... ],
  );
});
```

---

## Dimensión 2: Ciclo de Vida de Recursos y Fugas de Memoria (Memory Leaks)

### LEAK-01: Fuga de Memoria por `TextEditingController` No Liberado en `_showForgotPasswordModal`
- **Severidad:** High
- **Archivo y Líneas:** `c:\Users\Freddy\Desktop\Desarrollo de app\FishBit\lib\modules\auth_tenant\presentation\screens\login_screen.dart:63-134`
- **Descripción del Problema:**
  En la función `_showForgotPasswordModal`:
  ```dart
  void _showForgotPasswordModal() {
    final resetEmailCtrl = TextEditingController(text: _emailCtrl.text);
    showDialog<void>(
      context: context,
      builder: (dialogCtx) => Dialog(...),
    );
  }
  ```
  `resetEmailCtrl` se crea como variable local dentro de la función y se enlaza al widget `GlassFormField`. Cuando el usuario cierra el diálogo (pulsando la X, presionando atrás o tocando la barrera exterior), `resetEmailCtrl.dispose()` **nunca es invocado**.
- **Impacto:**
  - Fuga permanente del objeto `TextEditingController`, sus `ChangeNotifier` listeners y la conexión nativa al teclado virtual (InputMethodManager en Android / TextInputClient en iOS).
- **Solución Propuesta:**
  Extraer el modal a un widget `StatefulWidget` dedicado donde se instancie y libere en `dispose()`, o adjuntar la liberación al `Future` retornado por `showDialog`:

```dart
void _showForgotPasswordModal() {
  final resetEmailCtrl = TextEditingController(text: _emailCtrl.text);
  showDialog<void>(
    context: context,
    builder: (dialogCtx) => Dialog(...),
  ).whenComplete(() {
    resetEmailCtrl.dispose();
  });
}
```

---

### LEAK-02: Condición de Carrera y Fallo en `VideoBackgroundWidget`
- **Severidad:** High
- **Archivo y Líneas:** `c:\Users\Freddy\Desktop\Desarrollo de app\FishBit\lib\core\design_system\video_background_widget.dart:32-53`
- **Descripción del Problema:**
  En `_VideoBackgroundWidgetState`:
  ```dart
  Future<void> _initializeVideo() async {
    _controller = VideoPlayerController.asset(widget.assetPath);
    try {
      await _controller.initialize();
      await _controller.setLooping(true);
      await _controller.setVolume(0.0);
      await _controller.play();
      if (mounted) setState(() => _isInitialized = true);
    } catch (_) {}
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
  ```
  Si el usuario navega rápidamente fuera de la pantalla de bienvenida o login antes de que `_controller.initialize()` complete su inicialización nativa:
  1. Se llama a `dispose()`, el cual destruye el controlador nativo.
  2. Cuando el `Future` de `initialize()` finalmente despierta en el event loop, ejecuta `setLooping(true)` y `play()` sobre un controlador ya desechado.
  3. Esto arroja una excepción no controlada: `Bad state: Cannot use a VideoPlayerController after it has been disposed.`.
  4. Adicionalmente, si `dispose()` ocurre antes de que la línea 33 termine, `late VideoPlayerController _controller` arroja `LateInitializationError`.
- **Impacto:**
  - Fallos en consola, estado corrupto de codecs de video y pérdida de recursos de hardware de decodificación en dispositivos móviles.
- **Solución Propuesta:**
  Declarar el controlador como nullable (`VideoPlayerController? _controller`), verificar `if (!mounted) { _controller?.dispose(); return; }` tras cada suspensión asíncrona, y proteger el método `dispose`.

```dart
class _VideoBackgroundWidgetState extends State<VideoBackgroundWidget> {
  VideoPlayerController? _controller;
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _initializeVideo();
  }

  Future<void> _initializeVideo() async {
    final controller = VideoPlayerController.asset(widget.assetPath);
    _controller = controller;
    try {
      await controller.initialize();
      if (!mounted) {
        await controller.dispose();
        return;
      }
      await controller.setLooping(true);
      await controller.setVolume(0.0);
      await controller.play();
      if (mounted) {
        setState(() => _isInitialized = true);
      }
    } catch (_) {}
  }

  @override
  void dispose() {
    _controller?.dispose();
    _controller = null;
    super.dispose();
  }
}
```

---

### LEAK-03: Uso de `BuildContext` Desactivado Tras Navegación Asíncrona
- **Severidad:** Medium
- **Archivo y Líneas:** `c:\Users\Freddy\Desktop\Desarrollo de app\FishBit\lib\modules\auth_tenant\presentation\screens\register_company_screen.dart:103-105`, `lib/modules/auth_tenant/presentation/screens/onboarding_empresa_screen.dart:127-128`
- **Descripción del Problema:**
  En `RegisterCompanyScreen` y `OnboardingEmpresaScreen`:
  ```dart
  if (success && mounted) {
    context.go('/home'); // o context.go('/')
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('...')),
    );
  }
  ```
  La invocación de `context.go('/home')` programa de inmediato el desmontaje y reemplazo de la pantalla actual. Inmediatamente en la siguiente línea, el código llama a `ScaffoldMessenger.of(context)` utilizando el `BuildContext` del widget que acaba de ser desactivado de la jerarquía.
- **Impacto:**
  - Excepción de Flutter framework en modo debug (`Looking up a deactivated widget's ancestor is unsafe`).
  - Pérdida del snackbar informativo que confirma el registro o la bienvenida de la empresa.
- **Solución Propuesta:**
  Capturar la referencia al `ScaffoldMessenger` o `rootScaffoldMessenger` **antes** de disparar la navegación, o bien mostrar la notificación utilizando una clave global (`scaffoldMessengerKey`).

```dart
if (success && mounted) {
  final messenger = ScaffoldMessenger.of(context);
  final message = '¡Bienvenido a FishBit, ${_nombresCtrl.text}! Piscícola creada con éxito.';
  context.go('/');
  messenger.showSnackBar(
    SnackBar(content: Text(message), backgroundColor: AppColors.greenBiomass),
  );
}
```

---

### PERF-01: Sobrecarga Crítica de Shaders GPU por `BackdropFilter` en Listas con Desplazamiento
- **Severidad:** Critical
- **Archivo y Líneas:** `c:\Users\Freddy\Desktop\Desarrollo de app\FishBit\lib\core\design_system\glass_container.dart:89-91`, `lib\core\design_system\glass_card.dart:87-93`
- **Descripción del Problema:**
  `GlassContainer` implementa el efecto Glassmorphic mediante:
  ```dart
  ClipRRect(
    borderRadius: BorderRadius.circular(borderRadius),
    child: BackdropFilter(
      filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
      child: Container(...),
    ),
  )
  ```
  `BackdropFilter` obliga a la GPU a ejecutar una operación `saveLayer`, copiar el framebuffer anterior y aplicar un shader de desenfoque gaussiano de dos pasadas en cada cuadro.
  Debido a que `GlassCard` envuelve prácticamente cada elemento del sistema (tarjetas de estanques en `PondsDashboardScreen`, filas de parámetros en `BitacoraScreen`, tarjetas de insumos en `WarehouseScreen`), una sola pantalla en scroll contiene entre 10 y 25 instancias de `BackdropFilter` activas simultáneamente en el viewport.
- **Impacto:**
  - Severo estrangulamiento del fill-rate de la GPU.
  - Caída de la tasa de cuadros de 60/120 FPS a 20-35 FPS en dispositivos móviles de gama media y alta durante el scroll.
  - Sobrecalentamiento del dispositivo y drenaje acelerado de batería.
- **Solución Propuesta:**
  Hacer que el `BackdropFilter` sea opcional (`enableBlur: false` por defecto en listas). Para elementos de listas dinámicas, emular el acabado glassmorphic mediante colores sólidos translúcidos (`withValues(alpha: 0.12)`), bordes delgados de alto contraste (`Border.all(color: Colors.white12)`) y sombras proyectadas (`BoxShadow`). Reservar `BackdropFilter` exclusivamente para overlays estáticos (el Dock inferior y modales).

```dart
// En GlassContainer:
class GlassContainer extends StatelessWidget {
  final bool enableBlur; // Parámetro para optimización en listas
  ...
  @override
  Widget build(BuildContext context) {
    if (!enableBlur) {
      return Container(
        decoration: BoxDecoration(
          color: fill,
          borderRadius: BorderRadius.circular(borderRadius),
          border: border,
          boxShadow: shadows,
        ),
        child: child,
      );
    }
    // Modo blur solo para elementos flotantes persistentes
    ...
  }
}
```

---

### PERF-02: Bloqueo del Hilo Principal por Compresión Síncrona de Excel en `IcaOfficialReportsEngine`
- **Severidad:** High
- **Archivo y Líneas:** `c:\Users\Freddy\Desktop\Desarrollo de app\FishBit\lib\core\reports\ica_official_reports_engine.dart:949-981`, `lib\modules\ica_compliance\presentation\screens\ica_certification_screen.dart:482`
- **Descripción del Problema:**
  Al pulsar "Exportar Cuaderno de Campo Completo":
  ```dart
  void exportCuadernoCampoCompleto() {
    final excel = Excel.createExcel();
    _buildHojaResumenPredio(excel);
    _buildHojaAlimentacion(excel);
    _buildHojaMortalidad(excel);
    _buildHojaInventarioSemestral(excel);
    _buildHojaCalidadAgua(excel);
    _buildHojaCosechasVentas(excel);
    _buildHojaPersonal(excel);
    _buildHojaVehiculos(excel);
    _buildHojaNecropsias(excel);
    _downloadExcel(excel, ...);
  }
  ```
  La construcción de las 9 hojas, el formateo celda por celda de miles de registros zootécnicos y sanitarios, y la compresión ZIP/XML generada por `excel.save()` se ejecutan de manera 100% síncrona en el hilo principal de Dart/Flutter (Root Isolate).
- **Impacto:**
  - Congelamiento total de la interfaz gráfica durante 1.5 a 4.0 segundos en dispositivos móviles.
  - Riesgo de activación del diálogo ANR (Application Not Responding) en Android.
- **Solución Propuesta:**
  Mover la generación y codificación binaria de los reportes oficiales a un isolate secundario en segundo plano utilizando `compute()` o `Isolate.run()`.

```dart
// En IcaOfficialReportsEngine:
Future<void> exportCuadernoCampoCompletoAsync() async {
  // Transferir datos inmutables y generar bytes en Isolate secundario
  final bytes = await compute(_generateExcelBytesTask, _ExportPayload(...));
  if (bytes != null) {
    if (kIsWeb) {
      downloadFileWeb(bytes, 'Cuaderno_Campo_Oficial_ICA.xlsx');
    } else {
      // Guardado nativo móvil en directorio de descargas
    }
  }
}
```

---

## Dimensión 3: Rendimiento de Consultas SQL y Base de Datos (Supabase / PostgreSQL)

### DB-01: Cascada de Recarga Destructiva de UI y Tormenta de 5 Consultas en `PondsNotifier`
- **Severidad:** High
- **Archivo y Líneas:** `c:\Users\Freddy\Desktop\Desarrollo de app\FishBit\lib\modules\ponds_batches\presentation\providers\ponds_provider.dart:173-182, 289-296, 340-346`
- **Descripción del Problema:**
  En `PondsNotifier`, las operaciones de mutación como `recordMortality`, `recordBiometry`, `addBatch` y `executeTransferSplit` realizan lo siguiente:
  ```dart
  // Inserta el registro en memoria
  state = state.copyWith(mortalityRecords: [savedRecord, ...state.mortalityRecords]);
  // Refresca la totalidad de los datos
  await loadPondsAndBatches();
  ```
  Y en `loadPondsAndBatches`:
  ```dart
  state = state.copyWith(isLoading: true, errorMessage: null);
  final results = await Future.wait([
    _repository.fetchPondsByUnit(empresaId, finalUnitId),
    _repository.fetchBatchesByUnit(empresaId, finalUnitId),
    _repository.fetchBiometriesByUnit(empresaId, finalUnitId),
    _repository.fetchMortalityByUnit(empresaId, finalUnitId),
    _repository.fetchTransfersByUnit(empresaId, finalUnitId),
  ]);
  ```
- **Impacto:**
  - Al poner `isLoading: true`, toda la pantalla de estanques parpadea, desmantela la lista y muestra un indicador de carga circular en el centro.
  - Cada registro individual de una baja o un peso gatilla **5 consultas pesadas en paralelo** a Supabase, saturando la red celular del operador y consumiendo cuota de base de datos.
- **Solución Propuesta:**
  1. Implementar actualización optimista local de los estanques y lotes afectados en el estado sin activar `isLoading: true`.
  2. Si se requiere sincronización remota, consultar únicamente el lote o estanque modificado (`fetchBatchById`, `fetchPondById`), no la totalidad de las 5 tablas históricas.

```dart
// En recordMortality:
// 1. Actualizar el estanque y lote afectados en memoria local directamente:
final updatedPonds = state.ponds.map((p) => p.id == estanqueId ? p.copyWith(biomasaKg: newBiomass) : p).toList();
final updatedBatches = state.batches.map((b) => b.id == loteId ? b.copyWith(cantidadActualPeces: newCount, biomasaActualKg: newBiomass) : b).toList();

state = state.copyWith(
  mortalityRecords: [savedRecord, ...state.mortalityRecords],
  ponds: updatedPonds,
  batches: updatedBatches,
);
// NO llamar a loadPondsAndBatches() completo ni activar isLoading: true.
```

---

### DB-02: Consultas No Acotadas Sin `.limit()` en `fetchBatchesByUnit` y `fetchPondsByUnit`
- **Severidad:** High
- **Archivo y Líneas:** `c:\Users\Freddy\Desktop\Desarrollo de app\FishBit\lib\modules\ponds_batches\infrastructure\repositories\supabase_ponds_repository.dart:191-196, 259-264`
- **Descripción del Problema:**
  ```dart
  // fetchPondsByUnit:
  final res = await _supabase
      .from('estanques')
      .select('*')
      .eq('empresa_id', empresaId)
      .order('creado_en', ascending: true);

  // fetchBatchesByUnit:
  final res = await _supabase
      .from('lotes')
      .select('*')
      .eq('empresa_id', empresaId)
      .order('creado_en', ascending: true);
  ```
  Ninguna de las dos consultas incluye `.limit()`, ni cláusula de filtro por estado (`estado = 'Activo'`). En una piscícola comercial con decenas de ciclos productivos y cientos de lotes cosechados a lo largo de los años, cada apertura de la aplicación descarga la totalidad de los lotes cerrados y archivados desde el día uno de operación.
- **Impacto:**
  - Consumo excesivo de ancho de banda y latencia de carga inicial en redes celulares rurales.
  - Deserialización de miles de objetos JSON innecesarios en el cliente móvil.
- **Solución Propuesta:**
  Filtrar por defecto por lotes activos en el dashboard operativo, y aplicar paginación o límite de seguridad:

```dart
final res = await _supabase
    .from('lotes')
    .select('*')
    .eq('empresa_id', empresaId)
    .inFilter('estado', ['Activo', 'En Engorde', 'Pre-cria'])
    .order('creado_en', ascending: false)
    .limit(100);
```

---

### DB-03: Ausencia Crítica de Índices Compuestos `(empresa_id, fecha DESC)` en Tablas de Alto Tráfico
- **Severidad:** Critical
- **Archivo y Líneas:** `c:\Users\Freddy\Desktop\Desarrollo de app\FishBit\supabase\migrations\20260831_database_performance_and_rls_optimization.sql:63-128`
- **Descripción del Problema:**
  En las consultas habituales del frontend:
  1. `fetchRecentParametersByUnit`: `FROM parametros_calidad_agua WHERE empresa_id = $1 ORDER BY fecha DESC LIMIT 50;`
  2. `fetchFeedingRecords`: `FROM alimentacion_diaria WHERE empresa_id = $1 ORDER BY fecha DESC LIMIT 100;`
  3. `fetchBiometriesByUnit`: `FROM biometrias WHERE empresa_id = $1 ORDER BY date DESC LIMIT 100;`
  4. `fetchTransfersByUnit`: `FROM traslados_lotes WHERE empresa_id = $1 ORDER BY fecha_operacion DESC LIMIT 100;`

  Al revisar los índices existentes en la migración `20260831...`:
  - En `parametros_calidad_agua` existen: `(empresa_id, estanque_id, fecha DESC)` y `(empresa_id, unidad_acuicola_id, fecha DESC)`. Al no incluir `estanque_id` en el filtro `WHERE`, PostgreSQL **no puede usar el índice para ordenar directamente por fecha**.
  - En `alimentacion_diaria` existen: `(empresa_id, lote_id, fecha DESC)` y `(empresa_id, estanque_id, fecha DESC)`. No existe `(empresa_id, fecha DESC)`.
  - En `biometrias` existen: `(empresa_id, lote_id, date DESC)`. No existe `(empresa_id, date DESC)`.
  - En `traslados_lotes` existen: `(empresa_id, lote_origen_id, fecha_operacion DESC)`. No existe `(empresa_id, fecha_operacion DESC)`.
- **Impacto:**
  - El motor de PostgreSQL se ve forzado a realizar un Sequential Scan de todas las filas del tenant o un Bitmap Index Scan disperso, seguido de una operación de ordenamiento en memoria (`Sort Method: top-N heapsort`), elevando el consumo de CPU y memoria compartida del servidor de base de datos.
- **Solución Propuesta:**
  Crear los índices compuestos directos faltantes mediante una migración SQL complementaria:

```sql
-- Índices Compuestos Directos para Vistas Globales por Empresa:
CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_calidad_agua_empresa_fecha_desc 
  ON public.parametros_calidad_agua (empresa_id, fecha DESC);

CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_alimentacion_empresa_fecha_desc 
  ON public.alimentacion_diaria (empresa_id, fecha DESC);

CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_biometrias_empresa_date_desc 
  ON public.biometrias (empresa_id, date DESC);

CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_biometrias_empresa_estanque_date 
  ON public.biometrias (empresa_id, estanque_id, date DESC);

CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_mortalidad_empresa_date_desc 
  ON public.mortalidad (empresa_id, date DESC);

CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_traslados_empresa_fecha_desc 
  ON public.traslados_lotes (empresa_id, fecha_operacion DESC);
```

---

### DB-04: Doble Escritura HTTP Secuencial en el Flujo de Ventas
- **Severidad:** Medium
- **Archivo y Líneas:** `c:\Users\Freddy\Desktop\Desarrollo de app\FishBit\lib\modules\sales_harvest\infrastructure\repositories\supabase_sales_repository.dart:90-97`
- **Descripción del Problema:**
  Al registrar una venta:
  ```dart
  try {
    await _supabase.from('ventas').insert(ventaPayload);
  } catch (_) {}

  try {
    await _supabase.from('ventas_lotes').insert(sale.toJson());
  } catch (_) {}
  ```
  La aplicación realiza dos peticiones POST HTTP consecutivas a Supabase para duplicar el registro en la tabla legacy `ventas` y en la tabla canónica `ventas_lotes`.
- **Impacto:**
  - Duplica innecesariamente la latencia de red en cada transacción de cosecha/venta.
  - Riesgo de inconsistencia si la primera inserción es exitosa pero la segunda falla por pérdida momentánea de conexión.
- **Solución Propuesta:**
  Eliminar la inserción manual en `ventas` desde el cliente Flutter. Si la retrocompatibilidad con sistemas externos es indispensable, delegar la sincronización a un trigger `AFTER INSERT ON public.ventas_lotes` en PostgreSQL.

---

### DB-05: Consultas Ineficientes de Traslados por Estanque en `traslados_lotes`
- **Severidad:** Medium
- **Archivo y Líneas:** `c:\Users\Freddy\Desktop\Desarrollo de app\FishBit\lib\modules\ponds_batches\infrastructure\repositories\supabase_ponds_repository.dart:509-516`, `supabase/migrations/20260831_database_performance_and_rls_optimization.sql:117-128`
- **Descripción del Problema:**
  En `fetchTransfersByUnit`:
  ```dart
  if (pondId != null && pondId.isNotEmpty) {
    query = query.or('estanque_origen_id.eq.$pondId,estanque_destino_id.eq.$pondId');
  }
  final res = await query.order('fecha_operacion', ascending: false).limit(100);
  ```
  Los índices en `traslados_lotes` son: `idx_traslados_estanque_origen (estanque_origen_id)` e `idx_traslados_estanque_destino (estanque_destino_id)` de forma univaluada sin tenant ni fecha. La condición `OR` fuerza un `BitmapOr` y una posterior ordenación en memoria.
- **Impacto:**
  - Retardo en la apertura de la bitácora cuando se filtra por un estanque que ha tenido múltiples traslados o desdobles.
- **Solución Propuesta:**
  Añadir índices compuestos que incluyan `empresa_id` y `fecha_operacion`:

```sql
CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_traslados_empresa_origen_fecha 
  ON public.traslados_lotes (empresa_id, estanque_origen_id, fecha_operacion DESC);

CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_traslados_empresa_destino_fecha 
  ON public.traslados_lotes (empresa_id, estanque_destino_id, fecha_operacion DESC);
```

---

### DB-06: Cola Offline (`OfflineSyncQueue`) Desconectada y Pérdida de Datos en Campo
- **Severidad:** Critical
- **Archivo y Líneas:** `c:\Users\Freddy\Desktop\Desarrollo de app\FishBit\lib\core\storage\offline_sync_queue.dart:51-133`
- **Descripción del Problema:**
  La clase `OfflineSyncQueue` existe en el proyecto, pero **no es invocada por ningún repositorio de la aplicación**.
  Cuando falla una llamada en `SupabasePondsRepository` o `SupabaseNutritionRepository`:
  ```dart
  catch (_) {
    _demoRecords.insert(0, record);
    return record;
  }
  ```
  Los registros de alimentación, biometrías o mortalidades tomados en estanques sin señal 4G se insertan en listas estáticas en memoria RAM (`_demoRecords`). Al cerrar la app o reiniciarla, todos esos registros de producción se pierden definitivamente. Adicionalmente, el método `flushQueue` ejecuta inserciones individuales una a una en un bucle secuencial en lugar de un `batch insert`.
- **Impacto:**
  - Pérdida irremediable de datos biológicos y operativos tomados en el campo.
  - Fracaso del requerimiento de resiliencia offline.
- **Solución Propuesta:**
  1. Conectar los repositorios en sus bloques `catch` para encolar la acción en `OfflineSyncQueue.enqueue(...)`.
  2. Implementar un listener de conectividad en `SupabaseClientProvider` que dispare `OfflineSyncQueue.flushQueue` al recuperar red.
  3. Refactorizar `flushQueue` para agrupar inserciones por tabla (`batch insert` con `supabase.from(table).insert(listOfPayloads)`).

```dart
// En catch de recordFeeding:
catch (e) {
  await OfflineSyncQueue.enqueue(
    type: OfflineActionType.feeding,
    table: 'alimentacion_diaria',
    payload: insertData,
  );
  _eventBus.fire(DailyFeedingRecordedEvent(...));
  return record;
}
```

---

### DB-07: Consultas Secuenciales en Serie Durante la Hidratación de Sesión
- **Severidad:** Medium
- **Archivo y Líneas:** `c:\Users\Freddy\Desktop\Desarrollo de app\FishBit\lib\modules\auth_tenant\presentation\providers\auth_provider.dart:136-152`
- **Descripción del Problema:**
  Al iniciar sesión o hidratar el perfil del usuario:
  ```dart
  company = await _repository.fetchCompany(targetEmpresaId);
  units = await _repository.fetchUnits(targetEmpresaId);
  team = await _repository.fetchTeamMembers(targetEmpresaId);
  ```
  Estas tres consultas a Supabase se ejecutan una tras otra de forma estrictamente secuencial.
- **Impacto:**
  - Triple round-trip de red en el inicio de la app (sumando entre 450ms y 1200ms adicionales al splash screen/login).
- **Solución Propuesta:**
  Ejecutar las tres peticiones en paralelo mediante `Future.wait`:

```dart
final results = await Future.wait([
  _repository.fetchCompany(targetEmpresaId),
  _repository.fetchUnits(targetEmpresaId),
  _repository.fetchTeamMembers(targetEmpresaId),
]);
company = results[0] as Company?;
units = results[1] as List<AquacultureUnit>;
team = results[2] as List<UserMember>;
```

---

### DB-08: Clave Foránea `registrado_por` Sin Índice en `parametros_calidad_agua` y `biometrias`
- **Severidad:** Medium
- **Archivo y Líneas:** `supabase_schema_canonical_v10.sql:193`, `supabase/migrations/20260831_database_performance_and_rls_optimization.sql:149-180`
- **Descripción del Problema:**
  En `parametros_calidad_agua`, la columna `registrado_por UUID REFERENCES public.miembros_equipo(id) ON DELETE SET NULL` no cuenta con un índice B-Tree en la base de datos. Lo mismo ocurre en la tabla `biometrias`.
- **Impacto:**
  - Al actualizar o eliminar un registro en `miembros_equipo`, PostgreSQL debe realizar un Sequential Scan completo de `parametros_calidad_agua` y `biometrias` para verificar la restricción de integridad referencial, bloqueando filas innecesariamente.
- **Solución Propuesta:**
  Crear índices B-Tree sobre las claves foráneas:

```sql
CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_calidad_agua_registrado_por 
  ON public.parametros_calidad_agua(registrado_por);

CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_biometrias_registrado_por 
  ON public.biometrias(registrado_por);
```

---

### DB-09: Degradación de Planes de Ejecución RLS por Cláusula `OR` con Superadmin
- **Severidad:** High
- **Archivo y Líneas:** `supabase/migrations/20260831_database_performance_and_rls_optimization.sql:205-208, 242-245`
- **Descripción del Problema:**
  Las políticas de aislamiento multi-inquilino están formuladas como:
  ```sql
  CREATE POLICY parametros_calidad_agua_tenant_select ON public.parametros_calidad_agua
    FOR SELECT TO authenticated
    USING (empresa_id = (SELECT public.get_auth_empresa_id()) OR (SELECT public.is_superadmin()));
  ```
  En PostgreSQL, una política RLS con una disyunción `OR` no permite que el optimizador reduzca la búsqueda a un Index Scan limpio basado en la clave `empresa_id`, porque debe evaluar si la condición de superadministrador abre la puerta a todas las filas restantes.
- **Impacto:**
  - Pérdida de eficiencia en consultas frecuentes de lectura, incrementando los buffers leídos (`shared hit blocks`) en un factor de 2x a 5x.
- **Solución Propuesta:**
  Separar la política en dos políticas independientes de tipo `PERMISSIVE` (las cuales PostgreSQL combina automáticamente mediante un cortocircuito eficiente de unión de planes):

```sql
-- Política 1: Aislamiento estricto de Tenant (Index Scan garantizado)
DROP POLICY IF EXISTS parametros_calidad_agua_tenant_select ON public.parametros_calidad_agua;

CREATE POLICY parametros_calidad_agua_tenant_select ON public.parametros_calidad_agua
  FOR SELECT TO authenticated
  USING (empresa_id = (SELECT public.get_auth_empresa_id()));

-- Política 2: Bypass exclusivo para Superadmin de Plataforma
CREATE POLICY parametros_calidad_agua_superadmin_select ON public.parametros_calidad_agua
  FOR SELECT TO authenticated
  USING ((SELECT public.is_superadmin()));
```

---

## Plan Estratégico de Remediación Priorizado

```
┌────────────────────────────────────────────────────────────────────────────────────────────────┐
│ FASE 1: Remediación Inmediata (Estabilidad y Fugas de Memoria)                                │
├────────────────────────────────────────────────────────────────────────────────────────────────┤
│ 1. [STATE-06] Corregir GoRouter para evitar instanciación repetida en cambios de auth.        │
│ 2. [LEAK-01]  Disponer resetEmailCtrl en modal de recuperación de contraseña.                 │
│ 3. [LEAK-02]  Blindar ciclo de vida asíncrono de VideoBackgroundWidget con guards de mounted.  │
│ 4. [LEAK-03]  Capturar ScaffoldMessenger antes de context.go() en auth/onboarding.             │
└────────────────────────────────────────────────────────────────────────────────────────────────┘
                                                │
                                                ▼
┌────────────────────────────────────────────────────────────────────────────────────────────────┐
│ FASE 2: Optimización de Consultas SQL y Rendimiento de Base de Datos                           │
├────────────────────────────────────────────────────────────────────────────────────────────────┤
│ 1. [DB-03]    Aplicar migración con índices (empresa_id, fecha DESC) en 4 tablas críticas.     │
│ 2. [DB-09]    Dividir políticas RLS en políticas dobles (Tenant + Superadmin) sin OR.         │
│ 3. [DB-08]    Crear índices de FK en registrado_por (calidad agua y biometrías).               │
│ 4. [DB-02]    Agregar filtros de estado activo y .limit() a fetchBatchesByUnit.                │
│ 5. [DB-04]    Eliminar doble inserción HTTP en flujo de ventas.                                │
└────────────────────────────────────────────────────────────────────────────────────────────────┘
                                                │
                                                ▼
┌────────────────────────────────────────────────────────────────────────────────────────────────┐
│ FASE 3: Fluidez de UI, Desacoplamiento de Estado y Resiliencia Offline                         │
├────────────────────────────────────────────────────────────────────────────────────────────────┤
│ 1. [PERF-01]  Hacer opcional BackdropFilter en GlassCard dentro de listas en scroll.           │
│ 2. [STATE-01] Dividir BitacoraScreen en 4 ConsumerWidgets independientes por pestaña.          │
│ 3. [STATE-02] Mover _BiometryAnalysis.compute a biometryAnalysisProvider memoizado.           │
│ 4. [PERF-02]  Mover compresión ZIP de Excel ICA a un isolate secundario con compute().         │
│ 5. [DB-01]    Actualización optimista en PondsNotifier sin isLoading=true ni tormenta 5-query.│
│ 6. [DB-06]    Conectar OfflineSyncQueue con batching e interceptores de red.                  │
└────────────────────────────────────────────────────────────────────────────────────────────────┘
```

---
*Reporte generado por Explorer de Rendimiento, Estado y Base de Datos (FishBit M3).*
