import 'package:flutter_test/flutter_test.dart';

import 'package:umart_app/main.dart';

void main() {
  testWidgets('UMART home screen smoke test', (WidgetTester tester) async {
    // Build the app and trigger a frame.
    await tester.pumpWidget(const UMartApp());

    // Verify key UI elements are present.
    expect(find.text('Food'), findsOneWidget);
    expect(find.text('Parcel & more'), findsOneWidget);
    expect(find.text('Preloved'), findsOneWidget);
  });
}