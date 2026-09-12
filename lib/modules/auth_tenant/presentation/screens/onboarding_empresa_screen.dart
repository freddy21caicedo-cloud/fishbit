import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:fishbit_finance/core/design_system/app_colors.dart';
import 'package:fishbit_finance/core/design_system/app_typography.dart';
import 'package:fishbit_finance/core/design_system/glass_container.dart';
import 'package:fishbit_finance/core/design_system/glass_form_field.dart';
import 'package:fishbit_finance/core/design_system/glass_button.dart';
import 'package:fishbit_finance/modules/auth_tenant/presentation/providers/auth_provider.dart';
import 'package:fishbit_finance/modules/ponds_batches/presentation/providers/ponds_provider.dart';
import 'package:fishbit_finance/core/utils/sigla_generator.dart';

class OnboardingEmpresaScreen extends ConsumerStatefulWidget {
  const OnboardingEmpresaScreen({super.key});

  @override
  ConsumerState<OnboardingEmpresaScreen> createState() => _OnboardingEmpresaScreenState();
}

class _OnboardingEmpresaScreenState extends ConsumerState<OnboardingEmpresaScreen> {
  final _formKey = GlobalKey<FormState>();

  // Datos Administrador
  late final TextEditingController _adminNameCtrl;
  final _cedulaCtrl = TextEditingController();
  final _telefonoCtrl = TextEditingController();

  // Datos Empresa / Sede
  final _companyNameCtrl = TextEditingController();
  final _nitCtrl = TextEditingController();
  final _ubicacionCtrl = TextEditingController(text: 'Colombia');
  final _unitNameCtrl = TextEditingController();
  final _unitSiglaCtrl = TextEditingController(text: 'PRI');

  // Control para saber si el usuario editó manualmente la sede
  bool _isUnitNameManuallyEdited = false;

  // Datos Primer Estanque
  final _pondNameCtrl = TextEditingController(text: 'Estanque 01');
  final _pondCapacidadCtrl = TextEditingController(text: '300');
  String _pondTipo = 'Geomembrana';

  @override
  void initState() {
    super.initState();
    final user = ref.read(authProvider).currentUser;
    _adminNameCtrl = TextEditingController(text: user?.nombre ?? '');

    // Sincronizar automáticamente Nombre de Sede y Sigla a partir de la Empresa
    _companyNameCtrl.addListener(_onCompanyNameChanged);
    _unitNameCtrl.addListener(_onUnitNameChanged);
  }

  void _onCompanyNameChanged() {
    final compText = _companyNameCtrl.text;
    if (!_isUnitNameManuallyEdited) {
      _unitNameCtrl.text = compText;
      _unitSiglaCtrl.text = SiglaGenerator.generate(compText);
    }
  }

