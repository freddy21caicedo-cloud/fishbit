# Task Dispatch: Worker M2 Remediation (Iteration 2)

## Mission
Remediate the 5 concrete deficiencies identified by the Milestone 2 Gate Panel in `parametro_modal.dart`, `water_quality_provider.dart`, and associated test suites.

## Mandatory Paths to Read First
- `c:\Users\Freddy\Desktop\Desarrollo de app\FishBit\.agents\ORIGINAL_REQUEST.md` (MANDATORY)
- `c:\Users\Freddy\Desktop\Desarrollo de app\FishBit\.agents\orchestrator_impl_gen2\GATE_STATUS.md`
- `c:\Users\Freddy\Desktop\Desarrollo de app\FishBit\.agents\challenger_m2_2\handoff.md`
- `c:\Users\Freddy\Desktop\Desarrollo de app\FishBit\.agents\reviewer_m2_2\handoff.md`

## File Ownership
You have EXCLUSIVE write access to:
- `lib/modules/water_quality/presentation/dialogs/parametro_modal.dart`
- `lib/modules/water_quality/presentation/providers/water_quality_provider.dart`
- `test/modules/water_quality/parametro_modal_test.dart`
- `test/modules/water_quality/parametro_modal_adversarial_test.dart`

DO NOT modify files outside these paths.

## Remediation Requirements (All 5 Must Be Implemented)
1. **[CRITICAL] Synchronous Double-Tap & Concurrency Lock (`parametro_modal.dart`)**:
   - In `_ParametroModalState`, declare `bool _isSubmitting = false;`.
   - In `GlassButton`: bind `isLoading: _isSubmitting || waterState.isLoading`.
   - In `onPressed`: guard with:
     ```dart
     if (_isSubmitting) return;
     setState(() => _isSubmitting = true);
     try {
       // validation & save logic
     } finally {
       if (mounted) setState(() => _isSubmitting = false);
     }
     ```
2. **[HIGH] Asynchronous Failure Error Propagation & Feedback (`water_quality_provider.dart` & `parametro_modal.dart`)**:
   - In `lib/modules/water_quality/presentation/providers/water_quality_provider.dart`, update `recordWaterQuality`:
     ```dart
     Future<bool> recordWaterQuality(WaterParameter param) async {
       try {
         final saved = await _repository.recordParameters(param);
         state = state.copyWith(recentParameters: [saved, ...state.recentParameters]);
         return true;
       } catch (e) {
         state = state.copyWith(errorMessage: e.toString());
         return false;
       }
     }
     ```
   - In `parametro_modal.dart`: if `success` is false, do NOT pop dialog; display error SnackBar with `errorMessage`:
     ```dart
     if (success && mounted) {
       nav.pop();
       messenger.showSnackBar(
         const SnackBar(
           content: Text('¡Medición registrada con éxito con 11 parámetros y hora de toma!'),
           backgroundColor: AppColors.cyanWater,
         ),
       );
     } else if (!success && mounted) {
       messenger.showSnackBar(
         SnackBar(
           content: Text('Error al registrar medición: ${ref.read(waterQualityProvider).errorMessage ?? "Error de red"}'),
           backgroundColor: AppColors.coralAction,
         ),
       );
     }
     ```
3. **[HIGH] Add Missing Nitrite Warning Banner UI (`parametro_modal.dart`)**:
   - Inside the alert `Column` (between `isAmmoniaCritical` and `isChlorineAlert`), add the missing widget row for `if (isNitriteCritical)`:
     ```dart
     if (isNitriteCritical) ...[
       if (isHypoxia || isAmmoniaCritical) const SizedBox(height: 4),
       const Row(
         children: [
           Icon(Icons.warning_rounded, color: AppColors.coralAction, size: 16),
           SizedBox(width: 6),
           Expanded(
             child: Text(
               '¡Alerta Crítica! Nitritos NO₂⁻ > 0.2 ppm. Alto riesgo de toxicidad e hipoxia tisular.',
               style: TextStyle(color: AppColors.coralAction, fontSize: 11, fontWeight: FontWeight.w700),
             ),
           ),
         ],
       ),
     ],
     ```
4. **[HIGH] Stale/Invalid Preselected Pond Validation (`parametro_modal.dart`)**:
   - In `onPressed` pond validation, check:
     ```dart
     if (_selectedPondId == null || _selectedPondId!.isEmpty || !ponds.any((p) => p.id == _selectedPondId)) {
       messenger.showSnackBar(
         const SnackBar(
           content: Text('Debe seleccionar un estanque de medición válido para registrar los parámetros.'),
           backgroundColor: AppColors.coralAction,
         ),
       );
       return;
     }
     ```
5. **[MEDIUM] IEEE 754 `NaN` and `Infinite` Sanitization (`parametro_modal.dart`)**:
   - In `_parseDecimal(String? text)`, ensure `parsed.isNaN || parsed.isInfinite` returns `null`:
     ```dart
     double? _parseDecimal(String? text) {
       if (text == null) return null;
       final cleaned = text.trim().replaceAll(',', '.');
       if (cleaned.isEmpty) return null;
       final parsed = double.tryParse(cleaned);
       if (parsed == null || parsed.isNaN || parsed.isInfinite) return null;
       return parsed;
     }
     ```

6. **Test Suite Updates**:
   - Add tests in `test/modules/water_quality/parametro_modal_test.dart` verifying:
     - Rapid double-tap does not cause duplicate inserts.
     - Database error does not pop dialog and displays error SnackBar.
     - Critical nitrite value displays the nitrite warning banner text.
     - Stale `preselectedPondId` not in `ponds` is rejected by validator.
     - `"NaN"` input is rejected.

7. **Verification**:
   - `flutter analyze --no-fatal-infos` -> MUST return `No issues found!`.
   - `flutter test test/modules/water_quality/` -> All tests pass!

## MANDATORY INTEGRITY WARNING
DO NOT CHEAT. All implementations must be genuine. DO NOT hardcode test results, create dummy/facade implementations, or circumvent the intended task. A teamwork_preview_auditor will independently verify your work. Integrity violations WILL be detected and your work WILL be rejected.

Write your report to:
`c:\Users\Freddy\Desktop\Desarrollo de app\FishBit\.agents\worker_m2_remediation\handoff.md`
Notify orchestrator via `send_message`.

## 2026-09-14T14:19:41Z
You are Worker M2 Remediation.
Your working directory is: c:\Users\Freddy\Desktop\Desarrollo de app\FishBit\.agents\worker_m2_remediation
Read your instructions in c:\Users\Freddy\Desktop\Desarrollo de app\FishBit\.agents\worker_m2_remediation\DISPATCH.md.
MANDATORY: Read c:\Users\Freddy\Desktop\Desarrollo de app\FishBit\.agents\ORIGINAL_REQUEST.md first.
Also read:
- c:\Users\Freddy\Desktop\Desarrollo de app\FishBit\.agents\orchestrator_impl_gen2\GATE_STATUS.md
- c:\Users\Freddy\Desktop\Desarrollo de app\FishBit\.agents\challenger_m2_2\handoff.md
- c:\Users\Freddy\Desktop\Desarrollo de app\FishBit\.agents\reviewer_m2_2\handoff.md

Implement all 5 remediation items in lib/modules/water_quality/presentation/dialogs/parametro_modal.dart and lib/modules/water_quality/presentation/providers/water_quality_provider.dart.
Update test/modules/water_quality/parametro_modal_test.dart to verify all 5 fixes.
Run flutter analyze --no-fatal-infos and flutter test test/modules/water_quality/.

