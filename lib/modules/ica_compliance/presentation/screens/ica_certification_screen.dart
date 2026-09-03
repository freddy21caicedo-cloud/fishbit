import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fishbit_finance/core/design_system/app_colors.dart';
import 'package:fishbit_finance/core/design_system/app_typography.dart';
import 'package:fishbit_finance/core/design_system/fishbit_header.dart';
import 'package:fishbit_finance/core/design_system/glass_card.dart';
import 'package:fishbit_finance/core/design_system/glass_container.dart';
import 'package:fishbit_finance/core/design_system/glass_badge.dart';
import 'package:fishbit_finance/core/reports/ica_official_reports_engine.dart';
import 'package:fishbit_finance/modules/ponds_batches/presentation/providers/ponds_provider.dart';
import 'package:fishbit_finance/modules/feeding_nutrition/presentation/providers/nutrition_provider.dart';
import 'package:fishbit_finance/modules/water_quality/presentation/providers/water_quality_provider.dart';
import 'package:fishbit_finance/modules/sales_harvest/presentation/providers/sales_provider.dart';
import 'package:fishbit_finance/modules/ica_compliance/presentation/providers/ica_compliance_provider.dart';

// Modales interactivos de diligenciamiento exclusivo de Bioseguridad y Sanidad
import 'package:fishbit_finance/modules/ica_compliance/presentation/dialogs/ica_biosecurity_modals.dart';

class IcaCertificationScreen extends ConsumerStatefulWidget {
  const IcaCertificationScreen({super.key});

  @override
  ConsumerState<IcaCertificationScreen> createState() => _IcaCertificationScreenState();
}

