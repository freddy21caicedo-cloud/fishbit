# Informe de Auditoría Técnica 360° — Ergonomía de Campo (WCAG 2.2), UI/UX y Arquitectura Offline

**Subagente Explorador:** Explorer Survey 3 (Ergonomía, Accesibilidad y Resiliencia Offline)  
**Fecha de Auditoría:** 2026-10-27  
**Código de Misión:** R3 & R4 Audit (FishBit Finance 2.0)  
**Entorno de Proyecto:** Flutter 3.x / Dart / Riverpod / GoRouter / Supabase PostgreSQL  
**Modo:** Estrictamente Solo Lectura (Investigación Analítica y Asesoramiento Técnico)

---

## Resumen Ejecutivo

Esta auditoría técnica evalúa a profundidad los requerimientos **R3** (*Field Ergonomics, UI/UX Interaction & WCAG 2.2*) y **R4** (*Offline Resilience, State Architecture & Exception Handling*) sobre la base del código fuente en `lib/`. 

Se han identificado vulnerabilidades críticas de usabilidad y estabilidad:
1. **Ergonomía y Dimensiones Táctiles (WCAG 2.5.5):** El botón de acción operativa principal en `pond_bento_card.dart` posee una altura de 40 dp (falla el umbral mandatorio de 48x48 dp para manos húmedas en campo), y el botón de cierre en `glass_action_hub_sheet.dart` mide únicamente 24x24 dp.
2. **Contraste Solar Exterior en Modo Claro (WCAG 1.4.3):** Los acentos de marca como `cyanWater` (`#00B2CC`), `amberWarning` (`#FF9500`) y `greenBiomass` (`#10B981`) se renderizan como texto directo sobre fondos blancos y acrílicos esmerilados (`#FFFFFF` / `#F6F8FA`), arrojando ratios de contraste deficientes de **2.56:1**, **1.98:1** y **2.33:1** (muy por debajo del mínimo de 4.5:1). Además, la función adaptativa `AppColors.accentText()` no se utiliza en ningún widget del aplicativo, y existen casos de inversión de tokens donde se asigna texto blanco (`AppColors.textPrimaryDark`) en modo claro.
3. **Ergonomía a Una Mano en Operaciones de Campo:** Las rutinas críticas de campo (registro de oxígeno/pH, alimentación diaria, muestreo biométrico, mortalidad) se presentan mediante `showDialog()` con `Dialog` centrado. Esto obliga al operario en estanques a extender su pulgar hacia el tercio superior de pantallas de más de 6.5 pulgadas y genera colisiones y desplazamientos bruscos con el teclado virtual.
4. **Cola de Sincronización Offline (`OfflineSyncQueue`):** La cola está **dormida e incompleta**. El método de drenado `flushQueue()` no es invocado en ninguna parte de la aplicación. Repositorios clave como `SupabaseNutritionRepository` y `SupabasePondsRepository` no están conectados a la cola; en ausencia de red, `SupabaseNutritionRepository` almacena datos en un arreglo volátil en memoria RAM (`_demoRecords`) que se borra al cerrar la app, mientras que `SupabasePondsRepository` lanza excepciones sin persistencia local.
5. **Estabilidad de Ciclo de Vida en GoRouter y Shell de Navegación:** El enrutador principal en `lib/app/router.dart` utiliza `ShellRoute` en lugar de `StatefulShellRoute.indexedStack`. Como consecuencia, cada cambio de pestaña destruye la instancia del widget, perdiendo la posición de desplazamiento (*scroll offset*), filtros seleccionados y disparando peticiones remotas innecesarias. Además, pantallas como `BitacoraScreen` emplean separadores fijos `SizedBox(height: 80)` que colisionan con la barra flotante en dispositivos con barras de gestos del sistema (donde el despeje requerido supera los 104 dp).
6. **Manejo de Excepciones y Bloques Silenciosos:** Se detectaron más de 50 ocurrencias de `catch (_)` silencioso que devuelven listas vacías o silencian fallos de persistencia sin notificar al usuario. La jerarquía `AppFailure` está subutilizada (restringida casi exclusivamente a autenticación) y carece de subtipos para fallos de red (`NetworkFailure`) y cola local (`OfflineSyncFailure`).

