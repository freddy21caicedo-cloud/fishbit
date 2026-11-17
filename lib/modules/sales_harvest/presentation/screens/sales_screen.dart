import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fishbit_finance/core/design_system/app_colors.dart';
import 'package:fishbit_finance/core/design_system/app_typography.dart';
import 'package:fishbit_finance/core/design_system/fishbit_header.dart';
import 'package:fishbit_finance/core/design_system/glass_card.dart';
import 'package:fishbit_finance/core/design_system/floating_dock_layout.dart';
import 'package:fishbit_finance/core/design_system/glass_badge.dart';
import 'package:fishbit_finance/core/design_system/glass_date_picker.dart';
import 'package:fishbit_finance/modules/sales_harvest/domain/models/batch_sale.dart';
import 'package:fishbit_finance/modules/sales_harvest/presentation/dialogs/venta_rapida_modal.dart';
import 'package:fishbit_finance/modules/sales_harvest/presentation/providers/sales_provider.dart';

import 'package:fishbit_finance/core/utils/currency_formatters.dart';
import 'package:fishbit_finance/modules/sales_harvest/presentation/widgets/fishsales_hero_header.dart';
import 'package:fishbit_finance/modules/sales_harvest/presentation/widgets/sales_kpi_scorecard.dart';
import 'package:fishbit_finance/modules/sales_harvest/presentation/widgets/sales_trends_chart.dart';




class SalesScreen extends ConsumerStatefulWidget {
  const SalesScreen({super.key});

  @override
  ConsumerState<SalesScreen> createState() => _SalesScreenState();
}

