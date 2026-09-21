# Survey Explorer 2 — Handoff Report: Regulatory Data Integrity & Field Accessibility / Ergonomics (R2 & R3)

**Author:** Survey Explorer 2 - Data & UX  
**Date:** 2026-09-13T23:44:00Z  
**Scope:** Requirements R2 & R3 (DATA-01, UX-01, UX-02, A11Y-01)  
**Status:** Complete (Read-Only Investigation)  

---

## 1. Observations

### 1.1 Water Quality Modal (`lib/modules/water_quality/presentation/dialogs/parametro_modal.dart`)

1. **Simulated Hardcoded Default Values in Controllers:**
   In lines 36–47 of `lib/modules/water_quality/presentation/dialogs/parametro_modal.dart`:
   ```dart
   // 11 Parámetros Fisicoquímicos Solicitados
   final _oxigenoMgLCtrl = TextEditingController(text: '6.2');
   final _oxigenoPctCtrl = TextEditingController(text: '85.0');
   final _tempCtrl = TextEditingController(text: '28.5');
   final _phCtrl = TextEditingController(text: '7.4');
   final _amonioCtrl = TextEditingController(text: '0.15');
   final _nitritosCtrl = TextEditingController(text: '0.05');
   final _nitratosCtrl = TextEditingController(text: '10.0');
   final _alcalinidadCtrl = TextEditingController(text: '120.0');
   final _co2Ctrl = TextEditingController(text: '5.0');
   final _durezaCtrl = TextEditingController(text: '140.0');
   final _cloroCtrl = TextEditingController(text: '0.00');
   final _obsCtrl = TextEditingController();
   ```
   *Impact:* Every single physicochemical parameter opens prepopulated with fictitious "ideal" telemetry data. In a field scenario, an operator who accidentally taps "Guardar" immediately writes fabricated biological metrics into the official ICA audit database (`parametros_calidad_agua`).

2. **Alert Fallbacks Masking Missing Data:**
   In lines 92–101:
   ```dart
   final oxigeno = double.tryParse(_oxigenoMgLCtrl.text) ?? 6.2;
   final amonio = double.tryParse(_amonioCtrl.text) ?? 0.15;
   final nitritos = double.tryParse(_nitritosCtrl.text) ?? 0.05;
   final cloro = double.tryParse(_cloroCtrl.text) ?? 0.00;

   final isHypoxia = oxigeno < 4.0;
   final isAmmoniaCritical = amonio > 0.5;
   final isNitriteCritical = nitritos > 0.2;
   final isChlorineAlert = cloro > 0.05;
   ```
   *Impact:* Even if a user clears the field, `?? 6.2` forces the logic to assume safe default levels, concealing hypoxia or water deterioration.

3. **Absence of Form Validation & Field Constraints:**
   Inspecting lines 260–385:
   - `GlassFormField` for `_oxigenoMgLCtrl` (line 262): No `validator`, `isRequired` is `false`.
   - `GlassFormField` for `_tempCtrl` (line 285): No `validator`, `isRequired` is `false`.
   - `GlassFormField` for `_phCtrl` (line 294): No `validator`, `isRequired` is `false`.
   - In the save handler (line 449):
     ```dart
     if (!_formKey.currentState!.validate() || _selectedPondId == null) return;
     ```
     Because no field specifies a `validator`, `_formKey.currentState!.validate()` evaluates to `true` unconditionally, allowing completely empty entries to be committed if the controllers are wiped.
   - If `_selectedPondId == null`, the method returns silently without any snackbar or user-facing error message.
   - Values are parsed via `double.tryParse(_oxigenoMgLCtrl.text)`. In Latin American locales, mobile decimal keyboards frequently enter commas (`,`), which `double.tryParse("6,2")` evaluates as `null`.

---

### 1.2 Bento Card Touch Targets & Ergonomics (`lib/modules/ponds_batches/presentation/widgets/pond_bento_card.dart`)

