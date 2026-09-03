import 'package:flutter_test/flutter_test.dart';
import 'package:fishbit_finance/modules/ponds_batches/domain/models/biometria_record.dart';

void main() {
  group('BiometriaRecord Domain Model Tests', () {
    test('Serializes to JSON with all canonical biometrias schema columns', () {
      final now = DateTime(2026, 8, 29, 9, 15, 0);
      final bio = BiometriaRecord(
        id: 'bio-uuid-001',
        empresaId: 'emp-uuid-100',
        unitId: 'unit-uuid-200',
        estanqueId: 'pond-uuid-300',
        loteId: 'batch-uuid-400',
        fecha: now,
        hora: '09:15:00',
        pecesCapturados: 40,
        pesoTotalCapturaKg: 20.0,
        pesoPromedioG: 500.0,
        biomasaParcialKg: 2850.0,
        longitudCm: 28.5,
        factorK: 1.65,
        gdpGDia: 5.2,
        observaciones: 'Muestreo de engorde final',
        registradoPor: 'Acuicultor Principal',
        creadoEn: now,
      );

      final json = bio.toJson();

      expect(json['id'], 'bio-uuid-001');
      expect(json['empresa_id'], 'emp-uuid-100');
      expect(json['unit_id'], 'unit-uuid-200');
      expect(json['unidad_acuicola_id'], 'unit-uuid-200');
      expect(json['estanque_id'], 'pond-uuid-300');
      expect(json['lote_id'], 'batch-uuid-400');
      expect(json['batch_id'], 'batch-uuid-400');
      expect(json['fecha'], '2026-08-29');
      expect(json['date'], '2026-08-29');
      expect(json['hora'], '09:15:00');
      expect(json['peces_capturados'], 40);
      expect(json['peso_total_captura_kg'], 20.0);
      expect(json['peso_promedio_g'], 500.0);
      expect(json['avg_weight_gr'], 500.0);
      expect(json['biomasa_parcial_kg'], 2850.0);
      expect(json['total_biomass_kg'], 2850.0);
      expect(json['longitud_cm'], 28.5);
      expect(json['factor_k'], 1.65);
      expect(json['gdp_g_dia'], 5.2);
      expect(json['observaciones'], 'Muestreo de engorde final');
      expect(json['registrado_por'], 'Acuicultor Principal');
    });

    test('Deserializes from database JSON with English legacy and Spanish canonical column synonyms', () {
      final dbJson = {
        'id': 'bio-db-777',
        'empresa_id': '3500cc63-5477-4f83-b4a3-7758b7cd6509',
        'unit_id': '3500cc63-5477-4f83-b4a3-7758b7cd6509',
        'estanque_id': 'estanque-01',
        'batch_id': 'lote-tilapia-01',
        'date': '2026-08-20',
        'hora': '10:00:00',
        'sample_count': 35,
        'sample_total_weight_kg': 14.0,
        'avg_weight_gr': 400.0,
        'total_biomass_kg': 2280.0,
        'longitud_cm': 25.0,
        'factor_k': 1.60,
        'gdp_g_dia': 4.5,
        'observaciones': 'Desarrollo uniforme',
        'recorded_by': 'Carlos Tech',
      };

      final record = BiometriaRecord.fromJson(dbJson);

      expect(record.id, 'bio-db-777');
      expect(record.empresaId, '3500cc63-5477-4f83-b4a3-7758b7cd6509');
      expect(record.loteId, 'lote-tilapia-01');
      expect(record.batchId, 'lote-tilapia-01');
      expect(record.pecesCapturados, 35);
      expect(record.pecesMuestreados, 35);
      expect(record.pesoTotalCapturaKg, 14.0);
      expect(record.pesoPromedioG, 400.0);
      expect(record.avgWeightGr, 400.0);
      expect(record.biomasaParcialKg, 2280.0);
      expect(record.totalBiomassKg, 2280.0);
      expect(record.longitudCm, 25.0);
      expect(record.factorK, 1.60);
      expect(record.gdpGDia, 4.5);
      expect(record.registradoPor, 'Carlos Tech');
    });

    test('copyWith produces updated immutable instance', () {
      final bio = BiometriaRecord(
        id: 'bio-1',
        empresaId: 'emp-1',
        unitId: 'unit-1',
        estanqueId: 'pond-1',
        loteId: 'batch-1',
        fecha: DateTime(2026, 8, 1),
        pecesCapturados: 30,
        pesoTotalCapturaKg: 9.0,
        pesoPromedioG: 300.0,
        biomasaParcialKg: 1500.0,
        creadoEn: DateTime(2026, 8, 1),
      );

      final updated = bio.copyWith(
        pesoPromedioG: 350.0,
        biomasaParcialKg: 1750.0,
      );

      expect(updated.id, 'bio-1');
      expect(updated.pesoPromedioG, 350.0);
      expect(updated.biomasaParcialKg, 1750.0);
      expect(updated.pecesCapturados, 30);
    });
  });
}
