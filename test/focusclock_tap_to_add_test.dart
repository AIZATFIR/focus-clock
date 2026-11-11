import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:focus_clock/data/storage/fallback_storage.dart';
import 'package:focus_clock/features/focusclock/analog_clock_face.dart';
import 'package:focus_clock/features/focusclock/focusclock_tab.dart';
import 'package:focus_clock/providers/providers.dart';
import 'package:focus_clock/services/notification_service.dart';

class _MemoryStorage implements FallbackStorage {
  final values = <String, String>{};

  @override
  Future<String?> read(String key) async => values[key];

  @override
  Future<void> write(String key, String value) async => values[key] = value;
}

void main() {
  testWidgets('tapping empty time opens the quick activity composer', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1280, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final storage = _MemoryStorage();
    final container = ProviderContainer(
      overrides: [
        fallbackStorageProvider.overrideWithValue(storage),
        notificationServiceProvider.overrideWithValue(NotificationService()),
        currentTimeProvider.overrideWith(
          (ref) => Stream.value(DateTime(2026, 11, 12, 9)),
        ),
      ],
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(home: Scaffold(body: FocusClockTab())),
      ),
    );
    await tester.pump(const Duration(milliseconds: 600));
    await tester.pumpAndSettle();

    final dial = tester.getRect(find.byType(AnalogClockFace));
    final tapPoint = Offset(dial.center.dx, dial.top + dial.height * 0.15);
    await tester.tapAt(tapPoint);
    await tester.pump(const Duration(milliseconds: 600));
    await tester.pumpAndSettle();

    expect(find.text('What goes here?'), findsOneWidget);

    await tester.binding.handlePopRoute();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('What goes here?'), findsNothing);

    final date = container.read(currentDateProvider);
    expect(await container.read(activityRepoProvider).getByDate(date), isEmpty);

    await tester.tapAt(tapPoint);
    await tester.pump(const Duration(milliseconds: 600));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'Study LKS');
    await tester.pump();
    expect(
      tester.widget<FilledButton>(find.byType(FilledButton)).onPressed,
      isNotNull,
    );
    await tester.tap(find.byType(FilledButton));
    await tester.pump(const Duration(milliseconds: 1000));
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.text('What goes here?'), findsNothing);
    final activities = await container
        .read(activityRepoProvider)
        .getByDate(date);
    expect(activities, hasLength(1));
    expect(activities.single.title, 'Study LKS');
  });
}
