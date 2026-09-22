import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide AuthState;
import 'package:fishbit_finance/core/network/supabase_client_provider.dart';
import 'package:fishbit_finance/core/storage/local_storage_service.dart';
import 'package:fishbit_finance/modules/auth_tenant/domain/models/user_member.dart';
import 'package:fishbit_finance/modules/auth_tenant/domain/models/company.dart';
import 'package:fishbit_finance/modules/auth_tenant/domain/models/aquaculture_unit.dart';
import 'package:fishbit_finance/modules/auth_tenant/domain/repositories/auth_repository.dart';
import 'package:fishbit_finance/modules/auth_tenant/infrastructure/repositories/supabase_auth_repository.dart';

final localStorageServiceProvider = Provider<LocalStorageService>((ref) {
  throw UnimplementedError('LocalStorageService must be initialized in main()');
});

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  final supabase = ref.watch(supabaseClientProvider);
  final storage = ref.watch(localStorageServiceProvider);
  return SupabaseAuthRepository(supabase, storage);
});

class AuthState {
  final bool isLoading;
  final UserMember? currentUser;
  final Company? currentCompany;
  final List<Company> availableCompanies;
  final List<AquacultureUnit> units;
  final List<UserMember> teamMembers;
  final String? activeUnitId;
  final String? errorMessage;
  final bool isGoogleLoading;
  /// true cuando el usuario tiene ≥ 2 sedes y no hay preferencia guardada en
  /// localStorage para este dispositivo/usuario. El router lo redirige a /sede-selection.
  final bool needsSedeSelection;

  const AuthState({
    this.isLoading = false,
    this.isGoogleLoading = false,
    this.currentUser,
    this.currentCompany,
    this.availableCompanies = const [],
    this.units = const [],
    this.teamMembers = const [],
    this.activeUnitId,
    this.errorMessage,
    this.needsSedeSelection = false,
  });

  bool get isAuthenticated => currentUser != null;

  AuthState copyWith({
    bool? isLoading,
    bool? isGoogleLoading,
    UserMember? currentUser,
    Company? currentCompany,
    List<Company>? availableCompanies,
    List<AquacultureUnit>? units,
    List<UserMember>? teamMembers,
    String? activeUnitId,
    String? errorMessage,
    bool? needsSedeSelection,
  }) {
    return AuthState(
      isLoading: isLoading ?? this.isLoading,
      isGoogleLoading: isGoogleLoading ?? this.isGoogleLoading,
      currentUser: currentUser ?? this.currentUser,
      currentCompany: currentCompany ?? this.currentCompany,
      availableCompanies: availableCompanies ?? this.availableCompanies,
      units: units ?? this.units,
      teamMembers: teamMembers ?? this.teamMembers,
      activeUnitId: activeUnitId ?? this.activeUnitId,
      errorMessage: errorMessage,
      needsSedeSelection: needsSedeSelection ?? this.needsSedeSelection,
    );
  }
}

class AuthNotifier extends StateNotifier<AuthState> {
  final AuthRepository _repository;
  final LocalStorageService _storage;
  final SupabaseClient? _supabase;
  StreamSubscription<dynamic>? _authSubscription;

  AuthNotifier(this._repository, this._storage, [this._supabase]) : super(const AuthState(isLoading: true)) {
    _initSession();
    if (_supabase != null) {
      _listenToAuthChanges();
    }
  }

  void _listenToAuthChanges() {
    _authSubscription = _supabase?.auth.onAuthStateChange.listen((data) async {
      final event = data.event;
      final session = data.session;

      if (event == AuthChangeEvent.signedIn && session?.user != null) {
        // Al regresar del flujo de OAuth de Google en Web o móvil,
        // rehidratar si cambió el usuario O si el usuario en memoria no tiene empresa asignada
        final current = state.currentUser;
        if (current == null || current.id != session!.user.id || (current.empresaId?.isEmpty ?? true)) {
          await _initSession();
        }
      } else if (event == AuthChangeEvent.signedOut) {
        if (state.isAuthenticated) {
          state = const AuthState();
        }
      }
    });
  }

  Future<void> _initSession() async {
    try {
      final user = await _repository.getCurrentSession();
      if (user == null) {
        state = state.copyWith(isLoading: false);
        return;
      }
      await _hydrateUserData(user);
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
    }
  }

