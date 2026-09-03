import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fishbit_finance/modules/ponds_batches/presentation/providers/ponds_provider.dart';
import 'package:fishbit_finance/modules/ponds_batches/domain/repositories/ponds_repository.dart';
import 'package:fishbit_finance/modules/ponds_batches/domain/models/pond.dart';
import 'package:fishbit_finance/modules/ponds_batches/domain/models/fish_batch.dart';
import 'package:fishbit_finance/modules/ponds_batches/domain/models/biometria_record.dart';
import 'package:fishbit_finance/modules/ponds_batches/domain/models/mortality_record.dart';
import 'package:fishbit_finance/modules/ponds_batches/domain/models/transfer_record.dart';
import 'package:fishbit_finance/modules/auth_tenant/presentation/providers/auth_provider.dart';
import 'package:fishbit_finance/modules/auth_tenant/domain/models/user_member.dart';
import 'package:fishbit_finance/modules/auth_tenant/domain/models/company.dart';
import 'package:fishbit_finance/modules/finance_payroll/presentation/providers/finance_provider.dart';
import 'package:fishbit_finance/modules/finance_payroll/domain/repositories/finance_repository.dart';
import 'package:fishbit_finance/modules/finance_payroll/domain/models/payroll_config.dart';
import 'package:fishbit_finance/modules/finance_payroll/domain/models/payroll_record.dart';
import 'package:fishbit_finance/modules/finance_payroll/domain/models/jornal_record.dart';
import 'package:fishbit_finance/modules/finance_payroll/domain/models/energy_bill.dart';
import 'package:fishbit_finance/modules/finance_payroll/domain/models/maintenance_record.dart';
import 'package:fishbit_finance/modules/ica_compliance/presentation/providers/ica_compliance_provider.dart';
import 'package:fishbit_finance/modules/ica_compliance/domain/repositories/ica_compliance_repository.dart';
import 'package:fishbit_finance/modules/ica_compliance/domain/models/ica_personal_record.dart';
import 'package:fishbit_finance/modules/ica_compliance/domain/models/ica_vehiculo_record.dart';
import 'package:fishbit_finance/modules/ica_compliance/domain/models/ica_necropsia_record.dart';
import '../../helpers/test_auth_helper.dart';

// Mock throwing repository for Ponds Future.wait resilience
class FailingPondsRepository implements PondsRepository {
  final bool failPonds;
  final bool failBatches;
  final bool failBiometries;
  final bool failMortality;
  final bool failTransfers;

  FailingPondsRepository({
    this.failPonds = false,
    this.failBatches = false,
    this.failBiometries = false,
    this.failMortality = false,
    this.failTransfers = false,
  });

  @override
  Future<List<Pond>> fetchPondsByUnit(String empresaId, String unidadAcuicolaId) async {
    if (failPonds) throw Exception('Simulated Ponds Network Outage');
    return [
      Pond(
        id: 'pond_1',
        empresaId: empresaId,
        unidadAcuicolaId: unidadAcuicolaId,
        nombre: 'Estanque 1',
        sigla: 'E-01',
        capacidadM3: 500,
        biomasaKg: 1200,
        estado: PondStatus.active,
        creadoEn: DateTime.now(),
      ),
    ];
  }

  @override
  Future<List<FishBatch>> fetchBatchesByUnit(String empresaId, String unidadAcuicolaId) async {
    if (failBatches) throw Exception('Simulated Batches Network Outage');
    return [
      FishBatch(
        id: 'batch_1',
        empresaId: empresaId,
        unidadAcuicolaId: unidadAcuicolaId,
        estanqueId: 'pond_1',
        codigoLote: 'L-2026-01',
        especie: 'Tilapia Roja',
        cantidadInicialPeces: 5000,
        cantidadActualPeces: 4800,
        pesoInicialGramos: 5.0,
        pesoActualGramos: 250.0,
        biomasaActualKg: 1200.0,
        estado: BatchStatus.active,
        fechaSiembra: DateTime.now().subtract(const Duration(days: 90)),
        creadoEn: DateTime.now(),
      ),
    ];
  }

