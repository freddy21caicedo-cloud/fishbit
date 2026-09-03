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
  }) : margenBrutoPorcentaje = margenPorcentaje;

  // Porcentajes de participación en el costo total
  double get pctAlimento => costoTotalProduccion > 0 ? (totalCostoAlimento / costoTotalProduccion * 100).clamp(0.0, 100.0) : 0.0;
  double get pctAlevinos => costoTotalProduccion > 0 ? (totalCostoAlevinos / costoTotalProduccion * 100).clamp(0.0, 100.0) : 0.0;
  double get pctManoObra => costoTotalProduccion > 0 ? ((totalCostoNomina + totalCostoJornales) / costoTotalProduccion * 100).clamp(0.0, 100.0) : 0.0;
  double get pctEnergia => costoTotalProduccion > 0 ? (totalCostoEnergia / costoTotalProduccion * 100).clamp(0.0, 100.0) : 0.0;
  double get pctDepreciacion => costoTotalProduccion > 0 ? (totalDepreciacionCapex / costoTotalProduccion * 100).clamp(0.0, 100.0) : 0.0;
}
