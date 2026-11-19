import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:fishbit_finance/core/design_system/app_colors.dart';
import 'package:fishbit_finance/core/design_system/app_typography.dart';
import 'package:fishbit_finance/core/design_system/fishbit_header.dart';
import 'package:fishbit_finance/core/design_system/glass_card.dart';
import 'package:fishbit_finance/core/design_system/glass_container.dart';
import 'package:fishbit_finance/core/design_system/glass_button.dart';
import 'package:fishbit_finance/core/design_system/glass_badge.dart';
import 'package:fishbit_finance/core/design_system/glass_date_picker.dart';
import 'package:fishbit_finance/core/design_system/floating_dock_layout.dart';
import 'package:fishbit_finance/core/utils/currency_formatters.dart';
import 'package:fishbit_finance/modules/finance_payroll/domain/models/production_cost_summary.dart';
import 'package:fishbit_finance/modules/finance_payroll/domain/services/production_cost_engine.dart';
import 'package:fishbit_finance/modules/finance_payroll/presentation/dialogs/registro_nomina_modal.dart';
import 'package:fishbit_finance/modules/finance_payroll/presentation/dialogs/liquidacion_masiva_modal.dart';
import 'package:fishbit_finance/modules/finance_payroll/presentation/dialogs/colilla_nomina_modal.dart';
import 'package:fishbit_finance/modules/finance_payroll/presentation/dialogs/registro_jornal_modal.dart';
import 'package:fishbit_finance/modules/finance_payroll/presentation/dialogs/configuracion_nomina_modal.dart';
import 'package:fishbit_finance/modules/finance_payroll/presentation/widgets/cpk_breakdown_card.dart';
import 'package:fishbit_finance/modules/finance_payroll/presentation/providers/finance_provider.dart';
import 'package:fishbit_finance/modules/equipment_capex/presentation/providers/equipment_provider.dart';
import 'package:fishbit_finance/modules/ponds_batches/domain/models/pond.dart';
import 'package:fishbit_finance/modules/finance_payroll/domain/models/jornal_record.dart';
import 'package:fishbit_finance/modules/finance_payroll/domain/models/payroll_record.dart';
import 'package:fishbit_finance/modules/ponds_batches/presentation/providers/ponds_provider.dart';
import 'package:fishbit_finance/modules/sales_harvest/presentation/providers/sales_provider.dart';
import 'package:fishbit_finance/modules/warehouse_inventory/presentation/providers/warehouse_provider.dart';

/// Pantalla Principal del Módulo FishBit Finanzas (Hub Ejecutivo de Inversión y Rentabilidad Acuícola)
class FinanceScreen extends ConsumerStatefulWidget {
  const FinanceScreen({super.key});

  @override
  ConsumerState<FinanceScreen> createState() => _FinanceScreenState();
}

