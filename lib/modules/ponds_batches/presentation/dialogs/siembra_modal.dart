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
import 'package:fishbit_finance/modules/ponds_batches/domain/models/fish_batch.dart';
import 'package:fishbit_finance/modules/ponds_batches/domain/models/pond.dart';
import 'package:fishbit_finance/modules/ponds_batches/presentation/providers/ponds_provider.dart';
import 'package:fishbit_finance/modules/warehouse_inventory/domain/models/inventory_item.dart';
import 'package:fishbit_finance/modules/warehouse_inventory/presentation/dialogs/nuevo_item_modal.dart';
import 'package:fishbit_finance/modules/warehouse_inventory/presentation/dialogs/nueva_factura_modal.dart';
import 'package:fishbit_finance/modules/warehouse_inventory/presentation/providers/warehouse_provider.dart';

class SiembraModal extends ConsumerStatefulWidget {
  final Pond? initialPond;

  const SiembraModal({super.key, this.initialPond});

  static Future<void> show(BuildContext context, {Pond? pond}) {
    return showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => SiembraModal(initialPond: pond),
    );
  }

  @override
  ConsumerState<SiembraModal> createState() => _SiembraModalState();
}

class _SiembraModalState extends ConsumerState<SiembraModal> {
  final _formKey = GlobalKey<FormState>();
  final _codigoCtrl = TextEditingController();
  final _pecesCtrl = TextEditingController(text: '5000');
  final _pesoCtrl = TextEditingController(text: '1.5');
  final _costoAlevinosCtrl = TextEditingController(text: '0');

  String _selectedEspecie = 'Tilapia Roja';
  String? _selectedPondId;
  String? _selectedInventoryItemId;
  CivilDate _fechaSiembra = CivilDate.today();
  bool _costoModificadoManualmente = false;

  final List<String> _especies = [
    'Tilapia Roja',
    'Cachama Negra',
    'Trucha Arcoíris',
    'Bocachico',
    'Pangasius',
  ];

