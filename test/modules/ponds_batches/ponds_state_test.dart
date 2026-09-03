import 'package:flutter_test/flutter_test.dart';
import 'package:fishbit_finance/modules/ponds_batches/domain/models/pond.dart';
import 'package:fishbit_finance/modules/ponds_batches/domain/models/fish_batch.dart';
import 'package:fishbit_finance/modules/ponds_batches/domain/models/biometria_record.dart';
import 'package:fishbit_finance/modules/ponds_batches/domain/models/mortality_record.dart';
import 'package:fishbit_finance/modules/ponds_batches/presentation/providers/ponds_provider.dart';

void main() {
  group('PondsState & Collections Tests', () {
    test('PondsState holds biometries and mortalityRecords properly', () {
      final now = DateTime.now();
      final pond = Pond(
        id: 'p-1',
        empresaId: 'emp-1',
        unidadAcuicolaId: 'u-1',
        nombre: 'Estanque 1',
        sigla: 'E-01',
        capacidadM3: 500,
        biomasaKg: 2500,
        costoAcumuladoBiologico: 10000000,
        estado: PondStatus.active,
        creadoEn: now,
      );

      final batch = FishBatch(
        id: 'b-1',
        empresaId: 'emp-1',
        unidadAcuicolaId: 'u-1',
        estanqueId: 'p-1',
        codigoLote: 'LOT-01',
        especie: 'Tilapia Roja',
        cantidadInicialPeces: 5000,
        cantidadActualPeces: 5000,
        pesoInicialGramos: 10,
        pesoActualGramos: 500,
        biomasaInicialKg: 50,
        biomasaActualKg: 2500,
        costoInicialAlevinos: 1500000,
        costoAcumuladoInsumos: 7500000,
        costoAcumuladoFijo: 1000000,
        estado: BatchStatus.active,
        fechaSiembra: now.subtract(const Duration(days: 90)),
        creadoEn: now,
      );

      final bio = BiometriaRecord(
        id: 'bio-1',
        empresaId: 'emp-1',
        unitId: 'u-1',
        estanqueId: 'p-1',
        loteId: 'b-1',
        fecha: now,
        pecesCapturados: 35,
        pesoTotalCapturaKg: 17.5,
        pesoPromedioG: 500.0,
        biomasaParcialKg: 2500.0,
        creadoEn: now,
      );

      final mor = MortalityRecord(
        id: 'mor-1',
        empresaId: 'emp-1',
        unidadAcuicolaId: 'u-1',
        estanqueId: 'p-1',
        loteId: 'b-1',
        cantidadPecesMuertos: 5,
        pesoPromedioGramos: 500.0,
        biomasaPerdidaKg: 2.5,
        causaProbable: 'Hipoxia / Bajo O2',
        fecha: now,
        creadoEn: now,
      );

      final state = PondsState(
        isLoading: false,
        ponds: [pond],
        batches: [batch],
        biometries: [bio],
        mortalityRecords: [mor],
      );

      expect(state.ponds.length, 1);
      expect(state.batches.length, 1);
      expect(state.biometries.length, 1);
      expect(state.mortalityRecords.length, 1);
      expect(state.biomasaTotalKg, 2500.0);
      expect(state.costoTotalEnAgua, 10000000.0);
      expect(state.estanquesActivosCount, 1);

      // Test copyWith
      final updatedState = state.copyWith(
        biometries: [
          BiometriaRecord(
            id: 'bio-2',
            empresaId: 'emp-1',
            unitId: 'u-1',
            estanqueId: 'p-1',
            loteId: 'b-1',
            fecha: now.add(const Duration(days: 14)),
            pecesCapturados: 40,
            pesoTotalCapturaKg: 24.0,
            pesoPromedioG: 600.0,
            biomasaParcialKg: 3000.0,
            creadoEn: now,
          ),
          ...state.biometries,
        ],
      );

      expect(updatedState.biometries.length, 2);
      expect(updatedState.biometries.first.pesoPromedioG, 600.0);
    });
  });
}
