import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fishbit_finance/core/network/supabase_client_provider.dart';
import 'package:fishbit_finance/modules/auth_tenant/presentation/providers/auth_provider.dart';
import 'package:fishbit_finance/modules/warehouse_inventory/domain/models/inventory_item.dart';
import 'package:fishbit_finance/modules/warehouse_inventory/domain/models/supplier.dart';
import 'package:fishbit_finance/modules/warehouse_inventory/domain/models/purchase_invoice.dart';
import 'package:fishbit_finance/modules/warehouse_inventory/domain/models/biological_purchase.dart';
import 'package:fishbit_finance/modules/warehouse_inventory/domain/repositories/warehouse_repository.dart';
import 'package:fishbit_finance/modules/warehouse_inventory/infrastructure/repositories/supabase_warehouse_repository.dart';

import 'package:fishbit_finance/modules/warehouse_inventory/domain/services/product_catalog_service.dart';

final warehouseRepositoryProvider = Provider<WarehouseRepository>((ref) {
  final supabase = ref.watch(supabaseClientProvider);
  return SupabaseWarehouseRepository(supabase);
});

// Proveedores Colombianos Oficiales Pre-cargados
final List<Supplier> kDefaultSuppliers = [
  ...ProductCatalogService.kOfficialFeedSuppliers,
  ProductCatalogService.kSanoaSupplier,
];

