import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fishbit_finance/core/design_system/app_colors.dart';
import 'package:fishbit_finance/core/design_system/app_typography.dart';
import 'package:fishbit_finance/core/design_system/glass_container.dart';
import 'package:fishbit_finance/core/design_system/glass_button.dart';
import 'package:fishbit_finance/core/design_system/glass_badge.dart';
import 'package:fishbit_finance/core/utils/currency_formatters.dart';
import 'package:fishbit_finance/modules/ponds_batches/presentation/providers/ponds_provider.dart';
import 'package:fishbit_finance/modules/warehouse_inventory/presentation/providers/warehouse_provider.dart';
import 'package:fishbit_finance/modules/equipment_capex/presentation/providers/equipment_provider.dart';
import 'package:fishbit_finance/modules/finance_payroll/presentation/providers/finance_provider.dart';
import 'package:fishbit_finance/modules/finance_payroll/domain/services/production_cost_engine.dart';
import 'package:fishbit_finance/modules/finance_payroll/domain/models/production_cost_summary.dart';

/// Modal Ejecutivo de Inversión y Finanzas Acuícolas (FishBit Precision Hub)
class InversionFinanzasModal extends ConsumerStatefulWidget {
  const InversionFinanzasModal({super.key});

  static Future<void> show(BuildContext context) {
    return showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => const InversionFinanzasModal(),
    );
  }

  @override
  ConsumerState<InversionFinanzasModal> createState() => _InversionFinanzasModalState();
}

