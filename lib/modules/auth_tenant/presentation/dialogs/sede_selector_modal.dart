import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fishbit_finance/core/design_system/app_colors.dart';
import 'package:fishbit_finance/core/design_system/app_typography.dart';
import 'package:fishbit_finance/core/design_system/glass_container.dart';
import 'package:fishbit_finance/core/design_system/glass_form_field.dart';
import 'package:fishbit_finance/core/design_system/glass_button.dart';
import 'package:fishbit_finance/modules/auth_tenant/domain/models/user_member.dart';
import 'package:fishbit_finance/modules/auth_tenant/presentation/providers/auth_provider.dart';
import 'package:fishbit_finance/core/utils/sigla_generator.dart';

class SedeSelectorModal extends ConsumerStatefulWidget {
  const SedeSelectorModal({super.key});

  static Future<void> show(BuildContext context) {
    return showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Cerrar Selector',
      barrierColor: Colors.black.withValues(alpha: 0.55),
      transitionDuration: const Duration(milliseconds: 240),
      pageBuilder: (dialogCtx, anim1, anim2) => const Material(
        type: MaterialType.transparency,
        child: SedeSelectorModal(),
      ),
      transitionBuilder: (dialogCtx, anim, secondaryAnim, child) {
        final curved = CurvedAnimation(parent: anim, curve: Curves.easeOutCubic);
        return ScaleTransition(
          scale: Tween<double>(begin: 0.95, end: 1.0).animate(curved),
          child: FadeTransition(opacity: curved, child: child),
        );
      },
    );
  }

  @override
  ConsumerState<SedeSelectorModal> createState() => _SedeSelectorModalState();
}

