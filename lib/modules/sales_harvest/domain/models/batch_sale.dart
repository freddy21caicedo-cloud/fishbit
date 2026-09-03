/// Entidad inmutable de Venta y Cosecha con cálculo de utilidad neta y COGS
class BatchSale {
  final String id;
  final String empresaId;
  final String unidadAcuicolaId;
  final String? clienteId;
  final String clienteNombre;
  final String loteId;
  final String codigoLote;
  final String estanqueNombre;
  final String especie;
  final double biomasaVendidaKg;
  final double precioUnitarioKg;
  final double ingresoBruto;
  final double cogs; // Costo de producción cargado al lote
  final double utilidadNeta;
  final String estadoPago; // 'Pendiente' | 'Pagado'
  final double? pesoPromedioG;
  final double? porcentajeViscerasPct;
  final DateTime creadoEn;

  const BatchSale({
    required this.id,
    required this.empresaId,
    required this.unidadAcuicolaId,
    this.clienteId,
    required this.clienteNombre,
    required this.loteId,
    required this.codigoLote,
    required this.estanqueNombre,
    required this.especie,
    required this.biomasaVendidaKg,
    required this.precioUnitarioKg,
    required this.ingresoBruto,
    required this.cogs,
    required this.utilidadNeta,
    this.estadoPago = 'Pagado',
    this.pesoPromedioG,
    this.porcentajeViscerasPct,
    required this.creadoEn,
  });

  /// Margen neto de ganancia porcentual
  double get margenNetoPct => ingresoBruto > 0 ? (utilidadNeta / ingresoBruto) * 100.0 : 0.0;

  factory BatchSale.fromJson(Map<String, dynamic> json) {
    return BatchSale(
      id: json['id'] as String,
      empresaId: json['empresa_id'] as String? ?? '',
      unidadAcuicolaId: json['unidad_acuicola_id'] as String? ?? '',
      clienteId: json['cliente_id'] as String?,
      clienteNombre: json['cliente_nombre'] as String? ?? 'Cliente Particular',
      loteId: json['lote_id'] as String? ?? '',
      codigoLote: json['codigo_lote'] as String? ?? '',
      estanqueNombre: json['estanque_nombre'] as String? ?? '',
      especie: json['especie'] as String? ?? '',
      biomasaVendidaKg: (json['biomasa_vendida_kg'] as num?)?.toDouble() ?? 0.0,
      precioUnitarioKg: (json['precio_unitario_kg'] as num?)?.toDouble() ?? 0.0,
      ingresoBruto: (json['ingreso_bruto'] as num?)?.toDouble() ?? 0.0,
      cogs: (json['cogs'] as num?)?.toDouble() ?? 0.0,
      utilidadNeta: (json['utilidad_neta'] as num?)?.toDouble() ?? 0.0,
      estadoPago: json['estado_pago'] as String? ?? 'Pagado',
      pesoPromedioG: (json['peso_promedio_g'] as num?)?.toDouble(),
      porcentajeViscerasPct: (json['porcentaje_visceras_pct'] as num?)?.toDouble(),
      creadoEn: json['creado_en'] != null ? DateTime.parse(json['creado_en'] as String) : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'empresa_id': empresaId,
        'unidad_acuicola_id': unidadAcuicolaId,
        'cliente_id': clienteId,
        'cliente_nombre': clienteNombre,
        'lote_id': loteId,
        'codigo_lote': codigoLote,
        'estanque_nombre': estanqueNombre,
        'especie': especie,
        'biomasa_vendida_kg': biomasaVendidaKg,
        'precio_unitario_kg': precioUnitarioKg,
        'ingreso_bruto': ingresoBruto,
        'cogs': cogs,
        'utilidad_neta': utilidadNeta,
        'estado_pago': estadoPago,
        'peso_promedio_g': pesoPromedioG,
        'porcentaje_visceras_pct': porcentajeViscerasPct,
      };
}
