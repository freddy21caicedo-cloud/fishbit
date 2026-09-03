import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fishbit_finance/core/network/supabase_client_provider.dart';
import 'package:fishbit_finance/modules/auth_tenant/presentation/providers/auth_provider.dart';
import 'package:fishbit_finance/modules/equipment_capex/domain/models/equipment_asset.dart';
import 'package:fishbit_finance/modules/equipment_capex/domain/repositories/equipment_repository.dart';
import 'package:fishbit_finance/modules/equipment_capex/infrastructure/repositories/supabase_equipment_repository.dart';

final equipmentRepositoryProvider = Provider<EquipmentRepository>((ref) {
  final supabase = ref.watch(supabaseClientProvider);
  return SupabaseEquipmentRepository(supabase);
});

class EquipmentState {
  final bool isLoading;
  final List<EquipmentAsset> equipment;
  final String? errorMessage;

  const EquipmentState({
    this.isLoading = false,
    this.equipment = const [],
    this.errorMessage,
  });

  double get valorTotalActivos => equipment.fold(0.0, (sum, eq) => sum + eq.costoAdquisicion);
  double get depreciacionDiariaTotal => equipment.fold(0.0, (sum, eq) => sum + eq.depreciacionDiaria);

  EquipmentState copyWith({
    bool? isLoading,
    List<EquipmentAsset>? equipment,
    String? errorMessage,
  }) {
    return EquipmentState(
      isLoading: isLoading ?? this.isLoading,
      equipment: equipment ?? this.equipment,
      errorMessage: errorMessage,
    );
  }
}

class EquipmentNotifier extends StateNotifier<EquipmentState> {
  final EquipmentRepository _repository;
  final Ref _ref;

  EquipmentNotifier(this._repository, this._ref) : super(const EquipmentState(isLoading: true)) {
    loadEquipment();
  }

  Future<void> loadEquipment() async {
    final auth = _ref.read(authProvider);
    final user = auth.currentUser;
    final unitId = auth.activeUnitId;

    if (user == null || user.empresaId == null || unitId == null) {
      state = state.copyWith(isLoading: false);
      return;
    }

    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final list = await _repository.fetchEquipment(user.empresaId!, unitId);
      state = state.copyWith(isLoading: false, equipment: list);
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
    }
  }

  Future<void> addEquipment(EquipmentAsset eq) async {
    try {
      final created = await _repository.createEquipment(eq);
      state = state.copyWith(equipment: [...state.equipment, created]);
    } catch (e) {
      state = state.copyWith(errorMessage: e.toString());
    }
  }
}

final equipmentProvider = StateNotifierProvider<EquipmentNotifier, EquipmentState>((ref) {
  final repo = ref.watch(equipmentRepositoryProvider);
  return EquipmentNotifier(repo, ref);
});
