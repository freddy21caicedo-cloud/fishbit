import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fishbit_finance/core/design_system/app_colors.dart';
import 'package:fishbit_finance/core/design_system/app_typography.dart';

class MagicBentoCardData {
  final String title;
  final String? subtitle;
  final IconData? icon;
  final Color glowColor;
  final VoidCallback? onTap;
  final Widget child;

  const MagicBentoCardData({
    required this.title,
    this.subtitle,
    this.icon,
    this.glowColor = AppColors.cyanWater,
    this.onTap,
    required this.child,
  });
}

/// Grid interactivo `<MagicBento />` (React Bits) adaptado nativamente a Flutter:
/// - Spotlight global que cruza tarjetas (`spotlightRadius`)
/// - Border Glow direccional reactivo al cursor (`enableBorderGlow`)
/// - Estrellas/partículas destellantes (`enableStars`)
/// - Magnetismo y micro-inclinación en hover (`enableMagnetism`)
/// - Onda expansiva al hacer clic/tocar (`clickEffect`)
class MagicBentoGrid extends StatefulWidget {
  final List<MagicBentoCardData> items;
  final int columns;
  final double rowHeight;
  final double gap;
  final double radius;
  final bool enableBorderGlow;
  final bool enableSpotlight;
  final double spotlightRadius;
  final bool clickEffect;
  final bool enableStars;
  final bool enableMagnetism;

  const MagicBentoGrid({
    super.key,
    required this.items,
    this.columns = 4,
    this.rowHeight = 200.0,
    this.gap = 12.0,
    this.radius = 20.0,
    this.enableBorderGlow = true,
    this.enableSpotlight = true,
    this.spotlightRadius = 420.0,
    this.clickEffect = true,
    this.enableStars = true,
    this.enableMagnetism = true,
  });

  @override
  State<MagicBentoGrid> createState() => _MagicBentoGridState();
}

class _MagicBentoGridState extends State<MagicBentoGrid> {
  final ValueNotifier<Offset?> _pointerNotifier = ValueNotifier<Offset?>(null);

  void _updatePointer(Offset pos) {
    _pointerNotifier.value = pos;
  }

  void _clearPointer() {
    if (_pointerNotifier.value != null) {
      _pointerNotifier.value = null;
    }
  }

