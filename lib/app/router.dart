import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:fishbit_finance/app/main_navigation_shell.dart';
import 'package:fishbit_finance/modules/auth_tenant/presentation/providers/auth_provider.dart';
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
    initialLocation: '/login',
    refreshListenable: authNotifier,
    redirect: (context, state) {
      final isAuthRoute = state.matchedLocation == '/login' || state.matchedLocation == '/register';
      final isOnboardingRoute = state.matchedLocation == '/onboarding-empresa';

      if (authState.isLoading) return null;

      if (!authState.isAuthenticated) {
        return isAuthRoute ? null : '/login';
      }

      final user = authState.currentUser;
      final isSuperAdmin = user?.email.toLowerCase() == 'especialistaacuicola@gmail.com';
      final isSaasConsoleRoute = state.matchedLocation == '/saas-console' || state.matchedLocation == '/creator';

      // 1. Si es SuperAdmin de cobro/plataforma, redirigir directamente a la Consola SaaS
      if (isSuperAdmin) {
        return isSaasConsoleRoute ? null : '/saas-console';
      }

      // 2. Si no es SuperAdmin pero intenta acceder a la consola SaaS, redirigir al inicio
      if (isSaasConsoleRoute) {
        return '/';
      }

      if (isAuthRoute || isOnboardingRoute) {
        return '/';
      }

      return null;
    },
    routes: [
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
