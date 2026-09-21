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
import 'package:fishbit_finance/core/design_system/glass_button.dart';

class FakeWaterQualityRepo implements WaterQualityRepository {
  List<WaterParameter> recorded = [];
  Duration? delay;
  bool shouldThrow = false;
  String errorMessage = 'Database connection failure';

  @override
  Future<List<WaterParameter>> fetchParametersByEstanque(String empresaId, String estanqueId) async => recorded;

  @override
  Future<List<WaterParameter>> fetchRecentParametersByUnit(String empresaId, String unidadAcuicolaId) async => recorded;

  @override
  Future<WaterParameter> recordParameters(WaterParameter parameter) async {
    if (delay != null) {
      await Future<void>.delayed(delay!);
    }
    if (shouldThrow) {
      throw StateError(errorMessage);
    }
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
  Future<void> transferOrSplitBatch({
    required String batchOrigenId,
    required String estanqueOrigenId,
    required String estanqueDestinoId,
    required int pecesTrasladados,
    required double biomasaTrasladadaKg,
    required bool esDesdoble,
    required String nuevoCodigoLote,
    String? registradoPor,
  }) async {}
  @override
  Future<List<TransferRecord>> fetchTransfersByUnit(String empresaId, String unidadAcuicolaId, {String? pondId, String? batchId}) async => [];
  @override
  Future<List<BiometriaRecord>> fetchBiometriesByUnit(String empresaId, String unidadAcuicolaId, {String? pondId, String? batchId}) async => [];
  @override
  Future<List<MortalityRecord>> fetchMortalityByUnit(String empresaId, String unidadAcuicolaId, {String? pondId, String? batchId}) async => [];
  @override
  Future<BiometriaRecord> registerBiometry({
    String? empresaId,
    String? unidadAcuicolaId,
    required String estanqueId,
    required String loteId,
    required double nuevoPesoPromedioGramos,
    int? cantidadPecesMuestreados,
    double? pesoTotalCapturaKg,
    double? longitudPromedioCm,
    double? factorK,
    double? gdpGDia,
    String? observaciones,
    String? registradoPor,
    DateTime? fecha,
    String? hora,
  }) async {
    throw UnimplementedError();
  }
  @override
  Future<MortalityRecord> registerMortality({
    String? empresaId,
    String? unidadAcuicolaId,
    required String estanqueId,
    required String loteId,
    required int cantidadPecesMuertos,
    required double pesoPromedioGramos,
    required String causaProbable,
    double? biomasaPerdidaKg,
    String? observaciones,
    String? registradoPor,
    DateTime? fecha,
    String? hora,
  }) async {
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

      await tester.pumpWidget(buildModalTestWidget(preselectedPondId: 'pond-001'));
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

      await tester.pumpWidget(buildModalTestWidget(preselectedPondId: 'pond-001'));
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

      await tester.pumpWidget(buildModalTestWidget(preselectedPondId: 'pond-001'));
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

      await tester.pumpWidget(buildModalTestWidget(preselectedPondId: 'pond-001'));
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

    testWidgets('6. Mandatory Pond Selection: Blocks save and shows SnackBar when no pond is selected', (tester) async {
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(buildModalTestWidget()); // preselectedPondId is null
      await tester.tap(find.text('Abrir Modal'));
      await tester.pumpAndSettle();

      // Enter valid required fields
      final textFields = find.byType(TextFormField);
      await tester.enterText(textFields.at(0), '6.5');
      await tester.enterText(textFields.at(2), '28.0');
      await tester.enterText(textFields.at(3), '7.2');

      // Tap Save without selecting a pond
      await tester.tap(find.text('Guardar Medición de Calidad de Agua'));
      await tester.pumpAndSettle();

      expect(fakeWaterRepo.recorded, isEmpty);
      expect(find.text('Debe seleccionar un estanque de medición válido para registrar los parámetros.'), findsOneWidget);
    });

    testWidgets('7. Concurrency Lock: Rapid double-tap does not cause duplicate inserts', (tester) async {
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      fakeWaterRepo.delay = const Duration(milliseconds: 100);

      await tester.pumpWidget(buildModalTestWidget(preselectedPondId: 'pond-001'));
      await tester.tap(find.text('Abrir Modal'));
      await tester.pumpAndSettle();

      final textFields = find.byType(TextFormField);
      await tester.enterText(textFields.at(0), '6.5');
      await tester.enterText(textFields.at(2), '28.0');
      await tester.enterText(textFields.at(3), '7.2');

      final buttonFinder = find.byType(GlassButton);

      // First tap initiates submission and sets _isSubmitting = true
      await tester.tap(buttonFinder);
      await tester.pump(const Duration(milliseconds: 10));

      // Verify that while submitting, progress indicator is shown
      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      // Second tap while async repository operation is still executing
      await tester.tap(buttonFinder, warnIfMissed: false);
      await tester.pumpAndSettle();

      // Exactly 1 record must be inserted
      expect(fakeWaterRepo.recorded.length, 1);
      expect(find.byType(ParametroModal), findsNothing);
      expect(find.textContaining('¡Medición registrada con éxito'), findsOneWidget);
    });

    testWidgets('8. Error Handling: Repository failure keeps dialog open and shows error SnackBar', (tester) async {
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      fakeWaterRepo.shouldThrow = true;
      fakeWaterRepo.errorMessage = 'PostgreSQL connection timeout';

      await tester.pumpWidget(buildModalTestWidget(preselectedPondId: 'pond-001'));
      await tester.tap(find.text('Abrir Modal'));
      await tester.pumpAndSettle();

      final textFields = find.byType(TextFormField);
      await tester.enterText(textFields.at(0), '6.5');
      await tester.enterText(textFields.at(2), '28.0');
      await tester.enterText(textFields.at(3), '7.2');

      await tester.tap(find.text('Guardar Medición de Calidad de Agua'));
      await tester.pumpAndSettle();

      // Repository must not have recorded any parameters
      expect(fakeWaterRepo.recorded, isEmpty);
      // Dialog must NOT pop
      expect(find.byType(ParametroModal), findsOneWidget);
      // Error SnackBar must be displayed with error message
      expect(find.textContaining('Error al registrar medición:'), findsOneWidget);
      expect(find.textContaining('PostgreSQL connection timeout'), findsOneWidget);
    });

    testWidgets('9. Dynamic Alerts: Critical nitrite displays alert banner with descriptive warning text', (tester) async {
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(buildModalTestWidget(preselectedPondId: 'pond-001'));
      await tester.tap(find.text('Abrir Modal'));
      await tester.pumpAndSettle();

      final textFields = find.byType(TextFormField);

      // Enter critical nitrite value (> 0.2 ppm) using comma
      await tester.enterText(textFields.at(5), '0,35');
      await tester.pump();

      // Nitrite warning banner must be visible and contain exact text
      expect(find.textContaining('¡Alerta Crítica! Nitritos NO₂⁻ > 0.2 ppm. Alto riesgo de toxicidad e hipoxia tisular.'), findsOneWidget);

      // Clear nitrite value to verify banner disappears
      await tester.enterText(textFields.at(5), '');
      await tester.pump();
      expect(find.textContaining('Nitritos NO₂⁻ > 0.2 ppm'), findsNothing);
    });

    testWidgets('10. Stale Pond Validation: Rejects submission when preselectedPondId does not exist in ponds list', (tester) async {
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      // Supply a stale pond id that is not in fakePondsRepo.mockPonds
      await tester.pumpWidget(buildModalTestWidget(preselectedPondId: 'deleted-stale-pond-999'));
      await tester.tap(find.text('Abrir Modal'));
      await tester.pumpAndSettle();

      // Enter valid routine parameters
      final textFields = find.byType(TextFormField);
      await tester.enterText(textFields.at(0), '6.5');
      await tester.enterText(textFields.at(2), '28.0');
      await tester.enterText(textFields.at(3), '7.2');

      // Tap Save
      await tester.tap(find.text('Guardar Medición de Calidad de Agua'));
      await tester.pumpAndSettle();

      // Must reject submission
      expect(fakeWaterRepo.recorded, isEmpty);
      expect(find.byType(ParametroModal), findsOneWidget);
      expect(find.text('Debe seleccionar un estanque de medición válido para registrar los parámetros.'), findsOneWidget);
    });

    testWidgets('11. Input Sanitization: "NaN" and infinite inputs are rejected by range validators', (tester) async {
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(buildModalTestWidget(preselectedPondId: 'pond-001'));
      await tester.tap(find.text('Abrir Modal'));
      await tester.pumpAndSettle();

      final textFields = find.byType(TextFormField);

      // Enter "NaN" in required fields
      await tester.enterText(textFields.at(0), 'NaN');
      await tester.enterText(textFields.at(2), 'NaN');
      await tester.enterText(textFields.at(3), 'NaN');

      await tester.tap(find.text('Guardar Medición de Calidad de Agua'));
      await tester.pumpAndSettle();

      // Must be rejected by validators and not saved
      expect(fakeWaterRepo.recorded, isEmpty);
      expect(find.text('0-30 mg/L'), findsOneWidget);
      expect(find.text('5-45°C'), findsOneWidget);
      expect(find.text('0-14'), findsOneWidget);
      expect(find.byType(ParametroModal), findsOneWidget);
    });
  });
}
