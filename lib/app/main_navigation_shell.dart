import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:fishbit_finance/core/design_system/app_colors.dart';
import 'package:fishbit_finance/core/design_system/glass_action_hub_sheet.dart';
import 'package:fishbit_finance/core/design_system/gradient_waves_background.dart';
export 'package:fishbit_finance/core/design_system/floating_dock_layout.dart';

enum PillNavItemStyle { plain, bordered }

enum PillNavHoverEffect { fill, none }

enum PillNavIndicator { pill, underline }

enum PillNavLayout { joined, split }

enum PillNavSize { sm, md }

enum PillNavCollapse { never, auto }

class MainNavigationShell extends ConsumerStatefulWidget {
  final Widget child;

  const MainNavigationShell({
    super.key,
    required this.child,
  });

  @override
  ConsumerState<MainNavigationShell> createState() =>
      _MainNavigationShellState();
}

class _MainNavigationShellState extends ConsumerState<MainNavigationShell> {
  final GradientWavesController _wavesController = GradientWavesController();

  int _calculateSelectedIndex(BuildContext context) {
    final location = GoRouterState.of(context).matchedLocation;
    if (location.startsWith('/ponds')) return 1;
    if (location.startsWith('/warehouse')) return 2;
    if (location.startsWith('/bitacora') || location.startsWith('/records')) return 3;
    if (location.startsWith('/finance') ||
        location.startsWith('/sales') ||
        location.startsWith('/team') ||
        location.startsWith('/creator') ||
        location.startsWith('/ica')) {
      return 4; // Módulos del Hub Más
    }
    return 0;
  }

