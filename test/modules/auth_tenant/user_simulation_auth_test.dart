import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fishbit_finance/core/design_system/glass_form_field.dart';
import 'package:fishbit_finance/core/design_system/glass_button.dart';
import 'package:fishbit_finance/modules/auth_tenant/presentation/screens/login_screen.dart';
import 'package:fishbit_finance/modules/auth_tenant/presentation/screens/register_company_screen.dart';
import 'package:fishbit_finance/modules/auth_tenant/presentation/providers/auth_provider.dart';
import 'package:fishbit_finance/modules/auth_tenant/domain/models/user_member.dart';
import 'package:fishbit_finance/modules/auth_tenant/domain/models/company.dart';
import 'package:fishbit_finance/modules/auth_tenant/domain/models/aquaculture_unit.dart';
import 'package:fishbit_finance/modules/auth_tenant/domain/repositories/auth_repository.dart';
import 'package:fishbit_finance/core/storage/local_storage_service.dart';
import 'package:go_router/go_router.dart';

/// Repositorio interactivo para registrar las acciones y eventos del usuario simulado
class InteractiveUserSimulationRepo implements AuthRepository {
  bool failNextLogin = false;
  String? lastLoginEmail;
  String? lastLoginPassword;
  bool googleLoginInvoked = false;
  bool returnGoogleUserWithoutCompany = false;
  String? passwordResetEmailSent;
  bool registerCompanyInvoked = false;

  final UserMember mockExistingUser = UserMember(
    id: 'user-sim-001',
    email: 'admin@galapagos.com',
    nombre: 'Freddy Administrador',
    role: UserRole.admin,
    empresaId: 'emp-galapagos-01',
    unidadAcuicolaId: 'unit-principal',
    creadoEn: DateTime(2026, 1, 1),
  );

  @override
  Future<UserMember?> getCurrentSession() async => null;

  @override
  Future<UserMember> signInWithEmailPassword(String email, String password) async {
    lastLoginEmail = email;
    lastLoginPassword = password;
    if (failNextLogin) {
      throw Exception('Correo o contraseña incorrectos. Por favor verifica tus datos.');
    }
    return mockExistingUser;
  }

