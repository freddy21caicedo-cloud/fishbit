import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fishbit_finance/core/design_system/app_colors.dart';
import 'package:fishbit_finance/core/design_system/app_typography.dart';
import 'package:fishbit_finance/core/design_system/fishbit_header.dart';
import 'package:fishbit_finance/core/design_system/glass_card.dart';
import 'package:fishbit_finance/core/design_system/floating_dock_layout.dart';
import 'package:fishbit_finance/core/design_system/glass_container.dart';
import 'package:fishbit_finance/core/design_system/glass_badge.dart';
import 'package:fishbit_finance/core/design_system/glass_select_field.dart';
import 'package:fishbit_finance/core/design_system/hero_tabs.dart';
import 'package:fishbit_finance/core/utils/currency_formatters.dart';
import 'package:fishbit_finance/modules/auth_tenant/presentation/providers/auth_provider.dart';
import 'package:fishbit_finance/modules/water_quality/domain/models/water_parameter.dart';
import 'package:fishbit_finance/modules/water_quality/presentation/dialogs/parametro_modal.dart';
import 'package:fishbit_finance/modules/water_quality/presentation/providers/water_quality_provider.dart';
import 'package:fishbit_finance/modules/feeding_nutrition/domain/models/feeding_record.dart';
import 'package:fishbit_finance/modules/feeding_nutrition/presentation/providers/nutrition_provider.dart';
import 'package:fishbit_finance/modules/ponds_batches/presentation/providers/ponds_provider.dart';
import 'package:fishbit_finance/modules/ponds_batches/domain/models/pond.dart';
import 'package:fishbit_finance/modules/ponds_batches/domain/models/fish_batch.dart';
import 'package:fishbit_finance/modules/ponds_batches/domain/models/biometria_record.dart';
import 'package:fishbit_finance/modules/ponds_batches/domain/models/mortality_record.dart';
import 'package:fishbit_finance/modules/ponds_batches/domain/models/transfer_record.dart';
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

  @override
  Widget build(BuildContext context) {
    final currentUser = ref.watch(authProvider).currentUser;
    final isAdmin = (currentUser?.isAdmin ?? false) || (currentUser?.isCreator ?? false);
    final waterState = ref.watch(waterQualityProvider);
    final nutritionState = ref.watch(nutritionProvider);
    final pondsState = ref.watch(pondsProvider);

    // O(M) indexación para lookups O(1) en los builders virtuales
    final pondMap = {for (final p in pondsState.ponds) p.id: p};
    final batchMap = {for (final b in pondsState.batches) b.id: b};

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          NestedScrollView(
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
                  child: Builder(
                    builder: (context) {
                      final totalDataCount = waterState.recentParameters.length +
                          nutritionState.records.length +
                          pondsState.biometries.length +
                          pondsState.mortalityRecords.length;

                      final options = <GlassSelectOption<String>>[
                        GlassSelectOption<String>(
                          value: '__ALL__',
                          label: 'Todos los Estanques (${pondsState.ponds.length})',
                          subtitle: 'Filtra las 4 pestañas simultáneamente',
                          icon: Icons.grid_view_rounded,
                          badgeText: '$totalDataCount datos',
                          badgeColor: AppColors.cyanWater,
                        ),
                        ...pondsState.ponds.map((pond) {
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

                          return GlassSelectOption<String>(
                            value: pond.id,
                            label: '${pond.sigla} • ${pond.nombreLimpio}',
                            subtitle: subtitle,
                            icon: Icons.water_rounded,
                            badgeText: '$pondTotal datos',
                            badgeColor: pondTotal > 0 ? AppColors.cyanWater : AppColors.textSecondaryDark,
                          );
                        }),
                      ];

                      return GlassSelectField<String>(
                        label: 'ESTANQUE DE CONSULTA',
                        placeholder: 'Buscar estanque por nombre o sigla...',
                        value: _selectedPondId ?? '__ALL__',
                        accentColor: AppColors.cyanWater,
                        leadingIcon: Icons.tune_rounded,
                        options: options,
                        onChanged: (val) {
                          setState(() {
                            _selectedPondId = (val == null || val == '__ALL__') ? null : val;
                          });
                        },
                      );
                    },
                  ),
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1024),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                  child: Center(
                    child: HeroTabsBar(
                      controller: _tabController,
                      tabs: const [
                        HeroTabItem(
                          key: Key('tab_calidad_agua'),
                          label: 'Calidad de Agua',
                          icon: Icons.water_drop_rounded,
                          accentColor: AppColors.cyanWater,
                        ),
                        HeroTabItem(
                          key: Key('tab_alimentacion'),
                          label: 'Alimentación',
                          icon: Icons.restaurant_rounded,
                          accentColor: AppColors.greenBiomass,
                        ),
                        HeroTabItem(
                          key: Key('tab_biometrias'),
                          label: 'Biometrías y GDP',
                          icon: Icons.scale_rounded,
                          accentColor: Colors.purpleAccent,
                        ),
                        HeroTabItem(
                          key: Key('tab_bajas'),
                          label: 'Bajas y Sanidad',
                          icon: Icons.warning_amber_rounded,
                          accentColor: AppColors.coralAction,
                        ),
                      ],
                    ),
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
            _buildWaterQualityTab(context, waterState, pondsState, pondMap, isAdmin),

            // Pestaña 2: Alimentación Diaria
            _buildFeedingTab(context, nutritionState, pondsState, pondMap, batchMap, isAdmin),

            // Pestaña 3: Biometrías y Curvas (GDP)
            _buildBiometryTab(context, pondsState, pondMap, batchMap, isAdmin),

            // Pestaña 4: Mortalidad y Sanidad (Bajas)
            _buildMortalityTab(context, pondsState, pondMap, batchMap, isAdmin),
          ],
        ),
      ),

          // Botón flotante desplegable vertical unilateral (Estilo Uiverse risabbir)
          Positioned.fill(
            child: _BitacoraVerticalSpeedDial(
              bottomOffset:
                  FloatingDockLayout.dockTopOffset(context) + FloatingDockLayout.fabDockGap,
              actions: [
                _BitacoraDialAction(
                  label: 'O₂ y pH',
                  icon: Icons.water_drop_rounded,
                  onTap: () => ParametroModal.show(context, preselectedPondId: _selectedPondId),
                ),
                _BitacoraDialAction(
                  label: 'Alimentar',
                  icon: Icons.restaurant_rounded,
                  onTap: () {
                    final targetPond = _selectedPondId != null
                        ? ref.read(pondsProvider).ponds.where((p) => p.id == _selectedPondId).firstOrNull
                        : null;
                    AlimentarModal.show(context, pond: targetPond);
                  },
                ),
                _BitacoraDialAction(
                  label: 'Biometría',
                  icon: Icons.scale_rounded,
                  onTap: () {
                    final targetPond = _selectedPondId != null
                        ? ref.read(pondsProvider).ponds.where((p) => p.id == _selectedPondId).firstOrNull
                        : null;
                    BiometriaModal.show(context, pond: targetPond);
                  },
                ),
                _BitacoraDialAction(
                  label: 'Bajas / Mort.',
                  icon: Icons.warning_amber_rounded,
                  onTap: () {
                    final targetPond = _selectedPondId != null
                        ? ref.read(pondsProvider).ponds.where((p) => p.id == _selectedPondId).firstOrNull
                        : null;
                    MortalidadModal.show(context, pond: targetPond);
                  },
                ),
                _BitacoraDialAction(
                  label: 'Traslado',
                  icon: Icons.swap_horiz_rounded,
                  onTap: () {
                    final targetPond = _selectedPondId != null
                        ? ref.read(pondsProvider).ponds.where((p) => p.id == _selectedPondId).firstOrNull
                        : null;
                    TrasladoModal.show(context, pond: targetPond);
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAdminActionButtons({
    VoidCallback? onEdit,
    required VoidCallback onDelete,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (onEdit != null)
          IconButton(
            tooltip: 'Editar registro',
            visualDensity: VisualDensity.compact,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
            icon: const Icon(Icons.edit_outlined, size: 16, color: AppColors.cyanWater),
            onPressed: onEdit,
          ),
        IconButton(
          tooltip: 'Eliminar registro',
          visualDensity: VisualDensity.compact,
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
          icon: const Icon(Icons.delete_outline_rounded, size: 16, color: AppColors.coralAction),
          onPressed: onDelete,
        ),
      ],
    );
  }

  Future<void> _confirmDeleteRecord(
    BuildContext context, {
    required String title,
    required String message,
    required Future<bool> Function() onConfirm,
    required String successMessage,
  }) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surfaceDark,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 16)),
        content: Text(message, style: const TextStyle(color: AppColors.textSecondaryDark, fontSize: 13)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancelar', style: TextStyle(color: Colors.white70)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.coralAction,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Eliminar', style: TextStyle(fontWeight: FontWeight.w800)),
          ),
        ],
      ),
    );

    if (confirm == true && context.mounted) {
      final messenger = ScaffoldMessenger.of(context);
      final ok = await onConfirm();
      if (context.mounted) {
        messenger.showSnackBar(
          SnackBar(
            content: Text(ok ? successMessage : 'No se pudo eliminar el registro. Verifica tus permisos de administrador.'),
            backgroundColor: ok ? AppColors.coralAction : AppColors.amberWarning,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Widget _buildWaterQualityTab(
    BuildContext context,
    WaterQualityState waterState,
    PondsState pondsState,
    Map<String, Pond> pondMap,
    bool isAdmin,
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
              return const DockBottomSpacer(extra: 48.0);
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
                        if (isAdmin) ...[
                          const SizedBox(width: 4),
                          _buildAdminActionButtons(
                            onEdit: () => ParametroModal.show(context, parameterToEdit: p),
                            onDelete: () => _confirmDeleteRecord(
                              context,
                              title: 'Eliminar Medición de Agua',
                              message: '¿Deseas eliminar esta medición fisicoquímica de $pondTitulo ($fechaStr • $horaStr)?',
                              onConfirm: () => ref.read(waterQualityProvider.notifier).deleteWaterQuality(p.id),
                              successMessage: 'Medición de calidad de agua eliminada.',
                            ),
                          ),
                        ],
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
                    if (p.amonioMgL != null || p.nitritosMgL != null || p.nitratosMgL != null) ...[
                      Wrap(
                        spacing: 12,
                        runSpacing: 4,
                        children: [
                          if (p.amonioMgL != null)
                            Text('Amonio: ${p.amonioMgL!.toStringAsFixed(2)} ppm',
                                style: TextStyle(color: p.amonioMgL! > 0.5 ? AppColors.coralAction : textSecondary, fontSize: 11, fontWeight: FontWeight.w600)),
                          if (p.nitritosMgL != null)
                            Text('Nitrito NO₂: ${p.nitritosMgL!.toStringAsFixed(2)} ppm',
                                style: TextStyle(color: p.nitritosMgL! > 0.2 ? AppColors.coralAction : textSecondary, fontSize: 11)),
                          if (p.nitratosMgL != null)
                            Text('Nitrato NO₃: ${p.nitratosMgL!.toStringAsFixed(1)} ppm',
                                style: TextStyle(color: textSecondary, fontSize: 11)),
                        ],
                      ),
                      const SizedBox(height: 4),
                    ],

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
    bool isAdmin,
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
              return const DockBottomSpacer(extra: 48.0);
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
                    if (isAdmin) ...[
                      const SizedBox(width: 4),
                      _buildAdminActionButtons(
                        onEdit: () => AlimentarModal.show(
                          context,
                          pond: pond,
                          batch: batch,
                          recordToEdit: r,
                        ),
                        onDelete: () => _confirmDeleteRecord(
                          context,
                          title: 'Eliminar Registro de Alimentación',
                          message:
                              '¿Deseas eliminar esta ración de ${r.cantidadConsumidaKg.toStringAsFixed(1)} kg en $pondTitulo? Se reintegrará el alimento al inventario de Almacén y se recalculará el costo del lote.',
                          onConfirm: () => ref.read(nutritionProvider.notifier).deleteDailyFeeding(r),
                          successMessage: 'Alimentación eliminada y stock reintegrado en Almacén.',
                        ),
                      ),
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

  Widget _buildBiometryTab(
    BuildContext context,
    PondsState pondsState,
    Map<String, Pond> pondMap,
    Map<String, FishBatch> batchMap,
    bool isAdmin,
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
              return const DockBottomSpacer(extra: 48.0);
            }

            final bio = sortedBiometries[index - 1];
            final pond = pondMap[bio.estanqueId];
            final pondTitulo = pond != null ? pond.nombreLimpio : 'Estanque';
            final batch = batchMap[bio.loteId];
            final loteStr = batch != null ? 'Lote ${batch.codigoLote}' : (bio.loteId.isNotEmpty ? 'Lote ${bio.loteId}' : 'Lote Principal');
            final especieStr = batch?.especie ?? pond?.especieActual ?? 'Tilapia';
            final fechaStr = '${bio.fecha.day}/${bio.fecha.month}/${bio.fecha.year}';
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
                              GlassBadge(text: fechaStr, color: Colors.white70),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        GlassBadge(
                          text: '+${periodGdp.toStringAsFixed(2)} g/d',
                          color: periodGdp >= 1.5 ? AppColors.greenBiomass : (periodGdp >= 0.8 ? AppColors.cyanWater : AppColors.amberWarning),
                        ),
                        if (isAdmin) ...[
                          const SizedBox(width: 4),
                          _buildAdminActionButtons(
                            onEdit: () => BiometriaModal.show(
                              context,
                              pond: pond,
                              batch: batch,
                              recordToEdit: bio,
                            ),
                            onDelete: () => _confirmDeleteRecord(
                              context,
                              title: 'Eliminar Muestreo Biométrico',
                              message:
                                  '¿Deseas eliminar la biometría de $pondTitulo (${bio.pesoPromedioG.toStringAsFixed(1)} g)? El peso promedio y la biomasa del lote se recalcularán automáticamente.',
                              onConfirm: () => ref.read(pondsProvider.notifier).deleteBiometry(bio),
                              successMessage: 'Biometría eliminada y biomasa del lote recalculada.',
                            ),
                          ),
                        ],
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
    bool isAdmin,
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
                          if (isAdmin) ...[
                            const SizedBox(width: 4),
                            _buildAdminActionButtons(
                              onEdit: () => MortalidadModal.show(
                                context,
                                pond: pond,
                                batch: batch,
                                recordToEdit: r,
                              ),
                              onDelete: () => _confirmDeleteRecord(
                                context,
                                title: 'Eliminar Registro de Mortalidad',
                                message:
                                    '¿Deseas eliminar este reporte de ${r.cantidadPecesMuertos} bajas en $pondTitulo? Los peces se reintegrarán al inventario vivo del lote.',
                                onConfirm: () => ref.read(pondsProvider.notifier).deleteMortality(r),
                                successMessage: 'Registro de mortalidad eliminado y población del lote restaurada.',
                              ),
                            ),
                          ],
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
                          Expanded(
                            child: Text(
                              '${origen?.nombreLimpio ?? "Estanque"} ➔ ${destino?.nombreLimpio ?? "Estanque"}',
                              overflow: TextOverflow.ellipsis,
                              style: AppTypography.titleSmall.copyWith(color: Colors.white, fontWeight: FontWeight.w800),
                            ),
                          ),
                          GlassBadge(
                            text: t.tipoOperacionLabel,
                            color: t.esDesdoble ? AppColors.amberWarning : AppColors.cyanWater,
                          ),
                          if (isAdmin) ...[
                            const SizedBox(width: 4),
                            _buildAdminActionButtons(
                              onEdit: null,
                              onDelete: () => _confirmDeleteRecord(
                                context,
                                title: 'Revertir y Eliminar Traslado',
                                message: t.esDesdoble
                                    ? '¿Deseas revertir este desdoble de ${t.pecesTrasladados} peces? Se reintegrarán al lote origen y se ajustarán ambos estanques.'
                                    : '¿Deseas revertir este traslado total hacia ${destino?.nombreLimpio ?? "destino"} y devolver el lote a ${origen?.nombreLimpio ?? "origen"}?',
                                onConfirm: () => ref.read(pondsProvider.notifier).deleteTransfer(t),
                                successMessage: 'Traslado revertido y eliminado correctamente.',
                              ),
                            ),
                          ],
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
            return const DockBottomSpacer(extra: 48.0);
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
      list.sort((a, b) {
        final cmp = a.fecha.compareTo(b.fecha);
        if (cmp != 0) return cmp;
        return a.creadoEn.compareTo(b.creadoEn);
      });
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

    final sortedBiometries = List<BiometriaRecord>.from(biometries)
      ..sort((a, b) {
        final cmp = b.fecha.compareTo(a.fecha);
        if (cmp != 0) return cmp;
        return b.creadoEn.compareTo(a.creadoEn);
      });

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

class _BitacoraDialAction {
  final String label;
  final IconData icon;
  final VoidCallback onTap;

  const _BitacoraDialAction({
    required this.label,
    required this.icon,
    required this.onTap,
  });
}

/// Speed Dial vertical unilateral hacia arriba inspirado en Uiverse (`risabbir`).
class _BitacoraVerticalSpeedDial extends StatefulWidget {
  final double bottomOffset;
  final List<_BitacoraDialAction> actions;

  const _BitacoraVerticalSpeedDial({
    required this.bottomOffset,
    required this.actions,
  });

  @override
  State<_BitacoraVerticalSpeedDial> createState() =>
      _BitacoraVerticalSpeedDialState();
}

class _BitacoraVerticalSpeedDialState extends State<_BitacoraVerticalSpeedDial>
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
        // Scrim para cerrar al tocar fuera cuando está abierto
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

        // Sub-botones desplegándose verticalmente hacia arriba desde el botón +
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
            reverseCurve: Interval(
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
                right: 24, // Alineado al centro del botón de 64px (16 + 8)
                bottom: widget.bottomOffset + 8 + dy,
                child: Opacity(
                  opacity: opacityAnim.value.clamp(0.0, 1.0),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // Etiqueta lateral
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

                      // Círculo blanco 48x48 (risabbir)
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

        // Botón principal 64x64 (#3b82f6 -> #2563eb, icono + rota 45°)
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
                    turns: _isOpen ? 0.125 : 0.0, // 45°
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

