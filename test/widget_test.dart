import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:aakriti/main.dart';

void main() {
  testWidgets('App starts and shows the splash screen', (WidgetTester tester) async {
    await tester.pumpWidget(const AakritiApp());

    // The app should build without throwing, and start on a Scaffold
    // (the splash screen).
    expect(find.byType(Scaffold), findsWidgets);
  });
}
