/// Catálogo y servicio geográfico para FishBit Finance 2.0
/// Soporta cascada estructurada: País -> Departamento / Estado -> Ciudad / Municipio
class GeographicService {
  GeographicService._();

  static const String defaultCountry = 'Colombia';

  /// Catálogo de países soportados
  static const List<String> countries = [
    'Colombia',
    'Perú',
    'Ecuador',
    'México',
    'Brasil',
    'Chile',
    'Otro País...',
  ];

  /// Departamentos de Colombia (32 departamentos oficiales + Distrito Capital)
  static const List<String> colombiaDepartments = [
    'Amazonas',
    'Antioquia',
    'Arauca',
    'Atlántico',
    'Bolívar',
    'Boyacá',
    'Caldas',
    'Caquetá',
    'Casanare',
    'Cauca',
    'Cesar',
    'Chocó',
    'Córdoba',
    'Cundinamarca',
    'Guainía',
    'Guaviare',
    'Huila',
    'La Guajira',
    'Magdalena',
    'Meta',
    'Nariño',
    'Norte de Santander',
    'Putumayo',
    'Quindío',
    'Risaralda',
    'San Andrés y Providencia',
    'Santander',
    'Sucre',
    'Tolima',
    'Valle del Cauca',
    'Vaupés',
    'Vichada',
  ];

