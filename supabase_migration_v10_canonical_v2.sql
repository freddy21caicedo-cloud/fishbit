-- =====================================================================================
-- FISHBIT V2.0 - FIX FOR ERROR 42703: COLUMN "empresa_id" DOES NOT EXIST
-- Fully idempotent migration that adds missing columns to ALL existing tables first
-- =====================================================================================

-- 1. EXTENSIONS
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- 2. CREATE EMPRESAS TABLE IF NOT EXISTS
CREATE TABLE IF NOT EXISTS public.empresas (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    nombre TEXT NOT NULL DEFAULT 'Empresa Principal',
    nit TEXT,
    logo_url TEXT,
    moneda TEXT DEFAULT 'COP',
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Si no hay ninguna empresa, insertar una por defecto
INSERT INTO public.empresas (id, nombre, nit)
VALUES ('c1000000-0000-0000-0000-000000000001', 'Piscícola Del Caribe S.A.S.', '901.458.723-1')
ON CONFLICT (id) DO NOTHING;

-- 3. AGREGAR COLUMNA empresa_id DE FORMA SEGURA A TODAS LAS TABLAS EXISTENTES
ALTER TABLE public.profiles ADD COLUMN IF NOT EXISTS empresa_id UUID REFERENCES public.empresas(id) ON DELETE CASCADE;
ALTER TABLE public.profiles ADD COLUMN IF NOT EXISTS phone TEXT;
ALTER TABLE public.profiles ADD COLUMN IF NOT EXISTS avatar_url TEXT;
ALTER TABLE public.profiles ADD COLUMN IF NOT EXISTS role TEXT DEFAULT 'operario';
ALTER TABLE public.profiles ADD COLUMN IF NOT EXISTS is_superadmin BOOLEAN DEFAULT false;

ALTER TABLE public.units ADD COLUMN IF NOT EXISTS empresa_id UUID REFERENCES public.empresas(id) ON DELETE CASCADE;
ALTER TABLE public.units ADD COLUMN IF NOT EXISTS sigla TEXT;

ALTER TABLE public.estanques ADD COLUMN IF NOT EXISTS empresa_id UUID REFERENCES public.empresas(id) ON DELETE CASCADE;
ALTER TABLE public.estanques ADD COLUMN IF NOT EXISTS unit_id UUID REFERENCES public.units(id) ON DELETE CASCADE;

-- Tablas que pueden existir previamente y necesitan empresa_id
DO $$
BEGIN
    -- inventory
    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'inventory') THEN
        ALTER TABLE public.inventory ADD COLUMN IF NOT EXISTS empresa_id UUID REFERENCES public.empresas(id) ON DELETE CASCADE;
        ALTER TABLE public.inventory ADD COLUMN IF NOT EXISTS unit_id UUID REFERENCES public.units(id) ON DELETE SET NULL;
        ALTER TABLE public.inventory ADD COLUMN IF NOT EXISTS proteina_pct NUMERIC;
        ALTER TABLE public.inventory ADD COLUMN IF NOT EXISTS calibre_mm NUMERIC;
        ALTER TABLE public.inventory ADD COLUMN IF NOT EXISTS potencia_hp NUMERIC;
        ALTER TABLE public.inventory ADD COLUMN IF NOT EXISTS fase_electrica TEXT;
        ALTER TABLE public.inventory ADD COLUMN IF NOT EXISTS dias_retiro_sanitario INT DEFAULT 0;
        ALTER TABLE public.inventory ADD COLUMN IF NOT EXISTS principio_activo TEXT;
        ALTER TABLE public.inventory ADD COLUMN IF NOT EXISTS lote_fabricante TEXT;
        ALTER TABLE public.inventory ADD COLUMN IF NOT EXISTS stock_minimo_alerta NUMERIC DEFAULT 200.0;
        ALTER TABLE public.inventory ADD COLUMN IF NOT EXISTS costo_unitario_historico NUMERIC DEFAULT 0.0;
    ELSE
        CREATE TABLE public.inventory (
            id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
            empresa_id UUID REFERENCES public.empresas(id) ON DELETE CASCADE,
            unit_id UUID REFERENCES public.units(id) ON DELETE SET NULL,
            category TEXT NOT NULL,
            name TEXT NOT NULL,
            brand TEXT,
            presentation_unit TEXT DEFAULT 'Kg',
            current_stock NUMERIC NOT NULL DEFAULT 0.0,
            costo_unitario_historico NUMERIC NOT NULL DEFAULT 0.0,
            costo_total NUMERIC NOT NULL DEFAULT 0.0,
            stock_minimo_alerta NUMERIC DEFAULT 200.0,
            proteina_pct NUMERIC,
            calibre_mm NUMERIC,
            potencia_hp NUMERIC,
            fase_electrica TEXT,
            estanque_asignado_id UUID,
            dias_retiro_sanitario INT DEFAULT 0,
            principio_activo TEXT,
            lote_fabricante TEXT,
            fecha_vencimiento DATE,
            last_entry TIMESTAMPTZ DEFAULT NOW(),
            updated_at TIMESTAMPTZ DEFAULT NOW(),
            created_at TIMESTAMPTZ DEFAULT NOW()
        );
    END IF;

    -- providers
    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'providers') THEN
        ALTER TABLE public.providers ADD COLUMN IF NOT EXISTS empresa_id UUID REFERENCES public.empresas(id) ON DELETE CASCADE;
        ALTER TABLE public.providers ADD COLUMN IF NOT EXISTS phone TEXT;
        ALTER TABLE public.providers ADD COLUMN IF NOT EXISTS city TEXT;
        ALTER TABLE public.providers ADD COLUMN IF NOT EXISTS category_primary TEXT DEFAULT 'concentrados';
    ELSE
        CREATE TABLE public.providers (
            id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
            empresa_id UUID REFERENCES public.empresas(id) ON DELETE CASCADE,
            unit_id UUID REFERENCES public.units(id) ON DELETE SET NULL,
            name TEXT NOT NULL,
            nit TEXT,
            phone TEXT,
            city TEXT,
            category_primary TEXT DEFAULT 'concentrados',
            types TEXT[],
            created_at TIMESTAMPTZ DEFAULT NOW()
        );
    END IF;

    -- siembras
    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'siembras') THEN
        ALTER TABLE public.siembras ADD COLUMN IF NOT EXISTS empresa_id UUID REFERENCES public.empresas(id) ON DELETE CASCADE;
    ELSE
        CREATE TABLE public.siembras (
            id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
            empresa_id UUID REFERENCES public.empresas(id) ON DELETE CASCADE,
            unit_id UUID REFERENCES public.units(id) ON DELETE CASCADE,
            estanque_id UUID REFERENCES public.estanques(id) ON DELETE CASCADE,
            batch_code TEXT,
            date DATE NOT NULL DEFAULT CURRENT_DATE,
            hour TIME DEFAULT CURRENT_TIME,
            total_quantity INT NOT NULL DEFAULT 0,
            total_biomass_kg NUMERIC NOT NULL DEFAULT 0.0,
            status VARCHAR(50) DEFAULT 'activo',
            parent_siembra_id UUID REFERENCES public.siembras(id),
            costo_inicial_heredado NUMERIC DEFAULT 0.0,
            biomasa_inicial_heredada NUMERIC DEFAULT 0.0,
            created_at TIMESTAMPTZ DEFAULT NOW(),
            updated_at TIMESTAMPTZ DEFAULT NOW()
        );
    END IF;

    -- siembra_details
    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'siembra_details') THEN
        ALTER TABLE public.siembra_details ADD COLUMN IF NOT EXISTS empresa_id UUID REFERENCES public.empresas(id) ON DELETE CASCADE;
    ELSE
        CREATE TABLE public.siembra_details (
            id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
            empresa_id UUID REFERENCES public.empresas(id) ON DELETE CASCADE,
            siembra_id UUID NOT NULL REFERENCES public.siembras(id) ON DELETE CASCADE,
            species_name TEXT NOT NULL,
            rol_policultivo TEXT DEFAULT 'principal',
            quantity INT NOT NULL DEFAULT 0,
            avg_weight_gr NUMERIC NOT NULL DEFAULT 1.0,
            biomass_kg NUMERIC NOT NULL DEFAULT 0.0,
            inventory_item_id UUID,
            costo_unitario_alevino NUMERIC DEFAULT 0.0,
            costo_total_lote NUMERIC DEFAULT 0.0,
            created_at TIMESTAMPTZ DEFAULT NOW()
        );
    END IF;


    -- water_quality
    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'water_quality') THEN
        ALTER TABLE public.water_quality ADD COLUMN IF NOT EXISTS empresa_id UUID REFERENCES public.empresas(id) ON DELETE CASCADE;
    ELSE
        CREATE TABLE public.water_quality (
            id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
            empresa_id UUID REFERENCES public.empresas(id) ON DELETE CASCADE,
            unit_id UUID REFERENCES public.units(id) ON DELETE CASCADE,
            estanque_id UUID NOT NULL REFERENCES public.estanques(id) ON DELETE CASCADE,
            date DATE NOT NULL DEFAULT CURRENT_DATE,
            hour TIME DEFAULT CURRENT_TIME,
            o2_mg_l NUMERIC,
            o2_perc NUMERIC,
            temperature_c NUMERIC,
            ph NUMERIC,
            ammonia_mg_l NUMERIC,
            nitrite_mg_l NUMERIC,
            nitrate_mg_l NUMERIC,
            alkalinity NUMERIC,
            created_at TIMESTAMPTZ DEFAULT NOW()
        );
    END IF;

    -- biometrias
    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'biometrias') THEN
        ALTER TABLE public.biometrias ADD COLUMN IF NOT EXISTS empresa_id UUID REFERENCES public.empresas(id) ON DELETE CASCADE;
    ELSE
        CREATE TABLE public.biometrias (
            id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
            empresa_id UUID REFERENCES public.empresas(id) ON DELETE CASCADE,
            unit_id UUID REFERENCES public.units(id) ON DELETE CASCADE,
            estanque_id UUID NOT NULL REFERENCES public.estanques(id) ON DELETE CASCADE,
            siembra_id UUID REFERENCES public.siembras(id) ON DELETE SET NULL,
            species_name TEXT,
            batch_id TEXT,
            date DATE NOT NULL DEFAULT CURRENT_DATE,
            avg_weight_gr NUMERIC NOT NULL,
            total_biomass_kg NUMERIC NOT NULL,
            peces_muestreados INT DEFAULT 30,
            k_fulton NUMERIC,
            gdp_g_dia NUMERIC,
            created_at TIMESTAMPTZ DEFAULT NOW()
        );
    END IF;

    -- mortality
    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'mortality') THEN
        ALTER TABLE public.mortality ADD COLUMN IF NOT EXISTS empresa_id UUID REFERENCES public.empresas(id) ON DELETE CASCADE;
    ELSE
        CREATE TABLE public.mortality (
            id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
            empresa_id UUID REFERENCES public.empresas(id) ON DELETE CASCADE,
            unit_id UUID REFERENCES public.units(id) ON DELETE CASCADE,
            estanque_id UUID NOT NULL REFERENCES public.estanques(id) ON DELETE CASCADE,
            siembra_id UUID REFERENCES public.siembras(id) ON DELETE SET NULL,
            species_name TEXT,
            batch_id TEXT,
            date DATE NOT NULL DEFAULT CURRENT_DATE,
            quantity INT NOT NULL,
            cause TEXT,
            biomass_lost_kg NUMERIC,
            created_at TIMESTAMPTZ DEFAULT NOW()
        );
    END IF;
