class Supplier {
  final String id;
  final String nit;
  final String nombre;
  final String? tipoIdentificacion; // 'NIT', 'Cédula de Ciudadanía', 'Pasaporte'
  final String? telefono;
  final String? email;
  final String? contactoNombre;
  final String? pais;
  final String? departamento;
  final String? ciudad;
  final String? direccion;
  final String categoriaPrincipal; // 'concentrados', 'insumos', 'alevinos', 'equipos', 'farmacia'
  final List<String> categorias;
  final List<String> productosOfrecidos;
  final String? empresaId;
  final String? unidadAcuicolaSigla;
  final bool isCustom;

  const Supplier({
    required this.id,
    required this.nit,
    required this.nombre,
    this.tipoIdentificacion = 'NIT',
    this.telefono,
    this.email,
    this.contactoNombre,
    this.pais = 'Colombia',
    this.departamento,
    this.ciudad,
    this.direccion,
    this.categoriaPrincipal = 'concentrados',
    this.categorias = const [],
    this.productosOfrecidos = const [],
    this.empresaId,
    this.unidadAcuicolaSigla,
    this.isCustom = false,
  });

  Supplier copyWith({
    String? id,
    String? nit,
    String? nombre,
    String? tipoIdentificacion,
    String? telefono,
    String? email,
    String? contactoNombre,
    String? pais,
    String? departamento,
    String? ciudad,
    String? direccion,
    String? categoriaPrincipal,
    List<String>? categorias,
    List<String>? productosOfrecidos,
    String? empresaId,
    String? unidadAcuicolaSigla,
    bool? isCustom,
  }) {
    return Supplier(
      id: id ?? this.id,
      nit: nit ?? this.nit,
      nombre: nombre ?? this.nombre,
      tipoIdentificacion: tipoIdentificacion ?? this.tipoIdentificacion,
      telefono: telefono ?? this.telefono,
      email: email ?? this.email,
      contactoNombre: contactoNombre ?? this.contactoNombre,
      pais: pais ?? this.pais,
      departamento: departamento ?? this.departamento,
      ciudad: ciudad ?? this.ciudad,
      direccion: direccion ?? this.direccion,
      categoriaPrincipal: categoriaPrincipal ?? this.categoriaPrincipal,
      categorias: categorias ?? this.categorias,
      productosOfrecidos: productosOfrecidos ?? this.productosOfrecidos,
      empresaId: empresaId ?? this.empresaId,
      unidadAcuicolaSigla: unidadAcuicolaSigla ?? this.unidadAcuicolaSigla,
      isCustom: isCustom ?? this.isCustom,
    );
  }

  factory Supplier.fromJson(Map<String, dynamic> json) {
    final rawCats = json['categorias'] as List<dynamic>? ?? json['types'] as List<dynamic>?;
    final catList = rawCats?.map((e) => e.toString()).toList() ?? [];
    final primaryCat = json['categoria_principal'] as String? ??
        (json['category_primary'] as String? ??
            (json['tipo'] as String? ?? (catList.isNotEmpty ? catList.first : 'concentrados')));
    if (catList.isEmpty && primaryCat.isNotEmpty) {
      catList.add(primaryCat);
    }

    return Supplier(
      id: json['id'] as String? ?? '',
      nit: json['nit'] as String? ?? '',
      nombre: json['nombre'] as String? ?? (json['name'] as String? ?? ''),
      tipoIdentificacion: json['tipo_identificacion'] as String? ?? 'NIT',
      telefono: json['telefono'] as String? ?? (json['phone'] as String?),
      email: json['email'] as String?,
      contactoNombre: json['contacto_nombre'] as String?,
      pais: json['pais'] as String? ?? 'Colombia',
      departamento: json['departamento'] as String?,
      ciudad: json['ciudad'] as String? ?? (json['city'] as String?),
      direccion: json['direccion'] as String?,
      categoriaPrincipal: primaryCat,
      categorias: catList,
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
        'tipo_identificacion': tipoIdentificacion,
        'telefono': telefono,
        'email': email,
        'contacto_nombre': contactoNombre,
        'pais': pais,
        'departamento': departamento,
        'ciudad': ciudad,
        'direccion': direccion,
        'categoria_principal': categoriaPrincipal,
        'tipo': categoriaPrincipal,
        'categorias': categorias,
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
        if (telefono != null) 'telefono': telefono,
        if (email != null) 'email': email,
        if (contactoNombre != null) 'contacto_nombre': contactoNombre,
        if (tipoIdentificacion != null) 'tipo_identificacion': tipoIdentificacion,
        if (pais != null) 'pais': pais,
        if (departamento != null) 'departamento': departamento,
        if (ciudad != null) 'ciudad': ciudad,
        if (direccion != null) 'direccion': direccion,
        if (categorias.isNotEmpty) 'categorias': categorias,
      };

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Supplier &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}
