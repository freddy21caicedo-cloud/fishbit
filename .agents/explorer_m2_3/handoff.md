# Handoff Report: Explorer M2_3 (Water Quality & Bitacora Test Suites Analysis)

## 1. Observation

### 1.1 Existing Test Suite Inventory
- Executed `flutter test` across the repository (output logged in task-31, task-40, task-45):
  - Total tests: 123 tests executed. 118 passed, 5 failed.
  - Failures are localized to:
    - `test/modules/bitacora/bitacora_screen_test.dart` (2 failures).
    - `test/modules/warehouse_inventory/warehouse_inventory_test.dart` (3 failures, domain/notifier CPP recalculation, unrelated to water quality).
  - All tests in `test/modules/water_quality/water_parameter_test.dart` passed 100% (3/3 unit tests).
  - `test/modules/stress_tests/models_stress_test.dart` passed 100% (including `WaterParameter.toJson() & fromJson()` tests).
  - Searched repository via ripgrep (`grep_search`) for `ParametroModal` in `test/`: **0 occurrences found**.
  - **Critical Finding**: There are currently **zero widget tests** for `ParametroModal` in the entire repository.

---

### 1.2 Root Cause Analysis of `bitacora_screen_test.dart` Failures

#### Failure 1: Outdated KPI Text Finders (Line 518)
- **Test description**: `BitacoraScreen UI & State Integration Tests Renders all 4 tabs and initial state correctly on mobile 360px viewport`
- **Verbatim Error**:
  ```text
  Expected: exactly one matching candidate
    Actual: _TextWidgetFinder:<Found 0 widgets with text "OXÍGENO ÓPTIMO": []>
     Which: means none were found but one was expected
  When the exception was thrown, this was the stack:
  #4 main.<anonymous closure>.<anonymous closure> (file:///test/modules/bitacora/bitacora_screen_test.dart:518:7)
  ```
- **Code in `test/modules/bitacora/bitacora_screen_test.dart` (lines 517-520)**:
  ```dart
  // Tab 1 (Calidad de Agua) default view
  expect(find.text('OXÍGENO ÓPTIMO'), findsOneWidget);
  expect(find.text('PH RANGO'), findsOneWidget);
  expect(find.textContaining('O₂: 6.2 mg/L'), findsOneWidget);
  ```
- **Code in `lib/modules/bitacora/presentation/screens/bitacora_screen.dart` (lines 627-656)**:
  ```dart
  GlassCard(
    title: 'Oxígeno Disuelto',
    glowColor: AppColors.cyanWater,
    child: Column(
      children: [
        Text(oxigenoDisplay, ...), // Displays '6.2 mg/L'
        Text(oxigenoSub, ...),     // Displays 'Último registro (07:00)'
      ],
    ),
  ),
  GlassCard(
    title: 'pH de Agua',
    glowColor: AppColors.greenBiomass,
    child: Column(
      children: [
        Text(phDisplay, ...),      // Displays '7.3'
        Text(phSub, ...),          // Displays 'pH en equilibrio'
      ],
    ),
  ),
  ```
- **Observation**: `BitacoraScreen` was refactored with modern cards titled `'Oxígeno Disuelto'` and `'pH de Agua'`. The test asserts against deprecated strings `'OXÍGENO ÓPTIMO'` and `'PH RANGO'`. This failure is completely unrelated to zero-defaults or form validations.

#### Failure 2: Overbroad Text Matcher & Inconsistent Empty State String (Lines 596, 600)
- **Test description**: `BitacoraScreen UI & State Integration Tests Reactive Pond Filter filters all 4 tabs simultaneously and clears with Limpiar button`
- **Verbatim Error**:
  ```text
  Expected: exactly one matching candidate
    Actual: _TextContainingWidgetFinder:<Found 3 widgets with text containing Estanque 02: [
              Text("E-02 • Estanque 02", ...),
              Text("Sin mediciones en Estanque 02", ...),
              Text("Aún no se han registrado parámetros de oxígeno, pH o temperatura para Estanque 02.", ...)
            ]>
     Which: is too many
  When the exception was thrown, this was the stack:
  #4 main.<anonymous closure>.<anonymous closure> (file:///test/modules/bitacora/bitacora_screen_test.dart:596:7)
  ```
