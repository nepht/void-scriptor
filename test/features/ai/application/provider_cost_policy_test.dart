import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/features/ai/application/provider_cost_policy.dart';
import 'package:void_scriptor/features/ai/domain/ai_provider.dart';

class _CostProvider with AiStreamingFallback implements AiProvider {
  _CostProvider(this.id, this.cost);

  @override
  final String id;
  final double cost;

  @override
  String get displayName => id;

  @override
  Set<AiCapability> get capabilities => {AiCapability.textGeneration};

  @override
  Future<List<AiModelInfo>> listModels() async => const [];

  @override
  Future<AiGenerationResult> generate(AiGenerationRequest request) async =>
      AiGenerationResult(providerRequestId: id, outputs: const []);

  @override
  Future<void> cancel(String requestId) async {}

  @override
  bool validateTarget(PromptTarget target) => target == PromptTarget.story;
}

void main() {
  test('cost policy selects cheapest capable provider', () {
    final expensive = _CostProvider('expensive', 1.0);
    final cheap = _CostProvider('cheap', 0.1);
    final policy = AiProviderCostPolicy({
      expensive: expensive.cost,
      cheap: cheap.cost,
    });

    expect(policy.resolve(PromptTarget.story)?.id, 'cheap');
  });

  test('cost policy rejects negative and non-finite prices', () {
    expect(
      () => AiProviderCostPolicy({_CostProvider('bad', -1): -1}),
      throwsArgumentError,
    );
    expect(
      () =>
          AiProviderCostPolicy({_CostProvider('nan', double.nan): double.nan}),
      throwsArgumentError,
    );
  });
}
