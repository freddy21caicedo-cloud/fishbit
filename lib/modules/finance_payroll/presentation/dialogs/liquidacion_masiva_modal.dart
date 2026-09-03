import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import 'package:fishbit_finance/core/design_system/app_colors.dart';
import 'package:fishbit_finance/core/design_system/app_typography.dart';
import 'package:fishbit_finance/core/design_system/glass_container.dart';
import 'package:fishbit_finance/core/design_system/glass_button.dart';
import 'package:fishbit_finance/core/design_system/glass_badge.dart';
import 'package:fishbit_finance/core/design_system/glass_date_picker.dart';
import 'package:fishbit_finance/core/utils/currency_formatters.dart';
import 'package:fishbit_finance/modules/auth_tenant/presentation/providers/auth_provider.dart';
import 'package:fishbit_finance/modules/auth_tenant/domain/models/user_member.dart';
import 'package:fishbit_finance/modules/finance_payroll/domain/models/payroll_record.dart';
import 'package:fishbit_finance/modules/finance_payroll/domain/models/payroll_config.dart';
import 'package:fishbit_finance/modules/finance_payroll/domain/services/payroll_engine.dart';
import 'package:fishbit_finance/modules/finance_payroll/presentation/providers/finance_provider.dart';

/// Modal de Liquidación Masiva de Nómina / Planilla con 1 solo clic
class LiquidacionMasivaModal extends ConsumerStatefulWidget {
  const LiquidacionMasivaModal({super.key});

  static Future<void> show(BuildContext context) {
    return showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => const LiquidacionMasivaModal(),
    );
  }

  @override
  ConsumerState<LiquidacionMasivaModal> createState() => _LiquidacionMasivaModalState();
}

