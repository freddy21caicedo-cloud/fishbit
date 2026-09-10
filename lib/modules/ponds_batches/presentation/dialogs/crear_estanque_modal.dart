import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import 'package:fishbit_finance/core/design_system/app_colors.dart';
import 'package:fishbit_finance/core/design_system/app_typography.dart';
import 'package:fishbit_finance/core/design_system/glass_container.dart';
import 'package:fishbit_finance/core/design_system/glass_form_field.dart';
import 'package:fishbit_finance/core/design_system/glass_button.dart';
import 'package:fishbit_finance/modules/auth_tenant/presentation/providers/auth_provider.dart';
import 'package:fishbit_finance/modules/ponds_batches/domain/models/pond.dart';
import 'package:fishbit_finance/modules/ponds_batches/presentation/providers/ponds_provider.dart';

/// Modal interactivo Glassmorphic de 2 pasos para la creación y cubicaje de Estanques Físicos
class CrearEstanqueModal extends ConsumerStatefulWidget {
  const CrearEstanqueModal({super.key});

  static Future<Pond?> show(BuildContext context) {
    return showDialog<Pond>(
      context: context,
      barrierDismissible: true,
      barrierColor: Colors.black.withValues(alpha: 0.65),
      builder: (_) => const CrearEstanqueModal(),
    );
  }

  @override
  ConsumerState<CrearEstanqueModal> createState() => _CrearEstanqueModalState();
}

class _CrearEstanqueModalState extends ConsumerState<CrearEstanqueModal> {
  final _pageController = PageController();
  int _currentStep = 0;

  // Paso 1: Identificación y Estructura
  final _step1FormKey = GlobalKey<FormState>();
  final _nombreCtrl = TextEditingController();
  final _siglaCtrl = TextEditingController();
  String _tipoEstructura = 'Geomembrana Circular';

  final List<Map<String, dynamic>> _tiposEstructura = [
    {'label': 'Geomembrana Circular', 'icon': Icons.circle_outlined, 'desc': 'Tanque australiano / Zamorano'},
    {'label': 'Tierra Excavada', 'icon': Icons.landscape_outlined, 'desc': 'Estanque en tierra natural / grava'},
    {'label': 'Concreto / Mampostería', 'icon': Icons.foundation_outlined, 'desc': 'Estructura rígida de cemento'},
    {'label': 'Raceways', 'icon': Icons.view_column_outlined, 'desc': 'Canal de flujo rápido continuo'},
  ];

