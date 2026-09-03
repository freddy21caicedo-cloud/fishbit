import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:fishbit_finance/core/design_system/app_colors.dart';
import 'package:fishbit_finance/core/design_system/glass_container.dart';
import 'package:fishbit_finance/core/design_system/glass_action_hub_sheet.dart';

class MainNavigationShell extends ConsumerWidget {
  final Widget child;

  const MainNavigationShell({
    super.key,
    required this.child,
  });

  int _calculateSelectedIndex(BuildContext context) {
    final location = GoRouterState.of(context).matchedLocation;
    if (location.startsWith('/ponds')) return 1;
    if (location.startsWith('/warehouse')) return 2;
    if (location.startsWith('/bitacora') || location.startsWith('/records')) return 3;
    if (location.startsWith('/finance') || location.startsWith('/sales') || location.startsWith('/team') || location.startsWith('/creator') || location.startsWith('/ica')) {
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
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedIndex = _calculateSelectedIndex(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

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
            bottom: 16,
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
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      NavItemButton(
                        icon: Icons.dashboard_outlined,
                        activeIcon: Icons.dashboard_rounded,
                        label: 'Inicio',
                        isSelected: selectedIndex == 0,
                        onTap: () => _onItemTapped(0, context),
                      ),
                      NavItemButton(
                        icon: Icons.water_drop_outlined,
                        activeIcon: Icons.water_drop_rounded,
                        label: 'Estanques',
                        isSelected: selectedIndex == 1,
                        onTap: () => _onItemTapped(1, context),
                      ),
                      NavItemButton(
                        icon: Icons.inventory_2_outlined,
                        activeIcon: Icons.inventory_2_rounded,
                        label: 'Almacén',
                        isSelected: selectedIndex == 2,
                        onTap: () => _onItemTapped(2, context),
                      ),
                      NavItemButton(
                        icon: Icons.assignment_outlined,
                        activeIcon: Icons.assignment_rounded,
                        label: 'Bitácora',
                        isSelected: selectedIndex == 3,
                        onTap: () => _onItemTapped(3, context),
                      ),
                      NavItemButton(
                        icon: Icons.grid_view_rounded,
                        activeIcon: Icons.grid_view_rounded,
                        label: 'Más',
                        isSpecialHub: true,
                        isSelected: selectedIndex == 4,
                        onTap: () => _onItemTapped(4, context),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class NavItemButton extends StatefulWidget {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final bool isSelected;
  final bool isSpecialHub;
  final VoidCallback onTap;

  const NavItemButton({
    super.key,
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.isSelected,
    this.isSpecialHub = false,
    required this.onTap,
  });

  @override
  State<NavItemButton> createState() => _NavItemButtonState();
}

class _NavItemButtonState extends State<NavItemButton> with SingleTickerProviderStateMixin {
  bool _isPressed = false;
  late AnimationController _hubSpinController;

  @override
  void initState() {
    super.initState();
    _hubSpinController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 280),
    );
  }

  @override
  void dispose() {
    _hubSpinController.dispose();
    super.dispose();
  }

  void _handleTap() {
    if (widget.isSpecialHub) {
      _hubSpinController.forward(from: 0.0);
    }
    widget.onTap();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final unselectedColor = isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight;

    return Expanded(
      child: Semantics(
        button: true,
        label: widget.label,
        child: GestureDetector(
          onTapDown: (_) => setState(() => _isPressed = true),
          onTapUp: (_) => setState(() => _isPressed = false),
          onTapCancel: () => setState(() => _isPressed = false),
          onTap: _handleTap,
          behavior: HitTestBehavior.opaque,
          child: AnimatedScale(
            scale: _isPressed ? 0.88 : 1.0,
            duration: const Duration(milliseconds: 120),
            curve: Curves.easeOutCubic,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(vertical: 6),
              decoration: BoxDecoration(
                color: widget.isSelected
                    ? AppColors.cyanWater.withValues(alpha: isDark ? 0.20 : 0.15)
                    : (widget.isSpecialHub
                        ? (isDark ? Colors.white.withValues(alpha: 0.04) : Colors.black.withValues(alpha: 0.04))
                        : Colors.transparent),
                borderRadius: BorderRadius.circular(16),
                border: widget.isSelected
                    ? Border.all(color: AppColors.cyanWater.withValues(alpha: 0.4), width: 1)
                    : null,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  widget.isSpecialHub
                      ? RotationTransition(
                          turns: Tween<double>(begin: 0.0, end: 0.25).animate(
                            CurvedAnimation(parent: _hubSpinController, curve: Curves.easeOutBack),
                          ),
                          child: Icon(
                            widget.isSelected ? widget.activeIcon : widget.icon,
                            color: widget.isSelected
                                ? AppColors.cyanWater
                                : (isDark ? Colors.white70 : AppColors.textPrimaryLight),
                            size: 21,
                          ),
                        )
                      : Icon(
                          widget.isSelected ? widget.activeIcon : widget.icon,
                          color: widget.isSelected ? AppColors.cyanWater : unselectedColor,
                          size: 21,
                        ),
                  const SizedBox(height: 2),
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      widget.label,
                      style: TextStyle(
                        color: widget.isSelected ? AppColors.cyanWater : unselectedColor,
                        fontSize: 10,
                        fontWeight: widget.isSelected ? FontWeight.w800 : FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
