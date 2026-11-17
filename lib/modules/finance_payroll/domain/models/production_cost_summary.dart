import 'package:flutter/foundation.dart';

/// Modelo de desglose de costo productivo por estanque o global
@immutable
class PondCostBreakdown {
  final String pondId;
  final String pondName;
  final double biomasaKg;
  final double costoDirectoAlevines;
  final double costoDirectoAlimento;
  final double costoIndirectoAsignado;
  final double costoTotal;
  final double cpkDirecto;
  final double cpkTotal;
  final double margenKg;
  final double margenPorcentaje;

  const PondCostBreakdown({
    required this.pondId,
    required this.pondName,
    required this.biomasaKg,
    required this.costoDirectoAlevines,
    required this.costoDirectoAlimento,
    required this.costoIndirectoAsignado,
    required this.costoTotal,
    required this.cpkDirecto,
    required this.cpkTotal,
    required this.margenKg,
    required this.margenPorcentaje,
  });
}

/// Modelo inmutable con las métricas consolidadas de Unit Economics y Costos de Producción
@immutable
class ProductionCostSummary {
  // Biomasa
  final double totalBiomasaKg;
  final int totalEstanquesActivos;

  // Costos Directos
  final double totalCostoAlevinos;
  final double totalCostoAlimento;
  final double totalCostosDirectos;

  // Costos Indirectos / Fijos
  final double totalCostoNomina;
  final double totalCostoJornales;
  final double totalCostoEnergia;
  final double totalDepreciacionCapex;
  final double totalCostosIndirectos;

  // Costo Total
  final double costoTotalProduccion;

  // Unit Economics (COP/Kg)
  final double cpkDirecto;
  final double cpkTotal;
  final double precioMercadoKg;
  final double margenBrutoKg;
  final double margenBrutoPorcentaje;

  // Punto de Equilibrio (Break-Even)
  final double puntoEquilibrioKg;
  final double puntoEquilibrioCOP;

  // Desglose por Estanque
  final List<PondCostBreakdown> estanquesBreakdown;

  // Desglose por Especie
  final List<SpeciesCostBreakdown> especiesBreakdown;

  // Resumen de Inversión de la Granja (Radiografía de Activos y Capital)
  final FarmInvestmentSummary? investmentSummary;

  const ProductionCostSummary({
    required this.totalBiomasaKg,
    required this.totalEstanquesActivos,
    required this.totalCostoAlevinos,
    required this.totalCostoAlimento,
    required this.totalCostosDirectos,
    required this.totalCostoNomina,
    required this.totalCostoJornales,
    required this.totalCostoEnergia,
    required this.totalDepreciacionCapex,
    required this.totalCostosIndirectos,
    required this.costoTotalProduccion,
    required this.cpkDirecto,
    required this.cpkTotal,
    required this.precioMercadoKg,
    required this.margenBrutoKg,
    required double margenPorcentaje,
    required this.puntoEquilibrioKg,
    required this.puntoEquilibrioCOP,
    required this.estanquesBreakdown,
    this.especiesBreakdown = const [],
    this.investmentSummary,
  }) : margenBrutoPorcentaje = margenPorcentaje;

  // ROI estimado sobre el costo total de producción
  double get roiEstimadoPorcentaje {
    if (costoTotalProduccion <= 0) return 0.0;
    final valorTotalVenta = totalBiomasaKg * precioMercadoKg;
    final utilidadTotal = valorTotalVenta - costoTotalProduccion;
    return (utilidadTotal / costoTotalProduccion) * 100.0;
  }

  // Porcentajes de participación en el costo total
  double get pctAlimento => costoTotalProduccion > 0 ? (totalCostoAlimento / costoTotalProduccion * 100).clamp(0.0, 100.0) : 0.0;
  double get pctAlevinos => costoTotalProduccion > 0 ? (totalCostoAlevinos / costoTotalProduccion * 100).clamp(0.0, 100.0) : 0.0;
  double get pctManoObra => costoTotalProduccion > 0 ? ((totalCostoNomina + totalCostoJornales) / costoTotalProduccion * 100).clamp(0.0, 100.0) : 0.0;
  double get pctEnergia => costoTotalProduccion > 0 ? (totalCostoEnergia / costoTotalProduccion * 100).clamp(0.0, 100.0) : 0.0;
  double get pctDepreciacion => costoTotalProduccion > 0 ? (totalDepreciacionCapex / costoTotalProduccion * 100).clamp(0.0, 100.0) : 0.0;
}

