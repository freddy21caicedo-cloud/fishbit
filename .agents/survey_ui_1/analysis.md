# Auditoría y Análisis Técnico de UI/UX y Estado: Módulo Bitácora

**Módulo:** Bitácora Operacional (`lib/modules/bitacora/presentation/screens/bitacora_screen.dart`)  
**Proyecto:** FishBit Finance (Flutter + Riverpod + Supabase)  
**Fecha de Análisis:** 2026-08-28  
**Investigador:** UI/UX & State Explorer (`survey_ui_1`)

---

## 1. Visión General de la Pantalla Principal y sus 4 Pestañas

La pantalla `BitacoraScreen` (`bitacora_screen.dart`, 1025 líneas) es el centro neurálgico de captura y visualización de operaciones diarias de cultivo acuícola. Utiliza un `NestedScrollView` con `FishBitHeader`, selector de estanque interactivo en la cabecera, `TabBar` de 4 pestañas y un botón flotante (`FloatingActionButton.extended`) que abre el menú rápido de registro.

```
┌─────────────────────────────────────────────────────────────┐
│                       FishBitHeader                         │
├─────────────────────────────────────────────────────────────┤
│ 🔍 ESTANQUE DE CONSULTA: [ Todos los Estanques (2) ▼ ] [Limpiar] │
├─────────────────────────────────────────────────────────────┤
│ [💧 Calidad de Agua] [🍲 Alimentación] [⚖️ Biometrías] [⚠️ Bajas] │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│                      TabBarView (4 Tabs)                    │
│                                                             │
└─────────────────────────────────────────────────────────────┘
 [➕ Registrar en Bitácora] (FAB flotante)
```

### 1.1. Pestaña 1: Calidad de Agua (`_buildWaterQualityTab`)
- **Objetivo:** Mostrar los parámetros fisicoquímicos registrados en los estanques (oxígeno, pH, temperatura, amonio, nitritos, nitratos, alcalinidad, CO2, dureza, cloro).
- **Estado Actual:**
  - Muestra tarjetas de referencia ("Oxígeno Óptimo: 5.5 - 7.0 mg/L", "pH Rango: 6.8 - 7.8").
  - Renderiza lista de `waterState.recentParameters` filtrados por `_selectedPondId`.
  - Cada tarjeta presenta: Estanque, Sigla, Fecha/Hora, Badge de Estado (`Óptimo` vs `Atención`), fila rápida O2/Temp/pH, y filas de compuestos nitrogenados y balance químico mediante `Wrap`.
- **Hallazgo Crítico:**
  - El repositorio `SupabaseWaterQualityRepository.fetchRecentParametersByUnit()` consulta prioritariamente la tabla duplicada/legacy `water_quality` (que solo tiene 4 parámetros y está vacía en producción), y tiene filtros de empresa hardcodeados (`3500cc63-...` y `54dedaac-...`).
  - La tabla canónica `parametros_calidad_agua` contiene los 10 parámetros completos + hora, pero solo se lee como fallback si la primera consulta falla.

### 1.2. Pestaña 2: Alimentación (`_buildFeedingTab`)
- **Objetivo:** Mostrar el suministro diario de alimento concentrado, raciones y costeo asociado.
- **Estado Actual:**
  - Tarjetas superiores resumen: "ALIMENTO TOTAL (kg)" y "COSTO ALIMENTO (COP)".
  - Lista de `nutritionState.records` filtrados por `_selectedPondId`.
  - Cada item presenta: Estanque, Lote, Fecha, Consumo en kg y Costo calculado en COP.
- **Hallazgo Crítico:**
  - La persistencia en `alimentacion_diaria` contiene 84 registros reales en base de datos. Sin embargo, el título del estanque y lote en la fila `Row` (`line 781-789`) no tiene restricciones de flex, lo que provoca que en nombres de estanques largos el código de lote se corte severamente en pantallas estrechas.

### 1.3. Pestaña 3: Biometrías y GDP (`_buildBiometryTab`)
- **Objetivo:** Mostrar el historial cronológico de muestreos biométricos de los lotes y el cálculo de la Ganancia Diaria de Peso (GDP).
- **Estado Actual:**
  - **NO consulta ni muestra registros de la tabla `biometrias`.**
  - En su lugar, itera directamente sobre `pondsState.batches` (lotes activos) y calcula un promedio general estático:
    $$\text{GDP} = \frac{\text{pesoActualGramos} - \text{pesoInicialGramos}}{\text{diasDeCultivo}}$$
