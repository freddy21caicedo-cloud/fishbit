import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fishbit_finance/core/events/app_event_bus.dart';
import 'package:fishbit_finance/core/network/supabase_client_provider.dart';
import 'package:fishbit_finance/modules/auth_tenant/presentation/providers/auth_provider.dart';
import 'package:fishbit_finance/modules/feeding_nutrition/domain/models/feeding_record.dart';
import 'package:fishbit_finance/modules/feeding_nutrition/domain/models/nutrition_table.dart';
import 'package:fishbit_finance/modules/feeding_nutrition/domain/repositories/nutrition_repository.dart';
import 'package:fishbit_finance/modules/feeding_nutrition/infrastructure/repositories/supabase_nutrition_repository.dart';
import 'package:fishbit_finance/modules/ponds_batches/presentation/providers/ponds_provider.dart';
import 'package:fishbit_finance/modules/warehouse_inventory/presentation/providers/warehouse_provider.dart';

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

  Future<bool> recordDailyFeeding({
    required String estanqueId,
    required String loteId,
    String? insumoId,
    required double kgConsumidos,
    required double costoUnitarioAlimento,
    DateTime? fecha,
  }) async {
    final auth = _ref.read(authProvider);
    final user = auth.currentUser;
    final unitId = auth.activeUnitId ?? user?.unidadAcuicolaId ?? user?.empresaId;
    final empresaId = auth.currentCompany?.id ?? user?.empresaId ?? unitId;

    if (empresaId == null || empresaId.isEmpty || unitId == null || unitId.isEmpty) {
      state = state.copyWith(errorMessage: 'No se encontró empresa o sede activa.');
      return false;
    }

    try {
      final rec = await _repository.recordFeeding(
        empresaId: empresaId,
        unidadAcuicolaId: unitId,
        estanqueId: estanqueId,
        loteId: loteId,
        insumoId: insumoId,
        kgConsumidos: kgConsumidos,
        costoUnitarioAlimento: costoUnitarioAlimento,
        fecha: fecha,
      );
      final updatedRecords = [rec, ...state.records]
        ..sort((a, b) => b.fecha.compareTo(a.fecha));
      state = state.copyWith(records: updatedRecords);
      if (!empresaId.startsWith('c1000000-')) {
        await _ref.read(warehouseProvider.notifier).loadWarehouseData();
        await _ref.read(pondsProvider.notifier).loadPondsAndBatches();
      }
      return true;
    } catch (e) {
      state = state.copyWith(errorMessage: e.toString());
      return false;
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
    DateTime? fecha,
  }) async {
    return recordDailyFeeding(
      estanqueId: estanqueId,
      loteId: loteId,
      insumoId: insumoId,
      kgConsumidos: kgConsumidos,
      costoUnitarioAlimento: costoUnitarioAlimento,
      fecha: fecha,
    );
  }

  Future<bool> updateDailyFeeding({
    required FeedingRecord oldRecord,
    required double newKg,
    required double costoUnitario,
    String? newInsumoId,
    DateTime? newFecha,
  }) async {
    try {
      final updatedModel = oldRecord.copyWith(
        insumoId: newInsumoId ?? oldRecord.insumoId,
        cantidadConsumidaKg: newKg,
        costoCalculado: newKg * costoUnitario,
        fecha: newFecha ?? oldRecord.fecha,
      );

      final saved = await _repository.updateFeeding(updatedModel);

      // En empresas reales, el RPC update_daily_feeding_with_stock ajusta el stock atómicamente en Postgres.
      // Solo ajustamos en memoria local cuando es la empresa demo.
      if (oldRecord.empresaId.startsWith('c1000000-')) {
        final warehouseNotifier = _ref.read(warehouseProvider.notifier);
        final effectiveNewInsumo = newInsumoId ?? oldRecord.insumoId;
        if (oldRecord.insumoId != null && effectiveNewInsumo != oldRecord.insumoId) {
          await warehouseNotifier.restoreStock(
            itemId: oldRecord.insumoId!,
            cantidadKg: oldRecord.cantidadConsumidaKg,
          );
          if (effectiveNewInsumo != null) {
            await warehouseNotifier.discountStock(
              itemId: effectiveNewInsumo,
              cantidadKg: newKg,
              motivo: 'Edición de alimentación',
            );
          }
        } else if (effectiveNewInsumo != null) {
          final delta = newKg - oldRecord.cantidadConsumidaKg;
          if (delta > 0) {
            await warehouseNotifier.discountStock(
              itemId: effectiveNewInsumo,
              cantidadKg: delta,
              motivo: 'Ajuste positivo en alimentación',
            );
          } else if (delta < 0) {
            await warehouseNotifier.restoreStock(
              itemId: effectiveNewInsumo,
              cantidadKg: delta.abs(),
            );
          }
        }
      } else {
        await _ref.read(warehouseProvider.notifier).loadWarehouseData();
      }

      final updatedList = state.records.map((r) => r.id == saved.id ? saved : r).toList()
        ..sort((a, b) => b.fecha.compareTo(a.fecha));
      state = state.copyWith(records: updatedList);
      await _ref.read(pondsProvider.notifier).loadPondsAndBatches();
      return true;
    } catch (e) {
      state = state.copyWith(errorMessage: e.toString());
      return false;
    }
  }

  Future<bool> deleteDailyFeeding(FeedingRecord record) async {
    final auth = _ref.read(authProvider);
    final empresaId = auth.currentCompany?.id ?? auth.currentUser?.empresaId ?? record.empresaId;
    if (empresaId.isEmpty) return false;
    try {
      await _repository.deleteFeeding(record.id, empresaId);
      // En empresas reales, el trigger AFTER DELETE en Supabase reintegra el stock atómicamente.
      if (empresaId.startsWith('c1000000-')) {
        if (record.insumoId != null && record.insumoId!.isNotEmpty) {
          await _ref.read(warehouseProvider.notifier).restoreStock(
                itemId: record.insumoId!,
                cantidadKg: record.cantidadConsumidaKg,
              );
        }
      } else {
        await _ref.read(warehouseProvider.notifier).loadWarehouseData();
      }
      final updatedList = state.records.where((r) => r.id != record.id).toList();
      state = state.copyWith(records: updatedList);
      await _ref.read(pondsProvider.notifier).loadPondsAndBatches();
      return true;
    } catch (e) {
      state = state.copyWith(errorMessage: e.toString());
      return false;
    }
  }
}

final nutritionProvider = StateNotifierProvider<NutritionNotifier, NutritionState>((ref) {
  final repo = ref.watch(nutritionRepositoryProvider);
  return NutritionNotifier(repo, ref);
});
