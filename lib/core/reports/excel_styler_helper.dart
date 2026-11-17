import 'package:excel/excel.dart';
import 'package:intl/intl.dart';

/// Utilidad centralizada para diseño visual, jerarquía, personalidad corporativa
/// y formato de reportes Excel (.xlsx) para auditorías oficiales ICA / AUNAP.
class ExcelStylerHelper {
  static final _currencyFmt = NumberFormat.currency(locale: 'es_CO', symbol: '\$', decimalDigits: 0);
  static final _numberFmt = NumberFormat('#,##0.0', 'es_CO');
  static final _intFmt = NumberFormat('#,##0', 'es_CO');

  static String formatCurrency(double amount) => _currencyFmt.format(amount);
  static String formatNumber(double value) => _numberFmt.format(value);
  static String formatInt(int value) => _intFmt.format(value);

  // ─── Estilos de Celdas Institucionales y de Encabezado ─────────────────────

  /// Fila de Marca y Certificación Corporativa FishBit
  static CellStyle get corporateBrandStyle => CellStyle(
        backgroundColorHex: ExcelColor.fromHexString('#081B2A'),
        fontColorHex: ExcelColor.fromHexString('#00E5FF'),
        bold: true,
        fontSize: 10,
        horizontalAlign: HorizontalAlign.Center,
        verticalAlign: VerticalAlign.Center,
      );

  /// Estilo para el Título Principal Institucional
  static CellStyle get titleStyle => CellStyle(
        backgroundColorHex: ExcelColor.fromHexString('#0F172A'),
        fontColorHex: ExcelColor.fromHexString('#FFFFFF'),
        bold: true,
        fontSize: 13,
        horizontalAlign: HorizontalAlign.Center,
        verticalAlign: VerticalAlign.Center,
      );

  /// Estilo para el Subtítulo Normativo ICA
  static CellStyle get subtitleStyle => CellStyle(
        backgroundColorHex: ExcelColor.fromHexString('#1E293B'),
        fontColorHex: ExcelColor.fromHexString('#38BDF8'),
        bold: true,
        fontSize: 11,
        horizontalAlign: HorizontalAlign.Center,
        verticalAlign: VerticalAlign.Center,
      );

  /// Estilo para datos del predio (Ficha Técnica)
  static CellStyle get metaLabelStyle => CellStyle(
        backgroundColorHex: ExcelColor.fromHexString('#F1F5F9'),
        fontColorHex: ExcelColor.fromHexString('#334155'),
        bold: true,
        fontSize: 10,
        horizontalAlign: HorizontalAlign.Left,
        verticalAlign: VerticalAlign.Center,
      );

  /// Estilo para Valores de Metadatos
  static CellStyle get metaValueStyle => CellStyle(
        backgroundColorHex: ExcelColor.fromHexString('#F8FAFC'),
        fontColorHex: ExcelColor.fromHexString('#0F172A'),
        bold: false,
        fontSize: 10,
        horizontalAlign: HorizontalAlign.Left,
        verticalAlign: VerticalAlign.Center,
      );

  /// Estilo para Tarjetas KPI (Título / Métrica)
  static CellStyle get kpiTitleStyle => CellStyle(
        backgroundColorHex: ExcelColor.fromHexString('#E2E8F0'),
        fontColorHex: ExcelColor.fromHexString('#475569'),
        bold: true,
        fontSize: 9,
        horizontalAlign: HorizontalAlign.Center,
        verticalAlign: VerticalAlign.Center,
      );

  static CellStyle get kpiValueStyle => CellStyle(
        backgroundColorHex: ExcelColor.fromHexString('#F8FAFC'),
        fontColorHex: ExcelColor.fromHexString('#0284C7'),
        bold: true,
        fontSize: 12,
        horizontalAlign: HorizontalAlign.Center,
        verticalAlign: VerticalAlign.Center,
      );

  /// Estilo para Encabezados de Tablas de Datos
  static CellStyle tableHeaderStyle({String hexColor = '#008B9E'}) => CellStyle(
        backgroundColorHex: ExcelColor.fromHexString(hexColor),
        fontColorHex: ExcelColor.fromHexString('#FFFFFF'),
        bold: true,
        fontSize: 10,
        horizontalAlign: HorizontalAlign.Center,
        verticalAlign: VerticalAlign.Center,
      );

  /// Estilo de Fila de Datos Normal (Izquierda)
  static CellStyle get cellLeft => CellStyle(
        backgroundColorHex: ExcelColor.fromHexString('#FFFFFF'),
        fontColorHex: ExcelColor.fromHexString('#0F172A'),
        fontSize: 10,
        horizontalAlign: HorizontalAlign.Left,
        verticalAlign: VerticalAlign.Center,
      );

  /// Estilo de Fila de Datos Normal (Centrado - Fechas / Códigos)
  static CellStyle get cellCenter => CellStyle(
        backgroundColorHex: ExcelColor.fromHexString('#FFFFFF'),
        fontColorHex: ExcelColor.fromHexString('#0F172A'),
        fontSize: 10,
        horizontalAlign: HorizontalAlign.Center,
        verticalAlign: VerticalAlign.Center,
      );

