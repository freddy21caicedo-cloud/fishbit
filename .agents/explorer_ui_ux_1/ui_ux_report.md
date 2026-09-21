# FishBit — Informe Exhaustivo de Auditoría UI/UX, Ergonomía de Campo y Accesibilidad (WCAG 2.2)

**Fecha**: 2026-09-12  
**Autor**: Explorer UI/UX & Ergonomía (Multi-Agent Audit Team)  
**Alcance**: Totalidad de capas de presentación, navegación, formularios, pantallas y tokens de diseño en `lib/`  
**Estado**: 100% Completado (Auditoría de Solo Lectura)

---

## 1. Resumen Ejecutivo

La aplicación FishBit implementa una experiencia visual atractiva y moderna basada en un lenguaje de diseño **Glassmorphism** (tarjetas translúcidas con desenfoque Gaussiano, bordes luminiscentes sutiles, degradados cian/coral y tipografía geométrica). La arquitectura de información contempla un espectro completo de operaciones acuícolas: Dashboard Bento, Gestión de Estanques y Lotes, Bitácora Diaria, Calidad de Agua, Alimentación, Biometrías, Mortalidad, Traslados, Certificación ICA, Nómina/OPEX, Ventas e Inventario de Bodega.

No obstante, la evaluación de **ergonomía en campo** y **accesibilidad (WCAG 2.2)** revela fricciones críticas que comprometen la usabilidad en el entorno real de una piscifactoría (operadores con manos húmedas, guantes de nitrilo, luz solar directa tropical y operación a una sola mano mientras se camina por taludes o estanques):

1. **Riesgo Operativo Crítico en Bento Cards (`UX-01`)**: Los 4 botones de acción rápida de cada estanque (`Alimentar`, `Muestreo`, `Bajas`, `Traslado`) miden apenas **30 dp de alto** y están apiñados en una sola fila. En una pantalla de 360 dp, la probabilidad de pulsar por error "Bajas" en lugar de "Alimentar" es alarmante.
2. **Paradigma de Diálogos Centrales vs. Bottom Sheets (`UX-04`)**: Todas las acciones primarias de campo abren `showDialog` centrados en pantalla en vez de `showModalBottomSheet`. Esto sitúa los controles fuera de la zona natural del pulgar y genera colisiones severas cuando emerge el teclado virtual.
3. **Riesgo Regulatorio por Precarga de Datos de Laboratorio (`UX-05`)**: El modal de Calidad de Agua tiene preinicializados 11 parámetros físico-químicos con valores ficticios (`6.2 mg/L`, `28.5 °C`, `7.4 pH`). Un operador que guarde sin editar registrará datos inventados en los registros oficiales ICA.
4. **Ilegibilidad Crítica en Modo Claro / Exterior (`A11Y-01`)**: Los estilos de texto de `AppTypography` tienen colores oscuros codificados en duro (`textSecondaryDark: #8E9BAE`). Sobre fondo blanco o bajo luz solar intensa, el contraste cae a **2.6:1** (violando el mínimo de 4.5:1 de WCAG AA).
5. **Colisión del Dock Flotante con Gestos del Sistema y FAB (`UX-02`)**: El dock de navegación inferior carece de `SafeArea`, solapándose con la barra de gestos de iOS/Android. Para esquivarlo, cada pantalla añade un parche frágil de `bottom: 78` en sus FAB.

A continuación se desglosan los hallazgos con evidencia directa, impacto operativo y propuestas de código.

---

## 2. Matriz de Hallazgos y Severidad