- **Code in `test/modules/bitacora/bitacora_screen_test.dart` (lines 596-600)**:
  ```dart
  expect(find.textContaining('Estanque 02'), findsOneWidget);
  expect(find.text('Limpiar'), findsOneWidget);

  // Tab 1 (Calidad de Agua): should show empty state because Pond 2 has no water parameter records
  expect(find.text('No hay mediciones registradas para este estanque.'), findsOneWidget);
  ```
- **Code in `lib/modules/bitacora/presentation/screens/bitacora_screen.dart` (lines 690-700)**:
  ```dart
  Text('Sin mediciones en $nombreEstanque', ...), // "Sin mediciones en Estanque 02"
  Text('Aún no se han registrado parámetros de oxígeno, pH o temperatura para $nombreEstanque.', ...),
  ```
- **Observation**: When filtering by Estanque 02, the text `'Estanque 02'` appears 3 times (filter chip + empty state title + empty state description). `find.textContaining('Estanque 02')` finds 3 widgets instead of 1. Furthermore, line 600 expects the string `'No hay mediciones registradas para este estanque.'`, whereas the actual widget renders `'Sin mediciones en Estanque 02'`.

---

### 1.3 Inspection of `lib/modules/water_quality/presentation/dialogs/parametro_modal.dart`

1. **Initial Controller Values (Lines 36-47)**:
   ```dart
   final _oxigenoMgLCtrl = TextEditingController();
   final _oxigenoPctCtrl = TextEditingController();
   final _tempCtrl = TextEditingController();
   final _phCtrl = TextEditingController();
   final _amonioCtrl = TextEditingController();
   final _nitritosCtrl = TextEditingController();
   final _nitratosCtrl = TextEditingController();
   final _alcalinidadCtrl = TextEditingController();
   final _co2Ctrl = TextEditingController();
   final _durezaCtrl = TextEditingController();
   final _cloroCtrl = TextEditingController();
   final _obsCtrl = TextEditingController();
   ```
   - Controllers are currently instantiated with no initial text (`text = ''`).
   - Hints provide guidance: `hint: 'Ej: 6.2'`, `hint: 'Ej: 24.5'`, `hint: 'Ej: 7.2'`.

2. **Decimal Comma Deficiency in Parsing (Lines 92-95, 271, 303, 320, 495-505)**:
   - In Dart, `double.tryParse("6,2")` evaluates to `null`.
   - In `parametro_modal.dart`:
     - Line 271: `final parsed = double.tryParse(val.trim());` -> If user types `6,2`, returns `'Inválido'`.
     - Line 303: `final parsed = double.tryParse(val.trim());` -> If user types `28,5`, returns `'0-50°C'`.
     - Line 320: `final parsed = double.tryParse(val.trim());` -> If user types `7,3`, returns `'0-14'`.
     - Lines 495-505: When saving, `double.tryParse(_oxigenoMgLCtrl.text)` -> Evaluates to `null`, silently corrupting or losing recorded parameter measurements.
     - Lines 92-95: Real-time hazard banners (`isHypoxia`, `isAmmoniaCritical`, `isNitriteCritical`, `isChlorineAlert`) fail to activate when commas are entered.

3. **Incomplete Biological Parameter Bounds (Lines 272, 304, 321)**:
   - Oxígeno (line 272): `if (parsed == null || parsed < 0) return 'Inválido';` -> Lacks upper bound limit (`0 to 30 mg/L`). Allows impossible values like `500 mg/L`.
   - Temperatura (line 304): `if (parsed == null || parsed <= 0 || parsed > 50) return '0-50°C';` -> Specification contract requires `5 to 45 °C`.
   - Estanque (line 474): `if (!_formKey.currentState!.validate() || _selectedPondId == null) return;` -> If no pond is selected, returns silently with no feedback to the user.

---

### 1.4 Deceptive Fallback Operators in `bitacora_screen.dart`
- **File**: `lib/modules/bitacora/presentation/screens/bitacora_screen.dart` (lines 781-798):
  ```dart
  Text('O₂: ${(p.oxigenoMgL ?? 6.0).toStringAsFixed(1)} mg/L ...'),
  Text('Temp: ${(p.temperaturaC ?? 28.0).toStringAsFixed(1)}°C'),
  Text('pH: ${(p.ph ?? 7.2).toStringAsFixed(1)}'),
  Text('Amonio: ${(p.amonioMgL ?? 0.15).toStringAsFixed(2)} ppm'),
  ```
