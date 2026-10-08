/// Fail-closed provider expansion evidence inventory for roadmap step 118.29 --
/// Provider Expansion Evidence Inventory.
///
/// Objective (external canonical `sprint_118.json`): inventory demand evidence,
/// workflow value, API feasibility, maintenance cost, security, privacy, and
/// region constraints. The canonical field set is exactly eight items:
/// `provider_id`, `demand_evidence`, `workflow_value`, `api_feasibility`,
/// `maintenance_cost`, `security`, `privacy`, and `region_constraints`.
///
/// The release is delayed. No connector is certified (118.3 froze `CERTIFIED: 0`
/// of `32` registered), the 118.2 charter froze an expansion budget of zero new
/// certified connectors out of 32 registered and declared a 42-day observation
/// window that is not executed, and the committed 117.45 approval gate records
/// `decision=delay`, `approval_state=PENDING_CHOIRUDIN`,
/// `execution_authorized=false`, and `release_blocked=true`. No live demand,
/// workflow value, API feasibility, maintenance cost, security, privacy, or
/// region measurement exists for any provider. A provider expansion evidence
/// inventory written against that state therefore has exactly one honest shape:
/// enumerate all 32 registered providers, anchor each of the seven evidence
/// dimensions to a committed witness vocabulary, claim nothing live, and select
/// no expansion candidate.
///
/// The gate is fail-closed on these families of rules:
///
/// * The committed 118.2 charter anchor must be a genuine complete charter and
///   its expansion budget must stay frozen (`max_new_certified_connectors` and
///   `currently_certified` both zero). An inventory anchored to an unfrozen
///   budget describes an expansion nobody authorized.
/// * The committed 118.3 certified connector snapshot must be a genuine frozen
///   pass (`CERTIFIED_CONNECTOR_SNAPSHOT_FROZEN_LOCAL`). An inventory anchored
///   to an unfrozen snapshot describes a release nobody recorded.
/// * The committed 117.45 approval gate must record the delay decision
///   (`decision == delay`), read with the owner's exact grammar, never
///   case-folded or trimmed into agreement. If it is not a delay, the expansion
///   anchor is untrustworthy and the honest answer is `blocked`, not `fail`.
/// * The registered provider set must reconcile: the icon-registry provider
///   union, the 116.3 reconciliation count, and the frozen snapshot count must
///   agree. An inventory over a drifting registry is not an inventory.
/// * Every registered provider must appear exactly once. A record that drops a
///   provider, invents `telepathy`, or duplicates `openai` is not an inventory.
/// * Every entry must carry all eight canonical fields non-blank, and each of
///   the seven evidence dimensions must be grounded by the committed witness
///   vocabulary for that dimension, so an evidence value cannot be invented into
///   the list without a witness to ground it.
/// * On the delayed path a certified connector, an available endpoint, a
///   measured demand, a live observation, or a released provider describe
///   behavior that never ran. This is refused by name, per entry.
///
/// **A provider is never recorded as expansion-ready without committed
/// certification evidence and an authorized release.** When no connector is
/// certified and no release is authorized, the only honest inventory records a
/// declared reference for each dimension and selects nothing; any live claim is
/// refused by name.
///
/// The evidence vocabulary is *derived from committed witnesses* (the 118.21
/// feedback log `outcome_vocabulary` and `workflow_vocabulary`, the 114.25
/// external dependency `signals`, the 115.17 quota adapter `acceptance`, the
/// 115.50 privacy `data_subjects`, the 115.54 security `required_outputs`, and
/// the 116.42 provider error-state `required_states`), and the source for each
/// dimension is a committed manifest, not copied by hand, so the record and its
/// witnesses cannot drift apart silently.
///
/// Certification, provider exposure, live availability, live demand, cost and
/// quota reads, credential access, and publication remain `DEFERRED-EXTERNAL`;
/// this inventory freezes local declared state and executes none of it.
library;

import 'dart:convert';
import 'dart:io';

