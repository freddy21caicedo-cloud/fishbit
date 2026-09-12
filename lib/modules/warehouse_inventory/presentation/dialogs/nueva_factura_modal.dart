import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import 'package:fishbit_finance/core/design_system/app_colors.dart';
import 'package:fishbit_finance/core/design_system/app_typography.dart';
import 'package:fishbit_finance/core/design_system/glass_container.dart';
import 'package:fishbit_finance/core/design_system/glass_button.dart';
import 'package:fishbit_finance/core/design_system/glass_date_picker.dart';
import 'package:fishbit_finance/core/utils/currency_formatters.dart';
import 'package:fishbit_finance/modules/auth_tenant/presentation/providers/auth_provider.dart';
import 'package:fishbit_finance/modules/warehouse_inventory/domain/models/inventory_item.dart';
import 'package:fishbit_finance/modules/warehouse_inventory/domain/models/purchase_invoice.dart';
import 'package:fishbit_finance/modules/warehouse_inventory/domain/models/supplier.dart';
import 'package:fishbit_finance/modules/warehouse_inventory/presentation/providers/warehouse_provider.dart';



/// Modelo de estado editable para cada fila de producto en la factura
class EditableInvoiceItem {
  String codigo;
  String nombre;
  String loteFabricante;
  String unidadMedida; // 'Bulto 40 Kg', 'Bulto 20 Kg', 'Saco 50 Kg', 'Kg', 'Gramos (g)', 'Litros (L)', 'mL', 'Unidades', 'Millar'
  TextEditingController cantidadCtrl;
  TextEditingController factorUnidadCtrl; // ej. 40 para bulto 40kg, 1.0 para kg/unidad, etc.
  TextEditingController costoUnitarioCtrl;
  TextEditingController ivaPctCtrl;

  EditableInvoiceItem({
    this.codigo = '',
    required this.nombre,
    this.loteFabricante = '',
    this.unidadMedida = 'Bulto 40 Kg',
    String cantidad = '',
    String factorUnidad = '40',
    String costoUnitario = '',
    String ivaPct = '5.0',
  })  : cantidadCtrl = TextEditingController(text: cantidad),
        factorUnidadCtrl = TextEditingController(text: factorUnidad),
        costoUnitarioCtrl = TextEditingController(text: costoUnitario),
        ivaPctCtrl = TextEditingController(text: ivaPct);

  double get cantidad => double.tryParse(cantidadCtrl.text.replaceAll(RegExp(r'[^\d.]'), '')) ?? 0.0;
  double get factorUnidad => double.tryParse(factorUnidadCtrl.text.replaceAll(RegExp(r'[^\d.]'), '')) ?? 1.0;
  double get totalCantidadFisica => cantidad * factorUnidad;
  double get costoUnitario => CurrencyFormatters.parseCOP(costoUnitarioCtrl.text);
  double get ivaPct => double.tryParse(ivaPctCtrl.text.replaceAll(RegExp(r'[^\d.]'), '')) ?? 0.0;

  double get subtotalBruto => cantidad * costoUnitario;
  double get baseGravable => subtotalBruto;
  double get valorIva => baseGravable * (ivaPct / 100.0);
  double get valorTotal => baseGravable + valorIva;
  void dispose() {
    cantidadCtrl.dispose();
    factorUnidadCtrl.dispose();
    costoUnitarioCtrl.dispose();
    ivaPctCtrl.dispose();
  }
}

class NuevaFacturaModal extends ConsumerStatefulWidget {
  final String initialCategory;

  const NuevaFacturaModal({super.key, this.initialCategory = 'concentrados'});

  static Future<void> show(BuildContext context, {String initialCategory = 'concentrados'}) {
    return showDialog(
      context: context,
      barrierDismissible: true,
      builder: (_) => NuevaFacturaModal(initialCategory: initialCategory),
    );
  }

  @override
  ConsumerState<NuevaFacturaModal> createState() => _NuevaFacturaModalState();
}

class _NuevaFacturaModalState extends ConsumerState<NuevaFacturaModal> {
  final _formKey = GlobalKey<FormState>();

  late String _categoriaSeleccionada;
  Supplier? _selectedSupplier;

  // Cabecera de Factura
  final _facturaCtrl = TextEditingController();
  final _fleteCtrl = TextEditingController(text: '\$ 0');
  final _placaCtrl = TextEditingController();
  bool _esCredito = true;
  final _diasCreditoCtrl = TextEditingController(text: '30');
  CivilDate _fechaExpedicion = CivilDate.today();
  CivilDate _fechaVencimiento = CivilDate.today().addDays(30);

  // Lista de Productos en la Factura (Multi-Ítem)
  final List<EditableInvoiceItem> _items = [];

  @override
  void initState() {
    super.initState();
    _categoriaSeleccionada = widget.initialCategory;
    final randomNum = DateTime.now().millisecondsSinceEpoch.toString().substring(7);
    _facturaCtrl.text = 'BQAE $randomNum';
  }

  void _recalcularFechaVencimiento() {
    if (!_esCredito) {
      _fechaVencimiento = _fechaExpedicion;
    } else {
      final dias = int.tryParse(_diasCreditoCtrl.text) ?? 30;
      _fechaVencimiento = _fechaExpedicion.addDays(dias);
    }
  }

  @override
  void dispose() {
    _facturaCtrl.dispose();
    _fleteCtrl.dispose();
    _placaCtrl.dispose();
    _diasCreditoCtrl.dispose();
    for (final item in _items) {
      item.dispose();
    }
    super.dispose();
  }

