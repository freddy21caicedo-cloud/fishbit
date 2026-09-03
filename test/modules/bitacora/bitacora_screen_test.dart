import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fishbit_finance/modules/bitacora/presentation/screens/bitacora_screen.dart';
import 'package:fishbit_finance/modules/auth_tenant/domain/models/company.dart';
import 'package:fishbit_finance/modules/auth_tenant/domain/models/user_member.dart';
import 'package:fishbit_finance/modules/auth_tenant/domain/models/aquaculture_unit.dart';
import 'package:fishbit_finance/modules/auth_tenant/presentation/providers/auth_provider.dart';
import 'package:fishbit_finance/modules/water_quality/domain/models/water_parameter.dart';
import 'package:fishbit_finance/modules/water_quality/domain/repositories/water_quality_repository.dart';
import 'package:fishbit_finance/modules/water_quality/presentation/providers/water_quality_provider.dart';
import 'package:fishbit_finance/modules/feeding_nutrition/domain/models/feeding_record.dart';
import 'package:fishbit_finance/modules/feeding_nutrition/domain/models/nutrition_table.dart';
import 'package:fishbit_finance/modules/feeding_nutrition/domain/repositories/nutrition_repository.dart';
import 'package:fishbit_finance/modules/feeding_nutrition/presentation/providers/nutrition_provider.dart';
import 'package:fishbit_finance/modules/ponds_batches/domain/models/pond.dart';
import 'package:fishbit_finance/modules/ponds_batches/domain/models/fish_batch.dart';
import 'package:fishbit_finance/modules/ponds_batches/domain/models/biometria_record.dart';
import 'package:fishbit_finance/modules/ponds_batches/domain/models/mortality_record.dart';
import 'package:fishbit_finance/modules/ponds_batches/domain/models/transfer_record.dart';
import 'package:fishbit_finance/modules/ponds_batches/domain/repositories/ponds_repository.dart';
import 'package:fishbit_finance/modules/ponds_batches/presentation/providers/ponds_provider.dart';

class FakeWaterQualityRepository implements WaterQualityRepository {
  List<WaterParameter> params = [];

  @override
  Future<List<WaterParameter>> fetchParametersByEstanque(String empresaId, String estanqueId) async {
    return params.where((p) => p.estanqueId == estanqueId).toList();
  }

  @override
  Future<List<WaterParameter>> fetchRecentParametersByUnit(String empresaId, String unidadAcuicolaId) async {
    return List.from(params);
  }

  @override
  Future<WaterParameter> recordParameters(WaterParameter parameter) async {
    params.insert(0, parameter);
    return parameter;
  }
}

class FakeNutritionRepository implements NutritionRepository {
  List<FeedingRecord> records = [];

  @override
  Future<List<FeedingRecord>> fetchFeedingRecords(String empresaId, String unidadAcuicolaId) async {
    return List.from(records);
  }

  @override
  Future<List<NutritionTable>> fetchNutritionTables(String empresaId) async => [];

  @override
  Future<void> saveNutritionTable(NutritionTable table) async {}

  @override
  Future<void> deleteNutritionTable(String tableId) async {}

  @override
  Future<FeedingRecord> recordFeeding({
    required String empresaId,
    required String unidadAcuicolaId,
    required String estanqueId,
    required String loteId,
    String? insumoId,
    required double kgConsumidos,
    required double costoUnitarioAlimento,
  }) async {
    final r = FeedingRecord(
      id: 'feed-new',
      empresaId: empresaId,
      unidadAcuicolaId: unidadAcuicolaId,
      estanqueId: estanqueId,
      loteId: loteId,
      insumoId: insumoId ?? 'ins-1',
      cantidadConsumidaKg: kgConsumidos,
      costoCalculado: kgConsumidos * costoUnitarioAlimento,
      fecha: DateTime.now(),
      creadoEn: DateTime.now(),
    );
    records.insert(0, r);
    return r;
  }
}

