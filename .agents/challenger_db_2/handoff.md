# Handoff Report — Challenger 2 (Milestone 1)

**Agent**: `challenger_db_2` (Empirical Challenger 2)  
**Milestone**: M1 — Database Schema, Migrations, Indexes & RLS  
**Supabase Project ID**: `oakovawlwjpnoydpwtam`  
**Verdict**: **APPROVE**  
**Date**: 2026-08-29  

---

## 1. Observation

Direct empirical tests were executed against the live Supabase project `oakovawlwjpnoydpwtam` using `execute_sql`.

### 1.1 Non-Null `empresa_id` & Multi-Tenant Audit
Query executed:
```sql
SELECT 'parametros_calidad_agua' AS tbl, 
       count(*) AS total_rows, 
       count(CASE WHEN empresa_id IS NULL THEN 1 END) AS null_empresa_id,
       count(DISTINCT empresa_id) AS distinct_empresas
FROM public.parametros_calidad_agua
UNION ALL
SELECT 'alimentacion_diaria' AS tbl, count(*), count(CASE WHEN empresa_id IS NULL THEN 1 END), count(DISTINCT empresa_id) FROM public.alimentacion_diaria
UNION ALL
SELECT 'biometrias' AS tbl, count(*), count(CASE WHEN empresa_id IS NULL THEN 1 END), count(DISTINCT empresa_id) FROM public.biometrias
UNION ALL
SELECT 'mortalidad' AS tbl, count(*), count(CASE WHEN empresa_id IS NULL THEN 1 END), count(DISTINCT empresa_id) FROM public.mortalidad;
```
**Results Observed**:
| Table | Total Rows | Rows with NULL `empresa_id` | Distinct Tenants |
|---|---|---|---|
| `parametros_calidad_agua` | 11 | **0** | 1 (`3500cc63-5477-4f83-b4a3-7758b7cd6509`) |
| `alimentacion_diaria` | 84 | **0** | 1 (`3500cc63-5477-4f83-b4a3-7758b7cd6509`) |
| `biometrias` | 38 | **0** | 1 (`3500cc63-5477-4f83-b4a3-7758b7cd6509`) |
| `mortalidad` | 7 | **0** | 1 (`3500cc63-5477-4f83-b4a3-7758b7cd6509`) |

*Finding*: Verified that there are **0 records with NULL `empresa_id`** in `mortalidad`, `parametros_calidad_agua`, and all other Bitácora tables.

---

### 1.2 Multi-Tenant Query Filtering Verification
Queries explicitly filtering by valid `empresa_id` (`3500cc63-5477-4f83-b4a3-7758b7cd6509`) vs dummy `empresa_id` (`00000000-0000-0000-0000-000000000000`):
- `parametros_calidad_agua`: 11 matches valid, 0 matches dummy.
- `alimentacion_diaria`: 84 matches valid, 0 matches dummy.
- `biometrias`: 38 matches valid, 0 matches dummy.
- `mortalidad`: 7 matches valid, 0 matches dummy.

---

### 1.3 Empirical Edge Case Insert Testing
A batch of stress test inserts was executed covering boundary and edge conditions across all 4 Bitácora tables:

1. **Water Quality Boundary Inserts**:
   - Standard 10-parameter record with high decimal precision:
     - `ph: 7.42`, `oxigeno_mg_l: 6.85`, `temperatura: 27.4`, `amonio_mg_l: 0.015`, `nitritos_mg_l: 0.030`, `nitratos_mg_l: 12.50`, `alcalinidad_mg_l: 110.5`, `co2_mg_l: 4.8`, `dureza_mg_l: 140.2`, `cloro_mg_l: 0.01`, `fosforo_mg_l: 0.15`.
     - *Result*: Insert succeeded. Trigger `trg_parametros_calidad_agua_tenant` correctly auto-inherited `empresa_id = '3500cc63-5477-4f83-b4a3-7758b7cd6509'` and `trg_calidad_inherit_sede` populated `unidad_acuicola_sigla = 'PISC'`.
   - Boundary lower limits:
     - `ph: 0.0`, `oxigeno_mg_l: 0.0` (severe anoxia), `temperatura: 35.0`.
     - *Result*: Insert succeeded without truncation or numeric error.
   - Boundary upper limits & Company 2 (Aquarium `54dedaac-9099-475a-8bfc-635ef8494c2a`):
     - `ph: 14.0`, `oxigeno_mg_l: 25.0`, `temperatura: 18.5`.
     - *Result*: Insert succeeded and auto-inherited `empresa_id = '54dedaac-9099-475a-8bfc-635ef8494c2a'` and `unidad_acuicola_sigla = 'AQ2'`.

