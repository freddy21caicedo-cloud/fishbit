import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fishbit_finance/core/design_system/app_colors.dart';
import 'package:fishbit_finance/core/design_system/app_typography.dart';
import 'package:fishbit_finance/core/design_system/glass_container.dart';
import 'package:fishbit_finance/core/design_system/fishbit_header.dart';
import 'package:fishbit_finance/modules/auth_tenant/domain/models/user_member.dart';
import 'package:fishbit_finance/modules/auth_tenant/presentation/providers/auth_provider.dart';
import 'package:fishbit_finance/modules/auth_tenant/presentation/dialogs/crear_colaborador_modal.dart';

class GestionEquipoScreen extends ConsumerWidget {
  const GestionEquipoScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);
    final team = authState.teamMembers;

    final sanitarios = team.where((m) => m.role == UserRole.sanitaryDirector).length;
    final tecnicos = team.where((m) => m.role == UserRole.technician).length;
    final operarios = team.where((m) => m.role == UserRole.operator).length;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 78),
        child: FloatingActionButton.extended(
          backgroundColor: AppColors.cyanWater,
          foregroundColor: Colors.black,
          icon: const Icon(Icons.person_add_alt_1_rounded),
          label: const Text('Nuevo Colaborador', style: TextStyle(fontWeight: FontWeight.w800)),
          onPressed: () => CrearColaboradorModal.show(context),
        ),
      ),
      body: CustomScrollView(
        slivers: [
          const FishBitHeader(),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Métricas Bento de Personal
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final isWide = constraints.maxWidth > 800;
                      return Wrap(
                        spacing: 12,
                        runSpacing: 12,
                        children: [
                          _buildBentoMetric(
                            width: isWide ? (constraints.maxWidth - 36) / 4 : (constraints.maxWidth - 12) / 2,
                            title: 'TOTAL EQUIPO',
                            value: '${team.length}',
                            subtitle: 'Personal registrado',
                            icon: Icons.groups_rounded,
                            accentColor: Colors.white,
                          ),
                          _buildBentoMetric(
                            width: isWide ? (constraints.maxWidth - 36) / 4 : (constraints.maxWidth - 12) / 2,
                            title: 'DIR. SANITARIOS',
                            value: '$sanitarios',
                            subtitle: 'Sanidad, ICA y retiro',
                            icon: Icons.health_and_safety_rounded,
                            accentColor: AppColors.cyanWater,
                          ),
                          _buildBentoMetric(
                            width: isWide ? (constraints.maxWidth - 36) / 4 : (constraints.maxWidth - 12) / 2,
                            title: 'TÉCNICOS ACUÍCOLAS',
                            value: '$tecnicos',
                            subtitle: 'Biometría y calidad agua',
                            icon: Icons.biotech_rounded,
                            accentColor: AppColors.greenBiomass,
                          ),
                          _buildBentoMetric(
                            width: isWide ? (constraints.maxWidth - 36) / 4 : (constraints.maxWidth - 12) / 2,
                            title: 'OPERARIOS DE CAMPO',
                            value: '$operarios',
                            subtitle: 'Alimentación y estanques',
                            icon: Icons.agriculture_rounded,
                            accentColor: AppColors.coralAction,
                          ),
                        ],
                      );
                    },
                  ),
                  const SizedBox(height: 24),

                  // Título de sección y botón
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          'DIRECTORIO DE COLABORADORES',
                          style: AppTypography.titleMedium.copyWith(
                            color: AppColors.cyanWater,
                            letterSpacing: 1.0,
                            fontSize: 13,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      TextButton.icon(
                        icon: const Icon(Icons.add_circle_outline_rounded, color: AppColors.cyanWater, size: 18),
                        label: const Text('Agregar', style: TextStyle(color: AppColors.cyanWater, fontWeight: FontWeight.w700)),
                        onPressed: () => CrearColaboradorModal.show(context),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Lista Bento de Miembros
                  if (team.isEmpty)
                    Center(
                      child: Padding(
                        padding: const EdgeInsets.all(40),
                        child: Text(
                          'No hay colaboradores registrados aún.\nUtiliza el botón de arriba para registrar al Director Sanitario, Técnicos u Operarios.',
                          textAlign: TextAlign.center,
                          style: AppTypography.bodyMedium.copyWith(color: AppColors.textSecondaryDark),
                        ),
                      ),
                    )
                  else
                    ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: team.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        final member = team[index];
                        final currentUser = authState.currentUser;
                        final isAdmin = currentUser?.role == UserRole.admin || currentUser?.role == UserRole.creator;
                        return _buildMemberCard(context, member, isAdmin);
                      },
                    ),
                  const SizedBox(height: 80),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBentoMetric({
    required double width,
    required String title,
    required String value,
    required String subtitle,
    required IconData icon,
    required Color accentColor,
  }) {
    return SizedBox(
      width: width,
      child: GlassContainer(
        borderRadius: 20,
        padding: const EdgeInsets.all(16),
        blur: 16,
        opacity: 0.10,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    title,
                    style: AppTypography.labelMicro.copyWith(color: AppColors.textSecondaryDark),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 4),
                Icon(icon, color: accentColor, size: 20),
              ],
            ),

            const SizedBox(height: 8),
            Text(
              value,
              style: AppTypography.displayMedium.copyWith(
                color: accentColor,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 4),
            Text(subtitle, style: AppTypography.labelMicro.copyWith(color: AppColors.textSecondaryDark)),
          ],
        ),
      ),
    );
  }

  Widget _buildMemberCard(BuildContext context, UserMember member, bool isAdmin) {
    Color roleColor;
    IconData roleIcon;

    switch (member.role) {
      case UserRole.creator:
        roleColor = AppColors.amberWarning;
        roleIcon = Icons.stars_rounded;
        break;
      case UserRole.admin:
        roleColor = Colors.purpleAccent;
        roleIcon = Icons.admin_panel_settings_rounded;
        break;
      case UserRole.sanitaryDirector:
        roleColor = AppColors.cyanWater;
        roleIcon = Icons.health_and_safety_rounded;
        break;
      case UserRole.technician:
        roleColor = AppColors.greenBiomass;
        roleIcon = Icons.biotech_rounded;
        break;
      case UserRole.operator:
        roleColor = AppColors.coralAction;
        roleIcon = Icons.agriculture_rounded;
        break;
    }

    final cardContent = GlassContainer(
      borderRadius: 20,
      padding: const EdgeInsets.all(14),
      blur: 16,
      opacity: 0.08,
      borderColor: isAdmin ? Colors.white.withValues(alpha: 0.12) : null,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: roleColor.withValues(alpha: 0.18),
              border: Border.all(color: roleColor.withValues(alpha: 0.4)),
            ),
            child: Icon(roleIcon, color: roleColor, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Text(
                      member.nombre,
                      style: AppTypography.titleMedium.copyWith(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 14.5),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                      decoration: BoxDecoration(
                        color: roleColor.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: roleColor.withValues(alpha: 0.4)),
                      ),
                      child: Text(
                        member.roleDisplayName,
                        style: TextStyle(color: roleColor, fontSize: 9.5, fontWeight: FontWeight.w800),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Wrap(
                  spacing: 12,
                  runSpacing: 2,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.alternate_email_rounded, size: 12, color: AppColors.textSecondaryDark),
                        const SizedBox(width: 3),
                        Text(
                          member.email,
                          style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondaryDark, fontSize: 11.5),
                        ),
                      ],
                    ),
                    if (member.cedula != null && member.cedula!.isNotEmpty)
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.badge_outlined, size: 12, color: AppColors.textSecondaryDark),
                          const SizedBox(width: 3),
                          Text(
                            'C.C. ${member.cedula}',
                            style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondaryDark, fontSize: 11.5),
                          ),
                        ],
                      ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          if (isAdmin)
            Container(
              margin: const EdgeInsets.only(right: 6),
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: AppColors.cyanWater.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.edit_outlined, size: 15, color: AppColors.cyanWater),
            ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: AppColors.greenBiomass.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Text(
              'Activo',
              style: TextStyle(color: AppColors.greenBiomass, fontSize: 10.5, fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );

    if (!isAdmin) {
      return cardContent;
    }

    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: () => CrearColaboradorModal.show(context, memberToEdit: member),
      child: cardContent,
    );
  }
}
