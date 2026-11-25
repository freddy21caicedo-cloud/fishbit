import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import 'package:fishbit_finance/core/design_system/app_colors.dart';
import 'package:fishbit_finance/core/design_system/app_typography.dart';
import 'package:fishbit_finance/core/design_system/glass_container.dart';
import 'package:fishbit_finance/core/design_system/glass_button.dart';
import 'package:fishbit_finance/core/design_system/glass_date_picker.dart';
import 'package:fishbit_finance/core/design_system/glass_form_field.dart';
import 'package:fishbit_finance/core/utils/currency_formatters.dart';
import 'package:fishbit_finance/modules/auth_tenant/domain/models/user_member.dart';
import 'package:fishbit_finance/modules/auth_tenant/presentation/providers/auth_provider.dart';
import 'package:fishbit_finance/modules/finance_payroll/domain/models/payroll_config.dart';
import 'package:fishbit_finance/modules/finance_payroll/domain/models/payroll_record.dart';
import 'package:fishbit_finance/modules/finance_payroll/domain/services/payroll_engine.dart';
import 'package:fishbit_finance/modules/finance_payroll/presentation/providers/finance_provider.dart';

/// Modal de Registro de Nómina Mensual del Equipo Completo.
/// Arrastra automáticamente al equipo de la empresa, permite editar el valor mensual
/// de cada colaborador, incluye un interruptor referencial opcional de ARL/prestaciones
/// y aplica el costo como impacto general prorrateado por % de biomasa.
class RegistroNominaEquipoModal extends ConsumerStatefulWidget {
  const RegistroNominaEquipoModal({super.key});

  static Future<void> show(BuildContext context) {
    return showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (_) => const RegistroNominaEquipoModal(),
    );
  }

  @override
  ConsumerState<RegistroNominaEquipoModal> createState() =>
      _RegistroNominaEquipoModalState();
}

