import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:focus_clock/data/repositories/activity_repository.dart';
import 'package:focus_clock/data/repositories/preset_repository.dart';
import 'package:focus_clock/core/time_math.dart';
import 'package:focus_clock/models/activity.dart';
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

  test('requires approval before creating a goal-linked activity', () async {
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

    final reply = await service.send('Jadwalkan latihan LKS besok');
    expect(reply, contains('Draf tindakan siap ditinjau'));
    expect(reply, isNot(contains('Sudah dijadwalkan')));
    final proposal = service.pendingProposals.single;
    expect(proposal.toolName, 'create_activity');
    expect(proposal.summary, contains('Latihan LKS'));
    expect(await repository.getByDate(DateTime(2026, 11, 12)), isEmpty);

    expect(
      await service.confirmProposal(proposal.id),
      containsPair('success', true),
    );
    expect(proposal.status, AiActionProposalStatus.applied);
    expect(
      await service.confirmProposal(proposal.id),
      containsPair('error', isA<String>()),
    );
    final activities = await repository.getByDate(DateTime(2026, 11, 12));
    expect(activities, hasLength(1));
    expect(activities.single.focusGoalLink, 'Menang LKS nasional');
  });

  test(
    'does not partially apply a blueprint when a later block conflicts',
    () async {
      final repository = ActivityRepository(null, NotificationService());
      final occupied = Activity()
        ..title = 'Class'
        ..startMinute = 7 * 60
        ..endMinute = 8 * 60
        ..ampmHalf = AmPmHalf.am
        ..date = DateTime(2026, 11, 13)
        ..colorValue = 0xFF000000
        ..createdAt = DateTime(2026, 11, 12)
        ..updatedAt = DateTime(2026, 11, 12);
      await repository.upsert(occupied);

      var requestCount = 0;
      final service = AiService(
        baseUrl: 'https://provider.example/v1',
        apiKey: 'sk-user-key',
        model: 'provider-model',
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
                          'id': 'call-blueprint',
                          'type': 'function',
                          'function': {
                            'name': 'generate_blueprint',
                            'arguments': jsonEncode({
                              'date': '2026-11-13',
                              'wake_hour': 6,
                              'sleep_hour': 22,
                              'goals': ['Menang LKS nasional'],
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
                  'message': {'role': 'assistant', 'content': 'Tinjau draf.'},
                },
              ],
            }),
            200,
          );
        }),
      );

      await service.send('Buat blueprint untuk besok.');
      final proposal = service.pendingProposals.single;
      expect(proposal.toolName, 'generate_blueprint');
      await service.confirmProposal(proposal.id);

      final activities = await repository.getByDate(DateTime(2026, 11, 13));
      expect(activities, hasLength(1));
      expect(activities.single.title, 'Class');
    },
  );

  test(
    'adaptive goal schedule stays a draft until user confirmation',
    () async {
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
                          'id': 'call-plan',
                          'type': 'function',
                          'function': {
                            'name': 'schedule_adaptive_goal',
                            'arguments': jsonEncode({
                              'goal_title': 'Menang LKS nasional',
                              'target_date': '2026-11-20',
                              'daily_hours': 1,
                              'preferred_time': 'morning',
                              'days_per_week': 5,
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
                    'content': 'Tinjau dulu drafnya.',
                  },
                },
              ],
            }),
            200,
          );
        }),
      );

      await service.send('Buatkan jadwal latihan untuk LKS.');
      final proposal = service.pendingProposals.single;
      expect(proposal.toolName, 'schedule_adaptive_goal');
      expect(proposal.summary, contains('Menang LKS nasional'));
      expect(await repository.getByDate(DateTime(2026, 11, 13)), isEmpty);

      await service.confirmProposal(proposal.id);
      final activities = await repository.getByDate(DateTime(2026, 11, 13));
      expect(activities, hasLength(1));
      expect(activities.single.recurrence, 'weekday');
    },
  );

  test(
    'keeps a draft visible if the provider fails after proposing it',
    () async {
      final repository = ActivityRepository(null, NotificationService());
      var requestCount = 0;
      final service = AiService(
        baseUrl: 'https://provider.example/v1',
        apiKey: 'sk-user-key',
        model: 'provider-model',
        activityRepo: repository,
        presetRepo: PresetRepository(null),
        secureStorage: _FakeAiStorage(),
        httpClient: MockClient((request) async {
          requestCount++;
          if (requestCount > 1) return http.Response('provider down', 503);
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
                            'date': '2026-11-13',
                            'start_hour': 10,
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
        }),
      );

      final reply = await service.send('Tolong jadwalkan latihan LKS.');

      expect(reply, contains('Draf tindakan siap ditinjau'));
      expect(service.lastTurnProposals, hasLength(1));
      expect(await repository.getByDate(DateTime(2026, 11, 13)), isEmpty);
    },
  );

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
