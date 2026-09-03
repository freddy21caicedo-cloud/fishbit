-- ==============================================================================
-- Migration: 20260831_database_performance_and_rls_optimization.sql
-- Module: High-Performance Composite Indexes, RLS InitPlan Optimization & Tenant Security
-- Target: Supabase PostgreSQL (Project oakovawlwjpnoydpwtam)
-- Idempotency: Fully idempotent (safe to execute multiple times)
-- ==============================================================================

BEGIN;

-- ------------------------------------------------------------------------------
-- 1. Optimización de Funciones Helper & Expresiones de Búsqueda RLS
-- ------------------------------------------------------------------------------

-- Índice funcional para búsqueda ultrarrápida de email en miembros_equipo
CREATE INDEX IF NOT EXISTS idx_miembros_lower_email 
  ON public.miembros_equipo (LOWER(email));

-- Re-declarar funciones auxiliares con STABLE y search_path explícito
CREATE OR REPLACE FUNCTION public.get_auth_empresa_id()
RETURNS UUID
LANGUAGE sql
STABLE SECURITY DEFINER
SET search_path TO 'public'
AS $$
  SELECT COALESCE(
    (SELECT empresa_id FROM public.profiles WHERE id = (SELECT auth.uid()) LIMIT 1),
    (SELECT empresa_id FROM public.miembros_equipo WHERE LOWER(email) = LOWER((SELECT auth.jwt() ->> 'email')) LIMIT 1),
    (SELECT u.empresa_id FROM public.user_units uu JOIN public.units u ON u.id = uu.unit_id WHERE uu.user_id = (SELECT auth.uid()) LIMIT 1)
  );
$$;

CREATE OR REPLACE FUNCTION public.get_auth_user_role()
RETURNS TEXT
LANGUAGE sql
STABLE SECURITY DEFINER
SET search_path TO 'public'
AS $$
  SELECT LOWER(COALESCE(
    (SELECT role FROM public.profiles WHERE id = (SELECT auth.uid()) LIMIT 1),
    (SELECT role FROM public.miembros_equipo WHERE LOWER(email) = LOWER((SELECT auth.jwt() ->> 'email')) LIMIT 1),
    'operario'
  ));
$$;

CREATE OR REPLACE FUNCTION public.is_superadmin()
RETURNS BOOLEAN
LANGUAGE sql
STABLE SECURITY DEFINER
SET search_path TO 'public'
AS $$
  SELECT COALESCE(
    (SELECT is_superadmin OR LOWER(role) IN ('creador', 'master', 'billingadmin') OR LOWER(email) = 'especialistaacuicola@gmail.com' 
     FROM public.profiles WHERE id = (SELECT auth.uid()) LIMIT 1),
    false
  );
$$;

-- ------------------------------------------------------------------------------
-- 2. Creación de Índices Compuestos Estratégicos y Claves Foráneas
-- ------------------------------------------------------------------------------

-- A. Parámetros Calidad de Agua
CREATE INDEX IF NOT EXISTS idx_calidad_agua_empresa_estanque_fecha 
  ON public.parametros_calidad_agua (empresa_id, estanque_id, fecha DESC);
CREATE INDEX IF NOT EXISTS idx_calidad_agua_empresa_unidad_fecha 
  ON public.parametros_calidad_agua (empresa_id, unidad_acuicola_id, fecha DESC);
CREATE INDEX IF NOT EXISTS idx_calidad_agua_unidad_id 
  ON public.parametros_calidad_agua (unidad_acuicola_id);

-- B. Alimentación Diaria
CREATE INDEX IF NOT EXISTS idx_alimentacion_empresa_lote_fecha 
  ON public.alimentacion_diaria (empresa_id, lote_id, fecha DESC);
CREATE INDEX IF NOT EXISTS idx_alimentacion_empresa_estanque_fecha 
  ON public.alimentacion_diaria (empresa_id, estanque_id, fecha DESC);
CREATE INDEX IF NOT EXISTS idx_alimentacion_lote_id 
  ON public.alimentacion_diaria (lote_id);
CREATE INDEX IF NOT EXISTS idx_alimentacion_unidad_acuicola_id 
  ON public.alimentacion_diaria (unidad_acuicola_id);
CREATE INDEX IF NOT EXISTS idx_alimentacion_insumo_id 
  ON public.alimentacion_diaria (insumo_id);

-- C. Lotes (Centros de Costos)
CREATE INDEX IF NOT EXISTS idx_lotes_empresa_id 
  ON public.lotes (empresa_id);
CREATE INDEX IF NOT EXISTS idx_lotes_empresa_estado 
  ON public.lotes (empresa_id, estado);
CREATE INDEX IF NOT EXISTS idx_lotes_empresa_estanque 
  ON public.lotes (empresa_id, estanque_id);
CREATE INDEX IF NOT EXISTS idx_lotes_empresa_fecha 
  ON public.lotes (empresa_id, creado_en DESC);
CREATE INDEX IF NOT EXISTS idx_lotes_unit_id 
  ON public.lotes (unit_id);
CREATE INDEX IF NOT EXISTS idx_lotes_unidad_sigla 
  ON public.lotes (unidad_acuicola_sigla);
CREATE INDEX IF NOT EXISTS idx_lotes_padre_id 
  ON public.lotes (lote_padre_id);

-- D. Biometrías
CREATE INDEX IF NOT EXISTS idx_biometrias_empresa_lote_date 
  ON public.biometrias (empresa_id, lote_id, date DESC);
CREATE INDEX IF NOT EXISTS idx_biometrias_empresa_lote_fecha 
  ON public.biometrias (empresa_id, lote_id, fecha DESC);
CREATE INDEX IF NOT EXISTS idx_biometrias_unidad_acuicola_id 
  ON public.biometrias (unidad_acuicola_id);

-- E. Mortalidad
CREATE INDEX IF NOT EXISTS idx_mortalidad_empresa_lote_date 
  ON public.mortalidad (empresa_id, lote_id, date DESC);
CREATE INDEX IF NOT EXISTS idx_mortalidad_empresa_estanque_date 
  ON public.mortalidad (empresa_id, estanque_id, date DESC);
CREATE INDEX IF NOT EXISTS idx_mortalidad_unidad_acuicola_id 
  ON public.mortalidad (unidad_acuicola_id);
CREATE INDEX IF NOT EXISTS idx_mortalidad_siembra_id 
  ON public.mortalidad (siembra_id);

-- F. Traslados de Lotes
CREATE INDEX IF NOT EXISTS idx_traslados_empresa_lote_origen 
  ON public.traslados_lotes (empresa_id, lote_origen_id, fecha_operacion DESC);
CREATE INDEX IF NOT EXISTS idx_traslados_empresa_lote_destino 
  ON public.traslados_lotes (empresa_id, lote_destino_id, fecha_operacion DESC);
CREATE INDEX IF NOT EXISTS idx_traslados_lote_destino_id 
  ON public.traslados_lotes (lote_destino_id);
CREATE INDEX IF NOT EXISTS idx_traslados_unidad_acuicola_id 
  ON public.traslados_lotes (unidad_acuicola_id);
CREATE INDEX IF NOT EXISTS idx_traslados_estanque_origen 
  ON public.traslados_lotes (estanque_origen_id);
CREATE INDEX IF NOT EXISTS idx_traslados_estanque_destino 
  ON public.traslados_lotes (estanque_destino_id);

-- G. Ventas, Facturas y Estanques
CREATE INDEX IF NOT EXISTS idx_ventas_lotes_cliente_id 
  ON public.ventas_lotes (cliente_id);
CREATE INDEX IF NOT EXISTS idx_ventas_lotes_lote_id 
  ON public.ventas_lotes (lote_id);
CREATE INDEX IF NOT EXISTS idx_ventas_lotes_empresa_id
  ON public.ventas_lotes (empresa_id);
CREATE INDEX IF NOT EXISTS idx_facturas_unidad_acuicola_id 
  ON public.facturas (unidad_acuicola_id);
CREATE INDEX IF NOT EXISTS idx_facturas_cliente_id
  ON public.facturas (cliente_id);
CREATE INDEX IF NOT EXISTS idx_facturas_empresa_fecha 
  ON public.facturas (empresa_id, fecha_expedicion DESC);
CREATE INDEX IF NOT EXISTS idx_estanques_empresa_unidad 
  ON public.estanques (empresa_id, unidad_acuicola_id);
CREATE INDEX IF NOT EXISTS idx_estanques_cliente_id
  ON public.estanques (cliente_id);

