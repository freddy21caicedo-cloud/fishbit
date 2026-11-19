import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:fishbit_finance/core/design_system/app_colors.dart';
import 'package:fishbit_finance/core/design_system/app_typography.dart';
import 'package:fishbit_finance/core/design_system/fishbit_header.dart';
import 'package:fishbit_finance/core/design_system/glass_card.dart';
import 'package:fishbit_finance/core/design_system/floating_dock_layout.dart';
import 'package:fishbit_finance/core/design_system/glass_container.dart';
import 'package:fishbit_finance/core/design_system/magic_bento.dart';
import 'package:fishbit_finance/core/design_system/reflective_card.dart';
import 'package:fishbit_finance/core/utils/currency_formatters.dart';
import 'package:fishbit_finance/modules/feeding_nutrition/presentation/providers/nutrition_provider.dart';
import 'package:fishbit_finance/modules/home_dashboard/presentation/widgets/biological_trends_card.dart';
import 'package:fishbit_finance/modules/home_dashboard/presentation/widgets/pond_feed_ticker_board.dart';
import 'package:fishbit_finance/modules/ponds_batches/domain/models/fish_batch.dart';
import 'package:fishbit_finance/modules/ponds_batches/presentation/providers/ponds_provider.dart';
import 'package:fishbit_finance/modules/warehouse_inventory/presentation/providers/warehouse_provider.dart';
import 'package:fishbit_finance/modules/water_quality/presentation/providers/water_quality_provider.dart';

