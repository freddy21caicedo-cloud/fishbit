import 'package:uuid/uuid.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:fishbit_finance/core/events/app_event_bus.dart';
import 'package:fishbit_finance/modules/feeding_nutrition/domain/models/feeding_record.dart';
import 'package:fishbit_finance/modules/feeding_nutrition/domain/models/nutrition_table.dart';
import 'package:fishbit_finance/modules/feeding_nutrition/domain/repositories/nutrition_repository.dart';

class SupabaseNutritionRepository implements NutritionRepository {
  final SupabaseClient _supabase;
  final AppEventBus _eventBus;

  SupabaseNutritionRepository(this._supabase, this._eventBus);

  static final List<FeedingRecord> _demoRecords = [
    FeedingRecord(
      id: 'f1000000-0000-0000-0000-000000000001',
      empresaId: 'c1000000-0000-0000-0000-000000000001',
      unidadAcuicolaId: 'u1000000-0000-0000-0000-000000000001',
      estanqueId: 'p1000000-0000-0000-0000-000000000001',
      loteId: 'b1000000-0000-0000-0000-000000000001',
      cantidadConsumidaKg: 45.0,
      costoCalculado: 216000.0,
      fecha: DateTime.now(),
      creadoEn: DateTime.now(),
    ),
  ];

  static final List<NutritionTable> _demoTables = [];

  @override
  Future<List<FeedingRecord>> fetchFeedingRecords(String empresaId, String unidadAcuicolaId) async {
    if (empresaId.startsWith('c1000000-')) {
      return _demoRecords;
    }
    try {
      final res = await _supabase
          .from('alimentacion_diaria')
          .select('*')
          .eq('empresa_id', empresaId)
          .order('fecha', ascending: false)
          .limit(100);

      final rawList = res as List;
      return rawList.map((row) => FeedingRecord.fromJson(row as Map<String, dynamic>)).toList();
    } catch (_) {
      return [];
    }
  }

  @override
  Future<FeedingRecord> recordFeeding({
    required String empresaId,
    required String unidadAcuicolaId,
    required String estanqueId,
    required String loteId,
    String? insumoId,
    required double kgConsumidos,
    required double costoUnitarioAlimento,
    DateTime? fecha,
  }) async {
    final costoTotal = kgConsumidos * costoUnitarioAlimento;
    final recordDate = fecha ?? DateTime.now();
    final now = DateTime.now();
    final record = FeedingRecord(
      id: const Uuid().v4(),
      empresaId: empresaId,
      unidadAcuicolaId: unidadAcuicolaId,
      estanqueId: estanqueId,
      loteId: loteId,
      insumoId: insumoId,
      cantidadConsumidaKg: kgConsumidos,
      costoCalculado: costoTotal,
      fecha: recordDate,
      creadoEn: now,
    );

    if (empresaId.startsWith('c1000000-')) {
      _demoRecords.insert(0, record);
      _eventBus.fire(DailyFeedingRecordedEvent(
        estanqueId: estanqueId,
        loteId: loteId,
        kgConsumidos: kgConsumidos,
        costoTotal: costoTotal,
      ));
      return record;
    }

    // 1. Registrar alimentación y descontar stock de forma atómica vía RPC en Supabase
    final res = await _supabase.rpc<dynamic>(
      'record_daily_feeding_with_stock',
      params: {
        'p_id': record.id,
        'p_empresa_id': empresaId,
        'p_unidad_acuicola_id': unidadAcuicolaId,
        'p_estanque_id': estanqueId,
        'p_lote_id': loteId,
        'p_insumo_id': insumoId,
        'p_cantidad_kg': kgConsumidos,
        'p_costo_unitario': costoUnitarioAlimento,
        'p_fecha': recordDate.toIso8601String().split('T')[0],
      },
    );

    final savedRecord = res is Map
        ? FeedingRecord.fromJson(Map<String, dynamic>.from(res))
        : (res is List && res.isNotEmpty && res.first is Map
            ? FeedingRecord.fromJson(Map<String, dynamic>.from(res.first as Map))
            : record);

    _eventBus.fire(DailyFeedingRecordedEvent(
      estanqueId: estanqueId,
      loteId: loteId,
      kgConsumidos: kgConsumidos,
      costoTotal: savedRecord.costoCalculado,
    ));

    return savedRecord;
  }

  @override
  Future<FeedingRecord> updateFeeding(FeedingRecord record) async {
    final idx = _demoRecords.indexWhere((r) => r.id == record.id);
    if (idx != -1) {
      _demoRecords[idx] = record;
    }
    if (record.empresaId.startsWith('c1000000-')) {
      return record;
    }

    final unitCost = record.cantidadConsumidaKg > 0
        ? (record.costoCalculado / record.cantidadConsumidaKg)
        : 0.0;

    final res = await _supabase.rpc<dynamic>(
      'update_daily_feeding_with_stock',
      params: {
        'p_feeding_id': record.id,
        'p_new_kg': record.cantidadConsumidaKg,
        'p_costo_unitario': unitCost,
        'p_new_insumo_id': record.insumoId,
        'p_new_fecha': record.fecha.toIso8601String().split('T')[0],
      },
    );

    if (res is Map) {
      return FeedingRecord.fromJson(Map<String, dynamic>.from(res));
    }
    if (res is List && res.isNotEmpty && res.first is Map) {
      return FeedingRecord.fromJson(Map<String, dynamic>.from(res.first as Map));
    }
    return record;
  }

  @override
  Future<void> deleteFeeding(String recordId, String empresaId) async {
    _demoRecords.removeWhere((r) => r.id == recordId);
    if (empresaId.startsWith('c1000000-')) {
      return;
    }
    final deleted = await _supabase
        .from('alimentacion_diaria')
        .delete()
        .eq('id', recordId)
        .eq('empresa_id', empresaId)
        .select('id');

    if ((deleted as List).isEmpty) {
      throw Exception('No se encontró el registro o no tienes permisos de administrador para eliminarlo.');
    }
  }

  @override
  Future<List<NutritionTable>> fetchNutritionTables(String empresaId) async {
    if (empresaId.startsWith('c1000000-')) {
      return _demoTables;
    }
    try {
      final res = await _supabase
          .from('tablas_alimentacion')
          .select('*')
          .eq('empresa_id', empresaId)
          .order('creado_en', ascending: true);

      final list = (res as List).map((row) => NutritionTable.fromJson(row as Map<String, dynamic>)).toList();
      return list.isNotEmpty ? list : _demoTables;
    } catch (_) {
      return _demoTables;
    }
  }

  @override
  Future<void> saveNutritionTable(NutritionTable table) async {
    if (table.empresaId.startsWith('c1000000-')) {
      final idx = _demoTables.indexWhere((t) => t.id == table.id);
      if (idx != -1) {
        _demoTables[idx] = table;
      } else {
        _demoTables.add(table);
      }
      return;
    }
    try {
      await _supabase.from('tablas_alimentacion').upsert(table.toJson());
    } catch (_) {}
  }

  @override
  Future<void> deleteNutritionTable(String tableId) async {
    _demoTables.removeWhere((t) => t.id == tableId);
    try {
      await _supabase.from('tablas_alimentacion').delete().eq('id', tableId);
    } catch (_) {}
  }
}