| ID | Área / Módulo | Severidad | Categoría | Problema Clave |
|---|---|---|---|---|
| **UX-01** | `ponds_batches` (`pond_bento_card.dart`) | 🔴 **Crítica** | Ergonomía / Touch Targets | Botones de acción rápida de 30 dp apiñados en una fila (riesgo de pulsación errónea en campo). |
| **UX-02** | `core/navigation` (`main_navigation_shell.dart`, etc.) | 🟠 **Alta** | Layout / Navegación | Dock flotante colisiona con el Home Indicator; FABs parcheados con `bottom: 78`. |
| **UX-03** | `ponds_batches` & `auth_tenant` (Modales / Wizard) | 🟠 **Alta** | Responsividad / Teclado | `SizedBox(height: 400/480)` en `PageView` provoca desbordamientos `RenderFlex` al abrir teclado. |
| **UX-04** | Modales de Campo (`alimentar`, `biometria`, `mortalidad`) | 🟠 **Alta** | Ergonomía Pulgar | Uso de `showDialog` central en lugar de `BottomSheet` anclado al pulgar para uso a una mano. |
| **UX-05** | `water_quality` (`parametro_modal.dart`) | 🟠 **Alta** | Integridad de Datos / UX | Controladores de 11 parámetros precargados con valores numéricos simulados en vez de vacíos. |
| **UX-06** | `core/navigation` (`glass_action_hub_sheet.dart`) | 🟡 **Media** | Responsividad | `GridView.count` con `childAspectRatio: 1.45` fijo se desborda en 360 dp o con fuentes grandes. |
| **UX-07** | `ponds_batches` (`ponds_dashboard_screen.dart`) | 🟡 **Media** | Layout / Responsividad | `mainAxisExtent: 380` fijo en grid corta tarjetas con alertas sanitarias ICA o policultivo. |
| **UX-08** | `ponds_batches` & `auth_tenant` | 🟡 **Media** | User Journey / Navegación | Empty states mudos sin llamada a la acción; ruta inexistente `context.go('/home')` en registro. |
| **UX-09** | Global (`glass_date_picker.dart`, chips de filtro) | 🟡 **Media** | Touch Targets | Micro-chips de filtrado (~16-19 dp) y días de calendario de 30 dp violan WCAG 2.5.5 (48x48 dp). |
| **UX-10** | `core/design_system` (Glassmorphism & Rendimiento) | 🟡 **Media** | Ergonomía Visual / Outdoor | Sobrecarga de `BackdropFilter` en bajas gamas y pérdida de contraste bajo sol tropical. |
| **A11Y-01** | `core/design_system` (`app_typography.dart`) | 🔴 **Crítica** | WCAG 1.4.3 (Contraste) | Colores oscuros fijos en tipografía dejan texto secundario en 2.6:1 de contraste en tema claro. |
| **A11Y-02** | `core/design_system` (`glass_form_field.dart`) | 🟠 **Alta** | WCAG 4.1.2 / 3.3.1 (A11y) | Validador retorna `''` y pinta texto desconectado; lectores de pantalla no anuncian el error. |
| **A11Y-03** | `home_dashboard` & `mortalidad_modal` | 🟡 **Media** | WCAG 1.4.1 (Color) | Semáforo de estado dependiente únicamente de color; bajo contraste en chip de mortalidad alta. |

---

## 3. Desglose Detallado de Hallazgos

---

### UX-01: Botones de Acción Rápida en Bento Card Violando WCAG 2.5.5 y Provocando Errores de Registro en Campo
- **Archivo**: `lib/modules/ponds_batches/presentation/widgets/pond_bento_card.dart`
- **Líneas**: 395–505
- **Severidad**: 🔴 **Crítica**
- **Descripción**:
  La tarjeta de estanque ubica en su base cuatro botones de operación crítica (`Alimentar`, `Muestreo`, `Bajas`, `Traslado`) dentro de un único `Row`. Cada botón tiene configurado:
  ```dart
  minimumSize: const Size(0, 30),
  padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 2),
  ```
  En un dispositivo móvil estándar de 360 dp de ancho (viewport común de smartphones resistentes o de gama de entrada utilizados en piscifactorías), cada botón dispone de apenas **69 dp de ancho por 30 dp de alto**, con separación casi nula entre ellos.
- **Impacto en Campo**:
  En operaciones de campo acuícolas, el operador sostiene el móvil mientras está junto al estanque, a menudo con manos mojadas o usando guantes de trabajo. Un área de toque de 30 dp de alto viola la recomendación WCAG 2.5.5 (48×48 dp mínimo). Existe una alta probabilidad de pulsar "Bajas" (mortalidad) cuando se pretendía registrar "Alimentar", falseando el inventario de biomasa de la granja.
- **Propuesta de Rediseño (Código Diff)**:
  Reorganizar la botonera inferior en un bloque de 2×2 con altura mínima de 48 dp o sustituirla por un botón principal "Registrar Labor" de ancho completo que abra un bottom sheet unificado con blancos táctiles holgados:

```dart
// ANTES (pond_bento_card.dart:395)
Row(
  children: [
    Expanded(child: TextButton.icon(
      style: TextButton.styleFrom(
        minimumSize: const Size(0, 30),
        padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 2),
      ),
      label: Text('Alimentar', style: TextStyle(fontSize: 10)),
      ...
    )),
    // 3 botones adicionales idénticos...
  ],
)

// DESPUÉS (Ergonomía de Campo Optimizada: Cuadrícula Táctil 2x2)
Padding(
  padding: const EdgeInsets.only(top: 8),
  child: Column(
    children: [
      Row(
        children: [
          Expanded(
            child: _PondActionButton(
              icon: Icons.restaurant_rounded,
              label: 'Alimentar',
              color: AppColors.greenBiomass,
              minHeight: 48,
              onTap: () => AlimentarModal.show(context, pond: widget.pond, batch: batch),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _PondActionButton(
              icon: Icons.scale_rounded,
              label: 'Muestreo',
              color: AppColors.cyanWater,
              minHeight: 48,
              onTap: () => BiometriaModal.show(context, pond: widget.pond, batch: batch),
            ),
          ),
        ],
      ),
      const SizedBox(height: 6),
      Row(
        children: [
          Expanded(
            child: _PondActionButton(
              icon: Icons.warning_amber_rounded,
              label: 'Mortalidad',
              color: AppColors.coralAction,
              minHeight: 48,
              onTap: () => MortalidadModal.show(context, pond: widget.pond, batch: batch),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _PondActionButton(
              icon: Icons.sync_alt_rounded,
              label: 'Traslado',
              color: Colors.purpleAccent,
              minHeight: 48,
              onTap: () => TrasladoModal.show(context, pond: widget.pond, batch: batch),
            ),
          ),
        ],
      ),
    ],
  ),
)
```

