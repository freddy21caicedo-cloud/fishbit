import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:fishbit_finance/core/design_system/app_colors.dart';
import 'package:fishbit_finance/core/design_system/app_typography.dart';
import 'package:fishbit_finance/core/design_system/glass_badge.dart';
import 'package:fishbit_finance/core/design_system/glass_card.dart';
import 'package:fishbit_finance/core/utils/currency_formatters.dart';
import 'package:fishbit_finance/modules/feeding_nutrition/domain/models/nutrition_table.dart';
import 'package:fishbit_finance/modules/feeding_nutrition/presentation/providers/nutrition_provider.dart';
import 'package:fishbit_finance/modules/ponds_batches/domain/models/fish_batch.dart';
import 'package:fishbit_finance/modules/ponds_batches/domain/models/pond.dart';
import 'package:fishbit_finance/modules/ponds_batches/presentation/providers/ponds_provider.dart';
import 'package:fishbit_finance/modules/water_quality/presentation/providers/water_quality_provider.dart';

/// Calcula la tasa de alimentación (% de biomasa/día) para un lote según
/// tablas nutricionales configuradas o curva zootécnica estándar por peso.
double resolveFeedingRatePct(FishBatch? batch, List<NutritionTable> tables) {
  if (batch == null) return 2.5;
  final peso = batch.pesoActualGramos;

  for (final t in tables) {
    if (t.especie.toLowerCase() == batch.especie.toLowerCase() &&
        peso >= t.pesoMinG &&
        peso <= t.pesoMaxG) {
      return t.tasaAlimentacionPct;
    }
  }

  if (peso < 5.0) return 8.0;
  if (peso < 20.0) return 5.5;
  if (peso < 80.0) return 4.0;
  if (peso < 200.0) return 3.0;
  if (peso < 400.0) return 2.2;
  return 1.5;
}

/// Calcula el consumo diario proyectado total (Kg/día) de toda la granja.
double computeTotalProjectedFeedKgPerDay(
  List<Pond> ponds,
  List<FishBatch> batches,
  List<NutritionTable> tables,
) {
  double total = 0.0;
  for (final pond in ponds) {
    if (pond.biomasaKg <= 0) continue;
    final batch = batches
        .where((b) => b.estanqueId == pond.id && b.estado == BatchStatus.active)
        .firstOrNull;
    final rate = resolveFeedingRatePct(batch, tables);
    total += pond.biomasaKg * (rate / 100.0);
  }
  return total;
}

enum _TickerFilter { todos, pendientes, cumplidos, alertaO2 }

/// Tablero tipo Bolsa de Valores (Stock Ticker) con el consumo proyectado diario
/// por cada estanque activo, comparado en vivo contra lo suministrado hoy y alertas de O₂.
class PondFeedTickerBoard extends ConsumerStatefulWidget {
  const PondFeedTickerBoard({super.key});

  @override
  ConsumerState<PondFeedTickerBoard> createState() => _PondFeedTickerBoardState();
}

class _PondFeedTickerBoardState extends ConsumerState<PondFeedTickerBoard> {
  _TickerFilter _filter = _TickerFilter.todos;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final pondsState = ref.watch(pondsProvider);
    final nutritionState = ref.watch(nutritionProvider);
    final latestWaterByPond = ref.watch(latestWaterQualityByPondProvider);

    final now = DateTime.now();
    final todayRecords = nutritionState.records.where((r) {
      return r.fecha.year == now.year &&
          r.fecha.month == now.month &&
          r.fecha.day == now.day;
    }).toList();

    // Construir filas de cotización zootécnica por estanque con biomasa o estado activo
    final List<_PondTickerItem> items = [];
    double totalProyectadoHoy = 0.0;
    double totalServidoHoy = 0.0;

    for (final pond in pondsState.ponds) {
      if (pond.estado != PondStatus.active && pond.biomasaKg <= 0) continue;

      final activeBatch = pondsState.batches
          .where((b) => b.estanqueId == pond.id && b.estado == BatchStatus.active)
          .firstOrNull;

      final ratePct = resolveFeedingRatePct(activeBatch, nutritionState.tables);
      final proyectadoKg = pond.biomasaKg * (ratePct / 100.0);
      final servidoKg = todayRecords
          .where((r) => r.estanqueId == pond.id)
          .fold(0.0, (sum, r) => sum + r.cantidadConsumidaKg);

      final water = latestWaterByPond[pond.id];
      final o2 = water?.oxigenoMgL;
      final isHypoxia = o2 != null && o2 > 0 && o2 < 4.0;

      totalProyectadoHoy += proyectadoKg;
      totalServidoHoy += servidoKg;

      items.add(
        _PondTickerItem(
          pond: pond,
          batch: activeBatch,
          ratePct: ratePct,
          proyectadoKg: proyectadoKg,
          servidoKg: servidoKg,
          isHypoxia: isHypoxia,
          oxigenoMgL: o2,
        ),
      );
    }

