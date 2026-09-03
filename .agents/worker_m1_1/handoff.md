# Handoff Report — Milestone 1 (M1): Database Migration & Schema Alignment

**Agent**: `worker_m1_1` (Database Migration Worker)  
**Milestone**: M1 — Database Schema, Migrations, Indexes & RLS  
**Project ID**: `oakovawlwjpnoydpwtam`  
**Date**: 2026-08-29  

---

## 1. Observation

1. **Pre-Migration State**:
   - `parametros_calidad_agua`: 0 rows. Columns `empresa_id`, `unit_id`, `unidad_acuicola_id`, `hora` were missing. `rowsecurity = true` with 0 RLS policies (resulting in PostgreSQL `DENY ALL` for authenticated users). Missing trigger `trg_parametros_calidad_agua_tenant`.
   - `water_quality`: 11 historical telemetry rows recorded between 2026-04-30 and 2026-05-29 for unit `3500cc63-5477-4f83-b4a3-7758b7cd6509`.
   - `alimentacion_diaria`: 84 active rows, missing index on `(empresa_id, fecha DESC)`.
   - `biometrias`: 38 active rows, missing columns `peces_capturados`, `peso_total_captura_kg`, `peso_promedio_g`, `biomasa_parcial_kg`, `longitud_cm`, `lote_id`, `hora`.
   - `mortalidad`: 7 active rows, all 7 had `empresa_id = NULL` (inaccessible under tenant RLS). Missing columns `cantidad`, `causa`, `peso_promedio_gramos`, `biomasa_perdida_kg`, `lote_id`, `hora`.
   - `calidad_agua`: 0 rows, obsolete 3-parameter schema.

2. **Executed Migration Actions**:
   - Migration file written to: `supabase/migrations/20260829_milestone1_bitacora_schema_alignment.sql`
   - Applied via Supabase `apply_migration` MCP tool: returned `{"success": true}`.
   - Idempotency test executed via `execute_sql` (running the full migration script a second time): returned `[]` with 0 errors.

3. **Post-Migration Verified State**:
   - `parametros_calidad_agua`:
     - 11 total rows (migrated from `water_quality`).
     - 11/11 have `empresa_id = '3500cc63-5477-4f83-b4a3-7758b7cd6509'` and `unit_id = '3500cc63-5477-4f83-b4a3-7758b7cd6509'`.
     - Columns present: `id`, `estanque_id`, `fecha`, `hora`, `oxigeno_mg_l`, `oxigeno_pct`, `ph`, `temperatura`, `amonio_mg_l`, `nitritos_mg_l`, `nitratos_mg_l`, `fosforo_mg_l`, `alcalinidad_mg_l`, `dureza_mg_l`, `cloro_mg_l`, `co2_mg_l`, `observaciones`, `registrado_por`, `unidad_acuicola_sigla`, `creado_en`, `empresa_id`, `unit_id`, `unidad_acuicola_id`.
     - Policies active: `parametros_calidad_agua_tenant_select` (SELECT), `parametros_calidad_agua_tenant_modify` (ALL).
     - Triggers active: `trg_parametros_calidad_agua_tenant` (`fn_auto_inherit_tenant_context()`), `trg_calidad_inherit_sede` (`fn_estanque_hijo_inherit_sede()`).
     - Indexes: `idx_calidad_agua_empresa_fecha`, `idx_calidad_agua_empresa_id`, `idx_calidad_agua_unit_id`, `idx_calidad_agua_estanque_fecha`.
   - `alimentacion_diaria`:
     - 84 rows with valid `empresa_id` and `unit_id`.
     - Indexes: `idx_alimentacion_empresa_fecha`, `idx_alimentacion_empresa_id`, `idx_alimentacion_fecha`, `idx_alimentacion_estanque_fecha`, `idx_alimentacion_estanque_lote`, `idx_alimentacion_unit_id`.
     - Policies active: `alimentacion_diaria_tenant_select`, `alimentacion_diaria_tenant_modify`.
     - Columns: `unidad_acuicola_id`, `insumo_id`, `empresa_id`, `unit_id`.
   - `biometrias`:
     - 38 rows.
     - Synchronized columns: `peso_promedio_g` / `avg_weight_gr`, `biomasa_parcial_kg` / `total_biomass_kg`, `fecha` / `date`, `peces_capturados`, `peso_total_captura_kg`, `longitud_cm`, `lote_id`, `hora`.
     - Policies active: `biometrias_tenant_select`, `biometrias_tenant_modify`.
     - Triggers active: `trg_biometrias_tenant` (`fn_auto_inherit_tenant_context()`).
     - Indexes: `idx_biometrias_empresa_date`, `idx_biometrias_empresa_fecha`, `idx_biometrias_empresa_lote`, `idx_biometrias_empresa_id`, `idx_biometrias_estanque_id`, `idx_biometrias_unit_id`.
   - `mortalidad`:
     - 7 rows, 7/7 with backfilled `empresa_id = '3500cc63-5477-4f83-b4a3-7758b7cd6509'`.
     - Synchronized columns: `cantidad` / `quantity`, `causa` / `cause`, `peso_promedio_gramos`, `biomasa_perdida_kg`, `lote_id`, `fecha`, `hora`.
     - Policies active: `mortalidad_tenant_select`, `mortalidad_tenant_modify`.
     - Triggers active: `trg_mortalidad_tenant` (`fn_auto_inherit_tenant_context()`).
     - Indexes: `idx_mortalidad_empresa_date`, `idx_mortalidad_empresa_fecha`, `idx_mortalidad_empresa_id`, `idx_mortalidad_estanque_id`, `idx_mortalidad_unit_id`, `idx_mortalidad_lote_id`.
   - Legacy Tables:
     - `calidad_agua`, `water_quality`, `mortality` safely documented as DEPRECATED via PostgreSQL table comments.

