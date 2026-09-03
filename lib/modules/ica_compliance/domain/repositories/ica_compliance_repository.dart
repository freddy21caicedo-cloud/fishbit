import 'package:fishbit_finance/modules/ica_compliance/domain/models/ica_personal_record.dart';
import 'package:fishbit_finance/modules/ica_compliance/domain/models/ica_vehiculo_record.dart';
import 'package:fishbit_finance/modules/ica_compliance/domain/models/ica_necropsia_record.dart';

abstract class IcaComplianceRepository {
  // F-01: Personal y Visitas
  Future<List<IcaPersonalRecord>> getPersonalRecords({required String empresaId, required String unidadId});
  Future<bool> savePersonalRecord(IcaPersonalRecord record);

  // F-02: Vehículos y Rodiluvios
  Future<List<IcaVehiculoRecord>> getVehiculoRecords({required String empresaId, required String unidadId});
  Future<bool> saveVehiculoRecord(IcaVehiculoRecord record);

  // F-03: Necropsias y Hallazgos
  Future<List<IcaNecropsiaRecord>> getNecropsiaRecords({required String empresaId, required String unidadId});
  Future<bool> saveNecropsiaRecord(IcaNecropsiaRecord record);
}
