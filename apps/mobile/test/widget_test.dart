import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:opencaller_mobile/main.dart';

void main() {
  testWidgets('OpenCaller App smoke test and shell render', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: OpenCallerApp(hasCompletedOnboarding: true),
      ),
    );

    // Verify OpenCaller header is present
    expect(find.text('OpenCaller'), findsOneWidget);
    expect(find.text('Lookup'), findsOneWidget);
  });

  testWidgets('OpenCaller Onboarding flow render test', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: OpenCallerApp(hasCompletedOnboarding: false),
      ),
    );

    // Verify Onboarding manifesto title is present
    expect(find.text('El Identificador de Llamadas 100% Libre, Privado y Comunitario'), findsOneWidget);
    expect(find.text('Comenzar Configuración'), findsOneWidget);
  });
}
