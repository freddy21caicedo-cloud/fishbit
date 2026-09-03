import 'package:uuid/uuid.dart';

class IcaNecropsiaRecord {
  final String id;
  final String empresaId;
  final String unidadAcuicolaId;
  final String? estanqueId;
  final String? estanqueNombre;
  final String? loteCodigo;
  final DateTime fecha;
  final String especie;
  final int numeroEjemplares;
  final double pesoPromedioGramos;
  final double? tallaPromedioCm;
  // Signología externa
  final String hallazgosPielAletas;
  final String hallazgosOjos;
  final String hallazgosBranquias;
  final bool presenciaEctoparasitos;
  // Signología interna
  final String hallazgosHigado;
  final String hallazgosBazo;
  final String hallazgosIntestinoEstomago;
  final String hallazgosCavidadCelomica;
  final String hallazgosRinon;
  // Diagnóstico y conducta
  final String diagnosticoPresuntivo;
  final bool envioMuestrasLaboratorio;
  final String? tipoMuestraEnviada;
  final String conductaTratamiento;
  final String profesionalResponsable;
  final String? tarjetaProfesional;
  final DateTime createdAt;

  IcaNecropsiaRecord({
    String? id,
    required this.empresaId,
    required this.unidadAcuicolaId,
    this.estanqueId,
    this.estanqueNombre,
    this.loteCodigo,
    required this.fecha,
    required this.especie,
    this.numeroEjemplares = 2,
    this.pesoPromedioGramos = 250.0,
    this.tallaPromedioCm,
    this.hallazgosPielAletas = 'Piel y aletas íntegras, sin úlceras ni necrosis',
    this.hallazgosOjos = 'Ojos claros, transparentes, sin exoftalmia',
    this.hallazgosBranquias = 'Branquias de color rojo brillante, sin exceso de mucus ni parásitos',
    this.presenciaEctoparasitos = false,
    this.hallazgosHigado = 'Hígado con coloración rojiza homogénea, consistencia normal',
    this.hallazgosBazo = 'Bazo de tamaño normal, sin esplenomegalia',
    this.hallazgosIntestinoEstomago = 'Tracto digestivo con contenido alimenticio normal, sin enteritis',
    this.hallazgosCavidadCelomica = 'Cavidad celómica libre de líquido / sin ascitis',
    this.hallazgosRinon = 'Riñón posterior de aspecto normal, sin hipertrofia',
    required this.diagnosticoPresuntivo,
    this.envioMuestrasLaboratorio = false,
    this.tipoMuestraEnviada,
    required this.conductaTratamiento,
    required this.profesionalResponsable,
    this.tarjetaProfesional,
    DateTime? createdAt,
  })  : id = id ?? const Uuid().v4(),
        createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'empresa_id': empresaId,
      'unidad_acuicola_id': unidadAcuicolaId,
      'estanque_id': estanqueId,
      'estanque_nombre': estanqueNombre,
      'lote_codigo': loteCodigo,
      'fecha': fecha.toIso8601String().split('T')[0],
      'especie': especie,
      'numero_ejemplares': numeroEjemplares,
      'peso_promedio_gramos': pesoPromedioGramos,
      'talla_promedio_cm': tallaPromedioCm,
      'hallazgos_piel_aletas': hallazgosPielAletas,
      'hallazgos_ojos': hallazgosOjos,
      'hallazgos_branquias': hallazgosBranquias,
      'presencia_ectoparasitos': presenciaEctoparasitos,
      'hallazgos_higado': hallazgosHigado,
      'hallazgos_bazo': hallazgosBazo,
      'hallazgos_intestino_estomago': hallazgosIntestinoEstomago,
      'hallazgos_cavidad_celomica': hallazgosCavidadCelomica,
      'hallazgos_rinon': hallazgosRinon,
      'diagnostico_presuntivo': diagnosticoPresuntivo,
      'envio_muestras_laboratorio': envioMuestrasLaboratorio,
      'tipo_muestra_enviada': tipoMuestraEnviada,
      'conducta_tratamiento': conductaTratamiento,
      'profesional_responsable': profesionalResponsable,
      'tarjeta_profesional': tarjetaProfesional,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory IcaNecropsiaRecord.fromJson(Map<String, dynamic> json) {
    return IcaNecropsiaRecord(
      id: json['id'] as String,
      empresaId: json['empresa_id'] as String? ?? '',
      unidadAcuicolaId: json['unidad_acuicola_id'] as String? ?? '',
      estanqueId: json['estanque_id'] as String?,
      estanqueNombre: json['estanque_nombre'] as String?,
      loteCodigo: json['lote_codigo'] as String?,
      fecha: DateTime.tryParse(json['fecha'] as String? ?? '') ?? DateTime.now(),
      especie: json['especie'] as String? ?? 'Tilapia Roja',
      numeroEjemplares: (json['numero_ejemplares'] as num?)?.toInt() ?? 2,
      pesoPromedioGramos: (json['peso_promedio_gramos'] as num?)?.toDouble() ?? 250.0,
      tallaPromedioCm: (json['talla_promedio_cm'] as num?)?.toDouble(),
      hallazgosPielAletas: json['hallazgos_piel_aletas'] as String? ?? 'Normal',
      hallazgosOjos: json['hallazgos_ojos'] as String? ?? 'Normal',
      hallazgosBranquias: json['hallazgos_branquias'] as String? ?? 'Normal',
      presenciaEctoparasitos: json['presencia_ectoparasitos'] == true,
      hallazgosHigado: json['hallazgos_higado'] as String? ?? 'Normal',
      hallazgosBazo: json['hallazgos_bazo'] as String? ?? 'Normal',
      hallazgosIntestinoEstomago: json['hallazgos_intestino_estomago'] as String? ?? 'Normal',
      hallazgosCavidadCelomica: json['hallazgos_cavidad_celomica'] as String? ?? 'Normal',
      hallazgosRinon: json['hallazgos_rinon'] as String? ?? 'Normal',
      diagnosticoPresuntivo: json['diagnostico_presuntivo'] as String? ?? 'Inspección de rutina',
      envioMuestrasLaboratorio: json['envio_muestras_laboratorio'] == true,
      tipoMuestraEnviada: json['tipo_muestra_enviada'] as String?,
      conductaTratamiento: json['conducta_tratamiento'] as String? ?? json['conducta_tomada'] as String? ?? 'Monitoreo continuo',
      profesionalResponsable: json['profesional_responsable'] as String? ?? 'M.V. Sanidad',
      tarjetaProfesional: json['tarjeta_profesional'] as String?,
      createdAt: DateTime.tryParse(json['created_at'] as String? ?? '') ?? DateTime.now(),
    );
  }
}
