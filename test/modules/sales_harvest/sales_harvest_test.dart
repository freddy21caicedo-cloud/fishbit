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

    test('Serializes to JSON and deserializes correctly', () {
      final sale = BatchSale(
        id: 'sale-json-1',
        empresaId: 'emp-1',
        unidadAcuicolaId: 'unit-1',
        clienteId: 'cli-99',
        clienteNombre: 'Restaurante El Pescador',
        loteId: 'lot-55',
        codigoLote: 'L-TIL-55',
        estanqueNombre: 'Estanque 5',
        especie: 'Tilapia',
        biomasaVendidaKg: 500.0,
        precioUnitarioKg: 10000.0,
        ingresoBruto: 5000000.0,
        cogs: 3200000.0,
        utilidadNeta: 1800000.0,
        estadoPago: 'Pendiente',
        pesoPromedioG: 480.0,
        porcentajeViscerasPct: 11.8,
        creadoEn: DateTime(2026, 8, 25, 14, 0),
      );

      final json = sale.toJson();
      expect(json['id'], 'sale-json-1');
      expect(json['cliente_nombre'], 'Restaurante El Pescador');
      expect(json['biomasa_vendida_kg'], 500.0);
      expect(json['estado_pago'], 'Pendiente');

      final parsed = BatchSale.fromJson({
        'id': 'sale-json-1',
        'empresa_id': 'emp-1',
        'unidad_acuicola_id': 'unit-1',
        'cliente_id': 'cli-99',
        'cliente_nombre': 'Restaurante El Pescador',
        'lote_id': 'lot-55',
        'codigo_lote': 'L-TIL-55',
        'estanque_nombre': 'Estanque 5',
        'especie': 'Tilapia',
        'biomasa_vendida_kg': 500.0,
        'precio_unitario_kg': 10000.0,
        'ingreso_bruto': 5000000.0,
        'cogs': 3200000.0,
        'utilidad_neta': 1800000.0,
        'estado_pago': 'Pendiente',
        'peso_promedio_g': 480.0,
        'porcentaje_visceras_pct': 11.8,
        'creado_en': '2026-08-25T14:00:00.000',
      });

      expect(parsed.id, 'sale-json-1');
      expect(parsed.ingresoBruto, 5000000.0);
      expect(parsed.estadoPago, 'Pendiente');
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
