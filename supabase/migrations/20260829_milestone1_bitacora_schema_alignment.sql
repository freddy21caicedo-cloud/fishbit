-- ==============================================================================
-- Migration: 20260829_milestone1_bitacora_schema_alignment.sql
-- Module: Bitácora (Calidad de Agua, Alimentación Diaria, Biometrías, Mortalidad)
-- Target: Supabase PostgreSQL (Project oakovawlwjpnoydpwtam)
-- Idempotency: Fully idempotent (safe to execute multiple times)
-- ==============================================================================

BEGIN;

-- ------------------------------------------------------------------------------
-- 1. Table: parametros_calidad_agua (Canonical Water Quality Table)
-- ------------------------------------------------------------------------------

-- Ensure tenant columns, unit references, and physicochemical parameter columns
ALTER TABLE public.parametros_calidad_agua 
  ADD COLUMN IF NOT EXISTS empresa_id UUID REFERENCES public.empresas(id) ON DELETE CASCADE,
  ADD COLUMN IF NOT EXISTS unit_id UUID REFERENCES public.units(id) ON DELETE SET NULL,
  ADD COLUMN IF NOT EXISTS unidad_acuicola_id UUID REFERENCES public.units(id) ON DELETE SET NULL,
  ADD COLUMN IF NOT EXISTS hora TIME WITHOUT TIME ZONE,
  ADD COLUMN IF NOT EXISTS observaciones TEXT,
  ADD COLUMN IF NOT EXISTS registrado_por TEXT,
  ADD COLUMN IF NOT EXISTS oxigeno_mg_l NUMERIC,
  ADD COLUMN IF NOT EXISTS oxigeno_pct NUMERIC,
  ADD COLUMN IF NOT EXISTS ph NUMERIC,
  ADD COLUMN IF NOT EXISTS temperatura NUMERIC,
  ADD COLUMN IF NOT EXISTS amonio_mg_l NUMERIC,
  ADD COLUMN IF NOT EXISTS nitritos_mg_l NUMERIC,
  ADD COLUMN IF NOT EXISTS nitratos_mg_l NUMERIC,
  ADD COLUMN IF NOT EXISTS fosforo_mg_l NUMERIC,
  ADD COLUMN IF NOT EXISTS alcalinidad_mg_l NUMERIC,
  ADD COLUMN IF NOT EXISTS dureza_mg_l NUMERIC,
  ADD COLUMN IF NOT EXISTS cloro_mg_l NUMERIC,
  ADD COLUMN IF NOT EXISTS co2_mg_l NUMERIC,
  ADD COLUMN IF NOT EXISTS unidad_acuicola_sigla TEXT,
  ADD COLUMN IF NOT EXISTS creado_en TIMESTAMPTZ DEFAULT timezone('utc'::text, now());

-- Attach auto-inherit tenant context trigger
DROP TRIGGER IF EXISTS trg_parametros_calidad_agua_tenant ON public.parametros_calidad_agua;
CREATE TRIGGER trg_parametros_calidad_agua_tenant
  BEFORE INSERT OR UPDATE ON public.parametros_calidad_agua
  FOR EACH ROW
  EXECUTE FUNCTION public.fn_auto_inherit_tenant_context();

-- Enable RLS
ALTER TABLE public.parametros_calidad_agua ENABLE ROW LEVEL SECURITY;

-- Tenant RLS Policies
DROP POLICY IF EXISTS parametros_calidad_agua_tenant_select ON public.parametros_calidad_agua;
CREATE POLICY parametros_calidad_agua_tenant_select ON public.parametros_calidad_agua
  FOR SELECT TO authenticated
  USING ((empresa_id = public.get_auth_empresa_id()) OR public.is_superadmin());

