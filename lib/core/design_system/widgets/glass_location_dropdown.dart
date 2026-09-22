import 'package:flutter/material.dart';
import 'package:fishbit_finance/core/design_system/app_colors.dart';

/// Selector desplegable tipo "buttonlist" con estética Dark Glassmorphic.
/// Despliega la lista directamente anclada al botón sin abrir modales ni ventanas
/// superpuestas que rompan el flujo visual del usuario.
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
    // Protección contra valores desincronizados durante cambios en cascada
    final effectiveValue = items.contains(value)
        ? value
        : (items.isNotEmpty ? items.first : value);

    return Container(
      constraints: const BoxConstraints(minHeight: 56), // WCAG 2.5.5 touch target >= 48dp
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.16)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: items.contains(effectiveValue) ? effectiveValue : null,
          isExpanded: true,
          itemHeight: null,
          dropdownColor: const Color(0xFF101924),
          borderRadius: BorderRadius.circular(16),
          menuMaxHeight: 320,
          elevation: 12,
          icon: Icon(Icons.arrow_drop_down_rounded, color: accentColor, size: 26),

          selectedItemBuilder: (BuildContext context) {
            return items.map<Widget>((String item) {
              return Row(
                children: [
                  Icon(icon, color: accentColor, size: 20),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          label,
                          style: TextStyle(
                            color: accentColor,
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.6,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          item,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 13.5,
                            fontWeight: FontWeight.w700,
                          ),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                        ),
                      ],
                    ),
                  ),
                ],
              );
            }).toList();
          },
          items: items.map<DropdownMenuItem<String>>((String item) {
            final isSelected = item == effectiveValue;
            return DropdownMenuItem<String>(
              value: item,
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        item,
                        style: TextStyle(
                          color: isSelected ? accentColor : Colors.white,
                          fontWeight: isSelected ? FontWeight.w800 : FontWeight.w500,
                          fontSize: 13.5,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (isSelected)
                      Icon(Icons.check_rounded, color: accentColor, size: 18),
                  ],
                ),
              ),
            );
          }).toList(),
          onChanged: (String? newValue) {
            if (newValue != null && newValue != value) {
              onChanged(newValue);
            }
          },
        ),
      ),
    );
  }
}
