import 'package:flutter_test/flutter_test.dart';
import 'package:fishbit_finance/modules/finance_payroll/domain/models/payroll_config.dart';
import 'package:fishbit_finance/modules/finance_payroll/domain/services/payroll_engine.dart';

void main() {
  group('PayrollEngine Tests', () {
    const config = PayrollConfig(
      aplicaExoneracionLey1607: true,
      arlDefault: ArlRiskClass.claseIII, // 2.436%
      porcentajePensionPatronal: 0.12,
      porcentajeCajaCompensacion: 0.04,
      porcentajeSaludPatronal: 0.085,
      auxilioTransporteMensual: 162000.0,
      dotacionProvisionMensual: 35000.0,
    );

    test('Calcula liquidación quincenal estándar con Ley 1607 (exoneración salud)', () {
      final res = PayrollEngine.calculate(
        salarioBase: 700000.0, // Quincena de $1.400.000
        auxilioTransporte: 81000.0,
        recargosExtras: 0.0,
        config: config,
        periodo: 'Quincenal',
      );

      // Deducciones trabajador (4% Salud + 4% Pensión de $700.000 = $28.000 c/u -> $56.000)
      expect(res.saludTrabajador, 28000.0);
      expect(res.pensionTrabajador, 28000.0);
      expect(res.totalDeduccionesTrabajador, 56000.0);

      // Neto a pagar = (700.000 + 81.000) - 56.000 = 725.000
      expect(res.netoPagarTrabajador, 725000.0);

      // Salud patronal exenta por Ley 1607
      expect(res.saludPatronal, 0.0);

      // Pensión patronal (12% de 700.000) = 84.000
      expect(res.pensionPatronal, 84000.0);

      // ARL Clase III (2.436% de 700.000) = 17.052
      expect(res.arl, closeTo(17052.0, 0.01));

      // Caja de compensación (4% de 700.000) = 28.000
      expect(res.cajaCompensacion, 28000.0);

      // Provisiones sobre base de prestaciones ($781.000)
      // Prima (8.33% de 781.000) ≈ 65.057,3
      expect(res.prima, closeTo(65057.3, 0.1));

      // Costo empresa debe ser mayor que el sueldo base
      expect(res.costoTotalEmpresa, greaterThan(res.salarioBase));
    });

    test('Calcula salud patronal si no aplica exoneración Ley 1607', () {
      final configSinExoneracion = config.copyWith(aplicaExoneracionLey1607: false);
      final res = PayrollEngine.calculate(
        salarioBase: 1000000.0,
        config: configSinExoneracion,
      );

      // 8.5% de 1.000.000 = 85.000
      expect(res.saludPatronal, 85000.0);
    });
  });
}
