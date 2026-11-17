# Handoff Report: Investigation of 8 Field Dialogs with Mock Defaults (§2.3)

**Author:** explorer_m1_3  
**Date:** 2026-10-27T18:15:30Z  
**Task:** Remediation Specifications for Field Dialogs with Hardcoded Mock Defaults (`FINAL_AUDIT_REPORT.md §2.3`)  
**Target Recipient:** Orchestrator / Worker M1 (`worker_m1_*`)  

---

## 1. Observation

A forensic line-by-line inspection was conducted across all 8 field dialogs identified in `FINAL_AUDIT_REPORT.md §2.3`:

### 1.1 `lib/modules/water_quality/presentation/dialogs/parametro_modal.dart`
* **Lines 36-48:** All 11 physicochemical controllers initialize completely empty:
  ```dart
  final _oxigenoMgLCtrl = TextEditingController();
  final _oxigenoPctCtrl = TextEditingController();
  final _tempCtrl = TextEditingController();
  final _phCtrl = TextEditingController();
  ...
  ```
* **Lines 288-343:** Strict form validators enforce required field entry and biological boundaries:
  - Oxygen: `0.0 <= val <= 30.0 mg/L`
  - Temperature: `5.0 <= val <= 45.0 °C`
  - pH: `0.0 <= val <= 14.0`
* **Lines 515-535:** `_formKey.currentState!.validate()` is invoked prior to submission, and `_selectedPondId` is strictly checked against existing active ponds.
* **Status:** Clean and compliant with DATA-01.

---

### 1.2 `lib/modules/ponds_batches/presentation/dialogs/siembra_modal.dart`
* **Lines 40-44:** Controllers hardcode fictitious values:
  ```dart
  final _pecesCtrl = TextEditingController(text: CurrencyFormatters.formatInt(5000));
  final _pesoCtrl = TextEditingController(text: '1.5');
  final _metaCosechaCtrl = TextEditingController(text: '650');
  final _costoAlevinosCtrl = TextEditingController(text: CurrencyFormatters.formatCOP(0));
  ```
* **Lines 203-204:** Mock demo UUID fallbacks divert tenant data:
  ```dart
  final empresaId = authState.currentUser?.empresaId ?? 'c1000000-0000-0000-0000-000000000001';
  final unidadId = authState.activeUnitId ?? 'u1000000-0000-0000-0000-000000000001';
  ```
* **Line 206:** Fictitious weight fallback:
  ```dart
  final pesoG = double.tryParse(_pesoCtrl.text.replaceAll(',', '.').trim()) ?? 1.5;
  ```
* **Line 747:** Broken COP formatting parse:
  ```dart
  '\$${(double.tryParse(_costoAlevinosCtrl.text) ?? 0.0).toStringAsFixed(0)} COP'
  ```
  Because `_costoAlevinosCtrl.text` is COP formatted (e.g., `"$ 0"` or `"$ 1.500.000"`), `double.tryParse` always returns `null` and displays `$0 COP`.

---

### 1.3 `lib/modules/ponds_batches/presentation/dialogs/mortalidad_modal.dart`
* **Line 34:** Hardcoded casualty count:
  ```dart
  final _muertosCtrl = TextEditingController(text: '5');
  ```
* **Lines 58-60 & 88:** Fictitious 250.0g fallback:
  ```dart
  _pesoCtrl = TextEditingController(
    text: (widget.batch?.pesoActualGramos ?? 250.0).toStringAsFixed(1),
  );
  ...
  final pesoG = double.tryParse(_pesoCtrl.text.replaceAll(',', '.').trim()) ?? (activeBatch?.pesoActualGramos ?? 250.0);
  ```
* **Lines 282-300:** `_muertosCtrl` and `_pesoCtrl` lack `validator:` callbacks entirely.
* **Line 108 & Line 408:** `_formKey` is declared and bound to `<Form key: _formKey>`, but `_formKey.currentState!.validate()` is never called in `onPressed`.
* **Impact:** Tapping confirm immediately reduces batch inventory by 5 fish with zero manual confirmation.

---

### 1.4 `lib/modules/ponds_batches/presentation/dialogs/biometria_modal.dart`
* **Lines 33 & 48-54:** Pre-calculated sample weighing:
  ```dart
  final _pecesCapturadosCtrl = TextEditingController(text: '35');
  late final TextEditingController _pesoTotalCapturaKgCtrl;
  ...
  final defaultPesoG = widget.batch?.pesoActualGramos ?? 250.0;
  const defaultPeces = 35;
  final defaultCapturaKg = (defaultPeces * defaultPesoG) / 1000.0;
  _pesoTotalCapturaKgCtrl = TextEditingController(
    text: defaultCapturaKg.toStringAsFixed(2),
  );
  ```
