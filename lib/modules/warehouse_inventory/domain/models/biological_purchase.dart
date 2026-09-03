/// Compra de material biológico con trazabilidad ICA y AUNAP
class BiologicalPurchase {
  final String id;
  final String empresaId;
  final String unidadAcuicolaId;
  final String tipo; // 'Ovas' | 'Larvas' | 'Alevinos' | 'Reproductores'
  final String especie;
  final String proveedorNombre;
  final String proveedorNit;
  final String numeroFactura;
  final double costoUnitario;
  final double cantidad;
  final double cantidadOriginal;
  final double costoTotal;
  final double pesoPromedioGramos;
  final double biomasaEstimadaKg;
  final bool certificacionIca;
  final String? resolucionIca;
  final String? resolucionAunap;
  final DateTime fecha;
  final DateTime creadoEn;

  const BiologicalPurchase({
    required this.id,
    required this.empresaId,
    required this.unidadAcuicolaId,
    required this.tipo,
    required this.especie,
    required this.proveedorNombre,
    required this.proveedorNit,
    required this.numeroFactura,
    required this.costoUnitario,
    required this.cantidad,
    required this.cantidadOriginal,
    required this.costoTotal,
    this.pesoPromedioGramos = 0.0,
    this.biomasaEstimadaKg = 0.0,
    this.certificacionIca = false,
    this.resolucionIca,
    this.resolucionAunap,
    required this.fecha,
    required this.creadoEn,
  });

  factory BiologicalPurchase.fromJson(Map<String, dynamic> json) {
    return BiologicalPurchase(
      id: json['id'] as String,
      empresaId: json['empresa_id'] as String? ?? '',
      unidadAcuicolaId: json['unidad_acuicola_id'] as String? ?? '',
      tipo: json['tipo'] as String? ?? 'Alevinos',
      especie: json['especie'] as String? ?? '',
      proveedorNombre: json['proveedor_nombre'] as String? ?? '',
      proveedorNit: json['proveedor_nit'] as String? ?? '',
      numeroFactura: json['numero_factura'] as String? ?? '',
      costoUnitario: (json['costo_unitario'] as num?)?.toDouble() ?? 0.0,
      cantidad: (json['cantidad'] as num?)?.toDouble() ?? 0.0,
      cantidadOriginal: (json['cantidad_original'] as num?)?.toDouble() ?? 0.0,
      costoTotal: (json['costo_total'] as num?)?.toDouble() ?? 0.0,
      pesoPromedioGramos: (json['peso_promedio_gramos'] as num?)?.toDouble() ?? 0.0,
      biomasaEstimadaKg: (json['biomasa_estimada_kg'] as num?)?.toDouble() ?? 0.0,
      certificacionIca: json['certificacion_ica'] as bool? ?? false,
      resolucionIca: json['resolucion_ica'] as String?,
      resolucionAunap: json['resolucion_aunap'] as String?,
      fecha: json['fecha'] != null ? DateTime.parse(json['fecha'] as String) : DateTime.now(),
      creadoEn: json['creado_en'] != null ? DateTime.parse(json['creado_en'] as String) : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'empresa_id': empresaId,
        'unidad_acuicola_id': unidadAcuicolaId,
        'tipo': tipo,
        'especie': especie,
        'proveedor_nombre': proveedorNombre,
        'proveedor_nit': proveedorNit,
        'numero_factura': numeroFactura,
        'costo_unitario': costoUnitario,
        'cantidad': cantidad,
        'cantidad_original': cantidadOriginal,
        'costo_total': costoTotal,
        'peso_promedio_gramos': pesoPromedioGramos,
        'biomasa_estimada_kg': biomasaEstimadaKg,
        'certificacion_ica': certificacionIca,
        'resolucion_ica': resolucionIca,
        'resolucion_aunap': resolucionAunap,
        'fecha': fecha.toIso8601String().split('T')[0],
      };
}
