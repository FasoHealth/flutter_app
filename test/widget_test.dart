// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter_test/flutter_test.dart';

import 'package:community_security_alert_app_flutter/main.dart';

void main() {
  testWidgets('Login page is displayed when not logged in', (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp(initialLoggedIn: false, initialDarkMode: true));
    expect(find.text('CSA Mobile'), findsOneWidget);
    expect(find.text('SE CONNECTER'), findsOneWidget);
  });
}
