// This is a basic Flutter widget test for Mikhmon Clone app.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:mikhmon_clone/main.dart';

void main() {
  testWidgets('App initializes without crashing', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const MikhmonCloneApp());

    // Verify that the app builds successfully
    expect(find.byType(MaterialApp), findsOneWidget);
  });

  testWidgets('Welcome screen displays correctly', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const MikhmonCloneApp());

    // Verify welcome screen elements
    expect(find.text('Mikhmon Clone'), findsOneWidget);
  });

  testWidgets('Navigation to login works', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const MikhmonCloneApp());

    // Navigate to login screen
    // (Add navigation logic when welcome screen has login button)
    await tester.pumpAndSettle();

    // Verify login screen elements would appear here
    // after navigation is implemented in welcome screen
  });
}
