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
  const ParametroModal({super.key});

  static Future<void> show(BuildContext context) {
    return showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => const ParametroModal(),
    );
  }

  @override
  ConsumerState<ParametroModal> createState() => _ParametroModalState();
}

class _ParametroModalState extends ConsumerState<ParametroModal> {
  final _formKey = GlobalKey<FormState>();

  // 11 Parámetros Fisicoquímicos Solicitados
  final _oxigenoMgLCtrl = TextEditingController(text: '6.2');
  final _oxigenoPctCtrl = TextEditingController(text: '85.0');
  final _tempCtrl = TextEditingController(text: '28.5');
  final _phCtrl = TextEditingController(text: '7.4');
  final _amonioCtrl = TextEditingController(text: '0.15');
  final _nitritosCtrl = TextEditingController(text: '0.05');
  final _nitratosCtrl = TextEditingController(text: '10.0');
  final _alcalinidadCtrl = TextEditingController(text: '120.0');
  final _co2Ctrl = TextEditingController(text: '5.0');
  final _durezaCtrl = TextEditingController(text: '140.0');
  final _cloroCtrl = TextEditingController(text: '0.00');
  final _obsCtrl = TextEditingController();

  String? _selectedPondId;
  CivilDate _fechaMedicion = CivilDate.today();
  TimeOfDay _horaMedicion = TimeOfDay.now();

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

  @override
  Widget build(BuildContext context) {
    final pondsState = ref.watch(pondsProvider);
    final waterState = ref.watch(waterQualityProvider);
    final ponds = pondsState.ponds;

    if (_selectedPondId == null && ponds.isNotEmpty) {
      _selectedPondId = ponds.first.id;
    }

    final oxigeno = double.tryParse(_oxigenoMgLCtrl.text) ?? 6.2;
    final amonio = double.tryParse(_amonioCtrl.text) ?? 0.15;
    final nitritos = double.tryParse(_nitritosCtrl.text) ?? 0.05;
    final cloro = double.tryParse(_cloroCtrl.text) ?? 0.00;

    final isHypoxia = oxigeno < 4.0;
    final isAmmoniaCritical = amonio > 0.5;
    final isNitriteCritical = nitritos > 0.2;
    final isChlorineAlert = cloro > 0.05;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 520),
        child: GlassContainer(
          borderRadius: 24,
          padding: const EdgeInsets.all(22),
          blur: 24,
          opacity: 0.16,
          borderColor: AppColors.cyanWater.withValues(alpha: 0.35),
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
                              Text('💧 Calidad de Agua', style: AppTypography.titleMedium.copyWith(color: Colors.white, fontWeight: FontWeight.w800)),
                              const Text('Registro fisicoquímico integral', style: TextStyle(color: AppColors.textSecondaryDark, fontSize: 11)),
                            ],
                          ),
                        ],
                      ),
                      IconButton(
                        icon: const Icon(Icons.close_rounded, color: AppColors.textSecondaryDark),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  Text('ESTANQUE DE MEDICIÓN', style: AppTypography.labelMicro.copyWith(color: AppColors.textSecondaryDark)),
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.06),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: _selectedPondId,
                        dropdownColor: AppColors.surfaceDark,
                        isExpanded: true,
                        icon: const Icon(Icons.keyboard_arrow_down_rounded, color: AppColors.cyanWater),
                        items: ponds.map((p) {
                          return DropdownMenuItem<String>(
                            value: p.id,
                            child: Text('${p.nombre} (${p.sigla})', style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600)),
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
                          label: 'OXÍGENO (mg/L)',
                          controller: _oxigenoMgLCtrl,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          prefixIcon: Icons.air_rounded,
                          onChanged: (_) => setState(() {}),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: GlassFormField(
                          label: 'SATURACIÓN (%)',
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
                          label: 'TEMPERATURA (°C)',
                          controller: _tempCtrl,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          prefixIcon: Icons.thermostat_rounded,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: GlassFormField(
                          label: 'pH DEL AGUA',
                          controller: _phCtrl,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          prefixIcon: Icons.science_outlined,
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
                          if (isChlorineAlert) ...[
                            const SizedBox(height: 4),
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
                    isLoading: waterState.isLoading,
                    backgroundColor: AppColors.cyanWater,
                    onPressed: () async {
                      if (!_formKey.currentState!.validate() || _selectedPondId == null) return;

                      final authState = ref.read(authProvider);
                      final empresaId = authState.currentCompany?.id ?? authState.currentUser?.empresaId ?? 'c1000000-0000-0000-0000-000000000001';
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
                        oxigenoMgL: double.tryParse(_oxigenoMgLCtrl.text),
                        oxigenoPct: double.tryParse(_oxigenoPctCtrl.text),
                        ph: double.tryParse(_phCtrl.text),
                        temperaturaC: double.tryParse(_tempCtrl.text),
                        amonioMgL: double.tryParse(_amonioCtrl.text),
                        nitritosMgL: double.tryParse(_nitritosCtrl.text),
                        nitratosMgL: double.tryParse(_nitratosCtrl.text),
                        alcalinidadMgL: double.tryParse(_alcalinidadCtrl.text),
                        co2MgL: double.tryParse(_co2Ctrl.text),
                        durezaMgL: double.tryParse(_durezaCtrl.text),
                        cloroMgL: double.tryParse(_cloroCtrl.text),
                        observaciones: _obsCtrl.text.trim().isNotEmpty ? _obsCtrl.text.trim() : null,
                        registradoPor: authState.currentUser?.nombre,
                      );

                      final nav = Navigator.of(context);
                      final messenger = ScaffoldMessenger.of(context);

                      final success = await ref.read(waterQualityProvider.notifier).recordWaterQuality(param);
                      if (success && mounted) {
                        nav.pop();
                        messenger.showSnackBar(
                          const SnackBar(
                            content: Text('¡Medición registrada con éxito con 11 parámetros y hora de toma!'),
                            backgroundColor: AppColors.cyanWater,
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