-- H. Índices para Foreign Keys Adicionales
CREATE INDEX IF NOT EXISTS idx_aireacion_logs_unit_id ON public.aireacion_logs (unit_id);
CREATE INDEX IF NOT EXISTS idx_calidad_agua_unit_id ON public.calidad_agua (unit_id);
CREATE INDEX IF NOT EXISTS idx_calidad_agua_empresa_id ON public.calidad_agua (empresa_id);
CREATE INDEX IF NOT EXISTS idx_equipos_cliente_id ON public.equipos (cliente_id);
CREATE INDEX IF NOT EXISTS idx_equipos_estanque_asignado_id ON public.equipos (estanque_asignado_id);
CREATE INDEX IF NOT EXISTS idx_estanque_equipos_inventory_id ON public.estanque_equipos (inventory_id);
CREATE INDEX IF NOT EXISTS idx_historial_gastos_invoice_id ON public.historial_gastos (invoice_id);
CREATE INDEX IF NOT EXISTS idx_inventario_insumos_cliente_id ON public.inventario_insumos (cliente_id);
CREATE INDEX IF NOT EXISTS idx_invoice_items_invoice_id ON public.invoice_items (invoice_id);
CREATE INDEX IF NOT EXISTS idx_invoice_items_unit_id ON public.invoice_items (unit_id);
CREATE INDEX IF NOT EXISTS idx_invoices_provider_id ON public.invoices (provider_id);
CREATE INDEX IF NOT EXISTS idx_jornales_siembra_id ON public.jornales (siembra_id);
CREATE INDEX IF NOT EXISTS idx_jornales_unit_id ON public.jornales (unit_id);
CREATE INDEX IF NOT EXISTS idx_mantenimiento_logs_unit_id ON public.mantenimiento_logs (unit_id);
CREATE INDEX IF NOT EXISTS idx_mortality_empresa_id ON public.mortality (empresa_id);
CREATE INDEX IF NOT EXISTS idx_mortality_unit_id ON public.mortality (unit_id);
CREATE INDEX IF NOT EXISTS idx_nomina_siembra_id ON public.nomina (siembra_id);
CREATE INDEX IF NOT EXISTS idx_nomina_unit_id ON public.nomina (unit_id);
CREATE INDEX IF NOT EXISTS idx_payment_reports_unit_id ON public.payment_reports (unit_id);
CREATE INDEX IF NOT EXISTS idx_payment_reports_user_id ON public.payment_reports (user_id);
CREATE INDEX IF NOT EXISTS idx_pond_species_unit_id ON public.pond_species (unit_id);
CREATE INDEX IF NOT EXISTS idx_proveedores_empresa_id ON public.proveedores (empresa_id);
CREATE INDEX IF NOT EXISTS idx_providers_empresa_id ON public.providers (empresa_id);
CREATE INDEX IF NOT EXISTS idx_providers_unit_id ON public.providers (unit_id);
CREATE INDEX IF NOT EXISTS idx_registro_actividades_estanque_id ON public.registro_actividades (estanque_id);
CREATE INDEX IF NOT EXISTS idx_siembra_details_siembra_id ON public.siembra_details (siembra_id);
CREATE INDEX IF NOT EXISTS idx_siembras_parent_siembra_id ON public.siembras (parent_siembra_id);
CREATE INDEX IF NOT EXISTS idx_siembras_unit_id ON public.siembras (unit_id);
CREATE INDEX IF NOT EXISTS idx_subscriptions_unit_id ON public.subscriptions (unit_id);
CREATE INDEX IF NOT EXISTS idx_support_tickets_user_id ON public.support_tickets (user_id);
CREATE INDEX IF NOT EXISTS idx_transfers_siembra_destino_id ON public.transfers (siembra_destino_id);
CREATE INDEX IF NOT EXISTS idx_transfers_siembra_origen_id ON public.transfers (siembra_origen_id);
CREATE INDEX IF NOT EXISTS idx_transfers_unit_id ON public.transfers (unit_id);
CREATE INDEX IF NOT EXISTS idx_tratamiento_details_inventory_id ON public.tratamiento_details (inventory_id);
CREATE INDEX IF NOT EXISTS idx_tratamiento_details_tratamiento_id ON public.tratamiento_details (tratamiento_id);
CREATE INDEX IF NOT EXISTS idx_tratamiento_details_unit_id ON public.tratamiento_details (unit_id);
CREATE INDEX IF NOT EXISTS idx_tratamientos_siembra_id ON public.tratamientos (siembra_id);
CREATE INDEX IF NOT EXISTS idx_tratamientos_unit_id ON public.tratamientos (unit_id);
CREATE INDEX IF NOT EXISTS idx_user_units_unit_id ON public.user_units (unit_id);
CREATE INDEX IF NOT EXISTS idx_ventas_empresa_id ON public.ventas (empresa_id);
CREATE INDEX IF NOT EXISTS idx_ventas_unit_id ON public.ventas (unit_id);
CREATE INDEX IF NOT EXISTS idx_water_quality_empresa_id ON public.water_quality (empresa_id);
CREATE INDEX IF NOT EXISTS idx_water_quality_unit_id ON public.water_quality (unit_id);

-- ------------------------------------------------------------------------------
-- 3. Refactorización de Políticas RLS (InitPlan Caching & Split Modify)
-- ------------------------------------------------------------------------------

-- 1. PARAMETROS CALIDAD AGUA
ALTER TABLE public.parametros_calidad_agua ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS parametros_calidad_agua_tenant_select ON public.parametros_calidad_agua;
DROP POLICY IF EXISTS parametros_calidad_agua_tenant_modify ON public.parametros_calidad_agua;
DROP POLICY IF EXISTS parametros_calidad_agua_tenant_insert ON public.parametros_calidad_agua;
DROP POLICY IF EXISTS parametros_calidad_agua_tenant_update ON public.parametros_calidad_agua;
DROP POLICY IF EXISTS parametros_calidad_agua_tenant_delete ON public.parametros_calidad_agua;

CREATE POLICY parametros_calidad_agua_tenant_select ON public.parametros_calidad_agua
  FOR SELECT TO authenticated
  USING (empresa_id = (SELECT public.get_auth_empresa_id()) OR (SELECT public.is_superadmin()));

CREATE POLICY parametros_calidad_agua_tenant_insert ON public.parametros_calidad_agua
  FOR INSERT TO authenticated
  WITH CHECK (
    (empresa_id = (SELECT public.get_auth_empresa_id()) AND (SELECT public.get_auth_user_role()) = ANY (ARRAY['admin', 'creador', 'master', 'tecnico', 'operario', 'sanitarydirector'])) 
    OR (SELECT public.is_superadmin())
  );

CREATE POLICY parametros_calidad_agua_tenant_update ON public.parametros_calidad_agua
  FOR UPDATE TO authenticated
  USING (
    (empresa_id = (SELECT public.get_auth_empresa_id()) AND (SELECT public.get_auth_user_role()) = ANY (ARRAY['admin', 'creador', 'master', 'tecnico', 'operario', 'sanitarydirector'])) 
    OR (SELECT public.is_superadmin())
  )
  WITH CHECK (
    (empresa_id = (SELECT public.get_auth_empresa_id()) AND (SELECT public.get_auth_user_role()) = ANY (ARRAY['admin', 'creador', 'master', 'tecnico', 'operario', 'sanitarydirector'])) 
    OR (SELECT public.is_superadmin())
  );

CREATE POLICY parametros_calidad_agua_tenant_delete ON public.parametros_calidad_agua
  FOR DELETE TO authenticated
  USING (
    (empresa_id = (SELECT public.get_auth_empresa_id()) AND (SELECT public.get_auth_user_role()) = ANY (ARRAY['admin', 'creador', 'master'])) 
    OR (SELECT public.is_superadmin())
  );

-- 2. ALIMENTACION DIARIA
ALTER TABLE public.alimentacion_diaria ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS alimentacion_diaria_tenant_select ON public.alimentacion_diaria;
DROP POLICY IF EXISTS alimentacion_diaria_tenant_modify ON public.alimentacion_diaria;
DROP POLICY IF EXISTS alimentacion_diaria_tenant_insert ON public.alimentacion_diaria;
DROP POLICY IF EXISTS alimentacion_diaria_tenant_update ON public.alimentacion_diaria;
DROP POLICY IF EXISTS alimentacion_diaria_tenant_delete ON public.alimentacion_diaria;

CREATE POLICY alimentacion_diaria_tenant_select ON public.alimentacion_diaria
  FOR SELECT TO authenticated
  USING (empresa_id = (SELECT public.get_auth_empresa_id()) OR (SELECT public.is_superadmin()));

CREATE POLICY alimentacion_diaria_tenant_insert ON public.alimentacion_diaria
  FOR INSERT TO authenticated
  WITH CHECK (
    (empresa_id = (SELECT public.get_auth_empresa_id()) AND (SELECT public.get_auth_user_role()) = ANY (ARRAY['admin', 'creador', 'master', 'tecnico', 'operario'])) 
    OR (SELECT public.is_superadmin())
  );

CREATE POLICY alimentacion_diaria_tenant_update ON public.alimentacion_diaria
  FOR UPDATE TO authenticated
  USING (
    (empresa_id = (SELECT public.get_auth_empresa_id()) AND (SELECT public.get_auth_user_role()) = ANY (ARRAY['admin', 'creador', 'master', 'tecnico', 'operario'])) 
    OR (SELECT public.is_superadmin())
  )
  WITH CHECK (
    (empresa_id = (SELECT public.get_auth_empresa_id()) AND (SELECT public.get_auth_user_role()) = ANY (ARRAY['admin', 'creador', 'master', 'tecnico', 'operario'])) 
    OR (SELECT public.is_superadmin())
  );

CREATE POLICY alimentacion_diaria_tenant_delete ON public.alimentacion_diaria
  FOR DELETE TO authenticated
  USING (
    (empresa_id = (SELECT public.get_auth_empresa_id()) AND (SELECT public.get_auth_user_role()) = ANY (ARRAY['admin', 'creador', 'master'])) 
    OR (SELECT public.is_superadmin())
  );

-- 3. BIOMETRIAS
ALTER TABLE public.biometrias ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS biometrias_tenant_select ON public.biometrias;
DROP POLICY IF EXISTS biometrias_tenant_modify ON public.biometrias;
DROP POLICY IF EXISTS biometrias_tenant_insert ON public.biometrias;
DROP POLICY IF EXISTS biometrias_tenant_update ON public.biometrias;
DROP POLICY IF EXISTS biometrias_tenant_delete ON public.biometrias;

CREATE POLICY biometrias_tenant_select ON public.biometrias
  FOR SELECT TO authenticated
  USING (empresa_id = (SELECT public.get_auth_empresa_id()) OR (SELECT public.is_superadmin()));

CREATE POLICY biometrias_tenant_insert ON public.biometrias
  FOR INSERT TO authenticated
  WITH CHECK (
    (empresa_id = (SELECT public.get_auth_empresa_id()) AND (SELECT public.get_auth_user_role()) = ANY (ARRAY['admin', 'creador', 'master', 'tecnico', 'operario'])) 
    OR (SELECT public.is_superadmin())
  );

CREATE POLICY biometrias_tenant_update ON public.biometrias
  FOR UPDATE TO authenticated
  USING (
    (empresa_id = (SELECT public.get_auth_empresa_id()) AND (SELECT public.get_auth_user_role()) = ANY (ARRAY['admin', 'creador', 'master', 'tecnico', 'operario'])) 
    OR (SELECT public.is_superadmin())
  )
  WITH CHECK (
    (empresa_id = (SELECT public.get_auth_empresa_id()) AND (SELECT public.get_auth_user_role()) = ANY (ARRAY['admin', 'creador', 'master', 'tecnico', 'operario'])) 
    OR (SELECT public.is_superadmin())
  );

CREATE POLICY biometrias_tenant_delete ON public.biometrias
  FOR DELETE TO authenticated
  USING (
    (empresa_id = (SELECT public.get_auth_empresa_id()) AND (SELECT public.get_auth_user_role()) = ANY (ARRAY['admin', 'creador', 'master'])) 
    OR (SELECT public.is_superadmin())
  );

