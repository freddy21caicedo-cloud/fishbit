import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fishbit_finance/core/design_system/app_colors.dart';
import 'package:fishbit_finance/core/design_system/app_typography.dart';
import 'package:fishbit_finance/core/design_system/glass_container.dart';
import 'package:fishbit_finance/core/design_system/glass_form_field.dart';
import 'package:fishbit_finance/core/design_system/glass_button.dart';
import 'package:fishbit_finance/modules/auth_tenant/domain/models/user_member.dart';
import 'package:fishbit_finance/modules/auth_tenant/presentation/providers/auth_provider.dart';

class CrearColaboradorModal extends ConsumerStatefulWidget {
  final UserMember? memberToEdit;

  const CrearColaboradorModal({
    super.key,
    this.memberToEdit,
  });

  static Future<void> show(BuildContext context, {UserMember? memberToEdit}) {
    return showDialog(
      context: context,
      barrierDismissible: true,
      barrierColor: Colors.black.withValues(alpha: 0.7),
      builder: (_) => CrearColaboradorModal(memberToEdit: memberToEdit),
    );
  }

  @override
  ConsumerState<CrearColaboradorModal> createState() => _CrearColaboradorModalState();
}

class _CrearColaboradorModalState extends ConsumerState<CrearColaboradorModal> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nombreCtrl;
  late final TextEditingController _cedulaCtrl;
  late final TextEditingController _telefonoCtrl;
  late final TextEditingController _emailCtrl;
  late final TextEditingController _salarioCtrl;
  late final TextEditingController _passCtrl;

  late UserRole _selectedRole;
  String? _selectedUnitId;
  late String _periodoPago;
  late bool _permisoGlobal;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    final m = widget.memberToEdit;
    _nombreCtrl = TextEditingController(text: m?.nombre ?? '');
    _cedulaCtrl = TextEditingController(text: m?.cedula ?? '');
    _telefonoCtrl = TextEditingController();
    _emailCtrl = TextEditingController(text: m?.email ?? '');
    _salarioCtrl = TextEditingController(
      text: m != null && m.salarioBase > 0 ? m.salarioBase.toInt().toString() : '2000000',
    );
    _passCtrl = TextEditingController(text: 'FishBit.2026');

    _selectedRole = m?.role ?? UserRole.technician;
    _selectedUnitId = m?.unidadAcuicolaId;
    _periodoPago = m?.periodoPago ?? 'Quincenal';
    _permisoGlobal = m?.permisoGlobalEmpresa ?? false;
  }

  @override
  void dispose() {
    _nombreCtrl.dispose();
    _cedulaCtrl.dispose();
    _telefonoCtrl.dispose();
    _emailCtrl.dispose();
    _salarioCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  Future<void> _handleSubmit() async {
    if (_formKey.currentState != null && !_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isLoading = true);
    final salario = double.tryParse(_salarioCtrl.text.replaceAll(RegExp(r'[^0-9.]'), '')) ?? 0.0;

    bool success = false;
    final isEditing = widget.memberToEdit != null;

    if (isEditing) {
      final updated = widget.memberToEdit!.copyWith(
        nombre: _nombreCtrl.text.trim(),
        email: _emailCtrl.text.trim().toLowerCase(),
        cedula: _cedulaCtrl.text.trim(),
        role: _selectedRole,
        unidadAcuicolaId: _selectedUnitId,
        permisoGlobalEmpresa: _permisoGlobal || _selectedRole == UserRole.sanitaryDirector,
        salarioBase: salario,
        periodoPago: _periodoPago,
      );
      success = await ref.read(authProvider.notifier).updateTeamMember(updated);
    } else {
      success = await ref.read(authProvider.notifier).createTeamMember(
            nombre: _nombreCtrl.text,
            email: _emailCtrl.text,
            cedula: _cedulaCtrl.text,
            telefono: _telefonoCtrl.text,
            role: _selectedRole,
            unidadAcuicolaId: _selectedUnitId,
            permisoGlobalEmpresa: _permisoGlobal || _selectedRole == UserRole.sanitaryDirector,
            salarioBase: salario,
            periodoPago: _periodoPago,
            password: _passCtrl.text,
          );
    }

    setState(() => _isLoading = false);

    if (success && mounted) {
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            isEditing
                ? 'Colaborador ${_nombreCtrl.text} actualizado con éxito.'
                : 'Colaborador ${_nombreCtrl.text} registrado con éxito como ${_selectedRole.roleDisplayName}.',
          ),
          backgroundColor: AppColors.greenBiomass,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final units = authState.units;

    if (_selectedUnitId == null && units.isNotEmpty) {
      _selectedUnitId = authState.activeUnitId ?? units.first.id;
    }

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 540),
        child: GlassContainer(
          borderRadius: 24,
          padding: const EdgeInsets.all(24),
          blur: 24,
          opacity: 0.14,
          borderColor: Colors.white.withValues(alpha: 0.16),
          child: Form(
            key: _formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Encabezado
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: AppColors.cyanWater.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(
                              widget.memberToEdit != null ? Icons.edit_note_rounded : Icons.person_add_alt_1_rounded, 
                              color: AppColors.cyanWater, 
                              size: 22,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                widget.memberToEdit != null ? 'Editar Colaborador' : 'Nuevo Colaborador Acuícola', 
                                style: AppTypography.titleMedium.copyWith(color: Colors.white),
                              ),
                              Text(
                                widget.memberToEdit != null ? 'Actualizar datos, cargo o salario' : 'Registrar e incorporar personal a la piscícola', 
                                style: AppTypography.labelMicro.copyWith(color: AppColors.textSecondaryDark),
                              ),
                            ],
                          ),
                        ],
                      ),
                      IconButton(
                        icon: const Icon(Icons.close_rounded, color: AppColors.textSecondaryDark),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),

                  // Selección de Rol Acuícola
                  Text('CARGO / ROL EN LA PISCÍCOLA', style: AppTypography.labelMicro.copyWith(color: AppColors.textSecondaryDark)),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _buildRoleChip(UserRole.sanitaryDirector, '🩺 Dir. Sanitario', AppColors.cyanWater),
                      _buildRoleChip(UserRole.technician, '🔬 Técnico Acuícola', AppColors.greenBiomass),
                      _buildRoleChip(UserRole.operator, '🚜 Operario Campo', AppColors.coralAction),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Nombre y Cédula
                  Row(
                    children: [
                      Expanded(
                        flex: 3,
                        child: GlassFormField(
                          label: 'NOMBRE COMPLETO',
                          hint: 'Ej: Dr. Fernando Gómez',
                          controller: _nombreCtrl,
                          prefixIcon: Icons.person_outline_rounded,
                          validator: (v) => v == null || v.trim().isEmpty ? 'Requerido' : null,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        flex: 2,
                        child: GlassFormField(
                          label: 'CÉDULA / ID',
                          hint: '1.098.765.432',
                          controller: _cedulaCtrl,
                          keyboardType: TextInputType.number,
                          prefixIcon: Icons.badge_outlined,
                          validator: (v) => v == null || v.trim().isEmpty ? 'Requerido' : null,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Correo y Teléfono
                  Row(
                    children: [
                      Expanded(
                        child: GlassFormField(
                          label: 'CORREO ELECTRÓNICO',
                          hint: 'sanidad@piscicola.com',
                          controller: _emailCtrl,
                          keyboardType: TextInputType.emailAddress,
                          prefixIcon: Icons.alternate_email_rounded,
                          validator: (v) {
                            if (v == null || v.trim().isEmpty) return 'Requerido';
                            if (!v.contains('@')) return 'Inválido';
                            return null;
                          },
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: GlassFormField(
                          label: 'TELÉFONO / CONTACTO',
                          hint: '+57 300 123 4567',
                          controller: _telefonoCtrl,
                          keyboardType: TextInputType.phone,
                          prefixIcon: Icons.phone_outlined,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Sede Asignada y Salario Base
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('SEDE ASIGNADA', style: AppTypography.labelMicro.copyWith(color: AppColors.textSecondaryDark)),
                            const SizedBox(height: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.05),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
                              ),
                              child: DropdownButtonHideUnderline(
                                child: DropdownButton<String>(
                                  value: _selectedUnitId,
                                  isExpanded: true,
                                  dropdownColor: AppColors.surfaceDark,
                                  style: AppTypography.bodyMedium.copyWith(color: Colors.white),
                                  items: units.map((u) {
                                    return DropdownMenuItem<String>(
                                      value: u.id,
                                      child: Text('${u.sigla} - ${u.nombre}'),
                                    );
                                  }).toList(),
                                  onChanged: (val) => setState(() => _selectedUnitId = val),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: GlassFormField(
                          label: 'SALARIO MENSUAL (COP)',
                          hint: '2.500.000',
                          controller: _salarioCtrl,
                          keyboardType: TextInputType.number,
                          prefixIcon: Icons.attach_money_rounded,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Periodicidad y Permiso Global
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('PERIODO DE PAGO', style: AppTypography.labelMicro.copyWith(color: AppColors.textSecondaryDark)),
                            const SizedBox(height: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.05),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
                              ),
                              child: DropdownButtonHideUnderline(
                                child: DropdownButton<String>(
                                  value: _periodoPago,
                                  isExpanded: true,
                                  dropdownColor: AppColors.surfaceDark,
                                  style: AppTypography.bodyMedium.copyWith(color: Colors.white),
                                  items: const [
                                    DropdownMenuItem(value: 'Quincenal', child: Text('Quincenal')),
                                    DropdownMenuItem(value: 'Mensual', child: Text('Mensual')),
                                  ],
                                  onChanged: (val) => setState(() => _periodoPago = val ?? 'Quincenal'),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: InkWell(
                          onTap: () => setState(() => _permisoGlobal = !_permisoGlobal),
                          borderRadius: BorderRadius.circular(12),
                          child: Padding(
                            padding: const EdgeInsets.only(top: 14),
                            child: Row(
                              children: [
                                Checkbox(
                                  value: _permisoGlobal || _selectedRole == UserRole.sanitaryDirector,
                                  activeColor: AppColors.cyanWater,
                                  checkColor: Colors.black,
                                  side: BorderSide(color: Colors.white.withValues(alpha: 0.3)),
                                  onChanged: _selectedRole == UserRole.sanitaryDirector
                                      ? null
                                      : (val) => setState(() => _permisoGlobal = val ?? false),
                                ),
                                Expanded(
                                  child: Text(
                                    'Permiso Global (Todas las sedes)',
                                    style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondaryDark),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Contraseña Inicial
                  GlassFormField(
                    label: 'CONTRASEÑA INICIAL DE ACCESO',
                    hint: 'FishBit.2026',
                    controller: _passCtrl,
                    prefixIcon: Icons.lock_outline_rounded,
                    validator: (v) => v == null || v.isEmpty ? 'Requerida' : null,
                  ),
                  const SizedBox(height: 20),

                  // Botones de Acción
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.white,
                            side: BorderSide(color: Colors.white.withValues(alpha: 0.25)),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          ),
                          onPressed: () => Navigator.of(context).pop(),
                          child: const Text('Cancelar', style: TextStyle(fontWeight: FontWeight.w700)),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        flex: 2,
                        child: GlassButton(
                          label: widget.memberToEdit != null ? 'Guardar Cambios' : 'Registrar Colaborador',
                          isLoading: _isLoading,
                          backgroundColor: AppColors.cyanWater,
                          onPressed: _handleSubmit,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRoleChip(UserRole role, String label, Color color) {
    final isSelected = _selectedRole == role;
    return ChoiceChip(
      label: Text(label, style: TextStyle(color: isSelected ? Colors.black : Colors.white, fontWeight: FontWeight.w700, fontSize: 12)),
      selected: isSelected,
      selectedColor: color,
      backgroundColor: Colors.white.withValues(alpha: 0.06),
      side: BorderSide(color: isSelected ? color : Colors.white.withValues(alpha: 0.12)),
      onSelected: (selected) {
        if (selected) setState(() => _selectedRole = role);
      },
    );
  }
}
