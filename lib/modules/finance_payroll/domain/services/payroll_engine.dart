import 'package:flutter/foundation.dart';
import '../models/payroll_config.dart';
import '../models/payroll_record.dart';

/// Resultado detallado e inmutable de la liquidación laboral y parafiscal
@immutable
class PayrollCalculationResult {
  final double salarioBase;
  final double auxilioTransporte;
  final double recargosExtras;
  final double baseCotizacion;
  final double basePrestaciones;

  // Deducciones al Trabajador (8%)
  final double saludTrabajador;
  final double pensionTrabajador;
  final double totalDeduccionesTrabajador;
  final double netoPagarTrabajador;

  // Cargas y Seguridad Social Patronal
  final double saludPatronal;
  final double pensionPatronal;
  final double arl;
  final double cajaCompensacion;
  final double totalSeguridadSocialPatronal;

  // Provisiones de Prestaciones Sociales (Ley Colombiana)
  final double prima;
  final double cesantias;
  final double interesesCesantias;
  final double vacaciones;
  final double dotacion;
  final double totalProvisiones;

  // Costo Real Total para la Empresa
  final double costoTotalEmpresa;

  const PayrollCalculationResult({
    required this.salarioBase,
    required this.auxilioTransporte,
    required this.recargosExtras,
    required this.baseCotizacion,
    required this.basePrestaciones,
    required this.saludTrabajador,
    required this.pensionTrabajador,
    required this.totalDeduccionesTrabajador,
    required this.netoPagarTrabajador,
    required this.saludPatronal,
    required this.pensionPatronal,
    required this.arl,
    required this.cajaCompensacion,
    required this.totalSeguridadSocialPatronal,
    required this.prima,
    required this.cesantias,
    required this.interesesCesantias,
    required this.vacaciones,
    required this.dotacion,
    required this.totalProvisiones,
    required this.costoTotalEmpresa,
  });
}

/// Motor puro de cálculo de nómina, seguridad social y costos laborales agropecuarios (Ley Colombiana)
class PayrollEngine {
  const PayrollEngine._();

  /// Liquida los conceptos salariales, deducciones y cargas patronales de un colaborador
  static PayrollCalculationResult calculate({
    required double salarioBase,
    double auxilioTransporte = 0.0,
    double recargosExtras = 0.0,
    required PayrollConfig config,
    ArlRiskClass? arlClass,
    String periodo = 'Quincenal',
  }) {
    final arl = arlClass ?? config.arlDefault;
    final baseCotizacion = salarioBase + recargosExtras;
    final basePrestaciones = baseCotizacion + auxilioTransporte;

    // 1. Deducciones Trabajador (4% Salud + 4% Pensión)
    final saludTrabajador = baseCotizacion * 0.04;
    final pensionTrabajador = baseCotizacion * 0.04;
    final totalDeduccionesTrabajador = saludTrabajador + pensionTrabajador;
    final netoPagarTrabajador = (basePrestaciones - totalDeduccionesTrabajador).clamp(0.0, double.infinity);

    // 2. Seguridad Social Patronal
    final saludPatronal = config.aplicaExoneracionLey1607 ? 0.0 : (baseCotizacion * config.porcentajeSaludPatronal);
    final pensionPatronal = baseCotizacion * config.porcentajePensionPatronal;
    final arlMonto = baseCotizacion * arl.percentage;
    final cajaCompensacion = baseCotizacion * config.porcentajeCajaCompensacion;
    final totalSeguridadSocialPatronal = saludPatronal + pensionPatronal + arlMonto + cajaCompensacion;

    // 3. Provisiones de Prestaciones Sociales
    final prima = basePrestaciones * 0.0833;
    final cesantias = basePrestaciones * 0.0833;
    final interesesCesantias = cesantias * 0.12;
    final vacaciones = baseCotizacion * 0.0416;
    final dotacion = periodo.toLowerCase() == 'quincenal'
        ? (config.dotacionProvisionMensual / 2.0)
        : config.dotacionProvisionMensual;

    final totalProvisiones = prima + cesantias + interesesCesantias + vacaciones + dotacion;

    // 4. Costo Total Empresa
    final costoTotalEmpresa = basePrestaciones + totalSeguridadSocialPatronal + totalProvisiones;

    return PayrollCalculationResult(
      salarioBase: salarioBase,
      auxilioTransporte: auxilioTransporte,
      recargosExtras: recargosExtras,
      baseCotizacion: baseCotizacion,
      basePrestaciones: basePrestaciones,
      saludTrabajador: saludTrabajador,
      pensionTrabajador: pensionTrabajador,
      totalDeduccionesTrabajador: totalDeduccionesTrabajador,
      netoPagarTrabajador: netoPagarTrabajador,
      saludPatronal: saludPatronal,
      pensionPatronal: pensionPatronal,
      arl: arlMonto,
      cajaCompensacion: cajaCompensacion,
      totalSeguridadSocialPatronal: totalSeguridadSocialPatronal,
      prima: prima,
      cesantias: cesantias,
      interesesCesantias: interesesCesantias,
      vacaciones: vacaciones,
      dotacion: dotacion,
      totalProvisiones: totalProvisiones,
      costoTotalEmpresa: costoTotalEmpresa,
    );
  }

  /// Construye un PayrollRecord a partir del cálculo
  static PayrollRecord createRecord({
    required String id,
    required String empresaId,
    required String unidadAcuicolaId,
    required String empleadoId,
    required String empleadoNombre,
    required String periodo,
    required DateTime fechaPago,
    required PayrollCalculationResult calc,
  }) {
    return PayrollRecord(
      id: id,
      empresaId: empresaId,
      unidadAcuicolaId: unidadAcuicolaId,
      empleadoId: empleadoId,
      empleadoNombre: empleadoNombre,
      periodo: periodo,
      salarioBase: calc.salarioBase,
      auxilioTransporte: calc.auxilioTransporte,
      recargosExtras: calc.recargosExtras,
      pensionPatronal: calc.pensionPatronal,
      arl: calc.arl,
      cajaCompensacion: calc.cajaCompensacion,
      prima: calc.prima,
      cesantias: calc.cesantias,
      interesesCesantias: calc.interesesCesantias,
      vacaciones: calc.vacaciones,
      dotacionProvision: calc.dotacion,
      costoTotalEmpresa: calc.costoTotalEmpresa,
      fechaPago: fechaPago,
      creadoEn: DateTime.now(),
    );
  }
}