class _SedeSelectorModalState extends ConsumerState<SedeSelectorModal> {
  bool _isCreatingUnit = false;
  final _unitNameCtrl = TextEditingController();
  final _unitSiglaCtrl = TextEditingController();
  final _unitUbicacionCtrl = TextEditingController();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _unitNameCtrl.addListener(_onUnitNameChanged);
  }

  void _onUnitNameChanged() {
    final text = _unitNameCtrl.text;
    _unitSiglaCtrl.text = SiglaGenerator.generate(text, fallback: 'SED');
  }

  @override
  void dispose() {
    _unitNameCtrl.removeListener(_onUnitNameChanged);
    _unitNameCtrl.dispose();
    _unitSiglaCtrl.dispose();
    _unitUbicacionCtrl.dispose();
    super.dispose();
  }

  Future<void> _handleCreateUnit(String empresaId) async {
    if (_unitNameCtrl.text.trim().isEmpty || _unitSiglaCtrl.text.trim().isEmpty) return;

    setState(() => _isLoading = true);
    try {
      final repo = ref.read(authRepositoryProvider);
      final newUnit = await repo.createUnit(
        empresaId,
        _unitNameCtrl.text.trim(),
        _unitSiglaCtrl.text.trim(),
        _unitUbicacionCtrl.text.trim(),
      );

      await ref.read(authProvider.notifier).reloadCompanyAndUnits();
      await ref.read(authProvider.notifier).selectActiveUnit(newUnit.id);

      if (mounted) {
        setState(() {
          _isCreatingUnit = false;
          _isLoading = false;
        });
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Sede ${newUnit.nombre} (${newUnit.sigla}) creada y activada.'),
            backgroundColor: AppColors.greenBiomass,
          ),
        );
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final company = authState.currentCompany;
    final availableCompanies = authState.availableCompanies;
    final units = authState.units;
    final activeUnitId = authState.activeUnitId;
    final user = authState.currentUser;
    final isAdmin = user?.role == UserRole.admin || user?.role == UserRole.creator;

    return Material(
      type: MaterialType.transparency,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => Navigator.of(context).pop(),
        child: SafeArea(
          child: Align(
            alignment: Alignment.topCenter,
            child: Padding(
              // Flota suspendido justo debajo de la barra superior
              padding: const EdgeInsets.only(top: 68, left: 16, right: 16, bottom: 20),
              child: GestureDetector(
                onTap: () {}, // Evitar que clics dentro cierren el selector
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 480),
                  child: GlassContainer(
                    borderRadius: 26,
                    padding: const EdgeInsets.all(20),
                    blur: 28,
                    opacity: 0.18,
                    borderColor: AppColors.cyanWater.withValues(alpha: 0.35),
                    child: SingleChildScrollView(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Header con Empresa Activa y botón de cierre
                          Row(
                            children: [
                              Container(
                                width: 44,
                                height: 44,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: AppColors.cyanWater.withValues(alpha: 0.18),
                                  border: Border.all(color: AppColors.cyanWater.withValues(alpha: 0.4)),
                                ),
                                child: const Icon(Icons.business_rounded, color: AppColors.cyanWater, size: 22),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      company?.nombreComercial ?? 'Piscícola Activa',
                                      style: AppTypography.titleMedium.copyWith(color: Colors.white, fontWeight: FontWeight.w800),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    Text(
                                      'NIT: ${company?.nit ?? '900.123.456-7'} • ${company?.direccion ?? 'Colombia'}',
                                      style: AppTypography.labelMicro.copyWith(color: AppColors.textSecondaryDark),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                              ),
                              Material(
                                color: Colors.transparent,
                                child: InkWell(
                                  onTap: () => Navigator.of(context).pop(),
                                  borderRadius: BorderRadius.circular(12),
                                  child: Container(
                                    padding: const EdgeInsets.all(4),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withValues(alpha: 0.08),
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(Icons.close_rounded, size: 16, color: AppColors.textSecondaryDark),
                                  ),
                                ),
                              ),
                            ],
                          ),

                          // Selector de Empresa (Si existen múltiples empresas registradas)
                          if (availableCompanies.length > 1) ...[
                            const SizedBox(height: 16),
                            Text(
                              'EMPRESAS DISPONIBLES',
                              style: AppTypography.labelMicro.copyWith(
                                color: AppColors.textSecondaryDark,
                                letterSpacing: 1.2,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(height: 8),
                            SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              child: Row(
                                children: availableCompanies.map((c) {
                                  final isCompSelected = c.id == company?.id;
                                  return Padding(
                                    padding: const EdgeInsets.only(right: 8),
                                    child: Material(
                                      color: Colors.transparent,
                                      child: InkWell(
                                        onTap: () => ref.read(authProvider.notifier).selectCompany(c.id),
                                        borderRadius: BorderRadius.circular(12),
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                          decoration: BoxDecoration(
                                            color: isCompSelected ? AppColors.cyanWater.withValues(alpha: 0.20) : Colors.white.withValues(alpha: 0.05),
                                            borderRadius: BorderRadius.circular(12),
                                            border: Border.all(
                                              color: isCompSelected ? AppColors.cyanWater : Colors.white.withValues(alpha: 0.1),
                                              width: isCompSelected ? 1.5 : 1,
                                            ),
                                          ),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Icon(
                                                isCompSelected ? Icons.check_circle_rounded : Icons.domain_rounded,
                                                color: isCompSelected ? AppColors.cyanWater : AppColors.textSecondaryDark,
                                                size: 16,
                                              ),
                                              const SizedBox(width: 6),
                                              Text(
                                                c.nombreComercial,
                                                style: TextStyle(
                                                  color: isCompSelected ? Colors.white : AppColors.textSecondaryDark,
                                                  fontWeight: isCompSelected ? FontWeight.w800 : FontWeight.w600,
                                                  fontSize: 12,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                  );
                                }).toList(),
                              ),
                            ),
                          ],

                          const SizedBox(height: 18),

                          // Título del Listado y Botón "+ Nueva Sede"
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'SEDES ACUÍCOLAS (${units.length})',
                                style: AppTypography.labelMicro.copyWith(
                                  color: AppColors.cyanWater,
                                  letterSpacing: 1.2,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              if (isAdmin && !_isCreatingUnit)
                                Material(
                                  color: Colors.transparent,
                                  child: InkWell(
                                    onTap: () => setState(() => _isCreatingUnit = true),
                                    borderRadius: BorderRadius.circular(8),
                                    child: const Padding(
                                      padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(Icons.add_location_alt_outlined, color: AppColors.cyanWater, size: 15),
                                          SizedBox(width: 4),
                                          Text(
                                            'Nueva Sede',
                                            style: TextStyle(
                                              color: AppColors.cyanWater,
                                              fontSize: 11.5,
                                              fontWeight: FontWeight.w700,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 10),

                          // Formulario Desplegable para Crear Sede
                          if (_isCreatingUnit) ...[
                            GlassContainer(
                              borderRadius: 18,
                              padding: const EdgeInsets.all(16),
                              blur: 16,
                              opacity: 0.12,
                              borderColor: AppColors.cyanWater.withValues(alpha: 0.3),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Registrar Nueva Sede Acuícola',
                                    style: AppTypography.titleSmall.copyWith(color: AppColors.cyanWater, fontWeight: FontWeight.w800),
                                  ),
                                  const SizedBox(height: 12),
                                  Row(
                                    children: [
                                      Expanded(
                                        flex: 3,
                                        child: GlassFormField(
                                          label: 'NOMBRE DE SEDE',
                                          hint: 'Ej: Sede Norte',
                                          controller: _unitNameCtrl,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        flex: 2,
                                        child: GlassFormField(
                                          label: 'SIGLA (AUTO)',
                                          hint: 'SED',
                                          controller: _unitSiglaCtrl,
                                          prefixIcon: Icons.short_text_rounded,
                                          suffixWidget: const Padding(
                                            padding: EdgeInsets.only(right: 10),
                                            child: Icon(Icons.lock_outline_rounded, color: AppColors.cyanWater, size: 16),
                                          ),
                                          isReadOnly: true,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 10),
                                  GlassFormField(
                                    label: 'UBICACIÓN / MUNICIPIO',
                                    hint: 'Ej: Cereté, Vereda El Retiro',
                                    controller: _unitUbicacionCtrl,
                                  ),
                                  const SizedBox(height: 14),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: OutlinedButton(
                                          style: OutlinedButton.styleFrom(
                                            foregroundColor: Colors.white,
                                            side: BorderSide(color: Colors.white.withValues(alpha: 0.25)),
                                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                          ),
                                          onPressed: () => setState(() => _isCreatingUnit = false),
                                          child: const Text('Cancelar'),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        flex: 2,
                                        child: GlassButton(
                                          label: 'Guardar Sede',
                                          height: 42,
                                          isLoading: _isLoading,
                                          backgroundColor: AppColors.cyanWater,
                                          onPressed: () => _handleCreateUnit(company?.id ?? ''),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 10),
                          ],

                          // Listado Vertical de Sedes
                          ConstrainedBox(
                            constraints: const BoxConstraints(maxHeight: 280),
                            child: ListView.separated(
                              shrinkWrap: true,
                              itemCount: units.length,
                              separatorBuilder: (_, __) => const SizedBox(height: 8),
                              itemBuilder: (context, index) {
                                final unit = units[index];
                                final isSelected = unit.id == activeUnitId;

                                return Material(
                                  color: Colors.transparent,
                                  child: InkWell(
                                    onTap: () async {
                                      await ref.read(authProvider.notifier).selectActiveUnit(unit.id);
                                      if (context.mounted) {
                                        Navigator.of(context).pop();
                                      }
                                    },
                                    borderRadius: BorderRadius.circular(16),
                                    child: AnimatedContainer(
                                      duration: const Duration(milliseconds: 200),
                                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                                      decoration: BoxDecoration(
                                        color: isSelected
                                            ? AppColors.cyanWater.withValues(alpha: 0.16)
                                            : Colors.white.withValues(alpha: 0.04),
                                        borderRadius: BorderRadius.circular(16),
                                        border: Border.all(
                                          color: isSelected ? AppColors.cyanWater : Colors.white.withValues(alpha: 0.08),
                                          width: isSelected ? 1.5 : 1,
                                        ),
                                      ),
                                      child: Row(
                                        children: [
                                          Container(
                                            width: 40,
                                            height: 40,
                                            decoration: BoxDecoration(
                                              color: isSelected ? AppColors.cyanWater : Colors.white.withValues(alpha: 0.08),
                                              borderRadius: BorderRadius.circular(12),
                                            ),
                                            child: Center(
                                              child: Text(
                                                unit.sigla,
                                                style: TextStyle(
                                                  color: isSelected ? Colors.black : Colors.white,
                                                  fontWeight: FontWeight.w900,
                                                  fontSize: 13,
                                                ),
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 12),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  unit.nombre,
                                                  style: TextStyle(
                                                    color: isSelected ? Colors.white : AppColors.textSecondaryDark,
                                                    fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                                                    fontSize: 13.5,
                                                  ),
                                                ),
                                                if (unit.ubicacion != null)
                                                  Text(
                                                    unit.ubicacion!,
                                                    style: AppTypography.labelMicro.copyWith(color: AppColors.textSecondaryDark),
                                                  ),
                                              ],
                                            ),
                                          ),
                                          if (isSelected)
                                            const Icon(Icons.check_circle_rounded, color: AppColors.cyanWater, size: 20)
                                          else
                                            Icon(Icons.radio_button_unchecked_rounded, color: AppColors.textSecondaryDark.withValues(alpha: 0.5), size: 18),
                                        ],
                                      ),
                                    ),
                                  ),
                                );
                              },
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
        ),
      ),
    );
  }
}
