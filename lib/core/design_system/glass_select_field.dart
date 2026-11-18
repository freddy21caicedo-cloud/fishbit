import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:fishbit_finance/core/design_system/app_colors.dart';
import 'package:fishbit_finance/core/design_system/app_typography.dart';

/// Opción individual dentro de [GlassSelectField] (equivalente a `ListBox.Item`).
class GlassSelectOption<T> {
  final T value;
  final String label;
  final String? subtitle;
  final IconData? icon;
  final String? badgeText;
  final Color? badgeColor;

  const GlassSelectOption({
    required this.value,
    required this.label,
    this.subtitle,
    this.icon,
    this.badgeText,
    this.badgeColor,
  });
}

/// ComboBox Glassmorphism inspirado en la anatomía de HeroUI v3:
/// `ComboBox` -> `Label` -> `ComboBox.InputGroup` (`Input` inline + `ComboBox.Trigger`)
/// -> `ComboBox.Popover` -> `ListBox` scrolleable con `ListBox.ItemIndicator`.
class GlassSelectField<T> extends StatefulWidget {
  final String? label;
  final String placeholder;
  final T? value;
  final List<GlassSelectOption<T>> options;
  final ValueChanged<T?> onChanged;
  final Color accentColor;
  final IconData? leadingIcon;
  final bool? enableSearch;
  final String? Function(T?)? validator;

  const GlassSelectField({
    super.key,
    this.label,
    this.placeholder = 'Buscar o seleccionar...',
    required this.value,
    required this.options,
    required this.onChanged,
    this.accentColor = AppColors.cyanWater,
    this.leadingIcon,
    this.enableSearch,
    this.validator,
  });

  @override
  State<GlassSelectField<T>> createState() => _GlassSelectFieldState<T>();
}

class _GlassSelectFieldState<T> extends State<GlassSelectField<T>> {
  final LayerLink _layerLink = LayerLink();
  final OverlayPortalController _overlayController = OverlayPortalController();
  final GlobalKey _inputGroupKey = GlobalKey();
  final TextEditingController _inputCtrl = TextEditingController();
  final FocusNode _focusNode = FocusNode();

  bool _isOpen = false;
  bool _openAbove = false;
  bool _isFiltering = false;
  double _triggerWidth = 260.0;
  String _query = '';
  FormFieldState<T>? _activeFormState;

  @override
  void initState() {
    super.initState();
    _syncInputTextFromValue();
    _focusNode.addListener(_onFocusChanged);
  }

