import '../models/water_parameter.dart';

abstract class WaterQualityRepository {
  Future<List<WaterParameter>> fetchParametersByEstanque(String empresaId, String estanqueId);
  Future<List<WaterParameter>> fetchRecentParametersByUnit(String empresaId, String unidadAcuicolaId);
  Future<WaterParameter> recordParameters(WaterParameter parameter);
}
