import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:fishbit_finance/modules/auth_tenant/presentation/screens/onboarding_empresa_screen.dart';
import 'package:fishbit_finance/modules/auth_tenant/presentation/providers/auth_provider.dart';
import 'package:fishbit_finance/modules/auth_tenant/domain/models/user_member.dart';

class MockAuthNotifier extends StateNotifier<AuthState> implements AuthNotifier {
  MockAuthNotifier()
      : super(
          AuthState(
            isLoading: false,
            currentUser: UserMember(
              id: 'test-user-id',
              nombre: 'Carlos Administrador',
              email: 'carlos@piscicola.com',
              role: UserRole.admin,
              permisoGlobalEmpresa: true,
              estado: MemberStatus.active,
              salarioBase: 0,
              periodoPago: 'Mensual',
              creadoEn: DateTime(2026, 1, 1),
            ),
          ),
        );

  @override
  bool signOutCalled = false;

  @override
  Future<void> signOut() async {
    signOutCalled = true;
    state = const AuthState();
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  testWidgets('OnboardingEmpresaScreen renders 3-step wizard and advances correctly', (tester) async {
    tester.view.physicalSize = const Size(360 * 2, 780 * 2);
    tester.view.devicePixelRatio = 2.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authProvider.overrideWith((ref) => MockAuthNotifier()),
        ],
        child: const MaterialApp(
          home: OnboardingEmpresaScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Verify Title and Step 1 display
    expect(find.text('Configuración de Empresa'), findsOneWidget);
    expect(find.text('1. Administrador'), findsOneWidget);
    expect(find.text('2. Empresa'), findsOneWidget);
    expect(find.text('3. Infraestructura'), findsOneWidget);
    expect(find.text('DATOS PERSONALES DEL ADMINISTRADOR'), findsOneWidget);

    // Verify presence of Form Fields
    expect(find.byType(TextFormField), findsWidgets);

    // Enter required Step 1 data (Cedula and Telefono)
    final cedulaField = find.widgetWithText(TextFormField, 'ej. 1020304050');
    expect(cedulaField, findsOneWidget);
    await tester.enterText(cedulaField, '1020304050');

    final telefonoField = find.widgetWithText(TextFormField, 'ej. 3001234567');
    expect(telefonoField, findsOneWidget);
    await tester.enterText(telefonoField, '3001234567');

    // Verify Continuar button exists in Step 1
    final continueBtn = find.text('Continuar a Empresa');
    expect(continueBtn, findsOneWidget);

    // Scroll and tap Continuar to advance
    await tester.ensureVisible(continueBtn);
    await tester.tap(continueBtn);
    await tester.pumpAndSettle();

    // Verify Step 2 is reached
    expect(find.textContaining('DATOS FISCALES DE LA EMPRESA'), findsOneWidget);
    expect(find.textContaining('UBICACIÓN GEOGRÁFICA'), findsOneWidget);
  });

  testWidgets('OnboardingEmpresaScreen displays logout in header and return to login at bottom', (tester) async {
    tester.view.physicalSize = const Size(360 * 2, 780 * 2);
    tester.view.devicePixelRatio = 2.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    final mockNotifier = MockAuthNotifier();
    final router = GoRouter(
      initialLocation: '/onboarding-empresa',
      routes: [
        GoRoute(
          path: '/onboarding-empresa',
          builder: (context, state) => const OnboardingEmpresaScreen(),
        ),
        GoRoute(
          path: '/login',
          builder: (context, state) => const Scaffold(body: Text('Login Screen Mock')),
        ),
      ],
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authProvider.overrideWith((ref) => mockNotifier),
        ],
        child: MaterialApp.router(
          routerConfig: router,
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Verify header logout button exists with tooltip
    final headerLogout = find.byTooltip('Cerrar sesión e ir al Login');
    expect(headerLogout, findsOneWidget);

    // Verify bottom link to return to login exists
    final returnToLoginText = find.text('¿Deseas ingresar con otra cuenta? Volver al Login');
    expect(returnToLoginText, findsOneWidget);

    // Tap header logout
    await tester.tap(headerLogout);
    await tester.pumpAndSettle();

    expect(mockNotifier.signOutCalled, isTrue);
    expect(find.text('Login Screen Mock'), findsOneWidget);
  });
}
