# Task Dispatch: Explorer M2_2 (ICA Validation & Field Requirements)

## Mission
Investigate validation rules in `lib/modules/water_quality/presentation/dialogs/parametro_modal.dart` and define exact ICA regulatory validation logic for field routine parameters.

## Scope & Inputs
- `c:\Users\Freddy\Desktop\Desarrollo de app\FishBit\.agents\ORIGINAL_REQUEST.md` (MUST READ)
- `c:\Users\Freddy\Desktop\Desarrollo de app\FishBit\.agents\orchestrator_impl_gen2\PROJECT.md`
- `c:\Users\Freddy\Desktop\Desarrollo de app\FishBit\lib/modules/water_quality/presentation/dialogs/parametro_modal.dart`

## Requirements
1. Read `ORIGINAL_REQUEST.md` first.
2. Examine the submission / validation logic in `parametro_modal.dart` (saving parameters).
3. Determine how to enforce mandatory validation for routine parameters:
   - Oxígeno Disuelto: required, valid range 0 to 30 mg/L
   - Temperatura: required, valid range 5 to 45 °C
   - pH: required, valid range 0 to 14
   - Estanque (pond selection): required
4. Ensure robust decimal comma support (converting `,` to `.` before `double.tryParse`).
5. Provide user feedback (Snackbars / inline form validation errors) when validation fails, preventing save.
6. Write your report to `c:\Users\Freddy\Desktop\Desarrollo de app\FishBit\.agents\explorer_m2_2\handoff.md`.
7. Use `send_message` to notify the orchestrator when done.

## 2026-09-14T13:50:45Z
You are Explorer M2_2.
Your working directory is: c:\Users\Freddy\Desktop\Desarrollo de app\FishBit\.agents\explorer_m2_2
Read your instructions in c:\Users\Freddy\Desktop\Desarrollo de app\FishBit\.agents\explorer_m2_2\DISPATCH.md.
MANDATORY: Read c:\Users\Freddy\Desktop\Desarrollo de app\FishBit\.agents\ORIGINAL_REQUEST.md first.
Investigate validation rules, ICA compliance, mandatory parameters (O2, Temp, pH, pond selection), and decimal comma handling in parametro_modal.dart.
Write your structured handoff report to c:\Users\Freddy\Desktop\Desarrollo de app\FishBit\.agents\explorer_m2_2\handoff.md.
Send a message to the orchestrator when complete.
