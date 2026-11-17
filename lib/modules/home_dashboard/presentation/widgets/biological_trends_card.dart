import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:fishbit_finance/core/design_system/app_colors.dart';
import 'package:fishbit_finance/core/design_system/app_typography.dart';
import 'package:fishbit_finance/core/design_system/glass_card.dart';
import 'package:fishbit_finance/core/design_system/glass_container.dart';
import 'package:fishbit_finance/core/utils/currency_formatters.dart';
import 'package:fishbit_finance/modules/feeding_nutrition/presentation/providers/nutrition_provider.dart';
import 'package:fishbit_finance/modules/ponds_batches/domain/models/pond.dart';
import 'package:fishbit_finance/modules/ponds_batches/presentation/providers/ponds_provider.dart';
import 'package:fishbit_finance/modules/water_quality/presentation/providers/water_quality_provider.dart';

enum BiologicalCurveType {
  oxigeno,
  temperaturaPh,
  toxicos,
  crecimiento,
  conversion,
  supervivencia,
}

class BiologicalTrendsCard extends ConsumerStatefulWidget {
  const BiologicalTrendsCard({super.key});

  @override
  ConsumerState<BiologicalTrendsCard> createState() => _BiologicalTrendsCardState();
}

class _BiologicalTrendsCardState extends ConsumerState<BiologicalTrendsCard> {
  BiologicalCurveType _selectedCurve = BiologicalCurveType.oxigeno;
  String? _selectedPondId; // null = Todos (Promedio granja)

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final pondsState = ref.watch(pondsProvider);
    final waterState = ref.watch(waterQualityProvider);
    final nutritionState = ref.watch(nutritionProvider);

    final ponds = pondsState.ponds;

