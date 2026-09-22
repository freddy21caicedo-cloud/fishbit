import 'package:flutter_test/flutter_test.dart';
import 'package:fishbit_finance/modules/auth_tenant/domain/models/user_member.dart';
import 'package:fishbit_finance/modules/auth_tenant/domain/models/company.dart';
import 'package:fishbit_finance/modules/auth_tenant/domain/models/aquaculture_unit.dart';
import 'package:fishbit_finance/modules/auth_tenant/presentation/providers/auth_provider.dart';
import '../../helpers/test_auth_helper.dart';

void main() {
  group('Sede Selection Flow & User Isolation Tests', () {
    const testCompany = Company(
      id: 'emp-001',
      nombreComercial: 'Acuícola del Valle',
      razonSocial: 'Acuícola del Valle S.A.S.',
      nit: '900.123.456-7',
      direccion: 'Neiva, Huila',
      telefono: '3101234567',
    );


    final unit1 = AquacultureUnit(
      id: 'unit-101',
      empresaId: 'emp-001',
      nombre: 'Piscícola Principal',
      sigla: 'PRI',
      creadoEn: DateTime(2026, 1, 1),
    );

    final unit2 = AquacultureUnit(
      id: 'unit-102',
      empresaId: 'emp-001',
      nombre: 'Estación Betania',
      sigla: 'BET',
      creadoEn: DateTime(2026, 1, 1),
    );


    test('Single sede auto-activates without prompting sede selection', () async {
      final user = UserMember(
        id: 'user-single',
        email: 'single@fishbit.com',
        nombre: 'Usuario Un Sede',
        role: UserRole.technician,
        empresaId: 'emp-001',
        creadoEn: DateTime(2026, 1, 1),
      );

      final repo = FakeAuthRepository(
        mockUser: user,
        mockCompanies: [testCompany],
        mockUnits: [unit1],
      );
      final storage = FakeLocalStorageService();
      final notifier = AuthNotifier(repo, storage);

      await Future<void>.delayed(const Duration(milliseconds: 50));

      expect(notifier.state.units.length, 1);
      expect(notifier.state.activeUnitId, 'unit-101');
      expect(notifier.state.needsSedeSelection, isFalse);
      expect(storage.getActiveSedeIdForUser('user-single'), 'unit-101');
    });

    test('Multiple sedes without preference triggers needsSedeSelection', () async {
      final user = UserMember(
        id: 'user-multi',
        email: 'multi@fishbit.com',
        nombre: 'Usuario Multi Sede',
        role: UserRole.admin,
        empresaId: 'emp-001',
        creadoEn: DateTime(2026, 1, 1),
      );

      final repo = FakeAuthRepository(
        mockUser: user,
        mockCompanies: [testCompany],
        mockUnits: [unit1, unit2],
      );
      final storage = FakeLocalStorageService();
      final notifier = AuthNotifier(repo, storage);

      await Future<void>.delayed(const Duration(milliseconds: 50));

      expect(notifier.state.units.length, 2);
      expect(notifier.state.activeUnitId, isNull);
      expect(notifier.state.needsSedeSelection, isTrue);

      // Now user selects unit2
      await notifier.selectActiveUnit('unit-102');

      expect(notifier.state.activeUnitId, 'unit-102');
      expect(notifier.state.needsSedeSelection, isFalse);
      expect(storage.getActiveSedeIdForUser('user-multi'), 'unit-102');
    });

    test('User isolation: Sede preference of User A does not bleed into User B', () async {
      final storage = FakeLocalStorageService();

      // User A selects unit2
      await storage.setActiveSedeIdForUser('user-A', 'unit-102');

      // User B logs in without previous preference
      final userB = UserMember(
        id: 'user-B',
        email: 'userb@fishbit.com',
        nombre: 'Usuario B',
        role: UserRole.admin,
        empresaId: 'emp-001',
        creadoEn: DateTime(2026, 1, 1),
      );

      final repo = FakeAuthRepository(
        mockUser: userB,
        mockCompanies: [testCompany],
        mockUnits: [unit1, unit2],
      );
      final notifierB = AuthNotifier(repo, storage);

      await Future<void>.delayed(const Duration(milliseconds: 50));

      // User B must NOT inherit User A's sede
      expect(notifierB.state.activeUnitId, isNull);
      expect(notifierB.state.needsSedeSelection, isTrue);

      // User A's stored sede remains untouched
      expect(storage.getActiveSedeIdForUser('user-A'), 'unit-102');
    });

    test('Foreign sede from previous company is discarded', () async {
      final storage = FakeLocalStorageService();
      // Saved sede from an old/deleted company
      await storage.setActiveSedeIdForUser('user-migrated', 'unit-old-company');

      final user = UserMember(
        id: 'user-migrated',
        email: 'migrated@fishbit.com',
        nombre: 'Usuario Migrado',
        role: UserRole.admin,
        empresaId: 'emp-001',
        creadoEn: DateTime(2026, 1, 1),
      );

      final repo = FakeAuthRepository(
        mockUser: user,
        mockCompanies: [testCompany],
        mockUnits: [unit1, unit2],
      );
      final notifier = AuthNotifier(repo, storage);

      await Future<void>.delayed(const Duration(milliseconds: 50));

      // Should not adopt 'unit-old-company'
      expect(notifier.state.activeUnitId, isNull);
      expect(notifier.state.needsSedeSelection, isTrue);
    });
  });
}
