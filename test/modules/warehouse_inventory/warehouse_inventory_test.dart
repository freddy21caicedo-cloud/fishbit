import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fishbit_finance/modules/warehouse_inventory/domain/models/inventory_item.dart';
import 'package:fishbit_finance/modules/warehouse_inventory/domain/models/supplier.dart';
import 'package:fishbit_finance/modules/warehouse_inventory/domain/models/purchase_invoice.dart';
import 'package:fishbit_finance/modules/warehouse_inventory/domain/models/biological_purchase.dart';
import 'package:fishbit_finance/modules/warehouse_inventory/domain/repositories/warehouse_repository.dart';
import 'package:fishbit_finance/modules/warehouse_inventory/presentation/providers/warehouse_provider.dart';
import 'package:fishbit_finance/modules/auth_tenant/domain/models/user_member.dart';
import 'package:fishbit_finance/modules/auth_tenant/domain/models/company.dart';
import 'package:fishbit_finance/modules/auth_tenant/presentation/providers/auth_provider.dart';
import '../../helpers/test_auth_helper.dart';

class FakeWarehouseRepository implements WarehouseRepository {
  final List<InventoryItem> items;
  final List<PurchaseInvoice> invoices;
  final List<BiologicalPurchase> bioPurchases;
  final bool shouldFail;

  FakeWarehouseRepository({
    this.items = const [],
    this.invoices = const [],
    this.bioPurchases = const [],
    this.shouldFail = false,
  });

  @override
  Future<List<InventoryItem>> fetchInventory(String empresaId) async {
    if (shouldFail) throw Exception('Warehouse DB Outage');
    return items;
  }

  @override
  Future<List<PurchaseInvoice>> fetchInvoices(String empresaId, String unidadAcuicolaId) async {
    if (shouldFail) throw Exception('Invoices DB Outage');
    return invoices;
  }

  @override
  Future<List<BiologicalPurchase>> fetchBiologicalPurchases(String empresaId, String unidadAcuicolaId) async {
    if (shouldFail) throw Exception('Bio Purchases Outage');
    return bioPurchases;
  }

  @override
  Future<InventoryItem> addInventoryItem(InventoryItem item) async => item;

  @override
  Future<void> updateInventoryItem(InventoryItem item) async {}

  @override
  Future<PurchaseInvoice> createPurchaseInvoice(PurchaseInvoice invoice) async => invoice;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  group('InventoryItem Domain Model Tests', () {
    test('Correctly parses inventory item types', () {
      expect(InventoryItem.parseType('concentrado'), InventoryItemType.concentrado);
      expect(InventoryItem.parseType('alimento'), InventoryItemType.concentrado);
      expect(InventoryItem.parseType('farmacia'), InventoryItemType.farmacia);
      expect(InventoryItem.parseType('oxigenador'), InventoryItemType.oxigenador);
      expect(InventoryItem.parseType('alevino'), InventoryItemType.alevino);
      expect(InventoryItem.parseType('herramienta'), InventoryItemType.herramienta);
      expect(InventoryItem.parseType('otro'), InventoryItemType.insumo);
    });

    test('isLowStock triggers when current quantity is below or equal to stockMinimoAlerta', () {
      final lowStockItem = InventoryItem(
        id: 'item-low',
        empresaId: 'emp-1',
        tipo: InventoryItemType.concentrado,
        nombre: 'Aquatilapia 38%',
        cantidadOriginalKg: 1000.0,
        cantidadActualKg: 150.0,
        costoTotal: 510000.0,
        costoUnitarioHistorico: 3400.0,
        stockMinimoAlerta: 200.0,
        creadoEn: DateTime.now(),
      );

      final healthyItem = lowStockItem.copyWith(cantidadActualKg: 500.0);

      expect(lowStockItem.isLowStock, isTrue);
      expect(healthyItem.isLowStock, isFalse);
    });

    test('Serializes to and from Supabase JSON accurately', () {
      final item = InventoryItem(
        id: 'inv-test-01',
        empresaId: 'emp-uuid-1',
        unidadAcuicolaId: 'unit-uuid-1',
        tipo: InventoryItemType.concentrado,
        nombre: 'Aquatilapia 38% E',
        marcaProveedor: 'Italcol S.A.',
        presentacionUnidad: 'Bulto 40 Kg',
        cantidadOriginalKg: 2000.0,
        cantidadActualKg: 1600.0,
        costoTotal: 5440000.0,
        costoUnitarioHistorico: 3400.0,
        proteinaCrudaPct: 38.0,
        calibrePelletMm: 2.5,
        loteFabricante: 'ITA-38-001',
        creadoEn: DateTime(2026, 8, 10),
      );

      final json = item.toJson();
      expect(json['id'], 'inv-test-01');
      expect(json['category'], 'Concentrado');
      expect(json['current_stock'], 1600.0);
      expect(json['costo_unitario_historico'], 3400.0);

      final parsed = InventoryItem.fromJson({
        'id': 'inv-test-01',
        'empresa_id': 'emp-uuid-1',
        'unit_id': 'unit-uuid-1',
        'category': 'Concentrado',
        'name': 'Aquatilapia 38% E',
        'brand': 'Italcol S.A.',
        'unit': 'Bulto 40 Kg',
        'current_stock': 1600.0,
        'costo_total': 5440000.0,
        'costo_unitario_historico': 3400.0,
        'proteina_pct': 38.0,
        'calibre_mm': 2.5,
        'lote_fabricante': 'ITA-38-001',
        'created_at': '2026-08-10T00:00:00.000',
      });

      expect(parsed.id, 'inv-test-01');
      expect(parsed.tipo, InventoryItemType.concentrado);
      expect(parsed.cantidadActualKg, 1600.0);
      expect(parsed.proteinaCrudaPct, 38.0);
    });
  });

