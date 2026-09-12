import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fishbit_finance/core/network/supabase_client_provider.dart';
import 'package:fishbit_finance/core/events/app_event_bus.dart';
import 'package:fishbit_finance/modules/auth_tenant/presentation/providers/auth_provider.dart';
import 'package:fishbit_finance/modules/ponds_batches/domain/models/pond.dart';
import 'package:fishbit_finance/modules/ponds_batches/domain/models/fish_batch.dart';
import 'package:fishbit_finance/modules/ponds_batches/domain/models/biometria_record.dart';
import 'package:fishbit_finance/modules/ponds_batches/domain/models/mortality_record.dart';
import 'package:fishbit_finance/modules/ponds_batches/domain/models/transfer_record.dart';
import 'package:fishbit_finance/modules/ponds_batches/domain/repositories/ponds_repository.dart';
import 'package:fishbit_finance/modules/ponds_batches/infrastructure/repositories/supabase_ponds_repository.dart';

final pondsRepositoryProvider = Provider<PondsRepository>((ref) {
  final supabase = ref.watch(supabaseClientProvider);
  return SupabasePondsRepository(supabase);
});

class PondsState {
  final bool isLoading;
  final List<Pond> ponds;
  final List<FishBatch> batches;
  final List<BiometriaRecord> biometries;
  final List<MortalityRecord> mortalityRecords;
  final List<TransferRecord> transferRecords;
  final String? errorMessage;

  const PondsState({
    this.isLoading = false,
    this.ponds = const [],
    this.batches = const [],
    this.biometries = const [],
    this.mortalityRecords = const [],
    this.transferRecords = const [],
    this.errorMessage,
  });

  double get biomasaTotalKg => ponds.fold(0.0, (sum, p) => sum + p.biomasaKg);
  double get costoTotalEnAgua => ponds.fold(0.0, (sum, p) => sum + p.costoAcumuladoBiologico);
  int get estanquesActivosCount => ponds.where((p) => p.estado == PondStatus.active).length;

  PondsState copyWith({
    bool? isLoading,
    List<Pond>? ponds,
    List<FishBatch>? batches,
    List<BiometriaRecord>? biometries,
    List<MortalityRecord>? mortalityRecords,
    List<TransferRecord>? transferRecords,
    String? errorMessage,
  }) {
    return PondsState(
      isLoading: isLoading ?? this.isLoading,
      ponds: ponds ?? this.ponds,
      batches: batches ?? this.batches,
      biometries: biometries ?? this.biometries,
      mortalityRecords: mortalityRecords ?? this.mortalityRecords,
      transferRecords: transferRecords ?? this.transferRecords,
      errorMessage: errorMessage,
    );
  }
}

class PondsNotifier extends StateNotifier<PondsState> {
  final PondsRepository _repository;
  final Ref _ref;
  StreamSubscription<dynamic>? _feedingSub;
  StreamSubscription<dynamic>? _harvestSub;

  PondsNotifier(this._repository, this._ref) : super(const PondsState(isLoading: true)) {
    loadPondsAndBatches();
    _ref.listen<AuthState>(authProvider, (prev, next) {
      if (prev?.currentUser?.id != next.currentUser?.id ||
          prev?.currentCompany?.id != next.currentCompany?.id ||
          prev?.activeUnitId != next.activeUnitId ||
          (prev?.currentUser == null && next.currentUser != null)) {
        loadPondsAndBatches();
      }
    });

    // Suscripción al EventBus para cerrar la cadena de costos (Precision Aquaculture)
    final eventBus = _ref.read(eventBusProvider);
    _feedingSub = eventBus.on<DailyFeedingRecordedEvent>().listen((event) {
      _handleDailyFeedingRecorded(event);
    });
    _harvestSub = eventBus.on<HarvestSaleRecordedEvent>().listen((event) {
      _handleHarvestSaleRecorded(event);
    });
  }

  @override
  void dispose() {
    _feedingSub?.cancel();
    _harvestSub?.cancel();
    super.dispose();
  }

