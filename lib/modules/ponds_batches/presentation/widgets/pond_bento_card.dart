import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:fishbit_finance/core/design_system/app_colors.dart';
import 'package:fishbit_finance/core/design_system/app_typography.dart';
import 'package:fishbit_finance/core/design_system/glass_card.dart';
import 'package:fishbit_finance/core/design_system/glass_badge.dart';
import 'package:fishbit_finance/core/utils/currency_formatters.dart';
import 'package:fishbit_finance/modules/ponds_batches/domain/models/pond.dart';
import 'package:fishbit_finance/modules/ponds_batches/domain/models/fish_batch.dart';

/// Tarjeta Bento de Estanque Interactiva Optimizada a 60/120 FPS con efecto 3D Flip de 180°
/// - Cara Frontal: Resumen Operativo, Calidad de Agua, Densidad y Acciones Rápidas.
/// - Cara Trasera (Reverso 180°): Trazabilidad, Radiografía por Especie y Vista Consolidada en Policultivos.
class PondBentoCard extends StatefulWidget {
  final Pond pond;
  final FishBatch? batch;
  final List<FishBatch> batches;
  final VoidCallback? onFeedPressed;
  final VoidCallback? onTransferPressed;
  final VoidCallback? onSamplePressed;
  final VoidCallback? onMortalityPressed;

