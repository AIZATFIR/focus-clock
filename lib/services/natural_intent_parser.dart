import '../core/theme.dart';
import '../core/time_math.dart';
import '../models/activity.dart';

class ParsedIntent {
  final String title;
  final int startMinute; // 0..720 within the half
  final int endMinute;   // 0..720
  final AmPmHalf ampmHalf;
  final DateTime date;
  final int colorValue;
  final String iconKey;
  final int durationMinutes;

  const ParsedIntent({
    required this.title,
    required this.startMinute,
    required this.endMinute,
    required this.ampmHalf,
    required this.date,
    required this.colorValue,
    required this.iconKey,
    required this.durationMinutes,
  });

  Activity toActivity() {
    return Activity()
      ..title = title
      ..startMinute = startMinute
      ..endMinute = endMinute
      ..ampmHalf = ampmHalf
      ..date = dateOnly(date)
      ..colorValue = colorValue
      ..iconKey = iconKey
      ..description = 'Created via Natural Intent'
      ..recurrence = 'none'
      ..createdAt = DateTime.now()
      ..updatedAt = DateTime.now();
  }
}

class NaturalIntentParser {
  /// Parses natural language intention text into a concrete Activity schedule.
  static ParsedIntent parse(String input, {DateTime? referenceTime, DateTime? targetDate}) {
    final now = referenceTime ?? DateTime.now();
    final date = targetDate ?? now;
    final lower = input.trim().toLowerCase();

    // 1. Infer duration (default: 45 minutes)
    int duration = 45;
    final hourDurMatch = RegExp(r'(\d+)\s*(?:jam|hours?|hr|h)\b').firstMatch(lower);
    final minDurMatch = RegExp(r'(\d+)\s*(?:menit|mins?|minutes?|m)\b').firstMatch(lower);
    if (hourDurMatch != null && minDurMatch != null) {
      final h = int.tryParse(hourDurMatch.group(1)!) ?? 0;
      final m = int.tryParse(minDurMatch.group(1)!) ?? 0;
      duration = (h * 60) + m;
    } else if (hourDurMatch != null) {
      final h = int.tryParse(hourDurMatch.group(1)!) ?? 1;
      duration = h * 60;
    } else if (minDurMatch != null) {
      duration = int.tryParse(minDurMatch.group(1)!) ?? 45;
    }

    // 2. Infer start time
    int start24 = now.hour * 60 + now.minute;
    // Look for explicit time patterns: "jam 8 malam", "at 8pm", "jam 14:00", "at 7:30 am", "pukul 9"
    final timeMatch = RegExp(r'(?:jam|at|pukul|pada|pukul)\s*(\d{1,2})(?::(\d{2}))?\s*(am|pm|malam|pagi|siang|sore)?').firstMatch(lower);
    final directTimeMatch = RegExp(r'\b(\d{1,2}):(\d{2})\s*(am|pm)?').firstMatch(lower);

    if (timeMatch != null) {
      int hour = int.tryParse(timeMatch.group(1)!) ?? now.hour;
      final minute = int.tryParse(timeMatch.group(2) ?? '0') ?? 0;
      final modifier = timeMatch.group(3);

      if (modifier == 'pm' || modifier == 'malam' || modifier == 'sore') {
        if (hour < 12) hour += 12;
      } else if (modifier == 'am' || modifier == 'pagi') {
        if (hour == 12) hour = 0;
      } else if (modifier == 'siang') {
        if (hour >= 1 && hour <= 6) hour += 12;
      }
      start24 = (hour * 60) + minute;
    } else if (directTimeMatch != null) {
      int hour = int.tryParse(directTimeMatch.group(1)!) ?? now.hour;
      final minute = int.tryParse(directTimeMatch.group(2)!) ?? 0;
      final modifier = directTimeMatch.group(3);
      if (modifier == 'pm' && hour < 12) hour += 12;
      if (modifier == 'am' && hour == 12) hour = 0;
      start24 = (hour * 60) + minute;
    } else {
      // Default: snap to nearest upcoming 5 minutes
      start24 = snap5(start24);
    }

    start24 = start24.clamp(0, 1435);
    final end24 = (start24 + duration).clamp(start24 + 5, 1440);

    final dbStart = toDbMinute(start24);
    final dbHalf = toDbHalf(start24);
    final dbEnd = toDbEndMinute(end24, dbHalf);

    // 3. Infer category, icon, and eye-friendly pastel color
    String icon = '🎯';
    int color = pastelBookColors[3]; // Warm Ochre
    String cleanedTitle = input
        .replaceAll(RegExp(r'\b\d+\s*(?:jam|hours?|hr|h|menit|mins?|minutes?|m)\b', caseSensitive: false), '')
        .replaceAll(RegExp(r'(?:jam|at|pukul|pada)\s*\d{1,2}(?::\d{2})?\s*(?:am|pm|malam|pagi|siang|sore)?', caseSensitive: false), '')
        .replaceAll(RegExp(r'\b\d{1,2}:\d{2}\s*(?:am|pm)?\b', caseSensitive: false), '')
        .trim();

    if (cleanedTitle.isEmpty) {
      cleanedTitle = 'Sesi Fokus';
    } else {
      // Capitalize first letter
      cleanedTitle = cleanedTitle[0].toUpperCase() + cleanedTitle.substring(1);
    }

    if (lower.contains('gym') || lower.contains('olahraga') || lower.contains('run') || lower.contains('workout') || lower.contains('exercise') || lower.contains('lari') || lower.contains('fitness')) {
      icon = '🏃';
      color = pastelBookColors[6]; // Soft Terracotta
    } else if (lower.contains('code') || lower.contains('coding') || lower.contains('program') || lower.contains('dev') || lower.contains('laptop') || RegExp(r'\bwork\b').hasMatch(lower) || lower.contains('project')) {
      icon = '💻';
      color = pastelBookColors[2]; // Soft Periwinkle
    } else if (lower.contains('study') || lower.contains('belajar') || lower.contains('baca') || lower.contains('read') || lower.contains('book') || lower.contains('buku') || lower.contains('kursus')) {
      icon = '📖';
      color = pastelBookColors[0]; // Muted Sage Green
    } else if (lower.contains('rest') || lower.contains('istirahat') || lower.contains('sleep') || lower.contains('tidur') || lower.contains('nap') || lower.contains('santai') || lower.contains('meditasi')) {
      icon = '🧘';
      color = pastelBookColors[4]; // Soft Lavender
    } else if (lower.contains('write') || lower.contains('nulis') || lower.contains('tulis') || lower.contains('draft') || lower.contains('essay') || lower.contains('journal')) {
      icon = '✍️';
      color = pastelBookColors[1]; // Dusty Rose
    } else if (lower.contains('makan') || lower.contains('lunch') || lower.contains('dinner') || lower.contains('breakfast') || lower.contains('coffee') || lower.contains('kopi') || lower.contains('tea')) {
      icon = '☕';
      color = pastelBookColors[8]; // Muted Sand
    }

    return ParsedIntent(
      title: cleanedTitle,
      startMinute: dbStart,
      endMinute: dbEnd,
      ampmHalf: dbHalf,
      date: date,
      colorValue: color,
      iconKey: icon,
      durationMinutes: duration,
    );
  }
}
