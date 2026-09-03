/// Registro de mantenimiento preventivo o correctivo de estanques o infraestructura
class MaintenanceRecord {
  final String id;
  final String empresaId;
  final String unidadAcuicolaId;
  final String tipoMantenimiento; // 'Preventivo' | 'Correctivo'
  final String destino; // 'Estanque' | 'General'
  final String? estanqueId;
  final String concepto;
  final String proveedor;
  final DateTime fecha;
  final double valor;
  final DateTime creadoEn;

  const MaintenanceRecord({
    required this.id,
    required this.empresaId,
    required this.unidadAcuicolaId,
    required this.tipoMantenimiento,
    required this.destino,
    this.estanqueId,
    required this.concepto,
    required this.proveedor,
    required this.fecha,
    required this.valor,
    required this.creadoEn,
  });

  factory MaintenanceRecord.fromJson(Map<String, dynamic> json) {
    return MaintenanceRecord(
      id: json['id'] as String,
      empresaId: json['empresa_id'] as String? ?? '',
      unidadAcuicolaId: json['unidad_acuicola_id'] as String? ?? '',
      tipoMantenimiento: json['tipo_mantenimiento'] as String? ?? 'Preventivo',
      destino: json['destino'] as String? ?? 'General',
      estanqueId: json['estanque_id'] as String?,
      concepto: json['concepto'] as String? ?? '',
      proveedor: json['proveedor'] as String? ?? '',
      fecha: json['fecha'] != null ? DateTime.parse(json['fecha'] as String) : DateTime.now(),
      valor: (json['valor'] as num?)?.toDouble() ?? 0.0,
      creadoEn: json['creado_en'] != null ? DateTime.parse(json['creado_en'] as String) : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'empresa_id': empresaId,
        'unidad_acuicola_id': unidadAcuicolaId,
        'tipo_mantenimiento': tipoMantenimiento,
        'destino': destino,
        'estanque_id': estanqueId,
        'concepto': concepto,
        'proveedor': proveedor,
        'fecha': fecha.toIso8601String().split('T')[0],
        'valor': valor,
      };
}
