import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/features/ai/domain/ai_provider.dart';
import 'package:void_scriptor/features/ai/domain/ai_streaming.dart';
import 'package:void_scriptor/features/ai/application/provider_router.dart';

class _Provider with AiStreamingFallback implements AiProvider {
  _Provider({required this.id, required this.capabilities, this.failTimes = 0});
  @override
  final String id;
  @override
  final Set<AiCapability> capabilities;
  int failTimes;

  @override
  String get displayName => id;
  @override
  Future<List<AiModelInfo>> listModels() async => const [];
  @override
  Future<AiGenerationResult> generate(AiGenerationRequest request) async {
    if (failTimes > 0) {
      failTimes--;
      throw StateError('transient failure');
    }
    return AiGenerationResult(
      providerRequestId: '$id-r',
      outputs: [AiGeneratedOutput(type: AiOutputType.text, text: '$id out')],
    );
  }

  @override
  Future<void> cancel(String requestId) async {}
  @override
  bool validateTarget(PromptTarget target) {
    final required = switch (target) {
      PromptTarget.video => AiCapability.videoGeneration,
      PromptTarget.story => AiCapability.textGeneration,
      PromptTarget.vfx || PromptTarget.audio => AiCapability.audioGeneration,
      PromptTarget.dialogue => AiCapability.voiceGeneration,
      _ => AiCapability.imageGeneration,
    };
    return capabilities.contains(required);
  }

  @override
  Stream<AiStreamingChunk> streamGenerate(AiGenerationRequest request) async* {
    yield AiStreamingChunk.text('$id out');
    yield const AiStreamingChunk.done();
  }
}

void main() {
  test('routes to the best capable provider', () {
    final router = ProviderRouter([
      _Provider(id: 'text-only', capabilities: {AiCapability.textGeneration}),
      _Provider(id: 'image', capabilities: {AiCapability.imageGeneration}),
    ]);
    expect(router.resolve(PromptTarget.image)?.id, 'image');
    expect(router.resolve(PromptTarget.story)?.id, 'text-only');
  });

  test('returns null when no provider can serve the target', () {
    final router = ProviderRouter([
      _Provider(id: 'text', capabilities: {AiCapability.textGeneration}),
    ]);
    expect(router.resolve(PromptTarget.video), isNull);
  });

  test('falls back to next provider on failure', () async {
    final primary = _Provider(
      id: 'primary',
      capabilities: {AiCapability.textGeneration},
      failTimes: 1,
    );
    final fallback = _Provider(
      id: 'fallback',
      capabilities: {AiCapability.textGeneration},
    );
    final router = ProviderRouter([primary, fallback]);
    final result = await router.generateWithFallback(
      const AiGenerationRequest(
        jobId: 'j',
        prompt: 'p',
        target: PromptTarget.story,
      ),
      preferred: 'primary',
    );
    expect(result.providerRequestId, 'fallback-r');
  });

  test('throws when all providers fail', () async {
    final router = ProviderRouter([
      _Provider(
        id: 'a',
        capabilities: {AiCapability.textGeneration},
        failTimes: 1,
      ),
    ]);
    expect(
      () => router.generateWithFallback(
        const AiGenerationRequest(
          jobId: 'j',
          prompt: 'p',
          target: PromptTarget.story,
        ),
        preferred: 'a',
      ),
      throwsStateError,
    );
  });
}
