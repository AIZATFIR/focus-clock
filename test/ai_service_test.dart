import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:focus_clock/data/repositories/activity_repository.dart';
import 'package:focus_clock/data/repositories/preset_repository.dart';
import 'package:focus_clock/services/ai_service.dart';
import 'package:focus_clock/services/gemini_tool_adapter.dart';
import 'package:focus_clock/services/notification_service.dart';
import 'package:focus_clock/services/secure_storage_service.dart';

class _FakeAiStorage implements AiServiceStorage {
  _FakeAiStorage({this.apiKey = 'sk-user-key'});

  final String? apiKey;

  @override
  Future<String?> getGeminiApiKey() async => apiKey;

  @override
  Future<String?> getOpenRouterKey() async => null;

  @override
  Future<String> getBackendServerUrl() async => 'https://backend.example';
}

void main() {
  test('sends a configured non-Gemini key directly to its provider', () async {
    final requests = <http.Request>[];
    final service = AiService(
      baseUrl: 'https://provider.example/v1',
      apiKey: 'sk-user-key',
      model: 'provider-model',
      activityRepo: ActivityRepository(null, NotificationService()),
      presetRepo: PresetRepository(null),
      secureStorage: _FakeAiStorage(),
      httpClient: MockClient((request) async {
        requests.add(request);
        return http.Response(
          jsonEncode({
            'choices': [
              {
                'message': {'role': 'assistant', 'content': 'Got it.'},
              },
            ],
          }),
          200,
        );
      }),
    );

    expect(await service.send('I want to win LKS'), 'Got it.');
    expect(requests, hasLength(1));
    expect(
      requests.single.url,
      Uri.parse('https://provider.example/v1/chat/completions'),
    );
    expect(requests.single.headers['authorization'], 'Bearer sk-user-key');
    expect(jsonDecode(requests.single.body)['model'], 'provider-model');
    expect(service.activeMode, AiExecutionMode.byokOpenAiCompatibleDirect);
  });

  test(
    'keeps backend routing when no direct provider key is configured',
    () async {
      final requests = <http.Request>[];
      final service = AiService(
        baseUrl: 'https://provider.example/v1',
        apiKey: '',
        model: 'provider-model',
        activityRepo: ActivityRepository(null, NotificationService()),
        presetRepo: PresetRepository(null),
        secureStorage: _FakeAiStorage(apiKey: null),
        httpClient: MockClient((request) async {
          requests.add(request);
          return http.Response(jsonEncode({'reply': 'Backend reply.'}), 200);
        }),
      );

      expect(await service.send('Help me plan today'), 'Backend reply.');
      expect(requests, hasLength(1));
      expect(
        requests.single.url,
        Uri.parse('https://backend.example/api/chat/secretary'),
      );
      expect(service.activeMode, AiExecutionMode.serverOpenRouter);
    },
  );

  test('connects to a loopback provider without an API key', () async {
    final requests = <http.Request>[];
    final service = AiService(
      baseUrl: 'http://localhost:11434/v1',
      apiKey: '',
      model: 'llama3.2:latest',
      activityRepo: ActivityRepository(null, NotificationService()),
      presetRepo: PresetRepository(null),
      secureStorage: _FakeAiStorage(apiKey: null),
      httpClient: MockClient((request) async {
        requests.add(request);
        return http.Response(
          jsonEncode({
            'choices': [
              {
                'message': {'role': 'assistant', 'content': 'Local reply.'},
              },
            ],
          }),
          200,
        );
      }),
    );

    expect(await service.send('Help me focus'), 'Local reply.');
    expect(
      requests.single.url,
      Uri.parse('http://localhost:11434/v1/chat/completions'),
    );
    expect(requests.single.headers, isNot(contains('authorization')));
    expect(service.activeMode, AiExecutionMode.byokOpenAiCompatibleDirect);
  });

  test('links AI-created activities to the exact current focus goal', () async {
    final repository = ActivityRepository(null, NotificationService());
    var requestCount = 0;
    final service = AiService(
      baseUrl: 'https://provider.example/v1',
      apiKey: 'sk-user-key',
      model: 'provider-model',
      focusGoal: 'Menang LKS nasional',
      activityRepo: repository,
      presetRepo: PresetRepository(null),
      secureStorage: _FakeAiStorage(),
      httpClient: MockClient((request) async {
        requestCount++;
        if (requestCount == 1) {
          return http.Response(
            jsonEncode({
              'choices': [
                {
                  'message': {
                    'role': 'assistant',
                    'tool_calls': [
                      {
                        'id': 'call-create',
                        'type': 'function',
                        'function': {
                          'name': 'create_activity',
                          'arguments': jsonEncode({
                            'title': 'Latihan LKS',
                            'date': '2026-11-12',
                            'start_hour': 10,
                            'duration_minutes': 60,
                            'focus_goal_link': 'Menang LKS nasional',
                          }),
                        },
                      },
                    ],
                  },
                },
              ],
            }),
            200,
          );
        }
        return http.Response(
          jsonEncode({
            'choices': [
              {
                'message': {
                  'role': 'assistant',
                  'content': 'Sudah dijadwalkan.',
                },
              },
            ],
          }),
          200,
        );
      }),
    );

    expect(
      await service.send('Jadwalkan latihan LKS besok'),
      'Sudah dijadwalkan.',
    );
    final activities = await repository.getByDate(DateTime(2026, 11, 12));
    expect(activities, hasLength(1));
    expect(activities.single.focusGoalLink, 'Menang LKS nasional');
  });

  test('converts earlier plain chat turns into Gemini roles', () {
    final history = openAiMessagesToGeminiHistory([
      {'role': 'system', 'content': 'system prompt'},
      {'role': 'user', 'content': 'I want to win the national LKS'},
      {'role': 'assistant', 'content': 'When is the competition?'},
    ]);

    expect(history.map((message) => message.toJson()).toList(), [
      {
        'role': 'user',
        'parts': [
          {'text': 'I want to win the national LKS'},
        ],
      },
      {
        'role': 'model',
        'parts': [
          {'text': 'When is the competition?'},
        ],
      },
    ]);
  });

  test('skips tool messages and entries without text', () {
    final history = openAiMessagesToGeminiHistory([
      {'role': 'assistant', 'tool_calls': []},
      {'role': 'tool', 'content': '{"success":true}'},
      {'role': 'user', 'content': null},
    ]);

    expect(history, isEmpty);
  });

  test('converts OpenAI function declarations to Gemini schemas', () {
    final tools = convertOpenAiToolsToGemini([
      {
        'type': 'function',
        'function': {
          'name': 'schedule_adaptive_goal',
          'description': 'Plan repeated practice.',
          'parameters': {
            'type': 'object',
            'required': ['goal_title', 'preferred_time'],
            'properties': {
              'goal_title': {'type': 'string'},
              'preferred_time': {
                'type': 'string',
                'enum': ['morning', 'afternoon', 'evening'],
              },
            },
          },
        },
      },
    ]);

    expect(tools, hasLength(1));
    expect(tools.single.functionDeclarations, hasLength(1));
    expect(tools.single.functionDeclarations!.single.toJson(), {
      'name': 'schedule_adaptive_goal',
      'description': 'Plan repeated practice.',
      'parameters': {
        'type': 'OBJECT',
        'required': ['goal_title', 'preferred_time'],
        'properties': {
          'goal_title': {'type': 'STRING'},
          'preferred_time': {
            'type': 'STRING',
            'format': 'enum',
            'enum': ['morning', 'afternoon', 'evening'],
          },
        },
      },
    });
  });
}
