# FishBit Bitácora Database Schema & Architecture Audit

**Author**: Spec Miner & Database Explorer  
**Date**: 2026-08-29  
**Supabase Project ID**: `oakovawlwjpnoydpwtam`  
**PostgreSQL Version**: PostgreSQL 17.6 on aarch64-unknown-linux-gnu

---

## 1. Executive Summary

This audit examined the database schema, foreign keys, row-level security (RLS) policies, triggers, indexes, and existing data for the **Bitácora** module of FishBit across 9 core tables.

### Key Discoveries & Root Causes:
1. **Critical Blocker on `parametros_calidad_agua`**:
   - `rowsecurity = true` (RLS is active), but **ZERO RLS policies** exist on `parametros_calidad_agua`. In PostgreSQL, this results in an unconditional `DENY ALL` for authenticated and anonymous users.
   - Column `empresa_id` is **missing** from `parametros_calidad_agua` in the database.
   - Column `unit_id` is **missing** from `parametros_calidad_agua`.
   - The trigger `trg_calidad_inherit_sede` exists, but `trg_parametros_calidad_agua_tenant` (`fn_auto_inherit_tenant_context`) is missing.
   - The table currently has **0 rows** because all client attempts to insert or read from client sessions failed due to RLS / schema mismatches and were caught in empty `catch (_)` blocks in Dart.
2. **Telemetry Data Fragmentation (`water_quality` vs `parametros_calidad_agua`)**:
   - `water_quality` holds **11 historical telemetry rows** recorded between 2026-04-30 and 2026-05-29 for unit `3500cc63-5477-4f83-b4a3-7758b7cd6509` (Estanque `4c2cc39f-0ca6-4884-8563-98ffd0324a5a`).
   - `calidad_agua` is an obsolete legacy table (3 parameters only: `oxygen`, `temperature`, `ph`) with **0 rows**.
   - `parametros_calidad_agua` has schema columns for 12 physicochemical parameters (`oxigeno_mg_l`, `oxigeno_pct`, `ph`, `temperatura`, `amonio_mg_l`, `nitritos_mg_l`, `nitratos_mg_l`, `fosforo_mg_l`, `alcalinidad_mg_l`, `dureza_mg_l`, `cloro_mg_l`, `co2_mg_l`).
3. **`alimentacion_diaria` and `lotes` Status**:
   - `alimentacion_diaria` contains **84 active rows**.
   - `lotes` contains **15 active rows** (all foreign key references `alimentacion_diaria.lote_id -> lotes.id` are 100% valid and verified).
   - Missing indexes: `alimentacion_diaria` has NO index on `(empresa_id, fecha)` nor `fecha`.
4. **`biometrias` and `mortalidad` Data & UI Disconnect**:
   - `biometrias` contains **38 rows** of historical sampling data, but the Bitácora UI tab ("Biometrías y GDP") reads only from `pondsProvider.batches` rather than querying `biometrias`.
   - `mortalidad` contains **7 rows** of mortality logs, but existing rows have `empresa_id = NULL`. When queried by tenant-scoped RLS policies, they return empty, and the UI tab ("Bajas y Sanidad") currently only reads active lotes from `pondsProvider.batches`.
   - In `biometrias`, columns are `date`, `avg_weight_gr`, `total_biomass_kg`, `batch_id` (text), `species_name` (text). Missing columns: `peces_capturados`, `peso_total_captura_kg`, `biomasa_parcial_kg`, `longitud_cm`.
   - In `mortalidad`, columns are `date`, `quantity`, `cause`, `batch_id` (text), `siembra_id` (uuid).
5. **In-Memory Hardcoded UUID Filtering in Flutter**:
   - `SupabaseWaterQualityRepository` and `SupabaseNutritionRepository` fetch up to 50/100 records from Supabase without database-level filtering and perform client-side string comparisons against hardcoded UUIDs (`'3500cc63-5477-4f83-b4a3-7758b7cd6509'` and `'54dedaac-9099-475a-8bfc-635ef8494c2a'`).

---

## 2. Table-by-Table Schema & Constraint Analysis

### 2.1 Table Row Counts & RLS Status

