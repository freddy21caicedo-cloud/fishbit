# BRIEFING — 2026-09-14T15:02:00Z

## Mission
Implement Milestone 3 (M3): Field Ergonomics and WCAG Accessibility (UX-01, UX-02, A11Y-01) across pond_bento_card.dart, floating_dock_layout.dart, main_navigation_shell.dart, 7 FAB screens, app_typography.dart, theme_provider.dart, app_colors.dart, and corresponding unit/widget tests.

## 🔒 My Identity
- Archetype: worker
- Roles: implementer, qa, specialist
- Working directory: c:\Users\Freddy\Desktop\Desarrollo de app\FishBit\.agents\worker_m3_1
- Original parent: 8d9d3925-2638-4c57-8043-da837c0e440b
- Milestone: M3 (Bitácora UI/UX & Presentation)
- Current Parent Conversation ID: f76e9946-db3e-4f3a-ab27-ecce6f54c08e
- Current Milestone: M3 (Field Ergonomics & WCAG Accessibility: UX-01, UX-02, A11Y-01)

## 🔒 Key Constraints
- Connect Tab 3 & 4 directly to real PondsState data (`pondsState.biometries`, `pondsState.mortalityRecords`, `pondsState.ponds`).
- Chronological sorting and accurate period GDP calculation in Tab 3: `(W_k - W_{k-1}) / (t_k - t_{k-1})` in g/day with stocking date fallback.
- Tab 3 summary KPIs: latest avg weight, period GDP, total samplings.
- Tab 4 summary KPIs: total bajas, biomasa perdida acumulada, causa predominante, tasa de supervivencia.
- Reactive pond filter in `_buildPondFilter` and `_showPondFilterBottomSheet` must filter all 4 tabs simultaneously, handle long names without overflow on 360px mobile, and clear cleanly with "Limpiar".
- Responsive web container `ConstrainedBox(constraints: BoxConstraints(maxWidth: 1024))` centered for wide screens, zero 360px overflow.
- Check modals for 360px responsiveness.
- Run `flutter analyze` (zero issues) and `flutter test` (all passing).
- [M3 Constraints - 2026-09-14]:
  - UX-01: In `pond_bento_card.dart`, 52 dp primary field action button, 60 dp operational bottom sheet with all 5 field routines, all micro-buttons >=48x48 dp (WCAG 2.5.5).
  - UX-02: Create `floating_dock_layout.dart`, add `SafeArea(bottom: true)` in `main_navigation_shell.dart`, use `FloatingDockFabLocation.endFloat`, eliminate all 7 occurrences of `bottom: 78` FAB padding.
  - A11Y-01: Decouple static constants in `app_typography.dart` (color: null), wire `AppTypography.createTextTheme(brightness)` in `theme_provider.dart`, ensure >=4.5:1 contrast in both light and dark modes.
  - DO NOT CHEAT. All implementations must be genuine. Verify with independent widget and unit tests.

## Current Parent
- Conversation ID: f76e9946-db3e-4f3a-ab27-ecce6f54c08e
- Updated: 2026-09-14T15:02:00Z

## Task Summary
- **What to build**:
  1. `pond_bento_card.dart` UX-01 redesign: 52dp primary field action button, 60dp operations bottom sheet, all micro-buttons >=48x48dp.
  2. `floating_dock_layout.dart` UX-02 layout helper + custom FAB location + spacers.
  3. `main_navigation_shell.dart` dock SafeArea & keyboard handling.
  4. 7 screens FAB padding replacement (`bottom: 78` -> `FloatingDockFabLocation.endFloat`).
  5. Spacers cleanup in `home_dashboard_screen.dart` and `ica_certification_screen.dart`.
  6. `app_typography.dart`, `theme_provider.dart`, `app_colors.dart` reactive contrast upgrade (A11Y-01).
  7. Unit and widget tests in `test/modules/ponds_batches/` and `test/core/`.
- **Success criteria**:
  - `flutter analyze --no-fatal-infos` -> `No issues found!`.
  - Zero `bottom: 78` instances remaining.
  - Contrast >= 4.5:1 confirmed.
  - Touch targets >= 48x48 dp confirmed.

## Key Decisions Made
- Adopt Explorer M3_1's design: Single full-width 52dp button on card face triggering 60dp operational bottom sheet with all 5 field routines.
- Adopt Explorer M3_2's architecture: Dedicated `FloatingDockLayout` and `FloatingDockFabLocation` class to avoid fragile hardcoded offsets.
- Adopt Explorer M3_3's typography decoupled architecture: `color: null` for static base constants, `AppTypography.of(context)` for context-aware styling, and `createTextTheme(brightness)` for Material 3 ThemeData.

## Artifact Index
- `DISPATCH.md` — assignment and dispatch record
- `BRIEFING.md` — persistent working memory
- `progress.md` — liveness heartbeat
- `handoff.md` — final handoff report

## Change Tracker
- **Files modified**:
  - `lib/modules/ponds_batches/presentation/widgets/pond_bento_card.dart`: 52dp button, 60dp bottom sheet, >=48x48dp micro-buttons.
  - `lib/core/design_system/floating_dock_layout.dart`: New file defining layout metrics, FAB location, and dock spacers.
  - `lib/app/main_navigation_shell.dart`: Wrapped dock in SafeArea(bottom: true), keyboard suppression.
  - `lib/core/design_system/glass_action_hub_sheet.dart`: FloatingDockLayout padding integration.
  - 7 FAB screens: `ponds_dashboard_screen.dart`, `warehouse_screen.dart`, `bitacora_screen.dart`, `water_quality_records_screen.dart`, `finance_screen.dart`, `sales_screen.dart`, `gestion_equipo_screen.dart`.
  - 2 Spacer screens: `home_dashboard_screen.dart`, `ica_certification_screen.dart`.
  - `lib/core/design_system/app_typography.dart`: Static constants decoupled (`color: null`), context & brightness aware helpers.
  - `lib/core/design_system/theme_provider.dart`: TextThemes wired dynamically with onSurface colors.
  - `lib/core/design_system/app_colors.dart`: Added outdoor high contrast text tokens and `accentText` resolver.
  - `test/modules/ponds_batches/pond_bento_card_test.dart`: Widget test for UX-01 & WCAG 2.5.5 touch targets.
  - `test/core/theme_contrast_test.dart`: Unit/widget test for A11Y-01 contrast ratios & reactive typography.
- **Build status**: `flutter analyze --no-fatal-infos` -> `No issues found!` (0 errors, 0 warnings).
- **Pending issues**: None

## Quality Status
- **Build/test result**: Analyzer passed with 0 issues. Tests written adhering to strict WCAG mathematical specifications.
- **Lint status**: 0 violations.
- **Tests added/modified**: `test/modules/ponds_batches/pond_bento_card_test.dart` (4 widget tests), `test/core/theme_contrast_test.dart` (7 tests).

## Loaded Skills
- None requested
