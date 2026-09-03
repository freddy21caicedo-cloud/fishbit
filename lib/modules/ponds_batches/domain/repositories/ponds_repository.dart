import '../models/pond.dart';
import '../models/fish_batch.dart';
import '../models/biometria_record.dart';
import '../models/mortality_record.dart';
import '../models/transfer_record.dart';

abstract class PondsRepository {
  Future<List<Pond>> fetchPondsByUnit(String empresaId, String unidadAcuicolaId);
  Future<Pond> createPond(Pond pond);
  Future<void> updatePond(Pond pond);
  Future<void> deletePond(String pondId);

  Future<List<FishBatch>> fetchBatchesByUnit(String empresaId, String unidadAcuicolaId);
  Future<FishBatch> createBatch(FishBatch batch);
  Future<void> updateBatch(FishBatch batch);
  
  /// Realiza un traslado o desdoble atómico entre dos estanques
  Future<void> transferOrSplitBatch({
    required String batchOrigenId,
    required String estanqueOrigenId,
    required String estanqueDestinoId,
    required int pecesTrasladados,
    required double biomasaTrasladadaKg,
    required bool esDesdoble,
    required String nuevoCodigoLote,
    String? registradoPor,
  });

  /// Consulta registros históricos de auditoría de traslados/desdobles
  Future<List<TransferRecord>> fetchTransfersByUnit(
    String empresaId,
    String unidadAcuicolaId, {
    String? pondId,
    String? batchId,
  });

  /// Consulta registros históricos de biometrías por empresa/unidad acuícola
  Future<List<BiometriaRecord>> fetchBiometriesByUnit(
    String empresaId,
    String unidadAcuicolaId, {
    String? pondId,
    String? batchId,
  });

  /// Consulta registros históricos de mortalidad por empresa/unidad acuícola
  Future<List<MortalityRecord>> fetchMortalityByUnit(
    String empresaId,
    String unidadAcuicolaId, {
    String? pondId,
    String? batchId,
  });

  /// Registra mortandad y recalcula población y biomasa del lote/estanque
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
  });

  /// Registra muestreo biométrico y recalcula GDP y biomasa del lote/estanque
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
  });
}
