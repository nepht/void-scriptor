/// Fail-closed documentation & support update record for roadmap step 118.43 --
/// Documentation & Support Update.
///
/// Objective (external canonical `sprint_118.json`): update provider
/// availability, setup, permissions, limitations, quota, usage, cost, recovery,
/// billing, and known issues. The canonical output set is exactly eight
/// dimensions: `availability_matrix`, `setup_guides`, `permissions`,
/// `limitations`, `quota_notes`, `usage_cost_notes`, `recovery`, and
/// `known_issues`.
///
/// The release is delayed. No connector is certified (118.3 froze `CERTIFIED: 0`
/// of `32` registered; the committed 117.41 registry evidence records
/// `UNVERIFIED: 32`, `EXPOSED: 0`, `WITHHELD: 32`), the 118.2 charter froze an
/// expansion budget of zero new certified connectors out of 32 registered, and
/// the committed 117.45 approval gate records `decision=delay`,
/// `approval_state=PENDING_CHOIRUDIN`, `execution_authorized=false`, and
/// `release_blocked=true`. No documentation has been published, no guide has
/// been updated live, no support escalation has run, and no evidence has been
/// verified live. A documentation & support update record written against that
/// state therefore has exactly one honest shape: enumerate all 32 registered
/// providers, anchor each of the eight documentation & support dimensions to a
/// committed witness vocabulary, claim no documentation published, and update
/// none.
///
/// The gate is fail-closed on these families of rules:
///
/// * The committed 118.2 charter anchor must be a genuine complete charter and
///   its expansion budget must stay frozen (`max_new_certified_connectors` and
///   `currently_certified` both zero). A documentation update anchored to an
///   unfrozen budget documents connectors nobody authorized.
/// * The committed 118.3 certified connector snapshot must be a genuine frozen
///   pass (`CERTIFIED_CONNECTOR_SNAPSHOT_FROZEN_LOCAL`). A documentation update
///   anchored to an unfrozen snapshot rests on a release nobody recorded.
/// * The committed 117.45 approval gate must record the delay decision
///   (`decision == delay`), read with the owner's exact grammar, never
///   case-folded or trimmed into agreement. If it is not a delay, the anchor is
///   untrustworthy and the honest answer is `blocked`, not `fail`.
/// * The registered provider set must reconcile: the icon-registry provider
///   union, the 116.3 reconciliation count, the frozen snapshot count, the
///   charter count, the 117.41 registry evidence count, and the 117.4 snapshot
///   lock count must all agree. A documentation update over a drifting registry
///   is not a documentation update.
/// * The committed 117.41 registry visibility counts must reconcile (`EXPOSED`
///   plus `WITHHELD` equals the registered count) and must record zero exposed
///   providers while the release is delayed. A registry that already exposes a
///   connector contradicts the frozen zero-certified state.
/// * Every registered provider must appear exactly once. A record that drops a
///   provider, invents `telepathy`, or duplicates `stripe` is not a record.
/// * Every entry must carry all eight canonical documentation & support
///   dimensions non-blank, and each of the eight dimensions must be grounded by
///   the committed witness vocabulary for that dimension, so a documentation
///   reference cannot be invented into the list without a witness to ground it.
/// * On the delayed path a documented connector, a published documentation set,
///   an updated documentation set, a verified documentation set, a complete
///   documentation set, an active support escalation, a certified connector, or
///   a released connector describe behavior that never ran. This is refused by
///   name, per entry.
///
/// **Documentation is never published and support is never escalated without
/// live evidence and an authorized release.** When no documentation has been
/// published and no release is authorized, the only honest record states the
/// committed reference for each documentation & support dimension and claims
/// nothing live; any documented, published, updated, verified, complete,
/// supported, certified, or released claim is refused by name.
///
/// The output vocabulary is *derived from committed witnesses* (the 114.22
/// feature availability reconciliation `required_fields`, the 112.51
/// documentation & support release notes `outputs`, the 118.20
/// novel-character permission boundary health `boundary_acceptance`, the 115.17
/// provider quota adapters `acceptance`, the 118.35 AI connector expansion
/// `cost_vocabulary`, the 118.10 sync/backup/recovery health
/// `witness_backup_evidence`, and the 114.34 support & documentation
/// maintenance `outputs`), and the source for each dimension is a committed
/// manifest, not copied by hand, so the record and its witnesses cannot drift
/// apart silently.
///
/// Documentation publication, support escalation, connector certification,
/// connector release, and publication remain `DEFERRED-EXTERNAL`; this record
/// freezes local declared state and executes none of it.
library;

import 'dart:convert';
import 'dart:io';

