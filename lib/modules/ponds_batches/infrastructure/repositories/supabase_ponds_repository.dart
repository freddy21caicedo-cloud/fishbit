import 'package:uuid/uuid.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:fishbit_finance/modules/ponds_batches/domain/models/pond.dart';
import 'package:fishbit_finance/modules/ponds_batches/domain/models/fish_batch.dart';
import 'package:fishbit_finance/modules/ponds_batches/domain/models/biometria_record.dart';
import 'package:fishbit_finance/modules/ponds_batches/domain/models/mortality_record.dart';
import 'package:fishbit_finance/modules/ponds_batches/domain/models/transfer_record.dart';
import 'package:fishbit_finance/modules/ponds_batches/domain/repositories/ponds_repository.dart';

class SupabasePondsRepository implements PondsRepository {
  final SupabaseClient _supabase;

  SupabasePondsRepository(this._supabase);

  static final List<Pond> _demoPonds = [
    Pond(
      id: 'p1000000-0000-0000-0000-000000000001',
      empresaId: 'c1000000-0000-0000-0000-000000000001',
      unidadAcuicolaId: 'u1000000-0000-0000-0000-000000000001',
      nombre: 'Estanque 01 (Geomembrana)',
      sigla: 'E-01',
      capacidadM3: 450.0,
      biomasaKg: 2850.0,
      costoAcumuladoBiologico: 12450000.0,
      estado: PondStatus.active,
      aireacionActiva: true,
      creadoEn: DateTime.now(),
    ),
    Pond(
      id: 'p1000000-0000-0000-0000-000000000002',
      empresaId: 'c1000000-0000-0000-0000-000000000001',
      unidadAcuicolaId: 'u1000000-0000-0000-0000-000000000001',
      nombre: 'Estanque 02 (Tierra)',
      sigla: 'E-02',
      capacidadM3: 800.0,
      biomasaKg: 5200.0,
      costoAcumuladoBiologico: 21800000.0,
      estado: PondStatus.active,
      aireacionActiva: true,
      creadoEn: DateTime.now(),
    ),
    Pond(
      id: 'p1000000-0000-0000-0000-000000000003',
      empresaId: 'c1000000-0000-0000-0000-000000000001',
      unidadAcuicolaId: 'u1000000-0000-0000-0000-000000000001',
      nombre: 'Estanque 03 (Pre-cría)',
      sigla: 'E-03',
      capacidadM3: 250.0,
      biomasaKg: 0.0,
      costoAcumuladoBiologico: 0.0,
      estado: PondStatus.available,
      aireacionActiva: false,
      creadoEn: DateTime.now(),
    ),
  ];

  static final List<FishBatch> _demoBatches = [
    FishBatch(
      id: 'b1000000-0000-0000-0000-000000000001',
      empresaId: 'c1000000-0000-0000-0000-000000000001',
      unidadAcuicolaId: 'u1000000-0000-0000-0000-000000000001',
      estanqueId: 'p1000000-0000-0000-0000-000000000001',
      codigoLote: 'LOT-TIL-01-2026',
      especie: 'Tilapia Roja',
      cantidadInicialPeces: 6000,
      cantidadActualPeces: 5700,
      pesoInicialGramos: 15.0,
      pesoActualGramos: 500.0,
      biomasaInicialKg: 90.0,
      biomasaActualKg: 2850.0,
      costoInicialAlevinos: 1800000.0,
      costoAcumuladoInsumos: 8900000.0,
      costoAcumuladoFijo: 1750000.0,
      estado: BatchStatus.active,
      fechaSiembra: DateTime.now().subtract(const Duration(days: 110)),
      creadoEn: DateTime.now(),
    ),
    FishBatch(
      id: 'b1000000-0000-0000-0000-000000000002',
      empresaId: 'c1000000-0000-0000-0000-000000000001',
      unidadAcuicolaId: 'u1000000-0000-0000-0000-000000000001',
      estanqueId: 'p1000000-0000-0000-0000-000000000002',
      codigoLote: 'LOT-CAC-02-2026',
      especie: 'Cachama Negra',
      cantidadInicialPeces: 8500,
      cantidadActualPeces: 8000,
      pesoInicialGramos: 20.0,
      pesoActualGramos: 650.0,
      biomasaInicialKg: 170.0,
      biomasaActualKg: 5200.0,
      costoInicialAlevinos: 2550000.0,
      costoAcumuladoInsumos: 15850000.0,
      costoAcumuladoFijo: 3400000.0,
      estado: BatchStatus.active,
      fechaSiembra: DateTime.now().subtract(const Duration(days: 140)),
      creadoEn: DateTime.now(),
    ),
  ];

