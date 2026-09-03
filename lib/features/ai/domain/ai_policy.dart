import 'ai_provider.dart';

/// Sprint 145.36 — unified AI optional-boundary policy.
///
/// One stateless rulebook covering the three boundary axes the audit
/// required before any provider call:
///
/// * **BYOK** — credentials come from the user (`byokReady`), never from
///   the project database; a request without a credential gate result is
///   denied.
/// * **Explicit context** — a request must name the context it sends
///   ([AiPolicyCheckRequest.contextSummary]); empty context is denied so
///   silent "send everything" prompts are impossible.
/// * **Consent** — any external (network) transfer requires explicit
///   consent in the same request; local providers (Ollama/ComfyUI on
///   localhost) stay usable without consent.
///
/// The policy is a pure contract: callers (runtime/queue wiring) observe
/// the [PolicyResult] and fail closed on [PolicyResultDenied].
class AiPolicy {
  const AiPolicy();

  /// The canonical default: local-only AI is allowed, external transfer
  /// is denied until explicit consent arrives with the request.
  const AiPolicy.byDefault();

  PolicyResult check(AiPolicyCheckRequest request) {
    if (request.contextSummary.trim().isEmpty) {
      return const PolicyResultDenied(
        reason: 'explicit context required: no context summary provided',
      );
    }
    if (!request.byokReady) {
      return const PolicyResultDenied(
        reason: 'credential required: no BYOK provider credential configured',
      );
    }
    if (request.externalTransfer && !request.externalTransferConsent) {
      return const PolicyResultDenied(
        reason:
            'consent required: external transfer blocked without '
            'explicit consent',
      );
    }
    return PolicyResultAllowed(requiredContext: request.contextSummary);
  }
}

/// One pending provider call, described by its boundary facts.
class AiPolicyCheckRequest {
  const AiPolicyCheckRequest({
    required this.target,
    required this.contextSummary,
    required this.byokReady,
    this.externalTransfer = false,
    this.externalTransferConsent = false,
  });

  final PromptTarget target;

  /// Human-auditable summary of the context that will be sent. Empty or
  /// whitespace-only context is a boundary violation.
  final String contextSummary;

  /// Whether the request carries a working BYOK credential (secure store
  /// read succeeded for the selected provider).
  final bool byokReady;

  /// Whether this request leaves the machine (remote provider vs local
  /// Ollama/ComfyUI).
  final bool externalTransfer;

  /// Explicit per-request consent for [externalTransfer].
  final bool externalTransferConsent;
}

sealed class PolicyResult {
  const PolicyResult();
}

class PolicyResultAllowed extends PolicyResult {
  const PolicyResultAllowed({required this.requiredContext});

  /// The exact context summary the caller must attach to the request.
  final String requiredContext;
}

class PolicyResultDenied extends PolicyResult {
  const PolicyResultDenied({required this.reason});

  final String reason;
}
