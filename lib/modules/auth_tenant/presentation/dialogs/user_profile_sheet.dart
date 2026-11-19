import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:fishbit_finance/core/design_system/app_colors.dart';
import 'package:fishbit_finance/core/design_system/app_typography.dart';
import 'package:fishbit_finance/core/design_system/glass_button.dart';
import 'package:fishbit_finance/core/design_system/glass_container.dart';
import 'package:fishbit_finance/core/design_system/glass_form_field.dart';
import 'package:fishbit_finance/core/design_system/theme_animated_glass_toggle.dart';
import 'package:fishbit_finance/core/network/supabase_client_provider.dart';
import 'package:fishbit_finance/core/storage/offline_sync_queue.dart';
import 'package:fishbit_finance/modules/auth_tenant/domain/models/company.dart';
import 'package:fishbit_finance/modules/auth_tenant/domain/models/user_member.dart';
import 'package:fishbit_finance/modules/auth_tenant/presentation/providers/auth_provider.dart';

enum _ProfilePopoverView { menu, profile, settings }

enum _SettingsTab { empresa, produccion, unidades }

class UserProfileSheet extends ConsumerStatefulWidget {
  const UserProfileSheet({super.key});

  static Future<void> show(BuildContext context) {
    return showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Cerrar Perfil',
      barrierColor: Colors.black.withValues(alpha: 0.65),
      transitionDuration: const Duration(milliseconds: 220),
      pageBuilder: (dialogCtx, anim1, anim2) => const Material(
        type: MaterialType.transparency,
        child: UserProfileSheet(),
      ),
      transitionBuilder: (dialogCtx, anim, secondaryAnim, child) {
        final curvedAnim = CurvedAnimation(
          parent: anim,
          curve: Curves.easeOutCubic,
          reverseCurve: Curves.easeInCubic,
        );

        return FadeTransition(
          opacity: anim,
          child: ScaleTransition(
            alignment: const Alignment(0.90, -0.85),
            scale: Tween<double>(begin: 0.90, end: 1.0).animate(curvedAnim),
            child: child,
          ),
        );
      },
    );
  }

  @override
  ConsumerState<UserProfileSheet> createState() => _UserProfileSheetState();
}

class _UserProfileSheetState extends ConsumerState<UserProfileSheet> {
  static const List<String> _allSpecies = [
    'Tilapia Roja',
    'Cachama Negra',
    'Bocachico',
    'Trucha Arcoíris',
    'Pangasius',
    'Camarón / Langostino',
  ];

  static const List<String> _currencies = ['COP', 'USD', 'MXN', 'PEN', 'EUR'];

  _ProfilePopoverView _view = _ProfilePopoverView.menu;
  _SettingsTab _settingsTab = _SettingsTab.empresa;

  // Estado de sincronización offline
  int _pendingOfflineCount = 0;
  bool _isSyncingOffline = false;

  // Controladores de Perfil
  late final TextEditingController _nameCtrl;
  late final TextEditingController _phoneCtrl;
  final TextEditingController _newPasswordCtrl = TextEditingController();
  final TextEditingController _confirmPasswordCtrl = TextEditingController();
  bool _showPasswordSection = false;
  bool _isSavingProfile = false;
  bool _isUploadingAvatar = false;
  Uint8List? _localAvatarBytes;

  // Controladores de Configuración de Empresa y Producción
  late final TextEditingController _companyNameCtrl;
  late final TextEditingController _nitCtrl;
  late final TextEditingController _companyPhoneCtrl;
  late final TextEditingController _companyAddressCtrl;
  late final TextEditingController _icaCtrl;
  late final TextEditingController _aunapCtrl;
  late final TextEditingController _fcrCtrl;
  late final TextEditingController _o2MinCtrl;
  late final TextEditingController _phMinCtrl;
  late final TextEditingController _phMaxCtrl;
  late final TextEditingController _mortalityLimitCtrl;
  late final TextEditingController _minFeedStockCtrl;
  late final TextEditingController _marketPriceCtrl;
  late final TextEditingController _energyTariffCtrl;
  final Map<String, TextEditingController> _harvestWeightCtrls = {};

  late List<String> _selectedSpecies;
  late String _selectedCurrency;
  late String _selectedWeightUnit;
  late double _selectedBagKg;
  late String _selectedTempUnit;
  late bool _alertsIca;
  late bool _oxygenAlarm;
  bool _isSavingSettings = false;
  bool _isUploadingLogo = false;
  Uint8List? _localLogoBytes;

  String? _inlineFeedback;
  bool _inlineFeedbackIsError = false;