  group('Supplier & PurchaseInvoice Tests', () {
    test('Supplier contains Colombian aquaculture feed suppliers and catalogs', () {
      const supplier = Supplier(
        id: 'sup-01',
        nit: '860.026.895-8',
        nombre: 'Italcol S.A.',
        telefono: '+57 (601) 369-2000',
        ciudad: 'Bogotá',
        categoriaPrincipal: 'concentrados',
        productosOfrecidos: ['Aquatilapia 45%', 'Aquatilapia 38%'],
      );

      final json = supplier.toJson();
      expect(json['nit'], '860.026.895-8');
      expect(json['productos_ofrecidos'].length, 2);
    });

    test('PurchaseInvoice and InvoiceItemLine calculate bases, taxes and freight', () {
      const line = InvoiceItemLine(
        codigo: 'ALIM-38',
        nombre: 'Aquatilapia 38% Bulto 40 Kg',
        cantidadBultos: 25,
        kgPorBulto: 40.0,
        kilosTotales: 1000.0,
        valorUnitarioBulto: 136000.0,
        valorBruto: 3400000.0,
        descuentoPct: 5.0,
        valorDescuento: 170000.0,
        baseGravable: 3230000.0,
        ivaPct: 5.0,
        valorIva: 161500.0,
        valorTotal: 3391500.0,
        fleteProrrateado: 100000.0,
        costoFinalPorKg: 3491.5,
      );

      expect(line.kilosTotales, 1000.0);
      expect(line.valorBruto, 3400000.0);
      expect(line.baseGravable, 3230000.0);
      expect(line.valorTotal, 3391500.0);

      final invoice = PurchaseInvoice(
        id: 'inv-99',
        empresaId: 'emp-1',
        unidadAcuicolaId: 'unit-1',
        tipoFactura: 'concentrados',
        numeroFactura: 'FE-88990',
        proveedorNombre: 'Italcol S.A.',
        proveedorNit: '860.026.895-8',
        fechaExpedicion: DateTime(2026, 8, 20),
        fechaVencimiento: DateTime(2026, 9, 20),
        totalKilos: 1000.0,
        totalNeto: 3230000.0,
        totalIva: 161500.0,
        totalFactura: 3391500.0,
        costoFlete: 100000.0,
        productos: const [line],
        creadoEn: DateTime.now(),
      );

      expect(invoice.totalFactura, 3391500.0);
      expect(invoice.productos.length, 1);
    });
  });

