## 2026-08-31T20:06:06Z

You are the Frontend Flutter Performance Specialist Worker for Milestone 2: Flutter Frontend Performance Optimization.

Your working directory is:
c:\Users\Freddy\Desktop\Desarrollo de app\FishBit\.agents\worker_m2_fe

Read the authoritative documents first:
1. c:\Users\Freddy\Desktop\Desarrollo de app\FishBit\.agents\ORIGINAL_REQUEST.md
2. c:\Users\Freddy\Desktop\Desarrollo de app\FishBit\.agents\explorer_survey_fe\handoff.md
3. c:\Users\Freddy\Desktop\Desarrollo de app\FishBit\PROJECT.md

MANDATORY INTEGRITY WARNING:
DO NOT CHEAT. All implementations must be genuine. DO NOT hardcode test results, create dummy/facade implementations, or circumvent the intended task. A teamwork_preview_auditor will independently verify your work. Integrity violations WILL be detected and your work WILL be rejected.

Your Tasks:
1. **Network Waterfall Parallelization**:
   - In `lib/modules/ponds_batches/presentation/providers/ponds_provider.dart` (`loadPondsAndBatches`), `lib/modules/finance_payroll/presentation/providers/finance_provider.dart` (`loadFinanceData`), and `lib/modules/ica_compliance/presentation/providers/ica_compliance_provider.dart` (`loadAllRecords`): replace sequential `await` calls with `Future.wait([...])`.

2. **`PondsDashboardScreen` & `PondBentoCard`**:
   - In `lib/modules/ponds_batches/presentation/screens/ponds_dashboard_screen.dart`: Use Riverpod `.select()` on `pondsProvider` for scalar metrics; memoize batch-to-pond grouping; replace rigid `childAspectRatio: 1.5` in Grid with `SliverGridDelegateWithMaxCrossAxisExtent(maxCrossAxisExtent: 440, mainAxisExtent: 330)` to eliminate RenderFlex overflow on tablet/desktop (700px-880px).
   - In `lib/modules/ponds_batches/presentation/widgets/pond_bento_card.dart`: Add `RepaintBoundary` around card content and optimize 3D flip animation to avoid reconstructing front/back card widget trees on every frame tick; ensure operational buttons don't clip on 360px.

3. **`BitacoraScreen` Viewport Virtualization & Memoization**:
   - In `lib/modules/bitacora/presentation/screens/bitacora_screen.dart`: Convert all 4 tabs (`_buildWaterQualityTab`, `_buildNutritionTab`, `_buildBiometryTab`, `_buildMortalityTab`) from un-virtualized `ListView(children: records.map(...).toList())` to lazy virtualized `ListView.builder` or `ListView.separated`.
   - Memoize biometry sorting and historical GDP deltas in memoized providers/helpers instead of in-line UI sorting and O(N*M) scans. Replace linear `where(...).firstOrNull` lookups with O(1) map indexing.

4. **`IcaCertificationScreen` Optimization**:
   - In `lib/modules/ica_compliance/presentation/screens/ica_certification_screen.dart`: Memoize `IcaOfficialReportsEngine` instantiation and ensure format cards are virtualized cleanly without performance penalty.

5. **Responsive Layout Hardening (360px - 1920px)**:
   - In `lib/core/design_system/fishbit_header.dart`: Make `FishBitHeader` flexible and overflow-free on 360px screens (wrap `CompanyPillButton` in `Flexible` with proper padding).
   - In `lib/modules/finance_payroll/presentation/screens/finance_screen.dart`: Fix horizontal 3-button FAB Row to prevent RenderFlex overflow on <400px viewports (use a responsive layout, popup menu or wrap).

6. **Controller Lifecycle & Memory Leak Fixes**:
   - In `lib/modules/warehouse_inventory/presentation/screens/warehouse_screen.dart`: Properly dispose controllers in `_showQuickEntryDialog` and add debounce to search listener.
   - In `lib/modules/warehouse_inventory/presentation/dialogs/nueva_factura_modal.dart`: Dispose existing `EditableInvoiceItem` controllers before clearing `_items`.

7. **Verification**:
   - Run `flutter test` via `run_command` and ensure all tests (including `bitacora_screen_test.dart` and `ponds_notifier_test.dart`) pass 100%.
   - Run `flutter analyze --no-fatal-infos` to confirm 0 errors/warnings.
   - Write a comprehensive `handoff.md` in `c:\Users\Freddy\Desktop\Desarrollo de app\FishBit\.agents\worker_m2_fe\handoff.md` and send a message back when completed.
