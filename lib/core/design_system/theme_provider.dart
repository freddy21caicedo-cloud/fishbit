import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:fishbit_finance/core/design_system/app_colors.dart';
import 'package:fishbit_finance/core/design_system/app_typography.dart';

/// Notificador de Modo de Tema para FishBit (Soporte Sistema, Claro y Oscuro)
/// Conforme a la directriz 'color-mode-and-theme': combinado (prefers-color-scheme + override manual).
class ThemeModeNotifier extends StateNotifier<ThemeMode> {
  static const _themePrefKey = 'fishbit_app_theme_mode';

  ThemeModeNotifier() : super(ThemeMode.system) {
    _loadTheme();
  }

  Future<void> _loadTheme() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final rawVal = prefs.get(_themePrefKey);
      if (rawVal is String) {
        switch (rawVal) {
          case 'light':
            state = ThemeMode.light;
            return;
          case 'dark':
            state = ThemeMode.dark;
            return;
          case 'system':
          default:
            state = ThemeMode.system;
            return;
        }
      } else if (rawVal is bool) {
        // Compatibilidad con registros legacy guardados como boolean
        state = rawVal ? ThemeMode.light : ThemeMode.dark;
        return;
      }
      state = ThemeMode.system;
    } catch (_) {
      state = ThemeMode.system;
    }
  }

  /// Alterna manualmente entre modo oscuro y claro
  Future<void> toggleTheme([BuildContext? context]) async {
    final bool currentIsDark;
    if (state == ThemeMode.system && context != null) {
      currentIsDark = MediaQuery.platformBrightnessOf(context) == Brightness.dark;
    } else {
      currentIsDark = state == ThemeMode.dark;
    }

    final newMode = currentIsDark ? ThemeMode.light : ThemeMode.dark;
    await setTheme(newMode);
  }

  /// Establece un modo específico ('system', 'light', o 'dark')
  Future<void> setTheme(ThemeMode mode) async {
    state = mode;
    try {
      final prefs = await SharedPreferences.getInstance();
      final modeStr = switch (mode) {
        ThemeMode.light => 'light',
        ThemeMode.dark => 'dark',
        ThemeMode.system => 'system',
      };
      await prefs.setString(_themePrefKey, modeStr);
    } catch (_) {}
  }

  bool get isSystemMode => state == ThemeMode.system;
}

final themeModeProvider = StateNotifierProvider<ThemeModeNotifier, ThemeMode>((ref) {
  return ThemeModeNotifier();
});

/// Tema Oscuro Oficial FishBit (OLED Luxury & High-Contrast Glassmorphism)
final appDarkTheme = ThemeData.dark().copyWith(
  scaffoldBackgroundColor: AppColors.backgroundDark,
  canvasColor: AppColors.surfaceDark,
  cardColor: AppColors.surfaceDark,
  colorScheme: const ColorScheme.dark(
    primary: AppColors.cyanWater,
    secondary: AppColors.coralAction,
    surface: AppColors.surfaceDark,
    surfaceContainerHighest: AppColors.surfaceDarkRaised,
    onSurface: AppColors.textPrimaryDark,
    onSurfaceVariant: AppColors.textSecondaryDark,
    outline: AppColors.glassBorderDark,
  ),
  appBarTheme: const AppBarTheme(
    backgroundColor: AppColors.backgroundDark,
    elevation: 0,
    iconTheme: IconThemeData(color: AppColors.textPrimaryDark),
    titleTextStyle: TextStyle(
      color: AppColors.textPrimaryDark,
      fontSize: 17,
      fontWeight: FontWeight.w600,
    ),
  ),
  cardTheme: CardThemeData(
    color: AppColors.surfaceDark,
    elevation: 0,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(20),
      side: const BorderSide(color: AppColors.glassBorderDark),
    ),
  ),
  dialogTheme: DialogThemeData(
    backgroundColor: AppColors.surfaceDarkRaised,
    surfaceTintColor: Colors.transparent,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
  ),
  bottomSheetTheme: const BottomSheetThemeData(
    backgroundColor: Colors.transparent,
    surfaceTintColor: Colors.transparent,
    elevation: 0,
  ),
  dividerTheme: DividerThemeData(
    color: Colors.white.withValues(alpha: 0.08),
    thickness: 1,
    space: 1,
  ),
  iconTheme: const IconThemeData(color: AppColors.textPrimaryDark),
  tabBarTheme: const TabBarThemeData(
    labelColor: AppColors.cyanWater,
    unselectedLabelColor: AppColors.textSecondaryDark,
  ),
  popupMenuTheme: const PopupMenuThemeData(
    color: AppColors.surfaceDarkRaised,
    textStyle: TextStyle(color: AppColors.textPrimaryDark),
  ),
  textTheme: AppTypography.createTextTheme(Brightness.dark),
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
    surfaceContainerHighest: AppColors.surfaceLightRaised,
    onSurface: AppColors.textPrimaryLight,
    onSurfaceVariant: AppColors.textSecondaryLight,
    outline: AppColors.glassBorderLight,
    onPrimary: Colors.white,
  ),
  appBarTheme: const AppBarTheme(
    backgroundColor: AppColors.backgroundLight,
    elevation: 0,
    iconTheme: IconThemeData(color: AppColors.textPrimaryLight),
    titleTextStyle: TextStyle(
      color: AppColors.textPrimaryLight,
      fontSize: 17,
      fontWeight: FontWeight.w600,
    ),
  ),
  cardTheme: CardThemeData(
    color: AppColors.surfaceLight,
    elevation: 0,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(20),
      side: const BorderSide(color: AppColors.glassBorderLight),
    ),
  ),
  dialogTheme: DialogThemeData(
    backgroundColor: AppColors.surfaceLight,
    surfaceTintColor: Colors.transparent,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
  ),
  bottomSheetTheme: const BottomSheetThemeData(
    backgroundColor: Colors.transparent,
    surfaceTintColor: Colors.transparent,
    elevation: 0,
  ),
  dividerTheme: const DividerThemeData(
    color: AppColors.glassBorderLight,
    thickness: 1,
    space: 1,
  ),
  dividerColor: AppColors.glassBorderLight,
  iconTheme: const IconThemeData(color: AppColors.textPrimaryLight),
  tabBarTheme: const TabBarThemeData(
    labelColor: AppColors.cyanWater,
    unselectedLabelColor: AppColors.textSecondaryLight,
  ),
  popupMenuTheme: const PopupMenuThemeData(
    color: AppColors.surfaceLight,
    textStyle: TextStyle(color: AppColors.textPrimaryLight),
  ),
  textTheme: AppTypography.createTextTheme(Brightness.light),
);
