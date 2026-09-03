import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fishbit_finance/core/design_system/app_colors.dart';
import 'package:fishbit_finance/core/design_system/app_typography.dart';
import 'package:fishbit_finance/core/design_system/fishbit_header.dart';
import 'package:fishbit_finance/core/design_system/glass_card.dart';
import 'package:fishbit_finance/core/design_system/glass_badge.dart';
import 'package:fishbit_finance/core/design_system/glass_date_picker.dart';
import 'package:fishbit_finance/core/utils/currency_formatters.dart';
import 'package:fishbit_finance/modules/warehouse_inventory/domain/models/inventory_item.dart';
import 'package:fishbit_finance/modules/warehouse_inventory/presentation/dialogs/nueva_factura_modal.dart';
import 'package:fishbit_finance/modules/warehouse_inventory/presentation/dialogs/nuevo_item_modal.dart';
import 'package:fishbit_finance/modules/warehouse_inventory/presentation/dialogs/proveedores_modal.dart';
import 'package:fishbit_finance/modules/warehouse_inventory/presentation/providers/warehouse_provider.dart';

class WarehouseScreen extends ConsumerStatefulWidget {
  const WarehouseScreen({super.key});

  @override
  ConsumerState<WarehouseScreen> createState() => _WarehouseScreenState();
}

