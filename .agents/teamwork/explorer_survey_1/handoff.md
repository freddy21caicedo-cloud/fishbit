# HANDOFF REPORT — R1 Data Traceability, Biological/Economic Lifecycle & Supabase Schemas

**Agent**: Explorer Subagent 1 (`explorer_survey_1`)  
**Mission**: R1 Aquaculture Data Traceability, Lifecycle Calculations & Supabase PostgreSQL / RLS Audit  
**Parent / Caller**: `8bee9cda-5a61-477e-925b-df39d71e3b3a`  
**Working Directory**: `c:\Users\Freddy\Desktop\Desarrollo de app\FishBit\.agents\teamwork\explorer_survey_1`  
**Full Report Reference**: `survey_report.md` (41 KB detailed technical audit with SQL/Dart proposed diffs)  
**Date**: 2026-10-27  

---

## 1. Observation

Direct code observations verified across the codebase with exact file paths and line numbers:

1. **Missing DDL for `public.traslados_lotes`**:
   - `supabase_migration_v10_canonical_v2.sql` and `supabase_schema_canonical_v10.sql` do not contain `CREATE TABLE public.traslados_lotes`.
   - `20260831_database_performance_and_rls_optimization.sql:1037-1049` declares:
     ```sql
     CREATE INDEX IF NOT EXISTS idx_traslados_lotes_lote_origen ON public.traslados_lotes(lote_origen_id);
     CREATE INDEX IF NOT EXISTS idx_traslados_lotes_lote_destino ON public.traslados_lotes(lote_destino_id);
     CREATE INDEX IF NOT EXISTS idx_traslados_lotes_fecha ON public.traslados_lotes(fecha_traslado DESC);
     ALTER TABLE public.traslados_lotes ENABLE ROW LEVEL SECURITY;
     ```
   - `lib/data/repositories/supabase_ponds_repository.dart:621` attempts to insert into `traslados_lotes`:
     ```dart
     await _client.from('traslados_lotes').insert({ ... });
     ```
   - Running migration in a clean environment fails on index creation and RLS enablement.

2. **Multi-Tenant RLS Leaks on High-Value Tables**:
   - `supabase/migrations/20260831_database_performance_and_rls_optimization.sql`:
     - Line 519 (`compras_mat_biologico`): `USING (unidad_acuicola_sigla = public.get_auth_unidad_sigla())`
     - Line 563 (`equipos`): `USING (unidad_acuicola_sigla = public.get_auth_unidad_sigla())`
     - Line 607 (`mantenimientos`): `USING (unidad_acuicola_sigla = public.get_auth_unidad_sigla())`
     - Line 881 (`facturas`): `USING (cliente_id = auth.uid())`
     - Line 998 (`inventario_insumos`): `USING (unidad_acuicola_sigla = public.get_auth_unidad_sigla())`
   - In `supabase_schema_canonical_v10.sql:39`, `unidades_acuicolas.sigla` is only unique scoped to `empresa_id` (`UNIQUE (empresa_id, sigla)`). Two distinct tenant companies with sigla `'PRIN'` or `'SEDE1'` can query and access each other's equipment, purchases, maintenance, and feed inventory.

3. **Polyculture Biomass Overwrite Bug**:
   - `lib/data/repositories/supabase_ponds_repository.dart:935` (`registerMortality`):
     ```dart
     await _client.from('estanques').update({
       'biomasa_kg': newBiomass,
       'updated_at': DateTime.now().toIso8601String(),
     }).eq('id', batch['estanque_id']);
     ```
   - `lib/data/repositories/supabase_ponds_repository.dart:1098` (`registerBiometry`):
     ```dart
     await _client.from('estanques').update({
       'biomasa_kg': newBiomass,
       'peso_promedio_g': event.pesoPromedioG,
       'updated_at': DateTime.now().toIso8601String(),
     }).eq('id', batch['estanque_id']);
     ```
   - When multiple batches (e.g., Tilapia and Cachama/Bocachico) share a single pond, recording mortality or biometry on one batch resets `estanques.biomasa_kg` to only that single batch's biomass, destroying the companion species' biomass from the pond aggregate.

