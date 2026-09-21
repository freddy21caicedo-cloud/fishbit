import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fishbit_finance/core/design_system/app_colors.dart';
import 'package:fishbit_finance/core/design_system/app_typography.dart';
import 'package:fishbit_finance/core/design_system/theme_provider.dart';

/// Calculates WCAG 2.2 Relative Luminance according to W3C specification:
/// L = 0.2126 * R + 0.7152 * G + 0.0722 * B
double relativeLuminance(Color color) {
  double linearize(double channel) {
    return channel <= 0.04045
        ? channel / 12.92
        : math.pow((channel + 0.055) / 1.055, 2.4).toDouble();
  }

  final r = linearize(color.r);
  final g = linearize(color.g);
  final b = linearize(color.b);
  return 0.2126 * r + 0.7152 * g + 0.0722 * b;
}

/// Calculates standard WCAG contrast ratio between two colors:
/// (L1 + 0.05) / (L2 + 0.05) where L1 is the lighter color.
double contrastRatio(Color c1, Color c2) {
  final l1 = relativeLuminance(c1);
  final l2 = relativeLuminance(c2);
  final lighter = l1 > l2 ? l1 : l2;
  final darker = l1 > l2 ? l2 : l1;
  return (lighter + 0.05) / (darker + 0.05);
}

void main() {
  group('A11Y-01: WCAG 2.2 AA Contrast Compliance & Reactive Theme Tests', () {
    test('1. Light theme text tokens must exceed 4.5:1 against light surfaces', () {
      final primaryVsSurface = contrastRatio(AppColors.textPrimaryLight, AppColors.surfaceLight);
      final primaryVsBg = contrastRatio(AppColors.textPrimaryLight, AppColors.backgroundLight);
      final secondaryVsSurface = contrastRatio(AppColors.textSecondaryLight, AppColors.surfaceLight);
      final secondaryVsBg = contrastRatio(AppColors.textSecondaryLight, AppColors.backgroundLight);

      expect(primaryVsSurface, greaterThanOrEqualTo(4.5), reason: 'Primary text on surfaceLight must pass WCAG AA');
      expect(primaryVsBg, greaterThanOrEqualTo(4.5), reason: 'Primary text on backgroundLight must pass WCAG AA');
      expect(secondaryVsSurface, greaterThanOrEqualTo(4.5), reason: 'Secondary text on surfaceLight must pass WCAG AA');
      expect(secondaryVsBg, greaterThanOrEqualTo(4.5), reason: 'Secondary text on backgroundLight must pass WCAG AA');
    });

    test('2. Dark theme text tokens must exceed 4.5:1 against dark surfaces', () {
      final primaryVsSurface = contrastRatio(AppColors.textPrimaryDark, AppColors.surfaceDark);
      final primaryVsBg = contrastRatio(AppColors.textPrimaryDark, AppColors.backgroundDark);
      final secondaryVsSurface = contrastRatio(AppColors.textSecondaryDark, AppColors.surfaceDark);
      final secondaryVsBg = contrastRatio(AppColors.textSecondaryDark, AppColors.backgroundDark);

      expect(primaryVsSurface, greaterThanOrEqualTo(4.5), reason: 'Primary text on surfaceDark must pass WCAG AA');
      expect(primaryVsBg, greaterThanOrEqualTo(4.5), reason: 'Primary text on backgroundDark must pass WCAG AA');
      expect(secondaryVsSurface, greaterThanOrEqualTo(4.5), reason: 'Secondary text on surfaceDark must pass WCAG AA');
      expect(secondaryVsBg, greaterThanOrEqualTo(4.5), reason: 'Secondary text on backgroundDark must pass WCAG AA');
    });

    test('3. Outdoor high-contrast accent light text tokens must exceed 4.5:1 against white surface', () {
      expect(contrastRatio(AppColors.cyanWaterTextLight, Colors.white), greaterThanOrEqualTo(4.5));
      expect(contrastRatio(AppColors.greenBiomassTextLight, Colors.white), greaterThanOrEqualTo(4.5));
      expect(contrastRatio(AppColors.amberWarningTextLight, Colors.white), greaterThanOrEqualTo(4.5));
      expect(contrastRatio(AppColors.coralActionTextLight, Colors.white), greaterThanOrEqualTo(4.5));
      expect(contrastRatio(AppColors.purpleAnalyticsTextLight, Colors.white), greaterThanOrEqualTo(4.5));
    });

    test('4. AppTypography base static constants have color: null for dynamic theme inheritance', () {
      expect(AppTypography.displayLarge.color, isNull);
      expect(AppTypography.displayMedium.color, isNull);
      expect(AppTypography.titleLarge.color, isNull);
      expect(AppTypography.titleMedium.color, isNull);
      expect(AppTypography.titleSmall.color, isNull);
      expect(AppTypography.bodyMedium.color, isNull);
      expect(AppTypography.bodySmall.color, isNull);
      expect(AppTypography.labelMicro.color, isNull);
      expect(AppTypography.numberKpi.color, isNull);
    });

    test('5. AppTypography.dark and AppTypography.light have explicit calibrated colors', () {
      expect(AppTypography.dark.titleMedium.color, equals(AppColors.textPrimaryDark));
      expect(AppTypography.dark.bodyMedium.color, equals(AppColors.textSecondaryDark));
      expect(AppTypography.light.titleMedium.color, equals(AppColors.textPrimaryLight));
      expect(AppTypography.light.bodyMedium.color, equals(AppColors.textSecondaryLight));
    });

    testWidgets('6. AppTypography inherits DefaultTextStyle reactively in Light and Dark modes', (tester) async {
      // Test in Light Theme
      await tester.pumpWidget(
        MaterialApp(
          theme: appLightTheme,
          home: const Scaffold(
            body: Text('Legible Light Text', style: AppTypography.titleMedium),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final lightText = tester.widget<Text>(find.text('Legible Light Text'));
      expect(lightText.style?.color, isNull, reason: 'Static constant does not hardcode color');

      final lightDefault = tester.widget<DefaultTextStyle>(
        find.ancestor(of: find.text('Legible Light Text'), matching: find.byType(DefaultTextStyle)).first,
      );
      expect(lightDefault.style.color, equals(AppColors.textPrimaryLight),
          reason: 'Inherited default style in Light theme must be textPrimaryLight (high contrast)');

      // Test in Dark Theme
      await tester.pumpWidget(
        MaterialApp(
          theme: appDarkTheme,
          home: const Scaffold(
            body: Text('Legible Dark Text', style: AppTypography.titleMedium),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final darkDefault = tester.widget<DefaultTextStyle>(
        find.ancestor(of: find.text('Legible Dark Text'), matching: find.byType(DefaultTextStyle)).first,
      );
      expect(darkDefault.style.color, equals(AppColors.textPrimaryDark),
          reason: 'Inherited default style in Dark theme must be textPrimaryDark (white)');
    });

    testWidgets('7. AppColors.accentText resolves high-contrast variants in Light theme', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: appLightTheme,
          home: Builder(
            builder: (context) {
              final resolvedCyan = AppColors.accentText(context, AppColors.cyanWater);
              final resolvedGreen = AppColors.accentText(context, AppColors.greenBiomass);
              final resolvedAmber = AppColors.accentText(context, AppColors.amberWarning);

              expect(resolvedCyan, equals(AppColors.cyanWaterTextLight));
              expect(resolvedGreen, equals(AppColors.greenBiomassTextLight));
              expect(resolvedAmber, equals(AppColors.amberWarningTextLight));

              return const SizedBox();
            },
          ),
        ),
      );
      await tester.pumpAndSettle();
    });
  });
}
