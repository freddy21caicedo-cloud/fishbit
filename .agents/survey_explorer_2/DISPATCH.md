# Survey Explorer 2 Dispatch: Regulatory Data Integrity & WCAG Ergonomics (R2 & R3)
Date: 2026-09-13T23:37:35Z
Target Scope:
1. Water quality modal in `lib/modules/water_quality/presentation/dialogs/parametro_modal.dart` (ensure numeric controllers start completely empty, remove simulated defaults, enforce mandatory validation for O2, Temp, pH before save).
2. Field ergonomics in `lib/modules/ponds_batches/presentation/widgets/pond_bento_card.dart` (micro-buttons to WCAG 2.5.5 minimum 48x48 dp touch target, primary action button / bottom sheet for wet field conditions).
3. Navigation shell in `lib/app/main_navigation_shell.dart` (`SafeArea(bottom: true)`, insets, eliminate gesture bar overlap and remove fragile bottom padding hacks like `bottom: 78`).
4. Typography & colors in `AppTypography` / theme tokens (ensure reactive light/dark theme adaptation, minimum 4.5:1 contrast ratio WCAG 2.2 AA for outdoor sunlight).
Original Request: c:\Users\Freddy\Desktop\Desarrollo de app\FishBit\.agents\ORIGINAL_REQUEST.md
Working Directory: c:\Users\Freddy\Desktop\Desarrollo de app\FishBit\.agents\survey_explorer_2
Output file: c:\Users\Freddy\Desktop\Desarrollo de app\FishBit\.agents\survey_explorer_2\handoff.md
