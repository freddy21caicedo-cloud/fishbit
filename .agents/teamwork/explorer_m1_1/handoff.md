# Handoff Report: Database Schema, RLS Hardening & Traceability RPC (Milestone 1)

**Agent:** explorer_m1_1  
**Date:** 2026-10-27  
**Working Directory:** `c:\Users\Freddy\Desktop\Desarrollo de app\FishBit\.agents\teamwork\explorer_m1_1\`  
**Target Milestone:** Milestone 1 — Database Schema, Atomic RPC & Data Traceability  

---

## 1. Observation

### 1.1 RLS Multi-Tenant Leakage across 5 Tables
In `supabase/migrations/20260831_database_performance_and_rls_optimization.sql`, the RLS policies for `compras_mat_biologico`, `equipos`, `mantenimientos`, `facturas`, and `inventario_insumos` isolate records using:
- **`compras_mat_biologico` (lines 519, 526, 534, 539, 547):**
  ```sql
  unidad_acuicola_sigla IN (SELECT u.sigla FROM public.units u WHERE u.empresa_id = (SELECT public.get_auth_empresa_id()))
  OR (SELECT public.is_superadmin())
  ```
- **`equipos` (lines 563-564, 571, 579, 584, 592):**
  ```sql
  cliente_id = (SELECT public.get_auth_empresa_id())
  OR unidad_acuicola_sigla IN (SELECT u.sigla FROM public.units u WHERE u.empresa_id = (SELECT public.get_auth_empresa_id()))
  OR (SELECT public.is_superadmin())
  ```
- **`mantenimientos` (lines 607, 614, 622, 627, 635):**
  ```sql
  unidad_acuicola_sigla IN (SELECT u.sigla FROM public.units u WHERE u.empresa_id = (SELECT public.get_auth_empresa_id()))
  OR (SELECT public.is_superadmin())
  ```
- **`facturas` (lines 881-882, 889, 897, 902, 910):**
  ```sql
  empresa_id = (SELECT public.get_auth_empresa_id())
  OR unidad_acuicola_sigla IN (SELECT u.sigla FROM public.units u WHERE u.empresa_id = (SELECT public.get_auth_empresa_id()))
  OR (SELECT public.is_superadmin())
  ```
- **`inventario_insumos` (lines 998-999, 1006, 1014, 1019, 1027):**
  ```sql
  cliente_id = (SELECT public.get_auth_empresa_id()) 
  OR unidad_acuicola_sigla IN (SELECT u.sigla FROM public.units u WHERE u.empresa_id = (SELECT public.get_auth_empresa_id())) 
  OR (SELECT public.is_superadmin())
  ```
Meanwhile, in `supabase_schema_canonical_v10.sql:40`:
```sql
CONSTRAINT uq_empresa_sigla UNIQUE (empresa_id, sigla)
```
The acronym (`sigla`) is **unique only per company**, not globally. If Company A and Company B both configure a unit as `'SEDE'` or `'PRIN'`, any user of Company A can view and modify purchases, equipment, maintenance, invoices, and warehouse stock belonging to Company B.
Furthermore, in the existing migration, 4 separate policies were created per table (`_select`, `_insert`, `_update`, `_delete`). Any replacement script must explicitly `DROP` all 4 previous policies per table; dropping only `_select` and `_modify` would leave permissive `_insert`, `_update`, and `_delete` policies active under PostgreSQL's boolean `OR` policy aggregation rules.

### 1.2 Total Absence of DDL for `public.traslados_lotes` (DATA-01)
A thorough scan of all 6 `.sql` files in the repository:
- `supabase/migrations/20260829_milestone1_bitacora_schema_alignment.sql`
- `supabase/migrations/20260831_cost_security_and_immutability.sql`
- `supabase/migrations/20260831_database_performance_and_rls_optimization.sql`
- `supabase_data_sync_legacy_to_v2.sql`
- `supabase_migration_v10_canonical_v2.sql`
- `supabase_schema_canonical_v10.sql`
revealed that `public.traslados_lotes` is referenced in indexes and RLS statements (`20260831_database_performance_and_rls_optimization.sql:118-128, 383-412`) and in application code (`lib/modules/ponds_batches/infrastructure/repositories/supabase_ponds_repository.dart:682, 707`), but **no `CREATE TABLE` statement exists anywhere in the repository**. Any fresh deployment or migration execution on a clean database throws PostgreSQL error `42P01: relation "public.traslados_lotes" does not exist`.

### 1.3 Schema Discrepancies between Draft RPC in `FINAL_AUDIT_REPORT.md §6.2` and Canonical Database
Inspection of `supabase_schema_canonical_v10.sql:114-136` and `lib/modules/ponds_batches/domain/models/fish_batch.dart:216-254` revealed critical differences with the draft SQL in `FINAL_AUDIT_REPORT.md §6.2`:
1. **Column names on `public.lotes`:**
   - Draft RPC writes: `peso_inicial_g`, `peso_actual_g`, `costo_alevinos`, `costo_insumos`, `costo_fijo`, `costo_total`, `variedad`, `etapa`.
   - Real canonical schema has: `peso_inicial_gramos`, `peso_actual_gramos`, `costo_inicial_alevinos`, `costo_acumulado_insumos`, `costo_acumulado_fijo`.
   - `costo_total`, `variedad`, and `etapa` do NOT exist as columns in `public.lotes` (they are client-side computed getters or not present).
2. **Check constraint on `public.lotes.estado`:**
   - `CHECK (estado IN ('Activo', 'Cosechado', 'Dividido'))` (Title Case).
   - Draft RPC used uppercase `'ACTIVO'`, which will throw a check constraint violation error `23514`.
3. **Columns on `public.estanques` (`supabase_schema_canonical_v10.sql:92-109`):**
   - Real schema has: `biomasa_kg`, `costo_acumulado_biologico`, `especie_actual`, `estado` (`'Activo'`, `'Disponible'`, `'Cosechado'`).
   - Draft RPC attempts to update `cantidad_peces`, which **does NOT exist on `public.estanques`**.
4. **Missing columns on `public.lotes` for historical traceability:**
   - `alimento_acumulado_kg` is currently only in `fish_batch.dart:197` and not persisted in SQL. To transfer accumulated feed during batch splitting, `alimento_acumulado_kg NUMERIC NOT NULL DEFAULT 0.0` must be added via `ALTER TABLE`.
   - `rol_policultivo TEXT DEFAULT 'principal'` and `updated_at TIMESTAMPTZ` should be added.
5. **Timestamps on `public.traslados_lotes`:**
   - `TransferRecord.toJson()` (`transfer_record.dart:118`) serializes `'creado_en'`.
   - The proposed table must include both `creado_en TIMESTAMPTZ` and `created_at TIMESTAMPTZ` for total compatibility.

### 1.4 Polyculture Biomass Overwriting (DATA-02)
In `lib/modules/ponds_batches/infrastructure/repositories/supabase_ponds_repository.dart`:
- Line 935 (`registerMortality`): updates `estanques` with `biomasa_kg: newBiomass` (only the biomass of the current lot).
- Line 1098 (`registerBiometry`): updates `estanques` with `biomasa_kg: newBiomass` (only the biomass of the current lot).
In polyculture ponds with 2+ active lots, the total pond biomass is destroyed on every biometry/mortality event.

### 1.5 Missing Dependencies in `pubspec.yaml` for REG-01
In `lib/core/reports/web_download_helper_stub.dart:2-4`, `downloadFileWeb` is a no-op empty function. Implementing mobile/desktop report exports via `path_provider` and `share_plus` requires adding those packages to `pubspec.yaml`, which currently has neither.

---

## 2. Logic Chain

1. **Premise:** Multi-tenant security requires that tenant isolation relies exclusively on immutable tenant keys (`empresa_id = public.get_auth_empresa_id()`) rather than business acronyms (`unidad_acuicola_sigla`), because siglas can collide across organizations under `UNIQUE (empresa_id, sigla)`.
2. **Inference 1:** The RLS policies in `20260831_database_performance_and_rls_optimization.sql` on `compras_mat_biologico`, `equipos`, `mantenimientos`, `facturas`, and `inventario_insumos` permit unauthorized cross-tenant read/write when two companies have matching unit siglas (e.g. `'SEDE'`).
3. **Inference 2:** Replacing these policies requires dropping all legacy variants (`_select`, `_insert`, `_update`, `_delete`, `_modify`, `_tenant_all`) and creating single canonical tenant-checked policies on `empresa_id`.
4. **Premise:** The application queries `public.traslados_lotes` in `supabase_ponds_repository.dart:682, 707`.
5. **Inference 3:** Because `public.traslados_lotes` table DDL was never executed in any migration, the table does not exist in fresh databases, causing runtime error `42P01`.
6. **Premise:** Batch splitting and transfers in `supabase_ponds_repository.dart:584-657` execute 5 separate REST calls from Flutter without atomic database guarantees, distorting FCR when the child batch inherits 0 kg of feed history and parent batch retains 100% feed history while losing 50% biomass.
7. **Inference 4:** Deploying an atomic PostgreSQL function `public.split_or_transfer_batch` locks the parent batch, transfers proportional costs and accumulated feed, creates the child batch, logs the audit record in `traslados_lotes`, and recalculates pond biomass using `SUM(biomasa_actual_kg)` across all active batches in that pond.
8. **Inference 5:** To prevent execution errors in PostgreSQL, the RPC must strictly use existing column names (`peso_actual_gramos`, `costo_inicial_alevinos`, `costo_acumulado_insumos`, `costo_acumulado_fijo`, Title Case `'Activo'`), avoid nonexistent columns (`cantidad_peces`, `costo_total`, `variedad`), and ensure `alimento_acumulado_kg` is added to `public.lotes`.

---

## 3. Caveats

- **No Remote Database Executions:** Local static file investigation was conducted without direct execution against remote Supabase instance (per orchestrator instructions).
- **Existing Data Compatibility:** The migration uses `IF NOT EXISTS` for all tables, columns, and indexes, and `DROP POLICY IF EXISTS` for all policies, guaranteeing idempotency regardless of whether a database is newly initialized or already running previous migrations.
- **Client Synchronization:** Once `public.split_or_transfer_batch` is created, `supabase_ponds_repository.dart` should be updated to call `_supabase.rpc('split_or_transfer_batch', ...)` instead of executing the 5 non-atomic REST queries.

---

## 4. Conclusion & Actionable Recommendations

The Worker assigned to Milestone 1 must create `supabase/migrations/20261027_master_traceability_and_rls_hardening.sql` containing the exact, fully verified SQL script detailed below.

### 4.1 Canonical Migration Script: `supabase/migrations/20261027_master_traceability_and_rls_hardening.sql`

```sql
-- ==============================================================================
-- Migration: 20261027_master_traceability_and_rls_hardening.sql
-- Module: Traceability, Multi-Tenant RLS Hardening & Atomic Batch RPC
-- Target: Supabase PostgreSQL (FishBit Finance 2.0)
-- Idempotency: Fully idempotent (safe to execute multiple times)
-- ==============================================================================

