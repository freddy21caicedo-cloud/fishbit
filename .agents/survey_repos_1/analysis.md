# Technical Audit & Codebase Survey: Bitácora Module (FishBit)

**Auditor Role:** Codebase & Repository Explorer  
**Date:** 2026-08-28  
**Project ID:** `oakovawlwjpnoydpwtam`  
**Workspace:** `c:\Users\Freddy\Desktop\Desarrollo de app\FishBit`  

---

## Executive Summary

This report delivers a deep technical survey of the **Bitácora (Operations Logbook)** module within the FishBit application (Flutter + Riverpod + Supabase). The Bitácora module is responsible for recording and monitoring water quality, daily feeding, biometric sampling, and mortality/health.

Our investigation identified critical architectural and operational issues across data persistence, repository implementation, multi-tenant isolation, and data presentation:

1. **Water Quality Double-Write & Inverted Read Logic:** `recordParameters()` attempts double writes to `parametros_calidad_agua` and legacy `water_quality`. `fetchRecentParametersByUnit()` prioritizes the empty legacy table `water_quality` and uses unindexed memory-based fallback logic.
2. **Missing Multi-Tenant Columns & Unsecured RLS Policies:** Table `parametros_calidad_agua` lacks `empresa_id` and `unidad_acuicola_id`. It has RLS enabled but **zero policies** defined, causing Supabase to block all authenticated client requests.
3. **Pervasive Hardcoded Company UUIDs:** 8 repositories filter tenant data by comparing hardcoded UUIDs (`3500cc63-5477-4f83-b4a3-7758b7cd6509` and `54dedaac-9099-475a-8bfc-635ef8494c2a`) in Dart memory rather than executing parameterized SQL queries (`.eq('empresa_id', empresaId)`).
4. **Missing Biometrics & Mortality Data Layers:**
   - There are no read repository methods (`fetchBiometries`, `fetchMortality`).
   - The UI tabs ("Biometrías y GDP" and "Bajas y Sanidad") display only static batch summaries from `pondsProvider.batches`, completely ignoring historical sampling and mortality event logs.
   - `Biometria` domain model does not exist.
   - `MortalityRecord` has significant column mismatches with the database table `mortalidad`.
5. **Schema Divergence between Dart and Supabase:** Multiple discrepancies exist across column naming conventions (`alevinos` vs `alevines`, `unit_id` vs `unidad_acuicola_id`, `batch_id` vs `lote_id`, English legacy tables vs Spanish canonical tables).

---

## 1. Water Quality Repository & Data Flow Audit

### 1.1 Architecture & Components
- **Domain Model:** `lib/modules/water_quality/domain/models/water_parameter.dart`
- **Repository Interface:** `lib/modules/water_quality/domain/repositories/water_quality_repository.dart`
- **Infrastructure Implementation:** `lib/modules/water_quality/infrastructure/repositories/supabase_water_quality_repository.dart`
- **Riverpod Provider:** `lib/modules/water_quality/presentation/providers/water_quality_provider.dart`
- **UI Dialog / Modal:** `lib/modules/water_quality/presentation/dialogs/parametro_modal.dart`
- **Presentation Screen:** `lib/modules/water_quality/presentation/screens/water_quality_records_screen.dart`