4. **FCR Breakdown & Lack of Atomicity in Batch Desdoble / Transfer**:
   - `lib/data/repositories/supabase_ponds_repository.dart:584-633` (`transferOrSplitBatch`):
     - Executes 5 consecutive, uncoordinated client-side HTTP calls (`lotes.update`, `estanques.update`, `lotes.insert`, `estanques.update`, `traslados_lotes.insert`). Network failure midway produces orphaned batches or desynchronized pond counts.
     - While monetary costs (`costoTotal`, `costoAlimento`, etc.) are partitioned proportionally at line 593:
       ```dart
       costoTotal: (batch.costoTotal * (1 - ratio)).roundToDouble(),
       ```
       The historical feed consumption records in `public.alimentacion_diaria` are **not** split or re-assigned.
     - When FCR is calculated via `alimentoAcumuladoKg / gananciaBiomasaKg`, the parent batch retains 100% of the historical feed with only 50% of the biomass (artificially doubling its FCR), while the new child batch starts with 0 kg feed consumption (FCR becomes 0.0 or null).

5. **Ghost Fish Discrepancy on Harvest Sale**:
   - `lib/presentation/providers/ponds_provider.dart:189-203` (`recordHarvestSale`):
     ```dart
     final currentBiomass = pond.biomasaActualKg;
     final newBiomass = (currentBiomass - sale.biomasaVendidaKg).clamp(0.0, double.infinity);
     final updatedPond = pond.copyWith(
       biomasaActualKg: newBiomass,
       status: newBiomass <= 0 ? PondStatus.harvested : pond.status,
     );
     ```
   - The sold fish count (`sale.pecesVendidos` / `cantidadPeces`) is never decremented from `pond.cantidadActualPeces`. If a batch sells 1,000 kg (2,000 fish), the pond retains the original fish count with halved biomass. Recalculating average weight (`biomasa / peces`) yields half the real individual weight.

6. **ICA Official Regulatory Reports Platform Failure & Hardcoded Data**:
   - `lib/core/services/ica_official_reports_engine.dart:55`:
     ```dart
     if (kIsWeb) {
       _downloadExcelWeb(bytes, fileName);
     } else {
       // On mobile / desktop platforms
       _downloadExcel(bytes, fileName);
     }
     ```
     At line 224: `void _downloadExcel(List<int> bytes, String fileName) {}` is an **empty stub**. Running on Android, iOS, or Windows silently drops the generated bytes without writing to disk or launching a share intent.
   - Lines 107-119 & 137-142: Report F-06 (Limpieza y Desinfección) and Report F-12 (Monitoreo de Patógenos) inject hardcoded placeholder rows (`sampleRows`) instead of querying `bioseguridad_limpieza` and `sanidad_monitoreo_patogenos`.
   - Line 172-187: Report F-11 (Registro de Ingreso de Peces) hardcodes `'Alevinera Certificada del Huila'` and certificate `'REG-ICA-ALV-9941'` regardless of user input.

