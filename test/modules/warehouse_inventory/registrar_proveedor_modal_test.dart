import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:fishbit_finance/core/design_system/theme_provider.dart';
import 'package:fishbit_finance/core/design_system/glass_form_field.dart';
import 'package:fishbit_finance/core/storage/local_storage_service.dart';
import 'package:fishbit_finance/modules/auth_tenant/domain/models/company.dart';
import 'package:fishbit_finance/modules/auth_tenant/domain/models/user_member.dart';
import 'package:fishbit_finance/modules/auth_tenant/domain/models/aquaculture_unit.dart';
import 'package:fishbit_finance/modules/auth_tenant/presentation/providers/auth_provider.dart';
import 'package:fishbit_finance/modules/warehouse_inventory/domain/models/inventory_item.dart';
import 'package:fishbit_finance/modules/warehouse_inventory/domain/models/supplier.dart';
import 'package:fishbit_finance/modules/warehouse_inventory/domain/models/purchase_invoice.dart';
import 'package:fishbit_finance/modules/warehouse_inventory/domain/models/biological_purchase.dart';
import 'package:fishbit_finance/modules/warehouse_inventory/domain/repositories/warehouse_repository.dart';
import 'package:fishbit_finance/modules/warehouse_inventory/presentation/providers/warehouse_provider.dart';
import 'package:fishbit_finance/modules/warehouse_inventory/presentation/dialogs/registrar_proveedor_modal.dart';

import 'package:fishbit_finance/modules/auth_tenant/domain/repositories/auth_repository.dart';

class MockWarehouseRepository implements WarehouseRepository {
  List<Supplier> suppliers = [];

  @override
  Future<List<InventoryItem>> fetchInventory(String empresaId) async => [];

  @override
  Future<List<PurchaseInvoice>> fetchInvoices(String empresaId, String unidadAcuicolaId) async => [];

  @override
  Future<List<BiologicalPurchase>> fetchBiologicalPurchases(String empresaId, String unidadAcuicolaId) async => [];

  @override
  Future<BiologicalPurchase> createBiologicalPurchase(BiologicalPurchase purchase) async => purchase;

  @override
  Future<InventoryItem> addInventoryItem(InventoryItem item) async => item;

  @override
  Future<void> updateInventoryItem(InventoryItem item) async {}

  @override
  Future<PurchaseInvoice> createPurchaseInvoice(PurchaseInvoice invoice) async => invoice;

  @override
  Future<List<Supplier>> fetchCustomSuppliers(String empresaId) async => suppliers;

  @override
  Future<Supplier> createSupplier(Supplier supplier) async {
    suppliers.add(supplier);
    return supplier;
  }
}

class MockAuthRepository implements AuthRepository {
  @override
  Future<UserMember?> getCurrentSession() async => null;
  @override
  Future<UserMember> signInWithEmailPassword(String email, String password) async => throw UnimplementedError();
  @override
  Future<UserMember?> signInWithGoogle() async => null;
  @override
  Future<UserMember> setupCompanyForUser({
    required String userId,
    required String userEmail,
    required String userName,
    String? adminCedula,
    String? adminTelefono,
    required String companyNombre,
    required String companyNit,
    required String companyUbicacion,
    required String unitNombre,
    required String unitSigla,
    List<String>? especiesHabilitadas,
    String? primerEstanqueNombre,
    String? primerEstanqueTipo,
    double? primerEstanqueCapacidadM3,
    double? largoM,
    double? anchoM,
    double? profundidadM,
  }) async => throw UnimplementedError();
  @override
  Future<UserMember> registerCompanyWithAdmin({
    required String adminNombres,
    required String adminApellidos,
    required String adminCedulaNit,
    required String adminContacto,
    required String adminEmail,
    required String adminPassword,
    required String companyNombre,
    required String companyUbicacion,
    required String companyNit,
    required String companyEmail,
    String? companyRegistroIca,
    String? companyRegistroAunap,
  }) async => throw UnimplementedError();
  @override
  Future<void> sendPasswordResetEmail(String email) async {}
  @override
  Future<void> signOut() async {}
  @override
  Future<Company?> fetchCompany(String empresaId) async => null;
  @override
  Future<List<Company>> fetchUserCompanies(String userId) async => [];
  @override
  Future<void> updateCompany(Company company) async {}
  @override
  Future<List<AquacultureUnit>> fetchUnits(String empresaId) async => [];
  @override
  Future<AquacultureUnit> createUnit(String empresaId, String nombre, String sigla, String? ubicacion) async => throw UnimplementedError();
  @override
  Future<List<UserMember>> fetchTeamMembers(String empresaId) async => [];
  @override
  Future<UserMember> createTeamMember({
    required String empresaId,
    required String nombre,
    required String email,
    required String cedula,
    required String telefono,
    required UserRole role,
    String? unidadAcuicolaId,
    bool permisoGlobalEmpresa = false,
    double salarioBase = 0.0,
    String periodoPago = 'Quincenal',
    required String password,
  }) async => throw UnimplementedError();
  @override
  Future<String> createMemberInvitation({
    required String empresaId,
    required String nombre,
    required String email,
    required UserRole role,
    String? unidadAcuicolaId,
    String? cedula,
  }) async => throw UnimplementedError();
  @override
  Future<UserMember> registerWithInvitationToken(String token, String password) async => throw UnimplementedError();
  @override
  Future<UserMember> updateTeamMember(UserMember member) async => member;
  @override
  Future<void> updateMemberStatus(String memberId, MemberStatus newStatus) async {}
  @override
  Future<void> deleteMember(String memberId) async {}
}

