import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fishbit_finance/core/design_system/app_colors.dart';
import 'package:fishbit_finance/core/design_system/app_typography.dart';
import 'package:fishbit_finance/core/design_system/fishbit_header.dart';
import 'package:fishbit_finance/core/design_system/glass_card.dart';
import 'package:fishbit_finance/core/design_system/glass_container.dart';
import 'package:fishbit_finance/core/design_system/glass_badge.dart';
import 'package:fishbit_finance/core/utils/currency_formatters.dart';
import 'package:fishbit_finance/modules/water_quality/presentation/dialogs/parametro_modal.dart';
import 'package:fishbit_finance/modules/water_quality/presentation/providers/water_quality_provider.dart';
import 'package:fishbit_finance/modules/feeding_nutrition/presentation/providers/nutrition_provider.dart';
import 'package:fishbit_finance/modules/ponds_batches/presentation/providers/ponds_provider.dart';
import 'package:fishbit_finance/modules/ponds_batches/domain/models/pond.dart';
import 'package:fishbit_finance/modules/ponds_batches/domain/models/fish_batch.dart';
import 'package:fishbit_finance/modules/ponds_batches/domain/models/biometria_record.dart';
import 'package:fishbit_finance/modules/ponds_batches/domain/models/mortality_record.dart';
import 'package:fishbit_finance/modules/ponds_batches/presentation/dialogs/alimentar_modal.dart';
import 'package:fishbit_finance/modules/ponds_batches/presentation/dialogs/biometria_modal.dart';
import 'package:fishbit_finance/modules/ponds_batches/presentation/dialogs/mortalidad_modal.dart';
import 'package:fishbit_finance/modules/ponds_batches/presentation/dialogs/traslado_modal.dart';

class BitacoraScreen extends ConsumerStatefulWidget {
  const BitacoraScreen({super.key});

  @override
  ConsumerState<BitacoraScreen> createState() => _BitacoraScreenState();
}

