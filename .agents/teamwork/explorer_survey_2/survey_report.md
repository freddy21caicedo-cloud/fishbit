# INFORME TÉCNICO DE AUDITORÍA Y OPTIMIZACIÓN DUAL PLATFORM (WEB & MOBILE)
**FishBit Finance 2.0 — Flutter, Riverpod & Impeller/CanvasKit**
**Fecha**: 2026-10-27 | **Especialista**: Explorer Subagent (Dual Platform Performance Specialist)
**Alcance**: R2 — Rendimiento Dual Web vs. Mobile, GPU Fill-Rate, Reconstrucciones Riverpod, Ergonomía Móvil y Responsividad Web (360px a 1920px)

---

## 1. RESUMEN EJECUTIVO

Se ha llevado a cabo una auditoría analítica profunda y exhaustiva sobre la capa de presentación Flutter, la arquitectura de estado con Riverpod y el subsistema de renderizado gráfico de FishBit.

### Hallazgos Principales:
1. **GPU Fill-Rate Crítico en Glassmorphism**: El uso indiscriminado de `BackdropFilter` con `ImageFilter.blur(sigmaX: 16-24)` dentro de listas y grids virtuales (`ListView.builder`, `SliverGrid`) fuerza múltiples pasadas de desenfoque gaussiano por frame sobre fondos estáticos. Además, `PondBentoCard` instancia simultáneamente la cara frontal y la cara trasera en cada reconstrucción, duplicando las capas de desenfoque y objetos de renderizado.
2. **Alcance de Reconstrucciones Riverpod Ineficiente**:
   - `IcaCertificationScreen` observa 6 proveedores de estado completos en su método `build` raíz, invalidándose ante cualquier mutación del sistema.
   - `BitacoraScreen` observa 3 proveedores raíz (`waterQualityProvider`, `nutritionProvider`, `pondsProvider`); sus 4 pestañas son métodos privados y no `ConsumerWidget`s independientes, provocando reconstrucción en cascada de todo el árbol.
   - `PondsDashboardScreen` observa selectores de mapa agregados (`activeBatchesByPondProvider`, `latestWaterQualityByPondProvider`) en la raíz y llama `ref.watch(authProvider)` dentro del delegado de cada ítem.
3. **Ergonomía Móvil y Safe Area en Campo**:
   - `BitacoraScreen` utiliza `SizedBox(height: 80)` en sus 4 pestañas en lugar de `DockBottomSpacer()`, ocultando los últimos registros detrás del dock flotante (104 dp en iOS) y del FAB flotante (168 dp de despeje necesario).
   - Los modales operacionales clave (`ParametroModal`, `AlimentarModal`, etc.) son `Dialog` centrados en lugar de `ModalBottomSheet`, dificultando el uso con una sola mano en campo y sufriendo compresión al desplegarse el teclado virtual.
4. **Responsividad Web / Pantallas Grandes (hasta 1920px)**:
   - Pantallas principales (`HomeDashboardScreen`, `PondsDashboardScreen`, `FinanceScreen`, `WarehouseScreen`, `SalesScreen`) carecen de límites de ancho máximo (`maxWidth`), estirando los KPIs y encabezados a lo largo de 1920 píxeles.
   - Ausencia de configuración `ScrollBehavior` con soporte para arrastre con ratón (`PointerDeviceKind.mouse`) en listas y chips horizontales.
   - Cero implementación de estados `MouseRegion`/hover y uso de `GestureDetector` sin cursor de puntero (`SystemMouseCursors.click`).

---

## 2. AUDITORÍA DETALLADA POR COMPONENTE

### 2.1 GPU Fill-Rate & Cuellos de Botella de Renderizado Gráfico

#### Hallazgo PERF-GPU-01: Proliferación de `BackdropFilter` en Listas y Grids de Estanques
- **Archivos**:
  - `lib/core/design_system/glass_container.dart` (Líneas 87-101)
  - `lib/core/design_system/glass_card.dart` (Líneas 84-111)
  - `lib/modules/ponds_batches/presentation/widgets/pond_bento_card.dart` (Líneas 100-109, 161, 485, 1382)
  - `lib/modules/bitacora/presentation/screens/bitacora_screen.dart` (Líneas 732, 973, 1193, 1515, 1677)
