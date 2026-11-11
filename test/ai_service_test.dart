import 'package:flutter_test/flutter_test.dart';
import 'package:focus_clock/services/ai_service.dart';

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
}
