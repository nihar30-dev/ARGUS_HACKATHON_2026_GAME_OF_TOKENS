import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:meetwise/app/app.dart';

void main() {
  testWidgets('Smoke test - App renders meeting input screen', (WidgetTester tester) async {
    final originalErrorBuilder = ErrorWidget.builder;

    // Build our app and trigger a frame.
    await tester.pumpWidget(const MeetWiseApp());

    // Verify that our app renders the expected title and elements.
    expect(find.text('MeetWise'), findsWidgets);
    expect(find.text('New Meeting Intelligence'), findsWidgets);

    // Restore original builder to satisfy flutter test framework
    ErrorWidget.builder = originalErrorBuilder;
  });
}

