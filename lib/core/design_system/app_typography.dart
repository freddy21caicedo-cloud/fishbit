import 'package:flutter/material.dart';
import 'app_colors.dart';

/// Escala tipográfica compacta y de alta legibilidad
class AppTypography {
  AppTypography._();

  static const TextStyle displayLarge = TextStyle(
    fontSize: 26,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.5,
    color: AppColors.textPrimaryDark,
  );

  static const TextStyle displayMedium = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.w600,
    letterSpacing: -0.3,
    color: AppColors.textPrimaryDark,
  );

  static const TextStyle titleLarge = TextStyle(
    fontSize: 17,
    fontWeight: FontWeight.w600,
    letterSpacing: -0.2,
    color: AppColors.textPrimaryDark,
  );

  static const TextStyle titleMedium = TextStyle(
    fontSize: 15,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimaryDark,
  );

  static const TextStyle titleSmall = TextStyle(
    fontSize: 13,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimaryDark,
  );

  static const TextStyle bodyMedium = TextStyle(
    fontSize: 13,
    fontWeight: FontWeight.w400,
    color: AppColors.textSecondaryDark,
    height: 1.4,
  );

  static const TextStyle bodySmall = TextStyle(
    fontSize: 11,
    fontWeight: FontWeight.w400,
    color: AppColors.textSecondaryDark,
  );

  static const TextStyle labelMicro = TextStyle(
    fontSize: 10,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.5,
    color: AppColors.textSecondaryDark,
  );

  static const TextStyle numberKpi = TextStyle(
    fontSize: 22,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.5,
    color: AppColors.textPrimaryDark,
    fontFeatures: [FontFeature.tabularFigures()],
  );

  // ─── Helpers Adaptativos por Contexto de Tema (Dark / Light) ─────────────
  static TextStyle titleOf(BuildContext context, {double fontSize = 15, FontWeight fontWeight = FontWeight.w700}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return TextStyle(
      fontSize: fontSize,
      fontWeight: fontWeight,
      color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
    );
  }

  static TextStyle bodyOf(BuildContext context, {double fontSize = 12, FontWeight fontWeight = FontWeight.w500}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return TextStyle(
      fontSize: fontSize,
      fontWeight: fontWeight,
      color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
    );
  }
}

