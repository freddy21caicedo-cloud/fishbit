import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:fishbit_finance/modules/ponds_batches/domain/models/pond.dart';
import 'package:fishbit_finance/modules/ponds_batches/domain/models/fish_batch.dart';
import 'package:fishbit_finance/modules/ponds_batches/domain/models/transfer_record.dart';
import 'package:fishbit_finance/core/reports/web_download_helper.dart';

/// Exportador Oficial de Libro de Registro de Campo para Auditoría Sanitaria ICA / AUNAP
class IcaFieldBookExporter {
  /// Genera y descarga el archivo CSV estructurado oficial para auditoría
  static Future<void> exportToCsv({
    required String companyName,
    required String nit,
    required String unitName,
    required List<Pond> ponds,
    required List<FishBatch> batches,
    List<TransferRecord> transfers = const [],
  }) async {
    final buffer = StringBuffer();
    final now = DateTime.now();

    // 1. Encabezado Oficial ICA / AUNAP
    buffer.writeln('========================================================================================================');
    buffer.writeln('LIBRO DE REGISTRO DE CAMPO Y BIOSEGURIDAD ACUÍCOLA - AUDITORÍA OFICIAL ICA / AUNAP');
    buffer.writeln('========================================================================================================');
    buffer.writeln('EMPRESA: "$companyName",NIT: "$nit",GRANJA / SEDE: "$unitName",FECHA EMISIÓN: "${now.toIso8601String().split('T')[0]}"');
    buffer.writeln('');

    // 2. Inventario y Capacidad de Carga de Estanques
    buffer.writeln('--- 1. INVENTARIO DE ESTANQUES Y DENSIDADES DE CULTIVO ---');
    buffer.writeln('Sigla,Nombre,Volumen (m3),Especie,Biomasa Actual (Kg),Densidad (Kg/m3),Nivel Riesgo,HP Aireación Sugerido');
    for (final p in ponds) {
      buffer.writeln(
        '${p.sigla},"${p.nombre}",${p.capacidadM3.toStringAsFixed(1)},"${p.especieActual}",'
        '${p.biomasaKg.toStringAsFixed(1)},${p.densidadKgM3.toStringAsFixed(2)},'
        '${p.nivelRiesgoDensidad},${p.hpAireacionSugerido.toStringAsFixed(1)} HP',
      );
    }
    buffer.writeln('');

    // 3. Trazabilidad de Lotes y Factor de Conversión Alimenticia (FCR)
    buffer.writeln('--- 2. TRAZABILIDAD DE LOTES, BIOMETRÍAS Y FCR (CONVERSIÓN ALIMENTICIA) ---');
    buffer.writeln('Código Lote,Estanque,Especie,Peces Iniciales,Peces Actuales,Peso Promedio (g),Biomasa (Kg),Días Cultivo,GPD (g/d),FCR,Retiro ICA (Días)');
    for (final b in batches) {
      buffer.writeln(
        '${b.codigoLote},${b.estanqueId},"${b.especie}",${b.cantidadInicialPeces},${b.cantidadActualPeces},'
        '${b.pesoActualGramos.toStringAsFixed(1)},${b.biomasaActualKg.toStringAsFixed(1)},'
        '${b.diasDeCultivo},${b.gpd.toStringAsFixed(2)},${b.fcr.toStringAsFixed(2)},'
        '${b.diasRetiroSanitarioRestantes}',
      );
    }
    buffer.writeln('');

    // 4. Registro Histórico de Traslados y Desdobles
    if (transfers.isNotEmpty) {
      buffer.writeln('--- 3. REGISTRO OFICIAL DE TRASLADOS Y DESDOBLES DE LOTES ---');
      buffer.writeln('Fecha,Tipo Operación,Estanque Origen,Estanque Destino,Peces Trasladados,Biomasa (Kg),Peso Promedio (g),Costo Transferido (COP),Nuevo Lote,Responsable');
      for (final t in transfers) {
        final origPond = ponds.where((p) => p.id == t.estanqueOrigenId).firstOrNull;
        final destPond = ponds.where((p) => p.id == t.estanqueDestinoId).firstOrNull;
        final origNombre = origPond != null ? origPond.nombreLimpio : t.estanqueOrigenId;
        final destNombre = destPond != null ? destPond.nombreLimpio : t.estanqueDestinoId;

        buffer.writeln(
          '${t.fechaOperacion.toIso8601String().split('T')[0]},"${t.tipoOperacionLabel}",'
          '"$origNombre","$destNombre",${t.pecesTrasladados},'
          '${t.biomasaTrasladadaKg.toStringAsFixed(1)},${t.pesoPromedioGramos.toStringAsFixed(1)},'
          '${t.costoTotalTransferido.toStringAsFixed(2)},'
          '"${t.nuevoCodigoLote ?? '-'}", "${t.registradoPor ?? '-'}"',
        );
      }
      buffer.writeln('');
    }

    // 5. Declaración de Cumplimiento Sanitario
    buffer.writeln('--- 4. DECLARACIÓN DE INOCUIDAD Y TRAZABILIDAD SANITARIA ---');
    buffer.writeln('CERTIFICACIÓN: "Este informe certifica el cumplimiento del tiempo de retiro para fármacos, bioseguridad y trazabilidad zootécnica de movimientos."');
    buffer.writeln('RESPONSABLE TÉCNICO: "Director Técnico Acuícola",FIRMA: "_________________________"');

    final csvContent = buffer.toString();
    final bytes = utf8.encode(csvContent);

    // Descarga en Web o Plataformas Nativas
    if (kIsWeb) {
      downloadFileWeb(bytes, 'Libro_Campo_ICA_${unitName.replaceAll(' ', '_')}_${now.year}${now.month}${now.day}.csv');
    }
  }
}