DROP POLICY IF EXISTS parametros_calidad_agua_tenant_modify ON public.parametros_calidad_agua;
CREATE POLICY parametros_calidad_agua_tenant_modify ON public.parametros_calidad_agua
  FOR ALL TO authenticated
  USING (
    ((empresa_id = public.get_auth_empresa_id()) AND (public.get_auth_user_role() = ANY (ARRAY['admin'::text, 'creador'::text, 'master'::text, 'tecnico'::text, 'operario'::text, 'sanitarydirector'::text]))) 
    OR public.is_superadmin()
  )
  WITH CHECK (
    ((empresa_id = public.get_auth_empresa_id()) AND (public.get_auth_user_role() = ANY (ARRAY['admin'::text, 'creador'::text, 'master'::text, 'tecnico'::text, 'operario'::text, 'sanitarydirector'::text]))) 
    OR public.is_superadmin()
  );

-- Indexes for fast query filtering by tenant, date, pond, and unit
CREATE INDEX IF NOT EXISTS idx_calidad_agua_empresa_fecha ON public.parametros_calidad_agua(empresa_id, fecha DESC);
CREATE INDEX IF NOT EXISTS idx_calidad_agua_empresa_id ON public.parametros_calidad_agua(empresa_id);
CREATE INDEX IF NOT EXISTS idx_calidad_agua_unit_id ON public.parametros_calidad_agua(unit_id);
CREATE INDEX IF NOT EXISTS idx_calidad_agua_estanque_fecha ON public.parametros_calidad_agua(estanque_id, fecha DESC);

-- Migrate historical telemetry rows from water_quality into parametros_calidad_agua
INSERT INTO public.parametros_calidad_agua (
  id,
  estanque_id,
  fecha,
  hora,
  oxigeno_mg_l,
  oxigeno_pct,
  ph,
  temperatura,
  amonio_mg_l,
  nitritos_mg_l,
  nitratos_mg_l,
  alcalinidad_mg_l,
  empresa_id,
  unit_id,
  unidad_acuicola_sigla,
  observaciones,
  creado_en
)
SELECT
  wq.id,
  COALESCE(
    (SELECT e.id FROM public.estanques e WHERE e.id = wq.estanque_id),
    (SELECT e.id FROM public.estanques e WHERE e.unit_id = wq.unit_id AND (e.nombre ILIKE '%8%' OR e.sigla ILIKE '%8%') LIMIT 1),
    (SELECT e.id FROM public.estanques e WHERE e.unit_id = wq.unit_id LIMIT 1),
    (SELECT e.id FROM public.estanques e LIMIT 1)
  ) AS estanque_id,
  (wq.date::text || ' ' || COALESCE(wq.hour::text, '00:00:00'))::timestamptz AS fecha,
  wq.hour,
  wq.o2_mg_l,
  wq.o2_perc,
  wq.ph,
  wq.temperature_c,
  COALESCE(wq.ammonia_mg_l, wq.ammonia),
  COALESCE(wq.nitrite_mg_l, wq.nitrite),
  COALESCE(wq.nitrate_mg_l, wq.nitrate),
  wq.alkalinity,
  COALESCE(
    wq.empresa_id,
    (SELECT e.empresa_id FROM public.estanques e WHERE e.id = wq.estanque_id),
    (SELECT u.empresa_id FROM public.units u WHERE u.id = wq.unit_id),
    '3500cc63-5477-4f83-b4a3-7758b7cd6509'::uuid
  ) AS empresa_id,
  COALESCE(wq.unit_id, '3500cc63-5477-4f83-b4a3-7758b7cd6509'::uuid) AS unit_id,
  COALESCE(
    (SELECT e.unidad_acuicola_sigla FROM public.estanques e WHERE e.id = wq.estanque_id),
    (SELECT u.sigla FROM public.units u WHERE u.id = wq.unit_id),
    'PISC'
  ) AS unidad_acuicola_sigla,
  'Migrado desde telemetria water_quality' AS observaciones,
  COALESCE(wq.created_at, timezone('utc'::text, now())) AS creado_en
