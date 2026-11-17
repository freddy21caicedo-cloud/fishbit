/// Modelo de Unidad Acuícola (Sede física de la finca piscícola)
class AquacultureUnit {
  final String id;
  final String empresaId;
  final String nombre;
  final String sigla;
  final String? ubicacion;
  final String? pais;
  final String? departamento;
  final String? ciudad;
  final String? direccion;
  final String? telefono;
  final bool isDeleted;
  final DateTime creadoEn;

  const AquacultureUnit({
    required this.id,
    required this.empresaId,
    required this.nombre,
    required this.sigla,
    this.ubicacion,
    this.pais,
    this.departamento,
    this.ciudad,
    this.direccion,
    this.telefono,
    this.isDeleted = false,
    required this.creadoEn,
  });

  factory AquacultureUnit.fromJson(Map<String, dynamic> json) {
    return AquacultureUnit(
      id: json['id'] as String,
      empresaId: json['empresa_id'] as String? ?? '',
      nombre: json['nombre'] as String? ?? json['name'] as String? ?? 'Sede',
      sigla: json['sigla'] as String? ?? '',
      ubicacion: json['ubicacion'] as String? ?? json['location'] as String?,
      pais: json['pais'] as String?,
      departamento: json['departamento'] as String?,
      ciudad: json['ciudad'] as String?,
      direccion: json['direccion'] as String? ?? json['address'] as String?,
      telefono: json['telefono'] as String? ?? json['phone'] as String?,
      isDeleted: json['is_deleted'] as bool? ?? false,
      creadoEn: json['creado_en'] != null
          ? DateTime.parse(json['creado_en'] as String)
          : (json['created_at'] != null ? DateTime.parse(json['created_at'] as String) : DateTime.now()),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'empresa_id': empresaId,
        'nombre': nombre,
        'sigla': sigla,
        'ubicacion': ubicacion,
        'pais': pais,
        'departamento': departamento,
        'ciudad': ciudad,
        'direccion': direccion,
        'telefono': telefono,
        'is_deleted': isDeleted,
      };

  AquacultureUnit copyWith({
    String? id,
    String? empresaId,
    String? nombre,
    String? sigla,
    String? ubicacion,
    String? pais,
    String? departamento,
    String? ciudad,
    String? direccion,
    String? telefono,
    bool? isDeleted,
    DateTime? creadoEn,
  }) {
    return AquacultureUnit(
      id: id ?? this.id,
      empresaId: empresaId ?? this.empresaId,
      nombre: nombre ?? this.nombre,
      sigla: sigla ?? this.sigla,
      ubicacion: ubicacion ?? this.ubicacion,
      pais: pais ?? this.pais,
      departamento: departamento ?? this.departamento,
      ciudad: ciudad ?? this.ciudad,
      direccion: direccion ?? this.direccion,
      telefono: telefono ?? this.telefono,
      isDeleted: isDeleted ?? this.isDeleted,
      creadoEn: creadoEn ?? this.creadoEn,
    );
  }
}
