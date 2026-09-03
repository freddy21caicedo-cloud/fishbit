/// Entidad inmutable de Cliente (Comprador mayorista o minorista)
class Client {
  final String id;
  final String empresaId;
  final String nombre;
  final String? telefono;
  final String? email;
  final DateTime creadoEn;

  const Client({
    required this.id,
    required this.empresaId,
    required this.nombre,
    this.telefono,
    this.email,
    required this.creadoEn,
  });

  factory Client.fromJson(Map<String, dynamic> json) {
    return Client(
      id: json['id'] as String,
      empresaId: json['empresa_id'] as String? ?? '',
      nombre: json['nombre'] as String? ?? '',
      telefono: json['telefono'] as String?,
      email: json['email'] as String?,
      creadoEn: json['creado_en'] != null ? DateTime.parse(json['creado_en'] as String) : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'empresa_id': empresaId,
        'nombre': nombre,
        'telefono': telefono,
        'email': email,
      };
}