  void _handleDailyFeedingRecorded(DailyFeedingRecordedEvent event) {
    final bIndex = state.batches.indexWhere((b) => b.id == event.loteId);
    if (bIndex != -1) {
      final oldBatch = state.batches[bIndex];
      final updatedBatch = oldBatch.copyWith(
        alimentoAcumuladoKg: oldBatch.alimentoAcumuladoKg + event.kgConsumidos,
        costoAcumuladoInsumos: oldBatch.costoAcumuladoInsumos + event.costoTotal,
      );

      final updatedBatches = List<FishBatch>.from(state.batches);
      updatedBatches[bIndex] = updatedBatch;

      // Actualizar también costo acumulado biológico en el estanque
      final updatedPonds = state.ponds.map((p) {
        if (p.id == event.estanqueId) {
          return p.copyWith(
            costoAcumuladoBiologico: p.costoAcumuladoBiologico + event.costoTotal,
          );
        }
        return p;
      }).toList();

      state = state.copyWith(batches: updatedBatches, ponds: updatedPonds);

      // Persistir actualización en base de datos
      _repository.updateBatch(updatedBatch);
    }
  }

  void _handleHarvestSaleRecorded(HarvestSaleRecordedEvent event) {
    final bIndex = state.batches.indexWhere((b) => b.id == event.loteId);
    if (bIndex != -1) {
      final oldBatch = state.batches[bIndex];
      final remanenteBiomasa = (oldBatch.biomasaActualKg - event.biomasaVendidaKg).clamp(0.0, double.infinity);
      final isTotalHarvest = remanenteBiomasa <= 5.0; // margen técnico de cierre

      final updatedBatch = oldBatch.copyWith(
        biomasaActualKg: remanenteBiomasa,
        estado: isTotalHarvest ? BatchStatus.harvested : oldBatch.estado,
      );

      final updatedBatches = List<FishBatch>.from(state.batches);
      updatedBatches[bIndex] = updatedBatch;

      final updatedPonds = state.ponds.map((p) {
        if (p.id == oldBatch.estanqueId) {
          return p.copyWith(
            biomasaKg: remanenteBiomasa,
            estado: isTotalHarvest ? PondStatus.available : p.estado,
            especieActual: isTotalHarvest ? '' : p.especieActual,
            costoAcumuladoBiologico: isTotalHarvest ? 0.0 : (p.costoAcumuladoBiologico - event.cogs).clamp(0.0, double.infinity),
          );
        }
        return p;
      }).toList();

      state = state.copyWith(batches: updatedBatches, ponds: updatedPonds);
      _repository.updateBatch(updatedBatch);
    }
  }

  Future<void> loadData([String? unitId]) async {
    await loadPondsAndBatches(unitId);
  }

  Future<void> loadPondsAndBatches([String? overrideUnitId]) async {
    final auth = _ref.read(authProvider);
    final user = auth.currentUser;
    final unitId = overrideUnitId ?? auth.activeUnitId ?? user?.unidadAcuicolaId ?? user?.empresaId;
    final empresaId = auth.currentCompany?.id ?? user?.empresaId ?? unitId;

    if (empresaId == null || empresaId.isEmpty) {
      state = state.copyWith(isLoading: false);
      return;
    }

    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final finalUnitId = unitId ?? empresaId;
      final results = await Future.wait([
        _repository.fetchPondsByUnit(empresaId, finalUnitId),
        _repository.fetchBatchesByUnit(empresaId, finalUnitId),
        _repository.fetchBiometriesByUnit(empresaId, finalUnitId),
        _repository.fetchMortalityByUnit(empresaId, finalUnitId),
        _repository.fetchTransfersByUnit(empresaId, finalUnitId),
      ]);

      final ponds = results[0] as List<Pond>;
      final batches = results[1] as List<FishBatch>;
      final biometries = results[2] as List<BiometriaRecord>;
      final mortality = results[3] as List<MortalityRecord>;
      final transfers = results[4] as List<TransferRecord>;

      state = state.copyWith(
        isLoading: false,
        ponds: ponds,
        batches: batches,
        biometries: biometries,
        mortalityRecords: mortality,
        transferRecords: transfers,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
    }
  }

  Future<void> addPond(Pond pond) async {
    try {
      final created = await _repository.createPond(pond);
      state = state.copyWith(ponds: [...state.ponds, created]);
    } catch (e) {
      state = state.copyWith(errorMessage: e.toString());
      rethrow;
    }
  }

  Future<void> addBatch(FishBatch batch) async {
    try {
      await _repository.createBatch(batch);
      await loadPondsAndBatches();
    } catch (e) {
      state = state.copyWith(errorMessage: e.toString());
    }
  }

  Future<bool> plantBatch(FishBatch batch) async {
    await addBatch(batch);
    return true;
  }

