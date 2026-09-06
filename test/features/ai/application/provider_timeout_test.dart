import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/features/ai/application/provider_timeout.dart';
import 'package:void_scriptor/features/ai/domain/ai_provider.dart';

class _SlowProvider with AiStreamingFallback implements AiProvider {
  _SlowProvider(this.delay);
  final Duration delay;

  @override
  String get id => 'slow';
  @override
  String get displayName => 'Slow';
  @override
  Set<AiCapability> get capabilities => {AiCapability.textGeneration};
  @override
  Future<List<AiModelInfo>> listModels() async {
    await Future<void>.delayed(delay);
    return const [];
  }

  @override
  Future<AiGenerationResult> generate(AiGenerationRequest request) async {
    await Future<void>.delayed(delay);
    return const AiGenerationResult(providerRequestId: 'slow', outputs: []);
  }

  @override
  Future<void> cancel(String requestId) async {}
  @override
  bool validateTarget(PromptTarget target) => target == PromptTarget.story;
}

void main() {
  test(
    'timeout wrapper fails generation with safe timeout exception',
    () async {
      final provider = AiProviderWithTimeout(
        _SlowProvider(const Duration(milliseconds: 50)),
        timeout: const Duration(milliseconds: 1),
      );

      await expectLater(
        provider.generate(
          const AiGenerationRequest(
            jobId: 'timeout',
            prompt: 'test',
            target: PromptTarget.story,
          ),
        ),
        throwsA(isA<AiProviderTimeoutException>()),
      );
    },
  );

  test('timeout wrapper preserves successful operations', () async {
    final provider = AiProviderWithTimeout(
      _SlowProvider(Duration.zero),
      timeout: const Duration(seconds: 1),
    );

    expect(await provider.listModels(), isEmpty);
  });
}
