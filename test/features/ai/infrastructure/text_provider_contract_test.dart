import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/core/security/credential_store.dart';
import 'package:void_scriptor/features/ai/domain/ai_provider.dart';
import 'package:void_scriptor/features/ai/infrastructure/providers/gemini/gemini_provider.dart';
import 'package:void_scriptor/features/ai/infrastructure/providers/ollama/ollama_provider.dart';
import 'package:void_scriptor/features/ai/infrastructure/providers/openai/openai_provider.dart';

void main() {
  test('OpenAI accepts text and rejects unsupported video before I/O', () {
    final provider = OpenAiProvider(
      credentialStore: MemoryCredentialStore(),
      client: _OpenAiClient(),
    );

    expect(provider.validateTarget(PromptTarget.story), isTrue);
    expect(
      () => provider.validateTarget(PromptTarget.video),
      throwsUnsupportedError,
    );
  });

  test('Gemini accepts text and rejects unsupported video before I/O', () {
    final provider = GeminiProvider(
      credentialStore: MemoryCredentialStore(),
      client: _GeminiClient(),
    );

    expect(provider.validateTarget(PromptTarget.story), isTrue);
    expect(
      () => provider.validateTarget(PromptTarget.video),
      throwsUnsupportedError,
    );
  });

  test('Ollama accepts all non-media text targets only', () {
    final provider = OllamaProvider(client: _OllamaClient());

    expect(provider.validateTarget(PromptTarget.story), isTrue);
    expect(provider.validateTarget(PromptTarget.dialogue), isTrue);
    expect(
      () => provider.validateTarget(PromptTarget.image),
      throwsUnsupportedError,
    );
    expect(
      () => provider.validateTarget(PromptTarget.audio),
      throwsUnsupportedError,
    );
  });
}

class _OpenAiClient implements OpenAiClient {
  @override
  Future<AiGenerationResult> generate({
    required String apiKey,
    required AiGenerationRequest request,
  }) async =>
      const AiGenerationResult(providerRequestId: 'unused', outputs: []);

  @override
  Future<List<AiModelInfo>> listModels({required String apiKey}) async =>
      const [];
}

class _GeminiClient implements GeminiClient {
  @override
  Future<AiGenerationResult> generate({
    required String apiKey,
    required AiGenerationRequest request,
  }) async =>
      const AiGenerationResult(providerRequestId: 'unused', outputs: []);

  @override
  Future<List<AiModelInfo>> listModels({required String apiKey}) async =>
      const [];
}

class _OllamaClient implements OllamaClient {
  @override
  Future<AiGenerationResult> generate({
    required String baseUrl,
    required AiGenerationRequest request,
  }) async =>
      const AiGenerationResult(providerRequestId: 'unused', outputs: []);

  @override
  Future<List<AiModelInfo>> listModels({required String baseUrl}) async =>
      const [];
}
