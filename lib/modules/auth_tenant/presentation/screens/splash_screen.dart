import 'package:flutter/material.dart';
import 'package:fishbit_finance/core/design_system/app_colors.dart';
import 'package:fishbit_finance/core/design_system/app_typography.dart';
import 'package:fishbit_finance/core/design_system/silk_background.dart';

/// Pantalla de carga inicial que se muestra mientras [AuthNotifier._initSession()]
/// resuelve la sesión activa. Evita el parpadeo de la pantalla de login al arrancar.
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    );
    _fadeAnim = CurvedAnimation(parent: _controller, curve: Curves.easeOut);
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      body: Stack(
        children: [
          // Fondo animado <Silk /> (React Bits)
          const Positioned.fill(
            child: SilkBackground(
              color: Color(0xFF06B6D4),
              sheenColor: Color(0xFFF43F5E),
              speed: 5.0,
              scale: 1.0,
              rotation: 0.0,
              sheen: 0.5,
              depth: 0.5,
              glow: 0.3,
              noiseIntensity: 1.5,
              mouseInteraction: true,
              clickRipple: true,
              intro: true,
            ),
          ),

          // Velo radial sutil para asegurar legibilidad del logo sobre el shader
          Positioned.fill(
            child: IgnorePointer(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    center: Alignment.center,
                    radius: 0.85,
                    colors: [
                      Colors.black.withValues(alpha: 0.48),
                      Colors.black.withValues(alpha: 0.16),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
          ),

          // Contenido central
          Center(
            child: FadeTransition(
              opacity: _fadeAnim,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Logo FishBit.
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Fish',
                        style: TextStyle(
                          fontSize: 44,
                          fontWeight: FontWeight.w900,
                          letterSpacing: -1.5,
                          color: AppColors.cyanWater,
                          shadows: [
                            Shadow(
                              color: AppColors.cyanWater.withValues(alpha: 0.7),
                              blurRadius: 24,
                            ),
                          ],
                        ),
                      ),
                      Text(
                        'Bit.',
                        style: TextStyle(
                          fontSize: 44,
                          fontWeight: FontWeight.w900,
                          letterSpacing: -1.5,
                          color: AppColors.coralAction,
                          shadows: [
                            Shadow(
                              color: AppColors.coralAction.withValues(alpha: 0.7),
                              blurRadius: 24,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'GESTIÓN ACUÍCOLA',
                    style: AppTypography.labelMicro.copyWith(
                      color: AppColors.textSecondaryDark,
                      letterSpacing: 2.5,
                      fontSize: 11,
                    ),
                  ),
                  const SizedBox(height: 40),

                  // Spinner glassmorphic minimalista
                  SizedBox(
                    width: 36,
                    height: 36,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        AppColors.cyanWater.withValues(alpha: 0.8),
                      ),
                      backgroundColor: Colors.white.withValues(alpha: 0.08),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
