enum InventoryItemType {
  concentrado,
  insumo,
  alevino,
  oxigenador,
  farmacia,
  herramienta,
}

/// Entidad inmutable de Artículo de Inventario Acuícola V2.0
class InventoryItem {
  final String id;
  final String empresaId;
  final String? unidadAcuicolaId;
  final InventoryItemType tipo;
  final String nombre;
  final String? marcaProveedor;
  final String? presentacionUnidad; // 'Bulto 40 Kg', 'Saco 50 Kg', 'Litro', 'Galón', 'Unidad', 'Millar'
  
  // Cantidades y Métricas Financieras (CPP)
  final double cantidadOriginalKg; // o unidades/millares según el tipo
  final double cantidadActualKg;
  final double costoTotal;
  final double costoUnitarioHistorico; // Costo Promedio Ponderado (CPP) por kg o unidad
  final double stockMinimoAlerta;

  // Atributos Especializados Acuícolas
  final double? proteinaCrudaPct; // ej. 45%, 38%, 34%, 30%, 28% para concentrados
  final double? calibrePelletMm; // ej. 1.2 mm, 2.0 mm, 3.5 mm, 5.0 mm
  final String? especieAlevino; // ej. Tilapia Roja, Bocachico, Trucha
  final double? potenciaHp; // ej. 1.0, 1.5, 2.0 HP para oxigenadores
  final String? faseElectrica; // 'Monofásico 110V/220V', 'Trifásico 220V/440V'
  final String? estanqueAsignadoId; // Para equipos asignados
  final int? diasRetiroSanitario; // Periodo de carencia ICA en farmacia (días)
  final String? principioActivo; // Para fármacos
  final String? loteFabricante;
  final DateTime? fechaVencimiento;
  final DateTime creadoEn;

  const InventoryItem({
    required this.id,
    required this.empresaId,
    this.unidadAcuicolaId,
    required this.tipo,
    required this.nombre,
    this.marcaProveedor,
    this.presentacionUnidad = 'Kg',
    required this.cantidadOriginalKg,
    required this.cantidadActualKg,
    required this.costoTotal,
    required this.costoUnitarioHistorico,
    this.stockMinimoAlerta = 200.0,
    this.proteinaCrudaPct,
    this.calibrePelletMm,
    this.especieAlevino,
    this.potenciaHp,
    this.faseElectrica,
    this.estanqueAsignadoId,
    this.diasRetiroSanitario,
    this.principioActivo,
    this.loteFabricante,
    this.fechaVencimiento,
    required this.creadoEn,
  });

  bool get isLowStock => cantidadActualKg <= stockMinimoAlerta;

  static InventoryItemType parseType(String val) {
    switch (val.toLowerCase()) {
      case 'concentrado':
      case 'alimento':
        return InventoryItemType.concentrado;
      case 'farmacia':
      case 'farmaco':
        return InventoryItemType.farmacia;
      case 'oxigenador':
      case 'aireador':
      case 'equipo':
        return InventoryItemType.oxigenador;
      case 'alevino':
      case 'semilla':
        return InventoryItemType.alevino;
      case 'herramienta':
        return InventoryItemType.herramienta;
      default:
        return InventoryItemType.insumo;
    }
  }

  static String typeToString(InventoryItemType t) {
    switch (t) {
      case InventoryItemType.concentrado:
        return 'Concentrado';
      case InventoryItemType.farmacia:
        return 'Farmacia';
      case InventoryItemType.oxigenador:
        return 'Oxigenador';
      case InventoryItemType.alevino:
        return 'Alevino';
      case InventoryItemType.herramienta:
        return 'Herramienta';
      case InventoryItemType.insumo:
        return 'Insumo';
    }
  }

  InventoryItem copyWith({
    String? id,
    String? empresaId,
    String? unidadAcuicolaId,
    InventoryItemType? tipo,
    String? nombre,
    String? marcaProveedor,
    String? presentacionUnidad,
    double? cantidadOriginalKg,
    double? cantidadActualKg,
    double? costoTotal,
    double? costoUnitarioHistorico,
    double? stockMinimoAlerta,
    double? proteinaCrudaPct,
    double? calibrePelletMm,
    String? especieAlevino,
    double? potenciaHp,
    String? faseElectrica,
    String? estanqueAsignadoId,
    int? diasRetiroSanitario,
    String? principioActivo,
    String? loteFabricante,
    DateTime? fechaVencimiento,
    DateTime? creadoEn,
  }) {
    return InventoryItem(
      id: id ?? this.id,
      empresaId: empresaId ?? this.empresaId,
      unidadAcuicolaId: unidadAcuicolaId ?? this.unidadAcuicolaId,
      tipo: tipo ?? this.tipo,
      nombre: nombre ?? this.nombre,
      marcaProveedor: marcaProveedor ?? this.marcaProveedor,
      presentacionUnidad: presentacionUnidad ?? this.presentacionUnidad,
      cantidadOriginalKg: cantidadOriginalKg ?? this.cantidadOriginalKg,
      cantidadActualKg: cantidadActualKg ?? this.cantidadActualKg,
      costoTotal: costoTotal ?? this.costoTotal,
      costoUnitarioHistorico: costoUnitarioHistorico ?? this.costoUnitarioHistorico,
      stockMinimoAlerta: stockMinimoAlerta ?? this.stockMinimoAlerta,
      proteinaCrudaPct: proteinaCrudaPct ?? this.proteinaCrudaPct,
      calibrePelletMm: calibrePelletMm ?? this.calibrePelletMm,
      especieAlevino: especieAlevino ?? this.especieAlevino,
      potenciaHp: potenciaHp ?? this.potenciaHp,
      faseElectrica: faseElectrica ?? this.faseElectrica,
      estanqueAsignadoId: estanqueAsignadoId ?? this.estanqueAsignadoId,
      diasRetiroSanitario: diasRetiroSanitario ?? this.diasRetiroSanitario,
      principioActivo: principioActivo ?? this.principioActivo,
      loteFabricante: loteFabricante ?? this.loteFabricante,
      fechaVencimiento: fechaVencimiento ?? this.fechaVencimiento,
      creadoEn: creadoEn ?? this.creadoEn,
    );
  }

