import 'package:flutter_test/flutter_test.dart';
import 'package:focus_clock/services/focus_session_contract.dart';

void main() {
  group('FocusSessionContract Tests (PRD 3 §2, §35, §84)', () {
    test('FocusSessionRequest JSON roundtrip', () {
      final req = FocusSessionRequest(
        habitId: 101,
        title: 'Deep Coding',
        targetMinutes: 45,
        requestedAt: DateTime(2026, 9, 11, 10, 30),
      );

      final json = req.toJson();
      expect(json['version'], 'v1');
      expect(json['habitId'], 101);
      expect(json['title'], 'Deep Coding');
      expect(json['targetMinutes'], 45);

      final restored = FocusSessionRequest.fromJson(json);
      expect(restored.habitId, req.habitId);
      expect(restored.title, req.title);
      expect(restored.targetMinutes, req.targetMinutes);
      expect(restored.requestedAt, req.requestedAt);
    });

    test('FocusSessionResult JSON roundtrip', () {
      final res = FocusSessionResult(
        sessionId: 'session-xyz-123',
        habitId: 101,
        startedAt: DateTime(2026, 9, 11, 10, 30),
        endedAt: DateTime(2026, 9, 11, 11, 15),
        actualDurationMinutes: 45,
        status: 'completed',
      );

      final json = res.toJson();
      expect(json['version'], 'v1');
      expect(json['sessionId'], 'session-xyz-123');
      expect(json['status'], 'completed');
      expect(res.isCompleted, true);

      final restored = FocusSessionResult.fromJson(json);
      expect(restored.sessionId, res.sessionId);
      expect(restored.habitId, res.habitId);
      expect(restored.actualDurationMinutes, 45);
      expect(restored.isCompleted, true);
    });

    test('buildFocusClockUri and parseFocusClockUri roundtrip', () {
      final req = FocusSessionRequest(
        habitId: 55,
        title: 'French Conversation',
        targetMinutes: 20,
        requestedAt: DateTime(2026, 9, 11, 14, 0),
      );

      final uri = FocusSessionContract.buildFocusClockUri(req);
      expect(uri.scheme, 'focusclock');
      expect(uri.host, 'timer');
      expect(uri.queryParameters['version'], 'v1');
      expect(uri.queryParameters['habitId'], '55');
      expect(uri.queryParameters['title'], 'French Conversation');
      expect(uri.queryParameters['minutes'], '20');
      expect(uri.queryParameters['callback'], 'sadar://completed');

      final parsed = FocusSessionContract.parseFocusClockUri(uri);
      expect(parsed, isNotNull);
      expect(parsed!.habitId, 55);
      expect(parsed.title, 'French Conversation');
      expect(parsed.targetMinutes, 20);
    });

    test('rejects unsupported versions and malformed sessions', () {
      expect(
        FocusSessionContract.parseFocusClockUri(
          Uri.parse(
            'focusclock://timer?version=v2&habitId=55&title=Study&minutes=20',
          ),
        ),
        isNull,
      );
      expect(
        FocusSessionContract.parseFocusClockUri(
          Uri.parse(
            'focusclock://timer?version=v1&habitId=-1&title=Study&minutes=20',
          ),
        ),
        isNull,
      );
      expect(
        FocusSessionContract.parseFocusClockUri(
          Uri.parse(
            'focusclock://timer?version=v1&habitId=55&title=Study&duration=45&timestamp=1791734400000&callback=sadar%3A%2F%2Fcompleted',
          ),
        )?.targetMinutes,
        45,
      );
    });

    test('parses the Sadar web auto-start link', () {
      final request = FocusSessionContract.parseFocusClockUri(
        Uri.parse(
          'https://focus-clock-web.vercel.app/?task=Belajar%20LKS'
          '&duration=45&autoStart=true&habitKey=habit-8'
          '&sessionId=fc-abc123&timestamp=1794441600000'
          '&remaining=92&paused=true'
          '&callback=https%3A%2F%2Fsadar-web.vercel.app%2F',
        ),
      );

      expect(request, isNotNull);
      expect(request!.title, 'Belajar LKS');
      expect(request.targetMinutes, 45);
      expect(request.habitId, 0);
      expect(request.callbackUrl, 'https://sadar-web.vercel.app/');
      expect(request.sourceHabitKey, 'habit-8');
      expect(request.sourceSessionId, 'fc-abc123');
      expect(request.sourceRemainingSeconds, 92);
      expect(request.sourcePaused, isTrue);
      expect(
        request.sourceStartedAt,
        DateTime.fromMillisecondsSinceEpoch(1794441600000),
      );
    });

    test(
      'rejects web callbacks outside Sadar and local development origins',
      () {
        final request = FocusSessionContract.parseFocusClockUri(
          Uri.parse(
            'https://focus-clock-web.vercel.app/?task=Study&duration=25'
            '&autoStart=true&habitKey=habit-8'
            '&callback=https%3A%2F%2Fevil.example%2F',
          ),
        );

        expect(request, isNull);
      },
    );

    test('accepts Flutter Sadar numeric habit callbacks from the web', () {
      final request = FocusSessionContract.parseFocusClockUri(
        Uri.parse(
          'https://focus-clock-web.vercel.app/?task=Study&duration=25'
          '&autoStart=true&habitId=55&sessionId=fc-native-web-1'
          '&timestamp=1794441600000'
          '&callback=https%3A%2F%2Fsadar-web.vercel.app%2F',
        ),
      );

      expect(request, isNotNull);
      expect(request!.habitId, 55);
      expect(request.sourceHabitKey, isNull);
      expect(request.sourceSessionId, 'fc-native-web-1');
    });

    test('builds a versioned web completion return URL', () {
      final result = FocusSessionResult(
        sessionId: 'session-web-1',
        habitId: 0,
        startedAt: DateTime(2026, 11, 12, 9),
        endedAt: DateTime(2026, 11, 12, 9, 25),
        actualDurationMinutes: 25,
        status: 'completed',
      );

      final uri = FocusSessionContract.buildSadarWebCompletedUri(
        callbackUrl: 'https://sadar-web.vercel.app/',
        habitKey: 'habit-8',
        result: result,
      );

      expect(uri.scheme, 'https');
      expect(uri.host, 'sadar-web.vercel.app');
      expect(uri.queryParameters['fc_version'], '1');
      expect(uri.queryParameters['fc_session'], 'session-web-1');
      expect(uri.queryParameters['fc_habit'], 'habit-8');
      expect(uri.queryParameters['fc_duration'], '25');
      expect(uri.queryParameters['fc_status'], 'completed');
    });

    test('ignores web links that are not valid auto-start sessions', () {
      expect(
        FocusSessionContract.parseFocusClockUri(
          Uri.parse(
            'https://focus-clock-web.vercel.app/?task=Study&duration=45',
          ),
        ),
        isNull,
      );
      expect(
        FocusSessionContract.parseFocusClockUri(
          Uri.parse(
            'https://focus-clock-web.vercel.app/?task=Study&duration=0&autoStart=true',
          ),
        ),
        isNull,
      );
    });

    test('buildSadarCompletedUri and parseSadarCompletedUri roundtrip', () {
      final res = FocusSessionResult(
        sessionId: 'sess-888',
        habitId: 55,
        startedAt: DateTime(2026, 9, 11, 14, 0),
        endedAt: DateTime(2026, 9, 11, 14, 20),
        actualDurationMinutes: 20,
        status: 'completed',
      );

      final uri = FocusSessionContract.buildSadarCompletedUri(res);
      expect(uri.scheme, 'sadar');
      expect(uri.host, 'completed');
      expect(uri.queryParameters['sessionId'], 'sess-888');
      expect(uri.queryParameters['habitId'], '55');
      expect(uri.queryParameters['duration'], '20');
      expect(uri.queryParameters['status'], 'completed');

      final parsed = FocusSessionContract.parseSadarCompletedUri(uri);
      expect(parsed, isNotNull);
      expect(parsed!.sessionId, 'sess-888');
      expect(parsed.habitId, 55);
      expect(parsed.actualDurationMinutes, 20);
      expect(parsed.isCompleted, true);
    });
  });
}
