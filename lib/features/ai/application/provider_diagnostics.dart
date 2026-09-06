import '../domain/ai_provider.dart';
import 'provider_health.dart';

class AiProviderDiagnosticsReport {
  const AiProviderDiagnosticsReport({
    required this.providerId,
    required this.displayName,
    required this.capabilities,
    required this.health,
    required this.modelCount,
    required this.credentialConfigured,
  });

  final String providerId;
  final String displayName;
  final Set<AiCapability> capabilities;
  final AiProviderHealth health;
  final int modelCount;
  final bool credentialConfigured;

  Map<String, Object?> toSafeMap() => {
    'providerId': providerId,
    'displayName': displayName,
    'capabilities': capabilities.map((value) => value.name).toList(),
    'health': health.status.name,
    'modelCount': modelCount,
    'credentialConfigured': credentialConfigured,
  };
}

class AiProviderDiagnostics {
  const AiProviderDiagnostics(this.health);

  final AiProviderHealth health;

  AiProviderDiagnosticsReport build({
    required AiProvider provider,
    required bool credentialConfigured,
  }) => AiProviderDiagnosticsReport(
    providerId: provider.id,
    displayName: provider.displayName,
    capabilities: Set.unmodifiable(provider.capabilities),
    health: health,
    modelCount: health.modelCount,
    credentialConfigured: credentialConfigured,
  );
}
