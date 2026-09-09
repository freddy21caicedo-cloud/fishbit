import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fishbit_finance/core/design_system/app_colors.dart';
import 'package:fishbit_finance/core/design_system/app_typography.dart';
import 'package:fishbit_finance/core/design_system/glass_container.dart';

/// Campo de formulario Glassmorphic de alto nivel con foco interactivo (Focus Glow),
/// validación perimetral de error, botón de limpieza rápida y formateadores.
class GlassFormField extends StatefulWidget {
  final String label;
  final String? hint;
  final TextEditingController? controller;
  final bool obscureText;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final TextCapitalization textCapitalization;
  final IconData? prefixIcon;
  final Widget? prefixWidget;
  final Widget? suffixWidget;
  final String? Function(String?)? validator;
  final void Function(String)? onChanged;
  final void Function(String)? onFieldSubmitted;
  final VoidCallback? onTap;
  final bool isReadOnly;
  final bool isRequired;
  final bool showClearButton;
  final Color? accentColor;
  final List<TextInputFormatter>? inputFormatters;
  final FocusNode? focusNode;
  final int maxLines;
  final int? maxLength;

  const GlassFormField({
    super.key,
    required this.label,
    this.hint,
    this.controller,
    this.obscureText = false,
    this.keyboardType,
    this.textInputAction,
    this.textCapitalization = TextCapitalization.none,
    this.prefixIcon,
    this.prefixWidget,
    this.suffixWidget,
    this.validator,
    this.onChanged,
    this.onFieldSubmitted,
    this.onTap,
    this.isReadOnly = false,
    this.isRequired = false,
    this.showClearButton = false,
    this.accentColor,
    this.inputFormatters,
    this.focusNode,
    this.maxLines = 1,
    this.maxLength,
  });

  @override
  State<GlassFormField> createState() => _GlassFormFieldState();
}

class _GlassFormFieldState extends State<GlassFormField> {
  late final FocusNode _focusNode;
  bool _isInternalFocusNode = false;
  bool _isFocused = false;
  String? _errorText;
  bool _hasText = false;

  @override
  void initState() {
    super.initState();
    if (widget.focusNode != null) {
      _focusNode = widget.focusNode!;
    } else {
      _focusNode = FocusNode();
      _isInternalFocusNode = true;
    }

    _isFocused = _focusNode.hasFocus;
    _focusNode.addListener(_onFocusChange);

    if (widget.controller != null) {
      _hasText = widget.controller!.text.isNotEmpty;
      widget.controller!.addListener(_onTextChange);
    }
  }

  void _onFocusChange() {
    if (mounted) {
      setState(() => _isFocused = _focusNode.hasFocus);
    }
  }

  void _onTextChange() {
    if (widget.controller != null && mounted) {
      final hasTextNow = widget.controller!.text.isNotEmpty;
      if (hasTextNow != _hasText) {
        setState(() => _hasText = hasTextNow);
      }
    }
  }

