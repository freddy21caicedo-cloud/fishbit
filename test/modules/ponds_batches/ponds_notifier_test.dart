import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:fishbit_finance/core/storage/local_storage_service.dart';
import 'package:fishbit_finance/modules/auth_tenant/domain/models/company.dart';
import 'package:fishbit_finance/modules/auth_tenant/domain/models/user_member.dart';
import 'package:fishbit_finance/modules/auth_tenant/domain/models/aquaculture_unit.dart';
import 'package:fishbit_finance/modules/auth_tenant/domain/repositories/auth_repository.dart';
import 'package:fishbit_finance/modules/auth_tenant/presentation/providers/auth_provider.dart';
import 'package:fishbit_finance/modules/ponds_batches/domain/models/pond.dart';
import 'package:fishbit_finance/modules/ponds_batches/domain/models/fish_batch.dart';
import 'package:fishbit_finance/modules/ponds_batches/domain/models/biometria_record.dart';
import 'package:fishbit_finance/modules/ponds_batches/domain/models/mortality_record.dart';
import 'package:fishbit_finance/modules/ponds_batches/domain/models/transfer_record.dart';
import 'package:fishbit_finance/modules/ponds_batches/domain/repositories/ponds_repository.dart';
import 'package:fishbit_finance/modules/ponds_batches/presentation/providers/ponds_provider.dart';

class MockPondsRepository implements PondsRepository {
  List<Pond> ponds = [];
  List<FishBatch> batches = [];
  List<BiometriaRecord> biometries = [];
  List<MortalityRecord> mortalities = [];
  bool shouldThrowOnRegister = false;
  int registerBiometryDelayMs = 0;
  int registerMortalityDelayMs = 0;

  @override
  Future<List<Pond>> fetchPondsByUnit(String empresaId, String unidadAcuicolaId) async {
    return List.from(ponds);
  }

  @override
  Future<List<FishBatch>> fetchBatchesByUnit(String empresaId, String unidadAcuicolaId) async {
    return List.from(batches);
  }

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
    if (registerBiometryDelayMs > 0) {
      await Future<void>.delayed(Duration(milliseconds: registerBiometryDelayMs));
    }
    if (shouldThrowOnRegister) {
      throw Exception('DB Connection Timeout on registerBiometry');
    }

    final record = BiometriaRecord(
      id: 'bio-${DateTime.now().microsecondsSinceEpoch}',
      empresaId: empresaId ?? 'emp-1',
      unitId: unidadAcuicolaId ?? 'unit-1',
      estanqueId: estanqueId,
      loteId: loteId,
      fecha: fecha ?? DateTime.now(),
      hora: hora ?? '08:00:00',
      pecesCapturados: cantidadPecesMuestreados ?? 35,
      pesoTotalCapturaKg: pesoTotalCapturaKg ?? 17.5,
      pesoPromedioG: nuevoPesoPromedioGramos,
      biomasaParcialKg: 2500.0,
      longitudCm: longitudPromedioCm,
      factorK: factorK,
      gdpGDia: gdpGDia,
      observaciones: observaciones,
      registradoPor: registradoPor,
      creadoEn: DateTime.now(),
    );

    biometries.insert(0, record);
    return record;
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
    if (registerMortalityDelayMs > 0) {
      await Future<void>.delayed(Duration(milliseconds: registerMortalityDelayMs));
    }
    if (shouldThrowOnRegister) {
      throw Exception('DB Connection Timeout on registerMortality');
    }

    final record = MortalityRecord(
      id: 'mor-${DateTime.now().microsecondsSinceEpoch}',
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
      hora: hora ?? '09:00:00',
      creadoEn: DateTime.now(),
    );

    mortalities.insert(0, record);
    return record;
  }

  @override
  Future<Pond> createPond(Pond pond) async {
    ponds.add(pond);
    return pond;
  }

  @override
  Future<void> updatePond(Pond pond) async {}

  @override
  Future<void> deletePond(String pondId) async {}

  @override
  Future<FishBatch> createBatch(FishBatch batch) async {
    batches.add(batch);
    return batch;
  }

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
  Future<List<TransferRecord>> fetchTransfersByUnit(
    String empresaId,
    String unidadAcuicolaId, {
    String? pondId,
    String? batchId,
  }) async => [];
}

