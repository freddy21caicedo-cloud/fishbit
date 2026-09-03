/// Modelo de Registro de Jornales de Campo y Cuadrillas Ocasionales
class JornalRecord {
  final String id;
  final String empresaId;
  final String unidadAcuicolaId;
  final String? estanqueId;
  final String laborRealizada; // 'Cosecha Nocturna', 'Desdoble y Traslado', 'Lavado de Estanques', 'Mantenimiento y Mallas'
  final int cantidadJornales;  // Número de personas/jornadas trabajadas
  final double valorPorJornal;  // Tarifa diaria por trabajador
  final double totalPagado;     // cantidadJornales * valorPorJornal
  final String? observaciones;
  final String? responsablePago;
  final DateTime fecha;
  final DateTime creadoEn;

  const JornalRecord({
    required this.id,
    required this.empresaId,
    required this.unidadAcuicolaId,
    this.estanqueId,
    required this.laborRealizada,
    required this.cantidadJornales,
    required this.valorPorJornal,
    required this.totalPagado,
    this.observaciones,
    this.responsablePago,
    required this.fecha,
    required this.creadoEn,
  });

  factory JornalRecord.fromJson(Map<String, dynamic> json) {
    final cant = (json['cantidad_jornales'] as num?)?.toInt() ?? 1;
    final valor = (json['valor_por_jornal'] as num?)?.toDouble() ?? 65000.0;
    return JornalRecord(
      id: json['id']?.toString() ?? '',
      empresaId: json['empresa_id']?.toString() ?? '',
      unidadAcuicolaId: json['unidad_acuicola_id']?.toString() ?? '',
      estanqueId: json['estanque_id']?.toString(),
      laborRealizada: json['labor_realizada']?.toString() ?? 'Labores de Campo',
      cantidadJornales: cant,
      valorPorJornal: valor,
      totalPagado: (json['total_pagado'] as num?)?.toDouble() ?? (cant * valor),
      observaciones: json['observaciones']?.toString(),
      responsablePago: json['responsable_pago']?.toString(),
      fecha: json['fecha'] != null ? DateTime.tryParse(json['fecha'].toString()) ?? DateTime.now() : DateTime.now(),
      creadoEn: json['creado_en'] != null ? DateTime.tryParse(json['creado_en'].toString()) ?? DateTime.now() : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'empresa_id': empresaId,
    'unidad_acuicola_id': unidadAcuicolaId,
    'estanque_id': estanqueId,
    'labor_realizada': laborRealizada,
    'cantidad_jornales': cantidadJornales,
    'valor_por_jornal': valorPorJornal,
    'total_pagado': totalPagado,
    'observaciones': observaciones,
    'responsable_pago': responsablePago,
    'fecha': fecha.toIso8601String().split('T')[0],
  };
}