  @override
  void initState() {
    super.initState();
    final authState = ref.read(authProvider);
    final user = authState.currentUser;
    final company = authState.currentCompany;

    _nameCtrl = TextEditingController(text: user?.nombre ?? '');
    _phoneCtrl = TextEditingController(text: user?.telefono ?? '');

    _companyNameCtrl = TextEditingController(text: company?.nombreComercial ?? '');
    _nitCtrl = TextEditingController(text: company?.nit ?? '');
    _companyPhoneCtrl = TextEditingController(text: company?.telefono ?? '');
    _companyAddressCtrl = TextEditingController(text: company?.direccion ?? '');
    _icaCtrl = TextEditingController(text: company?.registroIca ?? '');
    _aunapCtrl = TextEditingController(text: company?.registroAunap ?? '');

    _fcrCtrl = TextEditingController(
      text: (company?.fcrObjetivo ?? 1.25).toStringAsFixed(2),
    );
    _o2MinCtrl = TextEditingController(
      text: (company?.oxigenoMinimoCritico ?? 4.0).toStringAsFixed(1),
    );
    _phMinCtrl = TextEditingController(
      text: (company?.phMinimo ?? 6.5).toStringAsFixed(1),
    );
    _phMaxCtrl = TextEditingController(
      text: (company?.phMaximo ?? 8.5).toStringAsFixed(1),
    );
    _mortalityLimitCtrl = TextEditingController(
      text: (company?.limiteMortalidadCritica ?? 10.0).toStringAsFixed(1),
    );
    _minFeedStockCtrl = TextEditingController(
      text: (company?.stockAlertaMinimoAlimento ?? 200.0).toStringAsFixed(0),
    );
    _marketPriceCtrl = TextEditingController(
      text: (company?.precioMercadoActualKg ?? 8500.0).toStringAsFixed(0),
    );
    _energyTariffCtrl = TextEditingController(
      text: (company?.tarifaEnergiaKwh ?? 850.0).toStringAsFixed(0),
    );

    _selectedSpecies = List<String>.from(
      company?.especiesHabilitadas ??
          const ['Tilapia Roja', 'Cachama Negra', 'Bocachico', 'Pangasius'],
    );
    for (final sp in _allSpecies) {
      final targetGrams = company != null
          ? company.getTargetHarvestWeightGrams(sp)
          : Company.defaultHarvestWeightForSpecies(sp);
      _harvestWeightCtrls[sp] =
          TextEditingController(text: targetGrams.toInt().toString());
    }

    _selectedCurrency = _currencies.contains(company?.moneda)
        ? company!.moneda
        : 'COP';
    _selectedWeightUnit = company?.unidadPeso ?? 'kg';
    _selectedBagKg = company?.kgPorBultoAlimento ?? 40.0;
    _selectedTempUnit = company?.unidadTemperatura ?? 'C';
    _alertsIca = company?.alertasIcaActivas ?? true;
    _oxygenAlarm = company?.alertaSonoraOxigeno ?? true;

    _loadOfflineQueueCount();
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    _newPasswordCtrl.dispose();
    _confirmPasswordCtrl.dispose();
    _companyNameCtrl.dispose();
    _nitCtrl.dispose();
    _companyPhoneCtrl.dispose();
    _companyAddressCtrl.dispose();
    _icaCtrl.dispose();
    _aunapCtrl.dispose();
    _fcrCtrl.dispose();
    _o2MinCtrl.dispose();
    _phMinCtrl.dispose();
    _phMaxCtrl.dispose();
    _mortalityLimitCtrl.dispose();
    _minFeedStockCtrl.dispose();
    _marketPriceCtrl.dispose();
    _energyTariffCtrl.dispose();
    for (final c in _harvestWeightCtrls.values) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _loadOfflineQueueCount() async {
    final pending = await OfflineSyncQueue.getPendingItems();
    if (mounted) {
      setState(() => _pendingOfflineCount = pending.length);
    }
  }

  void _setFeedback(String message, {bool isError = false}) {
    if (!mounted) return;
    setState(() {
      _inlineFeedback = message;
      _inlineFeedbackIsError = isError;
    });
  }

  void _goTo(_ProfilePopoverView next) {
    setState(() {
      _view = next;
      _inlineFeedback = null;
    });
  }

  Future<void> _handleOfflineSync() async {
    if (_isSyncingOffline) return;
    setState(() => _isSyncingOffline = true);
    try {
      final supabase = ref.read(supabaseClientProvider);
      final synced = await OfflineSyncQueue.flushQueue(supabase);
      await _loadOfflineQueueCount();
      _setFeedback(
        synced > 0
            ? 'Se sincronizaron $synced registro(s) con la nube.'
            : 'Todo está sincronizado al día.',
      );
    } catch (_) {
      _setFeedback('Sin conexión estable para sincronizar ahora.', isError: true);
    } finally {
      if (mounted) setState(() => _isSyncingOffline = false);
    }
  }

  Future<void> _pickAndUploadAvatar() async {
    try {
      final picker = ImagePicker();
      final picked = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 512,
        maxHeight: 512,
        imageQuality: 85,
      );
      if (picked == null) return;
      final bytes = await picked.readAsBytes();
      final ext = picked.name.contains('.') ? picked.name.split('.').last : 'jpg';
      setState(() {
        _localAvatarBytes = bytes;
        _isUploadingAvatar = true;
        _inlineFeedback = null;
      });
      final url = await ref
          .read(authProvider.notifier)
          .uploadProfileAvatar(bytes, ext);
      if (url != null) {
        _setFeedback('Foto de perfil actualizada.');
      } else {
        _setFeedback('No se pudo subir la foto. Verifica el bucket Storage.', isError: true);
      }
    } catch (_) {
      _setFeedback('No se pudo seleccionar la imagen.', isError: true);
    } finally {
      if (mounted) setState(() => _isUploadingAvatar = false);
    }
  }

