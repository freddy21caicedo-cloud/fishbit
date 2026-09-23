import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:fishbit_finance/core/design_system/app_colors.dart';
import 'package:fishbit_finance/core/design_system/app_typography.dart';
import 'package:fishbit_finance/core/design_system/glass_container.dart';
import 'package:fishbit_finance/modules/auth_tenant/domain/models/user_member.dart';
import 'package:fishbit_finance/modules/auth_tenant/presentation/providers/auth_provider.dart';
import 'package:fishbit_finance/modules/auth_tenant/presentation/dialogs/app_config_modal.dart';
import 'package:fishbit_finance/core/design_system/theme_animated_glass_toggle.dart';

class UserProfileSheet extends ConsumerWidget {
  const UserProfileSheet({super.key});

  static Future<void> show(BuildContext context) {
    return showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Cerrar Perfil',
      barrierColor: Colors.black.withValues(alpha: 0.55),
      transitionDuration: const Duration(milliseconds: 250),
      pageBuilder: (dialogCtx, anim1, anim2) => const Material(
        type: MaterialType.transparency,
        child: UserProfileSheet(),
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
            // El origen de la animación emerge exactamente desde el círculo del avatar en el header superior derecho
            alignment: const Alignment(0.90, -0.85),
            scale: Tween<double>(begin: 0.25, end: 1.0).animate(curvedAnim),
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
    final company = authState.currentCompany;
    final units = authState.units;
    final activeUnit = units.where((u) => u.id == authState.activeUnitId).firstOrNull;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final roleColor = switch (user?.role) {
      UserRole.admin => AppColors.cyanWater,
      UserRole.sanitaryDirector => AppColors.greenBiomass,
      UserRole.technician => AppColors.amberWarning,
      UserRole.operator => Colors.orangeAccent,
      UserRole.creator => Colors.purpleAccent,
      _ => AppColors.cyanWater,
    };

    return Material(
      type: MaterialType.transparency,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => Navigator.of(context).pop(),
        child: SafeArea(
          child: Align(
            alignment: Alignment.topRight,
            child: Padding(
              // Flota justo debajo del encabezado superior derecho
              padding: const EdgeInsets.only(top: 68, right: 16, left: 16, bottom: 20),
              child: GestureDetector(
                onTap: () {}, // Evitar que clics dentro cierren el popover
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 460),
                  child: GlassContainer(
                    borderRadius: 26,
                    padding: const EdgeInsets.all(20),
                    blur: 28,
                    opacity: isDark ? 0.18 : 0.94,
                    borderColor: roleColor.withValues(alpha: isDark ? 0.35 : 0.45),
                    child: SingleChildScrollView(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Header con Avatar y botón de cierre
                          Row(
                            children: [
                              // Avatar con resplandor
                              Container(
                                width: 48,
                                height: 48,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: roleColor.withValues(alpha: 0.18),
                                  border: Border.all(color: roleColor, width: 2),
                                  boxShadow: [
                                    BoxShadow(
                                      color: roleColor.withValues(alpha: 0.35),
                                      blurRadius: 14,
                                      spreadRadius: 1,
                                    ),
                                  ],
                                ),
                                child: Center(
                                  child: Text(
                                    (user?.nombre.isNotEmpty == true ? user!.nombre[0] : 'U').toUpperCase(),
                                    style: TextStyle(
                                      color: roleColor,
                                      fontWeight: FontWeight.w900,
                                      fontSize: 20,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      user?.nombre ?? 'Usuario Acuícola',
                                      style: AppTypography.titleMedium.copyWith(
                                        color: isDark ? Colors.white : AppColors.textPrimaryLight,
                                        fontWeight: FontWeight.w800,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      user?.email ?? 'usuario@piscicola.com',
                                      style: AppTypography.bodySmall.copyWith(
                                        color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                              ),
                              Material(
                                color: Colors.transparent,
                                child: InkWell(
                                  onTap: () => Navigator.of(context).pop(),
                                  borderRadius: BorderRadius.circular(12),
                                  child: Container(
                                    padding: const EdgeInsets.all(4),
                                    decoration: BoxDecoration(
                                      color: isDark
                                          ? Colors.white.withValues(alpha: 0.08)
                                          : Colors.black.withValues(alpha: 0.05),
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(
                                      Icons.close_rounded,
                                      size: 16,
                                      color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),

                          // Badges de Rol y Sede
                          Wrap(
                            spacing: 6,
                            runSpacing: 4,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: roleColor.withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: roleColor.withValues(alpha: 0.3)),
                                ),
                                child: Text(
                                  user?.roleDisplayName ?? 'Colaborador',
                                  style: TextStyle(color: roleColor, fontSize: 10, fontWeight: FontWeight.w800),
                                ),
                              ),
                              if (activeUnit != null)
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: isDark
                                        ? Colors.white.withValues(alpha: 0.08)
                                        : Colors.black.withValues(alpha: 0.05),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    'Sede: ${activeUnit.sigla}',
                                    style: TextStyle(
                                      color: isDark ? Colors.white70 : AppColors.textSecondaryLight,
                                      fontSize: 10,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 16),

                          // Selector Segmentado de Modo Visual (Sistema / Claro / Oscuro)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                            decoration: BoxDecoration(
                              color: isDark ? Colors.white.withValues(alpha: 0.06) : Colors.white,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: isDark ? Colors.white.withValues(alpha: 0.12) : AppColors.glassBorderLight,
                              ),
                              boxShadow: isDark
                                  ? null
                                  : [
                                      BoxShadow(
                                        color: Colors.black.withValues(alpha: 0.04),
                                        blurRadius: 10,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    const Icon(Icons.palette_outlined, size: 18, color: AppColors.cyanWater),
                                    const SizedBox(width: 8),
                                    Text(
                                      'Tema Visual',
                                      style: TextStyle(
                                        color: isDark ? Colors.white : AppColors.textPrimaryLight,
                                        fontSize: 12.5,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                    const Spacer(),
                                    Text(
                                      'Auto / Claro / Oscuro',
                                      style: TextStyle(
                                        color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                                        fontSize: 10.5,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 10),
                                const ThemeSegmentedGlassSelector(),
                              ],
                            ),
                          ),
                          const SizedBox(height: 18),

                          // Accesos a Módulos Clave
                          Text(
                            'MÓDULOS DE GESTIÓN Y CONFIGURACIÓN',
                            style: AppTypography.labelMicro.copyWith(
                              color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                              letterSpacing: 1.2,
                            ),
                          ),
                          const SizedBox(height: 10),

                          _buildModuleTile(
                            context: context,
                            isDark: isDark,
                            icon: Icons.groups_rounded,
                            color: Colors.purpleAccent,
                            title: 'Gestión de Equipos y Personal',
                            subtitle: 'Directorio de roles, técnicos y sueldos',
                            onTap: () {
                              Navigator.of(context).pop();
                              context.go('/team');
                            },
                          ),
                          const SizedBox(height: 8),

                          _buildModuleTile(
                            context: context,
                            isDark: isDark,
                            icon: Icons.point_of_sale_rounded,
                            color: AppColors.greenBiomass,
                            title: 'Módulo de Ventas y Cosechas',
                            subtitle: 'Facturación comercial y despachos',
                            onTap: () {
                              Navigator.of(context).pop();
                              context.go('/sales');
                            },
                          ),
                          const SizedBox(height: 8),

                          _buildModuleTile(
                            context: context,
                            isDark: isDark,
                            icon: Icons.account_balance_wallet_rounded,
                            color: AppColors.coralAction,
                            title: 'Finanzas, Nómina y OPEX',
                            subtitle: 'Costos de producción, nómina y balance',
                            onTap: () {
                              Navigator.of(context).pop();
                              context.go('/finance');
                            },
                          ),
                          const SizedBox(height: 8),

                          _buildModuleTile(
                            context: context,
                            isDark: isDark,
                            icon: Icons.tune_rounded,
                            color: AppColors.cyanWater,
                            title: 'Configuración de la App y Piscícola',
                            subtitle: 'FCR objetivo, tarifas de energía y alertas ICA',
                            onTap: () {
                              Navigator.of(context).pop();
                              AppConfigModal.show(context);
                            },
                          ),
                          const SizedBox(height: 18),

                          // Footer de Cerrar Sesión
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(
                                  'Empresa: ${company?.nombreComercial ?? 'Piscícola'}',
                                  style: AppTypography.labelMicro.copyWith(
                                    color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              TextButton.icon(
                                style: TextButton.styleFrom(
                                  foregroundColor: AppColors.coralAction,
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                ),
                                icon: const Icon(Icons.logout_rounded, size: 16),
                                label: const Text('Cerrar Sesión', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 12)),
                                onPressed: () {
                                  Navigator.of(context).pop();
                                  ref.read(authProvider.notifier).signOut();
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
      ),
    );
  }

  Widget _buildModuleTile({
    required BuildContext context,
    required bool isDark,
    required IconData icon,
    required Color color,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isDark ? color.withValues(alpha: 0.22) : AppColors.glassBorderLight,
            ),
            boxShadow: isDark
                ? null
                : [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.03),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(7),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: color, size: 18),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        color: isDark ? Colors.white : AppColors.textPrimaryLight,
                        fontWeight: FontWeight.w700,
                        fontSize: 12.5,
                      ),
                    ),
                    Text(
                      subtitle,
                      style: TextStyle(
                        color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios_rounded,
                color: isDark ? Colors.white24 : AppColors.textTertiaryLight,
                size: 12,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