- **Hallazgo Crítico:**
  - La tabla `biometrias` en Supabase está completamente desconectada de la vista. Cuando el usuario registra un muestreo biométrico en `BiometriaModal`, los datos históricos no aparecen como eventos de muestreo cronológicos en la pestaña.

### 1.4. Pestaña 4: Bajas y Sanidad (`_buildMortalityTab`)
- **Objetivo:** Monitorear eventos sanitarios y bajas de peces por estanque/lote con causas de mortalidad y tasa acumulada.
- **Estado Actual:**
  - **NO consulta ni muestra registros de la tabla `mortalidad`.**
  - Muestra únicamente una lista de lotes activos de `pondsState.batches` con un cálculo estático de bajas: `b.cantidadInicialPeces - b.cantidadActualPeces` y supervivencia `(totalPecesActual / totalPecesInicial) * 100`.
- **Hallazgo Crítico:**
  - La tabla `mortalidad` está vacía y desconectada de la UI. No se muestran eventos individuales de mortalidad (fecha, causas como Hipoxia, Bacteriosis, Hongos, ni biomasa perdida).

---

## 2. Inspección de Modales de Registro Rápido (FAB)

| Modal | Archivo | Entidad / Tabla Destino | Parámetros Capturados | Estado de Integración |
|---|---|---|---|---|
| **`ParametroModal`** | `lib/modules/water_quality/presentation/dialogs/parametro_modal.dart` | `parametros_calidad_agua` & `water_quality` | Estanque, Fecha, Hora, O2 (mg/L), O2 (%), Temp (°C), pH, Amonio (ppm), Nitritos (ppm), Nitratos (ppm), Alcalinidad (ppm), CO2 (ppm), Dureza (ppm), Cloro (ppm), Notas. | Completo en UI (11 campos + alertas tiempo real). Doble escritura en repo. |
| **`AlimentarModal`** | `lib/modules/ponds_batches/presentation/dialogs/alimentar_modal.dart` | `alimentacion_diaria` & `inventory` | Estanque, Lote, Insumo Bodega, Kg a suministrar, Raciones/día, Fecha. | Completo. Valida stock en bodega, calcula ración sugerida por especie/peso y descuenta inventario. |
| **`BiometriaModal`** | `lib/modules/ponds_batches/presentation/dialogs/biometria_modal.dart` | `biometrias`, `lotes`, `estanques` | Estanque, Lote, Peces capturados, Peso captura (kg), Talla (cm), Fecha, Notas. | Completo en UI (calcula Peso prom, Biomasa estimada, GDP, Factor K Fulton, Pellet sugerido). **Falta poblar en el estado local de lectura.** |
| **`MortalidadModal`** | `lib/modules/ponds_batches/presentation/dialogs/mortalidad_modal.dart` | `mortalidad`, `lotes`, `estanques` | Estanque, Lote, Peces muertos, Peso prom (g), Causa probable (Chips), Fecha, Notas. | Completo en UI (calcula Biomasa perdida, alerta crítica >2%, nueva población). **Falta poblar en el estado local de lectura.** |

---

## 3. Arquitectura de Estado Riverpod y Flujo de Datos

```
                               ┌─────────────────────────┐
                               │       authProvider      │
                               └────────────┬────────────┘
                                            │ (empresaId, unitId)
                    ┌───────────────────────┼───────────────────────┐
                    ▼                       ▼                       ▼
       ┌────────────────────────┐┌─────────────────────┐┌────────────────────────┐
       │  waterQualityProvider  ││  nutritionProvider  ││     pondsProvider      │
       ├────────────────────────┤├─────────────────────┤├────────────────────────┤
       │ - isLoading            ││ - isLoading         ││ - isLoading            │
       │ - recentParameters[]   ││ - records[]         ││ - ponds[]              │
       │ - errorMessage         ││ - tables[]          ││ - batches[]            │
       │                        ││ - errorMessage      ││ - (FALTA biometries[]) │
       │                        ││                     ││ - (FALTA mortality[])  │
       └────────────────────────┘└─────────────────────┘└────────────────────────┘
                    │                       │                       │
                    ▼                       ▼                       ▼
              [ Tab 1: Agua ]      [ Tab 2: Alimento ]     [ Tab 3 & 4: Batches ]
                                                           *(Desconectados de DB)*
```

