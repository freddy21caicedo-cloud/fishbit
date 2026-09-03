-- ============================================================================
-- FISHBIT FINANCE 2.0 - CANONICAL MODULAR MONOLITH DATABASE SCHEMA
-- Conforme a las directrices de Supabase Postgres Best Practices y Multi-Tenant Isolation
-- ============================================================================

CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "pgcrypto";

-- ─── 1. EMPRESAS (INQUILINO / TENANT MASTER) ────────────────────────────────
CREATE TABLE IF NOT EXISTS public.empresas (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    nombre_comercial TEXT NOT NULL,
    razon_social TEXT NOT NULL,
    nit TEXT NOT NULL UNIQUE,
    direccion TEXT,
    telefono TEXT,
    moneda TEXT NOT NULL DEFAULT 'COP',
    tarifa_energia_kwh NUMERIC NOT NULL DEFAULT 850.0,
    limite_mortalidad_critica NUMERIC NOT NULL DEFAULT 10.0,
    stock_alerta_minimo_alimento NUMERIC NOT NULL DEFAULT 200.0,
    precio_mercado_actual_kg NUMERIC NOT NULL DEFAULT 8500.0,
    precios_mercado_especies JSONB DEFAULT '{}'::jsonb,
    ciclos_especies_dias JSONB DEFAULT '{}'::jsonb,
    pesos_finales_especies_g JSONB DEFAULT '{}'::jsonb,
    logo_url TEXT,
    estado_suscripcion TEXT NOT NULL DEFAULT 'Activo' CHECK (estado_suscripcion IN ('Activo', 'PendienteAprobacion', 'Suspendido')),
    creado_en TIMESTAMPTZ NOT NULL DEFAULT timezone('utc'::text, now()),
    actualizado_en TIMESTAMPTZ NOT NULL DEFAULT timezone('utc'::text, now())
);

-- ─── 2. UNIDADES ACUÍCOLAS (SEDES DE LA EMPRESA) ────────────────────────────
CREATE TABLE IF NOT EXISTS public.unidades_acuicolas (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    empresa_id UUID NOT NULL REFERENCES public.empresas(id) ON DELETE CASCADE,
    nombre TEXT NOT NULL,
    sigla TEXT NOT NULL,
    ubicacion TEXT,
    is_deleted BOOLEAN NOT NULL DEFAULT false,
    creado_en TIMESTAMPTZ NOT NULL DEFAULT timezone('utc'::text, now()),
    CONSTRAINT uq_empresa_sigla UNIQUE (empresa_id, sigla)
);
CREATE INDEX IF NOT EXISTS idx_unidades_empresa_id ON public.unidades_acuicolas(empresa_id);

-- ─── 3. MIEMBROS DE EQUIPO (RBAC Y GESTIÓN DE USUARIOS) ─────────────────────
CREATE TABLE IF NOT EXISTS public.miembros_equipo (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    auth_user_id UUID, -- Vinculación con auth.users si aplica
    empresa_id UUID REFERENCES public.empresas(id) ON DELETE CASCADE, -- NULL sólo para el Creador Master
    nombre TEXT NOT NULL,
    email TEXT NOT NULL UNIQUE,
    role TEXT NOT NULL CHECK (role IN ('Creador', 'Admin', 'Tecnico', 'Operario')),
    unidad_acuicola_id UUID REFERENCES public.unidades_acuicolas(id) ON DELETE SET NULL, -- NULL o ID para sede específica, o Admin asignado a empresa
    permiso_global_empresa BOOLEAN NOT NULL DEFAULT false, -- True para Admin de todas las sedes
    estado TEXT NOT NULL DEFAULT 'Invitado' CHECK (estado IN ('Activo', 'Invitado', 'PendienteAprobacion', 'Suspendido')),
    token_invitacion TEXT,
    token_invitacion_expira TIMESTAMPTZ,
    cedula TEXT,
    salario_base NUMERIC DEFAULT 0.0,
    periodo_pago TEXT CHECK (periodo_pago IN ('Quincenal', 'Mensual')),
    creado_en TIMESTAMPTZ NOT NULL DEFAULT timezone('utc'::text, now()),
    actualizado_en TIMESTAMPTZ NOT NULL DEFAULT timezone('utc'::text, now())
);
CREATE INDEX IF NOT EXISTS idx_miembros_empresa_id ON public.miembros_equipo(empresa_id);
CREATE INDEX IF NOT EXISTS idx_miembros_unidad_id ON public.miembros_equipo(unidad_acuicola_id);
CREATE INDEX IF NOT EXISTS idx_miembros_email ON public.miembros_equipo(email);

