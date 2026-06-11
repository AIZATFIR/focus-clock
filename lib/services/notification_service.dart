import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

import '../core/time_math.dart';
import '../models/activity.dart';

class NotificationService {
  final _plugin = FlutterLocalNotificationsPlugin();
  bool _ready = false;

  /// Desktop platforms lack zonedSchedule — fall back to in-process timers.
  final Map<int, Timer> _timers = {};

  bool get _useTimerFallback =>
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.linux ||
          defaultTargetPlatform == TargetPlatform.windows ||
          defaultTargetPlatform == TargetPlatform.macOS);

  Future<void> init() async {
    if (_ready) return;
    tzdata.initializeTimeZones();
    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const linux = LinuxInitializationSettings(defaultActionName: 'Open');
    const init = InitializationSettings(android: android, linux: linux);
    await _plugin.initialize(init);
    _ready = true;
  }

  static const _details = NotificationDetails(
    android: AndroidNotificationDetails(
      'focus_clock_activity',
      'Activity reminders',
      channelDescription: '1 minute before activity start',
      importance: Importance.high,
      priority: Priority.high,
    ),
    linux: LinuxNotificationDetails(),
  );

  Future<void> scheduleForActivity(Activity a, {int leadMinutes = 1}) async {
    if (!_ready) return;
    try {
      await cancelForActivity(a.id);
      final start = toDateTime(a.date, a.ampmHalf, a.startMinute);
      final fire = start.subtract(Duration(minutes: leadMinutes));
      if (fire.isBefore(DateTime.now())) return;
      final title = a.title.isEmpty ? 'Activity' : a.title;
      final body = 'Mulai $leadMinutes menit lagi';

      if (_useTimerFallback) {
        _timers[a.id] = Timer(fire.difference(DateTime.now()), () {
          _timers.remove(a.id);
          _plugin.show(a.id, title, body, _details);
        });
        return;
      }

      await _plugin.zonedSchedule(
        a.id,
        title,
        body,
        tz.TZDateTime.from(fire, tz.local),
        _details,
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
      );
    } catch (e) {
      if (kDebugMode) debugPrint('notif schedule failed: $e');
    }
  }

  Future<void> cancelForActivity(int id) async {
    if (!_ready) return;
    _timers.remove(id)?.cancel();
    try {
      await _plugin.cancel(id);
    } catch (_) {}
  }
}