7. **Production Dialogs Pre-filled with Hardcoded Mock Defaults**:
   - `lib/presentation/widgets/modals/siembra_modal.dart:40-42`: Pre-fills `_cantidadController = TextEditingController(text: '5000')`, `_pesoInicialController = TextEditingController(text: '1.5')`, `_pesoObjetivoController = TextEditingController(text: '650')`.
   - `lib/presentation/widgets/modals/mortalidad_modal.dart:34, 59`: Pre-fills `_cantidadController = TextEditingController(text: '5')`, `_pesoPromedioController = TextEditingController(text: '250.0')`.
   - `lib/presentation/widgets/modals/biometria_modal.dart:33, 48-53`: Pre-fills `_pecesMuestreadosController = TextEditingController(text: '35')` and auto-calculates weight without physical weighing.
   - `lib/presentation/widgets/modals/traslado_modal.dart:50-51`: Fallbacks of `100.0`g and `1000` fish.
   - `lib/presentation/widgets/modals/venta_rapida_modal.dart:59`: `_precioKgController = TextEditingController(text: '9500')`.
   - `lib/presentation/widgets/modals/crear_colaborador_modal.dart:57, 59`: Pre-fills salary `$2,000,000 COP` and plaintext password `'FishBit.2026'`.
   - `lib/presentation/widgets/modals/ica_biosecurity_modals.dart:765-777`: Pre-fills normal necropsy text.
   - `lib/main.dart:33-41`: Production Supabase URL and anon JWT hardcoded as default fallbacks.

8. **Offline Sync Queue Inoperative**:
   - `lib/core/sync/offline_sync_queue.dart`: Defines `OfflineSyncQueue` with Hive storage, retry logic, and `flushQueue()`.
   - A search for `flushQueue` across the entire `lib/` directory shows it is never called anywhere in the app (neither in app startup, connectivity change listeners, nor repository sync hooks).

---

## 2. Logic Chain

1. **From Observation 1**: Because `public.traslados_lotes` lacks DDL, clean schema deployments fail. Any runtime batch transfer will throw a 404 or relation missing PostgreSQL error unless hot-patched.
2. **From Observation 2**: Because `sigla` is only unique within each company (`UNIQUE (empresa_id, sigla)`), tenants sharing common acronyms (`PRIN`, `SEDE1`) will have matching `get_auth_unidad_sigla()`. Since policies on 5 critical tables evaluate `unidad_acuicola_sigla` without filtering by `empresa_id = public.get_auth_empresa_id()`, multi-tenant isolation is breached.
3. **From Observation 3**: Setting `estanques.biomasa_kg = newBiomass` directly from a single batch assumes a strict 1-to-1 relationship between pond and batch. In polyculture operations where multiple batches co-exist in one pond, this statement forcibly overwrites total pond biomass, corrupting oxygenation, stocking density, and feeding rate algorithms.
4. **From Observation 4**: In aquaculture economics, $FCR = \frac{\text{Cumulative Feed (kg)}}{\text{Biomass Gain (kg)}}$. When a batch of 10,000 fish is split 50/50 after consuming 2,000 kg of feed, the parent batch now has 5,000 fish (~1,500 kg gain) with 2,000 kg recorded feed ($FCR = 1.33 \to \text{distorted to } 2.66$), while the child batch has 5,000 fish with 0 kg recorded feed ($FCR \to \text{undefined/0.0}$). Furthermore, performing this multi-table mutation across 5 separate REST calls over flaky rural mobile connectivity guarantees inconsistent state upon connection drop.
5. **From Observation 5**: If `biomasaActualKg` is reduced on sale without decrementing `cantidadActualPeces`, the pond model contains ghost fish. Any subsequent calculation of average weight ($W_{avg} = \text{Biomass} / N$) divides the remaining biomass by the old fish count, halving the perceived weight and triggering invalid feed table recommendations.
6. **From Observation 6**: ICA and AUNAP certifications require exact historical audit trails. Generating Excel files containing hardcoded sample data and dummy farm names (`Alevinera Certificada del Huila`) invalidates sanitary inspection books and exposes the producer to legal sanctions and loss of certification. The empty `_downloadExcel` stub on mobile completely prevents Colombian field operators from saving or exporting ICA books.
7. **From Observation 7**: Pre-filling form controllers with default numbers causes distracted field workers to tap "Confirmar" without entering real scale/counter measurements. This results in artificial batch sizes, uniform mortalities, and fictitious labor costs.
8. **From Observation 8**: Because `flushQueue` is never invoked, operations queued while offline in remote fish farms remain permanently in local Hive storage, never syncing to Supabase.

