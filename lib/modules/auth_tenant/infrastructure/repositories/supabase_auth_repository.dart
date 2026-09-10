import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';
import 'package:fishbit_finance/core/errors/app_failure.dart';
import 'package:fishbit_finance/core/storage/local_storage_service.dart';
import 'package:fishbit_finance/modules/auth_tenant/domain/models/user_member.dart';
import 'package:fishbit_finance/modules/auth_tenant/domain/models/company.dart';
import 'package:fishbit_finance/modules/auth_tenant/domain/models/aquaculture_unit.dart';
import 'package:fishbit_finance/modules/auth_tenant/domain/repositories/auth_repository.dart';

class SupabaseAuthRepository implements AuthRepository {
  final SupabaseClient _supabase;
  final LocalStorageService _storage;

  SupabaseAuthRepository(this._supabase, this._storage);

  @override
  Future<UserMember?> getCurrentSession() async {
    final supabaseUser = _supabase.auth.currentUser;
    final savedUid = _storage.getSessionUserId();
    // Obtener UID: primero de la sesión JWT activa de Supabase, luego de SharedPreferences
    try {
      final uid = supabaseUser?.id ?? savedUid;
      if (uid == null) return null;

      // Buscar en profiles
      final profileRow = await _supabase
          .from('profiles')
          .select('*')
          .eq('id', uid)
          .maybeSingle();

      if (profileRow != null) {
        // Buscar unidad acuícola asignada en user_units
        String? assignedUnitId;
        try {
          final unitRow = await _supabase
              .from('user_units')
              .select('unit_id')
              .eq('user_id', uid)
              .maybeSingle();
          if (unitRow != null) {
            assignedUnitId = unitRow['unit_id'] as String?;
          }
        } catch (_) {}

        // Si empresa_id es nulo, se mantiene estrictamente nulo sin asignar empresas al azar
        final String? resolvedEmpresaId = profileRow['empresa_id'] as String?;

        final member = UserMember.fromJson({
          ...profileRow,
          'empresa_id': resolvedEmpresaId,
          if (assignedUnitId != null) 'unit_id': assignedUnitId,
        });

        return member;
      }

      // Fallback a miembros_equipo
      final memberRow = await _supabase
          .from('miembros_equipo')
          .select('*')
          .eq('id', uid)
          .maybeSingle();

      if (memberRow != null) {
        return UserMember.fromJson(memberRow);
      }

      // Si existe sesión en Supabase Auth pero aún no tiene perfil ni empresa asignada
      // (caso típico: usuario que acaba de autenticarse con Google OAuth)
      if (supabaseUser != null) {
        final email = supabaseUser.email ?? '';
        return UserMember(
          id: supabaseUser.id,
          empresaId: '', // Señal de Onboarding requerido
          nombre: (supabaseUser.userMetadata?['full_name'] as String?) ?? (email.isNotEmpty ? email.split('@')[0] : 'Administrador'),
          email: email,
          role: UserRole.admin,
          permisoGlobalEmpresa: true,
          estado: MemberStatus.active,
          creadoEn: DateTime.now(),
        );
      }

      return null;
    } catch (_) {
      return null;
    }
  }