BEGIN;

-- ------------------------------------------------------------------------------
-- 1. EXTENSIONS & SCHEMA ALIGNMENT ON EXISTING TABLES
-- ------------------------------------------------------------------------------
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- Align public.lotes with traceability & polyculture columns
ALTER TABLE public.lotes 
  ADD COLUMN IF NOT EXISTS alimento_acumulado_kg NUMERIC NOT NULL DEFAULT 0.0,
  ADD COLUMN IF NOT EXISTS rol_policultivo TEXT DEFAULT 'principal',
  ADD COLUMN IF NOT EXISTS updated_at TIMESTAMPTZ DEFAULT timezone('utc'::text, now());

-- Align public.estanques with timestamp
ALTER TABLE public.estanques 
  ADD COLUMN IF NOT EXISTS updated_at TIMESTAMPTZ DEFAULT timezone('utc'::text, now());

-- Ensure empresa_id exists on all 5 operational tables
ALTER TABLE public.compras_mat_biologico 
  ADD COLUMN IF NOT EXISTS empresa_id UUID REFERENCES public.empresas(id) ON DELETE CASCADE;

ALTER TABLE public.equipos 
  ADD COLUMN IF NOT EXISTS empresa_id UUID REFERENCES public.empresas(id) ON DELETE CASCADE;