class _IcaCertificationScreenState extends ConsumerState<IcaCertificationScreen> with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  String _filtroFormato = 'TODOS';
  int _semestreSeleccionado = 2;
  int _anioSeleccionado = DateTime.now().year;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final engine = ref.watch(icaReportsEngineProvider);
    final pondsState = ref.watch(pondsProvider);
    final nutritionState = ref.watch(nutritionProvider);
    final waterState = ref.watch(waterQualityProvider);
    final salesState = ref.watch(salesProvider);
    final icaState = ref.watch(icaComplianceProvider);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) => [
          FishBitHeader(
            onRefresh: () {
              ref.read(waterQualityProvider.notifier).loadParameters();
              ref.read(nutritionProvider.notifier).loadData();
              ref.read(pondsProvider.notifier).loadPondsAndBatches();
              ref.read(icaComplianceProvider.notifier).loadAllRecords();
            },
          ),
          SliverToBoxAdapter(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1024),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Banner Superior Adaptable Responsive
                      GlassContainer(
                        borderRadius: 22,
                        padding: const EdgeInsets.all(16),
                        blur: 20,
                        opacity: isDark ? 0.16 : 0.94,
                        borderColor: AppColors.cyanWater.withValues(alpha: 0.35),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: AppColors.cyanWater.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(color: AppColors.cyanWater.withValues(alpha: 0.3)),
                              ),
                              child: const Icon(Icons.verified_user_rounded, color: AppColors.cyanWater, size: 24),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Wrap(
                                    crossAxisAlignment: WrapCrossAlignment.center,
                                    spacing: 8,
                                    runSpacing: 4,
                                    children: [
                                      Text(
                                        'Certificación y Normativa ICA',
                                        style: AppTypography.titleMedium.copyWith(
                                          color: isDark ? Colors.white : AppColors.textPrimaryLight,
                                          fontWeight: FontWeight.w900,
                                        ),
                                      ),
                                      const GlassBadge(text: 'RES. ICA 20186', color: AppColors.greenBiomass),
                                    ],
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    '12 Formatos Oficiales • Inventarios Semestrales • Trazabilidad Biosegura',
                                    style: AppTypography.labelMicro.copyWith(
                                      color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Barra de Pestañas
                      TabBar(
                        controller: _tabController,
                        isScrollable: true,
                        tabAlignment: TabAlignment.start,
                        indicatorColor: AppColors.cyanWater,
                        indicatorWeight: 3,
                        labelColor: isDark ? Colors.white : AppColors.textPrimaryLight,
                        unselectedLabelColor: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                        labelStyle: AppTypography.titleSmall.copyWith(fontWeight: FontWeight.w800),
                        unselectedLabelStyle: AppTypography.titleSmall.copyWith(fontWeight: FontWeight.w600),
                        tabs: const [
                          Tab(text: '📄 12 Formatos & Excel'),
                          Tab(text: '📋 Checklist Res. 20186'),
                          Tab(text: '💊 Inocuidad y Retiro'),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
        body: TabBarView(
          controller: _tabController,
          children: [
            _buildFormatosTab(context, engine, pondsState, nutritionState, waterState, salesState, icaState, isDark),
            _buildChecklistTab(context, isDark),
            _buildInocuidadTab(context, pondsState, isDark),
          ],
        ),
      ),
    );
  }

  // -------------------------------------------------------------
  // TAB 1: 12 Formatos Oficiales (Diligenciamiento + Excel)
  // -------------------------------------------------------------
  Widget _buildFormatosTab(
    BuildContext context,
    IcaOfficialReportsEngine engine,
    PondsState pondsState,
    NutritionState nutritionState,
    WaterQualityState waterState,
    SalesState salesState,
    IcaComplianceState icaState,
    bool isDark,
  ) {
    final List<_FormatoCardData> formatos = [
      _FormatoCardData(
        codigo: 'F-01',
        titulo: 'Ingreso de Personal (Visitas/Operarios)',
        descripcion: 'Control de acceso, 72h epidemiológico, pediluvio y responsabilidades.',
        categoria: 'BIOSEGURIDAD',
        icono: Icons.badge_rounded,
        color: AppColors.cyanWater,
        onExport: () => engine.exportF01Personal(),
        onDiligenciar: () => IngresoPersonalModal.show(context),
        badgeInfo: '${icaState.personalRecords.length} registrados',
        esDiligenciableEnIca: true,
      ),
      _FormatoCardData(
        codigo: 'F-02',
        titulo: 'Ingreso y Desinfección de Vehículos',
        descripcion: 'Control de rodiluvios, arcos de aspersión, productos químicos y placas.',
        categoria: 'BIOSEGURIDAD',
        icono: Icons.local_shipping_rounded,
        color: AppColors.amberWarning,
        onExport: () => engine.exportF02Vehiculos(),
        onDiligenciar: () => IngresoVehiculoModal.show(context),
        badgeInfo: '${icaState.vehiculoRecords.length} desinfecciones',
        esDiligenciableEnIca: true,
      ),
      _FormatoCardData(
        codigo: 'F-03',
        titulo: 'Registro de Necropsias y Hallazgos',
        descripcion: 'Evaluación de branquias, hígado, bazo, diagnóstico y M.V. responsable.',
        categoria: 'BIOSEGURIDAD',
        icono: Icons.biotech_rounded,
        color: Colors.purpleAccent,
        onExport: () => engine.exportF03Necropsias(),
        onDiligenciar: () => NecropsiaModal.show(context),
        badgeInfo: '${icaState.necropsiaRecords.length} necropsias',
        esDiligenciableEnIca: true,
      ),
      _FormatoCardData(
        codigo: 'F-04',
        titulo: 'Registro de Mortalidad y Sanidad',
        descripcion: 'Sincronizado desde Bitácora: causas probables, biomasa perdida e impacto.',
        categoria: 'PRODUCCION',
        icono: Icons.warning_amber_rounded,
        color: AppColors.coralAction,
        onExport: () => engine.exportF04Mortalidad(),
        badgeInfo: '${pondsState.mortalityRecords.length} bajas sincronizadas',
        esDiligenciableEnIca: false,
      ),
      _FormatoCardData(
        codigo: 'F-05',
        titulo: 'Registro de Alimentación Diaria',
        descripcion: 'Sincronizado desde Bitácora/Nutrición: Kg suministrados, raciones y FCR.',
        categoria: 'PRODUCCION',
        icono: Icons.restaurant_rounded,
        color: AppColors.greenBiomass,
        onExport: () => engine.exportF05Alimentacion(),
        badgeInfo: '${nutritionState.records.length} raciones al día',
        esDiligenciableEnIca: false,
      ),
      _FormatoCardData(
        codigo: 'F-06',
        titulo: 'Limpieza y Desinfección de Áreas',
        descripcion: 'Protocolos en pediluvios, bodegas de alimento, redes y salabardos.',
        categoria: 'BIOSEGURIDAD',
        icono: Icons.cleaning_services_rounded,
        color: AppColors.cyanWater,
        onExport: () => engine.exportF06Limpieza(),
        onDiligenciar: () => IngresoPersonalModal.show(context),
        esDiligenciableEnIca: true,
      ),
      _FormatoCardData(
        codigo: 'F-07',
        titulo: 'Tratamientos y Tiempo de Retiro',
        descripcion: 'Control de inocuidad farmacológica y días de carencia antes de cosecha.',
        categoria: 'PRODUCCION',
        icono: Icons.medical_services_rounded,
        color: AppColors.amberWarning,
        onExport: () => engine.exportF07Tratamientos(),
        badgeInfo: 'Monitoreo activo',
        esDiligenciableEnIca: false,
      ),
      _FormatoCardData(
        codigo: 'F-08',
        titulo: 'Inventario Semestral Consolidado',
        descripcion: 'Balance biológico oficial ICA: siembras, traslados, bajas y cosecha.',
        categoria: 'PRODUCCION',
        icono: Icons.inventory_2_rounded,
        color: AppColors.greenBiomass,
        onExport: () => engine.exportF08InventarioSemestral(semestre: _semestreSeleccionado, anio: _anioSeleccionado),
        badgeInfo: '${pondsState.batches.length} lotes analizados',
        isDestacado: true,
        esDiligenciableEnIca: false,
      ),
      _FormatoCardData(
        codigo: 'F-09',
        titulo: 'Parámetros de Calidad de Agua',
        descripcion: 'Sincronizado desde Calidad de Agua: 11 parámetros y estado sanitario.',
        categoria: 'PRODUCCION',
        icono: Icons.water_drop_rounded,
        color: AppColors.cyanWater,
        onExport: () => engine.exportF09ParametrosAgua(),
        badgeInfo: '${waterState.recentParameters.length} lecturas en vivo',
        esDiligenciableEnIca: false,
      ),
      _FormatoCardData(
        codigo: 'F-10',
        titulo: 'Cosechas, Ventas y Guías ICA',
        descripcion: 'Sincronizado desde Ventas: Kilos cosechados, clientes y trazabilidad.',
        categoria: 'PRODUCCION',
        icono: Icons.point_of_sale_rounded,
        color: AppColors.greenBiomass,
        onExport: () => engine.exportF10CosechasVentas(),
        badgeInfo: '${salesState.sales.length} despachos',
        esDiligenciableEnIca: false,
      ),
      _FormatoCardData(
        codigo: 'F-11',
        titulo: 'Trazabilidad de Material Genético',
        descripcion: 'Origen de alevinos, proveedor con registro ICA y guías de movilización.',
        categoria: 'BIOSEGURIDAD',
        icono: Icons.diversity_2_rounded,
        color: Colors.purpleAccent,
        onExport: () => engine.exportF11MaterialGenetico(),
        esDiligenciableEnIca: false,
      ),
      _FormatoCardData(
        codigo: 'F-12',
        titulo: 'Monitoreo Patógenos Oficiales',
        descripcion: 'Vigilancia de TiLV, IPN, ISAV y bacterias en laboratorios autorizados.',
        categoria: 'LAB',
        icono: Icons.health_and_safety_rounded,
        color: AppColors.coralAction,
        onExport: () => engine.exportF12MonitoreoPatogenos(),
        isDestacado: true,
        esDiligenciableEnIca: false,
      ),
    ];

    final filtered = _filtroFormato == 'TODOS'
        ? formatos
        : formatos.where((f) => f.categoria == _filtroFormato).toList();

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1024),
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Card Destacada: Generador de Inventario Semestral Oficial ICA (F-08)
            GlassCard(
              borderRadius: 20,
              glowColor: AppColors.cyanWater,
              title: 'GENERADOR DE INVENTARIO SEMESTRAL OFICIAL ICA (F-08)',
              trailingWidget: const GlassBadge(text: 'BALANCE BIOLÓGICO', color: AppColors.cyanWater),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Genera el balance semestral consolidado exigido por el ICA: Población inicial + Siembras + Entradas - Bajas - Cosechas = Población Final y Densidad de Carga (Kg/m³).',
                    style: TextStyle(
                      color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                      fontSize: 12,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(
                        child: DropdownButtonFormField<int>(
                          initialValue: _semestreSeleccionado,
                          decoration: InputDecoration(
                            labelText: 'Periodo Semestral',
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                          ),
                          items: const [
                            DropdownMenuItem(value: 1, child: Text('Semestre I (Ene - Jun)')),
                            DropdownMenuItem(value: 2, child: Text('Semestre II (Jul - Dic)')),
                          ],
                          onChanged: (v) => setState(() => _semestreSeleccionado = v ?? 2),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: DropdownButtonFormField<int>(
                          initialValue: _anioSeleccionado,
                          decoration: InputDecoration(
                            labelText: 'Año Fiscal',
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                          ),
                          items: [
                            DropdownMenuItem(value: DateTime.now().year, child: Text('${DateTime.now().year}')),
                            DropdownMenuItem(value: DateTime.now().year - 1, child: Text('${DateTime.now().year - 1}')),
                          ],
                          onChanged: (v) => setState(() => _anioSeleccionado = v ?? DateTime.now().year),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.cyanWater,
                        foregroundColor: Colors.black,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      icon: const Icon(Icons.table_view_rounded, size: 18),
                      label: Text(
                        'Descargar Balance Semestre $_semestreSeleccionado - $_anioSeleccionado en Excel',
                        style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 13),
                      ),
                      onPressed: () {
                        engine.exportF08InventarioSemestral(semestre: _semestreSeleccionado, anio: _anioSeleccionado);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('📄 Formato F-08 Inventario Semestre $_semestreSeleccionado exportado en Excel.'),
                            backgroundColor: AppColors.cyanWater,
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Card Consolidado Cuaderno de Campo
            GlassCard(
              borderRadius: 20,
              glowColor: AppColors.greenBiomass,
              title: 'CUADERNO DE CAMPO CONSOLIDADO (AUDITORÍA ICA)',
              trailingWidget: const GlassBadge(text: 'EXCEL / UTF-8 BOM', color: AppColors.greenBiomass),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Genera en un solo paso todos los registros zootécnicos y sanitarios en formato estándar legible por Microsoft Excel, garantizando cumplimiento de la Resolución ICA 20186/2016.',
                    style: TextStyle(
                      color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                      fontSize: 12,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.greenBiomass,
                        foregroundColor: Colors.black,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      icon: const Icon(Icons.file_download_rounded, size: 20),
                      label: const Text('Exportar Cuaderno de Campo Completo', style: TextStyle(fontWeight: FontWeight.w900)),
                      onPressed: () {
                        engine.exportCuadernoCampoCompleto();
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('📄 Cuaderno de Campo Consolidado descargado con éxito.'),
                            backgroundColor: AppColors.greenBiomass,
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),

            // Filtros de Formatos
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '12 FORMATOS OFICIALES ICA (${filtered.length})',
                  style: AppTypography.labelMicro.copyWith(
                    color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.1,
                  ),
                ),
                Wrap(
                  spacing: 6,
                  children: ['TODOS', 'BIOSEGURIDAD', 'PRODUCCION', 'LAB'].map((cat) {
                    final isSel = _filtroFormato == cat;
                    return ChoiceChip(
                      label: Text(cat == 'PRODUCCION' ? 'PRODUCCIÓN' : cat),
                      selected: isSel,
                      onSelected: (_) => setState(() => _filtroFormato = cat),
                      selectedColor: AppColors.cyanWater.withValues(alpha: 0.25),
                      labelStyle: TextStyle(
                        color: isSel ? AppColors.cyanWater : (isDark ? Colors.white70 : Colors.black87),
                        fontSize: 10,
                        fontWeight: isSel ? FontWeight.w800 : FontWeight.w500,
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Grid / Lista de Formatos
            LayoutBuilder(
              builder: (context, constraints) {
                final isWide = constraints.maxWidth > 650;
                return GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: isWide ? 2 : 1,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: isWide ? 1.75 : 1.6,
                  ),
                  itemCount: filtered.length,
                  itemBuilder: (context, index) {
                    final f = filtered[index];
                    return _buildFormatoCard(context, f, isDark);
                  },
                );
              },
            ),
            const SizedBox(height: 80),
          ],
        ),
      ),
    );
  }

  Widget _buildFormatoCard(BuildContext context, _FormatoCardData f, bool isDark) {
    return RepaintBoundary(
      child: Container(
        padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: f.isDestacado ? f.color.withValues(alpha: 0.6) : (isDark ? Colors.white12 : AppColors.glassBorderLight),
          width: f.isDestacado ? 1.5 : 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: f.color.withValues(alpha: 0.06),
            blurRadius: 10,
            spreadRadius: -2,
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
                  color: f.color.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  f.codigo,
                  style: TextStyle(color: f.color, fontWeight: FontWeight.w900, fontSize: 11),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  f.titulo,
                  style: TextStyle(
                    color: isDark ? Colors.white : AppColors.textPrimaryLight,
                    fontWeight: FontWeight.w800,
                    fontSize: 12.5,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (f.badgeInfo != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: isDark ? 0.08 : 0.05),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    f.badgeInfo!,
                    style: TextStyle(color: isDark ? Colors.white70 : AppColors.textSecondaryLight, fontSize: 9.5, fontWeight: FontWeight.w600),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 6),
          Expanded(
            child: Text(
              f.descripcion,
              style: TextStyle(
                color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                fontSize: 11,
                height: 1.3,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              if (f.esDiligenciableEnIca && f.onDiligenciar != null) ...[
                Expanded(
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: f.color,
                      side: BorderSide(color: f.color.withValues(alpha: 0.5)),
                      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    icon: const Icon(Icons.add_rounded, size: 14),
                    label: const FittedBox(child: Text('Nuevo Registro', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800))),
                    onPressed: f.onDiligenciar,
                  ),
                ),
                const SizedBox(width: 8),
              ],
              Expanded(
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: f.esDiligenciableEnIca ? (isDark ? Colors.white10 : Colors.black12) : f.color,
                    foregroundColor: f.esDiligenciableEnIca ? (isDark ? Colors.white : Colors.black) : Colors.black,
                    padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  icon: const Icon(Icons.file_download_outlined, size: 14),
                  label: FittedBox(
                    child: Text(
                      f.esDiligenciableEnIca ? 'Excel' : 'Exportar Excel Oficial',
                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w900),
                    ),
                  ),
                  onPressed: () {
                    f.onExport();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('📄 Formato ${f.codigo} exportado correctamente'),
                        backgroundColor: f.color,
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    ),
  );
}

  // -------------------------------------------------------------
  // TAB 2: Checklist Normativo Res. 20186
  // -------------------------------------------------------------
  Widget _buildChecklistTab(BuildContext context, bool isDark) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 900),
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            GlassCard(
              borderRadius: 20,
              glowColor: AppColors.cyanWater,
              title: 'AUTOEVALUACIÓN RESOLUCIÓN ICA 20186 DE 2016',
              trailingWidget: const GlassBadge(text: '92% CUMPLIMIENTO', color: AppColors.greenBiomass),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Requisitos fundamentales para la expedición o renovación del Registro de Predio Acuícola ante el ICA.',
                    style: TextStyle(fontSize: 12),
                  ),
                  const SizedBox(height: 14),
                  _buildCheckItem('1. Cerramiento perimetral que impida ingreso de animales ajenos al predio', true, isDark),
                  _buildCheckItem('2. Pediluvios y rodiluvios funcionales con desinfectante activo', true, isDark),
                  _buildCheckItem('3. Registro diario de parámetros fisicoquímicos de agua', true, isDark),
                  _buildCheckItem('4. Cuaderno de campo foliado / digital con trazabilidad de lotes', true, isDark),
                  _buildCheckItem('5. Protocolo de manejo y disposición biosegura de mortalidades', true, isDark),
                  _buildCheckItem('6. Bodega exclusiva de concentrados sobre estibas y libre de humedad', true, isDark),
                  _buildCheckItem('7. Plan Sanitario firmado por Médico Veterinario con Tarjeta Profesional', true, isDark),
                  _buildCheckItem('8. Concesión de aguas y vertimientos vigente ante autoridad ambiental', true, isDark),
                ],
              ),
            ),
            const SizedBox(height: 80),
          ],
        ),
      ),
    );
  }

  Widget _buildCheckItem(String text, bool checked, bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(checked ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded, color: checked ? AppColors.greenBiomass : AppColors.textSecondaryDark, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Text(text, style: TextStyle(color: isDark ? Colors.white : AppColors.textPrimaryLight, fontSize: 12.5, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }

  // -------------------------------------------------------------
  // TAB 3: Inocuidad y Tiempo de Retiro Farmacológico
  // -------------------------------------------------------------
  Widget _buildInocuidadTab(BuildContext context, PondsState pondsState, bool isDark) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 900),
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            GlassCard(
              borderRadius: 20,
              glowColor: AppColors.greenBiomass,
              title: 'ESTADO DE INOCUIDAD Y TIEMPOS DE RETIRO',
              trailingWidget: const GlassBadge(text: '100% INOCUO', color: AppColors.greenBiomass),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Monitoreo en vivo de los lotes en agua para garantizar que ningún pez con residuos farmacológicos sea cosechado o movilizado.',
                    style: TextStyle(fontSize: 12),
                  ),
                  const SizedBox(height: 14),
                  if (pondsState.batches.isEmpty)
                    const Text('No hay lotes activos en este momento.', style: TextStyle(color: AppColors.textSecondaryDark))
                  else
                    ...pondsState.batches.map((b) {
                      final inocuo = b.diasRetiroSanitarioRestantes <= 0;
                      return Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: isDark ? 0.04 : 0.6),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: inocuo ? AppColors.greenBiomass.withValues(alpha: 0.3) : AppColors.coralAction.withValues(alpha: 0.4)),
                        ),
                        child: Row(
                          children: [
                            Icon(inocuo ? Icons.verified_rounded : Icons.timelapse_rounded, color: inocuo ? AppColors.greenBiomass : AppColors.amberWarning, size: 20),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('${b.codigoLote} • ${b.especie}', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 12.5)),
                                  Text(
                                    inocuo ? 'Apto para Cosecha • Cero Fármacos Activos' : 'En Periodo de Retiro: ${b.diasRetiroSanitarioRestantes} días restantes',
                                    style: TextStyle(color: inocuo ? AppColors.greenBiomass : AppColors.coralAction, fontSize: 11, fontWeight: FontWeight.w700),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    }),
                ],
              ),
            ),
            const SizedBox(height: 80),
          ],
        ),
      ),
    );
  }
}

class _FormatoCardData {
  final String codigo;
  final String titulo;
  final String descripcion;
  final String categoria;
  final IconData icono;
  final Color color;
  final VoidCallback onExport;
  final VoidCallback? onDiligenciar;
  final String? badgeInfo;
  final bool isDestacado;
  final bool esDiligenciableEnIca;

  _FormatoCardData({
    required this.codigo,
    required this.titulo,
    required this.descripcion,
    required this.categoria,
    required this.icono,
    required this.color,
    required this.onExport,
    this.onDiligenciar,
    this.badgeInfo,
    this.isDestacado = false,
    this.esDiligenciableEnIca = false,
  });
}
