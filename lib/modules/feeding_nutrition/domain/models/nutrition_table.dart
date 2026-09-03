/// Tabla nutricional de referencia por especie y etapa de cultivo
class NutritionTable {
  final String id;
  final String empresaId;
  final String? unidadAcuicolaId;
  final String especie;
  final String? etapa;
  final int? semana;
  final double pesoMinG;
  final double pesoMaxG;
  final double tasaAlimentacionPct;
  final int racionesDia;

  const NutritionTable({
    required this.id,
    required this.empresaId,
    this.unidadAcuicolaId,
    required this.especie,
    this.etapa,
    this.semana,
    required this.pesoMinG,
    required this.pesoMaxG,
    required this.tasaAlimentacionPct,
    this.racionesDia = 3,
  });

  factory NutritionTable.fromJson(Map<String, dynamic> json) {
    return NutritionTable(
      id: json['id'] as String,
      empresaId: json['empresa_id'] as String? ?? '',
      unidadAcuicolaId: json['unidad_acuicola_id'] as String?,
      especie: json['especie'] as String? ?? '',
      etapa: json['etapa'] as String?,
      semana: json['semana'] as int?,
      pesoMinG: (json['peso_min_g'] as num?)?.toDouble() ?? 0.0,
      pesoMaxG: (json['peso_max_g'] as num?)?.toDouble() ?? 0.0,
      tasaAlimentacionPct: (json['tasa_alimentacion_pct'] as num?)?.toDouble() ?? 3.0,
      racionesDia: json['raciones_dia'] as int? ?? 3,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'empresa_id': empresaId,
        'unidad_acuicola_id': unidadAcuicolaId,
        'especie': especie,
        'etapa': etapa,
        'semana': semana,
        'peso_min_g': pesoMinG,
        'peso_max_g': pesoMaxG,
        'tasa_alimentacion_pct': tasaAlimentacionPct,
        'raciones_dia': racionesDia,
      };
}
