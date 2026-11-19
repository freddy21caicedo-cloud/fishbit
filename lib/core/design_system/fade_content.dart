import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Variantes visuales soportadas por [FadeContent] (adaptación de React Bits).
enum FadeContentEffect {
  /// Aparición desde neblina: opacidad + desenfoque decreciente + flotación y micro-escala.
  mist,

  /// Aparición suave por opacidad y desplazamiento ligero sin desenfoque.
  fade,
}

/// Detecta Web móvil / PWA (Android o iOS en navegador) donde animar
/// [ImageFilter.blur] sobre tarjetas con [BackdropFilter] puede producir
/// artefactos o parpadeo en motores WebGL móviles.
bool _isMobileWebRuntime() {
  if (!kIsWeb) return false;
  return defaultTargetPlatform == TargetPlatform.android ||
      defaultTargetPlatform == TargetPlatform.iOS;
}

/// Adaptación nativa en Flutter de `<FadeContent effect="mist" ease="power2.out" />`.
///
/// Características:
/// - Curva por defecto [Curves.easeOutQuad] (equivalente a GSAP `power2.out`).
/// - Desmonta automáticamente [ImageFiltered] cuando `sigma < 0.08` para
///   garantizar cero sobrecosto GPU en reposo.
/// - En Web móvil / PWA omite el blur animado a pantalla completa para mantener
///   fluidez constante y cero parpadeo sobre superficies glassmorphism.
/// - Respeta `MediaQuery.disableAnimationsOf(context)`.
class FadeContent extends StatefulWidget {
  final Widget child;
  final FadeContentEffect effect;
  final Duration duration;
  final Duration delay;
  final Curve curve;
  final double blurSigma;
  final double offsetY;
  final double scaleBegin;
  final bool enableBlurOnMobileWeb;

  const FadeContent({
    super.key,
    required this.child,
    this.effect = FadeContentEffect.mist,
    this.duration = const Duration(milliseconds: 650),
    this.delay = Duration.zero,
    this.curve = Curves.easeOutQuad,
    this.blurSigma = 8.0,
    this.offsetY = 14.0,
    this.scaleBegin = 0.985,
    this.enableBlurOnMobileWeb = false,
  });

  @override
  State<FadeContent> createState() => _FadeContentState();
}

class _FadeContentState extends State<FadeContent>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late Animation<double> _curved;
  bool _started = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.duration,
    );
    _curved = CurvedAnimation(
      parent: _controller,
      curve: widget.curve,
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;

    if (MediaQuery.disableAnimationsOf(context)) {
      _controller.value = 1.0;
      return;
    }

    if (widget.delay == Duration.zero) {
      _controller.forward();
    } else {
      Future<void>.delayed(widget.delay, () {
        if (mounted) {
          _controller.forward();
        }
      });
    }
  }

  @override
  void didUpdateWidget(covariant FadeContent oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.duration != widget.duration) {
      _controller.duration = widget.duration;
    }
    if (oldWidget.curve != widget.curve) {
      _curved = CurvedAnimation(
        parent: _controller,
        curve: widget.curve,
      );
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final allowBlur = widget.effect == FadeContentEffect.mist &&
        widget.blurSigma > 0 &&
        (widget.enableBlurOnMobileWeb || !_isMobileWebRuntime());

    return AnimatedBuilder(
      animation: _curved,
      child: widget.child,
      builder: (context, child) {
        final t = _curved.value.clamp(0.0, 1.0);
        if (t >= 0.999) {
          return child!;
        }

        final inv = 1.0 - t;
        final dy = widget.offsetY * inv;
        final scale = widget.scaleBegin + (1.0 - widget.scaleBegin) * t;
        final sigma = allowBlur ? widget.blurSigma * inv : 0.0;

        Widget result = child!;
        if (sigma >= 0.08) {
          result = ImageFiltered(
            imageFilter: ImageFilter.blur(
              sigmaX: sigma,
              sigmaY: sigma,
              tileMode: TileMode.decal,
            ),
            child: result,
          );
        }

        return Opacity(
          opacity: t,
          child: Transform.translate(
            offset: Offset(0, dy),
            child: Transform.scale(
              scale: scale,
              alignment: Alignment.topCenter,
              child: result,
            ),
          ),
        );
      },
    );
  }
}

