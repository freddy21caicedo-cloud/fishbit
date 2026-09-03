import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fishbit_finance/core/design_system/app_colors.dart';
import 'package:fishbit_finance/core/design_system/app_typography.dart';
import 'package:fishbit_finance/core/design_system/fishbit_header.dart';
import 'package:fishbit_finance/core/design_system/glass_card.dart';
import 'package:fishbit_finance/core/design_system/glass_badge.dart';
import 'package:fishbit_finance/core/design_system/glass_date_picker.dart';
import 'package:fishbit_finance/modules/water_quality/presentation/dialogs/parametro_modal.dart';
import 'package:fishbit_finance/modules/water_quality/presentation/providers/water_quality_provider.dart';
import 'package:fishbit_finance/modules/feeding_nutrition/presentation/providers/nutrition_provider.dart';

import 'package:fishbit_finance/modules/ponds_batches/presentation/providers/ponds_provider.dart';

class WaterQualityRecordsScreen extends ConsumerStatefulWidget {
  const WaterQualityRecordsScreen({super.key});

  @override
  ConsumerState<WaterQualityRecordsScreen> createState() => _WaterQualityRecordsScreenState();
}

class _WaterQualityRecordsScreenState extends ConsumerState<WaterQualityRecordsScreen> {
  CivilDateRange? _selectedRange;

