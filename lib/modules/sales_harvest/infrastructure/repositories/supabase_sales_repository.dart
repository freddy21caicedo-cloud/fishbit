import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:fishbit_finance/core/events/app_event_bus.dart';
import 'package:fishbit_finance/modules/sales_harvest/domain/models/batch_sale.dart';
import 'package:fishbit_finance/modules/sales_harvest/domain/models/client.dart';
import 'package:fishbit_finance/modules/sales_harvest/domain/repositories/sales_repository.dart';

class SupabaseSalesRepository implements SalesRepository {
  final SupabaseClient _supabase;
  final AppEventBus _eventBus;

  SupabaseSalesRepository(this._supabase, this._eventBus);

  static final List<Client> _demoClients = [
    Client(
      id: 'cl100000-0000-0000-0000-000000000001',
      empresaId: 'c1000000-0000-0000-0000-000000000001',
      nombre: 'Distribuidora del Mar S.A.S.',
      telefono: '+57 312 456 7890',
      email: 'compras@distrimar.com',
      creadoEn: DateTime.now(),
    ),
    Client(
      id: 'cl100000-0000-0000-0000-000000000002',
      empresaId: 'c1000000-0000-0000-0000-000000000001',
      nombre: 'Restaurante Pescadería Central',
      telefono: '+57 301 987 6543',
      email: 'pedidos@pescaderia.com',
      creadoEn: DateTime.now(),
    ),
  ];

  static final List<BatchSale> _demoSales = [
    BatchSale(
      id: 's1000000-0000-0000-0000-000000000001',
      empresaId: 'c1000000-0000-0000-0000-000000000001',
      unidadAcuicolaId: 'u1000000-0000-0000-0000-000000000001',
      loteId: 'b1000000-0000-0000-0000-000000000001',
      codigoLote: 'LOT-TIL-01-2026',
      estanqueNombre: 'Estanque 01 (Geomembrana)',
      clienteId: 'cl100000-0000-0000-0000-000000000001',
      clienteNombre: 'Distribuidora del Mar S.A.S.',
      especie: 'Tilapia Roja',
      biomasaVendidaKg: 850.0,
      precioUnitarioKg: 9200.0,
      ingresoBruto: 7820000.0,
      cogs: 3713684.0,
      utilidadNeta: 4106316.0,
      estadoPago: 'Pagado',
      creadoEn: DateTime.now().subtract(const Duration(days: 2)),
    ),
  ];

  @override
  Future<List<BatchSale>> fetchSales(String empresaId, String unidadAcuicolaId) async {
    if (empresaId.startsWith('c1000000-')) {
      return _demoSales;
    }
    try {
      final res = await _supabase
          .from('ventas_lotes')
          .select('*')
          .eq('empresa_id', empresaId)
          .order('creado_en', ascending: false)
          .limit(100);

      final list = (res as List).map((row) => BatchSale.fromJson(row as Map<String, dynamic>)).toList();
      return list;
    } catch (_) {
      return [];
    }
  }

  @override
  Future<BatchSale> recordSale(BatchSale sale) async {
    try {
      final ventaPayload = {
        'id': sale.id,
        'empresa_id': sale.empresaId,
        'unit_id': sale.unidadAcuicolaId,
        'species_name': 'Tilapia',
        'tipo_venta': 'Cosecha Total',
        'cantidad_kg': sale.biomasaVendidaKg,
        'precio_kg': sale.precioUnitarioKg,
        'total': sale.ingresoBruto,
        'estado_pago': 'Completado',
        'fecha': sale.creadoEn.toIso8601String().split('T')[0],
        'created_at': sale.creadoEn.toIso8601String(),
      };

      try {
        await _supabase.from('ventas').insert(ventaPayload);
      } catch (_) {}

      try {
        await _supabase.from('ventas_lotes').insert(sale.toJson());
      } catch (_) {}

      _eventBus.fire(HarvestSaleRecordedEvent(
        loteId: sale.loteId,
        biomasaVendidaKg: sale.biomasaVendidaKg,
        ingresoBruto: sale.ingresoBruto,
        cogs: sale.cogs,
      ));

      return sale;
    } catch (_) {
      _demoSales.insert(0, sale);
      _eventBus.fire(HarvestSaleRecordedEvent(
        loteId: sale.loteId,
        biomasaVendidaKg: sale.biomasaVendidaKg,
        ingresoBruto: sale.ingresoBruto,
        cogs: sale.cogs,
      ));
      return sale;
    }
  }

  @override
  Future<List<Client>> fetchClients(String empresaId) async {
    if (empresaId.startsWith('c1000000-')) {
      return _demoClients;
    }
    try {
      final res = await _supabase
          .from('clientes')
          .select('*')
          .eq('empresa_id', empresaId)
          .order('creado_en', ascending: true)
          .limit(100);

      final list = (res as List).map((row) => Client.fromJson(row as Map<String, dynamic>)).toList();
      return list.isNotEmpty ? list : _demoClients;
    } catch (_) {
      return _demoClients;
    }
  }

  @override
  Future<Client> createClient(Client client) async {
    if (client.empresaId.startsWith('c1000000-')) {
      _demoClients.add(client);
      return client;
    }
    try {
      final res = await _supabase
          .from('clientes')
          .insert(client.toJson())
          .select()
          .single();

      return Client.fromJson(res);
    } catch (_) {
      _demoClients.add(client);
      return client;
    }
  }
}
