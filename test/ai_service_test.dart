import 'package:flutter_test/flutter_test.dart';
import 'package:focus_clock/services/ai_service.dart';
import 'package:focus_clock/services/gemini_tool_adapter.dart';

void main() {
  test('converts earlier plain chat turns into Gemini roles', () {
    final history = openAiMessagesToGeminiHistory([
      {'role': 'system', 'content': 'system prompt'},
      {'role': 'user', 'content': 'I want to win the national LKS'},
      {'role': 'assistant', 'content': 'When is the competition?'},
    ]);

    expect(
      history.map((message) => message.toJson()).toList(),
      [
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
      ],
    );
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
