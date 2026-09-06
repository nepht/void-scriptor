import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/features/ai/domain/ai_provider.dart';
import 'package:void_scriptor/features/ai/infrastructure/providers/ollama/ollama_provider.dart';

class _Client implements OllamaClient {
  @override
  Future<List<AiModelInfo>> listModels({required String baseUrl}) async =>
      const [];

  @override
  Future<AiGenerationResult> generate({
    required String baseUrl,
    required AiGenerationRequest request,
  }) async => const AiGenerationResult(
    providerRequestId: 'text-request',
    outputs: [AiGeneratedOutput(type: AiOutputType.text, text: 'ok')],
  );
}

void main() {
  test('text provider accepts story and dialogue targets', () {
    final provider = OllamaProvider(client: _Client());

    expect(provider.validateTarget(PromptTarget.story), isTrue);
    expect(provider.validateTarget(PromptTarget.dialogue), isTrue);
  });

  test('text provider rejects image target', () {
    final provider = OllamaProvider(client: _Client());

    expect(
      () => provider.validateTarget(PromptTarget.image),
      throwsUnsupportedError,
    );
  });
}