/// Desglose de costos y rentabilidad por especie acuícola (Tilapia Roja, Cachama, Trucha, etc.)
@immutable
class SpeciesCostBreakdown {
  final String especie;
  final int totalPeces;
  final double totalBiomasaKg;
  final int estanquesCount;
  final double costoDirectoAlevines;
  final double costoDirectoAlimento;
  final double costoDirectoJornales;
  final double costoIndirectosProrrateados;
  final double costoTotal;
  final double cpkDirecto;
  final double cpkTotal;
  final double precioVentaKg;
  final double margenKg;
  final double margenPorcentaje;
  final double utilidadTotalEstimada;
  final double roiPorcentaje;

  const SpeciesCostBreakdown({
    required this.especie,
    required this.totalPeces,
    required this.totalBiomasaKg,
    required this.estanquesCount,
    required this.costoDirectoAlevines,
    required this.costoDirectoAlimento,
    required this.costoDirectoJornales,
    required this.costoIndirectosProrrateados,
    required this.costoTotal,
    required this.cpkDirecto,
    required this.cpkTotal,
    required this.precioVentaKg,
    required this.margenKg,
    required this.margenPorcentaje,
    required this.utilidadTotalEstimada,
    required this.roiPorcentaje,
  });

  double get costoDirectoTotal => costoDirectoAlevines + costoDirectoAlimento + costoDirectoJornales;
}

/// Radiografía de Capital Invertido y Patrimonio de la Granja Acuícola
@immutable
class FarmInvestmentSummary {
  /// 1. Capital Biológico Activo en Agua (Alevinos sembrados + Alimento consumido acumulado en lotes)
  final double capitalEnAguaAlevines;
  final double capitalEnAguaAlimento;
  final double capitalEnAguaTotal;

  /// 2. Capital Inmovilizado en Bodega (Concentrados + Farmacia/Químicos en inventario físico)
  final double inventarioAlimentoBodega;
  final double inventarioFarmaciaBodega;
  final double inventarioBodegaTotal;

  /// 3. Infraestructura y Activos Fijos (CAPEX)
  final double activosFijosEquiposValorTotal;
  final double depreciacionAcumuladaEstimada;
  final double activosFijosNetos;

  /// 4. Capital de Trabajo / Gastos Operativos Acumulados (Nómina + Jornales + Energía + Mantenimiento)
  final double totalGastosOperativosMes;

  const FarmInvestmentSummary({
    required this.capitalEnAguaAlevines,
    required this.capitalEnAguaAlimento,
    required this.capitalEnAguaTotal,
    required this.inventarioAlimentoBodega,
    required this.inventarioFarmaciaBodega,
    required this.inventarioBodegaTotal,
    required this.activosFijosEquiposValorTotal,
    required this.depreciacionAcumuladaEstimada,
    required this.activosFijosNetos,
    required this.totalGastosOperativosMes,
  });

  /// Inversión Total Bruta Consolidada
  double get inversionTotalConsolidada =>
      capitalEnAguaTotal + inventarioBodegaTotal + activosFijosNetos;

  /// Participación porcentual de activos
  double get pctAgua => inversionTotalConsolidada > 0 ? (capitalEnAguaTotal / inversionTotalConsolidada * 100) : 0.0;
  double get pctBodega => inversionTotalConsolidada > 0 ? (inventarioBodegaTotal / inversionTotalConsolidada * 100) : 0.0;
  double get pctEquipos => inversionTotalConsolidada > 0 ? (activosFijosNetos / inversionTotalConsolidada * 100) : 0.0;
}

