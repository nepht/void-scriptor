/// Fail-closed Sprint 119 readiness contract for roadmap step 118.45 --
/// Sprint 119 Readiness Gate.
///
/// Objective (external canonical `sprint_118.json`): decide whether the platform
/// is ready for a connector ecosystem, self-service tooling, or the next
/// corrective stabilization. The canonical evidence set is exactly six:
/// `stability_gate`, `expansion_gate`, `provider_registry`, `support_capacity`,
/// `security_privacy_constraints`, and `technical_debt`.
///
/// The release is delayed. No connector is certified (the committed 118.3
/// snapshot froze `charter_certified: 0` of `32` registered; the committed 117.41
/// registry evidence records `UNVERIFIED: 32`, `EXPOSED: 0`, `WITHHELD: 32`), the
/// committed 118.2 charter froze an expansion budget of zero new certified
/// connectors out of 32 registered, and the committed 117.45 approval gate
/// records `decision=delay`, `approval_state=PENDING_CHOIRUDIN`,
/// `execution_authorized=false`, and `release_blocked=true`. No live health has
/// been observed, no incident has been triaged, no connector has been certified,
/// no expansion has been authorized, and no self-service surface has been
/// enabled. A Sprint 119 readiness decision written against that state therefore
/// has exactly one honest shape: ground each of the six evidence dimensions in a
/// committed witness vocabulary, claim no readiness, and decide the next
/// corrective stabilization rather than a connector ecosystem or self-service
/// tooling that no evidence supports.
///
/// The gate is fail-closed on these families of rules:
///
/// * The committed 118.2 charter anchor must be a genuine complete charter and
///   its expansion budget must stay frozen (`max_new_certified_connectors` and
///   `currently_certified` both zero). A readiness decision anchored to an
///   unfrozen budget admits connectors nobody authorized.
/// * The committed 118.3 certified connector snapshot must be a genuine frozen
///   pass (`CERTIFIED_CONNECTOR_SNAPSHOT_FROZEN_LOCAL`). A decision anchored to
///   an unfrozen snapshot rests on a release nobody recorded.
/// * The committed 117.45 approval gate must record the delay decision
///   (`decision == delay`), read with the owner's exact grammar, never
///   case-folded or trimmed into agreement. If it is not a delay, the anchor is
///   untrustworthy and the honest answer is `blocked`, not `fail`.
/// * The registered provider set must reconcile: the icon-registry provider
///   union, the 116.3 reconciliation count, the frozen snapshot count, the
///   charter count, the 117.41 registry evidence count, and the 117.4 snapshot
///   lock count must all agree. A readiness decision over a drifting registry is
///   not a decision.
/// * The committed 117.41 registry visibility counts must reconcile (`EXPOSED`
///   plus `WITHHELD` equals the registered count) and must record zero exposed
///   providers while the release is delayed. A registry that already exposes a
///   connector contradicts the frozen zero-certified state.
/// * The release state must be `GA_DELAYED` and must agree with the anchor. A
///   decision that reads as released rests on a release nobody recorded.
/// * On the delayed path an authorized release execution and an unblocked
///   release describe behavior that never ran. This is refused.
/// * The expansion budget must stay frozen and the frozen snapshot must declare
///   zero certified connectors. A decision that certifies a connector
///   contradicts the delayed path.
/// * The readiness decision must be drawn from the canonical decision
///   vocabulary (`CONNECTOR_ECOSYSTEM`, `SELF_SERVICE_TOOLING`,
///   `CORRECTIVE_STABILIZATION`). On the delayed path a connector-ecosystem
///   decision is refused because zero connectors are certified, and a
///   self-service-tooling decision is refused because the release is not
///   authorized. The only honest decision is `CORRECTIVE_STABILIZATION`.
/// * Every one of the six canonical evidence dimensions must appear exactly
///   once. A decision that drops a dimension, invents `telepathy`, or duplicates
///   `stability_gate` is not a decision.
/// * Every dimension must carry a non-blank summary and non-empty committed
///   evidence, and its reference state must be grounded by the committed witness
///   vocabulary for that dimension, so a reference state cannot be invented into
///   the list without a witness to ground it.
/// * On the delayed path a ready dimension, an admitted dimension, a passed
///   dimension, a verified dimension, a complete dimension, a certified
///   dimension, a released dimension, an enabled self-service dimension, or a
///   ready connector-ecosystem dimension describe behavior that never ran. This
///   is refused by name, per dimension.
///
/// **A platform is never declared ready for a connector ecosystem or
/// self-service tooling without certified connectors, live evidence, and an
/// authorized release.** When no live evidence has been observed and no release
/// is authorized, the only honest readiness decision states the committed
/// reference for each evidence dimension and decides the next corrective
/// stabilization; any ready, admitted, passed, verified, complete, certified,
/// released, self-service-enabled, or ecosystem-ready claim is refused by name.
///
/// The dimension vocabulary is *derived from committed witnesses* (the 118.44
/// stability & expansion report `release_state_vocabulary`, the 118.42 expansion
/// acceptance gate `certification_vocabulary`, the 117.41 connector-registry
/// evidence `status_counts` and `visibility_counts`, the 118.6 incident support
/// intake `severity_levels` and `owners`, the 116.45 security certification gate
/// and 116.46 privacy compliance gate `acceptance_areas`, and the 114.42
/// technical debt deferred risk register `required_fields` and `deferred_checks`),
/// and the source for each dimension is a committed manifest, not copied by
/// hand, so the decision and its witnesses cannot drift apart silently.
///
/// Live health observation, incident response, connector certification,
/// connector release, expansion authorization, and self-service enablement
/// remain `DEFERRED-EXTERNAL`; this decision freezes local declared state and
/// executes none of it.
library;

import 'dart:convert';
import 'dart:io';

import 'github_app_release_authorization.dart';

/// The three states a readiness decision can rest in. `blocked` is the honest
/// resting state for "this decision cannot yet be trusted", and it is distinct
/// from `fail`, which means the decision contradicts its own evidence.
enum Sprint119ReadinessState { pass, fail, blocked }

/// One frozen readiness evidence dimension: the declared reference state for a
/// single canonical dimension, the committed evidence that grounds it, and a
/// summary.
///
/// `ready`, `admitted`, `passed`, `verified`, `complete`, `certified`,
/// `released`, `selfServiceEnabled`, and `ecosystemReady` are deliberately *not*
/// among the required fields; they are the flags the gate refuses when set, so
/// that a declared reference dimension can be recorded while never being read as
/// a live readiness claim.
class Sprint119ReadinessDimension {
  const Sprint119ReadinessDimension({
    required this.dimension,
    required this.referenceState,
    required this.summary,
    required this.evidence,
    this.ready = false,
    this.admitted = false,
    this.passed = false,
    this.verified = false,
    this.complete = false,
    this.certified = false,
    this.released = false,
    this.selfServiceEnabled = false,
    this.ecosystemReady = false,
  });

