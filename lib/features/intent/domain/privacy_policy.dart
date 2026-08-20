class InputConsent {
  const InputConsent({this.voice = false, this.revoked = false});
  final bool voice;
  final bool revoked;
}

enum InputPermission { voice, gaze, gesture, bci }

class PrivacyRequest {
  const PrivacyRequest({required this.input});
  final InputPermission input;
}

enum PrivacyDenialReason { consentRequired, consentRevoked }

class PrivacyDecision {
  const PrivacyDecision({
    required this.allowed,
    required this.requiresConfirmation,
    this.reason,
  });
  final bool allowed;
  final bool requiresConfirmation;
  final PrivacyDenialReason? reason;
}

class PrivacyPolicy {
  const PrivacyPolicy({required this.consent});
  final InputConsent consent;

  PrivacyDecision evaluate(PrivacyRequest request) {
    if (consent.revoked) {
      return const PrivacyDecision(
        allowed: false,
        requiresConfirmation: false,
        reason: PrivacyDenialReason.consentRevoked,
      );
    }
    final allowed = switch (request.input) {
      InputPermission.voice => consent.voice,
      InputPermission.gaze ||
      InputPermission.gesture ||
      InputPermission.bci => false,
    };
    return PrivacyDecision(
      allowed: allowed,
      requiresConfirmation: false,
      reason: allowed ? null : PrivacyDenialReason.consentRequired,
    );
  }
}
