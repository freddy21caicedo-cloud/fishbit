import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fishbit_finance/core/design_system/app_colors.dart';
import 'package:fishbit_finance/core/design_system/app_typography.dart';
import 'package:fishbit_finance/core/design_system/fishbit_header.dart';
import 'package:fishbit_finance/core/design_system/glass_card.dart';
import 'package:fishbit_finance/core/design_system/glass_badge.dart';
import 'package:fishbit_finance/core/design_system/glass_date_picker.dart';
import 'package:fishbit_finance/core/utils/currency_formatters.dart';
import 'package:fishbit_finance/modules/finance_payroll/presentation/dialogs/registro_nomina_modal.dart';
import 'package:fishbit_finance/modules/finance_payroll/presentation/dialogs/liquidacion_masiva_modal.dart';
import 'package:fishbit_finance/modules/finance_payroll/presentation/dialogs/colilla_nomina_modal.dart';
import 'package:fishbit_finance/modules/finance_payroll/presentation/dialogs/registro_jornal_modal.dart';
import 'package:fishbit_finance/modules/finance_payroll/presentation/dialogs/configuracion_nomina_modal.dart';
import 'package:fishbit_finance/modules/finance_payroll/presentation/widgets/cpk_breakdown_card.dart';
import 'package:fishbit_finance/modules/finance_payroll/presentation/providers/finance_provider.dart';
import 'package:fishbit_finance/modules/equipment_capex/presentation/providers/equipment_provider.dart';
import 'package:fishbit_finance/modules/ponds_batches/presentation/providers/ponds_provider.dart';

class FinanceScreen extends ConsumerStatefulWidget {
  const FinanceScreen({super.key});

  @override
  ConsumerState<FinanceScreen> createState() => _FinanceScreenState();
}

class _FinanceScreenState extends ConsumerState<FinanceScreen> {
  CivilDateRange? _selectedRange;

