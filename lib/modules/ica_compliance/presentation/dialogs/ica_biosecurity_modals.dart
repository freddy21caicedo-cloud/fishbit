import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fishbit_finance/core/design_system/app_colors.dart';
import 'package:fishbit_finance/core/design_system/app_typography.dart';
import 'package:fishbit_finance/core/design_system/glass_container.dart';
import 'package:fishbit_finance/core/design_system/glass_form_field.dart';
import 'package:fishbit_finance/core/design_system/glass_date_picker.dart';
import 'package:fishbit_finance/core/design_system/glass_button.dart';
import 'package:fishbit_finance/modules/auth_tenant/presentation/providers/auth_provider.dart';
import 'package:fishbit_finance/modules/ponds_batches/presentation/providers/ponds_provider.dart';
import 'package:fishbit_finance/modules/ica_compliance/domain/models/ica_personal_record.dart';
import 'package:fishbit_finance/modules/ica_compliance/domain/models/ica_vehiculo_record.dart';
import 'package:fishbit_finance/modules/ica_compliance/domain/models/ica_necropsia_record.dart';
import 'package:fishbit_finance/modules/ica_compliance/presentation/providers/ica_compliance_provider.dart';

// ============================================================================
// 1. MODAL EXHAUSTIVO: INGRESO DE PERSONAL Y VISITAS (F-01)
// ============================================================================
class IngresoPersonalModal extends ConsumerStatefulWidget {
  const IngresoPersonalModal({super.key});

  static Future<void> show(BuildContext context) {
    return showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => const IngresoPersonalModal(),
    );
  }

  @override
  ConsumerState<IngresoPersonalModal> createState() => _IngresoPersonalModalState();
}

