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

class MockIter2WaterRepo implements WaterQualityRepository {
  List<WaterParameter> recorded = [];
  Duration? latency;
  bool shouldFail = false;
  String failureMessage = 'Simulated Database Connection Timeout';
  int callCount = 0;

  @override
  Future<List<WaterParameter>> fetchParametersByEstanque(String empresaId, String estanqueId) async => recorded;

  @override
  Future<List<WaterParameter>> fetchRecentParametersByUnit(String empresaId, String unidadAcuicolaId) async => recorded;

  @override
  Future<WaterParameter> recordParameters(WaterParameter parameter) async {
    callCount++;
    if (latency != null) {
      await Future<void>.delayed(latency!);
    }
    if (shouldFail) {
      throw StateError(failureMessage);
    }
    recorded.add(parameter);
    return parameter;
  }
}

class MockIter2PondsRepo implements PondsRepository {
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

class MockIter2AuthNotifier extends StateNotifier<AuthState> implements AuthNotifier {
  MockIter2AuthNotifier(super.initial);
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  late MockIter2WaterRepo waterRepo;
  late MockIter2PondsRepo pondsRepo;
  late AuthState testAuthState;

  final pond1 = Pond(
    id: 'pond-iter2-01',
    empresaId: 'emp-iter2',
    unidadAcuicolaId: 'unit-iter2',
    nombre: 'Estanque Tilapia 1',
    sigla: 'ET-01',
    capacidadM3: 150.0,
    creadoEn: DateTime(2026, 1, 1),
  );

  final pond2 = Pond(
    id: 'pond-iter2-02',
    empresaId: 'emp-iter2',
    unidadAcuicolaId: 'unit-iter2',
    nombre: 'Estanque Trucha 2',
    sigla: 'ET-02',
    capacidadM3: 250.0,
    creadoEn: DateTime(2026, 1, 1),
  );

  setUp(() {
    waterRepo = MockIter2WaterRepo();
    pondsRepo = MockIter2PondsRepo()..mockPonds = [pond1, pond2];

    testAuthState = AuthState(
      currentUser: UserMember(
        id: 'usr-iter2',
        empresaId: 'emp-iter2',
        unidadAcuicolaId: 'unit-iter2',
        nombre: 'Dr. Auditor Concurrencia',
        email: 'auditor@fishbit.test',
        role: UserRole.admin,
        estado: MemberStatus.active,
        creadoEn: DateTime(2026, 1, 1),
      ),
      currentCompany: const Company(
        id: 'emp-iter2',
        nombreComercial: 'Piscícola San Jerónimo',
        razonSocial: 'Piscícola San Jerónimo SAS',
        nit: '901.555.444-1',
      ),
      units: [
        AquacultureUnit(
          id: 'unit-iter2',
          empresaId: 'emp-iter2',
          nombre: 'Estación Central',
          sigla: 'EC',
          ubicacion: 'Betania, Huila',
          creadoEn: DateTime(2026, 1, 1),
        ),
      ],
      activeUnitId: 'unit-iter2',
    );
  });

  Widget buildHarness({String? preselectedPondId}) {
    return ProviderScope(
      overrides: [
        authProvider.overrideWith((ref) => MockIter2AuthNotifier(testAuthState)),
        waterQualityRepositoryProvider.overrideWithValue(waterRepo),
        pondsRepositoryProvider.overrideWithValue(pondsRepo),
      ],
      child: MaterialApp(
        theme: ThemeData.dark(),
        home: Scaffold(
          body: Builder(
            builder: (context) => Center(
              child: ElevatedButton(
                onPressed: () => ParametroModal.show(context, preselectedPondId: preselectedPondId),
                child: const Text('Abrir ParametroModal'),
              ),
            ),
          ),
        ),
      ),
    );
  }