  void _onCategoryChanged(String newCat, List<Supplier> allSuppliers) {
    setState(() {
      _categoriaSeleccionada = newCat;
      final matching = allSuppliers.where((s) => s.categoriaPrincipal == newCat).toList();
      _selectedSupplier = matching.isNotEmpty ? matching.first : null;
      for (final item in _items) {
        item.dispose();
      }
      _items.clear();
      _addNewItem();
    });
  }

  void _addNewItem([String? defaultName, String? defaultCode, String? defaultLote, String? defaultPrice]) {
    final sup = _selectedSupplier;
    final String prodName = defaultName ?? (sup?.productosOfrecidos.isNotEmpty == true ? sup!.productosOfrecidos.first : 'Producto');
    
    final (defUnidad, defFactor, defIva) = switch (_categoriaSeleccionada) {
      'concentrados' => ('Bulto 40 Kg', '40', '5.0'),
      'insumos' => ('Saco 40 Kg', '40', '0.0'),
      'farmacia' => ('Litro (L)', '1', '19.0'),
      'oxigenadores' => ('Unidad Equipo', '1', '19.0'),
      'alevinos' => ('Millar Alevinos', '1000', '0.0'),
      _ => ('Unidad', '1', '0.0'),
    };

    final item = EditableInvoiceItem(
      codigo: defaultCode ?? '',
      nombre: prodName,
      loteFabricante: defaultLote ?? '',
      unidadMedida: defUnidad,
      cantidad: '10',
      factorUnidad: defFactor,
      costoUnitario: defaultPrice ?? _guessPrice(prodName),
      ivaPct: defIva,
    );

    setState(() {
      _items.add(item);
    });
  }

  String _guessPrice(String name) {
    final lower = name.toLowerCase();
    if (lower.contains('25')) return CurrencyFormatters.formatCOP(86906);
    if (lower.contains('30')) return CurrencyFormatters.formatCOP(95684);
    if (lower.contains('38')) return CurrencyFormatters.formatCOP(120764);
    if (lower.contains('45')) return CurrencyFormatters.formatCOP(134520);
    if (lower.contains('48') || lower.contains('micro')) return CurrencyFormatters.formatCOP(195000);
    if (lower.contains('sal')) return CurrencyFormatters.formatCOP(45000);
    if (lower.contains('cal')) return CurrencyFormatters.formatCOP(28000);
    if (lower.contains('oxitetraciclina')) return CurrencyFormatters.formatCOP(95000);
    if (lower.contains('aireador')) return CurrencyFormatters.formatCOP(2400000);
    if (lower.contains('alevino')) return CurrencyFormatters.formatCOP(120000);
    return CurrencyFormatters.formatCOP(50000);
  }

  void _removeItem(int index) {
    if (_items.length <= 1) return;
    setState(() {
      final removed = _items.removeAt(index);
      removed.dispose();
    });
  }

  double get _totalCantidadFisica => _items.fold(0.0, (sum, i) => sum + i.totalCantidadFisica);
  double get _totalItemsCantidad => _items.fold(0.0, (sum, i) => sum + i.cantidad);
  double get _totalBruto => _items.fold(0.0, (sum, i) => sum + i.subtotalBruto);
  double get _totalBaseGravable => _items.fold(0.0, (sum, i) => sum + i.baseGravable);
  double get _totalIva => _items.fold(0.0, (sum, i) => sum + i.valorIva);
  double get _flete => CurrencyFormatters.parseCOP(_fleteCtrl.text);
  double get _granTotalFactura => _totalBaseGravable + _totalIva + _flete;
  double get _costoPromedioPorUnidadConFlete => _totalCantidadFisica > 0 ? (_granTotalFactura / _totalCantidadFisica) : 0.0;

  InventoryItemType get _inventoryTypeFromCategory {
    switch (_categoriaSeleccionada) {
      case 'concentrados': return InventoryItemType.concentrado;
      case 'insumos': return InventoryItemType.insumo;
      case 'farmacia': return InventoryItemType.farmacia;
      case 'oxigenadores': return InventoryItemType.oxigenador;
      case 'alevinos': return InventoryItemType.alevino;
      default: return InventoryItemType.insumo;
    }
  }