-- ─── 4. CLIENTES (COMPRADORES DE COSECHAS) ──────────────────────────────────
CREATE TABLE IF NOT EXISTS public.clientes (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    empresa_id UUID NOT NULL REFERENCES public.empresas(id) ON DELETE CASCADE,
    nombre TEXT NOT NULL,
    telefono TEXT,
    email TEXT,
    creado_en TIMESTAMPTZ NOT NULL DEFAULT timezone('utc'::text, now())
);
CREATE INDEX IF NOT EXISTS idx_clientes_empresa_id ON public.clientes(empresa_id);

-- ─── 5. PROVEEDORES (INSUMOS, BIOLÓGICO, EQUIPOS) ──────────────────────────
CREATE TABLE IF NOT EXISTS public.proveedores (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    empresa_id UUID NOT NULL REFERENCES public.empresas(id) ON DELETE CASCADE,
    nit TEXT NOT NULL,
    nombre TEXT NOT NULL,
    tipo TEXT NOT NULL CHECK (tipo IN ('Biologico', 'Alimento', 'Insumo', 'Farmacia', 'Equipos', 'General')),
    telefono TEXT,
    email TEXT,
    creado_en TIMESTAMPTZ NOT NULL DEFAULT timezone('utc'::text, now())
);
CREATE INDEX IF NOT EXISTS idx_proveedores_empresa_id ON public.proveedores(empresa_id);

-- ─── 6. ESTANQUES FÍSICOS ───────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS public.estanques (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    empresa_id UUID NOT NULL REFERENCES public.empresas(id) ON DELETE CASCADE,
    unidad_acuicola_id UUID NOT NULL REFERENCES public.unidades_acuicolas(id) ON DELETE RESTRICT,
    nombre TEXT NOT NULL,
    sigla TEXT NOT NULL,
    capacidad_m3 NUMERIC NOT NULL CHECK (capacidad_m3 > 0),
    largo_m NUMERIC,
    ancho_m NUMERIC,
    profundidad_m NUMERIC,
    especie_actual TEXT DEFAULT '',
    biomasa_kg NUMERIC NOT NULL DEFAULT 0.0 CHECK (biomasa_kg >= 0),
    costo_acumulado_biologico NUMERIC NOT NULL DEFAULT 0.0 CHECK (costo_acumulado_biologico >= 0),
    estado TEXT NOT NULL DEFAULT 'Disponible' CHECK (estado IN ('Activo', 'Cosechado', 'Disponible')),
    aireacion_activa BOOLEAN NOT NULL DEFAULT false,
    is_deleted BOOLEAN NOT NULL DEFAULT false,
    creado_en TIMESTAMPTZ NOT NULL DEFAULT timezone('utc'::text, now())
);
CREATE INDEX IF NOT EXISTS idx_estanques_empresa_id ON public.estanques(empresa_id);
CREATE INDEX IF NOT EXISTS idx_estanques_unidad_id ON public.estanques(unidad_acuicola_id);

