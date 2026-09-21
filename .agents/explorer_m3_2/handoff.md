# Handoff Report — Explorer M3_2 (Navigation Dock & Gesture Bar SafeArea — UX-02)

**Task ID**: UX-02  
**Working Directory**: `c:\Users\Freddy\Desktop\Desarrollo de app\FishBit\.agents\explorer_m3_2`  
**Date**: 2026-09-14  
**Author**: Explorer M3_2  
**Target Milestone**: Milestone 3 (Field Ergonomics & WCAG A11y)  

---

## 1. Observation

### 1.1 Root Anchoring in `lib/app/main_navigation_shell.dart`
In `lib/app/main_navigation_shell.dart`, lines 50–78:
```dart
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedIndex = _calculateSelectedIndex(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final bottomPadding = MediaQuery.of(context).padding.bottom;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Stack(
        children: [
          // Pantalla actual activa
          Positioned.fill(child: child),

          // Barra Flotante Glassmorphic Bottom Dock (Estilo Apple macOS / iOS Dock)
          Positioned(
            left: 16,
            right: 16,
            bottom: bottomPadding > 0 ? bottomPadding + 8 : 16,
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 480),
                child: GlassContainer(
                  borderRadius: 28,
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
                  blur: 24,
                  opacity: isDark ? 0.14 : 0.92,
                  borderColor: isDark ? Colors.white.withValues(alpha: 0.16) : AppColors.glassBorderLight,
                  child: Row(
```
Direct observations:
1. The dock is not wrapped in `SafeArea(bottom: true)`. It uses an ad-hoc ternary expression: `bottom: bottomPadding > 0 ? bottomPadding + 8 : 16` based on `MediaQuery.of(context).padding.bottom`.
2. `MediaQuery.of(context).padding.bottom` is volatile: when the virtual soft keyboard opens (`viewInsets.bottom > 0`), Flutter platform channels zero-out or consume `padding.bottom`, causing layout thrashing.
3. Because the outer `Scaffold` does not specify `resizeToAvoidBottomInset: false` and lacks keyboard suppression (`MediaQuery.viewInsetsOf(context).bottom > 0`), the navigation dock is pushed upwards whenever an on-screen keyboard appears, hovering directly over input fields.
4. The dock height is ~58–60 dp (`GlassContainer` vertical padding 12 dp + `NavItemButton` padding 12 dp + icon 21 dp + label text ~12 dp + gap 2 dp).
5. On devices with system gesture bars (iOS home indicator 34 dp, Android gesture pill 24–28 dp), the dock's top edge is positioned at `34 + 8 + 60 = 102 dp` from the bottom edge of the device. On devices without insets (Android 3-button navigation, desktop/web), the top edge is at `16 + 60 = 76 dp`.

### 1.2 Cascading `bottom: 78` FAB Padding Hacks
Because `child` in `MainNavigationShell` is placed in `Positioned.fill(child: child)` inside an outer `Stack`, child screens use their own nested `Scaffold`. That inner `Scaffold` has no ambient knowledge of the outer floating dock. Consequently, Flutter's default `FloatingActionButtonLocation.endFloat` places FABs at the bottom of the screen, directly colliding with or hiding behind the floating dock.

To prevent this collision, developers manually injected `Padding(padding: const EdgeInsets.only(bottom: 78))` into `floatingActionButton` across exactly 7 presentation screens:

1. **`lib/modules/ponds_batches/presentation/screens/ponds_dashboard_screen.dart` (lines 46–48)**:
   ```dart
   floatingActionButton: Padding(
     padding: const EdgeInsets.only(bottom: 78),
     child: Column(
   ```
2. **`lib/modules/warehouse_inventory/presentation/screens/warehouse_screen.dart` (lines 101–103)**:
   ```dart
   floatingActionButton: Padding(
     padding: const EdgeInsets.only(bottom: 78),
     child: FloatingActionButton.extended(
   ```
3. **`lib/modules/bitacora/presentation/screens/bitacora_screen.dart` (lines 429–431)**:
   ```dart
   floatingActionButton: Padding(
     padding: const EdgeInsets.only(bottom: 78),
     child: FloatingActionButton.extended(
   ```
