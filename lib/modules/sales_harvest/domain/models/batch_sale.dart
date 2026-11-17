enum SalePresentation {
  vivo,
  medioEviscerado,
  evisceradoCompleto;

  String get label {
    switch (this) {
      case SalePresentation.vivo:
        return 'Pescado Vivo';
      case SalePresentation.medioEviscerado:
        return 'Medio Eviscerado';
      case SalePresentation.evisceradoCompleto:
        return 'Eviscerado Completo';
    }
  }

  static SalePresentation fromString(String? val) {
    if (val == null) return SalePresentation.vivo;
    switch (val.toLowerCase().trim()) {
      case 'medio_eviscerado':
      case 'medio eviscerado':
      case 'medioeviscerado':
      case 'media tripa':
      case 'media_tripa':
        return SalePresentation.medioEviscerado;
      case 'eviscerado_completo':
      case 'eviscerado completo':
      case 'eviscerado':
      case 'evisceradocompleto':
        return SalePresentation.evisceradoCompleto;
      case 'vivo':
      default:
        return SalePresentation.vivo;
    }
  }

  String toDbString() {
    switch (this) {
      case SalePresentation.vivo:
        return 'vivo';
      case SalePresentation.medioEviscerado:
        return 'medio_eviscerado';
      case SalePresentation.evisceradoCompleto:
        return 'eviscerado_completo';
    }
  }
}

/// Entidad inmutable de Venta y Cosecha con cálculo de utilidad neta, COGS y rendimiento de merma
class BatchSale {
  final String id;
  final String empresaId;
  final String unidadAcuicolaId;
  final String? clienteId;
  final String clienteNombre;
  final String? clienteCedulaNit;
  final String loteId;
  final String codigoLote;
  final String estanqueNombre;
  final String especie;
  final SalePresentation tipoVenta;
  final int cantidadPeces;
  final double pesoVivoKg;
  final double pesoArregladoKg;
  final double mermaKg;
  final double mermaPct;
  final double mermaGPpe; // merma en gramos por pez
  final String baseCobro; // 'peso_vivo' | 'peso_arreglado'
  final double biomasaVendidaKg; // Biomasa cosechada de la piscina (peso vivo)
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
    this.clienteCedulaNit,
    required this.loteId,
    required this.codigoLote,
    required this.estanqueNombre,
    required this.especie,
    this.tipoVenta = SalePresentation.vivo,
    this.cantidadPeces = 0,
    this.pesoVivoKg = 0.0,
    this.pesoArregladoKg = 0.0,
    this.mermaKg = 0.0,
    this.mermaPct = 0.0,
    this.mermaGPpe = 0.0,
    this.baseCobro = 'peso_vivo',
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
    final double rawBiomasa = (json['biomasa_vendida_kg'] as num?)?.toDouble() ??
        (json['cantidad_kg'] as num?)?.toDouble() ??
        0.0;
    final double rawVivo = (json['peso_vivo_kg'] as num?)?.toDouble() ?? rawBiomasa;
    final double rawArreglado = (json['peso_arreglado_kg'] as num?)?.toDouble() ?? rawVivo;
    final double rawMermaKg = (json['merma_kg'] as num?)?.toDouble() ?? (rawVivo - rawArreglado > 0 ? rawVivo - rawArreglado : 0.0);
    final double rawMermaPct = (json['merma_pct'] as num?)?.toDouble() ??
        (json['porcentaje_visceras_pct'] as num?)?.toDouble() ??
        (rawVivo > 0 ? (rawMermaKg / rawVivo) * 100.0 : 0.0);
    final int rawCantidadPeces = (json['cantidad_peces'] as num?)?.toInt() ?? 0;
    final double rawMermaG = (json['merma_g_por_pez'] as num?)?.toDouble() ??
        (rawCantidadPeces > 0 ? (rawMermaKg * 1000.0) / rawCantidadPeces : 0.0);

    return BatchSale(
      id: json['id'] as String,
      empresaId: json['empresa_id'] as String? ?? '',
      unidadAcuicolaId: json['unidad_acuicola_id'] as String? ?? json['unit_id'] as String? ?? '',
      clienteId: json['cliente_id'] as String?,
      clienteNombre: json['cliente_nombre'] as String? ?? 'Cliente Particular',
      clienteCedulaNit: json['cliente_cedula_nit'] as String?,
      loteId: json['lote_id'] as String? ?? '',
      codigoLote: json['codigo_lote'] as String? ?? '',
      estanqueNombre: json['estanque_nombre'] as String? ?? '',
      especie: json['especie'] as String? ?? json['species_name'] as String? ?? '',
      tipoVenta: SalePresentation.fromString(json['tipo_venta'] as String?),
      cantidadPeces: rawCantidadPeces,
      pesoVivoKg: rawVivo,
      pesoArregladoKg: rawArreglado,
      mermaKg: rawMermaKg,
      mermaPct: rawMermaPct,
      mermaGPpe: rawMermaG,
      baseCobro: json['base_cobro'] as String? ?? 'peso_vivo',
      biomasaVendidaKg: rawBiomasa > 0 ? rawBiomasa : rawVivo,
      precioUnitarioKg: (json['precio_unitario_kg'] as num?)?.toDouble() ??
          (json['precio_kg'] as num?)?.toDouble() ??
          0.0,
      ingresoBruto: (json['ingreso_bruto'] as num?)?.toDouble() ??
          (json['total'] as num?)?.toDouble() ??
          0.0,
      cogs: (json['cogs'] as num?)?.toDouble() ?? 0.0,
      utilidadNeta: (json['utilidad_neta'] as num?)?.toDouble() ?? 0.0,
      estadoPago: json['estado_pago'] as String? ?? 'Pagado',
      pesoPromedioG: (json['peso_promedio_g'] as num?)?.toDouble() ??
          (rawCantidadPeces > 0 && rawVivo > 0 ? (rawVivo * 1000.0) / rawCantidadPeces : null),
      porcentajeViscerasPct: rawMermaPct,
      creadoEn: json['creado_en'] != null
          ? DateTime.parse(json['creado_en'] as String)
          : (json['fecha'] != null
              ? DateTime.parse(json['fecha'] as String)
              : DateTime.now()),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'empresa_id': empresaId,
        'unidad_acuicola_id': unidadAcuicolaId,
        'cliente_id': clienteId,
        'cliente_nombre': clienteNombre,
        'cliente_cedula_nit': clienteCedulaNit,
        'lote_id': loteId,
        'codigo_lote': codigoLote,
        'estanque_nombre': estanqueNombre,
        'especie': especie,
        'tipo_venta': tipoVenta.toDbString(),
        'cantidad_peces': cantidadPeces,
        'peso_vivo_kg': pesoVivoKg,
        'peso_arreglado_kg': pesoArregladoKg,
        'merma_kg': mermaKg,
        'merma_pct': mermaPct,
        'merma_g_por_pez': mermaGPpe,
        'base_cobro': baseCobro,
        'biomasa_vendida_kg': biomasaVendidaKg,
        'precio_unitario_kg': precioUnitarioKg,
        'ingreso_bruto': ingresoBruto,
        'cogs': cogs,
        'utilidad_neta': utilidadNeta,
        'estado_pago': estadoPago,
        'peso_promedio_g': pesoPromedioG,
        'porcentaje_visceras_pct': porcentajeViscerasPct ?? mermaPct,
        'creado_en': creadoEn.toIso8601String(),
      };
}