-- ─── 7. LOTES DE PECES (CENTROS DE COSTO MÓVILES) ───────────────────────────
CREATE TABLE IF NOT EXISTS public.lotes (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    empresa_id UUID NOT NULL REFERENCES public.empresas(id) ON DELETE CASCADE,
    unidad_acuicola_id UUID NOT NULL REFERENCES public.unidades_acuicolas(id) ON DELETE RESTRICT,
    estanque_id UUID NOT NULL REFERENCES public.estanques(id) ON DELETE RESTRICT,
    lote_padre_id UUID REFERENCES public.lotes(id) ON DELETE SET NULL,
    codigo_lote TEXT NOT NULL,
    especie TEXT NOT NULL,
    cantidad_inicial_peces INTEGER NOT NULL CHECK (cantidad_inicial_peces > 0),
    cantidad_actual_peces INTEGER NOT NULL CHECK (cantidad_actual_peces >= 0),
    peso_inicial_gramos NUMERIC NOT NULL DEFAULT 1.0,
    peso_actual_gramos NUMERIC NOT NULL DEFAULT 1.0,
    biomasa_inicial_kg NUMERIC NOT NULL DEFAULT 0.0,
    biomasa_actual_kg NUMERIC NOT NULL DEFAULT 0.0,
    costo_inicial_alevinos NUMERIC NOT NULL DEFAULT 0.0,
    costo_acumulado_insumos NUMERIC NOT NULL DEFAULT 0.0,
    costo_acumulado_fijo NUMERIC NOT NULL DEFAULT 0.0,
    estado TEXT NOT NULL DEFAULT 'Activo' CHECK (estado IN ('Activo', 'Cosechado', 'Dividido')),
    fecha_siembra DATE NOT NULL DEFAULT CURRENT_DATE,
    fecha_cosecha_estimada DATE,
    creado_en TIMESTAMPTZ NOT NULL DEFAULT timezone('utc'::text, now()),
    CONSTRAINT uq_empresa_codigo_lote UNIQUE (empresa_id, codigo_lote)
);
CREATE INDEX IF NOT EXISTS idx_lotes_empresa_id ON public.lotes(empresa_id);
CREATE INDEX IF NOT EXISTS idx_lotes_estanque_id ON public.lotes(estanque_id);
CREATE INDEX IF NOT EXISTS idx_lotes_unidad_id ON public.lotes(unidad_acuicola_id);

-- ─── 8. INVENTARIO DE INSUMOS Y ALIMENTO (CPP CAPITALIZADO) ─────────────────
CREATE TABLE IF NOT EXISTS public.inventario_insumos (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    empresa_id UUID NOT NULL REFERENCES public.empresas(id) ON DELETE CASCADE,
    unidad_acuicola_id UUID REFERENCES public.unidades_acuicolas(id) ON DELETE SET NULL,
    tipo TEXT NOT NULL CHECK (tipo IN ('Alimento', 'Farmaco', 'Insumo', 'Aireador', 'Herramienta')),
    nombre TEXT NOT NULL,
    cantidad_original_kg NUMERIC NOT NULL CHECK (cantidad_original_kg > 0),
    cantidad_actual_kg NUMERIC NOT NULL CHECK (cantidad_actual_kg >= 0),
    costo_total NUMERIC NOT NULL CHECK (costo_total >= 0),
    costo_unitario_historico NUMERIC NOT NULL CHECK (costo_unitario_historico >= 0),
    creado_en TIMESTAMPTZ NOT NULL DEFAULT timezone('utc'::text, now())
);
CREATE INDEX IF NOT EXISTS idx_inventario_empresa_id ON public.inventario_insumos(empresa_id);
CREATE INDEX IF NOT EXISTS idx_inventario_unidad_id ON public.inventario_insumos(unidad_acuicola_id);