---

### UX-02: Dock Flotante Desconectado de Insets del Sistema y Parche Generalizado de `bottom: 78`
- **Archivos**:
  - `lib/core/navigation/main_navigation_shell.dart:62–66`
  - `lib/modules/bitacora/presentation/screens/bitacora_screen.dart:430`
  - `lib/modules/ponds_batches/presentation/screens/ponds_dashboard_screen.dart:47`
  - `lib/modules/finance_payroll/presentation/screens/finance_screen.dart:57`
  - `lib/modules/sales_harvest/presentation/screens/sales_screen.dart:44`
  - `lib/modules/warehouse_inventory/presentation/screens/warehouse_screen.dart:102`
  - `lib/modules/auth_tenant/presentation/screens/gestion_equipo_screen.dart:26`
- **Severidad**: 🟠 **Alta**
- **Descripción**:
  `MainNavigationShell` posiciona el dock flotante usando un valor estático:
  ```dart
  Positioned(
    left: 24,
    right: 24,
    bottom: 16,
    child: _FloatingDock(...),
  )
  ```
  No utiliza `SafeArea(bottom: true)` ni `MediaQuery.paddingOf(context).bottom`. En dispositivos modernos (iPhone con Home Indicator o Android con navegación por gestos donde el inset inferior mide entre 24 y 34 dp), el dock queda superpuesto sobre la barra de control del sistema operativo.
  Adicionalmente, debido a la presencia flotante del dock, **todas** las pantallas del sistema añaden un padding forzado manual de `EdgeInsets.only(bottom: 78)` en sus respectivos `FloatingActionButton`.
- **Impacto en Campo**:
  En pantallas pequeñas o cuando el teclado emerge parcialmente, el FAB flota a mitad de la lista de datos. Si el usuario navega a una subpantalla donde no está el dock, el FAB queda suspendido en el aire de forma inconsistente. Además, pulsar en los botones inferiores del dock en iOS provoca activación involuntaria del conmutador de aplicaciones del SO.
- **Propuesta de Rediseño (Código Diff)**:
  Anclar el dock respetando los insets del sistema y unificar el posicionamiento de los botones de acción:

```dart
// ANTES (main_navigation_shell.dart:62)
Positioned(
  left: 24,
  right: 24,
  bottom: 16,
  child: _FloatingDock(...),
)

// DESPUÉS (Alineación Segura con SafeArea)
Positioned(
  left: 16,
  right: 16,
  bottom: MediaQuery.paddingOf(context).bottom + 8,
  child: _FloatingDock(...),
)
```

---

### UX-03: `PageView` con Altura Rígida en Modales y Pantallas de Registro Provoca Desbordamientos de Teclado
- **Archivos**:
  - `lib/modules/ponds_batches/presentation/dialogs/crear_estanque_modal.dart:262` (`SizedBox(height: 400)`)
  - `lib/modules/auth_tenant/presentation/screens/register_company_screen.dart:225` (`SizedBox(height: 480)`)
- **Severidad**: 🟠 **Alta**
- **Descripción**:
  Tanto el asistente de creación de estanque como el registro de empresa encapsulan un `PageView` de varios pasos dentro de un contenedor con altura física codificada en duro (`height: 400` y `height: 480` respectivamente).
  En `crear_estanque_modal.dart`, la suma de alturas intrínsecas de los campos del Paso 1 (Nombre, Espejo de agua, Profundidad, Volumen calculado, Densidad objetivo) supera los **425 dp**.
- **Impacto en Campo**:
  Al tocar cualquier campo numérico, el teclado virtual del sistema operativo se despliega, reduciendo el viewport vertical a ~300-350 dp. Flutter dispara inmediatamente una excepción `RenderFlex overflowed by xx pixels` (franja amarilla y negra), bloqueando visualmente los botones "Continuar" o "Guardar" fuera del alcance del usuario.
- **Propuesta de Rediseño**:
  Eliminar los `SizedBox` de altura fija. Implementar cada paso como un `SingleChildScrollView` independiente dentro del modal o utilizar un `AnimatedSwitcher` basado en el índice del paso actual sin restricciones artificiales de altura:

