/// Recibo de energía eléctrica para cálculo de costo por kWh y OPEX
class EnergyBill {
  final String id;
  final String empresaId;
  final String unidadAcuicolaId;
  final DateTime fechaEmision;
  final DateTime fechaPago;
  final double totalKwh;
  final double totalPagado;
  final DateTime creadoEn;

  const EnergyBill({
    required this.id,
    required this.empresaId,
    required this.unidadAcuicolaId,
    required this.fechaEmision,
    required this.fechaPago,
    required this.totalKwh,
    required this.totalPagado,
    required this.creadoEn,
  });

  double get costoPorKwh => totalKwh > 0 ? (totalPagado / totalKwh) : 0.0;

  factory EnergyBill.fromJson(Map<String, dynamic> json) {
    return EnergyBill(
      id: json['id'] as String,
      empresaId: json['empresa_id'] as String? ?? '',
      unidadAcuicolaId: json['unidad_acuicola_id'] as String? ?? '',
      fechaEmision: json['fecha_emision'] != null ? DateTime.parse(json['fecha_emision'] as String) : DateTime.now(),
      fechaPago: json['fecha_pago'] != null ? DateTime.parse(json['fecha_pago'] as String) : DateTime.now(),
      totalKwh: (json['total_kwh'] as num?)?.toDouble() ?? 0.0,
      totalPagado: (json['total_pagado'] as num?)?.toDouble() ?? 0.0,
      creadoEn: json['creado_en'] != null ? DateTime.parse(json['creado_en'] as String) : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'empresa_id': empresaId,
        'unidad_acuicola_id': unidadAcuicolaId,
        'fecha_emision': fechaEmision.toIso8601String().split('T')[0],
        'fecha_pago': fechaPago.toIso8601String().split('T')[0],
        'total_kwh': totalKwh,
        'total_pagado': totalPagado,
      };
}