class MockAuthRepository implements AuthRepository {
  @override
  Future<UserMember?> getCurrentSession() async => null;
  @override
  Future<UserMember> signInWithEmailPassword(String email, String password) async => throw UnimplementedError();
  @override
  Future<UserMember?> signInWithGoogle() async => null;
  @override
  Future<UserMember> setupCompanyForUser({
    required String userId,
    required String userEmail,
    required String userName,
    String? adminCedula,
    String? adminTelefono,
    required String companyNombre,
    required String companyNit,
    required String companyUbicacion,
    required String unitNombre,
    required String unitSigla,
    List<String>? especiesHabilitadas,
    String? primerEstanqueNombre,
    String? primerEstanqueTipo,
    double? primerEstanqueCapacidadM3,
  }) async => throw UnimplementedError();
  @override
  Future<UserMember> registerCompanyWithAdmin({required String adminNombres, required String adminApellidos, required String adminCedulaNit, required String adminContacto, required String adminEmail, required String adminPassword, required String companyNombre, required String companyUbicacion, required String companyNit, required String companyEmail, String? companyRegistroIca, String? companyRegistroAunap}) async => throw UnimplementedError();
  @override
  Future<void> sendPasswordResetEmail(String email) async {}
  @override
  Future<void> signOut() async {}
  @override
  Future<Company?> fetchCompany(String empresaId) async => null;
  @override
  Future<List<Company>> fetchUserCompanies(String userId) async => [];
  @override
  Future<void> updateCompany(Company company) async {}
  @override
  Future<List<AquacultureUnit>> fetchUnits(String empresaId) async => [];
  @override
  Future<AquacultureUnit> createUnit(String empresaId, String nombre, String sigla, String? ubicacion) async => throw UnimplementedError();
  @override
  Future<List<UserMember>> fetchTeamMembers(String empresaId) async => [];
  @override
  Future<UserMember> createTeamMember({required String empresaId, required String nombre, required String email, required String cedula, required String telefono, required UserRole role, String? unidadAcuicolaId, bool permisoGlobalEmpresa = false, double salarioBase = 0.0, String periodoPago = 'Quincenal', required String password}) async => throw UnimplementedError();
  @override
  Future<String> createMemberInvitation({required String empresaId, required String nombre, required String email, required UserRole role, String? unidadAcuicolaId, String? cedula}) async => throw UnimplementedError();
  @override
  Future<UserMember> registerWithInvitationToken(String token, String password) async => throw UnimplementedError();
  @override
  Future<UserMember> updateTeamMember(UserMember member) async => member;
  @override
  Future<void> updateMemberStatus(String memberId, MemberStatus newStatus) async {}
  @override
  Future<void> deleteMember(String memberId) async {}
}

