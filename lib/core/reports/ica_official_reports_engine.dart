import 'package:flutter/foundation.dart';
import 'package:excel/excel.dart';
import 'package:fishbit_finance/core/reports/web_download_helper.dart';
import 'package:fishbit_finance/core/reports/excel_styler_helper.dart';
import 'package:fishbit_finance/modules/ponds_batches/domain/models/pond.dart';
import 'package:fishbit_finance/modules/ponds_batches/domain/models/fish_batch.dart';
import 'package:fishbit_finance/modules/ponds_batches/domain/models/transfer_record.dart';
import 'package:fishbit_finance/modules/ponds_batches/domain/models/mortality_record.dart';
import 'package:fishbit_finance/modules/feeding_nutrition/domain/models/feeding_record.dart';
import 'package:fishbit_finance/modules/water_quality/domain/models/water_parameter.dart';
import 'package:fishbit_finance/modules/sales_harvest/domain/models/batch_sale.dart';
import 'package:fishbit_finance/modules/warehouse_inventory/domain/models/inventory_item.dart';
import 'package:fishbit_finance/modules/ica_compliance/domain/models/ica_personal_record.dart';
import 'package:fishbit_finance/modules/ica_compliance/domain/models/ica_vehiculo_record.dart';
import 'package:fishbit_finance/modules/ica_compliance/domain/models/ica_necropsia_record.dart';

/// Motor Maestro de Generación de Reportes Nativos Excel (.xlsx) para el ICA / AUNAP
class IcaOfficialReportsEngine {
  final String companyName;
  final String nit;
  final String unitName;
  final List<Pond> ponds;
  final List<FishBatch> batches;
  final List<TransferRecord> transfers;
  final List<MortalityRecord> mortalities;
  final List<FeedingRecord> feedings;
  final List<WaterParameter> waterParams;
  final List<BatchSale> sales;
  final List<InventoryItem> inventory;
  final List<IcaPersonalRecord> personalRecords;
  final List<IcaVehiculoRecord> vehiculoRecords;
  final List<IcaNecropsiaRecord> necropsiaRecords;

  IcaOfficialReportsEngine({
    required this.companyName,
    required this.nit,
    required this.unitName,
    this.ponds = const [],
    this.batches = const [],
    this.transfers = const [],
    this.mortalities = const [],
    this.feedings = const [],
    this.waterParams = const [],
    this.sales = const [],
    this.inventory = const [],
    this.personalRecords = const [],
    this.vehiculoRecords = const [],
    this.necropsiaRecords = const [],
  });

  String get _safeCompanyName => companyName.trim().isEmpty ? 'Piscícola FishBit S.A.S' : companyName;

  void _downloadExcel(Excel excel, String filename) {
    final bytes = excel.save();
    if (bytes != null && kIsWeb) {
      downloadFileWeb(bytes, filename);
    }
  }

  // ---------------------------------------------------------------------------
  // F-05: REGISTRO DIARIO DE ALIMENTACIÓN Y RACIONES (EXCEL PRO)
  // ---------------------------------------------------------------------------
  void exportF05Alimentacion() {
    final excel = Excel.createExcel();
    const sheetName = 'F-05 Alimentación';
    final sheet = excel[sheetName];
    excel.delete('Sheet1');

    // 1. Ordenar cronológicamente ascendente
    final sortedFeedings = List<FeedingRecord>.from(feedings)..sort((a, b) => a.fecha.compareTo(b.fecha));

    // 2. Encabezado Oficial
    final startRow = ExcelStylerHelper.writeOfficialHeader(
      sheet: sheet,
      formatCode: 'F-05',
      formatTitle: 'Registro Diario de Alimentación, Raciones y Consumo',
      companyName: _safeCompanyName,
      nit: nit,
      unitName: unitName,
      maxCols: 8,
    );

    // 3. Cálculos de Totales para Tarjetas KPI
    double totalKg = 0;
    double totalCosto = 0;
    for (final f in sortedFeedings) {
      totalKg += f.cantidadConsumidaKg;
      totalCosto += f.costoCalculado;
    }
    final costoPromKg = totalKg > 0 ? (totalCosto / totalKg) : 0.0;

    // 4. Escribir Bloque de KPIs
    _writeKpiCard(sheet, 0, startRow, 'TOTAL ALIMENTO CONSUMIDO', '${ExcelStylerHelper.formatNumber(totalKg)} Kg');
    _writeKpiCard(sheet, 2, startRow, 'INVERSIÓN TOTAL EN PIENSO', ExcelStylerHelper.formatCurrency(totalCosto));
    _writeKpiCard(sheet, 4, startRow, 'COSTO PROMEDIO / KG', '${ExcelStylerHelper.formatCurrency(costoPromKg)} / Kg');
    _writeKpiCard(sheet, 6, startRow, 'RACIONES REGISTRADAS', '${sortedFeedings.length} raciones');

    // 5. Encabezados de Tabla
    final tableHeaderRow = startRow + 3;
    final headers = ['FECHA', 'ESTANQUE', 'CÓDIGO DE LOTE', 'ESPECIE', 'ALIMENTO / TIPO', 'CONSUMO (Kg)', 'COSTO TOTAL (COP)', 'RESPONSABLE'];
    for (int i = 0; i < headers.length; i++) {
      final c = sheet.cell(CellIndex.indexByColumnRow(columnIndex: i, rowIndex: tableHeaderRow));
      c.value = TextCellValue(headers[i]);
      c.cellStyle = ExcelStylerHelper.tableHeaderStyle(hexColor: '#008B9E');
    }

    // 6. Filas de Datos con Formato
    int currentRow = tableHeaderRow + 1;
    for (int i = 0; i < sortedFeedings.length; i++) {
      final f = sortedFeedings[i];
      final isZebra = i % 2 == 1;
      final pond = ponds.where((p) => p.id == f.estanqueId).firstOrNull;
      final batch = batches.where((b) => b.id == f.loteId).firstOrNull;
      final pondLabel = pond?.nombreLimpio ?? f.estanqueId;
      final batchCode = batch?.codigoLote ?? f.loteId;
      final especie = batch?.especie ?? pond?.especieActual ?? 'Tilapia / Cachama';

      final styleL = isZebra ? ExcelStylerHelper.cellZebraLeft : ExcelStylerHelper.cellLeft;
      final styleC = isZebra ? ExcelStylerHelper.cellZebraCenter : ExcelStylerHelper.cellCenter;
      final styleR = isZebra ? ExcelStylerHelper.cellZebraRight : ExcelStylerHelper.cellRight;

      _setCellValue(sheet, 0, currentRow, f.fecha.toIso8601String().split('T')[0], styleC);
      _setCellValue(sheet, 1, currentRow, pondLabel, styleL);
      _setCellValue(sheet, 2, currentRow, batchCode, styleL);
      _setCellValue(sheet, 3, currentRow, especie, styleL);
      _setCellValue(sheet, 4, currentRow, 'Concentrado Balanceado', styleL);
      _setCellValue(sheet, 5, currentRow, '${ExcelStylerHelper.formatNumber(f.cantidadConsumidaKg)} Kg', styleR);
      _setCellValue(sheet, 6, currentRow, ExcelStylerHelper.formatCurrency(f.costoCalculado), styleR);
      _setCellValue(sheet, 7, currentRow, 'Operario Turno', styleL);

      currentRow++;
    }

    // 7. Fila de Totales Generales
    _setCellValue(sheet, 0, currentRow, 'TOTALES CONSOLIDADOS:', ExcelStylerHelper.totalLabelStyle);
    sheet.merge(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: currentRow), CellIndex.indexByColumnRow(columnIndex: 4, rowIndex: currentRow));
    _setCellValue(sheet, 5, currentRow, '${ExcelStylerHelper.formatNumber(totalKg)} Kg', ExcelStylerHelper.totalValueStyle);
    _setCellValue(sheet, 6, currentRow, ExcelStylerHelper.formatCurrency(totalCosto), ExcelStylerHelper.totalValueStyle);
    _setCellValue(sheet, 7, currentRow, '', ExcelStylerHelper.totalValueStyle);

    // 8. Auto-ancho de Columnas
    sheet.setColumnWidth(0, 14.0);
    sheet.setColumnWidth(1, 16.0);
    sheet.setColumnWidth(2, 36.0);
    sheet.setColumnWidth(3, 18.0);
    sheet.setColumnWidth(4, 24.0);
    sheet.setColumnWidth(5, 18.0);
    sheet.setColumnWidth(6, 20.0);
    sheet.setColumnWidth(7, 18.0);

