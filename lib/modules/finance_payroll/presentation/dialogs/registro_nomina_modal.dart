import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import 'package:fishbit_finance/core/design_system/app_colors.dart';
import 'package:fishbit_finance/core/design_system/app_typography.dart';
import 'package:fishbit_finance/core/design_system/glass_container.dart';
import 'package:fishbit_finance/core/design_system/glass_form_field.dart';
import 'package:fishbit_finance/core/design_system/glass_button.dart';
import 'package:fishbit_finance/core/design_system/glass_date_picker.dart';
import 'package:fishbit_finance/core/utils/currency_formatters.dart';
import 'package:fishbit_finance/modules/auth_tenant/presentation/providers/auth_provider.dart';
import 'package:fishbit_finance/modules/auth_tenant/domain/models/user_member.dart';
import 'package:fishbit_finance/modules/finance_payroll/domain/models/payroll_config.dart';
import 'package:fishbit_finance/modules/finance_payroll/presentation/providers/finance_provider.dart';
import 'package:fishbit_finance/modules/finance_payroll/presentation/dialogs/configuracion_nomina_modal.dart';

import 'package:fishbit_finance/modules/finance_payroll/domain/services/payroll_engine.dart';

class RegistroNominaModal extends ConsumerStatefulWidget {
  const RegistroNominaModal({super.key});

  static Future<void> show(BuildContext context) {
    return showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => const RegistroNominaModal(),
    );
  }

  @override
  ConsumerState<RegistroNominaModal> createState() => _RegistroNominaModalState();
}

