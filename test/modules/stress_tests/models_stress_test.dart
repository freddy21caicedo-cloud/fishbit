import 'package:flutter_test/flutter_test.dart';
import 'package:fishbit_finance/modules/ponds_batches/domain/models/biometria_record.dart';
import 'package:fishbit_finance/modules/ponds_batches/domain/models/mortality_record.dart';
import 'package:fishbit_finance/modules/water_quality/domain/models/water_parameter.dart';

void main() {
  group('BiometriaRecord Stress Tests', () {
    test('Handles completely empty map without throwing', () {
      final bio = BiometriaRecord.fromJson({});
      expect(bio.id, '');
      expect(bio.empresaId, '');
      expect(bio.unitId, '');
      expect(bio.estanqueId, '');
      expect(bio.loteId, '');
      expect(bio.pecesCapturados, 0);
      expect(bio.pesoTotalCapturaKg, 0.0);
      expect(bio.pesoPromedioG, 0.0);
      expect(bio.biomasaParcialKg, 0.0);
      expect(bio.longitudCm, isNull);
      expect(bio.factorK, isNull);
      expect(bio.gdpGDia, isNull);
      expect(bio.observaciones, isNull);
      expect(bio.registradoPor, isNull);
      expect(bio.fecha, isNotNull);
    });

    test('Handles map with explicit null values for all keys', () {
      final nullMap = {
        'id': null,
        'empresa_id': null,
        'unit_id': null,
        'estanque_id': null,
        'lote_id': null,
        'fecha': null,
        'hora': null,
        'peces_capturados': null,
        'peso_total_captura_kg': null,
        'peso_promedio_g': null,
        'biomasa_parcial_kg': null,
        'longitud_cm': null,
        'factor_k': null,
        'gdp_g_dia': null,
        'observaciones': null,
        'registrado_por': null,
        'creado_en': null,
      };

      final bio = BiometriaRecord.fromJson(nullMap);
      expect(bio.id, '');
      expect(bio.empresaId, '');
      expect(bio.pecesCapturados, 0);
      expect(bio.pesoPromedioG, 0.0);
      expect(bio.biomasaParcialKg, 0.0);
    });

    test('Parses Spanish column variants correctly with numeric values', () {
      final spanishJson = {
        'id': 'bio-esp-01',
        'empresa_id': 'emp-001',
        'unidad_acuicola_id': 'unit-001',
        'estanque_id': 'est-001',
        'lote_id': 'lot-001',
        'fecha': '2026-08-20',
        'hora': '14:30:00',
        'peces_muestreados': 50,
        'peso_total_kg': 25.5,
        'peso_promedio_gramos': 510.0,
        'biomasa_total_kg': 2550.0,
        'longitud': 30.2,
        'factorK': 1.75,
        'gdp': 6.1,
        'observaciones': 'Muestreo de control',
        'registrado_por': 'Biólogo Juan',
      };

      final bio = BiometriaRecord.fromJson(spanishJson);
      expect(bio.id, 'bio-esp-01');
      expect(bio.unitId, 'unit-001');
      expect(bio.pecesCapturados, 50);
      expect(bio.pesoTotalCapturaKg, 25.5);
      expect(bio.pesoPromedioG, 510.0);
      expect(bio.biomasaParcialKg, 2550.0);
      expect(bio.longitudCm, 30.2);
      expect(bio.factorK, 1.75);
      expect(bio.gdpGDia, 6.1);
      expect(bio.observaciones, 'Muestreo de control');
      expect(bio.registradoPor, 'Biólogo Juan');
    });

    test('Parses English column variants correctly with numeric values', () {
      final englishJson = {
        'id': 'bio-eng-01',
        'empresaId': 'emp-eng-001',
        'unitId': 'unit-eng-001',
        'pond_id': 'pond-eng-001',
        'batch_id': 'batch-eng-001',
        'date': '2026-08-22',
        'hour': '09:00:00',
        'sample_count': 60,
        'sample_total_weight_kg': 30.0,
        'avg_weight_gr': 500.0,
        'total_biomass_kg': 3000.0,
        'length_cm': 29.0,
        'factor_k': 1.68,
        'adg_g_day': 5.8,
        'notes': 'Uniform growth observed',
        'recorded_by': 'Carlos Eng',
      };

      final bio = BiometriaRecord.fromJson(englishJson);
      expect(bio.id, 'bio-eng-01');
      expect(bio.empresaId, 'emp-eng-001');
      expect(bio.unitId, 'unit-eng-001');
      expect(bio.estanqueId, 'pond-eng-001');
      expect(bio.loteId, 'batch-eng-001');
      expect(bio.pecesCapturados, 60);
      expect(bio.pesoTotalCapturaKg, 30.0);
      expect(bio.pesoPromedioG, 500.0);
      expect(bio.biomasaParcialKg, 3000.0);
      expect(bio.longitudCm, 29.0);
      expect(bio.factorK, 1.68);
      expect(bio.gdpGDia, 5.8);
      expect(bio.observaciones, 'Uniform growth observed');
      expect(bio.registradoPor, 'Carlos Eng');
    });

    test('Resilient to String-encoded numbers without throwing TypeError', () {
      final stringNumberJson = {
        'id': '12345',
        'empresa_id': '999',
        'peces_capturados': '45', // String instead of int
        'peso_total_captura_kg': '22.75', // String instead of double
        'peso_promedio_g': '505.5',
        'biomasa_parcial_kg': '2527.5',
        'longitud_cm': '32.4',
        'factor_k': '1.55',
        'gdp_g_dia': '4.2',
      };

      final bio = BiometriaRecord.fromJson(stringNumberJson);
      expect(bio.id, '12345');
      expect(bio.empresaId, '999');
      expect(bio.pecesCapturados, 45);
      expect(bio.pesoTotalCapturaKg, 22.75);
      expect(bio.pesoPromedioG, 505.5);
      expect(bio.biomasaParcialKg, 2527.5);
      expect(bio.longitudCm, 32.4);
      expect(bio.factorK, 1.55);
      expect(bio.gdpGDia, 4.2);
    });

    test('Stress tests extreme numerical boundary values', () {
      final extremeJson = {
        'id': 'bio-extreme',
        'peces_capturados': 10000000,
        'peso_total_captura_kg': 50000000.0,
        'peso_promedio_g': 5000.0,
        'biomasa_parcial_kg': 50000000.0,
        'longitud_cm': 120.5,
        'factor_k': 0.001,
        'gdp_g_dia': -2.5, // Negative GDP for weight loss
      };

      final bio = BiometriaRecord.fromJson(extremeJson);
      expect(bio.pecesCapturados, 10000000);
      expect(bio.pesoTotalCapturaKg, 50000000.0);
      expect(bio.pesoPromedioG, 5000.0);
      expect(bio.biomasaParcialKg, 50000000.0);
      expect(bio.factorK, 0.001);
      expect(bio.gdpGDia, -2.5);
    });
  });

  group('MortalityRecord Stress Tests', () {
    test('Handles completely empty map without throwing', () {
      final mor = MortalityRecord.fromJson({});
      expect(mor.id, '');
      expect(mor.empresaId, '');
      expect(mor.unidadAcuicolaId, '');
      expect(mor.estanqueId, '');
      expect(mor.loteId, '');
      expect(mor.cantidadPecesMuertos, 0);
      expect(mor.pesoPromedioGramos, 0.0);
      expect(mor.biomasaPerdidaKg, 0.0);
      expect(mor.causaProbable, 'Desconocida');
      expect(mor.fecha, isNotNull);
    });

    test('Handles map with explicit null values for all keys', () {
      final nullMap = {
        'id': null,
        'empresa_id': null,
        'unit_id': null,
        'estanque_id': null,
        'lote_id': null,
        'cantidad_peces_muertos': null,
        'peso_promedio_gramos': null,
        'biomasa_perdida_kg': null,
        'causa_probable': null,
        'observaciones': null,
        'registrado_por': null,
        'fecha': null,
        'hora': null,
        'creado_en': null,
      };

      final mor = MortalityRecord.fromJson(nullMap);
      expect(mor.id, '');
      expect(mor.empresaId, '');
      expect(mor.cantidadPecesMuertos, 0);
      expect(mor.pesoPromedioGramos, 0.0);
      expect(mor.biomasaPerdidaKg, 0.0);
      expect(mor.causaProbable, 'Desconocida');
    });

    test('Parses Spanish column variants correctly', () {
      final spanishJson = {
        'id': 'mor-esp-01',
        'empresa_id': 'emp-esp-01',
        'unidad_acuicola_id': 'unit-esp-01',
        'estanque_id': 'estanque-05',
        'lote_id': 'lote-05',
        'cantidad': 25,
        'peso_promedio': 480.0,
        'biomasa_perdida': 12.0,
        'causa': 'Asfixia por alga',
        'observaciones': 'Bloom de cianobacterias',
        'registrado_por': 'Técnico Pedro',
        'fecha': '2026-08-28',
        'hora': '05:45:00',
      };

      final mor = MortalityRecord.fromJson(spanishJson);
      expect(mor.id, 'mor-esp-01');
      expect(mor.unidadAcuicolaId, 'unit-esp-01');
      expect(mor.cantidadPecesMuertos, 25);
      expect(mor.cantidad, 25);
      expect(mor.pesoPromedioGramos, 480.0);
      expect(mor.biomasaPerdidaKg, 12.0);
      expect(mor.causaProbable, 'Asfixia por alga');
      expect(mor.causa, 'Asfixia por alga');
      expect(mor.observaciones, 'Bloom de cianobacterias');
      expect(mor.registradoPor, 'Técnico Pedro');
    });

    test('Parses English column variants correctly', () {
      final englishJson = {
        'id': 'mor-eng-01',
        'empresaId': 'emp-eng-01',
        'unitId': 'unit-eng-01',
        'pond_id': 'pond-05',
        'batch_id': 'batch-05',
        'quantity': 18,
        'avg_weight_gr': 350.0,
        'lost_biomass_kg': 6.3,
        'cause': 'Parasitic infestation',
        'notes': 'Trichodina detected in gills',
        'recorded_by': 'Veterinarian Lisa',
        'date': '2026-08-27',
        'hour': '11:20:00',
      };

      final mor = MortalityRecord.fromJson(englishJson);
      expect(mor.id, 'mor-eng-01');
      expect(mor.empresaId, 'emp-eng-01');
      expect(mor.unitId, 'unit-eng-01');
      expect(mor.estanqueId, 'pond-05');
      expect(mor.loteId, 'batch-05');
      expect(mor.batchId, 'batch-05');
      expect(mor.quantity, 18);
      expect(mor.cantidadPecesMuertos, 18);
      expect(mor.pesoPromedioGramos, 350.0);
      expect(mor.avgWeightGr, 350.0);
      expect(mor.biomasaPerdidaKg, 6.3);
      expect(mor.lostBiomassKg, 6.3);
      expect(mor.cause, 'Parasitic infestation');
      expect(mor.causaProbable, 'Parasitic infestation');
      expect(mor.observaciones, 'Trichodina detected in gills');
      expect(mor.registradoPor, 'Veterinarian Lisa');
    });

    test('Resilient to String numbers without throwing TypeError in MortalityRecord', () {
      final stringNumberJson = {
        'id': '9999',
        'cantidad': '30', // String instead of int
        'peso_promedio_g': '400.0', // String instead of double
        'biomasa_perdida_kg': '12.0',
        'causa': 'Desconocida',
      };

      final mor = MortalityRecord.fromJson(stringNumberJson);
      expect(mor.id, '9999');
      expect(mor.cantidadPecesMuertos, 30);
      expect(mor.pesoPromedioGramos, 400.0);
      expect(mor.biomasaPerdidaKg, 12.0);
      expect(mor.causaProbable, 'Desconocida');
    });

    test('Computes biomasaPerdidaKg fallback when omitted from numeric json', () {
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

  group('WaterParameter.toJson() & fromJson() Canonical DB Alignment Tests', () {
    test('toJson() generates exact keys expected by parametros_calidad_agua DB schema', () {
      final testDate = DateTime(2026, 8, 29, 15, 45, 0);
      final param = WaterParameter(
        id: 'water-param-001',
        empresaId: '3500cc63-5477-4f83-b4a3-7758b7cd6509',
        unidadAcuicolaId: 'unit-uuid-1',
        estanqueId: 'pond-uuid-1',
        fecha: testDate,
        oxigenoMgL: 6.8,
        oxigenoPct: 92.5,
        ph: 7.35,
        temperaturaC: 28.2,
        amonioMgL: 0.12,
        nitritosMgL: 0.03,
        nitratosMgL: 4.5,
        alcalinidadMgL: 125.0,
        co2MgL: 5.0,
        durezaMgL: 145.0,
        cloroMgL: 0.01,
        observaciones: 'Calidad de agua óptima',
        registradoPor: 'Operador Estanque 1',
      );

      final json = param.toJson();

      // Verify all 21 keys produced by toJson()
      expect(json.containsKey('id'), isTrue);
      expect(json.containsKey('empresa_id'), isTrue);
      expect(json.containsKey('unit_id'), isTrue);
      expect(json.containsKey('unidad_acuicola_id'), isTrue);
      expect(json.containsKey('estanque_id'), isTrue);
      expect(json.containsKey('fecha'), isTrue);
      expect(json.containsKey('hora'), isTrue);
      expect(json.containsKey('oxigeno_mg_l'), isTrue);
      expect(json.containsKey('oxigeno_pct'), isTrue);
      expect(json.containsKey('ph'), isTrue);
      expect(json.containsKey('temperatura'), isTrue);
      expect(json.containsKey('temperatura_c'), isTrue);
      expect(json.containsKey('amonio_mg_l'), isTrue);
      expect(json.containsKey('nitritos_mg_l'), isTrue);
      expect(json.containsKey('nitratos_mg_l'), isTrue);
      expect(json.containsKey('alcalinidad_mg_l'), isTrue);
      expect(json.containsKey('co2_mg_l'), isTrue);
      expect(json.containsKey('dureza_mg_l'), isTrue);
      expect(json.containsKey('cloro_mg_l'), isTrue);
      expect(json.containsKey('observaciones'), isTrue);
      expect(json.containsKey('registrado_por'), isTrue);

      // Verify values
      expect(json['id'], 'water-param-001');
      expect(json['empresa_id'], '3500cc63-5477-4f83-b4a3-7758b7cd6509');
      expect(json['unit_id'], 'unit-uuid-1');
      expect(json['unidad_acuicola_id'], 'unit-uuid-1');
      expect(json['estanque_id'], 'pond-uuid-1');
      expect(json['fecha'], testDate.toIso8601String());
      expect(json['hora'], '15:45:00');
      expect(json['oxigeno_mg_l'], 6.8);
      expect(json['oxigeno_pct'], 92.5);
      expect(json['ph'], 7.35);
      expect(json['temperatura'], 28.2);
      expect(json['temperatura_c'], 28.2);
      expect(json['amonio_mg_l'], 0.12);
      expect(json['nitritos_mg_l'], 0.03);
      expect(json['nitratos_mg_l'], 4.5);
      expect(json['alcalinidad_mg_l'], 125.0);
      expect(json['co2_mg_l'], 5.0);
      expect(json['dureza_mg_l'], 145.0);
      expect(json['cloro_mg_l'], 0.01);
      expect(json['observaciones'], 'Calidad de agua óptima');
      expect(json['registrado_por'], 'Operador Estanque 1');
    });

    test('Handles null optional parameters in toJson() correctly', () {
      final testDate = DateTime(2026, 8, 29, 8, 0, 0);
      final minimalParam = WaterParameter(
        id: 'water-param-min',
        empresaId: 'emp-1',
        unidadAcuicolaId: 'unit-1',
        estanqueId: 'pond-1',
        fecha: testDate,
      );

      final json = minimalParam.toJson();
      expect(json['id'], 'water-param-min');
      expect(json['empresa_id'], 'emp-1');
      expect(json['unit_id'], 'unit-1');
      expect(json['hora'], '08:00:00');
      expect(json['oxigeno_mg_l'], isNull);
      expect(json['ph'], isNull);
      expect(json['temperatura'], isNull);
      expect(json['amonio_mg_l'], isNull);
      expect(json['nitritos_mg_l'], isNull);
      expect(json['nitratos_mg_l'], isNull);
      expect(json['alcalinidad_mg_l'], isNull);
      expect(json['co2_mg_l'], isNull);
      expect(json['dureza_mg_l'], isNull);
      expect(json['cloro_mg_l'], isNull);
      expect(json['observaciones'], isNull);
      expect(json['registrado_por'], isNull);
    });

    test('WaterParameter.fromJson is resilient to String-encoded numbers', () {
      final stringParamJson = {
        'id': 'water-str-01',
        'empresa_id': 'emp-01',
        'unit_id': 'unit-01',
        'estanque_id': 'pond-01',
        'fecha': '2026-08-29T10:00:00.000Z',
        'oxigeno_mg_l': '6.5',
        'oxigeno_pct': '88.5',
        'ph': '7.4',
        'temperatura': '28.5',
        'amonio_mg_l': '0.15',
        'nitritos_mg_l': '0.04',
        'nitratos_mg_l': '3.2',
        'alcalinidad_mg_l': '115.0',
        'co2_mg_l': '4.8',
        'dureza_mg_l': '135.0',
        'cloro_mg_l': '0.02',
      };

      final param = WaterParameter.fromJson(stringParamJson);
      expect(param.oxigenoMgL, 6.5);
      expect(param.oxigenoPct, 88.5);
      expect(param.ph, 7.4);
      expect(param.temperaturaC, 28.5);
      expect(param.amonioMgL, 0.15);
      expect(param.nitritosMgL, 0.04);
      expect(param.nitratosMgL, 3.2);
      expect(param.alcalinidadMgL, 115.0);
      expect(param.co2MgL, 4.8);
      expect(param.durezaMgL, 135.0);
      expect(param.cloroMgL, 0.02);
    });
  });
}
