import 'package:flutter/material.dart';
import 'package:fishbit_finance/core/design_system/app_colors.dart';
import 'package:fishbit_finance/core/design_system/app_typography.dart';
import 'package:fishbit_finance/core/utils/currency_formatters.dart';

/// Tarjeta interactiva de Precio de Venta por Especie inspirada en el diseño
/// Uiverse de JohnnyCSilva, adaptada a FishBit (Dark OLED & Light Neomórfico).
class SpeciesPriceCard extends StatefulWidget {
  final String especie;
  final double precioKg;
  final String subtitle;
  final VoidCallback onTap;

  const SpeciesPriceCard({
    super.key,
    required this.especie,
    required this.precioKg,
    required this.subtitle,
    required this.onTap,
  });

  @override
  State<SpeciesPriceCard> createState() => _SpeciesPriceCardState();
}

class _SpeciesPriceCardState extends State<SpeciesPriceCard> {
  bool _isCardHovered = false;
  bool _isSaveHovered = false;

  _SpeciesPalette _paletteFor(String especie) {
    final lower = especie.toLowerCase();
    if (lower.contains('tilapia')) {
      return const _SpeciesPalette(
        gradientTop: Color(0xFFE66465),
        gradientBottom: Color(0xFF9198E5),
        accent: Color(0xFF9198E5),
        pillLightBg: Color(0xFFE3FFF9),
      );
    }
    if (lower.contains('cachama')) {
      return const _SpeciesPalette(
        gradientTop: Color(0xFF00B2CC),
        gradientBottom: Color(0xFF6366F1),
        accent: Color(0xFF00B2CC),
        pillLightBg: Color(0xFFE0F7FA),
      );
    }
    if (lower.contains('bocachico')) {
      return const _SpeciesPalette(
        gradientTop: Color(0xFF10B981),
        gradientBottom: Color(0xFF0EA5E9),
        accent: Color(0xFF10B981),
        pillLightBg: Color(0xFFE3FFF9),
      );
    }
    if (lower.contains('pangasius')) {
      return const _SpeciesPalette(
        gradientTop: Color(0xFF8B5CF6),
        gradientBottom: Color(0xFF3B82F6),
        accent: Color(0xFF8B5CF6),
        pillLightBg: Color(0xFFEDE9FE),
      );
    }
    if (lower.contains('trucha')) {
      return const _SpeciesPalette(
        gradientTop: Color(0xFF06B6D4),
        gradientBottom: Color(0xFFA855F7),
        accent: Color(0xFF06B6D4),
        pillLightBg: Color(0xFFE0F2FE),
      );
    }
    if (lower.contains('camar') || lower.contains('langostino')) {
      return const _SpeciesPalette(
        gradientTop: Color(0xFFF59E0B),
        gradientBottom: Color(0xFFEF4444),
        accent: Color(0xFFF59E0B),
        pillLightBg: Color(0xFFFEF3C7),
      );
    }
    return const _SpeciesPalette(
      gradientTop: Color(0xFFE66465),
      gradientBottom: Color(0xFF9198E5),
      accent: Color(0xFF9198E5),
      pillLightBg: Color(0xFFE3FFF9),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final palette = _paletteFor(widget.especie);

    final cardBg = isDark ? const Color(0xFF101827) : Colors.white;
    final cardBorder = isDark
        ? (_isCardHovered
            ? palette.accent.withValues(alpha: 0.55)
            : Colors.white.withValues(alpha: 0.09))
        : Colors.black.withValues(alpha: 0.05);

    final shadows = isDark
        ? [
            BoxShadow(
              color: _isCardHovered
                  ? palette.accent.withValues(alpha: 0.24)
                  : Colors.black.withValues(alpha: 0.36),
              blurRadius: _isCardHovered ? 24 : 16,
              offset: Offset(0, _isCardHovered ? 10 : 6),
            ),
          ]
        : _isCardHovered
            ? [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.12),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ]
            : [
                BoxShadow(
                  color: const Color(0xFFBEBEBE).withValues(alpha: 0.55),
                  blurRadius: 22,
                  offset: const Offset(10, 10),
                ),
                BoxShadow(
                  color: Colors.white.withValues(alpha: 0.90),
                  blurRadius: 20,
                  offset: const Offset(-8, -8),
                ),
              ];

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _isCardHovered = true),
      onExit: (_) => setState(() => _isCardHovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeInOut,
          width: 220,
          height: 232,
          transform: Matrix4.translationValues(0, _isCardHovered ? -3.0 : 0.0, 0),
          decoration: BoxDecoration(
            color: cardBg,
            borderRadius: BorderRadius.circular(28),
            border: Border.all(color: cardBorder, width: 1),
            boxShadow: shadows,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Mitad superior (.img): gradiente por especie + watermark + botón flotante .save
              Container(
                width: double.infinity,
                height: 106,
                decoration: BoxDecoration(
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(27),
                  ),
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [palette.gradientTop, palette.gradientBottom],
                  ),
                ),
                child: Stack(
                  children: [
                    // Marca de agua acuática sutil
                    Positioned(
                      left: 16,
                      bottom: 12,
                      child: Icon(
                        Icons.set_meal_rounded,
                        size: 52,
                        color: Colors.white.withValues(alpha: 0.22),
                      ),
                    ),
                    // Botón superior derecho (.save) con animación scale(1.1) + rotate(10deg)
                    Positioned(
                      top: 14,
                      right: 14,
                      child: MouseRegion(
                        cursor: SystemMouseCursors.click,
                        onEnter: (_) => setState(() => _isSaveHovered = true),
                        onExit: (_) => setState(() => _isSaveHovered = false),
                        child: GestureDetector(
                          onTap: widget.onTap,
                          child: AnimatedScale(
                            scale: _isSaveHovered ? 1.12 : 1.0,
                            duration: const Duration(milliseconds: 200),
                            curve: Curves.easeInOut,
                            child: AnimatedRotation(
                              turns: _isSaveHovered ? 0.028 : 0.0, // ~10 deg
                              duration: const Duration(milliseconds: 200),
                              curve: Curves.easeInOut,
                              child: Container(
                                width: 32,
                                height: 32,
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.96),
                                  borderRadius: BorderRadius.circular(10),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withValues(alpha: 0.14),
                                      blurRadius: 8,
                                      offset: const Offset(0, 3),
                                    ),
                                  ],
                                ),
                                alignment: Alignment.center,
                                child: Icon(
                                  Icons.edit_rounded,
                                  size: 16,
                                  color: _isSaveHovered
                                      ? palette.accent
                                      : const Color(0xFF64748B),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Mitad inferior (.text): título especie, subtítulo y píldora de precio (.icon-box)
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.especie,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppTypography.titleSmall.copyWith(
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                              color: isDark
                                  ? Colors.white
                                  : AppColors.textPrimaryLight,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            widget.subtitle,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w500,
                              color: isDark
                                  ? AppColors.textSecondaryDark
                                  : const Color(0xFF888888),
                            ),
                          ),
                        ],
                      ),

                      // Píldora inferior (.icon-box)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: isDark
                              ? palette.accent.withValues(alpha: 0.14)
                              : palette.pillLightBg,
                          borderRadius: BorderRadius.circular(10),
                          border: isDark
                              ? Border.all(
                                  color: palette.accent.withValues(alpha: 0.28),
                                )
                              : null,
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.sell_rounded,
                              size: 15,
                              color: palette.accent,
                            ),
                            const SizedBox(width: 8),
                            Flexible(
                              child: FittedBox(
                                fit: BoxFit.scaleDown,
                                alignment: Alignment.centerLeft,
                                child: Text(
                                  '${CurrencyFormatters.formatCOP(widget.precioKg)} / Kg',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w800,
                                    color: isDark
                                        ? Colors.white
                                        : palette.accent,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SpeciesPalette {
  final Color gradientTop;
  final Color gradientBottom;
  final Color accent;
  final Color pillLightBg;

  const _SpeciesPalette({
    required this.gradientTop,
    required this.gradientBottom,
    required this.accent,
    required this.pillLightBg,
  });
}
