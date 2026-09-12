import '../models/inventory_item.dart';
import '../models/purchase_invoice.dart';
import '../models/biological_purchase.dart';
import '../models/supplier.dart';

abstract class WarehouseRepository {
  Future<List<InventoryItem>> fetchInventory(String empresaId);
  Future<InventoryItem> addInventoryItem(InventoryItem item);
  Future<void> updateInventoryItem(InventoryItem item);

  Future<List<PurchaseInvoice>> fetchInvoices(String empresaId, String unidadAcuicolaId);
  Future<PurchaseInvoice> createPurchaseInvoice(PurchaseInvoice invoice);

  Future<List<BiologicalPurchase>> fetchBiologicalPurchases(String empresaId, String unidadAcuicolaId);
  Future<BiologicalPurchase> createBiologicalPurchase(BiologicalPurchase purchase);

  Future<List<Supplier>> fetchCustomSuppliers(String empresaId);
  Future<Supplier> createSupplier(Supplier supplier);
}