class _LiquidacionMasivaModalState extends ConsumerState<LiquidacionMasivaModal> {
  final Set<String> _selectedMemberIds = {};
  CivilDate _fechaPago = CivilDate.today();
  String _periodo = 'Quincenal';
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    // Seleccionar a todos por defecto
    final team = ref.read(authProvider).teamMembers;
    _selectedMemberIds.addAll(team.map((m) => m.id));
  }

  @override
  Widget build(BuildContext context) {
    final team = ref.watch(authProvider).teamMembers;
    final config = ref.watch(financeProvider).payrollConfig;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Calcular liquidación para cada miembro seleccionado
    final preCalculos = <UserMember, PayrollCalculationResult>{};
    double totalNetoPagar = 0.0;
    double totalCostoEmpresa = 0.0;

    for (final member in team) {
      if (_selectedMemberIds.contains(member.id)) {
        final salarioBase = member.salarioBase > 0
            ? (_periodo == 'Quincenal' ? member.salarioBase / 2 : member.salarioBase)
            : (_periodo == 'Quincenal' ? 700000.0 : 1400000.0);

        final auxilio = _periodo == 'Quincenal'
            ? (config.auxilioTransporteMensual / 2)
            : config.auxilioTransporteMensual;

        final arl = (member.isTechnician || member.isOperator)
            ? ArlRiskClass.claseIII
            : ArlRiskClass.claseI;

        final calc = PayrollEngine.calculate(
          salarioBase: salarioBase,
          auxilioTransporte: auxilio,
          config: config,
          arlClass: arl,
          periodo: _periodo,
        );

        preCalculos[member] = calc;
        totalNetoPagar += calc.netoPagarTrabajador;
        totalCostoEmpresa += calc.costoTotalEmpresa;
      }
    }

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 580),
        child: GlassContainer(
          borderRadius: 24,
          padding: const EdgeInsets.all(22),
          blur: 24,
          opacity: 0.16,
          borderColor: AppColors.purpleAnalytics.withValues(alpha: 0.35),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Cabecera
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppColors.purpleAnalytics.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(Icons.groups_rounded, color: AppColors.purpleAnalytics, size: 22),
                        ),
                        const SizedBox(width: 10),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('PLANILLA MASIVA', style: AppTypography.labelMicro.copyWith(color: AppColors.purpleAnalytics, letterSpacing: 1.2)),
                            Text('Liquidación Masiva de Equipo', style: AppTypography.titleOf(context, fontWeight: FontWeight.w800, fontSize: 16)),
                          ],
                        ),
                      ],
                    ),
                    IconButton(
                      icon: Icon(Icons.close_rounded, color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                // Parámetros de Periodo y Fecha
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                        decoration: BoxDecoration(
                          color: isDark ? Colors.white.withValues(alpha: 0.06) : Colors.white,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: isDark ? Colors.white.withValues(alpha: 0.12) : AppColors.glassBorderLight),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: _periodo,
                            dropdownColor: isDark ? AppColors.surfaceDark : Colors.white,
                            isExpanded: true,
                            items: [
                              DropdownMenuItem(value: 'Quincenal', child: Text('Quincenal', style: TextStyle(color: isDark ? Colors.white : AppColors.textPrimaryLight, fontSize: 13))),
                              DropdownMenuItem(value: 'Mensual', child: Text('Mensual', style: TextStyle(color: isDark ? Colors.white : AppColors.textPrimaryLight, fontSize: 13))),
                            ],
                            onChanged: (val) {
                              if (val != null) setState(() => _periodo = val);
                            },
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: GlassDatePickerField(
                        label: 'FECHA DE PAGO',
                        accentColor: AppColors.purpleAnalytics,
                        initialDate: _fechaPago,
                        onDateChanged: (d) => setState(() => _fechaPago = d),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                // Lista de Colaboradores con Checkbox
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('COLABORADORES (${_selectedMemberIds.length}/${team.length})', style: AppTypography.labelMicro.copyWith(color: AppColors.cyanWater, letterSpacing: 1.1)),
                    InkWell(
                      onTap: () {
                        setState(() {
                          if (_selectedMemberIds.length == team.length) {
                            _selectedMemberIds.clear();
                          } else {
                            _selectedMemberIds.addAll(team.map((m) => m.id));
                          }
                        });
                      },
                      child: Text(
                        _selectedMemberIds.length == team.length ? 'Desmarcar todos' : 'Marcar todos',
                        style: const TextStyle(color: AppColors.purpleAnalytics, fontSize: 11, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                if (team.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 20),
                    child: Center(
                      child: Text('No hay colaboradores registrados en el equipo.', style: AppTypography.bodyOf(context)),
                    ),
                  )
                else
                  ...team.map((member) {
                    final isSelected = _selectedMemberIds.contains(member.id);
                    final calc = preCalculos[member];

                    return Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? (isDark ? Colors.white.withValues(alpha: 0.08) : Colors.white)
                            : (isDark ? Colors.white.withValues(alpha: 0.02) : Colors.black.withValues(alpha: 0.02)),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: isSelected
                              ? AppColors.purpleAnalytics.withValues(alpha: 0.4)
                              : (isDark ? Colors.white10 : AppColors.glassBorderLight),
                        ),
                      ),
                      child: Row(
                        children: [
                          Checkbox(
                            value: isSelected,
                            activeColor: AppColors.purpleAnalytics,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                            onChanged: (val) {
                              setState(() {
                                if (val == true) {
                                  _selectedMemberIds.add(member.id);
                                } else {
                                  _selectedMemberIds.remove(member.id);
                                }
                              });
                            },
                          ),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Text(
                                      member.nombre,
                                      style: TextStyle(
                                        color: isDark ? Colors.white : AppColors.textPrimaryLight,
                                        fontWeight: FontWeight.w800,
                                        fontSize: 13,
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                    GlassBadge(
                                      text: member.roleDisplayName,
                                      color: member.isTechnician ? AppColors.cyanWater : AppColors.purpleAnalytics,
                                    ),
                                  ],
                                ),
                                if (calc != null) ...[
                                  const SizedBox(height: 2),
                                  Text(
                                    'Neto: ${CurrencyFormatters.formatCOP(calc.netoPagarTrabajador)} • Costo Empresa: ${CurrencyFormatters.formatCOP(calc.costoTotalEmpresa)}',
                                    style: TextStyle(
                                      color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                                      fontSize: 11,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
                const SizedBox(height: 14),

                // Resumen Consolidado de la Planilla
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.purpleAnalytics.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.purpleAnalytics.withValues(alpha: 0.4)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('TOTAL DISPERSAR (NETO)', style: AppTypography.labelMicro.copyWith(color: AppColors.cyanWater)),
                          const SizedBox(height: 2),
                          Text(
                            CurrencyFormatters.formatCOP(totalNetoPagar),
                            style: const TextStyle(color: AppColors.cyanWater, fontWeight: FontWeight.w900, fontSize: 16),
                          ),
                        ],
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text('COSTO TOTAL OPEX', style: AppTypography.labelMicro.copyWith(color: AppColors.purpleAnalytics)),
                          const SizedBox(height: 2),
                          Text(
                            CurrencyFormatters.formatCOP(totalCostoEmpresa),
                            style: const TextStyle(color: AppColors.purpleAnalytics, fontWeight: FontWeight.w900, fontSize: 16),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),

                // Botón de Asentamiento Masivo
                GlassButton(
                  label: _isLoading ? 'Asentando Planilla...' : '✨ Liquidar ${_selectedMemberIds.length} Colaboradores',
                  isLoading: _isLoading,
                  backgroundColor: AppColors.purpleAnalytics,
                  onPressed: (_isLoading || _selectedMemberIds.isEmpty)
                      ? null
                      : () async {
                          setState(() => _isLoading = true);

                          final nav = Navigator.of(context);
                          final messenger = ScaffoldMessenger.of(context);
                          final auth = ref.read(authProvider);
                          final empresaId = auth.currentUser?.empresaId ?? 'c1000000-0000-0000-0000-000000000001';
                          final unidadId = auth.activeUnitId ?? 'u1000000-0000-0000-0000-000000000001';

                          final records = <PayrollRecord>[];
                          for (final entry in preCalculos.entries) {
                            records.add(
                              PayrollEngine.createRecord(
                                id: const Uuid().v4(),
                                empresaId: empresaId,
                                unidadAcuicolaId: unidadId,
                                empleadoId: entry.key.id,
                                empleadoNombre: '${entry.key.nombre} (${entry.key.roleDisplayName})',
                                periodo: _periodo,
                                fechaPago: _fechaPago.toDateTime(),
                                calc: entry.value,
                              ),
                            );
                          }

                          for (final record in records) {
                            await ref.read(financeProvider.notifier).addPayrollRecord(record);
                          }

                          if (mounted) {
                            setState(() => _isLoading = false);
                            nav.pop();
                            messenger.showSnackBar(
                              SnackBar(
                                content: Text('¡Planilla de ${records.length} colaboradores liquidada con éxito!'),
                                backgroundColor: AppColors.purpleAnalytics,
                              ),
                            );
                          }
                        },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
