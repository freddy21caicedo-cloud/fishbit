import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fishbit_finance/core/network/supabase_client_provider.dart';
import 'package:fishbit_finance/modules/auth_tenant/presentation/providers/auth_provider.dart';
import 'package:fishbit_finance/modules/water_quality/domain/models/water_parameter.dart';
import 'package:fishbit_finance/modules/water_quality/domain/repositories/water_quality_repository.dart';
import 'package:fishbit_finance/modules/water_quality/infrastructure/repositories/supabase_water_quality_repository.dart';

final waterQualityRepositoryProvider = Provider<WaterQualityRepository>((ref) {
  final supabase = ref.watch(supabaseClientProvider);
  return SupabaseWaterQualityRepository(supabase);
});

class WaterQualityState {
  final bool isLoading;
  final List<WaterParameter> recentParameters;
  final String? errorMessage;

  const WaterQualityState({
    this.isLoading = false,
    this.recentParameters = const [],
    this.errorMessage,
  });

  WaterQualityState copyWith({
    bool? isLoading,
    List<WaterParameter>? recentParameters,
    String? errorMessage,
  }) {
    return WaterQualityState(
      isLoading: isLoading ?? this.isLoading,
      recentParameters: recentParameters ?? this.recentParameters,
      errorMessage: errorMessage,
    );
  }
}

class WaterQualityNotifier extends StateNotifier<WaterQualityState> {
  final WaterQualityRepository _repository;
  final Ref _ref;

  WaterQualityNotifier(this._repository, this._ref) : super(const WaterQualityState(isLoading: true)) {
    loadParameters();
    _ref.listen<AuthState>(authProvider, (prev, next) {
      if (prev?.currentUser?.id != next.currentUser?.id ||
          prev?.currentCompany?.id != next.currentCompany?.id ||
          prev?.activeUnitId != next.activeUnitId ||
          (prev?.currentUser == null && next.currentUser != null)) {
        loadParameters();
      }
    });
  }

  Future<void> loadParameters() async {
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
      final params = await _repository.fetchRecentParametersByUnit(empresaId, unitId ?? empresaId);
      state = state.copyWith(isLoading: false, recentParameters: params);
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
    }
  }

  Future<void> addParameter(WaterParameter param) async {
    try {
      final saved = await _repository.recordParameters(param);
      state = state.copyWith(recentParameters: [saved, ...state.recentParameters]);
    } catch (e) {
      state = state.copyWith(errorMessage: e.toString());
    }
  }

  Future<bool> recordWaterQuality(WaterParameter param) async {
    await addParameter(param);
    return true;
  }
}

final waterQualityProvider = StateNotifierProvider<WaterQualityNotifier, WaterQualityState>((ref) {
  final repo = ref.watch(waterQualityRepositoryProvider);
  return WaterQualityNotifier(repo, ref);
});
