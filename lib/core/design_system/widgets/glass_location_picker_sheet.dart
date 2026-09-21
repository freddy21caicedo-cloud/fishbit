import 'package:flutter/material.dart';
import 'package:fishbit_finance/core/design_system/app_colors.dart';
import 'package:fishbit_finance/core/design_system/app_typography.dart';
import 'package:fishbit_finance/core/design_system/glass_container.dart';
import 'package:fishbit_finance/core/services/geographic_service.dart';

/// Modal Bottom-Sheet Glassmorphic con buscador predictivo en tiempo real
/// para seleccionar País, Departamento/Estado y Ciudad/Municipio
class GlassLocationPickerSheet extends StatefulWidget {
  final String title;
  final String subtitle;
  final List<String> items;
  final String? selectedItem;
  final String searchHint;
  final IconData prefixIcon;
  final bool allowCustomInput;

  const GlassLocationPickerSheet({
    super.key,
    required this.title,
    required this.subtitle,
    required this.items,
    this.selectedItem,
    this.searchHint = 'Buscar...',
    this.prefixIcon = Icons.search_rounded,
    this.allowCustomInput = true,
  });

  static Future<String?> show(
    BuildContext context, {
    required String title,
    required String subtitle,
    required List<String> items,
    String? selectedItem,
    String searchHint = 'Buscar...',
    IconData prefixIcon = Icons.location_on_rounded,
    bool allowCustomInput = true,
  }) {
    return showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black54,
      builder: (ctx) => GlassLocationPickerSheet(
        title: title,
        subtitle: subtitle,
        items: items,
        selectedItem: selectedItem,
        searchHint: searchHint,
        prefixIcon: prefixIcon,
        allowCustomInput: allowCustomInput,
      ),
    );
  }

  @override
  State<GlassLocationPickerSheet> createState() => _GlassLocationPickerSheetState();
}

class _GlassLocationPickerSheetState extends State<GlassLocationPickerSheet> {
  final _searchCtrl = TextEditingController();
  late List<String> _filteredItems;

  @override
  void initState() {
    super.initState();
    _filteredItems = List.from(widget.items);
    _searchCtrl.addListener(_onSearchChanged);
  }

