import '../models/production_cost_summary.dart';
import '../../../ponds_batches/domain/models/pond.dart';
import '../../../ponds_batches/domain/models/fish_batch.dart';
import '../models/jornal_record.dart';

/// Motor de cálculo de Costos Productivos, Unit Economics y Rentabilidad (Precision Aquaculture)
class ProductionCostEngine {
  const ProductionCostEngine._();

  /// Calcula el resumen consolidado de costos productivos para la granja y por estanque
  static ProductionCostSummary calculate({
    required List<Pond> ponds,
    List<FishBatch> batches = const [],
    List<JornalRecord> jornalesList = const [],
    required double totalAlimentoInsumos,
    required double totalNominaFija,
    required double totalJornales,
    required double totalEnergia,
    required double totalDepreciacionCapex,
    double precioMercadoKg = 10500.0,
    Map<String, double> preciosPorEspecie = const {},
    // Parámetros para la radiografía de inversión patrimonial
    double inventarioAlimentoBodega = 0.0,
    double inventarioFarmaciaBodega = 0.0,
    double activosFijosEquiposValorTotal = 0.0,
    double totalGastosOperativosMes = 0.0,
  }) {
    final activePonds = ponds.where((p) => !p.isDeleted && p.estado == PondStatus.active).toList();
    final effectivePonds = activePonds.isNotEmpty ? activePonds : ponds.where((p) => !p.isDeleted).toList();
    final activeBatches = batches.where((b) => b.estado == BatchStatus.active).toList();

    // 1. Biomasa Total Viva
    final totalBiomasaKg = effectivePonds.fold(0.0, (sum, p) => sum + p.biomasaKg);
    final biomasaCalculo = totalBiomasaKg > 0 ? totalBiomasaKg : (effectivePonds.length * 100.0 > 0 ? effectivePonds.length * 100.0 : 1000.0);

    // 2. Costo Directo de Alevinos/Semilla
    // Si existen lotes activos, se suma únicamente `costoInicialAlevinos` porque
    // `pond.costoAcumuladoBiologico` ya incluye semilla + alimento acumulado (evita doble conteo).
    final totalAlevines = activeBatches.isNotEmpty
        ? activeBatches.fold(0.0, (sum, b) => sum + b.costoInicialAlevinos)
        : effectivePonds.fold(0.0, (sum, p) => sum + p.costoAcumuladoBiologico);

    // 3. Costo Directo de Alimento (si no hay facturas registradas aún, estimar basado en biomasa y FCR típico 1.35)
    final alimentoReal = totalAlimentoInsumos > 0
        ? totalAlimentoInsumos
        : (totalBiomasaKg * 1.35 * 4500.0);

    // 4. Separación de Jornales: Directos a Estanque vs Indirectos Generales
    // Si un jornal tiene estanqueId, se asigna 100% como costo directo de ese estanque.
    // Los jornales sin estanqueId se suman a los costos indirectos generales de la granja.
    double totalJornalesDirectos = 0.0;
    final Map<String, double> jornalesPorEstanque = {};
    for (final j in jornalesList) {
      if (j.estanqueId != null && j.estanqueId!.isNotEmpty) {
        totalJornalesDirectos += j.totalPagado;
        jornalesPorEstanque[j.estanqueId!] = (jornalesPorEstanque[j.estanqueId!] ?? 0.0) + j.totalPagado;
      }
    }

    final double jornalesIndirectosGenerales = (totalJornales > totalJornalesDirectos)
        ? (totalJornales - totalJornalesDirectos)
        : (jornalesList.where((j) => j.estanqueId == null || j.estanqueId!.isEmpty).fold(0.0, (sum, j) => sum + j.totalPagado));

    final totalDirectos = totalAlevines + alimentoReal + totalJornalesDirectos;

    // 5. Costos Indirectos / Fijos (Mano de obra fija + jornales generales + energía + capex)
    final manoObraFija = totalNominaFija > 0 ? totalNominaFija : 0.0;
    final energia = totalEnergia > 0 ? totalEnergia : 0.0;
    final capex = totalDepreciacionCapex > 0 ? totalDepreciacionCapex : 0.0;

    final totalIndirectos = manoObraFija + jornalesIndirectosGenerales + energia + capex;
    final costoTotalProduccion = totalDirectos + totalIndirectos;

    // 6. Unit Economics (COP/Kg)
    final cpkDirecto = totalDirectos / biomasaCalculo;
    final cpkTotal = costoTotalProduccion / biomasaCalculo;

    // 7. Márgenes
    final margenBrutoKg = precioMercadoKg - cpkTotal;
    final margenPorcentaje = precioMercadoKg > 0 ? (margenBrutoKg / precioMercadoKg) * 100.0 : 0.0;

    // 8. Punto de Equilibrio (Break-Even)
    final margenContribucionUnitario = precioMercadoKg - cpkDirecto;
    final double puntoEquilibrioKg;
    if (margenContribucionUnitario > 0) {
      puntoEquilibrioKg = totalIndirectos / margenContribucionUnitario;
    } else {
      puntoEquilibrioKg = double.infinity;
    }
    final puntoEquilibrioCOP = puntoEquilibrioKg.isFinite ? puntoEquilibrioKg * precioMercadoKg : 0.0;

    // 9. Desglose por Estanque Individual
    final Map<String, List<FishBatch>> activeBatchesByPond = {};
    for (final b in activeBatches) {
      activeBatchesByPond.putIfAbsent(b.estanqueId, () => []).add(b);
    }

    final estanquesBreakdown = <PondCostBreakdown>[];
    for (final p in effectivePonds) {
      final pesoPonderadoBiomasa = totalBiomasaKg > 0
          ? (p.biomasaKg / totalBiomasaKg)
          : (1.0 / (effectivePonds.isNotEmpty ? effectivePonds.length : 1));

      final pondBatches = activeBatchesByPond[p.id];
      final hasPondBatches = pondBatches != null && pondBatches.isNotEmpty;
      final alevinesEstanque = hasPondBatches
          ? pondBatches.fold(0.0, (sum, b) => sum + b.costoInicialAlevinos)
          : p.costoAcumuladoBiologico;
      final insumosLotesEstanque = hasPondBatches
          ? pondBatches.fold(0.0, (sum, b) => sum + b.costoAcumuladoInsumos)
          : 0.0;
      // Asignar alimento real del lote si existe, o proporcionalmente a la biomasa
      final alimentoEstanque = insumosLotesEstanque > 0
          ? insumosLotesEstanque
          : (alimentoReal * pesoPonderadoBiomasa);
      final jornalesDirectosPond = jornalesPorEstanque[p.id] ?? 0.0;
      final directosEstanque = alimentoEstanque + alevinesEstanque + jornalesDirectosPond;

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

    // 10. Desglose por Especie (Multi-Species Breakdown)
    final Map<String, _SpeciesAccumulator> speciesMap = {};

    // Agrupar a partir de lotes activos si existen
    if (activeBatches.isNotEmpty) {
      for (final b in activeBatches) {
        final esp = b.especie.isNotEmpty ? b.especie : 'Tilapia Roja';
        final acc = speciesMap.putIfAbsent(esp, () => _SpeciesAccumulator(esp));
        acc.totalPeces += b.cantidadActualPeces;
        acc.totalBiomasaKg += b.biomasaActualKg;
        acc.costoDirectoAlevines += b.costoInicialAlevinos;
        acc.costoDirectoAlimento += b.costoAcumuladoInsumos;
        acc.estanqueIds.add(b.estanqueId);
      }
    } else {
      // Fallback a nivel de estanques
      for (final p in effectivePonds) {
        final esp = p.especieActual.isNotEmpty ? p.especieActual : 'Tilapia Roja';
        final acc = speciesMap.putIfAbsent(esp, () => _SpeciesAccumulator(esp));
        acc.totalBiomasaKg += p.biomasaKg;
        acc.costoDirectoAlevines += p.costoAcumuladoBiologico;
        final peso = totalBiomasaKg > 0 ? (p.biomasaKg / totalBiomasaKg) : (1.0 / effectivePonds.length);
        acc.costoDirectoAlimento += alimentoReal * peso;
        acc.estanqueIds.add(p.id);
      }
    }

    final especiesBreakdown = <SpeciesCostBreakdown>[];
    for (final acc in speciesMap.values) {
      final pesoEspecie = totalBiomasaKg > 0 ? (acc.totalBiomasaKg / totalBiomasaKg) : (1.0 / speciesMap.length);

      // Sumar jornales directos asignados a los estanques de esta especie
      double directJornalesEspecie = 0.0;
      for (final pId in acc.estanqueIds) {
        directJornalesEspecie += (jornalesPorEstanque[pId] ?? 0.0);
      }

      // Indirectos prorrateados por biomasa de la especie
      final indirectosEspecie = totalIndirectos * pesoEspecie;
      final costoTotalEspecie = acc.costoDirectoAlevines + acc.costoDirectoAlimento + directJornalesEspecie + indirectosEspecie;
      final biomasaEsp = acc.totalBiomasaKg > 0 ? acc.totalBiomasaKg : 1.0;

      final cpkDirectoEsp = (acc.costoDirectoAlevines + acc.costoDirectoAlimento + directJornalesEspecie) / biomasaEsp;
      final cpkTotalEsp = costoTotalEspecie / biomasaEsp;

      final precioEsp = preciosPorEspecie[acc.especie] ?? precioMercadoKg;
      final margenKgEsp = precioEsp - cpkTotalEsp;
      final margenPctEsp = precioEsp > 0 ? (margenKgEsp / precioEsp) * 100.0 : 0.0;
      final utilidadTotalEsp = (acc.totalBiomasaKg * precioEsp) - costoTotalEspecie;
      final roiEsp = costoTotalEspecie > 0 ? (utilidadTotalEsp / costoTotalEspecie) * 100.0 : 0.0;

      especiesBreakdown.add(
        SpeciesCostBreakdown(
          especie: acc.especie,
          totalPeces: acc.totalPeces,
          totalBiomasaKg: acc.totalBiomasaKg,
          estanquesCount: acc.estanqueIds.length,
          costoDirectoAlevines: acc.costoDirectoAlevines,
          costoDirectoAlimento: acc.costoDirectoAlimento,
          costoDirectoJornales: directJornalesEspecie,
          costoIndirectosProrrateados: indirectosEspecie,
          costoTotal: costoTotalEspecie,
          cpkDirecto: cpkDirectoEsp,
          cpkTotal: cpkTotalEsp,
          precioVentaKg: precioEsp,
          margenKg: margenKgEsp,
          margenPorcentaje: margenPctEsp,
          utilidadTotalEstimada: utilidadTotalEsp,
          roiPorcentaje: roiEsp,
        ),
      );
    }

    // 11. Radiografía de Inversión Patrimonial (FarmInvestmentSummary)
    final farmInvestment = FarmInvestmentSummary(
      capitalEnAguaAlevines: totalAlevines,
      capitalEnAguaAlimento: alimentoReal,
      capitalEnAguaTotal: totalAlevines + alimentoReal,
      inventarioAlimentoBodega: inventarioAlimentoBodega,
      inventarioFarmaciaBodega: inventarioFarmaciaBodega,
      inventarioBodegaTotal: inventarioAlimentoBodega + inventarioFarmaciaBodega,
      activosFijosEquiposValorTotal: activosFijosEquiposValorTotal,
      depreciacionAcumuladaEstimada: totalDepreciacionCapex,
      activosFijosNetos: (activosFijosEquiposValorTotal - totalDepreciacionCapex) > 0
          ? (activosFijosEquiposValorTotal - totalDepreciacionCapex)
          : activosFijosEquiposValorTotal,
      totalGastosOperativosMes: totalGastosOperativosMes > 0 ? totalGastosOperativosMes : totalIndirectos,
    );

    return ProductionCostSummary(
      totalBiomasaKg: totalBiomasaKg,
      totalEstanquesActivos: effectivePonds.length,
      totalCostoAlevinos: totalAlevines,
      totalCostoAlimento: alimentoReal,
      totalCostosDirectos: totalDirectos,
      totalCostoNomina: manoObraFija,
      totalCostoJornales: totalJornales,
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
      especiesBreakdown: especiesBreakdown,
      investmentSummary: farmInvestment,
    );
  }

  /// Simula la sensibilidad ante variaciones en el precio del alimento (%) o del FCR
  static ProductionCostSummary simulateSensitivity({
    required ProductionCostSummary currentSummary,
    required List<Pond> ponds,
    List<FishBatch> batches = const [],
    List<JornalRecord> jornalesList = const [],
    double factorAlimento = 1.0, // 1.10 = +10% en costo de alimento
    double fcrDelta = 0.0, // +0.2 en FCR
    double nuevoPrecioMercado = 10500.0,
  }) {
    final alimentoAjustado = currentSummary.totalCostoAlimento * factorAlimento * (1.0 + fcrDelta);

    return calculate(
      ponds: ponds,
      batches: batches,
      jornalesList: jornalesList,
      totalAlimentoInsumos: alimentoAjustado,
      totalNominaFija: currentSummary.totalCostoNomina,
      totalJornales: currentSummary.totalCostoJornales,
      totalEnergia: currentSummary.totalCostoEnergia,
      totalDepreciacionCapex: currentSummary.totalDepreciacionCapex,
      precioMercadoKg: nuevoPrecioMercado,
    );
  }
}

class _SpeciesAccumulator {
  final String especie;
  int totalPeces = 0;
  double totalBiomasaKg = 0.0;
  final Set<String> estanqueIds = {};
  double costoDirectoAlevines = 0.0;
  double costoDirectoAlimento = 0.0;

  _SpeciesAccumulator(this.especie);
}