  @override
  void dispose() {
    _focusNode.removeListener(_onFocusChange);
    if (_isInternalFocusNode) {
      _focusNode.dispose();
    }
    widget.controller?.removeListener(_onTextChange);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final effectiveAccent = widget.accentColor ?? AppColors.cyanWater;
    final hasError = _errorText != null && _errorText!.isNotEmpty;

    // Colores de borde y resplandor según estado
    final Color borderColor;
    final double borderAlpha;
    if (hasError) {
      borderColor = AppColors.coralAction;
      borderAlpha = 0.85;
    } else if (_isFocused) {
      borderColor = effectiveAccent;
      borderAlpha = isDark ? 0.75 : 0.90;
    } else {
      borderColor = isDark ? Colors.white : AppColors.glassBorderLight;
      borderAlpha = isDark ? 0.12 : 1.0;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        // Etiqueta superior con indicador de requerido
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            RichText(
              text: TextSpan(
                text: widget.label,
                style: AppTypography.bodySmall.copyWith(
                  fontWeight: FontWeight.w700,
                  fontSize: 11,
                  letterSpacing: 0.6,
                  color: hasError
                      ? AppColors.coralAction
                      : (_isFocused
                          ? effectiveAccent
                          : (isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight)),
                ),
                children: [
                  if (widget.isRequired)
                    const TextSpan(
                      text: ' *',
                      style: TextStyle(
                        color: AppColors.coralAction,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),

        // Contenedor Glass con animación de foco perimetral
        AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOutCubic,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              if (_isFocused && !hasError)
                BoxShadow(
                  color: effectiveAccent.withValues(alpha: isDark ? 0.22 : 0.15),
                  blurRadius: 12,
                  spreadRadius: 1,
                ),
              if (hasError)
                BoxShadow(
                  color: AppColors.coralAction.withValues(alpha: 0.25),
                  blurRadius: 10,
                  spreadRadius: 1,
                ),
            ],
          ),
          child: GlassContainer(
            borderRadius: 16,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
            opacity: isDark ? (_isFocused ? 0.08 : 0.04) : (_isFocused ? 0.98 : 0.90),
            borderColor: borderColor.withValues(alpha: borderAlpha),
            child: TextFormField(
              controller: widget.controller,
              focusNode: _focusNode,
              obscureText: widget.obscureText,
              keyboardType: widget.keyboardType,
              textInputAction: widget.textInputAction,
              textCapitalization: widget.textCapitalization,
              readOnly: widget.isReadOnly,
              onTap: widget.onTap,
              maxLines: widget.maxLines,
              maxLength: widget.maxLength,
              inputFormatters: widget.inputFormatters,
              onFieldSubmitted: widget.onFieldSubmitted,
              validator: (v) {
                final err = widget.validator?.call(v);
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (mounted && _errorText != err) {
                    setState(() => _errorText = err);
                  }
                });
                return err != null ? '' : null; // Suprime el mensaje feo estándar de Material
              },
              onChanged: (val) {
                if (hasError) {
                  setState(() => _errorText = null);
                }
                widget.onChanged?.call(val);
              },
              style: AppTypography.bodyMedium.copyWith(
                color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                fontWeight: FontWeight.w600,
                fontSize: 13.5,
              ),
              decoration: InputDecoration(
                hintText: widget.hint,
                hintStyle: AppTypography.bodyMedium.copyWith(
                  color: isDark ? AppColors.textTertiaryDark : AppColors.textTertiaryLight,
                  fontWeight: FontWeight.w400,
                  fontSize: 13,
                ),
                prefixIcon: widget.prefixWidget ??
                    (widget.prefixIcon != null
                        ? Icon(
                            widget.prefixIcon,
                            color: hasError
                                ? AppColors.coralAction
                                : (_isFocused
                                    ? effectiveAccent
                                    : (isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight)),
                            size: 19,
                          )
                        : null),
                suffixIcon: widget.suffixWidget ??
                    (widget.showClearButton && _hasText && !widget.isReadOnly
                        ? IconButton(
                            icon: const Icon(Icons.cancel_rounded, size: 18),
                            color: isDark ? Colors.white38 : Colors.black38,
                            tooltip: 'Limpiar campo',
                            onPressed: () {
                              widget.controller?.clear();
                              widget.onChanged?.call('');
                            },
                          )
                        : null),
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                errorBorder: InputBorder.none,
                focusedErrorBorder: InputBorder.none,
                errorStyle: const TextStyle(height: 0, fontSize: 0), // Evita brinco de layout
                contentPadding: const EdgeInsets.symmetric(vertical: 13),
              ),
            ),
          ),
        ),

        // Mensaje de error personalizado y estético
        if (hasError) ...[
          const SizedBox(height: 4),
          Padding(
            padding: const EdgeInsets.only(left: 6),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.error_outline_rounded, size: 12, color: AppColors.coralAction),
                const SizedBox(width: 4),
                Flexible(
                  child: Text(
                    _errorText!,
                    style: AppTypography.labelMicro.copyWith(
                      color: AppColors.coralAction,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}
