/// Data Integrity Validation (Step 113.25).
///
/// Domain contract for the six canonical evidence groups — id checks,
/// link checks, index checks, timeline checks, alias checks, and
/// checksum results — plus the resulting pass/fail/blocked decision.
///
/// The domain stays dependency-free: the test drives the real subsystems
/// (UUID identity + project manifest, AssetRelations DAO, SQLite FTS5
/// search index, timeline creation/restart, GoRouter foundation aliases,
/// HMAC integrity manifest) and records their observed behavior here.
/// Narrative branch editors and real media/export file manifests are out
/// of scope (see manifest limits).
library;

/// Canonical integrity areas covered by step 113.25.
enum IntegrityArea {
  id,
  link,
  searchIndex,
  timeline,
  alias,
  checksum;

  static const List<IntegrityArea> all = [
    IntegrityArea.id,
    IntegrityArea.link,
    IntegrityArea.searchIndex,
    IntegrityArea.timeline,
    IntegrityArea.alias,
    IntegrityArea.checksum,
  ];
}

/// Outcome of exercising one integrity area.
class IntegrityCheck {
  const IntegrityCheck({
    required this.area,
    required this.description,
    required this.passed,
    required this.detail,
  });

  final IntegrityArea area;
  final String description;
  final bool passed;
  final String detail;
}

/// Checksum/integrity-manifest evidence for one artifact set.
class ChecksumResult {
  const ChecksumResult({
    required this.label,
    required this.integrityHeld,
    required this.detail,
  });

  final String label;

  /// True when the checksum/integrity behavior matched the expectation
  /// (clean directory verifies TRUE; post-sign tampering is detected).
  final bool integrityHeld;
  final String detail;
}

/// Validation decision.
enum DataIntegrityDecision { pass, fail, blocked }

/// Aggregated report for the validation window.
class DataIntegrityReport {
  const DataIntegrityReport({
    required this.checks,
    required this.checksumResults,
  });

  final List<IntegrityCheck> checks;
  final List<ChecksumResult> checksumResults;

  List<IntegrityCheck> checksFor(IntegrityArea area) => [
    for (final check in checks)
      if (check.area == area) check,
  ];

  DataIntegrityDecision get decision {
    final hasAnyEvidence = checks.isNotEmpty || checksumResults.isNotEmpty;
    if (!hasAnyEvidence) return DataIntegrityDecision.blocked;

    final groupsComplete = IntegrityArea.all.every((area) {
      if (area == IntegrityArea.checksum) return checksumResults.isNotEmpty;
      return checksFor(area).isNotEmpty;
    });
    final anyCheckFailed = checks.any((check) => !check.passed);
    final anyChecksumUnverified = checksumResults.any(
      (result) => !result.integrityHeld,
    );
    if (!groupsComplete || anyCheckFailed || anyChecksumUnverified) {
      return DataIntegrityDecision.fail;
    }
    return DataIntegrityDecision.pass;
  }
}

/// Builder that records evidence per area and produces the report.
class DataIntegrityValidator {
  final List<IntegrityCheck> _checks = [];
  final List<ChecksumResult> _checksums = [];

  void recordCheck(IntegrityCheck check) => _checks.add(check);

  void recordChecksum(ChecksumResult result) => _checksums.add(result);

  List<IntegrityCheck> get idChecks => _for(IntegrityArea.id);

  List<IntegrityCheck> get linkChecks => _for(IntegrityArea.link);

  List<IntegrityCheck> get indexChecks => _for(IntegrityArea.searchIndex);

  List<IntegrityCheck> get timelineChecks => _for(IntegrityArea.timeline);

  List<IntegrityCheck> get aliasChecks => _for(IntegrityArea.alias);

  List<ChecksumResult> get checksumResults =>
      List<ChecksumResult>.unmodifiable(_checksums);

  List<IntegrityCheck> _for(IntegrityArea area) => [
    for (final check in _checks)
      if (check.area == area) check,
  ];

  DataIntegrityReport report() => DataIntegrityReport(
    checks: List<IntegrityCheck>.unmodifiable(_checks),
    checksumResults: checksumResults,
  );
}