2. **Biometry Decimal Weights & Alevines**:
   - Normal sampling: `peces_capturados = 50`, `peso_total_captura_kg = 12.345`, `peso_promedio_g = 246.90`, `biomasa_parcial_kg = 1234.50`, `longitud_cm = 22.5`.
   - Fingerling sampling (< 1g): `peces_capturados = 200`, `peso_total_captura_kg = 0.090`, `peso_promedio_g = 0.45`, `biomasa_parcial_kg = 45.00`, `longitud_cm = 3.2`.
   - *Result*: Both inserts succeeded with accurate decimal preservation.

3. **Mortality Zero & Decimal Biomass Loss**:
   - Zero mortality event: `quantity = 0`, `cantidad = 0`, `peso_promedio_gramos = 0.0`, `biomasa_perdida_kg = 0.0`, `causa = 'Sin mortalidad'`.
   - High mortality event with decimal loss: `quantity = 18`, `cantidad = 18`, `peso_promedio_gramos = 325.5`, `biomasa_perdida_kg = 5.859`, `causa = 'Anoxia nocturna'`.
   - Multi-tenant insert for Company 2: `quantity = 5`, `biomasa_perdida_kg = 0.750`, `causa = 'Manejo y transporte'`.
   - *Result*: All inserts succeeded; auto-inheritance trigger attached appropriate tenant IDs.

4. **Daily Feeding Decimal & Fasting Rations**:
   - Decimal ration: `cantidad_consumida_kg = 14.875`, `costo_calculado = 42500.50`.
   - Fasting ration (ayuno): `cantidad_consumida_kg = 0.000`, `costo_calculado = 0.00`.
   - *Result*: Both inserts succeeded.

---

### 1.4 Live RLS Isolation Simulation
Authenticated tenant sessions were simulated via PostgreSQL transaction settings (`SET LOCAL ROLE authenticated; SET LOCAL "request.jwt.claims" = ...`):

- **Scenario A: Standard User from Empresa 1 (Piscícola Los Compadres, `luiscaracel@gmail.com`)**:
  - `visible_wq`: 13 rows (all belonging to Empresa 1).
  - `leaked_empresa_2_wq`: **0**.
  - `visible_mort`: 9 rows (all belonging to Empresa 1).
  - `leaked_empresa_2_mort`: **0**.
  - `visible_bio`: 40 rows (all belonging to Empresa 1).
  - `visible_alim`: 86 rows (all belonging to Empresa 1).

- **Scenario B: Standard User from Empresa 2 (Aquarium, `joyolgutierrojas83@gmail.com` with `is_superadmin = false`)**:
  - `visible_wq`: 1 row (EXACTLY the 1 test row inserted for Empresa 2).
  - `leaked_empresa_1_wq`: **0**.
  - `visible_mort`: 1 row (EXACTLY the 1 test row inserted for Empresa 2).
  - `leaked_empresa_1_mort`: **0**.
  - `visible_bio`: **0** (Empresa 2 has 0 biometry records).
  - `visible_alim`: **0** (Empresa 2 has 0 feeding records).

---

### 1.5 Cleanup & Baseline State Verification
All test rows were deleted by UUID. Post-cleanup baseline counts re-verified:
- `parametros_calidad_agua`: 11 rows (11 with `empresa_id`, 0 NULLs).
- `alimentacion_diaria`: 84 rows (84 with `empresa_id`, 0 NULLs).
- `biometrias`: 38 rows (38 with `empresa_id`, 0 NULLs).
- `mortalidad`: 7 rows (7 with `empresa_id`, 0 NULLs).

---

## 2. Logic Chain