---

## 1. R3: Ergonomía de Campo y Accesibilidad WCAG 2.2

### 1.1. Dimensiones de Áreas Táctiles en Operaciones de Campo (WCAG 2.5.5)

#### Hallazgo R3.1.1 — Botón de Acción Principal de Bento Card por debajo del umbral de 48 dp
- **Archivo:** `lib/modules/ponds_batches/presentation/widgets/pond_bento_card.dart`
- **Líneas:** 409–425
- **Código Actual:**
  ```dart
  409: SizedBox(
  410:   width: double.infinity,
  411:   height: 40,
  412:   child: ElevatedButton(
  413:     style: ElevatedButton.styleFrom(
  414:       backgroundColor: AppColors.cyanWater.withValues(alpha: isDark ? 0.18 : 0.12),
  ...
  424:       padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
  425:     ),
  ```
- **Causa Raíz:** El contenedor tiene una restricción explícita `height: 40`. De acuerdo con el estándar WCAG 2.2 criterio 2.5.5 (Target Size AAA) y las especificaciones ergonómicas de Android Material Design / iOS Human Interface Guidelines, las metas táctiles en operaciones de campo deben medir un mínimo de **48x48 dp** (o 54 dp para operarios con guantes o dedos húmedos al pie de estanques de tierra o geomembrana).
- **Impacto:** Alta tasa de pulsaciones fallidas en campo cuando el piscicultor opera con una mano mientras sostiene una red o sonda multiparamétrica.
- **Solución Propuesta (Diff):**
  ```diff
  - SizedBox(
  -   width: double.infinity,
  -   height: 40,
  -   child: ElevatedButton(
  + SizedBox(
  +   width: double.infinity,
  +   height: 48,
  +   child: ElevatedButton(
  +     style: ElevatedButton.styleFrom(
  +       minimumSize: const Size.fromHeight(48),
  +       padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
  ```

#### Hallazgo R3.1.2 — Micro-Botón de Cierre en GlassActionHubSheet (24x24 dp)
- **Archivo:** `lib/core/design_system/glass_action_hub_sheet.dart`
- **Líneas:** 103–117
- **Código Actual:**
  ```dart
  103: Material(
  104:   color: Colors.transparent,
  105:   child: InkWell(
  106:     onTap: () => Navigator.of(context).pop(),
  107:     borderRadius: BorderRadius.circular(12),
  108:     child: Container(
  109:       padding: const EdgeInsets.all(4),
  110:       decoration: BoxDecoration(
  111:         color: Colors.white.withValues(alpha: 0.08),
  112:         shape: BoxShape.circle,
  113:       ),
  114:       child: const Icon(Icons.close_rounded, size: 16, color: AppColors.textSecondaryDark),
  115:     ),
  116:   ),
  117: ),
  ```
- **Causa Raíz:** El botón utiliza un `Icon` de 16 px con un `padding` de 4 px, resultando en un área táctil efectiva de solo **24x24 dp**, incumpliendo tanto WCAG 2.5.5 (48x48 dp) como WCAG 2.5.8 (24x24 con espaciado sin solapamiento).
- **Impacto:** Dificultad severa para cerrar el Hub "Más" en dispositivos móviles sin tocar inadvertidamente los mosaicos inferiores.
- **Solución Propuesta (Diff):**
  ```diff
  - Material(
  -   color: Colors.transparent,
  -   child: InkWell(
  -     onTap: () => Navigator.of(context).pop(),
  -     borderRadius: BorderRadius.circular(12),
  -     child: Container(
  -       padding: const EdgeInsets.all(4),
  -       decoration: BoxDecoration(
  -         color: Colors.white.withValues(alpha: 0.08),
  -         shape: BoxShape.circle,
  -       ),
  -       child: const Icon(Icons.close_rounded, size: 16, color: AppColors.textSecondaryDark),
  -     ),
  -   ),
  - ),
  + SizedBox(
  +   width: 48,
  +   height: 48,
  +   child: IconButton(
  +     icon: const Icon(Icons.close_rounded, size: 20),
  +     color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
  +     tooltip: 'Cerrar Menú',
  +     onPressed: () => Navigator.of(context).pop(),
  +   ),
  + ),
  ```

---