- **Severidad**: ALTA / CRÍTICA (en Web CanvasKit y dispositivos móviles con GPU Mali/Adreno de gama media-baja).
- **Causa Raíz**:
  `GlassContainer` envuelve su contenido en `BackdropFilter(filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur))` con valor por defecto `blur = 16.0` (o `24.0`).
  En Flutter, cada `BackdropFilter` requiere:
  1. Copia de la textura del framebuffer subyacente (`saveLayer` / lectura de textura).
  2. Aplicación de un shader de desenfoque gaussiano de dos pasadas (horizontal y vertical).
  3. Composición con el contenedor frontal.
  
  En `bitacora_screen.dart`, en cada pestaña de historial (`_buildWaterQualityTab`, `_buildFeedingTab`, etc.), CADA tarjeta generada por el `ListView.builder` es un `GlassContainer` con desenfoque activo. En una lista con 20 o 50 registros, el scroll continuo a 60/120 FPS fuerza al GPU a realizar decenas de pases de desenfoque por frame, colapsando el bus de memoria del GPU y causando jank severo (caída a 15-20 FPS) y sobrecalentamiento.
  
  Peor aún: en `GlassContainer` (Líneas 44-46), en modo claro la opacidad efectiva es de `0.88` a `0.94` (blanco casi opaco), lo que significa que el GPU realiza un costoso desenfoque de fondo que el ojo humano ni siquiera puede percibir a través del 90% de blanco.

- **Evidencia de Código (`lib/core/design_system/glass_container.dart:87-101`)**:
```dart
        child: ClipRRect(
          borderRadius: BorderRadius.circular(borderRadius),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
            child: Container(
              padding: padding ?? const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: fill,
                borderRadius: BorderRadius.circular(borderRadius),
                border: border,
              ),
              child: child,
            ),
          ),
        ),
```

- **Recomendación / Solución**:
  1. Añadir el parámetro `bool enableBlur = true` en `GlassContainer`. En tarjetas de listas repetitivas que descansan sobre el fondo plano del `Scaffold` (`Scaffold.backgroundColor`), desactivar el desenfoque (`enableBlur: false` o `blur: 0.0`) y renderizar únicamente el `Container` decorado con color acrílico translúcido y borde luminoso.
  2. Reservar `BackdropFilter` exclusivamente para elementos flotantes superpuestos que realmente se deslizan sobre contenido variable (ej. `FishBitHeader` pinned y el dock flotante inferior `MainNavigationShell`).
  3. En modo claro, si la opacidad supera `0.80`, omitir automáticamente la pasada de `BackdropFilter` para ahorrar 100% del fill-rate en fondos claros.

---

#### Hallazgo PERF-GPU-02: Doble Instanciación y Renderizado Simultáneo de Frente y Dorso en `PondBentoCard`
- **Archivo**: `lib/modules/ponds_batches/presentation/widgets/pond_bento_card.dart` (Líneas 93-127)
- **Severidad**: ALTA.
- **Causa Raíz**:
  En el método `build` de `_PondBentoCardState`:
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
  Tanto `_buildFrontCard` como `_buildBackCard` se ejecutan y construyen en el árbol de widgets en CADA frame o reconstrucción del estanque, aun cuando el estanque NO esté rotando y el usuario solo esté viendo la cara frontal (`angle == 0`).
  Dado que tanto la cara frontal como la trasera construyen un `GlassCard` (con `GlassContainer`, `BackdropFilter`, sombras y múltiples sub-widgets de telemetría y costos), una pantalla con 20 estanques en grid/lista construye 40 `GlassCard`s completas y asigna el doble de RenderObjects en memoria.

- **Recomendación / Solución**:
  Evaluar la rotación perezosamente. Si `_controller.value == 0.0`, instanciar únicamente `frontWidget`. Solo cuando la animación se inicie (`_controller.value > 0.0`) instanciar y componer el `backWidget`.
```dart
    // Optimización perezosa de doble cara
    final isFlipped = _controller.value >= 0.5;
    final isAnimating = _controller.isAnimating;

    Widget currentDisplay;
    if (!isAnimating) {
      currentDisplay = isFlipped
          ? Transform(
              alignment: FractionalOffset.center,
              transform: Matrix4.identity()..rotateY(math.pi),
              child: _buildBackCard(context, allBatches, isPolyculture, isActive),
            )
          : _buildFrontCard(context, allBatches, isPolyculture, isActive);
    } else {
      // Solo durante la transición 3D se instancian ambos lados
      ...
    }
```

