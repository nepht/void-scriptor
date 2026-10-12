/// Fail-closed versioned connector certification for roadmap step 118.39 --
/// Versioned Connector Certification.
///
/// Objective (external canonical `sprint_118.json`): record evidence, version,
/// status, limitations, reviewer, recheck date, and visibility for every
/// expansion connector. The canonical field set is exactly eight items:
/// `provider_id`, `connector_version`, `status`, `evidence`, `limitations`,
/// `reviewer`, `recheck_date`, and `visibility`.
///
/// The release is delayed. No connector is certified (118.3 froze `CERTIFIED: 0`
/// of `32` registered; the committed 117.41 registry evidence records
/// `UNVERIFIED: 32`, `EXPOSED: 0`, `WITHHELD: 32`), the 118.2 charter froze an
/// expansion budget of zero new certified connectors out of 32 registered, and
/// the committed 117.45 approval gate records `decision=delay`,
/// `approval_state=PENDING_CHOIRUDIN`, `execution_authorized=false`, and
/// `release_blocked=true`. No connector version has been certified live, no
/// certification evidence has been recorded against a live provider, no live
/// review has been performed, and no connector has been exposed or released. A
/// versioned connector certification written against that state therefore has
/// exactly one honest shape: enumerate all 32 registered providers, anchor each
/// of the seven certification outputs to a committed witness vocabulary, claim
/// nothing live, and certify no connector.
///
/// The gate is fail-closed on these families of rules:
///
/// * The committed 118.2 charter anchor must be a genuine complete charter and
///   its expansion budget must stay frozen (`max_new_certified_connectors` and
///   `currently_certified` both zero). A certification record anchored to an
///   unfrozen budget certifies a connector nobody authorized.
/// * The committed 118.3 certified connector snapshot must be a genuine frozen
///   pass (`CERTIFIED_CONNECTOR_SNAPSHOT_FROZEN_LOCAL`). A certification record
///   anchored to an unfrozen snapshot rests on a release nobody recorded.
/// * The committed 117.45 approval gate must record the delay decision
///   (`decision == delay`), read with the owner's exact grammar, never
///   case-folded or trimmed into agreement. If it is not a delay, the anchor is
///   untrustworthy and the honest answer is `blocked`, not `fail`.
/// * The registered provider set must reconcile: the icon-registry provider
///   union, the 116.3 reconciliation count, the frozen snapshot count, the
///   charter count, the 117.41 registry evidence count, and the 117.4 snapshot
///   lock count must all agree. A certification record over a drifting registry
///   is not a certification record.
/// * The committed 117.41 registry visibility counts must reconcile
///   (`EXPOSED` plus `WITHHELD` equals the registered count) and must record
///   zero exposed providers while the release is delayed. A registry that
///   already exposes a connector contradicts the frozen zero-certified state.
/// * Every registered provider must appear exactly once. A record that drops a
///   provider, invents `telepathy`, or duplicates `stripe` is not a
///   certification record.
/// * Every entry must carry all eight canonical fields non-blank, and each of
///   the seven certification outputs must be grounded by the committed witness
///   vocabulary for that output, so a certification value cannot be invented
///   into the list without a witness to ground it.
/// * On the delayed path a certified connector, a live-verified evidence
///   record, a live review, an exposed connector, a released connector, a
///   published connector, a `CERTIFIED`/`LIMITED` status, or an `EXPOSED`
///   visibility describe behavior that never ran. This is refused by name, per
///   entry.
///
/// **A provider is never recorded as a versioned certified connector without
/// live provider verification and an authorized release.** When no connector
/// version is certified and no release is authorized, the only honest
/// certification record states the committed reference for each output and
/// claims nothing live; any certified, verified, reviewed, exposed, released,
/// or published claim is refused by name.
///
/// The output vocabulary is *derived from committed witnesses* (the 116.2
/// certification policy `certification_statuses`, `evidence_requirements`, and
/// `limitations`, the 116.2 certification record `reviewer` and
/// `expires_or_recheck_at`, the 117.4 snapshot lock
/// `recorded_connector_versions`, and the 117.41 registry evidence
/// `required_fields` and `visibility_counts`), and the source for each output is
/// a committed manifest, not copied by hand, so the record and its witnesses
/// cannot drift apart silently.
///
/// Connector certification, live evidence verification, live review, provider
/// exposure, connector release, credential access, and publication remain
/// `DEFERRED-EXTERNAL`; this record freezes local declared state and executes
/// none of it.
library;

import 'dart:convert';
import 'dart:io';

import 'github_app_release_authorization.dart';

/// The three states a versioned connector certification can rest in. `blocked`
/// is the honest resting state for "this record cannot yet be trusted", and it
/// is distinct from `fail`, which means the record contradicts its own evidence.
enum Sprint118VersionedCertificationState { pass, fail, blocked }