4. **`lib/modules/water_quality/presentation/screens/water_quality_records_screen.dart` (lines 53–55)**:
   ```dart
   floatingActionButton: Padding(
     padding: const EdgeInsets.only(bottom: 78),
     child: FloatingActionButton.extended(
   ```
5. **`lib/modules/finance_payroll/presentation/screens/finance_screen.dart` (lines 56–58)**:
   ```dart
   floatingActionButton: Padding(
     padding: const EdgeInsets.only(bottom: 78),
     child: LayoutBuilder(
   ```
6. **`lib/modules/sales_harvest/presentation/screens/sales_screen.dart` (lines 43–45)**:
   ```dart
   floatingActionButton: Padding(
     padding: const EdgeInsets.only(bottom: 78),
     child: FloatingActionButton.extended(
   ```
7. **`lib/modules/auth_tenant/presentation/screens/gestion_equipo_screen.dart` (lines 25–27)**:
   ```dart
   floatingActionButton: Padding(
     padding: const EdgeInsets.only(bottom: 78),
     child: FloatingActionButton.extended(
   ```

### 1.3 Cascading Hardcoded Scroll Spacers
To prevent the last item of scrollable lists from being hidden behind the floating dock, arbitrary hardcoded spacers were scattered across screens:

1. **`lib/modules/home_dashboard/presentation/screens/home_dashboard_screen.dart` (line 333)**:
   ```dart
   const SizedBox(height: 100), // Espacio para el Dock de navegación
   ```
2. **`lib/modules/ponds_batches/presentation/screens/ponds_dashboard_screen.dart` (lines 365–367)**:
   ```dart
   const SliverToBoxAdapter(
     child: SizedBox(height: 100), // Espacio para el Dock Flotante
   ),
   ```
3. **`lib/modules/warehouse_inventory/presentation/screens/warehouse_screen.dart` (line 300)**:
   ```dart
   const SliverToBoxAdapter(child: SizedBox(height: 100)),
   ```
4. **`lib/modules/sales_harvest/presentation/screens/sales_screen.dart` (line 191)**:
   ```dart
   const SliverToBoxAdapter(child: SizedBox(height: 100)),
   ```
5. **`lib/modules/finance_payroll/presentation/screens/finance_screen.dart` (line 382)**:
   ```dart
   const SliverToBoxAdapter(child: SizedBox(height: 100)),
   ```
6. **`lib/modules/water_quality/presentation/screens/water_quality_records_screen.dart` (lines 201, 231)**:
   ```dart
   const SizedBox(height: 100),
   ```
7. **`lib/modules/ica_compliance/presentation/screens/ica_certification_screen.dart` (lines 556, 757, 839)**:
   ```dart
   const SizedBox(height: 80),
   ```
8. **`lib/core/design_system/glass_action_hub_sheet.dart` (lines 61–62)**:
   ```dart
   // Flota justo encima de la barra de navegación (bottom: 84px)
   padding: const EdgeInsets.only(left: 16, right: 16, bottom: 84),
   ```

---

## 2. Logic Chain

1. **Premise 1 (Disjoint Viewport Hierarchy)**: `MainNavigationShell` hosts a `Stack` where the body is an unconstrained `Positioned.fill` and the dock is a `Positioned` overlay. The inner screen widgets are independent `Scaffold` instances with no awareness of the floating dock.
2. **Premise 2 (Flawed Inset Geometry)**: In `MainNavigationShell`, `bottom: bottomPadding > 0 ? bottomPadding + 8 : 16` fails to employ `SafeArea(bottom: true)`. On iOS with a 34 dp home indicator, `bottom: 42 dp` places the dock near the gesture pill without formal safe area containment. On Android with 3-button navigation, `bottomPadding` is 0, placing the dock at 16 dp.
3. **Premise 3 (Inconsistent FAB Displacement)**:
   - On iOS (34 dp inset): The inner `Scaffold`'s default `FloatingActionButtonLocation.endFloat` applies `max(34, 0) + 16 (margin) = 50 dp`. When combined with the hardcoded `bottom: 78` padding, the FAB is pushed to `50 + 78 = 128 dp` from the bottom edge. Meanwhile, the dock top is at `34 + 8 + 60 = 102 dp`. This creates an uncoordinated 26 dp gap above the dock.
   - On Android 3-button / Desktop (0 dp inset): The FAB is at `0 + 16 + 78 = 94 dp`. The dock top is at `16 + 60 = 76 dp`. The gap is 18 dp.
   - The offset is fragile, non-adaptive, and brittle across devices.
