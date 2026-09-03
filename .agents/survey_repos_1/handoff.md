# Handoff Report: Bitácora Repositories & Data Layer Survey

**Agent ID:** `survey_repos_1` (Explorer)  
**Parent Agent:** `8d9d3925-2638-4c57-8043-da837c0e440b`  
**Date:** 2026-08-28  
**Artifact:** `.agents/survey_repos_1/analysis.md`

---

## 1. Observation

### 1.1 Water Quality Data Flow
- In `lib/modules/water_quality/infrastructure/repositories/supabase_water_quality_repository.dart`:
  - Lines 135–153: `recordParameters()` inserts into `parametros_calidad_agua` with keys `id`, `estanque_id`, `fecha`, `oxigeno_mg_l`, `oxigeno_pct`, `ph`, `temperatura`, `amonio_mg_l`, `nitritos_mg_l`, `nitratos_mg_l`, `alcalinidad_mg_l`, `co2_mg_l`, `dureza_mg_l`, `cloro_mg_l`, `observaciones`, `registrado_por`, `creado_en`. **`empresa_id` and `unidad_acuicola_id` are omitted**.
  - Lines 158–175: Double-write attempt to `water_quality`.
  - Lines 90–94: `fetchRecentParametersByUnit()` executes `_supabase.from('water_quality').select('*').order('date', ascending: false).limit(50)` without SQL filtering on `empresa_id` or `unit_id`.
  - Lines 100–105: Hardcoded in-memory filtering:
    ```dart
    if (empresaId == '3500cc63-5477-4f83-b4a3-7758b7cd6509' || unidadAcuicolaId == '3500cc63-5477-4f83-b4a3-7758b7cd6509' || unidadAcuicolaId == 'PISC') ...
    if (empresaId == '54dedaac-9099-475a-8bfc-635ef8494c2a' || unidadAcuicolaId == '54dedaac-9099-475a-8bfc-635ef8494c2a' || unidadAcuicolaId == 'AQUA' || unidadAcuicolaId == 'AQU') ...
    ```
  - Lines 112–118: Fallback queries `parametros_calidad_agua` without SQL tenant filtering, falling back to `_demoParameters`.

### 1.2 Supabase Database State
- Project ID: `oakovawlwjpnoydpwtam`.
- Table `parametros_calidad_agua` columns: `id`, `estanque_id`, `fecha`, `oxigeno_mg_l`, `oxigeno_pct`, `ph`, `amonio_mg_l`, `nitritos_mg_l`, `nitratos_mg_l`, `fosforo_mg_l`, `alcalinidad_mg_l`, `dureza_mg_l`, `cloro_mg_l`, `co2_mg_l`, `temperatura`, `observaciones`, `registrado_por`, `unidad_acuicola_sigla`, `creado_en`. **`empresa_id` and `unidad_acuicola_id` are absent**.
- `pg_policies` check: **0 policies** on `parametros_calidad_agua` and `water_quality`, while RLS is enabled (`rls_enabled: true`).
- `pg_indexes` check: Missing index `(empresa_id, fecha DESC)` on `parametros_calidad_agua` and `alimentacion_diaria`.

### 1.3 Hardcoded UUID Occurrences Across Repositories
Hardcoded UUIDs `3500cc63-5477-4f83-b4a3-7758b7cd6509` and `54dedaac-9099-475a-8bfc-635ef8494c2a` are present in:
1. `lib/modules/water_quality/infrastructure/repositories/supabase_water_quality_repository.dart` (lines 100–105)
2. `lib/modules/ponds_batches/infrastructure/repositories/supabase_ponds_repository.dart` (lines 112–117, 189–194)
3. `lib/modules/feeding_nutrition/infrastructure/repositories/supabase_nutrition_repository.dart` (lines 45–50)
4. `lib/modules/sales_harvest/infrastructure/repositories/supabase_sales_repository.dart` (lines 63–68)
5. `lib/modules/warehouse_inventory/infrastructure/repositories/supabase_warehouse_repository.dart` (lines 64–69)

### 1.4 Biometrics and Mortality State
- `BiometriaModal` (`lib/modules/ponds_batches/presentation/dialogs/biometria_modal.dart`) calls `pondsProvider.notifier.recordBiometry(...)`.
- `SupabasePondsRepository.registerBiometry` inserts only `id`, `estanque_id`, `batch_id`, `avg_weight_gr`, `total_biomass_kg`, `date`, `created_at` to `biometrias`.
- `MortalidadModal` (`lib/modules/ponds_batches/presentation/dialogs/mortalidad_modal.dart`) calls `pondsProvider.notifier.recordMortality(...)`.
- `SupabasePondsRepository.registerMortality` inserts only `id`, `estanque_id`, `batch_id`, `quantity`, `cause`, `date`, `created_at` to `mortalidad`.
- No read methods exist for biometries or mortalities in any repository or provider.
- `BitacoraScreen` (`lib/modules/bitacora/presentation/screens/bitacora_screen.dart` lines 809–1023) renders `pondsState.batches` for both the "Biometrías y GDP" and "Bajas y Sanidad" tabs, never reading from `biometrias` or `mortalidad` tables.
- No `Biometria` Dart domain model exists. `MortalityRecord` exists but its fields (`pesoPromedioGramos`, `biomasaPerdidaKg`, `observaciones`, `registradoPor`) are not in the DB `mortalidad` table.