ALTER TABLE public.mantenimientos 
  ADD COLUMN IF NOT EXISTS empresa_id UUID REFERENCES public.empresas(id) ON DELETE CASCADE;

ALTER TABLE public.facturas 
  ADD COLUMN IF NOT EXISTS empresa_id UUID REFERENCES public.empresas(id) ON DELETE CASCADE;

ALTER TABLE public.inventario_insumos 
  ADD COLUMN IF NOT EXISTS empresa_id UUID REFERENCES public.empresas(id) ON DELETE CASCADE;

-- Backfill empresa_id from units/cliente_id if null on legacy data
DO $$
BEGIN
  IF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_schema = 'public' AND table_name = 'equipos' AND column_name = 'cliente_id') THEN
    UPDATE public.equipos SET empresa_id = cliente_id WHERE empresa_id IS NULL AND cliente_id IS NOT NULL;
  END IF;
  IF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_schema = 'public' AND table_name = 'inventario_insumos' AND column_name = 'cliente_id') THEN
    UPDATE public.inventario_insumos SET empresa_id = cliente_id WHERE empresa_id IS NULL AND cliente_id IS NOT NULL;
  END IF;
END $$;

UPDATE public.compras_mat_biologico c
SET empresa_id = u.empresa_id
FROM public.units u
WHERE c.empresa_id IS NULL AND c.unidad_acuicola_id = u.id;

UPDATE public.mantenimientos m
SET empresa_id = u.empresa_id
FROM public.units u
WHERE m.empresa_id IS NULL AND m.unidad_acuicola_id = u.id;

UPDATE public.facturas f
SET empresa_id = u.empresa_id
FROM public.units u
WHERE f.empresa_id IS NULL AND f.unidad_acuicola_id = u.id;

-- ------------------------------------------------------------------------------
-- 2. DDL: CANONICAL CREATION OF public.traslados_lotes (DATA-01)
-- ------------------------------------------------------------------------------
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
    creado_en TIMESTAMPTZ NOT NULL DEFAULT timezone('utc'::text, now()),
    created_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc'::text, now())
);

