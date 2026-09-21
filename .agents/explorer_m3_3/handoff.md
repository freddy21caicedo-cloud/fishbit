# Handoff Report: Explorer M3_3 (High-Contrast Typography & Reactive Theme — A11Y-01)

## 1. Observation

### 1.1 Direct Inspection of `lib/core/design_system/app_typography.dart`
Lines 8–68 of `lib/core/design_system/app_typography.dart`:
```dart
class AppTypography {
  AppTypography._();

  static const TextStyle displayLarge = TextStyle(
    fontSize: 26,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.5,
    color: AppColors.textPrimaryDark, // 0xFFFFFFFF (Pure White)
  );

  static const TextStyle displayMedium = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.w600,
    letterSpacing: -0.3,
    color: AppColors.textPrimaryDark, // 0xFFFFFFFF
  );

  static const TextStyle titleLarge = TextStyle(
    fontSize: 17,
    fontWeight: FontWeight.w600,
    letterSpacing: -0.2,
    color: AppColors.textPrimaryDark, // 0xFFFFFFFF
  );

  static const TextStyle titleMedium = TextStyle(
    fontSize: 15,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimaryDark, // 0xFFFFFFFF
  );

  static const TextStyle titleSmall = TextStyle(
    fontSize: 13,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimaryDark, // 0xFFFFFFFF
  );

  static const TextStyle bodyMedium = TextStyle(
    fontSize: 13,
    fontWeight: FontWeight.w400,
    color: AppColors.textSecondaryDark, // 0xFF8E9BAE
    height: 1.4,
  );

  static const TextStyle bodySmall = TextStyle(
    fontSize: 11,
    fontWeight: FontWeight.w400,
    color: AppColors.textSecondaryDark, // 0xFF8E9BAE
  );

  static const TextStyle labelMicro = TextStyle(
    fontSize: 10,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.5,
    color: AppColors.textSecondaryDark, // 0xFF8E9BAE
  );

  static const TextStyle numberKpi = TextStyle(
    fontSize: 22,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.5,
    color: AppColors.textPrimaryDark, // 0xFFFFFFFF
    fontFeatures: [FontFeature.tabularFigures()],
  );
```
All 9 static base text styles hardcode dark mode colors:
- 6 styles hardcode `AppColors.textPrimaryDark` (`0xFFFFFFFF`).
- 3 styles hardcode `AppColors.textSecondaryDark` (`0xFF8E9BAE`).

### 1.2 Direct Inspection of `lib/core/design_system/theme_provider.dart`
Lines 43–76 of `lib/core/design_system/theme_provider.dart`:
```dart
/// Tema Oscuro Oficial FishBit (OLED Glassmorphism)
final appDarkTheme = ThemeData.dark().copyWith(
  scaffoldBackgroundColor: AppColors.backgroundDark,
  colorScheme: const ColorScheme.dark(
    primary: AppColors.cyanWater,
    secondary: AppColors.coralAction,
    surface: AppColors.surfaceDark,
  ),
  appBarTheme: const AppBarTheme(
    backgroundColor: AppColors.backgroundDark,
    elevation: 0,
  ),
);

/// Tema Claro Oficial FishBit (Apple Frosted Glass & Luxury Light)
final appLightTheme = ThemeData.light().copyWith(
  scaffoldBackgroundColor: AppColors.backgroundLight,
  canvasColor: AppColors.backgroundLight,
  cardColor: AppColors.surfaceLight,
  colorScheme: const ColorScheme.light(
    primary: AppColors.cyanWater,
    secondary: AppColors.coralAction,
    surface: AppColors.surfaceLight,
    onSurface: AppColors.textPrimaryLight,
    onPrimary: Colors.white,
  ),
  appBarTheme: const AppBarTheme(
    backgroundColor: AppColors.backgroundLight,
    elevation: 0,
    iconTheme: IconThemeData(color: AppColors.textPrimaryLight),
  ),
  dividerColor: AppColors.glassBorderLight,
);
```
- Neither `appDarkTheme` nor `appLightTheme` defines a `textTheme` or `primaryTextTheme`.
- In `appDarkTheme`, `colorScheme.onSurface` and `colorScheme.onBackground` are omitted.
- Material 3 type scale defaults are unconfigured, forcing widgets that rely on theme defaults or `AppTypography` constants into disconnected, non-reactive behavior.

### 1.3 Mathematical Relative Luminance and Contrast Ratio Audit (WCAG 2.2 AA)
Under standard WCAG 2.2 relative luminance formula:
$L = 0.2126 \times R_{lin} + 0.7152 \times G_{lin} + 0.0722 \times B_{lin}$
Contrast ratio: $\frac{L_1 + 0.05}{L_2 + 0.05}$

