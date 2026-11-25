import 'package:flutter_test/flutter_test.dart';
import 'package:fishbit_finance/modules/ponds_batches/domain/models/fish_batch.dart';

void main() {
  group('FishBatch biological balance (traslados vs mortalidad)', () {
    test('desdoble parcial con 0 bajas mantiene 0.0% mortalidad y 100.0% supervivencia', () {
      final parentBatch = FishBatch(
        id: 'parent-1',
        empresaId: 'emp-1',
        unidadAcuicolaId: 'unit-1',
        estanqueId: 'pond-1',
        codigoLote: 'LOT-E01-20261118-TILAPIAROJA',
        especie: 'Tilapia Roja',
        cantidadInicialPeces: 20000,
        cantidadActualPeces: 10200,
        mortalidadAcumuladaPeces: 0,
        pecesTrasladadosSalientes: 9800,
        pecesCosechados: 0,
        fechaSiembra: DateTime(2026, 11, 18),
        creadoEn: DateTime(2026, 11, 18),
      );

      final childBatch = FishBatch(
        id: 'child-1',
        empresaId: 'emp-1',
        unidadAcuicolaId: 'unit-1',
        estanqueId: 'pond-2',
        lotePadreId: 'parent-1',
        codigoLote: 'LOT-E01-20261118-TILAPIAROJA-B',
        especie: 'Tilapia Roja',
        cantidadInicialPeces: 9800,
        cantidadActualPeces: 9800,
        mortalidadAcumuladaPeces: 0,
        pecesTrasladadosSalientes: 0,
        pecesCosechados: 0,
        fechaSiembra: DateTime(2026, 11, 18),
        creadoEn: DateTime(2026, 11, 18),
      );

      expect(parentBatch.poblacionBaseNeta, 10200);
      expect(parentBatch.totalBajasMortalidad, 0);
      expect(parentBatch.porcentajeMortalidad, 0.0);
      expect(parentBatch.supervivenciaPct, 100.0);

      expect(childBatch.poblacionBaseNeta, 9800);
      expect(childBatch.porcentajeMortalidad, 0.0);
      expect(childBatch.supervivenciaPct, 100.0);

      // Consolidado granja: sin doble conteo de los 9,800 peces desdoblados
      final totalBase = parentBatch.poblacionBaseNeta + childBatch.poblacionBaseNeta;
      final totalBajas = parentBatch.mortalidadAcumuladaPeces + childBatch.mortalidadAcumuladaPeces;
      expect(totalBase, 20000);
      expect(totalBajas, 0);
    });

    test('bajas reales y cosechas parciales se calculan independientemente', () {
      final batch = FishBatch(
        id: 'batch-2',
        empresaId: 'emp-1',
        unidadAcuicolaId: 'unit-1',
        estanqueId: 'pond-1',
        codigoLote: 'LOT-TEST-02',
        especie: 'Tilapia Roja',
        cantidadInicialPeces: 10000,
        cantidadActualPeces: 6800,
        mortalidadAcumuladaPeces: 200,
        pecesTrasladadosSalientes: 0,
        pecesCosechados: 3000,
        fechaSiembra: DateTime(2026, 10, 1),
        creadoEn: DateTime(2026, 10, 1),
      );

      expect(batch.poblacionBaseNeta, 10000);
      expect(batch.totalBajasMortalidad, 200);
      expect(batch.porcentajeMortalidad, closeTo(2.0, 0.01));
      expect(batch.supervivenciaPct, closeTo(98.0, 0.01));
    });
  });
}
