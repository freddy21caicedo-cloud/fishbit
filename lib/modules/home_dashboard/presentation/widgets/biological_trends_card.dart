import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:fishbit_finance/core/design_system/app_colors.dart';
import 'package:fishbit_finance/core/design_system/app_typography.dart';
import 'package:fishbit_finance/core/design_system/glass_container.dart';
import 'package:fishbit_finance/core/design_system/glass_select_field.dart';
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

class _DailyRangeBar {
  final String dayLabel;
  final DateTime date;
  final double? minVal;
  final double? maxVal;
  final double? avgVal;
  final int count;
  final bool showTopDot;
  final bool showBottomDot;

  const _DailyRangeBar({
    required this.dayLabel,
    required this.date,
    this.minVal,
    this.maxVal,
    this.avgVal,
    this.count = 0,
    this.showTopDot = false,
    this.showBottomDot = false,
  });

  bool get hasData => minVal != null && maxVal != null && count > 0;
}

class _RecentReading {
  final String timeLabel;
  final String valueLabel;

  const _RecentReading({
    required this.timeLabel,
    required this.valueLabel,
  });
}

class _TrendDataset {
  final String title;
  final String unit;
  final Color accent;
  final Color accentLight;
  final double? minVal;
  final double? maxVal;
  final double? avgVal;
  final int decimals;
  final String dateRangeLabel;
  final String thresholdLabel;
  final String emptyTitle;
  final String emptySubtitle;
  final IconData emptyIcon;
  final List<_DailyRangeBar> bars;
  final List<_RecentReading> readings;

  const _TrendDataset({
    required this.title,
    required this.unit,
    required this.accent,
    required this.accentLight,
    this.minVal,
    this.maxVal,
    this.avgVal,
    this.decimals = 1,
    required this.dateRangeLabel,
    required this.thresholdLabel,
    required this.emptyTitle,
    required this.emptySubtitle,
    required this.emptyIcon,
    required this.bars,
    required this.readings,
  });

  bool get hasData => minVal != null && maxVal != null && avgVal != null;

  String formatValue(double v) =>
      decimals == 0 ? v.round().toString() : v.toStringAsFixed(decimals);

  String get rangeText {
    if (!hasData) return '--';
    final lo = formatValue(minVal!);
    final hi = formatValue(maxVal!);
    return lo == hi ? lo : '$lo-$hi';
  }

  String get avgBadgeText =>
      avgVal != null ? 'Prom. ${formatValue(avgVal!)}' : 'Prom. --';
}

class BiologicalTrendsCard extends ConsumerStatefulWidget {
  const BiologicalTrendsCard({super.key});

  @override
  ConsumerState<BiologicalTrendsCard> createState() =>
      _BiologicalTrendsCardState();
}

class _BiologicalTrendsCardState extends ConsumerState<BiologicalTrendsCard> {
  BiologicalCurveType _selectedCurve = BiologicalCurveType.oxigeno;
  String? _selectedPondId; // null = Todos los estanques

  static const _dayShortNames = ['Lu', 'Ma', 'Mi', 'Ju', 'Vi', 'Sá', 'Do'];

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final pondsState = ref.watch(pondsProvider);
    final waterState = ref.watch(waterQualityProvider);
    final nutritionState = ref.watch(nutritionProvider);

    final ponds = pondsState.ponds;
    final pondMap = {for (final p in ponds) p.id: p};

    final dataset = _buildDataset(
      type: _selectedCurve,
      waterState: waterState,
      pondsState: pondsState,
      nutritionState: nutritionState,
      pondMap: pondMap,
    );

    final cardBg = isDark ? AppColors.surfaceDark : Colors.white;
    final dividerColor = isDark
        ? Colors.white.withValues(alpha: 0.08)
        : const Color(0xFFF0F0F0);
    final titleColor = isDark ? Colors.white : const Color(0xFF1A1A1A);
    final mutedColor =
        isDark ? AppColors.textSecondaryDark : const Color(0xFF999999);
    final unitColor =
        isDark ? AppColors.textTertiaryDark : const Color(0xFFB0B0B0);

