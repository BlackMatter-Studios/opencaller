import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/localization/locale_provider.dart';
import '../../core/providers.dart';
import '../../core/theme/app_typography.dart';
import '../../core/theme/glass_colors.dart';
import '../../core/theme/neon_glow_button.dart';
import '../../core/theme/platform_glass_surface.dart';
import '../../l10n/app_localizations.dart';
import '../onboarding/onboarding_screen.dart';

class PrivacyScreen extends ConsumerStatefulWidget {
  const PrivacyScreen({super.key});

  @override
  ConsumerState<PrivacyScreen> createState() => _PrivacyScreenState();
}

class _PrivacyScreenState extends ConsumerState<PrivacyScreen> {
  bool _shareContactsEnabled = false;
  bool _excludeFavorites = true;
  bool _excludePrivateNotes = true;
  final TextEditingController _delistController = TextEditingController();
  bool _isDelisting = false;

  Widget _buildLanguageChip(WidgetRef ref, String? code, String label) {
    final currentLocale = ref.watch(localeProvider);
    final isSelected = (code == null && currentLocale == null) || (currentLocale?.languageCode == code);

    return Expanded(
      child: InkWell(
        onTap: () {
          ref.read(localeProvider.notifier).setLocale(code);
        },
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: isSelected ? GlassColors.neonCyan.withValues(alpha: 0.2) : GlassColors.glassFill,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected ? GlassColors.neonCyan : GlassColors.glassBorder,
              width: isSelected ? 1.5 : 1,
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              color: isSelected ? Colors.white : GlassColors.textSecondary,
            ),
          ),
        ),
      ),
    );
  }

  void _confirmEnableCommunitySharing(bool value) {
    if (!value) {
      setState(() => _shareContactsEnabled = false);
      return;
    }

    final l10n = AppLocalizations.of(context);
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: GlassColors.darkSurface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: const BorderSide(color: GlassColors.glassBorder),
          ),
          title: Row(
            children: [
              const Icon(Icons.shield_outlined, color: GlassColors.neonCyan),
              const SizedBox(width: 10),
              Text(l10n?.consentModalTitle ?? 'Community Caller ID', style: AppTypography.titleMedium),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l10n?.shareContactsDesc ?? 'By enabling this choice, your device contributes contact names to help identify incoming business and service calls.',
                style: AppTypography.bodyMedium,
              ),
              const SizedBox(height: 12),
              Text(
                l10n?.consentModalDesc ?? '• Strict Consensus: A name is only made visible once 3 or more independent users suggest it.\n'
                '• Zero Personal Data: Emails, photos, and physical addresses are NEVER accessed or transmitted.\n'
                '• Right to Opt-Out: Anyone can delist their number at any time.',
                style: const TextStyle(color: GlassColors.textSecondary, fontSize: 13, height: 1.4),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(l10n?.cancel ?? 'Cancel', style: const TextStyle(color: GlassColors.textMuted)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: GlassColors.neonCyan,
                foregroundColor: Colors.black,
              ),
              onPressed: () {
                Navigator.pop(context);
                setState(() => _shareContactsEnabled = true);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(l10n?.consentModalFeedback ?? 'Community sharing enabled with privacy safeguards.')),
                );
              },
              child: Text(l10n?.consentModalAgree ?? 'I Understand & Consent'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _handleDelistRequest() async {
    final l10n = AppLocalizations.of(context);
    final raw = _delistController.text.trim();
    final digits = raw.replaceAll(RegExp(r'[^\d]'), '');
    if (digits.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n?.delistNumberHint ?? 'Please enter a valid phone number with country code')),
      );
      return;
    }

    final e164 = int.tryParse(digits);
    if (e164 == null) return;

    setState(() => _isDelisting = true);
    try {
      final client = ref.read(apiClientProvider);
      final res = await client.delistNumber(e164Number: e164, reason: 'User requested self-delist');
      if (mounted) {
        _delistController.clear();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(res['message'] as String? ?? (l10n?.delistSuccess ?? 'Number successfully delisted!'))),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${l10n?.error ?? "Error"}: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isDelisting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      backgroundColor: GlassColors.deepSpace,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(l10n?.privacyTitle ?? 'Privacy & Sovereignty', style: AppTypography.headlineMedium),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Language Selector Card
            PlatformGlassSurface(
              padding: const EdgeInsets.all(18),
              borderRadius: BorderRadius.circular(20),
              borderColor: GlassColors.neonCyan.withValues(alpha: 0.3),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: GlassColors.neonCyan.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.language_rounded, color: GlassColors.neonCyan, size: 22),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(l10n?.languageTitle ?? 'Application Language', style: AppTypography.titleMedium),
                            const SizedBox(height: 2),
                            Text(
                              l10n?.languageSystem ?? 'System Default',
                              style: AppTypography.bodyMedium.copyWith(color: GlassColors.textSecondary, fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      _buildLanguageChip(ref, null, '🌐 Auto'),
                      const SizedBox(width: 6),
                      _buildLanguageChip(ref, 'en', '🇺🇸 EN'),
                      const SizedBox(width: 6),
                      _buildLanguageChip(ref, 'es', '🇪🇸 ES'),
                      const SizedBox(width: 6),
                      _buildLanguageChip(ref, 'pt', '🇧🇷 PT'),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            // Manifesto Card
            PlatformGlassSurface(
              padding: const EdgeInsets.all(20),
              borderRadius: BorderRadius.circular(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.lock_outline_rounded, color: GlassColors.neonCyan),
                      const SizedBox(width: 10),
                      Text(l10n?.privacyManifesto ?? 'Zero Commercial Tracking', style: AppTypography.titleMedium),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    l10n?.privacyManifestoDesc ?? 'OpenCaller is self-hosted, 100% open source, and federated. Your activity is never tracked, aggregated, or sold. You maintain complete control over your telephony data.',
                    style: AppTypography.bodyMedium,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Material(
              color: Colors.transparent,
              borderRadius: BorderRadius.circular(20),
              clipBehavior: Clip.antiAlias,
              child: InkWell(
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const OnboardingScreen()),
                  );
                },
                child: PlatformGlassSurface(
                  padding: const EdgeInsets.all(16),
                  borderRadius: BorderRadius.circular(20),
                  borderColor: GlassColors.cyberBlue.withValues(alpha: 0.4),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: GlassColors.cyberBlue.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.explore_rounded, color: GlassColors.cyberBlue, size: 24),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(l10n?.reopenOnboarding ?? 'Asistente de Soberanía & Verificación', style: AppTypography.titleMedium.copyWith(fontSize: 14)),
                            const SizedBox(height: 2),
                            Text(
                              l10n?.reopenOnboardingDesc ?? 'Revisa el manifiesto, cambia tu nivel de privacidad o verifica tu cuenta.',
                              style: AppTypography.bodyMedium.copyWith(fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                      const Icon(Icons.arrow_forward_ios_rounded, color: GlassColors.cyberBlue, size: 16),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),
            Text(l10n?.crowdsourcingControls ?? 'COMMUNITY CROWDSOURCING CONTROLS', style: AppTypography.badgeText.copyWith(color: GlassColors.neonCyan)),
            const SizedBox(height: 12),
            PlatformGlassSurface(
              padding: const EdgeInsets.all(16),
              borderRadius: BorderRadius.circular(20),
              child: Column(
                children: [
                  SwitchListTile(
                    activeThumbColor: GlassColors.neonCyan,
                    contentPadding: EdgeInsets.zero,
                    title: Text(l10n?.shareContactsTitle ?? 'Share Contacts to Community Directory', style: AppTypography.titleMedium),
                    subtitle: Text(
                      l10n?.shareContactsDesc ?? 'Help identify local businesses and service drivers. Strict 3-vote consensus required before publication.',
                      style: AppTypography.bodyMedium,
                    ),
                    value: _shareContactsEnabled,
                    onChanged: _confirmEnableCommunitySharing,
                  ),
                  const Divider(color: GlassColors.glassBorder),
                  SwitchListTile(
                    activeThumbColor: GlassColors.neonCyan,
                    contentPadding: EdgeInsets.zero,
                    title: Text(l10n?.excludeStarredTitle ?? 'Exclude Starred / Family Contacts', style: AppTypography.titleMedium),
                    subtitle: Text(
                      l10n?.excludeStarredDesc ?? 'Personal friends and favorites are never transmitted under any circumstances.',
                      style: AppTypography.bodyMedium,
                    ),
                    value: _excludeFavorites,
                    onChanged: (val) => setState(() => _excludeFavorites = val),
                  ),
                  const Divider(color: GlassColors.glassBorder),
                  SwitchListTile(
                    activeThumbColor: GlassColors.neonCyan,
                    contentPadding: EdgeInsets.zero,
                    title: Text(l10n?.stripMetadataTitle ?? 'Strip Private Metadata', style: AppTypography.titleMedium),
                    subtitle: Text(
                      l10n?.stripMetadataDesc ?? 'Emails, addresses, birthdays, and relationship notes stay strictly on-device.',
                      style: AppTypography.bodyMedium,
                    ),
                    value: _excludePrivateNotes,
                    onChanged: (val) => setState(() => _excludePrivateNotes = val),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 28),
            Text(l10n?.delistTitle.toUpperCase() ?? 'RIGHT TO BE FORGOTTEN (DELIST NUMBER)', style: AppTypography.badgeText.copyWith(color: GlassColors.severeScam)),
            const SizedBox(height: 12),
            PlatformGlassSurface(
              padding: const EdgeInsets.all(20),
              borderRadius: BorderRadius.circular(20),
              borderColor: GlassColors.severeScam.withValues(alpha: 0.3),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(l10n?.delistTitle ?? 'Remove Number from Public Index', style: AppTypography.titleMedium),
                  const SizedBox(height: 6),
                  Text(
                    l10n?.delistDesc ?? 'Want to keep your number completely private? Enter your E.164 number below to purge it from caller identification across all federated OpenCaller nodes.',
                    style: AppTypography.bodyMedium,
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _delistController,
                    keyboardType: TextInputType.phone,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      hintText: l10n?.delistNumberHint ?? '+506 8888 8888',
                      hintStyle: const TextStyle(color: GlassColors.textMuted),
                      filled: true,
                      fillColor: GlassColors.glassFill,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: const BorderSide(color: GlassColors.glassBorder),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  NeonGlowButton(
                    text: l10n?.delistButton ?? 'Delist & Purge Number',
                    glowColor: GlassColors.severeScam,
                    isLoading: _isDelisting,
                    onPressed: _handleDelistRequest,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