- **Observation**: If a parameter record contains `null` (e.g. routine field check where only oxygen was measured, or legacy data), `BitacoraScreen` displays fabricated dummy values (`6.0 mg/L`, `28.0°C`, `7.2`, `0.15 ppm`). This directly violates ICA regulatory transparency.

---

## 2. Logic Chain

1. **Premise 1**: M2 requires zero-defaults on controllers and mandatory validation for routine parameters (Oxígeno, Temperatura, pH) and pond selection (from `ORIGINAL_REQUEST.md §R2` and `PROJECT.md §DATA-01`).
2. **Premise 2**: Since `ParametroModal` currently has 0 widget tests in the repository, introducing empty initial controllers or mandatory validation has had **zero breaking impact** on existing test runs.
3. **Premise 3**: The test failures in `test/modules/bitacora/bitacora_screen_test.dart` are 100% caused by out-of-sync UI test assertions (`'OXÍGENO ÓPTIMO'` vs `'Oxígeno Disuelto'`, and non-unique substring finders on `'Estanque 02'`), rather than zero-defaults in `ParametroModal`.
4. **Premise 4**: Because aquaculture technicians in Colombia / Latin America use Spanish keyboard configurations where comma (`,`) is the standard decimal delimiter, `double.tryParse` without `replaceAll(',', '.')` creates critical data entry failure.
5. **Premise 5**: To ensure long-term regression safety, a dedicated widget test suite `test/modules/water_quality/parametro_modal_test.dart` must be designed and implemented to verify:
   - All 11 parameter controllers initialize empty.
   - Mandatory validation triggers on blank submissions and invalid biological ranges.
   - Decimal comma parsing works for validation, dynamic alert badges, and database payloads.
   - Complete save lifecycle succeeds with proper Riverpod state updates and SnackBar presentation.

---

## 3. Caveats

- **Scope boundary**: This investigation is strictly read-only. No application code or test files were modified during this turn.
- **Warehouse test failures**: The 3 failing tests in `test/modules/warehouse_inventory/warehouse_inventory_test.dart` were observed during the full test run but are scoped to Milestone M5 (QUAL-01) and are unrelated to water quality or bitacora.
- **Fallback operators in `bitacora_screen.dart`**: While this finding was uncovered during investigation of `bitacora_screen.dart`, modifying `bitacora_screen.dart` should be coordinated with Milestone M2 / M5 tasks.

---

## 4. Conclusion & Actionable Proposals

### 4.1 Required Fixes for `bitacora_screen_test.dart`
Update `test/modules/bitacora/bitacora_screen_test.dart`:
```dart
// Test 1 (lines 518-520):
expect(find.text('Oxígeno Disuelto'), findsOneWidget);
expect(find.text('pH de Agua'), findsOneWidget);
expect(find.textContaining('6.2 mg/L'), findsOneWidget);
expect(find.textContaining('7.3'), findsOneWidget);

// Test 4 (lines 596-600):
expect(find.text('E-02 • Estanque 02'), findsOneWidget);
expect(find.text('Limpiar'), findsOneWidget);
expect(find.textContaining('Sin mediciones en Estanque 02'), findsOneWidget);
```

### 4.2 Required Fixes for `lib/modules/water_quality/presentation/dialogs/parametro_modal.dart`
1. Add robust decimal parser helper:
   ```dart
   double? _parseDecimal(String? text) {
     if (text == null) return null;
     final cleaned = text.trim().replaceAll(',', '.');
     if (cleaned.isEmpty) return null;
     return double.tryParse(cleaned);
   }
   ```
2. Update validators with standard ICA biological ranges:
   - Oxígeno: `parsed < 0 || parsed > 30` -> `'0-30 mg/L'`
   - Temperatura: `parsed < 5 || parsed > 45` -> `'5-45°C'`
   - pH: `parsed < 0 || parsed > 14` -> `'0-14'`
3. Alert banners: Use `_parseDecimal` for `_oxigenoMgLCtrl`, `_amonioCtrl`, `_nitritosCtrl`, `_cloroCtrl`.
4. Submission payload: Use `_parseDecimal` for all 11 parameter fields.
5. Pond validation: Show explicit error feedback (`'Seleccione un estanque antes de guardar'`) if `_selectedPondId == null`.

---

### 4.3 Proposed Test Specification & Implementation: `test/modules/water_quality/parametro_modal_test.dart`