* **Lines 186-189 & 251-254:** Whenever pond or batch changes, simulated numbers are re-injected automatically:
  ```dart
  const pCount = 35;
  _pesoTotalCapturaKgCtrl.text = ((pCount * b.pesoActualGramos) / 1000.0).toStringAsFixed(2);
  ```
* **Lines 266-285:** Neither `_pecesCapturadosCtrl` nor `_pesoTotalCapturaKgCtrl` have a `validator:`.
* **Line 121 & Line 459:** `_formKey.currentState!.validate()` is never invoked.
* **Line 88:** `final pesoPromedioGramos = ... ?? (activeBatch?.pesoActualGramos ?? 250.0);` silently invents a 250g fish weight if fields are emptied.

---

### 1.5 `lib/modules/ponds_batches/presentation/dialogs/traslado_modal.dart`
* **Lines 50-52:** Mock fallbacks when batch is null:
  ```dart
  _pesoCtrl.text = (widget.batch?.pesoActualGramos ?? 100.0).toStringAsFixed(1);
  _pecesCtrl.text = (widget.batch?.cantidadActualPeces ?? 1000).toString();
  _nuevoCodigoCtrl.text = '${widget.batch?.codigoLote ?? "LOTE"}-B';
  ```
* **Lines 411-428:** `_pesoCtrl` has no `validator:` property.
* **Line 100:** Fictitious fallback:
  ```dart
  final pesoPromedioG = double.tryParse(_pesoCtrl.text.replaceAll(RegExp(r'[^\d.]'), '')) ?? (batchOrigen?.pesoActualGramos ?? 1.0);
  ```
* **Line 554:** Force unwrap `batchOrigen!.id` and `pondOrigen!.id` risks null-pointer exceptions if no active batch exists.

---

### 1.6 `lib/modules/sales_harvest/presentation/dialogs/venta_rapida_modal.dart`
* **Line 59:** Hardcoded unit sale price:
  ```dart
  final _precioKgCtrl = TextEditingController(text: '\$ 9.500');
  ```
* **Lines 169-175:** Aggressive state overwriting in `build()`:
  ```dart
  if (_pesoVivoKgCtrl.text.isEmpty && stockDisponibleKg > 0) {
    _pesoVivoKgCtrl.text = stockDisponibleKg.toStringAsFixed(1);
    _recalculateFromPesoVivo();
  }
  if (_cantidadPecesCtrl.text.isEmpty && stockPecesDisponible > 0) {
    _cantidadPecesCtrl.text = stockPecesDisponible.toString();
  }
  ```
  Whenever an operator clears a field to type a partial harvest, `build()` overwrites their input with 100% of the lot.
* **Line 192:** Hardcoded Cost of Production fallback:
  ```dart
  final cpk = selectedBatch?.cpk ?? 4500.0;
  ```
* **Line 792:** Mock tenant UUID fallback:
  ```dart
  final unitId = authState.activeUnitId ?? user?.unidadAcuicolaId ?? user?.empresaId ?? 'u1000000-0000-0000-0000-000000000001';
  ```
* **Lines 540-567 & 654-664:** `_cantidadPecesCtrl`, `_pesoVivoKgCtrl`, and `_precioKgCtrl` have `isRequired: true`, but **lack any `validator:` callback**.

---

### 1.7 `lib/modules/auth_tenant/presentation/dialogs/crear_colaborador_modal.dart`
* **Lines 56-59:** Hardcoded salary and plaintext default password:
  ```dart
  _salarioCtrl = TextEditingController(
    text: m != null && m.salarioBase > 0 ? m.salarioBase.toInt().toString() : '2000000',
  );
  _passCtrl = TextEditingController(text: 'FishBit.2026');
  ```
* **Lines 403-418:** Password input is validated even when editing an existing member (`widget.memberToEdit != null`), although the password is not updated during edit mode.

---

### 1.8 `lib/modules/ica_compliance/presentation/dialogs/ica_biosecurity_modals.dart`
* **Lines 765-779 (`NecropsiaModal`):** Complete veterinary clinical texts pre-filled:
  ```dart
  final _ejemplaresCtrl = TextEditingController(text: '3');
  final _pesoPromCtrl = TextEditingController(text: '250.0');
  final _tallaPromCtrl = TextEditingController(text: '22.0');
  final _pielAletasCtrl = TextEditingController(text: 'Piel con coloración homogénea, aletas íntegras sin erosión.');
  final _ojosCtrl = TextEditingController(text: 'Ojos claros, sin exoftalmia ni opacidad.');
  final _branquiasCtrl = TextEditingController(text: 'Branquias de color rojo cereza, filamentos intactos.');
  final _higadoCtrl = TextEditingController(text: 'Hígado rojizo de consistencia normal, bordes lisos.');
  final _bazoCtrl = TextEditingController(text: 'Bazo sin esplenomegalia, color rojo oscuro normal.');
  final _tractoCtrl = TextEditingController(text: 'Contenido alimenticio normal en estómago, sin enteritis.');
  final _cavidadCtrl = TextEditingController(text: 'Sin presencia de líquido libre celómico (sin ascitis).');
  final _rinonCtrl = TextEditingController(text: 'Riñón posterior de aspecto y tamaño conservado.');
  final _diagnosticoCtrl = TextEditingController(text: 'Muestreo de rutina / Monitoreo preventivo.');
  final _conductaCtrl = TextEditingController(text: 'Mantener tasa de aireación y recambio normal.');
  ```
