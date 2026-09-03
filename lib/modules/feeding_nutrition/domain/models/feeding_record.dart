/// Registro diario de alimentación física y descuento de insumo
class FeedingRecord {
  final String id;
  final String empresaId;
  final String unidadAcuicolaId;
  final String estanqueId;
  final String loteId;
  final String? insumoId;
  final double cantidadConsumidaKg;
  final double costoCalculado;
  final DateTime fecha;
  final DateTime creadoEn;

  const FeedingRecord({
    required this.id,
    required this.empresaId,
    required this.unidadAcuicolaId,
    required this.estanqueId,
    required this.loteId,
    this.insumoId,
    required this.cantidadConsumidaKg,
    required this.costoCalculado,
    required this.fecha,
    required this.creadoEn,
  });

  factory FeedingRecord.fromJson(Map<String, dynamic> json) {
    final rawCantidad = json['cantidad_consumida_kg'] ?? json['cantidad_kg'] ?? json['kilos'] ?? json['cantidad'];
    final rawCosto = json['costo_calculado'] ?? json['costo_total'] ?? json['costo'];
    final rawFecha = json['fecha'] ?? json['fecha_alimentacion'] ?? json['fecha_registro'] ?? json['creado_en'];

    return FeedingRecord(
      id: json['id']?.toString() ?? '',
      empresaId: json['empresa_id']?.toString() ?? '',
      unidadAcuicolaId: json['unidad_acuicola_id']?.toString() ?? '',
      estanqueId: json['estanque_id']?.toString() ?? '',
      loteId: json['lote_id']?.toString() ?? '',
      insumoId: (json['insumo_id'] ?? json['alimento_id'])?.toString(),
      cantidadConsumidaKg: (rawCantidad as num?)?.toDouble() ?? 0.0,
      costoCalculado: (rawCosto as num?)?.toDouble() ?? 0.0,
      fecha: rawFecha != null ? DateTime.tryParse(rawFecha.toString()) ?? DateTime.now() : DateTime.now(),
      creadoEn: json['creado_en'] != null ? DateTime.tryParse(json['creado_en'].toString()) ?? DateTime.now() : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'empresa_id': empresaId,
        'unidad_acuicola_id': unidadAcuicolaId,
        'estanque_id': estanqueId,
        'lote_id': loteId,
        'insumo_id': insumoId,
        'cantidad_consumida_kg': cantidadConsumidaKg,
        'costo_calculado': costoCalculado,
        'fecha': fecha.toIso8601String().split('T')[0],
      };
}
