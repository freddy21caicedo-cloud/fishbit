## 2026-08-28T23:22:13Z
You are the Flutter Data Layer & Persistence Worker for Milestone 2 (M2).
Your working directory is: c:\Users\Freddy\Desktop\Desarrollo de app\FishBit\.agents\worker_m2_1
Workspace root: c:\Users\Freddy\Desktop\Desarrollo de app\FishBit
Supabase Project ID: oakovawlwjpnoydpwtam

Read the following reference files:
1. ORIGINAL_REQUEST.md: c:\Users\Freddy\Desktop\Desarrollo de app\FishBit\.agents\ORIGINAL_REQUEST.md
2. PROJECT.md: c:\Users\Freddy\Desktop\Desarrollo de app\FishBit\.agents\orchestrator_main_1\PROJECT.md
3. M1 Worker Handoff: c:\Users\Freddy\Desktop\Desarrollo de app\FishBit\.agents\worker_m1_1\handoff.md
4. Repos Survey Analysis: c:\Users\Freddy\Desktop\Desarrollo de app\FishBit\.agents\survey_repos_1\analysis.md

MANDATORY INTEGRITY WARNING:
DO NOT CHEAT. All implementations must be genuine. DO NOT hardcode test results, create dummy/facade implementations, or circumvent the intended task. A teamwork_preview_auditor will independently verify your work. Integrity violations WILL be detected and your work WILL be rejected.

Milestone 2 Scope & Objectives:
1. `SupabaseWaterQualityRepository` (`lib/modules/water_quality/infrastructure/repositories/supabase_water_quality_repository.dart`):
   - Make `parametros_calidad_agua` the single canonical table for both reads and writes.
   - Remove the double-write attempt to `water_quality`.
   - Remove hardcoded UUID filters (`3500cc63-...`, `54dedaac-...`).
   - In `fetchRecentParametersByUnit()`, query `parametros_calidad_agua` directly using `.eq('empresa_id', empresaId)` (and/or `.eq('unit_id', unitId)` / `.eq('unidad_acuicola_id', unitId)`), ordering by `fecha` DESC.
   - In `recordParameters()`, insert into `parametros_calidad_agua` including `empresa_id`, `unit_id`, and all 10 physicochemical parameters + `hora`.
2. `SupabaseNutritionRepository` (`lib/modules/feeding_nutrition/infrastructure/repositories/supabase_nutrition_repository.dart`):
   - In `recordFeeding()`, ensure inserted keys match the `alimentacion_diaria` schema (`estanque_id`, `lote_id`, `fecha`, `hora`, `alimento_marca`, `alimento_tipo`, `proteina_pct`, `tamano_pellet_mm`, `cantidad_kg`, `empresa_id`, `unit_id`, `unidad_acuicola_id`, `insumo_id`, etc.).
   - Remove hardcoded UUID in-memory filtering; use native Supabase `.eq('empresa_id', empresaId)`.
3. Domain Models for Biometry & Mortality:
   - Create/update `BiometriaRecord` in `lib/modules/ponds_batches/domain/models/biometria_record.dart` (or appropriate model file) with full fields: `id`, `estanqueId`, `batchId`/`loteId`, `fecha`/`date`, `hora`, `pecesCapturados`, `pesoTotalCapturaKg`, `pesoPromedioG`, `biomasaParcialKg`, `longitudCm`, `gdpGDia`, `observaciones`, `registradoPor`, `empresaId`, `unitId`, and JSON serialization methods (`fromJson`, `toJson`).
   - Update `MortalityRecord` in `lib/modules/ponds_batches/domain/models/mortality_record.dart` to support both bilingual field synonyms (`quantity`/`cantidad`, `cause`/`causa`, `pesoPromedioGramos`, `biomasaPerdidaKg`, `fecha`/`date`, `hora`, `loteId`/`batchId`, `estanqueId`, `empresaId`, `unitId`).
4. `PondsRepository` & `SupabasePondsRepository` (`lib/modules/ponds_batches/`):
   - Add abstract methods to `PondsRepository`:
     `Future<List<BiometriaRecord>> fetchBiometriesByUnit(String unitId, {String? pondId, String? batchId});`
     `Future<List<MortalityRecord>> fetchMortalityByUnit(String unitId, {String? pondId, String? batchId});`
   - Implement these methods in `SupabasePondsRepository`: query `biometrias` and `mortalidad` with `.eq('empresa_id', empresaId)` (and/or unit filter), ordered by date DESC.
   - Update `registerBiometry` and `registerMortality` to save full payloads with `empresa_id`, `unit_id`, `peces_capturados`, `peso_promedio_g`, `biomasa_parcial_kg`, `longitud_cm`, `causa`, `peso_promedio_gramos`, `biomasa_perdida_kg`.
   - Remove hardcoded UUID checks across all methods in `SupabasePondsRepository`.
5. Riverpod State (`lib/modules/ponds_batches/presentation/providers/ponds_provider.dart`):
   - Update `PondsState` to include `final List<BiometriaRecord> biometries;` and `final List<MortalityRecord> mortalityRecords;`.
   - Update `PondsNotifier.loadData(String unitId)` to fetch `biometries` and `mortalityRecords` alongside ponds and batches.
   - Update `recordBiometry` and `recordMortality` in `PondsNotifier` to prepend/refresh the newly inserted records in state so the UI updates immediately.
6. Check other related repositories/files if necessary to ensure `flutter analyze` passes cleanly without compilation errors or type warnings.