  /// Estilo de Fila de Datos Normal (Derecha - Números / Dinero)
  static CellStyle get cellRight => CellStyle(
        backgroundColorHex: ExcelColor.fromHexString('#FFFFFF'),
        fontColorHex: ExcelColor.fromHexString('#0F172A'),
        fontSize: 10,
        horizontalAlign: HorizontalAlign.Right,
        verticalAlign: VerticalAlign.Center,
      );

  /// Estilo de Fila Alternada Zebra (Gris muy claro)
  static CellStyle get cellZebraLeft => CellStyle(
        backgroundColorHex: ExcelColor.fromHexString('#F8FAFC'),
        fontColorHex: ExcelColor.fromHexString('#0F172A'),
        fontSize: 10,
        horizontalAlign: HorizontalAlign.Left,
        verticalAlign: VerticalAlign.Center,
      );

  static CellStyle get cellZebraCenter => CellStyle(
        backgroundColorHex: ExcelColor.fromHexString('#F8FAFC'),
        fontColorHex: ExcelColor.fromHexString('#0F172A'),
        fontSize: 10,
        horizontalAlign: HorizontalAlign.Center,
        verticalAlign: VerticalAlign.Center,
      );

  static CellStyle get cellZebraRight => CellStyle(
        backgroundColorHex: ExcelColor.fromHexString('#F8FAFC'),
        fontColorHex: ExcelColor.fromHexString('#0F172A'),
        fontSize: 10,
        horizontalAlign: HorizontalAlign.Right,
        verticalAlign: VerticalAlign.Center,
      );

  // ─── Estilos Semánticos de Estado (Colores con Significado) ──────────────────

  /// Estado Óptimo / Aprobado / Negativo a Patógeno (Verde Suave)
  static CellStyle get statusOptimalStyle => CellStyle(
        backgroundColorHex: ExcelColor.fromHexString('#D1FAE5'),
        fontColorHex: ExcelColor.fromHexString('#065F46'),
        bold: true,
        fontSize: 10,
        horizontalAlign: HorizontalAlign.Center,
        verticalAlign: VerticalAlign.Center,
      );

  /// Estado Advertencia / Precaución / Tiempo de Retiro (Ámbar Suave)
  static CellStyle get statusWarningStyle => CellStyle(
        backgroundColorHex: ExcelColor.fromHexString('#FEF3C7'),
        fontColorHex: ExcelColor.fromHexString('#92400E'),
        bold: true,
        fontSize: 10,
        horizontalAlign: HorizontalAlign.Center,
        verticalAlign: VerticalAlign.Center,
      );

  /// Estado Crítico / Hipoxia / Mortalidad Alta (Coral Suave)
  static CellStyle get statusCriticalStyle => CellStyle(
        backgroundColorHex: ExcelColor.fromHexString('#FFE4E6'),
        fontColorHex: ExcelColor.fromHexString('#9F1239'),
        bold: true,
        fontSize: 10,
        horizontalAlign: HorizontalAlign.Center,
        verticalAlign: VerticalAlign.Center,
      );

  /// Estilo de Fila de Totales Generales
  static CellStyle get totalLabelStyle => CellStyle(
        backgroundColorHex: ExcelColor.fromHexString('#E2E8F0'),
        fontColorHex: ExcelColor.fromHexString('#0F172A'),
        bold: true,
        fontSize: 10,
        horizontalAlign: HorizontalAlign.Right,
        verticalAlign: VerticalAlign.Center,
      );

  static CellStyle get totalValueStyle => CellStyle(
        backgroundColorHex: ExcelColor.fromHexString('#E2E8F0'),
        fontColorHex: ExcelColor.fromHexString('#047857'),
        bold: true,
        fontSize: 10,
        horizontalAlign: HorizontalAlign.Right,
        verticalAlign: VerticalAlign.Center,
      );

  // ─── Helpers para Construcción de Secciones ──────────────────────────────────

