import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/features/ai/domain/ai_provider.dart';
import 'package:void_scriptor/features/ai/application/provider_router.dart';

class _PricedProvider extends _BaseProvider {
  _PricedProvider(super.id, super.capabilities, this.cost);
  final double cost;
}

class _BaseProvider with AiStreamingFallback implements AiProvider {
  _BaseProvider(this.id, this.capabilities);
  @override
  final String id;
  @override
  final Set<AiCapability> capabilities;
  double get costPerOutput => 0;

  @override
  String get displayName => id;
  @override
  Future<List<AiModelInfo>> listModels() async => const [];
  @override
  Future<AiGenerationResult> generate(AiGenerationRequest request) async =>
      const AiGenerationResult(
        providerRequestId: 'r',
        outputs: [AiGeneratedOutput(type: AiOutputType.text, text: 'x')],
      );
  @override
  Future<void> cancel(String requestId) async {}
  @override
  bool validateTarget(PromptTarget target) {
    final required = target == PromptTarget.story
        ? AiCapability.textGeneration
        : AiCapability.imageGeneration;
    return capabilities.contains(required);
  }
}

void main() {
  test('resolveCheapest picks the lowest-cost capable provider', () {
    final router = ProviderRouter([
      _PricedProvider('expensive', {AiCapability.textGeneration}, 1.0),
      _PricedProvider('cheap', {AiCapability.textGeneration}, 0.1),
    ]);
    final cheapest = router.resolveCheapest(
      PromptTarget.story,
      costOf: (p) => (p as _PricedProvider).cost,
    );
    expect(cheapest?.id, 'cheap');
  });

  test('resolveCheapest returns null when none capable', () {
    final router = ProviderRouter([
      _PricedProvider('img', {AiCapability.imageGeneration}, 0.1),
    ]);
    expect(
      router.resolveCheapest(
        PromptTarget.story,
        costOf: (p) => (p as _PricedProvider).cost,
      ),
      isNull,
    );
  });
}
