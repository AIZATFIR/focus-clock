import 'package:flutter_test/flutter_test.dart';

import 'package:focus_clock/core/time_math.dart';

void main() {
  group('splitSpan', () {
    test('sleep 22:00 → 05:00 splits into PM + AM segments', () {
      final start = DateTime(2026, 6, 11, 22, 0);
      final end = DateTime(2026, 6, 12, 5, 0);
      final segs = splitSpan(start, end);

      expect(segs.length, 2);
      expect(segs[0].half, AmPmHalf.pm);
      expect(segs[0].start, 600); // 22:00
      expect(segs[0].end, 720); // midnight
      expect(segs[1].half, AmPmHalf.am);
      expect(segs[1].start, 0);
      expect(segs[1].end, 300); // 05:00
      expect(segs[1].date, DateTime(2026, 6, 12));
    });

    test('within one half stays single segment', () {
      final segs = splitSpan(
        DateTime(2026, 6, 11, 8, 0),
        DateTime(2026, 6, 11, 9, 30),
      );
      expect(segs.length, 1);
      expect(segs[0].start, 480);
      expect(segs[0].end, 570);
    });

    test('crossing noon splits AM/PM', () {
      final segs = splitSpan(
        DateTime(2026, 6, 11, 11, 0),
        DateTime(2026, 6, 11, 13, 0),
      );
      expect(segs.length, 2);
      expect(segs[0].half, AmPmHalf.am);
      expect(segs[1].half, AmPmHalf.pm);
    });
  });
}
