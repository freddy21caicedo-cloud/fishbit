import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fishbit_finance/core/network/supabase_client_provider.dart';
import 'package:fishbit_finance/modules/auth_tenant/presentation/providers/auth_provider.dart';
import 'package:fishbit_finance/modules/warehouse_inventory/domain/models/inventory_item.dart';
import 'package:fishbit_finance/modules/warehouse_inventory/domain/models/supplier.dart';
import 'package:fishbit_finance/modules/warehouse_inventory/domain/models/purchase_invoice.dart';
import 'package:fishbit_finance/modules/warehouse_inventory/domain/models/biological_purchase.dart';
import 'package:fishbit_finance/modules/warehouse_inventory/domain/repositories/warehouse_repository.dart';
import 'package:fishbit_finance/modules/warehouse_inventory/infrastructure/repositories/supabase_warehouse_repository.dart';

final warehouseRepositoryProvider = Provider<WarehouseRepository>((ref) {
  final supabase = ref.watch(supabaseClientProvider);
  return SupabaseWarehouseRepository(supabase);
});

// Proveedores Colombianos Oficiales Pre-cargados
final List<Supplier> kDefaultSuppliers = [
  const Supplier(
    id: 'sup-italcol',
    nit: '860.026.895-8',
    nombre: 'Italcol S.A.',
    telefono: '+57 (601) 369-2000',
    ciudad: 'Bogotá / Ibagué',
    categoriaPrincipal: 'concentrados',
    productosOfrecidos: [
      'Aquatilapia 45% E (Iniciador)',
      'Aquatilapia Micro Extruido 48%',
      'Aquatilapia 45% Harina',
      'Aquatilapia 38% E (Levante I)',
      'Aquatilapia 34% E (Levante II)',
      'Aquatilapia 32% E (Engorde)',
      'Aquatilapia 30% E (Engorde I)',
      'Aquatilapia 25% E (Engorde Final)',
      'Aquatilapia 20% E',
      'Aquatruchas Iniciación 50% E',
      'Aquatruchas Levante 45% E Pigmento',
      'Aquatrucha Finalización 40% E Pigmento',
      'Aquatropico 22% E',
    ],
  ),
  const Supplier(
    id: 'sup-vgr-italcol',
    nit: '901.378.925-0',
    nombre: 'VGR Italcol del Norte S.A.S.',
    telefono: '+57 (605) 385-2000',
    ciudad: 'Barranquilla / Costa Caribe',
    categoriaPrincipal: 'concentrados',
    productosOfrecidos: [
      'Aquatilapia 45% E (Iniciador)',
      'Aquatilapia Micro Extruido 48%',
      'Aquatilapia 45% Harina',
      'Aquatilapia 38% E (Levante I)',
      'Aquatilapia 34% E (Levante II)',
      'Aquatilapia 32% E (Engorde)',
      'Aquatilapia 30% E (Engorde I)',
      'Aquatilapia 25% E (Engorde Final)',
      'Aquatilapia 20% E',
      'Aquatruchas Iniciación 50% E',
      'Aquatruchas Levante 45% E Pigmento',
      'Aquatrucha Finalización 40% E Pigmento',
      'Aquatropico 22% E',
    ],
  ),
  const Supplier(
    id: 'sup-solla',
    nit: '890.900.291-8',
    nombre: 'Solla S.A.',
    telefono: '+57 (604) 448-0020',
    ciudad: 'Medellín / Buga',
    categoriaPrincipal: 'concentrados',
    productosOfrecidos: [
      'Solla Mojarra 45% (Alevines)',
      'Mojarras 38% PB',
      'Mojarras 32% PB',
      'Mojarras 24% PB',
      'Mojarra Reproductores',
      'Solla Trucha Arco Iris Levante',
      'Trucha Arco Iris Engorde Pigmento',
      'Solla Peces 20% (Introducción)',
    ],
  ),
  const Supplier(
    id: 'sup-contegral',
    nit: '890.901.271-5',
    nombre: 'Contegral S.A.S.',
    telefono: '+57 (604) 370-5000',
    ciudad: 'Envigado / Barranquilla',
    categoriaPrincipal: 'concentrados',
    productosOfrecidos: [
      'Tilapias Reproducción',
      'Tilapias Iniciación 45%',
      'Peces Iniciación 45%',
      'Peces Prelevante 38%',
      'Peces Levante 32%',
      'Maxi-Peces 38%',
      'Maxi-Peces 36%',
      'Maxi-Peces 34%',
      'Maxi-Peces 32%',
      'Maxi-Peces 28%',
      'Maxi-Peces 25%',
      'Peces Engorde 25%',
      'Peces Engorde 22%',
      'Maxi Truchas 45 SP',
      'Truchas Iniciación',
      'Truchas 40',
    ],
  ),
  const Supplier(
    id: 'sup-agrinal',
    nit: '890.400.514-1',
    nombre: 'Agrinal Colombia S.A.S.',
    telefono: '+57 (601) 825-8800',
    ciudad: 'Buga / Villavicencio',
    categoriaPrincipal: 'concentrados',
    productosOfrecidos: [
      'Tilapia 45% Extruida (Iniciación)',
      'Tilapia 38% Extruida (Levante)',
      'Tilapia 30% Extruida (Desarrollo)',
      'Tilapia 24% Extruida (Engorde)',
      'Truchas 40% Con Pigmento Extruido',
      'Truchas 45% Sin Pigmento Extruido',
      'Trucha 48% Iniciación Sin Pigmento Extruida',
    ],
  ),
  const Supplier(
    id: 'sup-finca',
    nit: '860.004.828-1',
    nombre: 'Finca S.A.S.',
    telefono: '+57 (601) 422-1000',
    ciudad: 'Buga / Girardot',
    categoriaPrincipal: 'concentrados',
    productosOfrecidos: [
      'Tilapia Iniciación 45%',
      'Tilapia Levante 38%',
      'Tilapia Desarrollo 32%',
      'Tilapia Engorde 24%',
    ],
  ),
  const Supplier(
    id: 'sup-suministros-caribe',
    nit: '901.123.456-1',
    nombre: 'Suministros Acuícolas del Caribe',
    telefono: '+57 (605) 385-1122',
    ciudad: 'Barranquilla / Cartagena',
    categoriaPrincipal: 'insumos',
    productosOfrecidos: [
      'Sal Marina sin Yodo (Saco 50 Kg)',
      'Cal Agrícola Carbonato de Calcio (Saco 40 Kg)',
      'Cal Viva Óxido de Calcio (Saco 40 Kg)',
      'Melaza de Caña Pura (Caneca 25 Kg)',
      'Complejo Vitamínico C Hidrosoluble (Galón 5L)',
    ],
  ),
  const Supplier(
    id: 'sup-bio-acuaticos',
    nit: '890.333.444-3',
    nombre: 'Bio-Acuáticos de Colombia',
    telefono: '+57 (602) 667-8899',
    ciudad: 'Cali / Neiva',
    categoriaPrincipal: 'insumos',
    productosOfrecidos: [
      'Bacterias Probióticas Bacillus (Litro)',
      'Levadura Activa Industrial (Bolsa 10 Kg)',
      'Zeolita Micronizada para Fondos (Saco 25 Kg)',
    ],
  ),
  const Supplier(
    id: 'sup-tecnoaqua',
    nit: '900.789.091-1',
    nombre: 'Tecnoaqua S.A.S. (TecnoAqua)',
    telefono: '+57 (601) 745-9988',
    ciudad: 'Bogotá / Villavicencio',
    categoriaPrincipal: 'farmacia',
    productosOfrecidos: [
      'Oxitetraciclina Polvo 50% (Bolsa 5 Kg)',
      'Florfenicol 50% Grado Acuícola',
      'Formalina Terapéutica 37% (Galón 4L)',
      'Azul de Metileno Grado Farmacéutico',
      'Sulfato de Cobre Pentahidratado',
    ],
  ),
  const Supplier(
    id: 'sup-acuagranja',
    nit: '890.324.487-3',
    nombre: 'Acuagranja S.A.S. (Acuagranja)',
    telefono: '+57 (602) 555-1234',
    ciudad: 'Cali / Valle',
    categoriaPrincipal: 'farmacia',
    productosOfrecidos: [
      'Complejo Vitamínico B (Frasco 1 Kg)',
      'Probiótico Clínico (Litro)',
      'Oxitetraciclina Polvo 50% (Bolsa 5 Kg)',
    ],
  ),
  const Supplier(
    id: 'sup-dr-tilapia',
    nit: '901.473.921-6',
    nombre: 'Doctor Tilapia y Doña Trucha S.A.S.',
    telefono: '+57 (608) 871-3322',
    ciudad: 'Neiva / Huila',
    categoriaPrincipal: 'farmacia',
    productosOfrecidos: [
      'Oxitetraciclina Polvo 50% (Bolsa 5 Kg)',
      'Complejo Vitamínico B (Frasco 1 Kg)',
      'Formalina Terapéutica 37% (Galón 4L)',
    ],
  ),
  const Supplier(
    id: 'sup-truchas-surala',
    nit: '800.190.239-9',
    nombre: 'Truchas Surala S.A.S. (Surala)',
    telefono: '+57 (601) 862-4455',
    ciudad: 'Cundinamarca / Boyacá',
    categoriaPrincipal: 'farmacia',
    productosOfrecidos: [
      'Oxitetraciclina Polvo 50% (Bolsa 5 Kg)',
      'Formalina Terapéutica 37% (Galón 4L)',
    ],
  ),
  const Supplier(
    id: 'sup-equipos-aquapower',
    nit: '901.887.654-9',
    nombre: 'AquaPower Equipos y Motores',
    telefono: '+57 (604) 321-4455',
    ciudad: 'Medellín',
    categoriaPrincipal: 'oxigenadores',
    productosOfrecidos: [
      'Aireador de Paletas 1.0 HP (Monofásico)',
      'Aireador de Paletas 2.0 HP (Trifásico)',
      'Aireador Splash Tipo Hongo 1.5 HP',
      'Soplador Blower Regenerativo 2.5 HP',
      'Motobomba Sumergible 3.0 HP',
    ],
  ),
  const Supplier(
    id: 'sup-gtc-bio',
    nit: '800.092.799-4',
    nombre: 'Genética Tilapieira de Colombia S.A. (GTC)',
    telefono: '+57 (608) 835-9900',
    ciudad: 'Neiva / Betania',
    categoriaPrincipal: 'alevinos',
    productosOfrecidos: [
      'Alevinos Tilapia Roja Reversada',
      'Alevinos Tilapia Plateada Nilótica',
      'Ovas Embrionadas de Tilapia',
      'Reproductores Seleccionados GTC',
    ],
  ),
  const Supplier(
    id: 'sup-aquagen-bio',
    nit: '900.123.456-1',
    nombre: 'Aquagén Colombia S.A.S.',
    telefono: '+57 (601) 620-7711',
    ciudad: 'Bogotá / Llanos',
    categoriaPrincipal: 'alevinos',
    productosOfrecidos: [
      'Alevinos Cachama Blanca',
      'Alevinos Bocachico del Magdalena',
      'Alevinos Bagre Rayado / Yaque',
      'Alevinos Trucha Arcoíris Ovas All-Female',
    ],
  ),
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
    return items.where((i) {
      final isAlevino = i.tipo == InventoryItemType.alevino;
      final matchesSpecies = i.nombre.toLowerCase().contains(cleanEspecie) ||
          (i.especieAlevino != null && i.especieAlevino!.toLowerCase().contains(cleanEspecie)) ||
          cleanEspecie.contains(i.nombre.toLowerCase());
      return isAlevino && matchesSpecies;
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

      final isMockCompany = empresaId.startsWith('c1000000-');
      // Solo inicializar con catálogo demo si es una empresa de demostración/mock explícita
      final finalItems = (remoteItems.isNotEmpty || !isMockCompany) ? remoteItems : kDefaultInventoryItems;

      state = state.copyWith(
        isLoading: false,
        items: finalItems,
        suppliers: isMockCompany ? kDefaultSuppliers : [],
        invoices: invoices,
        bioPurchases: bioPurchases,
      );
    } catch (e) {
      final isMock = empresaId.startsWith('c1000000-');
      state = state.copyWith(
        isLoading: false,
        items: isMock ? kDefaultInventoryItems : [],
        suppliers: isMock ? kDefaultSuppliers : [],
        errorMessage: e.toString(),
      );
    }
  }

  Future<void> addSupplier(Supplier supplier) async {
    state = state.copyWith(suppliers: [...state.suppliers, supplier]);
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

