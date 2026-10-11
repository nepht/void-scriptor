/// Fail-closed expansion acceptance gate record for roadmap step 118.42 --
/// Expansion Acceptance Gate.
///
/// Objective (external canonical `sprint_118.json`): allow a new connector only
/// when certification, quality, security, privacy, accessibility, docs, and
/// rollback evidence are complete. The canonical evidence set is exactly seven
/// dimensions: `certification`, `contract_tests`, `security`, `privacy`,
/// `accessibility`, `documentation`, and `rollback`.
///
/// The release is delayed. No connector is certified (118.3 froze `CERTIFIED: 0`
/// of `32` registered; the committed 117.41 registry evidence records
/// `UNVERIFIED: 32`, `EXPOSED: 0`, `WITHHELD: 32`), the 118.2 charter froze an
/// expansion budget of zero new certified connectors out of 32 registered, and
/// the committed 117.45 approval gate records `decision=delay`,
/// `approval_state=PENDING_CHOIRUDIN`, `execution_authorized=false`, and
/// `release_blocked=true`. No connector has been allowed into the ecosystem, no
/// acceptance has been granted, no acceptance gate has passed, and no evidence
/// has been verified live. An expansion acceptance record written against that
/// state therefore has exactly one honest shape: enumerate all 32 registered
/// providers, anchor each of the seven acceptance evidence dimensions to a
/// committed witness vocabulary, claim no connector allowed, and accept none.
///
/// The gate is fail-closed on these families of rules:
///
/// * The committed 118.2 charter anchor must be a genuine complete charter and
///   its expansion budget must stay frozen (`max_new_certified_connectors` and
///   `currently_certified` both zero). An acceptance gate anchored to an
///   unfrozen budget accepts connectors nobody authorized.
/// * The committed 118.3 certified connector snapshot must be a genuine frozen
///   pass (`CERTIFIED_CONNECTOR_SNAPSHOT_FROZEN_LOCAL`). An acceptance gate
///   anchored to an unfrozen snapshot rests on a release nobody recorded.
/// * The committed 117.45 approval gate must record the delay decision
///   (`decision == delay`), read with the owner's exact grammar, never
///   case-folded or trimmed into agreement. If it is not a delay, the anchor is
///   untrustworthy and the honest answer is `blocked`, not `fail`.
/// * The registered provider set must reconcile: the icon-registry provider
///   union, the 116.3 reconciliation count, the frozen snapshot count, the
///   charter count, the 117.41 registry evidence count, and the 117.4 snapshot
///   lock count must all agree. An acceptance gate over a drifting registry is
///   not an acceptance gate.
/// * The committed 117.41 registry visibility counts must reconcile (`EXPOSED`
///   plus `WITHHELD` equals the registered count) and must record zero exposed
///   providers while the release is delayed. A registry that already exposes a
///   connector contradicts the frozen zero-certified state.
/// * Every registered provider must appear exactly once. A record that drops a
///   provider, invents `telepathy`, or duplicates `stripe` is not a record.
/// * Every entry must carry all seven canonical evidence dimensions non-blank,
///   and each of the seven acceptance evidence dimensions must be grounded by
///   the committed witness vocabulary for that dimension, so an acceptance
///   reference cannot be invented into the list without a witness to ground it.
/// * On the delayed path a connector allowed into the ecosystem, an acceptance
///   granted, a passed acceptance gate, a completed evidence set, a certified
///   connector, or a released connector describe behavior that never ran. This
///   is refused by name, per entry.
///
/// **A connector is never allowed without complete live evidence and an
/// authorized release.** When no acceptance has been granted and no release is
/// authorized, the only honest record states the committed reference for each
/// acceptance evidence dimension and claims nothing live; any allowed,
/// admitted, accepted, passed, evidence-complete, certified, or released claim
/// is refused by name.
///
/// The output vocabulary is *derived from committed witnesses* (the 118.39
/// versioned connector certification `status_vocabulary`, the 118.40 expansion
/// contract `suite_contract_vocabulary`, the 118 security health review
/// reference states, the 118 privacy health review reference states, the 118
/// accessibility health reference states, the 112 documentation & support
/// release notes `outputs`, and the 116.50 staged beta rollout monitoring
/// `rollback[].rollback_id`), and the source for each dimension is a committed
/// manifest, not copied by hand, so the record and its witnesses cannot drift
/// apart silently.
///
/// Connector acceptance, connector allowance, evidence verification, connector
/// certification, connector release, and publication remain `DEFERRED-EXTERNAL`;
/// this record freezes local declared state and executes none of it.
library;

import 'dart:convert';
import 'dart:io';

import 'github_app_release_authorization.dart';

/// The three states an acceptance record can rest in. `blocked` is the honest
/// resting state for "this record cannot yet be trusted", and it is distinct
/// from `fail`, which means the record contradicts its own evidence.
enum Sprint118ExpansionAcceptanceState { pass, fail, blocked }