  @override
  Widget build(BuildContext context) {
    final financeState = ref.watch(financeProvider);
    final equipmentState = ref.watch(equipmentProvider);
    final pondMap = {for (final p in ref.watch(pondsProvider).ponds) p.id: p};

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
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 78),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final screenWidth = MediaQuery.sizeOf(context).width;
            if (screenWidth < 440) {
              return FloatingActionButton.extended(
                heroTag: 'fab_finance_hub',
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
      ),
      body: CustomScrollView(
        slivers: [
          FishBitHeader(
            onRefresh: () {
              ref.read(financeProvider.notifier).loadFinanceData();
              ref.read(equipmentProvider.notifier).loadEquipment();
            },
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 1. Radiografía Insignia de Unit Economics & CPK
                  const CpkBreakdownCard(),
                  const SizedBox(height: 16),

                  // 2. Resumen OPEX & Botón de Configuración ARL
                  GlassCard(
                    title: 'OPEX MENSUAL ACUMULADO',
                    glowColor: AppColors.coralAction,
                    trailingWidget: InkWell(
                      onTap: () => ConfiguracionNominaModal.show(context),
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.purpleAnalytics.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: AppColors.purpleAnalytics.withValues(alpha: 0.3)),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.tune_rounded, size: 12, color: AppColors.purpleAnalytics),
                            SizedBox(width: 4),
                            Text('Ajustes ARL', style: TextStyle(color: AppColors.purpleAnalytics, fontSize: 10.5, fontWeight: FontWeight.w800)),
                          ],
                        ),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.centerLeft,
                          child: Text(
                            CurrencyFormatters.formatCOP(financeState.totalOpex),
                            style: AppTypography.displayLarge.copyWith(fontSize: 28, color: AppColors.coralAction, fontWeight: FontWeight.w900),
                          ),
                        ),
                        const SizedBox(height: 10),
                        Wrap(
                          spacing: 12,
                          runSpacing: 4,
                          alignment: WrapAlignment.spaceBetween,
                          children: [
                            Text('Nómina Fija: ${CurrencyFormatters.formatCOP(financeState.totalCostoNomina)}', style: AppTypography.bodyOf(context)),
                            Text('Jornales: ${CurrencyFormatters.formatCOP(financeState.totalCostoJornales)}', style: AppTypography.bodyOf(context).copyWith(color: AppColors.amberWarning, fontWeight: FontWeight.w700)),
                            Text('Energía: ${CurrencyFormatters.formatCOP(financeState.totalCostoEnergia)}', style: AppTypography.bodyOf(context)),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // 3. Activos CAPEX & Depreciación
                  Row(
                    children: [
                      Expanded(
                        child: GlassCard(
                          title: 'Activos CAPEX',
                          glowColor: AppColors.purpleAnalytics,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              FittedBox(
                                fit: BoxFit.scaleDown,
                                alignment: Alignment.centerLeft,
                                child: Text(
                                  CurrencyFormatters.formatCOP(equipmentState.valorTotalActivos),
                                  style: AppTypography.numberKpi.copyWith(color: AppColors.purpleAnalytics, fontSize: 16),
                                ),
                              ),
                              Text('Maquinaria y Equipos', style: AppTypography.bodyOf(context, fontSize: 11)),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: GlassCard(
                          title: 'Depreciación Diaria',
                          glowColor: AppColors.amberWarning,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              FittedBox(
                                fit: BoxFit.scaleDown,
                                alignment: Alignment.centerLeft,
                                child: Text(
                                  CurrencyFormatters.formatCOP(equipmentState.depreciacionDiariaTotal),
                                  style: AppTypography.numberKpi.copyWith(color: AppColors.amberWarning, fontSize: 16),
                                ),
                              ),
                              Text('Amortización Activos', style: AppTypography.bodyOf(context, fontSize: 11)),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Selector de Rango de Fechas
                  GlassDatePickerField(
                    label: 'FILTRAR POR PERÍODO',
                    mode: DatePickerSelectionMode.range,
                    initialRange: _selectedRange,
                    accentColor: AppColors.purpleAnalytics,
                    placeholder: 'Todos los períodos (Toca para filtrar)',
                    onRangeChanged: (range) => setState(() => _selectedRange = range),
                  ),
                  const SizedBox(height: 16),

                  // 4. Encabezado de Nómina & Jornales
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('HISTORIAL DE NÓMINA Y JORNALES', style: AppTypography.labelMicro.copyWith(color: Theme.of(context).brightness == Brightness.dark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight, letterSpacing: 1.5)),
                      Row(
                        children: [
                          Text('${filteredPayroll.length + filteredJornales.length} registros', style: const TextStyle(color: AppColors.cyanWater, fontSize: 11, fontWeight: FontWeight.w700)),
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
                  const SizedBox(height: 10),
                ],
              ),
            ),
          ),

          // Lista de Jornales Ocasionales
          if (filteredJornales.isNotEmpty) ...[
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final j = filteredJornales[index];
                    final estanqueAsignado = j.estanqueId != null ? pondMap[j.estanqueId] : null;
                    final isDark = Theme.of(context).brightness == Brightness.dark;
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
                                text: '🐟 ${estanqueAsignado.nombreLimpio}',
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
                  childCount: filteredJornales.length,
                ),
              ),
            ),
          ],

          // Lista de Nómina Fija
          if (filteredPayroll.isEmpty && filteredJornales.isEmpty)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Center(
                  child: Text('No hay registros de nómina o jornales emitidos en este período.', style: AppTypography.bodyOf(context, fontSize: 13)),
                ),
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final rec = filteredPayroll[index];
                    final isDark = Theme.of(context).brightness == Brightness.dark;
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
                  childCount: filteredPayroll.length,
                ),
              ),
            ),
          const SliverToBoxAdapter(child: SizedBox(height: 100)),
        ],
      ),
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