| Table Name | Actual Row Count | RLS Enabled? | RLS Policy Count | Primary Key | Canonical Status |
|---|---|---|---|---|---|
| `empresas` | 2 | Yes (`true`) | 2 policies | `id` (uuid) | Master Tenant Entity |
| `unidades_acuicolas` | 4 | Yes (`true`) | 0 policies | `id` (uuid) | Spanish Sede Table |
| `units` | 3 | Yes (`true`) | 2 policies | `id` (uuid) | Canonical Sede Table |
| `estanques` | 26 | Yes (`true`) | 3 policies | `id` (uuid) | Canonical Pond Table |
| `lotes` | 15 | Yes (`true`) | 2 policies | `id` (uuid) | Canonical Batch Table |
| `siembras` | 26 | Yes (`true`) | 2 policies | `id` (uuid) | Batch Legacy/Sync Table |
| `alimentacion_diaria` | 84 | Yes (`true`) | 2 policies | `id` (uuid) | Canonical Feeding Table |
| `parametros_calidad_agua` | 0 | Yes (`true`) | **0 policies (DENY ALL)** | `id` (uuid) | **Target Canonical Water Quality Table** |
| `water_quality` | 11 | Yes (`true`) | 0 policies | `id` (uuid) | Legacy Water Table (to migrate & deprecate) |
| `calidad_agua` | 0 | Yes (`true`) | 2 policies | `id` (uuid) | Obsolete Table (to drop/deprecate) |
| `biometrias` | 38 | Yes (`true`) | 2 policies | `id` (uuid) | Canonical Biometry Table |
| `mortalidad` | 7 | Yes (`true`) | 2 policies | `id` (uuid) | Canonical Mortality Table |
| `mortality` | 0 | Yes (`true`) | 0 policies | `id` (uuid) | Obsolete Table |

---

### 2.2 Detailed Column Specifications

#### 1. `parametros_calidad_agua`
- **Columns in Database**:
  - `id` (`uuid`, NOT NULL, default: `uuid_generate_v4()`)
  - `estanque_id` (`uuid`, NOT NULL, FK -> `estanques.id` ON DELETE CASCADE)
  - `fecha` (`timestamptz`, NOT NULL, default: `timezone('utc'::text, now())`)
  - `oxigeno_mg_l` (`numeric`, Nullable)
  - `oxigeno_pct` (`numeric`, Nullable)
  - `ph` (`numeric`, Nullable)
  - `amonio_mg_l` (`numeric`, Nullable)
  - `nitritos_mg_l` (`numeric`, Nullable)
  - `nitratos_mg_l` (`numeric`, Nullable)
  - `fosforo_mg_l` (`numeric`, Nullable)
  - `alcalinidad_mg_l` (`numeric`, Nullable)
  - `dureza_mg_l` (`numeric`, Nullable)
  - `cloro_mg_l` (`numeric`, Nullable)
  - `co2_mg_l` (`numeric`, Nullable)
  - `temperatura` (`numeric`, Nullable) *(Note: DB column is named `temperatura`)*
  - `observaciones` (`text`, Nullable)
  - `registrado_por` (`text`, Nullable)
  - `unidad_acuicola_sigla` (`text`, Nullable)
  - `creado_en` (`timestamptz`, NOT NULL, default: `timezone('utc'::text, now())`)
- **Missing Columns Required**:
  - `empresa_id` (`uuid`, REFERENCES `empresas(id)` ON DELETE CASCADE)
  - `unit_id` (`uuid`, REFERENCES `units(id)` ON DELETE CASCADE / SET NULL)
- **Water Quality Parameters Assessment**:
  - Contains all 10 standard parameters + 2 additional (`fosforo_mg_l` and `oxigeno_pct`).
  - Total: 12 parameters (`oxigeno_mg_l`, `oxigeno_pct`, `ph`, `temperatura`, `amonio_mg_l`, `nitritos_mg_l`, `nitratos_mg_l`, `fosforo_mg_l`, `alcalinidad_mg_l`, `dureza_mg_l`, `cloro_mg_l`, `co2_mg_l`).
  - `fecha` is `timestamptz`, which encompasses both date and time (hour/minute/second).

#### 2. `water_quality` (Legacy)
- **Columns in Database**:
  - `id` (`uuid`, NOT NULL, default: `gen_random_uuid()`)
  - `estanque_id` (`uuid`, Nullable)
  - `date` (`date`, default: `CURRENT_DATE`)
  - `hour` (`time without time zone`, Nullable)
  - `o2_mg_l` (`numeric`, Nullable)
  - `o2_perc` (`numeric`, Nullable)
  - `ph` (`numeric`, Nullable)
  - `ammonia_mg_l` (`numeric`, Nullable)
  - `nitrite_mg_l` (`numeric`, Nullable)
  - `nitrate_mg_l` (`numeric`, Nullable)
  - `alkalinity` (`numeric`, Nullable)
  - `ammonia` (`numeric`, Nullable)
  - `nitrite` (`numeric`, Nullable)
  - `nitrate` (`numeric`, Nullable)
  - `temperature_c` (`numeric`, Nullable)
  - `empresa_id` (`uuid`, Nullable, FK -> `empresas.id` ON DELETE CASCADE)
  - `unit_id` (`uuid`, Nullable, FK -> `units.id`)
  - `created_at` (`timestamptz`, default: `timezone('utc'::text, now())`)
