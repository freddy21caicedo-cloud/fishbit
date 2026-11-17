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

/// Modal oficial estructurado para la creación de nuevas sedes acuícolas.
/// Cumple con los estándares de diseño de FishBit: Glassmorphism, herramienta
/// geográfica en cascada (País -> Depto -> Ciudad), sigla auto-generada sin
/// colisiones, soporte completo de temas Claro/Oscuro y cero emojis.
class CrearSedeModal extends ConsumerStatefulWidget {
  final String empresaId;

  const CrearSedeModal({
    super.key,
    required this.empresaId,
  });

  /// Abre el diálogo centrado con transición fluida
  static Future<AquacultureUnit?> show(BuildContext context, {required String empresaId}) {
    return showGeneralDialog<AquacultureUnit>(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Cerrar Modal Sede',
      barrierColor: Colors.black.withValues(alpha: 0.65),
      transitionDuration: const Duration(milliseconds: 240),
      pageBuilder: (dialogCtx, anim1, anim2) => Material(
        type: MaterialType.transparency,
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: CrearSedeModal(empresaId: empresaId),
          ),
        ),
      ),
      transitionBuilder: (dialogCtx, anim, secondaryAnim, child) {
        final curved = CurvedAnimation(parent: anim, curve: Curves.easeOutCubic);
        return ScaleTransition(
          scale: Tween<double>(begin: 0.94, end: 1.0).animate(curved),
          child: FadeTransition(opacity: curved, child: child),
        );
      },
    );
  }

  @override
  ConsumerState<CrearSedeModal> createState() => _CrearSedeModalState();
}

class _CrearSedeModalState extends ConsumerState<CrearSedeModal> {
  final _formKey = GlobalKey<FormState>();

  final _nombreCtrl = TextEditingController();
  final _direccionCtrl = TextEditingController();
  final _telefonoCtrl = TextEditingController();

  String _siglaGenerada = 'SED1';