### Problemas Detectados en los Proveedores:
1. **Falta de colecciones en `PondsState`:**
   - `PondsState` (`lib/modules/ponds_batches/presentation/providers/ponds_provider.dart`, líneas 14-44) solo define `ponds` y `batches`.
   - No tiene `List<BiometriaRecord> biometries` ni `List<MortalityRecord> mortalityRecords`.
2. **Métodos de consulta inexistentes en `PondsRepository`:**
   - `PondsRepository` (`lib/modules/ponds_batches/domain/repositories/ponds_repository.dart`) no tiene contratos para `fetchBiometriesByUnit(empresaId, unitId)` ni `fetchMortalityRecordsByUnit(empresaId, unitId)`.
3. **Persistencia incompleta en `SupabasePondsRepository`:**
   - `registerBiometry()` (líneas 461-470) inserta `{id, estanque_id, batch_id, avg_weight_gr, total_biomass_kg, date, created_at}` pero no guarda `empresa_id`, `unidad_acuicola_id`, `peces_capturados`, `peso_total_captura_kg`, `longitud_cm`, `k_fulton`, `gdp_g_dia`.
   - `registerMortality()` (líneas 409-417) inserta `{id, estanque_id, batch_id, quantity, cause, date, created_at}` pero omite `empresa_id`, `unidad_acuicola_id`, `peso_promedio_gramos`, `biomasa_perdida_kg`.

---

## 4. Análisis de "Biometrías y GDP" (Cálculo Correcto vs Actual)

### 4.1. Deficiencia Actual
En `bitacora_screen.dart` (líneas 858-860):
```dart
final dias = b.diasDeCultivo > 0 ? b.diasDeCultivo : 1;
final gdp = (b.pesoActualGramos - b.pesoInicialGramos) / dias;
```
Este cálculo evalúa la tasa de crecimiento promedio desde el día 0 de siembra de todo el lote, en lugar de calcular la **Ganancia Diaria de Peso del periodo entre muestreos consecutivos**.

### 4.2. Algoritmo Correcto de GDP para Muestreos Biométricos
En acuicultura de precisión:
- Para un lote dado con un historial ordenado cronológicamente de $n$ muestreos:
  $$\text{Muestreo}_0 = (\text{Fecha}_{\text{siembra}}, W_0 = \text{peso\_inicial})$$
  $$\text{Muestreo}_1 = (t_1, W_1), \quad \text{Muestreo}_2 = (t_2, W_2), \quad \dots, \quad \text{Muestreo}_k = (t_k, W_k)$$

- **Ganancia Diaria de Peso del Periodo ($GDP_k$):**
  $$\text{GDP}_k = \frac{W_k - W_{k-1}}{t_k - t_{k-1} \text{ (días)}} \quad (\text{g/día})$$

- **Factor de Condición de Fulton ($K$):**
  $$K = 100 \times \frac{W_k}{(L_k)^3} \quad (\text{si se registra longitud } L \text{ en cm})$$

### 4.3. Propuesta de Visualización en Tab 3:
1. **Resumen Superior:**
   - Último Peso Promedio Registrado (g)
   - GDP Promedio del Ciclo (g/día)
   - Biomasa Viva Estimada (kg)
2. **Historial de Tarjetas de Muestreos:**
   - Cabecera: Estanque, Lote, Especie, Fecha y Hora del muestreo.
   - Datos del muestreo: Peces capturados en red ($N$), Peso total de captura ($Kg$), Peso promedio calculado ($W$).
   - Métricas de crecimiento: $\Delta W$ ($W_k - W_{k-1}$), Días transcurridos ($\Delta t$), **GDP del Periodo ($g/\text{día}$)**, Factor $K$.
   - Observaciones de campo y técnico responsable.

---

## 5. Análisis de "Bajas y Sanidad" (Mortalidad Real vs Actual)

### 5.1. Deficiencia Actual
En `bitacora_screen.dart` (líneas 927-933):
```dart
final totalPecesActual = batches.fold<int>(0, (sum, b) => sum + b.cantidadActualPeces);
final totalPecesInicial = batches.fold<int>(0, (sum, b) => sum + b.cantidadInicialPeces);
final supervivenciaReal = totalPecesInicial > 0 ? (totalPecesActual / totalPecesInicial) * 100.0 : 96.5;
```
No se consulta la tabla `mortalidad`. El usuario solo ve los lotes activos sin trazabilidad de cuándo ocurrieron las bajas ni por qué causas.

