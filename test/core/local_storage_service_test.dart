import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:fishbit_finance/core/storage/local_storage_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('LocalStorageService Per-User Sede Tests', () {
    late SharedPreferences prefs;
    late LocalStorageService storageService;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      prefs = await SharedPreferences.getInstance();
      storageService = LocalStorageService(
        prefs,
        const FlutterSecureStorage(),
      );
    });

    test('Saves and reads active sede isolated by userId', () async {
      await storageService.setActiveSedeIdForUser('user-1', 'unit-sede-1');
      await storageService.setActiveSedeIdForUser('user-2', 'unit-sede-2');

      expect(storageService.getActiveSedeIdForUser('user-1'), 'unit-sede-1');
      expect(storageService.getActiveSedeIdForUser('user-2'), 'unit-sede-2');
      expect(storageService.getActiveSedeIdForUser('user-unknown'), isNull);
    });

    test('Null value removes the user sede key', () async {
      await storageService.setActiveSedeIdForUser('user-1', 'unit-sede-1');
      expect(storageService.getActiveSedeIdForUser('user-1'), 'unit-sede-1');

      await storageService.setActiveSedeIdForUser('user-1', null);
      expect(storageService.getActiveSedeIdForUser('user-1'), isNull);
    });
  });
}