  /// Escribe el Encabezado Oficial Institucional ICA en la hoja con sello de trazabilidad
  static int writeOfficialHeader({
    required Sheet sheet,
    required String formatCode,
    required String formatTitle,
    required String companyName,
    required String nit,
    required String unitName,
    required int maxCols,
  }) {
    final now = DateTime.now();
    final dateStr = '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')} ${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';
    final safeCompany = companyName.trim().isEmpty ? 'Piscícola FishBit S.A.S' : companyName;

    // Fila 0: Cinta Superior de Marca FishBit + Trazabilidad
    var c0 = sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 0));
    c0.value = TextCellValue('🐟 FISHBIT PRECISION AQUACULTURE ERP  •  SISTEMA OFICIAL DE BIOSEGURIDAD Y REGISTRO ICA (RES. 20186 DE 2016)');
    c0.cellStyle = corporateBrandStyle;
    sheet.merge(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 0), CellIndex.indexByColumnRow(columnIndex: maxCols - 1, rowIndex: 0));

    // Fila 1: Título Institucional
    var c1 = sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 1));
    c1.value = TextCellValue('INSTITUTO COLOMBIANO AGROPECUARIO (ICA) - EXPEDIENTE TÉCNICO DE PREDIO ACUÍCOLA');
    c1.cellStyle = titleStyle;
    sheet.merge(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 1), CellIndex.indexByColumnRow(columnIndex: maxCols - 1, rowIndex: 1));

    // Fila 2: Subtítulo del Formato Oficial
    var c2 = sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 2));
    c2.value = TextCellValue('FORMATO OFICIAL $formatCode: ${formatTitle.toUpperCase()}');
    c2.cellStyle = subtitleStyle;
    sheet.merge(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 2), CellIndex.indexByColumnRow(columnIndex: maxCols - 1, rowIndex: 2));

    // Fila 3: Espacio
    sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 3)).value = TextCellValue('');

    // Fila 4 y 5: Ficha Técnica del Predio
    _setCell(sheet, 0, 4, 'EMPRESA / TITULAR:', metaLabelStyle);
    _setCell(sheet, 1, 4, safeCompany, metaValueStyle);
    _setCell(sheet, 2, 4, 'NIT / REGISTRO ICA:', metaLabelStyle);
    _setCell(sheet, 3, 4, nit.isEmpty ? 'REG-ICA-PREDIO-ACTIVO' : nit, metaValueStyle);

    _setCell(sheet, 0, 5, 'GRANJA / SEDE:', metaLabelStyle);
    _setCell(sheet, 1, 5, unitName, metaValueStyle);
    _setCell(sheet, 2, 5, 'FECHA/HORA EMISIÓN:', metaLabelStyle);
    _setCell(sheet, 3, 5, dateStr, metaValueStyle);

    // Fila 6: Espacio
    sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 6)).value = TextCellValue('');

    return 7; // Próxima fila disponible
  }

  /// Escribe el Bloque Oficial de Firmas y Validación Técnica al pie de página
  static void writeOfficialSignatureFooter({
    required Sheet sheet,
    required int startRow,
    required int maxCols,
    String responsablePredio = 'Administrador / Operador de Turno',
    String medicoVeterinario = 'Director Técnico / Médico Veterinario (M.V.)',
  }) {
    final int emptyRow = startRow + 2;
    sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: emptyRow)).value = TextCellValue('');

    final int signHeaderRow = emptyRow + 1;
    final int signLinesRow = signHeaderRow + 3;
    final int signLabelsRow = signLinesRow + 1;

    // Nota de Validez Legal
    final noteCell = sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: signHeaderRow));
    noteCell.value = TextCellValue('CONSTANCIA DE VALIDEZ Y AUDITORÍA: La presente información reposa en los registros oficiales digitales del predio y tiene validez probatoria ante visitas de inspección, vigilancia y control del ICA conforme a la Res. 20186/2016.');
    noteCell.cellStyle = CellStyle(
      fontColorHex: ExcelColor.fromHexString('#64748B'),
      italic: true,
      fontSize: 9,
      horizontalAlign: HorizontalAlign.Left,
      verticalAlign: VerticalAlign.Center,
    );
    sheet.merge(
      CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: signHeaderRow),
      CellIndex.indexByColumnRow(columnIndex: maxCols - 1, rowIndex: signHeaderRow),
    );

    // Líneas de Firma
    final int colMid = (maxCols / 2).floor();
    
    // Firma 1: Responsable del Predio
    _setCell(sheet, 0, signLinesRow, '___________________________________________', cellCenter);
    sheet.merge(
      CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: signLinesRow),
      CellIndex.indexByColumnRow(columnIndex: colMid - 1, rowIndex: signLinesRow),
    );
    _setCell(sheet, 0, signLabelsRow, 'FIRMA: $responsablePredio\nCédula / Cargo en Granja', cellCenter);
    sheet.merge(
      CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: signLabelsRow),
      CellIndex.indexByColumnRow(columnIndex: colMid - 1, rowIndex: signLabelsRow),
    );

    // Firma 2: Médico Veterinario / Director Técnico
    _setCell(sheet, colMid, signLinesRow, '___________________________________________', cellCenter);
    sheet.merge(
      CellIndex.indexByColumnRow(columnIndex: colMid, rowIndex: signLinesRow),
      CellIndex.indexByColumnRow(columnIndex: maxCols - 1, rowIndex: signLinesRow),
    );
    _setCell(sheet, colMid, signLabelsRow, 'FIRMA: $medicoVeterinario\nTarjeta Profesional COMVEZCOL', cellCenter);
    sheet.merge(
      CellIndex.indexByColumnRow(columnIndex: colMid, rowIndex: signLabelsRow),
      CellIndex.indexByColumnRow(columnIndex: maxCols - 1, rowIndex: signLabelsRow),
    );
  }

  /// Helper privado para escribir celdas de forma segura
  static void _setCell(Sheet sheet, int col, int row, String text, CellStyle style) {
    var c = sheet.cell(CellIndex.indexByColumnRow(columnIndex: col, rowIndex: row));
    c.value = TextCellValue(text);
    c.cellStyle = style;
  }
}
