import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:fishbit_finance/core/design_system/app_colors.dart';
import 'package:fishbit_finance/core/design_system/app_typography.dart';
import 'package:fishbit_finance/core/design_system/glass_card.dart';
import 'package:fishbit_finance/core/design_system/glass_badge.dart';
import 'package:fishbit_finance/core/utils/currency_formatters.dart';
import 'package:fishbit_finance/modules/ponds_batches/domain/models/pond.dart';
import 'package:fishbit_finance/modules/ponds_batches/domain/models/fish_batch.dart';
import 'package:fishbit_finance/modules/water_quality/domain/models/water_parameter.dart';

/// Tarjeta Bento de Estanque Interactiva Optimizada a 60/120 FPS con efecto 3D Flip de 180°
/// - Cara Frontal: Resumen Operativo, Calidad de Agua, Densidad y Progreso de Talla.
/// - Cara Trasera (Reverso 180°): Radiografía Biológica y Financiera por Especie / Policultivo.
class PondBentoCard extends StatefulWidget {
  final Pond pond;
  final FishBatch? batch;
  final List<FishBatch> batches;
  final WaterParameter? latestWaterParameter;
  final Map<String, dynamic>? targetWeightsBySpecies;

  const PondBentoCard({
    super.key,
    required this.pond,
    this.batch,
    this.batches = const [],
    this.latestWaterParameter,
    this.targetWeightsBySpecies,
  });

  @override
  State<PondBentoCard> createState() => _PondBentoCardState();
}

