import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import 'package:fishbit_finance/core/design_system/app_colors.dart';
import 'package:fishbit_finance/core/design_system/app_typography.dart';
import 'package:fishbit_finance/core/design_system/glass_container.dart';
import 'package:fishbit_finance/core/design_system/glass_form_field.dart';
import 'package:fishbit_finance/core/design_system/glass_button.dart';
import 'package:fishbit_finance/core/design_system/widgets/glass_location_dropdown.dart';
import 'package:fishbit_finance/core/services/geographic_service.dart';
import 'package:fishbit_finance/modules/warehouse_inventory/domain/models/supplier.dart';
import 'package:fishbit_finance/modules/warehouse_inventory/presentation/providers/warehouse_provider.dart';
import 'package:fishbit_finance/modules/auth_tenant/presentation/providers/auth_provider.dart';

/// Modal dialog oficial para registrar un nuevo proveedor comercial o fiscal.
/// Integra selector de tipo de documento, herramienta geográfica en cascada
/// (País -> Departamento -> Ciudad), datos de contacto y multi-selección de categorías.
class RegistrarProveedorModal extends ConsumerStatefulWidget {
  final String? initialCategory;

  const RegistrarProveedorModal({
    super.key,
    this.initialCategory,
  });

  static Future<Supplier?> show(BuildContext context, {String? initialCategory}) {
    return showDialog<Supplier?>(
      context: context,
      barrierDismissible: true,
      builder: (context) => RegistrarProveedorModal(initialCategory: initialCategory),
    );
  }

  @override
  ConsumerState<RegistrarProveedorModal> createState() => _RegistrarProveedorModalState();
}

class _RegistrarProveedorModalState extends ConsumerState<RegistrarProveedorModal> {
  final _formKey = GlobalKey<FormState>();

  // 1. Identificación y Razón Social
  final _nombreCtrl = TextEditingController();
  final _documentoCtrl = TextEditingController();
  String _tipoIdentificacion = 'NIT';

  // 2. Herramienta Geográfica en Cascada
  String _selectedCountry = GeographicService.defaultCountry;
  String _selectedDepartment = 'Antioquia';
  String _selectedCity = 'Medellín';

  // 3. Contacto
  final _contactoNombreCtrl = TextEditingController();
  final _telefonoCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _direccionCtrl = TextEditingController();

  // 4. Multi-categoría
  final Set<String> _categoriasSeleccionadas = {};

  final List<Map<String, dynamic>> _catalogoCategorias = [
    {
      'key': 'concentrados',
      'label': 'Concentrados y Nutrición',
      'icon': Icons.restaurant_rounded,
    },
    {
      'key': 'insumos',
      'label': 'Insumos y Tratamientos',
      'icon': Icons.science_rounded,
    },
    {
      'key': 'farmacia',
      'label': 'Farmacia y Medicamentos',
      'icon': Icons.medication_rounded,
    },
    {
      'key': 'oxigenadores',
      'label': 'Equipos y Oxigenadores',
      'icon': Icons.air_rounded,
    },
    {
      'key': 'alevinos',
      'label': 'Alevinos y Genética',
      'icon': Icons.bubble_chart_rounded,
    },
    {
      'key': 'empaque',
      'label': 'Empaque y Logística',
      'icon': Icons.inventory_2_rounded,
    },
    {
      'key': 'servicios',
      'label': 'Servicios y Mantenimiento',
      'icon': Icons.build_rounded,
    },
  ];

  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    // Inicializar categorías
    if (widget.initialCategory != null && widget.initialCategory!.isNotEmpty) {
      _categoriasSeleccionadas.add(widget.initialCategory!);
    } else {
      _categoriasSeleccionadas.add('concentrados');
    }

