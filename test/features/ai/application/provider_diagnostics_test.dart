import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/features/ai/application/provider_diagnostics.dart';
import 'package:void_scriptor/features/ai/application/provider_health.dart';
import 'package:void_scriptor/features/ai/domain/ai_provider.dart';
import 'package:void_scriptor/features/ai/domain/ai_streaming.dart';

class _DiagnosticProvider implements AiProvider {
  @override
  String get id => 'diagnostic';
  @override
  String get displayName => 'Diagnostic Provider';
  @override
  Set<AiCapability> get capabilities => {AiCapability.textGeneration};
  @override
  Future<List<AiModelInfo>> listModels() async => const [
    AiModelInfo(
      id: 'model',
      displayName: 'Model',
      capabilities: {AiCapability.textGeneration},
    ),
  ];
  @override
  Future<AiGenerationResult> generate(AiGenerationRequest request) async =>
      const AiGenerationResult(providerRequestId: 'id', outputs: []);
  @override
  Future<void> cancel(String requestId) async {}
  @override
  bool validateTarget(PromptTarget target) => target == PromptTarget.story;
  @override
  Stream<AiStreamingChunk> streamGenerate(AiGenerationRequest request) =>
      const Stream<AiStreamingChunk>.empty();
}

void main() {
  test(
    'diagnostics report contains safe provider facts and no credential value',
    () async {
      final health = await AiProviderHealthProbe(
        _DiagnosticProvider(),
        now: () => DateTime.utc(2026, 8, 21),
      ).check();
      final report = AiProviderDiagnostics(
        health,
      ).build(provider: _DiagnosticProvider(), credentialConfigured: true);

      expect(report.providerId, 'diagnostic');
      expect(report.credentialConfigured, isTrue);
      expect(report.modelCount, 1);
      expect(report.capabilities, contains(AiCapability.textGeneration));
      expect(report.toSafeMap(), isNot(contains('credential')));
    },
  );
}
