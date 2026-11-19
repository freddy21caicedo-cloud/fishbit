import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:fishbit_finance/core/design_system/app_colors.dart';
import 'package:fishbit_finance/core/design_system/app_typography.dart';

/// Tarjeta metálica reflectiva `<ReflectiveCard />` (React Bits) adaptada a Flutter.
/// Simula reflexión líquida, grano metálico (`roughness`), brillo
/// especular direccional (`shine`) y destello reactivo al puntero (`glare`).
class ReflectiveCard extends StatefulWidget {
  final String? title;
  final String statusText;
  final Color tint;
  final double metalness;
  final double roughness;
  final double blurStrength;
  final double shine;
  final double glare;
  final double borderRadius;
  final EdgeInsetsGeometry? padding;
  final Widget child;

  const ReflectiveCard({
    super.key,
    this.title,
    this.statusText = 'ACTIVA',
    this.tint = AppColors.greenBiomass,
    this.metalness = 1.0,
    this.roughness = 0.3,
    this.blurStrength = 6.0,
    this.shine = 1.0,
    this.glare = 0.5,
    this.borderRadius = 24.0,
    this.padding,
    required this.child,
  });

  @override
  State<ReflectiveCard> createState() => _ReflectiveCardState();
}

class _ReflectiveCardState extends State<ReflectiveCard>
    with SingleTickerProviderStateMixin {
  static const Offset _restNorm = Offset(0.35, 0.25);

  late final Ticker _ticker;
  final ValueNotifier<int> _paintTick = ValueNotifier<int>(0);
  double _phase = 0.0;
  Duration _lastElapsed = Duration.zero;

  Offset _pointerNorm = _restNorm;
  Offset _targetNorm = _restNorm;
  bool _isHovering = false;

  @override
  void initState() {
    super.initState();
    _ticker = createTicker(_onTick);
  }

  void _ensureTickerRunning() {
    if (!_ticker.isActive) {
      _lastElapsed = Duration.zero;
      _ticker.start();
    }
  }

  void _onTick(Duration elapsed) {
    final dt = _lastElapsed == Duration.zero
        ? (1.0 / 60.0)
        : math.min(0.05, (elapsed - _lastElapsed).inMicroseconds / 1e6);
    _lastElapsed = elapsed;
    _phase += dt;

    if (_isHovering) {
      final lerpFactor = 1.0 - math.exp(-dt * 10.0);
      _pointerNorm = Offset.lerp(_pointerNorm, _targetNorm, lerpFactor) ?? _targetNorm;
    } else {
      _targetNorm = _restNorm;
      _pointerNorm = Offset.lerp(_pointerNorm, _restNorm, 0.12) ?? _restNorm;
      if ((_pointerNorm - _restNorm).distance < 0.002) {
        _pointerNorm = _restNorm;
        _lastElapsed = Duration.zero;
        _ticker.stop();
      }
    }

    _paintTick.value++;
  }

  @override
  void dispose() {
    _ticker.dispose();
    _paintTick.dispose();
    super.dispose();
  }

  void _updatePointer(Offset localPos, Size size) {
    if (size.width <= 0 || size.height <= 0) return;
    _isHovering = true;
    _targetNorm = Offset(
      (localPos.dx / size.width).clamp(0.0, 1.0),
      (localPos.dy / size.height).clamp(0.0, 1.0),
    );
    _ensureTickerRunning();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final radius = BorderRadius.circular(widget.borderRadius);
    final tint = widget.tint;
    final metalness = widget.metalness.clamp(0.0, 1.0);
    final roughness = widget.roughness.clamp(0.0, 1.0);
    final shine = widget.shine.clamp(0.0, 1.5);
    final glare = widget.glare.clamp(0.0, 1.0);

    final baseDark = Color.lerp(
      isDark ? const Color(0xFF061611) : const Color(0xFF0B2920),
      tint,
      0.22,
    )!;
    final baseMid = Color.lerp(
      isDark ? const Color(0xFF0B2B20) : const Color(0xFF103E2E),
      tint,
      0.42,
    )!;

    // Subárbol estático de contenido + fondo; solo los CustomPaint escuchan _paintTick.
    final cardBody = DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: radius,
        boxShadow: [
          BoxShadow(
            color: tint.withValues(alpha: isDark ? 0.24 : 0.20),
            blurRadius: 28,
            spreadRadius: -6,
            offset: const Offset(0, 12),
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.45 : 0.16),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: radius,
        child: Stack(
          children: [
            // 1. Capa de reflexión líquida + acabado metálico (sin BackdropFilter por frame)
            Positioned.fill(
              child: RepaintBoundary(
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [baseDark, baseMid, baseDark],
                          stops: const [0.0, 0.52, 1.0],
                        ),
                      ),
                    ),
                    CustomPaint(
                      painter: _ReflectiveWavesPainter(
                        repaint: _paintTick,
                        phaseGetter: () => _phase,
                        pointerNormGetter: () => _pointerNorm,
                        tint: tint,
                        metalness: metalness,
                      ),
                    ),
                    // Tinte metálico anisotrópico + grano cepillado (roughness)
                    CustomPaint(
                      painter: _MetallicFinishPainter(
                        repaint: _paintTick,
                        pointerNormGetter: () => _pointerNorm,
                        tint: tint,
                        metalness: metalness,
                        roughness: roughness,
                        shine: shine,
                        glare: glare,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // 2. Borde biselado metálico reflectivo
            Positioned.fill(
              child: IgnorePointer(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    borderRadius: radius,
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.22 + 0.14 * metalness),
                      width: 1.1,
                    ),
                  ),
                ),
              ),
            ),

            // 3. Contenido principal + Header estilo ReflectiveCard ("ACTIVA")
            Padding(
              padding: widget.padding ?? const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      if (widget.title != null)
                        Expanded(
                          child: Text(
                            widget.title!.toUpperCase(),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppTypography.labelMicro.copyWith(
                              color: Colors.white.withValues(alpha: 0.88),
                              letterSpacing: 1.1,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      const SizedBox(width: 8),
                      _ReflectiveActivePill(
                        text: widget.statusText,
                        accentColor: tint,
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  widget.child,
                ],
              ),
            ),
          ],
        ),
      ),
    );

    return MouseRegion(
      onEnter: (_) {
        _isHovering = true;
        _ensureTickerRunning();
      },
      onHover: (e) {
        final box = context.findRenderObject() as RenderBox?;
        if (box != null && box.hasSize) {
          _updatePointer(e.localPosition, box.size);
        }
      },
      onExit: (_) {
        _isHovering = false;
        _ensureTickerRunning();
      },
      child: Listener(
        behavior: HitTestBehavior.translucent,
        onPointerDown: (e) {
          final box = context.findRenderObject() as RenderBox?;
          if (box != null && box.hasSize) {
            _updatePointer(e.localPosition, box.size);
          }
        },
        onPointerMove: (e) {
          final box = context.findRenderObject() as RenderBox?;
          if (box != null && box.hasSize) {
            _updatePointer(e.localPosition, box.size);
          }
        },
        onPointerUp: (_) {
          _isHovering = false;
          _ensureTickerRunning();
        },
        onPointerCancel: (_) {
          _isHovering = false;
          _ensureTickerRunning();
        },
        child: ValueListenableBuilder<int>(
          valueListenable: _paintTick,
          child: cardBody,
          builder: (context, _, staticBody) {
            final tiltX = (_pointerNorm.dy - 0.5) * -0.045 * metalness;
            final tiltY = (_pointerNorm.dx - 0.5) * 0.045 * metalness;

            if (tiltX.abs() < 0.0005 && tiltY.abs() < 0.0005) {
              return staticBody!;
            }

            return Transform(
              alignment: Alignment.center,
              transform: Matrix4.identity()
                ..setEntry(3, 2, 0.001)
                ..rotateX(tiltX)
                ..rotateY(tiltY),
              child: staticBody,
            );
          },
        ),
      ),
    );
  }
}