class _BitacoraScreenState extends ConsumerState<BitacoraScreen> with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  String? _selectedPondId;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _showQuickRecordSheet(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: GlassContainer(
              borderRadius: 26,
              padding: const EdgeInsets.all(20),
              blur: 24,
              opacity: 0.18,
              borderColor: AppColors.cyanWater.withValues(alpha: 0.35),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '➕ Registrar en Bitácora',
                        style: AppTypography.titleMedium.copyWith(color: Colors.white, fontWeight: FontWeight.w800),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close_rounded, color: AppColors.textSecondaryDark),
                        onPressed: () => Navigator.of(ctx).pop(),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(
                        child: _buildQuickOption(
                          icon: Icons.water_drop_rounded,
                          color: AppColors.cyanWater,
                          title: 'O₂ y pH',
                          onTap: () {
                            Navigator.of(ctx).pop();
                            ParametroModal.show(context, preselectedPondId: _selectedPondId);
                          },
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _buildQuickOption(
                          icon: Icons.restaurant_rounded,
                          color: AppColors.greenBiomass,
                          title: 'Alimentar',
                          onTap: () {
                            Navigator.of(ctx).pop();
                            final targetPond = _selectedPondId != null ? ref.read(pondsProvider).ponds.where((p) => p.id == _selectedPondId).firstOrNull : null;
                            AlimentarModal.show(context, pond: targetPond);
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: _buildQuickOption(
                          icon: Icons.scale_rounded,
                          color: Colors.purpleAccent,
                          title: 'Biometría',
                          onTap: () {
                            Navigator.of(ctx).pop();
                            final targetPond = _selectedPondId != null ? ref.read(pondsProvider).ponds.where((p) => p.id == _selectedPondId).firstOrNull : null;
                            BiometriaModal.show(context, pond: targetPond);
                          },
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _buildQuickOption(
                          icon: Icons.warning_amber_rounded,
                          color: AppColors.coralAction,
                          title: 'Bajas / Mort.',
                          onTap: () {
                            Navigator.of(ctx).pop();
                            final targetPond = _selectedPondId != null ? ref.read(pondsProvider).ponds.where((p) => p.id == _selectedPondId).firstOrNull : null;
                            MortalidadModal.show(context, pond: targetPond);
                          },
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _buildQuickOption(
                          icon: Icons.swap_horiz_rounded,
                          color: AppColors.amberWarning,
                          title: 'Traslado',
                          onTap: () {
                            Navigator.of(ctx).pop();
                            final targetPond = _selectedPondId != null ? ref.read(pondsProvider).ponds.where((p) => p.id == _selectedPondId).firstOrNull : null;
                            TrasladoModal.show(context, pond: targetPond);
                          },
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildQuickOption({
    required IconData icon,
    required Color color,
    required String title,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: color.withValues(alpha: 0.35)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(
                  color: Theme.of(context).brightness == Brightness.dark ? Colors.white : AppColors.textPrimaryLight,
                  fontWeight: FontWeight.w800,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showPondFilterBottomSheet(
    BuildContext context,
    WaterQualityState waterState,
    NutritionState nutritionState,
    PondsState pondsState,
  ) {
    final allPonds = pondsState.ponds;
    final totalDataCount = waterState.recentParameters.length +
        nutritionState.records.length +
        pondsState.biometries.length +
        pondsState.mortalityRecords.length;

    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 500),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
            child: GlassContainer(
              borderRadius: 28,
              padding: const EdgeInsets.all(22),
              blur: 24,
              opacity: 0.18,
              borderColor: AppColors.cyanWater.withValues(alpha: 0.35),
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
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: AppColors.cyanWater.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(Icons.waves_rounded, color: AppColors.cyanWater, size: 20),
                            ),
                            const SizedBox(width: 10),
                            const Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Filtrar por Estanque',
                                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 16),
                                  ),
                                  Text(
                                    'Filtra las 4 pestañas simultáneamente',
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(color: AppColors.textSecondaryDark, fontSize: 11),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close_rounded, color: AppColors.textSecondaryDark),
                        onPressed: () => Navigator.of(ctx).pop(),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),

                  // Opción: Todos los Estanques
                  _buildPondItem(
                    title: 'Todos los Estanques',
                    subtitle: '${allPonds.length} estanques disponibles',
                    badgeText: '$totalDataCount datos',
                    isSelected: _selectedPondId == null,
                    icon: Icons.grid_view_rounded,
                    onTap: () {
                      setState(() => _selectedPondId = null);
                      Navigator.of(ctx).pop();
                    },
                  ),
                  const SizedBox(height: 8),
                  const Divider(color: Colors.white12, height: 1),
                  const SizedBox(height: 8),

                  if (allPonds.isEmpty)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 20),
                      child: Center(
                        child: Text(
                          'No hay estanques registrados aún.',
                          style: TextStyle(color: AppColors.textSecondaryDark, fontSize: 12),
                        ),
                      ),
                    )
                  else
                    ConstrainedBox(
                      constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.42),
                      child: ListView.separated(
                        shrinkWrap: true,
                        itemCount: allPonds.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 8),
                        itemBuilder: (_, index) {
                          final pond = allPonds[index];
                          final countWater = waterState.recentParameters.where((p) => p.estanqueId == pond.id).length;
                          final countFeeding = nutritionState.records.where((r) => r.estanqueId == pond.id).length;
                          final countBiometrias = pondsState.biometries.where((b) => b.estanqueId == pond.id).length;
                          final countMortality = pondsState.mortalityRecords.where((m) => m.estanqueId == pond.id).length;
                          final pondTotal = countWater + countFeeding + countBiometrias + countMortality;

                          final parts = <String>[];
                          if (countWater > 0) parts.add('$countWater O₂/pH');
                          if (countFeeding > 0) parts.add('$countFeeding raciones');
                          if (countBiometrias > 0) parts.add('$countBiometrias muestreo(s)');
                          if (countMortality > 0) parts.add('$countMortality baja(s)');
                          final subtitle = parts.isNotEmpty
                              ? parts.join(' • ')
                              : (pond.especieActual.isNotEmpty ? 'Cultivo: ${pond.especieActual}' : 'Estanque activo');

                          return _buildPondItem(
                            title: '${pond.sigla} • ${pond.nombreLimpio}',
                            subtitle: subtitle,
                            badgeText: '$pondTotal datos',
                            isSelected: _selectedPondId == pond.id,
                            icon: Icons.water_rounded,
                            onTap: () {
                              setState(() => _selectedPondId = pond.id);
                              Navigator.of(ctx).pop();
                            },
                          );
                        },
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPondItem({
    required String title,
    required String subtitle,
    required String badgeText,
    required bool isSelected,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.cyanWater.withValues(alpha: 0.15) : Colors.white.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isSelected ? AppColors.cyanWater.withValues(alpha: 0.5) : Colors.white.withValues(alpha: 0.1),
              width: isSelected ? 1.5 : 1.0,
            ),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: isSelected ? AppColors.cyanWater.withValues(alpha: 0.25) : Colors.white.withValues(alpha: 0.06),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: isSelected ? AppColors.cyanWater : Colors.white70, size: 18),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                      style: TextStyle(
                        color: isSelected ? AppColors.cyanWater : Colors.white,
                        fontWeight: FontWeight.w800,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                      style: const TextStyle(color: AppColors.textSecondaryDark, fontSize: 11),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              GlassBadge(
                text: badgeText,
                color: isSelected ? AppColors.cyanWater : Colors.white54,
              ),
              if (isSelected) ...[
                const SizedBox(width: 8),
                const Icon(Icons.check_circle_rounded, color: AppColors.cyanWater, size: 18),
              ],
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final waterState = ref.watch(waterQualityProvider);
    final nutritionState = ref.watch(nutritionProvider);
    final pondsState = ref.watch(pondsProvider);

    // O(M) indexación para lookups O(1) en los builders virtuales
    final pondMap = {for (final p in pondsState.ponds) p.id: p};
    final batchMap = {for (final b in pondsState.batches) b.id: b};

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 78),
        child: FloatingActionButton.extended(
          backgroundColor: AppColors.cyanWater,
          icon: const Icon(Icons.edit_note_rounded, color: Colors.black, size: 22),
          label: const Text('Registrar en Bitácora', style: TextStyle(color: Colors.black, fontWeight: FontWeight.w900, fontSize: 13)),
          onPressed: () => _showQuickRecordSheet(context),
        ),
      ),
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) => [
          FishBitHeader(
            onRefresh: () {
              ref.read(waterQualityProvider.notifier).loadParameters();
              ref.read(nutritionProvider.notifier).loadData();
              ref.read(pondsProvider.notifier).loadPondsAndBatches();
            },
          ),
          SliverToBoxAdapter(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1024),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () => _showPondFilterBottomSheet(context, waterState, nutritionState, pondsState),
                      borderRadius: BorderRadius.circular(16),
                      child: GlassContainer(
                        borderRadius: 16,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        blur: 16,
                        opacity: 0.14,
                        borderColor: AppColors.cyanWater.withValues(alpha: 0.35),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: AppColors.cyanWater.withValues(alpha: 0.15),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: const Icon(Icons.tune_rounded, color: AppColors.cyanWater, size: 18),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text(
                                          'ESTANQUE DE CONSULTA',
                                          style: AppTypography.labelMicro.copyWith(color: AppColors.textSecondaryDark),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          _selectedPondId == null
                                              ? 'Todos los Estanques (${pondsState.ponds.length})'
                                              : () {
                                                  final p = pondMap[_selectedPondId];
                                                  return p != null ? '${p.sigla} • ${p.nombreLimpio}' : 'Estanque Seleccionado';
                                                }(),
                                          overflow: TextOverflow.ellipsis,
                                          maxLines: 1,
                                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 13),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                if (_selectedPondId != null)
                                  GestureDetector(
                                    onTap: () => setState(() => _selectedPondId = null),
                                    child: Container(
                                      margin: const EdgeInsets.only(right: 6),
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: AppColors.coralAction.withValues(alpha: 0.15),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: const Text('Limpiar', style: TextStyle(color: AppColors.coralAction, fontSize: 11, fontWeight: FontWeight.w700)),
                                    ),
                                  ),
                                const Icon(Icons.keyboard_arrow_down_rounded, color: AppColors.cyanWater, size: 22),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1024),
                child: Container(
                  color: Colors.transparent,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  child: TabBar(
                    controller: _tabController,
                    isScrollable: true,
                    tabAlignment: TabAlignment.start,
                    indicatorColor: AppColors.cyanWater,
                    indicatorWeight: 3,
                    labelColor: AppColors.cyanWater,
                    unselectedLabelColor: Theme.of(context).brightness == Brightness.dark
                        ? AppColors.textSecondaryDark
                        : AppColors.textSecondaryLight,
                    tabs: const [
                      Tab(key: Key('tab_calidad_agua'), icon: Icon(Icons.water_drop_rounded, size: 16), text: 'Calidad de Agua'),
                      Tab(key: Key('tab_alimentacion'), icon: Icon(Icons.restaurant_rounded, size: 16), text: 'Alimentación'),
                      Tab(key: Key('tab_biometrias'), icon: Icon(Icons.scale_rounded, size: 16), text: 'Biometrías y GDP'),
                      Tab(key: Key('tab_bajas'), icon: Icon(Icons.warning_amber_rounded, size: 16), text: 'Bajas y Sanidad'),
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
            // Pestaña 1: Calidad de Agua
            _buildWaterQualityTab(context, waterState, pondsState, pondMap),

            // Pestaña 2: Alimentación Diaria
            _buildFeedingTab(context, nutritionState, pondsState, pondMap, batchMap),

            // Pestaña 3: Biometrías y Curvas (GDP)
            _buildBiometryTab(context, pondsState, pondMap, batchMap),

            // Pestaña 4: Mortalidad y Sanidad (Bajas)
            _buildMortalityTab(context, pondsState, pondMap, batchMap),
          ],
        ),
      ),
    );
  }

  Widget _buildWaterQualityTab(
    BuildContext context,
    WaterQualityState waterState,
    PondsState pondsState,
    Map<String, Pond> pondMap,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textSecondary = isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight;

    final filteredParams = waterState.recentParameters.where((p) {
      if (_selectedPondId != null && p.estanqueId.trim() != _selectedPondId!.trim()) return false;
      return true;
    }).toList();

    // Cálculo dinámico de métricas para el estanque filtrado (o global)
    final latestParam = filteredParams.firstOrNull;
    final oxigenoDisplay = latestParam?.oxigenoMgL != null
        ? '${latestParam!.oxigenoMgL!.toStringAsFixed(1)} mg/L'
        : '—';
    final oxigenoSub = latestParam != null && latestParam.oxigenoMgL != null
        ? 'Último registro (${latestParam.fecha.hour.toString().padLeft(2, '0')}:${latestParam.fecha.minute.toString().padLeft(2, '0')})'
        : 'Sin mediciones registradas';
    final phDisplay = latestParam?.ph != null
        ? latestParam!.ph!.toStringAsFixed(1)
        : '—';
    final phSub = latestParam != null && latestParam.ph != null
        ? (latestParam.ph! >= 6.5 && latestParam.ph! <= 8.5 ? 'pH en equilibrio' : 'pH fuera de rango')
        : 'Sin mediciones registradas';

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1024),
        child: ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: filteredParams.isEmpty ? 2 : (filteredParams.length + 2),
          itemBuilder: (context, index) {
            if (index == 0) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: GlassCard(
                          title: 'Oxígeno Disuelto',
                          glowColor: AppColors.cyanWater,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              FittedBox(
                                fit: BoxFit.scaleDown,
                                alignment: Alignment.centerLeft,
                                child: Text(oxigenoDisplay, style: AppTypography.titleLarge.copyWith(color: AppColors.cyanWater, fontWeight: FontWeight.w900)),
                              ),
                              const SizedBox(height: 2),
                              Text(oxigenoSub, style: AppTypography.labelMicro.copyWith(color: textSecondary), overflow: TextOverflow.ellipsis),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: GlassCard(
                          title: 'pH de Agua',
                          glowColor: AppColors.greenBiomass,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              FittedBox(
                                fit: BoxFit.scaleDown,
                                alignment: Alignment.centerLeft,
                                child: Text(phDisplay, style: AppTypography.titleLarge.copyWith(color: AppColors.greenBiomass, fontWeight: FontWeight.w900)),
                              ),
                              const SizedBox(height: 2),
                              Text(phSub, style: AppTypography.labelMicro.copyWith(color: textSecondary), overflow: TextOverflow.ellipsis),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text('HISTORIAL DE MEDICIONES DE AGUA (${filteredParams.length})', style: AppTypography.labelMicro.copyWith(color: textSecondary, letterSpacing: 1.5)),
                  const SizedBox(height: 10),
                ],
              );
            }
            if (filteredParams.isEmpty) {
              final selectedPond = _selectedPondId != null ? pondMap[_selectedPondId] : null;
              final nombreEstanque = selectedPond != null ? selectedPond.nombreLimpio : 'este estanque';

              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 16),
                child: Center(
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppColors.cyanWater.withValues(alpha: 0.12),
                          shape: BoxShape.circle,
                          border: Border.all(color: AppColors.cyanWater.withValues(alpha: 0.3)),
                        ),
                        child: const Icon(Icons.water_drop_rounded, color: AppColors.cyanWater, size: 40),
                      ),
                      const SizedBox(height: 14),
                      Text(
                        'Sin mediciones en $nombreEstanque',
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 15),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Aún no se han registrado parámetros de oxígeno, pH o temperatura para $nombreEstanque.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: textSecondary, fontSize: 12),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton.icon(
                        onPressed: () => ParametroModal.show(context, preselectedPondId: _selectedPondId),
                        icon: const Icon(Icons.add_rounded, size: 18),
                        label: const Text('Registrar Primer Parámetro', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 12)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.cyanWater,
                          foregroundColor: Colors.black,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }
            if (index == filteredParams.length + 1) {
              return const SizedBox(height: 80);
            }

            final p = filteredParams[index - 1];
            final pond = pondMap[p.estanqueId];
            final pondTitulo = pond != null ? pond.nombreLimpio : 'Estanque';
            final pondSigla = pond != null ? pond.sigla.split('-').first.trim() : '';
            final horaStr = '${p.fecha.hour.toString().padLeft(2, '0')}:${p.fecha.minute.toString().padLeft(2, '0')}';
            final fechaStr = '${p.fecha.day}/${p.fecha.month}/${p.fecha.year}';
            final isOptimal = (p.oxigenoMgL ?? 6.0) >= 4.5 && (p.ph ?? 7.0) >= 6.5 && (p.ph ?? 7.0) <= 8.0 && (p.amonioMgL ?? 0.0) <= 0.5;
            final estadoSanitario = isOptimal ? 'Óptimo' : 'Atención';

            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: GlassContainer(
                borderRadius: 20,
                padding: const EdgeInsets.all(16),
                blur: 16,
                opacity: 0.14,
                borderColor: isOptimal ? AppColors.cyanWater.withValues(alpha: 0.25) : AppColors.coralAction.withValues(alpha: 0.4),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Fila Cabecera: Estanque, Fecha, Hora y Estado
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Wrap(
                            crossAxisAlignment: WrapCrossAlignment.center,
                            spacing: 8,
                            runSpacing: 4,
                            children: [
                              Text(pondTitulo, style: AppTypography.titleSmall.copyWith(color: AppColors.cyanWater, fontWeight: FontWeight.w800)),
                              if (pondSigla.isNotEmpty && pondSigla != pondTitulo)
                                GlassBadge(text: pondSigla, color: AppColors.cyanWater),
                              GlassBadge(text: '$fechaStr • ⏰ $horaStr', color: Colors.white),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        GlassBadge(
                          text: estadoSanitario,
                          color: isOptimal ? AppColors.greenBiomass : AppColors.coralAction,
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),

                    // Fila 1: O2, Temp, pH
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.04),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Wrap(
                        alignment: WrapAlignment.spaceBetween,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        spacing: 8,
                        runSpacing: 4,
                        children: [
                          Text('O₂: ${(p.oxigenoMgL ?? 6.0).toStringAsFixed(1)} mg/L ${p.oxigenoPct != null ? "(${p.oxigenoPct!.toInt()}%)" : ""}',
                              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 11.5)),
                          Text('Temp: ${(p.temperaturaC ?? 28.0).toStringAsFixed(1)}°C',
                              style: const TextStyle(color: Colors.white70, fontWeight: FontWeight.w600, fontSize: 11.5)),
                          Text('pH: ${(p.ph ?? 7.2).toStringAsFixed(1)}',
                              style: const TextStyle(color: AppColors.greenBiomass, fontWeight: FontWeight.w700, fontSize: 11.5)),
                        ],
                      ),
                    ),
                    const SizedBox(height: 6),

                    // Fila 2: Nitrógenos (Amonio, Nitrito, Nitrato)
                    Wrap(
                      spacing: 12,
                      runSpacing: 4,
                      children: [
                        Text('Amonio: ${(p.amonioMgL ?? 0.15).toStringAsFixed(2)} ppm',
                            style: TextStyle(color: (p.amonioMgL ?? 0.0) > 0.5 ? AppColors.coralAction : textSecondary, fontSize: 11, fontWeight: FontWeight.w600)),
                        if (p.nitritosMgL != null)
                          Text('Nitrito NO₂: ${p.nitritosMgL!.toStringAsFixed(2)} ppm',
                              style: TextStyle(color: p.nitritosMgL! > 0.2 ? AppColors.coralAction : textSecondary, fontSize: 11)),
                        if (p.nitratosMgL != null)
                          Text('Nitrato NO₃: ${p.nitratosMgL!.toStringAsFixed(1)} ppm',
                              style: TextStyle(color: textSecondary, fontSize: 11)),
                      ],
                    ),
                    const SizedBox(height: 4),

                    // Fila 3: Balance Químico (Alcalinidad, CO2, Dureza, Cloro)
                    Wrap(
                      spacing: 12,
                      runSpacing: 4,
                      children: [
                        if (p.alcalinidadMgL != null)
                          Text('Alcalinidad: ${p.alcalinidadMgL!.toInt()} ppm', style: TextStyle(color: textSecondary, fontSize: 11)),
                        if (p.co2MgL != null)
                          Text('CO₂: ${p.co2MgL!.toStringAsFixed(1)} ppm', style: TextStyle(color: (p.co2MgL ?? 0.0) > 20.0 ? AppColors.amberWarning : textSecondary, fontSize: 11)),
                        if (p.durezaMgL != null)
                          Text('Dureza: ${p.durezaMgL!.toInt()} ppm', style: TextStyle(color: textSecondary, fontSize: 11)),
                        if (p.cloroMgL != null)
                          Text('Cloro: ${p.cloroMgL!.toStringAsFixed(2)} ppm', style: TextStyle(color: (p.cloroMgL ?? 0.0) > 0.05 ? AppColors.coralAction : textSecondary, fontSize: 11)),
                      ],
                    ),

                    if (p.observaciones != null && p.observaciones!.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Text('Notas: ${p.observaciones}', style: const TextStyle(color: Colors.white54, fontStyle: FontStyle.italic, fontSize: 10.5)),
                    ],
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildFeedingTab(
    BuildContext context,
    NutritionState nutritionState,
    PondsState pondsState,
    Map<String, Pond> pondMap,
    Map<String, FishBatch> batchMap,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textSecondary = isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight;
    final textPrimary = isDark ? Colors.white : AppColors.textPrimaryLight;

    final records = nutritionState.records.where((r) {
      if (_selectedPondId != null && r.estanqueId.trim() != _selectedPondId!.trim()) return false;
      return true;
    }).toList();
    final totalKg = records.fold(0.0, (sum, r) => sum + r.cantidadConsumidaKg);
    final totalCosto = records.fold(0.0, (sum, r) => sum + r.costoCalculado);

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1024),
        child: ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: records.isEmpty ? 2 : (records.length + 2),
          itemBuilder: (context, index) {
            if (index == 0) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: GlassCard(
                          title: 'ALIMENTO TOTAL',
                          glowColor: AppColors.greenBiomass,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              FittedBox(
                                fit: BoxFit.scaleDown,
                                child: Text('${totalKg.toStringAsFixed(1)} kg', style: AppTypography.titleLarge.copyWith(color: AppColors.greenBiomass, fontWeight: FontWeight.w900)),
                              ),
                              Text('Suministrado en estanque(s)', style: AppTypography.labelMicro.copyWith(color: textSecondary)),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: GlassCard(
                          title: 'COSTO ALIMENTO',
                          glowColor: AppColors.coralAction,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              FittedBox(
                                fit: BoxFit.scaleDown,
                                child: Text(CurrencyFormatters.formatCOP(totalCosto), style: AppTypography.titleMedium.copyWith(color: AppColors.coralAction, fontWeight: FontWeight.w900)),
                              ),
                              Text('Insumo descontado', style: AppTypography.labelMicro.copyWith(color: textSecondary)),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text('REGISTROS DE ALIMENTACIÓN (${records.length})', style: AppTypography.labelMicro.copyWith(color: textSecondary, letterSpacing: 1.5)),
                  const SizedBox(height: 10),
                ],
              );
            }
            if (records.isEmpty) {
              final selectedPond = _selectedPondId != null ? pondMap[_selectedPondId] : null;
              final nombreEstanque = selectedPond != null ? selectedPond.nombreLimpio : 'este estanque';

              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 16),
                child: Center(
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppColors.greenBiomass.withValues(alpha: 0.12),
                          shape: BoxShape.circle,
                          border: Border.all(color: AppColors.greenBiomass.withValues(alpha: 0.3)),
                        ),
                        child: const Icon(Icons.restaurant_rounded, color: AppColors.greenBiomass, size: 40),
                      ),
                      const SizedBox(height: 14),
                      Text(
                        'Sin raciones registradas en $nombreEstanque',
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 15),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'No se han reportado raciones diarias de alimento concentrado para $nombreEstanque.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: textSecondary, fontSize: 12),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton.icon(
                        onPressed: () {
                          final targetPond = _selectedPondId != null ? ref.read(pondsProvider).ponds.where((p) => p.id == _selectedPondId).firstOrNull : null;
                          AlimentarModal.show(context, pond: targetPond);
                        },
                        icon: const Icon(Icons.restaurant_rounded, size: 18),
                        label: const Text('Registrar Alimentación', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 12)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.greenBiomass,
                          foregroundColor: Colors.black,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }
            if (index == records.length + 1) {
              return const SizedBox(height: 80);
            }

            final r = records[index - 1];
            final pond = pondMap[r.estanqueId];
            final pondTitulo = pond != null ? pond.nombreLimpio : 'Estanque';
            final batch = batchMap[r.loteId];
            final loteStr = batch != null ? 'Lote ${batch.codigoLote}' : (r.loteId.isNotEmpty ? (r.loteId.length > 6 ? 'Lote ${r.loteId.substring(0, 6)}' : 'Lote ${r.loteId}') : 'Cultivo Activo');
            final fechaStr = '${r.fecha.day}/${r.fecha.month}/${r.fecha.year}';

            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: GlassContainer(
                borderRadius: 18,
                padding: const EdgeInsets.all(14),
                blur: 16,
                opacity: 0.12,
                borderColor: AppColors.greenBiomass.withValues(alpha: 0.25),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: AppColors.greenBiomass.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(Icons.restaurant_rounded, color: AppColors.greenBiomass, size: 18),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Flexible(
                                      flex: 2,
                                      child: Text(
                                        pondTitulo,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(color: AppColors.cyanWater, fontWeight: FontWeight.w800, fontSize: 13),
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                    Flexible(
                                      flex: 3,
                                      child: Text(
                                        '• $loteStr ($fechaStr)',
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(color: textPrimary, fontWeight: FontWeight.w600, fontSize: 12),
                                      ),
                                    ),
                                  ],
                                ),
                                Text('Consumo: ${r.cantidadConsumidaKg.toStringAsFixed(1)} kg', style: TextStyle(color: textSecondary, fontSize: 11)),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(CurrencyFormatters.formatCOP(r.costoCalculado), style: const TextStyle(color: AppColors.greenBiomass, fontWeight: FontWeight.w800, fontSize: 13)),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildBiometryTab(
    BuildContext context,
    PondsState pondsState,
    Map<String, Pond> pondMap,
    Map<String, FishBatch> batchMap,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textSecondary = isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight;
    final textPrimary = isDark ? Colors.white : AppColors.textPrimaryLight;

    // Cálculo memoizado/indexado de análisis biométrico y curvas de crecimiento (GDP)
    final analysis = _BiometryAnalysis.compute(
      allBiometries: pondsState.biometries,
      batches: pondsState.batches,
      selectedPondId: _selectedPondId,
    );
    final sortedBiometries = analysis.sortedBiometries;
    final periodGdpMap = analysis.periodGdpMap;

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1024),
        child: ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: sortedBiometries.isEmpty ? 2 : (sortedBiometries.length + 2),
          itemBuilder: (context, index) {
            if (index == 0) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: GlassCard(
                          title: 'ÚLTIMO PESO PROM.',
                          glowColor: AppColors.cyanWater,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              FittedBox(
                                fit: BoxFit.scaleDown,
                                child: Text(
                                  sortedBiometries.isNotEmpty || analysis.latestAvgWeight > 0
                                      ? '${analysis.latestAvgWeight.toStringAsFixed(1)} g'
                                      : '—',
                                  style: AppTypography.titleLarge.copyWith(color: AppColors.cyanWater, fontWeight: FontWeight.w900),
                                ),
                              ),
                              Text(
                                sortedBiometries.isNotEmpty ? 'Muestreo más reciente' : 'Sin muestreos',
                                style: AppTypography.labelMicro.copyWith(color: textSecondary),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: GlassCard(
                          title: 'GDP DEL PERIODO',
                          glowColor: AppColors.greenBiomass,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              FittedBox(
                                fit: BoxFit.scaleDown,
                                child: Text(
                                  sortedBiometries.isNotEmpty ? '+${analysis.avgGdp.toStringAsFixed(2)} g/d' : '—',
                                  style: AppTypography.titleLarge.copyWith(color: AppColors.greenBiomass, fontWeight: FontWeight.w900),
                                ),
                              ),
                              Text(
                                'Crecimiento promedio',
                                style: AppTypography.labelMicro.copyWith(color: textSecondary),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'HISTORIAL DE MUESTREOS BIOMÉTRICOS (${sortedBiometries.length})',
                    style: AppTypography.labelMicro.copyWith(color: textSecondary, letterSpacing: 1.5),
                  ),
                  const SizedBox(height: 10),
                ],
              );
            }
            if (sortedBiometries.isEmpty) {
              final selectedPond = _selectedPondId != null ? pondMap[_selectedPondId] : null;
              final nombreEstanque = selectedPond != null ? selectedPond.nombreLimpio : 'este estanque';

              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 16),
                child: Center(
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.purpleAccent.withValues(alpha: 0.12),
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.purpleAccent.withValues(alpha: 0.3)),
                        ),
                        child: const Icon(Icons.scale_rounded, color: Colors.purpleAccent, size: 40),
                      ),
                      const SizedBox(height: 14),
                      Text(
                        'Sin muestreos biométricos en $nombreEstanque',
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 15),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Registra un muestreo de peso y talla para calcular la ganancia diaria de peso (GDP).',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: textSecondary, fontSize: 12),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton.icon(
                        onPressed: () {
                          final targetPond = _selectedPondId != null ? ref.read(pondsProvider).ponds.where((p) => p.id == _selectedPondId).firstOrNull : null;
                          BiometriaModal.show(context, pond: targetPond);
                        },
                        icon: const Icon(Icons.scale_rounded, size: 18),
                        label: const Text('Registrar Biometría', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 12)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.purpleAccent,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }
            if (index == sortedBiometries.length + 1) {
              return const SizedBox(height: 80);
            }

            final bio = sortedBiometries[index - 1];
            final pond = pondMap[bio.estanqueId];
            final pondTitulo = pond != null ? pond.nombreLimpio : 'Estanque';
            final batch = batchMap[bio.loteId];
            final loteStr = batch != null ? 'Lote ${batch.codigoLote}' : (bio.loteId.isNotEmpty ? 'Lote ${bio.loteId}' : 'Lote Principal');
            final especieStr = batch?.especie ?? pond?.especieActual ?? 'Tilapia';
            final fechaStr = '${bio.fecha.day}/${bio.fecha.month}/${bio.fecha.year}';
            final horaStr = bio.hora != null && bio.hora!.isNotEmpty
                ? (bio.hora!.length >= 5 ? bio.hora!.substring(0, 5) : bio.hora!)
                : '${bio.fecha.hour.toString().padLeft(2, '0')}:${bio.fecha.minute.toString().padLeft(2, '0')}';
            final periodGdp = periodGdpMap[bio.id] ?? bio.gdpGDia ?? 0.0;

            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: GlassContainer(
                borderRadius: 20,
                padding: const EdgeInsets.all(16),
                blur: 16,
                opacity: 0.14,
                borderColor: AppColors.cyanWater.withValues(alpha: 0.28),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Cabecera: Estanque, Lote, Especie, Fecha y Hora
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Wrap(
                            crossAxisAlignment: WrapCrossAlignment.center,
                            spacing: 8,
                            runSpacing: 4,
                            children: [
                              Text(pondTitulo, style: AppTypography.titleSmall.copyWith(color: AppColors.cyanWater, fontWeight: FontWeight.w800)),
                              GlassBadge(text: '$loteStr • $especieStr', color: Colors.white),
                              GlassBadge(text: '$fechaStr • ⏰ $horaStr', color: Colors.white70),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        GlassBadge(
                          text: '+${periodGdp.toStringAsFixed(2)} g/d',
                          color: periodGdp >= 1.5 ? AppColors.greenBiomass : (periodGdp >= 0.8 ? AppColors.cyanWater : AppColors.amberWarning),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),

                    // Métricas principales del muestreo
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.04),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('PESO PROMEDIO', style: AppTypography.labelMicro.copyWith(color: textSecondary), overflow: TextOverflow.ellipsis),
                                const SizedBox(height: 2),
                                Text(
                                  '${bio.pesoPromedioG.toStringAsFixed(1)} g',
                                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 14),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('MUESTRA CAPTURADA', style: AppTypography.labelMicro.copyWith(color: textSecondary), overflow: TextOverflow.ellipsis),
                                const SizedBox(height: 2),
                                Text(
                                  '${bio.pecesCapturados} peces (${bio.pesoTotalCapturaKg.toStringAsFixed(2)} kg)',
                                  style: TextStyle(color: textPrimary, fontWeight: FontWeight.w700, fontSize: 12),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text('BIOMASA ESTIMADA', style: AppTypography.labelMicro.copyWith(color: textSecondary), overflow: TextOverflow.ellipsis),
                                const SizedBox(height: 2),
                                Text(
                                  CurrencyFormatters.formatKg(bio.biomasaParcialKg),
                                  style: const TextStyle(color: AppColors.cyanWater, fontWeight: FontWeight.w900, fontSize: 13),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),

                    // Fila secundaria: Longitud y Factor K
                    Wrap(
                      spacing: 12,
                      runSpacing: 4,
                      children: [
                        if (bio.longitudCm != null && bio.longitudCm! > 0)
                          Text('Talla: ${bio.longitudCm!.toStringAsFixed(1)} cm', style: TextStyle(color: textSecondary, fontSize: 11, fontWeight: FontWeight.w600)),
                        if (bio.factorK != null && bio.factorK! > 0)
                          Text('Factor K: ${bio.factorK!.toStringAsFixed(2)} (Fulton)', style: TextStyle(color: textSecondary, fontSize: 11)),
                        Text('GDP Periodo: ${periodGdp.toStringAsFixed(2)} g/día', style: TextStyle(color: periodGdp >= 1.0 ? AppColors.greenBiomass : textSecondary, fontSize: 11, fontWeight: FontWeight.w600)),
                      ],
                    ),

                    if (bio.observaciones != null && bio.observaciones!.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Text('Notas: ${bio.observaciones}', style: const TextStyle(color: Colors.white54, fontStyle: FontStyle.italic, fontSize: 10.5)),
                    ],
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildMortalityTab(
    BuildContext context,
    PondsState pondsState,
    Map<String, Pond> pondMap,
    Map<String, FishBatch> batchMap,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textSecondary = isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight;
    final textPrimary = isDark ? Colors.white : AppColors.textPrimaryLight;

    // Filter mortality records by selected pond
    // Filter mortality records by selected pond
    final allMortalities = pondsState.mortalityRecords;
    final records = _selectedPondId != null
        ? allMortalities.where((m) => m.estanqueId.trim() == _selectedPondId!.trim()).toList()
        : allMortalities;

    // Sort records in reverse chronological order
    final sortedRecords = List<MortalityRecord>.from(records)..sort((a, b) => b.fecha.compareTo(a.fecha));

    // Calculate mortality KPIs
    final totalBajas = sortedRecords.fold<int>(0, (sum, m) => sum + m.cantidadPecesMuertos);
    final totalBiomasaPerdida = sortedRecords.fold<double>(0.0, (sum, m) => sum + m.biomasaPerdidaKg);

    String causaPredominante = 'Sin eventos';
    if (sortedRecords.isNotEmpty) {
      final Map<String, int> causeCounts = {};
      for (final m in sortedRecords) {
        causeCounts[m.causaProbable] = (causeCounts[m.causaProbable] ?? 0) + m.cantidadPecesMuertos;
      }
      causaPredominante = causeCounts.entries.reduce((a, b) => a.value > b.value ? a : b).key;
    }

    final relevantBatches = _selectedPondId != null
        ? pondsState.batches.where((b) => b.estanqueId.trim() == _selectedPondId!.trim()).toList()
        : pondsState.batches;
    final totalPecesActual = relevantBatches.fold<int>(0, (sum, b) => sum + b.cantidadActualPeces);
    final totalPecesInicial = relevantBatches.fold<int>(0, (sum, b) => sum + b.cantidadInicialPeces);
    final supervivencia = totalPecesInicial > 0
        ? (totalPecesActual / totalPecesInicial) * 100.0
        : (totalBajas > 0 ? (100.0 - (totalBajas / (totalBajas + 1000) * 100.0)) : 100.0);

    Color getCauseColor(String causa) {
      final c = causa.toLowerCase();
      if (c.contains('hipoxia') || c.contains('oxigeno') || c.contains('o2')) return AppColors.coralAction;
      if (c.contains('bacteri') || c.contains('hongo') || c.contains('enferm')) return AppColors.amberWarning;
      if (c.contains('manejo') || c.contains('trauma') || c.contains('muestreo')) return AppColors.cyanWater;
      if (c.contains('depred') || c.contains('ave')) return Colors.purpleAccent;
      return Colors.white70;
    }

    final filteredTransfers = _selectedPondId != null
        ? pondsState.transferRecords.where((t) => t.estanqueOrigenId.trim() == _selectedPondId!.trim() || t.estanqueDestinoId.trim() == _selectedPondId!.trim()).toList()
        : pondsState.transferRecords;

    final mortCount = sortedRecords.isEmpty ? 1 : sortedRecords.length;
    final transCount = filteredTransfers.isEmpty ? 1 : filteredTransfers.length;
    final totalItems = 1 + mortCount + 1 + transCount + 1;

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1024),
        child: ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: totalItems,
          itemBuilder: (context, index) {
            // 0: Header KPIs de Mortalidad
            if (index == 0) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: GlassCard(
                          title: 'TOTAL BAJAS',
                          glowColor: AppColors.coralAction,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              FittedBox(
                                fit: BoxFit.scaleDown,
                                child: Text(
                                  '$totalBajas peces',
                                  style: AppTypography.titleLarge.copyWith(color: AppColors.coralAction, fontWeight: FontWeight.w900),
                                ),
                              ),
                              Text(
                                'Pérdida: ${CurrencyFormatters.formatKg(totalBiomasaPerdida)}',
                                style: AppTypography.labelMicro.copyWith(color: textSecondary),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: GlassCard(
                          title: 'SUPERVIVENCIA',
                          glowColor: AppColors.greenBiomass,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              FittedBox(
                                fit: BoxFit.scaleDown,
                                child: Text(
                                  '${supervivencia.toStringAsFixed(1)}%',
                                  style: AppTypography.titleLarge.copyWith(color: AppColors.greenBiomass, fontWeight: FontWeight.w900),
                                ),
                              ),
                              Text(
                                'Causa: $causaPredominante',
                                overflow: TextOverflow.ellipsis,
                                maxLines: 1,
                                style: AppTypography.labelMicro.copyWith(color: textSecondary),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'HISTORIAL DE EVENTOS DE MORTALIDAD (${sortedRecords.length})',
                    style: AppTypography.labelMicro.copyWith(color: textSecondary, letterSpacing: 1.5),
                  ),
                  const SizedBox(height: 10),
                ],
              );
            }

            // 1..mortCount: Registros de mortalidad o estado vacío
            if (index >= 1 && index < 1 + mortCount) {
              if (sortedRecords.isEmpty) {
                final selectedPond = _selectedPondId != null ? pondMap[_selectedPondId] : null;
                final nombreEstanque = selectedPond != null ? selectedPond.nombreLimpio : 'este estanque';

                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
                  child: Center(
                    child: Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: AppColors.greenBiomass.withValues(alpha: 0.12),
                            shape: BoxShape.circle,
                            border: Border.all(color: AppColors.greenBiomass.withValues(alpha: 0.3)),
                          ),
                          child: const Icon(Icons.health_and_safety_rounded, color: AppColors.greenBiomass, size: 36),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Sin bajas reportadas en $nombreEstanque',
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 14),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Población en estado sanitario óptimo. (0 bajas registradas)',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: textSecondary, fontSize: 11.5),
                        ),
                        const SizedBox(height: 14),
                        OutlinedButton.icon(
                          onPressed: () {
                            final targetPond = _selectedPondId != null ? ref.read(pondsProvider).ponds.where((p) => p.id == _selectedPondId).firstOrNull : null;
                            MortalidadModal.show(context, pond: targetPond);
                          },
                          icon: const Icon(Icons.warning_amber_rounded, size: 16, color: AppColors.coralAction),
                          label: const Text('Registrar Novedad / Baja', style: TextStyle(color: AppColors.coralAction, fontWeight: FontWeight.w800, fontSize: 11.5)),
                          style: OutlinedButton.styleFrom(
                            side: BorderSide(color: AppColors.coralAction.withValues(alpha: 0.5)),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }

              final r = sortedRecords[index - 1];
              final pond = pondMap[r.estanqueId];
              final pondTitulo = pond != null ? pond.nombreLimpio : 'Estanque';
              final batch = batchMap[r.loteId];
              final loteStr = batch != null ? 'Lote ${batch.codigoLote}' : (r.loteId.isNotEmpty ? 'Lote ${r.loteId}' : 'Lote Activo');
              final especieStr = batch?.especie ?? pond?.especieActual ?? 'Tilapia';
              final fechaStr = '${r.fecha.day}/${r.fecha.month}/${r.fecha.year}';
              final horaStr = r.hora != null && r.hora!.isNotEmpty
                  ? (r.hora!.length >= 5 ? r.hora!.substring(0, 5) : r.hora!)
                  : '${r.fecha.hour.toString().padLeft(2, '0')}:${r.fecha.minute.toString().padLeft(2, '0')}';
              final causeColor = getCauseColor(r.causaProbable);

              final double mortalityPct;
              if (batch != null && batch.cantidadInicialPeces > 0) {
                mortalityPct = (r.cantidadPecesMuertos / batch.cantidadInicialPeces) * 100.0;
              } else {
                mortalityPct = 0.0;
              }

              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: GlassContainer(
                  borderRadius: 20,
                  padding: const EdgeInsets.all(16),
                  blur: 16,
                  opacity: 0.14,
                  borderColor: AppColors.coralAction.withValues(alpha: 0.28),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Cabecera: Estanque, Lote, Fecha y Causa
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Wrap(
                              crossAxisAlignment: WrapCrossAlignment.center,
                              spacing: 8,
                              runSpacing: 4,
                              children: [
                                Text(pondTitulo, style: AppTypography.titleSmall.copyWith(color: AppColors.cyanWater, fontWeight: FontWeight.w800)),
                                GlassBadge(text: '$loteStr • $especieStr', color: Colors.white),
                                GlassBadge(text: '$fechaStr • ⏰ $horaStr', color: Colors.white70),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          GlassBadge(
                            text: r.causaProbable,
                            color: causeColor,
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),

                      // Fila de datos cuantitativos de la baja
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.04),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('CANTIDAD BAJAS', style: AppTypography.labelMicro.copyWith(color: textSecondary), overflow: TextOverflow.ellipsis),
                                  const SizedBox(height: 2),
                                  Text(
                                    '${r.cantidadPecesMuertos} peces',
                                    style: const TextStyle(color: AppColors.coralAction, fontWeight: FontWeight.w900, fontSize: 14),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  Text('PESO PROMEDIO', style: AppTypography.labelMicro.copyWith(color: textSecondary), overflow: TextOverflow.ellipsis),
                                  const SizedBox(height: 2),
                                  Text(
                                    '${r.pesoPromedioGramos.toStringAsFixed(1)} g',
                                    style: TextStyle(color: textPrimary, fontWeight: FontWeight.w700, fontSize: 12),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text('BIOMASA PERDIDA', style: AppTypography.labelMicro.copyWith(color: textSecondary), overflow: TextOverflow.ellipsis),
                                  const SizedBox(height: 2),
                                  Text(
                                    CurrencyFormatters.formatKg(r.biomasaPerdidaKg),
                                    style: const TextStyle(color: AppColors.coralAction, fontWeight: FontWeight.w900, fontSize: 13),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 8),

                      // Fila de porcentaje acumulado / advertencia
                      Wrap(
                        spacing: 12,
                        runSpacing: 4,
                        children: [
                          if (mortalityPct > 0)
                            Text(
                              'Impacto lote: ${mortalityPct.toStringAsFixed(2)}% de población inicial',
                              style: TextStyle(color: mortalityPct >= 2.0 ? AppColors.coralAction : textSecondary, fontSize: 11, fontWeight: FontWeight.w600),
                            ),
                          if (batch != null)
                            Text(
                              'Supervivencia actual lote: ${(100.0 - batch.porcentajeMortalidad).toStringAsFixed(1)}%',
                              style: const TextStyle(color: AppColors.greenBiomass, fontSize: 11, fontWeight: FontWeight.w600),
                            ),
                        ],
                      ),

                      if (r.observaciones != null && r.observaciones!.isNotEmpty) ...[
                        const SizedBox(height: 6),
                        Text('Notas: ${r.observaciones}', style: const TextStyle(color: Colors.white54, fontStyle: FontStyle.italic, fontSize: 10.5)),
                      ],
                    ],
                  ),
                ),
              );
            }

            // 1 + mortCount: Cabecera de Traslados
            if (index == 1 + mortCount) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 16),
                  Wrap(
                    alignment: WrapAlignment.spaceBetween,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    spacing: 8,
                    runSpacing: 4,
                    children: [
                      Text(
                        '🔄 HISTORIAL DE TRASLADOS Y DESDOBLES',
                        style: AppTypography.labelMicro.copyWith(color: AppColors.amberWarning, letterSpacing: 1.2, fontWeight: FontWeight.w800),
                      ),
                      Text(
                        '${filteredTransfers.length} eventos',
                        style: AppTypography.labelMicro.copyWith(color: textSecondary),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                ],
              );
            }

            // (2 + mortCount)..(2 + mortCount + transCount - 1): Registros de traslados o estado vacío
            if (index >= 2 + mortCount && index < 2 + mortCount + transCount) {
              if (filteredTransfers.isEmpty) {
                return const Padding(
                  padding: EdgeInsets.all(16),
                  child: Center(
                    child: Text('No hay registros de traslados para este estanque.', style: TextStyle(color: AppColors.textSecondaryDark, fontSize: 12)),
                  ),
                );
              }

              final t = filteredTransfers[index - 2 - mortCount];
              final origen = pondMap[t.estanqueOrigenId];
              final destino = pondMap[t.estanqueDestinoId];
              final fechaStr = '${t.fechaOperacion.day}/${t.fechaOperacion.month}/${t.fechaOperacion.year}';

              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: GlassContainer(
                  borderRadius: 18,
                  padding: const EdgeInsets.all(14),
                  blur: 16,
                  opacity: 0.12,
                  borderColor: AppColors.amberWarning.withValues(alpha: 0.25),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Text(
                                '${origen?.nombreLimpio ?? "Estanque"} ➔ ${destino?.nombreLimpio ?? "Estanque"}',
                                style: AppTypography.titleSmall.copyWith(color: Colors.white, fontWeight: FontWeight.w800),
                              ),
                            ],
                          ),
                          GlassBadge(
                            text: t.tipoOperacionLabel,
                            color: t.esDesdoble ? AppColors.amberWarning : AppColors.cyanWater,
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            '${t.pecesFormatted} • ${t.biomasaFormatted} • ${t.pesoPromedioGramos.toStringAsFixed(1)} g',
                            style: const TextStyle(color: AppColors.cyanWater, fontWeight: FontWeight.w700, fontSize: 11.5),
                          ),
                          Text(
                            'Costo Transf: ${t.costoTotalFormatted}',
                            style: const TextStyle(color: AppColors.greenBiomass, fontWeight: FontWeight.w800, fontSize: 11.5),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Fecha: $fechaStr ${t.nuevoCodigoLote != null ? "• Lote: ${t.nuevoCodigoLote}" : ""}',
                            style: TextStyle(color: textSecondary, fontSize: 10),
                          ),
                          Text(
                            'Resp: ${t.registradoPor ?? "Operador"}',
                            style: TextStyle(color: textSecondary, fontSize: 10),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            }

            // Footer Spacer
            return const SizedBox(height: 80);
          },
        ),
      ),
    );
  }
}