/// One frozen acceptance record entry: the declared reference for each of the
/// seven canonical acceptance evidence dimensions of a single registered
/// provider.
///
/// `allowed`, `admitted`, `accepted`, `passed`, `evidenceComplete`, `certified`,
/// and `released` are deliberately *not* among the seven required fields; they
/// are the flags the gate refuses when set, so that a declared reference record
/// can be recorded while never being read as a connector allowed into the
/// ecosystem, an acceptance granted, a passed gate, a completed evidence set, a
/// certified connector, or a released connector.
class Sprint118ExpansionAcceptanceEntry {
  const Sprint118ExpansionAcceptanceEntry({
    required this.providerId,
    required this.certification,
    required this.contractTests,
    required this.security,
    required this.privacy,
    required this.accessibility,
    required this.documentation,
    required this.rollback,
    this.allowed = false,
    this.admitted = false,
    this.accepted = false,
    this.passed = false,
    this.evidenceComplete = false,
    this.certified = false,
    this.released = false,
  });

  /// The registered provider identifier, drawn from the committed icon registry.
  final String providerId;

  /// The certification evidence reference state, drawn from the committed 118.39
  /// versioned connector certification `status_vocabulary` (`UNVERIFIED`).
  final String certification;

  /// The contract-test evidence reference state, drawn from the committed 118.40
  /// expansion contract `suite_contract_vocabulary` (`manifest`).
  final String contractTests;

  /// The security evidence reference state, drawn from the committed 118
  /// security health review reference states (`oauth_tests`).
  final String security;

  /// The privacy evidence reference state, drawn from the committed 118 privacy
  /// health review reference states (`consent`).
  final String privacy;

  /// The accessibility evidence reference state, drawn from the committed 118
  /// accessibility health reference states (`keyboard_complete`).
  final String accessibility;

  /// The documentation evidence reference state, drawn from the committed 112
  /// documentation & support release notes `outputs` (`user_guides`).
  final String documentation;

  /// The rollback evidence reference state, drawn from the committed 116.50
  /// staged beta rollout monitoring `rollback[].rollback_id` (`rb_internal`).
  final String rollback;

  /// Whether the entry claims the connector was allowed into the ecosystem. On
  /// the delayed path this must stay `false`.
  final bool allowed;

  /// Whether the entry claims the connector was admitted. On the delayed path
  /// this must stay `false`.
  final bool admitted;

  /// Whether the entry claims acceptance was granted. On the delayed path this
  /// must stay `false`.
  final bool accepted;

  /// Whether the entry claims the acceptance gate passed. On the delayed path
  /// this must stay `false`.
  final bool passed;

  /// Whether the entry claims the evidence set is complete. On the delayed path
  /// this must stay `false`.
  final bool evidenceComplete;

  /// Whether the entry claims the connector was certified. On the delayed path
  /// this must stay `false`.
  final bool certified;

  /// Whether the entry claims the connector was released. On the delayed path
  /// this must stay `false`.
  final bool released;

  /// The seven canonical evidence dimensions as a name -> value map, so the gate
  /// can test blankness uniformly.
  Map<String, String> get requiredFields => <String, String>{
    'certification': certification,
    'contract_tests': contractTests,
    'security': security,
    'privacy': privacy,
    'accessibility': accessibility,
    'documentation': documentation,
    'rollback': rollback,
  };

  /// The seven acceptance evidence outputs as an output -> value map, so the
  /// gate can test grounding per dimension.
  Map<String, String> get outputFields => requiredFields;
}

/// The frozen acceptance record. `entries` is the declared reference for each
/// registered provider. On the delayed path no entry may claim a live
/// acceptance.
class Sprint118ExpansionAcceptanceRecord {
  const Sprint118ExpansionAcceptanceRecord({
    required this.releaseState,
    required this.entries,
  });

  final String releaseState;
  final List<Sprint118ExpansionAcceptanceEntry> entries;

  List<String> get providerIds => <String>[
    for (final entry in entries) entry.providerId,
  ];

  /// The providers the record claims were allowed. On the delayed path this must
  /// stay empty.
  List<String> get allowedProviders => <String>[
    for (final entry in entries)
      if (entry.allowed) entry.providerId,
  ];

  /// The providers the record claims were admitted. On the delayed path this
  /// must stay empty.
  List<String> get admittedProviders => <String>[
    for (final entry in entries)
      if (entry.admitted) entry.providerId,
  ];

  /// The providers the record claims had acceptance granted. On the delayed path
  /// this must stay empty.
  List<String> get acceptedProviders => <String>[
    for (final entry in entries)
      if (entry.accepted) entry.providerId,
  ];

  /// The providers the record claims passed the acceptance gate. On the delayed
  /// path this must stay empty.
  List<String> get passedProviders => <String>[
    for (final entry in entries)
      if (entry.passed) entry.providerId,
  ];

  /// The providers the record claims were certified. On the delayed path this
  /// must stay empty.
  List<String> get certifiedProviders => <String>[
    for (final entry in entries)
      if (entry.certified) entry.providerId,
  ];