class _ReflectiveActivePill extends StatelessWidget {
  final String text;
  final Color accentColor;

  const _ReflectiveActivePill({
    required this.text,
    required this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.28),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.24),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 7,
            height: 7,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0xFF34D399),
              boxShadow: [
                BoxShadow(
                  color: accentColor.withValues(alpha: 0.85),
                  blurRadius: 6,
                  spreadRadius: 1,
                ),
              ],
            ),
          ),
          const SizedBox(width: 6),
          Text(
            text.toUpperCase(),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTypography.labelMicro.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.9,
            ),
          ),
        ],
      ),
    );
  }
}

class _ReflectiveWavesPainter extends CustomPainter {
  final double Function() phaseGetter;
  final Offset Function() pointerNormGetter;
  final Color tint;
  final double metalness;

  const _ReflectiveWavesPainter({
    super.repaint,
    required this.phaseGetter,
    required this.pointerNormGetter,
    required this.tint,
    required this.metalness,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    if (w <= 0 || h <= 0) return;

    final phase = phaseGetter();
    final pointerNorm = pointerNormGetter();

    // Bandas fluidas de reflexión que simulan movimiento acuático/metálico
    final c1 = Offset(
      w * (0.25 + 0.18 * math.sin(phase * 0.7) + (pointerNorm.dx - 0.5) * 0.25),
      h * (0.30 + 0.18 * math.cos(phase * 0.6) + (pointerNorm.dy - 0.5) * 0.2),
    );
    final c2 = Offset(
      w * (0.78 + 0.16 * math.cos(phase * 0.55) - (pointerNorm.dx - 0.5) * 0.2),
      h * (0.72 + 0.16 * math.sin(phase * 0.8)),
    );

    final r1 = math.max(w, h) * 0.68;
    final r2 = math.max(w, h) * 0.58;

    canvas.drawCircle(
      c1,
      r1,
      Paint()
        ..shader = RadialGradient(
          colors: [
            tint.withValues(alpha: 0.55 * (0.5 + 0.5 * metalness)),
            tint.withValues(alpha: 0.18),
            Colors.transparent,
          ],
          stops: const [0.0, 0.55, 1.0],
        ).createShader(Rect.fromCircle(center: c1, radius: r1)),
    );

    canvas.drawCircle(
      c2,
      r2,
      Paint()
        ..shader = RadialGradient(
          colors: [
            const Color(0xFF6EE7B7).withValues(alpha: 0.42),
            tint.withValues(alpha: 0.14),
            Colors.transparent,
          ],
          stops: const [0.0, 0.5, 1.0],
        ).createShader(Rect.fromCircle(center: c2, radius: r2)),
    );
  }

  @override
  bool shouldRepaint(covariant _ReflectiveWavesPainter oldDelegate) =>
      oldDelegate.tint != tint || oldDelegate.metalness != metalness;
}

class _MetallicFinishPainter extends CustomPainter {
  final Offset Function() pointerNormGetter;
  final Color tint;
  final double metalness;
  final double roughness;
  final double shine;
  final double glare;

