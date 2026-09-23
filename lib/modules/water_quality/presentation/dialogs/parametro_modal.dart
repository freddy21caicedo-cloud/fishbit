import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import 'package:fishbit_finance/core/design_system/app_colors.dart';
import 'package:fishbit_finance/core/design_system/app_typography.dart';
import 'package:fishbit_finance/core/design_system/glass_container.dart';
import 'package:fishbit_finance/core/design_system/glass_form_field.dart';
import 'package:fishbit_finance/core/design_system/glass_button.dart';
import 'package:fishbit_finance/core/design_system/glass_date_picker.dart';
import 'package:fishbit_finance/modules/auth_tenant/presentation/providers/auth_provider.dart';
import 'package:fishbit_finance/modules/ponds_batches/presentation/providers/ponds_provider.dart';
import 'package:fishbit_finance/modules/water_quality/domain/models/water_parameter.dart';
import 'package:fishbit_finance/modules/water_quality/presentation/providers/water_quality_provider.dart';

class ParametroModal extends ConsumerStatefulWidget {
  final String? preselectedPondId;

  const ParametroModal({super.key, this.preselectedPondId});

  static Future<void> show(BuildContext context, {String? preselectedPondId}) {
    return showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => ParametroModal(preselectedPondId: preselectedPondId),
    );
  }

  @override
  ConsumerState<ParametroModal> createState() => _ParametroModalState();
}

class _ParametroModalState extends ConsumerState<ParametroModal> {
  final _formKey = GlobalKey<FormState>();

  // 11 Parámetros Fisicoquímicos Solicitados (Vacíos por defecto - Integridad ICA DATA-01)
  final _oxigenoMgLCtrl = TextEditingController();
  final _oxigenoPctCtrl = TextEditingController();
  final _tempCtrl = TextEditingController();
  final _phCtrl = TextEditingController();
  final _amonioCtrl = TextEditingController();
  final _nitritosCtrl = TextEditingController();
  final _nitratosCtrl = TextEditingController();
  final _alcalinidadCtrl = TextEditingController();
  final _co2Ctrl = TextEditingController();
  final _durezaCtrl = TextEditingController();
  final _cloroCtrl = TextEditingController();
  final _obsCtrl = TextEditingController();

  bool _isSubmitting = false;

  String? _selectedPondId;
  CivilDate _fechaMedicion = CivilDate.today();
  TimeOfDay _horaMedicion = TimeOfDay.now();

  @override
  void initState() {
    super.initState();
    _selectedPondId = widget.preselectedPondId;
  }

  @override
  void dispose() {
    _oxigenoMgLCtrl.dispose();
    _oxigenoPctCtrl.dispose();
    _tempCtrl.dispose();
    _phCtrl.dispose();
    _amonioCtrl.dispose();
    _nitritosCtrl.dispose();
    _nitratosCtrl.dispose();
    _alcalinidadCtrl.dispose();
    _co2Ctrl.dispose();
    _durezaCtrl.dispose();
    _cloroCtrl.dispose();
    _obsCtrl.dispose();
    super.dispose();
  }

