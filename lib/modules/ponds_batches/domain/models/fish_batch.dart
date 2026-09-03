enum BatchStatus { active, harvested, divided }

/// Entidad inmutable de Lote de Peces (Centro de Costo Móvil)
class FishBatch {
  final String id;
  final String empresaId;
  final String unidadAcuicolaId;
  final String estanqueId;
  final String? lotePadreId;
  final String codigoLote;
  final String especie;
  final String rolPolicultivo; // 'principal', 'secundaria', 'asociada'
  final int cantidadInicialPeces;
  final int cantidadActualPeces;
  final double pesoInicialGramos;
  final double pesoActualGramos;
  final double biomasaInicialKg;
  final double biomasaActualKg;
  final double alimentoAcumuladoKg;
  final int diasRetiroSanitarioRestantes;
  final double costoInicialAlevinos;
  final double costoAcumuladoInsumos;
  final double costoAcumuladoFijo;
  final BatchStatus estado;
  final DateTime fechaSiembra;
  final DateTime? fechaCosechaEstimada;
  final DateTime creadoEn;

  const FishBatch({
    required this.id,
    required this.empresaId,
    required this.unidadAcuicolaId,
    required this.estanqueId,
    this.lotePadreId,
    required this.codigoLote,
    required this.especie,
    this.rolPolicultivo = 'principal',
    required this.cantidadInicialPeces,
    required this.cantidadActualPeces,
    this.pesoInicialGramos = 1.0,
    this.pesoActualGramos = 1.0,
    this.biomasaInicialKg = 0.0,
    this.biomasaActualKg = 0.0,
    this.alimentoAcumuladoKg = 0.0,
    this.diasRetiroSanitarioRestantes = 0,
    this.costoInicialAlevinos = 0.0,
    this.costoAcumuladoInsumos = 0.0,
    this.costoAcumuladoFijo = 0.0,
    this.estado = BatchStatus.active,
    required this.fechaSiembra,
    this.fechaCosechaEstimada,
    required this.creadoEn,
  });

  int get diasDeCultivo {
    final diff = DateTime.now().difference(fechaSiembra).inDays;
    return diff > 0 ? diff : 1;
  }

  /// Factor de Conversión Alimenticia (FCR) = Kg Alimento / Ganancia de Biomasa
  double get fcr {
    final gananciaBiomasa = biomasaActualKg - biomasaInicialKg;
    if (alimentoAcumuladoKg > 0 && gananciaBiomasa > 0) {
      return alimentoAcumuladoKg / gananciaBiomasa;
    }
    // Estimación técnica por peso si no hay registro consolidado de alimento
    if (pesoActualGramos > pesoInicialGramos) {
      if (pesoActualGramos < 50) return 1.1;
      if (pesoActualGramos < 200) return 1.3;
      if (pesoActualGramos < 450) return 1.45;
      return 1.6;
    }
    return 1.35;
  }

  /// Ganancia de Peso Diario (GPD en gramos/día)
  double get gpd {
    final dias = diasDeCultivo;
    if (dias <= 0) return 0.0;
    final gananciaGramos = pesoActualGramos - pesoInicialGramos;
    return gananciaGramos > 0 ? (gananciaGramos / dias) : 0.0;
  }

  /// Indica si el lote está bloqueado para cosecha por tiempo de retiro de medicamentos (ICA)
  bool get enPeriodoRetiro => diasRetiroSanitarioRestantes > 0;

  FishBatch copyWith({
    String? id,
    String? empresaId,
    String? unidadAcuicolaId,
    String? estanqueId,
    String? lotePadreId,
    String? codigoLote,
    String? especie,
    String? rolPolicultivo,
    int? cantidadInicialPeces,
    int? cantidadActualPeces,
    double? pesoInicialGramos,
    double? pesoActualGramos,
    double? biomasaInicialKg,
    double? biomasaActualKg,
    double? alimentoAcumuladoKg,
    int? diasRetiroSanitarioRestantes,
    double? costoInicialAlevinos,
    double? costoAcumuladoInsumos,
    double? costoAcumuladoFijo,
    BatchStatus? estado,
    DateTime? fechaSiembra,
    DateTime? fechaCosechaEstimada,
    DateTime? creadoEn,
  }) {
    return FishBatch(
      id: id ?? this.id,
      empresaId: empresaId ?? this.empresaId,
      unidadAcuicolaId: unidadAcuicolaId ?? this.unidadAcuicolaId,
      estanqueId: estanqueId ?? this.estanqueId,
      lotePadreId: lotePadreId ?? this.lotePadreId,
      codigoLote: codigoLote ?? this.codigoLote,
      especie: especie ?? this.especie,
      rolPolicultivo: rolPolicultivo ?? this.rolPolicultivo,
      cantidadInicialPeces: cantidadInicialPeces ?? this.cantidadInicialPeces,
      cantidadActualPeces: cantidadActualPeces ?? this.cantidadActualPeces,
      pesoInicialGramos: pesoInicialGramos ?? this.pesoInicialGramos,
      pesoActualGramos: pesoActualGramos ?? this.pesoActualGramos,
      biomasaInicialKg: biomasaInicialKg ?? this.biomasaInicialKg,
      biomasaActualKg: biomasaActualKg ?? this.biomasaActualKg,
      alimentoAcumuladoKg: alimentoAcumuladoKg ?? this.alimentoAcumuladoKg,
      diasRetiroSanitarioRestantes: diasRetiroSanitarioRestantes ?? this.diasRetiroSanitarioRestantes,
      costoInicialAlevinos: costoInicialAlevinos ?? this.costoInicialAlevinos,
      costoAcumuladoInsumos: costoAcumuladoInsumos ?? this.costoAcumuladoInsumos,
      costoAcumuladoFijo: costoAcumuladoFijo ?? this.costoAcumuladoFijo,
      estado: estado ?? this.estado,
      fechaSiembra: fechaSiembra ?? this.fechaSiembra,
      fechaCosechaEstimada: fechaCosechaEstimada ?? this.fechaCosechaEstimada,
      creadoEn: creadoEn ?? this.creadoEn,
    );
  }