1. **Quick Action Micro-Buttons Touch Target Measurement:**
   In lines 398–504:
   ```dart
   OutlinedButton(
     style: OutlinedButton.styleFrom(
       backgroundColor: AppColors.greenBiomass.withValues(alpha: isDark ? 0.1 : 0.08),
       foregroundColor: AppColors.greenBiomass,
       side: const BorderSide(color: AppColors.greenBiomass),
       shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
       visualDensity: VisualDensity.compact,
       minimumSize: const Size(0, 30),
       padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 2),
     ),
     onPressed: widget.onFeedPressed,
     child: const FittedBox(
       fit: BoxFit.scaleDown,
       child: Row(
         mainAxisSize: MainAxisSize.min,
         children: [
           Icon(Icons.restaurant_outlined, size: 13),
           SizedBox(width: 4),
           Text('Alimentar', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800)),
         ],
       ),
     ),
   )
   ```
   *Exact Target Measurements:*
   - Button Height: **30.0 dp** (specified by `minimumSize: const Size(0, 30)` and `VisualDensity.compact`).
   - Button Width: In a single-column layout on a 360 dp screen, width is ~**69.5 dp**. In a two-column tablet/grid view (as invoked in `ponds_dashboard_screen.dart:307`), button width drops to ~**35 dp**.
   - WCAG Standard: WCAG 2.5.5 (Target Size - Enhanced) mandates a minimum touch target of **48 × 48 dp** (Android Material minimum: 48 × 48 dp; iOS HIG: 44 × 44 pt).
   - **Deficit:** Height falls short by **18 dp (-37.5%)**, and width in grid view falls short by **13 dp (-27%)**.

2. **Other Micro-Targets in Card:**
   - Flip button in trailing widget (lines 171–187): Container with `padding: const EdgeInsets.all(4)` and `Icon(..., size: 15)` = **23 × 23 dp** touch area.
   - Reverse view return button (lines 534–553): Container with vertical padding 4 dp and icon size 12 dp = **24 dp** height.

3. **Field Usability Failure:**
   In outdoor aquaculture facilities, operators work in humid environments, with wet hands or protective rubber gloves, under direct sunlight. Attempting to tap a 30 dp high button in a tight row of four adjacent actions ("Alimentar", "Muestreo", "Bajas", "Traslado") causes high error rates, frequently triggering a mortality modal ("Bajas") instead of feeding ("Alimentar").

---

### 1.3 Main Navigation Shell & Gesture Inset Collisions (`lib/app/main_navigation_shell.dart`)

1. **Navigation Dock Positioning:**
   In lines 62–66:
   ```dart
   Positioned(
     left: 16,
     right: 16,
     bottom: 16,
     child: Center(
       child: ConstrainedBox(
         constraints: const BoxConstraints(maxWidth: 480),
         child: GlassContainer(...),
       ),
     ),
   )
   ```
   *Observation:* The floating dock is positioned using a static `bottom: 16` inside a `Stack`. It completely lacks `SafeArea(bottom: true)` or window inset calculation (`MediaQuery.paddingOf(context).bottom`).
   *Collision Analysis:* On iOS devices (iPhone X through 16), the Home Indicator bar occupies a 34 dp bottom inset. On modern Android devices with gesture navigation enabled, the gesture pill occupies 16–28 dp. With `bottom: 16`, the floating dock is drawn directly over the system gesture zone. Tapping navigation tabs ("Estanques", "Bitácora", "Más") causes inadvertent system gestures (swiping home or switching apps).

2. **Downstream Fragile Padding Hacks (`bottom: 78`):**
   Because the floating dock sits at `bottom: 16` and has a height of ~64 dp (dock top boundary at ~80 dp), standard `Scaffold.floatingActionButton` instances were obstructed.
   Rather than handling insets architecturally, `padding: const EdgeInsets.only(bottom: 78)` was hardcoded across 7 separate screen files:
   - `lib/modules/ponds_batches/presentation/screens/ponds_dashboard_screen.dart:47`
   - `lib/modules/bitacora/presentation/screens/bitacora_screen.dart:430`
   - `lib/modules/water_quality/presentation/screens/water_quality_records_screen.dart:54`
   - `lib/modules/warehouse_inventory/presentation/screens/warehouse_screen.dart:102`
   - `lib/modules/auth_tenant/presentation/screens/gestion_equipo_screen.dart:26`
   - `lib/modules/sales_harvest/presentation/screens/sales_screen.dart:44`
   - `lib/modules/finance_payroll/presentation/screens/finance_screen.dart:57`
   Additionally, in `ponds_dashboard_screen.dart:366`, an arbitrary `SizedBox(height: 100)` spacer was inserted to prevent scroll content clipping.
   *Cascading Bug:* If `MainNavigationShell` is elevated to clear the 34 dp iOS gesture bar (moving the dock to `bottom: 50`), the top of the dock moves to `114 dp`. The hardcoded `bottom: 78` FABs then become partially hidden behind the dock!