class FakePondsRepository implements PondsRepository {
  List<Pond> ponds = [];
  List<FishBatch> batches = [];
  List<BiometriaRecord> biometries = [];
  List<MortalityRecord> mortalities = [];

  @override
  Future<List<Pond>> fetchPondsByUnit(String empresaId, String unidadAcuicolaId) async => List.from(ponds);

  @override
  Future<Pond> createPond(Pond pond) async {
    ponds.add(pond);
    return pond;
  }

  @override
  Future<void> updatePond(Pond pond) async {
    final idx = ponds.indexWhere((p) => p.id == pond.id);
    if (idx != -1) ponds[idx] = pond;
  }

  @override
  Future<void> deletePond(String pondId) async {
    ponds.removeWhere((p) => p.id == pondId);
  }

  @override
  Future<List<FishBatch>> fetchBatchesByUnit(String empresaId, String unidadAcuicolaId) async => List.from(batches);

  @override
  Future<FishBatch> createBatch(FishBatch batch) async {
    batches.add(batch);
    return batch;
  }

  @override
  Future<void> updateBatch(FishBatch batch) async {
    final idx = batches.indexWhere((b) => b.id == batch.id);
    if (idx != -1) batches[idx] = batch;
  }

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
  Future<List<TransferRecord>> fetchTransfersByUnit(
    String empresaId,
    String unidadAcuicolaId, {
    String? pondId,
    String? batchId,
  }) async => [];

  @override
  Future<List<BiometriaRecord>> fetchBiometriesByUnit(
    String empresaId,
    String unidadAcuicolaId, {
    String? pondId,
    String? batchId,
  }) async {
    var result = List<BiometriaRecord>.from(biometries);
    if (pondId != null) result = result.where((b) => b.estanqueId == pondId).toList();
    if (batchId != null) result = result.where((b) => b.loteId == batchId).toList();
    return result;
  }

  @override
  Future<List<MortalityRecord>> fetchMortalityByUnit(
    String empresaId,
    String unidadAcuicolaId, {
    String? pondId,
    String? batchId,
  }) async {
    var result = List<MortalityRecord>.from(mortalities);
    if (pondId != null) result = result.where((m) => m.estanqueId == pondId).toList();
    if (batchId != null) result = result.where((m) => m.loteId == batchId).toList();
    return result;
  }

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
    final b = BiometriaRecord(
      id: 'bio-new',
      empresaId: empresaId ?? 'emp-1',
      unitId: unidadAcuicolaId ?? 'unit-1',
      estanqueId: estanqueId,
      loteId: loteId,
      fecha: fecha ?? DateTime.now(),
      hora: hora,
      pecesCapturados: cantidadPecesMuestreados ?? 35,
      pesoTotalCapturaKg: pesoTotalCapturaKg ?? 10.0,
      pesoPromedioG: nuevoPesoPromedioGramos,
      biomasaParcialKg: 2500.0,
      longitudCm: longitudPromedioCm,
      factorK: factorK,
      gdpGDia: gdpGDia,
      observaciones: observaciones,
      registradoPor: registradoPor,
      creadoEn: DateTime.now(),
    );
    biometries.insert(0, b);
    return b;
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
    final m = MortalityRecord(
      id: 'mort-new',
      empresaId: empresaId ?? 'emp-1',
      unidadAcuicolaId: unidadAcuicolaId ?? 'unit-1',
      estanqueId: estanqueId,
      loteId: loteId,
      cantidadPecesMuertos: cantidadPecesMuertos,
      pesoPromedioGramos: pesoPromedioGramos,
      biomasaPerdidaKg: biomasaPerdidaKg ?? (cantidadPecesMuertos * pesoPromedioGramos / 1000.0),
      causaProbable: causaProbable,
      observaciones: observaciones,
      registradoPor: registradoPor,
      fecha: fecha ?? DateTime.now(),
      hora: hora,
      creadoEn: DateTime.now(),
    );
    mortalities.insert(0, m);
    return m;
  }
}

