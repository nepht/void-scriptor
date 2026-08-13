import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../../domain/ai_provider.dart';
import 'ollama_provider.dart';

class HttpOllamaClient implements OllamaClient {
  HttpOllamaClient({http.Client? client}) : client = client ?? http.Client();
  final http.Client client;
  @override
  Future<List<AiModelInfo>> listModels({required String baseUrl}) async {
    final response = await client.get(Uri.parse('$baseUrl/api/tags'));
    _check(response);
    final body = jsonDecode(response.body) as Map<String, dynamic>;
    return ((body['models'] as List<dynamic>? ?? const []))
        .whereType<Map<String, dynamic>>()
        .map(
          (item) => AiModelInfo(
            id: item['name'] as String? ?? '',
            displayName: item['name'] as String? ?? '',
            capabilities: const {AiCapability.textGeneration},
          ),
        )
        .toList(growable: false);
  }

  @override
  Future<AiGenerationResult> generate({
    required String baseUrl,
    required AiGenerationRequest request,
  }) async {
    final response = await client.post(
      Uri.parse('$baseUrl/api/generate'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'model': request.model ?? 'llama3.2',
        'prompt': request.prompt,
        'stream': false,
      }),
    );
    _check(response);
    final body = jsonDecode(response.body) as Map<String, dynamic>;
    return AiGenerationResult(
      providerRequestId: request.jobId,
      outputs: [
        AiGeneratedOutput(
          type: AiOutputType.text,
          text: body['response'] as String? ?? '',
          mimeType: 'text/plain',
        ),
      ],
    );
  }

  void _check(http.Response response) {
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw StateError(
        'Ollama request failed with HTTP ${response.statusCode}.',
      );
    }
  }
}
