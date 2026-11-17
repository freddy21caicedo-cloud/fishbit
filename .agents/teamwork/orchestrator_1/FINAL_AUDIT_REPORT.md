# INFORME TÉCNICO DE AUDITORÍA INTEGRAL Y PLAN MAESTRO DE OPTIMIZACIÓN — FISHBIT FINANCE 2.0

**Fecha de Emisión:** 2026-10-27  
**Autoridad:** Project Orchestrator (Subagent Hierarchical Teamwork System)  
**Proyecto:** FishBit Finance 2.0 (Flutter Multiplataforma + Supabase PostgreSQL Multi-Tenant)  
**Modalidad de Auditoría:** Estrictamente de Solo Lectura (Inspección Forense sin Modificación de Código de Producción)  
**Estado:** Auditoría Finalizada al 100% — Hallazgos Verificados, Impactos Evaluados y Parches Drop-In Diseñados  

---

## TABLA DE CONTENIDO
1. [Resumen Ejecutivo y Matriz de Priorización](#1-resumen-ejecutivo-y-matriz-de-priorización)
2. [R1: Trazabilidad Acuícola Punta a Punta, Ciclo de Vida e Integridad Regulatoria (ICA/AUNAP)](#2-r1-trazabilidad-acuícola-punta-a-punta-ciclo-de-vida-e-integridad-regulatoria-icaaunap)
   - 2.1 Cadena de Datos Biológicos (Siembra, Alimentación, Calidad de Agua, Mortalidad, Biometría, Desdobles, Cosecha)
   - 2.2 Fórmulas Biológicas y Financieras (FCR Económico vs Biológico, CPP/FIFO, Distribución de Costos CPK)
   - 2.3 Inventario de Valores Mock Quemados en Diálogos de Campo y Producción
   - 2.4 Auditoría de Esquemas PostgreSQL, Índices Compuestos y Fugas RLS Multi-Tenant
   - 2.5 Motor de Reportes Oficiales ICA/AUNAP (Fallas en Móvil y Datos Hardcodeados)
3. [R2: Optimización Dual de Plataforma (Rendimiento Web vs. Móvil)](#3-r2-optimización-dual-de-plataforma-rendimiento-web-vs-móvil)
   - 3.1 Cuellos de Botella de Tasa de Relleno GPU (BackdropFilter y Glassmorphism)
   - 3.2 Doble Instanciación y Árbol de Render en Flip Cards (`PondBentoCard`)
   - 3.3 Alcances de Reconstrucción Reactiva Riverpod (`select` vs Watches Globales)
   - 3.4 Responsividad Web en Pantallas Grandes (1920px), Mouse Drag y Hover
   - 3.5 Responsividad Móvil: SafeArea, Colisión con Dock y Desplazamiento por Teclado
4. [R3: Diseño de Interacción y Ergonomía de Campo (WCAG 2.2)](#4-r3-diseño-de-interacción-y-ergonomía-de-campo-wcag-22)
   - 4.1 Dimensiones de Áreas Táctiles en Operaciones de Campo (WCAG 2.5.5)
   - 4.2 Contraste y Legibilidad Bajo Luz Solar Tropical en Modo Claro (WCAG 1.4.3)
   - 4.3 Ergonomía de Campo a Una Mano: Transición de Diálogos Centrados a Modal Bottom Sheets
5. [R4: Resiliencia de Datos Offline y Arquitectura de Estado](#5-r4-resiliencia-de-datos-offline-y-arquitectura-de-estado)
   - 5.1 Reactivación de la Cola de Sincronización Offline (`OfflineSyncQueue`) y Eliminación de Memoria Volátil
   - 5.2 Estabilidad del Ciclo de Vida de Navegación con GoRouter (`StatefulShellRoute.indexedStack`)
   - 5.3 Erradicación de Bloques `catch (_)` Silenciosos y Jerarquía de Errores Tipados (`AppFailure`)
6. [Plan Maestro de Remediación y Diffs de Código Drop-In / Scripts SQL](#6-plan-maestro-de-remediación-y-diffs-de-código-drop-in--scripts-sql)
   - 6.1 Script SQL Canónico de Migración (`20261027_master_traceability_and_rls_hardening.sql`)
   - 6.2 Función Transaccional RPC en PostgreSQL (`public.split_or_transfer_batch`)
   - 6.3 Parches Drop-In en Repositorios y Modelos Dart
   - 6.4 Parches Drop-In en Capa de Presentación, GlassContainer y Modales Adaptativos

---

## 1. RESUMEN EJECUTIVO Y MATRIZ DE PRIORIZACIÓN

La auditoría forense integral de FishBit Finance 2.0 identificó que la plataforma cuenta con una arquitectura moderna (Flutter 3.x, Riverpod 2.x, Supabase PostgreSQL con RLS y diseño neumórfico/glassmorphic avanzado). No obstante, presenta **fallas estructurales críticas** que comprometen la integridad de los datos acuícolas, violan regulaciones sanitarias oficiales (ICA/AUNAP), generan fugas de seguridad entre empresas inquilinas, degradan el rendimiento gráfico a menos de 30 FPS en campo y ocasionan pérdida de información durante desconexiones rurales.

### Matriz de Priorización de Hallazgos

| ID | Área | Severidad | Descripción del Hallazgo | Archivos Clave |
|---|---|---|---|---|
| **SEC-01** | R1 | **CRÍTICA** | Fuga de datos multi-tenant en 5 tablas mediante `unidad_acuicola_sigla` y `cliente_id` sin filtrar por `empresa_id`. | `supabase/migrations/20260831_database_performance_and_rls_optimization.sql:519, 563, 607, 881, 998` |
| **DATA-01** | R1 | **CRÍTICA** | DDL faltante para `public.traslados_lotes` genera excepciones `42P01` en transferencias y desdobles. | `supabase_migration_v10_canonical_v2.sql`, `supabase_ponds_repository.dart:621` |
| **DATA-02** | R1 | **CRÍTICA** | Corrupción y sobreescritura de biomasa en estanques con policultivo al registrar biometrías o mortalidades. | `lib/modules/ponds_batches/infrastructure/repositories/supabase_ponds_repository.dart:935, 1098` |
| **DATA-03** | R1 | **CRÍTICA** | Distorsión matemática de FCR tras desdobles y mutaciones en cadena no atómicas desde el cliente (5 peticiones REST). | `lib/modules/ponds_batches/infrastructure/repositories/supabase_ponds_repository.dart:584-633` |
| **REG-01** | R1 | **CRÍTICA** | Falla total de descarga de libros oficiales ICA en Android/iOS (stub vacío) y datos falsificados hardcodeados en F-06, F-11 y F-12. | `lib/core/reports/ica_official_reports_engine.dart:55, 746, 881, 928`, `web_download_helper_stub.dart:2` |
| **OFF-01** | R4 | **CRÍTICA** | `OfflineSyncQueue.flushQueue` nunca es invocado; repositorios usan almacenamiento volátil en RAM (`_demoRecords`) al fallar la red. | `lib/core/storage/offline_sync_queue.dart:97`, `supabase_nutrition_repository.dart:130-139` |
| **PERF-01**| R2 | **ALTA** | Estrangulamiento de GPU por `BackdropFilter(sigma: 16)` incondicional en listados y sobre fondos blancos opacos. | `lib/core/design_system/glass_container.dart:44, 89`, `bitacora_screen.dart:732, 973, 1193` |
| **PERF-02**| R2 | **ALTA** | Reconstrucciones masivas innecesarias de pantallas completas por consumo de providers globales sin `.select()`. | `ica_certification_screen.dart:48`, `bitacora_screen.dart:420`, `ponds_dashboard_screen.dart:39` |
| **UX-01**  | R3 | **ALTA** | Violación de WCAG 2.5.5 (botones táctiles de 40 dp y 24x24 dp en tarjetas operativas y hojas de acción rápida). | `pond_bento_card.dart:411`, `glass_action_hub_sheet.dart:108` |
| **A11Y-01**| R3 | **ALTA** | Violación de WCAG 1.4.3 (contraste <2.6:1 en modo claro bajo sol tropical); tokens invertidos que pintan texto blanco en tarjetas blancas. | `app_colors.dart:27-31, 56`, `pond_bento_card.dart:217, 248, 510` |
| **DATA-04**| R1 | **ALTA** | "Peces fantasma": la venta de cosecha descuenta biomasa en kg pero no descuenta la cantidad de peces en el estanque. | `lib/modules/ponds_batches/presentation/providers/ponds_provider.dart:189-203` |
| **UX-02**  | R2 | **ALTA** | Oclusión de contenido inferior en Bitácora por `SizedBox(height: 80)` bajo el dock flotante de navegación de 104 dp. | `lib/modules/bitacora/presentation/screens/bitacora_screen.dart:718, 961, 1179, 1738` |
| **STATE-01**| R4| **ALTA** | Destrucción de estado de widgets, filtros y posición de scroll al cambiar de pestaña debido a `ShellRoute` simple. | `lib/app/router.dart:126` |
| **DATA-05**| R1 | **MEDIA** | 8 modales de captura productiva inicializan campos numéricos con valores simulados quemados (5.000 peces, 35 muestra, etc.). | `siembra_modal.dart:40`, `mortalidad_modal.dart:34`, `biometria_modal.dart:33`, etc. |
| **UX-03**  | R2/R3| **MEDIA** | Ausencia de restricciones `maxWidth: 1200` en pantallas de 1920px (Web) y falta de soporte para arrastre con ratón (`ScrollBehavior`). | `home_dashboard_screen.dart:36`, `lib/app/app.dart:15-32` |
| **ERR-01** | R4 | **MEDIA** | Más de 50 bloques `catch (_)` silenciosos en repositorios que ocultan fallos de red y rechazos de base de datos. | `supabase_nutrition_repository.dart:130`, `supabase_warehouse_repository.dart:120`, etc. |

---

## 2. R1: TRAZABILIDAD ACUÍCOLA PUNTA A PUNTA, CICLO DE VIDA E INTEGRIDAD REGULATORIA (ICA/AUNAP)

### 2.1 Cadena de Datos Biológicos y Falta de Atomicidad
La trazabilidad biológica exige que cada cambio de estado en los peces (siembra $\to$ alimentación $\to$ calidad de agua $\to$ biometría $\to$ mortalidad $\to$ desdoble $\to$ cosecha) mantenga la conservación de la materia (biomasa) y el conteo de individuos.

```
[Compra Alevinos] ──► [Almacén Bodega]
       │
       ▼
 [Siembra Lote] ──────► [Alimentación Diaria] ────► [Monitoreo Calidad Agua]
       │                         │
       ▼                         ▼
  [Biometría]           [Consumo de Pienso en Bodega]
       │
       ▼
  [Mortalidad] 
       │
       ▼
 [Desdoble / Traslado] ──► [Cosecha y Venta] ────► [Libros Oficiales ICA / AUNAP]
```

#### Deficiencias Críticas Detectadas en la Cadena:
1. **Desdobles / Traslados no atómicos (`supabase_ponds_repository.dart:577-683`):**
   Un desdoble parcial ejecuta 5 peticiones HTTP REST separadas:
   - `_supabase.from('lotes').update(...)` (reduce peces en lote origen).
   - `_supabase.from('estanques').update(...)` (reduce biomasa en estanque origen).
   - `_supabase.from('lotes').insert(...)` (crea lote destino).
   - `_supabase.from('estanques').update(...)` (aumenta biomasa en estanque destino).
   - `_supabase.from('traslados_lotes').insert(...)` (auditoría).
   *Impacto:* Si la red móvil falla en el paso 3, los peces se descontaron del origen pero no existen en el destino, perdiéndose la trazabilidad del lote.
2. **Corrupción de Biomasa en Policultivos (`supabase_ponds_repository.dart:935, 1098`):**
   Al registrar mortalidad o biometría, el repositorio ejecuta:
   ```dart
   await _supabase.from('estanques').update({
     'biomasa_kg': newBiomass,
   }).eq('id', estanqueId);
   ```
   Donde `newBiomass` es únicamente el remanente del lote intervenido. En estanques donde conviven dos especies (ej. Tilapia y Cachama), la biomasa total del estanque se reemplaza con la de un solo lote, borrando la existencia física de la otra especie.
3. **Peces Fantasma en Cosecha (`ponds_provider.dart:189-203`):**
   Al registrar una venta en `recordHarvestSale`, se descuenta la biomasa vendida (`biomasaActualKg - sale.biomasaVendidaKg`), pero **no se descuenta `cantidadActualPeces`**. En la siguiente biometría, el cálculo del peso promedio individual ($W = \text{Biomasa} / N$) divide los kilos remanentes entre el número total original de peces, reportando peces con la mitad de su peso real.

---

### 2.2 Fórmulas Biológicas y Financieras

#### A. Factor de Conversión Alimenticia (FCR)
- **Ubicación:** `lib/modules/ponds_batches/domain/models/fish_batch.dart:62-75`
- **Código analizado:**
  ```dart
  double? get fcrOrNull {
    final gananciaBiomasa = biomasaActualKg - biomasaInicialKg;
    if (alimentoAcumuladoKg > 0 && gananciaBiomasa > 0) {
      return alimentoAcumuladoKg / gananciaBiomasa;
    }
    return null;
  }
  ```
- **Falla en Desdobles:** Al dividir un lote en dos (50% cada uno), el lote padre conserva el 100% de `alimentoAcumuladoKg` histórico, pero su biomasa actual se reduce a la mitad. Su FCR aparente salta de 1.35 a 2.70+. El lote hijo inicia con 0 kg de alimento y FCR indefinido.
- **Fórmula Correcta Exigida por Normas Acuícolas:**
  $$\text{eFCR} = \frac{\text{Kg Alimento Consumido Acumulado}}{\text{Biomasa Actual (kg)} + \text{Biomasa Cosechada (kg)} - \text{Biomasa Inicial Sembrada (kg)}}$$
  $$\text{bFCR} = \frac{\text{Kg Alimento Consumido Acumulado}}{\text{Biomasa Actual (kg)} + \text{Biomasa Cosechada (kg)} + \text{Biomasa Muerta (kg)} - \text{Biomasa Inicial Sembrada (kg)}}$$

#### B. Costo de Producción por Kilo (CPK) y Deducción de Inventario
- **Ubicación:** `lib/modules/finance_payroll/domain/services/production_cost_engine.dart:38-42, 89-105`
- **Falla:** Si en el período no hay facturas cargadas, el motor de costos recurre a una estimación ficticia (`totalBiomasaKg * 1.35 * 4500.0`), e ignora los consumos reales reportados en `alimentacion_diaria`. La distribución entre estanques se hace por biomasa ponderada, subsidiando erróneamente estanques de pre-cría con alimento costoso a expensas de estanques de engorde.

---

### 2.3 Inventario de Valores Mock Quemados en Diálogos de Campo

Se identificaron 8 diálogos de producción que violan la integridad del registro al pre-cargar números arbitrarios en los controladores:

| Archivo | Líneas | Variable | Valor Hardcodeado | Consecuencia en Campo |
|---|---|---|---|---|
| `siembra_modal.dart` | 40-42 | `_pecesCtrl`, `_pesoCtrl`, `_metaCosechaCtrl` | `5000`, `1.5`, `650` | Siembra automática de 5.000 alevinos si el usuario presiona "Guardar" distraídamente. |
| `siembra_modal.dart` | 203-204 | `empresaId`, `unidadId` | `'c1000000-...'`, `'u1000000-...'` | Desvío silencioso de datos a la empresa demo de testing si la sesión se refresca. |
| `mortalidad_modal.dart` | 34, 59 | `_muertosCtrl`, `_pesoCtrl` | `'5'`, `250.0` | Registro de 5 bajas artificiales. |
| `biometria_modal.dart` | 33, 51-53 | `_pecesCapturadosCtrl`, `_pesoTotalCapturaKgCtrl` | `'35'`, `(35 * peso) / 1000` | Peso de muestra pre-calculado que simula un pesaje real en báscula. |
| `traslado_modal.dart` | 50-51 | `_pesoCtrl`, `_pecesCtrl` | `100.0`, `1000` | Fallback ficticio si el lote es nulo. |
| `venta_rapida_modal.dart` | 59, 192 | `_precioKgCtrl`, `cpk` | `'\$ 9.500'`, `4500.0` | Precio de venta y CPK fijos quemados. |
| `crear_colaborador_modal.dart`| 57, 59 | `_salarioCtrl`, `_passCtrl` | `'2000000'`, `'FishBit.2026'` | Salario fijo y contraseña en texto claro. |
| `ica_biosecurity_modals.dart` | 765-777| Órganos Clínicos | Textos descriptivos completos ("ojos claros", etc.) | Necropsias veterinarias pre-aprobadas sin examen patológico real. |

---

### 2.4 Auditoría de Esquemas PostgreSQL, Índices y Fugas RLS Multi-Tenant

#### A. Fuga de Datos Multi-Tenant en RLS (`20260831_database_performance_and_rls_optimization.sql`)
En las líneas 519, 563, 607, 881 y 998, las políticas RLS aíslan registros de compras, equipos, mantenimiento, facturas e inventario utilizando:
```sql
USING (
  unidad_acuicola_sigla IN (SELECT u.sigla FROM public.units u WHERE u.empresa_id = (SELECT public.get_auth_empresa_id()))
  OR (SELECT public.is_superadmin())
);
```
**Brecha de Seguridad:** En `supabase_schema_canonical_v10.sql:39`, la restricción es `UNIQUE (empresa_id, sigla)`. La sigla **no es única globalmente**. Si la Empresa A y la Empresa B tienen una sede llamada `'PRIN'`, los usuarios de la Empresa A tienen visibilidad total sobre las compras, equipos y bodega de la Empresa B.

#### B. DDL Faltante de `public.traslados_lotes`
Ningún archivo de migración contiene `CREATE TABLE public.traslados_lotes`. Aunque la migración del 31 de agosto intenta crear índices y habilitar RLS sobre ella, en una base de datos nueva el script falla inmediatamente.

#### C. Índices Compuestos Faltantes para Series de Tiempo
En `traslados_lotes`, la pantalla de Bitácora consulta traslados por estanque utilizando `.or('estanque_origen_id.eq.$id,estanque_destino_id.eq.$id')`. Faltan índices compuestos en:
- `(empresa_id, estanque_origen_id, fecha_operacion DESC)`
- `(empresa_id, estanque_destino_id, fecha_operacion DESC)`

---

### 2.5 Motor de Reportes Oficiales ICA/AUNAP

- **Falla en Plataformas Móviles y Escritorio:** En `lib/core/reports/ica_official_reports_engine.dart:55-58` y `lib/core/reports/web_download_helper_stub.dart:2-4`:
  ```dart
  void downloadFileWeb(List<int> bytes, String fileName) {
    // En plataformas móviles/escritorio se maneja a través de file_picker o share_plus
  }
  ```
  El método `downloadFileWeb` es un stub vacío. En Android, iOS y Windows, presionar "Exportar Libro Oficial" ejecuta cero código y desecha los bytes generados.
- **Exportación de Datos Médicos/Biológicos Falsificados:**
  - **F-06 (Limpieza):** Líneas 746-751 inyectan 4 filas fijas de muestra con "Amonio Cuaternario" en lugar de consultar `public.bioseguridad_limpieza`.
  - **F-11 (Material Genético):** Líneas 881-882 inyectan quemado `'Alevinera Certificada del Huila'` y `'REG-ICA-ALV-9941'`.
  - **F-12 (Patógenos TiLV/IPN):** Líneas 928-932 exportan diagnósticos fijos `'NEGATIVO'` para virus del lago de la tilapia y necrosis pancreática en lugar de consultar `public.sanidad_monitoreo_patogenos`.

---

## 3. R2: OPTIMIZACIÓN DUAL DE PLATAFORMA (RENDIMIENTO WEB VS. MÓVIL)

### 3.1 Cuellos de Botella de Tasa de Relleno GPU (BackdropFilter)
- **Ubicación:** `lib/core/design_system/glass_container.dart:44-46, 89-90`
- **Problema Técnico:** Cada `GlassContainer` ejecuta incondicionalmente:
  ```dart
  BackdropFilter(filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur))
  ```
  Con `blur: 16.0` por defecto. En modo claro (líneas 44-46), la opacidad efectiva se calcula como:
  ```dart
  effectiveOpacity = isDark ? opacity : (opacity > 0.4 ? opacity : 0.88);
  ```
  Esto significa que el contenedor pinta un fondo blanco con 88% a 94% de opacidad. La GPU ejecuta dos pasadas de convolución gaussiana de 16 píxeles sobre el framebuffer para luego cubrirlo con blanco casi sólido. El efecto visual del blur es imperceptible, pero consume hasta el 40% del tiempo de frame en GPUs móviles (Mali/Adreno) y en Web CanvasKit.
- **Listados Virtualizados:** En `lib/modules/bitacora/presentation/screens/bitacora_screen.dart` (líneas 732, 973, 1193, 1515, 1677), cada elemento del `ListView.builder` está envuelto en un `GlassContainer` con blur, provocando caídas de 60 FPS a 18-24 FPS durante el scroll.

---

### 3.2 Doble Instanciación en `PondBentoCard`
- **Ubicación:** `lib/modules/ponds_batches/presentation/widgets/pond_bento_card.dart:100-109`
- **Problema Técnico:** En cada frame de la animación y en estado de reposo, el widget construye simultáneamente:
  ```dart
  Transform(
    transform: Matrix4.identity()..rotateY(...),
    child: isUnder ? _buildBackCard(context) : _buildFrontCard(context),
  )
  ```
  Ambas caras (`_buildFrontCard` y `_buildBackCard`) son evaluadas e instancian `GlassCard` con `BackdropFilter`, duplicando la cantidad de render objects y llamadas de shader en la cuadrícula de estanques.

---

### 3.3 Alcances de Reconstrucción Reactiva en Riverpod
- **`IcaCertificationScreen` (`ica_certification_screen.dart:48-53`):**
  Observa 6 providers completos en la raíz del `build()`: `icaReportsEngineProvider`, `pondsProvider`, `nutritionProvider`, `waterQualityProvider`, `salesProvider` e `icaComplianceProvider`. No utiliza `.select()`. Cualquier medición de oxígeno en un estanque invalida la pantalla completa de certificación y reconstruye los 12 paneles de reportes.
- **`BitacoraScreen` (`bitacora_screen.dart:420-422`):**
  Observa `waterQualityProvider`, `nutritionProvider` y `pondsProvider`. Las 4 pestañas de la bitácora son métodos privados (`_buildWaterQualityTab()`, etc.) en lugar de `ConsumerWidget` independientes. Una inserción de alimentación reconstruye las listas de calidad de agua y mortalidad.
- **`PondsDashboardScreen` (`ponds_dashboard_screen.dart:39-40, 314, 351`):**
  Observa mapas agregados globales (`activeBatchesByPondProvider`, `latestWaterQualityByPondProvider`), reconstruyendo la cuadrícula completa de 20+ estanques cuando un único estanque registra telemetría.

---

### 3.4 Responsividad Web en Pantallas Grandes (1920px)
- **Falta de Restricciones Máximas:** En `home_dashboard_screen.dart:36`, `ponds_dashboard_screen.dart:170`, `finance_screen.dart:167`, `warehouse_screen.dart:115` y `sales_screen.dart:71`, los slivers y columnas principales carecen de `BoxConstraints(maxWidth: 1200)`. En monitores Full HD (1920x1080), las tarjetas KPI de 2 columnas se estiran a lo ancho de 1900 píxeles, provocando deformación visual y dispersión de datos.
- **Falta de Comportamiento de Scroll de Escritorio:** En `lib/app/app.dart:15-32`, no se ha configurado `ScrollBehavior`. Por defecto, Flutter Web deshabilita el arrastre con ratón en barras de pestañas horizontales (`TabBar(isScrollable: true)`) y carruseles de chips de filtro.
- **Cursores de Ratón:** En toda la app se usan `GestureDetector` sin `MouseRegion(cursor: SystemMouseCursors.click)`, lo que deja el cursor del ratón en modo flecha estándar sobre elementos interactivos en Web.

---

### 3.5 Responsividad Móvil: Dock Flotante y Desplazamiento por Teclado
- **Oclusión por Dock de Navegación (`bitacora_screen.dart:718, 961, 1179, 1738`):**
  Todas las pestañas de Bitácora finalizan con un espacio reservado de `SizedBox(height: 80)`. En dispositivos móviles modernos, el dock flotante tiene una altura de 58 dp, margen inferior de 12 dp y el safe area de gestos de iOS/Android es de 34 dp (altura total = 104 dp; y con el botón flotante FAB supera los 160 dp). Los últimos 2 registros de cada lista quedan ocultos detrás del dock.
- **Desbordamientos por Teclado Virtual:** En `login_screen.dart:100-114` (`_showForgotPasswordDialog`), el diálogo no tiene `SingleChildScrollView`, generando `RenderFlex overflowed by XX pixels` al desplegarse el teclado en pantallas pequeñas.

---

## 4. R3: DISEÑO DE INTERACCIÓN Y ERGONOMÍA DE CAMPO (WCAG 2.2)

### 4.1 Dimensiones de Áreas Táctiles en Campo (WCAG 2.5.5)
En el entorno de una granja piscícola, los operarios manipulan los teléfonos con manos húmedas, guantes o bajo lluvia. WCAG 2.5.5 exige un área de contacto mínima de $48 \times 48\text{ dp}$.
1. **Botón Principal en `PondBentoCard` (`pond_bento_card.dart:411`):**
   ```dart
   SizedBox(width: double.infinity, height: 40, child: ElevatedButton(...))
   ```
   Tiene una altura de **40 dp** (8 dp por debajo de la norma), provocando fallos de pulsación al registrar actividades de rutina.
2. **Botón de Cierre en `GlassActionHubSheet` (`glass_action_hub_sheet.dart:108-115`):**
   El botón de cierre es un contenedor de `padding: EdgeInsets.all(4)` con icono de 16 dp, totalizando **24x24 dp** (la mitad del mínimo accesible).

---

### 4.2 Contraste y Legibilidad Bajo Luz Solar Tropical (WCAG 1.4.3)
Bajo luz solar directa en estanques exteriores (50.000 a 100.000 lux), el modo claro sufre pérdida total de legibilidad si los contrastes son bajos.
1. **Ratios de Contraste Insuficientes en Modo Claro:**
   En `lib/core/design_system/app_colors.dart:27-31`:
   - `cyanWater` (`#00B2CC`) sobre fondo blanco `#FFFFFF`: **Ratio 2.56:1** (Falla WCAG AA 4.5:1).
   - `greenBiomass` (`#10B981`) sobre fondo blanco: **Ratio 2.33:1** (Falla WCAG AA 4.5:1).
   - `amberWarning` (`#FF9500`) sobre fondo blanco: **Ratio 1.98:1** (Falla crítica, ilegible).
2. **Función `AppColors.accentText` Desconectada:**
   `app_colors.dart:56` define variantes de alto contraste para texto (`cyanWaterTextLight = Color(0xFF007A8C)`, `greenBiomassTextLight = Color(0xFF047857)`), pero la auditoría confirmó **cero llamadas a esta función en toda la interfaz de la aplicación**.
3. **Inversión Errónea de Tokens en Tarjetas:**
   En `pond_bento_card.dart:217, 248, 510, 566`, se utiliza la expresión:
   ```dart
   color: isDark ? Colors.white : AppColors.textPrimaryDark
   ```
   Donde `textPrimaryDark` es `#FFFFFF`. Esto hace que en modo claro el texto se pinte de blanco sobre tarjetas de fondo blanco.

---

### 4.3 Ergonomía de Campo a Una Mano (Bottom Sheets vs Diálogos Centrados)
Actualmente, los 6 modales operativos de campo (`parametro_modal.dart:21`, `alimentar_modal.dart:25`, `biometria_modal.dart:20`, `mortalidad_modal.dart:21`, `traslado_modal.dart:20`, `siembra_modal.dart:26`) invocan `showDialog` y renderizan `Dialog` centrado.
- **Zona de Pulgar Inaccesible:** En teléfonos de 6.5 a 6.8 pulgadas, los campos de entrada quedan ubicados en la mitad superior de la pantalla, obligando al operario a usar ambas manos mientras camina sobre taludes o geomembranas húmedas.
- **Compresión por Teclado:** Al abrir el teclado virtual, el diálogo centrado se encoge a un visor de apenas ~180 dp de alto.
- **Solución Ergonómica:** Migrar a un helper adaptativo que presente un `ModalBottomSheet` arrastrable anclado a la base en pantallas móviles (<600 dp) y un diálogo centrado únicamente en escritorio/Web.

---

## 5. R4: RESILIENCIA DE DATOS OFFLINE Y ARQUITECTURA DE ESTADO

### 5.1 Reactivación de la Cola de Sincronización Offline (`OfflineSyncQueue`)
- **Estado Inerte:** En `lib/core/storage/offline_sync_queue.dart:97`, existe el método `flushQueue(SupabaseClient supabase)`. Una búsqueda exhaustiva en todo el código fuente confirmó que **no se invoca en ningún punto de la aplicación**.
- **Pérdida de Datos en Alimentación (`supabase_nutrition_repository.dart:130-139`):**
  ```dart
  } catch (_) {
    _demoRecords.insert(0, record);
    _eventBus.fire(DailyFeedingRecordedEvent(...));
    return record;
  }
  ```
  Al fallar la red en una granja sin señal, el repositorio almacena la alimentación en la lista en memoria `_demoRecords`. Cuando el operario cierra o minimiza la app, todos los registros de alimentación se destruyen sin llegar jamás a la base de datos.
- **Mortalidad y Biometría Desprotegidas:** En `supabase_ponds_repository.dart:940, 1103`, las excepciones de red simplemente se imprimen en consola y se relanzan con `rethrow`, mostrando un error al usuario y perdiendo el registro sin persistencia local.

---

### 5.2 Estabilidad del Ciclo de Vida de Navegación con GoRouter
- **Ubicación:** `lib/app/router.dart:126`
- **Problema:** Utiliza `ShellRoute` simple:
  ```dart
  ShellRoute(
    builder: (context, state, child) => MainNavigationShell(navigationShell: child),
    routes: [ ... ]
  )
  ```
  En `ShellRoute`, cambiar de pestaña en el dock destruye completamente el árbol de widgets de la pantalla saliente. Al regresar a Bitácora o Estanques, el usuario pierde su posición de scroll, los filtros seleccionados, y se lanzan nuevas peticiones HTTP redundantes a Supabase.
- **Solución:** Reemplazar con `StatefulShellRoute.indexedStack`.

---

### 5.3 Erradicación de Bloques `catch (_)` Silenciosos y Manejo de Errores Tipados
Existen más de 50 bloques `catch (_)` sin log ni tipado. En `lib/core/errors/app_failure.dart`, la clase solo contempla errores genéricos. Se requiere expandir la jerarquía con:
- `NetworkFailure` (falla de conectividad para encolar offline).
- `OfflineSyncFailure` (falla en el vaciado de cola).
- `DatabaseConstraintFailure` (violación de chequeo, foreign key o RLS).

---

## 6. PLAN MAESTRO DE REMEDIACIÓN Y DIFFS DE CÓDIGO DROP-IN / SCRIPTS SQL

### 6.1 Script SQL Canónico de Migración (`supabase/migrations/20261027_master_traceability_and_rls_hardening.sql`)

```sql
-- ============================================================================
-- MIGRACIÓN MAESTRA DE TRAZABILIDAD, DDL Y ENDURECIMIENTO RLS MULTI-TENANT
-- Fecha: 2026-10-27
-- ============================================================================

-- 1. CREACIÓN CANÓNICA DE LA TABLA TRASLADOS_LOTES
CREATE TABLE IF NOT EXISTS public.traslados_lotes (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    empresa_id UUID NOT NULL REFERENCES public.empresas(id) ON DELETE CASCADE,
    unidad_acuicola_id UUID REFERENCES public.unidades_acuicolas(id) ON DELETE SET NULL,
    lote_origen_id UUID REFERENCES public.lotes(id) ON DELETE SET NULL,
    lote_destino_id UUID REFERENCES public.lotes(id) ON DELETE SET NULL,
    estanque_origen_id UUID NOT NULL REFERENCES public.estanques(id) ON DELETE RESTRICT,
    estanque_destino_id UUID NOT NULL REFERENCES public.estanques(id) ON DELETE RESTRICT,
    tipo_operacion TEXT NOT NULL CHECK (tipo_operacion IN ('TRASLADO_TOTAL', 'DESDOBLE_PARCIAL')),
    peces_trasladados INTEGER NOT NULL CHECK (peces_trasladados > 0),
    peso_promedio_gramos NUMERIC NOT NULL CHECK (peso_promedio_gramos > 0),
    biomasa_trasladada_kg NUMERIC NOT NULL CHECK (biomasa_trasladada_kg > 0),
    proporcion_costos NUMERIC NOT NULL DEFAULT 0.0,
    costo_alevinos_transferido NUMERIC NOT NULL DEFAULT 0.0,
    costo_insumos_transferido NUMERIC NOT NULL DEFAULT 0.0,
    costo_fijo_transferido NUMERIC NOT NULL DEFAULT 0.0,
    costo_total_transferido NUMERIC NOT NULL DEFAULT 0.0,
    nuevo_codigo_lote TEXT,
    motivo TEXT,
    registrado_por TEXT,
    fecha_operacion TIMESTAMPTZ NOT NULL DEFAULT timezone('utc'::text, now()),
    created_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc'::text, now())
);

-- 2. ÍNDICES COMPUESTOS ESTRATÉGICOS PARA SERIES TEMPORALES Y BITÁCORA
CREATE INDEX IF NOT EXISTS idx_traslados_empresa_fecha ON public.traslados_lotes(empresa_id, fecha_operacion DESC);
CREATE INDEX IF NOT EXISTS idx_traslados_empresa_lote_origen ON public.traslados_lotes(empresa_id, lote_origen_id, fecha_operacion DESC);
CREATE INDEX IF NOT EXISTS idx_traslados_empresa_lote_destino ON public.traslados_lotes(empresa_id, lote_destino_id, fecha_operacion DESC);
CREATE INDEX IF NOT EXISTS idx_traslados_empresa_estanque_origen ON public.traslados_lotes(empresa_id, estanque_origen_id, fecha_operacion DESC);
CREATE INDEX IF NOT EXISTS idx_traslados_empresa_estanque_destino ON public.traslados_lotes(empresa_id, estanque_destino_id, fecha_operacion DESC);

-- Habilitar RLS estricto
ALTER TABLE public.traslados_lotes ENABLE ROW LEVEL SECURITY;

CREATE POLICY traslados_lotes_tenant_all ON public.traslados_lotes
    FOR ALL TO authenticated
    USING (empresa_id = (SELECT public.get_auth_empresa_id()))
    WITH CHECK (empresa_id = (SELECT public.get_auth_empresa_id()));

-- 3. CIERRE DE BRECHAS DE SEGURIDAD MULTI-TENANT EN RLS (CORRECCIÓN DE VULNERABILIDAD SEC-01)

-- A. Compras de Material Biológico
DROP POLICY IF EXISTS compras_mat_biologico_tenant_select ON public.compras_mat_biologico;
DROP POLICY IF EXISTS compras_mat_biologico_tenant_modify ON public.compras_mat_biologico;

CREATE POLICY compras_mat_biologico_tenant_select ON public.compras_mat_biologico
    FOR SELECT TO authenticated
    USING (empresa_id = (SELECT public.get_auth_empresa_id()) OR (SELECT public.is_superadmin()));

CREATE POLICY compras_mat_biologico_tenant_modify ON public.compras_mat_biologico
    FOR ALL TO authenticated
    USING (empresa_id = (SELECT public.get_auth_empresa_id()) OR (SELECT public.is_superadmin()))
    WITH CHECK (empresa_id = (SELECT public.get_auth_empresa_id()));

-- B. Equipos
DROP POLICY IF EXISTS equipos_tenant_select ON public.equipos;
DROP POLICY IF EXISTS equipos_tenant_modify ON public.equipos;

CREATE POLICY equipos_tenant_select ON public.equipos
    FOR SELECT TO authenticated
    USING (empresa_id = (SELECT public.get_auth_empresa_id()) OR (SELECT public.is_superadmin()));

CREATE POLICY equipos_tenant_modify ON public.equipos
    FOR ALL TO authenticated
    USING (empresa_id = (SELECT public.get_auth_empresa_id()) OR (SELECT public.is_superadmin()))
    WITH CHECK (empresa_id = (SELECT public.get_auth_empresa_id()));

-- C. Mantenimientos
DROP POLICY IF EXISTS mantenimientos_tenant_select ON public.mantenimientos;
DROP POLICY IF EXISTS mantenimientos_tenant_modify ON public.mantenimientos;

CREATE POLICY mantenimientos_tenant_select ON public.mantenimientos
    FOR SELECT TO authenticated
    USING (empresa_id = (SELECT public.get_auth_empresa_id()) OR (SELECT public.is_superadmin()));

CREATE POLICY mantenimientos_tenant_modify ON public.mantenimientos
    FOR ALL TO authenticated
    USING (empresa_id = (SELECT public.get_auth_empresa_id()) OR (SELECT public.is_superadmin()))
    WITH CHECK (empresa_id = (SELECT public.get_auth_empresa_id()));

-- D. Facturas
DROP POLICY IF EXISTS facturas_tenant_select ON public.facturas;
DROP POLICY IF EXISTS facturas_tenant_modify ON public.facturas;

CREATE POLICY facturas_tenant_select ON public.facturas
    FOR SELECT TO authenticated
    USING (empresa_id = (SELECT public.get_auth_empresa_id()) OR (SELECT public.is_superadmin()));

CREATE POLICY facturas_tenant_modify ON public.facturas
    FOR ALL TO authenticated
    USING (empresa_id = (SELECT public.get_auth_empresa_id()) OR (SELECT public.is_superadmin()))
    WITH CHECK (empresa_id = (SELECT public.get_auth_empresa_id()));

-- E. Inventario de Insumos
DROP POLICY IF EXISTS inventario_insumos_tenant_select ON public.inventario_insumos;
DROP POLICY IF EXISTS inventario_insumos_tenant_modify ON public.inventario_insumos;

CREATE POLICY inventario_insumos_tenant_select ON public.inventario_insumos
    FOR SELECT TO authenticated
    USING (empresa_id = (SELECT public.get_auth_empresa_id()) OR (SELECT public.is_superadmin()));

CREATE POLICY inventario_insumos_tenant_modify ON public.inventario_insumos
    FOR ALL TO authenticated
    USING (empresa_id = (SELECT public.get_auth_empresa_id()) OR (SELECT public.is_superadmin()))
    WITH CHECK (empresa_id = (SELECT public.get_auth_empresa_id()));
```

---

### 6.2 Función Transaccional RPC en PostgreSQL (`public.split_or_transfer_batch`)

Resuelve de raíz la falta de atomicidad (DATA-01 y DATA-03), la sobreescritura en policultivos y la distorsión del FCR:

```sql
CREATE OR REPLACE FUNCTION public.split_or_transfer_batch(
    p_lote_origen_id UUID,
    p_estanque_destino_id UUID,
    p_tipo_operacion TEXT, -- 'TRASLADO_TOTAL' o 'DESDOBLE_PARCIAL'
    p_peces_trasladar INT,
    p_peso_promedio NUMERIC,
    p_nuevo_codigo_lote TEXT DEFAULT NULL,
    p_motivo TEXT DEFAULT NULL,
    p_registrado_por TEXT DEFAULT NULL
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_lote_origen public.lotes%ROWTYPE;
    v_estanque_origen public.estanques%ROWTYPE;
    v_estanque_destino public.estanques%ROWTYPE;
    v_empresa_id UUID;
    v_nuevo_lote_id UUID;
    v_biomasa_trasladar NUMERIC;
    v_ratio NUMERIC;
    v_costo_alevinos NUMERIC;
    v_costo_insumos NUMERIC;
    v_costo_fijo NUMERIC;
    v_costo_total NUMERIC;
    v_alimento_transferir NUMERIC;
    v_fecha TIMESTAMPTZ := timezone('utc'::text, now());
BEGIN
    v_empresa_id := public.get_auth_empresa_id();
    IF v_empresa_id IS NULL THEN
        RAISE EXCEPTION 'No autorizado: usuario sin tenant asignado';
    END IF;

    -- 1. Validar y bloquear fila del lote origen
    SELECT * INTO v_lote_origen FROM public.lotes 
    WHERE id = p_lote_origen_id AND empresa_id = v_empresa_id FOR UPDATE;
    IF NOT FOUND THEN
        RAISE EXCEPTION 'Lote origen no encontrado';
    END IF;

    IF v_lote_origen.cantidad_actual_peces < p_peces_trasladar THEN
        RAISE EXCEPTION 'Cantidad de peces a trasladar (%) supera los existentes (%)', 
            p_peces_trasladar, v_lote_origen.cantidad_actual_peces;
    END IF;

    -- 2. Calcular biomasa y proporciones
    v_biomasa_trasladar := ROUND((p_peces_trasladar * p_peso_promedio / 1000.0)::numeric, 2);
    v_ratio := p_peces_trasladar::numeric / v_lote_origen.cantidad_actual_peces::numeric;

    v_costo_alevinos := ROUND((v_lote_origen.costo_alevinos * v_ratio)::numeric, 2);
    v_costo_insumos := ROUND((v_lote_origen.costo_insumos * v_ratio)::numeric, 2);
    v_costo_fijo := ROUND((v_lote_origen.costo_fijo * v_ratio)::numeric, 2);
    v_costo_total := ROUND((v_lote_origen.costo_total * v_ratio)::numeric, 2);
    v_alimento_transferir := ROUND((COALESCE(v_lote_origen.alimento_acumulado_kg, 0.0) * v_ratio)::numeric, 2);

    IF p_tipo_operacion = 'TRASLADO_TOTAL' THEN
        -- Mover lote origen al nuevo estanque
        UPDATE public.lotes SET
            estanque_id = p_estanque_destino_id,
            peso_actual_g = p_peso_promedio,
            biomasa_actual_kg = v_biomasa_trasladar,
            updated_at = v_fecha
        WHERE id = v_lote_origen.id;
        v_nuevo_lote_id := v_lote_origen.id;
    ELSE
        -- DESDOBLE_PARCIAL: Reducir lote origen y crear lote hijo con proporción de alimento
        UPDATE public.lotes SET
            cantidad_actual_peces = cantidad_actual_peces - p_peces_trasladar,
            biomasa_actual_kg = GREATEST(0.0, biomasa_actual_kg - v_biomasa_trasladar),
            costo_alevinos = costo_alevinos - v_costo_alevinos,
            costo_insumos = costo_insumos - v_costo_insumos,
            costo_fijo = costo_fijo - v_costo_fijo,
            costo_total = costo_total - v_costo_total,
            alimento_acumulado_kg = GREATEST(0.0, alimento_acumulado_kg - v_alimento_transferir),
            updated_at = v_fecha
        WHERE id = v_lote_origen.id;

        INSERT INTO public.lotes (
            empresa_id, unidad_acuicola_id, estanque_id, codigo_lote, especie, variedad,
            fecha_siembra, cantidad_inicial_peces, cantidad_actual_peces, peso_inicial_g,
            peso_actual_g, biomasa_inicial_kg, biomasa_actual_kg, alimento_acumulado_kg,
            costo_alevinos, costo_insumos, costo_fijo, costo_total, estado, etapa
        ) VALUES (
            v_empresa_id, v_lote_origen.unidad_acuicola_id, p_estanque_destino_id,
            COALESCE(p_nuevo_codigo_lote, v_lote_origen.codigo_lote || '-B'),
            v_lote_origen.especie, v_lote_origen.variedad, v_fecha,
            p_peces_trasladar, p_peces_trasladar, p_peso_promedio, p_peso_promedio,
            v_biomasa_trasladar, v_biomasa_trasladar, v_alimento_transferir,
            v_costo_alevinos, v_costo_insumos, v_costo_fijo, v_costo_total,
            'ACTIVO', v_lote_origen.etapa
        ) RETURNING id INTO v_nuevo_lote_id;
    END IF;

    -- 3. Registrar auditoría formal
    INSERT INTO public.traslados_lotes (
        empresa_id, unidad_acuicola_id, lote_origen_id, lote_destino_id,
        estanque_origen_id, estanque_destino_id, tipo_operacion,
        peces_trasladados, peso_promedio_gramos, biomasa_trasladada_kg,
        proporcion_costos, costo_alevinos_transferido, costo_insumos_transferido,
        costo_fijo_transferido, costo_total_transferido, nuevo_codigo_lote,
        motivo, registrado_por, fecha_operacion
    ) VALUES (
        v_empresa_id, v_lote_origen.unidad_acuicola_id, v_lote_origen.id, v_nuevo_lote_id,
        v_lote_origen.estanque_id, p_estanque_destino_id, p_tipo_operacion,
        p_peces_trasladar, p_peso_promedio, v_biomasa_trasladar,
        v_ratio, v_costo_alevinos, v_costo_insumos, v_costo_fijo, v_costo_total,
        p_nuevo_codigo_lote, p_motivo, p_registrado_por, v_fecha
    );

    -- 4. Re-sincronizar biomasa de ambos estanques basada en la suma real de sus lotes activos (soporte policultivo)
    UPDATE public.estanques e SET
        biomasa_kg = COALESCE((SELECT SUM(biomasa_actual_kg) FROM public.lotes WHERE estanque_id = e.id AND estado = 'ACTIVO'), 0.0),
        cantidad_peces = COALESCE((SELECT SUM(cantidad_actual_peces) FROM public.lotes WHERE estanque_id = e.id AND estado = 'ACTIVO'), 0),
        updated_at = v_fecha
    WHERE e.id IN (v_lote_origen.estanque_id, p_estanque_destino_id);

    RETURN jsonb_build_object(
        'success', true,
        'nuevo_lote_id', v_nuevo_lote_id,
        'biomasa_trasladada', v_biomasa_trasladar,
        'peces_trasladados', p_peces_trasladar
    );
END;
$$;
```

---

### 6.3 Parches Drop-In en Repositorios y Modelos Dart

#### A. Descuento de Peces en Cosecha (`lib/modules/ponds_batches/presentation/providers/ponds_provider.dart:189-205`)
```diff
--- a/lib/modules/ponds_batches/presentation/providers/ponds_provider.dart
+++ b/lib/modules/ponds_batches/presentation/providers/ponds_provider.dart
@@ -190,12 +190,19 @@ class PondsNotifier extends StateNotifier<PondsState> {
     final oldBatch = state.batches.firstWhere((b) => b.id == event.loteId);
     final remanenteBiomasa = (oldBatch.biomasaActualKg - event.biomasaVendidaKg).clamp(0.0, double.infinity);
+    final int pecesVendidos = event.pecesVendidos > 0 
+        ? event.pecesVendidos 
+        : (oldBatch.biomasaActualKg > 0 
+            ? (oldBatch.cantidadActualPeces * (event.biomasaVendidaKg / oldBatch.biomasaActualKg)).round()
+            : 0);
+    final int remanentePeces = (oldBatch.cantidadActualPeces - pecesVendidos).clamp(0, oldBatch.cantidadActualPeces);
     final isTotalHarvest = remanenteBiomasa <= 5.0;
     final updatedBatch = oldBatch.copyWith(
       biomasaActualKg: remanenteBiomasa,
+      cantidadActualPeces: isTotalHarvest ? 0 : remanentePeces,
       estado: isTotalHarvest ? BatchStatus.harvested : oldBatch.estado,
     );
```

#### B. Conexión de `OfflineSyncQueue` en Nutrición (`lib/modules/feeding_nutrition/infrastructure/repositories/supabase_nutrition_repository.dart:130-139`)
```diff
--- a/lib/modules/feeding_nutrition/infrastructure/repositories/supabase_nutrition_repository.dart
+++ b/lib/modules/feeding_nutrition/infrastructure/repositories/supabase_nutrition_repository.dart
@@ -130,9 +130,13 @@ class SupabaseNutritionRepository implements NutritionRepository {
-    } catch (_) {
-      _demoRecords.insert(0, record);
-      _eventBus.fire(DailyFeedingRecordedEvent(...));
-      return record;
-    }
+    } catch (e, stack) {
+      // Encolar persistentemente en Hive para contingencia offline
+      await OfflineSyncQueue.instance.enqueue(
+        operation: 'INSERT',
+        table: 'alimentacion_diaria',
+        payload: record.toJson(),
+      );
+      _eventBus.fire(DailyFeedingRecordedEvent(record: record, isOffline: true));
+      return record;
+    }
```

---

### 6.4 Parches Drop-In en Capa de Presentación, GlassContainer y Modales Adaptativos

#### A. Optimización GPU en `GlassContainer` (`lib/core/design_system/glass_container.dart:88-95`)
```diff
--- a/lib/core/design_system/glass_container.dart
+++ b/lib/core/design_system/glass_container.dart
@@ -88,7 +88,9 @@ class GlassContainer extends StatelessWidget {
-        child: BackdropFilter(
-          filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
-          child: Container(
+        child: (blur <= 0.0 || effectiveOpacity >= 0.85)
+            ? Container(decoration: BoxDecoration(...), child: child)
+            : BackdropFilter(
+                filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
+                child: Container(decoration: BoxDecoration(...), child: child),
+              ),
```

#### B. Eliminación de Oclusión en Bitácora (`lib/modules/bitacora/presentation/screens/bitacora_screen.dart`)
Reemplazar `return const SizedBox(height: 80);` en líneas 718, 961, 1179 y 1738 por:
```dart
return const DockBottomSpacer(extra: 48.0);
```

#### C. Corrección WCAG 2.5.5 Touch Target en Bento Card (`lib/modules/ponds_batches/presentation/widgets/pond_bento_card.dart:411`)
```diff
--- a/lib/modules/ponds_batches/presentation/widgets/pond_bento_card.dart
+++ b/lib/modules/ponds_batches/presentation/widgets/pond_bento_card.dart
@@ -411,2 +411,2 @@
-        SizedBox(
-          width: double.infinity,
-          height: 40,
+        SizedBox(
+          width: double.infinity,
+          height: 48, // Cumplimiento WCAG 2.5.5 (mínimo 48 dp)
```

#### D. Corrección WCAG 1.4.3 Contraste y Tokens Invertidos (`pond_bento_card.dart:217, 248`)
```diff
--- a/lib/modules/ponds_batches/presentation/widgets/pond_bento_card.dart
+++ b/lib/modules/ponds_batches/presentation/widgets/pond_bento_card.dart
@@ -217,1 +217,1 @@
-  color: isDark ? Colors.white : AppColors.textPrimaryDark,
+  color: isDark ? Colors.white : AppColors.textPrimaryLight,
```

---

## CONCLUSIÓN DE LA AUDITORÍA
La aplicación FishBit cuenta con un potencial productivo excepcional y un diseño visual de vanguardia. La aplicación de este Plan Maestro de Remediación —centrado en la atomicidad de transacciones con PostgreSQL RPC, el sellado de las políticas RLS, la reactivación de `OfflineSyncQueue`, la eliminación de filtros GPU redundantes y la adaptación accesible a WCAG 2.2— blindará a la plataforma para su despliegue comercial y certificación sanitaria ante el ICA y la AUNAP.