### 1.2 Inspection of `recordParameters()`
Located in `supabase_water_quality_repository.dart` (lines 125–181):
```dart
@override
Future<WaterParameter> recordParameters(WaterParameter parameter) async {
  _demoParameters.insert(0, parameter);
  if (parameter.empresaId.startsWith('c1000000-')) {
    return parameter;
  }
  try {
    final hourStr = '${parameter.fecha.hour.toString().padLeft(2, '0')}:${parameter.fecha.minute.toString().padLeft(2, '0')}:00';

    // 1. Inserción en parametros_calidad_agua (CANONICAL)
    try {
      await _supabase.from('parametros_calidad_agua').insert({
        'id': parameter.id,
        'estanque_id': parameter.estanqueId,
        'fecha': parameter.fecha.toIso8601String(),
        'oxigeno_mg_l': parameter.oxigenoMgL,
        'oxigeno_pct': parameter.oxigenoPct,
        'ph': parameter.ph,
        'temperatura': parameter.temperaturaC,
        'amonio_mg_l': parameter.amonioMgL,
        'nitritos_mg_l': parameter.nitritosMgL,
        'nitratos_mg_l': parameter.nitratosMgL,
        'alcalinidad_mg_l': parameter.alcalinidadMgL,
        'co2_mg_l': parameter.co2MgL,
        'dureza_mg_l': parameter.durezaMgL,
        'cloro_mg_l': parameter.cloroMgL,
        'observaciones': parameter.observaciones,
        'registrado_por': parameter.registradoPor,
        'creado_en': DateTime.now().toIso8601String(),
      });
    } catch (_) {}

    // 2. Inserción en water_quality (LEGACY / DUPLICATED)
    try {
      await _supabase.from('water_quality').insert({
        'id': parameter.id,
        'estanque_id': parameter.estanqueId,
        'empresa_id': parameter.empresaId,
        'unit_id': parameter.unidadAcuicolaId,
        'date': parameter.fecha.toIso8601String().split('T')[0],
        'hour': hourStr,
        'o2_mg_l': parameter.oxigenoMgL,
        'o2_perc': parameter.oxigenoPct,
        'ph': parameter.ph,
        'temperature_c': parameter.temperaturaC,
        'ammonia_mg_l': parameter.amonioMgL,
        'nitrite_mg_l': parameter.nitritosMgL,
        'nitrate_mg_l': parameter.nitratosMgL,
        'alkalinity': parameter.alcalinidadMgL,
        'created_at': parameter.fecha.toIso8601String(),
      });
    } catch (_) {}

    return parameter;
  } catch (_) {
    return parameter;
  }
}
```

**Flaws Identified:**
1. **Missing Tenant Keys in Primary Insert:** In step 1 (`parametros_calidad_agua`), `empresa_id` and `unidad_acuicola_id` (or `unit_id`) are completely omitted from the insert payload.
2. **Double-Write Anti-Pattern:** Writing to both `parametros_calidad_agua` and `water_quality` creates duplicate data and desynchronization risks.
3. **Silent Failure Swallowing:** Both inserts are wrapped in empty `catch (_) {}` blocks. If Supabase rejects an insert due to RLS or schema issues, no error is surfaced to the provider or UI.

### 1.3 Inspection of `fetchRecentParametersByUnit()` and Fallback Logic
Located in `supabase_water_quality_repository.dart` (lines 88–122):
```dart
@override
Future<List<WaterParameter>> fetchRecentParametersByUnit(String empresaId, String unidadAcuicolaId) async {
  try {
    // 1. Query against legacy water_quality table
    final res = await _supabase
        .from('water_quality')
        .select('*')
        .order('date', ascending: false)
        .limit(50);

    final rawList = res as List;
    if (rawList.isNotEmpty) {
      final all = rawList.map((row) => WaterParameter.fromJson(row as Map<String, dynamic>)).toList();
      final filtered = all.where((p) {
        if (empresaId == '3500cc63-5477-4f83-b4a3-7758b7cd6509' || unidadAcuicolaId == '3500cc63-5477-4f83-b4a3-7758b7cd6509' || unidadAcuicolaId == 'PISC') {
          return p.unidadAcuicolaId == '3500cc63-5477-4f83-b4a3-7758b7cd6509' || p.unidadAcuicolaId == 'PISC' || p.empresaId == '3500cc63-5477-4f83-b4a3-7758b7cd6509';
        }
        if (empresaId == '54dedaac-9099-475a-8bfc-635ef8494c2a' || unidadAcuicolaId == '54dedaac-9099-475a-8bfc-635ef8494c2a' || unidadAcuicolaId == 'AQUA' || unidadAcuicolaId == 'AQU') {
          return p.unidadAcuicolaId == '54dedaac-9099-475a-8bfc-635ef8494c2a' || p.unidadAcuicolaId == 'AQUA' || p.unidadAcuicolaId == 'AQU' || p.empresaId == '54dedaac-9099-475a-8bfc-635ef8494c2a';
        }
        return p.empresaId == empresaId || p.unidadAcuicolaId == unidadAcuicolaId;
      }).toList();

      return filtered.isNotEmpty ? filtered : all;
    }

    // 2. Fallback to parametros_calidad_agua
    final resFallback = await _supabase
        .from('parametros_calidad_agua')
        .select('*')
        .order('fecha', ascending: false)
        .limit(50);
    final listFallback = (resFallback as List).map((row) => WaterParameter.fromJson(row as Map<String, dynamic>)).toList();
    return listFallback.isNotEmpty ? listFallback : _demoParameters;
  } catch (_) {
    return _demoParameters;
  }
}
```

