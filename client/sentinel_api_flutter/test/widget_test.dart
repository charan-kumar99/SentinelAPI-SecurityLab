import 'package:flutter_test/flutter_test.dart';
import 'package:sentinel_api_flutter/main.dart';

void main() {
  testWidgets('SentinelAPI Flutter App smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const SentinelApiApp());

    // Verify brand header is rendered
    expect(find.text('SENTINEL API'), findsOneWidget);
    expect(find.text('SECURITY LAB'), findsOneWidget);
  });
}
