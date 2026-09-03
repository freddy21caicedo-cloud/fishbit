# Reviewer 2 Report — Milestone 1 (M1): RLS Security, Triggers & Database Integrity

**Reviewer**: `reviewer_db_2` (Reviewer & Adversarial Critic)  
**Milestone**: M1 — Database Schema, Migrations, Indexes & RLS  
**Project ID**: `oakovawlwjpnoydpwtam`  
**Verdict**: **APPROVE**  
**Date**: 2026-08-29  

---

## 1. Observation

Direct observations and SQL verification queries executed against live Supabase project `oakovawlwjpnoydpwtam`:

### 1.1 Row Counts & Tenant Context Population
```sql
SELECT 'parametros_calidad_agua' AS tbl, count(*) AS total_rows, count(empresa_id) AS rows_with_empresa, count(*) - count(empresa_id) AS rows_null_empresa FROM public.parametros_calidad_agua
UNION ALL
SELECT 'alimentacion_diaria' AS tbl, count(*), count(empresa_id), count(*) - count(empresa_id) FROM public.alimentacion_diaria
UNION ALL
SELECT 'biometrias' AS tbl, count(*), count(empresa_id), count(*) - count(empresa_id) FROM public.biometrias
UNION ALL
SELECT 'mortalidad' AS tbl, count(*), count(empresa_id), count(*) - count(empresa_id) FROM public.mortalidad;
```
**Result**:
- `parametros_calidad_agua`: `total_rows: 11`, `rows_with_empresa: 11`, `rows_null_empresa: 0`
- `alimentacion_diaria`: `total_rows: 84`, `rows_with_empresa: 84`, `rows_null_empresa: 0`
- `biometrias`: `total_rows: 38`, `rows_with_empresa: 38`, `rows_null_empresa: 0`
- `mortalidad`: `total_rows: 8`, `rows_with_empresa: 8`, `rows_null_empresa: 0`

### 1.2 Row Level Security (RLS) Status and Policy Definitions
From `pg_class`:
- `alimentacion_diaria`: `relrowsecurity = true`
- `biometrias`: `relrowsecurity = true`
- `mortalidad`: `relrowsecurity = true`
- `parametros_calidad_agua`: `relrowsecurity = true`

From `pg_policies`:
- `alimentacion_diaria_tenant_select` (`SELECT`): `((empresa_id = get_auth_empresa_id()) OR is_superadmin())`
- `alimentacion_diaria_tenant_modify` (`ALL`): `(((empresa_id = get_auth_empresa_id()) AND (get_auth_user_role() = ANY (ARRAY['admin'::text, 'creador'::text, 'master'::text, 'tecnico'::text, 'operario'::text]))) OR is_superadmin())`
- `biometrias_tenant_select` (`SELECT`): `((empresa_id = get_auth_empresa_id()) OR is_superadmin())`
- `biometrias_tenant_modify` (`ALL`): `(((empresa_id = get_auth_empresa_id()) AND (get_auth_user_role() = ANY (ARRAY['admin'::text, 'creador'::text, 'master'::text, 'tecnico'::text, 'operario'::text]))) OR is_superadmin())`
- `mortalidad_tenant_select` (`SELECT`): `((empresa_id = get_auth_empresa_id()) OR is_superadmin())`
- `mortalidad_tenant_modify` (`ALL`): `(((empresa_id = get_auth_empresa_id()) AND (get_auth_user_role() = ANY (ARRAY['admin'::text, 'creador'::text, 'master'::text, 'tecnico'::text, 'operario'::text]))) OR is_superadmin())`
- `parametros_calidad_agua_tenant_select` (`SELECT`): `((empresa_id = get_auth_empresa_id()) OR is_superadmin())`
- `parametros_calidad_agua_tenant_modify` (`ALL`): `(((empresa_id = get_auth_empresa_id()) AND (get_auth_user_role() = ANY (ARRAY['admin'::text, 'creador'::text, 'master'::text, 'tecnico'::text, 'operario'::text, 'sanitarydirector'::text]))) OR is_superadmin())`

Both `qual` (USING) and `with_check` clauses are identically configured across all `ALL`/MODIFY policies.

