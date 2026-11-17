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
import 'package:fishbit_finance/modules/ponds_batches/domain/models/fish_batch.dart';
import 'package:fishbit_finance/modules/ponds_batches/presentation/providers/ponds_provider.dart';
import 'package:fishbit_finance/modules/sales_harvest/domain/models/batch_sale.dart';
import 'package:fishbit_finance/modules/sales_harvest/domain/models/client.dart';
import 'package:fishbit_finance/modules/sales_harvest/presentation/dialogs/confirmar_venta_dialog.dart';
import 'package:fishbit_finance/modules/sales_harvest/presentation/providers/sales_provider.dart';


class VentaRapidaModal extends ConsumerStatefulWidget {
  final FishBatch? initialBatch;

  const VentaRapidaModal({super.key, this.initialBatch});

  static Future<void> show(BuildContext context, {FishBatch? batch}) {
    return showDialog(
      context: context,
      barrierDismissible: true,
      barrierColor: Colors.black.withValues(alpha: 0.65),
      builder: (context) => VentaRapidaModal(initialBatch: batch),
    );
  }

  @override
  ConsumerState<VentaRapidaModal> createState() => _VentaRapidaModalState();
}

class _VentaRapidaModalState extends ConsumerState<VentaRapidaModal> {
  final _formKey = GlobalKey<FormState>();

  // 1. Datos de Venta & Comprador
  CivilDate _fechaVenta = CivilDate.today();
  final _clienteNombreCtrl = TextEditingController();
  final _clienteCedulaCtrl = TextEditingController();
  String? _selectedClientId;

  // 2. Origen del Producto
  String? _selectedPondId;
  String? _selectedBatchId;

  // 3. Tipo de Venta / Presentación
  SalePresentation _tipoVenta = SalePresentation.vivo;

  // 4. Parámetros de Biometría & Merma
  final _cantidadPecesCtrl = TextEditingController();
  final _pesoVivoKgCtrl = TextEditingController();
  final _pesoArregladoKgCtrl = TextEditingController();
  final _mermaPctCtrl = TextEditingController(text: '10.0'); // Merma por defecto al cambiar
  final _precioKgCtrl = TextEditingController();

  // Base de cobro: sobre peso vivo o sobre peso arreglado
  String _baseCobro = 'peso_vivo';

