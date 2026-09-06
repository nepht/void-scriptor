import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/core/security/credential_store.dart';
import 'package:void_scriptor/features/ai/domain/ai_provider.dart';
import 'package:void_scriptor/features/ai/infrastructure/providers/comfyui/comfyui_provider.dart';
import 'package:void_scriptor/features/ai/infrastructure/providers/openai/openai_provider.dart';

void main() {
  const request = AiGenerationRequest(
    jobId: 'image-contract-job',
    prompt: 'A cinematic void landscape.',
    target: PromptTarget.image,
    model: 'image-model',
  );

  test('OpenAI forwards image credential and request to its client', () async {
    final client = _OpenAiClient();
    final credentials = MemoryCredentialStore();
    await credentials.write(
      key: OpenAiProvider.credentialKey,
      value: 'openai-image-credential',
    );
    final provider = OpenAiProvider(
      credentialStore: credentials,
      client: client,
    );

    final result = await provider.generate(request);

    expect(result.providerRequestId, 'openai-image-request');
    expect(client.apiKey, 'openai-image-credential');
    expect(client.request, same(request));
  });

  test('ComfyUI forwards image base URL and request to its client', () async {
    final client = _ComfyClient();
    final provider = ComfyUiProvider(
      client: client,
      baseUrl: 'http://comfyui.test:8188',
    );

    final result = await provider.generate(request);

    expect(result.providerRequestId, 'comfyui-image-request');
    expect(client.baseUrl, 'http://comfyui.test:8188');
    expect(client.request, same(request));
  });
}

class _OpenAiClient implements OpenAiClient {
  String? apiKey;
  AiGenerationRequest? request;

  @override
  Future<List<AiModelInfo>> listModels({required String apiKey}) async =>
      const [];

  @override
  Future<AiGenerationResult> generate({
    required String apiKey,
    required AiGenerationRequest request,
  }) async {
    this.apiKey = apiKey;
    this.request = request;
    return const AiGenerationResult(
      providerRequestId: 'openai-image-request',
      outputs: [AiGeneratedOutput(type: AiOutputType.image)],
    );
  }
}

class _ComfyClient implements ComfyUiClient {
  String? baseUrl;
  AiGenerationRequest? request;

  @override
  Future<List<AiModelInfo>> listModels({required String baseUrl}) async =>
      const [];

  @override
  Future<AiGenerationResult> generate({
    required String baseUrl,
    required AiGenerationRequest request,
  }) async {
    this.baseUrl = baseUrl;
    this.request = request;
    return const AiGenerationResult(
      providerRequestId: 'comfyui-image-request',
      outputs: [AiGeneratedOutput(type: AiOutputType.image)],
    );
  }

  @override
  Future<void> cancel({
    required String baseUrl,
    required String requestId,
  }) async {}
}
