import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:focus_clock/features/focusclock/widgets/quick_activity_sheet.dart';

void main() {
  testWidgets('empty name cannot place a block', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: TextButton(
              onPressed: () => showQuickActivitySheet(
                context,
                startLabel: '9:30 AM',
                durationOptions: const [15, 30, 45, 60],
                initialDuration: 30,
              ),
              child: const Text('Open'),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();

    final placeButton = tester.widget<FilledButton>(find.byType(FilledButton));
    expect(placeButton.onPressed, isNull);
    expect(find.text('Starts at 9:30 AM'), findsOneWidget);
  });

  testWidgets('places the named activity with the chosen duration', (
    tester,
  ) async {
    QuickActivityDraft? result;
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: TextButton(
              onPressed: () async {
                result = await showQuickActivitySheet(
                  context,
                  startLabel: '9:30 AM',
                  durationOptions: const [15, 30, 45, 60],
                  initialDuration: 30,
                );
              },
              child: const Text('Open'),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), ' Study LKS ');
    await tester.pump();
    expect(
      tester.widget<FilledButton>(find.byType(FilledButton)).onPressed,
      isNotNull,
    );
    await tester.tap(find.widgetWithText(ChoiceChip, '45m'));
    await tester.tap(find.text('Place on clock'));
    await tester.pumpAndSettle();

    expect(result?.title, 'Study LKS');
    expect(result?.durationMinutes, 45);
  });

  testWidgets('can mark a quick activity as supporting the focus goal', (
    tester,
  ) async {
    QuickActivityDraft? result;
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: TextButton(
              onPressed: () async {
                result = await showQuickActivitySheet(
                  context,
                  startLabel: '9:30 AM',
                  durationOptions: const [30, 60],
                  initialDuration: 30,
                  focusGoal: 'Menang LKS nasional',
                );
              },
              child: const Text('Open'),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'Study LKS');
    await tester.tap(find.byType(CheckboxListTile));
    await tester.pump();
    expect(
      tester.widget<CheckboxListTile>(find.byType(CheckboxListTile)).value,
      isTrue,
    );
    await tester.tap(find.text('Place on clock'));
    await tester.pumpAndSettle();

    expect(result?.focusGoalLink, 'Menang LKS nasional');
  });
}
