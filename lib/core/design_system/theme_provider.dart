import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:fishbit_finance/core/design_system/app_colors.dart';

class ThemeModeNotifier extends StateNotifier<ThemeMode> {
  static const _themePrefKey = 'fishbit_app_theme_mode';

  ThemeModeNotifier() : super(ThemeMode.dark) {
    _loadTheme();
  }

  Future<void> _loadTheme() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final isLight = prefs.getBool(_themePrefKey) ?? false;
      state = isLight ? ThemeMode.light : ThemeMode.dark;
    } catch (_) {}
  }

  Future<void> toggleTheme() async {
    final newMode = state == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark;
    state = newMode;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_themePrefKey, newMode == ThemeMode.light);
    } catch (_) {}
  }

  Future<void> setTheme(ThemeMode mode) async {
    state = mode;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_themePrefKey, mode == ThemeMode.light);
    } catch (_) {}
  }
}

final themeModeProvider = StateNotifierProvider<ThemeModeNotifier, ThemeMode>((ref) {
  return ThemeModeNotifier();
});

/// Tema Oscuro Oficial FishBit (OLED Glassmorphism)
final appDarkTheme = ThemeData.dark().copyWith(
  scaffoldBackgroundColor: AppColors.backgroundDark,
  colorScheme: const ColorScheme.dark(
    primary: AppColors.cyanWater,
    secondary: AppColors.coralAction,
    surface: AppColors.surfaceDark,
  ),
  appBarTheme: const AppBarTheme(
    backgroundColor: AppColors.backgroundDark,
    elevation: 0,
  ),
);

/// Tema Claro Oficial FishBit (Apple Frosted Glass & Luxury Light)
final appLightTheme = ThemeData.light().copyWith(
  scaffoldBackgroundColor: AppColors.backgroundLight,
  canvasColor: AppColors.backgroundLight,
  cardColor: AppColors.surfaceLight,
  colorScheme: const ColorScheme.light(
    primary: AppColors.cyanWater,
    secondary: AppColors.coralAction,
    surface: AppColors.surfaceLight,
    onSurface: AppColors.textPrimaryLight,
    onPrimary: Colors.white,
  ),
  appBarTheme: const AppBarTheme(
    backgroundColor: AppColors.backgroundLight,
    elevation: 0,
    iconTheme: IconThemeData(color: AppColors.textPrimaryLight),
  ),
  dividerColor: AppColors.glassBorderLight,
);
