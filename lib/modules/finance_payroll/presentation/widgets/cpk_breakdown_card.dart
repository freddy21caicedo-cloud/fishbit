import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fishbit_finance/core/design_system/app_colors.dart';
import 'package:fishbit_finance/core/design_system/app_typography.dart';
import 'package:fishbit_finance/core/design_system/glass_card.dart';
import 'package:fishbit_finance/core/design_system/glass_badge.dart';
import 'package:fishbit_finance/core/utils/currency_formatters.dart';
import 'package:fishbit_finance/modules/ponds_batches/presentation/providers/ponds_provider.dart';
import 'package:fishbit_finance/modules/warehouse_inventory/presentation/providers/warehouse_provider.dart';
import 'package:fishbit_finance/modules/finance_payroll/presentation/providers/finance_provider.dart';
import 'package:fishbit_finance/modules/equipment_capex/presentation/providers/equipment_provider.dart';
import 'package:fishbit_finance/modules/finance_payroll/domain/services/production_cost_engine.dart';

/// Tarjeta de Unit Economics & Radiografía de Costo por Kilogramo (CPK)
class CpkBreakdownCard extends ConsumerStatefulWidget {
  const CpkBreakdownCard({super.key});

  @override
  ConsumerState<CpkBreakdownCard> createState() => _CpkBreakdownCardState();
}

class _CpkBreakdownCardState extends ConsumerState<CpkBreakdownCard> {
  bool _showPondsBreakdown = false;

