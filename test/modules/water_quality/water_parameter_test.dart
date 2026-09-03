import 'package:flutter_test/flutter_test.dart';
import 'package:fishbit_finance/modules/water_quality/domain/models/water_parameter.dart';

void main() {
  group('WaterParameter Domain Model Tests', () {
    test('Serializes to JSON with all 10 physicochemical parameters and canonical fields', () {
      final now = DateTime(2026, 8, 29, 8, 30, 0);
      final param = WaterParameter(
        id: 'w-12345',
        empresaId: 'emp-001',
        unidadAcuicolaId: 'unit-001',
        estanqueId: 'pond-001',
        fecha: now,
        oxigenoMgL: 6.5,
        oxigenoPct: 90.0,
        ph: 7.2,
        temperaturaC: 28.0,
        amonioMgL: 0.1,
        nitritosMgL: 0.02,
        nitratosMgL: 5.0,
        alcalinidadMgL: 120.0,
        co2MgL: 4.5,
        durezaMgL: 140.0,
        cloroMgL: 0.0,
        observaciones: 'Condiciones excelentes',
        registradoPor: 'Biologo 1',
      );

      final json = param.toJson();

      expect(json['id'], 'w-12345');
      expect(json['empresa_id'], 'emp-001');
      expect(json['unit_id'], 'unit-001');
      expect(json['unidad_acuicola_id'], 'unit-001');
      expect(json['estanque_id'], 'pond-001');
      expect(json['oxigeno_mg_l'], 6.5);
      expect(json['oxigeno_pct'], 90.0);
      expect(json['ph'], 7.2);
      expect(json['temperatura'], 28.0);
      expect(json['temperatura_c'], 28.0);
      expect(json['amonio_mg_l'], 0.1);
      expect(json['nitritos_mg_l'], 0.02);
      expect(json['nitratos_mg_l'], 5.0);
      expect(json['alcalinidad_mg_l'], 120.0);
      expect(json['co2_mg_l'], 4.5);
      expect(json['dureza_mg_l'], 140.0);
      expect(json['cloro_mg_l'], 0.0);
      expect(json['observaciones'], 'Condiciones excelentes');
      expect(json['registrado_por'], 'Biologo 1');
      expect(json['hora'], '08:30:00');
    });

    test('Deserializes from database JSON with Spanish canonical columns', () {
      final dbJson = {
        'id': 'param-db-001',
        'empresa_id': '3500cc63-5477-4f83-b4a3-7758b7cd6509',
        'unit_id': '3500cc63-5477-4f83-b4a3-7758b7cd6509',
        'estanque_id': 'pond-999',
        'fecha': '2026-08-29T08:30:00.000Z',
        'hora': '08:30:00',
        'oxigeno_mg_l': 3.2,
        'oxigeno_pct': 45.0,
        'ph': 5.8,
        'temperatura': 29.5,
        'amonio_mg_l': 0.8,
        'nitritos_mg_l': 0.35,
        'nitratos_mg_l': 12.0,
        'alcalinidad_mg_l': 90.0,
        'co2_mg_l': 25.0,
        'dureza_mg_l': 110.0,
        'cloro_mg_l': 0.08,
        'observaciones': 'Alerta sanitaria',
        'registrado_por': 'Operador Juan',
      };

      final param = WaterParameter.fromJson(dbJson);

      expect(param.id, 'param-db-001');
      expect(param.empresaId, '3500cc63-5477-4f83-b4a3-7758b7cd6509');
      expect(param.unidadAcuicolaId, '3500cc63-5477-4f83-b4a3-7758b7cd6509');
      expect(param.estanqueId, 'pond-999');
      expect(param.oxigenoMgL, 3.2);
      expect(param.ph, 5.8);
      expect(param.temperaturaC, 29.5);
      expect(param.amonioMgL, 0.8);
      expect(param.nitritosMgL, 0.35);
      expect(param.co2MgL, 25.0);
      expect(param.cloroMgL, 0.08);

      // Verify critical alerts logic
      expect(param.isOxygenCritical, true);
      expect(param.isPhCritical, true);
      expect(param.isAmmoniaCritical, true);
      expect(param.isNitriteCritical, true);
      expect(param.isCo2Critical, true);
      expect(param.isChlorineCritical, true);
    });

    test('Deserializes from legacy water_quality format gracefully', () {
      final legacyJson = {
        'id': 'legacy-001',
        'empresa_id': 'emp-legacy',
        'unit_id': 'unit-legacy',
        'estanque_id': 'pond-legacy',
        'date': '2026-05-15',
        'hour': '06:00:00',
        'o2_mg_l': 6.0,
        'o2_perc': 85.0,
        'ph': 7.5,
        'temperature_c': 27.5,
        'ammonia_mg_l': 0.1,
        'nitrite_mg_l': 0.01,
        'nitrate_mg_l': 3.0,
        'alkalinity': 115.0,
      };

      final param = WaterParameter.fromJson(legacyJson);

      expect(param.id, 'legacy-001');
      expect(param.oxigenoMgL, 6.0);
      expect(param.oxigenoPct, 85.0);
      expect(param.ph, 7.5);
      expect(param.temperaturaC, 27.5);
      expect(param.amonioMgL, 0.1);
      expect(param.nitritosMgL, 0.01);
      expect(param.nitratosMgL, 3.0);
      expect(param.alcalinidadMgL, 115.0);
      expect(param.isOxygenCritical, false);
    });
  });
}
