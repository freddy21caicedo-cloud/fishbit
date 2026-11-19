import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:fishbit_finance/core/design_system/app_colors.dart';

/// Ámbito interno que marca cuándo los descendientes ya están dentro de la
/// carcasa principal de un menú, popover o modal flotante, evitando aplicar
/// opacidad de overlay o `BackdropFilter` redundantes en capas anidadas.
class _GlassOverlayScope extends InheritedWidget {
  final bool isInsideOverlay;

  const _GlassOverlayScope({
    required this.isInsideOverlay,
    required super.child,
  });

  static bool isInside(BuildContext context) {
    return context
            .dependOnInheritedWidgetOfExactType<_GlassOverlayScope>()
            ?.isInsideOverlay ??
        false;
  }

  @override
  bool updateShouldNotify(covariant _GlassOverlayScope oldWidget) =>
      oldWidget.isInsideOverlay != isInsideOverlay;
}

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
  final bool enableBlur;

  /// Define explícitamente si este contenedor actúa como carcasa flotante
  /// (menú, submenú, popover, bottom sheet o diálogo). Si es `null`, se detecta
  /// automáticamente cuando es la carcasa externa de una [PopupRoute].
  final bool? isOverlay;

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
    this.enableBlur = false,
    this.isOverlay,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final insideOverlay = _GlassOverlayScope.isInside(context);
    final isPopupRoute = ModalRoute.of(context) is PopupRoute<dynamic>;

    final effectiveIsOverlay = isOverlay ??
        (isPopupRoute && !insideOverlay && opacity >= 0.12 && blur >= 20.0);
    final isDarkOverlay = isDark && effectiveIsOverlay;

    final effectiveBorderRadius = BorderRadius.circular(borderRadius);

    late final Color fill;
    late final bool shouldBlur;
    late final double effectiveBlur;
    Gradient? overlayGradient;

    if (isDarkOverlay) {
      // En modo oscuro para menús/submenús/modales flotantes:
      // base obsidiana densa (88%) + BackdropFilter real + brillo superior sutil
      final bool hasExplicitDarkTint = tintColor != null &&
          tintColor != Colors.white &&
          tintColor!.computeLuminance() < 0.25;
      final baseColor =
          hasExplicitDarkTint ? tintColor! : AppColors.glassOverlayDarkBase;
      final overlayOpacity =
          opacity >= 0.80 ? opacity : AppColors.glassOverlayDarkOpacity;
      fill = baseColor.withValues(alpha: overlayOpacity);
      final topSheen = Color.alphaBlend(AppColors.glassOverlaySheenDark, fill);
      overlayGradient = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        stops: const [0.0, 0.30, 1.0],
        colors: [topSheen, fill, fill],
      );
      effectiveBlur = blur.clamp(18.0, 28.0);
      shouldBlur = blur > 0;
    } else {
      // Comportamiento estándar para tarjetas inline (oscuro) y todo el modo claro
      final defaultTint = tintColor ?? Colors.white;
      final effectiveOpacity =
          isDark ? opacity : (opacity > 0.4 ? opacity : 0.88);
      shouldBlur = enableBlur && blur > 0 && effectiveOpacity < 0.80;
      effectiveBlur = blur;
      final adjustedOpacity = (!shouldBlur && isDark && opacity < 0.12)
          ? (opacity * 1.4).clamp(0.08, 0.22)
          : effectiveOpacity;
      fill = defaultTint.withValues(alpha: adjustedOpacity);
    }

    final border = customBorder ??
        Border.all(
          color: borderColor ??
              (isDarkOverlay
                  ? AppColors.glassOverlayBorderDark
                  : (isDark
                      ? Colors.white.withValues(alpha: 0.10)
                      : AppColors.glassBorderLight)),
          width: borderWidth,
        );

    final Widget wrappedChild = effectiveIsOverlay
        ? _GlassOverlayScope(isInsideOverlay: true, child: child)
        : child;

    final contentContainer = Container(
      padding: padding ?? const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: overlayGradient == null ? fill : null,
        gradient: overlayGradient,
        borderRadius: effectiveBorderRadius,
        border: border,
      ),
      child: wrappedChild,
    );

    return RepaintBoundary(
      child: Container(
        width: width,
        height: height,
        margin: margin,
        decoration: BoxDecoration(
          borderRadius: effectiveBorderRadius,
          boxShadow: shadows ??
              [
                if (isDarkOverlay) ...[
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.58),
                    blurRadius: 32,
                    spreadRadius: -4,
                    offset: const Offset(0, 14),
                  ),
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.32),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ] else if (isDark)
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
          borderRadius: effectiveBorderRadius,
          child: shouldBlur
              ? BackdropFilter(
                  filter: ImageFilter.blur(
                    sigmaX: effectiveBlur,
                    sigmaY: effectiveBlur,
                  ),
                  child: contentContainer,
                )
              : contentContainer,
        ),
      ),
    );
  }
}
