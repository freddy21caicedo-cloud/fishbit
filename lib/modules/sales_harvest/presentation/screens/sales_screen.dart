import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fishbit_finance/core/design_system/app_colors.dart';
import 'package:fishbit_finance/core/design_system/app_typography.dart';
import 'package:fishbit_finance/core/design_system/fishbit_header.dart';
import 'package:fishbit_finance/core/design_system/glass_card.dart';
import 'package:fishbit_finance/core/design_system/glass_badge.dart';
import 'package:fishbit_finance/core/design_system/glass_date_picker.dart';
import 'package:fishbit_finance/core/utils/currency_formatters.dart';
import 'package:fishbit_finance/modules/sales_harvest/presentation/dialogs/venta_rapida_modal.dart';
import 'package:fishbit_finance/modules/sales_harvest/presentation/providers/sales_provider.dart';

class SalesScreen extends ConsumerStatefulWidget {
  const SalesScreen({super.key});

  @override
  ConsumerState<SalesScreen> createState() => _SalesScreenState();
}

class _SalesScreenState extends ConsumerState<SalesScreen> {
  CivilDateRange? _selectedRange;

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(salesProvider);

    final filteredSales = state.sales.where((sale) {
      if (_selectedRange == null) return true;
      final saleCivil = CivilDate.fromDate(sale.creadoEn);
      if (_selectedRange!.end != null) {
        return saleCivil.isBetween(_selectedRange!.start, _selectedRange!.end!);
      }
      return saleCivil.isSameDay(_selectedRange!.start);
    }).toList();

    final totalIngresos = filteredSales.fold(0.0, (sum, s) => sum + s.ingresoBruto);
    final totalUtilidad = filteredSales.fold(0.0, (sum, s) => sum + s.utilidadNeta);
    final totalKg = filteredSales.fold(0.0, (sum, s) => sum + s.biomasaVendidaKg);
    final totalCogs = filteredSales.fold(0.0, (sum, s) => sum + s.cogs);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 78),
        child: FloatingActionButton.extended(
          backgroundColor: AppColors.greenBiomass,
          icon: const Icon(Icons.point_of_sale_rounded, color: Colors.white),
          label: const Text('Venta Rápida', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800)),
          onPressed: () => VentaRapidaModal.show(context),
        ),
      ),
      body: CustomScrollView(
        slivers: [
          FishBitHeader(
            onRefresh: () => ref.read(salesProvider.notifier).loadSalesData(),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: GlassCard(
                          title: 'Total Ingresos',
                          glowColor: AppColors.greenBiomass,
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            alignment: Alignment.centerLeft,
                            child: Text(
                              CurrencyFormatters.formatCOP(totalIngresos),
                              style: AppTypography.numberKpi.copyWith(color: AppColors.greenBiomass, fontSize: 18),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: GlassCard(
                          title: 'Utilidad Neta',
                          glowColor: AppColors.purpleAnalytics,
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            alignment: Alignment.centerLeft,
                            child: Text(
                              CurrencyFormatters.formatCOP(totalUtilidad),
                              style: AppTypography.numberKpi.copyWith(color: AppColors.purpleAnalytics, fontSize: 18),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  GlassCard(
                    title: 'Biomasa Cosechada',
                    glowColor: AppColors.cyanWater,
                    child: Wrap(
                      spacing: 12,
                      runSpacing: 4,
                      alignment: WrapAlignment.spaceBetween,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Text(
                          CurrencyFormatters.formatKg(totalKg),
                          style: AppTypography.titleLarge.copyWith(color: AppColors.cyanWater),
                        ),
                        Text(
                          'COGS: ${CurrencyFormatters.formatCOP(totalCogs)}',
                          style: AppTypography.bodySmall.copyWith(color: AppColors.coralAction, fontWeight: FontWeight.w700),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Filtro de Rango de Fechas
                  GlassDatePickerField(
                    label: 'FILTRAR POR PERÍODO',
                    mode: DatePickerSelectionMode.range,
                    initialRange: _selectedRange,
                    accentColor: AppColors.greenBiomass,
                    placeholder: 'Todas las fechas (Toca para filtrar)',
                    onRangeChanged: (range) => setState(() => _selectedRange = range),
                  ),
                  const SizedBox(height: 16),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('HISTORIAL DE VENTAS (${filteredSales.length})', style: AppTypography.labelMicro.copyWith(color: AppColors.textSecondaryDark, letterSpacing: 1.5)),
                      if (_selectedRange != null)
                        TextButton(
                          onPressed: () => setState(() => _selectedRange = null),
                          style: TextButton.styleFrom(padding: EdgeInsets.zero, visualDensity: VisualDensity.compact),
                          child: const Text('Limpiar filtro', style: TextStyle(color: AppColors.cyanWater, fontSize: 11, fontWeight: FontWeight.bold)),
                        ),
                    ],
                  ),
                  const SizedBox(height: 10),
                ],
              ),
            ),
          ),
          if (filteredSales.isEmpty)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Center(
                  child: Text('No hay ventas en el período seleccionado.', style: AppTypography.bodyMedium.copyWith(color: AppColors.textSecondaryDark)),
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
                      padding: const EdgeInsets.only(bottom: 10),
                      child: GlassCard(
                        title: sale.clienteNombre,
                        subtitle: '${sale.especie} • Lote ${sale.codigoLote} • ${sale.creadoEn.day}/${sale.creadoEn.month}/${sale.creadoEn.year}',
                        trailingWidget: GlassBadge(
                          text: CurrencyFormatters.formatCOP(sale.ingresoBruto),
                          color: AppColors.greenBiomass,
                        ),
                        child: Wrap(
                          spacing: 12,
                          runSpacing: 4,
                          alignment: WrapAlignment.spaceBetween,
                          children: [
                            Text('${sale.biomasaVendidaKg} kg @ ${CurrencyFormatters.formatCOP(sale.precioUnitarioKg)}/kg', style: AppTypography.bodySmall),
                            Text(
                              'Utilidad: ${CurrencyFormatters.formatCOP(sale.utilidadNeta)}',
                              style: AppTypography.bodySmall.copyWith(color: AppColors.purpleAnalytics, fontWeight: FontWeight.w700),
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
          const SliverToBoxAdapter(child: SizedBox(height: 100)),
        ],
      ),
    );
  }
}