  Future<void> executeTransferSplit({
    required String batchOrigenId,
    required String estanqueOrigenId,
    required String estanqueDestinoId,
    required int pecesTrasladados,
    required double biomasaTrasladadaKg,
    required bool esDesdoble,
    required String nuevoCodigoLote,
    String? registradoPor,
  }) async {
    try {
      final auth = _ref.read(authProvider);
      final userName = registradoPor ?? auth.currentUser?.nombre;
      await _repository.transferOrSplitBatch(
        batchOrigenId: batchOrigenId,
        estanqueOrigenId: estanqueOrigenId,
        estanqueDestinoId: estanqueDestinoId,
        pecesTrasladados: pecesTrasladados,
        biomasaTrasladadaKg: biomasaTrasladadaKg,
        esDesdoble: esDesdoble,
        nuevoCodigoLote: nuevoCodigoLote,
        registradoPor: userName,
      );
      await loadPondsAndBatches();
    } catch (e) {
      state = state.copyWith(errorMessage: e.toString());
    }
  }

  Future<bool> recordMortality({
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
    final auth = _ref.read(authProvider);
    final user = auth.currentUser;
    final unitId = auth.activeUnitId ?? user?.unidadAcuicolaId ?? user?.empresaId;
    final empresaId = auth.currentCompany?.id ?? user?.empresaId ?? unitId;

    try {
      final savedRecord = await _repository.registerMortality(
        empresaId: empresaId,
        unidadAcuicolaId: unitId,
        estanqueId: estanqueId,
        loteId: loteId,
        cantidadPecesMuertos: cantidadPecesMuertos,
        pesoPromedioGramos: pesoPromedioGramos,
        causaProbable: causaProbable,
        biomasaPerdidaKg: biomasaPerdidaKg,
        observaciones: observaciones,
        registradoPor: registradoPor ?? user?.nombre,
        fecha: fecha,
        hora: hora,
      );

      // Prepend to state immediately for responsive UI
      state = state.copyWith(
        mortalityRecords: [savedRecord, ...state.mortalityRecords],
      );

      // Refresh ponds and batches to update population & biomass metrics
      await loadPondsAndBatches();
      return true;
    } catch (e) {
      state = state.copyWith(errorMessage: e.toString());
      return false;
    }
  }

  Future<bool> recordBiometry({
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
    final auth = _ref.read(authProvider);
    final user = auth.currentUser;
    final unitId = auth.activeUnitId ?? user?.unidadAcuicolaId ?? user?.empresaId;
    final empresaId = auth.currentCompany?.id ?? user?.empresaId ?? unitId;

    try {
      final savedRecord = await _repository.registerBiometry(
        empresaId: empresaId,
        unidadAcuicolaId: unitId,
        estanqueId: estanqueId,
        loteId: loteId,
        nuevoPesoPromedioGramos: nuevoPesoPromedioGramos,
        cantidadPecesMuestreados: cantidadPecesMuestreados,
        pesoTotalCapturaKg: pesoTotalCapturaKg,
        longitudPromedioCm: longitudPromedioCm,
        factorK: factorK,
        gdpGDia: gdpGDia,
        observaciones: observaciones,
        registradoPor: registradoPor ?? user?.nombre,
        fecha: fecha,
        hora: hora,
      );

      // Prepend to state immediately for responsive UI
      state = state.copyWith(
        biometries: [savedRecord, ...state.biometries],
      );

      // Refresh ponds and batches to update weight & biomass metrics
      await loadPondsAndBatches();
      return true;
    } catch (e) {
      state = state.copyWith(errorMessage: e.toString());
      return false;
    }
  }
}

final pondsProvider = StateNotifierProvider<PondsNotifier, PondsState>((ref) {
  final repo = ref.watch(pondsRepositoryProvider);
  return PondsNotifier(repo, ref);
});

/// Memoized selector that groups active batches by pond ID to avoid redundant O(N*M) lookups
final activeBatchesByPondProvider = Provider.autoDispose<Map<String, List<FishBatch>>>((ref) {
  final batches = ref.watch(pondsProvider.select((s) => s.batches));
  final map = <String, List<FishBatch>>{};
  for (final b in batches) {
    if (b.estado == BatchStatus.active) {
      map.putIfAbsent(b.estanqueId, () => []).add(b);
    }
  }
  return map;
});