### 1.2. Contraste Solar Exterior en Tema Claro (WCAG 1.4.3)

#### Hallazgo R3.2.1 — Falla Severa de Contraste en Colores de Acento Usados como Texto
- **Archivo:** `lib/core/design_system/app_colors.dart`, `lib/core/design_system/theme_provider.dart`, `lib/modules/ponds_batches/presentation/widgets/pond_bento_card.dart`
- **Evaluación Científica de Luminancia Relativa (sRGB / WCAG 2.2):**
  - Fondo Blanco (`#FFFFFF`): Luminancia $L = 1.0$
  - Fondo Claro Base (`#F6F8FA`): Luminancia $L \approx 0.948$
  - `cyanWater` (`#00B2CC`): Luminancia $L \approx 0.360$  
    $$\text{Ratio} = \frac{1.0 + 0.05}{0.360 + 0.05} = \frac{1.05}{0.410} = \mathbf{2.56:1} \quad (\text{Falla WCAG 4.5:1})$$
  - `amberWarning` (`#FF9500`): Luminancia $L \approx 0.481$  
    $$\text{Ratio} = \frac{1.05}{0.481 + 0.05} = \frac{1.05}{0.531} = \mathbf{1.98:1} \quad (\text{Falla Crítica})$$
  - `greenBiomass` (`#10B981`): Luminancia $L \approx 0.401$  
    $$\text{Ratio} = \frac{1.05}{0.401 + 0.05} = \frac{1.05}{0.451} = \mathbf{2.33:1} \quad (\text{Falla WCAG 4.5:1})$$
  - `textTertiaryLight` (`#64748B`) sobre `#F6F8FA`:  
    $$\text{Ratio} = \frac{0.948 + 0.05}{0.177 + 0.05} = \frac{0.998}{0.227} = \mathbf{4.39:1} \quad (\text{Falla 4.5:1 en texto pequeño } < 18\text{pt})$$
- **Causa Raíz:** En `AppColors` se diseñaron las variantes adaptativas para texto claro (`cyanWaterTextLight = Color(0xFF007A8C)`, `greenBiomassTextLight = Color(0xFF047857)`, `amberWarningTextLight = Color(0xFFB45309)`), y la función `AppColors.accentText(context, color)`. Sin embargo, **ningún widget en todo el repositorio invoca `accentText()`**. En su lugar, los widgets consumen `AppColors.cyanWater` o `AppColors.greenBiomass` directamente en `TextStyle.color`.
- **Efecto en Terreno:** En estanques piscícolas a cielo abierto bajo irradiación solar directa (entre 50,000 y 100,000 lux en zonas tropicales de Colombia como Huila, Meta o Santander), el reflejo especular en el cristal del teléfono anula la visualización de valores con contraste menor a 4.5:1, haciendo ilegibles métricas vitales como el Oxígeno Disuelto y la Densidad.

#### Hallazgo R3.2.2 — Inversión Errónea de Tokens (Texto Blanco en Modo Claro)
- **Archivo:** `lib/modules/ponds_batches/presentation/widgets/pond_bento_card.dart`
- **Líneas Identificadas:**
  - Línea 217:  
    `color: isRealActive ? (isDark ? Colors.white : AppColors.textPrimaryDark) : AppColors.textTertiaryDark`  
    *(Nota: `AppColors.textPrimaryDark` es `#FFFFFF`. Si `!isDark`, evalúa a texto blanco sobre fondo claro).*
  - Línea 248:  
    `style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600)`  
    *(Texto de especies en policultivo forzado a blanco sin importar el brillo del tema).*
  - Línea 510 & 512:  
    `color: isDark ? Colors.white : AppColors.textPrimaryDark`  
    `style: TextStyle(color: isDark ? Colors.white : AppColors.textPrimaryDark, ...)`
  - Línea 566:  
    `: (isDark ? Colors.white70 : AppColors.textPrimaryDark)`
