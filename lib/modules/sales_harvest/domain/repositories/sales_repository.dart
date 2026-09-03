import '../models/batch_sale.dart';
import '../models/client.dart';

abstract class SalesRepository {
  Future<List<BatchSale>> fetchSales(String empresaId, String unidadAcuicolaId);
  Future<BatchSale> recordSale(BatchSale sale);

  Future<List<Client>> fetchClients(String empresaId);
  Future<Client> createClient(Client client);
}
