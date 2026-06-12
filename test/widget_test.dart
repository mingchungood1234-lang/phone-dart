import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:phone_dart/main.dart';

void main() {
  testWidgets('client can receive, answer, and end a VoIP call', (
    tester,
  ) async {
    await tester.pumpWidget(const PhoneDartApp());

    expect(find.text('Your VoIP line is live'), findsOneWidget);
    expect(find.text('Incoming VoIP call'), findsNothing);

    await tester.tap(find.byIcon(Icons.add_call));
    await tester.pump(const Duration(milliseconds: 350));

    expect(find.text('Incoming VoIP call'), findsOneWidget);
    expect(find.text('Alicia Tan'), findsOneWidget);

    await tester.tap(find.byTooltip('Answer call'));
    await tester.pump();

    expect(find.text('Encrypted VoIP call'), findsOneWidget);
    expect(find.byTooltip('End call'), findsOneWidget);

    await tester.ensureVisible(find.byTooltip('End call'));
    await tester.pump();
    await tester.tap(find.byTooltip('End call'));
    await tester.pumpAndSettle();

    expect(find.text('Call ended'), findsOneWidget);
  });
}
