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
import 'package:fishbit_finance/modules/auth_tenant/domain/repositories/auth_repository.dart';
import 'package:fishbit_finance/modules/auth_tenant/presentation/providers/auth_provider.dart';
import 'package:fishbit_finance/modules/ponds_batches/domain/models/pond.dart';
import 'package:fishbit_finance/modules/ponds_batches/domain/models/fish_batch.dart';
import 'package:fishbit_finance/modules/ponds_batches/domain/models/biometria_record.dart';
import 'package:fishbit_finance/modules/ponds_batches/domain/models/mortality_record.dart';
import 'package:fishbit_finance/modules/ponds_batches/domain/models/transfer_record.dart';
import 'package:fishbit_finance/modules/ponds_batches/domain/repositories/ponds_repository.dart';
import 'package:fishbit_finance/modules/ponds_batches/presentation/dialogs/crear_estanque_modal.dart';
import 'package:fishbit_finance/modules/ponds_batches/presentation/providers/ponds_provider.dart';

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

class MockPondsRepository implements PondsRepository {
  List<Pond> ponds = [];

  @override
  Future<List<Pond>> fetchPondsByUnit(String empresaId, String unidadAcuicolaId) async => List.from(ponds);
  @override
  Future<List<FishBatch>> fetchBatchesByUnit(String empresaId, String unidadAcuicolaId) async => [];
  @override
  Future<List<BiometriaRecord>> fetchBiometriesByUnit(String empresaId, String unidadAcuicolaId, {String? pondId, String? batchId}) async => [];
  @override
  Future<List<MortalityRecord>> fetchMortalityByUnit(String empresaId, String unidadAcuicolaId, {String? pondId, String? batchId}) async => [];
  @override
  Future<BiometriaRecord> registerBiometry({String? empresaId, String? unidadAcuicolaId, required String estanqueId, required String loteId, required double nuevoPesoPromedioGramos, int? cantidadPecesMuestreados, double? pesoTotalCapturaKg, double? longitudPromedioCm, double? factorK, double? gdpGDia, String? observaciones, String? registradoPor, DateTime? fecha, String? hora}) async => throw UnimplementedError();
  @override
  Future<MortalityRecord> registerMortality({String? empresaId, String? unidadAcuicolaId, required String estanqueId, required String loteId, required int cantidadPecesMuertos, required double pesoPromedioGramos, required String causaProbable, double? biomasaPerdidaKg, String? observaciones, String? registradoPor, DateTime? fecha, String? hora}) async => throw UnimplementedError();
  @override
  Future<Pond> createPond(Pond pond) async {
    ponds.add(pond);
    return pond;
  }
  @override
  Future<void> updatePond(Pond pond) async {}
  @override
  Future<void> deletePond(String pondId) async {}
  @override
  Future<FishBatch> createBatch(FishBatch batch) async => batch;
  @override
  Future<void> updateBatch(FishBatch batch) async {}
  @override
  Future<void> transferOrSplitBatch({required String batchOrigenId, required String estanqueOrigenId, required String estanqueDestinoId, required int pecesTrasladados, required double biomasaTrasladadaKg, required bool esDesdoble, required String nuevoCodigoLote, String? registradoPor}) async {}
  @override
  Future<List<TransferRecord>> fetchTransfersByUnit(String empresaId, String unidadAcuicolaId, {String? pondId, String? batchId}) async => [];
}

class FakePondsNotifier extends PondsNotifier {
  FakePondsNotifier(PondsState initial, PondsRepository repo, Ref ref) : super(repo, ref) {
    state = initial;
  }

  @override
  Future<void> addPond(Pond pond) async {
    state = state.copyWith(ponds: [...state.ponds, pond]);
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const testCompany = Company(
    id: 'empresa-test-123',
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

  final existingPond1 = Pond(
    id: 'pond-1',
    empresaId: testCompany.id,
    unidadAcuicolaId: testUnit.id,
    unidadAcuicolaSigla: testUnit.sigla,
    nombre: 'Estanque 01',
    sigla: 'E01',
    capacidadM3: 135.0,
    estado: PondStatus.active,
    creadoEn: DateTime(2025, 1, 1),
  );

  final existingPond2 = Pond(
    id: 'pond-2',
    empresaId: testCompany.id,
    unidadAcuicolaId: testUnit.id,
    unidadAcuicolaSigla: testUnit.sigla,
    nombre: 'Estanque 02',
    sigla: 'E02',
    capacidadM3: 150.0,
    estado: PondStatus.available,
    creadoEn: DateTime(2025, 1, 2),
  );

  late LocalStorageService testStorage;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    testStorage = LocalStorageService(prefs);
  });