-- ------------------------------------------------------------------------------
-- 3. STRATEGIC COMPOSITE INDEXES FOR TIME SERIES & BITACORA
-- ------------------------------------------------------------------------------
CREATE INDEX IF NOT EXISTS idx_traslados_empresa_fecha 
  ON public.traslados_lotes(empresa_id, fecha_operacion DESC);

CREATE INDEX IF NOT EXISTS idx_traslados_empresa_lote_origen 
  ON public.traslados_lotes(empresa_id, lote_origen_id, fecha_operacion DESC);

CREATE INDEX IF NOT EXISTS idx_traslados_empresa_lote_destino 
  ON public.traslados_lotes(empresa_id, lote_destino_id, fecha_operacion DESC);

CREATE INDEX IF NOT EXISTS idx_traslados_empresa_estanque_origen 
  ON public.traslados_lotes(empresa_id, estanque_origen_id, fecha_operacion DESC);

CREATE INDEX IF NOT EXISTS idx_traslados_empresa_estanque_destino 
  ON public.traslados_lotes(empresa_id, estanque_destino_id, fecha_operacion DESC);

CREATE INDEX IF NOT EXISTS idx_compras_bio_empresa_fecha 
  ON public.compras_mat_biologico(empresa_id, fecha DESC);

CREATE INDEX IF NOT EXISTS idx_equipos_empresa_id 
  ON public.equipos(empresa_id);

CREATE INDEX IF NOT EXISTS idx_mantenimientos_empresa_fecha 
  ON public.mantenimientos(empresa_id, fecha DESC);

CREATE INDEX IF NOT EXISTS idx_facturas_empresa_fecha 
  ON public.facturas(empresa_id, fecha_expedicion DESC);

CREATE INDEX IF NOT EXISTS idx_inventario_insumos_empresa 
  ON public.inventario_insumos(empresa_id);

-- ------------------------------------------------------------------------------
-- 4. RLS ON traslados_lotes
-- ------------------------------------------------------------------------------
ALTER TABLE public.traslados_lotes ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS traslados_lotes_tenant_all ON public.traslados_lotes;
DROP POLICY IF EXISTS traslados_lotes_tenant_select ON public.traslados_lotes;
DROP POLICY IF EXISTS traslados_lotes_tenant_insert ON public.traslados_lotes;
DROP POLICY IF EXISTS traslados_lotes_tenant_update ON public.traslados_lotes;
DROP POLICY IF EXISTS traslados_lotes_tenant_delete ON public.traslados_lotes;
DROP POLICY IF EXISTS "Permitir acceso por empresa" ON public.traslados_lotes;

CREATE POLICY traslados_lotes_tenant_select ON public.traslados_lotes
  FOR SELECT TO authenticated
  USING (empresa_id = (SELECT public.get_auth_empresa_id()) OR (SELECT public.is_superadmin()));

CREATE POLICY traslados_lotes_tenant_insert ON public.traslados_lotes
  FOR INSERT TO authenticated
  WITH CHECK (empresa_id = (SELECT public.get_auth_empresa_id()) OR (SELECT public.is_superadmin()));

CREATE POLICY traslados_lotes_tenant_update ON public.traslados_lotes
  FOR UPDATE TO authenticated
  USING (empresa_id = (SELECT public.get_auth_empresa_id()) OR (SELECT public.is_superadmin()))
  WITH CHECK (empresa_id = (SELECT public.get_auth_empresa_id()));

CREATE POLICY traslados_lotes_tenant_delete ON public.traslados_lotes
  FOR DELETE TO authenticated
  USING (
    (empresa_id = (SELECT public.get_auth_empresa_id()) 
     AND (SELECT public.get_auth_user_role()) = ANY (ARRAY['admin', 'creador', 'master'])) 
    OR (SELECT public.is_superadmin())
  );

-- ------------------------------------------------------------------------------
-- 5. HARDENING MULTI-TENANT RLS POLICIES ACROSS 5 OPERATIONAL TABLES (SEC-01)
-- ------------------------------------------------------------------------------

-- A. compras_mat_biologico
ALTER TABLE public.compras_mat_biologico ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS compras_mat_biologico_tenant_all ON public.compras_mat_biologico;
DROP POLICY IF EXISTS compras_mat_biologico_tenant_select ON public.compras_mat_biologico;
DROP POLICY IF EXISTS compras_mat_biologico_tenant_modify ON public.compras_mat_biologico;
DROP POLICY IF EXISTS compras_mat_biologico_tenant_insert ON public.compras_mat_biologico;
DROP POLICY IF EXISTS compras_mat_biologico_tenant_update ON public.compras_mat_biologico;
DROP POLICY IF EXISTS compras_mat_biologico_tenant_delete ON public.compras_mat_biologico;

CREATE POLICY compras_mat_biologico_tenant_select ON public.compras_mat_biologico
  FOR SELECT TO authenticated
  USING (empresa_id = (SELECT public.get_auth_empresa_id()) OR (SELECT public.is_superadmin()));