FROM public.water_quality wq
WHERE NOT EXISTS (
  SELECT 1 FROM public.parametros_calidad_agua pca WHERE pca.id = wq.id
);


-- ------------------------------------------------------------------------------
-- 2. Table: alimentacion_diaria (Daily Feeding Table)
-- ------------------------------------------------------------------------------

-- Ensure tenant columns, unit references, and insumo references
ALTER TABLE public.alimentacion_diaria
  ADD COLUMN IF NOT EXISTS empresa_id UUID REFERENCES public.empresas(id) ON DELETE CASCADE,
  ADD COLUMN IF NOT EXISTS unit_id UUID REFERENCES public.units(id) ON DELETE SET NULL,
  ADD COLUMN IF NOT EXISTS unidad_acuicola_id UUID REFERENCES public.units(id) ON DELETE SET NULL,
  ADD COLUMN IF NOT EXISTS insumo_id UUID;

-- Attach auto-inherit tenant context trigger
DROP TRIGGER IF EXISTS trg_alimentacion_diaria_tenant ON public.alimentacion_diaria;
CREATE TRIGGER trg_alimentacion_diaria_tenant
  BEFORE INSERT OR UPDATE ON public.alimentacion_diaria
  FOR EACH ROW
  EXECUTE FUNCTION public.fn_auto_inherit_tenant_context();

-- Enable RLS
ALTER TABLE public.alimentacion_diaria ENABLE ROW LEVEL SECURITY;

-- Tenant RLS Policies
DROP POLICY IF EXISTS alimentacion_diaria_tenant_select ON public.alimentacion_diaria;
CREATE POLICY alimentacion_diaria_tenant_select ON public.alimentacion_diaria
  FOR SELECT TO authenticated
  USING ((empresa_id = public.get_auth_empresa_id()) OR public.is_superadmin());

DROP POLICY IF EXISTS alimentacion_diaria_tenant_modify ON public.alimentacion_diaria;
CREATE POLICY alimentacion_diaria_tenant_modify ON public.alimentacion_diaria
  FOR ALL TO authenticated
  USING (
    ((empresa_id = public.get_auth_empresa_id()) AND (public.get_auth_user_role() = ANY (ARRAY['admin'::text, 'creador'::text, 'master'::text, 'tecnico'::text, 'operario'::text]))) 
    OR public.is_superadmin()
  )
  WITH CHECK (
    ((empresa_id = public.get_auth_empresa_id()) AND (public.get_auth_user_role() = ANY (ARRAY['admin'::text, 'creador'::text, 'master'::text, 'tecnico'::text, 'operario'::text]))) 
    OR public.is_superadmin()
  );

-- Indexes for performance
CREATE INDEX IF NOT EXISTS idx_alimentacion_empresa_fecha ON public.alimentacion_diaria(empresa_id, fecha DESC);
CREATE INDEX IF NOT EXISTS idx_alimentacion_empresa_id ON public.alimentacion_diaria(empresa_id);
CREATE INDEX IF NOT EXISTS idx_alimentacion_fecha ON public.alimentacion_diaria(fecha DESC);
CREATE INDEX IF NOT EXISTS idx_alimentacion_estanque_fecha ON public.alimentacion_diaria(estanque_id, fecha DESC);
CREATE INDEX IF NOT EXISTS idx_alimentacion_unit_id ON public.alimentacion_diaria(unit_id);


-- ------------------------------------------------------------------------------
-- 3. Table: biometrias (Fish Sampling / Biometrics Table)
-- ------------------------------------------------------------------------------