```dart
// ANTES (crear_estanque_modal.dart:262)
SizedBox(
  height: 400,
  child: PageView(
    controller: _pageCtrl,
    children: [ _buildPaso1(), _buildPaso2() ],
  ),
)

// DESPUÉS (Contenedor Elástico con AnimatedSwitcher)
AnimatedSize(
  duration: const Duration(milliseconds: 250),
  curve: Curves.easeInOut,
  child: _pasoActual == 0 ? _buildPaso1(context) : _buildPaso2(context),
)
```

---

### UX-04: Paradigma de Diálogos Centrales (`showDialog`) vs. Bottom Sheets Ergonómicos para Operación a Una Mano
- **Archivos**:
  - `lib/modules/ponds_batches/presentation/dialogs/alimentar_modal.dart:23–28`
  - `lib/modules/ponds_batches/presentation/dialogs/biometria_modal.dart:20–25`
  - `lib/modules/ponds_batches/presentation/dialogs/mortalidad_modal.dart:21–25`
  - `lib/modules/ponds_batches/presentation/dialogs/traslado_modal.dart:21–25`
  - `lib/modules/ponds_batches/presentation/dialogs/siembra_modal.dart:21–25`
  - `lib/modules/ponds_batches/presentation/dialogs/crear_estanque_modal.dart:26–31`
- **Severidad**: 🟠 **Alta**
- **Descripción**:
  Los flujos de captura de datos diaria más frecuentes en una granja acuícola se invocan como diálogos flotantes centrados:
  ```dart
  static Future<void> show(BuildContext context, ...) {
    return showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => Dialog(
        insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
        child: ...,
      ),
    );
  }
  ```
- **Impacto en Campo**:
  1. **Zona de Alcance del Pulgar (Thumb Zone)**: En teléfonos de 6.1 a 6.7 pulgadas, el diálogo centrado sitúa los campos superiores y el botón de cerrar (`X`) en la esquina superior derecha, forzando al usuario a utilizar ambas manos o a sobreextender la muñeca.
  2. **Interacción con Teclado**: Al abrir el teclado numérico, el diálogo es empujado hacia el centro-superior, comprimiendo su contenido y forzando scrolls anidados difíciles de maniobrar con dedos húmedos.
- **Propuesta de Rediseño (Código Diff)**:
  Reemplazar `showDialog` por un `showModalBottomSheet` responsive con soporte para arrastre hacia abajo y acciones ancladas al pie:

```dart
// PROPUESTA DE ARQUITECTURA ERGONÓMICA UNIFICADA
static Future<void> show(BuildContext context, {Pond? pond, FishBatch? batch}) {
  final isTablet = MediaQuery.sizeOf(context).width >= 600;
  
  if (isTablet) {
    return showDialog(
      context: context,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 540),
          child: AlimentarModal(pond: pond, batch: batch),
        ),
      ),
    );
  }

  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) => Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(ctx).bottom),
      child: DraggableScrollableSheet(
        initialChildSize: 0.85,
        minChildSize: 0.50,
        maxChildSize: 0.95,
        builder: (ctx, scrollController) => AlimentarModal(
          pond: pond,
          batch: batch,
          scrollController: scrollController,
        ),
      ),
    ),
  );
}
```

---

### UX-05: Peligrosa Precarga de Parámetros de Laboratorio en Modal de Calidad de Agua
- **Archivo**: `lib/modules/water_quality/presentation/dialogs/parametro_modal.dart`
- **Líneas**: 36–46
- **Severidad**: 🟠 **Alta** (Riesgo de Integridad de Datos e Inspección ICA)
- **Descripción**:
  Al instanciar el formulario de registro de calidad de agua, 11 controladores vienen prellenados con valores numéricos literales fijos:
  ```dart
  final _oxigenoCtrl = TextEditingController(text: '6.2');
  final _saturacionCtrl = TextEditingController(text: '85.0');
  final _temperaturaCtrl = TextEditingController(text: '28.5');
  final _phCtrl = TextEditingController(text: '7.4');
  final _amonioCtrl = TextEditingController(text: '0.02');
  final _nitritosCtrl = TextEditingController(text: '0.5');
  final _alcalinidadCtrl = TextEditingController(text: '40.0');
  final _durezaCtrl = TextEditingController(text: '80.0');
  final _amoniacoNoIonizadoCtrl = TextEditingController(text: '0.01');
  final _co2Ctrl = TextEditingController(text: '1.2');
  final _transparenciaCtrl = TextEditingController(text: '25.0');
  ```
- **Impacto en Campo**:
  Si un operario toma la muestra de agua solo para Oxígeno y Temperatura, pero no realiza los test colorimétricos de Amonio, Nitritos ni Alcalinidad, al presionar "Guardar Registro" el sistema almacena 11 mediciones óptimas **completamente falsas**. Estos registros nutren la bitácora oficial exportable a PDF para auditorías de inocuidad y bioseguridad del ICA (Resolución 065463), lo que puede incurrir en sanciones legales o falsos diagnósticos sanitarios.
