import 'package:flutter_test/flutter_test.dart';
import 'package:fishbit_finance/core/services/geographic_service.dart';

void main() {
  group('GeographicService Tests', () {
    test('countries list contains Colombia, Peru, Ecuador, Mexico, Brasil, Chile', () {
      expect(GeographicService.countries, contains('Colombia'));
      expect(GeographicService.countries, contains('Perú'));
      expect(GeographicService.countries, contains('Ecuador'));
      expect(GeographicService.countries, contains('México'));
      expect(GeographicService.countries, contains('Brasil'));
      expect(GeographicService.countries, contains('Chile'));
    });

    test('getStatesForCountry returns 32 Colombian departments for Colombia', () {
      final depts = GeographicService.getStatesForCountry('Colombia');
      expect(depts.length, equals(32));
      expect(depts, contains('Huila'));
      expect(depts, contains('Antioquia'));
      expect(depts, contains('Meta'));
      expect(depts, contains('Valle del Cauca'));
    });

    test('getCitiesForState returns aquaculture municipalities for Huila', () {
      final cities = GeographicService.getCitiesForState('Colombia', 'Huila');
      expect(cities, contains('Neiva'));
      expect(cities.any((c) => c.startsWith('Betania')), isTrue);
      expect(cities, contains('Yaguará'));
      expect(cities, contains('Garzón'));
    });

    test('getCitiesForState returns aquaculture municipalities for Antioquia', () {
      final cities = GeographicService.getCitiesForState('Colombia', 'Antioquia');
      expect(cities, contains('Medellín'));
      expect(cities, contains('Guatapé'));
      expect(cities, contains('San Jerónimo'));
    });

    test('getStatesForCountry returns states for international countries', () {
      final peruStates = GeographicService.getStatesForCountry('Perú');
      expect(peruStates.any((s) => s.startsWith('Puno')), isTrue);
      expect(peruStates, contains('San Martín'));

      final ecuadorProvinces = GeographicService.getStatesForCountry('Ecuador');
      expect(ecuadorProvinces.any((p) => p.startsWith('Guayas')), isTrue);
      expect(ecuadorProvinces, contains('Manabí'));
    });

    test('filterList performs accent-insensitive and case-insensitive matching', () {
      final depts = ['Antioquia', 'Boyacá', 'Córdoba', 'Bogotá D.C.', 'Nariño'];
      
      // Matching with accent variation
      final matchCordoba = GeographicService.filterList(depts, 'cordoba');
      expect(matchCordoba, contains('Córdoba'));

      final matchBoyaca = GeographicService.filterList(depts, 'boyaca');
      expect(matchBoyaca, contains('Boyacá'));

      final matchNarino = GeographicService.filterList(depts, 'narino');
      expect(matchNarino, contains('Nariño'));

      // Case insensitive
      final matchAnti = GeographicService.filterList(depts, 'anti');
      expect(matchAnti, contains('Antioquia'));

      // Empty query returns full list
      expect(GeographicService.filterList(depts, '').length, equals(depts.length));
    });
  });
}