  void _onSearchChanged() {
    setState(() {
      _filteredItems = GeographicService.filterList(widget.items, _searchCtrl.text);
    });
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  void _select(String item) {
    Navigator.of(context).pop(item);
  }

  void _submitCustom() {
    final text = _searchCtrl.text.trim();
    if (text.isNotEmpty) {
      Navigator.of(context).pop(text);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final screenHeight = MediaQuery.of(context).size.height;

    return AnimatedPadding(
      padding: EdgeInsets.only(bottom: bottomInset),
      duration: const Duration(milliseconds: 150),
      curve: Curves.easeOut,
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 560),
          child: Container(
            height: screenHeight * 0.72,
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF0F172A).withValues(alpha: 0.95) : Colors.white.withValues(alpha: 0.96),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
              border: Border.all(
                color: isDark ? Colors.white.withValues(alpha: 0.12) : AppColors.glassBorderLight,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: isDark ? 0.5 : 0.15),
                  blurRadius: 24,
                  offset: const Offset(0, -4),
                ),
              ],
            ),
            child: Column(
              children: [
                // Indicador de arrastre táctil (Pill)
                const SizedBox(height: 10),
                Center(
                  child: Container(
                    width: 44,
                    height: 4,
                    decoration: BoxDecoration(
                      color: isDark ? Colors.white24 : Colors.black12,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                // Cabecera del Bottom Sheet
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.title,
                              style: AppTypography.titleMedium.copyWith(
                                color: isDark ? Colors.white : AppColors.textPrimaryLight,
                                fontWeight: FontWeight.w900,
                                fontSize: 16,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              widget.subtitle,
                              style: AppTypography.bodySmall.copyWith(
                                color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                                fontSize: 11.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.of(context).pop(),
                        icon: const Icon(Icons.close_rounded),
                        color: isDark ? Colors.white70 : AppColors.textSecondaryLight,
                        splashRadius: 20,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),

                // Buscador predictivo en tiempo real
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: GlassContainer(
                    borderRadius: 14,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
                    opacity: isDark ? 0.08 : 0.85,
                    borderColor: AppColors.cyanWater.withValues(alpha: 0.35),
                    child: TextField(
                      controller: _searchCtrl,
                      style: TextStyle(
                        color: isDark ? Colors.white : AppColors.textPrimaryLight,
                        fontSize: 13.5,
                        fontWeight: FontWeight.w600,
                      ),
                      decoration: InputDecoration(
                        hintText: widget.searchHint,
                        hintStyle: TextStyle(
                          color: isDark ? AppColors.textTertiaryDark : AppColors.textTertiaryLight,
                          fontSize: 13,
                        ),
                        border: InputBorder.none,
                        prefixIcon: Icon(widget.prefixIcon, color: AppColors.cyanWater, size: 20),
                        suffixIcon: _searchCtrl.text.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear_rounded, size: 18),
                                color: isDark ? Colors.white54 : Colors.black45,
                                onPressed: () {
                                  _searchCtrl.clear();
                                },
                              )
                            : null,
                      ),
                      onSubmitted: (_) => _submitCustom(),
                    ),
                  ),
                ),
                const SizedBox(height: 10),

                // Lista de elementos interactivos
                Expanded(
                  child: _filteredItems.isEmpty
                      ? Center(
                          child: Padding(
                            padding: const EdgeInsets.all(24),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.search_off_rounded, size: 40, color: isDark ? Colors.white24 : Colors.black26),
                                const SizedBox(height: 12),
                                Text(
                                  'No se encontraron coincidencias para "${_searchCtrl.text.trim()}".',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                                    fontSize: 12.5,
                                  ),
                                ),
                                if (widget.allowCustomInput && _searchCtrl.text.trim().isNotEmpty) ...[
                                  const SizedBox(height: 14),
                                  ElevatedButton.icon(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: AppColors.cyanWater,
                                      foregroundColor: Colors.black,
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                                    ),
                                    onPressed: _submitCustom,
                                    icon: const Icon(Icons.add_location_alt_rounded, size: 18),
                                    label: Text(
                                      'Usar "${_searchCtrl.text.trim()}"',
                                      style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 12.5),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        )
                      : ListView.separated(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                          itemCount: _filteredItems.length,
                          separatorBuilder: (_, __) => Divider(
                            height: 1,
                            thickness: 0.6,
                            color: isDark ? Colors.white.withValues(alpha: 0.06) : Colors.black.withValues(alpha: 0.05),
                          ),
                          itemBuilder: (ctx, idx) {
                            final item = _filteredItems[idx];
                            final isSelected = widget.selectedItem == item;

                            return InkWell(
                              onTap: () => _select(item),
                              borderRadius: BorderRadius.circular(12),
                              child: Container(
                                constraints: const BoxConstraints(minHeight: 48), // WCAG 2.5.5 >= 48dp
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? AppColors.cyanWater.withValues(alpha: isDark ? 0.18 : 0.12)
                                      : Colors.transparent,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Row(
                                  children: [
                                    Icon(
                                      isSelected ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded,
                                      size: 19,
                                      color: isSelected ? AppColors.cyanWater : (isDark ? Colors.white30 : Colors.black26),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Text(
                                        item,
                                        style: TextStyle(
                                          color: isSelected
                                              ? AppColors.cyanWater
                                              : (isDark ? Colors.white : AppColors.textPrimaryLight),
                                          fontSize: 13.5,
                                          fontWeight: isSelected ? FontWeight.w800 : FontWeight.w500,
                                        ),
                                      ),
                                    ),
                                    if (item.contains('(') || item.contains('...'))
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.04),
                                          borderRadius: BorderRadius.circular(6),
                                        ),
                                        child: Text(
                                          item.contains('(') ? 'Cuenca' : 'Opción',
                                          style: TextStyle(
                                            color: isDark ? Colors.white60 : Colors.black54,
                                            fontSize: 9.5,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