-- 4. MORTALIDAD
ALTER TABLE public.mortalidad ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS mortalidad_tenant_select ON public.mortalidad;
DROP POLICY IF EXISTS mortalidad_tenant_modify ON public.mortalidad;
DROP POLICY IF EXISTS mortalidad_tenant_insert ON public.mortalidad;
DROP POLICY IF EXISTS mortalidad_tenant_update ON public.mortalidad;
DROP POLICY IF EXISTS mortalidad_tenant_delete ON public.mortalidad;

CREATE POLICY mortalidad_tenant_select ON public.mortalidad
  FOR SELECT TO authenticated
  USING (empresa_id = (SELECT public.get_auth_empresa_id()) OR (SELECT public.is_superadmin()));

CREATE POLICY mortalidad_tenant_insert ON public.mortalidad
  FOR INSERT TO authenticated
  WITH CHECK (
    (empresa_id = (SELECT public.get_auth_empresa_id()) AND (SELECT public.get_auth_user_role()) = ANY (ARRAY['admin', 'creador', 'master', 'tecnico', 'operario'])) 
    OR (SELECT public.is_superadmin())
  );

CREATE POLICY mortalidad_tenant_update ON public.mortalidad
  FOR UPDATE TO authenticated
  USING (
    (empresa_id = (SELECT public.get_auth_empresa_id()) AND (SELECT public.get_auth_user_role()) = ANY (ARRAY['admin', 'creador', 'master', 'tecnico', 'operario'])) 
    OR (SELECT public.is_superadmin())
  )
  WITH CHECK (
    (empresa_id = (SELECT public.get_auth_empresa_id()) AND (SELECT public.get_auth_user_role()) = ANY (ARRAY['admin', 'creador', 'master', 'tecnico', 'operario'])) 
    OR (SELECT public.is_superadmin())
  );

CREATE POLICY mortalidad_tenant_delete ON public.mortalidad
  FOR DELETE TO authenticated
  USING (
    (empresa_id = (SELECT public.get_auth_empresa_id()) AND (SELECT public.get_auth_user_role()) = ANY (ARRAY['admin', 'creador', 'master'])) 
    OR (SELECT public.is_superadmin())
  );

-- 5. LOTES
ALTER TABLE public.lotes ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS lotes_tenant_select ON public.lotes;
DROP POLICY IF EXISTS lotes_tenant_modify ON public.lotes;
DROP POLICY IF EXISTS lotes_tenant_insert ON public.lotes;
DROP POLICY IF EXISTS lotes_tenant_update ON public.lotes;
DROP POLICY IF EXISTS lotes_tenant_delete ON public.lotes;

CREATE POLICY lotes_tenant_select ON public.lotes
  FOR SELECT TO authenticated
  USING (empresa_id = (SELECT public.get_auth_empresa_id()) OR (SELECT public.is_superadmin()));

CREATE POLICY lotes_tenant_insert ON public.lotes
  FOR INSERT TO authenticated
  WITH CHECK (
    (empresa_id = (SELECT public.get_auth_empresa_id()) AND (SELECT public.get_auth_user_role()) = ANY (ARRAY['admin', 'creador', 'master', 'tecnico', 'sanitarydirector'])) 
    OR (SELECT public.is_superadmin())
  );

CREATE POLICY lotes_tenant_update ON public.lotes
  FOR UPDATE TO authenticated
  USING (
    (empresa_id = (SELECT public.get_auth_empresa_id()) AND (SELECT public.get_auth_user_role()) = ANY (ARRAY['admin', 'creador', 'master', 'tecnico', 'sanitarydirector'])) 
    OR (SELECT public.is_superadmin())
  )
  WITH CHECK (
    (empresa_id = (SELECT public.get_auth_empresa_id()) AND (SELECT public.get_auth_user_role()) = ANY (ARRAY['admin', 'creador', 'master', 'tecnico', 'sanitarydirector'])) 
    OR (SELECT public.is_superadmin())
  );

CREATE POLICY lotes_tenant_delete ON public.lotes
  FOR DELETE TO authenticated
  USING (
    (empresa_id = (SELECT public.get_auth_empresa_id()) AND (SELECT public.get_auth_user_role()) = ANY (ARRAY['admin', 'creador', 'master'])) 
    OR (SELECT public.is_superadmin())
  );

-- 6. TRASLADOS DE LOTES (CORRECCIÓN DE VULNERABILIDAD RLS)
ALTER TABLE public.traslados_lotes ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "Permitir acceso por empresa" ON public.traslados_lotes;
DROP POLICY IF EXISTS traslados_lotes_tenant_select ON public.traslados_lotes;
DROP POLICY IF EXISTS traslados_lotes_tenant_insert ON public.traslados_lotes;
DROP POLICY IF EXISTS traslados_lotes_tenant_update ON public.traslados_lotes;
DROP POLICY IF EXISTS traslados_lotes_tenant_delete ON public.traslados_lotes;

CREATE POLICY traslados_lotes_tenant_select ON public.traslados_lotes
  FOR SELECT TO authenticated
  USING (empresa_id = (SELECT public.get_auth_empresa_id()) OR (SELECT public.is_superadmin()));

CREATE POLICY traslados_lotes_tenant_insert ON public.traslados_lotes
  FOR INSERT TO authenticated
  WITH CHECK (
    (empresa_id = (SELECT public.get_auth_empresa_id()) AND (SELECT public.get_auth_user_role()) = ANY (ARRAY['admin', 'creador', 'master', 'tecnico'])) 
    OR (SELECT public.is_superadmin())
  );

CREATE POLICY traslados_lotes_tenant_update ON public.traslados_lotes
  FOR UPDATE TO authenticated
  USING (
    (empresa_id = (SELECT public.get_auth_empresa_id()) AND (SELECT public.get_auth_user_role()) = ANY (ARRAY['admin', 'creador', 'master', 'tecnico'])) 
    OR (SELECT public.is_superadmin())
  )
  WITH CHECK (
    (empresa_id = (SELECT public.get_auth_empresa_id()) AND (SELECT public.get_auth_user_role()) = ANY (ARRAY['admin', 'creador', 'master', 'tecnico'])) 
    OR (SELECT public.is_superadmin())
  );

CREATE POLICY traslados_lotes_tenant_delete ON public.traslados_lotes
  FOR DELETE TO authenticated
  USING (
    (empresa_id = (SELECT public.get_auth_empresa_id()) AND (SELECT public.get_auth_user_role()) = ANY (ARRAY['admin', 'creador', 'master'])) 
    OR (SELECT public.is_superadmin())
  );

-- 7. ENDURECIMIENTO Y SPLIT RLS EN PROFILES & USER_UNITS (INITPLAN FIX)
ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS profiles_tenant_isolation_select ON public.profiles;
DROP POLICY IF EXISTS profiles_tenant_isolation_modify ON public.profiles;
DROP POLICY IF EXISTS profiles_tenant_isolation_insert ON public.profiles;
DROP POLICY IF EXISTS profiles_tenant_isolation_update ON public.profiles;
DROP POLICY IF EXISTS profiles_tenant_isolation_delete ON public.profiles;

CREATE POLICY profiles_tenant_isolation_select ON public.profiles
  FOR SELECT TO authenticated
  USING (
    id = (SELECT auth.uid()) 
    OR empresa_id = (SELECT public.get_auth_empresa_id()) 
    OR (SELECT public.is_superadmin())
  );

CREATE POLICY profiles_tenant_isolation_insert ON public.profiles
  FOR INSERT TO authenticated
  WITH CHECK (
    id = (SELECT auth.uid()) 
    OR (empresa_id = (SELECT public.get_auth_empresa_id()) AND (SELECT public.get_auth_user_role()) = ANY (ARRAY['admin', 'creador', 'master'])) 
    OR (SELECT public.is_superadmin())
  );

CREATE POLICY profiles_tenant_isolation_update ON public.profiles
  FOR UPDATE TO authenticated
  USING (
    id = (SELECT auth.uid()) 
    OR (empresa_id = (SELECT public.get_auth_empresa_id()) AND (SELECT public.get_auth_user_role()) = ANY (ARRAY['admin', 'creador', 'master'])) 
    OR (SELECT public.is_superadmin())
  )
  WITH CHECK (
    id = (SELECT auth.uid()) 
    OR (empresa_id = (SELECT public.get_auth_empresa_id()) AND (SELECT public.get_auth_user_role()) = ANY (ARRAY['admin', 'creador', 'master'])) 
    OR (SELECT public.is_superadmin())
  );

CREATE POLICY profiles_tenant_isolation_delete ON public.profiles
  FOR DELETE TO authenticated
  USING (
    (empresa_id = (SELECT public.get_auth_empresa_id()) AND (SELECT public.get_auth_user_role()) = ANY (ARRAY['admin', 'creador', 'master'])) 
    OR (SELECT public.is_superadmin())
  );

ALTER TABLE public.user_units ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS user_units_tenant_select ON public.user_units;
DROP POLICY IF EXISTS user_units_tenant_modify ON public.user_units;
DROP POLICY IF EXISTS user_units_tenant_insert ON public.user_units;
DROP POLICY IF EXISTS user_units_tenant_update ON public.user_units;
DROP POLICY IF EXISTS user_units_tenant_delete ON public.user_units;

CREATE POLICY user_units_tenant_select ON public.user_units
  FOR SELECT TO authenticated
  USING (
    user_id = (SELECT auth.uid()) 
    OR unit_id IN (SELECT u.id FROM public.units u WHERE u.empresa_id = (SELECT public.get_auth_empresa_id())) 
    OR (SELECT public.is_superadmin())
  );

CREATE POLICY user_units_tenant_insert ON public.user_units
  FOR INSERT TO authenticated
  WITH CHECK (
    (unit_id IN (SELECT u.id FROM public.units u WHERE u.empresa_id = (SELECT public.get_auth_empresa_id())) 
     AND (SELECT public.get_auth_user_role()) = ANY (ARRAY['admin', 'creador', 'master'])) 
    OR (SELECT public.is_superadmin())
  );

