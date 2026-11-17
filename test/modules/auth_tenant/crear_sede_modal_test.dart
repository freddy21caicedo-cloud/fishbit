import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:fishbit_finance/core/design_system/glass_form_field.dart';
import 'package:fishbit_finance/core/design_system/widgets/glass_location_dropdown.dart';
import 'package:fishbit_finance/core/storage/local_storage_service.dart';
import 'package:fishbit_finance/modules/auth_tenant/domain/models/company.dart';
import 'package:fishbit_finance/modules/auth_tenant/domain/models/user_member.dart';
import 'package:fishbit_finance/modules/auth_tenant/domain/models/aquaculture_unit.dart';
import 'package:fishbit_finance/modules/auth_tenant/domain/repositories/auth_repository.dart';
import 'package:fishbit_finance/modules/auth_tenant/presentation/providers/auth_provider.dart';
import 'package:fishbit_finance/modules/auth_tenant/presentation/dialogs/crear_sede_modal.dart';
import '../../helpers/test_auth_helper.dart';

class FakeAuthNotifier extends AuthNotifier {
  final AuthRepository _repo;
  FakeAuthNotifier(AuthState initial, this._repo, LocalStorageService storage)
      : super(_repo, storage) {
    state = initial;
  }

  @override
  Future<void> reloadCompanyAndUnits() async {
    final units = await _repo.fetchUnits(state.currentCompany?.id ?? '');
    state = state.copyWith(units: units);
  }