  factory InventoryItem.fromJson(Map<String, dynamic> json) {
    final rawCategory = (json['category'] ?? json['tipo'] ?? 'Insumo').toString();
    final rawName = (json['name'] ?? json['nombre'] ?? '').toString();
    final rawCurrentStock = (json['current_stock'] as num?)?.toDouble() ?? (json['cantidad_actual_kg'] as num?)?.toDouble() ?? 0.0;
    final rawOriginalStock = (json['cantidad_original_kg'] as num?)?.toDouble() ?? rawCurrentStock;
    final rawCostTotal = (json['costo_total'] as num?)?.toDouble() ?? 0.0;
    final rawCostUnit = (json['costo_unitario_historico'] as num?)?.toDouble() ?? (rawCurrentStock > 0 ? rawCostTotal / rawCurrentStock : 0.0);
    final rawBrand = json['brand'] as String? ?? json['marca_proveedor'] as String?;
    final rawUnit = json['unit'] as String? ?? json['presentacion_unidad'] as String? ?? 'Kg';
    final rawProtein = (json['proteina_pct'] as num?)?.toDouble() ?? (json['proteina_cruda_pct'] as num?)?.toDouble();
    final rawCalibre = (json['calibre_mm'] as num?)?.toDouble() ?? (json['calibre_pellet_mm'] as num?)?.toDouble();
    final rawUnitId = json['unit_id'] as String? ?? json['unidad_acuicola_id'] as String?;

    return InventoryItem(
      id: (json['id'] ?? '').toString(),
      empresaId: (json['empresa_id'] ?? '').toString(),
      unidadAcuicolaId: rawUnitId,
      tipo: parseType(rawCategory),
      nombre: rawName,
      marcaProveedor: rawBrand,
      presentacionUnidad: rawUnit,
      cantidadOriginalKg: rawOriginalStock,
      cantidadActualKg: rawCurrentStock,
      costoTotal: rawCostTotal,
      costoUnitarioHistorico: rawCostUnit,
      stockMinimoAlerta: (json['stock_minimo_alerta'] as num?)?.toDouble() ?? 200.0,
      proteinaCrudaPct: rawProtein,
      calibrePelletMm: rawCalibre,
      especieAlevino: json['especie_alevino'] as String?,
      potenciaHp: (json['potencia_hp'] as num?)?.toDouble(),
      faseElectrica: json['fase_electrica'] as String?,
      estanqueAsignadoId: json['estanque_asignado_id'] as String?,
      diasRetiroSanitario: json['dias_retiro_sanitario'] as int?,
      principioActivo: json['principio_activo'] as String?,
      loteFabricante: json['lote_fabricante'] as String?,
      fechaVencimiento: json['fecha_vencimiento'] != null ? DateTime.parse(json['fecha_vencimiento'] as String) : null,
      creadoEn: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : (json['creado_en'] != null ? DateTime.parse(json['creado_en'] as String) : DateTime.now()),
    );
  }

  Map<String, dynamic> toJson() => toSupabaseJson();

  Map<String, dynamic> toSupabaseJson() => {
        'id': id,
        'empresa_id': empresaId,
        'unit_id': unidadAcuicolaId,
        'category': typeToString(tipo),
        'name': nombre,
        'brand': marcaProveedor,
        'unit': presentacionUnidad,
        'current_stock': cantidadActualKg,
        'costo_total': costoTotal,
        'costo_unitario_historico': costoUnitarioHistorico,
        'stock_minimo_alerta': stockMinimoAlerta,
        'proteina_pct': proteinaCrudaPct,
        'calibre_mm': calibrePelletMm,
        'especie_alevino': especieAlevino,
        'potencia_hp': potenciaHp,
        'fase_electrica': faseElectrica,
        'dias_retiro_sanitario': diasRetiroSanitario,
        'principio_activo': principioActivo,
        'lote_fabricante': loteFabricante,
        'fecha_vencimiento': fechaVencimiento?.toIso8601String().split('T')[0],
        'created_at': creadoEn.toIso8601String(),
      };
}
