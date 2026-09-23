import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fishbit_finance/core/design_system/app_colors.dart';
import 'package:fishbit_finance/core/design_system/app_typography.dart';
import 'package:fishbit_finance/core/design_system/theme_provider.dart';
import 'package:fishbit_finance/core/design_system/theme_animated_glass_toggle.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('ThemeModeNotifier & Theme Storage Tests', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    test('1. Default theme mode is ThemeMode.system', () async {
      final notifier = ThemeModeNotifier();
      // Allow async _loadTheme to finish
      await Future<void>.delayed(const Duration(milliseconds: 10));

      expect(notifier.state, equals(ThemeMode.system));
      expect(notifier.isSystemMode, isTrue);
    });

    test('2. Restores saved theme mode from SharedPreferences string', () async {
      SharedPreferences.setMockInitialValues({
        'fishbit_app_theme_mode': 'light',
      });

      final notifier = ThemeModeNotifier();
      await Future<void>.delayed(const Duration(milliseconds: 10));

      expect(notifier.state, equals(ThemeMode.light));
      expect(notifier.isSystemMode, isFalse);
    });

    test('3. Restores saved dark theme mode from SharedPreferences string', () async {
      SharedPreferences.setMockInitialValues({
        'fishbit_app_theme_mode': 'dark',
      });

      final notifier = ThemeModeNotifier();
      await Future<void>.delayed(const Duration(milliseconds: 10));

      expect(notifier.state, equals(ThemeMode.dark));
      expect(notifier.isSystemMode, isFalse);
    });

    test('4. Handles legacy boolean preferences gracefully', () async {
      SharedPreferences.setMockInitialValues({
        'fishbit_app_theme_mode': true, // Legacy isLight = true
      });

      final notifier = ThemeModeNotifier();
      await Future<void>.delayed(const Duration(milliseconds: 10));

      expect(notifier.state, equals(ThemeMode.light));
    });

    test('5. setTheme updates state and persists string', () async {
      final notifier = ThemeModeNotifier();
      await notifier.setTheme(ThemeMode.dark);

      expect(notifier.state, equals(ThemeMode.dark));

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('fishbit_app_theme_mode'), equals('dark'));

      await notifier.setTheme(ThemeMode.system);
      expect(notifier.state, equals(ThemeMode.system));
      expect(prefs.getString('fishbit_app_theme_mode'), equals('system'));
    });

    test('6. toggleTheme switches between light and dark', () async {
      final notifier = ThemeModeNotifier();
      await notifier.setTheme(ThemeMode.dark);

      await notifier.toggleTheme();
      expect(notifier.state, equals(ThemeMode.light));

      await notifier.toggleTheme();
      expect(notifier.state, equals(ThemeMode.dark));
    });
  });

  group('Color Mode & Theme Architectural Guidelines', () {
    test('Surface elevation hierarchy uses progressive lightness (no pitch black background)', () {
      // In dark mode: backgroundDark < surfaceDark < surfaceDarkRaised
      expect(AppColors.backgroundDark.computeLuminance(), lessThan(AppColors.surfaceDark.computeLuminance()));
      expect(AppColors.surfaceDark.computeLuminance(), lessThan(AppColors.surfaceDarkRaised.computeLuminance()));

      // None of the dark surfaces should be pure black (0x000000)
      expect(AppColors.backgroundDark, isNot(equals(Colors.black)));
      expect(AppColors.surfaceDark, isNot(equals(Colors.black)));
    });

    test('Optical weight compensation: dark mode body text is calibrated (w500 vs w400)', () {
      expect(AppTypography.dark.bodyMedium.fontWeight, equals(FontWeight.w500));
      expect(AppTypography.dark.bodySmall.fontWeight, equals(FontWeight.w500));

      expect(AppTypography.light.bodyMedium.fontWeight, equals(FontWeight.w400));
      expect(AppTypography.light.bodySmall.fontWeight, equals(FontWeight.w400));
    });

    testWidgets('ThemeSegmentedGlassSelector renders all 3 modes and allows selection', (tester) async {
      SharedPreferences.setMockInitialValues({});

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            theme: appLightTheme,
            darkTheme: appDarkTheme,
            home: const Scaffold(
              body: Center(
                child: ThemeSegmentedGlassSelector(),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Auto'), findsOneWidget);
      expect(find.text('Claro'), findsOneWidget);
      expect(find.text('Oscuro'), findsOneWidget);

      // Tap on Claro
      await tester.tap(find.text('Claro'));
      await tester.pumpAndSettle();

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('fishbit_app_theme_mode'), equals('light'));

      // Tap on Oscuro
      await tester.tap(find.text('Oscuro'));
      await tester.pumpAndSettle();

      expect(prefs.getString('fishbit_app_theme_mode'), equals('dark'));
    });
  });
}
