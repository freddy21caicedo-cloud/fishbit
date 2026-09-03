/// Parámetros fisicoquímicos del agua para control y alertas
class WaterParameter {
  final String id;
  final String empresaId;
  final String unidadAcuicolaId;
  final String estanqueId;
  final DateTime fecha;
  final double? oxigenoMgL;
  final double? oxigenoPct;
  final double? ph;
  final double? temperaturaC;
  final double? amonioMgL;
  final double? nitritosMgL;
  final double? nitratosMgL;
  final double? alcalinidadMgL;
  final double? co2MgL;
  final double? durezaMgL;
  final double? cloroMgL;
  final String? observaciones;
  final String? registradoPor;

  const WaterParameter({
    required this.id,
    required this.empresaId,
    required this.unidadAcuicolaId,
    required this.estanqueId,
    required this.fecha,
    this.oxigenoMgL,
    this.oxigenoPct,
    this.ph,
    this.temperaturaC,
    this.amonioMgL,
    this.nitritosMgL,
    this.nitratosMgL,
    this.alcalinidadMgL,
    this.co2MgL,
    this.durezaMgL,
    this.cloroMgL,
    this.observaciones,
    this.registradoPor,
  });

  bool get isOxygenCritical => oxigenoMgL != null && oxigenoMgL! < 3.5;
  bool get isPhCritical => ph != null && (ph! < 6.0 || ph! > 9.0);
  bool get isAmmoniaCritical => amonioMgL != null && amonioMgL! > 0.5;
  bool get isNitriteCritical => nitritosMgL != null && nitritosMgL! > 0.2;
  bool get isCo2Critical => co2MgL != null && co2MgL! > 20.0;
  bool get isChlorineCritical => cloroMgL != null && cloroMgL! > 0.05;

  factory WaterParameter.fromJson(Map<String, dynamic> json) {
    DateTime parsedDate = DateTime.now();
    if (json['fecha'] != null) {
      parsedDate = DateTime.tryParse(json['fecha'].toString()) ?? DateTime.now();
    } else if (json['created_at'] != null) {
      parsedDate = DateTime.tryParse(json['created_at'].toString()) ?? DateTime.now();
    } else if (json['date'] != null) {
      final dStr = json['date'].toString();
      final hStr = json['hour']?.toString() ?? '00:00:00';
      parsedDate = DateTime.tryParse('${dStr}T$hStr') ?? DateTime.tryParse(dStr) ?? DateTime.now();
    }

    return WaterParameter(
      id: json['id']?.toString() ?? '',
      empresaId: (json['empresa_id'] ?? json['empresaId'])?.toString() ?? '',
      unidadAcuicolaId: (json['unidad_acuicola_id'] ?? json['unit_id'] ?? json['unidadId'])?.toString() ?? '',
      estanqueId: (json['estanque_id'] ?? json['pond_id'] ?? json['estanqueId'])?.toString() ?? '',
      fecha: parsedDate,
      oxigenoMgL: (json['oxigeno_mg_l'] ?? json['o2_mg_l'] ?? json['oxygen']) != null ? double.tryParse((json['oxigeno_mg_l'] ?? json['o2_mg_l'] ?? json['oxygen']).toString()) : null,
      oxigenoPct: (json['oxigeno_pct'] ?? json['o2_perc'] ?? json['oxygen_pct']) != null ? double.tryParse((json['oxigeno_pct'] ?? json['o2_perc'] ?? json['oxygen_pct']).toString()) : null,
      ph: json['ph'] != null ? double.tryParse(json['ph'].toString()) : null,
      temperaturaC: (json['temperatura_c'] ?? json['temperatura'] ?? json['temperature_c'] ?? json['temperature']) != null ? double.tryParse((json['temperatura_c'] ?? json['temperatura'] ?? json['temperature_c'] ?? json['temperature']).toString()) : null,
      amonioMgL: (json['amonio_mg_l'] ?? json['ammonia_mg_l'] ?? json['ammonia']) != null ? double.tryParse((json['amonio_mg_l'] ?? json['ammonia_mg_l'] ?? json['ammonia']).toString()) : null,
      nitritosMgL: (json['nitritos_mg_l'] ?? json['nitrite_mg_l'] ?? json['nitrite']) != null ? double.tryParse((json['nitritos_mg_l'] ?? json['nitrite_mg_l'] ?? json['nitrite']).toString()) : null,
      nitratosMgL: (json['nitratos_mg_l'] ?? json['nitrate_mg_l'] ?? json['nitrate']) != null ? double.tryParse((json['nitratos_mg_l'] ?? json['nitrate_mg_l'] ?? json['nitrate']).toString()) : null,
      alcalinidadMgL: (json['alcalinidad_mg_l'] ?? json['alkalinity']) != null ? double.tryParse((json['alcalinidad_mg_l'] ?? json['alkalinity']).toString()) : null,
      co2MgL: (json['co2_mg_l'] ?? json['co2']) != null ? double.tryParse((json['co2_mg_l'] ?? json['co2']).toString()) : null,
      durezaMgL: (json['dureza_mg_l'] ?? json['hardness']) != null ? double.tryParse((json['dureza_mg_l'] ?? json['hardness']).toString()) : null,
      cloroMgL: (json['cloro_mg_l'] ?? json['chlorine']) != null ? double.tryParse((json['cloro_mg_l'] ?? json['chlorine']).toString()) : null,
      observaciones: (json['observaciones'] ?? json['observations'] ?? json['notes'])?.toString(),
      registradoPor: (json['registrado_por'] ?? json['recorded_by'])?.toString(),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'empresa_id': empresaId,
        'unit_id': unidadAcuicolaId,
        'unidad_acuicola_id': unidadAcuicolaId,
        'estanque_id': estanqueId,
        'fecha': fecha.toIso8601String(),
        'hora': '${fecha.hour.toString().padLeft(2, '0')}:${fecha.minute.toString().padLeft(2, '0')}:00',
        'oxigeno_mg_l': oxigenoMgL,
        'oxigeno_pct': oxigenoPct,
        'ph': ph,
        'temperatura_c': temperaturaC,
        'temperatura': temperaturaC,
        'amonio_mg_l': amonioMgL,
        'nitritos_mg_l': nitritosMgL,
        'nitratos_mg_l': nitratosMgL,
        'alcalinidad_mg_l': alcalinidadMgL,
        'co2_mg_l': co2MgL,
        'dureza_mg_l': durezaMgL,
        'cloro_mg_l': cloroMgL,
        'observaciones': observaciones,
        'registrado_por': registradoPor,
      };
}