---

## 3. Caveats

1. **Read-Only Investigation**: In accordance with explorer subagent instructions, no source files or SQL migrations were modified. All solutions are provided as exact architectural specifications, proposed diffs, and SQL DDL/RLS snippets in `survey_report.md`.
2. **Third-Party Integrations**: Hardware telemetry sensors and IoT gateways were not examined as they are outside the scope of R1 data traceability and lifecycle schemas.
3. **Hive Storage Inspection**: Production local device Hive binary databases could not be inspected directly; analysis was performed from Dart models, repository adapters, and serialization schemas.

---

## 4. Conclusion

FishBit's data architecture has an advanced foundation (v10 canonical schema, Colombian ICA regulatory structures, polyculture data models, and cost engines), but suffers from **six critical production blockers**:

1. **Database Schema & Security**: Missing `traslados_lotes` DDL table and multi-tenant RLS data leaks on 5 tables via `unidad_acuicola_sigla`.
2. **Biological Integrity**: Polyculture biomass destruction on mortality/biometry updates, and ghost fish on partial harvest sales.
3. **Aquaculture Economics**: FCR mathematical distortion during batch desdoble/split, and non-atomic client-side REST mutations.
4. **Regulatory Non-Compliance**: ICA export engine fails silently on mobile platforms and outputs hardcoded dummy farm/pathogen rows.
5. **UI Data Contamination**: Mock/hardcoded text defaults across 8 production input modals.
6. **Offline Sync Dormancy**: Offline sync queue is completely disconnected from the application lifecycle.

**Action Plan**:
- Apply Migration `20261027_r1_traceability_and_rls_fixes.sql` (defined in `survey_report.md` Section 9.1).
- Implement atomic PostgreSQL RPC `public.split_or_transfer_batch` (defined in `survey_report.md` Section 9.2).
- Patch `SupabasePondsRepository` to calculate aggregate pond biomass via SQL SUM.
- Clear all pre-filled mock defaults in modal dialogs to `null` with strict form validators.
- Implement mobile Excel export via `path_provider` + `open_filex` / `share_plus` in `IcaOfficialReportsEngine`.
- Wire `OfflineSyncQueue.flushQueue()` into `Connectivity` listener and app startup.

---

## 5. Verification Method

To independently verify all findings and validate future fixes:

1. **Verify Missing DDL**:
   ```powershell
   grep -i "CREATE TABLE.*traslados_lotes" supabase/migrations/*.sql supabase/*.sql
   ```
   *Expected result*: No matches found (confirming missing DDL).

2. **Verify Multi-Tenant RLS Sigla Vulnerability**:
   Inspect `supabase/migrations/20260831_database_performance_and_rls_optimization.sql` lines 519, 563, 607, 881, 998. Notice the absence of `empresa_id = public.get_auth_empresa_id()`.

3. **Verify Polyculture Biomass Overwrite**:
   Inspect `lib/data/repositories/supabase_ponds_repository.dart` line 935 and 1098. Observe direct assignment of `biomasa_kg: newBiomass` to `estanques` without summing active lots.

4. **Verify ICA Mobile Export Stub**:
   Inspect `lib/core/services/ica_official_reports_engine.dart` lines 55-60 and line 224:
   ```dart
   void _downloadExcel(List<int> bytes, String fileName) {}
   ```

5. **Verify Modal Mock Defaults**:
   Inspect `lib/presentation/widgets/modals/siembra_modal.dart` lines 40-42, `mortalidad_modal.dart` line 34, `biometria_modal.dart` line 33.

6. **Verify Offline Sync Queue Inactivity**:
   ```powershell
   grep -rn "flushQueue" lib/
   ```
   *Expected result*: Only matches its own definition in `lib/core/sync/offline_sync_queue.dart`.

7. **Project Test Suite Verification**:
   Execute standard Flutter test suite:
   ```powershell
   flutter test
   ```
