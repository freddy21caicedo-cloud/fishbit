## 2026-10-27T18:24:07Z
You are worker_m1.
Working directory: c:\Users\Freddy\Desktop\Desarrollo de app\FishBit\.agents\teamwork\worker_m1\

MANDATORY INTEGRITY WARNING:
DO NOT CHEAT. All implementations must be genuine. DO NOT hardcode test results, create dummy/facade implementations, or circumvent the intended task. A teamwork_preview_auditor will independently verify your work. Integrity violations WILL be detected and your work WILL be rejected.

Mission:
Implement all items of Milestone 1: Database Schema, Atomic RPC & Data Traceability.

Read the Authoritative Request:
c:\Users\Freddy\Desktop\Desarrollo de app\FishBit\.agents\teamwork\ORIGINAL_REQUEST.md

Read the Master Audit Report:
c:\Users\Freddy\Desktop\Desarrollo de app\FishBit\.agents\teamwork\orchestrator_1\FINAL_AUDIT_REPORT.md

Read the Project Document:
c:\Users\Freddy\Desktop\Desarrollo de app\FishBit\.agents\teamwork\orchestrator_2\PROJECT.md

Read and follow the Explorer Reports:
- Database Schema & Migration: c:\Users\Freddy\Desktop\Desarrollo de app\FishBit\.agents\teamwork\explorer_m1_1\handoff.md
- Repositories & Traceability: c:\Users\Freddy\Desktop\Desarrollo de app\FishBit\.agents\teamwork\explorer_m1_2\handoff.md
- 8 Field Dialogs: c:\Users\Freddy\Desktop\Desarrollo de app\FishBit\.agents\teamwork\explorer_m1_3\handoff.md

Your Assigned Tasks & File Ownership:
1. `supabase/migrations/20261027_master_traceability_and_rls_hardening.sql`:
   - Create and populate with the exact canonical SQL from `explorer_m1_1\handoff.md §4.1`.
2. `lib/modules/ponds_batches/infrastructure/repositories/supabase_ponds_repository.dart`:
   - Implement `_syncPondBiomassAndCount(estanqueId)` helper.
   - Replace biomass overwriting in `registerMortality`, `registerBiometry`, and `createBatch` (both Supabase and demo modes) per `explorer_m1_2\handoff.md §4.4`.
   - Update `transferOrSplitBatch` to invoke atomic RPC `split_or_transfer_batch`.
3. `lib/core/events/app_event_bus.dart`:
   - Add `final int pecesVendidos;` to `HarvestSaleRecordedEvent` per `explorer_m1_2\handoff.md §4.1`.
4. `lib/modules/sales_harvest/infrastructure/repositories/supabase_sales_repository.dart`:
   - Pass `pecesVendidos: sale.cantidadPeces` when firing `HarvestSaleRecordedEvent`.
5. `lib/modules/ponds_batches/presentation/providers/ponds_provider.dart`:
   - In `_handleHarvestSaleRecorded`, implement proportional fish count deduction and polyculture biomass aggregation per `explorer_m1_2\handoff.md §4.3`.
6. `pubspec.yaml`:
   - Verify/add `share_plus` (e.g. `^10.0.0` or `^9.0.0`) and `path_provider` if needed, and run `flutter pub get`.
7. `lib/core/reports/web_download_helper_stub.dart`:
   - Implement native file saving to temporary directory and invoke `Share.shareXFiles` per `explorer_m1_2\handoff.md §4.5`.
8. `lib/core/reports/ica_official_reports_engine.dart`:
   - Remove `&& kIsWeb` guard in `_downloadExcel` per `explorer_m1_2\handoff.md §4.5`.
9. The 8 Field Dialogs per `explorer_m1_3\handoff.md §4`:
   - `lib/modules/water_quality/presentation/dialogs/parametro_modal.dart`
   - `lib/modules/ponds_batches/presentation/dialogs/siembra_modal.dart`
   - `lib/modules/ponds_batches/presentation/dialogs/mortalidad_modal.dart`
   - `lib/modules/ponds_batches/presentation/dialogs/biometria_modal.dart`
   - `lib/modules/ponds_batches/presentation/dialogs/traslado_modal.dart`
   - `lib/modules/sales_harvest/presentation/dialogs/venta_rapida_modal.dart`
   - `lib/modules/auth_tenant/presentation/dialogs/crear_colaborador_modal.dart`
   - `lib/modules/ica_compliance/presentation/dialogs/ica_biosecurity_modals.dart`
10. Run `flutter analyze` and existing tests:
   - Run `flutter analyze --no-fatal-infos` across the modified files.
   - Run affected tests and record verification outputs.

Write your completion report to `c:\Users\Freddy\Desktop\Desarrollo de app\FishBit\.agents\teamwork\worker_m1\handoff.md` and report back via send_message.
