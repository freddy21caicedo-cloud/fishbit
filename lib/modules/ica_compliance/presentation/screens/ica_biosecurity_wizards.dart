import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fishbit_finance/core/design_system/app_colors.dart';
import 'package:fishbit_finance/core/design_system/app_typography.dart';
import 'package:fishbit_finance/core/design_system/glass_container.dart';
import 'package:fishbit_finance/core/design_system/glass_form_field.dart';
import 'package:fishbit_finance/core/design_system/glass_date_picker.dart';
import 'package:fishbit_finance/modules/auth_tenant/presentation/providers/auth_provider.dart';
import 'package:fishbit_finance/modules/ponds_batches/presentation/providers/ponds_provider.dart';
import 'package:fishbit_finance/modules/ica_compliance/domain/models/ica_personal_record.dart';
import 'package:fishbit_finance/modules/ica_compliance/domain/models/ica_vehiculo_record.dart';
import 'package:fishbit_finance/modules/ica_compliance/domain/models/ica_necropsia_record.dart';
import 'package:fishbit_finance/modules/ica_compliance/presentation/providers/ica_compliance_provider.dart';
import 'package:fishbit_finance/modules/ica_compliance/presentation/widgets/ica_step_wizard_scaffold.dart';

// ============================================================================
// 1. ASISTENTE PASO A PASO: INGRESO DE PERSONAL Y VISITAS (F-01 WIZARD)
// ============================================================================
class IngresoPersonalWizardScreen extends ConsumerStatefulWidget {
  const IngresoPersonalWizardScreen({super.key});

  static Future<void> open(BuildContext context) {
    return Navigator.of(context, rootNavigator: true).push(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => const IngresoPersonalWizardScreen(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
      ),
    );
  }

  @override
  ConsumerState<IngresoPersonalWizardScreen> createState() => _IngresoPersonalWizardScreenState();
}

class _IngresoPersonalWizardScreenState extends ConsumerState<IngresoPersonalWizardScreen> {
  int _currentStep = 0;
  final _formKey1 = GlobalKey<FormState>();
  final _nombreCtrl = TextEditingController();
  final _docCtrl = TextEditingController();
  final _telCtrl = TextEditingController();
  final _entidadCtrl = TextEditingController();
  final _motivoCtrl = TextEditingController();
  final _detalleOtrasCtrl = TextEditingController();
  final _horaIngresoCtrl = TextEditingController(text: '08:00');
  final _horaSalidaCtrl = TextEditingController(text: '17:00');

  TipoPersonaIca _tipoPersona = TipoPersonaIca.visitanteTecnico;
  CivilDate _fecha = CivilDate.today();
  bool _haVisitadoOtras = false;
  bool _presentaSintomas = false;
  bool _lavadoManos = true;
  bool _desinfeccionCalzado = true;
  bool _indumentariaLimpia = true;
  bool _isLoading = false;

  final List<String> _stepTitles = [
    'Identificación y Cargo',
    'Filtro Epidemiológico 72h',
    'Protocolo de Acceso y Firma',
  ];

  @override
  void dispose() {
    _nombreCtrl.dispose();
    _docCtrl.dispose();
    _telCtrl.dispose();
    _entidadCtrl.dispose();
    _motivoCtrl.dispose();
    _detalleOtrasCtrl.dispose();
    _horaIngresoCtrl.dispose();
    _horaSalidaCtrl.dispose();
    super.dispose();
  }