    return GlassContainer(
      borderRadius: 20,
      padding: const EdgeInsets.all(18),
      isOverlay: false,
      tintColor: cardBg,
      opacity: isDark ? 0.92 : 0.98,
      borderColor: isDark
          ? dataset.accent.withValues(alpha: 0.28)
          : AppColors.glassBorderLight,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Kicker de sección
          Text(
            'ANALÍTICA BIOLÓGICA Y TENDENCIAS',
            style: AppTypography.labelMicro.copyWith(
              color: dataset.accent,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.1,
            ),
          ),
          const SizedBox(height: 12),

          // Selectores estilo Bitácora (Estanque + Analítica)
          LayoutBuilder(
            builder: (context, constraints) {
              final pondSelector = _buildPondSelector(
                ponds: ponds,
                waterState: waterState,
                pondsState: pondsState,
                nutritionState: nutritionState,
              );
              final metricSelector = _buildAnalyticsSelector();

              if (constraints.maxWidth >= 560) {
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(child: pondSelector),
                    const SizedBox(width: 12),
                    Expanded(child: metricSelector),
                  ],
                );
              }
              return Column(
                children: [
                  pondSelector,
                  const SizedBox(height: 10),
                  metricSelector,
                ],
              );
            },
          ),
          const SizedBox(height: 18),

          // ─── Cabecera estilo Uiverse NK2552003 (.header) ───
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Text(
                  dataset.title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: titleColor,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              _FullStatsButton(
                label: 'Ver bitácora →',
                isDark: isDark,
                onTap: () => GoRouter.maybeOf(context)?.go('/bitacora'),
              ),
            ],
          ),
          const SizedBox(height: 6),

          // ─── Rango principal (.range) ───
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Flexible(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    dataset.rangeText,
                    style: TextStyle(
                      fontSize: 30,
                      fontWeight: FontWeight.w700,
                      color: titleColor,
                      letterSpacing: -0.5,
                      height: 1.1,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 5),
              Text(
                dataset.unit,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w300,
                  color: unitColor,
                  height: 1.1,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),

          // ─── Rango de fechas (.date-range) ───
          Text(
            dataset.dateRangeLabel,
            style: TextStyle(
              fontSize: 11,
              color: mutedColor,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 18),

          // ─── Gráfica de barras de rango flotantes (.chart-container) ───
          if (dataset.hasData)
            _RangeBarChart(
              dataset: dataset,
              isDark: isDark,
            )
          else
            _buildEmptyChartState(
              isDark: isDark,
              icon: dataset.emptyIcon,
              color: dataset.accent,
              title: dataset.emptyTitle,
              subtitle: dataset.emptySubtitle,
            ),
          const SizedBox(height: 18),

          // ─── Lecturas recientes + Meta/Umbral (.readings) ───
          Container(
            decoration: BoxDecoration(
              border: Border(
                top: BorderSide(color: dividerColor, width: 1.5),
              ),
            ),
            padding: const EdgeInsets.only(top: 10),
            child: Column(
              children: [
                ...dataset.readings.map(
                  (r) => Container(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    decoration: BoxDecoration(
                      border: Border(
                        bottom: BorderSide(color: dividerColor, width: 1.5),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            r.timeLabel,
                            style: TextStyle(
                              fontSize: 10.5,
                              color: mutedColor,
                              fontWeight: FontWeight.w500,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          r.valueLabel,
                          style: TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w700,
                            color: titleColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(top: 8, bottom: 2),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Meta / Umbral',
                        style: TextStyle(
                          fontSize: 10.5,
                          color: mutedColor,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Text(
                        dataset.thresholdLabel,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: dataset.accent,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPondSelector({
    required List<Pond> ponds,
    required dynamic waterState,
    required dynamic pondsState,
    required dynamic nutritionState,
  }) {
    final totalDataCount = waterState.recentParameters.length +
        nutritionState.records.length +
        pondsState.biometries.length +
        pondsState.mortalityRecords.length;

    final options = <GlassSelectOption<String>>[
      GlassSelectOption<String>(
        value: '__ALL__',
        label: 'Todos los Estanques (${ponds.length})',
        subtitle: 'Promedio general de la granja',
        icon: Icons.grid_view_rounded,
        badgeText: '$totalDataCount datos',
        badgeColor: AppColors.cyanWater,
      ),
      ...ponds.map((pond) {
        final countWater = waterState.recentParameters
            .where((p) => p.estanqueId == pond.id)
            .length;
        final countFeeding = nutritionState.records
            .where((r) => r.estanqueId == pond.id)
            .length;
        final countBio = pondsState.biometries
            .where((b) => b.estanqueId == pond.id)
            .length;
        final countMort = pondsState.mortalityRecords
            .where((m) => m.estanqueId == pond.id)
            .length;
        final pondTotal = countWater + countFeeding + countBio + countMort;

        final parts = <String>[];
        if (countWater > 0) parts.add('$countWater O₂/pH');
        if (countFeeding > 0) parts.add('$countFeeding raciones');
        if (countBio > 0) parts.add('$countBio muestreo(s)');
        if (countMort > 0) parts.add('$countMort baja(s)');
        final subtitle = parts.isNotEmpty
            ? parts.join(' • ')
            : (pond.especieActual.isNotEmpty
                ? 'Cultivo: ${pond.especieActual}'
                : 'Estanque activo');

        return GlassSelectOption<String>(
          value: pond.id,
          label: '${pond.sigla} • ${pond.nombreLimpio}',
          subtitle: subtitle,
          icon: Icons.water_rounded,
          badgeText: '$pondTotal datos',
          badgeColor:
              pondTotal > 0 ? AppColors.cyanWater : AppColors.textSecondaryDark,
        );
      }),
    ];

    return GlassSelectField<String>(
      label: 'ESTANQUE DE CONSULTA',
      placeholder: 'Buscar estanque por nombre o sigla...',
      value: _selectedPondId ?? '__ALL__',
      accentColor: AppColors.cyanWater,
      leadingIcon: Icons.tune_rounded,
      options: options,
      onChanged: (val) {
        setState(() {
          _selectedPondId = (val == null || val == '__ALL__') ? null : val;
        });
      },
    );
  }

  Widget _buildAnalyticsSelector() {
    final accent = _getCurveAccent(_selectedCurve);
    const options = <GlassSelectOption<BiologicalCurveType>>[
      GlassSelectOption<BiologicalCurveType>(
        value: BiologicalCurveType.oxigeno,
        label: 'Oxígeno (O₂)',
        subtitle: 'Calidad de agua • mg/L',
        icon: Icons.waves_rounded,
        badgeText: 'Mín 4.0',
        badgeColor: AppColors.cyanWater,
      ),
      GlassSelectOption<BiologicalCurveType>(
        value: BiologicalCurveType.temperaturaPh,
        label: 'Temp & pH (°C)',
        subtitle: 'Confort térmico y pH • °C',
        icon: Icons.thermostat_rounded,
        badgeText: '26–30°C',
        badgeColor: AppColors.blueOcean,
      ),
      GlassSelectOption<BiologicalCurveType>(
        value: BiologicalCurveType.toxicos,
        label: 'Tóxicos (NH₃/NO₂)',
        subtitle: 'Amonio y nitritos • ppm',
        icon: Icons.warning_amber_rounded,
        badgeText: 'Máx 0.50',
        badgeColor: AppColors.coralAction,
      ),
      GlassSelectOption<BiologicalCurveType>(
        value: BiologicalCurveType.crecimiento,
        label: 'Crecimiento (g)',
        subtitle: 'Biometrías y peso promedio • g',
        icon: Icons.show_chart_rounded,
        badgeText: 'Meta 650g',
        badgeColor: AppColors.greenBiomass,
      ),
      GlassSelectOption<BiologicalCurveType>(
        value: BiologicalCurveType.conversion,
        label: 'Conversión (FCR)',
        subtitle: 'Consumo diario y eficiencia • kg',
        icon: Icons.restaurant_rounded,
        badgeText: 'Obj 1.25',
        badgeColor: AppColors.amberWarning,
      ),
      GlassSelectOption<BiologicalCurveType>(
        value: BiologicalCurveType.supervivencia,
        label: 'Supervivencia (%)',
        subtitle: 'Población viva por lote • %',
        icon: Icons.favorite_rounded,
        badgeText: 'Mín 90%',
        badgeColor: AppColors.purpleAnalytics,
      ),
    ];

    return GlassSelectField<BiologicalCurveType>(
      label: 'ANALÍTICA',
      placeholder: 'Seleccionar métrica biológica...',
      value: _selectedCurve,
      accentColor: accent,
      leadingIcon: Icons.analytics_outlined,
      options: options,
      onChanged: (val) {
        if (val != null) {
          setState(() => _selectedCurve = val);
        }
      },
    );
  }

  Color _getCurveAccent(BiologicalCurveType type) {
    switch (type) {
      case BiologicalCurveType.oxigeno:
        return AppColors.cyanWater;
      case BiologicalCurveType.temperaturaPh:
        return AppColors.blueOcean;
      case BiologicalCurveType.toxicos:
        return const Color(0xFFFF5A76);
      case BiologicalCurveType.crecimiento:
        return AppColors.greenBiomass;
      case BiologicalCurveType.conversion:
        return AppColors.amberWarning;
      case BiologicalCurveType.supervivencia:
        return AppColors.purpleAnalytics;
    }
  }

  Color _getCurveAccentLight(BiologicalCurveType type) {
    switch (type) {
      case BiologicalCurveType.oxigeno:
        return const Color(0xFF67E8F9);
      case BiologicalCurveType.temperaturaPh:
        return const Color(0xFF60A5FA);
      case BiologicalCurveType.toxicos:
        return const Color(0xFFFF8FA3);
      case BiologicalCurveType.crecimiento:
        return const Color(0xFF6EE7B7);
      case BiologicalCurveType.conversion:
        return const Color(0xFFFCD34D);
      case BiologicalCurveType.supervivencia:
        return const Color(0xFFC4B5FD);
    }
  }

  String _formatReadingTime(DateTime dt, {String? pondSigla}) {
    final now = DateTime.now();
    final isToday =
        dt.year == now.year && dt.month == now.month && dt.day == now.day;
    final timeStr = DateFormat('HH:mm').format(dt);
    final base = isToday
        ? 'Hoy ($timeStr)'
        : '${DateFormat('d MMM').format(dt)} ($timeStr)';
    if (_selectedPondId == null && pondSigla != null && pondSigla.isNotEmpty) {
      return '$base · $pondSigla';
    }
    return base;
  }

  _TrendDataset _buildDataset({
    required BiologicalCurveType type,
    required dynamic waterState,
    required dynamic pondsState,
    required dynamic nutritionState,
    required Map<String, Pond> pondMap,
  }) {
    final accent = _getCurveAccent(type);
    final accentLight = _getCurveAccentLight(type);

    final List<({DateTime date, double value, String? pondId, String? extra})>
        rawPoints = [];

    late String title;
    late String unit;
    late int decimals;
    late String thresholdLabel;
    late String emptyTitle;
    late String emptySubtitle;
    late IconData emptyIcon;
    double? lowAlert;
    double? highAlert;

    switch (type) {
      case BiologicalCurveType.oxigeno:
        title = 'Oxígeno (O₂)';
        unit = 'mg/L';
        decimals = 1;
        thresholdLabel = 'Mín: 4.0 mg/L';
        emptyTitle = 'Sin registros de oxígeno (O₂)';
        emptySubtitle = _selectedPondId == null
            ? 'Aún no hay lecturas de calidad de agua en la granja.'
            : 'Este estanque no tiene lecturas de oxígeno registradas.';
        emptyIcon = Icons.waves_rounded;
        lowAlert = 4.0;
        for (final p in waterState.recentParameters) {
          if (_selectedPondId != null && p.estanqueId != _selectedPondId) {
            continue;
          }
          final v = (p.oxigenoMgL as double?);
          if (v != null && v > 0.5) {
            rawPoints.add((
              date: p.fecha as DateTime,
              value: v,
              pondId: p.estanqueId as String?,
              extra: p.ph != null ? 'pH ${(p.ph as double).toStringAsFixed(1)}' : null,
            ));
          }
        }
        break;

      case BiologicalCurveType.temperaturaPh:
        title = 'Temp & pH';
        unit = '°C';
        decimals = 1;
        thresholdLabel = 'Rango: 26° - 30°C';
        emptyTitle = 'Sin registros de temperatura y pH';
        emptySubtitle = _selectedPondId == null
            ? 'Aún no hay lecturas térmicas registradas en la granja.'
            : 'Este estanque no tiene lecturas de temperatura registradas.';
        emptyIcon = Icons.thermostat_rounded;
        lowAlert = 24.0;
        highAlert = 31.0;
        for (final p in waterState.recentParameters) {
          if (_selectedPondId != null && p.estanqueId != _selectedPondId) {
            continue;
          }
          final v = (p.temperaturaC as double?);
          if (v != null && v > 5.0) {
            rawPoints.add((
              date: p.fecha as DateTime,
              value: v,
              pondId: p.estanqueId as String?,
              extra: p.ph != null ? 'pH ${(p.ph as double).toStringAsFixed(1)}' : null,
            ));
          }
        }
        break;

      case BiologicalCurveType.toxicos:
        title = 'Tóxicos (NH₃/NO₂)';
        unit = 'ppm';
        decimals = 2;
        thresholdLabel = 'Máx: 0.50 ppm';
        emptyTitle = 'Sin registros de tóxicos (NH₃/NO₂)';
        emptySubtitle = _selectedPondId == null
            ? 'Aún no hay mediciones de amonio o nitritos en la granja.'
            : 'Este estanque no tiene mediciones de amonio registradas.';
        emptyIcon = Icons.warning_amber_rounded;
        highAlert = 0.50;
        for (final p in waterState.recentParameters) {
          if (_selectedPondId != null && p.estanqueId != _selectedPondId) {
            continue;
          }
          final v = (p.amonioMgL as double?);
          if (v != null) {
            rawPoints.add((
              date: p.fecha as DateTime,
              value: v,
              pondId: p.estanqueId as String?,
              extra: p.nitritosMgL != null
                  ? 'NO₂ ${(p.nitritosMgL as double).toStringAsFixed(2)}'
                  : null,
            ));
          }
        }
        break;

      case BiologicalCurveType.crecimiento:
        title = 'Crecimiento';
        unit = 'g';
        decimals = 0;
        thresholdLabel = 'Meta: 650 g';
        emptyTitle = 'Sin biometrías registradas';
        emptySubtitle = _selectedPondId == null
            ? 'Registra muestreos de peso para visualizar la tendencia de crecimiento.'
            : 'Este estanque aún no tiene biometrías registradas.';
        emptyIcon = Icons.show_chart_rounded;
        for (final b in pondsState.biometries) {
          if (_selectedPondId != null && b.estanqueId != _selectedPondId) {
            continue;
          }
          rawPoints.add((
            date: b.fecha as DateTime,
            value: (b.pesoPromedioG as num).toDouble(),
            pondId: b.estanqueId as String?,
            extra: null,
          ));
        }
        break;

      case BiologicalCurveType.conversion:
        title = 'Conversión (FCR)';
        unit = 'kg';
        decimals = 1;
        thresholdLabel = 'Obj: 1.25:1';
        emptyTitle = 'Sin registros de alimentación';
        emptySubtitle = _selectedPondId == null
            ? 'Aún no hay raciones registradas para visualizar el consumo.'
            : 'Este estanque no tiene raciones de alimento registradas.';
        emptyIcon = Icons.restaurant_rounded;
        for (final f in nutritionState.records) {
          if (_selectedPondId != null && f.estanqueId != _selectedPondId) {
            continue;
          }
          rawPoints.add((
            date: f.fecha as DateTime,
            value: (f.cantidadConsumidaKg as num).toDouble(),
            pondId: f.estanqueId as String?,
            extra: null,
          ));
        }
        break;

      case BiologicalCurveType.supervivencia:
        title = 'Supervivencia';
        unit = '%';
        decimals = 1;
        thresholdLabel = 'Mín: 90.0%';
        emptyTitle = 'Sin lotes activos para supervivencia';
        emptySubtitle = _selectedPondId == null
            ? 'Siembra un lote para monitorear el porcentaje de supervivencia.'
            : 'Este estanque no tiene lotes activos o históricos.';
        emptyIcon = Icons.favorite_rounded;
        lowAlert = 90.0;
        for (final b in pondsState.batches) {
          if (_selectedPondId != null && b.estanqueId != _selectedPondId) {
            continue;
          }
          final surv = (b.supervivenciaPct as double?) ?? 90.0;
          rawPoints.add((
            date: (b.fechaSiembra as DateTime?) ?? DateTime.now(),
            value: surv,
            pondId: b.estanqueId as String?,
            extra: b.codigoLote as String?,
          ));
        }
        break;
    }

    if (rawPoints.isEmpty) {
      return _TrendDataset(
        title: title,
        unit: unit,
        accent: accent,
        accentLight: accentLight,
        decimals: decimals,
        dateRangeLabel: 'Últimos 7 días',
        thresholdLabel: thresholdLabel,
        emptyTitle: emptyTitle,
        emptySubtitle: emptySubtitle,
        emptyIcon: emptyIcon,
        bars: const [],
        readings: const [],
      );
    }

    rawPoints.sort((a, b) => a.date.compareTo(b.date));

    // Construir ventana de 7 días terminando en la fecha del último registro
    final endDate = DateTime(
      rawPoints.last.date.year,
      rawPoints.last.date.month,
      rawPoints.last.date.day,
    );
    final startDate = endDate.subtract(const Duration(days: 6));

    final windowPoints = rawPoints.where((pt) {
      final d = DateTime(pt.date.year, pt.date.month, pt.date.day);
      return !d.isBefore(startDate) && !d.isAfter(endDate);
    }).toList();

    final effectivePoints = windowPoints.isNotEmpty ? windowPoints : rawPoints;
    final allVals = effectivePoints.map((e) => e.value).toList();
    final globalMin = allVals.reduce(math.min);
    final globalMax = allVals.reduce(math.max);
    final globalAvg = allVals.fold(0.0, (s, v) => s + v) / allVals.length;

    final Map<String, List<double>> byDayKey = {};
    for (final pt in effectivePoints) {
      final key = DateFormat('yyyy-MM-dd').format(pt.date);
      byDayKey.putIfAbsent(key, () => []).add(pt.value);
    }

    final bars = <_DailyRangeBar>[];
    for (int i = 0; i < 7; i++) {
      final day = startDate.add(Duration(days: i));
      final key = DateFormat('yyyy-MM-dd').format(day);
      final vals = byDayKey[key];
      final dayLabel = _dayShortNames[(day.weekday - 1).clamp(0, 6)];

      if (vals == null || vals.isEmpty) {
        bars.add(_DailyRangeBar(dayLabel: dayLabel, date: day));
      } else {
        final dMin = vals.reduce(math.min);
        final dMax = vals.reduce(math.max);
        final dAvg = vals.fold(0.0, (s, v) => s + v) / vals.length;
        final isPeak = (dMax - globalMax).abs() < 1e-6 ||
            (highAlert != null && dMax >= highAlert);
        final isValley = (dMin - globalMin).abs() < 1e-6 ||
            (lowAlert != null && dMin <= lowAlert);

        bars.add(
          _DailyRangeBar(
            dayLabel: dayLabel,
            date: day,
            minVal: dMin,
            maxVal: dMax,
            avgVal: dAvg,
            count: vals.length,
            showTopDot: isPeak,
            showBottomDot: isValley,
          ),
        );
      }
    }

    final recentDesc = rawPoints.reversed.take(3).map((pt) {
      final pondSigla = pt.pondId != null ? pondMap[pt.pondId!]?.sigla : null;
      final formattedVal = decimals == 0
          ? '${pt.value.round()} $unit'
          : '${pt.value.toStringAsFixed(decimals)} $unit';
      final valueWithExtra =
          pt.extra != null ? '$formattedVal · ${pt.extra}' : formattedVal;
      return _RecentReading(
        timeLabel: _formatReadingTime(pt.date, pondSigla: pondSigla),
        valueLabel: valueWithExtra,
      );
    }).toList();

    final dateRangeLabel =
        '${DateFormat('d MMM').format(startDate)} – ${DateFormat('d MMM yyyy').format(endDate)}';

    return _TrendDataset(
      title: title,
      unit: unit,
      accent: accent,
      accentLight: accentLight,
      minVal: globalMin,
      maxVal: globalMax,
      avgVal: globalAvg,
      decimals: decimals,
      dateRangeLabel: dateRangeLabel,
      thresholdLabel: thresholdLabel,
      emptyTitle: emptyTitle,
      emptySubtitle: emptySubtitle,
      emptyIcon: emptyIcon,
      bars: bars,
      readings: recentDesc,
    );
  }

  Widget _buildEmptyChartState({
    required bool isDark,
    required IconData icon,
    required Color color,
    required String title,
    required String subtitle,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withValues(alpha: 0.03)
            : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.22)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.14),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 20, color: color),
          ),
          const SizedBox(height: 8),
          Text(
            title,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w800,
              color: isDark ? Colors.white : const Color(0xFF1A1A1A),
            ),
          ),
          const SizedBox(height: 3),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 11,
              color: isDark
                  ? AppColors.textSecondaryDark
                  : AppColors.textSecondaryLight,
            ),
          ),
        ],
      ),
    );
  }
}

class _FullStatsButton extends StatefulWidget {
  final String label;
  final bool isDark;
  final VoidCallback onTap;

  const _FullStatsButton({
    required this.label,
    required this.isDark,
    required this.onTap,
  });

  @override
  State<_FullStatsButton> createState() => _FullStatsButtonState();
}

class _FullStatsButtonState extends State<_FullStatsButton> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final bg = widget.isDark
        ? (_hovered
            ? Colors.white.withValues(alpha: 0.10)
            : Colors.white.withValues(alpha: 0.04))
        : (_hovered ? const Color(0xFFF5F5F5) : Colors.white);
    final border = widget.isDark
        ? Colors.white.withValues(alpha: _hovered ? 0.24 : 0.14)
        : (_hovered ? const Color(0xFFD0D0D0) : const Color(0xFFE0E0E0));
    final fg = widget.isDark ? Colors.white : const Color(0xFF1A1A1A);

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: border, width: 1.5),
          ),
          child: Text(
            widget.label,
            style: TextStyle(
              fontSize: 10.5,
              fontWeight: FontWeight.w600,
              color: fg,
            ),
          ),
        ),
      ),
    );
  }
}

