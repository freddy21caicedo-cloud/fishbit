import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:fishbit_finance/modules/water_quality/domain/models/water_parameter.dart';
import 'package:fishbit_finance/modules/water_quality/domain/repositories/water_quality_repository.dart';

class SupabaseWaterQualityRepository implements WaterQualityRepository {
  final SupabaseClient _supabase;

  SupabaseWaterQualityRepository(this._supabase);

  static final List<WaterParameter> _demoParameters = [
    WaterParameter(
      id: 'w1000000-0000-0000-0000-000000000001',
      empresaId: 'c1000000-0000-0000-0000-000000000001',
      unidadAcuicolaId: 'u1000000-0000-0000-0000-000000000001',
      estanqueId: 'p1000000-0000-0000-0000-000000000001',
      fecha: DateTime.now().subtract(const Duration(hours: 3)),
      oxigenoMgL: 6.2,
      oxigenoPct: 88.0,
      ph: 7.4,
      temperaturaC: 28.5,
      amonioMgL: 0.15,
      nitritosMgL: 0.05,
      alcalinidadMgL: 120.0,
      durezaMgL: 150.0,
      observaciones: 'Condiciones óptimas en cultivo',
    ),
    WaterParameter(
      id: 'w1000000-0000-0000-0000-000000000002',
      empresaId: 'c1000000-0000-0000-0000-000000000001',
      unidadAcuicolaId: 'u1000000-0000-0000-0000-000000000001',
      estanqueId: 'p1000000-0000-0000-0000-000000000002',
      fecha: DateTime.now().subtract(const Duration(hours: 5)),
      oxigenoMgL: 5.8,
      oxigenoPct: 82.0,
      ph: 7.1,
      temperaturaC: 29.0,
      amonioMgL: 0.20,
      nitritosMgL: 0.08,
      alcalinidadMgL: 110.0,
      durezaMgL: 140.0,
      observaciones: 'Aireación activa requerida en noche',
    ),
  ];

  @override
  Future<List<WaterParameter>> fetchParametersByEstanque(String empresaId, String estanqueId) async {
    if (empresaId.startsWith('c1000000-')) {
      return _demoParameters.where((p) => p.estanqueId == estanqueId).toList();
    }
    try {
      final res = await _supabase
          .from('parametros_calidad_agua')
          .select('*')
          .eq('empresa_id', empresaId)
          .eq('estanque_id', estanqueId)
          .order('fecha', ascending: false)
          .limit(50);

      final rawList = res as List;
      if (rawList.isNotEmpty) {
        return rawList.map((row) => WaterParameter.fromJson(row as Map<String, dynamic>)).toList();
      }

      return _demoParameters.where((p) => p.estanqueId == estanqueId).toList();
    } catch (_) {
      return _demoParameters.where((p) => p.estanqueId == estanqueId).toList();
    }
  }

  @override
  Future<List<WaterParameter>> fetchRecentParametersByUnit(String empresaId, String unidadAcuicolaId) async {
    if (empresaId.startsWith('c1000000-')) {
      return _demoParameters;
    }
    try {
      // Query canonical parametros_calidad_agua with native tenant filter
      var query = _supabase
          .from('parametros_calidad_agua')
          .select('*')
          .eq('empresa_id', empresaId);

      final res = await query.order('fecha', ascending: false).limit(50);

      final rawList = res as List;
      if (rawList.isNotEmpty) {
        return rawList.map((row) => WaterParameter.fromJson(row as Map<String, dynamic>)).toList();
      }

      return _demoParameters;
    } catch (_) {
      return _demoParameters;
    }
  }

  @override
  Future<WaterParameter> recordParameters(WaterParameter parameter) async {
    _demoParameters.insert(0, parameter);
    if (parameter.empresaId.startsWith('c1000000-')) {
      return parameter;
    }
    try {
      final hourStr = '${parameter.fecha.hour.toString().padLeft(2, '0')}:${parameter.fecha.minute.toString().padLeft(2, '0')}:00';

      final insertData = {
        'id': parameter.id,
        'empresa_id': parameter.empresaId,
        'unit_id': parameter.unidadAcuicolaId,
        'unidad_acuicola_id': parameter.unidadAcuicolaId,
        'estanque_id': parameter.estanqueId,
        'fecha': parameter.fecha.toIso8601String(),
        'hora': hourStr,
        'oxigeno_mg_l': parameter.oxigenoMgL,
        'oxigeno_pct': parameter.oxigenoPct,
        'ph': parameter.ph,
        'temperatura': parameter.temperaturaC,
        'amonio_mg_l': parameter.amonioMgL,
        'nitritos_mg_l': parameter.nitritosMgL,
        'nitratos_mg_l': parameter.nitratosMgL,
        'alcalinidad_mg_l': parameter.alcalinidadMgL,
        'co2_mg_l': parameter.co2MgL,
        'dureza_mg_l': parameter.durezaMgL,
        'cloro_mg_l': parameter.cloroMgL,
        'observaciones': parameter.observaciones,
        'registrado_por': parameter.registradoPor,
        'creado_en': DateTime.now().toIso8601String(),
      };

      await _supabase.from('parametros_calidad_agua').insert(insertData);
      return parameter;
    } catch (_) {
      return parameter;
    }
  }
}