class FakeAuthNotifier extends StateNotifier<AuthState> implements AuthNotifier {
  FakeAuthNotifier(super.initial);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  late FakeWaterQualityRepository fakeWaterRepo;
  late FakeNutritionRepository fakeNutritionRepo;
  late FakePondsRepository fakePondsRepo;
  late AuthState testAuthState;

  final testPond1 = Pond(
    id: 'pond-1',
    empresaId: 'emp-1',
    unidadAcuicolaId: 'unit-1',
    nombre: 'EST - ESTANQUE 01 (GEOMEMBRANA PRINCIPAL DE ALTA DENSIDAD)',
    sigla: 'E-01-GEO',
    capacidadM3: 150.0,
    especieActual: 'Tilapia Roja',
    biomasaKg: 3500.0,
    creadoEn: DateTime(2026, 1, 1),
  );

  final testPond2 = Pond(
    id: 'pond-2',
    empresaId: 'emp-1',
    unidadAcuicolaId: 'unit-1',
    nombre: 'Estanque 02',
    sigla: 'E-02',
    capacidadM3: 100.0,
    especieActual: 'Cachama Negra',
    biomasaKg: 1800.0,
    creadoEn: DateTime(2026, 1, 1),
  );

  final testBatch1 = FishBatch(
    id: 'batch-1',
    empresaId: 'emp-1',
    unidadAcuicolaId: 'unit-1',
    estanqueId: 'pond-1',
    codigoLote: 'LOT-2026-01',
    especie: 'Tilapia Roja',
    cantidadInicialPeces: 10000,
    cantidadActualPeces: 9800,
    pesoInicialGramos: 5.0,
    pesoActualGramos: 350.0,
    biomasaInicialKg: 50.0,
    biomasaActualKg: 3430.0,
    fechaSiembra: DateTime(2026, 1, 1),
    creadoEn: DateTime(2026, 1, 1),
  );

  final testBatch2 = FishBatch(
    id: 'batch-2',
    empresaId: 'emp-1',
    unidadAcuicolaId: 'unit-1',
    estanqueId: 'pond-2',
    codigoLote: 'LOT-2026-02',
    especie: 'Cachama Negra',
    cantidadInicialPeces: 5000,
    cantidadActualPeces: 4900,
    pesoInicialGramos: 10.0,
    pesoActualGramos: 400.0,
    biomasaInicialKg: 50.0,
    biomasaActualKg: 1960.0,
    fechaSiembra: DateTime(2026, 1, 1),
    creadoEn: DateTime(2026, 1, 1),
  );

  final bioSampling1 = BiometriaRecord(
    id: 'bio-1',
    empresaId: 'emp-1',
    unitId: 'unit-1',
    estanqueId: 'pond-1',
    loteId: 'batch-1',
    fecha: DateTime(2026, 1, 31),
    hora: '08:30:00',
    pecesCapturados: 50,
    pesoTotalCapturaKg: 4.5,
    pesoPromedioG: 90.0,
    biomasaParcialKg: 882.0,
    longitudCm: 14.5,
    factorK: 1.65,
    observaciones: 'Excelente desarrollo inicial',
    creadoEn: DateTime(2026, 1, 31, 8, 30),
  );

  final bioSampling2 = BiometriaRecord(
    id: 'bio-2',
    empresaId: 'emp-1',
    unitId: 'unit-1',
    estanqueId: 'pond-1',
    loteId: 'batch-1',
    fecha: DateTime(2026, 2, 28),
    hora: '09:00:00',
    pecesCapturados: 45,
    pesoTotalCapturaKg: 15.75,
    pesoPromedioG: 350.0,
    biomasaParcialKg: 3430.0,
    longitudCm: 22.0,
    factorK: 1.72,
    observaciones: 'Lote homogéneo y activo',
    creadoEn: DateTime(2026, 2, 28, 9, 0),
  );

