import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fishbit_finance/core/design_system/app_colors.dart';
import 'package:fishbit_finance/core/design_system/app_typography.dart';
import 'package:fishbit_finance/core/design_system/glass_container.dart';
import 'package:fishbit_finance/core/design_system/glass_form_field.dart';
import 'package:fishbit_finance/core/design_system/glass_button.dart';
import 'package:fishbit_finance/core/design_system/glass_date_picker.dart';
import 'package:fishbit_finance/modules/feeding_nutrition/presentation/providers/nutrition_provider.dart';
import 'package:fishbit_finance/modules/ponds_batches/domain/models/fish_batch.dart';
import 'package:fishbit_finance/modules/ponds_batches/domain/models/pond.dart';
import 'package:fishbit_finance/modules/ponds_batches/presentation/providers/ponds_provider.dart';
import 'package:fishbit_finance/modules/warehouse_inventory/domain/models/inventory_item.dart';
import 'package:fishbit_finance/modules/warehouse_inventory/presentation/providers/warehouse_provider.dart';

class AlimentarModal extends ConsumerStatefulWidget {
  final Pond? pond;
  final FishBatch? batch;

  const AlimentarModal({super.key, this.pond, this.batch});

  static Future<void> show(BuildContext context, {Pond? pond, FishBatch? batch}) {
    return showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => AlimentarModal(pond: pond, batch: batch),
    );
  }

  @override
  ConsumerState<AlimentarModal> createState() => _AlimentarModalState();
}