### 5.2. Propuesta de Visualización en Tab 4:
1. **Resumen Superior:**
   - Bajas Totales Registradas en el periodo / estanque seleccionado.
   - Tasa de Supervivencia Real Acumulada ($\%$).
   - Biomasa Total Perdida ($Kg$).
2. **Historial de Registros Sanitarios (desde `mortalidad` / `MortalityRecord`):**
   - Cabecera: Estanque, Lote ($L$), Especie, Fecha del evento.
   - Causa diagnosticada con Badge coloreado:
     - 🔴 `Hipoxia / Bajo O2` (Alerta Crítica)
     - 🟠 `Bacteriosis / Columnaris` (Alerta Patológica)
     - 🟡 `Trauma / Manejo` (Alerta Operativa)
     - ⚪ `Depredación / Aves` o `Desconocida`
   - Cantidad de bajas ($Q$), Peso promedio ($g$), Biomasa perdida ($Kg$).
   - Porcentaje de mortalidad del evento sobre la población del lote:
     $$\% \text{ Evento} = \frac{Q}{\text{Población Previa}} \times 100\%$$
   - Indicador de gravedad: Normal ($<2\%$) vs Alerta Sanitaria ($\ge 2\%$).

---

## 6. Análisis del Filtro por Estanque (Bottom Sheet) y Reactividad

### 6.1. Diagnóstico del Filtro Actual
- En `bitacora_screen.dart`:
  ```dart
  final waterPondIds = waterState.recentParameters.map((p) => p.estanqueId).toSet();
  final feedingPondIds = nutritionState.records.map((r) => r.estanqueId).toSet();
  final batchPondIds = pondsState.batches.map((b) => b.estanqueId).toSet();
  final allPondIdsWithData = {...waterPondIds, ...feedingPondIds, ...batchPondIds};

  final pondsWithData = pondsState.ponds.where((p) => allPondIdsWithData.contains(p.id)).toList();
  ```

### 6.2. Inconsistencias Detectadas:
1. **Exclusión de estanques válidos:**
   Si un estanque no tiene mediciones de agua ni raciones ni lote asignado aún (o si solo tiene registros en `biometrias` / `mortalidad`), queda excluido de `pondsWithData`. El usuario no puede seleccionar un estanque recién creado para revisar su bitácora vacía o registrar datos.
2. **Falta de reactividad con biometría y mortalidad:**
   Al no incluir los IDs de estanques presentes en `biometrias` y `mortalidad`, el conteo de datos en el badge (`${countWater + countFeeding + countBatches} datos`) es incompleto.
3. **Sincronización simultánea en las 4 Tabs:**
   Cada pestaña filtra su respectivo listado con:
   ```dart
   if (_selectedPondId != null && item.estanqueId != _selectedPondId) return false;
   ```
   Esto funciona correctamente cuando `_selectedPondId` cambia con `setState()`. Sin embargo, al recargar o al sincronizar con `pondsProvider`, si `_selectedPondId` está guardado en el estado local del widget en lugar de un `StateProvider` de Riverpod, el filtro se pierde al reconstruir la pantalla desde navegación externa.

---

## 7. Análisis de Responsividad y Riesgos de `RenderFlex Overflow`

### 7.1. Vista Móvil Estándar (360px de ancho)

#### 🔴 Riesgo Crítico 1: Overflow en el Botón Selector de Estanque (Líneas 426-476)
- **Ubicación:** `bitacora_screen.dart`, header filter container.
- **Estructura problemático:**
  ```dart
  Row(
    mainAxisAlignment: MainAxisAlignment.spaceBetween,
    children: [
      Row( // <--- SIN Expanded/Flexible
        children: [
          Container(padding: const EdgeInsets.all(8), child: const Icon(...)),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('ESTANQUE DE CONSULTA', ...),
              Text('E-01 • Estanque 01 (Geomembrana)', ...), // <--- Sin ellipsis/Flexible
            ],
          ),
        ],
      ),
      Row(
        children: [
          if (_selectedPondId != null) Container(child: const Text('Limpiar')),
          const Icon(Icons.keyboard_arrow_down_rounded),
        ],
      ),
    ],
  )
  ```