class FakeAuthNotifier extends AuthNotifier {
  FakeAuthNotifier(AuthState initial, LocalStorageService storage) : super(MockAuthRepository(), storage) {
    state = initial;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('PondsNotifier Riverpod State & Concurrency Tests', () {
    late MockPondsRepository mockRepo;
    late ProviderContainer container;
    late FakeAuthNotifier fakeAuth;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final storage = LocalStorageService(prefs);
      mockRepo = MockPondsRepository();

      final dummyUser = UserMember(
        id: 'user-01',
        email: 'user@test.com',
        nombre: 'Aquaculture Tester',
        role: UserRole.admin,
        empresaId: 'emp-uuid-1',
        unidadAcuicolaId: 'unit-uuid-1',
        creadoEn: DateTime.now(),
      );

      const dummyCompany = Company(
        id: 'emp-uuid-1',
        nombreComercial: 'Empresa Acuícola Real',
        razonSocial: 'Empresa Acuícola Real S.A.S.',
        nit: '900.123.456-7',
      );

      fakeAuth = FakeAuthNotifier(
        AuthState(
          isLoading: false,
          currentUser: dummyUser,
          currentCompany: dummyCompany,
          activeUnitId: 'unit-uuid-1',
        ),
        storage,
      );

      container = ProviderContainer(
        overrides: [
          pondsRepositoryProvider.overrideWithValue(mockRepo),
          authProvider.overrideWith((ref) => fakeAuth),
        ],
      );
    });

    tearDown(() {
      container.dispose();
    });

    test('Initial load populates state with ponds, batches, biometries, and mortalities', () async {
      final now = DateTime.now();
      mockRepo.ponds = [
        Pond(
          id: 'p-1',
          empresaId: 'emp-uuid-1',
          unidadAcuicolaId: 'unit-uuid-1',
          nombre: 'Estanque 1',
          sigla: 'E-01',
          capacidadM3: 500,
          biomasaKg: 2500,
          costoAcumuladoBiologico: 10000000,
          estado: PondStatus.active,
          creadoEn: now,
        ),
      ];

      final notifier = container.read(pondsProvider.notifier);
      await notifier.loadPondsAndBatches();

      final state = container.read(pondsProvider);
      expect(state.isLoading, isFalse);
      expect(state.ponds.length, 1);
      expect(state.ponds.first.id, 'p-1');
      expect(state.errorMessage, isNull);
    });

    test('recordBiometry mutates state.biometries immediately without delay', () async {
      final notifier = container.read(pondsProvider.notifier);
      await notifier.loadPondsAndBatches();

      expect(container.read(pondsProvider).biometries.isEmpty, isTrue);

      final success = await notifier.recordBiometry(
        estanqueId: 'p-1',
        loteId: 'b-1',
        nuevoPesoPromedioGramos: 450.0,
        cantidadPecesMuestreados: 40,
        pesoTotalCapturaKg: 18.0,
        longitudPromedioCm: 25.0,
        factorK: 1.65,
        gdpGDia: 5.2,
        observaciones: 'Muestreo semanal óptimo',
      );

      expect(success, isTrue);
      final state = container.read(pondsProvider);
      expect(state.biometries.length, 1);
      expect(state.biometries.first.estanqueId, 'p-1');
      expect(state.biometries.first.loteId, 'b-1');
      expect(state.biometries.first.pesoPromedioG, 450.0);
      expect(state.biometries.first.factorK, 1.65);
      expect(state.biometries.first.gdpGDia, 5.2);
      expect(state.errorMessage, isNull);
    });

    test('recordMortality mutates state.mortalityRecords immediately without delay', () async {
      final notifier = container.read(pondsProvider.notifier);
      await notifier.loadPondsAndBatches();

      expect(container.read(pondsProvider).mortalityRecords.isEmpty, isTrue);

      final success = await notifier.recordMortality(
        estanqueId: 'p-1',
        loteId: 'b-1',
        cantidadPecesMuertos: 12,
        pesoPromedioGramos: 420.0,
        causaProbable: 'Falla aireador noche',
        observaciones: 'Reemplazo de fusible efectuado',
      );

      expect(success, isTrue);
      final state = container.read(pondsProvider);
      expect(state.mortalityRecords.length, 1);
      expect(state.mortalityRecords.first.estanqueId, 'p-1');
      expect(state.mortalityRecords.first.loteId, 'b-1');
      expect(state.mortalityRecords.first.cantidadPecesMuertos, 12);
      expect(state.mortalityRecords.first.pesoPromedioGramos, 420.0);
      expect(state.mortalityRecords.first.causaProbable, 'Falla aireador noche');
      expect(state.errorMessage, isNull);
    });

    test('Stress Test: Concurrent invocations of recordBiometry & recordMortality preserve all records without race conditions', () async {
      final notifier = container.read(pondsProvider.notifier);
      mockRepo.registerBiometryDelayMs = 20;
      mockRepo.registerMortalityDelayMs = 20;

      // Launch 5 biometries and 5 mortalities concurrently
      final biometryFutures = List.generate(5, (i) {
        return notifier.recordBiometry(
          estanqueId: 'p-1',
          loteId: 'b-1',
          nuevoPesoPromedioGramos: 100.0 + (i * 20),
          cantidadPecesMuestreados: 30 + i,
          observaciones: 'Muestreo concurrente #$i',
        );
      });

      final mortalityFutures = List.generate(5, (i) {
        return notifier.recordMortality(
          estanqueId: 'p-1',
          loteId: 'b-1',
          cantidadPecesMuertos: i + 1,
          pesoPromedioGramos: 200.0,
          causaProbable: 'Causa test #$i',
        );
      });

      final bioResults = await Future.wait(biometryFutures);
      final morResults = await Future.wait(mortalityFutures);

      expect(bioResults.every((r) => r == true), isTrue);
      expect(morResults.every((r) => r == true), isTrue);

      final state = container.read(pondsProvider);
      expect(state.biometries.length, 5);
      expect(state.mortalityRecords.length, 5);
    });

    test('Handles repository error gracefully: sets errorMessage and returns false without crash', () async {
      final notifier = container.read(pondsProvider.notifier);
      await notifier.loadPondsAndBatches();
      mockRepo.shouldThrowOnRegister = true;

      final bioResult = await notifier.recordBiometry(
        estanqueId: 'p-1',
        loteId: 'b-1',
        nuevoPesoPromedioGramos: 300.0,
      );

      expect(bioResult, isFalse);
      expect(container.read(pondsProvider).errorMessage, contains('DB Connection Timeout on registerBiometry'));

      final morResult = await notifier.recordMortality(
        estanqueId: 'p-1',
        loteId: 'b-1',
        cantidadPecesMuertos: 5,
        pesoPromedioGramos: 300.0,
        causaProbable: 'Test Error',
      );

      expect(morResult, isFalse);
      expect(container.read(pondsProvider).errorMessage, contains('DB Connection Timeout on registerMortality'));
    });
  });
}
