import 'package:fishbit_finance/modules/auth_tenant/domain/models/user_member.dart';
import 'package:fishbit_finance/modules/auth_tenant/domain/models/company.dart';
import 'package:fishbit_finance/modules/auth_tenant/domain/models/aquaculture_unit.dart';
import 'package:fishbit_finance/modules/auth_tenant/domain/repositories/auth_repository.dart';
import 'package:fishbit_finance/core/storage/local_storage_service.dart';
import 'package:fishbit_finance/modules/auth_tenant/presentation/providers/auth_provider.dart';

class FakeAuthRepository implements AuthRepository {
  final UserMember? mockUser;
  final List<Company> mockCompanies;
  final List<AquacultureUnit> mockUnits;
  final List<UserMember> mockTeam;
  final bool shouldFail;

  FakeAuthRepository({
    this.mockUser,
    this.mockCompanies = const [],
    this.mockUnits = const [],
    this.mockTeam = const [],
    this.shouldFail = false,
  });

  @override
  Future<UserMember?> getCurrentSession() async {
    if (shouldFail) throw Exception('Session retrieval network error');
    return mockUser;
  }

  @override
  Future<UserMember> signInWithEmailPassword(String email, String password) async {
    if (shouldFail) throw Exception('Invalid credentials');
    return mockUser ??
        UserMember(
          id: 'u-login',
          email: email,
          nombre: 'Usuario Autenticado',
          role: UserRole.admin,
          empresaId: 'emp-1',
          creadoEn: DateTime(2026, 1, 1),
        );
  }

  @override
  Future<UserMember?> signInWithGoogle() async => mockUser;

  @override
  Future<List<Company>> fetchUserCompanies(String userId) async => mockCompanies;

  @override
  Future<Company?> fetchCompany(String companyId) async {
    final match = mockCompanies.where((c) => c.id == companyId);
    return match.isNotEmpty ? match.first : null;
  }

  @override
  Future<List<AquacultureUnit>> fetchUnits(String companyId) async => mockUnits;

  @override
  Future<List<UserMember>> fetchTeamMembers(String companyId) async => mockTeam;

  @override
  Future<void> signOut() async {}

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class FakeLocalStorageService implements LocalStorageService {
  String? activeSedeId;

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

class AuthNotifierMock extends AuthNotifier {
  AuthNotifierMock(AuthState initialState)
      : super(FakeAuthRepository(), FakeLocalStorageService()) {
    state = initialState;
  }
}