4. **Premise 4 (Content Occlusion by Fixed Spacers)**:
   - On an iPhone 14/15/16 Pro, the dock top is at `106 dp` from the screen bottom (`34 dp inset + 12 dp margin + 60 dp dock`).
   - In `ica_certification_screen.dart`, the spacer is `SizedBox(height: 80)`. Because `80 < 106`, the bottom `26 dp` of cards in all 3 tabs are permanently occluded behind the dock when scrolled to the end.
   - In screens with `SizedBox(height: 100)`, `100 < 106`, causing a 6 dp occlusion on iPhones.
5. **Deduction & Solution**:
   - The layout system must encapsulate dock metrics into a formal design system layout contract (`FloatingDockLayout`).
   - `MainNavigationShell` must anchor the floating dock using `SafeArea(bottom: true)` with a consistent bottom breathing room (12 dp) and horizontal padding (16 dp), constrained to `maxWidth: 480`.
   - Virtual keyboard visibility must suppress or hide the floating dock so it does not jump above the keyboard into active form fields.
   - A dedicated `FloatingDockFabLocation` implementing Flutter's standard `FloatingActionButtonLocation` contract must replace all hardcoded `Padding(bottom: 78)` wrappers on FABs. It dynamically reads `scaffoldGeometry.minViewPadding.bottom` (and `viewInsets.bottom` for keyboards) and computes exact 16 dp spacing above the dock.
   - Standardized `DockBottomSpacer` and `SliverDockBottomSpacer` widgets must replace all hardcoded `SizedBox(height: 100/80)` instances.

---

## 3. Caveats

1. **Modal Sheets Rendered in Root Navigator**: Modals like `parametro_modal.dart`, `crear_estanque_modal.dart`, and `colilla_nomina_modal.dart` use `showModalBottomSheet` or `showDialog`. These are pushed onto the root `Navigator` overlay, rendering *above* `MainNavigationShell` and the floating dock. They do not require `FloatingDockFabLocation`.
2. **GlassActionHubSheet Interaction**: `GlassActionHubSheet` is an action sheet triggered directly by the "Más" dock button. It already utilizes `SafeArea(bottom: true)`. Its bottom offset `bottom: 84` corresponds to `dockBottomMargin (12) + dockHeight (58) + gap (14) = 84 dp`. Standardizing this with `FloatingDockLayout` avoids magical constants.
3. **No Breaking Changes to Screen Logic**: Modifying `floatingActionButtonLocation` on the 7 screens is a zero-regression change that does not affect any Riverpod providers, business logic, or user interaction state.

---

## 4. Conclusion & Implementation Blueprint for Worker M3

### File 1: Create `lib/core/design_system/floating_dock_layout.dart`
Create a centralized layout configuration and custom FAB location:

```dart
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
    final double keyboardInset = scaffoldGeometry.viewInsets.bottom;
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
```

---

### File 2: Update `lib/app/main_navigation_shell.dart`
Refactor lines 50–78:
- Wrap floating dock in `SafeArea(bottom: true)` with `Padding(fromLTRB(16, 0, 16, 12))`.
- Suppress dock when virtual keyboard is active (`isKeyboardOpen`).
- Export `FloatingDockFabLocation` and spacer classes for convenient consumer access.

