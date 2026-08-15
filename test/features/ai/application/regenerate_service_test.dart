import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/features/ai/domain/ai_provider.dart';
import 'package:void_scriptor/features/ai/domain/ai_streaming.dart';
import 'package:void_scriptor/features/ai/application/regenerate_service.dart';

class _Provider with AiStreamingFallback implements AiProvider {
  final List<String> prompts = [];

  @override
  String get id => 'p';
  @override
  String get displayName => 'p';
  @override
  Set<AiCapability> get capabilities => {AiCapability.textGeneration};
  @override
  Future<List<AiModelInfo>> listModels() async => const [];
  @override
  Future<AiGenerationResult> generate(AiGenerationRequest request) async {
    prompts.add(request.prompt);
    return AiGenerationResult(
      providerRequestId: 'r',
      outputs: [AiGeneratedOutput(type: AiOutputType.text, text: 'new')],
    );
  }

  @override
  Future<void> cancel(String requestId) async {}
  @override
  bool validateTarget(PromptTarget target) => true;
}

void main() {
  test('regenerate appends feedback to the prompt', () async {
    final provider = _Provider();
    final service = RegenerateService(provider);
    final result = await service.regenerate(
      prompt: 'a character in a room',
      feedback: 'make it brighter',
      target: PromptTarget.story,
    );
    expect(result.providerRequestId, 'r');
    expect(provider.prompts.single, contains('make it brighter'));
    expect(provider.prompts.single, contains('a character in a room'));
  });
}
