import 'package:flutter_test/flutter_test.dart';
import 'package:focus_clock/models/task.dart';

void main() {
  group('Task Model & Eisenhower Logic Tests', () {
    test('Task defaults to non-urgent and non-important (Quadrant 3)', () {
      final t = Task()..title = 'Sample Task';

      expect(t.title, 'Sample Task');
      expect(t.isCompleted, false);
      expect(t.isUrgent, false);
      expect(t.importance, 0);
      expect(t.eisenhowerQuadrant, 3); // Eliminate/Neither
    });

    test('Urgent & Important task maps to Quadrant 0 (Do)', () {
      final t = Task()
        ..title = 'Urgent Bugfix'
        ..deadline = DateTime.now().add(const Duration(days: 1))
        ..importance = 1;

      expect(t.isUrgent, true);
      expect(t.eisenhowerQuadrant, 0);
    });

    test('Important but Not Urgent task maps to Quadrant 1 (Schedule)', () {
      final t = Task()
        ..title = 'Quarterly Strategy'
        ..deadline = DateTime.now().add(const Duration(days: 10))
        ..importance = 1;

      expect(t.isUrgent, false);
      expect(t.eisenhowerQuadrant, 1);
    });

    test('Urgent but Not Important task maps to Quadrant 2 (Delegate)', () {
      final t = Task()
        ..title = 'Phone Call'
        ..deadline = DateTime.now().add(const Duration(hours: 5))
        ..importance = 0;

      expect(t.isUrgent, true);
      expect(t.eisenhowerQuadrant, 2);
    });
  });
}
