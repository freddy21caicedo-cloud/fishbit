import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fishbit_finance/core/design_system/app_colors.dart';
import 'package:fishbit_finance/core/design_system/theme_provider.dart';

/// Selector Segmentado Glassmorphic de 3 Modos (Sistema / Claro / Oscuro)
/// Diseñado para popovers, hojas de perfil y pantallas de configuración.
class ThemeSegmentedGlassSelector extends ConsumerWidget {
  const ThemeSegmentedGlassSelector({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final options = [
      (mode: ThemeMode.system, label: 'Auto', icon: Icons.brightness_auto_rounded),
      (mode: ThemeMode.light, label: 'Claro', icon: Icons.wb_sunny_rounded),
      (mode: ThemeMode.dark, label: 'Oscuro', icon: Icons.nightlight_round),
    ];

    return Container(
      height: 40,
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withValues(alpha: 0.06) : Colors.black.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark ? Colors.white.withValues(alpha: 0.12) : AppColors.glassBorderLight,
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: options.map((opt) {
          final isSelected = themeMode == opt.mode;

          return Expanded(
            child: GestureDetector(
              onTap: () {
                HapticFeedback.selectionClick();
                ref.read(themeModeProvider.notifier).setTheme(opt.mode);
              },
              behavior: HitTestBehavior.opaque,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 240),
                curve: Curves.easeInOutCubic,
                alignment: Alignment.center,
                padding: const EdgeInsets.symmetric(horizontal: 8),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  color: isSelected
                      ? (isDark ? AppColors.cyanWater.withValues(alpha: 0.25) : Colors.white)
                      : Colors.transparent,
                  border: isSelected
                      ? Border.all(
                          color: isDark ? AppColors.cyanWater.withValues(alpha: 0.6) : AppColors.cyanWaterTextLight.withValues(alpha: 0.4),
                          width: 1,
                        )
                      : null,
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: isDark
                                ? AppColors.cyanWater.withValues(alpha: 0.20)
                                : Colors.black.withValues(alpha: 0.08),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ]
                      : null,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      opt.icon,
                      size: 14,
                      color: isSelected
                          ? (isDark ? AppColors.cyanWater : AppColors.cyanWaterTextLight)
                          : (isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      opt.label,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                        color: isSelected
                            ? (isDark ? Colors.white : AppColors.textPrimaryLight)
                            : (isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

/// Botón Toggle Animado con Efecto Glassmorphism y Micro-interacciones (2 Modos Directos)
class ThemeAnimatedGlassToggle extends ConsumerWidget {
  const ThemeAnimatedGlassToggle({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);
    final effectiveIsDark = Theme.of(context).brightness == Brightness.dark;
    final isDark = themeMode == ThemeMode.dark || (themeMode == ThemeMode.system && effectiveIsDark);

    return InkWell(
      onTap: () {
        HapticFeedback.mediumImpact();
        ref.read(themeModeProvider.notifier).toggleTheme(context);
      },
      borderRadius: BorderRadius.circular(30),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeInOutCubic,
        width: 136,
        height: 38,
        padding: const EdgeInsets.all(3),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(30),
          color: effectiveIsDark
              ? Colors.white.withValues(alpha: 0.08)
              : Colors.black.withValues(alpha: 0.05),
          border: Border.all(
            color: isDark
                ? AppColors.cyanWater.withValues(alpha: 0.35)
                : AppColors.amberWarning.withValues(alpha: 0.45),
            width: 1.2,
          ),
          boxShadow: [
            BoxShadow(
              color: isDark
                  ? AppColors.cyanWater.withValues(alpha: 0.15)
                  : AppColors.amberWarning.withValues(alpha: 0.15),
              blurRadius: 10,
              spreadRadius: 1,
            ),
          ],
        ),
        child: Stack(
          children: [
            // Pastilla deslizante (Sliding capsule)
            AnimatedAlign(
              duration: const Duration(milliseconds: 320),
              curve: Curves.easeInOutBack,
              alignment: isDark ? Alignment.centerLeft : Alignment.centerRight,
              child: Container(
                width: 64,
                height: 32,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(22),
                  gradient: LinearGradient(
                    colors: isDark
                        ? [
                            AppColors.cyanWater.withValues(alpha: 0.85),
                            const Color(0xFF007A8A),
                          ]
                        : [
                            AppColors.amberWarning,
                            const Color(0xFFFFB74D),
                          ],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: isDark
                          ? AppColors.cyanWater.withValues(alpha: 0.4)
                          : AppColors.amberWarning.withValues(alpha: 0.35),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
              ),
            ),

            // Iconos y Etiquetas superpuestas
            Row(
              children: [
                // Opción Oscuro (Luna)
                Expanded(
                  child: Center(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.nightlight_round,
                          size: 13,
                          color: isDark ? Colors.white : (effectiveIsDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Oscuro',
                          style: TextStyle(
                            fontSize: 10.5,
                            fontWeight: isDark ? FontWeight.w800 : FontWeight.w600,
                            color: isDark ? Colors.white : (effectiveIsDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Opción Claro (Sol)
                Expanded(
                  child: Center(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.wb_sunny_rounded,
                          size: 13,
                          color: !isDark ? Colors.white : (effectiveIsDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Claro',
                          style: TextStyle(
                            fontSize: 10.5,
                            fontWeight: !isDark ? FontWeight.w800 : FontWeight.w600,
                            color: !isDark ? Colors.white : (effectiveIsDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
