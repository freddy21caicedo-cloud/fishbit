import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import 'package:fishbit_finance/core/design_system/app_colors.dart';
import 'package:fishbit_finance/core/design_system/app_typography.dart';
import 'package:fishbit_finance/core/design_system/glass_container.dart';
import 'package:fishbit_finance/core/design_system/glass_form_field.dart';
import 'package:fishbit_finance/core/design_system/glass_button.dart';
import 'package:fishbit_finance/modules/auth_tenant/presentation/providers/auth_provider.dart';
import 'package:fishbit_finance/modules/sales_harvest/domain/models/client.dart';
import 'package:fishbit_finance/modules/sales_harvest/presentation/providers/sales_provider.dart';

/// Modal interactivo Glassmorphic para la creación rápida o detallada de Clientes Compradores
class CrearClienteModal extends ConsumerStatefulWidget {
  final String? initialNombre;
  final ValueChanged<Client>? onClientCreated;

  const CrearClienteModal({
    super.key,
    this.initialNombre,
    this.onClientCreated,
  });

  static Future<Client?> show(
    BuildContext context, {
    String? initialNombre,
    ValueChanged<Client>? onClientCreated,
  }) {
    return showDialog<Client>(
      context: context,
      barrierDismissible: true,
      barrierColor: Colors.black.withValues(alpha: 0.65),
      builder: (_) => CrearClienteModal(
        initialNombre: initialNombre,
        onClientCreated: onClientCreated,
      ),
    );
  }

  @override
  ConsumerState<CrearClienteModal> createState() => _CrearClienteModalState();
}

class _CrearClienteModalState extends ConsumerState<CrearClienteModal> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nombreCtrl;
  final _telefonoCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _nombreCtrl = TextEditingController(text: widget.initialNombre ?? '');
  }

  @override
  void dispose() {
    _nombreCtrl.dispose();
    _telefonoCtrl.dispose();
    _emailCtrl.dispose();
    super.dispose();
  }

  Future<void> _handleSave() async {
    if (_formKey.currentState != null && !_formKey.currentState!.validate()) {
      return;
    }

    final auth = ref.read(authProvider);
    final empresaId = auth.currentCompany?.id ?? auth.currentUser?.empresaId ?? 'c1000000-0000-0000-0000-000000000001';

    setState(() => _isSaving = true);

    try {
      final newClient = Client(
        id: const Uuid().v4(),
        empresaId: empresaId,
        nombre: _nombreCtrl.text.trim(),
        telefono: _telefonoCtrl.text.trim().isNotEmpty ? _telefonoCtrl.text.trim() : null,
        email: _emailCtrl.text.trim().isNotEmpty ? _emailCtrl.text.trim().toLowerCase() : null,
        creadoEn: DateTime.now(),
      );

      await ref.read(salesProvider.notifier).addClient(newClient);
      widget.onClientCreated?.call(newClient);

      if (mounted) {
        Navigator.of(context).pop(newClient);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ Cliente "${newClient.nombre}" creado exitosamente.'),
            backgroundColor: AppColors.greenBiomass,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSaving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al crear cliente: $e'),
            backgroundColor: AppColors.coralAction,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Center(
      child: SingleChildScrollView(
        child: Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 460),
            child: GlassContainer(
              borderRadius: 26,
              padding: const EdgeInsets.all(24),
              blur: 24,
              opacity: isDark ? 0.16 : 0.94,
              borderColor: AppColors.greenBiomass.withValues(alpha: isDark ? 0.35 : 0.6),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Cabecera Modal
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: AppColors.greenBiomass.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(
                                Icons.person_add_alt_1_rounded,
                                color: AppColors.greenBiomass,
                                size: 22,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Nuevo Cliente Comprador',
                                  style: AppTypography.titleMedium.copyWith(
                                    color: isDark ? Colors.white : AppColors.textPrimaryLight,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                                Text(
                                  'Directorio comercial y trazabilidad de despachos',
                                  style: AppTypography.labelMicro.copyWith(
                                    color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                                  ),
                                ),
                              ],
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
                    const SizedBox(height: 20),

                    // Campo Nombre / Razón Social
                    GlassFormField(
                      label: 'NOMBRE O RAZÓN SOCIAL',
                      hint: 'Ej: Distribuidora del Mar S.A.S.',
                      controller: _nombreCtrl,
                      prefixIcon: Icons.business_rounded,
                      textCapitalization: TextCapitalization.words,
                      textInputAction: TextInputAction.next,
                      isRequired: true,
                      showClearButton: true,
                      accentColor: AppColors.greenBiomass,
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) return 'El nombre del cliente es obligatorio';
                        if (v.trim().length < 3) return 'Mínimo 3 caracteres';
                        return null;
                      },
                    ),
                    const SizedBox(height: 14),

                    // Campo Teléfono / WhatsApp
                    GlassFormField(
                      label: 'TELÉFONO / WHATSAPP (OPCIONAL)',
                      hint: 'Ej: 300 123 4567',
                      controller: _telefonoCtrl,
                      prefixIcon: Icons.phone_outlined,
                      keyboardType: TextInputType.phone,
                      textInputAction: TextInputAction.next,
                      showClearButton: true,
                      accentColor: AppColors.greenBiomass,
                    ),
                    const SizedBox(height: 14),

                    // Campo Correo Electrónico
                    GlassFormField(
                      label: 'CORREO ELECTRÓNICO (OPCIONAL)',
                      hint: 'cliente@ejemplo.com',
                      controller: _emailCtrl,
                      prefixIcon: Icons.alternate_email_rounded,
                      keyboardType: TextInputType.emailAddress,
                      textInputAction: TextInputAction.done,
                      showClearButton: true,
                      accentColor: AppColors.greenBiomass,
                      validator: (v) {
                        if (v != null && v.trim().isNotEmpty && !v.contains('@')) {
                          return 'Ingresa un formato de correo válido';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 24),

                    // Botones de Acción
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            style: OutlinedButton.styleFrom(
                              foregroundColor: isDark ? Colors.white70 : AppColors.textSecondaryLight,
                              side: BorderSide(
                                color: isDark ? Colors.white24 : Colors.black12,
                              ),
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
                            label: 'Guardar Cliente',
                            backgroundColor: AppColors.greenBiomass,
                            isLoading: _isSaving,
                            onPressed: _handleSave,
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
      ),
    );
  }
}
