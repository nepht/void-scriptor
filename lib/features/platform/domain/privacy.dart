/// Sprint 50 — Step 50.76–50.81 Privacy, Local-Only Mode, Security Audits.
class PrivacyDashboard {
  const PrivacyDashboard({
    required this.id,
    required this.localOnlyMode,
    required this.telemetryEnabled,
    this.dataCollection = const {},
  });

  final String id;
  final bool localOnlyMode;
  final bool telemetryEnabled;
  final Map<String, bool> dataCollection;
}

class SecretsAudit {
  const SecretsAudit({
    required this.id,
    required this.checkedAt,
    this.foundSecrets = const [],
  });

  final String id;
  final DateTime checkedAt;
  final List<String> foundSecrets;

  bool get isClean => foundSecrets.isEmpty;
}