Surface luminance values:
- `surfaceLight` (`#FFFFFF`): $L = 1.0000$
- `backgroundLight` (`#F6F8FA`): $L = 0.9370$
- `surfaceDark` (`#101622`): $L = 0.0080$
- `backgroundDark` (`#070A0F`): $L = 0.0030$
- Dark card (`#1E293B`): $L = 0.0218$

Text and Accent color contrast metrics against target surfaces:

| Color Token | Hex | Target Surface | Contrast Ratio | WCAG 2.2 AA Standard (>=4.5:1) | WCAG 2.2 AA Large (>=3.0:1) | Assessment |
|---|---|---|---|---|---|---|
| `textPrimaryDark` | `#FFFFFF` | `surfaceLight` (`#FFFFFF`) | **1.00:1** | **FAIL** (0.22x required) | **FAIL** | ❌ Completely invisible |
| `textPrimaryDark` | `#FFFFFF` | `backgroundLight` (`#F6F8FA`) | **1.06:1** | **FAIL** | **FAIL** | ❌ Completely unreadable |
| `textSecondaryDark`| `#8E9BAE` | `surfaceLight` (`#FFFFFF`) | **2.81:1** | **FAIL** (0.62x required) | **FAIL** | ❌ Fails outdoor daylight |
| `textSecondaryDark`| `#8E9BAE` | `backgroundLight` (`#F6F8FA`) | **2.64:1** | **FAIL** | **FAIL** | ❌ Fails outdoor daylight |
| `textPrimaryDark` | `#FFFFFF` | `surfaceDark` (`#101622`) | **18.1:1** | **PASS** (AAA >= 7.0:1) | **PASS** | ✅ Excellent OLED luxury |
| `textSecondaryDark`| `#8E9BAE` | `surfaceDark` (`#101622`) | **6.44:1** | **PASS** (>= 4.5:1) | **PASS** | ✅ Compliant in Dark mode |
| `textPrimaryLight`| `#0F172A` | `surfaceLight` (`#FFFFFF`) | **17.8:1** | **PASS** (AAA >= 7.0:1) | **PASS** | ✅ High contrast in daylight |
| `textPrimaryLight`| `#0F172A` | `backgroundLight` (`#F6F8FA`) | **16.8:1** | **PASS** (AAA >= 7.0:1) | **PASS** | ✅ High contrast in daylight |
| `textSecondaryLight`| `#475569` | `surfaceLight` (`#FFFFFF`) | **7.49:1** | **PASS** (AAA >= 7.0:1) | **PASS** | ✅ Compliant in Light mode |
| `textSecondaryLight`| `#475569` | `backgroundLight` (`#F6F8FA`) | **7.05:1** | **PASS** (AAA >= 7.0:1) | **PASS** | ✅ Compliant in Light mode |
| `cyanWater` | `#00B2CC` | `surfaceDark` (`#101622`) | **7.11:1** | **PASS** | **PASS** | ✅ Excellent in Dark mode |
| `cyanWater` | `#00B2CC` | `surfaceLight` (`#FFFFFF`) | **2.54:1** | **FAIL** (0.56x required) | **FAIL** | ❌ Washed out in daylight |
| `greenBiomass` | `#10B981` | `surfaceDark` (`#101622`) | **7.16:1** | **PASS** | **PASS** | ✅ Excellent in Dark mode |
| `greenBiomass` | `#10B981` | `surfaceLight` (`#FFFFFF`) | **2.53:1** | **FAIL** (0.56x required) | **FAIL** | ❌ Washed out in daylight |
| `amberWarning` | `#FF9500` | `surfaceDark` (`#101622`) | **8.24:1** | **PASS** | **PASS** | ✅ Excellent in Dark mode |
| `amberWarning` | `#FF9500` | `surfaceLight` (`#FFFFFF`) | **2.20:1** | **FAIL** (0.49x required) | **FAIL** | ❌ Critical warning unreadable |
| `coralAction` | `#FF2D55` | `surfaceLight` (`#FFFFFF`) | **3.64:1** | **FAIL** (< 4.5:1) | **PASS** (>= 3.0:1) | ⚠️ Only passes large bold text |