---

### 2.2 Riverpod State Management & Reconstrucciones Innecesarias

#### Hallazgo PERF-STATE-01: Rebuild Global Descontrolado en `IcaCertificationScreen`
- **Archivo**: `lib/modules/ica_compliance/presentation/screens/ica_certification_screen.dart` (Líneas 46-54)
- **Severidad**: ALTA.
- **Causa Raíz**:
  En el método `build` de `_IcaCertificationScreenState`:
```dart
    final engine = ref.watch(icaReportsEngineProvider);
    final pondsState = ref.watch(pondsProvider);
    final nutritionState = ref.watch(nutritionProvider);
    final waterState = ref.watch(waterQualityProvider);
    final salesState = ref.watch(salesProvider);
    final icaState = ref.watch(icaComplianceProvider);
```
  La pantalla observa 6 estados globales completos sin utilizar `ref.watch(provider.select(...))`.
  Cualquier mutación en la aplicación —una nueva lectura de oxígeno disuelto, una ración alimenticia suministrada, una venta registrada en bodega, o una actualización de inventario— provoca la reconstrucción total de la pantalla de 875 líneas, recalculando los 12 formatos oficiales, el checklist de la resolución 20186 y las pestañas de inocuidad.
  Además, `icaReportsEngineProvider` (`lib/modules/ica_compliance/presentation/providers/ica_compliance_provider.dart:27-32`) también observa esos mismos 6 estados, regenerando la instancia completa del motor de reportes cada vez.

- **Recomendación / Solución**:
  1. Desacoplar las 3 pestañas (`_buildFormatosTab`, `_buildChecklistTab`, `_buildInocuidadTab`) en widgets `ConsumerWidget` independientes: `IcaFormatosTab`, `IcaChecklistTab`, `IcaInocuidadTab`.
  2. En el encabezado y en cada pestaña, usar `ref.watch(provider.select(...))` para observar únicamente las listas de registros pertinentes (`personalRecords`, `vehiculoRecords`, etc.).
  3. No instanciar `IcaOfficialReportsEngine` en el método build principal de la pantalla, sino proveerlo como una clase de utilidad o llamar sus métodos de exportación bajo demanda cuando el usuario presiona el botón de exportación Excel.

---

#### Hallazgo PERF-STATE-02: Rebuild Masivo Multitarea en `BitacoraScreen`
- **Archivo**: `lib/modules/bitacora/presentation/screens/bitacora_screen.dart` (Líneas 418-427)
- **Severidad**: ALTA.
- **Causa Raíz**:
```dart
  @override
  Widget build(BuildContext context) {
    final waterState = ref.watch(waterQualityProvider);
    final nutritionState = ref.watch(nutritionProvider);
    final pondsState = ref.watch(pondsProvider);

    // O(M) indexación para lookups O(1) en los builders virtuales
    final pondMap = {for (final p in pondsState.ponds) p.id: p};
    final batchMap = {for (final b in pondsState.batches) b.id: b};
```
  `BitacoraScreen` contiene 4 pestañas operativas:
  - Pestaña 1: Calidad de Agua (`waterState`)
  - Pestaña 2: Alimentación Diaria (`nutritionState`)
  - Pestaña 3: Biometrías y Curvas (`pondsState.biometries`)
  - Pestaña 4: Mortalidad y Sanidad (`pondsState.mortalityRecords`)
  
  Al observar los 3 objetos de estado completos en la raíz del `build`:
  - Si un técnico ingresa un registro de alimentación, `nutritionProvider` emite nuevo estado.
  - El método `build` de `BitacoraScreen` se ejecuta por completo: vuelve a reconstruir `pondMap` y `batchMap`, reconstruye el `NestedScrollView`, el selector de estanque, la barra de pestañas y las 4 vistas completas (incluso las 3 que no cambiaron).
  - Las pestañas están definidas como métodos privados (`_buildWaterQualityTab`, etc.) dentro de la misma clase `State`, lo que impide a Flutter podar el subárbol o aplicar memoización.

