import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fishbit_finance/core/design_system/app_colors.dart';
import 'package:fishbit_finance/core/design_system/app_typography.dart';
import 'package:fishbit_finance/core/design_system/glass_container.dart';
import 'package:fishbit_finance/modules/warehouse_inventory/domain/models/supplier.dart';
import 'package:fishbit_finance/modules/warehouse_inventory/presentation/providers/warehouse_provider.dart';
import 'package:fishbit_finance/modules/warehouse_inventory/presentation/dialogs/registrar_proveedor_modal.dart';

/// Modal para visualizar el directorio de proveedores registrados y permitir
/// seleccionar uno o abrir el formulario de registro de un nuevo proveedor.
class ProveedoresModal extends ConsumerStatefulWidget {
  const ProveedoresModal({super.key});

  static Future<Supplier?> show(BuildContext context) {
    return showDialog<Supplier?>(
      context: context,
      barrierDismissible: true,
      builder: (context) => const ProveedoresModal(),
    );
  }

  @override
  ConsumerState<ProveedoresModal> createState() => _ProveedoresModalState();
}

class _ProveedoresModalState extends ConsumerState<ProveedoresModal> {
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final state = ref.watch(warehouseProvider);
    final suppliers = state.suppliers;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 580, maxHeight: 680),
        child: GlassContainer(
          borderRadius: 24,
          padding: const EdgeInsets.all(22),
          blur: 24,
          opacity: isDark ? 0.16 : 0.90,
          borderColor: isDark ? AppColors.amberWarning.withValues(alpha: 0.35) : AppColors.glassBorderLight,
          tintColor: isDark ? AppColors.surfaceDarkRaised : AppColors.surfaceLight,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ─── Cabecera ──────────────────────────────────────────────
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppColors.amberWarning.withValues(alpha: isDark ? 0.15 : 0.12),
                          border: Border.all(
                            color: AppColors.amberWarning.withValues(alpha: 0.35),
                          ),
                        ),
                        child: const Icon(
                          Icons.store_mall_directory_rounded,
                          color: AppColors.amberWarning,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        'Directorio de Proveedores',
                        style: AppTypography.titleLarge.copyWith(
                          color: isDark ? Colors.white : AppColors.textPrimaryLight,
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                  IconButton(
                    icon: Icon(
                      Icons.close_rounded,
                      color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                    ),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              // ─── Barra de Acciones ─────────────────────────────────────
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${suppliers.length} Proveedores Registrados',
                    style: AppTypography.labelMicro.copyWith(
                      color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                      letterSpacing: 1.2,
                    ),
                  ),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.amberWarning,
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    icon: const Icon(Icons.add, size: 16, color: Colors.black),
                    label: const Text(
                      'Nuevo Proveedor',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800),
                    ),
                    onPressed: () async {
                      final created = await RegistrarProveedorModal.show(context);
                      if (created != null && context.mounted) {
                        Navigator.of(context).pop(created);
                      }
                    },
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // ─── Lista de Proveedores ──────────────────────────────────
              Expanded(
                child: _buildList(suppliers, isDark),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildList(List<Supplier> suppliers, bool isDark) {
    if (suppliers.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.store_mall_directory_outlined,
              size: 40,
              color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
            ),
            const SizedBox(height: 8),
            Text(
              'No hay proveedores registrados.',
              style: TextStyle(
                color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                fontSize: 13,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      itemCount: suppliers.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final s = suppliers[index];
        final categoriasMostrar = s.categorias.isNotEmpty ? s.categorias : [s.categoriaPrincipal];

        return InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => Navigator.of(context).pop(s),
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: isDark ? Colors.white.withValues(alpha: 0.04) : Colors.black.withValues(alpha: 0.02),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isDark ? Colors.white.withValues(alpha: 0.08) : AppColors.glassBorderLight,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        s.nombre,
                        style: AppTypography.titleSmall.copyWith(
                          color: isDark ? Colors.white : AppColors.textPrimaryLight,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: s.isCustom
                                ? AppColors.greenBiomass.withValues(alpha: isDark ? 0.15 : 0.12)
                                : (isDark ? Colors.white.withValues(alpha: 0.08) : Colors.black.withValues(alpha: 0.05)),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(
                              color: s.isCustom
                                  ? AppColors.greenBiomass.withValues(alpha: 0.3)
                                  : (isDark ? Colors.white12 : AppColors.glassBorderLight),
                            ),
                          ),
                          child: Text(
                            s.isCustom ? 'PROPIO' : 'OFICIAL',
                            style: TextStyle(
                              color: s.isCustom
                                  ? (isDark ? AppColors.greenBiomass : AppColors.greenBiomassTextLight)
                                  : (isDark ? AppColors.cyanWater : AppColors.cyanWaterTextLight),
                              fontSize: 9,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: AppColors.amberWarning.withValues(alpha: isDark ? 0.15 : 0.12),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            s.categoriaPrincipal.toUpperCase(),
                            style: TextStyle(
                              color: isDark ? AppColors.amberWarning : AppColors.amberWarningTextLight,
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(
                      Icons.badge_outlined,
                      size: 13,
                      color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${s.tipoIdentificacion ?? "NIT"}: ${s.nit}',
                      style: AppTypography.labelMicro.copyWith(
                        color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Icon(
                      Icons.place_outlined,
                      size: 13,
                      color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      s.ciudad ?? 'Colombia',
                      style: AppTypography.labelMicro.copyWith(
                        color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                      ),
                    ),
                  ],
                ),
                if (s.contactoNombre != null && s.contactoNombre!.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Icon(
                        Icons.person_outline_rounded,
                        size: 13,
                        color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Contacto: ${s.contactoNombre}',
                        style: TextStyle(
                          color: isDark ? Colors.white70 : AppColors.textPrimaryLight,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ],
                if (s.telefono != null && s.telefono!.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Icon(
                        Icons.phone_outlined,
                        size: 13,
                        color: isDark ? AppColors.cyanWater : AppColors.cyanWaterTextLight,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        s.telefono!,
                        style: TextStyle(
                          color: isDark ? AppColors.cyanWater : AppColors.cyanWaterTextLight,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ],
                if (categoriasMostrar.length > 1) ...[
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 6,
                    runSpacing: 4,
                    children: categoriasMostrar.map((cat) {
                      return Container(
                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                        decoration: BoxDecoration(
                          color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.04),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                            color: isDark ? Colors.white12 : AppColors.glassBorderLight,
                          ),
                        ),
                        child: Text(
                          cat,
                          style: TextStyle(
                            color: isDark ? Colors.white70 : AppColors.textSecondaryLight,
                            fontSize: 10,
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}
