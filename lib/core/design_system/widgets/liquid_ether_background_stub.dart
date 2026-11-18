import 'dart:math' as math;
import 'package:flutter/material.dart';

/// Implementación nativa de respaldo para plataformas móviles y de escritorio
/// que simula un flujo líquido suave con los mismos colores de LiquidEther.
Widget buildLiquidEtherBackground({
  required List<String> colors,
  required double mouseForce,
  required double cursorSize,
  required double persistence,
  required bool autoDemo,
  required double autoSpeed,
  required double autoIntensity,
  required String backgroundColor,
}) {
  return _NativeLiquidEtherFallback(
    colors: colors,
    autoSpeed: autoSpeed,
    backgroundColor: backgroundColor,
  );
}

class _NativeLiquidEtherFallback extends StatefulWidget {
  final List<String> colors;
  final double autoSpeed;
  final String backgroundColor;

  const _NativeLiquidEtherFallback({
    required this.colors,
    required this.autoSpeed,
    required this.backgroundColor,
  });

  @override
  State<_NativeLiquidEtherFallback> createState() =>
      _NativeLiquidEtherFallbackState();
}

class _NativeLiquidEtherFallbackState extends State<_NativeLiquidEtherFallback>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: Duration(
        milliseconds: (12000 / widget.autoSpeed.clamp(0.1, 3.0)).round(),
      ),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Color _parseHex(String hex, Color fallback) {
    final clean = hex.replaceAll('#', '').trim();
    if (clean.length == 6) {
      final val = int.tryParse('FF$clean', radix: 16);
      if (val != null) return Color(val);
    }
    return fallback;
  }

  @override
  Widget build(BuildContext context) {
    final c1 = widget.colors.isNotEmpty
        ? _parseHex(widget.colors.first, const Color(0xFF06B6D4))
        : const Color(0xFF06B6D4);
    final c2 = widget.colors.length > 1
        ? _parseHex(widget.colors.last, const Color(0xFFF43F5E))
        : c1;
    final bg = widget.backgroundColor == 'transparent'
        ? const Color(0xFF0A0F18)
        : _parseHex(widget.backgroundColor, const Color(0xFF0A0F18));

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        return CustomPaint(
          painter: _LiquidFallbackPainter(
            progress: _controller.value,
            colorPrimary: c1,
            colorSecondary: c2,
            backgroundColor: bg,
          ),
          size: Size.infinite,
        );
      },
    );
  }
}

class _LiquidFallbackPainter extends CustomPainter {
  final double progress;
  final Color colorPrimary;
  final Color colorSecondary;
  final Color backgroundColor;

  _LiquidFallbackPainter({
    required this.progress,
    required this.colorPrimary,
    required this.colorSecondary,
    required this.backgroundColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(
      Offset.zero & size,
      Paint()..color = backgroundColor,
    );

    final t = progress * 2 * math.pi;
    final center1 = Offset(
      size.width * (0.5 + 0.28 * math.sin(t * 0.83 + 1.3)),
      size.height * (0.5 + 0.25 * math.cos(t * 1.07 + 2.1)),
    );
    final center2 = Offset(
      size.width * (0.5 + 0.30 * math.cos(t * 0.71 + 0.4)),
      size.height * (0.5 + 0.28 * math.sin(t * 1.15 + 0.7)),
    );

    final radius = math.max(size.width, size.height) * 0.55;

    canvas.drawCircle(
      center1,
      radius,
      Paint()
        ..shader = RadialGradient(
          colors: [
            colorPrimary.withValues(alpha: 0.38),
            colorPrimary.withValues(alpha: 0.0),
          ],
        ).createShader(Rect.fromCircle(center: center1, radius: radius)),
    );

    canvas.drawCircle(
      center2,
      radius * 0.9,
      Paint()
        ..shader = RadialGradient(
          colors: [
            colorSecondary.withValues(alpha: 0.34),
            colorSecondary.withValues(alpha: 0.0),
          ],
        ).createShader(Rect.fromCircle(center: center2, radius: radius * 0.9)),
    );
  }

  @override
  bool shouldRepaint(covariant _LiquidFallbackPainter oldDelegate) =>
      oldDelegate.progress != progress;
}