/// One frozen versioned connector certification entry: the declared reference
/// for each of the seven canonical certification outputs of a single registered
/// provider.
///
/// `certified`, `verified`, `reviewed`, `exposed`, `released`, and `published`
/// are deliberately *not* among the eight required fields; they are the flags
/// the gate refuses when set, so that a declared reference certification can be
/// recorded while never being read as a certified connector, a live-verified
/// evidence record, a live review, an exposed connector, a released connector,
/// or a published connector.
class Sprint118VersionedConnectorEntry {
  const Sprint118VersionedConnectorEntry({
    required this.providerId,
    required this.connectorVersion,
    required this.status,
    required this.evidence,
    required this.limitations,
    required this.reviewer,
    required this.recheckDate,
    required this.visibility,
    this.certified = false,
    this.verified = false,
    this.reviewed = false,
    this.exposed = false,
    this.released = false,
    this.published = false,
  });

  /// The registered provider identifier, drawn from the committed icon registry.
  final String providerId;

  /// The connector-version reference state, drawn from the committed 117.4
  /// snapshot lock `recorded_connector_versions`.
  final String connectorVersion;

  /// The status reference state, drawn from the committed 116.2 certification
  /// policy `certification_statuses`.
  final String status;

  /// The evidence reference state, drawn from the committed 117.41 registry
  /// evidence `required_fields`.
  final String evidence;

  /// The limitations reference state, drawn from the committed 116.2
  /// certification policy `limitations`.
  final String limitations;

  /// The reviewer reference state, drawn from the committed 116.2 certification
  /// record `reviewer`.
  final String reviewer;

  /// The recheck-date reference state, drawn from the committed 116.2
  /// certification record `expires_or_recheck_at`.
  final String recheckDate;

  /// The visibility reference state, drawn from the committed 117.41 registry
  /// evidence `visibility_counts`.
  final String visibility;

  /// Whether the entry claims the connector was certified. On the delayed path
  /// this must stay `false`.
  final bool certified;

  /// Whether the entry claims evidence was verified live. On the delayed path
  /// this must stay `false`.
  final bool verified;

  /// Whether the entry claims a live review was performed. On the delayed path
  /// this must stay `false`.
  final bool reviewed;

  /// Whether the entry claims the connector was exposed. On the delayed path
  /// this must stay `false`.
  final bool exposed;

  /// Whether the entry claims the connector was released. On the delayed path
  /// this must stay `false`.
  final bool released;

  /// Whether the entry claims the connector was published. On the delayed path
  /// this must stay `false`.
  final bool published;

  /// The eight canonical fields as a name -> value map, so the gate can test
  /// blankness uniformly.
  Map<String, String> get requiredFields => <String, String>{
    'provider_id': providerId,
    'connector_version': connectorVersion,
    'status': status,
    'evidence': evidence,
    'limitations': limitations,
    'reviewer': reviewer,
    'recheck_date': recheckDate,
    'visibility': visibility,
  };

  /// The seven certification outputs as a field -> value map, so the gate can
  /// test grounding per output.
  Map<String, String> get outputFields => <String, String>{
    'connector_version': connectorVersion,
    'status': status,
    'evidence': evidence,
    'limitations': limitations,
    'reviewer': reviewer,
    'recheck_date': recheckDate,
    'visibility': visibility,
  };
}

/// The frozen versioned connector certification. `entries` is the declared
/// reference for each registered provider. On the delayed path no entry may
/// claim a live certification.
class Sprint118VersionedCertificationRecord {
  const Sprint118VersionedCertificationRecord({
    required this.releaseState,
    required this.entries,
  });

  final String releaseState;
  final List<Sprint118VersionedConnectorEntry> entries;

  List<String> get providerIds => <String>[
    for (final entry in entries) entry.providerId,
  ];

  /// The providers the record claims were certified. On the delayed path this
  /// must stay empty.
  List<String> get certifiedProviders => <String>[
    for (final entry in entries)
      if (entry.certified) entry.providerId,
  ];

  /// The providers the record claims were exposed. On the delayed path this
  /// must stay empty.
  List<String> get exposedProviders => <String>[
    for (final entry in entries)
      if (entry.exposed) entry.providerId,
  ];

  /// The providers the record claims were released. On the delayed path this
  /// must stay empty.
  List<String> get releasedProviders => <String>[
    for (final entry in entries)
      if (entry.released) entry.providerId,
  ];

  int get certifiedCount => entries.where((entry) => entry.certified).length;

  int get exposedCount => entries.where((entry) => entry.exposed).length;

  int get releasedCount => entries.where((entry) => entry.released).length;
}