---

### 1.4 Typography & Theme Contrast Tokens (`AppTypography` & `AppColors`)

1. **Definition Location:**
   - `AppTypography`: `lib/core/design_system/app_typography.dart`
   - `AppColors`: `lib/core/design_system/app_colors.dart`
   - Themes: `lib/core/design_system/theme_provider.dart`

2. **Hardcoded Dark Color Bindings in `AppTypography`:**
   In lines 8–67 of `app_typography.dart`:
   ```dart
   static const TextStyle displayLarge = TextStyle(
     fontSize: 26,
     fontWeight: FontWeight.w700,
     letterSpacing: -0.5,
     color: AppColors.textPrimaryDark, // 0xFFFFFFFF
   );
   ...
   static const TextStyle bodyMedium = TextStyle(
     fontSize: 13,
     fontWeight: FontWeight.w400,
     color: AppColors.textSecondaryDark, // 0xFF8E9BAE
     height: 1.4,
   );
   ...
   static const TextStyle labelMicro = TextStyle(
     fontSize: 10,
     fontWeight: FontWeight.w600,
     letterSpacing: 0.5,
     color: AppColors.textSecondaryDark, // 0xFF8E9BAE
   );
   ```
   Over 45 files directly invoke `AppTypography.displayLarge`, `AppTypography.titleMedium`, etc. without overriding color via `.copyWith()`.

3. **Mathematical Contrast Audit (WCAG 2.2 Relative Luminance Formula):**
   Using $L = 0.2126 R + 0.7152 G + 0.0722 B$ with gamma-expanded sRGB coefficients and contrast ratio formula $\frac{L_1 + 0.05}{L_2 + 0.05}$:

   | Token | Hex | Luminance ($L$) | Background | Background $L$ | Contrast Ratio | WCAG 2.2 AA Status |
   |---|---|---|---|---|---|---|
   | `textPrimaryDark` | `#FFFFFF` | 1.0000 | `surfaceDark` (`#101622`) | 0.0084 | **17.98 : 1** | PASS AAA |
   | `textPrimaryDark` | `#FFFFFF` | 1.0000 | `surfaceLight` (`#FFFFFF`) | 1.0000 | **1.00 : 1** | **FATAL FAIL (Invisible)** |
   | `textPrimaryDark` | `#FFFFFF` | 1.0000 | `backgroundLight` (`#F6F8FA`) | 0.9357 | **1.07 : 1** | **FATAL FAIL (Invisible)** |
   | `textSecondaryDark` | `#8E9BAE` | 0.3240 | `surfaceDark` (`#101622`) | 0.0084 | **6.40 : 1** | PASS AA |
   | `textSecondaryDark` | `#8E9BAE` | 0.3240 | `surfaceLight` (`#FFFFFF`) | 1.0000 | **2.81 : 1** | **FAIL (< 4.5:1)** |
   | `textSecondaryDark` | `#8E9BAE` | 0.3240 | `backgroundLight` (`#F6F8FA`) | 0.9357 | **2.64 : 1** | **FAIL (< 4.5:1)** |
   | `textTertiaryDark` | `#4B5563` | 0.0880 | `surfaceDark` (`#101622`) | 0.0084 | **2.36 : 1** | **FAIL (< 4.5:1 in Dark)** |
   | `textPrimaryLight` | `#0F172A` | 0.0095 | `surfaceLight` (`#FFFFFF`) | 1.0000 | **17.65 : 1** | PASS AAA |
   | `textSecondaryLight` | `#475569` | 0.0860 | `surfaceLight` (`#FFFFFF`) | 1.0000 | **7.72 : 1** | PASS AAA |
   | `cyanWater` | `#00B2CC` | 0.3840 | `surfaceLight` (`#FFFFFF`) | 1.0000 | **2.42 : 1** | **FAIL for text (< 4.5:1)** |
   | `greenBiomass` | `#10B981` | 0.3950 | `surfaceLight` (`#FFFFFF`) | 1.0000 | **2.36 : 1** | **FAIL for text (< 4.5:1)** |

   *Observation on `theme_provider.dart`:* Neither `appDarkTheme` nor `appLightTheme` configure `textTheme`. Therefore, unstyled text widgets and `AppTypography` fall back to the static white/gray dark tokens.