### 1.4 Direct Codebase Usages Suffering From Text Invisibility / Low Contrast
Grep search across `lib/` identified 45+ consumer files. Representative instances:
- `lib/modules/water_quality/presentation/screens/water_quality_records_screen.dart` lines 181–189:
  ```dart
  Text('pH: ${(p.ph ?? 7.2).toStringAsFixed(1)}', style: AppTypography.bodySmall),
  Text('Temp: ${(p.temperaturaC ?? 28.0).toStringAsFixed(1)}°C', style: AppTypography.bodySmall),
  ```
  Uses `AppTypography.bodySmall` directly; renders in `#8E9BAE` on white cards (contrast 2.81:1, failing WCAG AA).
- `lib/modules/ponds_batches/presentation/screens/ponds_dashboard_screen.dart` lines 220–223:
  ```dart
  Text('ESTANQUES (${filteredPonds.length})', style: AppTypography.labelMicro.copyWith(color: AppColors.textSecondaryDark, letterSpacing: 1.2)),
  ```
  Hardcoded `textSecondaryDark` on `#F6F8FA` scaffold background (contrast 2.64:1).
- `lib/modules/ponds_batches/presentation/widgets/pond_bento_card.dart` line 332:
  ```dart
  Text('Talla Promedio: ...', style: AppTypography.labelMicro.copyWith(color: AppColors.textSecondaryDark)),
  ```
- `lib/modules/ponds_batches/presentation/screens/ponds_dashboard_screen.dart` lines 81–85 & 120–124:
  `style: AppTypography.titleSmall.copyWith(color: Colors.white)` inside dark container hardcoded even in light mode.
- `lib/modules/water_quality/presentation/dialogs/parametro_modal.dart` line 144:
  `Text('💧 Calidad de Agua', style: AppTypography.titleMedium.copyWith(color: Colors.white, fontWeight: FontWeight.w800))`
- `lib/core/design_system/glass_card.dart` and `glass_form_field.dart`:
  Developers previously resorted to manual ternary checks:
  `color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight`
  confirming that `AppTypography` was recognized as deficient for light theme.

---

## 2. Logic Chain

1. **Premise 1 (Observation 1.1)**: `AppTypography.displayLarge`, `titleMedium`, `bodyMedium`, etc. are defined as `static const TextStyle` instances with `color: AppColors.textPrimaryDark` (`#FFFFFF`) and `color: AppColors.textSecondaryDark` (`#8E9BAE`).
2. **Premise 2 (Observation 1.3)**: Pure white text (`#FFFFFF`) on light surfaces (`#FFFFFF` / `#F6F8FA`) produces an inverse contrast ratio of 1.00:1–1.06:1. Secondary dark text (`#8E9BAE`) on light surfaces produces a contrast ratio of 2.64:1–2.81:1. Both fall far below the WCAG 2.2 AA standard threshold of 4.5:1 for body/normal text and 3.0:1 for large text.
3. **Premise 3 (Observation 1.4)**: The codebase contains 45+ consumer files calling `AppTypography.xxx` directly or using `copyWith(...)`. When the app switches to `ThemeMode.light`, any widget that uses bare `AppTypography` without manual ternary overrides renders illegible or invisible text.
4. **Premise 4 (Observation 1.2)**: `theme_provider.dart` defines `appLightTheme` and `appDarkTheme` without configuring `ThemeData.textTheme` or setting `colorScheme.onSurface` for dark mode. As a result, Flutter's Material 3 text resolution cannot supply compliant fallback colors.
5. **Deduction 1 (Structural Decoupling)**: If `AppTypography` removes the hardcoded `color` attribute from its 9 static base constants (setting `color: null`), Flutter's `Text` widget automatically falls back to merging with `DefaultTextStyle.of(context)` provided by `Theme.of(context)`.
6. **Deduction 2 (Theme Integration)**: If `theme_provider.dart` populates `ThemeData.textTheme` with light- and dark-calibrated `TextTheme` instances (via `AppTypography.createTextTheme(brightness)`), all `DefaultTextStyle` instances across the app will resolve to `AppColors.textPrimaryLight` (`#0F172A`, contrast 17.8:1) in light mode and `AppColors.textPrimaryDark` (`#FFFFFF`, contrast 18.1:1) in dark mode.
7. **Deduction 3 (Backward Compatibility)**: Existing call sites (e.g. `AppTypography.titleMedium.copyWith(...)`) retain 100% syntactic and semantic validity as compile-time constants (`const TextStyle`) while gaining immediate dynamic theme adaptability without requiring a high-risk mass refactoring of 45+ files.
8. **Deduction 4 (Type-Safe Ergonomic API)**: Providing `AppTypography.of(context)` and the extension `context.appTypography` allows future and updated widgets to explicitly select theme-resolved text tokens (`displayLarge`, `titleMedium`, `bodyMedium`, `bodySmall`, etc.) with compile-time type safety.
9. **Deduction 5 (Outdoor Sunlight Resilience)**: Introducing calibrated high-contrast light variants for accent colors (`cyanWaterTextLight = #007A8C`, `greenBiomassTextLight = #047857`, `amberWarningTextLight = #B45309`, `coralActionTextLight = #BE123C`) ensures >= 4.5:1 contrast for colored labels in outdoor field conditions.

