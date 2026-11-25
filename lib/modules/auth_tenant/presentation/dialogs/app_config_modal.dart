import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fishbit_finance/core/design_system/app_colors.dart';
import 'package:fishbit_finance/core/design_system/app_typography.dart';
import 'package:fishbit_finance/core/design_system/glass_container.dart';
import 'package:fishbit_finance/core/design_system/glass_form_field.dart';
import 'package:fishbit_finance/core/design_system/glass_button.dart';

import 'package:fishbit_finance/modules/auth_tenant/domain/models/company.dart';
import 'package:fishbit_finance/modules/auth_tenant/presentation/providers/auth_provider.dart';
import 'package:fishbit_finance/core/utils/currency_formatters.dart';

class AppConfigModal extends ConsumerStatefulWidget {
  const AppConfigModal({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => const AppConfigModal(),
    );
  }

  @override
  ConsumerState<AppConfigModal> createState() => _AppConfigModalState();
}

class _AppConfigModalState extends ConsumerState<AppConfigModal> {
  final _fcrCtrl = TextEditingController(text: '1.25');
  final _oxigenoMinCtrl = TextEditingController(text: '4.0');
  bool _notificacionesIca = true;
  bool _alertaSonoraSensores = true;
  bool _isSaving = false;

  final List<String> _todasEspecies = [
    'Tilapia Roja',
    'Cachama Blanca',
    'Bocachico',
    'Trucha Arcoíris',
    'Pangasius',
    'Camarón / Langostino',
  ];

  late List<String> _especiesSeleccionadas;
  final Map<String, TextEditingController> _pesosCosechaCtrls = {};

  @override
  void initState() {
    super.initState();
    final company = ref.read(authProvider).currentCompany;
    _especiesSeleccionadas = List<String>.from(company?.especiesHabilitadas ?? [
      'Tilapia Roja',
      'Cachama Blanca',
      'Bocachico',
      'Pangasius',
    ]);

    for (final sp in _todasEspecies) {
      final targetGrams = company != null
          ? company.getTargetHarvestWeightGrams(sp)
          : Company.defaultHarvestWeightForSpecies(sp);
      _pesosCosechaCtrls[sp] = TextEditingController(text: targetGrams.toInt().toString());
    }
  }

  @override
  void dispose() {
    _fcrCtrl.dispose();
    _oxigenoMinCtrl.dispose();
    for (final ctrl in _pesosCosechaCtrls.values) {
      ctrl.dispose();
    }
    super.dispose();
  }

