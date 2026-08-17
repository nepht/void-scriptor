/// Sprint 49 — Step 49.8–49.10 Build Validation, Validation Levels.
enum ValidationLevel {
  metadataCheck,
  buildCheck,
  runtimeSmoke,
  contentIntegrity,
  certification,
}

class ReleaseValidation {
  const ReleaseValidation({
    required this.releaseId,
    required this.level,
    this.passed = false,
    this.details,
  });

  final String releaseId;
  final ValidationLevel level;
  final bool passed;
  final String? details;

  ReleaseValidation markPassed({String? details}) => ReleaseValidation(
    releaseId: releaseId,
    level: level,
    passed: true,
    details: details ?? this.details,
  );
}
