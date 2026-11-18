import 'package:flutter/material.dart';
import 'liquid_ether_background_stub.dart'
    if (dart.library.html) 'liquid_ether_background_web.dart';

/// Fondo interactivo LiquidEther (WebGL2 Navier-Stokes en Web, fallback fluido en nativo).
class LiquidEtherBackground extends StatelessWidget {
  final List<String> colors;
  final double mouseForce;
  final double cursorSize;
  final double persistence;
  final bool autoDemo;
  final double autoSpeed;
  final double autoIntensity;
  final String backgroundColor;

  const LiquidEtherBackground({
    super.key,
    this.colors = const ['#06b6d4', '#f43f5e'],
    this.mouseForce = 20,
    this.cursorSize = 100,
    this.persistence = 0.75,
    this.autoDemo = true,
    this.autoSpeed = 0.5,
    this.autoIntensity = 2.2,
    this.backgroundColor = '#0A0F18',
  });

  @override
  Widget build(BuildContext context) {
    return buildLiquidEtherBackground(
      colors: colors,
      mouseForce: mouseForce,
      cursorSize: cursorSize,
      persistence: persistence,
      autoDemo: autoDemo,
      autoSpeed: autoSpeed,
      autoIntensity: autoIntensity,
      backgroundColor: backgroundColor,
    );
  }
}