  Future<void> _pickAndUploadCompanyLogo() async {
    try {
      final picker = ImagePicker();
      final picked = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 512,
        maxHeight: 512,
        imageQuality: 88,
      );
      if (picked == null) return;
      final bytes = await picked.readAsBytes();
      final ext = picked.name.contains('.') ? picked.name.split('.').last : 'png';
      setState(() {
        _localLogoBytes = bytes;
        _isUploadingLogo = true;
        _inlineFeedback = null;
      });
      final url = await ref
          .read(authProvider.notifier)
          .uploadCompanyLogo(bytes, ext);
      if (url != null) {
        _setFeedback('Logo de empresa actualizado.');
      } else {
        _setFeedback('No se pudo subir el logo. Verifica el bucket Storage.', isError: true);
      }
    } catch (_) {
      _setFeedback('No se pudo seleccionar el logo.', isError: true);
    } finally {
      if (mounted) setState(() => _isUploadingLogo = false);
    }
  }

  Future<void> _saveProfile() async {
    final name = _nameCtrl.text.trim();
    if (name.isEmpty) {
      _setFeedback('Ingresa tu nombre completo.', isError: true);
      return;
    }

    if (_showPasswordSection && _newPasswordCtrl.text.trim().isNotEmpty) {
      final pw = _newPasswordCtrl.text.trim();
      if (pw.length < 8) {
        _setFeedback('La nueva contraseña debe tener al menos 8 caracteres.', isError: true);
        return;
      }
      if (pw != _confirmPasswordCtrl.text.trim()) {
        _setFeedback('Las contraseñas no coinciden.', isError: true);
        return;
      }
    }

    setState(() {
      _isSavingProfile = true;
      _inlineFeedback = null;
    });

    final ok = await ref.read(authProvider.notifier).updateMyProfile(
          nombre: name,
          telefono: _phoneCtrl.text.trim(),
        );

    bool pwOk = true;
    if (ok && _showPasswordSection && _newPasswordCtrl.text.trim().isNotEmpty) {
      pwOk = await ref
          .read(authProvider.notifier)
          .changeMyPassword(_newPasswordCtrl.text.trim());
      if (pwOk) {
        _newPasswordCtrl.clear();
        _confirmPasswordCtrl.clear();
        _showPasswordSection = false;
      }
    }

    if (mounted) {
      setState(() => _isSavingProfile = false);
      if (ok && pwOk) {
        _setFeedback('Perfil guardado correctamente.');
      } else {
        _setFeedback(
          ref.read(authProvider).errorMessage ?? 'Error al guardar el perfil.',
          isError: true,
        );
      }
    }
  }

  Future<void> _saveSettings() async {
    final currentCompany = ref.read(authProvider).currentCompany;
    if (currentCompany == null) {
      _setFeedback('No hay una empresa activa para guardar.', isError: true);
      return;
    }

    setState(() {
      _isSavingSettings = true;
      _inlineFeedback = null;
    });

    final Map<String, dynamic> updatedWeights =
        Map<String, dynamic>.from(currentCompany.pesosFinalesEspeciesG);
    for (final entry in _harvestWeightCtrls.entries) {
      final v = double.tryParse(entry.value.text.trim());
      if (v != null && v > 0) {
        updatedWeights[entry.key] = v;
      }
    }

    final prefs = Map<String, dynamic>.from(currentCompany.preferenciasOperativas)
      ..addAll({
        'fcr_objetivo': double.tryParse(_fcrCtrl.text.trim()) ?? currentCompany.fcrObjetivo,
        'oxigeno_minimo_critico':
            double.tryParse(_o2MinCtrl.text.trim()) ?? currentCompany.oxigenoMinimoCritico,
        'ph_minimo': double.tryParse(_phMinCtrl.text.trim()) ?? currentCompany.phMinimo,
        'ph_maximo': double.tryParse(_phMaxCtrl.text.trim()) ?? currentCompany.phMaximo,
        'unidad_peso': _selectedWeightUnit,
        'kg_por_bulto_alimento': _selectedBagKg,
        'unidad_temperatura': _selectedTempUnit,
        'alertas_ica_activas': _alertsIca,
        'alerta_sonora_oxigeno': _oxygenAlarm,
      });

    final updatedCompany = currentCompany.copyWith(
      nombreComercial: _companyNameCtrl.text.trim().isNotEmpty
          ? _companyNameCtrl.text.trim()
          : currentCompany.nombreComercial,
      nit: _nitCtrl.text.trim(),
      telefono: _companyPhoneCtrl.text.trim(),
      direccion: _companyAddressCtrl.text.trim(),
      registroIca: _icaCtrl.text.trim(),
      registroAunap: _aunapCtrl.text.trim(),
      moneda: _selectedCurrency,
      tarifaEnergiaKwh:
          double.tryParse(_energyTariffCtrl.text.trim()) ?? currentCompany.tarifaEnergiaKwh,
      limiteMortalidadCritica:
          double.tryParse(_mortalityLimitCtrl.text.trim()) ??
              currentCompany.limiteMortalidadCritica,
      stockAlertaMinimoAlimento:
          double.tryParse(_minFeedStockCtrl.text.trim()) ??
              currentCompany.stockAlertaMinimoAlimento,
      precioMercadoActualKg:
          double.tryParse(_marketPriceCtrl.text.trim()) ??
              currentCompany.precioMercadoActualKg,
      especiesHabilitadas: _selectedSpecies,
      pesosFinalesEspeciesG: updatedWeights,
      preferenciasOperativas: prefs,
    );

    final ok = await ref.read(authProvider.notifier).updateCompany(updatedCompany);

    if (mounted) {
      setState(() => _isSavingSettings = false);
      if (ok) {
        _setFeedback('Configuración guardada y sincronizada.');
      } else {
        _setFeedback(
          ref.read(authProvider).errorMessage ?? 'No se pudo guardar la configuración.',
          isError: true,
        );
      }
    }
  }

  String _initialsFor(String? name) {
    final clean = (name ?? '').trim();
    if (clean.isEmpty) return 'U';
    final parts = clean.split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return parts.first.substring(0, parts.first.length >= 2 ? 2 : 1).toUpperCase();
  }

  Color _roleColorFor(UserRole? role) => switch (role) {
        UserRole.admin => AppColors.cyanWater,
        UserRole.sanitaryDirector => AppColors.greenBiomass,
        UserRole.technician => AppColors.amberWarning,
        UserRole.operator => Colors.orangeAccent,
        UserRole.creator => Colors.purpleAccent,
        _ => AppColors.cyanWater,
      };

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final user = authState.currentUser;
    final company = authState.currentCompany;
    final units = authState.units;
    final activeUnit =
        units.where((u) => u.id == authState.activeUnitId).firstOrNull;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final roleColor = _roleColorFor(user?.role);

    final double targetMaxWidth = switch (_view) {
      _ProfilePopoverView.menu => 300,
      _ProfilePopoverView.profile => 390,
      _ProfilePopoverView.settings => 430,
    };

    return Material(
      type: MaterialType.transparency,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => Navigator.of(context).pop(),
        child: SafeArea(
          child: Align(
            alignment: Alignment.topRight,
            child: Padding(
              padding: const EdgeInsets.only(top: 64, right: 14, left: 14, bottom: 16),
              child: GestureDetector(
                onTap: () {}, // Evita que los toques internos cierren el popover
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 220),
                  curve: Curves.easeOutCubic,
                  constraints: BoxConstraints(
                    maxWidth: targetMaxWidth,
                    maxHeight: MediaQuery.sizeOf(context).height * 0.80,
                  ),
                  child: GlassContainer(
                    borderRadius: 20,
                    padding: EdgeInsets.zero,
                    blur: 28,
                    opacity: isDark ? 0.88 : 0.96,
                    isOverlay: true,
                    borderColor: isDark
                        ? Colors.white.withValues(alpha: 0.14)
                        : AppColors.glassBorderLight,
                    child: AnimatedSize(
                      duration: const Duration(milliseconds: 220),
                      curve: Curves.easeOutCubic,
                      alignment: Alignment.topCenter,
                      child: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 200),
                        switchInCurve: Curves.easeOutCubic,
                        switchOutCurve: Curves.easeInCubic,
                        child: switch (_view) {
                          _ProfilePopoverView.menu => _buildMenuView(
                              isDark: isDark,
                              user: user,
                              activeUnitSigla: activeUnit?.sigla,
                              roleColor: roleColor,
                            ),
                          _ProfilePopoverView.profile => _buildProfileView(
                              isDark: isDark,
                              user: user,
                              company: company,
                              activeUnitName: activeUnit?.nombre,
                              roleColor: roleColor,
                            ),
                          _ProfilePopoverView.settings => _buildSettingsView(
                              isDark: isDark,
                              company: company,
                            ),
                        },
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAvatar({
    required double size,
    required String initials,
    required Color accentColor,
    String? imageUrl,
    Uint8List? localBytes,
  }) {
    Widget fallback() => Center(
          child: Text(
            initials,
            style: TextStyle(
              color: accentColor,
              fontWeight: FontWeight.w800,
              fontSize: size * 0.38,
            ),
          ),
        );

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: accentColor.withValues(alpha: 0.16),
        border: Border.all(color: accentColor.withValues(alpha: 0.55), width: 1.4),
      ),
      child: ClipOval(
        child: localBytes != null
            ? Image.memory(localBytes, width: size, height: size, fit: BoxFit.cover)
            : (imageUrl != null && imageUrl.isNotEmpty)
                ? Image.network(
                    imageUrl,
                    width: size,
                    height: size,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => fallback(),
                  )
                : fallback(),
      ),
    );
  }

  /// Vista Principal estilo HeroUI `<Dropdown.Popover>`
  Widget _buildMenuView({
    required bool isDark,
    required UserMember? user,
    required String? activeUnitSigla,
    required Color roleColor,
  }) {
    final dividerColor = isDark
        ? Colors.white.withValues(alpha: 0.08)
        : Colors.black.withValues(alpha: 0.06);

    return Column(
      key: const ValueKey('view_menu'),
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Header estilo HeroUI: Avatar sm + Nombre/Correo + Switch compacto (sin etiqueta "Tema Visual")
        Padding(
          padding: const EdgeInsets.fromLTRB(14, 14, 12, 10),
          child: Row(
            children: [
              _buildAvatar(
                size: 36,
                initials: _initialsFor(user?.nombre),
                accentColor: roleColor,
                imageUrl: user?.avatarUrl,
                localBytes: _localAvatarBytes,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      user?.nombre ?? 'Usuario FishBit',
                      style: TextStyle(
                        color: isDark ? Colors.white : AppColors.textPrimaryLight,
                        fontSize: 13.5,
                        fontWeight: FontWeight.w700,
                        height: 1.2,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      user?.email ?? 'usuario@fishbit.app',
                      style: TextStyle(
                        color: isDark
                            ? AppColors.textSecondaryDark
                            : AppColors.textSecondaryLight,
                        fontSize: 11,
                        height: 1.1,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (activeUnitSigla != null) ...[
                      const SizedBox(height: 3),
                      Text(
                        '${user?.roleDisplayName ?? 'Miembro'} · $activeUnitSigla',
                        style: TextStyle(
                          color: roleColor,
                          fontSize: 9.5,
                          fontWeight: FontWeight.w700,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 8),
              // Switch compacto (sin texto "Tema Visual")
              const ThemeAnimatedGlassToggle(scale: 0.76),
            ],
          ),
        ),

        Divider(height: 1, thickness: 1, color: dividerColor),

        // Ítems del Dropdown.Menu estilo HeroUI
        Padding(
          padding: const EdgeInsets.all(6),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _HeroDropdownItem(
                label: 'Perfil',
                trailingIcon: Icons.person_outline_rounded,
                isDark: isDark,
                onTap: () => _goTo(_ProfilePopoverView.profile),
              ),
              _HeroDropdownItem(
                label: 'Configuración',
                trailingIcon: Icons.settings_outlined,
                isDark: isDark,
                onTap: () => _goTo(_ProfilePopoverView.settings),
              ),
              _HeroDropdownItem(
                label: _isSyncingOffline
                    ? 'Sincronizando...'
                    : 'Sincronización Campo',
                trailingIcon: _pendingOfflineCount > 0
                    ? Icons.cloud_upload_outlined
                    : Icons.cloud_done_outlined,
                badgeText: _pendingOfflineCount > 0 ? '$_pendingOfflineCount' : null,
                badgeColor: AppColors.amberWarning,
                isDark: isDark,
                onTap: _handleOfflineSync,
              ),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 6),
                child: Divider(height: 1, thickness: 1, color: dividerColor),
              ),
              _HeroDropdownItem(
                label: 'Cerrar Sesión',
                trailingIcon: Icons.logout_rounded,
                isDanger: true,
                isDark: isDark,
                onTap: () {
                  Navigator.of(context).pop();
                  ref.read(authProvider.notifier).signOut();
                },
              ),
            ],
          ),
        ),

        if (_inlineFeedback != null) _buildFeedbackBanner(isDark),
      ],
    );
  }

  /// Subvista Inline 1: Mi Perfil (editar nombre, foto, teléfono y contraseña)
  Widget _buildProfileView({
    required bool isDark,
    required UserMember? user,
    required Company? company,
    required String? activeUnitName,
    required Color roleColor,
  }) {
    final muted = isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight;

    return SingleChildScrollView(
      key: const ValueKey('view_profile'),
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildSubViewHeader(title: 'Mi Perfil', isDark: isDark),
          const SizedBox(height: 14),

          // Avatar interactivo con botón de cámara
          Center(
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                _buildAvatar(
                  size: 68,
                  initials: _initialsFor(_nameCtrl.text.isNotEmpty ? _nameCtrl.text : user?.nombre),
                  accentColor: roleColor,
                  imageUrl: user?.avatarUrl,
                  localBytes: _localAvatarBytes,
                ),
                Positioned(
                  right: -2,
                  bottom: -2,
                  child: Material(
                    color: AppColors.cyanWater,
                    shape: const CircleBorder(),
                    child: InkWell(
                      customBorder: const CircleBorder(),
                      onTap: _isUploadingAvatar ? null : _pickAndUploadAvatar,
                      child: Padding(
                        padding: const EdgeInsets.all(6),
                        child: _isUploadingAvatar
                            ? const SizedBox(
                                width: 14,
                                height: 14,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Icon(
                                Icons.camera_alt_rounded,
                                size: 14,
                                color: Colors.white,
                              ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 6),
          Center(
            child: Text(
              'Toca la cámara para subir tu foto',
              style: TextStyle(color: muted, fontSize: 10.5),
            ),
          ),
          const SizedBox(height: 14),

          GlassFormField(
            label: 'NOMBRE COMPLETO',
            hint: 'Tu nombre',
            controller: _nameCtrl,
            prefixIcon: Icons.person_outline_rounded,
          ),
          const SizedBox(height: 10),

          GlassFormField(
            label: 'TELÉFONO / WHATSAPP',
            hint: '+57 300 000 0000',
            controller: _phoneCtrl,
            keyboardType: TextInputType.phone,
            prefixIcon: Icons.phone_outlined,
          ),
          const SizedBox(height: 10),

          // Info de cuenta (solo lectura)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.04)
                  : Colors.black.withValues(alpha: 0.03),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.08)
                    : AppColors.glassBorderLight,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  user?.email ?? '',
                  style: TextStyle(
                    color: isDark ? Colors.white70 : AppColors.textPrimaryLight,
                    fontSize: 11.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${user?.roleDisplayName ?? 'Usuario'} · ${company?.nombreComercial ?? 'Piscícola'}${activeUnitName != null ? ' ($activeUnitName)' : ''}',
                  style: TextStyle(color: muted, fontSize: 10.5),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),

          // Acordeón inline para cambiar contraseña
          InkWell(
            borderRadius: BorderRadius.circular(10),
            onTap: () => setState(() => _showPasswordSection = !_showPasswordSection),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
              child: Row(
                children: [
                  const Icon(Icons.lock_outline_rounded, size: 15, color: AppColors.cyanWater),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Cambiar contraseña',
                      style: TextStyle(
                        color: isDark ? Colors.white : AppColors.textPrimaryLight,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  Icon(
                    _showPasswordSection
                        ? Icons.keyboard_arrow_up_rounded
                        : Icons.keyboard_arrow_down_rounded,
                    size: 18,
                    color: muted,
                  ),
                ],
              ),
            ),
          ),
          if (_showPasswordSection) ...[
            const SizedBox(height: 6),
            GlassFormField(
              label: 'NUEVA CONTRASEÑA',
              hint: 'Mínimo 8 caracteres',
              controller: _newPasswordCtrl,
              obscureText: true,
              prefixIcon: Icons.key_rounded,
            ),
            const SizedBox(height: 8),
            GlassFormField(
              label: 'CONFIRMAR CONTRASEÑA',
              hint: 'Repite la contraseña',
              controller: _confirmPasswordCtrl,
              obscureText: true,
              prefixIcon: Icons.check_circle_outline_rounded,
            ),
          ],

          if (_inlineFeedback != null) ...[
            const SizedBox(height: 10),
            _buildFeedbackBanner(isDark),
          ],

          const SizedBox(height: 14),
          GlassButton(
            label: 'Guardar Perfil',
            isLoading: _isSavingProfile,
            backgroundColor: AppColors.cyanWater,
            onPressed: _saveProfile,
          ),
        ],
      ),
    );
  }

  /// Subvista Inline 2: Configuración de App y Piscícola (3 pestañas inline)
  Widget _buildSettingsView({
    required bool isDark,
    required Company? company,
  }) {
    return SingleChildScrollView(
      key: const ValueKey('view_settings'),
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildSubViewHeader(title: 'Configuración', isDark: isDark),
          const SizedBox(height: 10),

          // Mini-pestañas inline: Empresa | Producción | Unidades
          Container(
            padding: const EdgeInsets.all(3),
            decoration: BoxDecoration(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.06)
                  : Colors.black.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                _buildTabPill('Empresa', _SettingsTab.empresa, isDark),
                _buildTabPill('Producción', _SettingsTab.produccion, isDark),
                _buildTabPill('Unidades', _SettingsTab.unidades, isDark),
              ],
            ),
          ),
          const SizedBox(height: 14),

          if (_settingsTab == _SettingsTab.empresa)
            _buildCompanyTab(isDark: isDark, company: company),
          if (_settingsTab == _SettingsTab.produccion)
            _buildProductionTab(isDark: isDark),
          if (_settingsTab == _SettingsTab.unidades)
            _buildUnitsTab(isDark: isDark),

          if (_inlineFeedback != null) ...[
            const SizedBox(height: 10),
            _buildFeedbackBanner(isDark),
          ],

          const SizedBox(height: 14),
          GlassButton(
            label: 'Guardar Configuración',
            isLoading: _isSavingSettings,
            backgroundColor: AppColors.cyanWater,
            onPressed: _saveSettings,
          ),
        ],
      ),
    );
  }

  Widget _buildTabPill(String label, _SettingsTab tab, bool isDark) {
    final selected = _settingsTab == tab;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _settingsTab = tab),
        behavior: HitTestBehavior.opaque,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(vertical: 7),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: selected
                ? (isDark ? AppColors.cyanWater.withValues(alpha: 0.24) : Colors.white)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(9),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
              color: selected
                  ? (isDark ? Colors.white : AppColors.textPrimaryLight)
                  : (isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCompanyTab({required bool isDark, required Company? company}) {
    final muted = isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Logo de la empresa
        Row(
          children: [
            Container(
              width: 54,
              height: 54,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                color: AppColors.cyanWater.withValues(alpha: 0.12),
                border: Border.all(
                  color: AppColors.cyanWater.withValues(alpha: 0.35),
                ),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(13),
                child: _localLogoBytes != null
                    ? Image.memory(_localLogoBytes!, fit: BoxFit.cover)
                    : (company?.logoUrl != null && company!.logoUrl!.isNotEmpty)
                        ? Image.network(
                            company.logoUrl!,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => const Icon(
                              Icons.business_rounded,
                              color: AppColors.cyanWater,
                            ),
                          )
                        : const Icon(
                            Icons.business_rounded,
                            color: AppColors.cyanWater,
                          ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Logo de la Empresa',
                    style: TextStyle(
                      color: isDark ? Colors.white : AppColors.textPrimaryLight,
                      fontSize: 12.5,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Text(
                    'Se usa en reportes ICA y documentos.',
                    style: TextStyle(color: muted, fontSize: 10.5),
                  ),
                ],
              ),
            ),
            TextButton.icon(
              onPressed: _isUploadingLogo ? null : _pickAndUploadCompanyLogo,
              icon: _isUploadingLogo
                  ? const SizedBox(
                      width: 12,
                      height: 12,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.upload_rounded, size: 15),
              label: const Text('Subir', style: TextStyle(fontSize: 11.5)),
            ),
          ],
        ),
        const SizedBox(height: 12),
        GlassFormField(
          label: 'NOMBRE COMERCIAL',
          hint: 'Piscícola...',
          controller: _companyNameCtrl,
          prefixIcon: Icons.storefront_outlined,
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: GlassFormField(
                label: 'NIT / ID FISCAL',
                hint: '900.000.000-1',
                controller: _nitCtrl,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: GlassFormField(
                label: 'TELÉFONO',
                hint: '300 000 0000',
                controller: _companyPhoneCtrl,
                keyboardType: TextInputType.phone,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        GlassFormField(
          label: 'DIRECCIÓN / UBICACIÓN',
          hint: 'Vereda / Municipio',
          controller: _companyAddressCtrl,
          prefixIcon: Icons.location_on_outlined,
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: GlassFormField(
                label: 'REGISTRO ICA',
                hint: 'Opcional',
                controller: _icaCtrl,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: GlassFormField(
                label: 'REGISTRO AUNAP',
                hint: 'Opcional',
                controller: _aunapCtrl,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildProductionTab({required bool isDark}) {
    final textPrimary = isDark ? Colors.white : AppColors.textPrimaryLight;
    final muted = isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'ESPECIES HABILITADAS',
          style: AppTypography.labelMicro.copyWith(
            color: AppColors.cyanWater,
            letterSpacing: 1.0,
          ),
        ),
        const SizedBox(height: 6),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: _allSpecies.map((sp) {
            final isSelected = _selectedSpecies.contains(sp);
            return FilterChip(
              visualDensity: VisualDensity.compact,
              label: Text(
                sp,
                style: TextStyle(
                  fontSize: 11,
                  color: isSelected ? Colors.white : muted,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                ),
              ),
              selected: isSelected,
              selectedColor: AppColors.cyanWater.withValues(alpha: 0.30),
              checkmarkColor: AppColors.cyanWater,
              backgroundColor: isDark
                  ? Colors.white.withValues(alpha: 0.05)
                  : Colors.black.withValues(alpha: 0.04),
              side: BorderSide(
                color: isSelected
                    ? AppColors.cyanWater
                    : (isDark ? Colors.white12 : AppColors.glassBorderLight),
              ),
              onSelected: (val) {
                setState(() {
                  if (val) {
                    _selectedSpecies.add(sp);
                  } else if (_selectedSpecies.length > 1) {
                    _selectedSpecies.remove(sp);
                  }
                });
              },
            );
          }).toList(),
        ),
        const SizedBox(height: 10),
        Text(
          'META DE COSECHA (GRAMOS)',
          style: AppTypography.labelMicro.copyWith(
            color: AppColors.greenBiomass,
            letterSpacing: 1.0,
          ),
        ),
        const SizedBox(height: 6),
        ..._selectedSpecies.map((sp) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Row(
              children: [
                Expanded(
                  flex: 3,
                  child: Text(
                    sp,
                    style: TextStyle(
                      color: textPrimary,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: SizedBox(
                    height: 36,
                    child: TextField(
                      controller: _harvestWeightCtrls[sp],
                      keyboardType: TextInputType.number,
                      textAlign: TextAlign.end,
                      style: const TextStyle(
                        color: AppColors.cyanWater,
                        fontWeight: FontWeight.w800,
                        fontSize: 12.5,
                      ),
                      decoration: InputDecoration(
                        suffixText: ' g',
                        isDense: true,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                        filled: true,
                        fillColor: isDark
                            ? Colors.white.withValues(alpha: 0.05)
                            : Colors.black.withValues(alpha: 0.04),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(
                            color: isDark ? Colors.white12 : AppColors.glassBorderLight,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        }),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: GlassFormField(
                label: 'FCR OBJETIVO',
                hint: '1.25',
                controller: _fcrCtrl,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: GlassFormField(
                label: 'O₂ MÍNIMO (mg/L)',
                hint: '4.0',
                controller: _o2MinCtrl,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: GlassFormField(
                label: 'pH MÍNIMO',
                hint: '6.5',
                controller: _phMinCtrl,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: GlassFormField(
                label: 'pH MÁXIMO',
                hint: '8.5',
                controller: _phMaxCtrl,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: GlassFormField(
                label: 'MORTALIDAD CRÍT. (%)',
                hint: '10.0',
                controller: _mortalityLimitCtrl,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: GlassFormField(
                label: 'STOCK MÍN. ALIMENTO',
                hint: '200',
                controller: _minFeedStockCtrl,
                keyboardType: TextInputType.number,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        GlassFormField(
          label: 'PRECIO MERCADO PROMEDIO / KG',
          hint: '8500',
          controller: _marketPriceCtrl,
          keyboardType: TextInputType.number,
          prefixIcon: Icons.attach_money_rounded,
        ),
      ],
    );
  }

  Widget _buildUnitsTab({required bool isDark}) {
    final textPrimary = isDark ? Colors.white : AppColors.textPrimaryLight;
    final muted = isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight;

    Widget buildChoiceRow<T>({
      required String title,
      required List<(T, String)> items,
      required T current,
      required ValueChanged<T> onSelect,
    }) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: AppTypography.labelMicro.copyWith(color: muted, letterSpacing: 0.9),
          ),
          const SizedBox(height: 6),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: items.map((entry) {
              final selected = entry.$1 == current;
              return ChoiceChip(
                visualDensity: VisualDensity.compact,
                label: Text(
                  entry.$2,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
                    color: selected ? Colors.white : muted,
                  ),
                ),
                selected: selected,
                selectedColor: AppColors.cyanWater.withValues(alpha: 0.35),
                backgroundColor: isDark
                    ? Colors.white.withValues(alpha: 0.05)
                    : Colors.black.withValues(alpha: 0.04),
                side: BorderSide(
                  color: selected
                      ? AppColors.cyanWater
                      : (isDark ? Colors.white12 : AppColors.glassBorderLight),
                ),
                onSelected: (_) => onSelect(entry.$1),
              );
            }).toList(),
          ),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        buildChoiceRow<String>(
          title: 'MONEDA PRINCIPAL',
          items: _currencies.map((c) => (c, c)).toList(),
          current: _selectedCurrency,
          onSelect: (v) => setState(() => _selectedCurrency = v),
        ),
        const SizedBox(height: 12),
        buildChoiceRow<String>(
          title: 'UNIDAD DE BIOMASA / PESO',
          items: const [('kg', 'Kilogramos (kg)'), ('lb', 'Libras (lb)')],
          current: _selectedWeightUnit,
          onSelect: (v) => setState(() => _selectedWeightUnit = v),
        ),
        const SizedBox(height: 12),
        buildChoiceRow<double>(
          title: 'CONVERSIÓN DE BULTO DE ALIMENTO',
          items: const [(25.0, '25 kg'), (40.0, '40 kg'), (50.0, '50 kg')],
          current: _selectedBagKg,
          onSelect: (v) => setState(() => _selectedBagKg = v),
        ),
        const SizedBox(height: 12),
        buildChoiceRow<String>(
          title: 'UNIDAD DE TEMPERATURA',
          items: const [('C', 'Celsius (°C)'), ('F', 'Fahrenheit (°F)')],
          current: _selectedTempUnit,
          onSelect: (v) => setState(() => _selectedTempUnit = v),
        ),
        const SizedBox(height: 12),
        GlassFormField(
          label: 'TARIFA DE ENERGÍA (\$$_selectedCurrency / kWh)',
          hint: '850',
          controller: _energyTariffCtrl,
          keyboardType: TextInputType.number,
          prefixIcon: Icons.bolt_rounded,
        ),
        const SizedBox(height: 10),
        SwitchListTile(
          dense: true,
          contentPadding: EdgeInsets.zero,
          activeThumbColor: AppColors.cyanWater,
          title: Text(
            'Alertas Sanitarias ICA / AUNAP',
            style: TextStyle(color: textPrimary, fontSize: 12, fontWeight: FontWeight.w600),
          ),
          value: _alertsIca,
          onChanged: (v) => setState(() => _alertsIca = v),
        ),
        SwitchListTile(
          dense: true,
          contentPadding: EdgeInsets.zero,
          activeThumbColor: AppColors.cyanWater,
          title: Text(
            'Alarmas Críticas de Oxígeno',
            style: TextStyle(color: textPrimary, fontSize: 12, fontWeight: FontWeight.w600),
          ),
          value: _oxygenAlarm,
          onChanged: (v) => setState(() => _oxygenAlarm = v),
        ),
      ],
    );
  }

  Widget _buildSubViewHeader({required String title, required bool isDark}) {
    return Row(
      children: [
        InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: () => _goTo(_ProfilePopoverView.menu),
          child: Padding(
            padding: const EdgeInsets.all(4),
            child: Icon(
              Icons.arrow_back_ios_new_rounded,
              size: 15,
              color: isDark ? Colors.white70 : AppColors.textPrimaryLight,
            ),
          ),
        ),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            title,
            style: TextStyle(
              color: isDark ? Colors.white : AppColors.textPrimaryLight,
              fontSize: 14,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: () => Navigator.of(context).pop(),
          child: Padding(
            padding: const EdgeInsets.all(4),
            child: Icon(
              Icons.close_rounded,
              size: 16,
              color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFeedbackBanner(bool isDark) {
    final color = _inlineFeedbackIsError
        ? AppColors.coralAction
        : AppColors.greenBiomass;
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 0, 12, 10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.14),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withValues(alpha: 0.35)),
        ),
        child: Text(
          _inlineFeedback!,
          style: TextStyle(
            color: isDark ? Colors.white : color,
            fontSize: 11,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

class _HeroDropdownItem extends StatefulWidget {
  final String label;
  final IconData trailingIcon;
  final bool isDanger;
  final bool isDark;
  final String? badgeText;
  final Color? badgeColor;
  final VoidCallback onTap;

  const _HeroDropdownItem({
    required this.label,
    required this.trailingIcon,
    required this.isDark,
    required this.onTap,
    this.isDanger = false,
    this.badgeText,
    this.badgeColor,
  });

  @override
  State<_HeroDropdownItem> createState() => _HeroDropdownItemState();
}

class _HeroDropdownItemState extends State<_HeroDropdownItem> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final textColor = widget.isDanger
        ? AppColors.coralAction
        : (widget.isDark ? Colors.white : AppColors.textPrimaryLight);
    final iconColor = widget.isDanger
        ? AppColors.coralAction
        : (widget.isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight);
    final hoverBg = widget.isDanger
        ? AppColors.coralAction.withValues(alpha: widget.isDark ? 0.14 : 0.10)
        : (widget.isDark
            ? Colors.white.withValues(alpha: 0.08)
            : Colors.black.withValues(alpha: 0.05));

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 120),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
          decoration: BoxDecoration(
            color: _hovered ? hoverBg : Colors.transparent,
            borderRadius: BorderRadius.circular(11),
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  widget.label,
                  style: TextStyle(
                    color: textColor,
                    fontSize: 13,
                    fontWeight: widget.isDanger ? FontWeight.w600 : FontWeight.w500,
                  ),
                ),
              ),
              if (widget.badgeText != null) ...[
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                  decoration: BoxDecoration(
                    color: (widget.badgeColor ?? AppColors.cyanWater)
                        .withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    widget.badgeText!,
                    style: TextStyle(
                      color: widget.badgeColor ?? AppColors.cyanWater,
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                const SizedBox(width: 6),
              ],
              Icon(widget.trailingIcon, size: 15, color: iconColor),
            ],
          ),
        ),
      ),
    );
  }
}
