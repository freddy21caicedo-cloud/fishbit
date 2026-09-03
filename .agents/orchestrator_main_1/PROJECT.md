# Project: FishBit Bitácora Audit & Fix

## Architecture
FishBit is a Flutter + Riverpod + Supabase multi-tenant aquaculture management platform.
- **Frontend Presentation Layer**: `lib/modules/bitacora/presentation/screens/bitacora_screen.dart`, `lib/modules/*/presentation/dialogs/*`
- **State Management Layer**: `Riverpod` (`waterQualityProvider`, `nutritionProvider`, `pondsProvider`, `authProvider`, `farmContextNotifierProvider`)
- **Domain & Repository Layer**: `lib/modules/*/domain/models/`, `lib/modules/*/infrastructure/repositories/`
- **Backend Database**: Supabase PostgreSQL (`parametros_calidad_agua`, `alimentacion_diaria`, `biometrias`, `mortalidad`, `lotes`, `estanques`, `units`, `empresas`) with Row-Level Security (RLS) and multi-tenancy.

## Feature Inventory
| # | Feature | Description | Milestone | Source |
|---|---------|-------------|-----------|--------|
| 1 | Water Quality Canonical Table & RLS | Make `parametros_calidad_agua` canonical with 10 parameters + hora, add `empresa_id`/`unit_id`, add RLS policies | M1 (DONE) | ORIGINAL_REQUEST §R1, §R2 |
| 2 | Legacy Water Quality Migration | Safely migrate 11 rows from `water_quality` into `parametros_calidad_agua` and deprecate `calidad_agua` | M1 (DONE) | ORIGINAL_REQUEST §R2, Survey DB |
| 3 | Performance Indexes & Idempotent SQL | Add `(empresa_id, fecha/date DESC)` indexes on all 4 Bitácora tables | M1 (DONE) | ORIGINAL_REQUEST §R2 |
| 4 | Mortality & Biometry DB Alignment | Ensure `biometrias` and `mortalidad` schemas support all required fields, backfill null `empresa_id` | M1 (DONE) | ORIGINAL_REQUEST §R1, §R2 |
| 5 | Water Quality Repository Persistence | Point `SupabaseWaterQualityRepository` to `parametros_calidad_agua`, remove double writes and fallback | M2 (DONE) | ORIGINAL_REQUEST §R1 |
| 6 | Eliminate Hardcoded UUIDs | Replace hardcoded company UUID filters with native Supabase `.eq('empresa_id', empresaId)` | M2 (DONE) | ORIGINAL_REQUEST §R1 |
| 7 | Feeding Insert & Model Fix | Fix `SupabaseNutritionRepository` column mismatches and queries | M2 (DONE) | Survey Repos |
| 8 | Biometries & Mortality Repositories | Add `fetchBiometriesByUnit` & `fetchMortalityByUnit` and complete write payloads in `SupabasePondsRepository` | M2 (DONE) | ORIGINAL_REQUEST §R1 |
| 9 | Riverpod State Integration | Add `biometries` and `mortalityRecords` collections and fetch logic to `PondsState` / `PondsNotifier` | M2 (DONE) | ORIGINAL_REQUEST §R1, Survey UI |
| 10 | Biometrics Tab & GDP Calculation | Update Tab 3 to show sampling history and period GDP $(W_k - W_{k-1}) / \Delta t$ | M3 | ORIGINAL_REQUEST §R3 |
| 11 | Mortality Tab Real Logs | Update Tab 4 to display real mortality events, causes, quantities, and cumulative % | M3 | ORIGINAL_REQUEST §R3 |
| 12 | Reactive Pond Filter | Ensure pond filter Bottom Sheet allows any active pond and reactively filters all 4 tabs | M3 | ORIGINAL_REQUEST §R3 |
| 13 | Responsive Layout & Overflow Fix | Fix RenderFlex overflow on 360px mobile viewports (header filter row, modals) and web >768px | M3 | ORIGINAL_REQUEST §R3 |
| 14 | Flutter Analyze & Verification | Ensure `flutter analyze` returns `No issues found!` and automated verification passes | M4 | ORIGINAL_REQUEST Acceptance Criteria |