/// The three states a provider expansion evidence inventory can rest in.
/// `blocked` is the honest resting state for "this inventory cannot yet be
/// trusted", and it is distinct from `fail`, which means the record contradicts
/// its own evidence.
enum Sprint118ExpansionEvidenceState { pass, fail, blocked }

/// One frozen provider expansion-evidence entry: the declared reference for each
/// of the seven canonical evidence dimensions of a single registered provider.
///
/// `certified`, `available`, `demanded`, `observed`, and `released` are
/// deliberately *not* among the eight required fields; they are the flags the
/// gate refuses when set, so that a declared reference inventory can be recorded
/// while never being read as a certified connector, an available endpoint, a
/// measured demand, a live observation, or a released provider.
class Sprint118ExpansionEvidenceEntry {
  const Sprint118ExpansionEvidenceEntry({
    required this.providerId,
    required this.demandEvidence,
    required this.workflowValue,
    required this.apiFeasibility,
    required this.maintenanceCost,
    required this.security,
    required this.privacy,
    required this.regionConstraints,
    this.certified = false,
    this.available = false,
    this.demanded = false,
    this.observed = false,
    this.released = false,
  });

  /// The registered provider identifier, drawn from the committed icon registry.
  final String providerId;

  /// The demand-evidence reference state, drawn from the committed 118.21
  /// feedback-log outcome vocabulary.
  final String demandEvidence;

  /// The workflow-value reference state, drawn from the committed 118.21
  /// feedback-log workflow vocabulary.
  final String workflowValue;

  /// The API-feasibility reference state, drawn from the committed 114.25
  /// external-dependency signals.
  final String apiFeasibility;

  /// The maintenance-cost reference state, drawn from the committed 115.17 quota
  /// adapter acceptance vocabulary.
  final String maintenanceCost;

  /// The security reference state, drawn from the committed 115.54 security
  /// verification output vocabulary.
  final String security;

  /// The privacy reference state, drawn from the committed 115.50 privacy
  /// data-subject vocabulary.
  final String privacy;

  /// The region-constraint reference state, drawn from the committed 116.42
  /// provider error-state vocabulary.
  final String regionConstraints;

  /// Whether the entry claims a certified connector. On the delayed path this
  /// must stay `false`: a provider is never certified without certification
  /// evidence.
  final bool certified;

  /// Whether the entry claims an available endpoint. On the delayed path this
  /// must stay `false`.
  final bool available;

  /// Whether the entry claims a measured demand. On the delayed path this must
  /// stay `false`.
  final bool demanded;

  /// Whether the entry claims a live observation. On the delayed path this must
  /// stay `false`.
  final bool observed;

  /// Whether the entry claims a released provider. On the delayed path this must
  /// stay `false`.
  final bool released;

  /// The eight canonical fields as a name -> value map, so the gate can test
  /// blankness uniformly.
  Map<String, String> get requiredFields => <String, String>{
    'provider_id': providerId,
    'demand_evidence': demandEvidence,
    'workflow_value': workflowValue,
    'api_feasibility': apiFeasibility,
    'maintenance_cost': maintenanceCost,
    'security': security,
    'privacy': privacy,
    'region_constraints': regionConstraints,
  };

  /// The seven evidence dimensions as a field -> value map, so the gate can test
  /// grounding per dimension.
  Map<String, String> get evidenceFields => <String, String>{
    'demand_evidence': demandEvidence,
    'workflow_value': workflowValue,
    'api_feasibility': apiFeasibility,
    'maintenance_cost': maintenanceCost,
    'security': security,
    'privacy': privacy,
    'region_constraints': regionConstraints,
  };
}

/// The frozen provider expansion evidence inventory. `entries` is the declared
/// reference for each registered provider. On the delayed path no entry may
/// claim a live measurement.
class Sprint118ExpansionEvidenceRecord {
  const Sprint118ExpansionEvidenceRecord({
    required this.releaseState,
    required this.entries,
  });

