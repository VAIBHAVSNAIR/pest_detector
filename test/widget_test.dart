import 'package:flutter_test/flutter_test.dart';

import 'package:pest_detector/main.dart';

void main() {
  testWidgets('home shows truthful status and tabs open', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const PestGuardApp());

    expect(find.text('Good day, Farmer'), findsOneWidget);
    expect(find.text('AI offline'), findsOneWidget);

    await tester.tap(find.text('Scan'));
    await tester.pumpAndSettle();
    expect(find.text('Crop scanner'), findsOneWidget);

    await tester.tap(find.text('History'));
    await tester.pumpAndSettle();
    expect(find.text('No scans yet'), findsOneWidget);
  });
}