  @override
  Widget build(BuildContext context) {
    final waterState = ref.watch(waterQualityProvider);
    final nutritionState = ref.watch(nutritionProvider);
    final pondsState = ref.watch(pondsProvider);

    final filteredParams = waterState.recentParameters.where((p) {
      if (_selectedRange == null) return true;
      final c = CivilDate.fromDate(p.fecha);
      if (_selectedRange!.end != null) {
        return c.isBetween(_selectedRange!.start, _selectedRange!.end!);
      }
      return c.isSameDay(_selectedRange!.start);
    }).toList();

    final filteredFeeding = nutritionState.records.where((r) {
      if (_selectedRange == null) return true;
      final c = CivilDate.fromDate(r.fecha);
      if (_selectedRange!.end != null) {
        return c.isBetween(_selectedRange!.start, _selectedRange!.end!);
      }
      return c.isSameDay(_selectedRange!.start);
    }).toList();

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        floatingActionButton: Padding(
          padding: const EdgeInsets.only(bottom: 78),
          child: FloatingActionButton.extended(
            backgroundColor: AppColors.cyanWater,
            icon: const Icon(Icons.water_drop_rounded, color: Colors.black),
            label: const Text('Registrar O₂/pH', style: TextStyle(color: Colors.black, fontWeight: FontWeight.w800)),
            onPressed: () => ParametroModal.show(context),
          ),
        ),
        body: NestedScrollView(
          headerSliverBuilder: (context, innerBoxIsScrolled) => [
            FishBitHeader(
              onRefresh: () => ref.read(waterQualityProvider.notifier).loadParameters(),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                child: Column(
                  children: [
                    GlassDatePickerField(
                      label: 'FILTRAR POR PERÍODO',
                      mode: DatePickerSelectionMode.range,
                      initialRange: _selectedRange,
                      accentColor: AppColors.cyanWater,
                      placeholder: 'Todas las fechas (Toca para filtrar)',
                      onRangeChanged: (range) => setState(() => _selectedRange = range),
                    ),
                    if (_selectedRange != null) ...[
                      const SizedBox(height: 4),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          TextButton.icon(
                            icon: const Icon(Icons.close_rounded, size: 14, color: AppColors.coralAction),
                            label: const Text('Limpiar filtro', style: TextStyle(color: AppColors.coralAction, fontSize: 11, fontWeight: FontWeight.bold)),
                            onPressed: () => setState(() => _selectedRange = null),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: Container(
                color: Colors.transparent,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                child: const TabBar(
                  indicatorColor: AppColors.cyanWater,
                  indicatorWeight: 3,
                  labelColor: AppColors.cyanWater,
                  unselectedLabelColor: AppColors.textSecondaryDark,
                  tabs: [
                    Tab(text: 'Calidad de Agua (O₂ / pH)'),
                    Tab(text: 'Alimentación Diaria'),
                  ],
                ),
              ),
            ),
          ],
          body: TabBarView(
            children: [
              // Pestaña 1: Calidad de Agua
              ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: GlassCard(
                          title: 'Oxígeno Óptimo',
                          glowColor: AppColors.cyanWater,
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            alignment: Alignment.centerLeft,
                            child: Text('5.5 - 7.0 mg/L', style: AppTypography.titleMedium.copyWith(color: AppColors.cyanWater)),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: GlassCard(
                          title: 'pH Rango',
                          glowColor: AppColors.greenBiomass,
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            alignment: Alignment.centerLeft,
                            child: Text('6.8 - 7.8', style: AppTypography.titleMedium.copyWith(color: AppColors.greenBiomass)),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text('HISTORIAL DE MEDICIONES (${filteredParams.length})', style: AppTypography.labelMicro.copyWith(color: AppColors.textSecondaryDark, letterSpacing: 1.5)),
                  const SizedBox(height: 10),
                  if (filteredParams.isEmpty)
                    Padding(
                      padding: const EdgeInsets.all(32),
                      child: Center(
                        child: Text('No hay mediciones registradas en este período.', style: AppTypography.bodyMedium.copyWith(color: AppColors.textSecondaryDark)),
                      ),
                    )
                  else
                    ...filteredParams.map((p) {
                      final pond = pondsState.ponds.where((pond) => pond.id == p.estanqueId).firstOrNull;
                      final pondTitulo = pond != null ? pond.nombreLimpio : 'Estanque';
                      final pondSigla = pond != null ? pond.sigla.split('-').first.trim() : '';
                      final horaStr = '${p.fecha.hour.toString().padLeft(2, '0')}:${p.fecha.minute.toString().padLeft(2, '0')}';
                      final isHypoxia = (p.oxigenoMgL ?? 6.0) < 4.0;

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: GlassCard(
                          title: '$pondTitulo ${pondSigla.isNotEmpty ? "($pondSigla)" : ""}',
                          subtitle: '${p.fecha.day}/${p.fecha.month}/${p.fecha.year} • ⏰ $horaStr',
                          trailingWidget: GlassBadge(
                            text: '${(p.oxigenoMgL ?? 6.0).toStringAsFixed(1)} mg/L O₂',
                            color: isHypoxia ? AppColors.coralAction : AppColors.cyanWater,
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Wrap(
                                spacing: 12,
                                runSpacing: 4,
                                children: [
                                  Text('pH: ${(p.ph ?? 7.2).toStringAsFixed(1)}', style: AppTypography.bodySmall),
                                  Text('Temp: ${(p.temperaturaC ?? 28.0).toStringAsFixed(1)}°C', style: AppTypography.bodySmall),
                                  if (p.amonioMgL != null) Text('Amonio: ${p.amonioMgL} ppm', style: AppTypography.bodySmall),
                                  if (p.nitritosMgL != null) Text('NO₂: ${p.nitritosMgL} ppm', style: AppTypography.bodySmall),
                                  if (p.nitratosMgL != null) Text('NO₃: ${p.nitratosMgL} ppm', style: AppTypography.bodySmall),
                                  if (p.alcalinidadMgL != null) Text('Alcalinidad: ${p.alcalinidadMgL!.toInt()} ppm', style: AppTypography.bodySmall),
                                  if (p.co2MgL != null) Text('CO₂: ${p.co2MgL} ppm', style: AppTypography.bodySmall),
                                  if (p.durezaMgL != null) Text('Dureza: ${p.durezaMgL!.toInt()} ppm', style: AppTypography.bodySmall),
                                  if (p.cloroMgL != null) Text('Cloro: ${p.cloroMgL} ppm', style: AppTypography.bodySmall),
                                ],
                              ),
                              if (p.observaciones != null && p.observaciones!.isNotEmpty) ...[
                                const SizedBox(height: 4),
                                Text('Nota: ${p.observaciones}', style: const TextStyle(color: Colors.white54, fontSize: 11, fontStyle: FontStyle.italic)),
                              ],
                            ],
                          ),
                        ),
                      );
                    }),
                  const SizedBox(height: 100),
                ],
              ),

              // Pestaña 2: Alimentación Diaria
              ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  Text('REGISTRO DE RACIONES CONSUMIDAS (${filteredFeeding.length})', style: AppTypography.labelMicro.copyWith(color: AppColors.textSecondaryDark, letterSpacing: 1.5)),
                  const SizedBox(height: 10),
                  if (filteredFeeding.isEmpty)
                    Padding(
                      padding: const EdgeInsets.all(32),
                      child: Center(
                        child: Text('No hay registros de alimentación en este período.', style: AppTypography.bodyMedium.copyWith(color: AppColors.textSecondaryDark)),
                      ),
                    )
                  else
                    ...filteredFeeding.map((rec) => Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: GlassCard(
                            title: 'Lote ${rec.loteId.substring(0, 6)}',
                            subtitle: 'Fecha: ${rec.fecha.day}/${rec.fecha.month}/${rec.fecha.year}',
                            trailingWidget: GlassBadge(text: '${rec.cantidadConsumidaKg} kg', color: AppColors.greenBiomass),
                            child: Text(
                              'Costo Alimento: \$${rec.costoCalculado.toStringAsFixed(0)}',
                              style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondaryDark),
                            ),
                          ),
                        )),
                  const SizedBox(height: 100),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