  @override
  Future<void> selectActiveUnit(String unitId) async {
    state = state.copyWith(activeUnitId: unitId);
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late FakeAuthRepository mockAuthRepo;
  late FakeLocalStorageService mockStorage;

  const testCompany = Company(
    id: 'empresa-test-123',
    nombreComercial: 'Acuícola El Diamante',
    razonSocial: 'Acuícola El Diamante S.A.S.',
    nit: '900.555.123-1',
  );

  final testUser = UserMember(
    id: 'user-admin',
    email: 'admin@diamante.com',
    nombre: 'Administrador Principal',
    role: UserRole.admin,
    empresaId: 'empresa-test-123',
    creadoEn: DateTime(2026, 1, 1),
  );

  setUp(() {
    SharedPreferences.setMockInitialValues({'theme_mode': 'dark'});
    mockAuthRepo = FakeAuthRepository(
      mockUser: testUser,
      mockCompanies: [testCompany],
      mockUnits: [
        AquacultureUnit(
          id: 'unit-1',
          empresaId: 'empresa-test-123',
          nombre: 'Sede Principal',
          sigla: 'PRI',
          creadoEn: DateTime(2026, 1, 1),
        ),
      ],
    );
    mockStorage = FakeLocalStorageService();
  });

  Widget buildTestWidget({ThemeMode themeMode = ThemeMode.dark}) {
    return ProviderScope(
      overrides: [
        authRepositoryProvider.overrideWithValue(mockAuthRepo),
        localStorageServiceProvider.overrideWithValue(mockStorage),
        authProvider.overrideWith((ref) => FakeAuthNotifier(
              AuthState(
                currentUser: testUser,
                currentCompany: testCompany,
                units: mockAuthRepo.mockUnits,
                activeUnitId: mockAuthRepo.mockUnits.first.id,
              ),
              mockAuthRepo,
              mockStorage,
            )),
      ],
      child: MaterialApp(
        theme: ThemeData.light(),
        darkTheme: ThemeData.dark(),
        themeMode: themeMode,
        home: const Scaffold(
          body: Center(
            child: SizedBox(
              width: 480,
              height: 850,
              child: CrearSedeModal(empresaId: 'empresa-test-123'),
            ),
          ),
        ),
      ),
    );
  }

  group('CrearSedeModal - Pruebas de Formulario y Estándares Supabase', () {
    testWidgets('1. Renderiza formulario con todos los campos y sin emojis', (tester) async {
      await tester.binding.setSurfaceSize(const Size(600, 950));
      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      // Cabecera Oficial
      expect(find.text('Registrar Nueva Sede'), findsOneWidget);
      expect(find.byIcon(Icons.add_business_rounded), findsOneWidget);
      expect(find.byIcon(Icons.close_rounded), findsOneWidget);

      // Campos principales
      expect(find.byWidgetPredicate((w) => w is GlassFormField && w.label.contains('NOMBRE DE SEDE')), findsOneWidget);
      expect(find.text('SIGLA OFICIAL'), findsOneWidget);
      expect(find.text('UBICACIÓN GEOGRÁFICA'), findsOneWidget);
      expect(find.byType(GlassLocationDropdown), findsNWidgets(3)); // País, Depto, Ciudad
      expect(find.byWidgetPredicate((w) => w is GlassFormField && w.label.contains('DIRECCIÓN')), findsOneWidget);
      expect(find.byWidgetPredicate((w) => w is GlassFormField && w.label.contains('TELÉFONO')), findsOneWidget);

      // Botones
      expect(find.text('Cancelar'), findsOneWidget);
      expect(find.text('Guardar Sede'), findsOneWidget);

      // Cero emojis en la vista completa
      final allTextWidgets = tester.widgetList<Text>(find.byType(Text));
      final emojiRegex = RegExp(r'[\uD83C-\uDBFF\uDC00-\uDFFF]');
      for (final t in allTextWidgets) {
        expect(emojiRegex.hasMatch(t.data ?? ''), isFalse,
            reason: 'Se detectó un emoji en el texto: "${t.data}"');
      }
    });

    testWidgets('2. Genera sigla automáticamente y de forma reactiva al escribir el nombre', (tester) async {
      await tester.binding.setSurfaceSize(const Size(600, 950));
      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      final nombreFinder = find.byWidgetPredicate((w) => w is GlassFormField && w.label.contains('NOMBRE DE SEDE'));
      expect(find.text('SIGLA OFICIAL'), findsOneWidget);

      final nombreInput = find.descendant(of: nombreFinder, matching: find.byType(TextField));
      await tester.enterText(nombreInput, 'Piscícola La Esperanza');
      await tester.pumpAndSettle();

      expect(find.text('PE'), findsOneWidget);
    });

    testWidgets('3. Valida nombre de sede requerido al presionar Guardar Sede', (tester) async {
      await tester.binding.setSurfaceSize(const Size(600, 950));
      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      final guardarBtn = find.text('Guardar Sede');
      await tester.tap(guardarBtn);
      await tester.pumpAndSettle();

      expect(find.text('El nombre de la sede es obligatorio'), findsOneWidget);
      expect(mockAuthRepo.mockUnits.length, 1); // Solo la inicial
    });

    testWidgets('4. Registra sede exitosamente con datos geográficos y contacto', (tester) async {
      await tester.binding.setSurfaceSize(const Size(600, 950));
      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      // Completar campos
      final nombreFinder = find.byWidgetPredicate((w) => w is GlassFormField && w.label.contains('NOMBRE DE SEDE'));
      final dirFinder = find.byWidgetPredicate((w) => w is GlassFormField && w.label.contains('DIRECCIÓN'));
      final telFinder = find.byWidgetPredicate((w) => w is GlassFormField && w.label.contains('TELÉFONO'));

      final nombreInput = find.descendant(of: nombreFinder, matching: find.byType(TextField));
      final dirInput = find.descendant(of: dirFinder, matching: find.byType(TextField));
      final telInput = find.descendant(of: telFinder, matching: find.byType(TextField));

      await tester.enterText(nombreInput, 'Sede Cordillera');
      await tester.enterText(dirInput, 'Vereda El Retiro, Km 5');
      await tester.enterText(telInput, '3123456789');
      await tester.pumpAndSettle();

      // Presionar Guardar Sede
      final guardarBtn = find.text('Guardar Sede');
      await tester.tap(guardarBtn);
      await tester.pumpAndSettle();

      // Verificar que se haya registrado en el repositorio
      expect(mockAuthRepo.mockUnits.length, 2);
      final created = mockAuthRepo.mockUnits.last;
      expect(created.nombre, 'Sede Cordillera');
      expect(created.sigla, 'SC');
      expect(created.direccion, 'Vereda El Retiro, Km 5');
      expect(created.telefono, '3123456789');
      expect(created.pais, 'Colombia');
      expect(created.departamento, 'Antioquia');
      expect(created.ciudad, 'San Jerónimo');
      expect(created.ubicacion, contains('Vereda El Retiro, Km 5, San Jerónimo, Antioquia, Colombia'));
    });

    testWidgets('5. Renderiza de forma nítida en tema claro', (tester) async {
      await tester.binding.setSurfaceSize(const Size(600, 950));
      await tester.pumpWidget(buildTestWidget(themeMode: ThemeMode.light));
      await tester.pumpAndSettle();

      expect(find.text('Registrar Nueva Sede'), findsOneWidget);
      expect(find.text('Guardar Sede'), findsOneWidget);
    });
  });
}
