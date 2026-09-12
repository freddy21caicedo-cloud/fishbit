import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import 'package:fishbit_finance/core/design_system/app_colors.dart';
import 'package:fishbit_finance/core/design_system/app_typography.dart';
import 'package:fishbit_finance/core/design_system/glass_container.dart';
import 'package:fishbit_finance/core/design_system/glass_form_field.dart';
import 'package:fishbit_finance/core/design_system/glass_button.dart';
import 'package:fishbit_finance/modules/warehouse_inventory/domain/models/supplier.dart';
import 'package:fishbit_finance/modules/warehouse_inventory/presentation/providers/warehouse_provider.dart';

import 'package:fishbit_finance/modules/auth_tenant/presentation/providers/auth_provider.dart';

class ProveedoresModal extends ConsumerStatefulWidget {
  const ProveedoresModal({super.key});

  static Future<void> show(BuildContext context) {
    return showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => const ProveedoresModal(),
    );
  }

  @override
  ConsumerState<ProveedoresModal> createState() => _ProveedoresModalState();
}

class _ProveedoresModalState extends ConsumerState<ProveedoresModal> {
  bool _showForm = false;
  final _formKey = GlobalKey<FormState>();
  final _nombreCtrl = TextEditingController();
  final _nitCtrl = TextEditingController();
  final _telCtrl = TextEditingController();
  final _ciudadCtrl = TextEditingController();
  String _categoriaSeleccionada = 'concentrados';

  final Map<String, String> _categorias = {
    'concentrados': '🍽️ Concentrados y Nutrición',
    'insumos': '🧪 Insumos y Tratamientos',
    'farmacia': '💊 Farmacia y Medicamentos',
    'oxigenadores': '⚙️ Equipos y Oxigenadores',
    'alevinos': '🐟 Alevinos y Semilla',
  };

  @override
  void dispose() {
    _nombreCtrl.dispose();
    _nitCtrl.dispose();
    _telCtrl.dispose();
    _ciudadCtrl.dispose();
    super.dispose();
  }

