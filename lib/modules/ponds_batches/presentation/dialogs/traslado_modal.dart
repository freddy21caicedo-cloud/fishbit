import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fishbit_finance/core/design_system/app_colors.dart';
import 'package:fishbit_finance/core/design_system/app_typography.dart';
import 'package:fishbit_finance/core/design_system/glass_container.dart';
import 'package:fishbit_finance/core/design_system/glass_button.dart';
import 'package:fishbit_finance/core/design_system/glass_date_picker.dart';
import 'package:fishbit_finance/core/utils/currency_formatters.dart';
import 'package:fishbit_finance/modules/ponds_batches/domain/models/fish_batch.dart';
import 'package:fishbit_finance/modules/ponds_batches/domain/models/pond.dart';
import 'package:fishbit_finance/modules/ponds_batches/presentation/providers/ponds_provider.dart';

class TrasladoModal extends ConsumerStatefulWidget {
  final Pond? pond;
  final FishBatch? batch;

  const TrasladoModal({super.key, this.pond, this.batch});

  static Future<void> show(BuildContext context, {Pond? pond, FishBatch? batch}) {
    return showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => TrasladoModal(pond: pond, batch: batch),
    );
  }

  @override
  ConsumerState<TrasladoModal> createState() => _TrasladoModalState();
}

class _TrasladoModalState extends ConsumerState<TrasladoModal> {
  final _formKey = GlobalKey<FormState>();

  String? _selectedPondOrigenId;
  String? _selectedBatchId;
  String? _selectedPondDestinoId;

