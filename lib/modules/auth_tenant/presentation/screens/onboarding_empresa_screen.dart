import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:fishbit_finance/core/design_system/app_colors.dart';
import 'package:fishbit_finance/core/design_system/app_typography.dart';
import 'package:fishbit_finance/core/design_system/glass_container.dart';
import 'package:fishbit_finance/core/design_system/glass_form_field.dart';
import 'package:fishbit_finance/core/design_system/widgets/glass_location_dropdown.dart';
import 'package:fishbit_finance/core/services/geographic_service.dart';
import 'package:fishbit_finance/modules/auth_tenant/domain/models/user_member.dart';
import 'package:fishbit_finance/modules/auth_tenant/presentation/providers/auth_provider.dart';
import 'package:fishbit_finance/modules/ponds_batches/presentation/providers/ponds_provider.dart';
import 'package:fishbit_finance/core/utils/sigla_generator.dart';

/// Flujo de Configuración y Creación de Empresa y Administrador
/// Diseñado como un Wizard interactivo de 3 Pasos con Glassmorphism y
/// selector geográfico estructurado en cascada (País -> Departamento -> Ciudad).
class OnboardingEmpresaScreen extends ConsumerStatefulWidget {
  const OnboardingEmpresaScreen({super.key});

  @override
  ConsumerState<OnboardingEmpresaScreen> createState() => _OnboardingEmpresaScreenState();
}

class _OnboardingEmpresaScreenState extends ConsumerState<OnboardingEmpresaScreen> {
  final _step1FormKey = GlobalKey<FormState>();
  final _step2FormKey = GlobalKey<FormState>();
  final _step3FormKey = GlobalKey<FormState>();

  int _currentStep = 0; // 0: Administrador, 1: Empresa y Ubicación, 2: Infraestructura y Confirmación

  // ─── Paso 1: Datos Administrador ──────────────────────────────────────────
  late final TextEditingController _adminNameCtrl;
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _confirmPasswordCtrl = TextEditingController();
  final _cedulaCtrl = TextEditingController();
  final _telefonoCtrl = TextEditingController();
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  // ─── Paso 2: Datos Empresa & Ubicación en Cascada ──────────────────────────
  final _companyNameCtrl = TextEditingController();
  final _nitCtrl = TextEditingController();

  // Selector Geográfico
  String _selectedCountry = GeographicService.defaultCountry;
  String _selectedState = 'Antioquia';
  String _selectedCity = 'San Jerónimo';

  // Especies acuícolas
  final List<String> _allAvailableSpecies = [
    'Tilapia Roja',
    'Cachama Negra',
    'Bocachico',
    'Trucha Arcoíris',
    'Pangasius',
    'Camarón / Langostino',
  ];

  late final List<String> _selectedSpecies = [
    'Tilapia Roja',
    'Cachama Negra',
    'Bocachico',
  ];

  // ─── Paso 3: Infraestructura Inicial (Sede y Primer Estanque) ─────────────
  final _unitNameCtrl = TextEditingController();
  final _unitSiglaCtrl = TextEditingController(text: 'PRI');
  bool _isUnitNameManuallyEdited = false;

  final _pondNameCtrl = TextEditingController(text: 'Estanque 01');
  String _pondTipo = 'Geomembrana'; // Geomembrana, Tierra / Excavado, Concreto, Fibra de Vidrio, Raceways
  String _pondForma = 'Rectangular'; // 'Rectangular' o 'Circular'

  // Dimensiones del estanque
  final _largoCtrl = TextEditingController(text: '20');
  final _anchoCtrl = TextEditingController(text: '10');
  final _profundidadCtrl = TextEditingController(text: '1.5');
  final _diametroCtrl = TextEditingController(text: '12');

  double _calculatedM3 = 300.0;

  @override
  void initState() {
    super.initState();
    final user = ref.read(authProvider).currentUser;
    _adminNameCtrl = TextEditingController(text: user?.nombre ?? '');
    _emailCtrl.text = user?.email ?? '';

    // Sincronizar automáticamente Nombre de Sede y Sigla a partir de la Empresa
    _companyNameCtrl.addListener(_onCompanyNameChanged);
    _unitNameCtrl.addListener(_onUnitNameChanged);

    // Escuchar cambios de dimensiones para calcular volumen en tiempo real
    _largoCtrl.addListener(_recalculateVolume);
    _anchoCtrl.addListener(_recalculateVolume);
    _profundidadCtrl.addListener(_recalculateVolume);
    _diametroCtrl.addListener(_recalculateVolume);
    _recalculateVolume();
  }

  void _recalculateVolume() {
    final prof = double.tryParse(_profundidadCtrl.text.trim()) ?? 0.0;
    if (_pondForma == 'Rectangular') {
      final largo = double.tryParse(_largoCtrl.text.trim()) ?? 0.0;
      final ancho = double.tryParse(_anchoCtrl.text.trim()) ?? 0.0;
      setState(() {
        _calculatedM3 = (largo * ancho * prof);
      });
    } else {
      // Circular: pi * (d / 2)^2 * prof
      final diametro = double.tryParse(_diametroCtrl.text.trim()) ?? 0.0;
      final radio = diametro / 2.0;
      setState(() {
        _calculatedM3 = (3.141592653589793 * radio * radio * prof);
      });
    }
  }

