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

class MockWaterQualityRepo implements WaterQualityRepository {
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

class MockPondsRepo implements PondsRepository {
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
  }) async => throw UnimplementedError();
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
  }) async => throw UnimplementedError();
}

class MockAuthNotifier extends StateNotifier<AuthState> implements AuthNotifier {
  MockAuthNotifier(super.initial);
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  late MockWaterQualityRepo mockWaterRepo;
  late MockPondsRepo mockPondsRepo;
  late AuthState testAuthState;

  final testPond = Pond(
    id: 'pond-adversarial-01',
    empresaId: 'emp-adv-01',
    unidadAcuicolaId: 'unit-adv-01',
    nombre: 'Estanque Intensivo 1',
    sigla: 'EI-01',
    capacidadM3: 200.0,
    creadoEn: DateTime(2026, 1, 1),
  );

  setUp(() {
    mockWaterRepo = MockWaterQualityRepo();
    mockPondsRepo = MockPondsRepo()..mockPonds = [testPond];

    testAuthState = AuthState(
      currentUser: UserMember(
        id: 'usr-adv',
        empresaId: 'emp-adv-01',
        unidadAcuicolaId: 'unit-adv-01',
        nombre: 'Adversarial Challenger',
        email: 'challenger@fishbit.test',
        role: UserRole.admin,
        estado: MemberStatus.active,
        creadoEn: DateTime(2026, 1, 1),
      ),
      currentCompany: const Company(
        id: 'emp-adv-01',
        nombreComercial: 'Acuícola Stress Test',
        razonSocial: 'Acuícola Stress Test SAS',
        nit: '900.999.888-7',
      ),
      units: [
        AquacultureUnit(
          id: 'unit-adv-01',
          empresaId: 'emp-adv-01',
          nombre: 'Unidad de Pruebas',
          sigla: 'U-ADV',
          ubicacion: 'Neiva, Huila',
          creadoEn: DateTime(2026, 1, 1),
        ),
      ],
      activeUnitId: 'unit-adv-01',
    );
  });

  Widget buildTestModal({String? preselectedPondId}) {
    return ProviderScope(
      overrides: [
        authProvider.overrideWith((ref) => MockAuthNotifier(testAuthState)),
        waterQualityRepositoryProvider.overrideWithValue(mockWaterRepo),
        pondsRepositoryProvider.overrideWithValue(mockPondsRepo),
      ],
      child: MaterialApp(
        theme: ThemeData.dark(),
        home: Scaffold(
          body: Builder(
            builder: (context) => Center(
              child: ElevatedButton(
                onPressed: () => ParametroModal.show(context, preselectedPondId: preselectedPondId),
                child: const Text('Lanzar Modal'),
              ),
            ),
          ),
        ),
      ),
    );
  }