class _IngresoPersonalModalState extends ConsumerState<IngresoPersonalModal> {
  final _formKey = GlobalKey<FormState>();
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
    if (!_formKey.currentState!.validate()) return;
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
              content: Text('✅ Registro F-01 de ingreso y bioseguridad guardado exitosamente.'),
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

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 540),
        child: GlassContainer(
          borderRadius: 24,
          padding: const EdgeInsets.all(22),
          blur: 24,
          opacity: isDark ? 0.22 : 0.96,
          borderColor: AppColors.cyanWater.withValues(alpha: 0.35),
          child: SingleChildScrollView(
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AppColors.cyanWater.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.cyanWater.withValues(alpha: 0.3)),
                        ),
                        child: const Icon(Icons.badge_rounded, color: AppColors.cyanWater, size: 22),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Formato F-01: Control de Ingreso y Bioseguridad',
                              style: AppTypography.titleSmall.copyWith(
                                color: isDark ? Colors.white : AppColors.textPrimaryLight,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            Text(
                              'Resolución ICA 20186 • Personal y Visitantes',
                              style: AppTypography.labelMicro.copyWith(color: AppColors.textSecondaryDark),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close_rounded, size: 20),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Fecha y Horas
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
                  const SizedBox(height: 12),

                  // Tipo de Persona
                  Text('TIPO DE PERSONA', style: AppTypography.labelMicro.copyWith(color: AppColors.cyanWater, fontWeight: FontWeight.w800)),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: TipoPersonaIca.values.map((tipo) {
                      final isSelected = _tipoPersona == tipo;
                      return ChoiceChip(
                        label: Text(tipo.label),
                        selected: isSelected,
                        onSelected: (val) => setState(() => _tipoPersona = tipo),
                        selectedColor: AppColors.cyanWater.withValues(alpha: 0.25),
                        labelStyle: TextStyle(
                          color: isSelected ? AppColors.cyanWater : (isDark ? Colors.white70 : Colors.black87),
                          fontWeight: isSelected ? FontWeight.w800 : FontWeight.w500,
                          fontSize: 10,
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 12),

                  // Datos Personales
                  Row(
                    children: [
                      Expanded(
                        flex: 3,
                        child: GlassFormField(
                          label: 'NOMBRE COMPLETO *',
                          hint: 'Ej: Carlos Arturo Mendoza',
                          controller: _nombreCtrl,
                          validator: (v) => (v == null || v.trim().isEmpty) ? 'Requerido' : null,
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
                          label: 'ENTIDAD / EMPRESA DE ORIGEN',
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
                    hint: 'Ej: Toma de muestras oficiales de agua y necropsia de lote 3',
                    controller: _motivoCtrl,
                  ),
                  const SizedBox(height: 14),

                  // Sección Protocolos Sanitarios y Evaluación Epidemiológica
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: isDark ? 0.04 : 0.6),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: AppColors.cyanWater.withValues(alpha: 0.2)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('VERIFICACIÓN SANITARIA Y DE BIOSEGURIDAD', style: AppTypography.labelMicro.copyWith(color: AppColors.cyanWater, fontWeight: FontWeight.w900)),
                        const SizedBox(height: 8),

                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Expanded(
                              child: Text('¿Desinfección de calzado en pediluvio?', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                            ),
                            Switch.adaptive(
                              value: _desinfeccionCalzado,
                              activeTrackColor: AppColors.greenBiomass,
                              onChanged: (v) => setState(() => _desinfeccionCalzado = v),
                            ),
                          ],
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Expanded(
                              child: Text('¿Lavado y desinfección de manos?', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                            ),
                            Switch.adaptive(
                              value: _lavadoManos,
                              activeTrackColor: AppColors.greenBiomass,
                              onChanged: (v) => setState(() => _lavadoManos = v),
                            ),
                          ],
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Expanded(
                              child: Text('¿Indumentaria limpia / botas exclusivas?', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                            ),
                            Switch.adaptive(
                              value: _indumentariaLimpia,
                              activeTrackColor: AppColors.greenBiomass,
                              onChanged: (v) => setState(() => _indumentariaLimpia = v),
                            ),
                          ],
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Expanded(
                              child: Text('¿Presenta síntomas respiratorios o dérmicos?', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.coralAction)),
                            ),
                            Switch.adaptive(
                              value: _presentaSintomas,
                              activeTrackColor: AppColors.coralAction,
                              onChanged: (v) => setState(() => _presentaSintomas = v),
                            ),
                          ],
                        ),
                        const Divider(height: 16),

                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Expanded(
                              child: Text('¿Visitó otras granjas acuícolas en últimas 72 horas?', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.coralAction)),
                            ),
                            Switch.adaptive(
                              value: _haVisitadoOtras,
                              activeTrackColor: AppColors.coralAction,
                              onChanged: (v) => setState(() => _haVisitadoOtras = v),
                            ),
                          ],
                        ),
                        if (_haVisitadoOtras) ...[
                          const SizedBox(height: 8),
                          GlassFormField(
                            label: 'DETALLE DE OTRAS GRANJAS VISITADAS (MUNICIPIO / PREDIO) *',
                            hint: 'Ej: Piscícola El Porvenir - Garzón, Huila',
                            controller: _detalleOtrasCtrl,
                            validator: (v) => _haVisitadoOtras && (v == null || v.trim().isEmpty) ? 'Requerido por protocolo ICA' : null,
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),

                  GlassButton(
                    label: 'Guardar Registro Oficial de Ingreso (F-01)',
                    backgroundColor: AppColors.cyanWater,
                    isLoading: _isLoading,
                    onPressed: _guardar,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ============================================================================
// 2. MODAL EXHAUSTIVO: INGRESO Y DESINFECCIÓN DE VEHÍCULOS (F-02)
// ============================================================================
class IngresoVehiculoModal extends ConsumerStatefulWidget {
  const IngresoVehiculoModal({super.key});

  static Future<void> show(BuildContext context) {
    return showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => const IngresoVehiculoModal(),
    );
  }

  @override
  ConsumerState<IngresoVehiculoModal> createState() => _IngresoVehiculoModalState();
}

class _IngresoVehiculoModalState extends ConsumerState<IngresoVehiculoModal> {
  final _formKey = GlobalKey<FormState>();
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
    if (!_formKey.currentState!.validate()) return;
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

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 540),
        child: GlassContainer(
          borderRadius: 24,
          padding: const EdgeInsets.all(22),
          blur: 24,
          opacity: isDark ? 0.22 : 0.96,
          borderColor: AppColors.amberWarning.withValues(alpha: 0.35),
          child: SingleChildScrollView(
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AppColors.amberWarning.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.amberWarning.withValues(alpha: 0.3)),
                        ),
                        child: const Icon(Icons.local_shipping_rounded, color: AppColors.amberWarning, size: 22),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Formato F-02: Vehículos y Rodiluvios',
                              style: AppTypography.titleSmall.copyWith(
                                color: isDark ? Colors.white : AppColors.textPrimaryLight,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            Text(
                              'Resolución ICA 20186 • Desinfección de Transporte',
                              style: AppTypography.labelMicro.copyWith(color: AppColors.textSecondaryDark),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close_rounded, size: 20),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

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
                  const SizedBox(height: 12),

                  // Tipo de Vehículo
                  Text('TIPO DE VEHÍCULO', style: AppTypography.labelMicro.copyWith(color: AppColors.amberWarning, fontWeight: FontWeight.w800)),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: TipoVehiculoIca.values.map((tipo) {
                      final isSelected = _tipoVehiculo == tipo;
                      return ChoiceChip(
                        label: Text(tipo.label),
                        selected: isSelected,
                        onSelected: (val) => setState(() => _tipoVehiculo = tipo),
                        selectedColor: AppColors.amberWarning.withValues(alpha: 0.25),
                        labelStyle: TextStyle(
                          color: isSelected ? AppColors.amberWarning : (isDark ? Colors.white70 : Colors.black87),
                          fontWeight: isSelected ? FontWeight.w800 : FontWeight.w500,
                          fontSize: 10,
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 12),

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
                  const SizedBox(height: 12),

                  Row(
                    children: [
                      Expanded(
                        child: GlassFormField(
                          label: 'EMPRESA TRANSPORTADORA',
                          hint: 'Ej: Transportes del Huila S.A.S',
                          controller: _empresaTranspCtrl,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: GlassFormField(
                          label: 'LUGAR DE PROCEDENCIA *',
                          hint: 'Ej: Planta Concentrados Neiva',
                          controller: _procedenciaCtrl,
                          validator: (v) => (v == null || v.trim().isEmpty) ? 'Requerido' : null,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  GlassFormField(
                    label: 'DESTINO INTERNO AUTORIZADO',
                    hint: 'Ej: Bodega Central de Alimento / Rampa de Cosecha',
                    controller: _destinoInternoCtrl,
                  ),
                  const SizedBox(height: 14),

                  // Protocolo de Desinfección Aplicado
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: isDark ? 0.04 : 0.6),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: AppColors.amberWarning.withValues(alpha: 0.2)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('PROTOCOLO DE DESINFECCIÓN EN PUNTO DE ACCESO', style: AppTypography.labelMicro.copyWith(color: AppColors.amberWarning, fontWeight: FontWeight.w900)),
                        const SizedBox(height: 8),

                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Expanded(
                              child: Text('¿Paso por Rodiluvio (Llantas sumergidas)?', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                            ),
                            Switch.adaptive(
                              value: _desinfeccionRodiluvio,
                              activeTrackColor: AppColors.greenBiomass,
                              onChanged: (v) => setState(() => _desinfeccionRodiluvio = v),
                            ),
                          ],
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Expanded(
                              child: Text('¿Aspersión de Cabina, Carrocería y Chasis?', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                            ),
                            Switch.adaptive(
                              value: _desinfeccionArco,
                              activeTrackColor: AppColors.greenBiomass,
                              onChanged: (v) => setState(() => _desinfeccionArco = v),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(
                              flex: 3,
                              child: GlassFormField(
                                label: 'PRODUCTO DESINFECTANTE',
                                hint: 'Amonio Cuaternario / Yodo',
                                controller: _desinfectanteCtrl,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              flex: 2,
                              child: GlassFormField(
                                label: 'CONCENTRACIÓN (ppm)',
                                hint: '200 ppm',
                                controller: _concentracionCtrl,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),

                  GlassButton(
                    label: 'Guardar Registro de Desinfección Vehicular (F-02)',
                    backgroundColor: AppColors.amberWarning,
                    isLoading: _isLoading,
                    onPressed: _guardar,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ============================================================================
// 3. MODAL EXHAUSTIVO: NECROPSIAS Y HALLAZGOS CLÍNICOS (F-03)
// ============================================================================
class NecropsiaModal extends ConsumerStatefulWidget {
  const NecropsiaModal({super.key});

  static Future<void> show(BuildContext context) {
    return showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => const NecropsiaModal(),
    );
  }

  @override
  ConsumerState<NecropsiaModal> createState() => _NecropsiaModalState();
}

class _NecropsiaModalState extends ConsumerState<NecropsiaModal> {
  final _formKey = GlobalKey<FormState>();
  final _ejemplaresCtrl = TextEditingController(text: '3');
  final _pesoPromCtrl = TextEditingController(text: '250.0');
  final _tallaPromCtrl = TextEditingController(text: '22.0');

  // Signología externa e interna
  final _pielAletasCtrl = TextEditingController(text: 'Piel con coloración homogénea, aletas íntegras sin erosión.');
  final _ojosCtrl = TextEditingController(text: 'Ojos claros, sin exoftalmia ni opacidad.');
  final _branquiasCtrl = TextEditingController(text: 'Branquias de color rojo cereza, filamentos intactos.');
  final _higadoCtrl = TextEditingController(text: 'Hígado rojizo de consistencia normal, bordes lisos.');
  final _bazoCtrl = TextEditingController(text: 'Bazo sin esplenomegalia, color rojo oscuro normal.');
  final _tractoCtrl = TextEditingController(text: 'Contenido alimenticio normal en estómago, sin enteritis.');
  final _cavidadCtrl = TextEditingController(text: 'Sin presencia de líquido libre celómico (sin ascitis).');
  final _rinonCtrl = TextEditingController(text: 'Riñón posterior de aspecto y tamaño conservado.');
  final _diagnosticoCtrl = TextEditingController(text: 'Muestreo de rutina / Monitoreo preventivo.');
  final _conductaCtrl = TextEditingController(text: 'Mantener tasa de aireación y recambio normal.');
  final _profesionalCtrl = TextEditingController();
  final _tarjetaProfCtrl = TextEditingController();

  String? _selectedPondId;
  final String _especie = 'Tilapia Roja';
  CivilDate _fecha = CivilDate.today();
  bool _presenciaEctoparasitos = false;
  bool _envioLaboratorio = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    final user = ref.read(authProvider).currentUser;
    _profesionalCtrl.text = user?.nombre ?? 'M.V. Director Técnico';
  }

  @override
  void dispose() {
    _ejemplaresCtrl.dispose();
    _pesoPromCtrl.dispose();
    _tallaPromCtrl.dispose();
    _pielAletasCtrl.dispose();
    _ojosCtrl.dispose();
    _branquiasCtrl.dispose();
    _higadoCtrl.dispose();
    _bazoCtrl.dispose();
    _tractoCtrl.dispose();
    _cavidadCtrl.dispose();
    _rinonCtrl.dispose();
    _diagnosticoCtrl.dispose();
    _conductaCtrl.dispose();
    _profesionalCtrl.dispose();
    _tarjetaProfCtrl.dispose();
    super.dispose();
  }

  Future<void> _guardar() async {
    if (!_formKey.currentState!.validate()) return;
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
        hallazgosOjos: _ojosCtrl.text.trim(),
        hallazgosBranquias: _branquiasCtrl.text.trim(),
        presenciaEctoparasitos: _presenciaEctoparasitos,
        hallazgosHigado: _higadoCtrl.text.trim(),
        hallazgosBazo: _bazoCtrl.text.trim(),
        hallazgosIntestinoEstomago: _tractoCtrl.text.trim(),
        hallazgosCavidadCelomica: _cavidadCtrl.text.trim(),
        hallazgosRinon: _rinonCtrl.text.trim(),
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
              content: Text('✅ Informe clínico y necropsia F-03 guardado en el expediente ICA.'),
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
    final ponds = ref.watch(pondsProvider).ponds;

    if (_selectedPondId == null && ponds.isNotEmpty) {
      _selectedPondId = ponds.first.id;
    }

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 580),
        child: GlassContainer(
          borderRadius: 24,
          padding: const EdgeInsets.all(22),
          blur: 24,
          opacity: isDark ? 0.22 : 0.96,
          borderColor: Colors.purpleAccent.withValues(alpha: 0.35),
          child: SingleChildScrollView(
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.purpleAccent.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.purpleAccent.withValues(alpha: 0.3)),
                        ),
                        child: const Icon(Icons.biotech_rounded, color: Colors.purpleAccent, size: 22),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Formato F-03: Necropsia y Hallazgos Clínicos',
                              style: AppTypography.titleSmall.copyWith(
                                color: isDark ? Colors.white : AppColors.textPrimaryLight,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            Text(
                              'Resolución ICA 20186 • Sanidad y Diagnóstico Zootécnico',
                              style: AppTypography.labelMicro.copyWith(color: AppColors.textSecondaryDark),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close_rounded, size: 20),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  Row(
                    children: [
                      Expanded(
                        flex: 3,
                        child: GlassDatePickerField(
                          label: 'FECHA DEL PROCEDIMIENTO',
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
                              labelText: 'Estanque Muestreado',
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                            ),
                            items: ponds.map((p) => DropdownMenuItem(value: p.id, child: Text(p.nombreLimpio, style: const TextStyle(fontSize: 12)))).toList(),
                            onChanged: (v) => setState(() => _selectedPondId = v),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  Row(
                    children: [
                      Expanded(
                        child: GlassFormField(
                          label: 'NO. EJEMPLARES',
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
                  const SizedBox(height: 14),

                  // Hallazgos Órgano por Órgano
                  Text('EXAMEN CLÍNICO DETALLADO', style: AppTypography.labelMicro.copyWith(color: Colors.purpleAccent, fontWeight: FontWeight.w800)),
                  const SizedBox(height: 8),

                  GlassFormField(
                    label: 'BRANQUIAS (COLOR, MUCUS, FILAMENTOS)',
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
                    hint: 'Ej: Hígado rojizo homogéneo, bordes definidos',
                    controller: _higadoCtrl,
                  ),
                  const SizedBox(height: 10),

                  GlassFormField(
                    label: 'BAZO, TRACTO DIGESTIVO Y CAVIDAD CELÓMICA',
                    hint: 'Ej: Bazo de tamaño normal, sin líquido ascítico',
                    controller: _bazoCtrl,
                  ),
                  const SizedBox(height: 14),

                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: isDark ? 0.04 : 0.6),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: Colors.purpleAccent.withValues(alpha: 0.2)),
                    ),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Expanded(
                              child: Text('¿Presencia de Ectoparásitos (Argulus/Lernaea/Ictio)?', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                            ),
                            Switch.adaptive(
                              value: _presenciaEctoparasitos,
                              activeTrackColor: AppColors.coralAction,
                              onChanged: (v) => setState(() => _presenciaEctoparasitos = v),
                            ),
                          ],
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Expanded(
                              child: Text('¿Envío de muestras a laboratorio oficial ICA/AUNAP?', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                            ),
                            Switch.adaptive(
                              value: _envioLaboratorio,
                              activeTrackColor: Colors.purpleAccent,
                              onChanged: (v) => setState(() => _envioLaboratorio = v),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Diagnóstico y Responsable
                  GlassFormField(
                    label: 'DIAGNÓSTICO PRESUNTIVO *',
                    hint: 'Ej: Control rutinario negativo a patógenos',
                    controller: _diagnosticoCtrl,
                    validator: (v) => (v == null || v.trim().isEmpty) ? 'Requerido' : null,
                  ),
                  const SizedBox(height: 10),

                  GlassFormField(
                    label: 'CONDUCTA / MEDIDAS PROFILÁCTICAS',
                    hint: 'Ej: Continuar monitoreo de calidad de agua y desinfección preventiva',
                    controller: _conductaCtrl,
                  ),
                  const SizedBox(height: 12),

                  Row(
                    children: [
                      Expanded(
                        flex: 3,
                        child: GlassFormField(
                          label: 'PROFESIONAL RESPONSABLE *',
                          hint: 'Ej: Dr. Fernando Gómez',
                          controller: _profesionalCtrl,
                          validator: (v) => (v == null || v.trim().isEmpty) ? 'Requerido' : null,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        flex: 2,
                        child: GlassFormField(
                          label: 'TARJETA PROFESIONAL (M.V.)',
                          hint: 'Ej: TP-45982 COMVEZCOL',
                          controller: _tarjetaProfCtrl,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),

                  GlassButton(
                    label: 'Guardar Informe de Necropsia (F-03)',
                    backgroundColor: Colors.purpleAccent,
                    isLoading: _isLoading,
                    onPressed: _guardar,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
