# Handoff Report — UI/UX & State Survey: Módulo Bitácora

**Agent:** `survey_ui_1` (UI/UX & State Explorer)  
**Parent Agent:** `parent` (`8d9d3925-2638-4c57-8043-da837c0e440b`)  
**Target Module:** Bitácora (`lib/modules/bitacora/`, `lib/modules/water_quality/`, `lib/modules/feeding_nutrition/`, `lib/modules/ponds_batches/`)  
**Date:** 2026-08-28

---

## 1. Observation

Direct observations from source code inspection:

1. **`BitacoraScreen` Tab 3 (Biometrías y Curvas)** (`lib/modules/bitacora/presentation/screens/bitacora_screen.dart`, lines 809–920):
   ```dart
   final batches = _selectedPondId != null
       ? pondsState.batches.where((b) => b.estanqueId == _selectedPondId).toList()
       : pondsState.batches;
   ...
   final dias = b.diasDeCultivo > 0 ? b.diasDeCultivo : 1;
   final gdp = (b.pesoActualGramos - b.pesoInicialGramos) / dias;
   ```
   *Finding:* Tab 3 only reads `pondsState.batches` (active batches) and calculates GDP from batch initial weight to current weight divided by batch age in days. It does **not** read from `biometrias` table, does not store or display individual biometric sampling events, and does not compute period GDP between consecutive samplings $(W_2 - W_1)/(t_2 - t_1)$.

2. **`BitacoraScreen` Tab 4 (Mortalidad y Sanidad)** (`lib/modules/bitacora/presentation/screens/bitacora_screen.dart`, lines 922–1023):
   ```dart
   final batches = _selectedPondId != null
       ? pondsState.batches.where((b) => b.estanqueId == _selectedPondId).toList()
       : pondsState.batches;
   final totalPecesActual = batches.fold<int>(0, (sum, b) => sum + b.cantidadActualPeces);
   final totalPecesInicial = batches.fold<int>(0, (sum, b) => sum + b.cantidadInicialPeces);
   final supervivenciaReal = totalPecesInicial > 0 ? (totalPecesActual / totalPecesInicial) * 100.0 : 96.5;
   ...
   Text('${b.cantidadActualPeces} peces vivos • Bajas: ${b.cantidadInicialPeces - b.cantidadActualPeces}')
   ```
   *Finding:* Tab 4 only displays active batches with difference between initial and current count. It does **not** query or display records from the Supabase `mortalidad` table, omitting dates, causes (Hipoxia, Bacteriosis, etc.), casualty counts, and event biomass loss.

3. **`PondsState` & `PondsNotifier`** (`lib/modules/ponds_batches/presentation/providers/ponds_provider.dart`, lines 14–44, 130–181):
   - `PondsState` has fields `isLoading`, `ponds`, `batches`, `errorMessage`. It lacks `biometries` (`List<BiometriaRecord>`) and `mortalityRecords` (`List<MortalityRecord>`).
   - `recordBiometry()` and `recordMortality()` update batch numbers in memory and execute Supabase inserts, but there are no `fetchBiometries` or `fetchMortality` methods to load past records into state on init or refresh.

4. **`SupabasePondsRepository`** (`lib/modules/ponds_batches/infrastructure/repositories/supabase_ponds_repository.dart`, lines 407–432, 459–484):
   - `registerMortality` inserts into `mortalidad` with `id`, `estanque_id`, `batch_id`, `quantity`, `cause`, `date`, `created_at` — omitting `empresa_id`, `unidad_acuicola_id`, `peso_promedio_gramos`, `biomasa_perdida_kg`.
   - `registerBiometry` inserts into `biometrias` with `id`, `estanque_id`, `batch_id`, `avg_weight_gr`, `total_biomass_kg`, `date`, `created_at` — omitting `empresa_id`, `unidad_acuicola_id`, `peces_capturados`, `longitud_cm`, `gdp_g_dia`.
   - The repository has hardcoded company IDs in `fetchPondsByUnit` and `fetchBatchesByUnit` (lines 112–117, 189–194) (`3500cc63-...`, `54dedaac-...`).

5. **`SupabaseWaterQualityRepository`** (`lib/modules/water_quality/infrastructure/repositories/supabase_water_quality_repository.dart`, lines 88–122):
   - Queries `water_quality` first (limit 50) with hardcoded tenant UUID checks. `water_quality` has only 4 parameters and is empty. `parametros_calidad_agua` (which has 10 parameters) is only used as a fallback.

6. **Pond Filter Bottom Sheet & Header Row** (`lib/modules/bitacora/presentation/screens/bitacora_screen.dart`, lines 426–476):
   - In `_BitacoraScreenState`, the filter container row has:
     ```dart
     Row(
       mainAxisAlignment: MainAxisAlignment.spaceBetween,
       children: [
         Row( // Unconstrained!
           children: [
             Container(...),
             const SizedBox(width: 12),
             Column(
               crossAxisAlignment: CrossAxisAlignment.start,
               children: [
                 Text('ESTANQUE DE CONSULTA', ...),
                 Text(_selectedPondId == null ? ... : ...), // Unconstrained width!
               ],
             ),
           ],
         ),
         Row(children: [if (_selectedPondId != null) Container(child: const Text('Limpiar')), Icon(...)]),
       ],
     )
     ```
   - On a 360px screen, when a pond with a full name is selected and the "Limpiar" button appears, total width required exceeds 360px, creating a **RenderFlex overflow of ~75px**.
   - Furthermore, `pondsWithData` in lines 384–390 restricts the bottom sheet options to ponds having water, feeding, or batch records. Clean or newly added ponds without prior records cannot be filtered or selected.