  @override
  void dispose() {
    _pointerNotifier.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final maxWidth = constraints.maxWidth;
        final effectiveCols = maxWidth >= 840
            ? widget.columns
            : math.min(2, widget.columns);
        final effectiveRowHeight =
            effectiveCols >= 4 ? widget.rowHeight : math.min(widget.rowHeight, 152.0);
        final cardWidth =
            (maxWidth - (effectiveCols - 1) * widget.gap) / effectiveCols;

        final rowCount = (widget.items.length / effectiveCols).ceil();
        final totalHeight = rowCount * effectiveRowHeight +
            math.max(0, rowCount - 1) * widget.gap;

        return MouseRegion(
          onHover: (e) => _updatePointer(e.localPosition),
          onExit: (_) => _clearPointer(),
          child: Listener(
            behavior: HitTestBehavior.translucent,
            onPointerMove: (e) => _updatePointer(e.localPosition),
            onPointerDown: (e) => _updatePointer(e.localPosition),
            child: SizedBox(
              width: maxWidth,
              height: totalHeight,
              child: Stack(
                clipBehavior: Clip.none,
                children: List.generate(widget.items.length, (index) {
                  final col = index % effectiveCols;
                  final row = index ~/ effectiveCols;
                  final left = col * (cardWidth + widget.gap);
                  final top = row * (effectiveRowHeight + widget.gap);

                  return Positioned(
                    left: left,
                    top: top,
                    width: cardWidth,
                    height: effectiveRowHeight,
                    child: RepaintBoundary(
                      child: _MagicBentoCard(
                        data: widget.items[index],
                        seed: index + 1,
                        radius: widget.radius,
                        pointerListenable: _pointerNotifier,
                        cardOffset: Offset(left, top),
                        spotlightRadius: widget.spotlightRadius,
                        enableBorderGlow: widget.enableBorderGlow,
                        enableSpotlight: widget.enableSpotlight,
                        clickEffect: widget.clickEffect,
                        enableStars: widget.enableStars,
                        enableMagnetism: widget.enableMagnetism,
                      ),
                    ),
                  );
                }),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _MagicBentoCard extends StatefulWidget {
  final MagicBentoCardData data;
  final int seed;
  final double radius;
  final ValueListenable<Offset?> pointerListenable;
  final Offset cardOffset;
  final double spotlightRadius;
  final bool enableBorderGlow;
  final bool enableSpotlight;
  final bool clickEffect;
  final bool enableStars;
  final bool enableMagnetism;

  const _MagicBentoCard({
    required this.data,
    required this.seed,
    required this.radius,
    required this.pointerListenable,
    required this.cardOffset,
    required this.spotlightRadius,
    required this.enableBorderGlow,
    required this.enableSpotlight,
    required this.clickEffect,
    required this.enableStars,
    required this.enableMagnetism,
  });

  @override
  State<_MagicBentoCard> createState() => _MagicBentoCardState();
}

class _MagicBentoCardState extends State<_MagicBentoCard>
    with TickerProviderStateMixin {
  bool _isHovered = false;
  Offset? _hoverLocal;
  Offset? _clickOrigin;

  late final AnimationController _rippleController;
  late final AnimationController _starsController;
  late final List<_BentoStar> _stars;

  @override
  void initState() {
    super.initState();
    _rippleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 520),
    );
    _starsController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..value = 0.35;

    final rng = math.Random(widget.seed * 7919);
    _stars = List.generate(
      10,
      (_) => _BentoStar(
        nx: 0.1 + rng.nextDouble() * 0.8,
        ny: 0.1 + rng.nextDouble() * 0.8,
        radius: 0.9 + rng.nextDouble() * 1.4,
        phase: rng.nextDouble() * math.pi * 2,
      ),
    );
  }

  @override
  void didUpdateWidget(covariant _MagicBentoCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.enableStars != oldWidget.enableStars) {
      if (!widget.enableStars) {
        _starsController.stop();
      } else if (_isHovered && !_starsController.isAnimating) {
        _starsController.repeat();
      }
    }
  }

  @override
  void dispose() {
    _rippleController.dispose();
    _starsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final glowColor = widget.data.glowColor;
    final borderRadius = BorderRadius.circular(widget.radius);

    return LayoutBuilder(
      builder: (context, constraints) {
        final w = math.max(constraints.maxWidth, 1.0);
        final h = math.max(constraints.maxHeight, 1.0);

        // Magnetismo e inclinación sutil hacia el cursor
        Matrix4 transform = Matrix4.identity();
        if (widget.enableMagnetism && _isHovered && _hoverLocal != null) {
          final dx = ((_hoverLocal!.dx / w) - 0.5).clamp(-0.5, 0.5);
          final dy = ((_hoverLocal!.dy / h) - 0.5).clamp(-0.5, 0.5);
          transform = Matrix4.identity()
            ..setEntry(3, 2, 0.0012)
            ..translateByDouble(dx * 5.0, dy * 5.0, 0.0, 1.0)
            ..rotateX(-dy * 0.05)
            ..rotateY(dx * 0.05);
        }

        final baseBg = isDark
            ? const Color(0xFF0C1322).withValues(alpha: 0.84)
            : Colors.white.withValues(alpha: 0.90);
        final restingBorder = isDark
            ? Colors.white.withValues(alpha: 0.09)
            : Colors.black.withValues(alpha: 0.07);

        return MouseRegion(
          cursor: widget.data.onTap != null
              ? SystemMouseCursors.click
              : SystemMouseCursors.basic,
          onEnter: (e) {
            setState(() {
              _isHovered = true;
              _hoverLocal = e.localPosition;
            });
            if (widget.enableStars && !_starsController.isAnimating) {
              _starsController.repeat();
            }
          },
          onHover: (e) => setState(() => _hoverLocal = e.localPosition),
          onExit: (_) {
            setState(() {
              _isHovered = false;
              _hoverLocal = null;
            });
            if (_starsController.isAnimating) {
              _starsController.stop();
            }
          },
          child: GestureDetector(
            onTapDown: (d) {
              if (widget.clickEffect) {
                _clickOrigin = d.localPosition;
                _rippleController.forward(from: 0.0);
              }
            },
            onTap: () {
              if (widget.data.onTap != null) {
                HapticFeedback.lightImpact();
                widget.data.onTap!();
              }
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              curve: Curves.easeOutCubic,
              transform: transform,
              transformAlignment: Alignment.center,
              decoration: BoxDecoration(
                color: baseBg,
                borderRadius: borderRadius,
                border: Border.all(color: restingBorder, width: 1),
                boxShadow: [
                  BoxShadow(
                    color: _isHovered
                        ? glowColor.withValues(alpha: isDark ? 0.16 : 0.14)
                        : Colors.black.withValues(alpha: isDark ? 0.28 : 0.06),
                    blurRadius: _isHovered ? 24 : 14,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: borderRadius,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    // 1. Spotlight radial global dentro de la tarjeta (sin reconstruir la tarjeta)
                    if (widget.enableSpotlight)
                      IgnorePointer(
                        child: RepaintBoundary(
                          child: ValueListenableBuilder<Offset?>(
                            valueListenable: widget.pointerListenable,
                            builder: (context, pointerInGrid, _) {
                              if (pointerInGrid == null) {
                                return const SizedBox.shrink();
                              }
                              return CustomPaint(
                                painter: _SpotlightPainter(
                                  center: pointerInGrid - widget.cardOffset,
                                  radius: widget.spotlightRadius,
                                  color: glowColor.withValues(
                                    alpha: isDark ? 0.16 : 0.12,
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ),

                    // 2. Estrellas / partículas destellantes
                    if (widget.enableStars)
                      IgnorePointer(
                        child: RepaintBoundary(
                          child: AnimatedBuilder(
                            animation: _starsController,
                            builder: (context, _) {
                              return CustomPaint(
                                painter: _StarsPainter(
                                  stars: _stars,
                                  progress: _starsController.value,
                                  color: glowColor,
                                  intensity: _isHovered ? 1.0 : 0.45,
                                ),
                              );
                            },
                          ),
                        ),
                      ),

                    // 3. Click ripple burst
                    if (widget.clickEffect)
                      IgnorePointer(
                        child: AnimatedBuilder(
                          animation: _rippleController,
                          builder: (context, _) {
                            if (_clickOrigin == null ||
                                _rippleController.value == 0 ||
                                _rippleController.isCompleted) {
                              return const SizedBox.shrink();
                            }
                            return CustomPaint(
                              painter: _ClickRipplePainter(
                                origin: _clickOrigin!,
                                progress: Curves.easeOutCubic
                                    .transform(_rippleController.value),
                                color: glowColor,
                              ),
                            );
                          },
                        ),
                      ),

                    // 4. Contenido de la tarjeta Bento
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              if (widget.data.icon != null) ...[
                                Container(
                                  padding: const EdgeInsets.all(7),
                                  decoration: BoxDecoration(
                                    color: glowColor.withValues(alpha: 0.14),
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(
                                      color: glowColor.withValues(alpha: 0.25),
                                      width: 1,
                                    ),
                                  ),
                                  child: Icon(
                                    widget.data.icon,
                                    size: 16,
                                    color: glowColor,
                                  ),
                                ),
                                const SizedBox(width: 10),
                              ],
                              Expanded(
                                child: Text(
                                  widget.data.title.toUpperCase(),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: AppTypography.labelMicro.copyWith(
                                    color: isDark
                                        ? AppColors.textSecondaryDark
                                        : AppColors.textSecondaryLight,
                                    letterSpacing: 0.8,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                              if (widget.data.onTap != null)
                                Icon(
                                  Icons.arrow_outward_rounded,
                                  size: 14,
                                  color: _isHovered
                                      ? glowColor
                                      : (isDark
                                          ? Colors.white24
                                          : AppColors.textTertiaryLight),
                                ),
                            ],
                          ),
                          widget.data.child,
                        ],
                      ),
                    ),

                    // 5. Border Glow direccional reactivo al cursor (sin reconstruir la tarjeta)
                    if (widget.enableBorderGlow)
                      IgnorePointer(
                        child: RepaintBoundary(
                          child: ValueListenableBuilder<Offset?>(
                            valueListenable: widget.pointerListenable,
                            builder: (context, pointerInGrid, _) {
                              if (pointerInGrid == null) {
                                return const SizedBox.shrink();
                              }
                              return CustomPaint(
                                painter: _BorderGlowPainter(
                                  center: pointerInGrid - widget.cardOffset,
                                  spotlightRadius: widget.spotlightRadius,
                                  borderRadius: widget.radius,
                                  color: glowColor,
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _BentoStar {
  final double nx;
  final double ny;
  final double radius;
  final double phase;

  const _BentoStar({
    required this.nx,
    required this.ny,
    required this.radius,
    required this.phase,
  });
}

class _SpotlightPainter extends CustomPainter {
  final Offset center;
  final double radius;
  final Color color;

  const _SpotlightPainter({
    required this.center,
    required this.radius,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..shader = ui.Gradient.radial(
        center,
        radius * 0.72,
        [color, color.withValues(alpha: 0.0)],
      );
    canvas.drawRect(Offset.zero & size, paint);
  }

  @override
  bool shouldRepaint(covariant _SpotlightPainter oldDelegate) =>
      oldDelegate.center != center ||
      oldDelegate.radius != radius ||
      oldDelegate.color != color;
}

class _BorderGlowPainter extends CustomPainter {
  final Offset center;
  final double spotlightRadius;
  final double borderRadius;
  final Color color;

  const _BorderGlowPainter({
    required this.center,
    required this.spotlightRadius,
    required this.borderRadius,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final rrect = RRect.fromRectAndRadius(
      Rect.fromLTWH(0.75, 0.75, size.width - 1.5, size.height - 1.5),
      Radius.circular(borderRadius),
    );
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.6
      ..shader = ui.Gradient.radial(
        center,
        spotlightRadius * 0.65,
        [
          color.withValues(alpha: 0.85),
          color.withValues(alpha: 0.25),
          color.withValues(alpha: 0.0),
        ],
        const [0.0, 0.45, 1.0],
      );
    canvas.drawRRect(rrect, paint);
  }

  @override
  bool shouldRepaint(covariant _BorderGlowPainter oldDelegate) =>
      oldDelegate.center != center ||
      oldDelegate.spotlightRadius != spotlightRadius ||
      oldDelegate.color != color;
}

class _StarsPainter extends CustomPainter {
  final List<_BentoStar> stars;
  final double progress;
  final Color color;
  final double intensity;

  const _StarsPainter({
    required this.stars,
    required this.progress,
    required this.color,
    required this.intensity,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final t = progress * math.pi * 2;
    for (final s in stars) {
      final twinkle = 0.25 + 0.75 * (0.5 + 0.5 * math.sin(t + s.phase));
      final alpha = (twinkle * intensity * 0.55).clamp(0.0, 1.0);
      final pos = Offset(
        s.nx * size.width,
        s.ny * size.height + math.sin(t + s.phase) * 2.5,
      );
      canvas.drawCircle(
        pos,
        s.radius,
        Paint()..color = color.withValues(alpha: alpha),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _StarsPainter oldDelegate) =>
      oldDelegate.progress != progress || oldDelegate.intensity != intensity;
}

class _ClickRipplePainter extends CustomPainter {
  final Offset origin;
  final double progress;
  final Color color;

  const _ClickRipplePainter({
    required this.origin,
    required this.progress,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final maxR = math.sqrt(size.width * size.width + size.height * size.height);
    final r = maxR * progress;
    final alpha = (1.0 - progress).clamp(0.0, 1.0);

    canvas.drawCircle(
      origin,
      r,
      Paint()
        ..color = color.withValues(alpha: alpha * 0.20)
        ..style = PaintingStyle.fill,
    );
    canvas.drawCircle(
      origin,
      r,
      Paint()
        ..color = color.withValues(alpha: alpha * 0.55)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.6,
    );
  }

  @override
  bool shouldRepaint(covariant _ClickRipplePainter oldDelegate) =>
      oldDelegate.progress != progress || oldDelegate.origin != origin;
}