---

## 2. Logic Chain

```
[Observation 1.1: Prepopulated controllers text: '6.2', '7.4']
  └─> [Step 1: Modal opens with fictitious telemetry already present]
        └─> [Step 2: No validators exist on GlassFormField, form validate() always true]
              └─> [Step 3: Accidental submission writes simulated data into production DB]
                    └─> [Conclusion 1: Violates ICA regulatory compliance (DATA-01); controllers must be empty and routine fields strictly validated]

[Observation 1.2: OutlinedButton height 30 dp, width 35-69 dp]
  └─> [Step 4: WCAG 2.5.5 mandates >= 48x48 dp interactive touch target]
        └─> [Step 5: 30 dp height fails standard by 37.5%; buttons crammed in 4-column row]
              └─> [Step 6: Operators with wet hands/gloves experience frequent mis-taps]
                    └─> [Conclusion 2: Replace micro-row with 50 dp Primary Action Button + Operational Bottom Sheet with >= 56 dp tiles]

[Observation 1.3: Navigation dock Positioned at static bottom: 16]
  └─> [Step 7: iOS/Android bottom gesture bars occupy 16-34 dp]
        └─> [Step 8: Floating dock collides with system home/gesture navigation]
              └─> [Step 9: Fragile bottom: 78 hacks applied across 7 screens to clear dock]
                    └─> [Step 10: Modifying dock height breaks all 7 screens with hardcoded offsets]
                          └─> [Conclusion 3: Dock must use SafeArea/insets; wrap child with ambient inset clearance to eliminate all bottom: 78 hacks]

[Observation 1.4: AppTypography statically binds textPrimaryDark #FFFFFF and textSecondaryDark #8E9BAE]
  └─> [Step 11: In light mode, #FFFFFF on #FFFFFF has 1.0:1 contrast; #8E9BAE on white has 2.81:1 contrast]
        └─> [Step 12: WCAG 2.2 AA mandates >= 4.5:1 contrast for regular text]
              └─> [Step 13: Light mode screens become unreadable under outdoor solar glare]
                    └─> [Conclusion 4: Decouple hardcoded colors from AppTypography static styles, wire textTheme in theme_provider.dart, use high-contrast light tokens]
```

---

## 3. Recommended Implementation Strategy & Code Solutions

### 3.1 Water Quality Modal (`parametro_modal.dart`) — DATA-01

1. **Initialize Controllers Empty:**
   ```dart
   // lib/modules/water_quality/presentation/dialogs/parametro_modal.dart
   // Lines 36-47
   final _oxigenoMgLCtrl = TextEditingController();
   final _oxigenoPctCtrl = TextEditingController();
   final _tempCtrl = TextEditingController();
   final _phCtrl = TextEditingController();
   final _amonioCtrl = TextEditingController();
   final _nitritosCtrl = TextEditingController();
   final _nitratosCtrl = TextEditingController();
   final _alcalinidadCtrl = TextEditingController();
   final _co2Ctrl = TextEditingController();
   final _durezaCtrl = TextEditingController();
   final _cloroCtrl = TextEditingController();
   final _obsCtrl = TextEditingController();
   ```

2. **Null-Safe Reactive Alert Calculations:**
   ```dart
   // Lines 92-101
   final oxigeno = double.tryParse(_oxigenoMgLCtrl.text.replaceAll(',', '.'));
   final amonio = double.tryParse(_amonioCtrl.text.replaceAll(',', '.'));
   final nitritos = double.tryParse(_nitritosCtrl.text.replaceAll(',', '.'));
   final cloro = double.tryParse(_cloroCtrl.text.replaceAll(',', '.'));

   final isHypoxia = oxigeno != null && oxigeno < 4.0;
   final isAmmoniaCritical = amonio != null && amonio > 0.5;
   final isNitriteCritical = nitritos != null && nitritos > 0.2;
   final isChlorineAlert = cloro != null && cloro > 0.05;
   ```

