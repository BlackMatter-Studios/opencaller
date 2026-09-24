import 'package:flutter/material.dart';
import '../core/theme/glass_colors.dart';
import '../core/theme/platform_glass_surface.dart';
import '../l10n/app_localizations.dart';
import 'history/call_history_screen.dart';
import 'lookup/lookup_screen.dart';
import 'onboarding/setup_wizard_screen.dart';
import 'privacy/privacy_screen.dart';

class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _currentIndex = 0;

  final List<Widget> _screens = const [
    LookupScreen(),
    CallHistoryScreen(),
    PrivacyScreen(),
    SetupWizardScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      backgroundColor: GlassColors.deepSpace,
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: PlatformGlassSurface(
            borderRadius: BorderRadius.circular(24),
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildNavItem(0, Icons.search_rounded, l10n?.navLookup ?? 'Lookup'),
                _buildNavItem(1, Icons.history_rounded, l10n?.navHistory ?? 'Activity'),
                _buildNavItem(2, Icons.privacy_tip_outlined, l10n?.navPrivacy ?? 'Privacy'),
                _buildNavItem(3, Icons.shield_outlined, l10n?.navShield ?? 'Shield'),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(int index, IconData icon, String label) {
    final isSelected = _currentIndex == index;
    return GestureDetector(
      onTap: () => setState(() => _currentIndex = index),
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? GlassColors.neonCyan.withValues(alpha: 0.15) : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
          border: isSelected
              ? Border.all(color: GlassColors.neonCyan.withValues(alpha: 0.5), width: 1)
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: isSelected ? GlassColors.neonCyan : GlassColors.textMuted,
              size: 22,
            ),
            if (isSelected) ...[
              const SizedBox(width: 8),
              Text(
                label,
                style: const TextStyle(
                  color: GlassColors.neonCyan,
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