  static final List<BiometriaRecord> _demoBiometries = [
    BiometriaRecord(
      id: 'bio-0001',
      empresaId: 'c1000000-0000-0000-0000-000000000001',
      unitId: 'u1000000-0000-0000-0000-000000000001',
      estanqueId: 'p1000000-0000-0000-0000-000000000001',
      loteId: 'b1000000-0000-0000-0000-000000000001',
      fecha: DateTime.now().subtract(const Duration(days: 14)),
      hora: '08:30:00',
      pecesCapturados: 35,
      pesoTotalCapturaKg: 14.7,
      pesoPromedioG: 420.0,
      biomasaParcialKg: 2394.0,
      longitudCm: 26.5,
      factorK: 1.62,
      gdpGDia: 4.2,
      observaciones: 'Muestreo quincenal regular, peces sanos y activos',
      registradoPor: 'Admin Acuícola',
      creadoEn: DateTime.now().subtract(const Duration(days: 14)),
    ),
    BiometriaRecord(
      id: 'bio-0002',
      empresaId: 'c1000000-0000-0000-0000-000000000001',
      unitId: 'u1000000-0000-0000-0000-000000000001',
      estanqueId: 'p1000000-0000-0000-0000-000000000001',
      loteId: 'b1000000-0000-0000-0000-000000000001',
      fecha: DateTime.now(),
      hora: '09:00:00',
      pecesCapturados: 40,
      pesoTotalCapturaKg: 20.0,
      pesoPromedioG: 500.0,
      biomasaParcialKg: 2850.0,
      longitudCm: 28.0,
      factorK: 1.68,
      gdpGDia: 5.7,
      observaciones: 'Crecimiento óptimo, se autoriza transición a Engorde Final',
      registradoPor: 'Admin Acuícola',
      creadoEn: DateTime.now(),
    ),
  ];

  static final List<MortalityRecord> _demoMortalities = [
    MortalityRecord(
      id: 'mor-0001',
      empresaId: 'c1000000-0000-0000-0000-000000000001',
      unidadAcuicolaId: 'u1000000-0000-0000-0000-000000000001',
      estanqueId: 'p1000000-0000-0000-0000-000000000001',
      loteId: 'b1000000-0000-0000-0000-000000000001',
      cantidadPecesMuertos: 8,
      pesoPromedioGramos: 450.0,
      biomasaPerdidaKg: 3.6,
      causaProbable: 'Hipoxia / Bajo O2',
      observaciones: 'Falla eléctrica nocturna temporal en soplador 2',
      registradoPor: 'Operador de Turno',
      fecha: DateTime.now().subtract(const Duration(days: 3)),
      hora: '06:15:00',
      creadoEn: DateTime.now().subtract(const Duration(days: 3)),
    ),
  ];

