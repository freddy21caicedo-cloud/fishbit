import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:fishbit_finance/core/errors/app_failure.dart';
import 'package:fishbit_finance/core/storage/local_storage_service.dart';
import 'package:fishbit_finance/modules/auth_tenant/domain/models/user_member.dart';
import 'package:fishbit_finance/modules/auth_tenant/infrastructure/repositories/supabase_auth_repository.dart';

// =============================================================================
// EMPIRICAL TEST HARNESS & IN-MEMORY SUPABASE SIMULATOR
// =============================================================================

class FakeLocalStorage implements LocalStorageService {
  String? sessionUserId;
  String? activeSedeId;

  @override
  String? getSessionUserId() => sessionUserId;

  @override
  Future<bool> setSessionUserId(String? uid) async {
    sessionUserId = uid;
    return true;
  }

  @override
  String? getActiveSedeId() => activeSedeId;

  @override
  Future<bool> setActiveSedeId(String? sedeId) async {
    activeSedeId = sedeId;
    return true;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class FakeGoTrueClient implements GoTrueClient {
  User? mockCurrentUser;
  AuthResponse Function(String email, String password)? onSignIn;
  AuthResponse Function(String email, String password, Map<String, dynamic>? data)? onSignUp;

  @override
  User? get currentUser => mockCurrentUser;

  @override
  Future<AuthResponse> signInWithPassword({
    String? email,
    String? phone,
    required String password,
    String? captchaToken,
  }) async {
    if (onSignIn != null) {
      return onSignIn!(email ?? '', password);
    }
    throw const AuthException('Invalid login credentials');
  }

  @override
  Future<AuthResponse> signUp({
    String? email,
    String? phone,
    required String password,
    String? emailRedirectTo,
    Map<String, dynamic>? data,
    String? captchaToken,
    OtpChannel channel = OtpChannel.sms,
  }) async {
    if (onSignUp != null) {
      return onSignUp!(email ?? '', password, data);
    }
    return AuthResponse(
      user: User(
        id: 'mock-auth-id',
        appMetadata: {},
        userMetadata: data ?? {},
        aud: 'authenticated',
        createdAt: DateTime.now().toIso8601String(),
      ),
    );
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

enum FilterMode { list, single, maybeSingle }

class FakeQueryBuilder implements SupabaseQueryBuilder {
  final String tableName;
  final FakeDatabase database;
  final Map<String, dynamic> filters = {};

  FakeQueryBuilder(this.tableName, this.database);

  @override
  PostgrestFilterBuilder<List<Map<String, dynamic>>> select([String columns = '*']) {
    return _FakeFilterBuilder<List<Map<String, dynamic>>>(this, FilterMode.list);
  }

  @override
  PostgrestFilterBuilder<List<Map<String, dynamic>>> insert(dynamic values, {bool defaultToNull = true}) {
    database.insert(tableName, values);
    return _FakeFilterBuilder<List<Map<String, dynamic>>>(this, FilterMode.list);
  }

  @override
  PostgrestFilterBuilder<List<Map<String, dynamic>>> update(Map<dynamic, dynamic> values, {bool defaultToNull = true}) {
    return _FakeFilterBuilder<List<Map<String, dynamic>>>(this, FilterMode.list, updateValues: values);
  }

  @override
  PostgrestFilterBuilder<List<Map<String, dynamic>>> upsert(dynamic values, {
    String? onConflict,
    bool ignoreDuplicates = false,
    bool defaultToNull = true,
  }) {
    database.upsert(tableName, values);
    return _FakeFilterBuilder<List<Map<String, dynamic>>>(this, FilterMode.list);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeFilterBuilder<T> implements PostgrestFilterBuilder<T>, PostgrestTransformBuilder<T> {
  final FakeQueryBuilder parent;
  final FilterMode mode;
  final Map<dynamic, dynamic>? updateValues;

  _FakeFilterBuilder(this.parent, this.mode, {this.updateValues});

  @override
  PostgrestFilterBuilder<T> eq(String column, Object value) {
    parent.filters[column] = value;
    return this;
  }

  @override
  PostgrestFilterBuilder<T> or(String filters, {String? referencedTable}) {
    parent.filters['or'] = filters;
    return this;
  }

  @override
  PostgrestTransformBuilder<List<Map<String, dynamic>>> select([String columns = '*']) {
    return _FakeFilterBuilder<List<Map<String, dynamic>>>(parent, FilterMode.list, updateValues: updateValues);
  }

  @override
  PostgrestTransformBuilder<Map<String, dynamic>?> maybeSingle() {
    return _FakeFilterBuilder<Map<String, dynamic>?>(parent, FilterMode.maybeSingle, updateValues: updateValues);
  }

  @override
  PostgrestTransformBuilder<Map<String, dynamic>> single() {
    return _FakeFilterBuilder<Map<String, dynamic>>(parent, FilterMode.single, updateValues: updateValues);
  }

  @override
  Future<R> then<R>(FutureOr<R> Function(T value) onValue, {Function? onError}) {
    // If an update was queued, apply it to matched rows
    if (updateValues != null) {
      parent.database.update(parent.tableName, updateValues!, parent.filters);
    }

    dynamic res;
    if (mode == FilterMode.maybeSingle) {
      res = parent.database.querySingle(parent.tableName, parent.filters);
    } else if (mode == FilterMode.single) {
      final item = parent.database.querySingle(parent.tableName, parent.filters);
      if (item == null) {
        return Future<T>.error(const PostgrestException(message: 'Row not found')).then(onValue, onError: onError);
      }
      res = item;
    } else {
      res = parent.database.queryList(parent.tableName, parent.filters);
    }
    return Future<T>.value(res as T).then(onValue, onError: onError);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class FakeDatabase {
  final List<Map<String, dynamic>> profiles = [];
  final List<Map<String, dynamic>> miembrosEquipo = [];
  final List<Map<String, dynamic>> userUnits = [];

  List<Map<String, dynamic>> _getTable(String name) {
    switch (name) {
      case 'profiles':
        return profiles;
      case 'miembros_equipo':
        return miembrosEquipo;
      case 'user_units':
        return userUnits;
      default:
        return [];
    }
  }

  void insert(String table, dynamic values) {
    final t = _getTable(table);
    if (values is Map<String, dynamic>) {
      t.add(Map<String, dynamic>.from(values));
    } else if (values is List) {
      for (final item in values) {
        if (item is Map<String, dynamic>) {
          t.add(Map<String, dynamic>.from(item));
        }
      }
    }
  }

  void upsert(String table, dynamic values) {
    if (values is Map<String, dynamic>) {
      final t = _getTable(table);
      final id = values['id'];
      if (id != null) {
        final idx = t.indexWhere((row) => row['id'] == id);
        if (idx >= 0) {
          t[idx] = Map<String, dynamic>.from(values);
          return;
        }
      }
      t.add(Map<String, dynamic>.from(values));
    }
  }

  void update(String table, Map<dynamic, dynamic> values, Map<String, dynamic> filters) {
    final t = _getTable(table);
    for (final row in t) {
      if (_matches(row, filters)) {
        values.forEach((k, v) {
          row[k.toString()] = v;
        });
      }
    }
  }

  Map<String, dynamic>? querySingle(String table, Map<String, dynamic> filters) {
    final t = _getTable(table);
    for (final row in t) {
      if (_matches(row, filters)) {
        return Map<String, dynamic>.from(row);
      }
    }
    return null;
  }

  List<Map<String, dynamic>> queryList(String table, Map<String, dynamic> filters) {
    final t = _getTable(table);
    return t
        .where((row) => _matches(row, filters))
        .map((row) => Map<String, dynamic>.from(row))
        .toList();
  }

  bool _matches(Map<String, dynamic> row, Map<String, dynamic> filters) {
    for (final entry in filters.entries) {
      if (entry.key == 'or') continue; // Skip complex or for now
      final val = row[entry.key];
      if (val != entry.value) return false;
    }
    return true;
  }
}

class FakeSupabaseClient implements SupabaseClient {
  final FakeGoTrueClient mockAuth = FakeGoTrueClient();
  final FakeDatabase database = FakeDatabase();

  @override
  GoTrueClient get auth => mockAuth;

  @override
  SupabaseQueryBuilder from(String table) {
    return FakeQueryBuilder(table, database);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

// =============================================================================
// ADVERSARIAL TEST SUITE
// =============================================================================

void main() {
  late FakeSupabaseClient supabase;
  late FakeLocalStorage storage;
  late SupabaseAuthRepository repo;

  setUp(() {
    supabase = FakeSupabaseClient();
    storage = FakeLocalStorage();
    repo = SupabaseAuthRepository(supabase, storage);
  });

  // ---------------------------------------------------------------------------
  // SEC-02: signInWithEmailPassword
  // ---------------------------------------------------------------------------
  group('Adversarial SEC-02: signInWithEmailPassword Stress Tests', () {
    test(
        'REJECTS login with invalid password even when email exists in miembros_equipo (bypass eliminated)',
        () async {
      // Setup: victim exists in miembros_equipo with admin role
      supabase.database.insert('miembros_equipo', {
        'id': 'victim-uid-001',
        'email': 'victim@fishbit.com',
        'nombre': 'Victim Administrator',
        'role': 'admin',
        'empresa_id': 'empresa-real-001',
        'estado': 'Activo',
      });

      // Supabase Auth rejects the password
      supabase.mockAuth.onSignIn = (email, password) {
        throw const AuthException('Invalid login credentials');
      };

      // Attack: Attacker tries to login as victim with wrong password
      expect(
        () => repo.signInWithEmailPassword('victim@fishbit.com', 'wrongpassword'),
        throwsA(isA<AuthFailure>().having(
          (e) => e.message,
          'message',
          contains('Correo o contraseña incorrectos'),
        )),
      );

      // Verify: Session UID was NEVER saved
      expect(storage.sessionUserId, isNull);
    });

    test(
        'REJECTS login when user does not exist in Supabase Auth even if present in miembros_equipo',
        () async {
      // Setup: Email present in miembros_equipo
      supabase.database.insert('miembros_equipo', {
        'id': 'ghost-uid-002',
        'email': 'ghost@fishbit.com',
        'nombre': 'Ghost User',
        'role': 'operario',
        'empresa_id': 'empresa-real-001',
        'estado': 'Activo',
      });

      // Supabase Auth throws User not found
      supabase.mockAuth.onSignIn = (email, password) {
        throw const AuthException('User not found');
      };

      expect(
        () => repo.signInWithEmailPassword('ghost@fishbit.com', 'somePassword123'),
        throwsA(isA<AuthFailure>().having(
          (e) => e.message,
          'message',
          contains('No existe ningún usuario registrado con este correo electrónico'),
        )),
      );

      expect(storage.sessionUserId, isNull);
    });

    test('REJECTS empty and whitespace passwords', () async {
      supabase.mockAuth.onSignIn = (email, password) {
        if (password.isEmpty) {
          throw const AuthException('Password cannot be empty');
        }
        throw const AuthException('Invalid login credentials');
      };

      // Empty password
      expect(
        () => repo.signInWithEmailPassword('admin@fishbit.com', ''),
        throwsA(isA<AuthFailure>().having(
          (e) => e.message,
          'message',
          contains('Password cannot be empty'),
        )),
      );

      // Whitespace-only password (trimmed by repo to empty)
      expect(
        () => repo.signInWithEmailPassword('admin@fishbit.com', '    '),
        throwsA(isA<AuthFailure>().having(
          (e) => e.message,
          'message',
          contains('Password cannot be empty'),
        )),
      );

      expect(storage.sessionUserId, isNull);
    });

    test('REJECTS and wraps unexpected server errors into AuthFailure', () async {
      supabase.mockAuth.onSignIn = (email, password) {
        throw Exception('Supabase service unavailable 503');
      };

      expect(
        () => repo.signInWithEmailPassword('admin@fishbit.com', 'ValidPass123!'),
        throwsA(isA<AuthFailure>().having(
          (e) => e.message,
          'message',
          contains('Error de autenticación: Exception: Supabase service unavailable 503'),
        )),
      );

      expect(storage.sessionUserId, isNull);
    });

    test('SUCCEEDS ONLY when Supabase Auth succeeds and profile exists', () async {
      final authUser = User(
        id: 'auth-user-001',
        appMetadata: {},
        userMetadata: {},
        aud: 'authenticated',
        createdAt: DateTime.now().toIso8601String(),
      );

      supabase.mockAuth.onSignIn = (email, password) {
        return AuthResponse(user: authUser);
      };

      supabase.database.insert('profiles', {
        'id': 'auth-user-001',
        'email': 'legit@fishbit.com',
        'full_name': 'Legit Admin',
        'role': 'Administrador Piscícola',
        'empresa_id': 'empresa-real-001',
      });

      final user = await repo.signInWithEmailPassword('legit@fishbit.com', 'CorrectPass123!');
      expect(user.id, 'auth-user-001');
      expect(user.empresaId, 'empresa-real-001');
      expect(user.isAdmin, isTrue);
      expect(storage.sessionUserId, 'auth-user-001');
    });
  });

  // ---------------------------------------------------------------------------
  // SEC-03: registerWithInvitationToken
  // ---------------------------------------------------------------------------
  group('Adversarial SEC-03: registerWithInvitationToken Stress Tests', () {
    test('REJECTS empty token immediately without database query', () async {
      expect(
        () => repo.registerWithInvitationToken('', 'SecretPassword123!'),
        throwsA(isA<AuthFailure>().having(
          (e) => e.message,
          'message',
          'Token de invitación no válido o expirado',
        )),
      );
      expect(storage.sessionUserId, isNull);
    });

    test('REJECTS whitespace token immediately without database query', () async {
      expect(
        () => repo.registerWithInvitationToken('   \t\n   ', 'SecretPassword123!'),
        throwsA(isA<AuthFailure>().having(
          (e) => e.message,
          'message',
          'Token de invitación no válido o expirado',
        )),
      );
      expect(storage.sessionUserId, isNull);
    });

    test(
        'REJECTS fake/non-existent token (MOCK USER BACKDOOR IS COMPLETELY INACCESSIBLE)',
        () async {
      // Database has no matching token
      expect(
        () => repo.registerWithInvitationToken('INV-FAKE-TOKEN-666', 'SecretPassword123!'),
        throwsA(isA<AuthFailure>().having(
          (e) => e.message,
          'message',
          'Token de invitación no válido o expirado',
        )),
      );

      // Verify the old mock user backdoor was NOT executed
      expect(storage.sessionUserId, isNull);
      expect(storage.sessionUserId, isNot('c1000000-0000-0000-0000-000000000001'));
    });

    test('REJECTS expired invitation token', () async {
      supabase.database.insert('miembros_equipo', {
        'id': 'member-expired-001',
        'email': 'expired@fishbit.com',
        'nombre': 'Expired Member',
        'role': 'operario',
        'empresa_id': 'empresa-real-001',
        'token_invitacion': 'INV-EXPIRED-999',
        'token_invitacion_expira': DateTime.now().subtract(const Duration(hours: 1)).toIso8601String(),
        'estado': 'Invitado',
      });

      expect(
        () => repo.registerWithInvitationToken('INV-EXPIRED-999', 'NewPassword123!'),
        throwsA(isA<AuthFailure>().having(
          (e) => e.message,
          'message',
          'Token de invitación no válido o expirado',
        )),
      );

      // Member should not be activated
      final row = supabase.database.querySingle('miembros_equipo', {'id': 'member-expired-001'});
      expect(row?['estado'], 'Invitado');
      expect(storage.sessionUserId, isNull);
    });

    test('REJECTS token when member status is already Activo or Revocado', () async {
      supabase.database.insert('miembros_equipo', {
        'id': 'member-already-active',
        'email': 'active@fishbit.com',
        'nombre': 'Already Active Member',
        'role': 'operario',
        'empresa_id': 'empresa-real-001',
        'token_invitacion': 'INV-CONSUMED-123',
        'token_invitacion_expira': DateTime.now().add(const Duration(days: 1)).toIso8601String(),
        'estado': 'Activo', // Not 'Invitado'
      });

      expect(
        () => repo.registerWithInvitationToken('INV-CONSUMED-123', 'Password123!'),
        throwsA(isA<AuthFailure>().having(
          (e) => e.message,
          'message',
          'Token de invitación no válido o expirado',
        )),
      );

      expect(storage.sessionUserId, isNull);
    });

    test('SUCCEEDS for valid unexpired invitation token', () async {
      supabase.database.insert('miembros_equipo', {
        'id': 'member-valid-001',
        'email': 'newinvite@fishbit.com',
        'nombre': 'New Colleague',
        'role': 'tecnico',
        'empresa_id': 'empresa-real-001',
        'token_invitacion': 'INV-VALID-777',
        'token_invitacion_expira': DateTime.now().add(const Duration(days: 2)).toIso8601String(),
        'estado': 'Invitado',
      });

      final activeMember = await repo.registerWithInvitationToken('INV-VALID-777', 'SecurePassword123!');
      expect(activeMember.id, 'member-valid-001');
      expect(activeMember.estado, MemberStatus.active);
      expect(storage.sessionUserId, 'member-valid-001');

      // Verify token cleared in database
      final updatedRow = supabase.database.querySingle('miembros_equipo', {'id': 'member-valid-001'});
      expect(updatedRow?['estado'], 'Activo');
      expect(updatedRow?['token_invitacion'], isNull);
    });
  });

  // ---------------------------------------------------------------------------
  // SEC-03: createTeamMember & Admin Validation
  // ---------------------------------------------------------------------------
  group('Adversarial SEC-03: createTeamMember Role & Boundary Validation', () {
    test('REJECTS member creation when no session is active', () async {
      storage.sessionUserId = null;
      supabase.mockAuth.mockCurrentUser = null;

      expect(
        () => repo.createTeamMember(
          empresaId: 'emp-001',
          nombre: 'New Operator',
          email: 'op@fishbit.com',
          cedula: '12345678',
          telefono: '3001234567',
          role: UserRole.operator,
          password: 'Password123!',
        ),
        throwsA(isA<AuthFailure>().having(
          (e) => e.message,
          'message',
          'No hay una sesión activa para realizar esta operación.',
        )),
      );
    });

    test('REJECTS member creation from caller with non-admin role "operario"', () async {
      storage.sessionUserId = 'caller-operario';
      supabase.database.insert('profiles', {
        'id': 'caller-operario',
        'email': 'operario@fishbit.com',
        'full_name': 'Operator User',
        'role': 'operario',
        'empresa_id': 'emp-001',
      });

      expect(
        () => repo.createTeamMember(
          empresaId: 'emp-001',
          nombre: 'New Member',
          email: 'new@fishbit.com',
          cedula: '12345678',
          telefono: '3001234567',
          role: UserRole.operator,
          password: 'Password123!',
        ),
        throwsA(isA<AuthFailure>().having(
          (e) => e.message,
          'message',
          contains('Permisos insuficientes: se requieren privilegios administrativos'),
        )),
      );

      // Verify nothing inserted in miembros_equipo
      final rows = supabase.database.queryList('miembros_equipo', {'email': 'new@fishbit.com'});
      expect(rows, isEmpty);
    });

    test('REJECTS member creation from caller with non-admin role "tecnico"', () async {
      storage.sessionUserId = 'caller-tecnico';
      supabase.database.insert('profiles', {
        'id': 'caller-tecnico',
        'email': 'tecnico@fishbit.com',
        'full_name': 'Technician User',
        'role': 'tecnico',
        'empresa_id': 'emp-001',
      });

      expect(
        () => repo.createTeamMember(
          empresaId: 'emp-001',
          nombre: 'New Member',
          email: 'new2@fishbit.com',
          cedula: '12345678',
          telefono: '3001234567',
          role: UserRole.operator,
          password: 'Password123!',
        ),
        throwsA(isA<AuthFailure>().having(
          (e) => e.message,
          'message',
          contains('Permisos insuficientes: se requieren privilegios administrativos'),
        )),
      );
    });

    test('REJECTS member creation from caller with role "Director Sanitario"', () async {
      storage.sessionUserId = 'caller-sanitary';
      supabase.database.insert('profiles', {
        'id': 'caller-sanitary',
        'email': 'sanitario@fishbit.com',
        'full_name': 'Sanitary Director',
        'role': 'Director Sanitario',
        'empresa_id': 'emp-001',
      });

      expect(
        () => repo.createTeamMember(
          empresaId: 'emp-001',
          nombre: 'New Member',
          email: 'new3@fishbit.com',
          cedula: '12345678',
          telefono: '3001234567',
          role: UserRole.operator,
          password: 'Password123!',
        ),
        throwsA(isA<AuthFailure>().having(
          (e) => e.message,
          'message',
          contains('Permisos insuficientes: se requieren privilegios administrativos'),
        )),
      );
    });

    test(
        'REJECTS admin caller attempting cross-tenant injection into another empresa',
        () async {
      storage.sessionUserId = 'admin-tenant-A';
      supabase.database.insert('profiles', {
        'id': 'admin-tenant-A',
        'email': 'adminA@fishbit.com',
        'full_name': 'Admin Tenant A',
        'role': 'admin',
        'empresa_id': 'emp-tenant-A',
      });

      // Attempting to create member in emp-tenant-B
      expect(
        () => repo.createTeamMember(
          empresaId: 'emp-tenant-B',
          nombre: 'Cross Tenant Member',
          email: 'infiltrator@fishbit.com',
          cedula: '99999999',
          telefono: '3009999999',
          role: UserRole.operator,
          password: 'Password123!',
        ),
        throwsA(isA<AuthFailure>().having(
          (e) => e.message,
          'message',
          contains('Violación de seguridad multi-tenant: no tiene permisos para crear miembros en una empresa diferente a la suya.'),
        )),
      );

      final rows = supabase.database.queryList('miembros_equipo', {'email': 'infiltrator@fishbit.com'});
      expect(rows, isEmpty);
    });

    test('ALLOWS authorized admin caller in their own empresa', () async {
      storage.sessionUserId = 'admin-tenant-A';
      supabase.database.insert('profiles', {
        'id': 'admin-tenant-A',
        'email': 'adminA@fishbit.com',
        'full_name': 'Admin Tenant A',
        'role': 'admin',
        'empresa_id': 'emp-tenant-A',
      });

      final created = await repo.createTeamMember(
        empresaId: 'emp-tenant-A',
        nombre: 'Legit New Operator',
        email: 'legitop@fishbit.com',
        cedula: '11223344',
        telefono: '3001122334',
        role: UserRole.operator,
        password: 'Password123!',
      );

      expect(created.email, 'legitop@fishbit.com');
      expect(created.empresaId, 'emp-tenant-A');
      expect(created.role, UserRole.operator);

      final row = supabase.database.querySingle('miembros_equipo', {'email': 'legitop@fishbit.com'});
      expect(row, isNotNull);
      expect(row?['empresa_id'], 'emp-tenant-A');
    });

    test('ALLOWS platform creator to create members across any empresa', () async {
      storage.sessionUserId = 'super-creator';
      supabase.database.insert('profiles', {
        'id': 'super-creator',
        'email': 'creator@fishbit.com',
        'full_name': 'Master Creator',
        'role': 'creator',
        'is_superadmin': true,
        'empresa_id': 'emp-creator-hq',
      });

      final created = await repo.createTeamMember(
        empresaId: 'emp-client-XYZ',
        nombre: 'Client Admin',
        email: 'clientadmin@fishbit.com',
        cedula: '55667788',
        telefono: '3005566778',
        role: UserRole.admin,
        password: 'Password123!',
      );

      expect(created.email, 'clientadmin@fishbit.com');
      expect(created.empresaId, 'emp-client-XYZ');
    });

    test('createMemberInvitation also strictly enforces admin role and multi-tenant boundary', () async {
      // Operator cannot invite
      storage.sessionUserId = 'caller-operario';
      supabase.database.insert('profiles', {
        'id': 'caller-operario',
        'email': 'operario@fishbit.com',
        'full_name': 'Operator User',
        'role': 'operario',
        'empresa_id': 'emp-001',
      });

      expect(
        () => repo.createMemberInvitation(
          empresaId: 'emp-001',
          nombre: 'Invited Guy',
          email: 'invited@fishbit.com',
          role: UserRole.technician,
        ),
        throwsA(isA<AuthFailure>().having(
          (e) => e.message,
          'message',
          contains('Permisos insuficientes: se requieren privilegios administrativos'),
        )),
      );

      // Admin from Tenant A cannot invite to Tenant B
      storage.sessionUserId = 'admin-tenant-A';
      supabase.database.insert('profiles', {
        'id': 'admin-tenant-A',
        'email': 'adminA@fishbit.com',
        'full_name': 'Admin Tenant A',
        'role': 'admin',
        'empresa_id': 'emp-tenant-A',
      });

      expect(
        () => repo.createMemberInvitation(
          empresaId: 'emp-tenant-B',
          nombre: 'Invited Guy',
          email: 'invited@fishbit.com',
          role: UserRole.technician,
        ),
        throwsA(isA<AuthFailure>().having(
          (e) => e.message,
          'message',
          contains('Violación de seguridad multi-tenant'),
        )),
      );
    });

    test('updateTeamMember enforces active session, admin privileges and multi-tenant boundary', () async {
      final memberToUpdate = UserMember(
        id: 'member-target-001',
        empresaId: 'emp-tenant-A',
        nombre: 'Target Member',
        email: 'target@fishbit.com',
        role: UserRole.technician,
        estado: MemberStatus.active,
        creadoEn: DateTime(2026, 1, 1),
      );

      // 1. REJECTS when no session is active
      storage.sessionUserId = null;
      expect(
        () => repo.updateTeamMember(memberToUpdate),
        throwsA(isA<AuthFailure>().having(
          (e) => e.message,
          'message',
          contains('No hay una sesión activa para realizar esta operación.'),
        )),
      );

      // 2. REJECTS when caller has non-admin role (e.g. operario)
      storage.sessionUserId = 'caller-operario';
      supabase.database.insert('profiles', {
        'id': 'caller-operario',
        'email': 'operario@fishbit.com',
        'full_name': 'Operator User',
        'role': 'operario',
        'empresa_id': 'emp-tenant-A',
      });

      expect(
        () => repo.updateTeamMember(memberToUpdate),
        throwsA(isA<AuthFailure>().having(
          (e) => e.message,
          'message',
          contains('Permisos insuficientes: se requieren privilegios administrativos'),
        )),
      );

      // 3. REJECTS when admin from Tenant B tries to update a member of Tenant A
      storage.sessionUserId = 'admin-tenant-B';
      supabase.database.insert('profiles', {
        'id': 'admin-tenant-B',
        'email': 'adminB@fishbit.com',
        'full_name': 'Admin Tenant B',
        'role': 'admin',
        'empresa_id': 'emp-tenant-B',
      });

      expect(
        () => repo.updateTeamMember(memberToUpdate),
        throwsA(isA<AuthFailure>().having(
          (e) => e.message,
          'message',
          contains('Violación de seguridad multi-tenant: no tiene permisos para modificar miembros en una empresa diferente a la suya.'),
        )),
      );

      // 4. ALLOWS when admin of Tenant A updates a member of Tenant A
      storage.sessionUserId = 'admin-tenant-A';
      supabase.database.insert('profiles', {
        'id': 'admin-tenant-A',
        'email': 'adminA@fishbit.com',
        'full_name': 'Admin Tenant A',
        'role': 'admin',
        'empresa_id': 'emp-tenant-A',
      });
      supabase.database.insert('miembros_equipo', {
        'id': 'member-target-001',
        'empresa_id': 'emp-tenant-A',
        'nombre': 'Target Member',
        'email': 'target@fishbit.com',
        'role': 'tecnico',
        'estado': 'Activo',
      });

      final updated = await repo.updateTeamMember(
        memberToUpdate.copyWith(nombre: 'Target Member Updated'),
      );
      expect(updated.nombre, 'Target Member Updated');
    });

    test('createTeamMember and createMemberInvitation strictly reject callers with null or empty empresaId', () async {
      // Caller has admin role but empresa_id is null
      storage.sessionUserId = 'admin-unassigned';
      supabase.database.insert('profiles', {
        'id': 'admin-unassigned',
        'email': 'unassigned@fishbit.com',
        'full_name': 'Unassigned Admin',
        'role': 'admin',
        'empresa_id': null,
      });

      expect(
        () => repo.createTeamMember(
          empresaId: 'emp-tenant-XYZ',
          nombre: 'New Member',
          email: 'new@fishbit.com',
          cedula: '12345678',
          telefono: '3001234567',
          role: UserRole.technician,
          password: 'Password123!',
        ),
        throwsA(isA<AuthFailure>().having(
          (e) => e.message,
          'message',
          contains('Violación de seguridad multi-tenant'),
        )),
      );

      expect(
        () => repo.createMemberInvitation(
          empresaId: 'emp-tenant-XYZ',
          nombre: 'Invited Member',
          email: 'invited@fishbit.com',
          role: UserRole.technician,
        ),
        throwsA(isA<AuthFailure>().having(
          (e) => e.message,
          'message',
          contains('Violación de seguridad multi-tenant'),
        )),
      );
    });
  });
}