---

## 3. Caveats

1. **Ambient Sunlight vs. Screen Brightness**: Contrast ratios calculated here are strictly mathematical photometric WCAG 2.2 definitions under 100% display opacity. In direct tropical sunlight (>50,000 lux) with OLED panel glare, perceived contrast degrades by ~30–40%. For this reason, targeting >= 7.0:1 (WCAG AAA) for primary text (achieved by `textPrimaryLight` at 17.8:1) is crucial.
2. **Widgets with Manual `color: Colors.white` Overrides**: The decoupling of `AppTypography` will fix all usages that do not explicitly override `color`. However, widgets that contain explicit `copyWith(color: Colors.white)` (such as modal headers in `parametro_modal.dart` line 144 or `biometria_modal.dart` line 140) will still render white text unless those specific files are updated or the modal dialog surfaces are styled with dark backgrounds (`AppColors.surfaceDark`).
3. **Flutter 3.x Deprecations**: The proposed `TextTheme` implementation uses modern Material 3 typography names (`displayLarge`, `headlineLarge`, `titleMedium`, `bodyMedium`, `bodySmall`, `labelSmall`). It avoids deprecated Material 2 names (`headline1`, `bodyText1`, `subtitle1`).

---

## 4. Conclusion

The typography system must be upgraded through three coordinated changes:
1. **`lib/core/design_system/app_typography.dart`**:
   - Decouple static constants by removing hardcoded dark colors (`color: null`).
   - Add `AppTypographyData` with explicit `dark` and `light` token definitions.
   - Add `AppTypography.of(BuildContext context)` and `BuildContext.appTypography` extension.
   - Add `AppTypography.createTextTheme(Brightness brightness)` for `ThemeData`.
   - Preserve existing `titleOf`, `bodyOf`, `labelOf` helpers.
2. **`lib/core/design_system/theme_provider.dart`**:
   - Wire `AppTypography.createTextTheme(Brightness.dark)` into `appDarkTheme`.
   - Wire `AppTypography.createTextTheme(Brightness.light)` into `appLightTheme`.
   - Explicitly configure `onSurface`, `onBackground`, `appBarTheme.titleTextStyle`, and `dialogTheme`.
3. **`lib/core/design_system/app_colors.dart`**:
   - Add outdoor-ready high-contrast text variants for brand accents (`cyanWaterTextLight`, `greenBiomassTextLight`, `amberWarningTextLight`, `coralActionTextLight`, `purpleAnalyticsTextLight`) and the `AppColors.accentText(context, color)` resolver.

### Exact Proposed Code Diffs for Worker M3