  /// Municipios acuícolas y principales por departamento en Colombia
  static const Map<String, List<String>> colombiaMunicipalities = {
    'Antioquia': [
      'Medellín',
      'San Jerónimo',
      'Santa Fe de Antioquia',
      'Rionegro',
      'Guarne',
      'Marinilla',
      'El Peñol',
      'Guatapé',
      'Sopetrán',
      'Caucasia',
      'Tarazá',
      'Turbo',
      'Apartadó',
      'Yarumal',
      'Amalfi',
      'Puerto Berrío',
      'Puerto Nare',
      'La Pintada',
      'Jardín',
      'Urrao',
      'Otro municipio...',
    ],
    'Huila': [
      'Neiva',
      'Betania (Embalse de Betania)',
      'Yaguará',
      'Campoalegre',
      'Gigante',
      'Garzón',
      'Pitalito',
      'Aipe',
      'Palermo',
      'Rivera',
      'Villavieja',
      'La Plata',
      'San Agustín',
      'Otro municipio...',
    ],
    'Meta': [
      'Villavicencio',
      'Acacías',
      'Granada',
      'Puerto López',
      'Puerto Gaitán',
      'San Martín',
      'Cumaral',
      'Restrepo',
      'Castilla La Nueva',
      'Guamal',
      'Vista Hermosa',
      'Otro municipio...',
    ],
    'Tolima': [
      'Ibagué',
      'Espinal',
      'Melgar',
      'Flandes',
      'Prado (Represa de Prado)',
      'Purificación',
      'Guamo',
      'Honda',
      'Mariquita',
      'Chaparral',
      'Lérida',
      'Otro municipio...',
    ],
    'Boyacá': [
      'Tunja',
      'Duitama',
      'Sogamoso',
      'Aquitania (Lago de Tota)',
      'Tota',
      'Cuítiva',
      'Chiquinquirá',
      'Villa de Leyva',
      'Paipa',
      'Moniquirá',
      'Puerto Boyacá',
      'Otro municipio...',
    ],
    'Cundinamarca': [
      'Bogotá D.C.',
      'Girardot',
      'Fusagasugá',
      'Facatativá',
      'Zipaquirá',
      'Chía',
      'Mosquera',
      'Madrid',
      'Funza',
      'Guaduas',
      'Villeta',
      'La Vega',
      'Medina',
      'Ubaté',
      'Otro municipio...',
    ],
    'Santander': [
      'Bucaramanga',
      'Barrancabermeja',
      'Floridablanca',
      'Girón',
      'Piedecuesta',
      'San Gil',
      'Socorro',
      'Barbosa',
      'Cimitarra',
      'Sabana de Torres',
      'Puerto Wilches',
      'Otro municipio...',
    ],
    'Córdoba': [
      'Montería',
      'Lorica',
      'Cereté',
      'Sahagún',
      'Tierralta (Embalse de Urrá)',
      'Montelíbano',
      'Planeta Rica',
      'San Pelayo',
      'Ciénaga de Oro',
      'Otro municipio...',
    ],
    'Valle del Cauca': [
      'Cali',
      'Buenaventura',
      'Palmira',
      'Tuluá',
      'Buga',
      'Cartago',
      'Jamundí',
      'Yumbo',
      'Dagua',
      'Calima El Darién (Lago Calima)',
      'Roldanillo',
      'Otro municipio...',
    ],
    'Caldas': [
      'Manizales',
      'La Dorada',
      'Chinchiná',
      'Villamaría',
      'Anserma',
      'Riosucio',
      'Salamina',
      'Otro municipio...',
    ],
    'Risaralda': [
      'Pereira',
      'Dosquebradas',
      'Santa Rosa de Cabal',
      'La Virginia',
      'Belén de Umbría',
      'Otro municipio...',
    ],
    'Quindío': [
      'Armenia',
      'Calarcá',
      'Montenegro',
      'Quimbaya',
      'La Tebaida',
      'Circasia',
      'Salento',
      'Otro municipio...',
    ],
    'Cauca': [
      'Popayán',
      'Santander de Quilichao',
      'Puerto Tejada',
      'Patía (El Bordo)',
      'Piendamó',
      'Silvia',
      'Guapi',
      'Otro municipio...',
    ],
    'Nariño': [
      'Pasto',
      'Tumaco',
      'Ipiales',
      'Túquerres',
      'La Unión',
      'Samaniego',
      'La Cocha (Laguna de la Cocha)',
      'Otro municipio...',
    ],
    'Casanare': [
      'Yopal',
      'Aguazul',
      'Villanueva',
      'Tauramena',
      'Paz de Ariporo',
      'Maní',
      'Monterrey',
      'Otro municipio...',
    ],
    'Caquetá': [
      'Florencia',
      'San Vicente del Caguán',
      'Cartagena del Chairá',
      'El Doncello',
      'Puerto Rico',
      'Belén de los Andaquíes',
      'Otro municipio...',
    ],
    'Putumayo': [
      'Mocoa',
      'Puerto Asís',
      'Orito',
      'Valle del Guamuez (La Hormiga)',
      'Villagarzón',
      'Sibundoy',
      'Otro municipio...',
    ],
    'Arauca': [
      'Arauca',
      'Tame',
      'Saravena',
      'Arauquita',
      'Fortul',
      'Otro municipio...',
    ],
    'Atlántico': [
      'Barranquilla',
      'Soledad',
      'Malambo',
      'Sabanalarga',
      'Baranoa',
      'Puerto Colombia',
      'Repelón (Embalse del Guájaro)',
      'Otro municipio...',
    ],
    'Bolívar': [
      'Cartagena',
      'Magangué',
      'El Carmen de Bolívar',
      'Turbaco',
      'Arjona',
      'Mompox',
      'San Pablo',
      'Otro municipio...',
    ],
    'Cesar': [
      'Valledupar',
      'Aguachica',
      'Agustín Codazzi',
      'Bosconia',
      'Curumaní',
      'Chimichagua (Ciénaga de Zapatosa)',
      'La Jagua de Ibirico',
      'Otro municipio...',
    ],
    'Magdalena': [
      'Santa Marta',
      'Ciénaga',
      'Fundación',
      'Plato',
      'El Banco',
      'Aracataca',
      'Pivijay',
      'Sitio Nuevo',
      'Otro municipio...',
    ],
    'Sucre': [
      'Sincelejo',
      'Corozal',
      'San Marcos',
      'San Onofre',
      'Tolú',
      'Sampués',
      'Majagual',
      'Otro municipio...',
    ],
    'Norte de Santander': [
      'Cúcuta',
      'Ocaña',
      'Pamplona',
      'Villa del Rosario',
      'Los Patios',
      'Tibú',
      'El Zulia',
      'Otro municipio...',
    ],
    'Chocó': [
      'Quibdó',
      'Istmina',
      'Tadó',
      'Condoto',
      'Bahía Solano',
      'Acandí',
      'Otro municipio...',
    ],
    'La Guajira': [
      'Riohacha',
      'Maicao',
      'Uribia',
      'Manaure',
      'Fonseca',
      'San Juan del Cesar',
      'Otro municipio...',
    ],
    'Amazonas': [
      'Leticia',
      'Puerto Nariño',
      'Otro municipio...',
    ],
    'Guainía': [
      'Inírida',
      'Barranco Minas',
      'Otro municipio...',
    ],
    'Guaviare': [
      'San José del Guaviare',
      'El Retorno',
      'Calamar',
      'Miraflores',
      'Otro municipio...',
    ],
    'Vaupés': [
      'Mitú',
      'Carurú',
      'Taraira',
      'Otro municipio...',
    ],
    'Vichada': [
      'Puerto Carreño',
      'La Primavera',
      'Santa Rosalía',
      'Cumaribo',
      'Otro municipio...',
    ],
    'San Andrés y Providencia': [
      'San Andrés',
      'Providencia',
      'Otro municipio...',
    ],
  };