  /// Costo Total Acumulado en el lote
  double get costoTotal => costoInicialAlevinos + costoAcumuladoInsumos + costoAcumuladoFijo;

  /// Costo por Kilogramo producido (CPK)
  double get cpk => biomasaActualKg > 0 ? (costoTotal / biomasaActualKg) : 0.0;

  /// Mortalidad acumulada en porcentaje
  double get porcentajeMortalidad {
    if (cantidadInicialPeces <= 0) return 0.0;
    final muertos = cantidadInicialPeces - cantidadActualPeces;
    return (muertos / cantidadInicialPeces) * 100.0;
  }

  static BatchStatus parseStatus(String val) {
    switch (val.toLowerCase()) {
      case 'activo':
      case 'active':
        return BatchStatus.active;
      case 'cosechado':
      case 'harvested':
        return BatchStatus.harvested;
      default:
        return BatchStatus.divided;
    }
  }

  static String statusToString(BatchStatus s) {
    switch (s) {
      case BatchStatus.active:
        return 'Activo';
      case BatchStatus.harvested:
        return 'Cosechado';
      case BatchStatus.divided:
        return 'Dividido';
    }
  }

  factory FishBatch.fromJson(Map<String, dynamic> json) {
    return FishBatch(
      id: json['id'] as String,
      empresaId: json['empresa_id'] as String? ?? '',
      unidadAcuicolaId: json['unidad_acuicola_id'] as String? ?? '',
      estanqueId: json['estanque_id'] as String? ?? '',
      lotePadreId: json['lote_padre_id'] as String?,
      codigoLote: json['codigo_lote'] as String? ?? '',
      especie: json['especie'] as String? ?? '',
      rolPolicultivo: json['rol_policultivo'] as String? ?? 'principal',
      cantidadInicialPeces: json['cantidad_inicial_peces'] as int? ?? 0,
      cantidadActualPeces: json['cantidad_actual_peces'] as int? ?? 0,
      pesoInicialGramos: (json['peso_inicial_gramos'] as num?)?.toDouble() ?? 1.0,
      pesoActualGramos: (json['peso_actual_gramos'] as num?)?.toDouble() ?? 1.0,
      biomasaInicialKg: (json['biomasa_inicial_kg'] as num?)?.toDouble() ?? 0.0,
      biomasaActualKg: (json['biomasa_actual_kg'] as num?)?.toDouble() ?? 0.0,
      alimentoAcumuladoKg: (json['alimento_acumulado_kg'] as num?)?.toDouble() ?? 0.0,
      diasRetiroSanitarioRestantes: json['dias_retiro_sanitario_restantes'] as int? ?? 0,
      costoInicialAlevinos: (json['costo_inicial_alevinos'] as num?)?.toDouble() ?? 0.0,
      costoAcumuladoInsumos: (json['costo_acumulado_insumos'] as num?)?.toDouble() ?? 0.0,
      costoAcumuladoFijo: (json['costo_acumulado_fijo'] as num?)?.toDouble() ?? 0.0,
      estado: parseStatus(json['estado'] as String? ?? 'Activo'),
      fechaSiembra: json['fecha_siembra'] != null
          ? DateTime.parse(json['fecha_siembra'] as String)
          : DateTime.now(),
      fechaCosechaEstimada: json['fecha_cosecha_estimada'] != null
          ? DateTime.parse(json['fecha_cosecha_estimada'] as String)
          : null,
      creadoEn: json['creado_en'] != null
          ? DateTime.parse(json['creado_en'] as String)
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'empresa_id': empresaId,
        'unidad_acuicola_id': unidadAcuicolaId,
        'estanque_id': estanqueId,
        'lote_padre_id': lotePadreId,
        'codigo_lote': codigoLote,
        'especie': especie,
        'rol_policultivo': rolPolicultivo,
        'cantidad_inicial_peces': cantidadInicialPeces,
        'cantidad_actual_peces': cantidadActualPeces,
        'peso_inicial_gramos': pesoInicialGramos,
        'peso_actual_gramos': pesoActualGramos,
        'biomasa_inicial_kg': biomasaInicialKg,
        'biomasa_actual_kg': biomasaActualKg,
        'costo_inicial_alevinos': costoInicialAlevinos,
        'costo_acumulado_insumos': costoAcumuladoInsumos,
        'costo_acumulado_fijo': costoAcumuladoFijo,
        'estado': statusToString(estado),
        'fecha_siembra': fechaSiembra.toIso8601String().split('T')[0],
      };
}
