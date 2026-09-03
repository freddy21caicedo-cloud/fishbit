/// Niveles de riesgo ARL según Decreto 768 de 2022 en Colombia
enum ArlRiskClass {
  claseI,   // 0.522% - Administrativos / Oficina
  claseII,  // 1.044% - Ventas / Logística ligera
  claseIII, // 2.436% - Acuicultura & Piscicultura (CIIU 0322/0321)
  claseIV,  // 4.350% - Transporte de carga / Biomasa viva
  claseV,   // 6.960% - Construcción pesada / Alta tensión
}

extension ArlRiskClassExtension on ArlRiskClass {
  String get label {
    switch (this) {
      case ArlRiskClass.claseI:
        return 'Clase I (0.522%) - Administrativo / Oficina';
      case ArlRiskClass.claseII:
        return 'Clase II (1.044%) - Almacén / Comercial';
      case ArlRiskClass.claseIII:
        return 'Clase III (2.436%) - Acuícola / Campo Estándar';
      case ArlRiskClass.claseIV:
        return 'Clase IV (4.350%) - Transporte de Carga / Vivos';
      case ArlRiskClass.claseV:
        return 'Clase V (6.960%) - Construcción / Excavación';
    }
  }

  double get percentage {
    switch (this) {
      case ArlRiskClass.claseI:
        return 0.00522;
      case ArlRiskClass.claseII:
        return 0.01044;
      case ArlRiskClass.claseIII:
        return 0.02436;
      case ArlRiskClass.claseIV:
        return 0.04350;
      case ArlRiskClass.claseV:
        return 0.06960;
    }
  }

  static ArlRiskClass fromString(String? val) {
    if (val == null) return ArlRiskClass.claseIII;
    switch (val.toLowerCase()) {
      case 'clasei':
      case 'clase_i':
      case 'i':
        return ArlRiskClass.claseI;
      case 'claseii':
      case 'clase_ii':
      case 'ii':
        return ArlRiskClass.claseII;
      case 'claseiv':
      case 'clase_iv':
      case 'iv':
        return ArlRiskClass.claseIV;
      case 'clasev':
      case 'clase_v':
      case 'v':
        return ArlRiskClass.claseV;
      case 'claseiii':
      case 'clase_iii':
      case 'iii':
      default:
        return ArlRiskClass.claseIII;
    }
  }
}

/// Configuración paramétrica de Nómina y Seguridad Social de la Empresa
class PayrollConfig {
  final bool aplicaExoneracionLey1607; // Exento de Salud patronal (8.5%), SENA (2%) e ICBF (3%) si <10 SMMLV
  final ArlRiskClass arlDefault;       // Nivel ARL por defecto de la granja (Estándar: Clase III 2.436%)
  final double porcentajePensionPatronal; // 12.0%
  final double porcentajeCajaCompensacion;// 4.0%
  final double porcentajeSaludPatronal;   // 8.5% (si no aplica exoneración)
  final double auxilioTransporteMensual;  // $162.000 COP sugerido
  final double dotacionProvisionMensual;  // $35.000 COP sugerido
  final double tarifaJornalCampoDefecto;  // $65.000 COP / día sugerido

  const PayrollConfig({
    this.aplicaExoneracionLey1607 = true,
    this.arlDefault = ArlRiskClass.claseIII,
    this.porcentajePensionPatronal = 0.12,
    this.porcentajeCajaCompensacion = 0.04,
    this.porcentajeSaludPatronal = 0.085,
    this.auxilioTransporteMensual = 162000.0,
    this.dotacionProvisionMensual = 35000.0,
    this.tarifaJornalCampoDefecto = 65000.0,
  });

  factory PayrollConfig.fromJson(Map<String, dynamic> json) {
    return PayrollConfig(
      aplicaExoneracionLey1607: json['aplica_exoneracion_ley1607'] as bool? ?? true,
      arlDefault: ArlRiskClassExtension.fromString(json['arl_default'] as String?),
      porcentajePensionPatronal: (json['porcentaje_pension_patronal'] as num?)?.toDouble() ?? 0.12,
      porcentajeCajaCompensacion: (json['porcentaje_caja_compensacion'] as num?)?.toDouble() ?? 0.04,
      porcentajeSaludPatronal: (json['porcentaje_salud_patronal'] as num?)?.toDouble() ?? 0.085,
      auxilioTransporteMensual: (json['auxilio_transporte_mensual'] as num?)?.toDouble() ?? 162000.0,
      dotacionProvisionMensual: (json['dotacion_provision_mensual'] as num?)?.toDouble() ?? 35000.0,
      tarifaJornalCampoDefecto: (json['tarifa_jornal_campo_defecto'] as num?)?.toDouble() ?? 65000.0,
    );
  }

  Map<String, dynamic> toJson() => {
    'aplica_exoneracion_ley1607': aplicaExoneracionLey1607,
    'arl_default': arlDefault.name,
    'porcentaje_pension_patronal': porcentajePensionPatronal,
    'porcentaje_caja_compensacion': porcentajeCajaCompensacion,
    'porcentaje_salud_patronal': porcentajeSaludPatronal,
    'auxilio_transporte_mensual': auxilioTransporteMensual,
    'dotacion_provision_mensual': dotacionProvisionMensual,
    'tarifa_jornal_campo_defecto': tarifaJornalCampoDefecto,
  };

  PayrollConfig copyWith({
    bool? aplicaExoneracionLey1607,
    ArlRiskClass? arlDefault,
    double? porcentajePensionPatronal,
    double? porcentajeCajaCompensacion,
    double? porcentajeSaludPatronal,
    double? auxilioTransporteMensual,
    double? dotacionProvisionMensual,
    double? tarifaJornalCampoDefecto,
  }) {
    return PayrollConfig(
      aplicaExoneracionLey1607: aplicaExoneracionLey1607 ?? this.aplicaExoneracionLey1607,
      arlDefault: arlDefault ?? this.arlDefault,
      porcentajePensionPatronal: porcentajePensionPatronal ?? this.porcentajePensionPatronal,
      porcentajeCajaCompensacion: porcentajeCajaCompensacion ?? this.porcentajeCajaCompensacion,
      porcentajeSaludPatronal: porcentajeSaludPatronal ?? this.porcentajeSaludPatronal,
      auxilioTransporteMensual: auxilioTransporteMensual ?? this.auxilioTransporteMensual,
      dotacionProvisionMensual: dotacionProvisionMensual ?? this.dotacionProvisionMensual,
      tarifaJornalCampoDefecto: tarifaJornalCampoDefecto ?? this.tarifaJornalCampoDefecto,
    );
  }
}
