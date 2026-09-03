import '../models/production_cost_summary.dart';
import '../../../ponds_batches/domain/models/pond.dart';

/// Motor de cálculo de Costos Productivos, Unit Economics y Rentabilidad (Precision Aquaculture)
class ProductionCostEngine {
  const ProductionCostEngine._();

  /// Calcula el resumen consolidado de costos productivos para la granja y por estanque
  static ProductionCostSummary calculate({
    required List<Pond> ponds,
    required double totalAlimentoInsumos,
    required double totalNominaFija,
    required double totalJornales,
    required double totalEnergia,
    required double totalDepreciacionCapex,
    double precioMercadoKg = 10500.0,
  }) {
    final activePonds = ponds.where((p) => !p.isDeleted && p.estado == PondStatus.active).toList();
    final effectivePonds = activePonds.isNotEmpty ? activePonds : ponds.where((p) => !p.isDeleted).toList();

    // 1. Biomasa Total Viva
    final totalBiomasaKg = effectivePonds.fold(0.0, (sum, p) => sum + p.biomasaKg);
    final biomasaCalculo = totalBiomasaKg > 0 ? totalBiomasaKg : (effectivePonds.length * 100.0 > 0 ? effectivePonds.length * 100.0 : 1000.0);

    // 2. Costo Directo de Alevinos/Semilla (Costo biológico acumulado en estanques)
    final totalAlevines = effectivePonds.fold(0.0, (sum, p) => sum + p.costoAcumuladoBiologico);

    // 3. Costo Directo de Alimento (si no hay facturas registradas aún, estimar basado en biomasa y FCR típico 1.35)
    final alimentoReal = totalAlimentoInsumos > 0
        ? totalAlimentoInsumos
        : (totalBiomasaKg * 1.35 * 4500.0);

    final totalDirectos = totalAlevines + alimentoReal;

    // 4. Costos Indirectos / Fijos
    final manoObraFija = totalNominaFija > 0 ? totalNominaFija : 0.0;
    final jornales = totalJornales > 0 ? totalJornales : 0.0;
    final energia = totalEnergia > 0 ? totalEnergia : 0.0;
    final capex = totalDepreciacionCapex > 0 ? totalDepreciacionCapex : 0.0;

    final totalIndirectos = manoObraFija + jornales + energia + capex;
    final costoTotalProduccion = totalDirectos + totalIndirectos;

    // 5. Unit Economics (COP/Kg)
    final cpkDirecto = totalDirectos / biomasaCalculo;
    final cpkTotal = costoTotalProduccion / biomasaCalculo;

    // 6. Márgenes
    final margenBrutoKg = precioMercadoKg - cpkTotal;
    final margenPorcentaje = precioMercadoKg > 0 ? (margenBrutoKg / precioMercadoKg) * 100.0 : 0.0;

    // 7. Punto de Equilibrio (Break-Even)
    // Margen de contribución unitario sobre costos variables = Precio - CPK Directo
    final margenContribucionUnitario = precioMercadoKg - cpkDirecto;
    final double puntoEquilibrioKg;
    if (margenContribucionUnitario > 0) {
      puntoEquilibrioKg = totalIndirectos / margenContribucionUnitario;
    } else {
      puntoEquilibrioKg = double.infinity;
    }
    final puntoEquilibrioCOP = puntoEquilibrioKg.isFinite ? puntoEquilibrioKg * precioMercadoKg : 0.0;

    // 8. Desglose por Estanque Individual (Prorrateo de costos indirectos por peso de biomasa)
    final estanquesBreakdown = <PondCostBreakdown>[];
    for (final p in effectivePonds) {
      final pesoPonderadoBiomasa = totalBiomasaKg > 0
          ? (p.biomasaKg / totalBiomasaKg)
          : (1.0 / (effectivePonds.isNotEmpty ? effectivePonds.length : 1));

      // Asignar alimento proporcionalmente a la biomasa
      final alimentoEstanque = alimentoReal * pesoPonderadoBiomasa;
      final alevinesEstanque = p.costoAcumuladoBiologico;
      final directosEstanque = alimentoEstanque + alevinesEstanque;

      // Prorratear indirectos por peso de biomasa
      final indirectosEstanque = totalIndirectos * pesoPonderadoBiomasa;
      final totalEstanque = directosEstanque + indirectosEstanque;

      final biomasaPond = p.biomasaKg > 0 ? p.biomasaKg : 1.0;
      final cpkDirectoPond = directosEstanque / biomasaPond;
      final cpkTotalPond = totalEstanque / biomasaPond;
      final margenPond = precioMercadoKg - cpkTotalPond;
      final margenPctPond = precioMercadoKg > 0 ? (margenPond / precioMercadoKg) * 100.0 : 0.0;

      estanquesBreakdown.add(
        PondCostBreakdown(
          pondId: p.id,
          pondName: p.nombreLimpio,
          biomasaKg: p.biomasaKg,
          costoDirectoAlevines: alevinesEstanque,
          costoDirectoAlimento: alimentoEstanque,
          costoIndirectoAsignado: indirectosEstanque,
          costoTotal: totalEstanque,
          cpkDirecto: cpkDirectoPond,
          cpkTotal: cpkTotalPond,
          margenKg: margenPond,
          margenPorcentaje: margenPctPond,
        ),
      );
    }

    return ProductionCostSummary(
      totalBiomasaKg: totalBiomasaKg,
      totalEstanquesActivos: effectivePonds.length,
      totalCostoAlevinos: totalAlevines,
      totalCostoAlimento: alimentoReal,
      totalCostosDirectos: totalDirectos,
      totalCostoNomina: manoObraFija,
      totalCostoJornales: jornales,
      totalCostoEnergia: energia,
      totalDepreciacionCapex: capex,
      totalCostosIndirectos: totalIndirectos,
      costoTotalProduccion: costoTotalProduccion,
      cpkDirecto: cpkDirecto,
      cpkTotal: cpkTotal,
      precioMercadoKg: precioMercadoKg,
      margenBrutoKg: margenBrutoKg,
      margenPorcentaje: margenPorcentaje,
      puntoEquilibrioKg: puntoEquilibrioKg,
      puntoEquilibrioCOP: puntoEquilibrioCOP,
      estanquesBreakdown: estanquesBreakdown,
    );
  }

  /// Simula la sensibilidad ante variaciones en el precio del alimento (%) o del FCR
  static ProductionCostSummary simulateSensitivity({
    required ProductionCostSummary currentSummary,
    required List<Pond> ponds,
    double factorAlimento = 1.0, // 1.10 = +10% en costo de alimento
    double fcrDelta = 0.0, // +0.2 en FCR
    double nuevoPrecioMercado = 10500.0,
  }) {
    final alimentoAjustado = currentSummary.totalCostoAlimento * factorAlimento * (1.0 + fcrDelta);

    return calculate(
      ponds: ponds,
      totalAlimentoInsumos: alimentoAjustado,
      totalNominaFija: currentSummary.totalCostoNomina,
      totalJornales: currentSummary.totalCostoJornales,
      totalEnergia: currentSummary.totalCostoEnergia,
      totalDepreciacionCapex: currentSummary.totalDepreciacionCapex,
      precioMercadoKg: nuevoPrecioMercado,
    );
  }
}