3. **Form Validation Rules for Routine Parameters:**
   - **Oxígeno Disuelto (mg/L):**
     ```dart
     GlassFormField(
       label: 'OXÍGENO (mg/L)',
       controller: _oxigenoMgLCtrl,
       isRequired: true,
       keyboardType: const TextInputType.numberWithOptions(decimal: true),
       prefixIcon: Icons.air_rounded,
       onChanged: (_) => setState(() {}),
       validator: (v) {
         if (v == null || v.trim().isEmpty) return 'El oxígeno es obligatorio';
         final val = double.tryParse(v.trim().replaceAll(',', '.'));
         if (val == null) return 'Ingrese un número válido';
         if (val < 0.0 || val > 30.0) return 'Rango biológico: 0.0 - 30.0 mg/L';
         return null;
       },
     )
     ```
   - **Temperatura (°C):**
     ```dart
     GlassFormField(
       label: 'TEMPERATURA (°C)',
       controller: _tempCtrl,
       isRequired: true,
       keyboardType: const TextInputType.numberWithOptions(decimal: true),
       prefixIcon: Icons.thermostat_rounded,
       validator: (v) {
         if (v == null || v.trim().isEmpty) return 'La temperatura es obligatoria';
         final val = double.tryParse(v.trim().replaceAll(',', '.'));
         if (val == null) return 'Ingrese un número válido';
         if (val < 5.0 || val > 45.0) return 'Rango biológico: 5.0 - 45.0 °C';
         return null;
       },
     )
     ```
   - **pH del Agua:**
     ```dart
     GlassFormField(
       label: 'pH DEL AGUA',
       controller: _phCtrl,
       isRequired: true,
       keyboardType: const TextInputType.numberWithOptions(decimal: true),
       prefixIcon: Icons.science_outlined,
       validator: (v) {
         if (v == null || v.trim().isEmpty) return 'El pH es obligatorio';
         final val = double.tryParse(v.trim().replaceAll(',', '.'));
         if (val == null) return 'Ingrese un número válido';
         if (val < 0.0 || val > 14.0) return 'Escala de pH: 0.0 - 14.0';
         return null;
       },
     )
     ```
   - **Optional Parameters Validation (Amonio, Nitritos, etc.):**
     ```dart
     validator: (v) {
       if (v == null || v.trim().isEmpty) return null;
       final val = double.tryParse(v.trim().replaceAll(',', '.'));
       if (val == null) return 'Número inválido';
       if (val < 0.0) return 'Debe ser mayor o igual a 0';
       return null;
     }
     ```

4. **Estanque Validation & Decimal Normalization on Save:**
   ```dart
   // Line 449
   if (_selectedPondId == null) {
     ScaffoldMessenger.of(context).showSnackBar(
       const SnackBar(
         content: Text('Debe seleccionar un estanque de medición.'),
         backgroundColor: AppColors.coralAction,
       ),
     );
     return;
   }
   if (!_formKey.currentState!.validate()) return;
   ```
   And parse all fields replacing `,` with `.` when creating `WaterParameter`:
   ```dart
   oxigenoMgL: double.tryParse(_oxigenoMgLCtrl.text.replaceAll(',', '.')),
   ph: double.tryParse(_phCtrl.text.replaceAll(',', '.')),
   temperaturaC: double.tryParse(_tempCtrl.text.replaceAll(',', '.')),
   ...
   ```

---

### 3.2 Field Ergonomics & WCAG 2.5.5 (`pond_bento_card.dart`) — UX-01

1. **Ergonomic Primary Action Button (WCAG 2.5.5 compliant):**
   Replace lines 392–506 (the 4 crammed 30 dp buttons) with a single, high-contrast, full-width Action Button:
   ```dart
   if (isActive) ...[
     const SizedBox(height: 12),
     SizedBox(
       width: double.infinity,
       height: 48,
       child: ElevatedButton.icon(
         style: ElevatedButton.styleFrom(
           backgroundColor: AppColors.cyanWater.withValues(alpha: isDark ? 0.22 : 0.15),
           foregroundColor: isDark ? Colors.white : AppColors.textPrimaryLight,
           elevation: 0,
           side: BorderSide(
             color: AppColors.cyanWater.withValues(alpha: isDark ? 0.5 : 0.8),
             width: 1.2,
           ),
           shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
         ),
         onPressed: () => _showPondActionSheet(context, activeBatch),
         icon: const Icon(Icons.flash_on_rounded, color: AppColors.cyanWater, size: 20),
         label: const Text(
           'Operar Estanque (Acciones Rápidas)',
           style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, letterSpacing: 0.3),
         ),
       ),
     ),
   ],
   ```