CREATE POLICY user_units_tenant_update ON public.user_units
  FOR UPDATE TO authenticated
  USING (
    (unit_id IN (SELECT u.id FROM public.units u WHERE u.empresa_id = (SELECT public.get_auth_empresa_id())) 
     AND (SELECT public.get_auth_user_role()) = ANY (ARRAY['admin', 'creador', 'master'])) 
    OR (SELECT public.is_superadmin())
  )
  WITH CHECK (
    (unit_id IN (SELECT u.id FROM public.units u WHERE u.empresa_id = (SELECT public.get_auth_empresa_id())) 
     AND (SELECT public.get_auth_user_role()) = ANY (ARRAY['admin', 'creador', 'master'])) 
    OR (SELECT public.is_superadmin())
  );

CREATE POLICY user_units_tenant_delete ON public.user_units
  FOR DELETE TO authenticated
  USING (
    (unit_id IN (SELECT u.id FROM public.units u WHERE u.empresa_id = (SELECT public.get_auth_empresa_id())) 
     AND (SELECT public.get_auth_user_role()) = ANY (ARRAY['admin', 'creador', 'master'])) 
    OR (SELECT public.is_superadmin())
  );

-- 8. ENDURECIMIENTO DE TABLAS SIN POLÍTICAS O CON POLÍTICAS DUPLICADAS
-- A. compras_mat_biologico
ALTER TABLE public.compras_mat_biologico ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS compras_mat_biologico_tenant_select ON public.compras_mat_biologico;
DROP POLICY IF EXISTS compras_mat_biologico_tenant_modify ON public.compras_mat_biologico;
DROP POLICY IF EXISTS compras_mat_biologico_tenant_insert ON public.compras_mat_biologico;
DROP POLICY IF EXISTS compras_mat_biologico_tenant_update ON public.compras_mat_biologico;
DROP POLICY IF EXISTS compras_mat_biologico_tenant_delete ON public.compras_mat_biologico;

CREATE POLICY compras_mat_biologico_tenant_select ON public.compras_mat_biologico
  FOR SELECT TO authenticated
  USING (
    unidad_acuicola_sigla IN (SELECT u.sigla FROM public.units u WHERE u.empresa_id = (SELECT public.get_auth_empresa_id())) 
    OR (SELECT public.is_superadmin())
  );

CREATE POLICY compras_mat_biologico_tenant_insert ON public.compras_mat_biologico
  FOR INSERT TO authenticated
  WITH CHECK (
    (unidad_acuicola_sigla IN (SELECT u.sigla FROM public.units u WHERE u.empresa_id = (SELECT public.get_auth_empresa_id())) 
     AND (SELECT public.get_auth_user_role()) = ANY (ARRAY['admin', 'creador', 'master', 'tecnico'])) 
    OR (SELECT public.is_superadmin())
  );

CREATE POLICY compras_mat_biologico_tenant_update ON public.compras_mat_biologico
  FOR UPDATE TO authenticated
  USING (
    (unidad_acuicola_sigla IN (SELECT u.sigla FROM public.units u WHERE u.empresa_id = (SELECT public.get_auth_empresa_id())) 
     AND (SELECT public.get_auth_user_role()) = ANY (ARRAY['admin', 'creador', 'master', 'tecnico'])) 
    OR (SELECT public.is_superadmin())
  )
  WITH CHECK (
    (unidad_acuicola_sigla IN (SELECT u.sigla FROM public.units u WHERE u.empresa_id = (SELECT public.get_auth_empresa_id())) 
     AND (SELECT public.get_auth_user_role()) = ANY (ARRAY['admin', 'creador', 'master', 'tecnico'])) 
    OR (SELECT public.is_superadmin())
  );

CREATE POLICY compras_mat_biologico_tenant_delete ON public.compras_mat_biologico
  FOR DELETE TO authenticated
  USING (
    (unidad_acuicola_sigla IN (SELECT u.sigla FROM public.units u WHERE u.empresa_id = (SELECT public.get_auth_empresa_id())) 
     AND (SELECT public.get_auth_user_role()) = ANY (ARRAY['admin', 'creador', 'master'])) 
    OR (SELECT public.is_superadmin())
  );

-- B. equipos
ALTER TABLE public.equipos ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS equipos_tenant_select ON public.equipos;
DROP POLICY IF EXISTS equipos_tenant_modify ON public.equipos;
DROP POLICY IF EXISTS equipos_tenant_insert ON public.equipos;
DROP POLICY IF EXISTS equipos_tenant_update ON public.equipos;
DROP POLICY IF EXISTS equipos_tenant_delete ON public.equipos;

CREATE POLICY equipos_tenant_select ON public.equipos
  FOR SELECT TO authenticated
  USING (
    cliente_id = (SELECT public.get_auth_empresa_id())
    OR unidad_acuicola_sigla IN (SELECT u.sigla FROM public.units u WHERE u.empresa_id = (SELECT public.get_auth_empresa_id())) 
    OR (SELECT public.is_superadmin())
  );

CREATE POLICY equipos_tenant_insert ON public.equipos
  FOR INSERT TO authenticated
  WITH CHECK (
    ((cliente_id = (SELECT public.get_auth_empresa_id()) OR unidad_acuicola_sigla IN (SELECT u.sigla FROM public.units u WHERE u.empresa_id = (SELECT public.get_auth_empresa_id()))) 
     AND (SELECT public.get_auth_user_role()) = ANY (ARRAY['admin', 'creador', 'master', 'tecnico'])) 
    OR (SELECT public.is_superadmin())
  );

CREATE POLICY equipos_tenant_update ON public.equipos
  FOR UPDATE TO authenticated
  USING (
    ((cliente_id = (SELECT public.get_auth_empresa_id()) OR unidad_acuicola_sigla IN (SELECT u.sigla FROM public.units u WHERE u.empresa_id = (SELECT public.get_auth_empresa_id()))) 
     AND (SELECT public.get_auth_user_role()) = ANY (ARRAY['admin', 'creador', 'master', 'tecnico'])) 
    OR (SELECT public.is_superadmin())
  )
  WITH CHECK (
    ((cliente_id = (SELECT public.get_auth_empresa_id()) OR unidad_acuicola_sigla IN (SELECT u.sigla FROM public.units u WHERE u.empresa_id = (SELECT public.get_auth_empresa_id()))) 
     AND (SELECT public.get_auth_user_role()) = ANY (ARRAY['admin', 'creador', 'master', 'tecnico'])) 
    OR (SELECT public.is_superadmin())
  );

CREATE POLICY equipos_tenant_delete ON public.equipos
  FOR DELETE TO authenticated
  USING (
    ((cliente_id = (SELECT public.get_auth_empresa_id()) OR unidad_acuicola_sigla IN (SELECT u.sigla FROM public.units u WHERE u.empresa_id = (SELECT public.get_auth_empresa_id()))) 
     AND (SELECT public.get_auth_user_role()) = ANY (ARRAY['admin', 'creador', 'master'])) 
    OR (SELECT public.is_superadmin())
  );

-- C. mantenimientos
ALTER TABLE public.mantenimientos ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS mantenimientos_tenant_select ON public.mantenimientos;
DROP POLICY IF EXISTS mantenimientos_tenant_insert ON public.mantenimientos;
DROP POLICY IF EXISTS mantenimientos_tenant_update ON public.mantenimientos;
DROP POLICY IF EXISTS mantenimientos_tenant_delete ON public.mantenimientos;

CREATE POLICY mantenimientos_tenant_select ON public.mantenimientos
  FOR SELECT TO authenticated
  USING (
    unidad_acuicola_sigla IN (SELECT u.sigla FROM public.units u WHERE u.empresa_id = (SELECT public.get_auth_empresa_id())) 
    OR (SELECT public.is_superadmin())
  );

CREATE POLICY mantenimientos_tenant_insert ON public.mantenimientos
  FOR INSERT TO authenticated
  WITH CHECK (
    (unidad_acuicola_sigla IN (SELECT u.sigla FROM public.units u WHERE u.empresa_id = (SELECT public.get_auth_empresa_id())) 
     AND (SELECT public.get_auth_user_role()) = ANY (ARRAY['admin', 'creador', 'master', 'tecnico'])) 
    OR (SELECT public.is_superadmin())
  );

CREATE POLICY mantenimientos_tenant_update ON public.mantenimientos
  FOR UPDATE TO authenticated
  USING (
    (unidad_acuicola_sigla IN (SELECT u.sigla FROM public.units u WHERE u.empresa_id = (SELECT public.get_auth_empresa_id())) 
     AND (SELECT public.get_auth_user_role()) = ANY (ARRAY['admin', 'creador', 'master', 'tecnico'])) 
    OR (SELECT public.is_superadmin())
  )
  WITH CHECK (
    (unidad_acuicola_sigla IN (SELECT u.sigla FROM public.units u WHERE u.empresa_id = (SELECT public.get_auth_empresa_id())) 
     AND (SELECT public.get_auth_user_role()) = ANY (ARRAY['admin', 'creador', 'master', 'tecnico'])) 
    OR (SELECT public.is_superadmin())
  );

CREATE POLICY mantenimientos_tenant_delete ON public.mantenimientos
  FOR DELETE TO authenticated
  USING (
    (unidad_acuicola_sigla IN (SELECT u.sigla FROM public.units u WHERE u.empresa_id = (SELECT public.get_auth_empresa_id())) 
     AND (SELECT public.get_auth_user_role()) = ANY (ARRAY['admin', 'creador', 'master'])) 
    OR (SELECT public.is_superadmin())
  );

-- D. jornales
ALTER TABLE public.jornales ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS jornales_tenant_select ON public.jornales;
DROP POLICY IF EXISTS jornales_tenant_insert ON public.jornales;
DROP POLICY IF EXISTS jornales_tenant_update ON public.jornales;
DROP POLICY IF EXISTS jornales_tenant_delete ON public.jornales;

CREATE POLICY jornales_tenant_select ON public.jornales
  FOR SELECT TO authenticated
  USING (
    unit_id IN (SELECT u.id FROM public.units u WHERE u.empresa_id = (SELECT public.get_auth_empresa_id())) 
    OR (SELECT public.is_superadmin())
  );

