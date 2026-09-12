/// Línea de ítem o producto en la factura de compra
class InvoiceItemLine {
  final String codigo;
  final String nombre;
  final String? loteFabricante;
  final int cantidadBultos;
  final double kgPorBulto;
  final double kilosTotales;
  final double valorUnitarioBulto;
  final double valorBruto;
  final double descuentoPct;
  final double valorDescuento;
  final double baseGravable;
  final double ivaPct;
  final double valorIva;
  final double valorTotal;
  final double? fleteProrrateado;
  final double? costoFinalPorKg;

  const InvoiceItemLine({
    this.codigo = '',
    required this.nombre,
    this.loteFabricante,
    required this.cantidadBultos,
    this.kgPorBulto = 40.0,
    required this.kilosTotales,
    required this.valorUnitarioBulto,
    required this.valorBruto,
    this.descuentoPct = 0.0,
    this.valorDescuento = 0.0,
    required this.baseGravable,
    this.ivaPct = 5.0,
    required this.valorIva,
    required this.valorTotal,
    this.fleteProrrateado = 0.0,
    this.costoFinalPorKg,
  });

  factory InvoiceItemLine.fromJson(Map<String, dynamic> json) {
    final bultos = (json['cantidad_bultos'] as num?)?.toInt() ?? (json['bultos'] as num?)?.toInt() ?? 1;
    final kgBulto = (json['kg_por_bulto'] as num?)?.toDouble() ?? 40.0;
    final kilos = (json['kilos_totales'] as num?)?.toDouble() ?? (json['cantidad_kg'] as num?)?.toDouble() ?? (bultos * kgBulto);
    final unitBulto = (json['valor_unitario_bulto'] as num?)?.toDouble() ?? 0.0;
    final bruto = (json['valor_bruto'] as num?)?.toDouble() ?? (bultos * unitBulto);
    
    final dctoPct = (json['descuento_pct'] as num?)?.toDouble() ?? (json['descuento'] as num?)?.toDouble() ?? 0.0;
    final dctoVal = (json['valor_descuento'] as num?)?.toDouble() ?? (bruto * (dctoPct / 100.0));
    final base = (json['base_gravable'] as num?)?.toDouble() ?? (bruto - dctoVal);

    final ivaP = (json['iva_pct'] as num?)?.toDouble() ?? 5.0;
    final ivaV = (json['valor_iva'] as num?)?.toDouble() ?? (base * (ivaP / 100.0));
    final tot = (json['valor_total'] as num?)?.toDouble() ?? (json['costo_total'] as num?)?.toDouble() ?? (base + ivaV);

    return InvoiceItemLine(
      codigo: json['codigo']?.toString() ?? '',
      nombre: (json['nombre'] ?? json['description'] ?? 'Producto').toString(),
      loteFabricante: json['lote_fabricante']?.toString() ?? json['lote']?.toString(),
      cantidadBultos: bultos,
      kgPorBulto: kgBulto,
      kilosTotales: kilos,
      valorUnitarioBulto: unitBulto,
      valorBruto: bruto,
      descuentoPct: dctoPct,
      valorDescuento: dctoVal,
      baseGravable: base,
      ivaPct: ivaP,
      valorIva: ivaV,
      valorTotal: tot,
      fleteProrrateado: (json['flete_prorrateado'] as num?)?.toDouble() ?? 0.0,
      costoFinalPorKg: (json['costo_final_por_kg'] as num?)?.toDouble() ?? (kilos > 0 ? tot / kilos : 0.0),
    );
  }

  Map<String, dynamic> toJson() => {
        'codigo': codigo,
        'nombre': nombre,
        if (loteFabricante != null) 'lote_fabricante': loteFabricante,
        'cantidad_bultos': cantidadBultos,
        'kg_por_bulto': kgPorBulto,
        'kilos_totales': kilosTotales,
        'valor_unitario_bulto': valorUnitarioBulto,
        'valor_bruto': valorBruto,
        'descuento_pct': descuentoPct,
        'valor_descuento': valorDescuento,
        'base_gravable': baseGravable,
        'iva_pct': ivaPct,
        'valor_iva': valorIva,
        'valor_total': valorTotal,
        'flete_prorrateado': fleteProrrateado,
        'costo_final_por_kg': costoFinalPorKg,
      };
}

/// Factura de Compra con soporte Multi-ítem y prorrateo de fletes al inventario
class PurchaseInvoice {
  final String id;
  final String empresaId;
  final String unidadAcuicolaId;
  final String unidadAcuicolaSigla;
  final String tipoFactura; // 'concentrados' | 'insumos' | 'farmacia' | 'oxigenadores' | 'alevinos'
  final String numeroFactura;
  final String proveedorNombre;
  final String proveedorNit;
  final DateTime fechaExpedicion;
  final DateTime fechaVencimiento;
  final bool esCredito;
  final int diasCredito;
  final double totalKilos;
  final double totalNeto;
  final double totalIva;
  final double totalFactura;
  final double costoFlete;
  final String estadoPago; // 'Paga' | 'Pendiente' | 'Vencida'
  final String? conductorNombre;
  final String? placaVehiculo;
  final String? pedidoTiendaRef;
  final List<InvoiceItemLine> productos;
  final DateTime creadoEn;