  // Paso 2: Geometría y Volumen
  final _step2FormKey = GlobalKey<FormState>();
  bool _esCircular = true;
  final _diametroCtrl = TextEditingController(text: '12.0');
  final _profundidadCtrl = TextEditingController(text: '1.2');
  final _largoCtrl = TextEditingController(text: '20.0');
  final _anchoCtrl = TextEditingController(text: '10.0');
  final _capacidadFinalCtrl = TextEditingController();

  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _recalcularVolumen();
  }

  @override
  void dispose() {
    _pageController.dispose();
    _nombreCtrl.dispose();
    _siglaCtrl.dispose();
    _diametroCtrl.dispose();
    _profundidadCtrl.dispose();
    _largoCtrl.dispose();
    _anchoCtrl.dispose();
    _capacidadFinalCtrl.dispose();
    super.dispose();
  }

  void _recalcularVolumen() {
    double volumen = 0.0;
    if (_esCircular) {
      final diametro = double.tryParse(_diametroCtrl.text.replaceAll(',', '.')) ?? 0.0;
      final prof = double.tryParse(_profundidadCtrl.text.replaceAll(',', '.')) ?? 0.0;
      final radio = diametro / 2.0;
      volumen = math.pi * radio * radio * prof;
    } else {
      final largo = double.tryParse(_largoCtrl.text.replaceAll(',', '.')) ?? 0.0;
      final ancho = double.tryParse(_anchoCtrl.text.replaceAll(',', '.')) ?? 0.0;
      final prof = double.tryParse(_profundidadCtrl.text.replaceAll(',', '.')) ?? 0.0;
      volumen = largo * ancho * prof;
    }
    setState(() {
      _capacidadFinalCtrl.text = volumen > 0 ? volumen.toStringAsFixed(1) : '0.0';
    });
  }

  void _goToStep(int step) {
    if (step == 1 && _step1FormKey.currentState != null && !_step1FormKey.currentState!.validate()) {
      return;
    }
    setState(() => _currentStep = step);
    _pageController.animateToPage(
      step,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  Future<void> _handleSave() async {
    if (_step2FormKey.currentState != null && !_step2FormKey.currentState!.validate()) {
      return;
    }

    final capacidadM3 = double.tryParse(_capacidadFinalCtrl.text.replaceAll(',', '.')) ?? 0.0;
    if (capacidadM3 <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('La capacidad del estanque debe ser mayor a 0 m³'),
          backgroundColor: AppColors.coralAction,
        ),
      );
      return;
    }

    setState(() => _isSaving = true);

    final auth = ref.read(authProvider);
    final user = auth.currentUser;
    final empresaId = auth.currentCompany?.id ?? user?.empresaId ?? 'c1000000-0000-0000-0000-000000000001';
    final unidadId = auth.activeUnitId ?? user?.unidadAcuicolaId ?? 'u1000000-0000-0000-0000-000000000001';

    double? largo = _esCircular ? null : double.tryParse(_largoCtrl.text.replaceAll(',', '.'));
    double? ancho = _esCircular ? null : double.tryParse(_anchoCtrl.text.replaceAll(',', '.'));
    double? prof = double.tryParse(_profundidadCtrl.text.replaceAll(',', '.'));

    final newPond = Pond(
      id: const Uuid().v4(),
      empresaId: empresaId,
      unidadAcuicolaId: unidadId,
      nombre: _nombreCtrl.text.trim(),
      sigla: _siglaCtrl.text.trim().toUpperCase(),
      capacidadM3: capacidadM3,
      largoM: largo,
      anchoM: ancho,
      profundidadM: prof,
      estado: PondStatus.available,
      creadoEn: DateTime.now(),
    );

    try {
      await ref.read(pondsProvider.notifier).addPond(newPond);
      if (mounted) {
        Navigator.of(context).pop(newPond);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ Estanque "${newPond.nombre}" (${newPond.capacidadM3.toInt()} m³) creado con éxito.'),
            backgroundColor: AppColors.greenBiomass,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSaving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al crear estanque: $e'),
            backgroundColor: AppColors.coralAction,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Center(
      child: SingleChildScrollView(
        child: Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 500),
            child: GlassContainer(
              borderRadius: 28,
              padding: const EdgeInsets.all(26),
              blur: 24,
              opacity: isDark ? 0.16 : 0.94,
              borderColor: AppColors.cyanWater.withValues(alpha: isDark ? 0.35 : 0.6),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Cabecera Modal
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: AppColors.cyanWater.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(
                              Icons.waves_rounded,
                              color: AppColors.cyanWater,
                              size: 22,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Nuevo Estanque de Cultivo',
                                style: AppTypography.titleMedium.copyWith(
                                  color: isDark ? Colors.white : AppColors.textPrimaryLight,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              Text(
                                'Infraestructura, cubicaje y capacidad de carga',
                                style: AppTypography.labelMicro.copyWith(
                                  color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      IconButton(
                        icon: Icon(
                          Icons.close_rounded,
                          color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                        ),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),

                  // Barra de Progreso Wizard
                  _buildStepIndicator(),
                  const SizedBox(height: 18),

                  // Contenido de los Pasos
                  SizedBox(
                    height: 400,
                    child: PageView(
                      controller: _pageController,
                      physics: const NeverScrollableScrollPhysics(),
                      children: [
                        _buildStep1(),
                        _buildStep2(),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStepIndicator() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Row(
        children: [
          _buildStepPill(1, 'Identificación y Tipo', _currentStep == 0, _currentStep > 0),
          Expanded(
            child: Container(
              height: 2,
              margin: const EdgeInsets.symmetric(horizontal: 8),
              color: _currentStep > 0 ? AppColors.cyanWater : Colors.white12,
            ),
          ),
          _buildStepPill(2, 'Dimensiones y Volumen', _currentStep == 1, false),
        ],
      ),
    );
  }

  Widget _buildStepPill(int step, String title, bool isActive, bool isDone) {
    final color = isDone ? AppColors.greenBiomass : (isActive ? AppColors.cyanWater : AppColors.textSecondaryDark);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 22,
          height: 22,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: color.withValues(alpha: 0.2),
            border: Border.all(color: color, width: 1.5),
          ),
          child: Center(
            child: isDone
                ? const Icon(Icons.check_rounded, size: 13, color: AppColors.greenBiomass)
                : Text('$step', style: TextStyle(color: color, fontSize: 10.5, fontWeight: FontWeight.w800)),
          ),
        ),
        const SizedBox(width: 6),
        Text(
          title,
          style: TextStyle(
            color: isActive || isDone ? Colors.white : AppColors.textSecondaryDark,
            fontSize: 11.5,
            fontWeight: isActive ? FontWeight.w800 : FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildStep1() {
    return Form(
      key: _step1FormKey,
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  flex: 3,
                  child: GlassFormField(
                    label: 'NOMBRE DEL ESTANQUE',
                    hint: 'Ej: Estanque 05',
                    controller: _nombreCtrl,
                    prefixIcon: Icons.water_drop_outlined,
                    textCapitalization: TextCapitalization.words,
                    textInputAction: TextInputAction.next,
                    isRequired: true,
                    showClearButton: true,
                    accentColor: AppColors.cyanWater,
                    onChanged: (val) {
                      if (_siglaCtrl.text.isEmpty && val.trim().isNotEmpty) {
                        final words = val.trim().split(' ');
                        if (words.length == 1) {
                          _siglaCtrl.text = words[0].substring(0, math.min(3, words[0].length)).toUpperCase();
                        } else {
                          _siglaCtrl.text = 'E${words.last}'.toUpperCase();
                        }
                      }
                    },
                    validator: (v) => v == null || v.trim().isEmpty ? 'Requerido' : null,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  flex: 2,
                  child: GlassFormField(
                    label: 'SIGLA TÉCNICA',
                    hint: 'E05',
                    controller: _siglaCtrl,
                    prefixIcon: Icons.tag_rounded,
                    textCapitalization: TextCapitalization.characters,
                    textInputAction: TextInputAction.done,
                    isRequired: true,
                    showClearButton: true,
                    accentColor: AppColors.cyanWater,
                    validator: (v) => v == null || v.trim().isEmpty ? 'Requerido' : null,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),

            Text(
              'TIPO DE ESTRUCTURA / MATERIAL *',
              style: AppTypography.bodySmall.copyWith(
                fontWeight: FontWeight.w700,
                fontSize: 11,
                letterSpacing: 0.6,
                color: AppColors.cyanWater,
              ),
            ),
            const SizedBox(height: 8),

            ..._tiposEstructura.map((item) {
              final isSelected = _tipoEstructura == item['label'];
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: InkWell(
                  onTap: () {
                    setState(() {
                      _tipoEstructura = item['label'] as String;
                      // Ajustar por defecto forma según estructura
                      if (_tipoEstructura.contains('Circular')) {
                        _esCircular = true;
                      } else if (_tipoEstructura.contains('Raceways') || _tipoEstructura.contains('Tierra')) {
                        _esCircular = false;
                      }
                      _recalcularVolumen();
                    });
                  },
                  borderRadius: BorderRadius.circular(14),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: isSelected ? AppColors.cyanWater.withValues(alpha: 0.14) : Colors.white.withValues(alpha: 0.04),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: isSelected ? AppColors.cyanWater : Colors.white.withValues(alpha: 0.1),
                        width: isSelected ? 1.5 : 1.0,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          item['icon'] as IconData,
                          color: isSelected ? AppColors.cyanWater : AppColors.textSecondaryDark,
                          size: 20,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                item['label'] as String,
                                style: TextStyle(
                                  color: isSelected ? Colors.white : AppColors.textSecondaryDark,
                                  fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                                  fontSize: 12.5,
                                ),
                              ),
                              Text(
                                item['desc'] as String,
                                style: AppTypography.labelMicro.copyWith(
                                  color: AppColors.textSecondaryDark,
                                  fontSize: 10,
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (isSelected)
                          const Icon(Icons.check_circle_rounded, color: AppColors.cyanWater, size: 18),
                      ],
                    ),
                  ),
                ),
              );
            }),

            const SizedBox(height: 10),
            GlassButton(
              label: 'Continuar a Dimensiones y Cubicaje ➔',
              backgroundColor: AppColors.cyanWater,
              onPressed: () => _goToStep(1),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStep2() {
    final capacidadM3 = double.tryParse(_capacidadFinalCtrl.text.replaceAll(',', '.')) ?? 0.0;
    final litros = (capacidadM3 * 1000).toInt();

    return Form(
      key: _step2FormKey,
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Selector de Morfología: Circular vs Rectangular
            Row(
              children: [
                Expanded(
                  child: InkWell(
                    onTap: () {
                      setState(() {
                        _esCircular = true;
                        _recalcularVolumen();
                      });
                    },
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 9),
                      decoration: BoxDecoration(
                        color: _esCircular ? AppColors.cyanWater.withValues(alpha: 0.18) : Colors.white.withValues(alpha: 0.04),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: _esCircular ? AppColors.cyanWater : Colors.white12,
                          width: _esCircular ? 1.5 : 1,
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.radio_button_checked_rounded, size: 16, color: _esCircular ? AppColors.cyanWater : AppColors.textSecondaryDark),
                          const SizedBox(width: 6),
                          Text('Circular / Cilíndrico', style: TextStyle(color: _esCircular ? Colors.white : AppColors.textSecondaryDark, fontSize: 12, fontWeight: FontWeight.w700)),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: InkWell(
                    onTap: () {
                      setState(() {
                        _esCircular = false;
                        _recalcularVolumen();
                      });
                    },
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 9),
                      decoration: BoxDecoration(
                        color: !_esCircular ? AppColors.cyanWater.withValues(alpha: 0.18) : Colors.white.withValues(alpha: 0.04),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: !_esCircular ? AppColors.cyanWater : Colors.white12,
                          width: !_esCircular ? 1.5 : 1,
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.crop_square_rounded, size: 16, color: !_esCircular ? AppColors.cyanWater : AppColors.textSecondaryDark),
                          const SizedBox(width: 6),
                          Text('Rectangular / Tierra', style: TextStyle(color: !_esCircular ? Colors.white : AppColors.textSecondaryDark, fontSize: 12, fontWeight: FontWeight.w700)),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),

            // Campos según morfología
            if (_esCircular)
              Row(
                children: [
                  Expanded(
                    child: GlassFormField(
                      label: 'DIÁMETRO (m)',
                      hint: '12.0',
                      controller: _diametroCtrl,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      prefixIcon: Icons.straighten_rounded,
                      accentColor: AppColors.cyanWater,
                      onChanged: (_) => _recalcularVolumen(),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: GlassFormField(
                      label: 'PROFUNDIDAD (m)',
                      hint: '1.2',
                      controller: _profundidadCtrl,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      prefixIcon: Icons.vertical_align_bottom_rounded,
                      accentColor: AppColors.cyanWater,
                      onChanged: (_) => _recalcularVolumen(),
                    ),
                  ),
                ],
              )
            else ...[
              Row(
                children: [
                  Expanded(
                    child: GlassFormField(
                      label: 'LARGO (m)',
                      hint: '20.0',
                      controller: _largoCtrl,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      prefixIcon: Icons.straighten_rounded,
                      accentColor: AppColors.cyanWater,
                      onChanged: (_) => _recalcularVolumen(),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: GlassFormField(
                      label: 'ANCHO (m)',
                      hint: '10.0',
                      controller: _anchoCtrl,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      prefixIcon: Icons.width_normal_rounded,
                      accentColor: AppColors.cyanWater,
                      onChanged: (_) => _recalcularVolumen(),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              GlassFormField(
                label: 'PROFUNDIDAD MEDIA DE AGUA (m)',
                hint: '1.2',
                controller: _profundidadCtrl,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                prefixIcon: Icons.vertical_align_bottom_rounded,
                accentColor: AppColors.cyanWater,
                onChanged: (_) => _recalcularVolumen(),
              ),
            ],
            const SizedBox(height: 14),

            // Campo de Capacidad Final en m3 (Editable directamente)
            GlassFormField(
              label: 'CAPACIDAD DE VOLUMEN TOTAL (m³)',
              hint: 'Calculado automáticamente o escribe manual',
              controller: _capacidadFinalCtrl,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              prefixIcon: Icons.water_rounded,
              isRequired: true,
              accentColor: AppColors.cyanWater,
              validator: (v) {
                final val = double.tryParse(v?.replaceAll(',', '.') ?? '') ?? 0.0;
                if (val <= 0) return 'Ingresa un volumen válido en m³';
                return null;
              },
            ),
            const SizedBox(height: 10),

            // Indicador de Liquidación / Litros en Vivo
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: AppColors.cyanWater.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.cyanWater.withValues(alpha: 0.3)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.calculate_outlined, color: AppColors.cyanWater, size: 18),
                      const SizedBox(width: 8),
                      Text(
                        'Volumen Equivalente:',
                        style: AppTypography.bodySmall.copyWith(color: Colors.white, fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                  Text(
                    '${capacidadM3.toStringAsFixed(1)} m³ (${litros.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.')} L)',
                    style: AppTypography.titleSmall.copyWith(color: AppColors.cyanWater, fontWeight: FontWeight.w900),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Botones Volver y Guardar
            Row(
              children: [
                Expanded(
                  flex: 1,
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white,
                      side: BorderSide(color: Colors.white.withValues(alpha: 0.25)),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                    onPressed: () => _goToStep(0),
                    child: const Text('⬅ Volver', style: TextStyle(fontWeight: FontWeight.w700)),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  flex: 2,
                  child: GlassButton(
                    label: 'Guardar Estanque',
                    backgroundColor: AppColors.cyanWater,
                    isLoading: _isSaving,
                    onPressed: _handleSave,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
