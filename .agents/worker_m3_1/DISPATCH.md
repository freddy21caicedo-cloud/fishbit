# Task Dispatch: Worker M3 (Field Ergonomics & WCAG Accessibility: UX-01, UX-02, A11Y-01)

## Mission
Implement all Milestone 3 requirements across `pond_bento_card.dart`, `main_navigation_shell.dart`, `app_typography.dart`, `theme_provider.dart`, and the 7 FAB padding screens, create verification widget/contrast tests, and ensure `flutter analyze --no-fatal-infos` returns `No issues found!`.

## Mandatory Paths to Read First
- `c:\Users\Freddy\Desktop\Desarrollo de app\FishBit\.agents\ORIGINAL_REQUEST.md` (MANDATORY)
- `c:\Users\Freddy\Desktop\Desarrollo de app\FishBit\.agents\orchestrator_impl_gen2\PROJECT.md`
- `c:\Users\Freddy\Desktop\Desarrollo de app\FishBit\.agents\explorer_m3_1\handoff.md` (MUST READ: exact code diff for pond_bento_card.dart)
- `c:\Users\Freddy\Desktop\Desarrollo de app\FishBit\.agents\explorer_m3_2\handoff.md` (MUST READ: exact code diff for navigation dock & FABs)
- `c:\Users\Freddy\Desktop\Desarrollo de app\FishBit\.agents\explorer_m3_3\handoff.md` (MUST READ: exact code diff for typography & themes)

## File Ownership
You have EXCLUSIVE write access to:
- `lib/modules/ponds_batches/presentation/widgets/pond_bento_card.dart`
- `lib/core/design_system/floating_dock_layout.dart` (new)
- `lib/app/main_navigation_shell.dart`
- `lib/core/design_system/app_typography.dart`
- `lib/core/design_system/theme_provider.dart`
- `lib/core/design_system/app_colors.dart`
- The 7 screens with `bottom: 78` FAB padding:
  - `lib/modules/ponds_batches/presentation/screens/ponds_dashboard_screen.dart`
  - `lib/modules/warehouse_inventory/presentation/screens/warehouse_screen.dart`
  - `lib/modules/bitacora/presentation/screens/bitacora_screen.dart`
  - `lib/modules/water_quality/presentation/screens/water_quality_records_screen.dart`
  - `lib/modules/finances/presentation/screens/finance_screen.dart`
  - `lib/modules/commercial_sales/presentation/screens/sales_screen.dart`
  - `lib/modules/auth_tenant/presentation/screens/gestion_equipo_screen.dart`
- Tests:
  - `test/modules/ponds_batches/pond_bento_card_test.dart`
  - `test/core/theme_contrast_test.dart`

## Mandatory Requirements
1. **UX-01 (Bento Card Touch Targets & Operational Sheet)**:
   - Implement `SizedBox(width: double.infinity, height: 52)` primary action button on card front face.
   - Implement `_showOperationsBottomSheet` and `_PondOperationsSheetContent` with large 60 dp action tiles for Alimentar, Calidad de Agua (with `preselectedPondId: widget.pond.id`), Muestreo Biometría, Registrar Bajas, and Traslado/Cosecha.
   - Upgrade all micro-buttons on front and back card faces to >=48x48 dp (WCAG 2.5.5).
2. **UX-02 (Navigation Dock & Gesture Bar SafeArea)**:
   - Create `lib/core/design_system/floating_dock_layout.dart` with `FloatingDockFabLocation.endFloat` and `DockBottomSpacer`.
   - Update `main_navigation_shell.dart` to wrap dock in `SafeArea(bottom: true)` with bottom padding and keyboard suppression.
   - Eliminate all 7 occurrences of `Padding(padding: const EdgeInsets.only(bottom: 78))` on FABs, replacing with `floatingActionButtonLocation: FloatingDockFabLocation.endFloat`.
3. **A11Y-01 (High-Contrast Typography & Reactive Theme)**:
   - Decouple static constants in `AppTypography` by removing hardcoded dark colors (`color: null` fallback).
   - Wire `AppTypography.createTextTheme(brightness)` into both `appDarkTheme` and `appLightTheme` in `theme_provider.dart`.
   - Ensure text contrast >=4.5:1 (WCAG 2.2 AA) against card surfaces in both themes.
4. **Verification & Cleanliness**:
   - Run `flutter analyze --no-fatal-infos` -> MUST return `No issues found!`.
   - Run tests: `flutter test test/modules/ponds_batches/` and `flutter test test/core/`.

## MANDATORY INTEGRITY WARNING
DO NOT CHEAT. All implementations must be genuine. DO NOT hardcode test results, create dummy/facade implementations, or circumvent the intended task. A teamwork_preview_auditor will independently verify your work. Integrity violations WILL be detected and your work WILL be rejected.

Write your report to:
`c:\Users\Freddy\Desktop\Desarrollo de app\FishBit\.agents\worker_m3_1\handoff.md`
Notify orchestrator via `send_message`.

## 2026-09-14T14:43:11Z
You are Worker M3_1.
Your working directory is: c:\Users\Freddy\Desktop\Desarrollo de app\FishBit\.agents\worker_m3_1
Read your instructions in c:\Users\Freddy\Desktop\Desarrollo de app\FishBit\.agents\worker_m3_1\DISPATCH.md.
MANDATORY: Read c:\Users\Freddy\Desktop\Desarrollo de app\FishBit\.agents\ORIGINAL_REQUEST.md first.
Also read handoffs:
- c:\Users\Freddy\Desktop\Desarrollo de app\FishBit\.agents\explorer_m3_1\handoff.md
- c:\Users\Freddy\Desktop\Desarrollo de app\FishBit\.agents\explorer_m3_2\handoff.md
- c:\Users\Freddy\Desktop\Desarrollo de app\FishBit\.agents\explorer_m3_3\handoff.md

Implement all UX-01, UX-02, and A11Y-01 requirements:
1. pond_bento_card.dart: 52 dp primary field action button, 60 dp operational bottom sheet with all 5 field routines, all micro-buttons >=48x48 dp.
2. floating_dock_layout.dart & main_navigation_shell.dart: SafeArea(bottom: true), FloatingDockFabLocation.endFloat, eliminate all 7 occurrences of bottom: 78 FAB padding hacks.
3. app_typography.dart & theme_provider.dart: decouple hardcoded dark colors, wire createTextTheme(brightness) for WCAG 2.2 AA (>=4.5:1) reactive contrast.
4. Add tests in test/modules/ponds_batches/ and test/core/.
5. Verify flutter analyze --no-fatal-infos and tests pass 100%.
