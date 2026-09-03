import 'package:flutter_test/flutter_test.dart';
import 'package:fishbit_finance/modules/auth_tenant/domain/models/user_member.dart';
import 'package:fishbit_finance/modules/auth_tenant/domain/models/company.dart';
import 'package:fishbit_finance/modules/auth_tenant/domain/models/aquaculture_unit.dart';
import 'package:fishbit_finance/modules/auth_tenant/presentation/providers/auth_provider.dart';
import '../../helpers/test_auth_helper.dart';

void main() {
  group('UserMember Domain Model Tests', () {
    test('Correctly parses roles from string variants', () {
      expect(UserMember.parseRole('creator'), UserRole.creator);
      expect(UserMember.parseRole('Creador'), UserRole.creator);
      expect(UserMember.parseRole('admin'), UserRole.admin);
      expect(UserMember.parseRole('Administrador Piscícola'), UserRole.admin);
      expect(UserMember.parseRole('sanitario'), UserRole.sanitaryDirector);
      expect(UserMember.parseRole('Director Sanitario'), UserRole.sanitaryDirector);
      expect(UserMember.parseRole('tecnico'), UserRole.technician);
      expect(UserMember.parseRole('technician'), UserRole.technician);
      expect(UserMember.parseRole('operario'), UserRole.operator);
      expect(UserMember.parseRole('unknown_role'), UserRole.operator);
    });

    test('Correctly verifies role helper getters', () {
      final admin = UserMember(
        id: 'u-1',
        nombre: 'Admin Piscícola',
        email: 'admin@fishbit.com',
        role: UserRole.admin,
        creadoEn: DateTime(2026, 1, 1),
      );
      expect(admin.isAdmin, isTrue);
      expect(admin.isCreator, isFalse);
      expect(admin.isSanitaryDirector, isFalse);
      expect(admin.isTechnician, isFalse);
      expect(admin.isOperator, isFalse);
      expect(admin.roleDisplayName, 'Administrador Piscícola');
    });

    test('Serializes to JSON and deserializes from JSON accurately', () {
      final member = UserMember(
        id: 'u-100',
        authUserId: 'auth-100',
        empresaId: 'emp-500',
        nombre: 'Carlos Acuícola',
        email: 'Carlos@FishBit.com',
        role: UserRole.sanitaryDirector,
        unidadAcuicolaId: 'unit-50',
        permisoGlobalEmpresa: true,
        estado: MemberStatus.active,
        cedula: '1098765432',
        salarioBase: 2500000.0,
        periodoPago: 'Quincenal',
        creadoEn: DateTime(2026, 8, 15, 10, 30),
      );

      final json = member.toJson();
      expect(json['id'], 'u-100');
      expect(json['email'], 'carlos@fishbit.com');
      expect(json['role'], 'Director Sanitario');
      expect(json['permiso_global_empresa'], true);
      expect(json['salario_base'], 2500000.0);

      final fromJson = UserMember.fromJson({
        'id': 'u-100',
        'auth_user_id': 'auth-100',
        'empresa_id': 'emp-500',
        'nombre': 'Carlos Acuícola',
        'email': 'carlos@fishbit.com',
        'role': 'Director Sanitario',
        'unit_id': 'unit-50',
        'is_superadmin': true,
        'cedula': '1098765432',
        'salario_base': 2500000.0,
        'periodo_pago': 'Quincenal',
        'created_at': '2026-08-15T10:30:00.000',
      });

      expect(fromJson.id, 'u-100');
      expect(fromJson.email, 'carlos@fishbit.com');
      expect(fromJson.role, UserRole.sanitaryDirector);
      expect(fromJson.permisoGlobalEmpresa, isTrue);
      expect(fromJson.salarioBase, 2500000.0);
    });

    test('copyWith creates modified immutable clones correctly', () {
      final original = UserMember(
        id: 'u-1',
        nombre: 'Pedro',
        email: 'pedro@fishbit.com',
        role: UserRole.operator,
        creadoEn: DateTime(2026, 1, 1),
      );

      final updated = original.copyWith(
        nombre: 'Pedro Promovido',
        role: UserRole.technician,
        salarioBase: 1800000.0,
      );

      expect(updated.id, 'u-1');
      expect(updated.nombre, 'Pedro Promovido');
      expect(updated.role, UserRole.technician);
      expect(updated.salarioBase, 1800000.0);
      expect(original.nombre, 'Pedro');
    });
  });

  group('Company & AquacultureUnit Domain Model Tests', () {
    test('Company parses from JSON with sensible aquaculture defaults', () {
      final json = {
        'id': 'emp-default',
        'nombre_comercial': 'Acuícola San Jerónimo',
        'razon_social': 'San Jerónimo SAS',
        'nit': '901234567-8',
        'tarifa_energia_kwh': 920.5,
        'precio_mercado_actual_kg': 8900.0,
      };

      final company = Company.fromJson(json);
      expect(company.id, 'emp-default');
      expect(company.nombreComercial, 'Acuícola San Jerónimo');
      expect(company.moneda, 'COP');
      expect(company.tarifaEnergiaKwh, 920.5);
      expect(company.precioMercadoActualKg, 8900.0);
      expect(company.limiteMortalidadCritica, 10.0);
      expect(company.especiesHabilitadas, contains('Tilapia Roja'));
    });

    test('AquacultureUnit serializes and parses properly', () {
      final unit = AquacultureUnit(
        id: 'unit-meta-01',
        empresaId: 'emp-001',
        nombre: 'Sede Puerto López',
        sigla: 'PL-01',
        ubicacion: 'Meta, Colombia',
        creadoEn: DateTime(2026, 5, 1),
      );

      final json = unit.toJson();
      expect(json['id'], 'unit-meta-01');
      expect(json['nombre'], 'Sede Puerto López');
      expect(json['sigla'], 'PL-01');
      expect(json['is_deleted'], isFalse);

      final parsed = AquacultureUnit.fromJson(json);
      expect(parsed.id, 'unit-meta-01');
      expect(parsed.empresaId, 'emp-001');
      expect(parsed.nombre, 'Sede Puerto López');
    });
  });

  group('AuthNotifier State Machine Tests', () {
    test('Initial session hydration loads user, company, units and team correctly', () async {
      final testUser = UserMember(
        id: 'user-001',
        email: 'operador@fishbit.com',
        nombre: 'Operador Principal',
        role: UserRole.admin,
        empresaId: 'emp-001',
        unidadAcuicolaId: 'unit-001',
        creadoEn: DateTime(2026, 1, 1),
      );

      const testCompany = Company(
        id: 'emp-001',
        nombreComercial: 'Acuícola del Valle',
        razonSocial: 'Acuícola del Valle SAS',
        nit: '900111222-3',
      );

      final testUnit = AquacultureUnit(
        id: 'unit-001',
        empresaId: 'emp-001',
        nombre: 'Estación 1',
        sigla: 'E1',
        creadoEn: DateTime(2026, 1, 1),
      );

      final repo = FakeAuthRepository(
        mockUser: testUser,
        mockCompanies: [testCompany],
        mockUnits: [testUnit],
        mockTeam: [testUser],
      );
      final storage = FakeLocalStorageService();

      final notifier = AuthNotifier(repo, storage);

      // Wait microtasks for async session init
      await Future<void>.delayed(const Duration(milliseconds: 50));

      expect(notifier.state.isLoading, isFalse);
      expect(notifier.state.isAuthenticated, isTrue);
      expect(notifier.state.currentUser?.id, 'user-001');
      expect(notifier.state.currentCompany?.nombreComercial, 'Acuícola del Valle');
      expect(notifier.state.units.length, 1);
      expect(notifier.state.activeUnitId, 'unit-001');
    });

    test('Handles sign in failure gracefully without leaving state in loading', () async {
      final repo = FakeAuthRepository(shouldFail: true);
      final storage = FakeLocalStorageService();

      final notifier = AuthNotifier(repo, storage);
      await Future<void>.delayed(const Duration(milliseconds: 50));

      final success = await notifier.signIn('bad@email.com', 'wrongpass');
      expect(success, isFalse);
      expect(notifier.state.isLoading, isFalse);
      expect(notifier.state.errorMessage, contains('Invalid credentials'));
    });

    test('signOut clears state and resets authentication status', () async {
      final testUser = UserMember(
        id: 'user-logout',
        email: 'logout@fishbit.com',
        nombre: 'Usuario Saliente',
        role: UserRole.technician,
        creadoEn: DateTime(2026, 1, 1),
      );

      final repo = FakeAuthRepository(mockUser: testUser);
      final storage = FakeLocalStorageService();
      final notifier = AuthNotifier(repo, storage);
      await Future<void>.delayed(const Duration(milliseconds: 50));

      expect(notifier.state.isAuthenticated, isTrue);

      await notifier.signOut();
      expect(notifier.state.isAuthenticated, isFalse);
      expect(notifier.state.currentUser, isNull);
      expect(notifier.state.currentCompany, isNull);
    });
  });
}
