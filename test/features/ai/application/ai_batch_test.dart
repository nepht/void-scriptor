import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/features/ai/domain/ai_provider.dart';
import 'package:void_scriptor/features/ai/application/ai_batch.dart';

class _Provider with AiStreamingFallback implements AiProvider {
  _Provider({this.failIndex = -1});
  final int failIndex;
  int callCount = 0;

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
    final index = callCount++;
    if (index == failIndex) {
      throw StateError('fail');
    }
    return AiGenerationResult(
      providerRequestId: 'r$index',
      outputs: [AiGeneratedOutput(type: AiOutputType.text, text: 'out$index')],
    );
  }

  @override
  Future<void> cancel(String requestId) async {}
  @override
  bool validateTarget(PromptTarget target) => true;
}

void main() {
  test('AiBatchItem carries prompt and target', () {
    const item = AiBatchItem(prompt: 'hello', target: PromptTarget.story);
    expect(item.prompt, 'hello');
    expect(item.target, PromptTarget.story);
  });

  test('executor runs items with bounded concurrency', () async {
    final provider = _Provider();
    final executor = AiBatchExecutor(provider: provider, maxConcurrent: 2);
    final results = await executor.run(const [
      AiBatchItem(prompt: 'a', target: PromptTarget.story),
      AiBatchItem(prompt: 'b', target: PromptTarget.story),
      AiBatchItem(prompt: 'c', target: PromptTarget.story),
    ]);
    expect(results, hasLength(3));
    expect(results.where((r) => r.success), hasLength(3));
  });

  test('executor reports partial failure', () async {
    final provider = _Provider(failIndex: 1);
    final executor = AiBatchExecutor(provider: provider, maxConcurrent: 2);
    final results = await executor.run(const [
      AiBatchItem(prompt: 'a', target: PromptTarget.story),
      AiBatchItem(prompt: 'b', target: PromptTarget.story),
      AiBatchItem(prompt: 'c', target: PromptTarget.story),
    ]);
    expect(results.where((r) => r.success), hasLength(2));
    expect(results.where((r) => !r.success), hasLength(1));
  });
}
