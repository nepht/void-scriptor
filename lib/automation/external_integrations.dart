library;

import '../core/plugin/domain/plugin_manifest.dart';
import '../features/ai/application/provider_router.dart';
import '../features/ai/domain/ai_provider.dart';
import 'automation_rule.dart';

/// Sprint 104 / 104.14–104.20 — external workflow integrations over the
/// canonical infrastructure. Nothing here creates a second router, queue,
/// or store; each adapter wraps an existing subsystem and enforces its
/// sprint contract:
///
/// * 104.14 AI: generation goes through [ProviderRouter] (no direct
///   provider bypass), cost is surfaced per call, external-transfer
///   consent is checked BEFORE any provider call, and cancellation
///   delegates to `AiProvider.cancel`.
/// * 104.15 Render: jobs are described with the canonical
///   [WorkflowRenderRequest] vocabulary and carry a mandatory resource
///   budget plus output provenance fields.
/// * 104.16 Publishing: destinations must be on an explicit allowlist,
///   human confirmation defaults to REQUIRED, every decision is audited.
/// * 104.17 Plugin steps: plugin apiVersion major MUST equal 1, declared
///   capabilities are checked, uninstall behaviour is explicit.
/// * 104.18 Capability preflight: missing capabilities are VISIBLE
///   results, never silent fallbacks.
/// * 104.19 Secret references: plaintext secrets are structurally
///   impossible; only store references travel, and redaction is a method.
/// * 104.20 Network policy: deny-by-default destination gating with an
///   audit record for every request decision.

// ---------------------------------------------------------------------------
// 104.14 — AI provider integration
// ---------------------------------------------------------------------------

class AiWorkflowIntegration {
  AiWorkflowIntegration({
    required this.router,
    required this.externalTransferCheck,
    void Function(String providerId, double cost)? onCost,
    this.costOf,
  }) : onCost = onCost ?? ((_, __) {});

  final ProviderRouter router;
  final Future<bool> Function() externalTransferCheck;
  final void Function(String providerId, double cost) onCost;
  final double Function(Object provider)? costOf;

  /// Runs one AI generation for [rule]. Throws [StateError] when the
  /// external transfer check refuses (fail-closed) or no provider can
  /// serve the target (router contract).
  Future<AiGenerationResult> run(
    AutomationRule rule,
    AiGenerationRequest request, {
    String? preferredProviderId,
  }) async {
    if (!await externalTransferCheck()) {
      throw StateError(
        'external transfer refused by policy before any provider call',
      );
    }
    final result = await router.generateWithFallback(
      request,
      preferred: preferredProviderId,
    );
    // Cost visibility: surface a (possibly zero) cost per provider call.
    onCost(preferredProviderId ?? 'auto', _estimateCost(result));
    return result;
  }

  double _estimateCost(AiGenerationResult result) {
    // Canonical hook point for per-provider pricing; zero until a price
    // table is configured (never silently hidden).
    return 0;
  }

  /// Cancellation delegates to the provider's canonical cancel API.
  Future<void> cancel(AiProvider provider, String requestId) =>
      provider.cancel(requestId);
}

// ---------------------------------------------------------------------------
// 104.15 — render pipeline integration
// ---------------------------------------------------------------------------

class WorkflowRenderRequest {
  const WorkflowRenderRequest({
    required this.ruleId,
    required this.cinematicId,
    required this.presetId,
    required this.resourceBudget,
    required this.outputProvenance,
  });

  final String ruleId;
  final String cinematicId;
  final String presetId;

  /// Mandatory budget descriptor (cpu/disk/gpu minutes) — renders without
  /// an explicit budget are rejected.
  final Map<String, int> resourceBudget;

  /// Provenance recorded with outputs: rule + trigger identity.
  final Map<String, String> outputProvenance;
}

class RenderBudgetException implements Exception {
  RenderBudgetException(this.detail);
  final String detail;
  @override
  String toString() => 'RenderBudgetException: $detail';
}

RenderQueueJobDescriptor describeRenderJob(WorkflowRenderRequest request) {
  if (request.resourceBudget.isEmpty) {
    throw RenderBudgetException('resource budget is required');
  }
  return RenderQueueJobDescriptor(
    cinematicId: request.cinematicId,
    presetId: request.presetId,
    resourceBudget: Map.of(request.resourceBudget),
    outputProvenance: Map.of(request.outputProvenance),
  );
}

class RenderQueueJobDescriptor {
  const RenderQueueJobDescriptor({
    required this.cinematicId,
    required this.presetId,
    required this.resourceBudget,
    required this.outputProvenance,
  });

  final String cinematicId;
  final String presetId;
  final Map<String, int> resourceBudget;
  final Map<String, String> outputProvenance;
}

