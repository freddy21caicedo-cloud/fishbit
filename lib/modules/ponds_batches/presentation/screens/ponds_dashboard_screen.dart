import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fishbit_finance/core/design_system/app_colors.dart';
import 'package:fishbit_finance/core/design_system/app_typography.dart';
import 'package:fishbit_finance/core/design_system/fade_content.dart';
import 'package:fishbit_finance/core/design_system/fishbit_header.dart';
import 'package:fishbit_finance/core/design_system/floating_dock_layout.dart';
import 'package:fishbit_finance/modules/auth_tenant/presentation/providers/auth_provider.dart';
import 'package:fishbit_finance/modules/ponds_batches/domain/models/pond.dart';
import 'package:fishbit_finance/modules/ponds_batches/domain/models/fish_batch.dart';
import 'package:fishbit_finance/modules/ponds_batches/presentation/dialogs/crear_estanque_modal.dart';
import 'package:fishbit_finance/modules/ponds_batches/presentation/dialogs/siembra_modal.dart';
import 'package:fishbit_finance/modules/ponds_batches/presentation/providers/ponds_provider.dart';
import 'package:fishbit_finance/modules/ponds_batches/presentation/widgets/pond_bento_card.dart';
import 'package:fishbit_finance/modules/water_quality/presentation/providers/water_quality_provider.dart';

class PondsDashboardScreen extends ConsumerStatefulWidget {
  const PondsDashboardScreen({super.key});

  @override
  ConsumerState<PondsDashboardScreen> createState() => _PondsDashboardScreenState();
}

class _PondsDashboardScreenState extends ConsumerState<PondsDashboardScreen> {
  int _selectedFilterIndex = 0; // 0: Todos, 1: Activos, 2: Disponibles

  @override
  Widget build(BuildContext context) {
    final isLoading = ref.watch(pondsProvider.select((s) => s.isLoading));
    final ponds = ref.watch(pondsProvider.select((s) => s.ponds));
    final batchesByPond = ref.watch(activeBatchesByPondProvider);
    final waterQualityByPond = ref.watch(latestWaterQualityByPondProvider);
    final targetWeightsBySpecies = ref.watch(
      authProvider.select((s) => s.currentCompany?.pesosFinalesEspeciesG),
    );

    final filteredPonds = switch (_selectedFilterIndex) {
      1 => ponds.where((p) => p.estado == PondStatus.active).toList(),
      2 => ponds.where((p) => p.estado != PondStatus.active).toList(),
      _ => ponds,
    };

    return Scaffold(
      backgroundColor: Colors.transparent,
      floatingActionButtonLocation: FloatingDockFabLocation.endFloat,
      floatingActionButton: const _PondsSpeedDialFab(),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isWide = constraints.maxWidth > 700;

          return RefreshIndicator(
            color: AppColors.cyanWater,
            backgroundColor: AppColors.surfaceDark,
            onRefresh: () async {
              await ref.read(pondsProvider.notifier).loadPondsAndBatches();
            },
            child: CustomScrollView(
              slivers: [
                // Barra de navegación superior unificada FishBitHeader
                FishBitHeader(
                  onRefresh: () => ref.read(pondsProvider.notifier).loadPondsAndBatches(),
                ),

                // Barra de Filtros Segmentados
                SliverToBoxAdapter(
                  child: FadeContent(
                    delay: const Duration(milliseconds: 30),
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Barra de Filtros Segmentados
                          Wrap(
                            alignment: WrapAlignment.spaceBetween,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    'ESTANQUES (${filteredPonds.length})',
                                    style: AppTypography.labelMicro.copyWith(
                                      color: AppColors.textSecondaryDark,
                                      letterSpacing: 1.2,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  InkWell(
                                    onTap: () {
                                      showDialog<void>(
                                        context: context,
                                        barrierColor: Colors.black.withAlpha(160),
                                        builder: (_) => const CrearEstanqueModal(),
                                      );
                                    },
                                    borderRadius: BorderRadius.circular(16),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                      decoration: BoxDecoration(
                                        color: AppColors.cyanWater.withAlpha(25),
                                        borderRadius: BorderRadius.circular(16),
                                        border: Border.all(color: AppColors.cyanWater.withAlpha(80), width: 0.8),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          const Icon(Icons.add_rounded, size: 13, color: AppColors.cyanWater),
                                          const SizedBox(width: 3),
                                          Text(
                                            'Nuevo',
                                            style: AppTypography.labelMicro.copyWith(
                                              color: AppColors.cyanWater,
                                              fontWeight: FontWeight.w700,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              Wrap(
                                spacing: 6,
                                crossAxisAlignment: WrapCrossAlignment.center,
                                children: [
                                  _buildFilterChip(label: 'Todos', index: 0),
                                  _buildFilterChip(label: 'Activos', index: 1),
                                  _buildFilterChip(label: 'Vacíos', index: 2),
                                ],
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                        ],
                      ),
                    ),
                  ),
                ),

                // Listado o Grid Adaptable de Estanques Bento Cards
                if (isLoading)
                  const SliverFillRemaining(
                    child: Center(child: CircularProgressIndicator(color: AppColors.cyanWater)),
                  )
                else if (filteredPonds.isEmpty)
                  SliverFillRemaining(
                    child: Center(
                      child: Text(
                        'No hay estanques en esta categoría.',
                        style: AppTypography.bodyMedium.copyWith(color: AppColors.textSecondaryDark),
                      ),
                    ),
                  )
                else if (isWide)
                  SliverPadding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    sliver: SliverGrid(
                      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                        maxCrossAxisExtent: 440,
                        mainAxisExtent: 390,
                        crossAxisSpacing: 16,
                        mainAxisSpacing: 16,
                      ),
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          final pond = filteredPonds[index];
                          final activeBatches = batchesByPond[pond.id] ?? const <FishBatch>[];
                          final primaryBatch = activeBatches.firstOrNull;

                          return FadeContent(
                            delay: Duration(milliseconds: 90 + (index.clamp(0, 6) * 75)),
                            child: PondBentoCard(
                              pond: pond,
                              batch: primaryBatch,
                              batches: activeBatches,
                              latestWaterParameter: waterQualityByPond[pond.id],
                              targetWeightsBySpecies: targetWeightsBySpecies,
                            ),
                          );
                        },
                        childCount: filteredPonds.length,
                        addAutomaticKeepAlives: true,
                        addRepaintBoundaries: true,
                      ),
                    ),
                  )
                else
                  SliverPadding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          final pond = filteredPonds[index];
                          final activeBatches = batchesByPond[pond.id] ?? const <FishBatch>[];
                          final primaryBatch = activeBatches.firstOrNull;

                          return Padding(
                            padding: const EdgeInsets.only(bottom: 16),
                            child: FadeContent(
                              delay: Duration(milliseconds: 90 + (index.clamp(0, 6) * 75)),
                              child: PondBentoCard(
                                pond: pond,
                                batch: primaryBatch,
                                batches: activeBatches,
                                latestWaterParameter: waterQualityByPond[pond.id],
                                targetWeightsBySpecies: targetWeightsBySpecies,
                              ),
                            ),
                          );
                        },
                        childCount: filteredPonds.length,
                        addAutomaticKeepAlives: true,
                        addRepaintBoundaries: true,
                      ),
                    ),
                  ),

                const SliverDockBottomSpacer(),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildFilterChip({required String label, required int index}) {
    final isSelected = _selectedFilterIndex == index;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return InkWell(
      onTap: () => setState(() => _selectedFilterIndex = index),
      borderRadius: BorderRadius.circular(10),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.cyanWater.withValues(alpha: isDark ? 0.18 : 0.12)
              : (isDark ? Colors.white.withValues(alpha: 0.04) : Colors.white.withValues(alpha: 0.85)),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected
                ? AppColors.cyanWater
                : (isDark ? Colors.white.withValues(alpha: 0.1) : AppColors.glassBorderLight),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected
                ? AppColors.cyanWater
                : (isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight),
            fontSize: 11,
            fontWeight: isSelected ? FontWeight.w800 : FontWeight.w500,
          ),
        ),
      ),
    );
  }
}