  void _onCompanyNameChanged() {
    final compText = _companyNameCtrl.text;
    if (!_isUnitNameManuallyEdited) {
      _unitNameCtrl.text = compText;
      _unitSiglaCtrl.text = SiglaGenerator.generate(compText);
    }
  }

  void _onUnitNameChanged() {
    if (_unitNameCtrl.text != _companyNameCtrl.text) {
      _isUnitNameManuallyEdited = _unitNameCtrl.text.trim().isNotEmpty;
    }
    _unitSiglaCtrl.text = SiglaGenerator.generate(
      _unitNameCtrl.text.trim().isNotEmpty ? _unitNameCtrl.text : _companyNameCtrl.text,
    );
  }

  @override
  void dispose() {
    _adminNameCtrl.dispose();
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    _confirmPasswordCtrl.dispose();
    _cedulaCtrl.dispose();
    _telefonoCtrl.dispose();
    _companyNameCtrl.dispose();
    _nitCtrl.dispose();
    _unitNameCtrl.dispose();
    _unitSiglaCtrl.dispose();
    _pondNameCtrl.dispose();
    _largoCtrl.dispose();
    _anchoCtrl.dispose();
    _profundidadCtrl.dispose();
    _diametroCtrl.dispose();
    super.dispose();
  }

  String get _formattedUbicacion => '$_selectedCity, $_selectedState, $_selectedCountry';