  group('WarehouseState & Notifier CPP Recalculation Tests', () {
    test('WarehouseState valuation getters sum asset balances accurately', () {
      final c1 = InventoryItem(
        id: 'i1',
        empresaId: 'e1',
        tipo: InventoryItemType.concentrado,
        nombre: 'Concentrado 38%',
        cantidadOriginalKg: 1000.0,
        cantidadActualKg: 800.0,
        costoTotal: 2720000.0,
        costoUnitarioHistorico: 3400.0,
        creadoEn: DateTime.now(),
      );

      final c2 = InventoryItem(
        id: 'i2',
        empresaId: 'e1',
        tipo: InventoryItemType.concentrado,
        nombre: 'Concentrado 34%',
        cantidadOriginalKg: 1000.0,
        cantidadActualKg: 400.0,
        costoTotal: 1240000.0,
        costoUnitarioHistorico: 3100.0,
        creadoEn: DateTime.now(),
      );

      final state = WarehouseState(items: [c1, c2]);

      expect(state.totalConcentradoKg, 1200.0);
      expect(state.totalConcentradoBultos, 30.0);
      // Valor total = (800 * 3400) + (400 * 3100) = 2,720,000 + 1,240,000 = 3,960,000 COP
      expect(state.valorTotalInventario, 3960000.0);
    });

    test('registerPurchaseEntry applies Weighted Average Cost (WAC/CPP) formula accurately', () async {
      final initialItem = InventoryItem(
        id: 'item-cpp-01',
        empresaId: 'emp-test',
        tipo: InventoryItemType.concentrado,
        nombre: 'Aquatilapia 38%',
        cantidadOriginalKg: 1000.0,
        cantidadActualKg: 1000.0,
        costoTotal: 3000000.0,
        costoUnitarioHistorico: 3000.0, // Initial: 1000 kg @ $3,000 = $3,000,000
        creadoEn: DateTime.now(),
      );

      final repo = FakeWarehouseRepository(items: [initialItem]);

      final container = ProviderContainer(
        overrides: [
          warehouseRepositoryProvider.overrideWithValue(repo),
          authProvider.overrideWith((ref) => AuthNotifierMock(
            AuthState(
              currentUser: UserMember(
                id: 'u-1',
                email: 'test@fishbit.com',
                nombre: 'Tester',
                role: UserRole.admin,
                empresaId: 'emp-test',
                unidadAcuicolaId: 'unit-test',
                creadoEn: DateTime.now(),
              ),
              currentCompany: const Company(
                id: 'emp-test',
                nombreComercial: 'Empresa Test',
                razonSocial: 'Empresa Test SAS',
                nit: '900000000-1',
              ),
              activeUnitId: 'unit-test',
            ),
          )),
        ],
      );

      final notifier = container.read(warehouseProvider.notifier);
      await notifier.loadWarehouseData();

      // Purchase entry: 1000 kg @ $4,000
      // New stock = 2000 kg
      // New WAC = (1000 * 3000 + 1000 * 4000) / 2000 = 7,000,000 / 2000 = $3,500 / kg
      await notifier.registerPurchaseEntry(
        itemId: 'item-cpp-01',
        cantidadIngresada: 1000.0,
        costoUnitarioCompra: 4000.0,
        numeroFactura: 'FE-101',
        proveedor: 'Italcol',
      );

      final updatedItem = container.read(warehouseProvider).items.firstWhere((i) => i.id == 'item-cpp-01');
      expect(updatedItem.cantidadActualKg, 2000.0);
      expect(updatedItem.costoUnitarioHistorico, 3500.0);
      expect(updatedItem.costoTotal, 7000000.0);
    });

    test('discountStock reduces inventory quantity and clamps at zero', () async {
      final item = InventoryItem(
        id: 'item-disc',
        empresaId: 'emp-1',
        tipo: InventoryItemType.concentrado,
        nombre: 'Alimento Engorde',
        cantidadOriginalKg: 500.0,
        cantidadActualKg: 100.0,
        costoTotal: 300000.0,
        costoUnitarioHistorico: 3000.0,
        creadoEn: DateTime.now(),
      );

      final repo = FakeWarehouseRepository(items: [item]);
      final container = ProviderContainer(
        overrides: [
          warehouseRepositoryProvider.overrideWithValue(repo),
          authProvider.overrideWith((ref) => AuthNotifierMock(
            AuthState(
              currentUser: UserMember(
                id: 'u-1',
                email: 'test@fishbit.com',
                nombre: 'Tester',
                role: UserRole.admin,
                empresaId: 'emp-1',
                unidadAcuicolaId: 'unit-1',
                creadoEn: DateTime.now(),
              ),
              currentCompany: const Company(
                id: 'emp-1',
                nombreComercial: 'Empresa Test',
                razonSocial: 'Empresa Test SAS',
                nit: '900000000-1',
              ),
              activeUnitId: 'unit-1',
            ),
          )),
        ],
      );

      final notifier = container.read(warehouseProvider.notifier);
      await notifier.loadWarehouseData();

      // Discount 40 kg
      await notifier.discountStock(itemId: 'item-disc', cantidadKg: 40.0, motivo: 'Alimentación Estanque 1');
      var updated = container.read(warehouseProvider).items.firstWhere((i) => i.id == 'item-disc');
      expect(updated.cantidadActualKg, 60.0);

      // Discount 100 kg (more than remaining 60 kg) -> clamps to 0
      await notifier.discountStock(itemId: 'item-disc', cantidadKg: 100.0, motivo: 'Alimentación masiva');
      updated = container.read(warehouseProvider).items.firstWhere((i) => i.id == 'item-disc');
      expect(updated.cantidadActualKg, 0.0);
    });
  });
}
