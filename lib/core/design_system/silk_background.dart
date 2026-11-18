import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

class _SilkWave {
  final double x;
  final double y;
  double age = 0;

  _SilkWave({required this.x, required this.y});
}

/// Fondo animado `<Silk />` (React Bits) implementado con Fragment Shader GLSL nativo.
class SilkBackground extends StatefulWidget {
  final Color color;
  final Color sheenColor;
  final double speed;
  final double scale;
  final double rotation;
  final double sheen;
  final double depth;
  final double glow;
  final double noiseIntensity;
  final double ripple;
  final double wave;
  final double variation;
  final bool mouseInteraction;
  final double interactionStrength;
  final bool clickRipple;
  final bool intro;
  final double fade;
  final bool lightMode;
  final bool paused;

  const SilkBackground({
    super.key,
    this.color = const Color(0xFF06B6D4),
    this.sheenColor = const Color(0xFFF43F5E),
    this.speed = 5.0,
    this.scale = 1.0,
    this.rotation = 0.0,
    this.sheen = 0.5,
    this.depth = 0.5,
    this.glow = 0.3,
    this.noiseIntensity = 1.5,
    this.ripple = 1.0,
    this.wave = 1.0,
    this.variation = 0.0,
    this.mouseInteraction = true,
    this.interactionStrength = 1.0,
    this.clickRipple = true,
    this.intro = true,
    this.fade = 0.0,
    this.lightMode = false,
    this.paused = false,
  });

  @override
  State<SilkBackground> createState() => _SilkBackgroundState();
}

