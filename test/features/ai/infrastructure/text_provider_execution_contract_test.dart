import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/core/security/credential_store.dart';
import 'package:void_scriptor/features/ai/domain/ai_provider.dart';
import 'package:void_scriptor/features/ai/infrastructure/providers/gemini/gemini_provider.dart';
import 'package:void_scriptor/features/ai/infrastructure/providers/ollama/ollama_provider.dart';
import 'package:void_scriptor/features/ai/infrastructure/providers/openai/openai_provider.dart';

void main() {
  const request = AiGenerationRequest(
    jobId: 'text-contract-job',
    prompt: 'Write a short scene.',
    target: PromptTarget.story,
    model: 'text-model',
  );

  test('OpenAI forwards credential and request to its client', () async {
    final client = _OpenAiClient();
    final credentials = MemoryCredentialStore();
    await credentials.write(
      key: OpenAiProvider.credentialKey,
      value: 'openai-test-credential',
    );
    final provider = OpenAiProvider(
      credentialStore: credentials,
      client: client,
    );

    final result = await provider.generate(request);

    expect(result.providerRequestId, 'openai-request');
    expect(client.apiKey, 'openai-test-credential');
    expect(client.request, same(request));
  });

  test('Gemini forwards credential and request to its client', () async {
    final client = _GeminiClient();
    final credentials = MemoryCredentialStore();
    await credentials.write(
      key: GeminiProvider.credentialKey,
      value: 'gemini-test-credential',
    );
    final provider = GeminiProvider(
      credentialStore: credentials,
      client: client,
    );

    final result = await provider.generate(request);

    expect(result.providerRequestId, 'gemini-request');
    expect(client.apiKey, 'gemini-test-credential');
    expect(client.request, same(request));
  });

  test('Ollama forwards base URL and request to its client', () async {
    final client = _OllamaClient();
    final provider = OllamaProvider(
      client: client,
      baseUrl: 'http://ollama.test:11434',
    );

    final result = await provider.generate(request);

    expect(result.providerRequestId, 'ollama-request');
    expect(client.baseUrl, 'http://ollama.test:11434');
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
      providerRequestId: 'openai-request',
      outputs: [],
    );
  }
}

class _GeminiClient implements GeminiClient {
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
      providerRequestId: 'gemini-request',
      outputs: [],
    );
  }
}

class _OllamaClient implements OllamaClient {
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
      providerRequestId: 'ollama-request',
      outputs: [],
    );
  }
}
