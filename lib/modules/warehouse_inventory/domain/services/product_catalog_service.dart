import '../models/supplier.dart';

/// Modelo de producto de catálogo oficial con su especie y etapa
class CatalogProduct {
  final String nombre;
  final String especieObjetivo; // 'Trucha', 'Tilapia', 'Cachama', 'General'
  final String etapa; // 'Iniciación', 'Levante', 'Engorde', 'Reproducción', 'Tratamiento', 'General'
  final double pesoPresentacionKg;
  final double proteinaPct;
  final double precioEstimadoCOP;

  const CatalogProduct({
    required this.nombre,
    required this.especieObjetivo,
    required this.etapa,
    this.pesoPresentacionKg = 40.0,
    this.proteinaPct = 0.0,
    this.precioEstimadoCOP = 100000.0,
  });
}

/// Servicio que centraliza el portafolio oficial de proveedores y productos
class ProductCatalogService {
  ProductCatalogService._();

  // -------------------------------------------------------------
  // 1. PROVEEDORES OFICIALES PRECARGADOS
  // -------------------------------------------------------------

  /// 6 marcas oficiales de concentrados en Colombia
  static const List<Supplier> kOfficialFeedSuppliers = [
    Supplier(
      id: 'sup-italcol',
      nit: '860.026.895-8',
      nombre: 'Italcol S.A.',
      telefono: '+57 (601) 369-2000',
      ciudad: 'Bogotá / Ibagué',
      categoriaPrincipal: 'concentrados',
    ),
    Supplier(
      id: 'sup-solla',
      nit: '890.900.291-8',
      nombre: 'Solla S.A.',
      telefono: '+57 (604) 448-0020',
      ciudad: 'Medellín / Buga',
      categoriaPrincipal: 'concentrados',
    ),
    Supplier(
      id: 'sup-vgr-italcol',
      nit: '901.378.925-0',
      nombre: 'VGR Italcol del Norte S.A.S.',
      telefono: '+57 (605) 385-2000',
      ciudad: 'Barranquilla / Costa Caribe',
      categoriaPrincipal: 'concentrados',
    ),
    Supplier(
      id: 'sup-contegral',
      nit: '890.901.271-5',
      nombre: 'Contegral S.A.S.',
      telefono: '+57 (604) 370-5000',
      ciudad: 'Envigado / Barranquilla',
      categoriaPrincipal: 'concentrados',
    ),
    Supplier(
      id: 'sup-finca',
      nit: '860.004.828-1',
      nombre: 'Finca S.A.S.',
      telefono: '+57 (601) 422-1000',
      ciudad: 'Buga / Girardot',
      categoriaPrincipal: 'concentrados',
    ),
    Supplier(
      id: 'sup-agrinal',
      nit: '890.400.514-1',
      nombre: 'Agrinal Colombia S.A.S.',
      telefono: '+57 (601) 825-8800',
      ciudad: 'Buga / Villavicencio',
      categoriaPrincipal: 'concentrados',
    ),
  ];

  /// Único proveedor precargado para insumos, farmacia y tratamientos
  static const Supplier kSanoaSupplier = Supplier(
    id: 'sup-sanoa',
    nit: '1094283101',
    nombre: 'Sanoa',
    telefono: '+57 300 000 0000',
    ciudad: 'Colombia',
    categoriaPrincipal: 'insumos',
    productosOfrecidos: [
      'Sal Marina sin Yodo (Saco 50 Kg)',
      'Cal Agrícola Carbonato de Calcio (Saco 40 Kg)',
      'Cal Viva Óxido de Calcio (Saco 40 Kg)',
      'Melaza de Caña Pura (Caneca 25 Kg)',
      'Oxitetraciclina Polvo 50% (Bolsa 5 Kg)',
      'Florfenicol 50% Grado Acuícola',
      'Formalina Terapéutica 37% (Galón 4L)',
      'Azul de Metileno Grado Farmacéutico',
      'Complejo Vitamínico C Hidrosoluble',
      'Bacterias Probióticas Bacillus (Litro)',
      'Zeolita Micronizada (Saco 25 Kg)',
    ],
  );

  // -------------------------------------------------------------
  // 2. PORTAFOLIO DE CONCENTRADOS CLASIFICADO POR MARCA Y ESPECIE
  // -------------------------------------------------------------