/// Revela una lista vertical de secciones en cascada (`stagger` por defecto: 95 ms ≈ 0.1s),
/// replicando `<FadeContent effect="mist" stagger={0.1}>...</FadeContent>`.
class FadeContentStagger extends StatelessWidget {
  final List<Widget> children;
  final FadeContentEffect effect;
  final Duration duration;
  final Duration stagger;
  final Duration initialDelay;
  final Curve curve;
  final double blurSigma;
  final double offsetY;
  final double scaleBegin;
  final double spacing;
  final CrossAxisAlignment crossAxisAlignment;
  final MainAxisSize mainAxisSize;

  const FadeContentStagger({
    super.key,
    required this.children,
    this.effect = FadeContentEffect.mist,
    this.duration = const Duration(milliseconds: 650),
    this.stagger = const Duration(milliseconds: 95),
    this.initialDelay = Duration.zero,
    this.curve = Curves.easeOutQuad,
    this.blurSigma = 7.0,
    this.offsetY = 14.0,
    this.scaleBegin = 0.988,
    this.spacing = 0.0,
    this.crossAxisAlignment = CrossAxisAlignment.start,
    this.mainAxisSize = MainAxisSize.min,
  });

  @override
  Widget build(BuildContext context) {
    final staggered = <Widget>[];
    for (var i = 0; i < children.length; i++) {
      if (i > 0 && spacing > 0) {
        staggered.add(SizedBox(height: spacing));
      }
      staggered.add(
        FadeContent(
          effect: effect,
          duration: duration,
          delay: initialDelay + stagger * i,
          curve: curve,
          blurSigma: blurSigma,
          offsetY: offsetY,
          scaleBegin: scaleBegin,
          child: children[i],
        ),
      );
    }

    return Column(
      crossAxisAlignment: crossAxisAlignment,
      mainAxisSize: mainAxisSize,
      children: staggered,
    );
  }
}

/// Construye un [CustomTransitionPage] con entrada `mist` (`power2.out`) y salida
/// limpia y rápida para evitar solapamientos sobre fondos transparentes
/// (`GradientWavesBackground`) dentro de [ShellRoute].
CustomTransitionPage<T> buildMistTransitionPage<T>({
  required LocalKey key,
  required Widget child,
  Duration transitionDuration = const Duration(milliseconds: 520),
  Duration reverseTransitionDuration = const Duration(milliseconds: 190),
  double blurSigma = 8.5,
  double offsetY = 14.0,
  double scaleBegin = 0.986,
}) {
  return CustomTransitionPage<T>(
    key: key,
    child: child,
    transitionDuration: transitionDuration,
    reverseTransitionDuration: reverseTransitionDuration,
    transitionsBuilder: (context, animation, secondaryAnimation, pageChild) {
      if (MediaQuery.disableAnimationsOf(context)) {
        return pageChild;
      }

      final allowBlur = blurSigma > 0 && !_isMobileWebRuntime();
      final enterCurve = CurvedAnimation(
        parent: animation,
        curve: const Interval(0.06, 1.0, curve: Curves.easeOutQuad),
        reverseCurve: Curves.easeOutQuad,
      );

      return AnimatedBuilder(
        animation: enterCurve,
        child: pageChild,
        builder: (context, content) {
          final t = enterCurve.value.clamp(0.0, 1.0);
          if (t >= 0.999) {
            return content!;
          }

          final isReversing = animation.status == AnimationStatus.reverse;
          final inv = 1.0 - t;
          // Salida corta hacia arriba; entrada suave desde abajo saliendo de la neblina
          final dy = isReversing ? (-6.0 * inv) : (offsetY * inv);
          final scale = isReversing
              ? (1.0 - 0.008 * inv)
              : (scaleBegin + (1.0 - scaleBegin) * t);
          final sigma = allowBlur
              ? (isReversing ? (blurSigma * 0.45 * inv) : (blurSigma * inv))
              : 0.0;

          Widget result = content!;
          if (sigma >= 0.08) {
            result = ImageFiltered(
              imageFilter: ImageFilter.blur(
                sigmaX: sigma,
                sigmaY: sigma,
                tileMode: TileMode.decal,
              ),
              child: result,
            );
          }

          return Opacity(
            opacity: t,
            child: Transform.translate(
              offset: Offset(0, dy),
              child: Transform.scale(
                scale: scale,
                alignment: Alignment.topCenter,
                child: result,
              ),
            ),
          );
        },
      );
    },
  );
}
