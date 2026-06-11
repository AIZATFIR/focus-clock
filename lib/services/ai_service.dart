import 'dart:convert';

import 'package:http/http.dart' as http;

import '../core/time_math.dart';
import '../data/repositories/activity_repository.dart';
import '../data/repositories/preset_repository.dart';
import '../models/activity.dart';

// ── Tool schemas (OpenAI function calling format) ─────────────────────────────

const _tools = [
  {
    'type': 'function',
    'function': {
      'name': 'generate_blueprint',
      'description':
          'Generate a psychologically balanced full-day schedule (Fitrah Blueprint). '
          'Creates Deep Work blocks, Intentional Rest, Active Rest, Wind Down, and Sleep blocks '
          'based on circadian rhythm and ultradian cycle research. '
          'Call this when user asks to generate, plan, or blueprint their day.',
      'parameters': {
        'type': 'object',
        'required': ['date', 'wake_hour', 'sleep_hour'],
        'properties': {
          'date': {'type': 'string', 'description': 'ISO date yyyy-MM-dd'},
          'wake_hour': {
            'type': 'integer',
            'description': 'Wake-up hour (0-23), e.g. 6 for 6am',
          },
          'sleep_hour': {
            'type': 'integer',
            'description': 'Target sleep hour (0-23), e.g. 22 for 10pm',
          },
          'goals': {
            'type': 'array',
            'items': {'type': 'string'},
            'description':
                'Main goals/tasks for the day, e.g. ["Math study", "Exercise"]',
          },
        },
      },
    },
  },
  {
    'type': 'function',
    'function': {
      'name': 'set_priority',
      'description':
          'Set importance level and/or deadline for an activity (for Eisenhower Matrix).',
      'parameters': {
        'type': 'object',
        'required': ['id'],
        'properties': {
          'id': {'type': 'integer'},
          'importance': {
            'type': 'integer',
            'description': '0 = low importance, 1 = high importance',
            'enum': [0, 1],
          },
          'deadline': {
            'type': 'string',
            'description':
                'ISO date yyyy-MM-dd for deadline. Null to clear.',
          },
        },
      },
    },
  },
  {
    'type': 'function',
    'function': {
      'name': 'list_activities',
      'description': 'List all activities for a given date.',
      'parameters': {
        'type': 'object',
        'properties': {
          'date': {
            'type': 'string',
            'description': 'ISO date yyyy-MM-dd. Defaults to today if omitted.',
          },
        },
      },
    },
  },
  {
    'type': 'function',
    'function': {
      'name': 'create_activity',
      'description': 'Create a new time-block activity.',
      'parameters': {
        'type': 'object',
        'required': ['title', 'date', 'start_hour'],
        'properties': {
          'title': {'type': 'string'},
          'date': {'type': 'string', 'description': 'ISO date yyyy-MM-dd'},
          'start_hour': {
            'type': 'integer',
            'description': '0-23 (24h). 7=7am, 14=2pm.',
          },
          'start_minute': {'type': 'integer', 'description': '0-59. Default 0.'},
          'duration_minutes': {
            'type': 'integer',
            'description': 'Duration minutes. Default 60.',
          },
          'description': {'type': 'string'},
          'recurrence': {
            'type': 'string',
            'enum': ['none', 'daily', 'weekly'],
          },
        },
      },
    },
  },
  {
    'type': 'function',
    'function': {
      'name': 'update_activity',
      'description': 'Update an existing activity. Only supply fields to change.',
      'parameters': {
        'type': 'object',
        'required': ['id'],
        'properties': {
          'id': {'type': 'integer'},
          'title': {'type': 'string'},
          'date': {'type': 'string'},
          'start_hour': {'type': 'integer'},
          'start_minute': {'type': 'integer'},
          'duration_minutes': {'type': 'integer'},
          'description': {'type': 'string'},
          'recurrence': {
            'type': 'string',
            'enum': ['none', 'daily', 'weekly'],
          },
        },
      },
    },
  },
  {
    'type': 'function',
    'function': {
      'name': 'delete_activity',
      'description': 'Delete an activity by ID.',
      'parameters': {
        'type': 'object',
        'required': ['id'],
        'properties': {
          'id': {'type': 'integer'},
        },
      },
    },
  },
];

