enum EquipmentType { aireacion, medicion }
enum EquipmentHealth { operativo, bodega, mantenimiento }

/// Entidad inmutable de Equipo de Activo Fijo (CAPEX) con amortización lineal
class EquipmentAsset {
  final String id;
  final String empresaId;
  final String unidadAcuicolaId;
  final String nombre;
  final String sigla;
  final EquipmentType tipo;
  final EquipmentHealth estadoSalud;
  final double costoAdquisicion;
  final int vidaUtilDias;
  final String? estanqueAsignadoId;
  final String? hpPotencia;
  final String? faseElectrica;
  final String? voltajeAmperaje;
  final double? caudalLpm;
  final double? areaAccionM2;
  final String? categoriaMedicion;
  final double horasUsoDiario;
  final String? proveedor;
  final String? numeroFactura;
  final DateTime creadoEn;

  const EquipmentAsset({
    required this.id,
    required this.empresaId,
    required this.unidadAcuicolaId,
    required this.nombre,
    required this.sigla,
    required this.tipo,
    this.estadoSalud = EquipmentHealth.operativo,
    required this.costoAdquisicion,
    required this.vidaUtilDias,
    this.estanqueAsignadoId,
    this.hpPotencia,
    this.faseElectrica,
    this.voltajeAmperaje,
    this.caudalLpm,
    this.areaAccionM2,
    this.categoriaMedicion,
    this.horasUsoDiario = 0.0,
    this.proveedor,
    this.numeroFactura,
    required this.creadoEn,
  });

  /// Depreciación lineal diaria
  double get depreciacionDiaria => vidaUtilDias > 0 ? (costoAdquisicion / vidaUtilDias) : 0.0;

  static EquipmentType parseType(String val) {
    return val.toLowerCase() == 'medicion' ? EquipmentType.medicion : EquipmentType.aireacion;
  }

  static EquipmentHealth parseHealth(String val) {
    switch (val.toLowerCase()) {
      case 'bodega':
        return EquipmentHealth.bodega;
      case 'mantenimiento':
        return EquipmentHealth.mantenimiento;
      default:
        return EquipmentHealth.operativo;
    }
  }

  factory EquipmentAsset.fromJson(Map<String, dynamic> json) {
    return EquipmentAsset(
      id: json['id'] as String,
      empresaId: json['empresa_id'] as String? ?? '',
      unidadAcuicolaId: json['unidad_acuicola_id'] as String? ?? '',
      nombre: json['nombre'] as String? ?? '',
      sigla: json['sigla'] as String? ?? '',
      tipo: parseType(json['tipo'] as String? ?? 'Aireacion'),
      estadoSalud: parseHealth(json['estado_salud'] as String? ?? 'Operativo'),
      costoAdquisicion: (json['costo_adquisicion'] as num?)?.toDouble() ?? 0.0,
      vidaUtilDias: json['vida_util_dias'] as int? ?? 1825,
      estanqueAsignadoId: json['estanque_asignado_id'] as String?,
      hpPotencia: json['hp_potencia'] as String?,
      faseElectrica: json['fase_electrica'] as String?,
      voltajeAmperaje: json['voltaje_amperaje'] as String?,
      caudalLpm: (json['caudal_lpm'] as num?)?.toDouble(),
      areaAccionM2: (json['area_accion_m2'] as num?)?.toDouble(),
      categoriaMedicion: json['categoria_medicion'] as String?,
      horasUsoDiario: (json['horas_uso_diario'] as num?)?.toDouble() ?? 0.0,
      proveedor: json['proveedor'] as String?,
      numeroFactura: json['numero_factura'] as String?,
      creadoEn: json['creado_en'] != null ? DateTime.parse(json['creado_en'] as String) : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'empresa_id': empresaId,
        'unidad_acuicola_id': unidadAcuicolaId,
        'nombre': nombre,
        'sigla': sigla,
        'tipo': tipo == EquipmentType.medicion ? 'Medicion' : 'Aireacion',
        'estado_salud': estadoSalud.name.capitalize(),
        'costo_adquisicion': costoAdquisicion,
        'vida_util_dias': vidaUtilDias,
        'estanque_asignado_id': estanqueAsignadoId,
        'hp_potencia': hpPotencia,
        'fase_electrica': faseElectrica,
        'voltaje_amperaje': voltajeAmperaje,
        'caudal_lpm': caudalLpm,
        'area_accion_m2': areaAccionM2,
        'categoria_medicion': categoriaMedicion,
        'horas_uso_diario': horasUsoDiario,
        'proveedor': proveedor,
        'numero_factura': numeroFactura,
      };
}

extension StringExtension on String {
  String capitalize() => isEmpty ? this : '${this[0].toUpperCase()}${substring(1)}';
}
