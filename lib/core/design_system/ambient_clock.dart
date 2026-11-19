import 'dart:async';

/// Reloj compartido para animaciones decorativas continuas (fondos, bordes
/// estelares, etc.).
///
/// Motivo: en Flutter Web (CanvasKit) cada frame vuelve a componer toda la
/// escena, incluidos los `BackdropFilter` (blur) del header, la barra de
/// navegación y los modales. Un `Ticker` decorativo a 60 Hz obliga a recalcular
/// esos blur 60 veces por segundo aunque el usuario no esté interactuando.
///
/// Este reloj:
/// - Emite a ~30 FPS (visualmente equivalente para movimientos lentos).
/// - Es único: todos los suscriptores pintan en el MISMO frame, evitando que
///   varios temporizadores desfasados vuelvan a sumar 60+ frames/seg.
/// - Se detiene por completo cuando no hay suscriptores (0 % CPU/GPU en reposo).
class AmbientClock {
  AmbientClock._();

  static final AmbientClock instance = AmbientClock._();

  /// ~30 FPS.
  static const Duration frameInterval = Duration(milliseconds: 33);

  final Stopwatch _stopwatch = Stopwatch();
  final List<void Function(Duration elapsed)> _listeners = [];
  Timer? _timer;

  bool get isRunning => _timer != null;

  void subscribe(void Function(Duration elapsed) listener) {
    if (!_listeners.contains(listener)) {
      _listeners.add(listener);
    }
    if (_timer == null) {
      _stopwatch.start();
      _timer = Timer.periodic(frameInterval, (_) => _tick());
    }
  }

  void unsubscribe(void Function(Duration elapsed) listener) {
    _listeners.remove(listener);
    if (_listeners.isEmpty) {
      _timer?.cancel();
      _timer = null;
      _stopwatch.stop();
    }
  }

  void _tick() {
    final elapsed = _stopwatch.elapsed;
    for (final listener in List.of(_listeners)) {
      listener(elapsed);
    }
  }
}
