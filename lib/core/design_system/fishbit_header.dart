import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fishbit_finance/core/design_system/app_colors.dart';
import 'package:fishbit_finance/modules/auth_tenant/presentation/providers/auth_provider.dart';
import 'package:fishbit_finance/modules/auth_tenant/presentation/dialogs/sede_selector_modal.dart';
import 'package:fishbit_finance/modules/auth_tenant/presentation/dialogs/user_profile_sheet.dart';

/// Encabezado minimalista y de alta fidelidad estética para todas las páginas de FishBit
/// Presenta el branding "FishBit." limpio y la píldora interactiva de Empresa / Sede estilo Apple.
class FishBitHeader extends ConsumerWidget {
  final VoidCallback? onRefresh;
  final List<Widget>? customActions;

  const FishBitHeader({
    super.key,
    this.onRefresh,
    this.customActions,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final company = authState.currentCompany;
    final units = authState.units;
    final activeUnit = units.where((u) => u.id == authState.activeUnitId).firstOrNull ?? (units.isNotEmpty ? units.first : null);
    final user = authState.currentUser;

    final companyName = company?.nombreComercial ?? 'Piscícola';
    final sigla = activeUnit?.sigla ?? 'PRIN';

    return SliverAppBar(
      pinned: true,
      backgroundColor: Colors.transparent,
      elevation: 0,
      toolbarHeight: 68,
      automaticallyImplyLeading: false,
      flexibleSpace: ClipRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  (isDark ? AppColors.backgroundDark : Colors.white).withValues(alpha: 0.90),
                  (isDark ? AppColors.backgroundDark : Colors.white).withValues(alpha: 0.65),
                ],
              ),
              border: Border(
                bottom: BorderSide(
                  color: Colors.white.withValues(alpha: 0.04),
                  width: 0.5,
                ),
              ),
            ),
            child: SafeArea(
              bottom: false,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Branding FishBit. Limpio y Prominente
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'Fish',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w800,
                                letterSpacing: -0.8,
                                color: AppColors.cyanWater,
                                shadows: [
                                  Shadow(
                                    color: AppColors.cyanWater.withValues(alpha: 0.6),
                                    blurRadius: 14,
                                  ),
                                ],
                              ),
                            ),
                            Text(
                              'Bit.',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w800,
                                letterSpacing: -0.8,
                                color: AppColors.coralAction,
                                shadows: [
                                  Shadow(
                                    color: AppColors.coralAction.withValues(alpha: 0.6),
                                    blurRadius: 14,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        Text(
                          'Gestión Acuícola',
                          style: TextStyle(
                            fontSize: 8.5,
                            fontWeight: FontWeight.w500,
                            color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                            letterSpacing: 0.2,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Píldora Flotante Glassmorphic de Empresa & Sede (Notion / Dynamic Island Style)
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: Center(
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: CompanyPillButton(
                            key: ValueKey('pill_${company?.id}_${activeUnit?.id}_${sigla}_$companyName'),
                            companyName: companyName,
                            sigla: sigla,
                            onTap: () => SedeSelectorModal.show(context),
                          ),
                        ),
                      ),
                    ),
                  ),

                  // Acciones a la derecha
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (customActions != null) ...customActions!,
                      if (onRefresh != null)
                        IconButton(
                          icon: const Icon(Icons.refresh_rounded, color: AppColors.cyanWater, size: 20),
                          tooltip: 'Recargar datos',
                          onPressed: onRefresh,
                        ),
                      // Avatar de usuario con animación independiente y acceso a UserProfileSheet
                      HeaderAvatarButton(
                        userInitial: (user?.nombre.isNotEmpty == true ? user!.nombre[0] : 'U').toUpperCase(),
                        onTap: () => UserProfileSheet.show(context),
                      ),
                    ],
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

class HeaderAvatarButton extends StatefulWidget {
  final String userInitial;
  final VoidCallback onTap;

  const HeaderAvatarButton({
    super.key,
    required this.userInitial,
    required this.onTap,
  });

  @override
  State<HeaderAvatarButton> createState() => _HeaderAvatarButtonState();
}

class _HeaderAvatarButtonState extends State<HeaderAvatarButton> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) => setState(() => _isPressed = false),
      onTapCancel: () => setState(() => _isPressed = false),
      onTap: widget.onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedScale(
        scale: _isPressed ? 0.88 : 1.0,
        duration: const Duration(milliseconds: 120),
        curve: Curves.easeOutCubic,
        child: Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AppColors.cyanWater.withValues(alpha: 0.20),
            border: Border.all(color: AppColors.cyanWater, width: 1.5),
            boxShadow: [
              BoxShadow(
                color: AppColors.cyanWater.withValues(alpha: _isPressed ? 0.55 : 0.30),
                blurRadius: _isPressed ? 12 : 8,
                spreadRadius: _isPressed ? 1 : -1,
              ),
            ],
          ),
          child: Center(
            child: Text(
              widget.userInitial,
              style: const TextStyle(color: AppColors.cyanWater, fontWeight: FontWeight.w900, fontSize: 13.5),
            ),
          ),
        ),
      ),
    );
  }
}

class CompanyPillButton extends StatefulWidget {
  final String companyName;
  final String sigla;
  final VoidCallback onTap;

  const CompanyPillButton({
    super.key,
    required this.companyName,
    required this.sigla,
    required this.onTap,
  });

  @override
  State<CompanyPillButton> createState() => _CompanyPillButtonState();
}

class _CompanyPillButtonState extends State<CompanyPillButton> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) => setState(() => _isPressed = false),
      onTapCancel: () => setState(() => _isPressed = false),
      onTap: widget.onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedScale(
        scale: _isPressed ? 0.94 : 1.0,
        duration: const Duration(milliseconds: 120),
        curve: Curves.easeOutCubic,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: isDark
                ? Colors.white.withValues(alpha: _isPressed ? 0.12 : 0.06)
                : Colors.white.withValues(alpha: _isPressed ? 0.95 : 0.85),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: AppColors.cyanWater.withValues(alpha: _isPressed ? 0.60 : 0.35),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.cyanWater.withValues(alpha: _isPressed ? 0.25 : 0.12),
                blurRadius: _isPressed ? 14 : 10,
                spreadRadius: -2,
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 6,
                height: 6,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.greenBiomass,
                ),
              ),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  widget.companyName,
                  style: TextStyle(
                    color: isDark ? Colors.white : AppColors.textPrimaryLight,
                    fontSize: 11.5,
                    fontWeight: FontWeight.w700,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Text(
                ' • ${widget.sigla}',
                style: const TextStyle(
                  color: AppColors.cyanWater,
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(width: 2),
              const Icon(Icons.keyboard_arrow_down_rounded, color: AppColors.cyanWater, size: 14),
            ],
          ),
        ),
      ),
    );
  }
}