class _PondBentoCardState extends State<PondBentoCard> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _animation;
  int _selectedBatchIndex = 0;
  bool _showConsolidated = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 550),
    );

    _animation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOutCubic,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _flipCard() {
    if (_controller.isAnimating) return;
    if (_controller.value >= 0.5) {
      _controller.reverse();
    } else {
      _controller.forward();
    }
  }

  @override
  Widget build(BuildContext context) {
    final allBatches = widget.batches.isNotEmpty
        ? widget.batches
        : (widget.batch != null ? [widget.batch!] : <FishBatch>[]);
    final isPolyculture = allBatches.length > 1;
    final isActive = widget.pond.estado == PondStatus.active || allBatches.isNotEmpty;

    // Instanciación perezosa por cara y salto de Transform 3D en reposo para fluidez 60/120 FPS
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, _) {
        final v = _animation.value;
        if (v == 0.0) {
          return RepaintBoundary(
            child: _buildFrontCard(context, allBatches, isPolyculture, isActive),
          );
        }
        if (v == 1.0) {
          return RepaintBoundary(
            child: _buildBackCard(context, allBatches, isPolyculture, isActive),
          );
        }

        final angle = v * math.pi;
        final isFront = angle <= math.pi / 2;

        return Transform(
          alignment: FractionalOffset.center,
          transform: Matrix4.identity()
            ..setEntry(3, 2, 0.0015) // Perspectiva 3D solo durante el giro
            ..rotateY(angle),
          child: isFront
              ? RepaintBoundary(
                  child: _buildFrontCard(context, allBatches, isPolyculture, isActive),
                )
              : Transform(
                  alignment: FractionalOffset.center,
                  transform: Matrix4.identity()..rotateY(math.pi),
                  child: RepaintBoundary(
                    child: _buildBackCard(context, allBatches, isPolyculture, isActive),
                  ),
                ),
        );
      },
    );
  }

  // ---------------------------------------------------------------------------
  // CARA FRONTAL: Resumen Operativo, Calidad de Agua, Densidad y Progreso
  // ---------------------------------------------------------------------------
  Widget _buildFrontCard(
    BuildContext context,
    List<FishBatch> allBatches,
    bool isPolyculture,
    bool isActive,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final totalPeces = allBatches.fold(0, (sum, b) => sum + b.cantidadActualPeces);
    final totalBiomasa = allBatches.fold(0.0, (sum, b) => sum + b.biomasaActualKg);
    final displayBiomasa = totalBiomasa > 0 ? totalBiomasa : widget.pond.biomasaKg;
    final capacidadM3 = widget.pond.capacidadM3 > 0
        ? widget.pond.capacidadM3
        : (((widget.pond.largoM ?? 0) * (widget.pond.anchoM ?? 0) * (widget.pond.profundidadM ?? 0)) > 0
            ? ((widget.pond.largoM ?? 0) * (widget.pond.anchoM ?? 0) * (widget.pond.profundidadM ?? 0))
            : 1.0);
    final displayDensidad = capacidadM3 > 0 ? (displayBiomasa / capacidadM3) : widget.pond.densidadKgM3;
    final activeBatch = allBatches.isNotEmpty ? allBatches.first : widget.batch;

    final isRealActive = (widget.pond.estado == PondStatus.active || allBatches.isNotEmpty || displayBiomasa > 0) &&
        (totalPeces > 0 || displayBiomasa > 0);
    final densidadPecesM3 = capacidadM3 > 0 && totalPeces > 0 ? (totalPeces / capacidadM3) : 0.0;
    final avgWeightGrams = totalPeces > 0
        ? (displayBiomasa * 1000 / totalPeces)
        : (isRealActive ? (activeBatch?.pesoActualGramos ?? 0.0) : 0.0);

    final targetWeight = _getTargetHarvestWeightGrams(activeBatch?.especie ?? '');
    final harvestProgress = isRealActive && avgWeightGrams > 0
        ? (avgWeightGrams / targetWeight).clamp(0.01, 1.0)
        : 0.0;

    return GlassCard(
      borderRadius: 24,
      glowColor: isPolyculture
          ? Colors.purpleAccent
          : (isRealActive ? AppColors.cyanWater : AppColors.textTertiaryDark),
      title: widget.pond.sigla,
      subtitle: '${widget.pond.nombre} • ${widget.pond.capacidadM3.toInt()} m³',
      trailingWidget: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (widget.pond.aireacionActiva)
            Container(
              margin: const EdgeInsets.only(right: 6),
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: AppColors.cyanWater.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: AppColors.cyanWater.withValues(alpha: 0.4)),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.bolt_rounded, color: AppColors.cyanWater, size: 12),
                  SizedBox(width: 2),
                  Text('AIREACIÓN', style: TextStyle(color: AppColors.cyanWater, fontSize: 9, fontWeight: FontWeight.w800)),
                ],
              ),
            ),
          // Chip de Estado Operativo
          GlassBadge(
            text: isRealActive ? (isPolyculture ? 'POLICULTIVO' : 'ACTIVO') : 'VACÍO',
            color: isRealActive ? AppColors.greenBiomass : AppColors.textTertiaryDark,
          ),
          const SizedBox(width: 6),
          // Botón Rotar 3D hacia la Radiografía Biológica (WCAG 2.5.5 >= 48x48 dp)
          Tooltip(
            message: 'Ver radiografía y costos (Flip)',
            child: SizedBox(
              width: 48,
              height: 48,
              child: InkWell(
                onTap: isRealActive ? _flipCard : null,
                borderRadius: BorderRadius.circular(12),
                child: Center(
                  child: Container(
                    width: 36,
                    height: 36,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: isDark ? Colors.white.withValues(alpha: 0.08) : Colors.white.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: isDark ? Colors.white.withValues(alpha: 0.16) : Colors.grey.withValues(alpha: 0.25)),
                    ),
                    child: Icon(
                      Icons.flip_camera_android_rounded,
                      size: 18,
                      color: isRealActive
                          ? (isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight)
                          : AppColors.textTertiaryDark,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final frontContent = Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Especie o resumen de policultivo
              if (isPolyculture) ...[
                Text(
                  'Policultivo (${allBatches.length} especies activas)',
                  style: AppTypography.titleSmall.copyWith(color: Colors.purpleAccent, fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 4),
                ...allBatches.map((b) => Padding(
                      padding: const EdgeInsets.only(bottom: 2),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              '• ${b.especie} (${b.codigoLote})',
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: isDark ? Colors.white : AppColors.textPrimaryLight,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '${CurrencyFormatters.formatInt(b.cantidadActualPeces)} pcs • ${b.biomasaActualKg.toInt()} kg',
                            style: const TextStyle(color: AppColors.textSecondaryDark, fontSize: 11),
                          ),
                        ],
                      ),
                    )),
              ] else ...[
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        isRealActive && allBatches.isNotEmpty ? allBatches.first.especie : 'Estanque Vacío / Disponible',
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.titleMedium.copyWith(
                          color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    if (isRealActive && allBatches.isNotEmpty) ...[
                      const SizedBox(width: 8),
                      Text(
                        '${CurrencyFormatters.formatInt(totalPeces)} peces',
                        style: AppTypography.bodySmall.copyWith(
                          fontWeight: FontWeight.w800,
                          color: AppColors.cyanWater,
                        ),
                      ),
                    ],
                  ],
                ),
              ],

              const SizedBox(height: 8),

              // Mini-Strip de Calidad de Agua (Semáforo Operativo)
              _buildWaterQualityMiniStrip(context, widget.latestWaterParameter),

              const SizedBox(height: 10),

              // Grid de 3 Métricas Operativas
              Row(
                children: [
                  Expanded(
                    child: _buildMetricTile(
                      label: 'BIOMASA TOTAL',
                      value: CurrencyFormatters.formatKg(isRealActive ? displayBiomasa : 0.0),
                      caption: totalPeces > 0 ? '${avgWeightGrams.toStringAsFixed(1)} g/pez' : (isRealActive ? null : 'Sin biomasa'),
                      color: AppColors.cyanWater,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildMetricTile(
                      label: 'DENSIDAD',
                      value: isRealActive ? '${displayDensidad.toStringAsFixed(2)} kg/m³' : '0.0 kg/m³',
                      caption: isRealActive
                          ? (densidadPecesM3 > 0
                              ? '${densidadPecesM3.toStringAsFixed(1)} pcs/m³ • ${(displayDensidad < 8.0 ? 'Óptima' : (displayDensidad <= 16.0 ? 'Alerta' : 'Crítica'))}'
                              : (displayDensidad < 8.0 ? 'Óptima' : (displayDensidad <= 16.0 ? 'Alerta' : 'Crítica')))
                          : 'Disponible',
                      color: isRealActive
                          ? (displayDensidad < 8.0
                              ? AppColors.purpleAnalytics
                              : (displayDensidad <= 16.0 ? AppColors.amberWarning : AppColors.coralAction))
                          : AppColors.textTertiaryDark,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildMetricTile(
                      label: 'FCA (CONVERSIÓN)',
                      value: isRealActive && activeBatch != null
                          ? (activeBatch.fcrOrNull != null
                              ? '${activeBatch.fcrOrNull!.toStringAsFixed(2)}:1'
                              : (activeBatch.alimentoAcumuladoKg <= 0 ? '—' : 'Calc.'))
                          : '—',
                      caption: isRealActive && activeBatch != null
                          ? (activeBatch.fcrOrNull != null
                              ? 'GPD: ${activeBatch.gpd.toStringAsFixed(2)} g/d'
                              : (activeBatch.alimentoAcumuladoKg <= 0
                                  ? 'Sin alimento reg.'
                                  : 'GPD: ${activeBatch.gpd.toStringAsFixed(2)} g/d'))
                          : 'Sin lote activo',
                      color: isRealActive ? AppColors.greenBiomass : AppColors.textTertiaryDark,
                    ),
                  ),
                ],
              ),

              // Alerta de Periodo de Retiro ICA si está activo
              if (activeBatch != null && activeBatch.enPeriodoRetiro) ...[
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.coralAction.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.coralAction.withValues(alpha: 0.5)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.sanitizer_rounded, color: AppColors.coralAction, size: 16),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          'PERIODO DE RETIRO SANITARIO (ICA): Quedan ${activeBatch.diasRetiroSanitarioRestantes} días. Cosecha y venta bloqueadas temporalmente por inocuidad.',
                          style: const TextStyle(color: AppColors.coralAction, fontSize: 10, fontWeight: FontWeight.w700),
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              // Barra de Progreso de Talla hacia Cosecha
              if (isActive && activeBatch != null) ...[
                const SizedBox(height: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            'Talla Promedio: ${avgWeightGrams.toStringAsFixed(0)}g / ${targetWeight.toInt()}g cosecha',
                            style: AppTypography.labelMicro.copyWith(color: AppColors.textSecondaryDark),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          '${(harvestProgress * 100).toInt()}%',
                          style: AppTypography.labelMicro.copyWith(color: AppColors.cyanWater, fontWeight: FontWeight.w800),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: LinearProgressIndicator(
                        value: harvestProgress,
                        backgroundColor: Colors.white.withValues(alpha: 0.08),
                        valueColor: const AlwaysStoppedAnimation<Color>(AppColors.cyanWater),
                        minHeight: 6,
                      ),
                    ),
                  ],
                ),
              ],
            ],
          );

          if (constraints.hasBoundedHeight) {
            return SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: frontContent,
            );
          }

          return frontContent;
        },
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // CARA TRASERA: Radiografía Biológica y Costos (con Selector de Policultivo)
  // ---------------------------------------------------------------------------
  Widget _buildBackCard(
    BuildContext context,
    List<FishBatch> allBatches,
    bool isPolyculture,
    bool isActive,
  ) {
    final validIndex = _selectedBatchIndex < allBatches.length ? _selectedBatchIndex : 0;
    final activeBatch = allBatches.isNotEmpty ? allBatches[validIndex] : widget.batch;
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    return GlassCard(
      borderRadius: 24,
      glowColor: isPolyculture ? Colors.purpleAccent : AppColors.purpleAnalytics,
      title: isPolyculture
          ? (_showConsolidated ? 'POLICULTIVO CONSOLIDADO' : 'LOTE: ${activeBatch?.codigoLote ?? "ACTIVO"}')
          : 'LOTE: ${activeBatch?.codigoLote ?? "ACTIVO"}',
      subtitle: isPolyculture
          ? (_showConsolidated
              ? '${allBatches.length} especies coexistentes'
              : '${activeBatch?.especie} • Día ${_getDaysInCulture(activeBatch)} de cultivo')
          : '${activeBatch?.especie ?? "Especie Principal"} • Día ${_getDaysInCulture(activeBatch)} de cultivo',
      trailingWidget: SizedBox(
        height: 48,
        child: InkWell(
          onTap: _flipCard,
          borderRadius: BorderRadius.circular(10),
          child: Container(
            alignment: Alignment.center,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: isDark ? Colors.black.withValues(alpha: 0.2) : Colors.white.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: isDark ? Colors.white.withValues(alpha: 0.16) : Colors.black.withValues(alpha: 0.18),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.undo_rounded, size: 14, color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight),
                const SizedBox(width: 6),
                Text(
                  'VOLVER',
                  style: TextStyle(
                    color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final scrollContent = Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Selector de Especies para Policultivos
              if (isPolyculture) ...[
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      ...allBatches.asMap().entries.map((entry) {
                        final idx = entry.key;
                        final b = entry.value;
                        final isSelected = !_showConsolidated && validIndex == idx;

                        return Padding(
                          padding: const EdgeInsets.only(right: 6),
                          child: InkWell(
                            onTap: () => setState(() {
                              _selectedBatchIndex = idx;
                              _showConsolidated = false;
                            }),
                            borderRadius: BorderRadius.circular(8),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 180),
                              constraints: const BoxConstraints(minHeight: 48),
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? Colors.purpleAccent.withValues(alpha: isDark ? 0.45 : 0.25)
                                    : (isDark ? Colors.white.withValues(alpha: 0.04) : Colors.white.withValues(alpha: 0.08)),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: isSelected
                                      ? Colors.purpleAccent
                                      : (isDark ? Colors.white.withValues(alpha: 0.12) : Colors.grey.withValues(alpha: 0.12)),
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.set_meal_rounded,
                                    size: 12,
                                    color: isSelected
                                        ? Colors.purpleAccent
                                        : (isDark ? Colors.white70 : AppColors.textPrimaryLight),
                                  ),
                                  const SizedBox(width: 5),
                                  Text(
                                    b.especie,
                                    style: TextStyle(
                                      color: isSelected
                                          ? Colors.purpleAccent
                                          : (isDark ? Colors.white70 : AppColors.textPrimaryLight),
                                      fontSize: 10.5,
                                      fontWeight: isSelected ? FontWeight.w800 : FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      }),
                      // Chip de Resumen Consolidado
                      InkWell(
                        onTap: () => setState(() => _showConsolidated = true),
                        borderRadius: BorderRadius.circular(8),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 180),
                          constraints: const BoxConstraints(minHeight: 48),
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                          decoration: BoxDecoration(
                            color: _showConsolidated
                                ? AppColors.cyanWater.withValues(alpha: 0.25)
                                : Colors.white.withValues(alpha: 0.04),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: _showConsolidated ? AppColors.cyanWater : Colors.white.withValues(alpha: 0.12),
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.pie_chart_rounded,
                                size: 12,
                                color: _showConsolidated
                                    ? AppColors.cyanWater
                                    : (isDark ? Colors.white70 : AppColors.textPrimaryLight),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                'Consolidado',
                                style: TextStyle(
                                  color: _showConsolidated
                                      ? AppColors.cyanWater
                                      : (isDark ? Colors.white70 : AppColors.textPrimaryLight),
                                  fontSize: 10.5,
                                  fontWeight: _showConsolidated ? FontWeight.w800 : FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
              ],

              // Contenido con Transición Fluida entre Especie y Consolidado
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                transitionBuilder: (child, animation) => FadeTransition(opacity: animation, child: child),
                child: _showConsolidated && isPolyculture
                    ? _buildConsolidatedPolycultureView(allBatches)
                    : _buildSingleBatchView(activeBatch),
              ),
            ],
          );

          if (constraints.hasBoundedHeight) {
            return Scrollbar(
              thumbVisibility: false,
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: scrollContent,
              ),
            );
          }

          return ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 340),
            child: Scrollbar(
              thumbVisibility: false,
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: scrollContent,
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildSectionHeader({
    required IconData icon,
    required String title,
    required Color color,
  }) {
    return Row(
      children: [
        Icon(icon, size: 13, color: color),
        const SizedBox(width: 5),
        Expanded(
          child: Text(
            title,
            overflow: TextOverflow.ellipsis,
            style: AppTypography.labelMicro.copyWith(
              color: color,
              letterSpacing: 1.1,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ],
    );
  }

  // Radiografía de un Lote Individual
  Widget _buildSingleBatchView(FishBatch? activeBatch) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final initialPeces = activeBatch?.cantidadInicialPeces ?? 0;
    final currentPeces = activeBatch?.cantidadActualPeces ?? 0;
    final trasladadosSalientes = activeBatch?.pecesTrasladadosSalientes ?? 0;
    final poblacionBase = activeBatch?.poblacionBaseNeta ?? initialPeces;
    final mortalidadPeces = activeBatch?.mortalidadAcumuladaPeces ?? 0;
    final mortalidadPorcentaje = activeBatch?.porcentajeMortalidad ?? 0.0;

    final initialWeight = activeBatch?.pesoInicialGramos ?? 1.0;
    final currentWeight = activeBatch?.pesoActualGramos ?? 1.0;
    final daysInCulture = _getDaysInCulture(activeBatch);
    final gdp = daysInCulture > 0 ? ((currentWeight - initialWeight) / daysInCulture).clamp(0.0, 50.0) : 0.0;

    final costoAlevines = activeBatch?.costoInicialAlevinos ?? 0.0;
    final costoInsumos = activeBatch?.costoAcumuladoInsumos ?? 0.0;
    final costoFijo = activeBatch?.costoAcumuladoFijo ?? 0.0;
    final costoTotal = costoAlevines + costoInsumos + costoFijo;
    final cpk = (activeBatch?.biomasaActualKg ?? 0.0) > 0 ? (costoTotal / activeBatch!.biomasaActualKg) : 0.0;

    final capacidadM3 = widget.pond.capacidadM3 > 0
        ? widget.pond.capacidadM3
        : (((widget.pond.largoM ?? 0) * (widget.pond.anchoM ?? 0) * (widget.pond.profundidadM ?? 0)) > 0
            ? ((widget.pond.largoM ?? 0) * (widget.pond.anchoM ?? 0) * (widget.pond.profundidadM ?? 0))
            : 1.0);
    final batchBiomasa = activeBatch?.biomasaActualKg ?? 0.0;
    final singleDensidad = capacidadM3 > 0 ? (batchBiomasa / capacidadM3) : 0.0;
    final singleDensidadPeces = capacidadM3 > 0 && currentPeces > 0 ? (currentPeces / capacidadM3) : 0.0;

    final targetWeightSingle = _getTargetHarvestWeightGrams(activeBatch?.especie ?? '');
    final harvestProgressSingle = currentWeight > 0
        ? (currentWeight / targetWeightSingle).clamp(0.01, 1.0)
        : 0.0;

    return Column(
      key: ValueKey('batch_${activeBatch?.id ?? "single"}'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 1. Desglose Biológico
        _buildSectionHeader(
          icon: Icons.biotech_rounded,
          title: 'DESGLOSE BIOLÓGICO',
          color: AppColors.cyanWater,
        ),
        const SizedBox(height: 5),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.04),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
          ),
          child: Column(
            children: [
              _buildDataRow(
                context: context,
                label: 'Población:',
                value: '${CurrencyFormatters.formatInt(currentPeces)} / ${CurrencyFormatters.formatInt(poblacionBase)} pcs',
                extra: '$mortalidadPeces bajas (${mortalidadPorcentaje.toStringAsFixed(1)}%)',
                extraColor: mortalidadPorcentaje > 5.0 ? AppColors.coralAction : AppColors.greenBiomass,
              ),
              if (trasladadosSalientes > 0) ...[
                const Divider(height: 6, color: Colors.white12),
                _buildDataRow(
                  context: context,
                  label: 'Trasladados (Desdoble):',
                  value: '${CurrencyFormatters.formatInt(trasladadosSalientes)} pcs',
                  extra: 'Sembrados orig.: ${CurrencyFormatters.formatInt(initialPeces)}',
                  extraColor: AppColors.amberWarning,
                ),
              ],
              const Divider(height: 6, color: Colors.white12),
              _buildDataRow(
                context: context,
                label: 'Peso Promedio:',
                value: '${currentWeight.toStringAsFixed(1)} g (Inicial: ${initialWeight.toStringAsFixed(1)} g)',
                extra: daysInCulture > 0 ? 'GDP: +${gdp.toStringAsFixed(2)} g/día' : 'Sembrado hoy',
                extraColor: AppColors.cyanWater,
              ),
              const Divider(height: 6, color: Colors.white12),
              _buildDataRow(
                context: context,
                label: 'Biomasa Viva:',
                value: CurrencyFormatters.formatKg(activeBatch?.biomasaActualKg ?? 0.0),
                extra: 'Inicial: ${CurrencyFormatters.formatKg(activeBatch?.biomasaInicialKg ?? 0.0)}',
                extraColor: AppColors.greenBiomass,
              ),
              const Divider(height: 6, color: Colors.white12),
              _buildDataRow(
                context: context,
                label: 'FCA (Conversión):',
                value: activeBatch?.fcrOrNull != null
                    ? '${activeBatch!.fcrOrNull!.toStringAsFixed(2)}:1'
                    : ((activeBatch?.alimentoAcumuladoKg ?? 0) <= 0 ? 'Sin alimento' : 'Calculando...'),
                extra: 'Alimento: ${CurrencyFormatters.formatKg(activeBatch?.alimentoAcumuladoKg ?? 0.0)}',
                extraColor: (activeBatch?.fcrOrNull != null && activeBatch!.fcrOrNull! <= 1.6)
                    ? AppColors.greenBiomass
                    : AppColors.amberWarning,
              ),
              const Divider(height: 6, color: Colors.white12),
              _buildDataRow(
                context: context,
                label: 'Densidad por m³:',
                value: '${singleDensidad.toStringAsFixed(2)} kg/m³ (${capacidadM3.toStringAsFixed(0)} m³ agua)',
                extra: singleDensidadPeces > 0 ? '${singleDensidadPeces.toStringAsFixed(1)} pcs/m³' : '—',
                extraColor: singleDensidad < 8.0
                    ? AppColors.greenBiomass
                    : (singleDensidad <= 16.0 ? AppColors.amberWarning : AppColors.coralAction),
              ),
              const Divider(height: 6, color: Colors.white12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          'Talla Hacia Cosecha: ${currentWeight.toStringAsFixed(0)}g / ${targetWeightSingle.toInt()}g meta',
                          style: TextStyle(color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight, fontSize: 10),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        '${(harvestProgressSingle * 100).toInt()}%',
                        style: const TextStyle(color: AppColors.cyanWater, fontWeight: FontWeight.w800, fontSize: 11),
                      ),
                    ],
                  ),
                  const SizedBox(height: 3),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: harvestProgressSingle,
                      backgroundColor: Colors.white10,
                      valueColor: const AlwaysStoppedAnimation<Color>(AppColors.cyanWater),
                      minHeight: 4,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),

        const SizedBox(height: 8),

        // 2. Desglose Financiero y Costo Invertido
        _buildSectionHeader(
          icon: Icons.account_balance_wallet_rounded,
          title: 'RADIOGRAFÍA FINANCIERA Y COSTOS',
          color: AppColors.greenBiomass,
        ),
        const SizedBox(height: 5),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
          decoration: BoxDecoration(
            color: AppColors.greenBiomass.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.greenBiomass.withValues(alpha: 0.2)),
          ),
          child: Column(
            children: [
              _buildFinancialRow(context, '• Costo Alevinos:', CurrencyFormatters.formatCOP(costoAlevines)),
              _buildFinancialRow(context, '• Alimento e Insumos:', CurrencyFormatters.formatCOP(costoInsumos)),
              _buildFinancialRow(context, '• Costos Fijos:', CurrencyFormatters.formatCOP(costoFijo)),
              const Divider(height: 6, color: Colors.white24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      'COSTO TOTAL INVERTIDO:',
                      style: TextStyle(
                        color: isDark ? Colors.white : AppColors.textPrimaryLight,
                        fontWeight: FontWeight.w800,
                        fontSize: 11,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    CurrencyFormatters.formatCOP(costoTotal),
                    style: const TextStyle(color: AppColors.greenBiomass, fontWeight: FontWeight.w900, fontSize: 12.5),
                  ),
                ],
              ),
              const SizedBox(height: 2),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      'Costo Unitario por Kilo (CPK):',
                      style: TextStyle(
                        color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                        fontSize: 10,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '${CurrencyFormatters.formatCOP(cpk)} / kg',
                    style: const TextStyle(color: AppColors.cyanWater, fontWeight: FontWeight.w800, fontSize: 11),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  // Radiografía Consolidada del Policultivo
  Widget _buildConsolidatedPolycultureView(List<FishBatch> allBatches) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final totalPeces = allBatches.fold(0, (sum, b) => sum + b.cantidadActualPeces);
    final totalBaseNeta = allBatches.fold(0, (sum, b) => sum + b.poblacionBaseNeta);
    final totalBajas = allBatches.fold(0, (sum, b) => sum + b.mortalidadAcumuladaPeces);
    final totalBiomasa = allBatches.fold(0.0, (sum, b) => sum + b.biomasaActualKg);
    final totalBiomasaInicial = allBatches.fold(0.0, (sum, b) => sum + b.biomasaInicialKg);
    final totalAlimento = allBatches.fold(0.0, (sum, b) => sum + b.alimentoAcumuladoKg);
    final gananciaTotal = totalBiomasa - totalBiomasaInicial;
    final fcaGlobal = (totalAlimento > 0 && gananciaTotal > 0) ? (totalAlimento / gananciaTotal) : null;
    final totalAlevines = allBatches.fold(0.0, (sum, b) => sum + b.costoInicialAlevinos);
    final totalInsumos = allBatches.fold(0.0, (sum, b) => sum + b.costoAcumuladoInsumos);
    final totalFijos = allBatches.fold(0.0, (sum, b) => sum + b.costoAcumuladoFijo);
    final granTotal = totalAlevines + totalInsumos + totalFijos;
    final cpkGlobal = totalBiomasa > 0 ? (granTotal / totalBiomasa) : 0.0;

    final supervGlobal = totalBaseNeta > 0
        ? (((totalBaseNeta - totalBajas) / totalBaseNeta) * 100.0).clamp(0.0, 100.0)
        : 100.0;

    return Column(
      key: const ValueKey('polyculture_consolidated'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 1. Distribución Porcentual de Biomasa
        _buildSectionHeader(
          icon: Icons.donut_large_rounded,
          title: 'DISTRIBUCIÓN DE BIOMASA POR ESPECIE',
          color: Colors.purpleAccent,
        ),
        const SizedBox(height: 5),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
          decoration: BoxDecoration(
            color: Colors.purpleAccent.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.purpleAccent.withValues(alpha: 0.2)),
          ),
          child: Column(
            children: [
              ...allBatches.map((b) {
                final pct = totalBiomasa > 0 ? (b.biomasaActualKg / totalBiomasa) : 0.0;
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2.0),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              '• ${b.especie}',
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: isDark ? Colors.white : AppColors.textPrimaryLight,
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '${(pct * 100).toStringAsFixed(1)}% (${CurrencyFormatters.formatKg(b.biomasaActualKg)})',
                            style: const TextStyle(color: AppColors.cyanWater, fontSize: 10.5, fontWeight: FontWeight.w800),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(3),
                        child: LinearProgressIndicator(
                          value: pct,
                          backgroundColor: Colors.white10,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            b.especie.toLowerCase().contains('tilapia') ? AppColors.cyanWater : Colors.purpleAccent,
                          ),
                          minHeight: 4,
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ],
          ),
        ),

        const SizedBox(height: 8),

        // 2. Estructura Financiera Global del Policultivo
        _buildSectionHeader(
          icon: Icons.account_balance_wallet_rounded,
          title: 'INVERSIÓN TOTAL DEL POLICULTIVO',
          color: AppColors.greenBiomass,
        ),
        const SizedBox(height: 5),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
          decoration: BoxDecoration(
            color: AppColors.greenBiomass.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.greenBiomass.withValues(alpha: 0.2)),
          ),
          child: Column(
            children: [
              _buildDataRow(
                context: context,
                label: 'Población Total:',
                value: '${CurrencyFormatters.formatInt(totalPeces)} peces',
                extra: 'Supervivencia: ${supervGlobal.toStringAsFixed(1)}%',
                extraColor: AppColors.greenBiomass,
              ),
              const Divider(height: 6, color: Colors.white12),
              _buildDataRow(
                context: context,
                label: 'FCA Consolidado:',
                value: fcaGlobal != null ? '${fcaGlobal.toStringAsFixed(2)}:1' : '—',
                extra: 'Alimento: ${CurrencyFormatters.formatKg(totalAlimento)}',
                extraColor: (fcaGlobal != null && fcaGlobal <= 1.6) ? AppColors.greenBiomass : AppColors.amberWarning,
              ),
              const Divider(height: 6, color: Colors.white12),
              _buildDataRow(
                context: context,
                label: 'Densidad Consolidada:',
                value: '${(totalBiomasa / (widget.pond.capacidadM3 > 0 ? widget.pond.capacidadM3 : 1.0)).toStringAsFixed(2)} kg/m³',
                extra: '${(totalPeces / (widget.pond.capacidadM3 > 0 ? widget.pond.capacidadM3 : 1.0)).toStringAsFixed(1)} pcs/m³',
                extraColor: (totalBiomasa / (widget.pond.capacidadM3 > 0 ? widget.pond.capacidadM3 : 1.0)) < 8.0
                    ? AppColors.greenBiomass
                    : ((totalBiomasa / (widget.pond.capacidadM3 > 0 ? widget.pond.capacidadM3 : 1.0)) <= 16.0
                        ? AppColors.amberWarning
                        : AppColors.coralAction),
              ),
              const Divider(height: 6, color: Colors.white12),
              _buildFinancialRow(context, '• Total Semilla/Alevinaje:', CurrencyFormatters.formatCOP(totalAlevines)),
              _buildFinancialRow(context, '• Total Alimento e Insumos:', CurrencyFormatters.formatCOP(totalInsumos)),
              _buildFinancialRow(context, '• Total Costos Fijos Asignados:', CurrencyFormatters.formatCOP(totalFijos)),
              const Divider(height: 6, color: Colors.white24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      'INVERSIÓN TOTAL EN ESTANQUE:',
                      style: TextStyle(
                        color: isDark ? Colors.white : AppColors.textPrimaryLight,
                        fontWeight: FontWeight.w800,
                        fontSize: 11,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    CurrencyFormatters.formatCOP(granTotal),
                    style: const TextStyle(color: AppColors.greenBiomass, fontWeight: FontWeight.w900, fontSize: 12.5),
                  ),
                ],
              ),
              const SizedBox(height: 2),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      'CPK Promedio Ponderado:',
                      style: TextStyle(
                        color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                        fontSize: 10,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '${CurrencyFormatters.formatCOP(cpkGlobal)} / kg',
                    style: const TextStyle(color: AppColors.cyanWater, fontWeight: FontWeight.w800, fontSize: 11),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  double _getTargetHarvestWeightGrams(String especie) {
    if (widget.targetWeightsBySpecies != null && widget.targetWeightsBySpecies!.containsKey(especie)) {
      final val = widget.targetWeightsBySpecies![especie];
      if (val is num) return val.toDouble();
      final parsed = double.tryParse(val.toString());
      if (parsed != null && parsed > 0) return parsed;
    }
    final lower = especie.toLowerCase();
    if (lower.contains('cachama')) return 1000.0;
    if (lower.contains('tilapia')) return 650.0;
    if (lower.contains('trucha')) return 400.0;
    if (lower.contains('bocachico')) return 400.0;
    if (lower.contains('pangasius')) return 800.0;
    if (lower.contains('camar') || lower.contains('langostino')) return 25.0;
    return 500.0;
  }

  Widget _buildWaterQualityMiniStrip(BuildContext context, WaterParameter? param) {
    if (param == null) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.04),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.water_drop_outlined, size: 12, color: AppColors.textTertiaryDark),
            SizedBox(width: 4),
            Flexible(
              child: Text(
                'Agua: Sin registro reciente',
                overflow: TextOverflow.ellipsis,
                style: TextStyle(color: AppColors.textTertiaryDark, fontSize: 10, fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
      );
    }

    final o2 = param.oxigenoMgL;
    final temp = param.temperaturaC;
    final ph = param.ph;

    Color o2Color = AppColors.greenBiomass;
    if (o2 != null) {
      if (o2 < 3.5) {
        o2Color = AppColors.coralAction;
      } else if (o2 < 5.0) {
        o2Color = AppColors.amberWarning;
      }
    }

    Color phColor = AppColors.greenBiomass;
    if (ph != null) {
      if (ph < 6.0 || ph > 9.0) {
        phColor = AppColors.coralAction;
      } else if (ph < 6.5 || ph > 8.5) {
        phColor = AppColors.amberWarning;
      }
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.cyanWater.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.cyanWater.withValues(alpha: 0.2)),
      ),
      child: FittedBox(
        fit: BoxFit.scaleDown,
        alignment: Alignment.centerLeft,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.water_drop_rounded, size: 13, color: AppColors.cyanWater),
            const SizedBox(width: 4),
            Text(
              'O₂: ${o2 != null ? "${o2.toStringAsFixed(1)} mg/L" : "—"}',
              style: TextStyle(color: o2Color, fontSize: 10, fontWeight: FontWeight.w800),
            ),
            const Text(' • ', style: TextStyle(color: Colors.white30, fontSize: 10)),
            Text(
              'T: ${temp != null ? "${temp.toStringAsFixed(1)}°C" : "—"}',
              style: const TextStyle(color: AppColors.cyanWater, fontSize: 10, fontWeight: FontWeight.w700),
            ),
            const Text(' • ', style: TextStyle(color: Colors.white30, fontSize: 10)),
            Text(
              'pH: ${ph != null ? ph.toStringAsFixed(1) : "—"}',
              style: TextStyle(color: phColor, fontSize: 10, fontWeight: FontWeight.w800),
            ),
          ],
        ),
      ),
    );
  }

  int _getDaysInCulture(FishBatch? batch) {
    if (batch == null) return 0;
    final diff = DateTime.now().difference(batch.fechaSiembra).inDays;
    return diff > 0 ? diff : 0;
  }

  Widget _buildDataRow({
    required BuildContext context,
    required String label,
    required String value,
    required String extra,
    required Color extraColor,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight, fontSize: 10),
              ),
              Text(
                value,
                style: TextStyle(
                  color: isDark ? Colors.white : AppColors.textPrimaryLight,
                  fontWeight: FontWeight.w700,
                  fontSize: 11,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        Flexible(
          child: Text(
            extra,
            style: TextStyle(color: extraColor, fontWeight: FontWeight.w800, fontSize: 11),
            textAlign: TextAlign.right,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildFinancialRow(BuildContext context, String title, String amount) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 1.5),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(
              title,
              style: TextStyle(color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight, fontSize: 10),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            amount,
            style: TextStyle(
              color: isDark ? Colors.white : AppColors.textPrimaryLight,
              fontWeight: FontWeight.w600,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricTile({
    required String label,
    required String value,
    String? caption,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(label, style: AppTypography.labelMicro.copyWith(color: color, fontSize: 8)),
          ),
          const SizedBox(height: 2),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              value,
              style: AppTypography.titleMedium.copyWith(
                color: color,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          if (caption != null) ...[
            const SizedBox(height: 1),
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(
                caption,
                style: TextStyle(color: color.withValues(alpha: 0.8), fontSize: 9, fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
