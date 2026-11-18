import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:fishbit_finance/core/design_system/glass_action_hub_sheet.dart';
export 'package:fishbit_finance/core/design_system/floating_dock_layout.dart';

class MainNavigationShell extends ConsumerWidget {
  final Widget child;

  const MainNavigationShell({
    super.key,
    required this.child,
  });

  int _calculateSelectedIndex(BuildContext context) {
    final location = GoRouterState.of(context).matchedLocation;
    if (location.startsWith('/ponds')) return 1;
    if (location.startsWith('/warehouse')) return 2;
    if (location.startsWith('/bitacora') || location.startsWith('/records')) return 3;
    if (location.startsWith('/finance') || location.startsWith('/sales') || location.startsWith('/team') || location.startsWith('/creator') || location.startsWith('/ica')) {
      return 4; // Módulos del Hub Más
    }
    return 0;
  }

  void _onItemTapped(int index, BuildContext context) {
    HapticFeedback.lightImpact();
    switch (index) {
      case 0:
        context.go('/');
        break;
      case 1:
        context.go('/ponds');
        break;
      case 2:
        context.go('/warehouse');
        break;
      case 3:
        context.go('/bitacora');
        break;
      case 4:
        GlassActionHubSheet.show(context);
        break;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedIndex = _calculateSelectedIndex(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isKeyboardOpen = MediaQuery.viewInsetsOf(context).bottom > 0;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Stack(
        children: [
          // Pantalla actual activa
          Positioned.fill(child: child),

          // Barra Flotante <GooeyNav /> (React Bits)
          if (!isKeyboardOpen)
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: SafeArea(
                bottom: true,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(10, 0, 10, 12),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 520),
                      child: _GooeyNavBar(
                        activeIndex: selectedIndex,
                        isDark: isDark,
                        onSelect: (index) => _onItemTapped(index, context),
                        items: [
                          _GooeyNavItemData(
                            label: 'Inicio',
                            iconBuilder: (color, size) =>
                                _HomeSvgIcon(color: color, size: size),
                          ),
                          _GooeyNavItemData(
                            label: 'Estanques',
                            icon: Icons.water_drop_outlined,
                            activeIcon: Icons.water_drop_rounded,
                          ),
                          _GooeyNavItemData(
                            label: 'Almacén',
                            icon: Icons.inventory_2_outlined,
                            activeIcon: Icons.inventory_2_rounded,
                          ),
                          _GooeyNavItemData(
                            label: 'Bitácora',
                            icon: Icons.assignment_outlined,
                            activeIcon: Icons.assignment_rounded,
                          ),
                          const _GooeyNavItemData(
                            label: 'Más',
                            icon: Icons.grid_view_rounded,
                            activeIcon: Icons.grid_view_rounded,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _GooeyNavItemData {
  final String label;
  final IconData? icon;
  final IconData? activeIcon;
  final Widget Function(Color color, double size)? iconBuilder;

  const _GooeyNavItemData({
    required this.label,
    this.icon,
    this.activeIcon,
    this.iconBuilder,
  });
}

class _GooeyPillState {
  double mass = 0;
  double scale = 0;
  double velocity = 0;
  double outgoing = 0;
}

class _GooeyDrop {
  double x;
  double y;
  double vx = 0;
  double vy = 0;
  double mass;
  final double size;
  double given = 0;
  final int source;
  int index;
  final double leaveMs;
  double emerged = 0;
  double absorbed = 0;
  String state = 'waiting'; // 'waiting' | 'flying' | 'absorbing'
  double startMs = 0;
  double durationSec = 0.4;
  List<double> path = const [0, 0, 0, 0, 0, 0, 0, 0];

  _GooeyDrop({
    required this.x,
    required this.y,
    required this.mass,
    required this.size,
    required this.source,
    required this.index,
    required this.leaveMs,
  });
}

class _GooeyBox {
  final double cx;
  final double cy;
  final double hw;
  final double hh;

  const _GooeyBox(this.cx, this.cy, this.hw, this.hh);
}

class _GooeyBlob {
  final double x;
  final double y;
  final double r;
  final double tx;
  final double ty;

  const _GooeyBlob(this.x, this.y, this.r, this.tx, this.ty);
}

class _GooeyNavBar extends StatefulWidget {
  final List<_GooeyNavItemData> items;
  final int activeIndex;
  final bool isDark;
  final ValueChanged<int> onSelect;

  const _GooeyNavBar({
    required this.items,
    required this.activeIndex,
    required this.isDark,
    required this.onSelect,
  });

  @override
  State<_GooeyNavBar> createState() => _GooeyNavBarState();
}

class _GooeyNavBarState extends State<_GooeyNavBar>
    with SingleTickerProviderStateMixin {
  static const int _maxDrops = 32;
  static const int _animationTimeMs = 600;
  static const int _particleCount = 15;
  static const int _timeVarianceMs = 300;
  static const double _spread = 56.0;
  static const double _gooeyness = 0.5;
  static const double _wobble = 0.5;

  final GlobalKey _stageKey = GlobalKey();
  late List<GlobalKey> _itemKeys;
  final math.Random _rng = math.Random();

  late Ticker _ticker;
  Duration _lastElapsed = Duration.zero;
  double _clockMs = 0;

  List<Rect> _rects = const [];
  int _target = -1;
  final Map<int, _GooeyPillState> _pills = {};
  final List<_GooeyDrop> _drops = [];

  int _hoverIndex = -1;
  double _hoverX = 0;
  double _hoverY = 0;
  double _hoverW = 0;
  double _hoverH = 0;
  double _hoverAlpha = 0;

  Path _gooeyPath = Path();
  Rect? _hoverRect;

  @override
  void initState() {
    super.initState();
    _itemKeys = List.generate(widget.items.length, (_) => GlobalKey());
    _ticker = createTicker(_onTick);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _measure();
      _settle(widget.activeIndex);
    });
  }

  @override
  void didUpdateWidget(covariant _GooeyNavBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.items.length != widget.items.length) {
      _itemKeys = List.generate(widget.items.length, (_) => GlobalKey());
    }
    if (oldWidget.activeIndex != widget.activeIndex) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        _measure();
        _go(widget.activeIndex, animate: true);
      });
    }
  }

  @override
  void dispose() {
    _ticker.dispose();
    super.dispose();
  }

  double _clamp01(double v) => v < 0 ? 0 : (v > 1 ? 1 : v);

  double _travelEase(double t) {
    final x = _clamp01(t);
    return x < 0.5 ? 4 * x * x * x : 1 - math.pow(-2 * x + 2, 3) / 2;
  }

  double _bezier(double a, double b, double c, double d, double t) {
    final u = 1 - t;
    return u * u * u * a +
        3 * u * u * t * b +
        3 * u * t * t * c +
        t * t * t * d;
  }

  void _measure() {
    final stageCtx = _stageKey.currentContext;
    if (stageCtx == null) return;
    final stageBox = stageCtx.findRenderObject() as RenderBox?;
    if (stageBox == null || !stageBox.hasSize) return;

    final measured = <Rect>[];
    for (final key in _itemKeys) {
      final ctx = key.currentContext;
      final box = ctx?.findRenderObject() as RenderBox?;
      if (box == null || !box.hasSize) {
        measured.add(Rect.zero);
        continue;
      }
      final offset = box.localToGlobal(Offset.zero, ancestor: stageBox);
      measured.add(offset & box.size);
    }
    _rects = measured;
  }

  _GooeyPillState _pill(int index) {
    return _pills.putIfAbsent(index, () => _GooeyPillState());
  }

  Rect? _shape(int index, double amount) {
    if (index < 0 || index >= _rects.length) return null;
    final rect = _rects[index];
    if (rect.isEmpty || amount <= 0.002) return null;
    final h = rect.height *
        math.min(1.08, 0.42 + 0.58 * math.sqrt(math.max(0.0, amount)));
    final w = math.max(h, rect.width * math.pow(math.max(0.0, amount), 0.75));
    return Rect.fromCenter(
      center: rect.center,
      width: w,
      height: h,
    );
  }

  void _plan(_GooeyDrop drop, int index, double nowMs, bool fresh) {
    if (index < 0 || index >= _rects.length) return;
    final rect = _rects[index];
    if (rect.isEmpty) return;
    final ex = rect.center.dx + (_rng.nextDouble() - 0.5) * rect.width * 0.45;
    final ey = rect.center.dy + (_rng.nextDouble() - 0.5) * rect.height * 0.2;
    const base = _animationTimeMs / 1000.0;
    final variance = (_rng.nextDouble() - 0.5) * (_timeVarianceMs / 1000.0);
    final duration = math.max(
      0.15,
      base * (0.62 + _rng.nextDouble() * 0.32) + variance * 0.6,
    );
    final outAngle = _rng.nextDouble() * math.pi * 2;
    final intoAngle = _rng.nextDouble() * math.pi * 2;
    final burst = _spread * (0.7 + _rng.nextDouble() * 0.6);
    final swing = _spread * (0.55 + _rng.nextDouble() * 0.55);
    final carry = math.min(duration / 3, 0.12);

    drop.index = index;
    drop.startMs = nowMs;
    drop.durationSec = duration;
    drop.path = [
      drop.x,
      drop.y,
      fresh ? drop.x + math.cos(outAngle) * burst * 1.6 : drop.x + drop.vx * carry,
      fresh ? drop.y + math.sin(outAngle) * burst * 1.6 : drop.y + drop.vy * carry,
      ex + math.cos(intoAngle) * swing * 1.5,
      ey + math.sin(intoAngle) * swing * 1.5,
      ex,
      ey,
    ];
  }

  void _emit(int from, int to, double nowMs) {
    final source = _pills[from];
    if (source == null ||
        from < 0 ||
        from >= _rects.length ||
        to < 0 ||
        to >= _rects.length) {
      return;
    }
    final rect = _rects[from];
    if (rect.isEmpty || _rects[to].isEmpty) return;

    final available = source.mass - source.outgoing;
    if (available <= 0.002) return;
    final room = _maxDrops - _drops.length;
    final count = math.min(
      room,
      math.max(1, (_particleCount * available).round()),
    );
    if (count <= 0) return;

    const windowSec = (_animationTimeMs / 1000.0) * 0.16;
    for (int i = 0; i < count; i++) {
      final mass = available / count;
      source.outgoing += mass;
      _drops.add(
        _GooeyDrop(
          x: rect.center.dx + (_rng.nextDouble() - 0.5) * rect.width * 0.6,
          y: rect.center.dy + (_rng.nextDouble() - 0.5) * rect.height * 0.3,
          mass: mass,
          size: 0.8 + _rng.nextDouble() * 0.4,
          source: from,
          index: to,
          leaveMs: nowMs + _rng.nextDouble() * windowSec * 1000.0,
        ),
      );
    }
  }

  Path _tracePath(List<_GooeyBox> boxes, List<_GooeyBlob> blobs, double smooth) {
    if (boxes.isEmpty && blobs.isEmpty) return Path();
    if (boxes.length == 1 && blobs.isEmpty) {
      final b = boxes.first;
      final r = math.min(b.hw, b.hh);
      return Path()
        ..addRRect(
          RRect.fromRectAndRadius(
            Rect.fromCenter(center: Offset(b.cx, b.cy), width: b.hw * 2, height: b.hh * 2),
            Radius.circular(r),
          ),
        );
    }

    double minX = double.infinity;
    double minY = double.infinity;
    double maxX = double.negativeInfinity;
    double maxY = double.negativeInfinity;
    final pad = smooth + 4.0;

    for (final b in boxes) {
      minX = math.min(minX, b.cx - b.hw - pad);
      minY = math.min(minY, b.cy - b.hh - pad);
      maxX = math.max(maxX, b.cx + b.hw + pad);
      maxY = math.max(maxY, b.cy + b.hh + pad);
    }
    for (final blob in blobs) {
      final bx0 = math.min(blob.x, blob.x - blob.tx) - blob.r - pad;
      final by0 = math.min(blob.y, blob.y - blob.ty) - blob.r - pad;
      final bx1 = math.max(blob.x, blob.x - blob.tx) + blob.r + pad;
      final by1 = math.max(blob.y, blob.y - blob.ty) + blob.r + pad;
      minX = math.min(minX, bx0);
      minY = math.min(minY, by0);
      maxX = math.max(maxX, bx1);
      maxY = math.max(maxY, by1);
    }

    double field(double x, double y) {
      double d = 1e5;
      void merge(double value) {
        final h = _clamp01(0.5 + (0.5 * (value - d)) / smooth);
        d = value + (d - value) * h - smooth * h * (1.0 - h);
      }

      for (final box in boxes) {
        final r = math.min(box.hw, box.hh);
        final qx = (x - box.cx).abs() - box.hw + r;
        final qy = (y - box.cy).abs() - box.hh + r;
        final val = math.sqrt(math.max(qx, 0.0) * math.max(qx, 0.0) +
                math.max(qy, 0.0) * math.max(qy, 0.0)) +
            math.min(math.max(qx, qy), 0.0) -
            r;
        merge(val);
      }

      for (final blob in blobs) {
        final px = x - blob.x;
        final py = y - blob.y;
        final bx = -blob.tx;
        final by = -blob.ty;
        final span = bx * bx + by * by;
        final h = span > 0.0001 ? _clamp01((px * bx + py * by) / span) : 0.0;
        final dx = px - bx * h;
        final dy = py - by * h;
        final val = math.sqrt(dx * dx + dy * dy) - blob.r;
        if (val > d + smooth) continue;
        merge(val);
      }
      return d;
    }

    const double stepX = 2.0;
    const double stepY = 1.5;
    final path = Path();
    for (double y = minY; y < maxY; y += stepY) {
      final cy = y + stepY * 0.5;
      double previous = field(minX, cy);
      double? start = previous < 0 ? minX : null;
      for (double x = minX + stepX; x <= maxX + stepX; x += stepX) {
        final clampedX = math.min(x, maxX);
        final value = field(clampedX, cy);
        if ((previous < 0) != (value < 0)) {
          final denom = previous - value;
          final cross = denom.abs() > 1e-6
              ? x - stepX + (stepX * previous) / denom
              : clampedX;
          if (value < 0) {
            start = cross;
          } else if (start != null) {
            path.addRect(Rect.fromLTRB(start, y, cross, y + stepY + 0.15));
            start = null;
          }
        }
        previous = value;
      }
      if (start != null) {
        path.addRect(Rect.fromLTRB(start, y, maxX, y + stepY + 0.15));
      }
    }
    return path;
  }

  void _rebuildVisuals() {
    final fallbackHeight =
        (_target >= 0 && _target < _rects.length && !_rects[_target].isEmpty)
            ? _rects[_target].height
            : (_rects.isNotEmpty && !_rects[0].isEmpty ? _rects[0].height : 46.0);
    final smooth = fallbackHeight * (0.18 + 0.5 * _gooeyness);

    final boxes = <_GooeyBox>[];
    for (final entry in _pills.entries) {
      final box = _shape(entry.key, entry.value.scale);
      if (box != null) {
        boxes.add(_GooeyBox(box.center.dx, box.center.dy, box.width / 2, box.height / 2));
      }
    }

    final blobs = <_GooeyBlob>[];
    for (final drop in _drops) {
      if (drop.state == 'waiting') continue;
      final radius = 0.26 *
          fallbackHeight *
          drop.size *
          math.min(drop.emerged, 1.0 - drop.absorbed);
      if (radius <= 0.05) continue;
      final speed = math.sqrt(drop.vx * drop.vx + drop.vy * drop.vy);
      final length = math.min(radius * 1.1, speed * 0.018);
      blobs.add(
        _GooeyBlob(
          drop.x,
          drop.y,
          radius,
          speed > 0.01 ? (drop.vx / speed) * length : 0.0,
          speed > 0.01 ? (drop.vy / speed) * length : 0.0,
        ),
      );
    }

    _gooeyPath = _tracePath(boxes, blobs, smooth);
    _hoverRect = (_hoverAlpha > 0.005 && _hoverW > 1 && _hoverH > 1)
        ? Rect.fromCenter(
            center: Offset(_hoverX, _hoverY),
            width: _hoverW,
            height: _hoverH,
          )
        : null;
  }

  void _wake() {
    if (_ticker.isActive) return;
    _lastElapsed = Duration.zero;
    _ticker.start();
  }

  void _settle(int index) {
    _ticker.stop();
    _pills.clear();
    _drops.clear();
    _target = index;
    final state = _pill(index);
    state.mass = 1;
    state.scale = 1;
    state.velocity = 0;
    _rebuildVisuals();
    if (mounted) setState(() {});
  }

  void _go(int index, {required bool animate}) {
    if (index == _target) return;
    if (index < 0 ||
        index >= _rects.length ||
        _rects[index].isEmpty ||
        !animate ||
        _target < 0) {
      _settle(index);
      return;
    }
    final nowMs = _clockMs;
    _target = index;
    _pill(index);
    for (final drop in _drops) {
      drop.index = index;
      if (drop.state == 'flying') {
        _plan(drop, index, nowMs, false);
      } else if (drop.state == 'absorbing') {
        drop.state = 'flying';
        drop.mass *= 1 - drop.absorbed;
        drop.absorbed = 0;
        _plan(drop, index, nowMs, false);
      }
    }
    for (final from in [..._pills.keys]) {
      if (from != index) _emit(from, index, nowMs);
    }
    _wake();
  }

  void _onTick(Duration elapsed) {
    final dt = _lastElapsed == Duration.zero
        ? (1.0 / 60.0)
        : math.min(0.05, (elapsed - _lastElapsed).inMicroseconds / 1e6);
    _lastElapsed = elapsed;
    _clockMs += dt * 1000.0;
    final nowMs = _clockMs;

    const emergeTime = 0.09;
    const absorbTime = 0.12;

    for (int i = _drops.length - 1; i >= 0; i--) {
      final drop = _drops[i];
      if (drop.state == 'waiting') {
        if (nowMs < drop.leaveMs) continue;
        drop.state = 'flying';
        _plan(drop, drop.index, nowMs, true);
      }
      if (drop.state == 'flying') {
        drop.emerged = math.min(1.0, drop.emerged + dt / emergeTime);
        final source = _pills[drop.source];
        if (source != null && drop.given < drop.mass) {
          final step =
              math.min(drop.mass * (dt / emergeTime), drop.mass - drop.given);
          source.mass = math.max(0.0, source.mass - step);
          source.outgoing = math.max(0.0, source.outgoing - step);
          drop.given += step;
        }
        final t = _clamp01((nowMs - drop.startMs) / 1000.0 / drop.durationSec);
        final eased = _travelEase(t);
        final p = drop.path;
        final x = _bezier(p[0], p[2], p[4], p[6], eased);
        final y = _bezier(p[1], p[3], p[5], p[7], eased);
        if (dt > 0) {
          drop.vx = (x - drop.x) / dt;
          drop.vy = (y - drop.y) / dt;
        }
        drop.x = x;
        drop.y = y;
        if (t >= 1.0) drop.state = 'absorbing';
      }
      if (drop.state == 'absorbing') {
        final step = math.min(1.0 - drop.absorbed, dt / absorbTime);
        drop.absorbed += step;
        drop.vx *= 0.8;
        drop.vy *= 0.8;
        final host = _pill(drop.index);
        host.mass = math.min(1.0, host.mass + drop.mass * step);
        if (drop.absorbed >= 1.0) _drops.removeAt(i);
      }
    }

    const zeta = 1.0 - 0.72 * _wobble;
    const omega = 26.0;
    final steps = math.max(1, (dt / (1.0 / 240.0)).ceil());
    final h = dt / steps;
    final toRemove = <int>[];
    for (final entry in _pills.entries) {
      final index = entry.key;
      final state = entry.value;
      for (int n = 0; n < steps; n++) {
        state.velocity +=
            (omega * omega * (state.mass - state.scale) - 2 * zeta * omega * state.velocity) * h;
        state.scale += state.velocity * h;
      }
      if (index != _target &&
          state.mass <= 0.002 &&
          state.outgoing <= 0.002 &&
          state.scale.abs() < 0.004) {
        toRemove.add(index);
      }
    }
    for (final idx in toRemove) {
      _pills.remove(idx);
    }

    if (_hoverIndex >= 0 && _hoverIndex < _rects.length) {
      final rect = _rects[_hoverIndex];
      if (!rect.isEmpty) {
        final k = 1.0 - math.exp(-dt / 0.06);
        _hoverX += (rect.center.dx - _hoverX) * k;
        _hoverY += (rect.center.dy - _hoverY) * k;
        _hoverW += (rect.width - _hoverW) * k;
        _hoverH += (rect.height - _hoverH) * k;
      }
    }
    final hoverGoal = (_hoverIndex >= 0 && _hoverIndex != _target) ? 1.0 : 0.0;
    _hoverAlpha += (hoverGoal - _hoverAlpha) * (1.0 - math.exp(-dt / 0.08));

    _rebuildVisuals();

    final host = _pills[_target];
    final resting = _drops.isEmpty &&
        _pills.length == 1 &&
        host != null &&
        (host.mass - host.scale).abs() < 0.0008 &&
        host.velocity.abs() < 0.004;
    final hoverRect = (_hoverIndex >= 0 && _hoverIndex < _rects.length)
        ? _rects[_hoverIndex]
        : null;
    final hovering = (hoverGoal - _hoverAlpha).abs() > 0.003 ||
        (hoverRect != null &&
            ((hoverRect.center.dx - _hoverX).abs() +
                    (hoverRect.width - _hoverW).abs()) >
                0.1);

    if (resting && !hovering) {
      host.mass = 1;
      host.scale = 1;
      host.velocity = 0;
      _hoverAlpha = hoverGoal;
      _rebuildVisuals();
      _ticker.stop();
    }

    if (mounted) setState(() {});
  }

  void _onHoverEnter(int index) {
    _measure();
    if (index < 0 || index >= _rects.length || _rects[index].isEmpty) return;
    final rect = _rects[index];
    if (_hoverAlpha < 0.01) {
      _hoverX = rect.center.dx;
      _hoverY = rect.center.dy;
      _hoverW = rect.width;
      _hoverH = rect.height;
    }
    _hoverIndex = index;
    _wake();
  }

  void _onHoverExit() {
    _hoverIndex = -1;
    _wake();
  }

  Widget _buildItemsRow({required bool interactive, required Color ink, required Color muted}) {
    return Row(
      children: List.generate(widget.items.length, (index) {
        final item = widget.items[index];
        final isHovered = interactive && _hoverIndex == index;
        final isActive = index == widget.activeIndex;
        final color = !interactive
            ? ink
            : ((isHovered || isActive) ? ink : muted);

        final content = Container(
          key: interactive ? _itemKeys[index] : null,
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 6),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (item.iconBuilder != null)
                item.iconBuilder!(color, 20)
              else
                Icon(
                  isActive ? (item.activeIcon ?? item.icon) : item.icon,
                  color: color,
                  size: 20,
                ),
              const SizedBox(height: 3),
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  item.label,
                  style: TextStyle(
                    color: color,
                    fontSize: 11,
                    height: 1.0,
                    fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        );

        if (!interactive) {
          return Expanded(child: content);
        }

        return Expanded(
          child: Semantics(
            button: true,
            selected: isActive,
            label: item.label,
            child: MouseRegion(
              cursor: SystemMouseCursors.click,
              onEnter: (_) => _onHoverEnter(index),
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => widget.onSelect(index),
                child: content,
              ),
            ),
          ),
        );
      }),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = widget.isDark;
    final frameBg = isDark
        ? const Color.fromRGBO(38, 35, 46, 0.66)
        : const Color.fromRGBO(240, 240, 243, 0.80);
    final frameEdge = isDark
        ? Colors.white.withValues(alpha: 0.08)
        : const Color.fromRGBO(24, 24, 27, 0.07);
    final frameHighlight = isDark
        ? Colors.white.withValues(alpha: 0.07)
        : Colors.white.withValues(alpha: 0.95);
    final ink = isDark ? const Color(0xFFF4F4F5) : const Color(0xFF27272A);
    final muted = isDark
        ? const Color.fromRGBO(244, 244, 245, 0.62)
        : const Color.fromRGBO(39, 39, 42, 0.62);
    final pillColor =
        isDark ? const Color(0xFFF4F4F5) : const Color(0xFF27272A);
    final activeInk =
        isDark ? const Color(0xFF18161D) : const Color(0xFFFFFFFF);
    final hoverColor = isDark
        ? Colors.white.withValues(alpha: 0.08)
        : const Color.fromRGBO(24, 24, 27, 0.06);
    final shadowAlpha = isDark ? 0.40 : 0.20;

    return NotificationListener<SizeChangedLayoutNotification>(
      onNotification: (_) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          _measure();
          if (_drops.isEmpty) _settle(_target < 0 ? widget.activeIndex : _target);
        });
        return false;
      },
      child: SizeChangedLayoutNotifier(
        child: DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(999),
            boxShadow: isDark
                ? [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.80),
                      blurRadius: 44,
                      spreadRadius: -20,
                      offset: const Offset(0, 22),
                    ),
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.50),
                      blurRadius: 16,
                      spreadRadius: -8,
                      offset: const Offset(0, 6),
                    ),
                  ]
                : [
                    const BoxShadow(
                      color: Color.fromRGBO(24, 24, 27, 0.30),
                      blurRadius: 44,
                      spreadRadius: -22,
                      offset: Offset(0, 22),
                    ),
                    const BoxShadow(
                      color: Color.fromRGBO(24, 24, 27, 0.16),
                      blurRadius: 16,
                      spreadRadius: -10,
                      offset: Offset(0, 6),
                    ),
                  ],
          ),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              // Marco translúcido (.gooey-nav--framed + .gooey-nav__rim)
              Positioned.fill(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(999),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: frameBg,
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(color: frameEdge, width: 1),
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          stops: const [0.0, 0.14, 1.0],
                          colors: [
                            frameHighlight,
                            Colors.transparent,
                            Colors.transparent,
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),

              // Escenario (.gooey-nav__stage) con overflow libre para gotas
              Padding(
                padding: const EdgeInsets.all(6),
                child: MouseRegion(
                  onExit: (_) => _onHoverExit(),
                  child: Stack(
                    key: _stageKey,
                    clipBehavior: Clip.none,
                    children: [
                      // Lienzo metaball + hover (.gooey-nav__canvas)
                      Positioned.fill(
                        child: IgnorePointer(
                          child: CustomPaint(
                            painter: _GooeyCanvasPainter(
                              gooeyPath: _gooeyPath,
                              pillColor: pillColor,
                              hoverRect: _hoverRect,
                              hoverColor: hoverColor.withValues(
                                alpha: hoverColor.a * _hoverAlpha,
                              ),
                              shadowAlpha: shadowAlpha,
                            ),
                          ),
                        ),
                      ),

                      // Capa base interactiva (.gooey-nav__list)
                      _buildItemsRow(
                        interactive: true,
                        ink: ink,
                        muted: muted,
                      ),

                      // Capa invertida recortada por la masa líquida (.gooey-nav__list--active)
                      Positioned.fill(
                        child: IgnorePointer(
                          child: ClipPath(
                            clipper: _GooeyPathClipper(_gooeyPath),
                            child: _buildItemsRow(
                              interactive: false,
                              ink: activeInk,
                              muted: activeInk,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _GooeyCanvasPainter extends CustomPainter {
  final Path gooeyPath;
  final Color pillColor;
  final Rect? hoverRect;
  final Color hoverColor;
  final double shadowAlpha;

  const _GooeyCanvasPainter({
    required this.gooeyPath,
    required this.pillColor,
    required this.hoverRect,
    required this.hoverColor,
    required this.shadowAlpha,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (hoverRect != null && hoverColor.a > 0.002) {
      final hr = math.min(hoverRect!.width, hoverRect!.height) / 2;
      canvas.drawRRect(
        RRect.fromRectAndRadius(hoverRect!, Radius.circular(hr)),
        Paint()..color = hoverColor,
      );
    }

    if (!gooeyPath.getBounds().isEmpty) {
      // Sombra proyectada de la pastilla y gotas
      canvas.save();
      canvas.translate(0, 3);
      canvas.drawPath(
        gooeyPath,
        Paint()
          ..color = Colors.black.withValues(alpha: shadowAlpha * 0.45)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4.5),
      );
      canvas.restore();

      // Masa sólida líquida
      canvas.drawPath(
        gooeyPath,
        Paint()..color = pillColor,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _GooeyCanvasPainter oldDelegate) => true;
}

class _GooeyPathClipper extends CustomClipper<Path> {
  final Path path;

  const _GooeyPathClipper(this.path);

  @override
  Path getClip(Size size) => path;

  @override
  bool shouldReclip(covariant _GooeyPathClipper oldClipper) => true;
}

class _HomeSvgIcon extends StatelessWidget {
  final Color color;
  final double size;

  const _HomeSvgIcon({
    required this.color,
    required this.size,
  });

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size.square(size),
      painter: _HomeSvgPainter(color: color),
    );
  }
}

class _HomeSvgPainter extends CustomPainter {
  final Color color;

  const _HomeSvgPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final sx = size.width / 24.0;
    final sy = size.height / 24.0;
    canvas.save();
    canvas.scale(sx, sy);

    final path = Path()
      ..moveTo(3, 10.5651)
      ..cubicTo(3, 9.9907, 3, 9.70352, 3.07403, 9.43905)
      ..cubicTo(3.1396, 9.20478, 3.24737, 8.98444, 3.39203, 8.78886)
      ..cubicTo(3.55534, 8.56806, 3.78202, 8.39175, 4.23539, 8.03912)
      ..lineTo(11.0177, 2.764)
      ..cubicTo(11.369, 2.49075, 11.5447, 2.35412, 11.7387, 2.3016)
      ..cubicTo(11.9098, 2.25526, 12.0902, 2.25526, 12.2613, 2.3016)
      ..cubicTo(12.4553, 2.35412, 12.631, 2.49075, 12.9823, 2.764)
      ..lineTo(19.7646, 8.03913)
      ..cubicTo(20.218, 8.39175, 20.4447, 8.56806, 20.608, 8.78886)
      ..cubicTo(20.7526, 8.98444, 20.8604, 9.20478, 20.926, 9.43905)
      ..cubicTo(21, 9.70352, 21, 9.9907, 21, 10.5651)
      ..lineTo(21, 17.8)
      ..cubicTo(21, 18.9201, 21, 19.4801, 20.782, 19.908)
      ..cubicTo(20.5903, 20.2843, 20.2843, 20.5903, 19.908, 20.782)
      ..cubicTo(19.4802, 21, 18.9201, 21, 17.8, 21)
      ..lineTo(6.2, 21)
      ..cubicTo(5.07989, 21, 4.51984, 21, 4.09202, 20.782)
      ..cubicTo(3.71569, 20.5903, 3.40973, 20.2843, 3.21799, 19.908)
      ..cubicTo(3, 19.4801, 3, 18.9201, 3, 17.8)
      ..close();

    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    canvas.drawPath(path, paint);
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _HomeSvgPainter oldDelegate) =>
      oldDelegate.color != color;
}