  List<String> _getUnidadesDisponiblesPorCategoria() {
    switch (_categoriaSeleccionada) {
      case 'concentrados': return ['Bulto 40 Kg', 'Bulto 20 Kg', 'Kg Granel'];
      case 'farmacia': return ['Litro (L)', 'Mililitros (mL)', 'Kilogramo (Kg)', 'Gramos (g)', 'Frasco / Dosis', 'Bolsa 5 Kg'];
      case 'oxigenadores': return ['Unidad Equipo', 'Motor', 'Blower'];
      case 'alevinos': return ['Millar Alevinos', 'Unidades', 'Lote Semilla'];
      default: return ['Unidad', 'Kg', 'Litro'];
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final warehouseState = ref.watch(warehouseProvider);
    final allSuppliers = warehouseState.suppliers;

    if (_selectedSupplier == null && allSuppliers.isNotEmpty) {
      final matching = allSuppliers.where((s) => s.categoriaPrincipal == _categoriaSeleccionada).toList();
      _selectedSupplier = matching.isNotEmpty ? matching.first : allSuppliers.first;
      if (_items.isEmpty) _addNewItem();
    }

    final filteredSuppliers = allSuppliers.where((s) => s.categoriaPrincipal == _categoriaSeleccionada).toList();
    final availableProducts = _selectedSupplier?.productosOfrecidos ?? [];

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 880),
        child: GlassContainer(
          borderRadius: 24,
          padding: const EdgeInsets.all(20),
          blur: 24,
          opacity: isDark ? 0.18 : 0.96,
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
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: AppColors.amberWarning.withValues(alpha: 0.18),
                                border: Border.all(color: AppColors.amberWarning.withValues(alpha: 0.3)),
                              ),
                              child: const Icon(Icons.receipt_long_rounded, color: AppColors.amberWarning, size: 22),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Ingreso de Factura de Almacén',
                                    style: AppTypography.titleLarge.copyWith(
                                      color: isDark ? Colors.white : AppColors.textPrimaryLight,
                                      fontSize: 17,
                                      fontWeight: FontWeight.w800,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  Text(
                                    'Multi-producto, liquidación fiscal y actualización de stock',
                                    style: AppTypography.labelMicro.copyWith(
                                      color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: Icon(Icons.close_rounded, color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    physics: const BouncingScrollPhysics(),
                    child: Row(
                      children: [
                        _buildCategoryChip('concentrados', '🍽️ Concentrados', isDark, allSuppliers),
                        _buildCategoryChip('insumos', '🧪 Insumos', isDark, allSuppliers),
                        _buildCategoryChip('alevinos', '🐟 Alevinos', isDark, allSuppliers),
                        _buildCategoryChip('farmacia', '💊 Farmacia', isDark, allSuppliers),
                        _buildCategoryChip('oxigenadores', '⚙️ Equipos', isDark, allSuppliers),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: isDark ? Colors.white.withValues(alpha: 0.04) : Colors.black.withValues(alpha: 0.03),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: isDark ? Colors.white10 : AppColors.glassBorderLight),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        LayoutBuilder(
                          builder: (context, constraints) {
                            final isNarrow = constraints.maxWidth < 500;
                            if (isNarrow) {
                              return Column(
                                children: [
                                  _buildSupplierDropdown(filteredSuppliers, isDark),
                                  const SizedBox(height: 10),
                                  _buildAnimatedTextField(
                                    controller: _facturaCtrl,
                                    label: 'No. Factura',
                                    hint: 'BQAE 273409',
                                    prefixIcon: Icons.tag_rounded,
                                    isDark: isDark,
                                  ),
                                ],
                              );
                            }
                            return Row(
                              children: [
                                Expanded(flex: 3, child: _buildSupplierDropdown(filteredSuppliers, isDark)),
                                const SizedBox(width: 10),
                                Expanded(
                                  flex: 2,
                                  child: _buildAnimatedTextField(
                                    controller: _facturaCtrl,
                                    label: 'No. Factura',
                                    hint: 'BQAE 273409',
                                    prefixIcon: Icons.tag_rounded,
                                    isDark: isDark,
                                  ),
                                ),
                              ],
                            );
                          },
                        ),
                        const SizedBox(height: 12),
                        LayoutBuilder(
                          builder: (context, constraints) {
                            final isMobile = constraints.maxWidth < 740;
                            if (isMobile) {
                              return Column(
                                children: [
                                  Row(
                                    children: [
                                      Expanded(
                                        child: GlassDatePickerField(
                                          label: 'FECHA EXPEDICIÓN',
                                          initialDate: _fechaExpedicion,
                                          accentColor: AppColors.cyanWater,
                                          onDateChanged: (d) {
                                            setState(() {
                                              _fechaExpedicion = d;
                                              _recalcularFechaVencimiento();
                                            });
                                          },
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(child: _buildCreditToggle(isDark)),
                                    ],
                                  ),
                                  const SizedBox(height: 10),
                                  Row(
                                    children: [
                                      if (_esCredito) ...[
                                        Expanded(
                                          flex: 2,
                                          child: _buildAnimatedTextField(
                                            controller: _diasCreditoCtrl,
                                            label: 'Días Plazo',
                                            hint: '30',
                                            keyboardType: TextInputType.number,
                                            isDark: isDark,
                                            onChanged: (_) => setState(() => _recalcularFechaVencimiento()),
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                      ],
                                      Expanded(
                                        flex: 3,
                                        child: GlassDatePickerField(
                                          label: _esCredito ? 'FECHA VENCIMIENTO' : 'FECHA PAGO',
                                          initialDate: _fechaVencimiento,
                                          accentColor: _esCredito ? AppColors.amberWarning : AppColors.greenBiomass,
                                          onDateChanged: (d) => setState(() => _fechaVencimiento = d),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 10),
                                  _buildAnimatedTextField(
                                    controller: _placaCtrl,
                                    label: 'Placa Vehículo / Conductor',
                                    hint: 'TSK-921',
                                    prefixIcon: Icons.local_shipping_outlined,
                                    isDark: isDark,
                                  ),
                                ],
                              );
                            }
                            return Row(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Expanded(
                                  flex: 3,
                                  child: GlassDatePickerField(
                                    label: 'FECHA EXPEDICIÓN',
                                    initialDate: _fechaExpedicion,
                                    accentColor: AppColors.cyanWater,
                                    onDateChanged: (d) {
                                      setState(() {
                                        _fechaExpedicion = d;
                                        _recalcularFechaVencimiento();
                                      });
                                    },
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  flex: 3,
                                  child: _buildCreditToggle(isDark),
                                ),
                                const SizedBox(width: 8),
                                if (_esCredito) ...[
                                  Expanded(
                                    flex: 2,
                                    child: _buildAnimatedTextField(
                                      controller: _diasCreditoCtrl,
                                      label: 'Días Plazo',
                                      hint: '30',
                                      keyboardType: TextInputType.number,
                                      isDark: isDark,
                                      onChanged: (_) => setState(() => _recalcularFechaVencimiento()),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                ],
                                Expanded(
                                  flex: 3,
                                  child: GlassDatePickerField(
                                    label: _esCredito ? 'VENCIMIENTO' : 'PAGO',
                                    initialDate: _fechaVencimiento,
                                    accentColor: _esCredito ? AppColors.amberWarning : AppColors.greenBiomass,
                                    onDateChanged: (d) => setState(() => _fechaVencimiento = d),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  flex: 3,
                                  child: _buildAnimatedTextField(
                                    controller: _placaCtrl,
                                    label: 'Placa Vehículo',
                                    hint: 'TSK-921',
                                    prefixIcon: Icons.local_shipping_outlined,
                                    isDark: isDark,
                                  ),
                                ),
                              ],
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'DETALLE DE PRODUCTOS INGRESADOS (${_items.length})',
                        style: AppTypography.labelMicro.copyWith(
                          color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.8,
                        ),
                      ),
                      TextButton.icon(
                        icon: const Icon(Icons.add_circle_outline_rounded, size: 16, color: AppColors.cyanWater),
                        label: const Text('Agregar Producto', style: TextStyle(color: AppColors.cyanWater, fontWeight: FontWeight.w700, fontSize: 12)),
                        onPressed: () => _addNewItem(),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ..._items.asMap().entries.map((entry) => _buildProductBentoCard(entry.value, entry.key, availableProducts, isDark)),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.04),
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: isDark ? Colors.white12 : AppColors.glassBorderLight),
                    ),
                    child: Column(
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              flex: 3,
                              child: _buildAnimatedTextField(
                                controller: _fleteCtrl,
                                label: 'Flete de Transporte Total (\$)',
                                hint: '0',
                                keyboardType: const TextInputType.numberWithOptions(decimal: false),
                                inputFormatters: [CurrencyInputFormatter()],
                                prefixIcon: Icons.local_shipping_rounded,
                                isDark: isDark,
                                onChanged: (_) => setState(() {}),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              flex: 2,
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                                decoration: BoxDecoration(
                                  color: AppColors.cyanWater.withValues(alpha: isDark ? 0.08 : 0.05),
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(color: AppColors.cyanWater.withValues(alpha: 0.25)),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('Carga Total en Factura:', style: AppTypography.labelMicro.copyWith(color: AppColors.cyanWater, fontSize: 9.5)),
                                    const SizedBox(height: 2),
                                    Text(
                                      _categoriaSeleccionada == 'concentrados' || _categoriaSeleccionada == 'insumos'
                                          ? '${CurrencyFormatters.formatInt(_totalItemsCantidad.toInt())} BTO • ${CurrencyFormatters.formatKg(_totalCantidadFisica)}'
                                          : '${_totalItemsCantidad.toInt()} Unidades',
                                      style: AppTypography.bodySmall.copyWith(color: isDark ? Colors.white : AppColors.textPrimaryLight, fontWeight: FontWeight.w800),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        const Divider(color: Colors.white10),
                        const SizedBox(height: 6),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('Subtotal Bruto:', style: AppTypography.bodySmall.copyWith(color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight)),
                            Text(CurrencyFormatters.formatCOP(_totalBruto), style: AppTypography.bodyMedium.copyWith(color: isDark ? Colors.white : AppColors.textPrimaryLight, fontWeight: FontWeight.w700)),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              _categoriaSeleccionada == 'concentrados' ? 'IVA (5,00% Agropecuario Concentrados):' : 'Total IVA Liquidado:',
                              style: AppTypography.bodySmall.copyWith(color: AppColors.amberWarning),
                            ),
                            Text(CurrencyFormatters.formatCOP(_totalIva), style: AppTypography.bodyMedium.copyWith(color: AppColors.amberWarning, fontWeight: FontWeight.w700)),
                          ],
                        ),
                        if (_flete > 0) ...[
                          const SizedBox(height: 4),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('Flete de Transporte:', style: AppTypography.bodySmall.copyWith(color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight)),
                              Text(CurrencyFormatters.formatCOP(_flete), style: AppTypography.bodyMedium.copyWith(color: AppColors.cyanWater, fontWeight: FontWeight.w700)),
                            ],
                          ),
                        ],
                        const SizedBox(height: 6),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              _categoriaSeleccionada == 'concentrados' || _categoriaSeleccionada == 'insumos'
                                  ? 'Costo Promedio / Kg (Puesto Granja):'
                                  : 'Costo Promedio / Unidad (Puesto Granja):',
                              style: AppTypography.bodySmall.copyWith(color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight),
                            ),
                            Text(CurrencyFormatters.formatCOP(_costoPromedioPorUnidadConFlete), style: AppTypography.bodyMedium.copyWith(color: AppColors.greenBiomass, fontWeight: FontWeight.w800)),
                          ],
                        ),
                        const Divider(color: Colors.white12, height: 18),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('TOTAL FACTURA:', style: AppTypography.titleMedium.copyWith(color: isDark ? Colors.white : AppColors.textPrimaryLight, fontWeight: FontWeight.w900)),
                            Text(
                              CurrencyFormatters.formatCOP(_granTotalFactura),
                              style: AppTypography.titleLarge.copyWith(color: AppColors.greenBiomass, fontWeight: FontWeight.w900, fontSize: 20),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  GlassButton(
                    label: _categoriaSeleccionada == 'concentrados' || _categoriaSeleccionada == 'insumos'
                        ? 'Registrar Factura y Actualizar Stock (${CurrencyFormatters.formatKg(_totalCantidadFisica)})'
                        : 'Registrar Factura y Actualizar Stock (${_totalItemsCantidad.toInt()} unid.)',
                    isLoading: warehouseState.isLoading,
                    backgroundColor: AppColors.amberWarning,
                    onPressed: () async {
                      if (!_formKey.currentState!.validate()) return;
                      final nav = Navigator.of(context);
                      final messenger = ScaffoldMessenger.of(context);
                      final authState = ref.read(authProvider);
                      final empresaId = authState.currentUser?.empresaId ?? 'c1000000-0000-0000-0000-000000000001';
                      final unidadId = authState.activeUnitId ?? 'u1000000-0000-0000-0000-000000000001';
                      final activeUnit = authState.units.where((u) => u.id == authState.activeUnitId).firstOrNull ?? (authState.units.isNotEmpty ? authState.units.first : null);
                      final sigla = activeUnit?.sigla ?? 'SEDE';
                      final supName = _selectedSupplier?.nombre ?? 'Proveedor Oficial';
                      final supNit = _selectedSupplier?.nit ?? '860.026.895-8';

                      final invoiceLineItems = _items.map((it) {
                        final ratio = _totalCantidadFisica > 0 ? (it.totalCantidadFisica / _totalCantidadFisica) : 0.0;
                        final fleteItem = _flete * ratio;
                        final totalConFlete = it.valorTotal + fleteItem;
                        final costoUnit = it.totalCantidadFisica > 0 ? (totalConFlete / it.totalCantidadFisica) : 0.0;
                        return InvoiceItemLine(
                          codigo: it.codigo,
                          nombre: it.nombre,
                          loteFabricante: it.loteFabricante.isNotEmpty ? it.loteFabricante : null,
                          cantidadBultos: it.cantidad.toInt(),
                          kgPorBulto: it.factorUnidad,
                          kilosTotales: it.totalCantidadFisica,
                          valorUnitarioBulto: it.costoUnitario,
                          valorBruto: it.subtotalBruto,
                          baseGravable: it.baseGravable,
                          ivaPct: it.ivaPct,
                          valorIva: it.valorIva,
                          valorTotal: it.valorTotal,
                          fleteProrrateado: fleteItem,
                          costoFinalPorKg: costoUnit,
                        );
                      }).toList();

                      final invoice = PurchaseInvoice(
                        id: const Uuid().v4(),
                        empresaId: empresaId,
                        unidadAcuicolaId: unidadId,
                        unidadAcuicolaSigla: sigla,
                        tipoFactura: _categoriaSeleccionada,
                        numeroFactura: _facturaCtrl.text.trim(),
                        proveedorNombre: supName,
                        proveedorNit: supNit,
                        fechaExpedicion: _fechaExpedicion.toDateTime(),
                        fechaVencimiento: _fechaVencimiento.toDateTime(),
                        esCredito: _esCredito,
                        diasCredito: _esCredito ? (_fechaVencimiento.toDateTime().difference(_fechaExpedicion.toDateTime()).inDays) : 0,
                        totalKilos: _totalCantidadFisica,
                        totalNeto: _totalBruto,
                        totalIva: _totalIva,
                        totalFactura: _granTotalFactura,
                        costoFlete: _flete,
                        estadoPago: _esCredito ? 'Pendiente' : 'Paga',
                        placaVehiculo: _placaCtrl.text.trim().isNotEmpty ? _placaCtrl.text.trim() : null,
                        productos: invoiceLineItems,
                        creadoEn: DateTime.now(),
                      );

                      final itemsToSync = _items.map((it) {
                        final ratio = _totalCantidadFisica > 0 ? (it.totalCantidadFisica / _totalCantidadFisica) : 0.0;
                        final fleteItem = _flete * ratio;
                        final totalConFlete = it.valorTotal + fleteItem;
                        final costoUnit = it.totalCantidadFisica > 0 ? (totalConFlete / it.totalCantidadFisica) : 0.0;
                        return InventoryItem(
                          id: const Uuid().v4(),
                          empresaId: empresaId,
                          unidadAcuicolaId: unidadId,
                          tipo: _inventoryTypeFromCategory,
                          nombre: it.nombre,
                          marcaProveedor: supName,
                          presentacionUnidad: it.unidadMedida,
                          cantidadOriginalKg: it.totalCantidadFisica,
                          cantidadActualKg: it.totalCantidadFisica,
                          costoTotal: totalConFlete,
                          costoUnitarioHistorico: costoUnit,
                          loteFabricante: it.loteFabricante.isNotEmpty ? it.loteFabricante : null,
                          creadoEn: DateTime.now(),
                        );
                      }).toList();

                      await ref.read(warehouseProvider.notifier).registerMultiItemInvoice(invoice, itemsToSync);
                      nav.pop();
                      messenger.showSnackBar(SnackBar(content: Text('¡Factura ${_facturaCtrl.text} de $supName registrada exitosamente!'), backgroundColor: AppColors.greenBiomass));
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

  Widget _buildCreditToggle(bool isDark) {
    return InkWell(
      onTap: () {
        setState(() {
          _esCredito = !_esCredito;
          _recalcularFechaVencimiento();
        });
      },
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        decoration: BoxDecoration(
          color: _esCredito
              ? AppColors.amberWarning.withValues(alpha: isDark ? 0.12 : 0.08)
              : (isDark ? Colors.white.withValues(alpha: 0.04) : Colors.black.withValues(alpha: 0.03)),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: _esCredito ? AppColors.amberWarning : (isDark ? Colors.white12 : AppColors.glassBorderLight),
            width: _esCredito ? 1.4 : 1.0,
          ),
        ),
        child: Row(
          children: [
            Checkbox(
              value: _esCredito,
              activeColor: AppColors.amberWarning,
              visualDensity: VisualDensity.compact,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
              onChanged: (val) {
                setState(() {
                  _esCredito = val ?? false;
                  _recalcularFechaVencimiento();
                });
              },
            ),
            const SizedBox(width: 4),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '¿Es a crédito?',
                    style: TextStyle(
                      color: isDark ? Colors.white : AppColors.textPrimaryLight,
                      fontSize: 11.5,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  Text(
                    _esCredito ? 'Por pagar' : 'Contado',
                    style: AppTypography.labelMicro.copyWith(
                      color: _esCredito ? AppColors.amberWarning : AppColors.textSecondaryDark,
                      fontSize: 9.5,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSupplierDropdown(List<Supplier> filteredSuppliers, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'PROVEEDOR OFICIAL',
          style: AppTypography.labelMicro.copyWith(
            color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 5),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
          decoration: BoxDecoration(
            color: isDark ? Colors.white.withValues(alpha: 0.06) : Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: isDark ? Colors.white12 : AppColors.glassBorderLight),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<Supplier>(
              value: filteredSuppliers.contains(_selectedSupplier) ? _selectedSupplier : (filteredSuppliers.isNotEmpty ? filteredSuppliers.first : null),
              isExpanded: true,
              dropdownColor: isDark ? AppColors.surfaceDark : Colors.white,
              style: TextStyle(color: isDark ? Colors.white : AppColors.textPrimaryLight, fontSize: 13, fontWeight: FontWeight.w600),
              onChanged: (sup) {
                setState(() {
                  _selectedSupplier = sup;
                  if (_items.isNotEmpty) {
                    final firstProd = sup?.productosOfrecidos.isNotEmpty == true ? sup!.productosOfrecidos.first : 'Producto';
                    _items[0].nombre = firstProd;
                    _items[0].costoUnitarioCtrl.text = _guessPrice(firstProd);
                  }
                });
              },
              items: filteredSuppliers.map((s) => DropdownMenuItem<Supplier>(value: s, child: Text('${s.nombre} (${s.nit})', overflow: TextOverflow.ellipsis))).toList(),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAnimatedTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    IconData? prefixIcon,
    TextInputType? keyboardType,
    List<TextInputFormatter>? inputFormatters,
    void Function(String)? onChanged,
    required bool isDark,
    bool readOnly = false,
  }) {
    return TextFormField(
      controller: controller,
      readOnly: readOnly,
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      onChanged: onChanged,
      style: TextStyle(color: isDark ? Colors.white : AppColors.textPrimaryLight, fontSize: 12.5, fontWeight: FontWeight.w700),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        floatingLabelBehavior: FloatingLabelBehavior.auto,
        labelStyle: TextStyle(fontSize: 11.5, color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight, fontWeight: FontWeight.w600),
        floatingLabelStyle: const TextStyle(fontSize: 11.5, color: AppColors.cyanWater, fontWeight: FontWeight.w800),
        prefixIcon: prefixIcon != null ? Icon(prefixIcon, color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight, size: 18) : null,
        filled: true,
        fillColor: isDark ? Colors.white.withValues(alpha: 0.04) : Colors.white,
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: isDark ? Colors.white12 : AppColors.glassBorderLight)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: isDark ? Colors.white12 : AppColors.glassBorderLight)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: AppColors.cyanWater, width: 1.6)),
      ),
    );
  }

  Widget _buildProductBentoCard(EditableInvoiceItem item, int index, List<String> availableProducts, bool isDark) {
    final unidadesDisponibles = _getUnidadesDisponiblesPorCategoria();
    final esConcentrado = _categoriaSeleccionada == 'concentrados';

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withValues(alpha: 0.04) : Colors.white.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: isDark ? Colors.white.withValues(alpha: 0.12) : AppColors.glassBorderLight),
        boxShadow: [
          BoxShadow(
            color: isDark ? Colors.black26 : const Color(0xFF64748B).withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          LayoutBuilder(
            builder: (context, constraints) {
              final isNarrow = constraints.maxWidth < 660;
              if (isNarrow) {
                return Column(
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColors.cyanWater.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text('#${index + 1}', style: const TextStyle(color: AppColors.cyanWater, fontSize: 11.5, fontWeight: FontWeight.w900)),
                        ),
                        const SizedBox(width: 8),
                        Expanded(child: _buildProductDropdown(item, availableProducts, isDark)),
                        if (_items.length > 1)
                          IconButton(
                            icon: const Icon(Icons.delete_outline_rounded, color: AppColors.coralAction, size: 20),
                            visualDensity: VisualDensity.compact,
                            onPressed: () => _removeItem(index),
                          ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(flex: 3, child: _buildUnitDropdown(item, unidadesDisponibles, isDark)),
                        const SizedBox(width: 8),
                        Expanded(
                          flex: 2,
                          child: TextFormField(
                            initialValue: item.loteFabricante,
                            style: TextStyle(color: isDark ? Colors.white : AppColors.textPrimaryLight, fontSize: 12),
                            decoration: InputDecoration(
                              labelText: 'Lote Fab.',
                              floatingLabelBehavior: FloatingLabelBehavior.auto,
                              labelStyle: const TextStyle(fontSize: 11, color: AppColors.textSecondaryDark),
                              hintText: '88197',
                              isDense: true,
                              contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            onChanged: (v) => item.loteFabricante = v,
                          ),
                        ),
                      ],
                    ),
                  ],
                );
              }

              return Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.cyanWater.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text('#${index + 1}', style: const TextStyle(color: AppColors.cyanWater, fontSize: 11.5, fontWeight: FontWeight.w900)),
                  ),
                  const SizedBox(width: 8),
                  Expanded(flex: 4, child: _buildProductDropdown(item, availableProducts, isDark)),
                  const SizedBox(width: 8),
                  Expanded(flex: 3, child: _buildUnitDropdown(item, unidadesDisponibles, isDark)),
                  const SizedBox(width: 8),
                  Expanded(
                    flex: 2,
                    child: TextFormField(
                      initialValue: item.loteFabricante,
                      style: TextStyle(color: isDark ? Colors.white : AppColors.textPrimaryLight, fontSize: 12),
                      decoration: InputDecoration(
                        labelText: 'Lote Fab.',
                        floatingLabelBehavior: FloatingLabelBehavior.auto,
                        labelStyle: const TextStyle(fontSize: 11, color: AppColors.textSecondaryDark),
                        hintText: '88197',
                        isDense: true,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onChanged: (v) => item.loteFabricante = v,
                    ),
                  ),
                  if (_items.length > 1)
                    IconButton(
                      icon: const Icon(Icons.delete_outline_rounded, color: AppColors.coralAction, size: 20),
                      visualDensity: VisualDensity.compact,
                      onPressed: () => _removeItem(index),
                    ),
                ],
              );
            },
          ),
          const SizedBox(height: 10),
          LayoutBuilder(
            builder: (context, constraints) {
              final isNarrow = constraints.maxWidth < 660;
              if (isNarrow) {
                return Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          flex: 2,
                          child: TextFormField(
                            controller: item.cantidadCtrl,
                            keyboardType: TextInputType.number,
                            style: TextStyle(color: isDark ? Colors.white : AppColors.textPrimaryLight, fontSize: 12.5, fontWeight: FontWeight.w800),
                            decoration: InputDecoration(
                              labelText: 'Cantidad',
                              floatingLabelBehavior: FloatingLabelBehavior.auto,
                              labelStyle: const TextStyle(fontSize: 11, color: AppColors.cyanWater),
                              isDense: true,
                              contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            onChanged: (_) => setState(() {}),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          flex: 3,
                          child: TextFormField(
                            controller: item.costoUnitarioCtrl,
                            keyboardType: const TextInputType.numberWithOptions(decimal: false),
                            inputFormatters: [CurrencyInputFormatter()],
                            style: TextStyle(color: isDark ? Colors.white : AppColors.textPrimaryLight, fontSize: 12.5, fontWeight: FontWeight.w800),
                            decoration: InputDecoration(
                              labelText: 'Vlr. Unitario (\$)',
                              floatingLabelBehavior: FloatingLabelBehavior.auto,
                              labelStyle: const TextStyle(fontSize: 11, color: AppColors.amberWarning),
                              isDense: true,
                              contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            onChanged: (_) => setState(() {}),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          flex: 2,
                          child: TextFormField(
                            controller: item.ivaPctCtrl,
                            readOnly: esConcentrado,
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            style: TextStyle(color: esConcentrado ? AppColors.amberWarning : (isDark ? Colors.white : AppColors.textPrimaryLight), fontSize: 12, fontWeight: FontWeight.w700),
                            decoration: InputDecoration(
                              labelText: esConcentrado ? 'IVA 5% Fijo' : 'IVA %',
                              floatingLabelBehavior: FloatingLabelBehavior.auto,
                              labelStyle: const TextStyle(fontSize: 11, color: AppColors.textSecondaryDark),
                              isDense: true,
                              contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            onChanged: (_) => setState(() {}),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    _buildItemSummaryFooter(item, isDark),
                  ],
                );
              }

              return Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: TextFormField(
                      controller: item.cantidadCtrl,
                      keyboardType: TextInputType.number,
                      style: TextStyle(color: isDark ? Colors.white : AppColors.textPrimaryLight, fontSize: 12.5, fontWeight: FontWeight.w800),
                      decoration: InputDecoration(
                        labelText: 'Cantidad',
                        floatingLabelBehavior: FloatingLabelBehavior.auto,
                        labelStyle: const TextStyle(fontSize: 11, color: AppColors.cyanWater),
                        isDense: true,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onChanged: (_) => setState(() {}),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    flex: 3,
                    child: TextFormField(
                      controller: item.costoUnitarioCtrl,
                      keyboardType: const TextInputType.numberWithOptions(decimal: false),
                      inputFormatters: [CurrencyInputFormatter()],
                      style: TextStyle(color: isDark ? Colors.white : AppColors.textPrimaryLight, fontSize: 12.5, fontWeight: FontWeight.w800),
                      decoration: InputDecoration(
                        labelText: 'Vlr. Unitario (\$)',
                        floatingLabelBehavior: FloatingLabelBehavior.auto,
                        labelStyle: const TextStyle(fontSize: 11, color: AppColors.amberWarning),
                        isDense: true,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onChanged: (_) => setState(() {}),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    flex: 2,
                    child: TextFormField(
                      controller: item.ivaPctCtrl,
                      readOnly: esConcentrado,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      style: TextStyle(color: esConcentrado ? AppColors.amberWarning : (isDark ? Colors.white : AppColors.textPrimaryLight), fontSize: 12, fontWeight: FontWeight.w700),
                      decoration: InputDecoration(
                        labelText: esConcentrado ? 'IVA 5% Fijo' : 'IVA %',
                        floatingLabelBehavior: FloatingLabelBehavior.auto,
                        labelStyle: const TextStyle(fontSize: 11, color: AppColors.textSecondaryDark),
                        isDense: true,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onChanged: (_) => setState(() {}),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    flex: 4,
                    child: _buildItemSummaryFooter(item, isDark),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildProductDropdown(EditableInvoiceItem item, List<String> availableProducts, bool isDark) {
    if (availableProducts.isNotEmpty) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 1),
        decoration: BoxDecoration(
          color: isDark ? Colors.white.withValues(alpha: 0.06) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: isDark ? Colors.white10 : AppColors.glassBorderLight),
        ),
        child: DropdownButtonHideUnderline(
          child: DropdownButton<String>(
            value: availableProducts.contains(item.nombre) ? item.nombre : availableProducts.first,
            isExpanded: true,
            dropdownColor: isDark ? AppColors.surfaceDark : Colors.white,
            style: TextStyle(color: isDark ? Colors.white : AppColors.textPrimaryLight, fontSize: 12.5, fontWeight: FontWeight.w700),
            onChanged: (val) {
              if (val != null) {
                setState(() {
                  item.nombre = val;
                  item.costoUnitarioCtrl.text = _guessPrice(val);
                });
              }
            },
            items: availableProducts.map((p) => DropdownMenuItem<String>(value: p, child: Text(p, overflow: TextOverflow.ellipsis))).toList(),
          ),
        ),
      );
    }
    return TextFormField(
      initialValue: item.nombre,
      style: TextStyle(color: isDark ? Colors.white : AppColors.textPrimaryLight, fontSize: 12.5),
      decoration: InputDecoration(
        labelText: 'Nombre de Producto',
        floatingLabelBehavior: FloatingLabelBehavior.auto,
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
      onChanged: (v) => item.nombre = v,
    );
  }

  Widget _buildUnitDropdown(EditableInvoiceItem item, List<String> unidadesDisponibles, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 1),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withValues(alpha: 0.06) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: isDark ? Colors.white10 : AppColors.glassBorderLight),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: unidadesDisponibles.contains(item.unidadMedida) ? item.unidadMedida : unidadesDisponibles.first,
          isExpanded: true,
          dropdownColor: isDark ? AppColors.surfaceDark : Colors.white,
          style: TextStyle(color: isDark ? Colors.white : AppColors.textPrimaryLight, fontSize: 11.5, fontWeight: FontWeight.w700),
          onChanged: (val) {
            if (val != null) {
              setState(() {
                item.unidadMedida = val;
                if (val.contains('20')) {
                  item.factorUnidadCtrl.text = '20';
                } else if (val.contains('50')) {
                  item.factorUnidadCtrl.text = '50';
                } else if (val.contains('40')) {
                  item.factorUnidadCtrl.text = '40';
                } else if (val.contains('25')) {
                  item.factorUnidadCtrl.text = '25';
                } else if (val.contains('Millar')) {
                  item.factorUnidadCtrl.text = '1000';
                } else {
                  item.factorUnidadCtrl.text = '1';
                }
              });
            }
          },
          items: unidadesDisponibles.map((u) => DropdownMenuItem<String>(value: u, child: Text(u, overflow: TextOverflow.ellipsis))).toList(),
        ),
      ),
    );
  }

  Widget _buildItemSummaryFooter(EditableInvoiceItem item, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: isDark ? Colors.white10 : AppColors.glassBorderLight),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _categoriaSeleccionada == 'concentrados' || _categoriaSeleccionada == 'insumos'
                      ? CurrencyFormatters.formatKg(item.totalCantidadFisica)
                      : '${item.totalCantidadFisica.toInt()} unid.',
                  style: AppTypography.labelMicro.copyWith(fontSize: 10, color: AppColors.cyanWater, fontWeight: FontWeight.w800),
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  'IVA: ${CurrencyFormatters.formatCOP(item.valorIva)}',
                  style: AppTypography.labelMicro.copyWith(fontSize: 9, color: AppColors.textSecondaryDark),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              CurrencyFormatters.formatCOP(item.valorTotal),
              style: const TextStyle(color: AppColors.greenBiomass, fontSize: 13, fontWeight: FontWeight.w900),
              textAlign: TextAlign.end,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryChip(String catKey, String label, bool isDark, List<Supplier> allSuppliers) {
    final isSelected = _categoriaSeleccionada == catKey;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: InkWell(
        onTap: () => _onCategoryChanged(catKey, allSuppliers),
        borderRadius: BorderRadius.circular(12),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: isSelected
                ? AppColors.amberWarning.withValues(alpha: isDark ? 0.25 : 0.18)
                : (isDark ? Colors.white.withValues(alpha: 0.04) : Colors.black.withValues(alpha: 0.04)),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected ? AppColors.amberWarning : (isDark ? Colors.white12 : Colors.black12),
              width: isSelected ? 1.5 : 1.0,
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              color: isSelected ? AppColors.amberWarning : (isDark ? Colors.white70 : AppColors.textPrimaryLight),
              fontSize: 12,
              fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }
}
