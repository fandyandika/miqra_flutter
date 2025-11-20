// Basic Flutter widget test for Miqra app
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:miqra_flutter/main.dart';

void main() {
  testWidgets('Miqra app starts without crashing', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const ProviderScope(child: MiqraApp()));

    // Wait for the app to fully load
    await tester.pumpAndSettle();

    // The app should load without crashing
    // This is a basic smoke test to ensure the app initializes correctly
  });
}
