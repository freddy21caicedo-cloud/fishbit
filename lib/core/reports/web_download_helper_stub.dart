import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

/// Helper para plataformas no-web (Android, iOS, Windows, macOS, Linux):
/// Guarda el archivo en el directorio temporal y abre el diálogo nativo de compartir
Future<void> downloadFileWeb(List<int> bytes, String fileName) async {
  try {
    final tempDir = await getTemporaryDirectory();
    final file = File('${tempDir.path}/$fileName');
    await file.writeAsBytes(bytes, flush: true);

    await Share.shareXFiles(
      [XFile(file.path)],
      text: 'Libro Oficial ICA / AUNAP: $fileName',
      subject: fileName,
    );
  } catch (e) {
    debugPrint('[ReportExport] Error al exportar archivo $fileName en plataforma nativa: $e');
  }
}