**Flaws Identified:**
1. **Inverted Hierarchy:** Queries legacy table `water_quality` (which has 0 rows and lacks full parameter columns) before canonical `parametros_calidad_agua`.
2. **Missing SQL Filtering:** Executes unconstrained `SELECT * FROM ... LIMIT 50` without `.eq('empresa_id', empresaId)` or `.eq('unit_id', unidadAcuicolaId)`.
3. **Data Leakage Risk:** If `filtered` is empty, it returns `all`, exposing records belonging to other tenants.
4. **Hardcoded Fallback to In-Memory Demo Data:** If DB query fails or returns empty, returns static mock data `_demoParameters`.

---

## 2. Codebase-Wide Survey of Hardcoded UUIDs

### 2.1 Catalog of Hardcoded Company UUIDs
The investigation revealed two production tenant UUIDs embedded directly into client-side repository source code:
- `3500cc63-5477-4f83-b4a3-7758b7cd6509`: "Piscícola Los Compadres" (Sigla: `PISC`)
- `54dedaac-9099-475a-8bfc-635ef8494c2a`: "Aquarium" / "Aquarium II" (Siglas: `AQUA`, `AQU`, `AQ1`, `AQ2`)

### 2.2 Locations in Codebase
| File Path | Line Range | Context |
|---|---|---|
| `lib/modules/water_quality/infrastructure/repositories/supabase_water_quality_repository.dart` | 100–107 | In-memory filtering for `fetchRecentParametersByUnit` |
| `lib/modules/ponds_batches/infrastructure/repositories/supabase_ponds_repository.dart` | 112–117 | In-memory filtering for `fetchPondsByUnit` |
| `lib/modules/ponds_batches/infrastructure/repositories/supabase_ponds_repository.dart` | 189–194 | In-memory filtering for `fetchBatchesByUnit` |
| `lib/modules/feeding_nutrition/infrastructure/repositories/supabase_nutrition_repository.dart` | 45–50 | In-memory filtering for `fetchFeedingRecords` |
| `lib/modules/sales_harvest/infrastructure/repositories/supabase_sales_repository.dart` | 63–68 | In-memory filtering for `fetchSales` |
| `lib/modules/warehouse_inventory/infrastructure/repositories/supabase_warehouse_repository.dart` | 64–69 | In-memory filtering for `fetchInventory` |
| `lib/modules/water_quality/presentation/dialogs/parametro_modal.dart` | 446–447 | Fallback tenant defaults `c1000000-...` / `u1000000-...` |

### 2.3 Proposed Dynamic Resolution Pattern
The company/tenant ID and active unit ID are already managed in `AuthProvider` / `AuthState`:
```dart
final authState = ref.read(authProvider);
final empresaId = authState.currentCompany?.id ?? authState.currentUser?.empresaId;
final unitId = authState.activeUnitId ?? authState.currentUser?.unidadAcuicolaId;
```
All repository methods should receive `empresaId` and execute parameterized Supabase queries directly:
```dart
final res = await _supabase
    .from('parametros_calidad_agua')
    .select('*')
    .eq('empresa_id', empresaId)
    .order('fecha', ascending: false)
    .limit(50);
```

---

## 3. Biometrics & Mortality Data Layer Investigation

