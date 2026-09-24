import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'core/localization/locale_provider.dart';
import 'core/theme/glass_colors.dart';
import 'features/home_shell.dart';
import 'features/onboarding/onboarding_screen.dart';
import 'l10n/app_localizations.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final prefs = await SharedPreferences.getInstance();
  final hasCompletedOnboarding = prefs.getBool('has_completed_onboarding') ?? false;

  runApp(ProviderScope(
    child: OpenCallerApp(hasCompletedOnboarding: hasCompletedOnboarding),
  ));
}

class OpenCallerApp extends ConsumerWidget {
  final bool? hasCompletedOnboarding;
  const OpenCallerApp({super.key, this.hasCompletedOnboarding});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentLocale = ref.watch(localeProvider);

    return MaterialApp(
      title: 'OpenCaller',
      debugShowCheckedModeBanner: false,
      locale: currentLocale,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: GlassColors.deepSpace,
        colorScheme: ColorScheme.fromSeed(
          seedColor: GlassColors.neonCyan,
          brightness: Brightness.dark,
          surface: GlassColors.darkSurface,
        ),
        fontFamily: 'Roboto',
      ),
      home: (hasCompletedOnboarding == true) ? const HomeShell() : const OnboardingScreen(),
    );
  }
}
