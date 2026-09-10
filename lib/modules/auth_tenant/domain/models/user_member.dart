enum UserRole { creator, admin, sanitaryDirector, technician, operator }

extension UserRoleX on UserRole {
  String get roleDisplayName {
    switch (this) {
      case UserRole.creator:
        return 'Master SaaS Creator';
      case UserRole.admin:
        return 'Administrador Piscícola';
      case UserRole.sanitaryDirector:
        return 'Director Sanitario Acuícola';
      case UserRole.technician:
        return 'Técnico Acuícola';
      case UserRole.operator:
        return 'Operario Acuícola';
    }
  }
}

enum MemberStatus { active, invited, pendingApproval, suspended }

/// Entidad inmutable de Miembro de Equipo con RBAC y Aislamiento por Empresa
class UserMember {
  final String id;
  final String? authUserId;
  final String? empresaId;
  final String nombre;
  final String email;
  final UserRole role;
  final String? unidadAcuicolaId;
  final bool permisoGlobalEmpresa;
  final MemberStatus estado;
  final String? tokenInvitacion;
  final String? cedula;
  final double salarioBase;
  final String periodoPago; // 'Quincenal' | 'Mensual'
  final DateTime creadoEn;

  const UserMember({
    required this.id,
    this.authUserId,
    this.empresaId,
    required this.nombre,
    required this.email,
    required this.role,
    this.unidadAcuicolaId,
    this.permisoGlobalEmpresa = false,
    this.estado = MemberStatus.active,
    this.tokenInvitacion,
    this.cedula,
    this.salarioBase = 0.0,
    this.periodoPago = 'Quincenal',
    required this.creadoEn,
  });

  bool get isCreator => role == UserRole.creator;
  bool get isAdmin => role == UserRole.admin;
  bool get isSanitaryDirector => role == UserRole.sanitaryDirector;
  bool get isTechnician => role == UserRole.technician;
  bool get isOperator => role == UserRole.operator;

  String get roleDisplayName {
    switch (role) {
      case UserRole.creator:
        return 'Master SaaS Creator';
      case UserRole.admin:
        return 'Administrador Piscícola';
      case UserRole.sanitaryDirector:
        return 'Director Sanitario Acuícola';
      case UserRole.technician:
        return 'Técnico Acuícola';
      case UserRole.operator:
        return 'Operario Acuícola';
    }
  }

  static UserRole parseRole(String val) {
    final v = val
        .toLowerCase()
        .replaceAll('á', 'a')
        .replaceAll('é', 'e')
        .replaceAll('í', 'i')
        .replaceAll('ó', 'o')
        .replaceAll('ú', 'u')
        .replaceAll('_', '')
        .replaceAll(' ', '');
    switch (v) {
      case 'creador':
      case 'creator':
      case 'saasmaster':
        return UserRole.creator;
      case 'admin':
      case 'administrador':
      case 'administradorpiscicola':
        return UserRole.admin;
      case 'sanitario':
      case 'directorsanitario':
      case 'directorsanitarioacuicola':
      case 'veterinario':
      case 'sanitarydirector':
        return UserRole.sanitaryDirector;
      case 'tecnico':
      case 'tecnicoacuicola':
      case 'technician':
        return UserRole.technician;
      default:
        return UserRole.operator;
    }
  }

  static MemberStatus parseStatus(String val) {
    switch (val.toLowerCase()) {
      case 'activo':
      case 'active':
        return MemberStatus.active;
      case 'invitado':
      case 'invited':
        return MemberStatus.invited;
      case 'pendienteaprobacion':
        return MemberStatus.pendingApproval;
      case 'suspendido':
      case 'suspended':
        return MemberStatus.suspended;
      default:
        return MemberStatus.active;
    }
  }

  static String statusToString(MemberStatus s) {
    switch (s) {
      case MemberStatus.active:
        return 'Activo';
      case MemberStatus.invited:
        return 'Invitado';
      case MemberStatus.pendingApproval:
        return 'PendienteAprobacion';
      case MemberStatus.suspended:
        return 'Suspendido';
    }
  }

  static String roleToString(UserRole r) {
    switch (r) {
      case UserRole.creator:
        return 'Creador';
      case UserRole.admin:
        return 'Admin';
      case UserRole.sanitaryDirector:
        return 'Director Sanitario';
      case UserRole.technician:
        return 'Tecnico';
      case UserRole.operator:
        return 'Operario';
    }
  }

  UserMember copyWith({
    String? id,
    String? authUserId,
    String? empresaId,
    String? nombre,
    String? email,
    UserRole? role,
    String? unidadAcuicolaId,
    bool? permisoGlobalEmpresa,
    MemberStatus? estado,
    String? tokenInvitacion,
    String? cedula,
    double? salarioBase,
    String? periodoPago,
    DateTime? creadoEn,
  }) {
    return UserMember(
      id: id ?? this.id,
      authUserId: authUserId ?? this.authUserId,
      empresaId: empresaId ?? this.empresaId,
      nombre: nombre ?? this.nombre,
      email: email ?? this.email,
      role: role ?? this.role,
      unidadAcuicolaId: unidadAcuicolaId ?? this.unidadAcuicolaId,
      permisoGlobalEmpresa: permisoGlobalEmpresa ?? this.permisoGlobalEmpresa,
      estado: estado ?? this.estado,
      tokenInvitacion: tokenInvitacion ?? this.tokenInvitacion,
      cedula: cedula ?? this.cedula,
      salarioBase: salarioBase ?? this.salarioBase,
      periodoPago: periodoPago ?? this.periodoPago,
      creadoEn: creadoEn ?? this.creadoEn,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'empresa_id': empresaId,
        'nombre': nombre,
        'email': email.trim().toLowerCase(),
        'role': roleToString(role),
        'unidad_acuicola_id': unidadAcuicolaId,
        'permiso_global_empresa': permisoGlobalEmpresa,
        'estado': statusToString(estado),
        'cedula': cedula,
        'salario_base': salarioBase,
        'periodo_pago': periodoPago,
      };

  factory UserMember.fromJson(Map<String, dynamic> json) {
    final rawRole = json['role'] as String? ?? (json['is_superadmin'] == true ? 'Creador' : 'Operario');
    final rawName = json['full_name'] as String? ?? json['nombre'] as String? ?? 'Usuario FishBit';
    final isSuper = json['is_superadmin'] as bool? ?? json['permiso_global_empresa'] as bool? ?? false;
    final rawEmail = (json['email'] as String? ?? '').trim().toLowerCase();
    final rawUnitId = json['unit_id'] as String? ?? json['unidad_acuicola_id'] as String?;
    final rawEmpresaId = json['empresa_id'] as String?;

    return UserMember(
      id: json['id'] as String,
      authUserId: json['auth_user_id'] as String? ?? json['id'] as String?,
      empresaId: rawEmpresaId,
      nombre: rawName,
      email: rawEmail,
      role: parseRole(rawRole),
      unidadAcuicolaId: rawUnitId,
      permisoGlobalEmpresa: isSuper,
      estado: parseStatus(json['estado'] as String? ?? 'Activo'),
      tokenInvitacion: json['token_invitacion'] as String?,
      cedula: json['cedula'] as String?,
      salarioBase: (json['salario_base'] as num?)?.toDouble() ?? 0.0,
      periodoPago: json['periodo_pago'] as String? ?? 'Quincenal',
      creadoEn: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : json['creado_en'] != null
              ? DateTime.parse(json['creado_en'] as String)
              : DateTime.now(),
    );
  }
}
