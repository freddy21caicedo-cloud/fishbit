import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fishbit_finance/core/design_system/app_colors.dart';
import 'package:fishbit_finance/core/design_system/app_typography.dart';
import 'package:fishbit_finance/core/design_system/glass_container.dart';
import 'package:fishbit_finance/core/design_system/glass_badge.dart';
import 'package:fishbit_finance/core/reports/ica_official_reports_engine.dart';
import 'package:fishbit_finance/modules/auth_tenant/presentation/providers/auth_provider.dart';
import 'package:fishbit_finance/modules/ponds_batches/presentation/providers/ponds_provider.dart';
import 'package:fishbit_finance/modules/feeding_nutrition/presentation/providers/nutrition_provider.dart';
import 'package:fishbit_finance/modules/water_quality/presentation/providers/water_quality_provider.dart';
import 'package:fishbit_finance/modules/sales_harvest/presentation/providers/sales_provider.dart';
import 'package:fishbit_finance/modules/warehouse_inventory/presentation/providers/warehouse_provider.dart';

class FormatosIcaHubModal extends ConsumerStatefulWidget {
  const FormatosIcaHubModal({super.key});

  static Future<void> show(BuildContext context) {
    return showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => const FormatosIcaHubModal(),
    );
  }

  @override
  ConsumerState<FormatosIcaHubModal> createState() => _FormatosIcaHubModalState();
}

class _FormatosIcaHubModalState extends ConsumerState<FormatosIcaHubModal> {
  String _filtroCategoria = 'TODOS'; // 'TODOS', 'APP', 'BIOSEGURIDAD', 'LAB'

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final auth = ref.watch(authProvider);
    final user = auth.currentUser;
    final company = auth.currentCompany;

    final pondsState = ref.watch(pondsProvider);
    final nutritionState = ref.watch(nutritionProvider);
    final waterState = ref.watch(waterQualityProvider);
    final salesState = ref.watch(salesProvider);
    final warehouseState = ref.watch(warehouseProvider);

    final engine = IcaOfficialReportsEngine(
      companyName: company?.nombreComercial ?? company?.razonSocial ?? user?.nombre ?? 'Piscícola FishBit',
      nit: company?.nit ?? '901.445.882-1',
      unitName: 'Sede Principal',
      ponds: pondsState.ponds,
      batches: pondsState.batches,
      transfers: pondsState.transferRecords,
      mortalities: pondsState.mortalityRecords,
      feedings: nutritionState.records,
      waterParams: waterState.recentParameters,
      sales: salesState.sales,
      inventory: warehouseState.items,
    );