-- Ensure full schema compatibility
ALTER TABLE public.biometrias
  ADD COLUMN IF NOT EXISTS empresa_id UUID REFERENCES public.empresas(id) ON DELETE CASCADE,
  ADD COLUMN IF NOT EXISTS unit_id UUID REFERENCES public.units(id) ON DELETE SET NULL,
  ADD COLUMN IF NOT EXISTS unidad_acuicola_id UUID REFERENCES public.units(id) ON DELETE SET NULL,
  ADD COLUMN IF NOT EXISTS estanque_id UUID,
  ADD COLUMN IF NOT EXISTS batch_id TEXT,
  ADD COLUMN IF NOT EXISTS lote_id UUID REFERENCES public.lotes(id) ON DELETE SET NULL,
  ADD COLUMN IF NOT EXISTS date DATE DEFAULT CURRENT_DATE,
  ADD COLUMN IF NOT EXISTS fecha TIMESTAMPTZ DEFAULT timezone('utc'::text, now()),
  ADD COLUMN IF NOT EXISTS hora TIME WITHOUT TIME ZONE,
  ADD COLUMN IF NOT EXISTS peces_capturados INTEGER,
  ADD COLUMN IF NOT EXISTS peso_total_captura_kg NUMERIC,
  ADD COLUMN IF NOT EXISTS avg_weight_gr NUMERIC DEFAULT 0,
  ADD COLUMN IF NOT EXISTS peso_promedio_g NUMERIC,
  ADD COLUMN IF NOT EXISTS total_biomass_kg NUMERIC DEFAULT 0,
  ADD COLUMN IF NOT EXISTS biomasa_parcial_kg NUMERIC,
  ADD COLUMN IF NOT EXISTS longitud_cm NUMERIC,
  ADD COLUMN IF NOT EXISTS species_name TEXT,
  ADD COLUMN IF NOT EXISTS observaciones TEXT,
  ADD COLUMN IF NOT EXISTS registrado_por TEXT,
  ADD COLUMN IF NOT EXISTS created_at TIMESTAMPTZ DEFAULT timezone('utc'::text, now());

-- Harmonize field synonyms and defaults
UPDATE public.biometrias
SET 
  peso_promedio_g = COALESCE(peso_promedio_g, avg_weight_gr),
  avg_weight_gr = COALESCE(avg_weight_gr, peso_promedio_g),
  biomasa_parcial_kg = COALESCE(biomasa_parcial_kg, total_biomass_kg),
  total_biomass_kg = COALESCE(total_biomass_kg, biomasa_parcial_kg),
  fecha = COALESCE(fecha, date::timestamptz),
  date = COALESCE(date, fecha::date)
WHERE peso_promedio_g IS NULL OR avg_weight_gr IS NULL OR biomasa_parcial_kg IS NULL OR total_biomass_kg IS NULL OR fecha IS NULL OR date IS NULL;

-- Backfill empresa_id if null
UPDATE public.biometrias b
SET empresa_id = COALESCE(
  b.empresa_id,
  (SELECT e.empresa_id FROM public.estanques e WHERE e.id = b.estanque_id LIMIT 1),
  (SELECT u.empresa_id FROM public.units u WHERE u.id = b.unit_id LIMIT 1),
  '3500cc63-5477-4f83-b4a3-7758b7cd6509'::uuid
)
WHERE b.empresa_id IS NULL;

-- Attach auto-inherit tenant context trigger
DROP TRIGGER IF EXISTS trg_biometrias_tenant ON public.biometrias;
CREATE TRIGGER trg_biometrias_tenant
  BEFORE INSERT OR UPDATE ON public.biometrias
  FOR EACH ROW
  EXECUTE FUNCTION public.fn_auto_inherit_tenant_context();

-- Enable RLS
ALTER TABLE public.biometrias ENABLE ROW LEVEL SECURITY;

-- Tenant RLS Policies
DROP POLICY IF EXISTS biometrias_tenant_select ON public.biometrias;
CREATE POLICY biometrias_tenant_select ON public.biometrias
  FOR SELECT TO authenticated
  USING ((empresa_id = public.get_auth_empresa_id()) OR public.is_superadmin());

