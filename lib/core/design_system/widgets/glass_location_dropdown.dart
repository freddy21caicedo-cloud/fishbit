import 'package:flutter/material.dart';
import 'package:fishbit_finance/core/design_system/app_colors.dart';
import 'package:fishbit_finance/core/design_system/glass_select_field.dart';

/// Selector desplegable geográfico (País / Departamento / Ciudad)
/// basado en [GlassSelectField] para desplegar el ListBox anclado debajo
/// de la caja con scroll interno y estética Glassmorphism.
class GlassLocationDropdown extends StatelessWidget {
  final String label;
  final String value;
  final List<String> items;
  final IconData icon;
  final Color accentColor;
  final ValueChanged<String> onChanged;

  const GlassLocationDropdown({
    super.key,
    required this.label,
    required this.value,
    required this.items,
    required this.icon,
    this.accentColor = AppColors.cyanWater,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveValue = items.contains(value)
        ? value
        : (items.isNotEmpty ? items.first : value);

    return GlassSelectField<String>(
      label: label,
      value: items.contains(effectiveValue) ? effectiveValue : null,
      accentColor: accentColor,
      leadingIcon: icon,
      options: items
          .map((item) => GlassSelectOption<String>(
                value: item,
                label: item,
                icon: icon,
              ))
          .toList(),
      onChanged: (newValue) {
        if (newValue != null && newValue != value) {
          onChanged(newValue);
        }
      },
    );
  }
}