```diff
--- a/lib/app/main_navigation_shell.dart
+++ b/lib/app/main_navigation_shell.dart
@@ -6,6 +6,7 @@
 import 'package:fishbit_finance/core/design_system/app_colors.dart';
 import 'package:fishbit_finance/core/design_system/glass_container.dart';
 import 'package:fishbit_finance/core/design_system/glass_action_hub_sheet.dart';
+export 'package:fishbit_finance/core/design_system/floating_dock_layout.dart';
 
 class MainNavigationShell extends ConsumerWidget {
   final Widget child;
@@ -51,9 +52,8 @@
   Widget build(BuildContext context, WidgetRef ref) {
     final selectedIndex = _calculateSelectedIndex(context);
     final isDark = Theme.of(context).brightness == Brightness.dark;
-
-    final bottomPadding = MediaQuery.of(context).padding.bottom;
-
+    final isKeyboardOpen = MediaQuery.viewInsetsOf(context).bottom > 0;
+
     return Scaffold(
       backgroundColor: Theme.of(context).scaffoldBackgroundColor,
       body: Stack(
@@ -61,12 +61,16 @@
           // Pantalla actual activa
           Positioned.fill(child: child),
 
-          // Barra Flotante Glassmorphic Bottom Dock (Estilo Apple macOS / iOS Dock)
-          Positioned(
-            left: 16,
-            right: 16,
-            bottom: bottomPadding > 0 ? bottomPadding + 8 : 16,
-            child: Center(
+          // Barra Flotante Glassmorphic Bottom Dock (Estilo Apple macOS / iOS Dock)
+          if (!isKeyboardOpen)
+            Positioned(
+              left: 0,
+              right: 0,
+              bottom: 0,
+              child: SafeArea(
+                bottom: true,
+                child: Padding(
+                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
+                  child: Center(
```

---

### File 3: Update `lib/core/design_system/glass_action_hub_sheet.dart`
Link bottom padding to `FloatingDockLayout`:

```diff
--- a/lib/core/design_system/glass_action_hub_sheet.dart
+++ b/lib/core/design_system/glass_action_hub_sheet.dart
@@ -5,6 +5,7 @@
 import 'package:fishbit_finance/core/design_system/app_typography.dart';
 import 'package:fishbit_finance/core/design_system/glass_card.dart';
 import 'package:fishbit_finance/core/design_system/glass_container.dart';
+import 'package:fishbit_finance/core/design_system/floating_dock_layout.dart';
 import 'package:fishbit_finance/modules/auth_tenant/domain/entities/user_model.dart';
 import 'package:fishbit_finance/modules/auth_tenant/presentation/providers/auth_provider.dart';
@@ -60,4 +61,4 @@
             child: Padding(
-              // Flota justo encima de la barra de navegación (bottom: 84px)
-              padding: const EdgeInsets.only(left: 16, right: 16, bottom: 84),
+              // Flota justo encima de la barra de navegación (dockHeight 58 + dockMargin 12 + 14 = 84px)
+              padding: const EdgeInsets.only(left: 16, right: 16, bottom: FloatingDockLayout.dockHeight + FloatingDockLayout.dockBottomMargin + 14.0),
```

---

### File 4–10: Clean up 7 Screens with FABs

#### 1. `lib/modules/ponds_batches/presentation/screens/ponds_dashboard_screen.dart`
```diff
--- a/lib/modules/ponds_batches/presentation/screens/ponds_dashboard_screen.dart
+++ b/lib/modules/ponds_batches/presentation/screens/ponds_dashboard_screen.dart
@@ -10,6 +10,7 @@
 import 'package:fishbit_finance/core/design_system/glass_card.dart';
 import 'package:fishbit_finance/core/design_system/fishbit_header.dart';
+import 'package:fishbit_finance/core/design_system/floating_dock_layout.dart';
@@ -44,4 +45,4 @@
     return Scaffold(
       backgroundColor: Theme.of(context).scaffoldBackgroundColor,
-      floatingActionButton: Padding(
-        padding: const EdgeInsets.only(bottom: 78),
-        child: Column(
+      floatingActionButtonLocation: FloatingDockFabLocation.endFloat,
+      floatingActionButton: Column(
@@ -134,2 +135,1 @@
-        ),
       ),
@@ -365,3 +365,1 @@
-                const SliverToBoxAdapter(
-                  child: SizedBox(height: 100), // Espacio para el Dock Flotante
-                ),
+                const SliverDockBottomSpacer(),
```

