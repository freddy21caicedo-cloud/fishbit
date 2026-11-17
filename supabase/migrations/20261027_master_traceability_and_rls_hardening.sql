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