  static const Map<String, List<CatalogProduct>> _feedProductsByBrand = {
    'Italcol S.A.': [
      // Trucha
      CatalogProduct(nombre: 'Aquatruchas Iniciación 50% E', especieObjetivo: 'Trucha', etapa: 'Iniciación', proteinaPct: 50.0, pesoPresentacionKg: 20.0, precioEstimadoCOP: 195000),
      CatalogProduct(nombre: 'Aquatruchas Levante 45% E Pigmento', especieObjetivo: 'Trucha', etapa: 'Levante', proteinaPct: 45.0, pesoPresentacionKg: 40.0, precioEstimadoCOP: 155000),
      CatalogProduct(nombre: 'Aquatruchas Levante 45% E Sin Pigmento', especieObjetivo: 'Trucha', etapa: 'Levante', proteinaPct: 45.0, pesoPresentacionKg: 40.0, precioEstimadoCOP: 145000),
      CatalogProduct(nombre: 'Aquatrucha Finalización 40% E Pigmento', especieObjetivo: 'Trucha', etapa: 'Engorde', proteinaPct: 40.0, pesoPresentacionKg: 40.0, precioEstimadoCOP: 148000),
      CatalogProduct(nombre: 'Aquatrucha Finalización 40% E Sin Pigmento', especieObjetivo: 'Trucha', etapa: 'Engorde', proteinaPct: 40.0, pesoPresentacionKg: 40.0, precioEstimadoCOP: 138000),
      CatalogProduct(nombre: 'Aquatrucha Reproductores 42% E', especieObjetivo: 'Trucha', etapa: 'Reproducción', proteinaPct: 42.0, pesoPresentacionKg: 40.0, precioEstimadoCOP: 165000),
      // Tilapia
      CatalogProduct(nombre: 'Aquatilapia Micro Extruido 48%', especieObjetivo: 'Tilapia', etapa: 'Iniciación', proteinaPct: 48.0, pesoPresentacionKg: 20.0, precioEstimadoCOP: 195000),
      CatalogProduct(nombre: 'Aquatilapia 45% E (Iniciador)', especieObjetivo: 'Tilapia', etapa: 'Iniciación', proteinaPct: 45.0, pesoPresentacionKg: 40.0, precioEstimadoCOP: 134520),
      CatalogProduct(nombre: 'Aquatilapia 45% Harina', especieObjetivo: 'Tilapia', etapa: 'Iniciación', proteinaPct: 45.0, pesoPresentacionKg: 40.0, precioEstimadoCOP: 130000),
      CatalogProduct(nombre: 'Aquatilapia 38% E (Levante I)', especieObjetivo: 'Tilapia', etapa: 'Levante', proteinaPct: 38.0, pesoPresentacionKg: 40.0, precioEstimadoCOP: 120764),
      CatalogProduct(nombre: 'Aquatilapia 34% E (Levante II)', especieObjetivo: 'Tilapia', etapa: 'Levante', proteinaPct: 34.0, pesoPresentacionKg: 40.0, precioEstimadoCOP: 105000),
      CatalogProduct(nombre: 'Aquatilapia 32% E (Engorde)', especieObjetivo: 'Tilapia', etapa: 'Engorde', proteinaPct: 32.0, pesoPresentacionKg: 40.0, precioEstimadoCOP: 98000),
      CatalogProduct(nombre: 'Aquatilapia 30% E (Engorde I)', especieObjetivo: 'Tilapia', etapa: 'Engorde', proteinaPct: 30.0, pesoPresentacionKg: 40.0, precioEstimadoCOP: 95684),
      CatalogProduct(nombre: 'Aquatilapia 25% E (Engorde Final)', especieObjetivo: 'Tilapia', etapa: 'Engorde', proteinaPct: 25.0, pesoPresentacionKg: 40.0, precioEstimadoCOP: 86906),
      CatalogProduct(nombre: 'Aquatilapia 20% E', especieObjetivo: 'Tilapia', etapa: 'Engorde', proteinaPct: 20.0, pesoPresentacionKg: 40.0, precioEstimadoCOP: 78000),
      // Especies Nativas / Cachama
      CatalogProduct(nombre: 'Aquatropico 22% E', especieObjetivo: 'Cachama', etapa: 'Engorde', proteinaPct: 22.0, pesoPresentacionKg: 40.0, precioEstimadoCOP: 79000),
      CatalogProduct(nombre: 'Aquatropico 28% E', especieObjetivo: 'Cachama', etapa: 'Levante', proteinaPct: 28.0, pesoPresentacionKg: 40.0, precioEstimadoCOP: 89000),
    ],
    'VGR Italcol del Norte S.A.S.': [
      // Trucha
      CatalogProduct(nombre: 'Aquatruchas Iniciación 50% E', especieObjetivo: 'Trucha', etapa: 'Iniciación', proteinaPct: 50.0, pesoPresentacionKg: 20.0, precioEstimadoCOP: 195000),
      CatalogProduct(nombre: 'Aquatruchas Levante 45% E Pigmento', especieObjetivo: 'Trucha', etapa: 'Levante', proteinaPct: 45.0, pesoPresentacionKg: 40.0, precioEstimadoCOP: 155000),
      CatalogProduct(nombre: 'Aquatrucha Finalización 40% E Pigmento', especieObjetivo: 'Trucha', etapa: 'Engorde', proteinaPct: 40.0, pesoPresentacionKg: 40.0, precioEstimadoCOP: 148000),
      // Tilapia
      CatalogProduct(nombre: 'Aquatilapia Micro Extruido 48%', especieObjetivo: 'Tilapia', etapa: 'Iniciación', proteinaPct: 48.0, pesoPresentacionKg: 20.0, precioEstimadoCOP: 195000),
      CatalogProduct(nombre: 'Aquatilapia 45% E (Iniciador)', especieObjetivo: 'Tilapia', etapa: 'Iniciación', proteinaPct: 45.0, pesoPresentacionKg: 40.0, precioEstimadoCOP: 134520),
      CatalogProduct(nombre: 'Aquatilapia 38% E (Levante I)', especieObjetivo: 'Tilapia', etapa: 'Levante', proteinaPct: 38.0, pesoPresentacionKg: 40.0, precioEstimadoCOP: 120764),
      CatalogProduct(nombre: 'Aquatilapia 32% E (Engorde)', especieObjetivo: 'Tilapia', etapa: 'Engorde', proteinaPct: 32.0, pesoPresentacionKg: 40.0, precioEstimadoCOP: 98000),
      CatalogProduct(nombre: 'Aquatilapia 25% E (Engorde Final)', especieObjetivo: 'Tilapia', etapa: 'Engorde', proteinaPct: 25.0, pesoPresentacionKg: 40.0, precioEstimadoCOP: 86906),
      CatalogProduct(nombre: 'Aquatropico 22% E', especieObjetivo: 'Cachama', etapa: 'Engorde', proteinaPct: 22.0, pesoPresentacionKg: 40.0, precioEstimadoCOP: 79000),
    ],
    'Solla S.A.': [
      // Trucha
      CatalogProduct(nombre: 'Solla Trucha Arco Iris Iniciación 48%', especieObjetivo: 'Trucha', etapa: 'Iniciación', proteinaPct: 48.0, pesoPresentacionKg: 20.0, precioEstimadoCOP: 192000),
      CatalogProduct(nombre: 'Solla Trucha Arco Iris Levante 45%', especieObjetivo: 'Trucha', etapa: 'Levante', proteinaPct: 45.0, pesoPresentacionKg: 40.0, precioEstimadoCOP: 152000),
      CatalogProduct(nombre: 'Trucha Arco Iris Engorde Pigmento 40%', especieObjetivo: 'Trucha', etapa: 'Engorde', proteinaPct: 40.0, pesoPresentacionKg: 40.0, precioEstimadoCOP: 146000),
      CatalogProduct(nombre: 'Trucha Arco Iris Engorde Sin Pigmento 40%', especieObjetivo: 'Trucha', etapa: 'Engorde', proteinaPct: 40.0, pesoPresentacionKg: 40.0, precioEstimadoCOP: 136000),
      // Tilapia
      CatalogProduct(nombre: 'Solla Mojarra 45% (Alevines)', especieObjetivo: 'Tilapia', etapa: 'Iniciación', proteinaPct: 45.0, pesoPresentacionKg: 40.0, precioEstimadoCOP: 132000),
      CatalogProduct(nombre: 'Mojarras 38% PB', especieObjetivo: 'Tilapia', etapa: 'Levante', proteinaPct: 38.0, pesoPresentacionKg: 40.0, precioEstimadoCOP: 119000),
      CatalogProduct(nombre: 'Mojarras 32% PB', especieObjetivo: 'Tilapia', etapa: 'Engorde', proteinaPct: 32.0, pesoPresentacionKg: 40.0, precioEstimadoCOP: 97000),
      CatalogProduct(nombre: 'Mojarras 24% PB', especieObjetivo: 'Tilapia', etapa: 'Engorde', proteinaPct: 24.0, pesoPresentacionKg: 40.0, precioEstimadoCOP: 84000),
      CatalogProduct(nombre: 'Mojarra Reproductores 38%', especieObjetivo: 'Tilapia', etapa: 'Reproducción', proteinaPct: 38.0, pesoPresentacionKg: 40.0, precioEstimadoCOP: 125000),
      CatalogProduct(nombre: 'Solla Peces 20% (Introducción)', especieObjetivo: 'General', etapa: 'Engorde', proteinaPct: 20.0, pesoPresentacionKg: 40.0, precioEstimadoCOP: 76000),
    ],
    'Contegral S.A.S.': [
      // Trucha
      CatalogProduct(nombre: 'Maxi Truchas 45 SP', especieObjetivo: 'Trucha', etapa: 'Levante', proteinaPct: 45.0, pesoPresentacionKg: 40.0, precioEstimadoCOP: 150000),
      CatalogProduct(nombre: 'Truchas Iniciación 48%', especieObjetivo: 'Trucha', etapa: 'Iniciación', proteinaPct: 48.0, pesoPresentacionKg: 20.0, precioEstimadoCOP: 190000),
      CatalogProduct(nombre: 'Truchas 40% Pigmento', especieObjetivo: 'Trucha', etapa: 'Engorde', proteinaPct: 40.0, pesoPresentacionKg: 40.0, precioEstimadoCOP: 144000),
      // Tilapia
      CatalogProduct(nombre: 'Tilapias Iniciación 45%', especieObjetivo: 'Tilapia', etapa: 'Iniciación', proteinaPct: 45.0, pesoPresentacionKg: 40.0, precioEstimadoCOP: 131000),
      CatalogProduct(nombre: 'Peces Prelevante 38%', especieObjetivo: 'Tilapia', etapa: 'Levante', proteinaPct: 38.0, pesoPresentacionKg: 40.0, precioEstimadoCOP: 118000),
      CatalogProduct(nombre: 'Peces Levante 32%', especieObjetivo: 'Tilapia', etapa: 'Engorde', proteinaPct: 32.0, pesoPresentacionKg: 40.0, precioEstimadoCOP: 96000),
      CatalogProduct(nombre: 'Maxi-Peces 34%', especieObjetivo: 'Tilapia', etapa: 'Levante', proteinaPct: 34.0, pesoPresentacionKg: 40.0, precioEstimadoCOP: 102000),
      CatalogProduct(nombre: 'Maxi-Peces 28%', especieObjetivo: 'Tilapia', etapa: 'Engorde', proteinaPct: 28.0, pesoPresentacionKg: 40.0, precioEstimadoCOP: 89000),
      CatalogProduct(nombre: 'Maxi-Peces 25%', especieObjetivo: 'Tilapia', etapa: 'Engorde', proteinaPct: 25.0, pesoPresentacionKg: 40.0, precioEstimadoCOP: 85000),
    ],
    'Agrinal Colombia S.A.S.': [
      // Trucha
      CatalogProduct(nombre: 'Trucha 48% Iniciación Sin Pigmento Extruida', especieObjetivo: 'Trucha', etapa: 'Iniciación', proteinaPct: 48.0, pesoPresentacionKg: 20.0, precioEstimadoCOP: 188000),
      CatalogProduct(nombre: 'Truchas 45% Sin Pigmento Extruido', especieObjetivo: 'Trucha', etapa: 'Levante', proteinaPct: 45.0, pesoPresentacionKg: 40.0, precioEstimadoCOP: 149000),
      CatalogProduct(nombre: 'Truchas 40% Con Pigmento Extruido', especieObjetivo: 'Trucha', etapa: 'Engorde', proteinaPct: 40.0, pesoPresentacionKg: 40.0, precioEstimadoCOP: 143000),
      // Tilapia
      CatalogProduct(nombre: 'Tilapia 45% Extruida (Iniciación)', especieObjetivo: 'Tilapia', etapa: 'Iniciación', proteinaPct: 45.0, pesoPresentacionKg: 40.0, precioEstimadoCOP: 130000),
      CatalogProduct(nombre: 'Tilapia 38% Extruida (Levante)', especieObjetivo: 'Tilapia', etapa: 'Levante', proteinaPct: 38.0, pesoPresentacionKg: 40.0, precioEstimadoCOP: 117000),
      CatalogProduct(nombre: 'Tilapia 30% Extruida (Desarrollo)', especieObjetivo: 'Tilapia', etapa: 'Engorde', proteinaPct: 30.0, pesoPresentacionKg: 40.0, precioEstimadoCOP: 94000),
      CatalogProduct(nombre: 'Tilapia 24% Extruida (Engorde)', especieObjetivo: 'Tilapia', etapa: 'Engorde', proteinaPct: 24.0, pesoPresentacionKg: 40.0, precioEstimadoCOP: 82000),
    ],
    'Finca S.A.S.': [
      CatalogProduct(nombre: 'Tilapia Iniciación 45%', especieObjetivo: 'Tilapia', etapa: 'Iniciación', proteinaPct: 45.0, pesoPresentacionKg: 40.0, precioEstimadoCOP: 129000),
      CatalogProduct(nombre: 'Tilapia Levante 38%', especieObjetivo: 'Tilapia', etapa: 'Levante', proteinaPct: 38.0, pesoPresentacionKg: 40.0, precioEstimadoCOP: 116000),
      CatalogProduct(nombre: 'Tilapia Desarrollo 32%', especieObjetivo: 'Tilapia', etapa: 'Engorde', proteinaPct: 32.0, pesoPresentacionKg: 40.0, precioEstimadoCOP: 95000),
      CatalogProduct(nombre: 'Tilapia Engorde 24%', especieObjetivo: 'Tilapia', etapa: 'Engorde', proteinaPct: 24.0, pesoPresentacionKg: 40.0, precioEstimadoCOP: 81000),
    ],
  };

