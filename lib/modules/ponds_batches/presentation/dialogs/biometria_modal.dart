import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fishbit_finance/core/design_system/app_colors.dart';
import 'package:fishbit_finance/core/design_system/app_typography.dart';
import 'package:fishbit_finance/core/design_system/glass_container.dart';
import 'package:fishbit_finance/core/design_system/glass_form_field.dart';
import 'package:fishbit_finance/core/design_system/glass_button.dart';
import 'package:fishbit_finance/core/design_system/glass_date_picker.dart';
import 'package:fishbit_finance/modules/ponds_batches/domain/models/fish_batch.dart';
import 'package:fishbit_finance/modules/ponds_batches/domain/models/pond.dart';
import 'package:fishbit_finance/modules/ponds_batches/presentation/providers/ponds_provider.dart';

class BiometriaModal extends ConsumerStatefulWidget {
  final Pond? pond;
  final FishBatch? batch;

  const BiometriaModal({super.key, this.pond, this.batch});

  static Future<void> show(BuildContext context, {Pond? pond, FishBatch? batch}) {
    return showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => BiometriaModal(pond: pond, batch: batch),
    );
  }

  @override
  ConsumerState<BiometriaModal> createState() => _BiometriaModalState();
}

class _BiometriaModalState extends ConsumerState<BiometriaModal> {
  final _formKey = GlobalKey<FormState>();
  final _pecesCapturadosCtrl = TextEditingController(text: '35');
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
    _selectedPondId = widget.pond?.id;
    _selectedBatchId = widget.batch?.id;
    final defaultPesoG = widget.batch?.pesoActualGramos ?? 250.0;
    const defaultPeces = 35;
    final defaultCapturaKg = (defaultPeces * defaultPesoG) / 1000.0;
    _pesoTotalCapturaKgCtrl = TextEditingController(
      text: defaultCapturaKg.toStringAsFixed(2),
    );
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
    final pondsState = ref.watch(pondsProvider);
    final pondsList = pondsState.ponds.where((p) => p.estado == PondStatus.active).toList();
    final activePond = widget.pond ??
        (pondsList.where((p) => p.id == _selectedPondId).firstOrNull ?? (pondsList.isNotEmpty ? pondsList.first : null));
    final activeBatches = activePond != null
        ? pondsState.batches.where((b) => b.estanqueId == activePond.id && b.estado == BatchStatus.active).toList()
        : <FishBatch>[];
    final activeBatch = widget.batch ??
        (activeBatches.where((b) => b.id == _selectedBatchId).firstOrNull ?? activeBatches.firstOrNull);

    final pesoCapturaKg = double.tryParse(_pesoTotalCapturaKgCtrl.text) ?? 0.0;
    final pecesCapturados = int.tryParse(_pecesCapturadosCtrl.text) ?? 0;
    final pesoCapturaGramos = pesoCapturaKg * 1000.0;
    final pesoPromedioGramos = pecesCapturados > 0 ? (pesoCapturaGramos / pecesCapturados) : (activeBatch?.pesoActualGramos ?? 250.0);

    final pesoAnteriorG = activeBatch?.pesoActualGramos ?? 200.0;
    final pecesVivos = activeBatch?.cantidadActualPeces ?? 1000;
    final biomasaParcialKg = (pecesVivos * pesoPromedioGramos) / 1000.0;
    final gananciaPesoG = pesoPromedioGramos - pesoAnteriorG;

    // Cálculo GDP (Ganancia Diaria de Peso)
    final dias = (activeBatch?.diasDeCultivo ?? 30) > 0 ? (activeBatch?.diasDeCultivo ?? 30) : 1;
    final gdp = dias > 0 ? ((pesoPromedioGramos - (activeBatch?.pesoInicialGramos ?? 10.0)) / dias) : 0.0;

