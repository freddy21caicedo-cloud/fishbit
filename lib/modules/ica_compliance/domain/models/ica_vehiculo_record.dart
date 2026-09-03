import 'package:uuid/uuid.dart';

enum TipoVehiculoIca {
  camionAlimento,
  transporteAlevinos,
  camionCosecha,
  insumosCombustible,
  particularVisita,
  otro,
}

extension TipoVehiculoIcaExt on TipoVehiculoIca {
  String get label {
    switch (this) {
      case TipoVehiculoIca.camionAlimento:
        return 'CAMIÓN DE ALIMENTO BALANCEADO';
      case TipoVehiculoIca.transporteAlevinos:
        return 'TRANSPORTE DE ALEVINOS (OXÍGENO)';
      case TipoVehiculoIca.camionCosecha:
        return 'CAMIÓN TERMOAISLADO (COSECHA)';
      case TipoVehiculoIca.insumosCombustible:
        return 'VEHÍCULO DE INSUMOS / COMBUSTIBLE';
      case TipoVehiculoIca.particularVisita:
        return 'VEHÍCULO PARTICULAR / VISITA TÉCNICA';
      case TipoVehiculoIca.otro:
        return 'OTRO';
    }
  }

  static TipoVehiculoIca fromString(String? val) {
    if (val == null) return TipoVehiculoIca.camionAlimento;
    final v = val.toUpperCase().replaceAll(' ', '_');
    if (v.contains('ALIMENTO')) return TipoVehiculoIca.camionAlimento;
    if (v.contains('ALEVINO')) return TipoVehiculoIca.transporteAlevinos;
    if (v.contains('COSECHA') || v.contains('TERMO')) return TipoVehiculoIca.camionCosecha;
    if (v.contains('INSUMO') || v.contains('COMBUSTIBLE')) return TipoVehiculoIca.insumosCombustible;
    if (v.contains('PARTICULAR') || v.contains('VISITA')) return TipoVehiculoIca.particularVisita;
    return TipoVehiculoIca.camionAlimento;
  }
}

class IcaVehiculoRecord {
  final String id;
  final String empresaId;
  final String unidadAcuicolaId;
  final DateTime fecha;
  final String horaIngreso;
  final String? horaSalida;
  final String placa;
  final TipoVehiculoIca tipoVehiculo;
  final String conductor;
  final String? documentoConductor;
  final String? telefonoConductor;
  final String? empresaTransportadora;
  final String procedencia;
  final String destinoInterno;
  final bool desinfeccionRodiluvio;
  final bool desinfeccionArcoAspersion;
  final String desinfectanteUtilizado;
  final String concentracionPpm;
  final int tiempoContactoMinutos;
  final String? responsableDesinfeccion;
  final DateTime createdAt;

  IcaVehiculoRecord({
    String? id,
    required this.empresaId,
    required this.unidadAcuicolaId,
    required this.fecha,
    required this.horaIngreso,
    this.horaSalida,
    required this.placa,
    required this.tipoVehiculo,
    required this.conductor,
    this.documentoConductor,
    this.telefonoConductor,
    this.empresaTransportadora,
    required this.procedencia,
    this.destinoInterno = 'Zona de Descarga / Bodega',
    this.desinfeccionRodiluvio = true,
    this.desinfeccionArcoAspersion = true,
    this.desinfectanteUtilizado = 'Amonio Cuaternario 5ta Gen',
    this.concentracionPpm = '200 ppm (2 ml/L)',
    this.tiempoContactoMinutos = 5,
    this.responsableDesinfeccion,
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
      'placa': placa.toUpperCase(),
      'tipo_vehiculo': tipoVehiculo.label,
      'conductor': conductor,
      'documento_conductor': documentoConductor,
      'telefono_conductor': telefonoConductor,
      'empresa_transportadora': empresaTransportadora,
      'procedencia': procedencia,
      'destino_interno': destinoInterno,
      'desinfeccion_rodiluvio': desinfeccionRodiluvio,
      'desinfeccion_arco_aspersion': desinfeccionArcoAspersion,
      'desinfectante_utilizado': desinfectanteUtilizado,
      'concentracion_ppm': concentracionPpm,
      'tiempo_contacto_minutos': tiempoContactoMinutos,
      'responsable_desinfeccion': responsableDesinfeccion,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory IcaVehiculoRecord.fromJson(Map<String, dynamic> json) {
    return IcaVehiculoRecord(
      id: json['id'] as String,
      empresaId: json['empresa_id'] as String? ?? '',
      unidadAcuicolaId: json['unidad_acuicola_id'] as String? ?? '',
      fecha: DateTime.tryParse(json['fecha'] as String? ?? '') ?? DateTime.now(),
      horaIngreso: json['hora_ingreso'] as String? ?? '08:00',
      horaSalida: json['hora_salida'] as String?,
      placa: (json['placa'] as String? ?? json['placa_vehiculo'] as String? ?? '').toUpperCase(),
      tipoVehiculo: TipoVehiculoIcaExt.fromString(json['tipo_vehiculo'] as String?),
      conductor: json['conductor'] as String? ?? '',
      documentoConductor: json['documento_conductor'] as String?,
      telefonoConductor: json['telefono_conductor'] as String?,
      empresaTransportadora: json['empresa_transportadora'] as String?,
      procedencia: json['procedencia'] as String? ?? 'Planta de distribución',
      destinoInterno: json['destino_interno'] as String? ?? 'Bodega / Descarga',
      desinfeccionRodiluvio: json['desinfeccion_rodiluvio'] != false,
      desinfeccionArcoAspersion: json['desinfeccion_arco_aspersion'] != false,
      desinfectanteUtilizado: json['desinfectante_utilizado'] as String? ?? 'Amonio Cuaternario',
      concentracionPpm: json['concentracion_ppm'] as String? ?? '200 ppm',
      tiempoContactoMinutos: (json['tiempo_contacto_minutos'] as num?)?.toInt() ?? 5,
      responsableDesinfeccion: json['responsable_desinfeccion'] as String?,
      createdAt: DateTime.tryParse(json['created_at'] as String? ?? '') ?? DateTime.now(),
    );
  }
}