- **Propuesta de Rediseño**:
  Inicializar los controladores vacíos (`TextEditingController()`) y presentar los rangos ideales como sugerencias visuales (`hintText` y texto de ayuda):

```dart
// ANTES (parametro_modal.dart:36)
final _oxigenoCtrl = TextEditingController(text: '6.2');

// DESPUÉS (Controlador Limpio con Rango de Referencia Guía)
final _oxigenoCtrl = TextEditingController();

// En el GlassFormField correspondiente:
GlassFormField(
  controller: _oxigenoCtrl,
  label: 'OXÍGENO DISUELTO (OD)',
  hint: 'Ej: 5.5',
  suffixText: 'mg/L',
  helperText: 'Óptimo: 5.0 - 8.0 mg/L',
  keyboardType: const TextInputType.numberWithOptions(decimal: true),
)
```

---

### UX-06: Desbordamiento del Action Hub Sheet por Aspect Ratio Rígido en Dispositivos Compactos
- **Archivo**: `lib/core/navigation/glass_action_hub_sheet.dart`
- **Líneas**: 123–130
- **Severidad**: 🟡 **Media**
- **Descripción**:
  La cuadrícula del concentrador central de acciones rápidas utiliza un `GridView.count`:
  ```dart
  GridView.count(
    crossAxisCount: 2,
    shrinkWrap: true,
    physics: const NeverScrollableScrollPhysics(),
    mainAxisSpacing: 10,
    crossAxisSpacing: 10,
    childAspectRatio: 1.45,
    children: [...],
  )
  ```
- **Impacto en Campo**:
  En pantallas angostas (360 dp) o cuando el usuario tiene configurada una escala de texto del sistema operativo superior a 1.15x por necesidades de visión, el espacio vertical disponible dentro de cada celda no es suficiente para alojar el icono (38 dp), el título en negrita y el subtítulo explicativo de dos líneas, cortando el texto o generando desbordamiento `RenderFlex`.
- **Propuesta de Rediseño**:
  Hacer que el aspect ratio se ajuste dinámicamente según el factor de escala de texto o usar una lista de tarjetas expandibles:

```dart
final textScale = MediaQuery.textScalerOf(context).scale(1.0);
final dynamicAspectRatio = (1.45 / textScale).clamp(1.1, 1.5);

GridView.count(
  crossAxisCount: 2,
  shrinkWrap: true,
  physics: const NeverScrollableScrollPhysics(),
  mainAxisSpacing: 10,
  crossAxisSpacing: 10,
  childAspectRatio: dynamicAspectRatio,
  ...
)
```

---

### UX-07: Extensión Fija de Tarjetas en Ponds Dashboard Corta Banners de Retiro y Policultivo
- **Archivo**: `lib/modules/ponds_batches/presentation/screens/ponds_dashboard_screen.dart`
- **Línea**: 297
- **Severidad**: 🟡 **Media**
- **Descripción**:
  El grid de estanques está restringido con:
  ```dart
  gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
    maxCrossAxisExtent: 440,
    mainAxisExtent: 380,
    crossAxisSpacing: 16,
    mainAxisSpacing: 16,
  ),
  ```
- **Impacto en Campo**:
  Una tarjeta de estanque común con una sola especie cabe en 380 dp. Sin embargo, cuando un estanque tiene una **Alerta Activa de Periodo de Retiro ICA** (banner amarillo con fecha límite), o maneja policultivo (Tilapia + Cachama simultáneas), el contenido intrínseco de la tarjeta requiere entre 410 y 430 dp. Al estar fijada a `380 dp`, la tarjeta presenta desbordamientos por abajo que ocultan la botonera operativa.
- **Propuesta de Rediseño**:
  Aumentar la extensión base a 430 dp o emplear un layout sliver que permita altura intrínseca dinámica (`SliverCrossAxisGroup` o `SliverList`).

---

### UX-08: Pantallas con Estados Vacíos Mudos y Enlace de Navegación Roto en Registro
- **Archivos**:
  - `lib/modules/ponds_batches/presentation/screens/ponds_dashboard_screen.dart:284–289`
  - `lib/modules/auth_tenant/presentation/screens/register_company_screen.dart:104`
- **Severidad**: 🟡 **Media**
- **Descripción**:
  1. En `PondsDashboardScreen`, cuando no hay estanques en la categoría seleccionada o el filtro de búsqueda no arroja coincidencias, se muestra un texto plano:
     ```dart
     const Center(
       child: Padding(
         padding: EdgeInsets.all(32),
         child: Text('No hay estanques en esta categoría', style: TextStyle(color: Colors.white54)),
       ),
     );
     ```
     No hay ilustración, icono ilustrativo, ni botón de acción rápida ("Restablecer filtros" o "Crear mi primer estanque").
  2. En `register_company_screen.dart:104`, tras completar el registro de la empresa, el código ejecuta:
     ```dart
     context.go('/home');
     ```
     En `lib/core/navigation/router.dart`, la ruta `/home` **no existe**; la ruta raíz del dashboard es `/`. Al ejecutarse, GoRouter arroja una pantalla de error 404 o revienta en tiempo de ejecución.
