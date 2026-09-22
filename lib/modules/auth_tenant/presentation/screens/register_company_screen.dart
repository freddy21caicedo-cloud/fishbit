import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:fishbit_finance/core/design_system/app_colors.dart';
import 'package:fishbit_finance/core/design_system/app_typography.dart';
import 'package:fishbit_finance/core/design_system/glass_container.dart';
import 'package:fishbit_finance/core/design_system/glass_form_field.dart';
import 'package:fishbit_finance/core/design_system/glass_button.dart';
import 'package:fishbit_finance/core/design_system/widgets/glass_location_picker_sheet.dart';
import 'package:fishbit_finance/core/services/geographic_service.dart';
import 'package:fishbit_finance/modules/auth_tenant/presentation/providers/auth_provider.dart';

class RegisterCompanyScreen extends ConsumerStatefulWidget {
  const RegisterCompanyScreen({super.key});

  @override
  ConsumerState<RegisterCompanyScreen> createState() => _RegisterCompanyScreenState();
}

class _RegisterCompanyScreenState extends ConsumerState<RegisterCompanyScreen> {
  final _pageController = PageController();
  int _currentStep = 0;

  // Paso 1: Admin Controllers
  final _adminFormKey = GlobalKey<FormState>();
  final _nombresCtrl = TextEditingController();
  final _apellidosCtrl = TextEditingController();
  final _cedulaCtrl = TextEditingController();
  final _contactoCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _confirmPasswordCtrl = TextEditingController();
  bool _obscurePass = true;
  bool _obscureConfirmPass = true;

  // Paso 2: Empresa Controllers
  final _companyFormKey = GlobalKey<FormState>();
  final _companyNombreCtrl = TextEditingController();
  final _companyNitCtrl = TextEditingController();
  final _companyEmailCtrl = TextEditingController();
  final _companyIcaCtrl = TextEditingController();
  final _companyAunapCtrl = TextEditingController();

  // Selector Geográfico en Cascada
  String _selectedCountry = GeographicService.defaultCountry;
  String _selectedState = 'Antioquia';
  String _selectedCity = 'San Jerónimo';

  String get _formattedUbicacion => '$_selectedCity, $_selectedState, $_selectedCountry';

  Future<void> _pickCountry() async {
    final picked = await GlassLocationPickerSheet.show(
      context,
      title: 'Selecciona el País',
      subtitle: 'Elige el país de la empresa piscícola',
      items: GeographicService.countries,
      selectedItem: _selectedCountry,
      prefixIcon: Icons.public_rounded,
      searchHint: 'Buscar país...',
    );

    if (picked != null && picked != _selectedCountry) {
      setState(() {
        _selectedCountry = picked;
        final states = GeographicService.getStatesForCountry(_selectedCountry);
        _selectedState = states.isNotEmpty ? states.first : 'Principal';
        final cities = GeographicService.getCitiesForState(_selectedCountry, _selectedState);
        _selectedCity = cities.isNotEmpty ? cities.first : 'Principal';
      });
    }
  }

  Future<void> _pickState() async {
    final states = GeographicService.getStatesForCountry(_selectedCountry);
    final picked = await GlassLocationPickerSheet.show(
      context,
      title: 'Selecciona Departamento / Estado',
      subtitle: 'Región de $_selectedCountry',
      items: states,
      selectedItem: _selectedState,
      prefixIcon: Icons.map_rounded,
      searchHint: 'Buscar departamento o estado...',
    );

    if (picked != null && picked != _selectedState) {
      setState(() {
        _selectedState = picked;
        final cities = GeographicService.getCitiesForState(_selectedCountry, _selectedState);
        _selectedCity = cities.isNotEmpty ? cities.first : 'Principal';
      });
    }
  }

