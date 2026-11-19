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
  StreamSubscription<dynamic>? _biometrySub;
  StreamSubscription<dynamic>? _mortalitySub;

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
    _biometrySub = eventBus.on<BiometryRecordedEvent>().listen((event) {
      _handleBiometryRecorded(event);
    });
    _mortalitySub = eventBus.on<MortalityRecordedEvent>().listen((event) {
      _handleMortalityRecorded(event);
    });
  }

  @override
  void dispose() {
    _feedingSub?.cancel();
    _harvestSub?.cancel();
    _biometrySub?.cancel();
    _mortalitySub?.cancel();
    super.dispose();
  }

  void _handleBiometryRecorded(BiometryRecordedEvent event) {
    final bIndex = state.batches.indexWhere((b) => b.id == event.loteId);
    if (bIndex != -1) {
      final oldBatch = state.batches[bIndex];
      final newBio = event.biomasaCalculadaKg ?? ((oldBatch.cantidadActualPeces * event.pesoPromedioGramos) / 1000.0);
      final updatedBatch = oldBatch.copyWith(
        pesoActualGramos: event.pesoPromedioGramos,
        biomasaActualKg: newBio,
      );

      final updatedBatches = List<FishBatch>.from(state.batches);
      updatedBatches[bIndex] = updatedBatch;

      final updatedPonds = state.ponds.map((p) {
        if (p.id == event.estanqueId) {
          final pondBatches = updatedBatches.where((b) => b.estanqueId == event.estanqueId);
          final pondBio = pondBatches.fold(0.0, (sum, b) => sum + b.biomasaActualKg);
          return p.copyWith(biomasaKg: pondBio);
        }
        return p;
      }).toList();

      state = state.copyWith(batches: updatedBatches, ponds: updatedPonds);
    }
  }

  void _handleMortalityRecorded(MortalityRecordedEvent event) {
    final bIndex = state.batches.indexWhere((b) => b.id == event.loteId);
    if (bIndex != -1) {
      final oldBatch = state.batches[bIndex];
      final newCount = (oldBatch.cantidadActualPeces - event.cantidadPecesMuertos).clamp(0, 9999999);
      final newBio = (newCount * oldBatch.pesoActualGramos) / 1000.0;
      final updatedBatch = oldBatch.copyWith(
        cantidadActualPeces: newCount,
        biomasaActualKg: newBio,
      );

      final updatedBatches = List<FishBatch>.from(state.batches);
      updatedBatches[bIndex] = updatedBatch;

      final updatedPonds = state.ponds.map((p) {
        if (p.id == event.estanqueId) {
          final pondBatches = updatedBatches.where((b) => b.estanqueId == event.estanqueId);
          final pondBio = pondBatches.fold(0.0, (sum, b) => sum + b.biomasaActualKg);
          return p.copyWith(biomasaKg: pondBio);
        }
        return p;
      }).toList();

      state = state.copyWith(batches: updatedBatches, ponds: updatedPonds);
    }
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

      // Deducción exacta o proporcional de peces para prevenir peces fantasma
      final int pecesVendidos = event.pecesVendidos > 0
          ? event.pecesVendidos
          : (oldBatch.biomasaActualKg > 0
              ? (oldBatch.cantidadActualPeces * (event.biomasaVendidaKg / oldBatch.biomasaActualKg)).round()
              : 0);
      final int remanentePeces = (oldBatch.cantidadActualPeces - pecesVendidos).clamp(0, oldBatch.cantidadActualPeces);
      final isTotalHarvest = remanenteBiomasa <= 5.0 || remanentePeces <= 0;

      final updatedBatch = oldBatch.copyWith(
        biomasaActualKg: isTotalHarvest ? 0.0 : remanenteBiomasa,
        cantidadActualPeces: isTotalHarvest ? 0 : remanentePeces,
        estado: isTotalHarvest ? BatchStatus.harvested : oldBatch.estado,
      );

      final updatedBatches = List<FishBatch>.from(state.batches);
      updatedBatches[bIndex] = updatedBatch;

      // Soporte de policultivo: calcular la biomasa remanente total del estanque
      // sumando todos los lotes que permanezcan ACTIVOS en dicho estanque
      final activeBatchesInPond = updatedBatches.where(
        (b) => b.estanqueId == oldBatch.estanqueId && b.estado == BatchStatus.active,
      ).toList();

      final totalBiomasaEstanque = activeBatchesInPond.fold<double>(
        0.0, (acc, b) => acc + b.biomasaActualKg,
      );
      final bool pondHasActiveBatches = activeBatchesInPond.isNotEmpty;

      Pond? targetPondUpdated;
      final updatedPonds = state.ponds.map((p) {
        if (p.id == oldBatch.estanqueId) {
          final up = p.copyWith(
            biomasaKg: totalBiomasaEstanque,
            estado: pondHasActiveBatches ? PondStatus.active : PondStatus.available,
            especieActual: pondHasActiveBatches ? p.especieActual : '',
            costoAcumuladoBiologico: pondHasActiveBatches
                ? (p.costoAcumuladoBiologico - event.cogs).clamp(0.0, double.infinity)
                : 0.0,
          );
          targetPondUpdated = up;
          return up;
        }
        return p;
      }).toList();

      state = state.copyWith(batches: updatedBatches, ponds: updatedPonds);

      // Persistir en base de datos
      _repository.updateBatch(updatedBatch);
      if (targetPondUpdated != null) {
        _repository.updatePond(targetPondUpdated!);
      }
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

  Future<void> updatePond(Pond pond) async {
    try {
      await _repository.updatePond(pond);
      final updatedPonds = state.ponds.map((p) => p.id == pond.id ? pond : p).toList();
      state = state.copyWith(ponds: updatedPonds);
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
      rethrow;
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
    double? pesoPromedioGramos,
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
        pesoPromedioGramos: pesoPromedioGramos,
        esDesdoble: esDesdoble,
        nuevoCodigoLote: nuevoCodigoLote,
        registradoPor: userName,
      );
      await loadPondsAndBatches();
    } catch (e) {
      state = state.copyWith(errorMessage: e.toString());
      rethrow;
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

      // Optimistic local state update for immediate 60/120 FPS UI reactivity
      final updatedBatches = state.batches.map((b) {
        if (b.id == loteId) {
          final newCount = (b.cantidadActualPeces - cantidadPecesMuertos).clamp(0, 9999999);
          final effectivePeso = pesoPromedioGramos > 0 ? pesoPromedioGramos : b.pesoActualGramos;
          final newBio = (newCount * effectivePeso) / 1000.0;
          return b.copyWith(
            cantidadActualPeces: newCount,
            biomasaActualKg: newBio,
          );
        }
        return b;
      }).toList();

      final updatedPonds = state.ponds.map((p) {
        if (p.id == estanqueId) {
          final pondBatches = updatedBatches.where((b) => b.estanqueId == estanqueId);
          final pondBio = pondBatches.fold(0.0, (sum, b) => sum + b.biomasaActualKg);
          return p.copyWith(biomasaKg: pondBio);
        }
        return p;
      }).toList();

      state = state.copyWith(
        mortalityRecords: [savedRecord, ...state.mortalityRecords],
        batches: updatedBatches,
        ponds: updatedPonds,
      );

      // Disparar evento de dominio para sincronizar otros módulos en tiempo real
      _ref.read(eventBusProvider).fire(
        MortalityRecordedEvent(
          estanqueId: estanqueId,
          loteId: loteId,
          cantidadPecesMuertos: cantidadPecesMuertos,
          biomasaPerdidaKg: biomasaPerdidaKg,
          fecha: fecha,
        ),
      );

      // Refresh ponds and batches to guarantee full consistency with DB triggers
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
    double? biomasaCalculadaKg,
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
        biomasaCalculadaKg: biomasaCalculadaKg,
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

      // Optimistic local state update for immediate 60/120 FPS UI reactivity
      final updatedBatches = state.batches.map((b) {
        if (b.id == loteId) {
          final newBio = (b.cantidadActualPeces * nuevoPesoPromedioGramos) / 1000.0;
          return b.copyWith(
            pesoActualGramos: nuevoPesoPromedioGramos,
            biomasaActualKg: newBio,
          );
        }
        return b;
      }).toList();

      final updatedPonds = state.ponds.map((p) {
        if (p.id == estanqueId) {
          final pondBatches = updatedBatches.where((b) => b.estanqueId == estanqueId);
          final pondBio = pondBatches.fold(0.0, (sum, b) => sum + b.biomasaActualKg);
          return p.copyWith(biomasaKg: pondBio);
        }
        return p;
      }).toList();

      state = state.copyWith(
        biometries: [savedRecord, ...state.biometries],
        batches: updatedBatches,
        ponds: updatedPonds,
      );

      // Disparar evento de dominio para sincronizar otros módulos en tiempo real
      _ref.read(eventBusProvider).fire(
        BiometryRecordedEvent(
          estanqueId: estanqueId,
          loteId: loteId,
          pesoPromedioGramos: nuevoPesoPromedioGramos,
          biomasaCalculadaKg: biomasaCalculadaKg,
          fecha: fecha,
        ),
      );

      // Refresh ponds and batches to update weight & biomass metrics from backend
      await loadPondsAndBatches();
      return true;
    } catch (e) {
      state = state.copyWith(errorMessage: e.toString());
      return false;
    }
  }

  Future<bool> updateBiometry(BiometriaRecord record) async {
    try {
      await _repository.updateBiometry(record);
      await loadPondsAndBatches();
      return true;
    } catch (e) {
      state = state.copyWith(errorMessage: e.toString());
      return false;
    }
  }

  Future<bool> deleteBiometry(BiometriaRecord record) async {
    try {
      await _repository.deleteBiometry(record);
      await loadPondsAndBatches();
      return true;
    } catch (e) {
      state = state.copyWith(errorMessage: e.toString());
      return false;
    }
  }

  Future<bool> updateMortality(MortalityRecord oldRecord, MortalityRecord newRecord) async {
    try {
      await _repository.updateMortality(oldRecord, newRecord);
      await loadPondsAndBatches();
      return true;
    } catch (e) {
      state = state.copyWith(errorMessage: e.toString());
      return false;
    }
  }

  Future<bool> deleteMortality(MortalityRecord record) async {
    try {
      await _repository.deleteMortality(record);
      await loadPondsAndBatches();
      return true;
    } catch (e) {
      state = state.copyWith(errorMessage: e.toString());
      return false;
    }
  }

  Future<bool> deleteTransfer(TransferRecord record) async {
    try {
      await _repository.deleteTransfer(record);
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

