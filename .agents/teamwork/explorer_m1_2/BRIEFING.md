# BRIEFING — 2026-10-27T18:21:00Z

## Mission
Investigate repository logic, polyculture biomass calculation, harvest sales deduction, and ICA report export for Milestone 1.

## 🔒 My Identity
- Archetype: explorer
- Roles: investigator, synthesizer
- Working directory: c:\Users\Freddy\Desktop\Desarrollo de app\FishBit\.agents\teamwork\explorer_m1_2\
- Original parent: 0b489b89-04fe-4257-87de-f07ede87224b
- Milestone: Milestone 1

## 🔒 Key Constraints
- Read-only investigation — do NOT implement
- Output structured findings in handoff.md following 5-component protocol
- Verify all file paths, line numbers, and logic chains directly

## Current Parent
- Conversation ID: 0b489b89-04fe-4257-87de-f07ede87224b
- Updated: 2026-10-27T18:21:00Z

## Investigation State
- **Explored paths**:
  - `lib/modules/ponds_batches/infrastructure/repositories/supabase_ponds_repository.dart` (lines 380-425, 448-685, 800-945, 980-1109)
  - `lib/modules/ponds_batches/presentation/providers/ponds_provider.dart` (lines 80-235)
  - `lib/modules/sales_harvest/presentation/providers/sales_provider.dart` (lines 1-121)
  - `lib/modules/sales_harvest/infrastructure/repositories/supabase_sales_repository.dart` (lines 75-145)
  - `lib/core/events/app_event_bus.dart` (lines 20-50)
  - `lib/modules/sales_harvest/domain/models/batch_sale.dart` (lines 1-90)
  - `lib/modules/ponds_batches/domain/models/fish_batch.dart` (lines 150-256)
  - `lib/modules/ponds_batches/domain/models/pond.dart` (lines 1-60, 115-197)
  - `lib/core/reports/web_download_helper.dart`, `web_download_helper_stub.dart`, `web_download_helper_web.dart`
  - `lib/core/reports/ica_official_reports_engine.dart` (lines 1-70, 740-760, 875-940)
  - `pubspec.yaml` and `pubspec.lock` (dependencies audit)
- **Key findings**:
  1. Transfer/Split: `transferOrSplitBatch` executes 5 separate non-atomic REST calls; overwrites origin and destination pond biomass rather than aggregating active lots. Should invoke PostgreSQL atomic RPC `split_or_transfer_batch`.
  2. Polyculture Biomass: In `registerMortality` (:935), `registerBiometry` (:1098), and `createBatch` (:418), pond biomass is overwritten with only the affected lot's biomass, obliterating other species' biomass in polyculture ponds. Verified solution: implement `_syncPondBiomassAndCount(estanqueId)` querying all active lots in that pond.
  3. Harvest Sales Deduction: `HarvestSaleRecordedEvent` lacks `pecesVendidos`. `PondsNotifier._handleHarvestSaleRecorded` (:189-205) updates biomass but completely skips `cantidadActualPeces` deduction, creating "phantom fish". Furthermore, it overwrites pond biomass without polyculture aggregation. Verified solution: add `pecesVendidos` to event, pass from `sales_repository`, compute exact or proportional deduction in `PondsNotifier`, and recalculate pond biomass across remaining active lots.
  4. Non-web ICA Reports: In `ica_official_reports_engine.dart:55`, `if (bytes != null && kIsWeb)` explicitly blocks non-web platforms. In `web_download_helper_stub.dart`, the body is empty. Verified solution: remove `&& kIsWeb`, wire `path_provider` (already in `pubspec.lock` v2.1.6) and `share_plus` in `web_download_helper_stub.dart` to save to temp directory and invoke `Share.shareXFiles`. Web conditional export guarantees zero breakage of web compilation.
- **Unexplored areas**: None for Milestone 1 scope.

## Key Decisions Made
- Fully analyzed and designed drop-in code recommendations for Worker across the 4 key areas.

## Artifact Index
- DISPATCH.md — Incoming task dispatch record
- BRIEFING.md — Persistent working memory
- progress.md — Liveness heartbeat
- handoff.md — Comprehensive 5-component investigation report
