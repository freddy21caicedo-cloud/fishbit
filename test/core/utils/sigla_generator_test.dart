import 'package:flutter_test/flutter_test.dart';
import 'package:fishbit_finance/core/utils/sigla_generator.dart';

void main() {
  group('SiglaGenerator Tests', () {
    test('Calculates acronym from multi-word company names excluding stopwords', () {
      expect(SiglaGenerator.generate('Piscícola San Jerónimo'), equals('PSJ'));
      expect(SiglaGenerator.generate('Acuícola Alto Valle'), equals('AAV'));
      expect(SiglaGenerator.generate('Piscícola del Valle'), equals('PV'));
      expect(SiglaGenerator.generate('Piscícola y Comercializadora del Caribe S.A.S.'), equals('PCC'));
      expect(SiglaGenerator.generate('Truchas de Oriente'), equals('TO'));
    });

    test('Takes first 3 letters for single word names', () {
      expect(SiglaGenerator.generate('Aquacol'), equals('AQU'));
      expect(SiglaGenerator.generate('FishBit'), equals('FIS'));
      expect(SiglaGenerator.generate('Eco'), equals('ECO'));
      expect(SiglaGenerator.generate('Oz'), equals('OZ'));
    });

    test('Handles accents and special characters gracefully', () {
      expect(SiglaGenerator.generate('Piscícola El Cañón'), equals('PC'));
      expect(SiglaGenerator.generate('Estación Acuícola Río Claro'), equals('EARC'));
    });

    test('Returns default fallback when text is empty or blank', () {
      expect(SiglaGenerator.generate(''), equals('PRI'));
      expect(SiglaGenerator.generate('   '), equals('PRI'));
      expect(SiglaGenerator.generate('...', fallback: 'SED'), equals('SED'));
    });

    test('Respects maximum length parameter', () {
      expect(
        SiglaGenerator.generate('Empresa Piscicola Agropecuaria Sostenible Internacional Tropical', maxLength: 4),
        equals('EPAS'),
      );
    });
  });
}
