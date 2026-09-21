# DISPATCH — Reviewer M3_1 (Code & Interface Review)

## Mission
Perform an independent and rigorous code review of Milestone 3 deliverables (UX-01 and UX-02):
- `lib/modules/ponds_batches/presentation/widgets/pond_bento_card.dart`
- `lib/core/design_system/floating_dock_layout.dart`
- `lib/app/main_navigation_shell.dart`
- Refactored FAB screens (`ponds_dashboard_screen.dart`, `warehouse_screen.dart`, `bitacora_screen.dart`, `water_quality_records_screen.dart`, `finance_screen.dart`, `sales_screen.dart`, `gestion_equipo_screen.dart`)
- Test file: `test/modules/ponds_batches/pond_bento_card_test.dart`

## Key References
- Authoritative requirements: `c:\Users\Freddy\Desktop\Desarrollo de app\FishBit\.agents\ORIGINAL_REQUEST.md`
- Worker M3_1 handoff report: `c:\Users\Freddy\Desktop\Desarrollo de app\FishBit\.agents\worker_m3_1\handoff.md`
- Project scope & architecture: `c:\Users\Freddy\Desktop\Desarrollo de app\FishBit\.agents\orchestrator_impl_gen2\PROJECT.md`

## Verification Requirements
1. Verify all touch targets in `pond_bento_card.dart` comply with WCAG 2.5.5 (>= 48x48 dp).
2. Verify the 52.0 dp primary field action button (`"REGISTRAR ACCIÓN DE CAMPO"`) and the 60.0 dp operational modal bottom sheet with all 5 field routines (Alimentar, Calidad de Agua, Muestreo Biometría, Bajas, Traslado/Cosecha).
3. Verify `FloatingDockFabLocation.endFloat` correctly computes FAB coordinates without hardcoded offsets, taking safe area and keyboard into account.
4. Verify `main_navigation_shell.dart` has `SafeArea(bottom: true)` and hides dock on keyboard open.
5. Verify 0 occurrences of `bottom: 78` in `lib/`.
6. Run `flutter analyze --no-fatal-infos` and `flutter test test/modules/ponds_batches/pond_bento_card_test.dart`.
7. Deliver a clear verdict: `APPROVE` or `REQUEST_CHANGES`.

Write your handoff report to `c:\Users\Freddy\Desktop\Desarrollo de app\FishBit\.agents\reviewer_m3_1\handoff.md` and send a completion message to the orchestrator.

## 2026-09-14T15:04:06Z
You are Reviewer M3_1.
Your working directory is: c:\Users\Freddy\Desktop\Desarrollo de app\FishBit\.agents\reviewer_m3_1
Read your instructions in c:\Users\Freddy\Desktop\Desarrollo de app\FishBit\.agents\reviewer_m3_1\DISPATCH.md.
MANDATORY: Read c:\Users\Freddy\Desktop\Desarrollo de app\FishBit\.agents\ORIGINAL_REQUEST.md first.
Perform independent code review of Milestone 3 deliverables in lib/modules/ponds_batches/presentation/widgets/pond_bento_card.dart, lib/core/design_system/floating_dock_layout.dart, lib/app/main_navigation_shell.dart, and the 7 refactored FAB screens.
Run flutter analyze --no-fatal-infos and flutter test test/modules/ponds_batches/pond_bento_card_test.dart.
Issue clear verdict (APPROVE or REQUEST_CHANGES).
Write your report to c:\Users\Freddy\Desktop\Desarrollo de app\FishBit\.agents\reviewer_m3_1\handoff.md and notify orchestrator via send_message.