  @override
  void initState() {
    super.initState();
    _selectedPondId = widget.initialPond?.id;
    final company = ref.read(authProvider).currentCompany;
    if (company != null && company.especiesHabilitadas.isNotEmpty) {
      _selectedEspecie = company.especiesHabilitadas.first;
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final company = ref.read(authProvider).currentCompany;
    if (company != null && company.especiesHabilitadas.isNotEmpty) {
      if (!company.especiesHabilitadas.contains(_selectedEspecie)) {
        _selectedEspecie = company.especiesHabilitadas.first;
      }
    }
    _actualizarCodigoLote();
    _recalcularCostoAutomatico();
  }

  @override
  void dispose() {
    _codigoCtrl.dispose();
    _pecesCtrl.dispose();
    _pesoCtrl.dispose();
    _costoAlevinosCtrl.dispose();
    super.dispose();
  }

  /// Generar código estandarizado: LOT-(SIGLA)-(Fecha)-Especie
  void _actualizarCodigoLote() {
    final pondsState = ref.read(pondsProvider);
    final allPonds = pondsState.ponds;
    final pond = allPonds.where((p) => p.id == (_selectedPondId ?? (allPonds.isNotEmpty ? allPonds.first.id : null))).firstOrNull;

    final authState = ref.read(authProvider);
    final activeUnit = authState.units.where((u) => u.id == authState.activeUnitId).firstOrNull;
    final sigla = (pond?.sigla.isNotEmpty == true)
        ? pond!.sigla.trim().toUpperCase().replaceAll(' ', '')
        : (activeUnit?.sigla ?? 'SEDE');

    final fecha = _fechaSiembra.toDateTime();
    final fechaStr = '${fecha.year}${fecha.month.toString().padLeft(2, '0')}${fecha.day.toString().padLeft(2, '0')}';
    final especieSanitized = _selectedEspecie.trim().replaceAll(' ', '').toUpperCase();

    _codigoCtrl.text = 'LOT-$sigla-$fechaStr-$especieSanitized';
  }

  /// Recalcular costo total de alevinos según lote seleccionado en almacén o promedio
  void _recalcularCostoAutomatico() {
    if (_costoModificadoManualmente) return;
    final warehouseState = ref.read(warehouseProvider);
    final alevinosDisponibles = warehouseState.getAlevinosForSpecies(_selectedEspecie);

    double costoUnitario = 0.0;
    if (_selectedInventoryItemId != null) {
      final selectedItem = alevinosDisponibles.where((i) => i.id == _selectedInventoryItemId).firstOrNull;
      if (selectedItem != null) {
        costoUnitario = selectedItem.costoUnitarioHistorico;
      }
    }

    if (costoUnitario <= 0) {
      costoUnitario = warehouseState.getCostoUnitarioAlevino(_selectedEspecie);
    }

    final peces = int.tryParse(_pecesCtrl.text) ?? 0;

    if (costoUnitario > 0) {
      final total = peces * costoUnitario;
      _costoAlevinosCtrl.text = total.toStringAsFixed(0);
    } else {
      _costoAlevinosCtrl.text = '0';
    }
  }

  double get _biomasaCalculadaKg {
    final peces = int.tryParse(_pecesCtrl.text) ?? 0;
    final pesoG = double.tryParse(_pesoCtrl.text) ?? 0.0;
    return (peces * pesoG) / 1000.0;
  }

  Future<void> _handleSiembra() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedPondId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Por favor selecciona un estanque.')),
      );
      return;
    }

    final warehouseState = ref.read(warehouseProvider);
    final alevinosDisponibles = warehouseState.getAlevinosForSpecies(_selectedEspecie);
    final stockDisponible = warehouseState.getTotalAlevinosDisponibles(_selectedEspecie);
    final peces = int.tryParse(_pecesCtrl.text) ?? 0;

    if (stockDisponible <= 0 || alevinosDisponibles.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('No hay material genético disponible de $_selectedEspecie en almacén. Debe registrar una compra primero.'),
          backgroundColor: AppColors.waterCritical,
        ),
      );
      return;
    }

    if (_selectedInventoryItemId == null || _selectedInventoryItemId!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Por favor selecciona el lote específico de alevinos de almacén para garantizar trazabilidad.'),
          backgroundColor: AppColors.amberWarning,
        ),
      );
      return;
    }

    final selectedSeedItem = alevinosDisponibles.where((i) => i.id == _selectedInventoryItemId).firstOrNull;
    if (selectedSeedItem == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('El lote de semilla seleccionado ya no se encuentra disponible.'),
          backgroundColor: AppColors.waterCritical,
        ),
      );
      return;
    }

    if (peces > selectedSeedItem.cantidadActualKg) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('La cantidad a sembrar ($peces) supera el saldo disponible del lote seleccionado (${selectedSeedItem.cantidadActualKg.toInt()} pcs).'),
          backgroundColor: AppColors.waterCritical,
        ),
      );
      return;
    }

    final authState = ref.read(authProvider);
    final empresaId = authState.currentUser?.empresaId ?? 'c1000000-0000-0000-0000-000000000001';
    final unidadId = authState.activeUnitId ?? 'u1000000-0000-0000-0000-000000000001';

    final pesoG = double.tryParse(_pesoCtrl.text) ?? 1.5;
    final costoAlevinos = double.tryParse(_costoAlevinosCtrl.text) ?? 0.0;
    final biomasaKg = _biomasaCalculadaKg;

    final pondsState = ref.read(pondsProvider);
    final selectedPond = pondsState.ponds.where((p) => p.id == _selectedPondId).firstOrNull;
    final activeUnitSigla = authState.units.where((u) => u.id == authState.activeUnitId).firstOrNull?.sigla;
    final pondSigla = selectedPond?.unidadAcuicolaSigla ??
        (selectedPond?.sigla.contains('-') == true ? selectedPond!.sigla.split('-').last : null) ??
        activeUnitSigla ??
        'PRIN';

    final existingBatches = pondsState.batches.where((b) => b.estanqueId == _selectedPondId && b.estado == BatchStatus.active).toList();
    final isPolyculture = existingBatches.isNotEmpty;

    final batch = FishBatch(
      id: const Uuid().v4(),
      empresaId: empresaId,
      unidadAcuicolaId: unidadId,
      unidadAcuicolaSigla: pondSigla,
      estanqueId: _selectedPondId!,
      codigoLote: _codigoCtrl.text.trim(),
      especie: _selectedEspecie,
      rolPolicultivo: isPolyculture ? 'secundaria' : 'principal',
      cantidadInicialPeces: peces,
      cantidadActualPeces: peces,
      pesoInicialGramos: pesoG,
      pesoActualGramos: pesoG,
      biomasaInicialKg: biomasaKg,
      biomasaActualKg: biomasaKg,
      costoInicialAlevinos: costoAlevinos,
      costoAcumuladoInsumos: 0.0,
      costoAcumuladoFijo: 0.0,
      estado: BatchStatus.active,
      fechaSiembra: _fechaSiembra.toDateTime(),
      creadoEn: DateTime.now(),
    );

    final nav = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);

    try {
      // 1. Plantar el lote
      final success = await ref.read(pondsProvider.notifier).plantBatch(batch);
      if (success) {
        // 2. Descontar con trazabilidad estricta del lote específico en almacén
        await ref.read(warehouseProvider.notifier).discountAlevinosSiembra(
          especie: _selectedEspecie,
          cantidadPeces: peces.toDouble(),
          specificItemId: _selectedInventoryItemId,
        );

        if (mounted) {
          nav.pop();
          messenger.showSnackBar(
            SnackBar(
              content: Text('¡Lote ${batch.codigoLote} sembrado con éxito! Stock descontado de "${selectedSeedItem.nombre}".'),
              backgroundColor: AppColors.greenBiomass,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        messenger.showSnackBar(
          SnackBar(
            content: Text('Error al sembrar lote: $e'),
            backgroundColor: AppColors.waterCritical,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final pondsState = ref.watch(pondsProvider);
    final warehouseState = ref.watch(warehouseProvider);
    final allPonds = pondsState.ponds;
    final selectedPond = allPonds.where((p) => p.id == (_selectedPondId ?? (allPonds.isNotEmpty ? allPonds.first.id : null))).firstOrNull;
    final activeBatchesInSelected = selectedPond != null
        ? pondsState.batches.where((b) => b.estanqueId == selectedPond.id && b.estado == BatchStatus.active).toList()
        : <FishBatch>[];
    final isPolycultureTarget = activeBatchesInSelected.isNotEmpty;

    final alevinosDisponibles = warehouseState.getAlevinosForSpecies(_selectedEspecie).where((i) => i.cantidadActualKg > 0).toList();
    final stockDisponible = warehouseState.getTotalAlevinosDisponibles(_selectedEspecie);
    final bool sinMaterialGenetico = stockDisponible <= 0;

    if (_selectedInventoryItemId != null && !alevinosDisponibles.any((i) => i.id == _selectedInventoryItemId)) {
      _selectedInventoryItemId = null;
    }
    if (_selectedInventoryItemId == null && alevinosDisponibles.length == 1) {
      _selectedInventoryItemId = alevinosDisponibles.first.id;
    }

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 520),
        child: GlassContainer(
          borderRadius: 24,
          padding: const EdgeInsets.all(24),
          blur: 24,
          opacity: 0.14,
          borderColor: Colors.white.withValues(alpha: 0.18),
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
                          const Icon(Icons.water_drop_rounded, color: AppColors.cyanWater, size: 22),
                          const SizedBox(width: 8),
                          Text('🌱 Nueva Siembra de Peces', style: AppTypography.titleLarge.copyWith(color: AppColors.cyanWater, fontSize: 18)),
                        ],
                      ),
                      IconButton(
                        icon: const Icon(Icons.close_rounded, color: AppColors.textSecondaryDark),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Selector de Estanque
                  Text('ESTANQUE DE DESTINO', style: AppTypography.labelMicro.copyWith(color: AppColors.textSecondaryDark)),
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
                        value: _selectedPondId ?? (allPonds.isNotEmpty ? allPonds.first.id : null),
                        dropdownColor: AppColors.surfaceDark,
                        isExpanded: true,
                        icon: const Icon(Icons.keyboard_arrow_down_rounded, color: AppColors.cyanWater),
                        items: allPonds.map((p) {
                          final batches = pondsState.batches.where((b) => b.estanqueId == p.id && b.estado == BatchStatus.active).toList();
                          final statusLabel = batches.isNotEmpty
                              ? ' (Policultivo: ${batches.map((b) => b.especie).join(", ")})'
                              : ' (Disponible)';

                          return DropdownMenuItem<String>(
                            value: p.id,
                            child: Text(
                              '${p.sigla} - ${p.nombre}$statusLabel',
                              style: TextStyle(
                                color: batches.isNotEmpty ? Colors.purpleAccent : Colors.white,
                                fontSize: 12.5,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          );
                        }).toList(),
                        onChanged: (val) {
                          setState(() {
                            _selectedPondId = val;
                            _actualizarCodigoLote();
                          });
                        },
                      ),
                    ),
                  ),
                  if (isPolycultureTarget) ...[
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.purpleAccent.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.purpleAccent.withValues(alpha: 0.35)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.hub_rounded, color: Colors.purpleAccent, size: 16),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Siembra en Policultivo: Convivirá con ${activeBatchesInSelected.map((b) => b.especie).join(", ")}.',
                              style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(height: 14),

                  // Selector de Especie
                  Text('ESPECIE A SEMBRAR', style: AppTypography.labelMicro.copyWith(color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight)),
                  const SizedBox(height: 6),
                  Builder(
                    builder: (context) {
                      final company = ref.watch(authProvider).currentCompany;
                      final availableSpecies = (company != null && company.especiesHabilitadas.isNotEmpty)
                          ? company.especiesHabilitadas
                          : _especies;

                      if (!availableSpecies.contains(_selectedEspecie) && availableSpecies.isNotEmpty) {
                        _selectedEspecie = availableSpecies.first;
                      }

                      return Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        decoration: BoxDecoration(
                          color: isDark ? Colors.white.withValues(alpha: 0.06) : Colors.white,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: isDark ? Colors.white.withValues(alpha: 0.12) : AppColors.glassBorderLight),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: _selectedEspecie,
                            dropdownColor: isDark ? AppColors.surfaceDark : Colors.white,
                            isExpanded: true,
                            icon: const Icon(Icons.keyboard_arrow_down_rounded, color: AppColors.cyanWater),
                            items: availableSpecies.map((sp) {
                              return DropdownMenuItem<String>(
                                value: sp,
                                child: Text(sp, style: TextStyle(color: isDark ? Colors.white : AppColors.textPrimaryLight, fontSize: 13, fontWeight: FontWeight.w600)),
                              );
                            }).toList(),
                            onChanged: (val) {
                              if (val != null) {
                                setState(() {
                                  _selectedEspecie = val;
                                  _actualizarCodigoLote();
                                  _costoModificadoManualmente = false;
                                  _recalcularCostoAutomatico();
                                });
                              }
                            },
                          ),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 12),

                  // Estado de Almacén / Material Genético (Bento Glass Banner & Selector Estricto de Lote)
                  if (sinMaterialGenetico || alevinosDisponibles.isEmpty) ...[
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: AppColors.waterCritical.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: AppColors.waterCritical.withValues(alpha: 0.4)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.warning_amber_rounded, color: AppColors.waterCritical, size: 20),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'Sin Material Genético en Almacén',
                                  style: AppTypography.titleMedium.copyWith(color: AppColors.waterCritical, fontSize: 13, fontWeight: FontWeight.bold),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'No hay compras ni stock disponible de alevinos/larvas de "$_selectedEspecie". Para sembrar debe existir una compra previa en almacén.',
                            style: AppTypography.bodySmall.copyWith(color: Colors.white70, fontSize: 11.5),
                          ),
                          const SizedBox(height: 10),
                          Row(
                            children: [
                              Expanded(
                                child: ElevatedButton.icon(
                                  icon: const Icon(Icons.receipt_long_rounded, size: 16),
                                  label: const Text('Ingresar Factura', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppColors.cyanWater,
                                    foregroundColor: Colors.black,
                                    padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                  ),
                                  onPressed: () async {
                                    await NuevaFacturaModal.show(context, initialCategory: 'alevinos');
                                    await ref.read(warehouseProvider.notifier).loadWarehouseData();
                                  },
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: OutlinedButton.icon(
                                  icon: const Icon(Icons.add_box_outlined, size: 16),
                                  label: const Text('Entrada Directa', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: Colors.white,
                                    side: const BorderSide(color: Colors.white24),
                                    padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                  ),
                                  onPressed: () async {
                                    await NuevoItemModal.show(context, initialType: InventoryItemType.alevino);
                                    await ref.read(warehouseProvider.notifier).loadWarehouseData();
                                  },
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ] else ...[
                    // Selector Estricto de Lote de Alevinos / Semilla de Almacén
                    Text(
                      'LOTE ESPECÍFICO DE ALEVINOS (TRAZABILIDAD EN BODEGA)',
                      style: AppTypography.labelMicro.copyWith(color: AppColors.cyanWater, fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(
                        color: isDark ? Colors.white.withValues(alpha: 0.06) : Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: _selectedInventoryItemId != null ? AppColors.greenBiomass : AppColors.amberWarning.withValues(alpha: 0.6)),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: _selectedInventoryItemId,
                          hint: const Text(
                            'Seleccionar lote / factura de alevinos...',
                            style: TextStyle(color: AppColors.textSecondaryDark, fontSize: 12),
                          ),
                          dropdownColor: isDark ? AppColors.surfaceDark : Colors.white,
                          isExpanded: true,
                          icon: const Icon(Icons.keyboard_arrow_down_rounded, color: AppColors.cyanWater),
                          items: alevinosDisponibles.map((item) {
                            final prov = item.marcaProveedor?.isNotEmpty == true ? ' • ${item.marcaProveedor}' : '';
                            final lote = item.loteFabricante?.isNotEmpty == true ? ' [Lote: ${item.loteFabricante}]' : '';
                            return DropdownMenuItem<String>(
                              value: item.id,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    '${item.nombre}$prov$lote',
                                    style: TextStyle(
                                      color: isDark ? Colors.white : AppColors.textPrimaryLight,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  Text(
                                    'Disponible: ${item.cantidadActualKg.toInt()} pcs • CPP: \$${item.costoUnitarioHistorico.toStringAsFixed(0)} COP/pez',
                                    style: const TextStyle(color: AppColors.cyanWater, fontSize: 10),
                                  ),
                                ],
                              ),
                            );
                          }).toList(),
                          onChanged: (val) {
                            setState(() {
                              _selectedInventoryItemId = val;
                              _costoModificadoManualmente = false;
                              _recalcularCostoAutomatico();
                            });
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: AppColors.greenBiomass.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.greenBiomass.withValues(alpha: 0.35)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.inventory_2_rounded, color: AppColors.greenBiomass, size: 16),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Stock Total Especie: ${stockDisponible.toInt()} alevinos en almacén',
                              style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(height: 14),

                  // Código de Lote (Formato LOT-(SIGLA)-(Fecha)-Especie)
                  GlassFormField(
                    label: 'CÓDIGO DE LOTE ESTANDARIZADO',
                    controller: _codigoCtrl,
                    prefixIcon: Icons.qr_code_2_rounded,
                    validator: (val) {
                      if (val == null || val.trim().isEmpty) return 'El código de lote es obligatorio';
                      return null;
                    },
                  ),
                  const SizedBox(height: 14),

                  Row(
                    children: [
                      Expanded(
                        child: GlassFormField(
                          label: 'CANTIDAD PECES',
                          controller: _pecesCtrl,
                          keyboardType: TextInputType.number,
                          prefixIcon: Icons.pets_rounded,
                          validator: (val) {
                            final n = int.tryParse(val ?? '');
                            if (n == null || n <= 0) return 'Ingresa cantidad';
                            if (n > stockDisponible && stockDisponible > 0) {
                              return 'Excede stock (${stockDisponible.toInt()})';
                            }
                            return null;
                          },
                          onChanged: (_) {
                            setState(() {
                              _recalcularCostoAutomatico();
                            });
                          },
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: GlassFormField(
                          label: 'PESO PROM. (g)',
                          controller: _pesoCtrl,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          prefixIcon: Icons.scale_rounded,
                          validator: (val) {
                            final n = double.tryParse(val ?? '');
                            if (n == null || n <= 0) return 'Ingresa peso';
                            return null;
                          },
                          onChanged: (_) => setState(() {}),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),

                  // Costo Total Trasladado de Alevinos
                  GlassFormField(
                    label: 'COSTO TOTAL ALEVINOS (\$ COP) [Trasladado de Almacén]',
                    controller: _costoAlevinosCtrl,
                    keyboardType: TextInputType.number,
                    prefixIcon: Icons.monetization_on_outlined,
                    onChanged: (_) {
                      _costoModificadoManualmente = true;
                    },
                  ),
                  const SizedBox(height: 14),

                  GlassDatePickerField(
                    label: 'FECHA DE SIEMBRA',
                    initialDate: _fechaSiembra,
                    onDateChanged: (d) {
                      setState(() {
                        _fechaSiembra = d;
                        _actualizarCodigoLote();
                      });
                    },
                  ),
                  const SizedBox(height: 16),

                  // Resumen de Biomasa y Costo Total Trasladado
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.cyanWater.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: AppColors.cyanWater.withValues(alpha: 0.2)),
                    ),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('Biomasa Inicial Estimada:', style: AppTypography.bodySmall.copyWith(color: Colors.white70)),
                            Text(
                              '${_biomasaCalculadaKg.toStringAsFixed(2)} kg',
                              style: AppTypography.titleMedium.copyWith(color: AppColors.cyanWater, fontWeight: FontWeight.w900),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('Costo Inicial del Lote:', style: AppTypography.bodySmall.copyWith(color: Colors.white70)),
                            Text(
                              '\$${(double.tryParse(_costoAlevinosCtrl.text) ?? 0.0).toStringAsFixed(0)} COP',
                              style: AppTypography.titleMedium.copyWith(color: AppColors.greenBiomass, fontWeight: FontWeight.w900),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  GlassButton(
                    label: sinMaterialGenetico ? 'Material Genético no Disponible' : 'Confirmar Siembra',
                    isLoading: pondsState.isLoading,
                    backgroundColor: sinMaterialGenetico ? Colors.grey.shade700 : AppColors.greenBiomass,
                    onPressed: sinMaterialGenetico ? null : _handleSiembra,
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
