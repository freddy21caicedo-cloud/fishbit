import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fishbit_finance/core/design_system/hero_tabs.dart';
import 'package:fishbit_finance/core/design_system/magic_bento.dart';
import 'package:fishbit_finance/core/design_system/vertical_speed_dial.dart';
import 'package:fishbit_finance/core/storage/local_storage_service.dart';
import 'package:fishbit_finance/modules/auth_tenant/domain/models/aquaculture_unit.dart';
import 'package:fishbit_finance/modules/auth_tenant/domain/models/company.dart';
import 'package:fishbit_finance/modules/auth_tenant/domain/models/user_member.dart';
import 'package:fishbit_finance/modules/auth_tenant/presentation/providers/auth_provider.dart';
import 'package:fishbit_finance/modules/equipment_capex/domain/models/equipment_asset.dart';
import 'package:fishbit_finance/modules/equipment_capex/domain/repositories/equipment_repository.dart';
import 'package:fishbit_finance/modules/equipment_capex/presentation/providers/equipment_provider.dart';
import 'package:fishbit_finance/modules/finance_payroll/domain/models/energy_bill.dart';
import 'package:fishbit_finance/modules/finance_payroll/domain/models/jornal_record.dart';
import 'package:fishbit_finance/modules/finance_payroll/domain/models/maintenance_record.dart';
import 'package:fishbit_finance/modules/finance_payroll/domain/models/payroll_config.dart';
import 'package:fishbit_finance/modules/finance_payroll/domain/models/payroll_record.dart';
import 'package:fishbit_finance/modules/finance_payroll/domain/repositories/finance_repository.dart';
import 'package:fishbit_finance/modules/finance_payroll/presentation/providers/finance_provider.dart';
import 'package:fishbit_finance/modules/finance_payroll/presentation/screens/finance_screen.dart';
import 'package:fishbit_finance/modules/ponds_batches/domain/models/biometria_record.dart';
import 'package:fishbit_finance/modules/ponds_batches/domain/models/fish_batch.dart';
import 'package:fishbit_finance/modules/ponds_batches/domain/models/mortality_record.dart';
import 'package:fishbit_finance/modules/ponds_batches/domain/models/pond.dart';
import 'package:fishbit_finance/modules/ponds_batches/domain/models/transfer_record.dart';
import 'package:fishbit_finance/modules/ponds_batches/domain/repositories/ponds_repository.dart';
import 'package:fishbit_finance/modules/ponds_batches/presentation/providers/ponds_provider.dart';
import 'package:fishbit_finance/modules/sales_harvest/domain/models/batch_sale.dart';
import 'package:fishbit_finance/modules/sales_harvest/domain/models/client.dart';
import 'package:fishbit_finance/modules/sales_harvest/domain/repositories/sales_repository.dart';
import 'package:fishbit_finance/modules/sales_harvest/presentation/providers/sales_provider.dart';
import 'package:fishbit_finance/modules/warehouse_inventory/domain/models/biological_purchase.dart';
import 'package:fishbit_finance/modules/warehouse_inventory/domain/models/inventory_item.dart';
import 'package:fishbit_finance/modules/warehouse_inventory/domain/models/purchase_invoice.dart';
import 'package:fishbit_finance/modules/warehouse_inventory/domain/models/supplier.dart';
import 'package:fishbit_finance/modules/warehouse_inventory/domain/repositories/warehouse_repository.dart';
import 'package:fishbit_finance/modules/warehouse_inventory/presentation/providers/warehouse_provider.dart';
import '../../helpers/test_auth_helper.dart';

class _TrackingAuthRepo extends FakeAuthRepository {
  Company? lastUpdatedCompany;

  _TrackingAuthRepo({
    super.mockUser,
    super.mockCompanies,
    super.mockUnits,
    super.mockTeam,
  });

  @override
  Future<void> updateCompany(Company company) async {
    lastUpdatedCompany = company;
  }
}

class _FakeFinanceRepo implements FinanceRepository {
  final List<PayrollRecord> payroll;
  final List<JornalRecord> jornales;

  _FakeFinanceRepo({
    this.payroll = const [],
    this.jornales = const [],
  });