* **Lines 73, 458, 830:** Mock fallback UUID across all 3 ICA modals:
  ```dart
  final empresaId = auth.currentCompany?.id ?? auth.currentUser?.empresaId ?? 'c1000000-0000-0000-0000-000000000001';
  ```
* **Lines 42-43 & 426-427:** Hardcoded time strings `'08:00'`, `'17:00'`, `'09:00'`, `'10:30'` instead of dynamic `TimeOfDay.now()`.
* **Lines 989-1048:** Organ assessment fields lack `validator:`.

---

## 2. Logic Chain

1. **Regulatory Non-Compliance Risk:**
   - Under ICA Resolution 20186 and AUNAP biosecurity guidelines, aquaculture registries must represent verified physical measurements.
   - Pre-populating numbers (5.000 fish, 5 dead fish, 35 sample fish, 250g, $9.500 COP, healthy necropsy organs) allows operators to accidentally submit fabricated data with a single button press.
2. **Biological & Financial Corruption:**
   - Pre-loaded mortality reduces inventory and inflates apparent feed conversion ratio (FCR).
   - Pre-loaded biometry distorts pond biomass, carrying capacity ($kg/m^3$), and feeding tables.
   - Hardcoded CPK ($4.500) obscures real production costs and miscalculates gross margin.
3. **Multi-Tenant Leakage Risk:**
   - Fallback UUID `'c1000000-0000-0000-0000-000000000001'` redirects genuine operational data to the demo tenant whenever a user's session token refreshes with a null tenant claim.
4. **Form Validation Bypass:**
   - In `mortalidad_modal.dart`, `biometria_modal.dart`, and `venta_rapida_modal.dart`, form keys were defined but never checked (`_formKey.currentState!.validate()`). The form can submit completely blank or corrupted numbers without triggering inline error messages.

---

## 3. Caveats

* **Guidance vs. Pre-population:** Field workers rely on knowing the format or standard expected ranges. Rather than leaving inputs completely blank with no context, the solution must migrate existing default text into `hintText` / `hint` parameters.
* **One-Click Convenience:** In `venta_rapida_modal.dart`, harvesting 100% of a lot is a frequent action. Instead of forcing manual typing of exact decimals, the existing "Cosechar Todo (100%)" button will be retained as an intentional user action, while initial controller values start empty.
* **Editing Mode in Colaborador:** When updating an existing team member (`memberToEdit != null`), the password is not changed and must not be required.

---

## 4. Conclusion & Concrete Recommendations for Worker

The worker should apply the following precise remediations:

### Summary Matrix of Remediation Actions