  Future<void> _hydrateUserData(UserMember user) async {
    Company? company;
    List<Company> allCompanies = [];
    List<AquacultureUnit> units = [];
    List<UserMember> team = [];

    final isSuperAdmin = user.email.toLowerCase() == 'especialistaacuicola@gmail.com';

    if (!isSuperAdmin) {
      try {
        allCompanies = await _repository.fetchUserCompanies(user.id);
      } catch (e) {
        debugPrint('[_hydrateUserData] Error al obtener compañías: $e');
      }

      final targetEmpresaId = (user.empresaId != null && user.empresaId!.isNotEmpty)
          ? user.empresaId!
          : (allCompanies.isNotEmpty ? allCompanies.first.id : null);

      if (targetEmpresaId != null && targetEmpresaId.isNotEmpty) {
        try {
          company = await _repository.fetchCompany(targetEmpresaId);
        } catch (e) {
          debugPrint('[_hydrateUserData] Error al obtener empresa: $e');
        }

        if (user.empresaId == null || user.empresaId!.isEmpty) {
          user = user.copyWith(empresaId: targetEmpresaId);
        }

        try {
          units = await _repository.fetchUnits(targetEmpresaId);
        } catch (e) {
          debugPrint('[_hydrateUserData] Error al obtener sedes: $e');
        }

        // Auto-crear sede principal si la empresa existe pero no tiene ninguna unidad.
        // Esto cubre el caso de wizards interrumpidos o vacíos de datos históricos.
        if (units.isEmpty && company != null) {
          try {
            debugPrint('[_hydrateUserData] Empresa sin sedes, creando sede principal...');
            final defaultUnit = await _repository.createUnit(
              targetEmpresaId,
              company.nombreComercial,
              // La sigla se genera en el repositorio con unicidad garantizada
              '',
              company.direccion,
            );
            units = [defaultUnit];
          } catch (e) {
            debugPrint('[_hydrateUserData] Error al auto-crear sede: $e');
          }
        }

        try {
          team = await _repository.fetchTeamMembers(targetEmpresaId);
        } catch (e) {
          debugPrint('[_hydrateUserData] Error al obtener miembros: $e');
        }
      }
    }

    // ── Resolución de sede activa ────────────────────────────────────────────
    // Prioridad: localStorage-por-usuario > unidadAcuicolaId del perfil en DB
    // En ambos casos, validamos que el ID pertenezca realmente a las units cargadas
    // (evita usar sedes de una empresa anterior).
    final unitIds = units.map((u) => u.id).toSet();

    String? savedId = _storage.getActiveSedeIdForUser(user.id);
    if (savedId != null && !unitIds.contains(savedId)) {
      savedId = null; // Sede guardada no pertenece a esta empresa — descartar
    }

    String? profileId = user.unidadAcuicolaId;
    if (profileId != null && !unitIds.contains(profileId)) {
      profileId = null; // Sede del perfil no pertenece a esta empresa — descartar
    }

    String? activeId = savedId ?? profileId;
    bool needsSedeSelection = false;

    if (activeId == null && units.isNotEmpty) {
      if (units.length == 1) {
        // Una sola sede → activar automáticamente, sin preguntar al usuario
        activeId = units.first.id;
        await _storage.setActiveSedeIdForUser(user.id, activeId);
      } else {
        // Múltiples sedes sin preferencia → mostrar pantalla de selección
        needsSedeSelection = true;
      }
    }

    state = state.copyWith(
      isLoading: false,
      isGoogleLoading: false,
      currentUser: user,
      currentCompany: company,
      availableCompanies: allCompanies,
      units: units,
      teamMembers: team,
      activeUnitId: activeId,
      needsSedeSelection: needsSedeSelection,
    );
  }