/// What the committed witnesses actually say. A gate is only as honest as the
/// witnesses it is anchored to.
class Sprint118VersionedCertificationAnchor {
  const Sprint118VersionedCertificationAnchor({
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
    required this.connectorVersionVocabulary,
    required this.statusVocabulary,
    required this.evidenceVocabulary,
    required this.limitationsVocabulary,
    required this.reviewerVocabulary,
    required this.recheckDateVocabulary,
    required this.visibilityVocabulary,
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

  /// The connector-version vocabulary the committed 117.4 snapshot lock
  /// declares. It grounds the connector-version output.
  final List<String> connectorVersionVocabulary;

  /// The status vocabulary the committed 116.2 certification policy declares. It
  /// grounds the status output.
  final List<String> statusVocabulary;

  /// The evidence vocabulary the committed 117.41 registry evidence declares. It
  /// grounds the evidence output.
  final List<String> evidenceVocabulary;

  /// The limitations vocabulary the committed 116.2 certification policy
  /// declares. It grounds the limitations output.
  final List<String> limitationsVocabulary;

  /// The reviewer vocabulary the committed 116.2 certification record declares.
  /// It grounds the reviewer output.
  final List<String> reviewerVocabulary;

  /// The recheck-date vocabulary the committed 116.2 certification record
  /// declares. It grounds the recheck-date output.
  final List<String> recheckDateVocabulary;

  /// The visibility vocabulary the committed 117.41 registry evidence declares.
  /// It grounds the visibility output.
  final List<String> visibilityVocabulary;

  /// The committed evidence paths that are present and readable on disk.
  final List<String> readableSources;
}

/// The measured result. `pass` means the record is a faithful certification
/// freeze; `blocked` means it cannot yet be trusted; `fail` means it contradicts
/// its evidence.
class Sprint118VersionedCertificationReport {
  const Sprint118VersionedCertificationReport({
    required this.state,
    required this.verdict,
    required this.releaseState,
    this.violations = const <String>[],
    this.blockers = const <String>[],
    this.openItems = const <String>[],
    this.declaredProviders = const <String>[],
    this.certifiedProviders = const <String>[],
    this.exposedProviders = const <String>[],
    this.releasedProviders = const <String>[],
    this.certifiedCount = 0,
    this.exposedCount = 0,
    this.releasedCount = 0,
    this.expansionBudgetFrozen = false,
  });

  final Sprint118VersionedCertificationState state;
  final String verdict;
  final String releaseState;

  final List<String> violations;
  final List<String> blockers;
  final List<String> openItems;
  final List<String> declaredProviders;
  final List<String> certifiedProviders;
  final List<String> exposedProviders;
  final List<String> releasedProviders;
  final int certifiedCount;
  final int exposedCount;
  final int releasedCount;
  final bool expansionBudgetFrozen;

  /// Whether the record may be treated as a frozen certification record. Only a
  /// genuine `pass` allows it.
  bool get certificationVerified =>
      state == Sprint118VersionedCertificationState.pass;

  String get externalGates =>
      Sprint118VersionedCertificationContract.externalGates;
}

/// The fixed vocabulary and committed witness set for step 118.39.
abstract final class Sprint118VersionedCertificationContract {
  const Sprint118VersionedCertificationContract._();

  static const String canonicalStep = '118.39';
  static const String title = 'Versioned Connector Certification';

  static const String manifestPath =
      'docs/planning/v1.3/sprint_118_versioned_connector_certification.json';
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

  /// The committed 116.2 certification policy that grounds the status,
  /// evidence, limitations, reviewer, and recheck-date outputs.
  static const String certificationPolicyManifestPath =
      'docs/planning/v1.2/sprint_116_certification_policy.json';

  /// The committed 117.4 certification snapshot lock that grounds the
  /// connector-version output.
  static const String snapshotLockManifestPath =
      'docs/planning/v1.3/sprint_117_certification_snapshot_lock.json';

  /// The committed 117.41 connector-registry evidence that grounds the evidence
  /// and visibility outputs.
  static const String registryEvidencePath =
      'docs/evidence/sprint-117-41-manifest-20261002.json';

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

  /// The marker an entry declares when no committed witness names a reference
  /// state for an output. A record that uses it records an honest upstream gap
  /// rather than inventing a state.
  static const String noReferenceState = 'no_reference_state';

  /// The certification statuses that describe a released connector. On the
  /// delayed path no entry may carry one.
  static const List<String> releasedStatuses = <String>['CERTIFIED', 'LIMITED'];

  /// The visibility wire name that describes an exposed connector. On the
  /// delayed path no entry may carry it.
  static const String exposedVisibility = 'EXPOSED';

  /// The visibility wire name that describes a withheld connector, the honest
  /// state on the delayed path.
  static const String withheldVisibility = 'WITHHELD';

  /// The canonical field set each entry must carry, so a record cannot drop a
  /// field and still read as complete.
  static const List<String> requiredFields = <String>[
    'provider_id',
    'connector_version',
    'status',
    'evidence',
    'limitations',
    'reviewer',
    'recheck_date',
    'visibility',
  ];

  /// The seven canonical outputs named by the objective, in canonical order.
  /// `provider_id` is the key, not an output.
  static const List<String> requiredOutputs = <String>[
    'connector_version',
    'status',
    'evidence',
    'limitations',
    'reviewer',
    'recheck_date',
    'visibility',
  ];

  /// The committed evidence file each canonical output is anchored to, in
  /// canonical order.
  static const List<String> canonicalSources = <String>[
    snapshotLockManifestPath,
    certificationPolicyManifestPath,
    registryEvidencePath,
    certificationPolicyManifestPath,
    certificationPolicyManifestPath,
    certificationPolicyManifestPath,
    registryEvidencePath,
  ];

  /// The committed evidence files every record is anchored to. All must be
  /// readable.
  static const List<String> witnessSources = <String>[
    charterManifestPath,
    snapshotManifestPath,
    approvalGateManifestPath,
    iconRegistryManifestPath,
    registryReconciliationManifestPath,
    certificationPolicyManifestPath,
    snapshotLockManifestPath,
    registryEvidencePath,
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

  /// The declared reference state for the connector-version output. No connector
  /// version is certified live on the delayed path, so the honest reference is
  /// the committed 117.4 snapshot lock `recorded_connector_versions`
  /// (`manifest-v1`).
  static const String connectorVersionToken = 'manifest-v1';

  /// The declared reference state for the status output. No connector is
  /// certified on the delayed path, so the honest reference is the committed
  /// 116.2 certification status (`UNVERIFIED`).
  static const String statusToken = 'UNVERIFIED';

  /// The declared reference state for the evidence output. No live evidence is
  /// recorded on the delayed path, so the honest reference is the committed
  /// 117.41 registry evidence required field (`evidence`).
  static const String evidenceToken = 'evidence';

  /// The declared reference state for the limitations output. No live
  /// certification is performed on the delayed path, so the honest reference is
  /// the committed 116.2 certification limitation (`live_provider_certification`).
  static const String limitationsToken = 'live_provider_certification';

  /// The declared reference state for the reviewer output. No human review is
  /// performed on the delayed path, so the honest reference is the committed
  /// 116.2 certification record reviewer (`automation-governance`).
  static const String reviewerToken = 'automation-governance';

  /// The declared reference state for the recheck-date output. The recheck date
  /// is the committed 116.2 certification record `expires_or_recheck_at`
  /// (`2027-03-27`).
  static const String recheckDateToken = '2027-03-27';

  /// The declared reference state for the visibility output. No connector is
  /// exposed on the delayed path, so the honest reference is the committed
  /// 117.41 registry visibility (`WITHHELD`).
  static const String visibilityToken = 'WITHHELD';

  /// The committed witness vocabulary that grounds each canonical output, in
  /// canonical order.
  static List<List<String>> outputVocabularies(
    Sprint118VersionedCertificationAnchor anchor,
  ) => <List<String>>[
    anchor.connectorVersionVocabulary,
    anchor.statusVocabulary,
    anchor.evidenceVocabulary,
    anchor.limitationsVocabulary,
    anchor.reviewerVocabulary,
    anchor.recheckDateVocabulary,
    anchor.visibilityVocabulary,
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
  /// A witness grounds a token when it names the token exactly
  /// (`manifest-v1`, `UNVERIFIED`, `WITHHELD`), or when every underscore-separated
  /// part of a compound token is itself a witness-declared value. The vocabulary
  /// is measured from the committed witnesses, so a reference state cannot be
  /// invented into the list without a witness to ground it.
  static bool grounds(List<String> vocabulary, String token) {
    if (vocabulary.contains(token)) return true;
    final parts = token.split('_');
    if (parts.length < 2) return false;
    return parts.every(vocabulary.contains);
  }

  /// The committed witness vocabulary for a canonical output, or the empty list
  /// when the output is unknown.
  static List<String> vocabularyFor(
    Sprint118VersionedCertificationAnchor anchor,
    String output,
  ) {
    final index = requiredOutputs.indexOf(output);
    if (index < 0) return const <String>[];
    return outputVocabularies(anchor)[index];
  }

  /// The committed source for a canonical output, or `''` if unknown.
  static String sourceFor(String output) {
    final index = requiredOutputs.indexOf(output);
    return index < 0 ? '' : canonicalSources[index];
  }

  /// The canonical frozen record: every registered provider, each anchored to
  /// the committed witness vocabularies, claiming nothing live.
  static Sprint118VersionedCertificationRecord get canonicalRecord =>
      Sprint118VersionedCertificationRecord(
        releaseState: delayedReleaseState,
        entries: <Sprint118VersionedConnectorEntry>[
          for (final id in canonicalProviders)
            Sprint118VersionedConnectorEntry(
              providerId: id,
              connectorVersion: connectorVersionToken,
              status: statusToken,
              evidence: evidenceToken,
              limitations: limitationsToken,
              reviewer: reviewerToken,
              recheckDate: recheckDateToken,
              visibility: visibilityToken,
            ),
        ],
      );

  /// The narrow operator-authorized overlay. Only the live GitHub App example
  /// is promoted; publication remains false and all other providers remain on
  /// the delayed reference state.
  static Sprint118VersionedCertificationRecord
  get authorizedRecord => Sprint118VersionedCertificationRecord(
    releaseState: authorizedReleaseState,
    entries: <Sprint118VersionedConnectorEntry>[
      for (final id in canonicalProviders)
        Sprint118VersionedConnectorEntry(
          providerId: id,
          connectorVersion: connectorVersionToken,
          status: id == GithubAppReleaseAuthorization.authorizedProviderId
              ? GithubAppReleaseAuthorization.authorizedStatus
              : statusToken,
          evidence: evidenceToken,
          limitations: limitationsToken,
          reviewer: reviewerToken,
          recheckDate: recheckDateToken,
          visibility: id == GithubAppReleaseAuthorization.authorizedProviderId
              ? GithubAppReleaseAuthorization.authorizedVisibility
              : visibilityToken,
          certified: id == GithubAppReleaseAuthorization.authorizedProviderId,
          verified: id == GithubAppReleaseAuthorization.authorizedProviderId,
          reviewed: id == GithubAppReleaseAuthorization.authorizedProviderId,
          exposed: id == GithubAppReleaseAuthorization.authorizedProviderId,
          released: id == GithubAppReleaseAuthorization.authorizedProviderId,
        ),
    ],
  );
}

/// Reads the committed witnesses for step 118.39. Never invents: an unreadable
/// witness yields `null`, which the gate reports as blocked rather than as a
/// pass.
class Sprint118VersionedCertificationLoader {
  const Sprint118VersionedCertificationLoader();

  Sprint118VersionedCertificationAnchor? loadAnchor() {
    final charter = _read(
      Sprint118VersionedCertificationContract.charterManifestPath,
    );
    final snapshot = _read(
      Sprint118VersionedCertificationContract.snapshotManifestPath,
    );
    // Keep the delayed 118.3 snapshot and registry evidence canonical. The
    // authorized GitHub App path is an overlay in this step's manifest, so
    // earlier delayed-path gates do not inherit its exposure counts.
    final authorization = GithubAppReleaseAuthorization.load();
    final acceptance = authorization == null
        ? null
        : _read(Sprint118VersionedCertificationContract.manifestPath);
    final approval = _read(
      Sprint118VersionedCertificationContract.approvalGateManifestPath,
    );
    final icon = _read(
      Sprint118VersionedCertificationContract.iconRegistryManifestPath,
    );
    final reconciliation = _read(
      Sprint118VersionedCertificationContract
          .registryReconciliationManifestPath,
    );
    final policy = _read(
      Sprint118VersionedCertificationContract.certificationPolicyManifestPath,
    );
    final lock = _read(
      Sprint118VersionedCertificationContract.snapshotLockManifestPath,
    );
    final registry = _read(
      Sprint118VersionedCertificationContract.registryEvidencePath,
    );
    if (charter == null ||
        snapshot == null ||
        (authorization != null && acceptance == null) ||
        approval == null ||
        icon == null ||
        reconciliation == null ||
        policy == null ||
        lock == null ||
        registry == null) {
      return null;
    }

    final snapshotAnchor = acceptance ?? snapshot;
    final registryAnchor = acceptance ?? registry;

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

    final records = policy['evidence_records'];
    final firstRecord =
        records is List && records.isNotEmpty && records.first is Map
        ? records.first as Map
        : const <String, Object?>{};

    final lockAnchor = lock['anchor'];
    final lockAnchorMap = lockAnchor is Map<String, dynamic>
        ? lockAnchor
        : const <String, dynamic>{};

    final visibility = registry['visibility_counts'];
    final visibilityMap = visibility is Map<String, dynamic>
        ? visibility
        : const <String, dynamic>{};
    final visibilityVocabulary = <String>[
      for (final key in visibilityMap.keys) key,
    ];

    final sources = Sprint118VersionedCertificationContract.witnessSources
        .toSet();

    return Sprint118VersionedCertificationAnchor(
      charterState: _text(charter['state']),
      charterVerdict: _text(charter['verdict']),
      charterMaxNewCertified: _int(budgetMap['max_new_certified_connectors']),
      charterCurrentlyCertified: _int(budgetMap['currently_certified']),
      charterRegisteredProviders: _int(budgetMap['registered_providers']),
      snapshotState: _text(snapshotAnchor['state']),
      snapshotVerdict: _text(
        snapshotAnchor['snapshot_verdict'] ?? snapshotAnchor['verdict'],
      ),
      snapshotCertified: _int(
        snapshotAnchor['snapshot_certified'] ??
            snapshotAnchor['charter_certified'],
      ),
      snapshotRegistered: _int(
        snapshotAnchor['snapshot_registered'] ??
            snapshotAnchor['registered_provider_count'],
      ),
      releaseState: _text(snapshotAnchor['release_state']),
      registryExpectedCount: _int(reconciliation['expected_provider_count']),
      registryEvidenceProviderCount: _int(registry['provider_count']),
      registryEvidenceExposed: _int(
        registryAnchor['registry_evidence_exposed'] ??
            visibilityMap['EXPOSED'],
      ),
      registryEvidenceWithheld: _int(
        registryAnchor['registry_evidence_withheld'] ??
            visibilityMap['WITHHELD'],
      ),
      snapshotLockLockedCount: _int(lock['locked_provider_count']),
      approvalDecision: _text(approvalInner['decision']),
      approvalState: _text(approvalInner['approval_state']),
      executionAuthorized: approvalInner['execution_authorized'] == true,
      releaseBlocked: blockerInner['release_blocked'] == true,
      registeredProviders: registered,
      connectorVersionVocabulary: _strings(
        lockAnchorMap['recorded_connector_versions'],
      ),
      statusVocabulary: _strings(policy['certification_statuses']),
      evidenceVocabulary: _strings(registry['required_fields']),
      limitationsVocabulary: _strings(policy['limitations']),
      reviewerVocabulary: _strings(firstRecord['reviewer']),
      recheckDateVocabulary: _strings(firstRecord['expires_or_recheck_at']),
      visibilityVocabulary: visibilityVocabulary,
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

/// The fail-closed versioned connector certification gate for step 118.39.
class Sprint118VersionedCertificationGate {
  const Sprint118VersionedCertificationGate();

  Sprint118VersionedCertificationReport evaluate() {
    final authorization = GithubAppReleaseAuthorization.load();
    return evaluateWith(
      const Sprint118VersionedCertificationLoader().loadAnchor(),
      authorization == null
          ? Sprint118VersionedCertificationContract.canonicalRecord
          : Sprint118VersionedCertificationContract.authorizedRecord,
      authorization: authorization,
    );
  }

  Sprint118VersionedCertificationReport evaluateWith(
    Sprint118VersionedCertificationAnchor? anchor,
    Sprint118VersionedCertificationRecord record, {
    GithubAppReleaseAuthorization? authorization,
  }) {
    if (anchor == null) {
      return Sprint118VersionedCertificationReport(
        state: Sprint118VersionedCertificationState.blocked,
        verdict:
            'SPRINT_118_VERSIONED_CONNECTOR_CERTIFICATION_EVIDENCE_UNREADABLE',
        releaseState: record.releaseState,
        blockers: const <String>[
          'committed_versioned_certification_evidence_unreadable',
        ],
        openItems: const <String>[
          'committed_versioned_certification_evidence_unreadable',
        ],
      );
    }

    final violations = <String>[];
    final blockers = <String>[];
    final openItems = <String>[];
    final authorized =
        authorization?.isValid == true &&
        record.releaseState ==
            Sprint118VersionedCertificationContract.authorizedReleaseState;

    final frozen =
        anchor.charterMaxNewCertified == 0 &&
        anchor.charterCurrentlyCertified == 0;

    // (1) The 118.2 charter anchor must be a genuine complete charter.
    if (anchor.charterState !=
            Sprint118VersionedCertificationContract.requiredCharterState ||
        anchor.charterVerdict !=
            Sprint118VersionedCertificationContract.requiredCharterVerdict) {
      blockers.add('charter_not_complete:${anchor.charterVerdict}');
    }

    // (2) The 118.3 snapshot anchor must be a genuine frozen pass.
    if (anchor.snapshotState !=
            Sprint118VersionedCertificationContract.requiredSnapshotState ||
        (!authorized &&
            anchor.snapshotVerdict !=
                Sprint118VersionedCertificationContract
                    .requiredSnapshotVerdict) ||
        (authorized &&
            anchor.snapshotVerdict !=
                GithubAppReleaseAuthorization.authorizedSnapshotVerdict)) {
      blockers.add('snapshot_not_frozen:${anchor.snapshotVerdict}');
    }

    // (3) The 117.45 approval gate must record the delay decision, read with the
    // owner's exact grammar. If it is not a delay, the anchor is untrustworthy.
    if (!authorized &&
        anchor.approvalDecision !=
            Sprint118VersionedCertificationContract.requiredApprovalDecision) {
      blockers.add('approval_gate_not_delay:${anchor.approvalDecision}');
    }

    // (4) The registered provider set must reconcile across the icon registry,
    // the 116.3 reconciliation, the frozen snapshot, the charter, the 117.41
    // registry evidence, and the 117.4 snapshot lock.
    if (anchor.registeredProviders.length !=
            Sprint118VersionedCertificationContract.expectedProviderCount ||
        anchor.registryExpectedCount !=
            Sprint118VersionedCertificationContract.expectedProviderCount ||
        anchor.snapshotRegistered !=
            Sprint118VersionedCertificationContract.expectedProviderCount ||
        anchor.charterRegisteredProviders !=
            Sprint118VersionedCertificationContract.expectedProviderCount ||
        anchor.registryEvidenceProviderCount !=
            Sprint118VersionedCertificationContract.expectedProviderCount ||
        anchor.snapshotLockLockedCount !=
            Sprint118VersionedCertificationContract.expectedProviderCount) {
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
        Sprint118VersionedCertificationContract.expectedProviderCount) {
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
            Sprint118VersionedCertificationContract.delayedReleaseState) {
      violations.add(
        'versioned_connector_not_on_delayed_path:${record.releaseState}',
      );
    }

    final delayed =
        record.releaseState ==
        Sprint118VersionedCertificationContract.delayedReleaseState;

    if (!delayed && !authorized) {
      violations.add('versioned_connector_release_state_not_authorized');
    }

    // (7) On the delayed path an authorized release execution and an unblocked
    // release are behavior that never ran.
    if (delayed && anchor.executionAuthorized) {
      violations.add(
        'versioned_connector_execution_authorized_on_delayed_path',
      );
    }
    if (delayed && !anchor.releaseBlocked) {
      violations.add('versioned_connector_release_not_blocked_on_delayed_path');
    }

    // (8) The expansion budget must stay frozen: no new certified connector and
    // no already-certified connector while the release is delayed.
    if (!frozen && !authorized) {
      violations.add(
        'versioned_connector_expansion_budget_not_frozen:max_new='
        '${anchor.charterMaxNewCertified}:'
        'currently=${anchor.charterCurrentlyCertified}',
      );
    }
    // The frozen 118.3 snapshot must declare zero certified connectors. A
    // snapshot that already certifies a connector contradicts the delayed path.
    if (!authorized && anchor.snapshotCertified != 0) {
      violations.add(
        'versioned_connector_snapshot_certified_nonzero:'
        '${anchor.snapshotCertified}',
      );
    }

    // (9) Every registered provider must appear exactly once, and each entry
    // must carry all eight canonical fields non-blank with every output grounded
    // by its committed witness vocabulary.
    final declared = <String, int>{};
    for (final entry in record.entries) {
      declared[entry.providerId] = (declared[entry.providerId] ?? 0) + 1;
    }
    for (final entry in record.entries) {
      final id = entry.providerId;
      if (!anchor.registeredProviders.contains(id)) {
        violations.add('versioned_connector_provider_unknown:$id');
      }
      for (final field
          in Sprint118VersionedCertificationContract.requiredFields) {
        final value = entry.requiredFields[field] ?? '';
        if (value.trim().isEmpty) {
          violations.add('entry_blank_$field:$id');
        }
      }
      for (final output
          in Sprint118VersionedCertificationContract.requiredOutputs) {
        final token = entry.outputFields[output] ?? '';
        final vocabulary =
            Sprint118VersionedCertificationContract.vocabularyFor(
              anchor,
              output,
            );
        final grounded =
            token == Sprint118VersionedCertificationContract.noReferenceState ||
            Sprint118VersionedCertificationContract.grounds(vocabulary, token);
        if (token.trim().isEmpty || !grounded) {
          violations.add('reference_state_invalid:$output:$id');
        }
        if (token == Sprint118VersionedCertificationContract.noReferenceState) {
          openItems.add('upstream_state_vocabulary_gap:$output:$id');
        }
      }
      // A released status is never recorded on the delayed path.
      if (delayed &&
          Sprint118VersionedCertificationContract.releasedStatuses.contains(
            entry.status,
          )) {
        violations.add(
          'versioned_connector_status_certified_on_delayed_path:'
          '$id:${entry.status}',
        );
      }
      // An exposed visibility is never recorded on the delayed path.
      if (delayed &&
          entry.visibility ==
              Sprint118VersionedCertificationContract.exposedVisibility) {
        violations.add(
          'versioned_connector_visibility_exposed_on_delayed_path:$id',
        );
      }
      // A connector is never certified without live provider verification.
      if (delayed && entry.certified) {
        violations.add(
          'versioned_connector_certified_claimed_on_delayed_path:$id',
        );
      }
      // Evidence is never verified live on the delayed path.
      if (delayed && entry.verified) {
        violations.add(
          'versioned_connector_evidence_verified_on_delayed_path:$id',
        );
      }
      // A live review is never performed on the delayed path.
      if (delayed && entry.reviewed) {
        violations.add(
          'versioned_connector_reviewed_claimed_on_delayed_path:$id',
        );
      }
      // A connector is never exposed without an authorized release.
      if (delayed && entry.exposed) {
        violations.add(
          'versioned_connector_exposed_claimed_on_delayed_path:$id',
        );
      }
      // A connector is never released without an authorized release.
      if (delayed && entry.released) {
        violations.add('versioned_connector_released_claimed:$id');
      }
      // A connector is never published on the delayed path.
      if (delayed && entry.published) {
        violations.add('versioned_connector_published_claimed:$id');
      }
      if (authorized &&
          id == GithubAppReleaseAuthorization.authorizedProviderId) {
        if (!entry.certified ||
            !entry.verified ||
            !entry.reviewed ||
            !entry.exposed ||
            !entry.released ||
            entry.published ||
            entry.status != GithubAppReleaseAuthorization.authorizedStatus ||
            entry.visibility !=
                GithubAppReleaseAuthorization.authorizedVisibility) {
          violations.add('github_app_authorized_entry_incomplete');
        }
      } else if (authorized &&
          (entry.certified ||
              entry.verified ||
              entry.reviewed ||
              entry.exposed ||
              entry.released ||
              entry.published)) {
        violations.add('non_github_provider_authorized_claim:$id');
      }
    }
    for (final id in declared.keys) {
      if (declared[id]! > 1) {
        violations.add('versioned_connector_provider_duplicate:$id');
      }
    }
    for (final id in anchor.registeredProviders) {
      if (!declared.containsKey(id)) {
        violations.add('versioned_connector_provider_missing:$id');
      }
    }

    // (10) Every committed evidence source must be readable.
    for (final source
        in Sprint118VersionedCertificationContract.witnessSources.toSet()) {
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
      return Sprint118VersionedCertificationReport(
        state: Sprint118VersionedCertificationState.blocked,
        verdict:
            'SPRINT_118_VERSIONED_CONNECTOR_CERTIFICATION_BLOCKED_UPSTREAM',
        releaseState: record.releaseState,
        violations: violations,
        blockers: blockers,
        openItems: allItems,
        declaredProviders: providers,
        certifiedProviders: record.certifiedProviders,
        exposedProviders: record.exposedProviders,
        releasedProviders: record.releasedProviders,
        certifiedCount: record.certifiedCount,
        exposedCount: record.exposedCount,
        releasedCount: record.releasedCount,
        expansionBudgetFrozen: frozen,
      );
    }
    if (violations.isNotEmpty) {
      return Sprint118VersionedCertificationReport(
        state: Sprint118VersionedCertificationState.fail,
        verdict:
            'SPRINT_118_VERSIONED_CONNECTOR_CERTIFICATION_EVIDENCE_VIOLATION',
        releaseState: record.releaseState,
        violations: violations,
        blockers: blockers,
        openItems: allItems,
        declaredProviders: providers,
        certifiedProviders: record.certifiedProviders,
        exposedProviders: record.exposedProviders,
        releasedProviders: record.releasedProviders,
        certifiedCount: record.certifiedCount,
        exposedCount: record.exposedCount,
        releasedCount: record.releasedCount,
        expansionBudgetFrozen: frozen,
      );
    }
    return Sprint118VersionedCertificationReport(
      state: Sprint118VersionedCertificationState.pass,
      verdict: authorized
          ? 'VERSIONED_CONNECTOR_CERTIFICATION_AUTHORIZED_LOCAL'
          : 'VERSIONED_CONNECTOR_CERTIFICATION_VERIFIED_LOCAL',
      releaseState: record.releaseState,
      openItems: allItems,
      declaredProviders: providers,
      certifiedProviders: record.certifiedProviders,
      exposedProviders: record.exposedProviders,
      releasedProviders: record.releasedProviders,
      certifiedCount: record.certifiedCount,
      exposedCount: record.exposedCount,
      releasedCount: record.releasedCount,
      expansionBudgetFrozen: frozen,
    );
  }
}