/// The three states a documentation & support record can rest in. `blocked` is
/// the honest resting state for "this record cannot yet be trusted", and it is
/// distinct from `fail`, which means the record contradicts its own evidence.
enum Sprint118DocumentationSupportState { pass, fail, blocked }

/// One frozen documentation & support record entry: the declared reference for
/// each of the eight canonical documentation & support dimensions of a single
/// registered provider.
///
/// `documented`, `published`, `updated`, `verified`, `complete`, `supported`,
/// `certified`, and `released` are deliberately *not* among the eight required
/// fields; they are the flags the gate refuses when set, so that a declared
/// reference record can be recorded while never being read as a documented
/// connector, a published documentation set, an updated documentation set, a
/// verified documentation set, a complete documentation set, an active support
/// escalation, a certified connector, or a released connector.
class Sprint118DocumentationSupportEntry {
  const Sprint118DocumentationSupportEntry({
    required this.providerId,
    required this.availabilityMatrix,
    required this.setupGuides,
    required this.permissions,
    required this.limitations,
    required this.quotaNotes,
    required this.usageCostNotes,
    required this.recovery,
    required this.knownIssues,
    this.documented = false,
    this.published = false,
    this.updated = false,
    this.verified = false,
    this.complete = false,
    this.supported = false,
    this.certified = false,
    this.released = false,
  });

  /// The registered provider identifier, drawn from the committed icon registry.
  final String providerId;

  /// The availability-matrix reference state, drawn from the committed 114.22
  /// feature availability reconciliation `required_fields` (`available`).
  final String availabilityMatrix;

  /// The setup-guide reference state, drawn from the committed 112.51
  /// documentation & support release notes `outputs` (`user_guides`).
  final String setupGuides;

  /// The permissions reference state, drawn from the committed 118.20
  /// novel-character permission boundary health `boundary_acceptance`
  /// (`explicit_workspace_permission`).
  final String permissions;

  /// The limitations reference state, drawn from the committed 112.51
  /// documentation & support release notes `outputs` (`known_limits`).
  final String limitations;

  /// The quota-note reference state, drawn from the committed 115.17 provider
  /// quota adapters `acceptance` (`quota_unavailable`).
  final String quotaNotes;

  /// The usage/cost-note reference state, drawn from the committed 118.35 AI
  /// connector expansion `cost_vocabulary` (`provider_cost`).
  final String usageCostNotes;

  /// The recovery reference state, drawn from the committed 118.10
  /// sync/backup/recovery health `witness_backup_evidence` (`restore_success`).
  final String recovery;

  /// The known-issues reference state, drawn from the committed 114.34 support &
  /// documentation maintenance `outputs` (`known_issues`).
  final String knownIssues;

  /// Whether the entry claims the documentation was written. On the delayed path
  /// this must stay `false`.
  final bool documented;

  /// Whether the entry claims the documentation was published. On the delayed
  /// path this must stay `false`.
  final bool published;

  /// Whether the entry claims the documentation was updated live. On the delayed
  /// path this must stay `false`.
  final bool updated;

  /// Whether the entry claims the documentation was verified live. On the
  /// delayed path this must stay `false`.
  final bool verified;

  /// Whether the entry claims the documentation set is complete. On the delayed
  /// path this must stay `false`.
  final bool complete;

  /// Whether the entry claims an active support escalation. On the delayed path
  /// this must stay `false`.
  final bool supported;

  /// Whether the entry claims the connector was certified. On the delayed path
  /// this must stay `false`.
  final bool certified;

  /// Whether the entry claims the connector was released. On the delayed path
  /// this must stay `false`.
  final bool released;

  /// The eight canonical documentation & support dimensions as a name -> value
  /// map, so the gate can test blankness uniformly.
  Map<String, String> get requiredFields => <String, String>{
    'availability_matrix': availabilityMatrix,
    'setup_guides': setupGuides,
    'permissions': permissions,
    'limitations': limitations,
    'quota_notes': quotaNotes,
    'usage_cost_notes': usageCostNotes,
    'recovery': recovery,
    'known_issues': knownIssues,
  };

  /// The eight documentation & support outputs as an output -> value map, so the
  /// gate can test grounding per dimension.
  Map<String, String> get outputFields => requiredFields;
}

/// The frozen documentation & support record. `entries` is the declared
/// reference for each registered provider. On the delayed path no entry may
/// claim a live documentation update.
class Sprint118DocumentationSupportRecord {
  const Sprint118DocumentationSupportRecord({
    required this.releaseState,
    required this.entries,
  });

  final String releaseState;
  final List<Sprint118DocumentationSupportEntry> entries;

  List<String> get providerIds => <String>[
    for (final entry in entries) entry.providerId,
  ];

