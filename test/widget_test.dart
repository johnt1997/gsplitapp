// Smoke-Test für das interaktive Guinness-Glas (kein Firebase nötig).
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:gsplit/widgets/guinness_glass_rating.dart';

void main() {
  testWidgets('GuinnessGlassRating rendert Score und reagiert auf Tap', (
    WidgetTester tester,
  ) async {
    double? lastRating;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: GuinnessGlassRating(
              size: const Size(250, 350),
              rating: 5.0,
              onRatingChanged: (value) => lastRating = value,
            ),
          ),
        ),
      ),
    );

    // Der aktuelle Score wird angezeigt
    expect(find.text('5.0'), findsOneWidget);
    expect(find.text('STOUT SCORE'), findsOneWidget);

    // Tap weit oben im Glas => hohes Rating
    final glass = find.byType(GuinnessGlassRating);
    final topLeft = tester.getTopLeft(glass);
    await tester.tapAt(topLeft + const Offset(125, 20));
    await tester.pump();

    expect(lastRating, isNotNull);
    expect(lastRating, greaterThan(8.0));
  });
}
