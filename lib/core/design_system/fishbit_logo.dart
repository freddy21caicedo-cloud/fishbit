import 'package:flutter/material.dart';
import 'package:fishbit_finance/core/design_system/app_colors.dart';

/// Componente oficial de identidad visual para FishBit.
/// Renderiza el wordmark tipográfico "FishBit." con acentos de marca.
class FishBitLogo extends StatelessWidget {
  final double size;
  final bool showWordmark;
  final bool withSquircle;
  final String? subtitle;

  const FishBitLogo({
    super.key,
    this.size = 38.0,
    this.showWordmark = true,
    this.withSquircle = false,
    this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final fontSize = size * 0.56;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Fish',
              style: TextStyle(
                fontSize: fontSize,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.8,
                color: AppColors.cyanWater,
                shadows: [
                  Shadow(
                    color: AppColors.cyanWater.withValues(alpha: 0.5),
                    blurRadius: 12,
                  ),
                ],
              ),
            ),
            Text(
              'Bit.',
              style: TextStyle(
                fontSize: fontSize,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.8,
                color: AppColors.coralAction,
                shadows: [
                  Shadow(
                    color: AppColors.coralAction.withValues(alpha: 0.5),
                    blurRadius: 12,
                  ),
                ],
              ),
            ),
          ],
        ),
        if (subtitle != null) ...[
          const SizedBox(height: 1),
          Text(
            subtitle!,
            style: TextStyle(
              fontSize: size * 0.24,
              fontWeight: FontWeight.w500,
              color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
              letterSpacing: 0.2,
            ),
          ),
        ],
      ],
    );
  }
}
