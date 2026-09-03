import 'package:uuid/uuid.dart';

enum TipoPersonaIca {
  operarioGranja,
  medicoVeterinario,
  auditorIca,
  proveedorInsumos,
  transportador,
  visitanteTecnico,
  otro,
}

extension TipoPersonaIcaExt on TipoPersonaIca {
  String get label {
    switch (this) {
      case TipoPersonaIca.operarioGranja:
        return 'OPERARIO DE GRANJA';
      case TipoPersonaIca.medicoVeterinario:
        return 'MÉDICO VETERINARIO / TÉCNICO';
      case TipoPersonaIca.auditorIca:
        return 'AUDITOR / INSPECTOR ICA';
      case TipoPersonaIca.proveedorInsumos:
        return 'PROVEEDOR DE INSUMOS';
      case TipoPersonaIca.transportador:
        return 'TRANSPORTADOR';
      case TipoPersonaIca.visitanteTecnico:
        return 'VISITANTE TÉCNICO';
      case TipoPersonaIca.otro:
        return 'OTRO';
    }
  }

  static TipoPersonaIca fromString(String? val) {
    if (val == null) return TipoPersonaIca.visitanteTecnico;
    final v = val.toUpperCase().replaceAll(' ', '_');
    if (v.contains('VISITANTE')) return TipoPersonaIca.visitanteTecnico;
    if (v.contains('OPERARIO')) return TipoPersonaIca.operarioGranja;
    if (v.contains('VETERINARIO') || v.contains('TECNICO')) return TipoPersonaIca.medicoVeterinario;
    if (v.contains('ICA') || v.contains('AUDITOR')) return TipoPersonaIca.auditorIca;
    if (v.contains('PROVEEDOR')) return TipoPersonaIca.proveedorInsumos;
    if (v.contains('TRANSPORT')) return TipoPersonaIca.transportador;
    return TipoPersonaIca.visitanteTecnico;
  }
}

class IcaPersonalRecord {
  final String id;
  final String empresaId;
  final String unidadAcuicolaId;
  final DateTime fecha;
  final String horaIngreso;
  final String? horaSalida;
  final String nombreCompleto;
  final String documentoIdentidad;
  final String? telefono;
  final TipoPersonaIca tipoPersona;
  final String? entidadProcedencia;
  final String motivoVisita;
  final bool haVisitadoOtrasGranjas;
  final String? detalleOtrasGranjas;
  final bool presentaSintomas;
  final bool lavadoManos;
  final bool desinfeccionCalzado;
  final bool indumentariaLimpia;
  final String? autorizaIngreso;
  final DateTime createdAt;

  IcaPersonalRecord({
    String? id,
    required this.empresaId,
    required this.unidadAcuicolaId,
    required this.fecha,
    required this.horaIngreso,
    this.horaSalida,
    required this.nombreCompleto,
    required this.documentoIdentidad,
    this.telefono,
    required this.tipoPersona,
    this.entidadProcedencia,
    required this.motivoVisita,
    this.haVisitadoOtrasGranjas = false,
    this.detalleOtrasGranjas,
    this.presentaSintomas = false,
    this.lavadoManos = true,
    this.desinfeccionCalzado = true,
    this.indumentariaLimpia = true,
    this.autorizaIngreso,
    DateTime? createdAt,
  })  : id = id ?? const Uuid().v4(),
        createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'empresa_id': empresaId,
      'unidad_acuicola_id': unidadAcuicolaId,
      'fecha': fecha.toIso8601String().split('T')[0],
      'hora_ingreso': horaIngreso,
      'hora_salida': horaSalida,
      'nombre_completo': nombreCompleto,
      'documento_identidad': documentoIdentidad,
      'telefono': telefono,
      'tipo_persona': tipoPersona.label,
      'entidad_procedencia': entidadProcedencia,
      'motivo_visita': motivoVisita,
      'ha_visitado_otras_granjas': haVisitadoOtrasGranjas,
      'detalle_otras_granjas': detalleOtrasGranjas,
      'presenta_sintomas': presentaSintomas,
      'lavado_manos': lavadoManos,
      'desinfeccion_calzado': desinfeccionCalzado,
      'indumentaria_limpia': indumentariaLimpia,
      'autoriza_ingreso': autorizaIngreso,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory IcaPersonalRecord.fromJson(Map<String, dynamic> json) {
    return IcaPersonalRecord(
      id: json['id'] as String,
      empresaId: json['empresa_id'] as String? ?? '',
      unidadAcuicolaId: json['unidad_acuicola_id'] as String? ?? '',
      fecha: DateTime.tryParse(json['fecha'] as String? ?? '') ?? DateTime.now(),
      horaIngreso: json['hora_ingreso'] as String? ?? '08:00',
      horaSalida: json['hora_salida'] as String?,
      nombreCompleto: json['nombre_completo'] as String? ?? '',
      documentoIdentidad: json['documento_identidad'] as String? ?? '',
      telefono: json['telefono'] as String?,
      tipoPersona: TipoPersonaIcaExt.fromString(json['tipo_persona'] as String?),
      entidadProcedencia: json['entidad_procedencia'] as String?,
      motivoVisita: json['motivo_visita'] as String? ?? 'Labores de predio',
      haVisitadoOtrasGranjas: json['ha_visitado_otras_granjas'] == true,
      detalleOtrasGranjas: json['detalle_otras_granjas'] as String?,
      presentaSintomas: json['presenta_sintomas'] == true,
      lavadoManos: json['lavado_manos'] != false,
      desinfeccionCalzado: json['desinfeccion_calzado'] != false,
      indumentariaLimpia: json['indumentaria_limpia'] != false,
      autorizaIngreso: json['autoriza_ingreso'] as String?,
      createdAt: DateTime.tryParse(json['created_at'] as String? ?? '') ?? DateTime.now(),
    );
  }
}
