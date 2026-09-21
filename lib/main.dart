import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:fishbit_finance/app/app.dart';
import 'package:fishbit_finance/core/storage/local_storage_service.dart';
import 'package:fishbit_finance/modules/auth_tenant/presentation/providers/auth_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 1. Setup Global Error Boundaries for production error resilience
  FlutterError.onError = (FlutterErrorDetails details) {
    FlutterError.presentError(details);
    debugPrint('Global FlutterError: ${details.exceptionAsString()}');
    if (details.stack != null) {
      debugPrint('Stack: ${details.stack}');
    }
  };

  PlatformDispatcher.instance.onError = (Object error, StackTrace stack) {
    debugPrint('Uncaught Asynchronous Platform Error: $error');
    debugPrint('Stack: $stack');
    return true; // Return true to mark as handled and prevent app crash
  };

  // 2. Inicializar SharedPreferences & LocalStorageService
  final sharedPrefs = await SharedPreferences.getInstance();
  final storageService = LocalStorageService(sharedPrefs);

  // 3. Inicializar Supabase con inyección de variables de entorno (--dart-define)
  const supabaseUrl = String.fromEnvironment('SUPABASE_URL');
  const supabaseAnonKey = String.fromEnvironment('SUPABASE_ANON_KEY');

  // Validación en modo debug para feedback inmediato al desarrollador
  assert(
    supabaseUrl.isNotEmpty && supabaseAnonKey.isNotEmpty,
    'FishBit Security Error: SUPABASE_URL and SUPABASE_ANON_KEY must be provided via --dart-define',
  );

  // Validación estricta en tiempo de ejecución para compilaciones de release y producción
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

  await Supabase.initialize(
    url: supabaseUrl,
    // ignore: deprecated_member_use
    anonKey: supabaseAnonKey,
  );

  runApp(
    ProviderScope(
      overrides: [
        localStorageServiceProvider.overrideWithValue(storageService),
      ],
      child: const FishBitApp(),
    ),
  );
}
