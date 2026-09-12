import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import 'package:fishbit_finance/core/design_system/app_colors.dart';
import 'package:fishbit_finance/core/design_system/app_typography.dart';
import 'package:fishbit_finance/core/design_system/glass_container.dart';
import 'package:fishbit_finance/core/design_system/glass_button.dart';
import 'package:fishbit_finance/core/utils/currency_formatters.dart';
import 'package:fishbit_finance/modules/auth_tenant/presentation/providers/auth_provider.dart';
import 'package:fishbit_finance/modules/warehouse_inventory/domain/models/inventory_item.dart';
import 'package:fishbit_finance/modules/warehouse_inventory/domain/models/supplier.dart';
import 'package:fishbit_finance/modules/warehouse_inventory/domain/services/product_catalog_service.dart';
import 'package:fishbit_finance/modules/warehouse_inventory/presentation/providers/warehouse_provider.dart';
import 'package:fishbit_finance/modules/warehouse_inventory/presentation/dialogs/proveedores_modal.dart';

class NuevoItemModal extends ConsumerStatefulWidget {
  final InventoryItemType initialType;

  const NuevoItemModal({super.key, this.initialType = InventoryItemType.concentrado});

  static Future<void> show(BuildContext context, {InventoryItemType initialType = InventoryItemType.concentrado}) {
    return showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => NuevoItemModal(initialType: initialType),
    );
  }

  @override
  ConsumerState<NuevoItemModal> createState() => _NuevoItemModalState();
}

class _NuevoItemModalState extends ConsumerState<NuevoItemModal> {
  final _formKey = GlobalKey<FormState>();

  // Wizard Step (0: Categoría y Proveedor, 1: Producto y Ficha Técnica, 2: Cantidades y Flete, 3: Ticket Contable y Confirmación)
  int _currentStep = 0;

  late InventoryItemType _selectedType;
  String? _selectedSupplier;
  String? _selectedProduct;

  // Concentrados
  double _proteinaCruda = 38.0;
  double _kgPorBulto = 40.0;

  // Farmacia
  final _principioActivoCtrl = TextEditingController();
  int _diasRetiroSanitario = 0;

  // Oxigenadores / Equipos
  double _potenciaHp = 2.0;
  String _faseElectrica = 'Trifásico 220V/440V';

  // Alevinos / Semilla
  String _especieAlevino = 'Trucha Arcoíris';
  final _pesoPromedioCtrl = TextEditingController(text: '1.5');

  // Insumos
  String _presentacionInsumo = 'Saco 40 Kg';
  double _kgPorUnidadInsumo = 40.0;

  // Controladores Generales
  final _cantidadCtrl = TextEditingController();
  final _costoUnitarioBrutoCtrl = TextEditingController();
  final _fleteCtrl = TextEditingController();
  final _loteCtrl = TextEditingController();
  final _stockMinimoCtrl = TextEditingController();
  DateTime? _fechaVencimiento;
  bool _isSubmitting = false;

  String get _categoryKey {
    switch (_selectedType) {
      case InventoryItemType.concentrado:
        return 'concentrados';
      case InventoryItemType.insumo:
        return 'insumos';
      case InventoryItemType.farmacia:
        return 'farmacia';
      case InventoryItemType.oxigenador:
        return 'oxigenadores';
      case InventoryItemType.alevino:
        return 'alevinos';
      default:
        return 'concentrados';
    }
  }

  @override
  void initState() {
    super.initState();
    _selectedType = widget.initialType;
    if (_selectedType == InventoryItemType.farmacia) {
      _fechaVencimiento = DateTime.now().add(const Duration(days: 365));
    }
    _stockMinimoCtrl.text = _getDefaultStockMinimo(_selectedType).toStringAsFixed(0);
    
    final company = ref.read(authProvider).currentCompany;
    if (company != null && company.especiesHabilitadas.isNotEmpty) {
      _especieAlevino = company.especiesHabilitadas.first;
    }
  }

  double _getDefaultStockMinimo(InventoryItemType type) {
    switch (type) {
      case InventoryItemType.concentrado:
        return 400.0;
      case InventoryItemType.insumo:
        return 100.0;
      case InventoryItemType.alevino:
        return 1000.0;
      case InventoryItemType.oxigenador:
      case InventoryItemType.herramienta:
        return 1.0;
      case InventoryItemType.farmacia:
        return 2.0;
    }
  }

  @override
  void dispose() {
    _cantidadCtrl.dispose();
    _costoUnitarioBrutoCtrl.dispose();
    _fleteCtrl.dispose();
    _loteCtrl.dispose();
    _stockMinimoCtrl.dispose();
    _principioActivoCtrl.dispose();
    _pesoPromedioCtrl.dispose();
    super.dispose();
  }

  void _onTypeChanged(InventoryItemType newType) {
    if (_selectedType == newType) return;
    setState(() {
      _selectedType = newType;
      _selectedSupplier = null;
      _selectedProduct = null;
      _stockMinimoCtrl.text = _getDefaultStockMinimo(newType).toStringAsFixed(0);
      if (newType == InventoryItemType.farmacia && _fechaVencimiento == null) {
        _fechaVencimiento = DateTime.now().add(const Duration(days: 365));
      }
    });
  }