    final List<_FormatoItem> formatos = [
      _FormatoItem(
        codigo: 'F-01',
        titulo: 'Ingreso de Personal (Visitas y Operarios)',
        descripcion: 'Control de bioseguridad, desinfección de calzado e historial de granjas visitadas.',
        categoria: 'BIOSEGURIDAD',
        icono: Icons.badge_rounded,
        color: AppColors.cyanWater,
        onExport: () => engine.exportF01Personal(),
      ),
      _FormatoItem(
        codigo: 'F-02',
        titulo: 'Ingreso y Desinfección de Vehículos',
        descripcion: 'Control de rodiluvios, arcos de aspersión y procedencia de camiones.',
        categoria: 'BIOSEGURIDAD',
        icono: Icons.local_shipping_rounded,
        color: AppColors.amberWarning,
        onExport: () => engine.exportF02Vehiculos(),
      ),
      _FormatoItem(
        codigo: 'F-03',
        titulo: 'Registro de Necropsias y Hallazgos',
        descripcion: 'Inspección de branquias, hígado, bazo y piel con diagnóstico veterinario presuntivo.',
        categoria: 'BIOSEGURIDAD',
        icono: Icons.biotech_rounded,
        color: Colors.purpleAccent,
        onExport: () => engine.exportF03Necropsias(),
      ),
      _FormatoItem(
        codigo: 'F-04',
        titulo: 'Registro de Mortalidad y Sanidad',
        descripcion: 'Generado desde la bitácora: causas probables, peces perdidos y % de impacto.',
        categoria: 'APP',
        icono: Icons.warning_amber_rounded,
        color: AppColors.coralAction,
        onExport: () => engine.exportF04Mortalidad(),
        badgeInfo: '${pondsState.mortalityRecords.length} registros',
      ),
      _FormatoItem(
        codigo: 'F-05',
        titulo: 'Registro de Alimentación y Raciones',
        descripcion: 'Generado desde la bitácora: kg consumidos, marcas de concentrado y costos.',
        categoria: 'APP',
        icono: Icons.restaurant_rounded,
        color: AppColors.greenBiomass,
        onExport: () => engine.exportF05Alimentacion(),
        badgeInfo: '${nutritionState.records.length} registros',
      ),
      _FormatoItem(
        codigo: 'F-06',
        titulo: 'Limpieza y Desinfección de Áreas',
        descripcion: 'Protocolos en pediluvios, bodega de alimento, redes y salabardos.',
        categoria: 'BIOSEGURIDAD',
        icono: Icons.cleaning_services_rounded,
        color: AppColors.cyanWater,
        onExport: () => engine.exportF06Limpieza(),
      ),
      _FormatoItem(
        codigo: 'F-07',
        titulo: 'Tratamientos y Tiempo de Retiro',
        descripcion: 'Control de inocuidad farmacológica y días de retiro antes de la cosecha.',
        categoria: 'APP',
        icono: Icons.medical_services_rounded,
        color: AppColors.amberWarning,
        onExport: () => engine.exportF07Tratamientos(),
      ),
      _FormatoItem(
        codigo: 'F-08',
        titulo: 'Inventario Semestral (Siembras/Traslados)',
        descripcion: 'Reporte semestral obligatorio ICA: biomasa por estanque, densidades y desdobles.',
        categoria: 'APP',
        icono: Icons.inventory_2_rounded,
        color: AppColors.greenBiomass,
        onExport: () => engine.exportF08InventarioSemestral(),
        isDestacado: true,
      ),
      _FormatoItem(
        codigo: 'F-09',
        titulo: 'Registro de Parámetros de Calidad de Agua',
        descripcion: 'Oxígeno, pH, temperatura, amonio, nitritos, alcalinidad y dureza.',
        categoria: 'APP',
        icono: Icons.water_drop_rounded,
        color: AppColors.cyanWater,
        onExport: () => engine.exportF09ParametrosAgua(),
        badgeInfo: '${waterState.recentParameters.length} registros',
      ),
      _FormatoItem(
        codigo: 'F-10',
        titulo: 'Registro de Cosechas, Ventas y Guías',
        descripcion: 'Registro de kilogramos cosechados, cliente, precio y cumplimiento de retiro.',
        categoria: 'APP',
        icono: Icons.point_of_sale_rounded,
        color: AppColors.greenBiomass,
        onExport: () => engine.exportF10CosechasVentas(),
        badgeInfo: '${salesState.sales.length} ventas',
      ),
      _FormatoItem(
        codigo: 'F-11',
        titulo: 'Trazabilidad de Material Genético',
        descripcion: 'Origen de alevinos, proveedor con registro ICA y certificados de sanidad.',
        categoria: 'BIOSEGURIDAD',
        icono: Icons.diversity_2_rounded,
        color: Colors.purpleAccent,
        onExport: () => engine.exportF11MaterialGenetico(),
      ),
      _FormatoItem(
        codigo: 'F-12',
        titulo: 'Monitoreo Semestral (IPN, TiLV, Histopatología)',
        descripcion: 'Vigilancia de enfermedades de control oficial: IPN (trucha), TiLV (tilapia) e Histopatología.',
        categoria: 'LAB',
        icono: Icons.health_and_safety_rounded,
        color: AppColors.coralAction,
        onExport: () => engine.exportF12MonitoreoPatogenos(),
        isDestacado: true,
      ),
    ];

