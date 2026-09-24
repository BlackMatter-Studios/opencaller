import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:opencaller_mobile/main.dart';

void main() {
  testWidgets('OpenCaller App smoke test and shell render', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: OpenCallerApp(),
      ),
    );

    // Verify OpenCaller header is present
    expect(find.text('OpenCaller'), findsOneWidget);
    expect(find.text('Lookup'), findsOneWidget);
  });
}
