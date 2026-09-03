import 'package:excel/excel.dart';
import 'package:intl/intl.dart';

/// Utilidad centralizada para diseño visual, jerarquía y formato de reportes Excel (.xlsx)
class ExcelStylerHelper {
  static final _currencyFmt = NumberFormat.currency(locale: 'es_CO', symbol: '\$', decimalDigits: 0);
  static final _numberFmt = NumberFormat('#,##0.0', 'es_CO');
  static final _intFmt = NumberFormat('#,##0', 'es_CO');

  static String formatCurrency(double amount) => _currencyFmt.format(amount);
  static String formatNumber(double value) => _numberFmt.format(value);
  static String formatInt(int value) => _intFmt.format(value);

  // ─── Estilos de Celdas ──────────────────────────────────────────────────────

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
        fontColorHex: ExcelColor.fromHexString('#00E5FF'),
        bold: true,
        fontSize: 11,
        horizontalAlign: HorizontalAlign.Center,
        verticalAlign: VerticalAlign.Center,
      );

  /// Estilo para datos del predio (Ficha Técnica)
  static CellStyle get metaLabelStyle => CellStyle(
        backgroundColorHex: ExcelColor.fromHexString('#F8FAFC'),
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
        backgroundColorHex: ExcelColor.fromHexString('#F1F5F9'),
        fontColorHex: ExcelColor.fromHexString('#008B9E'),
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

  /// Escribe el Encabezado Oficial Institucional ICA en la hoja
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
    final dateStr = '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
    final safeCompany = companyName.trim().isEmpty ? 'Piscícola FishBit S.A.S' : companyName;

    // Fila 0: Banner Principal
    var c0 = sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 0));
    c0.value = TextCellValue('INSTITUTO COLOMBIANO AGROPECUARIO (ICA) - SISTEMA OFICIAL DE BIOSEGURIDAD ACUÍCOLA');
    c0.cellStyle = titleStyle;
    sheet.merge(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 0), CellIndex.indexByColumnRow(columnIndex: maxCols - 1, rowIndex: 0));

    // Fila 1: Título del Formato
    var c1 = sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 1));
    c1.value = TextCellValue('FORMATO OFICIAL $formatCode: ${formatTitle.toUpperCase()} (RES. ICA 20186 DE 2016)');
    c1.cellStyle = subtitleStyle;
    sheet.merge(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 1), CellIndex.indexByColumnRow(columnIndex: maxCols - 1, rowIndex: 1));

    // Fila 2: Espacio
    sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 2)).value = TextCellValue('');

    // Fila 3 y 4: Ficha del Predio
    _setCell(sheet, 0, 3, 'EMPRESA / TITULAR:', metaLabelStyle);
    _setCell(sheet, 1, 3, safeCompany, metaValueStyle);
    _setCell(sheet, 2, 3, 'NIT:', metaLabelStyle);
    _setCell(sheet, 3, 3, nit, metaValueStyle);

    _setCell(sheet, 0, 4, 'GRANJA / SEDE:', metaLabelStyle);
    _setCell(sheet, 1, 4, unitName, metaValueStyle);
    _setCell(sheet, 2, 4, 'FECHA EMISIÓN:', metaLabelStyle);
    _setCell(sheet, 3, 4, dateStr, metaValueStyle);

    // Fila 5: Espacio
    sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 5)).value = TextCellValue('');

    return 6; // Próxima fila disponible
  }

  /// Helper privado para escribir celdas de forma segura
  static void _setCell(Sheet sheet, int col, int row, String text, CellStyle style) {
    var c = sheet.cell(CellIndex.indexByColumnRow(columnIndex: col, rowIndex: row));
    c.value = TextCellValue(text);
    c.cellStyle = style;
  }
}