---

## 2. Logic Chain

1. **Why `parametros_calidad_agua` was previously empty**:
   - Lacked `empresa_id` and had zero RLS policies while RLS was enabled, blocking all authenticated client inserts.
   - Adding `empresa_id`, `unit_id`, `trg_parametros_calidad_agua_tenant`, and RLS policies (`parametros_calidad_agua_tenant_select`, `parametros_calidad_agua_tenant_modify`) unlocks the table for standard multi-tenant operations.
2. **Why telemetry data migration required estanque resolution**:
   - `water_quality` rows contained legacy estanque ID `'4c2cc39f-0ca6-4884-8563-98ffd0324a5a'` which referenced Estanque 8 in unit `3500cc63-5477-4f83-b4a3-7758b7cd6509`.
   - In `estanques`, Estanque 8 has active ID `'05d3702f-6f75-4517-91b9-3a71f7e2d0be'`.
   - The migration query dynamically resolved and mapped the estanque FK, preventing FK violation errors and ensuring all 11 rows now link to active valid ponds and company/unit context.
3. **Why backfilling `empresa_id` in `mortalidad` was critical**:
   - Authenticated tenant users query using `empresa_id = get_auth_empresa_id()`.
   - Without `empresa_id`, existing rows were filtered out, appearing empty to the app. Backfilling `empresa_id` restores visibility of historical loss logs.
4. **Idempotency Guarantee**:
   - All DDL statements use `IF NOT EXISTS` or `DROP ... IF EXISTS` followed by `CREATE`.
   - Data inserts use `WHERE NOT EXISTS (SELECT 1 FROM ... WHERE id = ...)`.
   - Data updates use `COALESCE` with null-check filters.
   - Re-running the migration confirms zero duplicate inserts and zero errors.

---

## 3. Caveats

- In `water_quality`, parameters `co2`, `dureza`, `cloro`, and `fosforo` were not tracked in earlier legacy software; in `parametros_calidad_agua`, those 4 fields are `NULL` for the 11 legacy entries, which is correct and expected for historical records.
- No caveats regarding idempotency or schema constraints.

---

## 4. Conclusion

Milestone 1 (M1) is 100% complete and verified:
- `parametros_calidad_agua` is now the fully functional, canonical water quality table with all 10+ physicochemical parameters, `empresa_id`, `unit_id`, triggers, indexes, and RLS policies.
- 11 historical telemetry rows from `water_quality` are successfully migrated into `parametros_calidad_agua`.
- `alimentacion_diaria`, `biometrias`, and `mortalidad` have complete schema columns, performance indexes on `(empresa_id, fecha/date DESC)`, auto-inherit triggers, and RLS policies.
- `empresa_id` was backfilled on all existing mortality rows.
- Legacy tables (`calidad_agua`, `water_quality`, `mortality`) are safely deprecated.
- Migration file is saved in `supabase/migrations/20260829_milestone1_bitacora_schema_alignment.sql` for version control.
- Idempotency verified by executing the entire script twice with 0 errors.

---

## 5. Verification Method

To independently verify the database state on project `oakovawlwjpnoydpwtam`:

1. **Verify Row Counts & Non-Null Empresa ID**:
   ```sql
   SELECT 'parametros_calidad_agua' AS tbl, count(*) AS total, count(empresa_id) AS with_empresa FROM public.parametros_calidad_agua
   UNION ALL
   SELECT 'alimentacion_diaria' AS tbl, count(*), count(empresa_id) FROM public.alimentacion_diaria
   UNION ALL
   SELECT 'biometrias' AS tbl, count(*), count(empresa_id) FROM public.biometrias
   UNION ALL
   SELECT 'mortalidad' AS tbl, count(*), count(empresa_id) FROM public.mortalidad;
   ```
   *Expected*: `parametros_calidad_agua` = 11 (11 with empresa), `alimentacion_diaria` = 84 (84 with empresa), `biometrias` = 38 (38 with empresa), `mortalidad` = 7 (7 with empresa).

2. **Verify RLS Policies**:
   ```sql
   SELECT tablename, policyname, cmd 
   FROM pg_policies 
   WHERE schemaname = 'public' AND tablename IN ('parametros_calidad_agua', 'alimentacion_diaria', 'biometrias', 'mortalidad');
   ```
   *Expected*: Each table has `*_tenant_select` (SELECT) and `*_tenant_modify` (ALL).

3. **Verify Indexes**:
   ```sql
   SELECT tablename, indexname 
   FROM pg_indexes 
   WHERE schemaname = 'public' AND tablename IN ('parametros_calidad_agua', 'alimentacion_diaria', 'biometrias', 'mortalidad')
   ORDER BY tablename, indexname;
   ```
   *Expected*: `idx_*_empresa_fecha` / `idx_*_empresa_date` on all 4 tables.

4. **Verify Trigger Auto-Inheritance**:
   ```sql
   SELECT event_object_table, trigger_name, action_statement
   FROM information_schema.triggers
   WHERE trigger_schema = 'public' AND event_object_table IN ('parametros_calidad_agua', 'alimentacion_diaria', 'biometrias', 'mortalidad')
   ORDER BY event_object_table, trigger_name;
   ```
   *Expected*: `trg_*_tenant` executing `fn_auto_inherit_tenant_context()` on all 4 tables.

5. **Verify Idempotency**:
   Re-execute `supabase/migrations/20260829_milestone1_bitacora_schema_alignment.sql` against the database; it must complete with 0 errors and unchanged row counts.
