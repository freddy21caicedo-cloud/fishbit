/// Estructura de desglose de nómina legal (Colombia 2026)
class PayrollBreakdown {
  final double salarioBase;
  final double auxilioTransporte;
  final double recargosExtras;
  final double saludPatronal; // Exonerado Art 114-1 ET si < 10 SMLMV
  final double pensionPatronal; // 12%
  final double arl; // Nivel II (1.044%) o Nivel III (2.436%)
  final double sena; // Exonerado
  final double icbf; // Exonerado
  final double cajaCompensacion; // 4%
  final double prima; // 8.33%
  final double cesantias; // 8.33%
  final double interesesCesantias; // 1% mensual sobre cesantías (12% anual)
  final double vacaciones; // 4.17%
  final double dotacionProvision;
  final double costoTotalEmpresa;

  const PayrollBreakdown({
    required this.salarioBase,
    required this.auxilioTransporte,
    required this.recargosExtras,
    required this.saludPatronal,
    required this.pensionPatronal,
    required this.arl,
    required this.sena,
    required this.icbf,
    required this.cajaCompensacion,
    required this.prima,
    required this.cesantias,
    required this.interesesCesantias,
    required this.vacaciones,
    required this.dotacionProvision,
    required this.costoTotalEmpresa,
  });
}

/// Calculadora de costos laborales y provisiones para piscicultura
class PayrollCalculator {
  PayrollCalculator._();

  static const double smlmv2026 = 1423500.0;
  static const double auxTransporte2026 = 200000.0;

  static PayrollBreakdown calculate({
    required double salarioBase,
    required String periodo, // 'Quincenal' o 'Mensual'
    double recargosExtras = 0.0,
    String riesgoArl = 'II', // 'II' = 1.044%, 'III' = 2.436%
  }) {
    final factorPeriodo = periodo == 'Quincenal' ? 0.5 : 1.0;
    final basePeriodo = salarioBase * factorPeriodo;
    
    // Auxilio de transporte aplica si el salario es <= 2 SMLMV
    final aplicaAuxilio = salarioBase <= (smlmv2026 * 2);
    final auxilio = aplicaAuxilio ? (auxTransporte2026 * factorPeriodo) : 0.0;

    final baseSalarialConExtras = basePeriodo + recargosExtras;
    final basePrestacional = baseSalarialConExtras + auxilio;

    // Seguridad Social Patronal
    final pension = baseSalarialConExtras * 0.12;
    final tasaArl = riesgoArl == 'III' ? 0.02436 : 0.01044;
    final arl = baseSalarialConExtras * tasaArl;

    // Parafiscales
    final caja = baseSalarialConExtras * 0.04;

    // Prestaciones Sociales
    final prima = basePrestacional * 0.0833;
    final cesantias = basePrestacional * 0.0833;
    final interesesCesantias = cesantias * 0.12 * factorPeriodo;
    final vacaciones = baseSalarialConExtras * 0.0417; // Vacaciones no incluye aux transporte

    // Provisión de dotación acuícola (botas, overoles, guantes)
    final dotacion = 35000.0 * factorPeriodo;

    final costoTotal = basePrestacional +
        pension +
        arl +
        caja +
        prima +
        cesantias +
        interesesCesantias +
        vacaciones +
        dotacion;

    return PayrollBreakdown(
      salarioBase: basePeriodo,
      auxilioTransporte: auxilio,
      recargosExtras: recargosExtras,
      saludPatronal: 0.0,
      pensionPatronal: pension,
      arl: arl,
      sena: 0.0,
      icbf: 0.0,
      cajaCompensacion: caja,
      prima: prima,
      cesantias: cesantias,
      interesesCesantias: interesesCesantias,
      vacaciones: vacaciones,
      dotacionProvision: dotacion,
      costoTotalEmpresa: costoTotal,
    );
  }
}