  // -------------------------------------------------------------
  // 3. CONSULTAS DINÁMICAS BASADAS EN EMPRESA Y ESPECIE
  // -------------------------------------------------------------

  /// Comprueba si la especie del producto coincide con las especies habilitadas de la empresa
  static bool _matchesCompanySpecies(String targetSpecies, List<String> companySpecies) {
    if (targetSpecies == 'General') return true;
    if (companySpecies.isEmpty) return true;

    final targetLower = targetSpecies.toLowerCase();
    for (final cs in companySpecies) {
      final compLower = cs.toLowerCase();
      if (compLower.contains('trucha') && targetLower.contains('trucha')) return true;
      if (compLower.contains('tilapia') && targetLower.contains('tilapia')) return true;
      if (compLower.contains('cachama') && targetLower.contains('cachama')) return true;
      if (compLower.contains('bocachico') && targetLower.contains('bocachico')) return true;
    }
    return false;
  }

  /// Retorna la lista de productos disponibles para un proveedor de concentrados,
  /// filtrando exclusivamente por las especies habilitadas de la empresa.
  static List<String> getFeedProductsForSupplier(String supplierName, List<String> companySpecies) {
    final list = _feedProductsByBrand[supplierName];
    if (list == null || list.isEmpty) return [];

    final filtered = list
        .where((p) => _matchesCompanySpecies(p.especieObjetivo, companySpecies))
        .map((p) => p.nombre)
        .toList();

    // Si por alguna razón ninguna coincidió (ej. empresa configuró especie atípica), devolver todo el portafolio del proveedor
    if (filtered.isEmpty) {
      return list.map((p) => p.nombre).toList();
    }
    return filtered;
  }

  /// Genera la lista plana de Material Biológico (Ovas, Larvas, Alevinos)
  /// estrictamente para las especies habilitadas en la empresa.
  static List<String> getBiologicalProducts(List<String> companySpecies) {
    final effectiveSpecies = companySpecies.isNotEmpty ? companySpecies : ['Trucha Arcoíris'];
    final List<String> results = [];

    for (final esp in effectiveSpecies) {
      results.add('Ovas de $esp');
      results.add('Larvas de $esp');
      results.add('Alevinos de $esp');
    }

    results.add('Otro (Personalizado)');
    return results;
  }

  /// Obtiene los proveedores predeterminados para una categoría
  static List<Supplier> getOfficialSuppliers(String category) {
    switch (category) {
      case 'concentrados':
        return kOfficialFeedSuppliers;
      case 'insumos':
      case 'farmacia':
      case 'oxigenadores':
        return [kSanoaSupplier];
      case 'alevinos':
      default:
        return []; // Sin proveedores ficticios de semilla/genética
    }
  }
}
