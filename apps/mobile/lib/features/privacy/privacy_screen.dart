import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/providers.dart';
import '../../core/theme/app_typography.dart';
import '../../core/theme/glass_colors.dart';
import '../../core/theme/neon_glow_button.dart';
import '../../core/theme/platform_glass_surface.dart';

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

  void _confirmEnableCommunitySharing(bool value) {
    if (!value) {
      setState(() => _shareContactsEnabled = false);
      return;
    }

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
              Text('Community Caller ID', style: AppTypography.titleMedium),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'By enabling this choice, your device contributes contact names to help identify incoming business and service calls.',
                style: AppTypography.bodyMedium,
              ),
              const SizedBox(height: 12),
              const Text(
                '• Strict Consensus: A name is only made visible once 3 or more independent users suggest it.\n'
                '• Zero Personal Data: Emails, photos, and physical addresses are NEVER accessed or transmitted.\n'
                '• Right to Opt-Out: Anyone can delist their number at any time.',
                style: TextStyle(color: GlassColors.textSecondary, fontSize: 13, height: 1.4),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel', style: TextStyle(color: GlassColors.textMuted)),
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
                  const SnackBar(content: Text('Community sharing enabled with privacy safeguards.')),
                );
              },
              child: const Text('I Understand & Consent'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _handleDelistRequest() async {
    final raw = _delistController.text.trim();
    final digits = raw.replaceAll(RegExp(r'[^\d]'), '');
    if (digits.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid phone number with country code')),
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
          SnackBar(content: Text(res['message'] as String? ?? 'Number successfully delisted!')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Delist request failed: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isDelisting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: GlassColors.deepSpace,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text('Privacy & Sovereignty', style: AppTypography.headlineMedium),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
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
                      Text('Zero Commercial Tracking', style: AppTypography.titleMedium),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'OpenCaller is self-hosted, 100% open source, and federated. Your activity is never tracked, aggregated, or sold. You maintain complete control over your telephony data.',
                    style: AppTypography.bodyMedium,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Text('COMMUNITY CROWDSOURCING CONTROLS', style: AppTypography.badgeText.copyWith(color: GlassColors.neonCyan)),
            const SizedBox(height: 12),
            PlatformGlassSurface(
              padding: const EdgeInsets.all(16),
              borderRadius: BorderRadius.circular(20),
              child: Column(
                children: [
                  SwitchListTile(
                    activeThumbColor: GlassColors.neonCyan,
                    contentPadding: EdgeInsets.zero,
                    title: Text('Share Contacts to Community Directory', style: AppTypography.titleMedium),
                    subtitle: Text(
                      'Help identify local businesses and service drivers. Strict 3-vote consensus required before publication.',
                      style: AppTypography.bodyMedium,
                    ),
                    value: _shareContactsEnabled,
                    onChanged: _confirmEnableCommunitySharing,
                  ),
                  const Divider(color: GlassColors.glassBorder),
                  SwitchListTile(
                    activeThumbColor: GlassColors.neonCyan,
                    contentPadding: EdgeInsets.zero,
                    title: Text('Exclude Starred / Family Contacts', style: AppTypography.titleMedium),
                    subtitle: Text(
                      'Personal friends and favorites are never transmitted under any circumstances.',
                      style: AppTypography.bodyMedium,
                    ),
                    value: _excludeFavorites,
                    onChanged: (val) => setState(() => _excludeFavorites = val),
                  ),
                  const Divider(color: GlassColors.glassBorder),
                  SwitchListTile(
                    activeThumbColor: GlassColors.neonCyan,
                    contentPadding: EdgeInsets.zero,
                    title: Text('Strip Private Metadata', style: AppTypography.titleMedium),
                    subtitle: Text(
                      'Emails, addresses, birthdays, and relationship notes stay strictly on-device.',
                      style: AppTypography.bodyMedium,
                    ),
                    value: _excludePrivateNotes,
                    onChanged: (val) => setState(() => _excludePrivateNotes = val),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 28),
            Text('RIGHT TO BE FORGOTTEN (DELIST NUMBER)', style: AppTypography.badgeText.copyWith(color: GlassColors.severeScam)),
            const SizedBox(height: 12),
            PlatformGlassSurface(
              padding: const EdgeInsets.all(20),
              borderRadius: BorderRadius.circular(20),
              borderColor: GlassColors.severeScam.withValues(alpha: 0.3),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Remove Number from Public Index', style: AppTypography.titleMedium),
                  const SizedBox(height: 6),
                  Text(
                    'Want to keep your number completely private? Enter your E.164 number below to purge it from caller identification across all federated OpenCaller nodes.',
                    style: AppTypography.bodyMedium,
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _delistController,
                    keyboardType: TextInputType.phone,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      hintText: '+506 8888 8888',
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
                    text: 'Delist & Purge Number',
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