#### 2. `lib/modules/warehouse_inventory/presentation/screens/warehouse_screen.dart`
```diff
--- a/lib/modules/warehouse_inventory/presentation/screens/warehouse_screen.dart
+++ b/lib/modules/warehouse_inventory/presentation/screens/warehouse_screen.dart
@@ -9,6 +9,7 @@
 import 'package:fishbit_finance/core/design_system/glass_card.dart';
 import 'package:fishbit_finance/core/design_system/glass_date_picker_field.dart';
 import 'package:fishbit_finance/core/design_system/fishbit_header.dart';
+import 'package:fishbit_finance/core/design_system/floating_dock_layout.dart';
@@ -100,4 +101,4 @@
     return Scaffold(
       backgroundColor: Theme.of(context).scaffoldBackgroundColor,
-      floatingActionButton: Padding(
-        padding: const EdgeInsets.only(bottom: 78),
-        child: FloatingActionButton.extended(
+      floatingActionButtonLocation: FloatingDockFabLocation.endFloat,
+      floatingActionButton: FloatingActionButton.extended(
@@ -110,2 +111,1 @@
-        ),
       ),
@@ -300,1 +300,1 @@
-          const SliverToBoxAdapter(child: SizedBox(height: 100)),
+          const SliverDockBottomSpacer(),
```

#### 3. `lib/modules/bitacora/presentation/screens/bitacora_screen.dart`
```diff
--- a/lib/modules/bitacora/presentation/screens/bitacora_screen.dart
+++ b/lib/modules/bitacora/presentation/screens/bitacora_screen.dart
@@ -12,6 +12,7 @@
 import 'package:fishbit_finance/core/design_system/glass_date_picker_field.dart';
 import 'package:fishbit_finance/core/design_system/fishbit_header.dart';
+import 'package:fishbit_finance/core/design_system/floating_dock_layout.dart';
@@ -428,4 +429,4 @@
     return Scaffold(
       backgroundColor: Theme.of(context).scaffoldBackgroundColor,
-      floatingActionButton: Padding(
-        padding: const EdgeInsets.only(bottom: 78),
-        child: FloatingActionButton.extended(
+      floatingActionButtonLocation: FloatingDockFabLocation.endFloat,
+      floatingActionButton: FloatingActionButton.extended(
@@ -436,2 +437,1 @@
-        ),
       ),
```

#### 4. `lib/modules/water_quality/presentation/screens/water_quality_records_screen.dart`
```diff
--- a/lib/modules/water_quality/presentation/screens/water_quality_records_screen.dart
+++ b/lib/modules/water_quality/presentation/screens/water_quality_records_screen.dart
@@ -11,6 +11,7 @@
 import 'package:fishbit_finance/core/design_system/glass_date_picker_field.dart';
 import 'package:fishbit_finance/core/design_system/fishbit_header.dart';
+import 'package:fishbit_finance/core/design_system/floating_dock_layout.dart';
@@ -52,4 +53,4 @@
         backgroundColor: Theme.of(context).scaffoldBackgroundColor,
-        floatingActionButton: Padding(
-          padding: const EdgeInsets.only(bottom: 78),
-          child: FloatingActionButton.extended(
+        floatingActionButtonLocation: FloatingDockFabLocation.endFloat,
+        floatingActionButton: FloatingActionButton.extended(
@@ -60,2 +61,1 @@
-          ),
         ),
@@ -201,1 +201,1 @@
-                  const SizedBox(height: 100),
+                  const DockBottomSpacer(),
@@ -231,1 +231,1 @@
-                  const SizedBox(height: 100),
+                  const DockBottomSpacer(),
```

#### 5. `lib/modules/finance_payroll/presentation/screens/finance_screen.dart`
```diff
--- a/lib/modules/finance_payroll/presentation/screens/finance_screen.dart
+++ b/lib/modules/finance_payroll/presentation/screens/finance_screen.dart
@@ -13,6 +13,7 @@
 import 'package:fishbit_finance/core/design_system/fishbit_header.dart';
+import 'package:fishbit_finance/core/design_system/floating_dock_layout.dart';
@@ -55,4 +56,4 @@
     return Scaffold(
       backgroundColor: Theme.of(context).scaffoldBackgroundColor,
-      floatingActionButton: Padding(
-        padding: const EdgeInsets.only(bottom: 78),
-        child: LayoutBuilder(
+      floatingActionButtonLocation: FloatingDockFabLocation.endFloat,
+      floatingActionButton: LayoutBuilder(
@@ -98,2 +99,1 @@
-        ),
       ),
@@ -382,1 +382,1 @@
-          const SliverToBoxAdapter(child: SizedBox(height: 100)),
+          const SliverDockBottomSpacer(),
```

