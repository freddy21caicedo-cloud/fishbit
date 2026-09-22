import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:fishbit_finance/app/main_navigation_shell.dart';
import 'package:fishbit_finance/modules/auth_tenant/presentation/providers/auth_provider.dart';
import 'package:fishbit_finance/modules/auth_tenant/presentation/screens/splash_screen.dart';
import 'package:fishbit_finance/modules/auth_tenant/presentation/screens/sede_selection_screen.dart';
import 'package:fishbit_finance/modules/auth_tenant/presentation/screens/login_screen.dart';
import 'package:fishbit_finance/modules/auth_tenant/presentation/screens/register_company_screen.dart';
import 'package:fishbit_finance/modules/auth_tenant/presentation/screens/onboarding_empresa_screen.dart';
import 'package:fishbit_finance/modules/auth_tenant/presentation/screens/gestion_equipo_screen.dart';
import 'package:fishbit_finance/modules/auth_tenant/presentation/screens/saas_console_screen.dart';
import 'package:fishbit_finance/modules/home_dashboard/presentation/screens/home_dashboard_screen.dart';
import 'package:fishbit_finance/modules/ponds_batches/presentation/screens/ponds_dashboard_screen.dart';
import 'package:fishbit_finance/modules/warehouse_inventory/presentation/screens/warehouse_screen.dart';
import 'package:fishbit_finance/modules/bitacora/presentation/screens/bitacora_screen.dart';
import 'package:fishbit_finance/modules/sales_harvest/presentation/screens/sales_screen.dart';
import 'package:fishbit_finance/modules/finance_payroll/presentation/screens/finance_screen.dart';
import 'package:fishbit_finance/modules/ica_compliance/presentation/screens/ica_certification_screen.dart';

class AuthRouterNotifier extends ChangeNotifier {
  final Ref _ref;

  AuthRouterNotifier(this._ref) {
    _ref.listen<AuthState>(authProvider, (_, __) {
      notifyListeners();
    });
  }
}

final authRouterNotifierProvider = Provider<AuthRouterNotifier>((ref) {
  return AuthRouterNotifier(ref);
});

final routerProvider = Provider<GoRouter>((ref) {
  final authNotifier = ref.watch(authRouterNotifierProvider);
  final authState = ref.watch(authProvider);

  return GoRouter(
    initialLocation: '/splash',
    refreshListenable: authNotifier,
    redirect: (context, state) {
      final loc = state.matchedLocation;
      final isAuthRoute = loc == '/login' || loc == '/register';
      final isOnboardingRoute = loc == '/onboarding-empresa';
      final isSplashRoute = loc == '/splash';
      final isSedeRoute = loc == '/sede-selection';

      // Mientras carga la sesión → mantener en /splash
      if (authState.isLoading) {
        return isSplashRoute ? null : '/splash';
      }

      // Sin sesión → login (salvo rutas de auth que ya son públicas)
      if (!authState.isAuthenticated) {
        if (isAuthRoute || isSplashRoute) return null;
        return '/login';
      }

      final user = authState.currentUser;
      final isSuperAdmin = user?.email.toLowerCase() == 'especialistaacuicola@gmail.com';
      final isSaasConsoleRoute = loc == '/saas-console' || loc == '/creator';

      // 1. SuperAdmin → consola SaaS
      if (isSuperAdmin) {
        return isSaasConsoleRoute ? null : '/saas-console';
      }

      // 2. Intento de acceso a consola sin permiso → inicio
      if (isSaasConsoleRoute) return '/';

      // 3. Sin empresa configurada → onboarding
      final hasCompany = user?.empresaId != null && user!.empresaId!.isNotEmpty;
      if (!hasCompany) {
        return isOnboardingRoute ? null : '/onboarding-empresa';
      }

      // 4. Múltiples sedes sin preferencia → selector de sede
      if (authState.needsSedeSelection) {
        return isSedeRoute ? null : '/sede-selection';
      }

      // 5. Ya autenticado con empresa y sede → redirigir fuera de rutas de setup
      if (isAuthRoute || isOnboardingRoute || isSplashRoute || isSedeRoute) {
        return '/';
      }

      return null;
    },
    routes: [
      GoRoute(
        path: '/splash',
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/register',
        builder: (context, state) => const RegisterCompanyScreen(),
      ),
      GoRoute(
        path: '/onboarding-empresa',
        builder: (context, state) => const OnboardingEmpresaScreen(),
      ),
      GoRoute(
        path: '/sede-selection',
        builder: (context, state) => const SedeSelectionScreen(),
      ),
      GoRoute(
        path: '/saas-console',
        builder: (context, state) => const SaasConsoleScreen(),
      ),
      GoRoute(
        path: '/creator',
        builder: (context, state) => const SaasConsoleScreen(),
      ),
      ShellRoute(
        builder: (context, state, child) => MainNavigationShell(child: child),
        routes: [
          GoRoute(
            path: '/',
            builder: (context, state) => const HomeDashboardScreen(),
          ),
          GoRoute(
            path: '/ponds',
            builder: (context, state) => const PondsDashboardScreen(),
          ),
          GoRoute(
            path: '/warehouse',
            builder: (context, state) => const WarehouseScreen(),
          ),
          GoRoute(
            path: '/bitacora',
            builder: (context, state) => const BitacoraScreen(),
          ),
          GoRoute(
            path: '/records',
            builder: (context, state) => const BitacoraScreen(),
          ),
          GoRoute(
            path: '/sales',
            builder: (context, state) => const SalesScreen(),
          ),
          GoRoute(
            path: '/finance',
            builder: (context, state) => const FinanceScreen(),
          ),
          GoRoute(
            path: '/team',
            builder: (context, state) => const GestionEquipoScreen(),
          ),
          GoRoute(
            path: '/ica',
            builder: (context, state) => const IcaCertificationScreen(),
          ),
        ],
      ),
    ],
  );
});
