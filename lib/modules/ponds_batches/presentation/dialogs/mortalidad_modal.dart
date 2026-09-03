import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fishbit_finance/core/design_system/app_colors.dart';
import 'package:fishbit_finance/core/design_system/app_typography.dart';
import 'package:fishbit_finance/core/design_system/glass_container.dart';
import 'package:fishbit_finance/core/design_system/glass_form_field.dart';
import 'package:fishbit_finance/core/design_system/glass_button.dart';
import 'package:fishbit_finance/core/design_system/glass_date_picker.dart';
import 'package:fishbit_finance/modules/auth_tenant/presentation/providers/auth_provider.dart';
import 'package:fishbit_finance/modules/ponds_batches/domain/models/fish_batch.dart';
import 'package:fishbit_finance/modules/ponds_batches/domain/models/pond.dart';
import 'package:fishbit_finance/modules/ponds_batches/presentation/providers/ponds_provider.dart';

class MortalidadModal extends ConsumerStatefulWidget {
  final Pond? pond;
  final FishBatch? batch;

  const MortalidadModal({super.key, this.pond, this.batch});

  static Future<void> show(BuildContext context, {Pond? pond, FishBatch? batch}) {
    return showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => MortalidadModal(pond: pond, batch: batch),
    );
  }

  @override
  ConsumerState<MortalidadModal> createState() => _MortalidadModalState();
}

class _MortalidadModalState extends ConsumerState<MortalidadModal> {
  final _formKey = GlobalKey<FormState>();
  final _muertosCtrl = TextEditingController(text: '5');
  late final TextEditingController _pesoCtrl;
  final _obsCtrl = TextEditingController();

  String _causaSeleccionada = 'Hipoxia / Bajo O2';
  String? _selectedPondId;
  String? _selectedBatchId;
  CivilDate _fechaRegistro = CivilDate.today();
  bool _isLoading = false;

  final List<String> _causas = [
    'Hipoxia / Bajo O2',
    'Bacteriosis / Columnaris',
    'Micosis / Hongos',
    'Trauma / Manejo en Desdoble',
    'Depredación / Aves',
    'Desconocida',
  ];

  @override
  void initState() {
    super.initState();
    _selectedPondId = widget.pond?.id;
    _selectedBatchId = widget.batch?.id;
    _pesoCtrl = TextEditingController(
      text: (widget.batch?.pesoActualGramos ?? 250.0).toStringAsFixed(1),
    );
  }