CREATE POLICY compras_mat_biologico_tenant_insert ON public.compras_mat_biologico
  FOR INSERT TO authenticated
  WITH CHECK (
    (empresa_id = (SELECT public.get_auth_empresa_id()) 
     AND (SELECT public.get_auth_user_role()) = ANY (ARRAY['admin', 'creador', 'master', 'tecnico']))
    OR (SELECT public.is_superadmin())
  );

CREATE POLICY compras_mat_biologico_tenant_update ON public.compras_mat_biologico
  FOR UPDATE TO authenticated
  USING (
    (empresa_id = (SELECT public.get_auth_empresa_id()) 
     AND (SELECT public.get_auth_user_role()) = ANY (ARRAY['admin', 'creador', 'master', 'tecnico']))
    OR (SELECT public.is_superadmin())
  )
  WITH CHECK (empresa_id = (SELECT public.get_auth_empresa_id()));

CREATE POLICY compras_mat_biologico_tenant_delete ON public.compras_mat_biologico
  FOR DELETE TO authenticated
  USING (
    (empresa_id = (SELECT public.get_auth_empresa_id()) 
     AND (SELECT public.get_auth_user_role()) = ANY (ARRAY['admin', 'creador', 'master']))
    OR (SELECT public.is_superadmin())
  );

-- B. equipos
ALTER TABLE public.equipos ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS equipos_tenant_all ON public.equipos;
DROP POLICY IF EXISTS equipos_tenant_select ON public.equipos;
DROP POLICY IF EXISTS equipos_tenant_modify ON public.equipos;
DROP POLICY IF EXISTS equipos_tenant_insert ON public.equipos;
DROP POLICY IF EXISTS equipos_tenant_update ON public.equipos;
DROP POLICY IF EXISTS equipos_tenant_delete ON public.equipos;

CREATE POLICY equipos_tenant_select ON public.equipos
  FOR SELECT TO authenticated
  USING (empresa_id = (SELECT public.get_auth_empresa_id()) OR (SELECT public.is_superadmin()));

CREATE POLICY equipos_tenant_insert ON public.equipos
  FOR INSERT TO authenticated
  WITH CHECK (
    (empresa_id = (SELECT public.get_auth_empresa_id()) 
     AND (SELECT public.get_auth_user_role()) = ANY (ARRAY['admin', 'creador', 'master', 'tecnico']))
    OR (SELECT public.is_superadmin())
  );

CREATE POLICY equipos_tenant_update ON public.equipos
  FOR UPDATE TO authenticated
  USING (
    (empresa_id = (SELECT public.get_auth_empresa_id()) 
     AND (SELECT public.get_auth_user_role()) = ANY (ARRAY['admin', 'creador', 'master', 'tecnico']))
    OR (SELECT public.is_superadmin())
  )
  WITH CHECK (empresa_id = (SELECT public.get_auth_empresa_id()));

CREATE POLICY equipos_tenant_delete ON public.equipos
  FOR DELETE TO authenticated
  USING (
    (empresa_id = (SELECT public.get_auth_empresa_id()) 
     AND (SELECT public.get_auth_user_role()) = ANY (ARRAY['admin', 'creador', 'master']))
    OR (SELECT public.is_superadmin())
  );

-- C. mantenimientos
ALTER TABLE public.mantenimientos ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS mantenimientos_tenant_all ON public.mantenimientos;
DROP POLICY IF EXISTS mantenimientos_tenant_select ON public.mantenimientos;
DROP POLICY IF EXISTS mantenimientos_tenant_modify ON public.mantenimientos;
DROP POLICY IF EXISTS mantenimientos_tenant_insert ON public.mantenimientos;
DROP POLICY IF EXISTS mantenimientos_tenant_update ON public.mantenimientos;
DROP POLICY IF EXISTS mantenimientos_tenant_delete ON public.mantenimientos;

CREATE POLICY mantenimientos_tenant_select ON public.mantenimientos
  FOR SELECT TO authenticated
  USING (empresa_id = (SELECT public.get_auth_empresa_id()) OR (SELECT public.is_superadmin()));

CREATE POLICY mantenimientos_tenant_insert ON public.mantenimientos
  FOR INSERT TO authenticated
  WITH CHECK (
    (empresa_id = (SELECT public.get_auth_empresa_id()) 
     AND (SELECT public.get_auth_user_role()) = ANY (ARRAY['admin', 'creador', 'master', 'tecnico']))
    OR (SELECT public.is_superadmin())
  );

CREATE POLICY mantenimientos_tenant_update ON public.mantenimientos
  FOR UPDATE TO authenticated
  USING (
    (empresa_id = (SELECT public.get_auth_empresa_id()) 
     AND (SELECT public.get_auth_user_role()) = ANY (ARRAY['admin', 'creador', 'master', 'tecnico']))
    OR (SELECT public.is_superadmin())
  )
  WITH CHECK (empresa_id = (SELECT public.get_auth_empresa_id()));

