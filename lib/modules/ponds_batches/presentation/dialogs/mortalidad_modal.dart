import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fishbit_finance/core/design_system/app_colors.dart';
import 'package:fishbit_finance/core/design_system/app_typography.dart';
import 'package:fishbit_finance/core/design_system/glass_container.dart';
import 'package:fishbit_finance/core/design_system/glass_form_field.dart';
import 'package:fishbit_finance/core/design_system/glass_button.dart';
import 'package:fishbit_finance/core/design_system/glass_date_picker.dart';
import 'package:fishbit_finance/core/design_system/glass_select_field.dart';
import 'package:fishbit_finance/modules/auth_tenant/presentation/providers/auth_provider.dart';
import 'package:fishbit_finance/modules/ponds_batches/domain/models/fish_batch.dart';
import 'package:fishbit_finance/modules/ponds_batches/domain/models/mortality_record.dart';
import 'package:fishbit_finance/modules/ponds_batches/domain/models/pond.dart';
import 'package:fishbit_finance/modules/ponds_batches/presentation/providers/ponds_provider.dart';

class MortalidadModal extends ConsumerStatefulWidget {
  final Pond? pond;
  final FishBatch? batch;
  final MortalityRecord? recordToEdit;

  const MortalidadModal({super.key, this.pond, this.batch, this.recordToEdit});

  static Future<void> show(
    BuildContext context, {
    Pond? pond,
    FishBatch? batch,
    MortalityRecord? recordToEdit,
  }) {
    return showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => MortalidadModal(
        pond: pond,
        batch: batch,
        recordToEdit: recordToEdit,
      ),
    );
  }

  @override
  ConsumerState<MortalidadModal> createState() => _MortalidadModalState();
}

class _MortalidadModalState extends ConsumerState<MortalidadModal> {
  final _formKey = GlobalKey<FormState>();
  final _muertosCtrl = TextEditingController();
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
    final edit = widget.recordToEdit;
    if (edit != null) {
      _selectedPondId = edit.estanqueId;
      _selectedBatchId = edit.loteId;
      _muertosCtrl.text = edit.cantidadPecesMuertos.toString();
      _pesoCtrl = TextEditingController(text: edit.pesoPromedioGramos.toStringAsFixed(1));
      if (edit.causaProbable.trim().isNotEmpty) {
        if (!_causas.contains(edit.causaProbable)) {
          _causas.insert(0, edit.causaProbable);
        }
        _causaSeleccionada = edit.causaProbable;
      }
      if (edit.observaciones != null) _obsCtrl.text = edit.observaciones!;
      _fechaRegistro = CivilDate.fromDate(edit.fecha);
    } else {
      _selectedPondId = widget.pond?.id;
      _selectedBatchId = widget.batch?.id;
      final batchWeight = widget.batch?.pesoActualGramos;
      _pesoCtrl = TextEditingController(
        text: (batchWeight != null && batchWeight > 0) ? batchWeight.toStringAsFixed(1) : '',
      );
    }
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
    final isEditing = widget.recordToEdit != null;
    final editRecord = widget.recordToEdit;
    final pondsState = ref.watch(pondsProvider);
    final authState = ref.watch(authProvider);
    final user = authState.currentUser;

    // Estanque y lote (en edición buscar también históricos aunque ya no estén activos)
    final pondsList = pondsState.ponds.where((p) => p.estado == PondStatus.active).toList();
    final effectivePondId = _selectedPondId ?? widget.pond?.id;
    final activePond = (isEditing
            ? pondsState.ponds.where((p) => p.id == effectivePondId).firstOrNull
            : pondsList.where((p) => p.id == effectivePondId).firstOrNull) ??
        widget.pond ??
        (pondsList.isNotEmpty ? pondsList.first : null);
    final activeBatches = activePond != null
        ? pondsState.batches.where((b) => b.estanqueId == activePond.id && b.estado == BatchStatus.active).toList()
        : <FishBatch>[];
    final activeBatch = widget.batch ??
        (isEditing
            ? pondsState.batches.where((b) => b.id == editRecord!.loteId).firstOrNull
            : (activeBatches.where((b) => b.id == _selectedBatchId).firstOrNull ?? activeBatches.firstOrNull));