  /// The canonical dimension name, drawn from the objective's six evidence
  /// dimensions.
  final String dimension;

  /// The declared reference state for the dimension, grounded by the committed
  /// witness vocabulary for that dimension.
  final String referenceState;

  /// A human-readable summary of the dimension's committed state.
  final String summary;

  /// The committed evidence paths that ground the dimension.
  final List<String> evidence;

  /// Whether the dimension claims readiness. On the delayed path this must stay
  /// `false`.
  final bool ready;

  /// Whether the dimension claims a provider was admitted. On the delayed path
  /// this must stay `false`.
  final bool admitted;

  /// Whether the dimension claims it passed live. On the delayed path this must
  /// stay `false`.
  final bool passed;

  /// Whether the dimension claims it was verified live. On the delayed path this
  /// must stay `false`.
  final bool verified;

  /// Whether the dimension claims it is complete. On the delayed path this must
  /// stay `false`.
  final bool complete;

  /// Whether the dimension claims a connector was certified. On the delayed path
  /// this must stay `false`.
  final bool certified;

  /// Whether the dimension claims a connector was released. On the delayed path
  /// this must stay `false`.
  final bool released;

  /// Whether the dimension claims self-service tooling was enabled. On the
  /// delayed path this must stay `false`.
  final bool selfServiceEnabled;

  /// Whether the dimension claims the connector ecosystem is ready. On the
  /// delayed path this must stay `false`.
  final bool ecosystemReady;

  /// The canonical dimension fields as a name -> value map, so the gate can test
  /// blankness uniformly.
  Map<String, String> get requiredFields => <String, String>{
    'dimension': dimension,
    'reference_state': referenceState,
    'summary': summary,
  };

  /// The dimension reference-state field as a dimension -> value map, so the
  /// gate can test grounding per dimension.
  Map<String, String> get outputFields => <String, String>{
    'reference_state': referenceState,
  };
}

/// The frozen readiness decision. `dimensions` is the declared reference for
/// each canonical evidence dimension. On the delayed path no dimension may claim
/// readiness.
class Sprint119ReadinessRecord {
  const Sprint119ReadinessRecord({
    required this.releaseState,
    required this.readinessDecision,
    required this.dimensions,
  });

  final String releaseState;
  final String readinessDecision;
  final List<Sprint119ReadinessDimension> dimensions;

  List<String> get dimensionNames => <String>[
    for (final dimension in dimensions) dimension.dimension,
  ];

  /// The dimensions the decision claims are ready. On the delayed path this must
  /// stay empty.
  List<String> get readyDimensions => <String>[
    for (final dimension in dimensions)
      if (dimension.ready) dimension.dimension,
  ];

  /// The dimensions the decision claims admitted a provider. On the delayed path
  /// this must stay empty.
  List<String> get admittedDimensions => <String>[
    for (final dimension in dimensions)
      if (dimension.admitted) dimension.dimension,
  ];

  /// The dimensions the decision claims passed live. On the delayed path this
  /// must stay empty.
  List<String> get passedDimensions => <String>[
    for (final dimension in dimensions)
      if (dimension.passed) dimension.dimension,
  ];

  /// The dimensions the decision claims were verified. On the delayed path this
  /// must stay empty.
  List<String> get verifiedDimensions => <String>[
    for (final dimension in dimensions)
      if (dimension.verified) dimension.dimension,
  ];

  /// The dimensions the decision claims are complete. On the delayed path this
  /// must stay empty.
  List<String> get completeDimensions => <String>[
    for (final dimension in dimensions)
      if (dimension.complete) dimension.dimension,
  ];

  /// The dimensions the decision claims certified a connector. On the delayed
  /// path this must stay empty.
  List<String> get certifiedDimensions => <String>[
    for (final dimension in dimensions)
      if (dimension.certified) dimension.dimension,
  ];

  /// The dimensions the decision claims released a connector. On the delayed
  /// path this must stay empty.
  List<String> get releasedDimensions => <String>[
    for (final dimension in dimensions)
      if (dimension.released) dimension.dimension,
  ];

  /// The dimensions the decision claims enabled self-service tooling. On the
  /// delayed path this must stay empty.
  List<String> get selfServiceEnabledDimensions => <String>[
    for (final dimension in dimensions)
      if (dimension.selfServiceEnabled) dimension.dimension,
  ];

  /// The dimensions the decision claims a ready connector ecosystem. On the
  /// delayed path this must stay empty.
  List<String> get ecosystemReadyDimensions => <String>[
    for (final dimension in dimensions)
      if (dimension.ecosystemReady) dimension.dimension,
  ];

  int get readyCount => dimensions.where((dimension) => dimension.ready).length;

  int get admittedCount =>
      dimensions.where((dimension) => dimension.admitted).length;

  int get passedCount =>
      dimensions.where((dimension) => dimension.passed).length;

  int get verifiedCount =>
      dimensions.where((dimension) => dimension.verified).length;

  int get completeCount =>
      dimensions.where((dimension) => dimension.complete).length;

  int get certifiedCount =>
      dimensions.where((dimension) => dimension.certified).length;

  int get releasedCount =>
      dimensions.where((dimension) => dimension.released).length;

  int get selfServiceEnabledCount =>
      dimensions.where((dimension) => dimension.selfServiceEnabled).length;

  int get ecosystemReadyCount =>
      dimensions.where((dimension) => dimension.ecosystemReady).length;
}

/// What the committed witnesses actually say. A decision is only as honest as
/// the witnesses it is anchored to.
class Sprint119ReadinessAnchor {
  const Sprint119ReadinessAnchor({
    required this.charterState,
    required this.charterVerdict,
    required this.charterMaxNewCertified,
    required this.charterCurrentlyCertified,
    required this.charterRegisteredProviders,
    required this.snapshotState,
    required this.snapshotVerdict,
    required this.snapshotCertified,
    required this.snapshotRegistered,
    required this.releaseState,
    required this.registryExpectedCount,
    required this.registryEvidenceProviderCount,
    required this.registryEvidenceExposed,
    required this.registryEvidenceWithheld,
    required this.snapshotLockLockedCount,
    required this.approvalDecision,
    required this.approvalState,
    required this.executionAuthorized,
    required this.releaseBlocked,
    required this.registeredProviders,
    required this.stabilityVocabulary,
    required this.expansionVocabulary,
    required this.registryVocabulary,
    required this.supportVocabulary,
    required this.securityPrivacyVocabulary,
    required this.technicalDebtVocabulary,
    required this.readableSources,
  });

  final String charterState;
  final String charterVerdict;

