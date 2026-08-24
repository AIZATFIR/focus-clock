import 'package:flutter_test/flutter_test.dart';
import 'package:focus_clock/core/time_math.dart';
import 'package:focus_clock/services/gcal_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('5-Minute Sliding & Snapping Math', () {
    test('snap5 snaps arbitrarily chosen minutes to exact 5-minute multiples', () {
      expect(snap5(0), 0);
      expect(snap5(1), 0);
      expect(snap5(2), 0);
      expect(snap5(3), 5);
      expect(snap5(4), 5);
      expect(snap5(7), 5);
      expect(snap5(8), 10);
      expect(snap5(33), 35);
      expect(snap5(47), 45);
      expect(snap5(719), 720);
      expect(snap5(1438), 1440);
    });

    test('snapDelta snaps movement delta with 5-minute granularity', () {
      expect(snapDelta(0), 0);
      expect(snapDelta(3), 5);
      expect(snapDelta(7), 5);
      expect(snapDelta(12), 10);
      expect(snapDelta(-8), -10);
      expect(snapDelta(58), 60); // prefers nearest hour
    });
  });

  group('AM/PM & 24H Time Representation', () {
    test('AM / PM half transitions correctly', () {
      expect(AmPmHalf.am.label, 'AM');
      expect(AmPmHalf.pm.label, 'PM');

      final morning = DateTime(2026, 8, 24, 7, 30);
      final afternoon = DateTime(2026, 8, 24, 15, 45);

      expect(halfOfNow(morning), AmPmHalf.am);
      expect(halfOfNow(afternoon), AmPmHalf.pm);
    });

    test('formatMinute formats 12h and 24h correctly', () {
      expect(formatMinute(480, AmPmHalf.am), '08:00'); // 8 AM in 24h
      expect(formatMinute(480, AmPmHalf.pm), '20:00'); // 8 PM in 24h
      expect(formatMinute(480, AmPmHalf.pm, is24h: false), '8:00 PM');
    });
  });

  group('Google Calendar Sync Resilience', () {
    test('GCalService singleton operates smoothly on web/desktop fallback', () async {
      final gcal = GCalService();
      expect(gcalSupported, isTrue);

      // Web / Desktop fallback sign in
      final signedIn = await gcal.signIn();
      expect(signedIn, isTrue);
      expect(gcal.isSignedIn, isTrue);

      // Sign out
      await gcal.signOut();
      expect(gcal.isSignedIn, isFalse);
    });
  });
}
