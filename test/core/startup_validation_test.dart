import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:fishbit_finance/main.dart' as app_main;

/// Replicate the exact validation logic in lib/main.dart lines 33-58
/// for empirical matrix testing across invalid inputs.
void validateStartupEnvironment(String supabaseUrl, String supabaseAnonKey) {
  // Debug assertion
  assert(
    supabaseUrl.isNotEmpty && supabaseAnonKey.isNotEmpty,
    'FishBit Security Error: SUPABASE_URL and SUPABASE_ANON_KEY must be provided via --dart-define',
  );

  // Runtime release validation
  if (supabaseUrl.isEmpty || supabaseAnonKey.isEmpty) {
    throw StateError(
      'FishBit Configuration Error: Required environment variables SUPABASE_URL and SUPABASE_ANON_KEY '
      'are missing. Pass them via --dart-define or --dart-define-from-file at compile time.',
    );
  }

  final parsedUri = Uri.tryParse(supabaseUrl);
  if (parsedUri == null ||
      !parsedUri.hasScheme ||
      (parsedUri.scheme != 'https' && parsedUri.scheme != 'http')) {
    throw StateError(
      'FishBit Configuration Error: SUPABASE_URL is not a valid HTTP/HTTPS URI: $supabaseUrl',
    );
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Startup Validation Logic - Direct lib/main.dart Execution', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    test('Invoking app_main.main() without --dart-define traps missing variables', () async {
      // In a default test runner without dart-define, SUPABASE_URL and SUPABASE_ANON_KEY
      // evaluate to empty strings.
      // Because main() is `void main() async`, uncaught errors after the first await
      // are dispatched through the asynchronous zone error handler.
      final completer = Completer<Object>();

      runZonedGuarded(() {
        app_main.main();
      }, (error, stack) {
        if (!completer.isCompleted) {
          completer.complete(error);
        }
      });

      final trappedError = await completer.future.timeout(
        const Duration(seconds: 5),
        onTimeout: () => throw TimeoutException('main() did not throw an error as expected'),
      );

      expect(trappedError, anyOf(
        isA<AssertionError>().having(
          (e) => e.message?.toString(),
          'message',
          contains('FishBit Security Error'),
        ),
        isA<StateError>().having(
          (e) => e.message,
          'message',
          contains('FishBit Configuration Error'),
        ),
      ));
    });
  });

  group('Startup Validation - Adversarial Input Matrix', () {
    test('Throws error when SUPABASE_URL is empty', () {
      expect(
        () => validateStartupEnvironment('', 'valid_anon_key_string'),
        throwsA(anyOf(isA<AssertionError>(), isA<StateError>())),
      );
    });

    test('Throws error when SUPABASE_ANON_KEY is empty', () {
      expect(
        () => validateStartupEnvironment('https://example.supabase.co', ''),
        throwsA(anyOf(isA<AssertionError>(), isA<StateError>())),
      );
    });

    test('Throws StateError when SUPABASE_URL has invalid scheme (ftp)', () {
      expect(
        () => validateStartupEnvironment('ftp://malicious.host.com', 'valid_key'),
        throwsA(isA<StateError>().having(
          (e) => e.message,
          'message',
          contains('not a valid HTTP/HTTPS URI'),
        )),
      );
    });

    test('Throws StateError when SUPABASE_URL has no scheme', () {
      expect(
        () => validateStartupEnvironment('my-project.supabase.co', 'valid_key'),
        throwsA(isA<StateError>().having(
          (e) => e.message,
          'message',
          contains('not a valid HTTP/HTTPS URI'),
        )),
      );
    });

    test('Throws StateError when SUPABASE_URL is file URI', () {
      expect(
        () => validateStartupEnvironment('file:///etc/passwd', 'valid_key'),
        throwsA(isA<StateError>().having(
          (e) => e.message,
          'message',
          contains('not a valid HTTP/HTTPS URI'),
        )),
      );
    });

    test('Throws StateError when SUPABASE_URL is javascript or data scheme', () {
      expect(
        () => validateStartupEnvironment('javascript:alert(1)', 'valid_key'),
        throwsA(isA<StateError>().having(
          (e) => e.message,
          'message',
          contains('not a valid HTTP/HTTPS URI'),
        )),
      );
    });

    test('Passes validation when valid https URL and non-empty key are supplied', () {
      expect(
        () => validateStartupEnvironment(
          'https://validproject.supabase.co',
          'valid_jwt_or_anon_key_token',
        ),
        returnsNormally,
      );
    });

    test('Passes validation when valid http URL (local dev) and non-empty key are supplied', () {
      expect(
        () => validateStartupEnvironment(
          'http://127.0.0.1:54321',
          'local_dev_anon_key_token',
        ),
        returnsNormally,
      );
    });
  });
}
