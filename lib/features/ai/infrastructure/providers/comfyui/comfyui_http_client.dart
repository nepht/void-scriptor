import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../../domain/ai_provider.dart';
import 'comfyui_provider.dart';

class HttpComfyUiClient implements ComfyUiClient {
  HttpComfyUiClient({http.Client? client}) : client = client ?? http.Client();
  final http.Client client;
  @override
  Future<List<AiModelInfo>> listModels({required String baseUrl}) async =>
      const [];
  @override
  Future<AiGenerationResult> generate({
    required String baseUrl,
    required AiGenerationRequest request,
  }) async {
    final workflow = request.parameters['workflow'];
    if (workflow is! Map<String, Object?>) {
      throw ArgumentError(
        'ComfyUI requires a workflow map in request.parameters[workflow].',
      );
    }
    final response = await client.post(
      Uri.parse('$baseUrl/prompt'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'prompt': workflow}),
    );
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw StateError(
        'ComfyUI request failed with HTTP ${response.statusCode}.',
      );
    }
    final body = jsonDecode(response.body) as Map<String, dynamic>;
    return AiGenerationResult(
      providerRequestId: body['prompt_id'] as String? ?? request.jobId,
      outputs: const [],
    );
  }

  @override
  Future<void> cancel({
    required String baseUrl,
    required String requestId,
  }) async {
    await client.post(
      Uri.parse('$baseUrl/interrupt'),
      headers: {'Content-Type': 'application/json'},
      body: '{}',
    );
  }
}
