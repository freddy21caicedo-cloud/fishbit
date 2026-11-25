import 'package:flutter/material.dart';

class VerticalSpeedDialAction {
  final Key? key;
  final String label;
  final IconData icon;
  final Color? hoverIconColor;
  final VoidCallback onTap;

  const VerticalSpeedDialAction({
    this.key,
    required this.label,
    required this.icon,
    this.hoverIconColor,
    required this.onTap,
  });
}

/// Speed Dial vertical unilateral hacia arriba inspirado en Uiverse (`risabbir`),
/// consistente con Bitácora y Almacén.
class VerticalSpeedDial extends StatefulWidget {
  final double bottomOffset;
  final List<VerticalSpeedDialAction> actions;
  final Color primaryColor;
  final Color hoverPrimaryColor;
  final Key? toggleButtonKey;

  const VerticalSpeedDial({
    super.key,
    required this.bottomOffset,
    required this.actions,
    this.primaryColor = const Color(0xFF3B82F6),
    this.hoverPrimaryColor = const Color(0xFF2563EB),
    this.toggleButtonKey,
  });

  @override
  State<VerticalSpeedDial> createState() => _VerticalSpeedDialState();
}

class _VerticalSpeedDialState extends State<VerticalSpeedDial>
    with SingleTickerProviderStateMixin {
  bool _isOpen = false;
  bool _isMainHovered = false;
  int _hoveredItemIndex = -1;
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 520),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _toggle() {
    setState(() {
      _isOpen = !_isOpen;
      if (_isOpen) {
        _controller.forward();
      } else {
        _controller.reverse();
      }
    });
  }

  void _close() {
    if (!_isOpen) return;
    setState(() {
      _isOpen = false;
      _hoveredItemIndex = -1;
      _controller.reverse();
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Stack(
      clipBehavior: Clip.none,
      children: [
        // Scrim para cerrar al tocar fuera cuando está abierto
        if (_isOpen)
          Positioned.fill(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: _close,
              child: AnimatedOpacity(
                opacity: _isOpen ? 1.0 : 0.0,
                duration: const Duration(milliseconds: 220),
                child: Container(
                  color: Colors.black.withValues(alpha: isDark ? 0.28 : 0.10),
                ),
              ),
            ),
          ),

        // Sub-botones desplegándose verticalmente hacia arriba desde el botón +
        ...List.generate(widget.actions.length, (index) {
          final action = widget.actions[index];
          final startInterval = (index * 0.10).clamp(0.0, 0.45);
          final endInterval = (startInterval + 0.55).clamp(0.0, 1.0);
          final springAnim = CurvedAnimation(
            parent: _controller,
            curve: Interval(
              startInterval,
              endInterval,
              curve: const Cubic(0.68, -0.55, 0.27, 1.55),
            ),
            reverseCurve: const Interval(
              0.0,
              0.7,
              curve: Curves.easeInCubic,
            ),
          );
          final opacityAnim = CurvedAnimation(
            parent: _controller,
            curve: Interval(startInterval, (startInterval + 0.35).clamp(0.0, 1.0)),
          );
          final labelOpacityAnim = CurvedAnimation(
            parent: _controller,
            curve: Interval(
              (startInterval + 0.22).clamp(0.0, 0.8),
              1.0,
              curve: Curves.easeOut,
            ),
          );

          final targetOffsetY = 76.0 + index * 60.0;
          final isHovered = _hoveredItemIndex == index;
          final activeIconColor = action.hoverIconColor ?? widget.primaryColor;

          return AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              if (_controller.value == 0.0 && !_isOpen) {
                return const SizedBox.shrink();
              }
              final dy = targetOffsetY * springAnim.value;
              return Positioned(
                right: 24,
                bottom: widget.bottomOffset + 8 + dy,
                child: Opacity(
                  opacity: opacityAnim.value.clamp(0.0, 1.0),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Opacity(
                        opacity: labelOpacityAnim.value.clamp(0.0, 1.0),
                        child: Container(
                          margin: const EdgeInsets.only(right: 12),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            color: isDark
                                ? const Color(0xFF1F2937).withValues(alpha: 0.92)
                                : Colors.white.withValues(alpha: 0.94),
                            borderRadius: BorderRadius.circular(10),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.12),
                                blurRadius: 8,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                          child: Text(
                            action.label,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: isDark
                                  ? const Color(0xFFF3F4F6)
                                  : const Color(0xFF374151),
                            ),
                          ),
                        ),
                      ),
                      MouseRegion(
                        cursor: SystemMouseCursors.click,
                        onEnter: (_) => setState(() => _hoveredItemIndex = index),
                        onExit: (_) => setState(() => _hoveredItemIndex = -1),
                        child: GestureDetector(
                          key: action.key,
                          onTap: () {
                            _close();
                            action.onTap();
                          },
                          child: AnimatedScale(
                            scale: isHovered ? 1.10 : 1.0,
                            duration: const Duration(milliseconds: 200),
                            curve: Curves.easeOutCubic,
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              width: 48,
                              height: 48,
                              decoration: BoxDecoration(
                                color: isHovered
                                    ? const Color(0xFFF3F4F6)
                                    : Colors.white,
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.16),
                                    blurRadius: 14,
                                    offset: const Offset(0, 6),
                                  ),
                                ],
                              ),
                              alignment: Alignment.center,
                              child: Icon(
                                action.icon,
                                size: 20,
                                color: isHovered
                                    ? activeIconColor
                                    : const Color(0xFF6B7280),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        }),

        // Botón principal 64x64 con icono + que rota 45°
        Positioned(
          right: 16,
          bottom: widget.bottomOffset,
          child: MouseRegion(
            cursor: SystemMouseCursors.click,
            onEnter: (_) => setState(() => _isMainHovered = true),
            onExit: (_) => setState(() => _isMainHovered = false),
            child: GestureDetector(
              key: widget.toggleButtonKey,
              onTap: _toggle,
              child: AnimatedScale(
                scale: (_isMainHovered || _isOpen) ? 1.10 : 1.0,
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeOutCubic,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: (_isMainHovered || _isOpen)
                        ? widget.hoverPrimaryColor
                        : widget.primaryColor,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: widget.primaryColor.withValues(alpha: 0.35),
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                      ),
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.18),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  alignment: Alignment.center,
                  child: AnimatedRotation(
                    turns: _isOpen ? 0.125 : 0.0,
                    duration: const Duration(milliseconds: 450),
                    curve: Curves.easeInOut,
                    child: const Icon(
                      Icons.add_rounded,
                      size: 32,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
