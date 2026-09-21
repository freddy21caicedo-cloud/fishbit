# Handoff Report — Explorer M2_1: Modal Controllers & Default Values Audit (DATA-01)

- **Agent**: Explorer M2_1
- **Role**: Read-only Investigation & Synthesis
- **Date**: 2026-09-14T13:55:00Z
- **Target File**: `lib/modules/water_quality/presentation/dialogs/parametro_modal.dart`
- **Milestone**: M2 (Regulatory Data Integrity ICA — DATA-01)

---

## 1. Observation

### 1.1 TextEditingController Initializations
In `lib/modules/water_quality/presentation/dialogs/parametro_modal.dart` (lines 35–48):
```dart
35:   // 11 Parámetros Fisicoquímicos Solicitados (Vacíos por defecto - Integridad ICA DATA-01)
36:   final _oxigenoMgLCtrl = TextEditingController();
37:   final _oxigenoPctCtrl = TextEditingController();
38:   final _tempCtrl = TextEditingController();
39:   final _phCtrl = TextEditingController();
40:   final _amonioCtrl = TextEditingController();
41:   final _nitritosCtrl = TextEditingController();
42:   final _nitratosCtrl = TextEditingController();
43:   final _alcalinidadCtrl = TextEditingController();
44:   final _co2Ctrl = TextEditingController();
45:   final _durezaCtrl = TextEditingController();
46:   final _cloroCtrl = TextEditingController();
47:   final _obsCtrl = TextEditingController();
```
All 12 controllers are initialized via default `TextEditingController()`, which produces `text = ''` by default. There are no hardcoded string parameters passed to `TextEditingController(text: ...)` in the field declarations.
In `initState` (lines 54–57):
```dart
54:   @override
55:   void initState() {
56:     super.initState();
57:     _selectedPondId = widget.preselectedPondId;
58:   }
```
Controllers are neither populated nor assigned values during `initState`. All 12 controllers are correctly disposed in `dispose()` (lines 60–74).

### 1.2 Silent Fallback Default: Auto-selecting First Pond
In `lib/modules/water_quality/presentation/dialogs/parametro_modal.dart` (lines 88–90):
```dart
88:     if (_selectedPondId == null && ponds.isNotEmpty) {
89:       _selectedPondId = ponds.first.id;
90:     }
```
When `ParametroModal.show(context)` is opened without `preselectedPondId` (such as from `WaterQualityRecordsScreen:59` or `HomeDashboardScreen:315`), `_selectedPondId` begins as `null`. However, inside `build()`, lines 88–90 silently set `_selectedPondId = ponds.first.id`.
Consequently:
- The dropdown in lines 161–174 renders with the first pond automatically pre-selected.
- The user is not forced to explicitly choose a pond. If an operator is recording for Pond 3 but does not manually touch the dropdown, the data is silently saved under Pond 1.

### 1.3 Silent Fallback Default: Hardcoded Demo Company UUID
In `lib/modules/water_quality/presentation/dialogs/parametro_modal.dart` (lines 476–478):
```dart
476:                       final authState = ref.read(authProvider);
477:                       final empresaId = authState.currentCompany?.id ?? authState.currentUser?.empresaId ?? 'c1000000-0000-0000-0000-000000000001';
478:                       final unidadId = authState.activeUnitId ?? authState.currentUser?.unidadAcuicolaId ?? empresaId;
```
Line 477 contains `'c1000000-0000-0000-0000-000000000001'` as a hardcoded fallback string. If `empresaId` is null or unauthenticated, instead of halting with an error, the modal silently commits records under the mock tenant. In `supabase_water_quality_repository.dart` line 48 and 95, `c1000000-` IDs bypass Supabase and write to static in-memory demo data.

