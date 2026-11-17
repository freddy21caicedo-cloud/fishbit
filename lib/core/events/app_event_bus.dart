import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Evento base para comunicación desacoplada entre módulos
abstract class AppDomainEvent {
  final DateTime occurredAt;
  AppDomainEvent() : occurredAt = DateTime.now();
}

/// Evento disparado cuando se registra una alimentación diaria
class DailyFeedingRecordedEvent extends AppDomainEvent {
  final String estanqueId;
  final String loteId;
  final double kgConsumidos;
  final double costoTotal;

  DailyFeedingRecordedEvent({
    required this.estanqueId,
    required this.loteId,
    required this.kgConsumidos,
    required this.costoTotal,
  });
}

/// Evento disparado cuando se realiza una venta o cosecha
class HarvestSaleRecordedEvent extends AppDomainEvent {
  final String loteId;
  final double biomasaVendidaKg;
  final double ingresoBruto;
  final double cogs;
  final int pecesVendidos;

  HarvestSaleRecordedEvent({
    required this.loteId,
    required this.biomasaVendidaKg,
    required this.ingresoBruto,
    required this.cogs,
    this.pecesVendidos = 0,
  });
}

/// Evento disparado cuando se registra una biometría (muestreo de peso)
class BiometryRecordedEvent extends AppDomainEvent {
  final String estanqueId;
  final String loteId;
  final double pesoPromedioGramos;
  final double? biomasaCalculadaKg;
  final DateTime fecha;

  BiometryRecordedEvent({
    required this.estanqueId,
    required this.loteId,
    required this.pesoPromedioGramos,
    this.biomasaCalculadaKg,
    DateTime? fecha,
  }) : fecha = fecha ?? DateTime.now();
}

/// Evento disparado cuando se registra una mortalidad (baja de peces)
class MortalityRecordedEvent extends AppDomainEvent {
  final String estanqueId;
  final String loteId;
  final int cantidadPecesMuertos;
  final double? biomasaPerdidaKg;
  final DateTime fecha;

  MortalityRecordedEvent({
    required this.estanqueId,
    required this.loteId,
    required this.cantidadPecesMuertos,
    this.biomasaPerdidaKg,
    DateTime? fecha,
  }) : fecha = fecha ?? DateTime.now();
}

/// Event Bus para publicar y suscribirse a eventos de dominio en proceso
class AppEventBus {
  final _controller = StreamController<AppDomainEvent>.broadcast();

  Stream<T> on<T extends AppDomainEvent>() {
    return _controller.stream.where((event) => event is T).cast<T>();
  }

  void fire(AppDomainEvent event) {
    _controller.add(event);
  }

  void dispose() {
    _controller.close();
  }
}

final eventBusProvider = Provider<AppEventBus>((ref) {
  final bus = AppEventBus();
  ref.onDispose(() => bus.dispose());
  return bus;
});