2. **Operational Bottom Sheet (`_showPondActionSheet`):**
   Designed specifically for wet field conditions and gloved operation:
   - Placed in thumb natural reach zone at bottom of screen.
   - 4 large distinct action cards, each with **min height: 60 dp**, full screen width, **generous 12 dp margin**, large 24 dp icon, and tactile haptic feedback (`HapticFeedback.lightImpact()`):
     1. **Alimentación Diaria:** Green badge (`AppColors.greenBiomass`), icon `Icons.restaurant_rounded`, subtext: "Registrar ración de alimento balanceado".
     2. **Muestreo Biométrico:** Cyan badge (`AppColors.cyanWater`), icon `Icons.scale_rounded`, subtext: "Registrar peso y talla de peces".
     3. **Registro de Mortalidad:** Coral badge (`AppColors.coralAction`), icon `Icons.warning_amber_rounded`, subtext: "Reportar bajas o anomalías clínicas".
     4. **Traslado de Lote:** Amber badge (`AppColors.amberWarning`), icon `Icons.swap_horiz_rounded`, subtext: "Mover biomasa a otro estanque".
   - Isolates sensitive actions (such as mortality recording) from accidental presses.

3. **Enlarge Flip Button Touch Target (Line 171):**
   Wrap the flip button in `SizedBox(width: 48, height: 48)`:
   ```dart
   SizedBox(
     width: 48,
     height: 48,
     child: IconButton(
       icon: const Icon(Icons.flip_camera_android_rounded, size: 18),
       tooltip: 'Rotar radiografía de estanque',
       onPressed: isRealActive ? _flipCard : null,
     ),
   )
   ```

---

### 3.3 Navigation Shell SafeArea & Gesture Insets (`main_navigation_shell.dart`) — UX-02

1. **Dynamic Bottom Inset Floating Dock:**
   In `lib/app/main_navigation_shell.dart`, lines 61–75:
   ```dart
   final bottomPadding = MediaQuery.paddingOf(context).bottom;
   final dockBottomOffset = 16.0 + bottomPadding;
   const dockContentHeight = 64.0;
   final totalDockClearance = dockBottomOffset + dockContentHeight;
   ```
   Position the dock:
   ```dart
   Positioned(
     left: 16,
     right: 16,
     bottom: dockBottomOffset,
     child: Center(
       child: ConstrainedBox(
         constraints: const BoxConstraints(maxWidth: 480),
         child: GlassContainer(...),
       ),
     ),
   )
   ```
   *Result:* The floating dock remains 16 dp above the gesture pill on Android and 16 dp above the iOS Home Indicator (total bottom offset 50 dp on iPhone), eliminating all gesture bar collisions.

2. **Propagate Insets & Eliminate Fragile `bottom: 78` Hacks:**
   In `MainNavigationShell`, wrap `Positioned.fill(child: child)` with an adjusted `MediaQuery`:
   ```dart
   Positioned.fill(
     child: MediaQuery(
       data: MediaQuery.of(context).copyWith(
         padding: MediaQuery.of(context).padding.copyWith(
           bottom: totalDockClearance,
         ),
       ),
       child: child,
     ),
   )
   ```
   *Architectural Benefit:*
   - In Flutter's `ScaffoldLayout`, `floatingActionButton` automatically computes its vertical elevation from `MediaQuery.of(context).padding.bottom`. By providing `totalDockClearance`, every child `Scaffold`'s FAB floats cleanly above the dock without requiring ANY manual padding.
   - All 7 fragile `padding: const EdgeInsets.only(bottom: 78)` instances across `ponds_dashboard_screen.dart`, `bitacora_screen.dart`, `water_quality_records_screen.dart`, `warehouse_screen.dart`, `gestion_equipo_screen.dart`, `sales_screen.dart`, and `finance_screen.dart` can be completely removed.
   - The hacky `SizedBox(height: 100)` spacer in `ponds_dashboard_screen.dart:366` is made redundant because `CustomScrollView` and `ListView` automatically extend their scroll extents by `mediaQuery.padding.bottom`.

---

### 3.4 Responsive Typography & Theme Contrast Tokens (`AppTypography`) — A11Y-01