### 1.4 Decimal Parsing Defect in Reactive Alerts & Save Payload
In `lib/modules/water_quality/presentation/dialogs/parametro_modal.dart`:
1. Reactive Alert Logic (lines 92–95):
```dart
92:     final oxigeno = double.tryParse(_oxigenoMgLCtrl.text.trim());
93:     final amonio = double.tryParse(_amonioCtrl.text.trim());
94:     final nitritos = double.tryParse(_nitritosCtrl.text.trim());
95:     final cloro = double.tryParse(_cloroCtrl.text.trim());
```
2. Payload Serialization (lines 495–505):
```dart
495:                         oxigenoMgL: double.tryParse(_oxigenoMgLCtrl.text),
496:                         oxigenoPct: double.tryParse(_oxigenoPctCtrl.text),
497:                         ph: double.tryParse(_phCtrl.text),
498:                         temperaturaC: double.tryParse(_tempCtrl.text),
499:                         amonioMgL: double.tryParse(_amonioCtrl.text),
500:                         nitritosMgL: double.tryParse(_nitritosCtrl.text),
501:                         nitratosMgL: double.tryParse(_nitratosCtrl.text),
502:                         alcalinidadMgL: double.tryParse(_alcalinidadCtrl.text),
503:                         co2MgL: double.tryParse(_co2Ctrl.text),
504:                         durezaMgL: double.tryParse(_durezaCtrl.text),
505:                         cloroMgL: double.tryParse(_cloroCtrl.text),
```
In Spanish/Latin American numeric keypads, decimal separators are often commas (`,`). `double.tryParse("6,2")` evaluates to `null`.
- In lines 92–95, if the user types `2,5` mg/L O₂, `isHypoxia` evaluates to `false` (no warning banner shown).
- In lines 495–505, if the user typed `6,2`, `double.tryParse` sends `null` to Supabase, silently discarding the field operator measurement!
- Furthermore, lines 495–505 lack `.trim()`, so accidental spaces like `" 6.2 "` also evaluate to `null`.

### 1.5 Missing User Feedback on Null Pond Selection
In `lib/modules/water_quality/presentation/dialogs/parametro_modal.dart` (line 474):
```dart
474:                       if (!_formKey.currentState!.validate() || _selectedPondId == null) return;
```
If `_selectedPondId` is null, the button click returns silently without showing a SnackBar or inline error.

### 1.6 Systemic Simulated Fallbacks in Downstream Consumers
Grep analysis across the codebase uncovered multiple dummy fallback values used when `WaterParameter` fields are null:
- `lib/core/reports/ica_official_reports_engine.dart:367`: `final promO2 = count > 0 ? (sumO2 / count) : 6.2;`
- `lib/core/reports/ica_official_reports_engine.dart:388`: `final ox = w.oxigenoMgL ?? 6.0;`
- `lib/core/reports/ica_official_reports_engine.dart:1251`: `final ox = w.oxigenoMgL ?? 6.0;`
- `lib/modules/water_quality/presentation/screens/water_quality_records_screen.dart:163`: `final isHypoxia = (p.oxigenoMgL ?? 6.0) < 4.0;`
- `lib/modules/water_quality/presentation/screens/water_quality_records_screen.dart:171`: `text: '${(p.oxigenoMgL ?? 6.0).toStringAsFixed(1)} mg/L O₂',`
- `lib/modules/water_quality/presentation/screens/water_quality_records_screen.dart:181`: `Text('pH: ${(p.ph ?? 7.2).toStringAsFixed(1)}', style: AppTypography.bodySmall),`
- `lib/modules/water_quality/presentation/screens/water_quality_records_screen.dart:182`: `Text('Temp: ${(p.temperaturaC ?? 28.0).toStringAsFixed(1)}°C', style: AppTypography.bodySmall),`
- `lib/modules/bitacora/presentation/screens/bitacora_screen.dart:728`: `final isOptimal = (p.oxigenoMgL ?? 6.0) >= 4.5 && (p.ph ?? 7.0) >= 6.5 && (p.ph ?? 7.0) <= 8.0 && (p.amonioMgL ?? 0.0) <= 0.5;`
- `lib/modules/bitacora/presentation/screens/bitacora_screen.dart:781`: `Text('O₂: ${(p.oxigenoMgL ?? 6.0).toStringAsFixed(1)} mg/L ${p.oxigenoPct != null ? "(${p.oxigenoPct!.toInt()}%)" : ""}',`
- `lib/modules/bitacora/presentation/screens/bitacora_screen.dart:783`: `Text('Temp: ${(p.temperaturaC ?? 28.0).toStringAsFixed(1)}°C',`
- `lib/modules/bitacora/presentation/screens/bitacora_screen.dart:785`: `Text('pH: ${(p.ph ?? 7.2).toStringAsFixed(1)}',`

---

## 2. Logic Chain

1. **Premise**: ICA regulatory integrity (DATA-01) demands that no simulated or fictitious values are written to official records. Operators must explicitly enter observed field metrics.
2. **Controller State Verification (Observation 1.1)**:
   The 12 controllers in `ParametroModal` (`_oxigenoMgLCtrl`, `_oxigenoPctCtrl`, `_tempCtrl`, `_phCtrl`, `_amonioCtrl`, `_nitritosCtrl`, `_nitratosCtrl`, `_alcalinidadCtrl`, `_co2Ctrl`, `_durezaCtrl`, `_cloroCtrl`, `_obsCtrl`) are already declared without default text arguments. When opening the dialog, all text inputs render empty.
