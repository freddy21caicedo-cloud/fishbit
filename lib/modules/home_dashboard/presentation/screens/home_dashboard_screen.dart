import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:fishbit_finance/core/design_system/app_colors.dart';
import 'package:fishbit_finance/core/design_system/app_typography.dart';
import 'package:fishbit_finance/core/design_system/fishbit_header.dart';
import 'package:fishbit_finance/core/design_system/glass_card.dart';
import 'package:fishbit_finance/core/design_system/glass_badge.dart';
import 'package:fishbit_finance/core/design_system/glass_container.dart';
import 'package:fishbit_finance/core/utils/currency_formatters.dart';
import 'package:fishbit_finance/modules/ponds_batches/presentation/dialogs/siembra_modal.dart';
import 'package:fishbit_finance/modules/ponds_batches/presentation/providers/ponds_provider.dart';
import 'package:fishbit_finance/modules/sales_harvest/presentation/dialogs/venta_rapida_modal.dart';
import 'package:fishbit_finance/modules/sales_harvest/presentation/providers/sales_provider.dart';
import 'package:fishbit_finance/modules/warehouse_inventory/presentation/providers/warehouse_provider.dart';
import 'package:fishbit_finance/modules/water_quality/presentation/dialogs/parametro_modal.dart';
import 'package:fishbit_finance/modules/water_quality/presentation/providers/water_quality_provider.dart';