  final bioSamplingPond2 = BiometriaRecord(
    id: 'bio-3',
    empresaId: 'emp-1',
    unitId: 'unit-1',
    estanqueId: 'pond-2',
    loteId: 'batch-2',
    fecha: DateTime(2026, 2, 15),
    hora: '10:00:00',
    pecesCapturados: 30,
    pesoTotalCapturaKg: 12.0,
    pesoPromedioG: 400.0,
    biomasaParcialKg: 1960.0,
    longitudCm: 24.0,
    factorK: 1.58,
    observaciones: 'Muestreo intermedio',
    creadoEn: DateTime(2026, 2, 15, 10, 0),
  );

  final mortRecord1 = MortalityRecord(
    id: 'mort-1',
    empresaId: 'emp-1',
    unidadAcuicolaId: 'unit-1',
    estanqueId: 'pond-1',
    loteId: 'batch-1',
    cantidadPecesMuertos: 40,
    pesoPromedioGramos: 120.0,
    biomasaPerdidaKg: 4.8,
    causaProbable: 'Hipoxia / Bajo O2',
    observaciones: 'Fallo en aireador nocturno',
    fecha: DateTime(2026, 2, 5),
    hora: '06:15:00',
    creadoEn: DateTime(2026, 2, 5, 6, 15),
  );

  final mortRecord2 = MortalityRecord(
    id: 'mort-2',
    empresaId: 'emp-1',
    unidadAcuicolaId: 'unit-1',
    estanqueId: 'pond-2',
    loteId: 'batch-2',
    cantidadPecesMuertos: 15,
    pesoPromedioGramos: 300.0,
    biomasaPerdidaKg: 4.5,
    causaProbable: 'Manejo / Trauma',
    observaciones: 'Post muestreo',
    fecha: DateTime(2026, 2, 16),
    hora: '11:00:00',
    creadoEn: DateTime(2026, 2, 16, 11, 0),
  );

  final waterParam1 = WaterParameter(
    id: 'wp-1',
    empresaId: 'emp-1',
    unidadAcuicolaId: 'unit-1',
    estanqueId: 'pond-1',
    fecha: DateTime(2026, 2, 28, 7, 0),
    oxigenoMgL: 6.2,
    oxigenoPct: 88.0,
    ph: 7.3,
    temperaturaC: 28.5,
    amonioMgL: 0.12,
    nitritosMgL: 0.05,
    nitratosMgL: 10.0,
  );

  final feedingRec1 = FeedingRecord(
    id: 'feed-1',
    empresaId: 'emp-1',
    unidadAcuicolaId: 'unit-1',
    estanqueId: 'pond-1',
    loteId: 'batch-1',
    insumoId: 'ins-1',
    cantidadConsumidaKg: 45.0,
    costoCalculado: 180000.0,
    fecha: DateTime(2026, 2, 28),
    creadoEn: DateTime(2026, 2, 28),
  );

  final testUser = UserMember(
    id: 'user-1',
    empresaId: 'emp-1',
    unidadAcuicolaId: 'unit-1',
    nombre: 'Freddy Aquaculturist',
    email: 'freddy@fishbit.test',
    role: UserRole.admin,
    estado: MemberStatus.active,
    creadoEn: DateTime(2026, 1, 1),
  );

  const testCompany = Company(
    id: 'emp-1',
    nombreComercial: 'Piscícola San Jerónimo',
    razonSocial: 'Piscícola San Jerónimo S.A.S.',
    nit: '900.123.456-7',
    direccion: 'San Jerónimo, Antioquia',
  );

  final testUnit = AquacultureUnit(
    id: 'unit-1',
    empresaId: 'emp-1',
    nombre: 'Unidad Principal',
    sigla: 'PRIN',
    ubicacion: 'San Jerónimo',
    creadoEn: DateTime(2026, 1, 1),
  );