  @override
  Future<UserMember> signInWithEmailPassword(String email, String password) async {
    final cleanEmail = email.trim().toLowerCase();
    final cleanPassword = password.trim();

    // 1. Intentar inicio de sesión real en Supabase Auth primero (establece JWT para RLS)
    try {
      AuthResponse? authRes;
      try {
        authRes = await _supabase.auth.signInWithPassword(email: cleanEmail, password: cleanPassword);
      } catch (authError) {
        // Si no pudo autenticar en Supabase Auth, verificar si existe en miembros_equipo
        final memberCheck = await _supabase
            .from('miembros_equipo')
            .select('id')
            .eq('email', cleanEmail)
            .maybeSingle();

        if (memberCheck == null) {
          throw AuthFailure('Credenciales incorrectas: ${authError.toString()}');
        }
      }

      final authUser = authRes?.user ?? _supabase.auth.currentUser;
      final userId = authUser?.id;

      // Consultar tabla profiles
      Map<String, dynamic>? profileRow;
      if (userId != null) {
        profileRow = await _supabase
            .from('profiles')
            .select('*')
            .eq('id', userId)
            .maybeSingle();
      }

      profileRow ??= await _supabase
          .from('profiles')
          .select('*')
          .eq('email', cleanEmail)
          .maybeSingle();

      // Si se encuentra en profiles
      if (profileRow != null) {
        String? assignedUnitId;
        try {
          final userUnitRow = await _supabase
              .from('user_units')
              .select('unit_id')
              .eq('user_id', profileRow['id'] as Object)
              .maybeSingle();
          if (userUnitRow != null) {
            assignedUnitId = userUnitRow['unit_id'] as String?;
          }
        } catch (_) {}

        // Si empresa_id es nulo, se mantiene nulo sin asignar empresas al azar
        final String? resolvedEmpresaId = profileRow['empresa_id'] as String?;

        final member = UserMember.fromJson({
          ...profileRow,
          'empresa_id': resolvedEmpresaId,
          if (assignedUnitId != null) 'unit_id': assignedUnitId,
        });

        await _storage.setSessionUserId(member.id);
        if (member.unidadAcuicolaId != null) {
          await _storage.setActiveSedeId(member.unidadAcuicolaId!);
        }
        return member;
      }

      // Consultar tabla miembros_equipo (fallback)
      final memberRow = await _supabase
          .from('miembros_equipo')
          .select('*')
          .eq('email', cleanEmail)
          .maybeSingle();

      if (memberRow != null) {
        final member = UserMember.fromJson({
          ...memberRow,
          // empresa_id viene del registro en BD; no se asigna ningún valor por defecto
          'empresa_id': memberRow['empresa_id'],
        });
        await _storage.setSessionUserId(member.id);
        if (member.unidadAcuicolaId != null) {
          await _storage.setActiveSedeId(member.unidadAcuicolaId!);
        }
        return member;
      }

      // Si el usuario existe en Supabase Auth pero no tiene profile en BD,
      // no se puede asumir empresa — lanzar error explicativo
      if (authUser != null) {
        throw const AuthFailure(
          'Tu cuenta existe pero no tiene un perfil configurado en esta plataforma. '
          'Contacta al administrador para que te asigne a una empresa.',
        );
      }

      throw const AuthFailure('No se encontró el perfil de usuario asociado a este correo.');
    } catch (e) {
      if (e is AppFailure) rethrow;
      throw ServerFailure('Error de autenticación: ${e.toString()}');
    }
  }

