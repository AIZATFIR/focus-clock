import 'package:flutter_test/flutter_test.dart';
import 'package:focus_clock/core/time_math.dart';
import 'package:focus_clock/services/natural_intent_parser.dart';

void main() {
  group('NaturalIntentParser Tests', () {
    test('Parses intention with duration and time in Indonesian', () {
      final ref = DateTime(2026, 8, 24, 10, 0);
      final parsed = NaturalIntentParser.parse('Belajar coding 2 jam jam 8 malam', referenceTime: ref);
      
      expect(parsed.title.toLowerCase(), contains('belajar coding'));
      expect(parsed.durationMinutes, equals(120));
      expect(parsed.ampmHalf, equals(AmPmHalf.pm));
      expect(parsed.iconKey, equals('💻'));
      expect(parsed.startMinute, equals(480)); // 8:00 PM is minute 480 of PM half (8 * 60)
      expect(parsed.endMinute, equals(600));   // 10:00 PM is minute 600 of PM half
    });

    test('Parses English intent with minutes and morning time', () {
      final ref = DateTime(2026, 8, 24, 6, 0);
      final parsed = NaturalIntentParser.parse('Gym workout 45m at 7:00 am', referenceTime: ref);
      
      expect(parsed.title.toLowerCase(), contains('gym workout'));
      expect(parsed.durationMinutes, equals(45));
      expect(parsed.ampmHalf, equals(AmPmHalf.am));
      expect(parsed.iconKey, equals('🏃'));
      expect(parsed.startMinute, equals(420)); // 7:00 AM is 7 * 60
      expect(parsed.endMinute, equals(465));   // 7:45 AM is 465
    });

    test('Defaults to upcoming snap time when no explicit time specified', () {
      final ref = DateTime(2026, 8, 24, 14, 13); // 2:13 PM -> snaps to 2:15 PM
      final parsed = NaturalIntentParser.parse('Membaca buku 30m', referenceTime: ref);
      
      expect(parsed.title.toLowerCase(), contains('membaca buku'));
      expect(parsed.durationMinutes, equals(30));
      expect(parsed.ampmHalf, equals(AmPmHalf.pm));
      expect(parsed.iconKey, equals('📖'));
      expect(parsed.startMinute, equals(135)); // 2:15 PM is 2*60 + 15 = 135
      expect(parsed.endMinute, equals(165));   // 2:45 PM is 165
    });
  });
}