  Future<void> _guardar() async {
    setState(() => _isLoading = true);

    try {
      final auth = ref.read(authProvider);
      final empresaId = auth.currentCompany?.id ?? auth.currentUser?.empresaId ?? 'c1000000-0000-0000-0000-000000000001';
      final unidadId = auth.activeUnitId ?? auth.currentUser?.unidadAcuicolaId ?? empresaId;

      final record = IcaPersonalRecord(
        empresaId: empresaId,
        unidadAcuicolaId: unidadId,
        fecha: _fecha.toDateTime(),
        horaIngreso: _horaIngresoCtrl.text.trim(),
        horaSalida: _horaSalidaCtrl.text.trim().isNotEmpty ? _horaSalidaCtrl.text.trim() : null,
        nombreCompleto: _nombreCtrl.text.trim(),
        documentoIdentidad: _docCtrl.text.trim(),
        telefono: _telCtrl.text.trim().isNotEmpty ? _telCtrl.text.trim() : null,
        tipoPersona: _tipoPersona,
        entidadProcedencia: _entidadCtrl.text.trim().isNotEmpty ? _entidadCtrl.text.trim() : null,
        motivoVisita: _motivoCtrl.text.trim().isNotEmpty ? _motivoCtrl.text.trim() : 'Labores de predio / inspección',
        haVisitadoOtrasGranjas: _haVisitadoOtras,
        detalleOtrasGranjas: _haVisitadoOtras ? _detalleOtrasCtrl.text.trim() : null,
        presentaSintomas: _presentaSintomas,
        lavadoManos: _lavadoManos,
        desinfeccionCalzado: _desinfeccionCalzado,
        indumentariaLimpia: _indumentariaLimpia,
        autorizaIngreso: auth.currentUser?.nombre ?? 'Director Técnico',
      );

      final ok = await ref.read(icaComplianceProvider.notifier).registerPersonal(record);

      if (mounted) {
        if (ok) {
          Navigator.of(context).pop();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('✅ Registro F-01 de ingreso y bioseguridad guardado en el expediente ICA.'),
              backgroundColor: AppColors.greenBiomass,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _handleNext() {
    if (_currentStep == 0) {
      if (!_formKey1.currentState!.validate()) return;
      setState(() => _currentStep = 1);
    } else if (_currentStep == 1) {
      if (_haVisitadoOtras && _detalleOtrasCtrl.text.trim().isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Por favor indica las granjas visitadas en las últimas 72 horas.'),
            backgroundColor: AppColors.coralAction,
            behavior: SnackBarBehavior.floating,
          ),
        );
        return;
      }
      setState(() => _currentStep = 2);
    } else {
      _guardar();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return IcaStepWizardScaffold(
      title: 'Control de Ingreso (F-01)',
      subtitle: 'Registro de Personal, Visitas y Bioseguridad ICA Res. 20186',
      icon: Icons.badge_rounded,
      themeColor: AppColors.cyanWater,
      currentStep: _currentStep,
      totalSteps: 3,
      stepTitles: _stepTitles,
      nextLabel: _currentStep == 2 ? 'Finalizar y Guardar F-01' : 'Continuar al Paso ${_currentStep + 2}',
      isNextLoading: _isLoading,
      onBack: () => setState(() => _currentStep = (_currentStep - 1).clamp(0, 2)),
      onNext: _handleNext,
      child: _buildCurrentStep(isDark),
    );
  }

  Widget _buildCurrentStep(bool isDark) {
    switch (_currentStep) {
      case 0:
        return _buildStep1Identificacion(isDark);
      case 1:
        return _buildStep2Epidemiologico(isDark);
      case 2:
        return _buildStep3Bioseguridad(isDark);
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildStep1Identificacion(bool isDark) {
    return Form(
      key: _formKey1,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('FECHA Y HORARIO DE ACCESO', style: AppTypography.labelMicro.copyWith(color: AppColors.cyanWater, fontWeight: FontWeight.w900)),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                flex: 3,
                child: GlassDatePickerField(
                  label: 'FECHA DE INGRESO',
                  initialDate: _fecha,
                  onDateChanged: (d) => setState(() => _fecha = d),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                flex: 2,
                child: GlassFormField(
                  label: 'HORA INGRESO',
                  hint: '08:00',
                  controller: _horaIngresoCtrl,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                flex: 2,
                child: GlassFormField(
                  label: 'HORA SALIDA',
                  hint: '17:00',
                  controller: _horaSalidaCtrl,
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),

          Text('TIPO DE PERSONA / ROL EN PREDIO', style: AppTypography.labelMicro.copyWith(color: AppColors.cyanWater, fontWeight: FontWeight.w900)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: TipoPersonaIca.values.map((tipo) {
              final isSel = _tipoPersona == tipo;
              return ChoiceChip(
                label: Text(tipo.label),
                selected: isSel,
                onSelected: (_) => setState(() => _tipoPersona = tipo),
                selectedColor: AppColors.cyanWater.withValues(alpha: 0.25),
                side: BorderSide(color: isSel ? AppColors.cyanWater : Colors.white12),
                labelStyle: TextStyle(
                  color: isSel ? AppColors.cyanWater : (isDark ? Colors.white70 : Colors.black87),
                  fontWeight: isSel ? FontWeight.w800 : FontWeight.w500,
                  fontSize: 11,
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 18),

          Text('DATOS DEL VISITANTE / OPERARIO', style: AppTypography.labelMicro.copyWith(color: AppColors.cyanWater, fontWeight: FontWeight.w900)),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                flex: 3,
                child: GlassFormField(
                  label: 'NOMBRE COMPLETO *',
                  hint: 'Ej: Carlos Arturo Mendoza',
                  controller: _nombreCtrl,
                  validator: (v) => (v == null || v.trim().isEmpty) ? 'Requerido para control ICA' : null,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                flex: 2,
                child: GlassFormField(
                  label: 'DOCUMENTO (C.C.) *',
                  hint: 'Ej: 1098455123',
                  controller: _docCtrl,
                  validator: (v) => (v == null || v.trim().isEmpty) ? 'Requerido' : null,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: GlassFormField(
                  label: 'ENTIDAD / PROCEDENCIA',
                  hint: 'Ej: Agrosavia / Universidad / Particular',
                  controller: _entidadCtrl,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: GlassFormField(
                  label: 'TELÉFONO DE CONTACTO',
                  hint: 'Ej: 310 123 4567',
                  controller: _telCtrl,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          GlassFormField(
            label: 'MOTIVO ESPECÍFICO DE LA VISITA',
            hint: 'Ej: Auditoría sanitaria, muestreo de agua o mantenimiento',
            controller: _motivoCtrl,
          ),
        ],
      ),
    );
  }

  Widget _buildStep2Epidemiologico(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('FILTRO EPIDEMIOLÓGICO Y VACÍO SANITARIO', style: AppTypography.labelMicro.copyWith(color: AppColors.cyanWater, fontWeight: FontWeight.w900)),
        const SizedBox(height: 8),
        Text(
          'El ICA exige verificar que los visitantes no provengan de zonas o predios acuícolas con alertas sanitarias en las últimas 72 horas para prevenir contagio cruzado (TiLV, bacterias o parásitos).',
          style: TextStyle(color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight, fontSize: 12, height: 1.4),
        ),
        const SizedBox(height: 16),

        // Pregunta 1: Visita a otras granjas
        _buildQuestionCard(
          title: '¿Ha visitado otras granjas acuícolas en las últimas 72 horas?',
          description: 'Requisito de vacío sanitario bioseguro ICA.',
          value: _haVisitadoOtras,
          activeColor: AppColors.coralAction,
          onChanged: (val) => setState(() => _haVisitadoOtras = val),
          isDark: isDark,
        ),

        if (_haVisitadoOtras) ...[
          const SizedBox(height: 12),
          GlassFormField(
            label: 'MUNICIPIO Y PREDIO VISITADO PREVIAMENTE *',
            hint: 'Ej: Piscícola El Porvenir - Garzón, Huila',
            controller: _detalleOtrasCtrl,
          ),
        ],

        const SizedBox(height: 16),

        // Pregunta 2: Síntomas de salud
        _buildQuestionCard(
          title: '¿Presenta síntomas respiratorios, dérmicos o gastrointestinales?',
          description: 'Protección de inocuidad en manipulación de peces y alimentos.',
          value: _presentaSintomas,
          activeColor: AppColors.coralAction,
          onChanged: (val) => setState(() => _presentaSintomas = val),
          isDark: isDark,
        ),
      ],
    );
  }

  Widget _buildStep3Bioseguridad(bool isDark) {
    final auth = ref.watch(authProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('PROTOCOLO SANITARIO EN PUNTO DE ACCESO', style: AppTypography.labelMicro.copyWith(color: AppColors.cyanWater, fontWeight: FontWeight.w900)),
        const SizedBox(height: 12),

        _buildCheckRow('Desinfección obligatoria de calzado en pediluvio', _desinfeccionCalzado, (v) => setState(() => _desinfeccionCalzado = v), isDark),
        _buildCheckRow('Lavado y desinfección de manos con jabón antibacterial', _lavadoManos, (v) => setState(() => _lavadoManos = v), isDark),
        _buildCheckRow('Uso de indumentaria limpia / botas exclusivas del predio', _indumentariaLimpia, (v) => setState(() => _indumentariaLimpia = v), isDark),

        const SizedBox(height: 20),

        // Tarjeta Resumen Final
        GlassContainer(
          borderRadius: 18,
          padding: const EdgeInsets.all(16),
          blur: 16,
          opacity: isDark ? 0.08 : 0.4,
          borderColor: AppColors.cyanWater.withValues(alpha: 0.3),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.verified_user_rounded, color: AppColors.greenBiomass, size: 20),
                  const SizedBox(width: 8),
                  Text('RESUMEN DE AUTORIZACIÓN', style: AppTypography.labelMicro.copyWith(color: AppColors.greenBiomass, fontWeight: FontWeight.w900)),
                ],
              ),
              const Divider(height: 16),
              _buildSummaryRow('Visitante:', _nombreCtrl.text.isEmpty ? 'Sin especificar' : _nombreCtrl.text),
              _buildSummaryRow('Documento:', _docCtrl.text.isEmpty ? 'Sin especificar' : _docCtrl.text),
              _buildSummaryRow('Tipo de Persona:', _tipoPersona.label),
              _buildSummaryRow('Fecha / Hora:', '${_fecha.toString().split(' ').first} (${_horaIngresoCtrl.text} - ${_horaSalidaCtrl.text})'),
              _buildSummaryRow('Autorizado Por:', auth.currentUser?.nombre ?? 'Director Técnico'),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildQuestionCard({
    required String title,
    required String description,
    required bool value,
    required Color activeColor,
    required ValueChanged<bool> onChanged,
    required bool isDark,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: isDark ? 0.04 : 0.6),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: value ? activeColor.withValues(alpha: 0.5) : (isDark ? Colors.white12 : Colors.black12)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                const SizedBox(height: 2),
                Text(description, style: TextStyle(color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight, fontSize: 11)),
              ],
            ),
          ),
          Switch.adaptive(
            value: value,
            activeTrackColor: activeColor,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }

  Widget _buildCheckRow(String title, bool value, ValueChanged<bool> onChanged, bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: isDark ? 0.03 : 0.5),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: isDark ? Colors.white10 : Colors.black12),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(child: Text(title, style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600))),
            Switch.adaptive(
              value: value,
              activeTrackColor: AppColors.greenBiomass,
              onChanged: onChanged,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2.5),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 11.5, color: Colors.grey)),
          Text(value, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}

// ============================================================================
// 2. ASISTENTE PASO A PASO: INGRESO DE VEHÍCULOS (F-02 WIZARD)
// ============================================================================
class IngresoVehiculoWizardScreen extends ConsumerStatefulWidget {
  const IngresoVehiculoWizardScreen({super.key});

  static Future<void> open(BuildContext context) {
    return Navigator.of(context, rootNavigator: true).push(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => const IngresoVehiculoWizardScreen(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
      ),
    );
  }

  @override
  ConsumerState<IngresoVehiculoWizardScreen> createState() => _IngresoVehiculoWizardScreenState();
}

class _IngresoVehiculoWizardScreenState extends ConsumerState<IngresoVehiculoWizardScreen> {
  int _currentStep = 0;
  final _formKey1 = GlobalKey<FormState>();
  final _placaCtrl = TextEditingController();
  final _conductorCtrl = TextEditingController();
  final _docConductorCtrl = TextEditingController();
  final _telConductorCtrl = TextEditingController();
  final _empresaTranspCtrl = TextEditingController();
  final _procedenciaCtrl = TextEditingController();
  final _destinoInternoCtrl = TextEditingController(text: 'Zona de Descarga / Bodega Concentrados');
  final _desinfectanteCtrl = TextEditingController(text: 'Amonio Cuaternario 5ta Gen (Glutaraldehído)');
  final _concentracionCtrl = TextEditingController(text: '200 ppm (2.0 ml/L agua)');
  final _horaIngresoCtrl = TextEditingController(text: '09:00');
  final _horaSalidaCtrl = TextEditingController(text: '10:30');

  TipoVehiculoIca _tipoVehiculo = TipoVehiculoIca.camionAlimento;
  CivilDate _fecha = CivilDate.today();
  bool _desinfeccionRodiluvio = true;
  bool _desinfeccionArco = true;
  final int _tiempoContacto = 5;
  bool _isLoading = false;

  final List<String> _stepTitles = [
    'Vehículo y Conductor',
    'Ruta y Procedencia',
    'Desinfección y Rodiluvio',
  ];

  @override
  void dispose() {
    _placaCtrl.dispose();
    _conductorCtrl.dispose();
    _docConductorCtrl.dispose();
    _telConductorCtrl.dispose();
    _empresaTranspCtrl.dispose();
    _procedenciaCtrl.dispose();
    _destinoInternoCtrl.dispose();
    _desinfectanteCtrl.dispose();
    _concentracionCtrl.dispose();
    _horaIngresoCtrl.dispose();
    _horaSalidaCtrl.dispose();
    super.dispose();
  }

  Future<void> _guardar() async {
    setState(() => _isLoading = true);

    try {
      final auth = ref.read(authProvider);
      final empresaId = auth.currentCompany?.id ?? auth.currentUser?.empresaId ?? 'c1000000-0000-0000-0000-000000000001';
      final unidadId = auth.activeUnitId ?? auth.currentUser?.unidadAcuicolaId ?? empresaId;

      final record = IcaVehiculoRecord(
        empresaId: empresaId,
        unidadAcuicolaId: unidadId,
        fecha: _fecha.toDateTime(),
        horaIngreso: _horaIngresoCtrl.text.trim(),
        horaSalida: _horaSalidaCtrl.text.trim().isNotEmpty ? _horaSalidaCtrl.text.trim() : null,
        placa: _placaCtrl.text.trim().toUpperCase(),
        tipoVehiculo: _tipoVehiculo,
        conductor: _conductorCtrl.text.trim(),
        documentoConductor: _docConductorCtrl.text.trim().isNotEmpty ? _docConductorCtrl.text.trim() : null,
        telefonoConductor: _telConductorCtrl.text.trim().isNotEmpty ? _telConductorCtrl.text.trim() : null,
        empresaTransportadora: _empresaTranspCtrl.text.trim().isNotEmpty ? _empresaTranspCtrl.text.trim() : null,
        procedencia: _procedenciaCtrl.text.trim(),
        destinoInterno: _destinoInternoCtrl.text.trim(),
        desinfeccionRodiluvio: _desinfeccionRodiluvio,
        desinfeccionArcoAspersion: _desinfeccionArco,
        desinfectanteUtilizado: _desinfectanteCtrl.text.trim(),
        concentracionPpm: _concentracionCtrl.text.trim(),
        tiempoContactoMinutos: _tiempoContacto,
        responsableDesinfeccion: auth.currentUser?.nombre ?? 'Operario Punto Acceso',
      );

      final ok = await ref.read(icaComplianceProvider.notifier).registerVehiculo(record);

      if (mounted) {
        if (ok) {
          Navigator.of(context).pop();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('✅ Registro F-02 de desinfección vehicular guardado exitosamente.'),
              backgroundColor: AppColors.amberWarning,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _handleNext() {
    if (_currentStep == 0) {
      if (!_formKey1.currentState!.validate()) return;
      setState(() => _currentStep = 1);
    } else if (_currentStep == 1) {
      if (_procedenciaCtrl.text.trim().isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Indica el lugar de procedencia del vehículo.'),
            backgroundColor: AppColors.amberWarning,
            behavior: SnackBarBehavior.floating,
          ),
        );
        return;
      }
      setState(() => _currentStep = 2);
    } else {
      _guardar();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return IcaStepWizardScaffold(
      title: 'Control Vehicular (F-02)',
      subtitle: 'Desinfección de Vehículos y Rodiluvios Res. ICA 20186',
      icon: Icons.local_shipping_rounded,
      themeColor: AppColors.amberWarning,
      currentStep: _currentStep,
      totalSteps: 3,
      stepTitles: _stepTitles,
      nextLabel: _currentStep == 2 ? 'Finalizar y Guardar F-02' : 'Continuar al Paso ${_currentStep + 2}',
      isNextLoading: _isLoading,
      onBack: () => setState(() => _currentStep = (_currentStep - 1).clamp(0, 2)),
      onNext: _handleNext,
      child: _buildCurrentStep(isDark),
    );
  }

  Widget _buildCurrentStep(bool isDark) {
    switch (_currentStep) {
      case 0:
        return Form(
          key: _formKey1,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('IDENTIFICACIÓN DEL VEHÍCULO', style: AppTypography.labelMicro.copyWith(color: AppColors.amberWarning, fontWeight: FontWeight.w900)),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    flex: 3,
                    child: GlassDatePickerField(
                      label: 'FECHA',
                      initialDate: _fecha,
                      onDateChanged: (d) => setState(() => _fecha = d),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    flex: 2,
                    child: GlassFormField(
                      label: 'PLACA *',
                      hint: 'TLP-456',
                      controller: _placaCtrl,
                      validator: (v) => (v == null || v.trim().isEmpty) ? 'Requerido' : null,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              Text('TIPO DE VEHÍCULO', style: AppTypography.labelMicro.copyWith(color: AppColors.amberWarning, fontWeight: FontWeight.w900)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: TipoVehiculoIca.values.map((tipo) {
                  final isSel = _tipoVehiculo == tipo;
                  return ChoiceChip(
                    label: Text(tipo.label),
                    selected: isSel,
                    onSelected: (_) => setState(() => _tipoVehiculo = tipo),
                    selectedColor: AppColors.amberWarning.withValues(alpha: 0.25),
                    labelStyle: TextStyle(
                      color: isSel ? AppColors.amberWarning : (isDark ? Colors.white70 : Colors.black87),
                      fontWeight: isSel ? FontWeight.w800 : FontWeight.w500,
                      fontSize: 11,
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),

              Row(
                children: [
                  Expanded(
                    flex: 3,
                    child: GlassFormField(
                      label: 'CONDUCTOR *',
                      hint: 'Ej: Juan Camilo Pérez',
                      controller: _conductorCtrl,
                      validator: (v) => (v == null || v.trim().isEmpty) ? 'Requerido' : null,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    flex: 2,
                    child: GlassFormField(
                      label: 'CÉDULA CONDUCTOR',
                      hint: 'Ej: 79885123',
                      controller: _docConductorCtrl,
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      case 1:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('TRAZABILIDAD DE CARGA Y RUTA', style: AppTypography.labelMicro.copyWith(color: AppColors.amberWarning, fontWeight: FontWeight.w900)),
            const SizedBox(height: 12),
            GlassFormField(
              label: 'LUGAR DE PROCEDENCIA *',
              hint: 'Ej: Planta Concentrados Neiva / Granja El Diamante',
              controller: _procedenciaCtrl,
            ),
            const SizedBox(height: 12),
            GlassFormField(
              label: 'EMPRESA TRANSPORTADORA',
              hint: 'Ej: Transportes del Huila S.A.S / Propio',
              controller: _empresaTranspCtrl,
            ),
            const SizedBox(height: 12),
            GlassFormField(
              label: 'DESTINO INTERNO AUTORIZADO',
              hint: 'Ej: Bodega Central de Alimento / Rampa de Cosecha',
              controller: _destinoInternoCtrl,
            ),
          ],
        );
      case 2:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('PROTOCOLO DE DESINFECCIÓN EN ARCO Y RODILUVIO', style: AppTypography.labelMicro.copyWith(color: AppColors.amberWarning, fontWeight: FontWeight.w900)),
            const SizedBox(height: 12),

            _buildSwitchItem('Paso por Rodiluvio (Llantas y guardabarros sumergidos)', _desinfeccionRodiluvio, (v) => setState(() => _desinfeccionRodiluvio = v), isDark),
            _buildSwitchItem('Aspersión en Arco / Cabina, Carrocería y Chasis', _desinfeccionArco, (v) => setState(() => _desinfeccionArco = v), isDark),

            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  flex: 3,
                  child: GlassFormField(
                    label: 'PRODUCTO DESINFECTANTE',
                    hint: 'Amonio Cuaternario / Glutaraldehído',
                    controller: _desinfectanteCtrl,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  flex: 2,
                  child: GlassFormField(
                    label: 'CONCENTRACIÓN',
                    hint: '200 ppm',
                    controller: _concentracionCtrl,
                  ),
                ),
              ],
            ),
          ],
        );
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildSwitchItem(String title, bool value, ValueChanged<bool> onChanged, bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: isDark ? 0.03 : 0.5),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: isDark ? Colors.white10 : Colors.black12),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(child: Text(title, style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600))),
            Switch.adaptive(
              value: value,
              activeTrackColor: AppColors.amberWarning,
              onChanged: onChanged,
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================================
// 3. ASISTENTE PASO A PASO: NECROPSIAS Y PATOLOGÍA (F-03 WIZARD)
// ============================================================================
class NecropsiaWizardScreen extends ConsumerStatefulWidget {
  const NecropsiaWizardScreen({super.key});

  static Future<void> open(BuildContext context) {
    return Navigator.of(context, rootNavigator: true).push(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => const NecropsiaWizardScreen(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
      ),
    );
  }

  @override
  ConsumerState<NecropsiaWizardScreen> createState() => _NecropsiaWizardScreenState();
}

class _NecropsiaWizardScreenState extends ConsumerState<NecropsiaWizardScreen> {
  int _currentStep = 0;
  final _ejemplaresCtrl = TextEditingController(text: '3');
  final _pesoPromCtrl = TextEditingController(text: '250.0');
  final _tallaPromCtrl = TextEditingController(text: '22.0');

  final _pielAletasCtrl = TextEditingController(text: 'Piel con coloración homogénea, aletas íntegras sin erosión.');
  final _branquiasCtrl = TextEditingController(text: 'Branquias de color rojo cereza, filamentos intactos.');
  final _higadoCtrl = TextEditingController(text: 'Hígado rojizo de consistencia normal, bordes lisos.');
  final _bazoCtrl = TextEditingController(text: 'Bazo sin esplenomegalia, color rojo oscuro normal.');
  final _diagnosticoCtrl = TextEditingController(text: 'Muestreo de rutina / Monitoreo preventivo.');
  final _conductaCtrl = TextEditingController(text: 'Mantener tasa de aireación y recambio normal.');
  final _profesionalCtrl = TextEditingController();
  final _tarjetaProfCtrl = TextEditingController();

  String? _selectedPondId;
  String _especie = 'Trucha Arcoíris';
  CivilDate _fecha = CivilDate.today();
  bool _presenciaEctoparasitos = false;
  bool _envioLaboratorio = false;
  bool _isLoading = false;

  final List<String> _stepTitles = [
    'Muestra y Biometría',
    'Examen de Órganos',
    'Diagnóstico y Firma M.V.',
  ];

  @override
  void initState() {
    super.initState();
    final auth = ref.read(authProvider);
    _profesionalCtrl.text = auth.currentUser?.nombre ?? 'Director Técnico / M.V.';
    final company = auth.currentCompany;
    if (company != null && company.especiesHabilitadas.isNotEmpty) {
      _especie = company.especiesHabilitadas.first;
    }
  }

  @override
  void dispose() {
    _ejemplaresCtrl.dispose();
    _pesoPromCtrl.dispose();
    _tallaPromCtrl.dispose();
    _pielAletasCtrl.dispose();
    _branquiasCtrl.dispose();
    _higadoCtrl.dispose();
    _bazoCtrl.dispose();
    _diagnosticoCtrl.dispose();
    _conductaCtrl.dispose();
    _profesionalCtrl.dispose();
    _tarjetaProfCtrl.dispose();
    super.dispose();
  }

  Future<void> _guardar() async {
    setState(() => _isLoading = true);

    try {
      final auth = ref.read(authProvider);
      final ponds = ref.read(pondsProvider).ponds;
      final batches = ref.read(pondsProvider).batches;
      final empresaId = auth.currentCompany?.id ?? auth.currentUser?.empresaId ?? 'c1000000-0000-0000-0000-000000000001';
      final unidadId = auth.activeUnitId ?? auth.currentUser?.unidadAcuicolaId ?? empresaId;

      final estanque = ponds.where((p) => p.id == _selectedPondId).firstOrNull ?? (ponds.isNotEmpty ? ponds.first : null);
      final lote = batches.where((b) => b.estanqueId == estanque?.id).firstOrNull;

      final record = IcaNecropsiaRecord(
        empresaId: empresaId,
        unidadAcuicolaId: unidadId,
        estanqueId: estanque?.id,
        estanqueNombre: estanque?.nombreLimpio,
        loteCodigo: lote?.codigoLote,
        fecha: _fecha.toDateTime(),
        especie: _especie,
        numeroEjemplares: int.tryParse(_ejemplaresCtrl.text) ?? 2,
        pesoPromedioGramos: double.tryParse(_pesoPromCtrl.text) ?? 250.0,
        tallaPromedioCm: double.tryParse(_tallaPromCtrl.text),
        hallazgosPielAletas: _pielAletasCtrl.text.trim(),
        hallazgosOjos: 'Ojos normales, sin exoftalmia',
        hallazgosBranquias: _branquiasCtrl.text.trim(),
        presenciaEctoparasitos: _presenciaEctoparasitos,
        hallazgosHigado: _higadoCtrl.text.trim(),
        hallazgosBazo: _bazoCtrl.text.trim(),
        hallazgosIntestinoEstomago: 'Contenido digestivo normal',
        hallazgosCavidadCelomica: 'Sin líquido libre celómico',
        hallazgosRinon: 'Riñón posterior conservado',
        diagnosticoPresuntivo: _diagnosticoCtrl.text.trim(),
        envioMuestrasLaboratorio: _envioLaboratorio,
        conductaTratamiento: _conductaCtrl.text.trim(),
        profesionalResponsable: _profesionalCtrl.text.trim(),
        tarjetaProfesional: _tarjetaProfCtrl.text.trim().isNotEmpty ? _tarjetaProfCtrl.text.trim() : null,
      );

      final ok = await ref.read(icaComplianceProvider.notifier).registerNecropsia(record);

      if (mounted) {
        if (ok) {
          Navigator.of(context).pop();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('✅ Informe de necropsia F-03 registrado en el expediente ICA.'),
              backgroundColor: Colors.purpleAccent,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return IcaStepWizardScaffold(
      title: 'Necropsia y Sanidad (F-03)',
      subtitle: 'Diagnóstico Clínico y Examen de Órganos Res. ICA 20186',
      icon: Icons.biotech_rounded,
      themeColor: Colors.purpleAccent,
      currentStep: _currentStep,
      totalSteps: 3,
      stepTitles: _stepTitles,
      nextLabel: _currentStep == 2 ? 'Finalizar y Guardar F-03' : 'Continuar al Paso ${_currentStep + 2}',
      isNextLoading: _isLoading,
      onBack: () => setState(() => _currentStep = (_currentStep - 1).clamp(0, 2)),
      onNext: () {
        if (_currentStep < 2) {
          setState(() => _currentStep++);
        } else {
          _guardar();
        }
      },
      child: _buildCurrentStep(isDark),
    );
  }

  Widget _buildCurrentStep(bool isDark) {
    final ponds = ref.watch(pondsProvider).ponds;
    if (_selectedPondId == null && ponds.isNotEmpty) {
      _selectedPondId = ponds.first.id;
    }

    switch (_currentStep) {
      case 0:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('DATOS DEL MUESTREO BIOLÓGICO', style: AppTypography.labelMicro.copyWith(color: Colors.purpleAccent, fontWeight: FontWeight.w900)),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  flex: 3,
                  child: GlassDatePickerField(
                    label: 'FECHA',
                    initialDate: _fecha,
                    onDateChanged: (d) => setState(() => _fecha = d),
                  ),
                ),
                const SizedBox(width: 10),
                if (ponds.isNotEmpty)
                  Expanded(
                    flex: 3,
                    child: DropdownButtonFormField<String>(
                      initialValue: _selectedPondId,
                      decoration: InputDecoration(
                        labelText: 'Estanque',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      ),
                      items: ponds.map((p) => DropdownMenuItem(value: p.id, child: Text(p.nombreLimpio))).toList(),
                      onChanged: (v) => setState(() => _selectedPondId = v),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: GlassFormField(
                    label: 'NO. PECES MUESTREADOS',
                    hint: '3',
                    controller: _ejemplaresCtrl,
                    keyboardType: TextInputType.number,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: GlassFormField(
                    label: 'PESO PROM. (g)',
                    hint: '250.0',
                    controller: _pesoPromCtrl,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: GlassFormField(
                    label: 'TALLA PROM. (cm)',
                    hint: '22.0',
                    controller: _tallaPromCtrl,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  ),
                ),
              ],
            ),
          ],
        );
      case 1:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('EVALUACIÓN ANATÓMICA Y PATOLÓGICA', style: AppTypography.labelMicro.copyWith(color: Colors.purpleAccent, fontWeight: FontWeight.w900)),
            const SizedBox(height: 12),
            GlassFormField(
              label: 'BRANQUIAS (COLOR, FILAMENTOS Y MUCUS)',
              hint: 'Ej: Rojo brillante, sin necrosis',
              controller: _branquiasCtrl,
            ),
            const SizedBox(height: 10),
            GlassFormField(
              label: 'PIEL, ESCAMAS Y ALETAS',
              hint: 'Ej: Piel íntegra, sin úlceras',
              controller: _pielAletasCtrl,
            ),
            const SizedBox(height: 10),
            GlassFormField(
              label: 'HÍGADO Y VESÍCULA BILIAR',
              hint: 'Ej: Hígado homogéneo, sin manchas',
              controller: _higadoCtrl,
            ),
            const SizedBox(height: 10),
            GlassFormField(
              label: 'BAZO Y ÓRGANOS INTERNOS',
              hint: 'Ej: Bazo de tamaño y color normal',
              controller: _bazoCtrl,
            ),
          ],
        );
      case 2:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('DIAGNÓSTICO Y RESPONSABLE TÉCNICO', style: AppTypography.labelMicro.copyWith(color: Colors.purpleAccent, fontWeight: FontWeight.w900)),
            const SizedBox(height: 12),
            GlassFormField(
              label: 'DIAGNÓSTICO PRESUNTIVO *',
              hint: 'Ej: Control zootécnico rutinario negativo',
              controller: _diagnosticoCtrl,
            ),
            const SizedBox(height: 10),
            GlassFormField(
              label: 'CONDUCTA / MEDIDAS PROFILÁCTICAS',
              hint: 'Ej: Mantener régimen normal de alimentación y aireación',
              controller: _conductaCtrl,
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  flex: 3,
                  child: GlassFormField(
                    label: 'MÉDICO VETERINARIO / PROFESIONAL *',
                    hint: 'Ej: Dr. Fernando Gómez',
                    controller: _profesionalCtrl,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  flex: 2,
                  child: GlassFormField(
                    label: 'TARJETA PROFESIONAL',
                    hint: 'TP-45982 COMVEZCOL',
                    controller: _tarjetaProfCtrl,
                  ),
                ),
              ],
            ),
          ],
        );
      default:
        return const SizedBox.shrink();
    }
  }
}