class FakeAuthNotifier extends AuthNotifier {
  FakeAuthNotifier(AuthState initial, LocalStorageService storage)
      : super(MockAuthRepository(), storage) {
    state = initial;
  }
}

void main() {
  const testCompany = Company(
    id: 'c1000000-0000-0000-0000-000000000001',
    nombreComercial: 'Piscícola El Paraíso',
    razonSocial: 'Piscícola El Paraíso S.A.S.',
    nit: '900123456-1',
    email: 'info@elparaiso.co',
    especiesHabilitadas: ['Tilapia Roja'],
  );

  final testUser = UserMember(
    id: 'user-test-123',
    empresaId: testCompany.id,
    unidadAcuicolaId: 'unit-test-1',
    nombre: 'Freddy Caicedo',
    email: 'freddy@fishbit.co',
    role: UserRole.admin,
    creadoEn: DateTime(2025, 1, 1),
  );

  final testUnit = AquacultureUnit(
    id: 'unit-test-1',
    empresaId: testCompany.id,
    nombre: 'Sede San Jerónimo',
    sigla: 'SJR',
    ubicacion: 'San Jerónimo, Antioquia',
    creadoEn: DateTime(2025, 1, 1),
  );

  late LocalStorageService testStorage;
  late MockWarehouseRepository mockRepo;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    testStorage = LocalStorageService(prefs);
    mockRepo = MockWarehouseRepository();
  });

  Widget createTestWidget({ThemeData? theme}) {
    return ProviderScope(
      overrides: [
        localStorageServiceProvider.overrideWithValue(testStorage),
        authProvider.overrideWith((ref) {
          return FakeAuthNotifier(
            AuthState(
              currentUser: testUser,
              currentCompany: testCompany,
              units: [testUnit],
              activeUnitId: testUnit.id,
            ),
            testStorage,
          );
        }),
        warehouseRepositoryProvider.overrideWithValue(mockRepo),
      ],
      child: MaterialApp(
        theme: theme ?? appDarkTheme,
        home: const Scaffold(
          body: RegistrarProveedorModal(),
        ),
      ),
    );
  }

  group('RegistrarProveedorModal - Pruebas de Formulario y Herramienta Geográfica', () {
    testWidgets('1. Renderiza formulario con todos los campos y sin emojis', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      expect(find.text('Registrar Nuevo Proveedor'), findsOneWidget);
      expect(find.text('SEDE SJR'), findsOneWidget);
      expect(find.text('IDENTIFICACIÓN Y RAZÓN SOCIAL'), findsOneWidget);
      expect(find.text('UBICACIÓN GEOGRÁFICA'), findsOneWidget);
      expect(find.text('DATOS DE CONTACTO'), findsOneWidget);
      expect(find.text('CATEGORÍAS DE SUMINISTRO *'), findsOneWidget);

      // Tipos de identificación
      expect(find.text('NIT'), findsWidgets);
      expect(find.text('Cédula'), findsOneWidget);
      expect(find.text('Pasaporte'), findsOneWidget);

      // Comprobar que no hay emojis comunes en la UI
      final allTexts = tester.widgetList<Text>(find.byType(Text)).map((t) => t.data ?? '').join(' ');
      expect(allTexts.contains('🍽️'), isFalse);
      expect(allTexts.contains('🧪'), isFalse);
      expect(allTexts.contains('💊'), isFalse);
      expect(allTexts.contains('⚙️'), isFalse);
      expect(allTexts.contains('🐟'), isFalse);
      expect(allTexts.contains('📍'), isFalse);
    });

    testWidgets('2. Conmuta tipo de identificación entre NIT, Cédula y Pasaporte', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Por defecto es NIT
      expect(
        find.byWidgetPredicate((w) => w is GlassFormField && w.label == 'NÚMERO DE IDENTIFICACIÓN (NIT) *'),
        findsOneWidget,
      );

      // Tap en Cédula
      await tester.tap(find.text('Cédula'));
      await tester.pumpAndSettle();
      expect(
        find.byWidgetPredicate((w) => w is GlassFormField && w.label == 'NÚMERO DE IDENTIFICACIÓN (Cédula de Ciudadanía) *'),
        findsOneWidget,
      );

      // Tap en Pasaporte
      await tester.tap(find.text('Pasaporte'));
      await tester.pumpAndSettle();
      expect(
        find.byWidgetPredicate((w) => w is GlassFormField && w.label == 'NÚMERO DE IDENTIFICACIÓN (Pasaporte) *'),
        findsOneWidget,
      );
    });

    testWidgets('3. Permite selección múltiple de categorías', (tester) async {
      tester.view.physicalSize = const Size(1080, 1920);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Inicialmente 1 seleccionada (concentrados)
      expect(find.text('1 seleccionada'), findsOneWidget);

      // Agregar Insumos y Tratamientos
      await tester.ensureVisible(find.text('Insumos y Tratamientos'));
      await tester.tap(find.text('Insumos y Tratamientos'));
      await tester.pumpAndSettle();
      expect(find.text('2 seleccionadas'), findsOneWidget);

      // Agregar Alevinos y Genética
      await tester.ensureVisible(find.text('Alevinos y Genética'));
      await tester.tap(find.text('Alevinos y Genética'));
      await tester.pumpAndSettle();
      expect(find.text('3 seleccionadas'), findsOneWidget);

      // Desmarcar Insumos y Tratamientos
      await tester.ensureVisible(find.text('Insumos y Tratamientos'));
      await tester.tap(find.text('Insumos y Tratamientos'));
      await tester.pumpAndSettle();
      expect(find.text('2 seleccionadas'), findsOneWidget);
    });

    testWidgets('4. Valida campos requeridos al presionar Guardar Proveedor', (tester) async {
      tester.view.physicalSize = const Size(1080, 1920);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      await tester.ensureVisible(find.text('Guardar Proveedor'));
      await tester.tap(find.text('Guardar Proveedor'));
      await tester.pumpAndSettle();

      expect(find.text('Ingresa el nombre o razón social del proveedor'), findsOneWidget);
      expect(find.text('Ingresa el número de identificación'), findsOneWidget);
    });

    testWidgets('5. Registra proveedor exitosamente con todos los campos', (tester) async {
      tester.view.physicalSize = const Size(1080, 1920);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Ingresar nombre
      final nombreField = find.byWidgetPredicate(
        (w) => w is GlassFormField && w.label == 'NOMBRE O RAZÓN SOCIAL *',
      );
      await tester.enterText(nombreField, 'Nutrición Acuícola del Valle S.A.S.');
      await tester.pumpAndSettle();

      // Ingresar número de NIT
      final nitField = find.byWidgetPredicate(
        (w) => w is GlassFormField && w.label.contains('NÚMERO DE IDENTIFICACIÓN'),
      );
      await tester.enterText(nitField, '901.888.777-2');
      await tester.pumpAndSettle();

      // Seleccionar una segunda categoría
      await tester.ensureVisible(find.text('Insumos y Tratamientos'));
      await tester.tap(find.text('Insumos y Tratamientos'));
      await tester.pumpAndSettle();

      // Guardar
      await tester.ensureVisible(find.text('Guardar Proveedor'));
      await tester.tap(find.text('Guardar Proveedor'));
      await tester.pumpAndSettle();

      // Verificar que se guardó en el repositorio
      expect(mockRepo.suppliers.length, 1);
      final saved = mockRepo.suppliers.first;
      expect(saved.nombre, 'Nutrición Acuícola del Valle S.A.S.');
      expect(saved.nit, '901.888.777-2');
      expect(saved.pais, 'Colombia');
      expect(saved.departamento, 'Antioquia');
      expect(saved.categorias.contains('concentrados'), isTrue);
      expect(saved.categorias.contains('insumos'), isTrue);
    });

    testWidgets('6. Renderiza de forma nítida en tema claro', (tester) async {
      await tester.pumpWidget(createTestWidget(theme: appLightTheme));
      await tester.pumpAndSettle();

      expect(find.text('Registrar Nuevo Proveedor'), findsOneWidget);
      expect(find.text('IDENTIFICACIÓN Y RAZÓN SOCIAL'), findsOneWidget);
    });
  });
}