- **Impacto:** Elementos de UI y etiquetas de policultivo se vuelven invisibles al alternar la app a Tema Claro.
- **Solución Propuesta (Diff):**
  ```diff
  - color: isRealActive ? (isDark ? Colors.white : AppColors.textPrimaryDark) : AppColors.textTertiaryDark,
  + color: isRealActive ? (isDark ? Colors.white : AppColors.textPrimaryLight) : (isDark ? AppColors.textTertiaryDark : AppColors.textTertiaryLight),
  
  - style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600),
  + style: TextStyle(
  +   color: isDark ? Colors.white : AppColors.textPrimaryLight,
  +   fontSize: 12,
  +   fontWeight: FontWeight.w600,
  + ),
  ```

---

### 1.3. Ergonomía a Una Mano: Bottom Sheets vs. Centered Dialogs

#### Hallazgo R3.3.1 — Modales Operativos de Campo Centrados en Pantalla
- **Archivos Auditados:**
  - `lib/modules/water_quality/presentation/dialogs/parametro_modal.dart` (línea 21, 110)
  - `lib/modules/ponds_batches/presentation/dialogs/alimentar_modal.dart` (línea 25, 122)
  - `lib/modules/ponds_batches/presentation/dialogs/biometria_modal.dart` (línea 20)
  - `lib/modules/ponds_batches/presentation/dialogs/mortalidad_modal.dart` (línea 21)
  - `lib/modules/ponds_batches/presentation/dialogs/traslado_modal.dart` (línea 20)
  - `lib/modules/ponds_batches/presentation/dialogs/siembra_modal.dart` (línea 26)
  - `lib/modules/ponds_batches/presentation/dialogs/crear_estanque_modal.dart` (línea 23)
- **Causa Raíz:** Todos estos flujos utilizan `showDialog()` y retornan `Dialog(insetPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 20))`.
- **Análisis de Ergonomía de Campo:**
  1. **Zona de Alcance del Pulgar (*Thumb Zone*):** En dispositivos de 6.1" a 6.8" (dimensiones habituales de smartphones de campo), el tercio superior de la pantalla está fuera del alcance natural del pulgar en agarre a una mano. El botón de cerrar (esquina superior derecha) y los primeros campos del formulario exigen cambiar el agarre o usar la segunda mano (que con frecuencia está ocupada sosteniendo instrumental o mojada).
  2. **Colisión con el Teclado Virtual (*Soft Keyboard Shift*):** Al pulsar sobre un campo numérico como Temperatura o pH, el teclado del sistema desplaza el `Dialog` hacia arriba sin anclaje suave, lo cual con frecuencia provoca advertencias de desbordamiento de renderizado (`A RenderFlex overflowed by X pixels`) o sitúa el botón "Guardar" fuera de la vista accesible.
  3. **Patrón Recomendado (*Modal Bottom Sheet Adaptativo*):**
     - En pantallas móviles (`width < 600 dp`): Desplegar mediante `showModalBottomSheet(isScrollControlled: true)` con borde superior redondeado, tirador de arrastre táctil (*drag handle*), acciones primarias fijas en la parte inferior respetando `SafeArea`, y compensación automática de teclado vía `padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom)`.
     - En Web / Desktop (`width >= 600 dp`): Mantener el centrado con restricciones de ancho máximo (520 dp) para una experiencia limpia de escritorio.

---

## 2. R4: Resiliencia de Datos Offline y Arquitectura de Estado

### 2.1. Arquitectura de Sincronización Offline (`OfflineSyncQueue`)

#### Hallazgo R4.1.1 — `flushQueue()` Huérfano y Dormido
- **Archivo:** `lib/core/storage/offline_sync_queue.dart`
- **Líneas:** 97–131
- **Observación:** El método estático `flushQueue(SupabaseClient supabase)` está completamente implementado para procesar los registros locales pendientes y sincronizarlos con Supabase. Sin embargo, una búsqueda en todo el proyecto demuestra que **no existe una sola llamada a `flushQueue()`** en ningún archivo del workspace.
- **Impacto:** Los registros que llegan a ser encolados localmente jamás se reintentan de forma autónoma. Permanecen inertes en `SharedPreferences` de por vida o hasta que la memoria caché del dispositivo sea borrada manualmente por el usuario.