class _FinanceScreenState extends ConsumerState<FinanceScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  double _simulatedMarketPrice = 11000.0;
  final TextEditingController _nominaRapidaController = TextEditingController();
  bool _isSavingNomina = false;
  CivilDateRange? _selectedRange;

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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final pondsState = ref.watch(pondsProvider);
    final warehouseState = ref.watch(warehouseProvider);
    final financeState = ref.watch(financeProvider);
    final equipmentState = ref.watch(equipmentProvider);
    final salesState = ref.watch(salesProvider);
    final pondMap = {for (final p in pondsState.ponds) p.id: p};

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

    final filteredJornales = financeState.jornales.where((j) {
      if (_selectedRange == null) return true;
      final c = CivilDate.fromDate(j.fecha);
      if (_selectedRange!.end != null) {
        return c.isBetween(_selectedRange!.start, _selectedRange!.end!);
      }
      return c.isSameDay(_selectedRange!.start);
    }).toList();

    final filteredPayroll = financeState.payrollRecords.where((p) {
      if (_selectedRange == null) return true;
      final c = CivilDate.fromDate(p.fechaPago);
      if (_selectedRange!.end != null) {
        return c.isBetween(_selectedRange!.start, _selectedRange!.end!);
      }
      return c.isSameDay(_selectedRange!.start);
    }).toList();

    return Scaffold(
      backgroundColor: Colors.transparent,
      floatingActionButtonLocation: FloatingDockFabLocation.endFloat,
      floatingActionButton: LayoutBuilder(
        builder: (context, constraints) {
          final screenWidth = MediaQuery.sizeOf(context).width;
          if (screenWidth < 480) {
            return FloatingActionButton.extended(
              heroTag: 'fab_finance_hub_actions',
              backgroundColor: AppColors.cyanWater,
              icon: const Icon(Icons.add_circle_outline_rounded, color: Colors.black87),
              label: const Text('Acciones OPEX', style: TextStyle(color: Colors.black87, fontWeight: FontWeight.w900)),
              onPressed: () => _showFinanceActionsSheet(context),
            );
          }
          return Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              FloatingActionButton.extended(
                heroTag: 'fab_jornal',
                backgroundColor: AppColors.amberWarning,
                icon: const Icon(Icons.agriculture_rounded, color: Colors.black87),
                label: const Text('+ Jornal', style: TextStyle(color: Colors.black87, fontWeight: FontWeight.w900)),
                onPressed: () => RegistroJornalModal.show(context),
              ),
              const SizedBox(width: 8),
              FloatingActionButton.extended(
                heroTag: 'fab_planilla_masiva',
                backgroundColor: AppColors.cyanWater,
                icon: const Icon(Icons.groups_rounded, color: Colors.black87),
                label: const Text('Planilla Masiva', style: TextStyle(color: Colors.black87, fontWeight: FontWeight.w900)),
                onPressed: () => LiquidacionMasivaModal.show(context),
              ),
              const SizedBox(width: 8),
              FloatingActionButton.extended(
                heroTag: 'fab_nomina',
                backgroundColor: AppColors.purpleAnalytics,
                icon: const Icon(Icons.group_add_rounded, color: Colors.white),
                label: const Text('+ Nómina', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800)),
                onPressed: () => RegistroNominaModal.show(context),
              ),
            ],
          );
        },
      ),
      body: CustomScrollView(
        slivers: [
          FishBitHeader(
            onRefresh: () {
              ref.read(financeProvider.notifier).loadFinanceData();
              ref.read(equipmentProvider.notifier).loadEquipment();
            },
            customActions: [
              IconButton(
                icon: const Icon(Icons.tune_rounded, color: AppColors.purpleAnalytics, size: 20),
                tooltip: 'Ajustes ARL & Nómina',
                onPressed: () => ConfiguracionNominaModal.show(context),
              ),
            ],
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Encabezado Insignia del Hub Ejecutivo
                  _buildExecutiveHeader(context, isDark, summary),
                  const SizedBox(height: 16),

                  // Tab Bar con Glassmorphism
                  _buildTabBar(isDark),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),

          // Contenido de las pestañas
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: AnimatedBuilder(
                animation: _tabController,
                builder: (context, _) {
                  switch (_tabController.index) {
                    case 0:
                      return _buildTabRadiografiaInversion(context, isDark, summary, warehouseState, equipmentState, financeState, pondsState, salesState);
                    case 1:
                      return _buildTabDesgloseEspecies(context, isDark, summary);
                    case 2:
                      return _buildTabSimuladorMercado(context, isDark, summary);
                    case 3:
                      return _buildTabNominaYJornales(
                        context,
                        isDark,
                        financeState,
                        filteredJornales,
                        filteredPayroll,
                        pondMap,
                      );
                    default:
                      return const SizedBox.shrink();
                  }
                },
              ),
            ),
          ),
          const SliverDockBottomSpacer(),
        ],
      ),
    );
  }

  // ENCABEZADO INSIGNIA EJECUTIVO
  Widget _buildExecutiveHeader(BuildContext context, bool isDark, ProductionCostSummary summary) {
    final colorMargen = summary.margenBrutoPorcentaje >= 30.0
        ? AppColors.greenBiomass
        : (summary.margenBrutoPorcentaje >= 15.0 ? AppColors.amberWarning : AppColors.coralAction);

    return GlassContainer(
      borderRadius: 20,
      blur: 24,
      opacity: isDark ? 0.16 : 0.85,
      tintColor: isDark ? const Color(0xFF0F172A) : Colors.white,
      borderColor: AppColors.cyanWater.withValues(alpha: isDark ? 0.35 : 0.25),
      borderWidth: 1.2,
      padding: const EdgeInsets.all(18),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isNarrow = constraints.maxWidth < 600;
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.cyanWater.withValues(alpha: isDark ? 0.20 : 0.12),
                      border: Border.all(color: AppColors.cyanWater.withValues(alpha: 0.5)),
                    ),
                    child: const Icon(Icons.account_balance_wallet_rounded, color: AppColors.cyanWater, size: 24),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              'FishBit Finanzas',
                              style: AppTypography.displayLarge.copyWith(
                                fontWeight: FontWeight.w900,
                                fontSize: isNarrow ? 20 : 24,
                                letterSpacing: -0.5,
                              ),
                            ),
                            const SizedBox(width: 10),
                            const GlassBadge(
                              text: 'HUB EJECUTIVO',
                              color: AppColors.cyanWater,
                            ),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Control de capital, unit economics por especie, simulador de retorno y nómina de campo',
                          style: AppTypography.bodySmall.copyWith(
                            color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (!isNarrow) ...[
                    const SizedBox(width: 12),
                    _buildRoiBadge(colorMargen, summary),
                  ],
                ],
              ),
              if (isNarrow) ...[
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Rendimiento Global del Proyecto:',
                      style: AppTypography.labelMicro.copyWith(
                        color: isDark ? Colors.white60 : Colors.black54,
                      ),
                    ),
                    _buildRoiBadge(colorMargen, summary),
                  ],
                ),
              ],
            ],
          );
        },
      ),
    );
  }

  Widget _buildRoiBadge(Color colorMargen, ProductionCostSummary summary) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: colorMargen.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colorMargen.withValues(alpha: 0.45)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.trending_up_rounded, color: colorMargen, size: 18),
          const SizedBox(width: 6),
          Text(
            'ROI: ${summary.roiEstimadoPorcentaje.toStringAsFixed(1)}%',
            style: TextStyle(
              color: colorMargen,
              fontWeight: FontWeight.w900,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }

  // TAB BAR INTERACTIVO
  Widget _buildTabBar(bool isDark) {
    return Container(
      height: 44,
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDark ? Colors.white.withValues(alpha: 0.08) : Colors.black.withValues(alpha: 0.06),
        ),
      ),
      child: TabBar(
        controller: _tabController,
        indicator: BoxDecoration(
          color: AppColors.cyanWater.withValues(alpha: isDark ? 0.28 : 0.20),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.cyanWater.withValues(alpha: 0.6)),
        ),
        labelColor: isDark ? Colors.white : AppColors.textPrimaryLight,
        unselectedLabelColor: isDark ? Colors.white60 : Colors.black54,
        labelStyle: const TextStyle(fontWeight: FontWeight.w800, fontSize: 12),
        unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
        indicatorSize: TabBarIndicatorSize.tab,
        dividerColor: Colors.transparent,
        onTap: (_) => setState(() {}),
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
            text: 'Nómina y Jornales',
          ),
        ],
      ),
    );
  }

  // TAB 1: RADIOGRAFÍA DE INVERSIÓN TOTAL Y UNIT ECONOMICS
  Widget _buildTabRadiografiaInversion(
    BuildContext context,
    bool isDark,
    ProductionCostSummary summary,
    WarehouseState warehouse,
    EquipmentState equipment,
    FinanceState finance,
    PondsState pondsState,
    SalesState salesState,
  ) {
    final inv = summary.investmentSummary;
    final totalInversion = inv?.inversionTotalConsolidada ?? summary.costoTotalProduccion;
    final capitalAgua = inv?.capitalEnAguaTotal ?? (summary.totalCostoAlevinos + summary.totalCostoAlimento);
    final capitalBodega = inv?.inventarioBodegaTotal ?? warehouse.valorTotalInventario;
    final activosFijos = inv?.activosFijosNetos ?? equipment.valorTotalActivos;
    final opexMes = inv?.totalGastosOperativosMes ?? summary.totalCostosIndirectos;
    final valorComercialBiomasa = pondsState.biomasaTotalKg * _simulatedMarketPrice;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 0. Valoración Comercial de Biomasa en Agua y Resultados de Cosecha (Trasladado desde Inicio para el Administrador)
        GlassCard(
          borderRadius: 20,
          glowColor: AppColors.cyanWater,
          title: 'VALOR TOTAL DE BIOMASA EN AGUA',
          trailingWidget: const GlassBadge(text: 'EN VIVO', color: AppColors.greenBiomass, icon: Icons.circle),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(
                  CurrencyFormatters.formatCOP(valorComercialBiomasa),
                  style: AppTypography.displayLarge.copyWith(
                    fontSize: 28,
                    color: AppColors.cyanWater,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              const SizedBox(height: 6),
              Wrap(
                spacing: 12,
                runSpacing: 4,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Text(
                    '${CurrencyFormatters.formatKg(pondsState.biomasaTotalKg)} en agua (@ ${CurrencyFormatters.formatCOP(_simulatedMarketPrice)}/Kg)',
                    style: AppTypography.bodySmall.copyWith(
                      color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                    ),
                  ),
                  Text(
                    'Costo Inv: ${CurrencyFormatters.formatCOP(pondsState.costoTotalEnAgua)}',
                    style: AppTypography.bodySmall.copyWith(
                      color: AppColors.greenBiomass,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: GlassCard(
                title: 'FishSales',
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
        const SizedBox(height: 16),

        // 1. Tarjeta Insignia de CPK
        const CpkBreakdownCard(),
        const SizedBox(height: 16),

        // 2. Banner Consolidado de Inversión Total
        GlassContainer(
          borderRadius: 18,
          blur: 18,
          opacity: isDark ? 0.12 : 0.70,
          tintColor: isDark ? const Color(0xFF1E293B) : Colors.white,
          borderColor: AppColors.cyanWater.withValues(alpha: 0.35),
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'CAPITAL TOTAL INVERTIDO EN GRANJA',
                    style: AppTypography.labelMicro.copyWith(
                      color: AppColors.cyanWater,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.0,
                    ),
                  ),
                  Text(
                    'Activos + OPEX + Biomasa',
                    style: TextStyle(
                      fontSize: 11,
                      color: isDark ? Colors.white60 : Colors.black54,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(
                  CurrencyFormatters.formatCOP(totalInversion),
                  style: AppTypography.displayLarge.copyWith(
                    fontWeight: FontWeight.w900,
                    color: AppColors.cyanWater,
                    letterSpacing: -0.5,
                  ),
                ),
              ),
              const SizedBox(height: 14),
              // Barra porcentual visual
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
              const SizedBox(height: 10),
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
        ),
        const SizedBox(height: 16),

        // 3. Grid de los 4 Pilares de Capital
        LayoutBuilder(
          builder: (context, constraints) {
            final isWide = constraints.maxWidth > 580;
            return GridView.count(
              crossAxisCount: isWide ? 4 : 2,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              childAspectRatio: isWide ? 1.45 : 1.35,
              children: [
                _buildAssetCard(
                  title: 'Capital en Agua',
                  subtitle: 'Biomasa y Alimento',
                  amount: capitalAgua,
                  pct: totalInversion > 0 ? (capitalAgua / totalInversion * 100) : 0,
                  icon: Icons.water_rounded,
                  color: AppColors.cyanWater,
                  isDark: isDark,
                ),
                _buildAssetCard(
                  title: 'En Bodega',
                  subtitle: 'Alimento y Medicamentos',
                  amount: capitalBodega,
                  pct: totalInversion > 0 ? (capitalBodega / totalInversion * 100) : 0,
                  icon: Icons.warehouse_rounded,
                  color: AppColors.greenBiomass,
                  isDark: isDark,
                ),
                _buildAssetCard(
                  title: 'Activos CAPEX',
                  subtitle: 'Equipos y Maquinaria',
                  amount: activosFijos,
                  pct: totalInversion > 0 ? (activosFijos / totalInversion * 100) : 0,
                  icon: Icons.precision_manufacturing_rounded,
                  color: AppColors.purpleAnalytics,
                  isDark: isDark,
                ),
                _buildAssetCard(
                  title: 'OPEX Mensual',
                  subtitle: 'Nómina, Energía y Otros',
                  amount: opexMes,
                  pct: totalInversion > 0 ? (opexMes / totalInversion * 100) : 0,
                  icon: Icons.receipt_long_rounded,
                  color: AppColors.coralAction,
                  isDark: isDark,
                ),
              ],
            );
          },
        ),
        const SizedBox(height: 16),

        // 4. Resumen de Depreciación y Energía
        Row(
          children: [
            Expanded(
              child: GlassCard(
                title: 'DEPRECIACIÓN DIARIA CAPEX',
                glowColor: AppColors.amberWarning,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: Text(
                        CurrencyFormatters.formatCOP(equipment.depreciacionDiariaTotal),
                        style: AppTypography.numberKpi.copyWith(color: AppColors.amberWarning, fontSize: 18),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text('Amortización acumulada de activos', style: AppTypography.bodyOf(context, fontSize: 11)),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: GlassCard(
                title: 'COSTO ENERGÉTICO MENSUAL',
                glowColor: AppColors.cyanWater,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: Text(
                        CurrencyFormatters.formatCOP(finance.totalCostoEnergia),
                        style: AppTypography.numberKpi.copyWith(color: AppColors.cyanWater, fontSize: 18),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text('Facturación directa de acueducto y luz', style: AppTypography.bodyOf(context, fontSize: 11)),
                  ],
                ),
              ),
            ),
          ],
        ),
      ],
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
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: AppTypography.titleSmall.copyWith(
                  fontWeight: FontWeight.w800,
                  fontSize: 12,
                  color: isDark ? Colors.white : AppColors.textPrimaryLight,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 10,
                  color: isDark ? Colors.white60 : Colors.black54,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(
                  CurrencyFormatters.formatCOP(amount),
                  style: AppTypography.titleMedium.copyWith(
                    fontWeight: FontWeight.w900,
                    fontSize: 15,
                    color: color,
                  ),
                ),
              ),
            ],
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
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 40),
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
        ),
      );
    }

    return ListView.separated(
      physics: const NeverScrollableScrollPhysics(),
      shrinkWrap: true,
      itemCount: especies.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final esp = especies[index];
        final colorMargen = esp.margenPorcentaje >= 30.0
            ? AppColors.greenBiomass
            : (esp.margenPorcentaje >= 15.0 ? AppColors.amberWarning : AppColors.coralAction);

        return GlassContainer(
          borderRadius: 18,
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
        FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerLeft,
          child: Text(
            value,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w800,
              color: color,
            ),
          ),
        ),
      ],
    );
  }

  // TAB 3: SIMULADOR DE MERCADO Y RETORNO (ROI)
  Widget _buildTabSimuladorMercado(
    BuildContext context,
    bool isDark,
    ProductionCostSummary summary,
  ) {
    final valorTotalVenta = summary.totalBiomasaKg * _simulatedMarketPrice;
    final utilidadTotal = valorTotalVenta - summary.costoTotalProduccion;
    final roi = summary.costoTotalProduccion > 0 ? (utilidadTotal / summary.costoTotalProduccion * 100) : 0.0;
    final colorResultado = utilidadTotal >= 0 ? AppColors.greenBiomass : AppColors.coralAction;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Tarjeta de Control del Simulador
        GlassContainer(
          borderRadius: 18,
          blur: 16,
          opacity: isDark ? 0.08 : 0.65,
          tintColor: isDark ? const Color(0xFF1E293B) : Colors.white,
          borderColor: AppColors.cyanWater.withValues(alpha: 0.3),
          padding: const EdgeInsets.all(18),
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
                padding: const EdgeInsets.all(16),
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
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: Text(
                        CurrencyFormatters.formatCOP(utilidadTotal),
                        style: AppTypography.titleMedium.copyWith(
                          fontWeight: FontWeight.w900,
                          fontSize: 16,
                          color: colorResultado,
                        ),
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
                padding: const EdgeInsets.all(16),
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
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: Text(
                        '${roi.toStringAsFixed(1)}%',
                        style: AppTypography.titleMedium.copyWith(
                          fontWeight: FontWeight.w900,
                          fontSize: 16,
                          color: colorResultado,
                        ),
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
          borderRadius: 18,
          blur: 16,
          opacity: isDark ? 0.08 : 0.65,
          tintColor: isDark ? const Color(0xFF1E293B) : Colors.white,
          borderColor: isDark ? Colors.white.withValues(alpha: 0.12) : AppColors.glassBorderLight,
          padding: const EdgeInsets.all(16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
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
              ),
              const SizedBox(width: 8),
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

  // TAB 4: NÓMINA DIRECTA, JORNALES E HISTORIAL OPERATIVO
  Widget _buildTabNominaYJornales(
    BuildContext context,
    bool isDark,
    FinanceState financeState,
    List<JornalRecord> dynamicFilteredJornales,
    List<PayrollRecord> dynamicFilteredPayroll,
    Map<String, Pond> pondMap,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 1. Registro Rápido de Nómina Mensual Consolidada
        GlassContainer(
          borderRadius: 18,
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
                          'REGISTRO RÁPIDO DE NÓMINA GENERAL',
                          style: AppTypography.titleSmall.copyWith(
                            fontWeight: FontWeight.w900,
                            color: isDark ? Colors.white : AppColors.textPrimaryLight,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Ingresa el valor total mensual pagado si no emites colillas individuales',
                          style: TextStyle(fontSize: 11, color: isDark ? Colors.white60 : Colors.black54),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _nominaRapidaController,
                      keyboardType: TextInputType.number,
                      inputFormatters: [CurrencyInputFormatter()],
                      style: TextStyle(
                        color: isDark ? Colors.white : AppColors.textPrimaryLight,
                        fontWeight: FontWeight.w800,
                      ),
                      decoration: InputDecoration(
                        labelText: 'Nómina Mensual Consolidada (\$ COP)',
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
                  ),
                  const SizedBox(width: 12),
                  SizedBox(
                    height: 52,
                    child: GlassButton(
                      label: _isSavingNomina ? '...' : 'Registrar',
                      icon: const Icon(Icons.check_circle_rounded, size: 18),
                      backgroundColor: AppColors.purpleAnalytics,
                      isLoading: _isSavingNomina,
                      borderRadius: 12,
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

                        final messenger = ScaffoldMessenger.of(context);
                        setState(() => _isSavingNomina = true);
                        try {
                          await ref.read(financeProvider.notifier).registrarNominaMensualGeneral(
                                valorTotalMensual: val,
                                mesPeriodo: DateTime.now(),
                              );
                          if (!mounted) return;
                          _nominaRapidaController.clear();
                          messenger.showSnackBar(
                            const SnackBar(
                              content: Text('Nómina mensual registrada con éxito'),
                              backgroundColor: AppColors.greenBiomass,
                            ),
                          );
                        } catch (e) {
                          if (!mounted) return;
                          messenger.showSnackBar(
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
            ],
          ),
        ),
        const SizedBox(height: 20),

        // 2. Selector de Rango de Fechas para Historial
        GlassDatePickerField(
          label: 'FILTRAR POR PERÍODO',
          mode: DatePickerSelectionMode.range,
          initialRange: _selectedRange,
          accentColor: AppColors.purpleAnalytics,
          placeholder: 'Todos los períodos (Toca para filtrar)',
          onRangeChanged: (range) => setState(() => _selectedRange = range),
        ),
        const SizedBox(height: 16),

        // 3. Encabezado de la Lista
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'HISTORIAL DE NÓMINA Y JORNALES',
              style: AppTypography.labelMicro.copyWith(
                color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                letterSpacing: 1.5,
              ),
            ),
            Row(
              children: [
                Text(
                  '${dynamicFilteredPayroll.length + dynamicFilteredJornales.length} registros',
                  style: const TextStyle(color: AppColors.cyanWater, fontSize: 11, fontWeight: FontWeight.w700),
                ),
                if (_selectedRange != null) ...[
                  const SizedBox(width: 8),
                  TextButton(
                    onPressed: () => setState(() => _selectedRange = null),
                    style: TextButton.styleFrom(padding: EdgeInsets.zero, visualDensity: VisualDensity.compact),
                    child: const Text('Limpiar', style: TextStyle(color: AppColors.coralAction, fontSize: 11, fontWeight: FontWeight.bold)),
                  ),
                ],
              ],
            ),
          ],
        ),
        const SizedBox(height: 12),

        // 4. Lista de Jornales Ocasionales
        if (dynamicFilteredJornales.isNotEmpty) ...[
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: dynamicFilteredJornales.length,
            itemBuilder: (context, index) {
              final j = dynamicFilteredJornales[index];
              final estanqueAsignado = j.estanqueId != null ? pondMap[j.estanqueId] : null;
              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: GlassCard(
                  title: j.laborRealizada,
                  subtitle: '${j.cantidadJornales} jornal(es) a ${CurrencyFormatters.formatCOP(j.valorPorJornal)} • ${j.fecha.day}/${j.fecha.month}/${j.fecha.year}',
                  trailingWidget: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (estanqueAsignado != null) ...[
                        GlassBadge(
                          text: estanqueAsignado.nombreLimpio,
                          color: AppColors.cyanWater,
                        ),
                        const SizedBox(width: 6),
                      ],
                      GlassBadge(
                        text: CurrencyFormatters.formatCOP(j.totalPagado),
                        color: AppColors.amberWarning,
                      ),
                      const SizedBox(width: 4),
                      IconButton(
                        icon: Icon(Icons.delete_outline_rounded, size: 16, color: isDark ? Colors.white38 : AppColors.textTertiaryLight),
                        splashRadius: 16,
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        onPressed: () {
                          ref.read(financeProvider.notifier).deleteJornal(j.id);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Registro de jornal eliminado'), duration: Duration(seconds: 2)),
                          );
                        },
                      ),
                    ],
                  ),
                  child: Text(
                    j.observaciones ?? 'Pago de mano de obra eventual de campo.',
                    style: AppTypography.bodyOf(context, fontSize: 12),
                  ),
                ),
              );
            },
          ),
        ],

        // 5. Lista de Nómina Fija
        if (dynamicFilteredPayroll.isNotEmpty) ...[
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: dynamicFilteredPayroll.length,
            itemBuilder: (context, index) {
              final rec = dynamicFilteredPayroll[index];
              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: GlassCard(
                  title: rec.empleadoNombre,
                  subtitle: 'Periodo: ${rec.periodo.toUpperCase()} • ${rec.fechaPago.day}/${rec.fechaPago.month}/${rec.fechaPago.year}',
                  trailingWidget: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      GlassBadge(
                        text: CurrencyFormatters.formatCOP(rec.salarioBase + rec.auxilioTransporte + rec.recargosExtras),
                        color: AppColors.cyanWater,
                      ),
                      const SizedBox(width: 4),
                      IconButton(
                        icon: const Icon(Icons.receipt_long_rounded, size: 16, color: AppColors.purpleAnalytics),
                        tooltip: 'Ver Comprobante de Nómina',
                        splashRadius: 16,
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        onPressed: () => ColillaNominaModal.show(context, record: rec),
                      ),
                      const SizedBox(width: 4),
                      IconButton(
                        icon: Icon(Icons.delete_outline_rounded, size: 16, color: isDark ? Colors.white38 : AppColors.textTertiaryLight),
                        splashRadius: 16,
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        onPressed: () {
                          ref.read(financeProvider.notifier).deletePayroll(rec.id);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Registro de nómina eliminado'), duration: Duration(seconds: 2)),
                          );
                        },
                      ),
                    ],
                  ),
                  child: Wrap(
                    spacing: 12,
                    runSpacing: 4,
                    alignment: WrapAlignment.spaceBetween,
                    children: [
                      Text('Base: ${CurrencyFormatters.formatCOP(rec.salarioBase)}', style: AppTypography.bodyOf(context)),
                      Text('Costo Empresa: ${CurrencyFormatters.formatCOP(rec.costoTotalEmpresa)}', style: AppTypography.bodyOf(context).copyWith(color: AppColors.coralAction, fontWeight: FontWeight.w700)),
                    ],
                  ),
                ),
              );
            },
          ),
        ],

        if (dynamicFilteredPayroll.isEmpty && dynamicFilteredJornales.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 36),
            child: Center(
              child: Text(
                'No hay registros de nómina o jornales emitidos en este período.',
                style: AppTypography.bodyOf(context, fontSize: 13),
              ),
            ),
          ),
      ],
    );
  }

  void _showFinanceActionsSheet(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => Container(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          border: Border.all(color: AppColors.cyanWater.withValues(alpha: 0.3)),
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.white24,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'ACCIONES DE NÓMINA Y OPEX',
                textAlign: TextAlign.center,
                style: TextStyle(fontWeight: FontWeight.w900, fontSize: 14, letterSpacing: 1.2, color: AppColors.cyanWater),
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.amberWarning,
                  foregroundColor: Colors.black87,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                icon: const Icon(Icons.agriculture_rounded),
                label: const Text('Registrar Jornal Ocasional', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 13)),
                onPressed: () {
                  Navigator.pop(ctx);
                  RegistroJornalModal.show(context);
                },
              ),
              const SizedBox(height: 10),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.cyanWater,
                  foregroundColor: Colors.black87,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                icon: const Icon(Icons.groups_rounded),
                label: const Text('Planilla Masiva de Pagos', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 13)),
                onPressed: () {
                  Navigator.pop(ctx);
                  LiquidacionMasivaModal.show(context);
                },
              ),
              const SizedBox(height: 10),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.purpleAnalytics,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                icon: const Icon(Icons.group_add_rounded),
                label: const Text('Registrar Pago de Nómina', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13)),
                onPressed: () {
                  Navigator.pop(ctx);
                  RegistroNominaModal.show(context);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