class _WarehouseScreenState extends ConsumerState<WarehouseScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchCtrl = TextEditingController();
  Timer? _searchDebounceTimer;
  String _searchQuery = '';

  final List<Map<String, dynamic>> _tabs = [
    {'type': InventoryItemType.concentrado, 'label': 'Concentrados', 'icon': Icons.restaurant_rounded, 'color': AppColors.greenBiomass},
    {'type': InventoryItemType.insumo, 'label': 'Insumos', 'icon': Icons.science_rounded, 'color': AppColors.amberWarning},
    {'type': InventoryItemType.alevino, 'label': 'Alevinos', 'icon': Icons.set_meal_rounded, 'color': AppColors.cyanWater},
    {'type': InventoryItemType.oxigenador, 'label': 'Oxigenadores', 'icon': Icons.air_rounded, 'color': Colors.purpleAccent},
    {'type': InventoryItemType.farmacia, 'label': 'Farmacia', 'icon': Icons.medical_services_rounded, 'color': AppColors.coralAction},
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabs.length, vsync: this);
    _searchCtrl.addListener(() {
      _searchDebounceTimer?.cancel();
      _searchDebounceTimer = Timer(const Duration(milliseconds: 200), () {
        if (mounted) {
          setState(() => _searchQuery = _searchCtrl.text.trim().toLowerCase());
        }
      });
    });
  }

  @override
  void dispose() {
    _searchDebounceTimer?.cancel();
    _tabController.dispose();
    _searchCtrl.dispose();
    super.dispose();
  }

  void _showQuickEntryDialog(BuildContext context, InventoryItem item) {
    showDialog<void>(
      context: context,
      builder: (ctx) => _QuickEntryDialog(item: item),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(warehouseProvider);
    final currentTabType = _tabs[_tabController.index]['type'] as InventoryItemType;

    final filteredItems = state.items.where((item) {
      final matchesTab = item.tipo == currentTabType;
      if (!matchesTab) return false;
      if (_searchQuery.isEmpty) return true;
      final matchName = item.nombre.toLowerCase().contains(_searchQuery);
      final matchSupplier = (item.marcaProveedor ?? '').toLowerCase().contains(_searchQuery);
      return matchName || matchSupplier;
    }).toList();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final categoryKey = () {
      switch (currentTabType) {
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
    }();

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 78),
        child: FloatingActionButton.extended(
          backgroundColor: AppColors.amberWarning,
          foregroundColor: Colors.black,
          icon: const Icon(Icons.add_shopping_cart_rounded, color: Colors.black),
          label: const Text('Factura Compra', style: TextStyle(color: Colors.black, fontWeight: FontWeight.w900)),
          onPressed: () => NuevaFacturaModal.show(context, initialCategory: categoryKey),
        ),
      ),
      body: CustomScrollView(
        slivers: [
          FishBitHeader(
            onRefresh: () => ref.read(warehouseProvider.notifier).loadWarehouseData(),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Bento Grid KPIs de Almacén
                  Row(
                    children: [
                      Expanded(
                        child: GlassCard(
                          title: 'Valor Total Inventario',
                          glowColor: AppColors.amberWarning,
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            alignment: Alignment.centerLeft,
                            child: Text(
                              CurrencyFormatters.formatCOP(state.valorTotalInventario),
                              style: AppTypography.numberKpi.copyWith(color: AppColors.amberWarning, fontSize: 18),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: GlassCard(
                          title: 'Alimento en Bodega',
                          glowColor: AppColors.greenBiomass,
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            alignment: Alignment.centerLeft,
                            child: Text(
                              CurrencyFormatters.formatKg(state.totalAlimentoKg),
                              style: AppTypography.numberKpi.copyWith(color: AppColors.greenBiomass, fontSize: 18),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),

                  // Barra de Búsqueda y Acciones Rápidas
                  Row(
                    children: [
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                          decoration: BoxDecoration(
                            color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: isDark ? Colors.white.withValues(alpha: 0.1) : AppColors.glassBorderLight),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.search_rounded, color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight, size: 18),
                              const SizedBox(width: 8),
                              Expanded(
                                child: TextField(
                                  controller: _searchCtrl,
                                  style: TextStyle(color: isDark ? Colors.white : AppColors.textPrimaryLight, fontSize: 13),
                                  decoration: InputDecoration(
                                    hintText: 'Buscar por producto o marca...',
                                    hintStyle: TextStyle(color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight, fontSize: 13),
                                    border: InputBorder.none,
                                    isDense: true,
                                  ),
                                ),
                              ),
                              if (_searchQuery.isNotEmpty)
                                GestureDetector(
                                  onTap: () => _searchCtrl.clear(),
                                  child: Icon(Icons.clear_rounded, color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight, size: 16),
                                ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        tooltip: 'Directorio de Proveedores',
                        style: IconButton.styleFrom(
                          backgroundColor: isDark ? Colors.white.withValues(alpha: 0.08) : Colors.white,
                          side: BorderSide(color: isDark ? Colors.transparent : AppColors.glassBorderLight),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        icon: const Icon(Icons.store_mall_directory_rounded, color: AppColors.amberWarning),
                        onPressed: () => ProveedoresModal.show(context),
                      ),
                      const SizedBox(width: 6),
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.cyanWater,
                          foregroundColor: Colors.black,
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          elevation: 0,
                        ),
                        icon: const Icon(Icons.add, size: 16, color: Colors.black),
                        label: const Text('Nuevo Ítem', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 12.5)),
                        onPressed: () => NuevoItemModal.show(context, initialType: currentTabType),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // 5 Tabs de Navegación Especializada
                  Container(
                    decoration: BoxDecoration(
                      color: isDark ? Colors.white.withValues(alpha: 0.04) : Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: isDark ? Colors.transparent : AppColors.glassBorderLight),
                    ),
                    child: TabBar(
                      controller: _tabController,
                      isScrollable: true,
                      tabAlignment: TabAlignment.start,
                      indicatorColor: _tabs[_tabController.index]['color'] as Color,
                      indicatorWeight: 3,
                      labelColor: isDark ? Colors.white : AppColors.textPrimaryLight,
                      unselectedLabelColor: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                      onTap: (_) => setState(() {}),
                      tabs: _tabs.map((tab) {
                        final type = tab['type'] as InventoryItemType;
                        final count = state.items.where((i) => i.tipo == type).length;
                        return Tab(
                          child: Row(
                            children: [
                              Icon(tab['icon'] as IconData, size: 16, color: tab['color'] as Color),
                              const SizedBox(width: 6),
                              Text('${tab['label']} ($count)'),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Contenido de la pestaña activa
          if (filteredItems.isEmpty)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(40),
                child: Center(
                  child: Column(
                    children: [
                      Icon(Icons.inventory_2_outlined, color: AppColors.textSecondaryDark.withValues(alpha: 0.4), size: 48),
                      const SizedBox(height: 12),
                      Text(
                        'No hay artículos en esta categoría.',
                        style: AppTypography.bodyMedium.copyWith(color: AppColors.textSecondaryDark),
                      ),
                      const SizedBox(height: 8),
                      TextButton.icon(
                        icon: const Icon(Icons.add, color: AppColors.cyanWater),
                        label: const Text('Registrar Primer Ítem', style: TextStyle(color: AppColors.cyanWater)),
                        onPressed: () => NuevoItemModal.show(context, initialType: currentTabType),
                      ),
                    ],
                  ),
                ),
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final item = filteredItems[index];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _buildItemCard(context, item),
                    );
                  },
                  childCount: filteredItems.length,
                ),
              ),
            ),
          const SliverToBoxAdapter(child: SizedBox(height: 100)),
        ],
      ),
    );
  }

  Widget _buildItemCard(BuildContext context, InventoryItem item) {
    Color badgeColor;
    switch (item.tipo) {
      case InventoryItemType.concentrado:
        badgeColor = AppColors.greenBiomass;
        break;
      case InventoryItemType.insumo:
        badgeColor = AppColors.amberWarning;
        break;
      case InventoryItemType.alevino:
        badgeColor = AppColors.cyanWater;
        break;
      case InventoryItemType.oxigenador:
        badgeColor = Colors.purpleAccent;
        break;
      case InventoryItemType.farmacia:
        badgeColor = AppColors.coralAction;
        break;
      default:
        badgeColor = Colors.grey;
    }

    final isLowStock = item.isLowStock;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GlassCard(
      title: item.nombre,
      subtitle: item.marcaProveedor != null ? 'Marca / Proveedor: ${item.marcaProveedor}' : 'Almacén Acuícola',
      glowColor: isLowStock ? AppColors.coralAction : badgeColor,
      trailingWidget: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (isLowStock) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: AppColors.coralAction.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: AppColors.coralAction.withValues(alpha: 0.4)),
              ),
              child: const Row(
                children: [
                  Icon(Icons.warning_amber_rounded, color: AppColors.coralAction, size: 12),
                  SizedBox(width: 4),
                  Text('STOCK BAJO', style: TextStyle(color: AppColors.coralAction, fontSize: 9, fontWeight: FontWeight.w800)),
                ],
              ),
            ),
            const SizedBox(width: 6),
          ],
          GlassBadge(
            text: '${CurrencyFormatters.formatInt(item.cantidadActualKg.toInt())} ${item.presentacionUnidad ?? "Kg"}',
            color: badgeColor,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Especificaciones técnicas por tipo
          if (item.tipo == InventoryItemType.concentrado) ...[
            Row(
              children: [
                if (item.proteinaCrudaPct != null)
                  _buildSpecPill('${item.proteinaCrudaPct!.toStringAsFixed(0)}% Proteína (PB)', AppColors.greenBiomass),
                if (item.calibrePelletMm != null) ...[
                  const SizedBox(width: 6),
                  _buildSpecPill('Pellet: ${item.calibrePelletMm!.toStringAsFixed(1)} mm', Colors.white70),
                ],
                if (item.loteFabricante != null) ...[
                  const SizedBox(width: 6),
                  _buildSpecPill('Lote: ${item.loteFabricante}', AppColors.textSecondaryDark),
                ],
              ],
            ),
            const SizedBox(height: 8),
          ] else if (item.tipo == InventoryItemType.farmacia) ...[
            Row(
              children: [
                if (item.principioActivo != null)
                  Expanded(
                    child: Text(
                      'Principio Activo: ${item.principioActivo}',
                      style: const TextStyle(color: Colors.white70, fontSize: 11.5),
                    ),
                  ),
                if (item.diasRetiroSanitario != null && item.diasRetiroSanitario! > 0)
                  _buildSpecPill('⚠️ Retiro ICA: ${item.diasRetiroSanitario} días carencia', AppColors.coralAction)
                else
                  _buildSpecPill('Retiro: 0 días', AppColors.greenBiomass),
              ],
            ),
            const SizedBox(height: 8),
          ] else if (item.tipo == InventoryItemType.oxigenador) ...[
            Row(
              children: [
                if (item.potenciaHp != null)
                  _buildSpecPill('Potencia: ${item.potenciaHp!.toStringAsFixed(1)} HP', Colors.purpleAccent),
                if (item.faseElectrica != null) ...[
                  const SizedBox(width: 6),
                  _buildSpecPill(item.faseElectrica!, Colors.white70),
                ],
              ],
            ),
            const SizedBox(height: 8),
          ],

          // Métricas de Valor y CPP
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('COSTO PROM. PONDERADO (CPP)', style: AppTypography.labelMicro.copyWith(color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight)),
                  Text(
                    '${CurrencyFormatters.formatCOP(item.costoUnitarioHistorico)} / ${item.presentacionUnidad?.split(' ').first ?? "kg"}',
                    style: TextStyle(color: isDark ? Colors.white : AppColors.textPrimaryLight, fontSize: 13, fontWeight: FontWeight.w700),
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text('VALOR TOTAL STOCK', style: AppTypography.labelMicro.copyWith(color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight)),
                  Text(
                    CurrencyFormatters.formatCOP(item.costoTotal),
                    style: AppTypography.bodyMedium.copyWith(color: AppColors.greenBiomass, fontWeight: FontWeight.w900),
                  ),
                ],
              ),
            ],
          ),

          const SizedBox(height: 10),

          // Botón Rápido de Entrada / Ajuste
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  foregroundColor: badgeColor,
                  side: BorderSide(color: badgeColor.withValues(alpha: 0.4)),
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                icon: const Icon(Icons.add_circle_outline_rounded, size: 14),
                label: const Text('Entrada Stock', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700)),
                onPressed: () => _showQuickEntryDialog(context, item),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSpecPill(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(text, style: TextStyle(color: color, fontSize: 10.5, fontWeight: FontWeight.w700)),
    );
  }
}

