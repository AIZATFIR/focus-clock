import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

import '../core/time_math.dart';
import '../models/activity.dart';

class NotificationService {
  final _plugin = FlutterLocalNotificationsPlugin();
  bool _ready = false;

  Future<void> init() async {
    if (_ready) return;
    tzdata.initializeTimeZones();
    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const linux = LinuxInitializationSettings(defaultActionName: 'Open');
    const init = InitializationSettings(android: android, linux: linux);
    await _plugin.initialize(init);
    _ready = true;
  }

  Future<void> scheduleForActivity(Activity a, {int leadMinutes = 1}) async {
    if (!_ready) return;
    try {
      await cancelForActivity(a.id);
      final start = toDateTime(a.date, a.ampmHalf, a.startMinute);
      final fire = start.subtract(Duration(minutes: leadMinutes));
      if (fire.isBefore(DateTime.now())) return;
      const details = NotificationDetails(
        android: AndroidNotificationDetails(
          'focus_clock_activity',
          'Activity reminders',
          channelDescription: '1 minute before activity start',
          importance: Importance.high,
          priority: Priority.high,
        ),
      );
      await _plugin.zonedSchedule(
        a.id,
        a.title.isEmpty ? 'Activity' : a.title,
        'Mulai $leadMinutes menit lagi',
        tz.TZDateTime.from(fire, tz.local),
        details,
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
    try {
      await _plugin.cancel(id);
    } catch (_) {}
  }
}
