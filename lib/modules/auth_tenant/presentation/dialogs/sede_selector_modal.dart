import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fishbit_finance/core/design_system/app_colors.dart';
import 'package:fishbit_finance/core/design_system/app_typography.dart';
import 'package:fishbit_finance/core/design_system/glass_container.dart';
import 'package:fishbit_finance/core/design_system/glass_form_field.dart';
import 'package:fishbit_finance/core/design_system/glass_button.dart';
import 'package:fishbit_finance/core/design_system/widgets/glass_location_dropdown.dart';
import 'package:fishbit_finance/core/services/geographic_service.dart';
import 'package:fishbit_finance/core/utils/sigla_generator.dart';
import 'package:fishbit_finance/modules/auth_tenant/domain/models/aquaculture_unit.dart';
import 'package:fishbit_finance/modules/auth_tenant/presentation/providers/auth_provider.dart';

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
  bool _isLoading = false;

  final _formKey = GlobalKey<FormState>();
  final _nombreCtrl = TextEditingController();
  final _direccionCtrl = TextEditingController();
  final _telefonoCtrl = TextEditingController();

  String _siglaGenerada = 'SED';
  String _selectedCountry = GeographicService.defaultCountry;
  String _selectedDepartment = 'Antioquia';
  String _selectedCity = 'San Jerónimo';

  @override
  void initState() {
    super.initState();
    _nombreCtrl.addListener(_onNombreChanged);
    _actualizarCascadaGeografica(_selectedCountry);
  }

  @override
  void dispose() {
    _nombreCtrl.removeListener(_onNombreChanged);
    _nombreCtrl.dispose();
    _direccionCtrl.dispose();
    _telefonoCtrl.dispose();
    super.dispose();
  }

  void _onNombreChanged() {
    final units = ref.read(authProvider).units;
    final newSigla = _computeUniqueSigla(_nombreCtrl.text, units);
    if (newSigla != _siglaGenerada && mounted) {
      setState(() {
        _siglaGenerada = newSigla;
      });
    }
  }

  static String _computeUniqueSigla(String name, List<AquacultureUnit> existingUnits) {
    final existingSiglas = existingUnits.map((u) => u.sigla.toUpperCase().trim()).toSet();
    final cleanName = name.trim();
    if (cleanName.isEmpty) {
      for (int i = 1; i <= 99; i++) {
        final candidate = 'SED$i';
        if (!existingSiglas.contains(candidate)) return candidate;
      }
      return 'SED';
    }

    final base = SiglaGenerator.generate(cleanName, fallback: 'SED', maxLength: 4).toUpperCase();
    if (!existingSiglas.contains(base)) return base;

    for (int i = 2; i <= 99; i++) {
      final candidate = '$base$i';
      if (!existingSiglas.contains(candidate)) return candidate;
    }
    return '${base}X';
  }

  void _actualizarCascadaGeografica(String pais) {
    final deptos = GeographicService.getStatesForCountry(pais);
    final nuevoDepto = deptos.isNotEmpty ? deptos.first : '';
    final ciudades = GeographicService.getCitiesForState(pais, nuevoDepto);
    final nuevaCiudad = ciudades.isNotEmpty ? ciudades.first : '';

    setState(() {
      _selectedCountry = pais;
      _selectedDepartment = nuevoDepto;
      _selectedCity = nuevaCiudad;
    });
  }

  void _onCountryChanged(String newCountry) {
    _actualizarCascadaGeografica(newCountry);
  }

  void _onDepartmentChanged(String newDepto) {
    final ciudades = GeographicService.getCitiesForState(_selectedCountry, newDepto);
    setState(() {
      _selectedDepartment = newDepto;
      _selectedCity = ciudades.isNotEmpty ? ciudades.first : '';
    });
  }

  void _onCityChanged(String newCity) {
    setState(() {
      _selectedCity = newCity;
    });
  }

  Future<void> _handleCreateUnit(String empresaId) async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    try {
      final repo = ref.read(authRepositoryProvider);
      final nombre = _nombreCtrl.text.trim();
      final sigla = _siglaGenerada.toUpperCase();
      final direccion = _direccionCtrl.text.trim();
      final telefono = _telefonoCtrl.text.trim();

      final ubicacionParts = [
        if (direccion.isNotEmpty) direccion,
        _selectedCity,
        _selectedDepartment,
        _selectedCountry,
      ];
      final ubicacion = ubicacionParts.join(', ');

      final newUnit = await repo.createUnit(
        empresaId,
        nombre,
        sigla,
        ubicacion,
        pais: _selectedCountry,
        departamento: _selectedDepartment,
        ciudad: _selectedCity,
        direccion: direccion.isNotEmpty ? direccion : null,
        telefono: telefono.isNotEmpty ? telefono : null,
      );

      await ref.read(authProvider.notifier).reloadCompanyAndUnits();
      await ref.read(authProvider.notifier).selectActiveUnit(newUnit.id);

      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Sede ${newUnit.nombre} (${newUnit.sigla}) registrada y activada con éxito.'),
            backgroundColor: AppColors.greenBiomass,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al crear sede: ${e.toString()}'),
            backgroundColor: AppColors.coralAction,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final authState = ref.watch(authProvider);
    final company = authState.currentCompany;
    final availableCompanies = authState.availableCompanies;
    final units = authState.units;
    final activeUnitId = authState.activeUnitId;
    final deptos = GeographicService.getStatesForCountry(_selectedCountry);
    final ciudades = GeographicService.getCitiesForState(_selectedCountry, _selectedDepartment);

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
                    opacity: isDark ? 0.20 : 0.95,
                    borderColor: AppColors.cyanWater.withValues(alpha: isDark ? 0.40 : 0.30),
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
                                      style: AppTypography.titleMedium.copyWith(
                                        color: isDark ? Colors.white : AppColors.textPrimaryLight,
                                        fontWeight: FontWeight.w800,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    Text(
                                      'NIT: ${company?.nit ?? '900.123.456-7'} • ${company?.direccion ?? 'Colombia'}',
                                      style: AppTypography.labelMicro.copyWith(
                                        color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                                      ),
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
                                      color: isDark ? Colors.white.withValues(alpha: 0.08) : Colors.black.withValues(alpha: 0.05),
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(
                                      Icons.close_rounded,
                                      size: 16,
                                      color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                                    ),
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
                                color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
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
                              if (!_isCreatingUnit)
                                Material(
                                  color: Colors.transparent,
                                  child: InkWell(
                                    onTap: () {
                                      setState(() {
                                        _isCreatingUnit = true;
                                        _onNombreChanged();
                                      });
                                    },
                                    borderRadius: BorderRadius.circular(8),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: AppColors.cyanWater.withValues(alpha: 0.12),
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(color: AppColors.cyanWater.withValues(alpha: 0.3)),
                                      ),
                                      child: const Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(Icons.add_business_rounded, color: AppColors.cyanWater, size: 14),
                                          SizedBox(width: 4),
                                          Text(
                                            '+ Nueva Sede',
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

                          // Formulario Estructurado Desplegable para Crear Sede
                          if (_isCreatingUnit) ...[
                            GlassContainer(
                              borderRadius: 20,
                              padding: const EdgeInsets.all(16),
                              blur: 24,
                              opacity: isDark ? 0.22 : 0.95,
                              borderColor: AppColors.cyanWater.withValues(alpha: isDark ? 0.45 : 0.35),
                              child: Form(
                                key: _formKey,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Container(
                                          width: 36,
                                          height: 36,
                                          decoration: BoxDecoration(
                                            shape: BoxShape.circle,
                                            color: AppColors.cyanWater.withValues(alpha: 0.18),
                                            border: Border.all(color: AppColors.cyanWater.withValues(alpha: 0.4)),
                                          ),
                                          child: const Icon(Icons.add_business_rounded, color: AppColors.cyanWater, size: 18),
                                        ),
                                        const SizedBox(width: 10),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                'Registrar Nueva Sede Acuícola',
                                                style: AppTypography.titleSmall.copyWith(
                                                  color: isDark ? Colors.white : AppColors.textPrimaryLight,
                                                  fontWeight: FontWeight.w800,
                                                ),
                                              ),
                                              Text(
                                                'Herramienta geográfica y asignación oficial',
                                                style: AppTypography.labelMicro.copyWith(
                                                  color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        IconButton(
                                          icon: const Icon(Icons.close_rounded, size: 18),
                                          color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                                          tooltip: 'Cancelar',
                                          onPressed: () => setState(() => _isCreatingUnit = false),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 14),

                                    // Nombre de Sede y Sigla
                                    Row(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Expanded(
                                          flex: 3,
                                          child: GlassFormField(
                                            label: 'NOMBRE DE SEDE *',
                                            hint: 'Ej: Sede Norte',
                                            controller: _nombreCtrl,
                                            prefixIcon: Icons.storefront_rounded,
                                            validator: (value) {
                                              if (value == null || value.trim().isEmpty) {
                                                return 'El nombre es obligatorio';
                                              }
                                              if (value.trim().length < 3) {
                                                return 'Mínimo 3 caracteres';
                                              }
                                              return null;
                                            },
                                          ),
                                        ),
                                        const SizedBox(width: 10),
                                        Expanded(
                                          flex: 2,
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Row(
                                                children: [
                                                  Text(
                                                    'SIGLA (AUTO)',
                                                    style: AppTypography.labelMicro.copyWith(
                                                      color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                                                      fontWeight: FontWeight.w700,
                                                    ),
                                                  ),
                                                  const SizedBox(width: 4),
                                                  const Icon(Icons.lock_rounded, size: 12, color: AppColors.cyanWater),
                                                ],
                                              ),
                                              const SizedBox(height: 6),
                                              Container(
                                                height: 56,
                                                padding: const EdgeInsets.symmetric(horizontal: 12),
                                                decoration: BoxDecoration(
                                                  color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.04),
                                                  borderRadius: BorderRadius.circular(16),
                                                  border: Border.all(
                                                    color: isDark ? Colors.white.withValues(alpha: 0.12) : AppColors.glassBorderLight,
                                                  ),
                                                ),
                                                child: Row(
                                                  children: [
                                                    const Icon(Icons.tag_rounded, size: 16, color: AppColors.cyanWater),
                                                    const SizedBox(width: 6),
                                                    Expanded(
                                                      child: Text(
                                                        _siglaGenerada,
                                                        style: TextStyle(
                                                          color: isDark ? Colors.white : AppColors.textPrimaryLight,
                                                          fontWeight: FontWeight.w800,
                                                          fontSize: 13.5,
                                                          letterSpacing: 0.8,
                                                        ),
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 14),

                                    // Herramienta Geográfica en Cascada
                                    Text(
                                      'UBICACIÓN GEOGRÁFICA',
                                      style: AppTypography.labelMicro.copyWith(
                                        color: AppColors.cyanWater,
                                        letterSpacing: 1.1,
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                    const SizedBox(height: 8),

                                    // Selector de País
                                    GlassLocationDropdown(
                                      label: 'PAÍS',
                                      value: _selectedCountry,
                                      items: GeographicService.countries,
                                      icon: Icons.public_rounded,
                                      accentColor: isDark ? AppColors.cyanWater : AppColors.cyanWaterTextLight,
                                      onChanged: _onCountryChanged,
                                    ),
                                    const SizedBox(height: 10),

                                    // Selectores de Depto y Ciudad
                                    Row(
                                      children: [
                                        Expanded(
                                          child: GlassLocationDropdown(
                                            label: 'DEPARTAMENTO / ESTADO',
                                            value: _selectedDepartment,
                                            items: deptos,
                                            icon: Icons.map_rounded,
                                            accentColor: isDark ? AppColors.cyanWater : AppColors.cyanWaterTextLight,
                                            onChanged: _onDepartmentChanged,
                                          ),
                                        ),
                                        const SizedBox(width: 10),
                                        Expanded(
                                          child: GlassLocationDropdown(
                                            label: 'CIUDAD / MUNICIPIO',
                                            value: _selectedCity,
                                            items: ciudades,
                                            icon: Icons.location_city_rounded,
                                            accentColor: isDark ? AppColors.cyanWater : AppColors.cyanWaterTextLight,
                                            onChanged: _onCityChanged,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 10),

                                    // Chip resumen de ubicación
                                    Container(
                                      width: double.infinity,
                                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                      decoration: BoxDecoration(
                                        color: AppColors.cyanWater.withValues(alpha: 0.08),
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(color: AppColors.cyanWater.withValues(alpha: 0.2)),
                                      ),
                                      child: Row(
                                        children: [
                                          const Icon(Icons.pin_drop_rounded, size: 16, color: AppColors.cyanWater),
                                          const SizedBox(width: 8),
                                          Expanded(
                                            child: Text(
                                              '$_selectedCity, $_selectedDepartment, $_selectedCountry',
                                              style: TextStyle(
                                                fontSize: 12,
                                                fontWeight: FontWeight.w600,
                                                color: isDark ? Colors.white70 : AppColors.textPrimaryLight,
                                              ),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(height: 12),

                                    // Dirección del predio
                                    GlassFormField(
                                      label: 'DIRECCIÓN / VEREDA / SECTOR (OPCIONAL)',
                                      hint: 'Ej: Vereda El Retiro, Km 5',
                                      controller: _direccionCtrl,
                                      prefixIcon: Icons.map_outlined,
                                    ),
                                    const SizedBox(height: 12),

                                    // Teléfono de contacto
                                    GlassFormField(
                                      label: 'TELÉFONO DE CONTACTO (OPCIONAL)',
                                      hint: 'Ej: 312 345 6789',
                                      controller: _telefonoCtrl,
                                      prefixIcon: Icons.phone_rounded,
                                      keyboardType: TextInputType.phone,
                                    ),
                                    const SizedBox(height: 16),

                                    // Botones Cancelar y Guardar
                                    Row(
                                      children: [
                                        Expanded(
                                          child: OutlinedButton(
                                            style: OutlinedButton.styleFrom(
                                              foregroundColor: isDark ? Colors.white70 : AppColors.textSecondaryLight,
                                              side: BorderSide(
                                                color: isDark ? Colors.white24 : Colors.black12,
                                              ),
                                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                                              padding: const EdgeInsets.symmetric(vertical: 12),
                                            ),
                                            onPressed: _isLoading ? null : () => setState(() => _isCreatingUnit = false),
                                            child: const Text('Cancelar', style: TextStyle(fontWeight: FontWeight.w600)),
                                          ),
                                        ),
                                        const SizedBox(width: 10),
                                        Expanded(
                                          flex: 2,
                                          child: GlassButton(
                                            label: 'Guardar Sede',
                                            height: 44,
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
                            ),
                            const SizedBox(height: 12),
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
