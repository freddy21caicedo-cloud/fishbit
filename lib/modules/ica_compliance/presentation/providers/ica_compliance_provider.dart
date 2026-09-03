import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fishbit_finance/core/network/supabase_client_provider.dart';
import 'package:fishbit_finance/core/reports/ica_official_reports_engine.dart';
import 'package:fishbit_finance/modules/auth_tenant/presentation/providers/auth_provider.dart';
import 'package:fishbit_finance/modules/ponds_batches/presentation/providers/ponds_provider.dart';
import 'package:fishbit_finance/modules/feeding_nutrition/presentation/providers/nutrition_provider.dart';
import 'package:fishbit_finance/modules/water_quality/presentation/providers/water_quality_provider.dart';
import 'package:fishbit_finance/modules/sales_harvest/presentation/providers/sales_provider.dart';
import 'package:fishbit_finance/modules/warehouse_inventory/presentation/providers/warehouse_provider.dart';
import 'package:fishbit_finance/modules/ica_compliance/domain/models/ica_personal_record.dart';
import 'package:fishbit_finance/modules/ica_compliance/domain/models/ica_vehiculo_record.dart';
import 'package:fishbit_finance/modules/ica_compliance/domain/models/ica_necropsia_record.dart';
import 'package:fishbit_finance/modules/ica_compliance/domain/repositories/ica_compliance_repository.dart';
import 'package:fishbit_finance/modules/ica_compliance/infrastructure/repositories/supabase_ica_compliance_repository.dart';

final icaComplianceRepositoryProvider = Provider<IcaComplianceRepository>((ref) {
  final supabase = ref.watch(supabaseClientProvider);
  return SupabaseIcaComplianceRepository(supabase);
});

/// Provider memoizado que instancia IcaOfficialReportsEngine solo cuando cambian los datos
final icaReportsEngineProvider = Provider.autoDispose<IcaOfficialReportsEngine>((ref) {
  final auth = ref.watch(authProvider);
  final user = auth.currentUser;
  final company = auth.currentCompany;

  final pondsState = ref.watch(pondsProvider);
  final nutritionState = ref.watch(nutritionProvider);
  final waterState = ref.watch(waterQualityProvider);
  final salesState = ref.watch(salesProvider);
  final warehouseState = ref.watch(warehouseProvider);
  final icaState = ref.watch(icaComplianceProvider);

  return IcaOfficialReportsEngine(
    companyName: company?.nombreComercial ?? company?.razonSocial ?? user?.nombre ?? 'Piscícola FishBit',
    nit: company?.nit ?? '901.445.882-1',
    unitName: 'Sede Principal',
    ponds: pondsState.ponds,
    batches: pondsState.batches,
    transfers: pondsState.transferRecords,
    mortalities: pondsState.mortalityRecords,
    feedings: nutritionState.records,
    waterParams: waterState.recentParameters,
    sales: salesState.sales,
    inventory: warehouseState.items,
    personalRecords: icaState.personalRecords,
    vehiculoRecords: icaState.vehiculoRecords,
    necropsiaRecords: icaState.necropsiaRecords,
  );
});

class IcaComplianceState {
  final List<IcaPersonalRecord> personalRecords;
  final List<IcaVehiculoRecord> vehiculoRecords;
  final List<IcaNecropsiaRecord> necropsiaRecords;
  final bool isLoading;
  final String? errorMessage;

  IcaComplianceState({
    this.personalRecords = const [],
    this.vehiculoRecords = const [],
    this.necropsiaRecords = const [],
    this.isLoading = false,
    this.errorMessage,
  });

  IcaComplianceState copyWith({
    List<IcaPersonalRecord>? personalRecords,
    List<IcaVehiculoRecord>? vehiculoRecords,
    List<IcaNecropsiaRecord>? necropsiaRecords,
    bool? isLoading,
    String? errorMessage,
  }) {
    return IcaComplianceState(
      personalRecords: personalRecords ?? this.personalRecords,
      vehiculoRecords: vehiculoRecords ?? this.vehiculoRecords,
      necropsiaRecords: necropsiaRecords ?? this.necropsiaRecords,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
    );
  }
}

class IcaComplianceNotifier extends StateNotifier<IcaComplianceState> {
  final IcaComplianceRepository _repository;
  final Ref _ref;

  IcaComplianceNotifier(this._repository, this._ref) : super(IcaComplianceState()) {
    loadAllRecords();
  }

  Future<void> loadAllRecords() async {
    final auth = _ref.read(authProvider);
    final empresaId = auth.currentCompany?.id ?? auth.currentUser?.empresaId;
    final unidadId = auth.activeUnitId ?? auth.currentUser?.unidadAcuicolaId ?? empresaId;

    if (empresaId == null || unidadId == null) return;

    state = state.copyWith(isLoading: true);
    try {
      final results = await Future.wait([
        _repository.getPersonalRecords(empresaId: empresaId, unidadId: unidadId),
        _repository.getVehiculoRecords(empresaId: empresaId, unidadId: unidadId),
        _repository.getNecropsiaRecords(empresaId: empresaId, unidadId: unidadId),
      ]);

      state = state.copyWith(
        personalRecords: results[0] as List<IcaPersonalRecord>,
        vehiculoRecords: results[1] as List<IcaVehiculoRecord>,
        necropsiaRecords: results[2] as List<IcaNecropsiaRecord>,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
    }
  }

  Future<bool> registerPersonal(IcaPersonalRecord record) async {
    final ok = await _repository.savePersonalRecord(record);
    if (ok) {
      state = state.copyWith(
        personalRecords: [record, ...state.personalRecords],
      );
    }
    return ok;
  }

  Future<bool> registerVehiculo(IcaVehiculoRecord record) async {
    final ok = await _repository.saveVehiculoRecord(record);
    if (ok) {
      state = state.copyWith(
        vehiculoRecords: [record, ...state.vehiculoRecords],
      );
    }
    return ok;
  }

  Future<bool> registerNecropsia(IcaNecropsiaRecord record) async {
    final ok = await _repository.saveNecropsiaRecord(record);
    if (ok) {
      state = state.copyWith(
        necropsiaRecords: [record, ...state.necropsiaRecords],
      );
    }
    return ok;
  }
}

final icaComplianceProvider = StateNotifierProvider<IcaComplianceNotifier, IcaComplianceState>((ref) {
  final repo = ref.watch(icaComplianceRepositoryProvider);
  return IcaComplianceNotifier(repo, ref);
});