Here is the complete, drop-in test suite designed for `ParametroModal`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fishbit_finance/modules/water_quality/presentation/dialogs/parametro_modal.dart';
import 'package:fishbit_finance/modules/water_quality/domain/models/water_parameter.dart';
import 'package:fishbit_finance/modules/water_quality/domain/repositories/water_quality_repository.dart';
import 'package:fishbit_finance/modules/water_quality/presentation/providers/water_quality_provider.dart';
import 'package:fishbit_finance/modules/ponds_batches/domain/models/pond.dart';
import 'package:fishbit_finance/modules/ponds_batches/domain/models/fish_batch.dart';
import 'package:fishbit_finance/modules/ponds_batches/domain/models/biometria_record.dart';
import 'package:fishbit_finance/modules/ponds_batches/domain/models/mortality_record.dart';
import 'package:fishbit_finance/modules/ponds_batches/domain/models/transfer_record.dart';
import 'package:fishbit_finance/modules/ponds_batches/domain/repositories/ponds_repository.dart';
import 'package:fishbit_finance/modules/ponds_batches/presentation/providers/ponds_provider.dart';
import 'package:fishbit_finance/modules/auth_tenant/domain/models/user_member.dart';
import 'package:fishbit_finance/modules/auth_tenant/domain/models/company.dart';
import 'package:fishbit_finance/modules/auth_tenant/domain/models/aquaculture_unit.dart';
import 'package:fishbit_finance/modules/auth_tenant/presentation/providers/auth_provider.dart';

class FakeWaterQualityRepo implements WaterQualityRepository {
  List<WaterParameter> recorded = [];

  @override
  Future<List<WaterParameter>> fetchParametersByEstanque(String empresaId, String estanqueId) async => recorded;

  @override
  Future<List<WaterParameter>> fetchRecentParametersByUnit(String empresaId, String unidadAcuicolaId) async => recorded;

  @override
  Future<WaterParameter> recordParameters(WaterParameter parameter) async {
    recorded.add(parameter);
    return parameter;
  }
}

class FakePondsRepo implements PondsRepository {
  List<Pond> mockPonds = [];
  @override
  Future<List<Pond>> fetchPondsByUnit(String empresaId, String unidadAcuicolaId) async => mockPonds;
  @override
  Future<Pond> createPond(Pond pond) async => pond;
  @override
  Future<void> updatePond(Pond pond) async {}
  @override
  Future<void> deletePond(String pondId) async {}
  @override
  Future<List<FishBatch>> fetchBatchesByUnit(String empresaId, String unidadAcuicolaId) async => [];
  @override
  Future<FishBatch> createBatch(FishBatch batch) async => batch;
  @override
  Future<void> updateBatch(FishBatch batch) async {}
  @override
  Future<void> transferOrSplitBatch({required String batchOrigenId, required String estanqueOrigenId, required String estanqueDestinoId, required int pecesTrasladados, required double biomasaTrasladadaKg, required bool esDesdoble, required String nuevoCodigoLote, String? registradoPor}) async {}
  @override
  Future<List<TransferRecord>> fetchTransfersByUnit(String empresaId, String unidadAcuicolaId, {String? pondId, String? batchId}) async => [];
  @override
  Future<List<BiometriaRecord>> fetchBiometriesByUnit(String empresaId, String unidadAcuicolaId, {String? pondId, String? batchId}) async => [];
  @override
  Future<List<MortalityRecord>> fetchMortalityByUnit(String empresaId, String unidadAcuicolaId, {String? pondId, String? batchId}) async => [];
  @override
  Future<BiometriaRecord> registerBiometry({String? empresaId, String? unidadAcuicolaId, required String estanqueId, required String loteId, required double nuevoPesoPromedioGramos, int? cantidadPecesMuestreados, double? pesoTotalCapturaKg, double? longitudPromedioCm, double? factorK, double? gdpGDia, String? observaciones, String? registradoPor, DateTime? fecha, String? hora}) async {
    throw UnimplementedError();
  }
  @override
  Future<MortalityRecord> registerMortality({String? empresaId, String? unidadAcuicolaId, required String estanqueId, required String loteId, required int cantidadPecesMuertos, required double pesoPromedioGramos, required String causaProbable, double? biomasaPerdidaKg, String? observaciones, String? registradoPor, DateTime? fecha, String? hora}) async {
    throw UnimplementedError();
  }
}