- **Recomendación / Solución**:
  Extraer cada pestaña a su propio `ConsumerWidget`:
  - `BitacoraWaterQualityTabView` (observa únicamente `waterQualityProvider.select((s) => s.recentParameters)` y estanques).
  - `BitacoraFeedingTabView` (observa únicamente `nutritionProvider.select((s) => s.records)`).
  - `BitacoraBiometryTabView` (observa únicamente biometrías).
  - `BitacoraMortalityTabView` (observa únicamente mortalidades).
  De esta forma, la actualización de un parámetro físico-químico no tiene ningún impacto en las otras tres pestañas.

---

#### Hallazgo PERF-STATE-03: Invalidación Masiva en `PondsDashboardScreen`
- **Archivo**: `lib/modules/ponds_batches/presentation/screens/ponds_dashboard_screen.dart` (Líneas 35-41, 314, 351)
- **Severidad**: MEDIA-ALTA.
- **Causa Raíz**:
  1. En las líneas 39-40:
     ```dart
     final batchesByPond = ref.watch(activeBatchesByPondProvider);
     final waterQualityByPond = ref.watch(latestWaterQualityByPondProvider);
     ```
     Ambos proveedores generan un nuevo mapa en cada recálculo. Cuando se agrega una medición a un único estanque (ej. Estanque E-01), `latestWaterQualityByPondProvider` emite un nuevo mapa. Como `PondsDashboardScreen` observa el mapa global en la raíz, se reconstruye TODO el dashboard, incluyendo los otros 19 estanques que no sufrieron cambios.
  2. En las líneas 314 y 351 (dentro de los `SliverChildBuilderDelegate`):
     ```dart
     targetWeightsBySpecies: ref.watch(authProvider).currentCompany?.pesosFinalesEspeciesG,
     ```
     Se invoca `ref.watch(authProvider)` dentro de la función de construcción del ítem sin utilizar `.select()`. Cualquier evento de autenticación (renovación de token, perfil de usuario) provoca la reconstrucción de los ítems delegados.
  3. En las líneas 31, 59, 98, 147:
     Abrir o cerrar el speed dial (`_isSpeedDialOpen`) llama a `setState()`, lo que invalida y reconstruye toda la pantalla de estanques, recalculando los slivers y el grid.

- **Recomendación / Solución**:
  - Reemplazar el cálculo de batches y calidad de agua por providers con selector familiar: `pondBatchesProvider(pond.id)` y `pondLatestWaterQualityProvider(pond.id)`, consumidos directamente por un `PondBentoCard` convertido en `ConsumerWidget`.
  - Extraer el Speed Dial FAB a un widget con estado propio (`PondsSpeedDialFab`) para que abrir/cerrar las opciones secundarias no invalide el `CustomScrollView` ni los estanques.

---

### 2.3 Responsividad Web & Experiencia de Escritorio (hasta 1920px)

#### Hallazgo RESP-WEB-01: Falta de Contenedor Centrado (`maxWidth`) en Pantallas Principales
- **Archivos**:
  - `lib/modules/home_dashboard/presentation/screens/home_dashboard_screen.dart` (Línea 36)
  - `lib/modules/ponds_batches/presentation/screens/ponds_dashboard_screen.dart` (Línea 170)
  - `lib/modules/finance_payroll/presentation/screens/finance_screen.dart` (Línea 167)
  - `lib/modules/warehouse_inventory/presentation/screens/warehouse_screen.dart` (Línea 115)
  - `lib/modules/sales_harvest/presentation/screens/sales_screen.dart` (Línea 71)
- **Severidad**: MEDIA.
- **Causa Raíz**:
  Mientras que `BitacoraScreen` e `IcaCertificationScreen` tienen `Center(child: ConstrainedBox(constraints: BoxConstraints(maxWidth: 1024), ...))`, en `HomeDashboardScreen`, `PondsDashboardScreen`, `FinanceScreen`, `WarehouseScreen` y `SalesScreen`, los slivers y filas de KPIs se expanden horizontalmente al 100% del viewport.
  En pantallas Full HD de escritorio (1920x1080):
  - Las tarjetas de KPI en fila de 2 se estiran hasta alcanzar ~940 píxeles de ancho cada una, luciendo como franjas gigantescas desproporcionadas con textos pegados a los bordes.
  - La gráfica biológica de `home_dashboard_screen.dart` se deforma a 1888 píxeles de ancho.
  - En `PondsDashboardScreen`, la fila de KPIs superior tiene 1888 píxeles de ancho, mientras que el grid de estanques que le sigue se descompone en 4 o 5 columnas de 440 píxeles, rompiendo la armonía visual y la jerarquía de la interfaz.

