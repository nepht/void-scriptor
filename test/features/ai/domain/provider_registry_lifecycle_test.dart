import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/features/ai/domain/ai_provider.dart';

void main() {
  test(
    'registry preserves insertion order and exposes an immutable snapshot',
    () {
      const first = MockAiProvider();
      final second = _Provider('second');
      final registry = AiProviderRegistry([first, second]);

      expect(registry.all.map((provider) => provider.id), ['mock', 'second']);
      expect(registry.get('second'), same(second));
      expect(registry.require('mock'), same(first));
      expect(() => registry.all.add(first), throwsUnsupportedError);
    },
  );
}

class _Provider with AiStreamingFallback implements AiProvider {
  _Provider(this.id);

  @override
  final String id;
  @override
  String get displayName => id;
  @override
  Set<AiCapability> get capabilities => {AiCapability.textGeneration};
  @override
  Future<List<AiModelInfo>> listModels() async => const [];
  @override
  Future<AiGenerationResult> generate(AiGenerationRequest request) async =>
      const AiGenerationResult(providerRequestId: 'request', outputs: []);
  @override
  Future<void> cancel(String requestId) async {}
  @override
  bool validateTarget(PromptTarget target) => target == PromptTarget.story;
}
