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
import 'package:fishbit_finance/modules/warehouse_inventory/presentation/providers/warehouse_provider.dart';

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
  String _especieAlevino = 'Tilapia Roja';
  final _pesoPromedioCtrl = TextEditingController(text: '1.5');

  // Insumos
  String _presentacionInsumo = 'Saco 40 Kg';
  double _kgPorUnidadInsumo = 40.0;

  // Controladores Generales
  final _cantidadCtrl = TextEditingController();
  final _costoUnitarioBrutoCtrl = TextEditingController();
  final _fleteCtrl = TextEditingController();
  final _loteCtrl = TextEditingController();
  DateTime? _fechaVencimiento;

  String get _categoryKey {
    switch (widget.initialType) {
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
    if (widget.initialType == InventoryItemType.farmacia) {
      _fechaVencimiento = DateTime.now().add(const Duration(days: 365));
    }
    final company = ref.read(authProvider).currentCompany;
    if (company != null && company.especiesHabilitadas.isNotEmpty) {
      _especieAlevino = company.especiesHabilitadas.first;
    }
  }

  @override
  void dispose() {
    _cantidadCtrl.dispose();
    _costoUnitarioBrutoCtrl.dispose();
    _fleteCtrl.dispose();
    _loteCtrl.dispose();
    _principioActivoCtrl.dispose();
    _pesoPromedioCtrl.dispose();
    super.dispose();
  }

  void _onProductSelected(String productName) {
    setState(() {
      _selectedProduct = productName;
      final lower = productName.toLowerCase();

      if (widget.initialType == InventoryItemType.concentrado) {
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
      } else if (widget.initialType == InventoryItemType.farmacia) {
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
      } else if (widget.initialType == InventoryItemType.insumo) {
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
      } else if (widget.initialType == InventoryItemType.oxigenador) {
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
      } else if (widget.initialType == InventoryItemType.alevino) {
        if (lower.contains('plateada') || lower.contains('nilótica')) {
          _especieAlevino = 'Tilapia Nilótica';
        } else if (lower.contains('cachama')) {
          _especieAlevino = 'Cachama Blanca';
        } else if (lower.contains('bocachico')) {
          _especieAlevino = 'Bocachico';
        } else if (lower.contains('trucha')) {
          _especieAlevino = 'Trucha Arcoíris';
        } else {
          _especieAlevino = 'Tilapia Roja';
        }
      }
    });
  }

  // Cálculos contables
  double get _cantidad => double.tryParse(_cantidadCtrl.text.replaceAll(RegExp(r'[^\d.]'), '')) ?? 0.0;
  
  double get _totalKilosOUunidades {
    switch (widget.initialType) {
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
  double get _ivaPct => widget.initialType == InventoryItemType.concentrado ? 0.05 : 0.0;
  double get _valorIva => _subtotalBruto * _ivaPct;
  double get _subtotalFactura => _subtotalBruto + _valorIva;
  double get _granTotalPuestoEnGranja => _subtotalFactura + _fleteTransporte;
  double get _costoRealPorUnidad => _totalKilosOUunidades > 0 ? (_granTotalPuestoEnGranja / _totalKilosOUunidades) : 0.0;
  double get _fletePorUnidad => _totalKilosOUunidades > 0 ? (_fleteTransporte / _totalKilosOUunidades) : 0.0;

  String get _unidadMedidaLabel {
    switch (widget.initialType) {
      case InventoryItemType.concentrado:
        return 'BULTOS';
      case InventoryItemType.insumo:
        return 'SACOS / CANECAS';
      case InventoryItemType.alevino:
        return 'MILLARES / UNID.';
      case InventoryItemType.oxigenador:
        return 'EQUIPOS (UNIDADES)';
      case InventoryItemType.farmacia:
        return 'FRASCOS / BOLSAS';
      case InventoryItemType.herramienta:
        return 'UNIDADES';
    }
  }

  String get _presentacionFinal {
    switch (widget.initialType) {
      case InventoryItemType.concentrado:
        return 'Bulto ${_kgPorBulto.toStringAsFixed(0)} Kg';
      case InventoryItemType.insumo:
        return _presentacionInsumo;
      case InventoryItemType.alevino:
        return 'Millar Alevinos (${_pesoPromedioCtrl.text}g)';
      case InventoryItemType.oxigenador:
        return 'Motor ${_potenciaHp}HP $_faseElectrica';
      case InventoryItemType.farmacia:
        return 'Presentación Farmacéutica';
      case InventoryItemType.herramienta:
        return 'Unidad';
    }
  }

  Future<void> _guardarItem() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedProduct == null || _selectedProduct!.isEmpty) return;

    final auth = ref.read(authProvider);
    final empresaId = auth.currentUser?.empresaId ?? 'c1000000-0000-0000-0000-000000000001';
    final unitId = auth.activeUnitId;

    final item = InventoryItem(
      id: const Uuid().v4(),
      empresaId: empresaId,
      unidadAcuicolaId: unitId,
      tipo: widget.initialType,
      nombre: _selectedProduct!,
      marcaProveedor: _selectedSupplier,
      presentacionUnidad: _presentacionFinal,
      cantidadOriginalKg: _totalKilosOUunidades,
      cantidadActualKg: _totalKilosOUunidades,
      costoUnitarioHistorico: _costoRealPorUnidad,
      costoTotal: _granTotalPuestoEnGranja,
      stockMinimoAlerta: widget.initialType == InventoryItemType.concentrado ? 400.0 : (widget.initialType == InventoryItemType.insumo ? 100.0 : 2.0),
      proteinaCrudaPct: widget.initialType == InventoryItemType.concentrado ? _proteinaCruda : null,
      principioActivo: widget.initialType == InventoryItemType.farmacia ? _principioActivoCtrl.text.trim() : null,
      diasRetiroSanitario: widget.initialType == InventoryItemType.farmacia ? _diasRetiroSanitario : null,
      potenciaHp: widget.initialType == InventoryItemType.oxigenador ? _potenciaHp : null,
      faseElectrica: widget.initialType == InventoryItemType.oxigenador ? _faseElectrica : null,
      especieAlevino: widget.initialType == InventoryItemType.alevino ? _especieAlevino : null,
      loteFabricante: _loteCtrl.text.trim().isNotEmpty ? _loteCtrl.text.trim() : null,
      fechaVencimiento: _fechaVencimiento,
      creadoEn: DateTime.now(),
    );

    final messenger = ScaffoldMessenger.of(context);
    final nav = Navigator.of(context);

    await ref.read(warehouseProvider.notifier).addInventory(item);

    if (mounted) {
      nav.pop();
      messenger.showSnackBar(
        SnackBar(
          content: Text('${InventoryItem.typeToString(widget.initialType)} "${item.nombre}" registrado exitosamente en Bodega.'),
          backgroundColor: AppColors.greenBiomass,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(warehouseProvider);
    final suppliers = state.suppliers.where((s) => s.categoriaPrincipal == _categoryKey).toList();

    // Inicializar proveedor por defecto
    if (_selectedSupplier == null && suppliers.isNotEmpty) {
      _selectedSupplier = suppliers.first.nombre;
      if (suppliers.first.productosOfrecidos.isNotEmpty) {
        _onProductSelected(suppliers.first.productosOfrecidos.first);
      }
    }

    final currentSupplierObj = suppliers.firstWhere(
      (s) => s.nombre == _selectedSupplier,
      orElse: () => suppliers.isNotEmpty ? suppliers.first : const Supplier(id: '1', nit: '', nombre: 'Proveedor Oficial', categoriaPrincipal: 'concentrados', productosOfrecidos: []),
    );
    final availableProducts = currentSupplierObj.productosOfrecidos;

    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Configuración estética por tipo
    final (headerTitle, headerSubtitle, headerIcon, headerColor) = switch (widget.initialType) {
      InventoryItemType.concentrado => ('Nuevo Alimento en Bodega', 'Portafolio Oficial y Liquidación Factura', Icons.inventory_2_rounded, AppColors.cyanWater),
      InventoryItemType.farmacia => ('Nuevo Fármaco en Bodega', 'Registro de Principio Activo y Retiro ICA', Icons.medical_services_rounded, AppColors.coralAction),
      InventoryItemType.insumo => ('Nuevo Insumo Acuícola', 'Sal, Cal, Melaza y Probióticos', Icons.science_rounded, AppColors.amberWarning),
      InventoryItemType.oxigenador => ('Nuevo Oxigenador / Equipo', 'Motores, Blowers y Aireación', Icons.air_rounded, AppColors.cyanWater),
      InventoryItemType.alevino => ('Ingreso de Lote de Alevinos', 'Siembra de Semilla y Biometría Inicial', Icons.set_meal_rounded, AppColors.greenBiomass),
      InventoryItemType.herramienta => ('Nueva Herramienta / Activo', 'Control de Equipos y Mantenimiento', Icons.build_rounded, AppColors.amberWarning),
    };

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 540),
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
                  // Título
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
                              Text(headerTitle, style: AppTypography.titleLarge.copyWith(color: headerColor, fontSize: 17, fontWeight: FontWeight.w800)),
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
                  const SizedBox(height: 16),

                  // 1. Selector de Fabricante / Proveedor Oficial
                  Text('PROVEEDOR / FABRICANTE OFICIAL', style: AppTypography.labelMicro.copyWith(color: AppColors.textSecondaryDark, fontWeight: FontWeight.w700)),
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
                        icon: Icon(Icons.keyboard_arrow_down_rounded, color: headerColor),
                        items: suppliers.map((s) {
                          return DropdownMenuItem(
                            value: s.nombre,
                            child: Row(
                              children: [
                                Icon(Icons.factory_outlined, size: 16, color: headerColor),
                                const SizedBox(width: 8),
                                Expanded(child: Text(s.nombre, style: TextStyle(color: isDark ? Colors.white : AppColors.textPrimaryLight, fontSize: 13, fontWeight: FontWeight.w700), overflow: TextOverflow.ellipsis)),
                                const SizedBox(width: 6),
                                Text('(${s.nit})', style: const TextStyle(color: AppColors.textSecondaryDark, fontSize: 11)),
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
                  const SizedBox(height: 14),

                  // 2. Referencia Oficial del Producto (Catálogo Cerrado)
                  Text('REFERENCIA / ARTÍCULO OFICIAL', style: AppTypography.labelMicro.copyWith(color: headerColor, fontWeight: FontWeight.w800)),
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
                    decoration: BoxDecoration(
                      color: isDark ? Colors.white.withValues(alpha: 0.06) : Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: headerColor.withValues(alpha: 0.35)),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: availableProducts.contains(_selectedProduct) ? _selectedProduct : (availableProducts.isNotEmpty ? availableProducts.first : null),
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

                  // 3. Ficha Técnica Especializada según Categoría
                  if (widget.initialType == InventoryItemType.concentrado) ...[
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
                                    Text('PRESENTACIÓN', style: AppTypography.labelMicro.copyWith(fontSize: 9, color: AppColors.amberWarning)),
                                    Text('${_kgPorBulto.toStringAsFixed(0)} Kg / Bto', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14, color: AppColors.amberWarning)),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                  ] else if (widget.initialType == InventoryItemType.farmacia) ...[
                    Row(
                      children: [
                        Expanded(
                          flex: 3,
                          child: TextFormField(
                            controller: _principioActivoCtrl,
                            style: TextStyle(color: isDark ? Colors.white : AppColors.textPrimaryLight, fontSize: 12.5),
                            decoration: InputDecoration(
                              labelText: 'Principio Activo Farmacéutico',
                              floatingLabelBehavior: FloatingLabelBehavior.auto,
                              labelStyle: const TextStyle(color: AppColors.textSecondaryDark, fontSize: 12),
                              floatingLabelStyle: const TextStyle(color: AppColors.coralAction, fontSize: 12, fontWeight: FontWeight.w700),
                              filled: true,
                              fillColor: isDark ? Colors.white.withValues(alpha: 0.04) : Colors.white,
                              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.coralAction, width: 1.8)),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          flex: 2,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                            decoration: BoxDecoration(
                              color: AppColors.coralAction.withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: AppColors.coralAction.withValues(alpha: 0.3)),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('RETIRO ICA', style: TextStyle(color: AppColors.coralAction, fontSize: 9.5, fontWeight: FontWeight.w800)),
                                Text('$_diasRetiroSanitario días carencia', style: const TextStyle(color: AppColors.coralAction, fontWeight: FontWeight.w800, fontSize: 12.5)),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                  ] else if (widget.initialType == InventoryItemType.oxigenador) ...[
                    Row(
                      children: [
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                            decoration: BoxDecoration(
                              color: AppColors.cyanWater.withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: AppColors.cyanWater.withValues(alpha: 0.25)),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('POTENCIA MOTOR', style: TextStyle(color: AppColors.cyanWater, fontSize: 9.5, fontWeight: FontWeight.w800)),
                                Text('${_potenciaHp.toStringAsFixed(1)} HP', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14, color: AppColors.cyanWater)),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                            decoration: BoxDecoration(
                              color: AppColors.amberWarning.withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: AppColors.amberWarning.withValues(alpha: 0.25)),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('FASE ELÉCTRICA', style: TextStyle(color: AppColors.amberWarning, fontSize: 9.5, fontWeight: FontWeight.w800)),
                                Text(_faseElectrica, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 12, color: AppColors.amberWarning), overflow: TextOverflow.ellipsis),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                  ] else if (widget.initialType == InventoryItemType.alevino) ...[
                    Builder(builder: (context) {
                      final company = ref.watch(authProvider).currentCompany;
                      final availableSpecies = (company != null && company.especiesHabilitadas.isNotEmpty)
                          ? company.especiesHabilitadas
                          : ['Trucha Arcoíris', 'Tilapia Roja', 'Tilapia Nilótica', 'Cachama Blanca', 'Bocachico'];

                      return Row(
                        children: [
                          Expanded(
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                              decoration: BoxDecoration(
                                color: AppColors.greenBiomass.withValues(alpha: 0.08),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: AppColors.greenBiomass.withValues(alpha: 0.25)),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Text('ESPECIE', style: TextStyle(color: AppColors.greenBiomass, fontSize: 9.5, fontWeight: FontWeight.w800)),
                                  DropdownButtonHideUnderline(
                                    child: DropdownButton<String>(
                                      value: availableSpecies.contains(_especieAlevino) ? _especieAlevino : availableSpecies.first,
                                      isExpanded: true,
                                      dropdownColor: isDark ? const Color(0xFF1E293B) : Colors.white,
                                      icon: const Icon(Icons.arrow_drop_down_rounded, color: AppColors.greenBiomass),
                                      style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13, color: isDark ? Colors.white : AppColors.textPrimaryLight),
                                      items: availableSpecies.map((esp) {
                                        return DropdownMenuItem<String>(
                                          value: esp,
                                          child: Text(esp, overflow: TextOverflow.ellipsis),
                                        );
                                      }).toList(),
                                      onChanged: (val) {
                                        if (val != null) {
                                          setState(() => _especieAlevino = val);
                                        }
                                      },
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: TextFormField(
                              controller: _pesoPromedioCtrl,
                              keyboardType: const TextInputType.numberWithOptions(decimal: true),
                              style: TextStyle(color: isDark ? Colors.white : AppColors.textPrimaryLight, fontSize: 13, fontWeight: FontWeight.w700),
                              decoration: InputDecoration(
                                labelText: 'Peso Promedio (g)',
                                floatingLabelBehavior: FloatingLabelBehavior.auto,
                                labelStyle: const TextStyle(color: AppColors.textSecondaryDark, fontSize: 12),
                                floatingLabelStyle: const TextStyle(color: AppColors.greenBiomass, fontSize: 12, fontWeight: FontWeight.w800),
                                filled: true,
                                fillColor: isDark ? Colors.white.withValues(alpha: 0.04) : Colors.white,
                                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.greenBiomass, width: 1.8)),
                              ),
                            ),
                          ),
                        ],
                      );
                    }),
                    const SizedBox(height: 14),
                  ],

                  // 4. Cantidad y Lote
                  Row(
                    children: [
                      // Cantidad
                      Expanded(
                        flex: 3,
                        child: TextFormField(
                          controller: _cantidadCtrl,
                          keyboardType: TextInputType.number,
                          style: TextStyle(color: isDark ? Colors.white : AppColors.textPrimaryLight, fontSize: 13.5, fontWeight: FontWeight.w800),
                          decoration: InputDecoration(
                            labelText: 'Cantidad ($_unidadMedidaLabel)',
                            floatingLabelBehavior: FloatingLabelBehavior.auto,
                            labelStyle: const TextStyle(color: AppColors.textSecondaryDark, fontSize: 12, fontWeight: FontWeight.w600),
                            floatingLabelStyle: TextStyle(color: headerColor, fontSize: 12, fontWeight: FontWeight.w800),
                            filled: true,
                            fillColor: isDark ? Colors.white.withValues(alpha: 0.04) : Colors.white,
                            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: isDark ? Colors.white12 : AppColors.glassBorderLight)),
                            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: isDark ? Colors.white12 : AppColors.glassBorderLight)),
                            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: headerColor, width: 1.8)),
                          ),
                          validator: (v) => (v == null || v.trim().isEmpty) ? 'Requerido' : null,
                          onChanged: (_) => setState(() {}),
                        ),
                      ),
                      const SizedBox(width: 10),

                      // Lote del Fabricante
                      Expanded(
                        flex: 2,
                        child: TextFormField(
                          controller: _loteCtrl,
                          style: TextStyle(color: isDark ? Colors.white : AppColors.textPrimaryLight, fontSize: 13, fontWeight: FontWeight.w600),
                          decoration: InputDecoration(
                            labelText: 'Lote Fabricante',
                            floatingLabelBehavior: FloatingLabelBehavior.auto,
                            labelStyle: const TextStyle(color: AppColors.textSecondaryDark, fontSize: 12, fontWeight: FontWeight.w600),
                            floatingLabelStyle: TextStyle(color: headerColor, fontSize: 12, fontWeight: FontWeight.w800),
                            filled: true,
                            fillColor: isDark ? Colors.white.withValues(alpha: 0.04) : Colors.white,
                            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: isDark ? Colors.white12 : AppColors.glassBorderLight)),
                            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: isDark ? Colors.white12 : AppColors.glassBorderLight)),
                            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: headerColor, width: 1.8)),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),

                  // 5. Costos y Flete
                  Row(
                    children: [
                      // Costo por Unidad antes de IVA
                      Expanded(
                        flex: 3,
                        child: TextFormField(
                          controller: _costoUnitarioBrutoCtrl,
                          keyboardType: const TextInputType.numberWithOptions(decimal: false),
                          inputFormatters: [CurrencyInputFormatter()],
                          style: TextStyle(color: isDark ? Colors.white : AppColors.textPrimaryLight, fontSize: 13.5, fontWeight: FontWeight.w800),
                          decoration: InputDecoration(
                            labelText: 'Valor Unitario Bruto (\$)',
                            floatingLabelBehavior: FloatingLabelBehavior.auto,
                            labelStyle: const TextStyle(color: AppColors.textSecondaryDark, fontSize: 12, fontWeight: FontWeight.w600),
                            floatingLabelStyle: const TextStyle(color: AppColors.amberWarning, fontSize: 12, fontWeight: FontWeight.w800),
                            filled: true,
                            fillColor: isDark ? Colors.white.withValues(alpha: 0.04) : Colors.white,
                            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: isDark ? Colors.white12 : AppColors.glassBorderLight)),
                            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: isDark ? Colors.white12 : AppColors.glassBorderLight)),
                            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: AppColors.amberWarning, width: 1.8)),
                          ),
                          validator: (v) => (v == null || v.trim().isEmpty) ? 'Requerido' : null,
                          onChanged: (_) => setState(() {}),
                        ),
                      ),
                      const SizedBox(width: 10),

                      // Flete de Transporte
                      Expanded(
                        flex: 2,
                        child: TextFormField(
                          controller: _fleteCtrl,
                          keyboardType: const TextInputType.numberWithOptions(decimal: false),
                          inputFormatters: [CurrencyInputFormatter()],
                          style: TextStyle(color: isDark ? Colors.white : AppColors.textPrimaryLight, fontSize: 13, fontWeight: FontWeight.w700),
                          decoration: InputDecoration(
                            labelText: 'Flete Total (\$)',
                            floatingLabelBehavior: FloatingLabelBehavior.auto,
                            labelStyle: const TextStyle(color: AppColors.textSecondaryDark, fontSize: 12, fontWeight: FontWeight.w600),
                            floatingLabelStyle: TextStyle(color: headerColor, fontSize: 12, fontWeight: FontWeight.w800),
                            filled: true,
                            fillColor: isDark ? Colors.white.withValues(alpha: 0.04) : Colors.white,
                            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: isDark ? Colors.white12 : AppColors.glassBorderLight)),
                            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: isDark ? Colors.white12 : AppColors.glassBorderLight)),
                            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: headerColor, width: 1.8)),
                          ),
                          onChanged: (_) => setState(() {}),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // 6. Liquidación Automática de Factura y Prorrateo Puesto en Bodega
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: isDark ? Colors.white.withValues(alpha: 0.04) : Colors.black.withValues(alpha: 0.03),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: isDark ? Colors.white12 : AppColors.glassBorderLight),
                    ),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              widget.initialType == InventoryItemType.concentrado || widget.initialType == InventoryItemType.insumo
                                  ? 'Total Kilos a Ingresar:'
                                  : 'Total Unidades a Ingresar:',
                              style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondaryDark, fontWeight: FontWeight.w600),
                            ),
                            Text(
                              widget.initialType == InventoryItemType.concentrado || widget.initialType == InventoryItemType.insumo
                                  ? CurrencyFormatters.formatKg(_totalKilosOUunidades)
                                  : '${_cantidad.toInt()} Unidades',
                              style: TextStyle(color: headerColor, fontWeight: FontWeight.w800, fontSize: 13.5),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('Valor Bruto (${_cantidad.toInt()} $_unidadMedidaLabel):', style: AppTypography.labelMicro.copyWith(color: AppColors.textSecondaryDark)),
                            Text(CurrencyFormatters.formatCOP(_subtotalBruto), style: TextStyle(color: isDark ? Colors.white70 : AppColors.textPrimaryLight, fontSize: 12)),
                          ],
                        ),
                        if (_ivaPct > 0) ...[
                          const SizedBox(height: 4),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('IVA (5,00% Alimentos Balanceados):', style: AppTypography.labelMicro.copyWith(color: AppColors.amberWarning)),
                              Text('+ ${CurrencyFormatters.formatCOP(_valorIva)}', style: const TextStyle(color: AppColors.amberWarning, fontSize: 12, fontWeight: FontWeight.w700)),
                            ],
                          ),
                        ],
                        if (_fleteTransporte > 0) ...[
                          const SizedBox(height: 4),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('(+) Flete de Transporte (+${CurrencyFormatters.formatCOP(_fletePorUnidad)}/unid):', style: AppTypography.labelMicro.copyWith(color: headerColor)),
                              Text('+ ${CurrencyFormatters.formatCOP(_fleteTransporte)}', style: TextStyle(color: headerColor, fontSize: 12, fontWeight: FontWeight.w700)),
                            ],
                          ),
                        ],
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 8),
                          child: Divider(height: 1, color: Colors.white12),
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('Total Puesto en Bodega:', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 13)),
                                Text(
                                  widget.initialType == InventoryItemType.concentrado || widget.initialType == InventoryItemType.insumo
                                      ? 'Costo Real: ${CurrencyFormatters.formatCOP(_costoRealPorUnidad)} / Kg'
                                      : 'Costo Real: ${CurrencyFormatters.formatCOP(_costoRealPorUnidad)} / Unidad',
                                  style: const TextStyle(color: AppColors.greenBiomass, fontSize: 11, fontWeight: FontWeight.w700),
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
                  const SizedBox(height: 18),

                  // Botón de Acción
                  GlassButton(
                    label: 'Registrar en Bodega',
                    backgroundColor: headerColor,
                    onPressed: _guardarItem,
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