  @override
  Future<List<BiometriaRecord>> fetchBiometriesByUnit(
    String empresaId,
    String unidadAcuicolaId, {
    String? pondId,
    String? batchId,
  }) async {
    if (failBiometries) throw Exception('Simulated Biometries Outage');
    return [];
  }

  @override
  Future<List<MortalityRecord>> fetchMortalityByUnit(
    String empresaId,
    String unidadAcuicolaId, {
    String? pondId,
    String? batchId,
  }) async {
    if (failMortality) throw Exception('Simulated Mortality Outage');
    return [];
  }

  @override
  Future<List<TransferRecord>> fetchTransfersByUnit(
    String empresaId,
    String unidadAcuicolaId, {
    String? pondId,
    String? batchId,
  }) async {
    if (failTransfers) throw Exception('Simulated Transfers Outage');
    return [];
  }

  @override
  Future<Pond> createPond(Pond pond) async => pond;
  @override
  Future<FishBatch> createBatch(FishBatch batch) async => batch;
  @override
  Future<void> updatePond(Pond pond) async {}
  @override
  Future<void> updateBatch(FishBatch batch) async {}
  @override
  Future<void> deletePond(String pondId) async {}
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

// Mock failing Finance repository
class FailingFinanceRepository implements FinanceRepository {
  final bool shouldFail;
  FailingFinanceRepository({this.shouldFail = true});

  @override
  Future<PayrollConfig> fetchPayrollConfig(String empresaId) async {
    if (shouldFail) throw Exception('Finance DB Timeout');
    return const PayrollConfig();
  }

  @override
  Future<List<PayrollRecord>> fetchPayroll(String empresaId, String unidadAcuicolaId) async => [];
  @override
  Future<List<JornalRecord>> fetchJornales(String empresaId, String unidadAcuicolaId) async => [];
  @override
  Future<List<EnergyBill>> fetchEnergyBills(String empresaId, String unidadAcuicolaId) async => [];
  @override
  Future<List<MaintenanceRecord>> fetchMaintenances(String empresaId, String unidadAcuicolaId) async => [];
  @override
  Future<void> savePayrollConfig(String empresaId, PayrollConfig config) async {}
  @override
  Future<PayrollRecord> createPayrollRecord(PayrollRecord record) async => record;
  @override
  Future<void> deletePayrollRecord(String id) async {}
  @override
  Future<JornalRecord> createJornalRecord(JornalRecord record) async => record;
  @override
  Future<void> deleteJornalRecord(String id) async {}
  @override
  Future<EnergyBill> recordEnergyBill(EnergyBill bill) async => bill;
  @override
  Future<MaintenanceRecord> recordMaintenance(MaintenanceRecord record) async => record;
}

// Mock failing ICA repository
class FailingIcaRepository implements IcaComplianceRepository {
  final bool shouldFail;
  FailingIcaRepository({this.shouldFail = true});

  @override
  Future<List<IcaPersonalRecord>> getPersonalRecords({required String empresaId, required String unidadId}) async {
    if (shouldFail) throw Exception('ICA service unreachable');
    return [];
  }