END $$;

-- 4. FUNCIONES HELPER RLS
CREATE OR REPLACE FUNCTION public.get_auth_empresa_id()
RETURNS UUID AS $$
  SELECT empresa_id FROM public.profiles WHERE id = auth.uid() LIMIT 1;
$$ LANGUAGE SQL STABLE SECURITY DEFINER;

CREATE OR REPLACE FUNCTION public.is_superadmin()
RETURNS BOOLEAN AS $$
  SELECT COALESCE(is_superadmin, false) OR role = 'creador' FROM public.profiles WHERE id = auth.uid() LIMIT 1;
$$ LANGUAGE SQL STABLE SECURITY DEFINER;

-- 5. RE-APLICAR RLS DE FORMA SEGURA
ALTER TABLE public.empresas ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.units ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.estanques ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.inventory ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.providers ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.siembras ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.siembra_details ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.water_quality ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.biometrias ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.mortality ENABLE ROW LEVEL SECURITY;

-- Eliminar políticas viejas si existen
DROP POLICY IF EXISTS "profiles_tenant_isolation" ON public.profiles;
DROP POLICY IF EXISTS "units_tenant_isolation" ON public.units;
DROP POLICY IF EXISTS "estanques_tenant_isolation" ON public.estanques;
DROP POLICY IF EXISTS "inventory_tenant_isolation" ON public.inventory;
DROP POLICY IF EXISTS "providers_tenant_isolation" ON public.providers;
DROP POLICY IF EXISTS "siembras_tenant_isolation" ON public.siembras;
DROP POLICY IF EXISTS "siembra_details_tenant_isolation" ON public.siembra_details;
DROP POLICY IF EXISTS "water_quality_tenant_isolation" ON public.water_quality;
DROP POLICY IF EXISTS "biometrias_tenant_isolation" ON public.biometrias;
DROP POLICY IF EXISTS "mortality_tenant_isolation" ON public.mortality;

