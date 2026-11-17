import 'package:flutter_test/flutter_test.dart';
import 'package:fishbit_finance/modules/finance_payroll/domain/services/production_cost_engine.dart';
import 'package:fishbit_finance/modules/finance_payroll/domain/models/jornal_record.dart';
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

    test('Calcula desglose por especie, jornales directos e inversión patrimonial', () {
      final ponds = [
        Pond(
          id: 'pond-tilapia',
          empresaId: 'emp-1',
          unidadAcuicolaId: 'u-1',
          nombre: 'Estanque Tilapia',
          sigla: 'EST-T',
          capacidadM3: 100.0,
          biomasaKg: 2000.0,
          especieActual: 'Tilapia Roja',
          costoAcumuladoBiologico: 1200000.0,
          estado: PondStatus.active,
          creadoEn: DateTime(2026, 1, 1),
        ),
        Pond(
          id: 'pond-cachama',
          empresaId: 'emp-1',
          unidadAcuicolaId: 'u-1',
          nombre: 'Estanque Cachama',
          sigla: 'EST-C',
          capacidadM3: 80.0,
          biomasaKg: 1000.0,
          especieActual: 'Cachama Blanca',
          costoAcumuladoBiologico: 600000.0,
          estado: PondStatus.active,
          creadoEn: DateTime(2026, 1, 1),
        ),
      ];

      final jornales = [
        JornalRecord(
          id: 'j-1',
          empresaId: 'emp-1',
          unidadAcuicolaId: 'u-1',
          estanqueId: 'pond-tilapia',
          laborRealizada: 'Pesca y Selección Tilapia',
          cantidadJornales: 2,
          valorPorJornal: 60000.0,
          totalPagado: 120000.0,
          fecha: DateTime(2026, 1, 15),
          creadoEn: DateTime(2026, 1, 15),
        ),
      ];

      final summary = ProductionCostEngine.calculate(
        ponds: ponds,
        jornalesList: jornales,
        totalAlimentoInsumos: 9000000.0,
        totalNominaFija: 3000000.0,
        totalJornales: 120000.0,
        totalEnergia: 600000.0,
        totalDepreciacionCapex: 400000.0,
        precioMercadoKg: 11000.0,
        inventarioAlimentoBodega: 4500000.0,
        inventarioFarmaciaBodega: 800000.0,
        activosFijosEquiposValorTotal: 15000000.0,
      );

      // Verificación de inversión patrimonial
      expect(summary.investmentSummary, isNotNull);
      final inv = summary.investmentSummary!;
      expect(inv.inventarioBodegaTotal, 5300000.0);
      expect(inv.capitalEnAguaAlevines, 1800000.0);
      expect(inv.capitalEnAguaTotal, 10800000.0); // 1.8M alevines + 9M alimento
      expect(inv.inversionTotalConsolidada, greaterThan(0.0));

      // Verificación de desglose multiespecie
      expect(summary.especiesBreakdown.length, 2);
      final tilapia = summary.especiesBreakdown.firstWhere((e) => e.especie == 'Tilapia Roja');
      final cachama = summary.especiesBreakdown.firstWhere((e) => e.especie == 'Cachama Blanca');

      expect(tilapia.totalBiomasaKg, 2000.0);
      expect(tilapia.costoDirectoJornales, 120000.0); // Jornal asignado directo
      expect(cachama.totalBiomasaKg, 1000.0);
      expect(cachama.costoDirectoJornales, 0.0);
      expect(summary.roiEstimadoPorcentaje, isNot(isNaN));
    });
  });
}