  group('Empirical Challenger M2_1: ParametroModal Adversarial Stress Tests', () {
    testWidgets('Decimal parsing unit behavior in Dart', (tester) async {
      // Direct empirical verification of double.tryParse edge cases
      expect(double.tryParse('NaN')?.isNaN, isTrue);
      expect(double.tryParse('Infinity')?.isInfinite, isTrue);
      expect(double.tryParse('-Infinity')?.isInfinite, isTrue);
      expect(double.tryParse('1e2'), 100.0);
      expect(double.tryParse('6.2'), 6.2);
    });

    testWidgets('1. Comma parsing with leading/trailing whitespace & multiple digits', (tester) async {
      tester.view.physicalSize = const Size(800, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(buildTestModal(preselectedPondId: 'pond-adversarial-01'));
      await tester.tap(find.text('Lanzar Modal'));
      await tester.pumpAndSettle();

      final fields = find.byType(TextFormField);

      // Enter values with whitespace around commas and high precision
      await tester.enterText(fields.at(0), '   6,200   ');
      await tester.enterText(fields.at(2), ' \t 28,50 \n ');
      await tester.enterText(fields.at(3), '  7,40  ');

      await tester.tap(find.text('Guardar Medición de Calidad de Agua'));
      await tester.pumpAndSettle();

      expect(mockWaterRepo.recorded.length, 1);
      final saved = mockWaterRepo.recorded.first;
      expect(saved.oxigenoMgL, 6.2);
      expect(saved.temperaturaC, 28.5);
      expect(saved.ph, 7.4);
    });

    testWidgets('2. Exact boundary tests: 0.0, 30.0, 5.0, 45.0, 14.0 must be accepted', (tester) async {
      tester.view.physicalSize = const Size(800, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(buildTestModal(preselectedPondId: 'pond-adversarial-01'));
      await tester.tap(find.text('Lanzar Modal'));
      await tester.pumpAndSettle();

      final fields = find.byType(TextFormField);

      // Exact minimum boundary: O2 = 0, Temp = 5, pH = 0
      await tester.enterText(fields.at(0), '0,0');
      await tester.enterText(fields.at(2), '5,0');
      await tester.enterText(fields.at(3), '0,0');

      await tester.tap(find.text('Guardar Medición de Calidad de Agua'));
      await tester.pumpAndSettle();

      expect(mockWaterRepo.recorded.length, 1);
      expect(mockWaterRepo.recorded.first.oxigenoMgL, 0.0);
      expect(mockWaterRepo.recorded.first.temperaturaC, 5.0);
      expect(mockWaterRepo.recorded.first.ph, 0.0);

      // Re-open and test exact maximum boundary: O2 = 30, Temp = 45, pH = 14
      await tester.tap(find.text('Lanzar Modal'));
      await tester.pumpAndSettle();

      final fields2 = find.byType(TextFormField);
      await tester.enterText(fields2.at(0), '30,0');
      await tester.enterText(fields2.at(2), '45,0');
      await tester.enterText(fields2.at(3), '14,0');

      await tester.tap(find.text('Guardar Medición de Calidad de Agua'));
      await tester.pumpAndSettle();

      expect(mockWaterRepo.recorded.length, 2);
      expect(mockWaterRepo.recorded[1].oxigenoMgL, 30.0);
      expect(mockWaterRepo.recorded[1].temperaturaC, 45.0);
      expect(mockWaterRepo.recorded[1].ph, 14.0);
    });

    testWidgets('3. Boundary violation tests: -0.01, 30.01, 4.99, 45.01, -0.01, 14.01 must be rejected', (tester) async {
      tester.view.physicalSize = const Size(800, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(buildTestModal(preselectedPondId: 'pond-adversarial-01'));
      await tester.tap(find.text('Lanzar Modal'));
      await tester.pumpAndSettle();

      final fields = find.byType(TextFormField);

      // Test just below lower boundary
      await tester.enterText(fields.at(0), '-0,01');
      await tester.enterText(fields.at(2), '4,99');
      await tester.enterText(fields.at(3), '-0,01');

      await tester.tap(find.text('Guardar Medición de Calidad de Agua'));
      await tester.pumpAndSettle();

      expect(mockWaterRepo.recorded, isEmpty);
      expect(find.text('0-30 mg/L'), findsOneWidget);
      expect(find.text('5-45°C'), findsOneWidget);
      expect(find.text('0-14'), findsOneWidget);

      // Test just above upper boundary
      await tester.enterText(fields.at(0), '30,01');
      await tester.enterText(fields.at(2), '45,01');
      await tester.enterText(fields.at(3), '14,01');

      await tester.tap(find.text('Guardar Medición de Calidad de Agua'));
      await tester.pumpAndSettle();

      expect(mockWaterRepo.recorded, isEmpty);
      expect(find.text('0-30 mg/L'), findsOneWidget);
      expect(find.text('5-45°C'), findsOneWidget);
      expect(find.text('0-14'), findsOneWidget);
    });

    testWidgets('4. Adversarial inputs: multiple commas, emoji, text, special chars rejected', (tester) async {
      tester.view.physicalSize = const Size(800, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(buildTestModal(preselectedPondId: 'pond-adversarial-01'));
      await tester.tap(find.text('Lanzar Modal'));
      await tester.pumpAndSettle();

      final fields = find.byType(TextFormField);

      // Enter multiple commas, emojis, and strings
      await tester.enterText(fields.at(0), '6,,2');
      await tester.enterText(fields.at(2), '28°C');
      await tester.enterText(fields.at(3), 'pH 7,4');

      await tester.tap(find.text('Guardar Medición de Calidad de Agua'));
      await tester.pumpAndSettle();

      expect(mockWaterRepo.recorded, isEmpty);
      expect(find.text('0-30 mg/L'), findsOneWidget);
      expect(find.text('5-45°C'), findsOneWidget);
      expect(find.text('0-14'), findsOneWidget);

      // Try emojis and symbols
      await tester.enterText(fields.at(0), '🐟 6,2');
      await tester.enterText(fields.at(2), '🔥 28');
      await tester.enterText(fields.at(3), '🧪 7');

      await tester.tap(find.text('Guardar Medición de Calidad de Agua'));
      await tester.pumpAndSettle();

      expect(mockWaterRepo.recorded, isEmpty);
      expect(find.text('0-30 mg/L'), findsOneWidget);
      expect(find.text('5-45°C'), findsOneWidget);
      expect(find.text('0-14'), findsOneWidget);

      // Try pure whitespace
      await tester.enterText(fields.at(0), '   ');
      await tester.enterText(fields.at(2), '\t\n');
      await tester.enterText(fields.at(3), '  ');

      await tester.tap(find.text('Guardar Medición de Calidad de Agua'));
      await tester.pumpAndSettle();

      expect(mockWaterRepo.recorded, isEmpty);
      expect(find.text('Requerido'), findsAtLeastNWidgets(3));
    });

    testWidgets('5. Scientific notation & Extreme values: 1e9, 999999, Infinity rejected', (tester) async {
      tester.view.physicalSize = const Size(800, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(buildTestModal(preselectedPondId: 'pond-adversarial-01'));
      await tester.tap(find.text('Lanzar Modal'));
      await tester.pumpAndSettle();

      final fields = find.byType(TextFormField);

      // Test extreme numbers
      await tester.enterText(fields.at(0), '999999');
      await tester.enterText(fields.at(2), '1e9');
      await tester.enterText(fields.at(3), 'Infinity');

      await tester.tap(find.text('Guardar Medición de Calidad de Agua'));
      await tester.pumpAndSettle();

      expect(mockWaterRepo.recorded, isEmpty);
      expect(find.text('0-30 mg/L'), findsOneWidget);
      expect(find.text('5-45°C'), findsOneWidget);
      expect(find.text('0-14'), findsOneWidget);
    });

    testWidgets('6. NaN input vulnerability assessment in required fields', (tester) async {
      tester.view.physicalSize = const Size(800, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(buildTestModal(preselectedPondId: 'pond-adversarial-01'));
      await tester.tap(find.text('Lanzar Modal'));
      await tester.pumpAndSettle();

      final fields = find.byType(TextFormField);

      // Entering "NaN" in O2, Temp, and pH
      await tester.enterText(fields.at(0), 'NaN');
      await tester.enterText(fields.at(2), 'NaN');
      await tester.enterText(fields.at(3), 'NaN');

      await tester.tap(find.text('Guardar Medición de Calidad de Agua'));
      await tester.pumpAndSettle();

      // Document adversarial observation:
      // In IEEE 754, NaN comparisons (< 0, > 30) evaluate to false.
      // With isNaN check in _parseDecimal, NaN is safely parsed as null, triggering validation errors.
      expect(mockWaterRepo.recorded, isEmpty);
      expect(find.text('0-30 mg/L'), findsOneWidget);
      expect(find.text('5-45°C'), findsOneWidget);
      expect(find.text('0-14'), findsOneWidget);
      expect(find.byType(ParametroModal), findsOneWidget);
    });

    testWidgets('7. Optional parameter inputs: negative numbers and invalid text behavior', (tester) async {
      tester.view.physicalSize = const Size(800, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(buildTestModal(preselectedPondId: 'pond-adversarial-01'));
      await tester.tap(find.text('Lanzar Modal'));
      await tester.pumpAndSettle();

      final fields = find.byType(TextFormField);

      // Valid required fields
      await tester.enterText(fields.at(0), '6,2');
      await tester.enterText(fields.at(2), '28,5');
      await tester.enterText(fields.at(3), '7,4');

      // Optional fields:
      // field 1 is Saturation (%)
      // field 4 is Amonio (ppm)
      // field 10 is Cloro (ppm)
      await tester.enterText(fields.at(1), 'invalid_text');
      await tester.enterText(fields.at(4), '-5,5'); // Negative amonio
      await tester.enterText(fields.at(10), '-0,1'); // Negative chlorine

      await tester.tap(find.text('Guardar Medición de Calidad de Agua'));
      await tester.pumpAndSettle();

      expect(mockWaterRepo.recorded.length, 1);
      final saved = mockWaterRepo.recorded.first;

      // Unparseable string in optional field is safely coerced to null by _parseDecimal
      expect(saved.oxigenoPct, isNull);
      // Verify values saved for negative optional inputs
      expect(saved.amonioMgL, -5.5);
      expect(saved.cloroMgL, -0.1);
    });

  });
}
