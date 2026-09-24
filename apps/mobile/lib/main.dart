import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/theme/glass_colors.dart';
import 'features/home_shell.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const ProviderScope(child: OpenCallerApp()));
}

class OpenCallerApp extends StatelessWidget {
  const OpenCallerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'OpenCaller',
      debugShowCheckedModeBanner: false,
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
      home: const HomeShell(),
    );
  }
}
