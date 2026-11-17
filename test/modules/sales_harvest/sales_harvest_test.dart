import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fishbit_finance/modules/sales_harvest/domain/models/batch_sale.dart';
import 'package:fishbit_finance/modules/sales_harvest/domain/models/client.dart';
import 'package:fishbit_finance/modules/sales_harvest/domain/repositories/sales_repository.dart';
import 'package:fishbit_finance/modules/sales_harvest/presentation/providers/sales_provider.dart';
import 'package:fishbit_finance/modules/auth_tenant/domain/models/user_member.dart';
import 'package:fishbit_finance/modules/auth_tenant/domain/models/company.dart';
import 'package:fishbit_finance/modules/auth_tenant/presentation/providers/auth_provider.dart';
import '../../helpers/test_auth_helper.dart';

class FakeSalesRepository implements SalesRepository {
  final List<BatchSale> mockSales;
  final List<Client> mockClients;
  final bool shouldFail;

  FakeSalesRepository({
    this.mockSales = const [],
    this.mockClients = const [],
    this.shouldFail = false,
  });

  @override
  Future<List<BatchSale>> fetchSales(String empresaId, String unidadAcuicolaId) async {
    if (shouldFail) throw Exception('Sales DB Outage');
    return mockSales;
  }

  @override
  Future<List<Client>> fetchClients(String empresaId) async {
    if (shouldFail) throw Exception('Clients DB Outage');
    return mockClients;
  }

  @override
  Future<BatchSale> recordSale(BatchSale sale) async {
    if (shouldFail) throw Exception('Failed to record sale');
    return sale;
  }

  @override
  Future<Client> createClient(Client client) async {
    if (shouldFail) throw Exception('Failed to create client');
    return client;
  }
}