class _RegistroNominaEquipoModalState
    extends ConsumerState<RegistroNominaEquipoModal> {
  final Set<String> _selectedMemberIds = {};
  final Map<String, TextEditingController> _salaryControllers = {};
  final TextEditingController _generalAmountCtrl = TextEditingController();
  CivilDate _fechaPago = CivilDate.today();
  bool _incluirProyeccionArl = false;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final team = ref.read(authProvider).teamMembers;
    for (final m in team) {
      _selectedMemberIds.add(m.id);
      _salaryControllers[m.id] = TextEditingController(
        text: m.salarioBase > 0 ? CurrencyFormatters.formatCOP(m.salarioBase) : '',
      );
    }
  }

  @override
  void dispose() {
    for (final c in _salaryControllers.values) {
      c.dispose();
    }
    _generalAmountCtrl.dispose();
    super.dispose();
  }

  TextEditingController _controllerFor(UserMember member) {
    return _salaryControllers.putIfAbsent(
      member.id,
      () => TextEditingController(
        text: member.salarioBase > 0
            ? CurrencyFormatters.formatCOP(member.salarioBase)
            : '',
      ),
    );
  }

  double _salaryFor(UserMember member) {
    final raw = _controllerFor(member).text;
    final parsed = CurrencyFormatters.parseCOP(raw);
    return parsed > 0 ? parsed : 0.0;
  }

  @override
  Widget build(BuildContext context) {
    final team = ref.watch(authProvider).teamMembers;
    final config = ref.watch(financeProvider).payrollConfig;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    double totalSalariosMensuales = 0.0;
    double totalArlYPrestaciones = 0.0;
    double totalCostoEmpresa = 0.0;

    final Map<String, PayrollCalculationResult> proyecciones = {};

    if (team.isNotEmpty) {
      for (final member in team) {
        if (!_selectedMemberIds.contains(member.id)) continue;
        final sal = _salaryFor(member);
        totalSalariosMensuales += sal;
        if (_incluirProyeccionArl && sal > 0) {
          final arl = (member.isTechnician || member.isOperator)
              ? ArlRiskClass.claseIII
              : ArlRiskClass.claseI;
          final calc = PayrollEngine.calculate(
            salarioBase: sal,
            auxilioTransporte: config.auxilioTransporteMensual,
            config: config,
            arlClass: arl,
            periodo: 'Mensual',
          );
          proyecciones[member.id] = calc;
          totalArlYPrestaciones +=
              calc.totalSeguridadSocialPatronal + calc.totalProvisiones + calc.auxilioTransporte;
          totalCostoEmpresa += calc.costoTotalEmpresa;
        } else {
          totalCostoEmpresa += sal;
        }
      }
    } else {
      final generalVal = CurrencyFormatters.parseCOP(_generalAmountCtrl.text);
      totalSalariosMensuales = generalVal > 0 ? generalVal : 0.0;
      if (_incluirProyeccionArl && totalSalariosMensuales > 0) {
        final calc = PayrollEngine.calculate(
          salarioBase: totalSalariosMensuales,
          auxilioTransporte: 0,
          config: config,
          arlClass: config.arlDefault,
          periodo: 'Mensual',
        );
        totalArlYPrestaciones =
            calc.totalSeguridadSocialPatronal + calc.totalProvisiones;
        totalCostoEmpresa = calc.costoTotalEmpresa;
      } else {
        totalCostoEmpresa = totalSalariosMensuales;
      }
    }

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 560),
        child: GlassContainer(
          borderRadius: 24,
          padding: const EdgeInsets.all(22),
          blur: 24,
          opacity: isDark ? 0.16 : 0.92,
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
                          child: const Icon(
                            Icons.groups_rounded,
                            color: AppColors.purpleAnalytics,
                            size: 22,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'NÓMINA MENSUAL DEL EQUIPO',
                              style: AppTypography.labelMicro.copyWith(
                                color: AppColors.purpleAnalytics,
                                letterSpacing: 1.1,
                              ),
                            ),
                            Text(
                              'Registro de Nómina',
                              style: AppTypography.titleOf(
                                context,
                                fontWeight: FontWeight.w800,
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
                        color: isDark
                            ? AppColors.textSecondaryDark
                            : AppColors.textSecondaryLight,
                      ),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Aviso de prorrateo por % de biomasa
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
                  decoration: BoxDecoration(
                    color: AppColors.cyanWater.withValues(alpha: 0.10),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: AppColors.cyanWater.withValues(alpha: 0.28),
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.pie_chart_outline_rounded,
                        size: 16,
                        color: AppColors.cyanWater,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Impacto general: el costo de nómina se prorratea automáticamente entre todos los estanques activos según su % de biomasa.',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: isDark ? Colors.white70 : AppColors.textSecondaryLight,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),

                // Fecha de pago
                GlassDatePickerField(
                  label: 'FECHA DE PAGO (MES CORRESPONDIENTE)',
                  accentColor: AppColors.purpleAnalytics,
                  initialDate: _fechaPago,
                  onDateChanged: (d) => setState(() => _fechaPago = d),
                ),
                const SizedBox(height: 14),

                // Equipo completo o valor consolidado
                if (team.isNotEmpty) ...[
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'EQUIPO COMPLETO (${_selectedMemberIds.length}/${team.length})',
                        style: AppTypography.labelMicro.copyWith(
                          color: AppColors.cyanWater,
                          letterSpacing: 1.0,
                        ),
                      ),
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
                          _selectedMemberIds.length == team.length
                              ? 'Desmarcar todos'
                              : 'Marcar todos',
                          style: const TextStyle(
                            color: AppColors.purpleAnalytics,
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ...team.map((member) {
                    final isSelected = _selectedMemberIds.contains(member.id);
                    final ctrl = _controllerFor(member);
                    final calc = proyecciones[member.id];

                    return Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? (isDark
                                ? Colors.white.withValues(alpha: 0.06)
                                : Colors.white)
                            : (isDark
                                ? Colors.white.withValues(alpha: 0.02)
                                : Colors.black.withValues(alpha: 0.02)),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: isSelected
                              ? AppColors.purpleAnalytics.withValues(alpha: 0.35)
                              : (isDark ? Colors.white10 : AppColors.glassBorderLight),
                        ),
                      ),
                      child: Row(
                        children: [
                          Checkbox(
                            value: isSelected,
                            activeColor: AppColors.purpleAnalytics,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(4),
                            ),
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
                                Text(
                                  member.nombre,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    color: isDark
                                        ? Colors.white
                                        : AppColors.textPrimaryLight,
                                    fontWeight: FontWeight.w800,
                                    fontSize: 13,
                                  ),
                                ),
                                Text(
                                  member.role.roleDisplayName,
                                  style: TextStyle(
                                    fontSize: 10.5,
                                    color: isDark
                                        ? AppColors.textSecondaryDark
                                        : AppColors.textSecondaryLight,
                                  ),
                                ),
                                if (calc != null)
                                  Text(
                                    'Proyección empresa: ${CurrencyFormatters.formatCOP(calc.costoTotalEmpresa)}',
                                    style: const TextStyle(
                                      fontSize: 10.5,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.amberWarning,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          SizedBox(
                            width: 142,
                            child: TextField(
                              controller: ctrl,
                              enabled: isSelected,
                              keyboardType: TextInputType.number,
                              inputFormatters: [CurrencyInputFormatter()],
                              onChanged: (_) => setState(() {}),
                              style: TextStyle(
                                color: isDark
                                    ? Colors.white
                                    : AppColors.textPrimaryLight,
                                fontWeight: FontWeight.w800,
                                fontSize: 12.5,
                              ),
                              decoration: InputDecoration(
                                hintText: '\$ Mensual',
                                isDense: true,
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 10,
                                ),
                                filled: true,
                                fillColor: isDark
                                    ? Colors.white.withValues(alpha: 0.05)
                                    : Colors.black.withValues(alpha: 0.03),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10),
                                  borderSide: BorderSide(
                                    color: AppColors.purpleAnalytics
                                        .withValues(alpha: 0.3),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
                ] else ...[
                  GlassFormField(
                    label: 'VALOR MENSUAL DE NÓMINA (\$ COP)',
                    controller: _generalAmountCtrl,
                    keyboardType: TextInputType.number,
                    inputFormatters: [CurrencyInputFormatter()],
                    prefixIcon: Icons.payments_outlined,
                    accentColor: AppColors.purpleAnalytics,
                    onChanged: (_) => setState(() {}),
                  ),
                ],
                const SizedBox(height: 12),

                // Interruptor opcional de proyección ARL y Prestaciones
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.04)
                        : Colors.black.withValues(alpha: 0.03),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: isDark ? Colors.white10 : AppColors.glassBorderLight,
                    ),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Proyección de ARL y prestaciones (referencial)',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: isDark
                                    ? Colors.white
                                    : AppColors.textPrimaryLight,
                              ),
                            ),
                            Text(
                              'Opcional mientras defines tu fórmula definitiva de ARL y prestaciones',
                              style: TextStyle(
                                fontSize: 10.5,
                                color: isDark
                                    ? AppColors.textSecondaryDark
                                    : AppColors.textSecondaryLight,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Switch(
                        value: _incluirProyeccionArl,
                        activeThumbColor: AppColors.purpleAnalytics,
                        onChanged: (val) =>
                            setState(() => _incluirProyeccionArl = val),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),

                // Resumen Total
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.purpleAnalytics.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: AppColors.purpleAnalytics.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Nómina Mensual Base:',
                            style: TextStyle(
                              fontSize: 12,
                              color: isDark ? Colors.white70 : Colors.black87,
                            ),
                          ),
                          Text(
                            CurrencyFormatters.formatCOP(totalSalariosMensuales),
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w800,
                              color: isDark
                                  ? Colors.white
                                  : AppColors.textPrimaryLight,
                            ),
                          ),
                        ],
                      ),
                      if (_incluirProyeccionArl) ...[
                        const SizedBox(height: 4),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Proyección ARL y Prestaciones:',
                              style: TextStyle(
                                fontSize: 11.5,
                                color: isDark ? Colors.white60 : Colors.black54,
                              ),
                            ),
                            Text(
                              '+ ${CurrencyFormatters.formatCOP(totalArlYPrestaciones)}',
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: AppColors.amberWarning,
                              ),
                            ),
                          ],
                        ),
                      ],
                      const Divider(height: 14),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'TOTAL A REGISTRAR:',
                            style: TextStyle(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w900,
                              color: isDark
                                  ? Colors.white
                                  : AppColors.textPrimaryLight,
                            ),
                          ),
                          Text(
                            CurrencyFormatters.formatCOP(totalCostoEmpresa),
                            style: const TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w900,
                              color: AppColors.purpleAnalytics,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                GlassButton(
                  label: 'Registrar Nómina Mensual',
                  isLoading: _isSaving,
                  backgroundColor: AppColors.purpleAnalytics,
                  onPressed: totalCostoEmpresa <= 0
                      ? null
                      : () async {
                          final auth = ref.read(authProvider);
                          final empresaId = auth.currentCompany?.id ??
                              auth.currentUser?.empresaId ??
                              '';
                          final unitId = auth.activeUnitId ?? '';
                          if (empresaId.isEmpty || unitId.isEmpty) return;

                          final messenger = ScaffoldMessenger.of(context);
                          final navigator = Navigator.of(context);
                          setState(() => _isSaving = true);
                          try {
                            final notifier = ref.read(financeProvider.notifier);
                            final fechaPago = _fechaPago.toDateTime();
                            int count = 0;

                            if (team.isNotEmpty) {
                              for (final member in team) {
                                if (!_selectedMemberIds.contains(member.id)) {
                                  continue;
                                }
                                final sal = _salaryFor(member);
                                if (sal <= 0) continue;

                                final calc = proyecciones[member.id];
                                final record = calc != null
                                    ? PayrollEngine.createRecord(
                                        id: const Uuid().v4(),
                                        empresaId: empresaId,
                                        unidadAcuicolaId: unitId,
                                        empleadoId: member.id,
                                        empleadoNombre: member.nombre,
                                        periodo: 'Mensual',
                                        fechaPago: fechaPago,
                                        calc: calc,
                                      )
                                    : PayrollRecord(
                                        id: const Uuid().v4(),
                                        empresaId: empresaId,
                                        unidadAcuicolaId: unitId,
                                        empleadoId: member.id,
                                        empleadoNombre: member.nombre,
                                        periodo: 'Mensual',
                                        salarioBase: sal,
                                        costoTotalEmpresa: sal,
                                        fechaPago: fechaPago,
                                        estado: 'Pagado',
                                        creadoEn: DateTime.now(),
                                      );
                                await notifier.addPayroll(record);
                                count++;
                              }
                            } else {
                              final record = PayrollRecord(
                                id: const Uuid().v4(),
                                empresaId: empresaId,
                                unidadAcuicolaId: unitId,
                                empleadoId: 'emp-general',
                                empleadoNombre: 'Nómina Mensual General',
                                periodo: 'Mensual',
                                salarioBase: totalSalariosMensuales,
                                costoTotalEmpresa: totalCostoEmpresa,
                                fechaPago: fechaPago,
                                estado: 'Pagado',
                                creadoEn: DateTime.now(),
                              );
                              await notifier.addPayroll(record);
                              count = 1;
                            }

                            if (!mounted) return;
                            navigator.pop();
                            messenger.showSnackBar(
                              SnackBar(
                                content: Text(
                                  count == 1
                                      ? 'Nómina mensual registrada con éxito'
                                      : 'Nómina mensual registrada para $count colaboradores',
                                ),
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
                            if (mounted) setState(() => _isSaving = false);
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