3. **Pond Auto-Selection Integrity Risk (Observation 1.2)**:
   Lines 88–90 automatically set `_selectedPondId = ponds.first.id` when `_selectedPondId` is null. Even though text fields are blank, the pond dropdown silently selects Pond #1. This violates the principle of explicit operator input: an operator measuring Pond #4 can accidentally commit data to Pond #1 if they fail to notice the dropdown.
4. **Tenant Isolation Breach Risk (Observation 1.3)**:
   Line 477 contains `?? 'c1000000-0000-0000-0000-000000000001'`. If auth state is lost, the app writes to a demo tenant rather than alerting the operator. This conflicts with SEC-01 multi-tenancy requirements.
5. **Decimal Comma & Data Loss Risk (Observation 1.4)**:
   Using raw `double.tryParse` without `.replaceAll(',', '.')` and `.trim()` causes any measurement typed with a decimal comma (e.g. `6,2` or `24,5`) to parse as `null`. When saving, the field operator believes they submitted `6,2` mg/L O₂, but Supabase receives `null`.
6. **Silent Failure on Save (Observation 1.5)**:
   If `_selectedPondId == null`, line 474 exits silently. Without visible feedback, the user does not know why tapping the save button had no effect.

---

## 3. Caveats

1. **Hints vs Defaults**: The form fields have hints such as `hint: 'Ej: 6.2'`, `hint: 'Ej: 24.5'`, `hint: 'Ej: 7.2'`. These are placeholders rendered only when the input is empty and are not submitted as form data. They serve as formatting examples and do not violate DATA-01 as long as the controller text remains empty.
2. **Preselected Pond Context**: When `ParametroModal` is opened from a specific pond card (e.g., in `bitacora_screen.dart:88`), `preselectedPondId` is explicitly provided. In this case, defaulting to that specific pond is expected UX. The auto-default in line 89 should only be disabled when `widget.preselectedPondId == null`.
3. **Downstream Fallbacks**: The fallback values identified in Observation 1.6 (`bitacora_screen.dart`, `water_quality_records_screen.dart`, `ica_official_reports_engine.dart`) are display/calculation fallbacks in other modules. While outside `parametro_modal.dart`, they should be noted for future hardening to prevent misleading the user when an optional parameter is genuinely null.

---

## 4. Conclusion & Recommended Action Plan

### Core Assessment
1. The `TextEditingController` instances in `parametro_modal.dart` are **properly initialized empty** (`text = ''`).
2. However, **4 critical data integrity and fallback defects** must be resolved in `parametro_modal.dart`:
   - **Fix 1**: Remove silent auto-selection of the first pond in `build()` (`lines 88–90`). Require explicit pond selection with a clear placeholder `hint`.
   - **Fix 2**: Remove the hardcoded dummy company UUID `'c1000000-0000-0000-0000-000000000001'` in line 477. Fail gracefully with an explicit error message if tenant ID is missing.
   - **Fix 3**: Implement a unified helper `_parseDecimal(String? text)` that trims whitespace and converts `,` to `.` before `double.tryParse`. Apply it to reactive alerts (lines 92–95) and payload creation (lines 495–505).
   - **Fix 4**: Provide explicit UI feedback (SnackBar) if `_selectedPondId == null` when the user taps "Guardar Medición".

### Proposed Code Changes for Implementer

#### 1. Helper Method for Decimal Comma & Space Normalization
Add inside `_ParametroModalState`:
```dart
double? _parseDecimal(String? text) {
  if (text == null) return null;
  final clean = text.trim().replaceAll(',', '.');
  return clean.isEmpty ? null : double.tryParse(clean);
}
```

#### 2. Fix Alert Logic (Lines 92–95)
```dart
// Before:
final oxigeno = double.tryParse(_oxigenoMgLCtrl.text.trim());
final amonio = double.tryParse(_amonioCtrl.text.trim());
final nitritos = double.tryParse(_nitritosCtrl.text.trim());
final cloro = double.tryParse(_cloroCtrl.text.trim());

// After:
final oxigeno = _parseDecimal(_oxigenoMgLCtrl.text);
final amonio = _parseDecimal(_amonioCtrl.text);
final nitritos = _parseDecimal(_nitritosCtrl.text);
final cloro = _parseDecimal(_cloroCtrl.text);
```

#### 3. Eliminate Auto-Select First Pond (Lines 88–90 & 160–174)
```dart
// Before (Lines 88-90):
if (_selectedPondId == null && ponds.isNotEmpty) {
  _selectedPondId = ponds.first.id;
}

// After:
// DO NOT auto-select ponds.first.id. Leave _selectedPondId null if widget.preselectedPondId is null.
```

