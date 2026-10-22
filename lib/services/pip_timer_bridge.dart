import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

class PipTimerBridge {
  static const MethodChannel _channel = MethodChannel('com.aizatfir.focus_clock/pip');

  /// Notify Android whether timer is currently counting down so onUserLeaveHint can trigger PiP
  static Future<bool> setTimerActive(bool active) async {
    if (kIsWeb) return false;
    try {
      final res = await _channel.invokeMethod<bool>('setTimerActive', {'active': active});
      return res ?? false;
    } catch (_) {
      return false;
    }
  }

  /// Manually enter Picture-in-Picture mode (e.g. from a floating PiP icon)
  static Future<bool> enterPip() async {
    if (kIsWeb) return false;
    try {
      final res = await _channel.invokeMethod<bool>('enterPip');
      return res ?? false;
    } catch (_) {
      return false;
    }
  }

  /// Update persistent notification with live clock countdown
  static Future<void> updateLiveNotification({
    required String title,
    required String timeStr,
    required String details,
  }) async {
    if (kIsWeb) return;
    try {
      await _channel.invokeMethod('updateLiveNotification', {
        'title': title,
        'timeStr': timeStr,
        'details': details,
      });
    } catch (_) {}
  }

  /// Clear the persistent timer notification
  static Future<void> cancelLiveNotification() async {
    if (kIsWeb) return;
    try {
      await _channel.invokeMethod('cancelLiveNotification');
    } catch (_) {}
  }
}