  // Selector Geográfico en cascada
  String _selectedCountry = GeographicService.defaultCountry;
  String _selectedDepartment = 'Antioquia';
  String _selectedCity = 'San Jerónimo';

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _nombreCtrl.addListener(_onNombreChanged);
    _actualizarCascadaGeografica(_selectedCountry, departamentoInicial: 'Antioquia', ciudadInicial: 'San Jerónimo');
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _recalcularSigla();
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
    _recalcularSigla();
  }

  void _recalcularSigla() {
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

  void _actualizarCascadaGeografica(String pais, {String? departamentoInicial, String? ciudadInicial}) {
    final deptos = GeographicService.getStatesForCountry(pais);
    final nuevoDepto = departamentoInicial != null && deptos.contains(departamentoInicial)
        ? departamentoInicial
        : (deptos.isNotEmpty ? deptos.first : '');

    final ciudades = GeographicService.getCitiesForState(pais, nuevoDepto);
    final nuevaCiudad = ciudadInicial != null && ciudades.contains(ciudadInicial)
        ? ciudadInicial
        : (ciudades.isNotEmpty ? ciudades.first : '');

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

  Future<void> _guardarSede() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final repo = ref.read(authRepositoryProvider);
      final nombre = _nombreCtrl.text.trim();
      final sigla = _siglaGenerada.toUpperCase();
      final direccion = _direccionCtrl.text.trim();
      final telefono = _telefonoCtrl.text.trim();

      // Construcción de la ubicación consolidada
      final ubicacionParts = [
        if (direccion.isNotEmpty) direccion,
        _selectedCity,
        _selectedDepartment,
        _selectedCountry,
      ];
      final ubicacion = ubicacionParts.join(', ');

      final newUnit = await repo.createUnit(
        widget.empresaId,
        nombre,
        sigla,
        ubicacion,
        pais: _selectedCountry,
        departamento: _selectedDepartment,
        ciudad: _selectedCity,
        direccion: direccion.isNotEmpty ? direccion : null,
        telefono: telefono.isNotEmpty ? telefono : null,
      );

      // Sincronizar estado global
      await ref.read(authProvider.notifier).reloadCompanyAndUnits();
      await ref.read(authProvider.notifier).selectActiveUnit(newUnit.id);

      if (mounted) {
        Navigator.of(context).pop(newUnit);
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
    final deptos = GeographicService.getStatesForCountry(_selectedCountry);
    final ciudades = GeographicService.getCitiesForState(_selectedCountry, _selectedDepartment);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: GlassContainer(
        borderRadius: 24,
        padding: const EdgeInsets.all(22),
        blur: 28,
        opacity: isDark ? 0.20 : 0.95,
        borderColor: AppColors.cyanWater.withValues(alpha: isDark ? 0.40 : 0.30),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Cabecera Oficial
                Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.cyanWater.withValues(alpha: 0.18),
                        border: Border.all(color: AppColors.cyanWater.withValues(alpha: 0.45)),
                      ),
                      child: const Icon(Icons.add_business_rounded, color: AppColors.cyanWater, size: 22),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Registrar Nueva Sede',
                            style: AppTypography.titleMedium.copyWith(
                              color: isDark ? Colors.white : AppColors.textPrimaryLight,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          Text(
                            'Añade una unidad productiva o finca piscícola',
                            style: AppTypography.labelMicro.copyWith(
                              color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded, size: 20),
                      color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                      tooltip: 'Cerrar',
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
                const SizedBox(height: 18),

                // Sección 1: Identificación
                Text(
                  'DATOS DE LA SEDE',
                  style: AppTypography.labelMicro.copyWith(
                    color: AppColors.cyanWater,
                    letterSpacing: 1.1,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 8),

                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      flex: 3,
                      child: GlassFormField(
                        label: 'NOMBRE DE SEDE *',
                        hint: 'Ej: Piscícola El Silencio',
                        controller: _nombreCtrl,
                        prefixIcon: Icons.storefront_rounded,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'El nombre de la sede es obligatorio';
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
                                'SIGLA OFICIAL',
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
                            padding: const EdgeInsets.symmetric(horizontal: 14),
                            decoration: BoxDecoration(
                              color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.04),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: isDark ? Colors.white.withValues(alpha: 0.12) : AppColors.glassBorderLight,
                              ),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.tag_rounded, size: 18, color: AppColors.cyanWater),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    _siglaGenerada,
                                    style: TextStyle(
                                      color: isDark ? Colors.white : AppColors.textPrimaryLight,
                                      fontWeight: FontWeight.w800,
                                      fontSize: 14,
                                      letterSpacing: 0.8,
                                    ),
                                  ),
                                ),
                                Tooltip(
                                  message: 'Asignada automáticamente para evitar réplicas.',
                                  child: Icon(
                                    Icons.info_outline_rounded,
                                    size: 16,
                                    color: isDark ? Colors.white38 : Colors.black38,
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
                const SizedBox(height: 16),

                // Sección 2: Herramienta Geográfica en Cascada
                Text(
                  'UBICACIÓN GEOGRÁFICA',
                  style: AppTypography.labelMicro.copyWith(
                    color: AppColors.cyanWater,
                    letterSpacing: 1.1,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 8),

                // País
                GlassLocationDropdown(
                  label: 'PAÍS',
                  value: _selectedCountry,
                  items: GeographicService.countries,
                  icon: Icons.public_rounded,
                  accentColor: isDark ? AppColors.cyanWater : AppColors.cyanWaterTextLight,
                  onChanged: _onCountryChanged,
                ),
                const SizedBox(height: 10),

                // Departamento y Ciudad en dos columnas
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

                // Chip de resumen de ubicación seleccionada
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

                // Dirección o Vereda física
                GlassFormField(
                  label: 'DIRECCIÓN / VEREDA / SECTOR (OPCIONAL)',
                  hint: 'Ej: Vereda El Retiro, Km 4 Vía San Jerónimo',
                  controller: _direccionCtrl,
                  prefixIcon: Icons.map_outlined,
                ),
                const SizedBox(height: 12),

                // Teléfono de contacto
                GlassFormField(
                  label: 'TELÉFONO DE CONTACTO (OPCIONAL)',
                  hint: 'Ej: 310 123 4567',
                  controller: _telefonoCtrl,
                  prefixIcon: Icons.phone_rounded,
                  keyboardType: TextInputType.phone,
                ),
                const SizedBox(height: 22),

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
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          padding: const EdgeInsets.symmetric(vertical: 13),
                        ),
                        onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
                        child: const Text('Cancelar', style: TextStyle(fontWeight: FontWeight.w600)),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 2,
                      child: GlassButton(
                        label: 'Guardar Sede',
                        height: 46,
                        isLoading: _isLoading,
                        backgroundColor: AppColors.cyanWater,
                        onPressed: _guardarSede,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