  /// The maximum number of new certified connectors the committed 118.2 charter
  /// allows. A frozen budget is zero.
  final int charterMaxNewCertified;

  /// The number of connectors already certified in the committed 118.2 charter.
  final int charterCurrentlyCertified;

  /// The registered provider count the committed 118.2 charter declares.
  final int charterRegisteredProviders;

  final String snapshotState;
  final String snapshotVerdict;

  /// The certified connector count the committed 118.3 snapshot declares.
  final int snapshotCertified;

  /// The registered provider count the committed 118.3 snapshot declares.
  final int snapshotRegistered;

  /// The release state the committed 118.3 snapshot declares.
  final String releaseState;

  /// The expected provider count the committed 116.3 reconciliation declares.
  final int registryExpectedCount;

  /// The provider count the committed 117.41 registry evidence declares.
  final int registryEvidenceProviderCount;

  /// The exposed provider count the committed 117.41 registry evidence
  /// declares. On the delayed path this must stay zero.
  final int registryEvidenceExposed;

  /// The withheld provider count the committed 117.41 registry evidence
  /// declares.
  final int registryEvidenceWithheld;

  /// The locked provider count the committed 117.4 snapshot lock declares.
  final int snapshotLockLockedCount;

  /// The decision the committed 117.45 approval gate records, read with the
  /// owner's exact grammar (never case-folded or trimmed).
  final String approvalDecision;

  /// The approval state the committed 117.45 approval gate records.
  final String approvalState;

  /// Whether the committed 117.45 approval gate authorizes execution. On the
  /// delayed path this must stay `false`.
  final bool executionAuthorized;

  /// Whether the committed 117.45 approval gate records the release as blocked.
  final bool releaseBlocked;

  /// The registered provider ids, unioned from the committed 115.8 icon
  /// registry.
  final List<String> registeredProviders;

  /// The stability vocabulary the committed 118.44 stability & expansion report
  /// declares. It grounds the stability_gate dimension.
  final List<String> stabilityVocabulary;

  /// The expansion vocabulary the committed 118.42 expansion acceptance gate
  /// declares. It grounds the expansion_gate dimension.
  final List<String> expansionVocabulary;

  /// The registry vocabulary the committed 117.41 connector-registry evidence
  /// declares. It grounds the provider_registry dimension.
  final List<String> registryVocabulary;

  /// The support vocabulary the committed 118.6 incident support intake
  /// declares. It grounds the support_capacity dimension.
  final List<String> supportVocabulary;

  /// The security and privacy vocabulary the committed 116.45 security
  /// certification gate and 116.46 privacy compliance gate declare. It grounds
  /// the security_privacy_constraints dimension.
  final List<String> securityPrivacyVocabulary;

  /// The technical debt vocabulary the committed 114.42 technical debt deferred
  /// risk register declares. It grounds the technical_debt dimension.
  final List<String> technicalDebtVocabulary;

  /// The committed evidence paths that are present and readable on disk.
  final List<String> readableSources;
}

/// The measured result. `pass` means the decision is a faithful Sprint 119
/// readiness freeze; `blocked` means it cannot yet be trusted; `fail` means it
/// contradicts its evidence.
class Sprint119ReadinessReport {
  const Sprint119ReadinessReport({
    required this.state,
    required this.verdict,
    required this.releaseState,
    required this.readinessDecision,
    this.violations = const <String>[],
    this.blockers = const <String>[],
    this.openItems = const <String>[],
    this.declaredDimensions = const <String>[],
    this.readyDimensions = const <String>[],
    this.admittedDimensions = const <String>[],
    this.passedDimensions = const <String>[],
    this.verifiedDimensions = const <String>[],
    this.completeDimensions = const <String>[],
    this.certifiedDimensions = const <String>[],
    this.releasedDimensions = const <String>[],
    this.selfServiceEnabledDimensions = const <String>[],
    this.ecosystemReadyDimensions = const <String>[],
    this.readyCount = 0,
    this.admittedCount = 0,
    this.passedCount = 0,
    this.verifiedCount = 0,
    this.completeCount = 0,
    this.certifiedCount = 0,
    this.releasedCount = 0,
    this.selfServiceEnabledCount = 0,
    this.ecosystemReadyCount = 0,
    this.expansionBudgetFrozen = false,
  });

  final Sprint119ReadinessState state;
  final String verdict;
  final String releaseState;
  final String readinessDecision;

  final List<String> violations;
  final List<String> blockers;
  final List<String> openItems;
  final List<String> declaredDimensions;
  final List<String> readyDimensions;
  final List<String> admittedDimensions;
  final List<String> passedDimensions;
  final List<String> verifiedDimensions;
  final List<String> completeDimensions;
  final List<String> certifiedDimensions;
  final List<String> releasedDimensions;
  final List<String> selfServiceEnabledDimensions;
  final List<String> ecosystemReadyDimensions;
  final int readyCount;
  final int admittedCount;
  final int passedCount;
  final int verifiedCount;
  final int completeCount;
  final int certifiedCount;
  final int releasedCount;
  final int selfServiceEnabledCount;
  final int ecosystemReadyCount;
  final bool expansionBudgetFrozen;

  /// Whether the decision may be treated as a frozen readiness freeze. Only a
  /// genuine `pass` allows it.
  bool get readinessVerified => state == Sprint119ReadinessState.pass;

  String get externalGates => Sprint119ReadinessContract.externalGates;
}

/// The fixed vocabulary and committed witness set for step 118.45.
abstract final class Sprint119ReadinessContract {
  const Sprint119ReadinessContract._();

  static const String canonicalStep = '118.45';
  static const String title = 'Sprint 119 Readiness Gate';

  static const String manifestPath =
      'docs/planning/v1.3/sprint_119_readiness_gate.json';
  static const String ledgerPath =
      'docs/sprints/sprint-118-account-cloud-center-stability.md';

  /// The committed 118.2 charter that declares the frozen expansion budget.
  static const String charterManifestPath =
      'docs/planning/v1.3/sprint_118_stability_expansion_charter.json';

  /// The committed 118.3 certified connector snapshot this decision rests on.
  static const String snapshotManifestPath =
      'docs/planning/v1.3/sprint_118_certified_connector_snapshot.json';

  /// The committed 117.45 approval gate that records the delay decision.
  static const String approvalGateManifestPath =
      'docs/planning/v1.3/sprint_117_ga_approval_gate.json';

  /// The committed 115.8 provider icon registry that is the single provider-id
  /// seam and the registered-provider source.
  static const String iconRegistryManifestPath =
      'docs/planning/v1.2/sprint_115_provider_icon_registry.json';