class _QuickEntryDialog extends ConsumerStatefulWidget {
  final InventoryItem item;

  const _QuickEntryDialog({required this.item});

  @override
  ConsumerState<_QuickEntryDialog> createState() => _QuickEntryDialogState();
}

class _QuickEntryDialogState extends ConsumerState<_QuickEntryDialog> {
  late final TextEditingController _cantCtrl;
  late final TextEditingController _costCtrl;
  late final TextEditingController _facturaCtrl;
  late CivilDate _fechaEntrada;

  @override
  void initState() {
    super.initState();
    _cantCtrl = TextEditingController();
    _costCtrl = TextEditingController(text: widget.item.costoUnitarioHistorico.toInt().toString());
    _facturaCtrl = TextEditingController();
    _fechaEntrada = CivilDate.today();
  }

  @override
  void dispose() {
    _cantCtrl.dispose();
    _costCtrl.dispose();
    _facturaCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppColors.surfaceDark,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Row(
        children: [
          const Icon(Icons.add_box_rounded, color: AppColors.greenBiomass, size: 22),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Entrada de Stock: ${widget.item.nombre}',
              style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Stock actual: ${CurrencyFormatters.formatInt(widget.item.cantidadActualKg.toInt())} ${widget.item.presentacionUnidad ?? "Kg"}',
              style: const TextStyle(color: AppColors.textSecondaryDark, fontSize: 12),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _cantCtrl,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                labelText: 'Cantidad a Ingresar (${widget.item.presentacionUnidad ?? "Kg"})',
                labelStyle: const TextStyle(color: AppColors.cyanWater),
                filled: true,
                fillColor: Colors.white.withValues(alpha: 0.05),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _costCtrl,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                labelText: 'Precio Unitario Compra (\$ COP)',
                labelStyle: const TextStyle(color: AppColors.amberWarning),
                filled: true,
                fillColor: Colors.white.withValues(alpha: 0.05),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _facturaCtrl,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                labelText: 'No. Factura / Remisión (Opcional)',
                labelStyle: const TextStyle(color: Colors.white70),
                filled: true,
                fillColor: Colors.white.withValues(alpha: 0.05),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 10),
            GlassDatePickerField(
              label: 'FECHA DE RECEPCIÓN',
              initialDate: _fechaEntrada,
              accentColor: AppColors.greenBiomass,
              onDateChanged: (d) => setState(() => _fechaEntrada = d),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancelar', style: TextStyle(color: AppColors.textSecondaryDark)),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.greenBiomass,
            foregroundColor: Colors.black,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
          onPressed: () {
            final cant = double.tryParse(_cantCtrl.text) ?? 0.0;
            final costo = double.tryParse(_costCtrl.text) ?? widget.item.costoUnitarioHistorico;
            if (cant > 0) {
              ref.read(warehouseProvider.notifier).registerPurchaseEntry(
                itemId: widget.item.id,
                cantidadIngresada: cant,
                costoUnitarioCompra: costo,
                numeroFactura: _facturaCtrl.text.trim().isNotEmpty ? _facturaCtrl.text.trim() : null,
                proveedor: widget.item.marcaProveedor,
              );
              Navigator.of(context).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Se ingresaron $cant a ${widget.item.nombre}. Costo Promedio Ponderado recalculado.'),
                  backgroundColor: AppColors.greenBiomass,
                ),
              );
            }
          },
          child: const Text('Guardar Entrada', style: TextStyle(fontWeight: FontWeight.w800)),
        ),
      ],
    );
  }
}