- **Assessment**: Contains 11 valid rows. Missing parameters: `co2_mg_l`, `dureza_mg_l`, `cloro_mg_l`, `fosforo_mg_l`.

#### 3. `calidad_agua` (Obsolete)
- **Columns in Database**:
  - `id`, `estanque_id`, `date`, `hour`, `oxygen`, `temperature`, `ph`, `created_at`, `unit_id`, `empresa_id`.
- **Assessment**: 0 rows. Missing 7 of the 10 required water quality parameters.

#### 4. `alimentacion_diaria`
- **Columns in Database**:
  - `id` (`uuid`, NOT NULL, default: `uuid_generate_v4()`)
  - `estanque_id` (`uuid`, NOT NULL, FK -> `estanques.id` ON DELETE CASCADE)
  - `lote_id` (`uuid`, NOT NULL, FK -> `lotes.id` ON DELETE CASCADE)
  - `cantidad_consumida_kg` (`numeric`, NOT NULL)
  - `costo_calculado` (`numeric`, NOT NULL, default: `0`)
  - `fecha` (`date`, NOT NULL, default: `CURRENT_DATE`)
  - `creado_en` (`timestamptz`, NOT NULL, default: `timezone('utc'::text, now())`)
  - `unidad_acuicola_sigla` (`text`, Nullable)
  - `empresa_id` (`uuid`, Nullable, FK -> `empresas.id` ON DELETE CASCADE)
  - `unit_id` (`uuid`, Nullable)

#### 5. `biometrias`
- **Columns in Database**:
  - `id` (`uuid`, NOT NULL, default: `gen_random_uuid()`)
  - `estanque_id` (`uuid`, Nullable)
  - `date` (`date`, default: `CURRENT_DATE`)
  - `avg_weight_gr` (`numeric`, default: `0`)
  - `total_biomass_kg` (`numeric`, default: `0`)
  - `species_name` (`text`, Nullable)
  - `batch_id` (`text`, Nullable)
  - `empresa_id` (`uuid`, Nullable, FK -> `empresas.id` ON DELETE CASCADE)
  - `unit_id` (`uuid`, Nullable, FK -> `units.id`)
  - `created_at` (`timestamptz`, default: `timezone('utc'::text, now())`)
- **Assessment**: Missing columns: `lote_id` (uuid FK), `peces_capturados` (int), `peso_total_captura_kg` (numeric), `biomasa_parcial_kg` (numeric), `longitud_cm` (numeric), `hora` (time).

#### 6. `mortalidad`
- **Columns in Database**:
  - `id` (`uuid`, NOT NULL, default: `gen_random_uuid()`)
  - `estanque_id` (`uuid`, Nullable)
  - `date` (`date`, default: `CURRENT_DATE`)
  - `quantity` (`integer`, default: `0`)
  - `cause` (`text`, Nullable)
  - `batch_id` (`text`, Nullable)
  - `siembra_id` (`uuid`, Nullable, FK -> `siembras.id`)
  - `empresa_id` (`uuid`, Nullable, FK -> `empresas.id` ON DELETE CASCADE)
  - `unit_id` (`uuid`, Nullable, FK -> `units.id`)
  - `created_at` (`timestamptz`, default: `timezone('utc'::text, now())`)

#### 7. `estanques`
- **Columns in Database**: 21 columns including `id`, `nombre`, `sigla`, `capacidad_m3`, `especie`, `biomasa_kg`, `costo_acumulado_biologico`, `estado`, `aireacion_activa`, `unidad_acuicola_sigla`, `empresa_id` (FK), `unit_id` (FK).
- **Row Count**: 26 active ponds.

#### 8. `lotes`
- **Columns in Database**: 18 columns including `id`, `codigo_lote`, `especie`, `cantidad_inicial_peces`, `cantidad_actual_peces`, `biomasa_actual_kg`, `costo_acumulado_insumos`, `costo_acumulado_fijo`, `estado`, `estanque_id` (FK), `creado_en`, `peso_inicial_gramos`, `biomasa_inicial_kg`, `costo_inicial_alevines`, `unidad_acuicola_sigla`, `empresa_id` (FK), `unit_id`.
- **Row Count**: 15 active fish batches.

