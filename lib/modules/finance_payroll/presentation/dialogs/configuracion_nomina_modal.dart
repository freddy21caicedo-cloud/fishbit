import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fishbit_finance/core/design_system/app_colors.dart';
import 'package:fishbit_finance/core/design_system/app_typography.dart';
import 'package:fishbit_finance/core/design_system/glass_container.dart';
import 'package:fishbit_finance/core/design_system/glass_form_field.dart';
import 'package:fishbit_finance/core/design_system/glass_button.dart';
import 'package:fishbit_finance/modules/finance_payroll/domain/models/payroll_config.dart';
import 'package:fishbit_finance/modules/finance_payroll/presentation/providers/finance_provider.dart';

class ConfiguracionNominaModal extends ConsumerStatefulWidget {
  const ConfiguracionNominaModal({super.key});

  static Future<void> show(BuildContext context) {
    return showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => const ConfiguracionNominaModal(),
    );
  }

  @override
  ConsumerState<ConfiguracionNominaModal> createState() => _ConfiguracionNominaModalState();
}

class _ConfiguracionNominaModalState extends ConsumerState<ConfiguracionNominaModal> {
  late bool _exoneracion;
  late ArlRiskClass _arlSelected;
  late TextEditingController _auxilioCtrl;
  late TextEditingController _dotacionCtrl;
  late TextEditingController _jornalCtrl;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    final config = ref.read(financeProvider).payrollConfig;
    _exoneracion = config.aplicaExoneracionLey1607;
    _arlSelected = config.arlDefault;
    _auxilioCtrl = TextEditingController(text: config.auxilioTransporteMensual.toInt().toString());
    _dotacionCtrl = TextEditingController(text: config.dotacionProvisionMensual.toInt().toString());
    _jornalCtrl = TextEditingController(text: config.tarifaJornalCampoDefecto.toInt().toString());
  }

  @override
  void dispose() {
    _auxilioCtrl.dispose();
    _dotacionCtrl.dispose();
    _jornalCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textSecondary = isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 520),
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
                          child: const Icon(Icons.tune_rounded, color: AppColors.purpleAnalytics, size: 20),
                        ),
                        const SizedBox(width: 10),
                        Text(
                          'Ajustes de Nómina y ARL',
                          style: AppTypography.titleOf(context, fontWeight: FontWeight.w800),
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

                // Exoneración Ley 1607
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: _exoneracion ? AppColors.greenBiomass.withValues(alpha: 0.4) : (isDark ? Colors.white12 : AppColors.glassBorderLight)),
                  ),
                  child: Row(
                    children: [
                      Switch(
                        value: _exoneracion,
                        activeTrackColor: AppColors.greenBiomass,
                        onChanged: (val) => setState(() => _exoneracion = val),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Exoneración Ley 1607 / Art. 114-1 E.T.',
                              style: TextStyle(color: isDark ? Colors.white : AppColors.textPrimaryLight, fontWeight: FontWeight.w800, fontSize: 12.5),
                            ),
                            Text(
                              _exoneracion
                                  ? '🟢 Empresa exenta de Salud Patronal (8.5%), SENA (2%) e ICBF (3%) en sueldos <10 SMMLV.'
                                  : '🔴 Empresa paga tarifa plena de Salud (8.5%), SENA e ICBF.',
                              style: TextStyle(color: textSecondary, fontSize: 11),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),

                // Selector de ARL (Decreto 768)
                Text('CLASE DE RIESGO ARL DE LA GRANJA (DECRETO 768)', style: AppTypography.labelMicro.copyWith(color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight)),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color: isDark ? Colors.white.withValues(alpha: 0.06) : Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: isDark ? Colors.white.withValues(alpha: 0.12) : AppColors.glassBorderLight),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<ArlRiskClass>(
                      value: _arlSelected,
                      dropdownColor: isDark ? AppColors.surfaceDark : Colors.white,
                      isExpanded: true,
                      items: ArlRiskClass.values.map((arl) {
                        return DropdownMenuItem(
                          value: arl,
                          child: Text(
                            arl.label,
                            style: TextStyle(color: isDark ? Colors.white : AppColors.textPrimaryLight, fontSize: 12.5),
                            overflow: TextOverflow.ellipsis,
                          ),
                        );
                      }).toList(),
                      onChanged: (val) {
                        if (val != null) setState(() => _arlSelected = val);
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 14),

                // Parámetros Monetarios
                Row(
                  children: [
                    Expanded(
                      child: GlassFormField(
                        label: 'AUXILIO TRANSPORTE MES',
                        controller: _auxilioCtrl,
                        keyboardType: TextInputType.number,
                        prefixIcon: Icons.directions_bus_outlined,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: GlassFormField(
                        label: 'PROVISIÓN DOTACIÓN/EPP',
                        controller: _dotacionCtrl,
                        keyboardType: TextInputType.number,
                        prefixIcon: Icons.checkroom_outlined,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                GlassFormField(
                  label: 'TARIFA SUGERIDA JORNAL DE CAMPO (\$ COP/DÍA)',
                  hint: '65000',
                  controller: _jornalCtrl,
                  keyboardType: TextInputType.number,
                  prefixIcon: Icons.agriculture_outlined,
                ),
                const SizedBox(height: 16),

                // Resumen de Cargas Patronales
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.purpleAnalytics.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppColors.purpleAnalytics.withValues(alpha: 0.25)),
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Pensión Patronal:', style: TextStyle(color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight, fontSize: 11.5)),
                          Text('12.0%', style: TextStyle(color: isDark ? Colors.white : AppColors.textPrimaryLight, fontWeight: FontWeight.w700, fontSize: 12)),
                        ],
                      ),
                      const SizedBox(height: 3),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('ARL Seleccionada:', style: TextStyle(color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight, fontSize: 11.5)),
                          Text('${(_arlSelected.percentage * 100).toStringAsFixed(3)}%', style: const TextStyle(color: AppColors.purpleAnalytics, fontWeight: FontWeight.w800, fontSize: 12)),
                        ],
                      ),
                      const SizedBox(height: 3),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Caja de Compensación:', style: TextStyle(color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight, fontSize: 11.5)),
                          Text('4.0%', style: TextStyle(color: isDark ? Colors.white : AppColors.textPrimaryLight, fontWeight: FontWeight.w700, fontSize: 12)),
                        ],
                      ),
                      const SizedBox(height: 3),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Prestaciones (Prima, Ces, Int, Vac):', style: TextStyle(color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight, fontSize: 11.5)),
                          Text('21.83%', style: TextStyle(color: isDark ? Colors.white : AppColors.textPrimaryLight, fontWeight: FontWeight.w700, fontSize: 12)),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 18),

                GlassButton(
                  label: 'Guardar Parámetros de Nómina',
                  height: 46,
                  backgroundColor: AppColors.purpleAnalytics,
                  isLoading: _isLoading,
                  onPressed: () async {
                    final nav = Navigator.of(context);
                    final messenger = ScaffoldMessenger.of(context);
                    setState(() => _isLoading = true);
                    final newConfig = PayrollConfig(
                      aplicaExoneracionLey1607: _exoneracion,
                      arlDefault: _arlSelected,
                      auxilioTransporteMensual: double.tryParse(_auxilioCtrl.text) ?? 162000.0,
                      dotacionProvisionMensual: double.tryParse(_dotacionCtrl.text) ?? 35000.0,
                      tarifaJornalCampoDefecto: double.tryParse(_jornalCtrl.text) ?? 65000.0,
                    );

                    await ref.read(financeProvider.notifier).updatePayrollConfig(newConfig);

                    if (mounted) {
                      setState(() => _isLoading = false);
                      nav.pop();
                      messenger.showSnackBar(
                        const SnackBar(
                          content: Text('¡Parámetros de nómina y ARL actualizados!'),
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