  static final List<TransferRecord> _demoTransfers = [
    TransferRecord(
      id: 'tra-0001',
      empresaId: 'c1000000-0000-0000-0000-000000000001',
      unidadAcuicolaId: 'u1000000-0000-0000-0000-000000000001',
      loteOrigenId: 'b1000000-0000-0000-0000-000000000001',
      loteDestinoId: 'b1000000-0000-0000-0000-000000000002',
      estanqueOrigenId: 'p1000000-0000-0000-0000-000000000001',
      estanqueDestinoId: 'p1000000-0000-0000-0000-000000000002',
      tipoOperacion: TransferType.desdobleParcial,
      pecesTrasladados: 2500,
      pesoPromedioGramos: 450.0,
      biomasaTrasladadaKg: 1125.0,
      proporcionCostos: 0.50,
      costoAlevinosTransferido: 1250000.0,
      costoInsumosTransferido: 4500000.0,
      costoFijoTransferido: 475000.0,
      costoTotalTransferido: 6225000.0,
      nuevoCodigoLote: 'LOTE-TILA-01-B',
      registradoPor: 'Admin Acuícola',
      fechaOperacion: DateTime.now().subtract(const Duration(days: 7)),
      creadoEn: DateTime.now().subtract(const Duration(days: 7)),
    ),
  ];

  @override
  Future<List<Pond>> fetchPondsByUnit(String empresaId, String unidadAcuicolaId) async {
    if (empresaId.startsWith('c1000000-')) {
      return _demoPonds;
    }
    try {
      final res = await _supabase
          .from('estanques')
          .select('*')
          .eq('empresa_id', empresaId)
          .order('creado_en', ascending: true);

      final rawList = res as List;
      if (rawList.isNotEmpty) {
        return rawList.map((row) => Pond.fromJson(row as Map<String, dynamic>)).toList();
      }
      return _demoPonds;
    } catch (_) {
      return _demoPonds;
    }
  }

  @override
  Future<Pond> createPond(Pond pond) async {
    if (pond.empresaId.startsWith('c1000000-')) {
      _demoPonds.add(pond);
      return pond;
    }
    try {
      final res = await _supabase
          .from('estanques')
          .insert(pond.toJson())
          .select()
          .single();

      return Pond.fromJson(res);
    } catch (_) {
      _demoPonds.add(pond);
      return pond;
    }
  }

  @override
  Future<void> updatePond(Pond pond) async {
    final idx = _demoPonds.indexWhere((p) => p.id == pond.id);
    if (idx != -1) _demoPonds[idx] = pond;

    if (!pond.empresaId.startsWith('c1000000-')) {
      try {
        await _supabase
            .from('estanques')
            .update(pond.toJson())
            .eq('id', pond.id);
      } catch (_) {}
    }
  }

  @override
  Future<void> deletePond(String pondId) async {
    _demoPonds.removeWhere((p) => p.id == pondId);
    try {
      await _supabase
          .from('estanques')
          .delete()
          .eq('id', pondId);
    } catch (_) {}
  }

  @override
  Future<List<FishBatch>> fetchBatchesByUnit(String empresaId, String unidadAcuicolaId) async {
    if (empresaId.startsWith('c1000000-')) {
      return _demoBatches;
    }
    try {
      final res = await _supabase
          .from('lotes')
          .select('*')
          .eq('empresa_id', empresaId)
          .order('creado_en', ascending: true);

      final rawList = res as List;
      if (rawList.isNotEmpty) {
        return rawList.map((row) => FishBatch.fromJson(row as Map<String, dynamic>)).toList();
      }

      // Fallback a siembras si lotes no retorna datos
      try {
        final resSiembras = await _supabase
            .from('siembras')
            .select('*')
            .eq('empresa_id', empresaId)
            .order('created_at', ascending: true);
        final siembrasList = resSiembras as List;
        if (siembrasList.isNotEmpty) {
          return siembrasList.map((row) => FishBatch.fromJson(row as Map<String, dynamic>)).toList();
        }
      } catch (_) {}

      return _demoBatches;
    } catch (_) {
      return _demoBatches;
    }
  }

