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
  bool _obscurePassword = true;

  @override
  void initState() {
    super.initState();
    final m = widget.memberToEdit;
    _nombreCtrl = TextEditingController(text: m?.nombre ?? '');
    _cedulaCtrl = TextEditingController(text: m?.cedula ?? '');
    _telefonoCtrl = TextEditingController();
    _emailCtrl = TextEditingController(text: m?.email ?? '');
    _salarioCtrl = TextEditingController(
      text: m != null && m.salarioBase > 0 ? m.salarioBase.toInt().toString() : '',
    );
    _passCtrl = TextEditingController();

    _selectedRole = m?.role ?? UserRole.technician;
    _selectedUnitId = m?.unidadAcuicolaId;
    _periodoPago = m?.periodoPago ?? 'Quincenal';
    _permisoGlobal = m?.permisoGlobalEmpresa ?? (_selectedRole == UserRole.admin || _selectedRole == UserRole.sanitaryDirector);
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
        permisoGlobalEmpresa: _permisoGlobal || _selectedRole == UserRole.admin || _selectedRole == UserRole.sanitaryDirector,
        salarioBase: salario,
        periodoPago: _periodoPago,
      );
      final newPw = _passCtrl.text.trim();
      success = await ref.read(authProvider.notifier).updateTeamMember(
            updated,
            newPassword: newPw.isNotEmpty ? newPw : null,
          );
    } else {
      success = await ref.read(authProvider.notifier).createTeamMember(
            nombre: _nombreCtrl.text,
            email: _emailCtrl.text,
            cedula: _cedulaCtrl.text,
            telefono: _telefonoCtrl.text,
            role: _selectedRole,
            unidadAcuicolaId: _selectedUnitId,
            permisoGlobalEmpresa: _permisoGlobal || _selectedRole == UserRole.admin || _selectedRole == UserRole.sanitaryDirector,
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
    } else if (mounted) {
      final err = ref.read(authProvider).errorMessage ?? 'Error al registrar colaborador. Verifica los datos o conexión.';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(err),
          backgroundColor: AppColors.coralAction,
        ),
      );
    }
  }

  Future<void> _handleDelete() async {
    final member = widget.memberToEdit;
    if (member == null) return;

    final confirmed = await showDialog<bool>(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.7),
      builder: (dialogCtx) => AlertDialog(
        backgroundColor: AppColors.surfaceDark,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: AppColors.coralAction.withValues(alpha: 0.4)),
        ),
        title: Row(
          children: [
            const Icon(Icons.warning_amber_rounded, color: AppColors.coralAction),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'Eliminar Colaborador',
                style: AppTypography.titleMedium.copyWith(color: Colors.white),
              ),
            ),
          ],
        ),
        content: Text(
          '¿Deseas eliminar a ${member.nombre} (${member.email})? Se revocará su acceso y se eliminará su cuenta.',
          style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondaryDark),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogCtx).pop(false),
            child: const Text('Cancelar', style: TextStyle(color: Colors.white70)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.coralAction,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () => Navigator.of(dialogCtx).pop(true),
            child: const Text('Eliminar', style: TextStyle(fontWeight: FontWeight.w800)),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;
    setState(() => _isLoading = true);
    final ok = await ref.read(authProvider.notifier).deleteTeamMember(member.id);
    if (!mounted) return;
    setState(() => _isLoading = false);

    if (ok) {
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Colaborador ${member.nombre} eliminado del equipo.'),
          backgroundColor: AppColors.greenBiomass,
        ),
      );
    } else {
      final err = ref.read(authProvider).errorMessage ?? 'Error al eliminar colaborador.';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(err), backgroundColor: AppColors.coralAction),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final units = authState.units;
    final currentUser = authState.currentUser;
    final canDelete = widget.memberToEdit != null &&
        currentUser != null &&
        widget.memberToEdit!.id != currentUser.id &&
        widget.memberToEdit!.email.toLowerCase() != currentUser.email.toLowerCase();

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
                      _buildRoleChip(UserRole.admin, '🛡️ Administrador', Colors.purpleAccent),
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
                          hint: 'Ej: 2.500.000',
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
                          onTap: (_selectedRole == UserRole.admin || _selectedRole == UserRole.sanitaryDirector)
                              ? null
                              : () => setState(() => _permisoGlobal = !_permisoGlobal),
                          borderRadius: BorderRadius.circular(12),
                          child: Padding(
                            padding: const EdgeInsets.only(top: 14),
                            child: Row(
                              children: [
                                Checkbox(
                                  value: _permisoGlobal || _selectedRole == UserRole.admin || _selectedRole == UserRole.sanitaryDirector,
                                  activeColor: AppColors.cyanWater,
                                  checkColor: Colors.black,
                                  side: BorderSide(color: Colors.white.withValues(alpha: 0.3)),
                                  onChanged: (_selectedRole == UserRole.admin || _selectedRole == UserRole.sanitaryDirector)
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

                  // Contraseña Temporal (Obligatoria al crear, Opcional al editar)
                  GlassFormField(
                    label: widget.memberToEdit == null
                        ? 'CONTRASEÑA TEMPORAL DE ACCESO'
                        : 'NUEVA CONTRASEÑA TEMPORAL (OPCIONAL)',
                    hint: widget.memberToEdit == null
                        ? 'Mínimo 8 caracteres'
                        : 'Dejar vacío para mantener la actual',
                    controller: _passCtrl,
                    obscureText: _obscurePassword,
                    prefixIcon: Icons.lock_outline_rounded,
                    suffixWidget: IconButton(
                      icon: Icon(
                        _obscurePassword ? Icons.visibility_off_rounded : Icons.visibility_rounded,
                        color: AppColors.textSecondaryDark,
                        size: 20,
                      ),
                      onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                    ),
                    validator: (v) {
                      final trimmed = v?.trim() ?? '';
                      if (widget.memberToEdit == null) {
                        if (trimmed.isEmpty) return 'Requerida';
                        if (trimmed.length < 8) return 'Mínimo 8 caracteres';
                      } else if (trimmed.isNotEmpty && trimmed.length < 8) {
                        return 'Mínimo 8 caracteres';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Al iniciar sesión por primera vez con esta clave temporal, el colaborador deberá definir una nueva contraseña personal.',
                    style: AppTypography.labelMicro.copyWith(
                      color: AppColors.cyanWater.withValues(alpha: 0.85),
                      height: 1.35,
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Botones de Acción
                  Row(
                    children: [
                      if (canDelete) ...[
                        IconButton(
                          tooltip: 'Eliminar Colaborador',
                          style: IconButton.styleFrom(
                            backgroundColor: AppColors.coralAction.withValues(alpha: 0.14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                              side: BorderSide(color: AppColors.coralAction.withValues(alpha: 0.35)),
                            ),
                            padding: const EdgeInsets.all(13),
                          ),
                          icon: const Icon(Icons.delete_outline_rounded, color: AppColors.coralAction),
                          onPressed: _isLoading ? null : _handleDelete,
                        ),
                        const SizedBox(width: 10),
                      ],
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
        if (selected) {
          setState(() {
            _selectedRole = role;
            if (role == UserRole.admin || role == UserRole.sanitaryDirector) {
              _permisoGlobal = true;
            }
          });
        }
      },
    );
  }
}