CREATE POLICY jornales_tenant_insert ON public.jornales
  FOR INSERT TO authenticated
  WITH CHECK (
    (unit_id IN (SELECT u.id FROM public.units u WHERE u.empresa_id = (SELECT public.get_auth_empresa_id())) 
     AND (SELECT public.get_auth_user_role()) = ANY (ARRAY['admin', 'creador', 'master', 'tecnico'])) 
    OR (SELECT public.is_superadmin())
  );

CREATE POLICY jornales_tenant_update ON public.jornales
  FOR UPDATE TO authenticated
  USING (
    (unit_id IN (SELECT u.id FROM public.units u WHERE u.empresa_id = (SELECT public.get_auth_empresa_id())) 
     AND (SELECT public.get_auth_user_role()) = ANY (ARRAY['admin', 'creador', 'master', 'tecnico'])) 
    OR (SELECT public.is_superadmin())
  )
  WITH CHECK (
    (unit_id IN (SELECT u.id FROM public.units u WHERE u.empresa_id = (SELECT public.get_auth_empresa_id())) 
     AND (SELECT public.get_auth_user_role()) = ANY (ARRAY['admin', 'creador', 'master', 'tecnico'])) 
    OR (SELECT public.is_superadmin())
  );

CREATE POLICY jornales_tenant_delete ON public.jornales
  FOR DELETE TO authenticated
  USING (
    (unit_id IN (SELECT u.id FROM public.units u WHERE u.empresa_id = (SELECT public.get_auth_empresa_id())) 
     AND (SELECT public.get_auth_user_role()) = ANY (ARRAY['admin', 'creador', 'master'])) 
    OR (SELECT public.is_superadmin())
  );

-- E. Bioseguridad y Sanidad (Reemplazo de USING true)
-- 1. bioseguridad_limpieza
ALTER TABLE public.bioseguridad_limpieza ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "Permitir acceso limpieza" ON public.bioseguridad_limpieza;
DROP POLICY IF EXISTS bioseguridad_limpieza_tenant_select ON public.bioseguridad_limpieza;
DROP POLICY IF EXISTS bioseguridad_limpieza_tenant_insert ON public.bioseguridad_limpieza;
DROP POLICY IF EXISTS bioseguridad_limpieza_tenant_update ON public.bioseguridad_limpieza;
DROP POLICY IF EXISTS bioseguridad_limpieza_tenant_delete ON public.bioseguridad_limpieza;

CREATE POLICY bioseguridad_limpieza_tenant_select ON public.bioseguridad_limpieza
  FOR SELECT TO authenticated
  USING (empresa_id = (SELECT public.get_auth_empresa_id()) OR (SELECT public.is_superadmin()));

CREATE POLICY bioseguridad_limpieza_tenant_insert ON public.bioseguridad_limpieza
  FOR INSERT TO authenticated
  WITH CHECK (
    (empresa_id = (SELECT public.get_auth_empresa_id()) AND (SELECT public.get_auth_user_role()) = ANY (ARRAY['admin', 'creador', 'master', 'tecnico', 'operario', 'sanitarydirector'])) 
    OR (SELECT public.is_superadmin())
  );

CREATE POLICY bioseguridad_limpieza_tenant_update ON public.bioseguridad_limpieza
  FOR UPDATE TO authenticated
  USING (
    (empresa_id = (SELECT public.get_auth_empresa_id()) AND (SELECT public.get_auth_user_role()) = ANY (ARRAY['admin', 'creador', 'master', 'tecnico', 'operario', 'sanitarydirector'])) 
    OR (SELECT public.is_superadmin())
  )
  WITH CHECK (
    (empresa_id = (SELECT public.get_auth_empresa_id()) AND (SELECT public.get_auth_user_role()) = ANY (ARRAY['admin', 'creador', 'master', 'tecnico', 'operario', 'sanitarydirector'])) 
    OR (SELECT public.is_superadmin())
  );

CREATE POLICY bioseguridad_limpieza_tenant_delete ON public.bioseguridad_limpieza
  FOR DELETE TO authenticated
  USING (
    (empresa_id = (SELECT public.get_auth_empresa_id()) AND (SELECT public.get_auth_user_role()) = ANY (ARRAY['admin', 'creador', 'master'])) 
    OR (SELECT public.is_superadmin())
  );

-- 2. bioseguridad_personal
ALTER TABLE public.bioseguridad_personal ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "Permitir acceso personal" ON public.bioseguridad_personal;
DROP POLICY IF EXISTS bioseguridad_personal_tenant_select ON public.bioseguridad_personal;
DROP POLICY IF EXISTS bioseguridad_personal_tenant_insert ON public.bioseguridad_personal;
DROP POLICY IF EXISTS bioseguridad_personal_tenant_update ON public.bioseguridad_personal;
DROP POLICY IF EXISTS bioseguridad_personal_tenant_delete ON public.bioseguridad_personal;

CREATE POLICY bioseguridad_personal_tenant_select ON public.bioseguridad_personal
  FOR SELECT TO authenticated
  USING (empresa_id = (SELECT public.get_auth_empresa_id()) OR (SELECT public.is_superadmin()));

CREATE POLICY bioseguridad_personal_tenant_insert ON public.bioseguridad_personal
  FOR INSERT TO authenticated
  WITH CHECK (
    (empresa_id = (SELECT public.get_auth_empresa_id()) AND (SELECT public.get_auth_user_role()) = ANY (ARRAY['admin', 'creador', 'master', 'tecnico', 'operario', 'sanitarydirector'])) 
    OR (SELECT public.is_superadmin())
  );

CREATE POLICY bioseguridad_personal_tenant_update ON public.bioseguridad_personal
  FOR UPDATE TO authenticated
  USING (
    (empresa_id = (SELECT public.get_auth_empresa_id()) AND (SELECT public.get_auth_user_role()) = ANY (ARRAY['admin', 'creador', 'master', 'tecnico', 'operario', 'sanitarydirector'])) 
    OR (SELECT public.is_superadmin())
  )
  WITH CHECK (
    (empresa_id = (SELECT public.get_auth_empresa_id()) AND (SELECT public.get_auth_user_role()) = ANY (ARRAY['admin', 'creador', 'master', 'tecnico', 'operario', 'sanitarydirector'])) 
    OR (SELECT public.is_superadmin())
  );

CREATE POLICY bioseguridad_personal_tenant_delete ON public.bioseguridad_personal
  FOR DELETE TO authenticated
  USING (
    (empresa_id = (SELECT public.get_auth_empresa_id()) AND (SELECT public.get_auth_user_role()) = ANY (ARRAY['admin', 'creador', 'master'])) 
    OR (SELECT public.is_superadmin())
  );

-- 3. bioseguridad_vehiculos
ALTER TABLE public.bioseguridad_vehiculos ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "Permitir acceso vehiculos" ON public.bioseguridad_vehiculos;
DROP POLICY IF EXISTS bioseguridad_vehiculos_tenant_select ON public.bioseguridad_vehiculos;
DROP POLICY IF EXISTS bioseguridad_vehiculos_tenant_insert ON public.bioseguridad_vehiculos;
DROP POLICY IF EXISTS bioseguridad_vehiculos_tenant_update ON public.bioseguridad_vehiculos;
DROP POLICY IF EXISTS bioseguridad_vehiculos_tenant_delete ON public.bioseguridad_vehiculos;

CREATE POLICY bioseguridad_vehiculos_tenant_select ON public.bioseguridad_vehiculos
  FOR SELECT TO authenticated
  USING (empresa_id = (SELECT public.get_auth_empresa_id()) OR (SELECT public.is_superadmin()));

CREATE POLICY bioseguridad_vehiculos_tenant_insert ON public.bioseguridad_vehiculos
  FOR INSERT TO authenticated
  WITH CHECK (
    (empresa_id = (SELECT public.get_auth_empresa_id()) AND (SELECT public.get_auth_user_role()) = ANY (ARRAY['admin', 'creador', 'master', 'tecnico', 'operario', 'sanitarydirector'])) 
    OR (SELECT public.is_superadmin())
  );

CREATE POLICY bioseguridad_vehiculos_tenant_update ON public.bioseguridad_vehiculos
  FOR UPDATE TO authenticated
  USING (
    (empresa_id = (SELECT public.get_auth_empresa_id()) AND (SELECT public.get_auth_user_role()) = ANY (ARRAY['admin', 'creador', 'master', 'tecnico', 'operario', 'sanitarydirector'])) 
    OR (SELECT public.is_superadmin())
  )
  WITH CHECK (
    (empresa_id = (SELECT public.get_auth_empresa_id()) AND (SELECT public.get_auth_user_role()) = ANY (ARRAY['admin', 'creador', 'master', 'tecnico', 'operario', 'sanitarydirector'])) 
    OR (SELECT public.is_superadmin())
  );

CREATE POLICY bioseguridad_vehiculos_tenant_delete ON public.bioseguridad_vehiculos
  FOR DELETE TO authenticated
  USING (
    (empresa_id = (SELECT public.get_auth_empresa_id()) AND (SELECT public.get_auth_user_role()) = ANY (ARRAY['admin', 'creador', 'master'])) 
    OR (SELECT public.is_superadmin())
  );

-- 4. sanidad_monitoreo_patogenos
ALTER TABLE public.sanidad_monitoreo_patogenos ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "Permitir acceso patogenos" ON public.sanidad_monitoreo_patogenos;
DROP POLICY IF EXISTS sanidad_monitoreo_patogenos_tenant_select ON public.sanidad_monitoreo_patogenos;
DROP POLICY IF EXISTS sanidad_monitoreo_patogenos_tenant_insert ON public.sanidad_monitoreo_patogenos;
DROP POLICY IF EXISTS sanidad_monitoreo_patogenos_tenant_update ON public.sanidad_monitoreo_patogenos;
DROP POLICY IF EXISTS sanidad_monitoreo_patogenos_tenant_delete ON public.sanidad_monitoreo_patogenos;

CREATE POLICY sanidad_monitoreo_patogenos_tenant_select ON public.sanidad_monitoreo_patogenos
  FOR SELECT TO authenticated
  USING (empresa_id = (SELECT public.get_auth_empresa_id()) OR (SELECT public.is_superadmin()));

CREATE POLICY sanidad_monitoreo_patogenos_tenant_insert ON public.sanidad_monitoreo_patogenos
  FOR INSERT TO authenticated
  WITH CHECK (
    (empresa_id = (SELECT public.get_auth_empresa_id()) AND (SELECT public.get_auth_user_role()) = ANY (ARRAY['admin', 'creador', 'master', 'tecnico', 'sanitarydirector'])) 
    OR (SELECT public.is_superadmin())
  );

