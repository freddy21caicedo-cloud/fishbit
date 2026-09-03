import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:fishbit_finance/modules/ica_compliance/domain/models/ica_personal_record.dart';
import 'package:fishbit_finance/modules/ica_compliance/domain/models/ica_vehiculo_record.dart';
import 'package:fishbit_finance/modules/ica_compliance/domain/models/ica_necropsia_record.dart';
import 'package:fishbit_finance/modules/ica_compliance/domain/repositories/ica_compliance_repository.dart';

class SupabaseIcaComplianceRepository implements IcaComplianceRepository {
  final SupabaseClient _supabase;

  SupabaseIcaComplianceRepository(this._supabase);

  // -------------------------------------------------------------
  // F-01: Personal y Visitas
  // -------------------------------------------------------------
  @override
  Future<List<IcaPersonalRecord>> getPersonalRecords({required String empresaId, required String unidadId}) async {
    try {
      final response = await _supabase
          .from('bioseguridad_personal')
          .select()
          .eq('empresa_id', empresaId)
          .order('fecha', ascending: false)
          .limit(100);

      final list = (response as List).map((json) => IcaPersonalRecord.fromJson(json as Map<String, dynamic>)).toList();
      await _cacheLocally('cache_ica_personal_$unidadId', list.map((e) => e.toJson()).toList());
      return list;
    } catch (e) {
      debugPrint('Error obteniendo registros personal ICA (usando cache local): $e');
      final local = await _readLocalCache('cache_ica_personal_$unidadId');
      return local.map((json) => IcaPersonalRecord.fromJson(json)).toList();
    }
  }

  @override
  Future<bool> savePersonalRecord(IcaPersonalRecord record) async {
    try {
      await _supabase.from('bioseguridad_personal').insert(record.toJson());
      await _appendLocalCache('cache_ica_personal_${record.unidadAcuicolaId}', record.toJson());
      return true;
    } catch (e) {
      debugPrint('Error guardando en Supabase bioseguridad_personal, guardando offline: $e');
      await _appendLocalCache('cache_ica_personal_${record.unidadAcuicolaId}', record.toJson());
      return true;
    }
  }

  // -------------------------------------------------------------
  // F-02: Vehículos y Rodiluvios
  // -------------------------------------------------------------
  @override
  Future<List<IcaVehiculoRecord>> getVehiculoRecords({required String empresaId, required String unidadId}) async {
    try {
      final response = await _supabase
          .from('bioseguridad_vehiculos')
          .select()
          .eq('empresa_id', empresaId)
          .order('fecha', ascending: false)
          .limit(100);

      final list = (response as List).map((json) => IcaVehiculoRecord.fromJson(json as Map<String, dynamic>)).toList();
      await _cacheLocally('cache_ica_vehiculos_$unidadId', list.map((e) => e.toJson()).toList());
      return list;
    } catch (e) {
      debugPrint('Error obteniendo registros vehiculos ICA (usando cache local): $e');
      final local = await _readLocalCache('cache_ica_vehiculos_$unidadId');
      return local.map((json) => IcaVehiculoRecord.fromJson(json)).toList();
    }
  }

  @override
  Future<bool> saveVehiculoRecord(IcaVehiculoRecord record) async {
    try {
      await _supabase.from('bioseguridad_vehiculos').insert(record.toJson());
      await _appendLocalCache('cache_ica_vehiculos_${record.unidadAcuicolaId}', record.toJson());
      return true;
    } catch (e) {
      debugPrint('Error guardando en Supabase bioseguridad_vehiculos, guardando offline: $e');
      await _appendLocalCache('cache_ica_vehiculos_${record.unidadAcuicolaId}', record.toJson());
      return true;
    }
  }

  // -------------------------------------------------------------
  // F-03: Necropsias y Hallazgos
  // -------------------------------------------------------------
  @override
  Future<List<IcaNecropsiaRecord>> getNecropsiaRecords({required String empresaId, required String unidadId}) async {
    try {
      final response = await _supabase
          .from('sanidad_necropsias')
          .select()
          .eq('empresa_id', empresaId)
          .order('fecha', ascending: false)
          .limit(100);

      final list = (response as List).map((json) => IcaNecropsiaRecord.fromJson(json as Map<String, dynamic>)).toList();
      await _cacheLocally('cache_ica_necropsias_$unidadId', list.map((e) => e.toJson()).toList());
      return list;
    } catch (e) {
      debugPrint('Error obteniendo registros necropsias ICA (usando cache local): $e');
      final local = await _readLocalCache('cache_ica_necropsias_$unidadId');
      return local.map((json) => IcaNecropsiaRecord.fromJson(json)).toList();
    }
  }

  @override
  Future<bool> saveNecropsiaRecord(IcaNecropsiaRecord record) async {
    try {
      await _supabase.from('sanidad_necropsias').insert(record.toJson());
      await _appendLocalCache('cache_ica_necropsias_${record.unidadAcuicolaId}', record.toJson());
      return true;
    } catch (e) {
      debugPrint('Error guardando en Supabase sanidad_necropsias, guardando offline: $e');
      await _appendLocalCache('cache_ica_necropsias_${record.unidadAcuicolaId}', record.toJson());
      return true;
    }
  }

  // -------------------------------------------------------------
  // Helper Cache Local Offline
  // -------------------------------------------------------------
  Future<void> _cacheLocally(String key, List<Map<String, dynamic>> items) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(key, jsonEncode(items));
    } catch (_) {}
  }

  Future<List<Map<String, dynamic>>> _readLocalCache(String key) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final str = prefs.getString(key);
      if (str == null) return [];
      final decoded = jsonDecode(str) as List;
      return decoded.map((e) => Map<String, dynamic>.from(e as Map)).toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> _appendLocalCache(String key, Map<String, dynamic> item) async {
    try {
      final items = await _readLocalCache(key);
      items.insert(0, item);
      await _cacheLocally(key, items);
    } catch (_) {}
  }
}
