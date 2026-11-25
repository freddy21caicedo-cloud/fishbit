import 'package:flutter/foundation.dart';
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
      mortalidadAcumuladaPeces: 300,
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
      especie: 'Cachama Blanca',
      cantidadInicialPeces: 8500,
      cantidadActualPeces: 8000,
      mortalidadAcumuladaPeces: 500,
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
      return List<Pond>.from(_demoPonds)..sort(Pond.compareByNumber);
    }
    try {
      final res = await _supabase
          .from('estanques')
          .select('*')
          .eq('empresa_id', empresaId)
          .eq('is_deleted', false)
          .order('creado_en', ascending: true);

      final rawList = res as List;
      if (rawList.isNotEmpty) {
        final ponds = rawList.map((row) => Pond.fromJson(row as Map<String, dynamic>)).toList();
        try {
          final lotesRes = await _supabase
              .from('lotes')
              .select('estanque_id, biomasa_actual_kg')
              .eq('empresa_id', empresaId)
              .eq('estado', 'Activo');
          final lotesList = lotesRes as List;
          if (lotesList.isNotEmpty) {
            final Map<String, double> bioPorEstanque = {};
            for (final l in lotesList) {
              final pid = l['estanque_id']?.toString() ?? '';
              final bio = (l['biomasa_actual_kg'] as num?)?.toDouble() ?? 0.0;
              bioPorEstanque[pid] = (bioPorEstanque[pid] ?? 0.0) + bio;
            }
            final enriched = ponds.map((p) {
              final realBio = bioPorEstanque[p.id];
              if (realBio != null && realBio > 0) {
                return p.copyWith(biomasaKg: realBio);
              }
              return p;
            }).toList()
              ..sort(Pond.compareByNumber);
            return enriched;
          }
        } catch (_) {}
        ponds.sort(Pond.compareByNumber);
        return ponds;
      }
      return [];
    } catch (_) {
      return [];
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
    } catch (e) {
      // Si falla la inserción en base de datos real, propagamos el error para no engañar al usuario
      rethrow;
    }
  }

  @override
  Future<void> updatePond(Pond pond) async {
    final idx = _demoPonds.indexWhere((p) => p.id == pond.id);
    if (idx != -1) _demoPonds[idx] = pond;

    if (!pond.empresaId.startsWith('c1000000-')) {
      final payload = Map<String, dynamic>.from(pond.toJson())..remove('id');
      await _supabase
          .from('estanques')
          .update(payload)
          .eq('id', pond.id);
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
        final batches = rawList.map((row) => FishBatch.fromJson(row as Map<String, dynamic>)).toList();
        
        // Sumar dinámicamente el alimento acumulado registrado en alimentacion_diaria para cálculo exacto de FCA
        try {
          final feedRes = await _supabase
              .from('alimentacion_diaria')
              .select('lote_id, cantidad_consumida_kg, costo_calculado')
              .eq('empresa_id', empresaId);
          final feedList = feedRes as List;
          if (feedList.isNotEmpty) {
            final Map<String, double> alimentoPorLote = {};
            final Map<String, double> costoInsumosPorLote = {};
            for (final f in feedList) {
              final lid = f['lote_id']?.toString() ?? '';
              final cant = (f['cantidad_consumida_kg'] as num?)?.toDouble() ?? 0.0;
              final costo = (f['costo_calculado'] as num?)?.toDouble() ?? 0.0;
              alimentoPorLote[lid] = (alimentoPorLote[lid] ?? 0.0) + cant;
              costoInsumosPorLote[lid] = (costoInsumosPorLote[lid] ?? 0.0) + costo;
            }
            final parentIdsWithChildren = batches
                .where((b) => b.lotePadreId != null && b.lotePadreId!.isNotEmpty)
                .map((b) => b.lotePadreId!)
                .toSet();
            final enriched = batches.map((b) {
              // Si el lote fue desdoblado (tiene lotes hijos), respetar el prorrateo almacenado en lotes
              if (parentIdsWithChildren.contains(b.id) || (b.lotePadreId != null && b.lotePadreId!.isNotEmpty)) {
                return b;
              }
              final kgAlimento = alimentoPorLote[b.id] ?? b.alimentoAcumuladoKg;
              final costoInsumos = costoInsumosPorLote[b.id] ?? b.costoAcumuladoInsumos;
              return b.copyWith(
                alimentoAcumuladoKg: kgAlimento > 0 ? kgAlimento : b.alimentoAcumuladoKg,
                costoAcumuladoInsumos: costoInsumos > 0 ? costoInsumos : b.costoAcumuladoInsumos,
              );
            }).toList();
            batches
              ..clear()
              ..addAll(enriched);
          }
        } catch (_) {}
        // Sincronizar dinámicamente el peso actual y biomasa con la última biometría registrada para consistencia infalible
        try {
          final bioRes = await _supabase
              .from('biometrias')
              .select('lote_id, peso_promedio_g, fecha, creado_en')
              .eq('empresa_id', empresaId)
              .order('fecha', ascending: false)
              .order('creado_en', ascending: false);
          final bioList = bioRes as List;
          if (bioList.isNotEmpty) {
            final Map<String, double> latestWeightByBatch = {};
            for (final bio in bioList) {
              final lid = bio['lote_id']?.toString() ?? '';
              final w = (bio['peso_promedio_g'] as num?)?.toDouble();
              if (lid.isNotEmpty && w != null && w > 0 && !latestWeightByBatch.containsKey(lid)) {
                latestWeightByBatch[lid] = w;
              }
            }

            for (int i = 0; i < batches.length; i++) {
              final b = batches[i];
              final latestW = latestWeightByBatch[b.id];
              if (latestW != null && latestW > 0 && latestW != b.pesoActualGramos) {
                final correctedBiomass = (b.cantidadActualPeces * latestW) / 1000.0;
                batches[i] = b.copyWith(
                  pesoActualGramos: latestW,
                  biomasaActualKg: correctedBiomass > 0 ? correctedBiomass : b.biomasaActualKg,
                );
              }
            }
          }
        } catch (_) {}

        return batches;
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

      return []; // BUG-13: no devolver demo data para empresas reales
    } catch (_) {
      return []; // BUG-13: no devolver demo data para empresas reales
    }
  }

  @override
  Future<FishBatch> createBatch(FishBatch batch) async {
    if (batch.empresaId.startsWith('c1000000-')) {
      _demoBatches.add(batch);
      final pondIdx = _demoPonds.indexWhere((p) => p.id == batch.estanqueId);
      if (pondIdx != -1) {
        final totalBiomasa = _demoBatches
            .where((b) => b.estanqueId == batch.estanqueId && b.estado == BatchStatus.active)
            .fold<double>(0.0, (acc, b) => acc + b.biomasaActualKg);
        final totalCosto = _demoBatches
            .where((b) => b.estanqueId == batch.estanqueId && b.estado == BatchStatus.active)
            .fold<double>(0.0, (acc, b) => acc + b.costoTotal);
        _demoPonds[pondIdx] = _demoPonds[pondIdx].copyWith(
          estado: PondStatus.active,
          especieActual: batch.especie,
          biomasaKg: totalBiomasa,
          costoAcumuladoBiologico: totalCosto,
        );
      }
      return batch;
    }

    try {
      final insertData = Map<String, dynamic>.from(batch.toJson());

      // Si falta unidad_acuicola_sigla, consultarla del estanque para garantizar la restricción chk_lote_unidad_acuicola_sigla_not_null
      if (insertData['unidad_acuicola_sigla'] == null || insertData['unidad_acuicola_sigla'].toString().trim().isEmpty) {
        try {
          final pondRow = await _supabase.from('estanques').select('sigla, unidad_acuicola_sigla').eq('id', batch.estanqueId).maybeSingle();
          if (pondRow != null) {
            final siglaPond = pondRow['unidad_acuicola_sigla'] ??
                (pondRow['sigla'] != null && pondRow['sigla'].toString().contains('-')
                    ? pondRow['sigla'].toString().split('-').last
                    : 'PRIN');
            insertData['unidad_acuicola_sigla'] = siglaPond;
          }
        } catch (_) {}
      }

      final res = await _supabase
          .from('lotes')
          .insert(insertData)
          .select()
          .single();

      await _supabase.from('estanques').update({
        'estado': 'Activo',
        'especie': batch.especie,
        'costo_acumulado_biologico': batch.costoTotal,
      }).eq('id', batch.estanqueId);

      await _syncPondBiomassAndCount(batch.estanqueId);

      return FishBatch.fromJson(res);
    } catch (e) {
      // Re-lanzar la excepción para alertar al usuario y no engañar a la UI con datos temporales que desaparecen
      rethrow;
    }
  }

  @override
  Future<FishBatch> plantBatchWithSeedDiscount({
    required FishBatch batch,
    required String inventoryItemId,
  }) async {
    final linkedBatch = batch.copyWith(inventoryItemId: inventoryItemId);

    if (linkedBatch.empresaId.startsWith('c1000000-')) {
      return createBatch(linkedBatch);
    }

    try {
      final res = await _supabase.rpc<dynamic>(
        'plant_batch_with_seed_discount',
        params: {
          'p_batch': linkedBatch.toJson(),
          'p_inventory_item_id': inventoryItemId,
          'p_cantidad_peces': linkedBatch.cantidadInicialPeces,
        },
      );

      if (res is Map) {
        return FishBatch.fromJson(Map<String, dynamic>.from(res));
      }
      if (res is List && res.isNotEmpty && res.first is Map) {
        return FishBatch.fromJson(Map<String, dynamic>.from(res.first as Map));
      }
      return linkedBatch;
    } catch (e) {
      rethrow;
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
    double? pesoPromedioGramos,
    required bool esDesdoble,
    required String nuevoCodigoLote,
    String? registradoPor,
  }) async {
    final now = DateTime.now();
    final origenIdx = _demoBatches.indexWhere((b) => b.id == batchOrigenId);
    final isDemo = origenIdx != -1 && _demoBatches[origenIdx].empresaId.startsWith('c1000000-');

    if (isDemo) {
      final origen = _demoBatches[origenIdx];
      if (pecesTrasladados <= 0) {
        throw Exception('La cantidad de peces a trasladar debe ser mayor a 0.');
      }
      if (esDesdoble && pecesTrasladados >= origen.cantidadActualPeces) {
        throw Exception(
          'No puedes desdoblar $pecesTrasladados peces cuando el lote solo tiene ${origen.cantidadActualPeces} vivos (para mover el 100% usa Traslado Total).',
        );
      }
      if (!esDesdoble && pecesTrasladados > origen.cantidadActualPeces) {
        throw Exception(
          'No puedes trasladar $pecesTrasladados peces cuando el lote solo tiene ${origen.cantidadActualPeces} vivos.',
        );
      }
      final pesoEfectivo = (pesoPromedioGramos != null && pesoPromedioGramos > 0)
          ? pesoPromedioGramos
          : origen.pesoActualGramos;
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
          pecesTrasladadosSalientes: origen.pecesTrasladadosSalientes + pecesTrasladados,
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
          final totalBiomasaOrig = _demoBatches
              .where((b) => b.estanqueId == estanqueOrigenId && b.estado == BatchStatus.active)
              .fold<double>(0.0, (acc, b) => acc + b.biomasaActualKg);
          _demoPonds[origPondIdx] = _demoPonds[origPondIdx].copyWith(
            biomasaKg: totalBiomasaOrig,
            costoAcumuladoBiologico: _demoBatches[origenIdx].costoTotal,
          );
        }

        final destPondIdx = _demoPonds.indexWhere((p) => p.id == estanqueDestinoId);
        if (destPondIdx != -1) {
          final totalBiomasaDest = _demoBatches
              .where((b) => b.estanqueId == estanqueDestinoId && b.estado == BatchStatus.active)
              .fold<double>(0.0, (acc, b) => acc + b.biomasaActualKg);
          _demoPonds[destPondIdx] = _demoPonds[destPondIdx].copyWith(
            estado: PondStatus.active,
            especieActual: origen.especie,
            biomasaKg: totalBiomasaDest,
            costoAcumuladoBiologico: newBatch.costoTotal,
          );
        }
      } else {
        _demoBatches[origenIdx] = origen.copyWith(estanqueId: estanqueDestinoId);
        final origPondIdx = _demoPonds.indexWhere((p) => p.id == estanqueOrigenId);
        if (origPondIdx != -1) {
          final activeBatchesOrig = _demoBatches
              .where((b) => b.estanqueId == estanqueOrigenId && b.estado == BatchStatus.active)
              .toList();
          final totalBiomasaOrig = activeBatchesOrig.fold<double>(0.0, (acc, b) => acc + b.biomasaActualKg);
          _demoPonds[origPondIdx] = _demoPonds[origPondIdx].copyWith(
            estado: activeBatchesOrig.isNotEmpty ? PondStatus.active : PondStatus.available,
            especieActual: activeBatchesOrig.isNotEmpty ? _demoPonds[origPondIdx].especieActual : '',
            biomasaKg: totalBiomasaOrig,
            costoAcumuladoBiologico: activeBatchesOrig.fold<double>(0.0, (acc, b) => acc + b.costoTotal),
          );
        }
        final destPondIdx = _demoPonds.indexWhere((p) => p.id == estanqueDestinoId);
        if (destPondIdx != -1) {
          final activeBatchesDest = _demoBatches
              .where((b) => b.estanqueId == estanqueDestinoId && b.estado == BatchStatus.active)
              .toList();
          _demoPonds[destPondIdx] = _demoPonds[destPondIdx].copyWith(
            estado: PondStatus.active,
            especieActual: origen.especie,
            biomasaKg: activeBatchesDest.fold<double>(0.0, (acc, b) => acc + b.biomasaActualKg),
            costoAcumuladoBiologico: activeBatchesDest.fold<double>(0.0, (acc, b) => acc + b.costoTotal),
          );
        }
      }

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
      return;
    }

    // Flujo para Empresas Reales en Supabase mediante RPC Atómica
    try {
      final loteOrigenRes = await _supabase
          .from('lotes')
          .select('*')
          .eq('id', batchOrigenId)
          .single();

      final currentPeces = (loteOrigenRes['cantidad_actual_peces'] as num?)?.toInt() ?? 0;
      if (pecesTrasladados <= 0) {
        throw Exception('La cantidad de peces a trasladar debe ser mayor a 0.');
      }
      if (currentPeces <= 0) {
        throw Exception('El lote origen no tiene peces vivos disponibles para trasladar.');
      }
      if (esDesdoble && pecesTrasladados >= currentPeces) {
        throw Exception(
          'No puedes desdoblar $pecesTrasladados peces cuando el lote solo tiene $currentPeces vivos (para mover el 100% usa Traslado Total).',
        );
      }
      if (!esDesdoble && pecesTrasladados > currentPeces) {
        throw Exception(
          'No puedes trasladar $pecesTrasladados peces cuando el lote solo tiene $currentPeces vivos.',
        );
      }

      final pesoPromedio = (pesoPromedioGramos != null && pesoPromedioGramos > 0)
          ? pesoPromedioGramos
          : ((loteOrigenRes['peso_actual_gramos'] as num?)?.toDouble() ??
              (pecesTrasladados > 0 ? (biomasaTrasladadaKg * 1000.0 / pecesTrasladados) : 100.0));

      try {
        await _supabase.rpc('split_or_transfer_batch', params: {
          'p_lote_origen_id': batchOrigenId,
          'p_estanque_destino_id': estanqueDestinoId,
          'p_tipo_operacion': esDesdoble ? 'DESDOBLE_PARCIAL' : 'TRASLADO_TOTAL',
          'p_peces_trasladar': pecesTrasladados,
          'p_peso_promedio': pesoPromedio,
          'p_nuevo_codigo_lote': nuevoCodigoLote,
          'p_motivo': 'Operación de ${esDesdoble ? 'desdoble parcial' : 'traslado total'}',
          'p_registrado_por': registradoPor ?? 'Admin Acuícola',
        });
      } catch (rpcErr) {
        debugPrint('[PondsRepository] RPC fallback en transferOrSplitBatch: $rpcErr');
        // Fallback seguro si el RPC falla por restricción unidad_acuicola_sigla o firma
        final origen = FishBatch.fromJson(loteOrigenRes);
        final proporcion = origen.cantidadActualPeces > 0
            ? (pecesTrasladados / origen.cantidadActualPeces).clamp(0.0, 1.0)
            : 0.0;
        final costoAlevinos = origen.costoInicialAlevinos * proporcion;
        final costoInsumos = origen.costoAcumuladoInsumos * proporcion;
        final costoFijo = origen.costoAcumuladoFijo * proporcion;
        final costoTotal = costoAlevinos + costoInsumos + costoFijo;
        final biomasaReal = (pecesTrasladados * pesoPromedio) / 1000.0;
        String nuevoLoteId = origen.id;

        if (esDesdoble) {
          final remanentePeces = (origen.cantidadActualPeces - pecesTrasladados).clamp(0, origen.cantidadActualPeces);
          final remanenteBiomasa = (remanentePeces * pesoPromedio) / 1000.0;
          await _supabase.from('lotes').update({
            'cantidad_actual_peces': remanentePeces,
            'peces_trasladados_salientes': origen.pecesTrasladadosSalientes + pecesTrasladados,
            'biomasa_actual_kg': remanenteBiomasa,
            'alimento_acumulado_kg': (origen.alimentoAcumuladoKg * (1 - proporcion)).clamp(0.0, double.infinity),
            'costo_inicial_alevinos': (origen.costoInicialAlevinos - costoAlevinos).clamp(0.0, double.infinity),
            'costo_acumulado_insumos': (origen.costoAcumuladoInsumos - costoInsumos).clamp(0.0, double.infinity),
            'costo_acumulado_fijo': (origen.costoAcumuladoFijo - costoFijo).clamp(0.0, double.infinity),
          }).eq('id', origen.id);

          nuevoLoteId = const Uuid().v4();
          final hijo = FishBatch(
            id: nuevoLoteId,
            empresaId: origen.empresaId,
            unidadAcuicolaId: origen.unidadAcuicolaId,
            unidadAcuicolaSigla: origen.unidadAcuicolaSigla ?? 'PRIN',
            estanqueId: estanqueDestinoId,
            lotePadreId: origen.id,
            codigoLote: nuevoCodigoLote,
            especie: origen.especie,
            rolPolicultivo: origen.rolPolicultivo,
            cantidadInicialPeces: pecesTrasladados,
            cantidadActualPeces: pecesTrasladados,
            pesoInicialGramos: pesoPromedio,
            pesoActualGramos: pesoPromedio,
            biomasaInicialKg: biomasaReal,
            biomasaActualKg: biomasaReal,
            alimentoAcumuladoKg: origen.alimentoAcumuladoKg * proporcion,
            costoInicialAlevinos: costoAlevinos,
            costoAcumuladoInsumos: costoInsumos,
            costoAcumuladoFijo: costoFijo,
            estado: BatchStatus.active,
            fechaSiembra: now,
            creadoEn: now,
          );
          await _supabase.from('lotes').insert(hijo.toJson());
        } else {
          await _supabase.from('lotes').update({
            'estanque_id': estanqueDestinoId,
            'peso_actual_gramos': pesoPromedio,
            'biomasa_actual_kg': biomasaReal,
          }).eq('id', origen.id);
        }

        await _supabase.from('traslados_lotes').insert({
          'id': const Uuid().v4(),
          'empresa_id': origen.empresaId,
          'unidad_acuicola_id': origen.unidadAcuicolaId,
          'lote_origen_id': origen.id,
          'lote_destino_id': nuevoLoteId,
          'estanque_origen_id': estanqueOrigenId,
          'estanque_destino_id': estanqueDestinoId,
          'tipo_operacion': esDesdoble ? 'DESDOBLE_PARCIAL' : 'TRASLADO_TOTAL',
          'peces_trasladados': pecesTrasladados,
          'peso_promedio_gramos': pesoPromedio,
          'biomasa_trasladada_kg': biomasaReal,
          'proporcion_costos': proporcion,
          'costo_alevinos_transferido': costoAlevinos,
          'costo_insumos_transferido': costoInsumos,
          'costo_fijo_transferido': costoFijo,
          'costo_total_transferido': costoTotal,
          'nuevo_codigo_lote': nuevoCodigoLote,
          'registrado_por': registradoPor ?? 'Admin Acuícola',
          'fecha_operacion': now.toIso8601String(),
        });
      }

      await _syncPondBiomassAndCount(estanqueOrigenId);
      await _syncPondBiomassAndCount(estanqueDestinoId);
    } catch (e) {
      debugPrint('[PondsRepository] Error en transferOrSplitBatch: $e');
      rethrow;
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
      return []; // BUG-13: no mezclar con datos demo para empresas reales
    } catch (_) {
      return []; // BUG-13: no mezclar con datos demo para empresas reales
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

      final res = await query
          .order('fecha', ascending: false)
          .order('creado_en', ascending: false)
          .limit(100);
      final rawList = res as List;
      return rawList.map((row) => BiometriaRecord.fromJson(row as Map<String, dynamic>)).toList();
    } catch (_) {
      return [];
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
      return rawList.map((row) => MortalityRecord.fromJson(row as Map<String, dynamic>)).toList();
    } catch (_) {
      return [];
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

    String finalEmpresaId = empresaId ?? '';
    String finalUnitId = unidadAcuicolaId ?? '';
    final isDemo = finalEmpresaId.startsWith('c1000000-');

    double newBiomass = 0.0;
    int newCount = 0;

    if (isDemo) {
      final batchIdx = _demoBatches.indexWhere((b) => b.id == loteId || b.estanqueId == estanqueId);
      if (batchIdx != -1) {
        final batch = _demoBatches[batchIdx];
        if (cantidadPecesMuertos <= 0) {
          throw Exception('La cantidad de bajas debe ser mayor a 0.');
        }
        if (cantidadPecesMuertos > batch.cantidadActualPeces) {
          throw Exception(
            'No puedes registrar $cantidadPecesMuertos bajas cuando el lote solo tiene ${batch.cantidadActualPeces} peces vivos.',
          );
        }
        if (finalEmpresaId.isEmpty) finalEmpresaId = batch.empresaId;
        if (finalUnitId.isEmpty) finalUnitId = batch.unidadAcuicolaId;
        newCount = (batch.cantidadActualPeces - cantidadPecesMuertos).clamp(0, 9999999);
        newBiomass = (newCount * (pesoPromedioGramos > 0 ? pesoPromedioGramos : batch.pesoActualGramos)) / 1000.0;
        
        _demoBatches[batchIdx] = batch.copyWith(
          cantidadActualPeces: newCount,
          mortalidadAcumuladaPeces: batch.mortalidadAcumuladaPeces + cantidadPecesMuertos,
          biomasaActualKg: newBiomass,
        );

        final pondIdx = _demoPonds.indexWhere((p) => p.id == estanqueId);
        if (pondIdx != -1) {
          final totalBiomasa = _demoBatches
              .where((b) => b.estanqueId == estanqueId && b.estado == BatchStatus.active)
              .fold<double>(0.0, (acc, b) => acc + b.biomasaActualKg);
          _demoPonds[pondIdx] = _demoPonds[pondIdx].copyWith(biomasaKg: totalBiomasa);
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
      _demoMortalities.insert(0, record);
      return record;
    }

    // Para empresas reales en Supabase
    try {
      final lotesRes = await _supabase
          .from('lotes')
          .select('cantidad_actual_peces, peso_actual_gramos, empresa_id, unit_id')
          .eq('id', loteId)
          .maybeSingle();

      if (lotesRes != null) {
        final currentPeces = (lotesRes['cantidad_actual_peces'] as num?)?.toInt() ?? 0;
        if (cantidadPecesMuertos <= 0) {
          throw Exception('La cantidad de bajas debe ser mayor a 0.');
        }
        if (cantidadPecesMuertos > currentPeces) {
          throw Exception(
            'No puedes registrar $cantidadPecesMuertos bajas cuando el lote solo tiene $currentPeces peces vivos.',
          );
        }
        final currentPeso = (lotesRes['peso_actual_gramos'] as num?)?.toDouble() ?? pesoPromedioGramos;
        if (finalEmpresaId.isEmpty) finalEmpresaId = lotesRes['empresa_id']?.toString() ?? '';
        if (finalUnitId.isEmpty) finalUnitId = lotesRes['unit_id']?.toString() ?? '';

        newCount = (currentPeces - cantidadPecesMuertos).clamp(0, 9999999);
        final effectivePeso = pesoPromedioGramos > 0 ? pesoPromedioGramos : currentPeso;
        newBiomass = (newCount * effectivePeso) / 1000.0;
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
        'fecha': now.toIso8601String(),
        'date': now.toIso8601String().split('T')[0],
        'hora': hourStr,
        'created_at': DateTime.now().toIso8601String(),
        'creado_en': DateTime.now().toIso8601String(),
      };

      await _supabase.from('mortalidad').insert(insertData);

      // Actualizar conteo y biomasa en lotes y sincronizar estanque considerando policultivo
      if (newCount >= 0) {
        await _supabase.from('lotes').update({
          'cantidad_actual_peces': newCount,
          'biomasa_actual_kg': newBiomass,
        }).eq('id', loteId);

        await _syncPondBiomassAndCount(estanqueId);
      }

      return record;
    } catch (e) {
      debugPrint('[PondsRepository] Error al registrar mortalidad en Supabase: $e');
      rethrow;
    }
  }

  @override
  Future<BiometriaRecord> registerBiometry({
    String? empresaId,
    String? unidadAcuicolaId,
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
    final now = fecha ?? DateTime.now();
    final hourStr = hora ?? '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}:00';
    final sampleCount = cantidadPecesMuestreados ?? 35;
    final totalCaptureKg = pesoTotalCapturaKg ?? ((sampleCount * nuevoPesoPromedioGramos) / 1000.0);

    String finalEmpresaId = empresaId ?? '';
    String finalUnitId = unidadAcuicolaId ?? '';
    final isDemo = finalEmpresaId.startsWith('c1000000-');

    double newBiomass = biomasaCalculadaKg ?? 0.0;

    if (isDemo) {
      final batchIdx = _demoBatches.indexWhere((b) => b.id == loteId || b.estanqueId == estanqueId);
      if (batchIdx != -1) {
        final batch = _demoBatches[batchIdx];
        if (finalEmpresaId.isEmpty) finalEmpresaId = batch.empresaId;
        if (finalUnitId.isEmpty) finalUnitId = batch.unidadAcuicolaId;
        if (newBiomass <= 0.0) {
          newBiomass = (batch.cantidadActualPeces * nuevoPesoPromedioGramos) / 1000.0;
        }

        _demoBatches[batchIdx] = batch.copyWith(
          pesoActualGramos: nuevoPesoPromedioGramos,
          biomasaActualKg: newBiomass,
        );

        final pondIdx = _demoPonds.indexWhere((p) => p.id == estanqueId);
        if (pondIdx != -1) {
          final totalBiomasa = _demoBatches
              .where((b) => b.estanqueId == estanqueId && b.estado == BatchStatus.active)
              .fold<double>(0.0, (acc, b) => acc + b.biomasaActualKg);
          _demoPonds[pondIdx] = _demoPonds[pondIdx].copyWith(biomasaKg: totalBiomasa);
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
      _demoBiometries.insert(0, record);
      return record;
    }

    // Para empresas reales en Supabase
    try {
      final lotesRes = await _supabase
          .from('lotes')
          .select('cantidad_actual_peces, empresa_id, unit_id')
          .eq('id', loteId)
          .maybeSingle();

      int currentPeces = 0;
      if (lotesRes != null) {
        currentPeces = (lotesRes['cantidad_actual_peces'] as num?)?.toInt() ?? 0;
        if (finalEmpresaId.isEmpty) finalEmpresaId = lotesRes['empresa_id']?.toString() ?? '';
        if (finalUnitId.isEmpty) finalUnitId = lotesRes['unit_id']?.toString() ?? '';
      }

      if (newBiomass <= 0.0 && currentPeces > 0) {
        newBiomass = (currentPeces * nuevoPesoPromedioGramos) / 1000.0;
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

      // 1. Insertar en tabla oficial biometrias
      final insertData = {
        'id': record.id,
        'empresa_id': finalEmpresaId,
        'unit_id': finalUnitId,
        'unidad_acuicola_id': finalUnitId,
        'estanque_id': estanqueId,
        'lote_id': loteId,
        'batch_id': loteId,
        'fecha': now.toIso8601String(),
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
        'created_at': DateTime.now().toIso8601String(),
        'creado_en': DateTime.now().toIso8601String(),
      };

      await _supabase.from('biometrias').insert(insertData);

      // 2. Actualizar biomasa y peso actual en lotes y estanques
      final updateBatchData = <String, dynamic>{
        'peso_actual_gramos': nuevoPesoPromedioGramos,
      };
      if (newBiomass > 0.0) {
        updateBatchData['biomasa_actual_kg'] = newBiomass;
      }
      await _supabase.from('lotes').update(updateBatchData).eq('id', loteId);

      if (newBiomass > 0.0) {
        await _syncPondBiomassAndCount(estanqueId);
      }

      return record;
    } catch (e) {
      debugPrint('[PondsRepository] Error al registrar biometría en Supabase: $e');
      rethrow;
    }
  }

  /// Recalcula y sincroniza la biomasa total y costo biológico de un estanque
  /// mediante agregación (SUM) sobre todos los lotes activos (soporte policultivo).
  Future<void> _syncPondBiomassAndCount(String estanqueId) async {
    try {
      final activeLotsRes = await _supabase
          .from('lotes')
          .select('biomasa_actual_kg, costo_inicial_alevinos, costo_acumulado_insumos, costo_acumulado_fijo, especie')
          .eq('estanque_id', estanqueId)
          .inFilter('estado', ['Activo', 'activo', 'ACTIVO']);

      double totalBiomasa = 0.0;
      double totalCosto = 0.0;
      String? primarySpecies;
      if (activeLotsRes is List) {
        for (final row in activeLotsRes) {
          totalBiomasa += (row['biomasa_actual_kg'] as num?)?.toDouble() ?? 0.0;
          totalCosto += ((row['costo_inicial_alevinos'] as num?)?.toDouble() ?? 0.0) +
              ((row['costo_acumulado_insumos'] as num?)?.toDouble() ?? 0.0) +
              ((row['costo_acumulado_fijo'] as num?)?.toDouble() ?? 0.0);
          primarySpecies ??= row['especie']?.toString();
        }
      }

      final hasActiveLots = activeLotsRes is List && activeLotsRes.isNotEmpty;

      await _supabase.from('estanques').update({
        'biomasa_kg': totalBiomasa,
        'costo_acumulado_biologico': totalCosto,
        'estado': hasActiveLots ? 'Activo' : 'Disponible',
        if (!hasActiveLots) 'especie': '' else if (primarySpecies != null) 'especie': primarySpecies,
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', estanqueId);
    } catch (e) {
      debugPrint('[PondsRepository] Error sincronizando biomasa del estanque $estanqueId: $e');
    }
  }

  @override
  Future<BiometriaRecord> updateBiometry(BiometriaRecord record) async {
    final idx = _demoBiometries.indexWhere((b) => b.id == record.id);
    if (idx != -1) {
      _demoBiometries[idx] = record;
    }
    if (record.empresaId.startsWith('c1000000-')) {
      return record;
    }

    final hourStr = record.hora ??
        '${record.fecha.hour.toString().padLeft(2, '0')}:${record.fecha.minute.toString().padLeft(2, '0')}:00';
    final updateData = {
      'estanque_id': record.estanqueId,
      'lote_id': record.loteId,
      'batch_id': record.loteId,
      'fecha': record.fecha.toIso8601String(),
      'date': record.fecha.toIso8601String().split('T')[0],
      'hora': hourStr,
      'peces_capturados': record.pecesCapturados,
      'peso_total_captura_kg': record.pesoTotalCapturaKg,
      'peso_promedio_g': record.pesoPromedioG,
      'avg_weight_gr': record.pesoPromedioG,
      'biomasa_parcial_kg': record.biomasaParcialKg,
      'total_biomass_kg': record.biomasaParcialKg,
      'longitud_cm': record.longitudCm,
      'factor_k': record.factorK,
      'gdp_g_dia': record.gdpGDia,
      'observaciones': record.observaciones,
    };

    final res = await _supabase
        .from('biometrias')
        .update(updateData)
        .eq('id', record.id)
        .eq('empresa_id', record.empresaId)
        .select()
        .single();

    await _syncPondBiomassAndCount(record.estanqueId);
    return BiometriaRecord.fromJson(res);
  }

  @override
  Future<void> deleteBiometry(BiometriaRecord record) async {
    _demoBiometries.removeWhere((b) => b.id == record.id);
    if (record.empresaId.startsWith('c1000000-')) {
      return;
    }
    final deleted = await _supabase
        .from('biometrias')
        .delete()
        .eq('id', record.id)
        .eq('empresa_id', record.empresaId)
        .select('id');

    if ((deleted as List).isEmpty) {
      throw Exception('No se encontró la biometría o no tienes permisos de administrador para eliminarla.');
    }

    // El trigger trg_sync_biometria_to_lote recalcula lotes y estanques,
    // pero reforzamos la sincronización del estanque por seguridad.
    await _syncPondBiomassAndCount(record.estanqueId);
  }

  @override
  Future<MortalityRecord> updateMortality(MortalityRecord oldRecord, MortalityRecord newRecord) async {
    final idx = _demoMortalities.indexWhere((m) => m.id == oldRecord.id);
    if (idx != -1) {
      _demoMortalities[idx] = newRecord;
    }
    if (newRecord.empresaId.startsWith('c1000000-')) {
      final bIdx = _demoBatches.indexWhere((b) => b.id == newRecord.loteId);
      if (bIdx != -1) {
        final batch = _demoBatches[bIdx];
        final delta = newRecord.cantidadPecesMuertos - oldRecord.cantidadPecesMuertos;
        final newCount = (batch.cantidadActualPeces - delta).clamp(0, batch.poblacionBaseNeta);
        final newMort = (batch.mortalidadAcumuladaPeces + delta).clamp(0, batch.poblacionBaseNeta);
        final newBio = (newCount * batch.pesoActualGramos) / 1000.0;
        _demoBatches[bIdx] = batch.copyWith(
          cantidadActualPeces: newCount,
          mortalidadAcumuladaPeces: newMort,
          biomasaActualKg: newBio,
        );
      }
      return newRecord;
    }

    final hourStr = newRecord.hora ??
        '${newRecord.fecha.hour.toString().padLeft(2, '0')}:${newRecord.fecha.minute.toString().padLeft(2, '0')}:00';

    final res = await _supabase.rpc<dynamic>(
      'update_mortality_with_lote_sync',
      params: {
        'p_mortality_id': newRecord.id,
        'p_cantidad': newRecord.cantidadPecesMuertos,
        'p_peso_promedio_g': newRecord.pesoPromedioGramos,
        'p_biomasa_perdida_kg': newRecord.biomasaPerdidaKg,
        'p_causa': newRecord.causaProbable,
        'p_observaciones': newRecord.observaciones,
        'p_fecha': newRecord.fecha.toIso8601String().split('T')[0],
        'p_hora': hourStr,
      },
    );

    if (newRecord.cantidadPecesMuertos != oldRecord.cantidadPecesMuertos) {
      await _syncPondBiomassAndCount(newRecord.estanqueId);
    }

    if (res is Map) {
      return MortalityRecord.fromJson(Map<String, dynamic>.from(res));
    }
    if (res is List && res.isNotEmpty && res.first is Map) {
      return MortalityRecord.fromJson(Map<String, dynamic>.from(res.first as Map));
    }
    return newRecord;
  }

  @override
  Future<void> deleteMortality(MortalityRecord record) async {
    _demoMortalities.removeWhere((m) => m.id == record.id);
    if (record.empresaId.startsWith('c1000000-')) {
      final bIdx = _demoBatches.indexWhere((b) => b.id == record.loteId);
      if (bIdx != -1) {
        final batch = _demoBatches[bIdx];
        final restoredCount = (batch.cantidadActualPeces + record.cantidadPecesMuertos).clamp(0, batch.poblacionBaseNeta);
        final restoredMort = (batch.mortalidadAcumuladaPeces - record.cantidadPecesMuertos).clamp(0, batch.poblacionBaseNeta);
        final restoredBio = (restoredCount * batch.pesoActualGramos) / 1000.0;
        _demoBatches[bIdx] = batch.copyWith(
          cantidadActualPeces: restoredCount,
          mortalidadAcumuladaPeces: restoredMort,
          biomasaActualKg: restoredBio,
        );
      }
      return;
    }

    // El trigger AFTER DELETE trg_mortalidad_restore_lote_on_delete reintegra atómicamente
    // los peces al lote y trg_lotes_sync_estanque_biomasa sincroniza el estanque.
    final deleted = await _supabase
        .from('mortalidad')
        .delete()
        .eq('id', record.id)
        .eq('empresa_id', record.empresaId)
        .select('id');

    if ((deleted as List).isEmpty) {
      throw Exception('No se encontró el registro de mortalidad o no tienes permisos de administrador para eliminarlo.');
    }

    await _syncPondBiomassAndCount(record.estanqueId);
  }

  @override
  Future<void> deleteTransfer(TransferRecord record) async {
    _demoTransfers.removeWhere((t) => t.id == record.id);
    if (record.empresaId.startsWith('c1000000-')) {
      return;
    }

    if (record.esDesdoble) {
      // Revertir desdoble: reintegrar peces y costos al lote origen y eliminar lote destino si existe
      if (record.loteOrigenId != null && record.loteOrigenId!.isNotEmpty) {
        final origRes = await _supabase
            .from('lotes')
            .select('cantidad_actual_peces, peso_actual_gramos, costo_inicial_alevinos, costo_acumulado_insumos, costo_acumulado_fijo')
            .eq('id', record.loteOrigenId!)
            .maybeSingle();

        if (origRes != null) {
          final currentPeces = (origRes['cantidad_actual_peces'] as num?)?.toInt() ?? 0;
          final pesoActual = (origRes['peso_actual_gramos'] as num?)?.toDouble() ?? record.pesoPromedioGramos;
          final restoredPeces = currentPeces + record.pecesTrasladados;
          final restoredBio = (restoredPeces * pesoActual) / 1000.0;

          await _supabase.from('lotes').update({
            'cantidad_actual_peces': restoredPeces,
            'biomasa_actual_kg': restoredBio,
            'costo_inicial_alevinos': ((origRes['costo_inicial_alevinos'] as num?)?.toDouble() ?? 0.0) + record.costoAlevinosTransferido,
            'costo_acumulado_insumos': ((origRes['costo_acumulado_insumos'] as num?)?.toDouble() ?? 0.0) + record.costoInsumosTransferido,
            'costo_acumulado_fijo': ((origRes['costo_acumulado_fijo'] as num?)?.toDouble() ?? 0.0) + record.costoFijoTransferido,
            'estado': 'Activo',
          }).eq('id', record.loteOrigenId!);
        }
      }

      if (record.loteDestinoId != null &&
          record.loteDestinoId!.isNotEmpty &&
          record.loteDestinoId != record.loteOrigenId) {
        await _supabase.from('lotes').delete().eq('id', record.loteDestinoId!);
      }
    } else {
      // Revertir traslado total: devolver el lote al estanque origen
      final targetBatchId = record.loteOrigenId ?? record.loteDestinoId;
      if (targetBatchId != null && targetBatchId.isNotEmpty) {
        await _supabase.from('lotes').update({
          'estanque_id': record.estanqueOrigenId,
        }).eq('id', targetBatchId);
      }
    }

    final deleted = await _supabase
        .from('traslados_lotes')
        .delete()
        .eq('id', record.id)
        .eq('empresa_id', record.empresaId)
        .select('id');

    if ((deleted as List).isEmpty) {
      throw Exception('No se encontró el traslado o no tienes permisos de administrador para revertirlo.');
    }

    await _syncPondBiomassAndCount(record.estanqueOrigenId);
    await _syncPondBiomassAndCount(record.estanqueDestinoId);
  }
}