  @override
  void dispose() {
    _muertosCtrl.dispose();
    _pesoCtrl.dispose();
    _obsCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final pondsState = ref.watch(pondsProvider);
    final authState = ref.watch(authProvider);
    final user = authState.currentUser;

    // Estanque y lote activo
    final pondsList = pondsState.ponds.where((p) => p.estado == PondStatus.active).toList();
    final activePond = widget.pond ??
        (pondsList.where((p) => p.id == _selectedPondId).firstOrNull ?? (pondsList.isNotEmpty ? pondsList.first : null));
    final activeBatches = activePond != null
        ? pondsState.batches.where((b) => b.estanqueId == activePond.id && b.estado == BatchStatus.active).toList()
        : <FishBatch>[];
    final activeBatch = widget.batch ??
        (activeBatches.where((b) => b.id == _selectedBatchId).firstOrNull ?? activeBatches.firstOrNull);

    final muertos = int.tryParse(_muertosCtrl.text) ?? 0;
    final pesoG = double.tryParse(_pesoCtrl.text) ?? (activeBatch?.pesoActualGramos ?? 250.0);
    final biomasaPerdidaKg = (muertos * pesoG) / 1000.0;
    final poblacionPrevia = activeBatch?.cantidadActualPeces ?? 1000;
    final nuevaPoblacion = (poblacionPrevia - muertos).clamp(0, 9999999);
    final tasaMortalidadPct = poblacionPrevia > 0 ? (muertos / poblacionPrevia) * 100.0 : 0.0;
    final esAlertaCritica = tasaMortalidadPct >= 2.0;

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
          borderColor: esAlertaCritica ? AppColors.coralAction : AppColors.amberWarning.withValues(alpha: 0.4),
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
                              color: AppColors.coralAction.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(Icons.warning_amber_rounded, color: AppColors.coralAction, size: 20),
                          ),
                          const SizedBox(width: 10),
                          Text(
                            'Registro de Mortalidad',
                            style: AppTypography.titleMedium.copyWith(color: Colors.white, fontWeight: FontWeight.w800),
                          ),
                        ],
                      ),
                      IconButton(
                        icon: const Icon(Icons.close_rounded, color: AppColors.textSecondaryDark),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Selector de Estanque si no se abrió desde uno específico
                  if (widget.pond == null && pondsList.isNotEmpty) ...[
                    Text('ESTANQUE CON BAJAS', style: AppTypography.labelMicro.copyWith(color: AppColors.textSecondaryDark)),
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
                          value: activePond?.id,
                          isExpanded: true,
                          dropdownColor: AppColors.backgroundDark,
                          items: pondsList.map((p) {
                            return DropdownMenuItem(
                              value: p.id,
                              child: Text(
                                '${p.sigla} - ${p.nombre} (${p.especieActual})',
                                style: const TextStyle(color: Colors.white, fontSize: 13),
                              ),
                            );
                          }).toList(),
                          onChanged: (val) {
                            setState(() {
                              _selectedPondId = val;
                              final batch = pondsState.batches.where((b) => b.estanqueId == val).firstOrNull;
                              if (batch != null) {
                                _pesoCtrl.text = batch.pesoActualGramos.toStringAsFixed(1);
                              }
                            });
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],

                  // Detalle Destacado del Lote y Especie
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.coralAction.withValues(alpha: 0.10),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: AppColors.coralAction.withValues(alpha: 0.35)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                'LOTE: ${activeBatch?.codigoLote ?? "ACTIVO"}',
                                style: const TextStyle(color: AppColors.coralAction, fontWeight: FontWeight.w900, fontSize: 12.5),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: AppColors.coralAction.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                activeBatch?.especie ?? activePond?.especieActual ?? 'Tilapia Roja',
                                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 11),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                'Estanque: ${activePond?.nombreLimpio ?? "Estanque"} (${activePond?.sigla ?? ""})',
                                style: const TextStyle(color: Colors.white70, fontSize: 11.5),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Población: $poblacionPrevia peces',
                              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 11.5),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Selector de Lote / Especie si el estanque está en Policultivo
                  if (activeBatches.length > 1) ...[
                    Text('SELECCIONAR LOTE / ESPECIE (POLICULTIVO)', style: AppTypography.labelMicro.copyWith(color: Colors.purpleAccent, letterSpacing: 1.2)),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        color: Colors.purpleAccent.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: Colors.purpleAccent.withValues(alpha: 0.35)),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: activeBatch?.id,
                          dropdownColor: AppColors.backgroundDark,
                          isExpanded: true,
                          icon: const Icon(Icons.keyboard_arrow_down_rounded, color: Colors.purpleAccent),
                          items: activeBatches.map((b) {
                            return DropdownMenuItem<String>(
                              value: b.id,
                              child: Text(
                                '${b.especie} (${b.codigoLote}) • ${b.cantidadActualPeces} peces vivos',
                                style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w700),
                              ),
                            );
                          }).toList(),
                          onChanged: (val) {
                            setState(() {
                              _selectedBatchId = val;
                              final b = activeBatches.where((batch) => batch.id == val).firstOrNull;
                              if (b != null) {
                                _pesoCtrl.text = b.pesoActualGramos.toStringAsFixed(1);
                              }
                            });
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                  ],
                  Row(
                    children: [
                      Expanded(
                        child: GlassFormField(
                          label: 'PECES MUERTOS RETIRADOS',
                          hint: '0',
                          controller: _muertosCtrl,
                          keyboardType: TextInputType.number,
                          onChanged: (_) => setState(() {}),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: GlassFormField(
                          label: 'PESO PROM. (g)',
                          hint: '250',
                          controller: _pesoCtrl,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          onChanged: (_) => setState(() {}),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),

                  // Causa Probable
                  Text('CAUSA PROBABLE / DIAGNÓSTICO', style: AppTypography.labelMicro.copyWith(color: AppColors.textSecondaryDark)),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: _causas.map((c) {
                      final isSel = c == _causaSeleccionada;
                      return ChoiceChip(
                        label: Text(c, style: TextStyle(fontSize: 11, color: isSel ? Colors.black : Colors.white, fontWeight: FontWeight.w700)),
                        selected: isSel,
                        selectedColor: AppColors.coralAction,
                        backgroundColor: Colors.white.withValues(alpha: 0.06),
                        onSelected: (val) => setState(() => _causaSeleccionada = c),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 14),

                  // Impacto Biométrico & Alerta
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: esAlertaCritica
                          ? AppColors.coralAction.withValues(alpha: 0.15)
                          : Colors.white.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: esAlertaCritica ? AppColors.coralAction.withValues(alpha: 0.5) : Colors.white.withValues(alpha: 0.1),
                      ),
                    ),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Biomasa Perdida:', style: TextStyle(color: AppColors.textSecondaryDark, fontSize: 12)),
                            Text('-${biomasaPerdidaKg.toStringAsFixed(2)} kg', style: const TextStyle(color: AppColors.coralAction, fontWeight: FontWeight.w900, fontSize: 13)),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Población Remanente:', style: TextStyle(color: AppColors.textSecondaryDark, fontSize: 12)),
                            Text('$nuevaPoblacion peces vivos', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 13)),
                          ],
                        ),
                        if (esAlertaCritica) ...[
                          const SizedBox(height: 8),
                          const Row(
                            children: [
                              Icon(Icons.report_problem_rounded, color: AppColors.coralAction, size: 16),
                              SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  '¡Alerta Sanitaria!: Tasa supera el 2.0%. Verificar oxígeno disuelto y recambio de agua.',
                                  style: TextStyle(color: AppColors.coralAction, fontSize: 11, fontWeight: FontWeight.w700),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),

                  GlassDatePickerField(
                    label: 'FECHA DEL REGISTRO',
                    initialDate: _fechaRegistro,
                    accentColor: AppColors.coralAction,
                    onDateChanged: (d) => setState(() => _fechaRegistro = d),
                  ),
                  const SizedBox(height: 14),

                  // Observaciones
                  GlassFormField(
                    label: 'OBSERVACIONES SANITARIAS (OPCIONAL)',
                    hint: 'Ej: Peces boqueando en la superficie por lluvia...',
                    controller: _obsCtrl,
                  ),
                  const SizedBox(height: 18),

                  // Botón de Confirmación
                  GlassButton(
                    label: 'Confirmar Registro de Mortalidad',
                    height: 46,
                    backgroundColor: AppColors.coralAction,
                    isLoading: _isLoading,
                    onPressed: (activePond == null || activeBatch == null || muertos <= 0)
                        ? null
                        : () async {
                            final nav = Navigator.of(context);
                            final messenger = ScaffoldMessenger.of(context);
                            setState(() => _isLoading = true);
                            final ok = await ref.read(pondsProvider.notifier).recordMortality(
                                  estanqueId: activePond.id,
                                  loteId: activeBatch.id,
                                  cantidadPecesMuertos: muertos,
                                  pesoPromedioGramos: pesoG,
                                  causaProbable: _causaSeleccionada,
                                  biomasaPerdidaKg: biomasaPerdidaKg,
                                  fecha: _fechaRegistro.toDateTime(),
                                  observaciones: _obsCtrl.text.trim().isEmpty ? null : _obsCtrl.text.trim(),
                                  registradoPor: user?.nombre,
                                );
                            if (mounted) {
                              setState(() => _isLoading = false);
                              if (ok) {
                                nav.pop();
                                messenger.showSnackBar(
                                  SnackBar(
                                    content: Text('Mortalidad registrada en ${activePond.sigla} (-$muertos peces). Biomasa recalculada.'),
                                    backgroundColor: AppColors.coralAction,
                                  ),
                                );
                              }
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
