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

/// Modal interactivo unificado para la creación, parametrización y cubicaje de Estanques Físicos
/// Sigue el estándar de los formularios de registro de FishBit (scroll fluido, sin PageView restringido,
/// sigla técnica auto-asignada sin réplicas y soporte completo para modo claro/oscuro).
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
  final _formKey = GlobalKey<FormState>();

  // Identificación
  final _nombreCtrl = TextEditingController();
  String _siglaGenerada = '';
  String _tipoEstructura = 'Geomembrana Circular';

  final List<Map<String, dynamic>> _tiposEstructura = [
    {'label': 'Geomembrana Circular', 'icon': Icons.circle_outlined, 'desc': 'Tanque australiano / Zamorano'},
    {'label': 'Tierra Excavada', 'icon': Icons.landscape_outlined, 'desc': 'Estanque en tierra natural / grava'},
    {'label': 'Concreto / Mampostería', 'icon': Icons.foundation_outlined, 'desc': 'Estructura rígida de cemento'},
    {'label': 'Raceways', 'icon': Icons.view_column_outlined, 'desc': 'Canal de flujo rápido continuo'},
  ];

  // Geometría y Volumen
  bool _esCircular = true;
  final _diametroCtrl = TextEditingController(text: '12.0');
  final _profundidadCtrl = TextEditingController(text: '1.2');
  final _largoCtrl = TextEditingController(text: '20.0');
  final _anchoCtrl = TextEditingController(text: '10.0');
  final _capacidadFinalCtrl = TextEditingController();

  bool _isSaving = false;
  bool _hasManuallyEditedCapacidad = false;

  @override
  void initState() {
    super.initState();
    _nombreCtrl.addListener(_onNombreChanged);
    _diametroCtrl.addListener(_recalcularVolumen);
    _profundidadCtrl.addListener(_recalcularVolumen);
    _largoCtrl.addListener(_recalcularVolumen);
    _anchoCtrl.addListener(_recalcularVolumen);
    _recalcularVolumen();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _actualizarSigla();
  }

  @override
  void dispose() {
    _nombreCtrl.dispose();
    _diametroCtrl.dispose();
    _profundidadCtrl.dispose();
    _largoCtrl.dispose();
    _anchoCtrl.dispose();
    _capacidadFinalCtrl.dispose();
    super.dispose();
  }

  void _onNombreChanged() {
    _actualizarSigla();
  }

  /// Calcula una sigla técnica única, secuencial y libre de réplicas en la unidad activa
  void _actualizarSigla() {
    final auth = ref.read(authProvider);
    final user = auth.currentUser;
    final unidadId = auth.activeUnitId ?? user?.unidadAcuicolaId ?? '';

    final pondsState = ref.read(pondsProvider);
    final existingPonds = pondsState.ponds.where((p) => p.unidadAcuicolaId == unidadId).toList();
    final newSigla = _computeUniqueSigla(_nombreCtrl.text, existingPonds);

    if (newSigla != _siglaGenerada) {
      setState(() {
        _siglaGenerada = newSigla;
      });
    }
  }

  static String _computeUniqueSigla(String pondName, List<Pond> existingPonds) {
    final existingSiglas = existingPonds.map((p) => p.sigla.toUpperCase().trim()).toSet();

    // 1. Si el nombre contiene números (ej: "Estanque 05", "Tanque 3")
    final match = RegExp(r'\d+').firstMatch(pondName);
    if (match != null) {
      final numberStr = match.group(0)!;
      final number = int.tryParse(numberStr);
      if (number != null) {
        final candidate = 'E${number.toString().padLeft(2, '0')}';
        if (!existingSiglas.contains(candidate)) {
          return candidate;
        }
      }
    } else if (pondName.trim().isNotEmpty) {
      // 2. Extraer iniciales de palabras significativas
      final words = pondName.trim().split(RegExp(r'\s+')).where((w) => w.isNotEmpty).toList();
      if (words.length > 1) {
        final acronym = words.map((w) => w[0].toUpperCase()).take(4).join();
        if (acronym.isNotEmpty && !existingSiglas.contains(acronym)) {
          return acronym;
        }
      }
    }

    // 3. Fallback correlativo garantizado libre de colisiones: E01, E02, E03...
    for (int i = 1; i <= 999; i++) {
      final candidate = 'E${i.toString().padLeft(2, '0')}';
      if (!existingSiglas.contains(candidate)) {
        return candidate;
      }
    }

    return 'E${existingPonds.length + 1}';
  }

  double _parseDecimal(String text) {
    return double.tryParse(text.replaceAll(',', '.').trim()) ?? 0.0;
  }

  void _recalcularVolumen() {
    double volumen = 0.0;
    if (_esCircular) {
      final diametro = _parseDecimal(_diametroCtrl.text);
      final prof = _parseDecimal(_profundidadCtrl.text);
      final radio = diametro / 2.0;
      volumen = math.pi * radio * radio * prof;
    } else {
      final largo = _parseDecimal(_largoCtrl.text);
      final ancho = _parseDecimal(_anchoCtrl.text);
      final prof = _parseDecimal(_profundidadCtrl.text);
      volumen = largo * ancho * prof;
    }

    if (!_hasManuallyEditedCapacidad) {
      setState(() {
        _capacidadFinalCtrl.text = volumen > 0 ? volumen.toStringAsFixed(1) : '0.0';
      });
    } else {
      setState(() {});
    }
  }

  Future<void> _handleSave() async {
    if (_formKey.currentState != null && !_formKey.currentState!.validate()) {
      return;
    }

    final capacidadM3 = _parseDecimal(_capacidadFinalCtrl.text);
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

    String? unidadSigla;
    try {
      final activeUnit = auth.units.firstWhere((u) => u.id == unidadId);
      unidadSigla = activeUnit.sigla;
    } catch (_) {
      unidadSigla = 'PRIN';
    }

    final double? largo = _esCircular ? null : _parseDecimal(_largoCtrl.text);
    final double? ancho = _esCircular ? null : _parseDecimal(_anchoCtrl.text);
    final prof = _parseDecimal(_profundidadCtrl.text);

    final newPond = Pond(
      id: const Uuid().v4(),
      empresaId: empresaId,
      unidadAcuicolaId: unidadId,
      unidadAcuicolaSigla: unidadSigla,
      tipoEstructura: _tipoEstructura,
      nombre: _nombreCtrl.text.trim(),
      sigla: _siglaGenerada,
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
            content: Text('✅ Estanque "${newPond.nombre}" (${newPond.sigla} - ${newPond.capacidadM3.toInt()} m³) creado con éxito.'),
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
    final auth = ref.watch(authProvider);
    final activeUnitId = auth.activeUnitId ?? auth.currentUser?.unidadAcuicolaId;
    final activeUnit = auth.units.where((u) => u.id == activeUnitId).firstOrNull;
    final activeUnitName = activeUnit?.nombre ?? 'Sede Principal';
    final activeUnitSigla = activeUnit?.sigla ?? 'PRIN';

    final capacidadM3 = _parseDecimal(_capacidadFinalCtrl.text);
    final litros = (capacidadM3 * 1000).toInt();

    return Center(
      child: Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 500),
          child: GlassContainer(
            borderRadius: 24,
            padding: const EdgeInsets.all(22),
            blur: 24,
            opacity: isDark ? 0.16 : 0.94,
            borderColor: AppColors.cyanWater.withValues(alpha: isDark ? 0.35 : 0.25),
            child: Form(
              key: _formKey,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // ─── 1. Cabecera del Modal ─────────────────────────────────
                    Row(
                      children: [
                        Expanded(
                          child: Row(
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
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Nuevo Estanque de Cultivo',
                                      style: AppTypography.titleMedium.copyWith(
                                        color: isDark ? Colors.white : AppColors.textPrimaryLight,
                                        fontWeight: FontWeight.w800,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    Text(
                                      'Infraestructura física y cubicaje hidráulico',
                                      style: TextStyle(
                                        color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                                        fontSize: 11,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
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
                    const SizedBox(height: 14),

                    // ─── 2. Sede Acuícola Asignada ─────────────────────────────
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.03),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isDark ? Colors.white.withValues(alpha: 0.1) : AppColors.glassBorderLight,
                        ),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.location_on_outlined, size: 16, color: AppColors.cyanWater),
                          const SizedBox(width: 8),
                          Text(
                            'SEDE ASIGNADA:',
                            style: AppTypography.labelMicro.copyWith(
                              color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              activeUnitName,
                              style: TextStyle(
                                color: isDark ? Colors.white : AppColors.textPrimaryLight,
                                fontWeight: FontWeight.w700,
                                fontSize: 12,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppColors.cyanWater.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              activeUnitSigla,
                              style: const TextStyle(
                                color: AppColors.cyanWater,
                                fontWeight: FontWeight.w800,
                                fontSize: 10,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),

                    // ─── 3. Nombre del Estanque y Sigla Bloqueada ───────────────
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
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
                            validator: (v) => v == null || v.trim().isEmpty ? 'Ingresa el nombre del estanque' : null,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          flex: 2,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Text(
                                    'SIGLA TÉCNICA',
                                    style: AppTypography.labelMicro.copyWith(
                                      color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  const Icon(Icons.lock_rounded, size: 11, color: AppColors.cyanWater),
                                ],
                              ),
                              const SizedBox(height: 6),
                              Container(
                                height: 48,
                                padding: const EdgeInsets.symmetric(horizontal: 12),
                                decoration: BoxDecoration(
                                  color: isDark ? Colors.white.withValues(alpha: 0.04) : Colors.black.withValues(alpha: 0.03),
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(
                                    color: AppColors.cyanWater.withValues(alpha: isDark ? 0.35 : 0.4),
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(Icons.tag_rounded, size: 16, color: AppColors.cyanWater),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        _siglaGenerada,
                                        style: TextStyle(
                                          color: isDark ? Colors.white : AppColors.textPrimaryLight,
                                          fontWeight: FontWeight.w800,
                                          fontSize: 14,
                                          letterSpacing: 0.8,
                                        ),
                                      ),
                                    ),
                                    Tooltip(
                                      message: 'Asignada automáticamente por el sistema para evitar réplicas.',
                                      child: Icon(
                                        Icons.info_outline_rounded,
                                        size: 14,
                                        color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),

                    // ─── 4. Tipo de Estructura / Material ──────────────────────
                    Text(
                      'TIPO DE ESTRUCTURA Y MATERIAL *',
                      style: AppTypography.labelMicro.copyWith(
                        color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _tiposEstructura.map((item) {
                        final isSelected = _tipoEstructura == item['label'];
                        return InkWell(
                          onTap: () {
                            setState(() {
                              _tipoEstructura = item['label'] as String;
                              if (_tipoEstructura.contains('Circular')) {
                                _esCircular = true;
                              } else {
                                _esCircular = false;
                              }
                              _recalcularVolumen();
                            });
                          },
                          borderRadius: BorderRadius.circular(12),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 150),
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? AppColors.cyanWater.withValues(alpha: isDark ? 0.18 : 0.15)
                                  : (isDark ? Colors.white.withValues(alpha: 0.04) : Colors.black.withValues(alpha: 0.03)),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: isSelected
                                    ? AppColors.cyanWater
                                    : (isDark ? Colors.white.withValues(alpha: 0.1) : AppColors.glassBorderLight),
                                width: isSelected ? 1.4 : 1.0,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  item['icon'] as IconData,
                                  size: 16,
                                  color: isSelected
                                      ? AppColors.cyanWater
                                      : (isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight),
                                ),
                                const SizedBox(width: 6),
                                Flexible(
                                  child: Text(
                                    item['label'] as String,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      color: isSelected
                                          ? (isDark ? Colors.white : AppColors.cyanWaterTextLight)
                                          : (isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight),
                                      fontSize: 11.5,
                                      fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 14),

                    // ─── 5. Selector de Morfología Geométrica ──────────────────
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
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              decoration: BoxDecoration(
                                color: _esCircular
                                    ? AppColors.cyanWater.withValues(alpha: isDark ? 0.18 : 0.15)
                                    : (isDark ? Colors.white.withValues(alpha: 0.04) : Colors.black.withValues(alpha: 0.03)),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: _esCircular
                                      ? AppColors.cyanWater
                                      : (isDark ? Colors.white.withValues(alpha: 0.1) : AppColors.glassBorderLight),
                                  width: _esCircular ? 1.5 : 1,
                                ),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    _esCircular ? Icons.radio_button_checked_rounded : Icons.radio_button_off_rounded,
                                    size: 15,
                                    color: _esCircular
                                        ? AppColors.cyanWater
                                        : (isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight),
                                  ),
                                  const SizedBox(width: 6),
                                  Flexible(
                                    child: Text(
                                      'Circular / Cilíndrico',
                                      style: TextStyle(
                                        color: _esCircular
                                            ? (isDark ? Colors.white : AppColors.cyanWaterTextLight)
                                            : (isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight),
                                        fontSize: 11.5,
                                        fontWeight: FontWeight.w700,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
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
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              decoration: BoxDecoration(
                                color: !_esCircular
                                    ? AppColors.cyanWater.withValues(alpha: isDark ? 0.18 : 0.15)
                                    : (isDark ? Colors.white.withValues(alpha: 0.04) : Colors.black.withValues(alpha: 0.03)),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: !_esCircular
                                      ? AppColors.cyanWater
                                      : (isDark ? Colors.white.withValues(alpha: 0.1) : AppColors.glassBorderLight),
                                  width: !_esCircular ? 1.5 : 1,
                                ),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    !_esCircular ? Icons.radio_button_checked_rounded : Icons.radio_button_off_rounded,
                                    size: 15,
                                    color: !_esCircular
                                        ? AppColors.cyanWater
                                        : (isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight),
                                  ),
                                  const SizedBox(width: 6),
                                  Flexible(
                                    child: Text(
                                      'Rectangular / Tierra',
                                      style: TextStyle(
                                        color: !_esCircular
                                            ? (isDark ? Colors.white : AppColors.cyanWaterTextLight)
                                            : (isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight),
                                        fontSize: 11.5,
                                        fontWeight: FontWeight.w700,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // ─── 6. Dimensiones Físicas y Profundidad ──────────────────
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
                              validator: (v) {
                                final val = _parseDecimal(v ?? '');
                                if (val <= 0) return 'Diámetro > 0';
                                return null;
                              },
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
                              validator: (v) {
                                final val = _parseDecimal(v ?? '');
                                if (val <= 0) return 'Profundidad > 0';
                                return null;
                              },
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
                              validator: (v) {
                                final val = _parseDecimal(v ?? '');
                                if (val <= 0) return 'Largo > 0';
                                return null;
                              },
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
                              validator: (v) {
                                final val = _parseDecimal(v ?? '');
                                if (val <= 0) return 'Ancho > 0';
                                return null;
                              },
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
                              validator: (v) {
                                final val = _parseDecimal(v ?? '');
                                if (val <= 0) return 'Profundidad > 0';
                                return null;
                              },
                            ),
                          ),
                        ],
                      ),
                    ],
                    const SizedBox(height: 12),

                    // ─── 7. Capacidad Final y Conversión de Litros en Vivo ────
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Expanded(
                          flex: 3,
                          child: GlassFormField(
                            label: 'CAPACIDAD OPERATIVA TOTAL (m³)',
                            hint: 'Calculado o manual',
                            controller: _capacidadFinalCtrl,
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            prefixIcon: Icons.water_rounded,
                            isRequired: true,
                            accentColor: AppColors.cyanWater,
                            onChanged: (_) {
                              _hasManuallyEditedCapacidad = true;
                              setState(() {});
                            },
                            validator: (v) {
                              final val = _parseDecimal(v ?? '');
                              if (val <= 0) return 'Capacidad requerida';
                              return null;
                            },
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          flex: 2,
                          child: Container(
                            height: 48,
                            padding: const EdgeInsets.symmetric(horizontal: 10),
                            decoration: BoxDecoration(
                              color: AppColors.cyanWater.withValues(alpha: isDark ? 0.12 : 0.08),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: AppColors.cyanWater.withValues(alpha: isDark ? 0.35 : 0.25),
                              ),
                            ),
                            child: Center(
                              child: Text(
                                '${litros.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.')} L',
                                style: AppTypography.titleSmall.copyWith(
                                  color: isDark ? AppColors.cyanWater : AppColors.cyanWaterTextLight,
                                  fontWeight: FontWeight.w900,
                                  fontSize: 13,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),

                    // ─── 8. Botones de Acción ──────────────────────────────────
                    Row(
                      children: [
                        Expanded(
                          flex: 1,
                          child: OutlinedButton(
                            style: OutlinedButton.styleFrom(
                              foregroundColor: isDark ? Colors.white : AppColors.textPrimaryLight,
                              side: BorderSide(
                                color: isDark ? Colors.white.withValues(alpha: 0.2) : AppColors.glassBorderLight,
                              ),
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                            ),
                            onPressed: () => Navigator.of(context).pop(),
                            child: const Text('Cancelar', style: TextStyle(fontWeight: FontWeight.w600)),
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
            ),
          ),
        ),
      ),
    );
  }
}