-- ─── 9. ALIMENTACIÓN DIARIA (DESCUENTO FIFO Y COSTEO) ──────────────────────
CREATE TABLE IF NOT EXISTS public.alimentacion_diaria (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    empresa_id UUID NOT NULL REFERENCES public.empresas(id) ON DELETE CASCADE,
    unidad_acuicola_id UUID NOT NULL REFERENCES public.unidades_acuicolas(id) ON DELETE RESTRICT,
    estanque_id UUID NOT NULL REFERENCES public.estanques(id) ON DELETE CASCADE,
    lote_id UUID NOT NULL REFERENCES public.lotes(id) ON DELETE CASCADE,
    insumo_id UUID REFERENCES public.inventario_insumos(id) ON DELETE SET NULL,
    cantidad_consumida_kg NUMERIC NOT NULL CHECK (cantidad_consumida_kg > 0),
    costo_calculado NUMERIC NOT NULL DEFAULT 0.0 CHECK (costo_calculado >= 0),
    fecha DATE NOT NULL DEFAULT CURRENT_DATE,
    creado_en TIMESTAMPTZ NOT NULL DEFAULT timezone('utc'::text, now())
);
CREATE INDEX IF NOT EXISTS idx_alimentacion_empresa_id ON public.alimentacion_diaria(empresa_id);
CREATE INDEX IF NOT EXISTS idx_alimentacion_lote_id ON public.alimentacion_diaria(lote_id);
CREATE INDEX IF NOT EXISTS idx_alimentacion_fecha ON public.alimentacion_diaria(fecha);

-- ─── 10. PARÁMETROS DE CALIDAD DE AGUA ──────────────────────────────────────
CREATE TABLE IF NOT EXISTS public.parametros_calidad_agua (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    empresa_id UUID NOT NULL REFERENCES public.empresas(id) ON DELETE CASCADE,
    unidad_acuicola_id UUID NOT NULL REFERENCES public.unidades_acuicolas(id) ON DELETE RESTRICT,
    estanque_id UUID NOT NULL REFERENCES public.estanques(id) ON DELETE CASCADE,
    fecha TIMESTAMPTZ NOT NULL DEFAULT timezone('utc'::text, now()),
    oxigeno_mg_l NUMERIC,
    oxigeno_pct NUMERIC,
    ph NUMERIC,
    temperatura_c NUMERIC,
    amonio_mg_l NUMERIC,
    nitritos_mg_l NUMERIC,
    nitratos_mg_l NUMERIC,
    alcalinidad_mg_l NUMERIC,
    dureza_mg_l NUMERIC,
    cloro_mg_l NUMERIC,
    co2_mg_l NUMERIC,
    observaciones TEXT,
    registrado_por UUID REFERENCES public.miembros_equipo(id) ON DELETE SET NULL,
    creado_en TIMESTAMPTZ NOT NULL DEFAULT timezone('utc'::text, now())
);
CREATE INDEX IF NOT EXISTS idx_calidad_agua_empresa_estanque ON public.parametros_calidad_agua(empresa_id, estanque_id, fecha DESC);

-- ─── 11. REGISTRO DE ACTIVIDADES Y AUDITORÍA EN CAMPO ───────────────────────
CREATE TABLE IF NOT EXISTS public.registro_actividades (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    empresa_id UUID NOT NULL REFERENCES public.empresas(id) ON DELETE CASCADE,
    unidad_acuicola_id UUID NOT NULL REFERENCES public.unidades_acuicolas(id) ON DELETE RESTRICT,
    estanque_id UUID NOT NULL REFERENCES public.estanques(id) ON DELETE CASCADE,
    tipo TEXT NOT NULL CHECK (tipo IN ('Alimentacion', 'Biometria', 'Mortalidad', 'Tratamiento', 'Traslado', 'Siembra')),
    descripcion TEXT NOT NULL,
    detalles JSONB DEFAULT '{}'::jsonb,
    fecha TIMESTAMPTZ NOT NULL DEFAULT timezone('utc'::text, now()),
    registrado_por UUID REFERENCES public.miembros_equipo(id) ON DELETE SET NULL,
    creado_en TIMESTAMPTZ NOT NULL DEFAULT timezone('utc'::text, now())
);
CREATE INDEX IF NOT EXISTS idx_actividades_empresa_estanque ON public.registro_actividades(empresa_id, estanque_id, fecha DESC);

