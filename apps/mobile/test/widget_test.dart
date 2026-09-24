import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:opencaller_mobile/core/localization/locale_provider.dart';
import 'package:opencaller_mobile/main.dart';

class TestLocaleNotifier extends LocaleNotifier {
  TestLocaleNotifier(Locale? locale) {
    state = locale;
  }
}

void main() {
  testWidgets('OpenCaller App smoke test and shell render (EN)', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: OpenCallerApp(hasCompletedOnboarding: true),
      ),
    );

    // Verify OpenCaller header is present
    expect(find.text('OpenCaller'), findsOneWidget);
    expect(find.text('Lookup'), findsOneWidget);
  });

  testWidgets('OpenCaller Onboarding flow render test (EN default)', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: OpenCallerApp(hasCompletedOnboarding: false),
      ),
    );

    // Verify Onboarding manifesto title is present in English
    expect(find.text('The 100% Free, Private & Community Caller ID'), findsOneWidget);
    expect(find.text('Start Configuration'), findsOneWidget);
  });

  testWidgets('OpenCaller Onboarding flow render test (ES override)', (WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          localeProvider.overrideWith((ref) => TestLocaleNotifier(const Locale('es'))),
        ],
        child: const OpenCallerApp(hasCompletedOnboarding: false),
      ),
    );

    // Verify Onboarding manifesto title is present in Spanish
    expect(find.text('El Identificador de Llamadas 100% Libre, Privado y Comunitario'), findsOneWidget);
    expect(find.text('Comenzar Configuración'), findsOneWidget);
  });

  testWidgets('OpenCaller Onboarding flow render test (PT override)', (WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          localeProvider.overrideWith((ref) => TestLocaleNotifier(const Locale('pt'))),
        ],
        child: const OpenCallerApp(hasCompletedOnboarding: false),
      ),
    );

    // Verify Onboarding manifesto title is present in Portuguese
    expect(find.text('O Identificador de Chamadas 100% Livre, Privado e Comunitário'), findsOneWidget);
    expect(find.text('Iniciar Configuração'), findsOneWidget);
  });
}
