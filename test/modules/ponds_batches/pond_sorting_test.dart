import 'package:flutter_test/flutter_test.dart';
import 'package:fishbit_finance/modules/ponds_batches/domain/models/pond.dart';

void main() {
  Pond makePond({
    required String id,
    required String nombre,
    required String sigla,
    DateTime? creadoEn,
  }) {
    return Pond(
      id: id,
      empresaId: 'emp-1',
      unidadAcuicolaId: 'unit-1',
      nombre: nombre,
      sigla: sigla,
      capacidadM3: 500,
      creadoEn: creadoEn ?? DateTime(2026, 1, 1),
    );
  }

  group('Pond.compareByNumber (ordenamiento numérico natural)', () {
    test('ordena correctamente casos reales donde Estanque 02 tiene sigla E-01 y fue creado antes que ESTANQUE 01', () {
      final ponds = [
        makePond(
          id: 'p-2',
          nombre: 'Estanque 02',
          sigla: 'E-01',
          creadoEn: DateTime(2026, 11, 19, 3, 2, 26),
        ),
        makePond(
          id: 'p-3',
          nombre: 'ESTANQUE 3',
          sigla: 'E03',
          creadoEn: DateTime(2026, 11, 19, 3, 39, 11),
        ),
        makePond(
          id: 'p-1',
          nombre: 'ESTANQUE 01',
          sigla: 'E01',
          creadoEn: DateTime(2026, 11, 19, 3, 13, 17),
        ),
      ]..sort(Pond.compareByNumber);

      expect(ponds.map((p) => p.id).toList(), ['p-1', 'p-2', 'p-3']);
    });

    test('ordena numéricamente 1..22 sin orden lexicográfico (10 después de 9, no después de 1)', () {
      final ponds = [
        makePond(id: '10', nombre: 'EST - ESTANQUE 10', sigla: 'ESTANQUE10-PISC'),
        makePond(id: '2', nombre: 'EST - ESTANQUE 2', sigla: 'ESTANQUE2-PISC'),
        makePond(id: 'salacuna', nombre: 'EST - Salacuna', sigla: 'EST-Salacuna-PISC'),
        makePond(id: '22', nombre: 'EST - ESTANQUE 22', sigla: 'ESTANQUE22-PISC'),
        makePond(id: '1', nombre: 'EST - ESTANQUE 1', sigla: 'ESTANQUE1-PISC'),
        makePond(id: '9', nombre: 'EST - ESTANQUE 9', sigla: 'ESTANQUE9-PISC'),
        makePond(id: 'almacen', nombre: 'EST - Almacenamiento', sigla: 'EST-ALM'),
      ]..sort(Pond.compareByNumber);

      expect(
        ponds.map((p) => p.id).toList(),
        ['1', '2', '9', '10', '22', 'almacen', 'salacuna'],
      );
    });

    test('usa la sigla como respaldo cuando el nombre no tiene dígitos', () {
      final ponds = [
        makePond(id: 'b', nombre: 'Estanque Norte', sigla: 'E-05'),
        makePond(id: 'a', nombre: 'Estanque Sur', sigla: 'E-02'),
        makePond(id: 'c', nombre: 'Salacuna', sigla: 'SC'),
      ]..sort(Pond.compareByNumber);

      expect(ponds.map((p) => p.id).toList(), ['a', 'b', 'c']);
    });
  });
}
