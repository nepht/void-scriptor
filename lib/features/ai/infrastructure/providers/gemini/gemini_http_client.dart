import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../../domain/ai_provider.dart';
import 'gemini_provider.dart';

class HttpGeminiClient implements GeminiClient {
  HttpGeminiClient({
    http.Client? client,
    this.baseUrl = 'https://generativelanguage.googleapis.com/v1beta',
  }) : client = client ?? http.Client();
  final http.Client client;
  final String baseUrl;
  @override
  Future<List<AiModelInfo>> listModels({required String apiKey}) async {
    final response = await client.get(
      Uri.parse('$baseUrl/models'),
      headers: {'x-goog-api-key': apiKey},
    );
    _check(response);
    final body = jsonDecode(response.body) as Map<String, dynamic>;
    return ((body['models'] as List<dynamic>? ?? const []))
        .whereType<Map<String, dynamic>>()
        .map(
          (item) => AiModelInfo(
            id: (item['name'] as String? ?? '').split('/').last,
            displayName:
                item['displayName'] as String? ?? item['name'] as String? ?? '',
            capabilities: const {
              AiCapability.textGeneration,
              AiCapability.imageGeneration,
            },
          ),
        )
        .toList(growable: false);
  }

  @override
  Future<AiGenerationResult> generate({
    required String apiKey,
    required AiGenerationRequest request,
  }) async {
    final model = request.model ?? 'gemini-2.5-flash';
    final response = await client.post(
      Uri.parse('$baseUrl/models/$model:generateContent'),
      headers: {'Content-Type': 'application/json', 'x-goog-api-key': apiKey},
      body: jsonEncode({
        'contents': [
          {
            'parts': [
              {'text': request.prompt},
            ],
          },
        ],
      }),
    );
    _check(response);
    final body = jsonDecode(response.body) as Map<String, dynamic>;
    final text =
        (((body['candidates'] as List<dynamic>? ?? const []).firstOrNull
                as Map<String, dynamic>?)?['content']
            as Map<String, dynamic>?)?['parts'];
    final value = text is List && text.isNotEmpty
        ? (text.first as Map<String, dynamic>)['text'] as String? ?? ''
        : '';
    return AiGenerationResult(
      providerRequestId: body['responseId'] as String? ?? request.jobId,
      outputs: [
        AiGeneratedOutput(
          type: AiOutputType.text,
          text: value,
          mimeType: 'text/plain',
        ),
      ],
    );
  }

  void _check(http.Response response) {
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw StateError(
        'Gemini request failed with HTTP ${response.statusCode}.',
      );
    }
  }
}

extension<T> on List<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
