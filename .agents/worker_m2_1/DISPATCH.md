# Task Dispatch: Worker M2 (Regulatory Data Integrity ICA: DATA-01)

## Mission
Implement all DATA-01 requirements in `lib/modules/water_quality/presentation/dialogs/parametro_modal.dart`, create comprehensive widget test suite in `test/modules/water_quality/parametro_modal_test.dart`, and update `test/modules/bitacora/bitacora_screen_test.dart` so all water quality and bitacora tests pass and `flutter analyze --no-fatal-infos` returns `No issues found!`.

## Mandatory Paths to Read First
- `c:\Users\Freddy\Desktop\Desarrollo de app\FishBit\.agents\ORIGINAL_REQUEST.md` (MANDATORY)
- `c:\Users\Freddy\Desktop\Desarrollo de app\FishBit\.agents\orchestrator_impl_gen2\PROJECT.md`
- `c:\Users\Freddy\Desktop\Desarrollo de app\FishBit\.agents\explorer_m2_1\handoff.md`
- `c:\Users\Freddy\Desktop\Desarrollo de app\FishBit\.agents\explorer_m2_2\handoff.md`
- `c:\Users\Freddy\Desktop\Desarrollo de app\FishBit\.agents\explorer_m2_3\handoff.md`

## File Ownership
You have EXCLUSIVE write access to:
- `lib/modules/water_quality/presentation/dialogs/parametro_modal.dart`
- `test/modules/water_quality/parametro_modal_test.dart`
- `test/modules/bitacora/bitacora_screen_test.dart`

DO NOT modify files outside these paths.

## Mandatory Requirements
1. **Zero-Defaults & No Fabricated Data**:
   - Ensure all 11 parameter controllers initialize completely empty (`text = ''`).
   - Eliminate hardcoded demo tenant ID (`?? 'c1000000-0000-0000-0000-000000000001'`).
   - Ensure an active pond selection is required before submission.
2. **Robust Decimal Comma Handling**:
   - Implement `double? _parseDecimal(String? text)` that trims whitespace and substitutes `,` with `.`.
   - Apply `_parseDecimal` across all real-time alert triggers, field validators, and `WaterParameter` save payload construction.
3. **Strict ICA Regulatory Range Validation**:
   - **Oxígeno Disuelto**: Required, range 0.0 to 30.0 mg/L.
   - **Temperatura**: Required, range 5.0 to 45.0 °C.
   - **pH**: Required, range 0.0 to 14.0.
   - **Pond Selection**: Mandatory.
4. **User Feedback**:
   - If pond is not selected, display descriptive SnackBar: `'Debe seleccionar un estanque de medición para registrar los parámetros.'`.
   - If form validation fails, display descriptive SnackBar directing the user to fix required parameters within valid ranges.
5. **Widget Test Suite**:
   - Implement `test/modules/water_quality/parametro_modal_test.dart` using the 5-test suite designed in `explorer_m2_3/handoff.md` (empty state, mandatory validation, biological bounds, comma parsing, and dynamic alerts).
6. **Fix `bitacora_screen_test.dart`**:
   - Update out-of-sync assertions in `test/modules/bitacora/bitacora_screen_test.dart` (lines 518-520 and 596-600) as identified in `explorer_m2_3/handoff.md`.
7. **Verification & Cleanliness**:
   - Run `flutter analyze --no-fatal-infos` -> MUST return `No issues found!`.
   - Run `flutter test test/modules/water_quality/` -> All tests pass!
   - Run `flutter test test/modules/bitacora/` -> All tests pass!

## MANDATORY INTEGRITY WARNING
DO NOT CHEAT. All implementations must be genuine. DO NOT hardcode test results, create dummy/facade implementations, or circumvent the intended task. A teamwork_preview_auditor will independently verify your work. Integrity violations WILL be detected and your work WILL be rejected.

## Handoff Requirements
Write your detailed report to:
`c:\Users\Freddy\Desktop\Desarrollo de app\FishBit\.agents\worker_m2_1\handoff.md`
Include:
1. Observation (exact diffs and changes made)
2. Logic Chain
3. Caveats
4. Conclusion (verdict: PASS)
5. Verification commands and verbatim outputs
Notify orchestrator via `send_message`.

## 2026-09-14T13:57:35Z
Implement all DATA-01 requirements in lib/modules/water_quality/presentation/dialogs/parametro_modal.dart, create test/modules/water_quality/parametro_modal_test.dart, update test/modules/bitacora/bitacora_screen_test.dart, run flutter analyze --no-fatal-infos and tests, and ensure all pass cleanly.