  Widget createTestWidget({
    List<Pond> ponds = const [],
    ThemeData? theme,
  }) {
    final mockRepo = MockPondsRepository()..ponds = List.from(ponds);

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
        pondsProvider.overrideWith((ref) => FakePondsNotifier(
              PondsState(ponds: ponds, isLoading: false),
              mockRepo,
              ref,
            )),
      ],
      child: MaterialApp(
        theme: theme ?? appDarkTheme,
        home: const Scaffold(
          body: Center(
            child: CrearEstanqueModal(),
          ),
        ),
      ),
    );
  }

  group('CrearEstanqueModal - Formulario Unificado & Asignación de Sigla', () {
    testWidgets('1. Renderiza formulario unificado sin PageView y con cabecera oficial', (tester) async {
      await tester.pumpWidget(createTestWidget(ponds: [existingPond1]));
      await tester.pumpAndSettle();

      expect(find.byType(PageView), findsNothing, reason: 'No debe existir un PageView confinado');
      expect(find.byType(SingleChildScrollView), findsWidgets);
      expect(find.text('Nuevo Estanque de Cultivo'), findsOneWidget);
      expect(find.text('SEDE ASIGNADA:'), findsOneWidget);
      expect(find.text('Sede San Jerónimo'), findsOneWidget);
      expect(find.byWidgetPredicate((w) => w is GlassFormField && w.label == 'NOMBRE DEL ESTANQUE'), findsOneWidget);
      expect(find.text('SIGLA TÉCNICA'), findsOneWidget);
      expect(find.text('Guardar Estanque'), findsOneWidget);
    });

    testWidgets('2. Genera sigla E03 automáticamente cuando E01 y E02 ya existen', (tester) async {
      await tester.pumpWidget(createTestWidget(ponds: [existingPond1, existingPond2]));
      await tester.pumpAndSettle();

      // Debe auto-asignar E03 ya que E01 y E02 existen
      expect(find.text('E03'), findsOneWidget);

      // Verificamos que tenga el ícono de candado (read-only)
      expect(find.byIcon(Icons.lock_rounded), findsOneWidget);
    });

    testWidgets('3. Al escribir "Estanque 05" asigna E05 automáticamente sin réplicas', (tester) async {
      await tester.pumpWidget(createTestWidget(ponds: [existingPond1, existingPond2]));
      await tester.pumpAndSettle();

      final nameField = find.widgetWithText(TextField, '');
      await tester.enterText(nameField.first, 'Estanque 05');
      await tester.pumpAndSettle();

      expect(find.text('E05'), findsOneWidget);
    });

    testWidgets('4. Si el usuario escribe un nombre cuyo número ya existe ("Estanque 01"), evita colisión', (tester) async {
      await tester.pumpWidget(createTestWidget(ponds: [existingPond1, existingPond2]));
      await tester.pumpAndSettle();

      final nameField = find.widgetWithText(TextField, '');
      await tester.enterText(nameField.first, 'Estanque 01'); // E01 ya existe en la base
      await tester.pumpAndSettle();

      // No debe asignar E01 (evita réplicas), debe asignar el siguiente libre E03
      expect(find.text('E01'), findsNothing);
      expect(find.text('E03'), findsOneWidget);
    });

    testWidgets('5. Conmuta entre morfología Circular y Rectangular actualizando campos', (tester) async {
      await tester.pumpWidget(createTestWidget(ponds: []));
      await tester.pumpAndSettle();

      // Inicialmente es circular: DIÁMETRO visible
      expect(find.byWidgetPredicate((w) => w is GlassFormField && w.label == 'DIÁMETRO (m)'), findsOneWidget);
      expect(find.byWidgetPredicate((w) => w is GlassFormField && w.label == 'LARGO (m)'), findsNothing);

      // Tap en Rectangular
      await tester.tap(find.text('Rectangular / Tierra'));
      await tester.pumpAndSettle();

      expect(find.byWidgetPredicate((w) => w is GlassFormField && w.label == 'DIÁMETRO (m)'), findsNothing);
      expect(find.byWidgetPredicate((w) => w is GlassFormField && w.label == 'LARGO (m)'), findsOneWidget);
      expect(find.byWidgetPredicate((w) => w is GlassFormField && w.label == 'ANCHO (m)'), findsOneWidget);
    });

    testWidgets('6. Valida campo requerido al intentar guardar con nombre vacío', (tester) async {
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(createTestWidget(ponds: []));
      await tester.pumpAndSettle();

      await tester.ensureVisible(find.text('Guardar Estanque'));
      await tester.tap(find.text('Guardar Estanque'));
      await tester.pumpAndSettle();

      expect(find.text('Ingresa el nombre del estanque'), findsOneWidget);
    });

    testWidgets('7. Renderiza de forma reactiva y nítida en tema claro', (tester) async {
      await tester.pumpWidget(createTestWidget(ponds: [existingPond1], theme: appLightTheme));
      await tester.pumpAndSettle();

      expect(find.text('Nuevo Estanque de Cultivo'), findsOneWidget);
      expect(find.text('E02'), findsOneWidget);
    });
  });
}
