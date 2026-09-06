import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/features/ai/application/provider_health.dart';
import 'package:void_scriptor/features/ai/domain/ai_provider.dart';
import 'package:void_scriptor/features/ai/domain/ai_streaming.dart';

class _HealthProvider implements AiProvider {
  _HealthProvider({this.failure});

  final Object? failure;

  @override
  String get id => 'health-test';

  @override
  String get displayName => 'Health Test';

  @override
  Set<AiCapability> get capabilities => {AiCapability.textGeneration};

  @override
  Future<List<AiModelInfo>> listModels() async {
    if (failure != null) throw failure!;
    return const [
      AiModelInfo(
        id: 'health-model',
        displayName: 'Health Model',
        capabilities: {AiCapability.textGeneration},
      ),
    ];
  }

  @override
  Future<AiGenerationResult> generate(AiGenerationRequest request) async =>
      const AiGenerationResult(providerRequestId: 'health', outputs: []);

  @override
  Future<void> cancel(String requestId) async {}

  @override
  bool validateTarget(PromptTarget target) => target == PromptTarget.story;

  @override
  Stream<AiStreamingChunk> streamGenerate(AiGenerationRequest request) async* {
    yield const AiStreamingChunk.done();
  }
}

void main() {
  test('health probe reports healthy provider and model count', () async {
    final result = await AiProviderHealthProbe(
      _HealthProvider(),
      now: () => DateTime.utc(2026, 8, 21),
    ).check();

    expect(result.status, AiProviderHealthStatus.healthy);
    expect(result.providerId, 'health-test');
    expect(result.modelCount, 1);
    expect(result.errorMessage, isNull);
    expect(result.checkedAt, DateTime.utc(2026, 8, 21));
  });

  test(
    'health probe reports unavailable provider without leaking error object',
    () async {
      final result = await AiProviderHealthProbe(
        _HealthProvider(failure: StateError('secret endpoint details')),
        now: () => DateTime.utc(2026, 8, 21),
      ).check();

      expect(result.status, AiProviderHealthStatus.unavailable);
      expect(result.modelCount, 0);
      expect(result.errorMessage, 'Provider health probe failed.');
      expect(result.errorMessage, isNot(contains('secret')));
    },
  );
}
