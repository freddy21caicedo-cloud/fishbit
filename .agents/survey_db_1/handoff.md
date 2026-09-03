# Handoff Report — Bitácora Database Schema Audit

**Agent Folder**: `.agents/survey_db_1/`  
**Milestone**: Bitácora Database & Schema Audit  
**Author**: Specification Miner & Database Explorer  
**Date**: 2026-08-29  

---

## 1. Observation

1. **Table Schema and Missing Columns on `parametros_calidad_agua`**:
   - Live query on `information_schema.columns` for `parametros_calidad_agua` returned 19 columns: `id`, `estanque_id`, `fecha`, `oxigeno_mg_l`, `oxigeno_pct`, `ph`, `amonio_mg_l`, `nitritos_mg_l`, `nitratos_mg_l`, `fosforo_mg_l`, `alcalinidad_mg_l`, `dureza_mg_l`, `cloro_mg_l`, `co2_mg_l`, `temperatura`, `observaciones`, `registrado_por`, `unidad_acuicola_sigla`, `creado_en`.
   - Columns `empresa_id` (UUID) and `unit_id` (UUID) **do not exist** on `parametros_calidad_agua`.
   - The temperature column in PostgreSQL is named `temperatura`, while in Dart `WaterParameter` model both `temperatura` and `temperatura_c` are handled.

2. **Row-Level Security (RLS) Denial on `parametros_calidad_agua`**:
   - Live query on `pg_tables` shows `rowsecurity = true` for `parametros_calidad_agua`.
   - Live query on `pg_policies` shows **0 rows** for `tablename = 'parametros_calidad_agua'`.
   - PostgreSQL documentation & behavior: When RLS is enabled and no policies exist, any command by non-superuser (`authenticated` or `anon`) returns empty or fails with error `42501`.

3. **Telemetry Row Counts & Data Distribution**:
   - `SELECT count(*) FROM public.parametros_calidad_agua` -> `0 rows`.
   - `SELECT count(*) FROM public.water_quality` -> `11 rows` (dates `2026-04-30` to `2026-05-29`, all referencing estanque `4c2cc39f-0ca6-4884-8563-98ffd0324a5a` and unit `3500cc63-5477-4f83-b4a3-7758b7cd6509`).
   - `SELECT count(*) FROM public.calidad_agua` -> `0 rows`.

4. **Feeding (`alimentacion_diaria`) and Batches (`lotes`)**:
   - `SELECT count(*) FROM public.alimentacion_diaria` -> `84 rows`.
   - `SELECT count(*) FROM public.lotes` -> `15 rows`.
   - Integrity check query: `SELECT count(*) FROM alimentacion_diaria ad JOIN lotes l ON l.id = ad.lote_id` confirmed that all 84 rows in `alimentacion_diaria` reference valid `lotes` and `estanques`.
   - `pg_indexes` for `alimentacion_diaria` has only `alimentacion_diaria_pkey` and `idx_alimentacion_estanque_lote`. It is **missing an index on `(empresa_id, fecha)`**.

5. **Biometry (`biometrias`) & Mortality (`mortalidad`) State**:
   - `SELECT count(*) FROM public.biometrias` -> `38 rows` with columns `avg_weight_gr`, `total_biomass_kg`, `batch_id`, `species_name`, `empresa_id`, `estanque_id`.
   - `SELECT count(*) FROM public.mortalidad` -> `7 rows`. In all 7 rows, `empresa_id` is `NULL`.
   - In `lib/modules/bitacora/presentation/screens/bitacora_screen.dart`:
     - Lines 809-920: `_buildBiometryTab` iterates over `pondsState.batches` (local state) instead of querying the `biometrias` table.
     - Lines 922-1024: `_buildMortalityTab` calculates difference between initial and current population from `pondsState.batches` instead of querying the `mortalidad` table.
   - In `lib/modules/ponds_batches/infrastructure/repositories/supabase_ponds_repository.dart`:
     - Lines 408-418: `registerMortality` inserts into `mortalidad` without setting `empresa_id`.
     - Lines 461-471: `registerBiometry` inserts into `biometrias` without setting `empresa_id`.

6. **Hardcoded Tenant Filtering in Repositories**:
   - In `lib/modules/water_quality/infrastructure/repositories/supabase_water_quality_repository.dart` (lines 100-106):
     ```dart
     if (empresaId == '3500cc63-5477-4f83-b4a3-7758b7cd6509' ...)
     ```
   - In `lib/modules/feeding_nutrition/infrastructure/repositories/supabase_nutrition_repository.dart` (lines 45-51):
     ```dart
     if (empresaId == '3500cc63-5477-4f83-b4a3-7758b7cd6509' ...)
     ```

---

## 2. Logic Chain

1. **Why `parametros_calidad_agua` had 0 rows despite being the intended canonical table**:
   - Because `parametros_calidad_agua` lacks `empresa_id` and has RLS enabled with 0 policies, any insertion attempt by the app client fails at the Postgres level.
   - In `SupabaseWaterQualityRepository.recordParameters` (lines 134-155), the insert into `parametros_calidad_agua` is wrapped in an unhandled `try { ... } catch (_) {}`, which suppressed the error and attempted a second insert into `water_quality`.
   - `fetchRecentParametersByUnit` reads `water_quality` first, masking the failure.