  /// The providers the record claims were released. On the delayed path this
  /// must stay empty.
  List<String> get releasedProviders => <String>[
    for (final entry in entries)
      if (entry.released) entry.providerId,
  ];

  int get allowedCount => entries.where((entry) => entry.allowed).length;

  int get admittedCount => entries.where((entry) => entry.admitted).length;

  int get acceptedCount => entries.where((entry) => entry.accepted).length;

  int get passedCount => entries.where((entry) => entry.passed).length;

  int get certifiedCount => entries.where((entry) => entry.certified).length;

  int get releasedCount => entries.where((entry) => entry.released).length;
}

/// What the committed witnesses actually say. A gate is only as honest as the
/// witnesses it is anchored to.
class Sprint118ExpansionAcceptanceAnchor {
  const Sprint118ExpansionAcceptanceAnchor({
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
    required this.certificationVocabulary,
    required this.contractVocabulary,
    required this.securityVocabulary,
    required this.privacyVocabulary,
    required this.accessibilityVocabulary,
    required this.documentationVocabulary,
    required this.rollbackVocabulary,
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

  /// The certification vocabulary the committed 118.39 versioned connector
  /// certification declares. It grounds the certification evidence dimension.
  final List<String> certificationVocabulary;

  /// The contract-test vocabulary the committed 118.40 expansion contract
  /// declares. It grounds the contract_tests evidence dimension.
  final List<String> contractVocabulary;

  /// The security vocabulary the committed 118 security health review declares.
  /// It grounds the security evidence dimension.
  final List<String> securityVocabulary;

  /// The privacy vocabulary the committed 118 privacy health review declares. It
  /// grounds the privacy evidence dimension.
  final List<String> privacyVocabulary;

  /// The accessibility vocabulary the committed 118 accessibility health
  /// declares. It grounds the accessibility evidence dimension.
  final List<String> accessibilityVocabulary;

  /// The documentation vocabulary the committed 112 documentation & support
  /// release notes declares. It grounds the documentation evidence dimension.
  final List<String> documentationVocabulary;

  /// The rollback vocabulary the committed 116.50 staged beta rollout monitoring
  /// declares. It grounds the rollback evidence dimension.
  final List<String> rollbackVocabulary;

  /// The committed evidence paths that are present and readable on disk.
  final List<String> readableSources;
}

/// The measured result. `pass` means the record is a faithful acceptance
/// freeze; `blocked` means it cannot yet be trusted; `fail` means it contradicts
/// its evidence.
class Sprint118ExpansionAcceptanceReport {
  const Sprint118ExpansionAcceptanceReport({
    required this.state,
    required this.verdict,
    required this.releaseState,
    this.violations = const <String>[],
    this.blockers = const <String>[],
    this.openItems = const <String>[],
    this.declaredProviders = const <String>[],
    this.allowedProviders = const <String>[],
    this.admittedProviders = const <String>[],
    this.acceptedProviders = const <String>[],
    this.passedProviders = const <String>[],
    this.certifiedProviders = const <String>[],
    this.releasedProviders = const <String>[],
    this.allowedCount = 0,
    this.admittedCount = 0,
    this.acceptedCount = 0,
    this.passedCount = 0,
    this.certifiedCount = 0,
    this.releasedCount = 0,
    this.expansionBudgetFrozen = false,
  });

  final Sprint118ExpansionAcceptanceState state;
  final String verdict;
  final String releaseState;

  final List<String> violations;
  final List<String> blockers;
  final List<String> openItems;
  final List<String> declaredProviders;
  final List<String> allowedProviders;
  final List<String> admittedProviders;
  final List<String> acceptedProviders;
  final List<String> passedProviders;
  final List<String> certifiedProviders;
  final List<String> releasedProviders;
  final int allowedCount;
  final int admittedCount;
  final int acceptedCount;
  final int passedCount;
  final int certifiedCount;
  final int releasedCount;
  final bool expansionBudgetFrozen;

  /// Whether the record may be treated as a frozen acceptance freeze. Only a
  /// genuine `pass` allows it.
  bool get recordVerified => state == Sprint118ExpansionAcceptanceState.pass;

  String get externalGates =>
      Sprint118ExpansionAcceptanceContract.externalGates;
}

/// The fixed vocabulary and committed witness set for step 118.42.
abstract final class Sprint118ExpansionAcceptanceContract {
  const Sprint118ExpansionAcceptanceContract._();

  static const String canonicalStep = '118.42';
  static const String title = 'Expansion Acceptance Gate';

  static const String manifestPath =
      'docs/planning/v1.3/sprint_118_expansion_acceptance_gate.json';
  static const String ledgerPath =
      'docs/sprints/sprint-118-account-cloud-center-stability.md';

  /// The committed 118.2 charter that declares the frozen expansion budget.
  static const String charterManifestPath =
      'docs/planning/v1.3/sprint_118_stability_expansion_charter.json';

  /// The committed 118.3 certified connector snapshot this record rests on.
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

  /// The committed 118.39 versioned connector certification that grounds the
  /// certification evidence dimension.
  static const String certificationManifestPath =
      'docs/planning/v1.3/sprint_118_versioned_connector_certification.json';

  /// The committed 118.40 expansion contract that grounds the contract_tests
  /// evidence dimension.
  static const String contractManifestPath =
      'docs/planning/v1.3/sprint_118_expansion_contract_e2e.json';

  /// The committed 118 security health review that grounds the security evidence
  /// dimension.
  static const String securityHealthPath =
      'docs/planning/v1.3/sprint_118_security_health_review.json';

  /// The committed 118 privacy health review that grounds the privacy evidence
  /// dimension.
  static const String privacyHealthPath =
      'docs/planning/v1.3/sprint_118_privacy_health_review.json';

  /// The committed 118 accessibility health that grounds the accessibility
  /// evidence dimension.
  static const String accessibilityHealthPath =
      'docs/planning/v1.3/sprint_118_accessibility_health.json';

  /// The committed 112 documentation & support release notes that ground the
  /// documentation evidence dimension.
  static const String documentationManifestPath =
      'docs/planning/v1.2/sprint_112_documentation_support_release_notes.json';

  /// The committed 116.50 staged beta rollout monitoring that grounds the
  /// rollback evidence dimension.
  static const String stagedBetaRolloutPath =
      'docs/planning/v1.2/sprint_116_staged_beta_rollout_monitoring.json';

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

  /// The number of canonical acceptance evidence dimensions the objective names.
  static const int expectedOutputCount = 7;

  /// The marker an entry declares when no committed witness names a reference
  /// state for a dimension. A record that uses it records an honest upstream gap
  /// rather than inventing a state.
  static const String noReferenceState = 'no_reference_state';

  /// The canonical evidence set each entry must carry, so a record cannot drop a
  /// dimension and still read as complete.
  static const List<String> requiredFields = <String>[
    'certification',
    'contract_tests',
    'security',
    'privacy',
    'accessibility',
    'documentation',
    'rollback',
  ];

  /// The seven canonical acceptance evidence dimensions named by the objective,
  /// in canonical order.
  static const List<String> requiredOutputs = requiredFields;

  /// The committed evidence file each canonical evidence dimension is anchored
  /// to, in canonical order.
  static const List<String> canonicalSources = <String>[
    certificationManifestPath,
    contractManifestPath,
    securityHealthPath,
    privacyHealthPath,
    accessibilityHealthPath,
    documentationManifestPath,
    stagedBetaRolloutPath,
  ];

  /// The committed evidence files every record is anchored to. All must be
  /// readable.
  static const List<String> witnessSources = <String>[
    charterManifestPath,
    snapshotManifestPath,
    approvalGateManifestPath,
    iconRegistryManifestPath,
    registryReconciliationManifestPath,
    snapshotLockManifestPath,
    registryEvidencePath,
    certificationManifestPath,
    contractManifestPath,
    securityHealthPath,
    privacyHealthPath,
    accessibilityHealthPath,
    documentationManifestPath,
    stagedBetaRolloutPath,
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

  /// The declared reference state for the certification evidence dimension. No
  /// connector is certified on the delayed path, so the honest reference is the
  /// committed 118.39 versioned connector certification first status
  /// (`UNVERIFIED`).
  static const String certificationToken = 'UNVERIFIED';

  /// The declared reference state for the contract_tests evidence dimension. No
  /// end-to-end suite has run live on the delayed path, so the honest reference
  /// is the committed 118.40 expansion contract first suite (`manifest`).
  static const String contractTestsToken = 'manifest';

  /// The declared reference state for the security evidence dimension. No live
  /// security observation is recorded on the delayed path, so the honest
  /// reference is the committed 118 security health review first reference state
  /// (`oauth_tests`).
  static const String securityToken = 'oauth_tests';

  /// The declared reference state for the privacy evidence dimension. No live
  /// privacy observation is recorded on the delayed path, so the honest
  /// reference is the committed 118 privacy health review first reference state
  /// (`consent`).
  static const String privacyToken = 'consent';

  /// The declared reference state for the accessibility evidence dimension. No
  /// live accessibility observation is recorded on the delayed path, so the
  /// honest reference is the committed 118 accessibility health first reference
  /// state (`keyboard_complete`).
  static const String accessibilityToken = 'keyboard_complete';

  /// The declared reference state for the documentation evidence dimension. No
  /// documentation has been published on the delayed path, so the honest
  /// reference is the committed 112 documentation & support release notes first
  /// output (`user_guides`).
  static const String documentationToken = 'user_guides';

  /// The declared reference state for the rollback evidence dimension. No
  /// rollback has been executed on the delayed path, so the honest reference is
  /// the committed 116.50 staged beta rollout monitoring first rollback
  /// (`rb_internal`).
  static const String rollbackToken = 'rb_internal';

  /// The committed witness vocabulary that grounds each canonical evidence
  /// dimension, in canonical order.
  static List<List<String>> outputVocabularies(
    Sprint118ExpansionAcceptanceAnchor anchor,
  ) => <List<String>>[
    anchor.certificationVocabulary,
    anchor.contractVocabulary,
    anchor.securityVocabulary,
    anchor.privacyVocabulary,
    anchor.accessibilityVocabulary,
    anchor.documentationVocabulary,
    anchor.rollbackVocabulary,
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
  /// A witness grounds a token when it names the token exactly (`UNVERIFIED`,
  /// `manifest`, `oauth_tests`), or when every underscore-separated part of a
  /// compound token is itself a witness-declared value. The vocabulary is
  /// measured from the committed witnesses, so a reference state cannot be
  /// invented into the list without a witness to ground it.
  static bool grounds(List<String> vocabulary, String token) {
    if (vocabulary.contains(token)) return true;
    final parts = token.split('_');
    if (parts.length < 2) return false;
    return parts.every(vocabulary.contains);
  }

  /// The committed witness vocabulary for a canonical evidence dimension, or the
  /// empty list when the dimension is unknown.
  static List<String> vocabularyFor(
    Sprint118ExpansionAcceptanceAnchor anchor,
    String output,
  ) {
    final index = requiredOutputs.indexOf(output);
    if (index < 0) return const <String>[];
    return outputVocabularies(anchor)[index];
  }

  /// The committed source for a canonical evidence dimension, or `''` if
  /// unknown.
  static String sourceFor(String output) {
    final index = requiredOutputs.indexOf(output);
    return index < 0 ? '' : canonicalSources[index];
  }

  /// The canonical frozen record: every registered provider, each anchored to
  /// the committed witness vocabularies, claiming nothing live.
  static Sprint118ExpansionAcceptanceRecord get canonicalRecord =>
      Sprint118ExpansionAcceptanceRecord(
        releaseState: delayedReleaseState,
        entries: <Sprint118ExpansionAcceptanceEntry>[
          for (final id in canonicalProviders)
            Sprint118ExpansionAcceptanceEntry(
              providerId: id,
              certification: certificationToken,
              contractTests: contractTestsToken,
              security: securityToken,
              privacy: privacyToken,
              accessibility: accessibilityToken,
              documentation: documentationToken,
              rollback: rollbackToken,
            ),
        ],
      );

  static Sprint118ExpansionAcceptanceRecord get authorizedRecord =>
      Sprint118ExpansionAcceptanceRecord(
        releaseState: authorizedReleaseState,
        entries: <Sprint118ExpansionAcceptanceEntry>[
          for (final id in canonicalProviders)
            Sprint118ExpansionAcceptanceEntry(
              providerId: id,
              certification:
                  id == GithubAppReleaseAuthorization.authorizedProviderId
                  ? GithubAppReleaseAuthorization.authorizedStatus
                  : certificationToken,
              contractTests: contractTestsToken,
              security: securityToken,
              privacy: privacyToken,
              accessibility: accessibilityToken,
              documentation: documentationToken,
              rollback: rollbackToken,
              certified:
                  id == GithubAppReleaseAuthorization.authorizedProviderId,
            ),
        ],
      );
}

/// Reads the committed witnesses for step 118.42. Never invents: an unreadable
/// witness yields `null`, which the gate reports as blocked rather than as a
/// pass.
class Sprint118ExpansionAcceptanceLoader {
  const Sprint118ExpansionAcceptanceLoader();

  Sprint118ExpansionAcceptanceAnchor? loadAnchor() {
    final charter = _read(
      Sprint118ExpansionAcceptanceContract.charterManifestPath,
    );
    final snapshot = _read(
      Sprint118ExpansionAcceptanceContract.snapshotManifestPath,
    );
    final approval = _read(
      Sprint118ExpansionAcceptanceContract.approvalGateManifestPath,
    );
    final icon = _read(
      Sprint118ExpansionAcceptanceContract.iconRegistryManifestPath,
    );
    final reconciliation = _read(
      Sprint118ExpansionAcceptanceContract.registryReconciliationManifestPath,
    );
    final lock = _read(
      Sprint118ExpansionAcceptanceContract.snapshotLockManifestPath,
    );
    final registry = _read(
      Sprint118ExpansionAcceptanceContract.registryEvidencePath,
    );
    final certification = _read(
      Sprint118ExpansionAcceptanceContract.certificationManifestPath,
    );
    final contract = _read(
      Sprint118ExpansionAcceptanceContract.contractManifestPath,
    );
    final security = _read(
      Sprint118ExpansionAcceptanceContract.securityHealthPath,
    );
    final privacy = _read(
      Sprint118ExpansionAcceptanceContract.privacyHealthPath,
    );
    final accessibility = _read(
      Sprint118ExpansionAcceptanceContract.accessibilityHealthPath,
    );
    final documentation = _read(
      Sprint118ExpansionAcceptanceContract.documentationManifestPath,
    );
    final stagedBeta = _read(
      Sprint118ExpansionAcceptanceContract.stagedBetaRolloutPath,
    );
    if (charter == null ||
        snapshot == null ||
        approval == null ||
        icon == null ||
        reconciliation == null ||
        lock == null ||
        registry == null ||
        certification == null ||
        contract == null ||
        security == null ||
        privacy == null ||
        accessibility == null ||
        documentation == null ||
        stagedBeta == null) {
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

    final sources = Sprint118ExpansionAcceptanceContract.witnessSources.toSet();

    return Sprint118ExpansionAcceptanceAnchor(
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
      certificationVocabulary: _strings(certification['status_vocabulary']),
      contractVocabulary: _strings(contract['suite_contract_vocabulary']),
      securityVocabulary: _column(security['entries'], 'reference_state'),
      privacyVocabulary: _column(privacy['entries'], 'reference_state'),
      accessibilityVocabulary: _column(
        accessibility['entries'],
        'reference_state',
      ),
      documentationVocabulary: _strings(documentation['outputs']),
      rollbackVocabulary: _column(stagedBeta['rollback'], 'rollback_id'),
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

  /// Collect a string field from a list of map rows, de-duplicated in first-seen
  /// order.
  static List<String> _column(Object? rows, String key) {
    final out = <String>[];
    if (rows is List) {
      for (final row in rows) {
        if (row is Map<String, dynamic>) {
          final value = row[key];
          if (value is String &&
              value.trim().isNotEmpty &&
              !out.contains(value)) {
            out.add(value);
          }
        }
      }
    }
    return out;
  }

  static int _int(Object? value) => value is int ? value : 0;
}

/// The fail-closed expansion acceptance gate for step 118.42.
class Sprint118ExpansionAcceptanceGate {
  const Sprint118ExpansionAcceptanceGate();

  Sprint118ExpansionAcceptanceReport evaluate() {
    final authorization = GithubAppReleaseAuthorization.load();
    return evaluateWith(
      const Sprint118ExpansionAcceptanceLoader().loadAnchor(),
      authorization == null
          ? Sprint118ExpansionAcceptanceContract.canonicalRecord
          : Sprint118ExpansionAcceptanceContract.authorizedRecord,
      authorization: authorization,
    );
  }

  Sprint118ExpansionAcceptanceReport evaluateWith(
    Sprint118ExpansionAcceptanceAnchor? anchor,
    Sprint118ExpansionAcceptanceRecord record, {
    GithubAppReleaseAuthorization? authorization,
  }) {
    if (anchor == null) {
      return Sprint118ExpansionAcceptanceReport(
        state: Sprint118ExpansionAcceptanceState.blocked,
        verdict: 'SPRINT_118_EXPANSION_ACCEPTANCE_EVIDENCE_UNREADABLE',
        releaseState: record.releaseState,
        blockers: const <String>[
          'committed_expansion_acceptance_evidence_unreadable',
        ],
        openItems: const <String>[
          'committed_expansion_acceptance_evidence_unreadable',
        ],
      );
    }

    final violations = <String>[];
    final blockers = <String>[];
    final openItems = <String>[];
    final authorized =
        authorization?.isValid == true &&
        record.releaseState ==
            Sprint118ExpansionAcceptanceContract.authorizedReleaseState;

    final frozen =
        anchor.charterMaxNewCertified == 0 &&
        anchor.charterCurrentlyCertified == 0;

    // (1) The 118.2 charter anchor must be a genuine complete charter.
    if (anchor.charterState !=
            Sprint118ExpansionAcceptanceContract.requiredCharterState ||
        anchor.charterVerdict !=
            Sprint118ExpansionAcceptanceContract.requiredCharterVerdict) {
      blockers.add('charter_not_complete:${anchor.charterVerdict}');
    }

    // (2) The 118.3 snapshot anchor must be a genuine frozen pass.
    if (anchor.snapshotState !=
            Sprint118ExpansionAcceptanceContract.requiredSnapshotState ||
        (!authorized &&
            anchor.snapshotVerdict !=
                Sprint118ExpansionAcceptanceContract.requiredSnapshotVerdict) ||
        (authorized &&
            anchor.snapshotVerdict !=
                GithubAppReleaseAuthorization.authorizedSnapshotVerdict)) {
      blockers.add('snapshot_not_frozen:${anchor.snapshotVerdict}');
    }

    // (3) The 117.45 approval gate must record the delay decision, read with the
    // owner's exact grammar. If it is not a delay, the anchor is untrustworthy.
    if (!authorized &&
        anchor.approvalDecision !=
            Sprint118ExpansionAcceptanceContract.requiredApprovalDecision) {
      blockers.add('approval_gate_not_delay:${anchor.approvalDecision}');
    }

    // (4) The registered provider set must reconcile across the icon registry,
    // the 116.3 reconciliation, the frozen snapshot, the charter, the 117.41
    // registry evidence, and the 117.4 snapshot lock.
    if (anchor.registeredProviders.length !=
            Sprint118ExpansionAcceptanceContract.expectedProviderCount ||
        anchor.registryExpectedCount !=
            Sprint118ExpansionAcceptanceContract.expectedProviderCount ||
        anchor.snapshotRegistered !=
            Sprint118ExpansionAcceptanceContract.expectedProviderCount ||
        anchor.charterRegisteredProviders !=
            Sprint118ExpansionAcceptanceContract.expectedProviderCount ||
        anchor.registryEvidenceProviderCount !=
            Sprint118ExpansionAcceptanceContract.expectedProviderCount ||
        anchor.snapshotLockLockedCount !=
            Sprint118ExpansionAcceptanceContract.expectedProviderCount) {
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
        Sprint118ExpansionAcceptanceContract.expectedProviderCount) {
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

    // (6) The release state must agree with the anchor.
    if (!authorized && record.releaseState != anchor.releaseState) {
      violations.add(
        'release_state_mismatch:anchor=${anchor.releaseState}:'
        'record=${record.releaseState}',
      );
    }
    if (!authorized &&
        record.releaseState !=
            Sprint118ExpansionAcceptanceContract.delayedReleaseState) {
      violations.add(
        'expansion_acceptance_not_on_delayed_path:${record.releaseState}',
      );
    }

    final delayed =
        record.releaseState ==
        Sprint118ExpansionAcceptanceContract.delayedReleaseState;

    if (!delayed && !authorized) {
      violations.add('expansion_acceptance_release_state_not_authorized');
    }

    // (7) On the delayed path an authorized release execution and an unblocked
    // release are behavior that never ran.
    if (delayed && anchor.executionAuthorized) {
      violations.add(
        'expansion_acceptance_execution_authorized_on_delayed_path',
      );
    }
    if (delayed && !anchor.releaseBlocked) {
      violations.add(
        'expansion_acceptance_release_not_blocked_on_delayed_path',
      );
    }

    // (8) The expansion budget must stay frozen: no new certified connector and
    // no already-certified connector while the release is delayed.
    if (!frozen && !authorized) {
      violations.add(
        'expansion_acceptance_expansion_budget_not_frozen:max_new='
        '${anchor.charterMaxNewCertified}:'
        'currently=${anchor.charterCurrentlyCertified}',
      );
    }
    // The frozen 118.3 snapshot must declare zero certified connectors. A
    // snapshot that already certifies a connector contradicts the delayed path.
    if (!authorized && anchor.snapshotCertified != 0) {
      violations.add(
        'expansion_acceptance_snapshot_certified_nonzero:'
        '${anchor.snapshotCertified}',
      );
    }

    // (9) Every registered provider must appear exactly once, and each entry
    // must carry all seven canonical evidence dimensions non-blank with every
    // dimension grounded by its committed witness vocabulary.
    final declared = <String, int>{};
    for (final entry in record.entries) {
      declared[entry.providerId] = (declared[entry.providerId] ?? 0) + 1;
    }
    for (final entry in record.entries) {
      final id = entry.providerId;
      if (!anchor.registeredProviders.contains(id)) {
        violations.add('expansion_acceptance_provider_unknown:$id');
      }
      for (final field in Sprint118ExpansionAcceptanceContract.requiredFields) {
        final value = entry.requiredFields[field] ?? '';
        if (value.trim().isEmpty) {
          violations.add('entry_blank_$field:$id');
        }
      }
      for (final output
          in Sprint118ExpansionAcceptanceContract.requiredOutputs) {
        final token = entry.outputFields[output] ?? '';
        final vocabulary = Sprint118ExpansionAcceptanceContract.vocabularyFor(
          anchor,
          output,
        );
        final grounded =
            token == Sprint118ExpansionAcceptanceContract.noReferenceState ||
            Sprint118ExpansionAcceptanceContract.grounds(vocabulary, token);
        if (token.trim().isEmpty || !grounded) {
          violations.add('reference_state_invalid:$output:$id');
        }
        if (token == Sprint118ExpansionAcceptanceContract.noReferenceState) {
          openItems.add('upstream_state_vocabulary_gap:$output:$id');
        }
      }
      // A connector is never allowed into the ecosystem without an authorized
      // release.
      if (delayed && entry.allowed) {
        violations.add(
          'expansion_acceptance_allowed_claimed_on_delayed_path:$id',
        );
      }
      // A connector is never admitted without an authorized release.
      if (delayed && entry.admitted) {
        violations.add(
          'expansion_acceptance_admitted_claimed_on_delayed_path:$id',
        );
      }
      // Acceptance is never granted without complete live evidence.
      if (delayed && entry.accepted) {
        violations.add(
          'expansion_acceptance_accepted_claimed_on_delayed_path:$id',
        );
      }
      // The acceptance gate never passes without complete live evidence.
      if (delayed && entry.passed) {
        violations.add(
          'expansion_acceptance_passed_claimed_on_delayed_path:$id',
        );
      }
      // Evidence is never complete without live provider verification.
      if (delayed && entry.evidenceComplete) {
        violations.add(
          'expansion_acceptance_evidence_complete_claimed_on_delayed_path:$id',
        );
      }
      // A connector is never certified without live provider verification.
      if (delayed && entry.certified) {
        violations.add(
          'expansion_acceptance_certified_claimed_on_delayed_path:$id',
        );
      }
      // A connector is never released without an authorized release.
      if (delayed && entry.released) {
        violations.add('expansion_acceptance_released_claimed:$id');
      }
      if (authorized &&
          id == GithubAppReleaseAuthorization.authorizedProviderId) {
        if (!entry.certified || entry.released) {
          // The authorized overlay deliberately stops at certification; a
          // public release/publication is still outside this scope.
          violations.add('github_app_acceptance_release_claimed');
        }
      } else if (authorized &&
          (entry.allowed ||
              entry.admitted ||
              entry.accepted ||
              entry.passed ||
              entry.evidenceComplete ||
              entry.certified ||
              entry.released)) {
        violations.add('non_github_provider_acceptance_claim:$id');
      }
    }
    for (final id in declared.keys) {
      if (declared[id]! > 1) {
        violations.add('expansion_acceptance_provider_duplicate:$id');
      }
    }
    for (final id in anchor.registeredProviders) {
      if (!declared.containsKey(id)) {
        violations.add('expansion_acceptance_provider_missing:$id');
      }
    }

    // (10) Every committed evidence source must be readable.
    for (final source
        in Sprint118ExpansionAcceptanceContract.witnessSources.toSet()) {
      if (!anchor.readableSources.contains(source)) {
        violations.add('required_source_unreadable:$source');
      }
    }

    final allItems = <String>[...violations, ...blockers, ...openItems];
    final providers = record.providerIds;

    // An untrustworthy anchor short-circuits: if a committed witness is not a
    // genuine pass, the entry-level findings cannot be trusted either, so the
    // honest answer is `blocked`, not `fail`.
    if (blockers.isNotEmpty) {
      return Sprint118ExpansionAcceptanceReport(
        state: Sprint118ExpansionAcceptanceState.blocked,
        verdict: 'SPRINT_118_EXPANSION_ACCEPTANCE_BLOCKED_UPSTREAM',
        releaseState: record.releaseState,
        violations: violations,
        blockers: blockers,
        openItems: allItems,
        declaredProviders: providers,
        allowedProviders: record.allowedProviders,
        admittedProviders: record.admittedProviders,
        acceptedProviders: record.acceptedProviders,
        passedProviders: record.passedProviders,
        certifiedProviders: record.certifiedProviders,
        releasedProviders: record.releasedProviders,
        allowedCount: record.allowedCount,
        admittedCount: record.admittedCount,
        acceptedCount: record.acceptedCount,
        passedCount: record.passedCount,
        certifiedCount: record.certifiedCount,
        releasedCount: record.releasedCount,
        expansionBudgetFrozen: frozen,
      );
    }
    if (violations.isNotEmpty) {
      return Sprint118ExpansionAcceptanceReport(
        state: Sprint118ExpansionAcceptanceState.fail,
        verdict: 'SPRINT_118_EXPANSION_ACCEPTANCE_EVIDENCE_VIOLATION',
        releaseState: record.releaseState,
        violations: violations,
        blockers: blockers,
        openItems: allItems,
        declaredProviders: providers,
        allowedProviders: record.allowedProviders,
        admittedProviders: record.admittedProviders,
        acceptedProviders: record.acceptedProviders,
        passedProviders: record.passedProviders,
        certifiedProviders: record.certifiedProviders,
        releasedProviders: record.releasedProviders,
        allowedCount: record.allowedCount,
        admittedCount: record.admittedCount,
        acceptedCount: record.acceptedCount,
        passedCount: record.passedCount,
        certifiedCount: record.certifiedCount,
        releasedCount: record.releasedCount,
        expansionBudgetFrozen: frozen,
      );
    }
    return Sprint118ExpansionAcceptanceReport(
      state: Sprint118ExpansionAcceptanceState.pass,
      verdict: authorized
          ? 'EXPANSION_ACCEPTANCE_GATE_AUTHORIZED_LOCAL'
          : 'EXPANSION_ACCEPTANCE_GATE_VERIFIED_LOCAL',
      releaseState: record.releaseState,
      openItems: allItems,
      declaredProviders: providers,
      allowedProviders: record.allowedProviders,
      admittedProviders: record.admittedProviders,
      acceptedProviders: record.acceptedProviders,
      passedProviders: record.passedProviders,
      certifiedProviders: record.certifiedProviders,
      releasedProviders: record.releasedProviders,
      allowedCount: record.allowedCount,
      admittedCount: record.admittedCount,
      acceptedCount: record.acceptedCount,
      passedCount: record.passedCount,
      certifiedCount: record.certifiedCount,
      releasedCount: record.releasedCount,
      expansionBudgetFrozen: frozen,
    );
  }
}
