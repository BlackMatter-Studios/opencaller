import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/telephony/telephony_platform.dart';
import '../../core/theme/app_typography.dart';
import '../../core/theme/glass_colors.dart';
import '../../core/theme/neon_glow_button.dart';
import '../../core/theme/platform_glass_surface.dart';

class SetupWizardScreen extends ConsumerStatefulWidget {
  const SetupWizardScreen({super.key});

  @override
  ConsumerState<SetupWizardScreen> createState() => _SetupWizardScreenState();
}

class _SetupWizardScreenState extends ConsumerState<SetupWizardScreen> {
  bool _isScreeningEnabled = false;
  int _iosExtensionStatus = 0; // 0: Unknown, 1: Disabled, 2: Enabled
  bool _isChecking = true;

  @override
  void initState() {
    super.initState();
    _checkStatus();
  }

  Future<void> _checkStatus() async {
    setState(() => _isChecking = true);
    if (!kIsWeb && Platform.isAndroid) {
      final enabled = await TelephonyPlatform.isCallScreeningEnabled();
      setState(() => _isScreeningEnabled = enabled);
    } else if (!kIsWeb && Platform.isIOS) {
      final status = await TelephonyPlatform.getCallDirectoryEnabledStatus();
      setState(() => _iosExtensionStatus = status);
    }
    setState(() => _isChecking = false);
  }

  Future<void> _requestAndroidRole() async {
    final granted = await TelephonyPlatform.requestCallScreeningRole();
    setState(() => _isScreeningEnabled = granted);
  }

  @override
  Widget build(BuildContext context) {
    final isAndroid = !kIsWeb && Platform.isAndroid;
    final isIOS = !kIsWeb && Platform.isIOS;

    return Scaffold(
      backgroundColor: GlassColors.deepSpace,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text('Telephony Defense Setup', style: AppTypography.headlineMedium),
        actions: [
          if (_isChecking)
            const Padding(
              padding: EdgeInsets.only(right: 16),
              child: SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 2, color: GlassColors.neonCyan),
              ),
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            PlatformGlassSurface(
              padding: const EdgeInsets.all(20),
              borderRadius: BorderRadius.circular(20),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: GlassColors.cyanPurpleGradient,
                    ),
                    child: const Icon(Icons.security_rounded, color: Colors.white, size: 24),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Native Call Shield', style: AppTypography.titleMedium),
                        const SizedBox(height: 4),
                        Text(
                          'OpenCaller runs locally to screen incoming calls with zero latency and zero data leakage.',
                          style: AppTypography.bodyMedium,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            if (isAndroid) _buildAndroidWizard(),
            if (isIOS) _buildIOSWizard(),
            if (!isAndroid && !isIOS)
              PlatformGlassSurface(
                padding: const EdgeInsets.all(20),
                borderRadius: BorderRadius.circular(20),
                child: Text(
                  'Telephony screening requires a physical Android or iOS device.',
                  style: AppTypography.bodyMedium,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildAndroidWizard() {
    return PlatformGlassSurface(
      padding: const EdgeInsets.all(22),
      borderRadius: BorderRadius.circular(22),
      borderColor: _isScreeningEnabled ? GlassColors.cleanVerified : GlassColors.warningSpam,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Android Call Screening Role', style: AppTypography.titleMedium),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: _isScreeningEnabled ? GlassColors.cleanVerifiedGlass : GlassColors.warningSpamGlass,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  _isScreeningEnabled ? 'ACTIVE' : 'ACTION REQUIRED',
                  style: AppTypography.badgeText.copyWith(
                    color: _isScreeningEnabled ? GlassColors.cleanVerified : GlassColors.warningSpam,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'Android requires granting the Call Screening role to allow OpenCaller to query the local SQLite database synchronously (<150ms) and silence or block spam calls before your phone rings.',
            style: AppTypography.bodyMedium,
          ),
          const SizedBox(height: 20),
          if (!_isScreeningEnabled)
            NeonGlowButton(
              text: 'Set as Call Screening App',
              glowColor: GlassColors.neonCyan,
              onPressed: _requestAndroidRole,
            )
          else
            Row(
              children: [
                const Icon(Icons.check_circle_rounded, color: GlassColors.cleanVerified),
                const SizedBox(width: 8),
                Text('Real-time screening active on this device', style: AppTypography.bodyMedium.copyWith(color: GlassColors.cleanVerified)),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildIOSWizard() {
    final isEnabled = _iosExtensionStatus == 2;

    return PlatformGlassSurface(
      padding: const EdgeInsets.all(22),
      borderRadius: BorderRadius.circular(22),
      borderColor: isEnabled ? GlassColors.cleanVerified : GlassColors.neonCyan,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('iOS Call Directory Extension', style: AppTypography.titleMedium),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: isEnabled ? GlassColors.cleanVerifiedGlass : GlassColors.neonCyanDim,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  isEnabled ? 'ENABLED' : 'SETUP NEEDED',
                  style: AppTypography.badgeText.copyWith(
                    color: isEnabled ? GlassColors.cleanVerified : GlassColors.neonCyan,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'On iOS, OpenCaller loads pre-sorted spam and community numbers into the iOS telephony database via CallKit. Apple requires toggling this extension once in System Settings.',
            style: AppTypography.bodyMedium,
          ),
          const SizedBox(height: 14),
          const Text(
            'Instructions:\n'
            '1. Tap "Open iPhone Settings" below.\n'
            '2. Go to Phone > Call Blocking & Identification.\n'
            '3. Turn ON "OpenCaller".',
            style: TextStyle(color: GlassColors.textSecondary, height: 1.4),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: NeonGlowButton(
                  text: 'Open iPhone Settings',
                  glowColor: GlassColors.cyberBlue,
                  onPressed: () => TelephonyPlatform.openSystemSettings(),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: TextButton.icon(
                  icon: const Icon(Icons.refresh_rounded, color: GlassColors.neonCyan, size: 18),
                  label: const Text('Refresh Status / Reload Extension', style: TextStyle(color: GlassColors.neonCyan)),
                  onPressed: () async {
                    await TelephonyPlatform.reloadCallDirectoryExtension();
                    _checkStatus();
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