class HomeDashboardScreen extends ConsumerWidget {
  const HomeDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pondsState = ref.watch(pondsProvider);
    final salesState = ref.watch(salesProvider);
    final warehouseState = ref.watch(warehouseProvider);
    final waterState = ref.watch(waterQualityProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: CustomScrollView(
        slivers: [
          // Barra Superior Unificada FishBitHeader
          const FishBitHeader(),

          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // KPI Principal: Valor Total en Agua (Biomasa)
                  GlassCard(
                    borderRadius: 24,
                    glowColor: AppColors.cyanWater,
                    title: 'VALOR TOTAL DE BIOMASA EN AGUA',
                    trailingWidget: const GlassBadge(text: 'EN VIVO', color: AppColors.greenBiomass, icon: Icons.circle),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            CurrencyFormatters.formatCOP(pondsState.biomasaTotalKg * 8500),
                            style: AppTypography.displayLarge.copyWith(
                              fontSize: 32,
                              color: AppColors.cyanWater,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 12,
                          runSpacing: 4,
                          alignment: WrapAlignment.spaceBetween,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            Text(
                              '${CurrencyFormatters.formatKg(pondsState.biomasaTotalKg)} totales',
                              style: AppTypography.bodyMedium.copyWith(
                                color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                              ),
                            ),
                            Text(
                              'Costo Inv: ${CurrencyFormatters.formatCOP(pondsState.costoTotalEnAgua)}',
                              style: AppTypography.bodySmall.copyWith(color: AppColors.greenBiomass, fontWeight: FontWeight.w700),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 14),

                  // Banner de Estado Biológico y Sanitario (ICA/AUNAP)
                  // KPI Sanitario y Calidad de Agua en vivo desde Bitácora
                  Builder(
                    builder: (context) {
                      final params = waterState.recentParameters;
                      final latest = params.firstOrNull;
                      final bool hasData = latest != null;
                      final double oxigeno = latest?.oxigenoMgL ?? 0.0;
                      final double ph = latest?.ph ?? 0.0;
                      final bool isHypoxia = hasData && oxigeno > 0 && oxigeno < 4.0;
                      final bool isPhAlert = hasData && ph > 0 && (ph < 6.5 || ph > 8.5);
                      final bool hasAlert = isHypoxia || isPhAlert;

                      final colorStatus = !hasData
                          ? AppColors.textTertiaryDark
                          : (hasAlert ? AppColors.coralAction : AppColors.greenBiomass);
                      final titleStatus = !hasData
                          ? 'Estado Sanitario: Sin registros'
                          : (hasAlert ? 'Estado Sanitario: Atención Requerida' : 'Estado Sanitario: Óptimo');
                      final descStatus = !hasData
                          ? 'Sin mediciones de agua registradas en bitácora'
                          : 'O₂: ${oxigeno.toStringAsFixed(1)} mg/L • pH: ${ph.toStringAsFixed(1)} • ${hasAlert ? (isHypoxia ? "Alerta de Oxígeno" : "Alerta de pH") : "Parámetros en equilibrio"}';

                      return InkWell(
                        onTap: () => context.go('/bitacora'),
                        borderRadius: BorderRadius.circular(18),
                        child: GlassContainer(
                          borderRadius: 18,
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          blur: 16,
                          opacity: 0.08,
                          borderColor: colorStatus.withValues(alpha: 0.35),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: colorStatus.withValues(alpha: 0.15),
                                ),
                                child: Icon(
                                  hasAlert ? Icons.warning_amber_rounded : Icons.verified_user_rounded,
                                  color: colorStatus,
                                  size: 20,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Text(
                                          titleStatus,
                                          style: TextStyle(
                                            color: isDark ? Colors.white : AppColors.textPrimaryLight,
                                            fontWeight: FontWeight.w800,
                                            fontSize: 13,
                                          ),
                                        ),
                                        const SizedBox(width: 6),
                                        Icon(Icons.circle, color: colorStatus, size: 8),
                                      ],
                                    ),
                                    Text(
                                      descStatus,
                                      style: AppTypography.labelMicro.copyWith(
                                        color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                              ),
                              Icon(Icons.arrow_forward_ios_rounded, color: isDark ? Colors.white24 : AppColors.textTertiaryLight, size: 12),
                            ],
                          ),
                        ),
                      );
                    },
                  ),

                  const SizedBox(height: 14),

                  // Resumen de Bento Grid 2x2
                  Row(
                    children: [
                      Expanded(
                        child: GlassCard(
                          title: 'Estanques',
                          glowColor: AppColors.cyanWater,
                          onTap: () => context.go('/ponds'),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              FittedBox(
                                fit: BoxFit.scaleDown,
                                child: Text(
                                  '${pondsState.estanquesActivosCount} / ${pondsState.ponds.length}',
                                  style: AppTypography.numberKpi.copyWith(color: AppColors.cyanWater),
                                ),
                              ),
                              Text(
                                'Productivos',
                                style: AppTypography.labelMicro.copyWith(
                                  color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: GlassCard(
                          title: 'Alimento',
                          glowColor: AppColors.amberWarning,
                          onTap: () => context.go('/warehouse'),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              FittedBox(
                                fit: BoxFit.scaleDown,
                                child: Text(
                                  CurrencyFormatters.formatKg(warehouseState.totalAlimentoKg),
                                  style: AppTypography.numberKpi.copyWith(color: AppColors.amberWarning),
                                ),
                              ),
                              Text(
                                'En Bodega',
                                style: AppTypography.labelMicro.copyWith(
                                  color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 12),

                  Row(
                    children: [
                      Expanded(
                        child: GlassCard(
                          title: 'Ventas',
                          glowColor: AppColors.greenBiomass,
                          onTap: () => context.go('/sales'),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              FittedBox(
                                fit: BoxFit.scaleDown,
                                child: Text(
                                  CurrencyFormatters.formatCOP(salesState.totalIngresosBrutos),
                                  style: AppTypography.numberKpi.copyWith(color: AppColors.greenBiomass, fontSize: 16),
                                ),
                              ),
                              Text(
                                'Ingresos Cosechas',
                                style: AppTypography.labelMicro.copyWith(
                                  color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: GlassCard(
                          title: 'Utilidad',
                          glowColor: AppColors.purpleAnalytics,
                          onTap: () => context.go('/finance'),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              FittedBox(
                                fit: BoxFit.scaleDown,
                                child: Text(
                                  CurrencyFormatters.formatCOP(salesState.totalUtilidadNeta),
                                  style: AppTypography.numberKpi.copyWith(color: AppColors.purpleAnalytics, fontSize: 16),
                                ),
                              ),
                              Text(
                                'Margen Acumulado',
                                style: AppTypography.labelMicro.copyWith(
                                  color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),
                  Text(
                    'ACCESOS RÁPIDOS OPERATIVOS',
                    style: AppTypography.labelMicro.copyWith(
                      color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                      letterSpacing: 1.5,
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Accesos Rápidos
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: [
                      _buildQuickAction(
                        context: context,
                        icon: Icons.add_circle_outline_rounded,
                        label: 'Sembrar Lote',
                        color: AppColors.cyanWater,
                        onTap: () => SiembraModal.show(context),
                      ),
                      _buildQuickAction(
                        context: context,
                        icon: Icons.water_drop_outlined,
                        label: 'Calidad Agua',
                        color: AppColors.blueOcean,
                        onTap: () => ParametroModal.show(context),
                      ),
                      _buildQuickAction(
                        context: context,
                        icon: Icons.point_of_sale_rounded,
                        label: 'Venta Rápida',
                        color: AppColors.greenBiomass,
                        onTap: () => VentaRapidaModal.show(context),
                      ),
                      _buildQuickAction(
                        context: context,
                        icon: Icons.inventory_2_outlined,
                        label: 'Ver Almacén',
                        color: AppColors.amberWarning,
                        onTap: () => context.go('/warehouse'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 100), // Espacio para el Dock de navegación
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickAction({
    required BuildContext context,
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: color.withValues(alpha: isDark ? 0.12 : 0.08),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withValues(alpha: isDark ? 0.3 : 0.25)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 18),
            const SizedBox(width: 8),
            Text(
              label,
              style: AppTypography.bodySmall.copyWith(
                color: isDark ? Colors.white : AppColors.textPrimaryLight,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
