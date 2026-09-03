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
import 'package:fishbit_finance/modules/ponds_batches/presentation/providers/ponds_provider.dart';
import 'package:fishbit_finance/modules/finance_payroll/domain/models/jornal_record.dart';
import 'package:fishbit_finance/modules/finance_payroll/presentation/providers/finance_provider.dart';

class RegistroJornalModal extends ConsumerStatefulWidget {
  const RegistroJornalModal({super.key});

  static Future<void> show(BuildContext context) {
    return showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => const RegistroJornalModal(),
    );
  }

  @override
  ConsumerState<RegistroJornalModal> createState() => _RegistroJornalModalState();
}

class _RegistroJornalModalState extends ConsumerState<RegistroJornalModal> {
  final _formKey = GlobalKey<FormState>();
  final List<String> _laboresComunes = [
    '🐟 Cosecha Nocturna y Selección',
    '🔀 Desdoble y Traslado de Biomasa',
    '🧼 Lavado y Desinfección de Estanque',
    '🚜 Limpieza de Mallas y Canales',
    '🌾 Siembra y Aclimatación de Alevinos',
    '⚡ Mantenimiento de Aireación y Motores',
    '📦 Carga y Empaque para Despacho',
  ];

  late String _laborSeleccionada;
  final _cantidadCtrl = TextEditingController(text: '3');
  late TextEditingController _valorJornalCtrl;
  final _obsCtrl = TextEditingController();
  String? _estanqueSeleccionadoId;
  CivilDate _fechaLabor = CivilDate.today();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _laborSeleccionada = _laboresComunes.first;
    final config = ref.read(financeProvider).payrollConfig;
    _valorJornalCtrl = TextEditingController(text: config.tarifaJornalCampoDefecto.toInt().toString());
  }

  @override
  void dispose() {
    _cantidadCtrl.dispose();
    _valorJornalCtrl.dispose();
    _obsCtrl.dispose();
    super.dispose();
  }

  int get _cantidad => int.tryParse(_cantidadCtrl.text) ?? 1;
  double get _valorJornal => double.tryParse(_valorJornalCtrl.text) ?? 65000.0;
  double get _totalPagar => _cantidad * _valorJornal;

  @override
  Widget build(BuildContext context) {
    final ponds = ref.watch(pondsProvider).ponds;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480),
        child: GlassContainer(
          borderRadius: 24,
          padding: const EdgeInsets.all(22),
          blur: 24,
          opacity: 0.16,
          borderColor: AppColors.amberWarning.withValues(alpha: 0.35),
          child: Form(
            key: _formKey,
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
                              color: AppColors.amberWarning.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(Icons.agriculture_rounded, color: AppColors.amberWarning, size: 20),
                          ),
                          const SizedBox(width: 10),
                          Text(
                            'Jornales de Campo',
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

                  // Selector de Labor Predefinida (Zero Typing)
                  Text('LABOR REALIZADA', style: AppTypography.labelMicro.copyWith(color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight)),
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: isDark ? Colors.white.withValues(alpha: 0.06) : Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: isDark ? Colors.white.withValues(alpha: 0.12) : AppColors.glassBorderLight),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: _laborSeleccionada,
                        dropdownColor: isDark ? AppColors.surfaceDark : Colors.white,
                        isExpanded: true,
                        items: _laboresComunes.map((lab) {
                          return DropdownMenuItem(
                            value: lab,
                            child: Text(
                              lab,
                              style: TextStyle(color: isDark ? Colors.white : AppColors.textPrimaryLight, fontSize: 13, fontWeight: FontWeight.w600),
                            ),
                          );
                        }).toList(),
                        onChanged: (val) {
                          if (val != null) setState(() => _laborSeleccionada = val);
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Selector de Estanque Asignado (Opcional)
                  Text('ESTANQUE DESTINO (PRORRATEO CPK)', style: AppTypography.labelMicro.copyWith(color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight)),
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: isDark ? Colors.white.withValues(alpha: 0.06) : Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: isDark ? Colors.white.withValues(alpha: 0.12) : AppColors.glassBorderLight),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String?>(
                        value: _estanqueSeleccionadoId,
                        dropdownColor: isDark ? AppColors.surfaceDark : Colors.white,
                        isExpanded: true,
                        hint: Text('🌾 General de Granja (Prorrateo Global)', style: TextStyle(color: isDark ? Colors.white70 : AppColors.textSecondaryLight, fontSize: 12)),
                        items: [
                          DropdownMenuItem<String?>(
                            value: null,
                            child: Text('🌾 General de Granja (Prorrateo Global)', style: TextStyle(color: isDark ? Colors.white70 : AppColors.textSecondaryLight, fontSize: 12)),
                          ),
                          ...ponds.map((p) => DropdownMenuItem<String?>(
                                value: p.id,
                                child: Text('🐟 ${p.nombreLimpio}', style: TextStyle(color: isDark ? Colors.white : AppColors.textPrimaryLight, fontSize: 12.5, fontWeight: FontWeight.w600)),
                              )),
                        ],
                        onChanged: (val) => setState(() => _estanqueSeleccionadoId = val),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  Row(
                    children: [
                      Expanded(
                        child: GlassFormField(
                          label: 'CANTIDAD JORNALES / DÍAS',
                          controller: _cantidadCtrl,
                          keyboardType: TextInputType.number,
                          prefixIcon: Icons.people_outline,
                          onChanged: (_) => setState(() {}),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: GlassFormField(
                          label: 'VALOR POR JORNAL (\$ COP)',
                          controller: _valorJornalCtrl,
                          keyboardType: TextInputType.number,
                          prefixIcon: Icons.payments_outlined,
                          onChanged: (_) => setState(() {}),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  GlassDatePickerField(
                    label: 'FECHA DE LA LABOR',
                    accentColor: AppColors.amberWarning,
                    initialDate: _fechaLabor,
                    onDateChanged: (d) => setState(() => _fechaLabor = d),
                  ),
                  const SizedBox(height: 14),

                  // Total a Pagar
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    decoration: BoxDecoration(
                      color: AppColors.amberWarning.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: AppColors.amberWarning.withValues(alpha: 0.3)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('TOTAL CUADRILLA A PAGAR:', style: TextStyle(color: isDark ? Colors.white : AppColors.textPrimaryLight, fontWeight: FontWeight.w800, fontSize: 12)),
                        Text(
                          CurrencyFormatters.formatCOP(_totalPagar),
                          style: const TextStyle(color: AppColors.amberWarning, fontWeight: FontWeight.w900, fontSize: 16),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 18),

                  GlassButton(
                    label: 'Registrar Jornal en OPEX',
                    isLoading: _isLoading,
                    backgroundColor: AppColors.amberWarning,
                    onPressed: () async {
                      if (!_formKey.currentState!.validate()) return;
                      setState(() => _isLoading = true);

                      final auth = ref.read(authProvider);
                      final empresaId = auth.currentUser?.empresaId ?? 'c1000000-0000-0000-0000-000000000001';
                      final unidadId = auth.activeUnitId ?? 'u1000000-0000-0000-0000-000000000001';

                      final record = JornalRecord(
                        id: const Uuid().v4(),
                        empresaId: empresaId,
                        unidadAcuicolaId: unidadId,
                        estanqueId: _estanqueSeleccionadoId,
                        laborRealizada: _laborSeleccionada,
                        cantidadJornales: _cantidad,
                        valorPorJornal: _valorJornal,
                        totalPagado: _totalPagar,
                        observaciones: _obsCtrl.text.trim().isNotEmpty ? _obsCtrl.text.trim() : null,
                        responsablePago: auth.currentUser?.nombre,
                        fecha: _fechaLabor.toDateTime(),
                        creadoEn: DateTime.now(),
                      );

                      final nav = Navigator.of(context);
                      final messenger = ScaffoldMessenger.of(context);

                      await ref.read(financeProvider.notifier).addJornal(record);

                      if (mounted) {
                        setState(() => _isLoading = false);
                        nav.pop();
                        messenger.showSnackBar(
                          const SnackBar(
                            content: Text('¡Jornal de campo registrado con éxito!'),
                            backgroundColor: AppColors.amberWarning,
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