  Future<void> _handleSave() async {
    setState(() => _isSaving = true);
    final authNotifier = ref.read(authProvider.notifier);
    final currentCompany = ref.read(authProvider).currentCompany;

    if (currentCompany != null) {
      final Map<String, dynamic> nuevosPesos = Map<String, dynamic>.from(currentCompany.pesosFinalesEspeciesG);
      for (final entry in _pesosCosechaCtrls.entries) {
        final val = double.tryParse(entry.value.text.trim());
        if (val != null && val > 0) {
          nuevosPesos[entry.key] = val;
        }
      }

      final updatedCompany = currentCompany.copyWith(
        especiesHabilitadas: _especiesSeleccionadas,
        pesosFinalesEspeciesG: nuevosPesos,
      );
      await authNotifier.updateCompany(updatedCompany);
    }

    if (mounted) {
      setState(() => _isSaving = false);
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('¡Configuraciones y especies habilitadas actualizadas con éxito!'),
          backgroundColor: AppColors.greenBiomass,
        ),
      );
    }
  }


  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => Navigator.of(context).pop(),
      child: GestureDetector(
        onTap: () {}, // Evitar que clics dentro cierren el modal
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 540),
            child: Container(
              decoration: BoxDecoration(
                color: AppColors.backgroundDark.withValues(alpha: 0.95),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
                border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
              ),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.25),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 18),

                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.cyanWater.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.tune_rounded, color: AppColors.cyanWater, size: 22),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Configuración de Piscícola', style: AppTypography.titleMedium.copyWith(color: Colors.white)),
                        Text('Parámetros biológicos, costos y alertas ICA', style: AppTypography.labelMicro.copyWith(color: AppColors.textSecondaryDark)),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // Sección 1: Especies Piscícolas Habilitadas
                Text('ESPECIES HABILITADAS EN ESTA EMPRESA', style: AppTypography.labelMicro.copyWith(color: AppColors.cyanWater, letterSpacing: 1.2)),
                const SizedBox(height: 6),
                Text('Marca las especies que tu granja cultiva para siembras y bitácoras:', style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondaryDark, fontSize: 11.5)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _todasEspecies.map((sp) {
                    final isSelected = _especiesSeleccionadas.contains(sp);
                    return FilterChip(
                      label: Text(sp, style: TextStyle(color: isSelected ? Colors.white : AppColors.textSecondaryDark, fontWeight: isSelected ? FontWeight.w800 : FontWeight.w500, fontSize: 12)),
                      selected: isSelected,
                      selectedColor: AppColors.cyanWater.withValues(alpha: 0.25),
                      checkmarkColor: AppColors.cyanWater,
                      backgroundColor: Colors.white.withValues(alpha: 0.05),
                      side: BorderSide(color: isSelected ? AppColors.cyanWater : Colors.white12),
                      onSelected: (val) {
                        setState(() {
                          if (val) {
                            _especiesSeleccionadas.add(sp);
                          } else {
                            if (_especiesSeleccionadas.length > 1) {
                              _especiesSeleccionadas.remove(sp);
                            }
                          }
                        });
                      },
                    );
                  }).toList(),
                ),
                const SizedBox(height: 14),

                // Sub-sección: Meta de Talla / Peso de Cosecha por Especie
                Text(
                  'META DE COSECHA POR ESPECIE (GRAMOS)',
                  style: AppTypography.labelMicro.copyWith(color: AppColors.greenBiomass, letterSpacing: 1.1),
                ),
                const SizedBox(height: 6),
                Text(
                  'Define el peso objetivo de cosecha para calibrar la barra de progreso en las tarjetas:',
                  style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondaryDark, fontSize: 11),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.04),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
                  ),
                  child: Column(
                    children: _especiesSeleccionadas.map((sp) {
                      final ctrl = _pesosCosechaCtrls[sp];
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Row(
                          children: [
                            Expanded(
                              flex: 3,
                              child: Text(
                                sp,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 12,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              flex: 2,
                              child: SizedBox(
                                height: 38,
                                child: TextField(
                                  controller: ctrl,
                                  keyboardType: TextInputType.number,
                                  textAlign: TextAlign.end,
                                  style: const TextStyle(
                                    color: AppColors.cyanWater,
                                    fontWeight: FontWeight.w800,
                                    fontSize: 13,
                                  ),
                                  decoration: InputDecoration(
                                    suffixText: ' g',
                                    suffixStyle: TextStyle(
                                      color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                                      fontSize: 11,
                                    ),
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                    filled: true,
                                    fillColor: Colors.white.withValues(alpha: 0.05),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(8),
                                      borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
                                    ),
                                    enabledBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(8),
                                      borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(8),
                                      borderSide: const BorderSide(color: AppColors.cyanWater),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                ),
                const SizedBox(height: 18),

                // Sección 2: Parámetros Biológicos
                Text('PARÁMETROS BIOLÓGICOS Y SANITARIOS', style: AppTypography.labelMicro.copyWith(color: AppColors.cyanWater, letterSpacing: 1.2)),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: GlassFormField(
                        label: 'FCR OBJETIVO',
                        hint: '1.25',
                        controller: _fcrCtrl,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        prefixIcon: Icons.restaurant_outlined,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: GlassFormField(
                        label: 'O₂ MÍNIMO CRÍTICO (mg/L)',
                        hint: '4.0',
                        controller: _oxigenoMinCtrl,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        prefixIcon: Icons.waves_rounded,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),


                // Sección 3: Preferencias y Cumplimiento
                Text('PREFERENCIAS Y CUMPLIMIENTO', style: AppTypography.labelMicro.copyWith(color: AppColors.amberWarning, letterSpacing: 1.2)),
                const SizedBox(height: 10),
                GlassContainer(
                  borderRadius: 16,
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  blur: 16,
                  opacity: 0.08,
                  child: Column(
                    children: [
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        activeThumbColor: AppColors.cyanWater,
                        title: const Text('Alertas Sanitarias ICA / AUNAP', style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600)),
                        subtitle: const Text('Notificar bitácoras y cambios de agua obligatorios', style: TextStyle(color: AppColors.textSecondaryDark, fontSize: 11)),
                        value: _notificacionesIca,
                        onChanged: (val) => setState(() => _notificacionesIca = val),
                      ),
                      const Divider(color: Colors.white10, height: 1),
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        activeThumbColor: AppColors.cyanWater,
                        title: const Text('Alarmas Críticas de Oxígeno', style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600)),
                        subtitle: const Text('Sonido y vibración cuando el oxígeno caiga a < 4.0 mg/L', style: TextStyle(color: AppColors.textSecondaryDark, fontSize: 11)),
                        value: _alertaSonoraSensores,
                        onChanged: (val) => setState(() => _alertaSonoraSensores = val),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                GlassButton(
                  label: 'Guardar Configuraciones',
                  isLoading: _isSaving,
                  backgroundColor: AppColors.cyanWater,
                  onPressed: _handleSave,
                ),
              ],
            ),
          ),
        ),
      ),
    ),
    ),
    );
  }
}