#### Hallazgo R4.1.2 — Repositorios de Producción Desconectados de la Cola Offline
- **Archivos Auditados:**
  1. `lib/modules/feeding_nutrition/infrastructure/repositories/supabase_nutrition_repository.dart` (líneas 104–140):
     - Cuando falla el `insert` en Supabase por caída de red, el bloque `catch (_)` inserta el registro en la lista en memoria `_demoRecords.insert(0, record)`.
     - **Riesgo Crítico de Pérdida de Datos:** `_demoRecords` reside en la memoria volátil de la aplicación. En cuanto el sistema operativo finaliza el proceso de Flutter o el usuario cierra la app en segundo plano, todas las raciones de alimento registradas en campo se pierden irreversiblemente. Nunca se llama a `OfflineSyncQueue.enqueue()`.
  2. `lib/modules/ponds_batches/infrastructure/repositories/supabase_ponds_repository.dart` (líneas 940–943, 1103–1106):
     - Tanto en `registerBiometry()` como en `recordMortality()`, en caso de fallo de red el bloque `catch (e)` simplemente imprime en consola y ejecuta `rethrow`.
     - El operario en campo ve un error de red y el pesaje biométrico o reporte de bajas sanitarias se descarta.
  3. `lib/modules/water_quality/infrastructure/repositories/supabase_water_quality_repository.dart` (líneas 127–158):
     - Es el **único repositorio** que actualmente invoca `OfflineSyncQueue.enqueue()`. Sin embargo, al no existir mecanismo de drenado (`flushQueue`), los parámetros de calidad de agua quedan varados en el almacenamiento local.

#### Patrón Arquitectónico de Solución para Repositorios:
Cada repositorio debe implementar el patrón *Write-Through with Local-First Fallback*:
```dart
Future<T> saveEntity(T entity) async {
  try {
    await _supabase.from(tableName).insert(entity.toJson());
    return entity;
  } on SocketException catch (_) {
    await OfflineSyncQueue.enqueue(type: actionType, table: tableName, payload: entity.toJson());
    return entity; // Retorno optimista para no interrumpir el flujo del operario
  } on PostgrestException catch (e) {
    throw ServerFailure(e.message, e.code);
  }
}
```
Además, un servicio singleton o Riverpod Provider (`OfflineSyncService`) debe escuchar cambios de conectividad (`connectivity_plus`) y el ciclo de vida del app (`AppLifecycleState.resumed`) para desencadenar `OfflineSyncQueue.flushQueue(_supabase)`.

---

### 2.2. Estabilidad de Ciclo de Vida en GoRouter y Shell de Navegación

#### Hallazgo R4.2.1 — Destrucción de Estado por Uso de `ShellRoute` en lugar de `StatefulShellRoute`
- **Archivo:** `lib/app/router.dart`
- **Líneas:** 126–165
- **Código Actual:**
  ```dart
  126: ShellRoute(
  127:   builder: (context, state, child) => MainNavigationShell(child: child),
  128:   routes: [
  129:     GoRoute(path: '/', builder: (context, state) => const HomeDashboardScreen()),
  130:     GoRoute(path: '/ponds', builder: (context, state) => const PondsDashboardScreen()),
  131:     GoRoute(path: '/warehouse', builder: (context, state) => const WarehouseScreen()),
  132:     GoRoute(path: '/bitacora', builder: (context, state) => const BitacoraScreen()),
  ...
  ```
- **Causa Raíz:** `ShellRoute` destruye y desmonta el árbol de widgets de la ruta anterior cada vez que el usuario navega a otra pestaña del Dock inferior.
- **Impacto en Producción:**
  1. Pérdida completa de la posición del scroll: si el piscicultor desciende en la lista de 20 estanques en `PondsDashboardScreen`, pasa a `Almacén` a revisar bultos de alimento, y regresa a `Estanques`, la pantalla se reinicia en el tope.
  2. Pérdida de estados locales efímeros (pestaña activa en `BitacoraScreen`, filtro de especie seleccionado, cartas con giro 3D activo).
  3. Disparo redundante de consultas remotas: cada remonte vuelve a consultar `FutureProvider` y colecciones remotas, consumiendo ancho de banda celular limitado en zonas rurales.