  bool _isAutoCalculating = false;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    if (widget.initialBatch != null) {
      _selectedBatchId = widget.initialBatch!.id;
      _selectedPondId = widget.initialBatch!.estanqueId;
    }
  }

  @override
  void dispose() {
    _clienteNombreCtrl.dispose();
    _clienteCedulaCtrl.dispose();
    _cantidadPecesCtrl.dispose();
    _pesoVivoKgCtrl.dispose();
    _pesoArregladoKgCtrl.dispose();
    _mermaPctCtrl.dispose();
    _precioKgCtrl.dispose();
    super.dispose();
  }

  void _onTipoVentaChanged(SalePresentation nueva) {
    setState(() {
      _tipoVenta = nueva;
      if (nueva == SalePresentation.vivo) {
        _mermaPctCtrl.text = '0.0';
        _baseCobro = 'peso_vivo';
      } else if (nueva == SalePresentation.medioEviscerado) {
        _mermaPctCtrl.text = '10.0';
      } else if (nueva == SalePresentation.evisceradoCompleto) {
        _mermaPctCtrl.text = '16.5';
      }
      _recalculateFromPesoVivo();
    });
  }

  void _recalculateFromPesoVivo() {
    if (_isAutoCalculating) return;
    _isAutoCalculating = true;

    final pesoVivo = double.tryParse(_pesoVivoKgCtrl.text.replaceAll(',', '.')) ?? 0.0;
    final mermaPct = double.tryParse(_mermaPctCtrl.text.replaceAll(',', '.')) ?? 0.0;

    if (_tipoVenta == SalePresentation.vivo) {
      _pesoArregladoKgCtrl.text = pesoVivo.toStringAsFixed(1);
    } else {
      final mermaKg = pesoVivo * (mermaPct / 100.0);
      final pesoArreglado = (pesoVivo - mermaKg).clamp(0.0, pesoVivo);
      _pesoArregladoKgCtrl.text = pesoArreglado.toStringAsFixed(1);
    }

    _isAutoCalculating = false;
  }

  void _recalculateFromPesoArreglado() {
    if (_isAutoCalculating) return;
    _isAutoCalculating = true;

    final pesoArreglado = double.tryParse(_pesoArregladoKgCtrl.text.replaceAll(',', '.')) ?? 0.0;
    final pesoVivo = double.tryParse(_pesoVivoKgCtrl.text.replaceAll(',', '.')) ?? 0.0;

    if (pesoVivo > 0 && pesoArreglado <= pesoVivo) {
      final mermaKg = pesoVivo - pesoArreglado;
      final mermaPct = (mermaKg / pesoVivo) * 100.0;
      _mermaPctCtrl.text = mermaPct.toStringAsFixed(1);
    }

    _isAutoCalculating = false;
  }

  @override
  Widget build(BuildContext context) {
    final pondsState = ref.watch(pondsProvider);
    final salesState = ref.watch(salesProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final activeBatches = pondsState.batches.where((b) => b.estado == BatchStatus.active).toList();

    // Sincronizar estanques con lotes activos
    final availablePonds = pondsState.ponds.where((p) {
      return activeBatches.any((b) => b.estanqueId == p.id);
    }).toList();

    if (_selectedPondId == null && availablePonds.isNotEmpty) {
      _selectedPondId = availablePonds.first.id;
    }

    // Filtrar lotes correspondientes al estanque seleccionado
    final batchesInPond = activeBatches.where((b) => b.estanqueId == _selectedPondId).toList();

    if ((_selectedBatchId == null || !batchesInPond.any((b) => b.id == _selectedBatchId)) &&
        batchesInPond.isNotEmpty) {
      _selectedBatchId = batchesInPond.first.id;
    }

    final selectedBatch = activeBatches.where((b) => b.id == _selectedBatchId).firstOrNull;
    final selectedPond = pondsState.ponds.where((p) => p.id == _selectedPondId).firstOrNull;

    final stockDisponibleKg = selectedBatch?.biomasaActualKg ?? 0.0;
    final stockPecesDisponible = selectedBatch?.cantidadActualPeces ?? 0;

    // Cálculos dinámicos
    final cantPeces = CurrencyFormatters.parseCOP(_cantidadPecesCtrl.text).toInt();
    final pesoVivoKg = double.tryParse(_pesoVivoKgCtrl.text.replaceAll(',', '.')) ?? 0.0;
    final pesoArregladoKg = double.tryParse(_pesoArregladoKgCtrl.text.replaceAll(',', '.')) ?? pesoVivoKg;
    final mermaKg = (pesoVivoKg - pesoArregladoKg).clamp(0.0, pesoVivoKg);
    final mermaPct = pesoVivoKg > 0 ? (mermaKg / pesoVivoKg) * 100.0 : 0.0;
    final mermaGPpe = cantPeces > 0 ? (mermaKg * 1000.0) / cantPeces : 0.0;
    final pesoPromedioG = (cantPeces > 0 && pesoVivoKg > 0) ? (pesoVivoKg * 1000.0) / cantPeces : (selectedBatch?.pesoActualGramos ?? 0.0);

    final precioKg = CurrencyFormatters.parseCOP(_precioKgCtrl.text);
    final baseKgFacturar = _baseCobro == 'peso_vivo' ? pesoVivoKg : pesoArregladoKg;
    final ingresoBruto = baseKgFacturar * precioKg;

    final cpk = (selectedBatch != null && selectedBatch.biomasaActualKg > 0)
        ? (selectedBatch.costoTotal / selectedBatch.biomasaActualKg)
        : (selectedBatch?.cpk ?? 0.0);
    final cogs = pesoVivoKg * cpk; // El costo de producción se aplica a la biomasa viva retirada del estanque
    final utilidadNeta = ingresoBruto - cogs;
    final margenPct = ingresoBruto > 0 ? (utilidadNeta / ingresoBruto) * 100.0 : 0.0;

    final stockInsuficiente = selectedBatch != null && (pesoVivoKg <= 0 || pesoVivoKg > (stockDisponibleKg + 0.5));

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 20),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 540),
        child: GlassContainer(
          borderRadius: 24,
          padding: const EdgeInsets.all(22),
          blur: 24,
          opacity: isDark ? 0.16 : 0.96,
          borderColor: AppColors.greenBiomass.withValues(alpha: 0.35),
          child: Form(
            key: _formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Cabecera Modal
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
                            child: const Icon(Icons.point_of_sale_rounded, color: AppColors.greenBiomass, size: 22),
                          ),
                          const SizedBox(width: 10),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Registro de Venta y Cosecha',
                                style: AppTypography.titleMedium.copyWith(
                                  color: isDark ? Colors.white : AppColors.textPrimaryLight,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              Text(
                                'Vivo, media tripa y eviscerado con control de merma',
                                style: AppTypography.labelMicro.copyWith(
                                  color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                                ),
                              ),
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

                  // ─── SECCIÓN 1: DATOS DE VENTA & COMPRADOR ─────────────────────────
                  _buildSectionHeader('1. DATOS DEL COMPRADOR & FECHA', Icons.person_pin_rounded),
                  const SizedBox(height: 8),

                  GlassDatePickerField(
                    label: 'FECHA DE COSECHA / VENTA',
                    accentColor: AppColors.greenBiomass,
                    initialDate: _fechaVenta,
                    onDateChanged: (d) => setState(() => _fechaVenta = d),
                  ),
                  const SizedBox(height: 10),

                  // Selector de clientes registrados + botón nuevo
                  if (salesState.clients.isNotEmpty) ...[
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.06),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: salesState.clients.any((c) => c.id == _selectedClientId) ? _selectedClientId : null,
                          hint: Text('Cargar cliente frecuente...', style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondaryDark)),
                          dropdownColor: AppColors.surfaceDark,
                          isExpanded: true,
                          icon: const Icon(Icons.keyboard_arrow_down_rounded, color: AppColors.greenBiomass),
                          items: salesState.clients.map((c) {
                            return DropdownMenuItem<String>(
                              value: c.id,
                              child: Text(
                                '${c.nombre} ${c.cedulaNit != null ? "- ${c.cedulaNit}" : ""}',
                                style: const TextStyle(color: Colors.white, fontSize: 13),
                              ),
                            );
                          }).toList(),
                          onChanged: (val) {
                            if (val != null) {
                              final matched = salesState.clients.firstWhere((c) => c.id == val);
                              setState(() {
                                _selectedClientId = matched.id;
                                _clienteNombreCtrl.text = matched.nombre;
                                if (matched.cedulaNit != null) {
                                  _clienteCedulaCtrl.text = matched.cedulaNit!;
                                }
                              });
                            }
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                  ] else ...[
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.03),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.info_outline_rounded, size: 16, color: AppColors.textSecondaryDark),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Sin clientes frecuentes registrados. Se guardará automáticamente al registrar.',
                              style: AppTypography.labelMicro.copyWith(color: AppColors.textSecondaryDark),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 10),
                  ],

                  Row(
                    children: [
                      Expanded(
                        flex: 3,
                        child: GlassFormField(
                          label: 'NOMBRE COMPLETO DEL COMPRADOR',
                          hint: 'Ej: Distribuidora Neiva / Juan Pérez',
                          controller: _clienteNombreCtrl,
                          prefixIcon: Icons.person_outline_rounded,
                          isRequired: true,
                          showClearButton: true,
                          accentColor: AppColors.greenBiomass,
                          validator: (v) => v == null || v.trim().isEmpty ? 'Ingresa el nombre del comprador' : null,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        flex: 2,
                        child: GlassFormField(
                          label: 'CÉDULA / NIT',
                          hint: 'Ej: 1075283921 / 900...',
                          controller: _clienteCedulaCtrl,
                          prefixIcon: Icons.badge_outlined,
                          isRequired: true,
                          showClearButton: true,
                          accentColor: AppColors.greenBiomass,
                          validator: (v) => v == null || v.trim().isEmpty ? 'Cédula/NIT requerida' : null,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),

                  // ─── SECCIÓN 2: ORIGEN (ESTANQUE & ESPECIE) ────────────────────────
                  _buildSectionHeader('2. ORIGEN DE LA BIOMASA', Icons.pool_rounded),
                  const SizedBox(height: 8),

                  Row(
                    children: [
                      // Selector de Estanque
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('ESTANQUE', style: AppTypography.labelMicro.copyWith(color: AppColors.textSecondaryDark)),
                            const SizedBox(height: 4),
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
                                  items: availablePonds.map((p) {
                                    return DropdownMenuItem<String>(
                                      value: p.id,
                                      child: Text(p.nombreLimpio, style: const TextStyle(color: Colors.white, fontSize: 13)),
                                    );
                                  }).toList(),
                                  onChanged: (val) {
                                    setState(() {
                                      _selectedPondId = val;
                                      final batches = activeBatches.where((b) => b.estanqueId == val).toList();
                                      if (batches.isNotEmpty) {
                                        _selectedBatchId = batches.first.id;
                                        _pesoVivoKgCtrl.text = batches.first.biomasaActualKg.toStringAsFixed(1);
                                        _cantidadPecesCtrl.text = batches.first.cantidadActualPeces.toString();
                                        _recalculateFromPesoVivo();
                                      }
                                    });
                                  },
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 10),

                      // Selector de Especie / Lote
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('ESPECIE / LOTE', style: AppTypography.labelMicro.copyWith(color: AppColors.textSecondaryDark)),
                            const SizedBox(height: 4),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.06),
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
                              ),
                              child: DropdownButtonHideUnderline(
                                child: DropdownButton<String>(
                                  value: _selectedBatchId,
                                  dropdownColor: AppColors.surfaceDark,
                                  isExpanded: true,
                                  icon: const Icon(Icons.keyboard_arrow_down_rounded, color: AppColors.cyanWater),
                                  items: batchesInPond.map((b) {
                                    return DropdownMenuItem<String>(
                                      value: b.id,
                                      child: Text('${b.especie} (${b.codigoLote})', style: const TextStyle(color: Colors.white, fontSize: 13)),
                                    );
                                  }).toList(),
                                  onChanged: (val) {
                                    setState(() {
                                      _selectedBatchId = val;
                                      _pesoVivoKgCtrl.clear();
                                      _cantidadPecesCtrl.clear();
                                      _recalculateFromPesoVivo();
                                    });
                                  },
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  if (selectedBatch != null) ...[
                    const SizedBox(height: 6),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Disponible: ${stockDisponibleKg.toStringAsFixed(1)} kg • $stockPecesDisponible peces',
                          style: AppTypography.labelMicro.copyWith(color: AppColors.cyanWater),
                        ),

                        InkWell(
                          onTap: () {
                            setState(() {
                              _pesoVivoKgCtrl.text = stockDisponibleKg.toStringAsFixed(1);
                              _cantidadPecesCtrl.text = stockPecesDisponible.toString();
                              _recalculateFromPesoVivo();
                            });
                          },
                          child: Text(
                            'Cosechar Todo (100%)',
                            style: AppTypography.labelMicro.copyWith(color: AppColors.greenBiomass, fontWeight: FontWeight.w700),
                          ),
                        ),
                      ],
                    ),
                  ],
                  const SizedBox(height: 18),

                  // ─── SECCIÓN 3: TIPO DE VENTA & MERMA ──────────────────────────────
                  _buildSectionHeader('3. TIPO DE PRESENTACIÓN & MERMA', Icons.restaurant_menu_rounded),
                  const SizedBox(height: 8),

                  // Selector Segmentado de Presentación
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.06),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
                    ),
                    child: Row(
                      children: [
                        _PresentationTab(
                          label: 'Vivo',
                          sub: '0% merma',
                          icon: Icons.waves_rounded,
                          isSelected: _tipoVenta == SalePresentation.vivo,
                          onTap: () => _onTipoVentaChanged(SalePresentation.vivo),
                        ),
                        _PresentationTab(
                          label: 'Media Tripa',
                          sub: '~10% merma',
                          icon: Icons.content_cut_rounded,
                          isSelected: _tipoVenta == SalePresentation.medioEviscerado,
                          onTap: () => _onTipoVentaChanged(SalePresentation.medioEviscerado),
                        ),
                        _PresentationTab(
                          label: 'Eviscerado',
                          sub: '~16.5% merma',
                          icon: Icons.cleaning_services_rounded,
                          isSelected: _tipoVenta == SalePresentation.evisceradoCompleto,
                          onTap: () => _onTipoVentaChanged(SalePresentation.evisceradoCompleto),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Parámetros de Biometría & Rendimiento
                  Row(
                    children: [
                      Expanded(
                        child: GlassFormField(
                          label: 'CANTIDAD PECES',
                          hint: 'Ej: 500',
                          controller: _cantidadPecesCtrl,
                          keyboardType: TextInputType.number,
                          inputFormatters: [IntegerThousandsFormatter()],
                          prefixIcon: Icons.set_meal_outlined,
                          isRequired: true,
                          accentColor: AppColors.cyanWater,
                          validator: (val) {
                            final n = CurrencyFormatters.parseCOP(val).toInt();
                            if (n <= 0) return 'Ingresa peces (> 0)';
                            if (stockPecesDisponible > 0 && n > stockPecesDisponible) {
                              return 'Supera stock ($stockPecesDisponible)';
                            }
                            return null;
                          },
                          onChanged: (_) => setState(() {}),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: GlassFormField(
                          label: 'PESO VIVO (kg)',
                          hint: 'Ej: 250.0',
                          controller: _pesoVivoKgCtrl,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          prefixIcon: Icons.scale_rounded,
                          isRequired: true,
                          accentColor: AppColors.cyanWater,
                          validator: (val) {
                            final p = double.tryParse(val?.replaceAll(',', '.').trim() ?? '');
                            if (p == null || p <= 0) return 'Ingresa peso (> 0)';
                            if (stockDisponibleKg > 0 && p > (stockDisponibleKg + 0.5)) {
                              return 'Supera biomasa (${stockDisponibleKg.toStringAsFixed(1)} kg)';
                            }
                            return null;
                          },
                          onChanged: (_) {
                            _recalculateFromPesoVivo();
                            setState(() {});
                          },
                        ),
                      ),
                    ],
                  ),

                  if (_tipoVenta != SalePresentation.vivo) ...[
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: GlassFormField(
                            label: '% MERMA VÍSCERAS',
                            hint: '10.0',
                            controller: _mermaPctCtrl,
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            prefixIcon: Icons.percent_rounded,
                            isRequired: true,
                            accentColor: AppColors.amberWarning,
                            onChanged: (_) {
                              _recalculateFromPesoVivo();
                              setState(() {});
                            },
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: GlassFormField(
                            label: 'PESO ARREGLADO (kg)',
                            hint: 'Ej: 225.0',
                            controller: _pesoArregladoKgCtrl,
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            prefixIcon: Icons.shopping_bag_outlined,
                            isRequired: true,
                            accentColor: AppColors.greenBiomass,
                            onChanged: (_) {
                              _recalculateFromPesoArreglado();
                              setState(() {});
                            },
                          ),
                        ),
                      ],
                    ),

                    // Tarjeta Resumen de Merma
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        color: AppColors.amberWarning.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: AppColors.amberWarning.withValues(alpha: 0.3)),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.pie_chart_outline_rounded, color: AppColors.amberWarning, size: 18),
                              const SizedBox(width: 8),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Merma total: ${mermaKg.toStringAsFixed(1)} kg (${mermaPct.toStringAsFixed(1)}%)',
                                    style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w700),
                                  ),
                                  if (mermaGPpe > 0)
                                    Text(
                                      'Pérdida por pez: ~${mermaGPpe.toStringAsFixed(0)} g/pez (peso prom: ${pesoPromedioG.toStringAsFixed(0)} g)',
                                      style: AppTypography.labelMicro.copyWith(color: AppColors.textSecondaryDark),
                                    ),
                                ],
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(height: 18),

                  // ─── SECCIÓN 4: CALCULADOR AUTOMÁTICO ─────────────────────────────
                  _buildSectionHeader('4. LIQUIDACIÓN COMERCIAL', Icons.calculate_rounded),
                  const SizedBox(height: 8),

                  Row(
                    children: [
                      Expanded(
                        flex: 3,
                        child: GlassFormField(
                          label: 'PRECIO / KG (\$ COP)',
                          hint: 'Ej: \$ 9.500',
                          controller: _precioKgCtrl,
                          keyboardType: TextInputType.number,
                          inputFormatters: [CurrencyInputFormatter()],
                          prefixIcon: Icons.monetization_on_outlined,
                          isRequired: true,
                          accentColor: AppColors.greenBiomass,
                          validator: (val) {
                            final p = CurrencyFormatters.parseCOP(val);
                            if (p <= 0) return 'Ingresa precio (> 0)';
                            return null;
                          },
                          onChanged: (_) => setState(() {}),
                        ),
                      ),
                      if (_tipoVenta != SalePresentation.vivo) ...[
                        const SizedBox(width: 10),
                        Expanded(
                          flex: 3,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('BASE COBRO', style: AppTypography.labelMicro.copyWith(color: AppColors.textSecondaryDark)),
                              const SizedBox(height: 4),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.06),
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
                                ),
                                child: DropdownButtonHideUnderline(
                                  child: DropdownButton<String>(
                                    value: _baseCobro,
                                    dropdownColor: AppColors.surfaceDark,
                                    isExpanded: true,
                                    items: const [
                                      DropdownMenuItem(value: 'peso_vivo', child: Text('S/Peso Vivo', style: TextStyle(color: Colors.white, fontSize: 12))),
                                      DropdownMenuItem(value: 'peso_arreglado', child: Text('S/Peso Arreglado', style: TextStyle(color: Colors.white, fontSize: 12))),
                                    ],
                                    onChanged: (val) {
                                      if (val != null) setState(() => _baseCobro = val);
                                    },
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Panel Financiero en Tiempo Real
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceDark.withValues(alpha: 0.85),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
                    ),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Facturación (${baseKgFacturar.toStringAsFixed(1)} kg @ ${CurrencyFormatters.formatCOP(precioKg)}):',
                              style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondaryDark),
                            ),
                            Text(CurrencyFormatters.formatCOP(ingresoBruto), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 14)),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('Costo Producción Lote (COGS):', style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondaryDark)),
                            Text('- ${CurrencyFormatters.formatCOP(cogs)}', style: const TextStyle(color: AppColors.coralAction, fontWeight: FontWeight.w700, fontSize: 13)),
                          ],
                        ),
                        const Divider(color: Colors.white12, height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('UTILIDAD NETA ESTIMADA:', style: AppTypography.bodyMedium.copyWith(color: Colors.white, fontWeight: FontWeight.w900)),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  CurrencyFormatters.formatCOP(utilidadNeta),
                                  style: const TextStyle(color: AppColors.greenBiomass, fontSize: 16, fontWeight: FontWeight.w900),
                                ),
                                Text('Margen: ${margenPct.toStringAsFixed(1)}%', style: AppTypography.labelMicro.copyWith(color: AppColors.purpleAnalytics, fontWeight: FontWeight.w700)),
                              ],
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  if (stockInsuficiente) ...[
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppColors.coralAction.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.coralAction.withValues(alpha: 0.4)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.warning_amber_rounded, color: AppColors.coralAction, size: 18),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              pesoVivoKg <= 0
                                  ? 'Ingresa una biomasa válida para cosechar.'
                                  : '⚠️ El peso vivo (${pesoVivoKg.toStringAsFixed(1)} kg) supera la biomasa actual del lote (${stockDisponibleKg.toStringAsFixed(1)} kg).',
                              style: const TextStyle(color: Colors.white, fontSize: 11.5, fontWeight: FontWeight.w700),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(height: 20),

                  // Botón Verde Prominente: Registrar Venta
                  GlassButton(
                    label: 'Registrar Venta',
                    backgroundColor: AppColors.greenBiomass,
                    isLoading: _isSaving,
                    onPressed: (selectedBatch == null || stockInsuficiente)
                        ? null
                        : () async {
                            if (!_formKey.currentState!.validate()) return;

                            final authState = ref.read(authProvider);
                            final user = authState.currentUser;
                            final empresaId = authState.currentCompany?.id ?? user?.empresaId;
                            final unitId = authState.activeUnitId ?? user?.unidadAcuicolaId ?? empresaId ?? '';

                            if (empresaId == null || empresaId.isEmpty) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Error: No se encontró una empresa activa en la sesión.'),
                                  backgroundColor: AppColors.coralAction,
                                ),
                              );
                              return;
                            }

                            final saleDraft = BatchSale(
                              id: const Uuid().v4(),
                              empresaId: empresaId,
                              unidadAcuicolaId: unitId,
                              loteId: selectedBatch.id,
                              codigoLote: selectedBatch.codigoLote,
                              estanqueNombre: selectedPond?.nombreLimpio ?? 'Estanque',
                              clienteId: _selectedClientId,
                              clienteNombre: _clienteNombreCtrl.text.trim(),
                              clienteCedulaNit: _clienteCedulaCtrl.text.trim(),
                              especie: selectedBatch.especie,
                              tipoVenta: _tipoVenta,
                              cantidadPeces: cantPeces,
                              pesoVivoKg: pesoVivoKg,
                              pesoArregladoKg: pesoArregladoKg,
                              mermaKg: mermaKg,
                              mermaPct: mermaPct,
                              mermaGPpe: mermaGPpe,
                              baseCobro: _baseCobro,
                              biomasaVendidaKg: pesoVivoKg,
                              precioUnitarioKg: precioKg,
                              ingresoBruto: ingresoBruto,
                              cogs: cogs,
                              utilidadNeta: utilidadNeta,
                              estadoPago: 'Pagado',
                              pesoPromedioG: pesoPromedioG,
                              porcentajeViscerasPct: mermaPct,
                              creadoEn: _fechaVenta.toDateTime(),
                            );

                            final nav = Navigator.of(context);
                            final messenger = ScaffoldMessenger.of(context);

                            // Abrir Modal de Confirmación y Resumen antes de proceder
                            final confirmed = await showDialog<bool>(
                              context: context,
                              builder: (ctx) => ConfirmarVentaDialog(
                                sale: saleDraft,
                                onConfirm: () => Navigator.of(ctx).pop(true),
                              ),
                            );

                            if (confirmed != true || !mounted) return;

                            setState(() => _isSaving = true);

                            // Registrar cliente si es nuevo
                            if (_selectedClientId == null) {
                              try {
                                final newClient = Client(
                                  id: const Uuid().v4(),
                                  empresaId: empresaId,
                                  nombre: _clienteNombreCtrl.text.trim(),
                                  cedulaNit: _clienteCedulaCtrl.text.trim(),
                                  creadoEn: DateTime.now(),
                                );
                                await ref.read(salesProvider.notifier).addClient(newClient);
                              } catch (_) {}
                            }

                            final success = await ref.read(salesProvider.notifier).recordSale(saleDraft);
                            if (mounted) {
                              setState(() => _isSaving = false);
                              if (success) {
                                await ref.read(pondsProvider.notifier).loadPondsAndBatches();
                                nav.pop();
                                messenger.showSnackBar(
                                  const SnackBar(
                                    content: Text('¡Venta registrada y comprobante generado con éxito!'),
                                    backgroundColor: AppColors.greenBiomass,
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

  Widget _buildSectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 14, color: AppColors.greenBiomass),
        const SizedBox(width: 6),
        Text(
          title,
          style: AppTypography.labelMicro.copyWith(
            color: AppColors.greenBiomass,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.1,
          ),
        ),
      ],
    );
  }
}

class _PresentationTab extends StatelessWidget {
  final String label;
  final String sub;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  const _PresentationTab({
    required this.label,
    required this.sub,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.greenBiomass.withValues(alpha: 0.22) : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            border: isSelected ? Border.all(color: AppColors.greenBiomass.withValues(alpha: 0.7)) : null,
          ),
          child: Column(
            children: [
              Icon(icon, size: 18, color: isSelected ? AppColors.greenBiomass : AppColors.textSecondaryDark),
              const SizedBox(height: 3),
              Text(
                label,
                style: TextStyle(
                  color: isSelected ? Colors.white : AppColors.textSecondaryDark,
                  fontSize: 11.5,
                  fontWeight: isSelected ? FontWeight.w800 : FontWeight.w500,
                ),
              ),
              Text(
                sub,
                style: TextStyle(
                  color: isSelected ? AppColors.greenBiomass : AppColors.textTertiaryDark,
                  fontSize: 9,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