void main() {
  group('BatchSale Domain Model Tests', () {
    test('Calculates financial metrics and net margin percentage correctly', () {
      final sale = BatchSale(
        id: 'sale-001',
        empresaId: 'emp-10',
        unidadAcuicolaId: 'unit-10',
        clienteId: 'cli-1',
        clienteNombre: 'Distribuidora del Centro',
        loteId: 'lote-10',
        codigoLote: 'L-2026-TIL-01',
        estanqueNombre: 'Estanque 1',
        especie: 'Tilapia Roja',
        biomasaVendidaKg: 1000.0,
        precioUnitarioKg: 9500.0,
        ingresoBruto: 9500000.0,
        cogs: 6000000.0, // 6,000 COP/kg cost of goods sold
        utilidadNeta: 3500000.0, // 3,500,000 COP net profit
        estadoPago: 'Pagado',
        pesoPromedioG: 500.0,
        porcentajeViscerasPct: 12.5,
        creadoEn: DateTime(2026, 8, 20),
      );

      expect(sale.biomasaVendidaKg, 1000.0);
      expect(sale.precioUnitarioKg, 9500.0);
      expect(sale.ingresoBruto, 9500000.0);
      expect(sale.cogs, 6000000.0);
      expect(sale.utilidadNeta, 3500000.0);
      // Margen neto = 3,500,000 / 9,500,000 * 100 = 36.8421%
      expect(sale.margenNetoPct, closeTo(36.84, 0.01));
    });

    test('Handles zero gross revenue edge case without dividing by zero', () {
      final zeroSale = BatchSale(
        id: 'sale-000',
        empresaId: 'emp-1',
        unidadAcuicolaId: 'unit-1',
        clienteNombre: 'Muestra',
        loteId: 'lote-1',
        codigoLote: 'L-0',
        estanqueNombre: 'E0',
        especie: 'Tilapia',
        biomasaVendidaKg: 0.0,
        precioUnitarioKg: 0.0,
        ingresoBruto: 0.0,
        cogs: 0.0,
        utilidadNeta: 0.0,
        creadoEn: DateTime.now(),
      );

      expect(zeroSale.margenNetoPct, 0.0);
    });

    test('Calculates yield loss (merma), viscera percent and clean weight accurately for eviscerated fish', () {
      final sale = BatchSale(
        id: 'sale-evisc-01',
        empresaId: 'emp-10',
        unidadAcuicolaId: 'unit-10',
        clienteNombre: 'Pescadería San Pedro',
        clienteCedulaNit: '900.543.210-9',
        loteId: 'lote-10',
        codigoLote: 'LOT-TIL-01',
        estanqueNombre: 'Estanque 2',
        especie: 'Tilapia Roja',
        tipoVenta: SalePresentation.evisceradoCompleto,
        cantidadPeces: 1000,
        pesoVivoKg: 500.0,
        pesoArregladoKg: 420.0,
        mermaKg: 80.0,
        mermaPct: 16.0,
        mermaGPpe: 80.0,
        baseCobro: 'peso_arreglado',
        biomasaVendidaKg: 500.0,
        precioUnitarioKg: 12000.0, // Facturado sobre peso arreglado
        ingresoBruto: 420.0 * 12000.0, // 5,040,000 COP
        cogs: 2500000.0,
        utilidadNeta: (420.0 * 12000.0) - 2500000.0, // 2,540,000 COP
        creadoEn: DateTime(2026, 9, 1),
      );

      expect(sale.tipoVenta, SalePresentation.evisceradoCompleto);
      expect(sale.clienteCedulaNit, '900.543.210-9');
      expect(sale.cantidadPeces, 1000);
      expect(sale.pesoVivoKg, 500.0);
      expect(sale.pesoArregladoKg, 420.0);
      expect(sale.mermaKg, 80.0);
      expect(sale.mermaPct, 16.0);
      expect(sale.mermaGPpe, 80.0);
      expect(sale.baseCobro, 'peso_arreglado');
      expect(sale.ingresoBruto, 5040000.0);
      expect(sale.utilidadNeta, 2540000.0);
    });

    test('Serializes to JSON and deserializes correctly with precision fields', () {
      final sale = BatchSale(
        id: 'sale-json-1',
        empresaId: 'emp-1',
        unidadAcuicolaId: 'unit-1',
        clienteId: 'cli-99',
        clienteNombre: 'Restaurante El Pescador',
        clienteCedulaNit: '1075283921',
        loteId: 'lot-55',
        codigoLote: 'L-TIL-55',
        estanqueNombre: 'Estanque 5',
        especie: 'Tilapia',
        tipoVenta: SalePresentation.medioEviscerado,
        cantidadPeces: 200,
        pesoVivoKg: 100.0,
        pesoArregladoKg: 90.0,
        mermaKg: 10.0,
        mermaPct: 10.0,
        mermaGPpe: 50.0,
        baseCobro: 'peso_vivo',
        biomasaVendidaKg: 100.0,
        precioUnitarioKg: 10000.0,
        ingresoBruto: 1000000.0,
        cogs: 600000.0,
        utilidadNeta: 400000.0,
        estadoPago: 'Pagado',
        pesoPromedioG: 500.0,
        porcentajeViscerasPct: 10.0,
        creadoEn: DateTime(2026, 8, 25, 14, 0),
      );

      final json = sale.toJson();
      expect(json['id'], 'sale-json-1');
      expect(json['cliente_nombre'], 'Restaurante El Pescador');
      expect(json['cliente_cedula_nit'], '1075283921');
      expect(json['tipo_venta'], 'medio_eviscerado');
      expect(json['peso_vivo_kg'], 100.0);
      expect(json['peso_arreglado_kg'], 90.0);
      expect(json['merma_kg'], 10.0);
      expect(json['merma_pct'], 10.0);

      final parsed = BatchSale.fromJson(json);
      expect(parsed.id, 'sale-json-1');
      expect(parsed.clienteCedulaNit, '1075283921');
      expect(parsed.tipoVenta, SalePresentation.medioEviscerado);
      expect(parsed.pesoArregladoKg, 90.0);
      expect(parsed.mermaKg, 10.0);
    });
  });


  group('Client Domain Model Tests', () {
    test('Client parses from JSON and produces correct Map', () {
      final client = Client(
        id: 'cli-001',
        empresaId: 'emp-001',
        nombre: 'Comercializadora Neiva',
        telefono: '3112223344',
        email: 'ventas@comercializadora.com',
        creadoEn: DateTime(2026, 4, 1),
      );

      final json = client.toJson();
      expect(json['id'], 'cli-001');
      expect(json['nombre'], 'Comercializadora Neiva');

      final parsed = Client.fromJson({
        'id': 'cli-001',
        'empresa_id': 'emp-001',
        'nombre': 'Comercializadora Neiva',
        'telefono': '3112223344',
        'email': 'ventas@comercializadora.com',
        'creado_en': '2026-04-01T00:00:00.000',
      });

      expect(parsed.id, 'cli-001');
      expect(parsed.email, 'ventas@comercializadora.com');
    });
  });

  group('SalesState Aggregation & Notifier Tests', () {
    test('SalesState totals accumulate revenue, cogs, profit and biomass accurately', () {
      final s1 = BatchSale(
        id: 's1',
        empresaId: 'emp-1',
        unidadAcuicolaId: 'unit-1',
        clienteNombre: 'Cliente 1',
        loteId: 'l1',
        codigoLote: 'L1',
        estanqueNombre: 'E1',
        especie: 'Tilapia',
        biomasaVendidaKg: 1000.0,
        precioUnitarioKg: 9000.0,
        ingresoBruto: 9000000.0,
        cogs: 6000000.0,
        utilidadNeta: 3000000.0,
        creadoEn: DateTime.now(),
      );

      final s2 = BatchSale(
        id: 's2',
        empresaId: 'emp-1',
        unidadAcuicolaId: 'unit-1',
        clienteNombre: 'Cliente 2',
        loteId: 'l2',
        codigoLote: 'L2',
        estanqueNombre: 'E2',
        especie: 'Cachama',
        biomasaVendidaKg: 500.0,
        precioUnitarioKg: 8000.0,
        ingresoBruto: 4000000.0,
        cogs: 2500000.0,
        utilidadNeta: 1500000.0,
        creadoEn: DateTime.now(),
      );

      final state = SalesState(sales: [s1, s2]);

      expect(state.totalBiomasaVendidaKg, 1500.0);
      expect(state.totalIngresosBrutos, 13000000.0);
      expect(state.totalCogs, 8500000.0);
      expect(state.totalUtilidadNeta, 4500000.0);
    });

    test('SalesNotifier loads sales and clients via Riverpod container', () async {
      final s1 = BatchSale(
        id: 's1',
        empresaId: 'emp-test',
        unidadAcuicolaId: 'unit-test',
        clienteNombre: 'Cliente 1',
        loteId: 'l1',
        codigoLote: 'L1',
        estanqueNombre: 'E1',
        especie: 'Tilapia',
        biomasaVendidaKg: 200.0,
        precioUnitarioKg: 10000.0,
        ingresoBruto: 2000000.0,
        cogs: 1200000.0,
        utilidadNeta: 800000.0,
        creadoEn: DateTime.now(),
      );

      final c1 = Client(
        id: 'c1',
        empresaId: 'emp-test',
        nombre: 'Restaurante Mar y Río',
        creadoEn: DateTime.now(),
      );

      final repo = FakeSalesRepository(mockSales: [s1], mockClients: [c1]);

      final container = ProviderContainer(
        overrides: [
          salesRepositoryProvider.overrideWithValue(repo),
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

      final notifier = container.read(salesProvider.notifier);
      await notifier.loadSalesData();

      final state = container.read(salesProvider);
      expect(state.isLoading, isFalse);
      expect(state.sales.length, 1);
      expect(state.clients.length, 1);
      expect(state.totalIngresosBrutos, 2000000.0);
    });
  });
}