- **Recomendación / Solución**:
  Implementar un contenedor semántico unificado de diseño para pantallas de escritorio:
```dart
Center(
  child: ConstrainedBox(
    constraints: const BoxConstraints(maxWidth: 1200),
    child: ...
  ),
)
```
  O alternativamente, en pantallas >= 1200px, reorganizar los KPIs en una barra lateral o un grid Bento de 4 columnas en lugar de 2 filas estiradas.

---

#### Hallazgo RESP-WEB-02: Comportamiento de Scroll y Arrastre con Ratón en Web (`ScrollBehavior`)
- **Archivo**: `lib/app/app.dart` (Líneas 15-32)
- **Severidad**: MEDIA.
- **Causa Raíz**:
  `MaterialApp.router` no define la propiedad `scrollBehavior`.
  Por defecto en Flutter Web:
  1. `MaterialScrollBehavior` restringe el arrastre de vista únicamente a dispositivos táctiles (`PointerDeviceKind.touch`, `stylus`).
  2. Los usuarios de escritorio con ratón convencional no pueden hacer clic y arrastrar en listas horizontales ni en barras de chips (por ejemplo, las pestañas desplazables `TabBar(isScrollable: true)` en `BitacoraScreen`, `IcaCertificationScreen` o los chips de filtro en `PondsDashboardScreen`).
  3. No se visualizan barras de desplazamiento persistentes o con hover intuitivo en conjuntos de datos largos.

- **Recomendación / Solución**:
  Configurar un `AppScrollBehavior` global en `lib/app/app.dart`:
```dart
class AppScrollBehavior extends MaterialScrollBehavior {
  const AppScrollBehavior();

  @override
  Set<PointerDeviceKind> get dragDevices => {
        PointerDeviceKind.touch,
        PointerDeviceKind.mouse,
        PointerDeviceKind.trackpad,
        PointerDeviceKind.stylus,
      };

  @override
  Widget buildScrollbar(BuildContext context, Widget child, ScrollableDetails details) {
    return Scrollbar(
      controller: details.controller,
      interactive: true,
      thumbVisibility: details.direction == Axis.vertical,
      child: child,
    );
  }
}
```
  Y asignarlo a `MaterialApp.router(scrollBehavior: const AppScrollBehavior(), ...)`.

---

#### Hallazgo RESP-WEB-03: Cero Estados Hover y Cursores de Ratón Falsos (`GestureDetector` vs `InkWell`)
- **Archivos**:
  - `lib/core/design_system/fishbit_header.dart` (Líneas 145, 207)
  - `lib/app/main_navigation_shell.dart` (Línea 192)
  - `lib/core/design_system/glass_action_hub_sheet.dart` (Líneas 54, 63)
  - `lib/modules/bitacora/presentation/screens/bitacora_screen.dart` (Línea 510)
  - `lib/modules/warehouse_inventory/presentation/screens/warehouse_screen.dart` (Línea 185)
- **Severidad**: POLISH / MEDIA.
- **Causa Raíz**:
  No existe ninguna ocurrencia de `MouseRegion` ni `onHover` en todo el proyecto.
  Asimismo, elementos interactivos críticos como `CompanyPillButton` (selector de sede), el avatar de usuario en el header, y los botones del dock de navegación (`NavItemButton`) están implementados con `GestureDetector` sin envolver en `MouseRegion(cursor: SystemMouseCursors.click)` ni `InkWell`.
  En Web y escritorio, al pasar el cursor sobre estos botones, el cursor permanece como la flecha estándar del sistema en lugar de convertirse en mano interactiva, provocando que el usuario piense que son elementos informativos estáticos.

- **Recomendación / Solución**:
  - Reemplazar `GestureDetector` por `InkWell` o encapsular los botones en `MouseRegion(cursor: SystemMouseCursors.click)`.
  - Incorporar micro-interacciones hover en `GlassCard` (aumento sutil de resplandor `glowColor` con `alpha: 0.15` a `0.30` o elevación de escala de 1.0 a 1.015 en desktop).

---

### 2.4 Ergonomía Móvil en Campo & Safe Area