class HomeDashboardScreen extends ConsumerWidget {
  const HomeDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pondsState = ref.watch(pondsProvider);
    final warehouseState = ref.watch(warehouseProvider);
    final waterState = ref.watch(waterQualityProvider);
    final nutritionState = ref.watch(nutritionProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Métricas zootécnicas globales calculadas en vivo
    final activeBatches = pondsState.batches.where((b) => b.estado == BatchStatus.active).toList();
    final int poblacionViva = activeBatches.fold(0, (sum, b) => sum + b.cantidadActualPeces);
    final validFcrBatches = activeBatches.where((b) => b.fcrOrNull != null).toList();
    final double? fcrGlobal = validFcrBatches.isNotEmpty
        ? validFcrBatches.fold(0.0, (sum, b) => sum + b.fcrOrNull!) / validFcrBatches.length
        : null;

    final double pesoPromedioGlobal = activeBatches.isNotEmpty
        ? activeBatches.fold(0.0, (sum, b) => sum + b.pesoActualGramos) / activeBatches.length
        : 0.0;

    final double supervivenciaGlobal = activeBatches.isNotEmpty
        ? activeBatches.fold(0.0, (sum, b) => sum + (100.0 - b.porcentajeMortalidad).clamp(0.0, 100.0)) /
            activeBatches.length
        : 0.0;

    final double consumoProyectadoDiaKg = computeTotalProjectedFeedKgPerDay(
      pondsState.ponds,
      pondsState.batches,
      nutritionState.tables,
    );

    final now = DateTime.now();
    final double servidoHoyKg = nutritionState.records
        .where((r) => r.fecha.year == now.year && r.fecha.month == now.month && r.fecha.day == now.day)
        .fold(0.0, (sum, r) => sum + r.cantidadConsumidaKg);

    final double? diasAutonomiaAlimento = consumoProyectadoDiaKg > 0
        ? (warehouseState.totalAlimentoKg / consumoProyectadoDiaKg)
        : null;

    final double capacidadTotalM3 = pondsState.ponds.fold(0.0, (sum, p) => sum + p.capacidadM3);
    final double densidadMediaKgM3 = capacidadTotalM3 > 0 ? (pondsState.biomasaTotalKg / capacidadTotalM3) : 0.0;

    return Scaffold(
      backgroundColor: Colors.transparent,
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
                  // KPI Principal Zootécnico: Biomasa Viva Total en Agua (Kg)
                  ReflectiveCard(
                    borderRadius: 24,
                    title: 'BIOMASA VIVA TOTAL EN AGUA',
                    statusText: 'ACTIVA',
                    tint: AppColors.greenBiomass,
                    metalness: 1.0,
                    roughness: 0.3,
                    blurStrength: 6.0,
                    shine: 1.0,
                    glare: 0.5,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            CurrencyFormatters.formatKg(pondsState.biomasaTotalKg),
                            style: AppTypography.displayLarge.copyWith(
                              fontSize: 32,
                              color: Colors.white,
                              fontWeight: FontWeight.w900,
                              shadows: [
                                Shadow(
                                  color: AppColors.greenBiomass.withValues(alpha: 0.55),
                                  blurRadius: 16,
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 14,
                          runSpacing: 4,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            Text(
                              'Población: ${CurrencyFormatters.formatInt(poblacionViva)} peces',
                              style: AppTypography.bodyMedium.copyWith(
                                color: Colors.white.withValues(alpha: 0.88),
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            Text(
                              fcrGlobal != null ? 'FCR Global: ${fcrGlobal.toStringAsFixed(2)}:1' : 'FCR: --',
                              style: AppTypography.bodySmall.copyWith(
                                color: const Color(0xFF6EE7B7),
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            if (pesoPromedioGlobal > 0)
                              Text(
                                'Peso prom: ${pesoPromedioGlobal.toInt()} g',
                                style: AppTypography.bodySmall.copyWith(
                                  color: const Color(0xFFFCD34D),
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 14),

                  // Banner de Estado Biológico y Sanitario (ICA/AUNAP) en vivo desde Bitácora
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

                  // Bento Grid Zootécnico <MagicBento /> (React Bits)
                  MagicBentoGrid(
                    columns: 4,
                    rowHeight: 200,
                    gap: 12,
                    radius: 20,
                    enableBorderGlow: true,
                    enableSpotlight: true,
                    spotlightRadius: 420,
                    clickEffect: true,
                    enableStars: true,
                    enableMagnetism: true,
                    items: [
                      MagicBentoCardData(
                        title: 'Estanques',
                        icon: Icons.water_drop_rounded,
                        glowColor: AppColors.cyanWater,
                        onTap: () => context.go('/ponds'),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Text(
                                '${pondsState.estanquesActivosCount} / ${pondsState.ponds.length}',
                                style: AppTypography.numberKpi.copyWith(color: AppColors.cyanWater),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Densidad: ${densidadMediaKgM3.toStringAsFixed(1)} Kg/m³',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: AppTypography.labelMicro.copyWith(
                                color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                              ),
                            ),
                          ],
                        ),
                      ),
                      MagicBentoCardData(
                        title: 'Alimento Bodega',
                        icon: Icons.inventory_2_rounded,
                        glowColor: AppColors.amberWarning,
                        onTap: () => context.go('/warehouse'),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Text(
                                CurrencyFormatters.formatKg(warehouseState.totalAlimentoKg),
                                style: AppTypography.numberKpi.copyWith(color: AppColors.amberWarning),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              diasAutonomiaAlimento != null
                                  ? 'Autonomía: ${diasAutonomiaAlimento.toStringAsFixed(0)} días'
                                  : 'En Bodega',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: AppTypography.labelMicro.copyWith(
                                color: diasAutonomiaAlimento != null && diasAutonomiaAlimento < 7
                                    ? AppColors.coralAction
                                    : (isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight),
                                fontWeight: diasAutonomiaAlimento != null && diasAutonomiaAlimento < 7
                                    ? FontWeight.w800
                                    : FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                      MagicBentoCardData(
                        title: 'Ración Hoy',
                        icon: Icons.set_meal_rounded,
                        glowColor: AppColors.greenBiomass,
                        onTap: () => context.go('/bitacora'),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Text(
                                '${consumoProyectadoDiaKg.toStringAsFixed(1)} Kg',
                                style: AppTypography.numberKpi.copyWith(color: AppColors.greenBiomass, fontSize: 18),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Servido hoy: ${servidoHoyKg.toStringAsFixed(1)} Kg',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: AppTypography.labelMicro.copyWith(
                                color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                              ),
                            ),
                          ],
                        ),
                      ),
                      MagicBentoCardData(
                        title: 'Supervivencia',
                        icon: Icons.favorite_rounded,
                        glowColor: AppColors.purpleAnalytics,
                        onTap: () => context.go('/ponds'),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Text(
                                activeBatches.isNotEmpty ? '${supervivenciaGlobal.toStringAsFixed(1)}%' : '--',
                                style: AppTypography.numberKpi.copyWith(color: AppColors.purpleAnalytics, fontSize: 18),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${activeBatches.length} lote(s) activos',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: AppTypography.labelMicro.copyWith(
                                color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),

                  // Tablero Bursátil (Stock Ticker) de Consumo Proyectado Diario por Estanque
                  const PondFeedTickerBoard(),

                  const SizedBox(height: 20),

                  // Analítica Biológica y Tendencias en Curvas
                  const BiologicalTrendsCard(),

                  const DockBottomSpacer(), // Espacio para el Dock de navegación
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
