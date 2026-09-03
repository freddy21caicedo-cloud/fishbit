-- ==============================================================================
-- Migration: 20260831_cost_security_and_immutability.sql
-- Module: Cost Security, Immutability & Multi-Tenant Audit Ledger
-- Target: Supabase PostgreSQL (FishBit Finance 2.0)
-- Conforme a las directrices de Supabase Postgres Best Practices & Farming Expert
-- Idempotency: Fully idempotent (safe to execute multiple times)
-- ==============================================================================

BEGIN;

-- ------------------------------------------------------------------------------
-- 1. Tabla de Auditoría Inmutable de Costos (Append-Only Audit Ledger)
-- ------------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.auditoria_costos (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    empresa_id UUID NOT NULL REFERENCES public.empresas(id) ON DELETE CASCADE,
    entidad_tipo TEXT NOT NULL CHECK (entidad_tipo IN ('Lote', 'Nomina', 'Jornal', 'Factura', 'Alimentacion', 'Venta', 'Capex', 'Energia')),
    entidad_id UUID NOT NULL,
    accion TEXT NOT NULL CHECK (accion IN ('INSERT', 'UPDATE', 'DELETE', 'CIERRE_CICLO', 'ANULACION')),
    valores_anteriores JSONB,
    valores_nuevos JSONB,
    usuario_id UUID,
    usuario_email TEXT,
    ip_address TEXT,
    creado_en TIMESTAMPTZ NOT NULL DEFAULT timezone('utc'::text, now())
);

-- Índices de consulta rápida para auditoría contable
CREATE INDEX IF NOT EXISTS idx_audit_costos_empresa_fecha ON public.auditoria_costos(empresa_id, creado_en DESC);
CREATE INDEX IF NOT EXISTS idx_audit_costos_entidad ON public.auditoria_costos(entidad_tipo, entidad_id);

-- RLS en Auditoría: Solo lectura para roles administrativos de la empresa, inserción vía triggers
ALTER TABLE public.auditoria_costos ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS auditoria_costos_tenant_select ON public.auditoria_costos;
CREATE POLICY auditoria_costos_tenant_select ON public.auditoria_costos
    FOR SELECT TO authenticated
    USING (
        ((empresa_id = public.get_auth_empresa_id()) AND (public.get_auth_user_role() = ANY (ARRAY['admin'::text, 'creador'::text, 'master'::text])))
        OR public.is_superadmin()
    );

DROP POLICY IF EXISTS auditoria_costos_block_user_mutation ON public.auditoria_costos;
-- Nadie puede modificar ni borrar registros de auditoría directamente
CREATE POLICY auditoria_costos_block_user_mutation ON public.auditoria_costos
    FOR UPDATE TO authenticated
    USING (false);


-- ------------------------------------------------------------------------------
-- 2. Función y Trigger: Bloqueo de Modificación en Lotes Cosechados (Ciclo Cerrado)
-- ------------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.fn_prevent_harvested_lot_mutation()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_estado TEXT;
BEGIN
    -- Verificar si el lote objetivo ya fue cosechado
    IF TG_TABLE_NAME = 'lotes' THEN
        IF OLD.estado IN ('Cosechado', 'Harvested') AND (NEW.costo_acumulado_insumos <> OLD.costo_acumulado_insumos OR NEW.costo_acumulado_fijo <> OLD.costo_acumulado_fijo) THEN
            RAISE EXCEPTION 'FishBit Security: No es posible alterar costos de un lote cosechado (ciclo cerrado). Lote ID: %', OLD.id;
        END IF;
    ELSIF TG_TABLE_NAME = 'alimentacion_diaria' THEN
        SELECT estado INTO v_estado FROM public.lotes WHERE id = COALESCE(NEW.lote_id, OLD.lote_id);
        IF v_estado IN ('Cosechado', 'Harvested') THEN
            RAISE EXCEPTION 'FishBit Security: No se puede registrar ni alterar alimentación en un lote ya cosechado. Lote ID: %', COALESCE(NEW.lote_id, OLD.lote_id);
        END IF;
    END IF;

    RETURN COALESCE(NEW, OLD);
END;
$$;

-- Triggers en Lotes y Alimentación
DROP TRIGGER IF EXISTS trg_prevent_harvested_lot_cost_change ON public.lotes;
CREATE TRIGGER trg_prevent_harvested_lot_cost_change
    BEFORE UPDATE ON public.lotes
    FOR EACH ROW
    EXECUTE FUNCTION public.fn_prevent_harvested_lot_mutation();

DROP TRIGGER IF EXISTS trg_prevent_harvested_lot_feed_insert ON public.alimentacion_diaria;
CREATE TRIGGER trg_prevent_harvested_lot_feed_insert
    BEFORE INSERT OR UPDATE OR DELETE ON public.alimentacion_diaria
    FOR EACH ROW
    EXECUTE FUNCTION public.fn_prevent_harvested_lot_mutation();


