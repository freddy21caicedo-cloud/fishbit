import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fishbit_finance/core/design_system/app_colors.dart';

class HeroTabItem {
  final Key? key;
  final String label;
  final IconData icon;
  final Color accentColor;
  final int? badgeCount;

  const HeroTabItem({
    this.key,
    required this.label,
    required this.icon,
    this.accentColor = AppColors.cyanWater,
    this.badgeCount,
  });
}

/// Barra de pestañas inspirada en HeroUI v3 `Tabs`
/// (`Tabs.ListContainer` → `Tabs.List` → `Tabs.Tab` + `Tabs.Indicator` deslizante).
class HeroTabsBar extends StatefulWidget {
  final TabController controller;
  final List<HeroTabItem> tabs;
  final ValueChanged<int>? onTap;
  final bool borderless;

  const HeroTabsBar({
    super.key,
    required this.controller,
    required this.tabs,
    this.onTap,
    this.borderless = false,
  });

  @override
  State<HeroTabsBar> createState() => _HeroTabsBarState();
}

class _HeroTabsBarState extends State<HeroTabsBar> {
  final GlobalKey _rowKey = GlobalKey();
  late List<GlobalKey> _tabKeys;
  List<Rect> _tabRects = const [];
  int _hoveredIndex = -1;
  int _lastKnownIndex = 0;

