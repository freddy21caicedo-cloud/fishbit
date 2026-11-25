import 'package:flutter_test/flutter_test.dart';
import 'package:fishbit_finance/modules/ponds_batches/domain/models/fish_batch.dart';
import 'package:fishbit_finance/modules/warehouse_inventory/presentation/providers/warehouse_provider.dart';

void main() {
  group('Blindaje de stock al editar facturas de alevinos', () {
    test('Editar factura ya sembrada al 100% sin cambiar cantidad mantiene stock en 0', () {
      final result = WarehouseNotifier.computeUpdatedStockForInvoiceEdit(
        itemName: 'Alevinos de Tilapia Roja',
        currentStock: 0,
        oldInvoiceQty: 35000,
        newInvoiceQty: 35000,
      );

      expect(result, 0.0);
    });

    test('Reducir cantidad por debajo de lo ya sembrado lanza excepción', () {
      expect(
        () => WarehouseNotifier.computeUpdatedStockForInvoiceEdit(
          itemName: 'Alevinos de Tilapia Roja',
          currentStock: 0,
          oldInvoiceQty: 35000,
          newInvoiceQty: 20000,
        ),
        throwsException,
      );
    });

    test('Aumentar cantidad en factura ya sembrada solo suma la diferencia real', () {
      final result = WarehouseNotifier.computeUpdatedStockForInvoiceEdit(
        itemName: 'Alevinos de Tilapia Roja',
        currentStock: 0,
        oldInvoiceQty: 35000,
        newInvoiceQty: 40000,
      );

      expect(result, 5000.0);
    });

    test('Reducir cantidad dentro del saldo no sembrado ajusta correctamente', () {
      final result = WarehouseNotifier.computeUpdatedStockForInvoiceEdit(
        itemName: 'Alevinos de Tilapia Roja',
        currentStock: 10000,
        oldInvoiceQty: 35000,
        newInvoiceQty: 30000,
      );

      expect(result, 5000.0);
    });

    test('FishBatch serializa y deserializa inventory_item_id correctamente', () {
      final now = DateTime(2026, 11, 19);
      final batch = FishBatch(
        id: 'batch-1',
        empresaId: 'emp-1',
        unidadAcuicolaId: 'unit-1',
        estanqueId: 'pond-1',
        inventoryItemId: 'inv-alevinos-001',
        codigoLote: 'LOT-E01-20261119-TILAPIA',
        especie: 'Tilapia Roja',
        cantidadInicialPeces: 35000,
        cantidadActualPeces: 35000,
        fechaSiembra: now,
        creadoEn: now,
      );

      final json = batch.toJson();
      expect(json['inventory_item_id'], 'inv-alevinos-001');

      final parsed = FishBatch.fromJson(json);
      expect(parsed.inventoryItemId, 'inv-alevinos-001');
    });
  });
}
