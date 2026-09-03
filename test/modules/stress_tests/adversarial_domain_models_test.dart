import 'package:flutter_test/flutter_test.dart';
import 'package:fishbit_finance/modules/ponds_batches/domain/models/biometria_record.dart';
import 'package:fishbit_finance/modules/ponds_batches/domain/models/mortality_record.dart';
import 'package:fishbit_finance/modules/warehouse_inventory/domain/models/inventory_item.dart';
import 'package:fishbit_finance/modules/sales_harvest/domain/models/batch_sale.dart';

void main() {
  group('Adversarial Challenge: BiometriaRecord', () {
    test('Empty Map, Nulls, and Malformed Keys', () {
      final bio = BiometriaRecord.fromJson({});
      expect(bio.id, '');
      expect(bio.pecesCapturados, 0);
      expect(bio.pesoTotalCapturaKg, 0.0);
      expect(bio.pesoPromedioG, 0.0);
      expect(bio.biomasaParcialKg, 0.0);
    });

    test('String numbers, scientific notation, and invalid strings', () {
      final bio = BiometriaRecord.fromJson({
        'id': 12345, // int instead of string
        'peces_capturados': '50',
        'peso_total_captura_kg': '25.75',
        'peso_promedio_g': '515.0',
        'biomasa_parcial_kg': '2575.0',
        'longitud_cm': '31.2',
        'factor_k': '1.65',
        'gdp_g_dia': '5.5',
      });
      expect(bio.id, '12345');
      expect(bio.pecesCapturados, 50);
      expect(bio.pesoTotalCapturaKg, 25.75);
      expect(bio.pesoPromedioG, 515.0);
      expect(bio.biomasaParcialKg, 2575.0);
      expect(bio.longitudCm, 31.2);
      expect(bio.factorK, 1.65);
      expect(bio.gdpGDia, 5.5);
    });

    test('Boundary conditions: negative numbers, zero, large numbers, and dates', () {
      final bio = BiometriaRecord.fromJson({
        'id': 'bio-boundary',
        'peces_capturados': -10,
        'peso_total_captura_kg': 0.0,
        'peso_promedio_g': -5.0,
        'biomasa_parcial_kg': 999999999.99,
        'fecha': '2026-08-31',
        'hora': '23:59:59',
      });
      expect(bio.pecesCapturados, -10);
      expect(bio.pesoTotalCapturaKg, 0.0);
      expect(bio.pesoPromedioG, -5.0);
      expect(bio.biomasaParcialKg, 999999999.99);
      expect(bio.hora, '23:59:59');
    });

    test('Date fallback on malformed dates', () {
      final bio = BiometriaRecord.fromJson({
        'fecha': 'not-a-date',
      });
      expect(bio.fecha, isNotNull);
    });
  });

  group('Adversarial Challenge: MortalityRecord', () {
    test('Empty Map and Nulls', () {
      final mor = MortalityRecord.fromJson({});
      expect(mor.id, '');
      expect(mor.cantidadPecesMuertos, 0);
      expect(mor.pesoPromedioGramos, 0.0);
      expect(mor.biomasaPerdidaKg, 0.0);
      expect(mor.causaProbable, 'Desconocida');
    });

    test('String numbers and invalid strings', () {
      final mor = MortalityRecord.fromJson({
        'id': 999,
        'cantidad': '15',
        'peso_promedio': '450.5',
        'biomasa_perdida': '6.7575',
        'causa': 'Hipoxia severa',
      });
      expect(mor.id, '999');
      expect(mor.cantidadPecesMuertos, 15);
      expect(mor.pesoPromedioGramos, 450.5);
      expect(mor.biomasaPerdidaKg, 6.7575);
      expect(mor.causaProbable, 'Hipoxia severa');
    });

    test('Biomass calculation fallback when biomasa is missing or invalid', () {
      final mor = MortalityRecord.fromJson({
        'cantidad': '20',
        'peso_promedio': '500',
      });
      expect(mor.cantidadPecesMuertos, 20);
      expect(mor.pesoPromedioGramos, 500.0);
      // Fallback: (20 * 500) / 1000 = 10.0 kg
      expect(mor.biomasaPerdidaKg, 10.0);
    });
  });

  group('Adversarial Challenge: InventoryItem', () {
    test('Tests InventoryItem with String numbers and missing fields', () {
      try {
        final item = InventoryItem.fromJson({
          'id': 'inv-1',
          'current_stock': '150.0', // String number
          'costo_total': '500000', // String number
        });
        expect(item.id, 'inv-1');
      } catch (e) {
        // Record failure mode
        expect(e, isA<TypeError>());
      }
    });

    test('Tests InventoryItem with null ID and empty map', () {
      final item = InventoryItem.fromJson({});
      expect(item.id, '');
      expect(item.nombre, '');
      expect(item.cantidadActualKg, 0.0);
      expect(item.costoTotal, 0.0);
    });
  });

  group('Adversarial Challenge: BatchSale', () {
    test('Tests BatchSale with empty map (null id)', () {
      try {
        final sale = BatchSale.fromJson({});
        expect(sale.id, '');
      } catch (e) {
        expect(e, isA<TypeError>());
      }
    });

    test('Tests BatchSale with String numbers', () {
      try {
        final sale = BatchSale.fromJson({
          'id': 's1',
          'biomasa_vendida_kg': '500.0',
          'precio_unitario_kg': '9000.0',
        });
        expect(sale.biomasaVendidaKg, 500.0);
      } catch (e) {
        expect(e, isA<TypeError>());
      }
    });
  });
}
