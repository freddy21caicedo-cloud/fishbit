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

/// Botón Switch Día/Noche animado (Estilo Uiverse JustCode14: Luna + Estrellas / Sol + Nube)
class ThemeAnimatedGlassToggle extends ConsumerWidget {
  const ThemeAnimatedGlassToggle({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);
    final effectiveIsDark = Theme.of(context).brightness == Brightness.dark;
    final isDark =
        themeMode == ThemeMode.dark || (themeMode == ThemeMode.system && effectiveIsDark);

    return Semantics(
      toggled: !isDark,
      button: true,
      label: isDark ? 'Cambiar a modo claro' : 'Cambiar a modo oscuro',
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: GestureDetector(
          onTap: () {
            HapticFeedback.mediumImpact();
            ref.read(themeModeProvider.notifier).toggleTheme(context);
          },
          behavior: HitTestBehavior.opaque,
          child: Container(
            width: 68,
            height: 38,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(30),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.10),
                  blurRadius: 10,
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(30),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 400),
                curve: Curves.easeInOut,
                color: isDark ? const Color(0xFF2A2A2A) : const Color(0xFF00A6FF),
                child: Stack(
                  clipBehavior: Clip.hardEdge,
                  children: [
                    // Estrellas (Modo Oscuro)
                    _ThemeStarDot(left: 42.5, top: 8.5, visible: isDark),
                    _ThemeStarDot(left: 37.4, top: 20.4, visible: isDark),
                    _ThemeStarDot(left: 51.0, top: 15.3, visible: isDark),

                    // Nube (Modo Claro)
                    Positioned(
                      left: -18.7,
                      bottom: -23.8,
                      child: AnimatedOpacity(
                        opacity: isDark ? 0.0 : 1.0,
                        duration: const Duration(milliseconds: 400),
                        curve: Curves.easeInOut,
                        child: CustomPaint(
                          size: const Size(59.5, 42.0),
                          painter: _DayCloudPainter(),
                        ),
                      ),
                    ),

                    // Perilla Luna / Sol
                    AnimatedPositioned(
                      duration: const Duration(milliseconds: 400),
                      curve: const Cubic(0.81, -0.04, 0.38, 1.5),
                      left: isDark ? 8.5 : 39.1,
                      bottom: 8.5,
                      width: 20.4,
                      height: 20.4,
                      child: TweenAnimationBuilder<double>(
                        tween: Tween<double>(end: isDark ? 0.0 : 1.0),
                        duration: const Duration(milliseconds: 400),
                        curve: Curves.easeInOut,
                        builder: (context, progress, _) {
                          return CustomPaint(
                            size: const Size.square(20.4),
                            painter: _CelestialKnobPainter(progress: progress),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ThemeStarDot extends StatelessWidget {
  final double left;
  final double top;
  final bool visible;

  const _ThemeStarDot({
    required this.left,
    required this.top,
    required this.visible,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: left,
      top: top,
      child: AnimatedOpacity(
        opacity: visible ? 1.0 : 0.0,
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
        child: Container(
          width: 5,
          height: 5,
          decoration: const BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
          ),
        ),
      ),
    );
  }
}

class _CelestialKnobPainter extends CustomPainter {
  final double progress; // 0.0 = luna creciente (#FFFFFF), 1.0 = sol (#FFCF48)

  const _CelestialKnobPainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;
    final color = Color.lerp(Colors.white, const Color(0xFFFFCF48), progress)!;

    final outerCircle = Path()
      ..addOval(Rect.fromCircle(center: center, radius: radius));

    if (progress >= 0.99) {
      canvas.drawPath(outerCircle, Paint()..color = color);
      return;
    }

    // Recorte que simula `box-shadow: inset 8px -4px 0px 0px #fff` en modo oscuro
    // y se desliza fuera del círculo al pasar a modo claro.
    final cutoutCenter = Offset(
      center.dx + radius * (0.52 + progress * 1.65),
      center.dy - radius * (0.34 + progress * 0.65),
    );
    final cutout = Path()
      ..addOval(Rect.fromCircle(center: cutoutCenter, radius: radius * 0.88));

    final crescent = Path.combine(PathOperation.difference, outerCircle, cutout);
    canvas.drawPath(crescent, Paint()..color = color);
  }

  @override
  bool shouldRepaint(covariant _CelestialKnobPainter oldDelegate) =>
      oldDelegate.progress != progress;
}

class _DayCloudPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;

    final w = size.width;
    final h = size.height;

    final cloudPath = Path()
      ..addOval(Rect.fromCircle(center: Offset(w * 0.30, h * 0.56), radius: w * 0.22))
      ..addOval(Rect.fromCircle(center: Offset(w * 0.52, h * 0.36), radius: w * 0.26))
      ..addOval(Rect.fromCircle(center: Offset(w * 0.74, h * 0.52), radius: w * 0.20))
      ..addRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(w * 0.12, h * 0.48, w * 0.78, h * 0.42),
          const Radius.circular(14),
        ),
      );

    canvas.drawPath(cloudPath, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