  void _onItemTapped(int index, BuildContext context) {
    HapticFeedback.lightImpact();
    switch (index) {
      case 0:
        context.go('/');
        break;
      case 1:
        context.go('/ponds');
        break;
      case 2:
        context.go('/warehouse');
        break;
      case 3:
        context.go('/bitacora');
        break;
      case 4:
        GlassActionHubSheet.show(context);
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final selectedIndex = _calculateSelectedIndex(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isKeyboardOpen = MediaQuery.viewInsetsOf(context).bottom > 0;
    final screenSize = MediaQuery.sizeOf(context);

    // Paleta FishBit: océano cian + horizonte con toque sutil coral FishBit
    final horizonColor =
        isDark ? const Color(0xFF4C142B) : const Color(0xFFFDA4AF);
    final waveColor =
        isDark ? AppColors.cyanWater : const Color(0xFF38BDF8);
    final crestColor =
        isDark ? const Color(0xFF67E8F9) : const Color(0xFFE0F2FE);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Listener(
        behavior: HitTestBehavior.translucent,
        onPointerHover: (e) =>
            _wavesController.updatePointer(e.position, screenSize),
        onPointerMove: (e) =>
            _wavesController.updatePointer(e.position, screenSize),
        onPointerDown: (e) =>
            _wavesController.triggerSwell(e.position, screenSize),
        child: Stack(
          children: [
            // Fondo global único <GradientWaves /> (React Bits) continuo entre vistas
            Positioned.fill(
              child: IgnorePointer(
                child: GradientWavesBackground(
                  controller: _wavesController,
                  horizonColor: horizonColor,
                  waveColor: waveColor,
                  crestColor: crestColor,
                  speed: 0.45,
                  amplitude: 1.6,
                  relief: 1.0,
                  lightAngle: 150.0,
                  mouseInteraction: true,
                  swellOnClick: true,
                  waveScale: 0.9,
                  swell: 24.0,
                  turbulence: 26.0,
                  opacity: isDark ? 0.40 : 0.34,
                  paused: isKeyboardOpen,
                ),
              ),
            ),

            // Pantalla actual activa (aislada en RepaintBoundary sobre las ondas)
            Positioned.fill(child: RepaintBoundary(child: widget.child)),

          // Barra Flotante <PillNav /> (React Bits: itemStyle="plain", hoverEffect="fill",
          // indicator="pill", layout="joined", size="sm", collapse="never")
          if (!isKeyboardOpen)
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: SafeArea(
                bottom: true,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(10, 0, 10, 12),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 500),
                      child: PillNavBar(
                        activeIndex: selectedIndex,
                        isDark: isDark,
                        itemStyle: PillNavItemStyle.plain,
                        hoverEffect: PillNavHoverEffect.fill,
                        indicator: PillNavIndicator.pill,
                        layout: PillNavLayout.joined,
                        size: PillNavSize.sm,
                        collapse: PillNavCollapse.never,
                        onSelect: (index) => _onItemTapped(index, context),
                        items: [
                          PillNavItemData(
                            label: 'Inicio',
                            iconBuilder: (color, size) =>
                                _HomeSvgIcon(color: color, size: size),
                          ),
                          const PillNavItemData(
                            label: 'Estanques',
                            icon: Icons.water_drop_outlined,
                            activeIcon: Icons.water_drop_rounded,
                          ),
                          const PillNavItemData(
                            label: 'Almacén',
                            icon: Icons.inventory_2_outlined,
                            activeIcon: Icons.inventory_2_rounded,
                          ),
                          const PillNavItemData(
                            label: 'Bitácora',
                            icon: Icons.assignment_outlined,
                            activeIcon: Icons.assignment_rounded,
                          ),
                          const PillNavItemData(
                            label: 'Más',
                            icon: Icons.grid_view_rounded,
                            activeIcon: Icons.grid_view_rounded,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class PillNavItemData {
  final String label;
  final IconData? icon;
  final IconData? activeIcon;
  final Widget Function(Color color, double size)? iconBuilder;

  const PillNavItemData({
    required this.label,
    this.icon,
    this.activeIcon,
    this.iconBuilder,
  });
}

class PillNavBar extends StatefulWidget {
  final List<PillNavItemData> items;
  final int activeIndex;
  final bool isDark;
  final ValueChanged<int> onSelect;
  final PillNavItemStyle itemStyle;
  final PillNavHoverEffect hoverEffect;
  final PillNavIndicator indicator;
  final PillNavLayout layout;
  final PillNavSize size;
  final PillNavCollapse collapse;

  const PillNavBar({
    super.key,
    required this.items,
    required this.activeIndex,
    required this.isDark,
    required this.onSelect,
    this.itemStyle = PillNavItemStyle.plain,
    this.hoverEffect = PillNavHoverEffect.fill,
    this.indicator = PillNavIndicator.pill,
    this.layout = PillNavLayout.joined,
    this.size = PillNavSize.sm,
    this.collapse = PillNavCollapse.never,
  });

  @override
  State<PillNavBar> createState() => _PillNavBarState();
}

class _PillNavBarState extends State<PillNavBar>
    with SingleTickerProviderStateMixin {
  static const Cubic _pillCurve = Cubic(0.22, 1.0, 0.36, 1.0);

  final GlobalKey _stageKey = GlobalKey();
  late List<GlobalKey> _itemKeys;

  late AnimationController _pillController;
  Rect? _fromRect;
  Rect? _toRect;
  Rect? _currentPillRect;

  List<Rect> _rects = const [];
  int _hoveredIndex = -1;
  int _pressedIndex = -1;

  @override
  void initState() {
    super.initState();
    _itemKeys = List.generate(widget.items.length, (_) => GlobalKey());
    _pillController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 280),
    )..addListener(_onPillTick);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _measure();
      _snapTo(widget.activeIndex);
    });
  }

  @override
  void didUpdateWidget(covariant PillNavBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.items.length != widget.items.length) {
      _itemKeys = List.generate(widget.items.length, (_) => GlobalKey());
    }
    if (oldWidget.activeIndex != widget.activeIndex) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        _measure();
        _animateTo(widget.activeIndex);
      });
    }
  }

  @override
  void dispose() {
    _pillController.removeListener(_onPillTick);
    _pillController.dispose();
    super.dispose();
  }

  void _measure() {
    final stageCtx = _stageKey.currentContext;
    if (stageCtx == null) return;
    final stageBox = stageCtx.findRenderObject() as RenderBox?;
    if (stageBox == null || !stageBox.hasSize) return;

    final measured = <Rect>[];
    for (final key in _itemKeys) {
      final box = key.currentContext?.findRenderObject() as RenderBox?;
      if (box == null || !box.hasSize) {
        measured.add(Rect.zero);
        continue;
      }
      final offset = box.localToGlobal(Offset.zero, ancestor: stageBox);
      measured.add(offset & box.size);
    }
    _rects = measured;
  }

  void _snapTo(int index) {
    if (index < 0 || index >= _rects.length || _rects[index].isEmpty) return;
    _pillController.stop();
    _fromRect = _rects[index];
    _toRect = _rects[index];
    setState(() {
      _currentPillRect = _rects[index];
    });
  }

  void _animateTo(int index) {
    if (index < 0 || index >= _rects.length || _rects[index].isEmpty) return;
    final target = _rects[index];
    if (_currentPillRect == null) {
      _snapTo(index);
      return;
    }
    // Retomar desde la posición actual si el usuario cambia rápido a mitad de animación
    _fromRect = _currentPillRect;
    _toRect = target;
    _pillController.forward(from: 0.0);
  }

  void _onPillTick() {
    if (_fromRect == null || _toRect == null) return;
    final t = _pillCurve.transform(_pillController.value);
    setState(() {
      _currentPillRect = Rect.lerp(_fromRect, _toRect, t);
    });
  }

  Widget _buildItemsRow({
    required bool interactive,
    required Color ink,
    required Color muted,
    required Color hoverFill,
  }) {
    final isSm = widget.size == PillNavSize.sm;
    final iconSize = isSm ? 18.0 : 20.0;
    final fontSize = isSm ? 10.5 : 11.5;
    final vPad = isSm ? 6.0 : 8.0;

    return Row(
      children: List.generate(widget.items.length, (index) {
        final item = widget.items[index];
        final isActive = index == widget.activeIndex;
        final isHovered = interactive &&
            widget.hoverEffect == PillNavHoverEffect.fill &&
            (_hoveredIndex == index || _pressedIndex == index) &&
            !isActive;
        final color = !interactive ? ink : (isHovered ? ink : muted);

        final content = AnimatedContainer(
          key: interactive ? _itemKeys[index] : null,
          duration: const Duration(milliseconds: 140),
          curve: Curves.easeOutCubic,
          padding: EdgeInsets.symmetric(vertical: vPad, horizontal: 4),
          decoration: BoxDecoration(
            color: isHovered ? hoverFill : Colors.transparent,
            borderRadius: BorderRadius.circular(999),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (item.iconBuilder != null)
                item.iconBuilder!(color, iconSize)
              else
                Icon(
                  !interactive && isActive
                      ? (item.activeIcon ?? item.icon)
                      : item.icon,
                  color: color,
                  size: iconSize,
                ),
              const SizedBox(height: 2.5),
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  item.label,
                  maxLines: 1,
                  style: TextStyle(
                    color: color,
                    fontSize: fontSize,
                    height: 1.0,
                    letterSpacing: -0.15,
                    fontWeight:
                        (!interactive || isActive) ? FontWeight.w600 : FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        );

        if (!interactive) {
          return Expanded(child: content);
        }

        return Expanded(
          child: Semantics(
            button: true,
            selected: isActive,
            label: item.label,
            child: MouseRegion(
              cursor: SystemMouseCursors.click,
              onEnter: (_) {
                if (_hoveredIndex != index) {
                  setState(() => _hoveredIndex = index);
                }
              },
              onExit: (_) {
                if (_hoveredIndex == index) {
                  setState(() => _hoveredIndex = -1);
                }
              },
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTapDown: (_) => setState(() => _pressedIndex = index),
                onTapUp: (_) => setState(() => _pressedIndex = -1),
                onTapCancel: () => setState(() => _pressedIndex = -1),
                onTap: () => widget.onSelect(index),
                child: content,
              ),
            ),
          ),
        );
      }),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = widget.isDark;
    final frameBg = isDark
        ? const Color.fromRGBO(28, 28, 34, 0.72)
        : const Color.fromRGBO(244, 244, 247, 0.86);
    final frameEdge = isDark
        ? Colors.white.withValues(alpha: 0.10)
        : const Color.fromRGBO(24, 24, 27, 0.08);
    final frameHighlight = isDark
        ? Colors.white.withValues(alpha: 0.08)
        : Colors.white.withValues(alpha: 0.95);
    final ink = isDark ? const Color(0xFFF4F4F5) : const Color(0xFF18181B);
    final muted = isDark
        ? const Color.fromRGBO(244, 244, 245, 0.62)
        : const Color.fromRGBO(24, 24, 27, 0.60);
    final pillColor =
        isDark ? const Color(0xFFF4F4F5) : const Color(0xFF18181B);
    final activeInk =
        isDark ? const Color(0xFF18181B) : const Color(0xFFFFFFFF);
    final hoverFill = isDark
        ? Colors.white.withValues(alpha: 0.09)
        : Colors.black.withValues(alpha: 0.06);

    final activeClipRRect = _currentPillRect != null
        ? RRect.fromRectAndRadius(
            _currentPillRect!,
            const Radius.circular(999),
          )
        : null;

    return NotificationListener<SizeChangedLayoutNotification>(
      onNotification: (_) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          _measure();
          if (!_pillController.isAnimating) {
            _snapTo(widget.activeIndex);
          }
        });
        return false;
      },
      child: SizeChangedLayoutNotifier(
        child: DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(999),
            boxShadow: isDark
                ? [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.72),
                      blurRadius: 36,
                      spreadRadius: -18,
                      offset: const Offset(0, 18),
                    ),
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.42),
                      blurRadius: 12,
                      spreadRadius: -6,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : [
                    const BoxShadow(
                      color: Color.fromRGBO(24, 24, 27, 0.22),
                      blurRadius: 32,
                      spreadRadius: -16,
                      offset: Offset(0, 16),
                    ),
                    const BoxShadow(
                      color: Color.fromRGBO(24, 24, 27, 0.10),
                      blurRadius: 10,
                      spreadRadius: -4,
                      offset: Offset(0, 4),
                    ),
                  ],
          ),
          child: Stack(
            children: [
              // Marco glassmorphic aislado en RepaintBoundary para evitar recomputar el blur en cada frame
              Positioned.fill(
                child: RepaintBoundary(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(999),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          color: frameBg,
                          borderRadius: BorderRadius.circular(999),
                          border: Border.all(color: frameEdge, width: 1),
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            stops: const [0.0, 0.16, 1.0],
                            colors: [
                              frameHighlight,
                              Colors.transparent,
                              Colors.transparent,
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),

              // Escenario unido (layout="joined") con size="sm"
              Padding(
                padding: const EdgeInsets.all(4),
                child: Stack(
                  key: _stageKey,
                  children: [
                    // Pastilla indicadora deslizante O(1)
                    if (_currentPillRect != null)
                      Positioned.fromRect(
                        rect: _currentPillRect!,
                        child: IgnorePointer(
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              color: pillColor,
                              borderRadius: BorderRadius.circular(999),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black
                                      .withValues(alpha: isDark ? 0.30 : 0.14),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),

                    // Capa base interactiva (itemStyle="plain", hoverEffect="fill")
                    _buildItemsRow(
                      interactive: true,
                      ink: ink,
                      muted: muted,
                      hoverFill: hoverFill,
                    ),

                    // Capa invertida recortada por la pastilla activa en tiempo O(1)
                    if (activeClipRRect != null)
                      Positioned.fill(
                        child: IgnorePointer(
                          child: ClipRRect(
                            clipper: _PillRRectClipper(activeClipRRect),
                            child: _buildItemsRow(
                              interactive: false,
                              ink: activeInk,
                              muted: activeInk,
                              hoverFill: Colors.transparent,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PillRRectClipper extends CustomClipper<RRect> {
  final RRect rrect;

  const _PillRRectClipper(this.rrect);

  @override
  RRect getClip(Size size) => rrect;

  @override
  bool shouldReclip(covariant _PillRRectClipper oldClipper) =>
      oldClipper.rrect != rrect;
}

class _HomeSvgIcon extends StatelessWidget {
  final Color color;
  final double size;

  const _HomeSvgIcon({
    required this.color,
    required this.size,
  });

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size.square(size),
      painter: _HomeSvgPainter(color: color),
    );
  }
}

class _HomeSvgPainter extends CustomPainter {
  final Color color;

  const _HomeSvgPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final sx = size.width / 24.0;
    final sy = size.height / 24.0;
    canvas.save();
    canvas.scale(sx, sy);

    final path = Path()
      ..moveTo(3, 10.5651)
      ..cubicTo(3, 9.9907, 3, 9.70352, 3.07403, 9.43905)
      ..cubicTo(3.1396, 9.20478, 3.24737, 8.98444, 3.39203, 8.78886)
      ..cubicTo(3.55534, 8.56806, 3.78202, 8.39175, 4.23539, 8.03912)
      ..lineTo(11.0177, 2.764)
      ..cubicTo(11.369, 2.49075, 11.5447, 2.35412, 11.7387, 2.3016)
      ..cubicTo(11.9098, 2.25526, 12.0902, 2.25526, 12.2613, 2.3016)
      ..cubicTo(12.4553, 2.35412, 12.631, 2.49075, 12.9823, 2.764)
      ..lineTo(19.7646, 8.03913)
      ..cubicTo(20.218, 8.39175, 20.4447, 8.56806, 20.608, 8.78886)
      ..cubicTo(20.7526, 8.98444, 20.8604, 9.20478, 20.926, 9.43905)
      ..cubicTo(21, 9.70352, 21, 9.9907, 21, 10.5651)
      ..lineTo(21, 17.8)
      ..cubicTo(21, 18.9201, 21, 19.4801, 20.782, 19.908)
      ..cubicTo(20.5903, 20.2843, 20.2843, 20.5903, 19.908, 20.782)
      ..cubicTo(19.4802, 21, 18.9201, 21, 17.8, 21)
      ..lineTo(6.2, 21)
      ..cubicTo(5.07989, 21, 4.51984, 21, 4.09202, 20.782)
      ..cubicTo(3.71569, 20.5903, 3.40973, 20.2843, 3.21799, 19.908)
      ..cubicTo(3, 19.4801, 3, 18.9201, 3, 17.8)
      ..close();

    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    canvas.drawPath(path, paint);
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _HomeSvgPainter oldDelegate) =>
      oldDelegate.color != color;
}
