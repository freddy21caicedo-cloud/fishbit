import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fishbit_finance/core/events/app_event_bus.dart';
import 'package:fishbit_finance/core/network/supabase_client_provider.dart';
import 'package:fishbit_finance/modules/auth_tenant/presentation/providers/auth_provider.dart';
import 'package:fishbit_finance/modules/sales_harvest/domain/models/batch_sale.dart';
import 'package:fishbit_finance/modules/sales_harvest/domain/models/client.dart';
import 'package:fishbit_finance/modules/sales_harvest/domain/repositories/sales_repository.dart';
import 'package:fishbit_finance/modules/sales_harvest/infrastructure/repositories/supabase_sales_repository.dart';

final salesRepositoryProvider = Provider<SalesRepository>((ref) {
  final supabase = ref.watch(supabaseClientProvider);
  final eventBus = ref.watch(eventBusProvider);
  return SupabaseSalesRepository(supabase, eventBus);
});

class SalesState {
  final bool isLoading;
  final List<BatchSale> sales;
  final List<Client> clients;
  final String? errorMessage;

  const SalesState({
    this.isLoading = false,
    this.sales = const [],
    this.clients = const [],
    this.errorMessage,
  });

  double get totalIngresosBrutos => sales.fold(0.0, (sum, s) => sum + s.ingresoBruto);
  double get totalCogs => sales.fold(0.0, (sum, s) => sum + s.cogs);
  double get totalUtilidadNeta => sales.fold(0.0, (sum, s) => sum + s.utilidadNeta);
  double get totalBiomasaVendidaKg => sales.fold(0.0, (sum, s) => sum + s.biomasaVendidaKg);

  SalesState copyWith({
    bool? isLoading,
    List<BatchSale>? sales,
    List<Client>? clients,
    String? errorMessage,
  }) {
    return SalesState(
      isLoading: isLoading ?? this.isLoading,
      sales: sales ?? this.sales,
      clients: clients ?? this.clients,
      errorMessage: errorMessage,
    );
  }
}

class SalesNotifier extends StateNotifier<SalesState> {
  final SalesRepository _repository;
  final Ref _ref;

  SalesNotifier(this._repository, this._ref) : super(const SalesState(isLoading: true)) {
    loadSalesData();
    _ref.listen<AuthState>(authProvider, (prev, next) {
      if (prev?.currentUser?.id != next.currentUser?.id ||
          prev?.currentCompany?.id != next.currentCompany?.id ||
          prev?.activeUnitId != next.activeUnitId ||
          (prev?.currentUser == null && next.currentUser != null)) {
        loadSalesData();
      }
    });
  }

  Future<void> loadSalesData() async {
    final auth = _ref.read(authProvider);
    final user = auth.currentUser;
    final unitId = auth.activeUnitId ?? user?.unidadAcuicolaId ?? user?.empresaId;
    final empresaId = auth.currentCompany?.id ?? user?.empresaId ?? unitId;

    if (empresaId == null || empresaId.isEmpty) {
      state = state.copyWith(isLoading: false);
      return;
    }

    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final sales = await _repository.fetchSales(empresaId, unitId ?? empresaId);
      final clients = await _repository.fetchClients(empresaId);
      state = state.copyWith(isLoading: false, sales: sales, clients: clients);
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
    }
  }

  Future<void> registerSale(BatchSale sale) async {
    try {
      final created = await _repository.recordSale(sale);
      state = state.copyWith(sales: [created, ...state.sales]);
    } catch (e) {
      state = state.copyWith(errorMessage: e.toString());
    }
  }

  Future<bool> recordSale(BatchSale sale) async {
    await registerSale(sale);
    return true;
  }

  Future<void> addClient(Client client) async {
    try {
      final created = await _repository.createClient(client);
      state = state.copyWith(clients: [...state.clients, created]);
    } catch (e) {
      state = state.copyWith(errorMessage: e.toString());
    }
  }
}

final salesProvider = StateNotifierProvider<SalesNotifier, SalesState>((ref) {
  final repo = ref.watch(salesRepositoryProvider);
  return SalesNotifier(repo, ref);
});
