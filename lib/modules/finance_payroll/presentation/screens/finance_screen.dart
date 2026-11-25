import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:fishbit_finance/core/design_system/app_colors.dart';
import 'package:fishbit_finance/core/design_system/app_typography.dart';
import 'package:fishbit_finance/core/design_system/fade_content.dart';
import 'package:fishbit_finance/core/design_system/fishbit_header.dart';
import 'package:fishbit_finance/core/design_system/glass_badge.dart';
import 'package:fishbit_finance/core/design_system/glass_button.dart';
import 'package:fishbit_finance/core/design_system/glass_container.dart';
import 'package:fishbit_finance/core/design_system/glass_date_picker.dart';
import 'package:fishbit_finance/core/design_system/floating_dock_layout.dart';
import 'package:fishbit_finance/core/design_system/hero_tabs.dart';
import 'package:fishbit_finance/core/design_system/magic_bento.dart';
import 'package:fishbit_finance/core/design_system/vertical_speed_dial.dart';
import 'package:fishbit_finance/core/utils/currency_formatters.dart';
import 'package:fishbit_finance/modules/auth_tenant/domain/models/company.dart';
import 'package:fishbit_finance/modules/auth_tenant/presentation/providers/auth_provider.dart';
import 'package:fishbit_finance/modules/finance_payroll/domain/models/production_cost_summary.dart';
import 'package:fishbit_finance/modules/finance_payroll/domain/services/production_cost_engine.dart';
import 'package:fishbit_finance/modules/finance_payroll/presentation/dialogs/colilla_nomina_modal.dart';
import 'package:fishbit_finance/modules/finance_payroll/presentation/dialogs/registro_jornal_modal.dart';
import 'package:fishbit_finance/modules/finance_payroll/presentation/dialogs/registro_nomina_equipo_modal.dart';
import 'package:fishbit_finance/modules/finance_payroll/presentation/providers/finance_provider.dart';
import 'package:fishbit_finance/modules/finance_payroll/presentation/widgets/species_price_card.dart';
import 'package:fishbit_finance/modules/equipment_capex/presentation/providers/equipment_provider.dart';
import 'package:fishbit_finance/modules/ponds_batches/domain/models/fish_batch.dart';
import 'package:fishbit_finance/modules/ponds_batches/domain/models/pond.dart';
import 'package:fishbit_finance/modules/finance_payroll/domain/models/jornal_record.dart';
import 'package:fishbit_finance/modules/finance_payroll/domain/models/payroll_record.dart';
import 'package:fishbit_finance/modules/ponds_batches/presentation/providers/ponds_provider.dart';
import 'package:fishbit_finance/modules/sales_harvest/presentation/providers/sales_provider.dart';
import 'package:fishbit_finance/modules/warehouse_inventory/presentation/providers/warehouse_provider.dart';

/// Pantalla Principal del Módulo FishBit Finanzas
class FinanceScreen extends ConsumerStatefulWidget {
  const FinanceScreen({super.key});

  @override
  ConsumerState<FinanceScreen> createState() => _FinanceScreenState();
}

