# Life Blueprint & Routine Template Maker Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build a complete **Life Blueprint & Routine Template Maker Studio** ("Recipe to a Good Life") in Focus Clock, featuring preloaded Dev Blueprints (*5 Pillars of Muslim Time Management* and *The Balanced High-Performer Universal Routine*), 1-tap clock application, and a visual Template Maker Studio.

**Architecture:** Model `RoutineBlueprint` and `BlueprintBlock` with JSON serialization, a dedicated `BlueprintRepository` with built-in official seeds, a `BlueprintApplierService` that translates blueprints into active/recurring `Activity` models, and a modern UI with mini analog clock previews in `PresetsTab` and a full-featured `BlueprintEditorSheet`.

**Tech Stack:** Flutter / Dart, Riverpod, Isar / In-memory Web fallback, CustomPainter (Mini Analog Clock Preview).

## Global Constraints
- Target Flutter SDK: ^3.11.4
- Responsive on Desktop (Linux, Windows, macOS), Mobile (Android, iOS), and Web SPA
- Non-breaking compatibility with existing `Preset` and `Activity` schemas
- Zero white screens or Isar startup crashes on Web and Native

---

### Task 1: `RoutineBlueprint` & `BlueprintBlock` Data Models & Official Dev Seeds

**Files:**
- Create: `lib/models/routine_blueprint.dart`
- Create: `lib/data/repositories/blueprint_repository.dart`
- Test: `test/blueprint_model_test.dart`

**Interfaces:**
- Produces: `class BlueprintBlock`, `class RoutineBlueprint`, `class BlueprintRepository` with `getAll()`, `getOfficial()`, `getCustom()`, `save(RoutineBlueprint)`, `delete(int)`

- [ ] **Step 1: Write the failing test for Blueprint Models & Serialization**

```dart
// test/blueprint_model_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:focus_clock/models/routine_blueprint.dart';
import 'package:focus_clock/core/time_math.dart';

void main() {
  group('RoutineBlueprint and BlueprintBlock', () {
    test('BlueprintBlock serialization and time translation', () {
      final block = BlueprintBlock(
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
    });

    test('Official 5-Pillars seed contains 6 complete daily blocks', () {
      final blueprint = RoutineBlueprint.muslimFivePillars();
      expect(blueprint.name, contains('5 Pillars'));
      expect(blueprint.blocks.length, 6);
      expect(blueprint.blocks.first.title, contains('Subuh'));
    });

    test('Official Balanced High-Performer seed contains 7 complete daily blocks', () {
      final blueprint = RoutineBlueprint.balancedHighPerformer();
      expect(blueprint.name, contains('Balanced High-Performer'));
      expect(blueprint.blocks.length, 7);
    });
  });
}
```

- [ ] **Step 2: Run test to verify failure**

Run: `flutter test test/blueprint_model_test.dart`
Expected: FAIL with compilation error (classes not found).

- [ ] **Step 3: Implement `RoutineBlueprint`, `BlueprintBlock`, and `BlueprintRepository`**

