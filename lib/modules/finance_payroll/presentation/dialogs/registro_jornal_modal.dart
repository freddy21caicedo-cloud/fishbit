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
    return showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (_) => const RegistroJornalModal(),
    );
  }

  @override
  ConsumerState<RegistroJornalModal> createState() => _RegistroJornalModalState();
}

class _RegistroJornalModalState extends ConsumerState<RegistroJornalModal> {
  static const String _otraLaborKey = 'Otra labor (personalizada)';

  final _formKey = GlobalKey<FormState>();
  final List<String> _laboresComunes = const [
    'Cosecha Nocturna y Selección',
    'Desdoble y Traslado de Biomasa',
    'Lavado y Desinfección de Estanque',
    'Limpieza de Mallas y Canales',
    'Siembra y Aclimatación de Alevinos',
    'Mantenimiento de Aireación y Motores',
    'Carga y Empaque para Despacho',
    _otraLaborKey,
  ];

  late String _laborSeleccionada;
  final _otraLaborCtrl = TextEditingController();
  final _responsableCtrl = TextEditingController();
  final _cantidadCtrl = TextEditingController(text: '1');
  late final TextEditingController _valorJornalCtrl;
  final _obsCtrl = TextEditingController();
  String? _estanqueSeleccionadoId;
  CivilDate _fechaLabor = CivilDate.today();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _laborSeleccionada = _laboresComunes.first;
    final config = ref.read(financeProvider).payrollConfig;
    _valorJornalCtrl = TextEditingController(
      text: CurrencyFormatters.formatCOP(config.tarifaJornalCampoDefecto),
    );
  }

  @override
  void dispose() {
    _otraLaborCtrl.dispose();
    _responsableCtrl.dispose();
    _cantidadCtrl.dispose();
    _valorJornalCtrl.dispose();
    _obsCtrl.dispose();
    super.dispose();
  }

  int get _cantidad =>
      CurrencyFormatters.parseCOP(_cantidadCtrl.text).toInt().clamp(1, 999999);

  double get _valorJornal {
    final parsed = CurrencyFormatters.parseCOP(_valorJornalCtrl.text);
    return parsed > 0 ? parsed : 65000.0;
  }

  double get _totalPagar => _cantidad * _valorJornal;

  @override
  Widget build(BuildContext context) {
    final ponds = ref.watch(pondsProvider).ponds;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 500),
        child: GlassContainer(
          borderRadius: 24,
          padding: const EdgeInsets.all(22),
          blur: 24,
          opacity: isDark ? 0.16 : 0.92,
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
                            child: const Icon(
                              Icons.agriculture_rounded,
                              color: AppColors.amberWarning,
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'MANO DE OBRA EVENTUAL',
                                style: AppTypography.labelMicro.copyWith(
                                  color: AppColors.amberWarning,
                                  letterSpacing: 1.1,
                                ),
                              ),
                              Text(
                                'Registro de Jornalero',
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
                  const SizedBox(height: 14),

                  // 1. Trabajador o Cuadrilla
                  GlassFormField(
                    label: 'NOMBRE DEL JORNALERO / CUADRILLA',
                    controller: _responsableCtrl,
                    prefixIcon: Icons.person_outline_rounded,
                    accentColor: AppColors.amberWarning,
                    hint: 'Ej. Carlos Pérez / Cuadrilla Cosecha',
                  ),
                  const SizedBox(height: 12),

                  // 2. Labor realizada
                  Text(
                    'LABOR REALIZADA',
                    style: AppTypography.labelMicro.copyWith(
                      color: isDark
                          ? AppColors.textSecondaryDark
                          : AppColors.textSecondaryLight,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: isDark
                          ? Colors.white.withValues(alpha: 0.06)
                          : Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: isDark
                            ? Colors.white.withValues(alpha: 0.12)
                            : AppColors.glassBorderLight,
                      ),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: _laborSeleccionada,
                        dropdownColor:
                            isDark ? AppColors.surfaceDark : Colors.white,
                        isExpanded: true,
                        items: _laboresComunes.map((lab) {
                          return DropdownMenuItem(
                            value: lab,
                            child: Text(
                              lab,
                              style: TextStyle(
                                color: isDark
                                    ? Colors.white
                                    : AppColors.textPrimaryLight,
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          );
                        }).toList(),
                        onChanged: (val) {
                          if (val != null) {
                            setState(() => _laborSeleccionada = val);
                          }
                        },
                      ),
                    ),
                  ),
                  if (_laborSeleccionada == _otraLaborKey) ...[
                    const SizedBox(height: 10),
                    GlassFormField(
                      label: 'DESCRIPCIÓN DE LA LABOR',
                      controller: _otraLaborCtrl,
                      prefixIcon: Icons.edit_note_rounded,
                      accentColor: AppColors.amberWarning,
                      isRequired: true,
                      hint: 'Describe la labor realizada...',
                    ),
                  ],
                  const SizedBox(height: 12),

                  // 3. Destino del costo: Costo General vs Estanque específico
                  Text(
                    'DESTINO DEL COSTO',
                    style: AppTypography.labelMicro.copyWith(
                      color: isDark
                          ? AppColors.textSecondaryDark
                          : AppColors.textSecondaryLight,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: isDark
                          ? Colors.white.withValues(alpha: 0.06)
                          : Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: isDark
                            ? Colors.white.withValues(alpha: 0.12)
                            : AppColors.glassBorderLight,
                      ),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String?>(
                        value: _estanqueSeleccionadoId,
                        dropdownColor:
                            isDark ? AppColors.surfaceDark : Colors.white,
                        isExpanded: true,
                        items: [
                          DropdownMenuItem<String?>(
                            value: null,
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
                                    'Costo General de Granja (Prorrateo % biomasa)',
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      color: isDark
                                          ? Colors.white
                                          : AppColors.textPrimaryLight,
                                      fontSize: 12.5,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          ...ponds.map(
                            (p) => DropdownMenuItem<String?>(
                              value: p.id,
                              child: Row(
                                children: [
                                  const Icon(
                                    Icons.water_drop_rounded,
                                    size: 16,
                                    color: AppColors.greenBiomass,
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      'Estanque: ${p.nombreLimpio}',
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        color: isDark
                                            ? Colors.white
                                            : AppColors.textPrimaryLight,
                                        fontSize: 12.5,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                        onChanged: (val) =>
                            setState(() => _estanqueSeleccionadoId = val),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // 4. Cantidad y Valor por jornal
                  Row(
                    children: [
                      Expanded(
                        child: GlassFormField(
                          label: 'CANTIDAD JORNALES / DÍAS',
                          controller: _cantidadCtrl,
                          keyboardType: TextInputType.number,
                          prefixIcon: Icons.people_outline_rounded,
                          accentColor: AppColors.amberWarning,
                          onChanged: (_) => setState(() {}),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: GlassFormField(
                          label: 'VALOR POR JORNAL (\$ COP)',
                          controller: _valorJornalCtrl,
                          keyboardType: TextInputType.number,
                          inputFormatters: [CurrencyInputFormatter()],
                          prefixIcon: Icons.payments_outlined,
                          accentColor: AppColors.amberWarning,
                          onChanged: (_) => setState(() {}),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // 5. Fecha de la labor
                  GlassDatePickerField(
                    label: 'FECHA DE LA LABOR',
                    accentColor: AppColors.amberWarning,
                    initialDate: _fechaLabor,
                    onDateChanged: (d) => setState(() => _fechaLabor = d),
                  ),
                  const SizedBox(height: 12),

                  // 6. Observaciones
                  GlassFormField(
                    label: 'OBSERVACIONES (OPCIONAL)',
                    controller: _obsCtrl,
                    prefixIcon: Icons.notes_rounded,
                    accentColor: AppColors.amberWarning,
                    hint: 'Detalles adicionales de la jornada...',
                  ),
                  const SizedBox(height: 14),

                  // Total a Pagar
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.amberWarning.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: AppColors.amberWarning.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'TOTAL A PAGAR:',
                          style: TextStyle(
                            color: isDark
                                ? Colors.white
                                : AppColors.textPrimaryLight,
                            fontWeight: FontWeight.w800,
                            fontSize: 12,
                          ),
                        ),
                        Text(
                          CurrencyFormatters.formatCOP(_totalPagar),
                          style: const TextStyle(
                            color: AppColors.amberWarning,
                            fontWeight: FontWeight.w900,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  GlassButton(
                    label: 'Registrar Jornalero',
                    isLoading: _isLoading,
                    backgroundColor: AppColors.amberWarning,
                    onPressed: () async {
                      if (!_formKey.currentState!.validate()) return;
                      final auth = ref.read(authProvider);
                      final empresaId = auth.currentCompany?.id ??
                          auth.currentUser?.empresaId ??
                          '';
                      final unitId = auth.activeUnitId ?? '';
                      if (unitId.isEmpty) return;

                      final laborFinal = _laborSeleccionada == _otraLaborKey
                          ? _otraLaborCtrl.text.trim()
                          : _laborSeleccionada;

                      final navigator = Navigator.of(context);
                      final messenger = ScaffoldMessenger.of(context);
                      setState(() => _isLoading = true);
                      try {
                        final record = JornalRecord(
                          id: const Uuid().v4(),
                          empresaId: empresaId,
                          unidadAcuicolaId: unitId,
                          estanqueId: _estanqueSeleccionadoId,
                          laborRealizada: laborFinal.isNotEmpty
                              ? laborFinal
                              : 'Labores de Campo',
                          cantidadJornales: _cantidad,
                          valorPorJornal: _valorJornal,
                          totalPagado: _totalPagar,
                          responsablePago: _responsableCtrl.text.trim().isNotEmpty
                              ? _responsableCtrl.text.trim()
                              : null,
                          observaciones: _obsCtrl.text.trim().isNotEmpty
                              ? _obsCtrl.text.trim()
                              : null,
                          fecha: _fechaLabor.toDateTime(),
                          creadoEn: DateTime.now(),
                        );

                        await ref.read(financeProvider.notifier).addJornal(record);
                        if (!mounted) return;
                        navigator.pop();
                        messenger.showSnackBar(
                          const SnackBar(
                            content: Text('Jornalero registrado con éxito'),
                            backgroundColor: AppColors.greenBiomass,
                          ),
                        );
                      } catch (e) {
                        if (!mounted) return;
                        messenger.showSnackBar(
                          SnackBar(
                            content: Text('Error al registrar jornalero: $e'),
                            backgroundColor: AppColors.coralAction,
                          ),
                        );
                      } finally {
                        if (mounted) setState(() => _isLoading = false);
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
