import '../models/equipment_asset.dart';

abstract class EquipmentRepository {
  Future<List<EquipmentAsset>> fetchEquipment(String empresaId, String unidadAcuicolaId);
  Future<EquipmentAsset> createEquipment(EquipmentAsset equipment);
  Future<void> updateEquipment(EquipmentAsset equipment);
}
