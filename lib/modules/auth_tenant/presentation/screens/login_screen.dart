import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:fishbit_finance/core/design_system/app_colors.dart';
import 'package:fishbit_finance/core/design_system/app_typography.dart';
import 'package:fishbit_finance/core/design_system/glass_container.dart';
import 'package:fishbit_finance/core/design_system/glass_form_field.dart';
import 'package:fishbit_finance/core/design_system/glass_button.dart';
import 'package:fishbit_finance/core/design_system/fishbit_icons.dart';
import 'package:fishbit_finance/modules/auth_tenant/presentation/providers/auth_provider.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();

  bool _obscurePassword = true;
  bool _rememberMe = true;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (_formKey.currentState != null && !_formKey.currentState!.validate()) {
      return;
    }

    final success = await ref.read(authProvider.notifier).signIn(
          _emailCtrl.text,
          _passCtrl.text,
        );
    if (!success && mounted) {
      final err = ref.read(authProvider).errorMessage ?? 'Error de autenticación';
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(err),
        backgroundColor: Colors.redAccent,
      ));
    }
  }

  Future<void> _handleGoogleLogin() async {
    final user = await ref.read(authProvider.notifier).signInWithGoogle();
    if (user != null && mounted) {
      // El router GoRouter maneja la redirección automáticamente
      // basándose en el estado de autenticación (isAuthenticated, isSuperAdmin, etc.)
      // No se navega manualmente aquí para evitar conflictos con el redirect guard.
    }
  }

  void _showForgotPasswordModal() {
    final resetEmailCtrl = TextEditingController(text: _emailCtrl.text);

    showDialog<void>(
      context: context,
      builder: (dialogCtx) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: GlassContainer(
            borderRadius: 24,
            padding: const EdgeInsets.all(24),
            blur: 24,
            opacity: 0.15,
            borderColor: Colors.white.withValues(alpha: 0.16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Recuperar Acceso', style: AppTypography.titleMedium.copyWith(color: Colors.white)),
                    IconButton(
                      icon: const Icon(Icons.close_rounded, color: AppColors.textSecondaryDark),
                      onPressed: () => Navigator.of(dialogCtx).pop(),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  'Ingresa tu correo registrado y te enviaremos un enlace seguro para restablecer tu contraseña.',
                  style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondaryDark),
                ),
                const SizedBox(height: 20),
                GlassFormField(
                  label: 'CORREO ELECTRÓNICO',
                  hint: 'ejemplo@piscicola.com',
                  controller: resetEmailCtrl,
                  keyboardType: TextInputType.emailAddress,
                  prefixIcon: Icons.alternate_email_rounded,
                ),
                const SizedBox(height: 24),
                GlassButton(
                  label: 'Enviar Enlace de Recuperación',
                  backgroundColor: AppColors.cyanWater,
                  onPressed: () async {
                    if (resetEmailCtrl.text.trim().isEmpty || !resetEmailCtrl.text.contains('@')) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Ingresa un correo válido'), backgroundColor: Colors.redAccent),
                      );
                      return;
                    }
                    Navigator.of(dialogCtx).pop();
                    await ref.read(authProvider.notifier).sendPasswordReset(resetEmailCtrl.text.trim());
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Enlace enviado a ${resetEmailCtrl.text}. Revisa tu bandeja de entrada.'),
                          backgroundColor: AppColors.greenBiomass,
                        ),
                      );
                    }
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);

    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      body: Stack(
        children: [
          // 1. Textura de Fondo con Grabado Científico Vintage de Peces (Seamless Repeat)
          Positioned.fill(
            child: Image.asset(
              'assets/images/fish_pattern_bg.jpg',
              repeat: ImageRepeat.repeat,
              fit: BoxFit.none,
              scale: 2.2, // Escala refinada para grabado taxonómico nítido
              alignment: Alignment.topLeft,
            ),
          ),

          // 2. Capa de Tinte y Contraste Translúcido (Permite apreciar claramente las ilustraciones de peces)
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    AppColors.backgroundDark.withValues(alpha: 0.45),
                    const Color(0xFF0A0F18).withValues(alpha: 0.40),
                    AppColors.backgroundDark.withValues(alpha: 0.55),
                  ],
                ),
              ),
            ),
          ),

          // 3. Orbes de Resplandor Ambiental Atmosférico (Apple / Luxury Glow)
          Positioned(
            top: -60,
            left: -60,
            child: Container(
              width: 320,
              height: 320,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.cyanWater.withValues(alpha: 0.20),
              ),
            ),
          ),
          Positioned(
            bottom: -80,
            right: -80,
            child: Container(
              width: 340,
              height: 340,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.coralAction.withValues(alpha: 0.18),
              ),
            ),
          ),

          // 4. Tarjeta Glassmorphic de Autenticación (Mayor desenfoque y presencia para perfecta legibilidad)
          Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 32),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 420),
                child: GlassContainer(
                  borderRadius: 28,
                  padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 36),
                  blur: 32,
                  opacity: 0.65,
                  tintColor: const Color(0xFF0D1522),
                  borderColor: Colors.white.withValues(alpha: 0.22),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Logo de Marca FishBit (Escalable y responsivo).
                        Center(
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  'Fish',
                                  style: TextStyle(
                                    fontSize: 38,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: -1.2,
                                    color: AppColors.cyanWater,
                                    shadows: [
                                      Shadow(
                                        color: AppColors.cyanWater.withValues(alpha: 0.7),
                                        blurRadius: 20,
                                      ),
                                    ],
                                  ),
                                ),
                                Text(
                                  'Bit.',
                                  style: TextStyle(
                                    fontSize: 38,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: -1.2,
                                    color: AppColors.coralAction,
                                    shadows: [
                                      Shadow(
                                        color: AppColors.coralAction.withValues(alpha: 0.7),
                                        blurRadius: 20,
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'LÍNEA GESTIÓN ACUÍCOLA DE GRUPO GALÁGOS',
                          textAlign: TextAlign.center,
                          style: AppTypography.labelMicro.copyWith(
                            color: AppColors.textSecondaryDark,
                            letterSpacing: 1.1,
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 28),

                        // Formulario de Ingreso
                        GlassFormField(
                          label: 'CORREO ELECTRÓNICO',
                          hint: 'admin@fishbit.com',
                          controller: _emailCtrl,
                          keyboardType: TextInputType.emailAddress,
                          prefixIcon: Icons.alternate_email_rounded,
                          validator: (val) {
                            if (val == null || val.trim().isEmpty) return 'El correo es requerido';
                            if (!val.contains('@')) return 'Ingresa un correo electrónico válido';
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        GlassFormField(
                          label: 'CONTRASEÑA',
                          hint: '••••••••',
                          controller: _passCtrl,
                          obscureText: _obscurePassword,
                          prefixIcon: Icons.lock_outline_rounded,
                          suffixWidget: IconButton(
                            icon: Icon(
                              _obscurePassword ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                              color: AppColors.textSecondaryDark,
                              size: 20,
                            ),
                            tooltip: _obscurePassword ? 'Mostrar contraseña' : 'Ocultar contraseña',
                            onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                          ),
                          validator: (val) {
                            if (val == null || val.trim().isEmpty) return 'La contraseña es requerida';
                            return null;
                          },
                        ),
                        const SizedBox(height: 10),

                        // Recordar Sesión & Olvidé mi contraseña
                        Wrap(
                          alignment: WrapAlignment.spaceBetween,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          spacing: 8,
                          runSpacing: 4,
                          children: [
                            InkWell(
                              onTap: () => setState(() => _rememberMe = !_rememberMe),
                              borderRadius: BorderRadius.circular(6),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  SizedBox(
                                    width: 24,
                                    height: 24,
                                    child: Checkbox(
                                      value: _rememberMe,
                                      activeColor: AppColors.cyanWater,
                                      checkColor: Colors.black,
                                      side: BorderSide(color: Colors.white.withValues(alpha: 0.3)),
                                      onChanged: (val) => setState(() => _rememberMe = val ?? true),
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    'Recordarme',
                                    style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondaryDark),
                                  ),
                                ],
                              ),
                            ),
                            TextButton(
                              style: TextButton.styleFrom(
                                padding: EdgeInsets.zero,
                                minimumSize: Size.zero,
                                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              ),
                              onPressed: _showForgotPasswordModal,
                              child: Text(
                                '¿Olvidaste tu contraseña?',
                                style: AppTypography.bodySmall.copyWith(
                                  color: AppColors.cyanWater,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),

                        GlassButton(
                          label: 'Ingresar',
                          isLoading: authState.isLoading,
                          onPressed: _handleLogin,
                        ),
                        const SizedBox(height: 12),

                        // Botón de Inicio con Google / Gmail
                        InkWell(
                          onTap: _handleGoogleLogin,
                          borderRadius: BorderRadius.circular(16),
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(vertical: 13, horizontal: 16),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
                            ),
                            child: FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  SvgPicture.network(
                                    'https://www.gstatic.com/firebasejs/ui/2.0.0/images/auth/google.svg',
                                    width: 20,
                                    height: 20,
                                    placeholderBuilder: (_) => const Icon(
                                      Icons.g_mobiledata_rounded,
                                      color: Colors.white,
                                      size: 24,
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Text(
                                    'Continuar con Google',
                                    style: AppTypography.titleMedium.copyWith(
                                      color: Colors.white,
                                      fontSize: 14,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),

                        // Registro de Nueva Empresa
                        Center(
                          child: GestureDetector(
                            onTap: () => context.go('/register'),
                            child: RichText(
                              text: TextSpan(
                                text: '¿No tienes cuenta? ',
                                style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondaryDark),
                                children: [
                                  TextSpan(
                                    text: 'Regístrate aquí',
                                    style: AppTypography.bodySmall.copyWith(
                                      color: AppColors.cyanWater,
                                      fontWeight: FontWeight.w700,
                                      decoration: TextDecoration.underline,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(height: 20),

                        // Accesos Directos de Contacto (WhatsApp & Instagram) Responsivos
                        Wrap(
                          alignment: WrapAlignment.center,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          spacing: 10,
                          runSpacing: 8,
                          children: [
                            // Botón WhatsApp Soporte
                            InkWell(
                              borderRadius: BorderRadius.circular(14),
                              onTap: () async {
                                final Uri whatsappUri = Uri.parse('https://wa.me/573003420063?text=Hola%20Equipo%20de%20Soporte%20FishBit%2C%20requiero%20asistencia%20con%20mi%20cuenta.');
                                try {
                                  await launchUrl(whatsappUri, mode: LaunchMode.externalApplication);
                                } catch (_) {}
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF25D366).withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(
                                    color: const Color(0xFF25D366).withValues(alpha: 0.35),
                                    width: 1,
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(
                                      FishBitIcons.whatsapp,
                                      color: Color(0xFF25D366),
                                      size: 16,
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      'Soporte',
                                      style: AppTypography.bodySmall.copyWith(
                                        color: const Color(0xFF25D366),
                                        fontWeight: FontWeight.w700,
                                        fontSize: 11.5,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),

                            // Botón Instagram (@groupgalapagos)
                            InkWell(
                              borderRadius: BorderRadius.circular(14),
                              onTap: () async {
                                final Uri instaUri = Uri.parse('https://instagram.com/groupgalapagos');
                                try {
                                  await launchUrl(instaUri, mode: LaunchMode.externalApplication);
                                } catch (_) {}
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFE1306C).withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(
                                    color: const Color(0xFFE1306C).withValues(alpha: 0.35),
                                    width: 1,
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(
                                      FishBitIcons.instagram,
                                      color: Color(0xFFE1306C),
                                      size: 16,
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      '@groupgalapagos',
                                      style: AppTypography.bodySmall.copyWith(
                                        color: const Color(0xFFE1306C),
                                        fontWeight: FontWeight.w700,
                                        fontSize: 11.5,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 18),
                        Text(
                          '© 2026 Grupo Galápagos • Soporte +57 300 342 0063',
                          textAlign: TextAlign.center,
                          style: AppTypography.labelMicro.copyWith(color: AppColors.textSecondaryDark),
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
