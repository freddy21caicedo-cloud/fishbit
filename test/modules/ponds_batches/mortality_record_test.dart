import 'package:flutter_test/flutter_test.dart';
import 'package:fishbit_finance/modules/ponds_batches/domain/models/mortality_record.dart';

void main() {
  group('MortalityRecord Domain Model Tests', () {
    test('Serializes to JSON with bilingual canonical columns', () {
      final now = DateTime(2026, 8, 29, 7, 0, 0);
      final record = MortalityRecord(
        id: 'mor-uuid-001',
        empresaId: 'emp-uuid-1',
        unidadAcuicolaId: 'unit-uuid-1',
        estanqueId: 'pond-uuid-1',
        loteId: 'batch-uuid-1',
        cantidadPecesMuertos: 12,
        pesoPromedioGramos: 350.0,
        biomasaPerdidaKg: 4.2,
        causaProbable: 'Hipoxia / Bajo O2',
        observaciones: 'Falla temporal de aireador',
        registradoPor: 'Operador Sanitario',
        fecha: now,
        hora: '07:00:00',
        creadoEn: now,
      );

      final json = record.toJson();

      expect(json['id'], 'mor-uuid-001');
      expect(json['empresa_id'], 'emp-uuid-1');
      expect(json['unit_id'], 'unit-uuid-1');
      expect(json['unidad_acuicola_id'], 'unit-uuid-1');
      expect(json['estanque_id'], 'pond-uuid-1');
      expect(json['lote_id'], 'batch-uuid-1');
      expect(json['batch_id'], 'batch-uuid-1');
      expect(json['cantidad_peces_muertos'], 12);
      expect(json['cantidad'], 12);
      expect(json['quantity'], 12);
      expect(json['peso_promedio_gramos'], 350.0);
      expect(json['biomasa_perdida_kg'], 4.2);
      expect(json['causa_probable'], 'Hipoxia / Bajo O2');
      expect(json['causa'], 'Hipoxia / Bajo O2');
      expect(json['cause'], 'Hipoxia / Bajo O2');
      expect(json['observaciones'], 'Falla temporal de aireador');
      expect(json['registrado_por'], 'Operador Sanitario');
      expect(json['fecha'], '2026-08-29');
      expect(json['date'], '2026-08-29');
      expect(json['hora'], '07:00:00');
    });

    test('Deserializes from database JSON with bilingual synonym support', () {
      final dbJson = {
        'id': 'mor-db-555',
        'empresa_id': '3500cc63-5477-4f83-b4a3-7758b7cd6509',
        'unit_id': '3500cc63-5477-4f83-b4a3-7758b7cd6509',
        'estanque_id': 'estanque-02',
        'batch_id': 'lote-cachama-02',
        'date': '2026-08-25',
        'hour': '06:30:00',
        'quantity': 15,
        'cause': 'Bacteriosis / Columnaris',
        'peso_promedio_gramos': 400.0,
        'biomasa_perdida_kg': 6.0,
        'observaciones': 'Tratamiento iniciado',
        'recorded_by': 'Sanidad Acuícola',
      };

      final record = MortalityRecord.fromJson(dbJson);

      expect(record.id, 'mor-db-555');
      expect(record.empresaId, '3500cc63-5477-4f83-b4a3-7758b7cd6509');
      expect(record.unidadAcuicolaId, '3500cc63-5477-4f83-b4a3-7758b7cd6509');
      expect(record.unitId, '3500cc63-5477-4f83-b4a3-7758b7cd6509');
      expect(record.loteId, 'lote-cachama-02');
      expect(record.batchId, 'lote-cachama-02');
      expect(record.cantidadPecesMuertos, 15);
      expect(record.quantity, 15);
      expect(record.cantidad, 15);
      expect(record.causaProbable, 'Bacteriosis / Columnaris');
      expect(record.cause, 'Bacteriosis / Columnaris');
      expect(record.causa, 'Bacteriosis / Columnaris');
      expect(record.pesoPromedioGramos, 400.0);
      expect(record.biomasaPerdidaKg, 6.0);
      expect(record.registradoPor, 'Sanidad Acuícola');
    });

    test('Computes biomasaPerdidaKg fallback if missing from json', () {
      final jsonNoBiomass = {
        'id': 'mor-auto-01',
        'empresa_id': 'emp-1',
        'estanque_id': 'pond-1',
        'lote_id': 'batch-1',
        'cantidad_peces_muertos': 10,
        'peso_promedio_gramos': 500.0,
        'causa': 'Depredación / Aves',
      };

      final record = MortalityRecord.fromJson(jsonNoBiomass);

      expect(record.cantidadPecesMuertos, 10);
      expect(record.pesoPromedioGramos, 500.0);
      expect(record.biomasaPerdidaKg, 5.0); // (10 * 500) / 1000 = 5.0 kg
    });
  });
}