- **Solución Propuesta:** Migrar a `StatefulShellRoute.indexedStack`:
  ```dart
  StatefulShellRoute.indexedStack(
    builder: (context, state, navigationShell) => MainNavigationShell(navigationShell: navigationShell),
    branches: [
      StatefulShellBranch(routes: [GoRoute(path: '/', ...)]),
      StatefulShellBranch(routes: [GoRoute(path: '/ponds', ...)]),
      StatefulShellBranch(routes: [GoRoute(path: '/warehouse', ...)]),
      StatefulShellBranch(routes: [GoRoute(path: '/bitacora', ...)]),
    ],
  )
  ```

#### Hallazgo R4.2.2 — Despeje de Barra Flotante Roto en Bitácora y Gestión de Equipo
- **Archivos:**
  - `lib/modules/bitacora/presentation/screens/bitacora_screen.dart` (líneas 718, 961, 1179, 1738)
  - `lib/modules/auth_tenant/presentation/screens/gestion_equipo_screen.dart` (línea 140)
- **Código Actual:**
  ```dart
  // bitacora_screen.dart
  if (index == filteredParams.length + 1) {
    return const SizedBox(height: 80);
  }
  ```
- **Causa Raíz:** Se usa una altura estática fija `SizedBox(height: 80)`.
- **Cálculo de Colisión:**
  - `FloatingDockLayout.dockHeight` = 58 dp
  - `FloatingDockLayout.dockBottomMargin` = 12 dp
  - Inset de barra de gestos en iOS/Android moderno (`MediaQuery.viewPadding.bottom`) = 34 dp
  - Despeje total mínimo requerido = $58 + 12 + 34 + 16 = \mathbf{120\text{ dp}}$.
  - Al utilizar 80 dp, los últimos 40 dp del último registro de la lista quedan permanentemente ocultos detrás del dock flotante acrílico, imposibilitando su lectura o pulsación.
- **Solución Propuesta:** Reemplazar los `SizedBox(height: 80)` por `DockBottomSpacer()` o `SliverDockBottomSpacer()`, los cuales calculan dinámicamente el despeje exacto según el dispositivo.

---

### 2.3. Detección de Bloques Silenciosos `catch (_)` y Migración a `AppFailure`

#### Hallazgo R4.3.1 — Ocultación Masiva de Errores con `catch (_)`
- **Archivos Afectados (Muestra de Alta Severidad):**
  - `lib/modules/feeding_nutrition/infrastructure/repositories/supabase_nutrition_repository.dart` (líneas 45, 106, 116, 130, 156)
  - `lib/modules/warehouse_inventory/infrastructure/repositories/supabase_warehouse_repository.dart` (líneas 81, 138)
  - `lib/modules/sales_harvest/infrastructure/repositories/supabase_sales_repository.dart` (línea 83)
  - `lib/modules/auth_tenant/presentation/providers/auth_provider.dart` (líneas 465, 498, 506)
  - `lib/modules/warehouse_inventory/presentation/providers/warehouse_provider.dart` (líneas 371, 415, 438, 481, 489, 499)
- **Causa Raíz:** Uso indiscriminado de `try { ... } catch (_) { return []; }` o `catch (_) {}`.
- **Impacto:** Si Supabase deniega un registro por violación de Row-Level Security (RLS), o si la conexión TCP se corta a medio camino, la aplicación no emite ninguna advertencia al usuario, simulando que la operación fue exitosa o mostrando pantallas vacías sin botón de reintento (*retry*).

#### Hallazgo R4.3.2 — Jerarquía `AppFailure` Incompleta
- **Archivo:** `lib/core/errors/app_failure.dart`
- **Observación:** La clase abstracta `AppFailure` solo define `ServerFailure`, `AuthFailure`, `ValidationFailure` y `NotFoundFailure`.
- **Deficiencia:** No existen tipos para:
  1. `NetworkFailure`: Desconexión de socket, timeout de DNS, pérdida de señal 4G en campo.
  2. `OfflineSyncFailure`: Error de persistencia en SQLite/SharedPreferences al intentar encolar localmente.
  3. `PermissionFailure`: Rechazo de políticas RLS por pertenecer a otra empresa (aislamiento multi-tenant).
- **Esquema de Migración Propuesto:**
  ```dart
  class NetworkFailure extends AppFailure {
    const NetworkFailure([String message = 'Sin conexión a internet en campo', String? code])
        : super(message, code);
  }

  class OfflineSyncFailure extends AppFailure {
    const OfflineSyncFailure(super.message, [super.code]);
  }

  class PermissionFailure extends AppFailure {
    const PermissionFailure(super.message, [super.code]);
  }
  ```