// Inventario Inicial Acuícola Demo V2.0
final List<InventoryItem> kDefaultInventoryItems = [
  InventoryItem(
    id: 'inv-c-01',
    empresaId: 'c1000000-0000-0000-0000-000000000001',
    tipo: InventoryItemType.concentrado,
    nombre: 'Aquatilapia 38% E (Levante I)',
    marcaProveedor: 'Italcol S.A.',
    presentacionUnidad: 'Bulto 40 Kg',
    cantidadOriginalKg: 2000.0, // 50 bultos
    cantidadActualKg: 1450.0,
    costoTotal: 4930000.0,
    costoUnitarioHistorico: 3400.0, // $3.400 / kg ($136.000 / bulto)
    proteinaCrudaPct: 38.0,
    calibrePelletMm: 2.0,
    loteFabricante: 'LOT-ITA-38-992',
    stockMinimoAlerta: 400.0,
    creadoEn: DateTime.now().subtract(const Duration(days: 10)),
  ),
  InventoryItem(
    id: 'inv-c-02',
    empresaId: 'c1000000-0000-0000-0000-000000000001',
    tipo: InventoryItemType.concentrado,
    nombre: 'Aquatilapia 34% E (Levante II)',
    marcaProveedor: 'Italcol S.A.',
    presentacionUnidad: 'Bulto 40 Kg',
    cantidadOriginalKg: 3000.0,
    cantidadActualKg: 2200.0,
    costoTotal: 6820000.0,
    costoUnitarioHistorico: 3100.0, // $3.100 / kg ($124.000 / bulto)
    proteinaCrudaPct: 34.0,
    calibrePelletMm: 3.0,
    loteFabricante: 'LOT-ITA-34-401',
    stockMinimoAlerta: 500.0,
    creadoEn: DateTime.now().subtract(const Duration(days: 8)),
  ),
  InventoryItem(
    id: 'inv-c-03',
    empresaId: 'c1000000-0000-0000-0000-000000000001',
    tipo: InventoryItemType.concentrado,
    nombre: 'Solla Mojarra 45% (Alevines)',
    marcaProveedor: 'Solla S.A.',
    presentacionUnidad: 'Bulto 40 Kg',
    cantidadOriginalKg: 800.0,
    cantidadActualKg: 640.0,
    costoTotal: 3072000.0,
    costoUnitarioHistorico: 4800.0,
    proteinaCrudaPct: 45.0,
    calibrePelletMm: 1.2,
    loteFabricante: 'SOL-MOJ-45-12',
    stockMinimoAlerta: 200.0,
    creadoEn: DateTime.now().subtract(const Duration(days: 15)),
  ),
  InventoryItem(
    id: 'inv-ins-01',
    empresaId: 'c1000000-0000-0000-0000-000000000001',
    tipo: InventoryItemType.insumo,
    nombre: 'Cal Agrícola (Carbonato de Calcio)',
    marcaProveedor: 'Suministros Acuícolas del Caribe',
    presentacionUnidad: 'Saco 40 Kg',
    cantidadOriginalKg: 1200.0,
    cantidadActualKg: 920.0,
    costoTotal: 460000.0,
    costoUnitarioHistorico: 500.0,
    stockMinimoAlerta: 200.0,
    creadoEn: DateTime.now().subtract(const Duration(days: 20)),
  ),
  InventoryItem(
    id: 'inv-ins-02',
    empresaId: 'c1000000-0000-0000-0000-000000000001',
    tipo: InventoryItemType.insumo,
    nombre: 'Sal Marina Pura no Yodada',
    marcaProveedor: 'Suministros Acuícolas del Caribe',
    presentacionUnidad: 'Saco 50 Kg',
    cantidadOriginalKg: 1000.0,
    cantidadActualKg: 750.0,
    costoTotal: 675000.0,
    costoUnitarioHistorico: 900.0,
    stockMinimoAlerta: 150.0,
    creadoEn: DateTime.now().subtract(const Duration(days: 18)),
  ),
  InventoryItem(
    id: 'inv-ins-03',
    empresaId: 'c1000000-0000-0000-0000-000000000001',
    tipo: InventoryItemType.insumo,
    nombre: 'Melaza de Caña Concentrada',
    marcaProveedor: 'Bio-Acuáticos de Colombia',
    presentacionUnidad: 'Caneca 25 Kg',
    cantidadOriginalKg: 250.0,
    cantidadActualKg: 175.0,
    costoTotal: 262500.0,
    costoUnitarioHistorico: 1500.0,
    stockMinimoAlerta: 50.0,
    creadoEn: DateTime.now().subtract(const Duration(days: 12)),
  ),
  InventoryItem(
    id: 'inv-ale-01',
    empresaId: 'c1000000-0000-0000-0000-000000000001',
    tipo: InventoryItemType.alevino,
    nombre: 'Alevinos Tilapia Roja Revertida (Semilla)',
    marcaProveedor: 'Estación Piscícola El Porvenir',
    presentacionUnidad: 'Millar (1.000 pcs)',
    cantidadOriginalKg: 20000.0, // 20.000 peces
    cantidadActualKg: 20000.0,
    costoTotal: 3600000.0,
    costoUnitarioHistorico: 180.0, // $180 por alevino
    especieAlevino: 'Tilapia Roja',
    stockMinimoAlerta: 5000.0,
    creadoEn: DateTime.now().subtract(const Duration(days: 5)),
  ),
  InventoryItem(
    id: 'inv-oxi-01',
    empresaId: 'c1000000-0000-0000-0000-000000000001',
    tipo: InventoryItemType.oxigenador,
    nombre: 'Aireador de Paletas 2.0 HP (4 Paletas)',
    marcaProveedor: 'AquaPower Equipos y Motores',
    presentacionUnidad: 'Unidad Equipo',
    cantidadOriginalKg: 4.0, // 4 aireadores
    cantidadActualKg: 4.0,
    costoTotal: 9600000.0,
    costoUnitarioHistorico: 2400000.0,
    potenciaHp: 2.0,
    faseElectrica: 'Trifásico 220V',
    stockMinimoAlerta: 1.0,
    creadoEn: DateTime.now().subtract(const Duration(days: 60)),
  ),
  InventoryItem(
    id: 'inv-far-01',
    empresaId: 'c1000000-0000-0000-0000-000000000001',
    tipo: InventoryItemType.farmacia,
    nombre: 'Oxitetraciclina Polvo Soluble 50%',
    marcaProveedor: 'Tecnoaqua S.A.S.',
    presentacionUnidad: 'Bolsa 5 Kg',
    cantidadOriginalKg: 15.0, // 3 bolsas
    cantidadActualKg: 10.0,
    costoTotal: 950000.0,
    costoUnitarioHistorico: 95000.0,
    principioActivo: 'Oxitetraciclina Clorhidrato 500mg/g',
    diasRetiroSanitario: 21, // 21 días de retiro obligatorio ICA
    loteFabricante: 'VET-OXI-2026-B',
    stockMinimoAlerta: 5.0,
    creadoEn: DateTime.now().subtract(const Duration(days: 25)),
  ),
  InventoryItem(
    id: 'inv-far-02',
    empresaId: 'c1000000-0000-0000-0000-000000000001',
    tipo: InventoryItemType.farmacia,
    nombre: 'Formalina Grado Terapéutico 37%',
    marcaProveedor: 'Tecnoaqua S.A.S.',
    presentacionUnidad: 'Galón 4 Litros',
    cantidadOriginalKg: 20.0, // 5 galones
    cantidadActualKg: 12.0,
    costoTotal: 420000.0,
    costoUnitarioHistorico: 35000.0,
    principioActivo: 'Formaldehído 37% acuoso',
    diasRetiroSanitario: 0, // Tratamiento tópico de agua/baño
    loteFabricante: 'FORM-TEC-440',
    stockMinimoAlerta: 4.0,
    creadoEn: DateTime.now().subtract(const Duration(days: 30)),
  ),
];