#### Diff 1: `lib/core/design_system/app_typography.dart`
```dart
--- a/lib/core/design_system/app_typography.dart
+++ b/lib/core/design_system/app_typography.dart
@@ -1,68 +1,241 @@
+import 'dart:ui';
 import 'package:flutter/material.dart';
 import 'app_colors.dart';
 
-/// Escala tipográfica compacta y de alta legibilidad
+/// Escala tipográfica compacta y de alta legibilidad para FishBit Finance 2.0.
+/// Cumple con WCAG 2.2 AA (contraste >= 4.5:1 para texto normal y >= 3.0:1 para texto grande)
+/// tanto en modo oscuro (OLED Glassmorphism) como en modo claro (Luxury Light).
 class AppTypography {
   AppTypography._();
 
+  // ─── Estilos Base Estáticos (color: null para herencia reactiva del tema) ─────
+  // Al no fijar color estático oscuro, heredan reactivamente de DefaultTextStyle
+  // asegurando legibilidad inmediata en tema claro y tema oscuro sin romper código existente.
   static const TextStyle displayLarge = TextStyle(
     fontSize: 26,
     fontWeight: FontWeight.w700,
     letterSpacing: -0.5,
-    color: AppColors.textPrimaryDark,
   );
 
   static const TextStyle displayMedium = TextStyle(
     fontSize: 20,
     fontWeight: FontWeight.w600,
     letterSpacing: -0.3,
-    color: AppColors.textPrimaryDark,
   );
 
   static const TextStyle titleLarge = TextStyle(
     fontSize: 17,
     fontWeight: FontWeight.w600,
     letterSpacing: -0.2,
-    color: AppColors.textPrimaryDark,
   );
 
   static const TextStyle titleMedium = TextStyle(
     fontSize: 15,
     fontWeight: FontWeight.w600,
-    color: AppColors.textPrimaryDark,
   );
 
   static const TextStyle titleSmall = TextStyle(
     fontSize: 13,
     fontWeight: FontWeight.w600,
-    color: AppColors.textPrimaryDark,
   );
 
   static const TextStyle bodyMedium = TextStyle(
     fontSize: 13,
     fontWeight: FontWeight.w400,
-    color: AppColors.textSecondaryDark,
     height: 1.4,
   );
 
   static const TextStyle bodySmall = TextStyle(
     fontSize: 11,
     fontWeight: FontWeight.w400,
-    color: AppColors.textSecondaryDark,
   );
 
   static const TextStyle labelMicro = TextStyle(
     fontSize: 10,
     fontWeight: FontWeight.w600,
     letterSpacing: 0.5,
-    color: AppColors.textSecondaryDark,
   );
 
   static const TextStyle numberKpi = TextStyle(
     fontSize: 22,
     fontWeight: FontWeight.w700,
     letterSpacing: -0.5,
-    color: AppColors.textPrimaryDark,
     fontFeatures: [FontFeature.tabularFigures()],
   );
+
+  // ─── Acceso Adaptativo por Contexto (Theme-Aware) ───────────────────────────
+  static AppTypographyData of(BuildContext context) {
+    final isDark = Theme.of(context).brightness == Brightness.dark;
+    return isDark ? dark : light;
+  }
+
+  static const AppTypographyData dark = AppTypographyData._(
+    displayLarge: TextStyle(
+      fontSize: 26,
+      fontWeight: FontWeight.w700,
+      letterSpacing: -0.5,
+      color: AppColors.textPrimaryDark,
+    ),
+    displayMedium: TextStyle(
+      fontSize: 20,
+      fontWeight: FontWeight.w600,
+      letterSpacing: -0.3,
+      color: AppColors.textPrimaryDark,
+    ),
+    titleLarge: TextStyle(
+      fontSize: 17,
+      fontWeight: FontWeight.w600,
+      letterSpacing: -0.2,
+      color: AppColors.textPrimaryDark,
+    ),
+    titleMedium: TextStyle(
+      fontSize: 15,
+      fontWeight: FontWeight.w600,
+      color: AppColors.textPrimaryDark,
+    ),
+    titleSmall: TextStyle(
+      fontSize: 13,
+      fontWeight: FontWeight.w600,
+      color: AppColors.textPrimaryDark,
+    ),
+    bodyMedium: TextStyle(
+      fontSize: 13,
+      fontWeight: FontWeight.w400,
+      color: AppColors.textSecondaryDark,
+      height: 1.4,
+    ),
+    bodySmall: TextStyle(
+      fontSize: 11,
+      fontWeight: FontWeight.w400,
+      color: AppColors.textSecondaryDark,
+    ),
+    labelMicro: TextStyle(
+      fontSize: 10,
+      fontWeight: FontWeight.w600,
+      letterSpacing: 0.5,
+      color: AppColors.textSecondaryDark,
+    ),
+    numberKpi: TextStyle(
+      fontSize: 22,
+      fontWeight: FontWeight.w700,
+      letterSpacing: -0.5,
+      color: AppColors.textPrimaryDark,
+      fontFeatures: [FontFeature.tabularFigures()],
+    ),
+  );
+
+  static const AppTypographyData light = AppTypographyData._(
+    displayLarge: TextStyle(
+      fontSize: 26,
+      fontWeight: FontWeight.w700,
+      letterSpacing: -0.5,
+      color: AppColors.textPrimaryLight,
+    ),
+    displayMedium: TextStyle(
+      fontSize: 20,
+      fontWeight: FontWeight.w600,
+      letterSpacing: -0.3,
+      color: AppColors.textPrimaryLight,
+    ),
+    titleLarge: TextStyle(
+      fontSize: 17,
+      fontWeight: FontWeight.w600,
+      letterSpacing: -0.2,
+      color: AppColors.textPrimaryLight,
+    ),
+    titleMedium: TextStyle(
+      fontSize: 15,
+      fontWeight: FontWeight.w600,
+      color: AppColors.textPrimaryLight,
+    ),
+    titleSmall: TextStyle(
+      fontSize: 13,
+      fontWeight: FontWeight.w600,
+      color: AppColors.textPrimaryLight,
+    ),
+    bodyMedium: TextStyle(
+      fontSize: 13,
+      fontWeight: FontWeight.w400,
+      color: AppColors.textSecondaryLight,
+      height: 1.4,
+    ),
+    bodySmall: TextStyle(
+      fontSize: 11,
+      fontWeight: FontWeight.w400,
+      color: AppColors.textSecondaryLight,
+    ),
+    labelMicro: TextStyle(
+      fontSize: 10,
+      fontWeight: FontWeight.w600,
+      letterSpacing: 0.5,
+      color: AppColors.textSecondaryLight,
+    ),
+    numberKpi: TextStyle(
+      fontSize: 22,
+      fontWeight: FontWeight.w700,
+      letterSpacing: -0.5,
+      color: AppColors.textPrimaryLight,
+      fontFeatures: [FontFeature.tabularFigures()],
+    ),
+  );
+
+  // ─── Generador de TextTheme para ThemeData (Material 3) ─────────────────────
+  static TextTheme createTextTheme(Brightness brightness) {
+    final isDark = brightness == Brightness.dark;
+    final primary = isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight;
+    final secondary = isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight;
+
+    return TextTheme(
+      displayLarge: TextStyle(
+        fontSize: 26,
+        fontWeight: FontWeight.w700,
+        letterSpacing: -0.5,
+        color: primary,
+      ),
+      displayMedium: TextStyle(
+        fontSize: 20,
+        fontWeight: FontWeight.w600,
+        letterSpacing: -0.3,
+        color: primary,
+      ),
+      displaySmall: TextStyle(
+        fontSize: 18,
+        fontWeight: FontWeight.w600,
+        letterSpacing: -0.2,
+        color: primary,
+      ),
+      headlineLarge: TextStyle(
+        fontSize: 22,
+        fontWeight: FontWeight.w700,
+        letterSpacing: -0.5,
+        color: primary,
+        fontFeatures: const [FontFeature.tabularFigures()],
+      ),
+      headlineMedium: TextStyle(
+        fontSize: 18,
+        fontWeight: FontWeight.w600,
+        color: primary,
+      ),
+      headlineSmall: TextStyle(
+        fontSize: 16,
+        fontWeight: FontWeight.w600,
+        color: primary,
+      ),
+      titleLarge: TextStyle(
+        fontSize: 17,
+        fontWeight: FontWeight.w600,
+        letterSpacing: -0.2,
+        color: primary,
+      ),
+      titleMedium: TextStyle(
+        fontSize: 15,
+        fontWeight: FontWeight.w600,
+        color: primary,
+      ),
+      titleSmall: TextStyle(
+        fontSize: 13,
+        fontWeight: FontWeight.w600,
+        color: primary,
+      ),
+      bodyLarge: TextStyle(
+        fontSize: 15,
+        fontWeight: FontWeight.w400,
+        color: primary,
+      ),
+      bodyMedium: TextStyle(
+        fontSize: 13,
+        fontWeight: FontWeight.w400,
+        color: primary,
+        height: 1.4,
+      ),
+      bodySmall: TextStyle(
+        fontSize: 11,
+        fontWeight: FontWeight.w400,
+        color: secondary,
+      ),
+      labelLarge: TextStyle(
+        fontSize: 12,
+        fontWeight: FontWeight.w600,
+        letterSpacing: 0.5,
+        color: primary,
+      ),
+      labelMedium: TextStyle(
+        fontSize: 10,
+        fontWeight: FontWeight.w600,
+        letterSpacing: 0.5,
+        color: secondary,
+      ),
+      labelSmall: TextStyle(
+        fontSize: 9,
+        fontWeight: FontWeight.w600,
+        letterSpacing: 0.5,
+        color: secondary,
+      ),
+    );
+  }
 
   // ─── Helpers Adaptativos por Contexto de Tema (Dark / Light - WCAG 2.2 AA) ──
   static TextStyle titleOf(BuildContext context, {double fontSize = 15, FontWeight fontWeight = FontWeight.w700}) {
@@ -95,4 +268,30 @@
     );
   }
 }
+
+/// Contenedor inmutable de estilos resueltos por tema
+class AppTypographyData {
+  final TextStyle displayLarge;
+  final TextStyle displayMedium;
+  final TextStyle titleLarge;
+  final TextStyle titleMedium;
+  final TextStyle titleSmall;
+  final TextStyle bodyMedium;
+  final TextStyle bodySmall;
+  final TextStyle labelMicro;
+  final TextStyle numberKpi;
+
+  const AppTypographyData._({
+    required this.displayLarge,
+    required this.displayMedium,
+    required this.titleLarge,
+    required this.titleMedium,
+    required this.titleSmall,
+    required this.bodyMedium,
+    required this.bodySmall,
+    required this.labelMicro,
+    required this.numberKpi,
+  });
+}
+
+/// Extensión de conveniencia en BuildContext
+extension AppTypographyContextExtension on BuildContext {
+  AppTypographyData get appTypography => AppTypography.of(this);
+}
```

