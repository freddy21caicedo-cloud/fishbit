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
      if (rawList.isNotEmpty) {
        return rawList.map((row) => FeedingRecord.fromJson(row as Map<String, dynamic>)).toList();
      }
      return _demoRecords;
    } catch (_) {
      return _demoRecords;
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
  }) async {
    final costoTotal = kgConsumidos * costoUnitarioAlimento;
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
      fecha: now,
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

    try {
      // 1. Guardar registro en alimentacion_diaria
      final insertData = {
        'id': record.id,
        'empresa_id': empresaId,
        'unit_id': unidadAcuicolaId,
        'unidad_acuicola_id': unidadAcuicolaId,
        'estanque_id': estanqueId,
        'lote_id': loteId,
        if (insumoId != null) 'insumo_id': insumoId,
        'cantidad_consumida_kg': kgConsumidos,
        'costo_calculado': costoTotal,
        'fecha': now.toIso8601String().split('T')[0],
        'creado_en': now.toIso8601String(),
      };

      try {
        await _supabase.from('alimentacion_diaria').insert(insertData);
      } catch (_) {
        // Fallback a tabla alimentacion si fuera necesario
        try {
          await _supabase.from('alimentacion').insert({
            'estanque_id': estanqueId,
            'lote_id': loteId,
            'cantidad_kg': kgConsumidos,
            'costo_total': costoTotal,
            'fecha': now.toIso8601String().split('T')[0],
          });
        } catch (_) {}
      }

      // 2. Descontar stock del insumo de bodega si existe insumoId
      if (insumoId != null && insumoId.isNotEmpty) {
        try {
          final item = await _supabase.from('inventory').select('current_stock').eq('id', insumoId).maybeSingle();
          if (item != null) {
            final curr = (item['current_stock'] as num?)?.toDouble() ?? 0.0;
            final updatedStock = (curr - kgConsumidos).clamp(0.0, double.infinity);
            await _supabase.from('inventory').update({'current_stock': updatedStock}).eq('id', insumoId);
          }
        } catch (_) {}
      }

      _eventBus.fire(DailyFeedingRecordedEvent(
        estanqueId: estanqueId,
        loteId: loteId,
        kgConsumidos: kgConsumidos,
        costoTotal: costoTotal,
      ));

      return record;
    } catch (_) {
      _demoRecords.insert(0, record);
      _eventBus.fire(DailyFeedingRecordedEvent(
        estanqueId: estanqueId,
        loteId: loteId,
        kgConsumidos: kgConsumidos,
        costoTotal: costoTotal,
      ));
      return record;
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
