import 'package:flutter/material.dart';
import 'package:fishbit_finance/core/design_system/app_colors.dart';
import 'package:fishbit_finance/core/design_system/app_typography.dart';
import 'package:fishbit_finance/core/design_system/glass_card.dart';
import 'package:fishbit_finance/core/design_system/glass_badge.dart';
import 'package:fishbit_finance/core/utils/currency_formatters.dart';
import 'package:fishbit_finance/modules/sales_harvest/presentation/providers/sales_provider.dart';

class SalesKpiScorecard extends StatelessWidget {
  final SalesState salesState;

  const SalesKpiScorecard({
    super.key,
    required this.salesState,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Fila 1: Ingreso Total y Utilidad Neta (KPIs principales con resplandor)
        Row(
          children: [
            Expanded(
              child: GlassCard(
                title: 'TOTAL INGRESOS',
                glowColor: AppColors.greenBiomass,
                trailingWidget: GlassBadge(
                  text: '${salesState.sales.length} despachos',
                  color: AppColors.greenBiomass,
                  icon: Icons.receipt_long_rounded,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: Text(
                        CurrencyFormatters.formatCOP(salesState.totalIngresosBrutos),
                        style: AppTypography.displayLarge.copyWith(
                          color: AppColors.greenBiomass,
                          fontWeight: FontWeight.w900,
                          fontSize: 22,
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Ticket promedio: ${CurrencyFormatters.formatCOP(salesState.ticketPromedioCOP)}',
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
                title: 'UTILIDAD NETA',
                glowColor: AppColors.purpleAnalytics,
                trailingWidget: GlassBadge(
                  text: '${salesState.margenNetoPromedioPct.toStringAsFixed(1)}% mg',
                  color: AppColors.purpleAnalytics,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: Text(
                        CurrencyFormatters.formatCOP(salesState.totalUtilidadNeta),
                        style: AppTypography.displayLarge.copyWith(
                          color: AppColors.purpleAnalytics,
                          fontWeight: FontWeight.w900,
                          fontSize: 22,
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'COGS: -${CurrencyFormatters.formatCOP(salesState.totalCogs)}',
                      style: AppTypography.labelMicro.copyWith(
                        color: AppColors.coralAction,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),

        const SizedBox(height: 12),

        // Fila 2: Rendimiento Biológico y Mermas (Biomasa Viva, Peso Arreglado, Merma en Kg y %)
        GlassCard(
          title: 'RENDIMIENTO DE COSECHA & MERMAS',
          glowColor: AppColors.cyanWater,
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _MetricColumn(
                    label: 'BIOMASA VIVA',
                    value: CurrencyFormatters.formatKg(salesState.totalBiomasaVendidaKg),
                    color: AppColors.cyanWater,
                    icon: Icons.waves_rounded,
                  ),
                  _MetricDivider(),
                  _MetricColumn(
                    label: 'PESO ARREGLADO',
                    value: CurrencyFormatters.formatKg(salesState.totalPesoArregladoKg),
                    color: AppColors.greenBiomass,
                    icon: Icons.restaurant_menu_rounded,
                  ),
                  _MetricDivider(),
                  _MetricColumn(
                    label: 'MERMA TOTAL',
                    value: '${salesState.totalMermaKg.toStringAsFixed(1)} kg',
                    subtitle: '(${salesState.mermaPromedioPct.toStringAsFixed(1)}%)',
                    color: AppColors.amberWarning,
                    icon: Icons.pie_chart_outline_rounded,
                  ),
                  _MetricDivider(),
                  _MetricColumn(
                    label: 'PECES',
                    value: '${salesState.totalPecesVendidos}',
                    color: isDark ? Colors.white : AppColors.textPrimaryLight,
                    icon: Icons.set_meal_rounded,
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _MetricColumn extends StatelessWidget {
  final String label;
  final String value;
  final String? subtitle;
  final Color color;
  final IconData icon;

  const _MetricColumn({
    required this.label,
    required this.value,
    this.subtitle,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 12, color: color),
              const SizedBox(width: 4),
              Flexible(
                child: Text(
                  label,
                  style: AppTypography.labelMicro.copyWith(
                    color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                    fontSize: 9,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              value,
              style: TextStyle(
                color: color,
                fontSize: 14,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 2),
            Text(
              subtitle!,
              style: AppTypography.labelMicro.copyWith(
                color: color.withValues(alpha: 0.85),
                fontSize: 9.5,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _MetricDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 1,
      height: 32,
      margin: const EdgeInsets.symmetric(horizontal: 4),
      color: Colors.white.withValues(alpha: 0.1),
    );
  }
}
