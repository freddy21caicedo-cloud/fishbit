import 'package:flutter_test/flutter_test.dart';
import 'package:fishbit_finance/modules/ponds_batches/domain/models/biometria_record.dart';
import 'package:fishbit_finance/modules/ponds_batches/domain/models/mortality_record.dart';
import 'package:fishbit_finance/modules/ponds_batches/presentation/dialogs/alimentar_modal.dart';
import 'package:fishbit_finance/modules/water_quality/domain/models/water_parameter.dart';

void main() {
  group('Edición en sitio de Alimentación (AlimentarModal.validateStockForFeeding)', () {
    test('Cambiar solo la fecha con stock actual en 0 kg NO bloquea la edición', () {
      final res = AlimentarModal.validateStockForFeeding(
        isEditing: true,
        originalInsumoId: 'insumo-1',
        selectedInsumoId: 'insumo-1',
        originalKg: 280.0,
        newKg: 280.0,
        currentStockKg: 0.0,
      );

      expect(res.isInsufficient, isFalse);
      expect(res.requiresStockCheck, isFalse);
      expect(res.deltaKg, 0.0);
    });

    test('Reducir cantidad en edición con stock 0 kg está permitido y calcula delta negativo', () {
      final res = AlimentarModal.validateStockForFeeding(
        isEditing: true,
        originalInsumoId: 'insumo-1',
        selectedInsumoId: 'insumo-1',
        originalKg: 280.0,
        newKg: 200.0,
        currentStockKg: 0.0,
      );

      expect(res.isInsufficient, isFalse);
      expect(res.deltaKg, -80.0);
    });

    test('Aumentar cantidad en edición solo exige stock para la diferencia adicional', () {
      final okRes = AlimentarModal.validateStockForFeeding(
        isEditing: true,
        originalInsumoId: 'insumo-1',
        selectedInsumoId: 'insumo-1',
        originalKg: 280.0,
        newKg: 320.0,
        currentStockKg: 50.0,
      );
      expect(okRes.isInsufficient, isFalse);
      expect(okRes.deltaKg, 40.0);

      final failRes = AlimentarModal.validateStockForFeeding(
        isEditing: true,
        originalInsumoId: 'insumo-1',
        selectedInsumoId: 'insumo-1',
        originalKg: 280.0,
        newKg: 350.0,
        currentStockKg: 50.0,
      );
      expect(failRes.isInsufficient, isTrue);
      expect(failRes.deltaKg, 70.0);
    });

    test('Cambiar a otro concentrado en edición valida contra el stock del nuevo insumo', () {
      final failRes = AlimentarModal.validateStockForFeeding(
        isEditing: true,
        originalInsumoId: 'insumo-1',
        selectedInsumoId: 'insumo-2',
        originalKg: 280.0,
        newKg: 280.0,
        currentStockKg: 100.0,
      );
      expect(failRes.isInsufficient, isTrue);

      final okRes = AlimentarModal.validateStockForFeeding(
        isEditing: true,
        originalInsumoId: 'insumo-1',
        selectedInsumoId: 'insumo-2',
        originalKg: 280.0,
        newKg: 280.0,
        currentStockKg: 300.0,
      );
      expect(okRes.isInsufficient, isFalse);
    });
  });

  group('Modelos editables (limpieza de opcionales y fechas sin corrimiento UTC)', () {
    test('BiometriaRecord.copyWith permite limpiar observaciones, longitud y factorK', () {
      final now = DateTime(2026, 11, 19);
      final bio = BiometriaRecord(
        id: 'bio-1',
        empresaId: 'emp-1',
        unitId: 'u-1',
        estanqueId: 'p-1',
        loteId: 'l-1',
        fecha: now,
        pecesCapturados: 35,
        pesoTotalCapturaKg: 10.5,
        pesoPromedioG: 300.0,
        biomasaParcialKg: 1500.0,
        longitudCm: 22.0,
        factorK: 1.65,
        observaciones: 'Nota inicial',
        creadoEn: now,
      );

      final cleaned = bio.copyWith(
        clearLongitudCm: true,
        clearFactorK: true,
        clearObservaciones: true,
      );

      expect(cleaned.longitudCm, isNull);
      expect(cleaned.factorK, isNull);
      expect(cleaned.observaciones, isNull);
    });

    test('MortalityRecord.fromJson conserva la fecha civil sin correrse por UTC y copyWith limpia observaciones', () {
      final rec = MortalityRecord.fromJson({
        'id': 'm-1',
        'empresa_id': 'emp-1',
        'estanque_id': 'p-1',
        'lote_id': 'l-1',
        'cantidad_peces_muertos': 15,
        'peso_promedio_gramos': 120.0,
        'causa_probable': 'Causa personalizada',
        'observaciones': 'Nota previa',
        'fecha': '2026-02-23 00:00:00+00',
        'date': '2026-02-23',
      });

      expect(rec.fecha.year, 2026);
      expect(rec.fecha.month, 2);
      expect(rec.fecha.day, 23);
      expect(rec.causaProbable, 'Causa personalizada');

      final cleaned = rec.copyWith(clearObservaciones: true);
      expect(cleaned.observaciones, isNull);
    });

    test('WaterParameter.fromJson convierte timestamptz UTC a hora local', () {
      const utcIso = '2026-11-19T17:30:00Z';
      final param = WaterParameter.fromJson({
        'id': 'w-1',
        'empresa_id': 'emp-1',
        'estanque_id': 'p-1',
        'fecha': utcIso,
        'oxigeno_mg_l': 6.0,
        'ph': 7.2,
        'temperatura': 26.0,
      });

      expect(param.fecha.isUtc, isFalse);
      expect(param.fecha, DateTime.parse(utcIso).toLocal());
    });
  });
}
