/// Modelo de Registro de Muestreo Biométrico Acuícola
class BiometriaRecord {
  final String id;
  final String empresaId;
  final String unitId;
  final String estanqueId;
  final String loteId;
  final DateTime fecha;
  final String? hora;
  final int pecesCapturados;
  final double pesoTotalCapturaKg;
  final double pesoPromedioG;
  final double biomasaParcialKg;
  final double? longitudCm;
  final double? factorK;
  final double? gdpGDia;
  final String? observaciones;
  final String? registradoPor;
  final DateTime creadoEn;

  const BiometriaRecord({
    required this.id,
    required this.empresaId,
    required this.unitId,
    required this.estanqueId,
    required this.loteId,
    required this.fecha,
    this.hora,
    required this.pecesCapturados,
    required this.pesoTotalCapturaKg,
    required this.pesoPromedioG,
    required this.biomasaParcialKg,
    this.longitudCm,
    this.factorK,
    this.gdpGDia,
    this.observaciones,
    this.registradoPor,
    required this.creadoEn,
  });

  // Bilingual / synonym getters for flexibility across layers
  String get batchId => loteId;
  DateTime get date => fecha;
  String get unidadAcuicolaId => unitId;
  double get avgWeightGr => pesoPromedioG;
  double get totalBiomassKg => biomasaParcialKg;
  int get pecesMuestreados => pecesCapturados;

