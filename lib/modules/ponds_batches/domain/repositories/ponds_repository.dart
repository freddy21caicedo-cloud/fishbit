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
    double? pesoPromedioGramos,
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
  });

  /// Actualiza una biometría existente y resincroniza lote y estanque
  Future<BiometriaRecord> updateBiometry(BiometriaRecord record);

  /// Elimina una biometría y resincroniza el peso/biomasa del lote y estanque
  Future<void> deleteBiometry(BiometriaRecord record);

  /// Actualiza un registro de mortalidad y ajusta la población viva del lote y estanque
  Future<MortalityRecord> updateMortality(MortalityRecord oldRecord, MortalityRecord newRecord);

  /// Elimina un registro de mortalidad y reintegra los peces al lote y estanque
  Future<void> deleteMortality(MortalityRecord record);

  /// Revierte y elimina un traslado o desdoble de lotes
  Future<void> deleteTransfer(TransferRecord record);
}
