import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:weather_app/app.dart';

void main() {
  testWidgets('Weather App loads with basic UI elements', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const WeatherApp());

    // Verify that the app bar is present
    expect(find.text('Weather App'), findsOneWidget);

    // Verify that navigation bar is present with three destinations
    expect(find.text('Current'), findsOneWidget);
    expect(find.text('Forecast'), findsOneWidget);
    expect(find.text('About'), findsOneWidget);

    // Verify that the location status is displayed
    expect(find.byType(CircularProgressIndicator), findsWidgets);
  });
}