### 3.1 Biometrics Audit
- **Current State:**
  - `BiometriaModal` (`lib/modules/ponds_batches/presentation/dialogs/biometria_modal.dart`) captures: `peces_capturados` (int), `peso_total_captura_kg` (double), calculated `peso_promedio_g`, calculated `biomasa_parcial_kg`, `longitud_cm` (optional), Fulton K factor, accumulated GDP, and notes.
  - Submits via `ref.read(pondsProvider.notifier).recordBiometry(...)`.
  - `SupabasePondsRepository.registerBiometry` writes only 4 fields to table `biometrias`:
    ```dart
    await _supabase.from('biometrias').insert({
      'id': const Uuid().v4(),
      'estanque_id': estanqueId,
      'batch_id': loteId,
      'avg_weight_gr': nuevoPesoPromedioGramos,
      'total_biomass_kg': newBiomass,
      'date': DateTime.now().toIso8601String().split('T')[0],
      'created_at': DateTime.now().toIso8601String(),
    });
    ```
  - `empresa_id` and `unit_id` are **omitted**.
  - No `Biometria` model exists in `lib/modules/ponds_batches/domain/models/`.
  - There is **no read method** (e.g. `fetchBiometriesByEstanque` or `fetchBiometriesByUnit`) in `PondsRepository`.
  - In `BitacoraScreen`, `_buildBiometryTab` displays only current `batches` from `pondsState.batches` with an estimated GDP calculation (`(b.pesoActualGramos - b.pesoInicialGramos) / dias`). It does not show historical sampling logs.

### 3.2 Mortality Audit
- **Current State:**
  - `MortalidadModal` (`lib/modules/ponds_batches/presentation/dialogs/mortalidad_modal.dart`) captures: `estanque_id`, `lote_id`, `muertos` (quantity), `peso_promedio_g`, calculated `biomasa_perdida_kg`, `causa_probable`, `fecha`, and notes.
  - Submits via `ref.read(pondsProvider.notifier).recordMortality(...)`.
  - `SupabasePondsRepository.registerMortality` writes only 4 fields to table `mortalidad`:
    ```dart
    await _supabase.from('mortalidad').insert({
      'id': const Uuid().v4(),
      'estanque_id': estanqueId,
      'batch_id': loteId,
      'quantity': cantidadPecesMuertos,
      'cause': causaProbable,
      'date': DateTime.now().toIso8601String().split('T')[0],
      'created_at': DateTime.now().toIso8601String(),
    });
    ```
  - `empresa_id`, `unit_id`, `peso_promedio_gramos`, `biomasa_perdida_kg`, `observaciones`, and `registrado_por` are **omitted**.
  - `MortalityRecord` model exists (`lib/modules/ponds_batches/domain/models/mortality_record.dart`), but is never used by the repository.
  - There is **no read method** (e.g. `fetchMortalityByUnit`) in `PondsRepository`.
  - In `BitacoraScreen`, `_buildMortalityTab` displays only active batches and computes `b.cantidadInicialPeces - b.cantidadActualPeces`. Real mortality event rows from table `mortalidad` are never displayed.

---

## 4. Daily Feeding & Nutrition Repository Audit

- **Domain Model:** `FeedingRecord` (`lib/modules/feeding_nutrition/domain/models/feeding_record.dart`)
- **Infrastructure:** `SupabaseNutritionRepository` (`lib/modules/feeding_nutrition/infrastructure/repositories/supabase_nutrition_repository.dart`)
- **Table `alimentacion_diaria` schema in Supabase:**
  - `id` (uuid, PK)
  - `estanque_id` (uuid, FK -> estanques)
  - `lote_id` (uuid, FK -> lotes)
  - `cantidad_consumida_kg` (numeric)
  - `costo_calculado` (numeric)
  - `fecha` (date)
  - `creado_en` (timestamptz)
  - `unidad_acuicola_sigla` (text)
  - `empresa_id` (uuid, FK -> empresas)
  - `unit_id` (uuid)
