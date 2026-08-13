import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/core/security/credential_store.dart';
import 'package:void_scriptor/features/ai/domain/ai_provider.dart';

void main() {
  test(
    'memory credential store writes reads and deletes without exposing secrets in config',
    () async {
      final store = MemoryCredentialStore();
      await store.write(key: 'ai.openai.api_key', value: 'secret-value');
      expect(await store.read('ai.openai.api_key'), 'secret-value');
      await store.delete('ai.openai.api_key');
      expect(await store.read('ai.openai.api_key'), isNull);
      const config = AiProviderConfig(
        id: 'openai',
        type: AiProviderType.openAi,
        displayName: 'OpenAI',
        enabled: true,
        defaultModel: 'gpt-image-1',
      );
      expect(config.toString(), isNot(contains('secret')));
    },
  );

  test('capability validation rejects unsupported target', () {
    const provider = MockAiProvider();
    expect(
      () => provider.validateTarget(PromptTarget.video),
      throwsUnsupportedError,
    );
    expect(provider.validateTarget(PromptTarget.image), isTrue);
  });

  test('mock provider returns a unified output', () async {
    const provider = MockAiProvider();
    final result = await provider.generate(
      const AiGenerationRequest(
        jobId: 'job-1',
        prompt: 'Qowner portrait',
        target: PromptTarget.image,
      ),
    );
    expect(result.providerRequestId, 'mock-request');
    expect(result.outputs.single.type, AiOutputType.text);
  });
}
