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
  final Map<String, dynamic> preferenciasOperativas;

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
    this.preferenciasOperativas = const {},
  });

  factory Company.fromJson(Map<String, dynamic> json) {
    List<String> especies = ['Tilapia Roja', 'Cachama Negra', 'Bocachico', 'Pangasius'];
    if (json['especies_habilitadas'] != null) {
      if (json['especies_habilitadas'] is List) {
        especies = (json['especies_habilitadas'] as List).map((e) => e.toString()).toList();
      }
    }

    final resolvedName = json['nombre'] as String? ??
        json['nombre_comercial'] as String? ??
        json['razon_social'] as String? ??
        'Piscícola';

    return Company(
      id: json['id'] as String,
      nombreComercial: (json['nombre_comercial'] as String?)?.trim().isNotEmpty == true
          ? (json['nombre_comercial'] as String).trim()
          : resolvedName,
      razonSocial: (json['razon_social'] as String?)?.trim().isNotEmpty == true
          ? (json['razon_social'] as String).trim()
          : resolvedName,
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
      preferenciasOperativas: json['preferencias_operativas'] is Map
          ? Map<String, dynamic>.from(json['preferencias_operativas'] as Map)
          : const {},
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'nombre': nombreComercial,
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
        'preferencias_operativas': preferenciasOperativas,
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
    Map<String, dynamic>? preferenciasOperativas,
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
      preferenciasOperativas: preferenciasOperativas ?? this.preferenciasOperativas,
    );
  }

  double get fcrObjetivo =>
      (preferenciasOperativas['fcr_objetivo'] as num?)?.toDouble() ?? 1.25;
  double get oxigenoMinimoCritico =>
      (preferenciasOperativas['oxigeno_minimo_critico'] as num?)?.toDouble() ?? 4.0;
  double get phMinimo =>
      (preferenciasOperativas['ph_minimo'] as num?)?.toDouble() ?? 6.5;
  double get phMaximo =>
      (preferenciasOperativas['ph_maximo'] as num?)?.toDouble() ?? 8.5;
  String get unidadPeso =>
      (preferenciasOperativas['unidad_peso'] as String?) ?? 'kg';
  double get kgPorBultoAlimento =>
      (preferenciasOperativas['kg_por_bulto_alimento'] as num?)?.toDouble() ?? 40.0;
  String get unidadTemperatura =>
      (preferenciasOperativas['unidad_temperatura'] as String?) ?? 'C';
  bool get alertasIcaActivas =>
      (preferenciasOperativas['alertas_ica_activas'] as bool?) ?? true;
  bool get alertaSonoraOxigeno =>
      (preferenciasOperativas['alerta_sonora_oxigeno'] as bool?) ?? true;

  /// Retorna el peso objetivo de cosecha estándar por especie
  static double defaultHarvestWeightForSpecies(String especie) {
    final lower = especie.toLowerCase();
    if (lower.contains('cachama')) return 1000.0;
    if (lower.contains('tilapia')) return 650.0;
    if (lower.contains('trucha')) return 400.0;
    if (lower.contains('bocachico')) return 400.0;
    if (lower.contains('pangasius')) return 800.0;
    if (lower.contains('camar') || lower.contains('langostino')) return 25.0;
    return 500.0;
  }

  /// Obtiene la meta de peso de cosecha en gramos configurada para la especie, o el valor por defecto
  double getTargetHarvestWeightGrams(String especie) {
    final configured = pesosFinalesEspeciesG[especie];
    if (configured != null) {
      if (configured is num) return configured.toDouble();
      final parsed = double.tryParse(configured.toString());
      if (parsed != null && parsed > 0) return parsed;
    }
    return defaultHarvestWeightForSpecies(especie);
  }
}


