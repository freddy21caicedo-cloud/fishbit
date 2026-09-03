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
  const supabaseUrl = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: 'https://oakovawlwjpnoydpwtam.supabase.co',
  );
  const supabaseAnonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
    defaultValue:
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im9ha292YXdsd2pwbm95ZHB3dGFtIiwicm9sZSI6ImFub24iLCJpYXQiOjE3Nzc5MDQ3NTksImV4cCI6MjA5MzQ4MDc1OX0.Hd-yeZaNvZtjd7inkhwcF3IVWWKRC8Sd9nGHeItmFVw',
  );

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
