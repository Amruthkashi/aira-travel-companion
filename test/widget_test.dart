import 'package:flutter_test/flutter_test.dart';
import 'package:aira_mobile/main.dart';

void main() {
  testWidgets('Aira app launch test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const AiraTravelApp());

    // Verify that our app starts on the Splash screen showing 'Aira'.
    expect(find.text('Aira'), findsOneWidget);
  });
}