2. **Why telemetry data exists only in `water_quality`**:
   - The 11 historical telemetry rows were inserted into `water_quality` because `water_quality` had `unit_id`, `estanque_id`, and `date` columns matching earlier schema versions.
   - To make `parametros_calidad_agua` canonical without data loss, these 11 rows must be migrated with proper timestamp formatting.

3. **Why `lotes` is NOT empty (contrary to initial hypothesis)**:
   - Initial metadata tools showed cached table stats of 0 rows, but direct `SELECT count(*)` confirmed 15 active lotes. All 84 feeding records in `alimentacion_diaria` match these 15 lotes, so there is no foreign key constraint violation on existing data.

4. **Why mortality records were not showing for non-admin sessions**:
   - In `mortalidad`, `empresa_id` is `NULL`. The RLS policy `mortalidad_tenant_select` requires `empresa_id = get_auth_empresa_id()`. Therefore, normal authenticated users get 0 rows back.
   - Adding `trg_mortalidad_tenant` or populating `empresa_id` on insert is required.

---

## 3. Caveats

- In `water_quality`, columns `co2`, `dureza`, `cloro`, and `fosforo` were not tracked historically; when migrating the 11 rows to `parametros_calidad_agua`, those fields will be `NULL` for those 11 legacy entries.
- `unidades_acuicolas` (4 rows) and `units` (3 rows) both exist in the database with overlapping IDs (`3500cc63-5477-4f83-b4a3-7758b7cd6509`, `969805c9-666a-4d96-a3fe-46d76c0439e5`, `31f842b3-21f2-4ab2-ad45-cce1144ab23e`). Foreign keys on `biometrias`, `mortalidad`, `water_quality`, and `alimentacion_diaria` link to `units(id)`.

---

## 4. Conclusion

1. **Database Schema Fixes Needed**:
   - Alter `parametros_calidad_agua`: add `empresa_id UUID REFERENCES empresas(id) ON DELETE CASCADE` and `unit_id UUID REFERENCES units(id) ON DELETE SET NULL`.
   - Add trigger `trg_parametros_calidad_agua_tenant` executing `fn_auto_inherit_tenant_context()`.
   - Create RLS policies on `parametros_calidad_agua`: `parametros_calidad_agua_tenant_select` and `parametros_calidad_agua_tenant_modify`.
   - Backfill `empresa_id` in `parametros_calidad_agua` and `mortalidad`.
   - Migrate 11 rows from `water_quality` to `parametros_calidad_agua`.
   - Create indexes:
     - `idx_calidad_agua_empresa_fecha` on `parametros_calidad_agua(empresa_id, fecha DESC)`.
     - `idx_alimentacion_empresa_fecha` on `alimentacion_diaria(empresa_id, fecha DESC)`.
     - `idx_biometrias_empresa_date` on `biometrias(empresa_id, date DESC)`.
     - `idx_mortalidad_empresa_date` on `mortalidad(empresa_id, date DESC)`.
2. **Flutter Codebase Fixes Needed**:
   - Replace in-memory hardcoded UUID filtering in `SupabaseWaterQualityRepository` and `SupabaseNutritionRepository` with direct `.eq('empresa_id', empresaId)` Supabase queries.
   - Point `SupabaseWaterQualityRepository` exclusively to `parametros_calidad_agua` as canonical.
   - Update `registerBiometry` and `registerMortality` to pass `empresa_id` and `unit_id`.
   - Connect Bitácora Screen tabs "Biometrías y GDP" and "Bajas y Sanidad" to real data providers querying `biometrias` and `mortalidad`.

---

## 5. Verification Method

To verify these findings independently:

1. **Verify `parametros_calidad_agua` schema & missing columns**:
   ```sql
   SELECT column_name, data_type, is_nullable 
   FROM information_schema.columns 
   WHERE table_name = 'parametros_calidad_agua';
   ```
2. **Verify missing RLS policies on `parametros_calidad_agua`**:
   ```sql
   SELECT tablename, policyname, cmd 
   FROM pg_policies 
   WHERE tablename = 'parametros_calidad_agua';
   ```
3. **Verify `water_quality` data to be migrated**:
   ```sql
   SELECT id, estanque_id, date, hour, o2_mg_l, ph, temperature_c 
   FROM public.water_quality;
   ```
4. **Verify `mortalidad` null `empresa_id` values**:
   ```sql
   SELECT id, estanque_id, quantity, cause, empresa_id 
   FROM public.mortalidad;
   ```
5. **Verify existing indexes on Bitácora tables**:
   ```sql
   SELECT tablename, indexname, indexdef 
   FROM pg_indexes 
   WHERE tablename IN ('parametros_calidad_agua', 'alimentacion_diaria', 'biometrias', 'mortalidad');
   ```