```dart
// lib/models/routine_blueprint.dart
import 'dart:convert';
import '../core/time_math.dart';

class BlueprintBlock {
  final String title;
  final int startMinute;
  final int endMinute;
  final AmPmHalf ampmHalf;
  final String iconKey;
  final int colorValue;
  final String philosophy;
  final String category;

  const BlueprintBlock({
    required this.title,
    required this.startMinute,
    required this.endMinute,
    required this.ampmHalf,
    required this.iconKey,
    required this.colorValue,
    required this.philosophy,
    required this.category,
  });

  Map<String, dynamic> toJson() => {
    'title': title,
    'startMinute': startMinute,
    'endMinute': endMinute,
    'ampmHalf': ampmHalf.name,
    'iconKey': iconKey,
    'colorValue': colorValue,
    'philosophy': philosophy,
    'category': category,
  };

  factory BlueprintBlock.fromJson(Map<String, dynamic> json) => BlueprintBlock(
    title: json['title'] as String? ?? 'Activity',
    startMinute: json['startMinute'] as int? ?? 0,
    endMinute: json['endMinute'] as int? ?? 60,
    ampmHalf: json['ampmHalf'] == 'pm' ? AmPmHalf.pm : AmPmHalf.am,
    iconKey: json['iconKey'] as String? ?? '⚡',
    colorValue: json['colorValue'] as int? ?? 0xFF3B82F6,
    philosophy: json['philosophy'] as String? ?? '',
    category: json['category'] as String? ?? 'General',
  );
}

class RoutineBlueprint {
  int id;
  String name;
  String tagline;
  String description;
  String author;
  String category;
  String iconKey;
  List<BlueprintBlock> blocks;
  DateTime createdAt;
  DateTime updatedAt;

  RoutineBlueprint({
    required this.id,
    required this.name,
    required this.tagline,
    required this.description,
    required this.author,
    required this.category,
    required this.iconKey,
    required this.blocks,
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  static RoutineBlueprint muslimFivePillars() => RoutineBlueprint(
    id: 101,
    name: '5 Pillars of Muslim Time Management',
    tagline: 'Harmonize barakah, deep focus, family & spirituality around the 5 daily prayers.',
    description: 'A life rhythm anchored to the 5 prayer stations. Morning barakah is devoted to deep work, midday to joyful reflection & reset, afternoon to health & family, dusk to dinner & connection, and night to gratitude & restorative sleep.',
    author: 'Official Dev',
    category: 'Spiritual & Focus',
    iconKey: '🕌',
    blocks: [
      BlueprintBlock(
        title: 'Subuh & Barakah Deep Work',
        startMinute: 300, // 05:00
        endMinute: 510,   // 08:30
        ampmHalf: AmPmHalf.am,
        iconKey: '🌅',
        colorValue: 0xFF3B82F6, // Blue
        philosophy: 'Peak morning cognitive output and creative focus before the noise of the day starts.',
        category: 'Deepwork',
      ),
      BlueprintBlock(
        title: 'Dhuhur, Evaluasi & Joyful Work',
        startMinute: 0,   // 12:00 PM
        endMinute: 120,   // 14:00 PM
        ampmHalf: AmPmHalf.pm,
        iconKey: '☀️',
        colorValue: 0xFFEAB308, // Amber
        philosophy: 'Midday prayer, mindful lunch, daily progress check-in, and collaborative joyful work.',
        category: 'Work & Reset',
      ),
      BlueprintBlock(
        title: 'Ashar, Physical Vitality & Socialize',
        startMinute: 210, // 15:30 PM
        endMinute: 330,   // 17:30 PM
        ampmHalf: AmPmHalf.pm,
        iconKey: '🏃',
        colorValue: 0xFF10B981, // Emerald
        philosophy: 'Ashar prayer, sports, physical workout, hobbies, and spending active time with family.',
        category: 'Exercise & Family',
      ),
      BlueprintBlock(
        title: 'Maghrib, Spiritual Presence & Dinner',
        startMinute: 360, // 18:00 PM
        endMinute: 450,   // 19:30 PM
        ampmHalf: AmPmHalf.pm,
        iconKey: '🌙',
        colorValue: 0xFFF97316, // Orange
        philosophy: 'Maghrib prayer, warm family meal, digital detox, and relaxing transition to evening.',
        category: 'Family & Rest',
      ),
      BlueprintBlock(
        title: 'Isya, Journaling & Evening Wind-Down',
        startMinute: 450, // 19:30 PM
        endMinute: 570,   // 21:30 PM
        ampmHalf: AmPmHalf.pm,
        iconKey: '📖',
        colorValue: 0xFF8B5CF6, // Purple
        philosophy: 'Isya prayer, daily gratitude reflection, planning tomorrow, and preparing mind for sleep.',
        category: 'Wind down',
      ),
      BlueprintBlock(
        title: 'Restorative Deep Sleep',
        startMinute: 570, // 21:30 PM (to 04:30 AM)
        endMinute: 720,   // 24:00
        ampmHalf: AmPmHalf.pm,
        iconKey: '😴',
        colorValue: 0xFF64748B, // Slate
        philosophy: '7 hours of undisturbed deep sleep to recharge body and soul for dawn prayer.',
        category: 'Sleep',
      ),
    ],
  );

  static RoutineBlueprint balancedHighPerformer() => RoutineBlueprint(
    id: 102,
    name: 'The Balanced High-Performer',
    tagline: 'Circadian-aligned 24-hour cadence for peak cognitive output, vitality, and peace.',
    description: 'Designed for professionals, engineers, and creators who need uninterrupted morning focus, structured afternoon collaboration, and deliberate evening recovery.',
    author: 'Official Dev',
    category: 'High Performance',
    iconKey: '⚡',
    blocks: [
      BlueprintBlock(
        title: 'Morning Ritual & Mindful Movement',
        startMinute: 360, // 06:00 AM
        endMinute: 450,   // 07:30 AM
        ampmHalf: AmPmHalf.am,
        iconKey: '🌅',
        colorValue: 0xFF06B6D4, // Cyan
        philosophy: 'Hydration, sunlight exposure, gentle stretching, and mental preparation.',
        category: 'Intentional Rest',
      ),
      BlueprintBlock(
        title: 'Peak Cognitive Deep Work',
        startMinute: 480, // 08:00 AM
        endMinute: 690,   // 11:30 AM
        ampmHalf: AmPmHalf.am,
        iconKey: '🎯',
        colorValue: 0xFF3B82F6, // Blue
        philosophy: 'Zero-distraction high-leverage problem solving, coding, or strategy.',
        category: 'Deepwork',
      ),
      BlueprintBlock(
        title: 'Mindful Fuel & Strategic Reset',
        startMinute: 0,   // 12:00 PM
        endMinute: 90,    // 13:30 PM
        ampmHalf: AmPmHalf.pm,
        iconKey: '🥗',
        colorValue: 0xFFF59E0B, // Amber
        philosophy: 'Nutritious lunch, walking, stepping away from screens.',
        category: 'Intentional Rest',
      ),
      BlueprintBlock(
        title: 'Collaborative Execution & Async Work',
        startMinute: 120, // 14:00 PM
        endMinute: 270,   // 16:30 PM
        ampmHalf: AmPmHalf.pm,
        iconKey: '🤝',
        colorValue: 0xFF8B5CF6, // Purple
        philosophy: 'Meetings, communication, email processing, and administrative execution.',
        category: 'Social activity',
      ),
      BlueprintBlock(
        title: 'Physical Fitness & Recreation',
        startMinute: 300, // 17:00 PM
        endMinute: 420,   // 19:00 PM
        ampmHalf: AmPmHalf.pm,
        iconKey: '🏃',
        colorValue: 0xFF10B981, // Emerald
        philosophy: 'Strength training, cardio, outdoor exercise, or creative hobby.',
        category: 'Exercise',
      ),
      BlueprintBlock(
        title: 'Unplug, Family & Mindful Wind-Down',
        startMinute: 480, // 20:00 PM
        endMinute: 600,   // 22:00 PM
        ampmHalf: AmPmHalf.pm,
        iconKey: '🕯️',
        colorValue: 0xFFEC4899, // Pink
        philosophy: 'Dinner with loved ones, reading fiction or non-screen book, dimming lights.',
        category: 'Wind down',
      ),
      BlueprintBlock(
        title: '8 Hours Restorative Rest',
        startMinute: 600, // 22:00 PM
        endMinute: 720,   // 24:00
        ampmHalf: AmPmHalf.pm,
        iconKey: '🛌',
        colorValue: 0xFF64748B, // Slate
        philosophy: 'High quality deep sleep in a cool, dark room.',
        category: 'Sleep',
      ),
    ],
  );
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `flutter test test/blueprint_model_test.dart`
Expected: PASS

- [ ] **Step 5: Commit Task 1**

```bash
git add lib/models/routine_blueprint.dart lib/data/repositories/blueprint_repository.dart test/blueprint_model_test.dart
git commit -m "feat(blueprint): add RoutineBlueprint model, official seeds, and unit tests"
```

---

### Task 2: `BlueprintApplierService` (Clock Schedule Engine)

**Files:**
- Create: `lib/services/blueprint_applier_service.dart`
- Modify: `lib/providers/providers.dart`
- Test: `test/blueprint_applier_test.dart`

**Interfaces:**
- Consumes: `ActivityRepository`, `RoutineBlueprint`
- Produces: `BlueprintApplierService.applyBlueprint({required RoutineBlueprint blueprint, required DateTime targetDate, required bool isDailyRecurring})`

- [ ] **Step 1: Write the failing test for BlueprintApplierService**

```dart
// test/blueprint_applier_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:focus_clock/data/repositories/activity_repository.dart';
import 'package:focus_clock/models/routine_blueprint.dart';
import 'package:focus_clock/services/blueprint_applier_service.dart';
import 'package:focus_clock/services/notification_service.dart';