  @override
  Future<FishBatch> createBatch(FishBatch batch) async {
    if (batch.empresaId.startsWith('c1000000-')) {
      _demoBatches.add(batch);
      final pondIdx = _demoPonds.indexWhere((p) => p.id == batch.estanqueId);
      if (pondIdx != -1) {
        _demoPonds[pondIdx] = _demoPonds[pondIdx].copyWith(
          estado: PondStatus.active,
          especieActual: batch.especie,
          biomasaKg: batch.biomasaActualKg,
          costoAcumuladoBiologico: batch.costoTotal,
        );
      }
      return batch;
    }

    try {
      final res = await _supabase
          .from('lotes')
          .insert(batch.toJson())
          .select()
          .single();

      await _supabase.from('estanques').update({
        'estado': 'Activo',
        'especie_actual': batch.especie,
        'biomasa_kg': batch.biomasaActualKg,
        'costo_acumulado_biologico': batch.costoTotal,
      }).eq('id', batch.estanqueId);

      return FishBatch.fromJson(res);
    } catch (_) {
      _demoBatches.add(batch);
      final pondIdx = _demoPonds.indexWhere((p) => p.id == batch.estanqueId);
      if (pondIdx != -1) {
        _demoPonds[pondIdx] = _demoPonds[pondIdx].copyWith(
          estado: PondStatus.active,
          especieActual: batch.especie,
          biomasaKg: batch.biomasaActualKg,
          costoAcumuladoBiologico: batch.costoTotal,
        );
      }
      return batch;
    }
  }

