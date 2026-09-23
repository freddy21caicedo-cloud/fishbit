import 'package:flutter/material.dart';

/// Paleta de colores para FishBit Finance 2.0
/// Combinación de Dark OLED Luxury, Glassmorphism y Acentos Acuícolas
class AppColors {
  AppColors._();

  // ─── Fondos y Superficies ───────────────────────────────────────────────────
  static const Color backgroundDark = Color(0xFF070A0F);
  static const Color backgroundLight = Color(0xFFF6F8FA);
  
  static const Color surfaceDark = Color(0xFF101622);
  static const Color surfaceDarkRaised = Color(0xFF161F2E); // +2 elevación (modales, popovers)
  static const Color surfaceLight = Color(0xFFFFFFFF);
  static const Color surfaceLightRaised = Color(0xFFF1F5F9); // +2 elevación light

  // ─── Capas Glassmorphism (Translúcidas) ──────────────────────────────────────
  static const Color glassFillDark = Color(0x0FFFFFFF); // ~6% blanco
  static const Color glassFillLight = Color(0xF2FFFFFF); // ~95% blanco esmerilado puro
  
  static const Color glassBorderDark = Color(0x1FFFFFFF); // ~12% blanco
  static const Color glassBorderLight = Color(0xFFE2E8F0); // Borde cristalino nítido
  
  static const Color glassBorderHighlight = Color(0x40FFFFFF); // ~25% resplandor

  // ─── Acentos de Marca (Acuicultura de Precisión) ────────────────────────────
  static const Color cyanWater = Color(0xFF00B2CC);      // Tecnología, agua, dashboard
  static const Color coralAction = Color(0xFFFF2D55);    // Acciones principales, alertas
  static const Color greenBiomass = Color(0xFF10B981);   // Biomasa sana, rentabilidad, OK
  static const Color amberWarning = Color(0xFFFF9500);   // Alerta de oxígeno, stock bajo
  static const Color purpleAnalytics = Color(0xFF8B5CF6);// Métricas analíticas, FCR
  static const Color blueOcean = Color(0xFF1D4ED8);      // Sedes e infraestructura

  // ─── Texto y Tipografía ─────────────────────────────────────────────────────
  static const Color textPrimaryDark = Color(0xFFFFFFFF);
  static const Color textSecondaryDark = Color(0xFF8E9BAE);
  static const Color textTertiaryDark = Color(0xFF4B5563);

  static const Color textPrimaryLight = Color(0xFF0F172A);  // Midnight Slate (Alto contraste)
  static const Color textSecondaryLight = Color(0xFF475569);// Neutral Slate
  static const Color textTertiaryLight = Color(0xFF64748B); // Muted Slate

  // ─── Estados de Calidad de Agua ─────────────────────────────────────────────
  static const Color waterOptimal = Color(0xFF10B981);
  static const Color waterCaution = Color(0xFFFBBF24);
  static const Color waterCritical = Color(0xFFEF4444);

  // ─── Variantes Adaptativas para Texto de Alto Contraste (WCAG 2.2 AA >= 4.5:1) ──
  static const Color cyanWaterTextLight = Color(0xFF007A8C);     // 5.1:1 en blanco
  static const Color greenBiomassTextLight = Color(0xFF047857);   // 5.2:1 en blanco
  static const Color amberWarningTextLight = Color(0xFFB45309);   // 4.6:1 en blanco
  static const Color coralActionTextLight = Color(0xFFBE123C);    // 5.4:1 en blanco
  static const Color purpleAnalyticsTextLight = Color(0xFF6D28D9); // 6.5:1 en blanco

  /// Selector reactivo de color de acento para texto según brillo del tema
  static Color accentText(BuildContext context, Color darkColor) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    if (isDark) return darkColor;
    if (darkColor == cyanWater) return cyanWaterTextLight;
    if (darkColor == greenBiomass || darkColor == waterOptimal) return greenBiomassTextLight;
    if (darkColor == amberWarning || darkColor == waterCaution) return amberWarningTextLight;
    if (darkColor == coralAction || darkColor == waterCritical) return coralActionTextLight;
    if (darkColor == purpleAnalytics) return purpleAnalyticsTextLight;
    return darkColor;
  }

  // ─── Selectores Semánticos Reactivos por Contexto ───────────────────────────
  static Color surface(BuildContext context, {bool raised = false}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    if (isDark) return raised ? surfaceDarkRaised : surfaceDark;
    return raised ? surfaceLightRaised : surfaceLight;
  }

  static Color background(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark ? backgroundDark : backgroundLight;
  }

  static Color textPrimary(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark ? textPrimaryDark : textPrimaryLight;
  }

  static Color textSecondary(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark ? textSecondaryDark : textSecondaryLight;
  }

  static Color textTertiary(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark ? textTertiaryDark : textTertiaryLight;
  }

  static Color glassFill(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark ? glassFillDark : glassFillLight;
  }

  static Color glassBorder(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark ? glassBorderDark : glassBorderLight;
  }

  static Color divider(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? Colors.white.withValues(alpha: 0.08)
        : glassBorderLight;
  }
}

/// Extensión ergonómica sobre [BuildContext] para acceso ágil y seguro al sistema de temas
extension ThemeContextExtension on BuildContext {
  bool get isDark => Theme.of(this).brightness == Brightness.dark;
  Color get textPrimary => isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight;
  Color get textSecondary => isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight;
  Color get textTertiary => isDark ? AppColors.textTertiaryDark : AppColors.textTertiaryLight;
  Color get surfaceColor => isDark ? AppColors.surfaceDark : AppColors.surfaceLight;
  Color get surfaceRaisedColor => isDark ? AppColors.surfaceDarkRaised : AppColors.surfaceLightRaised;
  Color get backgroundColor => isDark ? AppColors.backgroundDark : AppColors.backgroundLight;
  Color get glassBorderColor => isDark ? AppColors.glassBorderDark : AppColors.glassBorderLight;
  Color get glassFillColor => isDark ? AppColors.glassFillDark : AppColors.glassFillLight;
  Color get dividerColor => isDark ? Colors.white.withValues(alpha: 0.08) : AppColors.glassBorderLight;
}