#### Diff 2: `lib/core/design_system/theme_provider.dart`
```dart
--- a/lib/core/design_system/theme_provider.dart
+++ b/lib/core/design_system/theme_provider.dart
@@ -2,6 +2,7 @@
 import 'package:flutter_riverpod/flutter_riverpod.dart';
 import 'package:shared_preferences/shared_preferences.dart';
 import 'package:fishbit_finance/core/design_system/app_colors.dart';
+import 'package:fishbit_finance/core/design_system/app_typography.dart';
 
 class ThemeModeNotifier extends StateNotifier<ThemeMode> {
   static const _themePrefKey = 'fishbit_app_theme_mode';
@@ -47,11 +48,22 @@
   scaffoldBackgroundColor: AppColors.backgroundDark,
   colorScheme: const ColorScheme.dark(
     primary: AppColors.cyanWater,
     secondary: AppColors.coralAction,
     surface: AppColors.surfaceDark,
+    onSurface: AppColors.textPrimaryDark,
+    onBackground: AppColors.textPrimaryDark,
   ),
   appBarTheme: const AppBarTheme(
     backgroundColor: AppColors.backgroundDark,
     elevation: 0,
+    iconTheme: IconThemeData(color: AppColors.textPrimaryDark),
+    titleTextStyle: TextStyle(
+      color: AppColors.textPrimaryDark,
+      fontSize: 17,
+      fontWeight: FontWeight.w600,
+    ),
   ),
+  textTheme: AppTypography.createTextTheme(Brightness.dark),
+  dialogTheme: const DialogTheme(
+    backgroundColor: AppColors.surfaceDark,
+  ),
 );
 
 /// Tema Claro Oficial FishBit (Apple Frosted Glass & Luxury Light)
@@ -64,9 +76,19 @@
     surface: AppColors.surfaceLight,
     onSurface: AppColors.textPrimaryLight,
+    onBackground: AppColors.textPrimaryLight,
     onPrimary: Colors.white,
   ),
   appBarTheme: const AppBarTheme(
     backgroundColor: AppColors.backgroundLight,
     elevation: 0,
     iconTheme: IconThemeData(color: AppColors.textPrimaryLight),
+    titleTextStyle: TextStyle(
+      color: AppColors.textPrimaryLight,
+      fontSize: 17,
+      fontWeight: FontWeight.w600,
+    ),
   ),
+  textTheme: AppTypography.createTextTheme(Brightness.light),
+  dialogTheme: const DialogTheme(
+    backgroundColor: AppColors.surfaceLight,
+  ),
   dividerColor: AppColors.glassBorderLight,
 );
```