CREATE POLICY sanidad_monitoreo_patogenos_tenant_update ON public.sanidad_monitoreo_patogenos
  FOR UPDATE TO authenticated
  USING (
    (empresa_id = (SELECT public.get_auth_empresa_id()) AND (SELECT public.get_auth_user_role()) = ANY (ARRAY['admin', 'creador', 'master', 'tecnico', 'sanitarydirector'])) 
    OR (SELECT public.is_superadmin())
  )
  WITH CHECK (
    (empresa_id = (SELECT public.get_auth_empresa_id()) AND (SELECT public.get_auth_user_role()) = ANY (ARRAY['admin', 'creador', 'master', 'tecnico', 'sanitarydirector'])) 
    OR (SELECT public.is_superadmin())
  );

CREATE POLICY sanidad_monitoreo_patogenos_tenant_delete ON public.sanidad_monitoreo_patogenos
  FOR DELETE TO authenticated
  USING (
    (empresa_id = (SELECT public.get_auth_empresa_id()) AND (SELECT public.get_auth_user_role()) = ANY (ARRAY['admin', 'creador', 'master'])) 
    OR (SELECT public.is_superadmin())
  );

-- 5. sanidad_necropsias
ALTER TABLE public.sanidad_necropsias ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "Permitir acceso necropsias" ON public.sanidad_necropsias;
DROP POLICY IF EXISTS sanidad_necropsias_tenant_select ON public.sanidad_necropsias;
DROP POLICY IF EXISTS sanidad_necropsias_tenant_insert ON public.sanidad_necropsias;
DROP POLICY IF EXISTS sanidad_necropsias_tenant_update ON public.sanidad_necropsias;
DROP POLICY IF EXISTS sanidad_necropsias_tenant_delete ON public.sanidad_necropsias;

CREATE POLICY sanidad_necropsias_tenant_select ON public.sanidad_necropsias
  FOR SELECT TO authenticated
  USING (empresa_id = (SELECT public.get_auth_empresa_id()) OR (SELECT public.is_superadmin()));

CREATE POLICY sanidad_necropsias_tenant_insert ON public.sanidad_necropsias
  FOR INSERT TO authenticated
  WITH CHECK (
    (empresa_id = (SELECT public.get_auth_empresa_id()) AND (SELECT public.get_auth_user_role()) = ANY (ARRAY['admin', 'creador', 'master', 'tecnico', 'sanitarydirector'])) 
    OR (SELECT public.is_superadmin())
  );

CREATE POLICY sanidad_necropsias_tenant_update ON public.sanidad_necropsias
  FOR UPDATE TO authenticated
  USING (
    (empresa_id = (SELECT public.get_auth_empresa_id()) AND (SELECT public.get_auth_user_role()) = ANY (ARRAY['admin', 'creador', 'master', 'tecnico', 'sanitarydirector'])) 
    OR (SELECT public.is_superadmin())
  )
  WITH CHECK (
    (empresa_id = (SELECT public.get_auth_empresa_id()) AND (SELECT public.get_auth_user_role()) = ANY (ARRAY['admin', 'creador', 'master', 'tecnico', 'sanitarydirector'])) 
    OR (SELECT public.is_superadmin())
  );

CREATE POLICY sanidad_necropsias_tenant_delete ON public.sanidad_necropsias
  FOR DELETE TO authenticated
  USING (
    (empresa_id = (SELECT public.get_auth_empresa_id()) AND (SELECT public.get_auth_user_role()) = ANY (ARRAY['admin', 'creador', 'master'])) 
    OR (SELECT public.is_superadmin())
  );

-- F. Split de Permissive Policies en Tablas Restantes
-- 1. facturas
ALTER TABLE public.facturas ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS facturas_tenant_select ON public.facturas;
DROP POLICY IF EXISTS facturas_tenant_modify ON public.facturas;
DROP POLICY IF EXISTS facturas_tenant_insert ON public.facturas;
DROP POLICY IF EXISTS facturas_tenant_update ON public.facturas;
DROP POLICY IF EXISTS facturas_tenant_delete ON public.facturas;

CREATE POLICY facturas_tenant_select ON public.facturas
  FOR SELECT TO authenticated
  USING (
    empresa_id = (SELECT public.get_auth_empresa_id())
    OR unidad_acuicola_sigla IN (SELECT u.sigla FROM public.units u WHERE u.empresa_id = (SELECT public.get_auth_empresa_id())) 
    OR (SELECT public.is_superadmin())
  );

CREATE POLICY facturas_tenant_insert ON public.facturas
  FOR INSERT TO authenticated
  WITH CHECK (
    ((empresa_id = (SELECT public.get_auth_empresa_id()) OR unidad_acuicola_sigla IN (SELECT u.sigla FROM public.units u WHERE u.empresa_id = (SELECT public.get_auth_empresa_id())))
     AND (SELECT public.get_auth_user_role()) = ANY (ARRAY['admin', 'creador', 'master', 'tecnico', 'sanitarydirector'])) 
    OR (SELECT public.is_superadmin())
  );

CREATE POLICY facturas_tenant_update ON public.facturas
  FOR UPDATE TO authenticated
  USING (
    ((empresa_id = (SELECT public.get_auth_empresa_id()) OR unidad_acuicola_sigla IN (SELECT u.sigla FROM public.units u WHERE u.empresa_id = (SELECT public.get_auth_empresa_id())))
     AND (SELECT public.get_auth_user_role()) = ANY (ARRAY['admin', 'creador', 'master', 'tecnico', 'sanitarydirector'])) 
    OR (SELECT public.is_superadmin())
  )
  WITH CHECK (
    ((empresa_id = (SELECT public.get_auth_empresa_id()) OR unidad_acuicola_sigla IN (SELECT u.sigla FROM public.units u WHERE u.empresa_id = (SELECT public.get_auth_empresa_id())))
     AND (SELECT public.get_auth_user_role()) = ANY (ARRAY['admin', 'creador', 'master', 'tecnico', 'sanitarydirector'])) 
    OR (SELECT public.is_superadmin())
  );

CREATE POLICY facturas_tenant_delete ON public.facturas
  FOR DELETE TO authenticated
  USING (
    ((empresa_id = (SELECT public.get_auth_empresa_id()) OR unidad_acuicola_sigla IN (SELECT u.sigla FROM public.units u WHERE u.empresa_id = (SELECT public.get_auth_empresa_id())))
     AND (SELECT public.get_auth_user_role()) = ANY (ARRAY['admin', 'creador', 'master'])) 
    OR (SELECT public.is_superadmin())
  );

-- 2. clientes
ALTER TABLE public.clientes ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS clientes_tenant_select ON public.clientes;
DROP POLICY IF EXISTS clientes_tenant_modify ON public.clientes;
DROP POLICY IF EXISTS clientes_tenant_insert ON public.clientes;
DROP POLICY IF EXISTS clientes_tenant_update ON public.clientes;
DROP POLICY IF EXISTS clientes_tenant_delete ON public.clientes;

CREATE POLICY clientes_tenant_select ON public.clientes
  FOR SELECT TO authenticated
  USING (empresa_id = (SELECT public.get_auth_empresa_id()) OR (SELECT public.is_superadmin()));

CREATE POLICY clientes_tenant_insert ON public.clientes
  FOR INSERT TO authenticated
  WITH CHECK (
    (empresa_id = (SELECT public.get_auth_empresa_id()) AND (SELECT public.get_auth_user_role()) = ANY (ARRAY['admin', 'creador', 'master', 'tecnico', 'operario'])) 
    OR (SELECT public.is_superadmin())
  );

CREATE POLICY clientes_tenant_update ON public.clientes
  FOR UPDATE TO authenticated
  USING (
    (empresa_id = (SELECT public.get_auth_empresa_id()) AND (SELECT public.get_auth_user_role()) = ANY (ARRAY['admin', 'creador', 'master', 'tecnico', 'operario'])) 
    OR (SELECT public.is_superadmin())
  )
  WITH CHECK (
    (empresa_id = (SELECT public.get_auth_empresa_id()) AND (SELECT public.get_auth_user_role()) = ANY (ARRAY['admin', 'creador', 'master', 'tecnico', 'operario'])) 
    OR (SELECT public.is_superadmin())
  );

CREATE POLICY clientes_tenant_delete ON public.clientes
  FOR DELETE TO authenticated
  USING (
    (empresa_id = (SELECT public.get_auth_empresa_id()) AND (SELECT public.get_auth_user_role()) = ANY (ARRAY['admin', 'creador', 'master'])) 
    OR (SELECT public.is_superadmin())
  );

-- 3. proveedores
ALTER TABLE public.proveedores ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS proveedores_tenant_select ON public.proveedores;
DROP POLICY IF EXISTS proveedores_tenant_insert ON public.proveedores;
DROP POLICY IF EXISTS proveedores_tenant_update ON public.proveedores;
DROP POLICY IF EXISTS proveedores_tenant_delete ON public.proveedores;

CREATE POLICY proveedores_tenant_select ON public.proveedores
  FOR SELECT TO authenticated
  USING (empresa_id = (SELECT public.get_auth_empresa_id()) OR (SELECT public.is_superadmin()));

CREATE POLICY proveedores_tenant_insert ON public.proveedores
  FOR INSERT TO authenticated
  WITH CHECK (
    (empresa_id = (SELECT public.get_auth_empresa_id()) AND (SELECT public.get_auth_user_role()) = ANY (ARRAY['admin', 'creador', 'master', 'tecnico'])) 
    OR (SELECT public.is_superadmin())
  );

CREATE POLICY proveedores_tenant_update ON public.proveedores
  FOR UPDATE TO authenticated
  USING (
    (empresa_id = (SELECT public.get_auth_empresa_id()) AND (SELECT public.get_auth_user_role()) = ANY (ARRAY['admin', 'creador', 'master', 'tecnico'])) 
    OR (SELECT public.is_superadmin())
  )
  WITH CHECK (
    (empresa_id = (SELECT public.get_auth_empresa_id()) AND (SELECT public.get_auth_user_role()) = ANY (ARRAY['admin', 'creador', 'master', 'tecnico'])) 
    OR (SELECT public.is_superadmin())
  );