    // Factor K de Fulton (si se ingresa longitud en cm)
    final longitudCm = double.tryParse(_longitudCtrl.text);
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
                            'Muestreo Biométrico',
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
                    Text('ESTANQUE MUESTREADO', style: AppTypography.labelMicro.copyWith(color: AppColors.textSecondaryDark)),
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
                                '${p.sigla} - ${p.nombre} (${p.biomasaKg.toInt()} kg)',
                                style: const TextStyle(color: Colors.white, fontSize: 13),
                              ),
                            );
                          }).toList(),
                          onChanged: (val) {
                            setState(() {
                              _selectedPondId = val;
                              final b = pondsState.batches.where((b) => b.estanqueId == val).firstOrNull;
                              if (b != null) {
                                const pCount = 35;
                                _pesoTotalCapturaKgCtrl.text = ((pCount * b.pesoActualGramos) / 1000.0).toStringAsFixed(2);
                              }
                            });
                          },
                        ),
                      ),
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

                  // Selector de Lote / Especie si el estanque está en Policultivo
                  if (activeBatches.length > 1) ...[
                    Text('ESPECIE / LOTE A MUESTREAR (POLICULTIVO)', style: AppTypography.labelMicro.copyWith(color: Colors.purpleAccent, letterSpacing: 1.2)),
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
                                '${b.especie} (${b.codigoLote}) • Peso actual: ${b.pesoActualGramos.toStringAsFixed(1)}g',
                                style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w700),
                              ),
                            );
                          }).toList(),
                          onChanged: (val) {
                            setState(() {
                              _selectedBatchId = val;
                              final b = activeBatches.where((batch) => batch.id == val).firstOrNull;
                              if (b != null) {
                                const pCount = 35;
                                _pesoTotalCapturaKgCtrl.text = ((pCount * b.pesoActualGramos) / 1000.0).toStringAsFixed(2);
                              }
                            });
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                  ],

                  // Campos de Muestreo: Peces Capturados y Peso Total Captura (kg)
                  Row(
                    children: [
                      Expanded(
                        child: GlassFormField(
                          label: 'PECES CAPTURADOS (RED)',
                          hint: '35',
                          controller: _pecesCapturadosCtrl,
                          keyboardType: TextInputType.number,
                          onChanged: (_) => setState(() {}),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: GlassFormField(
                          label: 'PESO TOTAL CAPTURA (kg)',
                          hint: '8.75',
                          controller: _pesoTotalCapturaKgCtrl,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
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
                                child: Text('${pesoPromedioGramos.toStringAsFixed(1)} g', style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w900)),
                              ),
                              Text('${pesoCapturaKg.toStringAsFixed(2)} kg ÷ $pecesCapturados peces', style: const TextStyle(color: Colors.white60, fontSize: 10)),
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
                                child: Text('${biomasaParcialKg.toStringAsFixed(1)} kg', style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w900)),
                              ),
                              Text('En $pecesVivos peces vivos', style: const TextStyle(color: Colors.white60, fontSize: 10)),
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

                  // Recomendación de Pellet y Proteína
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

                  // Botón de Confirmación
                  GlassButton(
                    label: 'Guardar Muestreo y Actualizar Biomasa',
                    height: 46,
                    backgroundColor: AppColors.cyanWater,
                    isLoading: _isLoading,
                    onPressed: (activePond == null || activeBatch == null || pesoPromedioGramos <= 0)
                        ? null
                        : () async {
                            final nav = Navigator.of(context);
                            final messenger = ScaffoldMessenger.of(context);
                            setState(() => _isLoading = true);
                            final ok = await ref.read(pondsProvider.notifier).recordBiometry(
                                  estanqueId: activePond.id,
                                  loteId: activeBatch.id,
                                  nuevoPesoPromedioGramos: pesoPromedioGramos,
                                  cantidadPecesMuestreados: int.tryParse(_pecesCapturadosCtrl.text),
                                  pesoTotalCapturaKg: pesoCapturaKg,
                                  longitudPromedioCm: longitudCm,
                                  factorK: factorK,
                                  gdpGDia: gdp,
                                  fecha: _fechaMuestreo.toDateTime(),
                                  observaciones: _obsCtrl.text.trim().isEmpty ? null : _obsCtrl.text.trim(),
                                );
                            if (mounted) {
                              setState(() => _isLoading = false);
                              if (ok) {
                                nav.pop();
                                messenger.showSnackBar(
                                  SnackBar(
                                    content: Text('Biometría guardada en ${activePond.sigla} (${pesoPromedioGramos.toStringAsFixed(1)}g). Biomasa ajustada a ${biomasaParcialKg.toStringAsFixed(1)} kg.'),
                                    backgroundColor: AppColors.cyanWater,
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