  /// Departamentos/Estados de otros países clave
  static const Map<String, List<String>> internationalStates = {
    'Perú': [
      'Puno (Lago Titicaca)',
      'San Martín',
      'Loreto',
      'Ucayali',
      'Junín',
      'Piura',
      'Tumbes',
      'Lima',
      'Arequipa',
      'Cusco',
      'Otro departamento...',
    ],
    'Ecuador': [
      'Guayas (Golfo de Guayaquil)',
      'El Oro',
      'Manabí',
      'Esmeraldas',
      'Santa Elena',
      'Pichincha',
      'Azuay',
      'Tungurahua',
      'Napo',
      'Pastaza',
      'Otro estado/provincia...',
    ],
    'México': [
      'Sinaloa',
      'Sonora',
      'Veracruz',
      'Jalisco',
      'Chiapas',
      'Tabasco',
      'Michoacán',
      'Yucatán',
      'Nayarit',
      'Estado de México',
      'Otro estado...',
    ],
    'Brasil': [
      'Paraná',
      'São Paulo',
      'Santa Catarina',
      'Rondônia',
      'Mato Grosso',
      'Goiás',
      'Bahia',
      'Minas Gerais',
      'Ceará',
      'Pará',
      'Outro estado...',
    ],
    'Chile': [
      'Los Lagos (Puerto Montt)',
      'Aysén',
      'Magallanes',
      'Biobío',
      'Araucanía',
      'Coquimbo',
      'Santiago',
      'Otra región...',
    ],
  };

  /// Ciudades de otros países clave
  static const Map<String, Map<String, List<String>>> internationalCities = {
    'Perú': {
      'Puno (Lago Titicaca)': ['Puno', 'Juliaca', 'Chucuito', 'Yunguyo', 'Otra ciudad...'],
      'San Martín': ['Tarapoto', 'Moyobamba', 'Juanjuí', 'Rioja', 'Otra ciudad...'],
      'Loreto': ['Iquitos', 'Yurimaguas', 'Nauta', 'Requena', 'Otra ciudad...'],
      'Ucayali': ['Pucallpa', 'Coronel Portillo', 'Padre Abad', 'Otra ciudad...'],
      'Piura': ['Piura', 'Sechura', 'Sullana', 'Paita', 'Talara', 'Otra ciudad...'],
      'Tumbes': ['Tumbes', 'Zarumilla', 'Contralmirante Villar', 'Otra ciudad...'],
    },
    'Ecuador': {
      'Guayas (Golfo de Guayaquil)': ['Guayaquil', 'Durán', 'Samborondón', 'Daule', 'Milagro', 'Naranjal', 'Otra ciudad...'],
      'El Oro': ['Machala', 'Santa Rosa', 'Huaquillas', 'Pasaje', 'Arenillas', 'Otra ciudad...'],
      'Manabí': ['Manta', 'Portoviejo', 'Bahía de Caráquez', 'Pedernales', 'Chone', 'Otra ciudad...'],
      'Esmeraldas': ['Esmeraldas', 'Atacames', 'San Lorenzo', 'Muisne', 'Otra ciudad...'],
      'Santa Elena': ['Santa Elena', 'Salinas', 'La Libertad', 'Chanduy', 'Otra ciudad...'],
    },
    'México': {
      'Sinaloa': ['Culiacán', 'Mazatlán', 'Ahome (Los Mochis)', 'Guasave', 'Navolato', 'Otra ciudad...'],
      'Sonora': ['Hermosillo', 'Ciudad Obregón', 'Guaymas', 'Navojoa', 'Nogales', 'Otra ciudad...'],
      'Veracruz': ['Veracruz', 'Boca del Río', 'Alvarado', 'Coatzacoalcos', 'Poza Rica', 'Catemaco', 'Otra ciudad...'],
      'Jalisco': ['Guadalajara', 'Zapopan', 'Puerto Vallarta', 'Tepatitlán', 'Chapala', 'Otra ciudad...'],
      'Chiapas': ['Tuxtla Gutiérrez', 'Tapachula', 'Chiapa de Corzo', 'Palenque', 'Otra ciudad...'],
    },
  };

  /// Obtiene los departamentos o estados correspondientes a un país
  static List<String> getStatesForCountry(String country) {
    if (country == 'Colombia') {
      return colombiaDepartments;
    }
    return internationalStates[country] ?? ['Estado/Provincia Principal', 'Otra región...'];
  }

  /// Obtiene las ciudades o municipios correspondientes
  static List<String> getCitiesForState(String country, String state) {
    if (country == 'Colombia') {
      return colombiaMunicipalities[state] ?? ['Ciudad Capital / Cabecera', 'Otra ciudad...'];
    }

    final countryMap = internationalCities[country];
    if (countryMap != null && countryMap.containsKey(state)) {
      return countryMap[state]!;
    }

    return ['Ciudad Principal', 'Otra ciudad / Municipio...'];
  }

  /// Filtra una lista de strings con búsqueda predictiva tolerante a tildes y mayúsculas
  static List<String> filterList(List<String> items, String query) {
    if (query.trim().isEmpty) return items;
    final normalizedQuery = _normalize(query);
    return items.where((item) => _normalize(item).contains(normalizedQuery)).toList();
  }

  static String _normalize(String text) {
    return text
        .toLowerCase()
        .replaceAll('á', 'a')
        .replaceAll('é', 'e')
        .replaceAll('í', 'i')
        .replaceAll('ó', 'o')
        .replaceAll('ú', 'u')
        .replaceAll('ñ', 'n')
        .trim();
  }
}
