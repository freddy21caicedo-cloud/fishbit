import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fishbit_finance/core/network/supabase_client_provider.dart';
import 'package:fishbit_finance/modules/auth_tenant/presentation/providers/auth_provider.dart';
import 'package:fishbit_finance/modules/finance_payroll/domain/models/payroll_record.dart';
import 'package:fishbit_finance/modules/finance_payroll/domain/models/payroll_config.dart';
import 'package:fishbit_finance/modules/finance_payroll/domain/models/jornal_record.dart';
import 'package:fishbit_finance/modules/finance_payroll/domain/models/energy_bill.dart';
import 'package:fishbit_finance/modules/finance_payroll/domain/models/maintenance_record.dart';
import 'package:fishbit_finance/modules/finance_payroll/domain/repositories/finance_repository.dart';
import 'package:fishbit_finance/modules/finance_payroll/infrastructure/repositories/supabase_finance_repository.dart';

final financeRepositoryProvider = Provider<FinanceRepository>((ref) {
  final supabase = ref.watch(supabaseClientProvider);
  return SupabaseFinanceRepository(supabase);
});

class FinanceState {
  final bool isLoading;
  final PayrollConfig payrollConfig;
  final List<PayrollRecord> payrollRecords;
  final List<JornalRecord> jornales;
  final List<EnergyBill> energyBills;
  final List<MaintenanceRecord> maintenances;
  final String? errorMessage;

  const FinanceState({
    this.isLoading = false,
    this.payrollConfig = const PayrollConfig(),
    this.payrollRecords = const [],
    this.jornales = const [],
    this.energyBills = const [],
    this.maintenances = const [],
    this.errorMessage,
  });

  double get totalCostoNomina => payrollRecords.fold(0.0, (sum, p) => sum + p.costoTotalEmpresa);
  double get totalCostoJornales => jornales.fold(0.0, (sum, j) => sum + j.totalPagado);
  double get totalCostoManoObra => totalCostoNomina + totalCostoJornales;
  double get totalCostoEnergia => energyBills.fold(0.0, (sum, e) => sum + e.totalPagado);
  double get totalCostoMantenimiento => maintenances.fold(0.0, (sum, m) => sum + m.valor);
  double get totalOpex => totalCostoManoObra + totalCostoEnergia + totalCostoMantenimiento;

  FinanceState copyWith({
    bool? isLoading,
    PayrollConfig? payrollConfig,
    List<PayrollRecord>? payrollRecords,
    List<JornalRecord>? jornales,
    List<EnergyBill>? energyBills,
    List<MaintenanceRecord>? maintenances,
    String? errorMessage,
  }) {
    return FinanceState(
      isLoading: isLoading ?? this.isLoading,
      payrollConfig: payrollConfig ?? this.payrollConfig,
      payrollRecords: payrollRecords ?? this.payrollRecords,
      jornales: jornales ?? this.jornales,
      energyBills: energyBills ?? this.energyBills,
      maintenances: maintenances ?? this.maintenances,
      errorMessage: errorMessage,
    );
  }
}

class FinanceNotifier extends StateNotifier<FinanceState> {
  final FinanceRepository _repository;
  final Ref _ref;

  FinanceNotifier(this._repository, this._ref) : super(const FinanceState(isLoading: true)) {
    loadFinanceData();
    _ref.listen<AuthState>(authProvider, (prev, next) {
      if (prev?.activeUnitId != next.activeUnitId) {
        loadFinanceData();
      }
    });
  }

  Future<void> loadFinanceData() async {
    final auth = _ref.read(authProvider);
    final user = auth.currentUser;
    final unitId = auth.activeUnitId;

    if (user == null || user.empresaId == null || unitId == null) {
      state = state.copyWith(isLoading: false);
      return;
    }

    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final results = await Future.wait([
        _repository.fetchPayrollConfig(user.empresaId!),
        _repository.fetchPayroll(user.empresaId!, unitId),
        _repository.fetchJornales(user.empresaId!, unitId),
        _repository.fetchEnergyBills(user.empresaId!, unitId),
        _repository.fetchMaintenances(user.empresaId!, unitId),
      ]);

      state = state.copyWith(
        isLoading: false,
        payrollConfig: results[0] as PayrollConfig,
        payrollRecords: results[1] as List<PayrollRecord>,
        jornales: results[2] as List<JornalRecord>,
        energyBills: results[3] as List<EnergyBill>,
        maintenances: results[4] as List<MaintenanceRecord>,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
    }
  }

  Future<void> updatePayrollConfig(PayrollConfig newConfig) async {
    final auth = _ref.read(authProvider);
    final empresaId = auth.currentUser?.empresaId ?? 'c1000000-0000-0000-0000-000000000001';
    state = state.copyWith(payrollConfig: newConfig);
    try {
      await _repository.savePayrollConfig(empresaId, newConfig);
    } catch (e) {
      state = state.copyWith(errorMessage: e.toString());
    }
  }

  Future<void> addPayroll(PayrollRecord record) async {
    try {
      final created = await _repository.createPayrollRecord(record);
      state = state.copyWith(payrollRecords: [created, ...state.payrollRecords]);
    } catch (e) {
      state = state.copyWith(errorMessage: e.toString());
    }
  }

  Future<void> addPayrollRecord(PayrollRecord record) async => await addPayroll(record);

  Future<void> deletePayroll(String recordId) async {
    state = state.copyWith(
      payrollRecords: state.payrollRecords.where((r) => r.id != recordId).toList(),
    );
    try {
      await _repository.deletePayrollRecord(recordId);
    } catch (e) {
      state = state.copyWith(errorMessage: e.toString());
    }
  }

  Future<void> addJornal(JornalRecord record) async {
    try {
      final created = await _repository.createJornalRecord(record);
      state = state.copyWith(jornales: [created, ...state.jornales]);
    } catch (e) {
      state = state.copyWith(errorMessage: e.toString());
    }
  }

  Future<void> deleteJornal(String recordId) async {
    state = state.copyWith(
      jornales: state.jornales.where((j) => j.id != recordId).toList(),
    );
    try {
      await _repository.deleteJornalRecord(recordId);
    } catch (e) {
      state = state.copyWith(errorMessage: e.toString());
    }
  }


  Future<void> addEnergyBill(EnergyBill bill) async {
    try {
      final created = await _repository.recordEnergyBill(bill);
      state = state.copyWith(energyBills: [created, ...state.energyBills]);
    } catch (e) {
      state = state.copyWith(errorMessage: e.toString());
    }
  }

  Future<void> addMaintenance(MaintenanceRecord record) async {
    try {
      final created = await _repository.recordMaintenance(record);
      state = state.copyWith(maintenances: [created, ...state.maintenances]);
    } catch (e) {
      state = state.copyWith(errorMessage: e.toString());
    }
  }
}

final financeProvider = StateNotifierProvider<FinanceNotifier, FinanceState>((ref) {
  final repo = ref.watch(financeRepositoryProvider);
  return FinanceNotifier(repo, ref);
});