  @override
  Future<List<IcaVehiculoRecord>> getVehiculoRecords({required String empresaId, required String unidadId}) async => [];
  @override
  Future<List<IcaNecropsiaRecord>> getNecropsiaRecords({required String empresaId, required String unidadId}) async => [];
  @override
  Future<bool> savePersonalRecord(IcaPersonalRecord record) async => true;
  @override
  Future<bool> saveVehiculoRecord(IcaVehiculoRecord record) async => true;
  @override
  Future<bool> saveNecropsiaRecord(IcaNecropsiaRecord record) async => true;
}

void main() {
  group('Empirical Challenger: Frontend Performance, Memory & Future.wait Resilience', () {
    test('PondsNotifier Future.wait handles single service failure gracefully without locking isLoading', () async {
      final container = ProviderContainer(
        overrides: [
          pondsRepositoryProvider.overrideWithValue(FailingPondsRepository(failBiometries: true)),
          authProvider.overrideWith((ref) => AuthNotifierMock(
            AuthState(
              currentUser: UserMember(
                id: 'u1',
                email: 'test@fishbit.com',
                nombre: 'Tester',
                role: UserRole.admin,
                empresaId: 'emp_1',
                unidadAcuicolaId: 'unit_1',
                creadoEn: DateTime.now(),
              ),
              currentCompany: const Company(
                id: 'emp_1',
                nombreComercial: 'FishBit',
                razonSocial: 'FishBit SAS',
                nit: '900123456-1',
              ),
              activeUnitId: 'unit_1',
            ),
          )),
        ],
      );

      final notifier = container.read(pondsProvider.notifier);
      await notifier.loadPondsAndBatches('unit_1');

      final state = container.read(pondsProvider);
      expect(state.isLoading, false, reason: 'Notifier must reset isLoading to false on Future.wait failure');
      expect(state.errorMessage, contains('Simulated Biometries Outage'));
    });

    test('FinanceNotifier Future.wait handles network failure gracefully without hanging', () async {
      final container = ProviderContainer(
        overrides: [
          financeRepositoryProvider.overrideWithValue(FailingFinanceRepository(shouldFail: true)),
          authProvider.overrideWith((ref) => AuthNotifierMock(
            AuthState(
              currentUser: UserMember(
                id: 'u1',
                email: 'test@fishbit.com',
                nombre: 'Tester',
                role: UserRole.admin,
                empresaId: 'emp_1',
                unidadAcuicolaId: 'unit_1',
                creadoEn: DateTime.now(),
              ),
              activeUnitId: 'unit_1',
            ),
          )),
        ],
      );

      final notifier = container.read(financeProvider.notifier);
      await notifier.loadFinanceData();

      final state = container.read(financeProvider);
      expect(state.isLoading, false);
      expect(state.errorMessage, contains('Finance DB Timeout'));
    });

    test('IcaComplianceNotifier Future.wait handles exception cleanly', () async {
      final container = ProviderContainer(
        overrides: [
          icaComplianceRepositoryProvider.overrideWithValue(FailingIcaRepository(shouldFail: true)),
          authProvider.overrideWith((ref) => AuthNotifierMock(
            AuthState(
              currentUser: UserMember(
                id: 'u1',
                email: 'test@fishbit.com',
                nombre: 'Tester',
                role: UserRole.admin,
                empresaId: 'emp_1',
                unidadAcuicolaId: 'unit_1',
                creadoEn: DateTime.now(),
              ),
              currentCompany: const Company(
                id: 'emp_1',
                nombreComercial: 'FishBit',
                razonSocial: 'FishBit SAS',
                nit: '900123456-1',
              ),
              activeUnitId: 'unit_1',
            ),
          )),
        ],
      );

      final notifier = container.read(icaComplianceProvider.notifier);
      await notifier.loadAllRecords();

      final state = container.read(icaComplianceProvider);
      expect(state.isLoading, false);
      expect(state.errorMessage, contains('ICA service unreachable'));
    });

    test('activeBatchesByPondProvider memoizes active batches by pond ID in O(N)', () {
      final container = ProviderContainer(
        overrides: [
          pondsRepositoryProvider.overrideWithValue(FailingPondsRepository()),
          authProvider.overrideWith((ref) => AuthNotifierMock(const AuthState())),
        ],
      );

      final groupedBatches = container.read(activeBatchesByPondProvider);
      expect(groupedBatches, isA<Map<String, List<FishBatch>>>());
    });

    test('Debounce timer correctly cancels previous timers on rapid successive inputs', () async {
      int queryExecutionCount = 0;
      String lastQueriedString = '';
      Timer? debounceTimer;

      void onSearchChanged(String text) {
        debounceTimer?.cancel();
        debounceTimer = Timer(const Duration(milliseconds: 50), () {
          queryExecutionCount++;
          lastQueriedString = text;
        });
      }

      // Rapidly simulate 10 keypresses within 20ms
      for (int i = 1; i <= 10; i++) {
        onSearchChanged('query_$i');
        await Future<void>.delayed(const Duration(milliseconds: 2));
      }

      // Wait for debounce timer (50ms) to fire
      await Future<void>.delayed(const Duration(milliseconds: 80));

      expect(queryExecutionCount, 1, reason: 'Debounce must execute exactly once for rapid keystrokes');
      expect(lastQueriedString, 'query_10', reason: 'Debounce must query the latest value');
    });
  });
}