class _FinanceScreenState extends ConsumerState<FinanceScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  CivilDateRange? _selectedRange;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(_onTabChanged);
  }

  void _onTabChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _tabController.removeListener(_onTabChanged);
    _tabController.dispose();
    super.dispose();
  }

  Map<String, double> _extractSpeciesPrices(Company? company) {
    final map = <String, double>{};
    if (company == null) return map;
    company.preciosMercadoEspecies.forEach((key, value) {
      final parsed = (value is num)
          ? value.toDouble()
          : double.tryParse(value.toString());
      if (parsed != null && parsed > 0) {
        map[key] = parsed;
      }
    });
    return map;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final authState = ref.watch(authProvider);
    final company = authState.currentCompany;
    final pondsState = ref.watch(pondsProvider);
    final warehouseState = ref.watch(warehouseProvider);
    final financeState = ref.watch(financeProvider);
    final equipmentState = ref.watch(equipmentProvider);
    final salesState = ref.watch(salesProvider);
    final pondMap = {for (final p in pondsState.ponds) p.id: p};

    final batches = pondsState.batches;
    final activeBatches = batches.where((b) => b.estado == BatchStatus.active).toList();
    final costoInsumosRealLotes = activeBatches.fold(0.0, (sum, b) => sum + b.costoAcumuladoInsumos);
    final totalAlimentoFacturas = warehouseState.invoices.fold(0.0, (sum, inv) => sum + inv.totalFactura);
    final totalAlimentoInsumosEfectivo = costoInsumosRealLotes > 0 ? costoInsumosRealLotes : totalAlimentoFacturas;

    final preciosPorEspecie = _extractSpeciesPrices(company);
    final precioBaseMercado = (company != null && company.precioMercadoActualKg > 0)
        ? company.precioMercadoActualKg
        : 10500.0;

    final summary = ProductionCostEngine.calculate(
      ponds: pondsState.ponds,
      batches: batches,
      jornalesList: financeState.jornales,
      totalAlimentoInsumos: totalAlimentoInsumosEfectivo,
      totalNominaFija: financeState.totalCostoNomina,
      totalJornales: financeState.totalCostoJornales,
      totalEnergia: financeState.totalCostoEnergia,
      totalDepreciacionCapex: equipmentState.depreciacionDiariaTotal * 30.0,
      precioMercadoKg: precioBaseMercado,
      preciosPorEspecie: preciosPorEspecie,
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
      body: Stack(
        children: [
          CustomScrollView(
            slivers: [
              FishBitHeader(
                onRefresh: () {
                  ref.read(financeProvider.notifier).loadFinanceData();
                  ref.read(equipmentProvider.notifier).loadEquipment();
                },
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Título con identidad visual FishBit
                      FadeContent(
                        delay: Duration.zero,
                        child: _buildModuleTitle(isDark),
                      ),
                      const SizedBox(height: 14),

                      // Barra de navegación replicada de Bitácora y Almacén (solo iconos)
                      FadeContent(
                        delay: const Duration(milliseconds: 80),
                        child: Center(
                          child: HeroTabsBar(
                            controller: _tabController,
                            borderless: true,
                            iconOnly: true,
                            onTap: (_) => setState(() {}),
                            tabs: const [
                              HeroTabItem(
                                key: Key('tab_finanzas_inversion'),
                                label: 'Radiografía de Inversión',
                                icon: Icons.pie_chart_rounded,
                                accentColor: AppColors.cyanWater,
                              ),
                              HeroTabItem(
                                key: Key('tab_finanzas_especies'),
                                label: 'Costo por Especie',
                                icon: Icons.set_meal_rounded,
                                accentColor: AppColors.greenBiomass,
                              ),
                              HeroTabItem(
                                key: Key('tab_finanzas_nomina'),
                                label: 'Nómina y Jornales',
                                icon: Icons.payments_rounded,
                                accentColor: AppColors.purpleAnalytics,
                              ),
                            ],
                          ),
                        ),
                      ),
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
                      final Widget tabContent = switch (_tabController.index) {
                        0 => _buildTabRadiografiaInversion(
                            context,
                            isDark,
                            summary,
                            warehouseState,
                            equipmentState,
                            financeState,
                            pondsState,
                            salesState,
                            totalAlimentoInsumosEfectivo,
                          ),
                        1 => _buildTabDesgloseEspecies(
                            context,
                            isDark,
                            summary,
                            company,
                            preciosPorEspecie,
                            precioBaseMercado,
                          ),
                        2 => _buildTabNominaYJornales(
                            context,
                            isDark,
                            summary,
                            financeState,
                            filteredJornales,
                            filteredPayroll,
                            pondMap,
                          ),
                        _ => const SizedBox.shrink(),
                      };

                      return FadeContent(
                        key: ValueKey<int>(_tabController.index),
                        delay: Duration.zero,
                        duration: const Duration(milliseconds: 360),
                        offsetY: 10,
                        blurSigma: 4,
                        child: tabContent,
                      );
                    },
                  ),
                ),
              ),
              const SliverDockBottomSpacer(),
            ],
          ),

          // Speed Dial estilo Bitácora exclusivo del módulo de Nómina (Tab 2)
          if (_tabController.index == 2)
            Positioned.fill(
              child: VerticalSpeedDial(
                toggleButtonKey: const Key('nomina_speed_dial_toggle'),
                bottomOffset:
                    FloatingDockLayout.dockTopOffset(context) + FloatingDockLayout.fabDockGap,
                primaryColor: AppColors.purpleAnalytics,
                hoverPrimaryColor: const Color(0xFF7C3AED),
                actions: [
                  VerticalSpeedDialAction(
                    key: const Key('dial_action_jornalero'),
                    label: 'Jornalero',
                    icon: Icons.agriculture_rounded,
                    hoverIconColor: AppColors.amberWarning,
                    onTap: () => RegistroJornalModal.show(context),
                  ),
                  VerticalSpeedDialAction(
                    key: const Key('dial_action_nomina'),
                    label: 'Nómina',
                    icon: Icons.groups_rounded,
                    hoverIconColor: AppColors.purpleAnalytics,
                    onTap: () => RegistroNominaEquipoModal.show(context),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  /// Título del módulo con paleta oficial FishBit (cyanWater + coralAction)
  Widget _buildModuleTitle(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text.rich(
          TextSpan(
            children: [
              TextSpan(
                text: 'Fish',
                style: AppTypography.displayLarge.copyWith(
                  fontSize: 26,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.7,
                  color: AppColors.cyanWater,
                  shadows: [
                    Shadow(
                      color: AppColors.cyanWater.withValues(alpha: 0.45),
                      blurRadius: 12,
                    ),
                  ],
                ),
              ),
              TextSpan(
                text: 'Bit',
                style: AppTypography.displayLarge.copyWith(
                  fontSize: 26,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.7,
                  color: AppColors.coralAction,
                  shadows: [
                    Shadow(
                      color: AppColors.coralAction.withValues(alpha: 0.45),
                      blurRadius: 12,
                    ),
                  ],
                ),
              ),
              TextSpan(
                text: ' Finanzas',
                style: AppTypography.displayLarge.copyWith(
                  fontSize: 26,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.7,
                  color: isDark ? Colors.white : AppColors.textPrimaryLight,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 6),
        Container(
          width: 56,
          height: 3,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(99),
            gradient: const LinearGradient(
              colors: [AppColors.cyanWater, AppColors.coralAction],
            ),
          ),
        ),
      ],
    );
  }

  // TAB 0: RADIOGRAFÍA DE INVERSIÓN TOTAL
  Widget _buildTabRadiografiaInversion(
    BuildContext context,
    bool isDark,
    ProductionCostSummary summary,
    WarehouseState warehouse,
    EquipmentState equipment,
    FinanceState finance,
    PondsState pondsState,
    SalesState salesState,
    double costoAlimentoReal,
  ) {
    final inv = summary.investmentSummary;
    final totalInversion = inv?.inversionTotalConsolidada ?? summary.costoTotalProduccion;
    final capitalAgua = inv?.capitalEnAguaTotal ?? (summary.totalCostoAlevinos + summary.totalCostoAlimento);
    final capitalBodega = inv?.inventarioBodegaTotal ?? warehouse.valorTotalInventario;
    final activosFijos = inv?.activosFijosNetos ?? equipment.valorTotalActivos;
    final opexMes = inv?.totalGastosOperativosMes ?? summary.totalCostosIndirectos;

    // Capital real invertido en biomasa en agua separado correctamente por semilla vs alimento/insumos
    // (evita doble conteo ya que `estanque.costo_acumulado_biologico` incluye semilla + alimento).
    final activeBatches = pondsState.batches.where((b) => b.estado == BatchStatus.active).toList();
    final double costoSemillaReal = activeBatches.isNotEmpty
        ? activeBatches.fold(0.0, (sum, b) => sum + b.costoInicialAlevinos)
        : pondsState.costoTotalEnAgua;
    final double costoAlimentoEnAgua = activeBatches.isNotEmpty
        ? activeBatches.fold(0.0, (sum, b) => sum + b.costoAcumuladoInsumos)
        : costoAlimentoReal;
    final double capitalInvertidoEnAgua = activeBatches.isNotEmpty
        ? (costoSemillaReal + costoAlimentoEnAgua)
        : pondsState.costoTotalEnAgua;
    final double costoInvertidoPorKg = pondsState.biomasaTotalKg > 0
        ? (capitalInvertidoEnAgua / pondsState.biomasaTotalKg)
        : 0.0;

    final pctAgua = totalInversion > 0 ? (capitalAgua / totalInversion * 100) : 0.0;
    final pctBodega = totalInversion > 0 ? (capitalBodega / totalInversion * 100) : 0.0;
    final pctActivos = totalInversion > 0 ? (activosFijos / totalInversion * 100) : 0.0;
    final pctOpex = totalInversion > 0 ? (opexMes / totalInversion * 100) : 0.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 1. Capital Real Invertido en Biomasa en Agua (sin proyección de venta)
        FadeContent(
          delay: Duration.zero,
          child: MagicBentoCard(
            seed: 11,
            radius: 20,
            glowColor: AppColors.cyanWater,
            icon: Icons.water_drop_rounded,
            title: 'VALOR TOTAL DE BIOMASA EN AGUA',
            trailingWidget: const GlassBadge(
              text: 'CAPITAL INVERTIDO',
              color: AppColors.greenBiomass,
              icon: Icons.circle,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    CurrencyFormatters.formatCOP(capitalInvertidoEnAgua),
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
                      '${CurrencyFormatters.formatKg(pondsState.biomasaTotalKg)} en agua',
                      style: AppTypography.bodySmall.copyWith(
                        color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      'Semilla: ${CurrencyFormatters.formatCOP(costoSemillaReal)}',
                      style: AppTypography.bodySmall.copyWith(
                        color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                      ),
                    ),
                    Text(
                      'Alimento/Insumos: ${CurrencyFormatters.formatCOP(costoAlimentoEnAgua)}',
                      style: AppTypography.bodySmall.copyWith(
                        color: AppColors.greenBiomass,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    if (costoInvertidoPorKg > 0)
                      Text(
                        'Costo/Kg: ${CurrencyFormatters.formatCOP(costoInvertidoPorKg)}',
                        style: AppTypography.bodySmall.copyWith(
                          color: AppColors.cyanWater,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),

        // 2. Grid Bento de FishSales y Utilidad
        FadeContent(
          delay: const Duration(milliseconds: 90),
          child: MagicBentoGrid(
            columns: 2,
            rowHeight: 148,
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
                title: 'FishSales',
                icon: Icons.point_of_sale_rounded,
                glowColor: AppColors.greenBiomass,
                onTap: () => context.go('/sales'),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        CurrencyFormatters.formatCOP(salesState.totalIngresosBrutos),
                        style: AppTypography.numberKpi.copyWith(
                          color: AppColors.greenBiomass,
                          fontSize: 18,
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Ingresos Cosechas',
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
                title: 'Utilidad',
                icon: Icons.trending_up_rounded,
                glowColor: AppColors.purpleAnalytics,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        CurrencyFormatters.formatCOP(salesState.totalUtilidadNeta),
                        style: AppTypography.numberKpi.copyWith(
                          color: AppColors.purpleAnalytics,
                          fontSize: 18,
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Margen Acumulado',
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
        ),
        const SizedBox(height: 16),

        // 3. Banner Consolidado de Inversión Total
        FadeContent(
          delay: const Duration(milliseconds: 180),
          child: MagicBentoCard(
            seed: 23,
            radius: 20,
            glowColor: AppColors.cyanWater,
            icon: Icons.account_balance_wallet_rounded,
            title: 'CAPITAL TOTAL INVERTIDO EN GRANJA',
            trailingWidget: Text(
              'Activos + OPEX + Biomasa',
              style: TextStyle(
                fontSize: 11,
                color: isDark ? Colors.white60 : Colors.black54,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
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
        ),
        const SizedBox(height: 16),

        // 4. Grid Bento de los 4 Pilares de Capital (estilo Inicio: 4 cols desktop / 2x2 móvil)
        FadeContent(
          delay: const Duration(milliseconds: 270),
          child: MagicBentoGrid(
            columns: 4,
            rowHeight: 168,
            gap: 12,
            radius: 20,
            enableBorderGlow: true,
            enableSpotlight: true,
            spotlightRadius: 420,
            clickEffect: true,
            enableStars: true,
            enableMagnetism: true,
            items: [
              _buildCapitalPillarItem(
                title: 'Capital en Agua',
                subtitle: 'Biomasa y Alimento',
                amount: capitalAgua,
                pct: pctAgua,
                icon: Icons.water_rounded,
                color: AppColors.cyanWater,
                isDark: isDark,
              ),
              _buildCapitalPillarItem(
                title: 'En Bodega',
                subtitle: 'Alimento y Farmacia',
                amount: capitalBodega,
                pct: pctBodega,
                icon: Icons.warehouse_rounded,
                color: AppColors.greenBiomass,
                isDark: isDark,
              ),
              _buildCapitalPillarItem(
                title: 'Activos CAPEX',
                subtitle: 'Equipos y Maquinaria',
                amount: activosFijos,
                pct: pctActivos,
                icon: Icons.precision_manufacturing_rounded,
                color: AppColors.purpleAnalytics,
                isDark: isDark,
              ),
              _buildCapitalPillarItem(
                title: 'OPEX Mensual',
                subtitle: 'Nómina, Energía y Otros',
                amount: opexMes,
                pct: pctOpex,
                icon: Icons.receipt_long_rounded,
                color: AppColors.coralAction,
                isDark: isDark,
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // 5. Grid Bento de Depreciación y Energía
        FadeContent(
          delay: const Duration(milliseconds: 360),
          child: MagicBentoGrid(
            columns: 2,
            rowHeight: 148,
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
                title: 'Depreciación Diaria CAPEX',
                icon: Icons.trending_down_rounded,
                glowColor: AppColors.amberWarning,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: Text(
                        CurrencyFormatters.formatCOP(equipment.depreciacionDiariaTotal),
                        style: AppTypography.numberKpi.copyWith(
                          color: AppColors.amberWarning,
                          fontSize: 18,
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Amortización acumulada de activos',
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
                title: 'Costo Energético Mensual',
                icon: Icons.bolt_rounded,
                glowColor: AppColors.cyanWater,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: Text(
                        CurrencyFormatters.formatCOP(finance.totalCostoEnergia),
                        style: AppTypography.numberKpi.copyWith(
                          color: AppColors.cyanWater,
                          fontSize: 18,
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Facturación directa de acueducto y luz',
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
        ),
      ],
    );
  }

  MagicBentoCardData _buildCapitalPillarItem({
    required String title,
    required String subtitle,
    required double amount,
    required double pct,
    required IconData icon,
    required Color color,
    required bool isDark,
  }) {
    return MagicBentoCardData(
      title: title,
      icon: icon,
      glowColor: color,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              CurrencyFormatters.formatCOP(amount),
              style: AppTypography.numberKpi.copyWith(
                fontWeight: FontWeight.w900,
                fontSize: 17,
                color: color,
              ),
            ),
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Expanded(
                child: Text(
                  subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.labelMicro.copyWith(
                    color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                  ),
                ),
              ),
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  '${pct.toStringAsFixed(1)}%',
                  style: TextStyle(
                    color: color,
                    fontWeight: FontWeight.w800,
                    fontSize: 10,
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

  // TAB 1: COSTO Y RENDIMIENTO POR ESPECIE + BENTO CARD INTERACTIVO DE PRECIOS
  Widget _buildTabDesgloseEspecies(
    BuildContext context,
    bool isDark,
    ProductionCostSummary summary,
    Company? company,
    Map<String, double> preciosPorEspecie,
    double precioBaseMercado,
  ) {
    final especies = summary.especiesBreakdown;

    // Lista consolidada de especies manejadas (activas en agua + habilitadas en la empresa)
    final managedSpecies = <String>{
      ...especies.map((e) => e.especie),
      if (company != null) ...company.especiesHabilitadas,
    }.toList();

    // Mapa rápido de métricas activas por especie para el subtítulo de cada tarjeta
    final speciesMetricsMap = {for (final e in especies) e.especie: e};

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Encabezado de sección Precios de Venta por Especie
        FadeContent(
          delay: Duration.zero,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'PRECIOS DE VENTA POR ESPECIE',
                    style: AppTypography.labelMicro.copyWith(
                      color: AppColors.greenBiomass,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.1,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Toca una tarjeta para actualizar su precio actual (\$/Kg)',
                    style: AppTypography.bodySmall.copyWith(
                      fontSize: 11.5,
                      color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                    ),
                  ),
                ],
              ),
              GlassBadge(
                text: '${managedSpecies.length} especies',
                color: AppColors.greenBiomass,
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),

        // Carrusel horizontal de tarjetas Uiverse (una por especie)
        SizedBox(
          height: 248,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 6),
            itemCount: managedSpecies.length,
            separatorBuilder: (_, __) => const SizedBox(width: 14),
            itemBuilder: (context, index) {
              final especie = managedSpecies[index];
              final precioActual = preciosPorEspecie[especie] ?? precioBaseMercado;
              final metrics = speciesMetricsMap[especie];
              final subtitle = metrics != null
                  ? '${metrics.estanquesCount} estanque(s) • ${metrics.totalBiomasaKg.toStringAsFixed(0)} Kg'
                  : 'Toca para editar precio';

              return FadeContent(
                delay: Duration(milliseconds: (index * 60).clamp(0, 240)),
                child: SpeciesPriceCard(
                  key: Key('species_price_chip_$especie'),
                  especie: especie,
                  precioKg: precioActual,
                  subtitle: subtitle,
                  onTap: () => _showEditSpeciesPriceDialog(
                    context,
                    especie: especie,
                    currentPrice: precioActual,
                    company: company,
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 14),

        if (especies.isEmpty)
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 36),
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
          )
        else
          ListView.separated(
            physics: const NeverScrollableScrollPhysics(),
            shrinkWrap: true,
            itemCount: especies.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final esp = especies[index];
              final colorMargen = esp.margenPorcentaje >= 30.0
                  ? AppColors.greenBiomass
                  : (esp.margenPorcentaje >= 15.0 ? AppColors.amberWarning : AppColors.coralAction);

              return FadeContent(
                delay: Duration(milliseconds: (index * 70).clamp(0, 350)),
                child: MagicBentoCard(
                  seed: index + 31,
                  radius: 20,
                  glowColor: colorMargen,
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
                              label: 'Precio Venta',
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
                ),
              );
            },
          ),
      ],
    );
  }

  Future<void> _showEditSpeciesPriceDialog(
    BuildContext context, {
    required String especie,
    required double currentPrice,
    required Company? company,
  }) async {
    if (company == null) return;
    final savedPrice = await showDialog<double>(
      context: context,
      builder: (_) => _EditSpeciesPriceDialog(
        especie: especie,
        currentPrice: currentPrice,
        company: company,
      ),
    );

    if (savedPrice != null && mounted) {
      ScaffoldMessenger.of(this.context).showSnackBar(
        SnackBar(
          content: Text(
            'Precio de $especie actualizado a ${CurrencyFormatters.formatCOP(savedPrice)}/Kg',
          ),
          backgroundColor: AppColors.greenBiomass,
        ),
      );
    }
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

  // TAB 2: NÓMINA DIRECTA, JORNALES E HISTORIAL OPERATIVO
  Widget _buildTabNominaYJornales(
    BuildContext context,
    bool isDark,
    ProductionCostSummary summary,
    FinanceState financeState,
    List<JornalRecord> dynamicFilteredJornales,
    List<PayrollRecord> dynamicFilteredPayroll,
    Map<String, Pond> pondMap,
  ) {
    final now = DateTime.now();
    final quarterStart = DateTime(now.year, now.month - 2, 1);

    // 1. Costo de nómina del mes actual (principal) + jornales del mes (complementario)
    final double nominaMesActual = financeState.payrollRecords
        .where((p) => p.fechaPago.year == now.year && p.fechaPago.month == now.month)
        .fold(0.0, (sum, p) => sum + p.costoTotalEmpresa);
    final double jornalesMesActual = financeState.jornales
        .where((j) => j.fecha.year == now.year && j.fecha.month == now.month)
        .fold(0.0, (sum, j) => sum + j.totalPagado);

    // 2. Acumulado último trimestre (últimos 3 meses calendario)
    final double nominaUltimoTrimestre = financeState.payrollRecords
        .where((p) => !p.fechaPago.isBefore(quarterStart))
        .fold(0.0, (sum, p) => sum + p.costoTotalEmpresa);

    // 3. Acumulado año anterior
    final double nominaAnoAnterior = financeState.payrollRecords
        .where((p) => p.fechaPago.year == now.year - 1)
        .fold(0.0, (sum, p) => sum + p.costoTotalEmpresa);

    // 4. Impacto porcentual sobre el costo total de producción actual
    final double impactoProduccionPct = summary.costoTotalProduccion > 0
        ? ((financeState.totalCostoNomina / summary.costoTotalProduccion) * 100.0).clamp(0.0, 100.0)
        : 0.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 1. Bento Card Fijo de KPIs de Nómina
        FadeContent(
          delay: Duration.zero,
          child: MagicBentoCard(
            seed: 41,
            radius: 20,
            glowColor: AppColors.purpleAnalytics,
            icon: Icons.payments_rounded,
            title: 'COSTO DE NÓMINA ACTUAL',
            trailingWidget: GlassBadge(
              text: '${impactoProduccionPct.toStringAsFixed(1)}% IMPACTO',
              color: AppColors.purpleAnalytics,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    CurrencyFormatters.formatCOP(nominaMesActual),
                    style: AppTypography.displayLarge.copyWith(
                      fontSize: 28,
                      fontWeight: FontWeight.w900,
                      color: AppColors.purpleAnalytics,
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Mes en curso • Jornales del mes: ${CurrencyFormatters.formatCOP(jornalesMesActual)}',
                  style: AppTypography.bodySmall.copyWith(
                    color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                  ),
                ),
                const SizedBox(height: 14),

                // Comparativos históricos: Último Trimestre & Año Anterior
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: isDark
                              ? Colors.white.withValues(alpha: 0.05)
                              : Colors.black.withValues(alpha: 0.03),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: isDark ? Colors.white10 : AppColors.glassBorderLight,
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'ÚLTIMO TRIMESTRE',
                              style: AppTypography.labelMicro.copyWith(
                                fontSize: 10,
                                color: isDark ? Colors.white60 : Colors.black54,
                              ),
                            ),
                            const SizedBox(height: 4),
                            FittedBox(
                              fit: BoxFit.scaleDown,
                              alignment: Alignment.centerLeft,
                              child: Text(
                                CurrencyFormatters.formatCOP(nominaUltimoTrimestre),
                                style: AppTypography.titleMedium.copyWith(
                                  fontWeight: FontWeight.w900,
                                  color: AppColors.cyanWater,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: isDark
                              ? Colors.white.withValues(alpha: 0.05)
                              : Colors.black.withValues(alpha: 0.03),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: isDark ? Colors.white10 : AppColors.glassBorderLight,
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'AÑO ANTERIOR (${now.year - 1})',
                              style: AppTypography.labelMicro.copyWith(
                                fontSize: 10,
                                color: isDark ? Colors.white60 : Colors.black54,
                              ),
                            ),
                            const SizedBox(height: 4),
                            FittedBox(
                              fit: BoxFit.scaleDown,
                              alignment: Alignment.centerLeft,
                              child: Text(
                                CurrencyFormatters.formatCOP(nominaAnoAnterior),
                                style: AppTypography.titleMedium.copyWith(
                                  fontWeight: FontWeight.w900,
                                  color: isDark ? Colors.white : AppColors.textPrimaryLight,
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

                // Barra de impacto sobre el costo de producción general
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'IMPACTO EN COSTO DE PRODUCCIÓN GENERAL',
                      style: AppTypography.labelMicro.copyWith(
                        fontSize: 10,
                        color: isDark ? Colors.white70 : Colors.black54,
                      ),
                    ),
                    Text(
                      '${impactoProduccionPct.toStringAsFixed(1)}%',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w900,
                        color: AppColors.purpleAnalytics,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: LinearProgressIndicator(
                    value: (impactoProduccionPct / 100.0).clamp(0.0, 1.0),
                    minHeight: 8,
                    backgroundColor: isDark ? Colors.white12 : Colors.black12,
                    valueColor: const AlwaysStoppedAnimation<Color>(AppColors.purpleAnalytics),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),

        // 2. Selector de Rango de Fechas para Historial
        FadeContent(
          delay: const Duration(milliseconds: 80),
          child: GlassDatePickerField(
            label: 'FILTRAR POR PERÍODO',
            mode: DatePickerSelectionMode.range,
            initialRange: _selectedRange,
            accentColor: AppColors.purpleAnalytics,
            placeholder: 'Todos los períodos (Toca para filtrar)',
            onRangeChanged: (range) => setState(() => _selectedRange = range),
          ),
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
                child: FadeContent(
                  delay: Duration(milliseconds: (index * 60).clamp(0, 300)),
                  child: MagicBentoCard(
                    seed: index + 51,
                    glowColor: AppColors.amberWarning,
                    title: j.laborRealizada,
                    subtitle: '${j.cantidadJornales} jornal(es) a ${CurrencyFormatters.formatCOP(j.valorPorJornal)} • ${j.fecha.day}/${j.fecha.month}/${j.fecha.year}',
                    clickEffect: false,
                    trailingWidget: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        GlassBadge(
                          text: estanqueAsignado?.nombreLimpio ?? 'Costo General',
                          color: estanqueAsignado != null ? AppColors.cyanWater : AppColors.purpleAnalytics,
                        ),
                        const SizedBox(width: 6),
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
                      [
                        if (j.responsablePago != null && j.responsablePago!.isNotEmpty)
                          'Responsable: ${j.responsablePago}',
                        j.observaciones ?? 'Pago de mano de obra eventual de campo.',
                      ].join(' • '),
                      style: AppTypography.bodyOf(context, fontSize: 12),
                    ),
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
                child: FadeContent(
                  delay: Duration(milliseconds: (index * 60).clamp(0, 300)),
                  child: MagicBentoCard(
                    seed: index + 71,
                    glowColor: AppColors.cyanWater,
                    title: rec.empleadoNombre,
                    subtitle: 'Periodo: ${rec.periodo.toUpperCase()} • ${rec.fechaPago.day}/${rec.fechaPago.month}/${rec.fechaPago.year}',
                    clickEffect: false,
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
}

/// Diálogo stateful dedicado para editar el precio de venta por especie,
/// gestionando de forma segura el ciclo de vida de su [TextEditingController].
class _EditSpeciesPriceDialog extends ConsumerStatefulWidget {
  final String especie;
  final double currentPrice;
  final Company company;

  const _EditSpeciesPriceDialog({
    required this.especie,
    required this.currentPrice,
    required this.company,
  });

  @override
  ConsumerState<_EditSpeciesPriceDialog> createState() =>
      _EditSpeciesPriceDialogState();
}

class _EditSpeciesPriceDialogState
    extends ConsumerState<_EditSpeciesPriceDialog> {
  late final TextEditingController _ctrl;
  bool _isSaving = false;
  String? _errorText;

  @override
  void initState() {
    super.initState();
    _ctrl = TextEditingController(
      text: CurrencyFormatters.formatCOP(widget.currentPrice),
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _adjustBy(double delta) {
    final cur = CurrencyFormatters.parseCOP(_ctrl.text);
    final next = (cur + delta).clamp(500.0, 500000.0);
    _ctrl.text = CurrencyFormatters.formatCOP(next);
    setState(() => _errorText = null);
  }

  Future<void> _save() async {
    final newPrice = CurrencyFormatters.parseCOP(_ctrl.text);
    if (newPrice <= 0) {
      setState(() => _errorText = 'Ingresa un precio válido mayor a \$0');
      return;
    }

    FocusScope.of(context).unfocus();
    setState(() {
      _isSaving = true;
      _errorText = null;
    });

    final updatedPrices =
        Map<String, dynamic>.from(widget.company.preciosMercadoEspecies);
    updatedPrices[widget.especie] = newPrice;

    final ok = await ref.read(authProvider.notifier).updateCompany(
          widget.company.copyWith(preciosMercadoEspecies: updatedPrices),
        );

    if (!mounted) return;
    if (ok) {
      Navigator.of(context).pop(newPrice);
    } else {
      setState(() {
        _isSaving = false;
        _errorText = 'No se pudo guardar el precio. Intenta de nuevo.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: GlassContainer(
          borderRadius: 22,
          padding: const EdgeInsets.all(20),
          blur: 24,
          opacity: isDark ? 0.18 : 0.94,
          borderColor: AppColors.greenBiomass.withValues(alpha: 0.4),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppColors.greenBiomass.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(
                          Icons.sell_rounded,
                          color: AppColors.greenBiomass,
                          size: 18,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'ACTUALIZAR PRECIO DE VENTA',
                            style: AppTypography.labelMicro.copyWith(
                              color: AppColors.greenBiomass,
                              letterSpacing: 1.0,
                            ),
                          ),
                          Text(
                            widget.especie,
                            style: AppTypography.titleOf(
                              context,
                              fontWeight: FontWeight.w900,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  IconButton(
                    icon: Icon(
                      Icons.close_rounded,
                      color: isDark ? Colors.white60 : Colors.black54,
                    ),
                    onPressed: _isSaving ? null : () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              TextField(
                key: const Key('edit_species_price_input'),
                controller: _ctrl,
                keyboardType: TextInputType.number,
                inputFormatters: [CurrencyInputFormatter()],
                onSubmitted: (_) => _save(),
                style: TextStyle(
                  color: isDark ? Colors.white : AppColors.textPrimaryLight,
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                ),
                decoration: InputDecoration(
                  labelText: 'Precio de venta por Kg (\$ COP)',
                  errorText: _errorText,
                  prefixIcon: const Icon(
                    Icons.attach_money_rounded,
                    color: AppColors.greenBiomass,
                  ),
                  filled: true,
                  fillColor: isDark
                      ? Colors.white.withValues(alpha: 0.06)
                      : Colors.black.withValues(alpha: 0.03),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide(
                      color: AppColors.greenBiomass.withValues(alpha: 0.35),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  _buildQuickDeltaChip('-500', () => _adjustBy(-500), isDark),
                  const SizedBox(width: 8),
                  _buildQuickDeltaChip('+500', () => _adjustBy(500), isDark),
                  const SizedBox(width: 8),
                  _buildQuickDeltaChip('+1.000', () => _adjustBy(1000), isDark),
                ],
              ),
              const SizedBox(height: 18),
              GlassButton(
                key: const Key('save_species_price_btn'),
                label: 'Guardar Precio',
                isLoading: _isSaving,
                backgroundColor: AppColors.greenBiomass,
                onPressed: _save,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQuickDeltaChip(String label, VoidCallback onTap, bool isDark) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: isDark
              ? Colors.white.withValues(alpha: 0.08)
              : Colors.black.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isDark
                ? Colors.white.withValues(alpha: 0.14)
                : Colors.black.withValues(alpha: 0.10),
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
}