  setUp(() {
    fakeWaterRepo = FakeWaterQualityRepository()..params = [waterParam1];
    fakeNutritionRepo = FakeNutritionRepository()..records = [feedingRec1];
    fakePondsRepo = FakePondsRepository()
      ..ponds = [testPond1, testPond2]
      ..batches = [testBatch1, testBatch2]
      ..biometries = [bioSampling1, bioSampling2, bioSamplingPond2]
      ..mortalities = [mortRecord1, mortRecord2];

    testAuthState = AuthState(
      currentUser: testUser,
      currentCompany: testCompany,
      units: [testUnit],
      activeUnitId: 'unit-1',
    );
  });

  Widget buildTestWidget({Size screenSize = const Size(360, 800)}) {
    return ProviderScope(
      overrides: [
        authProvider.overrideWith((ref) => FakeAuthNotifier(testAuthState)),
        waterQualityRepositoryProvider.overrideWithValue(fakeWaterRepo),
        nutritionRepositoryProvider.overrideWithValue(fakeNutritionRepo),
        pondsRepositoryProvider.overrideWithValue(fakePondsRepo),
      ],
      child: MaterialApp(
        theme: ThemeData.dark(),
        home: MediaQuery(
          data: MediaQueryData(size: screenSize),
          child: const BitacoraScreen(),
        ),
      ),
    );
  }

