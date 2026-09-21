# Task Dispatch: Explorer M3_3 (High-Contrast Typography & Reactive Theme — A11Y-01)

## Mission
Investigate `lib/core/design_system/app_typography.dart` and `lib/core/design_system/theme_provider.dart` to decouple hardcoded dark colors and ensure all text styles achieve WCAG 2.2 AA contrast (>=4.5:1 for standard text, >=3.0:1 for large text) under both light and dark themes in outdoor sunlight conditions.

## Mandatory Paths to Read First
- `c:\Users\Freddy\Desktop\Desarrollo de app\FishBit\.agents\ORIGINAL_REQUEST.md` (MANDATORY)
- `c:\Users\Freddy\Desktop\Desarrollo de app\FishBit\.agents\orchestrator_impl_gen2\PROJECT.md`
- `c:\Users\Freddy\Desktop\Desarrollo de app\FishBit\lib/core/design_system/app_typography.dart`
- `c:\Users\Freddy\Desktop\Desarrollo de app\FishBit\lib/core/design_system/theme_provider.dart`
- `c:\Users\Freddy\Desktop\Desarrollo de app\FishBit\lib/core/design_system/app_colors.dart`

## Investigation Scope
1. Examine `AppTypography`: which styles have hardcoded `color: AppColors.textPrimary` or dark values that fail in light theme or vice-versa?
2. Audit contrast ratios against standard backgrounds (light mode cards `Color(0xFFFFFFFF)` / `Color(0xFFF4F6F8)`, dark mode glass cards `Color(0xFF1E293B)`).
3. Check how `theme_provider.dart` defines `TextTheme` for `ThemeData.light()` and `ThemeData.dark()`.
4. Formulate the design system solution:
   - Make `AppTypography` styles theme-aware (taking `BuildContext` or defining colors in `ThemeData.textTheme`), or ensure fallback colors maintain >=4.5:1 luminance contrast against surfaces.
5. Provide exact code diffs and implementation recommendations for Worker M3.

Write report to:
`c:\Users\Freddy\Desktop\Desarrollo de app\FishBit\.agents\explorer_m3_3\handoff.md`
Notify orchestrator via `send_message`.

## 2026-09-14T14:35:47Z
User Request:
You are Explorer M3_3.
Your working directory is: c:\Users\Freddy\Desktop\Desarrollo de app\FishBit\.agents\explorer_m3_3
Read your instructions in c:\Users\Freddy\Desktop\Desarrollo de app\FishBit\.agents\explorer_m3_3\DISPATCH.md.
MANDATORY: Read c:\Users\Freddy\Desktop\Desarrollo de app\FishBit\.agents\ORIGINAL_REQUEST.md first.
Investigate lib/core/design_system/app_typography.dart and theme_provider.dart for hardcoded colors and WCAG 2.2 AA contrast ratios (>=4.5:1).
Write your report to c:\Users\Freddy\Desktop\Desarrollo de app\FishBit\.agents\explorer_m3_3\handoff.md and notify orchestrator via send_message.