#### 6. `lib/modules/sales_harvest/presentation/screens/sales_screen.dart`
```diff
--- a/lib/modules/sales_harvest/presentation/screens/sales_screen.dart
+++ b/lib/modules/sales_harvest/presentation/screens/sales_screen.dart
@@ -10,6 +10,7 @@
 import 'package:fishbit_finance/core/design_system/glass_card.dart';
 import 'package:fishbit_finance/core/design_system/fishbit_header.dart';
+import 'package:fishbit_finance/core/design_system/floating_dock_layout.dart';
@@ -42,4 +43,4 @@
     return Scaffold(
       backgroundColor: Theme.of(context).scaffoldBackgroundColor,
-      floatingActionButton: Padding(
-        padding: const EdgeInsets.only(bottom: 78),
-        child: FloatingActionButton.extended(
+      floatingActionButtonLocation: FloatingDockFabLocation.endFloat,
+      floatingActionButton: FloatingActionButton.extended(
@@ -50,2 +51,1 @@
-        ),
       ),
@@ -191,1 +191,1 @@
-          const SliverToBoxAdapter(child: SizedBox(height: 100)),
+          const SliverDockBottomSpacer(),
```

#### 7. `lib/modules/auth_tenant/presentation/screens/gestion_equipo_screen.dart`
```diff
--- a/lib/modules/auth_tenant/presentation/screens/gestion_equipo_screen.dart
+++ b/lib/modules/auth_tenant/presentation/screens/gestion_equipo_screen.dart
@@ -7,6 +7,7 @@
 import 'package:fishbit_finance/core/design_system/app_typography.dart';
 import 'package:fishbit_finance/core/design_system/glass_card.dart';
 import 'package:fishbit_finance/core/design_system/fishbit_header.dart';
+import 'package:fishbit_finance/core/design_system/floating_dock_layout.dart';
@@ -24,4 +25,4 @@
     return Scaffold(
       backgroundColor: Theme.of(context).scaffoldBackgroundColor,
-      floatingActionButton: Padding(
-        padding: const EdgeInsets.only(bottom: 78),
-        child: FloatingActionButton.extended(
+      floatingActionButtonLocation: FloatingDockFabLocation.endFloat,
+      floatingActionButton: FloatingActionButton.extended(
@@ -33,2 +34,1 @@
-        ),
       ),
```

#### 8. Spacers Cleanup in `home_dashboard_screen.dart` and `ica_certification_screen.dart`
- **`home_dashboard_screen.dart:333`**: Replace `const SizedBox(height: 100), // Espacio para el Dock de navegación` with `const DockBottomSpacer(),`.
- **`ica_certification_screen.dart:556, 757, 839`**: Replace `const SizedBox(height: 80),` with `const DockBottomSpacer(),`.

---

## 5. Verification Method

### 5.1 Verification Commands
Run the Flutter static analysis command to verify 0 errors, 0 warnings:
```bash
flutter analyze --no-fatal-infos
```

Run the existing widget and unit test suites:
```bash
flutter test
```

### 5.2 File Inspection Checklist
- [ ] `lib/core/design_system/floating_dock_layout.dart` exists and exports `FloatingDockLayout`, `FloatingDockFabLocation`, `DockBottomSpacer`, `SliverDockBottomSpacer`.
- [ ] `lib/app/main_navigation_shell.dart` contains `SafeArea(bottom: true)` and has no `bottom: bottomPadding > 0 ? bottomPadding + 8 : 16`.
- [ ] Zero occurrences of `padding: const EdgeInsets.only(bottom: 78)` remain in `lib/`.
- [ ] All 7 screens with FABs use `floatingActionButtonLocation: FloatingDockFabLocation.endFloat`.
- [ ] In `ica_certification_screen.dart`, all 3 tabs have `const DockBottomSpacer()` instead of `const SizedBox(height: 80)`.

### 5.3 Invalidation Conditions
- If any FAB overlaps or collides with the dock on an iPhone layout simulation (`minViewPadding.bottom == 34.0`).
- If `flutter analyze` reports any unused imports, deprecated members, or typing issues with `FloatingDockFabLocation`.
- If on-screen keyboard opening causes the floating dock to obscure input elements.
