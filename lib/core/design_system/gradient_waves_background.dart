import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:fishbit_finance/core/design_system/ambient_clock.dart';
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

class _WaveAnimState extends ChangeNotifier {
  double time = 0.0;
  Offset smoothedPointer = const Offset(0.5, 0.5);
  Offset clickOrigin = const Offset(0.5, 0.5);
  double clickRadius = 0.0;
  double clickStrength = 0.0;

  void advance({
    required double dt,
    required double speed,
    required bool mouseInteraction,
    required bool swellOnClick,
    GradientWavesController? controller,
  }) {
    time += dt * speed;
    if (controller != null) {
      if (mouseInteraction) {
        final k = 1.0 - math.exp(-dt * 5.0);
        smoothedPointer =
            Offset.lerp(smoothedPointer, controller._pointerNorm, k)!;
      }
      if (swellOnClick && controller._clickStrength > 0.001) {
        controller._clickRadius += dt * 0.65;
        controller._clickStrength =
            math.max(0.0, controller._clickStrength - dt * 0.9);
      }
      clickOrigin = controller._clickOriginNorm;
      clickRadius = controller._clickRadius;
      clickStrength = swellOnClick ? controller._clickStrength : 0.0;
    }
    notifyListeners();
  }
}

/// Fondo animado `<GradientWaves />` (React Bits).
/// - Cero `setState()` por frame (usa `repaint: Listenable` para evitar parpadeos).
/// - En PWA móvil (`kIsWeb` sobre Android/iOS) usa renderizado Skia 2D nativo
///   para eliminar al 100% el parpadeo de *framebuffer readback* entre WebGL
///   `RuntimeEffect` y `BackdropFilter`.
/// - En escritorio y móvil nativo reutiliza una única instancia de `FragmentShader`.
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
    this.horizonColor = const Color(0xFF4C142B),
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
  State<GradientWavesBackground> createState() =>
      _GradientWavesBackgroundState();
}