  const _MetallicFinishPainter({
    super.repaint,
    required this.pointerNormGetter,
    required this.tint,
    required this.metalness,
    required this.roughness,
    required this.shine,
    required this.glare,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    if (size.isEmpty) return;

    final pointerNorm = pointerNormGetter();

    // 1. Barrido especular metálico diagonal (shine)
    if (shine > 0.01) {
      final shift = (pointerNorm.dx - 0.5) * 0.7 + (pointerNorm.dy - 0.5) * 0.3;
      final centerStop = (0.5 + shift).clamp(0.15, 0.85);
      final bandWidth = 0.16 + 0.18 * roughness;

      canvas.drawRect(
        rect,
        Paint()
          ..shader = LinearGradient(
            begin: const Alignment(-1.0, -0.8),
            end: const Alignment(1.0, 0.8),
            stops: [
              (centerStop - bandWidth).clamp(0.0, 1.0),
              centerStop,
              (centerStop + bandWidth).clamp(0.0, 1.0),
            ],
            colors: [
              Colors.transparent,
              Colors.white.withValues(alpha: (0.22 * shine * metalness).clamp(0.0, 0.45)),
              Colors.transparent,
            ],
          ).createShader(rect),
      );
    }

    // 2. Glare radial interactivo que sigue el cursor/toque
    if (glare > 0.01) {
      final center = Offset(
        pointerNorm.dx * size.width,
        pointerNorm.dy * size.height,
      );
      final radius = math.max(size.width, size.height) * (0.45 + 0.2 * roughness);
      canvas.drawCircle(
        center,
        radius,
        Paint()
          ..shader = RadialGradient(
            colors: [
              Colors.white.withValues(alpha: (0.28 * glare).clamp(0.0, 0.45)),
              tint.withValues(alpha: (0.14 * glare).clamp(0.0, 0.3)),
              Colors.transparent,
            ],
            stops: const [0.0, 0.42, 1.0],
          ).createShader(Rect.fromCircle(center: center, radius: radius)),
      );
    }

    // 3. Micro-textura cepillada horizontal sutil controlada por roughness
    if (roughness > 0.02) {
      final grainPaint = Paint()
        ..color = Colors.white.withValues(alpha: (0.045 * roughness).clamp(0.0, 0.08))
        ..strokeWidth = 0.8;
      for (double y = 2.0; y < size.height; y += 5.0) {
        canvas.drawLine(Offset(0, y), Offset(size.width, y), grainPaint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _MetallicFinishPainter oldDelegate) =>
      oldDelegate.tint != tint ||
      oldDelegate.metalness != metalness ||
      oldDelegate.roughness != roughness ||
      oldDelegate.shine != shine ||
      oldDelegate.glare != glare;
}
