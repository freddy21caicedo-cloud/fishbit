import 'package:flutter/material.dart';
import 'package:fishbit_finance/core/design_system/app_colors.dart';
import 'package:fishbit_finance/core/design_system/app_typography.dart';

class GlassButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;
  final Color? backgroundColor;
  final Color? textColor;
  final Widget? icon;
  final double height;
  final double borderRadius;

  const GlassButton({
    super.key,
    required this.label,
    this.onPressed,
    this.isLoading = false,
    this.backgroundColor,
    this.textColor,
    this.icon,
    this.height = 54.0,
    this.borderRadius = 16.0,
  });

  @override
  Widget build(BuildContext context) {
    final themeColor = backgroundColor ?? AppColors.cyanWater;
    final effectiveTextColor = textColor ?? (themeColor.computeLuminance() > 0.45 ? const Color(0xFF0F172A) : Colors.white);

    return Semantics(
      button: true,
      label: label,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        height: height,
        width: double.infinity,
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: themeColor,
            foregroundColor: effectiveTextColor,
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(borderRadius),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 20),
          ),
          onPressed: isLoading ? null : onPressed,
          child: isLoading
              ? SizedBox(
                  height: 22,
                  width: 22,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    valueColor: AlwaysStoppedAnimation<Color>(effectiveTextColor),
                  ),
                )
              : Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (icon != null) ...[
                      icon!,
                      const SizedBox(width: 8),
                    ],
                    Flexible(
                      child: Text(
                        label,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                        style: AppTypography.titleMedium.copyWith(
                          color: effectiveTextColor,
                          fontWeight: FontWeight.w800,
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