class WarehouseState {
  final bool isLoading;
  final List<InventoryItem> items;
  final List<Supplier> suppliers;
  final List<PurchaseInvoice> invoices;
  final List<BiologicalPurchase> bioPurchases;
  final String? errorMessage;

  const WarehouseState({
    this.isLoading = false,
    this.items = const [],
    this.suppliers = const [],
    this.invoices = const [],
    this.bioPurchases = const [],
    this.errorMessage,
  });

  // Métricas Financieras y Físicas
  double get valorTotalInventario => items.fold(0.0, (sum, i) => sum + (i.cantidadActualKg * i.costoUnitarioHistorico));
  
  double get totalConcentradoKg => items
      .where((i) => i.tipo == InventoryItemType.concentrado)
      .fold(0.0, (sum, i) => sum + i.cantidadActualKg);
  
  // Alias de compatibilidad
  double get totalAlimentoKg => totalConcentradoKg;
  
  double get totalConcentradoBultos => totalConcentradoKg / 40.0;

  double get valorTotalConcentrados => items
      .where((i) => i.tipo == InventoryItemType.concentrado)
      .fold(0.0, (sum, i) => sum + (i.cantidadActualKg * i.costoUnitarioHistorico));

  int get totalEquiposActivos => items
      .where((i) => i.tipo == InventoryItemType.oxigenador)
      .fold(0, (sum, i) => sum + i.cantidadActualKg.toInt());

  int get totalItemsAlertaStock => items.where((i) => i.isLowStock).length;

  /// Estimar días de autonomía en base al consumo diario total de la granja (ej. 75 kg/día)
  /// Obtener items o compras de alevinos/larvas disponibles para una especie
  List<InventoryItem> getAlevinosForSpecies(String especie) {
    final cleanEspecie = especie.trim().toLowerCase();
    // Extraer palabras clave de especie (ej. "trucha", "tilapia", "cachama")
    final speciesKeywords = cleanEspecie
        .split(RegExp(r'\s+'))
        .where((k) => k.length > 3)
        .toList();

    return items.where((i) {
      final isAlevino = i.tipo == InventoryItemType.alevino;
      if (!isAlevino) return false;

      final itemName = i.nombre.toLowerCase();
      final itemSpecies = (i.especieAlevino ?? '').toLowerCase();

      final directMatch = itemName.contains(cleanEspecie) ||
          itemSpecies.contains(cleanEspecie) ||
          cleanEspecie.contains(itemName);

      if (directMatch) return true;

      // Coincidencia por palabra clave principal (ej: "trucha")
      return speciesKeywords.any((k) => itemName.contains(k) || itemSpecies.contains(k));
    }).toList();
  }

  /// Total de alevinos disponibles en almacén para una especie
  double getTotalAlevinosDisponibles(String especie) {
    final alevinos = getAlevinosForSpecies(especie);
    return alevinos.fold(0.0, (sum, i) => sum + i.cantidadActualKg);
  }

  /// Costo unitario promedio o del lote disponible
  double getCostoUnitarioAlevino(String especie) {
    final alevinos = getAlevinosForSpecies(especie);
    if (alevinos.isEmpty) return 0.0;
    final totalStock = getTotalAlevinosDisponibles(especie);
    if (totalStock <= 0) return alevinos.first.costoUnitarioHistorico;
    final totalValor = alevinos.fold(0.0, (sum, i) => sum + (i.cantidadActualKg * i.costoUnitarioHistorico));
    return totalValor / totalStock;
  }

  WarehouseState copyWith({
    bool? isLoading,
    List<InventoryItem>? items,
    List<Supplier>? suppliers,
    List<PurchaseInvoice>? invoices,
    List<BiologicalPurchase>? bioPurchases,
    String? errorMessage,
  }) {
    return WarehouseState(
      isLoading: isLoading ?? this.isLoading,
      items: items ?? this.items,
      suppliers: suppliers ?? this.suppliers,
      invoices: invoices ?? this.invoices,
      bioPurchases: bioPurchases ?? this.bioPurchases,
      errorMessage: errorMessage,
    );
  }
}