-- ─── 12. FACTURAS DE COMPRA (ALIMENTO E INSUMOS CON FLETES PRORRATEADOS) ────
CREATE TABLE IF NOT EXISTS public.facturas (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    empresa_id UUID NOT NULL REFERENCES public.empresas(id) ON DELETE CASCADE,
    unidad_acuicola_id UUID NOT NULL REFERENCES public.unidades_acuicolas(id) ON DELETE RESTRICT,
    tipo_factura TEXT NOT NULL CHECK (tipo_factura IN ('Alimento', 'Insumo')),
    numero_factura TEXT NOT NULL,
    proveedor_nombre TEXT NOT NULL,
    proveedor_nit TEXT NOT NULL,
    fecha_expedicion DATE NOT NULL,
    fecha_vencimiento DATE NOT NULL,
    es_credito BOOLEAN NOT NULL DEFAULT false,
    dias_credito INTEGER DEFAULT 0,
    total_neto NUMERIC NOT NULL,
    total_iva NUMERIC NOT NULL DEFAULT 0.0,
    total_factura NUMERIC NOT NULL,
    costo_flete NUMERIC NOT NULL DEFAULT 0.0,
    estado_pago TEXT NOT NULL CHECK (estado_pago IN ('Paga', 'Pendiente', 'Vencida')),
    pago_info JSONB,
    productos JSONB NOT NULL,
    creado_en TIMESTAMPTZ NOT NULL DEFAULT timezone('utc'::text, now())
);
CREATE INDEX IF NOT EXISTS idx_facturas_empresa_id ON public.facturas(empresa_id);

-- ─── 13. VENTAS DE COSECHAS Y COGS ──────────────────────────────────────────
CREATE TABLE IF NOT EXISTS public.ventas_lotes (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    empresa_id UUID NOT NULL REFERENCES public.empresas(id) ON DELETE CASCADE,
    unidad_acuicola_id UUID NOT NULL REFERENCES public.unidades_acuicolas(id) ON DELETE RESTRICT,
    cliente_id UUID REFERENCES public.clientes(id) ON DELETE SET NULL,
    cliente_nombre TEXT NOT NULL,
    lote_id UUID NOT NULL REFERENCES public.lotes(id) ON DELETE RESTRICT,
    codigo_lote TEXT NOT NULL,
    estanque_nombre TEXT NOT NULL,
    especie TEXT NOT NULL,
    biomasa_vendida_kg NUMERIC NOT NULL CHECK (biomasa_vendida_kg > 0),
    precio_unitario_kg NUMERIC NOT NULL CHECK (precio_unitario_kg > 0),
    ingreso_bruto NUMERIC NOT NULL,
    cogs NUMERIC NOT NULL, -- Costo de producción asignado
    utilidad_neta NUMERIC NOT NULL,
    estado_pago TEXT NOT NULL CHECK (estado_pago IN ('Pendiente', 'Pagado')),
    peso_promedio_g NUMERIC,
    porcentaje_visceras_pct NUMERIC,
    creado_en TIMESTAMPTZ NOT NULL DEFAULT timezone('utc'::text, now())
);
CREATE INDEX IF NOT EXISTS idx_ventas_empresa_id ON public.ventas_lotes(empresa_id);