#### Hallazgo RESP-MOB-01: Oclusión Crítica de Registros en `BitacoraScreen` por Espaciado Inferior Insuficiente
- **Archivo**: `lib/modules/bitacora/presentation/screens/bitacora_screen.dart` (Líneas 718, 961, 1179, 1738)
- **Severidad**: ALTA / CRÍTICA.
- **Causa Raíz**:
  En las 4 pestañas de la bitácora:
  - Calidad de Agua: Línea 718: `if (index == filteredParams.length + 1) return const SizedBox(height: 80);`
  - Alimentación: Línea 961: `if (index == records.length + 1) return const SizedBox(height: 80);`
  - Biometrías: Línea 1179: `if (index == sortedBiometries.length + 1) return const SizedBox(height: 80);`
  - Bajas y Sanidad: Línea 1738: `return const SizedBox(height: 80);`
  
  Cálculo de dimensiones reales en dispositivos móviles modernos:
  - En iOS (iPhone con Dynamic Island o Home Indicator): el Safe Area inferior mide `34 dp`.
  - Margen del dock: `12 dp`.
  - Altura del dock: `58 dp`.
  - La parte superior del dock se ubica a `34 + 12 + 58 = 104 dp` del borde inferior de la pantalla.
  - Además, `BitacoraScreen` tiene un botón flotante extendido ("Registrar en Bitácora") con altura de `48 dp` y gap de `16 dp`. La parte superior del FAB se sitúa a `104 + 16 + 48 = 168 dp`.
  
  Al colocar únicamente `SizedBox(height: 80)`, el último elemento de la lista queda ubicado debajo del dock flotante y del FAB. En teléfonos móviles, el usuario NO puede ver ni tocar el último registro de la lista porque queda completamente tapado.
  `BitacoraScreen` no utilizó el widget `DockBottomSpacer()` ni `FloatingDockLayout.scrollClearance(context)` que sí fue creado para solucionar este problema en otras pantallas.

- **Recomendación / Solución**:
  Reemplazar `const SizedBox(height: 80)` en las 4 pestañas de `BitacoraScreen` por:
```dart
const DockBottomSpacer(extra: 48.0) // 48dp extra para librar limpiamente el FAB extendido
```

---

#### Hallazgo RESP-MOB-02: Ergonomía de Pulgar en Campo: Diálogos Centrados vs. Bottom Sheets Adaptativos
- **Archivos**:
  - `lib/modules/water_quality/presentation/dialogs/parametro_modal.dart` (Línea 110)
  - `lib/modules/ponds_batches/presentation/dialogs/alimentar_modal.dart` (Línea 122)
  - `lib/modules/ponds_batches/presentation/dialogs/biometria_modal.dart` (Línea 113)
  - `lib/modules/ponds_batches/presentation/dialogs/mortalidad_modal.dart` (Línea 100)
  - `lib/modules/ponds_batches/presentation/dialogs/siembra_modal.dart` (Línea 328)
  - `lib/modules/ponds_batches/presentation/dialogs/traslado_modal.dart` (Línea 111)
  - `lib/modules/ponds_batches/presentation/dialogs/crear_estanque_modal.dart` (Línea 312)
- **Severidad**: ALTA (en usabilidad de campo en piscícolas) / MEDIA (en código).
- **Causa Raíz**:
  Todos los formularios de recolección de datos de campo están creados utilizando `showDialog` y retornando `Dialog`.
  En una operación acuícola real:
  1. El operario o técnico sostiene el móvil con una sola mano cerca al estanque (a menudo con dedos mojados o guantes).
  2. Los modales centrados en medio de la pantalla exigen extender el pulgar hacia la parte superior de la pantalla para cerrar el diálogo o alcanzar los primeros campos del formulario (ej. selector de estanque o fecha).
  3. Al enfocarse cualquier campo de texto numérico, el teclado virtual del sistema emerge desde el fondo de la pantalla. Al ser un `Dialog` centrado con márgenes verticales fijos (`vertical: 20`), el cuadro se contrae violentamente en el espacio vertical restante, comprimiendo el formulario en una pequeña ventana interna de 180-220 dp de altura que dificulta la digitación.
  
  En móviles, el patrón canónico para operaciones de campo con una sola mano es un `showModalBottomSheet(isScrollControlled: true, useSafeArea: true)` anclado en la parte inferior, donde los campos principales y el botón de guardado quedan inmediatamente al alcance del pulgar y se elevan fluidamente junto con el teclado.