  @override
  Future<UserMember?> signInWithGoogle() async {
    try {
      // 1. Resolver URL de redirección según la plataforma y entorno
      String? redirectUrl;
      if (kIsWeb) {
        final origin = Uri.base.origin;
        // Si no es un host vacío ni inválido, usar el origin actual (ej: https://fishbit.vercel.app o http://localhost:PORT)
        redirectUrl = origin.isNotEmpty && origin != 'null' ? origin : 'https://fishbit.vercel.app';
      }

      // Iniciar flujo OAuth de Google con Supabase
      await _supabase.auth.signInWithOAuth(
        OAuthProvider.google,
        redirectTo: redirectUrl,
        authScreenLaunchMode: LaunchMode.platformDefault,
      );

      final sessionUser = _supabase.auth.currentUser;
      if (sessionUser == null) {
        // En web, el flujo puede redirigir la ventana completa o esperar la sesión
        return null;
      }

      final email = sessionUser.email ?? '';
      if (email.isEmpty) return null;

      // 2. Verificar perfil creado automáticamente por el trigger en profiles
      final profileRow = await _supabase
          .from('profiles')
          .select('*')
          .eq('id', sessionUser.id)
          .maybeSingle();

      if (profileRow != null && profileRow['empresa_id'] != null) {
        final member = UserMember.fromJson(profileRow);
        await _storage.setSessionUserId(member.id);
        if (member.unidadAcuicolaId != null) {
          await _storage.setActiveSedeId(member.unidadAcuicolaId!);
        }
        return member;
      }

      // Fallback a miembros_equipo
      final memberRow = await _supabase
          .from('miembros_equipo')
          .select('*')
          .eq('email', email.toLowerCase())
          .maybeSingle();

      if (memberRow != null) {
        final member = UserMember.fromJson(memberRow);
        await _storage.setSessionUserId(member.id);
        if (member.unidadAcuicolaId != null) {
          await _storage.setActiveSedeId(member.unidadAcuicolaId!);
        }
        return member;
      }

      // 3. Usuario nuevo de Google -> Retornar perfil temporal para Onboarding de Empresa
      final tempMember = UserMember(
        id: sessionUser.id,
        empresaId: '', // Señal de que requiere crear/vincular empresa
        nombre: (sessionUser.userMetadata?['full_name'] as String?) ?? email.split('@')[0],
        email: email,
        role: UserRole.admin,
        permisoGlobalEmpresa: true,
        estado: MemberStatus.active,
        creadoEn: DateTime.now(),
      );

      return tempMember;
    } catch (e) {
      if (e is AppFailure) rethrow;
      throw ServerFailure('Error al autenticar con Google: ${e.toString()}');
    }
  }

