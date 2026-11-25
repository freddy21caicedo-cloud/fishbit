import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fishbit_finance/core/design_system/app_colors.dart';
import 'package:fishbit_finance/core/design_system/app_typography.dart';
import 'package:fishbit_finance/core/design_system/fade_content.dart';
import 'package:fishbit_finance/core/design_system/fishbit_header.dart';
import 'package:fishbit_finance/core/design_system/glass_card.dart';
import 'package:fishbit_finance/core/design_system/floating_dock_layout.dart';
import 'package:fishbit_finance/core/design_system/glass_badge.dart';
import 'package:fishbit_finance/core/design_system/hero_tabs.dart';
import 'package:fishbit_finance/core/design_system/app_notification.dart';
import 'package:fishbit_finance/core/utils/currency_formatters.dart';
import 'package:fishbit_finance/modules/warehouse_inventory/domain/models/inventory_item.dart';
import 'package:fishbit_finance/modules/warehouse_inventory/domain/models/purchase_invoice.dart';
import 'package:fishbit_finance/modules/warehouse_inventory/presentation/dialogs/nueva_factura_modal.dart';
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
    {'type': InventoryItemType.oxigenador, 'label': 'Aireadores', 'icon': Icons.air_rounded, 'color': Colors.purpleAccent},
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

  bool _matchesCategory(String tipoFactura, InventoryItemType type) {
    final lower = tipoFactura.trim().toLowerCase();
    return switch (type) {
      InventoryItemType.concentrado => lower == 'concentrados' || lower == 'concentrado' || lower == 'alimento',
      InventoryItemType.insumo => lower == 'insumos' || lower == 'insumo',
      InventoryItemType.alevino => lower == 'alevinos' || lower == 'alevino',
      InventoryItemType.oxigenador => lower == 'oxigenadores' || lower == 'oxigenador' || lower == 'aireadores',
      InventoryItemType.farmacia => lower == 'farmacia',
      InventoryItemType.herramienta => lower == 'herramienta' || lower == 'herramientas',
    };
  }

  Future<void> _confirmDeleteInvoice(BuildContext context, PurchaseInvoice invoice) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surfaceDark,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          'Eliminar Factura',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800),
        ),
        content: Text(
          '¿Deseas eliminar la factura ${invoice.numeroFactura} de ${invoice.proveedorNombre}? Se descontarán de bodega las cantidades ingresadas en esta factura.',
          style: const TextStyle(color: AppColors.textSecondaryDark, fontSize: 13),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancelar', style: TextStyle(color: AppColors.textSecondaryDark)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.coralAction,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Eliminar', style: TextStyle(fontWeight: FontWeight.w800)),
          ),
        ],
      ),
    );

    if (confirm != true || !context.mounted) return;
    try {
      await ref.read(warehouseProvider.notifier).deletePurchaseInvoice(invoice);
      if (context.mounted) {
        AppToast.success(context, 'Factura ${invoice.numeroFactura} eliminada y stock ajustado.');
      }
    } catch (e) {
      if (context.mounted) {
        AppToast.error(context, 'No se pudo eliminar la factura: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(warehouseProvider);
    final currentTabType = _tabs[_tabController.index]['type'] as InventoryItemType;
    final currentTabColor = _tabs[_tabController.index]['color'] as Color;

    final categoryItems = state.items.where((i) => i.tipo == currentTabType).toList();
    final filteredInvoices = state.invoices.where((inv) {
      if (!_matchesCategory(inv.tipoFactura, currentTabType)) return false;
      if (_searchQuery.isEmpty) return true;
      final matchNum = inv.numeroFactura.toLowerCase().contains(_searchQuery);
      final matchProv = inv.proveedorNombre.toLowerCase().contains(_searchQuery);
      final matchNit = inv.proveedorNit.toLowerCase().contains(_searchQuery);
      final matchProd = inv.productos.any(
        (p) =>
            p.nombre.toLowerCase().contains(_searchQuery) ||
            (p.loteFabricante ?? '').toLowerCase().contains(_searchQuery),
      );
      return matchNum || matchProv || matchNit || matchProd;
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
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          CustomScrollView(
        slivers: [
          FishBitHeader(
            onRefresh: () => ref.read(warehouseProvider.notifier).loadWarehouseData(),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: FadeContentStagger(
                stagger: const Duration(milliseconds: 90),
                spacing: 14,
                children: [
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
                                    hintText: 'Buscar por # factura, proveedor o producto...',
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
                    ],
                  ),

                  // 5 Tabs de Navegación Especializada (HeroUI v3 Tabs, estilo Bitácora sin bordes)
                  Center(
                    child: HeroTabsBar(
                      controller: _tabController,
                      borderless: true,
                      onTap: (_) => setState(() {}),
                      tabs: _tabs.map((tab) {
                        final type = tab['type'] as InventoryItemType;
                        final count = state.invoices
                            .where((inv) => _matchesCategory(inv.tipoFactura, type))
                            .length;
                        return HeroTabItem(
                          label: tab['label'] as String,
                          icon: tab['icon'] as IconData,
                          accentColor: tab['color'] as Color,
                          badgeCount: count,
                        );
                      }).toList(),
                    ),
                  ),

                  if (categoryItems.isNotEmpty)
                    _buildCategoryStockSummary(categoryItems, currentTabColor, isDark),
                ],
              ),
            ),
          ),

          // Listado detallado de Facturas de Compra de la categoría activa
          if (filteredInvoices.isEmpty)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(40),
                child: Center(
                  child: Column(
                    children: [
                      Icon(Icons.receipt_long_outlined, color: AppColors.textSecondaryDark.withValues(alpha: 0.4), size: 48),
                      const SizedBox(height: 12),
                      Text(
                        'No hay facturas registradas en esta categoría.',
                        style: AppTypography.bodyMedium.copyWith(color: AppColors.textSecondaryDark),
                      ),
                      const SizedBox(height: 8),
                      TextButton.icon(
                        icon: const Icon(Icons.add, color: AppColors.cyanWater),
                        label: const Text('Registrar Primera Factura', style: TextStyle(color: AppColors.cyanWater)),
                        onPressed: () => NuevaFacturaModal.show(context, initialCategory: categoryKey),
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
                    final invoice = filteredInvoices[index];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _buildInvoiceCard(context, invoice, currentTabColor, state.items),
                    );
                  },
                  childCount: filteredInvoices.length,
                ),
              ),
            ),
          const SliverDockBottomSpacer(),
        ],
      ),

          // Botón flotante desplegable vertical unilateral de Compras (Estilo Uiverse risabbir)
          Positioned.fill(
            child: _WarehouseVerticalSpeedDial(
              bottomOffset:
                  FloatingDockLayout.dockTopOffset(context) + FloatingDockLayout.fabDockGap,
              actions: [
                _WarehouseDialAction(
                  label: 'Concentrados',
                  icon: Icons.restaurant_rounded,
                  onTap: () {
                    _tabController.animateTo(0);
                    setState(() {});
                    NuevaFacturaModal.show(context, initialCategory: 'concentrados');
                  },
                ),
                _WarehouseDialAction(
                  label: 'Insumos',
                  icon: Icons.science_rounded,
                  onTap: () {
                    _tabController.animateTo(1);
                    setState(() {});
                    NuevaFacturaModal.show(context, initialCategory: 'insumos');
                  },
                ),
                _WarehouseDialAction(
                  label: 'Alevinos',
                  icon: Icons.set_meal_rounded,
                  onTap: () {
                    _tabController.animateTo(2);
                    setState(() {});
                    NuevaFacturaModal.show(context, initialCategory: 'alevinos');
                  },
                ),
                _WarehouseDialAction(
                  label: 'Aireadores',
                  icon: Icons.air_rounded,
                  onTap: () {
                    _tabController.animateTo(3);
                    setState(() {});
                    NuevaFacturaModal.show(context, initialCategory: 'oxigenadores');
                  },
                ),
                _WarehouseDialAction(
                  label: 'Farmacia',
                  icon: Icons.medical_services_rounded,
                  onTap: () {
                    _tabController.animateTo(4);
                    setState(() {});
                    NuevaFacturaModal.show(context, initialCategory: 'farmacia');
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryStockSummary(
    List<InventoryItem> items,
    Color accentColor,
    bool isDark,
  ) {
    final totalStock = items.fold<double>(0.0, (s, i) => s + i.cantidadActualKg);
    final totalValor = items.fold<double>(0.0, (s, i) => s + i.costoTotal);
    final lowStockCount = items.where((i) => i.isLowStock).length;
    final unitSuffix = items.first.tipo == InventoryItemType.concentrado ||
            items.first.tipo == InventoryItemType.insumo
        ? 'Kg'
        : 'unid.';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.white.withValues(alpha: 0.85),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: lowStockCount > 0
              ? AppColors.coralAction.withValues(alpha: 0.40)
              : accentColor.withValues(alpha: 0.28),
        ),
      ),
      child: Row(
        children: [
          Icon(Icons.inventory_2_rounded, size: 18, color: accentColor),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Stock disponible (${items.length} ref.): ${CurrencyFormatters.formatInt(totalStock.toInt())} $unitSuffix',
                  style: TextStyle(
                    color: isDark ? Colors.white : AppColors.textPrimaryLight,
                    fontWeight: FontWeight.w800,
                    fontSize: 12,
                  ),
                ),
                Text(
                  'Valorización en bodega: ${CurrencyFormatters.formatCOP(totalValor)}',
                  style: AppTypography.labelMicro.copyWith(
                    color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                  ),
                ),
              ],
            ),
          ),
          if (lowStockCount > 0)
            GlassBadge(
              text: '$lowStockCount STOCK BAJO',
              color: AppColors.coralAction,
            ),
        ],
      ),
    );
  }

  Widget _buildInvoiceCard(
    BuildContext context,
    PurchaseInvoice inv,
    Color badgeColor,
    List<InventoryItem> inventoryItems,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final expDate =
        '${inv.fechaExpedicion.day.toString().padLeft(2, '0')}/${inv.fechaExpedicion.month.toString().padLeft(2, '0')}/${inv.fechaExpedicion.year}';
    final vencDate =
        '${inv.fechaVencimiento.day.toString().padLeft(2, '0')}/${inv.fechaVencimiento.month.toString().padLeft(2, '0')}/${inv.fechaVencimiento.year}';
    final bool isAlevinoInvoice = _matchesCategory(inv.tipoFactura, InventoryItemType.alevino);

    double? alevinosEnBodega;
    if (isAlevinoInvoice && inv.productos.isNotEmpty) {
      double totalDisp = 0.0;
      for (final line in inv.productos) {
        final match = inventoryItems.where(
          (i) =>
              i.tipo == InventoryItemType.alevino &&
              i.nombre.trim().toLowerCase() == line.nombre.trim().toLowerCase(),
        );
        for (final item in match) {
          totalDisp += item.cantidadActualKg;
        }
      }
      alevinosEnBodega = totalDisp;
    }

    return GlassCard(
      title: '${inv.numeroFactura} • ${inv.proveedorNombre}',
      subtitle: 'NIT: ${inv.proveedorNit} • Exp: $expDate • Venc: $vencDate',
      glowColor: badgeColor,
      trailingWidget: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          GlassBadge(
            text: inv.esCredito ? 'CRÉDITO (${inv.estadoPago.toUpperCase()})' : 'CONTADO',
            color: inv.esCredito ? AppColors.amberWarning : AppColors.greenBiomass,
          ),
          const SizedBox(width: 4),
          IconButton(
            tooltip: 'Editar factura',
            visualDensity: VisualDensity.compact,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 30, minHeight: 30),
            icon: const Icon(Icons.edit_outlined, color: AppColors.cyanWater, size: 18),
            onPressed: () => NuevaFacturaModal.show(context, invoiceToEdit: inv),
          ),
          IconButton(
            tooltip: 'Eliminar factura',
            visualDensity: VisualDensity.compact,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 30, minHeight: 30),
            icon: const Icon(Icons.delete_outline_rounded, color: AppColors.coralAction, size: 18),
            onPressed: () => _confirmDeleteInvoice(context, inv),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (alevinosEnBodega != null) ...[
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  GlassBadge(
                    text: alevinosEnBodega <= 0
                        ? 'SEMBRADA / AGOTADA'
                        : 'EN BODEGA • ${CurrencyFormatters.formatInt(alevinosEnBodega.toInt())} PCS',
                    color: alevinosEnBodega <= 0 ? AppColors.cyanWater : AppColors.greenBiomass,
                  ),
                  if (alevinosEnBodega <= 0) ...[
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Factura conservada en historial contable',
                        style: AppTypography.labelMicro.copyWith(
                          color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                          fontSize: 10,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
          ...inv.productos.map((line) {
            return Container(
              margin: const EdgeInsets.only(bottom: 6),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.04)
                    : Colors.black.withValues(alpha: 0.03),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: isDark ? Colors.white10 : AppColors.glassBorderLight,
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          line.nombre,
                          style: TextStyle(
                            color: isDark ? Colors.white : AppColors.textPrimaryLight,
                            fontWeight: FontWeight.w700,
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${line.cantidadBultos} × ${line.kgPorBulto.toStringAsFixed(0)} (${CurrencyFormatters.formatInt(line.kilosTotales.toInt())}) • Vlr/u: ${CurrencyFormatters.formatCOP(line.valorUnitarioBulto)} • IVA ${line.ivaPct.toStringAsFixed(0)}%${line.loteFabricante != null ? " • Lote: ${line.loteFabricante}" : ""}',
                          style: AppTypography.labelMicro.copyWith(
                            color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                            fontSize: 10,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    CurrencyFormatters.formatCOP(line.valorTotal),
                    style: TextStyle(
                      color: isDark ? Colors.white : AppColors.textPrimaryLight,
                      fontWeight: FontWeight.w800,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            );
          }),

          const SizedBox(height: 6),
          const Divider(height: 1, color: Colors.white12),
          const SizedBox(height: 8),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Wrap(
                  spacing: 12,
                  runSpacing: 4,
                  children: [
                    Text(
                      'Neto: ${CurrencyFormatters.formatCOP(inv.totalNeto)}',
                      style: AppTypography.labelMicro.copyWith(
                        color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                      ),
                    ),
                    Text(
                      'IVA: ${CurrencyFormatters.formatCOP(inv.totalIva)}',
                      style: AppTypography.labelMicro.copyWith(
                        color: AppColors.amberWarning,
                      ),
                    ),
                    if (inv.costoFlete > 0)
                      Text(
                        'Flete: ${CurrencyFormatters.formatCOP(inv.costoFlete)}${inv.placaVehiculo != null ? " (${inv.placaVehiculo})" : ""}',
                        style: AppTypography.labelMicro.copyWith(
                          color: AppColors.cyanWater,
                        ),
                      ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    'TOTAL FACTURA',
                    style: AppTypography.labelMicro.copyWith(
                      color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                      fontSize: 9,
                    ),
                  ),
                  Text(
                    CurrencyFormatters.formatCOP(inv.totalFactura),
                    style: AppTypography.bodyMedium.copyWith(
                      color: AppColors.greenBiomass,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _WarehouseDialAction {
  final String label;
  final IconData icon;
  final VoidCallback onTap;

  const _WarehouseDialAction({
    required this.label,
    required this.icon,
    required this.onTap,
  });
}

/// Speed Dial vertical unilateral hacia arriba para Registrar Compra (Estilo Uiverse risabbir).
class _WarehouseVerticalSpeedDial extends StatefulWidget {
  final double bottomOffset;
  final List<_WarehouseDialAction> actions;

  const _WarehouseVerticalSpeedDial({
    required this.bottomOffset,
    required this.actions,
  });

  @override
  State<_WarehouseVerticalSpeedDial> createState() =>
      _WarehouseVerticalSpeedDialState();
}

class _WarehouseVerticalSpeedDialState extends State<_WarehouseVerticalSpeedDial>
    with SingleTickerProviderStateMixin {
  bool _isOpen = false;
  bool _isMainHovered = false;
  int _hoveredItemIndex = -1;
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 560),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _toggle() {
    setState(() {
      _isOpen = !_isOpen;
      if (_isOpen) {
        _controller.forward();
      } else {
        _controller.reverse();
      }
    });
  }

  void _close() {
    if (!_isOpen) return;
    setState(() {
      _isOpen = false;
      _hoveredItemIndex = -1;
      _controller.reverse();
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Stack(
      clipBehavior: Clip.none,
      children: [
        if (_isOpen)
          Positioned.fill(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: _close,
              child: AnimatedOpacity(
                opacity: _isOpen ? 1.0 : 0.0,
                duration: const Duration(milliseconds: 220),
                child: Container(
                  color: Colors.black.withValues(alpha: isDark ? 0.28 : 0.10),
                ),
              ),
            ),
          ),

        ...List.generate(widget.actions.length, (index) {
          final action = widget.actions[index];
          final startInterval = (index * 0.08).clamp(0.0, 0.45);
          final endInterval = (startInterval + 0.55).clamp(0.0, 1.0);
          final springAnim = CurvedAnimation(
            parent: _controller,
            curve: Interval(
              startInterval,
              endInterval,
              curve: const Cubic(0.68, -0.55, 0.27, 1.55),
            ),
            reverseCurve: const Interval(
              0.0,
              0.7,
              curve: Curves.easeInCubic,
            ),
          );
          final opacityAnim = CurvedAnimation(
            parent: _controller,
            curve: Interval(startInterval, (startInterval + 0.35).clamp(0.0, 1.0)),
          );
          final labelOpacityAnim = CurvedAnimation(
            parent: _controller,
            curve: Interval(
              (startInterval + 0.22).clamp(0.0, 0.8),
              1.0,
              curve: Curves.easeOut,
            ),
          );

          final targetOffsetY = 76.0 + index * 60.0;
          final isHovered = _hoveredItemIndex == index;

          return AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              if (_controller.value == 0.0 && !_isOpen) {
                return const SizedBox.shrink();
              }
              final dy = targetOffsetY * springAnim.value;
              return Positioned(
                right: 24,
                bottom: widget.bottomOffset + 8 + dy,
                child: Opacity(
                  opacity: opacityAnim.value.clamp(0.0, 1.0),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Opacity(
                        opacity: labelOpacityAnim.value.clamp(0.0, 1.0),
                        child: Container(
                          margin: const EdgeInsets.only(right: 12),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            color: isDark
                                ? const Color(0xFF1F2937).withValues(alpha: 0.92)
                                : Colors.white.withValues(alpha: 0.94),
                            borderRadius: BorderRadius.circular(10),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.12),
                                blurRadius: 8,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                          child: Text(
                            action.label,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: isDark
                                  ? const Color(0xFFF3F4F6)
                                  : const Color(0xFF374151),
                            ),
                          ),
                        ),
                      ),
                      MouseRegion(
                        cursor: SystemMouseCursors.click,
                        onEnter: (_) => setState(() => _hoveredItemIndex = index),
                        onExit: (_) => setState(() => _hoveredItemIndex = -1),
                        child: GestureDetector(
                          onTap: () {
                            _close();
                            action.onTap();
                          },
                          child: AnimatedScale(
                            scale: isHovered ? 1.10 : 1.0,
                            duration: const Duration(milliseconds: 200),
                            curve: Curves.easeOutCubic,
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              width: 48,
                              height: 48,
                              decoration: BoxDecoration(
                                color: isHovered
                                    ? const Color(0xFFF3F4F6)
                                    : Colors.white,
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.16),
                                    blurRadius: 14,
                                    offset: const Offset(0, 6),
                                  ),
                                ],
                              ),
                              alignment: Alignment.center,
                              child: Icon(
                                action.icon,
                                size: 20,
                                color: isHovered
                                    ? const Color(0xFF3B82F6)
                                    : const Color(0xFF9CA3AF),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        }),

        Positioned(
          right: 16,
          bottom: widget.bottomOffset,
          child: MouseRegion(
            cursor: SystemMouseCursors.click,
            onEnter: (_) => setState(() => _isMainHovered = true),
            onExit: (_) => setState(() => _isMainHovered = false),
            child: GestureDetector(
              onTap: _toggle,
              child: AnimatedScale(
                scale: (_isMainHovered || _isOpen) ? 1.10 : 1.0,
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeOutCubic,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: (_isMainHovered || _isOpen)
                        ? const Color(0xFF2563EB)
                        : const Color(0xFF3B82F6),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF3B82F6).withValues(alpha: 0.35),
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                      ),
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.18),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  alignment: Alignment.center,
                  child: AnimatedRotation(
                    turns: _isOpen ? 0.125 : 0.0,
                    duration: const Duration(milliseconds: 500),
                    curve: Curves.easeInOut,
                    child: const Icon(
                      Icons.add_rounded,
                      size: 32,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
