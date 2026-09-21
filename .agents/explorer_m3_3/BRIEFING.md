# BRIEFING — 2026-09-14T09:41:00-05:00

## Mission
Investigate `lib/core/design_system/app_typography.dart` and `lib/core/design_system/theme_provider.dart` to decouple hardcoded dark colors and ensure all text styles achieve WCAG 2.2 AA contrast (>=4.5:1 for standard text, >=3.0:1 for large text) under both light and dark themes in outdoor sunlight conditions.

## 🔒 My Identity
- Archetype: explorer
- Roles: investigation, synthesis
- Working directory: c:\Users\Freddy\Desktop\Desarrollo de app\FishBit\.agents\explorer_m3_3
- Original parent: f76e9946-db3e-4f3a-ab27-ecce6f54c08e
- Milestone: M3 (Field Ergonomics & WCAG A11y)

## 🔒 Key Constraints
- Read-only investigation — do NOT implement
- Do not modify application source code
- Investigate lib/core/design_system/app_typography.dart and theme_provider.dart
- WCAG 2.2 AA contrast ratios (>=4.5:1 for standard text, >=3.0:1 for large text)
- Propose concrete code diffs and recommendations for Worker M3 in handoff.md

## Current Parent
- Conversation ID: f76e9946-db3e-4f3a-ab27-ecce6f54c08e
- Updated: 2026-09-14T09:41:00-05:00

## Investigation State
- **Explored paths**:
  - `lib/core/design_system/app_typography.dart`
  - `lib/core/design_system/theme_provider.dart`
  - `lib/core/design_system/app_colors.dart`
  - `lib/core/design_system/glass_card.dart`
  - `lib/core/design_system/glass_container.dart`
  - `lib/core/design_system/glass_form_field.dart`
  - `lib/core/design_system/glass_badge.dart`
  - `lib/core/design_system/glass_button.dart`
  - `lib/modules/ponds_batches/presentation/widgets/pond_bento_card.dart`
  - `lib/modules/ponds_batches/presentation/screens/ponds_dashboard_screen.dart`
  - `lib/modules/water_quality/presentation/dialogs/parametro_modal.dart`
  - `lib/modules/water_quality/presentation/screens/water_quality_records_screen.dart`
- **Key findings**:
  - `AppTypography` statically binds all 9 base `TextStyle` constants to `textPrimaryDark` (`#FFFFFF`) or `textSecondaryDark` (`#8E9BAE`).
  - In light theme, on `surfaceLight` (`#FFFFFF`) and `backgroundLight` (`#F6F8FA`), these styles result in catastrophic contrast failures: 1.0:1 (pure white on white, invisible) and 2.64-2.81:1 (light slate on white, failing 4.5:1 minimum).
  - Neither `appDarkTheme` nor `appLightTheme` in `theme_provider.dart` defines `textTheme` or `primaryTextTheme`.
  - Brand accents (`cyanWater` #00B2CC, `greenBiomass` #10B981, `amberWarning` #FF9500) achieve ~7-8:1 in dark mode, but fail severely in light mode (2.2-2.5:1 on white).
  - A 3-pillar architectural solution completely decouples static colors (setting base static TextStyle colors to `null` to inherit `DefaultTextStyle` reactively), introduces `AppTypography.of(context)` / `context.appTypography`, generates a complete Material 3 `TextTheme` via `AppTypography.createTextTheme(brightness)`, and configures light/dark `textTheme` in `theme_provider.dart`.
- **Unexplored areas**:
  - None within M3_3 scope.

## Key Decisions Made
- Neutral base constants (`color: null`) ensure 100% backward compatibility for all 45+ call sites without breaking `const` or `copyWith(...)`.
- `AppTypographyData` and `AppTypography.of(context)` / `context.appTypography` provide type-safe, theme-aware tokens.
- `AppTypography.createTextTheme(brightness)` wires into `theme_provider.dart` for system-wide Material 3 compliance.
- High-contrast text variants for brand accents documented for Worker M3.

## Artifact Index
- `progress.md` — Heartbeat and step tracking
- `handoff.md` — Final comprehensive 5-component report for Worker M3 and Orchestrator
