import 'package:flutter/material.dart';
import 'package:fishbit_finance/core/design_system/app_colors.dart';
import 'package:fishbit_finance/core/design_system/app_typography.dart';
import 'package:fishbit_finance/core/design_system/glass_container.dart';

class GlassFormField extends StatelessWidget {
  final String label;
  final String? hint;
  final TextEditingController? controller;
  final bool obscureText;
  final TextInputType? keyboardType;
  final IconData? prefixIcon;
  final Widget? suffixWidget;
  final String? Function(String?)? validator;
  final void Function(String)? onChanged;
  final VoidCallback? onTap;
  final bool isReadOnly;

  const GlassFormField({
    super.key,
    required this.label,
    this.hint,
    this.controller,
    this.obscureText = false,
    this.keyboardType,
    this.prefixIcon,
    this.suffixWidget,
    this.validator,
    this.onChanged,
    this.onTap,
    this.isReadOnly = false,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppTypography.bodySmall.copyWith(
            fontWeight: FontWeight.w600,
            color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
          ),
        ),
        const SizedBox(height: 8),
        GlassContainer(
          borderRadius: 16,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
          opacity: isDark ? 0.04 : 0.9,
          borderColor: isDark ? Colors.white.withValues(alpha: 0.12) : AppColors.glassBorderLight,
          child: TextFormField(
            controller: controller,
            obscureText: obscureText,
            keyboardType: keyboardType,
            readOnly: isReadOnly,
            onTap: onTap,
            validator: validator,
            onChanged: onChanged,
            style: AppTypography.bodyMedium.copyWith(
              color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
            ),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: AppTypography.bodyMedium.copyWith(
                color: isDark ? AppColors.textTertiaryDark : AppColors.textTertiaryLight,
              ),
              prefixIcon: prefixIcon != null
                  ? Icon(prefixIcon, color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight, size: 20)
                  : null,
              suffixIcon: suffixWidget,
              border: InputBorder.none,
              enabledBorder: InputBorder.none,
              focusedBorder: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(vertical: 14),
            ),
          ),
        ),
      ],
    );
  }
}
