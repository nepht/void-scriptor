/// Security Revalidation (Step 113.26).
///
/// Domain contract for the six canonical evidence groups — security tests,
/// dependency scan, package scan, findings, remediations, and residual
/// risk — plus the resulting pass/fail/blocked decision.
///
/// The domain stays dependency-free: the test drives the real subsystems
/// (WorkspacePermissionPolicy, PortableProjectImporter zip-slip/secret
/// guards, ProjectPackage path escape, BackupLocationPolicy,
/// PluginSandbox/PluginPermissionSet, SharePackageBuilder leak controls,
/// SecretRedactor/SecretScanner, live pubspec.lock/pubspec.yaml scan, and
/// ArchiveSecretPolicy staging/archive scanning) and records their
/// observed behavior here. External advisory/OSV auditing, native GUI,
/// hosted CI, signing, hardware, and public release are out of scope
/// (see manifest limits).
library;

/// Canonical security areas covered by step 113.26.
enum SecurityArea {
  permission,
  importArchive,
  pathHandling,
  pluginBoundary,
  sharing,
  redaction,
  dependency,
  packaging;

  static const List<SecurityArea> all = [
    SecurityArea.permission,
    SecurityArea.importArchive,
    SecurityArea.pathHandling,
    SecurityArea.pluginBoundary,
    SecurityArea.sharing,
    SecurityArea.redaction,
    SecurityArea.dependency,
    SecurityArea.packaging,
  ];
}

/// Outcome of exercising one security area.
class SecurityCheck {
  const SecurityCheck({
    required this.area,
    required this.description,
    required this.passed,
    required this.detail,
  });

  final SecurityArea area;
  final String description;
  final bool passed;
  final String detail;
}

/// Result of scanning the live dependency lockfile.
class DependencyScanResult {
  const DependencyScanResult({
    required this.hostedPackages,
    required this.hostedWithoutSha256,
    required this.gitSources,
    required this.pathSources,
    required this.dependencyOverrides,
    required this.secretMatches,
  });

  /// Number of `source: hosted` packages in pubspec.lock.
  final int hostedPackages;

  /// Hosted packages missing a sha256 hash pin (must be 0).
  final int hostedWithoutSha256;

  /// Packages resolved from a git source (must be 0 for this gate).
  final int gitSources;

  /// Packages resolved from a local path source (must be 0 for this gate).
  final int pathSources;

  /// True when pubspec.yaml declares a dependency_overrides section.
  final bool dependencyOverrides;

  /// Credential-format matches found by SecretScanner in the lockfile.
  final int secretMatches;
}

/// Result of scanning package staging directories and archive entries.
class PackageScanResult {
  const PackageScanResult({
    required this.cleanStagingAccepted,
    required this.secretFileDetected,
    required this.secretPayloadDetected,
    required this.archiveSecretDetected,
    required this.detectionMatrixOk,
  });

  final bool cleanStagingAccepted;
  final bool secretFileDetected;
  final bool secretPayloadDetected;
  final bool archiveSecretDetected;
  final bool detectionMatrixOk;
}

/// Lifecycle state of a security finding.
enum FindingStatus { open, remediated }

/// Severity of a security finding.
enum FindingSeverity { low, medium, high }

/// One finding produced by the revalidation.
class SecurityFinding {
  const SecurityFinding({
    required this.id,
    required this.area,
    required this.severity,
    required this.summary,
    required this.status,
  });

  final String id;
  final SecurityArea area;
  final FindingSeverity severity;
  final String summary;
  final FindingStatus status;
}

/// A recorded remediation bound to a finding id.
class SecurityRemediation {
  const SecurityRemediation({required this.findingId, required this.action});

  final String findingId;
  final String action;
}

/// A residual risk that remains after revalidation (documented, not a
/// failed check).
class ResidualRisk {
  const ResidualRisk({required this.area, required this.description});

  final SecurityArea area;
  final String description;
}

/// Validation decision.
enum SecurityRevalidationDecision { pass, fail, blocked }

/// Aggregated report for the revalidation window.
class SecurityRevalidationReport {
  const SecurityRevalidationReport({
    required this.checks,
    required this.dependencyScan,
    required this.packageScan,
    required this.findings,
    required this.remediations,
    required this.residualRisks,
  });

  final List<SecurityCheck> checks;
  final DependencyScanResult? dependencyScan;
  final PackageScanResult? packageScan;
  final List<SecurityFinding> findings;
  final List<SecurityRemediation> remediations;
  final List<ResidualRisk> residualRisks;

  List<SecurityCheck> checksFor(SecurityArea area) => [
    for (final check in checks)
      if (check.area == area) check,
  ];

  SecurityRevalidationDecision get decision {
    if (checks.isEmpty) return SecurityRevalidationDecision.blocked;

    final groupsComplete = SecurityArea.all.every(
      (area) => checksFor(area).isNotEmpty,
    );
    final anyCheckFailed = checks.any((check) => !check.passed);
    final anyOpenFinding = findings.any(
      (finding) => finding.status == FindingStatus.open,
    );
    if (!groupsComplete || anyCheckFailed || anyOpenFinding) {
      return SecurityRevalidationDecision.fail;
    }
    return SecurityRevalidationDecision.pass;
  }
}

/// Builder that records evidence per area and produces the report.
class SecurityRevalidator {
  final List<SecurityCheck> _checks = [];
  final List<SecurityFinding> _findings = [];
  final List<SecurityRemediation> _remediations = [];
  final List<ResidualRisk> _residualRisks = [];
  DependencyScanResult? _dependencyScan;
  PackageScanResult? _packageScan;

  void recordCheck(SecurityCheck check) => _checks.add(check);

  void recordDependencyScan(DependencyScanResult result) =>
      _dependencyScan = result;

  void recordPackageScan(PackageScanResult result) => _packageScan = result;

  void recordFinding(SecurityFinding finding) => _findings.add(finding);

  void recordRemediation(SecurityRemediation remediation) =>
      _remediations.add(remediation);

  void recordResidualRisk(ResidualRisk risk) => _residualRisks.add(risk);

  List<SecurityCheck> checksFor(SecurityArea area) => [
    for (final check in _checks)
      if (check.area == area) check,
  ];

  List<SecurityFinding> get findings =>
      List<SecurityFinding>.unmodifiable(_findings);

  List<SecurityRemediation> get remediations =>
      List<SecurityRemediation>.unmodifiable(_remediations);

  List<ResidualRisk> get residualRisks =>
      List<ResidualRisk>.unmodifiable(_residualRisks);

  SecurityRevalidationReport report() => SecurityRevalidationReport(
    checks: List<SecurityCheck>.unmodifiable(_checks),
    dependencyScan: _dependencyScan,
    packageScan: _packageScan,
    findings: findings,
    remediations: remediations,
    residualRisks: residualRisks,
  );
}