CREATE POLICY mantenimientos_tenant_delete ON public.mantenimientos
  FOR DELETE TO authenticated
  USING (
    (empresa_id = (SELECT public.get_auth_empresa_id()) 
     AND (SELECT public.get_auth_user_role()) = ANY (ARRAY['admin', 'creador', 'master']))
    OR (SELECT public.is_superadmin())
  );

-- D. facturas
ALTER TABLE public.facturas ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS facturas_tenant_all ON public.facturas;
DROP POLICY IF EXISTS facturas_tenant_select ON public.facturas;
DROP POLICY IF EXISTS facturas_tenant_modify ON public.facturas;
DROP POLICY IF EXISTS facturas_tenant_insert ON public.facturas;
DROP POLICY IF EXISTS facturas_tenant_update ON public.facturas;
DROP POLICY IF EXISTS facturas_tenant_delete ON public.facturas;

CREATE POLICY facturas_tenant_select ON public.facturas
  FOR SELECT TO authenticated
  USING (empresa_id = (SELECT public.get_auth_empresa_id()) OR (SELECT public.is_superadmin()));

CREATE POLICY facturas_tenant_insert ON public.facturas
  FOR INSERT TO authenticated
  WITH CHECK (
    (empresa_id = (SELECT public.get_auth_empresa_id()) 
     AND (SELECT public.get_auth_user_role()) = ANY (ARRAY['admin', 'creador', 'master', 'tecnico', 'sanitarydirector']))
    OR (SELECT public.is_superadmin())
  );

CREATE POLICY facturas_tenant_update ON public.facturas
  FOR UPDATE TO authenticated
  USING (
    (empresa_id = (SELECT public.get_auth_empresa_id()) 
     AND (SELECT public.get_auth_user_role()) = ANY (ARRAY['admin', 'creador', 'master', 'tecnico', 'sanitarydirector']))
    OR (SELECT public.is_superadmin())
  )
  WITH CHECK (empresa_id = (SELECT public.get_auth_empresa_id()));

CREATE POLICY facturas_tenant_delete ON public.facturas
  FOR DELETE TO authenticated
  USING (
    (empresa_id = (SELECT public.get_auth_empresa_id()) 
     AND (SELECT public.get_auth_user_role()) = ANY (ARRAY['admin', 'creador', 'master']))
    OR (SELECT public.is_superadmin())
  );

-- E. inventario_insumos
ALTER TABLE public.inventario_insumos ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS inventario_insumos_tenant_all ON public.inventario_insumos;
DROP POLICY IF EXISTS inventario_insumos_tenant_select ON public.inventario_insumos;
DROP POLICY IF EXISTS inventario_insumos_tenant_modify ON public.inventario_insumos;
DROP POLICY IF EXISTS inventario_insumos_tenant_insert ON public.inventario_insumos;
DROP POLICY IF EXISTS inventario_insumos_tenant_update ON public.inventario_insumos;
DROP POLICY IF EXISTS inventario_insumos_tenant_delete ON public.inventario_insumos;

CREATE POLICY inventario_insumos_tenant_select ON public.inventario_insumos
  FOR SELECT TO authenticated
  USING (empresa_id = (SELECT public.get_auth_empresa_id()) OR (SELECT public.is_superadmin()));

CREATE POLICY inventario_insumos_tenant_insert ON public.inventario_insumos
  FOR INSERT TO authenticated
  WITH CHECK (
    (empresa_id = (SELECT public.get_auth_empresa_id()) 
     AND (SELECT public.get_auth_user_role()) = ANY (ARRAY['admin', 'creador', 'master', 'tecnico', 'operario']))
    OR (SELECT public.is_superadmin())
  );

CREATE POLICY inventario_insumos_tenant_update ON public.inventario_insumos
  FOR UPDATE TO authenticated
  USING (
    (empresa_id = (SELECT public.get_auth_empresa_id()) 
     AND (SELECT public.get_auth_user_role()) = ANY (ARRAY['admin', 'creador', 'master', 'tecnico', 'operario']))
    OR (SELECT public.is_superadmin())
  )
  WITH CHECK (empresa_id = (SELECT public.get_auth_empresa_id()));

CREATE POLICY inventario_insumos_tenant_delete ON public.inventario_insumos
  FOR DELETE TO authenticated
  USING (
    (empresa_id = (SELECT public.get_auth_empresa_id()) 
     AND (SELECT public.get_auth_user_role()) = ANY (ARRAY['admin', 'creador', 'master']))
    OR (SELECT public.is_superadmin())
  );