class _InversionFinanzasModalState extends ConsumerState<InversionFinanzasModal>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  double _simulatedMarketPrice = 11000.0;
  final TextEditingController _nominaRapidaController = TextEditingController();
  bool _isSavingNomina = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _nominaRapidaController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final pondsState = ref.watch(pondsProvider);
    final warehouseState = ref.watch(warehouseProvider);
    final financeState = ref.watch(financeProvider);
    final equipmentState = ref.watch(equipmentProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final batches = pondsState.batches;
    final costoInsumosRealLotes = batches.fold(0.0, (sum, b) => sum + b.costoAcumuladoInsumos);
    final totalAlimentoFacturas = warehouseState.invoices.fold(0.0, (sum, inv) => sum + inv.totalFactura);
    final totalAlimentoInsumosEfectivo = costoInsumosRealLotes > 0 ? costoInsumosRealLotes : totalAlimentoFacturas;

    final summary = ProductionCostEngine.calculate(
      ponds: pondsState.ponds,
      batches: batches,
      jornalesList: financeState.jornales,
      totalAlimentoInsumos: totalAlimentoInsumosEfectivo,
      totalNominaFija: financeState.totalCostoNomina,
      totalJornales: financeState.totalCostoJornales,
      totalEnergia: financeState.totalCostoEnergia,
      totalDepreciacionCapex: equipmentState.depreciacionDiariaTotal * 30.0,
      precioMercadoKg: _simulatedMarketPrice,
      inventarioAlimentoBodega: warehouseState.valorTotalConcentrados,
      inventarioFarmaciaBodega: warehouseState.valorTotalInventario - warehouseState.valorTotalConcentrados,
      activosFijosEquiposValorTotal: equipmentState.valorTotalActivos,
      totalGastosOperativosMes: financeState.totalOpex,
    );

    final screenSize = MediaQuery.of(context).size;
    final dialogWidth = screenSize.width > 900 ? 860.0 : (screenSize.width * 0.94);
    final dialogHeight = screenSize.height > 850 ? 760.0 : (screenSize.height * 0.90);

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      child: GlassContainer(
        width: dialogWidth,
        height: dialogHeight,
        borderRadius: 24,
        blur: 24,
        opacity: isDark ? 0.16 : 0.88,
        tintColor: isDark ? const Color(0xFF0F172A) : Colors.white,
        borderColor: AppColors.cyanWater.withValues(alpha: isDark ? 0.35 : 0.25),
        borderWidth: 1.2,
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header del Hub
            _buildHeader(context, isDark, summary),
            const SizedBox(height: 14),

            // Tab Bar
            _buildTabBar(isDark),
            const SizedBox(height: 14),

            // Tab Views
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildTabRadiografiaInversion(context, isDark, summary, warehouseState, equipmentState),
                  _buildTabDesgloseEspecies(context, isDark, summary),
                  _buildTabSimuladorMercado(context, isDark, summary),
                  _buildTabRegistroNominaRapida(isDark),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, bool isDark, ProductionCostSummary summary) {
    final colorMargen = summary.margenBrutoPorcentaje >= 30.0
        ? AppColors.greenBiomass
        : (summary.margenBrutoPorcentaje >= 15.0 ? AppColors.amberWarning : AppColors.coralAction);

    return Row(
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AppColors.cyanWater.withValues(alpha: isDark ? 0.20 : 0.12),
            border: Border.all(color: AppColors.cyanWater.withValues(alpha: 0.5)),
          ),
          child: const Icon(Icons.account_balance_wallet_rounded, color: AppColors.cyanWater, size: 22),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    'INVERSIÓN Y FINANZAS ACUÍCOLAS',
                    style: AppTypography.titleMedium.copyWith(
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.8,
                      color: isDark ? Colors.white : AppColors.textPrimaryLight,
                    ),
                  ),
                  const SizedBox(width: 8),
                  const GlassBadge(
                    text: 'HUB EJECUTIVO',
                    color: AppColors.cyanWater,
                  ),
                ],
              ),
              const SizedBox(height: 2),
              Text(
                'Radiografía de capital invertido, unit economics por especie y simulador de retorno',
                style: AppTypography.bodySmall.copyWith(
                  color: isDark ? Colors.white70 : Colors.black54,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: colorMargen.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: colorMargen.withValues(alpha: 0.4)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.trending_up_rounded, color: colorMargen, size: 16),
              const SizedBox(width: 6),
              Text(
                'ROI: ${summary.roiEstimadoPorcentaje.toStringAsFixed(1)}%',
                style: TextStyle(
                  color: colorMargen,
                  fontWeight: FontWeight.w800,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        IconButton(
          onPressed: () => Navigator.of(context).pop(),
          icon: const Icon(Icons.close_rounded),
          color: isDark ? Colors.white70 : Colors.black54,
          tooltip: 'Cerrar ventana',
        ),
      ],
    );
  }

  Widget _buildTabBar(bool isDark) {
    return Container(
      height: 42,
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? Colors.white.withValues(alpha: 0.08) : Colors.black.withValues(alpha: 0.06),
        ),
      ),
      child: TabBar(
        controller: _tabController,
        indicator: BoxDecoration(
          color: AppColors.cyanWater.withValues(alpha: isDark ? 0.28 : 0.20),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppColors.cyanWater.withValues(alpha: 0.6)),
        ),
        labelColor: isDark ? Colors.white : AppColors.textPrimaryLight,
        unselectedLabelColor: isDark ? Colors.white60 : Colors.black54,
        labelStyle: const TextStyle(fontWeight: FontWeight.w800, fontSize: 12),
        unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
        indicatorSize: TabBarIndicatorSize.tab,
        dividerColor: Colors.transparent,
        tabs: const [
          Tab(
            icon: Icon(Icons.pie_chart_rounded, size: 16),
            text: 'Radiografía Inversión',
          ),
          Tab(
            icon: Icon(Icons.water_rounded, size: 16),
            text: 'Costo por Especie',
          ),
          Tab(
            icon: Icon(Icons.calculate_rounded, size: 16),
            text: 'Simulador Retorno',
          ),
          Tab(
            icon: Icon(Icons.payments_rounded, size: 16),
            text: 'Nómina Directa',
          ),
        ],
      ),
    );
  }

  // TAB 1: RADIOGRAFÍA DE INVERSIÓN TOTAL
  Widget _buildTabRadiografiaInversion(
    BuildContext context,
    bool isDark,
    ProductionCostSummary summary,
    WarehouseState warehouse,
    EquipmentState equipment,
  ) {
    final inv = summary.investmentSummary;
    final totalInversion = inv?.inversionTotalConsolidada ?? summary.costoTotalProduccion;
    final capitalAgua = inv?.capitalEnAguaTotal ?? (summary.totalCostoAlevinos + summary.totalCostoAlimento);
    final capitalBodega = inv?.inventarioBodegaTotal ?? warehouse.valorTotalInventario;
    final activosFijos = inv?.activosFijosNetos ?? equipment.valorTotalActivos;
    final opexMes = inv?.totalGastosOperativosMes ?? summary.totalCostosIndirectos;

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Banner Consolidado de Inversión Total
          GlassContainer(
            borderRadius: 16,
            blur: 16,
            opacity: isDark ? 0.12 : 0.70,
            tintColor: AppColors.cyanWater,
            borderColor: AppColors.cyanWater.withValues(alpha: 0.3),
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'CAPITAL TOTAL INVERTIDO EN LA OPERACIÓN',
                      style: AppTypography.labelMicro.copyWith(
                        color: isDark ? Colors.white70 : Colors.black54,
                        letterSpacing: 0.8,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      CurrencyFormatters.formatCOP(totalInversion),
                      style: AppTypography.displayLarge.copyWith(
                        color: AppColors.cyanWater,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -0.5,
                      ),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppColors.cyanWater.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.cyanWater.withValues(alpha: 0.3)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        'Biomasa en Agua',
                        style: TextStyle(fontSize: 11, color: isDark ? Colors.white60 : Colors.black54),
                      ),
                      Text(
                        '${summary.totalBiomasaKg.toStringAsFixed(0)} Kg',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w900,
                          color: isDark ? Colors.white : AppColors.textPrimaryLight,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // 4 Pilares de Activos
          Row(
            children: [
              Expanded(
                child: _buildAssetCard(
                  title: 'Capital en Agua',
                  subtitle: 'Alevinos + Alimento en estanques',
                  amount: capitalAgua,
                  pct: totalInversion > 0 ? (capitalAgua / totalInversion * 100) : 0.0,
                  icon: Icons.waves_rounded,
                  color: AppColors.cyanWater,
                  isDark: isDark,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildAssetCard(
                  title: 'Stock en Bodega',
                  subtitle: 'Concentrados y farmacia física',
                  amount: capitalBodega,
                  pct: totalInversion > 0 ? (capitalBodega / totalInversion * 100) : 0.0,
                  icon: Icons.inventory_2_rounded,
                  color: AppColors.greenBiomass,
                  isDark: isDark,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _buildAssetCard(
                  title: 'Equipos & CAPEX',
                  subtitle: 'Aireadores, bombas e infraestructura',
                  amount: activosFijos,
                  pct: totalInversion > 0 ? (activosFijos / totalInversion * 100) : 0.0,
                  icon: Icons.precision_manufacturing_rounded,
                  color: AppColors.purpleAnalytics,
                  isDark: isDark,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildAssetCard(
                  title: 'Gastos Operativos (OPEX)',
                  subtitle: 'Nómina, jornales y energía mensual',
                  amount: opexMes,
                  pct: totalInversion > 0 ? (opexMes / totalInversion * 100) : 0.0,
                  icon: Icons.receipt_long_rounded,
                  color: AppColors.amberWarning,
                  isDark: isDark,
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),

          // Barra de Distribución Proporcional de Capital
          Text(
            'DISTRIBUCIÓN PORCENTUAL DEL PATRIMONIO OPERACIONAL',
            style: AppTypography.labelMicro.copyWith(
              color: isDark ? Colors.white70 : Colors.black54,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.6,
            ),
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: SizedBox(
              height: 14,
              child: Row(
                children: [
                  if (capitalAgua > 0)
                    Expanded(
                      flex: (capitalAgua * 100 / (totalInversion > 0 ? totalInversion : 1)).round().clamp(1, 100),
                      child: Container(color: AppColors.cyanWater),
                    ),
                  if (capitalBodega > 0)
                    Expanded(
                      flex: (capitalBodega * 100 / (totalInversion > 0 ? totalInversion : 1)).round().clamp(1, 100),
                      child: Container(color: AppColors.greenBiomass),
                    ),
                  if (activosFijos > 0)
                    Expanded(
                      flex: (activosFijos * 100 / (totalInversion > 0 ? totalInversion : 1)).round().clamp(1, 100),
                      child: Container(color: AppColors.purpleAnalytics),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildLegendItem('Agua', AppColors.cyanWater, capitalAgua, totalInversion, isDark),
              _buildLegendItem('Bodega', AppColors.greenBiomass, capitalBodega, totalInversion, isDark),
              _buildLegendItem('Equipos', AppColors.purpleAnalytics, activosFijos, totalInversion, isDark),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAssetCard({
    required String title,
    required String subtitle,
    required double amount,
    required double pct,
    required IconData icon,
    required Color color,
    required bool isDark,
  }) {
    return GlassContainer(
      borderRadius: 16,
      blur: 16,
      opacity: isDark ? 0.08 : 0.65,
      tintColor: isDark ? const Color(0xFF1E293B) : Colors.white,
      borderColor: color.withValues(alpha: isDark ? 0.35 : 0.25),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: color, size: 18),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  '${pct.toStringAsFixed(1)}%',
                  style: TextStyle(color: color, fontWeight: FontWeight.w800, fontSize: 10),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            title,
            style: AppTypography.titleSmall.copyWith(
              fontWeight: FontWeight.w800,
              color: isDark ? Colors.white : AppColors.textPrimaryLight,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            subtitle,
            style: TextStyle(
              fontSize: 10,
              color: isDark ? Colors.white60 : Colors.black54,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 8),
          Text(
            CurrencyFormatters.formatCOP(amount),
            style: AppTypography.titleMedium.copyWith(
              fontWeight: FontWeight.w900,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLegendItem(String label, Color color, double amount, double total, bool isDark) {
    final pct = total > 0 ? (amount / total * 100) : 0.0;
    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(
          '$label: ${pct.toStringAsFixed(1)}%',
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: isDark ? Colors.white70 : Colors.black87,
          ),
        ),
      ],
    );
  }

  // TAB 2: COSTO Y RENDIMIENTO POR ESPECIE
  Widget _buildTabDesgloseEspecies(
    BuildContext context,
    bool isDark,
    ProductionCostSummary summary,
  ) {
    final especies = summary.especiesBreakdown;

    if (especies.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.bubble_chart_rounded, size: 48, color: isDark ? Colors.white30 : Colors.black26),
            const SizedBox(height: 12),
            Text(
              'No hay estanques con siembra activa registrada',
              style: AppTypography.bodyMedium.copyWith(
                color: isDark ? Colors.white60 : Colors.black54,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      physics: const BouncingScrollPhysics(),
      itemCount: especies.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final esp = especies[index];
        final colorMargen = esp.margenPorcentaje >= 30.0
            ? AppColors.greenBiomass
            : (esp.margenPorcentaje >= 15.0 ? AppColors.amberWarning : AppColors.coralAction);

        return GlassContainer(
          borderRadius: 16,
          blur: 16,
          opacity: isDark ? 0.08 : 0.65,
          tintColor: isDark ? const Color(0xFF1E293B) : Colors.white,
          borderColor: isDark ? Colors.white.withValues(alpha: 0.12) : AppColors.glassBorderLight,
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Especie
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
                        child: const Icon(Icons.set_meal_rounded, color: AppColors.cyanWater, size: 20),
                      ),
                      const SizedBox(width: 10),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            esp.especie,
                            style: AppTypography.titleMedium.copyWith(
                              fontWeight: FontWeight.w900,
                              color: isDark ? Colors.white : AppColors.textPrimaryLight,
                            ),
                          ),
                          Text(
                            '${esp.estanquesCount} estanque(s) • ${esp.totalPeces > 0 ? esp.totalPeces.toString() : 'N/A'} peces',
                            style: TextStyle(
                              fontSize: 11,
                              color: isDark ? Colors.white60 : Colors.black54,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: colorMargen.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: colorMargen.withValues(alpha: 0.4)),
                    ),
                    child: Text(
                      'Margen: ${esp.margenPorcentaje.toStringAsFixed(1)}%',
                      style: TextStyle(
                        color: colorMargen,
                        fontWeight: FontWeight.w900,
                        fontSize: 11,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              // Métricas Principales en Grid
              Row(
                children: [
                  Expanded(
                    child: _buildMetricTile(
                      label: 'Biomasa Activa',
                      value: '${esp.totalBiomasaKg.toStringAsFixed(0)} Kg',
                      color: AppColors.cyanWater,
                      isDark: isDark,
                    ),
                  ),
                  Expanded(
                    child: _buildMetricTile(
                      label: 'CPK Directo',
                      value: CurrencyFormatters.formatCOP(esp.cpkDirecto),
                      color: isDark ? Colors.white70 : Colors.black87,
                      isDark: isDark,
                    ),
                  ),
                  Expanded(
                    child: _buildMetricTile(
                      label: 'CPK Total',
                      value: CurrencyFormatters.formatCOP(esp.cpkTotal),
                      color: AppColors.coralAction,
                      isDark: isDark,
                    ),
                  ),
                  Expanded(
                    child: _buildMetricTile(
                      label: 'Precio Mercado',
                      value: CurrencyFormatters.formatCOP(esp.precioVentaKg),
                      color: AppColors.greenBiomass,
                      isDark: isDark,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              const Divider(height: 1),
              const SizedBox(height: 10),

              // Ganancia Neta Estimada y ROI
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Utilidad Estimada: ${CurrencyFormatters.formatCOP(esp.utilidadTotalEstimada)}',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      color: esp.utilidadTotalEstimada >= 0 ? AppColors.greenBiomass : AppColors.coralAction,
                    ),
                  ),
                  Row(
                    children: [
                      Text(
                        'ROI Especie: ',
                        style: TextStyle(
                          fontSize: 12,
                          color: isDark ? Colors.white60 : Colors.black54,
                        ),
                      ),
                      Text(
                        '${esp.roiPorcentaje.toStringAsFixed(1)}%',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w900,
                          color: esp.roiPorcentaje >= 0 ? AppColors.greenBiomass : AppColors.coralAction,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildMetricTile({
    required String label,
    required String value,
    required Color color,
    required bool isDark,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            color: isDark ? Colors.white60 : Colors.black54,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w800,
            color: color,
          ),
        ),
      ],
    );
  }

  // TAB 3: SIMULADOR DE MERCADO Y RETORNO EN TIEMPO REAL
  Widget _buildTabSimuladorMercado(
    BuildContext context,
    bool isDark,
    ProductionCostSummary summary,
  ) {
    final valorTotalVenta = summary.totalBiomasaKg * _simulatedMarketPrice;
    final utilidadTotal = valorTotalVenta - summary.costoTotalProduccion;
    final roi = summary.costoTotalProduccion > 0 ? (utilidadTotal / summary.costoTotalProduccion * 100) : 0.0;
    final colorResultado = utilidadTotal >= 0 ? AppColors.greenBiomass : AppColors.coralAction;

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Tarjeta de Control del Simulador
          GlassContainer(
            borderRadius: 16,
            blur: 16,
            opacity: isDark ? 0.08 : 0.65,
            tintColor: isDark ? const Color(0xFF1E293B) : Colors.white,
            borderColor: AppColors.cyanWater.withValues(alpha: 0.3),
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'PRECIO DE VENTA PROYECTADO POR KG',
                      style: AppTypography.labelMicro.copyWith(
                        color: isDark ? Colors.white70 : Colors.black54,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.6,
                      ),
                    ),
                    Text(
                      CurrencyFormatters.formatCOP(_simulatedMarketPrice),
                      style: AppTypography.titleLarge.copyWith(
                        fontWeight: FontWeight.w900,
                        color: AppColors.cyanWater,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                SliderTheme(
                  data: SliderTheme.of(context).copyWith(
                    activeTrackColor: AppColors.cyanWater,
                    thumbColor: AppColors.cyanWater,
                    inactiveTrackColor: isDark ? Colors.white12 : Colors.black12,
                    overlayColor: AppColors.cyanWater.withValues(alpha: 0.2),
                  ),
                  child: Slider(
                    value: _simulatedMarketPrice.clamp(7000.0, 22000.0),
                    min: 7000.0,
                    max: 22000.0,
                    divisions: 30,
                    onChanged: (val) {
                      setState(() {
                        _simulatedMarketPrice = (val / 100).round() * 100.0;
                      });
                    },
                  ),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('\$7.000 / Kg', style: TextStyle(fontSize: 10, color: isDark ? Colors.white60 : Colors.black54)),
                    Row(
                      children: [
                        _buildQuickPriceButton('-500', () {
                          setState(() {
                            _simulatedMarketPrice = (_simulatedMarketPrice - 500).clamp(7000.0, 22000.0);
                          });
                        }, isDark),
                        const SizedBox(width: 8),
                        _buildQuickPriceButton('+500', () {
                          setState(() {
                            _simulatedMarketPrice = (_simulatedMarketPrice + 500).clamp(7000.0, 22000.0);
                          });
                        }, isDark),
                      ],
                    ),
                    Text('\$22.000 / Kg', style: TextStyle(fontSize: 10, color: isDark ? Colors.white60 : Colors.black54)),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Proyecciones de Retorno
          Row(
            children: [
              Expanded(
                child: GlassContainer(
                  borderRadius: 16,
                  blur: 16,
                  opacity: isDark ? 0.08 : 0.65,
                  tintColor: isDark ? const Color(0xFF1E293B) : Colors.white,
                  borderColor: colorResultado.withValues(alpha: 0.3),
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'UTILIDAD NETA TOTAL',
                        style: AppTypography.labelMicro.copyWith(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: isDark ? Colors.white60 : Colors.black54,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        CurrencyFormatters.formatCOP(utilidadTotal),
                        style: AppTypography.titleMedium.copyWith(
                          fontWeight: FontWeight.w900,
                          color: colorResultado,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: GlassContainer(
                  borderRadius: 16,
                  blur: 16,
                  opacity: isDark ? 0.08 : 0.65,
                  tintColor: isDark ? const Color(0xFF1E293B) : Colors.white,
                  borderColor: colorResultado.withValues(alpha: 0.3),
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'RETORNO ROI ESTIMADO',
                        style: AppTypography.labelMicro.copyWith(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: isDark ? Colors.white60 : Colors.black54,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${roi.toStringAsFixed(1)}%',
                        style: AppTypography.titleMedium.copyWith(
                          fontWeight: FontWeight.w900,
                          color: colorResultado,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Tarjeta de Break-Even (Punto de Equilibrio)
          GlassContainer(
            borderRadius: 16,
            blur: 16,
            opacity: isDark ? 0.08 : 0.65,
            tintColor: isDark ? const Color(0xFF1E293B) : Colors.white,
            borderColor: isDark ? Colors.white.withValues(alpha: 0.12) : AppColors.glassBorderLight,
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'PUNTO DE EQUILIBRIO OPERACIONAL',
                      style: AppTypography.labelMicro.copyWith(
                        fontWeight: FontWeight.w800,
                        color: isDark ? Colors.white70 : Colors.black54,
                        letterSpacing: 0.6,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${summary.puntoEquilibrioKg.toStringAsFixed(0)} Kg para cubrir costos fijos',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        color: isDark ? Colors.white : AppColors.textPrimaryLight,
                      ),
                    ),
                  ],
                ),
                SizedBox(
                  width: 140,
                  height: 38,
                  child: GlassButton(
                    label: 'Copiar Reporte',
                    icon: const Icon(Icons.copy_rounded, size: 14),
                    backgroundColor: AppColors.cyanWater,
                    borderRadius: 10,
                    height: 38,
                    onPressed: () {
                      final report = 'FishBit - Simulación de Rentabilidad:\n'
                          'Biomasa: ${summary.totalBiomasaKg.toStringAsFixed(0)} Kg\n'
                          'Precio Estimado: ${CurrencyFormatters.formatCOP(_simulatedMarketPrice)}/Kg\n'
                          'CPK Total: ${CurrencyFormatters.formatCOP(summary.cpkTotal)}/Kg\n'
                          'Utilidad Neta: ${CurrencyFormatters.formatCOP(utilidadTotal)}\n'
                          'ROI Proyectado: ${roi.toStringAsFixed(1)}%';
                      Clipboard.setData(ClipboardData(text: report));
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Reporte copiado al portapapeles'),
                          backgroundColor: AppColors.surfaceDarkRaised,
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickPriceButton(String label, VoidCallback onPressed, bool isDark) {
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: isDark ? Colors.white.withValues(alpha: 0.08) : Colors.black.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isDark ? Colors.white.withValues(alpha: 0.12) : Colors.black.withValues(alpha: 0.1),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: isDark ? Colors.white70 : Colors.black87,
          ),
        ),
      ),
    );
  }

  // TAB 4: REGISTRO RÁPIDO DE NÓMINA GENERAL
  Widget _buildTabRegistroNominaRapida(bool isDark) {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GlassContainer(
            borderRadius: 16,
            blur: 16,
            opacity: isDark ? 0.08 : 0.65,
            tintColor: isDark ? const Color(0xFF1E293B) : Colors.white,
            borderColor: AppColors.purpleAnalytics.withValues(alpha: 0.35),
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.purpleAnalytics.withValues(alpha: 0.15),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.flash_on_rounded, color: AppColors.purpleAnalytics, size: 20),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'REGISTRO RÁPIDO DE NÓMINA CONSOLIDADA',
                            style: AppTypography.titleSmall.copyWith(
                              fontWeight: FontWeight.w900,
                              color: isDark ? Colors.white : AppColors.textPrimaryLight,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Ingresa el valor total mensual pagado a empleados si no usas colillas individuales',
                            style: TextStyle(fontSize: 11, color: isDark ? Colors.white60 : Colors.black54),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),

                TextField(
                  controller: _nominaRapidaController,
                  keyboardType: TextInputType.number,
                  inputFormatters: [CurrencyInputFormatter()],
                  style: TextStyle(
                    color: isDark ? Colors.white : AppColors.textPrimaryLight,
                    fontWeight: FontWeight.w800,
                  ),
                  decoration: InputDecoration(
                    labelText: 'Valor Total Nómina del Mes (\$ COP)',
                    hintText: 'Ej. \$ 3.500.000',
                    prefixIcon: const Icon(Icons.attach_money_rounded, color: AppColors.purpleAnalytics),
                    filled: true,
                    fillColor: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.03),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: AppColors.purpleAnalytics.withValues(alpha: 0.3)),
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                SizedBox(
                  width: double.infinity,
                  child: GlassButton(
                    label: _isSavingNomina ? 'Registrando...' : 'Guardar Nómina del Mes',
                    icon: const Icon(Icons.check_circle_rounded, size: 18),
                    backgroundColor: AppColors.purpleAnalytics,
                    isLoading: _isSavingNomina,
                    onPressed: () async {
                      final val = CurrencyFormatters.parseCOP(_nominaRapidaController.text);
                      if (val <= 0) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Ingresa un valor válido de nómina'),
                            backgroundColor: AppColors.coralAction,
                          ),
                        );
                        return;
                      }

                      setState(() => _isSavingNomina = true);
                      try {
                        await ref.read(financeProvider.notifier).registrarNominaMensualGeneral(
                              valorTotalMensual: val,
                              mesPeriodo: DateTime.now(),
                            );
                        if (!mounted) return;
                        _nominaRapidaController.clear();
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Nómina mensual registrada con éxito'),
                            backgroundColor: AppColors.greenBiomass,
                          ),
                        );
                      } catch (e) {
                        if (!mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Error al registrar nómina: $e'),
                            backgroundColor: AppColors.coralAction,
                          ),
                        );
                      } finally {
                        if (mounted) setState(() => _isSavingNomina = false);
                      }
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
