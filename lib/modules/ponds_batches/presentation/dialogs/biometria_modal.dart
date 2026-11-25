import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fishbit_finance/core/design_system/app_colors.dart';
import 'package:fishbit_finance/core/design_system/app_typography.dart';
import 'package:fishbit_finance/core/design_system/glass_container.dart';
import 'package:fishbit_finance/core/design_system/glass_form_field.dart';
import 'package:fishbit_finance/core/design_system/glass_button.dart';
import 'package:fishbit_finance/core/design_system/glass_date_picker.dart';
import 'package:fishbit_finance/core/design_system/glass_select_field.dart';
import 'package:fishbit_finance/modules/ponds_batches/domain/models/biometria_record.dart';
import 'package:fishbit_finance/modules/ponds_batches/domain/models/fish_batch.dart';
import 'package:fishbit_finance/modules/ponds_batches/domain/models/pond.dart';
import 'package:fishbit_finance/modules/ponds_batches/presentation/providers/ponds_provider.dart';

class BiometriaModal extends ConsumerStatefulWidget {
  final Pond? pond;
  final FishBatch? batch;
  final BiometriaRecord? recordToEdit;

  const BiometriaModal({super.key, this.pond, this.batch, this.recordToEdit});

  static Future<void> show(
    BuildContext context, {
    Pond? pond,
    FishBatch? batch,
    BiometriaRecord? recordToEdit,
  }) {
    return showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => BiometriaModal(
        pond: pond,
        batch: batch,
        recordToEdit: recordToEdit,
      ),
    );
  }

  @override
  ConsumerState<BiometriaModal> createState() => _BiometriaModalState();
}

class _BiometriaModalState extends ConsumerState<BiometriaModal> {
  final _formKey = GlobalKey<FormState>();
  final _pecesCapturadosCtrl = TextEditingController();
  late final TextEditingController _pesoTotalCapturaKgCtrl;
  final _longitudCtrl = TextEditingController();
  final _obsCtrl = TextEditingController();