// ── Chat message ──────────────────────────────────────────────────────────────

class ChatMessage {
  ChatMessage({required this.role, required this.text, this.isLoading = false});
  final String role; // 'user' | 'model'
  final String text;
  final bool isLoading;
}

// ── AiService ─────────────────────────────────────────────────────────────────

class AiService {
  AiService({
    required this.baseUrl,
    required this.apiKey,
    required this.model,
    required ActivityRepository activityRepo,
    required PresetRepository presetRepo,
  })  : _activityRepo = activityRepo,
        _presetRepo = presetRepo;

  final String baseUrl;
  final String apiKey;
  final String model;
  final ActivityRepository _activityRepo;
  final PresetRepository _presetRepo;

  // Conversation history (OpenAI messages format)
  final List<Map<String, dynamic>> _history = [];
  bool _initialized = false;

  Future<void> _ensureInit() async {
    if (_initialized) return;
    final now = DateTime.now();
    final presets = await _presetRepo.getAll();
    final presetList = presets.isEmpty
        ? 'none'
        : presets
            .asMap()
            .entries
            .map((e) => '${e.key + 1}. "${e.value.name}"')
            .join(', ');
    final dateStr = _fmtDate(now);
    final timeStr =
        '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';

    _history.add({
      'role': 'system',
      'content': '''You are a smart scheduling assistant for Focus Clock, a time-blocking productivity app.
Today: $dateStr. Current time: $timeStr.
User presets: $presetList.

## Core Rules
- Call list_activities first if you need existing schedule before editing.
- Times are 24h. Convert natural language: "7am"→7, "2pm"→14, "setengah 8"→7:30.
- "move"/"pindah"/"geser": call update_activity with new start_hour.
- "delete"/"hapus"/"cancel": call delete_activity.
- After every tool call, summarise in 1 sentence.
- If ambiguous (multiple matches), list IDs and ask.
- Reply in the same language as the user. Be concise.

## Eisenhower Matrix
- Use set_priority to classify tasks: importance=1 (important), importance=0 (not important).
- Urgency is auto-computed from deadline (≤3 days = urgent).
- Quadrants: urgent+important=DO, not urgent+important=SCHEDULE, urgent+not important=DELEGATE, not urgent+not important=ELIMINATE.
- When user inputs multiple tasks at once, classify and set priorities before scheduling.

## Fitrah Blueprint (generate_blueprint tool)
When generating a day blueprint, follow this psychology-based structure:
1. **Morning Routine** (wake_hour, 30min): Light planning, hydrate.
2. **Deep Work Block 1** (wake_hour+0.5h, 90min): Main goal / highest-priority task. Peak cognitive energy.
3. **Intentional Rest** (after DW1, 20min): Complete rest — NO screens, NO scrolling. Brain consolidates memory (DMN activation).
4. **Deep Work Block 2** (if time permits, 90min): Second priority task.
5. **Intentional Rest** (20min): Same — no screens.
6. **Lunch + Active Rest** (90min): Eat + light exercise/social/hobbies. Restores dopamine.
7. **Deep Work Block 3** (optional, 60-90min): Admin tasks, less demanding work.
8. **Wind Down** (sleep_hour - 60min, 45min): Journal, reflect day, light plan tomorrow.
9. **Sleep** (sleep_hour, 90-min cycle × n = ideal 7.5h or 9h): Use 90-min multiples to avoid sleep inertia.

Key constraints:
- Deep Work blocks: MAX 90-120 min each (ultradian rhythm).
- Intentional Rest: NO cognitive activity. Schedule it explicitly.
- Sleep: Always in 90-min multiples (4.5h, 6h, 7.5h, 9h). Count back from wake time.
- Goals parameter → assign to Deep Work blocks in order of importance.''',
    });
    _initialized = true;
  }