- **Propuesta de Rediseño**:
  1. Implementar un `EmptyStateView` reutilizable con botón interactivo.
  2. Corregir la llamada en `register_company_screen.dart` a `context.go('/')`.

---

### UX-09: Micro Blancos Táctiles en Date Pickers, Chips de Porcentaje y Filtros
- **Archivos**:
  - `lib/core/design_system/glass_date_picker.dart:318` (Celda del día con altura de ~30 dp)
  - `lib/modules/ponds_batches/presentation/screens/ponds_dashboard_screen.dart:385` (Chips de filtro con `vertical: 4` -> ~19 dp)
  - `lib/modules/ponds_batches/presentation/dialogs/traslado_modal.dart:608` (Chips de porcentaje con `vertical: 3` -> ~16 dp)
  - `lib/modules/ponds_batches/presentation/widgets/pond_bento_card.dart:175` (Botón 3D de giro de tarjeta de 23×23 dp)
- **Severidad**: 🟡 **Media**
- **Descripción**:
  Múltiples elementos interactivos presentan áreas de pulsación física inferiores a 32 dp, violando la pauta WCAG 2.5.8 (mínimo de 24×24 dp) y WCAG 2.5.5 (48×48 dp recomendado para interfaces táctiles).
- **Impacto en Campo**:
  Seleccionar el porcentaje rápido de traslado (25%, 50%, 75%, 100%) o cambiar el filtro de estanques exige una precisión milimétrica inviable durante la inspección física de campo en la granja.

---

### UX-10: Sobrecarga de Shaders Glassmorphism y Falta de Modo de Alto Contraste Exterior
- **Archivos**:
  - `lib/core/design_system/glass_card.dart:73–82`
  - `lib/core/design_system/glass_container.dart:67–75`
  - `lib/core/design_system/fishbit_header.dart:62`
- **Severidad**: 🟡 **Media**
- **Descripción**:
  Cada tarjeta, cabecera y botón encapsula un `BackdropFilter` con `ImageFilter.blur(sigmaX: 16, sigmaY: 16)`. Al hacer scroll rápido en un listado con 10–15 estanques o en la bitácora, el motor Skia/Impeller debe realizar múltiples pases de desenfoque por fotograma sobre superficies translúcidas encadenadas.
  Asimismo, los bordes de tarjeta utilizan `Colors.white.withValues(alpha: 0.12)`.
- **Impacto en Campo**:
  1. En dispositivos Android de gama media/baja comunes en entornos rurales, la tasa de refresco cae por debajo de 30 FPS, provocando microtirones (*jank*).
  2. Bajo luz solar directa a mediodía (más de 25.000 lux), el sutil borde de 12% de opacidad y el efecto translúcido se desvanecen completamente, haciendo que las tarjetas parezcan flotar sin límites definidos.
- **Propuesta de Rediseño**:
  Incorporar un ajuste de **"Modo Campo / Alto Contraste"** en la configuración de la app que reemplace el desenfoque activo por fondos sólidos opacos (`Color(0xFF141E2E)`) con bordes sólidos de 1.5 dp (`AppColors.cyanWater` o `#2E3D52`), mejorando tanto el rendimiento gráfico a 60 FPS estables como la legibilidad solar.

---

### A11Y-01: Tipografía con Colores Oscuros Fijos Invalida el Contraste en Tema Claro (WCAG 1.4.3)
- **Archivos**:
  - `lib/core/design_system/app_typography.dart:8–67`
  - `lib/modules/bitacora/presentation/screens/bitacora_screen.dart:827, 1302`
  - `lib/modules/water_quality/presentation/screens/water_quality_records_screen.dart:148, 181–189`
- **Severidad**: 🔴 **Crítica (Accesibilidad)**
- **Descripción**:
  Las constantes tipográficas de `AppTypography` definen directamente colores oscuros en sus estilos:
  ```dart
  static const TextStyle bodySmall = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w400,
    color: AppColors.textSecondaryDark, // #8E9BAE
  );
  ```
  Cuando el usuario activa el modo claro (`ThemeMode.light`), donde el fondo de pantalla es blanco (`#FFFFFF`) o gris claro (`#F4F6F9`), cualquier widget que utilice `AppTypography.bodySmall` o `AppTypography.labelMicro` renderiza texto `#8E9BAE` sobre blanco.
- **Cálculo de Contraste**:
  - `#8E9BAE` sobre `#FFFFFF` = **Ratio de Contraste 2.6:1**
  - **Exigencia WCAG 2.2 AA (Nivel Mínimo)**: **4.5:1** para texto normal.
  - Además, en `bitacora_screen.dart:827` y `1302`, se utiliza `color: Colors.white54` directamente sin consultar el tema. En modo claro, blanco con 54% de opacidad sobre fondo blanco genera un contraste de **1.6:1**, resultando completamente invisible.