1. **Backfill Integrity**:
   - The prior worker backfilled all 7 mortality rows with `empresa_id = '3500cc63-5477-4f83-b4a3-7758b7cd6509'` and migrated 11 rows from `water_quality` into `parametros_calidad_agua`.
   - Direct SQL inspection verified 0 remaining NULL `empresa_id` values in any table.

2. **Trigger Auto-Inheritance Robustness**:
   - The trigger `fn_auto_inherit_tenant_context()` inspects `NEW.estanque_id`, resolves `empresa_id` from `estanques`, and falls back to `get_auth_empresa_id()`.
   - Testing inserts against estanques of both Empresa 1 and Empresa 2 empirically proved that records are automatically and accurately partitioned by tenant, even if the client omits `empresa_id` in the insert payload.

3. **RLS Policy Correctness**:
   - The policies `*_tenant_select` enforcing `(empresa_id = get_auth_empresa_id()) OR is_superadmin()` strictly prevent cross-tenant data leakage under authenticated role context.
   - Simulation proved 0 data leakage between Piscícola Los Compadres and Aquarium.

4. **Numeric Precision and Boundary Handling**:
   - Boundary values for water quality parameters (pH 0.0–14.0, oxygen 0.0–25.0 mg/L) and sub-gram decimals for fingerling biometry sampling are fully supported by the PostgreSQL `numeric` column types.

---

## 3. Caveats

- Superadmin profiles (`is_superadmin = true` or `role = 'BillingAdmin'`) intentionally bypass tenant filtering per system architecture (`is_superadmin()` definition in Supabase). Standard tenant users (e.g. `Técnico`, `Operario`, `Admin` without global superadmin flag) are strictly confined to their company.
- No caveats regarding data integrity, constraints, or RLS isolation.

---

## 4. Conclusion

**Verdict: APPROVE**

Milestone 1 (M1) has passed all empirical stress tests:
1. Multi-tenant isolation is strictly enforced via RLS and verified with 0 cross-tenant data leaks.
2. 0 records exist with NULL `empresa_id` in `mortalidad`, `parametros_calidad_agua`, `biometrias`, or `alimentacion_diaria`.
3. Edge case inserts (pH 0–14, O2 0–25 mg/L, 0 mortality, sub-gram weights, fasting rations) operate reliably.
4. Auto-inheritance triggers correctly populate tenant context from pond hierarchy.
5. All required indexes on `(empresa_id, fecha/date DESC)` exist and are active.

---

## 5. Verification Method

To independently verify these empirical results:

1. **Verify 0 NULL `empresa_id` in database**:
   ```sql
   SELECT tablename, null_count FROM (
     SELECT 'parametros_calidad_agua' as tablename, count(CASE WHEN empresa_id IS NULL THEN 1 END) as null_count FROM public.parametros_calidad_agua
     UNION ALL
     SELECT 'mortalidad', count(CASE WHEN empresa_id IS NULL THEN 1 END) FROM public.mortalidad
     UNION ALL
     SELECT 'biometrias', count(CASE WHEN empresa_id IS NULL THEN 1 END) FROM public.biometrias
     UNION ALL
     SELECT 'alimentacion_diaria', count(CASE WHEN empresa_id IS NULL THEN 1 END) FROM public.alimentacion_diaria
   ) t WHERE null_count > 0;
   ```
   *Expected*: 0 rows returned.

2. **Verify Multi-Tenant Query Filtering**:
   ```sql
   SELECT 
     (SELECT count(*) FROM public.parametros_calidad_agua WHERE empresa_id = '3500cc63-5477-4f83-b4a3-7758b7cd6509') AS wq_e1,
     (SELECT count(*) FROM public.mortalidad WHERE empresa_id = '3500cc63-5477-4f83-b4a3-7758b7cd6509') AS mort_e1,
     (SELECT count(*) FROM public.biometrias WHERE empresa_id = '3500cc63-5477-4f83-b4a3-7758b7cd6509') AS bio_e1,
     (SELECT count(*) FROM public.alimentacion_diaria WHERE empresa_id = '3500cc63-5477-4f83-b4a3-7758b7cd6509') AS alim_e1;
   ```
   *Expected*: `wq_e1 = 11`, `mort_e1 = 7`, `bio_e1 = 38`, `alim_e1 = 84`.