class WarehouseNotifier extends StateNotifier<WarehouseState> {
  final WarehouseRepository _repository;
  final Ref _ref;

  WarehouseNotifier(this._repository, this._ref)
      : super(const WarehouseState(isLoading: true)) {
    loadWarehouseData();
    _ref.listen<AuthState>(authProvider, (prev, next) {
      if (prev?.currentUser?.id != next.currentUser?.id ||
          prev?.currentCompany?.id != next.currentCompany?.id ||
          prev?.activeUnitId != next.activeUnitId ||
          (prev?.currentUser == null && next.currentUser != null)) {
        loadWarehouseData();
      }
    });
  }

  Future<void> loadWarehouseData() async {
    final auth = _ref.read(authProvider);
    final user = auth.currentUser;
    final unitId = auth.activeUnitId ?? user?.unidadAcuicolaId ?? user?.empresaId;
    final empresaId = auth.currentCompany?.id ?? user?.empresaId ?? unitId;

    if (empresaId == null || empresaId.isEmpty) {
      state = state.copyWith(
        isLoading: false,
        suppliers: kDefaultSuppliers,
        items: kDefaultInventoryItems,
      );
      return;
    }

    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final remoteItems = await _repository.fetchInventory(empresaId);
      final invoices = await _repository.fetchInvoices(empresaId, unitId ?? empresaId);
      final bioPurchases = await _repository.fetchBiologicalPurchases(empresaId, unitId ?? empresaId);
      final customSuppliers = await _repository.fetchCustomSuppliers(empresaId);

      final isMockCompany = empresaId.startsWith('c1000000-');
      // Solo inicializar con catálogo demo si es una empresa de demostración/mock explícita
      final finalItems = (remoteItems.isNotEmpty || !isMockCompany) ? remoteItems : kDefaultInventoryItems;
      final mergedSuppliers = [...kDefaultSuppliers, ...customSuppliers];

      state = state.copyWith(
        isLoading: false,
        items: finalItems,
        suppliers: mergedSuppliers,
        invoices: invoices,
        bioPurchases: bioPurchases,
      );
    } catch (e) {
      final isMock = empresaId.startsWith('c1000000-');
      state = state.copyWith(
        isLoading: false,
        items: isMock ? kDefaultInventoryItems : [],
        suppliers: kDefaultSuppliers,
        errorMessage: e.toString(),
      );
    }
  }

  Future<void> addSupplier(Supplier supplier) async {
    try {
      final created = await _repository.createSupplier(supplier);
      state = state.copyWith(suppliers: [...state.suppliers, created]);
    } catch (_) {
      state = state.copyWith(suppliers: [...state.suppliers, supplier]);
    }
  }

  Future<void> addInventory(InventoryItem item) async {
    try {
      final created = await _repository.addInventoryItem(item);
      state = state.copyWith(items: [...state.items, created]);
    } catch (e) {
      // Fallback local en memoria
      state = state.copyWith(items: [...state.items, item]);
    }
  }

  /// Registrar una entrada o compra con recálculo de Costo Promedio Ponderado (CPP)
  Future<void> registerPurchaseEntry({
    required String itemId,
    required double cantidadIngresada,
    required double costoUnitarioCompra,
    required String? numeroFactura,
    required String? proveedor,
  }) async {
    final idx = state.items.indexWhere((i) => i.id == itemId);
    if (idx != -1) {
      final item = state.items[idx];
      final stockAnterior = item.cantidadActualKg;
      final stockNuevo = stockAnterior + cantidadIngresada;
      
      // Fórmula CPP / WAC
      final nuevoCostoUnitario = stockNuevo > 0
          ? ((stockAnterior * item.costoUnitarioHistorico) + (cantidadIngresada * costoUnitarioCompra)) / stockNuevo
          : costoUnitarioCompra;
      
      final nuevoCostoTotal = stockNuevo * nuevoCostoUnitario;

      final updated = item.copyWith(
        cantidadActualKg: stockNuevo,
        costoUnitarioHistorico: nuevoCostoUnitario,
        costoTotal: nuevoCostoTotal,
      );

      try {
        await _repository.updateInventoryItem(updated);
      } catch (_) {}

      final list = [...state.items];
      list[idx] = updated;
      state = state.copyWith(items: list);
    }
  }

  Future<void> discountStock({
    required String itemId,
    required double cantidadKg,
    required String motivo,
  }) async {
    final idx = state.items.indexWhere((i) => i.id == itemId);
    if (idx != -1) {
      final item = state.items[idx];
      final remanente = (item.cantidadActualKg - cantidadKg).clamp(0.0, 999999.0);
      final updated = item.copyWith(
        cantidadActualKg: remanente,
        costoTotal: remanente * item.costoUnitarioHistorico,
      );
      try {
        await _repository.updateInventoryItem(updated);
      } catch (_) {}

      final list = [...state.items];
      list[idx] = updated;
      state = state.copyWith(items: list);
    }
  }

  Future<void> registerInvoiceWithItem(PurchaseInvoice invoice, InventoryItem item) async {
    await registerMultiItemInvoice(invoice, [item]);
  }

  /// Registra una Factura Multi-Ítem (ej. Facturas de 30 toneladas de Italcol con 4+ tipos de concentrado)
  Future<void> registerMultiItemInvoice(PurchaseInvoice invoice, List<InventoryItem> itemsToProcess) async {
    try {
      final createdInv = await _repository.createPurchaseInvoice(invoice);

      final updatedItemsList = List<InventoryItem>.from(state.items);

      for (final newItem in itemsToProcess) {
        final existingIdx = updatedItemsList.indexWhere((i) =>
            i.nombre.trim().toLowerCase() == newItem.nombre.trim().toLowerCase() &&
            i.tipo == newItem.tipo);

        if (existingIdx != -1) {
          // Actualizar stock y CPP del item existente
          final existing = updatedItemsList[existingIdx];
          final stockAnterior = existing.cantidadActualKg;
          final stockNuevo = stockAnterior + newItem.cantidadActualKg;
          final nuevoCostoUnitario = stockNuevo > 0
              ? ((stockAnterior * existing.costoUnitarioHistorico) + (newItem.cantidadActualKg * newItem.costoUnitarioHistorico)) / stockNuevo
              : newItem.costoUnitarioHistorico;
          final nuevoCostoTotal = stockNuevo * nuevoCostoUnitario;

          final updated = existing.copyWith(
            cantidadActualKg: stockNuevo,
            costoUnitarioHistorico: nuevoCostoUnitario,
            costoTotal: nuevoCostoTotal,
            loteFabricante: newItem.loteFabricante ?? existing.loteFabricante,
          );

          try {
            await _repository.updateInventoryItem(updated);
          } catch (_) {}

          updatedItemsList[existingIdx] = updated;
        } else {
          // Crear nuevo item de inventario
          try {
            final created = await _repository.addInventoryItem(newItem);
            updatedItemsList.add(created);
          } catch (_) {
            updatedItemsList.add(newItem);
          }
        }
      }

      state = state.copyWith(
        invoices: [createdInv, ...state.invoices],
        items: updatedItemsList,
      );
    } catch (_) {
      state = state.copyWith(
        invoices: [invoice, ...state.invoices],
        items: [...state.items, ...itemsToProcess],
      );
    }
  }

  /// Descontar alevinos utilizados durante la siembra de un lote
  Future<void> discountAlevinosSiembra({
    required String especie,
    required double cantidadPeces,
    String? specificItemId,
  }) async {
    if (specificItemId != null) {
      await discountStock(
        itemId: specificItemId,
        cantidadKg: cantidadPeces,
        motivo: 'Siembra de lote ($especie)',
      );
      return;
    }

    final alevinos = state.getAlevinosForSpecies(especie);
    double pendiente = cantidadPeces;

    for (final item in alevinos) {
      if (pendiente <= 0) break;
      if (item.cantidadActualKg <= 0) continue;

      final aDescontar = pendiente > item.cantidadActualKg ? item.cantidadActualKg : pendiente;
      await discountStock(
        itemId: item.id,
        cantidadKg: aDescontar,
        motivo: 'Siembra de lote ($especie)',
      );
      pendiente -= aDescontar;
    }
  }
}

final warehouseProvider = StateNotifierProvider<WarehouseNotifier, WarehouseState>((ref) {
  final repo = ref.watch(warehouseRepositoryProvider);
  return WarehouseNotifier(repo, ref);
});

