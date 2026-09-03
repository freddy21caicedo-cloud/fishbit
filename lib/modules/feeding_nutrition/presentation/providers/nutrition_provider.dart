import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fishbit_finance/core/events/app_event_bus.dart';
import 'package:fishbit_finance/core/network/supabase_client_provider.dart';
import 'package:fishbit_finance/modules/auth_tenant/presentation/providers/auth_provider.dart';
import 'package:fishbit_finance/modules/feeding_nutrition/domain/models/feeding_record.dart';
import 'package:fishbit_finance/modules/feeding_nutrition/domain/models/nutrition_table.dart';
import 'package:fishbit_finance/modules/feeding_nutrition/domain/repositories/nutrition_repository.dart';
import 'package:fishbit_finance/modules/feeding_nutrition/infrastructure/repositories/supabase_nutrition_repository.dart';

final nutritionRepositoryProvider = Provider<NutritionRepository>((ref) {
  final supabase = ref.watch(supabaseClientProvider);
  final eventBus = ref.watch(eventBusProvider);
  return SupabaseNutritionRepository(supabase, eventBus);
});

class NutritionState {
  final bool isLoading;
  final List<FeedingRecord> records;
  final List<NutritionTable> tables;
  final String? errorMessage;

  const NutritionState({
    this.isLoading = false,
    this.records = const [],
    this.tables = const [],
    this.errorMessage,
  });

  NutritionState copyWith({
    bool? isLoading,
    List<FeedingRecord>? records,
    List<NutritionTable>? tables,
    String? errorMessage,
  }) {
    return NutritionState(
      isLoading: isLoading ?? this.isLoading,
      records: records ?? this.records,
      tables: tables ?? this.tables,
      errorMessage: errorMessage,
    );
  }
}

class NutritionNotifier extends StateNotifier<NutritionState> {
  final NutritionRepository _repository;
  final Ref _ref;

  NutritionNotifier(this._repository, this._ref) : super(const NutritionState(isLoading: true)) {
    loadData();
    _ref.listen<AuthState>(authProvider, (prev, next) {
      if (prev?.currentUser?.id != next.currentUser?.id ||
          prev?.currentCompany?.id != next.currentCompany?.id ||
          prev?.activeUnitId != next.activeUnitId ||
          (prev?.currentUser == null && next.currentUser != null)) {
        loadData();
      }
    });
  }

  Future<void> loadData() async {
    final auth = _ref.read(authProvider);
    final user = auth.currentUser;
    final unitId = auth.activeUnitId ?? user?.unidadAcuicolaId ?? user?.empresaId;
    final empresaId = auth.currentCompany?.id ?? user?.empresaId ?? unitId;

    if (empresaId == null || empresaId.isEmpty) {
      state = state.copyWith(isLoading: false);
      return;
    }

    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final records = await _repository.fetchFeedingRecords(empresaId, unitId ?? empresaId);
      final tables = await _repository.fetchNutritionTables(empresaId);
      state = state.copyWith(isLoading: false, records: records, tables: tables);
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
    }
  }

  Future<void> recordDailyFeeding({
    required String estanqueId,
    required String loteId,
    String? insumoId,
    required double kgConsumidos,
    required double costoUnitarioAlimento,
  }) async {
    final auth = _ref.read(authProvider);
    final user = auth.currentUser;
    final unitId = auth.activeUnitId;

    if (user == null || user.empresaId == null || unitId == null) return;

    try {
      final rec = await _repository.recordFeeding(
        empresaId: user.empresaId!,
        unidadAcuicolaId: unitId,
        estanqueId: estanqueId,
        loteId: loteId,
        insumoId: insumoId,
        kgConsumidos: kgConsumidos,
        costoUnitarioAlimento: costoUnitarioAlimento,
      );
      state = state.copyWith(records: [rec, ...state.records]);
    } catch (e) {
      state = state.copyWith(errorMessage: e.toString());
    }
  }

  Future<bool> recordFeeding({
    required String empresaId,
    required String unidadAcuicolaId,
    required String estanqueId,
    required String loteId,
    String? insumoId,
    required double kgConsumidos,
    required double costoUnitarioAlimento,
  }) async {
    await recordDailyFeeding(
      estanqueId: estanqueId,
      loteId: loteId,
      insumoId: insumoId,
      kgConsumidos: kgConsumidos,
      costoUnitarioAlimento: costoUnitarioAlimento,
    );
    return true;
  }
}

final nutritionProvider = StateNotifierProvider<NutritionNotifier, NutritionState>((ref) {
  final repo = ref.watch(nutritionRepositoryProvider);
  return NutritionNotifier(repo, ref);
});