/// Helper memoizado para análisis de biometrías y cálculo de tasas de crecimiento (GDP) O(N)
class _BiometryAnalysis {
  final Map<String, double> periodGdpMap;
  final Map<String, double> weightDeltaMap;
  final Map<String, int> daysElapsedMap;
  final List<BiometriaRecord> sortedBiometries;
  final double latestAvgWeight;
  final double avgGdp;

  const _BiometryAnalysis({
    required this.periodGdpMap,
    required this.weightDeltaMap,
    required this.daysElapsedMap,
    required this.sortedBiometries,
    required this.latestAvgWeight,
    required this.avgGdp,
  });

  factory _BiometryAnalysis.compute({
    required List<BiometriaRecord> allBiometries,
    required List<FishBatch> batches,
    required String? selectedPondId,
  }) {
    final biometries = selectedPondId != null
        ? allBiometries.where((b) => b.estanqueId.trim() == selectedPondId.trim()).toList()
        : allBiometries;

    final batchByIdOrCode = <String, FishBatch>{};
    for (final b in batches) {
      batchByIdOrCode[b.id] = b;
      batchByIdOrCode[b.codigoLote] = b;
    }

    final Map<String, List<BiometriaRecord>> biometriesByBatch = {};
    for (final bio in allBiometries) {
      final key = bio.loteId.isNotEmpty ? bio.loteId : bio.estanqueId;
      biometriesByBatch.putIfAbsent(key, () => []).add(bio);
    }
    for (final list in biometriesByBatch.values) {
      list.sort((a, b) => a.fecha.compareTo(b.fecha));
    }

    final Map<String, double> periodGdpMap = {};
    final Map<String, double> weightDeltaMap = {};
    final Map<String, int> daysElapsedMap = {};

    for (final entry in biometriesByBatch.entries) {
      final list = entry.value;
      final batch = batchByIdOrCode[entry.key];

      for (int i = 0; i < list.length; i++) {
        final current = list[i];
        if (i == 0) {
          final initialWeight = batch?.pesoInicialGramos ?? 1.0;
          final stockingDate = batch?.fechaSiembra ?? current.fecha.subtract(const Duration(days: 30));
          final daysDiff = current.fecha.difference(stockingDate).inDays;
          final days = daysDiff > 0 ? daysDiff : 1;
          final deltaW = current.pesoPromedioG - initialWeight;
          final calculatedGdp = deltaW > 0 ? (deltaW / days) : (current.gdpGDia ?? 0.0);
          periodGdpMap[current.id] = current.gdpGDia ?? calculatedGdp;
          weightDeltaMap[current.id] = deltaW;
          daysElapsedMap[current.id] = days;
        } else {
          final previous = list[i - 1];
          final daysDiff = current.fecha.difference(previous.fecha).inDays;
          final days = daysDiff > 0 ? daysDiff : 1;
          final deltaW = current.pesoPromedioG - previous.pesoPromedioG;
          final calculatedGdp = days > 0 ? (deltaW / days) : 0.0;
          periodGdpMap[current.id] = current.gdpGDia ?? calculatedGdp;
          weightDeltaMap[current.id] = deltaW;
          daysElapsedMap[current.id] = days;
        }
      }
    }

    final sortedBiometries = List<BiometriaRecord>.from(biometries)..sort((a, b) => b.fecha.compareTo(a.fecha));

    final double latestAvgWeight;
    if (sortedBiometries.isNotEmpty) {
      latestAvgWeight = sortedBiometries.first.pesoPromedioG;
    } else if (batches.isNotEmpty) {
      final relevantBatches = selectedPondId != null
          ? batches.where((b) => b.estanqueId == selectedPondId).toList()
          : batches;
      latestAvgWeight = relevantBatches.isNotEmpty
          ? (relevantBatches.fold<double>(0.0, (sum, b) => sum + b.pesoActualGramos) / relevantBatches.length)
          : 0.0;
    } else {
      latestAvgWeight = 0.0;
    }

    final double avgGdp;
    if (sortedBiometries.isNotEmpty) {
      final totalGdp = sortedBiometries.fold<double>(0.0, (sum, b) => sum + (periodGdpMap[b.id] ?? b.gdpGDia ?? 0.0));
      avgGdp = totalGdp / sortedBiometries.length;
    } else {
      avgGdp = 0.0;
    }

    return _BiometryAnalysis(
      periodGdpMap: periodGdpMap,
      weightDeltaMap: weightDeltaMap,
      daysElapsedMap: daysElapsedMap,
      sortedBiometries: sortedBiometries,
      latestAvgWeight: latestAvgWeight,
      avgGdp: avgGdp,
    );
  }
}