class _GradientWavesBackgroundState extends State<GradientWavesBackground>
    with WidgetsBindingObserver {
  static Future<ui.FragmentProgram>? _programFuture;

  /// El fondo es decorativo y de movimiento lento: se alimenta del
  /// [AmbientClock] compartido (~30 FPS) en lugar de un `Ticker` a 60 Hz.
  /// Esto reduce a la mitad el trabajo de GPU (shader a pantalla completa +
  /// recomposición de todos los BackdropFilter que hay encima: header, barra
  /// de navegación y modales).
  ui.FragmentShader? _cachedShader;
  bool _clockSubscribed = false;
  final _WaveAnimState _animState = _WaveAnimState();
  Duration _lastElapsed = Duration.zero;
  bool _appResumed = true;
  bool _tickerModeEnabled = true;
  bool _reduceMotion = false;

  bool get _useMobilePwaCanvasRenderer =>
      kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.android ||
          defaultTargetPlatform == TargetPlatform.iOS);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    if (!_useMobilePwaCanvasRenderer) {
      _loadShader();
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Pausar cuando la ruta queda oculta (TickerMode) o cuando el sistema
    // solicita reducir animaciones (accesibilidad / ahorro de batería).
    _tickerModeEnabled = TickerMode.of(context);
    _reduceMotion = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    _syncTickerState();
  }

  Future<void> _loadShader() async {
    try {
      _programFuture ??=
          ui.FragmentProgram.fromAsset('shaders/gradient_waves.frag');
      final program = await _programFuture!;
      if (!mounted) return;
      final shader = program.fragmentShader();
      setState(() {
        _cachedShader?.dispose();
        _cachedShader = shader;
      });
    } catch (_) {
      // Fallback al renderizador 2D si el entorno no soporta FragmentShader
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
    final shouldRun = !widget.paused &&
        _appResumed &&
        _tickerModeEnabled &&
        !_reduceMotion;
    if (shouldRun && !_clockSubscribed) {
      _lastElapsed = Duration.zero;
      AmbientClock.instance.subscribe(_onTick);
      _clockSubscribed = true;
    } else if (!shouldRun && _clockSubscribed) {
      AmbientClock.instance.unsubscribe(_onTick);
      _clockSubscribed = false;
    }
  }

  void _onTick(Duration elapsed) {
    if (!mounted) return;
    final rawDt = (elapsed - _lastElapsed).inMicroseconds / 1e6;
    final dt = _lastElapsed == Duration.zero || rawDt <= 0
        ? (1.0 / 30.0)
        : math.min(0.05, rawDt);
    _lastElapsed = elapsed;

    // Sin setState: solo notifica al CustomPainter a través del Listenable
    _animState.advance(
      dt: dt,
      speed: widget.speed,
      mouseInteraction: widget.mouseInteraction,
      swellOnClick: widget.swellOnClick,
      controller: widget.controller,
    );
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    if (_clockSubscribed) {
      AmbientClock.instance.unsubscribe(_onTick);
      _clockSubscribed = false;
    }
    _cachedShader?.dispose();
    _animState.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final baseBg = isDark ? AppColors.backgroundDark : AppColors.backgroundLight;
    final useShader = !_useMobilePwaCanvasRenderer && _cachedShader != null;

    return RepaintBoundary(
      child: Stack(
        fit: StackFit.expand,
        children: [
          ColoredBox(color: baseBg),
          if (useShader)
            CustomPaint(
              painter: _GradientWavesShaderPainter(
                shader: _cachedShader!,
                animState: _animState,
                horizonColor: widget.horizonColor,
                waveColor: widget.waveColor,
                crestColor: widget.crestColor,
                amplitude: widget.amplitude,
                relief: widget.relief,
                lightAngleDeg: widget.lightAngle,
                waveScale: widget.waveScale,
                swell: widget.swell,
                turbulence: widget.turbulence,
                mouseInteraction: widget.mouseInteraction,
                opacity: widget.opacity,
              ),
            )
          else
            CustomPaint(
              painter: _SmoothRibbonWavesPainter(
                animState: _animState,
                horizonColor: widget.horizonColor,
                waveColor: widget.waveColor,
                crestColor: widget.crestColor,
                amplitude: widget.amplitude,
                waveScale: widget.waveScale,
                mouseInteraction: widget.mouseInteraction,
                opacity: widget.opacity,
                isDark: isDark,
              ),
            ),
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

class _GradientWavesShaderPainter extends CustomPainter {
  final ui.FragmentShader shader;
  final _WaveAnimState animState;
  final Color horizonColor;
  final Color waveColor;
  final Color crestColor;
  final double amplitude;
  final double relief;
  final double lightAngleDeg;
  final double waveScale;
  final double swell;
  final double turbulence;
  final bool mouseInteraction;
  final double opacity;

  _GradientWavesShaderPainter({
    required this.shader,
    required this.animState,
    required this.horizonColor,
    required this.waveColor,
    required this.crestColor,
    required this.amplitude,
    required this.relief,
    required this.lightAngleDeg,
    required this.waveScale,
    required this.swell,
    required this.turbulence,
    required this.mouseInteraction,
    required this.opacity,
  }) : super(repaint: animState);

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) return;
    final rad = lightAngleDeg * math.pi / 180.0;
    final ptr =
        mouseInteraction ? animState.smoothedPointer : const Offset(0.5, 0.5);

    int i = 0;
    shader.setFloat(i++, size.width);
    shader.setFloat(i++, size.height);
    shader.setFloat(i++, animState.time);
    shader.setFloat(i++, horizonColor.r);
    shader.setFloat(i++, horizonColor.g);
    shader.setFloat(i++, horizonColor.b);
    shader.setFloat(i++, waveColor.r);
    shader.setFloat(i++, waveColor.g);
    shader.setFloat(i++, waveColor.b);
    shader.setFloat(i++, crestColor.r);
    shader.setFloat(i++, crestColor.g);
    shader.setFloat(i++, crestColor.b);
    shader.setFloat(i++, amplitude);
    shader.setFloat(i++, relief);
    shader.setFloat(i++, math.cos(rad));
    shader.setFloat(i++, math.sin(rad));
    shader.setFloat(i++, waveScale);
    shader.setFloat(i++, swell);
    shader.setFloat(i++, turbulence);
    shader.setFloat(i++, ptr.dx);
    shader.setFloat(i++, ptr.dy);
    shader.setFloat(i++, animState.clickOrigin.dx);
    shader.setFloat(i++, animState.clickOrigin.dy);
    shader.setFloat(i++, animState.clickRadius);
    shader.setFloat(i++, animState.clickStrength);
    shader.setFloat(i++, opacity);

    canvas.drawRect(Offset.zero & size, Paint()..shader = shader);
  }

  @override
  bool shouldRepaint(covariant _GradientWavesShaderPainter oldDelegate) =>
      oldDelegate.shader != shader ||
      oldDelegate.horizonColor != horizonColor ||
      oldDelegate.waveColor != waveColor ||
      oldDelegate.crestColor != crestColor ||
      oldDelegate.opacity != opacity;
}

/// Renderizador Skia 2D sin parpadeo para PWA móvil (Android/iOS Web).
/// Dibuja horizonte coral sutil + 5 capas de ondas oceánicas en perspectiva
/// con crestas luminosas y pulso interactivo al toque, sin cambios de contexto WebGL.
class _SmoothRibbonWavesPainter extends CustomPainter {
  final _WaveAnimState animState;
  final Color horizonColor;
  final Color waveColor;
  final Color crestColor;
  final double amplitude;
  final double waveScale;
  final bool mouseInteraction;
  final double opacity;
  final bool isDark;

  _SmoothRibbonWavesPainter({
    required this.animState,
    required this.horizonColor,
    required this.waveColor,
    required this.crestColor,
    required this.amplitude,
    required this.waveScale,
    required this.mouseInteraction,
    required this.opacity,
    required this.isDark,
  }) : super(repaint: animState);

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) return;
    final w = size.width;
    final h = size.height;
    final t = animState.time;
    final ptr =
        mouseInteraction ? animState.smoothedPointer : const Offset(0.5, 0.5);
    final px = (ptr.dx - 0.5) * 28.0;
    final py = (ptr.dy - 0.5) * 14.0;

    // 1. Horizonte superior con resplandor coral/oceánico suave
    final horizonRect = Offset.zero & size;
    canvas.drawRect(
      horizonRect,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          stops: const [0.0, 0.30, 0.65, 1.0],
          colors: [
            horizonColor.withValues(alpha: opacity * 0.72),
            Color.lerp(horizonColor, waveColor, 0.55)!
                .withValues(alpha: opacity * 0.45),
            waveColor.withValues(alpha: opacity * 0.32),
            waveColor.withValues(alpha: opacity * 0.14),
          ],
        ).createShader(horizonRect),
    );

    // 2. Capas de ondas en perspectiva (5 bandas fluidas)
    const int layers = 5;
    const int steps = 28;
    for (int l = 0; l < layers; l++) {
      final frac = l / (layers - 1);
      final baseY = h * (0.24 + frac * 0.58) + py * (0.4 + frac * 0.6);
      final layerAmp = (10.0 + frac * 18.0) * (amplitude / 1.6);
      final freq = (1.6 + (1.0 - frac) * 1.4) * waveScale;
      final phase = t * (0.85 + frac * 0.45) + l * 1.35 + px * 0.015;

      final path = Path()..moveTo(0, h);
      final crestPath = Path();

      for (int s = 0; s <= steps; s++) {
        final u = s / steps;
        final x = u * w;
        final wave1 = math.sin(u * math.pi * 2.0 * freq + phase);
        final wave2 =
            math.cos(u * math.pi * 3.2 * freq - phase * 0.72 + l) * 0.45;
        final y = baseY + (wave1 + wave2) * layerAmp;

        path.lineTo(x, y);
        if (s == 0) {
          crestPath.moveTo(x, y);
        } else {
          crestPath.lineTo(x, y);
        }
      }
      path
        ..lineTo(w, h)
        ..close();

      final layerColor = Color.lerp(
        horizonColor,
        waveColor,
        0.35 + frac * 0.65,
      )!;
      final layerAlpha = (opacity * (0.22 + frac * 0.24)).clamp(0.0, 0.55);

      canvas.drawPath(
        path,
        Paint()
          ..shader = LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              layerColor.withValues(alpha: layerAlpha),
              layerColor.withValues(alpha: layerAlpha * 0.15),
            ],
          ).createShader(Rect.fromLTWH(0, baseY - layerAmp, w, h - baseY + layerAmp)),
      );

      // Cresta luminosa sutil sobre cada ola
      canvas.drawPath(
        crestPath,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.2 + frac * 0.8
          ..color = crestColor.withValues(alpha: opacity * (0.20 + frac * 0.22)),
      );
    }

    // 3. Pulso expansivo suave al tocar (swellOnClick)
    if (animState.clickStrength > 0.01) {
      final center = Offset(
        animState.clickOrigin.dx * w,
        animState.clickOrigin.dy * h,
      );
      final maxR = math.max(w, h) * 0.55;
      final r = math.max(12.0, animState.clickRadius * maxR);
      canvas.drawCircle(
        center,
        r,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.0
          ..color = crestColor.withValues(
            alpha: (animState.clickStrength * opacity * 0.65).clamp(0.0, 0.45),
          ),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _SmoothRibbonWavesPainter oldDelegate) =>
      oldDelegate.horizonColor != horizonColor ||
      oldDelegate.waveColor != waveColor ||
      oldDelegate.crestColor != crestColor ||
      oldDelegate.opacity != opacity ||
      oldDelegate.isDark != isDark;
}
