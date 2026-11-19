import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';

enum StarBorderHoverMode { lap, brighten, reveal, none }

enum StarBorderDirection { clockwise, counterclockwise }

class _OutlineSegment {
  final double length;
  final double x;
  final double y;
  final double dx;
  final double dy;
  final double? angle;

  const _OutlineSegment({
    required this.length,
    required this.x,
    required this.y,
    required this.dx,
    required this.dy,
    required this.angle,
  });
}

class _OutlineShape {
  final double r;
  final List<_OutlineSegment> segments;
  final double total;

  const _OutlineShape({
    required this.r,
    required this.segments,
    required this.total,
  });
}

class _PerimeterPoint {
  double x = 0;
  double y = 0;
  double nx = 0;
  double ny = -1;
}

class _StarPulse {
  final double origin;
  double age = 0;

  _StarPulse(this.origin);
}

class _StarDust {
  double x;
  double y;
  double vx;
  double vy;
  double age = 0;
  final double life;
  final double size;
  final double seed;

  _StarDust({
    required this.x,
    required this.y,
    required this.vx,
    required this.vy,
    required this.life,
    required this.size,
    required this.seed,
  });
}

/// Botón `<StarBorder />` (React Bits) adaptado nativamente a Flutter.
class StarBorderButton extends StatefulWidget {
  final Widget child;
  final VoidCallback? onPressed;
  final Color? color;
  final Color? trailColor;
  final double duration;
  final StarBorderDirection direction;
  final int stars;
  final double trailLength;
  final double thickness;
  final double radius;
  final double glow;
  final bool sparkle;
  final StarBorderHoverMode hover;
  final bool clickPulse;
  final Color? backgroundColor;
  final Color? textColor;
  final Color? borderColor;
  final EdgeInsetsGeometry padding;
  final bool isLoading;

  const StarBorderButton({
    super.key,
    required this.child,
    this.onPressed,
    this.color,
    this.trailColor,
    this.duration = 6.0,
    this.direction = StarBorderDirection.clockwise,
    this.stars = 1,
    this.trailLength = 0.3,
    this.thickness = 1.0,
    this.radius = 12.0,
    this.glow = 0.7,
    this.sparkle = true,
    this.hover = StarBorderHoverMode.lap,
    this.clickPulse = true,
    this.backgroundColor,
    this.textColor,
    this.borderColor,
    this.padding = const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
    this.isLoading = false,
  });

  @override
  State<StarBorderButton> createState() => _StarBorderButtonState();
}