  factory BiometriaRecord.fromJson(Map<String, dynamic> json) {
    DateTime parsedFecha = DateTime.now();
    if (json['fecha'] != null) {
      parsedFecha = DateTime.tryParse(json['fecha'].toString()) ?? DateTime.now();
    } else if (json['date'] != null) {
      final dStr = json['date'].toString();
      final hStr = json['hora']?.toString() ?? json['hour']?.toString() ?? '00:00:00';
      parsedFecha = DateTime.tryParse('${dStr}T$hStr') ?? DateTime.tryParse(dStr) ?? DateTime.now();
    } else if (json['created_at'] != null) {
      parsedFecha = DateTime.tryParse(json['created_at'].toString()) ?? DateTime.now();
    } else if (json['creado_en'] != null) {
      parsedFecha = DateTime.tryParse(json['creado_en'].toString()) ?? DateTime.now();
    }

    final rawPeces = json['peces_capturados'] ?? json['peces_muestreados'] ?? json['sample_count'] ?? json['pecesCapturados'] ?? json['cantidad_peces'];
    final rawPesoTotalKg = json['peso_total_captura_kg'] ?? json['sample_total_weight_kg'] ?? json['pesoTotalCapturaKg'] ?? json['peso_total_kg'];
    final rawPesoPromG = json['peso_promedio_g'] ?? json['avg_weight_gr'] ?? json['peso_promedio_gramos'] ?? json['pesoPromedioG'] ?? json['peso_promedio'];
    final rawBiomasaKg = json['biomasa_parcial_kg'] ?? json['total_biomass_kg'] ?? json['biomasaParcialKg'] ?? json['biomasa_kg'] ?? json['biomasa_total_kg'];
    final rawLongitud = json['longitud_cm'] ?? json['length_cm'] ?? json['longitudCm'] ?? json['longitud'];
    final rawFactorK = json['factor_k'] ?? json['factorK'];
    final rawGdp = json['gdp_g_dia'] ?? json['adg_g_day'] ?? json['gdpGDia'] ?? json['gdp'];

    return BiometriaRecord(
      id: json['id']?.toString() ?? '',
      empresaId: (json['empresa_id'] ?? json['empresaId'])?.toString() ?? '',
      unitId: (json['unit_id'] ?? json['unidad_acuicola_id'] ?? json['unidadId'] ?? json['unitId'])?.toString() ?? '',
      estanqueId: (json['estanque_id'] ?? json['pond_id'] ?? json['estanqueId'])?.toString() ?? '',
      loteId: (json['lote_id'] ?? json['batch_id'] ?? json['loteId'] ?? json['batchId'])?.toString() ?? '',
      fecha: parsedFecha,
      hora: (json['hora'] ?? json['hour'] ?? json['time'])?.toString(),
      pecesCapturados: rawPeces is num ? rawPeces.toInt() : (int.tryParse(rawPeces?.toString() ?? '') ?? 0),
      pesoTotalCapturaKg: rawPesoTotalKg is num ? rawPesoTotalKg.toDouble() : (double.tryParse(rawPesoTotalKg?.toString() ?? '') ?? 0.0),
      pesoPromedioG: rawPesoPromG is num ? rawPesoPromG.toDouble() : (double.tryParse(rawPesoPromG?.toString() ?? '') ?? 0.0),
      biomasaParcialKg: rawBiomasaKg is num ? rawBiomasaKg.toDouble() : (double.tryParse(rawBiomasaKg?.toString() ?? '') ?? 0.0),
      longitudCm: rawLongitud != null ? (rawLongitud is num ? rawLongitud.toDouble() : double.tryParse(rawLongitud.toString())) : null,
      factorK: rawFactorK != null ? (rawFactorK is num ? rawFactorK.toDouble() : double.tryParse(rawFactorK.toString())) : null,
      gdpGDia: rawGdp != null ? (rawGdp is num ? rawGdp.toDouble() : double.tryParse(rawGdp.toString())) : null,
      observaciones: (json['observaciones'] ?? json['observations'] ?? json['notes'])?.toString(),
      registradoPor: (json['registrado_por'] ?? json['recorded_by'] ?? json['registradoPor'])?.toString(),
      creadoEn: json['creado_en'] != null
          ? DateTime.tryParse(json['creado_en'].toString()) ?? parsedFecha
          : (json['created_at'] != null ? DateTime.tryParse(json['created_at'].toString()) ?? parsedFecha : parsedFecha),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'empresa_id': empresaId,
        'unit_id': unitId,
        'unidad_acuicola_id': unitId,
        'estanque_id': estanqueId,
        'lote_id': loteId,
        'batch_id': loteId,
        'fecha': fecha.toIso8601String().split('T')[0],
        'date': fecha.toIso8601String().split('T')[0],
        'hora': hora ?? '${fecha.hour.toString().padLeft(2, '0')}:${fecha.minute.toString().padLeft(2, '0')}:00',
        'peces_capturados': pecesCapturados,
        'peso_total_captura_kg': pesoTotalCapturaKg,
        'peso_promedio_g': pesoPromedioG,
        'avg_weight_gr': pesoPromedioG,
        'biomasa_parcial_kg': biomasaParcialKg,
        'total_biomass_kg': biomasaParcialKg,
        if (longitudCm != null) 'longitud_cm': longitudCm,
        if (factorK != null) 'factor_k': factorK,
        if (gdpGDia != null) 'gdp_g_dia': gdpGDia,
        if (observaciones != null) 'observaciones': observaciones,
        if (registradoPor != null) 'registrado_por': registradoPor,
        'creado_en': creadoEn.toIso8601String(),
      };

  BiometriaRecord copyWith({
    String? id,
    String? empresaId,
    String? unitId,
    String? estanqueId,
    String? loteId,
    DateTime? fecha,
    String? hora,
    int? pecesCapturados,
    double? pesoTotalCapturaKg,
    double? pesoPromedioG,
    double? biomasaParcialKg,
    double? longitudCm,
    double? factorK,
    double? gdpGDia,
    String? observaciones,
    String? registradoPor,
    DateTime? creadoEn,
  }) {
    return BiometriaRecord(
      id: id ?? this.id,
      empresaId: empresaId ?? this.empresaId,
      unitId: unitId ?? this.unitId,
      estanqueId: estanqueId ?? this.estanqueId,
      loteId: loteId ?? this.loteId,
      fecha: fecha ?? this.fecha,
      hora: hora ?? this.hora,
      pecesCapturados: pecesCapturados ?? this.pecesCapturados,
      pesoTotalCapturaKg: pesoTotalCapturaKg ?? this.pesoTotalCapturaKg,
      pesoPromedioG: pesoPromedioG ?? this.pesoPromedioG,
      biomasaParcialKg: biomasaParcialKg ?? this.biomasaParcialKg,
      longitudCm: longitudCm ?? this.longitudCm,
      factorK: factorK ?? this.factorK,
      gdpGDia: gdpGDia ?? this.gdpGDia,
      observaciones: observaciones ?? this.observaciones,
      registradoPor: registradoPor ?? this.registradoPor,
      creadoEn: creadoEn ?? this.creadoEn,
    );
  }
}
