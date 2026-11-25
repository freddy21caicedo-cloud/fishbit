/// Modelo de Registro de Jornales de Campo y Cuadrillas Ocasionales
/// Alineado con el esquema real de `public.jornales` en Supabase:
/// (`id`, `unit_id`, `estanque_id`, `fecha`, `cantidad_jornales`, `valor_jornal`, `total`, `descripcion`, `created_at`).
class JornalRecord {
  final String id;
  final String empresaId;
  final String unidadAcuicolaId;
  final String? estanqueId;
  final String laborRealizada;
  final int cantidadJornales;
  final double valorPorJornal;
  final double totalPagado;
  final String? observaciones;
  final String? responsablePago;
  final DateTime fecha;
  final DateTime creadoEn;

  const JornalRecord({
    required this.id,
    required this.empresaId,
    required this.unidadAcuicolaId,
    this.estanqueId,
    required this.laborRealizada,
    required this.cantidadJornales,
    required this.valorPorJornal,
    required this.totalPagado,
    this.observaciones,
    this.responsablePago,
    required this.fecha,
    required this.creadoEn,
  });

  factory JornalRecord.fromJson(Map<String, dynamic> json) {
    final cant = (json['cantidad_jornales'] as num?)?.toInt() ?? 1;
    final valor = (json['valor_jornal'] as num?)?.toDouble() ??
        (json['valor_por_jornal'] as num?)?.toDouble() ??
        65000.0;
    final total = (json['total'] as num?)?.toDouble() ??
        (json['total_pagado'] as num?)?.toDouble() ??
        (cant * valor);

    String labor = json['labor_realizada']?.toString() ?? '';
    String? obs = json['observaciones']?.toString();
    String? resp = json['responsable_pago']?.toString();

    final rawDesc = json['descripcion']?.toString() ?? '';
    if (labor.isEmpty && rawDesc.isNotEmpty) {
      final parts = rawDesc.split(' | ');
      labor = parts.first.trim();
      for (final part in parts.skip(1)) {
        final trimmed = part.trim();
        if (trimmed.startsWith('Resp:')) {
          resp ??= trimmed.substring(5).trim();
        } else if (trimmed.isNotEmpty) {
          obs = obs == null || obs.isEmpty ? trimmed : '$obs • $trimmed';
        }
      }
    }
    if (labor.isEmpty) {
      labor = 'Labores de Campo';
    }

    final createdRaw = json['created_at'] ?? json['creado_en'];

    return JornalRecord(
      id: json['id']?.toString() ?? '',
      empresaId: json['empresa_id']?.toString() ?? '',
      unidadAcuicolaId: json['unit_id']?.toString() ??
          json['unidad_acuicola_id']?.toString() ??
          '',
      estanqueId: json['estanque_id']?.toString(),
      laborRealizada: labor,
      cantidadJornales: cant,
      valorPorJornal: valor,
      totalPagado: total,
      observaciones: (obs != null && obs.isNotEmpty) ? obs : null,
      responsablePago: (resp != null && resp.isNotEmpty) ? resp : null,
      fecha: json['fecha'] != null
          ? DateTime.tryParse(json['fecha'].toString()) ?? DateTime.now()
          : DateTime.now(),
      creadoEn: createdRaw != null
          ? DateTime.tryParse(createdRaw.toString()) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  /// Construye la descripción consolidada para la columna `descripcion` de `public.jornales`
  String _buildDescripcion() {
    final segments = <String>[laborRealizada.trim()];
    if (responsablePago != null && responsablePago!.trim().isNotEmpty) {
      segments.add('Resp: ${responsablePago!.trim()}');
    }
    if (observaciones != null && observaciones!.trim().isNotEmpty) {
      segments.add(observaciones!.trim());
    }
    return segments.join(' | ');
  }

  /// Serializa al esquema real de `public.jornales` en Supabase
  Map<String, dynamic> toJson() => {
        'id': id,
        'unit_id': unidadAcuicolaId,
        'estanque_id': (estanqueId != null && estanqueId!.isNotEmpty) ? estanqueId : null,
        'fecha': fecha.toIso8601String().split('T')[0],
        'cantidad_jornales': cantidadJornales,
        'valor_jornal': valorPorJornal,
        'total': totalPagado,
        'descripcion': _buildDescripcion(),
      };
}