In the DropdownButton (lines 161–174):
```dart
DropdownButton<String>(
  value: _selectedPondId,
  dropdownColor: AppColors.surfaceDark,
  isExpanded: true,
  hint: const Text(
    'Selecciona un estanque *',
    style: TextStyle(color: AppColors.textSecondaryDark, fontSize: 13, fontWeight: FontWeight.w500),
  ),
  icon: const Icon(Icons.keyboard_arrow_down_rounded, color: AppColors.cyanWater),
  items: ponds.map((p) {
    return DropdownMenuItem<String>(
      value: p.id,
      child: Text('${p.nombre} (${p.sigla})', style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600)),
    );
  }).toList(),
  onChanged: (val) => setState(() => _selectedPondId = val),
)
```

#### 4. Remove Hardcoded Tenant and Add Missing Selection Feedback (Lines 474–479)
```dart
// Before:
if (!_formKey.currentState!.validate() || _selectedPondId == null) return;

final authState = ref.read(authProvider);
final empresaId = authState.currentCompany?.id ?? authState.currentUser?.empresaId ?? 'c1000000-0000-0000-0000-000000000001';
final unidadId = authState.activeUnitId ?? authState.currentUser?.unidadAcuicolaId ?? empresaId;

// After:
if (_selectedPondId == null) {
  ScaffoldMessenger.of(context).showSnackBar(
    const SnackBar(
      content: Text('⚠️ Por favor selecciona un estanque para la medición.'),
      backgroundColor: AppColors.coralAction,
    ),
  );
  return;
}

if (!_formKey.currentState!.validate()) return;

final authState = ref.read(authProvider);
final empresaId = authState.currentCompany?.id ?? authState.currentUser?.empresaId;
if (empresaId == null || empresaId.isEmpty) {
  ScaffoldMessenger.of(context).showSnackBar(
    const SnackBar(
      content: Text('Error: No se encontró la empresa del usuario autenticado.'),
      backgroundColor: AppColors.coralAction,
    ),
  );
  return;
}
final unidadId = authState.activeUnitId ?? authState.currentUser?.unidadAcuicolaId ?? empresaId;
```

#### 5. Payload Construction with `_parseDecimal` (Lines 495–505)
```dart
// Before:
oxigenoMgL: double.tryParse(_oxigenoMgLCtrl.text),
oxigenoPct: double.tryParse(_oxigenoPctCtrl.text),
ph: double.tryParse(_phCtrl.text),
temperaturaC: double.tryParse(_tempCtrl.text),
amonioMgL: double.tryParse(_amonioCtrl.text),
nitritosMgL: double.tryParse(_nitritosCtrl.text),
nitratosMgL: double.tryParse(_nitratosCtrl.text),
alcalinidadMgL: double.tryParse(_alcalinidadCtrl.text),
co2MgL: double.tryParse(_co2Ctrl.text),
durezaMgL: double.tryParse(_durezaCtrl.text),
cloroMgL: double.tryParse(_cloroCtrl.text),

// After:
oxigenoMgL: _parseDecimal(_oxigenoMgLCtrl.text),
oxigenoPct: _parseDecimal(_oxigenoPctCtrl.text),
ph: _parseDecimal(_phCtrl.text),
temperaturaC: _parseDecimal(_tempCtrl.text),
amonioMgL: _parseDecimal(_amonioCtrl.text),
nitritosMgL: _parseDecimal(_nitritosCtrl.text),
nitratosMgL: _parseDecimal(_nitratosCtrl.text),
alcalinidadMgL: _parseDecimal(_alcalinidadCtrl.text),
co2MgL: _parseDecimal(_co2Ctrl.text),
durezaMgL: _parseDecimal(_durezaCtrl.text),
cloroMgL: _parseDecimal(_cloroCtrl.text),
```

---

## 5. Verification Method

To independently verify these observations and proposed resolutions:

1. **Controller Empty State Verification**:
   Inspect `lib/modules/water_quality/presentation/dialogs/parametro_modal.dart` lines 36–47 using `view_file`. Verify that none of the `TextEditingController` declarations include a `text` argument.
2. **Pond Auto-Selection Inspection**:
   Inspect lines 88–90 in `parametro_modal.dart`. Check for `if (_selectedPondId == null && ponds.isNotEmpty) _selectedPondId = ponds.first.id;`.
3. **Tenant Fallback Inspection**:
   Inspect line 477 in `parametro_modal.dart`. Check for the string literal `'c1000000-0000-0000-0000-000000000001'`.
4. **Decimal Parsing Verification**:
   Review lines 92–95 and lines 495–505. Observe that `double.tryParse` is called directly on uncleaned strings without `,` replacement.
5. **Form Invalidation Conditions**:
   - If `_selectedPondId` is null, attempting to submit should be blocked and trigger an explicit warning.
   - If values contain commas (e.g. `6,2`), verify that `_parseDecimal("6,2")` evaluates to `6.2` rather than `null`.