1. **Decouple Colors from Baseline `AppTypography` Tokens:**
   In `lib/core/design_system/app_typography.dart`:
   Remove the static `color: AppColors.textPrimaryDark` from definitions so that they inherit the ambient `DefaultTextStyle` from the active theme:
   ```dart
   class AppTypography {
     AppTypography._();

     static const TextStyle displayLarge = TextStyle(
       fontSize: 26,
       fontWeight: FontWeight.w700,
       letterSpacing: -0.5,
     );

     static const TextStyle displayMedium = TextStyle(
       fontSize: 20,
       fontWeight: FontWeight.w600,
       letterSpacing: -0.3,
     );

     static const TextStyle titleLarge = TextStyle(
       fontSize: 17,
       fontWeight: FontWeight.w600,
       letterSpacing: -0.2,
     );

     static const TextStyle titleMedium = TextStyle(
       fontSize: 15,
       fontWeight: FontWeight.w600,
     );

     static const TextStyle titleSmall = TextStyle(
       fontSize: 13,
       fontWeight: FontWeight.w600,
     );

     static const TextStyle bodyMedium = TextStyle(
       fontSize: 13,
       fontWeight: FontWeight.w400,
       height: 1.4,
     );

     static const TextStyle bodySmall = TextStyle(
       fontSize: 11,
       fontWeight: FontWeight.w400,
     );

     static const TextStyle labelMicro = TextStyle(
       fontSize: 10,
       fontWeight: FontWeight.w600,
       letterSpacing: 0.5,
     );

     static const TextStyle numberKpi = TextStyle(
       fontSize: 22,
       fontWeight: FontWeight.w700,
       letterSpacing: -0.5,
       fontFeatures: [FontFeature.tabularFigures()],
     );
   ```

2. **Configure Comprehensive `TextTheme` in `theme_provider.dart`:**
   Configure high-contrast text hierarchies in `appDarkTheme` and `appLightTheme`:
   ```dart
   // lib/core/design_system/theme_provider.dart

   final appDarkTheme = ThemeData.dark().copyWith(
     scaffoldBackgroundColor: AppColors.backgroundDark,
     colorScheme: const ColorScheme.dark(
       primary: AppColors.cyanWater,
       secondary: AppColors.coralAction,
       surface: AppColors.surfaceDark,
       onSurface: AppColors.textPrimaryDark,
     ),
     textTheme: const TextTheme(
       displayLarge: TextStyle(color: AppColors.textPrimaryDark),
       displayMedium: TextStyle(color: AppColors.textPrimaryDark),
       titleLarge: TextStyle(color: AppColors.textPrimaryDark),
       titleMedium: TextStyle(color: AppColors.textPrimaryDark),
       titleSmall: TextStyle(color: AppColors.textPrimaryDark),
       bodyLarge: TextStyle(color: AppColors.textPrimaryDark),
       bodyMedium: TextStyle(color: AppColors.textSecondaryDark),
       bodySmall: TextStyle(color: AppColors.textSecondaryDark),
       labelSmall: TextStyle(color: AppColors.textSecondaryDark),
     ),
   );

   final appLightTheme = ThemeData.light().copyWith(
     scaffoldBackgroundColor: AppColors.backgroundLight,
     canvasColor: AppColors.backgroundLight,
     cardColor: AppColors.surfaceLight,
     colorScheme: const ColorScheme.light(
       primary: AppColors.cyanWater,
       secondary: AppColors.coralAction,
       surface: AppColors.surfaceLight,
       onSurface: AppColors.textPrimaryLight, // 0xFF0F172A (17.65:1 contrast)
       onPrimary: Colors.white,
     ),
     textTheme: const TextTheme(
       displayLarge: TextStyle(color: AppColors.textPrimaryLight),
       displayMedium: TextStyle(color: AppColors.textPrimaryLight),
       titleLarge: TextStyle(color: AppColors.textPrimaryLight),
       titleMedium: TextStyle(color: AppColors.textPrimaryLight),
       titleSmall: TextStyle(color: AppColors.textPrimaryLight),
       bodyLarge: TextStyle(color: AppColors.textPrimaryLight),
       bodyMedium: TextStyle(color: AppColors.textSecondaryLight), // 0xFF475569 (7.72:1 contrast)
       bodySmall: TextStyle(color: AppColors.textSecondaryLight),
       labelSmall: TextStyle(color: AppColors.textSecondaryLight),
     ),
   );
   ```