-- ------------------------------------------------------------------------------
-- 6. HELPER FUNCTION: SYNC POND BIOMASS ACROSS ACTIVE LOTS (DATA-02)
-- ------------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.sync_pond_biomass(p_estanque_id UUID)
RETURNS VOID
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
BEGIN
  UPDATE public.estanques e
  SET 
    biomasa_kg = COALESCE((
      SELECT SUM(biomasa_actual_kg) 
      FROM public.lotes 
      WHERE estanque_id = p_estanque_id AND estado = 'Activo'
    ), 0.0),
    costo_acumulado_biologico = COALESCE((
      SELECT SUM(costo_inicial_alevinos + costo_acumulado_insumos + costo_acumulado_fijo) 
      FROM public.lotes 
      WHERE estanque_id = p_estanque_id AND estado = 'Activo'
    ), 0.0),
    especie_actual = COALESCE((
      SELECT string_agg(DISTINCT especie, ', ') 
      FROM public.lotes 
      WHERE estanque_id = p_estanque_id AND estado = 'Activo'
    ), ''),
    estado = CASE 
      WHEN EXISTS (SELECT 1 FROM public.lotes WHERE estanque_id = p_estanque_id AND estado = 'Activo') THEN 'Activo' 
      ELSE 'Disponible' 
    END,
    updated_at = timezone('utc'::text, now())
  WHERE e.id = p_estanque_id;
END;
$$;

-- ------------------------------------------------------------------------------
-- 7. ATOMIC TRANSACTIONAL RPC: public.split_or_transfer_batch (DATA-01, DATA-03)
-- ------------------------------------------------------------------------------
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
SET search_path = public, pg_temp
AS $$
DECLARE
    v_lote_origen public.lotes%ROWTYPE;
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
    SELECT * INTO v_lote_origen 
    FROM public.lotes 
    WHERE id = p_lote_origen_id AND empresa_id = v_empresa_id 
    FOR UPDATE;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'Lote origen no encontrado o no pertenece a la empresa';
    END IF;

    -- Validar estanque destino y pertenencia a empresa
    SELECT * INTO v_estanque_destino 
    FROM public.estanques 
    WHERE id = p_estanque_destino_id AND empresa_id = v_empresa_id;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'Estanque destino no encontrado o no pertenece a la empresa';
    END IF;

    IF v_lote_origen.cantidad_actual_peces < p_peces_trasladar THEN
        RAISE EXCEPTION 'Cantidad de peces a trasladar (%) supera los existentes (%)', 
            p_peces_trasladar, v_lote_origen.cantidad_actual_peces;
    END IF;

    -- 2. Calcular biomasa y ratios de prorrateo
    v_biomasa_trasladar := ROUND((p_peces_trasladar * p_peso_promedio / 1000.0)::numeric, 2);
    v_ratio := CASE 
        WHEN v_lote_origen.cantidad_actual_peces > 0 
        THEN p_peces_trasladar::numeric / v_lote_origen.cantidad_actual_peces::numeric 
        ELSE 0.0 
    END;

    v_costo_alevinos := ROUND((COALESCE(v_lote_origen.costo_inicial_alevinos, 0.0) * v_ratio)::numeric, 2);
    v_costo_insumos := ROUND((COALESCE(v_lote_origen.costo_acumulado_insumos, 0.0) * v_ratio)::numeric, 2);
    v_costo_fijo := ROUND((COALESCE(v_lote_origen.costo_acumulado_fijo, 0.0) * v_ratio)::numeric, 2);
    v_costo_total := v_costo_alevinos + v_costo_insumos + v_costo_fijo;
    v_alimento_transferir := ROUND((COALESCE(v_lote_origen.alimento_acumulado_kg, 0.0) * v_ratio)::numeric, 2);

    IF p_tipo_operacion = 'TRASLADO_TOTAL' THEN
        -- Traslado completo: mover lote origen al nuevo estanque
        UPDATE public.lotes SET
            estanque_id = p_estanque_destino_id,
            peso_actual_gramos = p_peso_promedio,
            biomasa_actual_kg = v_biomasa_trasladar,
            updated_at = v_fecha
        WHERE id = v_lote_origen.id;
        v_nuevo_lote_id := v_lote_origen.id;
    ELSE
        -- DESDOBLE_PARCIAL: Reducir lote origen y crear lote hijo con proporción de alimento y costos
        UPDATE public.lotes SET
            cantidad_actual_peces = cantidad_actual_peces - p_peces_trasladar,
            biomasa_actual_kg = GREATEST(0.0, biomasa_actual_kg - v_biomasa_trasladar),
            costo_inicial_alevinos = GREATEST(0.0, costo_inicial_alevinos - v_costo_alevinos),
            costo_acumulado_insumos = GREATEST(0.0, costo_acumulado_insumos - v_costo_insumos),
            costo_acumulado_fijo = GREATEST(0.0, costo_acumulado_fijo - v_costo_fijo),
            alimento_acumulado_kg = GREATEST(0.0, alimento_acumulado_kg - v_alimento_transferir),
            updated_at = v_fecha
        WHERE id = v_lote_origen.id;

        INSERT INTO public.lotes (
            empresa_id, unidad_acuicola_id, estanque_id, lote_padre_id,
            codigo_lote, especie, fecha_siembra,
            cantidad_inicial_peces, cantidad_actual_peces,
            peso_inicial_gramos, peso_actual_gramos,
            biomasa_inicial_kg, biomasa_actual_kg,
            alimento_acumulado_kg, costo_inicial_alevinos,
            costo_acumulado_insumos, costo_acumulado_fijo,
            estado, rol_policultivo, creado_en
        ) VALUES (
            v_empresa_id, v_lote_origen.unidad_acuicola_id, p_estanque_destino_id, v_lote_origen.id,
            COALESCE(p_nuevo_codigo_lote, v_lote_origen.codigo_lote || '-B'),
            v_lote_origen.especie, v_fecha::date,
            p_peces_trasladar, p_peces_trasladar,
            p_peso_promedio, p_peso_promedio,
            v_biomasa_trasladar, v_biomasa_trasladar,
            v_alimento_transferir, v_costo_alevinos,
            v_costo_insumos, v_costo_fijo,
            'Activo', COALESCE(v_lote_origen.rol_policultivo, 'principal'),
            v_fecha
        ) RETURNING id INTO v_nuevo_lote_id;
    END IF;

    -- 3. Registrar auditoría formal en traslados_lotes
    INSERT INTO public.traslados_lotes (
        empresa_id, unidad_acuicola_id, lote_origen_id, lote_destino_id,
        estanque_origen_id, estanque_destino_id, tipo_operacion,
        peces_trasladados, peso_promedio_gramos, biomasa_trasladada_kg,
        proporcion_costos, costo_alevinos_transferido, costo_insumos_transferido,
        costo_fijo_transferido, costo_total_transferido, nuevo_codigo_lote,
        motivo, registrado_por, fecha_operacion, creado_en, created_at
    ) VALUES (
        v_empresa_id, v_lote_origen.unidad_acuicola_id, v_lote_origen.id, v_nuevo_lote_id,
        v_lote_origen.estanque_id, p_estanque_destino_id, p_tipo_operacion,
        p_peces_trasladar, p_peso_promedio, v_biomasa_trasladar,
        v_ratio, v_costo_alevinos, v_costo_insumos, v_costo_fijo, v_costo_total,
        p_nuevo_codigo_lote, p_motivo, p_registrado_por, v_fecha, v_fecha, v_fecha
    );

    -- 4. Re-sincronizar biomasa de ambos estanques basada en la suma real de sus lotes activos (soporte policultivo)
    PERFORM public.sync_pond_biomass(v_lote_origen.estanque_id);
    PERFORM public.sync_pond_biomass(p_estanque_destino_id);

    RETURN jsonb_build_object(
        'success', true,
        'tipo_operacion', p_tipo_operacion,
        'lote_origen_id', v_lote_origen.id,
        'nuevo_lote_id', v_nuevo_lote_id,
        'estanque_origen_id', v_lote_origen.estanque_id,
        'estanque_destino_id', p_estanque_destino_id,
        'biomasa_trasladada_kg', v_biomasa_trasladar,
        'peces_trasladados', p_peces_trasladar,
        'proporcion_costos', v_ratio
    );
