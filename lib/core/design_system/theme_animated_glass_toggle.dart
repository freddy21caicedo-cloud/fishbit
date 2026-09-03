import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fishbit_finance/core/design_system/app_colors.dart';
import 'package:fishbit_finance/core/design_system/theme_provider.dart';

/// Botón Toggle Animado con Efecto Glassmorphism y Micro-interacciones
class ThemeAnimatedGlassToggle extends ConsumerWidget {
  const ThemeAnimatedGlassToggle({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);
    final isDark = themeMode == ThemeMode.dark;

    return InkWell(
      onTap: () => ref.read(themeModeProvider.notifier).toggleTheme(),
      borderRadius: BorderRadius.circular(30),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeInOutCubic,
        width: 140,
        height: 42,
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(30),
          color: isDark
              ? Colors.white.withValues(alpha: 0.08)
              : Colors.black.withValues(alpha: 0.06),
          border: Border.all(
            color: isDark
                ? AppColors.cyanWater.withValues(alpha: 0.35)
                : AppColors.amberWarning.withValues(alpha: 0.45),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: isDark
                  ? AppColors.cyanWater.withValues(alpha: 0.15)
                  : AppColors.amberWarning.withValues(alpha: 0.20),
              blurRadius: 12,
              spreadRadius: 1,
            ),
          ],
        ),
        child: Stack(
          children: [
            // Pastilla deslizante (Sliding capsule)
            AnimatedAlign(
              duration: const Duration(milliseconds: 350),
              curve: Curves.easeInOutBack,
              alignment: isDark ? Alignment.centerLeft : Alignment.centerRight,
              child: Container(
                width: 66,
                height: 34,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(24),
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
                          : AppColors.amberWarning.withValues(alpha: 0.4),
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
                          size: 15,
                          color: isDark ? Colors.white : AppColors.textSecondaryDark,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Oscuro',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: isDark ? FontWeight.w800 : FontWeight.w600,
                            color: isDark ? Colors.white : AppColors.textSecondaryDark,
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
                          size: 15,
                          color: !isDark ? Colors.white : AppColors.textSecondaryDark,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Claro',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: !isDark ? FontWeight.w800 : FontWeight.w600,
                            color: !isDark ? Colors.white : AppColors.textSecondaryDark,
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