- **Insert Bug:** `recordFeeding()` prepares an insert payload with non-existent columns:
  ```dart
  final insertData = {
    'id': record.id,
    'empresa_id': empresaId,
    'unidad_acuicola_id': unidadAcuicolaId, // BUG: Column does not exist in alimentacion_diaria
    'estanque_id': estanqueId,
    'lote_id': loteId,
    if (insumoId != null) 'insumo_id': insumoId, // BUG: Column does not exist in alimentacion_diaria
    'cantidad_consumida_kg': kgConsumidos,
    'costo_calculado': costoTotal,
    'fecha': DateTime.now().toIso8601String().split('T')[0],
  };
  ```
  This causes Postgres to return `ERROR: 42703: column "unidad_acuicola_id" of relation "alimentacion_diaria" does not exist`, silently aborting the Supabase write.

---

## 5. Comprehensive Dart Model vs. Supabase Schema Discrepancy Matrix

| Entity | Dart Field / Model | Supabase Column (Actual DB) | Canonical SQL Spec (`v10`) | Discrepancy Type / Impact |
|---|---|---|---|---|
| **Calidad de Agua** | `WaterParameter.empresaId` | *(MISSING in `parametros_calidad_agua`)* | `empresa_id UUID NOT NULL` | **Critical:** Cannot filter by tenant or apply RLS |
| **Calidad de Agua** | `WaterParameter.unidadAcuicolaId` | `unidad_acuicola_sigla TEXT` | `unidad_acuicola_id UUID` | Data type mismatch (`uuid` vs `text` sigla) |
| **Calidad de Agua** | `WaterParameter.temperaturaC` | `temperatura NUMERIC` | `temperatura_c NUMERIC` | Column name mismatch (`temperatura` vs `temperatura_c`) |
| **Calidad de Agua** | `WaterParameter.registradoPor` | `registrado_por TEXT` | `registrado_por UUID` | Dart stores user name string, DB expects text, v10 spec specifies UUID FK |
| **Calidad de Agua** | *(RLS Policies)* | *(0 policies on `parametros_calidad_agua`)* | Strict multi-tenant RLS | **Critical:** RLS enabled with 0 policies blocks all client access |
| **Alimentación** | `FeedingRecord.unidadAcuicolaId` | `unit_id UUID` / `unidad_acuicola_sigla` | `unidad_acuicola_id UUID` | `insert` sends `'unidad_acuicola_id'`, fails with error 42703 |
| **Alimentación** | `FeedingRecord.insumoId` | *(MISSING in `alimentacion_diaria`)* | `insumo_id UUID` | `insert` sends `'insumo_id'`, fails with error 42703 |
| **Lotes / Batches** | `FishBatch.costoInicialAlevinos` | `costo_inicial_alevines NUMERIC` | `costo_inicial_alevinos NUMERIC` | Name mismatch (`alevinos` in Dart vs `alevines` in DB) |
| **Lotes / Batches** | `FishBatch.pesoActualGramos` | *(MISSING in `lotes`)* | `peso_actual_gramos NUMERIC` | Model expects `peso_actual_gramos`, column missing in DB `lotes` |
| **Lotes / Batches** | `FishBatch.fechaSiembra` | *(MISSING in `lotes`)* | `fecha_siembra DATE` | Model expects `fecha_siembra`, column missing in DB `lotes` |
| **Lotes / Batches** | `FishBatch.rolPolicultivo` | *(MISSING in `lotes`)* | *(Only in `siembra_details`)* | Missing column in `lotes` |
| **Mortalidad** | `MortalityRecord.loteId` | `batch_id TEXT` / `siembra_id UUID` | `lote_id UUID` | DB column is `batch_id` (text) or `siembra_id` |
| **Mortalidad** | `MortalityRecord.cantidadPecesMuertos` | `quantity INT` | `cantidad_peces_muertos INT` | Dart sends `cantidad_peces_muertos`, DB column is `quantity` |
| **Mortalidad** | `MortalityRecord.causaProbable` | `cause TEXT` | `causa_probable TEXT` | Dart sends `causa_probable`, DB column is `cause` |
| **Mortalidad** | `MortalityRecord.pesoPromedioGramos` | *(MISSING in `mortalidad`)* | `peso_promedio_gramos NUMERIC` | Column missing in DB `mortalidad` |
| **Mortalidad** | `MortalityRecord.biomasaPerdidaKg` | *(MISSING in `mortalidad`)* | `biomasa_perdida_kg NUMERIC` | Column missing in DB `mortalidad` |
| **Mortalidad** | `MortalityRecord.observaciones` | *(MISSING in `mortalidad`)* | `observaciones TEXT` | Column missing in DB `mortalidad` |
| **Biometría** | *(Model Missing)* | `avg_weight_gr NUMERIC`, `total_biomass_kg NUMERIC`, `batch_id TEXT` | `peces_capturados`, `peso_total_captura_kg`, `peso_promedio_g` | No Dart model exists; DB lacks capture counts and sampling metrics |
| **Unidades** | `AquacultureUnit.empresaId` | *(MISSING in `unidades_acuicolas`)* | `empresa_id UUID` | `unidades_acuicolas` lacks `empresa_id` FK |