  /// Send message, execute any tool calls, return final text.
  Future<String> send(String userMessage) async {
    await _ensureInit();
    _history.add({'role': 'user', 'content': userMessage});

    // Agentic loop
    for (int loop = 0; loop < 6; loop++) {
      final response = await _callApi();
      final choice = response['choices'][0];
      final msg = choice['message'] as Map<String, dynamic>;

      // Add assistant message to history
      _history.add(msg);

      final toolCalls = msg['tool_calls'] as List?;
      if (toolCalls == null || toolCalls.isEmpty) {
        // Final answer
        return (msg['content'] as String?)?.trim() ?? '(no response)';
      }

      // Execute each tool call
      for (final tc in toolCalls) {
        final name = tc['function']['name'] as String;
        final args = jsonDecode(tc['function']['arguments'] as String)
            as Map<String, dynamic>;
        final result = await _executeTool(name, args);
        _history.add({
          'role': 'tool',
          'tool_call_id': tc['id'],
          'content': jsonEncode(result),
        });
      }
    }

    return '(max tool iterations reached)';
  }

  Future<Map<String, dynamic>> _callApi() async {
    final uri = Uri.parse('$baseUrl/chat/completions');
    final body = jsonEncode({
      'model': model,
      'messages': _history,
      'tools': _tools,
      'tool_choice': 'auto',
    });

    final resp = await http.post(
      uri,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $apiKey',
        if (baseUrl.contains('openrouter'))
          'HTTP-Referer': 'https://focusclock.app',
      },
      body: body,
    );