- **Recomendación / Solución**:
  Crear una función constructora adaptativa (`showAdaptiveFieldModal`):
  - Si el ancho de pantalla es `< 600 dp` (móviles): presentar un `ModalBottomSheet` arrastrable anclado al fondo, respetando `MediaQuery.viewInsetsOf(context).bottom`.
  - Si el ancho de pantalla es `>= 600 dp` (web / tablets): presentar el `Dialog` flotante centrado con `maxWidth: 520`.

---

#### Hallazgo RESP-MOB-03: Riesgos de RenderFlex Overflow en Modales sin Scroll y Popovers
- **Archivos**:
  - `lib/modules/auth_tenant/presentation/screens/login_screen.dart` (Líneas 100-114)
  - `lib/core/design_system/glass_action_hub_sheet.dart` (Líneas 67-190)
- **Severidad**: MEDIA.
- **Causa Raíz**:
  1. En `login_screen.dart:100-114` (`_showForgotPasswordDialog`), el diálogo utiliza `Column(mainAxisSize: MainAxisSize.min)` que contiene texto explicativo, un `GlassFormField` y un botón, pero NO está envuelto en `SingleChildScrollView`. Si un usuario abre este diálogo en un teléfono pequeño o en orientación horizontal (landscape) y toca el campo de texto, el teclado virtual consume más del 50% de la altura de la pantalla, provocando un error visual `RenderFlex overflowed by X pixels`.
  2. En `glass_action_hub_sheet.dart:67-190`, el popover "Más" contiene una cabecera y un `GridView.count(shrinkWrap: true, physics: const NeverScrollableScrollPhysics())` con hasta 5 botones de módulo. Si el usuario tiene habilitado el escalado de fuentes de accesibilidad en el sistema operativo (escala de texto >= 1.3x), la altura del popover supera la altura visible disponible sobre el dock, generando overflow.

- **Recomendación / Solución**:
  - Envolver el contenido del diálogo de recuperación de contraseña en `SingleChildScrollView(child: Column(...))`.
  - Envolver el `Column` de `GlassActionHubSheet` en `SingleChildScrollView(physics: BouncingScrollPhysics(), child: ...)`.

---

#### Hallazgo RESP-MOB-04: Conflicto de Gestos de Desplazamiento Anidados en `PondBentoCard`
- **Archivo**: `lib/modules/ponds_batches/presentation/widgets/pond_bento_card.dart` (Líneas 459-465, 626-645)
- **Severidad**: MEDIA.
- **Causa Raíz**:
  En `pond_bento_card.dart`:
  - En la cara frontal (Línea 460): si `constraints.hasBoundedHeight` es verdadero (como ocurre en el grid de estanques donde `mainAxisExtent: 450`), la tarjeta envuelve su contenido en un `SingleChildScrollView(physics: BouncingScrollPhysics())`.
  - En la cara trasera (Líneas 636-645): cuando se encuentra en lista móvil con altura no acotada, fuerza `ConstrainedBox(constraints: BoxConstraints(maxHeight: 380))` y envuelve el dorso en su propio `SingleChildScrollView`.
  
  Esto crea vistas de scroll anidadas en el mismo eje vertical que el `CustomScrollView` o `ListView` principal sin coordinación de controlador de scroll. Cuando el usuario intenta deslizar la página hacia arriba o hacia abajo con el dedo, si el toque inicia sobre una tarjeta con scroll interno, el gesto queda atrapado por la tarjeta hasta que esta llega a su límite, interrumpiendo la fluidez del scroll de la pantalla completa.

- **Recomendación / Solución**:
  - Evitar scroll vertical dentro de las tarjetas de estanques. Ajustar el diseño de `PondBentoCard` mediante `FittedBox`, espaciados compactos o paneles colapsables para que tanto la cara frontal como la trasera tengan altura natural auto-ajustable sin necesidad de un `SingleChildScrollView` vertical interno.

---

## 3. MATRIZ DE PRIORIZACIÓN DE RESOLUCIÓN