  group('Challenger M2_2 Iteration 2: Empirical Stress Test Harness', () {
    testWidgets('Stress Test 1: Quadruple rapid tap under 150ms network delay ensures strict single insert', (tester) async {
      tester.view.physicalSize = const Size(800, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      waterRepo.latency = const Duration(milliseconds: 150);

      await tester.pumpWidget(buildHarness(preselectedPondId: 'pond-iter2-01'));
      await tester.tap(find.text('Abrir ParametroModal'));
      await tester.pumpAndSettle();

      final fields = find.byType(TextFormField);
      await tester.enterText(fields.at(0), '7.2');
      await tester.enterText(fields.at(2), '26.8');
      await tester.enterText(fields.at(3), '7.35');

      final saveButton = find.byType(GlassButton);

      // Tap 1
      await tester.tap(saveButton);
      await tester.pump(const Duration(milliseconds: 20));

      // CircularProgressIndicator must be active
      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      // Rapid Taps 2, 3, 4 while async write is pending
      await tester.tap(saveButton, warnIfMissed: false);
      await tester.pump(const Duration(milliseconds: 20));
      await tester.tap(saveButton, warnIfMissed: false);
      await tester.pump(const Duration(milliseconds: 20));
      await tester.tap(saveButton, warnIfMissed: false);

      // Settle all async operations
      await tester.pumpAndSettle();

      // Assertions: exactly 1 call and 1 insert occurred
      expect(waterRepo.callCount, 1);
      expect(waterRepo.recorded.length, 1);
      expect(find.byType(ParametroModal), findsNothing);
      expect(find.textContaining('¡Medición registrada con éxito'), findsOneWidget);
    });

    testWidgets('Stress Test 2: Network failure leaves modal open, displays SnackBar, and recovers on user retry', (tester) async {
      tester.view.physicalSize = const Size(800, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      waterRepo.shouldFail = true;
      waterRepo.failureMessage = 'PostgreSQL 503 Service Unavailable';

      await tester.pumpWidget(buildHarness(preselectedPondId: 'pond-iter2-01'));
      await tester.tap(find.text('Abrir ParametroModal'));
      await tester.pumpAndSettle();

      final fields = find.byType(TextFormField);
      await tester.enterText(fields.at(0), '6.8');
      await tester.enterText(fields.at(2), '27.4');
      await tester.enterText(fields.at(3), '7.15');
      await tester.enterText(fields.at(11), 'Observación pre-falla');

      final saveButton = find.byType(GlassButton);

      // First attempt: Fails
      await tester.tap(saveButton);
      await tester.pumpAndSettle();

      expect(waterRepo.callCount, 1);
      expect(waterRepo.recorded, isEmpty);
      expect(find.byType(ParametroModal), findsOneWidget); // Modal MUST stay open
      expect(find.textContaining('PostgreSQL 503 Service Unavailable'), findsOneWidget);

      // Verify form state is intact
      expect(find.text('6.8'), findsOneWidget);
      expect(find.text('27.4'), findsOneWidget);
      expect(find.text('7.15'), findsOneWidget);
      expect(find.text('Observación pre-falla'), findsOneWidget);

      // Now heal the connection and retry
      waterRepo.shouldFail = false;
      await tester.tap(saveButton);
      await tester.pumpAndSettle();

      // Must succeed on retry
      expect(waterRepo.callCount, 2);
      expect(waterRepo.recorded.length, 1);
      expect(waterRepo.recorded.first.oxigenoMgL, 6.8);
      expect(waterRepo.recorded.first.observaciones, 'Observación pre-falla');
      expect(find.byType(ParametroModal), findsNothing);

      // Advance past the first SnackBar's display duration so queued success SnackBar appears
      await tester.pump(const Duration(seconds: 4));
      await tester.pumpAndSettle();
      expect(find.textContaining('¡Medición registrada con éxito'), findsOneWidget);
    });

    testWidgets('Stress Test 3: Nitrite banner appears dynamically at 0.3 ppm, disappears when cleared, and survives multi-alerts', (tester) async {
      tester.view.physicalSize = const Size(800, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(buildHarness(preselectedPondId: 'pond-iter2-01'));
      await tester.tap(find.text('Abrir ParametroModal'));
      await tester.pumpAndSettle();

      final fields = find.byType(TextFormField);
      // Nitritos is index 5
      final nitritoField = fields.at(5);

      // 1. Boundary: 0.20 ppm -> NO alert
      await tester.enterText(nitritoField, '0.20');
      await tester.pump();
      expect(find.textContaining('Nitritos NO₂⁻ > 0.2 ppm'), findsNothing);

      // 2. Alert triggered: 0.30 ppm -> Banner renders visibly with icon and warning text
      await tester.enterText(nitritoField, '0.30');
      await tester.pump();
      expect(find.textContaining('¡Alerta Crítica! Nitritos NO₂⁻ > 0.2 ppm. Alto riesgo de toxicidad e hipoxia tisular.'), findsOneWidget);

      // 3. Multi-alert cascade: Hypoxia (index 0 = 2.5), Ammonia (index 4 = 0.9), Chlorine (index 10 = 0.2)
      await tester.enterText(fields.at(0), '2.5'); // Hypoxia
      await tester.enterText(fields.at(4), '0.9'); // Ammonia
      await tester.enterText(fields.at(10), '0.2'); // Chlorine
      await tester.pump();

      expect(find.textContaining('¡Alerta de Hipoxia!'), findsOneWidget);
      expect(find.textContaining('¡Alerta de Toxicidad! Amonio'), findsOneWidget);
      expect(find.textContaining('¡Alerta Crítica! Nitritos NO₂⁻ > 0.2 ppm'), findsOneWidget);
      expect(find.textContaining('Presencia de Cloro Residual'), findsOneWidget);

      // 4. Remove nitrites -> other alerts remain, nitrite alert removed cleanly
      await tester.enterText(nitritoField, '');
      await tester.pump();
      expect(find.textContaining('Nitritos NO₂⁻ > 0.2 ppm'), findsNothing);
      expect(find.textContaining('¡Alerta de Hipoxia!'), findsOneWidget);
      expect(find.textContaining('¡Alerta de Toxicidad! Amonio'), findsOneWidget);
      expect(find.textContaining('Presencia de Cloro Residual'), findsOneWidget);
    });

    testWidgets('Stress Test 4: Stale pond ID blocks save, but user can recover by picking valid pond from dropdown', (tester) async {
      tester.view.physicalSize = const Size(800, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      // Preselect a non-existent / deleted pond ID
      await tester.pumpWidget(buildHarness(preselectedPondId: 'non-existent-or-deleted-pond-id'));
      await tester.tap(find.text('Abrir ParametroModal'));
      await tester.pumpAndSettle();

      final fields = find.byType(TextFormField);
      await tester.enterText(fields.at(0), '6.5');
      await tester.enterText(fields.at(2), '27.0');
      await tester.enterText(fields.at(3), '7.3');

      // Attempt Save with stale pond ID
      final saveButton = find.byType(GlassButton);
      await tester.tap(saveButton);
      await tester.pumpAndSettle();

      // Blocked!
      expect(waterRepo.recorded, isEmpty);
      expect(find.text('Debe seleccionar un estanque de medición válido para registrar los parámetros.'), findsOneWidget);
      expect(find.byType(ParametroModal), findsOneWidget);

      // Now user interacts with Dropdown and selects pond2
      await tester.tap(find.byType(DropdownButton<String>), warnIfMissed: false);
      await tester.pumpAndSettle();

      await tester.tap(find.text('Estanque Trucha 2 (ET-02)').last);
      await tester.pumpAndSettle();

      // Retry Save
      await tester.tap(saveButton);
      await tester.pumpAndSettle();

      // Successfully saved with selected pond
      expect(waterRepo.recorded.length, 1);
      expect(waterRepo.recorded.first.estanqueId, 'pond-iter2-02');
      expect(find.byType(ParametroModal), findsNothing);
    });

    testWidgets('Stress Test 5: Exhaustive non-finite and IEEE 754 "NaN" inputs are rejected across all fields', (tester) async {
      tester.view.physicalSize = const Size(800, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(buildHarness(preselectedPondId: 'pond-iter2-01'));
      await tester.tap(find.text('Abrir ParametroModal'));
      await tester.pumpAndSettle();

      final fields = find.byType(TextFormField);
      final saveButton = find.byType(GlassButton);

      // 1. Enter lowercase "nan", "+nan", "-nan", "Infinity", "-Infinity"
      await tester.enterText(fields.at(0), 'nan');
      await tester.enterText(fields.at(2), '+Infinity');
      await tester.enterText(fields.at(3), '-Infinity');

      await tester.tap(saveButton);
      await tester.pumpAndSettle();

      expect(waterRepo.recorded, isEmpty);
      expect(find.text('0-30 mg/L'), findsOneWidget);
      expect(find.text('5-45°C'), findsOneWidget);
      expect(find.text('0-14'), findsOneWidget);

      // 2. Mixed case NaN: "NaN", "-NaN"
      await tester.enterText(fields.at(0), '-NaN');
      await tester.enterText(fields.at(2), 'NaN');
      await tester.enterText(fields.at(3), '+NaN');

      await tester.tap(saveButton);
      await tester.pumpAndSettle();

      expect(waterRepo.recorded, isEmpty);
      expect(find.text('0-30 mg/L'), findsOneWidget);
      expect(find.text('5-45°C'), findsOneWidget);
      expect(find.text('0-14'), findsOneWidget);
    });
  });
}
