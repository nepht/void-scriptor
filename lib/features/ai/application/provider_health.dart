import '../domain/ai_provider.dart';

/// Coarse provider availability derived from an executable model-list probe.
enum AiProviderHealthStatus { healthy, degraded, unavailable }

class AiProviderHealth {
  const AiProviderHealth({
    required this.providerId,
    required this.status,
    required this.checkedAt,
    required this.modelCount,
    this.latency,
    this.errorMessage,
  });

  final String providerId;
  final AiProviderHealthStatus status;
  final DateTime checkedAt;
  final int modelCount;
  final Duration? latency;
  final String? errorMessage;
}

class AiProviderHealthProbe {
  AiProviderHealthProbe(this.provider, {DateTime Function()? now})
    : _now = now ?? DateTime.now;

  final AiProvider provider;
  final DateTime Function() _now;

  Future<AiProviderHealth> check() async {
    final started = _now();
    try {
      final models = await provider.listModels();
      final finished = _now();
      return AiProviderHealth(
        providerId: provider.id,
        status: models.isEmpty
            ? AiProviderHealthStatus.degraded
            : AiProviderHealthStatus.healthy,
        checkedAt: finished,
        modelCount: models.length,
        latency: finished.difference(started),
      );
    } catch (_) {
      final finished = _now();
      return AiProviderHealth(
        providerId: provider.id,
        status: AiProviderHealthStatus.unavailable,
        checkedAt: finished,
        modelCount: 0,
        latency: finished.difference(started),
        errorMessage: 'Provider health probe failed.',
      );
    }
  }
}