| Modal File | Parameter / Variable | Problem | Drop-in Remediation |
|---|---|---|---|
| `siembra_modal.dart` | `_pecesCtrl`, `_pesoCtrl`, `_metaCosechaCtrl`, `_costoAlevinosCtrl` | 5000, 1.5g, 650g defaults | Initialize controllers empty: `TextEditingController()`. Provide hints (`hint: 'Ej: 5.000'`). |
| `siembra_modal.dart` | `empresaId`, `unidadId` (L203-204) | Mock UUIDs `'c1000...001'` | Require non-null tenant from `authProvider`. Show SnackBar error and return if null. |
| `siembra_modal.dart` | UI Cost display (L747) | `double.tryParse` on COP string | Replace with `CurrencyFormatters.parseCOP(_costoAlevinosCtrl.text)`. |
| `mortalidad_modal.dart` | `_muertosCtrl`, `_pesoCtrl` | Hardcoded `'5'`, fallback 250.0g | Initialize `_muertosCtrl = TextEditingController()`. Initialize `_pesoCtrl` from `widget.batch?.pesoActualGramos` only if > 0, else empty. |
| `mortalidad_modal.dart` | Form Validation | `validate()` never called; no field validators | Add `validator:` to both fields. Call `if (!_formKey.currentState!.validate()) return;` in `onPressed`. |
| `biometria_modal.dart` | `_pecesCapturadosCtrl`, `_pesoTotalCapturaKgCtrl` | Hardcoded `'35'`, auto-calculated 8.75kg | Initialize both empty. Remove auto-injection on pond/batch change. Display `'--'` when empty. |
| `biometria_modal.dart` | Form Validation | `validate()` never called; no field validators | Add `validator:` to both fields. Call `if (!_formKey.currentState!.validate()) return;` in `onPressed`. |
| `traslado_modal.dart` | `_pesoCtrl`, `_pecesCtrl` | Fallback 100.0g, 1000 fish | Leave empty if `widget.batch == null`. Add `validator:` to `_pesoCtrl`. Check for null `batchOrigen`/`pondOrigen`. |
| `venta_rapida_modal.dart` | `_pesoVivoKgCtrl`, `_cantidadPecesCtrl` | Auto-populated in `build()` | Remove lines 169-175. Initialize empty. User clicks "Cosechar Todo (100%)" if harvesting all. |
| `venta_rapida_modal.dart` | `_precioKgCtrl` | Hardcoded `'$ 9.500'` | Initialize empty: `TextEditingController()`. Hint: `'Ej: \$ 9.500'`. Add validator (`p > 0`). |
| `venta_rapida_modal.dart` | `cpk` (L192) | Hardcoded `4500.0` fallback | Calculate real CPK: `selectedBatch.costoTotal / selectedBatch.biomasaActualKg`. Default to `0.0`. |
| `venta_rapida_modal.dart` | Missing validators | Key numeric fields have no `validator:` | Add `validator:` to `_cantidadPecesCtrl` and `_pesoVivoKgCtrl`. |
| `crear_colaborador_modal.dart` | `_salarioCtrl`, `_passCtrl` | `'2000000'`, `'FishBit.2026'` | Initialize empty. Show password field only when `memberToEdit == null`. Enforce min 8 chars. |
| `ica_biosecurity_modals.dart` | Necropsia organ controllers | Pre-filled clinical diagnoses | Initialize all 11 organ controllers empty. Move clinical descriptions to `hint:`. Add validators. |
| `ica_biosecurity_modals.dart` | `empresaId` (L73, 458, 830) | Mock UUIDs `'c1000...001'` | Require active company tenant. Block operation if null. |
| `ica_biosecurity_modals.dart` | `_horaIngresoCtrl`, `_horaSalidaCtrl` | Hardcoded `'08:00'`, etc. | Use `TimeOfDay.now()` formatted dynamically. |

---

## 5. Verification Method

### 5.1 Static Analysis
Verify that all 8 files compile with 0 errors and 0 warnings:
```pwsh
flutter analyze --no-fatal-infos lib/modules/water_quality/presentation/dialogs/parametro_modal.dart lib/modules/ponds_batches/presentation/dialogs/siembra_modal.dart lib/modules/ponds_batches/presentation/dialogs/mortalidad_modal.dart lib/modules/ponds_batches/presentation/dialogs/biometria_modal.dart lib/modules/ponds_batches/presentation/dialogs/traslado_modal.dart lib/modules/sales_harvest/presentation/dialogs/venta_rapida_modal.dart lib/modules/auth_tenant/presentation/dialogs/crear_colaborador_modal.dart lib/modules/ica_compliance/presentation/dialogs/ica_biosecurity_modals.dart
```

### 5.2 Unit & Widget Test Validation
Run existing test suite to ensure no regressions:
```pwsh
flutter test test/modules/ponds_batches/
flutter test test/modules/water_quality/
flutter test test/modules/sales_harvest/
```

### 5.3 Manual Inspection Checklist for Worker
1. Open `siembra_modal.dart`: Verify that upon opening, fish count and weight are empty. Tapping "Confirmar Siembra" triggers inline validation errors ("Ingresa cantidad", "Ingresa peso").
2. Open `mortalidad_modal.dart`: Verify that dead fish count is empty. Tapping "Confirmar" is blocked by validator.
3. Open `biometria_modal.dart`: Verify captured fish count and total weight are empty. Cards display `-- g` and `-- kg`. Tapping submit triggers validation.
4. Open `traslado_modal.dart`: Verify `_pesoCtrl` enforces positive decimal input.
5. Open `venta_rapida_modal.dart`: Verify price per kg and biomass are empty. Clearing a field does not reset it on widget rebuild.
6. Open `crear_colaborador_modal.dart`: Verify salary and password are empty. Password field is hidden/optional when editing an existing member.
7. Open `ica_biosecurity_modals.dart` (`NecropsiaModal`): Verify organ fields start empty with placeholder guidance hints.
8. Verify zero occurrences of `'c1000000-0000-0000-0000-000000000001'` remain in these 8 dialogs.
