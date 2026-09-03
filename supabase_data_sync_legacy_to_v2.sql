-- =====================================================================================
-- FISHBIT V2.0 - DATA SYNC & LEGACY MIGRATION SCRIPT (ROBUST & CANONICAL)
-- Exact column matching for siembras (batch_id), providers, inventory, and water_quality.
-- =====================================================================================

-- 1. ASEGURAR COLUMNAS EN public.inventory
ALTER TABLE public.inventory ADD COLUMN IF NOT EXISTS created_at TIMESTAMPTZ DEFAULT NOW();
ALTER TABLE public.inventory ADD COLUMN IF NOT EXISTS updated_at TIMESTAMPTZ DEFAULT NOW();
ALTER TABLE public.inventory ADD COLUMN IF NOT EXISTS last_entry TIMESTAMPTZ DEFAULT NOW();
ALTER TABLE public.inventory ADD COLUMN IF NOT EXISTS costo_total NUMERIC DEFAULT 0.0;
ALTER TABLE public.inventory ADD COLUMN IF NOT EXISTS costo_unitario_historico NUMERIC DEFAULT 0.0;
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

-- 2. ASEGURAR COLUMNAS EN public.providers
ALTER TABLE public.providers ADD COLUMN IF NOT EXISTS created_at TIMESTAMPTZ DEFAULT NOW();
ALTER TABLE public.providers ADD COLUMN IF NOT EXISTS empresa_id UUID REFERENCES public.empresas(id) ON DELETE CASCADE;
ALTER TABLE public.providers ADD COLUMN IF NOT EXISTS unit_id UUID REFERENCES public.units(id) ON DELETE SET NULL;
ALTER TABLE public.providers ADD COLUMN IF NOT EXISTS phone TEXT;
ALTER TABLE public.providers ADD COLUMN IF NOT EXISTS city TEXT;
ALTER TABLE public.providers ADD COLUMN IF NOT EXISTS category_primary TEXT DEFAULT 'concentrados';
ALTER TABLE public.providers ADD COLUMN IF NOT EXISTS types TEXT[];

-- 3. ASEGURAR COLUMNAS EN public.siembras
ALTER TABLE public.siembras ADD COLUMN IF NOT EXISTS created_at TIMESTAMPTZ DEFAULT NOW();
ALTER TABLE public.siembras ADD COLUMN IF NOT EXISTS empresa_id UUID REFERENCES public.empresas(id) ON DELETE CASCADE;
ALTER TABLE public.siembras ADD COLUMN IF NOT EXISTS unit_id UUID REFERENCES public.units(id) ON DELETE CASCADE;
ALTER TABLE public.siembras ADD COLUMN IF NOT EXISTS batch_id TEXT;
ALTER TABLE public.siembras ADD COLUMN IF NOT EXISTS batch_code TEXT;

-- 4. ASEGURAR COLUMNAS EN public.siembra_details
ALTER TABLE public.siembra_details ADD COLUMN IF NOT EXISTS rol_policultivo TEXT DEFAULT 'principal';
ALTER TABLE public.siembra_details ADD COLUMN IF NOT EXISTS costo_unitario_alevino NUMERIC DEFAULT 0.0;
ALTER TABLE public.siembra_details ADD COLUMN IF NOT EXISTS costo_total_lote NUMERIC DEFAULT 0.0;

-- 5. ASEGURAR COLUMNAS EN public.water_quality
ALTER TABLE public.water_quality ADD COLUMN IF NOT EXISTS created_at TIMESTAMPTZ DEFAULT NOW();
ALTER TABLE public.water_quality ADD COLUMN IF NOT EXISTS empresa_id UUID REFERENCES public.empresas(id) ON DELETE CASCADE;
ALTER TABLE public.water_quality ADD COLUMN IF NOT EXISTS unit_id UUID REFERENCES public.units(id) ON DELETE CASCADE;

-- 6. BLOQUE DE MIGRACIÓN Y COPIA DE DATOS
DO $$
DECLARE
    default_empresa_id UUID := 'c1000000-0000-0000-0000-000000000001';
    default_unit_id UUID;
