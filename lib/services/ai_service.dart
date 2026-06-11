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

Rules:
- Call list_activities first if you need existing schedule before editing.
- Times are 24h. Convert natural language: "7am"→7, "2pm"→14, "setengah 8"→7:30.
- "move"/"pindah"/"geser": call update_activity with new start_hour.
- "delete"/"hapus"/"cancel": call delete_activity.
- After every tool call, summarise in 1 sentence.
- If ambiguous (multiple matches), list IDs and ask.
- Reply in the same language as the user. Be concise.''',
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
