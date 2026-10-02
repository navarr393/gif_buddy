import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:gif_buddy/main.dart';

void main() {
  testWidgets('badge text controls validate unsupported characters', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    await tester.pumpWidget(const MyApp());
    await tester.pumpAndSettle();
    expect(find.text('Scrolling badge text'), findsOneWidget);
    expect(find.text('Send text'), findsOneWidget);
    await tester.enterText(find.byType(TextField), 'hello 🌞');
    await tester.tap(find.text('Send text'));
    await tester.pumpAndSettle();
    expect(find.textContaining('no emoji'), findsOneWidget);
    expect(find.text('Send text'), findsOneWidget);
  });
}