-- Crear políticas limpias
CREATE POLICY "profiles_tenant_isolation" ON public.profiles
FOR ALL TO authenticated
USING (id = auth.uid() OR empresa_id = public.get_auth_empresa_id() OR public.is_superadmin())
WITH CHECK (id = auth.uid() OR empresa_id = public.get_auth_empresa_id() OR public.is_superadmin());

CREATE POLICY "units_tenant_isolation" ON public.units
FOR ALL TO authenticated
USING (empresa_id = public.get_auth_empresa_id() OR public.is_superadmin())
WITH CHECK (empresa_id = public.get_auth_empresa_id() OR public.is_superadmin());

CREATE POLICY "estanques_tenant_isolation" ON public.estanques
FOR ALL TO authenticated
USING (empresa_id = public.get_auth_empresa_id() OR public.is_superadmin())
WITH CHECK (empresa_id = public.get_auth_empresa_id() OR public.is_superadmin());

CREATE POLICY "inventory_tenant_isolation" ON public.inventory
FOR ALL TO authenticated
USING (empresa_id = public.get_auth_empresa_id() OR public.is_superadmin())
WITH CHECK (empresa_id = public.get_auth_empresa_id() OR public.is_superadmin());

CREATE POLICY "providers_tenant_isolation" ON public.providers
FOR ALL TO authenticated
USING (empresa_id = public.get_auth_empresa_id() OR public.is_superadmin())
WITH CHECK (empresa_id = public.get_auth_empresa_id() OR public.is_superadmin());

