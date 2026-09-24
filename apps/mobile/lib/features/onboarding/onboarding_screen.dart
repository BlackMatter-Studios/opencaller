import 'dart:convert';
import 'dart:io';
import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/providers.dart';
import '../../core/telephony/telephony_platform.dart';
import '../../core/theme/app_typography.dart';
import '../../core/theme/glass_colors.dart';
import '../../core/theme/neon_glow_button.dart';
import '../../core/theme/platform_glass_surface.dart';
import '../home_shell.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  // Sovereignty choice (0: Offline, 1: Cloud Intelligence, 2: Community Contributor)
  int _sovereigntyTier = 1;

  // Multi-Channel Verification
  String _selectedChannel = 'anonymous_pow'; // 'telegram', 'whatsapp', 'android_gateway', 'anonymous_pow'
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _otpController = TextEditingController();
  String? _sessionId;
  String? _otpInstructions;
  bool _isRequestingOtp = false;
  bool _isVerifyingOtp = false;
  bool _isAccountVerified = false;
  String? _verifiedBadgeLabel;

  // Shield status
  bool _isScreeningEnabled = false;
  int _iosStatus = 0;

  @override
  void initState() {
    super.initState();
    _checkShieldStatus();
  }

  Future<void> _checkShieldStatus() async {
    if (!kIsWeb && Platform.isAndroid) {
      final enabled = await TelephonyPlatform.isCallScreeningEnabled();
      if (mounted) setState(() => _isScreeningEnabled = enabled);
    } else if (!kIsWeb && Platform.isIOS) {
      final status = await TelephonyPlatform.getCallDirectoryEnabledStatus();
      if (mounted) setState(() => _iosStatus = status);
    }
  }

  Future<void> _requestAndroidRole() async {
    final granted = await TelephonyPlatform.requestCallScreeningRole();
    if (mounted) setState(() => _isScreeningEnabled = granted);
  }

  void _nextPage() {
    if (_currentPage < 4) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeInOutCubic,
      );
    }
  }

  void _prevPage() {
    if (_currentPage > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeInOutCubic,
      );
    }
  }

  Future<void> _finishOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('has_completed_onboarding', true);
    await prefs.setInt('sovereignty_tier', _sovereigntyTier);
    await prefs.setBool('share_contacts_enabled', _sovereigntyTier == 2);

    if (mounted) {
      Navigator.of(context).pushReplacement(
        PageRouteBuilder(
          transitionDuration: const Duration(milliseconds: 600),
          pageBuilder: (context, animation, secondaryAnimation) => FadeTransition(
            opacity: animation,
            child: const HomeShell(),
          ),
        ),
      );
    }
  }

  // Verification Logic
  Future<void> _handleRequestOtp() async {
    setState(() => _isRequestingOtp = true);
    try {
      final client = ref.read(apiClientProvider);
      final phone = _phoneController.text.trim().replaceAll(RegExp(r'[^\d+]'), '');
      final res = await client.requestOtp(
        channel: _selectedChannel,
        phoneNumber: phone.isNotEmpty ? phone : null,
      );
      if (mounted) {
        setState(() {
          _sessionId = res['session_id'] as String?;
          _otpInstructions = res['instructions'] as String?;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_otpInstructions ?? 'Código solicitado'),
            backgroundColor: GlassColors.cyberBlue,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error solicitando código: $e'), backgroundColor: GlassColors.severeScam),
        );
      }
    } finally {
      if (mounted) setState(() => _isRequestingOtp = false);
    }
  }

  Future<void> _handleVerifyOtp() async {
    final code = _otpController.text.trim();
    if (_sessionId == null || code.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ingresa el código OTP de 6 dígitos')),
      );
      return;
    }

    setState(() => _isVerifyingOtp = true);
    try {
      final client = ref.read(apiClientProvider);
      await client.verifyOtp(sessionId: _sessionId!, code: code);
      if (mounted) {
        setState(() {
          _isAccountVerified = true;
          _verifiedBadgeLabel = 'Verificado vía ${_selectedChannel.toUpperCase()}';
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('¡Cuenta verificada exitosamente!'), backgroundColor: GlassColors.cleanVerified),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Verificación fallida: $e'), backgroundColor: GlassColors.severeScam),
        );
      }
    } finally {
      if (mounted) setState(() => _isVerifyingOtp = false);
    }
  }

  Future<void> _handleAnonymousPoW() async {
    setState(() => _isVerifyingOtp = true);
    try {
      final client = ref.read(apiClientProvider);
      final prefs = await SharedPreferences.getInstance();
      var fingerprint = prefs.getString('device_fingerprint');
      if (fingerprint == null) {
        fingerprint = 'dev_${DateTime.now().millisecondsSinceEpoch}_${(1000 + (DateTime.now().microsecond % 9000))}';
        await prefs.setString('device_fingerprint', fingerprint);
      }

      // Compute client-side Proof-of-Work: sha256(fingerprint:nonce) starting with "0000"
      int nonce = 0;
      while (true) {
        final challenge = '$fingerprint:$nonce';
        final digest = sha256.convert(utf8.encode(challenge)).toString();
        if (digest.startsWith('0000')) {
          break;
        }
        nonce++;
      }

      await client.verifyAnonymousAttestation(
        deviceFingerprint: fingerprint,
        powNonce: nonce,
        clientPlatform: !kIsWeb && Platform.isIOS ? 'ios' : 'android',
      );

      if (mounted) {
        setState(() {
          _isAccountVerified = true;
          _verifiedBadgeLabel = 'Dispositivo Criptográficamente Blindado (Anónimo)';
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('¡Dispositivo anónimo verificado con prueba criptográfica!'),
            backgroundColor: GlassColors.cleanVerified,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error en prueba criptográfica: $e'), backgroundColor: GlassColors.severeScam),
        );
      }
    } finally {
      if (mounted) setState(() => _isVerifyingOtp = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: GlassColors.deepSpace,
      body: SafeArea(
        child: Column(
          children: [
            // Top App Bar with Step Indicator
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  if (_currentPage > 0)
                    IconButton(
                      icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white70, size: 20),
                      onPressed: _prevPage,
                    )
                  else
                    const SizedBox(width: 40),
                  Row(
                    children: List.generate(5, (index) {
                      final isActive = index == _currentPage;
                      return AnimatedContainer(
                        duration: const Duration(milliseconds: 250),
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        width: isActive ? 24 : 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: isActive ? GlassColors.neonCyan : GlassColors.textMuted.withValues(alpha: 0.3),
                          borderRadius: BorderRadius.circular(4),
                          boxShadow: isActive
                              ? [
                                  BoxShadow(
                                    color: GlassColors.neonCyan.withValues(alpha: 0.6),
                                    blurRadius: 8,
                                  ),
                                ]
                              : null,
                        ),
                      );
                    }),
                  ),
                  TextButton(
                    onPressed: _finishOnboarding,
                    child: Text(
                      _currentPage == 4 ? '' : 'Omitir',
                      style: const TextStyle(color: GlassColors.textMuted),
                    ),
                  ),
                ],
              ),
            ),
            // Page Slider
            Expanded(
              child: PageView(
                controller: _pageController,
                physics: const BouncingScrollPhysics(),
                onPageChanged: (page) => setState(() => _currentPage = page),
                children: [
                  _buildSlide1Manifesto(),
                  _buildSlide2SovereigntyTiers(),
                  _buildSlide3Verification(),
                  _buildSlide4TelephonyRole(),
                  _buildSlide5Ready(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- SLIDE 1: MANIFESTO ---
  Widget _buildSlide1Manifesto() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              gradient: GlassColors.cyanPurpleGradient,
              boxShadow: [
                BoxShadow(color: Color(0x6600E5FF), blurRadius: 30, spreadRadius: 4),
              ],
            ),
            child: const Icon(Icons.shield_rounded, size: 56, color: Colors.white),
          ),
          const SizedBox(height: 24),
          Text(
            'OpenCaller',
            style: AppTypography.displayLarge.copyWith(fontSize: 34, letterSpacing: -0.5),
          ),
          const SizedBox(height: 8),
          Text(
            'El Identificador de Llamadas 100% Libre, Privado y Comunitario',
            textAlign: TextAlign.center,
            style: AppTypography.bodyMedium.copyWith(fontSize: 15, color: GlassColors.neonCyan),
          ),
          const SizedBox(height: 28),
          _buildFeatureTile(
            Icons.speed_rounded,
            'Detección Local Instantánea (<10ms)',
            'Tu dispositivo consulta una base de datos local SQLite antes de que suene el teléfono. Cero latencia y cero llamadas a la nube para números conocidos.',
          ),
          const SizedBox(height: 16),
          _buildFeatureTile(
            Icons.visibility_off_rounded,
            'Cero Rastreo Comercial',
            'Sin SDKs de Facebook ni Google Ads. Tu historial y libreta jamás se venden. 100% código abierto bajo licencia MIT.',
          ),
          const SizedBox(height: 16),
          _buildFeatureTile(
            Icons.hub_rounded,
            'Poder Comunitario Federado',
            'Una red descentralizada donde los usuarios colaboran y verifican números con consenso democrático y gradual.',
          ),
          const SizedBox(height: 32),
          NeonGlowButton(
            text: 'Comenzar Configuración',
            glowColor: GlassColors.neonCyan,
            onPressed: _nextPage,
          ),
        ],
      ),
    );
  }

  // --- SLIDE 2: SOVEREIGNTY TIERS ---
  Widget _buildSlide2SovereigntyTiers() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Nivel de Privacidad', style: AppTypography.headlineMedium),
          const SizedBox(height: 6),
          Text(
            'Elige cómo interactúa OpenCaller con la red. Control total en tus manos:',
            style: AppTypography.bodyMedium,
          ),
          const SizedBox(height: 20),
          _buildTierCard(
            tierIndex: 0,
            icon: Icons.wifi_off_rounded,
            title: 'Nivel 0: Escudo 100% Offline',
            subtitle: 'Máxima anonimidad. Cero llamadas de red salientes. La app solo bloquea usando la base descargada localmente.',
            badge: 'AIR-GAPPED',
            color: Colors.white70,
          ),
          const SizedBox(height: 14),
          _buildTierCard(
            tierIndex: 1,
            icon: Icons.cloud_done_rounded,
            title: 'Nivel 1: Inteligencia de Red',
            subtitle: 'Recomendado. Consulta en tiempo real números desconocidos y recibe alertas de fraude sin compartir tus contactos.',
            badge: 'RECOMENDADO',
            color: GlassColors.neonCyan,
          ),
          const SizedBox(height: 14),
          _buildTierCard(
            tierIndex: 2,
            icon: Icons.people_alt_rounded,
            title: 'Nivel 2: Colaborador Híbrido',
            subtitle: 'Aporta nombres de comercios y servicios. Se excluyen automáticamente contactos favoritos, notas y datos personales.',
            badge: 'COMUNITARIO',
            color: const Color(0xFF10B981),
          ),
          const SizedBox(height: 28),
          NeonGlowButton(
            text: 'Confirmar y Continuar',
            glowColor: GlassColors.neonCyan,
            onPressed: _nextPage,
          ),
        ],
      ),
    );
  }

  // --- SLIDE 3: MULTI-CHANNEL VERIFICATION ---
  Widget _buildSlide3Verification() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Verificación Anti-Abuso', style: AppTypography.headlineMedium),
          const SizedBox(height: 6),
          Text(
            'Para proteger a la comunidad de bots sin costosos SMS corporativos, elije tu método:',
            style: AppTypography.bodyMedium,
          ),
          const SizedBox(height: 20),
          // Verified status card if already authenticated
          if (_isAccountVerified)
            PlatformGlassSurface(
              padding: const EdgeInsets.all(18),
              borderRadius: BorderRadius.circular(18),
              borderColor: GlassColors.cleanVerified,
              child: Row(
                children: [
                  const Icon(Icons.check_circle_rounded, color: GlassColors.cleanVerified, size: 28),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Dispositivo Verificado', style: AppTypography.titleMedium.copyWith(color: GlassColors.cleanVerified)),
                        const SizedBox(height: 2),
                        Text(_verifiedBadgeLabel ?? 'Autenticado correctamente', style: AppTypography.bodyMedium),
                      ],
                    ),
                  ),
                ],
              ),
            )
          else ...[
            // Channel Selector Grid
            Row(
              children: [
                Expanded(
                  child: _buildChannelOption(
                    id: 'anonymous_pow',
                    title: 'Anónimo (PoW)',
                    icon: Icons.fingerprint_rounded,
                    color: GlassColors.neonCyan,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _buildChannelOption(
                    id: 'telegram',
                    title: 'Telegram Bot',
                    icon: Icons.send_rounded,
                    color: GlassColors.cyberBlue,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: _buildChannelOption(
                    id: 'whatsapp',
                    title: 'WhatsApp (Baileys)',
                    icon: Icons.chat_rounded,
                    color: const Color(0xFF25D366),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _buildChannelOption(
                    id: 'android_gateway',
                    title: 'Android Gateway',
                    icon: Icons.phone_android_rounded,
                    color: const Color(0xFF9333EA),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            // Channel Action Form
            if (_selectedChannel == 'anonymous_pow')
              PlatformGlassSurface(
                padding: const EdgeInsets.all(18),
                borderRadius: BorderRadius.circular(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Verificación Criptográfica Local', style: AppTypography.titleMedium),
                    const SizedBox(height: 6),
                    Text(
                      'No requiere número de teléfono. Resuelve un Proof-of-Work SHA-256 en ~50ms en tu teléfono para probar que eres un dispositivo real y no un bot.',
                      style: AppTypography.bodyMedium,
                    ),
                    const SizedBox(height: 16),
                    NeonGlowButton(
                      text: 'Generar Credencial Anónima',
                      glowColor: GlassColors.neonCyan,
                      isLoading: _isVerifyingOtp,
                      onPressed: _handleAnonymousPoW,
                    ),
                  ],
                ),
              )
            else
              PlatformGlassSurface(
                padding: const EdgeInsets.all(18),
                borderRadius: BorderRadius.circular(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Ingresa tu Número Telefónico', style: AppTypography.titleMedium),
                    const SizedBox(height: 10),
                    TextField(
                      controller: _phoneController,
                      keyboardType: TextInputType.phone,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        hintText: '+506 8888 8888',
                        hintStyle: const TextStyle(color: GlassColors.textMuted),
                        filled: true,
                        fillColor: GlassColors.glassFill,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: GlassColors.glassBorder),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    NeonGlowButton(
                      text: 'Solicitar Código OTP',
                      glowColor: GlassColors.cyberBlue,
                      isLoading: _isRequestingOtp,
                      onPressed: _handleRequestOtp,
                    ),
                    if (_sessionId != null) ...[
                      const SizedBox(height: 16),
                      Text('Código de 6 Dígitos:', style: AppTypography.titleMedium),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _otpController,
                        keyboardType: TextInputType.number,
                        style: const TextStyle(color: Colors.white, letterSpacing: 4, fontSize: 18),
                        decoration: InputDecoration(
                          hintText: '123456',
                          hintStyle: const TextStyle(color: GlassColors.textMuted),
                          filled: true,
                          fillColor: GlassColors.glassFill,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: GlassColors.glassBorder),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      NeonGlowButton(
                        text: 'Verificar Código',
                        glowColor: GlassColors.cleanVerified,
                        isLoading: _isVerifyingOtp,
                        onPressed: _handleVerifyOtp,
                      ),
                    ],
                  ],
                ),
              ),
          ],
          const SizedBox(height: 28),
          NeonGlowButton(
            text: 'Siguiente Paso',
            glowColor: GlassColors.neonCyan,
            onPressed: _nextPage,
          ),
        ],
      ),
    );
  }

  // --- SLIDE 4: TELEPHONY ROLE ---
  Widget _buildSlide4TelephonyRole() {
    final isAndroid = !kIsWeb && Platform.isAndroid;
    final isIOS = !kIsWeb && Platform.isIOS;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Blindaje Telefónico Nativo', style: AppTypography.headlineMedium),
          const SizedBox(height: 6),
          Text(
            'Para silenciar o bloquear estafas antes de que tu teléfono empiece a timbrar:',
            style: AppTypography.bodyMedium,
          ),
          const SizedBox(height: 24),
          if (isAndroid)
            PlatformGlassSurface(
              padding: const EdgeInsets.all(20),
              borderRadius: BorderRadius.circular(20),
              borderColor: _isScreeningEnabled ? GlassColors.cleanVerified : GlassColors.warningSpam,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Rol de Detección de Llamadas', style: AppTypography.titleMedium),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: _isScreeningEnabled ? GlassColors.cleanVerifiedGlass : GlassColors.warningSpamGlass,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          _isScreeningEnabled ? 'ACTIVO' : 'PENDIENTE',
                          style: TextStyle(
                            color: _isScreeningEnabled ? GlassColors.cleanVerified : GlassColors.warningSpam,
                            fontWeight: FontWeight.bold,
                            fontSize: 11,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Permite que el servicio Android CallScreeningService intercepte llamadas entrantes en tiempo real con cero latencia.',
                    style: AppTypography.bodyMedium,
                  ),
                  const SizedBox(height: 18),
                  if (!_isScreeningEnabled)
                    NeonGlowButton(
                      text: 'Activar Permiso de Detección',
                      glowColor: GlassColors.neonCyan,
                      onPressed: _requestAndroidRole,
                    )
                  else
                    Row(
                      children: [
                        const Icon(Icons.check_circle_rounded, color: GlassColors.cleanVerified),
                        const SizedBox(width: 8),
                        Text('Filtro activo y listo en este dispositivo', style: TextStyle(color: GlassColors.cleanVerified)),
                      ],
                    ),
                ],
              ),
            ),
          if (isIOS)
            PlatformGlassSurface(
              padding: const EdgeInsets.all(20),
              borderRadius: BorderRadius.circular(20),
              borderColor: _iosStatus == 2 ? GlassColors.cleanVerified : GlassColors.neonCyan,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Extensión CallKit de iOS', style: AppTypography.titleMedium),
                  const SizedBox(height: 8),
                  const Text(
                    '1. Abre Ajustes de iPhone.\n'
                    '2. Ve a Teléfono > Bloqueo e ID de llamadas.\n'
                    '3. Activa OpenCaller.',
                    style: TextStyle(color: GlassColors.textSecondary, height: 1.4),
                  ),
                  const SizedBox(height: 16),
                  NeonGlowButton(
                    text: 'Abrir Ajustes de iOS',
                    glowColor: GlassColors.cyberBlue,
                    onPressed: () => TelephonyPlatform.openSystemSettings(),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 32),
          NeonGlowButton(
            text: 'Continuar',
            glowColor: GlassColors.neonCyan,
            onPressed: _nextPage,
          ),
        ],
      ),
    );
  }

  // --- SLIDE 5: READY ---
  Widget _buildSlide5Ready() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(24),
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: GlassColors.cleanVerifiedGlass,
              boxShadow: [
                BoxShadow(color: Color(0x6610B981), blurRadius: 30, spreadRadius: 4),
              ],
            ),
            child: const Icon(Icons.verified_rounded, size: 64, color: GlassColors.cleanVerified),
          ),
          const SizedBox(height: 24),
          Text('¡Todo Configurado!', style: AppTypography.displayLarge.copyWith(fontSize: 30)),
          const SizedBox(height: 8),
          Text(
            'Tu teléfono ahora está protegido con soberanía y privacidad.',
            textAlign: TextAlign.center,
            style: AppTypography.bodyMedium,
          ),
          const SizedBox(height: 28),
          PlatformGlassSurface(
            padding: const EdgeInsets.all(18),
            borderRadius: BorderRadius.circular(20),
            child: Column(
              children: [
                _buildSummaryRow(
                  'Nivel de Privacidad',
                  _sovereigntyTier == 0
                      ? 'Nivel 0 (100% Offline)'
                      : (_sovereigntyTier == 1 ? 'Nivel 1 (Nube)' : 'Nivel 2 (Comunitario)'),
                ),
                const Divider(color: GlassColors.glassBorder),
                _buildSummaryRow(
                  'Estado del Blindaje',
                  _isScreeningEnabled ? 'Activo (Call Screening)' : 'Configurable en Ajustes',
                ),
                const Divider(color: GlassColors.glassBorder),
                _buildSummaryRow(
                  'Verificación',
                  _isAccountVerified ? (_verifiedBadgeLabel ?? 'Verificado') : 'Modo Invitado',
                ),
              ],
            ),
          ),
          const SizedBox(height: 36),
          NeonGlowButton(
            text: 'Entrar a OpenCaller',
            glowColor: GlassColors.cleanVerified,
            onPressed: _finishOnboarding,
          ),
        ],
      ),
    );
  }

  // --- HELPER WIDGETS ---
  Widget _buildFeatureTile(IconData icon, String title, String description) {
    return PlatformGlassSurface(
      padding: const EdgeInsets.all(16),
      borderRadius: BorderRadius.circular(18),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: GlassColors.neonCyan.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: GlassColors.neonCyan, size: 24),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: AppTypography.titleMedium.copyWith(fontSize: 15)),
                const SizedBox(height: 4),
                Text(description, style: AppTypography.bodyMedium.copyWith(fontSize: 13, height: 1.4)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTierCard({
    required int tierIndex,
    required IconData icon,
    required String title,
    required String subtitle,
    required String badge,
    required Color color,
  }) {
    final isSelected = _sovereigntyTier == tierIndex;
    return GestureDetector(
      onTap: () => setState(() => _sovereigntyTier = tierIndex),
      child: PlatformGlassSurface(
        padding: const EdgeInsets.all(16),
        borderRadius: BorderRadius.circular(18),
        borderColor: isSelected ? color : GlassColors.glassBorder,
        borderWidth: isSelected ? 2.0 : 1.0,
        fillColor: isSelected ? color.withValues(alpha: 0.1) : null,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              isSelected ? Icons.radio_button_checked_rounded : Icons.radio_button_off_rounded,
              color: isSelected ? color : GlassColors.textMuted,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(title, style: AppTypography.titleMedium.copyWith(color: isSelected ? Colors.white : Colors.white70)),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: color.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(badge, style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(subtitle, style: AppTypography.bodyMedium.copyWith(fontSize: 13, height: 1.35)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChannelOption({
    required String id,
    required String title,
    required IconData icon,
    required Color color,
  }) {
    final isSelected = _selectedChannel == id;
    return GestureDetector(
      onTap: () => setState(() => _selectedChannel = id),
      child: PlatformGlassSurface(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
        borderRadius: BorderRadius.circular(16),
        borderColor: isSelected ? color : GlassColors.glassBorder,
        borderWidth: isSelected ? 2.0 : 1.0,
        fillColor: isSelected ? color.withValues(alpha: 0.15) : null,
        child: Column(
          children: [
            Icon(icon, color: isSelected ? color : GlassColors.textMuted, size: 26),
            const SizedBox(height: 8),
            Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: isSelected ? Colors.white : Colors.white70,
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(label, style: const TextStyle(color: GlassColors.textMuted, fontSize: 13)),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.end,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }
}
