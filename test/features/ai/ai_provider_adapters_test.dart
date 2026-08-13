import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/core/security/credential_store.dart';
import 'package:void_scriptor/features/ai/domain/ai_provider.dart';
import 'package:void_scriptor/features/ai/infrastructure/providers/openai/openai_provider.dart';

void main() {
  test(
    'OpenAI adapter requires secure credential before client call',
    () async {
      final client = FakeOpenAiClient();
      final provider = OpenAiProvider(
        credentialStore: MemoryCredentialStore(),
        client: client,
      );
      expect(
        () => provider.generate(
          const AiGenerationRequest(
            jobId: 'j1',
            prompt: 'portrait',
            target: PromptTarget.image,
          ),
        ),
        throwsStateError,
      );
      expect(client.calls, 0);
    },
  );

  test(
    'OpenAI adapter maps unified image request to client and returns outputs',
    () async {
      final store = MemoryCredentialStore();
      await store.write(
        key: 'ai.openai.api_key',
        value: 'redacted-test-secret',
      );
      final client = FakeOpenAiClient();
      final provider = OpenAiProvider(credentialStore: store, client: client);
      final result = await provider.generate(
        const AiGenerationRequest(
          jobId: 'j1',
          prompt: 'portrait',
          target: PromptTarget.image,
          model: 'gpt-image-1',
        ),
      );
      expect(client.calls, 1);
      expect(client.lastApiKey, 'redacted-test-secret');
      expect(client.lastRequest?.model, 'gpt-image-1');
      expect(
        result.outputs.single.remoteUrl,
        'https://example.invalid/output.png',
      );
    },
  );
}

class FakeOpenAiClient implements OpenAiClient {
  int calls = 0;
  String? lastApiKey;
  AiGenerationRequest? lastRequest;
  @override
  Future<AiGenerationResult> generate({
    required String apiKey,
    required AiGenerationRequest request,
  }) async {
    calls++;
    lastApiKey = apiKey;
    lastRequest = request;
    return const AiGenerationResult(
      providerRequestId: 'openai-request',
      outputs: [
        AiGeneratedOutput(
          type: AiOutputType.image,
          remoteUrl: 'https://example.invalid/output.png',
          mimeType: 'image/png',
        ),
      ],
    );
  }

  @override
  Future<List<AiModelInfo>> listModels({required String apiKey}) async =>
      const [];
}