  void _onUnitNameChanged() {
    // Si el usuario escribe algo diferente a la empresa, marcar como manual y recalcular sigla
    if (_unitNameCtrl.text != _companyNameCtrl.text) {
      _isUnitNameManuallyEdited = _unitNameCtrl.text.trim().isNotEmpty;
    }
    _unitSiglaCtrl.text = SiglaGenerator.generate(
      _unitNameCtrl.text.trim().isNotEmpty ? _unitNameCtrl.text : _companyNameCtrl.text,
    );
  }

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
    'Pangasius',
  ];

  @override
  void dispose() {
    _adminNameCtrl.dispose();
    _cedulaCtrl.dispose();
    _telefonoCtrl.dispose();
    _companyNameCtrl.dispose();
    _nitCtrl.dispose();
    _ubicacionCtrl.dispose();
    _unitNameCtrl.dispose();
    _unitSiglaCtrl.dispose();
    _pondNameCtrl.dispose();
    _pondCapacidadCtrl.dispose();
    super.dispose();
  }

  Future<void> _handleSetup() async {
    if (!_formKey.currentState!.validate()) return;

    final capacidadParsed = double.tryParse(_pondCapacidadCtrl.text.trim()) ?? 250.0;

    final success = await ref.read(authProvider.notifier).setupCompanyForUser(
          adminNombre: _adminNameCtrl.text.trim(),
          adminCedula: _cedulaCtrl.text.trim(),
          adminTelefono: _telefonoCtrl.text.trim(),
          companyNombre: _companyNameCtrl.text.trim(),
          companyNit: _nitCtrl.text.trim(),
          companyUbicacion: _ubicacionCtrl.text.trim(),
          unitNombre: _unitNameCtrl.text.trim(),
          unitSigla: _unitSiglaCtrl.text.trim(),
          especiesHabilitadas: _selectedSpecies,
          primerEstanqueNombre: _pondNameCtrl.text.trim(),
          primerEstanqueCapacidadM3: capacidadParsed,
          primerEstanqueTipo: _pondTipo,
        );

    if (success && mounted) {
      // Recargar datos de estanques inmediatamente para el nuevo tenant
      await ref.read(pondsProvider.notifier).loadPondsAndBatches();
      if (mounted) {
        context.go('/');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('¡Bienvenido Administrador! ${_companyNameCtrl.text} y su primer estanque han sido creados con éxito.'),
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


  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final user = authState.currentUser;

    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      body: Stack(
        children: [
          // Orbes de luz ambiental
          Positioned(
            top: -60,
            left: -60,
            child: Container(
              width: 320,
              height: 320,
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
              width: 320,
              height: 320,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.greenBiomass.withValues(alpha: 0.15),
              ),
            ),
          ),

          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 520),
                  child: GlassContainer(
                    borderRadius: 28,
                    padding: const EdgeInsets.all(28),
                    blur: 24,
                    opacity: 0.14,
                    borderColor: Colors.white.withValues(alpha: 0.16),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
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
                                child: const Icon(Icons.domain_add_rounded, color: AppColors.cyanWater, size: 24),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Configura tu Empresa Piscícola',
                                      style: AppTypography.titleLarge.copyWith(color: Colors.white, fontWeight: FontWeight.w900),
                                    ),
                                    Text(
                                      'Hola ${user?.nombre ?? 'Administrador'}, crea tu tenant acuícola.',
                                      style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondaryDark),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),

                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: AppColors.cyanWater.withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: AppColors.cyanWater.withValues(alpha: 0.2)),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.admin_panel_settings_rounded, color: AppColors.cyanWater, size: 20),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    'Cuenta Google verificada: ${user?.email ?? 'Gmail'}. Asignada automáticamente como Administrador General de la Empresa.',
                                    style: AppTypography.bodySmall.copyWith(color: Colors.white70, fontSize: 12),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 24),

                          // 1. DATOS DEL ADMINISTRADOR (TOMA EL CORREO DE GOOGLE)
                          Text('1. DATOS DEL ADMINISTRADOR GENERAL', style: AppTypography.labelMicro.copyWith(color: AppColors.cyanWater, letterSpacing: 1.2)),
                          const SizedBox(height: 10),

                          // Correo de Google (Bloqueado / Solo Lectura)
                          GlassFormField(
                            label: 'CORREO ELECTRÓNICO (GOOGLE)',
                            hint: user?.email ?? 'admin@gmail.com',
                            controller: TextEditingController(text: user?.email ?? ''),
                            prefixIcon: Icons.mark_email_read_rounded,
                            suffixWidget: const Padding(
                              padding: EdgeInsets.only(right: 12),
                              child: Icon(Icons.lock_outline_rounded, color: AppColors.cyanWater, size: 18),
                            ),
                            isReadOnly: true,
                          ),
                          const SizedBox(height: 12),

                          // Nombre Completo del Admin
                          GlassFormField(
                            label: 'NOMBRE COMPLETO DEL ADMINISTRADOR',
                            hint: 'ej. Carlos Alberto Gómez',
                            controller: _adminNameCtrl,
                            prefixIcon: Icons.person_outline_rounded,
                            validator: (val) => val == null || val.trim().isEmpty ? 'Ingresa el nombre del administrador' : null,
                          ),
                          const SizedBox(height: 12),

                          // Cédula y Teléfono
                          Row(
                            children: [
                              Expanded(
                                child: GlassFormField(
                                  label: 'CÉDULA / DNI',
                                  hint: 'ej. 1020304050',
                                  controller: _cedulaCtrl,
                                  prefixIcon: Icons.badge_outlined,
                                  keyboardType: TextInputType.number,
                                  validator: (val) => val == null || val.trim().isEmpty ? 'Ingresa la cédula' : null,
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: GlassFormField(
                                  label: 'TELÉFONO / WHATSAPP',
                                  hint: 'ej. 3001234567',
                                  controller: _telefonoCtrl,
                                  prefixIcon: Icons.phone_android_rounded,
                                  keyboardType: TextInputType.phone,
                                  validator: (val) => val == null || val.trim().isEmpty ? 'Ingresa el teléfono' : null,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 24),

                          // 2. DATOS DE LA EMPRESA & PISCÍCOLA
                          Text('2. DATOS DE LA EMPRESA PISCÍCOLA', style: AppTypography.labelMicro.copyWith(color: AppColors.cyanWater, letterSpacing: 1.2)),
                          const SizedBox(height: 10),

                          GlassFormField(
                            label: 'NOMBRE O RAZÓN SOCIAL DE LA EMPRESA',
                            hint: 'ej. Piscícola San Jerónimo S.A.S.',
                            controller: _companyNameCtrl,
                            prefixIcon: Icons.business_rounded,
                            validator: (val) => val == null || val.trim().isEmpty ? 'Ingresa el nombre de la empresa' : null,
                          ),
                          const SizedBox(height: 12),

                          Row(
                            children: [
                              Expanded(
                                child: GlassFormField(
                                  label: 'NIT / RUT',
                                  hint: 'ej. 901.888.777-2',
                                  controller: _nitCtrl,
                                  prefixIcon: Icons.domain_verification_rounded,
                                  validator: (val) => val == null || val.trim().isEmpty ? 'Ingresa el NIT' : null,
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: GlassFormField(
                                  label: 'UBICACIÓN / MUNICIPIO',
                                  hint: 'ej. San Jerónimo, Antioquia',
                                  controller: _ubicacionCtrl,
                                  prefixIcon: Icons.location_on_outlined,
                                  validator: (val) => val == null || val.trim().isEmpty ? 'Ingresa la ubicación' : null,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),

                          // Sede Inicial
                          Row(
                            children: [
                              Expanded(
                                flex: 3,
                                child: GlassFormField(
                                  label: 'NOMBRE SEDE PRINCIPAL',
                                  hint: 'ej. Sede Principal',
                                  controller: _unitNameCtrl,
                                  prefixIcon: Icons.waves_rounded,
                                  validator: (val) => val == null || val.trim().isEmpty ? 'Nombre de sede' : null,
                                ),
                              ),
                              const SizedBox(width: 10),
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
                                  validator: (val) => val == null || val.trim().isEmpty ? 'Sigla' : null,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 24),

                          Text('ESPECIES ACUÍCOLAS A CULTIVAR', style: AppTypography.labelMicro.copyWith(color: AppColors.cyanWater, letterSpacing: 1.2)),
                          const SizedBox(height: 6),
                          Text('Selecciona las especies que manejará esta empresa:', style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondaryDark, fontSize: 11.5)),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: _allAvailableSpecies.map((sp) {
                              final isSelected = _selectedSpecies.contains(sp);
                              return FilterChip(
                                label: Text(sp, style: TextStyle(color: isSelected ? Colors.white : AppColors.textSecondaryDark, fontWeight: isSelected ? FontWeight.w800 : FontWeight.w500, fontSize: 12)),
                                selected: isSelected,
                                selectedColor: AppColors.cyanWater.withValues(alpha: 0.25),
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
                          const SizedBox(height: 24),

                          // 3. CONFIGURACIÓN DEL PRIMER ESTANQUE
                          Text('3. TU PRIMER ESTANQUE', style: AppTypography.labelMicro.copyWith(color: AppColors.cyanWater, letterSpacing: 1.2)),
                          const SizedBox(height: 6),
                          Text('Inicia tu inventario acuícola configurando tu primer estanque:', style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondaryDark, fontSize: 11.5)),
                          const SizedBox(height: 12),

                          // Nombre / Código del Estanque
                          GlassFormField(
                            label: 'NOMBRE O IDENTIFICADOR DEL ESTANQUE',
                            hint: 'ej. Estanque 01 (Geomembrana)',
                            controller: _pondNameCtrl,
                            prefixIcon: Icons.water_rounded,
                            validator: (val) => val == null || val.trim().isEmpty ? 'Ingresa el nombre del estanque' : null,
                          ),
                          const SizedBox(height: 12),

                          // Capacidad y Tipo de Estanque
                          Row(
                            children: [
                              Expanded(
                                flex: 3,
                                child: GlassFormField(
                                  label: 'VOLUMEN / CAPACIDAD (m³)',
                                  hint: 'ej. 300',
                                  controller: _pondCapacidadCtrl,
                                  prefixIcon: Icons.straighten_rounded,
                                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                  validator: (val) {
                                    if (val == null || val.trim().isEmpty) return 'Requerido';
                                    if (double.tryParse(val.trim()) == null) return 'Inválido';
                                    return null;
                                  },
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                flex: 3,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'TIPO DE ESTANQUE',
                                      style: AppTypography.labelMicro.copyWith(
                                        color: AppColors.cyanWater,
                                        fontWeight: FontWeight.w700,
                                        letterSpacing: 0.8,
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    Container(
                                      height: 52,
                                      padding: const EdgeInsets.symmetric(horizontal: 12),
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
                                          style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600),
                                          isExpanded: true,
                                          items: const [
                                            DropdownMenuItem(value: 'Geomembrana', child: Text('Geomembrana')),
                                            DropdownMenuItem(value: 'Tierra', child: Text('Tierra')),
                                            DropdownMenuItem(value: 'Concreto', child: Text('Concreto')),
                                            DropdownMenuItem(value: 'Raceway', child: Text('Raceway')),
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
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 24),

                          // Banner de Plan Anual
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: AppColors.purpleAnalytics.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: AppColors.purpleAnalytics.withValues(alpha: 0.3)),
                            ),
                            child: const Row(
                              children: [
                                Icon(Icons.workspace_premium_rounded, color: AppColors.purpleAnalytics, size: 22),
                                SizedBox(width: 10),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text('Plan Anual Pro: \$400.000 COP / año', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 12.5)),
                                      Text('Acceso completo a todos los módulos (Finanzas, CAPEX, Nómina, Calidad de Agua, Bodega y Ventas).', style: TextStyle(color: AppColors.textSecondaryDark, fontSize: 11)),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 24),

                          GlassButton(
                            label: 'Crear Piscícola y Activar Administrador',
                            backgroundColor: AppColors.cyanWater,
                            isLoading: authState.isLoading,
                            onPressed: _handleSetup,
                          ),

                        ],
                      ),
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
}
