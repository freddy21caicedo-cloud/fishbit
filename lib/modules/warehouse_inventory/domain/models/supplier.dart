class Supplier {
  final String id;
  final String nit;
  final String nombre;
  final String? telefono;
  final String? email;
  final String? ciudad;
  final String categoriaPrincipal; // 'concentrados', 'insumos', 'alevinos', 'equipos', 'farmacia'
  final List<String> productosOfrecidos;
  final String? empresaId;
  final String? unidadAcuicolaSigla;
  final bool isCustom;

  const Supplier({
    required this.id,
    required this.nit,
    required this.nombre,
    this.telefono,
    this.email,
    this.ciudad,
    this.categoriaPrincipal = 'concentrados',
    this.productosOfrecidos = const [],
    this.empresaId,
    this.unidadAcuicolaSigla,
    this.isCustom = false,
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
    String? empresaId,
    String? unidadAcuicolaSigla,
    bool? isCustom,
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
      empresaId: empresaId ?? this.empresaId,
      unidadAcuicolaSigla: unidadAcuicolaSigla ?? this.unidadAcuicolaSigla,
      isCustom: isCustom ?? this.isCustom,
    );
  }

  factory Supplier.fromJson(Map<String, dynamic> json) {
    return Supplier(
      id: json['id'] as String? ?? '',
      nit: json['nit'] as String? ?? '',
      nombre: json['nombre'] as String? ?? '',
      telefono: json['telefono'] as String?,
      email: json['email'] as String?,
      ciudad: json['ciudad'] as String?,
      categoriaPrincipal: json['categoria_principal'] as String? ?? (json['tipo'] as String? ?? 'concentrados'),
      productosOfrecidos: (json['productos_ofrecidos'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
      empresaId: json['empresa_id'] as String?,
      unidadAcuicolaSigla: json['unidad_acuicola_sigla'] as String?,
      isCustom: json['empresa_id'] != null && (json['empresa_id'] as String).isNotEmpty,
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
        'tipo': categoriaPrincipal,
        'productos_ofrecidos': productosOfrecidos,
        if (empresaId != null) 'empresa_id': empresaId,
        if (unidadAcuicolaSigla != null) 'unidad_acuicola_sigla': unidadAcuicolaSigla,
      };

  Map<String, dynamic> toSupabaseJson() => {
        'id': id,
        'nit': nit,
        'nombre': nombre,
        'tipo': categoriaPrincipal,
        'empresa_id': empresaId,
        'unidad_acuicola_sigla': (unidadAcuicolaSigla?.isNotEmpty == true) ? unidadAcuicolaSigla : 'SEDE',
      };
}