DROP POLICY IF EXISTS biometrias_tenant_modify ON public.biometrias;
CREATE POLICY biometrias_tenant_modify ON public.biometrias
  FOR ALL TO authenticated
  USING (
    ((empresa_id = public.get_auth_empresa_id()) AND (public.get_auth_user_role() = ANY (ARRAY['admin'::text, 'creador'::text, 'master'::text, 'tecnico'::text, 'operario'::text]))) 
    OR public.is_superadmin()
  )
  WITH CHECK (
    ((empresa_id = public.get_auth_empresa_id()) AND (public.get_auth_user_role() = ANY (ARRAY['admin'::text, 'creador'::text, 'master'::text, 'tecnico'::text, 'operario'::text]))) 
    OR public.is_superadmin()
  );

-- Indexes for performance
CREATE INDEX IF NOT EXISTS idx_biometrias_empresa_date ON public.biometrias(empresa_id, date DESC);
CREATE INDEX IF NOT EXISTS idx_biometrias_empresa_fecha ON public.biometrias(empresa_id, fecha DESC);
CREATE INDEX IF NOT EXISTS idx_biometrias_empresa_lote ON public.biometrias(empresa_id, lote_id);
CREATE INDEX IF NOT EXISTS idx_biometrias_empresa_id ON public.biometrias(empresa_id);
CREATE INDEX IF NOT EXISTS idx_biometrias_estanque_id ON public.biometrias(estanque_id);
CREATE INDEX IF NOT EXISTS idx_biometrias_unit_id ON public.biometrias(unit_id);


-- ------------------------------------------------------------------------------
-- 4. Table: mortalidad (Mortality & Losses Table)
-- ------------------------------------------------------------------------------

-- Ensure full schema compatibility
ALTER TABLE public.mortalidad
  ADD COLUMN IF NOT EXISTS empresa_id UUID REFERENCES public.empresas(id) ON DELETE CASCADE,
  ADD COLUMN IF NOT EXISTS unit_id UUID REFERENCES public.units(id) ON DELETE SET NULL,
  ADD COLUMN IF NOT EXISTS unidad_acuicola_id UUID REFERENCES public.units(id) ON DELETE SET NULL,
  ADD COLUMN IF NOT EXISTS estanque_id UUID,
  ADD COLUMN IF NOT EXISTS batch_id TEXT,
  ADD COLUMN IF NOT EXISTS lote_id UUID REFERENCES public.lotes(id) ON DELETE SET NULL,
  ADD COLUMN IF NOT EXISTS siembra_id UUID,
  ADD COLUMN IF NOT EXISTS date DATE DEFAULT CURRENT_DATE,
  ADD COLUMN IF NOT EXISTS fecha TIMESTAMPTZ DEFAULT timezone('utc'::text, now()),
  ADD COLUMN IF NOT EXISTS hora TIME WITHOUT TIME ZONE,
  ADD COLUMN IF NOT EXISTS quantity INTEGER DEFAULT 0,
  ADD COLUMN IF NOT EXISTS cantidad INTEGER,
  ADD COLUMN IF NOT EXISTS cause TEXT,
  ADD COLUMN IF NOT EXISTS causa TEXT,
  ADD COLUMN IF NOT EXISTS peso_promedio_gramos NUMERIC,
  ADD COLUMN IF NOT EXISTS biomasa_perdida_kg NUMERIC,
  ADD COLUMN IF NOT EXISTS observaciones TEXT,
  ADD COLUMN IF NOT EXISTS registrado_por TEXT,
  ADD COLUMN IF NOT EXISTS created_at TIMESTAMPTZ DEFAULT timezone('utc'::text, now());

-- Harmonize field synonyms and defaults
UPDATE public.mortalidad
SET 
  cantidad = COALESCE(cantidad, quantity),
  quantity = COALESCE(quantity, cantidad, 0),
  causa = COALESCE(causa, cause),
  cause = COALESCE(cause, causa),
  fecha = COALESCE(fecha, date::timestamptz),
  date = COALESCE(date, fecha::date)