END;
$$;

REVOKE ALL ON FUNCTION public.split_or_transfer_batch FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.split_or_transfer_batch TO authenticated, service_role;

COMMIT;
```

---

## 5. Verification Method

To independently verify this investigation and the resulting deliverables:

1. **Verify Schema Alignment:**
   - Inspect `c:\Users\Freddy\Desktop\Desarrollo de app\FishBit\supabase_schema_canonical_v10.sql:114-136` to verify exact column names for `public.lotes`.
   - Inspect `c:\Users\Freddy\Desktop\Desarrollo de app\FishBit\supabase\migrations\20260831_database_performance_and_rls_optimization.sql:519, 563, 607, 881, 998` to confirm multi-tenant leakage patterns using `unidad_acuicola_sigla` and `cliente_id`.
2. **Verify DDL Absoluteness:**
   - Execute grep search: `grep -rn "CREATE TABLE.*traslados_lotes" .` across the workspace; confirm that zero occurrences existed prior to this migration proposal.
3. **Verify Dart Models & Repositories:**
   - Inspect `lib/modules/ponds_batches/domain/models/transfer_record.dart:118` to confirm `'creado_en'` key serialization.
   - Inspect `lib/modules/ponds_batches/infrastructure/repositories/supabase_ponds_repository.dart:935, 1098` to verify the polyculture biomass overwriting bug.
   - Inspect `lib/modules/ponds_batches/presentation/providers/ponds_provider.dart:193-199` to verify missing `cantidadActualPeces` deduction in harvest sales.
4. **Syntax & Analysis Verification (Post-Worker Implementation):**
   - Run `flutter analyze` from workspace root to guarantee zero analysis errors or warnings.