  Future<bool> signIn(String email, String password) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final user = await _repository.signInWithEmailPassword(email, password);
      await _hydrateUserData(user);
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
      return false;
    }
  }

  Future<UserMember?> signInWithGoogle() async {
    state = state.copyWith(isLoading: true, isGoogleLoading: true, errorMessage: null);
    try {
      final user = await _repository.signInWithGoogle();
      if (user != null) {
        if (user.empresaId != null && user.empresaId!.isNotEmpty) {
          await _hydrateUserData(user);
        } else {
          // Usuario nuevo pendiente de configurar empresa
          state = state.copyWith(isLoading: false, isGoogleLoading: false, currentUser: user);
        }
      } else {
        state = state.copyWith(isLoading: false, isGoogleLoading: false);
      }
      return user;
    } catch (e) {
      state = state.copyWith(isLoading: false, isGoogleLoading: false, errorMessage: e.toString());
      return null;
    }
  }

  Future<bool> setupCompanyForUser({
    String? adminNombre,
    String? adminCedula,
    String? adminTelefono,
    required String companyNombre,
    required String companyNit,
    required String companyUbicacion,
    required String unitNombre,
    required String unitSigla,
    List<String>? especiesHabilitadas,
    String? primerEstanqueNombre,
    double? primerEstanqueCapacidadM3,
    String? primerEstanqueTipo,
  }) async {
    final user = state.currentUser;
    if (user == null) return false;

    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final admin = await _repository.setupCompanyForUser(
        userId: user.id,
        userEmail: user.email,
        userName: adminNombre?.trim().isNotEmpty == true ? adminNombre!.trim() : user.nombre,
        adminCedula: adminCedula,
        adminTelefono: adminTelefono,
        companyNombre: companyNombre,
        companyNit: companyNit,
        companyUbicacion: companyUbicacion,
        unitNombre: unitNombre,
        unitSigla: unitSigla,
        especiesHabilitadas: especiesHabilitadas,
        primerEstanqueNombre: primerEstanqueNombre,
        primerEstanqueCapacidadM3: primerEstanqueCapacidadM3,
        primerEstanqueTipo: primerEstanqueTipo,
      );

      // Sincronizar inmediatamente el currentUser para que el Router Guard detecte hasCompany = true
      state = state.copyWith(currentUser: admin);

      await _hydrateUserData(admin);
      return true;
    } catch (e) {
      debugPrint('[setupCompanyForUser] Error capturado: $e');
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
      return false;
    }
  }

  Future<bool> redeemInvitation(String token, String password) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final user = await _repository.registerWithInvitationToken(token, password);
      await _hydrateUserData(user);
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
      return false;
    }
  }

  Future<bool> registerCompanyWithAdmin({
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
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final user = await _repository.registerCompanyWithAdmin(
        adminNombres: adminNombres,
        adminApellidos: adminApellidos,
        adminCedulaNit: adminCedulaNit,
        adminContacto: adminContacto,
        adminEmail: adminEmail,
        adminPassword: adminPassword,
        companyNombre: companyNombre,
        companyUbicacion: companyUbicacion,
        companyNit: companyNit,
        companyEmail: companyEmail,
        companyRegistroIca: companyRegistroIca,
        companyRegistroAunap: companyRegistroAunap,
      );
      state = state.copyWith(currentUser: user);
      await _hydrateUserData(user);
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
      return false;
    }
  }

  Future<bool> createTeamMember({
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
  }) async {
    final comp = state.currentCompany;
    if (comp == null) return false;

    try {
      final newMember = await _repository.createTeamMember(
        empresaId: comp.id,
        nombre: nombre,
        email: email,
        cedula: cedula,
        telefono: telefono,
        role: role,
        unidadAcuicolaId: unidadAcuicolaId ?? state.activeUnitId,
        permisoGlobalEmpresa: permisoGlobalEmpresa,
        salarioBase: salarioBase,
        periodoPago: periodoPago,
        password: password,
      );
      final updatedList = [...state.teamMembers, newMember];
      state = state.copyWith(teamMembers: updatedList);
      return true;
    } catch (e) {
      state = state.copyWith(errorMessage: e.toString());
      return false;
    }
  }

  Future<bool> updateTeamMember(UserMember member) async {
    try {
      final updated = await _repository.updateTeamMember(member);
      final updatedList = state.teamMembers.map((m) => m.id == updated.id ? updated : m).toList();
      state = state.copyWith(teamMembers: updatedList);
      return true;
    } catch (e) {
      state = state.copyWith(errorMessage: e.toString());
      return false;
    }
  }

  Future<void> selectCompany(String companyId) async {
    state = state.copyWith(isLoading: true);
    try {
      final comp = await _repository.fetchCompany(companyId);
      final units = await _repository.fetchUnits(companyId);
      final firstUnitId = units.isNotEmpty ? units.first.id : null;
      if (firstUnitId != null) {
        await _storage.setActiveSedeId(firstUnitId);
      }
      final updatedUser = state.currentUser?.copyWith(
        empresaId: companyId,
        unidadAcuicolaId: firstUnitId,
      );
      state = state.copyWith(
        isLoading: false,
        currentUser: updatedUser,
        currentCompany: comp,
        units: units,
        activeUnitId: firstUnitId,
      );
    } catch (_) {
      state = state.copyWith(isLoading: false);
    }
  }

  Future<void> selectActiveUnit(String unitId) async {
    final userId = state.currentUser?.id;
    if (userId != null) {
      await _storage.setActiveSedeIdForUser(userId, unitId);
    }
    final updatedUser = state.currentUser?.copyWith(unidadAcuicolaId: unitId);
    state = state.copyWith(
      activeUnitId: unitId,
      currentUser: updatedUser,
      needsSedeSelection: false,
    );
  }

  Future<void> reloadCompanyAndUnits() async {
    final user = state.currentUser;
    if (user != null) {
      await _hydrateUserData(user);
    }
  }

  Future<void> sendPasswordReset(String email) async {
    await _repository.sendPasswordResetEmail(email);
  }

  Future<void> updateCompany(Company company) async {
    try {
      await _repository.updateCompany(company);
      state = state.copyWith(currentCompany: company);
    } catch (_) {}
  }

  Future<void> signOut() async {
    // Solo limpiamos tokens y sessionUserId. La preferencia de sede (por usuario)
    // se conserva para que el próximo login la recuerde automáticamente.
    try {
      await _repository.signOut();
    } catch (_) {}
    state = const AuthState();
  }


  @override
  void dispose() {
    _authSubscription?.cancel();
    super.dispose();
  }
}

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  final repo = ref.watch(authRepositoryProvider);
  final storage = ref.watch(localStorageServiceProvider);
  final supabase = ref.watch(supabaseClientProvider);
  return AuthNotifier(repo, storage, supabase);
});