  /// The providers the record claims were documented. On the delayed path this
  /// must stay empty.
  List<String> get documentedProviders => <String>[
    for (final entry in entries)
      if (entry.documented) entry.providerId,
  ];

  /// The providers the record claims were published. On the delayed path this
  /// must stay empty.
  List<String> get publishedProviders => <String>[
    for (final entry in entries)
      if (entry.published) entry.providerId,
  ];

  /// The providers the record claims were updated. On the delayed path this must
  /// stay empty.
  List<String> get updatedProviders => <String>[
    for (final entry in entries)
      if (entry.updated) entry.providerId,
  ];

  /// The providers the record claims were verified. On the delayed path this
  /// must stay empty.
  List<String> get verifiedProviders => <String>[
    for (final entry in entries)
      if (entry.verified) entry.providerId,
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

  int get documentedCount => entries.where((entry) => entry.documented).length;

  int get publishedCount => entries.where((entry) => entry.published).length;

  int get updatedCount => entries.where((entry) => entry.updated).length;

  int get verifiedCount => entries.where((entry) => entry.verified).length;

  int get completeCount => entries.where((entry) => entry.complete).length;

  int get supportedCount => entries.where((entry) => entry.supported).length;

  int get certifiedCount => entries.where((entry) => entry.certified).length;

  int get releasedCount => entries.where((entry) => entry.released).length;
}

/// What the committed witnesses actually say. A gate is only as honest as the
/// witnesses it is anchored to.
class Sprint118DocumentationSupportAnchor {
  const Sprint118DocumentationSupportAnchor({
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
    required this.availabilityVocabulary,
    required this.setupGuidesVocabulary,
    required this.permissionsVocabulary,
    required this.limitationsVocabulary,
    required this.quotaNotesVocabulary,
    required this.usageCostNotesVocabulary,
    required this.recoveryVocabulary,
    required this.knownIssuesVocabulary,
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

  /// The availability vocabulary the committed 114.22 feature availability
  /// reconciliation declares. It grounds the availability_matrix dimension.
  final List<String> availabilityVocabulary;

  /// The setup-guide vocabulary the committed 112.51 documentation & support
  /// release notes declare. It grounds the setup_guides dimension.
  final List<String> setupGuidesVocabulary;

  /// The permissions vocabulary the committed 118.20 novel-character permission
  /// boundary health declares. It grounds the permissions dimension.
  final List<String> permissionsVocabulary;

  /// The limitations vocabulary the committed 112.51 documentation & support
  /// release notes declare. It grounds the limitations dimension.
  final List<String> limitationsVocabulary;

  /// The quota-note vocabulary the committed 115.17 provider quota adapters
  /// declare. It grounds the quota_notes dimension.
  final List<String> quotaNotesVocabulary;

  /// The usage/cost-note vocabulary the committed 118.35 AI connector expansion
  /// declares. It grounds the usage_cost_notes dimension.
  final List<String> usageCostNotesVocabulary;

  /// The recovery vocabulary the committed 118.10 sync/backup/recovery health
  /// declares. It grounds the recovery dimension.
  final List<String> recoveryVocabulary;

  /// The known-issues vocabulary the committed 114.34 support & documentation
  /// maintenance declares. It grounds the known_issues dimension.
  final List<String> knownIssuesVocabulary;

  /// The committed evidence paths that are present and readable on disk.
  final List<String> readableSources;
}

/// The measured result. `pass` means the record is a faithful documentation &
/// support freeze; `blocked` means it cannot yet be trusted; `fail` means it
/// contradicts its evidence.
class Sprint118DocumentationSupportReport {
  const Sprint118DocumentationSupportReport({
    required this.state,
    required this.verdict,
    required this.releaseState,
    this.violations = const <String>[],
    this.blockers = const <String>[],
    this.openItems = const <String>[],
    this.declaredProviders = const <String>[],
    this.documentedProviders = const <String>[],
    this.publishedProviders = const <String>[],
    this.updatedProviders = const <String>[],
    this.verifiedProviders = const <String>[],
    this.certifiedProviders = const <String>[],
    this.releasedProviders = const <String>[],
    this.documentedCount = 0,
    this.publishedCount = 0,
    this.updatedCount = 0,
    this.verifiedCount = 0,
    this.completeCount = 0,
    this.supportedCount = 0,
    this.certifiedCount = 0,
    this.releasedCount = 0,
    this.expansionBudgetFrozen = false,
  });

  final Sprint118DocumentationSupportState state;
  final String verdict;
  final String releaseState;

  final List<String> violations;
  final List<String> blockers;
  final List<String> openItems;
  final List<String> declaredProviders;
  final List<String> documentedProviders;
  final List<String> publishedProviders;
  final List<String> updatedProviders;
  final List<String> verifiedProviders;
  final List<String> certifiedProviders;
  final List<String> releasedProviders;
  final int documentedCount;
  final int publishedCount;
  final int updatedCount;
  final int verifiedCount;
  final int completeCount;
  final int supportedCount;
  final int certifiedCount;
  final int releasedCount;
  final bool expansionBudgetFrozen;

  /// Whether the record may be treated as a frozen documentation & support
  /// freeze. Only a genuine `pass` allows it.
  bool get recordVerified => state == Sprint118DocumentationSupportState.pass;

  String get externalGates =>
      Sprint118DocumentationSupportContract.externalGates;
}

/// The fixed vocabulary and committed witness set for step 118.43.
abstract final class Sprint118DocumentationSupportContract {
  const Sprint118DocumentationSupportContract._();

  static const String canonicalStep = '118.43';
  static const String title = 'Documentation & Support Update';

  static const String manifestPath =
      'docs/planning/v1.3/sprint_118_documentation_support_update.json';
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

  /// The committed 114.22 feature availability reconciliation that grounds the
  /// availability_matrix dimension.
  static const String availabilityManifestPath =
      'docs/planning/v1.2/sprint_114_feature_availability_reconciliation.json';

  /// The committed 112.51 documentation & support release notes that ground the
  /// setup_guides and limitations dimensions.
  static const String documentationSupportPath =
      'docs/planning/v1.2/sprint_112_documentation_support_release_notes.json';

  /// The committed 118.20 novel-character permission boundary health that
  /// grounds the permissions dimension.
  static const String permissionBoundaryPath =
      'docs/planning/v1.3/sprint_118_permission_boundary_health.json';

  /// The committed 115.17 provider quota adapters that ground the quota_notes
  /// dimension.
  static const String quotaAdaptersPath =
      'docs/planning/v1.2/sprint_115_provider_quota_adapters.json';

  /// The committed 118.35 AI connector expansion that grounds the
  /// usage_cost_notes dimension.
  static const String usageCostManifestPath =
      'docs/planning/v1.3/sprint_118_ai_connector_expansion.json';

  /// The committed 118.10 sync/backup/recovery health that grounds the recovery
  /// dimension.
  static const String syncBackupRecoveryPath =
      'docs/planning/v1.3/sprint_118_sync_backup_recovery_health.json';

  /// The committed 114.34 support & documentation maintenance that grounds the
  /// known_issues dimension.
  static const String supportDocumentationPath =
      'docs/planning/v1.2/sprint_114_support_documentation_maintenance.json';

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

  /// The number of registered providers the committed witnesses reconcile to.
  static const int expectedProviderCount = 32;

  /// The number of canonical documentation & support dimensions the objective
  /// names.
  static const int expectedOutputCount = 8;

  /// The marker an entry declares when no committed witness names a reference
  /// state for a dimension. A record that uses it records an honest upstream gap
  /// rather than inventing a state.
  static const String noReferenceState = 'no_reference_state';

  /// The canonical documentation & support set each entry must carry, so a
  /// record cannot drop a dimension and still read as complete.
  static const List<String> requiredFields = <String>[
    'availability_matrix',
    'setup_guides',
    'permissions',
    'limitations',
    'quota_notes',
    'usage_cost_notes',
    'recovery',
    'known_issues',
  ];

  /// The eight canonical documentation & support dimensions named by the
  /// objective, in canonical order.
  static const List<String> requiredOutputs = requiredFields;

  /// The committed evidence file each canonical documentation & support
  /// dimension is anchored to, in canonical order.
  static const List<String> canonicalSources = <String>[
    availabilityManifestPath,
    documentationSupportPath,
    permissionBoundaryPath,
    documentationSupportPath,
    quotaAdaptersPath,
    usageCostManifestPath,
    syncBackupRecoveryPath,
    supportDocumentationPath,
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
    availabilityManifestPath,
    documentationSupportPath,
    permissionBoundaryPath,
    quotaAdaptersPath,
    usageCostManifestPath,
    syncBackupRecoveryPath,
    supportDocumentationPath,
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

  /// The declared reference state for the availability_matrix dimension. No live
  /// availability has been verified on the delayed path, so the honest reference
  /// is the committed 114.22 feature availability reconciliation first required
  /// field (`available`).
  static const String availabilityToken = 'available';

  /// The declared reference state for the setup_guides dimension. No setup guide
  /// has been published on the delayed path, so the honest reference is the
  /// committed 112.51 documentation & support release notes first output
  /// (`user_guides`).
  static const String setupGuidesToken = 'user_guides';

  /// The declared reference state for the permissions dimension. No permission
  /// has been granted live on the delayed path, so the honest reference is the
  /// committed 118.20 novel-character permission boundary health first boundary
  /// acceptance (`explicit_workspace_permission`).
  static const String permissionsToken = 'explicit_workspace_permission';

  /// The declared reference state for the limitations dimension. No limitation
  /// has been re-reviewed live on the delayed path, so the honest reference is
  /// the committed 112.51 documentation & support release notes output
  /// (`known_limits`).
  static const String limitationsToken = 'known_limits';

  /// The declared reference state for the quota_notes dimension. No live quota
  /// reading is recorded on the delayed path, so the honest reference is the
  /// committed 115.17 provider quota adapters first acceptance
  /// (`quota_unavailable`).
  static const String quotaNotesToken = 'quota_unavailable';

  /// The declared reference state for the usage_cost_notes dimension. No live
  /// usage/cost reading is recorded on the delayed path, so the honest reference
  /// is the committed 118.35 AI connector expansion first cost vocabulary
  /// (`provider_cost`).
  static const String usageCostNotesToken = 'provider_cost';

  /// The declared reference state for the recovery dimension. No recovery has
  /// been executed live on the delayed path, so the honest reference is the
  /// committed 118.10 sync/backup/recovery health first backup evidence
  /// (`restore_success`).
  static const String recoveryToken = 'restore_success';

  /// The declared reference state for the known_issues dimension. No issue has
  /// been triaged live on the delayed path, so the honest reference is the
  /// committed 114.34 support & documentation maintenance first output
  /// (`known_issues`).
  static const String knownIssuesToken = 'known_issues';

  /// The committed witness vocabulary that grounds each canonical documentation
  /// & support dimension, in canonical order.
  static List<List<String>> outputVocabularies(
    Sprint118DocumentationSupportAnchor anchor,
  ) => <List<String>>[
    anchor.availabilityVocabulary,
    anchor.setupGuidesVocabulary,
    anchor.permissionsVocabulary,
    anchor.limitationsVocabulary,
    anchor.quotaNotesVocabulary,
    anchor.usageCostNotesVocabulary,
    anchor.recoveryVocabulary,
    anchor.knownIssuesVocabulary,
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
  /// A witness grounds a token when it names the token exactly (`available`,
  /// `user_guides`, `explicit_workspace_permission`), or when every
  /// underscore-separated part of a compound token is itself a witness-declared
  /// value. The vocabulary is measured from the committed witnesses, so a
  /// reference state cannot be invented into the list without a witness to
  /// ground it.
  static bool grounds(List<String> vocabulary, String token) {
    if (vocabulary.contains(token)) return true;
    final parts = token.split('_');
    if (parts.length < 2) return false;
    return parts.every(vocabulary.contains);
  }

  /// The committed witness vocabulary for a canonical documentation & support
  /// dimension, or the empty list when the dimension is unknown.
  static List<String> vocabularyFor(
    Sprint118DocumentationSupportAnchor anchor,
    String output,
  ) {
    final index = requiredOutputs.indexOf(output);
    if (index < 0) return const <String>[];
    return outputVocabularies(anchor)[index];
  }

  /// The committed source for a canonical documentation & support dimension, or
  /// `''` if unknown.
  static String sourceFor(String output) {
    final index = requiredOutputs.indexOf(output);
    return index < 0 ? '' : canonicalSources[index];
  }

  /// The canonical frozen record: every registered provider, each anchored to
  /// the committed witness vocabularies, claiming nothing live.
  static Sprint118DocumentationSupportRecord get canonicalRecord =>
      Sprint118DocumentationSupportRecord(
        releaseState: delayedReleaseState,
        entries: <Sprint118DocumentationSupportEntry>[
          for (final id in canonicalProviders)
            Sprint118DocumentationSupportEntry(
              providerId: id,
              availabilityMatrix: availabilityToken,
              setupGuides: setupGuidesToken,
              permissions: permissionsToken,
              limitations: limitationsToken,
              quotaNotes: quotaNotesToken,
              usageCostNotes: usageCostNotesToken,
              recovery: recoveryToken,
              knownIssues: knownIssuesToken,
            ),
        ],
      );
}

/// Reads the committed witnesses for step 118.43. Never invents: an unreadable
/// witness yields `null`, which the gate reports as blocked rather than as a
/// pass.
class Sprint118DocumentationSupportLoader {
  const Sprint118DocumentationSupportLoader();

  Sprint118DocumentationSupportAnchor? loadAnchor() {
    final charter = _read(
      Sprint118DocumentationSupportContract.charterManifestPath,
    );
    final snapshot = _read(
      Sprint118DocumentationSupportContract.snapshotManifestPath,
    );
    final approval = _read(
      Sprint118DocumentationSupportContract.approvalGateManifestPath,
    );
    final icon = _read(
      Sprint118DocumentationSupportContract.iconRegistryManifestPath,
    );
    final reconciliation = _read(
      Sprint118DocumentationSupportContract.registryReconciliationManifestPath,
    );
    final lock = _read(
      Sprint118DocumentationSupportContract.snapshotLockManifestPath,
    );
    final registry = _read(
      Sprint118DocumentationSupportContract.registryEvidencePath,
    );
    final availability = _read(
      Sprint118DocumentationSupportContract.availabilityManifestPath,
    );
    final documentationSupport = _read(
      Sprint118DocumentationSupportContract.documentationSupportPath,
    );
    final permissionBoundary = _read(
      Sprint118DocumentationSupportContract.permissionBoundaryPath,
    );
    final quotaAdapters = _read(
      Sprint118DocumentationSupportContract.quotaAdaptersPath,
    );
    final usageCost = _read(
      Sprint118DocumentationSupportContract.usageCostManifestPath,
    );
    final syncBackup = _read(
      Sprint118DocumentationSupportContract.syncBackupRecoveryPath,
    );
    final supportDocumentation = _read(
      Sprint118DocumentationSupportContract.supportDocumentationPath,
    );
    if (charter == null ||
        snapshot == null ||
        approval == null ||
        icon == null ||
        reconciliation == null ||
        lock == null ||
        registry == null ||
        availability == null ||
        documentationSupport == null ||
        permissionBoundary == null ||
        quotaAdapters == null ||
        usageCost == null ||
        syncBackup == null ||
        supportDocumentation == null) {
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

    final sources = Sprint118DocumentationSupportContract.witnessSources
        .toSet();

    return Sprint118DocumentationSupportAnchor(
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
      availabilityVocabulary: _strings(availability['required_fields']),
      setupGuidesVocabulary: _strings(documentationSupport['outputs']),
      permissionsVocabulary: _strings(
        permissionBoundary['boundary_acceptance'],
      ),
      limitationsVocabulary: _strings(documentationSupport['outputs']),
      quotaNotesVocabulary: _strings(quotaAdapters['acceptance']),
      usageCostNotesVocabulary: _strings(usageCost['cost_vocabulary']),
      recoveryVocabulary: _strings(syncBackup['witness_backup_evidence']),
      knownIssuesVocabulary: _strings(supportDocumentation['outputs']),
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

/// The fail-closed documentation & support gate for step 118.43.
class Sprint118DocumentationSupportGate {
  const Sprint118DocumentationSupportGate();

  Sprint118DocumentationSupportReport evaluate() => evaluateWith(
    const Sprint118DocumentationSupportLoader().loadAnchor(),
    Sprint118DocumentationSupportContract.canonicalRecord,
  );

  Sprint118DocumentationSupportReport evaluateWith(
    Sprint118DocumentationSupportAnchor? anchor,
    Sprint118DocumentationSupportRecord record,
  ) {
    if (anchor == null) {
      return Sprint118DocumentationSupportReport(
        state: Sprint118DocumentationSupportState.blocked,
        verdict: 'SPRINT_118_DOCUMENTATION_SUPPORT_EVIDENCE_UNREADABLE',
        releaseState: record.releaseState,
        blockers: const <String>[
          'committed_documentation_support_evidence_unreadable',
        ],
        openItems: const <String>[
          'committed_documentation_support_evidence_unreadable',
        ],
      );
    }

    final violations = <String>[];
    final blockers = <String>[];
    final openItems = <String>[];

    final frozen =
        anchor.charterMaxNewCertified == 0 &&
        anchor.charterCurrentlyCertified == 0;

    // (1) The 118.2 charter anchor must be a genuine complete charter.
    if (anchor.charterState !=
            Sprint118DocumentationSupportContract.requiredCharterState ||
        anchor.charterVerdict !=
            Sprint118DocumentationSupportContract.requiredCharterVerdict) {
      blockers.add('charter_not_complete:${anchor.charterVerdict}');
    }

    // (2) The 118.3 snapshot anchor must be a genuine frozen pass.
    if (anchor.snapshotState !=
            Sprint118DocumentationSupportContract.requiredSnapshotState ||
        anchor.snapshotVerdict !=
            Sprint118DocumentationSupportContract.requiredSnapshotVerdict) {
      blockers.add('snapshot_not_frozen:${anchor.snapshotVerdict}');
    }

    // (3) The 117.45 approval gate must record the delay decision, read with the
    // owner's exact grammar. If it is not a delay, the anchor is untrustworthy.
    if (anchor.approvalDecision !=
        Sprint118DocumentationSupportContract.requiredApprovalDecision) {
      blockers.add('approval_gate_not_delay:${anchor.approvalDecision}');
    }

    // (4) The registered provider set must reconcile across the icon registry,
    // the 116.3 reconciliation, the frozen snapshot, the charter, the 117.41
    // registry evidence, and the 117.4 snapshot lock.
    if (anchor.registeredProviders.length !=
            Sprint118DocumentationSupportContract.expectedProviderCount ||
        anchor.registryExpectedCount !=
            Sprint118DocumentationSupportContract.expectedProviderCount ||
        anchor.snapshotRegistered !=
            Sprint118DocumentationSupportContract.expectedProviderCount ||
        anchor.charterRegisteredProviders !=
            Sprint118DocumentationSupportContract.expectedProviderCount ||
        anchor.registryEvidenceProviderCount !=
            Sprint118DocumentationSupportContract.expectedProviderCount ||
        anchor.snapshotLockLockedCount !=
            Sprint118DocumentationSupportContract.expectedProviderCount) {
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
        Sprint118DocumentationSupportContract.expectedProviderCount) {
      blockers.add(
        'registry_visibility_not_reconciled:'
        'exposed=${anchor.registryEvidenceExposed}:'
        'withheld=${anchor.registryEvidenceWithheld}',
      );
    }
    if (anchor.registryEvidenceExposed != 0) {
      blockers.add(
        'registry_visibility_exposed_on_delayed_path:'
        '${anchor.registryEvidenceExposed}',
      );
    }

    // (6) The release state must agree with the anchor.
    if (record.releaseState != anchor.releaseState) {
      violations.add(
        'release_state_mismatch:anchor=${anchor.releaseState}:'
        'record=${record.releaseState}',
      );
    }
    if (record.releaseState !=
        Sprint118DocumentationSupportContract.delayedReleaseState) {
      violations.add(
        'documentation_support_not_on_delayed_path:${record.releaseState}',
      );
    }

    final delayed =
        record.releaseState ==
        Sprint118DocumentationSupportContract.delayedReleaseState;

    // (7) On the delayed path an authorized release execution and an unblocked
    // release are behavior that never ran.
    if (delayed && anchor.executionAuthorized) {
      violations.add(
        'documentation_support_execution_authorized_on_delayed_path',
      );
    }
    if (delayed && !anchor.releaseBlocked) {
      violations.add(
        'documentation_support_release_not_blocked_on_delayed_path',
      );
    }

    // (8) The expansion budget must stay frozen: no new certified connector and
    // no already-certified connector while the release is delayed.
    if (!frozen) {
      violations.add(
        'documentation_support_expansion_budget_not_frozen:max_new='
        '${anchor.charterMaxNewCertified}:'
        'currently=${anchor.charterCurrentlyCertified}',
      );
    }
    // The frozen 118.3 snapshot must declare zero certified connectors. A
    // snapshot that already certifies a connector contradicts the delayed path.
    if (anchor.snapshotCertified != 0) {
      violations.add(
        'documentation_support_snapshot_certified_nonzero:'
        '${anchor.snapshotCertified}',
      );
    }

    // (9) Every registered provider must appear exactly once, and each entry
    // must carry all eight canonical documentation & support dimensions
    // non-blank with every dimension grounded by its committed witness
    // vocabulary.
    final declared = <String, int>{};
    for (final entry in record.entries) {
      declared[entry.providerId] = (declared[entry.providerId] ?? 0) + 1;
    }
    for (final entry in record.entries) {
      final id = entry.providerId;
      if (!anchor.registeredProviders.contains(id)) {
        violations.add('documentation_support_provider_unknown:$id');
      }
      for (final field
          in Sprint118DocumentationSupportContract.requiredFields) {
        final value = entry.requiredFields[field] ?? '';
        if (value.trim().isEmpty) {
          violations.add('entry_blank_$field:$id');
        }
      }
      for (final output
          in Sprint118DocumentationSupportContract.requiredOutputs) {
        final token = entry.outputFields[output] ?? '';
        final vocabulary = Sprint118DocumentationSupportContract.vocabularyFor(
          anchor,
          output,
        );
        final grounded =
            token == Sprint118DocumentationSupportContract.noReferenceState ||
            Sprint118DocumentationSupportContract.grounds(vocabulary, token);
        if (token.trim().isEmpty || !grounded) {
          violations.add('reference_state_invalid:$output:$id');
        }
        if (token == Sprint118DocumentationSupportContract.noReferenceState) {
          openItems.add('upstream_state_vocabulary_gap:$output:$id');
        }
      }
      // Documentation is never written without an authorized release.
      if (entry.documented) {
        violations.add(
          'documentation_support_documented_claimed_on_delayed_path:$id',
        );
      }
      // Documentation is never published without an authorized release.
      if (entry.published) {
        violations.add(
          'documentation_support_published_claimed_on_delayed_path:$id',
        );
      }
      // Documentation is never updated live without an authorized release.
      if (entry.updated) {
        violations.add(
          'documentation_support_updated_claimed_on_delayed_path:$id',
        );
      }
      // Documentation is never verified live without live provider evidence.
      if (entry.verified) {
        violations.add(
          'documentation_support_verified_claimed_on_delayed_path:$id',
        );
      }
      // Documentation is never complete without live provider verification.
      if (entry.complete) {
        violations.add(
          'documentation_support_complete_claimed_on_delayed_path:$id',
        );
      }
      // Support is never escalated without a live incident.
      if (entry.supported) {
        violations.add(
          'documentation_support_supported_claimed_on_delayed_path:$id',
        );
      }
      // A connector is never certified without live provider verification.
      if (entry.certified) {
        violations.add(
          'documentation_support_certified_claimed_on_delayed_path:$id',
        );
      }
      // A connector is never released without an authorized release.
      if (entry.released) {
        violations.add('documentation_support_released_claimed:$id');
      }
    }
    for (final id in declared.keys) {
      if (declared[id]! > 1) {
        violations.add('documentation_support_provider_duplicate:$id');
      }
    }
    for (final id in anchor.registeredProviders) {
      if (!declared.containsKey(id)) {
        violations.add('documentation_support_provider_missing:$id');
      }
    }

    // (10) Every committed evidence source must be readable.
    for (final source
        in Sprint118DocumentationSupportContract.witnessSources.toSet()) {
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
      return Sprint118DocumentationSupportReport(
        state: Sprint118DocumentationSupportState.blocked,
        verdict: 'SPRINT_118_DOCUMENTATION_SUPPORT_BLOCKED_UPSTREAM',
        releaseState: record.releaseState,
        violations: violations,
        blockers: blockers,
        openItems: allItems,
        declaredProviders: providers,
        documentedProviders: record.documentedProviders,
        publishedProviders: record.publishedProviders,
        updatedProviders: record.updatedProviders,
        verifiedProviders: record.verifiedProviders,
        certifiedProviders: record.certifiedProviders,
        releasedProviders: record.releasedProviders,
        documentedCount: record.documentedCount,
        publishedCount: record.publishedCount,
        updatedCount: record.updatedCount,
        verifiedCount: record.verifiedCount,
        completeCount: record.completeCount,
        supportedCount: record.supportedCount,
        certifiedCount: record.certifiedCount,
        releasedCount: record.releasedCount,
        expansionBudgetFrozen: frozen,
      );
    }
    if (violations.isNotEmpty) {
      return Sprint118DocumentationSupportReport(
        state: Sprint118DocumentationSupportState.fail,
        verdict: 'SPRINT_118_DOCUMENTATION_SUPPORT_EVIDENCE_VIOLATION',
        releaseState: record.releaseState,
        violations: violations,
        blockers: blockers,
        openItems: allItems,
        declaredProviders: providers,
        documentedProviders: record.documentedProviders,
        publishedProviders: record.publishedProviders,
        updatedProviders: record.updatedProviders,
        verifiedProviders: record.verifiedProviders,
        certifiedProviders: record.certifiedProviders,
        releasedProviders: record.releasedProviders,
        documentedCount: record.documentedCount,
        publishedCount: record.publishedCount,
        updatedCount: record.updatedCount,
        verifiedCount: record.verifiedCount,
        completeCount: record.completeCount,
        supportedCount: record.supportedCount,
        certifiedCount: record.certifiedCount,
        releasedCount: record.releasedCount,
        expansionBudgetFrozen: frozen,
      );
    }
    return Sprint118DocumentationSupportReport(
      state: Sprint118DocumentationSupportState.pass,
      verdict: 'DOCUMENTATION_SUPPORT_UPDATE_VERIFIED_LOCAL',
      releaseState: record.releaseState,
      openItems: allItems,
      declaredProviders: providers,
      documentedProviders: record.documentedProviders,
      publishedProviders: record.publishedProviders,
      updatedProviders: record.updatedProviders,
      verifiedProviders: record.verifiedProviders,
      certifiedProviders: record.certifiedProviders,
      releasedProviders: record.releasedProviders,
      documentedCount: record.documentedCount,
      publishedCount: record.publishedCount,
      updatedCount: record.updatedCount,
      verifiedCount: record.verifiedCount,
      completeCount: record.completeCount,
      supportedCount: record.supportedCount,
      certifiedCount: record.certifiedCount,
      releasedCount: record.releasedCount,
      expansionBudgetFrozen: frozen,
    );
  }
}
