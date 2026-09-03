import '../models/feeding_record.dart';
import '../models/nutrition_table.dart';

abstract class NutritionRepository {
  Future<List<FeedingRecord>> fetchFeedingRecords(String empresaId, String unidadAcuicolaId);
  Future<FeedingRecord> recordFeeding({
    required String empresaId,
    required String unidadAcuicolaId,
    required String estanqueId,
    required String loteId,
    String? insumoId,
    required double kgConsumidos,
    required double costoUnitarioAlimento,
  });

  Future<List<NutritionTable>> fetchNutritionTables(String empresaId);
  Future<void> saveNutritionTable(NutritionTable table);
  Future<void> deleteNutritionTable(String tableId);
}
