import 'package:flutter/material.dart';

/// Layout metrics and geometric constants for the floating bottom navigation dock.
class FloatingDockLayout {
  FloatingDockLayout._();

  /// Height of the floating dock container itself.
  static const double dockHeight = 58.0;

  /// Bottom margin between dock and system gesture insets / screen edge.
  static const double dockBottomMargin = 12.0;

  /// Horizontal padding around the dock.
  static const double dockHorizontalPadding = 16.0;

  /// Default vertical gap between the top of the dock and floating action buttons.
  static const double fabDockGap = 16.0;

  /// Returns the total distance from the bottom of the screen to the top of the dock,
  /// including the physical device's gesture bar safe area.
  static double dockTopOffset(BuildContext context) {
    final bottomInset = MediaQuery.viewPaddingOf(context).bottom;
    return bottomInset + dockBottomMargin + dockHeight;
  }

  /// Returns the recommended clearance height for scrollable views (ListView, CustomScrollView)
  /// so that the bottommost content is never hidden behind the floating dock.
  static double scrollClearance(BuildContext context, {double extra = 16.0}) {
    return dockTopOffset(context) + extra;
  }
}

/// A custom [FloatingActionButtonLocation] that dynamically positions the FAB
/// right-aligned and floating cleanly above the FishBit floating navigation dock,
/// adapting dynamically to system gesture bars (iOS home indicator, Android gesture pill)
/// and virtual keyboards.
class FloatingDockFabLocation extends FloatingActionButtonLocation {
  final double extraBottomMargin;

  const FloatingDockFabLocation({this.extraBottomMargin = 0.0});

  /// Standard end-float location for all main screens above the navigation dock.
  static const FloatingDockFabLocation endFloat = FloatingDockFabLocation();

  @override
  Offset getOffset(ScaffoldPrelayoutGeometry scaffoldGeometry) {
    // 1. Horizontal: 16dp from right edge
    final double fabX = scaffoldGeometry.scaffoldSize.width -
        scaffoldGeometry.floatingActionButtonSize.width -
        16.0;

    // 2. Vertical keyboard handling: if keyboard is open, float 16dp above keyboard
    final double keyboardInset = scaffoldGeometry.minInsets.bottom;
    if (keyboardInset > 0) {
      final double fabY = scaffoldGeometry.scaffoldSize.height -
          keyboardInset -
          scaffoldGeometry.floatingActionButtonSize.height -
          16.0;
      return Offset(fabX, fabY);
    }

    // 3. Float cleanly above the floating dock
    final double bottomInset = scaffoldGeometry.minViewPadding.bottom;
    final double totalClearance = bottomInset +
        FloatingDockLayout.dockBottomMargin +
        FloatingDockLayout.dockHeight +
        FloatingDockLayout.fabDockGap +
        extraBottomMargin;

    final double fabY = scaffoldGeometry.scaffoldSize.height -
        totalClearance -
        scaffoldGeometry.floatingActionButtonSize.height;

    return Offset(fabX, fabY);
  }
}

/// A spacer widget to place at the end of [ListView] or [Column] to prevent
/// content occlusion behind the floating navigation dock.
class DockBottomSpacer extends StatelessWidget {
  final double extra;
  const DockBottomSpacer({super.key, this.extra = 16.0});

  @override
  Widget build(BuildContext context) {
    return SizedBox(height: FloatingDockLayout.scrollClearance(context, extra: extra));
  }
}

/// A sliver spacer widget to place at the end of [CustomScrollView] to prevent
/// content occlusion behind the floating navigation dock.
class SliverDockBottomSpacer extends StatelessWidget {
  final double extra;
  const SliverDockBottomSpacer({super.key, this.extra = 16.0});

  @override
  Widget build(BuildContext context) {
    return SliverToBoxAdapter(
      child: SizedBox(height: FloatingDockLayout.scrollClearance(context, extra: extra)),
    );
  }
}