    final muertos = int.tryParse(_muertosCtrl.text.trim()) ?? 0;
    final pesoG = double.tryParse(_pesoCtrl.text.replaceAll(',', '.').trim()) ?? (activeBatch?.pesoActualGramos ?? 0.0);
    final biomasaPerdidaKg = (muertos * pesoG) / 1000.0;
    final poblacionPrevia = activeBatch?.cantidadActualPeces ?? 0;
    final poblacionDisponible = poblacionPrevia + (editRecord?.cantidadPecesMuertos ?? 0);
    final bool aumentoBajas = !isEditing || muertos > editRecord!.cantidadPecesMuertos;
    final superacionPoblacion = aumentoBajas && poblacionDisponible > 0 && muertos > poblacionDisponible;
    final nuevaPoblacion = (poblacionDisponible - muertos).clamp(0, 9999999);
    final tasaMortalidadPct = poblacionDisponible > 0 ? (muertos / poblacionDisponible) * 100.0 : 0.0;
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
                            widget.recordToEdit != null ? 'Editar Mortalidad' : 'Registro de Mortalidad',
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

                  // Selector de Estanque si no es edición
                  if (widget.recordToEdit == null && pondsList.isNotEmpty) ...[
                    GlassSelectField<String>(
                      label: 'ESTANQUE CON BAJAS',
                      value: activePond?.id,
                      accentColor: AppColors.coralAction,
                      leadingIcon: Icons.waves_rounded,
                      options: pondsList
                          .map((p) => GlassSelectOption<String>(
                                value: p.id,
                                label: '${p.sigla} - ${p.nombre}',
                                subtitle: p.especieActual,
                                icon: Icons.waves_rounded,
                              ))
                          .toList(),
                      onChanged: (val) {
                        setState(() {
                          _selectedPondId = val;
                          _selectedBatchId = null;
                          final batch = pondsState.batches.where((b) => b.estanqueId == val && b.estado == BatchStatus.active).firstOrNull;
                          if (batch != null) {
                            _pesoCtrl.text = batch.pesoActualGramos.toStringAsFixed(1);
                          }
                        });
                      },
                    ),
                    const SizedBox(height: 12),
                  ],

