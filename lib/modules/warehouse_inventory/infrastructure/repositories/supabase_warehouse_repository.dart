import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:fishbit_finance/modules/warehouse_inventory/domain/models/inventory_item.dart';
import 'package:fishbit_finance/modules/warehouse_inventory/domain/models/purchase_invoice.dart';
import 'package:fishbit_finance/modules/warehouse_inventory/domain/models/biological_purchase.dart';
import 'package:fishbit_finance/modules/warehouse_inventory/domain/repositories/warehouse_repository.dart';

class SupabaseWarehouseRepository implements WarehouseRepository {
  final SupabaseClient _supabase;

  SupabaseWarehouseRepository(this._supabase);

  static final List<InventoryItem> _demoItems = [
    InventoryItem(
      id: 'i1000000-0000-0000-0000-000000000001',
      empresaId: 'c1000000-0000-0000-0000-000000000001',
      tipo: InventoryItemType.concentrado,
      nombre: 'Alimento Inicio 45% PB (Bulto 25kg)',
      cantidadOriginalKg: 1000.0,
      cantidadActualKg: 750.0,
      costoTotal: 4875000.0,
      costoUnitarioHistorico: 6500.0,
      creadoEn: DateTime.now(),
    ),
    InventoryItem(
      id: 'i1000000-0000-0000-0000-000000000002',
      empresaId: 'c1000000-0000-0000-0000-000000000001',
      tipo: InventoryItemType.concentrado,
      nombre: 'Alimento Engorde 32% PB (Bulto 40kg)',
      cantidadOriginalKg: 3000.0,
      cantidadActualKg: 2100.0,
      costoTotal: 10080000.0,
      costoUnitarioHistorico: 4800.0,
      creadoEn: DateTime.now(),
    ),
    InventoryItem(
      id: 'i1000000-0000-0000-0000-000000000003',
      empresaId: 'c1000000-0000-0000-0000-000000000001',
      tipo: InventoryItemType.insumo,
      nombre: 'Sal Marina Industrial Grado Acuícola',
      cantidadOriginalKg: 500.0,
      cantidadActualKg: 420.0,
      costoTotal: 336000.0,
      costoUnitarioHistorico: 800.0,
      creadoEn: DateTime.now(),
    ),
  ];

  static final List<PurchaseInvoice> _demoInvoices = [];
  static final List<BiologicalPurchase> _demoBioPurchases = [];

  @override
  Future<List<InventoryItem>> fetchInventory(String empresaId) async {
    if (empresaId.startsWith('c1000000-')) {
      return _demoItems;
    }
    try {
      // 1. Intentar con tabla inventory
      final res = await _supabase
          .from('inventory')
          .select('*')
          .eq('empresa_id', empresaId)
          .order('created_at', ascending: true)
          .limit(100);

      final rawList = res as List;
      if (rawList.isNotEmpty) {
        return rawList.map((row) => InventoryItem.fromJson(row as Map<String, dynamic>)).toList();
      }

      // 2. Si inventory está vacío, consultar inventario_insumos
      final resFallback = await _supabase
          .from('inventario_insumos')
          .select('*')
          .eq('empresa_id', empresaId)
          .order('creado_en', ascending: true)
          .limit(100);
      final listFallback = (resFallback as List).map((row) => InventoryItem.fromJson(row as Map<String, dynamic>)).toList();
      return listFallback;
    } catch (_) {
      return [];
    }
  }

  @override
  Future<InventoryItem> addInventoryItem(InventoryItem item) async {
    if (item.empresaId.startsWith('c1000000-')) {
      _demoItems.add(item);
      return item;
    }
    try {
      final res = await _supabase
          .from('inventory')
          .insert(item.toJson())
          .select()
          .single();

      return InventoryItem.fromJson(res);
    } catch (_) {
      _demoItems.add(item);
      return item;
    }
  }

  @override
  Future<void> updateInventoryItem(InventoryItem item) async {
    final idx = _demoItems.indexWhere((i) => i.id == item.id);
    if (idx != -1) _demoItems[idx] = item;

    if (!item.empresaId.startsWith('c1000000-')) {
      try {
        await _supabase
            .from('inventory')
            .update(item.toJson())
            .eq('id', item.id)
            .eq('empresa_id', item.empresaId);
      } catch (_) {}
    }
  }

  @override
  Future<List<PurchaseInvoice>> fetchInvoices(String empresaId, String unidadAcuicolaId) async {
    try {
      var query = _supabase.from('facturas').select('*');
      if (empresaId.isNotEmpty && !empresaId.startsWith('c1000000-')) {
        query = query.eq('empresa_id', empresaId);
      }
      if (unidadAcuicolaId.isNotEmpty) {
        query = query.eq('unidad_acuicola_sigla', unidadAcuicolaId);
      }
      final res = await query.order('creado_en', ascending: false).limit(100);

      final isMockCompany = empresaId.startsWith('c1000000-');
      final list = (res as List).map((row) => PurchaseInvoice.fromJson(row as Map<String, dynamic>)).toList();
      return (list.isNotEmpty || !isMockCompany) ? list : _demoInvoices;
    } catch (_) {
      return empresaId.startsWith('c1000000-') ? _demoInvoices : [];
    }
  }

  @override
  Future<PurchaseInvoice> createPurchaseInvoice(PurchaseInvoice invoice) async {
    try {
      final res = await _supabase
          .from('facturas')
          .insert(invoice.toJson())
          .select()
          .single();

      return PurchaseInvoice.fromJson(res);
    } catch (_) {
      _demoInvoices.add(invoice);
      return invoice;
    }
  }

  @override
  Future<List<BiologicalPurchase>> fetchBiologicalPurchases(String empresaId, String unidadAcuicolaId) async {
    try {
      var query = _supabase.from('compras_mat_biologico').select('*');
      if (unidadAcuicolaId.isNotEmpty) {
        query = query.eq('unidad_acuicola_sigla', unidadAcuicolaId);
      }
      final res = await query.order('creado_en', ascending: false).limit(100);

      final isMockCompany = empresaId.startsWith('c1000000-');
      final list = (res as List).map((row) => BiologicalPurchase.fromJson(row as Map<String, dynamic>)).toList();
      return (list.isNotEmpty || !isMockCompany) ? list : _demoBioPurchases;
    } catch (_) {
      return empresaId.startsWith('c1000000-') ? _demoBioPurchases : [];
    }
  }

  @override
  Future<BiologicalPurchase> createBiologicalPurchase(BiologicalPurchase purchase) async {
    try {
      final res = await _supabase
          .from('compras_mat_biologico')
          .insert(purchase.toJson())
          .select()
          .single();

      return BiologicalPurchase.fromJson(res);
    } catch (_) {
      _demoBioPurchases.add(purchase);
      return purchase;
    }
  }
}