  void _guardarProveedor() async {
    if (!_formKey.currentState!.validate()) return;

    final auth = ref.read(authProvider);
    final empresaId = auth.currentUser?.empresaId ?? auth.currentCompany?.id ?? 'c1000000-0000-0000-0000-000000000001';
    final activeUnit = auth.units.where((u) => u.id == auth.activeUnitId).firstOrNull ?? (auth.units.isNotEmpty ? auth.units.first : null);
    final sigla = activeUnit?.sigla ?? 'SEDE';

    final newSupplier = Supplier(
      id: const Uuid().v4(),
      nit: _nitCtrl.text.trim(),
      nombre: _nombreCtrl.text.trim(),
      telefono: _telCtrl.text.trim().isNotEmpty ? _telCtrl.text.trim() : null,
      ciudad: _ciudadCtrl.text.trim().isNotEmpty ? _ciudadCtrl.text.trim() : null,
      categoriaPrincipal: _categoriaSeleccionada,
      empresaId: empresaId,
      unidadAcuicolaSigla: sigla,
      isCustom: true,
    );

    await ref.read(warehouseProvider.notifier).addSupplier(newSupplier);

    if (!mounted) return;
    setState(() {
      _showForm = false;
      _nombreCtrl.clear();
      _nitCtrl.clear();
      _telCtrl.clear();
      _ciudadCtrl.clear();
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Proveedor "${newSupplier.nombre}" guardado exitosamente.'),
        backgroundColor: AppColors.greenBiomass,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
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
          opacity: 0.16,
          borderColor: AppColors.amberWarning.withValues(alpha: 0.3),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppColors.amberWarning.withValues(alpha: 0.15),
                        ),
                        child: const Icon(Icons.store_mall_directory_rounded, color: AppColors.amberWarning, size: 20),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        'Directorio de Proveedores',
                        style: AppTypography.titleLarge.copyWith(color: Colors.white, fontSize: 18),
                      ),
                    ],
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, color: AppColors.textSecondaryDark),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              // Botón para alternar formulario de nuevo proveedor
              if (!_showForm)
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '${suppliers.length} Proveedores Registrados',
                      style: AppTypography.labelMicro.copyWith(color: AppColors.textSecondaryDark, letterSpacing: 1.2),
                    ),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.amberWarning,
                        foregroundColor: Colors.black,
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      icon: const Icon(Icons.add, size: 16, color: Colors.black),
                      label: const Text('Nuevo Proveedor', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800)),
                      onPressed: () => setState(() => _showForm = true),
                    ),
                  ],
                ),

              const SizedBox(height: 12),

              // Formulario o Lista
              Expanded(
                child: _showForm ? _buildForm() : _buildList(suppliers),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildForm() {
    return Form(
      key: _formKey,
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('REGISTRAR NUEVO PROVEEDOR', style: AppTypography.labelMicro.copyWith(color: AppColors.amberWarning, fontWeight: FontWeight.w800)),
            const SizedBox(height: 12),
            GlassFormField(
              label: 'NOMBRE O RAZÓN SOCIAL',
              hint: 'Ej. Molinos del Oriente S.A.S.',
              controller: _nombreCtrl,
              validator: (v) => (v == null || v.trim().isEmpty) ? 'Requerido' : null,
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: GlassFormField(
                    label: 'NIT / IDENTIFICACIÓN',
                    hint: '900.123.456-7',
                    controller: _nitCtrl,
                    validator: (v) => (v == null || v.trim().isEmpty) ? 'Requerido' : null,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: GlassFormField(
                    label: 'CIUDAD / MUNICIPIO',
                    hint: 'Bogotá / Villavicencio',
                    controller: _ciudadCtrl,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            GlassFormField(
              label: 'TELÉFONO DE CONTACTO',
              hint: '+57 310 123 4567',
              controller: _telCtrl,
              keyboardType: TextInputType.phone,
            ),
            const SizedBox(height: 12),
            Text('CATEGORÍA PRINCIPAL', style: AppTypography.labelMicro.copyWith(color: AppColors.textSecondaryDark)),
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: _categoriaSeleccionada,
                  dropdownColor: AppColors.backgroundDark,
                  isExpanded: true,
                  items: _categorias.entries.map((e) {
                    return DropdownMenuItem(
                      value: e.key,
                      child: Text(e.value, style: const TextStyle(color: Colors.white, fontSize: 13)),
                    );
                  }).toList(),
                  onChanged: (val) => setState(() => _categoriaSeleccionada = val ?? 'concentrados'),
                ),
              ),
            ),
            const SizedBox(height: 18),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.textSecondaryDark,
                      side: BorderSide(color: Colors.white.withValues(alpha: 0.2)),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: () => setState(() => _showForm = false),
                    child: const Text('Cancelar'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: GlassButton(
                    label: 'Guardar Proveedor',
                    backgroundColor: AppColors.amberWarning,
                    onPressed: _guardarProveedor,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildList(List<Supplier> suppliers) {
    if (suppliers.isEmpty) {
      return const Center(
        child: Text('No hay proveedores registrados.', style: TextStyle(color: AppColors.textSecondaryDark)),
      );
    }

    return ListView.separated(
      itemCount: suppliers.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final s = suppliers[index];
        return Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.04),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
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
                      style: AppTypography.titleSmall.copyWith(color: Colors.white, fontWeight: FontWeight.w800),
                    ),
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: s.isCustom ? AppColors.greenBiomass.withValues(alpha: 0.15) : Colors.white.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: s.isCustom ? AppColors.greenBiomass.withValues(alpha: 0.3) : Colors.white12),
                        ),
                        child: Text(
                          s.isCustom ? 'PROPIO' : 'OFICIAL',
                          style: TextStyle(
                            color: s.isCustom ? AppColors.greenBiomass : AppColors.cyanWater,
                            fontSize: 9,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: AppColors.amberWarning.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          s.categoriaPrincipal.toUpperCase(),
                          style: const TextStyle(color: AppColors.amberWarning, fontSize: 10, fontWeight: FontWeight.w800),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                'NIT: ${s.nit} • ${s.ciudad ?? "Colombia"}',
                style: AppTypography.labelMicro.copyWith(color: AppColors.textSecondaryDark),
              ),
              if (s.telefono != null) ...[
                const SizedBox(height: 2),
                Text('Tel: ${s.telefono}', style: const TextStyle(color: AppColors.cyanWater, fontSize: 11)),
              ],
              if (s.productosOfrecidos.isNotEmpty) ...[
                const SizedBox(height: 8),
                Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  children: s.productosOfrecidos.take(3).map((p) {
                    return Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.06),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(p, style: const TextStyle(color: Colors.white70, fontSize: 10)),
                    );
                  }).toList(),
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}