WHERE cantidad IS NULL OR quantity IS NULL OR causa IS NULL OR cause IS NULL OR fecha IS NULL OR date IS NULL;

-- Backfill empresa_id for the 7 historical mortality rows
UPDATE public.mortalidad m
SET empresa_id = COALESCE(
  m.empresa_id,
  (SELECT e.empresa_id FROM public.estanques e WHERE e.id = m.estanque_id LIMIT 1),
  (SELECT u.empresa_id FROM public.units u WHERE u.id = m.unit_id LIMIT 1),
  '3500cc63-5477-4f83-b4a3-7758b7cd6509'::uuid
)
WHERE m.empresa_id IS NULL;

-- Attach auto-inherit tenant context trigger
DROP TRIGGER IF EXISTS trg_mortalidad_tenant ON public.mortalidad;
CREATE TRIGGER trg_mortalidad_tenant
  BEFORE INSERT OR UPDATE ON public.mortalidad
  FOR EACH ROW
  EXECUTE FUNCTION public.fn_auto_inherit_tenant_context();

-- Enable RLS
ALTER TABLE public.mortalidad ENABLE ROW LEVEL SECURITY;

-- Tenant RLS Policies
DROP POLICY IF EXISTS mortalidad_tenant_select ON public.mortalidad;
CREATE POLICY mortalidad_tenant_select ON public.mortalidad
  FOR SELECT TO authenticated
  USING ((empresa_id = public.get_auth_empresa_id()) OR public.is_superadmin());

DROP POLICY IF EXISTS mortalidad_tenant_modify ON public.mortalidad;
CREATE POLICY mortalidad_tenant_modify ON public.mortalidad
  FOR ALL TO authenticated
  USING (
    ((empresa_id = public.get_auth_empresa_id()) AND (public.get_auth_user_role() = ANY (ARRAY['admin'::text, 'creador'::text, 'master'::text, 'tecnico'::text, 'operario'::text]))) 
    OR public.is_superadmin()
  )
  WITH CHECK (
    ((empresa_id = public.get_auth_empresa_id()) AND (public.get_auth_user_role() = ANY (ARRAY['admin'::text, 'creador'::text, 'master'::text, 'tecnico'::text, 'operario'::text]))) 
    OR public.is_superadmin()
  );

-- Indexes for performance
CREATE INDEX IF NOT EXISTS idx_mortalidad_empresa_date ON public.mortalidad(empresa_id, date DESC);
CREATE INDEX IF NOT EXISTS idx_mortalidad_empresa_fecha ON public.mortalidad(empresa_id, fecha DESC);
CREATE INDEX IF NOT EXISTS idx_mortalidad_empresa_id ON public.mortalidad(empresa_id);
CREATE INDEX IF NOT EXISTS idx_mortalidad_estanque_id ON public.mortalidad(estanque_id);
CREATE INDEX IF NOT EXISTS idx_mortalidad_unit_id ON public.mortalidad(unit_id);
CREATE INDEX IF NOT EXISTS idx_mortalidad_lote_id ON public.mortalidad(lote_id);


-- ------------------------------------------------------------------------------
-- 5. Safe Deprecation of Legacy Tables
-- ------------------------------------------------------------------------------

DO $$
BEGIN
  IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema = 'public' AND table_name = 'calidad_agua') THEN
    COMMENT ON TABLE public.calidad_agua IS 'DEPRECATED: Use public.parametros_calidad_agua as the canonical table for water quality.';
  END IF;
  IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema = 'public' AND table_name = 'water_quality') THEN
    COMMENT ON TABLE public.water_quality IS 'DEPRECATED: Telemetry data migrated to public.parametros_calidad_agua.';
  END IF;
  IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema = 'public' AND table_name = 'mortality') THEN
    COMMENT ON TABLE public.mortality IS 'DEPRECATED: Use public.mortalidad as the canonical mortality table.';
  END IF;
END $$;

COMMIT;
