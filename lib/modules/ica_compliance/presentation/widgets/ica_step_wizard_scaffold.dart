import 'package:flutter/material.dart';
import 'package:fishbit_finance/core/design_system/app_colors.dart';
import 'package:fishbit_finance/core/design_system/app_typography.dart';
import 'package:fishbit_finance/core/design_system/glass_container.dart';

/// Estructura base para asistentes y formularios guiados paso a paso (Wizard)
/// con barra de progreso superior animada, navegación ergonómica y diseño Glassmorphism.
class IcaStepWizardScaffold extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color themeColor;
  final int currentStep;
  final int totalSteps;
  final List<String> stepTitles;
  final Widget child;
  final VoidCallback? onBack;
  final VoidCallback? onNext;
  final String nextLabel;
  final bool isNextLoading;
  final bool canGoNext;

  const IcaStepWizardScaffold({
    super.key,
    required this.title,
    required this.subtitle,
    required this.icon,
    this.themeColor = AppColors.cyanWater,
    required this.currentStep,
    required this.totalSteps,
    required this.stepTitles,
    required this.child,
    this.onBack,
    this.onNext,
    this.nextLabel = 'Siguiente Paso',
    this.isNextLoading = false,
    this.canGoNext = true,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final progress = (currentStep + 1) / totalSteps;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          onPressed: () {
            if (currentStep > 0 && onBack != null) {
              onBack!();
            } else {
              Navigator.of(context).pop();
            }
          },
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: AppTypography.titleMedium.copyWith(
                fontWeight: FontWeight.w900,
                color: isDark ? Colors.white : AppColors.textPrimaryLight,
                fontSize: 16,
              ),
            ),
            Text(
              subtitle,
              style: AppTypography.labelMicro.copyWith(
                color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Cerrar asistente',
            icon: const Icon(Icons.close_rounded, size: 22),
            onPressed: () => Navigator.of(context).pop(),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 720),
            child: Column(
              children: [
                // 1. Barra de Progreso y Pasos Superiores
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'PASO ${currentStep + 1} DE $totalSteps: ${stepTitles.length > currentStep ? stepTitles[currentStep].toUpperCase() : ""}',
                            style: TextStyle(
                              color: themeColor,
                              fontWeight: FontWeight.w800,
                              fontSize: 11,
                              letterSpacing: 1.1,
                            ),
                          ),
                          Text(
                            '${(progress * 100).toInt()}% completado',
                            style: TextStyle(
                              color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: TweenAnimationBuilder<double>(
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeInOut,
                          tween: Tween<double>(begin: 0, end: progress),
                          builder: (context, value, _) => LinearProgressIndicator(
                            value: value,
                            minHeight: 6,
                            backgroundColor: Colors.white.withValues(alpha: isDark ? 0.08 : 0.15),
                            valueColor: AlwaysStoppedAnimation<Color>(themeColor),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 6),

                // 2. Contenido Central del Paso
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    child: child,
                  ),
                ),

                // 3. Barra Inferior de Navegación del Paso a Paso
                Container(
                  padding: EdgeInsets.fromLTRB(
                    20,
                    14,
                    20,
                    14 + MediaQuery.viewPaddingOf(context).bottom,
                  ),
                  decoration: BoxDecoration(
                    color: isDark
                        ? AppColors.backgroundDark.withValues(alpha: 0.95)
                        : Colors.white.withValues(alpha: 0.95),
                    border: Border(
                      top: BorderSide(color: Colors.white.withValues(alpha: isDark ? 0.08 : 0.2)),
                    ),
                  ),
                  child: Row(
                    children: [
                      if (currentStep > 0) ...[
                        Expanded(
                          flex: 2,
                          child: OutlinedButton.icon(
                            style: OutlinedButton.styleFrom(
                              foregroundColor: isDark ? Colors.white70 : Colors.black87,
                              side: BorderSide(color: isDark ? Colors.white24 : Colors.black26),
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                            ),
                            icon: const Icon(Icons.arrow_back_rounded, size: 18),
                            label: const Text('Anterior', style: TextStyle(fontWeight: FontWeight.w700)),
                            onPressed: onBack,
                          ),
                        ),
                        const SizedBox(width: 12),
                      ],
                      Expanded(
                        flex: 3,
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: themeColor,
                            foregroundColor: Colors.black,
                            elevation: 4,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          ),
                          icon: isNextLoading
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black),
                                )
                              : Icon(
                                  currentStep == totalSteps - 1 ? Icons.check_circle_rounded : Icons.arrow_forward_rounded,
                                  size: 18,
                                ),
                          label: Text(
                            nextLabel,
                            style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 13),
                          ),
                          onPressed: canGoNext && !isNextLoading ? onNext : null,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