class _SilkBackgroundState extends State<SilkBackground>
    with SingleTickerProviderStateMixin {
  static Future<ui.FragmentProgram>? _programFuture;

  static const double _introSeconds = 2.2;
  static const double _introRush = 1.6;
  static const double _waveLife = 1.6;
  static const double _defaultLightX = -0.55;
  static const double _defaultLightY = 0.7;
  static final double _lightTilt = math.sqrt(
    _defaultLightX * _defaultLightX + _defaultLightY * _defaultLightY,
  );

  ui.FragmentProgram? _program;
  late Ticker _ticker;
  Duration _lastElapsed = Duration.zero;

  double _flow = 0.0;
  late double _intro;
  double _touch = 0.0;
  double _pointerX = 0.0;
  double _pointerY = 0.0;
  double _stateX = 0.0;
  double _stateY = 0.0;
  double _dragX = 0.0;
  double _dragY = 0.0;
  double _lightX = _defaultLightX;
  double _lightY = _defaultLightY;
  bool _pointerInside = false;
  Size _viewSize = const Size(1, 1);
  final List<_SilkWave> _waves = [];

  @override
  void initState() {
    super.initState();
    _intro = widget.intro ? 0.0 : 1.0;
    _ticker = createTicker(_onTick)..start();
    _loadProgram();
  }

  Future<void> _loadProgram() async {
    try {
      _programFuture ??= ui.FragmentProgram.fromAsset('shaders/silk.frag');
      final program = await _programFuture!;
      if (mounted) {
        setState(() => _program = program);
      }
    } catch (_) {
      // Fallback gradient remains visible if shader fails to load.
    }
  }

  @override
  void dispose() {
    _ticker.dispose();
    super.dispose();
  }

  double _ease(double t) => t * t * t * (t * (t * 6 - 15) + 10);

  (double, double) _variationShift(double variation) {
    if (variation == 0) return (0.0, 0.0);
    double wave(double k) {
      final v = math.sin(variation * 12.9898 + k * 78.233) * 43758.5453;
      return v - v.floorToDouble() - 0.5;
    }
    return (wave(1) * 6, wave(2) * 6);
  }

  void _onTick(Duration elapsed) {
    final dt = _lastElapsed == Duration.zero
        ? (1.0 / 60.0)
        : math.min(0.05, (elapsed - _lastElapsed).inMicroseconds / 1e6);
    _lastElapsed = elapsed;

    if (!widget.paused && widget.speed != 0) {
      _flow += dt * 0.1 * widget.speed;
    }

    if (!widget.intro) {
      _intro = 1.0;
    } else if (_intro < 1.0) {
      _intro = math.min(1.0, _intro + dt / _introSeconds);
    }

    final engaged = widget.mouseInteraction && _pointerInside;
    if (engaged && _touch < 0.01) {
      _stateX = _pointerX;
      _stateY = _pointerY;
    }
    final follow = 1.0 - math.exp(-dt * 10.0);
    final prevX = _stateX;
    final prevY = _stateY;
    _stateX += (_pointerX - _stateX) * follow;
    _stateY += (_pointerY - _stateY) * follow;

    final vh = math.max(_viewSize.height, 1.0);
    final velX = (_stateX - prevX) / math.max(dt, 0.001) / vh;
    final velY = (_stateY - prevY) / math.max(dt, 0.001) / vh;
    final dragBlend = 1.0 - math.exp(-dt * 4.0);
    _dragX += ((velX * 0.03).clamp(-0.06, 0.06) - _dragX) * dragBlend;
    _dragY += ((-velY * 0.03).clamp(-0.06, 0.06) - _dragY) * dragBlend;
    _touch += ((engaged ? 1.0 : 0.0) - _touch) *
        (1.0 - math.exp(-dt * (engaged ? 3.5 : 1.4)));

    double lightGoalX = _defaultLightX;
    double lightGoalY = _defaultLightY;
    if (engaged) {
      final aimX =
          (_pointerX / math.max(_viewSize.width, 1.0) - 0.5) * (_viewSize.width / vh);
      final aimY = 0.5 - _pointerY / vh;
      final reach = math.sqrt(aimX * aimX + aimY * aimY);
      if (reach > 0.04) {
        lightGoalX = (aimX / reach) * _lightTilt;
        lightGoalY = (aimY / reach) * _lightTilt;
      } else {
        lightGoalX = _lightX;
        lightGoalY = _lightY;
      }
    }
    final lightFollow = 1.0 - math.exp(-dt * 3.0);
    _lightX += (lightGoalX - _lightX) * lightFollow;
    _lightY += (lightGoalY - _lightY) * lightFollow;

    for (int i = _waves.length - 1; i >= 0; i--) {
      _waves[i].age += dt;
      if (_waves[i].age > _waveLife * 2.5) {
        _waves.removeAt(i);
      }
    }

    if (mounted) setState(() {});
  }

  void _updatePointer(Offset localPos, bool inside) {
    _pointerX = localPos.dx;
    _pointerY = localPos.dy;
    _pointerInside = inside;
  }

  void _spawnRipple(Offset localPos) {
    if (!widget.clickRipple) return;
    final w = math.max(_viewSize.width, 1.0);
    final h = math.max(_viewSize.height, 1.0);
    _waves.add(_SilkWave(x: localPos.dx / w, y: 1.0 - localPos.dy / h));
    if (_waves.length > 4) _waves.removeAt(0);
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        _viewSize = Size(
          constraints.maxWidth.isFinite ? constraints.maxWidth : 1.0,
          constraints.maxHeight.isFinite ? constraints.maxHeight : 1.0,
        );

        final unfold = _ease(_intro);
        final presence = 1.0 - math.pow(1.0 - _intro, 3).toDouble();
        final (shiftX, shiftY) = _variationShift(widget.variation);

        return MouseRegion(
          onHover: (e) => _updatePointer(e.localPosition, true),
          onExit: (_) => _pointerInside = false,
          child: Listener(
            behavior: HitTestBehavior.translucent,
            onPointerDown: (e) {
              _updatePointer(e.localPosition, true);
              _spawnRipple(e.localPosition);
            },
            onPointerMove: (e) => _updatePointer(e.localPosition, true),
            onPointerUp: (_) => _pointerInside = false,
            onPointerCancel: (_) => _pointerInside = false,
            child: _program == null
                ? DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: RadialGradient(
                        center: const Alignment(-0.4, -0.3),
                        radius: 1.2,
                        colors: [
                          widget.color.withValues(alpha: 0.28),
                          widget.sheenColor.withValues(alpha: 0.14),
                          const Color(0xFF0A0F1A),
                        ],
                      ),
                    ),
                    child: const SizedBox.expand(),
                  )
                : CustomPaint(
                    size: Size.infinite,
                    painter: _SilkShaderPainter(
                      program: _program!,
                      color: widget.color,
                      sheenColor: widget.sheenColor,
                      scale: widget.scale,
                      rotation: widget.rotation,
                      time: _flow - _introRush * (1.0 - unfold),
                      wave: math.max(0.0, widget.wave),
                      ripple: math.max(0.0, widget.ripple),
                      fold: 0.25 + 0.75 * unfold,
                      shiftX: shiftX,
                      shiftY: shiftY,
                      pointerX: _stateX / math.max(_viewSize.width, 1.0),
                      pointerY: 1.0 - _stateY / math.max(_viewSize.height, 1.0),
                      pointerTouch: _touch * math.max(0.0, widget.interactionStrength),
                      dragX: _dragX,
                      dragY: _dragY,
                      waves: _waves,
                      waveLife: _waveLife,
                      noiseIntensity: math.max(0.0, widget.noiseIntensity),
                      depth: widget.depth.clamp(0.0, 1.0),
                      sheen: math.max(0.0, widget.sheen),
                      glow: math.max(0.0, widget.glow),
                      lightMode: widget.lightMode,
                      lightX: _lightX,
                      lightY: _lightY,
                      presence: presence,
                      fade: widget.fade.clamp(0.0, 1.0),
                    ),
                  ),
          ),
        );
      },
    );
  }
}