class _SalesScreenState extends ConsumerState<SalesScreen> {
  CivilDateRange? _selectedRange;
  SalePresentation? _filtroPresentacion;

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(salesProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final filteredSales = state.sales.where((sale) {
      if (_selectedRange != null) {
        final saleCivil = CivilDate.fromDate(sale.creadoEn);
        if (_selectedRange!.end != null) {
          if (!saleCivil.isBetween(_selectedRange!.start, _selectedRange!.end!)) return false;
        } else {
          if (!saleCivil.isSameDay(_selectedRange!.start)) return false;
        }
      }
      if (_filtroPresentacion != null && sale.tipoVenta != _filtroPresentacion) {
        return false;
      }
      return true;
    }).toList();

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      floatingActionButtonLocation: FloatingDockFabLocation.endFloat,
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.greenBiomass,
        elevation: 6,
        icon: const Icon(Icons.add_shopping_cart_rounded, color: Colors.white, size: 20),
        label: const Text(
          'Nueva Venta',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 13),
        ),
        onPressed: () => VentaRapidaModal.show(context),
      ),
      body: CustomScrollView(
        slivers: [
          FishBitHeader(
            onRefresh: () => ref.read(salesProvider.notifier).loadSalesData(),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ─── HERO HEADER: FISHSALES & BRANDING ────────────────────────
                  const FishSalesHeroHeader(),
                  const SizedBox(height: 6),

                  // ─── SCORECARD DE VENTAS & RENDIMIENTO ────────────────────────
                  SalesKpiScorecard(salesState: state),
                  const SizedBox(height: 14),

                  // ─── DASHBOARD DE TENDENCIAS (GRÁFICA FL_CHART) ───────────────
                  if (state.sales.isNotEmpty) ...[
                    SalesTrendsChart(sales: state.sales),
                    const SizedBox(height: 14),
                  ],

                  // ─── FILTRO DE FECHAS & PRESENTACIÓN ──────────────────────────
                  GlassDatePickerField(
                    label: 'FILTRAR POR PERÍODO',
                    mode: DatePickerSelectionMode.range,
                    initialRange: _selectedRange,
                    accentColor: AppColors.greenBiomass,
                    placeholder: 'Todas las fechas (Toca para filtrar)',
                    onRangeChanged: (range) => setState(() => _selectedRange = range),
                  ),
                  const SizedBox(height: 10),

                  // Filtro rápido por presentación (sin emojis)
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _FilterChip(
                          label: 'Todos',
                          isSelected: _filtroPresentacion == null,
                          onTap: () => setState(() => _filtroPresentacion = null),
                        ),
                        const SizedBox(width: 8),
                        _FilterChip(
                          label: 'Vivo',
                          isSelected: _filtroPresentacion == SalePresentation.vivo,
                          onTap: () => setState(() => _filtroPresentacion = SalePresentation.vivo),
                        ),
                        const SizedBox(width: 8),
                        _FilterChip(
                          label: 'Media Tripa',
                          isSelected: _filtroPresentacion == SalePresentation.medioEviscerado,
                          onTap: () => setState(() => _filtroPresentacion = SalePresentation.medioEviscerado),
                        ),
                        const SizedBox(width: 8),
                        _FilterChip(
                          label: 'Eviscerado',
                          isSelected: _filtroPresentacion == SalePresentation.evisceradoCompleto,
                          onTap: () => setState(() => _filtroPresentacion = SalePresentation.evisceradoCompleto),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),


                  // Cabecera Historial
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'REGISTRO DE DESPACHOS (${filteredSales.length})',
                        style: AppTypography.labelMicro.copyWith(
                          color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                          letterSpacing: 1.4,
                        ),
                      ),
                      if (_selectedRange != null || _filtroPresentacion != null)
                        TextButton(
                          onPressed: () => setState(() {
                            _selectedRange = null;
                            _filtroPresentacion = null;
                          }),
                          style: TextButton.styleFrom(padding: EdgeInsets.zero, visualDensity: VisualDensity.compact),
                          child: const Text(
                            'Limpiar filtros',
                            style: TextStyle(color: AppColors.cyanWater, fontSize: 11, fontWeight: FontWeight.bold),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 8),
                ],
              ),
            ),
          ),

          // ─── LISTADO DE VENTAS ─────────────────────────────────────────────
          if (filteredSales.isEmpty)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
                child: Center(
                  child: Column(
                    children: [
                      Icon(Icons.receipt_long_outlined, size: 48, color: AppColors.textSecondaryDark.withValues(alpha: 0.5)),
                      const SizedBox(height: 12),
                      Text(
                        'No hay despachos de venta registrados en este período.',
                        style: AppTypography.bodyMedium.copyWith(
                          color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final sale = filteredSales[index];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: GlassCard(
                        title: sale.clienteNombre,
                        subtitle: '${sale.clienteCedulaNit != null && sale.clienteCedulaNit!.isNotEmpty ? "NIT/CC: ${sale.clienteCedulaNit} • " : ""}${sale.estanqueNombre} • ${sale.creadoEn.day}/${sale.creadoEn.month}/${sale.creadoEn.year}',
                        trailingWidget: GlassBadge(
                          text: CurrencyFormatters.formatCOP(sale.ingresoBruto),
                          color: AppColors.greenBiomass,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    _SaleBadge(tipo: sale.tipoVenta),
                                    const SizedBox(width: 8),
                                    Text(
                                      '${sale.especie} (Lote: ${sale.codigoLote})',
                                      style: TextStyle(
                                        color: isDark ? Colors.white70 : AppColors.textSecondaryLight,
                                        fontSize: 11.5,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                                if (sale.cantidadPeces > 0)
                                  Text(
                                    '${sale.cantidadPeces} peces',
                                    style: TextStyle(
                                      color: isDark ? Colors.white60 : AppColors.textTertiaryLight,
                                      fontSize: 11,
                                    ),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Wrap(
                              spacing: 12,
                              runSpacing: 4,
                              alignment: WrapAlignment.spaceBetween,
                              children: [
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      sale.tipoVenta == SalePresentation.vivo
                                          ? '${sale.pesoVivoKg.toStringAsFixed(1)} kg vivos @ ${CurrencyFormatters.formatCOP(sale.precioUnitarioKg)}/kg'
                                          : '${sale.pesoArregladoKg.toStringAsFixed(1)} kg arreglados (Vivo: ${sale.pesoVivoKg.toStringAsFixed(1)} kg)',
                                      style: AppTypography.bodySmall.copyWith(
                                        color: isDark ? Colors.white : AppColors.textPrimaryLight,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    if (sale.tipoVenta != SalePresentation.vivo && sale.mermaKg > 0)
                                      Text(
                                        'Merma: -${sale.mermaKg.toStringAsFixed(1)} kg (${sale.mermaPct.toStringAsFixed(1)}%)',
                                        style: AppTypography.labelMicro.copyWith(
                                          color: AppColors.amberWarning,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                  ],
                                ),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Text(
                                      'Utilidad: ${CurrencyFormatters.formatCOP(sale.utilidadNeta)}',
                                      style: AppTypography.bodySmall.copyWith(
                                        color: AppColors.purpleAnalytics,
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                    Text(
                                      'Margen: ${sale.margenNetoPct.toStringAsFixed(1)}%',
                                      style: AppTypography.labelMicro.copyWith(
                                        color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
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
                  childCount: filteredSales.length,
                ),
              ),
            ),
          const SliverDockBottomSpacer(),
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.greenBiomass.withValues(alpha: 0.22) : Colors.white.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? AppColors.greenBiomass : Colors.white.withValues(alpha: 0.12),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : AppColors.textSecondaryDark,
            fontSize: 11,
            fontWeight: isSelected ? FontWeight.w800 : FontWeight.w500,
          ),
        ),
      ),
    );
  }
}

class _SaleBadge extends StatelessWidget {
  final SalePresentation tipo;

  const _SaleBadge({required this.tipo});

  @override
  Widget build(BuildContext context) {
    Color bg;
    Color border;
    String text;

    switch (tipo) {
      case SalePresentation.vivo:
        bg = AppColors.cyanWater.withValues(alpha: 0.15);
        border = AppColors.cyanWater.withValues(alpha: 0.4);
        text = 'Vivo';
        break;
      case SalePresentation.medioEviscerado:
        bg = AppColors.amberWarning.withValues(alpha: 0.15);
        border = AppColors.amberWarning.withValues(alpha: 0.4);
        text = 'Media Tripa';
        break;
      case SalePresentation.evisceradoCompleto:
        bg = AppColors.purpleAnalytics.withValues(alpha: 0.15);
        border = AppColors.purpleAnalytics.withValues(alpha: 0.4);
        text = 'Eviscerado';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: border, width: 0.8),
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 9.5,
          fontWeight: FontWeight.w700,
        ),
      ),

    );
  }
}