class _StarBorderButtonState extends State<StarBorderButton>
    with SingleTickerProviderStateMixin {
  static const double _lapDuration = 0.9;
  static const double _tau = math.pi * 2;

  final GlobalKey _boxKey = GlobalKey();
  final math.Random _rng = math.Random();
  final ValueNotifier<int> _paintTick = ValueNotifier<int>(0);
  late Ticker _ticker;
  Duration _lastElapsed = Duration.zero;

  Size _size = Size.zero;
  double _phase = 0;
  double _velocity = 0;
  double _motion = 0;
  double _lap = -1;
  double _time = 0;
  double _reveal = 1.0;
  double _boost = 0;
  double _flash = 0;
  double _emit = 0;
  bool _hovered = false;
  bool _pressed = false;
  final List<_StarPulse> _pulses = [];
  final List<_StarDust> _dust = [];

  @override
  void initState() {
    super.initState();
    _reveal = widget.hover == StarBorderHoverMode.reveal ? 0.0 : 1.0;
    _ticker = createTicker(_onTick)..start();
  }

  @override
  void dispose() {
    _ticker.dispose();
    _paintTick.dispose();
    super.dispose();
  }

  double _wrap(double v, double total) => ((v % total) + total) % total;

  double _ease(double t) =>
      t < 0.5 ? 4 * t * t * t : 1 - math.pow(2 - 2 * t, 3) / 2;

  _OutlineShape _outline(double width, double height, double radius) {
    final r = math.max(0.0, math.min(radius, math.min(width / 2, height / 2)));
    final arc = (math.pi * r) / 2;
    final across = math.max(0.0, width - 2 * r);
    final down = math.max(0.0, height - 2 * r);
    final segments = [
      _OutlineSegment(length: across, x: r, y: 0, dx: 1, dy: 0, angle: null),
      _OutlineSegment(length: arc, x: width - r, y: r, dx: 0, dy: 0, angle: -math.pi / 2),
      _OutlineSegment(length: down, x: width, y: r, dx: 0, dy: 1, angle: null),
      _OutlineSegment(length: arc, x: width - r, y: height - r, dx: 0, dy: 0, angle: 0),
      _OutlineSegment(length: across, x: width - r, y: height, dx: -1, dy: 0, angle: null),
      _OutlineSegment(length: arc, x: r, y: height - r, dx: 0, dy: 0, angle: math.pi / 2),
      _OutlineSegment(length: down, x: 0, y: height - r, dx: 0, dy: -1, angle: null),
      _OutlineSegment(length: arc, x: r, y: r, dx: 0, dy: 0, angle: math.pi),
    ];
    final total = math.max(
      1.0,
      segments.fold<double>(0.0, (sum, s) => sum + s.length),
    );
    return _OutlineShape(r: r, segments: segments, total: total);
  }

  _OutlineShape _shapeFor() {
    final t = math.max(0.5, widget.thickness);
    return _outline(
      math.max(1.0, _size.width - t),
      math.max(1.0, _size.height - t),
      math.max(0.0, widget.radius - t / 2),
    );
  }

  void _pointAt(_OutlineShape shape, double distance, _PerimeterPoint out) {
    var s = _wrap(distance, shape.total);
    for (final seg in shape.segments) {
      if (seg.length > 0 && s <= seg.length) {
        if (seg.angle == null) {
          out.x = seg.x + seg.dx * s;
          out.y = seg.y + seg.dy * s;
          out.nx = seg.dy;
          out.ny = -seg.dx;
        } else {
          final angle = seg.angle! + s / shape.r;
          out.nx = math.cos(angle);
          out.ny = math.sin(angle);
          out.x = seg.x + out.nx * shape.r;
          out.y = seg.y + out.ny * shape.r;
        }
        return;
      }
      s -= seg.length;
    }
  }

  double _project(_OutlineShape shape, double px, double py) {
    double best = double.infinity;
    double found = 0;
    double offset = 0;
    for (final seg in shape.segments) {
      if (seg.length > 0) {
        double s = 0;
        double x = 0;
        double y = 0;
        if (seg.angle == null) {
          s = ((px - seg.x) * seg.dx + (py - seg.y) * seg.dy)
              .clamp(0.0, seg.length);
          x = seg.x + seg.dx * s;
          y = seg.y + seg.dy * s;
        } else {
          var angle = _wrap(
            math.atan2(py - seg.y, px - seg.x) - seg.angle!,
            _tau,
          );
          if (angle > math.pi / 2) {
            angle = angle > math.pi * 1.25 ? 0 : math.pi / 2;
          }
          s = angle * shape.r;
          x = seg.x + math.cos(seg.angle! + angle) * shape.r;
          y = seg.y + math.sin(seg.angle! + angle) * shape.r;
        }
        final distSq = (px - x) * (px - x) + (py - y) * (py - y);
        if (distSq < best) {
          best = distSq;
          found = offset + s;
        }
      }
      offset += seg.length;
    }
    return found;
  }

  void _spawnDust(double x, double y, double nx, double ny, double speed) {
    if (_dust.length > 42) return;
    final push = 3.0 + _rng.nextDouble() * 10.0;
    final drift = (_rng.nextDouble() - 0.5) * 8.0;
    _dust.add(
      _StarDust(
        x: x + nx * (_rng.nextDouble() * 3.0 - 1.0),
        y: y + ny * (_rng.nextDouble() * 3.0 - 1.0),
        vx: nx * push - ny * drift - speed * -ny * 0.04,
        vy: ny * push + nx * drift - speed * nx * 0.04,
        life: 0.35 + _rng.nextDouble() * 0.5,
        size: 0.5 + _rng.nextDouble() * 0.8,
        seed: _rng.nextDouble() * _tau,
      ),
    );
  }

  void _onTick(Duration elapsed) {
    final dt = _lastElapsed == Duration.zero
        ? (1.0 / 60.0)
        : math.min(0.05, math.max(0.001, (elapsed - _lastElapsed).inMicroseconds / 1e6));
    _lastElapsed = elapsed;
    _time += dt;

    final box = _boxKey.currentContext?.findRenderObject() as RenderBox?;
    if (box != null && box.hasSize && box.size != _size) {
      final wasUnmeasured = _size.width < 2 || _size.height < 2;
      _size = box.size;
      if (wasUnmeasured && _size.width >= 2 && _size.height >= 2 && mounted) {
        setState(() {});
      }
    }
    if (_size.width < 2 || _size.height < 2) return;

    final shape = _shapeFor();
    final total = shape.total;
    final stars = widget.stars.clamp(1, 6);
    final spacing = total / stars;
    final dur = math.max(0.3, widget.duration);
    final dir = widget.direction == StarBorderDirection.counterclockwise ? -1.0 : 1.0;
    final cruise = (dir * total) / dur;

    final revealTarget =
        (widget.hover == StarBorderHoverMode.reveal && !_hovered) ? 0.0 : 1.0;
    _reveal += (revealTarget - _reveal) *
        (1.0 - math.exp(-dt / (revealTarget > _reveal ? 0.16 : 0.45)));
    final boostTarget =
        (widget.hover == StarBorderHoverMode.brighten && _hovered) ? 1.0 : 0.0;
    _boost += (boostTarget - _boost) *
        (1.0 - math.exp(-dt / (boostTarget > _boost ? 0.18 : 0.5)));
    _flash *= math.exp(-dt / 0.22);

    _velocity += (cruise - _velocity) * (1.0 - math.exp(-dt / 0.45));
    double extra = 0;
    if (_lap >= 0) {
      final before = _ease(math.min(1.0, _lap / _lapDuration));
      _lap += dt;
      extra = (_ease(math.min(1.0, _lap / _lapDuration)) - before) * total * dir;
      if (_lap >= _lapDuration) _lap = -1;
    }
    _motion = _velocity + extra / dt;
    _phase = _wrap(_phase + _velocity * dt + extra, total);

    final pace = _motion.abs() / math.max(1.0, (total / dur).abs());
    if (widget.sparkle && _reveal > 0.05) {
      _emit += dt * (2.0 + 6.0 * math.min(2.0, pace)) * stars;
      final pt = _PerimeterPoint();
      while (_emit > 1.0) {
        _emit -= 1.0;
        _pointAt(shape, _phase + _rng.nextInt(stars) * spacing, pt);
        _spawnDust(pt.x, pt.y, pt.nx, pt.ny, _motion);
      }
    }

    for (int i = _dust.length - 1; i >= 0; i--) {
      final m = _dust[i];
      m.age += dt;
      m.x += m.vx * dt;
      m.y += m.vy * dt;
      m.vx *= math.exp(-dt * 2.2);
      m.vy *= math.exp(-dt * 2.2);
      if (m.age >= m.life) _dust.removeAt(i);
    }

    for (int i = _pulses.length - 1; i >= 0; i--) {
      _pulses[i].age += dt;
      if (_pulses[i].age >= 0.65) _pulses.removeAt(i);
    }

    _paintTick.value++;
  }

  void _triggerPulse(Offset localPos) {
    if (!widget.clickPulse || _size.width < 2 || _size.height < 2) return;
    final t = math.max(0.5, widget.thickness);
    final origin = _project(_shapeFor(), localPos.dx - t / 2, localPos.dy - t / 2);
    _pulses.add(_StarPulse(origin));
    if (_pulses.length > 4) _pulses.removeAt(0);
    _flash = 1.0;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final disabled = widget.onPressed == null || widget.isLoading;

    final surfaceColor = widget.backgroundColor ??
        (isDark ? const Color(0xFF0C0C0F).withValues(alpha: 0.72) : Colors.white.withValues(alpha: 0.88));
    final textColor = widget.textColor ??
        (isDark ? const Color(0xFFFAFAFA) : const Color(0xFF18181B));
    final trackColor = widget.borderColor ??
        (isDark ? Colors.white.withValues(alpha: 0.12) : const Color.fromRGBO(24, 24, 27, 0.12));
    final starColor = widget.color ??
        (isDark ? Colors.white : const Color(0xFF18181B));
    final trailColor = widget.trailColor ?? starColor;

    return Opacity(
      opacity: disabled ? 0.52 : 1.0,
      child: MouseRegion(
        cursor: disabled ? SystemMouseCursors.forbidden : SystemMouseCursors.click,
        onEnter: (_) {
          _hovered = true;
          if (widget.hover == StarBorderHoverMode.lap && _lap < 0 && !disabled) {
            _lap = 0;
          }
        },
        onExit: (_) => _hovered = false,
        child: GestureDetector(
          onTapDown: disabled
              ? null
              : (d) {
                  setState(() => _pressed = true);
                  _triggerPulse(d.localPosition);
                },
          onTapUp: (_) => setState(() => _pressed = false),
          onTapCancel: () => setState(() => _pressed = false),
          onTap: disabled
              ? null
              : () {
                  HapticFeedback.lightImpact();
                  widget.onPressed?.call();
                },
          child: AnimatedScale(
            scale: _pressed ? 0.97 : 1.0,
            duration: const Duration(milliseconds: 120),
            curve: Curves.easeOutCubic,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                // Superficie glassmorphic + track del botón
                Container(
                  key: _boxKey,
                  padding: widget.padding,
                  decoration: BoxDecoration(
                    color: surfaceColor,
                    borderRadius: BorderRadius.circular(widget.radius),
                    border: Border.all(
                      color: trackColor,
                      width: widget.thickness,
                    ),
                  ),
                  child: DefaultTextStyle.merge(
                    style: TextStyle(
                      color: textColor,
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                    ),
                    child: IconTheme.merge(
                      data: IconThemeData(color: textColor, size: 17),
                      child: widget.child,
                    ),
                  ),
                ),

                // Lienzo de la estrella, estela, brillo, polvo y clickPulse
                if (_size.width >= 2 && _size.height >= 2)
                  Positioned.fill(
                    child: IgnorePointer(
                      child: CustomPaint(
                        painter: _StarBorderPainter(
                          repaint: _paintTick,
                          state: this,
                          isLight: !isDark,
                          starColor: starColor,
                          trailColor: trailColor,
                          thickness: widget.thickness,
                          radius: widget.radius,
                          glow: widget.glow,
                          sparkle: widget.sparkle,
                          stars: widget.stars.clamp(1, 6),
                          duration: math.max(0.3, widget.duration),
                          trailLength: widget.trailLength.clamp(0.0, 1.0),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _StarBorderPainter extends CustomPainter {
  final _StarBorderButtonState state;
  final bool isLight;
  final Color starColor;
  final Color trailColor;
  final double thickness;
  final double radius;
  final double glow;
  final bool sparkle;
  final int stars;
  final double duration;
  final double trailLength;

  const _StarBorderPainter({
    super.repaint,
    required this.state,
    required this.isLight,
    required this.starColor,
    required this.trailColor,
    required this.thickness,
    required this.radius,
    required this.glow,
    required this.sparkle,
    required this.stars,
    required this.duration,
    required this.trailLength,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final shape = state._shapeFor();
    final phase = state._phase;
    final motion = state._motion;
    final time = state._time;
    final reveal = state._reveal;
    final boost = state._boost;
    final flash = state._flash;
    final pulses = state._pulses;
    final dust = state._dust;
    final pointAt = state._pointAt;

    final effectiveGlow = boost > 0.001 ? math.min(1.5, glow + 0.4 * boost) : glow;
    final offset = thickness / 2;
    canvas.save();
    canvas.translate(offset, offset);

    final total = shape.total;
    final spacing = total / stars;
    final speed = motion.abs();
    final sign = motion >= 0 ? 1.0 : -1.0;
    final span = trailLength * duration;
    final length = math.min(speed * span, math.min(spacing * 0.92, total * 0.6));
    final intensity = reveal * (1.0 + 0.4 * boost + 0.6 * flash);

    final ring = flash * (isLight ? 0.18 : 0.32) +
        boost * reveal * (isLight ? 0.07 : 0.12);
    if (ring > 0.005) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(
            0,
            0,
            math.max(1.0, size.width - thickness),
            math.max(1.0, size.height - thickness),
          ),
          Radius.circular(math.max(0.0, shape.r)),
        ),
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = thickness + 2 * effectiveGlow
          ..color = starColor.withValues(alpha: ring.clamp(0.0, 1.0)),
      );
    }

    final pt = _PerimeterPoint();

    void drawTrail(double head, double len, double dirSign, double inten, {bool tip = true}) {
      if (len < 0.5 || inten <= 0) return;
      final steps = (len / 4).ceil().clamp(2, 24);
      pointAt(shape, head, pt);
      var px = pt.x;
      var py = pt.y;
      for (int i = 1; i <= steps; i++) {
        pointAt(shape, head - dirSign * len * (i / steps), pt);
        final u = 1.0 - (i - 0.5) / steps;
        final fade = (u * u * inten).clamp(0.0, 1.0);
        var tone = Color.lerp(trailColor, starColor, u)!;
        if (!isLight) {
          tone = Color.lerp(tone, Colors.white, math.pow(u, 6).toDouble() * 0.65)!;
        }
        final cap = (tip && i == 1) ? StrokeCap.round : StrokeCap.butt;
        canvas.drawLine(
          Offset(px, py),
          Offset(pt.x, pt.y),
          Paint()
            ..strokeCap = cap
            ..strokeWidth = 2.0 + 6.0 * effectiveGlow
            ..color = tone.withValues(
              alpha: (fade * (isLight ? 0.10 : 0.22) * effectiveGlow).clamp(0.0, 1.0),
            ),
        );
        canvas.drawLine(
          Offset(px, py),
          Offset(pt.x, pt.y),
          Paint()
            ..strokeCap = cap
            ..strokeWidth = thickness
            ..color = tone.withValues(alpha: fade),
        );
        px = pt.x;
        py = pt.y;
      }
    }

    void drawHead(double x, double y, double inten, double twinkle) {
      if (inten <= 0) return;
      final reach = (12.0 + 34.0 * effectiveGlow) * (isLight ? 0.6 : 1.0);
      final strength = ((isLight ? 0.10 : 0.42) * effectiveGlow * inten).clamp(0.0, 1.0);
      final bloomPaint = Paint()
        ..shader = ui.Gradient.radial(
          Offset(x, y),
          reach,
          [
            starColor.withValues(alpha: strength),
            starColor.withValues(alpha: strength * 0.4),
            starColor.withValues(alpha: strength * 0.1),
            starColor.withValues(alpha: 0.0),
          ],
          const [0.0, 0.2, 0.5, 1.0],
        );
      canvas.drawCircle(Offset(x, y), reach, bloomPaint);

      if (!sparkle) return;

      final sz = (1.0 + thickness * 0.6) * (isLight ? 0.85 : 1.0);
      final centerCol = isLight ? starColor : Colors.white;
      canvas.drawCircle(
        Offset(x, y),
        sz * 2.2,
        Paint()
          ..shader = ui.Gradient.radial(
            Offset(x, y),
            sz * 2.2,
            [
              centerCol.withValues(alpha: inten.clamp(0.0, 1.0)),
              Color.lerp(starColor, centerCol, 0.5)!.withValues(alpha: (inten * 0.9).clamp(0.0, 1.0)),
              starColor.withValues(alpha: 0.0),
            ],
            const [0.0, 0.4, 1.0],
          ),
      );

      final spike = (3.0 + 4.0 * effectiveGlow + thickness * 1.5) * twinkle;
      final lineW = isLight ? 0.8 : 1.05;
      canvas.drawLine(
        Offset(x - spike, y),
        Offset(x + spike, y),
        Paint()
          ..strokeWidth = lineW
          ..shader = ui.Gradient.linear(
            Offset(x - spike, y),
            Offset(x + spike, y),
            [
              starColor.withValues(alpha: 0.0),
              centerCol.withValues(alpha: (inten * 0.95).clamp(0.0, 1.0)),
              starColor.withValues(alpha: 0.0),
            ],
            const [0.0, 0.5, 1.0],
          ),
      );
      canvas.drawLine(
        Offset(x, y - spike),
        Offset(x, y + spike),
        Paint()
          ..strokeWidth = lineW
          ..shader = ui.Gradient.linear(
            Offset(x, y - spike),
            Offset(x, y + spike),
            [
              starColor.withValues(alpha: 0.0),
              centerCol.withValues(alpha: (inten * 0.95).clamp(0.0, 1.0)),
              starColor.withValues(alpha: 0.0),
            ],
            const [0.0, 0.5, 1.0],
          ),
      );
    }

    final still = (1.0 - speed / math.max(1.0, (total / duration) * 0.6)).clamp(0.0, 1.0) *
        math.min(1.0, intensity);
    final rest = (10.0 + 14.0 * effectiveGlow + thickness * 2.0) * still;

    for (int i = 0; i < stars; i++) {
      final head = phase + i * spacing;
      drawTrail(head, length, sign, math.min(1.0, intensity));
      if (still > 0.01) {
        drawTrail(head, rest, 1.0, still, tip: false);
        drawTrail(head, rest, -1.0, still, tip: false);
      }
    }

    for (final p in pulses) {
      final progress = p.age / 0.65;
      final fade = math.pow(1.0 - progress, 2).toDouble();
      final travel = (total / 2) * (1.0 - math.pow(1.0 - math.min(1.0, p.age / 0.5), 2).toDouble());
      final tail = math.min(travel, total * 0.16);
      for (final way in const [1.0, -1.0]) {
        final front = p.origin + way * travel;
        drawTrail(front, tail, way, fade);
        pointAt(shape, front, pt);
        drawHead(pt.x, pt.y, fade * 0.8, 0.8);
      }
    }

    for (int i = 0; i < stars; i++) {
      pointAt(shape, phase + i * spacing, pt);
      final twinkle = 0.82 +
          0.18 * math.sin(time * 6.1 + i * 2.3) * math.sin(time * 2.7 + i);
      drawHead(pt.x, pt.y, math.min(1.3, intensity), twinkle);
    }

    for (final m in dust) {
      final left = 1.0 - m.age / m.life;
      final shimmer = 0.45 + 0.55 * math.sin(time * 20.0 + m.seed);
      final alpha = (left * shimmer * reveal * (isLight ? 0.35 : 0.9)).clamp(0.0, 1.0);
      if (alpha <= 0.01) continue;
      final col = isLight ? starColor : Color.lerp(trailColor, Colors.white, 0.6)!;
      canvas.drawCircle(
        Offset(m.x, m.y),
        m.size * (0.6 + 0.4 * left),
        Paint()..color = col.withValues(alpha: alpha),
      );
    }

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _StarBorderPainter oldDelegate) =>
      oldDelegate.isLight != isLight ||
      oldDelegate.starColor != starColor ||
      oldDelegate.trailColor != trailColor ||
      oldDelegate.thickness != thickness ||
      oldDelegate.radius != radius ||
      oldDelegate.glow != glow ||
      oldDelegate.sparkle != sparkle ||
      oldDelegate.stars != stars ||
      oldDelegate.duration != duration ||
      oldDelegate.trailLength != trailLength;
}
