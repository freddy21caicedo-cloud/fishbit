import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:fishbit_finance/core/design_system/app_colors.dart';
import 'package:fishbit_finance/core/design_system/theme_provider.dart';

/// Selector Segmentado Glassmorphic de 3 Modos (Sistema / Claro / Oscuro)
/// Diseñado para popovers, hojas de perfil y pantallas de configuración.
class ThemeSegmentedGlassSelector extends ConsumerWidget {
  const ThemeSegmentedGlassSelector({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final options = [
      (mode: ThemeMode.system, label: 'Auto', icon: Icons.brightness_auto_rounded),
      (mode: ThemeMode.light, label: 'Claro', icon: Icons.wb_sunny_rounded),
      (mode: ThemeMode.dark, label: 'Oscuro', icon: Icons.nightlight_round),
    ];

    return Container(
      height: 40,
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withValues(alpha: 0.06) : Colors.black.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark ? Colors.white.withValues(alpha: 0.12) : AppColors.glassBorderLight,
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: options.map((opt) {
          final isSelected = themeMode == opt.mode;

          return Expanded(
            child: GestureDetector(
              onTap: () {
                HapticFeedback.selectionClick();
                ref.read(themeModeProvider.notifier).setTheme(opt.mode);
              },
              behavior: HitTestBehavior.opaque,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 240),
                curve: Curves.easeInOutCubic,
                alignment: Alignment.center,
                padding: const EdgeInsets.symmetric(horizontal: 8),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  color: isSelected
                      ? (isDark ? AppColors.cyanWater.withValues(alpha: 0.25) : Colors.white)
                      : Colors.transparent,
                  border: isSelected
                      ? Border.all(
                          color: isDark ? AppColors.cyanWater.withValues(alpha: 0.6) : AppColors.cyanWaterTextLight.withValues(alpha: 0.4),
                          width: 1,
                        )
                      : null,
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: isDark
                                ? AppColors.cyanWater.withValues(alpha: 0.20)
                                : Colors.black.withValues(alpha: 0.08),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ]
                      : null,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      opt.icon,
                      size: 14,
                      color: isSelected
                          ? (isDark ? AppColors.cyanWater : AppColors.cyanWaterTextLight)
                          : (isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      opt.label,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                        color: isSelected
                            ? (isDark ? Colors.white : AppColors.textPrimaryLight)
                            : (isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

const String _sunSvg =
    '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24">'
    '<g fill="#ffd43b">'
    '<circle r="5" cy="12" cx="12"></circle>'
    '<path d="m21 13h-1a1 1 0 0 1 0-2h1a1 1 0 0 1 0 2zm-17 0h-1a1 1 0 0 1 0-2h1a1 1 0 0 1 0 2zm13.66-5.66a1 1 0 0 1 -.66-.29 1 1 0 0 1 0-1.41l.71-.71a1 1 0 1 1 1.41 1.41l-.71.71a1 1 0 0 1 -.75.29zm-12.02 12.02a1 1 0 0 1 -.71-.29 1 1 0 0 1 0-1.41l.71-.66a1 1 0 0 1 1.41 1.41l-.71.71a1 1 0 0 1 -.7.24zm6.36-14.36a1 1 0 0 1 -1-1v-1a1 1 0 0 1 2 0v1a1 1 0 0 1 -1 1zm0 17a1 1 0 0 1 -1-1v-1a1 1 0 0 1 2 0v1a1 1 0 0 1 -1 1zm-5.66-14.66a1 1 0 0 1 -.7-.29l-.71-.71a1 1 0 0 1 1.41-1.41l.71.71a1 1 0 0 1 0 1.41 1 1 0 0 1 -.71.29zm12.02 12.02a1 1 0 0 1 -.7-.29l-.66-.71a1 1 0 0 1 1.36-1.36l.71.71a1 1 0 0 1 0 1.41 1 1 0 0 1 -.71.24z"></path>'
    '</g>'
    '</svg>';

const String _moonSvg =
    '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 384 512">'
    '<path fill="#73C0FC" d="m223.5 32c-123.5 0-223.5 100.3-223.5 224s100 224 223.5 224c60.6 0 115.5-24.2 155.8-63.4 5-4.9 6.3-12.5 3.1-18.7s-10.1-9.7-17-8.5c-9.8 1.7-19.8 2.6-30.1 2.6-96.9 0-175.5-78.8-175.5-176 0-65.8 36-123.1 89.3-153.3 6.1-3.5 9.2-10.5 7.7-17.3s-7.3-11.9-14.3-12.5c-6.3-.5-12.6-.8-19-.8z"></path>'
    '</svg>';

/// Botón Switch Día/Noche animado (Estilo Uiverse andrew-demchenk0: Sol rotando / Luna balanceándose)
class ThemeAnimatedGlassToggle extends ConsumerStatefulWidget {
  final double scale;

  const ThemeAnimatedGlassToggle({
    super.key,
    this.scale = 1.0,
  });

  @override
  ConsumerState<ThemeAnimatedGlassToggle> createState() =>
      _ThemeAnimatedGlassToggleState();
}

class _ThemeAnimatedGlassToggleState
    extends ConsumerState<ThemeAnimatedGlassToggle>
    with TickerProviderStateMixin {
  late final AnimationController _sunController;
  late final AnimationController _moonController;
  late final Animation<double> _moonTiltAnimation;
  bool _isFocused = false;

  @override
  void initState() {
    super.initState();
    _sunController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 15),
    )..repeat();

    _moonController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 5),
    )..repeat();

    _moonTiltAnimation = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(begin: 0.0, end: -10.0 / 360.0),
        weight: 25,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: -10.0 / 360.0, end: 10.0 / 360.0),
        weight: 50,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 10.0 / 360.0, end: 0.0),
        weight: 25,
      ),
    ]).animate(_moonController);
  }

  @override
  void dispose() {
    _sunController.dispose();
    _moonController.dispose();
    super.dispose();
  }

  void _handleToggle() {
    HapticFeedback.mediumImpact();
    ref.read(themeModeProvider.notifier).toggleTheme(context);
  }

  @override
  Widget build(BuildContext context) {
    final themeMode = ref.watch(themeModeProvider);
    final effectiveIsDark = Theme.of(context).brightness == Brightness.dark;
    final isDark = themeMode == ThemeMode.dark ||
        (themeMode == ThemeMode.system && effectiveIsDark);

    final toggle = RepaintBoundary(
      child: Semantics(
        toggled: isDark,
        button: true,
        label: isDark ? 'Cambiar a modo claro' : 'Cambiar a modo oscuro',
        child: FocusableActionDetector(
          mouseCursor: SystemMouseCursors.click,
          onShowFocusHighlight: (focused) {
            if (_isFocused != focused) {
              setState(() => _isFocused = focused);
            }
          },
          actions: <Type, Action<Intent>>{
            ActivateIntent: CallbackAction<ActivateIntent>(
              onInvoke: (_) {
                _handleToggle();
                return null;
              },
            ),
          },
          child: GestureDetector(
            onTap: _handleToggle,
            behavior: HitTestBehavior.opaque,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 400),
              curve: Curves.easeInOut,
              width: 64,
              height: 34,
              decoration: BoxDecoration(
                color: isDark
                    ? const Color(0xFF183153)
                    : const Color(0xFF73C0FC),
                borderRadius: BorderRadius.circular(30),
                boxShadow: _isFocused
                    ? const [
                        BoxShadow(
                          color: Color(0xFF183153),
                          blurRadius: 1,
                        ),
                      ]
                    : null,
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(30),
                child: Stack(
                  children: [
                    // Sol rotando 360° en 15s (visible en Modo Claro)
                    Positioned(
                      top: 6,
                      left: 36,
                      width: 24,
                      height: 24,
                      child: RotationTransition(
                        turns: _sunController,
                        child: SvgPicture.string(
                          _sunSvg,
                          width: 24,
                          height: 24,
                          fit: BoxFit.contain,
                        ),
                      ),
                    ),

                    // Luna balanceándose ±10° en 5s (visible en Modo Oscuro)
                    Positioned(
                      top: 5,
                      left: 5,
                      width: 24,
                      height: 24,
                      child: RotationTransition(
                        turns: _moonTiltAnimation,
                        child: SvgPicture.string(
                          _moonSvg,
                          width: 24,
                          height: 24,
                          fit: BoxFit.contain,
                        ),
                      ),
                    ),

                    // Perilla deslizante (.slider:before) sobre sol y luna (z-index: 2)
                    AnimatedPositioned(
                      duration: const Duration(milliseconds: 400),
                      curve: Curves.easeInOut,
                      left: isDark ? 32 : 2,
                      bottom: 2,
                      width: 30,
                      height: 30,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          color: const Color(0xFFE8E8E8),
                          borderRadius: BorderRadius.circular(20),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );

    if (widget.scale == 1.0) return toggle;
    return SizedBox(
      width: 64 * widget.scale,
      height: 34 * widget.scale,
      child: FittedBox(
        fit: BoxFit.contain,
        child: toggle,
      ),
    );
  }
}