BEGIN
    -- A. Asegurar Empresa Principal
    INSERT INTO public.empresas (id, nombre, nit)
    VALUES (default_empresa_id, 'Piscícola Del Caribe S.A.S.', '901.458.723-1')
    ON CONFLICT (id) DO NOTHING;

    -- B. Asegurar Sede / Unit Principal
    SELECT id INTO default_unit_id FROM public.units LIMIT 1;
    IF default_unit_id IS NULL THEN
        default_unit_id := 'u1000000-0000-0000-0000-000000000001';
        INSERT INTO public.units (id, empresa_id, name, sigla, location)
        VALUES (default_unit_id, default_empresa_id, 'Sede Principal Caribe', 'CAR', 'Barranquilla, Atlántico')
        ON CONFLICT (id) DO NOTHING;
    ELSE
        UPDATE public.units SET empresa_id = default_empresa_id WHERE empresa_id IS NULL;
    END IF;

    -- C. Vincular Profiles a la Empresa
    UPDATE public.profiles SET empresa_id = default_empresa_id WHERE empresa_id IS NULL;

    -- D. Actualizar Estanques existentes con empresa_id y unit_id
    UPDATE public.estanques 
    SET empresa_id = default_empresa_id, unit_id = default_unit_id 
    WHERE empresa_id IS NULL;

    -- E. MIGRAR INVENTARIO
    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'inventario_insumos') THEN
        INSERT INTO public.inventory (
            id,
            empresa_id,
            unit_id,
            category,
            name,
            current_stock,
            costo_unitario_historico,
            costo_total,
            created_at
        )
        SELECT 
            inv.id,
            default_empresa_id,
            default_unit_id,
            CASE 
                WHEN inv.tipo ILIKE '%alimento%' OR inv.tipo ILIKE '%concentrado%' THEN 'concentrado'
                WHEN inv.tipo ILIKE '%alevin%' THEN 'alevino'
                WHEN inv.tipo ILIKE '%oxigen%' OR inv.tipo ILIKE '%equipo%' THEN 'oxigenador'
                WHEN inv.tipo ILIKE '%farm%' OR inv.tipo ILIKE '%medic%' THEN 'farmacia'
                ELSE 'insumo'
            END,
            inv.nombre,
            COALESCE(inv.cantidad_actual_kg, 0.0),
            COALESCE(inv.costo_unitario_historico, 0.0),
            COALESCE(inv.costo_total, 0.0),
            COALESCE(inv.creado_en, NOW())
        FROM public.inventario_insumos inv
        WHERE NOT EXISTS (SELECT 1 FROM public.inventory i WHERE i.id = inv.id);
    END IF;

    -- F. MIGRAR PROVEEDORES
    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'proveedores') THEN
        INSERT INTO public.providers (
            id,
            empresa_id,
            unit_id,
            name,
            nit,
            category_primary,
            types,
            created_at
        )
        SELECT 
            p.id,
            default_empresa_id,
            default_unit_id,
            p.nombre,
            p.nit,
            COALESCE(p.tipo, 'concentrados'),
            ARRAY[COALESCE(p.tipo, 'concentrados')],
            COALESCE(p.creado_en, NOW())
        FROM public.proveedores p
        WHERE NOT EXISTS (
            SELECT 1 FROM public.providers ex 
            WHERE ex.id = p.id OR (p.nit IS NOT NULL AND ex.nit = p.nit AND ex.unit_id = default_unit_id)
        );
    END IF;

    -- G. MIGRAR CALIDAD DE AGUA
    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'parametros_calidad_agua') THEN
        INSERT INTO public.water_quality (
            id,
            empresa_id,
            unit_id,
            estanque_id,
            date,
            o2_mg_l,
            o2_perc,
            temperature_c,
            ph,
            ammonia_mg_l,
            nitrite_mg_l,
            nitrate_mg_l,
            alkalinity,
            created_at
        )
        SELECT 
            w.id,
            default_empresa_id,
            default_unit_id,
            w.estanque_id,
            w.fecha::date,
            w.oxigeno_mg_l,
            oxigeno_pct,
            w.temperatura,
            w.ph,
            w.amonio_mg_l,
            w.nitritos_mg_l,
            w.nitratos_mg_l,
            w.alcalinidad_mg_l,
            COALESCE(w.creado_en, NOW())
        FROM public.parametros_calidad_agua w
        WHERE NOT EXISTS (SELECT 1 FROM public.water_quality ex WHERE ex.id = w.id);
    END IF;

    -- H. MIGRAR LOTES: de lotes -> siembras & siembra_details (usando batch_id exacto)
    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'lotes') THEN
        INSERT INTO public.siembras (
            id,
            empresa_id,
            unit_id,
            estanque_id,
            batch_id,
            date,
            total_quantity,
            total_biomass_kg,
            status,
            costo_inicial_heredado,
            biomasa_inicial_heredada,
            created_at
        )
        SELECT 
            l.id,
            default_empresa_id,
            default_unit_id,
            l.estanque_id,
            l.codigo_lote,
            l.creado_en::date,
            COALESCE(l.cantidad_actual_peces, l.cantidad_inicial_peces, 0),
            COALESCE(l.biomasa_actual_kg, l.biomasa_inicial_kg, 0.0),
            CASE WHEN l.estado ILIKE '%inactiv%' OR l.estado ILIKE '%cosech%' THEN 'cosechado' ELSE 'activo' END,
            COALESCE(l.costo_inicial_alevines, 0.0),
            COALESCE(l.biomasa_inicial_kg, 0.0),
            COALESCE(l.creado_en, NOW())
        FROM public.lotes l
        WHERE NOT EXISTS (SELECT 1 FROM public.siembras ex WHERE ex.id = l.id);

        IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'siembra_details') THEN
            INSERT INTO public.siembra_details (
                siembra_id,
                species_name,
                rol_policultivo,
                quantity,
                avg_weight_gr,
                biomass_kg,
                costo_unitario_alevino,
                costo_total_lote,
                created_at
            )
            SELECT 
                l.id,
                COALESCE(l.especie, 'Tilapia Roja'),
                'principal',
                COALESCE(l.cantidad_actual_peces, l.cantidad_inicial_peces, 0),
                COALESCE(l.peso_inicial_gramos, 1.0),
                COALESCE(l.biomasa_actual_kg, l.biomasa_inicial_kg, 0.0),
                CASE WHEN COALESCE(l.cantidad_inicial_peces, 0) > 0 THEN COALESCE(l.costo_inicial_alevines, 0.0) / l.cantidad_inicial_peces ELSE 0.0 END,
                COALESCE(l.costo_inicial_alevines, 0.0) + COALESCE(l.costo_acumulado_insumos, 0.0),
                COALESCE(l.creado_en, NOW())
            FROM public.lotes l
            WHERE NOT EXISTS (SELECT 1 FROM public.siembra_details sd WHERE sd.siembra_id = l.id);
        END IF;
    END IF;

END $$;
