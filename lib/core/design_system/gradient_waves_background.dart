import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:fishbit_finance/core/design_system/app_colors.dart';

/// Controlador ligero para alimentar `mouseInteraction` y `swellOnClick`
/// en [GradientWavesBackground] sin provocar rebuilds del árbol de widgets.
class GradientWavesController {
  Offset _pointerNorm = const Offset(0.5, 0.5);
  Offset _clickOriginNorm = const Offset(0.5, 0.5);
  double _clickStrength = 0.0;
  double _clickRadius = 0.0;

  void updatePointer(Offset localPos, Size size) {
    if (size.width <= 0 || size.height <= 0) return;
    _pointerNorm = Offset(
      (localPos.dx / size.width).clamp(0.0, 1.0),
      (localPos.dy / size.height).clamp(0.0, 1.0),
    );
  }

  void triggerSwell(Offset localPos, Size size) {
    if (size.width <= 0 || size.height <= 0) return;
    _clickOriginNorm = Offset(
      (localPos.dx / size.width).clamp(0.0, 1.0),
      (localPos.dy / size.height).clamp(0.0, 1.0),
    );
    _clickRadius = 0.0;
    _clickStrength = 1.0;
  }
}

/// Fondo animado `<GradientWaves />` (React Bits) implementado con Fragment Shader GLSL nativo.
/// Optimizado a ~30 FPS suaves con pausa automática en segundo plano y fallback estático para tests.
class GradientWavesBackground extends StatefulWidget {
  final Color horizonColor;
  final Color waveColor;
  final Color crestColor;
  final double speed;
  final double amplitude;
  final double relief;
  final double lightAngle;
  final bool mouseInteraction;
  final bool swellOnClick;
  final double waveScale;
  final double swell;
  final double turbulence;
  final double opacity;
  final bool paused;
  final GradientWavesController? controller;

  const GradientWavesBackground({
    super.key,
    this.horizonColor = const Color(0xFF4A152E),
    this.waveColor = AppColors.cyanWater,
    this.crestColor = const Color(0xFF67E8F9),
    this.speed = 0.45,
    this.amplitude = 1.6,
    this.relief = 1.0,
    this.lightAngle = 150.0,
    this.mouseInteraction = true,
    this.swellOnClick = true,
    this.waveScale = 0.9,
    this.swell = 24.0,
    this.turbulence = 26.0,
    this.opacity = 0.42,
    this.paused = false,
    this.controller,
  });

  @override
  State<GradientWavesBackground> createState() => _GradientWavesBackgroundState();
}