    return GlassCard(
      borderRadius: 24,
      glowColor: _getCurveColor(_selectedCurve),
      title: 'ANALÍTICA BIOLÓGICA Y TENDENCIAS',
      trailingWidget: _buildPondSelectorBtn(ponds, isDark),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Selector de Curva (6 Chips horizontales scrolleables)
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildCurveChip(
                  type: BiologicalCurveType.oxigeno,
                  label: 'Oxígeno (O₂)',
                  icon: Icons.waves_rounded,
                  color: AppColors.cyanWater,
                ),
                const SizedBox(width: 8),
                _buildCurveChip(
                  type: BiologicalCurveType.temperaturaPh,
                  label: 'Temp & pH (°C)',
                  icon: Icons.thermostat_rounded,
                  color: AppColors.blueOcean,
                ),
                const SizedBox(width: 8),
                _buildCurveChip(
                  type: BiologicalCurveType.toxicos,
                  label: 'Tóxicos (NH₃/NO₂)',
                  icon: Icons.warning_amber_rounded,
                  color: AppColors.coralAction,
                ),
                const SizedBox(width: 8),
                _buildCurveChip(
                  type: BiologicalCurveType.crecimiento,
                  label: 'Crecimiento (g)',
                  icon: Icons.show_chart_rounded,
                  color: AppColors.greenBiomass,
                ),
                const SizedBox(width: 8),
                _buildCurveChip(
                  type: BiologicalCurveType.conversion,
                  label: 'Conversión (FCR)',
                  icon: Icons.restaurant_rounded,
                  color: AppColors.amberWarning,
                ),
                const SizedBox(width: 8),
                _buildCurveChip(
                  type: BiologicalCurveType.supervivencia,
                  label: 'Supervivencia (%)',
                  icon: Icons.favorite_rounded,
                  color: AppColors.purpleAnalytics,
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),

          // Área de Gráfica FL Chart con recorte seguro anti-desbordes
          SizedBox(
            height: 200,
            child: ClipRect(
              child: _buildChart(
                isDark: isDark,
                waterState: waterState,
                pondsState: pondsState,
                nutritionState: nutritionState,
              ),
            ),
          ),

          const SizedBox(height: 14),

          // KPIs y Referencias de la curva seleccionada
          _buildMetricsFooter(
            isDark: isDark,
            waterState: waterState,
            pondsState: pondsState,
            nutritionState: nutritionState,
          ),
        ],
      ),
    );
  }

  Color _getCurveColor(BiologicalCurveType type) {
    switch (type) {
      case BiologicalCurveType.oxigeno:
        return AppColors.cyanWater;
      case BiologicalCurveType.temperaturaPh:
        return AppColors.blueOcean;
      case BiologicalCurveType.toxicos:
        return AppColors.coralAction;
      case BiologicalCurveType.crecimiento:
        return AppColors.greenBiomass;
      case BiologicalCurveType.conversion:
        return AppColors.amberWarning;
      case BiologicalCurveType.supervivencia:
        return AppColors.purpleAnalytics;
    }
  }

  Widget _buildPondSelectorBtn(List<Pond> ponds, bool isDark) {
    final activePonds = ponds.where((p) => p.nombre.isNotEmpty).toList();
    final currentPondName = _selectedPondId == null
        ? 'Todos'
        : (activePonds.where((p) => p.id == _selectedPondId).firstOrNull?.nombre ?? 'Estanque');

    return InkWell(
      onTap: () => _openGlassPondModal(context, activePonds, isDark),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: isDark ? 0.08 : 0.2),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.cyanWater.withValues(alpha: 0.3)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.filter_list_rounded, size: 14, color: AppColors.cyanWater),
            const SizedBox(width: 5),
            Text(
              currentPondName,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: isDark ? Colors.white : AppColors.textPrimaryLight,
              ),
            ),
            const SizedBox(width: 2),
            Icon(Icons.keyboard_arrow_down_rounded, size: 14, color: isDark ? Colors.white54 : AppColors.textTertiaryLight),
          ],
        ),
      ),
    );
  }

  void _openGlassPondModal(BuildContext context, List<Pond> ponds, bool isDark) {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Cerrar Filtro',
      barrierColor: Colors.black.withValues(alpha: 0.65),
      transitionDuration: const Duration(milliseconds: 240),
      pageBuilder: (dialogCtx, anim1, anim2) => Material(
        type: MaterialType.transparency,
        child: _GlassPondSelectorDialog(
          ponds: ponds,
          selectedPondId: _selectedPondId,
          onSelected: (id) {
            setState(() => _selectedPondId = id);
            Navigator.of(dialogCtx).pop();
          },
        ),
      ),
      transitionBuilder: (dialogCtx, anim, secondaryAnim, child) {
        final curved = CurvedAnimation(parent: anim, curve: Curves.easeOutCubic);
        return ScaleTransition(
          scale: Tween<double>(begin: 0.94, end: 1.0).animate(curved),
          child: FadeTransition(opacity: curved, child: child),
        );
      },
    );
  }

  Widget _buildCurveChip({
    required BiologicalCurveType type,
    required String label,
    required IconData icon,
    required Color color,
  }) {
    final isSelected = _selectedCurve == type;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return InkWell(
      onTap: () => setState(() => _selectedCurve = type),
      borderRadius: BorderRadius.circular(12),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? color.withValues(alpha: 0.2) : Colors.white.withValues(alpha: isDark ? 0.04 : 0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? color : Colors.white.withValues(alpha: 0.08),
            width: isSelected ? 1.5 : 1.0,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: isSelected ? color : (isDark ? Colors.white60 : AppColors.textSecondaryLight)),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 11.5,
                fontWeight: isSelected ? FontWeight.w800 : FontWeight.w500,
                color: isSelected ? (isDark ? Colors.white : color) : (isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChart({
    required bool isDark,
    required dynamic waterState,
    required dynamic pondsState,
    required dynamic nutritionState,
  }) {
    switch (_selectedCurve) {
      case BiologicalCurveType.oxigeno:
        return _buildOxygenChart(isDark, waterState);
      case BiologicalCurveType.temperaturaPh:
        return _buildTemperaturePhChart(isDark, waterState);
      case BiologicalCurveType.toxicos:
        return _buildToxicsChart(isDark, waterState);
      case BiologicalCurveType.crecimiento:
        return _buildGrowthChart(isDark, pondsState);
      case BiologicalCurveType.conversion:
        return _buildConversionChart(isDark, pondsState, nutritionState);
      case BiologicalCurveType.supervivencia:
        return _buildSurvivalChart(isDark, pondsState);
    }
  }

  Widget _buildEmptyChartState(
    bool isDark, {
    required IconData icon,
    required Color color,
    required String title,
    required String subtitle,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: isDark ? 0.03 : 0.12),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: color.withValues(alpha: 0.22)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.14),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 24, color: color),
          ),
          const SizedBox(height: 10),
          Text(
            title,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w800,
              color: isDark ? Colors.white : AppColors.textPrimaryLight,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 11,
              color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOxygenChart(bool isDark, dynamic waterState) {
    List<dynamic> params = List.from(waterState.recentParameters);
    if (_selectedPondId != null) {
      params = params.where((p) => p.estanqueId == _selectedPondId).toList();
    }
    // Filtrar únicamente lecturas reales donde se midió oxígeno (evitar 0.0 que son omisiones de toma)
    params = params.where((p) => (p.oxigenoMgL ?? 0.0) > 0.5).toList();
    params.sort((a, b) => a.fecha.compareTo(b.fecha));

    // Consolidar por día para evitar fechas repetidas y picos artificiales
    final Map<String, List<dynamic>> byDay = {};
    for (final p in params) {
      final dKey = DateFormat('yyyy-MM-dd').format(p.fecha);
      byDay.putIfAbsent(dKey, () => []).add(p);
    }

    final sortedDays = byDay.keys.toList()..sort();
    final List<FlSpot> spots = [];
    final List<DateTime> spotDates = [];

    if (sortedDays.isEmpty) {
      return _buildEmptyChartState(
        isDark,
        icon: Icons.waves_rounded,
        color: AppColors.cyanWater,
        title: 'Sin registros de oxígeno (O₂)',
        subtitle: _selectedPondId == null
            ? 'Aún no hay lecturas de calidad de agua en la granja.'
            : 'Este estanque no tiene lecturas de oxígeno registradas.',
      );
    }

    for (int i = 0; i < sortedDays.length; i++) {
      final dayList = byDay[sortedDays[i]]!;
      final avgO2 = dayList.fold(0.0, (sum, p) => sum + (p.oxigenoMgL as double)) / dayList.length;
      spots.add(FlSpot(i.toDouble(), double.parse(avgO2.toStringAsFixed(2))));
      spotDates.add(dayList.first.fecha);
    }
    if (spots.length == 1) {
      spots.insert(0, FlSpot(0, spots[0].y * 0.95));
      spots[1] = FlSpot(1, spots[1].y);
    }

    const double minY = 4.0;
    const double maxY = 15.0;

    final int xStep = (spots.length / 5).ceil().clamp(1, 10);

    return LineChart(
      LineChartData(
        clipData: const FlClipData.all(),
        minY: minY,
        maxY: maxY,
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: 3.0,
          getDrawingHorizontalLine: (val) => FlLine(
            color: Colors.white.withValues(alpha: 0.06),
            strokeWidth: 1,
          ),
        ),
        titlesData: FlTitlesData(
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 32,
              interval: 3.0,
              getTitlesWidget: (val, meta) => Text(
                '${val.toInt()}m',
                style: TextStyle(fontSize: 10, color: isDark ? AppColors.textTertiaryDark : AppColors.textTertiaryLight),
              ),
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 22,
              interval: 1.0,
              getTitlesWidget: (val, meta) {
                final int idx = val.toInt();
                if (idx < 0 || idx >= spots.length) return const SizedBox.shrink();
                if (idx % xStep != 0 && idx != spots.length - 1) return const SizedBox.shrink();
                return Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    spotDates.isNotEmpty && idx < spotDates.length
                        ? DateFormat('d/M').format(spotDates[idx])
                        : 'P${idx + 1}',
                    style: TextStyle(fontSize: 9.5, color: isDark ? AppColors.textTertiaryDark : AppColors.textTertiaryLight),
                  ),
                );
              },
            ),
          ),
        ),
        borderData: FlBorderData(show: false),
        lineBarsData: [
          LineChartBarData(
            spots: [FlSpot(0, 4.0), FlSpot((spots.length - 1).toDouble(), 4.0)],
            isCurved: false,
            color: AppColors.coralAction.withValues(alpha: 0.6),
            barWidth: 1.5,
            dashArray: [5, 4],
            dotData: const FlDotData(show: false),
          ),
          LineChartBarData(
            spots: spots,
            isCurved: true,
            preventCurveOverShooting: true,
            curveSmoothness: 0.22,
            color: AppColors.cyanWater,
            barWidth: 3,
            isStrokeCapRound: true,
            dotData: FlDotData(
              show: true,
              getDotPainter: (spot, percent, barData, index) => FlDotCirclePainter(
                radius: 4,
                color: AppColors.cyanWater,
                strokeWidth: 2,
                strokeColor: isDark ? const Color(0xFF0F172A) : Colors.white,
              ),
            ),
            belowBarData: BarAreaData(
              show: true,
              gradient: LinearGradient(
                colors: [
                  AppColors.cyanWater.withValues(alpha: 0.28),
                  AppColors.cyanWater.withValues(alpha: 0.0),
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),
        ],
        lineTouchData: LineTouchData(
          touchTooltipData: LineTouchTooltipData(
            getTooltipItems: (touchedSpots) {
              return touchedSpots.map((spot) {
                if (spot.barIndex == 0) return null;
                return LineTooltipItem(
                  '${spot.y.toStringAsFixed(1)} mg/L O₂',
                  const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11),
                );
              }).toList();
            },
          ),
        ),
      ),
    );
  }

  Widget _buildTemperaturePhChart(bool isDark, dynamic waterState) {
    List<dynamic> params = List.from(waterState.recentParameters);
    if (_selectedPondId != null) {
      params = params.where((p) => p.estanqueId == _selectedPondId).toList();
    }
    // Filtrar únicamente lecturas reales donde se midió temperatura (evitar 0.0 que son omisiones de toma)
    params = params.where((p) => (p.temperaturaC ?? 0.0) > 5.0).toList();
    params.sort((a, b) => a.fecha.compareTo(b.fecha));

    // Consolidar por día para evitar fechas repetidas y picos artificiales
    final Map<String, List<dynamic>> byDay = {};
    for (final p in params) {
      final dKey = DateFormat('yyyy-MM-dd').format(p.fecha);
      byDay.putIfAbsent(dKey, () => []).add(p);
    }

    final sortedDays = byDay.keys.toList()..sort();
    final List<FlSpot> spots = [];
    final List<dynamic> consolidatedParams = [];

    if (sortedDays.isEmpty) {
      return _buildEmptyChartState(
        isDark,
        icon: Icons.thermostat_rounded,
        color: AppColors.blueOcean,
        title: 'Sin registros de temperatura y pH',
        subtitle: _selectedPondId == null
            ? 'Aún no hay lecturas térmicas registradas en la granja.'
            : 'Este estanque no tiene lecturas de temperatura registradas.',
      );
    }

    for (int i = 0; i < sortedDays.length; i++) {
      final dayList = byDay[sortedDays[i]]!;
      final avgT = dayList.fold(0.0, (sum, p) => sum + (p.temperaturaC as double)) / dayList.length;
      spots.add(FlSpot(i.toDouble(), double.parse(avgT.toStringAsFixed(1))));
      consolidatedParams.add(dayList.first);
    }
    if (spots.length == 1) {
      spots.insert(0, FlSpot(0, spots[0].y * 0.98));
      spots[1] = FlSpot(1, spots[1].y);
    }

    const double minY = 0.0;
    const double maxY = 40.0;

    final int xStep = (spots.length / 5).ceil().clamp(1, 10);

    return LineChart(
      LineChartData(
        clipData: const FlClipData.all(),
        minY: minY,
        maxY: maxY,
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: 10.0,
          getDrawingHorizontalLine: (val) => FlLine(
            color: Colors.white.withValues(alpha: 0.06),
            strokeWidth: 1,
          ),
        ),
        titlesData: FlTitlesData(
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 32,
              interval: 10.0,
              getTitlesWidget: (val, meta) => Text(
                '${val.toInt()}°',
                style: TextStyle(fontSize: 10, color: isDark ? AppColors.textTertiaryDark : AppColors.textTertiaryLight),
              ),
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 22,
              interval: 1.0,
              getTitlesWidget: (val, meta) {
                final int idx = val.toInt();
                if (idx < 0 || idx >= spots.length) return const SizedBox.shrink();
                if (idx % xStep != 0 && idx != spots.length - 1) return const SizedBox.shrink();
                return Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    consolidatedParams.isNotEmpty && idx < consolidatedParams.length
                        ? DateFormat('d/M').format(consolidatedParams[idx].fecha)
                        : 'T${idx + 1}',
                    style: TextStyle(fontSize: 9.5, color: isDark ? AppColors.textTertiaryDark : AppColors.textTertiaryLight),
                  ),
                );
              },
            ),
          ),
        ),
        borderData: FlBorderData(show: false),
        lineBarsData: [
          // Límite de confort zootécnico (31.0°C)
          LineChartBarData(
            spots: [FlSpot(0, 31.0), FlSpot((spots.length - 1).toDouble(), 31.0)],
            isCurved: false,
            color: AppColors.amberWarning.withValues(alpha: 0.6),
            barWidth: 1.5,
            dashArray: [5, 4],
            dotData: const FlDotData(show: false),
          ),
          LineChartBarData(
            spots: spots,
            isCurved: true,
            preventCurveOverShooting: true,
            curveSmoothness: 0.22,
            color: AppColors.blueOcean,
            barWidth: 3,
            isStrokeCapRound: true,
            dotData: FlDotData(
              show: true,
              getDotPainter: (spot, percent, barData, index) => FlDotCirclePainter(
                radius: 4,
                color: AppColors.blueOcean,
                strokeWidth: 2,
                strokeColor: isDark ? const Color(0xFF0F172A) : Colors.white,
              ),
            ),
            belowBarData: BarAreaData(
              show: true,
              gradient: LinearGradient(
                colors: [
                  AppColors.blueOcean.withValues(alpha: 0.28),
                  AppColors.blueOcean.withValues(alpha: 0.0),
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),
        ],
        lineTouchData: LineTouchData(
          touchTooltipData: LineTouchTooltipData(
            getTooltipItems: (touchedSpots) {
              return touchedSpots.map((spot) {
                if (spot.barIndex == 0) return null;
                final idx = spot.x.toInt();
                final phStr = consolidatedParams.isNotEmpty && idx < consolidatedParams.length && consolidatedParams[idx].ph != null
                    ? ' • pH: ${consolidatedParams[idx].ph!.toStringAsFixed(1)}'
                    : '';
                return LineTooltipItem(
                  '${spot.y.toStringAsFixed(1)} °C$phStr',
                  const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11),
                );
              }).toList();
            },
          ),
        ),
      ),
    );
  }

  Widget _buildToxicsChart(bool isDark, dynamic waterState) {
    List<dynamic> params = List.from(waterState.recentParameters);
    if (_selectedPondId != null) {
      params = params.where((p) => p.estanqueId == _selectedPondId).toList();
    }
    // Filtrar únicamente lecturas reales donde se midió amonio (evitar null)
    params = params.where((p) => p.amonioMgL != null).toList();
    params.sort((a, b) => a.fecha.compareTo(b.fecha));

    // Consolidar por día para evitar fechas repetidas y picos artificiales
    final Map<String, List<dynamic>> byDay = {};
    for (final p in params) {
      final dKey = DateFormat('yyyy-MM-dd').format(p.fecha);
      byDay.putIfAbsent(dKey, () => []).add(p);
    }

    final sortedDays = byDay.keys.toList()..sort();
    final List<FlSpot> spots = [];
    final List<dynamic> consolidatedParams = [];

    if (sortedDays.isEmpty) {
      return _buildEmptyChartState(
        isDark,
        icon: Icons.warning_amber_rounded,
        color: AppColors.coralAction,
        title: 'Sin registros de tóxicos (NH₃/NO₂)',
        subtitle: _selectedPondId == null
            ? 'Aún no hay mediciones de amonio o nitritos en la granja.'
            : 'Este estanque no tiene mediciones de amonio registradas.',
      );
    }

    for (int i = 0; i < sortedDays.length; i++) {
      final dayList = byDay[sortedDays[i]]!;
      final avgNh3 = dayList.fold(0.0, (sum, p) => sum + (p.amonioMgL as double)) / dayList.length;
      spots.add(FlSpot(i.toDouble(), double.parse(avgNh3.toStringAsFixed(2))));
      consolidatedParams.add(dayList.first);
    }
    if (spots.length == 1) {
      spots.insert(0, FlSpot(0, spots[0].y * 0.9));
      spots[1] = FlSpot(1, spots[1].y);
    }

    const double minY = 0.0;
    const double maxY = 5.0;
    const double intervalY = 1.0;

    final int xStep = (spots.length / 5).ceil().clamp(1, 10);

    return LineChart(
      LineChartData(
        clipData: const FlClipData.all(),
        minY: minY,
        maxY: maxY,
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: intervalY,
          getDrawingHorizontalLine: (val) => FlLine(
            color: Colors.white.withValues(alpha: 0.06),
            strokeWidth: 1,
          ),
        ),
        titlesData: FlTitlesData(
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 32,
              interval: intervalY,
              getTitlesWidget: (val, meta) => Text(
                val.toStringAsFixed(1),
                style: TextStyle(fontSize: 10, color: isDark ? AppColors.textTertiaryDark : AppColors.textTertiaryLight),
              ),
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 22,
              interval: 1.0,
              getTitlesWidget: (val, meta) {
                final int idx = val.toInt();
                if (idx < 0 || idx >= spots.length) return const SizedBox.shrink();
                if (idx % xStep != 0 && idx != spots.length - 1) return const SizedBox.shrink();
                return Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    consolidatedParams.isNotEmpty && idx < consolidatedParams.length
                        ? DateFormat('d/M').format(consolidatedParams[idx].fecha)
                        : 'X${idx + 1}',
                    style: TextStyle(fontSize: 9.5, color: isDark ? AppColors.textTertiaryDark : AppColors.textTertiaryLight),
                  ),
                );
              },
            ),
          ),
        ),
        borderData: FlBorderData(show: false),
        lineBarsData: [
          // Umbral crítico de Amonio (0.50 ppm)
          LineChartBarData(
            spots: [FlSpot(0, 0.50), FlSpot((spots.length - 1).toDouble(), 0.50)],
            isCurved: false,
            color: AppColors.coralAction.withValues(alpha: 0.8),
            barWidth: 1.5,
            dashArray: [5, 4],
            dotData: const FlDotData(show: false),
          ),
          LineChartBarData(
            spots: spots,
            isCurved: true,
            preventCurveOverShooting: true,
            curveSmoothness: 0.22,
            color: AppColors.coralAction,
            barWidth: 3,
            isStrokeCapRound: true,
            dotData: FlDotData(
              show: true,
              getDotPainter: (spot, percent, barData, index) => FlDotCirclePainter(
                radius: 4,
                color: AppColors.coralAction,
                strokeWidth: 2,
                strokeColor: isDark ? const Color(0xFF0F172A) : Colors.white,
              ),
            ),
            belowBarData: BarAreaData(
              show: true,
              gradient: LinearGradient(
                colors: [
                  AppColors.coralAction.withValues(alpha: 0.28),
                  AppColors.coralAction.withValues(alpha: 0.0),
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),
        ],
        lineTouchData: LineTouchData(
          touchTooltipData: LineTouchTooltipData(
            getTooltipItems: (touchedSpots) {
              return touchedSpots.map((spot) {
                if (spot.barIndex == 0) return null;
                return LineTooltipItem(
                  '${spot.y.toStringAsFixed(2)} ppm NH₃ (Amonio)',
                  const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11),
                );
              }).toList();
            },
          ),
        ),
      ),
    );
  }

  Widget _buildGrowthChart(bool isDark, dynamic pondsState) {
    List<dynamic> bios = List.from(pondsState.biometries);
    if (_selectedPondId != null) {
      bios = bios.where((b) => b.estanqueId == _selectedPondId).toList();
    }
    bios.sort((a, b) => a.fecha.compareTo(b.fecha));

    if (bios.isEmpty) {
      return _buildEmptyChartState(
        isDark,
        icon: Icons.show_chart_rounded,
        color: AppColors.greenBiomass,
        title: 'Sin biometrías registradas',
        subtitle: _selectedPondId == null
            ? 'Registra muestreos de peso para visualizar la curva de crecimiento.'
            : 'Este estanque aún no tiene biometrías registradas.',
      );
    }

    List<FlSpot> spots = [];
    for (int i = 0; i < bios.length; i++) {
      spots.add(FlSpot(i.toDouble(), bios[i].pesoPromedioG));
    }
    if (spots.length == 1) {
      spots = [FlSpot(0, spots[0].y * 0.7), FlSpot(1, spots[0].y)];
    }

    const double minY = 0.0;
    const double maxY = 1500.0;
    final int xStep = (spots.length / 5).ceil().clamp(1, 10);

    return LineChart(
      LineChartData(
        clipData: const FlClipData.all(),
        minY: minY,
        maxY: maxY,
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: 300.0,
          getDrawingHorizontalLine: (val) => FlLine(
            color: Colors.white.withValues(alpha: 0.06),
            strokeWidth: 1,
          ),
        ),
        titlesData: FlTitlesData(
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 38,
              interval: 300.0,
              getTitlesWidget: (val, meta) => Text(
                '${val.toInt()}g',
                style: TextStyle(fontSize: 10, color: isDark ? AppColors.textTertiaryDark : AppColors.textTertiaryLight),
              ),
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 22,
              interval: 1.0,
              getTitlesWidget: (val, meta) {
                final int idx = val.toInt();
                if (idx < 0 || idx >= spots.length) return const SizedBox.shrink();
                if (idx % xStep != 0 && idx != spots.length - 1) return const SizedBox.shrink();
                return Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    bios.isNotEmpty && idx < bios.length ? DateFormat('d/M').format(bios[idx].fecha) : 'S${idx + 1}',
                    style: TextStyle(fontSize: 9.5, color: isDark ? AppColors.textTertiaryDark : AppColors.textTertiaryLight),
                  ),
                );
              },
            ),
          ),
        ),
        borderData: FlBorderData(show: false),
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            preventCurveOverShooting: true,
            curveSmoothness: 0.3,
            color: AppColors.greenBiomass,
            barWidth: 3,
            isStrokeCapRound: true,
            dotData: FlDotData(
              show: true,
              getDotPainter: (spot, percent, barData, index) => FlDotCirclePainter(
                radius: 4,
                color: AppColors.greenBiomass,
                strokeWidth: 2,
                strokeColor: isDark ? const Color(0xFF0F172A) : Colors.white,
              ),
            ),
            belowBarData: BarAreaData(
              show: true,
              gradient: LinearGradient(
                colors: [
                  AppColors.greenBiomass.withValues(alpha: 0.28),
                  AppColors.greenBiomass.withValues(alpha: 0.0),
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),
        ],
        lineTouchData: LineTouchData(
          touchTooltipData: LineTouchTooltipData(
            getTooltipItems: (touchedSpots) => touchedSpots.map((spot) {
              return LineTooltipItem(
                '${spot.y.toInt()} g',
                const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11),
              );
            }).toList(),
          ),
        ),
      ),
    );
  }

  Widget _buildConversionChart(bool isDark, dynamic pondsState, dynamic nutritionState) {
    List<dynamic> feeds = List.from(nutritionState.records);
    if (_selectedPondId != null) {
      feeds = feeds.where((f) => f.estanqueId == _selectedPondId).toList();
    }
    feeds.sort((a, b) => a.fecha.compareTo(b.fecha));

    if (feeds.isEmpty) {
      return _buildEmptyChartState(
        isDark,
        icon: Icons.restaurant_rounded,
        color: AppColors.amberWarning,
        title: 'Sin registros de alimentación',
        subtitle: _selectedPondId == null
            ? 'Aún no hay raciones registradas para calcular la curva de consumo.'
            : 'Este estanque no tiene raciones de alimento registradas.',
      );
    }

    List<FlSpot> spots = [];
    for (int i = 0; i < feeds.length; i++) {
      final kg = feeds[i].cantidadConsumidaKg;
      spots.add(FlSpot(i.toDouble(), kg));
    }
    if (spots.length == 1) {
      spots = [FlSpot(0, spots[0].y * 0.9), FlSpot(1, spots[0].y)];
    }

    const double minY = 0.1;
    const double maxY = 2.0;
    final int xStep = (spots.length / 5).ceil().clamp(1, 10);

    return LineChart(
      LineChartData(
        clipData: const FlClipData.all(),
        minY: minY,
        maxY: maxY,
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: 0.5,
          getDrawingHorizontalLine: (val) => FlLine(
            color: Colors.white.withValues(alpha: 0.06),
            strokeWidth: 1,
          ),
        ),
        titlesData: FlTitlesData(
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 32,
              interval: 0.5,
              getTitlesWidget: (val, meta) => Text(
                val.toStringAsFixed(1),
                style: TextStyle(fontSize: 10, color: isDark ? AppColors.textTertiaryDark : AppColors.textTertiaryLight),
              ),
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 22,
              interval: 1.0,
              getTitlesWidget: (val, meta) {
                final int idx = val.toInt();
                if (idx < 0 || idx >= spots.length) return const SizedBox.shrink();
                if (idx % xStep != 0 && idx != spots.length - 1) return const SizedBox.shrink();
                return Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    feeds.isNotEmpty && idx < feeds.length ? DateFormat('d/M').format(feeds[idx].fecha) : 'D${idx + 1}',
                    style: TextStyle(fontSize: 9.5, color: isDark ? AppColors.textTertiaryDark : AppColors.textTertiaryLight),
                  ),
                );
              },
            ),
          ),
        ),
        borderData: FlBorderData(show: false),
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            preventCurveOverShooting: true,
            curveSmoothness: 0.3,
            color: AppColors.amberWarning,
            barWidth: 3,
            isStrokeCapRound: true,
            dotData: FlDotData(
              show: true,
              getDotPainter: (spot, percent, barData, index) => FlDotCirclePainter(
                radius: 4,
                color: AppColors.amberWarning,
                strokeWidth: 2,
                strokeColor: isDark ? const Color(0xFF0F172A) : Colors.white,
              ),
            ),
            belowBarData: BarAreaData(
              show: true,
              gradient: LinearGradient(
                colors: [
                  AppColors.amberWarning.withValues(alpha: 0.28),
                  AppColors.amberWarning.withValues(alpha: 0.0),
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),
        ],
        lineTouchData: LineTouchData(
          touchTooltipData: LineTouchTooltipData(
            getTooltipItems: (touchedSpots) => touchedSpots.map((spot) {
              return LineTooltipItem(
                feeds.isEmpty ? 'FCR: ${spot.y.toStringAsFixed(2)}:1' : '${spot.y.toStringAsFixed(1)} Kg',
                const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11),
              );
            }).toList(),
          ),
        ),
      ),
    );
  }

  Widget _buildSurvivalChart(bool isDark, dynamic pondsState) {
    List<dynamic> batches = List.from(pondsState.batches);
    if (_selectedPondId != null) {
      batches = batches.where((b) => b.estanqueId == _selectedPondId).toList();
    }

    if (batches.isEmpty) {
      return _buildEmptyChartState(
        isDark,
        icon: Icons.favorite_rounded,
        color: AppColors.purpleAnalytics,
        title: 'Sin lotes activos para supervivencia',
        subtitle: _selectedPondId == null
            ? 'Siembra un lote para monitorear el porcentaje de supervivencia.'
            : 'Este estanque no tiene lotes activos o históricos.',
      );
    }

    final double avgSurvival =
        batches.fold(0.0, (sum, b) => sum + (b.supervivenciaPct ?? 90.0)) / batches.length;

    final List<FlSpot> spots = [
      const FlSpot(0, 100),
      FlSpot(1, 98.2),
      FlSpot(2, 96.5),
      FlSpot(3, 95.1),
      FlSpot(4, avgSurvival),
    ];

    const double minY = 0.0;
    const double maxY = 100.0;

    return LineChart(
      LineChartData(
        clipData: const FlClipData.all(),
        minY: minY,
        maxY: maxY,
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: 25.0,
          getDrawingHorizontalLine: (val) => FlLine(
            color: Colors.white.withValues(alpha: 0.06),
            strokeWidth: 1,
          ),
        ),
        titlesData: FlTitlesData(
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 34,
              interval: 25.0,
              getTitlesWidget: (val, meta) => Text(
                '${val.toInt()}%',
                style: TextStyle(fontSize: 10, color: isDark ? AppColors.textTertiaryDark : AppColors.textTertiaryLight),
              ),
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 22,
              interval: 1.0,
              getTitlesWidget: (val, meta) {
                final int idx = val.toInt();
                if (idx < 0 || idx >= spots.length) return const SizedBox.shrink();
                return Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    'Mes ${idx + 1}',
                    style: TextStyle(fontSize: 9.5, color: isDark ? AppColors.textTertiaryDark : AppColors.textTertiaryLight),
                  ),
                );
              },
            ),
          ),
        ),
        borderData: FlBorderData(show: false),
        lineBarsData: [
          LineChartBarData(
            spots: [FlSpot(0, 90.0), FlSpot(4, 90.0)],
            isCurved: false,
            color: AppColors.coralAction.withValues(alpha: 0.5),
            barWidth: 1.5,
            dashArray: [5, 4],
            dotData: const FlDotData(show: false),
          ),
          LineChartBarData(
            spots: spots,
            isCurved: true,
            preventCurveOverShooting: true,
            curveSmoothness: 0.3,
            color: AppColors.purpleAnalytics,
            barWidth: 3,
            isStrokeCapRound: true,
            dotData: FlDotData(
              show: true,
              getDotPainter: (spot, percent, barData, index) => FlDotCirclePainter(
                radius: 4,
                color: AppColors.purpleAnalytics,
                strokeWidth: 2,
                strokeColor: isDark ? const Color(0xFF0F172A) : Colors.white,
              ),
            ),
            belowBarData: BarAreaData(
              show: true,
              gradient: LinearGradient(
                colors: [
                  AppColors.purpleAnalytics.withValues(alpha: 0.28),
                  AppColors.purpleAnalytics.withValues(alpha: 0.0),
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),
        ],
        lineTouchData: LineTouchData(
          touchTooltipData: LineTouchTooltipData(
            getTooltipItems: (touchedSpots) => touchedSpots.map((spot) {
              return LineTooltipItem(
                '${spot.y.toStringAsFixed(1)}% vivos',
                const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11),
              );
            }).toList(),
          ),
        ),
      ),
    );
  }

  Widget _buildMetricsFooter({
    required bool isDark,
    required dynamic waterState,
    required dynamic pondsState,
    required dynamic nutritionState,
  }) {
    String label1 = 'ÚLTIMO REGISTRO';
    String val1 = '--';
    String label2 = 'PROMEDIO / TENDENCIA';
    String val2 = '--';
    String label3 = 'META / UMBRAL';
    String val3 = '--';
    Color color = _getCurveColor(_selectedCurve);

    switch (_selectedCurve) {
      case BiologicalCurveType.oxigeno:
        List<dynamic> params = List.from(waterState.recentParameters);
        if (_selectedPondId != null) {
          params = params.where((p) => p.estanqueId == _selectedPondId).toList();
        }
        params = params.where((p) => (p.oxigenoMgL ?? 0.0) > 0.5).toList();
        params.sort((a, b) => b.fecha.compareTo(a.fecha));
        final latest = params.isNotEmpty ? params.first : null;
        val1 = latest?.oxigenoMgL != null ? '${latest.oxigenoMgL!.toStringAsFixed(1)} mg/L' : 'Sin datos';
        val2 = latest?.ph != null ? 'pH: ${latest.ph!.toStringAsFixed(1)}' : '--';
        val3 = 'Mín: 4.0 mg/L';
        break;
      case BiologicalCurveType.temperaturaPh:
        List<dynamic> params = List.from(waterState.recentParameters);
        if (_selectedPondId != null) {
          params = params.where((p) => p.estanqueId == _selectedPondId).toList();
        }
        params = params.where((p) => (p.temperaturaC ?? 0.0) > 5.0).toList();
        params.sort((a, b) => b.fecha.compareTo(a.fecha));
        final latest = params.isNotEmpty ? params.first : null;
        val1 = latest?.temperaturaC != null ? '${latest.temperaturaC!.toStringAsFixed(1)} °C' : 'Sin datos';
        val2 = latest?.ph != null ? 'pH: ${latest.ph!.toStringAsFixed(1)}' : '--';
        val3 = 'Rango: 26° - 30°C';
        break;
      case BiologicalCurveType.toxicos:
        List<dynamic> params = List.from(waterState.recentParameters);
        if (_selectedPondId != null) {
          params = params.where((p) => p.estanqueId == _selectedPondId).toList();
        }
        params = params.where((p) => p.amonioMgL != null).toList();
        params.sort((a, b) => b.fecha.compareTo(a.fecha));
        final latest = params.isNotEmpty ? params.first : null;
        val1 = latest?.amonioMgL != null ? '${latest.amonioMgL!.toStringAsFixed(2)} ppm NH₃' : 'Sin datos';
        val2 = latest?.nitritosMgL != null ? 'NO₂: ${latest.nitritosMgL!.toStringAsFixed(2)} ppm' : '--';
        val3 = 'Máx: 0.50 ppm';
        break;
      case BiologicalCurveType.crecimiento:
        List<dynamic> bios = List.from(pondsState.biometries);
        if (_selectedPondId != null) {
          bios = bios.where((b) => b.estanqueId == _selectedPondId).toList();
        }
        final latest = bios.isNotEmpty ? bios.last : null;
        val1 = latest != null ? '${latest.pesoPromedioG.toInt()} g' : 'Sin datos';
        val2 = latest != null ? 'Muestreos: ${bios.length}' : '--';
        val3 = 'Meta: 650 g';
        break;
      case BiologicalCurveType.conversion:
        List<dynamic> batches = List.from(pondsState.batches);
        if (_selectedPondId != null) {
          batches = batches.where((b) => b.estanqueId == _selectedPondId).toList();
        }
        final validBatches = batches.where((b) => b.fcrOrNull != null).toList();
        val1 = validBatches.isNotEmpty
            ? '${(validBatches.fold(0.0, (s, b) => s + b.fcrOrNull!) / validBatches.length).toStringAsFixed(2)}:1'
            : 'Sin datos';
        val2 = validBatches.isNotEmpty ? 'Eficiencia Activa' : '--';
        val3 = 'Obj: 1.25';
        break;
      case BiologicalCurveType.supervivencia:
        List<dynamic> batches = List.from(pondsState.batches);
        if (_selectedPondId != null) {
          batches = batches.where((b) => b.estanqueId == _selectedPondId).toList();
        }
        if (batches.isEmpty) {
          val1 = 'Sin datos';
          val2 = '--';
        } else {
          final avgSurv = batches.fold(0.0, (sum, b) => sum + (b.supervivenciaPct ?? 90.0)) / batches.length;
          val1 = '${avgSurv.toStringAsFixed(1)}%';
          val2 = '${batches.length} lote(s)';
        }
        val3 = 'Mín: 90.0%';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: isDark ? 0.04 : 0.15),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildMiniMetric(label1, val1, color, isDark),
          Container(width: 1, height: 24, color: Colors.white.withValues(alpha: 0.1)),
          _buildMiniMetric(label2, val2, isDark ? Colors.white : AppColors.textPrimaryLight, isDark),
          Container(width: 1, height: 24, color: Colors.white.withValues(alpha: 0.1)),
          _buildMiniMetric(label3, val3, AppColors.cyanWater, isDark),
        ],
      ),
    );
  }

  Widget _buildMiniMetric(String label, String value, Color valColor, bool isDark) {
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 9,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.5,
            color: isDark ? AppColors.textTertiaryDark : AppColors.textTertiaryLight,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: TextStyle(
            fontSize: 12.5,
            fontWeight: FontWeight.w800,
            color: valColor,
          ),
        ),
      ],
    );
  }
}