  String _formatTimeOfDay(TimeOfDay t) {
    final hour = t.hour.toString().padLeft(2, '0');
    final minute = t.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  double? _parseDecimal(String? text) {
    if (text == null) return null;
    final cleaned = text.trim().replaceAll(',', '.');
    if (cleaned.isEmpty) return null;
    final parsed = double.tryParse(cleaned);
    if (parsed == null || parsed.isNaN || parsed.isInfinite) return null;
    return parsed;
  }

  @override
  Widget build(BuildContext context) {
    final pondsState = ref.watch(pondsProvider);
    final waterState = ref.watch(waterQualityProvider);
    final ponds = pondsState.ponds;

    final oxigeno = _parseDecimal(_oxigenoMgLCtrl.text);
    final amonio = _parseDecimal(_amonioCtrl.text);
    final nitritos = _parseDecimal(_nitritosCtrl.text);
    final cloro = _parseDecimal(_cloroCtrl.text);

    final isHypoxia = oxigeno != null && oxigeno < 4.0;
    final isAmmoniaCritical = amonio != null && amonio > 0.5;
    final isNitriteCritical = nitritos != null && nitritos > 0.2;
    final isChlorineAlert = cloro != null && cloro > 0.05;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 520),
        child: GlassContainer(
          borderRadius: 24,
          padding: const EdgeInsets.all(22),
          blur: 24,
          opacity: isDark ? 0.16 : 0.94,
          borderColor: AppColors.cyanWater.withValues(alpha: isDark ? 0.35 : 0.25),
          child: Form(
            key: _formKey,
            child: SingleChildScrollView(
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
                              color: AppColors.cyanWater.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(Icons.water_drop_rounded, color: AppColors.cyanWater, size: 22),
                          ),
                          const SizedBox(width: 10),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('💧 Calidad de Agua', style: AppTypography.titleMedium.copyWith(color: isDark ? Colors.white : AppColors.textPrimaryLight, fontWeight: FontWeight.w800)),
                              Text('Registro fisicoquímico integral', style: TextStyle(color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight, fontSize: 11)),
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
                  const SizedBox(height: 16),

                  Text('ESTANQUE DE MEDICIÓN', style: AppTypography.labelMicro.copyWith(color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight)),
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: isDark ? Colors.white.withValues(alpha: 0.06) : Colors.black.withValues(alpha: 0.04),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: isDark ? Colors.white.withValues(alpha: 0.12) : AppColors.glassBorderLight),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: ponds.any((p) => p.id == _selectedPondId) ? _selectedPondId : null,
                        dropdownColor: isDark ? AppColors.surfaceDarkRaised : AppColors.surfaceLight,
                        isExpanded: true,
                        hint: Text(
                          'Selecciona un estanque *',
                          style: TextStyle(color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight, fontSize: 13, fontWeight: FontWeight.w500),
                        ),
                        icon: const Icon(Icons.keyboard_arrow_down_rounded, color: AppColors.cyanWater),
                        items: ponds.map((p) {
                          return DropdownMenuItem<String>(
                            value: p.id,
                            child: Text(
                              '${p.nombre} (${p.sigla})',
                              style: TextStyle(
                                color: isDark ? Colors.white : AppColors.textPrimaryLight,
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          );
                        }).toList(),
                        onChanged: (val) => setState(() => _selectedPondId = val),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),

                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        flex: 3,
                        child: GlassDatePickerField(
                          label: 'FECHA DE LA TOMA',
                          initialDate: _fechaMedicion,
                          accentColor: AppColors.cyanWater,
                          onDateChanged: (d) => setState(() => _fechaMedicion = d),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        flex: 2,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text('HORA DE TOMA', style: AppTypography.labelMicro.copyWith(color: AppColors.textSecondaryDark)),
                                GestureDetector(
                                  onTap: () => setState(() => _horaMedicion = TimeOfDay.now()),
                                  child: const Text('Ahora', style: TextStyle(color: AppColors.cyanWater, fontSize: 10, fontWeight: FontWeight.w800)),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            InkWell(
                              onTap: () async {
                                final picked = await showTimePicker(
                                  context: context,
                                  initialTime: _horaMedicion,
                                  builder: (context, child) {
                                    return Theme(
                                      data: ThemeData.dark().copyWith(
                                        colorScheme: const ColorScheme.dark(
                                          primary: AppColors.cyanWater,
                                          onPrimary: Colors.black,
                                          surface: AppColors.surfaceDark,
                                          onSurface: Colors.white,
                                        ),
                                      ),
                                      child: child!,
                                    );
                                  },
                                );
                                if (picked != null) {
                                  setState(() => _horaMedicion = picked);
                                }
                              },
                              borderRadius: BorderRadius.circular(14),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 13),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.06),
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(color: AppColors.cyanWater.withValues(alpha: 0.35)),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      _formatTimeOfDay(_horaMedicion),
                                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 13),
                                    ),
                                    const Icon(Icons.access_time_rounded, color: AppColors.cyanWater, size: 16),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),

                  _buildSectionHeader('🫁 OXÍGENO Y TEMPERATURA', AppColors.cyanWater),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: GlassFormField(
                          label: 'OXÍGENO (mg/L) *',
                          hint: 'Ej: 6.2',
                          isRequired: true,
                          controller: _oxigenoMgLCtrl,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          prefixIcon: Icons.air_rounded,
                          validator: (val) {
                            if (val == null || val.trim().isEmpty) return 'Requerido';
                            final parsed = _parseDecimal(val);
                            if (parsed == null || parsed < 0 || parsed > 30) return '0-30 mg/L';
                            return null;
                          },
                          onChanged: (_) => setState(() {}),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: GlassFormField(
                          label: 'SATURACIÓN (%)',
                          hint: 'Ej: 85.0',
                          controller: _oxigenoPctCtrl,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          prefixIcon: Icons.percent_rounded,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: GlassFormField(
                          label: 'TEMPERATURA (°C) *',
                          hint: 'Ej: 24.5',
                          isRequired: true,
                          controller: _tempCtrl,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          prefixIcon: Icons.thermostat_rounded,
                          validator: (val) {
                            if (val == null || val.trim().isEmpty) return 'Requerido';
                            final parsed = _parseDecimal(val);
                            if (parsed == null || parsed < 5 || parsed > 45) return '5-45°C';
                            return null;
                          },
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: GlassFormField(
                          label: 'pH DEL AGUA *',
                          hint: 'Ej: 7.2',
                          isRequired: true,
                          controller: _phCtrl,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          prefixIcon: Icons.science_outlined,
                          validator: (val) {
                            if (val == null || val.trim().isEmpty) return 'Requerido';
                            final parsed = _parseDecimal(val);
                            if (parsed == null || parsed < 0 || parsed > 14) return '0-14';
                            return null;
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  _buildSectionHeader('🧪 COMPUESTOS NITROGENADOS', AppColors.greenBiomass),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: GlassFormField(
                          label: 'AMONIO TOTAL (ppm)',
                          controller: _amonioCtrl,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          prefixIcon: Icons.bubble_chart_rounded,
                          onChanged: (_) => setState(() {}),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: GlassFormField(
                          label: 'NITRITO NO₂⁻ (ppm)',
                          controller: _nitritosCtrl,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          prefixIcon: Icons.biotech_rounded,
                          onChanged: (_) => setState(() {}),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  GlassFormField(
                    label: 'NITRATO NO₃⁻ (ppm)',
                    controller: _nitratosCtrl,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    prefixIcon: Icons.grain_rounded,
                  ),
                  const SizedBox(height: 16),

                  _buildSectionHeader('🛡️ BALANCE QUÍMICO Y DESINFECCIÓN', AppColors.purpleAnalytics),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: GlassFormField(
                          label: 'ALCALINIDAD (ppm)',
                          controller: _alcalinidadCtrl,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          prefixIcon: Icons.shield_outlined,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: GlassFormField(
                          label: 'CO₂ LIBRE (ppm)',
                          controller: _co2Ctrl,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          prefixIcon: Icons.cloud_outlined,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: GlassFormField(
                          label: 'DUREZA TOTAL (ppm)',
                          controller: _durezaCtrl,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          prefixIcon: Icons.layers_rounded,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: GlassFormField(
                          label: 'CLORO LIBRE (ppm)',
                          controller: _cloroCtrl,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          prefixIcon: Icons.clean_hands_rounded,
                          onChanged: (_) => setState(() {}),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),

                  GlassFormField(
                    label: 'OBSERVACIONES TÉCNICAS (OPCIONAL)',
                    hint: 'Ej: Medición matutina post-lluvia, aireación encendida...',
                    controller: _obsCtrl,
                  ),
                  const SizedBox(height: 14),

                  if (isHypoxia || isAmmoniaCritical || isNitriteCritical || isChlorineAlert)
                    Container(
                      margin: const EdgeInsets.only(bottom: 14),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.coralAction.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: AppColors.coralAction.withValues(alpha: 0.4)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (isHypoxia)
                            const Row(
                              children: [
                                Icon(Icons.warning_rounded, color: AppColors.coralAction, size: 16),
                                SizedBox(width: 6),
                                Expanded(
                                  child: Text('¡Alerta de Hipoxia! Oxígeno crítico (<4.0 mg/L). Activar aireadores.', style: TextStyle(color: AppColors.coralAction, fontSize: 11, fontWeight: FontWeight.w700)),
                                ),
                              ],
                            ),
                          if (isAmmoniaCritical) ...[
                            if (isHypoxia) const SizedBox(height: 4),
                            const Row(
                              children: [
                                Icon(Icons.warning_rounded, color: AppColors.coralAction, size: 16),
                                SizedBox(width: 6),
                                Expanded(
                                  child: Text('¡Alerta de Toxicidad! Amonio > 0.5 ppm. Suspender alimento y recambiar agua.', style: TextStyle(color: AppColors.coralAction, fontSize: 11, fontWeight: FontWeight.w700)),
                                ),
                              ],
                            ),
                          ],
                          if (isNitriteCritical) ...[
                            if (isHypoxia || isAmmoniaCritical) const SizedBox(height: 4),
                            const Row(
                              children: [
                                Icon(Icons.warning_rounded, color: AppColors.coralAction, size: 16),
                                SizedBox(width: 6),
                                Expanded(
                                  child: Text(
                                    '¡Alerta Crítica! Nitritos NO₂⁻ > 0.2 ppm. Alto riesgo de toxicidad e hipoxia tisular.',
                                    style: TextStyle(color: AppColors.coralAction, fontSize: 11, fontWeight: FontWeight.w700),
                                  ),
                                ),
                              ],
                            ),
                          ],
                          if (isChlorineAlert) ...[
                            if (isHypoxia || isAmmoniaCritical || isNitriteCritical) const SizedBox(height: 4),
                            const Row(
                              children: [
                                Icon(Icons.warning_rounded, color: AppColors.amberWarning, size: 16),
                                SizedBox(width: 6),
                                Expanded(
                                  child: Text('Presencia de Cloro Residual (>0.05 ppm). Verificar descloración de la fuente.', style: TextStyle(color: AppColors.amberWarning, fontSize: 11, fontWeight: FontWeight.w700)),
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),

                  GlassButton(
                    label: 'Guardar Medición de Calidad de Agua',
                    isLoading: _isSubmitting || waterState.isLoading,
                    backgroundColor: AppColors.cyanWater,
                    onPressed: () async {
                      if (_isSubmitting) return;
                      setState(() => _isSubmitting = true);

                      try {
                        final messenger = ScaffoldMessenger.of(context);
                        final nav = Navigator.of(context);

                        final isFormValid = _formKey.currentState!.validate();

                        if (_selectedPondId == null || _selectedPondId!.isEmpty || !ponds.any((p) => p.id == _selectedPondId)) {
                          messenger.showSnackBar(
                            const SnackBar(
                              content: Text('Debe seleccionar un estanque de medición válido para registrar los parámetros.'),
                              backgroundColor: AppColors.coralAction,
                            ),
                          );
                          return;
                        }

                        if (!isFormValid) {
                          messenger.showSnackBar(
                            const SnackBar(
                              content: Text('Por favor complete los campos obligatorios (O₂, Temp, pH) dentro de los rangos válidos.'),
                              backgroundColor: AppColors.coralAction,
                            ),
                          );
                          return;
                        }

                        final authState = ref.read(authProvider);
                        final empresaId = authState.currentCompany?.id ?? authState.currentUser?.empresaId;
                        if (empresaId == null || empresaId.isEmpty) {
                          messenger.showSnackBar(
                            const SnackBar(
                              content: Text('Error: No se encontró una empresa activa para registrar la medición.'),
                              backgroundColor: AppColors.coralAction,
                            ),
                          );
                          return;
                        }
                        final unidadId = authState.activeUnitId ?? authState.currentUser?.unidadAcuicolaId ?? empresaId;

                        final baseDate = _fechaMedicion.toDateTime();
                        final fullDateTime = DateTime(
                          baseDate.year,
                          baseDate.month,
                          baseDate.day,
                          _horaMedicion.hour,
                          _horaMedicion.minute,
                        );

                        final param = WaterParameter(
                          id: const Uuid().v4(),
                          empresaId: empresaId,
                          unidadAcuicolaId: unidadId,
                          estanqueId: _selectedPondId!,
                          fecha: fullDateTime,
                          oxigenoMgL: _parseDecimal(_oxigenoMgLCtrl.text),
                          oxigenoPct: _parseDecimal(_oxigenoPctCtrl.text),
                          ph: _parseDecimal(_phCtrl.text),
                          temperaturaC: _parseDecimal(_tempCtrl.text),
                          amonioMgL: _parseDecimal(_amonioCtrl.text),
                          nitritosMgL: _parseDecimal(_nitritosCtrl.text),
                          nitratosMgL: _parseDecimal(_nitratosCtrl.text),
                          alcalinidadMgL: _parseDecimal(_alcalinidadCtrl.text),
                          co2MgL: _parseDecimal(_co2Ctrl.text),
                          durezaMgL: _parseDecimal(_durezaCtrl.text),
                          cloroMgL: _parseDecimal(_cloroCtrl.text),
                          observaciones: _obsCtrl.text.trim().isNotEmpty ? _obsCtrl.text.trim() : null,
                          registradoPor: authState.currentUser?.nombre,
                        );

                        final success = await ref.read(waterQualityProvider.notifier).recordWaterQuality(param);
                        if (success && mounted) {
                          nav.pop();
                          messenger.showSnackBar(
                            const SnackBar(
                              content: Text('¡Medición registrada con éxito con 11 parámetros y hora de toma!'),
                              backgroundColor: AppColors.cyanWater,
                            ),
                          );
                        } else if (!success && mounted) {
                          messenger.showSnackBar(
                            SnackBar(
                              content: Text('Error al registrar medición: ${ref.read(waterQualityProvider).errorMessage ?? "Error de red"}'),
                              backgroundColor: AppColors.coralAction,
                            ),
                          );
                        }
                      } finally {
                        if (mounted) setState(() => _isSubmitting = false);
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

  Widget _buildSectionHeader(String title, Color color) {
    return Row(
      children: [
        Container(width: 3, height: 12, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(2))),
        const SizedBox(width: 6),
        Text(title, style: TextStyle(color: color, fontSize: 10.5, fontWeight: FontWeight.w800, letterSpacing: 0.8)),
      ],
    );
  }
}
