// ignore: avoid_web_libraries_in_flutter, deprecated_member_use
import 'dart:html' as html;
// ignore: avoid_web_libraries_in_flutter, deprecated_member_use
import 'dart:js_util' as js_util;
import 'dart:ui_web' as ui_web;
import 'package:flutter/material.dart';

/// Implementación WebGL2 nativa de LiquidEther para Flutter Web.
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
  return _WebLiquidEtherWidget(
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

class _WebLiquidEtherWidget extends StatefulWidget {
  final List<String> colors;
  final double mouseForce;
  final double cursorSize;
  final double persistence;
  final bool autoDemo;
  final double autoSpeed;
  final double autoIntensity;
  final String backgroundColor;

  const _WebLiquidEtherWidget({
    required this.colors,
    required this.mouseForce,
    required this.cursorSize,
    required this.persistence,
    required this.autoDemo,
    required this.autoSpeed,
    required this.autoIntensity,
    required this.backgroundColor,
  });

  @override
  State<_WebLiquidEtherWidget> createState() => _WebLiquidEtherWidgetState();
}

class _WebLiquidEtherWidgetState extends State<_WebLiquidEtherWidget> {
  static int _viewCounter = 0;
  late final String _viewType;
  late final html.DivElement _container;

  @override
  void initState() {
    super.initState();
    _viewCounter++;
    _viewType = 'fishbit-liquid-ether-$_viewCounter';

    _container = html.DivElement()
      ..style.width = '100%'
      ..style.height = '100%'
      ..style.position = 'relative'
      ..style.overflow = 'hidden'
      ..style.pointerEvents = 'none'
      ..style.backgroundColor = widget.backgroundColor == 'transparent'
          ? 'transparent'
          : widget.backgroundColor;

    ui_web.platformViewRegistry.registerViewFactory(
      _viewType,
      (int viewId) {
        // Montar LiquidEther después de que el DOM inserte el contenedor
        Future<void>.delayed(Duration.zero, _mountSimulation);
        return _container;
      },
    );
  }

  void _mountSimulation() {
    if (!mounted) return;
    try {
      if (js_util.hasProperty(html.window, 'mountLiquidEther')) {
        final options = js_util.jsify({
          'colors': widget.colors,
          'mouseForce': widget.mouseForce,
          'cursorSize': widget.cursorSize,
          'persistence': widget.persistence,
          'autoDemo': widget.autoDemo,
          'autoSpeed': widget.autoSpeed,
          'autoIntensity': widget.autoIntensity,
          'autoResumeDelay': 0,
          'backgroundColor': widget.backgroundColor,
        });
        js_util.callMethod(html.window, 'mountLiquidEther', [_container, options]);
      }
    } catch (_) {}
  }

  @override
  void dispose() {
    try {
      if (js_util.hasProperty(_container, '__liquidEtherDestroy')) {
        final destroyFn = js_util.getProperty<Object?>(_container, '__liquidEtherDestroy');
        if (destroyFn != null) {
          js_util.callMethod(_container, '__liquidEtherDestroy', const []);
        }
      }
    } catch (_) {}
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: HtmlElementView(viewType: _viewType),
    );
  }
}
