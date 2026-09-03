import 'package:flutter_test/flutter_test.dart';
import 'package:fishbit_finance/modules/finance_payroll/domain/services/production_cost_engine.dart';
import 'package:fishbit_finance/modules/ponds_batches/domain/models/pond.dart';

void main() {
  group('ProductionCostEngine Tests', () {
    test('Calcula Unit Economics y CPK correctamente con biomasa activa', () {
      final ponds = [
        Pond(
          id: 'pond-1',
          empresaId: 'emp-1',
          unidadAcuicolaId: 'u-1',
          nombre: 'Estanque 1',
          sigla: 'EST-1',
          capacidadM3: 50.0,
          biomasaKg: 1000.0,
          costoAcumuladoBiologico: 500000.0,
          estado: PondStatus.active,
          creadoEn: DateTime(2026, 1, 1),
        ),
        Pond(
          id: 'pond-2',
          empresaId: 'emp-1',
          unidadAcuicolaId: 'u-1',
          nombre: 'Estanque 2',
          sigla: 'EST-2',
          capacidadM3: 50.0,
          biomasaKg: 1000.0,
          costoAcumuladoBiologico: 500000.0,
          estado: PondStatus.active,
          creadoEn: DateTime(2026, 1, 1),
        ),
      ];

      final summary = ProductionCostEngine.calculate(
        ponds: ponds,
        totalAlimentoInsumos: 6000000.0, // $6.000.000
        totalNominaFija: 2000000.0,      // $2.000.000
        totalJornales: 500000.0,         // $500.000
        totalEnergia: 500000.0,          // $500.000
        totalDepreciacionCapex: 200000.0,// $200.000
        precioMercadoKg: 10000.0,        // $10.000 / kg
      );

      // Biomasa total = 2000 kg
      expect(summary.totalBiomasaKg, 2000.0);
      expect(summary.totalEstanquesActivos, 2);

      // Costos Directos = 1.000.000 (alevines) + 6.000.000 (alimento) = 7.000.000
      expect(summary.totalCostosDirectos, 7000000.0);
      expect(summary.cpkDirecto, 3500.0); // 7.000.000 / 2000

      // Costos Indirectos = 2.000.000 + 500.000 + 500.000 + 200.000 = 3.200.000
      expect(summary.totalCostosIndirectos, 3200000.0);

      // Costo Total = 10.200.000
      expect(summary.costoTotalProduccion, 10200000.0);
      expect(summary.cpkTotal, 5100.0); // 10.200.000 / 2000

      // Margen Bruto: 10.000 - 5.100 = 4.900 / kg (49%)
      expect(summary.margenBrutoKg, 4900.0);
      expect(summary.margenBrutoPorcentaje, 49.0);

      // Punto de Equilibrio:
      // Margen contribución = 10.000 - 3.500 = 6.500
      // Indirectos / 6.500 = 3.200.000 / 6.500 ≈ 492.30 kg
      expect(summary.puntoEquilibrioKg, closeTo(492.3, 0.1));

      // Desglose por estanque
      expect(summary.estanquesBreakdown.length, 2);
      expect(summary.estanquesBreakdown.first.cpkTotal, 5100.0);
    });

    test('Maneja casos borde de biomasa cero sin errores ni divisiones por cero', () {
      final summary = ProductionCostEngine.calculate(
        ponds: [],
        totalAlimentoInsumos: 0.0,
        totalNominaFija: 0.0,
        totalJornales: 0.0,
        totalEnergia: 0.0,
        totalDepreciacionCapex: 0.0,
        precioMercadoKg: 10000.0,
      );

      expect(summary.totalBiomasaKg, 0.0);
      expect(summary.costoTotalProduccion, 0.0);
      expect(summary.cpkTotal, isNot(isNaN));
      expect(summary.margenBrutoPorcentaje, 100.0);
    });
  });
}
