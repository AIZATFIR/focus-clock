import 'package:google_generative_ai/google_generative_ai.dart';

List<Tool> convertOpenAiToolsToGemini(
  Iterable<Map<String, dynamic>> openAiTools,
) {
  final declarations = <FunctionDeclaration>[];
  for (final tool in openAiTools) {
    if (tool['type'] != 'function' || tool['function'] is! Map) {
      throw const FormatException('Unsupported OpenAI tool declaration.');
    }
    final function = Map<String, dynamic>.from(tool['function'] as Map);
    final parameters = function['parameters'];
    declarations.add(
      FunctionDeclaration(
        function['name'] as String,
        function['description'] as String? ?? '',
        parameters is Map
            ? _schemaFromOpenApi(Map<String, dynamic>.from(parameters))
            : null,
      ),
    );
  }
  return [Tool(functionDeclarations: declarations)];
}

Schema _schemaFromOpenApi(Map<String, dynamic> schema) {
  final description = schema['description'] as String?;
  switch (schema['type']) {
    case 'object':
      final rawProperties = schema['properties'] as Map? ?? const {};
      return Schema.object(
        description: description,
        properties: {
          for (final entry in rawProperties.entries)
            entry.key as String: _schemaFromOpenApi(
              Map<String, dynamic>.from(entry.value as Map),
            ),
        },
        requiredProperties: (schema['required'] as List?)?.cast<String>(),
      );
    case 'array':
      return Schema.array(
        description: description,
        items: _schemaFromOpenApi(
          Map<String, dynamic>.from(schema['items'] as Map),
        ),
      );
    case 'string':
      final values = (schema['enum'] as List?)?.cast<String>();
      return values == null
          ? Schema.string(description: description)
          : Schema.enumString(enumValues: values, description: description);
    case 'integer':
      return Schema.integer(description: description);
    case 'number':
      return Schema.number(description: description);
    case 'boolean':
      return Schema.boolean(description: description);
    default:
      throw FormatException(
        'Unsupported tool parameter type: ${schema['type']}',
      );
  }
}