#### Diff 3: `lib/core/design_system/app_colors.dart` (Optional Accent Enhancement)
```dart
--- a/lib/core/design_system/app_colors.dart
+++ b/lib/core/design_system/app_colors.dart
@@ -32,6 +32,23 @@
   static const Color textPrimaryDark = Color(0xFFFFFFFF);
   static const Color textSecondaryDark = Color(0xFF8E9BAE);
   static const Color textTertiaryDark = Color(0xFF4B5563);
 
   static const Color textPrimaryLight = Color(0xFF0F172A);  // Midnight Slate (Alto contraste)
   static const Color textSecondaryLight = Color(0xFF475569);// Neutral Slate
   static const Color textTertiaryLight = Color(0xFF64748B); // Muted Slate
+
+  // ─── Variantes Adaptativas para Texto de Alto Contraste (WCAG 2.2 AA >= 4.5:1) ──
+  static const Color cyanWaterTextLight = Color(0xFF007A8C);     // 5.1:1 en blanco
+  static const Color greenBiomassTextLight = Color(0xFF047857);   // 5.2:1 en blanco
+  static const Color amberWarningTextLight = Color(0xFFB45309);   // 4.6:1 en blanco
+  static const Color coralActionTextLight = Color(0xFFBE123C);    // 5.4:1 en blanco
+  static const Color purpleAnalyticsTextLight = Color(0xFF6D28D9); // 6.5:1 en blanco
+
+  /// Selector reactivo de color de acento para texto según brillo del tema
+  static Color accentText(BuildContext context, Color darkColor) {
+    final isDark = Theme.of(context).brightness == Brightness.dark;
+    if (isDark) return darkColor;
+    if (darkColor == cyanWater) return cyanWaterTextLight;
+    if (darkColor == greenBiomass || darkColor == waterOptimal) return greenBiomassTextLight;
+    if (darkColor == amberWarning || darkColor == waterCaution) return amberWarningTextLight;
+    if (darkColor == coralAction || darkColor == waterCritical) return coralActionTextLight;
+    if (darkColor == purpleAnalytics) return purpleAnalyticsTextLight;
+    return darkColor;
+  }
```