### 1.3 Tenant Auto-Inheritance Triggers
From `information_schema.triggers`:
- `alimentacion_diaria`: `trg_alimentacion_diaria_tenant` (`BEFORE INSERT OR UPDATE FOR EACH ROW EXECUTE FUNCTION fn_auto_inherit_tenant_context()`)
- `biometrias`: `trg_biometrias_tenant` (`BEFORE INSERT OR UPDATE FOR EACH ROW EXECUTE FUNCTION fn_auto_inherit_tenant_context()`)
- `mortalidad`: `trg_mortalidad_tenant` (`BEFORE INSERT OR UPDATE FOR EACH ROW EXECUTE FUNCTION fn_auto_inherit_tenant_context()`)
- `parametros_calidad_agua`: `trg_parametros_calidad_agua_tenant` (`BEFORE INSERT OR UPDATE FOR EACH ROW EXECUTE FUNCTION fn_auto_inherit_tenant_context()`)

### 1.4 Foreign Key Integrity & Cascade Rules
From `information_schema.referential_constraints`:
- `empresa_id` in `parametros_calidad_agua`, `alimentacion_diaria`, `biometrias`, `mortalidad` references `empresas(id)` with `delete_rule = CASCADE`.
- `estanque_id` in `parametros_calidad_agua` and `alimentacion_diaria` references `estanques(id)` with `delete_rule = CASCADE`.
- `lote_id` in `biometrias` and `mortalidad` references `lotes(id)` with `delete_rule = SET NULL`.
- `unit_id` in `parametros_calidad_agua`, `alimentacion_diaria`, `biometrias`, `mortalidad` references `units(id)` with `delete_rule = SET NULL`.

### 1.5 Performance Indexes
From `pg_indexes`:
- `idx_calidad_agua_empresa_fecha` on `parametros_calidad_agua(empresa_id, fecha DESC)`
- `idx_alimentacion_empresa_fecha` on `alimentacion_diaria(empresa_id, fecha DESC)`
- `idx_biometrias_empresa_date` on `biometrias(empresa_id, date DESC)` & `idx_biometrias_empresa_fecha` on `biometrias(empresa_id, fecha DESC)`
- `idx_mortalidad_empresa_date` on `mortalidad(empresa_id, date DESC)` & `idx_mortalidad_empresa_fecha` on `mortalidad(empresa_id, fecha DESC)`

### 1.6 Idempotency Test Execution
Re-executed the entire migration script `supabase/migrations/20260829_milestone1_bitacora_schema_alignment.sql` directly on the database via MCP `execute_sql`.
- Execution returned `[]` with 0 errors.
- Pre and post row counts matched exactly (`parametros_calidad_agua`: 11, `alimentacion_diaria`: 84, `biometrias`: 38, `mortalidad`: 8).
- Zero duplicate rows created.

---

## 2. Logic Chain

1. **RLS Policy Correctness**:
   - The user request requires that data access is tenant-isolated using `get_auth_empresa_id()`.
   - Inspection of `pg_policies` proves that every Bitácora table has both an explicit `SELECT` policy and an `ALL` (INSERT/UPDATE/DELETE) policy.
   - The policies enforce `(empresa_id = public.get_auth_empresa_id()) OR public.is_superadmin()`, guaranteeing strict multi-tenant data boundaries.
   - Authorized roles (`admin`, `creador`, `master`, `tecnico`, `operario`, `sanitarydirector`) are verified via `get_auth_user_role()`.

2. **Trigger Safety & Fallback**:
   - The function `public.fn_auto_inherit_tenant_context()` was inspected in `pg_proc`.
   - When a client inserts a record without specifying `empresa_id`, the trigger automatically resolves `empresa_id` and `unit_id` from `estanques` via `NEW.estanque_id`. If `NEW.estanque_id` is null or does not yield an empresa, it falls back to `get_auth_empresa_id()`.
   - Adversarial testing in a transactional DO block confirmed that omitting `empresa_id` during insert on any of the 4 tables successfully auto-populates `empresa_id` matching the parent pond.