  group('BitacoraScreen UI & State Integration Tests', () {
    testWidgets('Renders all 4 tabs and initial state correctly on mobile 360px viewport', (tester) async {
      tester.view.physicalSize = const Size(360, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      // Check header and tabs
      expect(find.text('Calidad de Agua'), findsOneWidget);
      expect(find.text('Alimentación'), findsOneWidget);
      expect(find.text('Biometrías y GDP'), findsOneWidget);
      expect(find.text('Bajas y Sanidad'), findsOneWidget);

      // Check filter bar displays "Todos los Estanques"
      expect(find.textContaining('Todos los Estanques'), findsOneWidget);

      // Tab 1 (Calidad de Agua) default view
      expect(find.text('OXÍGENO ÓPTIMO'), findsOneWidget);
      expect(find.text('PH RANGO'), findsOneWidget);
      expect(find.textContaining('O₂: 6.2 mg/L'), findsOneWidget);
    });

    testWidgets('Tab 3 (Biometrías y GDP) displays sampling history and chronological period GDP calculation', (tester) async {
      tester.view.physicalSize = const Size(1024, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(buildTestWidget(screenSize: const Size(1024, 900)));
      await tester.pumpAndSettle();

      // Tap Tab 3 using Key
      await tester.tap(find.byKey(const Key('tab_biometrias')));
      await tester.pumpAndSettle();

      // Summary KPIs
      expect(find.text('ÚLTIMO PESO PROM.'), findsOneWidget);
      expect(find.text('GDP DEL PERIODO'), findsOneWidget);
      expect(find.textContaining('HISTORIAL DE MUESTREOS BIOMÉTRICOS'), findsOneWidget);

      // Sampling cards
      expect(find.textContaining('90.0 g'), findsOneWidget);
      expect(find.textContaining('350.0 g'), findsAtLeastNWidgets(1));
      expect(find.textContaining('400.0 g'), findsAtLeastNWidgets(1));

      // Consecutive sampling GDP calculation check:
      // Sampling 2 (350g on Feb 28) vs Sampling 1 (90g on Jan 31):
      // Delta W = 260g over 28 days = 9.29 g/day
      expect(find.textContaining('+9.29 G/D'), findsOneWidget);
    });

    testWidgets('Tab 4 (Bajas y Sanidad) displays real mortality incidents and summary KPIs', (tester) async {
      tester.view.physicalSize = const Size(1024, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(buildTestWidget(screenSize: const Size(1024, 900)));
      await tester.pumpAndSettle();

      // Tap Tab 4 using Key
      await tester.tap(find.byKey(const Key('tab_bajas')));
      await tester.pumpAndSettle();

      // Summary KPIs
      expect(find.text('TOTAL BAJAS'), findsOneWidget);
      expect(find.text('SUPERVIVENCIA'), findsOneWidget);
      expect(find.text('55 peces'), findsOneWidget); // 40 + 15

      // Incident cards
      expect(find.text('40 peces'), findsAtLeastNWidgets(1));
      expect(find.text('15 peces'), findsAtLeastNWidgets(1));
      expect(find.textContaining('HIPOXIA'), findsAtLeastNWidgets(1));
      expect(find.textContaining('MANEJO'), findsAtLeastNWidgets(1));
    });

    testWidgets('Reactive Pond Filter filters all 4 tabs simultaneously and clears with Limpiar button', (tester) async {
      tester.view.physicalSize = const Size(1024, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(buildTestWidget(screenSize: const Size(1024, 900)));
      await tester.pumpAndSettle();

      // Open pond filter bottom sheet
      await tester.tap(find.textContaining('ESTANQUE DE CONSULTA'));
      await tester.pumpAndSettle();

      expect(find.text('Filtrar por Estanque'), findsOneWidget);
      expect(find.textContaining('E-01-GEO'), findsOneWidget);
      expect(find.textContaining('E-02'), findsOneWidget);

      // Select Pond 2 (Estanque 02)
      await tester.tap(find.textContaining('E-02'));
      await tester.pumpAndSettle();

      // Check header shows Estanque 02 and "Limpiar" button appears without overflow
      expect(find.textContaining('Estanque 02'), findsOneWidget);
      expect(find.text('Limpiar'), findsOneWidget);

      // Tab 1 (Calidad de Agua): should show empty state because Pond 2 has no water parameter records
      expect(find.text('No hay mediciones registradas para este estanque.'), findsOneWidget);

      // Tab 2 (Alimentación): should show empty state because Pond 2 has no feeding records
      await tester.tap(find.byKey(const Key('tab_alimentacion')));
      await tester.pumpAndSettle();
      expect(find.text('No hay registros de alimentación para este estanque.'), findsOneWidget);

      // Tab 3 (Biometrías): should only show Pond 2 sampling (400.0 g)
      await tester.tap(find.byKey(const Key('tab_biometrias')));
      await tester.pumpAndSettle();
      expect(find.textContaining('400.0 g'), findsAtLeastNWidgets(1));
      expect(find.textContaining('90.0 g'), findsNothing);

      // Tab 4 (Bajas): should only show Pond 2 mortality (15 peces)
      await tester.tap(find.byKey(const Key('tab_bajas')));
      await tester.pumpAndSettle();
      expect(find.text('15 peces'), findsAtLeastNWidgets(1));
      expect(find.text('40 peces'), findsNothing);

      // Now tap "Limpiar" to clear the filter
      await tester.tap(find.text('Limpiar'));
      await tester.pumpAndSettle();

      // Both mortality records should be visible again in Tab 4
      expect(find.text('40 peces'), findsAtLeastNWidgets(1));
      expect(find.text('15 peces'), findsAtLeastNWidgets(1));
      expect(find.textContaining('Todos los Estanques'), findsOneWidget);
    });

    testWidgets('360px viewport stress test with extremely long pond name does not trigger RenderFlex overflow', (tester) async {
      tester.view.physicalSize = const Size(360, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      // Open pond filter bottom sheet and select Pond 1 with long name
      await tester.tap(find.textContaining('ESTANQUE DE CONSULTA'));
      await tester.pumpAndSettle();

      await tester.tap(find.textContaining('E-01-GEO'));
      await tester.pumpAndSettle();

      // Verify no RenderFlex overflow exceptions occurred
      expect(tester.takeException(), isNull);
      expect(find.text('Limpiar'), findsOneWidget);
    });

    testWidgets('Web desktop layout (>768px) centers container correctly', (tester) async {
      tester.view.physicalSize = const Size(1200, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(buildTestWidget(screenSize: const Size(1200, 900)));
      await tester.pumpAndSettle();

      expect(find.byType(BitacoraScreen), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}