CREATE POLICY "siembras_tenant_isolation" ON public.siembras
FOR ALL TO authenticated
USING (empresa_id = public.get_auth_empresa_id() OR public.is_superadmin())
WITH CHECK (empresa_id = public.get_auth_empresa_id() OR public.is_superadmin());

CREATE POLICY "siembra_details_tenant_isolation" ON public.siembra_details
FOR ALL TO authenticated
USING (
  empresa_id = public.get_auth_empresa_id() OR public.is_superadmin()
  OR EXISTS (
    SELECT 1 FROM public.siembras s
    WHERE s.id = siembra_details.siembra_id
      AND (s.empresa_id = public.get_auth_empresa_id() OR public.is_superadmin())
  )
)
WITH CHECK (
  empresa_id = public.get_auth_empresa_id() OR public.is_superadmin()
  OR EXISTS (
    SELECT 1 FROM public.siembras s
    WHERE s.id = siembra_details.siembra_id
      AND (s.empresa_id = public.get_auth_empresa_id() OR public.is_superadmin())
  )
);

CREATE POLICY "water_quality_tenant_isolation" ON public.water_quality
FOR ALL TO authenticated
USING (empresa_id = public.get_auth_empresa_id() OR public.is_superadmin())
WITH CHECK (empresa_id = public.get_auth_empresa_id() OR public.is_superadmin());

CREATE POLICY "biometrias_tenant_isolation" ON public.biometrias
FOR ALL TO authenticated
USING (empresa_id = public.get_auth_empresa_id() OR public.is_superadmin())
WITH CHECK (empresa_id = public.get_auth_empresa_id() OR public.is_superadmin());

CREATE POLICY "mortality_tenant_isolation" ON public.mortality
FOR ALL TO authenticated
USING (empresa_id = public.get_auth_empresa_id() OR public.is_superadmin())
WITH CHECK (empresa_id = public.get_auth_empresa_id() OR public.is_superadmin());

-- 6. PROTECCIÓN CONTRA ESCALADA DE PRIVILEGIOS EN PROFILES (SEC-01)
CREATE OR REPLACE FUNCTION public.trg_protect_profile_privileges()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
BEGIN
  IF TG_OP = 'INSERT' THEN
    -- Al insertar un perfil nuevo:
    -- Si el llamador no es superadministrador ni creador
    IF NOT (SELECT public.is_superadmin()) THEN
      -- Forzar que is_superadmin sea falso
      NEW.is_superadmin := false;
      -- Bloquear cualquier intento de auto-asignarse roles privilegiados
      IF NEW.role IN ('master', 'creador') THEN
        RAISE EXCEPTION 'FishBit Security Violation (SEC-01): No posee autorización para asignar roles de alta jerarquía o privilegios de superadministrador.'
          USING ERRCODE = '42501';
      END IF;
    END IF;
    RETURN NEW;
  ELSIF TG_OP = 'UPDATE' THEN
    -- Si el usuario intenta cambiar su propio rol, estatus de superadministrador o empresa asignada
    IF (NEW.role IS DISTINCT FROM OLD.role 
        OR NEW.is_superadmin IS DISTINCT FROM OLD.is_superadmin 
        OR NEW.empresa_id IS DISTINCT FROM OLD.empresa_id) THEN
      -- Solo un superadministrador/creador autenticado puede alterar estos campos privilegiados
      IF NOT (SELECT public.is_superadmin()) THEN
        RAISE EXCEPTION 'FishBit Security Violation (SEC-01): No posee autorización para alterar roles, empresa asignada o privilegios de superadministrador.'
          USING ERRCODE = '42501';
      END IF;
    END IF;
    RETURN NEW;
  END IF;
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_enforce_profile_privilege_protection ON public.profiles;
CREATE TRIGGER trg_enforce_profile_privilege_protection
  BEFORE INSERT OR UPDATE ON public.profiles
  FOR EACH ROW
  EXECUTE FUNCTION public.trg_protect_profile_privileges();