  /// The committed 116.3 provider registry reconciliation that declares the
  /// expected provider count.
  static const String registryReconciliationManifestPath =
      'docs/planning/v1.2/sprint_116_provider_registry_reconciliation.json';

  /// The committed 117.4 certification snapshot lock that declares the locked
  /// provider count.
  static const String snapshotLockManifestPath =
      'docs/planning/v1.3/sprint_117_certification_snapshot_lock.json';

  /// The committed 117.41 connector-registry evidence that declares the provider
  /// count and the visibility counts.
  static const String registryEvidencePath =
      'docs/evidence/sprint-117-41-manifest-20261002.json';

  /// The committed 118.44 stability & expansion report that grounds the
  /// stability_gate dimension.
  static const String stabilityReportPath =
      'docs/planning/v1.3/sprint_118_stability_expansion_report.json';

  /// The committed 118.42 expansion acceptance gate that grounds the
  /// expansion_gate dimension.
  static const String expansionAcceptancePath =
      'docs/planning/v1.3/sprint_118_expansion_acceptance_gate.json';

  /// The committed 118.6 incident support intake that grounds the
  /// support_capacity dimension.
  static const String incidentIntakePath =
      'docs/planning/v1.3/sprint_118_incident_support_intake.json';

  /// The committed 116.45 security certification gate that grounds the security
  /// half of the security_privacy_constraints dimension.
  static const String securityGatePath =
      'docs/planning/v1.2/sprint_116_security_certification_gate.json';

  /// The committed 116.46 privacy compliance gate that grounds the privacy half
  /// of the security_privacy_constraints dimension.
  static const String privacyGatePath =
      'docs/planning/v1.2/sprint_116_privacy_compliance_gate.json';

  /// The committed 114.42 technical debt deferred risk register that grounds the
  /// technical_debt dimension.
  static const String technicalDebtPath =
      'docs/planning/v1.2/sprint_114_technical_debt_deferred_risk_register.json';

  static const String externalGates = 'DEFERRED-EXTERNAL';

  /// The verdict and state the 118.2 charter anchor must carry.
  static const String requiredCharterVerdict = 'CHARTER_COMPLETE_LOCAL';
  static const String requiredCharterState = 'pass';

  /// The verdict and state the 118.3 snapshot anchor must carry.
  static const String requiredSnapshotVerdict =
      'CERTIFIED_CONNECTOR_SNAPSHOT_FROZEN_LOCAL';
  static const String requiredSnapshotState = 'pass';

  /// The decision the committed 117.45 approval gate must record. Read with the
  /// owner's exact grammar, never case-folded.
  static const String requiredApprovalDecision = 'delay';

  static const String delayedReleaseState = 'GA_DELAYED';
  static const String authorizedReleaseState =
      GithubAppReleaseAuthorization.authorizedReleaseState;

  /// The number of registered providers the committed witnesses reconcile to.
  static const int expectedProviderCount = 32;

  /// The number of canonical evidence dimensions the objective names.
  static const int expectedEvidenceCount = 6;

  /// The marker a dimension declares when no committed witness names a reference
  /// state for a dimension. A decision that uses it records an honest upstream
  /// gap rather than inventing a state.
  static const String noReferenceState = 'no_reference_state';

  /// The canonical evidence dimension set each decision must carry, so a
  /// decision cannot drop a dimension and still read as complete.
  static const List<String> requiredEvidence = <String>[
    'stability_gate',
    'expansion_gate',
    'provider_registry',
    'support_capacity',
    'security_privacy_constraints',
    'technical_debt',
  ];

  /// The six canonical evidence dimensions named by the objective, in canonical
  /// order.
  static const List<String> requiredOutputs = requiredEvidence;

  /// The per-dimension fields every declared dimension must carry a non-blank
  /// value for, so a dimension cannot be recorded with a blank name, state, or
  /// summary.
  static const List<String> requiredFieldsForDimension = <String>[
    'dimension',
    'reference_state',
    'summary',
  ];

  /// The committed evidence file each canonical dimension is anchored to, in
  /// canonical order.
  static const List<String> canonicalSources = <String>[
    stabilityReportPath,
    expansionAcceptancePath,
    registryEvidencePath,
    incidentIntakePath,
    securityGatePath,
    technicalDebtPath,
  ];

  /// The committed evidence files every decision is anchored to. All must be
  /// readable.
  static const List<String> witnessSources = <String>[
    charterManifestPath,
    snapshotManifestPath,
    approvalGateManifestPath,
    iconRegistryManifestPath,
    registryReconciliationManifestPath,
    snapshotLockManifestPath,
    registryEvidencePath,
    stabilityReportPath,
    expansionAcceptancePath,
    incidentIntakePath,
    securityGatePath,
    privacyGatePath,
    technicalDebtPath,
  ];

  /// The registered provider ids, in first-seen icon-registry order. This is the
  /// canonical review key set: every id appears exactly once and no id is
  /// invented.
  static const List<String> canonicalProviders = <String>[
    'email',
    'google',
    'microsoft',
    'apple',
    'github',
    'discord',
    'x',
    'facebook',
    'google_drive',
    'onedrive',
    'dropbox',
    'mega',
    'local_storage',
    'openai',
    'gemini',
    'anthropic',
    'flux',
    'openrouter',
    'local_ai',
    'gitlab',
    'bitbucket',
    'azure_devops',
    'figma',
    'adobe',
    'canva',
    'blender_cloud',
    'sketchfab',
    'paypal',
    'stripe',
    'midtrans',
    'saweria',
    'kofi',
  ];

  /// The canonical readiness decisions a Sprint 119 gate may record.
  static const List<String> decisionVocabulary = <String>[
    'CONNECTOR_ECOSYSTEM',
    'SELF_SERVICE_TOOLING',
    'CORRECTIVE_STABILIZATION',
  ];

  /// The only honest decision on the delayed path: the next corrective
  /// stabilization.
  static const String requiredDecision = 'CORRECTIVE_STABILIZATION';

  /// The declared reference state for the stability_gate dimension. No live
  /// stability state has been observed on the delayed path, so the honest
  /// reference is the committed 118.44 report `release_state` (`GA_DELAYED`).
  static const String stabilityGateToken = 'GA_DELAYED';

  /// The declared reference state for the expansion_gate dimension. No connector
  /// has been accepted on the delayed path, so the honest reference is the
  /// committed 118.42 expansion acceptance gate first certification status
  /// (`UNVERIFIED`).
  static const String expansionGateToken = 'UNVERIFIED';

  /// The declared reference state for the provider_registry dimension. No
  /// connector has been exposed on the delayed path, so the honest reference is
  /// the committed 117.41 registry evidence withheld visibility (`WITHHELD`).
  static const String providerRegistryToken = 'WITHHELD';

