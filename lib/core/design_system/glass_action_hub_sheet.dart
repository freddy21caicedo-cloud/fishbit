import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:fishbit_finance/core/design_system/app_colors.dart';
import 'package:fishbit_finance/core/design_system/app_typography.dart';
import 'package:fishbit_finance/core/design_system/glass_container.dart';
import 'package:fishbit_finance/modules/auth_tenant/domain/models/user_member.dart';
import 'package:fishbit_finance/modules/auth_tenant/presentation/providers/auth_provider.dart';
import 'package:fishbit_finance/modules/auth_tenant/presentation/dialogs/sede_selector_modal.dart';

class GlassActionHubSheet extends ConsumerWidget {
  const GlassActionHubSheet({super.key});

  static Future<void> show(BuildContext context) {
    return showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Cerrar Menú',
      barrierColor: Colors.black.withValues(alpha: 0.55),
      transitionDuration: const Duration(milliseconds: 240),
      pageBuilder: (dialogCtx, anim1, anim2) => const Material(
        type: MaterialType.transparency,
        child: GlassActionHubSheet(),
      ),
      transitionBuilder: (dialogCtx, anim, secondaryAnim, child) {
        final curvedAnim = CurvedAnimation(
          parent: anim,
          curve: Curves.easeOutBack,
          reverseCurve: Curves.easeInCubic,
        );

        return FadeTransition(
          opacity: anim,
          child: ScaleTransition(
            // El origen de la animación emerge exactamente desde el botón "Más" (inferior derecho del dock)
            alignment: const Alignment(0.72, 0.88),
            scale: Tween<double>(begin: 0.65, end: 1.0).animate(curvedAnim),
            child: child,
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);
    final user = authState.currentUser;
    final isCreator = user?.role == UserRole.creator;
    final isAdmin = user?.role == UserRole.admin || isCreator;

    return Material(
      type: MaterialType.transparency,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => Navigator.of(context).pop(),
        child: SafeArea(
          child: Align(
            alignment: Alignment.bottomCenter,
            child: Padding(
              // Flota justo encima de la barra de navegación (bottom: 84px)
              padding: const EdgeInsets.only(left: 16, right: 16, bottom: 84),
              child: GestureDetector(
                onTap: () {}, // Evitar que clics dentro cierren el popover
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 480),
                  child: GlassContainer(
                    borderRadius: 28,
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 22),
                    blur: 28,
                    opacity: 0.18,
                    borderColor: AppColors.cyanWater.withValues(alpha: 0.3),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Header del Hub con botón de cierre
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                Container(
                                  width: 28,
                                  height: 28,
                                  decoration: BoxDecoration(
                                    color: AppColors.cyanWater.withValues(alpha: 0.2),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(Icons.apps_rounded, size: 16, color: AppColors.cyanWater),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'MÓDULOS Y GESTIÓN',
                                  style: AppTypography.labelMicro.copyWith(
                                    color: AppColors.cyanWater,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: 1.2,
                                  ),
                                ),
                              ],
                            ),
                            Material(
                              color: Colors.transparent,
                              child: InkWell(
                                onTap: () => Navigator.of(context).pop(),
                                borderRadius: BorderRadius.circular(12),
                                child: Container(
                                  padding: const EdgeInsets.all(4),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.08),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(Icons.close_rounded, size: 16, color: AppColors.textSecondaryDark),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),

                        // Grid de Módulos de Gestión
                        GridView.count(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          crossAxisCount: 2,
                          crossAxisSpacing: 10,
                          mainAxisSpacing: 10,
                          childAspectRatio: 1.45,
                          children: [
                            _buildHubTile(
                              context: context,
                              icon: Icons.point_of_sale_rounded,
                              color: AppColors.greenBiomass,
                              title: 'Ventas y Cosecha',
                              subtitle: 'Despachos y clientes',
                              onTap: () {
                                Navigator.of(context).pop();
                                context.go('/sales');
                              },
                            ),
                            if (isAdmin)
                              _buildHubTile(
                                context: context,
                                icon: Icons.account_balance_wallet_rounded,
                                color: AppColors.purpleAnalytics,
                                title: 'Finanzas y OPEX',
                                subtitle: 'Nómina, energía y CAPEX',
                                onTap: () {
                                  Navigator.of(context).pop();
                                  context.go('/finance');
                                },
                              ),
                            if (isAdmin)
                              _buildHubTile(
                                context: context,
                                icon: Icons.groups_rounded,
                                color: Colors.purpleAccent,
                                title: 'Equipo Acuícola',
                                subtitle: 'Personal y roles',
                                onTap: () {
                                  Navigator.of(context).pop();
                                  context.go('/team');
                                },
                              ),
                            _buildHubTile(
                              context: context,
                              icon: Icons.storefront_rounded,
                              color: AppColors.amberWarning,
                              title: 'Sedes y Piscícola',
                              subtitle: 'Cambiar o crear sede',
                              onTap: () {
                                Navigator.of(context).pop();
                                SedeSelectorModal.show(context);
                              },
                            ),
                            _buildHubTile(
                              context: context,
                              icon: Icons.verified_user_rounded,
                              color: AppColors.cyanWater,
                              title: 'Trazabilidad ICA / AUNAP',
                              subtitle: '12 formatos y reportes Excel',
                              onTap: () {
                                Navigator.of(context).pop();
                                context.go('/ica');
                              },
                            ),
                            if (isCreator)
                              _buildHubTile(
                                context: context,
                                icon: Icons.admin_panel_settings_rounded,
                                color: AppColors.coralAction,
                                title: 'Consola SaaS',
                                subtitle: 'Licenciamiento global',
                                onTap: () {
                                  Navigator.of(context).pop();
                                  context.go('/creator');
                                },
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHubTile({
    required BuildContext context,
    required IconData icon,
    required Color color,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: isDark ? Colors.white.withValues(alpha: 0.06) : Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: isDark ? color.withValues(alpha: 0.28) : AppColors.glassBorderLight,
            ),
            boxShadow: [
              BoxShadow(
                color: isDark ? color.withValues(alpha: 0.05) : const Color(0xFF64748B).withValues(alpha: 0.06),
                blurRadius: 10,
                spreadRadius: -2,
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: isDark ? 0.16 : 0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(icon, color: color, size: 18),
                  ),
                  const Spacer(),
                  Icon(Icons.arrow_forward_ios_rounded, color: isDark ? AppColors.textSecondaryDark.withValues(alpha: 0.4) : AppColors.textTertiaryLight, size: 11),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                title,
                style: AppTypography.titleSmall.copyWith(
                  color: isDark ? Colors.white : AppColors.textPrimaryLight,
                  fontWeight: FontWeight.w800,
                  fontSize: 12.5,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: AppTypography.labelMicro.copyWith(
                  color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                  fontSize: 9.5,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