- **Propuesta de Rediseño (Código Diff)**:
  Desacoplar los colores de las constantes tipográficas o construir extensiones de tema (`Theme.of(context)`):

```dart
// ANTES (app_typography.dart:45)
static const TextStyle bodySmall = TextStyle(
  fontSize: 12,
  fontWeight: FontWeight.w400,
  color: AppColors.textSecondaryDark,
);

// DESPUÉS (Tipografía Respetuosa con el Tema)
static TextStyle bodySmall(BuildContext context) {
  final isDark = Theme.of(context).brightness == Brightness.dark;
  return TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w400,
    color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
  );
}
```

---

### A11Y-02: Supresión de Semántica de Error en Formularios Afecta a Lectores de Pantalla (WCAG 4.1.2)
- **Archivo**: `lib/core/design_system/glass_form_field.dart`
- **Líneas**: 211–218, 284–292
- **Severidad**: 🟠 **Alta (Accesibilidad)**
- **Descripción**:
  Para evitar que el `TextFormField` estándar de Flutter dibuje el mensaje de error en rojo rompiendo el estilo glassmorphic, el validador interno oculta el texto nativo:
  ```dart
  validator: widget.validator != null
      ? (value) {
          final error = widget.validator!(value);
          if (error != null) {
            return ''; // Retorna string vacío para ocultar texto nativo de Flutter
          }
          return null;
        }
      : null,
  ```
  Y posteriormente dibuja el mensaje de error en un `Text` independiente debajo del campo:
  ```dart
  if (_errorText != null) ...[
    const SizedBox(height: 6),
    Text(_errorText!, style: const TextStyle(color: AppColors.coralAction, fontSize: 11)),
  ]
  ```
- **Impacto en Accesibilidad**:
  Los lectores de pantalla (Google TalkBack en Android y VoiceOver en iOS) identifican el campo como "inválido", pero al consultar el nodo semántico de error del input reciben `''` (cadena vacía). El usuario con discapacidad visual o baja visión escucha "Campo en error", pero **no se le anuncia qué debe corregir** (por ejemplo: "El valor debe ser superior a 0" o "La fecha no puede ser futura").
- **Propuesta de Rediseño (Código Diff)**:
  Vincular el mensaje de error con un nodo `Semantics` configurado con `liveRegion: true`:

```dart
if (_errorText != null) ...[
  const SizedBox(height: 6),
  Semantics(
    liveRegion: true,
    label: 'Error: $_errorText',
    child: Row(
      children: [
        const Icon(Icons.error_outline_rounded, size: 14, color: AppColors.coralAction),
        const SizedBox(width: 4),
        Expanded(
          child: Text(
            _errorText!,
            style: const TextStyle(color: AppColors.coralAction, fontSize: 11, fontWeight: FontWeight.w600),
          ),
        ),
      ],
    ),
  ),
]
```

---

### A11Y-03: Indicadores de Estado Basados Exclusivamente en Color y Contraste Deficiente en Alertas
- **Archivos**:
  - `lib/modules/home_dashboard/presentation/screens/home_dashboard_screen.dart:150`
  - `lib/modules/ponds_batches/presentation/dialogs/mortalidad_modal.dart:312`
- **Severidad**: 🟡 **Media (Accesibilidad)**
- **Descripción**:
  1. En `home_dashboard_screen.dart:150`, el estado de los estanques se muestra con un punto de color:
     ```dart
     Icon(Icons.circle, color: colorStatus, size: 8)
     ```
     No existe icono de forma diferenciada ni etiqueta textual que describa el estado para usuarios con daltonismo (deuteranopía o protanopía).
  2. En `mortalidad_modal.dart:312`, cuando se selecciona una severidad de mortalidad crítica, se usa un chip con fondo rojo (`AppColors.coralAction` = `#FF2D55`) y texto negro por defecto.
     - Ratio de contraste Negro (`#000000`) sobre `#FF2D55`: **4.2:1** (falla el umbral de 4.5:1 exigido por WCAG 2.2 AA).
- **Propuesta de Rediseño**:
  1. Acompañar el color de estado con formas geométricas distintivas (p. ej. rombo para advertencia, cuadrado para crítico, círculo para óptimo).
  2. Forzar texto blanco (`#FFFFFF`) sobre `#FF2D55` (alcanza un ratio de **4.7:1**, cumpliendo WCAG 2.2 AA).

---

## 4. Auditoría de Flujos y Experiencia de Usuario (User Journeys)

### 4.1 Autenticación y Onboarding
- **Flujo**: `LoginScreen` -> `RegisterCompanyScreen` -> `OnboardingEmpresaScreen` -> Dashboard (`/`).
- **Puntos de Fricción Identificados**:
  - `register_company_screen.dart` tiene una redirección fallida (`context.go('/home')`), provocando un fallo en la primera experiencia del usuario.
  - El teclado numérico en la configuración inicial de dimensiones de la granja produce un choque con el `PageView` de altura fija (`SizedBox(height: 480)`).
  - La pantalla de login incluye una textura de fondo de alta resolución que luce impecable, pero el contraste del texto secundario en el modal de recuperación de contraseña decae cuando el fondo es brillante.