-- ─── 14. COMPRAS DE MATERIAL BIOLÓGICO (TRAZABILIDAD ICA / AUNAP) ────────────
CREATE TABLE IF NOT EXISTS public.compras_mat_biologico (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    empresa_id UUID NOT NULL REFERENCES public.empresas(id) ON DELETE CASCADE,
    unidad_acuicola_id UUID NOT NULL REFERENCES public.unidades_acuicolas(id) ON DELETE RESTRICT,
    tipo TEXT NOT NULL CHECK (tipo IN ('Ovas', 'Larvas', 'Alevinos', 'Reproductores')),
    especie TEXT NOT NULL,
    proveedor_nombre TEXT NOT NULL,
    proveedor_nit TEXT NOT NULL,
    numero_factura TEXT NOT NULL,
    costo_unitario NUMERIC NOT NULL CHECK (costo_unitario >= 0),
    cantidad NUMERIC NOT NULL CHECK (cantidad > 0),
    cantidad_original NUMERIC NOT NULL,
    costo_total NUMERIC NOT NULL CHECK (costo_total >= 0),
    peso_promedio_gramos NUMERIC DEFAULT 0.0,
    biomasa_estimada_kg NUMERIC DEFAULT 0.0,
    certificacion_ica BOOLEAN NOT NULL DEFAULT false,
    resolucion_ica TEXT,
    resolucion_aunap TEXT,
    fecha DATE NOT NULL DEFAULT CURRENT_DATE,
    creado_en TIMESTAMPTZ NOT NULL DEFAULT timezone('utc'::text, now())
);
CREATE INDEX IF NOT EXISTS idx_compras_bio_empresa_id ON public.compras_mat_biologico(empresa_id);

-- ─── 15. NÓMINA LABORAL Y PRESTACIONES SOCIALES ─────────────────────────────
CREATE TABLE IF NOT EXISTS public.registros_nomina (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    empresa_id UUID NOT NULL REFERENCES public.empresas(id) ON DELETE CASCADE,
    unidad_acuicola_id UUID NOT NULL REFERENCES public.unidades_acuicolas(id) ON DELETE RESTRICT,
    empleado_id UUID NOT NULL REFERENCES public.miembros_equipo(id) ON DELETE RESTRICT,
    empleado_nombre TEXT NOT NULL,
    periodo TEXT NOT NULL CHECK (periodo IN ('Quincenal', 'Mensual')),
    salario_base NUMERIC NOT NULL,
    auxilio_transporte NUMERIC DEFAULT 0.0,
    recargos_extras NUMERIC DEFAULT 0.0,
    pension_patronal NUMERIC DEFAULT 0.0,
    arl NUMERIC DEFAULT 0.0,
    caja_compensacion NUMERIC DEFAULT 0.0,
    prima NUMERIC DEFAULT 0.0,
    cesantias NUMERIC DEFAULT 0.0,
    intereses_cesantias NUMERIC DEFAULT 0.0,
    vacaciones NUMERIC DEFAULT 0.0,
    dotacion_provision NUMERIC DEFAULT 0.0,
    costo_total_empresa NUMERIC NOT NULL,
    fecha_pago DATE NOT NULL,
    estado TEXT NOT NULL CHECK (estado IN ('Pendiente', 'Pagado')),
    creado_en TIMESTAMPTZ NOT NULL DEFAULT timezone('utc'::text, now())
);
CREATE INDEX IF NOT EXISTS idx_nomina_empresa_id ON public.registros_nomina(empresa_id);

-- ─── 16. EQUIPOS DE AIREACIÓN Y MEDICIÓN (ACTIVOS CAPEX) ───────────────────
CREATE TABLE IF NOT EXISTS public.equipos (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    empresa_id UUID NOT NULL REFERENCES public.empresas(id) ON DELETE CASCADE,
    unidad_acuicola_id UUID NOT NULL REFERENCES public.unidades_acuicolas(id) ON DELETE RESTRICT,
    nombre TEXT NOT NULL,
    sigla TEXT NOT NULL,
    tipo TEXT NOT NULL CHECK (tipo IN ('Aireacion', 'Medicion')),
    estado_salud TEXT NOT NULL CHECK (estado_salud IN ('Operativo', 'Bodega', 'Mantenimiento')),
    costo_adquisicion NUMERIC NOT NULL,
    vida_util_dias INTEGER NOT NULL,
    estanque_asignado_id UUID REFERENCES public.estanques(id) ON DELETE SET NULL,
    hp_potencia TEXT,
    fase_electrica TEXT,
    voltaje_amperaje TEXT,
    tasa_sort TEXT,
    caudal_lpm NUMERIC,
    area_accion_m2 NUMERIC,
    categoria_medicion TEXT,
    horas_uso_diario NUMERIC DEFAULT 0.0,
    proveedor TEXT,
    numero_factura TEXT,
    creado_en TIMESTAMPTZ NOT NULL DEFAULT timezone('utc'::text, now())
);
CREATE INDEX IF NOT EXISTS idx_equipos_empresa_id ON public.equipos(empresa_id);

