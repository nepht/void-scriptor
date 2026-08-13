import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../../domain/ai_provider.dart';
import 'openai_provider.dart';

class HttpOpenAiClient implements OpenAiClient {
  HttpOpenAiClient({
    http.Client? client,
    this.baseUrl = 'https://api.openai.com/v1',
  }) : client = client ?? http.Client();
  final http.Client client;
  final String baseUrl;

  Map<String, String> _headers(String apiKey) => {
    'Authorization': 'Bearer $apiKey',
    'Content-Type': 'application/json',
  };

  @override
  Future<List<AiModelInfo>> listModels({required String apiKey}) async {
    final response = await client.get(
      Uri.parse('$baseUrl/models'),
      headers: _headers(apiKey),
    );
    _check(response);
    final body = jsonDecode(response.body) as Map<String, dynamic>;
    return ((body['data'] as List<dynamic>? ?? const []))
        .whereType<Map<String, dynamic>>()
        .map(
          (item) => AiModelInfo(
            id: item['id'] as String,
            displayName: item['id'] as String,
            capabilities: const {AiCapability.textGeneration},
          ),
        )
        .toList(growable: false);
  }

  @override
  Future<AiGenerationResult> generate({
    required String apiKey,
    required AiGenerationRequest request,
  }) async {
    final response = request.target == PromptTarget.image
        ? await client.post(
            Uri.parse('$baseUrl/images/generations'),
            headers: _headers(apiKey),
            body: jsonEncode({
              'model': request.model ?? 'gpt-image-1',
              'prompt': request.prompt,
              'n': request.parameters['count'] ?? 1,
              if (request.parameters['size'] != null)
                'size': request.parameters['size'],
            }),
          )
        : await client.post(
            Uri.parse('$baseUrl/responses'),
            headers: _headers(apiKey),
            body: jsonEncode({
              'model': request.model ?? 'gpt-5',
              'input': request.prompt,
            }),
          );
    _check(response);
    final body = jsonDecode(response.body) as Map<String, dynamic>;
    if (request.target == PromptTarget.image) {
      final data = (body['data'] as List<dynamic>? ?? const [])
          .whereType<Map<String, dynamic>>();
      return AiGenerationResult(
        providerRequestId: body['id'] as String? ?? request.jobId,
        outputs: data
            .map(
              (item) => AiGeneratedOutput(
                type: AiOutputType.image,
                remoteUrl: item['url'] as String?,
                mimeType: 'image/png',
              ),
            )
            .toList(growable: false),
      );
    }
    final text = body['output_text'] as String? ?? '';
    return AiGenerationResult(
      providerRequestId: body['id'] as String? ?? request.jobId,
      outputs: [
        AiGeneratedOutput(
          type: AiOutputType.text,
          text: text,
          mimeType: 'text/plain',
        ),
      ],
    );
  }

  void _check(http.Response response) {
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw StateError(
        'OpenAI request failed with HTTP ${response.statusCode}.',
      );
    }
  }
}
