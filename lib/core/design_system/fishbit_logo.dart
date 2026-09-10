import 'package:flutter/material.dart';
import 'package:fishbit_finance/core/design_system/app_colors.dart';

/// Componente oficial de identidad visual y logotipo para FishBit
/// Soporta despliegue como Isotipo compacto, Icono con Squircle o Logo Completo con Wordmark.
class FishBitLogo extends StatelessWidget {
  final double size;
  final bool showWordmark;
  final bool withSquircle;
  final String? subtitle;

  const FishBitLogo({
    super.key,
    this.size = 38.0,
    this.showWordmark = false,
    this.withSquircle = true,
    this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    Widget iconWidget = ClipRRect(
      borderRadius: BorderRadius.circular(withSquircle ? size * 0.24 : 0),
      child: Image.asset(
        'assets/icons/fishbit_logo.png',
        width: size,
        height: size,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              color: AppColors.backgroundDark,
              borderRadius: BorderRadius.circular(size * 0.24),
              border: Border.all(
                color: AppColors.cyanWater.withValues(alpha: 0.5),
                width: 1,
              ),
            ),
            child: Icon(
              Icons.waves,
              color: AppColors.cyanWater,
              size: size * 0.6,
            ),
          );
        },
      ),
    );

    if (withSquircle) {
      iconWidget = Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(size * 0.24),
          boxShadow: [
            BoxShadow(
              color: AppColors.cyanWater.withValues(alpha: 0.25),
              blurRadius: size * 0.35,
              offset: Offset(0, size * 0.08),
            ),
          ],
        ),
        child: iconWidget,
      );
    }

    if (!showWordmark) {
      return iconWidget;
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        iconWidget,
        const SizedBox(width: 10),
        Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Fish',
                  style: TextStyle(
                    fontSize: size * 0.52,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.8,
                    color: AppColors.cyanWater,
                    shadows: [
                      Shadow(
                        color: AppColors.cyanWater.withValues(alpha: 0.5),
                        blurRadius: 10,
                      ),
                    ],
                  ),
                ),
                Text(
                  'Bit.',
                  style: TextStyle(
                    fontSize: size * 0.52,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.8,
                    color: AppColors.coralAction,
                    shadows: [
                      Shadow(
                        color: AppColors.coralAction.withValues(alpha: 0.5),
                        blurRadius: 10,
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
        ),
      ],
    );
  }
}
