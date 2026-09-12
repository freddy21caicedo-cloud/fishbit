import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import 'package:fishbit_finance/core/design_system/app_colors.dart';
import 'package:fishbit_finance/core/design_system/app_typography.dart';
import 'package:fishbit_finance/core/design_system/glass_container.dart';
import 'package:fishbit_finance/core/design_system/glass_date_picker.dart';
import 'package:fishbit_finance/core/utils/currency_formatters.dart';
import 'package:fishbit_finance/modules/auth_tenant/presentation/providers/auth_provider.dart';
import 'package:fishbit_finance/modules/warehouse_inventory/domain/models/inventory_item.dart';
import 'package:fishbit_finance/modules/warehouse_inventory/domain/models/purchase_invoice.dart';
import 'package:fishbit_finance/modules/warehouse_inventory/domain/models/supplier.dart';
import 'package:fishbit_finance/modules/warehouse_inventory/domain/services/product_catalog_service.dart';
import 'package:fishbit_finance/modules/warehouse_inventory/presentation/providers/warehouse_provider.dart';
import 'package:fishbit_finance/modules/warehouse_inventory/presentation/dialogs/proveedores_modal.dart';

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

  const NuevaFacturaModal({
    super.key,
    this.initialCategory = 'concentrados',
  });

  static Future<void> show(BuildContext context, {String initialCategory = 'concentrados'}) {
    return showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => NuevaFacturaModal(initialCategory: initialCategory),
    );
  }

  @override
  ConsumerState<NuevaFacturaModal> createState() => _NuevaFacturaModalState();
}

class _NuevaFacturaModalState extends ConsumerState<NuevaFacturaModal> {
  final _formKey = GlobalKey<FormState>();

  // Wizard Step: 0: Cabecera & Proveedor, 1: Condiciones & Flete, 2: Productos Multi-Ítem, 3: Ticket Fiscal y Confirmación
  int _currentStep = 0;

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
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _categoriaSeleccionada = widget.initialCategory;
    final randomNum = DateTime.now().millisecondsSinceEpoch.toString().substring(7);
    _facturaCtrl.text = 'FACT-$randomNum';
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
    final company = ref.read(authProvider).currentCompany;
    final companySpecies = company?.especiesHabilitadas ?? ['Trucha Arcoíris'];

    String prodName = defaultName ?? '';
    if (prodName.isEmpty) {
      if (_categoriaSeleccionada == 'alevinos') {
        final bioProducts = ProductCatalogService.getBiologicalProducts(companySpecies);
        // Default to "Alevinos de [Especie]" if available
        final defaultAlevino = bioProducts.firstWhere(
          (p) => p.toLowerCase().startsWith('alevinos de'),
          orElse: () => bioProducts.isNotEmpty ? bioProducts.first : 'Alevinos de Trucha Arcoíris',
        );
        prodName = defaultAlevino;
      } else if (sup?.productosOfrecidos.isNotEmpty == true) {
        prodName = sup!.productosOfrecidos.first;
      } else if (_categoriaSeleccionada == 'concentrados') {
        final feedProds = ProductCatalogService.getFeedProductsForSupplier(sup?.nombre ?? '', companySpecies);
        prodName = feedProds.isNotEmpty ? feedProds.first : 'Concentrado Comercial';
      } else {
        prodName = switch (_categoriaSeleccionada) {
          'insumos' => 'Insumo Acuícola',
          'farmacia' => 'Fármaco Veterinario',
          'oxigenadores' => 'Oxigenador / Aireador',
          _ => 'Producto General',
        };
      }
    }
    
    final (defUnidad, defFactor, defIva) = switch (_categoriaSeleccionada) {
      'concentrados' => ('Bulto 40 Kg', '40', '5.0'),
      'insumos' => ('Saco 40 Kg', '40', '0.0'),
      'farmacia' => ('Litro (L)', '1', '0.0'),
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
    if (lower.contains('melaza')) return CurrencyFormatters.formatCOP(65000);
    if (lower.contains('alevin')) return CurrencyFormatters.formatCOP(180000);
    if (lower.contains('ova')) return CurrencyFormatters.formatCOP(120000);
    if (lower.contains('aireador') || lower.contains('motor')) return CurrencyFormatters.formatCOP(2450000);
    return CurrencyFormatters.formatCOP(95000);
  }