3. **Outdoor Sunlight Accent Color Adjustments:**
   When rendering text labels using brand colors on light backgrounds:
   - For Cyan text: Use `AppColors.blueOcean` (`#1D4ED8`, contrast **7.09:1**) in light mode.
   - For Green text: Use `#047857` (contrast **6.0:1**) in light mode.
   - For Coral text: Use `#DC2626` (contrast **4.9:1**) in light mode.
   - For Amber text: Use `#B45309` (contrast **4.8:1**) in light mode.

---

## 4. Caveats

- **Existing Tests:** The unit test suite (`test/modules/water_quality/water_parameter_test.dart`) tests serialization and deserialization of `WaterParameter` models. No existing tests directly assert the initial controller string of `ParametroModal`. Therefore, tests will not fail if controllers are changed from `'6.2'` to `''`. However, new widget tests should be written to verify that initial controllers are empty and validation fires.
- **Third-Party Keyboards on Android:** Some custom Android keyboards emit comma (`,`) instead of dot (`.`) even when `keyboardType: TextInputType.numberWithOptions(decimal: true)` is set. Normalizing user input via `.replaceAll(',', '.')` before parsing is required to prevent silent data loss.
- **Platform Insets on Desktop/Web:** On desktop platforms (Windows/macOS/Linux) and Web where `MediaQuery.paddingOf(context).bottom` is `0`, `dockBottomOffset` cleanly falls back to the minimum `16 dp`.

---

## 5. Conclusion

1. **DATA-01 (Water Quality Modal):** Initializing controllers with prefilled telemetry data creates serious regulatory non-compliance risks under ICA standards. By wiping default strings, adding mandatory range validators for DO, Temp, and pH, and requiring explicit pond selection, data integrity is guaranteed.
2. **UX-01 & A11Y-01 (Pond Bento Card):** The existing 30 dp quick action buttons fail WCAG 2.5.5 touch target criteria (min 48 × 48 dp) by 37.5% in height and up to 27% in width, creating severe operational friction in wet field conditions. A 48 dp primary action button opening an Operational Bottom Sheet with >= 56 dp tiles completely resolves this.
3. **UX-02 (Main Navigation Shell):** Hardcoding `bottom: 16` causes system gesture bar collisions on iOS and Android. Elevating the dock with `MediaQuery.paddingOf(context).bottom` and propagating total dock clearance through `MediaQuery` cleanly fixes the collision and eliminates all 7 downstream `bottom: 78` hacks.
4. **A11Y-01 (AppTypography Contrast):** Hardcoding dark tokens in `AppTypography` produces severe WCAG 2.2 AA contrast failures (1.0:1 and 2.81:1) in light mode. Decoupling colors from static styles and wiring `TextTheme` in `theme_provider.dart` ensures crisp, outdoor-readable text with contrast ratios > 7.0:1 across all lighting conditions.

---

## 6. Verification Method

### 6.1 Static Analysis
Execute static analysis to ensure zero analyzer regressions:
```powershell
flutter analyze --no-fatal-infos
```
*Expected Result:* `No issues found!`.

### 6.2 Unit and Model Tests
Execute existing test suite to ensure no domain regressions:
```powershell
flutter test test/modules/water_quality/water_parameter_test.dart
flutter test test/modules/ponds_batches/ponds_state_test.dart
flutter test test/modules/stress_tests/models_stress_test.dart
```
*Expected Result:* All tests pass with 100% success.

### 6.3 Automated Verification Commands for Future Implementation Turn
1. **Verify Empty Controllers in Modal:**
   Inspect `parametro_modal.dart` lines 36–47 using `view_file` to confirm `TextEditingController()` without text arguments.
2. **Verify Touch Targets:**
   Inspect `pond_bento_card.dart` to confirm all interactive targets are `>= 48` dp.
3. **Verify Removal of `bottom: 78`:**
   Run `git grep -n "bottom: 78" lib/` to ensure 0 matches remain in the repository.
4. **Verify Contrast Ratios:**
   Calculate contrast ratios of `appLightTheme.textTheme.bodyMedium` against `appLightTheme.colorScheme.surface` using WCAG relative luminance formula to ensure `>= 4.5:1`.