---

## 5. Verification Method

### 5.1 Static Analysis Verification
Run:
```powershell
flutter analyze --no-fatal-infos
```
Expected: 0 errors, 0 warnings.
Verifies that all `AppTypography` static members remain accessible, `AppTypography.of(context)` functions properly, and `theme_provider.dart` builds without import or typing discrepancies.

### 5.2 Unit Test Verification Plan
Create `test/core/typography_contrast_test.dart` to verify WCAG 2.2 AA compliance:
```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fishbit_finance/core/design_system/app_colors.dart';
import 'package:fishbit_finance/core/design_system/app_typography.dart';
import 'package:fishbit_finance/core/design_system/theme_provider.dart';

double relativeLuminance(Color color) {
  double linearize(double channel) {
    return channel <= 0.04045
        ? channel / 12.92
        : ((channel + 0.055) / 1.055) * ((channel + 0.055) / 1.055); // approx 2.4
  }
  final r = linearize(color.red / 255.0);
  final g = linearize(color.green / 255.0);
  final b = linearize(color.blue / 255.0);
  return 0.2126 * r + 0.7152 * g + 0.0722 * b;
}

double contrastRatio(Color c1, Color c2) {
  final l1 = relativeLuminance(c1);
  final l2 = relativeLuminance(c2);
  final lighter = l1 > l2 ? l1 : l2;
  final darker = l1 > l2 ? l2 : l1;
  return (lighter + 0.05) / (darker + 0.05);
}

void main() {
  group('WCAG 2.2 AA Typography & Contrast Compliance Tests', () {
    test('Light theme text colors must exceed 4.5:1 against surfaceLight', () {
      expect(contrastRatio(AppColors.textPrimaryLight, AppColors.surfaceLight), greaterThanOrEqualTo(4.5));
      expect(contrastRatio(AppColors.textSecondaryLight, AppColors.surfaceLight), greaterThanOrEqualTo(4.5));
    });

    test('Dark theme text colors must exceed 4.5:1 against surfaceDark', () {
      expect(contrastRatio(AppColors.textPrimaryDark, AppColors.surfaceDark), greaterThanOrEqualTo(4.5));
      expect(contrastRatio(AppColors.textSecondaryDark, AppColors.surfaceDark), greaterThanOrEqualTo(4.5));
    });

    test('AppTypography.light must have high contrast light colors', () {
      expect(AppTypography.light.titleMedium.color, equals(AppColors.textPrimaryLight));
      expect(AppTypography.light.bodyMedium.color, equals(AppColors.textSecondaryLight));
    });

    test('AppTypography.dark must have high contrast dark colors', () {
      expect(AppTypography.dark.titleMedium.color, equals(AppColors.textPrimaryDark));
      expect(AppTypography.dark.bodyMedium.color, equals(AppColors.textSecondaryDark));
    });

    test('AppTypography static constants have color == null for theme inheritance', () {
      expect(AppTypography.displayLarge.color, isNull);
      expect(AppTypography.titleMedium.color, isNull);
      expect(AppTypography.bodyMedium.color, isNull);
      expect(AppTypography.bodySmall.color, isNull);
      expect(AppTypography.labelMicro.color, isNull);
    });

    testWidgets('AppTypography inherits DefaultTextStyle color in Light mode', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: appLightTheme,
          home: const Scaffold(
            body: Text('Test', style: AppTypography.titleMedium),
          ),
        ),
      );

      final textWidget = tester.widget<Text>(find.text('Test'));
      expect(textWidget.style?.color, isNull); // Inherits from DefaultTextStyle

      final defaultTextStyle = tester.widget<DefaultTextStyle>(
        find.ancestor(of: find.text('Test'), matching: find.byType(DefaultTextStyle)).first,
      );
      expect(defaultTextStyle.style.color, equals(AppColors.textPrimaryLight));
    });
  });
}
```

### 5.3 Invalidation Conditions
- Any static TextStyle in `AppTypography` that fixes `color: AppColors.textPrimaryDark` invalidates light-theme compatibility.
- Modifying `appLightTheme` without assigning `textTheme: AppTypography.createTextTheme(Brightness.light)` causes Material widgets to fall back to uncalibrated defaults.