  final String releaseState;
  final List<Sprint118ExpansionEvidenceEntry> entries;

  List<String> get providerIds => <String>[
    for (final entry in entries) entry.providerId,
  ];

  int get observedCount => entries.where((entry) => entry.observed).length;

  int get certifiedCount => entries.where((entry) => entry.certified).length;
}

/// What the committed witnesses actually say. A gate is only as honest as the
/// witnesses it is anchored to.
class Sprint118ExpansionEvidenceAnchor {
  const Sprint118ExpansionEvidenceAnchor({
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
    required this.approvalDecision,
    required this.approvalState,
    required this.executionAuthorized,
    required this.releaseBlocked,
    required this.registeredProviders,
    required this.demandOutcomes,
    required this.workflows,
    required this.dependencySignals,
    required this.costAcceptance,
    required this.securityOutputs,
    required this.privacySubjects,
    required this.feasibilityStates,
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

  /// The registered provider ids, unioned from the committed 115.8 icon registry.
  final List<String> registeredProviders;

  /// The outcome vocabulary the committed 118.21 feedback log declares. It
  /// grounds the demand-evidence dimension.
  final List<String> demandOutcomes;

  /// The workflow vocabulary the committed 118.21 feedback log declares. It
  /// grounds the workflow-value dimension.
  final List<String> workflows;

  /// The signal vocabulary the committed 114.25 external dependency health
  /// declares. It grounds the API-feasibility dimension.
  final List<String> dependencySignals;

  /// The acceptance vocabulary the committed 115.17 quota adapters declare. It
  /// grounds the maintenance-cost dimension.
  final List<String> costAcceptance;

  /// The output vocabulary the committed 115.54 security verification declares.
  /// It grounds the security dimension.
  final List<String> securityOutputs;

  /// The data-subject vocabulary the committed 115.50 privacy review declares. It
  /// grounds the privacy dimension.
  final List<String> privacySubjects;

  /// The state vocabulary the committed 116.42 provider error-state
  /// certification declares. It grounds the region-constraint dimension.
  final List<String> feasibilityStates;

  /// The committed evidence paths that are present and readable on disk.
  final List<String> readableSources;
}

/// The measured result. `pass` means the inventory is a faithful freeze;
/// `blocked` means it cannot yet be trusted; `fail` means it contradicts its
/// evidence.
class Sprint118ExpansionEvidenceReport {
  const Sprint118ExpansionEvidenceReport({
    required this.state,
    required this.verdict,
    required this.releaseState,
    this.violations = const <String>[],
    this.blockers = const <String>[],
    this.openItems = const <String>[],
    this.declaredProviders = const <String>[],
    this.observedCount = 0,
    this.certifiedCount = 0,
    this.expansionBudgetFrozen = false,
  });

  final Sprint118ExpansionEvidenceState state;
  final String verdict;
  final String releaseState;

  final List<String> violations;
  final List<String> blockers;
  final List<String> openItems;
  final List<String> declaredProviders;
  final int observedCount;
  final int certifiedCount;
  final bool expansionBudgetFrozen;

  /// Whether the inventory may be treated as a frozen expansion-evidence record.
  /// Only a genuine `pass` allows it.
  bool get inventoryVerified => state == Sprint118ExpansionEvidenceState.pass;

  String get externalGates => Sprint118ExpansionEvidenceContract.externalGates;
}

/// The fixed vocabulary and committed witness set for step 118.29.
abstract final class Sprint118ExpansionEvidenceContract {
  const Sprint118ExpansionEvidenceContract._();

  static const String canonicalStep = '118.29';
  static const String title = 'Provider Expansion Evidence Inventory';

  static const String manifestPath =
      'docs/planning/v1.3/sprint_118_provider_expansion_evidence_inventory.json';
  static const String ledgerPath =
      'docs/sprints/sprint-118-account-cloud-center-stability.md';

  /// The committed 118.2 charter that declares the frozen expansion budget.
  static const String charterManifestPath =
      'docs/planning/v1.3/sprint_118_stability_expansion_charter.json';

  /// The committed 118.3 certified connector snapshot this inventory rests on.
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

  /// The committed 118.21 feedback & adoption evidence log that declares the
  /// demand-outcome and workflow vocabularies.
  static const String feedbackLogManifestPath =
      'docs/planning/v1.3/sprint_118_feedback_adoption_evidence_log.json';

  /// The committed 114.25 external dependency health that declares the
  /// API-feasibility signal vocabulary.
  static const String externalDependencyManifestPath =
      'docs/planning/v1.2/sprint_114_provider_external_dependency_health.json';

  /// The committed 115.17 quota adapters that declare the maintenance-cost
  /// acceptance vocabulary.
  static const String quotaAdaptersManifestPath =
      'docs/planning/v1.2/sprint_115_provider_quota_adapters.json';

  /// The committed 115.50 privacy data-flow review that declares the privacy
  /// data-subject vocabulary.
  static const String privacyReviewManifestPath =
      'docs/planning/v1.2/sprint_115_privacy_data_flow_review.json';

  /// The committed 115.54 security verification that declares the security
  /// output vocabulary.
  static const String securityVerificationManifestPath =
      'docs/planning/v1.2/sprint_115_security_billing_verification.json';

  /// The committed 116.42 provider error-state certification that declares the
  /// region-constraint state vocabulary.
  static const String errorStateManifestPath =
      'docs/planning/v1.2/sprint_116_provider_error_state_certification.json';

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

  /// The marker an entry declares when no committed witness names a reference
  /// state for a dimension. A record that uses it records an honest upstream gap
  /// rather than inventing a state.
  static const String noReferenceState = 'no_reference_state';

  /// The canonical field set each entry must carry, so a record cannot drop a
  /// field and still read as complete.
  static const List<String> requiredFields = <String>[
    'provider_id',
    'demand_evidence',
    'workflow_value',
    'api_feasibility',
    'maintenance_cost',
    'security',
    'privacy',
    'region_constraints',
  ];

  /// The seven canonical evidence dimensions named by the objective, in
  /// canonical order. `provider_id` is the key, not a dimension.
  static const List<String> requiredDimensions = <String>[
    'demand_evidence',
    'workflow_value',
    'api_feasibility',
    'maintenance_cost',
    'security',
    'privacy',
    'region_constraints',
  ];

  /// The committed evidence file each canonical dimension is anchored to, in
  /// canonical order.
  static const List<String> canonicalSources = <String>[
    feedbackLogManifestPath,
    feedbackLogManifestPath,
    externalDependencyManifestPath,
    quotaAdaptersManifestPath,
    securityVerificationManifestPath,
    privacyReviewManifestPath,
    errorStateManifestPath,
  ];

  /// The committed evidence files every inventory is anchored to. All must be
  /// readable.
  static const List<String> witnessSources = <String>[
    charterManifestPath,
    snapshotManifestPath,
    approvalGateManifestPath,
    iconRegistryManifestPath,
    registryReconciliationManifestPath,
    feedbackLogManifestPath,
    externalDependencyManifestPath,
    quotaAdaptersManifestPath,
    privacyReviewManifestPath,
    securityVerificationManifestPath,
    errorStateManifestPath,
  ];

  /// The registered provider ids, in first-seen icon-registry order. This is the
  /// canonical inventory key set: every id appears exactly once and no id is
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

  /// The declared workflow value for each provider, keyed by the icon-registry
  /// category the provider belongs to. Every value is a member of the committed
  /// 118.21 workflow vocabulary.
  static const Map<String, String> providerWorkflows = <String, String>{
    'email': 'sharing',
    'google': 'sharing',
    'microsoft': 'sharing',
    'apple': 'sharing',
    'github': 'writer',
    'discord': 'sharing',
    'x': 'sharing',
    'facebook': 'sharing',
    'google_drive': 'sharing',
    'onedrive': 'sharing',
    'dropbox': 'sharing',
    'mega': 'sharing',
    'local_storage': 'sharing',
    'openai': 'writer',
    'gemini': 'writer',
    'anthropic': 'writer',
    'flux': 'simulation',
    'openrouter': 'writer',
    'local_ai': 'writer',
    'gitlab': 'writer',
    'bitbucket': 'writer',
    'azure_devops': 'writer',
    'figma': 'simulation',
    'adobe': 'simulation',
    'canva': 'simulation',
    'blender_cloud': 'simulation',
    'sketchfab': 'simulation',
    'paypal': 'publishing',
    'stripe': 'publishing',
    'midtrans': 'publishing',
    'saweria': 'publishing',
    'kofi': 'publishing',
  };

  /// The declared reference state for the demand-evidence dimension. No live
  /// demand is measured on the delayed path, so the honest reference is the
  /// committed 118.21 no-live-outcome marker.
  static const String demandEvidenceToken = 'no_live_outcome';

  /// The declared reference state for the API-feasibility dimension. Availability
  /// is declared and unverified, so the honest reference is the committed 114.25
  /// availability signal.
  static const String apiFeasibilityToken = 'provider_availability';

  /// The declared reference state for the maintenance-cost dimension. No quota or
  /// cost is available, so the honest reference is the committed 115.17
  /// quota-unavailable marker.
  static const String maintenanceCostToken = 'quota_unavailable';

  /// The declared reference state for the security dimension. The honest
  /// reference is the committed 115.54 permission-boundary verification bucket.
  static const String securityToken = 'permission_tests';

  /// The declared reference state for the privacy dimension. The honest
  /// reference is the committed 115.50 external-transfer data subject.
  static const String privacyToken = 'external_transfers';

  /// The declared reference state for the region-constraint dimension. The honest
  /// reference is the committed 116.42 unsupported-region state.
  static const String regionConstraintsToken = 'unsupported_region';

  /// The committed witness vocabulary that grounds each canonical dimension, in
  /// canonical order.
  static List<List<String>> dimensionVocabularies(
    Sprint118ExpansionEvidenceAnchor anchor,
  ) => <List<String>>[
    anchor.demandOutcomes,
    anchor.workflows,
    anchor.dependencySignals,
    anchor.costAcceptance,
    anchor.securityOutputs,
    anchor.privacySubjects,
    anchor.feasibilityStates,
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
  /// A witness grounds a token when it names the token exactly (`no_live_outcome`,
  /// `unsupported_region`), or when every underscore-separated part of a compound
  /// token is itself a witness-declared value. The vocabulary is measured from the
  /// committed witnesses, so a reference state cannot be invented into the list
  /// without a witness to ground it.
  static bool grounds(List<String> vocabulary, String token) {
    if (vocabulary.contains(token)) return true;
    final parts = token.split('_');
    if (parts.length < 2) return false;
    return parts.every(vocabulary.contains);
  }

  /// The committed witness vocabulary for a canonical dimension, or the empty
  /// list when the dimension is unknown.
  static List<String> vocabularyFor(
    Sprint118ExpansionEvidenceAnchor anchor,
    String dimension,
  ) {
    final index = requiredDimensions.indexOf(dimension);
    if (index < 0) return const <String>[];
    return dimensionVocabularies(anchor)[index];
  }

  /// The committed source for a canonical dimension, or `''` if unknown.
  static String sourceFor(String dimension) {
    final index = requiredDimensions.indexOf(dimension);
    return index < 0 ? '' : canonicalSources[index];
  }

  /// The canonical frozen inventory: every registered provider, each anchored to
  /// the committed witness vocabularies, claiming nothing live.
  static Sprint118ExpansionEvidenceRecord get canonicalRecord =>
      Sprint118ExpansionEvidenceRecord(
        releaseState: delayedReleaseState,
        entries: <Sprint118ExpansionEvidenceEntry>[
          for (final id in canonicalProviders)
            Sprint118ExpansionEvidenceEntry(
              providerId: id,
              demandEvidence: demandEvidenceToken,
              workflowValue: providerWorkflows[id] ?? 'writer',
              apiFeasibility: apiFeasibilityToken,
              maintenanceCost: maintenanceCostToken,
              security: securityToken,
              privacy: privacyToken,
              regionConstraints: regionConstraintsToken,
            ),
        ],
      );
}

/// Reads the committed witnesses for step 118.29. Never invents: an unreadable
/// witness yields `null`, which the gate reports as blocked rather than as a
/// pass.
class Sprint118ExpansionEvidenceLoader {
  const Sprint118ExpansionEvidenceLoader();

  Sprint118ExpansionEvidenceAnchor? loadAnchor() {
    final charter = _read(
      Sprint118ExpansionEvidenceContract.charterManifestPath,
    );
    final snapshot = _read(
      Sprint118ExpansionEvidenceContract.snapshotManifestPath,
    );
    final approval = _read(
      Sprint118ExpansionEvidenceContract.approvalGateManifestPath,
    );
    final icon = _read(
      Sprint118ExpansionEvidenceContract.iconRegistryManifestPath,
    );
    final reconciliation = _read(
      Sprint118ExpansionEvidenceContract.registryReconciliationManifestPath,
    );
    final feedback = _read(
      Sprint118ExpansionEvidenceContract.feedbackLogManifestPath,
    );
    final dependency = _read(
      Sprint118ExpansionEvidenceContract.externalDependencyManifestPath,
    );
    final quota = _read(
      Sprint118ExpansionEvidenceContract.quotaAdaptersManifestPath,
    );
    final privacy = _read(
      Sprint118ExpansionEvidenceContract.privacyReviewManifestPath,
    );
    final security = _read(
      Sprint118ExpansionEvidenceContract.securityVerificationManifestPath,
    );
    final errorState = _read(
      Sprint118ExpansionEvidenceContract.errorStateManifestPath,
    );
    if (charter == null ||
        snapshot == null ||
        approval == null ||
        icon == null ||
        reconciliation == null ||
        feedback == null ||
        dependency == null ||
        quota == null ||
        privacy == null ||
        security == null ||
        errorState == null) {
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

    final sources = Sprint118ExpansionEvidenceContract.witnessSources.toSet();

    return Sprint118ExpansionEvidenceAnchor(
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
      approvalDecision: _text(approvalInner['decision']),
      approvalState: _text(approvalInner['approval_state']),
      executionAuthorized: approvalInner['execution_authorized'] == true,
      releaseBlocked: blockerInner['release_blocked'] == true,
      registeredProviders: registered,
      demandOutcomes: _strings(feedback['outcome_vocabulary']),
      workflows: _strings(feedback['workflow_vocabulary']),
      dependencySignals: _strings(dependency['signals']),
      costAcceptance: _strings(quota['acceptance']),
      securityOutputs: _strings(security['required_outputs']),
      privacySubjects: _strings(privacy['data_subjects']),
      feasibilityStates: _strings(errorState['required_states']),
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

  static List<String> _strings(Object? value) => value is List
      ? <String>[
          for (final item in value)
            if (item is String) item,
        ]
      : const <String>[];

  static int _int(Object? value) => value is int ? value : 0;
}

/// The fail-closed provider expansion evidence inventory gate for step 118.29.
class Sprint118ExpansionEvidenceGate {
  const Sprint118ExpansionEvidenceGate();

  Sprint118ExpansionEvidenceReport evaluate() => evaluateWith(
    const Sprint118ExpansionEvidenceLoader().loadAnchor(),
    Sprint118ExpansionEvidenceContract.canonicalRecord,
  );

  Sprint118ExpansionEvidenceReport evaluateWith(
    Sprint118ExpansionEvidenceAnchor? anchor,
    Sprint118ExpansionEvidenceRecord record,
  ) {
    if (anchor == null) {
      return Sprint118ExpansionEvidenceReport(
        state: Sprint118ExpansionEvidenceState.blocked,
        verdict: 'SPRINT_118_EXPANSION_EVIDENCE_INVENTORY_EVIDENCE_UNREADABLE',
        releaseState: record.releaseState,
        blockers: const <String>['committed_expansion_evidence_unreadable'],
        openItems: const <String>['committed_expansion_evidence_unreadable'],
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
            Sprint118ExpansionEvidenceContract.requiredCharterState ||
        anchor.charterVerdict !=
            Sprint118ExpansionEvidenceContract.requiredCharterVerdict) {
      blockers.add('charter_not_complete:${anchor.charterVerdict}');
    }

    // (2) The 118.3 snapshot anchor must be a genuine frozen pass.
    if (anchor.snapshotState !=
            Sprint118ExpansionEvidenceContract.requiredSnapshotState ||
        anchor.snapshotVerdict !=
            Sprint118ExpansionEvidenceContract.requiredSnapshotVerdict) {
      blockers.add('snapshot_not_frozen:${anchor.snapshotVerdict}');
    }

    // (3) The 117.45 approval gate must record the delay decision, read with the
    // owner's exact grammar. If it is not a delay, the anchor is untrustworthy.
    if (anchor.approvalDecision !=
        Sprint118ExpansionEvidenceContract.requiredApprovalDecision) {
      blockers.add('approval_gate_not_delay:${anchor.approvalDecision}');
    }

    // (4) The registered provider set must reconcile across the icon registry,
    // the 116.3 reconciliation, the frozen snapshot, and the charter.
    if (anchor.registeredProviders.length !=
            Sprint118ExpansionEvidenceContract.expectedProviderCount ||
        anchor.registryExpectedCount !=
            Sprint118ExpansionEvidenceContract.expectedProviderCount ||
        anchor.snapshotRegistered !=
            Sprint118ExpansionEvidenceContract.expectedProviderCount ||
        anchor.charterRegisteredProviders !=
            Sprint118ExpansionEvidenceContract.expectedProviderCount) {
      blockers.add(
        'registry_not_reconciled:icon=${anchor.registeredProviders.length}:'
        'reconciliation=${anchor.registryExpectedCount}:'
        'snapshot=${anchor.snapshotRegistered}:'
        'charter=${anchor.charterRegisteredProviders}',
      );
    }

    // (5) The release state must agree with the anchor.
    if (record.releaseState != anchor.releaseState) {
      violations.add(
        'release_state_mismatch:anchor=${anchor.releaseState}:'
        'record=${record.releaseState}',
      );
    }
    if (record.releaseState !=
        Sprint118ExpansionEvidenceContract.delayedReleaseState) {
      violations.add(
        'expansion_inventory_not_on_delayed_path:${record.releaseState}',
      );
    }

    final delayed =
        record.releaseState ==
        Sprint118ExpansionEvidenceContract.delayedReleaseState;

    // (6) On the delayed path an authorized release execution and an unblocked
    // release are behavior that never ran.
    if (delayed && anchor.executionAuthorized) {
      violations.add('expansion_execution_authorized_on_delayed_path');
    }
    if (delayed && !anchor.releaseBlocked) {
      violations.add('expansion_release_not_blocked_on_delayed_path');
    }

    // (7) The expansion budget must stay frozen: no new certified connector and
    // no already-certified connector while the release is delayed.
    if (!frozen) {
      violations.add(
        'expansion_budget_not_frozen:max_new=${anchor.charterMaxNewCertified}:'
        'currently=${anchor.charterCurrentlyCertified}',
      );
    }

    // (8) Every registered provider must appear exactly once, and each entry must
    // carry all eight canonical fields non-blank with every evidence dimension
    // grounded by its committed witness vocabulary.
    final declared = <String, int>{};
    for (final entry in record.entries) {
      declared[entry.providerId] = (declared[entry.providerId] ?? 0) + 1;
    }
    for (final entry in record.entries) {
      final id = entry.providerId;
      if (!anchor.registeredProviders.contains(id)) {
        violations.add('expansion_provider_unknown:$id');
      }
      for (final field in Sprint118ExpansionEvidenceContract.requiredFields) {
        final value = entry.requiredFields[field] ?? '';
        if (value.trim().isEmpty) {
          violations.add('entry_blank_$field:$id');
        }
      }
      for (final dimension
          in Sprint118ExpansionEvidenceContract.requiredDimensions) {
        final token = entry.evidenceFields[dimension] ?? '';
        final vocabulary = Sprint118ExpansionEvidenceContract.vocabularyFor(
          anchor,
          dimension,
        );
        final grounded =
            token == Sprint118ExpansionEvidenceContract.noReferenceState ||
            Sprint118ExpansionEvidenceContract.grounds(vocabulary, token);
        if (token.trim().isEmpty || !grounded) {
          violations.add('reference_state_invalid:$dimension:$id');
        }
        if (token == Sprint118ExpansionEvidenceContract.noReferenceState) {
          openItems.add('upstream_state_vocabulary_gap:$dimension:$id');
        }
      }
      // A provider is never certified without certification evidence.
      if (entry.certified) {
        violations.add('expansion_provider_certified_claimed:$id');
      }
      // An endpoint is never available without a live probe.
      if (entry.available) {
        violations.add('expansion_provider_available_claimed:$id');
      }
      // Demand is never measured without live adoption evidence.
      if (entry.demanded) {
        violations.add('expansion_provider_demanded_claimed:$id');
      }
      // No live observation on the delayed path.
      if (entry.observed) {
        violations.add('expansion_provider_observed_claimed:$id');
      }
      // A provider is never released without an authorized release.
      if (entry.released) {
        violations.add('expansion_provider_released_claimed:$id');
      }
    }
    for (final id in declared.keys) {
      if (declared[id]! > 1) {
        violations.add('expansion_provider_duplicate:$id');
      }
    }
    for (final id in anchor.registeredProviders) {
      if (!declared.containsKey(id)) {
        violations.add('expansion_provider_missing:$id');
      }
    }

    // (9) Every committed evidence source must be readable.
    for (final source
        in Sprint118ExpansionEvidenceContract.witnessSources.toSet()) {
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
      return Sprint118ExpansionEvidenceReport(
        state: Sprint118ExpansionEvidenceState.blocked,
        verdict: 'SPRINT_118_EXPANSION_EVIDENCE_INVENTORY_BLOCKED_UPSTREAM',
        releaseState: record.releaseState,
        violations: violations,
        blockers: blockers,
        openItems: allItems,
        declaredProviders: providers,
        observedCount: record.observedCount,
        certifiedCount: record.certifiedCount,
        expansionBudgetFrozen: frozen,
      );
    }
    if (violations.isNotEmpty) {
      return Sprint118ExpansionEvidenceReport(
        state: Sprint118ExpansionEvidenceState.fail,
        verdict: 'SPRINT_118_EXPANSION_EVIDENCE_INVENTORY_EVIDENCE_VIOLATION',
        releaseState: record.releaseState,
        violations: violations,
        blockers: blockers,
        openItems: allItems,
        declaredProviders: providers,
        observedCount: record.observedCount,
        certifiedCount: record.certifiedCount,
        expansionBudgetFrozen: frozen,
      );
    }
    return Sprint118ExpansionEvidenceReport(
      state: Sprint118ExpansionEvidenceState.pass,
      verdict: 'PROVIDER_EXPANSION_EVIDENCE_INVENTORY_VERIFIED_LOCAL',
      releaseState: record.releaseState,
      openItems: allItems,
      declaredProviders: providers,
      observedCount: record.observedCount,
      certifiedCount: record.certifiedCount,
      expansionBudgetFrozen: frozen,
    );
  }
}
