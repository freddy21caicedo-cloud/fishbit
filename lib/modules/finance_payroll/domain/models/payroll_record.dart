/// Registro de nómina laboral pagada o pendiente con provisiones
class PayrollRecord {
  final String id;
  final String empresaId;
  final String unidadAcuicolaId;
  final String empleadoId;
  final String empleadoNombre;
  final String periodo; // 'Quincenal' | 'Mensual'
  final double salarioBase;
  final double auxilioTransporte;
  final double recargosExtras;
  final double pensionPatronal;
  final double arl;
  final double cajaCompensacion;
  final double prima;
  final double cesantias;
  final double interesesCesantias;
  final double vacaciones;
  final double dotacionProvision;
  final double costoTotalEmpresa;
  final DateTime fechaPago;
  final String estado; // 'Pendiente' | 'Pagado'
  final DateTime creadoEn;

  const PayrollRecord({
    required this.id,
    required this.empresaId,
    required this.unidadAcuicolaId,
    required this.empleadoId,
    required this.empleadoNombre,
    required this.periodo,
    required this.salarioBase,
    this.auxilioTransporte = 0.0,
    this.recargosExtras = 0.0,
    this.pensionPatronal = 0.0,
    this.arl = 0.0,
    this.cajaCompensacion = 0.0,
    this.prima = 0.0,
    this.cesantias = 0.0,
    this.interesesCesantias = 0.0,
    this.vacaciones = 0.0,
    this.dotacionProvision = 0.0,
    required this.costoTotalEmpresa,
    required this.fechaPago,
    this.estado = 'Pagado',
    required this.creadoEn,
  });

  factory PayrollRecord.fromJson(Map<String, dynamic> json) {
    return PayrollRecord(
      id: json['id'] as String,
      empresaId: json['empresa_id'] as String? ?? '',
      unidadAcuicolaId: json['unidad_acuicola_id'] as String? ?? '',
      empleadoId: json['empleado_id'] as String? ?? '',
      empleadoNombre: json['empleado_nombre'] as String? ?? '',
      periodo: json['periodo'] as String? ?? 'Quincenal',
      salarioBase: (json['salario_base'] as num?)?.toDouble() ?? 0.0,
      auxilioTransporte: (json['auxilio_transporte'] as num?)?.toDouble() ?? 0.0,
      recargosExtras: (json['recargos_extras'] as num?)?.toDouble() ?? 0.0,
      pensionPatronal: (json['pension_patronal'] as num?)?.toDouble() ?? 0.0,
      arl: (json['arl'] as num?)?.toDouble() ?? 0.0,
      cajaCompensacion: (json['caja_compensacion'] as num?)?.toDouble() ?? 0.0,
      prima: (json['prima'] as num?)?.toDouble() ?? 0.0,
      cesantias: (json['cesantias'] as num?)?.toDouble() ?? 0.0,
      interesesCesantias: (json['intereses_cesantias'] as num?)?.toDouble() ?? 0.0,
      vacaciones: (json['vacaciones'] as num?)?.toDouble() ?? 0.0,
      dotacionProvision: (json['dotacion_provision'] as num?)?.toDouble() ?? 0.0,
      costoTotalEmpresa: (json['costo_total_empresa'] as num?)?.toDouble() ?? 0.0,
      fechaPago: json['fecha_pago'] != null ? DateTime.parse(json['fecha_pago'] as String) : DateTime.now(),
      estado: json['estado'] as String? ?? 'Pagado',
      creadoEn: json['creado_en'] != null ? DateTime.parse(json['creado_en'] as String) : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'empresa_id': empresaId,
        'unidad_acuicola_id': unidadAcuicolaId,
        'empleado_id': empleadoId,
        'empleado_nombre': empleadoNombre,
        'periodo': periodo,
        'salario_base': salarioBase,
        'auxilio_transporte': auxilioTransporte,
        'recargos_extras': recargosExtras,
        'pension_patronal': pensionPatronal,
        'arl': arl,
        'caja_compensacion': cajaCompensacion,
        'prima': prima,
        'cesantias': cesantias,
        'intereses_cesantias': interesesCesantias,
        'vacaciones': vacaciones,
        'dotacion_provision': dotacionProvision,
        'costo_total_empresa': costoTotalEmpresa,
        'fecha_pago': fechaPago.toIso8601String().split('T')[0],
        'estado': estado,
      };
}