class _PondsSpeedDialFab extends StatefulWidget {
  const _PondsSpeedDialFab();

  @override
  State<_PondsSpeedDialFab> createState() => _PondsSpeedDialFabState();
}

class _PondsSpeedDialFabState extends State<_PondsSpeedDialFab> {
  bool _isOpen = false;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        if (_isOpen) ...[
          InkWell(
            onTap: () {
              setState(() => _isOpen = false);
              CrearEstanqueModal.show(context);
            },
            borderRadius: BorderRadius.circular(16),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: AppColors.surfaceDark,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.cyanWater.withValues(alpha: 0.4)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.35),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.waves_rounded, color: AppColors.cyanWater, size: 18),
                  const SizedBox(width: 8),
                  Text(
                    'Nuevo Estanque',
                    style: AppTypography.titleSmall.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 10),
          InkWell(
            onTap: () {
              setState(() => _isOpen = false);
              SiembraModal.show(context);
            },
            borderRadius: BorderRadius.circular(16),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: AppColors.surfaceDark,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.greenBiomass.withValues(alpha: 0.4)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.35),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.add_circle_outline_rounded, color: AppColors.greenBiomass, size: 18),
                  const SizedBox(width: 8),
                  Text(
                    'Sembrar Lote',
                    style: AppTypography.titleSmall.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
        ],
        FloatingActionButton.extended(
          backgroundColor: _isOpen ? AppColors.coralAction : AppColors.cyanWater,
          icon: AnimatedRotation(
            turns: _isOpen ? 0.125 : 0.0,
            duration: const Duration(milliseconds: 200),
            child: Icon(_isOpen ? Icons.close_rounded : Icons.add_rounded, color: Colors.black),
          ),
          label: Text(
            _isOpen ? 'Cerrar' : 'Acción Rápida',
            style: const TextStyle(color: Colors.black, fontWeight: FontWeight.w800),
          ),
          onPressed: () => setState(() => _isOpen = !_isOpen),
        ),
      ],
    );
  }
}