3. **Data Backfill & Schema Compatibility**:
   - In `mortalidad`, all 8 rows have non-null `empresa_id = '3500cc63-5477-4f83-b4a3-7758b7cd6509'`.
   - Dual-naming synonyms (`cantidad`/`quantity`, `causa`/`cause`, `fecha`/`date`, `avg_weight_gr`/`peso_promedio_g`, `total_biomass_kg`/`biomasa_parcial_kg`) are synchronized with zero null values across core fields.
   - In `parametros_calidad_agua`, all 11 migrated telemetry rows link to active ponds with valid timestamps, company, and unit IDs.

4. **Integrity & Absence of Dummy Implementations**:
   - Source code and migration scripts were checked for fake mocks, hardcoded test results, or bypasses.
   - Migration DDL statements are standard PostgreSQL syntax with full constraint checking.
   - No integrity violations detected.

---

## 3. Caveats

- In `parametros_calidad_agua`, historical records migrated from the legacy telemetry table only recorded `oxigeno_mg_l`, `ph`, `temperatura`, `amonio_mg_l`, `nitritos_mg_l`, `nitratos_mg_l`, and `alcalinidad_mg_l`; parameters not tracked in the legacy system (`co2_mg_l`, `dureza_mg_l`, `cloro_mg_l`, `fosforo_mg_l`) remain `NULL` for those 11 legacy entries, which accurately reflects historical telemetry data.
- No caveats regarding RLS enforcement, trigger behavior, or database constraints.

---

## 4. Conclusion

**Verdict: APPROVE**

Milestone 1 (M1) satisfies all database security, integrity, and performance requirements:
1. Canonical table `parametros_calidad_agua` is fully configured with 10+ physicochemical parameters, RLS, triggers, indexes, and migrated historical data.
2. RLS policies (`SELECT` and `ALL`) exist and are active on `parametros_calidad_agua`, `alimentacion_diaria`, `biometrias`, and `mortalidad` using `get_auth_empresa_id()`.
3. Auto-inheriting triggers (`trg_*_tenant`) are attached and verified.
4. `mortalidad` and `biometrias` backfills and column synchronizations are 100% complete with zero null `empresa_id` values.
5. Migration SQL script is idempotent and safe for repeat executions.

---

## 5. Verification Method

To independently reproduce this verification:

1. **Verify Row Counts & Empresa Non-Null**:
   ```sql
   SELECT tbl, total_rows, rows_with_empresa, rows_null_empresa
   FROM (
     SELECT 'parametros_calidad_agua' AS tbl, count(*) AS total_rows, count(empresa_id) AS rows_with_empresa, count(*) - count(empresa_id) AS rows_null_empresa FROM public.parametros_calidad_agua
     UNION ALL
     SELECT 'alimentacion_diaria' AS tbl, count(*), count(empresa_id), count(*) - count(empresa_id) FROM public.alimentacion_diaria
     UNION ALL
     SELECT 'biometrias' AS tbl, count(*), count(empresa_id), count(*) - count(empresa_id) FROM public.biometrias
     UNION ALL
     SELECT 'mortalidad' AS tbl, count(*), count(empresa_id), count(*) - count(empresa_id) FROM public.mortalidad
   ) t;
   ```
   *Expected*: `rows_null_empresa = 0` for all 4 tables.

2. **Verify Active RLS Policies**:
   ```sql
   SELECT tablename, policyname, cmd, qual, with_check 
   FROM pg_policies 
   WHERE schemaname = 'public' AND tablename IN ('parametros_calidad_agua', 'alimentacion_diaria', 'biometrias', 'mortalidad')
   ORDER BY tablename, cmd;
   ```
   *Expected*: 2 policies per table (`*_tenant_select` for `SELECT` and `*_tenant_modify` for `ALL`).

3. **Verify Triggers**:
   ```sql
   SELECT event_object_table, trigger_name, action_timing, action_statement
   FROM information_schema.triggers
   WHERE trigger_schema = 'public' AND event_object_table IN ('parametros_calidad_agua', 'alimentacion_diaria', 'biometrias', 'mortalidad')
   ORDER BY event_object_table, trigger_name;
   ```
   *Expected*: `trg_*_tenant` attached to `BEFORE INSERT OR UPDATE` executing `fn_auto_inherit_tenant_context()`.

4. **Verify Idempotency**:
   Execute the migration SQL file against `oakovawlwjpnoydpwtam` and verify that execution succeeds with zero errors and no duplicate rows.