#### 9. `empresas`
- **Columns in Database**: `id`, `nombre`, `nit`, `logo_url`, `moneda`, `configuraciones_nomina`, `especies_habilitadas`, `created_at`, `updated_at`.
- **Active Tenants**:
  1. `3500cc63-5477-4f83-b4a3-7758b7cd6509` ("Piscícola Los Compadres", NIT: 901.530.907-1)
  2. `54dedaac-9099-475a-8bfc-635ef8494c2a` ("Aquarium", NIT: 109.215.401-2)

---

## 3. Foreign Key & Integrity Verification

| Constraint Name | Source Table | Source Column | Referenced Table | Referenced Column | On Delete | Integrity Status |
|---|---|---|---|---|---|---|
| `alimentacion_diaria_empresa_id_fkey` | `alimentacion_diaria` | `empresa_id` | `empresas` | `id` | CASCADE | ✅ Verified (84/84 match) |
| `alimentacion_diaria_estanque_id_fkey` | `alimentacion_diaria` | `estanque_id` | `estanques` | `id` | CASCADE | ✅ Verified (84/84 match) |
| `alimentacion_diaria_lote_id_fkey` | `alimentacion_diaria` | `lote_id` | `lotes` | `id` | CASCADE | ✅ Verified (84/84 match) |
| `biometrias_empresa_id_fkey` | `biometrias` | `empresa_id` | `empresas` | `id` | CASCADE | ⚠️ 38 rows have `empresa_id` set |
| `biometrias_unit_id_fkey` | `biometrias` | `unit_id` | `units` | `id` | NO ACTION | ✅ Verified |
| `mortalidad_empresa_id_fkey` | `mortalidad` | `empresa_id` | `empresas` | `id` | CASCADE | ⚠️ 7 rows have `empresa_id = NULL` |
| `mortalidad_siembra_id_fkey` | `mortalidad` | `siembra_id` | `siembras` | `id` | NO ACTION | ⚠️ 7 rows have `siembra_id = NULL` |
| `mortalidad_unit_id_fkey` | `mortalidad` | `unit_id` | `units` | `id` | NO ACTION | ⚠️ 2 rows have `unit_id = NULL` |
| `parametros_calidad_agua_estanque_id_fkey` | `parametros_calidad_agua` | `estanque_id` | `estanques` | `id` | CASCADE | ✅ Verified |
| *MISSING FK* | `parametros_calidad_agua` | `empresa_id` | `empresas` | `id` | CASCADE | ❌ Column missing from table |

---

## 4. Index Analysis

| Table | Existing Indexes | Missing / Recommended Indexes |
|---|---|---|
| `parametros_calidad_agua` | `parametros_calidad_agua_pkey` (`id`)<br>`idx_calidad_agua_estanque_fecha` (`estanque_id`, `fecha DESC`)<br>`idx_calidad_agua_sigla` (`unidad_acuicola_sigla`) | `idx_calidad_agua_empresa_fecha` (`empresa_id`, `fecha DESC`)<br>`idx_calidad_agua_empresa_id` (`empresa_id`) |
| `alimentacion_diaria` | `alimentacion_diaria_pkey` (`id`)<br>`idx_alimentacion_estanque_lote` (`estanque_id`, `lote_id`) | `idx_alimentacion_empresa_fecha` (`empresa_id`, `fecha DESC`)<br>`idx_alimentacion_empresa_id` (`empresa_id`)<br>`idx_alimentacion_fecha` (`fecha DESC`) |
| `biometrias` | `biometrias_pkey` (`id`)<br>`idx_biometrias_empresa_id` (`empresa_id`)<br>`idx_biometrias_estanque_id` (`estanque_id`)<br>`idx_biometrias_unit_id` (`unit_id`) | `idx_biometrias_empresa_date` (`empresa_id`, `date DESC`)<br>`idx_biometrias_empresa_estanque_date` (`empresa_id`, `estanque_id`, `date DESC`) |
| `mortalidad` | `mortalidad_pkey` (`id`)<br>`idx_mortalidad_estanque_id` (`estanque_id`) | `idx_mortalidad_empresa_id` (`empresa_id`)<br>`idx_mortalidad_empresa_date` (`empresa_id`, `date DESC`)<br>`idx_mortalidad_empresa_estanque_date` (`empresa_id`, `estanque_id`, `date DESC`) |
| `estanques` | `estanques_pkey` (`id`)<br>`idx_estanques_empresa_id` (`empresa_id`)<br>`idx_estanques_unidad_acuicola_id`<br>`idx_estanques_unit_id`<br>`idx_estanques_unidad_acuicola_sigla` | None (fully covered) |
| `lotes` | `lotes_pkey` (`id`)<br>`lotes_codigo_lote_key` (`codigo_lote`)<br>`idx_lotes_estanque_id`<br>`idx_lotes_unidad_acuicola_sigla` | `idx_lotes_empresa_id` (`empresa_id`) |