  /// The declared reference state for the support_capacity dimension. No
  /// incident has been triaged live on the delayed path, so the honest reference
  /// is the committed 118.6 incident support intake first severity level (`P0`).
  static const String supportCapacityToken = 'P0';

  /// The declared reference state for the security_privacy_constraints
  /// dimension. No security verification has run live on the delayed path, so
  /// the honest reference is the committed 116.45 security certification gate
  /// first acceptance area (`oauth_tests`).
  static const String securityPrivacyToken = 'oauth_tests';

  /// The declared reference state for the technical_debt dimension. No risk has
  /// been re-assessed live on the delayed path, so the honest reference is the
  /// committed 114.42 technical debt deferred risk register first required field
  /// (`impact`).
  static const String technicalDebtToken = 'impact';

  /// The declared reference state for each canonical dimension, in canonical
  /// order.
  static const List<String> dimensionTokens = <String>[
    stabilityGateToken,
    expansionGateToken,
    providerRegistryToken,
    supportCapacityToken,
    securityPrivacyToken,
    technicalDebtToken,
  ];

  /// The committed witness vocabulary that grounds each canonical dimension, in
  /// canonical order.
  static List<List<String>> outputVocabularies(
    Sprint119ReadinessAnchor anchor,
  ) => <List<String>>[
    anchor.stabilityVocabulary,
    anchor.expansionVocabulary,
    anchor.registryVocabulary,
    anchor.supportVocabulary,
    anchor.securityPrivacyVocabulary,
    anchor.technicalDebtVocabulary,
  ];

  /// Union of the committed witness vocabularies, de-duplicated in first-seen
  /// order, plus the honest no-reference marker.
  static List<String> stateVocabulary(List<List<String>> vocabularies) {
    final seen = <String>{};
    final result = <String>[];
    for (final vocabulary in vocabularies) {
      for (final value in vocabulary) {
        if (seen.add(value)) result.add(value);
      }
    }
    if (seen.add(noReferenceState)) result.add(noReferenceState);
    return result;
  }

  /// Whether a committed witness vocabulary grounds a reference-state token.
  ///
  /// A witness grounds a token when it names the token exactly (`GA_DELAYED`,
  /// `P0`, `oauth_tests`), or when every underscore-separated part of a compound
  /// token is itself a witness-declared value. The vocabulary is measured from
  /// the committed witnesses, so a reference state cannot be invented into the
  /// list without a witness to ground it.
  static bool grounds(List<String> vocabulary, String token) {
    if (vocabulary.contains(token)) return true;
    final parts = token.split('_');
    if (parts.length < 2) return false;
    return parts.every(vocabulary.contains);
  }

  /// The committed witness vocabulary for a canonical dimension, or the empty
  /// list when the dimension is unknown.
  static List<String> vocabularyFor(
    Sprint119ReadinessAnchor anchor,
    String output,
  ) {
    final index = requiredOutputs.indexOf(output);
    if (index < 0) return const <String>[];
    return outputVocabularies(anchor)[index];
  }

  /// The committed source for a canonical dimension, or `''` if unknown.
  static String sourceFor(String output) {
    final index = requiredOutputs.indexOf(output);
    return index < 0 ? '' : canonicalSources[index];
  }

  /// The canonical frozen decision: every canonical dimension, each anchored to
  /// the committed witness vocabularies, claiming nothing ready, and deciding
  /// the next corrective stabilization.
  static Sprint119ReadinessRecord get canonicalRecord =>
      Sprint119ReadinessRecord(
        releaseState: delayedReleaseState,
        readinessDecision: requiredDecision,
        dimensions: <Sprint119ReadinessDimension>[
          for (var index = 0; index < requiredEvidence.length; index += 1)
            Sprint119ReadinessDimension(
              dimension: requiredEvidence[index],
              referenceState: dimensionTokens[index],
              summary:
                  'no live ${requiredEvidence[index]} verified on the delayed '
                  'path; committed reference only',
              evidence: <String>[canonicalSources[index]],
            ),
        ],
      );

  static Sprint119ReadinessRecord
  get authorizedRecord => Sprint119ReadinessRecord(
    releaseState: authorizedReleaseState,
    readinessDecision: 'CONNECTOR_ECOSYSTEM',
    dimensions: <Sprint119ReadinessDimension>[
      for (final dimension in requiredEvidence)
        Sprint119ReadinessDimension(
          dimension: dimension,
          referenceState: dimension == 'provider_registry'
              ? GithubAppReleaseAuthorization.authorizedStatus
              : dimensionTokens[requiredEvidence.indexOf(dimension)],
          summary: dimension == 'provider_registry'
              ? 'GitHub App certification example is authorized for Sprint 119 entry.'
              : 'No live $dimension evidence was authorized in this overlay.',
          evidence: <String>[
            canonicalSources[requiredEvidence.indexOf(dimension)],
          ],
          ready: dimension == 'provider_registry',
          certified: dimension == 'provider_registry',
        ),
    ],
  );
}

/// Reads the committed witnesses for step 118.45. Never invents: an unreadable
/// witness yields `null`, which the gate reports as blocked rather than as a
/// pass.
class Sprint119ReadinessLoader {
  const Sprint119ReadinessLoader();

