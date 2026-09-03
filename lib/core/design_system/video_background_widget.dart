import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:fishbit_finance/core/design_system/app_colors.dart';

/// Widget de Video de Fondo optimizado para web, escritorio y movil con loop continuo y overlay estetico
class VideoBackgroundWidget extends StatefulWidget {
  final String assetPath;
  final Widget child;
  final double overlayOpacity;

  const VideoBackgroundWidget({
    super.key,
    required this.assetPath,
    required this.child,
    this.overlayOpacity = 0.55,
  });

  @override
  State<VideoBackgroundWidget> createState() => _VideoBackgroundWidgetState();
}

class _VideoBackgroundWidgetState extends State<VideoBackgroundWidget> {
  late VideoPlayerController _controller;
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _initializeVideo();
  }

  Future<void> _initializeVideo() async {
    _controller = VideoPlayerController.asset(widget.assetPath);
    try {
      await _controller.initialize();
      await _controller.setLooping(true);
      await _controller.setVolume(0.0); // Mute para evitar bloqueos de autoplay en web/navegadores
      await _controller.play();
      if (mounted) {
        setState(() {
          _isInitialized = true;
        });
      }
    } catch (_) {
      // Fallback a gradiente elegante si el formato de video no es compatible con el entorno
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // 1. Capa de Video escalado responsive (FittedBox Cover para soporte multi-pantalla)
        Positioned.fill(
          child: _isInitialized
              ? SizedBox.expand(
                  child: FittedBox(
                    fit: BoxFit.cover,
                    child: SizedBox(
                      width: _controller.value.size.width > 0 ? _controller.value.size.width : 1920,
                      height: _controller.value.size.height > 0 ? _controller.value.size.height : 1080,
                      child: VideoPlayer(_controller),
                    ),
                  ),
                )
              : Container(
                  decoration: const BoxDecoration(
                    gradient: RadialGradient(
                      center: Alignment(-0.6, -0.6),
                      radius: 1.4,
                      colors: [
                        Color(0xFF0D2538),
                        AppColors.backgroundDark,
                        Color(0xFF03070D),
                      ],
                    ),
                  ),
                ),
        ),

        // 2. Capa Overlay Oscura y Cinemática con tinte Glassmorphism
        Positioned.fill(
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  AppColors.backgroundDark.withValues(alpha: widget.overlayOpacity),
                  const Color(0xFF06101E).withValues(alpha: widget.overlayOpacity + 0.15),
                  AppColors.backgroundDark.withValues(alpha: 0.90),
                ],
              ),
            ),
          ),
        ),

        // 3. Orbes de luz ambientales para conservar la estetica Apple Aura
        Positioned(
          top: -80,
          left: -80,
          child: Container(
            width: 320,
            height: 320,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.cyanWater.withValues(alpha: 0.15),
            ),
          ),
        ),
        Positioned(
          bottom: -100,
          right: -100,
          child: Container(
            width: 380,
            height: 380,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.coralAction.withValues(alpha: 0.12),
            ),
          ),
        ),

        // 4. Contenido Principal UI (Formulario, botones, etc.)
        Positioned.fill(child: widget.child),
      ],
    );
  }
}
