import '../models/user_member.dart';
import '../models/company.dart';
import '../models/aquaculture_unit.dart';

abstract class AuthRepository {
  Future<UserMember?> getCurrentSession();
  Future<UserMember> signInWithEmailPassword(String email, String password);
  Future<UserMember?> signInWithGoogle();
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
    double? primerEstanqueCapacidadM3,
    String? primerEstanqueTipo,
  });
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
  });
  Future<void> sendPasswordResetEmail(String email);
  Future<void> signOut();

  Future<Company?> fetchCompany(String empresaId);
  Future<List<Company>> fetchUserCompanies(String userId);
  Future<void> updateCompany(Company company);

  Future<List<AquacultureUnit>> fetchUnits(String empresaId);
  Future<AquacultureUnit> createUnit(String empresaId, String nombre, String sigla, String? ubicacion);

  Future<List<UserMember>> fetchTeamMembers(String empresaId);
  Future<UserMember> createTeamMember({
    required String empresaId,
    required String nombre,
    required String email,
    required String cedula,
    required String telefono,
    required UserRole role,
    String? unidadAcuicolaId,
    bool permisoGlobalEmpresa,
    double salarioBase,
    String periodoPago,
    required String password,
  });
  Future<String> createMemberInvitation({
    required String empresaId,
    required String nombre,
    required String email,
    required UserRole role,
    String? unidadAcuicolaId,
    String? cedula,
  });
  Future<UserMember> registerWithInvitationToken(String token, String password);
  Future<UserMember> updateTeamMember(UserMember member);
  Future<void> updateMemberStatus(String memberId, MemberStatus newStatus);
  Future<void> deleteMember(String memberId);
}