---

## 5. RLS Policies & Auth Helper Functions

### 5.1 Auth Helper Functions Definition
1. **`get_auth_empresa_id()`**:
   ```sql
   CREATE OR REPLACE FUNCTION public.get_auth_empresa_id()
    RETURNS uuid
    LANGUAGE sql
    STABLE SECURITY DEFINER
    SET search_path TO 'public'
   AS $function$
     SELECT COALESCE(
       (SELECT empresa_id FROM public.profiles WHERE id = auth.uid() LIMIT 1),
       (SELECT empresa_id FROM public.miembros_equipo WHERE LOWER(email) = LOWER(auth.jwt() ->> 'email') LIMIT 1),
       (SELECT u.empresa_id FROM public.user_units uu JOIN public.units u ON u.id = uu.unit_id WHERE uu.user_id = auth.uid() LIMIT 1)
     );
   $function$;
   ```
2. **`get_auth_user_role()`**:
   Returns the user's role in lowercase (`'admin'`, `'creador'`, `'master'`, `'tecnico'`, `'operario'`), defaulting to `'operario'`.
3. **`is_superadmin()`**:
   Checks if the user has `is_superadmin = true` or `role = 'billingadmin'` or is `'especialistaacuicola@gmail.com'`.

### 5.2 RLS Policy Coverage Assessment

| Table | SELECT Policy | ALL / MODIFY Policy | Status & Issues |
|---|---|---|---|
| `parametros_calidad_agua` | **NONE** | **NONE** | ❌ **CRITICAL BLOCKER**: RLS enabled with 0 policies denies all client operations. |
| `alimentacion_diaria` | `(empresa_id = get_auth_empresa_id()) OR is_superadmin()` | Role-based check with `empresa_id = get_auth_empresa_id()` | ✅ Working for tenant queries |
| `biometrias` | `(empresa_id = get_auth_empresa_id()) OR is_superadmin()` | Role-based check with `empresa_id = get_auth_empresa_id()` | ✅ Working when `empresa_id` is set |
| `mortalidad` | `(empresa_id = get_auth_empresa_id()) OR is_superadmin()` | Role-based check with `empresa_id = get_auth_empresa_id()` | ⚠️ Existing 7 rows have `empresa_id = NULL`, hidden from tenant select |
| `estanques` | `(empresa_id = get_auth_empresa_id()) OR is_superadmin()` | Role-based check with `empresa_id = get_auth_empresa_id()` | ✅ Working |
| `lotes` | `(empresa_id = get_auth_empresa_id()) OR is_superadmin()` | Role-based check with `empresa_id = get_auth_empresa_id()` | ✅ Working |

---

## 6. Deprecation & Migration Strategy for `calidad_agua` & `water_quality`

### 6.1 `calidad_agua`
- **Assessment**: Empty table (0 rows), obsolete 3-parameter schema (`oxygen`, `temperature`, `ph`).
- **Action**: Safe to deprecate or drop immediately. No active client features rely on it.

### 6.2 `water_quality`
- **Assessment**: Contains 11 valid telemetry measurements.
- **Action**:
  1. Add `empresa_id` and `unit_id` to `parametros_calidad_agua`.
  2. Copy the 11 rows from `water_quality` into `parametros_calidad_agua` with proper column mappings:
     - `water_quality.date` + `water_quality.hour` -> `parametros_calidad_agua.fecha`
     - `water_quality.o2_mg_l` -> `oxigeno_mg_l`
     - `water_quality.o2_perc` -> `oxigeno_pct`
     - `water_quality.temperature_c` -> `temperatura`
     - `water_quality.ph` -> `ph`
     - `water_quality.ammonia_mg_l` -> `amonio_mg_l`
     - `water_quality.nitrite_mg_l` -> `nitritos_mg_l`
     - `water_quality.nitrate_mg_l` -> `nitratos_mg_l`
     - `water_quality.alkalinity` -> `alcalinidad_mg_l`
     - `COALESCE(water_quality.empresa_id, estanques.empresa_id)` -> `empresa_id`
  3. Create RLS policies and indexes on `parametros_calidad_agua`.
  4. Update `SupabaseWaterQualityRepository` in Flutter to read/write exclusively to `parametros_calidad_agua`.
  5. Back up and safely deprecate/drop `water_quality`.