class _SilkShaderPainter extends CustomPainter {
  final ui.FragmentProgram program;
  final Color color;
  final Color sheenColor;
  final double scale;
  final double rotation;
  final double time;
  final double wave;
  final double ripple;
  final double fold;
  final double shiftX;
  final double shiftY;
  final double pointerX;
  final double pointerY;
  final double pointerTouch;
  final double dragX;
  final double dragY;
  final List<_SilkWave> waves;
  final double waveLife;
  final double noiseIntensity;
  final double depth;
  final double sheen;
  final double glow;
  final bool lightMode;
  final double lightX;
  final double lightY;
  final double presence;
  final double fade;

  const _SilkShaderPainter({
    required this.program,
    required this.color,
    required this.sheenColor,
    required this.scale,
    required this.rotation,
    required this.time,
    required this.wave,
    required this.ripple,
    required this.fold,
    required this.shiftX,
    required this.shiftY,
    required this.pointerX,
    required this.pointerY,
    required this.pointerTouch,
    required this.dragX,
    required this.dragY,
    required this.waves,
    required this.waveLife,
    required this.noiseIntensity,
    required this.depth,
    required this.sheen,
    required this.glow,
    required this.lightMode,
    required this.lightX,
    required this.lightY,
    required this.presence,
    required this.fade,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final shader = program.fragmentShader();
    int i = 0;

    // uView (0..1)
    shader.setFloat(i++, size.width);
    shader.setFloat(i++, size.height);
    // uScale (2), uRotation (3), uTime (4), uWave (5), uRipple (6), uFold (7)
    shader.setFloat(i++, scale);
    shader.setFloat(i++, rotation);
    shader.setFloat(i++, time);
    shader.setFloat(i++, wave);
    shader.setFloat(i++, ripple);
    shader.setFloat(i++, fold);
    // uShift (8..9)
    shader.setFloat(i++, shiftX);
    shader.setFloat(i++, shiftY);
    // uPointer (10..13)
    shader.setFloat(i++, pointerX);
    shader.setFloat(i++, pointerY);
    shader.setFloat(i++, pointerTouch);
    shader.setFloat(i++, 0.32);
    // uDrag (14..15)
    shader.setFloat(i++, dragX);
    shader.setFloat(i++, dragY);

    // uWave0..uWave3 (16..31)
    for (int w = 0; w < 4; w++) {
      if (w < waves.length) {
        final item = waves[w];
        shader.setFloat(i++, item.x);
        shader.setFloat(i++, item.y);
        shader.setFloat(i++, item.age * 0.6);
        shader.setFloat(i++, math.exp(-item.age / (waveLife * 0.45)));
      } else {
        shader.setFloat(i++, 0.0);
        shader.setFloat(i++, 0.0);
        shader.setFloat(i++, 0.0);
        shader.setFloat(i++, 0.0);
      }
    }

    // uColor (32..34)
    shader.setFloat(i++, color.r);
    shader.setFloat(i++, color.g);
    shader.setFloat(i++, color.b);
    // uSheenColor (35..37)
    shader.setFloat(i++, sheenColor.r);
    shader.setFloat(i++, sheenColor.g);
    shader.setFloat(i++, sheenColor.b);
    // uNoiseIntensity (38), uDepth (39), uSheen (40), uGlow (41), uLightMode (42)
    shader.setFloat(i++, noiseIntensity);
    shader.setFloat(i++, depth);
    shader.setFloat(i++, sheen);
    shader.setFloat(i++, glow);
    shader.setFloat(i++, lightMode ? 1.0 : 0.0);
    // uLight (43..45)
    shader.setFloat(i++, lightX);
    shader.setFloat(i++, lightY);
    shader.setFloat(i++, pointerTouch);
    // uStep (46..47)
    shader.setFloat(i++, 1.0 / math.max(size.width, 1.0));
    shader.setFloat(i++, 1.0 / math.max(size.height, 1.0));
    // uPresence (48), uFade (49)
    shader.setFloat(i++, presence);
    shader.setFloat(i++, fade);

    canvas.drawRect(
      Offset.zero & size,
      Paint()..shader = shader,
    );
  }

  @override
  bool shouldRepaint(covariant _SilkShaderPainter oldDelegate) => true;
}
