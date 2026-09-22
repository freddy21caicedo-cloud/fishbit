import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fishbit_finance/core/design_system/app_colors.dart';
import 'package:fishbit_finance/core/design_system/app_typography.dart';
import 'package:fishbit_finance/core/design_system/glass_container.dart';
import 'package:fishbit_finance/modules/auth_tenant/domain/models/aquaculture_unit.dart';
import 'package:fishbit_finance/modules/auth_tenant/presentation/providers/auth_provider.dart';

/// Pantalla intermedia de selección de sede. Se muestra cuando el usuario tiene
/// 2 o más sedes y no hay ninguna preferencia guardada en este dispositivo.
/// No se puede saltar — [PopScope] bloquea el retroceso.
class SedeSelectionScreen extends ConsumerStatefulWidget {
  const SedeSelectionScreen({super.key});

  @override
  ConsumerState<SedeSelectionScreen> createState() => _SedeSelectionScreenState();
}

class _SedeSelectionScreenState extends ConsumerState<SedeSelectionScreen>
    with TickerProviderStateMixin {
  late final AnimationController _staggerController;
  final List<Animation<double>> _cardAnimations = [];
  bool _isSelecting = false;

  @override
  void initState() {
    super.initState();
    final units = ref.read(authProvider).units;

    _staggerController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 300 + units.length * 80),
    );

    for (int i = 0; i < units.length; i++) {
      final start = (i * 0.12).clamp(0.0, 0.9);
      final end = (start + 0.4).clamp(0.0, 1.0);
      _cardAnimations.add(
        CurvedAnimation(
          parent: _staggerController,
          curve: Interval(start, end, curve: Curves.easeOutCubic),
        ),
      );
    }
    // Pequeño delay para que la pantalla se pinte antes de iniciar la animación
    Timer(const Duration(milliseconds: 80), () {
      if (mounted) _staggerController.forward();
    });
  }

  @override
  void dispose() {
    _staggerController.dispose();
    super.dispose();
  }

  Future<void> _selectUnit(String unitId) async {
    if (_isSelecting) return;
    setState(() => _isSelecting = true);
    await ref.read(authProvider.notifier).selectActiveUnit(unitId);
    // El router reacciona a needsSedeSelection = false y navega a '/'
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final units = authState.units;
    final company = authState.currentCompany;

    return PopScope(
      canPop: false, // No se puede retroceder sin seleccionar una sede
      child: Scaffold(
        backgroundColor: AppColors.backgroundDark,
        body: Stack(
          children: [
            // Fondo — patrón de peces (mismo que login)
            Positioned.fill(
              child: Image.asset(
                'assets/images/fish_pattern_bg.jpg',
                repeat: ImageRepeat.repeat,
                fit: BoxFit.none,
                scale: 2.2,
                alignment: Alignment.topLeft,
              ),
            ),
            // Tinte translúcido
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      AppColors.backgroundDark.withValues(alpha: 0.55),
                      const Color(0xFF0A0F18).withValues(alpha: 0.50),
                      AppColors.backgroundDark.withValues(alpha: 0.65),
                    ],
                  ),
                ),
              ),
            ),
            // Orbe cyan
            Positioned(
              top: -60,
              left: -60,
              child: Container(
                width: 300,
                height: 300,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.cyanWater.withValues(alpha: 0.18),
                ),
              ),
            ),
            // Orbe coral
            Positioned(
              bottom: -80,
              right: -80,
              child: Container(
                width: 320,
                height: 320,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.coralAction.withValues(alpha: 0.15),
                ),
              ),
            ),

            // Contenido
            SafeArea(
              child: Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 32),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 440),
                    child: Column(
                      children: [
                        // Header
                        const Icon(
                          Icons.location_on_rounded,
                          color: AppColors.cyanWater,
                          size: 40,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Selecciona tu Sede',
                          style: AppTypography.titleLarge.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w900,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 6),
                        Text(
                          company?.nombreComercial ?? 'Elige la sede acuícola donde vas a trabajar hoy.',
                          style: AppTypography.bodySmall.copyWith(
                            color: AppColors.textSecondaryDark,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 28),

                        // Cards de sedes con animación staggered
                        ...List.generate(units.length, (index) {
                          final unit = units[index];
                          final anim = index < _cardAnimations.length
                              ? _cardAnimations[index]
                              : const AlwaysStoppedAnimation(1.0);

                          return AnimatedBuilder(
                            animation: anim,
                            builder: (context, child) => Transform.translate(
                              offset: Offset(0, 24 * (1 - anim.value)),
                              child: Opacity(
                                opacity: anim.value.clamp(0.0, 1.0),
                                child: child,
                              ),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: _SedeCard(
                                unit: unit,
                                isLoading: _isSelecting,
                                onTap: () => _selectUnit(unit.id),
                              ),
                            ),
                          );
                        }),

                        const SizedBox(height: 20),
                        Text(
                          'Puedes cambiar de sede en cualquier momento desde el menú superior.',
                          style: AppTypography.labelMicro.copyWith(
                            color: AppColors.textTertiaryDark,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SedeCard extends StatelessWidget {
  const _SedeCard({
    required this.unit,
    required this.onTap,
    required this.isLoading,
  });

  final AquacultureUnit unit;
  final VoidCallback onTap;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: isLoading ? null : onTap,
      child: GlassContainer(
        borderRadius: 20,
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        blur: 20,
        opacity: 0.14,
        borderColor: AppColors.cyanWater.withValues(alpha: 0.30),
        child: Row(
          children: [
            // Badge de sigla
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: AppColors.cyanWater.withValues(alpha: 0.18),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: AppColors.cyanWater.withValues(alpha: 0.45),
                  width: 1.5,
                ),
              ),
              child: Center(
                child: Text(
                  unit.sigla.isNotEmpty ? unit.sigla : '??',
                  style: const TextStyle(
                    color: AppColors.cyanWater,
                    fontWeight: FontWeight.w900,
                    fontSize: 14,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 14),
            // Nombre y ubicación
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    unit.nombre,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                      fontSize: 14.5,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (unit.ubicacion != null && unit.ubicacion!.isNotEmpty) ...[
                    const SizedBox(height: 3),
                    Row(
                      children: [
                        const Icon(
                          Icons.place_outlined,
                          color: AppColors.textSecondaryDark,
                          size: 12,
                        ),
                        const SizedBox(width: 3),
                        Expanded(
                          child: Text(
                            unit.ubicacion!,
                            style: AppTypography.labelMicro.copyWith(
                              color: AppColors.textSecondaryDark,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],

                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 10),
            // Chevron / indicador de acción
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: AppColors.cyanWater.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.arrow_forward_ios_rounded,
                color: AppColors.cyanWater,
                size: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