  @override
  Future<PayrollConfig> fetchPayrollConfig(String empresaId) async => const PayrollConfig();
  @override
  Future<List<PayrollRecord>> fetchPayroll(String empresaId, String unitId) async => payroll;
  @override
  Future<List<JornalRecord>> fetchJornales(String empresaId, String unitId) async => jornales;
  @override
  Future<List<EnergyBill>> fetchEnergyBills(String empresaId, String unitId) async => const [];
  @override
  Future<List<MaintenanceRecord>> fetchMaintenances(String empresaId, String unitId) async => const [];
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeEquipmentRepo implements EquipmentRepository {
  @override
  Future<List<EquipmentAsset>> fetchEquipment(String empresaId, String unitId) async => const [];
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeSalesRepo implements SalesRepository {
  @override
  Future<List<BatchSale>> fetchSales(String empresaId, String unitId) async => const [];
  @override
  Future<List<Client>> fetchClients(String empresaId) async => const [];
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeWarehouseRepo implements WarehouseRepository {
  @override
  Future<List<InventoryItem>> fetchInventory(String empresaId, {String? unitId}) async => const [];
  @override
  Future<List<Supplier>> fetchSuppliers(String empresaId) async => const [];
  @override
  Future<List<PurchaseInvoice>> fetchPurchaseInvoices(String empresaId, {String? unitId}) async => const [];
  @override
  Future<List<BiologicalPurchase>> fetchBiologicalPurchases(String empresaId, {String? unitId}) async => const [];
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakePondsRepo implements PondsRepository {
  final List<Pond> ponds;
  final List<FishBatch> batches;

  _FakePondsRepo({
    this.ponds = const [],
    this.batches = const [],
  });

  @override
  Future<List<Pond>> fetchPondsByUnit(String empresaId, String unidadAcuicolaId) async => ponds;
  @override
  Future<List<FishBatch>> fetchBatchesByUnit(String empresaId, String unidadAcuicolaId) async => batches;
  @override
  Future<List<BiometriaRecord>> fetchBiometries({
    required String empresaId,
    required String unidadAcuicolaId,
    String? pondId,
    String? batchId,
  }) async =>
      const [];
  @override
  Future<List<MortalityRecord>> fetchMortalityRecords({
    required String empresaId,
    required String unidadAcuicolaId,
    String? pondId,
    String? batchId,
  }) async =>
      const [];
  @override
  Future<List<TransferRecord>> fetchTransferRecords({
    required String empresaId,
    required String unidadAcuicolaId,
    String? pondId,
  }) async =>
      const [];
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

Widget _buildTestApp({
  required Size surfaceSize,
  required _TrackingAuthRepo authRepo,
  List<Pond> ponds = const [],
  List<FishBatch> batches = const [],
  List<PayrollRecord> payroll = const [],
  List<JornalRecord> jornales = const [],
}) {
  return ProviderScope(
    overrides: [
      localStorageServiceProvider.overrideWithValue(FakeLocalStorageService()),
      authRepositoryProvider.overrideWithValue(authRepo),
      financeRepositoryProvider.overrideWithValue(
        _FakeFinanceRepo(payroll: payroll, jornales: jornales),
      ),
      equipmentRepositoryProvider.overrideWithValue(_FakeEquipmentRepo()),
      salesRepositoryProvider.overrideWithValue(_FakeSalesRepo()),
      warehouseRepositoryProvider.overrideWithValue(_FakeWarehouseRepo()),
      pondsRepositoryProvider.overrideWithValue(
        _FakePondsRepo(ponds: ponds, batches: batches),
      ),
    ],
    child: MaterialApp(
      theme: ThemeData.dark(),
      home: MediaQuery(
        data: MediaQueryData(size: surfaceSize),
        child: const FinanceScreen(),
      ),
    ),
  );
}

void main() {
  test('JornalRecord serializes and parses real Supabase public.jornales columns', () {
    final record = JornalRecord(
      id: 'j-1',
      empresaId: 'emp-1',
      unidadAcuicolaId: 'unit-1',
      estanqueId: 'pond-1',
      laborRealizada: 'Cosecha Nocturna',
      cantidadJornales: 2,
      valorPorJornal: 70000,
      totalPagado: 140000,
      responsablePago: 'Carlos Pérez',
      observaciones: 'Turno completo',
      fecha: DateTime(2026, 11, 20),
      creadoEn: DateTime(2026, 11, 20),
    );

    final json = record.toJson();
    expect(json['unit_id'], 'unit-1');
    expect(json['estanque_id'], 'pond-1');
    expect(json['valor_jornal'], 70000);
    expect(json['total'], 140000);
    expect(json['descripcion'], 'Cosecha Nocturna | Resp: Carlos Pérez | Turno completo');
    expect(json.containsKey('empresa_id'), isFalse);

    final parsed = JornalRecord.fromJson(json);
    expect(parsed.unidadAcuicolaId, 'unit-1');
    expect(parsed.laborRealizada, 'Cosecha Nocturna');
    expect(parsed.responsablePago, 'Carlos Pérez');
    expect(parsed.observaciones, 'Turno completo');
    expect(parsed.valorPorJornal, 70000);
    expect(parsed.totalPagado, 140000);
  });

  testWidgets('FinanceScreen Phase 1 & 2: invested capital, interactive species prices, payroll KPIs & speed dial', (tester) async {
    final now = DateTime.now();
    final user = UserMember(
      id: 'u-1',
      email: 'admin@fishbit.co',
      nombre: 'Admin FishBit',
      role: UserRole.admin,
      empresaId: 'emp-1',
      unidadAcuicolaId: 'unit-1',
      salarioBase: 2000000,
      creadoEn: DateTime(2026, 1, 1),
    );
    final company = Company(
      id: 'emp-1',
      nombreComercial: 'Piscícola Test',
      razonSocial: 'Piscícola Test S.A.S.',
      nit: '900123456',
      precioMercadoActualKg: 10000,
      preciosMercadoEspecies: const {'Tilapia Roja': 10000},
      especiesHabilitadas: const ['Tilapia Roja', 'Cachama Blanca'],
    );
    final unit = AquacultureUnit(
      id: 'unit-1',
      empresaId: 'emp-1',
      nombre: 'Sede Principal',
      sigla: 'PRIN',
      creadoEn: DateTime(2026, 1, 1),
    );
    final pond = Pond(
      id: 'p-1',
      empresaId: 'emp-1',
      unidadAcuicolaId: 'unit-1',
      nombre: 'Estanque 1',
      sigla: 'E1',
      capacidadM3: 100,
      estado: PondStatus.active,
      especieActual: 'Tilapia Roja',
      biomasaKg: 500,
      costoAcumuladoBiologico: 2500000, // 1.5M semilla + 1.0M alimento (como en Supabase)
      creadoEn: DateTime(2026, 1, 1),
    );
    final batch = FishBatch(
      id: 'b-1',
      empresaId: 'emp-1',
      unidadAcuicolaId: 'unit-1',
      estanqueId: 'p-1',
      especie: 'Tilapia Roja',
      cantidadInicialPeces: 1000,
      cantidadActualPeces: 1000,
      pesoPromedioInicialG: 5,
      pesoActualGramos: 500,
      costoInicialAlevinos: 1500000,
      costoAcumuladoInsumos: 1000000,
      fechaSiembra: DateTime(2026, 6, 1),
      estado: BatchStatus.active,
      creadoEn: DateTime(2026, 6, 1),
    );
    final payrollCurrent = PayrollRecord(
      id: 'nom-1',
      empresaId: 'emp-1',
      unidadAcuicolaId: 'unit-1',
      empleadoId: 'u-1',
      empleadoNombre: 'Admin FishBit',
      periodo: 'Mensual',
      salarioBase: 2000000,
      costoTotalEmpresa: 2000000,
      fechaPago: now,
      creadoEn: now,
    );

    final authRepo = _TrackingAuthRepo(
      mockUser: user,
      mockCompanies: [company],
      mockUnits: [unit],
      mockTeam: [user],
    );

    for (final size in const [Size(390, 844), Size(1280, 800)]) {
      await tester.binding.setSurfaceSize(size);
      await tester.pumpWidget(
        _buildTestApp(
          surfaceSize: size,
          authRepo: authRepo,
          ponds: [pond],
          batches: [batch],
          payroll: [payrollCurrent],
        ),
      );
      await tester.pump(const Duration(milliseconds: 800));

      // 1. Título FishBit Finanzas y eliminaciones
      expect(find.textContaining('FishBit Finanzas', findRichText: true), findsOneWidget);
      expect(find.text('HUB EJECUTIVO'), findsNothing);
      expect(find.textContaining('UNIT ECONOMICS'), findsNothing);
      expect(find.byTooltip('Ajustes ARL & Nómina'), findsNothing);

      // 2. HeroTabsBar solo iconos (3 tabs)
      final heroTabs = tester.widget<HeroTabsBar>(find.byType(HeroTabsBar));
      expect(heroTabs.borderless, isTrue);
      expect(heroTabs.iconOnly, isTrue);
      expect(heroTabs.tabs.length, 3);

      // 3. Tab 0: Capital real invertido en agua (1.5M semilla + 1.0M insumos = 2.5M), sin proyección ni doble conteo
      expect(find.text('CAPITAL INVERTIDO'), findsOneWidget);
      expect(find.textContaining('Semilla: \$ 1.500.000'), findsOneWidget);
      expect(find.textContaining('Alimento/Insumos: \$ 1.000.000'), findsOneWidget);
      expect(find.textContaining('@ \$'), findsNothing);
      expect(find.byType(MagicBentoGrid), findsNWidgets(3));
      expect(find.byType(VerticalSpeedDial), findsNothing);

      // 4. Tab 1: Bento Card interactivo de precios de venta por especie
      await tester.tap(find.byKey(const Key('tab_finanzas_especies')));
      await tester.pump(const Duration(milliseconds: 500));
      expect(find.text('PRECIOS DE VENTA POR ESPECIE'), findsOneWidget);
      expect(find.byKey(const Key('species_price_chip_Tilapia Roja')), findsOneWidget);
      expect(find.byKey(const Key('species_price_chip_Cachama Blanca')), findsOneWidget);

      // Editar precio de Tilapia Roja y verificar que cierra sin error de ciclo de vida y actualiza el modelo
      await tester.tap(find.byKey(const Key('species_price_chip_Tilapia Roja')));
      await tester.pump(const Duration(milliseconds: 300));
      await tester.enterText(find.byKey(const Key('edit_species_price_input')), '13000');
      await tester.tap(find.byKey(const Key('save_species_price_btn')));
      await tester.pump(const Duration(milliseconds: 500));
      expect(authRepo.lastUpdatedCompany?.preciosMercadoEspecies['Tilapia Roja'], 13000.0);

      // 5. Tab 2: Bento Card fijo de Nómina + Speed Dial estilo Bitácora
      await tester.tap(find.byKey(const Key('tab_finanzas_nomina')));
      await tester.pump(const Duration(milliseconds: 500));
      expect(find.text('COSTO DE NÓMINA ACTUAL'), findsOneWidget);
      expect(find.text('ÚLTIMO TRIMESTRE'), findsOneWidget);
      expect(find.textContaining('AÑO ANTERIOR'), findsOneWidget);
      expect(find.text('IMPACTO EN COSTO DE PRODUCCIÓN GENERAL'), findsOneWidget);
      expect(find.text('REGISTRO RÁPIDO DE NÓMINA GENERAL'), findsNothing);
      expect(find.byType(VerticalSpeedDial), findsOneWidget);

      // Abrir Speed Dial y verificar botones de Nómina y Jornalero
      await tester.tap(find.byKey(const Key('nomina_speed_dial_toggle')));
      await tester.pump(const Duration(milliseconds: 600));
      expect(find.byKey(const Key('dial_action_nomina')), findsOneWidget);
      expect(find.byKey(const Key('dial_action_jornalero')), findsOneWidget);

      // Volver a Tab 0
      await tester.tap(find.byKey(const Key('nomina_speed_dial_toggle')));
      await tester.pump(const Duration(milliseconds: 500));
      await tester.tap(find.byKey(const Key('tab_finanzas_inversion')));
      await tester.pump(const Duration(milliseconds: 500));
    }

    await tester.binding.setSurfaceSize(null);
  });
}