  void _onProductSelected(String productName) {
    setState(() {
      _selectedProduct = productName;
      final lower = productName.toLowerCase();

      if (_selectedType == InventoryItemType.concentrado) {
        if (lower.contains('micro') || lower.contains('48%')) {
          _kgPorBulto = 20.0;
          _proteinaCruda = 48.0;
        } else if (lower.contains('45%') || lower.contains('iniciación') || lower.contains('iniciador') || lower.contains('alevine')) {
          _kgPorBulto = 40.0;
          _proteinaCruda = 45.0;
        } else if (lower.contains('40%')) {
          _kgPorBulto = 40.0;
          _proteinaCruda = 40.0;
        } else if (lower.contains('38%') || lower.contains('prelevante')) {
          _kgPorBulto = 40.0;
          _proteinaCruda = 38.0;
        } else if (lower.contains('36%')) {
          _kgPorBulto = 40.0;
          _proteinaCruda = 36.0;
        } else if (lower.contains('34%')) {
          _kgPorBulto = 40.0;
          _proteinaCruda = 34.0;
        } else if (lower.contains('32%')) {
          _kgPorBulto = 40.0;
          _proteinaCruda = 32.0;
        } else if (lower.contains('30%')) {
          _kgPorBulto = 40.0;
          _proteinaCruda = 30.0;
        } else if (lower.contains('28%')) {
          _kgPorBulto = 40.0;
          _proteinaCruda = 28.0;
        } else if (lower.contains('25%')) {
          _kgPorBulto = 40.0;
          _proteinaCruda = 25.0;
        } else if (lower.contains('24%')) {
          _kgPorBulto = 40.0;
          _proteinaCruda = 24.0;
        } else if (lower.contains('22%')) {
          _kgPorBulto = 40.0;
          _proteinaCruda = 22.0;
        } else if (lower.contains('20%')) {
          _kgPorBulto = 40.0;
          _proteinaCruda = 20.0;
        } else if (lower.contains('50%')) {
          _kgPorBulto = 40.0;
          _proteinaCruda = 50.0;
        } else {
          _kgPorBulto = 40.0;
          _proteinaCruda = 32.0;
        }
      } else if (_selectedType == InventoryItemType.farmacia) {
        if (lower.contains('oxitetraciclina')) {
          _principioActivoCtrl.text = 'Oxitetraciclina Clorhidrato 500mg/g';
          _diasRetiroSanitario = 21;
        } else if (lower.contains('florfenicol')) {
          _principioActivoCtrl.text = 'Florfenicol 50% Grado Acuícola';
          _diasRetiroSanitario = 15;
        } else if (lower.contains('formalina')) {
          _principioActivoCtrl.text = 'Formaldehído 37% acuoso';
          _diasRetiroSanitario = 0;
        } else if (lower.contains('azul')) {
          _principioActivoCtrl.text = 'Azul de Metileno USP';
          _diasRetiroSanitario = 0;
        } else if (lower.contains('sulfato')) {
          _principioActivoCtrl.text = 'Sulfato de Cobre Pentahidratado';
          _diasRetiroSanitario = 5;
        } else {
          _principioActivoCtrl.text = 'Vitamina / Probiótico';
          _diasRetiroSanitario = 0;
        }
      } else if (_selectedType == InventoryItemType.insumo) {
        if (lower.contains('50 kg') || lower.contains('sal')) {
          _presentacionInsumo = 'Saco 50 Kg';
          _kgPorUnidadInsumo = 50.0;
        } else if (lower.contains('25 kg') || lower.contains('caneca') || lower.contains('melaza') || lower.contains('zeolita')) {
          _presentacionInsumo = 'Caneca/Saco 25 Kg';
          _kgPorUnidadInsumo = 25.0;
        } else if (lower.contains('litro') || lower.contains('galón')) {
          _presentacionInsumo = 'Litro / Galón';
          _kgPorUnidadInsumo = 1.0;
        } else {
          _presentacionInsumo = 'Saco 40 Kg';
          _kgPorUnidadInsumo = 40.0;
        }
      } else if (_selectedType == InventoryItemType.oxigenador) {
        if (lower.contains('1.0 hp') || lower.contains('monofásico')) {
          _potenciaHp = 1.0;
          _faseElectrica = 'Monofásico 110V/220V';
        } else if (lower.contains('1.5 hp')) {
          _potenciaHp = 1.5;
          _faseElectrica = 'Trifásico 220V';
        } else if (lower.contains('2.5 hp')) {
          _potenciaHp = 2.5;
          _faseElectrica = 'Trifásico 220V/440V';
        } else if (lower.contains('3.0 hp')) {
          _potenciaHp = 3.0;
          _faseElectrica = 'Trifásico 220V/440V';
        } else {
          _potenciaHp = 2.0;
          _faseElectrica = 'Trifásico 220V/440V';
        }
      } else if (_selectedType == InventoryItemType.alevino) {
        final company = ref.read(authProvider).currentCompany;
        final companySpecies = company?.especiesHabilitadas ?? [];
        
        if (lower.contains('trucha')) {
          _especieAlevino = companySpecies.firstWhere((s) => s.toLowerCase().contains('trucha'), orElse: () => 'Trucha Arcoíris');
        } else if (lower.contains('tilapia')) {
          _especieAlevino = companySpecies.firstWhere((s) => s.toLowerCase().contains('tilapia'), orElse: () => 'Tilapia');
        } else if (lower.contains('cachama')) {
          _especieAlevino = companySpecies.firstWhere((s) => s.toLowerCase().contains('cachama'), orElse: () => 'Cachama Blanca');
        }
      }
    });
  }

  // Cálculos contables
  double get _cantidad => double.tryParse(_cantidadCtrl.text.replaceAll(RegExp(r'[^\d.]'), '')) ?? 0.0;
  
  double get _totalKilosOUunidades {
    switch (_selectedType) {
      case InventoryItemType.concentrado:
        return _cantidad * _kgPorBulto;
      case InventoryItemType.insumo:
        return _cantidad * _kgPorUnidadInsumo;
      case InventoryItemType.alevino:
      case InventoryItemType.oxigenador:
      case InventoryItemType.farmacia:
      case InventoryItemType.herramienta:
        return _cantidad;
    }
  }

  double get _precioUnitarioBruto => CurrencyFormatters.parseCOP(_costoUnitarioBrutoCtrl.text);
  double get _fleteTransporte => CurrencyFormatters.parseCOP(_fleteCtrl.text);

  double get _subtotalBruto => _cantidad * _precioUnitarioBruto;
  double get _ivaPct => _selectedType == InventoryItemType.concentrado ? 0.05 : 0.0;
  double get _valorIva => _subtotalBruto * _ivaPct;
  double get _subtotalFactura => _subtotalBruto + _valorIva;
  double get _granTotalPuestoEnGranja => _subtotalFactura + _fleteTransporte;
  double get _costoRealPorUnidad => _totalKilosOUunidades > 0 ? (_granTotalPuestoEnGranja / _totalKilosOUunidades) : 0.0;
  double get _fletePorUnidad => _totalKilosOUunidades > 0 ? (_fleteTransporte / _totalKilosOUunidades) : 0.0;