  const PondBentoCard({
    super.key,
    required this.pond,
    this.batch,
    this.batches = const [],
    this.onFeedPressed,
    this.onTransferPressed,
    this.onSamplePressed,
    this.onMortalityPressed,
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

    final frontWidget = RepaintBoundary(
      child: _buildFrontCard(context, allBatches, isPolyculture, isActive),
    );
    final backWidget = Transform(
      alignment: FractionalOffset.center,
      transform: Matrix4.identity()..rotateY(math.pi), // Espejo reverso
      child: RepaintBoundary(
        child: _buildBackCard(context, allBatches, isPolyculture, isActive),
      ),
    );

    // Cacheamos el frente y reverso dentro de RepaintBoundary para aceleración por GPU (60/120 FPS)
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        final angle = _animation.value * math.pi;
        final isFront = angle <= math.pi / 2;

        return Transform(
          alignment: FractionalOffset.center,
          transform: Matrix4.identity()
            ..setEntry(3, 2, 0.0015) // Perspectiva 3D
            ..rotateY(angle),
          child: isFront ? frontWidget : backWidget,
        );
      },
    );
  }

  // ---------------------------------------------------------------------------
  // CARA FRONTAL: Resumen Operativo, Densidad y Acciones Rápidas
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
    final displayDensidad = widget.pond.capacidadM3 > 0 ? (displayBiomasa / widget.pond.capacidadM3) : widget.pond.densidadKgM3;
    final activeBatch = allBatches.isNotEmpty ? allBatches.first : widget.batch;

    final isRealActive = (widget.pond.estado == PondStatus.active || allBatches.isNotEmpty) && totalPeces > 0;
    final avgWeightGrams = totalPeces > 0
        ? (displayBiomasa * 1000 / totalPeces)
        : (isRealActive ? (activeBatch?.pesoActualGramos ?? 0.0) : 0.0);

    const targetWeight = 500.0;
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
          // Botón Rotar 3D hacia la Radiografía Biológica
          InkWell(
            onTap: isRealActive ? _flipCard : null,
            borderRadius: BorderRadius.circular(8),
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: isDark ? Colors.white.withValues(alpha: 0.06) : Colors.white.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: isDark ? Colors.white.withValues(alpha: 0.12) : Colors.grey.withValues(alpha: 0.2)),
              ),
              child: Icon(
                Icons.flip_camera_android_rounded,
                size: 15,
                color: isRealActive ? (isDark ? Colors.white : AppColors.textPrimaryDark) : AppColors.textTertiaryDark,
              ),
            ),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
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
                          style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600),
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

          const SizedBox(height: 12),

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
                  value: isRealActive ? '${displayDensidad.toStringAsFixed(1)} kg/m³' : '0.0 kg/m³',
                  caption: isRealActive
                      ? (widget.pond.nivelRiesgoDensidad == 'Óptimo'
                          ? '🟢 Óptima'
                          : (widget.pond.nivelRiesgoDensidad == 'Alerta' ? '🟡 Alerta' : '🔴 Crítica'))
                      : '⚪ Disponible',
                  color: isRealActive
                      ? (widget.pond.nivelRiesgoDensidad == 'Óptimo'
                          ? AppColors.purpleAnalytics
                          : (widget.pond.nivelRiesgoDensidad == 'Alerta' ? AppColors.amberWarning : AppColors.coralAction))
                      : AppColors.textTertiaryDark,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildMetricTile(
                  label: 'FCR CONVERSIÓN',
                  value: isRealActive && activeBatch != null
                      ? (activeBatch.fcrOrNull != null ? activeBatch.fcrOrNull!.toStringAsFixed(2) : '—')
                      : '—',
                  caption: isRealActive && activeBatch != null
                      ? (activeBatch.diasDeCultivo <= 0
                          ? 'Sembrado hoy'
                          : 'GPD: ${activeBatch.gpd.toStringAsFixed(2)} g/d')
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
                    Text(
                      'Talla Promedio: ${avgWeightGrams.toStringAsFixed(0)}g / ${targetWeight.toInt()}g cosecha',
                      style: AppTypography.labelMicro.copyWith(color: AppColors.textSecondaryDark),
                    ),
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

          const SizedBox(height: 12),

          // Botón Disparador del 3D Flip
          if (isActive && allBatches.isNotEmpty)
            InkWell(
              onTap: _flipCard,
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                decoration: BoxDecoration(
                  color: (isPolyculture ? Colors.purpleAccent : AppColors.cyanWater).withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: (isPolyculture ? Colors.purpleAccent : AppColors.cyanWater).withValues(alpha: 0.25)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.flip_camera_android_rounded, size: 15, color: isPolyculture ? Colors.purpleAccent : AppColors.cyanWater),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        isPolyculture
                            ? 'Radiografía Policultivo (Flip)'
                            : 'Radiografía y Costos (Flip)',
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: isPolyculture ? Colors.purpleAccent : AppColors.cyanWater,
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.2,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

          if (isActive) ...[
            const SizedBox(height: 10),
            // Barra de Acciones Rápidas
            Row(
              children: [
                if (widget.onFeedPressed != null)
                  Expanded(
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        backgroundColor: AppColors.greenBiomass.withValues(alpha: isDark ? 0.1 : 0.08),
                        foregroundColor: AppColors.greenBiomass,
                        side: const BorderSide(color: AppColors.greenBiomass),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        visualDensity: VisualDensity.compact,
                        minimumSize: const Size(0, 30),
                        padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 2),
                      ),
                      onPressed: widget.onFeedPressed,
                      child: const FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.restaurant_outlined, size: 13),
                            SizedBox(width: 4),
                            Text('Alimentar', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800)),
                          ],
                        ),
                      ),
                    ),
                  ),
                const SizedBox(width: 6),
                if (widget.onSamplePressed != null)
                  Expanded(
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        backgroundColor: AppColors.cyanWater.withValues(alpha: isDark ? 0.1 : 0.08),
                        foregroundColor: AppColors.cyanWater,
                        side: const BorderSide(color: AppColors.cyanWater),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        visualDensity: VisualDensity.compact,
                        minimumSize: const Size(0, 30),
                        padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 2),
                      ),
                      onPressed: widget.onSamplePressed,
                      child: const FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.scale_rounded, size: 13),
                            SizedBox(width: 4),
                            Text('Muestreo', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800)),
                          ],
                        ),
                      ),
                    ),
                  ),
                const SizedBox(width: 6),
                if (widget.onMortalityPressed != null)
                  Expanded(
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        backgroundColor: AppColors.coralAction.withValues(alpha: isDark ? 0.1 : 0.08),
                        foregroundColor: AppColors.coralAction,
                        side: BorderSide(color: AppColors.coralAction.withValues(alpha: 0.6)),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        visualDensity: VisualDensity.compact,
                        minimumSize: const Size(0, 30),
                        padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 2),
                      ),
                      onPressed: widget.onMortalityPressed,
                      child: const FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.warning_amber_rounded, size: 13),
                            SizedBox(width: 4),
                            Text('Bajas', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800)),
                          ],
                        ),
                      ),
                    ),
                  ),
                const SizedBox(width: 6),
                if (widget.onTransferPressed != null)
                  Expanded(
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        backgroundColor: AppColors.amberWarning.withValues(alpha: isDark ? 0.1 : 0.08),
                        foregroundColor: AppColors.amberWarning,
                        side: BorderSide(color: AppColors.amberWarning.withValues(alpha: 0.6)),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        visualDensity: VisualDensity.compact,
                        minimumSize: const Size(0, 30),
                        padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 2),
                      ),
                      onPressed: widget.onTransferPressed,
                      child: const FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.swap_horiz_rounded, size: 14),
                            SizedBox(width: 4),
                            Text('Traslado', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800)),
                          ],
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ],
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
          ? (_showConsolidated ? '${allBatches.length} especies coexistentes' : '${activeBatch?.especie} • Día ${_getDaysInCulture(activeBatch)} de cultivo')
          : '${activeBatch?.especie ?? "Especie Principal"} • Día ${_getDaysInCulture(activeBatch)} de cultivo',
      trailingWidget: InkWell(
        onTap: _flipCard,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: isDark ? Colors.black.withValues(alpha: 0.06) : Colors.white.withValues(alpha: 0.06),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: isDark ? Colors.white.withValues(alpha: 0.12) : Colors.black.withValues(alpha: 0.12)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.undo_rounded, size: 12, color: isDark ? Colors.white : AppColors.textPrimaryDark),
              const SizedBox(width: 4),
              Text('VOLVER', style: TextStyle(color: isDark ? Colors.white : AppColors.textPrimaryDark, fontSize: 10, fontWeight: FontWeight.w800)),
            ],
          ),
        ),
      ),
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
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
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
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
                              Text(
                                '🐟 ${b.especie}',
                                style: TextStyle(
                                  color: isSelected
                                      ? Colors.purpleAccent
                                      : (isDark ? Colors.white70 : AppColors.textPrimaryDark),
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
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: _showConsolidated ? AppColors.cyanWater.withValues(alpha: 0.25) : Colors.white.withValues(alpha: 0.04),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: _showConsolidated ? AppColors.cyanWater : Colors.white.withValues(alpha: 0.12),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.pie_chart_rounded, size: 12, color: _showConsolidated ? AppColors.cyanWater : Colors.white70),
                          const SizedBox(width: 4),
                          Text(
                            '📊 Consolidado',
                            style: TextStyle(
                              color: _showConsolidated ? AppColors.cyanWater : Colors.white70,
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
            const SizedBox(height: 10),
          ],

          // Contenido con Transición Fluida entre Especie y Consolidado
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 200),
            transitionBuilder: (child, animation) => FadeTransition(opacity: animation, child: child),
            child: _showConsolidated && isPolyculture
                ? _buildConsolidatedPolycultureView(allBatches)
                : _buildSingleBatchView(activeBatch),
          ),

          const SizedBox(height: 12),

          // Botón para rotar al frente
          InkWell(
            onTap: _flipCard,
            borderRadius: BorderRadius.circular(12),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 8),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.arrow_back_rounded, size: 14, color: Colors.white),
                  SizedBox(width: 6),
                  Text('↩️ Volver a Vista de Estanque', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700)),
                ],
              ),
            ),
          ),
        ],
      ),
    ),
  );
  }

  // Radiografía de un Lote Individual
  Widget _buildSingleBatchView(FishBatch? activeBatch) {
    final initialPeces = activeBatch?.cantidadInicialPeces ?? 0;
    final currentPeces = activeBatch?.cantidadActualPeces ?? 0;
    final mortalidadPeces = (initialPeces - currentPeces).clamp(0, initialPeces);
    final mortalidadPorcentaje = initialPeces > 0 ? (mortalidadPeces / initialPeces * 100) : 0.0;

    final initialWeight = activeBatch?.pesoInicialGramos ?? 1.0;
    final currentWeight = activeBatch?.pesoActualGramos ?? 1.0;
    final daysInCulture = _getDaysInCulture(activeBatch);
    final gdp = daysInCulture > 0 ? ((currentWeight - initialWeight) / daysInCulture).clamp(0.0, 50.0) : 0.0;

    final costoAlevines = activeBatch?.costoInicialAlevinos ?? 0.0;
    final costoInsumos = activeBatch?.costoAcumuladoInsumos ?? 0.0;
    final costoFijo = activeBatch?.costoAcumuladoFijo ?? 0.0;
    final costoTotal = costoAlevines + costoInsumos + costoFijo;
    final cpk = (activeBatch?.biomasaActualKg ?? 0.0) > 0 ? (costoTotal / activeBatch!.biomasaActualKg) : 0.0;

    return Column(
      key: ValueKey('batch_${activeBatch?.id ?? "single"}'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 1. Desglose Biológico
        Text('🔬 DESGLOSE BIOLÓGICO', style: AppTypography.labelMicro.copyWith(color: AppColors.cyanWater, letterSpacing: 1.2, fontWeight: FontWeight.w800)),
        const SizedBox(height: 6),
        Container(
          padding: const EdgeInsets.all(10),
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
                value: '${CurrencyFormatters.formatInt(currentPeces)} / ${CurrencyFormatters.formatInt(initialPeces)} pcs',
                extra: '$mortalidadPeces bajas (${mortalidadPorcentaje.toStringAsFixed(1)}%)',
                extraColor: mortalidadPorcentaje > 5.0 ? AppColors.coralAction : AppColors.greenBiomass,
              ),
              const Divider(height: 10, color: Colors.white12),
              _buildDataRow(
                context: context,
                label: 'Peso Promedio:',
                value: '${currentWeight.toStringAsFixed(1)} g (Inicial: ${initialWeight.toStringAsFixed(1)} g)',
                extra: daysInCulture > 0 ? 'GDP: +${gdp.toStringAsFixed(2)} g/día' : 'Sembrado hoy',
                extraColor: AppColors.cyanWater,
              ),
              const Divider(height: 10, color: Colors.white12),
              _buildDataRow(
                context: context,
                label: 'Biomasa Viva:',
                value: CurrencyFormatters.formatKg(activeBatch?.biomasaActualKg ?? 0.0),
                extra: 'Inicial: ${CurrencyFormatters.formatKg(activeBatch?.biomasaInicialKg ?? 0.0)}',
                extraColor: AppColors.greenBiomass,
              ),
            ],
          ),
        ),

        const SizedBox(height: 10),

        // 2. Desglose Financiero y Costo Invertido
        Text('💰 RADIOGRAFÍA FINANCIERA Y COSTOS', style: AppTypography.labelMicro.copyWith(color: AppColors.greenBiomass, letterSpacing: 1.2, fontWeight: FontWeight.w800)),
        const SizedBox(height: 6),
        Container(
          padding: const EdgeInsets.all(10),
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
              const Divider(height: 8, color: Colors.white24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('COSTO TOTAL INVERTIDO:', style: TextStyle(color: Theme.of(context).brightness == Brightness.dark ? Colors.white : AppColors.textPrimaryLight, fontWeight: FontWeight.w800, fontSize: 11)),
                  Text(CurrencyFormatters.formatCOP(costoTotal), style: const TextStyle(color: AppColors.greenBiomass, fontWeight: FontWeight.w900, fontSize: 13)),
                ],
              ),
              const SizedBox(height: 2),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Costo Unitario por Kilo (CPK):', style: TextStyle(color: Theme.of(context).brightness == Brightness.dark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight, fontSize: 10)),
                  Text('${CurrencyFormatters.formatCOP(cpk)} / kg', style: const TextStyle(color: AppColors.cyanWater, fontWeight: FontWeight.w800, fontSize: 11)),
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
    final totalPeces = allBatches.fold(0, (sum, b) => sum + b.cantidadActualPeces);
    final totalPecesIniciales = allBatches.fold(0, (sum, b) => sum + b.cantidadInicialPeces);
    final totalBiomasa = allBatches.fold(0.0, (sum, b) => sum + b.biomasaActualKg);
    final totalAlevines = allBatches.fold(0.0, (sum, b) => sum + b.costoInicialAlevinos);
    final totalInsumos = allBatches.fold(0.0, (sum, b) => sum + b.costoAcumuladoInsumos);
    final totalFijos = allBatches.fold(0.0, (sum, b) => sum + b.costoAcumuladoFijo);
    final granTotal = totalAlevines + totalInsumos + totalFijos;
    final cpkGlobal = totalBiomasa > 0 ? (granTotal / totalBiomasa) : 0.0;

    final supervGlobal = totalPecesIniciales > 0 ? (totalPeces / totalPecesIniciales * 100) : 100.0;

    return Column(
      key: const ValueKey('polyculture_consolidated'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 1. Distribución Porcentual de Biomasa
        Text('📊 DISTRIBUCIÓN DE BIOMASA POR ESPECIE', style: AppTypography.labelMicro.copyWith(color: Colors.purpleAccent, letterSpacing: 1.2, fontWeight: FontWeight.w800)),
        const SizedBox(height: 6),
        Container(
          padding: const EdgeInsets.all(10),
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
                  padding: const EdgeInsets.symmetric(vertical: 2.5),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('• ${b.especie}', style: TextStyle(color: Theme.of(context).brightness == Brightness.dark ? Colors.white : AppColors.textPrimaryLight, fontSize: 11, fontWeight: FontWeight.w700)),
                          Text('${(pct * 100).toStringAsFixed(1)}% (${CurrencyFormatters.formatKg(b.biomasaActualKg)})', style: const TextStyle(color: AppColors.cyanWater, fontSize: 10.5, fontWeight: FontWeight.w800)),
                        ],
                      ),
                      const SizedBox(height: 3),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(3),
                        child: LinearProgressIndicator(
                          value: pct,
                          backgroundColor: Colors.white10,
                          valueColor: AlwaysStoppedAnimation<Color>(b.especie.toLowerCase().contains('tilapia') ? AppColors.cyanWater : Colors.purpleAccent),
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

        const SizedBox(height: 10),

        // 2. Estructura Financiera Global del Policultivo
        Text('💰 INVERSIÓN TOTAL DEL POLICULTIVO', style: AppTypography.labelMicro.copyWith(color: AppColors.greenBiomass, letterSpacing: 1.2, fontWeight: FontWeight.w800)),
        const SizedBox(height: 6),
        Container(
          padding: const EdgeInsets.all(10),
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
              const Divider(height: 8, color: Colors.white12),
              _buildFinancialRow(context, '• Total Semilla/Alevinaje:', CurrencyFormatters.formatCOP(totalAlevines)),
              _buildFinancialRow(context, '• Total Alimento e Insumos:', CurrencyFormatters.formatCOP(totalInsumos)),
              _buildFinancialRow(context, '• Total Costos Fijos Asignados:', CurrencyFormatters.formatCOP(totalFijos)),
              const Divider(height: 8, color: Colors.white24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('INVERSIÓN TOTAL EN ESTANQUE:', style: TextStyle(color: Theme.of(context).brightness == Brightness.dark ? Colors.white : AppColors.textPrimaryLight, fontWeight: FontWeight.w800, fontSize: 11)),
                  Text(CurrencyFormatters.formatCOP(granTotal), style: const TextStyle(color: AppColors.greenBiomass, fontWeight: FontWeight.w900, fontSize: 13)),
                ],
              ),
              const SizedBox(height: 2),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('CPK Promedio Ponderado:', style: TextStyle(color: Theme.of(context).brightness == Brightness.dark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight, fontSize: 10)),
                  Text('${CurrencyFormatters.formatCOP(cpkGlobal)} / kg', style: const TextStyle(color: AppColors.cyanWater, fontWeight: FontWeight.w800, fontSize: 11)),
                ],
              ),
            ],
          ),
        ),
      ],
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
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: TextStyle(color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight, fontSize: 10)),
            Text(value, style: TextStyle(color: isDark ? Colors.white : AppColors.textPrimaryLight, fontWeight: FontWeight.w700, fontSize: 11)),
          ],
        ),
        Text(extra, style: TextStyle(color: extraColor, fontWeight: FontWeight.w800, fontSize: 11)),
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
          Text(title, style: TextStyle(color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight, fontSize: 10)),
          Text(amount, style: TextStyle(color: isDark ? Colors.white : AppColors.textPrimaryLight, fontWeight: FontWeight.w600, fontSize: 11)),
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
          Text(label, style: AppTypography.labelMicro.copyWith(color: color, fontSize: 8)),
          const SizedBox(height: 2),
          FittedBox(
            fit: BoxFit.scaleDown,
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
            Text(caption, style: TextStyle(color: color.withValues(alpha: 0.8), fontSize: 9, fontWeight: FontWeight.w600)),
          ],
        ],
      ),
    );
  }
}
