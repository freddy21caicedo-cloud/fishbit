/// Modelo de Unidad Acuícola (Sede física de la finca piscícola)
class AquacultureUnit {
  final String id;
  final String empresaId;
  final String nombre;
  final String sigla;
  final String? ubicacion;
  final bool isDeleted;
  final DateTime creadoEn;

  const AquacultureUnit({
    required this.id,
    required this.empresaId,
    required this.nombre,
    required this.sigla,
    this.ubicacion,
    this.isDeleted = false,
    required this.creadoEn,
  });

  factory AquacultureUnit.fromJson(Map<String, dynamic> json) {
    return AquacultureUnit(
      id: json['id'] as String,
      empresaId: json['empresa_id'] as String? ?? '',
      nombre: json['nombre'] as String? ?? 'Sede',
      sigla: json['sigla'] as String? ?? '',
      ubicacion: json['ubicacion'] as String?,
      isDeleted: json['is_deleted'] as bool? ?? false,
      creadoEn: json['creado_en'] != null
          ? DateTime.parse(json['creado_en'] as String)
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'empresa_id': empresaId,
        'nombre': nombre,
        'sigla': sigla,
        'ubicacion': ubicacion,
        'is_deleted': isDeleted,
      };
}