  String get _unidadMedidaLabel {
    switch (_selectedType) {
      case InventoryItemType.concentrado:
        return 'BULTOS';
      case InventoryItemType.insumo:
        return 'SACOS / CANECAS';
      case InventoryItemType.alevino:
        return 'MILLARES / PECES';
      case InventoryItemType.oxigenador:
        return 'EQUIPOS (UNID)';
      case InventoryItemType.farmacia:
        return 'FRASCOS / BOLSAS';
      case InventoryItemType.herramienta:
        return 'UNIDADES';
    }
  }

  String get _presentacionFinal {
    switch (_selectedType) {
      case InventoryItemType.concentrado:
        return 'Bulto ${_kgPorBulto.toStringAsFixed(0)} Kg';
      case InventoryItemType.insumo:
        return _presentacionInsumo;
      case InventoryItemType.alevino:
        return 'Millar (${_pesoPromedioCtrl.text}g)';
      case InventoryItemType.oxigenador:
        return 'Motor ${_potenciaHp}HP $_faseElectrica';
      case InventoryItemType.farmacia:
        return 'Fármaco / Principio Activo';
      case InventoryItemType.herramienta:
        return 'Unidad';
    }
  }

  bool _validateStep(int step) {
    if (step == 0) {
      if (_selectedSupplier == null || _selectedSupplier!.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Por favor selecciona o crea un proveedor.'), backgroundColor: AppColors.coralAction),
        );
        return false;
      }
      return true;
    } else if (step == 1) {
      if (_selectedProduct == null || _selectedProduct!.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Por favor selecciona el producto o referencia oficial.'), backgroundColor: AppColors.coralAction),
        );
        return false;
      }
      if (_selectedType == InventoryItemType.farmacia && _principioActivoCtrl.text.trim().isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Por favor indica el principio activo del fármaco.'), backgroundColor: AppColors.coralAction),
        );
        return false;
      }
      return true;
    } else if (step == 2) {
      if (_cantidad <= 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Ingresa una cantidad válida mayor a 0.'), backgroundColor: AppColors.coralAction),
        );
        return false;
      }
      if (_precioUnitarioBruto <= 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Ingresa un valor unitario bruto válido.'), backgroundColor: AppColors.coralAction),
        );
        return false;
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

  Future<void> _guardarItem() async {
    if (_selectedProduct == null || _selectedProduct!.isEmpty) return;

    setState(() => _isSubmitting = true);

    final auth = ref.read(authProvider);
    final empresaId = auth.currentCompany?.id ?? auth.currentUser?.empresaId ?? '';
    final unitId = auth.activeUnitId ?? auth.currentUser?.unidadAcuicolaId;

    if (empresaId.isEmpty) {
      setState(() => _isSubmitting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No se pudo determinar la empresa activa. Por favor verifica tu sesión.'),
          backgroundColor: AppColors.coralAction,
        ),
      );
      return;
    }

    final stockMinimo = double.tryParse(_stockMinimoCtrl.text.replaceAll(RegExp(r'[^\d.]'), '')) ?? _getDefaultStockMinimo(_selectedType);

    final item = InventoryItem(
      id: const Uuid().v4(),
      empresaId: empresaId,
      unidadAcuicolaId: unitId,
      tipo: _selectedType,
      nombre: _selectedProduct!,
      marcaProveedor: _selectedSupplier,
      presentacionUnidad: _presentacionFinal,
      cantidadOriginalKg: _totalKilosOUunidades,
      cantidadActualKg: _totalKilosOUunidades,
      costoUnitarioHistorico: _costoRealPorUnidad,
      costoTotal: _granTotalPuestoEnGranja,
      stockMinimoAlerta: stockMinimo,
      proteinaCrudaPct: _selectedType == InventoryItemType.concentrado ? _proteinaCruda : null,
      principioActivo: _selectedType == InventoryItemType.farmacia ? _principioActivoCtrl.text.trim() : null,
      diasRetiroSanitario: _selectedType == InventoryItemType.farmacia ? _diasRetiroSanitario : null,
      potenciaHp: _selectedType == InventoryItemType.oxigenador ? _potenciaHp : null,
      faseElectrica: _selectedType == InventoryItemType.oxigenador ? _faseElectrica : null,
      especieAlevino: _selectedType == InventoryItemType.alevino ? _especieAlevino : null,
      loteFabricante: _loteCtrl.text.trim().isNotEmpty ? _loteCtrl.text.trim() : null,
      fechaVencimiento: _fechaVencimiento,
      creadoEn: DateTime.now(),
    );

    final messenger = ScaffoldMessenger.of(context);
    final nav = Navigator.of(context);

    try {
      await ref.read(warehouseProvider.notifier).addInventory(item);

      if (mounted) {
        nav.pop();
        messenger.showSnackBar(
          SnackBar(
            content: Text('${InventoryItem.typeToString(_selectedType)} "${item.nombre}" registrado exitosamente en Bodega.'),
            backgroundColor: AppColors.greenBiomass,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSubmitting = false);
        messenger.showSnackBar(
          SnackBar(
            content: Text('Error al registrar ítem: $e'),
            backgroundColor: AppColors.coralAction,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(warehouseProvider);
    final authState = ref.watch(authProvider);
    final company = authState.currentCompany;
    final companySpecies = company?.especiesHabilitadas ?? ['Trucha Arcoíris'];

    final suppliers = state.suppliers.where((s) => s.categoriaPrincipal == _categoryKey).toList();

    // Inicializar proveedor por defecto
    if (_selectedSupplier == null && suppliers.isNotEmpty) {
      _selectedSupplier = suppliers.first.nombre;
    }

    final List<String> availableProducts;
    if (_selectedType == InventoryItemType.concentrado) {
      availableProducts = ProductCatalogService.getFeedProductsForSupplier(_selectedSupplier ?? '', companySpecies);
    } else if (_selectedType == InventoryItemType.alevino) {
      availableProducts = ProductCatalogService.getBiologicalProducts(companySpecies);
    } else {
      final currentSupplierObj = suppliers.firstWhere(
        (s) => s.nombre == _selectedSupplier,
        orElse: () => suppliers.isNotEmpty
            ? suppliers.first
            : const Supplier(id: '1', nit: '', nombre: 'Proveedor Oficial', categoriaPrincipal: 'insumos', productosOfrecidos: []),
      );
      availableProducts = currentSupplierObj.productosOfrecidos;
    }

    if (_selectedProduct == null && availableProducts.isNotEmpty) {
      _selectedProduct = availableProducts.first;
      _onProductSelected(availableProducts.first);
    } else if (_selectedProduct != null && !availableProducts.contains(_selectedProduct) && availableProducts.isNotEmpty) {
      _selectedProduct = availableProducts.first;
      _onProductSelected(availableProducts.first);
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;

    final (headerTitle, headerSubtitle, headerIcon, headerColor) = switch (_selectedType) {
      InventoryItemType.concentrado => ('Alimento en Bodega', 'Nutrición y Portafolio Balanceado', Icons.inventory_2_rounded, AppColors.cyanWater),
      InventoryItemType.farmacia => ('Fármaco Sanitario', 'Control de Principio Activo y Tiempos ICA', Icons.medical_services_rounded, AppColors.coralAction),
      InventoryItemType.insumo => ('Insumo Acuícola', 'Sal, Cal, Melaza y Aditivos', Icons.science_rounded, AppColors.amberWarning),
      InventoryItemType.oxigenador => ('Oxigenador / Equipo', 'Aireadores, Motores y Bombas', Icons.air_rounded, AppColors.cyanWater),
      InventoryItemType.alevino => ('Material Biológico', 'Ovas, Larvas y Alevinos', Icons.set_meal_rounded, AppColors.greenBiomass),
      InventoryItemType.herramienta => ('Herramienta / Activo', 'Redes, Balanzas y Equipos Menores', Icons.build_rounded, AppColors.amberWarning),
    };

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 580),
        child: GlassContainer(
          borderRadius: 24,
          padding: const EdgeInsets.all(22),
          blur: 24,
          opacity: 0.16,
          borderColor: headerColor.withValues(alpha: 0.35),
          child: Form(
            key: _formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header con título y botón de cierre
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: headerColor.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Icon(headerIcon, color: headerColor, size: 20),
                          ),
                          const SizedBox(width: 10),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(headerTitle, style: AppTypography.titleLarge.copyWith(color: headerColor, fontSize: 16, fontWeight: FontWeight.w800)),
                              Text(headerSubtitle, style: AppTypography.labelMicro.copyWith(color: AppColors.textSecondaryDark)),
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
                  const SizedBox(height: 14),

                  // Barra de Progreso del Wizard (Paso 1 a 4)
                  _buildWizardStepIndicator(headerColor),
                  const SizedBox(height: 18),

                  // Contenido según el paso activo con animación fluida
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 250),
                    child: switch (_currentStep) {
                      0 => _buildStep1CategoryAndSupplier(isDark, headerColor, suppliers),
                      1 => _buildStep2ProductAndSpecs(isDark, headerColor, availableProducts, companySpecies),
                      2 => _buildStep3QuantitiesAndFreight(isDark, headerColor),
                      3 => _buildStep4DigitalTicket(isDark, headerColor),
                      _ => const SizedBox.shrink(),
                    },
                  ),

                  const SizedBox(height: 20),

                  // Barra de Navegación Inferior (Atrás / Continuar / Confirmar)
                  _buildNavigationButtons(headerColor),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // --- WIDGETS DEL WIZARD ---

  /// Indicador interactivo superior de los 4 pasos
  Widget _buildWizardStepIndicator(Color accentColor) {
    final stepLabels = ['Categoría', 'Producto', 'Cantidades', 'Ticket Final'];

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
          final stepColor = isCurrent ? accentColor : (isCompleted ? AppColors.greenBiomass : Colors.white24);

          return Expanded(
            child: Row(
              children: [
                Container(
                  width: 22,
                  height: 22,
                  decoration: BoxDecoration(
                    color: isCurrent
                        ? accentColor.withValues(alpha: 0.2)
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
                              color: isCurrent ? accentColor : Colors.white54,
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

  /// PASO 1: Categoría & Proveedor
  Widget _buildStep1CategoryAndSupplier(bool isDark, Color accentColor, List<Supplier> suppliers) {
    return Column(
      key: const ValueKey(0),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'PASO 1: ¿QUÉ DESEAS INGRESAR A BODEGA?',
          style: AppTypography.labelMicro.copyWith(color: accentColor, fontWeight: FontWeight.w800, letterSpacing: 0.5),
        ),
        const SizedBox(height: 4),
        Text(
          'Selecciona la categoría del artículo para personalizar la ficha técnica y portafolios disponibles:',
          style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondaryDark, fontSize: 12),
        ),
        const SizedBox(height: 12),

        // Chips/Tarjetas Interactivas de Categoría
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _buildCategoryChip(InventoryItemType.concentrado, 'Alimento', Icons.inventory_2_rounded, AppColors.cyanWater),
            _buildCategoryChip(InventoryItemType.alevino, 'Alevinos / Semilla', Icons.set_meal_rounded, AppColors.greenBiomass),
            _buildCategoryChip(InventoryItemType.farmacia, 'Farmacia / Sanidad', Icons.medical_services_rounded, AppColors.coralAction),
            _buildCategoryChip(InventoryItemType.insumo, 'Insumos / Químicos', Icons.science_rounded, AppColors.amberWarning),
            _buildCategoryChip(InventoryItemType.oxigenador, 'Oxigenador / Equipo', Icons.air_rounded, AppColors.cyanWater),
            _buildCategoryChip(InventoryItemType.herramienta, 'Herramientas', Icons.build_rounded, AppColors.amberWarning),
          ],
        ),

        const SizedBox(height: 18),
        const Divider(height: 1, color: Colors.white12),
        const SizedBox(height: 14),

        // Selector de Proveedor / Fabricante
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('PROVEEDOR / FABRICANTE', style: AppTypography.labelMicro.copyWith(color: AppColors.textSecondaryDark, fontWeight: FontWeight.w700)),
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
        const SizedBox(height: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: isDark ? Colors.white.withValues(alpha: 0.06) : Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: isDark ? Colors.white.withValues(alpha: 0.12) : AppColors.glassBorderLight),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: _selectedSupplier,
              dropdownColor: isDark ? AppColors.surfaceDark : Colors.white,
              isExpanded: true,
              icon: Icon(Icons.keyboard_arrow_down_rounded, color: accentColor),
              items: suppliers.map((s) {
                final isCustom = s.isCustom;
                return DropdownMenuItem(
                  value: s.nombre,
                  child: Row(
                    children: [
                      Icon(Icons.factory_outlined, size: 16, color: accentColor),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          s.nombre,
                          style: TextStyle(
                            color: isDark ? Colors.white : AppColors.textPrimaryLight,
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: isCustom ? AppColors.cyanWater.withValues(alpha: 0.15) : AppColors.greenBiomass.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          isCustom ? 'PROPIO' : 'OFICIAL',
                          style: TextStyle(
                            color: isCustom ? AppColors.cyanWater : AppColors.greenBiomass,
                            fontSize: 9,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
              onChanged: (val) {
                if (val != null) {
                  setState(() {
                    _selectedSupplier = val;
                    final supObj = suppliers.firstWhere((s) => s.nombre == val);
                    if (supObj.productosOfrecidos.isNotEmpty) {
                      _onProductSelected(supObj.productosOfrecidos.first);
                    }
                  });
                }
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCategoryChip(InventoryItemType type, String label, IconData icon, Color color) {
    final isSelected = _selectedType == type;

    return InkWell(
      onTap: () => _onTypeChanged(type),
      borderRadius: BorderRadius.circular(12),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? color.withValues(alpha: 0.22) : Colors.white.withValues(alpha: 0.04),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? color : Colors.white.withValues(alpha: 0.09),
            width: isSelected ? 1.5 : 1.0,
          ),
        ),
        child: Row(
          mainAxisSize: dynamicIconSize(16),
          children: [
            Icon(icon, color: isSelected ? color : Colors.white60, size: 16),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.white : Colors.white70,
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.w800 : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  MainAxisSize dynamicIconSize(double size) => MainAxisSize.min;

  /// PASO 2: Producto & Ficha Técnica
  Widget _buildStep2ProductAndSpecs(bool isDark, Color accentColor, List<String> availableProducts, List<String> companySpecies) {
    return Column(
      key: const ValueKey(1),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'PASO 2: PRODUCTO Y FICHA TÉCNICA',
          style: AppTypography.labelMicro.copyWith(color: accentColor, fontWeight: FontWeight.w800, letterSpacing: 0.5),
        ),
        const SizedBox(height: 4),
        Text(
          'Portafolio oficial disponible para $_selectedSupplier y las especies de la piscícola:',
          style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondaryDark, fontSize: 12),
        ),
        const SizedBox(height: 12),

        // Referencia Oficial del Producto
        Text('REFERENCIA / ARTÍCULO OFICIAL', style: AppTypography.labelMicro.copyWith(color: accentColor, fontWeight: FontWeight.w800)),
        const SizedBox(height: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
          decoration: BoxDecoration(
            color: isDark ? Colors.white.withValues(alpha: 0.06) : Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: accentColor.withValues(alpha: 0.35)),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: availableProducts.contains(_selectedProduct)
                  ? _selectedProduct
                  : (availableProducts.isNotEmpty ? availableProducts.first : null),
              dropdownColor: isDark ? AppColors.surfaceDark : Colors.white,
              isExpanded: true,
              icon: const Icon(Icons.check_circle_outline_rounded, color: AppColors.greenBiomass, size: 18),
              items: availableProducts.map((p) {
                return DropdownMenuItem(
                  value: p,
                  child: Text(
                    p,
                    style: TextStyle(
                      color: isDark ? Colors.white : AppColors.textPrimaryLight,
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                );
              }).toList(),
              onChanged: (val) {
                if (val != null) _onProductSelected(val);
              },
            ),
          ),
        ),
        const SizedBox(height: 14),

        // Ficha Técnica contextual
        if (_selectedType == InventoryItemType.concentrado) ...[
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: AppColors.cyanWater.withValues(alpha: isDark ? 0.08 : 0.05),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.cyanWater.withValues(alpha: 0.25)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.biotech_rounded, color: AppColors.cyanWater, size: 20),
                      const SizedBox(width: 8),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('% PROTEÍNA (PB)', style: AppTypography.labelMicro.copyWith(fontSize: 9, color: AppColors.cyanWater)),
                          Text('${_proteinaCruda.toStringAsFixed(0)}% PB', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14, color: AppColors.cyanWater)),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: AppColors.amberWarning.withValues(alpha: isDark ? 0.08 : 0.05),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.amberWarning.withValues(alpha: 0.25)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.scale_rounded, color: AppColors.amberWarning, size: 20),
                      const SizedBox(width: 8),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('PESO POR BULTO', style: AppTypography.labelMicro.copyWith(fontSize: 9, color: AppColors.amberWarning)),
                          Text('${_kgPorBulto.toStringAsFixed(0)} Kg / Bto', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14, color: AppColors.amberWarning)),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ] else if (_selectedType == InventoryItemType.farmacia) ...[
          TextFormField(
            controller: _principioActivoCtrl,
            style: TextStyle(color: isDark ? Colors.white : AppColors.textPrimaryLight, fontSize: 12.5),
            decoration: InputDecoration(
              labelText: 'Principio Activo Farmacéutico',
              labelStyle: const TextStyle(color: AppColors.textSecondaryDark, fontSize: 12),
              floatingLabelStyle: const TextStyle(color: AppColors.coralAction, fontSize: 12, fontWeight: FontWeight.w700),
              filled: true,
              fillColor: isDark ? Colors.white.withValues(alpha: 0.04) : Colors.white,
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: isDark ? Colors.white12 : AppColors.glassBorderLight)),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: isDark ? Colors.white12 : AppColors.glassBorderLight)),
              focusedBorder: const OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(14)), borderSide: BorderSide(color: AppColors.coralAction, width: 1.8)),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: isDark ? Colors.white.withValues(alpha: 0.04) : Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: isDark ? Colors.white12 : AppColors.glassBorderLight),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<int>(
                      value: _diasRetiroSanitario,
                      dropdownColor: isDark ? AppColors.surfaceDark : Colors.white,
                      isExpanded: true,
                      items: [0, 5, 10, 15, 21, 30, 45].map((d) {
                        return DropdownMenuItem(
                          value: d,
                          child: Text(
                            d == 0 ? 'Retiro: Inmediato (0 días)' : 'Retiro ICA: $d días',
                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                          ),
                        );
                      }).toList(),
                      onChanged: (val) => setState(() => _diasRetiroSanitario = val ?? 0),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: GestureDetector(
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: _fechaVencimiento ?? DateTime.now().add(const Duration(days: 365)),
                      firstDate: DateTime.now(),
                      lastDate: DateTime.now().add(const Duration(days: 365 * 5)),
                    );
                    if (picked != null) setState(() => _fechaVencimiento = picked);
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                    decoration: BoxDecoration(
                      color: isDark ? Colors.white.withValues(alpha: 0.04) : Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: isDark ? Colors.white12 : AppColors.glassBorderLight),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.event_available_rounded, size: 16, color: AppColors.coralAction),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            _fechaVencimiento != null
                                ? 'Vence: ${_fechaVencimiento!.day}/${_fechaVencimiento!.month}/${_fechaVencimiento!.year}'
                                : 'Fecha Vencimiento',
                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ] else if (_selectedType == InventoryItemType.alevino) ...[
          Row(
            children: [
              Expanded(
                flex: 3,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color: isDark ? Colors.white.withValues(alpha: 0.04) : Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: isDark ? Colors.white12 : AppColors.glassBorderLight),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: companySpecies.contains(_especieAlevino)
                          ? _especieAlevino
                          : (companySpecies.isNotEmpty ? companySpecies.first : null),
                      dropdownColor: isDark ? AppColors.surfaceDark : Colors.white,
                      isExpanded: true,
                      items: companySpecies.map((esp) {
                        return DropdownMenuItem(
                          value: esp,
                          child: Text(esp, style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700)),
                        );
                      }).toList(),
                      onChanged: (val) {
                        if (val != null) setState(() => _especieAlevino = val);
                      },
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                flex: 2,
                child: TextFormField(
                  controller: _pesoPromedioCtrl,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  style: TextStyle(color: isDark ? Colors.white : AppColors.textPrimaryLight, fontSize: 13, fontWeight: FontWeight.w700),
                  decoration: InputDecoration(
                    labelText: 'Peso Inicial (g)',
                    labelStyle: const TextStyle(color: AppColors.textSecondaryDark, fontSize: 11),
                    floatingLabelStyle: const TextStyle(color: AppColors.greenBiomass, fontSize: 12, fontWeight: FontWeight.w800),
                    suffixText: 'g',
                    filled: true,
                    fillColor: isDark ? Colors.white.withValues(alpha: 0.04) : Colors.white,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: isDark ? Colors.white12 : AppColors.glassBorderLight)),
                    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: isDark ? Colors.white12 : AppColors.glassBorderLight)),
                    focusedBorder: const OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(14)), borderSide: BorderSide(color: AppColors.greenBiomass, width: 1.8)),
                  ),
                ),
              ),
            ],
          ),
        ] else if (_selectedType == InventoryItemType.oxigenador) ...[
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color: isDark ? Colors.white.withValues(alpha: 0.04) : Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: isDark ? Colors.white12 : AppColors.glassBorderLight),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<double>(
                      value: _potenciaHp,
                      dropdownColor: isDark ? AppColors.surfaceDark : Colors.white,
                      isExpanded: true,
                      items: [0.5, 1.0, 1.5, 2.0, 2.5, 3.0, 4.0, 5.0].map((hp) {
                        return DropdownMenuItem(
                          value: hp,
                          child: Text('${hp.toStringAsFixed(1)} HP Potencia', style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700)),
                        );
                      }).toList(),
                      onChanged: (val) => setState(() => _potenciaHp = val ?? 2.0),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color: isDark ? Colors.white.withValues(alpha: 0.04) : Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: isDark ? Colors.white12 : AppColors.glassBorderLight),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: _faseElectrica,
                      dropdownColor: isDark ? AppColors.surfaceDark : Colors.white,
                      isExpanded: true,
                      items: ['Monofásico 110V/220V', 'Bifásico 220V', 'Trifásico 220V/440V', 'Solar Directo DC'].map((f) {
                        return DropdownMenuItem(
                          value: f,
                          child: Text(f, style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600)),
                        );
                      }).toList(),
                      onChanged: (val) => setState(() => _faseElectrica = val ?? 'Trifásico 220V/440V'),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ] else if (_selectedType == InventoryItemType.insumo) ...[
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: isDark ? Colors.white.withValues(alpha: 0.04) : Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: isDark ? Colors.white12 : AppColors.glassBorderLight),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: _presentacionInsumo,
                dropdownColor: isDark ? AppColors.surfaceDark : Colors.white,
                isExpanded: true,
                items: ['Saco 50 Kg', 'Saco 40 Kg', 'Caneca/Saco 25 Kg', 'Galón 3.8 L', 'Litro / Botella', 'Kilogramo Granel'].map((pres) {
                  return DropdownMenuItem(
                    value: pres,
                    child: Text(pres, style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700)),
                  );
                }).toList(),
                onChanged: (val) {
                  if (val != null) {
                    setState(() {
                      _presentacionInsumo = val;
                      if (val.contains('50')) {
                        _kgPorUnidadInsumo = 50.0;
                      } else if (val.contains('40')) {
                        _kgPorUnidadInsumo = 40.0;
                      } else if (val.contains('25')) {
                        _kgPorUnidadInsumo = 25.0;
                      } else if (val.contains('Galón')) {
                        _kgPorUnidadInsumo = 3.8;
                      } else {
                        _kgPorUnidadInsumo = 1.0;
                      }
                    });
                  }
                },
              ),
            ),
          ),
        ],

        const SizedBox(height: 14),

        // Lote del Fabricante
        TextFormField(
          controller: _loteCtrl,
          style: TextStyle(color: isDark ? Colors.white : AppColors.textPrimaryLight, fontSize: 13),
          decoration: InputDecoration(
            labelText: 'Lote del Fabricante (Opcional - Trazabilidad)',
            labelStyle: const TextStyle(color: AppColors.textSecondaryDark, fontSize: 12),
            floatingLabelStyle: TextStyle(color: accentColor, fontSize: 12, fontWeight: FontWeight.w700),
            filled: true,
            fillColor: isDark ? Colors.white.withValues(alpha: 0.04) : Colors.white,
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: isDark ? Colors.white12 : AppColors.glassBorderLight)),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: isDark ? Colors.white12 : AppColors.glassBorderLight)),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: accentColor, width: 1.8)),
          ),
        ),
      ],
    );
  }

  /// PASO 3: Cantidades & Flete
  Widget _buildStep3QuantitiesAndFreight(bool isDark, Color accentColor) {
    return Column(
      key: const ValueKey(2),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'PASO 3: CANTIDADES, COSTOS Y FLETE',
          style: AppTypography.labelMicro.copyWith(color: accentColor, fontWeight: FontWeight.w800, letterSpacing: 0.5),
        ),
        const SizedBox(height: 4),
        Text(
          'Especifica el volumen a ingresar y los valores de factura para el costeo contable:',
          style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondaryDark, fontSize: 12),
        ),
        const SizedBox(height: 14),

        // Cantidad y Unidad de Medida
        Row(
          children: [
            Expanded(
              flex: 3,
              child: TextFormField(
                controller: _cantidadCtrl,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                style: TextStyle(color: isDark ? Colors.white : AppColors.textPrimaryLight, fontSize: 15, fontWeight: FontWeight.w900),
                decoration: InputDecoration(
                  labelText: 'Cantidad a Ingresar',
                  labelStyle: const TextStyle(color: AppColors.textSecondaryDark, fontSize: 12),
                  floatingLabelStyle: TextStyle(color: accentColor, fontSize: 12, fontWeight: FontWeight.w800),
                  suffixText: _unidadMedidaLabel,
                  suffixStyle: TextStyle(color: accentColor, fontSize: 11, fontWeight: FontWeight.w800),
                  filled: true,
                  fillColor: isDark ? Colors.white.withValues(alpha: 0.04) : Colors.white,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: isDark ? Colors.white12 : AppColors.glassBorderLight)),
                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: isDark ? Colors.white12 : AppColors.glassBorderLight)),
                  focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: accentColor, width: 1.8)),
                ),
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Requerido' : null,
                onChanged: (_) => setState(() {}),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              flex: 2,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 11),
                decoration: BoxDecoration(
                  color: isDark ? Colors.white.withValues(alpha: 0.04) : Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: isDark ? Colors.white12 : AppColors.glassBorderLight),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('TOTAL FÍSICO', style: AppTypography.labelMicro.copyWith(fontSize: 8.5, color: AppColors.textSecondaryDark)),
                    const SizedBox(height: 2),
                    Text(
                      _selectedType == InventoryItemType.concentrado || _selectedType == InventoryItemType.insumo
                          ? CurrencyFormatters.formatKg(_totalKilosOUunidades)
                          : '${_cantidad.toInt()} Unid.',
                      style: TextStyle(color: accentColor, fontWeight: FontWeight.w800, fontSize: 12),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),

        // Valor Unitario Bruto y Flete
        Row(
          children: [
            Expanded(
              flex: 3,
              child: TextFormField(
                controller: _costoUnitarioBrutoCtrl,
                keyboardType: const TextInputType.numberWithOptions(decimal: false),
                inputFormatters: [CurrencyInputFormatter()],
                style: TextStyle(color: isDark ? Colors.white : AppColors.textPrimaryLight, fontSize: 13.5, fontWeight: FontWeight.w800),
                decoration: InputDecoration(
                  labelText: 'Valor Unitario Bruto (\$)',
                  labelStyle: const TextStyle(color: AppColors.textSecondaryDark, fontSize: 12, fontWeight: FontWeight.w600),
                  floatingLabelStyle: const TextStyle(color: AppColors.amberWarning, fontSize: 12, fontWeight: FontWeight.w800),
                  filled: true,
                  fillColor: isDark ? Colors.white.withValues(alpha: 0.04) : Colors.white,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: isDark ? Colors.white12 : AppColors.glassBorderLight)),
                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: isDark ? Colors.white12 : AppColors.glassBorderLight)),
                  focusedBorder: const OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(14)), borderSide: BorderSide(color: AppColors.amberWarning, width: 1.8)),
                ),
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Requerido' : null,
                onChanged: (_) => setState(() {}),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              flex: 2,
              child: TextFormField(
                controller: _fleteCtrl,
                keyboardType: const TextInputType.numberWithOptions(decimal: false),
                inputFormatters: [CurrencyInputFormatter()],
                style: TextStyle(color: isDark ? Colors.white : AppColors.textPrimaryLight, fontSize: 13, fontWeight: FontWeight.w700),
                decoration: InputDecoration(
                  labelText: 'Flete Total (\$)',
                  labelStyle: const TextStyle(color: AppColors.textSecondaryDark, fontSize: 12, fontWeight: FontWeight.w600),
                  floatingLabelStyle: TextStyle(color: accentColor, fontSize: 12, fontWeight: FontWeight.w800),
                  filled: true,
                  fillColor: isDark ? Colors.white.withValues(alpha: 0.04) : Colors.white,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: isDark ? Colors.white12 : AppColors.glassBorderLight)),
                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: isDark ? Colors.white12 : AppColors.glassBorderLight)),
                  focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: accentColor, width: 1.8)),
                ),
                onChanged: (_) => setState(() {}),
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),

        // Stock Mínimo de Alerta
        TextFormField(
          controller: _stockMinimoCtrl,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          style: TextStyle(color: isDark ? Colors.white : AppColors.textPrimaryLight, fontSize: 12.5),
          decoration: InputDecoration(
            labelText: 'Stock Mínimo de Alerta Preventiva',
            labelStyle: const TextStyle(color: AppColors.textSecondaryDark, fontSize: 12),
            floatingLabelStyle: TextStyle(color: accentColor, fontSize: 12, fontWeight: FontWeight.w700),
            suffixText: _selectedType == InventoryItemType.concentrado || _selectedType == InventoryItemType.insumo ? 'Kg' : 'Unid',
            filled: true,
            fillColor: isDark ? Colors.white.withValues(alpha: 0.04) : Colors.white,
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: isDark ? Colors.white12 : AppColors.glassBorderLight)),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: isDark ? Colors.white12 : AppColors.glassBorderLight)),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: accentColor, width: 1.8)),
          ),
        ),
      ],
    );
  }

  /// PASO 4: Ticket Digital Glassmorphic & Confirmación Contable
  Widget _buildStep4DigitalTicket(bool isDark, Color accentColor) {
    return Column(
      key: const ValueKey(3),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'PASO 4: TICKET DIGITAL Y LIQUIDACIÓN CONTABLE',
          style: AppTypography.labelMicro.copyWith(color: AppColors.greenBiomass, fontWeight: FontWeight.w800, letterSpacing: 0.5),
        ),
        const SizedBox(height: 4),
        Text(
          'Revisa el prorrateo de costos y confirma el ingreso físico a la bodega:',
          style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondaryDark, fontSize: 12),
        ),
        const SizedBox(height: 12),

        // Tarjeta Ticket Digital Glassmorphic
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.white,
            borderRadius: BorderRadius.circular(18),
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
              // Encabezado del Ticket
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.receipt_long_rounded, color: AppColors.greenBiomass, size: 20),
                      const SizedBox(width: 8),
                      Text('TICKET DE ENTRADA', style: AppTypography.titleMedium.copyWith(color: AppColors.greenBiomass, fontSize: 14, fontWeight: FontWeight.w900)),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppColors.greenBiomass.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text(
                      'BODEGA ACTIVA',
                      style: TextStyle(color: AppColors.greenBiomass, fontSize: 9.5, fontWeight: FontWeight.w800),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Datos del Producto
              Text(_selectedProduct ?? 'Producto no especificado', style: TextStyle(color: isDark ? Colors.white : AppColors.textPrimaryLight, fontSize: 15, fontWeight: FontWeight.w800)),
              Text('Fabricante: ${_selectedSupplier ?? "N/A"} • Presentación: $_presentacionFinal', style: const TextStyle(color: AppColors.textSecondaryDark, fontSize: 11.5)),
              if (_loteCtrl.text.trim().isNotEmpty)
                Text('Lote Fabricante: ${_loteCtrl.text.trim()}', style: const TextStyle(color: AppColors.cyanWater, fontSize: 11, fontWeight: FontWeight.w600)),

              const Padding(
                padding: EdgeInsets.symmetric(vertical: 10),
                child: Divider(height: 1, color: Colors.white12),
              ),

              // Desglose Contable
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Cantidad Física Ingresada:', style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondaryDark)),
                  Text(
                    _selectedType == InventoryItemType.concentrado || _selectedType == InventoryItemType.insumo
                        ? '${CurrencyFormatters.formatKg(_totalKilosOUunidades)} (${_cantidad.toInt()} $_unidadMedidaLabel)'
                        : '${_cantidad.toInt()} Unidades',
                    style: TextStyle(color: isDark ? Colors.white : AppColors.textPrimaryLight, fontWeight: FontWeight.w700, fontSize: 12),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Valor Bruto Subtotal:', style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondaryDark)),
                  Text(CurrencyFormatters.formatCOP(_subtotalBruto), style: TextStyle(color: isDark ? Colors.white70 : AppColors.textPrimaryLight, fontSize: 12)),
                ],
              ),
              if (_ivaPct > 0) ...[
                const SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('IVA Aplicado (5.0% Alimento):', style: AppTypography.bodySmall.copyWith(color: AppColors.amberWarning)),
                    Text('+ ${CurrencyFormatters.formatCOP(_valorIva)}', style: const TextStyle(color: AppColors.amberWarning, fontSize: 12, fontWeight: FontWeight.w700)),
                  ],
                ),
              ],
              if (_fleteTransporte > 0) ...[
                const SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Flete (+${CurrencyFormatters.formatCOP(_fletePorUnidad)}/unid):', style: AppTypography.bodySmall.copyWith(color: accentColor)),
                    Text('+ ${CurrencyFormatters.formatCOP(_fleteTransporte)}', style: TextStyle(color: accentColor, fontSize: 12, fontWeight: FontWeight.w700)),
                  ],
                ),
              ],

              const Padding(
                padding: EdgeInsets.symmetric(vertical: 10),
                child: Divider(height: 1, color: Colors.white12),
              ),

              // Total Puesto en Granja y Costo Real Ponderado
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Total Inversión Puesto en Granja:', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 12.5)),
                      Text(
                        _selectedType == InventoryItemType.concentrado || _selectedType == InventoryItemType.insumo
                            ? 'Costo Real Efectivo: ${CurrencyFormatters.formatCOP(_costoRealPorUnidad)} / Kg'
                            : 'Costo Real Efectivo: ${CurrencyFormatters.formatCOP(_costoRealPorUnidad)} / Unid',
                        style: const TextStyle(color: AppColors.greenBiomass, fontSize: 11.5, fontWeight: FontWeight.w800),
                      ),
                    ],
                  ),
                  Text(
                    CurrencyFormatters.formatCOP(_granTotalPuestoEnGranja),
                    style: const TextStyle(color: AppColors.greenBiomass, fontWeight: FontWeight.w900, fontSize: 16),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// Botones de Navegación Inferior (Atrás / Continuar / Confirmar)
  Widget _buildNavigationButtons(Color accentColor) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
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

        // Botón Continuar o Confirmar Ingreso
        if (_currentStep < 3)
          ElevatedButton.icon(
            onPressed: _nextStep,
            icon: const Icon(Icons.arrow_forward_rounded, size: 16, color: Colors.black),
            label: const Text('Continuar', style: TextStyle(color: Colors.black, fontSize: 13, fontWeight: FontWeight.w800)),
            style: ElevatedButton.styleFrom(
              backgroundColor: accentColor,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            ),
          )
        else
          GlassButton(
            label: _isSubmitting ? 'Registrando en Bodega...' : 'Confirmar e Ingresar a Bodega',
            backgroundColor: AppColors.greenBiomass,
            onPressed: _isSubmitting ? () {} : _guardarItem,
          ),
      ],
    );
  }
}