  String? _selectedPondId;
  String? _selectedBatchId;
  CivilDate _fechaMuestreo = CivilDate.today();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    final edit = widget.recordToEdit;
    _pesoTotalCapturaKgCtrl = TextEditingController();
    if (edit != null) {
      _selectedPondId = edit.estanqueId;
      _selectedBatchId = edit.loteId;
      _pecesCapturadosCtrl.text = edit.pecesCapturados.toString();
      _pesoTotalCapturaKgCtrl.text = edit.pesoTotalCapturaKg.toStringAsFixed(2);
      if (edit.longitudCm != null && edit.longitudCm! > 0) {
        _longitudCtrl.text = edit.longitudCm!.toStringAsFixed(1);
      }
      if (edit.observaciones != null) {
        _obsCtrl.text = edit.observaciones!;
      }
      _fechaMuestreo = CivilDate.fromDate(edit.fecha);
    } else {
      _selectedPondId = widget.pond?.id;
      _selectedBatchId = widget.batch?.id;
    }
  }

  @override
  void dispose() {
    _pesoTotalCapturaKgCtrl.dispose();
    _pecesCapturadosCtrl.dispose();
    _longitudCtrl.dispose();
    _obsCtrl.dispose();
    super.dispose();
  }

  String _getRecommendedPelletAndProtein(double pesoG) {
    if (pesoG <= 20) return 'Iniciador 45% PB • Pellet 1.0 - 1.2 mm';
    if (pesoG <= 60) return 'Levante I 38% PB • Pellet 1.5 - 2.0 mm';
    if (pesoG <= 150) return 'Levante II 34% PB • Pellet 2.5 - 3.0 mm';
    if (pesoG <= 350) return 'Engorde I 30% PB • Pellet 3.5 - 4.0 mm';
    return 'Engorde Final 28% PB • Pellet 4.5 - 5.0 mm';
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.recordToEdit != null;
    final editRecord = widget.recordToEdit;
    final pondsState = ref.watch(pondsProvider);
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

    final pesoCapturaKg = double.tryParse(_pesoTotalCapturaKgCtrl.text.replaceAll(',', '.').trim()) ?? 0.0;
    final pecesCapturados = int.tryParse(_pecesCapturadosCtrl.text.trim()) ?? 0;
    final bool hasValidSample = pecesCapturados > 0 && pesoCapturaKg > 0;
    final pesoCapturaGramos = pesoCapturaKg * 1000.0;
    final pesoPromedioGramos = hasValidSample ? (pesoCapturaGramos / pecesCapturados) : 0.0;

    final pesoAnteriorG = activeBatch?.pesoActualGramos ?? 0.0;
    final pecesVivos = activeBatch?.cantidadActualPeces ?? 0;
    final bool sampleUnchangedInEdit = isEditing &&
        pecesCapturados == editRecord!.pecesCapturados &&
        (pesoCapturaKg - editRecord.pesoTotalCapturaKg).abs() < 0.001;
    final biomasaParcialKg = sampleUnchangedInEdit
        ? editRecord.biomasaParcialKg
        : (pecesVivos * pesoPromedioGramos) / 1000.0;
    final gananciaPesoG = hasValidSample ? (pesoPromedioGramos - pesoAnteriorG) : 0.0;

    final capacidadM3 = activePond?.capacidadM3 ?? 0.0;
    final nuevaDensidadKgM3 = capacidadM3 > 0 ? (biomasaParcialKg / capacidadM3) : 0.0;
    final densidadPecesM3 = capacidadM3 > 0 ? (pecesVivos / capacidadM3) : 0.0;

    // Cálculo GDP (Ganancia Diaria de Peso) respecto a la fecha del muestreo, no a DateTime.now()
    final int diasDesdeSiembra = activeBatch != null
        ? _fechaMuestreo.toDateTime().difference(activeBatch.fechaSiembra).inDays
        : 30;
    final dias = diasDesdeSiembra > 0 ? diasDesdeSiembra : 1;
    final gdp = (pesoPromedioGramos - (activeBatch?.pesoInicialGramos ?? 1.0)) / dias;

    // Factor K de Fulton (si se ingresa longitud en cm)
    final longitudCm = double.tryParse(_longitudCtrl.text.replaceAll(',', '.').trim());
    final factorK = (longitudCm != null && longitudCm > 0) ? (100.0 * pesoPromedioGramos / (longitudCm * longitudCm * longitudCm)) : null;

    final recomendacionNutricional = _getRecommendedPelletAndProtein(pesoPromedioGramos);

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
          borderColor: AppColors.cyanWater.withValues(alpha: 0.35),
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
                              color: AppColors.cyanWater.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(Icons.scale_rounded, color: AppColors.cyanWater, size: 20),
                          ),
                          const SizedBox(width: 10),
                          Text(
                            widget.recordToEdit != null ? 'Editar Muestreo Biométrico' : 'Muestreo Biométrico',
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
                      label: 'ESTANQUE MUESTREADO',
                      value: activePond?.id,
                      accentColor: AppColors.cyanWater,
                      leadingIcon: Icons.waves_rounded,
                      options: pondsList
                          .map((p) => GlassSelectOption<String>(
                                value: p.id,
                                label: '${p.sigla} - ${p.nombre}',
                                subtitle: '${p.biomasaKg.toInt()} kg',
                                icon: Icons.waves_rounded,
                              ))
                          .toList(),
                      onChanged: (val) => setState(() {
                        _selectedPondId = val;
                        _selectedBatchId = null;
                      }),
                    ),
                    const SizedBox(height: 12),
                  ] else if (activePond != null) ...[
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.05),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              'Estanque: ${activePond.nombre}',
                              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 12.5),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text('Población: $pecesVivos peces', style: const TextStyle(color: AppColors.cyanWater, fontWeight: FontWeight.w800, fontSize: 12)),
                        ],
                      ),
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
                              'Modo Edición: actualizando muestreo del ${editRecord!.fecha.day}/${editRecord.fecha.month}/${editRecord.fecha.year} (${editRecord.pesoPromedioG.toStringAsFixed(1)} g). No se creará un dato nuevo.',
                              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 11.5),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],

                  // Selector de Lote / Especie si el estanque está en Policultivo
                  if (!isEditing && activeBatches.length > 1) ...[
                    GlassSelectField<String>(
                      label: 'ESPECIE / LOTE A MUESTREAR (POLICULTIVO)',
                      value: activeBatch?.id,
                      accentColor: Colors.purpleAccent,
                      leadingIcon: Icons.set_meal_rounded,
                      options: activeBatches
                          .map((b) => GlassSelectOption<String>(
                                value: b.id,
                                label: '${b.especie} (${b.codigoLote})',
                                subtitle: 'Peso actual: ${b.pesoActualGramos.toStringAsFixed(1)} g',
                                icon: Icons.set_meal_rounded,
                              ))
                          .toList(),
                      onChanged: (val) => setState(() => _selectedBatchId = val),
                    ),
                    const SizedBox(height: 14),
                  ],

                  // Campos de Muestreo: Peces Capturados y Peso Total Captura (kg)
                  Row(
                    children: [
                      Expanded(
                        child: GlassFormField(
                          label: 'PECES CAPTURADOS (RED)',
                          hint: 'Ej: 35',
                          controller: _pecesCapturadosCtrl,
                          keyboardType: TextInputType.number,
                          validator: (val) {
                            final n = int.tryParse(val?.trim() ?? '');
                            if (n == null || n <= 0) return 'Ingresa peces (> 0)';
                            if (!isEditing) {
                              if (pecesVivos <= 0) return 'Lote sin peces vivos';
                              if (n > pecesVivos) return 'Supera población ($pecesVivos)';
                            }
                            return null;
                          },
                          onChanged: (_) => setState(() {}),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: GlassFormField(
                          label: 'PESO TOTAL CAPTURA (kg)',
                          hint: 'Ej: 8.75',
                          controller: _pesoTotalCapturaKgCtrl,
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
                  const SizedBox(height: 12),

                  // Tarjetas Destacadas: Peso Promedio Resultante y Biomasa Parcial
                  Row(
                    children: [
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppColors.cyanWater.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: AppColors.cyanWater.withValues(alpha: 0.35)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('PESO PROM. CALCULADO', style: TextStyle(color: AppColors.cyanWater, fontSize: 10.5, fontWeight: FontWeight.w800, letterSpacing: 0.8)),
                              const SizedBox(height: 4),
                              FittedBox(
                                fit: BoxFit.scaleDown,
                                alignment: Alignment.centerLeft,
                                child: Text(
                                  hasValidSample ? '${pesoPromedioGramos.toStringAsFixed(1)} g' : '-- g',
                                  style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w900),
                                ),
                              ),
                              Text(
                                hasValidSample ? '${pesoCapturaKg.toStringAsFixed(2)} kg ÷ $pecesCapturados peces' : '-- kg ÷ -- peces',
                                style: const TextStyle(color: Colors.white60, fontSize: 10),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppColors.greenBiomass.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: AppColors.greenBiomass.withValues(alpha: 0.35)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('BIOMASA ESTIMADA', style: TextStyle(color: AppColors.greenBiomass, fontSize: 10.5, fontWeight: FontWeight.w800, letterSpacing: 0.8)),
                              const SizedBox(height: 4),
                              FittedBox(
                                fit: BoxFit.scaleDown,
                                alignment: Alignment.centerLeft,
                                child: Text(
                                  hasValidSample ? '${biomasaParcialKg.toStringAsFixed(1)} kg' : '-- kg',
                                  style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w900),
                                ),
                              ),
                              Text(
                                hasValidSample ? 'En $pecesVivos peces vivos' : 'Requiere pesaje de muestra',
                                style: const TextStyle(color: Colors.white60, fontSize: 10),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Longitud opcional para Factor K
                  GlassFormField(
                    label: 'TALLA / LONGITUD PROM. (cm) - OPCIONAL',
                    hint: 'Ej: 22.5',
                    controller: _longitudCtrl,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    onChanged: (_) => setState(() {}),
                  ),
                  const SizedBox(height: 14),

                  // Métricas Biométricas Complementarias
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.04),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: AppColors.cyanWater.withValues(alpha: 0.25)),
                    ),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Ganancia de Peso:', style: TextStyle(color: AppColors.textSecondaryDark, fontSize: 12)),
                            Text('${gananciaPesoG >= 0 ? "+" : ""}${gananciaPesoG.toStringAsFixed(1)} g',
                                style: TextStyle(
                                  color: gananciaPesoG >= 0 ? AppColors.greenBiomass : AppColors.coralAction,
                                  fontWeight: FontWeight.w900,
                                  fontSize: 13,
                                )),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('GDP Acumulado (g/día):', style: TextStyle(color: AppColors.textSecondaryDark, fontSize: 12)),
                            Text('${gdp.toStringAsFixed(2)} g/día', style: const TextStyle(color: AppColors.cyanWater, fontWeight: FontWeight.w800, fontSize: 13)),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Densidad Resultante por m³:', style: TextStyle(color: AppColors.textSecondaryDark, fontSize: 12)),
                            Text(
                              '${nuevaDensidadKgM3.toStringAsFixed(2)} kg/m³ (${densidadPecesM3.toStringAsFixed(1)} pcs/m³)',
                              style: TextStyle(
                                color: nuevaDensidadKgM3 < 8.0
                                    ? AppColors.purpleAnalytics
                                    : (nuevaDensidadKgM3 <= 16.0 ? AppColors.amberWarning : AppColors.coralAction),
                                fontWeight: FontWeight.w800,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                        if (factorK != null) ...[
                          const SizedBox(height: 4),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('Factor de Condición K (Fulton):', style: TextStyle(color: AppColors.textSecondaryDark, fontSize: 12)),
                              Text('${factorK.toStringAsFixed(2)} (${factorK >= 1.6 ? "Excelente" : "Normal"})',
                                  style: const TextStyle(color: AppColors.amberWarning, fontWeight: FontWeight.w800, fontSize: 12)),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Recomendación de Pellet y Proteína (solo en nuevo muestreo)
                  if (!isEditing) ...[
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppColors.greenBiomass.withValues(alpha: 0.10),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.greenBiomass.withValues(alpha: 0.25)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.check_circle_outline_rounded, color: AppColors.greenBiomass, size: 16),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Alimento Sugerido: $recomendacionNutricional',
                              style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),
                  ],

                  GlassDatePickerField(
                    label: 'FECHA DEL MUESTREO',
                    initialDate: _fechaMuestreo,
                    onDateChanged: (d) => setState(() => _fechaMuestreo = d),
                  ),
                  const SizedBox(height: 14),

                  // Observaciones
                  GlassFormField(
                    label: 'NOTAS DE MUESTREO (OPCIONAL)',
                    hint: 'Ej: Peces activos con excelente brillo y aletas sanas...',
                    controller: _obsCtrl,
                  ),
                  const SizedBox(height: 18),

                  if (!isEditing && activeBatch == null) ...[
                    Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.amberWarning.withValues(alpha: 0.14),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: AppColors.amberWarning.withValues(alpha: 0.4)),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.info_outline_rounded, color: AppColors.amberWarning, size: 18),
                          SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Este estanque no tiene un lote activo sembrado. Seleccione un estanque activo para registrar el muestreo.',
                              style: TextStyle(color: Colors.white, fontSize: 11.5, fontWeight: FontWeight.w700),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],

                  // Botón de Confirmación
                  GlassButton(
                    label: isEditing
                        ? 'Actualizar Muestreo y Biomasa'
                        : 'Guardar Muestreo y Actualizar Biomasa',
                    loadingLabel: isEditing ? 'Actualizando...' : 'Guardando...',
                    height: 46,
                    backgroundColor: AppColors.cyanWater,
                    isLoading: _isLoading,
                    onPressed: () async {
                      if (_isLoading) return;
                      final messenger = ScaffoldMessenger.of(context);
                      if (!isEditing && (activePond == null || activeBatch == null)) {
                        messenger.showSnackBar(
                          const SnackBar(
                            content: Text('Debe seleccionar un estanque con lote activo para guardar la biometría.'),
                            backgroundColor: AppColors.coralAction,
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                        return;
                      }
                      if (!_formKey.currentState!.validate() || !hasValidSample) {
                        messenger.showSnackBar(
                          const SnackBar(
                            content: Text('Ingrese cantidad de peces capturados y peso total de captura mayores a 0.'),
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
                          estanqueId: activePond?.id ?? editRecord.estanqueId,
                          loteId: activeBatch?.id ?? editRecord.loteId,
                          fecha: _fechaMuestreo.toDateTime(),
                          pecesCapturados: pecesCapturados,
                          pesoTotalCapturaKg: pesoCapturaKg,
                          pesoPromedioG: pesoPromedioGramos,
                          biomasaParcialKg: biomasaParcialKg,
                          longitudCm: longitudCm,
                          clearLongitudCm: longitudCm == null,
                          factorK: factorK,
                          clearFactorK: factorK == null,
                          gdpGDia: gdp,
                          observaciones: obsText.isEmpty ? null : obsText,
                          clearObservaciones: obsText.isEmpty,
                        );
                        ok = await ref.read(pondsProvider.notifier).updateBiometry(updated);
                      } else {
                        ok = await ref.read(pondsProvider.notifier).recordBiometry(
                              estanqueId: activePond!.id,
                              loteId: activeBatch!.id,
                              nuevoPesoPromedioGramos: pesoPromedioGramos,
                              biomasaCalculadaKg: biomasaParcialKg,
                              cantidadPecesMuestreados: int.tryParse(_pecesCapturadosCtrl.text),
                              pesoTotalCapturaKg: pesoCapturaKg,
                              longitudPromedioCm: longitudCm,
                              factorK: factorK,
                              gdpGDia: gdp,
                              fecha: _fechaMuestreo.toDateTime(),
                              observaciones: _obsCtrl.text.trim().isEmpty ? null : _obsCtrl.text.trim(),
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
                                    ? 'Biometría actualizada (${pesoPromedioGramos.toStringAsFixed(1)}g). Biomasa ajustada a ${biomasaParcialKg.toStringAsFixed(1)} kg.'
                                    : 'Biometría guardada en ${activePond!.sigla} (${pesoPromedioGramos.toStringAsFixed(1)}g). Biomasa ajustada a ${biomasaParcialKg.toStringAsFixed(1)} kg • Densidad: ${nuevaDensidadKgM3.toStringAsFixed(2)} kg/m³.',
                              ),
                              backgroundColor: AppColors.cyanWater,
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        } else {
                          messenger.showSnackBar(
                            SnackBar(
                              content: Text('Error al guardar biometría: ${ref.read(pondsProvider).errorMessage ?? "Verifique su conexión"}'),
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
