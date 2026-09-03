/// Modelo de Registro Sanitario de Mortalidad Acuícola
class MortalityRecord {
  final String id;
  final String empresaId;
  final String unidadAcuicolaId;
  final String estanqueId;
  final String loteId;
  final int cantidadPecesMuertos;
  final double pesoPromedioGramos;
  final double biomasaPerdidaKg;
  final String causaProbable;
  final String? observaciones;
  final String? registradoPor;
  final DateTime fecha;
  final String? hora;
  final DateTime creadoEn;

  const MortalityRecord({
    required this.id,
    required this.empresaId,
    required this.unidadAcuicolaId,
    required this.estanqueId,
    required this.loteId,
    required this.cantidadPecesMuertos,
    required this.pesoPromedioGramos,
    required this.biomasaPerdidaKg,
    required this.causaProbable,
    this.observaciones,
    this.registradoPor,
    required this.fecha,
    this.hora,
    required this.creadoEn,
  });

  // Bilingual / synonym getters for cross-layer compatibility
  String get unitId => unidadAcuicolaId;
  String get batchId => loteId;
  DateTime get date => fecha;
  int get quantity => cantidadPecesMuertos;
  int get cantidad => cantidadPecesMuertos;
  String get cause => causaProbable;
  String get causa => causaProbable;
  double get avgWeightGr => pesoPromedioGramos;
  double get lostBiomassKg => biomasaPerdidaKg;

  factory MortalityRecord.fromJson(Map<String, dynamic> json) {
    DateTime parsedDate = DateTime.now();
    if (json['fecha'] != null) {
      parsedDate = DateTime.tryParse(json['fecha'].toString()) ?? DateTime.now();
    } else if (json['date'] != null) {
      final dStr = json['date'].toString();
      final hStr = json['hora']?.toString() ?? json['hour']?.toString() ?? '00:00:00';
      parsedDate = DateTime.tryParse('${dStr}T$hStr') ?? DateTime.tryParse(dStr) ?? DateTime.now();
    } else if (json['created_at'] != null) {
      parsedDate = DateTime.tryParse(json['created_at'].toString()) ?? DateTime.now();
    } else if (json['creado_en'] != null) {
      parsedDate = DateTime.tryParse(json['creado_en'].toString()) ?? DateTime.now();
    }

    final rawCantidad = json['cantidad_peces_muertos'] ?? json['cantidad'] ?? json['quantity'] ?? json['muertos'] ?? json['peces_muertos'];
    final rawPeso = json['peso_promedio_gramos'] ?? json['peso_promedio_g'] ?? json['peso_promedio'] ?? json['avg_weight_gr'] ?? json['pesoPromedioGramos'];
    final rawBiomasa = json['biomasa_perdida_kg'] ?? json['biomasa_perdida'] ?? json['lost_biomass_kg'] ?? json['biomasaPerdidaKg'];
    final rawCausa = json['causa_probable'] ?? json['causa'] ?? json['cause'] ?? json['causaProbable'] ?? 'Desconocida';

    final int cantidadVal = rawCantidad is num ? rawCantidad.toInt() : (int.tryParse(rawCantidad?.toString() ?? '') ?? 0);
    final double pesoVal = rawPeso is num ? rawPeso.toDouble() : (double.tryParse(rawPeso?.toString() ?? '') ?? 0.0);
    final double biomasaVal = rawBiomasa is num ? rawBiomasa.toDouble() : (double.tryParse(rawBiomasa?.toString() ?? '') ?? ((cantidadVal * pesoVal) / 1000.0));

    return MortalityRecord(
      id: json['id']?.toString() ?? '',
      empresaId: (json['empresa_id'] ?? json['empresaId'])?.toString() ?? '',
      unidadAcuicolaId: (json['unidad_acuicola_id'] ?? json['unit_id'] ?? json['unidadId'] ?? json['unitId'])?.toString() ?? '',
      estanqueId: (json['estanque_id'] ?? json['pond_id'] ?? json['estanqueId'])?.toString() ?? '',
      loteId: (json['lote_id'] ?? json['batch_id'] ?? json['loteId'] ?? json['batchId'])?.toString() ?? '',
      cantidadPecesMuertos: cantidadVal,
      pesoPromedioGramos: pesoVal,
      biomasaPerdidaKg: biomasaVal,
      causaProbable: rawCausa.toString(),
      observaciones: (json['observaciones'] ?? json['observations'] ?? json['notes'])?.toString(),
      registradoPor: (json['registrado_por'] ?? json['recorded_by'] ?? json['registradoPor'])?.toString(),
      fecha: parsedDate,
      hora: (json['hora'] ?? json['hour'] ?? json['time'])?.toString(),
      creadoEn: json['creado_en'] != null
          ? DateTime.tryParse(json['creado_en'].toString()) ?? parsedDate
          : (json['created_at'] != null ? DateTime.tryParse(json['created_at'].toString()) ?? parsedDate : parsedDate),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'empresa_id': empresaId,
        'unit_id': unidadAcuicolaId,
        'unidad_acuicola_id': unidadAcuicolaId,
        'estanque_id': estanqueId,
        'lote_id': loteId,
        'batch_id': loteId,
        'cantidad_peces_muertos': cantidadPecesMuertos,
        'cantidad': cantidadPecesMuertos,
        'quantity': cantidadPecesMuertos,
        'peso_promedio_gramos': pesoPromedioGramos,
        'biomasa_perdida_kg': biomasaPerdidaKg,
        'causa_probable': causaProbable,
        'causa': causaProbable,
        'cause': causaProbable,
        if (observaciones != null) 'observaciones': observaciones,
        if (registradoPor != null) 'registrado_por': registradoPor,
        'fecha': fecha.toIso8601String().split('T')[0],
        'date': fecha.toIso8601String().split('T')[0],
        'hora': hora ?? '${fecha.hour.toString().padLeft(2, '0')}:${fecha.minute.toString().padLeft(2, '0')}:00',
        'creado_en': creadoEn.toIso8601String(),
      };

  MortalityRecord copyWith({
    String? id,
    String? empresaId,
    String? unidadAcuicolaId,
    String? estanqueId,
    String? loteId,
    int? cantidadPecesMuertos,
    double? pesoPromedioGramos,
    double? biomasaPerdidaKg,
    String? causaProbable,
    String? observaciones,
    String? registradoPor,
    DateTime? fecha,
    String? hora,
    DateTime? creadoEn,
  }) {
    return MortalityRecord(
      id: id ?? this.id,
      empresaId: empresaId ?? this.empresaId,
      unidadAcuicolaId: unidadAcuicolaId ?? this.unidadAcuicolaId,
      estanqueId: estanqueId ?? this.estanqueId,
      loteId: loteId ?? this.loteId,
      cantidadPecesMuertos: cantidadPecesMuertos ?? this.cantidadPecesMuertos,
      pesoPromedioGramos: pesoPromedioGramos ?? this.pesoPromedioGramos,
      biomasaPerdidaKg: biomasaPerdidaKg ?? this.biomasaPerdidaKg,
      causaProbable: causaProbable ?? this.causaProbable,
      observaciones: observaciones ?? this.observaciones,
      registradoPor: registradoPor ?? this.registradoPor,
      fecha: fecha ?? this.fecha,
      hora: hora ?? this.hora,
      creadoEn: creadoEn ?? this.creadoEn,
    );
  }
}