class _RegistroNominaModalState extends ConsumerState<RegistroNominaModal> {
  final _formKey = GlobalKey<FormState>();
  UserMember? _colaboradorSeleccionado;
  final _nombreManualCtrl = TextEditingController();
  final _salarioCtrl = TextEditingController();
  late TextEditingController _auxilioCtrl;
  final _recargosCtrl = TextEditingController(text: '0');
  late ArlRiskClass _arlEmpleado;
  CivilDate _fechaPago = CivilDate.today();
  String _periodo = 'Quincenal';
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    final config = ref.read(financeProvider).payrollConfig;
    _arlEmpleado = config.arlDefault;
    _auxilioCtrl = TextEditingController(text: (config.auxilioTransporteMensual / 2).toInt().toString());
  }

  @override
  void dispose() {
    _nombreManualCtrl.dispose();
    _salarioCtrl.dispose();
    _auxilioCtrl.dispose();
    _recargosCtrl.dispose();
    super.dispose();
  }

  double get _salario => double.tryParse(_salarioCtrl.text) ?? 0.0;
  double get _auxilio => double.tryParse(_auxilioCtrl.text) ?? 0.0;
  double get _recargos => double.tryParse(_recargosCtrl.text) ?? 0.0;

  PayrollCalculationResult _getCalculation(PayrollConfig config) {
    return PayrollEngine.calculate(
      salarioBase: _salario,
      auxilioTransporte: _auxilio,
      recargosExtras: _recargos,
      config: config,
      arlClass: _arlEmpleado,
      periodo: _periodo,
    );
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final financeConfig = ref.watch(financeProvider).payrollConfig;
    final team = authState.teamMembers;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final calc = _getCalculation(financeConfig);

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 540),
        child: GlassContainer(
          borderRadius: 24,
          padding: const EdgeInsets.all(22),
          blur: 24,
          opacity: 0.16,
          borderColor: AppColors.purpleAnalytics.withValues(alpha: 0.35),
          child: Form(
            key: _formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 1. Encabezado con Quick Config
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
                            child: const Icon(Icons.receipt_long_rounded, color: AppColors.purpleAnalytics, size: 20),
                          ),
                          const SizedBox(width: 10),
                          Text('Liquidación de Nómina', style: AppTypography.titleOf(context, fontWeight: FontWeight.w800)),
                        ],
                      ),
                      IconButton(
                        icon: const Icon(Icons.tune_rounded, color: AppColors.purpleAnalytics, size: 20),
                        tooltip: 'Configuración ARL y Ley 1607',
                        onPressed: () => ConfiguracionNominaModal.show(context),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),

                  // 2. Bloque: Selección de Colaborador (Zero-Typing)
                  Text('1. COLABORADOR A LIQUIDAR', style: AppTypography.labelMicro.copyWith(color: AppColors.cyanWater, fontWeight: FontWeight.w800, letterSpacing: 1.1)),
                  const SizedBox(height: 6),
                  if (team.isNotEmpty) ...[
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        color: isDark ? Colors.white.withValues(alpha: 0.06) : Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: isDark ? Colors.white.withValues(alpha: 0.12) : AppColors.glassBorderLight),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<UserMember?>(
                          value: _colaboradorSeleccionado,
                          dropdownColor: isDark ? AppColors.surfaceDark : Colors.white,
                          isExpanded: true,
                          hint: Text('👤 Seleccionar colaborador registrado...', style: TextStyle(color: isDark ? Colors.white70 : AppColors.textSecondaryLight, fontSize: 13)),
                          items: [
                            DropdownMenuItem<UserMember?>(
                              value: null,
                              child: Text('👤 Ingreso manual de colaborador...', style: TextStyle(color: isDark ? Colors.white70 : AppColors.textSecondaryLight, fontSize: 13)),
                            ),
                            ...team.map((m) => DropdownMenuItem<UserMember?>(
                                  value: m,
                                  child: Text('👤 ${m.nombre} (${m.roleDisplayName})', style: TextStyle(color: isDark ? Colors.white : AppColors.textPrimaryLight, fontSize: 13, fontWeight: FontWeight.w600)),
                                )),
                          ],
                          onChanged: (val) {
                            setState(() {
                              _colaboradorSeleccionado = val;
                              if (val != null) {
                                _nombreManualCtrl.text = '${val.nombre} (${val.roleDisplayName})';
                                if (val.salarioBase > 0) {
                                  _salarioCtrl.text = val.periodoPago == 'Quincenal' ? (val.salarioBase / 2).toInt().toString() : val.salarioBase.toInt().toString();
                                }
                                _periodo = val.periodoPago;
                                if (val.isTechnician || val.isOperator) {
                                  _arlEmpleado = ArlRiskClass.claseIII;
                                } else if (val.isAdmin || val.isCreator) {
                                  _arlEmpleado = ArlRiskClass.claseI;
                                }
                              }
                            });
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                  ],

                  if (_colaboradorSeleccionado == null)
                    GlassFormField(
                      label: 'NOMBRE DEL COLABORADOR / CARGO',
                      hint: 'Ej. Juan Pérez (Operario)',
                      controller: _nombreManualCtrl,
                      prefixIcon: Icons.badge_outlined,
                      validator: (v) => (v == null || v.trim().isEmpty) ? 'Ingresa el nombre del colaborador' : null,
                    ),
                  const SizedBox(height: 12),

                  // 3. Bloque: Periodo y Valores Devengados
                  Text('2. PARÁMETROS DEL PERIODO Y DEVENGADO', style: AppTypography.labelMicro.copyWith(color: AppColors.purpleAnalytics, fontWeight: FontWeight.w800, letterSpacing: 1.1)),
                  const SizedBox(height: 6),
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
                                DropdownMenuItem(value: 'Quincenal', child: Text('Quincenal', style: TextStyle(color: isDark ? Colors.white : AppColors.textPrimaryLight, fontSize: 12.5))),
                                DropdownMenuItem(value: 'Mensual', child: Text('Mensual', style: TextStyle(color: isDark ? Colors.white : AppColors.textPrimaryLight, fontSize: 12.5))),
                              ],
                              onChanged: (val) {
                                if (val != null) {
                                  setState(() {
                                    _periodo = val;
                                    _auxilioCtrl.text = (val == 'Quincenal'
                                            ? financeConfig.auxilioTransporteMensual / 2
                                            : financeConfig.auxilioTransporteMensual)
                                        .toInt()
                                        .toString();
                                  });
                                }
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
                  const SizedBox(height: 10),

                  Row(
                    children: [
                      Expanded(
                        child: GlassFormField(
                          label: 'SUELDO DEVENGADO',
                          controller: _salarioCtrl,
                          keyboardType: TextInputType.number,
                          prefixIcon: Icons.payments_outlined,
                          validator: (v) => (v == null || v.trim().isEmpty) ? 'Ingresa el sueldo' : null,
                          onChanged: (_) => setState(() {}),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: GlassFormField(
                          label: 'AUXILIO TRANSPORTE',
                          controller: _auxilioCtrl,
                          keyboardType: TextInputType.number,
                          prefixIcon: Icons.directions_bus_outlined,
                          onChanged: (_) => setState(() {}),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),

                  // 4. Bloque: Radiografía Financiera Comparativa (Trabajador vs Empresa)
                  Text('3. RADIOGRAFÍA FINANCIERA Y COSTOS', style: AppTypography.labelMicro.copyWith(color: AppColors.greenBiomass, fontWeight: FontWeight.w800, letterSpacing: 1.1)),
                  const SizedBox(height: 6),

                  Row(
                    children: [
                      // Tarjeta 1: Neto Trabajador
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppColors.cyanWater.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: AppColors.cyanWater.withValues(alpha: 0.3)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('NETO A TRANSFERIR', style: AppTypography.labelMicro.copyWith(color: AppColors.cyanWater)),
                              const SizedBox(height: 2),
                              FittedBox(
                                fit: BoxFit.scaleDown,
                                alignment: Alignment.centerLeft,
                                child: Text(
                                  CurrencyFormatters.formatCOP(calc.netoPagarTrabajador),
                                  style: TextStyle(color: isDark ? Colors.white : AppColors.textPrimaryLight, fontWeight: FontWeight.w900, fontSize: 16),
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text('Deducción SS (8%): -${CurrencyFormatters.formatCOP(calc.totalDeduccionesTrabajador)}', style: TextStyle(color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight, fontSize: 9.5)),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),

                      // Tarjeta 2: Costo Total Empresa
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppColors.purpleAnalytics.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: AppColors.purpleAnalytics.withValues(alpha: 0.4)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('COSTO REAL EMPRESA', style: AppTypography.labelMicro.copyWith(color: AppColors.purpleAnalytics)),
                              const SizedBox(height: 2),
                              FittedBox(
                                fit: BoxFit.scaleDown,
                                alignment: Alignment.centerLeft,
                                child: Text(
                                  CurrencyFormatters.formatCOP(calc.costoTotalEmpresa),
                                  style: const TextStyle(color: AppColors.purpleAnalytics, fontWeight: FontWeight.w900, fontSize: 16),
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text('Incluye prestaciones + ARL', style: TextStyle(color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight, fontSize: 9.5)),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  // Acordeón / Desglose de Cargas
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.surfaceDark.withValues(alpha: 0.6) : Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: isDark ? Colors.white.withValues(alpha: 0.08) : AppColors.glassBorderLight),
                    ),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('ARL ${_arlEmpleado.name.toUpperCase()} (${(_arlEmpleado.percentage * 100).toStringAsFixed(3)}%):', style: TextStyle(color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight, fontSize: 11)),
                            Text(CurrencyFormatters.formatCOP(calc.arl), style: TextStyle(color: isDark ? Colors.white : AppColors.textPrimaryLight, fontSize: 11, fontWeight: FontWeight.w600)),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('Pensión Patronal (12%) + Caja (4%):', style: TextStyle(color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight, fontSize: 11)),
                            Text(CurrencyFormatters.formatCOP(calc.pensionPatronal + calc.cajaCompensacion), style: TextStyle(color: isDark ? Colors.white : AppColors.textPrimaryLight, fontSize: 11, fontWeight: FontWeight.w600)),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('Provisiones (Prima, Ces, Vac, EPP):', style: TextStyle(color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight, fontSize: 11)),
                            Text(CurrencyFormatters.formatCOP(calc.totalProvisiones), style: TextStyle(color: isDark ? Colors.white : AppColors.textPrimaryLight, fontSize: 11, fontWeight: FontWeight.w600)),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),

                  // 5. Botón de Acción con Protección Debounce / Single-Flight
                  GlassButton(
                    label: _isLoading ? 'Guardando en Planilla...' : '✨ Asentar Liquidación en OPEX',
                    isLoading: _isLoading,
                    backgroundColor: AppColors.purpleAnalytics,
                    onPressed: _isLoading
                        ? null
                        : () async {
                            if (!_formKey.currentState!.validate()) return;
                            setState(() => _isLoading = true);

                            final nav = Navigator.of(context);
                            final messenger = ScaffoldMessenger.of(context);
                            final auth = ref.read(authProvider);
                            final empresaId = auth.currentUser?.empresaId ?? 'c1000000-0000-0000-0000-000000000001';
                            final unidadId = auth.activeUnitId ?? 'u1000000-0000-0000-0000-000000000001';

                            final record = PayrollEngine.createRecord(
                              id: const Uuid().v4(),
                              empresaId: empresaId,
                              unidadAcuicolaId: unidadId,
                              empleadoId: _colaboradorSeleccionado?.id ?? const Uuid().v4(),
                              empleadoNombre: _nombreManualCtrl.text.trim().isNotEmpty ? _nombreManualCtrl.text.trim() : 'Colaborador',
                              periodo: _periodo,
                              fechaPago: _fechaPago.toDateTime(),
                              calc: calc,
                            );

                            await ref.read(financeProvider.notifier).addPayrollRecord(record);

                            if (mounted) {
                              setState(() => _isLoading = false);
                              nav.pop();
                              messenger.showSnackBar(
                                const SnackBar(
                                  content: Text('¡Liquidación de nómina asentada con éxito!'),
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
      ),
    );
  }
}