    if (resp.statusCode != 200) {
      throw Exception('API ${resp.statusCode}: ${resp.body}');
    }
    return jsonDecode(resp.body) as Map<String, dynamic>;
  }

  // ── Tool executor ─────────────────────────────────────────────────────────

  Future<Map<String, dynamic>> _executeTool(
      String name, Map<String, dynamic> args) async {
    try {
      return switch (name) {
        'list_activities' => await _listActivities(args),
        'create_activity' => await _createActivity(args),
        'update_activity' => await _updateActivity(args),
        'delete_activity' => await _deleteActivity(args),
        'set_priority' => await _setPriority(args),
        'generate_blueprint' => await _generateBlueprint(args),
        _ => {'error': 'Unknown tool: $name'},
      };
    } catch (e) {
      return {'error': e.toString()};
    }
  }

  Future<Map<String, dynamic>> _listActivities(
      Map<String, dynamic> args) async {
    final dateStr = args['date'] as String?;
    final date = dateStr != null ? DateTime.parse(dateStr) : DateTime.now();
    final activities = await _activityRepo.getByDate(dateOnly(date));
    return {
      'activities': activities
          .map((a) => {
                'id': a.id,
                'title': a.title,
                'date': _fmtDate(a.date),
                'start': _fmtTime(a.ampmHalf, a.startMinute),
                'end': _fmtTime(a.ampmHalf, a.endMinute),
                'description': a.description,
                'recurrence': a.recurrence,
              })
          .toList(),
    };
  }

  Future<Map<String, dynamic>> _createActivity(
      Map<String, dynamic> args) async {
    final title = args['title'] as String;
    final dateStr = args['date'] as String;
    final startHour = (args['start_hour'] as num).toInt();
    final startMin = (args['start_minute'] as num?)?.toInt() ?? 0;
    final duration = (args['duration_minutes'] as num?)?.toInt() ?? 60;
    final description = args['description'] as String? ?? '';
    final recurrence = args['recurrence'] as String? ?? 'none';

    final date = DateTime.parse(dateStr);
    final half = startHour < 12 ? AmPmHalf.am : AmPmHalf.pm;
    final relStart = (startHour % 12) * 60 + startMin;
    final relEnd = (relStart + duration).clamp(0, 720);
    final now = DateTime.now();

    final a = Activity()
      ..title = title
      ..startMinute = relStart
      ..endMinute = relEnd
      ..ampmHalf = half
      ..date = dateOnly(date)
      ..description = description
      ..recurrence = recurrence
      ..colorValue = 0xFFFFD700
      ..createdAt = now
      ..updatedAt = now;

    final id = await _activityRepo.upsert(a);
    return {'success': true, 'id': id, 'title': title};
  }

  Future<Map<String, dynamic>> _updateActivity(
      Map<String, dynamic> args) async {
    final id = (args['id'] as num).toInt();
    final existing = await _activityRepo.get(id);
    if (existing == null) return {'error': 'Activity $id not found'};

    if (args['title'] != null) existing.title = args['title'] as String;
    if (args['description'] != null) {
      existing.description = args['description'] as String;
    }
    if (args['recurrence'] != null) {
      existing.recurrence = args['recurrence'] as String;
    }
    if (args['date'] != null) {
      existing.date = dateOnly(DateTime.parse(args['date'] as String));
    }

    if (args['start_hour'] != null || args['start_minute'] != null) {
      final h = args['start_hour'] != null
          ? (args['start_hour'] as num).toInt()
          : (existing.ampmHalf == AmPmHalf.pm ? 12 : 0) +
              existing.startMinute ~/ 60;
      final m = args['start_minute'] != null
          ? (args['start_minute'] as num).toInt()
          : existing.startMinute % 60;
      final dur = existing.endMinute - existing.startMinute;
      existing.ampmHalf = h < 12 ? AmPmHalf.am : AmPmHalf.pm;
      existing.startMinute = (h % 12) * 60 + m;
      if (args['duration_minutes'] == null) {
        existing.endMinute = (existing.startMinute + dur).clamp(0, 720);
      }
    }

    if (args['duration_minutes'] != null) {
      final dur = (args['duration_minutes'] as num).toInt();
      existing.endMinute = (existing.startMinute + dur).clamp(0, 720);
    }

    await _activityRepo.upsert(existing);
    return {'success': true, 'id': id};
  }

  Future<Map<String, dynamic>> _deleteActivity(
      Map<String, dynamic> args) async {
    final id = (args['id'] as num).toInt();
    final ok = await _activityRepo.delete(id);
    return {'success': ok, 'id': id};
  }

  Future<Map<String, dynamic>> _setPriority(
      Map<String, dynamic> args) async {
    final id = (args['id'] as num).toInt();
    final existing = await _activityRepo.get(id);
    if (existing == null) return {'error': 'Activity $id not found'};

    if (args['importance'] != null) {
      await _activityRepo.setImportance(id, (args['importance'] as num).toInt());
    }
    if (args.containsKey('deadline')) {
      final dl = args['deadline'] as String?;
      await _activityRepo.setDeadline(
          id, dl != null ? DateTime.parse(dl) : null);
    }
    return {'success': true, 'id': id};
  }

  /// Generates a Fitrah Blueprint — creates all blocks in one call.
  /// The AI is responsible for computing timestamps from the system prompt rules,
  /// but as a fallback this tool directly creates a hardcoded template.
  Future<Map<String, dynamic>> _generateBlueprint(
      Map<String, dynamic> args) async {
    final dateStr = args['date'] as String;
    final date = DateTime.parse(dateStr);
    final wakeH = (args['wake_hour'] as num).toInt();
    final sleepH = (args['sleep_hour'] as num).toInt();
    final goals = (args['goals'] as List?)?.cast<String>() ?? [];

    // Available work hours
    final workStart = wakeH + 1; // after morning routine
    // Build blueprint blocks
    final blocks = <Map<String, dynamic>>[];

    // Morning routine (30 min)
    blocks.add({
      'title': '🌅 Morning Routine',
      'start_hour': wakeH,
      'start_minute': 0,
      'duration_minutes': 30,
      'description': 'Hydrate, light stretch, review today\'s plan.',
      'color': 0xFFFFD700,
    });

    int cursor = workStart * 60; // minutes from midnight

    // Deep Work blocks for goals
    final goalLabels = goals.isNotEmpty
        ? goals
        : ['Deep Work'];
    for (int i = 0; i < goalLabels.length && i < 3; i++) {
      final dwDur = 90;
      // Don't schedule past sleepH - 2h
      if (cursor + dwDur > sleepH * 60 - 120) break;

      blocks.add({
        'title': '🎯 Deep Work: ${goalLabels[i]}',
        'start_hour': cursor ~/ 60,
        'start_minute': cursor % 60,
        'duration_minutes': dwDur,
        'description': 'Full focus. No notifications, no interruptions.',
        'color': 0xFF4A9EFF,
      });
      cursor += dwDur;

      // Intentional Rest after each Deep Work
      blocks.add({
        'title': '🧠 Intentional Rest',
        'start_hour': cursor ~/ 60,
        'start_minute': cursor % 60,
        'duration_minutes': 20,
        'description':
            'No screens. Let your mind wander — activates DMN for memory consolidation.',
        'color': 0xFF6BCB77,
      });
      cursor += 20;

      // Lunch break after first Deep Work (if ~noon)
      if (i == 0 && cursor ~/ 60 >= 11) {
        blocks.add({
          'title': '🍱 Lunch + Active Rest',
          'start_hour': cursor ~/ 60,
          'start_minute': cursor % 60,
          'duration_minutes': 90,
          'description':
              'Eat mindfully. Short walk, social time, or light hobby.',
          'color': 0xFFFF9F40,
        });
        cursor += 90;
      }
    }

    // Wind Down
    final windDownStart = sleepH * 60 - 60;
    if (windDownStart > cursor) {
      blocks.add({
        'title': '📓 Wind Down',
        'start_hour': windDownStart ~/ 60,
        'start_minute': windDownStart % 60,
        'duration_minutes': 45,
        'description':
            'Journal, reflect on today, lightly plan tomorrow with AI.',
        'color': 0xFF9B8FFF,
      });
    }

    // Sleep (90-min cycle — round 7.5h back from wake)
    blocks.add({
      'title': '💤 Sleep',
      'start_hour': sleepH,
      'start_minute': 0,
      'duration_minutes': ((wakeH + 24 - sleepH) * 60).clamp(270, 540),
      'description':
          '${(wakeH + 24 - sleepH)} hours = ${(wakeH + 24 - sleepH) ~/ 1.5} sleep cycles (90-min each). Wakes at end of cycle to avoid sleep inertia.',
      'color': 0xFF2E2E4E,
    });

    // Create all blocks
    final created = <int>[];
    final now = DateTime.now();
    for (final b in blocks) {
      final h = b['start_hour'] as int;
      final m = b['start_minute'] as int;
      final dur = b['duration_minutes'] as int;
      final half = h < 12 ? AmPmHalf.am : AmPmHalf.pm;
      final relStart = (h % 12) * 60 + m;
      final a = Activity()
        ..title = b['title'] as String
        ..startMinute = relStart
        ..endMinute = (relStart + dur).clamp(0, 720)
        ..ampmHalf = half
        ..date = dateOnly(date)
        ..description = b['description'] as String
        ..recurrence = 'none'
        ..colorValue = b['color'] as int
        ..createdAt = now
        ..updatedAt = now;
      final id = await _activityRepo.upsert(a);
      created.add(id);
    }

    return {
      'success': true,
      'blocks_created': created.length,
      'message':
          'Blueprint generated: ${created.length} blocks for $dateStr. '
          'Deep Work at peak energy morning, Intentional Rest for memory consolidation, '
          'Sleep at ${sleepH}:00 (90-min cycles).',
    };
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  String _fmtDate(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  String _fmtTime(AmPmHalf half, int relMin) {
    final h = (half == AmPmHalf.pm ? 12 : 0) + relMin ~/ 60;
    final m = relMin % 60;
    return '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}';
  }

  void reset() {
    _history.clear();
    _initialized = false;
  }
}