---

## 6. Required Action Items & Strategic Plan

### 6.1 Database Schema Harmonization (Supabase Migration)
1. **Consolidate `parametros_calidad_agua`:**
   - Add `empresa_id UUID REFERENCES public.empresas(id) ON DELETE CASCADE`.
   - Add `unidad_acuicola_id UUID` (or `unit_id`).
   - Add index: `CREATE INDEX idx_parametros_agua_empresa_fecha ON public.parametros_calidad_agua(empresa_id, fecha DESC);`.
   - Create RLS policies for `SELECT` and `ALL` using `empresa_id = public.get_auth_empresa_id()`.
2. **Harmonize `alimentacion_diaria`:**
   - Add `unidad_acuicola_id UUID` and `insumo_id UUID REFERENCES public.inventory(id) ON DELETE SET NULL`.
   - Add index: `CREATE INDEX idx_alimentacion_empresa_fecha ON public.alimentacion_diaria(empresa_id, fecha DESC);`.
3. **Harmonize `biometrias` & `mortalidad`:**
   - Add missing columns to `biometrias`: `lote_id UUID`, `peces_capturados INT`, `peso_total_captura_kg NUMERIC`, `longitud_cm NUMERIC`, `factor_k NUMERIC`, `gdp_g_dia NUMERIC`, `observaciones TEXT`, `registrado_por TEXT`, `hora TIME`.
   - Add missing columns to `mortalidad`: `lote_id UUID`, `peso_promedio_gramos NUMERIC`, `biomasa_perdida_kg NUMERIC`, `observaciones TEXT`, `registrado_por TEXT`.
   - Add composite indexes on `(empresa_id, fecha DESC)` or `(empresa_id, estanque_id, fecha DESC)`.
4. **Deprecate Legacy Duplicate Tables:**
   - Migrate data from `water_quality` and `calidad_agua` into `parametros_calidad_agua`.
   - Migrate data from `mortality` into `mortalidad`.

### 6.2 Flutter / Dart Repository Layer Refactoring
1. **`SupabaseWaterQualityRepository`:**
   - Eliminate legacy writes to `water_quality`.
   - Make `parametros_calidad_agua` the single canonical target for reads and writes.
   - Replace in-memory UUID filtering with direct Supabase query filters: `.eq('empresa_id', empresaId)`.
2. **`SupabaseNutritionRepository`:**
   - Align insert payload field keys with actual DB columns.
   - Filter queries with `.eq('empresa_id', empresaId)`.
3. **`PondsRepository` / `BiometriasRepository` / `MortalityRepository`:**
   - Create domain model `Biometria` with JSON serialization matching canonical table.
   - Add repository read methods: `fetchBiometries(String empresaId, {String? estanqueId})` and `fetchMortality(String empresaId, {String? estanqueId})`.
   - Update `recordBiometry` and `recordMortality` to persist all captured form fields with `empresa_id` and `unit_id`.
4. **`BitacoraScreen` UI Update:**
   - Update tab 3 ("Biometrías y GDP") to consume historical biometry records from the provider.
   - Update tab 4 ("Bajas y Sanidad") to consume real mortality incident records from the provider.
   - Ensure the pond filter bottom sheet dynamically filters all 4 tabs concurrently.