class FakeAuthNotifier extends StateNotifier<AuthState> implements AuthNotifier {
  FakeAuthNotifier(super.initial);
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  late FakeWaterQualityRepo fakeWaterRepo;
  late FakePondsRepo fakePondsRepo;
  late AuthState testAuthState;

  final testPond1 = Pond(
    id: 'pond-001',
    empresaId: 'emp-001',
    unidadAcuicolaId: 'unit-001',
    nombre: 'Estanque 01 Principal',
    sigla: 'E-01',
    capacidadM3: 120.0,
    creadoEn: DateTime(2026, 1, 1),
  );

  setUp(() {
    fakeWaterRepo = FakeWaterQualityRepo();
    fakePondsRepo = FakePondsRepo()..mockPonds = [testPond1];

    testAuthState = AuthState(
      currentUser: UserMember(
        id: 'usr-001',
        empresaId: 'emp-001',
        unidadAcuicolaId: 'unit-001',
        nombre: 'Biólogo Evaluador',
        email: 'biologo@fishbit.test',
        role: UserRole.admin,
        estado: MemberStatus.active,
        creadoEn: DateTime(2026, 1, 1),
      ),
      currentCompany: const Company(
        id: 'emp-001',
        nombreComercial: 'Acuícola del Huila',
        razonSocial: 'Acuícola del Huila SAS',
        nit: '900.111.222-3',
      ),
      units: [
        AquacultureUnit(
          id: 'unit-001',
          empresaId: 'emp-001',
          nombre: 'Sede Principal',
          sigla: 'PRIN',
          ubicacion: 'Gigante, Huila',
          creadoEn: DateTime(2026, 1, 1),
        ),
      ],
      activeUnitId: 'unit-001',
    );
  });

  Widget buildModalTestWidget({String? preselectedPondId}) {
    return ProviderScope(
      overrides: [
        authProvider.overrideWith((ref) => FakeAuthNotifier(testAuthState)),
        waterQualityRepositoryProvider.overrideWithValue(fakeWaterRepo),
        pondsRepositoryProvider.overrideWithValue(fakePondsRepo),
      ],
      child: MaterialApp(
        theme: ThemeData.dark(),
        home: Scaffold(
          body: Builder(
            builder: (context) => Center(
              child: ElevatedButton(
                onPressed: () => ParametroModal.show(context, preselectedPondId: preselectedPondId),
                child: const Text('Abrir Modal'),
              ),
            ),
          ),
        ),
      ),
    );
  }

