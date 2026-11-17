import 'package:flutter_test/flutter_test.dart';
import 'package:fishbit_finance/core/events/app_event_bus.dart';

void main() {
  test('AppEventBus propaga BiometryRecordedEvent y MortalityRecordedEvent correctamente', () async {
    final bus = AppEventBus();
    BiometryRecordedEvent? receivedBio;
    MortalityRecordedEvent? receivedMort;

    final sub1 = bus.on<BiometryRecordedEvent>().listen((e) => receivedBio = e);
    final sub2 = bus.on<MortalityRecordedEvent>().listen((e) => receivedMort = e);

    bus.fire(BiometryRecordedEvent(
      estanqueId: 'est-1',
      loteId: 'lote-1',
      pesoPromedioGramos: 500.0,
      biomasaCalculadaKg: 2500.0,
    ));

    bus.fire(MortalityRecordedEvent(
      estanqueId: 'est-1',
      loteId: 'lote-1',
      cantidadPecesMuertos: 15,
      biomasaPerdidaKg: 7.5,
    ));

    await Future.delayed(const Duration(milliseconds: 50));

    expect(receivedBio, isNotNull);
    expect(receivedBio!.pesoPromedioGramos, 500.0);
    expect(receivedBio!.biomasaCalculadaKg, 2500.0);

    expect(receivedMort, isNotNull);
    expect(receivedMort!.cantidadPecesMuertos, 15);
    expect(receivedMort!.biomasaPerdidaKg, 7.5);

    await sub1.cancel();
    await sub2.cancel();
    bus.dispose();
  });
}
