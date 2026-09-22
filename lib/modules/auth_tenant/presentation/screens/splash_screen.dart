import 'package:flutter/material.dart';
import 'package:fishbit_finance/core/design_system/app_colors.dart';
import 'package:fishbit_finance/core/design_system/app_typography.dart';

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
          // Orbe cyan superior-izquierdo (mismo que login para transición fluida)
          Positioned(
            top: -80,
            left: -80,
            child: Container(
              width: 320,
              height: 320,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.cyanWater.withValues(alpha: 0.18),
              ),
            ),
          ),
          // Orbe coral inferior-derecho
          Positioned(
            bottom: -100,
            right: -100,
            child: Container(
              width: 360,
              height: 360,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.coralAction.withValues(alpha: 0.15),
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