    _actualizarCascadaGeografica(_selectedCountry, departamentoInicial: 'Antioquia', ciudadInicial: 'Medellín');
  }

  @override
  void dispose() {
    _nombreCtrl.dispose();
    _documentoCtrl.dispose();
    _contactoNombreCtrl.dispose();
    _telefonoCtrl.dispose();
    _emailCtrl.dispose();
    _direccionCtrl.dispose();
    super.dispose();
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
    if (newCountry == _selectedCountry) return;
    _actualizarCascadaGeografica(newCountry);
  }

  void _onDepartmentChanged(String newDept) {
    if (newDept == _selectedDepartment) return;
    final ciudades = GeographicService.getCitiesForState(_selectedCountry, newDept);
    setState(() {
      _selectedDepartment = newDept;
      _selectedCity = ciudades.isNotEmpty ? ciudades.first : '';
    });
  }

  void _onCityChanged(String newCity) {
    setState(() {
      _selectedCity = newCity;
    });
  }

  void _toggleCategoria(String catKey) {
    setState(() {
      if (_categoriasSeleccionadas.contains(catKey)) {
        if (_categoriasSeleccionadas.length > 1) {
          _categoriasSeleccionadas.remove(catKey);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Debe seleccionar al menos una categoría para el proveedor.'),
              duration: Duration(seconds: 2),
            ),
          );
        }
      } else {
        _categoriasSeleccionadas.add(catKey);
      }
    });
  }

  String _getDocumentoHint() {
    switch (_tipoIdentificacion) {
      case 'NIT':
        return 'Ej. 900.123.456-7';
      case 'Cédula de Ciudadanía':
        return 'Ej. 1.020.345.678';
      case 'Pasaporte':
        return 'Ej. PA1234567';
      default:
        return 'Número de documento';
    }
  }

  Future<void> _guardarProveedor() async {
    if (!_formKey.currentState!.validate()) return;

    if (_categoriasSeleccionadas.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Selecciona al menos una categoría de suministro.'),
          backgroundColor: AppColors.amberWarning,
        ),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      final auth = ref.read(authProvider);
      final empresaId = auth.currentUser?.empresaId ??
          auth.currentCompany?.id ??
          'c1000000-0000-0000-0000-000000000001';

      final activeUnit = auth.units.where((u) => u.id == auth.activeUnitId).firstOrNull ??
          (auth.units.isNotEmpty ? auth.units.first : null);
      final sigla = activeUnit?.sigla ?? 'SEDE';

      final categoriasList = _categoriasSeleccionadas.toList();
      final catPrincipal = categoriasList.first;

      final newSupplier = Supplier(
        id: const Uuid().v4(),
        nit: _documentoCtrl.text.trim(),
        nombre: _nombreCtrl.text.trim(),
        tipoIdentificacion: _tipoIdentificacion,
        telefono: _telefonoCtrl.text.trim().isNotEmpty ? _telefonoCtrl.text.trim() : null,
        email: _emailCtrl.text.trim().isNotEmpty ? _emailCtrl.text.trim() : null,
        contactoNombre: _contactoNombreCtrl.text.trim().isNotEmpty ? _contactoNombreCtrl.text.trim() : null,
        pais: _selectedCountry,
        departamento: _selectedDepartment,
        ciudad: _selectedCity,
        direccion: _direccionCtrl.text.trim().isNotEmpty ? _direccionCtrl.text.trim() : null,
        categoriaPrincipal: catPrincipal,
        categorias: categoriasList,
        empresaId: empresaId,
        unidadAcuicolaSigla: sigla,
        isCustom: true,
      );

      await ref.read(warehouseProvider.notifier).addSupplier(newSupplier);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Proveedor "${newSupplier.nombre}" registrado exitosamente.'),
          backgroundColor: AppColors.greenBiomass,
        ),
      );

      Navigator.of(context).pop(newSupplier);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al registrar proveedor: $e'),
          backgroundColor: AppColors.coralAction,
        ),
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final auth = ref.watch(authProvider);
    final activeUnit = auth.units.where((u) => u.id == auth.activeUnitId).firstOrNull ??
        (auth.units.isNotEmpty ? auth.units.first : null);
    final unitSigla = activeUnit?.sigla ?? 'SEDE';

    final deptosDisponibles = GeographicService.getStatesForCountry(_selectedCountry);
    final ciudadesDisponibles = GeographicService.getCitiesForState(_selectedCountry, _selectedDepartment);

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 540, maxHeight: 820),
        child: GlassContainer(
          borderRadius: 24,
          padding: const EdgeInsets.all(22),
          blur: 24,
          opacity: isDark ? 0.16 : 0.90,
          borderColor: isDark ? AppColors.amberWarning.withValues(alpha: 0.35) : AppColors.glassBorderLight,
          tintColor: isDark ? AppColors.surfaceDarkRaised : AppColors.surfaceLight,
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // ─── Cabecera ──────────────────────────────────────────────
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: AppColors.amberWarning.withValues(alpha: isDark ? 0.18 : 0.15),
                              border: Border.all(
                                color: AppColors.amberWarning.withValues(alpha: 0.4),
                                width: 1.2,
                              ),
                            ),
                            child: const Icon(
                              Icons.storefront_rounded,
                              color: AppColors.amberWarning,
                              size: 22,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Registrar Nuevo Proveedor',
                                  style: AppTypography.titleLarge.copyWith(
                                    color: isDark ? Colors.white : AppColors.textPrimaryLight,
                                    fontSize: 17,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: AppColors.cyanWater.withValues(alpha: isDark ? 0.15 : 0.12),
                                        borderRadius: BorderRadius.circular(6),
                                        border: Border.all(
                                          color: AppColors.cyanWater.withValues(alpha: 0.35),
                                          width: 1,
                                        ),
                                      ),
                                      child: Text(
                                        'SEDE $unitSigla',
                                        style: TextStyle(
                                          color: isDark ? AppColors.cyanWater : AppColors.cyanWaterTextLight,
                                          fontSize: 10,
                                          fontWeight: FontWeight.w800,
                                          letterSpacing: 0.6,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Flexible(
                                      child: Text(
                                        'Directorio comercial y fiscal',
                                        style: AppTypography.labelMicro.copyWith(
                                          color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: Icon(
                        Icons.close_rounded,
                        color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                        size: 22,
                      ),
                      onPressed: () => Navigator.of(context).pop(),
                      tooltip: 'Cerrar',
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // ─── Contenido con Scroll ──────────────────────────────────
                Flexible(
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // 1. Identificación y Razón Social
                        Text(
                          'IDENTIFICACIÓN Y RAZÓN SOCIAL',
                          style: AppTypography.labelMicro.copyWith(
                            color: isDark ? AppColors.amberWarning : AppColors.amberWarningTextLight,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.8,
                          ),
                        ),
                        const SizedBox(height: 10),

                        GlassFormField(
                          label: 'NOMBRE O RAZÓN SOCIAL *',
                          hint: 'Ej. Molinos y Concentrados del Oriente S.A.S.',
                          controller: _nombreCtrl,
                          prefixIcon: Icons.business_rounded,
                          validator: (v) {
                            if (v == null || v.trim().isEmpty) {
                              return 'Ingresa el nombre o razón social del proveedor';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 12),

                        // Selector de Tipo de Identificación
                        Text(
                          'TIPO DE IDENTIFICACIÓN *',
                          style: AppTypography.labelMicro.copyWith(
                            color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: ['NIT', 'Cédula de Ciudadanía', 'Pasaporte'].map((tipo) {
                            final isSelected = _tipoIdentificacion == tipo;
                            return Expanded(
                              child: Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 3),
                                child: InkWell(
                                  onTap: () {
                                    setState(() => _tipoIdentificacion = tipo);
                                  },
                                  borderRadius: BorderRadius.circular(10),
                                  child: Container(
                                    constraints: const BoxConstraints(minHeight: 40),
                                    alignment: Alignment.center,
                                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
                                    decoration: BoxDecoration(
                                      color: isSelected
                                          ? AppColors.amberWarning.withValues(alpha: isDark ? 0.22 : 0.18)
                                          : (isDark
                                              ? Colors.white.withValues(alpha: 0.04)
                                              : Colors.black.withValues(alpha: 0.03)),
                                      borderRadius: BorderRadius.circular(10),
                                      border: Border.all(
                                        color: isSelected
                                            ? AppColors.amberWarning
                                            : (isDark
                                                ? Colors.white.withValues(alpha: 0.1)
                                                : AppColors.glassBorderLight),
                                        width: isSelected ? 1.4 : 1.0,
                                      ),
                                    ),
                                    child: Text(
                                      tipo == 'Cédula de Ciudadanía' ? 'Cédula' : tipo,
                                      style: TextStyle(
                                        color: isSelected
                                            ? (isDark ? Colors.white : AppColors.amberWarningTextLight)
                                            : (isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight),
                                        fontSize: 12,
                                        fontWeight: isSelected ? FontWeight.w800 : FontWeight.w500,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                        const SizedBox(height: 10),

                        GlassFormField(
                          label: 'NÚMERO DE IDENTIFICACIÓN ($_tipoIdentificacion) *',
                          hint: _getDocumentoHint(),
                          controller: _documentoCtrl,
                          prefixIcon: Icons.badge_rounded,
                          validator: (v) {
                            if (v == null || v.trim().isEmpty) {
                              return 'Ingresa el número de identificación';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 18),

                        // 2. Herramienta Geográfica en Cascada
                        Row(
                          children: [
                            const Icon(Icons.location_on_rounded, color: AppColors.cyanWater, size: 18),
                            const SizedBox(width: 8),
                            Text(
                              'UBICACIÓN GEOGRÁFICA',
                              style: AppTypography.labelMicro.copyWith(
                                color: isDark ? AppColors.cyanWater : AppColors.cyanWaterTextLight,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0.8,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),

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

                        // Departamento y Ciudad en dos columnas responsivas
                        LayoutBuilder(
                          builder: (context, constraints) {
                            final isCompact = constraints.maxWidth < 400;
                            if (isCompact) {
                              return Column(
                                children: [
                                  GlassLocationDropdown(
                                    label: 'DEPARTAMENTO / ESTADO',
                                    value: _selectedDepartment,
                                    items: deptosDisponibles,
                                    icon: Icons.map_rounded,
                                    accentColor: isDark ? AppColors.cyanWater : AppColors.cyanWaterTextLight,
                                    onChanged: _onDepartmentChanged,
                                  ),
                                  const SizedBox(height: 10),
                                  GlassLocationDropdown(
                                    label: 'CIUDAD / MUNICIPIO',
                                    value: _selectedCity,
                                    items: ciudadesDisponibles,
                                    icon: Icons.location_city_rounded,
                                    accentColor: isDark ? AppColors.cyanWater : AppColors.cyanWaterTextLight,
                                    onChanged: _onCityChanged,
                                  ),
                                ],
                              );
                            }
                            return Row(
                              children: [
                                Expanded(
                                  child: GlassLocationDropdown(
                                    label: 'DEPARTAMENTO / ESTADO',
                                    value: _selectedDepartment,
                                    items: deptosDisponibles,
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
                                    items: ciudadesDisponibles,
                                    icon: Icons.location_city_rounded,
                                    accentColor: isDark ? AppColors.cyanWater : AppColors.cyanWaterTextLight,
                                    onChanged: _onCityChanged,
                                  ),
                                ),
                              ],
                            );
                          },
                        ),
                        const SizedBox(height: 10),

                        // Chip resumen de ubicación geográfica
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                          decoration: BoxDecoration(
                            color: isDark ? Colors.white.withValues(alpha: 0.04) : Colors.black.withValues(alpha: 0.03),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: isDark
                                  ? AppColors.cyanWater.withValues(alpha: 0.25)
                                  : AppColors.cyanWater.withValues(alpha: 0.35),
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.pin_drop_rounded,
                                size: 14,
                                color: isDark ? AppColors.cyanWater : AppColors.cyanWaterTextLight,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  '$_selectedCountry / $_selectedDepartment / $_selectedCity',
                                  style: TextStyle(
                                    color: isDark ? Colors.white70 : AppColors.textPrimaryLight,
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.w600,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 18),

                        // 3. Contacto y Comunicación
                        Row(
                          children: [
                            const Icon(Icons.contact_phone_rounded, color: AppColors.greenBiomass, size: 18),
                            const SizedBox(width: 8),
                            Text(
                              'DATOS DE CONTACTO',
                              style: AppTypography.labelMicro.copyWith(
                                color: isDark ? AppColors.greenBiomass : AppColors.greenBiomassTextLight,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0.8,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),

                        GlassFormField(
                          label: 'NOMBRE DEL CONTACTO O ASESOR',
                          hint: 'Ej. Ing. Carlos Mendoza',
                          controller: _contactoNombreCtrl,
                          prefixIcon: Icons.person_rounded,
                        ),
                        const SizedBox(height: 10),

                        Row(
                          children: [
                            Expanded(
                              child: GlassFormField(
                                label: 'TELÉFONO / WHATSAPP',
                                hint: 'Ej. +57 310 123 4567',
                                controller: _telefonoCtrl,
                                keyboardType: TextInputType.phone,
                                prefixIcon: Icons.phone_rounded,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: GlassFormField(
                                label: 'CORREO ELECTRÓNICO',
                                hint: 'Ej. ventas@empresa.com',
                                controller: _emailCtrl,
                                keyboardType: TextInputType.emailAddress,
                                prefixIcon: Icons.alternate_email_rounded,
                                validator: (v) {
                                  if (v != null && v.trim().isNotEmpty) {
                                    final emailRegex = RegExp(r'^[^@]+@[^@]+\.[^@]+$');
                                    if (!emailRegex.hasMatch(v.trim())) {
                                      return 'Formato de correo inválido';
                                    }
                                  }
                                  return null;
                                },
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),

                        GlassFormField(
                          label: 'DIRECCIÓN FÍSICA U OFICINA',
                          hint: 'Ej. Km 4 Vía San Jerónimo, Bodega 3',
                          controller: _direccionCtrl,
                          prefixIcon: Icons.home_work_rounded,
                        ),
                        const SizedBox(height: 18),

                        // 4. Categorías de Suministro (Multi-Selección)
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.category_rounded, color: AppColors.amberWarning, size: 18),
                                const SizedBox(width: 8),
                                Text(
                                  'CATEGORÍAS DE SUMINISTRO *',
                                  style: AppTypography.labelMicro.copyWith(
                                    color: isDark ? AppColors.amberWarning : AppColors.amberWarningTextLight,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: 0.8,
                                  ),
                                ),
                              ],
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: AppColors.amberWarning.withValues(alpha: isDark ? 0.16 : 0.12),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                '${_categoriasSeleccionadas.length} seleccionada${_categoriasSeleccionadas.length == 1 ? '' : 's'}',
                                style: TextStyle(
                                  color: isDark ? AppColors.amberWarning : AppColors.amberWarningTextLight,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Selecciona todas las categorías que apliquen para este proveedor.',
                          style: TextStyle(
                            color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                            fontSize: 11,
                          ),
                        ),
                        const SizedBox(height: 10),

                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: _catalogoCategorias.map((item) {
                            final key = item['key'] as String;
                            final label = item['label'] as String;
                            final icon = item['icon'] as IconData;
                            final isSelected = _categoriasSeleccionadas.contains(key);

                            return InkWell(
                              onTap: () => _toggleCategoria(key),
                              borderRadius: BorderRadius.circular(12),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 150),
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? AppColors.amberWarning.withValues(alpha: isDark ? 0.22 : 0.18)
                                      : (isDark
                                          ? Colors.white.withValues(alpha: 0.04)
                                          : Colors.black.withValues(alpha: 0.03)),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: isSelected
                                        ? AppColors.amberWarning
                                        : (isDark
                                            ? Colors.white.withValues(alpha: 0.1)
                                            : AppColors.glassBorderLight),
                                    width: isSelected ? 1.5 : 1.0,
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      isSelected ? Icons.check_circle_rounded : icon,
                                      size: 16,
                                      color: isSelected
                                          ? AppColors.amberWarning
                                          : (isDark
                                              ? AppColors.textSecondaryDark
                                              : AppColors.textSecondaryLight),
                                    ),
                                    const SizedBox(width: 8),
                                    Flexible(
                                      child: Text(
                                        label,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                          color: isSelected
                                              ? (isDark ? Colors.white : AppColors.amberWarningTextLight)
                                              : (isDark
                                                  ? AppColors.textSecondaryDark
                                                  : AppColors.textSecondaryLight),
                                          fontSize: 12,
                                          fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                        const SizedBox(height: 16),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 14),

                // ─── Botones de Acción ─────────────────────────────────────
                Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          minimumSize: const Size(double.infinity, 48),
                          foregroundColor: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                          side: BorderSide(
                            color: isDark ? Colors.white.withValues(alpha: 0.2) : Colors.black.withValues(alpha: 0.15),
                          ),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        ),
                        onPressed: () => Navigator.of(context).pop(),
                        child: const Text('Cancelar'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 3,
                      child: GlassButton(
                        label: 'Guardar Proveedor',
                        icon: const Icon(Icons.save_rounded, size: 18),
                        backgroundColor: AppColors.amberWarning,
                        isLoading: _isSaving,
                        onPressed: _guardarProveedor,
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