  @override
  void didUpdateWidget(covariant GlassSelectField<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.value != widget.value || oldWidget.options != widget.options) {
      if (!_isOpen) {
        _syncInputTextFromValue();
      }
    }
  }

  @override
  void dispose() {
    _focusNode.removeListener(_onFocusChanged);
    _focusNode.dispose();
    _inputCtrl.dispose();
    super.dispose();
  }

  void _syncInputTextFromValue() {
    final selectedOpt = widget.options.where((o) => o.value == widget.value).firstOrNull;
    _inputCtrl.text = selectedOpt?.label ?? '';
  }

  void _onFocusChanged() {
    if (_focusNode.hasFocus && !_isOpen) {
      _openPopover(filterMode: false);
    }
  }

  void _toggleFromTrigger(FormFieldState<T>? formState) {
    _activeFormState = formState;
    if (_isOpen) {
      _closePopover();
    } else {
      _focusNode.requestFocus();
      _openPopover(filterMode: false);
    }
  }

  void _openPopover({required bool filterMode}) {
    final renderBox = _inputGroupKey.currentContext?.findRenderObject() as RenderBox?;
    if (renderBox != null) {
      final size = renderBox.size;
      final offset = renderBox.localToGlobal(Offset.zero);
      final screenHeight = MediaQuery.sizeOf(context).height;
      final bottomInset = MediaQuery.viewInsetsOf(context).bottom;
      final availableBelow = screenHeight - bottomInset - (offset.dy + size.height) - 16;

      _triggerWidth = size.width;
      _openAbove = availableBelow < 180 && offset.dy > 220;
    }

    setState(() {
      _isOpen = true;
      _isFiltering = filterMode;
      if (!filterMode) _query = '';
    });
    _overlayController.show();
  }

  void _closePopover() {
    if (!_isOpen) return;
    _overlayController.hide();
    _focusNode.unfocus();
    if (mounted) {
      setState(() {
        _isOpen = false;
        _isFiltering = false;
        _query = '';
        _syncInputTextFromValue();
      });
    }
  }

  void _selectValue(T val) {
    _overlayController.hide();
    _focusNode.unfocus();
    final opt = widget.options.where((o) => o.value == val).firstOrNull;
    if (mounted) {
      setState(() {
        _isOpen = false;
        _isFiltering = false;
        _query = '';
        _inputCtrl.text = opt?.label ?? '';
      });
    }
    _activeFormState?.didChange(val);
    widget.onChanged(val);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final selectedOpt = widget.options.where((o) => o.value == widget.value).firstOrNull;
    final canType = widget.enableSearch ?? true;

    Widget buildComboBox(FormFieldState<T>? formState) {
      _activeFormState = formState;
      final hasError = formState?.hasError == true;
      final borderColor = hasError
          ? AppColors.coralAction
          : (_isOpen || _focusNode.hasFocus
              ? widget.accentColor
              : (isDark ? Colors.white.withValues(alpha: 0.14) : AppColors.glassBorderLight));

      return OverlayPortal(
        controller: _overlayController,
        overlayChildBuilder: (overlayCtx) {
          final filtered = (!_isFiltering || _query.isEmpty)
              ? widget.options
              : widget.options.where((o) {
                  final q = _query.toLowerCase();
                  return o.label.toLowerCase().contains(q) ||
                      (o.subtitle ?? '').toLowerCase().contains(q) ||
                      (o.badgeText ?? '').toLowerCase().contains(q);
                }).toList();

          return Stack(
            children: [
              // Tap fuera para cerrar el ComboBox.Popover
              Positioned.fill(
                child: GestureDetector(
                  behavior: HitTestBehavior.translucent,
                  onTap: _closePopover,
                  child: const SizedBox.expand(),
                ),
              ),
              // ComboBox.Popover anclado exactamente al ComboBox.InputGroup sin taparlo
              CompositedTransformFollower(
                link: _layerLink,
                showWhenUnlinked: false,
                targetAnchor: _openAbove ? Alignment.topLeft : Alignment.bottomLeft,
                followerAnchor: _openAbove ? Alignment.bottomLeft : Alignment.topLeft,
                offset: Offset(0, _openAbove ? -6 : 6),
                child: Builder(
                  builder: (_) {
                    final double popoverWidth = _triggerWidth < 220.0 ? 220.0 : _triggerWidth;
                    return Material(
                      type: MaterialType.transparency,
                      child: ConstrainedBox(
                        constraints: BoxConstraints(
                          minWidth: popoverWidth,
                          maxWidth: popoverWidth,
                          maxHeight: 225,
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: BackdropFilter(
                            filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                            child: Container(
                              width: popoverWidth,
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: isDark
                                ? const Color(0xFF111B27).withValues(alpha: 0.96)
                                : Colors.white.withValues(alpha: 0.98),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: widget.accentColor.withValues(alpha: 0.35),
                              width: 1.1,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: isDark ? 0.50 : 0.14),
                                blurRadius: 20,
                                offset: Offset(0, _openAbove ? -6 : 8),
                              ),
                            ],
                          ),
                          child: filtered.isEmpty
                              ? Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 18),
                                  child: Center(
                                    child: Text(
                                      'Sin coincidencias para "$_query"',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                                      ),
                                    ),
                                  ),
                                )
                              : Scrollbar(
                                  thumbVisibility: filtered.length > 4,
                                  radius: const Radius.circular(8),
                                  child: ListView.separated(
                                    shrinkWrap: true,
                                    padding: EdgeInsets.zero,
                                    physics: const BouncingScrollPhysics(),
                                    itemCount: filtered.length,
                                    separatorBuilder: (_, __) => const SizedBox(height: 2),
                                    itemBuilder: (_, index) {
                                      final opt = filtered[index];
                                      final isSel = opt.value == widget.value;

                                      return InkWell(
                                        onTap: () => _selectValue(opt.value),
                                        borderRadius: BorderRadius.circular(10),
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                          decoration: BoxDecoration(
                                            color: isSel
                                                ? widget.accentColor.withValues(alpha: isDark ? 0.20 : 0.12)
                                                : Colors.transparent,
                                            borderRadius: BorderRadius.circular(10),
                                          ),
                                          child: Row(
                                            children: [
                                              if (opt.icon != null) ...[
                                                Icon(
                                                  opt.icon,
                                                  size: 15,
                                                  color: isSel
                                                      ? widget.accentColor
                                                      : (isDark ? Colors.white60 : Colors.black54),
                                                ),
                                                const SizedBox(width: 8),
                                              ],
                                              Expanded(
                                                child: Column(
                                                  crossAxisAlignment: CrossAxisAlignment.start,
                                                  mainAxisSize: MainAxisSize.min,
                                                  children: [
                                                    Text(
                                                      opt.label,
                                                      maxLines: 1,
                                                      overflow: TextOverflow.ellipsis,
                                                      style: TextStyle(
                                                        fontSize: 12.5,
                                                        fontWeight: isSel ? FontWeight.w800 : FontWeight.w600,
                                                        color: isDark ? Colors.white : AppColors.textPrimaryLight,
                                                      ),
                                                    ),
                                                    if (opt.subtitle != null && opt.subtitle!.isNotEmpty)
                                                      Text(
                                                        opt.subtitle!,
                                                        maxLines: 1,
                                                        overflow: TextOverflow.ellipsis,
                                                        style: TextStyle(
                                                          fontSize: 10,
                                                          color: isDark
                                                              ? AppColors.textSecondaryDark
                                                              : AppColors.textSecondaryLight,
                                                        ),
                                                      ),
                                                  ],
                                                ),
                                              ),
                                              if (opt.badgeText != null) ...[
                                                const SizedBox(width: 6),
                                                Container(
                                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                                  decoration: BoxDecoration(
                                                    color: (opt.badgeColor ?? widget.accentColor)
                                                        .withValues(alpha: 0.15),
                                                    borderRadius: BorderRadius.circular(6),
                                                  ),
                                                  child: Text(
                                                    opt.badgeText!,
                                                    style: TextStyle(
                                                      color: opt.badgeColor ?? widget.accentColor,
                                                      fontSize: 9,
                                                      fontWeight: FontWeight.w800,
                                                    ),
                                                  ),
                                                ),
                                              ],
                                              if (isSel) ...[
                                                const SizedBox(width: 6),
                                                Icon(Icons.check_rounded, size: 16, color: widget.accentColor),
                                              ],
                                            ],
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                ),
                        ),
                      ),
                    ),
                  ),
                );
                  },
                ),
              ),
            ],
          );
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (widget.label != null && widget.label!.isNotEmpty) ...[
              Text(
                widget.label!,
                style: AppTypography.labelMicro.copyWith(
                  color: hasError
                      ? AppColors.coralAction
                      : (isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight),
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 6),
            ],
            // ComboBox.InputGroup = Input inline + ComboBox.Trigger
            CompositedTransformTarget(
              link: _layerLink,
              child: AnimatedContainer(
                key: _inputGroupKey,
                duration: const Duration(milliseconds: 160),
                padding: const EdgeInsets.only(left: 12, right: 6),
                decoration: BoxDecoration(
                  color: isDark ? Colors.white.withValues(alpha: 0.06) : Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: borderColor,
                    width: _isOpen || hasError ? 1.4 : 1.0,
                  ),
                ),
                child: Row(
                  children: [
                    if (selectedOpt?.icon != null || widget.leadingIcon != null) ...[
                      Icon(
                        selectedOpt?.icon ?? widget.leadingIcon,
                        size: 16,
                        color: widget.accentColor,
                      ),
                      const SizedBox(width: 8),
                    ],
                    Expanded(
                      child: TextField(
                        controller: _inputCtrl,
                        focusNode: _focusNode,
                        readOnly: !canType,
                        onTap: () {
                          if (!_isOpen) {
                            _openPopover(filterMode: false);
                          }
                        },
                        onChanged: (val) {
                          _query = val.trim();
                          _isFiltering = true;
                          if (!_isOpen) {
                            _openPopover(filterMode: true);
                          } else {
                            setState(() {});
                          }
                        },
                        style: TextStyle(
                          color: isDark ? Colors.white : AppColors.textPrimaryLight,
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                        ),
                        decoration: InputDecoration(
                          hintText: widget.placeholder,
                          hintStyle: TextStyle(
                            color: isDark ? AppColors.textTertiaryDark : AppColors.textTertiaryLight,
                            fontSize: 12.5,
                            fontWeight: FontWeight.w500,
                          ),
                          border: InputBorder.none,
                          isDense: true,
                          contentPadding: const EdgeInsets.symmetric(vertical: 11),
                        ),
                      ),
                    ),
                    if (!_isFiltering && selectedOpt?.badgeText != null) ...[
                      const SizedBox(width: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: (selectedOpt!.badgeColor ?? widget.accentColor).withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          selectedOpt.badgeText!,
                          style: TextStyle(
                            color: selectedOpt.badgeColor ?? widget.accentColor,
                            fontSize: 9,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ],
                    // ComboBox.Trigger
                    InkWell(
                      onTap: () => _toggleFromTrigger(formState),
                      borderRadius: BorderRadius.circular(10),
                      child: Padding(
                        padding: const EdgeInsets.all(6),
                        child: AnimatedRotation(
                          turns: _isOpen ? 0.5 : 0.0,
                          duration: const Duration(milliseconds: 180),
                          child: Icon(
                            Icons.keyboard_arrow_down_rounded,
                            size: 20,
                            color: widget.accentColor,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            if (hasError) ...[
              const SizedBox(height: 5),
              Padding(
                padding: const EdgeInsets.only(left: 10),
                child: Text(
                  formState!.errorText!,
                  style: const TextStyle(color: AppColors.coralAction, fontSize: 11, fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ],
        ),
      );
    }

    if (widget.validator != null) {
      return FormField<T>(
        initialValue: widget.value,
        validator: (_) => widget.validator!(widget.value),
        builder: (state) => buildComboBox(state),
      );
    }

    return buildComboBox(null);
  }
}