  @override
  Widget build(BuildContext context) {
    final ponds = ref.watch(pondsProvider).ponds;
    final warehouseState = ref.watch(warehouseProvider);
    final financeState = ref.watch(financeProvider);
    final equipmentState = ref.watch(equipmentProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final totalAlimentoFacturas = warehouseState.invoices.fold(0.0, (sum, inv) => sum + inv.totalFactura);

    final summary = ProductionCostEngine.calculate(
      ponds: ponds,
      totalAlimentoInsumos: totalAlimentoFacturas,
      totalNominaFija: financeState.totalCostoNomina,
      totalJornales: financeState.totalCostoJornales,
      totalEnergia: financeState.totalCostoEnergia,
      totalDepreciacionCapex: equipmentState.depreciacionDiariaTotal * 30.0,
      precioMercadoKg: 10500.0,
    );

    final colorMargen = summary.margenBrutoPorcentaje >= 30.0
        ? AppColors.greenBiomass
        : (summary.margenBrutoPorcentaje >= 15.0 ? AppColors.amberWarning : AppColors.coralAction);

    return GlassCard(
      title: 'UNIT ECONOMICS • COSTO POR KG (CPK)',
      subtitle: 'Rentabilidad, desglose y punto de equilibrio por biomasa viva',
      glowColor: AppColors.cyanWater,
      trailingWidget: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: colorMargen.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: colorMargen.withValues(alpha: 0.4)),
        ),
        child: Text(
          'Margen: ${summary.margenBrutoPorcentaje.toStringAsFixed(1)}%',
          style: TextStyle(color: colorMargen, fontWeight: FontWeight.w900, fontSize: 11),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // KPI Hero Principal
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('COSTO PRODUCTIVO / KG (FULL)', style: AppTypography.labelMicro.copyWith(color: AppColors.textSecondaryDark)),
                  const SizedBox(height: 2),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      Text(
                        CurrencyFormatters.formatCOP(summary.cpkTotal),
                        style: AppTypography.displayLarge.copyWith(fontSize: 26, color: AppColors.cyanWater, fontWeight: FontWeight.w900),
                      ),
                      const SizedBox(width: 4),
                      Text('/ kg producido', style: TextStyle(color: isDark ? Colors.white70 : AppColors.textSecondaryLight, fontSize: 11)),
                    ],
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text('PRECIO MERCADO', style: AppTypography.labelMicro.copyWith(color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight)),
                  const SizedBox(height: 2),
                  Text(
                    '${CurrencyFormatters.formatCOP(summary.precioMercadoKg)} / kg',
                    style: TextStyle(color: isDark ? Colors.white : AppColors.textPrimaryLight, fontWeight: FontWeight.w800, fontSize: 14),
                  ),
                  Text(
                    '+${CurrencyFormatters.formatCOP(summary.margenBrutoKg)} ganancia/kg',
                    style: TextStyle(color: colorMargen, fontWeight: FontWeight.w700, fontSize: 10.5),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Barra Segmentada de Composición del Costo
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: SizedBox(
              height: 10,
              child: Row(
                children: [
                  Expanded(
                    flex: summary.pctAlimento.round().clamp(1, 100),
                    child: Container(color: AppColors.greenBiomass),
                  ),
                  const SizedBox(width: 2),
                  Expanded(
                    flex: summary.pctAlevinos.round().clamp(1, 100),
                    child: Container(color: AppColors.cyanWater),
                  ),
                  const SizedBox(width: 2),
                  Expanded(
                    flex: summary.pctManoObra.round().clamp(1, 100),
                    child: Container(color: AppColors.purpleAnalytics),
                  ),
                  const SizedBox(width: 2),
                  Expanded(
                    flex: summary.pctEnergia.round().clamp(1, 100),
                    child: Container(color: AppColors.amberWarning),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 10),

          // Leyenda de Composición
          Wrap(
            spacing: 12,
            runSpacing: 6,
            alignment: WrapAlignment.spaceBetween,
            children: [
              _buildLegendItem(context, '🍽️ Alimento', summary.pctAlimento, AppColors.greenBiomass),
              _buildLegendItem(context, '🐟 Alevinos', summary.pctAlevinos, AppColors.cyanWater),
              _buildLegendItem(context, '👷 Nómina/Jornales', summary.pctManoObra, AppColors.purpleAnalytics),
              _buildLegendItem(context, '⚡ Energía', summary.pctEnergia, AppColors.amberWarning),
            ],
          ),
          const SizedBox(height: 12),

          // Punto de Equilibrio & Toggle de Estanques
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.04),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.08)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.balance_rounded, size: 14, color: AppColors.cyanWater),
                    const SizedBox(width: 6),
                    Text(
                      'Punto de Equilibrio: ${summary.puntoEquilibrioKg.isFinite ? summary.puntoEquilibrioKg.toStringAsFixed(0) : "0"} Kg (${CurrencyFormatters.formatCOP(summary.puntoEquilibrioCOP)})',
                      style: TextStyle(
                        color: isDark ? Colors.white70 : AppColors.textSecondaryLight,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                if (summary.estanquesBreakdown.isNotEmpty)
                  InkWell(
                    onTap: () => setState(() => _showPondsBreakdown = !_showPondsBreakdown),
                    borderRadius: BorderRadius.circular(6),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                      child: Row(
                        children: [
                          Text(
                            _showPondsBreakdown ? 'Ocultar' : 'Por Estanque',
                            style: const TextStyle(color: AppColors.purpleAnalytics, fontSize: 10.5, fontWeight: FontWeight.bold),
                          ),
                          Icon(
                            _showPondsBreakdown ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                            size: 14,
                            color: AppColors.purpleAnalytics,
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),

          // Desglose por Estanque Expandible
          if (_showPondsBreakdown && summary.estanquesBreakdown.isNotEmpty) ...[
            const SizedBox(height: 10),
            const Divider(height: 1),
            const SizedBox(height: 8),
            Text('DESGLOSE DE COSTO POR ESTANQUE ACTIVO', style: AppTypography.labelMicro.copyWith(color: AppColors.textSecondaryDark)),
            const SizedBox(height: 6),
            ...summary.estanquesBreakdown.map((pond) => Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 6,
                        height: 6,
                        decoration: const BoxDecoration(color: AppColors.cyanWater, shape: BoxShape.circle),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        pond.pondName,
                        style: TextStyle(color: isDark ? Colors.white : AppColors.textPrimaryLight, fontSize: 12, fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        '(${pond.biomasaKg.toStringAsFixed(0)} kg)',
                        style: TextStyle(color: isDark ? Colors.white38 : AppColors.textTertiaryLight, fontSize: 10.5),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      Text(
                        'CPK: ${CurrencyFormatters.formatCOP(pond.cpkTotal)}',
                        style: const TextStyle(color: AppColors.cyanWater, fontSize: 11, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(width: 6),
                      GlassBadge(
                        text: '${pond.margenPorcentaje.toStringAsFixed(0)}%',
                        color: pond.margenPorcentaje >= 30 ? AppColors.greenBiomass : AppColors.amberWarning,
                      ),
                    ],
                  ),
                ],
              ),
            )),
          ],
        ],
      ),
    );
  }

  Widget _buildLegendItem(BuildContext context, String label, double pct, Color color) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 5),
        Text(
          '$label: ${pct.toStringAsFixed(0)}%',
          style: TextStyle(color: isDark ? Colors.white : AppColors.textPrimaryLight, fontSize: 11, fontWeight: FontWeight.w600),
        ),
      ],
    );
  }
}