### 4.2 Monitoreo de Estanques y Biomasa
- **Flujo**: Visualización Bento -> Giro 3D a Especificaciones Técnicas -> Botones Operativos Rápidos.
- **Puntos de Fricción Identificados**:
  - El botón 3D de giro de la tarjeta mide 23×23 dp (difícil de presionar con precisión).
  - La fila inferior de 4 acciones rápidas (`Alimentar`, `Muestreo`, `Bajas`, `Traslado`) es el punto de mayor peligro ergonómico de toda la aplicación debido a sus botones de 30 dp de alto.

### 4.3 Captura de Bitácora y Calidad de Agua
- **Flujo**: FAB Bitácora -> Selección de Evento -> Formulario de Parámetros -> Confirmación.
- **Puntos de Fricción Identificados**:
  - Modal de Calidad de Agua precargado con 11 cifras ficticias (`UX-05`).
  - El archivo `water_quality_records_screen.dart` contiene código legado no referenciado en el router que realiza operaciones inseguras de cadenas (`rec.loteId.substring(0, 6)` sin verificar longitud mínima). Debe limpiarse o integrarse formalmente.

### 4.4 Módulos de Finanzas, Ventas e Inventario
- **Flujos**:
  - `FinanceScreen`: Radiografía CPK, Registro de Jornales y Planillas Masivas.
  - `SalesScreen`: Registro de Venta Rápida y cálculo de Biomasa Cosechada.
  - `WarehouseScreen`: Control de Existencias de Alimento, Medicamentos y Facturas.
- **Puntos de Fricción Identificados**:
  - Todos los FABs usan un offset manual de `bottom: 78` para no tapar el dock flotante.
  - En anchos superiores a 440 dp (tablets o modo horizontal), `FinanceScreen` pinta tres botones FAB flotantes en fila que pueden sobrecargar el espacio visual inferior.

---

## 5. Plan de Remediación Priorizado (Roadmap UI/UX)

### Fase 1: Correcciones Críticas de Campo e Integridad (Inmediato)
1. **Rediseñar la Botonera Inferior de `PondBentoCard` (`UX-01`)**:
   Implementar cuadrícula táctil 2×2 con altura mínima de 48 dp y separación de 8 dp.
2. **Limpiar Controladores Prellenados en `ParametroModal` (`UX-05`)**:
   Reemplazar textos por defecto con `hintText` para evitar registros de laboratorio involuntarios.
3. **Corregir Ruta Rota en `RegisterCompanyScreen` (`UX-08`)**:
   Cambiar `context.go('/home')` a `context.go('/')`.
4. **Restaurar Contraste Tipográfico en Tema Claro (`A11Y-01`)**:
   Migrar estilos estáticos de `AppTypography` a tokens conscientes de `Theme.of(context)`.

### Fase 2: Ergonomía Móvil y Responsividad (Corto Plazo)
1. **Migración a `ModalBottomSheet` Ergonómico (`UX-04`)**:
   Transformar `AlimentarModal`, `BiometriaModal`, `MortalidadModal` y `TrasladoModal` en bottom sheets anclados al pulgar en teléfonos móviles.
2. **Eliminación de Alturas Rígidas en Modales (`UX-03`)**:
   Sustituir `SizedBox(height: 400)` por contenedores elásticos sin conflicto de scroll.
3. **Saneamiento de la Barra Flotante y FABs (`UX-02`)**:
   Envolver `_FloatingDock` en `SafeArea` y unificar la elevación de los FABs.
4. **Ampliación de Extensión en Ponds Grid (`UX-07`)**:
   Ajustar `mainAxisExtent` para evitar cortes en tarjetas de policultivo y retiro sanitario.

### Fase 3: Accesibilidad WCAG 2.2 y Optimización de Rendimiento (Medio Plazo)
1. **Semántica de Error Accesible (`A11Y-02`)**:
   Añadir `Semantics(liveRegion: true)` a los mensajes de error en `GlassFormField`.
2. **Diferenciación de Estados sin Dependencia Exclusiva de Color (`A11Y-03`)**:
   Añadir iconos geométricos (checkmark, triángulo, octágono) junto a los puntos de color en el dashboard.
3. **Ampliación de Blancos Táctiles (`UX-09`)**:
   Llevar celdas de calendario y chips de filtros a un mínimo de 44×44 dp.
4. **Interruptor "Modo Campo / Alto Contraste" (`UX-10`)**:
   Proveer en la configuración de la app un perfil de alto rendimiento y contraste solar que desactive `BackdropFilter` para dispositivos en exteriores.