7. **Responsive Form Field in Modals** (`lib/modules/water_quality/presentation/dialogs/parametro_modal.dart`, lines 251–280):
   - 3 `Expanded` columns (O2, Saturation %, Temp °C) on a 360px viewport allocate only ~89px per column. With 32px container padding + 20px prefix icon, text fields for 3-digit values are visually compressed.

---

## 2. Logic Chain

1. **Observations 1 & 3 $\rightarrow$ Disconnected Biometry Sampling History & Inaccurate GDP:**
   Because `PondsState` lacks a `biometries` list and `PondsRepository` has no `fetchBiometriesByUnit()` method, `BitacoraScreen` Tab 3 fell back to rendering `pondsState.batches`. Consequently, users cannot view past biometric samplings, and GDP is calculated as a single batch-lifetime metric instead of period growth $(W_k - W_{k-1}) / \Delta t$.

2. **Observations 2 & 3 $\rightarrow$ Disconnected Mortality Tracking:**
   Because `PondsState` lacks a `mortalityRecords` collection and repository fetch methods, Tab 4 only computes the static difference in batch counts ($N_{\text{inicial}} - N_{\text{actual}}$). No mortality events, causes of death, or chronological health events are displayed.

3. **Observations 4 & 5 $\rightarrow$ Schema Inconsistencies & Query Fallbacks:**
   Divergence between legacy tables (`water_quality`, `mortality` vs `mortalidad`) and canonical tables (`parametros_calidad_agua`, `biometrias`) combined with hardcoded UUID filters causes query failures, data omissions, and double writes.

4. **Observation 6 $\rightarrow$ RenderFlex Overflow on Mobile & Incomplete Pond Filtering:**
   The unconstrained inner `Row` in the filter header card causes a 75px horizontal overflow on 360px screens when a pond name and "Limpiar" button render simultaneously. In addition, computing `pondsWithData` strictly from existing water/feed/batch sets hides active/available ponds that have no records yet.

---

## 3. Caveats

- **Existing Database Contents:** The Supabase database contains 84 rows in `alimentacion_diaria` and 0 rows in `parametros_calidad_agua`, `biometrias`, and `mortalidad`. Once the UI and repositories are properly connected, sample data or seed records should be verified to confirm table rendering.
- **Polyculture Batches:** When multiple species coexist in a single pond (polyculture), both `BiometriaModal` and `MortalidadModal` support selecting the specific batch/species (`activeBatches > 1`). The display lists in Tab 3 and Tab 4 must also display the batch code and species alongside the pond title.
- **Read-Only Scope:** This investigation was conducted in read-only mode without modifying application source files.

---

## 4. Conclusion

The Bitácora UI and state architecture have complete, well-designed modal forms (`ParametroModal`, `AlimentarModal`, `BiometriaModal`, `MortalidadModal`), but suffer from four specific state and UI gaps:
1. **Tabs 3 and 4** are disconnected from their canonical Supabase tables (`biometrias` and `mortalidad`) because `PondsState` lacks collections and `PondsRepository` lacks fetch queries for them.
2. **GDP Calculation** in Tab 3 must be updated from batch-lifetime average to period daily weight gain between consecutive sampling dates: $(W_k - W_{k-1}) / (t_k - t_{k-1})$.
3. **Pond Filter Bottom Sheet & Header Card** has a RenderFlex overflow on 360px mobile viewports (fixable by adding `Expanded` and `TextOverflow.ellipsis`) and overly restricts the filter options to ponds with prior data.
4. **Desktop / Web Layout (>768px)** benefits from centering the list views with `ConstrainedBox(maxWidth: 1024)` to avoid over-stretching cards on wide viewports.

---

## 5. Verification Method

To verify these findings independently:

1. **Inspect Source Files:**
   - `lib/modules/bitacora/presentation/screens/bitacora_screen.dart` (lines 426–476 for filter Row overflow; lines 809–920 for Tab 3; lines 922–1023 for Tab 4).
   - `lib/modules/ponds_batches/presentation/providers/ponds_provider.dart` (lines 14–44 for `PondsState` fields; lines 130–181 for missing biometry/mortality collections).
   - `lib/modules/water_quality/infrastructure/repositories/supabase_water_quality_repository.dart` (lines 88–122 for query priority).
   - `lib/modules/ponds_batches/domain/models/mortality_record.dart` (existing domain model for mortality).

2. **Verify Static Code Analysis:**
   - Run `flutter analyze` across the project to ensure no syntax errors exist.

3. **Verify Layout Constraints:**
   - Set viewport to 360px width in Flutter Device Preview or Chrome Inspector, navigate to Bitácora, and select an active pond. Observe the header filter card overflow before fix.