/// Gráfica de barras de rango flotantes estilo Uiverse NK2552003
class _RangeBarChart extends StatefulWidget {
  final _TrendDataset dataset;
  final bool isDark;

  const _RangeBarChart({
    required this.dataset,
    required this.isDark,
  });

  @override
  State<_RangeBarChart> createState() => _RangeBarChartState();
}

class _RangeBarChartState extends State<_RangeBarChart> {
  int _hoveredIdx = -1;

  @override
  Widget build(BuildContext context) {
    const double plotHeight = 96.0;
    const double labelAreaHeight = 20.0;
    final dataset = widget.dataset;
    final isDark = widget.isDark;

    final minV = dataset.minVal ?? 0.0;
    final maxV = dataset.maxVal ?? 1.0;
    final span = (maxV - minV).abs();
    final pad = span < 1e-4 ? math.max(1.0, maxV.abs() * 0.25) : span * 0.18;
    final domainMin = minV - pad;
    final domainMax = maxV + pad;
    final domainSpan = math.max(1e-4, domainMax - domainMin);

    double toFrac(double v) => ((v - domainMin) / domainSpan).clamp(0.0, 1.0);

    final avgFrac = toFrac(dataset.avgVal ?? minV);
    final avgTop = ((1.0 - avgFrac) * (plotHeight - 14) + 7).clamp(14.0, plotHeight - 14.0);

    final lineColor = isDark
        ? Colors.white.withValues(alpha: 0.14)
        : const Color(0xFFE0E0E0);
    final avgPillBg = isDark ? const Color(0xFFF4F4F5) : const Color(0xFF1A1A1A);
    final avgPillFg = isDark ? const Color(0xFF18181B) : Colors.white;
    final dayLabelColor =
        isDark ? AppColors.textSecondaryDark : const Color(0xFF999999);
    final dotFill = isDark ? AppColors.surfaceDark : Colors.white;

    return SizedBox(
      height: plotHeight + labelAreaHeight + 6,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // Línea horizontal del promedio (.avg-line)
          Positioned(
            left: 0,
            right: 0,
            top: avgTop,
            child: Container(
              height: 1.5,
              color: lineColor,
            ),
          ),

          // Pastilla de promedio (.avg-label)
          Positioned(
            right: 0,
            top: math.max(0.0, avgTop - 22),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: avgPillBg,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                dataset.avgBadgeText,
                style: TextStyle(
                  color: avgPillFg,
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),

          // Columnas de 7 días (.chart)
          Positioned.fill(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: List.generate(dataset.bars.length, (index) {
                  final bar = dataset.bars[index];
                  final isHovered = _hoveredIdx == index;

                  double barHeight = 0;
                  double bottomMargin = 8;
                  if (bar.hasData) {
                    final loFrac = toFrac(bar.minVal!);
                    final hiFrac = toFrac(bar.maxVal!);
                    final rawH = (hiFrac - loFrac) * (plotHeight - 16);
                    barHeight = rawH.clamp(22.0, plotHeight - 12);
                    bottomMargin =
                        (loFrac * (plotHeight - barHeight - 8) + 4)
                            .clamp(4.0, plotHeight - barHeight - 2);
                  }

                  final tooltipMsg = bar.hasData
                      ? '${DateFormat('d MMM').format(bar.date)}\n'
                          'Mín: ${dataset.formatValue(bar.minVal!)} ${dataset.unit}\n'
                          'Prom: ${dataset.formatValue(bar.avgVal!)} ${dataset.unit}\n'
                          'Máx: ${dataset.formatValue(bar.maxVal!)} ${dataset.unit}'
                      : '${DateFormat('d MMM').format(bar.date)}: sin registros';

                  return Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        SizedBox(
                          height: plotHeight,
                          child: Align(
                            alignment: Alignment.bottomCenter,
                            child: bar.hasData
                                ? Padding(
                                    padding: EdgeInsets.only(bottom: bottomMargin),
                                    child: Tooltip(
                                      message: tooltipMsg,
                                      child: MouseRegion(
                                        cursor: SystemMouseCursors.click,
                                        onEnter: (_) =>
                                            setState(() => _hoveredIdx = index),
                                        onExit: (_) =>
                                            setState(() => _hoveredIdx = -1),
                                        child: AnimatedScale(
                                          scale: isHovered ? 1.08 : 1.0,
                                          duration:
                                              const Duration(milliseconds: 220),
                                          curve: Curves.easeOutCubic,
                                          child: SizedBox(
                                            width: 20,
                                            height: barHeight,
                                            child: Stack(
                                              clipBehavior: Clip.none,
                                              alignment: Alignment.center,
                                              children: [
                                                Container(
                                                  width: 20,
                                                  height: barHeight,
                                                  decoration: BoxDecoration(
                                                    borderRadius:
                                                        BorderRadius.circular(10),
                                                    gradient: LinearGradient(
                                                      begin: Alignment.topCenter,
                                                      end: Alignment.bottomCenter,
                                                      colors: [
                                                        dataset.accent,
                                                        dataset.accentLight,
                                                      ],
                                                    ),
                                                  ),
                                                ),
                                                if (bar.showTopDot)
                                                  Positioned(
                                                    top: -4,
                                                    child: _EndpointDot(
                                                      fillColor: dotFill,
                                                      borderColor: dataset.accent,
                                                    ),
                                                  ),
                                                if (bar.showBottomDot)
                                                  Positioned(
                                                    bottom: -4,
                                                    child: _EndpointDot(
                                                      fillColor: dotFill,
                                                      borderColor: dataset.accent,
                                                    ),
                                                  ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  )
                                : Padding(
                                    padding: const EdgeInsets.only(bottom: 10),
                                    child: Container(
                                      width: 8,
                                      height: 8,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: isDark
                                            ? Colors.white.withValues(alpha: 0.08)
                                            : Colors.black.withValues(alpha: 0.06),
                                      ),
                                    ),
                                  ),
                          ),
                        ),
                        const SizedBox(height: 6),
                        SizedBox(
                          height: labelAreaHeight,
                          child: Text(
                            bar.dayLabel,
                            style: TextStyle(
                              fontSize: 9.5,
                              color: isHovered ? dataset.accent : dayLabelColor,
                              fontWeight:
                                  isHovered ? FontWeight.w700 : FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _EndpointDot extends StatelessWidget {
  final Color fillColor;
  final Color borderColor;

  const _EndpointDot({
    required this.fillColor,
    required this.borderColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 8,
      height: 8,
      decoration: BoxDecoration(
        color: fillColor,
        shape: BoxShape.circle,
        border: Border.all(color: borderColor, width: 1.5),
      ),
    );
  }
}
