import 'package:flutter_test/flutter_test.dart';
import 'package:aira_mobile/main.dart';

void main() {
  testWidgets('Tria app launch test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const TriaTravelApp());

    // Verify that our app starts on the Splash screen showing 'Tria'.
    expect(find.text('Tria'), findsOneWidget);
  });
}