class _AlimentarModalState extends ConsumerState<AlimentarModal> {
  final _kgCtrl = TextEditingController();
  final _racionesCtrl = TextEditingController(text: '3');
  String? _selectedInsumoId;
  String? _selectedPondId;
  CivilDate _fechaAlimentacion = CivilDate.today();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _selectedPondId = widget.pond?.id;
  }

  @override
  void dispose() {
    _kgCtrl.dispose();
    _racionesCtrl.dispose();
    super.dispose();
  }

  double _getSuggestedRationPct(String especie, double pesoGramos) {
    final esp = especie.toLowerCase();
    if (esp.contains('trucha')) {
      // Trucha: Metabolismo acelerado de agua fría
      if (pesoGramos <= 20) return 4.5;
      if (pesoGramos <= 100) return 3.0;
      if (pesoGramos <= 250) return 2.2;
      return 1.4;
    } else if (esp.contains('cachama') || esp.contains('bocachico')) {
      // Especies rústicas amazónicas / omnívoras
      if (pesoGramos <= 30) return 5.5;
      if (pesoGramos <= 150) return 3.2;
      if (pesoGramos <= 350) return 2.2;
      return 1.5;
    }
    // Tilapia / Especie Estándar
    if (pesoGramos <= 20) return 6.0;
    if (pesoGramos <= 50) return 4.8;
    if (pesoGramos <= 120) return 3.5;
    if (pesoGramos <= 250) return 2.6;
    if (pesoGramos <= 450) return 2.0;
    return 1.6;
  }

  @override
  Widget build(BuildContext context) {
    final pondsState = ref.watch(pondsProvider);
    final warehouseState = ref.watch(warehouseProvider);
    final feedItems = warehouseState.items
        .where((i) => i.tipo == InventoryItemType.concentrado)
        .toList();

    final pondsList = pondsState.ponds.where((p) => p.estado == PondStatus.active).toList();
    final activePond = widget.pond ??
        (pondsList.where((p) => p.id == _selectedPondId).firstOrNull ?? (pondsList.isNotEmpty ? pondsList.first : null));
    final activeBatch = widget.batch ??
        (activePond != null
            ? pondsState.batches.where((b) => b.estanqueId == activePond.id && b.estado == BatchStatus.active).firstOrNull
            : null);

    if ((_selectedInsumoId == null || !feedItems.any((i) => i.id == _selectedInsumoId)) && feedItems.isNotEmpty) {
      final itemConStock = feedItems.where((i) => i.cantidadActualKg > 0).firstOrNull;
      _selectedInsumoId = itemConStock?.id ?? feedItems.first.id;
    }

    final pesoProm = activeBatch?.pesoActualGramos ?? 250.0;
    final biomasaKg = activeBatch?.biomasaActualKg ?? activePond?.biomasaKg ?? 1000.0;
    final especie = activeBatch?.especie ?? 'Tilapia Roja';
    final rationPct = _getSuggestedRationPct(especie, pesoProm);
    final racionSugeridaDiaKg = (biomasaKg * rationPct) / 100.0;

    if (_kgCtrl.text.isEmpty && racionSugeridaDiaKg > 0) {
      _kgCtrl.text = racionSugeridaDiaKg.toStringAsFixed(1);
    }

    final selectedItem = feedItems.where((i) => i.id == _selectedInsumoId).firstOrNull;
    final stockDisponibleKg = selectedItem?.cantidadActualKg ?? 0.0;
    final costoUnitario = selectedItem?.costoUnitarioHistorico ?? 4800.0;
    final kgSuministrados = double.tryParse(_kgCtrl.text) ?? racionSugeridaDiaKg;
    final stockInsuficiente = selectedItem != null && stockDisponibleKg > 0 && kgSuministrados > stockDisponibleKg;
    final costoTotal = kgSuministrados * costoUnitario;
    final racionesNum = int.tryParse(_racionesCtrl.text) ?? 3;
    final kgPorRacion = racionesNum > 0 ? (kgSuministrados / racionesNum) : kgSuministrados;

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
          borderColor: AppColors.greenBiomass.withValues(alpha: 0.35),
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
                            color: AppColors.greenBiomass.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(Icons.restaurant_rounded, color: AppColors.greenBiomass, size: 20),
                        ),
                        const SizedBox(width: 10),
                        Text(
                          'Alimentación y FCR',
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

                // Selector de Estanque si no vino especificado
                if (widget.pond == null && pondsList.isNotEmpty) ...[
                  Text('ESTANQUE DESTINO', style: AppTypography.labelMicro.copyWith(color: AppColors.textSecondaryDark)),
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
                              final r = _getSuggestedRationPct(b.especie, b.pesoActualGramos);
                              _kgCtrl.text = ((b.biomasaActualKg * r) / 100).toStringAsFixed(1);
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
                        Text('Biomasa: ${biomasaKg.toInt()} kg', style: const TextStyle(color: AppColors.greenBiomass, fontWeight: FontWeight.w800, fontSize: 12)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                ],

                // Sugerencia Acuícola de Precisión
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.cyanWater.withValues(alpha: 0.10),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppColors.cyanWater.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.auto_graph_rounded, color: AppColors.cyanWater, size: 20),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Ración Sugerida: ${racionSugeridaDiaKg.toStringAsFixed(1)} kg/día ($rationPct% de biomasa)',
                              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 12),
                            ),
                            Text(
                              'Para peso promedio de ${pesoProm.toStringAsFixed(1)}g en ${activeBatch?.especie ?? "Tilapia"}',
                              style: const TextStyle(color: AppColors.textSecondaryDark, fontSize: 10.5),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),

                // Selector de Alimento en Bodega
                Text('ALIMENTO DISPONIBLE EN BODEGA', style: AppTypography.labelMicro.copyWith(color: AppColors.textSecondaryDark)),
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
                      value: _selectedInsumoId,
                      isExpanded: true,
                      dropdownColor: AppColors.backgroundDark,
                      items: feedItems.map((item) {
                        final tieneStock = item.cantidadActualKg > 0;
                        return DropdownMenuItem(
                          value: item.id,
                          child: Text(
                            '${item.nombre} (${tieneStock ? "${item.cantidadActualKg.toStringAsFixed(1)} kg disponibles" : "Sin Stock en bodega"} • \$${item.costoUnitarioHistorico.toInt()}/kg)',
                            style: TextStyle(
                              color: tieneStock ? Colors.white : AppColors.coralAction,
                              fontSize: 12.5,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        );
                      }).toList(),
                      onChanged: (val) => setState(() => _selectedInsumoId = val),
                    ),
                  ),
                ),
                if (stockInsuficiente) ...[
                  const SizedBox(height: 6),
                  Text(
                    '⚠️ La cantidad a suministrar (${kgSuministrados.toStringAsFixed(1)} kg) supera el stock en bodega (${stockDisponibleKg.toStringAsFixed(1)} kg).',
                    style: const TextStyle(color: AppColors.coralAction, fontSize: 11, fontWeight: FontWeight.w700),
                  ),
                ],
                const SizedBox(height: 14),

                // Cantidad de Alimento y Distribución de Raciones
                Row(
                  children: [
                    Expanded(
                      flex: 3,
                      child: GlassFormField(
                        label: 'TOTAL ALIMENTO A SUMINISTRAR (kg)',
                        hint: '0.0',
                        controller: _kgCtrl,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        onChanged: (_) => setState(() {}),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      flex: 2,
                      child: GlassFormField(
                        label: 'RACIONES/DÍA',
                        hint: '3',
                        controller: _racionesCtrl,
                        keyboardType: TextInputType.number,
                        onChanged: (_) => setState(() {}),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                GlassDatePickerField(
                  label: 'FECHA DE ALIMENTACIÓN',
                  initialDate: _fechaAlimentacion,
                  onDateChanged: (d) => setState(() => _fechaAlimentacion = d),
                ),
                const SizedBox(height: 14),

                // Resumen Financiero y Logístico
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.04),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Distribución:', style: TextStyle(color: AppColors.textSecondaryDark, fontSize: 12)),
                          Text('${kgPorRacion.toStringAsFixed(1)} kg en cada ración', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 12.5)),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Costo del Suministro:', style: TextStyle(color: AppColors.textSecondaryDark, fontSize: 12)),
                          Text('\$${costoTotal.toStringAsFixed(0)} COP', style: const TextStyle(color: AppColors.greenBiomass, fontWeight: FontWeight.w900, fontSize: 13)),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),

                // Botón de Confirmación
                GlassButton(
                  label: 'Registrar Suministro de Alimento',
                  height: 46,
                  backgroundColor: AppColors.greenBiomass,
                  isLoading: _isLoading,
                  onPressed: (activePond == null || activeBatch == null || kgSuministrados <= 0 || stockInsuficiente)
                      ? null
                      : () async {
                          final nav = Navigator.of(context);
                          final messenger = ScaffoldMessenger.of(context);
                          setState(() => _isLoading = true);
                          // 1. Descontar inventario en Bodega
                          if (_selectedInsumoId != null) {
                            await ref.read(warehouseProvider.notifier).discountStock(
                                  itemId: _selectedInsumoId!,
                                  cantidadKg: kgSuministrados,
                                  motivo: 'Alimentación en estanque ${activePond.sigla}',
                                );
                          }
                          // 2. Registrar en módulo de nutrición
                          await ref.read(nutritionProvider.notifier).recordDailyFeeding(
                                estanqueId: activePond.id,
                                loteId: activeBatch.id,
                                insumoId: _selectedInsumoId,
                                kgConsumidos: kgSuministrados,
                                costoUnitarioAlimento: costoUnitario,
                              );
                          // 3. Recargar estanques para actualizar FCR y costo
                          await ref.read(pondsProvider.notifier).loadPondsAndBatches();

                          if (mounted) {
                            setState(() => _isLoading = false);
                            nav.pop();
                            messenger.showSnackBar(
                              SnackBar(
                                content: Text('Alimentación registrada en ${activePond.sigla} (${kgSuministrados.toStringAsFixed(1)} kg). Stock descontado en Bodega.'),
                                backgroundColor: AppColors.greenBiomass,
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
    );
  }
}
