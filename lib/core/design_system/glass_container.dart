import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:fishbit_finance/core/design_system/app_colors.dart';

/// Contenedor de vidrio esmerilado con desenfoque gaussiano y borde luminoso optimizado para 120 FPS
class GlassContainer extends StatelessWidget {
  final Widget child;
  final double blur;
  final double opacity;
  final double borderRadius;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final Color? tintColor;
  final Color? borderColor;
  final double borderWidth;
  final BoxBorder? customBorder;
  final List<BoxShadow>? shadows;
  final double? width;
  final double? height;

  const GlassContainer({
    super.key,
    required this.child,
    this.blur = 16.0,
    this.opacity = 0.06,
    this.borderRadius = 20.0,
    this.padding,
    this.margin,
    this.tintColor,
    this.borderColor,
    this.borderWidth = 1.0,
    this.customBorder,
    this.shadows,
    this.width,
    this.height,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    // En modo oscuro: vidrio translúcido OLED con leve tinte blanco
    // En modo claro: acrílico blanco esmerilado puro (Apple Frosted Glass)
    final defaultTint = tintColor ?? Colors.white;
    final effectiveOpacity = isDark ? opacity : (opacity > 0.4 ? opacity : 0.88);
    final fill = defaultTint.withValues(alpha: effectiveOpacity);

    final border = customBorder ??
        Border.all(
          color: borderColor ??
              (isDark
                  ? Colors.white.withValues(alpha: 0.10)
                  : AppColors.glassBorderLight),
          width: borderWidth,
        );

    return RepaintBoundary(
      child: Container(
        width: width,
        height: height,
        margin: margin,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(borderRadius),
          boxShadow: shadows ??
              [
                if (isDark)
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.35),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  )
                else ...[
                  BoxShadow(
                    color: const Color(0xFF64748B).withValues(alpha: 0.07),
                    blurRadius: 22,
                    offset: const Offset(0, 8),
                    spreadRadius: -2,
                  ),
                  BoxShadow(
                    color: const Color(0xFF0F172A).withValues(alpha: 0.03),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(borderRadius),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
            child: Container(
              padding: padding ?? const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: fill,
                borderRadius: BorderRadius.circular(borderRadius),
                border: border,
              ),
              child: child,
            ),
          ),
        ),
      ),
    );
  }
}