CREATE POLICY proveedores_tenant_delete ON public.proveedores
  FOR DELETE TO authenticated
  USING (
    (empresa_id = (SELECT public.get_auth_empresa_id()) AND (SELECT public.get_auth_user_role()) = ANY (ARRAY['admin', 'creador', 'master'])) 
    OR (SELECT public.is_superadmin())
  );

-- 4. inventario_insumos
ALTER TABLE public.inventario_insumos ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS inventario_insumos_tenant_select ON public.inventario_insumos;
DROP POLICY IF EXISTS inventario_insumos_tenant_insert ON public.inventario_insumos;
DROP POLICY IF EXISTS inventario_insumos_tenant_update ON public.inventario_insumos;
DROP POLICY IF EXISTS inventario_insumos_tenant_delete ON public.inventario_insumos;

CREATE POLICY inventario_insumos_tenant_select ON public.inventario_insumos
  FOR SELECT TO authenticated
  USING (
    cliente_id = (SELECT public.get_auth_empresa_id()) 
    OR unidad_acuicola_sigla IN (SELECT u.sigla FROM public.units u WHERE u.empresa_id = (SELECT public.get_auth_empresa_id())) 
    OR (SELECT public.is_superadmin())
  );

CREATE POLICY inventario_insumos_tenant_insert ON public.inventario_insumos
  FOR INSERT TO authenticated
  WITH CHECK (
    ((cliente_id = (SELECT public.get_auth_empresa_id()) OR unidad_acuicola_sigla IN (SELECT u.sigla FROM public.units u WHERE u.empresa_id = (SELECT public.get_auth_empresa_id()))) 
     AND (SELECT public.get_auth_user_role()) = ANY (ARRAY['admin', 'creador', 'master', 'tecnico', 'operario'])) 
    OR (SELECT public.is_superadmin())
  );

CREATE POLICY inventario_insumos_tenant_update ON public.inventario_insumos
  FOR UPDATE TO authenticated
  USING (
    ((cliente_id = (SELECT public.get_auth_empresa_id()) OR unidad_acuicola_sigla IN (SELECT u.sigla FROM public.units u WHERE u.empresa_id = (SELECT public.get_auth_empresa_id()))) 
     AND (SELECT public.get_auth_user_role()) = ANY (ARRAY['admin', 'creador', 'master', 'tecnico', 'operario'])) 
    OR (SELECT public.is_superadmin())
  )
  WITH CHECK (
    ((cliente_id = (SELECT public.get_auth_empresa_id()) OR unidad_acuicola_sigla IN (SELECT u.sigla FROM public.units u WHERE u.empresa_id = (SELECT public.get_auth_empresa_id()))) 
     AND (SELECT public.get_auth_user_role()) = ANY (ARRAY['admin', 'creador', 'master', 'tecnico', 'operario'])) 
    OR (SELECT public.is_superadmin())
  );

CREATE POLICY inventario_insumos_tenant_delete ON public.inventario_insumos
  FOR DELETE TO authenticated
  USING (
    ((cliente_id = (SELECT public.get_auth_empresa_id()) OR unidad_acuicola_sigla IN (SELECT u.sigla FROM public.units u WHERE u.empresa_id = (SELECT public.get_auth_empresa_id()))) 
     AND (SELECT public.get_auth_user_role()) = ANY (ARRAY['admin', 'creador', 'master'])) 
    OR (SELECT public.is_superadmin())
  );

-- 5. inventory
ALTER TABLE public.inventory ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS inventory_tenant_select ON public.inventory;
DROP POLICY IF EXISTS inventory_tenant_modify ON public.inventory;
DROP POLICY IF EXISTS inventory_tenant_insert ON public.inventory;
DROP POLICY IF EXISTS inventory_tenant_update ON public.inventory;
DROP POLICY IF EXISTS inventory_tenant_delete ON public.inventory;

CREATE POLICY inventory_tenant_select ON public.inventory
  FOR SELECT TO authenticated
  USING (empresa_id = (SELECT public.get_auth_empresa_id()) OR (SELECT public.is_superadmin()));

CREATE POLICY inventory_tenant_insert ON public.inventory
  FOR INSERT TO authenticated
  WITH CHECK (
    (empresa_id = (SELECT public.get_auth_empresa_id()) AND (SELECT public.get_auth_user_role()) = ANY (ARRAY['admin', 'creador', 'master', 'tecnico'])) 
    OR (SELECT public.is_superadmin())
  );

CREATE POLICY inventory_tenant_update ON public.inventory
  FOR UPDATE TO authenticated
  USING (
    (empresa_id = (SELECT public.get_auth_empresa_id()) AND (SELECT public.get_auth_user_role()) = ANY (ARRAY['admin', 'creador', 'master', 'tecnico'])) 
    OR (SELECT public.is_superadmin())
  )
  WITH CHECK (
    (empresa_id = (SELECT public.get_auth_empresa_id()) AND (SELECT public.get_auth_user_role()) = ANY (ARRAY['admin', 'creador', 'master', 'tecnico'])) 
    OR (SELECT public.is_superadmin())
  );

CREATE POLICY inventory_tenant_delete ON public.inventory
  FOR DELETE TO authenticated
  USING (
    (empresa_id = (SELECT public.get_auth_empresa_id()) AND (SELECT public.get_auth_user_role()) = ANY (ARRAY['admin', 'creador', 'master'])) 
    OR (SELECT public.is_superadmin())
  );

-- 6. ventas_lotes
ALTER TABLE public.ventas_lotes ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS ventas_lotes_tenant_select ON public.ventas_lotes;
DROP POLICY IF EXISTS ventas_lotes_tenant_modify ON public.ventas_lotes;
DROP POLICY IF EXISTS ventas_lotes_tenant_insert ON public.ventas_lotes;
DROP POLICY IF EXISTS ventas_lotes_tenant_update ON public.ventas_lotes;
DROP POLICY IF EXISTS ventas_lotes_tenant_delete ON public.ventas_lotes;

CREATE POLICY ventas_lotes_tenant_select ON public.ventas_lotes
  FOR SELECT TO authenticated
  USING (empresa_id = (SELECT public.get_auth_empresa_id()) OR (SELECT public.is_superadmin()));

CREATE POLICY ventas_lotes_tenant_insert ON public.ventas_lotes
  FOR INSERT TO authenticated
  WITH CHECK (
    (empresa_id = (SELECT public.get_auth_empresa_id()) AND (SELECT public.get_auth_user_role()) = ANY (ARRAY['admin', 'creador', 'master', 'tecnico', 'operario'])) 
    OR (SELECT public.is_superadmin())
  );

CREATE POLICY ventas_lotes_tenant_update ON public.ventas_lotes
  FOR UPDATE TO authenticated
  USING (
    (empresa_id = (SELECT public.get_auth_empresa_id()) AND (SELECT public.get_auth_user_role()) = ANY (ARRAY['admin', 'creador', 'master', 'tecnico', 'operario'])) 
    OR (SELECT public.is_superadmin())
  )
  WITH CHECK (
    (empresa_id = (SELECT public.get_auth_empresa_id()) AND (SELECT public.get_auth_user_role()) = ANY (ARRAY['admin', 'creador', 'master', 'tecnico', 'operario'])) 
    OR (SELECT public.is_superadmin())
  );

CREATE POLICY ventas_lotes_tenant_delete ON public.ventas_lotes
  FOR DELETE TO authenticated
  USING (
    (empresa_id = (SELECT public.get_auth_empresa_id()) AND (SELECT public.get_auth_user_role()) = ANY (ARRAY['admin', 'creador', 'master'])) 
    OR (SELECT public.is_superadmin())
  );

-- 7. estanques
ALTER TABLE public.estanques ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS estanques_tenant_select ON public.estanques;
DROP POLICY IF EXISTS estanques_tenant_modify ON public.estanques;
DROP POLICY IF EXISTS estanques_write_authorized ON public.estanques;
DROP POLICY IF EXISTS estanques_tenant_insert ON public.estanques;
DROP POLICY IF EXISTS estanques_tenant_update ON public.estanques;
DROP POLICY IF EXISTS estanques_tenant_delete ON public.estanques;

CREATE POLICY estanques_tenant_select ON public.estanques
  FOR SELECT TO authenticated
  USING (empresa_id = (SELECT public.get_auth_empresa_id()) OR (SELECT public.is_superadmin()));

CREATE POLICY estanques_tenant_insert ON public.estanques
  FOR INSERT TO authenticated
  WITH CHECK (
    (empresa_id = (SELECT public.get_auth_empresa_id()) AND (SELECT public.get_auth_user_role()) = ANY (ARRAY['admin', 'creador', 'master', 'tecnico', 'sanitarydirector'])) 
    OR (SELECT public.is_superadmin())
  );

CREATE POLICY estanques_tenant_update ON public.estanques
  FOR UPDATE TO authenticated
  USING (
    (empresa_id = (SELECT public.get_auth_empresa_id()) AND (SELECT public.get_auth_user_role()) = ANY (ARRAY['admin', 'creador', 'master', 'tecnico', 'sanitarydirector'])) 
    OR (SELECT public.is_superadmin())
  )
  WITH CHECK (
    (empresa_id = (SELECT public.get_auth_empresa_id()) AND (SELECT public.get_auth_user_role()) = ANY (ARRAY['admin', 'creador', 'master', 'tecnico', 'sanitarydirector'])) 
    OR (SELECT public.is_superadmin())
  );

CREATE POLICY estanques_tenant_delete ON public.estanques
  FOR DELETE TO authenticated
  USING (
    (empresa_id = (SELECT public.get_auth_empresa_id()) AND (SELECT public.get_auth_user_role()) = ANY (ARRAY['admin', 'creador', 'master'])) 
    OR (SELECT public.is_superadmin())
  );

-- 8. miembros_equipo
ALTER TABLE public.miembros_equipo ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS miembros_equipo_tenant_select ON public.miembros_equipo;
DROP POLICY IF EXISTS miembros_equipo_tenant_modify ON public.miembros_equipo;
DROP POLICY IF EXISTS miembros_equipo_tenant_insert ON public.miembros_equipo;
DROP POLICY IF EXISTS miembros_equipo_tenant_update ON public.miembros_equipo;
DROP POLICY IF EXISTS miembros_equipo_tenant_delete ON public.miembros_equipo;