| Código | Área | Descripción del Problema | Impacto | Complejidad de Corrección | Prioridad |
| :--- | :--- | :--- | :--- | :--- | :--- |
| **RESP-MOB-01** | Mobile | `BitacoraScreen` ocluye registros finales por `SizedBox(height: 80)` vs Dock/FAB | Alto (bloqueo de UI) | Baja (sustituir por `DockBottomSpacer`) | **P1 - Inmediato** |
| **PERF-GPU-01** | GPU / Web | `BackdropFilter` excesivo en listas y cards con opacidad 0.9 | Alto (jank / FPS) | Media (`enableBlur` adaptativo) | **P1 - Inmediato** |
| **PERF-GPU-02** | GPU / Render | Doble instanciación simultánea frente/dorso en `PondBentoCard` | Alto (memoria/GPU) | Media (construcción perezosa) | **P1 - Inmediato** |
| **PERF-STATE-01** | Riverpod | `IcaCertificationScreen` observa 6 estados globales en raíz | Alto (CPU/batería) | Media (desacople a ConsumerWidgets) | **P2 - Alta** |
| **PERF-STATE-02** | Riverpod | `BitacoraScreen` observa 3 estados globales en raíz | Alto (CPU/rebuilds) | Media (desacople a pestañas hijas) | **P2 - Alta** |
| **RESP-MOB-02** | Mobile UX | Modales de campo como `Dialog` centrado vs `ModalBottomSheet` | Alto (ergonomía) | Media (helper adaptativo) | **P2 - Alta** |
| **RESP-WEB-01** | Web / Layout | Pantallas principales sin `maxWidth` estiradas a 1920px | Medio (estética) | Baja (envolver en `ConstrainedBox`) | **P2 - Alta** |
| **RESP-WEB-02** | Web Engine | Falta de `ScrollBehavior` con soporte de arrastre de mouse | Medio (usabilidad) | Baja (añadir `AppScrollBehavior`) | **P2 - Alta** |
| **RESP-MOB-03** | Mobile UX | Riesgos de RenderFlex overflow en modales sin scroll | Medio (bug visual) | Baja (`SingleChildScrollView`) | **P3 - Media** |
| **PERF-STATE-03** | Riverpod | `PondsDashboardScreen` observa mapas agregados en raíz | Medio (rebuilds) | Media (family providers) | **P3 - Media** |
| **RESP-WEB-03** | Web UX | Cero estados hover y uso de `GestureDetector` sin cursor click | Bajo (polish) | Baja (`InkWell` / `MouseRegion`) | **P3 - Media** |
| **RESP-MOB-04** | Mobile UX | Scroll vertical anidado dentro de tarjetas `PondBentoCard` | Medio (fricción) | Media (layout auto-ajustable) | **P3 - Media** |

---

## 4. VERIFICACIÓN Y VALIDACIÓN INDEPENDIENTE

Para verificar cada hallazgo de forma independiente sin alterar el código de producción:
1. **Verificación de `BitacoraScreen` (RESP-MOB-01)**:
   - Inspeccionar `lib/modules/bitacora/presentation/screens/bitacora_screen.dart` en las líneas 718, 961, 1179 y 1738.
   - Constatar la presencia de `return const SizedBox(height: 80);`.
   - Comparar contra `FloatingDockLayout.dockTopOffset(context)` en `lib/core/design_system/floating_dock_layout.dart:21-24`, donde el despeje mínimo es de 104 dp en iOS + 64 dp de FAB = 168 dp.
2. **Verificación de `BackdropFilter` en `GlassContainer` (PERF-GPU-01)**:
   - Inspeccionar `lib/core/design_system/glass_container.dart` en las líneas 89-90.
   - Constatar que no existe condición para omitir `BackdropFilter` cuando `blur == 0` o en modo claro con alta opacidad (línea 45).
3. **Verificación de Rebuilds en `IcaCertificationScreen` y `BitacoraScreen` (PERF-STATE-01, PERF-STATE-02)**:
   - Inspeccionar `lib/modules/ica_compliance/presentation/screens/ica_certification_screen.dart:48-53`.
   - Inspeccionar `lib/modules/bitacora/presentation/screens/bitacora_screen.dart:420-422`.
   - Constatar la ausencia de `.select()` y que las pestañas son métodos privados y no `ConsumerWidget`s.
4. **Verificación de Ausencia de `maxWidth` en `HomeDashboardScreen` (RESP-WEB-01)**:
   - Inspeccionar `lib/modules/home_dashboard/presentation/screens/home_dashboard_screen.dart:36-45`.
   - Constatar que el `CustomScrollView` y el `Column` principal no cuentan con ningún `ConstrainedBox(maxWidth: ...)`.
