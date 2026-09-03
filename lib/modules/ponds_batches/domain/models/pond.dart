enum PondStatus { active, harvested, available }

/// Entidad inmutable de Estanque Físico de cultivo
class Pond {
  final String id;
  final String empresaId;
  final String unidadAcuicolaId;
  final String nombre;
  final String sigla;
  final double capacidadM3;
  final double? largoM;
  final double? anchoM;
  final double? profundidadM;
  final String especieActual;
  final double biomasaKg;
  final double costoAcumuladoBiologico;
  final PondStatus estado;
  final bool aireacionActiva;
  final bool isDeleted;
  final DateTime creadoEn;

  const Pond({
    required this.id,
    required this.empresaId,
    required this.unidadAcuicolaId,
    required this.nombre,
    required this.sigla,
    required this.capacidadM3,
    this.largoM,
    this.anchoM,
    this.profundidadM,
    this.especieActual = '',
    this.biomasaKg = 0.0,
    this.costoAcumuladoBiologico = 0.0,
    this.estado = PondStatus.available,
    this.aireacionActiva = false,
    this.isDeleted = false,
    required this.creadoEn,
  });

  Pond copyWith({
    String? id,
    String? empresaId,
    String? unidadAcuicolaId,
    String? nombre,
    String? sigla,
    double? capacidadM3,
    double? largoM,
    double? anchoM,
    double? profundidadM,
    String? especieActual,
    double? biomasaKg,
    double? costoAcumuladoBiologico,
    PondStatus? estado,
    bool? aireacionActiva,
    bool? isDeleted,
    DateTime? creadoEn,
  }) {
    return Pond(
      id: id ?? this.id,
      empresaId: empresaId ?? this.empresaId,
      unidadAcuicolaId: unidadAcuicolaId ?? this.unidadAcuicolaId,
      nombre: nombre ?? this.nombre,
      sigla: sigla ?? this.sigla,
      capacidadM3: capacidadM3 ?? this.capacidadM3,
      largoM: largoM ?? this.largoM,
      anchoM: anchoM ?? this.anchoM,
      profundidadM: profundidadM ?? this.profundidadM,
      especieActual: especieActual ?? this.especieActual,
      biomasaKg: biomasaKg ?? this.biomasaKg,
      costoAcumuladoBiologico: costoAcumuladoBiologico ?? this.costoAcumuladoBiologico,
      estado: estado ?? this.estado,
      aireacionActiva: aireacionActiva ?? this.aireacionActiva,
      isDeleted: isDeleted ?? this.isDeleted,
      creadoEn: creadoEn ?? this.creadoEn,
    );
  }

  /// Costo acumulado de producción por kilogramo de biomasa (CPK)
  double get costoPorKg => biomasaKg > 0 ? (costoAcumuladoBiologico / biomasaKg) : 0.0;

  /// Densidad de cultivo en kg/m3
  double get densidadKgM3 => capacidadM3 > 0 ? (biomasaKg / capacidadM3) : 0.0;

  /// Semáforo de capacidad de carga: 'Óptimo' (<8), 'Alerta' (8-16), 'Crítico' (>16)
  String get nivelRiesgoDensidad {
    final d = densidadKgM3;
    if (d <= 8.0) return 'Óptimo';
    if (d <= 16.0) return 'Alerta';
    return 'Crítico';
  }

  /// Nombre formateado y limpio para presentación en UI (ej. "Estanque 1" en lugar de "EST - ESTANQUE 1")
  String get nombreLimpio {
    String n = nombre.trim();
    if (n.toUpperCase().startsWith('EST - ')) {
      n = n.substring(6).trim();
    } else if (n.toUpperCase().startsWith('EST-')) {
      n = n.substring(4).trim();
    }
    // Normalizar capitalización si está todo en mayúsculas
    if (n == n.toUpperCase() && n.length > 3) {
      n = n.split(' ').map((w) => w.isNotEmpty ? '${w[0].toUpperCase()}${w.substring(1).toLowerCase()}' : '').join(' ');
    }
    return n.isNotEmpty ? n : sigla;
  }

  /// Identificador visual completo para tarjetas, bitácora y cabeceras
  String get identificadorVisual => '$nombreLimpio (${sigla.split('-').first.trim()})';

  /// HP de aireación mecánica sugerido (1 HP por cada 1.000 kg de biomasa en alta densidad)
  double get hpAireacionSugerido => (biomasaKg / 1000.0) * (densidadKgM3 > 10 ? 1.2 : 0.8);

  static PondStatus parseStatus(String val) {
    switch (val.toLowerCase()) {
      case 'activo':
      case 'active':
        return PondStatus.active;
      case 'cosechado':
      case 'harvested':
        return PondStatus.harvested;
      default:
        return PondStatus.available;
    }
  }

  static String statusToString(PondStatus s) {
    switch (s) {
      case PondStatus.active:
        return 'Activo';
      case PondStatus.harvested:
        return 'Cosechado';
      case PondStatus.available:
        return 'Disponible';
    }
  }

  factory Pond.fromJson(Map<String, dynamic> json) {
    DateTime createdAt = DateTime.now();
    if (json['creado_en'] != null) {
      createdAt = DateTime.tryParse(json['creado_en'].toString()) ?? DateTime.now();
    } else if (json['created_at'] != null) {
      createdAt = DateTime.tryParse(json['created_at'].toString()) ?? DateTime.now();
    }

    return Pond(
      id: (json['id'] ?? '').toString(),
      empresaId: (json['empresa_id'] ?? json['unidad_acuicola_id'] ?? '').toString(),
      unidadAcuicolaId: (json['unidad_acuicola_id'] ?? json['empresa_id'] ?? '').toString(),
      nombre: (json['nombre'] ?? json['name'] ?? '').toString(),
      sigla: (json['sigla'] ?? '').toString(),
      capacidadM3: (json['capacidad_m3'] as num?)?.toDouble() ?? 50.0,
      largoM: (json['largo_m'] as num?)?.toDouble(),
      anchoM: (json['ancho_m'] as num?)?.toDouble(),
      profundidadM: (json['profundidad_m'] as num?)?.toDouble(),
      especieActual: (json['especie_actual'] ?? '').toString(),
      biomasaKg: (json['biomasa_kg'] as num?)?.toDouble() ?? 0.0,
      costoAcumuladoBiologico: (json['costo_acumulado_biologico'] as num?)?.toDouble() ?? 0.0,
      estado: parseStatus((json['estado'] ?? 'Disponible').toString()),
      aireacionActiva: json['aireacion_activa'] == true,
      isDeleted: json['is_deleted'] == true,
      creadoEn: createdAt,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'empresa_id': empresaId,
        'unidad_acuicola_id': unidadAcuicolaId,
        'nombre': nombre,
        'sigla': sigla,
        'capacidad_m3': capacidadM3,
        'largo_m': largoM,
        'ancho_m': anchoM,
        'profundidad_m': profundidadM,
        'especie_actual': especieActual,
        'biomasa_kg': biomasaKg,
        'costo_acumulado_biologico': costoAcumuladoBiologico,
        'estado': statusToString(estado),
        'aireacion_activa': aireacionActiva,
        'is_deleted': isDeleted,
      };
}