-- ─── 17. COSTOS OPERATIVOS (ENERGÍA, MANTENIMIENTO, CAPEX) ──────────────────
CREATE TABLE IF NOT EXISTS public.recibos_energia (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    empresa_id UUID NOT NULL REFERENCES public.empresas(id) ON DELETE CASCADE,
    unidad_acuicola_id UUID NOT NULL REFERENCES public.unidades_acuicolas(id) ON DELETE RESTRICT,
    fecha_emision DATE NOT NULL,
    fecha_pago DATE NOT NULL,
    total_kwh NUMERIC NOT NULL,
    total_pagado NUMERIC NOT NULL,
    creado_en TIMESTAMPTZ NOT NULL DEFAULT timezone('utc'::text, now())
);
CREATE INDEX IF NOT EXISTS idx_recibos_energia_empresa ON public.recibos_energia(empresa_id);

CREATE TABLE IF NOT EXISTS public.mantenimientos (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    empresa_id UUID NOT NULL REFERENCES public.empresas(id) ON DELETE CASCADE,
    unidad_acuicola_id UUID NOT NULL REFERENCES public.unidades_acuicolas(id) ON DELETE RESTRICT,
    tipo_mantenimiento TEXT NOT NULL CHECK (tipo_mantenimiento IN ('Preventivo', 'Correctivo')),
    destino TEXT NOT NULL CHECK (destino IN ('Estanque', 'General')),
    estanque_id UUID REFERENCES public.estanques(id) ON DELETE SET NULL,
    concepto TEXT NOT NULL,
    proveedor TEXT NOT NULL,
    fecha DATE NOT NULL,
    valor NUMERIC NOT NULL,
    creado_en TIMESTAMPTZ NOT NULL DEFAULT timezone('utc'::text, now())
);
CREATE INDEX IF NOT EXISTS idx_mantenimientos_empresa ON public.mantenimientos(empresa_id);

CREATE TABLE IF NOT EXISTS public.inversiones_capex (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    empresa_id UUID NOT NULL REFERENCES public.empresas(id) ON DELETE CASCADE,
    unidad_acuicola_id UUID NOT NULL REFERENCES public.unidades_acuicolas(id) ON DELETE RESTRICT,
    concepto TEXT NOT NULL,
    fecha DATE NOT NULL,
    valor_total NUMERIC NOT NULL,
    vida_util_anos NUMERIC NOT NULL,
    creado_en TIMESTAMPTZ NOT NULL DEFAULT timezone('utc'::text, now())
);
CREATE INDEX IF NOT EXISTS idx_inversiones_capex_empresa ON public.inversiones_capex(empresa_id);

CREATE TABLE IF NOT EXISTS public.tablas_alimentacion (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    empresa_id UUID NOT NULL REFERENCES public.empresas(id) ON DELETE CASCADE,
    unidad_acuicola_id UUID REFERENCES public.unidades_acuicolas(id) ON DELETE SET NULL,
    especie TEXT NOT NULL,
    etapa TEXT,
    semana INTEGER,
    peso_min_g NUMERIC NOT NULL,
    peso_max_g NUMERIC NOT NULL,
    tasa_alimentacion_pct NUMERIC NOT NULL,
    raciones_dia INTEGER NOT NULL DEFAULT 3,
    creado_en TIMESTAMPTZ NOT NULL DEFAULT timezone('utc'::text, now())
);
CREATE INDEX IF NOT EXISTS idx_tablas_alimentacion_empresa ON public.tablas_alimentacion(empresa_id);
