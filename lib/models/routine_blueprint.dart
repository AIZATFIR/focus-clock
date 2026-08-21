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

  BlueprintBlock copyWith({
    String? title,
    int? startMinute,
    int? endMinute,
    AmPmHalf? ampmHalf,
    String? iconKey,
    int? colorValue,
    String? philosophy,
    String? category,
  }) =>
      BlueprintBlock(
        title: title ?? this.title,
        startMinute: startMinute ?? this.startMinute,
        endMinute: endMinute ?? this.endMinute,
        ampmHalf: ampmHalf ?? this.ampmHalf,
        iconKey: iconKey ?? this.iconKey,
        colorValue: colorValue ?? this.colorValue,
        philosophy: philosophy ?? this.philosophy,
        category: category ?? this.category,
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

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'tagline': tagline,
        'description': description,
        'author': author,
        'category': category,
        'iconKey': iconKey,
        'blocks': blocks.map((b) => b.toJson()).toList(),
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
      };

  factory RoutineBlueprint.fromJson(Map<String, dynamic> json) => RoutineBlueprint(
        id: json['id'] as int? ?? 0,
        name: json['name'] as String? ?? 'Custom Blueprint',
        tagline: json['tagline'] as String? ?? '',
        description: json['description'] as String? ?? '',
        author: json['author'] as String? ?? 'Custom',
        category: json['category'] as String? ?? 'General',
        iconKey: json['iconKey'] as String? ?? '📋',
        blocks: (json['blocks'] as List<dynamic>?)
                ?.map((b) => BlueprintBlock.fromJson(b as Map<String, dynamic>))
                .toList() ??
            [],
        createdAt: json['createdAt'] != null
            ? DateTime.tryParse(json['createdAt'] as String) ?? DateTime.now()
            : DateTime.now(),
        updatedAt: json['updatedAt'] != null
            ? DateTime.tryParse(json['updatedAt'] as String) ?? DateTime.now()
            : DateTime.now(),
      );

  RoutineBlueprint copyWith({
    int? id,
    String? name,
    String? tagline,
    String? description,
    String? author,
    String? category,
    String? iconKey,
    List<BlueprintBlock>? blocks,
  }) =>
      RoutineBlueprint(
        id: id ?? this.id,
        name: name ?? this.name,
        tagline: tagline ?? this.tagline,
        description: description ?? this.description,
        author: author ?? this.author,
        category: category ?? this.category,
        iconKey: iconKey ?? this.iconKey,
        blocks: blocks != null ? List.from(blocks) : List.from(this.blocks),
        createdAt: createdAt,
        updatedAt: DateTime.now(),
      );

  static RoutineBlueprint muslimFivePillars() => RoutineBlueprint(
        id: 101,
        name: '5 Pillars of Muslim Time Management',
        tagline: 'Harmonize barakah, deep focus, family & spirituality around the 5 daily prayers.',
        description:
            'A life rhythm anchored to the 5 prayer stations. Morning barakah is devoted to deep work, midday to joyful reflection & reset, afternoon to health & family, dusk to dinner & connection, and night to gratitude & restorative sleep.',
        author: 'Official Dev',
        category: 'Spiritual & Focus',
        iconKey: '🕌',
        blocks: const [
          BlueprintBlock(
            title: 'Subuh & Barakah Deep Work',
            startMinute: 300, // 05:00
            endMinute: 510,   // 08:30
            ampmHalf: AmPmHalf.am,
            iconKey: '🌅',
            colorValue: 0xFF3B82F6, // Blue
            philosophy:
                'Peak morning cognitive output and creative focus before the noise of the day starts.',
            category: 'Deepwork',
          ),
          BlueprintBlock(
            title: 'Dhuhur, Evaluasi & Joyful Work',
            startMinute: 0,   // 12:00 PM
            endMinute: 120,   // 14:00 PM
            ampmHalf: AmPmHalf.pm,
            iconKey: '☀️',
            colorValue: 0xFFEAB308, // Amber
            philosophy:
                'Midday prayer, mindful lunch, daily progress check-in, and collaborative joyful work.',
            category: 'Work & Reset',
          ),
          BlueprintBlock(
            title: 'Ashar, Physical Vitality & Socialize',
            startMinute: 210, // 15:30 PM
            endMinute: 330,   // 17:30 PM
            ampmHalf: AmPmHalf.pm,
            iconKey: '🏃',
            colorValue: 0xFF10B981, // Emerald
            philosophy:
                'Ashar prayer, sports, physical workout, hobbies, and spending active time with family.',
            category: 'Exercise & Family',
          ),
          BlueprintBlock(
            title: 'Maghrib, Spiritual Presence & Dinner',
            startMinute: 360, // 18:00 PM
            endMinute: 450,   // 19:30 PM
            ampmHalf: AmPmHalf.pm,
            iconKey: '🌙',
            colorValue: 0xFFF97316, // Orange
            philosophy:
                'Maghrib prayer, warm family meal, digital detox, and relaxing transition to evening.',
            category: 'Family & Rest',
          ),
          BlueprintBlock(
            title: 'Isya, Journaling & Evening Wind-Down',
            startMinute: 450, // 19:30 PM
            endMinute: 570,   // 21:30 PM
            ampmHalf: AmPmHalf.pm,
            iconKey: '📖',
            colorValue: 0xFF8B5CF6, // Purple
            philosophy:
                'Isya prayer, daily gratitude reflection, planning tomorrow, and preparing mind for sleep.',
            category: 'Wind down',
          ),
          BlueprintBlock(
            title: 'Restorative Deep Sleep',
            startMinute: 570, // 21:30 PM (to 04:30 AM)
            endMinute: 720,   // 24:00
            ampmHalf: AmPmHalf.pm,
            iconKey: '😴',
            colorValue: 0xFF64748B, // Slate
            philosophy:
                '7 hours of undisturbed deep sleep to recharge body and soul for dawn prayer.',
            category: 'Sleep',
          ),
        ],
      );

  static RoutineBlueprint balancedHighPerformer() => RoutineBlueprint(
        id: 102,
        name: 'The Balanced High-Performer',
        tagline:
            'Circadian-aligned 24-hour cadence for peak cognitive output, vitality, and peace.',
        description:
            'Designed for professionals, engineers, and creators who need uninterrupted morning focus, structured afternoon collaboration, and deliberate evening recovery.',
        author: 'Official Dev',
        category: 'High Performance',
        iconKey: '⚡',
        blocks: const [
          BlueprintBlock(
            title: 'Morning Ritual & Mindful Movement',
            startMinute: 360, // 06:00 AM
            endMinute: 450,   // 07:30 AM
            ampmHalf: AmPmHalf.am,
            iconKey: '🌅',
            colorValue: 0xFF06B6D4, // Cyan
            philosophy:
                'Hydration, sunlight exposure, gentle stretching, and mental preparation.',
            category: 'Intentional Rest',
          ),
          BlueprintBlock(
            title: 'Peak Cognitive Deep Work',
            startMinute: 480, // 08:00 AM
            endMinute: 690,   // 11:30 AM
            ampmHalf: AmPmHalf.am,
            iconKey: '🎯',
            colorValue: 0xFF3B82F6, // Blue
            philosophy:
                'Zero-distraction high-leverage problem solving, coding, or strategy.',
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
            philosophy:
                'Meetings, communication, email processing, and administrative execution.',
            category: 'Social activity',
          ),
          BlueprintBlock(
            title: 'Physical Fitness & Recreation',
            startMinute: 300, // 17:00 PM
            endMinute: 420,   // 19:00 PM
            ampmHalf: AmPmHalf.pm,
            iconKey: '🏃',
            colorValue: 0xFF10B981, // Emerald
            philosophy:
                'Strength training, cardio, outdoor exercise, or creative hobby.',
            category: 'Exercise',
          ),
          BlueprintBlock(
            title: 'Unplug, Family & Mindful Wind-Down',
            startMinute: 480, // 20:00 PM
            endMinute: 600,   // 22:00 PM
            ampmHalf: AmPmHalf.pm,
            iconKey: '🕯️',
            colorValue: 0xFFEC4899, // Pink
            philosophy:
                'Dinner with loved ones, reading fiction or non-screen book, dimming lights.',
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