// ---------------------------------------------------------------------------
// 104.16 — publishing integration
// ---------------------------------------------------------------------------

enum PublishConfirmation { notRequired, required }

class PublishingWorkflowAdapter {
  const PublishingWorkflowAdapter({required this.allowedDestinations});

  /// Explicit allowlist; anything else is denied regardless of settings.
  final Set<String> allowedDestinations;

  bool isDestinationAllowed(String destination) =>
      allowedDestinations.contains(destination);

  /// Human confirmation is the DEFAULT; callers must opt out explicitly.
  PublishConfirmation defaultConfirmation(String destination) =>
      PublishConfirmation.required;

  /// Audit record for a publish attempt (identifier-only).
  Map<String, Object> auditRecord({
    required String ruleId,
    required String destination,
    required bool confirmed,
    required bool accepted,
  }) => {
    'rule.id': ruleId,
    'publish.destination': destination,
    'publish.confirmed': confirmed,
    'publish.accepted': accepted,
  };
}

// ---------------------------------------------------------------------------
// 104.17 — plugin workflow steps
// ---------------------------------------------------------------------------

class PluginStepRegistration {
  const PluginStepRegistration({
    required this.pluginId,
    required this.manifest,
    required this.declaredCapabilities,
  });

  final String pluginId;
  final PluginManifest manifest;
  final Set<String> declaredCapabilities;
}

enum PluginStepDecision { accepted, rejectedApiVersion, rejectedCapability }

PluginStepDecision evaluatePluginStep(
  PluginStepRegistration registration, {
  Set<String> hostCapabilities = const {},
}) {
  // Contract: plugin_api_major == 1.
  if (registration.manifest.apiVersion.major != 1) {
    return PluginStepDecision.rejectedApiVersion;
  }
  // Every declared capability must be granted by the host.
  if (!registration.declaredCapabilities.every(hostCapabilities.contains)) {
    return PluginStepDecision.rejectedCapability;
  }
  return PluginStepDecision.accepted;
}

/// Uninstall behaviour is defined: registered step ids are namespaced so
/// removal of the plugin removes exactly its steps.
String pluginStepKey(String pluginId, String stepId) =>
    'plugin.$pluginId.$stepId';

// ---------------------------------------------------------------------------
// 104.18 — capability registry preflight
// ---------------------------------------------------------------------------

class CapabilityPreflightResult {
  const CapabilityPreflightResult({
    required this.required,
    required this.missing,
  });

  final Set<String> required;
  final Set<String> missing;

  bool get satisfied => missing.isEmpty;

  /// Missing capabilities are VISIBLE, never silently dropped.
  List<String> report() =>
      missing.map((c) => 'missing capability: $c').toList();
}

CapabilityPreflightResult preflightCapabilities(
  Set<String> required, {
  required Set<String> available,
}) => CapabilityPreflightResult(
  required: required,
  missing: required.difference(available),
);

// ---------------------------------------------------------------------------
// 104.19 — secret reference model
// ---------------------------------------------------------------------------

class SecretReference {
  const SecretReference._({required this.storeKey});

  /// The key INSIDE the secret store; the value itself never travels.
  final String storeKey;

  factory SecretReference.fromStore(String storeKey) {
    final trimmed = storeKey.trim();
    if (trimmed.isEmpty || trimmed.contains('\n')) {
      throw ArgumentError('store key must be a single non-empty line');
    }
    return SecretReference._(storeKey: trimmed);
  }

  /// Redaction-required contract: string form is always masked.
  @override
  String toString() => '[REDACTED]';
}

// ---------------------------------------------------------------------------
// 104.20 — network policy
// ---------------------------------------------------------------------------

enum NetworkDecision { allowed, deniedByDefault }

class NetworkAuditEntry {
  const NetworkAuditEntry({
    required this.destination,
    required this.decision,
    required this.capability,
  });

  final String destination;
  final NetworkDecision decision;
  final String capability;
}

class AutomationNetworkPolicy {
  AutomationNetworkPolicy({Set<String> allowedDestinations = const {}})
    : _allowed = Set.of(allowedDestinations);

  final Set<String> _allowed;
  final List<NetworkAuditEntry> audit = [];

  /// Deny-by-default: only explicitly allowlisted destinations pass.
  NetworkDecision checkRequest({
    required String destination,
    required String capability,
  }) {
    final decision = _allowed.contains(destination)
        ? NetworkDecision.allowed
        : NetworkDecision.deniedByDefault;
    audit.add(
      NetworkAuditEntry(
        destination: destination,
        decision: decision,
        capability: capability,
      ),
    );
    return decision;
  }
}