  group('ParametroModal ICA Regulatory Compliance & Data Integrity Tests', () {
    testWidgets('1. Initial State: All 11 numerical controllers initialize completely blank', (tester) async {
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(buildModalTestWidget());
      await tester.tap(find.text('Abrir Modal'));
      await tester.pumpAndSettle();

      // Find all TextFormFields
      final textFields = tester.widgetList<TextFormField>(find.byType(TextFormField)).toList();

      // All 12 text fields (11 numeric + 1 observations) must be completely empty
      for (final field in textFields) {
        expect(field.controller?.text ?? '', isEmpty);
      }

      // Verify no simulated values exist in inputs
      expect(find.text('6.2'), findsNothing);
      expect(find.text('7.4'), findsNothing);
      expect(find.text('28.5'), findsNothing);
    });

    testWidgets('2. Mandatory Field Validation: Rejects save when required fields are blank', (tester) async {
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(buildModalTestWidget());
      await tester.tap(find.text('Abrir Modal'));
      await tester.pumpAndSettle();

      // Tap Save without entering any data
      await tester.tap(find.text('Guardar Medición de Calidad de Agua'));
      await tester.pumpAndSettle();

      // Must find validation error messages
      expect(find.text('Requerido'), findsAtLeastNWidgets(3)); // O2, Temp, pH
      expect(fakeWaterRepo.recorded, isEmpty);
      expect(find.byType(ParametroModal), findsOneWidget); // Dialog stays open
    });

    testWidgets('3. Biological Range Validation: Rejects out-of-range O2, Temp, and pH', (tester) async {
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(buildModalTestWidget());
      await tester.tap(find.text('Abrir Modal'));
      await tester.pumpAndSettle();

      final textFields = find.byType(TextFormField);

      // Enter invalid O2 (> 30)
      await tester.enterText(textFields.at(0), '45.0');
      // Enter invalid Temp (< 5)
      await tester.enterText(textFields.at(2), '2.0');
      // Enter invalid pH (> 14)
      await tester.enterText(textFields.at(3), '15.5');

      await tester.tap(find.text('Guardar Medición de Calidad de Agua'));
      await tester.pumpAndSettle();

      expect(fakeWaterRepo.recorded, isEmpty);
      expect(find.text('0-30 mg/L'), findsOneWidget);
      expect(find.text('5-45°C'), findsOneWidget);
      expect(find.text('0-14'), findsOneWidget);
    });

    testWidgets('4. Spanish Decimal Comma: Correctly parses values formatted with comma and saves', (tester) async {
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(buildModalTestWidget());
      await tester.tap(find.text('Abrir Modal'));
      await tester.pumpAndSettle();

      final textFields = find.byType(TextFormField);

      // Enter parameters using comma as decimal separator
      await tester.enterText(textFields.at(0), '6,5');  // O2 mg/L
      await tester.enterText(textFields.at(1), '92,5'); // O2 %
      await tester.enterText(textFields.at(2), '28,4'); // Temp °C
      await tester.enterText(textFields.at(3), '7,35'); // pH
      await tester.enterText(textFields.at(4), '0,18'); // Amonio
      await tester.enterText(textFields.at(5), '0,04'); // Nitritos
      await tester.enterText(textFields.at(6), '4,5');  // Nitratos
      await tester.enterText(textFields.at(7), '120,5'); // Alcalinidad
      await tester.enterText(textFields.at(8), '5,0');  // CO2
      await tester.enterText(textFields.at(9), '140,0'); // Dureza
      await tester.enterText(textFields.at(10), '0,01'); // Cloro
      await tester.enterText(textFields.at(11), 'Medición post-alimentación');

      // Tap Save
      await tester.tap(find.text('Guardar Medición de Calidad de Agua'));
      await tester.pumpAndSettle();

      // Must succeed and save to repository
      expect(fakeWaterRepo.recorded.length, 1);
      final saved = fakeWaterRepo.recorded.first;

      expect(saved.oxigenoMgL, 6.5);
      expect(saved.oxigenoPct, 92.5);
      expect(saved.temperaturaC, 28.4);
      expect(saved.ph, 7.35);
      expect(saved.amonioMgL, 0.18);
      expect(saved.nitritosMgL, 0.04);
      expect(saved.nitratosMgL, 4.5);
      expect(saved.alcalinidadMgL, 120.5);
      expect(saved.co2MgL, 5.0);
      expect(saved.durezaMgL, 140.0);
      expect(saved.cloroMgL, 0.01);
      expect(saved.observaciones, 'Medición post-alimentación');
      expect(saved.estanqueId, 'pond-001');

      // Modal must dismiss and SnackBar must appear
      expect(find.byType(ParametroModal), findsNothing);
      expect(find.textContaining('¡Medición registrada con éxito'), findsOneWidget);
    });

    testWidgets('5. Dynamic Alerts: Triggers hypoxia and ammonia toxicity alerts with comma numbers', (tester) async {
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(buildModalTestWidget());
      await tester.tap(find.text('Abrir Modal'));
      await tester.pumpAndSettle();

      final textFields = find.byType(TextFormField);

      // Trigger hypoxia (< 4.0 mg/L) with comma
      await tester.enterText(textFields.at(0), '3,2');
      await tester.pump();
      expect(find.textContaining('¡Alerta de Hipoxia!'), findsOneWidget);

      // Trigger toxic ammonia (> 0.5 ppm) with comma
      await tester.enterText(textFields.at(4), '0,85');
      await tester.pump();
      expect(find.textContaining('¡Alerta de Toxicidad!'), findsOneWidget);
    });
  });
}
```

---

## 5. Verification Method

### How to independently verify this report:
1. Run `flutter test test/modules/water_quality/water_parameter_test.dart` to confirm domain model stability (Expected: 3 passed).
2. Run `flutter test test/modules/bitacora/bitacora_screen_test.dart` to reproduce the exact 2 failing tests documented in Section 1.2.
3. Inspect `lib/modules/water_quality/presentation/dialogs/parametro_modal.dart` at line 271, 303, 320, 495 to confirm `double.tryParse` without comma replacement.
4. Once the implementer adds `test/modules/water_quality/parametro_modal_test.dart` and the suggested parser in `parametro_modal.dart`, run:
   ```bash
   flutter test test/modules/water_quality/
   ```
   All tests in `water_quality` must pass at 100%.
