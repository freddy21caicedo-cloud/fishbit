import 'package:flutter_test/flutter_test.dart';
import 'package:fishbit_finance/modules/feeding_nutrition/domain/models/feeding_record.dart';

void main() {
  group('FeedingRecord Domain Model Tests', () {
    test('Serializes to JSON with canonical alimentacion_diaria columns', () {
      final now = DateTime(2026, 8, 29);
      final record = FeedingRecord(
        id: 'feed-001',
        empresaId: 'emp-10',
        unidadAcuicolaId: 'unit-20',
        estanqueId: 'pond-30',
        loteId: 'batch-40',
        insumoId: 'feed-item-50',
        cantidadConsumidaKg: 50.0,
        costoCalculado: 240000.0,
        fecha: now,
        creadoEn: now,
      );

      final json = record.toJson();

      expect(json['id'], 'feed-001');
      expect(json['empresa_id'], 'emp-10');
      expect(json['unidad_acuicola_id'], 'unit-20');
      expect(json['estanque_id'], 'pond-30');
      expect(json['lote_id'], 'batch-40');
      expect(json['insumo_id'], 'feed-item-50');
      expect(json['cantidad_consumida_kg'], 50.0);
      expect(json['costo_calculado'], 240000.0);
      expect(json['fecha'], '2026-08-29');
    });

    test('Deserializes from database JSON with canonical columns', () {
      final dbJson = {
        'id': 'feed-db-99',
        'empresa_id': '3500cc63-5477-4f83-b4a3-7758b7cd6509',
        'unit_id': '3500cc63-5477-4f83-b4a3-7758b7cd6509',
        'estanque_id': 'estanque-01',
        'lote_id': 'lote-01',
        'insumo_id': 'insumo-concentrado-45',
        'cantidad_consumida_kg': 60.5,
        'costo_calculado': 290400.0,
        'fecha': '2026-08-29',
        'creado_en': '2026-08-29T12:00:00.000Z',
      };

      final record = FeedingRecord.fromJson(dbJson);

      expect(record.id, 'feed-db-99');
      expect(record.empresaId, '3500cc63-5477-4f83-b4a3-7758b7cd6509');
      expect(record.estanqueId, 'estanque-01');
      expect(record.loteId, 'lote-01');
      expect(record.insumoId, 'insumo-concentrado-45');
      expect(record.cantidadConsumidaKg, 60.5);
      expect(record.costoCalculado, 290400.0);
    });
  });
}