  const PurchaseInvoice({
    required this.id,
    required this.empresaId,
    required this.unidadAcuicolaId,
    this.unidadAcuicolaSigla = 'SEDE',
    required this.tipoFactura,
    required this.numeroFactura,
    required this.proveedorNombre,
    required this.proveedorNit,
    required this.fechaExpedicion,
    required this.fechaVencimiento,
    this.esCredito = false,
    this.diasCredito = 0,
    this.totalKilos = 0.0,
    required this.totalNeto,
    this.totalIva = 0.0,
    required this.totalFactura,
    this.costoFlete = 0.0,
    this.estadoPago = 'Paga',
    this.conductorNombre,
    this.placaVehiculo,
    this.pedidoTiendaRef,
    required this.productos,
    required this.creadoEn,
  });

  factory PurchaseInvoice.fromJson(Map<String, dynamic> json) {
    final rawProds = json['productos'] as List<dynamic>? ?? [];
    final parsedProds = rawProds.map((p) {
      if (p is Map<String, dynamic>) {
        return InvoiceItemLine.fromJson(p);
      }
      return InvoiceItemLine(
        nombre: p.toString(),
        cantidadBultos: 1,
        kilosTotales: 40.0,
        valorUnitarioBulto: 0.0,
        valorBruto: 0.0,
        baseGravable: 0.0,
        valorIva: 0.0,
        valorTotal: 0.0,
      );
    }).toList();

    return PurchaseInvoice(
      id: json['id'] as String,
      empresaId: json['empresa_id'] as String? ?? '',
      unidadAcuicolaId: json['unidad_acuicola_id'] as String? ?? '',
      unidadAcuicolaSigla: json['unidad_acuicola_sigla'] as String? ?? 'SEDE',
      tipoFactura: json['tipo_factura'] as String? ?? 'concentrados',
      numeroFactura: json['numero_factura'] as String? ?? '',
      proveedorNombre: json['proveedor_nombre'] as String? ?? '',
      proveedorNit: json['proveedor_nit'] as String? ?? '',
      fechaExpedicion: json['fecha_expedicion'] != null ? DateTime.parse(json['fecha_expedicion'] as String) : DateTime.now(),
      fechaVencimiento: json['fecha_vencimiento'] != null ? DateTime.parse(json['fecha_vencimiento'] as String) : DateTime.now(),
      esCredito: json['es_credito'] as bool? ?? false,
      diasCredito: json['dias_credito'] as int? ?? 0,
      totalKilos: (json['total_kilos'] as num?)?.toDouble() ?? parsedProds.fold(0.0, (s, p) => s + p.kilosTotales),
      totalNeto: (json['total_neto'] as num?)?.toDouble() ?? 0.0,
      totalIva: (json['total_iva'] as num?)?.toDouble() ?? 0.0,
      totalFactura: (json['total_factura'] as num?)?.toDouble() ?? 0.0,
      costoFlete: (json['costo_flete'] as num?)?.toDouble() ?? 0.0,
      estadoPago: json['estado_pago'] as String? ?? 'Paga',
      conductorNombre: json['conductor_nombre'] as String?,
      placaVehiculo: json['placa_vehiculo'] as String?,
      pedidoTiendaRef: json['pedido_tienda_ref'] as String?,
      productos: parsedProds,
      creadoEn: json['creado_en'] != null ? DateTime.parse(json['creado_en'] as String) : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'empresa_id': empresaId.isNotEmpty ? empresaId : null,
        'unidad_acuicola_id': (unidadAcuicolaId.isNotEmpty && !unidadAcuicolaId.startsWith('u1000000-')) ? unidadAcuicolaId : null,
        'unidad_acuicola_sigla': unidadAcuicolaSigla.isNotEmpty ? unidadAcuicolaSigla : 'SEDE',
        'tipo_factura': tipoFactura,
        'numero_factura': numeroFactura,
        'proveedor_nombre': proveedorNombre,
        'proveedor_nit': proveedorNit,
        'fecha_expedicion': fechaExpedicion.toIso8601String().split('T')[0],
        'fecha_vencimiento': fechaVencimiento.toIso8601String().split('T')[0],
        'es_credito': esCredito,
        'dias_credito': diasCredito,
        'total_kilos': totalKilos,
        'total_neto': totalNeto,
        'total_iva': totalIva,
        'total_factura': totalFactura,
        'costo_flete': costoFlete,
        'estado_pago': estadoPago,
        if (conductorNombre != null) 'conductor_nombre': conductorNombre,
        if (placaVehiculo != null) 'placa_vehiculo': placaVehiculo,
        if (pedidoTiendaRef != null) 'pedido_tienda_ref': pedidoTiendaRef,
        'productos': productos.map((p) => p.toJson()).toList(),
      };
}