  bool _esDesdoble = false;
  final _pecesCtrl = TextEditingController();
  final _pesoCtrl = TextEditingController();
  final _nuevoCodigoCtrl = TextEditingController();
  CivilDate _fechaTraslado = CivilDate.today();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _selectedPondOrigenId = widget.pond?.id;
    _selectedBatchId = widget.batch?.id;
    _pesoCtrl.text = (widget.batch?.pesoActualGramos ?? 100.0).toStringAsFixed(1);
    _pecesCtrl.text = (widget.batch?.cantidadActualPeces ?? 1000).toString();
    _nuevoCodigoCtrl.text = '${widget.batch?.codigoLote ?? "LOTE"}-B';
  }

  @override
  void dispose() {
    _pecesCtrl.dispose();
    _pesoCtrl.dispose();
    _nuevoCodigoCtrl.dispose();
    super.dispose();
  }

  void _onBatchChanged(FishBatch b) {
    setState(() {
      _selectedBatchId = b.id;
      _pesoCtrl.text = b.pesoActualGramos.toStringAsFixed(1);
      _pecesCtrl.text = _esDesdoble
          ? (b.cantidadActualPeces ~/ 2).toString()
          : b.cantidadActualPeces.toString();
      _nuevoCodigoCtrl.text = '${b.codigoLote}-B';
    });
  }

  void _setPercentage(double pct, int maxPeces) {
    setState(() {
      final peces = (maxPeces * pct).round().clamp(1, maxPeces);
      _pecesCtrl.text = peces.toString();
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final pondsState = ref.watch(pondsProvider);

    Pond? pondOrigen = pondsState.ponds.where((p) => p.id == _selectedPondOrigenId).firstOrNull;
    pondOrigen ??= widget.pond ?? pondsState.ponds.where((p) => p.estado == PondStatus.active).firstOrNull;

    final batchesInOrigen = pondOrigen != null
        ? pondsState.batches.where((b) => b.estanqueId == pondOrigen!.id && b.estado == BatchStatus.active).toList()
        : <FishBatch>[];

    FishBatch? batchOrigen = batchesInOrigen.where((b) => b.id == _selectedBatchId).firstOrNull;
    batchOrigen ??= widget.batch ?? batchesInOrigen.firstOrNull;

    final destinationPonds = pondsState.ponds.where((p) => p.id != pondOrigen?.id).toList();

    final maxPeces = batchOrigen?.cantidadActualPeces ?? 0;
    final pecesTrasladados = (int.tryParse(_pecesCtrl.text.replaceAll(RegExp(r'[^\d]'), '')) ?? 0).clamp(0, maxPeces > 0 ? maxPeces : 1000000);
    final pesoPromedioG = double.tryParse(_pesoCtrl.text.replaceAll(RegExp(r'[^\d.]'), '')) ?? (batchOrigen?.pesoActualGramos ?? 1.0);
    final biomasaTrasladadaKg = (pecesTrasladados * pesoPromedioG) / 1000.0;

    final proporcion = maxPeces > 0 ? (pecesTrasladados / maxPeces) : 0.0;
    final costoAlevinesTransferido = (batchOrigen?.costoInicialAlevinos ?? 0.0) * proporcion;
    final costoInsumosTransferido = (batchOrigen?.costoAcumuladoInsumos ?? 0.0) * proporcion;
    final costoFijoTransferido = (batchOrigen?.costoAcumuladoFijo ?? 0.0) * proporcion;
    final costoTotalTransferido = costoAlevinesTransferido + costoInsumosTransferido + costoFijoTransferido;

    final pondDestino = destinationPonds.where((p) => p.id == _selectedPondDestinoId).firstOrNull;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 620),
        child: GlassContainer(
          borderRadius: 24,
          padding: const EdgeInsets.all(20),
          blur: 24,
          opacity: isDark ? 0.20 : 0.95,
          borderColor: isDark ? Colors.white.withValues(alpha: 0.18) : AppColors.glassBorderLight,
          child: Form(
            key: _formKey,
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AppColors.amberWarning.withValues(alpha: isDark ? 0.2 : 0.12),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: AppColors.amberWarning.withValues(alpha: 0.3)),
                        ),
                        child: const Icon(Icons.swap_horiz_rounded, color: AppColors.amberWarning, size: 22),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Traslado y Desdoble de Lotes',
                              style: AppTypography.titleMedium.copyWith(
                                color: isDark ? Colors.white : AppColors.textPrimaryLight,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            Text(
                              'Trazabilidad biológica y financiera entre estanques',
                              style: AppTypography.labelMicro.copyWith(
                                color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close_rounded, size: 20),
                        onPressed: () => Navigator.of(context).pop(),
                        visualDensity: VisualDensity.compact,
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: isDark ? Colors.black26 : Colors.black.withValues(alpha: 0.04),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: isDark ? Colors.white10 : AppColors.glassBorderLight),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: InkWell(
                            onTap: () {
                              setState(() {
                                _esDesdoble = false;
                                if (batchOrigen != null) {
                                  _pecesCtrl.text = batchOrigen.cantidadActualPeces.toString();
                                }
                              });
                            },
                            borderRadius: BorderRadius.circular(10),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 180),
                              padding: const EdgeInsets.symmetric(vertical: 10),
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color: !_esDesdoble
                                    ? AppColors.cyanWater.withValues(alpha: isDark ? 0.25 : 0.18)
                                    : Colors.transparent,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: !_esDesdoble ? AppColors.cyanWater : Colors.transparent,
                                  width: 1.2,
                                ),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.arrow_forward_rounded, size: 15, color: !_esDesdoble ? AppColors.cyanWater : AppColors.textSecondaryDark),
                                  const SizedBox(width: 6),
                                  Text(
                                    'Traslado Total (100%)',
                                    style: TextStyle(
                                      color: !_esDesdoble ? AppColors.cyanWater : AppColors.textSecondaryDark,
                                      fontWeight: FontWeight.w800,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: InkWell(
                            onTap: () {
                              setState(() {
                                _esDesdoble = true;
                                if (batchOrigen != null) {
                                  _pecesCtrl.text = (batchOrigen.cantidadActualPeces ~/ 2).toString();
                                }
                              });
                            },
                            borderRadius: BorderRadius.circular(10),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 180),
                              padding: const EdgeInsets.symmetric(vertical: 10),
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color: _esDesdoble
                                    ? AppColors.amberWarning.withValues(alpha: isDark ? 0.25 : 0.18)
                                    : Colors.transparent,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: _esDesdoble ? AppColors.amberWarning : Colors.transparent,
                                  width: 1.2,
                                ),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.call_split_rounded, size: 15, color: _esDesdoble ? AppColors.amberWarning : AppColors.textSecondaryDark),
                                  const SizedBox(width: 6),
                                  Text(
                                    'Desdoble / Raleo (%)',
                                    style: TextStyle(
                                      color: _esDesdoble ? AppColors.amberWarning : AppColors.textSecondaryDark,
                                      fontWeight: FontWeight.w800,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: isDark ? Colors.white.withValues(alpha: 0.04) : Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: isDark ? Colors.white10 : AppColors.glassBorderLight),
                    ),
                    child: Column(
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('ESTANQUE ORIGEN', style: AppTypography.labelMicro.copyWith(color: AppColors.cyanWater, fontSize: 9.5)),
                                  const SizedBox(height: 4),
                                  Text(
                                    pondOrigen?.nombreLimpio ?? 'Seleccione origen',
                                    style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  Text(
                                    '${batchOrigen?.especie ?? "Sin lote"} • ${CurrencyFormatters.formatInt(maxPeces)} pcs',
                                    style: AppTypography.labelMicro.copyWith(color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight),
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: (_esDesdoble ? AppColors.amberWarning : AppColors.cyanWater).withValues(alpha: 0.15),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                _esDesdoble ? Icons.call_split_rounded : Icons.trending_flat_rounded,
                                color: _esDesdoble ? AppColors.amberWarning : AppColors.cyanWater,
                                size: 18,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text('ESTANQUE DESTINO', style: AppTypography.labelMicro.copyWith(color: AppColors.greenBiomass, fontSize: 9.5)),
                                  const SizedBox(height: 4),
                                  Text(
                                    pondDestino?.nombreLimpio ?? 'Por seleccionar',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w800,
                                      fontSize: 13,
                                      color: pondDestino != null ? AppColors.greenBiomass : AppColors.textSecondaryDark,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  Text(
                                    pondDestino != null
                                        ? '${pondDestino.capacidadM3.toInt()} m³ • ${pondDestino.estado == PondStatus.active ? "En uso" : "Disponible"}'
                                        : 'Elija estanque...',
                                    style: AppTypography.labelMicro.copyWith(color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),

                  _buildDropdownField(
                    label: 'Estanque Receptor (Destino)',
                    hint: 'Seleccione el estanque destino...',
                    value: destinationPonds.any((p) => p.id == _selectedPondDestinoId) ? _selectedPondDestinoId : null,
                    items: destinationPonds.map((p) {
                      final statusLabel = p.estado == PondStatus.active ? '🟠 En Uso' : '🟢 Disponible';
                      return DropdownMenuItem<String>(
                        value: p.id,
                        child: Text('${p.nombreLimpio} (${p.capacidadM3.toInt()} m³) • $statusLabel', overflow: TextOverflow.ellipsis),
                      );
                    }).toList(),
                    onChanged: (val) => setState(() => _selectedPondDestinoId = val),
                    validator: (val) => val == null || val.isEmpty ? 'Seleccione el estanque destino' : null,
                    isDark: isDark,
                  ),
                  const SizedBox(height: 12),

                  if (batchesInOrigen.length > 1) ...[
                    _buildDropdownField(
                      label: 'Lote a Trasladar / Desdoblar',
                      hint: 'Seleccione el lote...',
                      value: _selectedBatchId,
                      items: batchesInOrigen.map((b) {
                        return DropdownMenuItem<String>(
                          value: b.id,
                          child: Text('${b.codigoLote} - ${b.especie} (${CurrencyFormatters.formatInt(b.cantidadActualPeces)} pcs)'),
                        );
                      }).toList(),
                      onChanged: (val) {
                        final found = batchesInOrigen.where((b) => b.id == val).firstOrNull;
                        if (found != null) _onBatchChanged(found);
                      },
                      isDark: isDark,
                    ),
                    const SizedBox(height: 12),
                  ],

                  Row(
                    children: [
                      Expanded(
                        flex: 3,
                        child: TextFormField(
                          controller: _pecesCtrl,
                          keyboardType: TextInputType.number,
                          style: TextStyle(color: isDark ? Colors.white : AppColors.textPrimaryLight, fontWeight: FontWeight.w800, fontSize: 13),
                          decoration: InputDecoration(
                            labelText: _esDesdoble ? 'Peces a Desdoblar' : 'Peces Trasladados',
                            floatingLabelBehavior: FloatingLabelBehavior.auto,
                            labelStyle: const TextStyle(fontSize: 11, color: AppColors.cyanWater),
                            hintText: '5000',
                            isDense: true,
                            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                          ),
                          onChanged: (_) => setState(() {}),
                          validator: (v) {
                            final val = int.tryParse(v ?? '') ?? 0;
                            if (val <= 0) return 'Ingrese cantidad > 0';
                            if (val > maxPeces) return 'Máximo $maxPeces peces';
                            return null;
                          },
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        flex: 2,
                        child: TextFormField(
                          controller: _pesoCtrl,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          style: TextStyle(color: isDark ? Colors.white : AppColors.textPrimaryLight, fontWeight: FontWeight.w800, fontSize: 13),
                          decoration: InputDecoration(
                            labelText: 'Peso Prom (g)',
                            floatingLabelBehavior: FloatingLabelBehavior.auto,
                            labelStyle: const TextStyle(fontSize: 11, color: AppColors.amberWarning),
                            hintText: '350.0',
                            isDense: true,
                            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                          ),
                          onChanged: (_) => setState(() {}),
                        ),
                      ),
                    ],
                  ),

                  if (_esDesdoble && maxPeces > 0) ...[
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Text('Porcentaje:', style: AppTypography.labelMicro.copyWith(color: AppColors.textSecondaryDark)),
                        const SizedBox(width: 8),
                        _buildQuickPctChip('25%', 0.25, maxPeces, isDark),
                        const SizedBox(width: 6),
                        _buildQuickPctChip('33%', 0.333, maxPeces, isDark),
                        const SizedBox(width: 6),
                        _buildQuickPctChip('50% (Mitad)', 0.50, maxPeces, isDark),
                        const SizedBox(width: 6),
                        _buildQuickPctChip('75%', 0.75, maxPeces, isDark),
                      ],
                    ),
                  ],
                  const SizedBox(height: 12),

                  Row(
                    children: [
                      if (_esDesdoble) ...[
                        Expanded(
                          flex: 3,
                          child: TextFormField(
                            controller: _nuevoCodigoCtrl,
                            style: TextStyle(color: isDark ? Colors.white : AppColors.textPrimaryLight, fontWeight: FontWeight.w800, fontSize: 13),
                            decoration: InputDecoration(
                              labelText: 'Código Nuevo Lote',
                              floatingLabelBehavior: FloatingLabelBehavior.auto,
                              labelStyle: const TextStyle(fontSize: 11, color: AppColors.cyanWater),
                              hintText: 'LOTE-TILA-01-B',
                              isDense: true,
                              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                      ],
                      Expanded(
                        flex: 2,
                        child: GlassDatePickerField(
                          label: 'FECHA OPERACIÓN',
                          initialDate: _fechaTraslado,
                          accentColor: _esDesdoble ? AppColors.amberWarning : AppColors.cyanWater,
                          onDateChanged: (d) => setState(() => _fechaTraslado = d),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),

                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.greenBiomass.withValues(alpha: isDark ? 0.08 : 0.05),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.greenBiomass.withValues(alpha: 0.25)),
                    ),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('Biomasa a Transferir:', style: AppTypography.bodySmall.copyWith(color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight)),
                            Text(
                              CurrencyFormatters.formatKg(biomasaTrasladadaKg),
                              style: const TextStyle(color: AppColors.cyanWater, fontWeight: FontWeight.w900, fontSize: 13),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('Proporción de Costos (${(proporcion * 100).toStringAsFixed(1)}%):', style: AppTypography.bodySmall.copyWith(color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight)),
                            Text(
                              CurrencyFormatters.formatCOP(costoTotalTransferido),
                              style: const TextStyle(color: AppColors.greenBiomass, fontWeight: FontWeight.w900, fontSize: 13),
                            ),
                          ],
                        ),
                        const Divider(height: 10, color: Colors.white12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              _esDesdoble
                                  ? 'Costo Alevinos: ${CurrencyFormatters.formatCOP(costoAlevinesTransferido)} • Insumos: ${CurrencyFormatters.formatCOP(costoInsumosTransferido)}'
                                  : 'Transferencia total del centro de costos acumulado',
                              style: AppTypography.labelMicro.copyWith(color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight, fontSize: 9.5),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),

                  GlassButton(
                    label: _isLoading
                        ? 'Procesando Traslado...'
                        : (_esDesdoble ? 'Confirmar Desdoble de Lote' : 'Confirmar Traslado de Lote'),
                    icon: Icon(_esDesdoble ? Icons.call_split_rounded : Icons.swap_horiz_rounded, size: 18),
                    backgroundColor: _esDesdoble ? AppColors.amberWarning : AppColors.cyanWater,
                    isLoading: _isLoading,
                    onPressed: () async {
                      if (!_formKey.currentState!.validate()) return;
                      if (_selectedPondDestinoId == null) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('⚠️ Debe seleccionar el estanque de destino'),
                            backgroundColor: AppColors.coralAction,
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                        return;
                      }

                      setState(() => _isLoading = true);

                      try {
                        await ref.read(pondsProvider.notifier).executeTransferSplit(
                              batchOrigenId: batchOrigen!.id,
                              estanqueOrigenId: pondOrigen!.id,
                              estanqueDestinoId: _selectedPondDestinoId!,
                              pecesTrasladados: pecesTrasladados,
                              biomasaTrasladadaKg: biomasaTrasladadaKg,
                              esDesdoble: _esDesdoble,
                              nuevoCodigoLote: _nuevoCodigoCtrl.text.trim().isNotEmpty
                                  ? _nuevoCodigoCtrl.text.trim()
                                  : '${batchOrigen.codigoLote}-B',
                            );

                        if (context.mounted) {
                          Navigator.of(context).pop();
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                _esDesdoble
                                    ? '✂️ Desdoble de lote realizado exitosamente hacia ${pondDestino?.nombreLimpio}'
                                    : '🔄 Lote trasladado exitosamente hacia ${pondDestino?.nombreLimpio}',
                              ),
                              backgroundColor: AppColors.greenBiomass,
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        }
                      } catch (e) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Error al ejecutar traslado: $e'),
                              backgroundColor: AppColors.coralAction,
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        }
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

  Widget _buildQuickPctChip(String label, double pct, int maxPeces, bool isDark) {
    return InkWell(
      onTap: () => _setPercentage(pct, maxPeces),
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: AppColors.amberWarning.withValues(alpha: isDark ? 0.15 : 0.08),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.amberWarning.withValues(alpha: 0.3)),
        ),
        child: Text(
          label,
          style: const TextStyle(color: AppColors.amberWarning, fontSize: 10, fontWeight: FontWeight.w800),
        ),
      ),
    );
  }

  Widget _buildDropdownField({
    required String label,
    required String hint,
    required String? value,
    required List<DropdownMenuItem<String>> items,
    required ValueChanged<String?> onChanged,
    FormFieldValidator<String>? validator,
    required bool isDark,
  }) {
    return DropdownButtonFormField<String>(
      initialValue: value,
      items: items,
      onChanged: onChanged,
      validator: validator,
      isExpanded: true,
      dropdownColor: isDark ? AppColors.surfaceDark : Colors.white,
      style: TextStyle(color: isDark ? Colors.white : AppColors.textPrimaryLight, fontSize: 12.5, fontWeight: FontWeight.w600),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        floatingLabelBehavior: FloatingLabelBehavior.auto,
        labelStyle: const TextStyle(fontSize: 11, color: AppColors.cyanWater),
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
      ),
    );
  }
}