    final filtered = _filtroCategoria == 'TODOS'
        ? formatos
        : formatos.where((f) => f.categoria == _filtroCategoria).toList();

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 820, maxHeight: 780),
        child: GlassContainer(
          borderRadius: 24,
          padding: const EdgeInsets.all(20),
          blur: 24,
          opacity: isDark ? 0.22 : 0.95,
          borderColor: isDark ? Colors.white.withValues(alpha: 0.18) : AppColors.glassBorderLight,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Cabecera Modal
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.greenBiomass.withValues(alpha: isDark ? 0.2 : 0.12),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: AppColors.greenBiomass.withValues(alpha: 0.3)),
                    ),
                    child: const Icon(Icons.verified_user_rounded, color: AppColors.greenBiomass, size: 24),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Centro de Formatos Oficiales ICA / AUNAP',
                          style: AppTypography.titleMedium.copyWith(
                            color: isDark ? Colors.white : AppColors.textPrimaryLight,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        Text(
                          '12 Formatos de Diligenciamiento y Exportación para Auditoría de Bioseguridad',
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
              const SizedBox(height: 14),

              // Barra de Filtros y Botón Paquete Completo
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Wrap(
                    spacing: 6,
                    children: [
                      _buildCatChip('TODOS', 'Todos (12)', isDark),
                      _buildCatChip('APP', 'Datos de App (6)', isDark),
                      _buildCatChip('BIOSEGURIDAD', 'Bioseguridad (4)', isDark),
                      _buildCatChip('LAB', 'Laboratorio (2)', isDark),
                    ],
                  ),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.greenBiomass,
                      foregroundColor: Colors.black,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                    icon: const Icon(Icons.cloud_download_rounded, size: 16),
                    label: const Text('Descargar Todo (ZIP/CSV)', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 11.5)),
                    onPressed: () {
                      engine.exportCuadernoCampoCompleto();
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('📦 Paquete oficial ICA generado y descargado exitosamente'),
                          backgroundColor: AppColors.greenBiomass,
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    },
                  ),
                ],
              ),
              const SizedBox(height: 14),

              // Grid de Formatos
              Expanded(
                child: ListView.builder(
                  physics: const BouncingScrollPhysics(),
                  itemCount: filtered.length,
                  itemBuilder: (context, idx) {
                    final item = filtered[idx];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: isDark ? Colors.white.withValues(alpha: 0.04) : Colors.white,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: item.isDestacado
                                ? AppColors.greenBiomass.withValues(alpha: 0.4)
                                : (isDark ? Colors.white10 : AppColors.glassBorderLight),
                            width: item.isDestacado ? 1.4 : 1.0,
                          ),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 36,
                              height: 36,
                              decoration: BoxDecoration(
                                color: item.color.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Center(
                                child: Text(
                                  item.codigo,
                                  style: TextStyle(color: item.color, fontWeight: FontWeight.w900, fontSize: 11),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          item.titulo,
                                          style: TextStyle(
                                            color: isDark ? Colors.white : AppColors.textPrimaryLight,
                                            fontWeight: FontWeight.w700,
                                            fontSize: 12.5,
                                          ),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      if (item.badgeInfo != null) ...[
                                        const SizedBox(width: 6),
                                        GlassBadge(text: item.badgeInfo!, color: AppColors.cyanWater),
                                      ],
                                      if (item.isDestacado) ...[
                                        const SizedBox(width: 6),
                                        const GlassBadge(text: 'OBLIGATORIO', color: AppColors.greenBiomass),
                                      ],
                                    ],
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    item.descripcion,
                                    style: TextStyle(
                                      color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                                      fontSize: 10.5,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            IconButton(
                              tooltip: 'Descargar Formato Excel/CSV',
                              style: IconButton.styleFrom(
                                backgroundColor: item.color.withValues(alpha: 0.12),
                                foregroundColor: item.color,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              ),
                              icon: const Icon(Icons.download_rounded, size: 18),
                              onPressed: () {
                                item.onExport();
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('📄 Formato ${item.codigo} descargado'),
                                    backgroundColor: item.color,
                                    behavior: SnackBarBehavior.floating,
                                    duration: const Duration(seconds: 2),
                                  ),
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCatChip(String key, String label, bool isDark) {
    final isSelected = _filtroCategoria == key;
    return InkWell(
      onTap: () => setState(() => _filtroCategoria = key),
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.cyanWater.withValues(alpha: isDark ? 0.25 : 0.18)
              : (isDark ? Colors.black26 : Colors.black.withValues(alpha: 0.04)),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? AppColors.cyanWater : (isDark ? Colors.white10 : AppColors.glassBorderLight),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? AppColors.cyanWater : (isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight),
            fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
            fontSize: 11,
          ),
        ),
      ),
    );
  }
}

class _FormatoItem {
  final String codigo;
  final String titulo;
  final String descripcion;
  final String categoria;
  final IconData icono;
  final Color color;
  final VoidCallback onExport;
  final String? badgeInfo;
  final bool isDestacado;

  _FormatoItem({
    required this.codigo,
    required this.titulo,
    required this.descripcion,
    required this.categoria,
    required this.icono,
    required this.color,
    required this.onExport,
    this.badgeInfo,
    this.isDestacado = false,
  });
}