    // Ordenar: primero alertas de O2, luego mayor consumo proyectado
    items.sort((a, b) {
      if (a.isHypoxia != b.isHypoxia) return a.isHypoxia ? -1 : 1;
      return b.proyectadoKg.compareTo(a.proyectadoKg);
    });

    final filteredItems = items.where((item) {
      switch (_filter) {
        case _TickerFilter.todos:
          return true;
        case _TickerFilter.pendientes:
          return !item.isCompleted && !item.isHypoxia;
        case _TickerFilter.cumplidos:
          return item.isCompleted;
        case _TickerFilter.alertaO2:
          return item.isHypoxia;
      }
    }).toList();

    return GlassCard(
      borderRadius: 24,
      glowColor: AppColors.amberWarning,
      title: 'PIZARRA DE CONSUMO DIARIO POR ESTANQUE',
      trailingWidget: GlassBadge(
        text: 'META: ${CurrencyFormatters.formatKg(totalProyectadoHoy)}/d',
        color: AppColors.amberWarning,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Resumen tipo Ticker Global + Filtros rápidos
          Row(
            children: [
              Expanded(
                child: Text(
                  'Servido hoy: ${CurrencyFormatters.formatKg(totalServidoHoy)} de ${CurrencyFormatters.formatKg(totalProyectadoHoy)}',
                  style: AppTypography.labelMicro.copyWith(
                    color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              InkWell(
                onTap: () => context.go('/bitacora'),
                borderRadius: BorderRadius.circular(8),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Registrar ración',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          color: AppColors.cyanWater,
                        ),
                      ),
                      const SizedBox(width: 2),
                      const Icon(Icons.arrow_forward_rounded, size: 12, color: AppColors.cyanWater),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Chips de filtro rápido
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildFilterChip(_TickerFilter.todos, 'Todos (${items.length})', AppColors.cyanWater, isDark),
                const SizedBox(width: 6),
                _buildFilterChip(
                  _TickerFilter.pendientes,
                  'Pendientes (${items.where((i) => !i.isCompleted && !i.isHypoxia).length})',
                  AppColors.amberWarning,
                  isDark,
                ),
                const SizedBox(width: 6),
                _buildFilterChip(
                  _TickerFilter.cumplidos,
                  'Cumplidos (${items.where((i) => i.isCompleted).length})',
                  AppColors.greenBiomass,
                  isDark,
                ),
                const SizedBox(width: 6),
                _buildFilterChip(
                  _TickerFilter.alertaO2,
                  'Alerta O₂ (${items.where((i) => i.isHypoxia).length})',
                  AppColors.coralAction,
                  isDark,
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          if (filteredItems.isEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 22, horizontal: 16),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: isDark ? 0.03 : 0.14),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
              ),
              child: Column(
                children: [
                  Icon(
                    Icons.candlestick_chart_rounded,
                    size: 26,
                    color: isDark ? Colors.white38 : AppColors.textTertiaryLight,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    items.isEmpty
                        ? 'Sin estanques activos con biomasa para proyectar ración'
                        : 'No hay estanques en esta categoría de filtro',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                    ),
                  ),
                ],
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: filteredItems.length > 8 ? 8 : filteredItems.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (context, index) => _buildTickerRow(filteredItems[index], isDark),
            ),

          if (filteredItems.length > 8) ...[
            const SizedBox(height: 10),
            Center(
              child: TextButton.icon(
                onPressed: () => context.go('/ponds'),
                icon: const Icon(Icons.open_in_new_rounded, size: 14),
                label: Text('Ver los ${filteredItems.length} estanques en Estanques'),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildFilterChip(_TickerFilter type, String label, Color color, bool isDark) {
    final isSel = _filter == type;
    return InkWell(
      onTap: () => setState(() => _filter = type),
      borderRadius: BorderRadius.circular(10),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: isSel ? color.withValues(alpha: 0.20) : Colors.white.withValues(alpha: isDark ? 0.04 : 0.12),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSel ? color : Colors.white.withValues(alpha: 0.08),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 10.5,
            fontWeight: isSel ? FontWeight.w800 : FontWeight.w600,
            color: isSel
                ? (isDark ? Colors.white : color)
                : (isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight),
          ),
        ),
      ),
    );
  }

  Widget _buildTickerRow(_PondTickerItem item, bool isDark) {
    final Color statusColor;
    final String statusText;
    final IconData statusIcon;

    if (item.isHypoxia) {
      statusColor = AppColors.coralAction;
      statusText = '▼ ALERTA O₂ (${item.oxigenoMgL?.toStringAsFixed(1)} mg/L)';
      statusIcon = Icons.warning_amber_rounded;
    } else if (item.isCompleted) {
      statusColor = AppColors.greenBiomass;
      statusText = '▲ 100% CUMPLIDO';
      statusIcon = Icons.trending_up_rounded;
    } else if (item.servidoKg > 0) {
      statusColor = AppColors.amberWarning;
      statusText = '▶ EN RACIÓN (${item.progressPct.toInt()}%)';
      statusIcon = Icons.timelapse_rounded;
    } else {
      statusColor = AppColors.cyanWater;
      statusText = '• PENDIENTE HOY';
      statusIcon = Icons.schedule_rounded;
    }

    final sigla = item.pond.sigla.isNotEmpty ? item.pond.sigla : item.pond.nombre.substring(0, item.pond.nombre.length.clamp(0, 5)).toUpperCase();
    final especie = item.batch?.especie.isNotEmpty == true
        ? item.batch!.especie
        : (item.pond.especieActual.isNotEmpty ? item.pond.especieActual : 'Sin especie');
    final pesoProm = item.batch != null ? '${item.batch!.pesoActualGramos.toInt()} g' : '--';

    return InkWell(
      onTap: () => context.go('/ponds'),
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: isDark ? 0.04 : 0.16),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: item.isHypoxia
                ? AppColors.coralAction.withValues(alpha: 0.45)
                : Colors.white.withValues(alpha: 0.08),
          ),
        ),
        child: Row(
          children: [
            // Símbolo bursátil del estanque (Ticker Badge)
            Container(
              width: 58,
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
              decoration: BoxDecoration(
                color: statusColor.withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: statusColor.withValues(alpha: 0.35)),
              ),
              child: Column(
                children: [
                  Text(
                    sigla,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w900,
                      color: statusColor,
                      letterSpacing: 0.4,
                    ),
                  ),
                  Text(
                    pesoProm,
                    style: TextStyle(
                      fontSize: 9.5,
                      fontWeight: FontWeight.w700,
                      color: isDark ? Colors.white70 : AppColors.textSecondaryLight,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),

            // Nombre, especie y biomasa viva
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.pond.nombre,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w800,
                      color: isDark ? Colors.white : AppColors.textPrimaryLight,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '$especie • ${CurrencyFormatters.formatKg(item.pond.biomasaKg)} (${item.pond.densidadKgM3.toStringAsFixed(1)} Kg/m³)',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 10.5,
                      color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),

            // Cotización de consumo proyectado (Kg/día) y estado bursátil
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '${item.proyectadoKg.toStringAsFixed(1)} Kg/d',
                      style: TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w900,
                        color: isDark ? Colors.white : AppColors.textPrimaryLight,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '@${item.ratePct.toStringAsFixed(1)}%',
                      style: TextStyle(
                        fontSize: 9.5,
                        fontWeight: FontWeight.w700,
                        color: AppColors.amberWarning,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 3),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(statusIcon, size: 10, color: statusColor),
                      const SizedBox(width: 3),
                      Text(
                        statusText,
                        style: TextStyle(
                          fontSize: 9.5,
                          fontWeight: FontWeight.w800,
                          color: statusColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _PondTickerItem {
  final Pond pond;
  final FishBatch? batch;
  final double ratePct;
  final double proyectadoKg;
  final double servidoKg;
  final bool isHypoxia;
  final double? oxigenoMgL;

  _PondTickerItem({
    required this.pond,
    required this.batch,
    required this.ratePct,
    required this.proyectadoKg,
    required this.servidoKg,
    required this.isHypoxia,
    required this.oxigenoMgL,
  });

  double get progressPct => proyectadoKg > 0 ? ((servidoKg / proyectadoKg) * 100.0).clamp(0.0, 100.0) : 0.0;
  bool get isCompleted => proyectadoKg > 0 && servidoKg >= (proyectadoKg * 0.95);
}