  @override
  Future<void> updateBatch(FishBatch batch) async {
    final idx = _demoBatches.indexWhere((b) => b.id == batch.id);
    if (idx != -1) _demoBatches[idx] = batch;

    if (!batch.empresaId.startsWith('c1000000-')) {
      try {
        await _supabase
            .from('lotes')
            .update(batch.toJson())
            .eq('id', batch.id);
      } catch (_) {}
    }
  }

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
  }) async {
    final now = DateTime.now();
    final origenIdx = _demoBatches.indexWhere((b) => b.id == batchOrigenId);
    if (origenIdx != -1) {
      final origen = _demoBatches[origenIdx];
      final proporcion = origen.cantidadActualPeces > 0
          ? (pecesTrasladados / origen.cantidadActualPeces)
          : 0.0;

      final costoInsumosProporcional = origen.costoAcumuladoInsumos * proporcion;
      final costoFijoProporcional = origen.costoAcumuladoFijo * proporcion;
      final costoAlevinesProporcional = origen.costoInicialAlevinos * proporcion;
      final costoTotalProporcional = costoAlevinesProporcional + costoInsumosProporcional + costoFijoProporcional;
      String? nuevoLoteId;

      if (esDesdoble) {
        final remanentePeces = origen.cantidadActualPeces - pecesTrasladados;
        final remanenteBiomasa = origen.biomasaActualKg - biomasaTrasladadaKg;

        _demoBatches[origenIdx] = origen.copyWith(
          cantidadActualPeces: remanentePeces,
          biomasaActualKg: remanenteBiomasa,
          costoAcumuladoInsumos: origen.costoAcumuladoInsumos - costoInsumosProporcional,
          costoAcumuladoFijo: origen.costoAcumuladoFijo - costoFijoProporcional,
          costoInicialAlevinos: origen.costoInicialAlevinos - costoAlevinesProporcional,
        );

        nuevoLoteId = const Uuid().v4();
        final newBatch = FishBatch(
          id: nuevoLoteId,
          empresaId: origen.empresaId,
          unidadAcuicolaId: origen.unidadAcuicolaId,
          estanqueId: estanqueDestinoId,
          lotePadreId: origen.id,
          codigoLote: nuevoCodigoLote,
          especie: origen.especie,
          cantidadInicialPeces: pecesTrasladados,
          cantidadActualPeces: pecesTrasladados,
          pesoInicialGramos: origen.pesoActualGramos,
          pesoActualGramos: origen.pesoActualGramos,
          biomasaInicialKg: biomasaTrasladadaKg,
          biomasaActualKg: biomasaTrasladadaKg,
          costoInicialAlevinos: costoAlevinesProporcional,
          costoAcumuladoInsumos: costoInsumosProporcional,
          costoAcumuladoFijo: costoFijoProporcional,
          estado: BatchStatus.active,
          fechaSiembra: now,
          creadoEn: now,
        );
        _demoBatches.add(newBatch);

        final origPondIdx = _demoPonds.indexWhere((p) => p.id == estanqueOrigenId);
        if (origPondIdx != -1) {
          _demoPonds[origPondIdx] = _demoPonds[origPondIdx].copyWith(
            biomasaKg: remanenteBiomasa,
            costoAcumuladoBiologico: _demoBatches[origenIdx].costoTotal,
          );
        }

        final destPondIdx = _demoPonds.indexWhere((p) => p.id == estanqueDestinoId);
        if (destPondIdx != -1) {
          _demoPonds[destPondIdx] = _demoPonds[destPondIdx].copyWith(
            estado: PondStatus.active,
            especieActual: origen.especie,
            biomasaKg: biomasaTrasladadaKg,
            costoAcumuladoBiologico: newBatch.costoTotal,
          );
        }
      } else {
        _demoBatches[origenIdx] = origen.copyWith(estanqueId: estanqueDestinoId);
        final origPondIdx = _demoPonds.indexWhere((p) => p.id == estanqueOrigenId);
        if (origPondIdx != -1) {
          _demoPonds[origPondIdx] = _demoPonds[origPondIdx].copyWith(
            estado: PondStatus.available,
            especieActual: '',
            biomasaKg: 0.0,
            costoAcumuladoBiologico: 0.0,
          );
        }
        final destPondIdx = _demoPonds.indexWhere((p) => p.id == estanqueDestinoId);
        if (destPondIdx != -1) {
          _demoPonds[destPondIdx] = _demoPonds[destPondIdx].copyWith(
            estado: PondStatus.active,
            especieActual: origen.especie,
            biomasaKg: origen.biomasaActualKg,
            costoAcumuladoBiologico: origen.costoTotal,
          );
        }
      }

      // Registro de Auditoría en memoria
      final transferAudit = TransferRecord(
        id: const Uuid().v4(),
        empresaId: origen.empresaId,
        unidadAcuicolaId: origen.unidadAcuicolaId,
        loteOrigenId: origen.id,
        loteDestinoId: nuevoLoteId ?? origen.id,
        estanqueOrigenId: estanqueOrigenId,
        estanqueDestinoId: estanqueDestinoId,
        tipoOperacion: esDesdoble ? TransferType.desdobleParcial : TransferType.trasladoTotal,
        pecesTrasladados: pecesTrasladados,
        pesoPromedioGramos: origen.pesoActualGramos,
        biomasaTrasladadaKg: biomasaTrasladadaKg,
        proporcionCostos: proporcion,
        costoAlevinosTransferido: costoAlevinesProporcional,
        costoInsumosTransferido: costoInsumosProporcional,
        costoFijoTransferido: costoFijoProporcional,
        costoTotalTransferido: costoTotalProporcional,
        nuevoCodigoLote: nuevoCodigoLote,
        registradoPor: registradoPor ?? 'Admin Acuícola',
        fechaOperacion: now,
        creadoEn: now,
      );
      _demoTransfers.insert(0, transferAudit);

      // Persistencia en Supabase Postgres
      if (!origen.empresaId.startsWith('c1000000-')) {
        try {
          await _supabase.from('traslados_lotes').insert(transferAudit.toJson());
        } catch (_) {}
      }
    }
  }

  @override
  Future<List<TransferRecord>> fetchTransfersByUnit(
    String empresaId,
    String unidadAcuicolaId, {
    String? pondId,
    String? batchId,
  }) async {
    if (empresaId.startsWith('c1000000-')) {
      var list = _demoTransfers;
      if (pondId != null && pondId.isNotEmpty) {
        list = list.where((t) => t.estanqueOrigenId == pondId || t.estanqueDestinoId == pondId).toList();
      }
      if (batchId != null && batchId.isNotEmpty) {
        list = list.where((t) => t.loteOrigenId == batchId || t.loteDestinoId == batchId).toList();
      }
      return list;
    }
    try {
      var query = _supabase.from('traslados_lotes').select('*').eq('empresa_id', empresaId);
      if (pondId != null && pondId.isNotEmpty) {
        query = query.or('estanque_origen_id.eq.$pondId,estanque_destino_id.eq.$pondId');
      }
      if (batchId != null && batchId.isNotEmpty) {
        query = query.or('lote_origen_id.eq.$batchId,lote_destino_id.eq.$batchId');
      }
      final res = await query.order('fecha_operacion', ascending: false).limit(100);
      final rawList = res as List;
      if (rawList.isNotEmpty) {
        return rawList.map((row) => TransferRecord.fromJson(row as Map<String, dynamic>)).toList();
      }
      return _demoTransfers;
    } catch (_) {
      return _demoTransfers;
    }
  }

  @override
  Future<List<BiometriaRecord>> fetchBiometriesByUnit(
    String empresaId,
    String unidadAcuicolaId, {
    String? pondId,
    String? batchId,
  }) async {
    if (empresaId.startsWith('c1000000-')) {
      var list = _demoBiometries;
      if (pondId != null && pondId.isNotEmpty) {
        list = list.where((b) => b.estanqueId == pondId).toList();
      }
      if (batchId != null && batchId.isNotEmpty) {
        list = list.where((b) => b.loteId == batchId).toList();
      }
      return list;
    }
    try {
      var query = _supabase.from('biometrias').select('*').eq('empresa_id', empresaId);

      if (pondId != null && pondId.isNotEmpty) {
        query = query.eq('estanque_id', pondId);
      }
      if (batchId != null && batchId.isNotEmpty) {
        query = query.or('batch_id.eq.$batchId,lote_id.eq.$batchId');
      }

      final res = await query.order('date', ascending: false).limit(100);
      final rawList = res as List;
      if (rawList.isNotEmpty) {
        return rawList.map((row) => BiometriaRecord.fromJson(row as Map<String, dynamic>)).toList();
      }

      var list = _demoBiometries;
      if (pondId != null && pondId.isNotEmpty) {
        list = list.where((b) => b.estanqueId == pondId).toList();
      }
      return list;
    } catch (_) {
      var list = _demoBiometries;
      if (pondId != null && pondId.isNotEmpty) {
        list = list.where((b) => b.estanqueId == pondId).toList();
      }
      return list;
    }
  }

  @override
  Future<List<MortalityRecord>> fetchMortalityByUnit(
    String empresaId,
    String unidadAcuicolaId, {
    String? pondId,
    String? batchId,
  }) async {
    if (empresaId.startsWith('c1000000-')) {
      var list = _demoMortalities;
      if (pondId != null && pondId.isNotEmpty) {
        list = list.where((m) => m.estanqueId == pondId).toList();
      }
      if (batchId != null && batchId.isNotEmpty) {
        list = list.where((m) => m.loteId == batchId).toList();
      }
      return list;
    }
    try {
      var query = _supabase.from('mortalidad').select('*').eq('empresa_id', empresaId);

      if (pondId != null && pondId.isNotEmpty) {
        query = query.eq('estanque_id', pondId);
      }
      if (batchId != null && batchId.isNotEmpty) {
        query = query.or('batch_id.eq.$batchId,lote_id.eq.$batchId');
      }

      final res = await query.order('date', ascending: false).limit(100);
      final rawList = res as List;
      if (rawList.isNotEmpty) {
        return rawList.map((row) => MortalityRecord.fromJson(row as Map<String, dynamic>)).toList();
      }

      var list = _demoMortalities;
      if (pondId != null && pondId.isNotEmpty) {
        list = list.where((m) => m.estanqueId == pondId).toList();
      }
      return list;
    } catch (_) {
      var list = _demoMortalities;
      if (pondId != null && pondId.isNotEmpty) {
        list = list.where((m) => m.estanqueId == pondId).toList();
      }
      return list;
    }
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
    final now = fecha ?? DateTime.now();
    final hourStr = hora ?? '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}:00';
    final biomasaPerdida = biomasaPerdidaKg ?? ((cantidadPecesMuertos * pesoPromedioGramos) / 1000.0);

    final batchIdx = _demoBatches.indexWhere((b) => b.id == loteId || b.estanqueId == estanqueId);
    double newBiomass = 0.0;
    int newCount = 0;

    String finalEmpresaId = empresaId ?? '';
    String finalUnitId = unidadAcuicolaId ?? '';

    if (batchIdx != -1) {
      final batch = _demoBatches[batchIdx];
      if (finalEmpresaId.isEmpty) finalEmpresaId = batch.empresaId;
      if (finalUnitId.isEmpty) finalUnitId = batch.unidadAcuicolaId;
      newCount = (batch.cantidadActualPeces - cantidadPecesMuertos).clamp(0, 9999999);
      newBiomass = (newCount * (pesoPromedioGramos > 0 ? pesoPromedioGramos : batch.pesoActualGramos)) / 1000.0;
      
      _demoBatches[batchIdx] = batch.copyWith(
        cantidadActualPeces: newCount,
        biomasaActualKg: newBiomass,
      );

      final pondIdx = _demoPonds.indexWhere((p) => p.id == estanqueId);
      if (pondIdx != -1) {
        _demoPonds[pondIdx] = _demoPonds[pondIdx].copyWith(biomasaKg: newBiomass);
      }
    }

    final record = MortalityRecord(
      id: const Uuid().v4(),
      empresaId: finalEmpresaId,
      unidadAcuicolaId: finalUnitId,
      estanqueId: estanqueId,
      loteId: loteId,
      cantidadPecesMuertos: cantidadPecesMuertos,
      pesoPromedioGramos: pesoPromedioGramos,
      biomasaPerdidaKg: biomasaPerdida,
      causaProbable: causaProbable,
      observaciones: observaciones,
      registradoPor: registradoPor,
      fecha: now,
      hora: hourStr,
      creadoEn: DateTime.now(),
    );

    if (finalEmpresaId.startsWith('c1000000-')) {
      _demoMortalities.insert(0, record);
      return record;
    }

    try {
      // 1. Insertar en tabla oficial mortalidad con schema completo
      final insertData = {
        'id': record.id,
        'empresa_id': finalEmpresaId,
        'unit_id': finalUnitId,
        'unidad_acuicola_id': finalUnitId,
        'estanque_id': estanqueId,
        'lote_id': loteId,
        'batch_id': loteId,
        'cantidad': cantidadPecesMuertos,
        'quantity': cantidadPecesMuertos,
        'cantidad_peces_muertos': cantidadPecesMuertos,
        'causa': causaProbable,
        'cause': causaProbable,
        'causa_probable': causaProbable,
        'peso_promedio_gramos': pesoPromedioGramos,
        'biomasa_perdida_kg': biomasaPerdida,
        if (observaciones != null) 'observaciones': observaciones,
        if (registradoPor != null) 'registrado_por': registradoPor,
        'fecha': now.toIso8601String().split('T')[0],
        'date': now.toIso8601String().split('T')[0],
        'hora': hourStr,
        'creado_en': DateTime.now().toIso8601String(),
      };

      await _supabase.from('mortalidad').insert(insertData);

      // 2. Actualizar conteo y biomasa en lotes si aplica
      if (newCount > 0) {
        await _supabase.from('lotes').update({
          'cantidad_actual_peces': newCount,
          'biomasa_actual_kg': newBiomass,
        }).eq('id', loteId);

        await _supabase.from('estanques').update({
          'biomasa_kg': newBiomass,
        }).eq('id', estanqueId);
      }

      _demoMortalities.insert(0, record);
      return record;
    } catch (_) {
      _demoMortalities.insert(0, record);
      return record;
    }
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
    final now = fecha ?? DateTime.now();
    final hourStr = hora ?? '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}:00';
    final sampleCount = cantidadPecesMuestreados ?? 35;
    final totalCaptureKg = pesoTotalCapturaKg ?? ((sampleCount * nuevoPesoPromedioGramos) / 1000.0);

    final batchIdx = _demoBatches.indexWhere((b) => b.id == loteId || b.estanqueId == estanqueId);
    double newBiomass = 0.0;

    String finalEmpresaId = empresaId ?? '';
    String finalUnitId = unidadAcuicolaId ?? '';

    if (batchIdx != -1) {
      final batch = _demoBatches[batchIdx];
      if (finalEmpresaId.isEmpty) finalEmpresaId = batch.empresaId;
      if (finalUnitId.isEmpty) finalUnitId = batch.unidadAcuicolaId;
      newBiomass = (batch.cantidadActualPeces * nuevoPesoPromedioGramos) / 1000.0;

      _demoBatches[batchIdx] = batch.copyWith(
        pesoActualGramos: nuevoPesoPromedioGramos,
        biomasaActualKg: newBiomass,
      );

      final pondIdx = _demoPonds.indexWhere((p) => p.id == estanqueId);
      if (pondIdx != -1) {
        _demoPonds[pondIdx] = _demoPonds[pondIdx].copyWith(biomasaKg: newBiomass);
      }
    }

    final record = BiometriaRecord(
      id: const Uuid().v4(),
      empresaId: finalEmpresaId,
      unitId: finalUnitId,
      estanqueId: estanqueId,
      loteId: loteId,
      fecha: now,
      hora: hourStr,
      pecesCapturados: sampleCount,
      pesoTotalCapturaKg: totalCaptureKg,
      pesoPromedioG: nuevoPesoPromedioGramos,
      biomasaParcialKg: newBiomass,
      longitudCm: longitudPromedioCm,
      factorK: factorK,
      gdpGDia: gdpGDia,
      observaciones: observaciones,
      registradoPor: registradoPor,
      creadoEn: DateTime.now(),
    );

    if (finalEmpresaId.startsWith('c1000000-')) {
      _demoBiometries.insert(0, record);
      return record;
    }

    try {
      // 1. Insertar en tabla oficial biometrias con schema completo
      final insertData = {
        'id': record.id,
        'empresa_id': finalEmpresaId,
        'unit_id': finalUnitId,
        'unidad_acuicola_id': finalUnitId,
        'estanque_id': estanqueId,
        'lote_id': loteId,
        'batch_id': loteId,
        'fecha': now.toIso8601String().split('T')[0],
        'date': now.toIso8601String().split('T')[0],
        'hora': hourStr,
        'peces_capturados': sampleCount,
        'peso_total_captura_kg': totalCaptureKg,
        'peso_promedio_g': nuevoPesoPromedioGramos,
        'avg_weight_gr': nuevoPesoPromedioGramos,
        'biomasa_parcial_kg': newBiomass,
        'total_biomass_kg': newBiomass,
        if (longitudPromedioCm != null) 'longitud_cm': longitudPromedioCm,
        if (factorK != null) 'factor_k': factorK,
        if (gdpGDia != null) 'gdp_g_dia': gdpGDia,
        if (observaciones != null) 'observaciones': observaciones,
        if (registradoPor != null) 'registrado_por': registradoPor,
        'creado_en': DateTime.now().toIso8601String(),
      };

      await _supabase.from('biometrias').insert(insertData);

      // 2. Actualizar biomasa y peso actual en lotes y estanques
      if (newBiomass > 0) {
        await _supabase.from('lotes').update({
          'biomasa_actual_kg': newBiomass,
          'peso_actual_gramos': nuevoPesoPromedioGramos,
        }).eq('id', loteId);

        await _supabase.from('estanques').update({
          'biomasa_kg': newBiomass,
        }).eq('id', estanqueId);
      }

      _demoBiometries.insert(0, record);
      return record;
    } catch (_) {
      _demoBiometries.insert(0, record);
      return record;
    }
  }
}