  Sprint119ReadinessAnchor? loadAnchor() {
    final charter = _read(Sprint119ReadinessContract.charterManifestPath);
    final snapshot = _read(Sprint119ReadinessContract.snapshotManifestPath);
    final approval = _read(Sprint119ReadinessContract.approvalGateManifestPath);
    final icon = _read(Sprint119ReadinessContract.iconRegistryManifestPath);
    final reconciliation = _read(
      Sprint119ReadinessContract.registryReconciliationManifestPath,
    );
    final lock = _read(Sprint119ReadinessContract.snapshotLockManifestPath);
    final registry = _read(Sprint119ReadinessContract.registryEvidencePath);
    final stability = _read(Sprint119ReadinessContract.stabilityReportPath);
    final expansion = _read(Sprint119ReadinessContract.expansionAcceptancePath);
    final incidents = _read(Sprint119ReadinessContract.incidentIntakePath);
    final security = _read(Sprint119ReadinessContract.securityGatePath);
    final privacy = _read(Sprint119ReadinessContract.privacyGatePath);
    final technicalDebt = _read(Sprint119ReadinessContract.technicalDebtPath);
    if (charter == null ||
        snapshot == null ||
        approval == null ||
        icon == null ||
        reconciliation == null ||
        lock == null ||
        registry == null ||
        stability == null ||
        expansion == null ||
        incidents == null ||
        security == null ||
        privacy == null ||
        technicalDebt == null) {
      return null;
    }

    final budget = charter['expansion_budget'];
    final budgetMap = budget is Map<String, dynamic>
        ? budget
        : const <String, dynamic>{};

    final approvalMap = approval['approval'];
    final approvalInner = approvalMap is Map<String, dynamic>
        ? approvalMap
        : const <String, dynamic>{};
    final blockerMap = approval['blocker_status'];
    final blockerInner = blockerMap is Map<String, dynamic>
        ? blockerMap
        : const <String, dynamic>{};

    final categories = icon['categories'];
    final categoryMap = categories is Map<String, dynamic>
        ? categories
        : const <String, dynamic>{};
    final registered = <String>[];
    for (final value in categoryMap.values) {
      if (value is List) {
        for (final item in value) {
          if (item is String && !registered.contains(item)) {
            registered.add(item);
          }
        }
      }
    }

    final visibility = registry['visibility_counts'];
    final visibilityMap = visibility is Map<String, dynamic>
        ? visibility
        : const <String, dynamic>{};
    final status = registry['status_counts'];
    final statusMap = status is Map<String, dynamic>
        ? status
        : const <String, dynamic>{};

    final registryVocabulary = <String>[
      ...statusMap.keys.whereType<String>(),
      ...visibilityMap.keys.whereType<String>(),
    ];

    final sources = Sprint119ReadinessContract.witnessSources.toSet();

    return Sprint119ReadinessAnchor(
      charterState: _text(charter['state']),
      charterVerdict: _text(charter['verdict']),
      charterMaxNewCertified: _int(budgetMap['max_new_certified_connectors']),
      charterCurrentlyCertified: _int(budgetMap['currently_certified']),
      charterRegisteredProviders: _int(budgetMap['registered_providers']),
      snapshotState: _text(snapshot['state']),
      snapshotVerdict: _text(snapshot['verdict']),
      snapshotCertified: _int(snapshot['charter_certified']),
      snapshotRegistered: _int(snapshot['registered_provider_count']),
      releaseState: _text(snapshot['release_state']),
      registryExpectedCount: _int(reconciliation['expected_provider_count']),
      registryEvidenceProviderCount: _int(registry['provider_count']),
      registryEvidenceExposed: _int(visibilityMap['EXPOSED']),
      registryEvidenceWithheld: _int(visibilityMap['WITHHELD']),
      snapshotLockLockedCount: _int(lock['locked_provider_count']),
      approvalDecision: _text(approvalInner['decision']),
      approvalState: _text(approvalInner['approval_state']),
      executionAuthorized: approvalInner['execution_authorized'] == true,
      releaseBlocked: blockerInner['release_blocked'] == true,
      registeredProviders: registered,
      stabilityVocabulary: _strings(stability['release_state_vocabulary']),
      expansionVocabulary: _strings(expansion['certification_vocabulary']),
      registryVocabulary: registryVocabulary,
      supportVocabulary: <String>[
        ..._strings(incidents['severity_levels']),
        ..._strings(incidents['owners']),
      ],
      securityPrivacyVocabulary: <String>[
        ..._strings(security['acceptance_areas']),
        ..._strings(privacy['acceptance_areas']),
      ],
      technicalDebtVocabulary: <String>[
        ..._strings(technicalDebt['required_fields']),
        ..._strings(technicalDebt['deferred_checks']),
      ],
      readableSources: <String>[
        for (final path in sources)
          if (File(path).existsSync()) path,
      ],
    );
  }

  static Map<String, dynamic>? _read(String path) {
    final file = File(path);
    if (!file.existsSync()) return null;
    try {
      final value = jsonDecode(file.readAsStringSync());
      return value is Map<String, dynamic> ? value : null;
    } on FormatException {
      return null;
    }
  }

  static String _text(Object? value) => value is String ? value.trim() : '';

  /// Coerce a witness field into a non-empty vocabulary. A scalar string becomes
  /// a single-element list; a list becomes its non-empty string elements. A
  /// missing or non-string field yields the empty list, so the gate reports the
  /// resulting grounding gap rather than inventing a value.
  static List<String> _strings(Object? value) {
    if (value is String) {
      final trimmed = value.trim();
      return trimmed.isEmpty ? const <String>[] : <String>[trimmed];
    }
    if (value is List) {
      final out = <String>[];
      for (final item in value) {
        if (item is String && item.trim().isNotEmpty) out.add(item);
      }
      return out;
    }
    return const <String>[];
  }

  static int _int(Object? value) => value is int ? value : 0;
}

/// The fail-closed Sprint 119 readiness gate for step 118.45.
class Sprint119ReadinessGate {
  const Sprint119ReadinessGate();

  Sprint119ReadinessReport evaluate() {
    final authorization = GithubAppReleaseAuthorization.load();
    return evaluateWith(
      const Sprint119ReadinessLoader().loadAnchor(),
      authorization == null
          ? Sprint119ReadinessContract.canonicalRecord
          : Sprint119ReadinessContract.authorizedRecord,
      authorization: authorization,
    );
  }