void main() {
  test('BlueprintApplierService converts blueprint blocks into Activity entries', () async {
    final repo = ActivityRepository(null, NotificationService());
    final service = BlueprintApplierService(repo);

    final blueprint = RoutineBlueprint.muslimFivePillars();
    final date = DateTime(2026, 8, 21);

    final count = await service.applyBlueprint(
      blueprint: blueprint,
      targetDate: date,
      isDailyRecurring: true,
    );

    expect(count, equals(blueprint.blocks.length));
  });
}
```

- [ ] **Step 2: Run test to verify failure**

Run: `flutter test test/blueprint_applier_test.dart`
Expected: FAIL (service not found).

- [ ] **Step 3: Implement `BlueprintApplierService`**

```dart
// lib/services/blueprint_applier_service.dart
import '../core/time_math.dart';
import '../data/repositories/activity_repository.dart';
import '../models/activity.dart';
import '../models/routine_blueprint.dart';

class BlueprintApplierService {
  final ActivityRepository activityRepo;

  BlueprintApplierService(this.activityRepo);

  Future<int> applyBlueprint({
    required RoutineBlueprint blueprint,
    required DateTime targetDate,
    required bool isDailyRecurring,
  }) async {
    final d = dateOnly(targetDate);
    final now = DateTime.now();
    int count = 0;

    for (final block in blueprint.blocks) {
      final activity = Activity()
        ..title = block.title
        ..startMinute = block.startMinute
        ..endMinute = block.endMinute
        ..ampmHalf = block.ampmHalf
        ..date = d
        ..description = block.philosophy
        ..colorValue = block.colorValue
        ..iconKey = block.iconKey
        ..recurrence = isDailyRecurring ? 'daily' : 'none'
        ..createdAt = now
        ..updatedAt = now;

      await activityRepo.upsert(activity);
      count++;
    }

    return count;
  }
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `flutter test test/blueprint_applier_test.dart`
Expected: PASS

- [ ] **Step 5: Commit Task 2**

```bash
git add lib/services/blueprint_applier_service.dart lib/providers/providers.dart test/blueprint_applier_test.dart
git commit -m "feat(blueprint): implement BlueprintApplierService with recurrence support"
```

---

### Task 3: Mini Clock Preview & Blueprint Card UI

**Files:**
- Create: `lib/features/presets/widgets/blueprint_clock_preview.dart`
- Create: `lib/features/presets/widgets/blueprint_card.dart`
- Create: `lib/features/presets/dialogs/blueprint_detail_dialog.dart`
- Create: `lib/features/presets/dialogs/apply_blueprint_dialog.dart`

**Interfaces:**
- Produces: `BlueprintClockPreview(blocks: List<BlueprintBlock>)`, `BlueprintCard(blueprint, onApply, onEdit, onRead)`, `BlueprintDetailDialog`, `ApplyBlueprintDialog`

- [ ] **Step 1: Implement `BlueprintClockPreview` (CustomPainter Visual Dial)**
- [ ] **Step 2: Implement `BlueprintCard` (Rich Book Card with category pill, author badge, dial preview, action buttons)**
- [ ] **Step 3: Implement `BlueprintDetailDialog` (Philosophy, chapter details, full 24h arc breakdown)**
- [ ] **Step 4: Implement `ApplyBlueprintDialog` (Choose Daily Recurring vs Single Day with date picker)**
- [ ] **Step 5: Verify build & commit**

```bash
git add lib/features/presets/widgets/ lib/features/presets/dialogs/
git commit -m "feat(blueprint-ui): add BlueprintClockPreview, BlueprintCard, and dialogs"
```

---

### Task 4: Template Maker Studio (`BlueprintEditorSheet`)

**Files:**
- Create: `lib/features/presets/blueprint_editor_sheet.dart`

**Interfaces:**
- Produces: `BlueprintEditorSheet({RoutineBlueprint? initialBlueprint})` for creating & customizing daily routines with dynamic block editing and live clock updates.

- [ ] **Step 1: Implement `BlueprintEditorSheet` with live preview & time pickers**
- [ ] **Step 2: Connect save callback to `BlueprintRepository`**
- [ ] **Step 3: Commit Task 4**

```bash
git add lib/features/presets/blueprint_editor_sheet.dart
git commit -m "feat(blueprint-editor): add visual Template Maker Studio with live clock preview"
```

---

### Task 5: Upgrade `PresetsTab` with Segmented Control (`Routine Blueprints` vs `Category Tags`)

**Files:**
- Modify: `lib/features/presets/presets_tab.dart`

- [ ] **Step 1: Add modern Segmented Switcher at top of `PresetsTab`**
- [ ] **Step 2: Display Official Dev Blueprints & Custom User Blueprints section with "+ Buat Blueprint" FAB/button**
- [ ] **Step 3: Retain existing category tags in Tab 2**
- [ ] **Step 4: Commit Task 5**

```bash
git add lib/features/presets/presets_tab.dart
git commit -m "feat(presets): integrate Routine Blueprints catalog into PresetsTab"
```

---

### Task 6: Comprehensive Verification & End-to-End Testing

**Files:**
- Test: Run `flutter analyze` & `flutter test`

- [ ] **Step 1: Run `flutter analyze`** (Ensure 0 errors, 0 warnings)
- [ ] **Step 2: Run `flutter test`** (Ensure 100% tests pass)
- [ ] **Step 3: Verify Web SPA build (`flutter build web --release`)**
- [ ] **Step 4: Final commit & walkthrough documentation**
