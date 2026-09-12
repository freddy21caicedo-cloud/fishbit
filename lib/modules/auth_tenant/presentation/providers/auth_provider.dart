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

  const AuthState({
    this.isLoading = false,
    this.currentUser,
    this.currentCompany,
    this.availableCompanies = const [],
    this.units = const [],
    this.teamMembers = const [],
    this.activeUnitId,
    this.errorMessage,
  });

  bool get isAuthenticated => currentUser != null;

  AuthState copyWith({
    bool? isLoading,
    UserMember? currentUser,
    Company? currentCompany,
    List<Company>? availableCompanies,
    List<AquacultureUnit>? units,
    List<UserMember>? teamMembers,
    String? activeUnitId,
    String? errorMessage,
  }) {
    return AuthState(
      isLoading: isLoading ?? this.isLoading,
      currentUser: currentUser ?? this.currentUser,
      currentCompany: currentCompany ?? this.currentCompany,
      availableCompanies: availableCompanies ?? this.availableCompanies,
      units: units ?? this.units,
      teamMembers: teamMembers ?? this.teamMembers,
      activeUnitId: activeUnitId ?? this.activeUnitId,
      errorMessage: errorMessage,
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

        try {
          units = await _repository.fetchUnits(targetEmpresaId);
        } catch (e) {
          debugPrint('[_hydrateUserData] Error al obtener sedes: $e');
        }

        try {
          team = await _repository.fetchTeamMembers(targetEmpresaId);
        } catch (e) {
          debugPrint('[_hydrateUserData] Error al obtener miembros: $e');
        }
      }
    }

    String? activeId = user.unidadAcuicolaId ?? _storage.getActiveSedeId();
    if ((activeId == null || activeId.isEmpty) && units.isNotEmpty) {
      activeId = units.first.id;
    }

    state = state.copyWith(
      isLoading: false,
      currentUser: user,
      currentCompany: company,
      availableCompanies: allCompanies,
      units: units,
      teamMembers: team,
      activeUnitId: activeId,
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
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final user = await _repository.signInWithGoogle();
      if (user != null) {
        if (user.empresaId != null && user.empresaId!.isNotEmpty) {
          await _hydrateUserData(user);
        } else {
          // Usuario nuevo pendiente de configurar empresa
          state = state.copyWith(isLoading: false, currentUser: user);
        }
      } else {
        state = state.copyWith(isLoading: false);
      }
      return user;
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
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
    await _storage.setActiveSedeId(unitId);
    final updatedUser = state.currentUser?.copyWith(unidadAcuicolaId: unitId);
    state = state.copyWith(activeUnitId: unitId, currentUser: updatedUser);
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
    await _repository.signOut();
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
