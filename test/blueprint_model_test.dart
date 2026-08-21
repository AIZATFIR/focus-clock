import 'package:flutter_test/flutter_test.dart';
import 'package:focus_clock/models/routine_blueprint.dart';
import 'package:focus_clock/core/time_math.dart';

void main() {
  group('RoutineBlueprint and BlueprintBlock', () {
    test('BlueprintBlock serialization and time translation', () {
      const block = BlueprintBlock(
        title: 'Subuh & Barakah Deep Work',
        startMinute: 300, // 05:00
        endMinute: 510,   // 08:30
        ampmHalf: AmPmHalf.am,
        iconKey: '🌅',
        colorValue: 0xFF3B82F6,
        philosophy: 'Peak morning cognitive output before daily distractions.',
        category: 'Deepwork',
      );

      final json = block.toJson();
      final decoded = BlueprintBlock.fromJson(json);

      expect(decoded.title, 'Subuh & Barakah Deep Work');
      expect(decoded.startMinute, 300);
      expect(decoded.endMinute, 510);
      expect(decoded.ampmHalf, AmPmHalf.am);
      expect(decoded.iconKey, '🌅');
      expect(decoded.colorValue, 0xFF3B82F6);
    });

    test('Official 5-Pillars seed contains 6 complete daily blocks', () {
      final blueprint = RoutineBlueprint.muslimFivePillars();
      expect(blueprint.name, contains('5 Pillars'));
      expect(blueprint.blocks.length, 6);
      expect(blueprint.blocks.first.title, contains('Subuh'));
      expect(blueprint.blocks.any((b) => b.title.contains('Dhuhur')), isTrue);
      expect(blueprint.blocks.any((b) => b.title.contains('Ashar')), isTrue);
      expect(blueprint.blocks.any((b) => b.title.contains('Maghrib')), isTrue);
      expect(blueprint.blocks.any((b) => b.title.contains('Isya')), isTrue);
    });

    test('Official Balanced High-Performer seed contains 7 complete daily blocks', () {
      final blueprint = RoutineBlueprint.balancedHighPerformer();
      expect(blueprint.name, contains('Balanced High-Performer'));
      expect(blueprint.blocks.length, 7);
    });

    test('RoutineBlueprint serialization roundtrip', () {
      final blueprint = RoutineBlueprint.muslimFivePillars();
      final json = blueprint.toJson();
      final restored = RoutineBlueprint.fromJson(json);

      expect(restored.id, blueprint.id);
      expect(restored.name, blueprint.name);
      expect(restored.blocks.length, blueprint.blocks.length);
      expect(restored.blocks[0].title, blueprint.blocks[0].title);
    });
  });
}