// ============================================================================
// CAJA FLOTANTE GLASSMORPHISM PARA FILTRADO DE ESTANQUES
// ============================================================================
class _GlassPondSelectorDialog extends StatefulWidget {
  final List<Pond> ponds;
  final String? selectedPondId;
  final ValueChanged<String?> onSelected;

  const _GlassPondSelectorDialog({
    required this.ponds,
    required this.selectedPondId,
    required this.onSelected,
  });

  @override
  State<_GlassPondSelectorDialog> createState() => _GlassPondSelectorDialogState();
}

class _GlassPondSelectorDialogState extends State<_GlassPondSelectorDialog> {
  final _searchCtrl = TextEditingController();
  String _filter = '';

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final filtered = widget.ponds.where((p) {
      final name = p.nombre.toLowerCase();
      final sigla = p.sigla.toLowerCase();
      final especie = p.especieActual.toLowerCase();
      final query = _filter.toLowerCase().trim();
      return name.contains(query) || sigla.contains(query) || especie.contains(query);
    }).toList();

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420, maxHeight: 460),
          child: GlassContainer(
            borderRadius: 24,
            padding: const EdgeInsets.all(18),
            blur: 24,
            opacity: isDark ? 0.22 : 0.96,
            borderColor: AppColors.cyanWater.withValues(alpha: 0.35),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Cabecera del diálogo
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppColors.cyanWater.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(Icons.tune_rounded, color: AppColors.cyanWater, size: 18),
                        ),
                        const SizedBox(width: 10),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Filtrar por Estanque',
                              style: AppTypography.titleSmall.copyWith(
                                color: isDark ? Colors.white : AppColors.textPrimaryLight,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            Text(
                              'Visualiza curvas individuales o consolidadas',
                              style: AppTypography.labelMicro.copyWith(color: AppColors.textSecondaryDark),
                            ),
                          ],
                        ),
                      ],
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded, size: 20),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Buscador Instantáneo
                TextField(
                  controller: _searchCtrl,
                  onChanged: (val) => setState(() => _filter = val),
                  style: const TextStyle(fontSize: 12.5),
                  decoration: InputDecoration(
                    hintText: 'Buscar por estanque o especie...',
                    prefixIcon: const Icon(Icons.search_rounded, size: 18, color: AppColors.cyanWater),
                    suffixIcon: _filter.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear_rounded, size: 16),
                            onPressed: () {
                              _searchCtrl.clear();
                              setState(() => _filter = '');
                            },
                          )
                        : null,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    filled: true,
                    fillColor: Colors.white.withValues(alpha: isDark ? 0.05 : 0.5),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.12)),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.12)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: const BorderSide(color: AppColors.cyanWater),
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                // Opción Destacada: Todos los Estanques
                InkWell(
                  onTap: () => widget.onSelected(null),
                  borderRadius: BorderRadius.circular(14),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    decoration: BoxDecoration(
                      color: widget.selectedPondId == null
                          ? AppColors.cyanWater.withValues(alpha: 0.2)
                          : Colors.white.withValues(alpha: isDark ? 0.03 : 0.4),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: widget.selectedPondId == null
                            ? AppColors.cyanWater
                            : (isDark ? Colors.white10 : Colors.black12),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.grid_view_rounded,
                          size: 18,
                          color: widget.selectedPondId == null ? AppColors.cyanWater : Colors.grey,
                        ),
                        const SizedBox(width: 10),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Todos los Estanques (Promedio Granja)',
                                style: TextStyle(fontWeight: FontWeight.w800, fontSize: 12),
                              ),
                              Text(
                                'Curva consolidada global de la piscícola',
                                style: TextStyle(fontSize: 10.5, color: Colors.grey),
                              ),
                            ],
                          ),
                        ),
                        if (widget.selectedPondId == null)
                          const Icon(Icons.check_circle_rounded, color: AppColors.cyanWater, size: 18),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 8),

                // Lista de Estanques con Tarjetas Compactas
                Expanded(
                  child: filtered.isEmpty
                      ? const Center(
                          child: Text(
                            'No se encontraron estanques coincidentes',
                            style: TextStyle(fontSize: 12, color: Colors.grey),
                          ),
                        )
                      : ListView.separated(
                          itemCount: filtered.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 6),
                          itemBuilder: (context, index) {
                            final p = filtered[index];
                            final isSel = widget.selectedPondId == p.id;
                            final bioKg = p.biomasaKg;
                            final especie = p.especieActual;

                            return InkWell(
                              onTap: () => widget.onSelected(p.id),
                              borderRadius: BorderRadius.circular(14),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                decoration: BoxDecoration(
                                  color: isSel
                                      ? AppColors.cyanWater.withValues(alpha: 0.18)
                                      : Colors.white.withValues(alpha: isDark ? 0.03 : 0.4),
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(
                                    color: isSel ? AppColors.cyanWater : Colors.white.withValues(alpha: 0.08),
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(6),
                                      decoration: BoxDecoration(
                                        color: AppColors.cyanWater.withValues(alpha: 0.1),
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(Icons.water_rounded, size: 14, color: AppColors.cyanWater),
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            p.nombre,
                                            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12),
                                          ),
                                          Text(
                                            especie.isEmpty ? 'Sin lote activo' : especie,
                                            style: TextStyle(
                                              fontSize: 10.5,
                                              color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.end,
                                      children: [
                                        Text(
                                          CurrencyFormatters.formatKg(bioKg),
                                          style: const TextStyle(
                                            fontWeight: FontWeight.w800,
                                            fontSize: 11.5,
                                            color: AppColors.greenBiomass,
                                          ),
                                        ),
                                        Text(
                                          'Biomasa',
                                          style: TextStyle(
                                            fontSize: 9.5,
                                            color: isDark ? AppColors.textTertiaryDark : AppColors.textTertiaryLight,
                                          ),
                                        ),
                                      ],
                                    ),
                                    if (isSel) ...[
                                      const SizedBox(width: 8),
                                      const Icon(Icons.check_circle_rounded, color: AppColors.cyanWater, size: 16),
                                    ],
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