  @override
  Future<UserMember?> signInWithGoogle() async {
    googleLoginInvoked = true;
    if (returnGoogleUserWithoutCompany) {
      return UserMember(
        id: 'google-new-user-002',
        email: 'nuevo.google@gmail.com',
        nombre: 'Nuevo Usuario Google',
        role: UserRole.admin,
        empresaId: '', // Requiere onboarding
        creadoEn: DateTime(2026, 1, 1),
      );
    }
    return mockExistingUser;
  }

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
  }) async {
    registerCompanyInvoked = true;
    return UserMember(
      id: 'admin-reg-001',
      email: adminEmail,
      nombre: '$adminNombres $adminApellidos',
      role: UserRole.admin,
      empresaId: 'emp-new-001',
      unidadAcuicolaId: 'unit-new-001',
      creadoEn: DateTime(2026, 1, 1),
    );
  }

  @override
  Future<void> sendPasswordResetEmail(String email) async {
    passwordResetEmailSent = email;
  }

  @override
  Future<Company?> fetchCompany(String empresaId) async {
    return const Company(
      id: 'emp-galapagos-01',
      nombreComercial: 'Piscícola Galápagos',
      razonSocial: 'Grupo Galápagos SAS',
      nit: '900987654-1',
    );
  }

  @override
  Future<List<AquacultureUnit>> fetchUnits(String empresaId) async {
    return [
      AquacultureUnit(
        id: 'unit-principal',
        empresaId: empresaId,
        nombre: 'Sede Principal Represa',
        sigla: 'SPR',
        creadoEn: DateTime(2026, 1, 1),
      )
    ];
  }

  @override
  Future<List<UserMember>> fetchTeamMembers(String empresaId) async => [mockExistingUser];

  @override
  Future<List<Company>> fetchUserCompanies(String userId) async => [
        const Company(
          id: 'emp-galapagos-01',
          nombreComercial: 'Piscícola Galápagos',
          razonSocial: 'Grupo Galápagos SAS',
          nit: '900987654-1',
        )
      ];

  @override
  Future<void> signOut() async {}

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class FakeLocalStorage implements LocalStorageService {
  String? activeSede;
  String? sessionUid;
  final Map<String, String?> userSedes = {};

  @override
  String? getActiveSedeId() => activeSede;

  @override
  Future<bool> setActiveSedeId(String? sedeId) async {
    activeSede = sedeId;
    return true;
  }

  @override
  String? getActiveSedeIdForUser(String userId) => userSedes[userId];

  @override
  Future<bool> setActiveSedeIdForUser(String userId, String? sedeId) async {
    userSedes[userId] = sedeId;
    return true;
  }

  @override
  String? getSessionUserId() => sessionUid;

  @override
  Future<bool> setSessionUserId(String? uid) async {
    sessionUid = uid;
    return true;
  }

  @override
  Future<bool> clearSession() async {
    sessionUid = null;
    return true;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

Finder findFormFieldByLabel(String label) {
  return find.descendant(
    of: find.byWidgetPredicate((w) => w is GlassFormField && w.label == label),
    matching: find.byType(TextFormField),
  );
}

void main() {
  late InteractiveUserSimulationRepo fakeRepo;
  late FakeLocalStorage fakeStorage;

  setUp(() {
    fakeRepo = InteractiveUserSimulationRepo();
    fakeStorage = FakeLocalStorage();
  });

  Widget createLoginTestWidget({AuthNotifier? notifier}) {
    final router = GoRouter(
      initialLocation: '/login',
      routes: [
        GoRoute(
          path: '/login',
          builder: (context, state) => const LoginScreen(),
        ),
        GoRoute(
          path: '/register',
          builder: (context, state) => const Scaffold(body: Text('Register Screen')),
        ),
        GoRoute(
          path: '/',
          builder: (context, state) => const Scaffold(body: Text('Home Dashboard')),
        ),
      ],
    );
    return ProviderScope(
      overrides: [
        if (notifier != null)
          authProvider.overrideWith((ref) => notifier)
        else
          authProvider.overrideWith((ref) => AuthNotifier(fakeRepo, fakeStorage)),
      ],
      child: MaterialApp.router(
        routerConfig: router,
      ),
    );
  }

  Widget createRegisterTestWidget() {
    final router = GoRouter(
      initialLocation: '/register',
      routes: [
        GoRoute(
          path: '/register',
          builder: (context, state) => const RegisterCompanyScreen(),
        ),
        GoRoute(
          path: '/',
          builder: (context, state) => const Scaffold(body: Text('Home Dashboard')),
        ),
        GoRoute(
          path: '/login',
          builder: (context, state) => const Scaffold(body: Text('Login Screen')),
        ),
      ],
    );
    return ProviderScope(
      overrides: [
        authProvider.overrideWith((ref) => AuthNotifier(fakeRepo, fakeStorage)),
      ],
      child: MaterialApp.router(
        routerConfig: router,
      ),
    );
  }

  group('Simulación de Usuario: Flujo de Inicio de Sesión (Login)', () {
    testWidgets('1. Usuario observa todos los elementos de la interfaz de Login', (tester) async {
      tester.view.physicalSize = const Size(420 * 2, 850 * 2);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(createLoginTestWidget());
      await tester.pumpAndSettle();

      // Marca visual FishBit
      expect(find.text('Fish'), findsOneWidget);
      expect(find.text('Bit.'), findsOneWidget);
      expect(find.text('LÍNEA GESTIÓN ACUÍCOLA DE GRUPO GALÁGOS'), findsOneWidget);

      // Campos y controles
      expect(find.byWidgetPredicate((w) => w is GlassFormField && w.label == 'CORREO ELECTRÓNICO'), findsOneWidget);
      expect(find.byWidgetPredicate((w) => w is GlassFormField && w.label == 'CONTRASEÑA'), findsOneWidget);
      expect(find.text('Recordarme'), findsOneWidget);
      expect(find.text('¿Olvidaste tu contraseña?'), findsOneWidget);
      expect(find.text('Ingresar'), findsOneWidget);

      // Botón Continuar con Google
      expect(find.text('Continuar con Google'), findsOneWidget);

      // Enlace a Registro
      expect(
        find.byWidgetPredicate((w) => w is RichText && w.text.toPlainText().contains('Regístrate aquí')),
        findsOneWidget,
      );

      // Soporte
      expect(find.text('Soporte'), findsOneWidget);
      expect(find.text('@groupgalapagos'), findsOneWidget);
    });

    testWidgets('2. Usuario intenta ingresar con campos vacíos y recibe validaciones', (tester) async {
      tester.view.physicalSize = const Size(420 * 2, 850 * 2);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(createLoginTestWidget());
      await tester.pumpAndSettle();

      // Clic en 'Ingresar' sin digitar nada
      final ingresarBtn = find.widgetWithText(GlassButton, 'Ingresar');
      expect(ingresarBtn, findsOneWidget);
      await tester.tap(ingresarBtn);
      await tester.pumpAndSettle();

      // Verificación de mensajes de error de validación
      expect(find.text('El correo es requerido'), findsOneWidget);
      expect(find.text('La contraseña es requerida'), findsOneWidget);
      expect(fakeRepo.lastLoginEmail, isNull);
    });

    testWidgets('3. Usuario escribe correo con formato inválido y recibe feedback', (tester) async {
      tester.view.physicalSize = const Size(420 * 2, 850 * 2);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(createLoginTestWidget());
      await tester.pumpAndSettle();

      // Escribir correo sin arroba
      final emailFields = find.byType(TextFormField);
      await tester.enterText(emailFields.first, 'usuario_sin_formato');
      await tester.enterText(emailFields.last, 'clave1234');

      final ingresarBtn = find.widgetWithText(GlassButton, 'Ingresar');
      await tester.tap(ingresarBtn);
      await tester.pumpAndSettle();

      expect(find.text('Ingresa un correo electrónico válido'), findsOneWidget);
      expect(fakeRepo.lastLoginEmail, isNull);
    });

    testWidgets('4. Usuario conmuta la visibilidad de su contraseña', (tester) async {
      tester.view.physicalSize = const Size(420 * 2, 850 * 2);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(createLoginTestWidget());
      await tester.pumpAndSettle();

      // Botón del ojito para mostrar u ocultar contraseña
      final visibilityBtn = find.byTooltip('Mostrar contraseña');
      expect(visibilityBtn, findsOneWidget);

      await tester.tap(visibilityBtn);
      await tester.pumpAndSettle();

      expect(find.byTooltip('Ocultar contraseña'), findsOneWidget);
    });

    testWidgets('5. Usuario abre modal de recuperación de contraseña y solicita enlace', (tester) async {
      tester.view.physicalSize = const Size(420 * 2, 850 * 2);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(createLoginTestWidget());
      await tester.pumpAndSettle();

      // Clic en ¿Olvidaste tu contraseña?
      final forgotBtn = find.text('¿Olvidaste tu contraseña?');
      await tester.tap(forgotBtn);
      await tester.pumpAndSettle();

      // Modal abierto
      expect(find.text('Recuperar Acceso'), findsOneWidget);
      expect(find.text('Enviar Enlace de Recuperación'), findsOneWidget);

      // Ingresar correo y enviar
      final modalField = find.descendant(
        of: find.byType(Dialog),
        matching: find.byType(TextFormField),
      );
      await tester.enterText(modalField, 'recuperar@galapagos.com');

      final sendBtn = find.widgetWithText(GlassButton, 'Enviar Enlace de Recuperación');
      await tester.tap(sendBtn);
      await tester.pumpAndSettle();

      // Comprobar que se invocó el envío
      expect(fakeRepo.passwordResetEmailSent, 'recuperar@galapagos.com');
      expect(find.textContaining('Enlace enviado a recuperar@galapagos.com'), findsOneWidget);
    });

    testWidgets('6. Usuario ingresa credenciales erróneas y recibe SnackBar explicativo', (tester) async {
      tester.view.physicalSize = const Size(420 * 2, 850 * 2);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      fakeRepo.failNextLogin = true;

      await tester.pumpWidget(createLoginTestWidget());
      await tester.pumpAndSettle();

      final emailFields = find.byType(TextFormField);
      await tester.enterText(emailFields.first, 'admin@galapagos.com');
      await tester.enterText(emailFields.last, 'clave_incorrecta');

      final ingresarBtn = find.widgetWithText(GlassButton, 'Ingresar');
      await tester.tap(ingresarBtn);
      await tester.pumpAndSettle();

      // SnackBar de error
      expect(find.textContaining('Correo o contraseña incorrectos'), findsOneWidget);
    });

    testWidgets('7. Usuario ingresa credenciales válidas y completa autenticación exitosa', (tester) async {
      tester.view.physicalSize = const Size(420 * 2, 850 * 2);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      fakeRepo.failNextLogin = false;

      final notifier = AuthNotifier(fakeRepo, fakeStorage);
      await tester.pumpWidget(createLoginTestWidget(notifier: notifier));
      await tester.pumpAndSettle();

      final emailFields = find.byType(TextFormField);
      await tester.enterText(emailFields.first, 'admin@galapagos.com');
      await tester.enterText(emailFields.last, 'Password123!');

      final ingresarBtn = find.widgetWithText(GlassButton, 'Ingresar');
      await tester.tap(ingresarBtn);
      await tester.pumpAndSettle();

      expect(fakeRepo.lastLoginEmail, 'admin@galapagos.com');
      expect(fakeRepo.lastLoginPassword, 'Password123!');
      expect(notifier.state.isAuthenticated, isTrue);
      expect(notifier.state.currentUser?.email, 'admin@galapagos.com');
      expect(notifier.state.currentCompany?.nombreComercial, 'Piscícola Galápagos');
      expect(notifier.state.activeUnitId, 'unit-principal');
    });
  });

  group('Simulación de Usuario: Flujo de Registro de Usuario y Empresa (Register)', () {
    testWidgets('8. Usuario visualiza el Wizard de Registro (Paso 1: Administrador Maestro)', (tester) async {
      tester.view.physicalSize = const Size(500 * 2, 950 * 2);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(createRegisterTestWidget());
      await tester.pumpAndSettle();

      expect(find.text('REGISTRO DE NUEVA EMPRESA PISCÍCOLA'), findsOneWidget);
      expect(find.text('Administrador'), findsOneWidget);
      expect(find.text('Empresa'), findsOneWidget);
      expect(find.textContaining('Paso 1: Datos del Administrador Maestro'), findsOneWidget);

      expect(find.byWidgetPredicate((w) => w is GlassFormField && w.label == 'NOMBRE(S)'), findsOneWidget);
      expect(find.byWidgetPredicate((w) => w is GlassFormField && w.label == 'APELLIDO(S)'), findsOneWidget);
      expect(find.byWidgetPredicate((w) => w is GlassFormField && w.label == 'CÉDULA / ID'), findsOneWidget);
      expect(find.byWidgetPredicate((w) => w is GlassFormField && w.label == 'CONTACTO / CELULAR'), findsOneWidget);
      expect(find.byWidgetPredicate((w) => w is GlassFormField && w.label == 'CORREO ELECTRÓNICO (USUARIO MASTER)'), findsOneWidget);
      expect(find.byWidgetPredicate((w) => w is GlassFormField && w.label == 'CONTRASEÑA'), findsOneWidget);
      expect(find.byWidgetPredicate((w) => w is GlassFormField && w.label == 'CONFIRMAR CLAVE'), findsOneWidget);
      expect(find.text('Continuar a Datos de Empresa ➔'), findsOneWidget);
    });

    testWidgets('9. Usuario intenta continuar con campos vacíos y el formulario lo detiene', (tester) async {
      tester.view.physicalSize = const Size(500 * 2, 950 * 2);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(createRegisterTestWidget());
      await tester.pumpAndSettle();

      final continueBtn = find.text('Continuar a Datos de Empresa ➔');
      await tester.ensureVisible(continueBtn);
      await tester.tap(continueBtn);
      await tester.pumpAndSettle();

      // Validaciones requeridas
      expect(find.text('Requerido'), findsWidgets);
      expect(find.text('El correo es requerido'), findsOneWidget);
      expect(find.text('Contraseña requerida'), findsOneWidget);
      expect(find.textContaining('Paso 2: Datos de la Empresa Piscícola'), findsNothing);
    });

    testWidgets('10. Usuario ingresa contraseñas no coincidentes y recibe advertencia', (tester) async {
      tester.view.physicalSize = const Size(500 * 2, 950 * 2);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(createRegisterTestWidget());
      await tester.pumpAndSettle();

      // Llenar campos Paso 1 usando findFormFieldByLabel
      await tester.enterText(findFormFieldByLabel('NOMBRE(S)'), 'Freddy');
      await tester.enterText(findFormFieldByLabel('APELLIDO(S)'), 'Caicedo');
      await tester.enterText(findFormFieldByLabel('CÉDULA / ID'), '1098765432');
      await tester.enterText(findFormFieldByLabel('CONTACTO / CELULAR'), '3001234567');
      await tester.enterText(findFormFieldByLabel('CORREO ELECTRÓNICO (USUARIO MASTER)'), 'freddy@piscicola.com');
      await tester.enterText(findFormFieldByLabel('CONTRASEÑA'), 'Clave123');
      await tester.enterText(findFormFieldByLabel('CONFIRMAR CLAVE'), 'OtraClaveDiferente');

      final continueBtn = find.text('Continuar a Datos de Empresa ➔');
      await tester.ensureVisible(continueBtn);
      await tester.tap(continueBtn);
      await tester.pumpAndSettle();

      expect(find.text('Las contraseñas no coinciden'), findsOneWidget);
    });

    testWidgets('11. Usuario completa Paso 1, pasa al Paso 2, llena Empresa y Finaliza registro', (tester) async {
      tester.view.physicalSize = const Size(500 * 2, 950 * 2);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(createRegisterTestWidget());
      await tester.pumpAndSettle();

      // Completar Paso 1 válido
      await tester.enterText(findFormFieldByLabel('NOMBRE(S)'), 'Freddy');
      await tester.enterText(findFormFieldByLabel('APELLIDO(S)'), 'Caicedo');
      await tester.enterText(findFormFieldByLabel('CÉDULA / ID'), '1098765432');
      await tester.enterText(findFormFieldByLabel('CONTACTO / CELULAR'), '3001234567');
      await tester.enterText(findFormFieldByLabel('CORREO ELECTRÓNICO (USUARIO MASTER)'), 'freddy@piscicola.com');
      await tester.enterText(findFormFieldByLabel('CONTRASEÑA'), 'Piscicola2026*');
      await tester.enterText(findFormFieldByLabel('CONFIRMAR CLAVE'), 'Piscicola2026*');

      // Avanzar al Paso 2
      final continueBtn = find.text('Continuar a Datos de Empresa ➔');
      await tester.ensureVisible(continueBtn);
      await tester.tap(continueBtn);
      await tester.pumpAndSettle();

      // Verificar que estamos en Paso 2
      expect(find.textContaining('Paso 2: Datos de la Empresa Piscícola'), findsOneWidget);
      expect(find.byWidgetPredicate((w) => w is GlassFormField && w.label == 'NOMBRE DE LA EMPRESA / PISCÍCOLA'), findsOneWidget);
      expect(find.text('UBICACIÓN GEOGRÁFICA (EN CASCADA)'), findsOneWidget);
      expect(find.byWidgetPredicate((w) => w is GlassFormField && w.label == 'NIT / RUT'), findsOneWidget);

      // Llenar campos de Empresa
      await tester.enterText(findFormFieldByLabel('NOMBRE DE LA EMPRESA / PISCÍCOLA'), 'Piscícola Del Oriente S.A.S.');
      await tester.enterText(findFormFieldByLabel('NIT / RUT'), '901.555.777-2');
      await tester.enterText(findFormFieldByLabel('CORREO CORPORATIVO'), 'contacto@deloriente.com');

      // Scroll dentro de Paso 2 para asegurar que el botón final esté a la vista
      await tester.drag(find.text('UBICACIÓN GEOGRÁFICA (EN CASCADA)'), const Offset(0, -320));
      await tester.pumpAndSettle();

      // Presionar "Finalizar y Crear Piscícola"
      final finishBtn = find.widgetWithText(GlassButton, 'Finalizar y Crear Piscícola');
      await tester.ensureVisible(finishBtn);
      await tester.tap(finishBtn);
      await tester.pumpAndSettle();

      // Comprobar que el repositorio ejecutó el registro
      expect(fakeRepo.registerCompanyInvoked, isTrue);
      expect(find.textContaining('Piscícola creada con éxito'), findsOneWidget);
    });
  });

  group('Simulación de Usuario: Flujo Continuar con Google', () {
    testWidgets('12. Usuario pulsa Continuar con Google y se activa el estado de conexión', (tester) async {
      tester.view.physicalSize = const Size(420 * 2, 850 * 2);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final notifier = AuthNotifier(fakeRepo, fakeStorage);
      await tester.pumpWidget(createLoginTestWidget(notifier: notifier));
      await tester.pumpAndSettle();

      final googleBtn = find.text('Continuar con Google');
      expect(googleBtn, findsOneWidget);

      await tester.tap(googleBtn);
      await tester.pumpAndSettle();

      expect(fakeRepo.googleLoginInvoked, isTrue);
      // Usuario autenticado con éxito
      expect(notifier.state.isAuthenticated, isTrue);
      expect(notifier.state.currentUser?.nombre, 'Freddy Administrador');
    });

    testWidgets('13. Usuario nuevo con Google es detectado sin empresa para Onboarding', (tester) async {
      fakeRepo.returnGoogleUserWithoutCompany = true;

      final notifier = AuthNotifier(fakeRepo, fakeStorage);
      final user = await notifier.signInWithGoogle();

      expect(fakeRepo.googleLoginInvoked, isTrue);
      expect(user, isNotNull);
      expect(user?.email, 'nuevo.google@gmail.com');
      // Señal para router: empresaId vacía -> Router redirige a /onboarding-empresa
      expect(user?.empresaId, isEmpty);
      expect(notifier.state.currentUser?.empresaId, isEmpty);
    });
  });
}