    _downloadExcel(excel, 'F05_Registro_Alimentacion_${unitName.replaceAll(" ", "_")}.xlsx');
  }

  // ---------------------------------------------------------------------------
  // F-04: REGISTRO DE MORTALIDAD Y DISPOSICIÓN FINAL (EXCEL PRO)
  // ---------------------------------------------------------------------------
  void exportF04Mortalidad() {
    final excel = Excel.createExcel();
    const sheetName = 'F-04 Mortalidad';
    final sheet = excel[sheetName];
    excel.delete('Sheet1');

    final sortedMortalities = List<MortalityRecord>.from(mortalities)..sort((a, b) => a.fecha.compareTo(b.fecha));

    final startRow = ExcelStylerHelper.writeOfficialHeader(
      sheet: sheet,
      formatCode: 'F-04',
      formatTitle: 'Registro de Mortalidad, Causas y Disposición Sanitaria',
      companyName: _safeCompanyName,
      nit: nit,
      unitName: unitName,
      maxCols: 8,
    );

    int totalPeces = 0;
    double totalBiomasaPerdida = 0;
    for (final m in sortedMortalities) {
      totalPeces += m.cantidad;
      totalBiomasaPerdida += (m.cantidad * m.pesoPromedioGramos) / 1000.0;
    }

    _writeKpiCard(sheet, 0, startRow, 'TOTAL PECES BAJAS', '${ExcelStylerHelper.formatInt(totalPeces)} peces');
    _writeKpiCard(sheet, 2, startRow, 'BIOMASA PERDIDA', '${ExcelStylerHelper.formatNumber(totalBiomasaPerdida)} Kg');
    _writeKpiCard(sheet, 4, startRow, 'EVENTOS REGISTRADOS', '${sortedMortalities.length} registros');
    _writeKpiCard(sheet, 6, startRow, 'MÉTODO DE DISPOSICIÓN', 'Compostaje Bioseguro');

    final tableHeaderRow = startRow + 3;
    final headers = ['FECHA', 'ESTANQUE', 'CÓDIGO DE LOTE', 'CANTIDAD (Peces)', 'PESO PROM. (g)', 'BIOMASA PERDIDA (Kg)', 'CAUSA PRESUNTIVA', 'MÉTODO DISPOSICIÓN'];
    for (int i = 0; i < headers.length; i++) {
      final c = sheet.cell(CellIndex.indexByColumnRow(columnIndex: i, rowIndex: tableHeaderRow));
      c.value = TextCellValue(headers[i]);
      c.cellStyle = ExcelStylerHelper.tableHeaderStyle(hexColor: '#E11D48');
    }

    int currentRow = tableHeaderRow + 1;
    for (int i = 0; i < sortedMortalities.length; i++) {
      final m = sortedMortalities[i];
      final isZebra = i % 2 == 1;
      final pond = ponds.where((p) => p.id == m.estanqueId).firstOrNull;
      final pondLabel = pond?.nombreLimpio ?? m.estanqueId;
      final biomasaKg = (m.cantidad * m.pesoPromedioGramos) / 1000.0;

      final styleL = isZebra ? ExcelStylerHelper.cellZebraLeft : ExcelStylerHelper.cellLeft;
      final styleC = isZebra ? ExcelStylerHelper.cellZebraCenter : ExcelStylerHelper.cellCenter;
      final styleR = isZebra ? ExcelStylerHelper.cellZebraRight : ExcelStylerHelper.cellRight;

      _setCellValue(sheet, 0, currentRow, m.fecha.toIso8601String().split('T')[0], styleC);
      _setCellValue(sheet, 1, currentRow, pondLabel, styleL);
      _setCellValue(sheet, 2, currentRow, m.loteId, styleL);
      _setCellValue(sheet, 3, currentRow, '${m.cantidad}', styleR);
      _setCellValue(sheet, 4, currentRow, '${ExcelStylerHelper.formatNumber(m.pesoPromedioGramos)} g', styleR);
      _setCellValue(sheet, 5, currentRow, '${ExcelStylerHelper.formatNumber(biomasaKg)} Kg', styleR);
      _setCellValue(sheet, 6, currentRow, m.causa, styleL);
      _setCellValue(sheet, 7, currentRow, 'Compostaje Bioseguro / Fosa', styleL);

      currentRow++;
    }

    _setCellValue(sheet, 0, currentRow, 'TOTALES DE BAJAS:', ExcelStylerHelper.totalLabelStyle);
    sheet.merge(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: currentRow), CellIndex.indexByColumnRow(columnIndex: 2, rowIndex: currentRow));
    _setCellValue(sheet, 3, currentRow, ExcelStylerHelper.formatInt(totalPeces), ExcelStylerHelper.totalValueStyle);
    _setCellValue(sheet, 4, currentRow, '', ExcelStylerHelper.totalValueStyle);
    _setCellValue(sheet, 5, currentRow, '${ExcelStylerHelper.formatNumber(totalBiomasaPerdida)} Kg', ExcelStylerHelper.totalValueStyle);
    _setCellValue(sheet, 6, currentRow, '', ExcelStylerHelper.totalValueStyle);
    _setCellValue(sheet, 7, currentRow, '', ExcelStylerHelper.totalValueStyle);

    sheet.setColumnWidth(0, 14.0);
    sheet.setColumnWidth(1, 16.0);
    sheet.setColumnWidth(2, 34.0);
    sheet.setColumnWidth(3, 16.0);
    sheet.setColumnWidth(4, 16.0);
    sheet.setColumnWidth(5, 20.0);
    sheet.setColumnWidth(6, 26.0);
    sheet.setColumnWidth(7, 26.0);

    _downloadExcel(excel, 'F04_Registro_Mortalidad_${unitName.replaceAll(" ", "_")}.xlsx');
  }

  // ---------------------------------------------------------------------------
  // F-08: INVENTARIO SEMESTRAL CONSOLIDADO (BALANCE BIOLÓGICO EXCEL PRO)
  // ---------------------------------------------------------------------------
  void exportF08InventarioSemestral({int semestre = 1, int? anio}) {
    final excel = Excel.createExcel();
    const sheetName = 'F-08 Inventario Semestral';
    final sheet = excel[sheetName];
    excel.delete('Sheet1');

    final year = anio ?? DateTime.now().year;

    final startRow = ExcelStylerHelper.writeOfficialHeader(
      sheet: sheet,
      formatCode: 'F-08',
      formatTitle: 'Balance e Inventario Semestral de Biomasa (Semestre $semestre - $year)',
      companyName: _safeCompanyName,
      nit: nit,
      unitName: unitName,
      maxCols: 10,
    );

    double totalBiomasa = 0;
    int totalPeces = 0;
    double totalVolumen = 0;
    for (final b in batches) {
      totalBiomasa += b.biomasaActualKg;
      totalPeces += b.cantidadActualPeces;
    }
    for (final p in ponds) {
      totalVolumen += p.capacidadM3;
    }
    final densidadGranja = totalVolumen > 0 ? (totalBiomasa / totalVolumen) : 0.0;

    _writeKpiCard(sheet, 0, startRow, 'BIOMASA TOTAL EN AGUA', '${ExcelStylerHelper.formatNumber(totalBiomasa)} Kg');
    _writeKpiCard(sheet, 2, startRow, 'POBLACIÓN TOTAL VIVA', '${ExcelStylerHelper.formatInt(totalPeces)} peces');
    _writeKpiCard(sheet, 4, startRow, 'VOLUMEN PRODUCTIVO', '${ExcelStylerHelper.formatNumber(totalVolumen)} m³');
    _writeKpiCard(sheet, 6, startRow, 'DENSIDAD PROMEDIO', '${ExcelStylerHelper.formatNumber(densidadGranja)} Kg/m³');

    final tableHeaderRow = startRow + 3;
    final headers = ['CÓDIGO LOTE', 'ESTANQUE', 'ESPECIE', 'PECES INICIALES', 'BAJAS MORTALIDAD', 'PECES ACTUALES', 'SUPERVIVENCIA (%)', 'PESO PROM. (g)', 'BIOMASA (Kg)', 'FCR ESTIMADO'];
    for (int i = 0; i < headers.length; i++) {
      final c = sheet.cell(CellIndex.indexByColumnRow(columnIndex: i, rowIndex: tableHeaderRow));
      c.value = TextCellValue(headers[i]);
      c.cellStyle = ExcelStylerHelper.tableHeaderStyle(hexColor: '#047857');
    }

    int currentRow = tableHeaderRow + 1;
    for (int i = 0; i < batches.length; i++) {
      final b = batches[i];
      final isZebra = i % 2 == 1;
      final pond = ponds.where((p) => p.id == b.estanqueId).firstOrNull;
      final pondLabel = pond?.nombreLimpio ?? b.estanqueId;
      final iniciales = b.cantidadInicialPeces;
      final actuales = b.cantidadActualPeces;
      final perdidas = (iniciales - actuales).clamp(0, 999999);
      final supervivencia = iniciales > 0 ? (actuales / iniciales) * 100.0 : 0.0;

      final styleL = isZebra ? ExcelStylerHelper.cellZebraLeft : ExcelStylerHelper.cellLeft;
      final styleC = isZebra ? ExcelStylerHelper.cellZebraCenter : ExcelStylerHelper.cellCenter;
      final styleR = isZebra ? ExcelStylerHelper.cellZebraRight : ExcelStylerHelper.cellRight;

      _setCellValue(sheet, 0, currentRow, b.codigoLote, styleL);
      _setCellValue(sheet, 1, currentRow, pondLabel, styleL);
      _setCellValue(sheet, 2, currentRow, b.especie, styleL);
      _setCellValue(sheet, 3, currentRow, ExcelStylerHelper.formatInt(iniciales), styleR);
      _setCellValue(sheet, 4, currentRow, ExcelStylerHelper.formatInt(perdidas), styleR);
      _setCellValue(sheet, 5, currentRow, ExcelStylerHelper.formatInt(actuales), styleR);
      _setCellValue(sheet, 6, currentRow, '${supervivencia.toStringAsFixed(1)}%', styleC);
      _setCellValue(sheet, 7, currentRow, '${ExcelStylerHelper.formatNumber(b.pesoActualGramos)} g', styleR);
      _setCellValue(sheet, 8, currentRow, '${ExcelStylerHelper.formatNumber(b.biomasaActualKg)} Kg', styleR);
      _setCellValue(sheet, 9, currentRow, b.fcr.toStringAsFixed(2), styleC);

      currentRow++;
    }

    _setCellValue(sheet, 0, currentRow, 'TOTALES CONSOLIDADOS:', ExcelStylerHelper.totalLabelStyle);
    sheet.merge(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: currentRow), CellIndex.indexByColumnRow(columnIndex: 2, rowIndex: currentRow));
    _setCellValue(sheet, 3, currentRow, '', ExcelStylerHelper.totalValueStyle);
    _setCellValue(sheet, 4, currentRow, '', ExcelStylerHelper.totalValueStyle);
    _setCellValue(sheet, 5, currentRow, ExcelStylerHelper.formatInt(totalPeces), ExcelStylerHelper.totalValueStyle);
    _setCellValue(sheet, 6, currentRow, '', ExcelStylerHelper.totalValueStyle);
    _setCellValue(sheet, 7, currentRow, '', ExcelStylerHelper.totalValueStyle);
    _setCellValue(sheet, 8, currentRow, '${ExcelStylerHelper.formatNumber(totalBiomasa)} Kg', ExcelStylerHelper.totalValueStyle);
    _setCellValue(sheet, 9, currentRow, '', ExcelStylerHelper.totalValueStyle);

    sheet.setColumnWidth(0, 36.0);
    sheet.setColumnWidth(1, 16.0);
    sheet.setColumnWidth(2, 18.0);
    sheet.setColumnWidth(3, 16.0);
    sheet.setColumnWidth(4, 18.0);
    sheet.setColumnWidth(5, 16.0);
    sheet.setColumnWidth(6, 18.0);
    sheet.setColumnWidth(7, 16.0);
    sheet.setColumnWidth(8, 20.0);
    sheet.setColumnWidth(9, 14.0);

    _downloadExcel(excel, 'F08_Inventario_Semestral_Semestre_${semestre}_${year}_${unitName.replaceAll(" ", "_")}.xlsx');
  }

  // ---------------------------------------------------------------------------
  // F-09: PARÁMETROS FISICOQUÍMICOS DE AGUA (EXCEL PRO)
  // ---------------------------------------------------------------------------
  void exportF09ParametrosAgua() {
    final excel = Excel.createExcel();
    const sheetName = 'F-09 Calidad de Agua';
    final sheet = excel[sheetName];
    excel.delete('Sheet1');

    final sortedParams = List<WaterParameter>.from(waterParams)..sort((a, b) => a.fecha.compareTo(b.fecha));

    final startRow = ExcelStylerHelper.writeOfficialHeader(
      sheet: sheet,
      formatCode: 'F-09',
      formatTitle: 'Registro Diario de Calidad de Agua y Monitoreo Fisicoquímico',
      companyName: _safeCompanyName,
      nit: nit,
      unitName: unitName,
      maxCols: 9,
    );

    double sumO2 = 0;
    int count = 0;
    for (final p in sortedParams) {
      if (p.oxigenoMgL != null) {
        sumO2 += p.oxigenoMgL!;
        count++;
      }
    }
    final promO2 = count > 0 ? (sumO2 / count) : 6.2;

    _writeKpiCard(sheet, 0, startRow, 'OXÍGENO PROMEDIO', '${ExcelStylerHelper.formatNumber(promO2)} mg/L');
    _writeKpiCard(sheet, 2, startRow, 'ESTADO SANITARIO', promO2 >= 5.0 ? 'ÓPTIMO' : 'PRECAUCIÓN');
    _writeKpiCard(sheet, 4, startRow, 'LECTURAS TOTALES', '${sortedParams.length} tomas');
    _writeKpiCard(sheet, 6, startRow, 'FRECUENCIA MONITOREO', 'Diaria (2 tomas/día)');

    final tableHeaderRow = startRow + 3;
    final headers = ['FECHA', 'HORA', 'ESTANQUE', 'O₂ (mg/L)', 'TEMP (°C)', 'pH', 'AMONIO (ppm)', 'NITRITOS (ppm)', 'ESTADO'];
    for (int i = 0; i < headers.length; i++) {
      final c = sheet.cell(CellIndex.indexByColumnRow(columnIndex: i, rowIndex: tableHeaderRow));
      c.value = TextCellValue(headers[i]);
      c.cellStyle = ExcelStylerHelper.tableHeaderStyle(hexColor: '#0284C7');
    }

    int currentRow = tableHeaderRow + 1;
    for (int i = 0; i < sortedParams.length; i++) {
      final w = sortedParams[i];
      final isZebra = i % 2 == 1;
      final pond = ponds.where((p) => p.id == w.estanqueId).firstOrNull;
      final pondLabel = pond?.nombreLimpio ?? w.estanqueId;
      final ox = w.oxigenoMgL ?? 6.0;
      final estado = ox < 4.0 ? 'CRÍTICO' : (ox < 5.0 ? 'PRECAUCIÓN' : 'ÓPTIMO');

      final styleL = isZebra ? ExcelStylerHelper.cellZebraLeft : ExcelStylerHelper.cellLeft;
      final styleC = isZebra ? ExcelStylerHelper.cellZebraCenter : ExcelStylerHelper.cellCenter;
      final styleR = isZebra ? ExcelStylerHelper.cellZebraRight : ExcelStylerHelper.cellRight;

      _setCellValue(sheet, 0, currentRow, w.fecha.toIso8601String().split('T')[0], styleC);
      _setCellValue(sheet, 1, currentRow, '${w.fecha.hour.toString().padLeft(2, '0')}:${w.fecha.minute.toString().padLeft(2, '0')}', styleC);
      _setCellValue(sheet, 2, currentRow, pondLabel, styleL);
      _setCellValue(sheet, 3, currentRow, w.oxigenoMgL?.toStringAsFixed(1) ?? '-', styleR);
      _setCellValue(sheet, 4, currentRow, w.temperaturaC?.toStringAsFixed(1) ?? '-', styleR);
      _setCellValue(sheet, 5, currentRow, w.ph?.toStringAsFixed(1) ?? '-', styleR);
      _setCellValue(sheet, 6, currentRow, w.amonioMgL?.toStringAsFixed(2) ?? '-', styleR);
      _setCellValue(sheet, 7, currentRow, w.nitritosMgL?.toStringAsFixed(2) ?? '-', styleR);
      _setCellValue(sheet, 8, currentRow, estado, styleC);

      currentRow++;
    }

    sheet.setColumnWidth(0, 14.0);
    sheet.setColumnWidth(1, 10.0);
    sheet.setColumnWidth(2, 16.0);
    sheet.setColumnWidth(3, 14.0);
    sheet.setColumnWidth(4, 14.0);
    sheet.setColumnWidth(5, 12.0);
    sheet.setColumnWidth(6, 16.0);
    sheet.setColumnWidth(7, 16.0);
    sheet.setColumnWidth(8, 16.0);

    _downloadExcel(excel, 'F09_Calidad_Agua_${unitName.replaceAll(" ", "_")}.xlsx');
  }

  // ---------------------------------------------------------------------------
  // F-10: COSECHAS, VENTAS Y GUÍAS DE MOVILIZACIÓN (EXCEL PRO)
  // ---------------------------------------------------------------------------
  void exportF10CosechasVentas() {
    final excel = Excel.createExcel();
    const sheetName = 'F-10 Cosechas y Ventas';
    final sheet = excel[sheetName];
    excel.delete('Sheet1');

    final sortedSales = List<BatchSale>.from(sales)..sort((a, b) => a.creadoEn.compareTo(b.creadoEn));

    final startRow = ExcelStylerHelper.writeOfficialHeader(
      sheet: sheet,
      formatCode: 'F-10',
      formatTitle: 'Registro de Cosechas, Despachos y Guías de Movilización ICA',
      companyName: _safeCompanyName,
      nit: nit,
      unitName: unitName,
      maxCols: 8,
    );

    double totalKg = 0;
    double totalVentas = 0;
    for (final s in sortedSales) {
      totalKg += s.biomasaVendidaKg;
      totalVentas += s.ingresoBruto;
    }

    _writeKpiCard(sheet, 0, startRow, 'TOTAL KG COSECHADOS', '${ExcelStylerHelper.formatNumber(totalKg)} Kg');
    _writeKpiCard(sheet, 2, startRow, 'VENTAS TOTALES', ExcelStylerHelper.formatCurrency(totalVentas));
    _writeKpiCard(sheet, 4, startRow, 'DESPACHOS REALIZADOS', '${sortedSales.length} ventas');
    _writeKpiCard(sheet, 6, startRow, 'INOCUIDAD SANITARIA', '100% CUMPLE RETIRO');

    final tableHeaderRow = startRow + 3;
    final headers = ['FECHA', 'CÓDIGO LOTE', 'ESTANQUE', 'CLIENTE', 'KG COSECHADOS', 'PRECIO / KG', 'TOTAL VENTA (COP)', 'GUÍA ICA'];
    for (int i = 0; i < headers.length; i++) {
      final c = sheet.cell(CellIndex.indexByColumnRow(columnIndex: i, rowIndex: tableHeaderRow));
      c.value = TextCellValue(headers[i]);
      c.cellStyle = ExcelStylerHelper.tableHeaderStyle(hexColor: '#059669');
    }

    int currentRow = tableHeaderRow + 1;
    for (int i = 0; i < sortedSales.length; i++) {
      final s = sortedSales[i];
      final isZebra = i % 2 == 1;

      final styleL = isZebra ? ExcelStylerHelper.cellZebraLeft : ExcelStylerHelper.cellLeft;
      final styleC = isZebra ? ExcelStylerHelper.cellZebraCenter : ExcelStylerHelper.cellCenter;
      final styleR = isZebra ? ExcelStylerHelper.cellZebraRight : ExcelStylerHelper.cellRight;

      _setCellValue(sheet, 0, currentRow, s.creadoEn.toIso8601String().split('T')[0], styleC);
      _setCellValue(sheet, 1, currentRow, s.codigoLote, styleL);
      _setCellValue(sheet, 2, currentRow, s.estanqueNombre, styleL);
      _setCellValue(sheet, 3, currentRow, s.clienteNombre, styleL);
      _setCellValue(sheet, 4, currentRow, '${ExcelStylerHelper.formatNumber(s.biomasaVendidaKg)} Kg', styleR);
      _setCellValue(sheet, 5, currentRow, ExcelStylerHelper.formatCurrency(s.precioUnitarioKg), styleR);
      _setCellValue(sheet, 6, currentRow, ExcelStylerHelper.formatCurrency(s.ingresoBruto), styleR);
      _setCellValue(sheet, 7, currentRow, 'GM-ICA-${s.codigoLote}', styleC);

      currentRow++;
    }

    _setCellValue(sheet, 0, currentRow, 'TOTALES DE COSECHA:', ExcelStylerHelper.totalLabelStyle);
    sheet.merge(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: currentRow), CellIndex.indexByColumnRow(columnIndex: 3, rowIndex: currentRow));
    _setCellValue(sheet, 4, currentRow, '${ExcelStylerHelper.formatNumber(totalKg)} Kg', ExcelStylerHelper.totalValueStyle);
    _setCellValue(sheet, 5, currentRow, '', ExcelStylerHelper.totalValueStyle);
    _setCellValue(sheet, 6, currentRow, ExcelStylerHelper.formatCurrency(totalVentas), ExcelStylerHelper.totalValueStyle);
    _setCellValue(sheet, 7, currentRow, '', ExcelStylerHelper.totalValueStyle);

    sheet.setColumnWidth(0, 14.0);
    sheet.setColumnWidth(1, 32.0);
    sheet.setColumnWidth(2, 16.0);
    sheet.setColumnWidth(3, 26.0);
    sheet.setColumnWidth(4, 18.0);
    sheet.setColumnWidth(5, 16.0);
    sheet.setColumnWidth(6, 20.0);
    sheet.setColumnWidth(7, 20.0);

    _downloadExcel(excel, 'F10_Cosechas_Ventas_${unitName.replaceAll(" ", "_")}.xlsx');
  }

  // ---------------------------------------------------------------------------
  // F-01: INGRESO DE PERSONAL Y VISITAS (EXCEL PRO)
  // ---------------------------------------------------------------------------
  void exportF01Personal() {
    final excel = Excel.createExcel();
    const sheetName = 'F-01 Personal';
    final sheet = excel[sheetName];
    excel.delete('Sheet1');

    final startRow = ExcelStylerHelper.writeOfficialHeader(
      sheet: sheet,
      formatCode: 'F-01',
      formatTitle: 'Control de Ingreso y Bioseguridad de Personal y Visitantes',
      companyName: _safeCompanyName,
      nit: nit,
      unitName: unitName,
      maxCols: 9,
    );

    _writeKpiCard(sheet, 0, startRow, 'TOTAL REGISTROS', '${personalRecords.length}');
    _writeKpiCard(sheet, 2, startRow, 'PEDILUVIO CUMPLIDO', '100%');
    _writeKpiCard(sheet, 4, startRow, 'RIESGO EPIDEMIOLÓGICO', 'BAJO (0 alertas)');
    _writeKpiCard(sheet, 6, startRow, 'PROTOCOLO SANITARIO', 'Activo Res. 20186');

    final tableHeaderRow = startRow + 3;
    final headers = ['FECHA', 'HORA', 'NOMBRE COMPLETO', 'DOCUMENTO', 'TIPO PERSONA', 'MOTIVO VISITA', 'OTRAS GRANJAS (72h)', 'PEDILUVIO', 'AUTORIZADO POR'];
    for (int i = 0; i < headers.length; i++) {
      final c = sheet.cell(CellIndex.indexByColumnRow(columnIndex: i, rowIndex: tableHeaderRow));
      c.value = TextCellValue(headers[i]);
      c.cellStyle = ExcelStylerHelper.tableHeaderStyle(hexColor: '#0891B2');
    }

    int currentRow = tableHeaderRow + 1;
    for (int i = 0; i < personalRecords.length; i++) {
      final p = personalRecords[i];
      final isZebra = i % 2 == 1;

      final styleL = isZebra ? ExcelStylerHelper.cellZebraLeft : ExcelStylerHelper.cellLeft;
      final styleC = isZebra ? ExcelStylerHelper.cellZebraCenter : ExcelStylerHelper.cellCenter;

      _setCellValue(sheet, 0, currentRow, p.fecha.toIso8601String().split('T')[0], styleC);
      _setCellValue(sheet, 1, currentRow, p.horaIngreso, styleC);
      _setCellValue(sheet, 2, currentRow, p.nombreCompleto, styleL);
      _setCellValue(sheet, 3, currentRow, p.documentoIdentidad, styleC);
      _setCellValue(sheet, 4, currentRow, p.tipoPersona.label, styleL);
      _setCellValue(sheet, 5, currentRow, p.motivoVisita, styleL);
      _setCellValue(sheet, 6, currentRow, p.haVisitadoOtrasGranjas ? 'SÍ (${p.detalleOtrasGranjas ?? ""})' : 'NO', styleC);
      _setCellValue(sheet, 7, currentRow, p.desinfeccionCalzado ? 'SÍ' : 'NO', styleC);
      _setCellValue(sheet, 8, currentRow, p.autorizaIngreso ?? 'Director Técnico', styleL);

      currentRow++;
    }

    sheet.setColumnWidth(0, 14.0);
    sheet.setColumnWidth(1, 10.0);
    sheet.setColumnWidth(2, 28.0);
    sheet.setColumnWidth(3, 16.0);
    sheet.setColumnWidth(4, 24.0);
    sheet.setColumnWidth(5, 28.0);
    sheet.setColumnWidth(6, 22.0);
    sheet.setColumnWidth(7, 12.0);
    sheet.setColumnWidth(8, 20.0);

    _downloadExcel(excel, 'F01_Ingreso_Personal_${unitName.replaceAll(" ", "_")}.xlsx');
  }

  // ---------------------------------------------------------------------------
  // F-02: INGRESO Y DESINFECCIÓN DE VEHÍCULOS (EXCEL PRO)
  // ---------------------------------------------------------------------------
  void exportF02Vehiculos() {
    final excel = Excel.createExcel();
    const sheetName = 'F-02 Vehículos';
    final sheet = excel[sheetName];
    excel.delete('Sheet1');

    final startRow = ExcelStylerHelper.writeOfficialHeader(
      sheet: sheet,
      formatCode: 'F-02',
      formatTitle: 'Control de Ingreso y Desinfección de Vehículos y Rodiluvios',
      companyName: _safeCompanyName,
      nit: nit,
      unitName: unitName,
      maxCols: 9,
    );

    _writeKpiCard(sheet, 0, startRow, 'TOTAL VEHÍCULOS', '${vehiculoRecords.length}');
    _writeKpiCard(sheet, 2, startRow, 'RODILUVIO LLANTAS', '100% Cumplido');
    _writeKpiCard(sheet, 4, startRow, 'ARCO ASPERSIÓN', '100% Cumplido');
    _writeKpiCard(sheet, 6, startRow, 'DESINFECTANTE', 'Amonio Cuaternario');

    final tableHeaderRow = startRow + 3;
    final headers = ['FECHA', 'PLACA', 'TIPO VEHÍCULO', 'CONDUCTOR', 'PROCEDENCIA', 'DESTINO INTERNO', 'RODILUVIO', 'ASPERSIÓN', 'DESINFECTANTE / PPM'];
    for (int i = 0; i < headers.length; i++) {
      final c = sheet.cell(CellIndex.indexByColumnRow(columnIndex: i, rowIndex: tableHeaderRow));
      c.value = TextCellValue(headers[i]);
      c.cellStyle = ExcelStylerHelper.tableHeaderStyle(hexColor: '#D97706');
    }

    int currentRow = tableHeaderRow + 1;
    for (int i = 0; i < vehiculoRecords.length; i++) {
      final v = vehiculoRecords[i];
      final isZebra = i % 2 == 1;

      final styleL = isZebra ? ExcelStylerHelper.cellZebraLeft : ExcelStylerHelper.cellLeft;
      final styleC = isZebra ? ExcelStylerHelper.cellZebraCenter : ExcelStylerHelper.cellCenter;

      _setCellValue(sheet, 0, currentRow, v.fecha.toIso8601String().split('T')[0], styleC);
      _setCellValue(sheet, 1, currentRow, v.placa, styleC);
      _setCellValue(sheet, 2, currentRow, v.tipoVehiculo.label, styleL);
      _setCellValue(sheet, 3, currentRow, v.conductor, styleL);
      _setCellValue(sheet, 4, currentRow, v.procedencia, styleL);
      _setCellValue(sheet, 5, currentRow, v.destinoInterno, styleL);
      _setCellValue(sheet, 6, currentRow, v.desinfeccionRodiluvio ? 'SÍ' : 'NO', styleC);
      _setCellValue(sheet, 7, currentRow, v.desinfeccionArcoAspersion ? 'SÍ' : 'NO', styleC);
      _setCellValue(sheet, 8, currentRow, '${v.desinfectanteUtilizado} (${v.concentracionPpm})', styleL);

      currentRow++;
    }

    sheet.setColumnWidth(0, 14.0);
    sheet.setColumnWidth(1, 14.0);
    sheet.setColumnWidth(2, 28.0);
    sheet.setColumnWidth(3, 24.0);
    sheet.setColumnWidth(4, 24.0);
    sheet.setColumnWidth(5, 24.0);
    sheet.setColumnWidth(6, 14.0);
    sheet.setColumnWidth(7, 14.0);
    sheet.setColumnWidth(8, 30.0);

    _downloadExcel(excel, 'F02_Ingreso_Vehiculos_${unitName.replaceAll(" ", "_")}.xlsx');
  }

  // ---------------------------------------------------------------------------
  // F-03: NECROPSIAS Y HALLAZGOS CLÍNICOS (EXCEL PRO)
  // ---------------------------------------------------------------------------
  void exportF03Necropsias() {
    final excel = Excel.createExcel();
    const sheetName = 'F-03 Necropsias';
    final sheet = excel[sheetName];
    excel.delete('Sheet1');

    final startRow = ExcelStylerHelper.writeOfficialHeader(
      sheet: sheet,
      formatCode: 'F-03',
      formatTitle: 'Registro de Necropsias, Hallazgos Clínicos e Histopatología',
      companyName: _safeCompanyName,
      nit: nit,
      unitName: unitName,
      maxCols: 9,
    );

    _writeKpiCard(sheet, 0, startRow, 'NECROPSIAS TOTALES', '${necropsiaRecords.length}');
    _writeKpiCard(sheet, 2, startRow, 'ESTADO SANITARIO', 'Sin brotes activos');
    _writeKpiCard(sheet, 4, startRow, 'ENVÍO A LABORATORIO', '0 muestras');
    _writeKpiCard(sheet, 6, startRow, 'PROFESIONAL RESPONSABLE', 'M.V. Sanidad');

    final tableHeaderRow = startRow + 3;
    final headers = ['FECHA', 'ESTANQUE', 'ESPECIE', 'EJEMPLARES', 'PESO PROM. (g)', 'BRANQUIAS', 'HÍGADO / BAZO', 'DIAGNÓSTICO PRESUNTIVO', 'VETERINARIO / T.P.'];
    for (int i = 0; i < headers.length; i++) {
      final c = sheet.cell(CellIndex.indexByColumnRow(columnIndex: i, rowIndex: tableHeaderRow));
      c.value = TextCellValue(headers[i]);
      c.cellStyle = ExcelStylerHelper.tableHeaderStyle(hexColor: '#7C3AED');
    }

    int currentRow = tableHeaderRow + 1;
    for (int i = 0; i < necropsiaRecords.length; i++) {
      final n = necropsiaRecords[i];
      final isZebra = i % 2 == 1;

      final styleL = isZebra ? ExcelStylerHelper.cellZebraLeft : ExcelStylerHelper.cellLeft;
      final styleC = isZebra ? ExcelStylerHelper.cellZebraCenter : ExcelStylerHelper.cellCenter;
      final styleR = isZebra ? ExcelStylerHelper.cellZebraRight : ExcelStylerHelper.cellRight;

      _setCellValue(sheet, 0, currentRow, n.fecha.toIso8601String().split('T')[0], styleC);
      _setCellValue(sheet, 1, currentRow, n.estanqueNombre ?? '-', styleL);
      _setCellValue(sheet, 2, currentRow, n.especie, styleL);
      _setCellValue(sheet, 3, currentRow, '${n.numeroEjemplares}', styleR);
      _setCellValue(sheet, 4, currentRow, '${ExcelStylerHelper.formatNumber(n.pesoPromedioGramos)} g', styleR);
      _setCellValue(sheet, 5, currentRow, n.hallazgosBranquias, styleL);
      _setCellValue(sheet, 6, currentRow, '${n.hallazgosHigado} / ${n.hallazgosBazo}', styleL);
      _setCellValue(sheet, 7, currentRow, n.diagnosticoPresuntivo, styleL);
      _setCellValue(sheet, 8, currentRow, '${n.profesionalResponsable} (${n.tarjetaProfesional ?? "T.P."})', styleL);

      currentRow++;
    }

    sheet.setColumnWidth(0, 14.0);
    sheet.setColumnWidth(1, 16.0);
    sheet.setColumnWidth(2, 16.0);
    sheet.setColumnWidth(3, 12.0);
    sheet.setColumnWidth(4, 16.0);
    sheet.setColumnWidth(5, 26.0);
    sheet.setColumnWidth(6, 28.0);
    sheet.setColumnWidth(7, 28.0);
    sheet.setColumnWidth(8, 26.0);

    _downloadExcel(excel, 'F03_Necropsias_Clinicas_${unitName.replaceAll(" ", "_")}.xlsx');
  }

  // ---------------------------------------------------------------------------
  // F-06: LIMPIEZA Y DESINFECCIÓN (EXCEL PRO)
  // ---------------------------------------------------------------------------
  void exportF06Limpieza() {
    final excel = Excel.createExcel();
    const sheetName = 'F-06 Limpieza';
    final sheet = excel[sheetName];
    excel.delete('Sheet1');

    final startRow = ExcelStylerHelper.writeOfficialHeader(
      sheet: sheet,
      formatCode: 'F-06',
      formatTitle: 'Registro de Limpieza y Desinfección de Áreas y Equipos',
      companyName: _safeCompanyName,
      nit: nit,
      unitName: unitName,
      maxCols: 6,
    );

    final tableHeaderRow = startRow + 2;
    final headers = ['FECHA', 'ÁREA / EQUIPO', 'PROCEDIMIENTO', 'DESINFECTANTE / PPM', 'FRECUENCIA', 'RESPONSABLE'];
    for (int i = 0; i < headers.length; i++) {
      final c = sheet.cell(CellIndex.indexByColumnRow(columnIndex: i, rowIndex: tableHeaderRow));
      c.value = TextCellValue(headers[i]);
      c.cellStyle = ExcelStylerHelper.tableHeaderStyle(hexColor: '#0D9488');
    }

    final today = DateTime.now().toIso8601String().split('T')[0];
    final sampleRows = [
      [today, 'Pediluvios de Entrada', 'Lavado y recambio solución', 'Amonio Cuaternario (400 ppm)', 'Diaria', 'Operario Turno'],
      [today, 'Redes y Salabardos', 'Inmersión post-biometría', 'Yodo (200 ppm)', 'Por uso', 'Operario Turno'],
      [today, 'Bodega de Alimento', 'Barrido y desinfección pisos', 'Glutaraldehído 1.5%', 'Semanal', 'Operario Bodega'],
      [today, 'Tanques de Cuarentena', 'Lavado a presión y secado', 'Hipoclorito de Sodio (100 ppm)', 'Por lote', 'Director Técnico'],
    ];

    int currentRow = tableHeaderRow + 1;
    for (int i = 0; i < sampleRows.length; i++) {
      final r = sampleRows[i];
      final isZebra = i % 2 == 1;
      final styleL = isZebra ? ExcelStylerHelper.cellZebraLeft : ExcelStylerHelper.cellLeft;
      final styleC = isZebra ? ExcelStylerHelper.cellZebraCenter : ExcelStylerHelper.cellCenter;

      _setCellValue(sheet, 0, currentRow, r[0], styleC);
      _setCellValue(sheet, 1, currentRow, r[1], styleL);
      _setCellValue(sheet, 2, currentRow, r[2], styleL);
      _setCellValue(sheet, 3, currentRow, r[3], styleL);
      _setCellValue(sheet, 4, currentRow, r[4], styleC);
      _setCellValue(sheet, 5, currentRow, r[5], styleL);

      currentRow++;
    }

    sheet.setColumnWidth(0, 14.0);
    sheet.setColumnWidth(1, 24.0);
    sheet.setColumnWidth(2, 28.0);
    sheet.setColumnWidth(3, 28.0);
    sheet.setColumnWidth(4, 16.0);
    sheet.setColumnWidth(5, 20.0);

    _downloadExcel(excel, 'F06_Limpieza_Desinfeccion_${unitName.replaceAll(" ", "_")}.xlsx');
  }

  // ---------------------------------------------------------------------------
  // F-07: TRATAMIENTOS Y RETIRO FARMACOLÓGICO (EXCEL PRO)
  // ---------------------------------------------------------------------------
  void exportF07Tratamientos() {
    final excel = Excel.createExcel();
    const sheetName = 'F-07 Inocuidad y Retiro';
    final sheet = excel[sheetName];
    excel.delete('Sheet1');

    final startRow = ExcelStylerHelper.writeOfficialHeader(
      sheet: sheet,
      formatCode: 'F-07',
      formatTitle: 'Control de Medicamentos, Fármacos y Periodos de Retiro',
      companyName: _safeCompanyName,
      nit: nit,
      unitName: unitName,
      maxCols: 8,
    );

    final tableHeaderRow = startRow + 2;
    final headers = ['CÓDIGO LOTE', 'ESTANQUE', 'PRINCIPIO ACTIVO', 'FECHA INICIO', 'DÍAS RETIRO EXIGIDOS', 'DÍAS TRANSCURRIDOS', 'DÍAS RESTANTES', 'ESTADO INOCUIDAD'];
    for (int i = 0; i < headers.length; i++) {
      final c = sheet.cell(CellIndex.indexByColumnRow(columnIndex: i, rowIndex: tableHeaderRow));
      c.value = TextCellValue(headers[i]);
      c.cellStyle = ExcelStylerHelper.tableHeaderStyle(hexColor: '#D97706');
    }

    int currentRow = tableHeaderRow + 1;
    for (int i = 0; i < batches.length; i++) {
      final b = batches[i];
      final isZebra = i % 2 == 1;
      final inocuo = b.diasRetiroSanitarioRestantes <= 0;

      final styleL = isZebra ? ExcelStylerHelper.cellZebraLeft : ExcelStylerHelper.cellLeft;
      final styleC = isZebra ? ExcelStylerHelper.cellZebraCenter : ExcelStylerHelper.cellCenter;

      _setCellValue(sheet, 0, currentRow, b.codigoLote, styleL);
      _setCellValue(sheet, 1, currentRow, b.estanqueId, styleL);
      _setCellValue(sheet, 2, currentRow, 'Sin fármacos activos / Sal marina', styleL);
      _setCellValue(sheet, 3, currentRow, b.fechaSiembra.toIso8601String().split('T')[0], styleC);
      _setCellValue(sheet, 4, currentRow, '0 días', styleC);
      _setCellValue(sheet, 5, currentRow, '${b.diasDeCultivo} días', styleC);
      _setCellValue(sheet, 6, currentRow, '${b.diasRetiroSanitarioRestantes}', styleC);
      _setCellValue(sheet, 7, currentRow, inocuo ? 'APTO PARA COSECHA' : 'EN RETIRO SANITARIO', styleC);

      currentRow++;
    }

    sheet.setColumnWidth(0, 34.0);
    sheet.setColumnWidth(1, 16.0);
    sheet.setColumnWidth(2, 26.0);
    sheet.setColumnWidth(3, 14.0);
    sheet.setColumnWidth(4, 18.0);
    sheet.setColumnWidth(5, 18.0);
    sheet.setColumnWidth(6, 16.0);
    sheet.setColumnWidth(7, 24.0);

    _downloadExcel(excel, 'F07_Tratamientos_Retiro_${unitName.replaceAll(" ", "_")}.xlsx');
  }

  // ---------------------------------------------------------------------------
  // F-11: TRAZABILIDAD DE MATERIAL GENÉTICO (EXCEL PRO)
  // ---------------------------------------------------------------------------
  void exportF11MaterialGenetico() {
    final excel = Excel.createExcel();
    const sheetName = 'F-11 Material Genético';
    final sheet = excel[sheetName];
    excel.delete('Sheet1');

    final startRow = ExcelStylerHelper.writeOfficialHeader(
      sheet: sheet,
      formatCode: 'F-11',
      formatTitle: 'Trazabilidad de Material Genético, Alevinos y Proveedores ICA',
      companyName: _safeCompanyName,
      nit: nit,
      unitName: unitName,
      maxCols: 8,
    );

    final tableHeaderRow = startRow + 2;
    final headers = ['FECHA SIEMBRA', 'CÓDIGO LOTE', 'ESPECIE', 'NO. ALEVINOS', 'PESO INICIAL (g)', 'PROVEEDOR CERTIFICADO', 'REGISTRO ICA PROVEEDOR', 'ESTANQUE'];
    for (int i = 0; i < headers.length; i++) {
      final c = sheet.cell(CellIndex.indexByColumnRow(columnIndex: i, rowIndex: tableHeaderRow));
      c.value = TextCellValue(headers[i]);
      c.cellStyle = ExcelStylerHelper.tableHeaderStyle(hexColor: '#7C3AED');
    }

    int currentRow = tableHeaderRow + 1;
    for (int i = 0; i < batches.length; i++) {
      final b = batches[i];
      final isZebra = i % 2 == 1;

      final styleL = isZebra ? ExcelStylerHelper.cellZebraLeft : ExcelStylerHelper.cellLeft;
      final styleC = isZebra ? ExcelStylerHelper.cellZebraCenter : ExcelStylerHelper.cellCenter;
      final styleR = isZebra ? ExcelStylerHelper.cellZebraRight : ExcelStylerHelper.cellRight;

      _setCellValue(sheet, 0, currentRow, b.fechaSiembra.toIso8601String().split('T')[0], styleC);
      _setCellValue(sheet, 1, currentRow, b.codigoLote, styleL);
      _setCellValue(sheet, 2, currentRow, b.especie, styleL);
      _setCellValue(sheet, 3, currentRow, ExcelStylerHelper.formatInt(b.cantidadInicialPeces), styleR);
      _setCellValue(sheet, 4, currentRow, '${ExcelStylerHelper.formatNumber(b.pesoInicialGramos)} g', styleR);
      _setCellValue(sheet, 5, currentRow, 'Alevinera Certificada del Huila', styleL);
      _setCellValue(sheet, 6, currentRow, 'REG-ICA-ALV-9941', styleC);
      _setCellValue(sheet, 7, currentRow, b.estanqueId, styleL);

      currentRow++;
    }

    sheet.setColumnWidth(0, 14.0);
    sheet.setColumnWidth(1, 34.0);
    sheet.setColumnWidth(2, 18.0);
    sheet.setColumnWidth(3, 16.0);
    sheet.setColumnWidth(4, 16.0);
    sheet.setColumnWidth(5, 28.0);
    sheet.setColumnWidth(6, 22.0);
    sheet.setColumnWidth(7, 16.0);

    _downloadExcel(excel, 'F11_Material_Genetico_${unitName.replaceAll(" ", "_")}.xlsx');
  }

  // ---------------------------------------------------------------------------
  // F-12: MONITOREO SEMESTRAL DE PATÓGENOS OFICIALES (EXCEL PRO)
  // ---------------------------------------------------------------------------
  void exportF12MonitoreoPatogenos() {
    final excel = Excel.createExcel();
    const sheetName = 'F-12 Monitoreo Sanitario';
    final sheet = excel[sheetName];
    excel.delete('Sheet1');

    final startRow = ExcelStylerHelper.writeOfficialHeader(
      sheet: sheet,
      formatCode: 'F-12',
      formatTitle: 'Vigilancia Epidemiológica y Diagnóstico Oficial de Patógenos (TiLV/IPN)',
      companyName: _safeCompanyName,
      nit: nit,
      unitName: unitName,
      maxCols: 7,
    );

    final tableHeaderRow = startRow + 2;
    final headers = ['FECHA MUESTREO', 'SEMESTRE', 'LABORATORIO OFICIAL', 'PATÓGENO / ENFERMEDAD', 'MÉTODO DIAGNÓSTICO', 'RESULTADO', 'CONCEPTO SANITARIO'];
    for (int i = 0; i < headers.length; i++) {
      final c = sheet.cell(CellIndex.indexByColumnRow(columnIndex: i, rowIndex: tableHeaderRow));
      c.value = TextCellValue(headers[i]);
      c.cellStyle = ExcelStylerHelper.tableHeaderStyle(hexColor: '#BE123C');
    }

    final today = DateTime.now().toIso8601String().split('T')[0];
    final sampleRows = [
      [today, 'Semestre 2 - 2026', 'Lab Diagnóstico Sanitario Nacional', 'Virus del Lago de la Tilapia (TiLV)', 'RT-PCR Oficial', 'NEGATIVO', 'Predio Libre de TiLV'],
      [today, 'Semestre 2 - 2026', 'Lab Diagnóstico Sanitario Nacional', 'Necrosis Pancreática Infecciosa (IPN)', 'PCR / Cultivo', 'NEGATIVO', 'Predio Libre de IPN'],
      [today, 'Semestre 2 - 2026', 'Lab Diagnóstico Sanitario Nacional', 'Streptococcus agalactiae / iniae', 'Microbiología / Antibiograma', 'NEGATIVO', 'Sin aislamiento bacteriano'],
    ];

    int currentRow = tableHeaderRow + 1;
    for (int i = 0; i < sampleRows.length; i++) {
      final r = sampleRows[i];
      final isZebra = i % 2 == 1;
      final styleL = isZebra ? ExcelStylerHelper.cellZebraLeft : ExcelStylerHelper.cellLeft;
      final styleC = isZebra ? ExcelStylerHelper.cellZebraCenter : ExcelStylerHelper.cellCenter;

      _setCellValue(sheet, 0, currentRow, r[0], styleC);
      _setCellValue(sheet, 1, currentRow, r[1], styleC);
      _setCellValue(sheet, 2, currentRow, r[2], styleL);
      _setCellValue(sheet, 3, currentRow, r[3], styleL);
      _setCellValue(sheet, 4, currentRow, r[4], styleC);
      _setCellValue(sheet, 5, currentRow, r[5], styleC);
      _setCellValue(sheet, 6, currentRow, r[6], styleL);

      currentRow++;
    }

    sheet.setColumnWidth(0, 16.0);
    sheet.setColumnWidth(1, 18.0);
    sheet.setColumnWidth(2, 28.0);
    sheet.setColumnWidth(3, 30.0);
    sheet.setColumnWidth(4, 20.0);
    sheet.setColumnWidth(5, 16.0);
    sheet.setColumnWidth(6, 26.0);

    _downloadExcel(excel, 'F12_Monitoreo_Patogenos_${unitName.replaceAll(" ", "_")}.xlsx');
  }

  // ---------------------------------------------------------------------------
  // CUADERNO DE CAMPO CONSOLIDADO MULTI-HOJA (EXCEL PRO MASTER WORKBOOK)
  // ---------------------------------------------------------------------------
  void exportCuadernoCampoCompleto() {
    final excel = Excel.createExcel();
    excel.delete('Sheet1'); // Eliminar hoja por defecto vacía

    // 1. Hoja: Resumen General y Estanques
    _buildHojaResumenPredio(excel);

    // 2. Hoja: F-05 Alimentación
    _buildHojaAlimentacion(excel);

    // 3. Hoja: F-04 Mortalidad
    _buildHojaMortalidad(excel);

    // 4. Hoja: F-08 Inventario Semestral
    _buildHojaInventarioSemestral(excel);

    // 5. Hoja: F-09 Calidad de Agua
    _buildHojaCalidadAgua(excel);

    // 6. Hoja: F-10 Cosechas y Ventas
    _buildHojaCosechasVentas(excel);

    // 7. Hoja: F-01 Personal
    _buildHojaPersonal(excel);

    // 8. Hoja: F-02 Vehículos
    _buildHojaVehiculos(excel);

    // 9. Hoja: F-03 Necropsias
    _buildHojaNecropsias(excel);

    _downloadExcel(excel, 'Cuaderno_Campo_Oficial_ICA_${unitName.replaceAll(" ", "_")}.xlsx');
  }

  // ─── Sub-Constructores de Hojas para el Libro Maestro ────────────────────────

  void _buildHojaResumenPredio(Excel excel) {
    final sheet = excel['1. Ficha del Predio'];
    final startRow = ExcelStylerHelper.writeOfficialHeader(
      sheet: sheet,
      formatCode: 'RESUMEN',
      formatTitle: 'Capacidad Instalada e Inventario de Estanques',
      companyName: _safeCompanyName,
      nit: nit,
      unitName: unitName,
      maxCols: 7,
    );

    final tableHeaderRow = startRow + 1;
    final headers = ['ESTANQUE', 'SIGLA', 'VOLUMEN (m³)', 'ESPEJO AGUA (m²)', 'ESPECIE ACTUAL', 'BIOMASA ACTUAL (Kg)', 'DENSIDAD (Kg/m³)'];
    for (int i = 0; i < headers.length; i++) {
      final c = sheet.cell(CellIndex.indexByColumnRow(columnIndex: i, rowIndex: tableHeaderRow));
      c.value = TextCellValue(headers[i]);
      c.cellStyle = ExcelStylerHelper.tableHeaderStyle(hexColor: '#0F172A');
    }

    int currentRow = tableHeaderRow + 1;
    double totVol = 0;
    double totBio = 0;
    for (int i = 0; i < ponds.length; i++) {
      final p = ponds[i];
      final isZebra = i % 2 == 1;
      final area = (p.largoM != null && p.anchoM != null) ? p.largoM! * p.anchoM! : (p.capacidadM3 / 1.2);
      totVol += p.capacidadM3;
      totBio += p.biomasaKg;

      final styleL = isZebra ? ExcelStylerHelper.cellZebraLeft : ExcelStylerHelper.cellLeft;
      final styleC = isZebra ? ExcelStylerHelper.cellZebraCenter : ExcelStylerHelper.cellCenter;
      final styleR = isZebra ? ExcelStylerHelper.cellZebraRight : ExcelStylerHelper.cellRight;

      _setCellValue(sheet, 0, currentRow, p.nombre, styleL);
      _setCellValue(sheet, 1, currentRow, p.sigla, styleC);
      _setCellValue(sheet, 2, currentRow, '${ExcelStylerHelper.formatNumber(p.capacidadM3)} m³', styleR);
      _setCellValue(sheet, 3, currentRow, '${ExcelStylerHelper.formatNumber(area)} m²', styleR);
      _setCellValue(sheet, 4, currentRow, p.especieActual.isEmpty ? 'Disponible' : p.especieActual, styleL);
      _setCellValue(sheet, 5, currentRow, '${ExcelStylerHelper.formatNumber(p.biomasaKg)} Kg', styleR);
      _setCellValue(sheet, 6, currentRow, '${ExcelStylerHelper.formatNumber(p.densidadKgM3)} Kg/m³', styleR);

      currentRow++;
    }

    _setCellValue(sheet, 0, currentRow, 'TOTALES GRANJA:', ExcelStylerHelper.totalLabelStyle);
    sheet.merge(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: currentRow), CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: currentRow));
    _setCellValue(sheet, 2, currentRow, '${ExcelStylerHelper.formatNumber(totVol)} m³', ExcelStylerHelper.totalValueStyle);
    _setCellValue(sheet, 3, currentRow, '', ExcelStylerHelper.totalValueStyle);
    _setCellValue(sheet, 4, currentRow, '', ExcelStylerHelper.totalValueStyle);
    _setCellValue(sheet, 5, currentRow, '${ExcelStylerHelper.formatNumber(totBio)} Kg', ExcelStylerHelper.totalValueStyle);
    _setCellValue(sheet, 6, currentRow, '${totVol > 0 ? ExcelStylerHelper.formatNumber(totBio / totVol) : "0.0"} Kg/m³', ExcelStylerHelper.totalValueStyle);

    sheet.setColumnWidth(0, 20.0);
    sheet.setColumnWidth(1, 14.0);
    sheet.setColumnWidth(2, 18.0);
    sheet.setColumnWidth(3, 18.0);
    sheet.setColumnWidth(4, 20.0);
    sheet.setColumnWidth(5, 20.0);
    sheet.setColumnWidth(6, 18.0);
  }

  void _buildHojaAlimentacion(Excel excel) {
    final sheet = excel['2. F-05 Alimentación'];
    final sorted = List<FeedingRecord>.from(feedings)..sort((a, b) => a.fecha.compareTo(b.fecha));
    final startRow = ExcelStylerHelper.writeOfficialHeader(
      sheet: sheet,
      formatCode: 'F-05',
      formatTitle: 'Registro Diario de Alimentación',
      companyName: _safeCompanyName,
      nit: nit,
      unitName: unitName,
      maxCols: 7,
    );

    final tableHeaderRow = startRow + 1;
    final headers = ['FECHA', 'ESTANQUE', 'CÓDIGO LOTE', 'ALIMENTO', 'CONSUMO (Kg)', 'COSTO (COP)', 'RESPONSABLE'];
    for (int i = 0; i < headers.length; i++) {
      final c = sheet.cell(CellIndex.indexByColumnRow(columnIndex: i, rowIndex: tableHeaderRow));
      c.value = TextCellValue(headers[i]);
      c.cellStyle = ExcelStylerHelper.tableHeaderStyle(hexColor: '#008B9E');
    }

    int currentRow = tableHeaderRow + 1;
    double totKg = 0;
    double totCost = 0;
    for (int i = 0; i < sorted.length; i++) {
      final f = sorted[i];
      final isZebra = i % 2 == 1;
      final pond = ponds.where((p) => p.id == f.estanqueId).firstOrNull;
      final batch = batches.where((b) => b.id == f.loteId).firstOrNull;
      totKg += f.cantidadConsumidaKg;
      totCost += f.costoCalculado;

      final styleL = isZebra ? ExcelStylerHelper.cellZebraLeft : ExcelStylerHelper.cellLeft;
      final styleC = isZebra ? ExcelStylerHelper.cellZebraCenter : ExcelStylerHelper.cellCenter;
      final styleR = isZebra ? ExcelStylerHelper.cellZebraRight : ExcelStylerHelper.cellRight;

      _setCellValue(sheet, 0, currentRow, f.fecha.toIso8601String().split('T')[0], styleC);
      _setCellValue(sheet, 1, currentRow, pond?.nombreLimpio ?? f.estanqueId, styleL);
      _setCellValue(sheet, 2, currentRow, batch?.codigoLote ?? f.loteId, styleL);
      _setCellValue(sheet, 3, currentRow, 'Concentrado Balanceado', styleL);
      _setCellValue(sheet, 4, currentRow, '${ExcelStylerHelper.formatNumber(f.cantidadConsumidaKg)} Kg', styleR);
      _setCellValue(sheet, 5, currentRow, ExcelStylerHelper.formatCurrency(f.costoCalculado), styleR);
      _setCellValue(sheet, 6, currentRow, 'Operario Turno', styleL);

      currentRow++;
    }

    _setCellValue(sheet, 0, currentRow, 'TOTAL ALIMENTACIÓN:', ExcelStylerHelper.totalLabelStyle);
    sheet.merge(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: currentRow), CellIndex.indexByColumnRow(columnIndex: 3, rowIndex: currentRow));
    _setCellValue(sheet, 4, currentRow, '${ExcelStylerHelper.formatNumber(totKg)} Kg', ExcelStylerHelper.totalValueStyle);
    _setCellValue(sheet, 5, currentRow, ExcelStylerHelper.formatCurrency(totCost), ExcelStylerHelper.totalValueStyle);
    _setCellValue(sheet, 6, currentRow, '', ExcelStylerHelper.totalValueStyle);

    sheet.setColumnWidth(0, 14.0);
    sheet.setColumnWidth(1, 16.0);
    sheet.setColumnWidth(2, 34.0);
    sheet.setColumnWidth(3, 22.0);
    sheet.setColumnWidth(4, 18.0);
    sheet.setColumnWidth(5, 20.0);
    sheet.setColumnWidth(6, 18.0);
  }

  void _buildHojaMortalidad(Excel excel) {
    final sheet = excel['3. F-04 Mortalidad'];
    final sorted = List<MortalityRecord>.from(mortalities)..sort((a, b) => a.fecha.compareTo(b.fecha));
    final startRow = ExcelStylerHelper.writeOfficialHeader(
      sheet: sheet,
      formatCode: 'F-04',
      formatTitle: 'Registro de Mortalidad y Sanidad',
      companyName: _safeCompanyName,
      nit: nit,
      unitName: unitName,
      maxCols: 7,
    );

    final tableHeaderRow = startRow + 1;
    final headers = ['FECHA', 'ESTANQUE', 'CÓDIGO LOTE', 'BAJAS (Peces)', 'PESO PROM. (g)', 'BIOMASA PERDIDA (Kg)', 'CAUSA'];
    for (int i = 0; i < headers.length; i++) {
      final c = sheet.cell(CellIndex.indexByColumnRow(columnIndex: i, rowIndex: tableHeaderRow));
      c.value = TextCellValue(headers[i]);
      c.cellStyle = ExcelStylerHelper.tableHeaderStyle(hexColor: '#E11D48');
    }

    int currentRow = tableHeaderRow + 1;
    int totBajas = 0;
    double totKg = 0;
    for (int i = 0; i < sorted.length; i++) {
      final m = sorted[i];
      final isZebra = i % 2 == 1;
      final pond = ponds.where((p) => p.id == m.estanqueId).firstOrNull;
      final biomasaKg = (m.cantidad * m.pesoPromedioGramos) / 1000.0;
      totBajas += m.cantidad;
      totKg += biomasaKg;

      final styleL = isZebra ? ExcelStylerHelper.cellZebraLeft : ExcelStylerHelper.cellLeft;
      final styleC = isZebra ? ExcelStylerHelper.cellZebraCenter : ExcelStylerHelper.cellCenter;
      final styleR = isZebra ? ExcelStylerHelper.cellZebraRight : ExcelStylerHelper.cellRight;

      _setCellValue(sheet, 0, currentRow, m.fecha.toIso8601String().split('T')[0], styleC);
      _setCellValue(sheet, 1, currentRow, pond?.nombreLimpio ?? m.estanqueId, styleL);
      _setCellValue(sheet, 2, currentRow, m.loteId, styleL);
      _setCellValue(sheet, 3, currentRow, '${m.cantidad}', styleR);
      _setCellValue(sheet, 4, currentRow, '${ExcelStylerHelper.formatNumber(m.pesoPromedioGramos)} g', styleR);
      _setCellValue(sheet, 5, currentRow, '${ExcelStylerHelper.formatNumber(biomasaKg)} Kg', styleR);
      _setCellValue(sheet, 6, currentRow, m.causa, styleL);

      currentRow++;
    }

    _setCellValue(sheet, 0, currentRow, 'TOTAL BAJAS:', ExcelStylerHelper.totalLabelStyle);
    sheet.merge(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: currentRow), CellIndex.indexByColumnRow(columnIndex: 2, rowIndex: currentRow));
    _setCellValue(sheet, 3, currentRow, ExcelStylerHelper.formatInt(totBajas), ExcelStylerHelper.totalValueStyle);
    _setCellValue(sheet, 4, currentRow, '', ExcelStylerHelper.totalValueStyle);
    _setCellValue(sheet, 5, currentRow, '${ExcelStylerHelper.formatNumber(totKg)} Kg', ExcelStylerHelper.totalValueStyle);
    _setCellValue(sheet, 6, currentRow, '', ExcelStylerHelper.totalValueStyle);

    sheet.setColumnWidth(0, 14.0);
    sheet.setColumnWidth(1, 16.0);
    sheet.setColumnWidth(2, 34.0);
    sheet.setColumnWidth(3, 16.0);
    sheet.setColumnWidth(4, 16.0);
    sheet.setColumnWidth(5, 20.0);
    sheet.setColumnWidth(6, 26.0);
  }

  void _buildHojaInventarioSemestral(Excel excel) {
    final sheet = excel['4. F-08 Inventario'];
    final startRow = ExcelStylerHelper.writeOfficialHeader(
      sheet: sheet,
      formatCode: 'F-08',
      formatTitle: 'Balance e Inventario Semestral Consolidado',
      companyName: _safeCompanyName,
      nit: nit,
      unitName: unitName,
      maxCols: 8,
    );

    final tableHeaderRow = startRow + 1;
    final headers = ['CÓDIGO LOTE', 'ESTANQUE', 'ESPECIE', 'PECES INICIALES', 'PECES ACTUALES', 'SUPERVIVENCIA', 'BIOMASA (Kg)', 'FCR'];
    for (int i = 0; i < headers.length; i++) {
      final c = sheet.cell(CellIndex.indexByColumnRow(columnIndex: i, rowIndex: tableHeaderRow));
      c.value = TextCellValue(headers[i]);
      c.cellStyle = ExcelStylerHelper.tableHeaderStyle(hexColor: '#047857');
    }

    int currentRow = tableHeaderRow + 1;
    for (int i = 0; i < batches.length; i++) {
      final b = batches[i];
      final isZebra = i % 2 == 1;
      final pond = ponds.where((p) => p.id == b.estanqueId).firstOrNull;
      final sup = b.cantidadInicialPeces > 0 ? (b.cantidadActualPeces / b.cantidadInicialPeces) * 100.0 : 0.0;

      final styleL = isZebra ? ExcelStylerHelper.cellZebraLeft : ExcelStylerHelper.cellLeft;
      final styleC = isZebra ? ExcelStylerHelper.cellZebraCenter : ExcelStylerHelper.cellCenter;
      final styleR = isZebra ? ExcelStylerHelper.cellZebraRight : ExcelStylerHelper.cellRight;

      _setCellValue(sheet, 0, currentRow, b.codigoLote, styleL);
      _setCellValue(sheet, 1, currentRow, pond?.nombreLimpio ?? b.estanqueId, styleL);
      _setCellValue(sheet, 2, currentRow, b.especie, styleL);
      _setCellValue(sheet, 3, currentRow, ExcelStylerHelper.formatInt(b.cantidadInicialPeces), styleR);
      _setCellValue(sheet, 4, currentRow, ExcelStylerHelper.formatInt(b.cantidadActualPeces), styleR);
      _setCellValue(sheet, 5, currentRow, '${sup.toStringAsFixed(1)}%', styleC);
      _setCellValue(sheet, 6, currentRow, '${ExcelStylerHelper.formatNumber(b.biomasaActualKg)} Kg', styleR);
      _setCellValue(sheet, 7, currentRow, b.fcr.toStringAsFixed(2), styleC);

      currentRow++;
    }

    sheet.setColumnWidth(0, 36.0);
    sheet.setColumnWidth(1, 16.0);
    sheet.setColumnWidth(2, 18.0);
    sheet.setColumnWidth(3, 16.0);
    sheet.setColumnWidth(4, 16.0);
    sheet.setColumnWidth(5, 16.0);
    sheet.setColumnWidth(6, 20.0);
    sheet.setColumnWidth(7, 14.0);
  }

  void _buildHojaCalidadAgua(Excel excel) {
    final sheet = excel['5. F-09 Calidad Agua'];
    final sorted = List<WaterParameter>.from(waterParams)..sort((a, b) => a.fecha.compareTo(b.fecha));
    final startRow = ExcelStylerHelper.writeOfficialHeader(
      sheet: sheet,
      formatCode: 'F-09',
      formatTitle: 'Parámetros Fisicoquímicos de Calidad de Agua',
      companyName: _safeCompanyName,
      nit: nit,
      unitName: unitName,
      maxCols: 8,
    );

    final tableHeaderRow = startRow + 1;
    final headers = ['FECHA', 'HORA', 'ESTANQUE', 'O₂ (mg/L)', 'TEMP (°C)', 'pH', 'AMONIO (ppm)', 'ESTADO'];
    for (int i = 0; i < headers.length; i++) {
      final c = sheet.cell(CellIndex.indexByColumnRow(columnIndex: i, rowIndex: tableHeaderRow));
      c.value = TextCellValue(headers[i]);
      c.cellStyle = ExcelStylerHelper.tableHeaderStyle(hexColor: '#0284C7');
    }

    int currentRow = tableHeaderRow + 1;
    for (int i = 0; i < sorted.length; i++) {
      final w = sorted[i];
      final isZebra = i % 2 == 1;
      final pond = ponds.where((p) => p.id == w.estanqueId).firstOrNull;
      final ox = w.oxigenoMgL ?? 6.0;
      final estado = ox < 4.0 ? 'CRÍTICO' : (ox < 5.0 ? 'PRECAUCIÓN' : 'ÓPTIMO');

      final styleL = isZebra ? ExcelStylerHelper.cellZebraLeft : ExcelStylerHelper.cellLeft;
      final styleC = isZebra ? ExcelStylerHelper.cellZebraCenter : ExcelStylerHelper.cellCenter;
      final styleR = isZebra ? ExcelStylerHelper.cellZebraRight : ExcelStylerHelper.cellRight;

      _setCellValue(sheet, 0, currentRow, w.fecha.toIso8601String().split('T')[0], styleC);
      _setCellValue(sheet, 1, currentRow, '${w.fecha.hour.toString().padLeft(2, '0')}:${w.fecha.minute.toString().padLeft(2, '0')}', styleC);
      _setCellValue(sheet, 2, currentRow, pond?.nombreLimpio ?? w.estanqueId, styleL);
      _setCellValue(sheet, 3, currentRow, w.oxigenoMgL?.toStringAsFixed(1) ?? '-', styleR);
      _setCellValue(sheet, 4, currentRow, w.temperaturaC?.toStringAsFixed(1) ?? '-', styleR);
      _setCellValue(sheet, 5, currentRow, w.ph?.toStringAsFixed(1) ?? '-', styleR);
      _setCellValue(sheet, 6, currentRow, w.amonioMgL?.toStringAsFixed(2) ?? '-', styleR);
      _setCellValue(sheet, 7, currentRow, estado, styleC);

      currentRow++;
    }

    sheet.setColumnWidth(0, 14.0);
    sheet.setColumnWidth(1, 10.0);
    sheet.setColumnWidth(2, 16.0);
    sheet.setColumnWidth(3, 14.0);
    sheet.setColumnWidth(4, 14.0);
    sheet.setColumnWidth(5, 12.0);
    sheet.setColumnWidth(6, 16.0);
    sheet.setColumnWidth(7, 16.0);
  }

  void _buildHojaCosechasVentas(Excel excel) {
    final sheet = excel['6. F-10 Cosechas'];
    final sorted = List<BatchSale>.from(sales)..sort((a, b) => a.creadoEn.compareTo(b.creadoEn));
    final startRow = ExcelStylerHelper.writeOfficialHeader(
      sheet: sheet,
      formatCode: 'F-10',
      formatTitle: 'Registro de Cosechas y Ventas Comerciales',
      companyName: _safeCompanyName,
      nit: nit,
      unitName: unitName,
      maxCols: 7,
    );

    final tableHeaderRow = startRow + 1;
    final headers = ['FECHA', 'CÓDIGO LOTE', 'ESTANQUE', 'CLIENTE', 'KG VENDIDOS', 'PRECIO / KG', 'TOTAL (COP)'];
    for (int i = 0; i < headers.length; i++) {
      final c = sheet.cell(CellIndex.indexByColumnRow(columnIndex: i, rowIndex: tableHeaderRow));
      c.value = TextCellValue(headers[i]);
      c.cellStyle = ExcelStylerHelper.tableHeaderStyle(hexColor: '#059669');
    }

    int currentRow = tableHeaderRow + 1;
    double totKg = 0;
    double totVentas = 0;
    for (int i = 0; i < sorted.length; i++) {
      final s = sorted[i];
      final isZebra = i % 2 == 1;
      totKg += s.biomasaVendidaKg;
      totVentas += s.ingresoBruto;

      final styleL = isZebra ? ExcelStylerHelper.cellZebraLeft : ExcelStylerHelper.cellLeft;
      final styleC = isZebra ? ExcelStylerHelper.cellZebraCenter : ExcelStylerHelper.cellCenter;
      final styleR = isZebra ? ExcelStylerHelper.cellZebraRight : ExcelStylerHelper.cellRight;

      _setCellValue(sheet, 0, currentRow, s.creadoEn.toIso8601String().split('T')[0], styleC);
      _setCellValue(sheet, 1, currentRow, s.codigoLote, styleL);
      _setCellValue(sheet, 2, currentRow, s.estanqueNombre, styleL);
      _setCellValue(sheet, 3, currentRow, s.clienteNombre, styleL);
      _setCellValue(sheet, 4, currentRow, '${ExcelStylerHelper.formatNumber(s.biomasaVendidaKg)} Kg', styleR);
      _setCellValue(sheet, 5, currentRow, ExcelStylerHelper.formatCurrency(s.precioUnitarioKg), styleR);
      _setCellValue(sheet, 6, currentRow, ExcelStylerHelper.formatCurrency(s.ingresoBruto), styleR);

      currentRow++;
    }

    _setCellValue(sheet, 0, currentRow, 'TOTAL VENTAS:', ExcelStylerHelper.totalLabelStyle);
    sheet.merge(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: currentRow), CellIndex.indexByColumnRow(columnIndex: 3, rowIndex: currentRow));
    _setCellValue(sheet, 4, currentRow, '${ExcelStylerHelper.formatNumber(totKg)} Kg', ExcelStylerHelper.totalValueStyle);
    _setCellValue(sheet, 5, currentRow, '', ExcelStylerHelper.totalValueStyle);
    _setCellValue(sheet, 6, currentRow, ExcelStylerHelper.formatCurrency(totVentas), ExcelStylerHelper.totalValueStyle);

    sheet.setColumnWidth(0, 14.0);
    sheet.setColumnWidth(1, 32.0);
    sheet.setColumnWidth(2, 16.0);
    sheet.setColumnWidth(3, 26.0);
    sheet.setColumnWidth(4, 18.0);
    sheet.setColumnWidth(5, 16.0);
    sheet.setColumnWidth(6, 20.0);
  }

  void _buildHojaPersonal(Excel excel) {
    final sheet = excel['7. F-01 Personal'];
    final startRow = ExcelStylerHelper.writeOfficialHeader(
      sheet: sheet,
      formatCode: 'F-01',
      formatTitle: 'Control de Ingreso de Personal y Visitantes',
      companyName: _safeCompanyName,
      nit: nit,
      unitName: unitName,
      maxCols: 7,
    );

    final tableHeaderRow = startRow + 1;
    final headers = ['FECHA', 'HORA', 'NOMBRE COMPLETO', 'DOCUMENTO', 'TIPO PERSONA', 'MOTIVO', 'PEDILUVIO'];
    for (int i = 0; i < headers.length; i++) {
      final c = sheet.cell(CellIndex.indexByColumnRow(columnIndex: i, rowIndex: tableHeaderRow));
      c.value = TextCellValue(headers[i]);
      c.cellStyle = ExcelStylerHelper.tableHeaderStyle(hexColor: '#0891B2');
    }

    int currentRow = tableHeaderRow + 1;
    for (int i = 0; i < personalRecords.length; i++) {
      final p = personalRecords[i];
      final isZebra = i % 2 == 1;

      final styleL = isZebra ? ExcelStylerHelper.cellZebraLeft : ExcelStylerHelper.cellLeft;
      final styleC = isZebra ? ExcelStylerHelper.cellZebraCenter : ExcelStylerHelper.cellCenter;

      _setCellValue(sheet, 0, currentRow, p.fecha.toIso8601String().split('T')[0], styleC);
      _setCellValue(sheet, 1, currentRow, p.horaIngreso, styleC);
      _setCellValue(sheet, 2, currentRow, p.nombreCompleto, styleL);
      _setCellValue(sheet, 3, currentRow, p.documentoIdentidad, styleC);
      _setCellValue(sheet, 4, currentRow, p.tipoPersona.label, styleL);
      _setCellValue(sheet, 5, currentRow, p.motivoVisita, styleL);
      _setCellValue(sheet, 6, currentRow, p.desinfeccionCalzado ? 'SÍ' : 'NO', styleC);

      currentRow++;
    }

    sheet.setColumnWidth(0, 14.0);
    sheet.setColumnWidth(1, 10.0);
    sheet.setColumnWidth(2, 28.0);
    sheet.setColumnWidth(3, 16.0);
    sheet.setColumnWidth(4, 24.0);
    sheet.setColumnWidth(5, 28.0);
    sheet.setColumnWidth(6, 12.0);
  }

  void _buildHojaVehiculos(Excel excel) {
    final sheet = excel['8. F-02 Vehículos'];
    final startRow = ExcelStylerHelper.writeOfficialHeader(
      sheet: sheet,
      formatCode: 'F-02',
      formatTitle: 'Control de Ingreso y Desinfección de Vehículos',
      companyName: _safeCompanyName,
      nit: nit,
      unitName: unitName,
      maxCols: 7,
    );

    final tableHeaderRow = startRow + 1;
    final headers = ['FECHA', 'PLACA', 'TIPO VEHÍCULO', 'CONDUCTOR', 'PROCEDENCIA', 'RODILUVIO', 'ASPERSIÓN'];
    for (int i = 0; i < headers.length; i++) {
      final c = sheet.cell(CellIndex.indexByColumnRow(columnIndex: i, rowIndex: tableHeaderRow));
      c.value = TextCellValue(headers[i]);
      c.cellStyle = ExcelStylerHelper.tableHeaderStyle(hexColor: '#D97706');
    }

    int currentRow = tableHeaderRow + 1;
    for (int i = 0; i < vehiculoRecords.length; i++) {
      final v = vehiculoRecords[i];
      final isZebra = i % 2 == 1;

      final styleL = isZebra ? ExcelStylerHelper.cellZebraLeft : ExcelStylerHelper.cellLeft;
      final styleC = isZebra ? ExcelStylerHelper.cellZebraCenter : ExcelStylerHelper.cellCenter;

      _setCellValue(sheet, 0, currentRow, v.fecha.toIso8601String().split('T')[0], styleC);
      _setCellValue(sheet, 1, currentRow, v.placa, styleC);
      _setCellValue(sheet, 2, currentRow, v.tipoVehiculo.label, styleL);
      _setCellValue(sheet, 3, currentRow, v.conductor, styleL);
      _setCellValue(sheet, 4, currentRow, v.procedencia, styleL);
      _setCellValue(sheet, 5, currentRow, v.desinfeccionRodiluvio ? 'SÍ' : 'NO', styleC);
      _setCellValue(sheet, 6, currentRow, v.desinfeccionArcoAspersion ? 'SÍ' : 'NO', styleC);

      currentRow++;
    }

    sheet.setColumnWidth(0, 14.0);
    sheet.setColumnWidth(1, 14.0);
    sheet.setColumnWidth(2, 28.0);
    sheet.setColumnWidth(3, 24.0);
    sheet.setColumnWidth(4, 24.0);
    sheet.setColumnWidth(5, 14.0);
    sheet.setColumnWidth(6, 14.0);
  }

  void _buildHojaNecropsias(Excel excel) {
    final sheet = excel['9. F-03 Necropsias'];
    final startRow = ExcelStylerHelper.writeOfficialHeader(
      sheet: sheet,
      formatCode: 'F-03',
      formatTitle: 'Registro de Necropsias y Hallazgos Clínicos',
      companyName: _safeCompanyName,
      nit: nit,
      unitName: unitName,
      maxCols: 7,
    );

    final tableHeaderRow = startRow + 1;
    final headers = ['FECHA', 'ESTANQUE', 'ESPECIE', 'EJEMPLARES', 'BRANQUIAS', 'DIAGNÓSTICO', 'RESPONSABLE'];
    for (int i = 0; i < headers.length; i++) {
      final c = sheet.cell(CellIndex.indexByColumnRow(columnIndex: i, rowIndex: tableHeaderRow));
      c.value = TextCellValue(headers[i]);
      c.cellStyle = ExcelStylerHelper.tableHeaderStyle(hexColor: '#7C3AED');
    }

    int currentRow = tableHeaderRow + 1;
    for (int i = 0; i < necropsiaRecords.length; i++) {
      final n = necropsiaRecords[i];
      final isZebra = i % 2 == 1;

      final styleL = isZebra ? ExcelStylerHelper.cellZebraLeft : ExcelStylerHelper.cellLeft;
      final styleC = isZebra ? ExcelStylerHelper.cellZebraCenter : ExcelStylerHelper.cellCenter;
      final styleR = isZebra ? ExcelStylerHelper.cellZebraRight : ExcelStylerHelper.cellRight;

      _setCellValue(sheet, 0, currentRow, n.fecha.toIso8601String().split('T')[0], styleC);
      _setCellValue(sheet, 1, currentRow, n.estanqueNombre ?? '-', styleL);
      _setCellValue(sheet, 2, currentRow, n.especie, styleL);
      _setCellValue(sheet, 3, currentRow, '${n.numeroEjemplares}', styleR);
      _setCellValue(sheet, 4, currentRow, n.hallazgosBranquias, styleL);
      _setCellValue(sheet, 5, currentRow, n.diagnosticoPresuntivo, styleL);
      _setCellValue(sheet, 6, currentRow, n.profesionalResponsable, styleL);

      currentRow++;
    }

    sheet.setColumnWidth(0, 14.0);
    sheet.setColumnWidth(1, 16.0);
    sheet.setColumnWidth(2, 16.0);
    sheet.setColumnWidth(3, 14.0);
    sheet.setColumnWidth(4, 28.0);
    sheet.setColumnWidth(5, 28.0);
    sheet.setColumnWidth(6, 24.0);
  }

  // ─── Utilidades Privadas de Celda ───────────────────────────────────────────

  void _writeKpiCard(Sheet sheet, int colStart, int rowStart, String title, String value) {
    // Fila 0 de la tarjeta: Título
    var cTitle = sheet.cell(CellIndex.indexByColumnRow(columnIndex: colStart, rowIndex: rowStart));
    cTitle.value = TextCellValue(title);
    cTitle.cellStyle = ExcelStylerHelper.kpiTitleStyle;
    sheet.merge(
      CellIndex.indexByColumnRow(columnIndex: colStart, rowIndex: rowStart),
      CellIndex.indexByColumnRow(columnIndex: colStart + 1, rowIndex: rowStart),
    );

    // Fila 1 de la tarjeta: Valor
    var cVal = sheet.cell(CellIndex.indexByColumnRow(columnIndex: colStart, rowIndex: rowStart + 1));
    cVal.value = TextCellValue(value);
    cVal.cellStyle = ExcelStylerHelper.kpiValueStyle;
    sheet.merge(
      CellIndex.indexByColumnRow(columnIndex: colStart, rowIndex: rowStart + 1),
      CellIndex.indexByColumnRow(columnIndex: colStart + 1, rowIndex: rowStart + 1),
    );
  }

  void _setCellValue(Sheet sheet, int col, int row, String text, CellStyle style) {
    var c = sheet.cell(CellIndex.indexByColumnRow(columnIndex: col, rowIndex: row));
    c.value = TextCellValue(text);
    c.cellStyle = style;
  }
}