  @override
  void initState() {
    super.initState();
    _tabKeys = List.generate(widget.tabs.length, (_) => GlobalKey());
    _lastKnownIndex = widget.controller.index;
    widget.controller.addListener(_onControllerChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) => _measureTabs());
  }

  @override
  void didUpdateWidget(covariant HeroTabsBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller.removeListener(_onControllerChanged);
      widget.controller.addListener(_onControllerChanged);
    }
    if (oldWidget.tabs.length != widget.tabs.length) {
      _tabKeys = List.generate(widget.tabs.length, (_) => GlobalKey());
    }
    WidgetsBinding.instance.addPostFrameCallback((_) => _measureTabs());
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onControllerChanged);
    super.dispose();
  }

  void _onControllerChanged() {
    if (!mounted) return;
    if (widget.controller.index != _lastKnownIndex) {
      _lastKnownIndex = widget.controller.index;
      _ensureActiveVisible();
    }
    setState(() {});
  }

  void _ensureActiveVisible() {
    final idx = widget.controller.index;
    if (idx < 0 || idx >= _tabKeys.length) return;
    final ctx = _tabKeys[idx].currentContext;
    if (ctx != null) {
      Scrollable.ensureVisible(
        ctx,
        duration: const Duration(milliseconds: 260),
        curve: Curves.easeOutCubic,
        alignment: 0.5,
      );
    }
  }

  void _measureTabs() {
    if (!mounted) return;
    final rowCtx = _rowKey.currentContext;
    final rowBox = rowCtx?.findRenderObject() as RenderBox?;
    if (rowBox == null || !rowBox.hasSize) return;

    final rects = <Rect>[];
    for (final key in _tabKeys) {
      final box = key.currentContext?.findRenderObject() as RenderBox?;
      if (box == null || !box.hasSize) {
        rects.add(Rect.zero);
        continue;
      }
      final offset = box.localToGlobal(Offset.zero, ancestor: rowBox);
      rects.add(offset & box.size);
    }

    if (rects.length != _tabRects.length ||
        Iterable.generate(rects.length, (i) => rects[i] != _tabRects[i])
            .any((changed) => changed)) {
      setState(() => _tabRects = rects);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final listBg = isDark ? const Color(0xFF18181B) : const Color(0xFFF4F4F5);
    final listBorder = isDark
        ? Colors.white.withValues(alpha: 0.08)
        : Colors.black.withValues(alpha: 0.06);

    final animation = widget.controller.animation ??
        AlwaysStoppedAnimation<double>(widget.controller.index.toDouble());

    return NotificationListener<SizeChangedLayoutNotification>(
      onNotification: (_) {
        WidgetsBinding.instance.addPostFrameCallback((_) => _measureTabs());
        return false;
      },
      child: SizeChangedLayoutNotifier(
        child: Container(
          decoration: widget.borderless
              ? null
              : BoxDecoration(
                  color: listBg,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: listBorder, width: 1),
                ),
          padding: widget.borderless
              ? const EdgeInsets.symmetric(vertical: 2)
              : const EdgeInsets.all(4),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            child: AnimatedBuilder(
              animation: animation,
              builder: (context, child) {
                final animVal = animation.value
                    .clamp(0.0, (widget.tabs.length - 1).toDouble());
                final floorIdx = animVal.floor();
                final ceilIdx = animVal.ceil();
                final t = animVal - floorIdx;

                Rect? indicatorRect;
                if (_tabRects.length == widget.tabs.length &&
                    floorIdx < _tabRects.length &&
                    ceilIdx < _tabRects.length) {
                  final rA = _tabRects[floorIdx];
                  final rB = _tabRects[ceilIdx];
                  if (!rA.isEmpty && !rB.isEmpty) {
                    indicatorRect = Rect.lerp(rA, rB, t);
                  }
                }

                final activeAccent = Color.lerp(
                  widget.tabs[floorIdx].accentColor,
                  widget.tabs[ceilIdx].accentColor,
                  t,
                )!;

                return Stack(
                  children: [
                    // <Tabs.Indicator /> flotante deslizante
                    if (indicatorRect != null)
                      Positioned(
                        left: indicatorRect.left,
                        top: indicatorRect.top,
                        width: indicatorRect.width,
                        height: indicatorRect.height,
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            color: widget.borderless
                                ? (isDark
                                    ? activeAccent.withValues(alpha: 0.18)
                                    : Colors.white.withValues(alpha: 0.92))
                                : (isDark
                                    ? const Color(0xFF27272A)
                                    : Colors.white),
                            borderRadius: BorderRadius.circular(
                              widget.borderless ? 999 : 10,
                            ),
                            border: Border.all(
                              color: isDark
                                  ? activeAccent.withValues(
                                      alpha: widget.borderless ? 0.45 : 0.35,
                                    )
                                  : (widget.borderless
                                      ? activeAccent.withValues(alpha: 0.25)
                                      : Colors.black.withValues(alpha: 0.05)),
                              width: 1,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black
                                    .withValues(alpha: isDark ? 0.28 : 0.08),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                        ),
                      ),

                    // <Tabs.List /> con <Tabs.Tab />
                    Row(
                      key: _rowKey,
                      mainAxisSize: MainAxisSize.min,
                      children: List.generate(widget.tabs.length, (index) {
                        final tab = widget.tabs[index];
                        final isSelected = widget.controller.index == index;
                        final isHovered = _hoveredIndex == index;
                        final distance = (animVal - index).abs().clamp(0.0, 1.0);
                        final activeWeight = 1.0 - distance;

                        final inactiveText = isDark
                            ? const Color(0xFFA1A1AA)
                            : const Color(0xFF71717A);
                        final activeText =
                            isDark ? Colors.white : const Color(0xFF18181B);
                        final labelColor = ui.Color.lerp(
                          isHovered ? activeText : inactiveText,
                          activeText,
                          activeWeight,
                        )!;
                        final iconColor = ui.Color.lerp(
                          isHovered ? tab.accentColor : inactiveText,
                          tab.accentColor,
                          activeWeight,
                        )!;

                        return MouseRegion(
                          cursor: SystemMouseCursors.click,
                          onEnter: (_) => setState(() => _hoveredIndex = index),
                          onExit: (_) => setState(() => _hoveredIndex = -1),
                          child: GestureDetector(
                            key: tab.key,
                            behavior: HitTestBehavior.opaque,
                            onTap: () {
                              HapticFeedback.selectionClick();
                              widget.controller.animateTo(index);
                              widget.onTap?.call(index);
                            },
                            child: Container(
                              key: _tabKeys[index],
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 9,
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    tab.icon,
                                    size: 16,
                                    color: iconColor,
                                  ),
                                  const SizedBox(width: 7),
                                  Text(
                                    tab.label,
                                    style: TextStyle(
                                      color: labelColor,
                                      fontSize: 13,
                                      fontWeight: isSelected
                                          ? FontWeight.w700
                                          : FontWeight.w500,
                                      letterSpacing: -0.1,
                                    ),
                                  ),
                                  if (tab.badgeCount != null) ...[
                                    const SizedBox(width: 6),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 6,
                                        vertical: 1.5,
                                      ),
                                      decoration: BoxDecoration(
                                        color: isSelected
                                            ? tab.accentColor
                                                .withValues(alpha: 0.18)
                                            : (isDark
                                                ? Colors.white
                                                    .withValues(alpha: 0.07)
                                                : Colors.black
                                                    .withValues(alpha: 0.06)),
                                        borderRadius: BorderRadius.circular(99),
                                      ),
                                      child: Text(
                                        '${tab.badgeCount}',
                                        style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w700,
                                          color: isSelected
                                              ? tab.accentColor
                                              : inactiveText,
                                        ),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ),
                        );
                      }),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}