  Future<void> _pickCity() async {
    final cities = GeographicService.getCitiesForState(_selectedCountry, _selectedState);
    final picked = await GlassLocationPickerSheet.show(
      context,
      title: 'Selecciona Ciudad o Municipio',
      subtitle: 'En $_selectedState, $_selectedCountry',
      items: cities,
      selectedItem: _selectedCity,
      prefixIcon: Icons.location_city_rounded,
      searchHint: 'Buscar municipio o ciudad...',
    );

    if (picked != null && picked != _selectedCity) {
      setState(() {
        _selectedCity = picked;
      });
    }
  }

  Widget _buildLocationSelectTile({
    required String label,
    required String value,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        constraints: const BoxConstraints(minHeight: 52),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withValues(alpha: 0.16)),
        ),
        child: Row(
          children: [
            Icon(icon, color: AppColors.greenBiomass, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    label,
                    style: const TextStyle(
                      color: AppColors.greenBiomass,
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.6,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    value,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 13.5,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.arrow_drop_down_rounded, color: AppColors.greenBiomass, size: 24),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    _nombresCtrl.dispose();
    _apellidosCtrl.dispose();
    _cedulaCtrl.dispose();
    _contactoCtrl.dispose();
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    _confirmPasswordCtrl.dispose();
    _companyNombreCtrl.dispose();
    _companyNitCtrl.dispose();
    _companyEmailCtrl.dispose();
    _companyIcaCtrl.dispose();
    _companyAunapCtrl.dispose();
    super.dispose();
  }

  void _nextStep() {
    if (_adminFormKey.currentState != null && !_adminFormKey.currentState!.validate()) {
      return;
    }
    setState(() => _currentStep = 1);
    _pageController.animateToPage(
      1,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  void _prevStep() {
    setState(() => _currentStep = 0);
    _pageController.animateToPage(
      0,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  Future<void> _handleCompleteRegistration() async {
    if (_companyFormKey.currentState != null && !_companyFormKey.currentState!.validate()) {
      return;
    }

    final success = await ref.read(authProvider.notifier).registerCompanyWithAdmin(
          adminNombres: _nombresCtrl.text,
          adminApellidos: _apellidosCtrl.text,
          adminCedulaNit: _cedulaCtrl.text,
          adminContacto: _contactoCtrl.text,
          adminEmail: _emailCtrl.text,
          adminPassword: _passwordCtrl.text,
          companyNombre: _companyNombreCtrl.text,
          companyUbicacion: _formattedUbicacion,
          companyNit: _companyNitCtrl.text,
          companyEmail: _companyEmailCtrl.text.isNotEmpty ? _companyEmailCtrl.text : _emailCtrl.text,
          companyRegistroIca: _companyIcaCtrl.text,
          companyRegistroAunap: _companyAunapCtrl.text,
        );

    if (success && mounted) {
      context.go('/');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('¡Bienvenido a FishBit, ${_nombresCtrl.text}! Piscícola creada con éxito.'),
          backgroundColor: AppColors.greenBiomass,
        ),
      );
    } else if (mounted) {
      final err = ref.read(authProvider).errorMessage ?? 'Error al registrar la empresa';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(err), backgroundColor: Colors.redAccent),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);

    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      body: Stack(
        children: [
          // Orbes de luz ambiental de fondo (Apple Aura Effect)
          Positioned(
            top: -60,
            left: -60,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.cyanWater.withValues(alpha: 0.18),
              ),
            ),
          ),
          Positioned(
            bottom: -80,
            right: -80,
            child: Container(
              width: 320,
              height: 320,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.coralAction.withValues(alpha: 0.15),
              ),
            ),
          ),

          Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 30),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 520),
                child: GlassContainer(
                  borderRadius: 28,
                  padding: const EdgeInsets.all(28),
                  blur: 24,
                  opacity: 0.12,
                  borderColor: Colors.white.withValues(alpha: 0.16),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Encabezado con Logo y Botón Volver
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.arrow_back_rounded, color: AppColors.textSecondaryDark),
                            tooltip: 'Volver al Login',
                            onPressed: () => context.go('/login'),
                          ),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                'Fish',
                                style: TextStyle(
                                  fontSize: 26,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: -1.0,
                                  color: AppColors.cyanWater,
                                  shadows: [
                                    Shadow(color: AppColors.cyanWater.withValues(alpha: 0.6), blurRadius: 16),
                                  ],
                                ),
                              ),
                              Text(
                                'Bit.',
                                style: TextStyle(
                                  fontSize: 26,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: -1.0,
                                  color: AppColors.coralAction,
                                  shadows: [
                                    Shadow(color: AppColors.coralAction.withValues(alpha: 0.6), blurRadius: 16),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(width: 48), // Balance visual con el IconButton
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'REGISTRO DE NUEVA EMPRESA PISCÍCOLA',
                        textAlign: TextAlign.center,
                        style: AppTypography.labelMicro.copyWith(
                          color: AppColors.textSecondaryDark,
                          letterSpacing: 1.2,
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Barra de Progreso del Wizard
                      _buildWizardProgressBar(),
                      const SizedBox(height: 24),

                      // Contenido de los Pasos
                      SizedBox(
                        height: 560,
                        child: PageView(
                          controller: _pageController,
                          physics: const NeverScrollableScrollPhysics(),
                          children: [
                            _buildStep1AdminForm(),
                            _buildStep2CompanyForm(authState.isLoading),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWizardProgressBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Row(
        children: [
          _buildStepIndicator(
            stepNumber: 1,
            title: 'Administrador',
            isActive: _currentStep == 0,
            isCompleted: _currentStep > 0,
            activeColor: AppColors.cyanWater,
          ),
          const Expanded(
            child: Divider(
              color: Colors.white24,
              thickness: 1,
              indent: 12,
              endIndent: 12,
            ),
          ),
          _buildStepIndicator(
            stepNumber: 2,
            title: 'Empresa',
            isActive: _currentStep == 1,
            isCompleted: false,
            activeColor: AppColors.greenBiomass,
          ),
        ],
      ),
    );
  }

  Widget _buildStepIndicator({
    required int stepNumber,
    required String title,
    required bool isActive,
    required bool isCompleted,
    required Color activeColor,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isCompleted
                ? AppColors.greenBiomass
                : (isActive ? activeColor : Colors.white.withValues(alpha: 0.08)),
            border: Border.all(
              color: isActive || isCompleted ? activeColor : Colors.white.withValues(alpha: 0.2),
              width: 1.5,
            ),
          ),
          child: Center(
            child: isCompleted
                ? const Icon(Icons.check_rounded, color: Colors.black, size: 16)
                : Text(
                    '$stepNumber',
                    style: TextStyle(
                      color: isActive ? Colors.black : Colors.white70,
                      fontWeight: FontWeight.w800,
                      fontSize: 12,
                    ),
                  ),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          title,
          style: TextStyle(
            color: isActive ? Colors.white : AppColors.textSecondaryDark,
            fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
            fontSize: 13,
          ),
        ),
      ],
    );
  }

  Widget _buildStep1AdminForm() {
    return Form(
      key: _adminFormKey,
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('👤 Paso 1: Datos del Administrador Maestro', style: AppTypography.titleMedium.copyWith(color: AppColors.cyanWater)),
            const SizedBox(height: 14),

            Row(
              children: [
                Expanded(
                  child: GlassFormField(
                    label: 'NOMBRE(S)',
                    hint: 'Freddy',
                    controller: _nombresCtrl,
                    prefixIcon: Icons.person_outline_rounded,
                    textCapitalization: TextCapitalization.words,
                    textInputAction: TextInputAction.next,
                    isRequired: true,
                    showClearButton: true,
                    accentColor: AppColors.cyanWater,
                    validator: (v) => v == null || v.trim().isEmpty ? 'Requerido' : null,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: GlassFormField(
                    label: 'APELLIDO(S)',
                    hint: 'Rojas',
                    controller: _apellidosCtrl,
                    prefixIcon: Icons.badge_outlined,
                    textCapitalization: TextCapitalization.words,
                    textInputAction: TextInputAction.next,
                    isRequired: true,
                    showClearButton: true,
                    accentColor: AppColors.cyanWater,
                    validator: (v) => v == null || v.trim().isEmpty ? 'Requerido' : null,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            Row(
              children: [
                Expanded(
                  child: GlassFormField(
                    label: 'CÉDULA / ID',
                    hint: '1098765432',
                    controller: _cedulaCtrl,
                    keyboardType: TextInputType.number,
                    textInputAction: TextInputAction.next,
                    prefixIcon: Icons.credit_card_rounded,
                    isRequired: true,
                    showClearButton: true,
                    accentColor: AppColors.cyanWater,
                    validator: (v) => v == null || v.trim().isEmpty ? 'Requerido' : null,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: GlassFormField(
                    label: 'CONTACTO / CELULAR',
                    hint: '300 123 4567',
                    controller: _contactoCtrl,
                    keyboardType: TextInputType.phone,
                    textInputAction: TextInputAction.next,
                    prefixIcon: Icons.phone_outlined,
                    isRequired: true,
                    showClearButton: true,
                    accentColor: AppColors.cyanWater,
                    validator: (v) => v == null || v.trim().isEmpty ? 'Requerido' : null,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            GlassFormField(
              label: 'CORREO ELECTRÓNICO (USUARIO MASTER)',
              hint: 'admin@piscicola.com',
              controller: _emailCtrl,
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.next,
              prefixIcon: Icons.alternate_email_rounded,
              isRequired: true,
              showClearButton: true,
              accentColor: AppColors.cyanWater,
              validator: (v) {
                if (v == null || v.trim().isEmpty) return 'El correo es requerido';
                if (!v.contains('@') || !v.contains('.')) return 'Ingresa un correo electrónico válido';
                return null;
              },
            ),
            const SizedBox(height: 12),

            Row(
              children: [
                Expanded(
                  child: GlassFormField(
                    label: 'CONTRASEÑA',
                    hint: 'Mínimo 6 caracteres',
                    controller: _passwordCtrl,
                    obscureText: _obscurePass,
                    textInputAction: TextInputAction.next,
                    prefixIcon: Icons.lock_outline_rounded,
                    isRequired: true,
                    accentColor: AppColors.cyanWater,
                    suffixWidget: IconButton(
                      icon: Icon(
                        _obscurePass ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                        color: AppColors.textSecondaryDark,
                        size: 18,
                      ),
                      onPressed: () => setState(() => _obscurePass = !_obscurePass),
                    ),
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) return 'Contraseña requerida';
                      if (v.trim().length < 6) return 'Mínimo 6 caracteres';
                      return null;
                    },
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: GlassFormField(
                    label: 'CONFIRMAR CLAVE',
                    hint: 'Repetir clave',
                    controller: _confirmPasswordCtrl,
                    obscureText: _obscureConfirmPass,
                    textInputAction: TextInputAction.done,
                    prefixIcon: Icons.lock_reset_rounded,
                    isRequired: true,
                    accentColor: AppColors.cyanWater,
                    suffixWidget: IconButton(
                      icon: Icon(
                        _obscureConfirmPass ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                        color: AppColors.textSecondaryDark,
                        size: 18,
                      ),
                      onPressed: () => setState(() => _obscureConfirmPass = !_obscureConfirmPass),
                    ),
                    validator: (v) {
                      if (v != _passwordCtrl.text) return 'Las contraseñas no coinciden';
                      return null;
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            GlassButton(
              label: 'Continuar a Datos de Empresa ➔',
              backgroundColor: AppColors.cyanWater,
              onPressed: _nextStep,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStep2CompanyForm(bool isLoading) {
    return Form(
      key: _companyFormKey,
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('🏭 Paso 2: Datos de la Empresa Piscícola', style: AppTypography.titleMedium.copyWith(color: AppColors.greenBiomass)),
            const SizedBox(height: 14),

            GlassFormField(
              label: 'NOMBRE DE LA EMPRESA / PISCÍCOLA',
              hint: 'Ej: Piscícola Del Caribe S.A.S.',
              controller: _companyNombreCtrl,
              prefixIcon: Icons.water_drop_outlined,
              textCapitalization: TextCapitalization.words,
              textInputAction: TextInputAction.next,
              isRequired: true,
              showClearButton: true,
              accentColor: AppColors.greenBiomass,
              validator: (v) => v == null || v.trim().isEmpty ? 'Nombre de empresa requerido' : null,
            ),
            const SizedBox(height: 14),

            // Ubicación en Cascada Estructurada
            Row(
              children: [
                const Icon(Icons.share_location_rounded, color: AppColors.greenBiomass, size: 18),
                const SizedBox(width: 8),
                Text(
                  'UBICACIÓN GEOGRÁFICA (EN CASCADA)',
                  style: AppTypography.labelMicro.copyWith(color: AppColors.greenBiomass, letterSpacing: 1.1),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // Selector 1: País
            _buildLocationSelectTile(
              label: 'PAÍS',
              value: _selectedCountry,
              icon: Icons.public_rounded,
              onTap: _pickCountry,
            ),
            const SizedBox(height: 10),

            // Selector 2: Departamento / Estado
            _buildLocationSelectTile(
              label: 'DEPARTAMENTO / ESTADO',
              value: _selectedState,
              icon: Icons.map_rounded,
              onTap: _pickState,
            ),
            const SizedBox(height: 10),

            // Selector 3: Ciudad / Municipio
            _buildLocationSelectTile(
              label: 'CIUDAD / MUNICIPIO',
              value: _selectedCity,
              icon: Icons.location_city_rounded,
              onTap: _pickCity,
            ),
            const SizedBox(height: 12),

            // Chip resumen de ubicación
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.greenBiomass.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.place_rounded, color: AppColors.greenBiomass, size: 16),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Ubicación registrada: $_formattedUbicacion',
                      style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w700),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),

            Row(
              children: [
                Expanded(
                  child: GlassFormField(
                    label: 'NIT / RUT',
                    hint: '900.123.456-7',
                    controller: _companyNitCtrl,
                    prefixIcon: Icons.receipt_long_outlined,
                    textInputAction: TextInputAction.next,
                    isRequired: true,
                    showClearButton: true,
                    accentColor: AppColors.greenBiomass,
                    validator: (v) => v == null || v.trim().isEmpty ? 'NIT requerido' : null,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: GlassFormField(
                    label: 'CORREO CORPORATIVO',
                    hint: 'contacto@piscicola.com',
                    controller: _companyEmailCtrl,
                    keyboardType: TextInputType.emailAddress,
                    textInputAction: TextInputAction.next,
                    prefixIcon: Icons.mail_outline_rounded,
                    showClearButton: true,
                    accentColor: AppColors.greenBiomass,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            Row(
              children: [
                Expanded(
                  child: GlassFormField(
                    label: 'REGISTRO ICA (OPCIONAL)',
                    hint: 'Ej: ICA-2026-0045',
                    controller: _companyIcaCtrl,
                    textCapitalization: TextCapitalization.characters,
                    textInputAction: TextInputAction.next,
                    prefixIcon: Icons.verified_outlined,
                    showClearButton: true,
                    accentColor: AppColors.greenBiomass,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: GlassFormField(
                    label: 'REGISTRO AUNAP (OPCIONAL)',
                    hint: 'Ej: AUNAP-RES-0129',
                    controller: _companyAunapCtrl,
                    textCapitalization: TextCapitalization.characters,
                    textInputAction: TextInputAction.done,
                    prefixIcon: Icons.shield_outlined,
                    showClearButton: true,
                    accentColor: AppColors.greenBiomass,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            Row(
              children: [
                Expanded(
                  flex: 1,
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white,
                      side: BorderSide(color: Colors.white.withValues(alpha: 0.3)),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                    onPressed: _prevStep,
                    child: const Text('⬅ Volver', style: TextStyle(fontWeight: FontWeight.w700)),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  flex: 2,
                  child: GlassButton(
                    label: 'Finalizar y Crear Piscícola',
                    isLoading: isLoading,
                    backgroundColor: AppColors.greenBiomass,
                    onPressed: _handleCompleteRegistration,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
