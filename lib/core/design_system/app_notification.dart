import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';

enum AppNotificationType {
  success,
  error,
  warning,
  info,
}

/// Sistema global de notificaciones flotantes estilo Uiverse (`akshat-patel28`).
class AppToast {
  static OverlayEntry? _activeEntry;
  static Timer? _dismissTimer;

  static void dismiss() {
    _dismissTimer?.cancel();
    _dismissTimer = null;
    _activeEntry?.remove();
    _activeEntry = null;
  }

  static void success(
    BuildContext context,
    String message, {
    String title = 'Guardado con éxito',
    Duration duration = const Duration(seconds: 4),
  }) {
    show(
      context,
      message: message,
      title: title,
      type: AppNotificationType.success,
      duration: duration,
    );
  }

  static void error(
    BuildContext context,
    String message, {
    String title = 'Ocurrió un error',
    Duration duration = const Duration(seconds: 4),
  }) {
    show(
      context,
      message: message,
      title: title,
      type: AppNotificationType.error,
      duration: duration,
    );
  }

  static void warning(
    BuildContext context,
    String message, {
    String title = 'Atención',
    Duration duration = const Duration(seconds: 4),
  }) {
    show(
      context,
      message: message,
      title: title,
      type: AppNotificationType.warning,
      duration: duration,
    );
  }

  static void info(
    BuildContext context,
    String message, {
    String title = 'Aviso',
    Duration duration = const Duration(seconds: 4),
  }) {
    show(
      context,
      message: message,
      title: title,
      type: AppNotificationType.info,
      duration: duration,
    );
  }

  static void show(
    BuildContext context, {
    required String message,
    String? title,
    AppNotificationType type = AppNotificationType.success,
    Duration duration = const Duration(seconds: 4),
  }) {
    if (!context.mounted) return;
    final overlay = Overlay.maybeOf(context, rootOverlay: true);
    if (overlay == null) return;

    dismiss();

    final effectiveTitle = title ??
        switch (type) {
          AppNotificationType.success => 'Guardado con éxito',
          AppNotificationType.error => 'Ocurrió un error',
          AppNotificationType.warning => 'Atención',
          AppNotificationType.info => 'Aviso',
        };

    late OverlayEntry entry;
    entry = OverlayEntry(
      builder: (ctx) => _FloatingToastWrapper(
        title: effectiveTitle,
        message: message,
        type: type,
        onClose: () {
          if (_activeEntry == entry) {
            dismiss();
          } else {
            entry.remove();
          }
        },
      ),
    );

    _activeEntry = entry;
    overlay.insert(entry);
    _dismissTimer = Timer(duration, () {
      if (_activeEntry == entry) {
        dismiss();
      }
    });
  }
}

class _FloatingToastWrapper extends StatefulWidget {
  final String title;
  final String message;
  final AppNotificationType type;
  final VoidCallback onClose;

  const _FloatingToastWrapper({
    required this.title,
    required this.message,
    required this.type,
    required this.onClose,
  });

  @override
  State<_FloatingToastWrapper> createState() => _FloatingToastWrapperState();
}

