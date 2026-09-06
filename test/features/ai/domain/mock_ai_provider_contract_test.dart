import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/features/ai/domain/ai_provider.dart';

void main() {
  const provider = MockAiProvider();

  test('fake provider exposes models for every declared capability', () async {
    final models = await provider.listModels();
    final modelCapabilities = models
        .expand((model) => model.capabilities)
        .toSet();

    expect(modelCapabilities, contains(AiCapability.textGeneration));
    expect(modelCapabilities, contains(AiCapability.imageGeneration));
  });

  test('fake provider returns output matching the requested target', () async {
    final image = await provider.generate(
      const AiGenerationRequest(
        jobId: 'fake-image',
        prompt: 'void landscape',
        target: PromptTarget.image,
      ),
    );
    final text = await provider.generate(
      const AiGenerationRequest(
        jobId: 'fake-text',
        prompt: 'scene summary',
        target: PromptTarget.story,
      ),
    );

    expect(image.outputs.single.type, AiOutputType.image);
    expect(text.outputs.single.type, AiOutputType.text);
  });
}
