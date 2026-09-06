import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/core/security/credential_store.dart';
import 'package:void_scriptor/features/ai/domain/ai_provider.dart';
import 'package:void_scriptor/features/ai/domain/prompt_preset.dart';
import 'package:void_scriptor/features/ai/infrastructure/providers/openai/openai_provider.dart';

class _Client implements OpenAiClient {
  AiGenerationRequest? request;
  String? apiKey;

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
      providerRequestId: 'vision-request',
      outputs: [AiGeneratedOutput(type: AiOutputType.text, text: 'ok')],
    );
  }
}

void main() {
  test(
    'vision-capable provider forwards reference images without leaking config',
    () async {
      final client = _Client();
      final credentials = MemoryCredentialStore();
      await credentials.write(
        key: OpenAiProvider.credentialKey,
        value: '[REDACTED]',
      );
      final provider = OpenAiProvider(
        credentialStore: credentials,
        client: client,
      );

      const request = AiGenerationRequest(
        jobId: 'vision-job',
        prompt: 'describe the reference',
        target: PromptTarget.image,
        referenceImages: [
          AiReferenceImage(
            path: 'assets/reference.png',
            role: 'reference',
            priority: 1,
          ),
        ],
      );
      await provider.generate(request);

      expect(provider.capabilities, contains(AiCapability.visionInput));
      expect(
        client.request?.referenceImages.single.path,
        'assets/reference.png',
      );
      expect(client.request?.parameters.containsValue('[REDACTED]'), isFalse);
      expect(client.apiKey, '[REDACTED]');
    },
  );
}
