import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:fishbit_finance/core/design_system/app_colors.dart';
import 'package:fishbit_finance/core/design_system/app_typography.dart';
import 'package:fishbit_finance/core/design_system/glass_card.dart';
import 'package:fishbit_finance/core/utils/currency_formatters.dart';
import 'package:fishbit_finance/modules/sales_harvest/domain/models/batch_sale.dart';

enum ChartMetricType { ingresos, biomasa }

class SalesTrendsChart extends StatefulWidget {
  final List<BatchSale> sales;

  const SalesTrendsChart({
    super.key,
    required this.sales,
  });

  @override
  State<SalesTrendsChart> createState() => _SalesTrendsChartState();
}

class _SalesTrendsChartState extends State<SalesTrendsChart> {
  ChartMetricType _selectedMetric = ChartMetricType.ingresos;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (widget.sales.isEmpty) {
      return const SizedBox.shrink();
    }

    // Ordenar cronológicamente para la serie de tiempo
    final sortedSales = [...widget.sales]..sort((a, b) => a.creadoEn.compareTo(b.creadoEn));

    // Tomar hasta las últimas 10 ventas para una lectura gráfica nítida
    final displaySales = sortedSales.length > 8 ? sortedSales.sublist(sortedSales.length - 8) : sortedSales;

    final spots = <FlSpot>[];
    double maxY = 0;

    for (int i = 0; i < displaySales.length; i++) {
      final s = displaySales[i];
      final val = _selectedMetric == ChartMetricType.ingresos ? s.ingresoBruto : s.biomasaVendidaKg;
      spots.add(FlSpot(i.toDouble(), val));
      if (val > maxY) maxY = val;
    }

    if (maxY == 0) maxY = 100;

    final activeColor = _selectedMetric == ChartMetricType.ingresos ? AppColors.greenBiomass : AppColors.cyanWater;

    return GlassCard(
      title: 'TENDENCIA DE VENTAS',
      glowColor: activeColor,
      trailingWidget: Container(
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
        ),
        padding: const EdgeInsets.all(2),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _MetricTabButton(
              title: '\$ COP',
              isSelected: _selectedMetric == ChartMetricType.ingresos,
              activeColor: AppColors.greenBiomass,
              onTap: () => setState(() => _selectedMetric = ChartMetricType.ingresos),
            ),
            _MetricTabButton(
              title: 'Kg',
              isSelected: _selectedMetric == ChartMetricType.biomasa,
              activeColor: AppColors.cyanWater,
              onTap: () => setState(() => _selectedMetric = ChartMetricType.biomasa),
            ),
          ],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _selectedMetric == ChartMetricType.ingresos
                ? 'Comportamiento de Ingresos Brutos por lote cosechado'
                : 'Volumen cosechado en kilogramos vivos',
            style: AppTypography.labelMicro.copyWith(
              color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 160,
            child: LineChart(
              LineChartData(
                minX: 0,
                maxX: (displaySales.length - 1).toDouble() > 0 ? (displaySales.length - 1).toDouble() : 1.0,
                minY: 0,
                maxY: maxY * 1.25,
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: (maxY * 1.25) / 4 > 0 ? (maxY * 1.25) / 4 : 1,
                  getDrawingHorizontalLine: (value) => FlLine(
                    color: Colors.white.withValues(alpha: 0.06),
                    strokeWidth: 1,
                    dashArray: [4, 4],
                  ),
                ),
                titlesData: FlTitlesData(
                  show: true,
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 46,
                      interval: (maxY * 1.25) / 3 > 0 ? (maxY * 1.25) / 3 : 1,
                      getTitlesWidget: (value, meta) {
                        if (value == 0) return const SizedBox.shrink();
                        final text = _selectedMetric == ChartMetricType.ingresos
                            ? '${(value / 1000000).toStringAsFixed(1)}M'
                            : '${value.toInt()}k';
                        return Text(
                          text,
                          style: TextStyle(
                            color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                          ),
                        );
                      },
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 22,
                      interval: 1,
                      getTitlesWidget: (value, meta) {
                        final index = value.toInt();
                        if (index < 0 || index >= displaySales.length) return const SizedBox.shrink();
                        final s = displaySales[index];
                        return Padding(
                          padding: const EdgeInsets.only(top: 6),
                          child: Text(
                            '${s.creadoEn.day}/${s.creadoEn.month}',
                            style: TextStyle(
                              color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                              fontSize: 9.5,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
                borderData: FlBorderData(show: false),
                lineTouchData: LineTouchData(
                  handleBuiltInTouches: true,
                  touchTooltipData: LineTouchTooltipData(
                    getTooltipItems: (touchedSpots) {
                      return touchedSpots.map((spot) {
                        final index = spot.x.toInt();
                        final sale = displaySales[index];
                        final valStr = _selectedMetric == ChartMetricType.ingresos
                            ? CurrencyFormatters.formatCOP(spot.y)
                            : CurrencyFormatters.formatKg(spot.y);
                        return LineTooltipItem(
                          '${sale.clienteNombre}\n$valStr\n${sale.especie}',
                          const TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                          ),
                        );
                      }).toList();
                    },
                  ),
                ),
                lineBarsData: [
                  LineChartBarData(
                    spots: spots,
                    isCurved: true,
                    curveSmoothness: 0.35,
                    color: activeColor,
                    barWidth: 3,
                    isStrokeCapRound: true,
                    dotData: FlDotData(
                      show: true,
                      getDotPainter: (spot, percent, barData, index) {
                        return FlDotCirclePainter(
                          radius: 3.5,
                          color: Colors.white,
                          strokeWidth: 2,
                          strokeColor: activeColor,
                        );
                      },
                    ),
                    belowBarData: BarAreaData(
                      show: true,
                      gradient: LinearGradient(
                        colors: [
                          activeColor.withValues(alpha: 0.28),
                          activeColor.withValues(alpha: 0.0),
                        ],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MetricTabButton extends StatelessWidget {
  final String title;
  final bool isSelected;
  final Color activeColor;
  final VoidCallback onTap;

  const _MetricTabButton({
    required this.title,
    required this.isSelected,
    required this.activeColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: isSelected ? activeColor.withValues(alpha: 0.25) : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          border: isSelected ? Border.all(color: activeColor.withValues(alpha: 0.6)) : null,
        ),
        child: Text(
          title,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w800,
            color: isSelected ? activeColor : AppColors.textSecondaryDark,
          ),
        ),
      ),
    );
  }
}
