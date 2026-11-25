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

final List<PurchaseInvoice> kDefaultPurchaseInvoices = [
  PurchaseInvoice(
    id: 'fac-demo-01',
    empresaId: 'c1000000-0000-0000-0000-000000000001',
    unidadAcuicolaId: 'u1000000-0000-0000-0000-000000000001',
    unidadAcuicolaSigla: 'PRIN',
    tipoFactura: 'concentrados',
    numeroFactura: 'FACT-884210',
    proveedorNombre: 'Italcol S.A.',
    proveedorNit: '860.026.895-8',
    fechaExpedicion: DateTime.now().subtract(const Duration(days: 10)),
    fechaVencimiento: DateTime.now().add(const Duration(days: 20)),
    esCredito: true,
    diasCredito: 30,
    totalKilos: 2000.0,
    totalNeto: 6476190.0,
    totalIva: 323810.0,
    totalFactura: 6800000.0,
    costoFlete: 180000.0,
    estadoPago: 'Pendiente',
    placaVehiculo: 'WPA-412',
    productos: [
      const InvoiceItemLine(
        codigo: 'ITA-38',
        nombre: 'Aquatilapia 38% E (Levante I)',
        loteFabricante: 'LOT-ITA-38-992',
        cantidadBultos: 50,
        kgPorBulto: 40.0,
        kilosTotales: 2000.0,
        valorUnitarioBulto: 129524.0,
        valorBruto: 6476190.0,
        baseGravable: 6476190.0,
        ivaPct: 5.0,
        valorIva: 323810.0,
        valorTotal: 6800000.0,
      ),
    ],
    creadoEn: DateTime.now().subtract(const Duration(days: 10)),
  ),
  PurchaseInvoice(
    id: 'fac-demo-02',
    empresaId: 'c1000000-0000-0000-0000-000000000001',
    unidadAcuicolaId: 'u1000000-0000-0000-0000-000000000001',
    unidadAcuicolaSigla: 'PRIN',
    tipoFactura: 'insumos',
    numeroFactura: 'FACT-319044',
    proveedorNombre: 'Suministros Acuícolas del Caribe',
    proveedorNit: '900.412.881-3',
    fechaExpedicion: DateTime.now().subtract(const Duration(days: 18)),
    fechaVencimiento: DateTime.now().subtract(const Duration(days: 18)),
    esCredito: false,
    diasCredito: 0,
    totalKilos: 1200.0,
    totalNeto: 600000.0,
    totalIva: 0.0,
    totalFactura: 600000.0,
    costoFlete: 45000.0,
    estadoPago: 'Paga',
    productos: [
      const InvoiceItemLine(
        codigo: 'CAL-40',
        nombre: 'Cal Agrícola (Carbonato de Calcio)',
        cantidadBultos: 30,
        kgPorBulto: 40.0,
        kilosTotales: 1200.0,
        valorUnitarioBulto: 20000.0,
        valorBruto: 600000.0,
        baseGravable: 600000.0,
        ivaPct: 0.0,
        valorIva: 0.0,
        valorTotal: 600000.0,
      ),
    ],
    creadoEn: DateTime.now().subtract(const Duration(days: 18)),
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

    final allAlevinos = items.where((i) => i.tipo == InventoryItemType.alevino).toList();
    if (allAlevinos.isEmpty) return [];

    final matched = allAlevinos.where((i) {
      final itemName = i.nombre.toLowerCase();
      final itemSpecies = (i.especieAlevino ?? '').toLowerCase();

      final directMatch = itemName.contains(cleanEspecie) ||
          itemSpecies.contains(cleanEspecie) ||
          cleanEspecie.contains(itemName);

      if (directMatch) return true;

      // Coincidencia por palabra clave principal (ej: "trucha")
      return speciesKeywords.any((k) => itemName.contains(k) || itemSpecies.contains(k));
    }).toList();

    if (matched.isNotEmpty) return matched;

    // Fallback de resiliencia: si los ítems de alevino en bodega no especifican otra especie rival,
    // o solo hay un lote de alevinos disponible en la empresa, asociarlo para no bloquear al productor.
    final rivalKeywords = ['trucha', 'tilapia', 'cachama', 'bocachico', 'salmón', 'bagre', 'carpa', 'camarón'];
    final requestedRivals = rivalKeywords.where((rk) => !cleanEspecie.contains(rk)).toList();

    final fallback = allAlevinos.where((i) {
      final name = i.nombre.toLowerCase();
      final spec = (i.especieAlevino ?? '').toLowerCase();
      // Si el ítem no contiene explícitamente una especie rival distinta a la solicitada
      final hasOtherSpecies = requestedRivals.any((rk) => name.contains(rk) || spec.contains(rk));
      return !hasOtherSpecies;
    }).toList();

    return fallback;
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
        invoices: kDefaultPurchaseInvoices,
      );
      return;
    }

    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final remoteItems = await _repository.fetchInventory(empresaId);
      final invoices = await _repository.fetchInvoices(empresaId, unitId ?? empresaId);
      final bioPurchases = await _repository.fetchBiologicalPurchases(empresaId, unitId ?? empresaId);
      var customSuppliers = await _repository.fetchCustomSuppliers(empresaId);

      final isMockCompany = empresaId.startsWith('c1000000-');
      if (!isMockCompany && customSuppliers.isEmpty) {
        await _repository.ensureDefaultSuppliersSeeded(empresaId);
        customSuppliers = await _repository.fetchCustomSuppliers(empresaId);
      }

      // Enriquecer catálogo de Sanoa si viene desde BD sin productosOfrecidos
      final hydratedSuppliers = customSuppliers.map((s) {
        if ((s.nit == '1094283101' || s.nombre.toLowerCase() == 'sanoa') &&
            s.productosOfrecidos.isEmpty) {
          return s.copyWith(productosOfrecidos: ProductCatalogService.kSanoaSupplier.productosOfrecidos);
        }
        return s;
      }).toList();

      // Solo inicializar con catálogo demo si es una empresa de demostración/mock explícita
      final finalItems = (remoteItems.isNotEmpty || !isMockCompany) ? remoteItems : kDefaultInventoryItems;
      final finalInvoices = (invoices.isNotEmpty || !isMockCompany) ? invoices : kDefaultPurchaseInvoices;
      final mergedSuppliers = isMockCompany
          ? [...kDefaultSuppliers, ...hydratedSuppliers]
          : (hydratedSuppliers.isNotEmpty ? hydratedSuppliers : kDefaultSuppliers);

      state = state.copyWith(
        isLoading: false,
        items: finalItems,
        suppliers: mergedSuppliers,
        invoices: finalInvoices,
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

  /// Reintegra existencias al inventario cuando se edita o elimina un consumo en Bitácora
  Future<void> restoreStock({
    required String itemId,
    required double cantidadKg,
  }) async {
    if (cantidadKg <= 0) return;
    if (state.items.isEmpty || !state.items.any((i) => i.id == itemId)) {
      await loadWarehouseData();
    }
    final idx = state.items.indexWhere((i) => i.id == itemId);
    if (idx != -1) {
      final item = state.items[idx];
      final nuevoStock = item.cantidadActualKg + cantidadKg;
      final updated = item.copyWith(
        cantidadActualKg: nuevoStock,
        costoTotal: nuevoStock * item.costoUnitarioHistorico,
      );
      await _repository.updateInventoryItem(updated);

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
    if (state.items.isEmpty || !state.items.any((i) => i.id == itemId)) {
      await loadWarehouseData();
    }
    final idx = state.items.indexWhere((i) => i.id == itemId);
    if (idx != -1) {
      final item = state.items[idx];
      final remanente = (item.cantidadActualKg - cantidadKg).clamp(0.0, double.infinity);
      final updated = item.copyWith(
        cantidadActualKg: remanente,
        costoTotal: remanente * item.costoUnitarioHistorico,
      );
      await _repository.updateInventoryItem(updated);

      final list = [...state.items];
      list[idx] = updated;
      state = state.copyWith(items: list);
    }
  }

  /// Calcula el nuevo stock al editar una factura usando el delta real (nueva - anterior).
  /// Evita regenerar stock fantasma cuando una factura ya fue consumida o sembrada,
  /// y bloquea reducciones por debajo de lo ya consumido/sembrado.
  static double computeUpdatedStockForInvoiceEdit({
    required String itemName,
    required double currentStock,
    required double oldInvoiceQty,
    required double newInvoiceQty,
  }) {
    final delta = newInvoiceQty - oldInvoiceQty;
    final projected = currentStock + delta;
    if (projected < -0.0001) {
      throw Exception(
        'No se puede reducir "$itemName" en ${(-delta).toStringAsFixed(0)} unidades porque parte o la totalidad ya fue sembrada o consumida (disponible actual: ${currentStock.toStringAsFixed(0)}).',
      );
    }
    return projected < 0 ? 0.0 : projected;
  }

  Future<void> registerInvoiceWithItem(PurchaseInvoice invoice, InventoryItem item) async {
    await registerMultiItemInvoice(invoice, [item]);
  }

  /// Registra una Factura Multi-Ítem (ej. Facturas de 30 toneladas de Italcol con 4+ tipos de concentrado)
  Future<void> registerMultiItemInvoice(PurchaseInvoice invoice, List<InventoryItem> itemsToProcess) async {
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

        await _repository.updateInventoryItem(updated);
        updatedItemsList[existingIdx] = updated;
      } else {
        // Crear nuevo item de inventario
        final created = await _repository.addInventoryItem(newItem);
        updatedItemsList.add(created);
      }
    }

    state = state.copyWith(
      invoices: [createdInv, ...state.invoices],
      items: updatedItemsList,
    );
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

  /// Actualizar una factura de compra existente y ajustar stock diferencial real (nueva - anterior)
  Future<void> updatePurchaseInvoice(
    PurchaseInvoice oldInvoice,
    PurchaseInvoice newInvoice,
    List<InventoryItem> newItems,
  ) async {
    if (state.items.isEmpty) {
      await loadWarehouseData();
    }
    final updatedItemsList = List<InventoryItem>.from(state.items);

    // Agrupar cantidades anteriores y nuevas por nombre normalizado
    final Map<String, double> oldQtyByKey = {};
    final Map<String, String> displayNameByKey = {};
    for (final oldLine in oldInvoice.productos) {
      final key = oldLine.nombre.trim().toLowerCase();
      oldQtyByKey[key] = (oldQtyByKey[key] ?? 0.0) + oldLine.kilosTotales;
      displayNameByKey[key] = oldLine.nombre;
    }

    final Map<String, double> newQtyByKey = {};
    final Map<String, InventoryItem> newItemByKey = {};
    for (final newItem in newItems) {
      final key = newItem.nombre.trim().toLowerCase();
      newQtyByKey[key] = (newQtyByKey[key] ?? 0.0) + newItem.cantidadActualKg;
      newItemByKey[key] = newItem;
      displayNameByKey[key] = newItem.nombre;
    }

    final allKeys = <String>{...oldQtyByKey.keys, ...newQtyByKey.keys};

    // 1. Pre-validación: bloquear reducciones por debajo de lo ya consumido/sembrado antes de mutar BD
    for (final key in allKeys) {
      final oldQty = oldQtyByKey[key] ?? 0.0;
      final newQty = newQtyByKey[key] ?? 0.0;
      final newItem = newItemByKey[key];
      final idx = updatedItemsList.indexWhere(
        (i) =>
            i.nombre.trim().toLowerCase() == key &&
            (newItem == null || i.tipo == newItem.tipo),
      );
      if (idx != -1) {
        computeUpdatedStockForInvoiceEdit(
          itemName: displayNameByKey[key] ?? updatedItemsList[idx].nombre,
          currentStock: updatedItemsList[idx].cantidadActualKg,
          oldInvoiceQty: oldQty,
          newInvoiceQty: newQty,
        );
      }
    }

    // 2. Persistir la factura actualizada en Supabase
    final updatedInv = await _repository.updatePurchaseInvoice(newInvoice);

    // 3. Aplicar deltas reales en inventario
    for (final key in allKeys) {
      final oldQty = oldQtyByKey[key] ?? 0.0;
      final newQty = newQtyByKey[key] ?? 0.0;
      final delta = newQty - oldQty;
      final newItem = newItemByKey[key];

      final idx = updatedItemsList.indexWhere(
        (i) =>
            i.nombre.trim().toLowerCase() == key &&
            (newItem == null || i.tipo == newItem.tipo),
      );

      if (idx != -1) {
        final existing = updatedItemsList[idx];
        final stockAnterior = existing.cantidadActualKg;
        final stockNuevo = computeUpdatedStockForInvoiceEdit(
          itemName: displayNameByKey[key] ?? existing.nombre,
          currentStock: stockAnterior,
          oldInvoiceQty: oldQty,
          newInvoiceQty: newQty,
        );

        double nuevoCostoUnitario = existing.costoUnitarioHistorico;
        if (delta > 0 && newItem != null) {
          nuevoCostoUnitario = stockNuevo > 0
              ? ((stockAnterior * existing.costoUnitarioHistorico) + (delta * newItem.costoUnitarioHistorico)) / stockNuevo
              : newItem.costoUnitarioHistorico;
        } else if (delta == 0 && newItem != null && newItem.costoUnitarioHistorico > 0) {
          nuevoCostoUnitario = newItem.costoUnitarioHistorico;
        }

        final updated = existing.copyWith(
          cantidadActualKg: stockNuevo,
          costoUnitarioHistorico: nuevoCostoUnitario,
          costoTotal: stockNuevo * nuevoCostoUnitario,
          loteFabricante: newItem?.loteFabricante ?? existing.loteFabricante,
        );

        await _repository.updateInventoryItem(updated);
        updatedItemsList[idx] = updated;
      } else if (newItem != null && newQty > 0) {
        final created = await _repository.addInventoryItem(newItem);
        updatedItemsList.add(created);
      }
    }

    state = state.copyWith(
      invoices: state.invoices.map((inv) => inv.id == updatedInv.id ? updatedInv : inv).toList(),
      items: updatedItemsList,
    );
  }

  /// Eliminar una factura de compra y descontar el stock ingresado por ella
  Future<void> deletePurchaseInvoice(PurchaseInvoice invoice) async {
    if (state.items.isEmpty) {
      await loadWarehouseData();
    }
    await _repository.deletePurchaseInvoice(invoice.id, invoice.empresaId);
    final updatedItemsList = List<InventoryItem>.from(state.items);

    for (final line in invoice.productos) {
      final idx = updatedItemsList.indexWhere(
        (i) => i.nombre.trim().toLowerCase() == line.nombre.trim().toLowerCase(),
      );
      if (idx != -1) {
        final existing = updatedItemsList[idx];
        final revertedStock = (existing.cantidadActualKg - line.kilosTotales).clamp(0.0, double.infinity);
        final updated = existing.copyWith(
          cantidadActualKg: revertedStock,
          costoTotal: revertedStock * existing.costoUnitarioHistorico,
        );
        await _repository.updateInventoryItem(updated);
        updatedItemsList[idx] = updated;
      }
    }

    state = state.copyWith(
      invoices: state.invoices.where((inv) => inv.id != invoice.id).toList(),
      items: updatedItemsList,
    );
  }

  /// Actualizar un proveedor existente en Supabase y estado local
  Future<Supplier> updateSupplier(Supplier supplier) async {
    final updated = await _repository.updateSupplier(supplier);
    final updatedList = state.suppliers.map((s) => s.id == updated.id ? updated : s).toList();
    state = state.copyWith(suppliers: updatedList);
    return updated;
  }

  /// Eliminar un proveedor del directorio en Supabase y estado local
  Future<void> deleteSupplier(String supplierId) async {
    await _repository.deleteSupplier(supplierId);
    final updatedList = state.suppliers.where((s) => s.id != supplierId).toList();
    state = state.copyWith(suppliers: updatedList);
  }
}

final warehouseProvider = StateNotifierProvider<WarehouseNotifier, WarehouseState>((ref) {
  final repo = ref.watch(warehouseRepositoryProvider);
  return WarehouseNotifier(repo, ref);
});