class _GradientWavesBackgroundState extends State<GradientWavesBackground>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  static Future<ui.FragmentProgram>? _programFuture;

  ui.FragmentProgram? _program;
  late final Ticker _ticker;
  Duration _lastElapsed = Duration.zero;
  double _accumulatedDt = 0.0;
  double _time = 0.0;
  Offset _smoothedPointer = const Offset(0.5, 0.5);
  bool _appResumed = true;

  // ~30 FPS cap: visualmente fluido para ondas lentas (speed ~0.45) reduciendo 50% carga GPU
  static const double _frameIntervalSec = 1.0 / 30.0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _ticker = createTicker(_onTick);
    if (!widget.paused) {
      _ticker.start();
    }
    _loadProgram();
  }

  Future<void> _loadProgram() async {
    try {
      _programFuture ??=
          ui.FragmentProgram.fromAsset('shaders/gradient_waves.frag');
      final program = await _programFuture!;
      if (mounted) {
        setState(() => _program = program);
      }
    } catch (_) {
      // Fallback gradient remains visible in environments without shader support
    }
  }

  @override
  void didUpdateWidget(covariant GradientWavesBackground oldWidget) {
    super.didUpdateWidget(oldWidget);
    _syncTickerState();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _appResumed = state == AppLifecycleState.resumed;
    _syncTickerState();
  }

  void _syncTickerState() {
    final shouldRun = !widget.paused && _appResumed;
    if (shouldRun && !_ticker.isActive) {
      _lastElapsed = Duration.zero;
      _ticker.start();
    } else if (!shouldRun && _ticker.isActive) {
      _ticker.stop();
    }
  }

  void _onTick(Duration elapsed) {
    final dt = _lastElapsed == Duration.zero
        ? _frameIntervalSec
        : math.min(0.08, (elapsed - _lastElapsed).inMicroseconds / 1e6);
    _lastElapsed = elapsed;
    _accumulatedDt += dt;
    if (_accumulatedDt < _frameIntervalSec) return;

    final step = _accumulatedDt;
    _accumulatedDt = 0.0;

    final ctrl = widget.controller;
    if (ctrl != null) {
      if (widget.mouseInteraction) {
        final k = 1.0 - math.exp(-step * 5.0);
        _smoothedPointer = Offset.lerp(_smoothedPointer, ctrl._pointerNorm, k)!;
      }
      if (widget.swellOnClick && ctrl._clickStrength > 0.001) {
        ctrl._clickRadius += step * 0.65;
        ctrl._clickStrength = math.max(0.0, ctrl._clickStrength - step * 0.9);
      }
    }

    if (mounted) {
      setState(() {
        _time += step * widget.speed;
      });
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _ticker.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final baseBg = isDark ? AppColors.backgroundDark : AppColors.backgroundLight;

    return RepaintBoundary(
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Base sólida del tema (garantiza contraste WCAG 2.2 AA en todo momento)
          ColoredBox(color: baseBg),

          // Capa de ondas shader o fallback suave
          if (_program != null)
            CustomPaint(
              painter: _GradientWavesPainter(
                program: _program!,
                time: _time,
                horizonColor: widget.horizonColor,
                waveColor: widget.waveColor,
                crestColor: widget.crestColor,
                amplitude: widget.amplitude,
                relief: widget.relief,
                lightAngleDeg: widget.lightAngle,
                waveScale: widget.waveScale,
                swell: widget.swell,
                turbulence: widget.turbulence,
                pointerNorm: widget.mouseInteraction
                    ? _smoothedPointer
                    : const Offset(0.5, 0.5),
                clickOriginNorm:
                    widget.controller?._clickOriginNorm ?? const Offset(0.5, 0.5),
                clickRadius: widget.controller?._clickRadius ?? 0.0,
                clickStrength: widget.swellOnClick
                    ? (widget.controller?._clickStrength ?? 0.0)
                    : 0.0,
                opacity: widget.opacity,
              ),
            )
          else
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    widget.horizonColor.withValues(alpha: widget.opacity * 0.55),
                    widget.waveColor.withValues(alpha: widget.opacity * 0.35),
                    baseBg,
                  ],
                ),
              ),
            ),

          // Scrim sutil superior e inferior para legibilidad perfecta de header y dock
          IgnorePointer(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  stops: const [0.0, 0.22, 0.78, 1.0],
                  colors: [
                    baseBg.withValues(alpha: isDark ? 0.55 : 0.42),
                    Colors.transparent,
                    Colors.transparent,
                    baseBg.withValues(alpha: isDark ? 0.65 : 0.50),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _GradientWavesPainter extends CustomPainter {
  final ui.FragmentProgram program;
  final double time;
  final Color horizonColor;
  final Color waveColor;
  final Color crestColor;
  final double amplitude;
  final double relief;
  final double lightAngleDeg;
  final double waveScale;
  final double swell;
  final double turbulence;
  final Offset pointerNorm;
  final Offset clickOriginNorm;
  final double clickRadius;
  final double clickStrength;
  final double opacity;

  const _GradientWavesPainter({
    required this.program,
    required this.time,
    required this.horizonColor,
    required this.waveColor,
    required this.crestColor,
    required this.amplitude,
    required this.relief,
    required this.lightAngleDeg,
    required this.waveScale,
    required this.swell,
    required this.turbulence,
    required this.pointerNorm,
    required this.clickOriginNorm,
    required this.clickRadius,
    required this.clickStrength,
    required this.opacity,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) return;
    final shader = program.fragmentShader();
    final rad = lightAngleDeg * math.pi / 180.0;

    int i = 0;
    // uView (vec2)
    shader.setFloat(i++, size.width);
    shader.setFloat(i++, size.height);
    // uTime (float)
    shader.setFloat(i++, time);
    // uHorizonColor (vec3)
    shader.setFloat(i++, horizonColor.r);
    shader.setFloat(i++, horizonColor.g);
    shader.setFloat(i++, horizonColor.b);
    // uWaveColor (vec3)
    shader.setFloat(i++, waveColor.r);
    shader.setFloat(i++, waveColor.g);
    shader.setFloat(i++, waveColor.b);
    // uCrestColor (vec3)
    shader.setFloat(i++, crestColor.r);
    shader.setFloat(i++, crestColor.g);
    shader.setFloat(i++, crestColor.b);
    // uAmplitude, uRelief
    shader.setFloat(i++, amplitude);
    shader.setFloat(i++, relief);
    // uLightDir (vec2)
    shader.setFloat(i++, math.cos(rad));
    shader.setFloat(i++, math.sin(rad));
    // uWaveScale, uSwell, uTurbulence
    shader.setFloat(i++, waveScale);
    shader.setFloat(i++, swell);
    shader.setFloat(i++, turbulence);
    // uPointer (vec2)
    shader.setFloat(i++, pointerNorm.dx);
    shader.setFloat(i++, pointerNorm.dy);
    // uClickWave (vec4)
    shader.setFloat(i++, clickOriginNorm.dx);
    shader.setFloat(i++, clickOriginNorm.dy);
    shader.setFloat(i++, clickRadius);
    shader.setFloat(i++, clickStrength);
    // uOpacity (float)
    shader.setFloat(i++, opacity);

    canvas.drawRect(Offset.zero & size, Paint()..shader = shader);
  }

  @override
  bool shouldRepaint(covariant _GradientWavesPainter oldDelegate) =>
      oldDelegate.time != time ||
      oldDelegate.horizonColor != horizonColor ||
      oldDelegate.waveColor != waveColor ||
      oldDelegate.crestColor != crestColor ||
      oldDelegate.pointerNorm != pointerNorm ||
      oldDelegate.clickStrength != clickStrength ||
      oldDelegate.opacity != opacity;
}