### 1.5 Daily Feeding Insert Failure
- In `SupabaseNutritionRepository.recordFeeding()` (`lib/modules/feeding_nutrition/infrastructure/repositories/supabase_nutrition_repository.dart` lines 99–109), `insertData` contains `'unidad_acuicola_id'` and `'insumo_id'`, neither of which exists in `alimentacion_diaria`.

---

## 2. Logic Chain

1. **Why water quality data is not persisting / appearing:**
   - Table `parametros_calidad_agua` has RLS enabled with 0 policies, blocking all client queries.
   - `recordParameters()` does not insert `empresa_id`, so even with RLS policies checking `empresa_id = get_auth_empresa_id()`, rows would be rejected or invisible.
   - `fetchRecentParametersByUnit()` queries `water_quality` first, which is empty, and then falls back to `parametros_calidad_agua` (which fails/returns 0), and then falls back to mock demo data.
2. **Why multi-tenancy is broken:**
   - Data is queried globally (`select('*')`) and filtered in client memory by hardcoded UUID strings. If an unhandled tenant logs in, queries return either all rows or fallback to demo data.
3. **Why Biometrics & Mortality tabs don't show real logs:**
   - There are no read methods or state collections for `Biometria` or `MortalityRecord`.
   - `BitacoraScreen` binds tabs 3 and 4 directly to `pondsState.batches`, displaying only current batch calculations instead of event log rows.
4. **Why Daily Feeding inserts fail:**
   - Attempting to insert keys `'unidad_acuicola_id'` and `'insumo_id'` triggers PostgreSQL error 42703 (undefined column), forcing the execution into the catch block.

---

## 3. Caveats

- Investigation was performed in read-only mode; no source code or database schema modifications were executed.
- Analysis verified both the active PostgreSQL database via Supabase MCP tool (`execute_sql`, `list_tables`) and the local Dart codebase.
- Other modules (`equipment_capex`, `finance_payroll`, `sales_harvest`, `warehouse_inventory`) also share the hardcoded UUID / demo fallback pattern.

---

## 4. Conclusion

The Bitácora module requires a 3-part coordinated remediation:

1. **Database Migration (Supabase):**
   - Alter `parametros_calidad_agua` to add `empresa_id` (FK to `empresas`), `unidad_acuicola_id` (FK to `unidades_acuicolas`), index `(empresa_id, fecha DESC)`, and RLS policies for `SELECT` and `ALL`.
   - Alter `alimentacion_diaria` to add `unidad_acuicola_id`, `insumo_id`, index `(empresa_id, fecha DESC)`, and RLS policies.
   - Alter `biometrias` and `mortalidad` to add missing columns (`lote_id`, `peces_capturados`, `peso_total_captura_kg`, `longitud_cm`, `peso_promedio_gramos`, `biomasa_perdida_kg`, `observaciones`, `registrado_por`), indexes on `(empresa_id, fecha DESC)`, and RLS policies.
   - Deprecate/migrate legacy tables (`water_quality`, `calidad_agua`, `mortality`).

2. **Repository & Model Layer Refactoring (Flutter / Dart):**
   - Make `parametros_calidad_agua` the single canonical table for `WaterQualityRepository`.
   - Replace in-memory UUID filtering with native Supabase `.eq('empresa_id', empresaId)` across all repositories.
   - Create `Biometria` domain model and add `fetchBiometries` and `fetchMortality` methods to the data layer.
   - Align `FeedingRecord` and `MortalityRecord` JSON mappings with Supabase columns.

3. **Presentation Layer Refactoring (`BitacoraScreen`):**
   - Wire tab 3 ("Biometrías y GDP") to consume historical biometry records.
   - Wire tab 4 ("Bajas y Sanidad") to consume real mortality records from `mortalidad`.
   - Ensure the pond filter applies reactively across all 4 tabs simultaneously.

---

## 5. Verification Method

To independently verify these findings:
1. **Inspect table columns and RLS policies:**
   - Execute query: `SELECT * FROM pg_policies WHERE tablename IN ('parametros_calidad_agua', 'water_quality', 'biometrias', 'mortalidad', 'alimentacion_diaria');`
   - Execute query: `SELECT column_name, data_type FROM information_schema.columns WHERE table_name = 'parametros_calidad_agua';`
2. **Inspect repository code:**
   - View `lib/modules/water_quality/infrastructure/repositories/supabase_water_quality_repository.dart` lines 100–107 and 135–175.
   - View `lib/modules/ponds_batches/infrastructure/repositories/supabase_ponds_repository.dart` lines 112–117, 409–417, and 462–470.
   - View `lib/modules/bitacora/presentation/screens/bitacora_screen.dart` lines 809–1023.