-- ------------------------------------------------------------------------------
-- 3. Función y Trigger: Inmutabilidad de Nómina Pagada
-- ------------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.fn_enforce_payroll_immutability()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
    -- Si la nómina ya fue liquidada y pagada, prohibir cambios en montos financieros
    IF OLD.estado = 'Pagado' THEN
        IF (NEW.salario_base <> OLD.salario_base OR 
            NEW.auxilio_transporte <> OLD.auxilio_transporte OR
            NEW.costo_total_empresa <> OLD.costo_total_empresa OR
            NEW.pension_patronal <> OLD.pension_patronal OR
            NEW.arl <> OLD.arl) THEN
            RAISE EXCEPTION 'FishBit Security: El registro de nómina ya está en estado Pagado y es inmutable. Cree una novedad o anulación formal.';
        END IF;
    END IF;

    RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_enforce_payroll_immutability ON public.registros_nomina;
CREATE TRIGGER trg_enforce_payroll_immutability
    BEFORE UPDATE ON public.registros_nomina
    FOR EACH ROW
    EXECUTE FUNCTION public.fn_enforce_payroll_immutability();


-- ------------------------------------------------------------------------------
-- 4. Función y Trigger: Registro Automático en Audit Ledger
-- ------------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.fn_record_cost_audit_log()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_empresa_id UUID;
    v_entidad_tipo TEXT;
    v_entidad_id UUID;
    v_accion TEXT;
    v_old JSONB := NULL;
    v_new JSONB := NULL;
    v_user_email TEXT;
BEGIN
    v_accion := TG_OP;

    IF TG_OP = 'DELETE' THEN
        v_empresa_id := OLD.empresa_id;
        v_entidad_id := OLD.id;
        v_old := to_jsonb(OLD);
    ELSE
        v_empresa_id := NEW.empresa_id;
        v_entidad_id := NEW.id;
        v_new := to_jsonb(NEW);
        IF TG_OP = 'UPDATE' THEN
            v_old := to_jsonb(OLD);
        END IF;
    END IF;

    CASE TG_TABLE_NAME
        WHEN 'registros_nomina' THEN v_entidad_tipo := 'Nomina';
        WHEN 'facturas' THEN v_entidad_tipo := 'Factura';
        WHEN 'ventas_lotes' THEN v_entidad_tipo := 'Venta';
        WHEN 'lotes' THEN v_entidad_tipo := 'Lote';
        WHEN 'inversiones_capex' THEN v_entidad_tipo := 'Capex';
        WHEN 'recibos_energia' THEN v_entidad_tipo := 'Energia';
        ELSE v_entidad_tipo := 'Lote';
    END CASE;

    -- Obtener email del usuario autenticado si existe
    BEGIN
        SELECT email INTO v_user_email FROM auth.users WHERE id = auth.uid();
    EXCEPTION WHEN OTHERS THEN
        v_user_email := NULL;
    END;

    INSERT INTO public.auditoria_costos (
        empresa_id,
        entidad_tipo,
        entidad_id,
        accion,
        valores_anteriores,
        valores_nuevos,
        usuario_id,
        usuario_email,
        creado_en
    ) VALUES (
        v_empresa_id,
        v_entidad_tipo,
        v_entidad_id,
        v_accion,
        v_old,
        v_new,
        auth.uid(),
        v_user_email,
        timezone('utc'::text, now())
    );

    RETURN COALESCE(NEW, OLD);
END;
$$;

-- Triggers de auditoría en tablas financieras críticas
DROP TRIGGER IF EXISTS trg_audit_nomina ON public.registros_nomina;
CREATE TRIGGER trg_audit_nomina
    AFTER INSERT OR UPDATE OR DELETE ON public.registros_nomina
    FOR EACH ROW
    EXECUTE FUNCTION public.fn_record_cost_audit_log();

DROP TRIGGER IF EXISTS trg_audit_facturas ON public.facturas;
CREATE TRIGGER trg_audit_facturas
    AFTER INSERT OR UPDATE OR DELETE ON public.facturas
    FOR EACH ROW
    EXECUTE FUNCTION public.fn_record_cost_audit_log();

DROP TRIGGER IF EXISTS trg_audit_ventas ON public.ventas_lotes;
CREATE TRIGGER trg_audit_ventas
    AFTER INSERT OR UPDATE OR DELETE ON public.ventas_lotes
    FOR EACH ROW
    EXECUTE FUNCTION public.fn_record_cost_audit_log();

DROP TRIGGER IF EXISTS trg_audit_capex ON public.inversiones_capex;
CREATE TRIGGER trg_audit_capex
    AFTER INSERT OR UPDATE OR DELETE ON public.inversiones_capex
    FOR EACH ROW
    EXECUTE FUNCTION public.fn_record_cost_audit_log();

DROP TRIGGER IF EXISTS trg_audit_energia ON public.recibos_energia;
CREATE TRIGGER trg_audit_energia
    AFTER INSERT OR UPDATE OR DELETE ON public.recibos_energia
    FOR EACH ROW
    EXECUTE FUNCTION public.fn_record_cost_audit_log();

COMMIT;
