import 'package:fishbit_finance/core/utils/currency_formatters.dart';

enum TransferType { trasladoTotal, desdobleParcial }

/// Registro inmutable de Auditoría Histórica de Traslados y Desdobles de Lotes
class TransferRecord {
  final String id;
  final String empresaId;
  final String unidadAcuicolaId;
  final String? loteOrigenId;
  final String? loteDestinoId;
  final String estanqueOrigenId;
  final String estanqueDestinoId;
  final TransferType tipoOperacion;
  final int pecesTrasladados;
  final double pesoPromedioGramos;
  final double biomasaTrasladadaKg;
  final double proporcionCostos; // 0.0 a 1.0
  final double costoAlevinosTransferido;
  final double costoInsumosTransferido;
  final double costoFijoTransferido;
  final double costoTotalTransferido;
  final String? nuevoCodigoLote;
  final String? registradoPor;
  final DateTime fechaOperacion;
  final DateTime creadoEn;

  const TransferRecord({
    required this.id,
    required this.empresaId,
    required this.unidadAcuicolaId,
    this.loteOrigenId,
    this.loteDestinoId,
    required this.estanqueOrigenId,
    required this.estanqueDestinoId,
    required this.tipoOperacion,
    required this.pecesTrasladados,
    required this.pesoPromedioGramos,
    required this.biomasaTrasladadaKg,
    required this.proporcionCostos,
    this.costoAlevinosTransferido = 0.0,
    this.costoInsumosTransferido = 0.0,
    this.costoFijoTransferido = 0.0,
    this.costoTotalTransferido = 0.0,
    this.nuevoCodigoLote,
    this.registradoPor,
    required this.fechaOperacion,
    required this.creadoEn,
  });

  bool get esDesdoble => tipoOperacion == TransferType.desdobleParcial;
  String get tipoOperacionLabel => esDesdoble ? 'Desdoble Parcial' : 'Traslado Total';

  String get costoTotalFormatted => CurrencyFormatters.formatCOP(costoTotalTransferido);
  String get biomasaFormatted => CurrencyFormatters.formatKg(biomasaTrasladadaKg);
  String get pecesFormatted => '${CurrencyFormatters.formatInt(pecesTrasladados)} peces';

  static TransferType parseType(String? val) {
    if (val == null) return TransferType.trasladoTotal;
    final clean = val.toUpperCase().trim();
    if (clean.contains('DESDOBLE')) return TransferType.desdobleParcial;
    return TransferType.trasladoTotal;
  }

  static String typeToString(TransferType t) {
    return t == TransferType.desdobleParcial ? 'DESDOBLE_PARCIAL' : 'TRASLADO_TOTAL';
  }

  factory TransferRecord.fromJson(Map<String, dynamic> json) {
    return TransferRecord(
      id: json['id'] as String,
      empresaId: json['empresa_id'] as String? ?? '',
      unidadAcuicolaId: json['unidad_acuicola_id'] as String? ?? '',
      loteOrigenId: json['lote_origen_id'] as String?,
      loteDestinoId: json['lote_destino_id'] as String?,
      estanqueOrigenId: json['estanque_origen_id'] as String? ?? '',
      estanqueDestinoId: json['estanque_destino_id'] as String? ?? '',
      tipoOperacion: parseType(json['tipo_operacion'] as String?),
      pecesTrasladados: (json['peces_trasladados'] as num?)?.toInt() ?? 0,
      pesoPromedioGramos: (json['peso_promedio_gramos'] as num?)?.toDouble() ?? 1.0,
      biomasaTrasladadaKg: (json['biomasa_trasladada_kg'] as num?)?.toDouble() ?? 0.0,
      proporcionCostos: (json['proporcion_costos'] as num?)?.toDouble() ?? 0.0,
      costoAlevinosTransferido: (json['costo_alevinos_transferido'] as num?)?.toDouble() ?? 0.0,
      costoInsumosTransferido: (json['costo_insumos_transferido'] as num?)?.toDouble() ?? 0.0,
      costoFijoTransferido: (json['costo_fijo_transferido'] as num?)?.toDouble() ?? 0.0,
      costoTotalTransferido: (json['costo_total_transferido'] as num?)?.toDouble() ?? 0.0,
      nuevoCodigoLote: json['nuevo_codigo_lote'] as String?,
      registradoPor: json['registrado_por'] as String?,
      fechaOperacion: json['fecha_operacion'] != null
          ? DateTime.parse(json['fecha_operacion'] as String)
          : DateTime.now(),
      creadoEn: json['creado_en'] != null
          ? DateTime.parse(json['creado_en'] as String)
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'empresa_id': empresaId,
        'unidad_acuicola_id': unidadAcuicolaId,
        'lote_origen_id': loteOrigenId,
        'lote_destino_id': loteDestinoId,
        'estanque_origen_id': estanqueOrigenId,
        'estanque_destino_id': estanqueDestinoId,
        'tipo_operacion': typeToString(tipoOperacion),
        'peces_trasladados': pecesTrasladados,
        'peso_promedio_gramos': pesoPromedioGramos,
        'biomasa_trasladada_kg': biomasaTrasladadaKg,
        'proporcion_costos': proporcionCostos,
        'costo_alevinos_transferido': costoAlevinosTransferido,
        'costo_insumos_transferido': costoInsumosTransferido,
        'costo_fijo_transferido': costoFijoTransferido,
        'costo_total_transferido': costoTotalTransferido,
        'nuevo_codigo_lote': nuevoCodigoLote,
        'registrado_por': registradoPor,
        'fecha_operacion': fechaOperacion.toIso8601String().split('T')[0],
        'creado_en': creadoEn.toIso8601String(),
      };
}