- **Cálculo de Render en 360px:**
  - Ancho de pantalla: 360px.
  - Padding exterior: $16 \times 2 = 32\text{px}$.
  - Padding GlassContainer: $16 \times 2 = 32\text{px}$.
  - Ancho interior disponible: $296\text{px}$.
  - Botón "Limpiar" + Ícono flecha: $\sim 95\text{px}$.
  - Espacio remanente para la izquierda: $201\text{px}$.
  - Ícono estanque + margen: $46\text{px}$.
  - Ancho disponible para el texto: $155\text{px}$.
  - El texto `'E-01 • Estanque 01 (Geomembrana)'` mide $\sim 230\text{px}$.
  - **Resultado:** **RenderFlex OVERFLOW de $\sim 75\text{px}$ a la derecha** cuando un estanque con nombre largo está seleccionado y se muestra el botón "Limpiar".

#### 🟡 Riesgo 2: Fila de Título en Tarjetas de Alimentación, Biometría y Bajas
- **Ubicación:** Líneas 781-789, 888-896, 998-1005 de `bitacora_screen.dart`.
- **Estructura:**
  ```dart
  Row(
    children: [
      Text(pondTitulo, style: ...), // <--- Sin Flexible/Expanded
      const SizedBox(width: 6),
      Expanded(
        child: Text('• $loteStr ($fechaStr)', overflow: TextOverflow.ellipsis, ...),
      ),
    ],
  )
  ```
- Si `pondTitulo` es "Estanque 01 (Geomembrana)", ocupa casi todo el ancho disponible, reduciendo el `Expanded` a $<20\text{px}$, truncando el código de lote por completo.
- **Solución:** Usar `Flexible(flex: 2, child: Text(pondTitulo, overflow: TextOverflow.ellipsis))` y `Flexible(flex: 3, child: Text(...))`.

#### 🟡 Riesgo 3: Formulario en 3 Columnas en `ParametroModal`
- **Ubicación:** `parametro_modal.dart`, líneas 251-280.
- **Estructura:** `Row` con 3 `Expanded(child: GlassFormField(...))` (Oxígeno, Saturación, Temperatura).
- En pantallas de 360px, cada columna tiene solo $\approx 89\text{px}$ de ancho. `GlassFormField` tiene un padding horizontal interno de 16px en `GlassContainer` más el ícono de prefijo (20px). Esto deja apenas $\sim 25\text{px}$ para el campo de texto, provocando que valores como "100.0" se corten visualmente.
- **Solución:** Reorganizar a 2 filas (Fila 1: Oxígeno y Saturación en 2 columnas; Fila 2: Temperatura y pH) o compactar el padding interno del `GlassFormField`.

### 7.2. Vista Web / Desktop (>768px)
- En pantallas anchas (>768px o 1200px), los `ListView` de `bitacora_screen.dart` se expanden al ancho total de la ventana (1920px), haciendo que las tarjetas y badges se estiren desproporcionadamente.
- **Solución:** Envolver el contenido del cuerpo o las listas en:
  ```dart
  Center(
    child: ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 1024),
      child: ...
    ),
  )
  ```
  Esto garantiza una experiencia visual consistente y limpia tanto en dispositivos móviles como en pantallas de escritorio/tablets.

---

## 8. Resumen de Mejoras y Hoja de Ruta para Implementación

1. **Persistencia y Modelado de Datos:**
   - Crear entidad `BiometriaRecord` en `lib/modules/ponds_batches/domain/models/biometria_record.dart`.
   - Utilizar el modelo existente `MortalityRecord` (`mortality_record.dart`).
   - Agregar `fetchBiometriesByUnit()` y `fetchMortalityByUnit()` a `PondsRepository` y `SupabasePondsRepository`.
   - Actualizar `PondsState` para incluir `biometries` y `mortalityRecords`.
   - Eliminar consultas a tablas obsoletas (`water_quality`) y asegurar filtros directos por `empresa_id`.

2. **Cálculo de GDP:**
   - Implementar función matemática de GDP incremental entre muestreos ordenados cronológicamente por lote:
     $$\text{GDP} = \frac{W_t - W_{t-1}}{\Delta \text{días}}$$

3. **Correcciones de UI y Reactividad:**
   - Corregir el `Row` del header filter envolviendo en `Expanded` y aplicando `TextOverflow.ellipsis`.
   - Mostrar todos los estanques en el Bottom Sheet de filtrado (no solo `pondsWithData`), indicando estado activo/disponible.
   - Reemplazar el renderizado de lotes en Tab 3 y Tab 4 por listas cronológicas de `BiometriaRecord` y `MortalityRecord` reales.
   - Envolver vistas en `ConstrainedBox(maxWidth: 1024)` para soporte web/desktop óptimo.
