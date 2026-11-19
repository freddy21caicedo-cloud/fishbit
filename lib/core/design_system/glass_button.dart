import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fishbit_finance/core/design_system/app_colors.dart';
import 'package:fishbit_finance/core/design_system/app_typography.dart';

class GlassButton extends StatefulWidget {
  final String label;
  final String? loadingLabel;
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
    this.loadingLabel,
    this.onPressed,
    this.isLoading = false,
    this.backgroundColor,
    this.textColor,
    this.icon,
    this.height = 54.0,
    this.borderRadius = 16.0,
  });

  @override
  State<GlassButton> createState() => _GlassButtonState();
}

class _GlassButtonState extends State<GlassButton> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final themeColor = widget.backgroundColor ?? AppColors.cyanWater;
    final effectiveTextColor = widget.textColor ??
        (themeColor.computeLuminance() > 0.45 ? const Color(0xFF0F172A) : Colors.white);
    final isInteractive = !widget.isLoading && widget.onPressed != null;

    return Semantics(
      button: true,
      label: widget.label,
      child: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTapDown: isInteractive ? (_) => setState(() => _isPressed = true) : null,
        onTapUp: isInteractive ? (_) => setState(() => _isPressed = false) : null,
        onTapCancel: isInteractive ? () => setState(() => _isPressed = false) : null,
        child: AnimatedScale(
          scale: _isPressed ? 0.98 : 1.0,
          duration: const Duration(milliseconds: 110),
          curve: Curves.easeOutCubic,
          child: SizedBox(
            height: widget.height,
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: themeColor,
                disabledBackgroundColor: themeColor.withValues(alpha: 0.55),
                foregroundColor: effectiveTextColor,
                disabledForegroundColor: effectiveTextColor.withValues(alpha: 0.85),
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(widget.borderRadius),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 20),
              ),
              onPressed: isInteractive
                  ? () {
                      HapticFeedback.lightImpact();
                      widget.onPressed!();
                    }
                  : null,
              child: widget.isLoading
                  ? Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SizedBox(
                          height: 18,
                          width: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.4,
                            valueColor: AlwaysStoppedAnimation<Color>(effectiveTextColor),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Flexible(
                          child: Text(
                            widget.loadingLabel ?? 'Guardando...',
                            overflow: TextOverflow.ellipsis,
                            style: AppTypography.titleSmall.copyWith(
                              color: effectiveTextColor,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ],
                    )
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (widget.icon != null) ...[
                          widget.icon!,
                          const SizedBox(width: 8),
                        ],
                        Flexible(
                          child: Text(
                            widget.label,
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
        ),
      ),
    );
  }
}
