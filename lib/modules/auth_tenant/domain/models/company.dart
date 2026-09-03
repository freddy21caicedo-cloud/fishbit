/// Modelo de Empresa / Inquilino (Tenant) para aislamiento multi-empresa
class Company {
  final String id;
  final String nombreComercial;
  final String razonSocial;
  final String nit;
  final String? direccion;
  final String? telefono;
  final String? email;
  final String? registroIca;
  final String? registroAunap;
  final String moneda;
  final double tarifaEnergiaKwh;
  final double limiteMortalidadCritica;
  final double stockAlertaMinimoAlimento;
  final double precioMercadoActualKg;
  final Map<String, dynamic> preciosMercadoEspecies;
  final Map<String, dynamic> ciclosEspeciesDias;
  final Map<String, dynamic> pesosFinalesEspeciesG;
  final List<String> especiesHabilitadas;
  final String? logoUrl;
  final String estadoSuscripcion;

  const Company({
    required this.id,
    required this.nombreComercial,
    required this.razonSocial,
    required this.nit,
    this.direccion,
    this.telefono,
    this.email,
    this.registroIca,
    this.registroAunap,
    this.moneda = 'COP',
    this.tarifaEnergiaKwh = 850.0,
    this.limiteMortalidadCritica = 10.0,
    this.stockAlertaMinimoAlimento = 200.0,
    this.precioMercadoActualKg = 8500.0,
    this.preciosMercadoEspecies = const {},
    this.ciclosEspeciesDias = const {},
    this.pesosFinalesEspeciesG = const {},
    this.especiesHabilitadas = const ['Tilapia Roja', 'Cachama Negra', 'Bocachico', 'Pangasius'],
    this.logoUrl,
    this.estadoSuscripcion = 'Activo',
  });

  factory Company.fromJson(Map<String, dynamic> json) {
    List<String> especies = ['Tilapia Roja', 'Cachama Negra', 'Bocachico', 'Pangasius'];
    if (json['especies_habilitadas'] != null) {
      if (json['especies_habilitadas'] is List) {
        especies = (json['especies_habilitadas'] as List).map((e) => e.toString()).toList();
      }
    }

    return Company(
      id: json['id'] as String,
      nombreComercial: json['nombre_comercial'] as String? ?? '',
      razonSocial: json['razon_social'] as String? ?? '',
      nit: json['nit'] as String? ?? '',
      direccion: json['direccion'] as String?,
      telefono: json['telefono'] as String?,
      email: json['email'] as String?,
      registroIca: json['registro_ica'] as String?,
      registroAunap: json['registro_aunap'] as String?,
      moneda: json['moneda'] as String? ?? 'COP',
      tarifaEnergiaKwh: (json['tarifa_energia_kwh'] as num?)?.toDouble() ?? 850.0,
      limiteMortalidadCritica: (json['limite_mortalidad_critica'] as num?)?.toDouble() ?? 10.0,
      stockAlertaMinimoAlimento: (json['stock_alerta_minimo_alimento'] as num?)?.toDouble() ?? 200.0,
      precioMercadoActualKg: (json['precio_mercado_actual_kg'] as num?)?.toDouble() ?? 8500.0,
      preciosMercadoEspecies: json['precios_mercado_especies'] as Map<String, dynamic>? ?? {},
      ciclosEspeciesDias: json['ciclos_especies_dias'] as Map<String, dynamic>? ?? {},
      pesosFinalesEspeciesG: json['pesos_finales_especies_g'] as Map<String, dynamic>? ?? {},
      especiesHabilitadas: especies,
      logoUrl: json['logo_url'] as String?,
      estadoSuscripcion: json['estado_suscripcion'] as String? ?? 'Activo',
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'nombre_comercial': nombreComercial,
        'razon_social': razonSocial,
        'nit': nit,
        'direccion': direccion,
        'telefono': telefono,
        'email': email,
        'registro_ica': registroIca,
        'registro_aunap': registroAunap,
        'moneda': moneda,
        'tarifa_energia_kwh': tarifaEnergiaKwh,
        'limite_mortalidad_critica': limiteMortalidadCritica,
        'stock_alerta_minimo_alimento': stockAlertaMinimoAlimento,
        'precio_mercado_actual_kg': precioMercadoActualKg,
        'precios_mercado_especies': preciosMercadoEspecies,
        'ciclos_especies_dias': ciclosEspeciesDias,
        'pesos_finales_especies_g': pesosFinalesEspeciesG,
        'especies_habilitadas': especiesHabilitadas,
        'logo_url': logoUrl,
        'estado_suscripcion': estadoSuscripcion,
      };

  Company copyWith({
    String? id,
    String? nombreComercial,
    String? razonSocial,
    String? nit,
    String? direccion,
    String? telefono,
    String? email,
    String? registroIca,
    String? registroAunap,
    String? moneda,
    double? tarifaEnergiaKwh,
    double? limiteMortalidadCritica,
    double? stockAlertaMinimoAlimento,
    double? precioMercadoActualKg,
    Map<String, dynamic>? preciosMercadoEspecies,
    Map<String, dynamic>? ciclosEspeciesDias,
    Map<String, dynamic>? pesosFinalesEspeciesG,
    List<String>? especiesHabilitadas,
    String? logoUrl,
    String? estadoSuscripcion,
  }) {
    return Company(
      id: id ?? this.id,
      nombreComercial: nombreComercial ?? this.nombreComercial,
      razonSocial: razonSocial ?? this.razonSocial,
      nit: nit ?? this.nit,
      direccion: direccion ?? this.direccion,
      telefono: telefono ?? this.telefono,
      email: email ?? this.email,
      registroIca: registroIca ?? this.registroIca,
      registroAunap: registroAunap ?? this.registroAunap,
      moneda: moneda ?? this.moneda,
      tarifaEnergiaKwh: tarifaEnergiaKwh ?? this.tarifaEnergiaKwh,
      limiteMortalidadCritica: limiteMortalidadCritica ?? this.limiteMortalidadCritica,
      stockAlertaMinimoAlimento: stockAlertaMinimoAlimento ?? this.stockAlertaMinimoAlimento,
      precioMercadoActualKg: precioMercadoActualKg ?? this.precioMercadoActualKg,
      preciosMercadoEspecies: preciosMercadoEspecies ?? this.preciosMercadoEspecies,
      ciclosEspeciesDias: ciclosEspeciesDias ?? this.ciclosEspeciesDias,
      pesosFinalesEspeciesG: pesosFinalesEspeciesG ?? this.pesosFinalesEspeciesG,
      especiesHabilitadas: especiesHabilitadas ?? this.especiesHabilitadas,
      logoUrl: logoUrl ?? this.logoUrl,
      estadoSuscripcion: estadoSuscripcion ?? this.estadoSuscripcion,
    );
  }
}


