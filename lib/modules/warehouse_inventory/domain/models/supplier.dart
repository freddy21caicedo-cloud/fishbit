class Supplier {
  final String id;
  final String nit;
  final String nombre;
  final String? telefono;
  final String? email;
  final String? ciudad;
  final String categoriaPrincipal; // 'concentrados', 'insumos', 'alevinos', 'equipos', 'farmacia'
  final List<String> productosOfrecidos;

  const Supplier({
    required this.id,
    required this.nit,
    required this.nombre,
    this.telefono,
    this.email,
    this.ciudad,
    this.categoriaPrincipal = 'concentrados',
    this.productosOfrecidos = const [],
  });

  Supplier copyWith({
    String? id,
    String? nit,
    String? nombre,
    String? telefono,
    String? email,
    String? ciudad,
    String? categoriaPrincipal,
    List<String>? productosOfrecidos,
  }) {
    return Supplier(
      id: id ?? this.id,
      nit: nit ?? this.nit,
      nombre: nombre ?? this.nombre,
      telefono: telefono ?? this.telefono,
      email: email ?? this.email,
      ciudad: ciudad ?? this.ciudad,
      categoriaPrincipal: categoriaPrincipal ?? this.categoriaPrincipal,
      productosOfrecidos: productosOfrecidos ?? this.productosOfrecidos,
    );
  }

  factory Supplier.fromJson(Map<String, dynamic> json) {
    return Supplier(
      id: json['id'] as String,
      nit: json['nit'] as String? ?? '',
      nombre: json['nombre'] as String? ?? '',
      telefono: json['telefono'] as String?,
      email: json['email'] as String?,
      ciudad: json['ciudad'] as String?,
      categoriaPrincipal: json['categoria_principal'] as String? ?? 'concentrados',
      productosOfrecidos: (json['productos_ofrecidos'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'nit': nit,
        'nombre': nombre,
        'telefono': telefono,
        'email': email,
        'ciudad': ciudad,
        'categoria_principal': categoriaPrincipal,
        'productos_ofrecidos': productosOfrecidos,
      };
}