CREATE POLICY miembros_equipo_tenant_select ON public.miembros_equipo
  FOR SELECT TO authenticated
  USING (empresa_id = (SELECT public.get_auth_empresa_id()) OR (SELECT public.is_superadmin()));

CREATE POLICY miembros_equipo_tenant_insert ON public.miembros_equipo
  FOR INSERT TO authenticated
  WITH CHECK (
    (empresa_id = (SELECT public.get_auth_empresa_id()) AND (SELECT public.get_auth_user_role()) = ANY (ARRAY['admin', 'creador', 'master'])) 
    OR (SELECT public.is_superadmin())
  );

CREATE POLICY miembros_equipo_tenant_update ON public.miembros_equipo
  FOR UPDATE TO authenticated
  USING (
    (empresa_id = (SELECT public.get_auth_empresa_id()) AND (SELECT public.get_auth_user_role()) = ANY (ARRAY['admin', 'creador', 'master'])) 
    OR (SELECT public.is_superadmin())
  )
  WITH CHECK (
    (empresa_id = (SELECT public.get_auth_empresa_id()) AND (SELECT public.get_auth_user_role()) = ANY (ARRAY['admin', 'creador', 'master'])) 
    OR (SELECT public.is_superadmin())
  );

CREATE POLICY miembros_equipo_tenant_delete ON public.miembros_equipo
  FOR DELETE TO authenticated
  USING (
    (empresa_id = (SELECT public.get_auth_empresa_id()) AND (SELECT public.get_auth_user_role()) = ANY (ARRAY['admin', 'creador', 'master'])) 
    OR (SELECT public.is_superadmin())
  );

-- 9. empresas & units
ALTER TABLE public.empresas ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS empresas_tenant_isolation_select ON public.empresas;
DROP POLICY IF EXISTS empresas_tenant_isolation_modify ON public.empresas;
DROP POLICY IF EXISTS empresas_tenant_isolation_insert ON public.empresas;
DROP POLICY IF EXISTS empresas_tenant_isolation_update ON public.empresas;
DROP POLICY IF EXISTS empresas_tenant_isolation_delete ON public.empresas;

CREATE POLICY empresas_tenant_isolation_select ON public.empresas
  FOR SELECT TO authenticated
  USING (id = (SELECT public.get_auth_empresa_id()) OR (SELECT public.is_superadmin()));

CREATE POLICY empresas_tenant_isolation_insert ON public.empresas
  FOR INSERT TO authenticated
  WITH CHECK ((SELECT public.is_superadmin()));

CREATE POLICY empresas_tenant_isolation_update ON public.empresas
  FOR UPDATE TO authenticated
  USING (
    (id = (SELECT public.get_auth_empresa_id()) AND (SELECT public.get_auth_user_role()) = ANY (ARRAY['admin', 'creador', 'master'])) 
    OR (SELECT public.is_superadmin())
  )
  WITH CHECK (
    (id = (SELECT public.get_auth_empresa_id()) AND (SELECT public.get_auth_user_role()) = ANY (ARRAY['admin', 'creador', 'master'])) 
    OR (SELECT public.is_superadmin())
  );

CREATE POLICY empresas_tenant_isolation_delete ON public.empresas
  FOR DELETE TO authenticated
  USING ((SELECT public.is_superadmin()));

ALTER TABLE public.units ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS units_tenant_isolation_select ON public.units;
DROP POLICY IF EXISTS units_tenant_isolation_modify ON public.units;
DROP POLICY IF EXISTS units_tenant_isolation_insert ON public.units;
DROP POLICY IF EXISTS units_tenant_isolation_update ON public.units;
DROP POLICY IF EXISTS units_tenant_isolation_delete ON public.units;

CREATE POLICY units_tenant_isolation_select ON public.units
  FOR SELECT TO authenticated
  USING (empresa_id = (SELECT public.get_auth_empresa_id()) OR (SELECT public.is_superadmin()));

CREATE POLICY units_tenant_isolation_insert ON public.units
  FOR INSERT TO authenticated
  WITH CHECK (
    (empresa_id = (SELECT public.get_auth_empresa_id()) AND (SELECT public.get_auth_user_role()) = ANY (ARRAY['admin', 'creador', 'master'])) 
    OR (SELECT public.is_superadmin())
  );

CREATE POLICY units_tenant_isolation_update ON public.units
  FOR UPDATE TO authenticated
  USING (
    (empresa_id = (SELECT public.get_auth_empresa_id()) AND (SELECT public.get_auth_user_role()) = ANY (ARRAY['admin', 'creador', 'master'])) 
    OR (SELECT public.is_superadmin())
  )
  WITH CHECK (
    (empresa_id = (SELECT public.get_auth_empresa_id()) AND (SELECT public.get_auth_user_role()) = ANY (ARRAY['admin', 'creador', 'master'])) 
    OR (SELECT public.is_superadmin())
  );

CREATE POLICY units_tenant_isolation_delete ON public.units
  FOR DELETE TO authenticated
  USING (
    (empresa_id = (SELECT public.get_auth_empresa_id()) AND (SELECT public.get_auth_user_role()) = ANY (ARRAY['admin', 'creador', 'master'])) 
    OR (SELECT public.is_superadmin())
  );

-- ------------------------------------------------------------------------------
-- 4. Corrección de Vistas Security Definer a Security Invoker
-- ------------------------------------------------------------------------------

DROP VIEW IF EXISTS public.v_estanques_inconsistencias;
CREATE OR REPLACE VIEW public.v_estanques_inconsistencias 
WITH (security_invoker = true) AS
SELECT e.id, e.nombre, e.sigla, e.empresa_id, e.biomasa_kg, COALESCE(SUM(l.biomasa_actual_kg), 0) AS biomasa_lotes
FROM public.estanques e
LEFT JOIN public.lotes l ON l.estanque_id = e.id AND l.estado = 'Activo'
GROUP BY e.id, e.nombre, e.sigla, e.empresa_id, e.biomasa_kg
HAVING ABS(e.biomasa_kg - COALESCE(SUM(l.biomasa_actual_kg), 0)) > 0.01;

DROP VIEW IF EXISTS public.view_huerfanos_sede_report;
CREATE OR REPLACE VIEW public.view_huerfanos_sede_report
WITH (security_invoker = true) AS
 SELECT 'estanques'::text AS tabla,
    estanques.id::text AS id,
    estanques.nombre,
    estanques.sigla,
    estanques.creado_en
   FROM public.estanques
  WHERE estanques.unidad_acuicola_sigla IS NULL AND estanques.is_deleted = false
UNION ALL
 SELECT 'lotes'::text AS tabla,
    lotes.id::text AS id,
    lotes.codigo_lote AS nombre,
    lotes.codigo_lote AS sigla,
    lotes.creado_en
   FROM public.lotes
  WHERE lotes.unidad_acuicola_sigla IS NULL
UNION ALL
 SELECT 'clientes'::text AS tabla,
    clientes.id::text AS id,
    clientes.nombre,
    clientes.email AS sigla,
    clientes.creado_en
   FROM public.clientes
  WHERE clientes.unidad_acuicola_sigla IS NULL
UNION ALL
 SELECT 'proveedores'::text AS tabla,
    proveedores.id::text AS id,
    proveedores.nombre,
    proveedores.nit AS sigla,
    proveedores.creado_en
   FROM public.proveedores
  WHERE proveedores.unidad_acuicola_sigla IS NULL
UNION ALL
 SELECT 'ventas_lotes'::text AS tabla,
    ventas_lotes.id::text AS id,
    ventas_lotes.codigo_lote AS nombre,
    ventas_lotes.codigo_lote AS sigla,
    ventas_lotes.creado_en
   FROM public.ventas_lotes
  WHERE ventas_lotes.unidad_acuicola_sigla IS NULL
UNION ALL
 SELECT 'alimentacion_diaria'::text AS tabla,
    alimentacion_diaria.id::text AS id,
    alimentacion_diaria.lote_id::text AS nombre,
    alimentacion_diaria.estanque_id::text AS sigla,
    alimentacion_diaria.creado_en
   FROM public.alimentacion_diaria
  WHERE alimentacion_diaria.unidad_acuicola_sigla IS NULL
UNION ALL
 SELECT 'registro_actividades'::text AS tabla,
    registro_actividades.id::text AS id,
    registro_actividades.tipo AS nombre,
    registro_actividades.descripcion AS sigla,
    registro_actividades.creado_en
   FROM public.registro_actividades
  WHERE registro_actividades.unidad_acuicola_sigla IS NULL
UNION ALL
 SELECT 'inventario_insumos'::text AS tabla,
    inventario_insumos.id::text AS id,
    inventario_insumos.nombre,
    inventario_insumos.tipo AS sigla,
    inventario_insumos.creado_en
   FROM public.inventario_insumos
  WHERE inventario_insumos.unidad_acuicola_sigla IS NULL
UNION ALL
 SELECT 'facturas'::text AS tabla,
    facturas.id::text AS id,
    facturas.numero_factura AS nombre,
    facturas.proveedor_nombre AS sigla,
    facturas.creado_en
   FROM public.facturas
  WHERE facturas.unidad_acuicola_sigla IS NULL
UNION ALL
 SELECT 'compras_mat_biologico'::text AS tabla,
    compras_mat_biologico.id,
    compras_mat_biologico.especie AS nombre,
    compras_mat_biologico.proveedor_nombre AS sigla,
    compras_mat_biologico.creado_en
   FROM public.compras_mat_biologico
  WHERE compras_mat_biologico.unidad_acuicola_sigla IS NULL
UNION ALL
 SELECT 'registros_nomina'::text AS tabla,
    registros_nomina.id,
    registros_nomina.empleado_nombre AS nombre,
    registros_nomina.periodo AS sigla,
    registros_nomina.creado_en
   FROM public.registros_nomina
  WHERE registros_nomina.unidad_acuicola_sigla IS NULL
UNION ALL
 SELECT 'equipos'::text AS tabla,
    equipos.id::text AS id,
    equipos.nombre,
    equipos.sigla,
    equipos.creado_en
   FROM public.equipos
  WHERE equipos.unidad_acuicola_sigla IS NULL;

COMMIT;