class _FloatingToastWrapperState extends State<_FloatingToastWrapper>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _opacity;
  late final Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 240),
    );
    _opacity = CurvedAnimation(parent: _controller, curve: Curves.easeOut);
    _slide = Tween<Offset>(
      begin: const Offset(0, -0.25),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.sizeOf(context).width;
    final topPadding = MediaQuery.paddingOf(context).top;
    final isWide = screenWidth >= 600;

    return Positioned(
      top: topPadding + 16,
      left: isWide ? null : 16,
      right: isWide ? 20 : 16,
      child: Align(
        alignment: isWide ? Alignment.topRight : Alignment.topCenter,
        child: Material(
          color: Colors.transparent,
          child: FadeTransition(
            opacity: _opacity,
            child: SlideTransition(
              position: _slide,
              child: AppNotificationCard(
                title: widget.title,
                message: widget.message,
                type: widget.type,
                onClose: widget.onClose,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Tarjeta de notificación fiel al diseño Uiverse (`akshat-patel28`).
class AppNotificationCard extends StatelessWidget {
  final String title;
  final String message;
  final AppNotificationType type;
  final VoidCallback? onClose;

  const AppNotificationCard({
    super.key,
    required this.title,
    required this.message,
    this.type = AppNotificationType.success,
    this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    final (Color accent, Color waveColor, Color iconBg, IconData icon) =
        switch (type) {
      AppNotificationType.success => (
          const Color(0xFF269B24),
          const Color(0x3A04E400),
          const Color(0x4804E400),
          Icons.check_rounded,
        ),
      AppNotificationType.error => (
          const Color(0xFFD93025),
          const Color(0x33FF3B30),
          const Color(0x40FF3B30),
          Icons.error_outline_rounded,
        ),
      AppNotificationType.warning => (
          const Color(0xFFC77700),
          const Color(0x33FF9500),
          const Color(0x40FF9500),
          Icons.warning_amber_rounded,
        ),
      AppNotificationType.info => (
          const Color(0xFF007AFF),
          const Color(0x33007AFF),
          const Color(0x40007AFF),
          Icons.info_outline_rounded,
        ),
    };

    final maxWidth = math.min(330.0, MediaQuery.sizeOf(context).width - 32);

    return Container(
      width: maxWidth,
      constraints: const BoxConstraints(minHeight: 80),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: const [
          BoxShadow(
            color: Color.fromRGBO(149, 157, 165, 0.20),
            blurRadius: 24,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Stack(
          children: [
            // Onda decorativa lateral (.wave)
            Positioned(
              left: -31,
              top: 32,
              child: Transform.rotate(
                angle: math.pi / 2,
                child: CustomPaint(
                  size: const Size(80, 48),
                  painter: _NotificationWavePainter(color: waveColor),
                ),
              ),
            ),

            // Contenido principal (.card)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
              child: ConstrainedBox(
                constraints: const BoxConstraints(minHeight: 60),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const SizedBox(width: 8),
                    // .icon-container
                    Container(
                      width: 35,
                      height: 35,
                      decoration: BoxDecoration(
                        color: iconBg,
                        shape: BoxShape.circle,
                      ),
                      alignment: Alignment.center,
                      child: Icon(
                        icon,
                        size: 17,
                        color: accent,
                      ),
                    ),
                    const SizedBox(width: 15),
                    // .message-text-container
                    Expanded(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: accent,
                              fontSize: 17,
                              fontWeight: FontWeight.w700,
                              height: 1.15,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            message,
                            maxLines: 3,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Color(0xFF555555),
                              fontSize: 14,
                              fontWeight: FontWeight.w400,
                              height: 1.25,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 10),
                    // .cross-icon
                    MouseRegion(
                      cursor: SystemMouseCursors.click,
                      child: GestureDetector(
                        onTap: onClose,
                        behavior: HitTestBehavior.opaque,
                        child: const Padding(
                          padding: EdgeInsets.all(4),
                          child: Icon(
                            Icons.close_rounded,
                            size: 18,
                            color: Color(0xFF555555),
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
    );
  }
}

class _NotificationWavePainter extends CustomPainter {
  final Color color;

  const _NotificationWavePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final path = Path()
      ..moveTo(0, h)
      ..lineTo(0, h * 0.45)
      ..cubicTo(w * 0.25, h * 0.15, w * 0.45, h * 0.85, w * 0.72, h * 0.42)
      ..cubicTo(w * 0.86, h * 0.20, w * 0.94, h * 0.35, w, h * 0.30)
      ..lineTo(w, h)
      ..close();

    canvas.drawPath(path, Paint()..color = color);
  }

  @override
  bool shouldRepaint(covariant _NotificationWavePainter oldDelegate) =>
      oldDelegate.color != color;
}