  void _nextStep() {
    if (_currentStep == 0) {
      if (!_step1FormKey.currentState!.validate()) return;
    } else if (_currentStep == 1) {
      if (!_step2FormKey.currentState!.validate()) return;
      if (_selectedSpecies.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Por favor selecciona al menos una especie acuícola a cultivar.'),
            backgroundColor: AppColors.coralAction,
          ),
        );
        return;
      }
    }
    if (_currentStep < 2) {
      setState(() => _currentStep++);
    }
  }

  void _prevStep() {
    if (_currentStep > 0) {
      setState(() => _currentStep--);
    }
  }

  Future<void> _handleSetup() async {
    if (!_step3FormKey.currentState!.validate()) return;

    final user = ref.read(authProvider).currentUser;
    final isGoogleUser = user != null && user.email.isNotEmpty;

    final largo = _pondForma == 'Rectangular' ? double.tryParse(_largoCtrl.text.trim()) : null;
    final ancho = _pondForma == 'Rectangular' ? double.tryParse(_anchoCtrl.text.trim()) : null;
    final profundidad = double.tryParse(_profundidadCtrl.text.trim());

    final success = await ref.read(authProvider.notifier).setupCompanyForUser(
          adminEmail: isGoogleUser ? user.email : _emailCtrl.text.trim(),
          adminPassword: isGoogleUser ? null : _passwordCtrl.text.trim(),
          adminNombre: _adminNameCtrl.text.trim(),
          adminCedula: _cedulaCtrl.text.trim(),
          adminTelefono: _telefonoCtrl.text.trim(),
          companyNombre: _companyNameCtrl.text.trim(),
          companyNit: _nitCtrl.text.trim(),
          companyUbicacion: _formattedUbicacion,
          unitNombre: _unitNameCtrl.text.trim(),
          unitSigla: _unitSiglaCtrl.text.trim(),
          especiesHabilitadas: _selectedSpecies,
          primerEstanqueNombre: _pondNameCtrl.text.trim(),
          primerEstanqueCapacidadM3: _calculatedM3 > 0 ? _calculatedM3 : 250.0,
          primerEstanqueTipo: _pondTipo,
          largoM: largo,
          anchoM: ancho,
          profundidadM: profundidad,
        );

    if (success && mounted) {
      await ref.read(pondsProvider.notifier).loadPondsAndBatches();
      if (mounted) {
        context.go('/');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('¡Bienvenido! ${_companyNameCtrl.text} ha sido creada con éxito.'),
            backgroundColor: AppColors.greenBiomass,
          ),
        );
      }
    } else if (mounted) {
      final errorMsg = ref.read(authProvider).errorMessage ?? 'Ocurrió un error al configurar la empresa y administrador.';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.error_outline_rounded, color: Colors.white),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  errorMsg,
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
          backgroundColor: Colors.redAccent,
          duration: const Duration(seconds: 5),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  // ─── Manejadores Selectores Geográficos en Cascada (Inline Dropdown) ──────
  void _onCountryChanged(String newCountry) {
    setState(() {
      _selectedCountry = newCountry;
      final states = GeographicService.getStatesForCountry(_selectedCountry);
      _selectedState = states.isNotEmpty ? states.first : 'Principal';
      final cities = GeographicService.getCitiesForState(_selectedCountry, _selectedState);
      _selectedCity = cities.isNotEmpty ? cities.first : 'Principal';
    });
  }

  void _onStateChanged(String newState) {
    setState(() {
      _selectedState = newState;
      final cities = GeographicService.getCitiesForState(_selectedCountry, _selectedState);
      _selectedCity = cities.isNotEmpty ? cities.first : 'Principal';
    });
  }

  void _onCityChanged(String newCity) {
    setState(() {
      _selectedCity = newCity;
    });
  }


  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final user = authState.currentUser;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      body: Stack(
        children: [
          // Orbes de luz ambiental decorativos
          Positioned(
            top: -60,
            left: -60,
            child: Container(
              width: 340,
              height: 340,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.cyanWater.withValues(alpha: 0.15),
              ),
            ),
          ),
          Positioned(
            bottom: -60,
            right: -60,
            child: Container(
              width: 340,
              height: 340,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.greenBiomass.withValues(alpha: 0.15),
              ),
            ),
          ),

          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 560),
                  child: GlassContainer(
                    borderRadius: 28,
                    padding: EdgeInsets.all(screenWidth < 400 ? 18 : 26),
                    blur: 24,
                    opacity: 0.15,
                    borderColor: Colors.white.withValues(alpha: 0.16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Cabecera Principal
                        _buildHeader(user),
                        const SizedBox(height: 20),

                        // Indicador de Pasos Glassmorphic (Stepper)
                        _buildStepProgress(),
                        const SizedBox(height: 22),

                        // Contenido dinámico según el paso activo
                        if (_currentStep == 0)
                          _buildStep1Admin(user, screenWidth)
                        else if (_currentStep == 1)
                          _buildStep2CompanyAndLocation(screenWidth)
                        else
                          _buildStep3Infrastructure(screenWidth, isDark),

                        const SizedBox(height: 24),

                        // Barra de Navegación del Wizard
                        _buildBottomActions(authState.isLoading),

                        const SizedBox(height: 16),

                        // Opción para cerrar sesión y volver al login
                        Center(
                          child: TextButton.icon(
                            style: TextButton.styleFrom(
                              foregroundColor: Colors.white60,
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            ),
                            onPressed: authState.isLoading
                                ? null
                                : () async {
                                    await ref.read(authProvider.notifier).signOut();
                                    if (context.mounted) {
                                      context.go('/login');
                                    }
                                  },
                            icon: const Icon(Icons.arrow_back_rounded, size: 16, color: Colors.white60),
                            label: const Text(
                              '¿Deseas ingresar con otra cuenta? Volver al Login',
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 12.5,
                                fontWeight: FontWeight.w500,
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
        ],
      ),
    );
  }

  Widget _buildHeader(UserMember? user) {
    return Row(
      children: [
        Container(
          width: 46,
          height: 46,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AppColors.cyanWater.withValues(alpha: 0.18),
            border: Border.all(color: AppColors.cyanWater.withValues(alpha: 0.4)),
          ),
          child: const Icon(Icons.domain_add_rounded, color: AppColors.cyanWater, size: 25),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Configuración de Empresa',
                style: AppTypography.titleLarge.copyWith(color: Colors.white, fontWeight: FontWeight.w900),
              ),
              Text(
                'Paso ${_currentStep + 1} de 3 • ${_getStepTitle()}',
                style: AppTypography.bodySmall.copyWith(color: AppColors.cyanWater, fontWeight: FontWeight.w700),
              ),
            ],
          ),
        ),
        IconButton(
          tooltip: 'Cerrar sesión e ir al Login',
          icon: const Icon(Icons.logout_rounded, color: Colors.white70),
          onPressed: () async {
            await ref.read(authProvider.notifier).signOut();
            if (mounted) {
              context.go('/login');
            }
          },
        ),
      ],
    );
  }

  String _getStepTitle() {
    switch (_currentStep) {
      case 0:
        return 'Administrador General';
      case 1:
        return 'Empresa y Ubicación';
      case 2:
        return 'Infraestructura Inicial';
      default:
        return '';
    }
  }

  Widget _buildStepProgress() {
    final steps = [
      '1. Administrador',
      '2. Empresa',
      '3. Infraestructura',
    ];

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Row(
        children: List.generate(steps.length, (index) {
          final isPassed = index < _currentStep;
          final isCurrent = index == _currentStep;
          final color = isCurrent
              ? AppColors.cyanWater
              : (isPassed ? AppColors.greenBiomass : Colors.white30);

          return Expanded(
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            width: 22,
                            height: 22,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: isCurrent
                                  ? AppColors.cyanWater
                                  : (isPassed ? AppColors.greenBiomass.withValues(alpha: 0.25) : Colors.white10),
                              border: Border.all(color: color, width: 1.5),
                            ),
                            child: Center(
                              child: isPassed
                                  ? const Icon(Icons.check, size: 14, color: AppColors.backgroundDark)
                                  : Text(
                                      '${index + 1}',
                                      style: TextStyle(
                                        color: isCurrent ? AppColors.backgroundDark : Colors.white70,
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                            ),
                          ),
                          const SizedBox(width: 6),
                          Flexible(
                            child: Text(
                              steps[index],
                              style: AppTypography.bodySmall.copyWith(
                                color: isCurrent ? Colors.white : Colors.white54,
                                fontWeight: isCurrent ? FontWeight.w800 : FontWeight.w500,
                                fontSize: 11,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Container(
                        height: 3,
                        decoration: BoxDecoration(
                          color: color,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ],
                  ),
                ),
                if (index < steps.length - 1) const SizedBox(width: 8),
              ],
            ),
          );
        }),
      ),
    );
  }

  // ─── PASO 1: DATOS DEL ADMINISTRADOR ─────────────────────────────────────
  Widget _buildStep1Admin(UserMember? user, double screenWidth) {
    final isGoogleUser = user != null && user.email.isNotEmpty;

    return Form(
      key: _step1FormKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isGoogleUser ? AppColors.cyanWater.withValues(alpha: 0.08) : Colors.white.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: isGoogleUser ? AppColors.cyanWater.withValues(alpha: 0.25) : Colors.white.withValues(alpha: 0.12),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  isGoogleUser ? Icons.verified_user_rounded : Icons.person_add_alt_1_rounded,
                  color: isGoogleUser ? AppColors.cyanWater : AppColors.greenBiomass,
                  size: 20,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    isGoogleUser
                        ? 'Cuenta autenticada: ${user.email}. Asignada automáticamente como Administrador General.'
                        : 'Crea tu cuenta de Administrador General para tu empresa piscícola.',
                    style: AppTypography.bodySmall.copyWith(color: Colors.white70, fontSize: 12),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),

          Text(
            'DATOS DEL ADMINISTRADOR',
            style: AppTypography.labelMicro.copyWith(color: AppColors.cyanWater, letterSpacing: 1.1),
          ),
          const SizedBox(height: 10),

          // Correo Electrónico
          GlassFormField(
            label: 'CORREO ELECTRÓNICO',
            hint: isGoogleUser ? user.email : 'ej. admin@piscicola.com',
            controller: _emailCtrl,
            prefixIcon: isGoogleUser ? Icons.mark_email_read_rounded : Icons.alternate_email_rounded,
            keyboardType: TextInputType.emailAddress,
            isReadOnly: isGoogleUser,
            isRequired: true,
            suffixWidget: isGoogleUser
                ? const Padding(
                    padding: EdgeInsets.only(right: 12),
                    child: Icon(Icons.lock_outline_rounded, color: AppColors.cyanWater, size: 18),
                  )
                : null,
            validator: (val) {
              if (val == null || val.trim().isEmpty) return 'Ingresa el correo electrónico';
              if (!val.contains('@') || !val.contains('.')) return 'Correo inválido';
              return null;
            },
          ),
          const SizedBox(height: 14),

          // Campos de Contraseña (Solo si no viene autenticado con Google)
          if (!isGoogleUser) ...[
            if (screenWidth < 420) ...[
              GlassFormField(
                label: 'CONTRASEÑA',
                hint: 'Mínimo 6 caracteres',
                controller: _passwordCtrl,
                prefixIcon: Icons.lock_outline_rounded,
                obscureText: _obscurePassword,
                suffixWidget: IconButton(
                  icon: Icon(
                    _obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                    color: Colors.white54,
                    size: 20,
                  ),
                  onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                ),
                isRequired: true,
                validator: (val) {
                  if (val == null || val.trim().isEmpty) return 'Ingresa una contraseña';
                  if (val.trim().length < 6) return 'Mínimo 6 caracteres';
                  return null;
                },
              ),
              const SizedBox(height: 14),
              GlassFormField(
                label: 'CONFIRMAR CONTRASEÑA',
                hint: 'Repite la contraseña',
                controller: _confirmPasswordCtrl,
                prefixIcon: Icons.lock_reset_rounded,
                obscureText: _obscureConfirmPassword,
                suffixWidget: IconButton(
                  icon: Icon(
                    _obscureConfirmPassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                    color: Colors.white54,
                    size: 20,
                  ),
                  onPressed: () => setState(() => _obscureConfirmPassword = !_obscureConfirmPassword),
                ),
                isRequired: true,
                validator: (val) {
                  if (val == null || val.trim().isEmpty) return 'Confirma tu contraseña';
                  if (val.trim() != _passwordCtrl.text.trim()) return 'Las contraseñas no coinciden';
                  return null;
                },
              ),
            ] else ...[
              Row(
                children: [
                  Expanded(
                    child: GlassFormField(
                      label: 'CONTRASEÑA',
                      hint: 'Mínimo 6 caracteres',
                      controller: _passwordCtrl,
                      prefixIcon: Icons.lock_outline_rounded,
                      obscureText: _obscurePassword,
                      suffixWidget: IconButton(
                        icon: Icon(
                          _obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                          color: Colors.white54,
                          size: 20,
                        ),
                        onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                      ),
                      isRequired: true,
                      validator: (val) {
                        if (val == null || val.trim().isEmpty) return 'Ingresa una contraseña';
                        if (val.trim().length < 6) return 'Mínimo 6 caracteres';
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: GlassFormField(
                      label: 'CONFIRMAR CONTRASEÑA',
                      hint: 'Repite la contraseña',
                      controller: _confirmPasswordCtrl,
                      prefixIcon: Icons.lock_reset_rounded,
                      obscureText: _obscureConfirmPassword,
                      suffixWidget: IconButton(
                        icon: Icon(
                          _obscureConfirmPassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                          color: Colors.white54,
                          size: 20,
                        ),
                        onPressed: () => setState(() => _obscureConfirmPassword = !_obscureConfirmPassword),
                      ),
                      isRequired: true,
                      validator: (val) {
                        if (val == null || val.trim().isEmpty) return 'Confirma tu contraseña';
                        if (val.trim() != _passwordCtrl.text.trim()) return 'Las contraseñas no coinciden';
                        return null;
                      },
                    ),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 14),
          ],

          // Nombre Completo
          GlassFormField(
            label: 'NOMBRE COMPLETO DEL ADMINISTRADOR',
            hint: 'ej. Carlos Alberto Gómez',
            controller: _adminNameCtrl,
            prefixIcon: Icons.person_outline_rounded,
            isRequired: true,
            validator: (val) => val == null || val.trim().isEmpty ? 'Ingresa el nombre del administrador' : null,
          ),
          const SizedBox(height: 14),

          // Cédula y Teléfono (Diseño adaptativo)
          if (screenWidth < 420) ...[
            GlassFormField(
              label: 'CÉDULA / DNI',
              hint: 'ej. 1020304050',
              controller: _cedulaCtrl,
              prefixIcon: Icons.badge_outlined,
              keyboardType: TextInputType.number,
              isRequired: true,
              validator: (val) => val == null || val.trim().isEmpty ? 'Ingresa la cédula' : null,
            ),
            const SizedBox(height: 14),
            GlassFormField(
              label: 'TELÉFONO / WHATSAPP',
              hint: 'ej. 3001234567',
              controller: _telefonoCtrl,
              prefixIcon: Icons.phone_android_rounded,
              keyboardType: TextInputType.phone,
              isRequired: true,
              validator: (val) => val == null || val.trim().isEmpty ? 'Ingresa el teléfono' : null,
            ),
          ] else ...[
            Row(
              children: [
                Expanded(
                  child: GlassFormField(
                    label: 'CÉDULA / DNI',
                    hint: 'ej. 1020304050',
                    controller: _cedulaCtrl,
                    prefixIcon: Icons.badge_outlined,
                    keyboardType: TextInputType.number,
                    isRequired: true,
                    validator: (val) => val == null || val.trim().isEmpty ? 'Ingresa la cédula' : null,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: GlassFormField(
                    label: 'TELÉFONO / WHATSAPP',
                    hint: 'ej. 3001234567',
                    controller: _telefonoCtrl,
                    prefixIcon: Icons.phone_android_rounded,
                    keyboardType: TextInputType.phone,
                    isRequired: true,
                    validator: (val) => val == null || val.trim().isEmpty ? 'Ingresa el teléfono' : null,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  // ─── PASO 2: DATOS DE LA EMPRESA & UBICACIÓN EN CASCADA ──────────────────
  Widget _buildStep2CompanyAndLocation(double screenWidth) {
    return Form(
      key: _step2FormKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'DATOS FISCALES DE LA EMPRESA',
            style: AppTypography.labelMicro.copyWith(color: AppColors.cyanWater, letterSpacing: 1.1),
          ),
          const SizedBox(height: 10),

          GlassFormField(
            label: 'NOMBRE O RAZÓN SOCIAL DE LA EMPRESA',
            hint: 'ej. Piscícola San Jerónimo S.A.S.',
            controller: _companyNameCtrl,
            prefixIcon: Icons.business_rounded,
            isRequired: true,
            validator: (val) => val == null || val.trim().isEmpty ? 'Ingresa el nombre de la empresa' : null,
          ),
          const SizedBox(height: 14),

          GlassFormField(
            label: 'NIT / RUT',
            hint: 'ej. 901.888.777-2',
            controller: _nitCtrl,
            prefixIcon: Icons.domain_verification_rounded,
            isRequired: true,
            validator: (val) => val == null || val.trim().isEmpty ? 'Ingresa el NIT o Identificador fiscal' : null,
          ),
          const SizedBox(height: 20),

          // Ubicación en Cascada Estructurada
          Row(
            children: [
              const Icon(Icons.share_location_rounded, color: AppColors.cyanWater, size: 18),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  'UBICACIÓN GEOGRÁFICA (EN CASCADA)',
                  style: AppTypography.labelMicro.copyWith(color: AppColors.cyanWater, letterSpacing: 1.1),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'Configura el país, departamento y municipio de la operación piscícola:',
            style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondaryDark, fontSize: 11.5),
          ),
          const SizedBox(height: 12),

          // Selector 1: País (Buttonlist desplegable inline)
          GlassLocationDropdown(
            label: 'PAÍS',
            value: _selectedCountry,
            items: GeographicService.countries,
            icon: Icons.public_rounded,
            accentColor: AppColors.cyanWater,
            onChanged: _onCountryChanged,
          ),
          const SizedBox(height: 10),

          // Selector 2: Departamento / Estado (Buttonlist desplegable en cascada)
          GlassLocationDropdown(
            label: 'DEPARTAMENTO / ESTADO',
            value: _selectedState,
            items: GeographicService.getStatesForCountry(_selectedCountry),
            icon: Icons.map_rounded,
            accentColor: AppColors.cyanWater,
            onChanged: _onStateChanged,
          ),
          const SizedBox(height: 10),

          // Selector 3: Ciudad / Municipio (Buttonlist desplegable en cascada)
          GlassLocationDropdown(
            label: 'CIUDAD / MUNICIPIO',
            value: _selectedCity,
            items: GeographicService.getCitiesForState(_selectedCountry, _selectedState),
            icon: Icons.location_city_rounded,
            accentColor: AppColors.cyanWater,
            onChanged: _onCityChanged,
          ),

          const SizedBox(height: 14),

          // Chip resumen de ubicación
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.cyanWater.withValues(alpha: 0.3)),
            ),
            child: Row(
              children: [
                const Icon(Icons.place_rounded, color: AppColors.cyanWater, size: 16),
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
          const SizedBox(height: 22),

          // Especies Acuícolas a Cultivar
          Text(
            'ESPECIES ACUÍCOLAS A CULTIVAR',
            style: AppTypography.labelMicro.copyWith(color: AppColors.cyanWater, letterSpacing: 1.1),
          ),
          const SizedBox(height: 6),
          Text(
            'Selecciona las especies que manejará tu empresa:',
            style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondaryDark, fontSize: 11.5),
          ),
          const SizedBox(height: 10),

          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _allAvailableSpecies.map((sp) {
              final isSelected = _selectedSpecies.contains(sp);
              return FilterChip(
                label: Text(
                  sp,
                  style: TextStyle(
                    color: isSelected ? Colors.white : AppColors.textSecondaryDark,
                    fontWeight: isSelected ? FontWeight.w800 : FontWeight.w500,
                    fontSize: 12,
                  ),
                ),
                selected: isSelected,
                selectedColor: AppColors.cyanWater.withValues(alpha: 0.28),
                checkmarkColor: AppColors.cyanWater,
                backgroundColor: Colors.white.withValues(alpha: 0.05),
                side: BorderSide(color: isSelected ? AppColors.cyanWater : Colors.white12),
                onSelected: (val) {
                  setState(() {
                    if (val) {
                      _selectedSpecies.add(sp);
                    } else {
                      if (_selectedSpecies.length > 1) {
                        _selectedSpecies.remove(sp);
                      }
                    }
                  });
                },
              );
            }).toList(),
          ),
        ],
      ),
    );
  }


  // ─── PASO 3: INFRAESTRUCTURA INICIAL Y ACTIVACIÓN ─────────────────────────
  Widget _buildStep3Infrastructure(double screenWidth, bool isDark) {
    return Form(
      key: _step3FormKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'SEDE PRINCIPAL DE OPERACIONES',
            style: AppTypography.labelMicro.copyWith(color: AppColors.cyanWater, letterSpacing: 1.1),
          ),
          const SizedBox(height: 10),

          // Nombre de Sede y Sigla
          if (screenWidth < 420) ...[
            GlassFormField(
              label: 'NOMBRE DE LA SEDE PRINCIPAL',
              hint: 'ej. Sede Central / Piscícola San Jerónimo',
              controller: _unitNameCtrl,
              prefixIcon: Icons.waves_rounded,
              isRequired: true,
              validator: (val) => val == null || val.trim().isEmpty ? 'Ingresa el nombre de la sede' : null,
            ),
            const SizedBox(height: 12),
            GlassFormField(
              label: 'SIGLA (AUTO)',
              hint: 'PRI',
              controller: _unitSiglaCtrl,
              prefixIcon: Icons.short_text_rounded,
              suffixWidget: const Padding(
                padding: EdgeInsets.only(right: 10),
                child: Icon(Icons.lock_outline_rounded, color: AppColors.cyanWater, size: 16),
              ),
              isReadOnly: true,
              isRequired: true,
              validator: (val) => val == null || val.trim().isEmpty ? 'Sigla requerida' : null,
            ),
          ] else ...[
            Row(
              children: [
                Expanded(
                  flex: 3,
                  child: GlassFormField(
                    label: 'NOMBRE DE LA SEDE PRINCIPAL',
                    hint: 'ej. Sede Central',
                    controller: _unitNameCtrl,
                    prefixIcon: Icons.waves_rounded,
                    isRequired: true,
                    validator: (val) => val == null || val.trim().isEmpty ? 'Ingresa el nombre de la sede' : null,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: GlassFormField(
                    label: 'SIGLA (AUTO)',
                    hint: 'PRI',
                    controller: _unitSiglaCtrl,
                    prefixIcon: Icons.short_text_rounded,
                    suffixWidget: const Padding(
                      padding: EdgeInsets.only(right: 10),
                      child: Icon(Icons.lock_outline_rounded, color: AppColors.cyanWater, size: 16),
                    ),
                    isReadOnly: true,
                    isRequired: true,
                    validator: (val) => val == null || val.trim().isEmpty ? 'Sigla requerida' : null,
                  ),
                ),
              ],
            ),
          ],
          const SizedBox(height: 20),

          // Configuración del Primer Estanque
          Text(
            'CONFIGURACIÓN DEL PRIMER ESTANQUE',
            style: AppTypography.labelMicro.copyWith(color: AppColors.cyanWater, letterSpacing: 1.1),
          ),
          const SizedBox(height: 6),
          Text(
            'Inicia tu inventario acuícola creando tu primer estanque:',
            style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondaryDark, fontSize: 11.5),
          ),
          const SizedBox(height: 10),

          GlassFormField(
            label: 'NOMBRE / IDENTIFICADOR DEL ESTANQUE',
            hint: 'ej. Estanque 01',
            controller: _pondNameCtrl,
            prefixIcon: Icons.water_rounded,
            isRequired: true,
            validator: (val) => val == null || val.trim().isEmpty ? 'Ingresa el identificador del estanque' : null,
          ),
          const SizedBox(height: 14),

          // Selector de Tipo de Estanque y Selector de Forma Geométrica
          Row(
            children: [
              Expanded(
                flex: 3,
                child: _buildPondTypeDropdown(),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 3,
                child: _buildPondShapeDropdown(),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Dimensiones según Forma Geométrica
          if (_pondForma == 'Rectangular') ...[
            Row(
              children: [
                Expanded(
                  child: GlassFormField(
                    label: 'LARGO (m)',
                    hint: 'ej. 20',
                    controller: _largoCtrl,
                    prefixIcon: Icons.straighten_rounded,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    isRequired: true,
                    validator: (val) {
                      if (val == null || val.trim().isEmpty) return 'Requerido';
                      final parsed = double.tryParse(val.trim());
                      if (parsed == null || parsed <= 0) return 'Mayor a 0';
                      return null;
                    },
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: GlassFormField(
                    label: 'ANCHO (m)',
                    hint: 'ej. 10',
                    controller: _anchoCtrl,
                    prefixIcon: Icons.straighten_rounded,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    isRequired: true,
                    validator: (val) {
                      if (val == null || val.trim().isEmpty) return 'Requerido';
                      final parsed = double.tryParse(val.trim());
                      if (parsed == null || parsed <= 0) return 'Mayor a 0';
                      return null;
                    },
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: GlassFormField(
                    label: 'PROFUNDIDAD (m)',
                    hint: 'ej. 1.5',
                    controller: _profundidadCtrl,
                    prefixIcon: Icons.vertical_align_bottom_rounded,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    isRequired: true,
                    validator: (val) {
                      if (val == null || val.trim().isEmpty) return 'Requerido';
                      final parsed = double.tryParse(val.trim());
                      if (parsed == null || parsed <= 0) return 'Mayor a 0';
                      return null;
                    },
                  ),
                ),
              ],
            ),
          ] else ...[
            Row(
              children: [
                Expanded(
                  flex: 3,
                  child: GlassFormField(
                    label: 'DIÁMETRO (m)',
                    hint: 'ej. 12',
                    controller: _diametroCtrl,
                    prefixIcon: Icons.panorama_fish_eye_rounded,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    isRequired: true,
                    validator: (val) {
                      if (val == null || val.trim().isEmpty) return 'Requerido';
                      final parsed = double.tryParse(val.trim());
                      if (parsed == null || parsed <= 0) return 'Mayor a 0';
                      return null;
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 3,
                  child: GlassFormField(
                    label: 'PROFUNDIDAD (m)',
                    hint: 'ej. 1.5',
                    controller: _profundidadCtrl,
                    prefixIcon: Icons.vertical_align_bottom_rounded,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    isRequired: true,
                    validator: (val) {
                      if (val == null || val.trim().isEmpty) return 'Requerido';
                      final parsed = double.tryParse(val.trim());
                      if (parsed == null || parsed <= 0) return 'Mayor a 0';
                      return null;
                    },
                  ),
                ),
              ],
            ),
          ],
          const SizedBox(height: 14),

          // Tarjeta de Cálculo de Volumen en Tiempo Real
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppColors.cyanWater.withValues(alpha: 0.15),
                  AppColors.greenBiomass.withValues(alpha: 0.12),
                ],
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.cyanWater.withValues(alpha: 0.35)),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.cyanWater.withValues(alpha: 0.2),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.calculate_rounded, color: AppColors.cyanWater, size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'VOLUMEN CALCULADO AUTOMÁTICAMENTE',
                        style: AppTypography.labelMicro.copyWith(
                          color: AppColors.cyanWater,
                          letterSpacing: 0.8,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${_calculatedM3.toStringAsFixed(1)} m³ de agua (${(_calculatedM3 * 1000).toStringAsFixed(0)} Litros aprox.)',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14.5,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Credencial / Resumen Corporativo Previo a la Activación
          _buildCorporateSummaryCard(),
        ],
      ),
    );
  }

  Widget _buildPondShapeDropdown() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'FORMA GEOMÉTRICA',
          style: AppTypography.labelMicro.copyWith(
            color: AppColors.cyanWater,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.8,
          ),
        ),
        const SizedBox(height: 6),
        Container(
          height: 52,
          padding: const EdgeInsets.symmetric(horizontal: 14),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: _pondForma,
              dropdownColor: const Color(0xFF131F2E),
              icon: const Icon(Icons.arrow_drop_down_rounded, color: AppColors.cyanWater),
              style: const TextStyle(color: Colors.white, fontSize: 13.5, fontWeight: FontWeight.w600),
              isExpanded: true,
              items: const [
                DropdownMenuItem(value: 'Rectangular', child: Text('Rectangular (L × A × P)')),
                DropdownMenuItem(value: 'Circular', child: Text('Circular (Diámetro)')),
              ],
              onChanged: (val) {
                if (val != null) {
                  setState(() {
                    _pondForma = val;
                    _recalculateVolume();
                  });
                }
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPondTypeDropdown() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'TIPO DE ESTRUCTURA',
          style: AppTypography.labelMicro.copyWith(
            color: AppColors.cyanWater,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.8,
          ),
        ),
        const SizedBox(height: 6),
        Container(
          height: 52,
          padding: const EdgeInsets.symmetric(horizontal: 14),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: _pondTipo,
              dropdownColor: const Color(0xFF131F2E),
              icon: const Icon(Icons.arrow_drop_down_rounded, color: AppColors.cyanWater),
              style: const TextStyle(color: Colors.white, fontSize: 13.5, fontWeight: FontWeight.w600),
              isExpanded: true,
              items: const [
                DropdownMenuItem(value: 'Geomembrana', child: Text('Geomembrana')),
                DropdownMenuItem(value: 'Tierra / Excavado', child: Text('Tierra / Excavado')),
                DropdownMenuItem(value: 'Concreto', child: Text('Concreto')),
                DropdownMenuItem(value: 'Fibra de Vidrio', child: Text('Fibra de Vidrio')),
                DropdownMenuItem(value: 'Raceways', child: Text('Raceways')),
              ],
              onChanged: (val) {
                if (val != null) {
                  setState(() => _pondTipo = val);
                }
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCorporateSummaryCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cyanWater.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.cyanWater.withValues(alpha: 0.35)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.assignment_turned_in_rounded, color: AppColors.cyanWater, size: 20),
              const SizedBox(width: 8),
              Text(
                'RESUMEN DE ACTIVACIÓN FISCAL Y TÉCNICA',
                style: AppTypography.labelMicro.copyWith(color: AppColors.cyanWater, letterSpacing: 0.8),
              ),
            ],
          ),
          const Divider(height: 18, thickness: 0.5, color: Colors.white12),
          _buildSummaryRow('Empresa:', _companyNameCtrl.text.trim().isNotEmpty ? _companyNameCtrl.text.trim() : 'Sin definir'),
          _buildSummaryRow('NIT / RUT:', _nitCtrl.text.trim().isNotEmpty ? _nitCtrl.text.trim() : 'Sin definir'),
          _buildSummaryRow('Ubicación:', _formattedUbicacion),
          _buildSummaryRow('Administrador:', _adminNameCtrl.text.trim().isNotEmpty ? _adminNameCtrl.text.trim() : 'Sin definir'),
          _buildSummaryRow('Sede Inicial:', '${_unitNameCtrl.text.trim()} [${_unitSiglaCtrl.text.trim()}]'),
          _buildSummaryRow('Primer Estanque:', '${_pondNameCtrl.text.trim()} • ${_calculatedM3.toStringAsFixed(1)} m³ ($_pondTipo)'),
          _buildSummaryRow('Especies:', _selectedSpecies.join(', ')),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 105,
            child: Text(
              label,
              style: const TextStyle(color: AppColors.textSecondaryDark, fontSize: 11.5, fontWeight: FontWeight.w600),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w800),
            ),
          ),
        ],
      ),
    );
  }

  // ─── ACCIONES INFERIORES DEL WIZARD ──────────────────────────────────────
  Widget _buildBottomActions(bool isLoading) {
    return Row(
      children: [
        if (_currentStep > 0) ...[
          OutlinedButton.icon(
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.white70,
              side: const BorderSide(color: Colors.white24),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              minimumSize: const Size(0, 48), // WCAG 2.5.5
              padding: const EdgeInsets.symmetric(horizontal: 16),
            ),
            onPressed: isLoading ? null : _prevStep,
            icon: const Icon(Icons.arrow_back_rounded, size: 18),
            label: const Text('Atrás', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
          ),
          const SizedBox(width: 12),
        ],
        Expanded(
          child: ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: _currentStep == 2 ? AppColors.greenBiomass : AppColors.cyanWater,
              foregroundColor: Colors.black,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              minimumSize: const Size(0, 50), // WCAG 2.5.5
              elevation: 4,
              shadowColor: (_currentStep == 2 ? AppColors.greenBiomass : AppColors.cyanWater).withValues(alpha: 0.4),
              padding: const EdgeInsets.symmetric(horizontal: 18),
            ),
            onPressed: isLoading
                ? null
                : () {
                    if (_currentStep < 2) {
                      _nextStep();
                    } else {
                      _handleSetup();
                    }
                  },
            icon: isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2.2, color: Colors.black),
                  )
                : Icon(
                    _currentStep == 2 ? Icons.check_circle_rounded : Icons.arrow_forward_rounded,
                    size: 19,
                  ),
            label: Text(
              isLoading
                  ? 'Configurando...'
                  : (_currentStep == 2
                      ? 'Crear Piscícola y Activar'
                      : 'Continuar a ${_currentStep == 0 ? "Empresa" : "Infraestructura"}'),
              style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 13.5),
            ),
          ),
        ),
      ],
    );
  }
}