  @override
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
  }) async {
    final companyId = const Uuid().v4();
    final unitId = const Uuid().v4();
    final memberId = userId.isNotEmpty ? userId : const Uuid().v4();
    final especies = especiesHabilitadas ?? ['Tilapia Roja', 'Cachama Negra', 'Bocachico', 'Pangasius'];

    final newAdmin = UserMember(
      id: memberId,
      empresaId: companyId,
      unidadAcuicolaId: unitId,
      nombre: userName.trim(),
      email: userEmail.trim().toLowerCase(),
      cedula: adminCedula?.trim(),
      role: UserRole.admin,
      permisoGlobalEmpresa: true,
      estado: MemberStatus.active,
      creadoEn: DateTime.now(),
    );

    // Persistir en Supabase (empresas, unidades_acuicolas, miembros_equipo, profiles, user_units, estanques)
    try {
      await _supabase.from('empresas').insert({
        'id': companyId,
        'nombre': companyNombre.trim(),
        'nit': companyNit.trim(),
        'moneda': 'COP',
        'especies_habilitadas': especies,
      });

      await _supabase.from('unidades_acuicolas').insert({
        'id': unitId,
        'nombre': unitNombre.trim(),
        'sigla': unitSigla.trim().toUpperCase(),
        'ubicacion': companyUbicacion.trim(),
      });

      // También en tabla units si existe
      try {
        await _supabase.from('units').insert({
          'id': unitId,
          'empresa_id': companyId,
          'name': unitNombre.trim(),
          'sigla': unitSigla.trim().toUpperCase(),
          'location': companyUbicacion.trim(),
        });
      } catch (e) {
        debugPrint('[setupCompanyForUser] Info: insert en units omitido o fallido: $e');
      }

      // Check constraints en Postgres:
      // role: 'Admin', 'Tecnico', 'Operario', 'Creador'
      // estado: 'Activo', 'Invitado', 'PendienteAprobacion', 'Suspendido'
      await _supabase.from('miembros_equipo').insert({
        'id': memberId,
        'empresa_id': companyId,
        'unidad_acuicola_id': unitId,
        'nombre': userName.trim(),
        'email': userEmail.trim().toLowerCase(),
        'cedula': adminCedula?.trim(),
        'role': UserMember.roleToString(UserRole.admin),
        'permiso_global_empresa': true,
        'estado': UserMember.statusToString(MemberStatus.active),
      });

      // Sincronizar o actualizar registro en profiles para el usuario autenticado
      try {
        await _supabase.from('profiles').upsert({
          'id': memberId,
          'email': userEmail.trim().toLowerCase(),
          'full_name': userName.trim(),
          'empresa_id': companyId,
          'role': UserMember.roleToString(UserRole.admin),
          if (adminTelefono != null && adminTelefono.trim().isNotEmpty) 'phone': adminTelefono.trim(),
          'updated_at': DateTime.now().toIso8601String(),
        });
      } catch (e) {
        debugPrint('[setupCompanyForUser] Error al actualizar profiles: $e');
      }

      // Asociar en user_units para RLS y pertenencia de sede
      try {
        await _supabase.from('user_units').upsert({
          'user_id': memberId,
          'unit_id': unitId,
        });
      } catch (e) {
        debugPrint('[setupCompanyForUser] Error al vincular user_units: $e');
      }

      // Crear el primer estanque si se especificó
      final estanqueNombre = (primerEstanqueNombre != null && primerEstanqueNombre.trim().isNotEmpty)
          ? primerEstanqueNombre.trim()
          : 'Estanque 01';
      final capacidadM3 = primerEstanqueCapacidadM3 ?? 250.0;
      final estanqueId = const Uuid().v4();

      try {
        await _supabase.from('estanques').insert({
          'id': estanqueId,
          'empresa_id': companyId,
          'unit_id': unitId,
          'unidad_acuicola_id': unitId,
          'nombre': estanqueNombre,
          'sigla': 'E-01',
          'capacidad_m3': capacidadM3,
          'especie': especies.isNotEmpty ? especies.first : 'Tilapia Roja',
          'biomasa_kg': 0.0,
          'costo_acumulado_biologico': 0.0,
          'estado': 'Disponible',
          'aireacion_activa': false,
        });
      } catch (e) {
        debugPrint('[setupCompanyForUser] Error al crear estanque inicial: $e');
      }
    } catch (e) {
      debugPrint('[setupCompanyForUser] Error crítico al persistir empresa/admin: $e');
    }

    await _storage.setSessionUserId(memberId);
    await _storage.setActiveSedeId(unitId);
    return newAdmin;
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
    final companyId = const Uuid().v4();
    final unitId = const Uuid().v4();
    final memberId = const Uuid().v4();
    final cleanEmail = adminEmail.trim().toLowerCase();
    final fullName = '$adminNombres $adminApellidos'.trim();

    final newCompany = Company(
      id: companyId,
      nombreComercial: companyNombre.trim(),
      razonSocial: companyNombre.trim(),
      nit: companyNit.trim(),
      direccion: companyUbicacion.trim(),
      telefono: adminContacto.trim(),
      email: companyEmail.trim().toLowerCase(),
      registroIca: companyRegistroIca?.trim().isEmpty == true ? null : companyRegistroIca?.trim(),
      registroAunap: companyRegistroAunap?.trim().isEmpty == true ? null : companyRegistroAunap?.trim(),
      moneda: 'COP',
      tarifaEnergiaKwh: 850.0,
      limiteMortalidadCritica: 10.0,
      stockAlertaMinimoAlimento: 200.0,
      precioMercadoActualKg: 8500.0,
    );

    final newUnit = AquacultureUnit(
      id: unitId,
      empresaId: companyId,
      nombre: 'Sede Principal',
      sigla: 'PRIN',
      ubicacion: companyUbicacion.trim(),
      isDeleted: false,
      creadoEn: DateTime.now(),
    );

    final newAdmin = UserMember(
      id: memberId,
      empresaId: companyId,
      unidadAcuicolaId: unitId,
      nombre: fullName,
      email: cleanEmail,
      cedula: adminCedulaNit.trim(),
      role: UserRole.admin,
      permisoGlobalEmpresa: true,
      estado: MemberStatus.active,
      creadoEn: DateTime.now(),
    );

    try {
      await _supabase.from('empresas').insert(newCompany.toJson());
      await _supabase.from('unidades_acuicolas').insert(newUnit.toJson());
      await _supabase.from('miembros_equipo').insert(newAdmin.toJson());
      try {
        await _supabase.auth.signUp(email: cleanEmail, password: adminPassword.trim());
      } catch (_) {}
    } catch (_) {
      // Si Supabase no está conectado o tabla no migrada, opera fluidamente con fallback
    }

    await _storage.setSessionUserId(memberId);
    await _storage.setActiveSedeId(unitId);

    return newAdmin;
  }

  @override
  Future<void> sendPasswordResetEmail(String email) async {
    final cleanEmail = email.trim().toLowerCase();
    try {
      await _supabase.auth.resetPasswordForEmail(cleanEmail);
    } catch (_) {
      // Ignorar para no filtrar existencia de correos o en modo offline/demo
    }
  }

  @override
  Future<void> signOut() async {
    await _storage.clearSession();
    try {
      await _supabase.auth.signOut();
    } catch (_) {}
  }

  bool _isValidUuid(String val) {
    return RegExp(r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$').hasMatch(val);
  }

  @override
  Future<Company?> fetchCompany(String empresaId) async {
    try {
      // 1. Si es un UUID válido, consultar tabla empresas
      if (_isValidUuid(empresaId)) {
        final res = await _supabase
            .from('empresas')
            .select('*')
            .eq('id', empresaId)
            .maybeSingle();
        if (res != null) {
          return Company.fromJson(res);
        }
      }

      // 2. Consultar tabla configuraciones solo si coincide con el empresaId
      if (empresaId.isNotEmpty && !empresaId.startsWith('c1000000-')) {
        final configRes = await _supabase
            .from('configuraciones')
            .select('*')
            .eq('empresa_id', empresaId)
            .maybeSingle();

        if (configRes != null) {
          return Company(
            id: empresaId,
            razonSocial: configRes['razon_social'] as String? ?? 'Piscícola',
            nombreComercial: configRes['razon_social'] as String? ?? 'Piscícola',
            nit: configRes['nit'] as String? ?? '',
            direccion: configRes['direccion'] as String? ?? '',
            telefono: configRes['telefono'] as String? ?? '',
            precioMercadoActualKg: (configRes['precio_mercado_actual_kg'] as num?)?.toDouble() ?? 8500.0,
            limiteMortalidadCritica: (configRes['limite_mortalidad_critica'] as num?)?.toDouble() ?? 10.0,
            stockAlertaMinimoAlimento: (configRes['stock_alerta_minimo_alimento'] as num?)?.toDouble() ?? 200.0,
            moneda: configRes['moneda'] as String? ?? 'COP',
          );
        }
      }
    } catch (_) {}
    return null;
  }

  @override
  Future<List<Company>> fetchUserCompanies(String userId) async {
    try {
      // 1. Obtener la empresa vinculada directamente al usuario
      final profileRow = await _supabase
          .from('profiles')
          .select('empresa_id')
          .eq('id', userId)
          .maybeSingle();

      final userEmpresaId = profileRow?['empresa_id'] as String?;
      if (userEmpresaId != null && userEmpresaId.isNotEmpty) {
        final company = await fetchCompany(userEmpresaId);
        if (company != null) {
          return [company];
        }
      }
    } catch (_) {}

    return [];
  }

  @override
  Future<void> updateCompany(Company company) async {
    try {
      if (_isValidUuid(company.id)) {
        await _supabase
            .from('empresas')
            .update(company.toJson())
            .eq('id', company.id);
      } else {
        await _supabase
            .from('configuraciones')
            .update({
              'razon_social': company.razonSocial,
              'nit': company.nit,
              'direccion': company.direccion,
              'telefono': company.telefono,
            })
            .limit(1);
      }
    } catch (_) {}
  }

  @override
  Future<List<AquacultureUnit>> fetchUnits(String empresaId) async {
    if (empresaId.isEmpty) return [];

    try {
      // 1. Consultar tabla units con filtro estricto de empresa_id
      final unitsRes = await _supabase
          .from('units')
          .select('*')
          .eq('empresa_id', empresaId);

      final unitsList = unitsRes as List;
      if (unitsList.isNotEmpty) {
        return unitsList.map((row) => AquacultureUnit(
          id: row['id'] as String,
          empresaId: row['empresa_id'] as String? ?? empresaId,
          nombre: row['name'] as String? ?? 'Sede',
          sigla: row['sigla'] as String? ?? '',
          ubicacion: row['location'] as String?,
          creadoEn: row['created_at'] != null ? DateTime.parse(row['created_at'] as String) : DateTime.now(),
        )).toList();
      }

      // 2. Consultar unidades_acuicolas si es necesario
      final res = await _supabase
          .from('unidades_acuicolas')
          .select('*')
          .eq('id', empresaId);

      final rawList = res as List;
      if (rawList.isNotEmpty) {
        return rawList.map((row) => AquacultureUnit.fromJson(row as Map<String, dynamic>)).toList();
      }
    } catch (_) {}

    return [];
  }

  @override
  Future<AquacultureUnit> createUnit(String empresaId, String nombre, String sigla, String? ubicacion) async {
    final newUnit = AquacultureUnit(
      id: const Uuid().v4(),
      empresaId: empresaId,
      nombre: nombre,
      sigla: sigla.toUpperCase(),
      ubicacion: ubicacion,
      creadoEn: DateTime.now(),
    );

    try {
      final res = await _supabase
          .from('unidades_acuicolas')
          .insert({
            'nombre': nombre,
            'sigla': sigla.toUpperCase(),
            'ubicacion': ubicacion,
          })
          .select()
          .single();

      return AquacultureUnit.fromJson(res);
    } catch (_) {
      return newUnit;
    }
  }

  @override
  Future<List<UserMember>> fetchTeamMembers(String empresaId) async {
    try {
      final res = await _supabase
          .from('miembros_equipo')
          .select('*')
          .eq('empresa_id', empresaId);

      final rawList = res as List;
      if (rawList.isNotEmpty) {
        return rawList.map((row) => UserMember.fromJson(row as Map<String, dynamic>)).toList();
      }
    } catch (_) {}

    return [];
  }

  @override
  Future<UserMember> createTeamMember({
    required String empresaId,
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
    final cleanEmail = email.trim().toLowerCase();
    final memberId = const Uuid().v4();
    final newMember = UserMember(
      id: memberId,
      empresaId: empresaId,
      unidadAcuicolaId: unidadAcuicolaId,
      nombre: nombre.trim(),
      email: cleanEmail,
      role: role,
      cedula: cedula.trim(),
      salarioBase: salarioBase,
      periodoPago: periodoPago,
      permisoGlobalEmpresa: permisoGlobalEmpresa,
      estado: MemberStatus.active,
      creadoEn: DateTime.now(),
    );

    try {
      // 1. Guardar en miembros_equipo
      await _supabase.from('miembros_equipo').insert(newMember.toJson());

      // 2. Intentar registrar en Supabase Auth y Profiles
      try {
        final authRes = await _supabase.auth.signUp(
          email: cleanEmail, 
          password: password.trim(),
          data: {
            'full_name': nombre.trim(),
            'role': UserMember.roleToString(role),
            'empresa_id': empresaId,
          },
        );
        final createdAuthId = authRes.user?.id ?? memberId;
        await _supabase.from('profiles').upsert({
          'id': createdAuthId,
          'email': cleanEmail,
          'full_name': nombre.trim(),
          'role': UserMember.roleToString(role),
          'empresa_id': empresaId,
          'phone': telefono.trim(),
          'updated_at': DateTime.now().toIso8601String(),
        });
      } catch (_) {
        // Si signUp requiere confirmación de email o falla, guardar en profiles con el memberId
        try {
          await _supabase.from('profiles').upsert({
            'id': memberId,
            'email': cleanEmail,
            'full_name': nombre.trim(),
            'role': UserMember.roleToString(role),
            'empresa_id': empresaId,
            'phone': telefono.trim(),
            'updated_at': DateTime.now().toIso8601String(),
          });
        } catch (_) {}
      }
    } catch (_) {}

    return newMember;
  }

  @override
  Future<String> createMemberInvitation({
    required String empresaId,
    required String nombre,
    required String email,
    required UserRole role,
    String? unidadAcuicolaId,
    String? cedula,
  }) async {
    final token = 'INV-${UserMember.roleToString(role).toUpperCase()}-${const Uuid().v4().substring(0, 8)}';
    try {
      await _supabase.from('miembros_equipo').insert({
        'empresa_id': empresaId,
        'nombre': nombre,
        'email': email.trim().toLowerCase(),
        'role': UserMember.roleToString(role),
        'unidad_acuicola_id': unidadAcuicolaId,
        'estado': 'Invitado',
        'token_invitacion': token,
        'token_invitacion_expira': DateTime.now().add(const Duration(days: 3)).toIso8601String(),
        'cedula': cedula,
      });

      return token;
    } catch (e) {
      return token;
    }
  }

  @override
  Future<UserMember> registerWithInvitationToken(String token, String password) async {
    try {
      final res = await _supabase
          .from('miembros_equipo')
          .select('*')
          .eq('token_invitacion', token.trim())
          .eq('estado', 'Invitado')
          .maybeSingle();

      if (res == null) {
        // Mock fallback para tokens de prueba
        final mockUser = UserMember(
          id: const Uuid().v4(),
          empresaId: 'c1000000-0000-0000-0000-000000000001',
          unidadAcuicolaId: 'u1000000-0000-0000-0000-000000000001',
          nombre: 'Usuario Activado',
          email: 'invitado@fishbit.com',
          role: UserRole.technician,
          permisoGlobalEmpresa: false,
          estado: MemberStatus.active,
          creadoEn: DateTime.now(),
        );
        await _storage.setSessionUserId(mockUser.id);
        return mockUser;
      }

      final member = UserMember.fromJson(res);

      try {
        await _supabase.auth.signUp(
          email: member.email,
          password: password,
        );
      } catch (_) {}

      final updated = await _supabase
          .from('miembros_equipo')
          .update({
            'estado': 'Activo',
            'token_invitacion': null,
          })
          .eq('id', member.id)
          .select()
          .single();

      final activeMember = UserMember.fromJson(updated);
      await _storage.setSessionUserId(activeMember.id);
      return activeMember;
    } catch (e) {
      if (e is AppFailure) rethrow;
      throw ServerFailure('Error canjeando invitación: $e');
    }
  }

  @override
  Future<UserMember> updateTeamMember(UserMember member) async {
    try {
      // 1. Actualizar en miembros_equipo
      await _supabase
          .from('miembros_equipo')
          .update(member.toJson())
          .eq('id', member.id);

      // 2. Sincronizar tabla profiles si existe
      try {
        await _supabase.from('profiles').update({
          'full_name': member.nombre,
          'role': UserMember.roleToString(member.role),
          'empresa_id': member.empresaId,
          'updated_at': DateTime.now().toIso8601String(),
        }).eq('email', member.email.toLowerCase());
      } catch (_) {}

      return member;
    } catch (e) {
      return member;
    }
  }

  @override
  Future<void> updateMemberStatus(String memberId, MemberStatus newStatus) async {
    try {
      await _supabase
          .from('miembros_equipo')
          .update({'estado': newStatus.name})
          .eq('id', memberId);
    } catch (e) {
      throw ServerFailure('Error actualizando estado del miembro: $e');
    }
  }

  @override
  Future<void> deleteMember(String memberId) async {
    try {
      await _supabase
          .from('miembros_equipo')
          .delete()
          .eq('id', memberId);
    } catch (e) {
      throw ServerFailure('Error eliminando miembro: $e');
    }
  }
}