---

## 3. Matriz Priorizada de Acciones Correctivas

| ID | Módulo / Archivo | Criterio | Impacto | Esfuerzo | Acción Recomendada |
|---|---|---|---|---|---|
| **ERG-01** | `pond_bento_card.dart:411` | WCAG 2.5.5 | **Alto** | Inmediato | Aumentar altura del botón de acción rápida de 40 dp a 48 dp mínimo con `minimumSize: Size.fromHeight(48)`. |
| **ERG-02** | `glass_action_hub_sheet.dart:108` | WCAG 2.5.5 | **Medio** | Inmediato | Reemplazar micro-botón circular de 24 dp por `IconButton` de 48x48 dp. |
| **A11Y-01** | `app_colors.dart:56`, `pond_bento_card.dart` | WCAG 1.4.3 | **Alto** | Corto | Aplicar `AppColors.accentText(context, color)` en todos los textos de acento (`cyanWater`, `greenBiomass`, `amberWarning`) para garantizar ratio $\ge 4.5:1$ en fondos claros. |
| **A11Y-02** | `pond_bento_card.dart:217, 248, 510` | WCAG 1.4.3 | **Alto** | Corto | Corregir inversión de tokens: sustituir `AppColors.textPrimaryDark` por `textPrimaryLight` cuando el brillo sea claro. |
| **A11Y-03** | `theme_provider.dart:143, 188` | WCAG 1.4.3 | **Alto** | Corto | Actualizar `ColorScheme.light.primary` y `tabBarTheme.labelColor` a `cyanWaterTextLight` (`#007A8C`, ratio 5.1:1). |
| **UX-01** | `parametro_modal.dart`, `alimentar_modal.dart`, etc. | Ergonomía | **Medio** | Medio | Crear helper `showResponsiveModal()` que use `showModalBottomSheet` en móviles ($<600$ dp) y `showDialog` en Web/Desktop. |
| **OFF-01** | `offline_sync_queue.dart:97` | Resiliencia | **Crítico** | Medio | Crear `OfflineSyncService` que escuche reconexión de red (`connectivity_plus`) y ejecute `flushQueue()`. |
| **OFF-02** | `supabase_nutrition_repository.dart:130` | Resiliencia | **Crítico** | Corto | Eliminar fallback a `_demoRecords` volátil en RAM y conectar mutaciones de alimentación a `OfflineSyncQueue.enqueue()`. |
| **OFF-03** | `supabase_ponds_repository.dart:940, 1103` | Resiliencia | **Crítico** | Corto | Conectar `registerBiometry` y `recordMortality` a `OfflineSyncQueue.enqueue()` ante fallos de red. |
| **ROUT-01** | `router.dart:126` | Ciclo de Vida | **Alto** | Medio | Migrar de `ShellRoute` a `StatefulShellRoute.indexedStack` para preservar estado, scroll y evitar refetching en tabs. |
| **ROUT-02** | `bitacora_screen.dart`, `gestion_equipo_screen.dart` | SafeArea / Insets | **Medio** | Corto | Reemplazar `SizedBox(height: 80)` por `DockBottomSpacer()` para evitar oclusión con la barra de gestos del sistema. |
| **ERR-01** | `app_failure.dart`, repositorios Supabase | Arquitectura | **Medio** | Medio | Añadir `NetworkFailure` y tipar bloques `catch (e)` para transformar excepciones de Postgrest/Socket en fallos controlados. |

---

## 4. Conclusión de la Auditoría

El sistema FishBit cuenta con una base estética de alta calidad visual (*Dark OLED Luxury* y *Glassmorphism*). No obstante, para garantizar su viabilidad en entornos productivos acuícolas de campo, es indispensable resolver la discrepancia de contrastes en exteriores (donde el sol tropical exige $\ge 4.5:1$), elevar las áreas táctiles al estándar WCAG 2.5.5 ($\ge 48$ dp), activar el mecanismo de sincronización offline actualmente inerte para no perder datos en zonas rurales sin cobertura, y estabilizar el ciclo de vida de la navegación mediante `StatefulShellRoute`.
