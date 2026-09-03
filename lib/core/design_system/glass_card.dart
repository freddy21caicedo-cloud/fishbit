import 'package:flutter/material.dart';
import 'package:fishbit_finance/core/design_system/app_colors.dart';
import 'package:fishbit_finance/core/design_system/app_typography.dart';
import 'package:fishbit_finance/core/design_system/glass_container.dart';

/// Tarjeta Bento Glassmorphic para KPIs, Estanques y Alertas
class GlassCard extends StatelessWidget {
  final Widget? titleWidget;
  final String? title;
  final String? subtitle;
  final Widget child;
  final Widget? leadingIcon;
  final Widget? trailingWidget;
  final Color? glowColor;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry? padding;
  final double borderRadius;

  const GlassCard({
    super.key,
    this.title,
    this.subtitle,
    this.titleWidget,
    required this.child,
    this.leadingIcon,
    this.trailingWidget,
    this.glowColor,
    this.onTap,
    this.padding,
    this.borderRadius = 20.0,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    Widget content = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (title != null || titleWidget != null || leadingIcon != null || trailingWidget != null) ...[
          Row(
            children: [
              if (leadingIcon != null) ...[
                leadingIcon!,
                const SizedBox(width: 8),
              ],
              Expanded(
                child: titleWidget ??
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (title != null)
                          Text(
                            title!.toUpperCase(),
                            style: AppTypography.labelMicro.copyWith(
                              color: glowColor ?? (isDark ? AppColors.cyanWater : AppColors.blueOcean),
                            ),
                          ),
                        if (subtitle != null) ...[
                          const SizedBox(height: 2),
                          Text(
                            subtitle!,
                            style: AppTypography.bodySmall.copyWith(
                              color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                            ),
                          ),
                        ],
                      ],
                    ),
              ),
              if (trailingWidget != null) trailingWidget!,
            ],
          ),
          const SizedBox(height: 12),
        ],
        child,
      ],
    );

    final card = GlassContainer(
      borderRadius: borderRadius,
      padding: padding ?? const EdgeInsets.all(16),
      borderColor: glowColor?.withValues(alpha: 0.3) ??
          (isDark ? Colors.white.withValues(alpha: 0.08) : AppColors.glassBorderLight),
      child: content,
    );

    if (onTap != null) {
      return InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(borderRadius),
        child: card,
      );
    }

    return card;
  }
}