## Milestones
| # | Name | Scope | Dependencies | Status |
|---|------|-------|-------------|--------|
| M1 | Database Schema, Migrations, Indexes & RLS | Execute idempotent SQL migrations in Supabase: add columns, RLS policies, migrate legacy rows, create indexes | none | DONE |
| M2 | Supabase Repositories & Data Persistence Layer | Update Flutter repositories, domain models, remove hardcoded UUIDs, add biometry/mortality read/write, integrate Riverpod state | M1 | DONE |
| M3 | Bitácora UI/UX, GDP Calculation & Responsive Layout | Update Tab 3 (Biometrías & GDP), Tab 4 (Bajas & Sanidad), reactive 4-tab filter, resolve RenderFlex overflows | M2 | IN_PROGRESS |
| M4 | Final Verification, Static Analysis & Gate Verification | Run `flutter analyze`, execute test harness, adversarial audit, and verify all acceptance criteria | M3 | PLANNED |

## Interface Contracts
### Supabase DB ↔ Repositories
- `parametros_calidad_agua`: `id`, `estanque_id`, `fecha`, `hora`, `oxigeno_mg_l`, `oxigeno_pct`, `ph`, `temperatura`, `amonio_mg_l`, `nitritos_mg_l`, `nitratos_mg_l`, `alcalinidad_mg_l`, `co2_mg_l`, `dureza_mg_l`, `cloro_mg_l`, `fosforo_mg_l`, `observaciones`, `registrado_por`, `empresa_id`, `unit_id`
- `biometrias`: `id`, `estanque_id`, `batch_id` / `lote_id`, `fecha` / `date`, `peces_capturados`, `peso_total_captura_kg`, `avg_weight_gr` / `peso_promedio_g`, `total_biomass_kg` / `biomasa_parcial_kg`, `longitud_cm`, `empresa_id`, `unit_id`, `observaciones`
- `mortalidad`: `id`, `estanque_id`, `batch_id` / `lote_id`, `date` / `fecha`, `quantity` / `cantidad`, `cause` / `causa`, `peso_promedio_gramos`, `biomasa_perdida_kg`, `observaciones`, `registrado_por`, `empresa_id`, `unit_id`

### Repositories ↔ Riverpod Notifiers
- `PondsRepository.fetchBiometriesByUnit(String empresaId, String unidadAcuicolaId, {String? pondId, String? batchId}) -> Future<List<BiometriaRecord>>`
- `PondsRepository.fetchMortalityByUnit(String empresaId, String unidadAcuicolaId, {String? pondId, String? batchId}) -> Future<List<MortalityRecord>>`
- `PondsNotifier.loadData(String unitId)` / `loadPondsAndBatches()` populates `ponds`, `batches`, `biometries`, `mortalityRecords`

## Code Layout
- `lib/modules/bitacora/presentation/screens/bitacora_screen.dart`
- `lib/modules/water_quality/infrastructure/repositories/supabase_water_quality_repository.dart`
- `lib/modules/feeding_nutrition/infrastructure/repositories/supabase_nutrition_repository.dart`
- `lib/modules/ponds_batches/infrastructure/repositories/supabase_ponds_repository.dart`
- `lib/modules/ponds_batches/domain/models/biometria_record.dart`
- `lib/modules/ponds_batches/domain/models/mortality_record.dart`
- `lib/modules/ponds_batches/presentation/providers/ponds_provider.dart`
- `lib/modules/ponds_batches/presentation/dialogs/biometria_modal.dart`
- `lib/modules/ponds_batches/presentation/dialogs/mortalidad_modal.dart`
- `lib/modules/water_quality/presentation/dialogs/parametro_modal.dart`
