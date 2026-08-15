import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/features/ai/application/target_defaults.dart';
import 'package:void_scriptor/features/ai/domain/prompt_target.dart';

void main() {
  const defaults = TargetDefaults();

  test('has a sensible default provider for every target', () {
    for (final target in PromptTarget.values) {
      final entry = defaults.defaultFor(target);
      expect(entry, isNotNull, reason: 'missing default for $target');
    }
  });

  test('text targets prefer text-capable providers', () {
    expect(defaults.defaultFor(PromptTarget.story)?.providerId, 'openai');
  });

  test('image targets prefer image-capable providers', () {
    expect(defaults.defaultFor(PromptTarget.image)?.providerId, 'openai');
  });

  test('can override default provider for a target', () {
    final defaults = TargetDefaults(overrides: {
      PromptTarget.story: const ProviderModelChoice(
        providerId: 'ollama',
        modelId: 'llama3',
      ),
    });
    expect(defaults.defaultFor(PromptTarget.story)?.providerId, 'ollama');
    expect(defaults.defaultFor(PromptTarget.story)?.modelId, 'llama3');
  });
}