  void _removeItem(int index) {
    if (_items.length <= 1) return;
    setState(() {
      final removed = _items.removeAt(index);
      removed.dispose();
    });
  }

  // Cálculos contables
  double get _totalItemsCantidad => _items.fold(0.0, (sum, i) => sum + i.cantidad);
  double get _totalCantidadFisica => _items.fold(0.0, (sum, i) => sum + i.totalCantidadFisica);
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
      default: return ['Saco 40 Kg', 'Saco 50 Kg', 'Caneca 25 Kg', 'Galón 3.8 L', 'Unidad', 'Kg'];
    }
  }

  bool _validateStep(int step) {
    if (step == 0) {
      if (_selectedSupplier == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Por favor selecciona un proveedor oficial o registrado.'), backgroundColor: AppColors.coralAction),
        );
        return false;
      }
      if (_facturaCtrl.text.trim().isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Por favor ingresa el número o consecutivo de la factura.'), backgroundColor: AppColors.coralAction),
        );
        return false;
      }
      return true;
    } else if (step == 1) {
      return true;
    } else if (step == 2) {
      if (_items.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Debes ingresar al menos un producto a la factura.'), backgroundColor: AppColors.coralAction),
        );
        return false;
      }
      for (int i = 0; i < _items.length; i++) {
        if (_items[i].cantidad <= 0) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('El producto #${i + 1} tiene una cantidad inválida.'), backgroundColor: AppColors.coralAction),
          );
          return false;
        }
        if (_items[i].costoUnitario <= 0) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('El producto #${i + 1} requiere un valor unitario mayor a cero.'), backgroundColor: AppColors.coralAction),
          );
          return false;
        }
      }
      return true;
    }
    return true;
  }

  void _nextStep() {
    if (!_validateStep(_currentStep)) return;
    if (_currentStep < 3) {
      setState(() => _currentStep++);
    }
  }

  void _prevStep() {
    if (_currentStep > 0) {
      setState(() => _currentStep--);
    } else {
      Navigator.of(context).pop();
    }
  }

  Future<void> _guardarFactura() async {
    if (!_validateStep(2)) return;

    setState(() => _isSubmitting = true);

    final nav = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final authState = ref.read(authProvider);
    final empresaId = authState.currentCompany?.id ?? authState.currentUser?.empresaId ?? '';
    final unidadId = authState.activeUnitId ?? authState.currentUser?.unidadAcuicolaId;
    final activeUnit = authState.units.where((u) => u.id == authState.activeUnitId).firstOrNull ?? (authState.units.isNotEmpty ? authState.units.first : null);
    final sigla = activeUnit?.sigla ?? 'SEDE';
    final supName = _selectedSupplier?.nombre ?? 'Proveedor Oficial';
    final supNit = _selectedSupplier?.nit ?? '860.026.895-8';

    if (empresaId.isEmpty) {
      setState(() => _isSubmitting = false);
      messenger.showSnackBar(
        const SnackBar(
          content: Text('No se pudo determinar la empresa activa. Por favor verifica tu sesión.'),
          backgroundColor: AppColors.coralAction,
        ),
      );
      return;
    }

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
      unidadAcuicolaId: unidadId ?? '',
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

      String? especieAlevino;
      if (_inventoryTypeFromCategory == InventoryItemType.alevino) {
        final lower = it.nombre.toLowerCase();
        final company = ref.read(authProvider).currentCompany;
        final companySpecies = company?.especiesHabilitadas ?? ['Trucha Arcoíris'];
        
        if (lower.contains('trucha')) {
          especieAlevino = companySpecies.firstWhere((s) => s.toLowerCase().contains('trucha'), orElse: () => 'Trucha Arcoíris');
        } else if (lower.contains('tilapia')) {
          especieAlevino = companySpecies.firstWhere((s) => s.toLowerCase().contains('tilapia'), orElse: () => 'Tilapia Roja');
        } else if (lower.contains('cachama')) {
          especieAlevino = companySpecies.firstWhere((s) => s.toLowerCase().contains('cachama'), orElse: () => 'Cachama Negra');
        } else if (lower.contains('bocachico')) {
          especieAlevino = companySpecies.firstWhere((s) => s.toLowerCase().contains('bocachico'), orElse: () => 'Bocachico');
        } else {
          especieAlevino = companySpecies.isNotEmpty ? companySpecies.first : 'Trucha Arcoíris';
        }
      }

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
        especieAlevino: especieAlevino,
        loteFabricante: it.loteFabricante.isNotEmpty ? it.loteFabricante : null,
        creadoEn: DateTime.now(),
      );
    }).toList();

    try {
      await ref.read(warehouseProvider.notifier).registerMultiItemInvoice(invoice, itemsToSync);
      if (mounted) {
        nav.pop();
        messenger.showSnackBar(
          SnackBar(
            content: Text('¡Factura ${_facturaCtrl.text} de $supName registrada exitosamente!'),
            backgroundColor: AppColors.greenBiomass,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSubmitting = false);
        messenger.showSnackBar(
          SnackBar(
            content: Text('Error al registrar factura: $e'),
            backgroundColor: AppColors.coralAction,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final warehouseState = ref.watch(warehouseProvider);
    final authState = ref.watch(authProvider);
    final company = authState.currentCompany;
    final companySpecies = company?.especiesHabilitadas ?? ['Trucha Arcoíris'];
    final allSuppliers = warehouseState.suppliers;

    final filteredSuppliers = allSuppliers.where((s) => s.categoriaPrincipal == _categoriaSeleccionada).toList();

    if (_selectedSupplier == null && filteredSuppliers.isNotEmpty) {
      _selectedSupplier = filteredSuppliers.first;
      if (_items.isEmpty) _addNewItem();
    }

    final List<String> availableProducts;
    if (_categoriaSeleccionada == 'concentrados') {
      final supName = _selectedSupplier?.nombre ?? '';
      availableProducts = ProductCatalogService.getFeedProductsForSupplier(supName, companySpecies);
    } else if (_categoriaSeleccionada == 'alevinos') {
      availableProducts = ProductCatalogService.getBiologicalProducts(companySpecies);
    } else {
      availableProducts = _selectedSupplier?.productosOfrecidos ?? [];
    }

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 820),
        child: GlassContainer(
          borderRadius: 24,
          padding: const EdgeInsets.all(22),
          blur: 24,
          opacity: isDark ? 0.18 : 0.96,
          borderColor: AppColors.amberWarning.withValues(alpha: 0.35),
          child: Form(
            key: _formKey,
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header con título y botón cerrar
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(9),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: AppColors.amberWarning.withValues(alpha: 0.18),
                              border: Border.all(color: AppColors.amberWarning.withValues(alpha: 0.3)),
                            ),
                            child: const Icon(Icons.receipt_long_rounded, color: AppColors.amberWarning, size: 22),
                          ),
                          const SizedBox(width: 12),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Ingreso de Factura de Almacén',
                                style: AppTypography.titleLarge.copyWith(
                                  color: isDark ? Colors.white : AppColors.textPrimaryLight,
                                  fontSize: 17,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              Text(
                                'Multi-producto, liquidación fiscal y actualización de stock',
                                style: AppTypography.labelMicro.copyWith(color: AppColors.textSecondaryDark),
                              ),
                            ],
                          ),
                        ],
                      ),
                      IconButton(
                        icon: Icon(Icons.close_rounded, color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),

                  // Barra de Progreso del Wizard (Paso 1 a 4)
                  _buildWizardStepIndicator(),
                  const SizedBox(height: 18),

                  // Contenido de cada paso con animación fluida
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 250),
                    child: switch (_currentStep) {
                      0 => _buildStep1FiscalHeader(isDark, filteredSuppliers, allSuppliers),
                      1 => _buildStep2CommercialConditions(isDark),
                      2 => _buildStep3ProductsList(isDark, availableProducts),
                      3 => _buildStep4FiscalTicket(isDark),
                      _ => const SizedBox.shrink(),
                    },
                  ),

                  const SizedBox(height: 20),

                  // Barra de Navegación Inferior (Atrás / Continuar / Confirmar)
                  _buildNavigationButtons(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // --- WIDGETS DEL WIZARD ---

  /// Barra de progreso interactiva con 4 pasos
  Widget _buildWizardStepIndicator() {
    final stepLabels = ['Proveedor', 'Condiciones', 'Productos', 'Ticket Fiscal'];

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: List.generate(4, (index) {
          final isCompleted = _currentStep > index;
          final isCurrent = _currentStep == index;
          final stepColor = isCurrent ? AppColors.amberWarning : (isCompleted ? AppColors.greenBiomass : Colors.white24);

          return Expanded(
            child: Row(
              children: [
                Container(
                  width: 22,
                  height: 22,
                  decoration: BoxDecoration(
                    color: isCurrent
                        ? AppColors.amberWarning.withValues(alpha: 0.2)
                        : (isCompleted ? AppColors.greenBiomass.withValues(alpha: 0.2) : Colors.transparent),
                    shape: BoxShape.circle,
                    border: Border.all(color: stepColor, width: 1.5),
                  ),
                  child: Center(
                    child: isCompleted
                        ? const Icon(Icons.check_rounded, size: 12, color: AppColors.greenBiomass)
                        : Text(
                            '${index + 1}',
                            style: TextStyle(
                              color: isCurrent ? AppColors.amberWarning : Colors.white54,
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                  ),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    stepLabels[index],
                    style: TextStyle(
                      color: isCurrent ? Colors.white : (isCompleted ? Colors.white70 : Colors.white38),
                      fontSize: 11,
                      fontWeight: isCurrent ? FontWeight.w800 : FontWeight.w500,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (index < 3)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: Icon(Icons.chevron_right_rounded, size: 14, color: isCompleted ? AppColors.greenBiomass : Colors.white24),
                  ),
              ],
            ),
          );
        }),
      ),
    );
  }

  /// PASO 1: Cabecera Fiscal & Proveedor
  Widget _buildStep1FiscalHeader(bool isDark, List<Supplier> filteredSuppliers, List<Supplier> allSuppliers) {
    return Column(
      key: const ValueKey(0),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'PASO 1: CATEGORÍA DE FACTURA Y PROVEEDOR',
          style: AppTypography.labelMicro.copyWith(color: AppColors.amberWarning, fontWeight: FontWeight.w800, letterSpacing: 0.5),
        ),
        const SizedBox(height: 4),
        Text(
          'Selecciona la categoría del gasto y el proveedor que emite el documento fiscal:',
          style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondaryDark, fontSize: 12),
        ),
        const SizedBox(height: 12),

        // Chips de categoría
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          physics: const BouncingScrollPhysics(),
          child: Row(
            children: [
              _buildCategoryChip('concentrados', '🍽️ Concentrados', isDark, allSuppliers),
              _buildCategoryChip('insumos', '🧪 Insumos', isDark, allSuppliers),
              _buildCategoryChip('alevinos', '🐟 Alevinos / Semilla', isDark, allSuppliers),
              _buildCategoryChip('farmacia', '💊 Farmacia', isDark, allSuppliers),
              _buildCategoryChip('oxigenadores', '⚙️ Equipos / Motores', isDark, allSuppliers),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Selector de Proveedor
        _buildSupplierDropdown(filteredSuppliers, isDark),
        const SizedBox(height: 14),

        // Número o Consecutivo de Factura
        _buildAnimatedTextField(
          controller: _facturaCtrl,
          label: 'Número Oficial de Factura / Remisión',
          hint: 'FE-002910',
          prefixIcon: Icons.tag_rounded,
          isDark: isDark,
        ),
      ],
    );
  }

  /// PASO 2: Condiciones Comerciales & Logística
  Widget _buildStep2CommercialConditions(bool isDark) {
    return Column(
      key: const ValueKey(1),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'PASO 2: CONDICIONES COMERCIALES Y TRANSPORTE',
          style: AppTypography.labelMicro.copyWith(color: AppColors.cyanWater, fontWeight: FontWeight.w800, letterSpacing: 0.5),
        ),
        const SizedBox(height: 4),
        Text(
          'Define las fechas de expedición/vencimiento, modalidad de pago y flete:',
          style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondaryDark, fontSize: 12),
        ),
        const SizedBox(height: 14),

        // Modalidad de Pago: Contado / Crédito
        Row(
          children: [
            Expanded(child: _buildCreditToggle(isDark)),
            const SizedBox(width: 12),
            if (_esCredito)
              Expanded(
                child: _buildAnimatedTextField(
                  controller: _diasCreditoCtrl,
                  label: 'Plazo Comercial (Días)',
                  hint: '30',
                  keyboardType: TextInputType.number,
                  prefixIcon: Icons.timer_outlined,
                  isDark: isDark,
                  onChanged: (_) => setState(() => _recalcularFechaVencimiento()),
                ),
              )
            else
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  decoration: BoxDecoration(
                    color: AppColors.greenBiomass.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppColors.greenBiomass.withValues(alpha: 0.3)),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.check_circle_outline_rounded, color: AppColors.greenBiomass, size: 18),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Pago de Contado Inmediato',
                          style: TextStyle(color: AppColors.greenBiomass, fontWeight: FontWeight.w700, fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 14),

        // Fechas de Factura
        Row(
          children: [
            Expanded(
              child: GlassDatePickerField(
                label: 'Fecha Expedición',
                initialDate: _fechaExpedicion,
                onDateChanged: (CivilDate d) => setState(() {
                  _fechaExpedicion = d;
                  _recalcularFechaVencimiento();
                }),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: GlassDatePickerField(
                label: 'Fecha Vencimiento',
                initialDate: _fechaVencimiento,
                enabled: _esCredito,
                onDateChanged: (CivilDate d) => setState(() => _fechaVencimiento = d),
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),

        // Flete de Transporte y Placa de Vehículo
        Row(
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
              child: _buildAnimatedTextField(
                controller: _placaCtrl,
                label: 'Placa Vehículo (Opcional)',
                hint: 'WPA-123',
                prefixIcon: Icons.directions_car_rounded,
                isDark: isDark,
              ),
            ),
          ],
        ),
      ],
    );
  }

  /// PASO 3: Lista de Productos (Multi-Ítem)
  Widget _buildStep3ProductsList(bool isDark, List<String> availableProducts) {
    return Column(
      key: const ValueKey(2),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'PASO 3: PRODUCTOS EN FACTURA (${_items.length})',
                  style: AppTypography.labelMicro.copyWith(color: AppColors.cyanWater, fontWeight: FontWeight.w800, letterSpacing: 0.5),
                ),
                Text(
                  'Agrega los ítems que componen el documento:',
                  style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondaryDark, fontSize: 12),
                ),
              ],
            ),
            TextButton.icon(
              icon: const Icon(Icons.add_circle_outline_rounded, size: 16, color: AppColors.cyanWater),
              label: const Text('Agregar Producto', style: TextStyle(color: AppColors.cyanWater, fontWeight: FontWeight.w700, fontSize: 12)),
              onPressed: () => _addNewItem(),
            ),
          ],
        ),
        const SizedBox(height: 12),

        // Listado de Tarjetas Bento
        ..._items.asMap().entries.map((entry) => _buildProductBentoCard(entry.value, entry.key, availableProducts, isDark)),
      ],
    );
  }

  /// PASO 4: Ticket Fiscal Glassmorphic & Confirmación
  Widget _buildStep4FiscalTicket(bool isDark) {
    return Column(
      key: const ValueKey(3),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'PASO 4: TICKET FISCAL Y LIQUIDACIÓN PUESTO EN GRANJA',
          style: AppTypography.labelMicro.copyWith(color: AppColors.greenBiomass, fontWeight: FontWeight.w800, letterSpacing: 0.5),
        ),
        const SizedBox(height: 4),
        Text(
          'Verifica los subtotales tributarios, el prorrateo del flete y confirma el ingreso a bodega:',
          style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondaryDark, fontSize: 12),
        ),
        const SizedBox(height: 14),

        // Ticket Digital Glassmorphic
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.greenBiomass.withValues(alpha: 0.35)),
            boxShadow: [
              BoxShadow(
                color: AppColors.greenBiomass.withValues(alpha: 0.08),
                blurRadius: 16,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Cabecera del Ticket
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.verified_rounded, color: AppColors.greenBiomass, size: 22),
                      const SizedBox(width: 8),
                      Text(
                        'FACTURA ${_facturaCtrl.text.trim().toUpperCase()}',
                        style: AppTypography.titleMedium.copyWith(color: AppColors.greenBiomass, fontSize: 15, fontWeight: FontWeight.w900),
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: (_esCredito ? AppColors.amberWarning : AppColors.greenBiomass).withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      _esCredito ? 'CRÉDITO A VENCER' : 'PAGADO DE CONTADO',
                      style: TextStyle(
                        color: _esCredito ? AppColors.amberWarning : AppColors.greenBiomass,
                        fontSize: 9.5,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text('Emisor: ${_selectedSupplier?.nombre ?? "Proveedor"} (NIT: ${_selectedSupplier?.nit ?? "N/A"})', style: const TextStyle(color: AppColors.textSecondaryDark, fontSize: 12)),
              Text('Expedición: ${_fechaExpedicion.day}/${_fechaExpedicion.month}/${_fechaExpedicion.year} • Vencimiento: ${_fechaVencimiento.day}/${_fechaVencimiento.month}/${_fechaVencimiento.year}', style: const TextStyle(color: AppColors.textSecondaryDark, fontSize: 11.5)),

              const Padding(
                padding: EdgeInsets.symmetric(vertical: 10),
                child: Divider(height: 1, color: Colors.white12),
              ),

              // Resumen de Líneas de Factura
              ..._items.map((it) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          '${it.cantidad.toInt()} x ${it.nombre}',
                          style: TextStyle(color: isDark ? Colors.white : AppColors.textPrimaryLight, fontSize: 12, fontWeight: FontWeight.w600),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Text(CurrencyFormatters.formatCOP(it.valorTotal), style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
                    ],
                  ),
                );
              }),

              const Padding(
                padding: EdgeInsets.symmetric(vertical: 8),
                child: Divider(height: 1, color: Colors.white12),
              ),

              // Desglose Tributario
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Subtotal Bruto:', style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondaryDark)),
                  Text(CurrencyFormatters.formatCOP(_totalBruto), style: TextStyle(color: isDark ? Colors.white : AppColors.textPrimaryLight, fontSize: 12.5, fontWeight: FontWeight.w700)),
                ],
              ),
              const SizedBox(height: 4),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Total IVA Liquidado:', style: AppTypography.bodySmall.copyWith(color: AppColors.amberWarning)),
                  Text('+ ${CurrencyFormatters.formatCOP(_totalIva)}', style: const TextStyle(color: AppColors.amberWarning, fontSize: 12.5, fontWeight: FontWeight.w700)),
                ],
              ),
              if (_flete > 0) ...[
                const SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Flete de Transporte Prorrateado:', style: AppTypography.bodySmall.copyWith(color: AppColors.cyanWater)),
                    Text('+ ${CurrencyFormatters.formatCOP(_flete)}', style: const TextStyle(color: AppColors.cyanWater, fontSize: 12.5, fontWeight: FontWeight.w700)),
                  ],
                ),
              ],
              const SizedBox(height: 6),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    _categoriaSeleccionada == 'concentrados' || _categoriaSeleccionada == 'insumos'
                        ? 'Costo Ponderado / Kg Puesto en Bodega:'
                        : 'Costo Ponderado / Unidad Puesto en Bodega:',
                    style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondaryDark),
                  ),
                  Text(CurrencyFormatters.formatCOP(_costoPromedioPorUnidadConFlete), style: const TextStyle(color: AppColors.greenBiomass, fontWeight: FontWeight.w800, fontSize: 12.5)),
                ],
              ),

              const Padding(
                padding: EdgeInsets.symmetric(vertical: 10),
                child: Divider(height: 1, color: Colors.white12),
              ),

              // Gran Total
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('TOTAL FACTURA:', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 13.5)),
                      Text(
                        _categoriaSeleccionada == 'concentrados' || _categoriaSeleccionada == 'insumos'
                            ? '${CurrencyFormatters.formatKg(_totalCantidadFisica)} Ingresados a Bodega'
                            : '${_totalItemsCantidad.toInt()} Unidades Ingresadas',
                        style: const TextStyle(color: AppColors.greenBiomass, fontSize: 11, fontWeight: FontWeight.w700),
                      ),
                    ],
                  ),
                  Text(
                    CurrencyFormatters.formatCOP(_granTotalFactura),
                    style: const TextStyle(color: AppColors.greenBiomass, fontWeight: FontWeight.w900, fontSize: 20),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Botón de Confirmación Principal dentro del Ticket
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _isSubmitting ? null : _guardarFactura,
                  icon: _isSubmitting
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black),
                        )
                      : const Icon(Icons.check_circle_rounded, color: Colors.black, size: 20),
                  label: Text(
                    _isSubmitting
                        ? 'Registrando Factura...'
                        : (_categoriaSeleccionada == 'concentrados' || _categoriaSeleccionada == 'insumos'
                            ? 'Confirmar Factura e Ingresar ${CurrencyFormatters.formatKg(_totalCantidadFisica)}'
                            : 'Confirmar Factura e Ingresar ${_totalItemsCantidad.toInt()} Unidades'),
                    style: const TextStyle(color: Colors.black, fontSize: 13.5, fontWeight: FontWeight.w900),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.greenBiomass,
                    elevation: 4,
                    shadowColor: AppColors.greenBiomass.withValues(alpha: 0.4),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// Botones de Navegación Inferior (Atrás / Continuar / Confirmar)
  Widget _buildNavigationButtons() {
    return Row(
      children: [
        // Botón Atrás / Cancelar
        TextButton.icon(
          onPressed: _prevStep,
          icon: Icon(_currentStep == 0 ? Icons.close_rounded : Icons.arrow_back_rounded, size: 16, color: AppColors.textSecondaryDark),
          label: Text(
            _currentStep == 0 ? 'Cancelar' : 'Atrás',
            style: const TextStyle(color: AppColors.textSecondaryDark, fontSize: 13, fontWeight: FontWeight.w600),
          ),
        ),
        const Spacer(),

        // Botón Continuar o Confirmar Factura
        if (_currentStep < 3)
          ElevatedButton.icon(
            onPressed: _nextStep,
            icon: const Icon(Icons.arrow_forward_rounded, size: 16, color: Colors.black),
            label: const Text('Continuar', style: TextStyle(color: Colors.black, fontSize: 13, fontWeight: FontWeight.w800)),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.amberWarning,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            ),
          )
        else
          ElevatedButton.icon(
            onPressed: _isSubmitting ? null : _guardarFactura,
            icon: const Icon(Icons.check_circle_rounded, color: Colors.black, size: 18),
            label: Text(
              _isSubmitting ? 'Guardando...' : 'Confirmar Factura',
              style: const TextStyle(color: Colors.black, fontSize: 13, fontWeight: FontWeight.w800),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.greenBiomass,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            ),
          ),
      ],
    );
  }

  // --- COMPONENTES AUXILIARES ---

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
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: _esCredito
              ? AppColors.amberWarning.withValues(alpha: isDark ? 0.15 : 0.1)
              : AppColors.greenBiomass.withValues(alpha: isDark ? 0.15 : 0.1),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: _esCredito ? AppColors.amberWarning.withValues(alpha: 0.3) : AppColors.greenBiomass.withValues(alpha: 0.3),
          ),
        ),
        child: Row(
          children: [
            Icon(
              _esCredito ? Icons.calendar_month_rounded : Icons.payments_rounded,
              color: _esCredito ? AppColors.amberWarning : AppColors.greenBiomass,
              size: 20,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'MODALIDAD DE PAGO',
                    style: AppTypography.labelMicro.copyWith(
                      color: _esCredito ? AppColors.amberWarning : AppColors.greenBiomass,
                      fontSize: 9.5,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  Text(
                    _esCredito ? 'Crédito Comercial' : 'Pago de Contado',
                    style: TextStyle(
                      color: isDark ? Colors.white : AppColors.textPrimaryLight,
                      fontWeight: FontWeight.w800,
                      fontSize: 13,
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
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              _categoriaSeleccionada == 'concentrados' ? 'PROVEEDOR DE ALIMENTOS' : 'PROVEEDOR',
              style: AppTypography.labelMicro.copyWith(
                color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                fontWeight: FontWeight.w800,
              ),
            ),
            GestureDetector(
              onTap: () => ProveedoresModal.show(context),
              child: const Text(
                '+ Nuevo Proveedor',
                style: TextStyle(
                  color: AppColors.cyanWater,
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ],
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
              hint: const Text('Seleccionar o registrar proveedor...', style: TextStyle(fontSize: 12, color: Colors.grey)),
              style: TextStyle(color: isDark ? Colors.white : AppColors.textPrimaryLight, fontSize: 13, fontWeight: FontWeight.w600),
              onChanged: (sup) {
                setState(() {
                  _selectedSupplier = sup;
                  if (_items.isNotEmpty && _categoriaSeleccionada != 'concentrados' && _categoriaSeleccionada != 'alevinos') {
                    final firstProd = sup?.productosOfrecidos.isNotEmpty == true ? sup!.productosOfrecidos.first : 'Producto';
                    _items[0].nombre = firstProd;
                    _items[0].costoUnitarioCtrl.text = _guessPrice(firstProd);
                  }
                });
              },
              items: filteredSuppliers.map((s) => DropdownMenuItem<Supplier>(
                value: s,
                child: Row(
                  children: [
                    if (s.isCustom)
                      Container(
                        margin: const EdgeInsets.only(right: 6),
                        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                        decoration: BoxDecoration(
                          color: AppColors.cyanWater.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text('PROPIO', style: TextStyle(color: AppColors.cyanWater, fontSize: 8.5, fontWeight: FontWeight.w800)),
                      )
                    else
                      Container(
                        margin: const EdgeInsets.only(right: 6),
                        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                        decoration: BoxDecoration(
                          color: AppColors.greenBiomass.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text('OFICIAL', style: TextStyle(color: AppColors.greenBiomass, fontSize: 8.5, fontWeight: FontWeight.w800)),
                      ),
                    Expanded(child: Text('${s.nombre} (${s.nit})', overflow: TextOverflow.ellipsis)),
                  ],
                ),
              )).toList(),
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
        focusedBorder: const OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(14)), borderSide: BorderSide(color: AppColors.cyanWater, width: 1.6)),
      ),
    );
  }

  Widget _buildProductBentoCard(EditableInvoiceItem item, int index, List<String> availableProducts, bool isDark) {
    final unidadesDisponibles = _getUnidadesDisponiblesPorCategoria();
    final esConcentrado = _categoriaSeleccionada == 'concentrados';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
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
              Expanded(flex: 4, child: _buildProductDropdown(item, availableProducts, isDark)),
              const SizedBox(width: 8),
              Expanded(flex: 3, child: _buildUnitDropdown(item, unidadesDisponibles, isDark)),
              if (_items.length > 1)
                IconButton(
                  icon: const Icon(Icons.delete_outline_rounded, color: AppColors.coralAction, size: 20),
                  visualDensity: VisualDensity.compact,
                  onPressed: () => _removeItem(index),
                ),
            ],
          ),
          const SizedBox(height: 10),
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
          const SizedBox(height: 8),
          _buildItemSummaryFooter(item, isDark),
        ],
      ),
    );
  }

  Widget _buildProductDropdown(EditableInvoiceItem item, List<String> availableProducts, bool isDark) {
    if (availableProducts.isNotEmpty && !availableProducts.contains(item.nombre)) {
      final defaultProduct = availableProducts.first;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && item.nombre != defaultProduct) {
          setState(() {
            item.nombre = defaultProduct;
            item.costoUnitarioCtrl.text = _guessPrice(defaultProduct);
          });
        }
      });
    }

    final currentVal = availableProducts.contains(item.nombre) ? item.nombre : (availableProducts.isNotEmpty ? availableProducts.first : null);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withValues(alpha: 0.04) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: isDark ? Colors.white12 : AppColors.glassBorderLight),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: currentVal,
          isExpanded: true,
          dropdownColor: isDark ? AppColors.surfaceDark : Colors.white,
          style: TextStyle(color: isDark ? Colors.white : AppColors.textPrimaryLight, fontSize: 12, fontWeight: FontWeight.w700),
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

  Widget _buildUnitDropdown(EditableInvoiceItem item, List<String> unidadesDisponibles, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withValues(alpha: 0.04) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: isDark ? Colors.white12 : AppColors.glassBorderLight),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: unidadesDisponibles.contains(item.unidadMedida) ? item.unidadMedida : unidadesDisponibles.first,
          isExpanded: true,
          dropdownColor: isDark ? AppColors.surfaceDark : Colors.white,
          style: TextStyle(color: isDark ? Colors.white : AppColors.textPrimaryLight, fontSize: 12),
          onChanged: (val) {
            if (val != null) {
              setState(() {
                item.unidadMedida = val;
                if (val.contains('40')) {
                  item.factorUnidadCtrl.text = '40';
                } else if (val.contains('20')) {
                  item.factorUnidadCtrl.text = '20';
                } else if (val.contains('50')) {
                  item.factorUnidadCtrl.text = '50';
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