  Sprint119ReadinessReport evaluateWith(
    Sprint119ReadinessAnchor? anchor,
    Sprint119ReadinessRecord record, {
    GithubAppReleaseAuthorization? authorization,
  }) {
    if (anchor == null) {
      return Sprint119ReadinessReport(
        state: Sprint119ReadinessState.blocked,
        verdict: 'SPRINT_119_READINESS_EVIDENCE_UNREADABLE',
        releaseState: record.releaseState,
        readinessDecision: record.readinessDecision,
        blockers: const <String>['committed_readiness_evidence_unreadable'],
        openItems: const <String>['committed_readiness_evidence_unreadable'],
      );
    }

    final violations = <String>[];
    final blockers = <String>[];
    final openItems = <String>[];
    final authorized =
        authorization?.isValid == true &&
        record.releaseState ==
            Sprint119ReadinessContract.authorizedReleaseState;

    final frozen =
        anchor.charterMaxNewCertified == 0 &&
        anchor.charterCurrentlyCertified == 0;

    // (1) The 118.2 charter anchor must be a genuine complete charter.
    if (anchor.charterState !=
            Sprint119ReadinessContract.requiredCharterState ||
        anchor.charterVerdict !=
            Sprint119ReadinessContract.requiredCharterVerdict) {
      blockers.add('charter_not_complete:${anchor.charterVerdict}');
    }

    // (2) The 118.3 snapshot anchor must be a genuine frozen pass.
    if (anchor.snapshotState !=
            Sprint119ReadinessContract.requiredSnapshotState ||
        (!authorized &&
            anchor.snapshotVerdict !=
                Sprint119ReadinessContract.requiredSnapshotVerdict) ||
        (authorized &&
            anchor.snapshotVerdict !=
                GithubAppReleaseAuthorization.authorizedSnapshotVerdict)) {
      blockers.add('snapshot_not_frozen:${anchor.snapshotVerdict}');
    }

    // (3) The 117.45 approval gate must record the delay decision, read with the
    // owner's exact grammar. If it is not a delay, the anchor is untrustworthy.
    if (!authorized &&
        anchor.approvalDecision !=
            Sprint119ReadinessContract.requiredApprovalDecision) {
      blockers.add('approval_gate_not_delay:${anchor.approvalDecision}');
    }

    // (4) The registered provider set must reconcile across the icon registry,
    // the 116.3 reconciliation, the frozen snapshot, the charter, the 117.41
    // registry evidence, and the 117.4 snapshot lock.
    if (anchor.registeredProviders.length !=
            Sprint119ReadinessContract.expectedProviderCount ||
        anchor.registryExpectedCount !=
            Sprint119ReadinessContract.expectedProviderCount ||
        anchor.snapshotRegistered !=
            Sprint119ReadinessContract.expectedProviderCount ||
        anchor.charterRegisteredProviders !=
            Sprint119ReadinessContract.expectedProviderCount ||
        anchor.registryEvidenceProviderCount !=
            Sprint119ReadinessContract.expectedProviderCount ||
        anchor.snapshotLockLockedCount !=
            Sprint119ReadinessContract.expectedProviderCount) {
      blockers.add(
        'registry_not_reconciled:icon=${anchor.registeredProviders.length}:'
        'reconciliation=${anchor.registryExpectedCount}:'
        'snapshot=${anchor.snapshotRegistered}:'
        'charter=${anchor.charterRegisteredProviders}:'
        'registry_evidence=${anchor.registryEvidenceProviderCount}:'
        'snapshot_lock=${anchor.snapshotLockLockedCount}',
      );
    }

    // (5) The 117.41 registry visibility must reconcile and must record zero
    // exposed providers while the release is delayed. A registry that already
    // exposes a connector contradicts the frozen zero-certified state.
    if (anchor.registryEvidenceExposed + anchor.registryEvidenceWithheld !=
        Sprint119ReadinessContract.expectedProviderCount) {
      blockers.add(
        'registry_visibility_not_reconciled:'
        'exposed=${anchor.registryEvidenceExposed}:'
        'withheld=${anchor.registryEvidenceWithheld}',
      );
    }
    if (!authorized && anchor.registryEvidenceExposed != 0) {
      blockers.add(
        'registry_visibility_exposed_on_delayed_path:'
        '${anchor.registryEvidenceExposed}',
      );
    }

    // (6) The release state must agree with the anchor and must be delayed.
    if (!authorized && record.releaseState != anchor.releaseState) {
      violations.add(
        'release_state_mismatch:anchor=${anchor.releaseState}:'
        'record=${record.releaseState}',
      );
    }
    if (!authorized &&
        record.releaseState != Sprint119ReadinessContract.delayedReleaseState) {
      violations.add('readiness_not_on_delayed_path:${record.releaseState}');
    }

    final delayed =
        record.releaseState == Sprint119ReadinessContract.delayedReleaseState;

    if (!delayed && !authorized) {
      violations.add('readiness_release_state_not_authorized');
    }

    // (7) On the delayed path an authorized release execution and an unblocked
    // release are behavior that never ran.
    if (delayed && anchor.executionAuthorized) {
      violations.add('readiness_execution_authorized_on_delayed_path');
    }
    if (delayed && !anchor.releaseBlocked) {
      violations.add('readiness_release_not_blocked_on_delayed_path');
    }

    // (8) The expansion budget must stay frozen: no new certified connector and
    // no already-certified connector while the release is delayed.
    if (!frozen && !authorized) {
      violations.add(
        'readiness_expansion_budget_not_frozen:max_new='
        '${anchor.charterMaxNewCertified}:'
        'currently=${anchor.charterCurrentlyCertified}',
      );
    }
    // The frozen 118.3 snapshot must declare zero certified connectors. A
    // snapshot that already certifies a connector contradicts the delayed path.
    if (!authorized && anchor.snapshotCertified != 0) {
      violations.add(
        'readiness_snapshot_certified_nonzero:${anchor.snapshotCertified}',
      );
    }

    // (9) The readiness decision must be drawn from the canonical decision
    // vocabulary. On the delayed path a connector-ecosystem decision is refused
    // because zero connectors are certified, a self-service-tooling decision is
    // refused because the release is not authorized, and the only honest
    // decision is the next corrective stabilization.
    final decision = record.readinessDecision;
    if (!Sprint119ReadinessContract.decisionVocabulary.contains(decision)) {
      violations.add('readiness_decision_unknown:$decision');
    }
    if (delayed && decision == 'CONNECTOR_ECOSYSTEM') {
      violations.add(
        'connector_ecosystem_readiness_claimed_on_delayed_path:'
        'certified=${anchor.snapshotCertified}',
      );
    }
    if (delayed && decision == 'SELF_SERVICE_TOOLING') {
      violations.add(
        'self_service_tooling_readiness_claimed_on_delayed_path:'
        'execution_authorized=${anchor.executionAuthorized}',
      );
    }
    if (delayed && decision != Sprint119ReadinessContract.requiredDecision) {
      violations.add(
        'sprint_119_readiness_not_corrective_on_delayed_path:$decision',
      );
    }

    // (10) Every canonical dimension must appear exactly once, and each
    // dimension must carry a non-blank summary, non-empty committed evidence,
    // and a reference state grounded by its committed witness vocabulary.
    final declared = <String, int>{};
    for (final dimension in record.dimensions) {
      declared[dimension.dimension] = (declared[dimension.dimension] ?? 0) + 1;
    }
    for (final dimension in record.dimensions) {
      final name = dimension.dimension;
      if (!Sprint119ReadinessContract.requiredEvidence.contains(name)) {
        violations.add('readiness_dimension_unknown:$name');
      }
      for (final field
          in Sprint119ReadinessContract.requiredFieldsForDimension) {
        final value = dimension.requiredFields[field] ?? '';
        if (value.trim().isEmpty) {
          violations.add('entry_blank_$field:$name');
        }
      }
      if (dimension.evidence.isEmpty ||
          dimension.evidence.any((item) => item.trim().isEmpty)) {
        violations.add('readiness_dimension_evidence_missing:$name');
      } else {
        for (final item in dimension.evidence) {
          if (!anchor.readableSources.contains(item)) {
            violations.add(
              'readiness_dimension_evidence_unreadable:$name:$item',
            );
          }
        }
      }
      final token = dimension.outputFields['reference_state'] ?? '';
      final vocabulary = Sprint119ReadinessContract.vocabularyFor(anchor, name);
      final grounded =
          token == Sprint119ReadinessContract.noReferenceState ||
          Sprint119ReadinessContract.grounds(vocabulary, token);
      if (token.trim().isEmpty || !grounded) {
        violations.add('reference_state_invalid:$name');
      }
      if (token == Sprint119ReadinessContract.noReferenceState) {
        openItems.add('upstream_state_vocabulary_gap:$name');
      }
      // Readiness is never declared without live evidence.
      if (delayed && dimension.ready) {
        violations.add('readiness_ready_claimed_on_delayed_path:$name');
      }
      // A provider is never admitted without live evidence.
      if (delayed && dimension.admitted) {
        violations.add('readiness_admitted_claimed_on_delayed_path:$name');
      }
      // A dimension is never passed live without live evidence.
      if (delayed && dimension.passed) {
        violations.add('readiness_passed_claimed_on_delayed_path:$name');
      }
      // A dimension is never verified live without live evidence.
      if (delayed && dimension.verified) {
        violations.add('readiness_verified_claimed_on_delayed_path:$name');
      }
      // A dimension is never complete without live verification.
      if (delayed && dimension.complete) {
        violations.add('readiness_complete_claimed_on_delayed_path:$name');
      }
      // A connector is never certified without live provider verification.
      if (delayed && dimension.certified) {
        violations.add('readiness_certified_claimed_on_delayed_path:$name');
      }
      // A connector is never released without an authorized release.
      if (delayed && dimension.released) {
        violations.add('readiness_released_claimed:$name');
      }
      // Self-service tooling is never enabled without an authorized release.
      if (delayed && dimension.selfServiceEnabled) {
        violations.add(
          'readiness_self_service_enabled_claimed_on_delayed_path:$name',
        );
      }
      // A connector ecosystem is never ready without certified connectors.
      if (delayed && dimension.ecosystemReady) {
        violations.add(
          'readiness_ecosystem_ready_claimed_on_delayed_path:$name',
        );
      }
    }
    for (final name in declared.keys) {
      if (declared[name]! > 1) {
        violations.add('readiness_dimension_duplicate:$name');
      }
    }
    for (final name in Sprint119ReadinessContract.requiredEvidence) {
      if (!declared.containsKey(name)) {
        violations.add('readiness_dimension_missing:$name');
      }
    }

    // (11) Every committed evidence source must be readable.
    for (final source in Sprint119ReadinessContract.witnessSources.toSet()) {
      if (!anchor.readableSources.contains(source)) {
        violations.add('required_source_unreadable:$source');
      }
    }

    final allItems = <String>[...violations, ...blockers, ...openItems];
    final names = record.dimensionNames;

    // An untrustworthy anchor short-circuits: if a committed witness is not a
    // genuine pass, the dimension-level findings cannot be trusted either, so
    // the honest answer is `blocked`, not `fail`.
    if (blockers.isNotEmpty) {
      return Sprint119ReadinessReport(
        state: Sprint119ReadinessState.blocked,
        verdict: 'SPRINT_119_READINESS_BLOCKED_UPSTREAM',
        releaseState: record.releaseState,
        readinessDecision: record.readinessDecision,
        violations: violations,
        blockers: blockers,
        openItems: allItems,
        declaredDimensions: names,
        readyDimensions: record.readyDimensions,
        admittedDimensions: record.admittedDimensions,
        passedDimensions: record.passedDimensions,
        verifiedDimensions: record.verifiedDimensions,
        completeDimensions: record.completeDimensions,
        certifiedDimensions: record.certifiedDimensions,
        releasedDimensions: record.releasedDimensions,
        selfServiceEnabledDimensions: record.selfServiceEnabledDimensions,
        ecosystemReadyDimensions: record.ecosystemReadyDimensions,
        readyCount: record.readyCount,
        admittedCount: record.admittedCount,
        passedCount: record.passedCount,
        verifiedCount: record.verifiedCount,
        completeCount: record.completeCount,
        certifiedCount: record.certifiedCount,
        releasedCount: record.releasedCount,
        selfServiceEnabledCount: record.selfServiceEnabledCount,
        ecosystemReadyCount: record.ecosystemReadyCount,
        expansionBudgetFrozen: frozen,
      );
    }
    if (violations.isNotEmpty) {
      return Sprint119ReadinessReport(
        state: Sprint119ReadinessState.fail,
        verdict: 'SPRINT_119_READINESS_EVIDENCE_VIOLATION',
        releaseState: record.releaseState,
        readinessDecision: record.readinessDecision,
        violations: violations,
        blockers: blockers,
        openItems: allItems,
        declaredDimensions: names,
        readyDimensions: record.readyDimensions,
        admittedDimensions: record.admittedDimensions,
        passedDimensions: record.passedDimensions,
        verifiedDimensions: record.verifiedDimensions,
        completeDimensions: record.completeDimensions,
        certifiedDimensions: record.certifiedDimensions,
        releasedDimensions: record.releasedDimensions,
        selfServiceEnabledDimensions: record.selfServiceEnabledDimensions,
        ecosystemReadyDimensions: record.ecosystemReadyDimensions,
        readyCount: record.readyCount,
        admittedCount: record.admittedCount,
        passedCount: record.passedCount,
        verifiedCount: record.verifiedCount,
        completeCount: record.completeCount,
        certifiedCount: record.certifiedCount,
        releasedCount: record.releasedCount,
        selfServiceEnabledCount: record.selfServiceEnabledCount,
        ecosystemReadyCount: record.ecosystemReadyCount,
        expansionBudgetFrozen: frozen,
      );
    }
    return Sprint119ReadinessReport(
      state: Sprint119ReadinessState.pass,
      verdict: authorized
          ? 'SPRINT_119_READINESS_GATE_AUTHORIZED_LOCAL'
          : 'SPRINT_119_READINESS_GATE_VERIFIED_LOCAL',
      releaseState: record.releaseState,
      readinessDecision: record.readinessDecision,
      openItems: allItems,
      declaredDimensions: names,
      readyDimensions: record.readyDimensions,
      admittedDimensions: record.admittedDimensions,
      passedDimensions: record.passedDimensions,
      verifiedDimensions: record.verifiedDimensions,
      completeDimensions: record.completeDimensions,
      certifiedDimensions: record.certifiedDimensions,
      releasedDimensions: record.releasedDimensions,
      selfServiceEnabledDimensions: record.selfServiceEnabledDimensions,
      ecosystemReadyDimensions: record.ecosystemReadyDimensions,
      readyCount: record.readyCount,
      admittedCount: record.admittedCount,
      passedCount: record.passedCount,
      verifiedCount: record.verifiedCount,
      completeCount: record.completeCount,
      certifiedCount: record.certifiedCount,
      releasedCount: record.releasedCount,
      selfServiceEnabledCount: record.selfServiceEnabledCount,
      ecosystemReadyCount: record.ecosystemReadyCount,
      expansionBudgetFrozen: frozen,
    );
  }
}
