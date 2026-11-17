import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fishbit_finance/core/design_system/app_colors.dart';
import 'package:fishbit_finance/core/design_system/app_typography.dart';
import 'package:fishbit_finance/core/design_system/glass_container.dart';
import 'package:fishbit_finance/core/design_system/glass_form_field.dart';
import 'package:fishbit_finance/core/design_system/glass_button.dart';
import 'package:fishbit_finance/modules/auth_tenant/presentation/providers/auth_provider.dart';

/// Pantalla obligatoria de cambio de contraseña en el primer inicio de sesión
/// para colaboradores creados con contraseña temporal por el Administrador.
class ForceChangePasswordScreen extends ConsumerStatefulWidget {
  const ForceChangePasswordScreen({super.key});

  @override
  ConsumerState<ForceChangePasswordScreen> createState() =>
      _ForceChangePasswordScreenState();
}

class _ForceChangePasswordScreenState
    extends ConsumerState<ForceChangePasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _newPassCtrl = TextEditingController();
  final _confirmPassCtrl = TextEditingController();

  bool _obscureNew = true;
  bool _obscureConfirm = true;
  bool _isSubmitting = false;

  @override
  void dispose() {
    _newPassCtrl.dispose();
    _confirmPassCtrl.dispose();
    super.dispose();
  }

  Future<void> _handleUpdatePassword() async {
    if (_formKey.currentState != null && !_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isSubmitting = true);
    final success = await ref
        .read(authProvider.notifier)
        .completeFirstLoginPasswordChange(_newPassCtrl.text.trim());

    if (!mounted) return;
    setState(() => _isSubmitting = false);

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Contraseña actualizada con éxito. Bienvenido a FishBit.',
          ),
          backgroundColor: AppColors.greenBiomass,
        ),
      );
    } else {
      final err = ref.read(authProvider).errorMessage ??
          'No se pudo actualizar la contraseña. Intenta nuevamente.';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(err),
          backgroundColor: AppColors.coralAction,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final user = authState.currentUser;
    final busy = _isSubmitting || authState.isLoading;

    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 28),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 460),
              child: GlassContainer(
                borderRadius: 28,
                padding: const EdgeInsets.all(28),
                blur: 24,
                opacity: 0.12,
                borderColor: Colors.white.withValues(alpha: 0.16),
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: AppColors.cyanWater.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: AppColors.cyanWater.withValues(alpha: 0.35),
                              ),
                            ),
                            child: const Icon(
                              Icons.lock_reset_rounded,
                              color: AppColors.cyanWater,
                              size: 28,
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Actualiza tu Contraseña',
                                  style: AppTypography.titleLarge.copyWith(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'Primer inicio de sesión requerido',
                                  style: AppTypography.bodySmall.copyWith(
                                    color: AppColors.cyanWater,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.05),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.1),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Hola, ${user?.nombre ?? 'Colaborador'}',
                              style: AppTypography.titleMedium.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Por seguridad, debes definir una nueva contraseña personal antes de acceder al sistema (${user?.email ?? ''}).',
                              style: AppTypography.bodySmall.copyWith(
                                color: AppColors.textSecondaryDark,
                                height: 1.4,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 22),
                      GlassFormField(
                        label: 'NUEVA CONTRASEÑA',
                        hint: 'Mínimo 8 caracteres',
                        controller: _newPassCtrl,
                        obscureText: _obscureNew,
                        prefixIcon: Icons.lock_outline_rounded,
                        textInputAction: TextInputAction.next,
                        isRequired: true,
                        suffixWidget: IconButton(
                          icon: Icon(
                            _obscureNew
                                ? Icons.visibility_off_rounded
                                : Icons.visibility_rounded,
                            color: AppColors.textSecondaryDark,
                            size: 20,
                          ),
                          onPressed: () =>
                              setState(() => _obscureNew = !_obscureNew),
                        ),
                        validator: (val) {
                          if (val == null || val.trim().isEmpty) {
                            return 'Ingresa tu nueva contraseña';
                          }
                          if (val.trim().length < 8) {
                            return 'Debe tener al menos 8 caracteres';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      GlassFormField(
                        label: 'CONFIRMAR NUEVA CONTRASEÑA',
                        hint: 'Repite la nueva contraseña',
                        controller: _confirmPassCtrl,
                        obscureText: _obscureConfirm,
                        prefixIcon: Icons.verified_user_outlined,
                        textInputAction: TextInputAction.done,
                        isRequired: true,
                        onFieldSubmitted: (_) =>
                            busy ? null : _handleUpdatePassword(),
                        suffixWidget: IconButton(
                          icon: Icon(
                            _obscureConfirm
                                ? Icons.visibility_off_rounded
                                : Icons.visibility_rounded,
                            color: AppColors.textSecondaryDark,
                            size: 20,
                          ),
                          onPressed: () => setState(
                            () => _obscureConfirm = !_obscureConfirm,
                          ),
                        ),
                        validator: (val) {
                          if (val == null || val.trim().isEmpty) {
                            return 'Confirma tu nueva contraseña';
                          }
                          if (val.trim() != _newPassCtrl.text.trim()) {
                            return 'Las contraseñas no coinciden';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 24),
                      GlassButton(
                        label: 'Guardar Nueva Contraseña e Ingresar',
                        isLoading: busy,
                        backgroundColor: AppColors.cyanWater,
                        onPressed: busy ? null : _handleUpdatePassword,
                      ),
                      const SizedBox(height: 12),
                      Center(
                        child: TextButton.icon(
                          onPressed: busy
                              ? null
                              : () => ref.read(authProvider.notifier).signOut(),
                          icon: const Icon(
                            Icons.logout_rounded,
                            size: 16,
                            color: AppColors.textSecondaryDark,
                          ),
                          label: Text(
                            'Cerrar sesión',
                            style: AppTypography.bodySmall.copyWith(
                              color: AppColors.textSecondaryDark,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