                  if (isEditing) ...[
                    Container(
                      padding: const EdgeInsets.all(11),
                      decoration: BoxDecoration(
                        color: AppColors.cyanWater.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.cyanWater.withValues(alpha: 0.35)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.edit_note_rounded, color: AppColors.cyanWater, size: 18),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Modo Edición: actualizando reporte del ${editRecord!.fecha.day}/${editRecord.fecha.month}/${editRecord.fecha.year} (${editRecord.cantidadPecesMuertos} bajas). No se creará un dato nuevo.',
                              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 11.5),
                            ),
                          ),
                        ],
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
                    GlassSelectField<String>(
                      label: 'SELECCIONAR LOTE / ESPECIE (POLICULTIVO)',
                      value: activeBatch?.id,
                      accentColor: Colors.purpleAccent,
                      leadingIcon: Icons.set_meal_rounded,
                      options: activeBatches
                          .map((b) => GlassSelectOption<String>(
                                value: b.id,
                                label: '${b.especie} (${b.codigoLote})',
                                subtitle: '${b.cantidadActualPeces} peces vivos',
                                icon: Icons.set_meal_rounded,
                              ))
                          .toList(),
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
                    const SizedBox(height: 14),
                  ],
                  Row(
                    children: [
                      Expanded(
                        child: GlassFormField(
                          label: 'PECES MUERTOS RETIRADOS',
                          hint: 'Ej: 5',
                          controller: _muertosCtrl,
                          keyboardType: TextInputType.number,
                          validator: (val) {
                            final n = int.tryParse(val?.trim() ?? '');
                            if (n == null || n <= 0) return 'Ingresa bajas (> 0)';
                            final aumenta = !isEditing || n > editRecord!.cantidadPecesMuertos;
                            if (aumenta && poblacionDisponible <= 0) {
                              return 'Lote sin peces vivos';
                            }
                            if (aumenta && n > poblacionDisponible) {
                              return 'Supera población ($poblacionDisponible)';
                            }
                            return null;
                          },
                          onChanged: (_) => setState(() {}),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: GlassFormField(
                          label: 'PESO PROM. (g)',
                          hint: 'Ej: 250',
                          controller: _pesoCtrl,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          validator: (val) {
                            final p = double.tryParse(val?.replaceAll(',', '.').trim() ?? '');
                            if (p == null || p <= 0) return 'Ingresa peso (> 0)';
                            return null;
                          },
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
                        if (superacionPoblacion) ...[
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              const Icon(Icons.error_outline_rounded, color: AppColors.coralAction, size: 16),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  'Error: La cantidad de bajas ($muertos) supera la población disponible en el lote ($poblacionDisponible peces).',
                                  style: const TextStyle(color: AppColors.coralAction, fontSize: 11, fontWeight: FontWeight.w800),
                                ),
                              ),
                            ],
                          ),
                        ] else if (esAlertaCritica) ...[
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
                    label: isEditing
                        ? 'Actualizar Registro de Mortalidad'
                        : 'Confirmar Registro de Mortalidad',
                    loadingLabel: isEditing ? 'Actualizando...' : 'Guardando...',
                    height: 46,
                    backgroundColor: AppColors.coralAction,
                    isLoading: _isLoading,
                    onPressed: () async {
                      if (_isLoading) return;
                      final messenger = ScaffoldMessenger.of(context);
                      if (!isEditing && (activePond == null || activeBatch == null)) {
                        messenger.showSnackBar(
                          const SnackBar(
                            content: Text('Seleccione un estanque con lote activo para registrar la mortalidad.'),
                            backgroundColor: AppColors.coralAction,
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                        return;
                      }
                      if (!_formKey.currentState!.validate() || muertos <= 0 || superacionPoblacion) {
                        messenger.showSnackBar(
                          SnackBar(
                            content: Text(
                              superacionPoblacion
                                  ? 'La cantidad de bajas ($muertos) supera la población disponible ($poblacionDisponible peces).'
                                  : 'Complete la cantidad de peces muertos y el peso promedio.',
                            ),
                            backgroundColor: AppColors.coralAction,
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                        return;
                      }

                      final nav = Navigator.of(context);
                      setState(() => _isLoading = true);

                      final bool ok;
                      if (isEditing) {
                        final obsText = _obsCtrl.text.trim();
                        final updated = editRecord!.copyWith(
                          cantidadPecesMuertos: muertos,
                          pesoPromedioGramos: pesoG,
                          causaProbable: _causaSeleccionada,
                          biomasaPerdidaKg: biomasaPerdidaKg,
                          fecha: _fechaRegistro.toDateTime(),
                          observaciones: obsText.isEmpty ? null : obsText,
                          clearObservaciones: obsText.isEmpty,
                        );
                        ok = await ref.read(pondsProvider.notifier).updateMortality(editRecord, updated);
                      } else {
                        ok = await ref.read(pondsProvider.notifier).recordMortality(
                              estanqueId: activePond!.id,
                              loteId: activeBatch!.id,
                              cantidadPecesMuertos: muertos,
                              pesoPromedioGramos: pesoG,
                              causaProbable: _causaSeleccionada,
                              biomasaPerdidaKg: biomasaPerdidaKg,
                              fecha: _fechaRegistro.toDateTime(),
                              observaciones: _obsCtrl.text.trim().isEmpty ? null : _obsCtrl.text.trim(),
                              registradoPor: user?.nombre,
                            );
                      }

                      if (mounted) {
                        setState(() => _isLoading = false);
                        if (ok) {
                          nav.pop();
                          messenger.showSnackBar(
                            SnackBar(
                              content: Text(
                                isEditing
                                    ? 'Mortalidad actualizada ($muertos peces). Datos sincronizados.'
                                    : 'Mortalidad registrada en ${activePond!.sigla} (-$muertos peces). Biomasa recalculada.',
                              ),
                              backgroundColor: AppColors.coralAction,
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        } else {
                          messenger.showSnackBar(
                            SnackBar(
                              content: Text('Error al guardar mortalidad: ${ref.read(pondsProvider).errorMessage ?? "Verifique su conexión"}'),
                              backgroundColor: AppColors.coralAction,
                              behavior: SnackBarBehavior.floating,
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
