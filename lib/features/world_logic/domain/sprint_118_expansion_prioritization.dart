/// Fail-closed expansion prioritization for roadmap step 118.30 -- Expansion
/// Prioritization.
///
/// Objective (external canonical `sprint_118.json`): prioritize providers by
/// value, evidence, feasibility, risk, support cost, and strategic fit. The
/// canonical criterion set is exactly seven items: `user_value`,
/// `evidence_strength`, `feasibility`, `risk`, `maintenance`, `support_cost`,
/// and `strategic_fit`.
///
/// The release is delayed. No connector is certified (118.3 froze `CERTIFIED: 0`
/// of `32` registered), the 118.2 charter froze an expansion budget of zero new
/// certified connectors out of 32 registered and declared a 42-day observation
/// window that is not executed, the committed 118.29 inventory enumerated all 32
/// providers as declared references claiming nothing live, and the committed
/// 117.45 approval gate records `decision=delay`, `approval_state=PENDING_CHOIRUDIN`,
/// `execution_authorized=false`, and `release_blocked=true`. No live user value,
/// evidence strength, feasibility, risk, maintenance, support cost, or strategic
/// fit has been measured for any provider. An expansion prioritization written
/// against that state therefore has exactly one honest shape: enumerate all 32
/// registered providers, anchor each of the seven criteria to a committed
/// witness vocabulary, rank and recommend nothing, and select no provider as an
/// expansion priority.
///
/// The gate is fail-closed on these families of rules:
///
/// * The committed 118.2 charter anchor must be a genuine complete charter and
///   its expansion budget must stay frozen (`max_new_certified_connectors` and
///   `currently_certified` both zero). A prioritization anchored to an unfrozen
///   budget ranks an expansion nobody authorized.
/// * The committed 118.3 certified connector snapshot must be a genuine frozen
///   pass (`CERTIFIED_CONNECTOR_SNAPSHOT_FROZEN_LOCAL`). A prioritization
///   anchored to an unfrozen snapshot ranks a release nobody recorded.
/// * The committed 117.45 approval gate must record the delay decision
///   (`decision == delay`), read with the owner's exact grammar, never
///   case-folded or trimmed into agreement. If it is not a delay, the expansion
///   anchor is untrustworthy and the honest answer is `blocked`, not `fail`.
/// * The registered provider set must reconcile: the icon-registry provider
///   union, the 116.3 reconciliation count, the frozen snapshot count, and the
///   charter count must agree. A prioritization over a drifting registry is not
///   a prioritization.
/// * Every registered provider must appear exactly once. A record that drops a
///   provider, invents `telepathy`, or duplicates `openai` is not a
///   prioritization.
/// * Every entry must carry all eight canonical fields non-blank, and each of
///   the seven criteria must be grounded by the committed witness vocabulary for
///   that criterion, so a priority value cannot be invented into the list
///   without a witness to ground it.
/// * On the delayed path a prioritized provider, a ranking, a recommendation, a
///   certified connector, or a released provider describe behavior that never
///   ran. This is refused by name, per entry.
///
/// **A provider is never recorded as an expansion priority without committed
/// certification evidence and an authorized release.** When no connector is
/// certified and no release is authorized, the only honest prioritization
/// records a declared reference for each criterion and selects nothing; any
/// prioritized, ranked, recommended, certified, or released claim is refused by
/// name.
///
/// The criterion vocabulary is *derived from committed witnesses* (the 118.21
/// feedback log `outcome_vocabulary`, the 118.29 inventory `required_dimensions`,
/// the 114.25 external dependency `signals`, the 118.2 charter `stop_conditions`
/// metrics and `stability_questions` areas, the 114.42 technical-debt
/// `deferred_checks`, and the 117.6 support-readiness `severity_levels`), and the
/// source for each criterion is a committed manifest, not copied by hand, so the
/// record and its witnesses cannot drift apart silently.
///
/// Certification, provider exposure, live availability, live demand, cost and
/// quota reads, credential access, and publication remain `DEFERRED-EXTERNAL`;
/// this prioritization freezes local declared state and executes none of it.
library;

import 'dart:convert';
import 'dart:io';

/// The three states an expansion prioritization can rest in. `blocked` is the
/// honest resting state for "this prioritization cannot yet be trusted", and it
/// is distinct from `fail`, which means the record contradicts its own evidence.
enum Sprint118ExpansionPriorityState { pass, fail, blocked }

/// One frozen expansion-priority entry: the declared reference for each of the
/// seven canonical criteria of a single registered provider.
///
/// `prioritized`, `ranked`, `recommended`, `certified`, and `released` are
/// deliberately *not* among the eight required fields; they are the flags the
/// gate refuses when set, so that a declared reference prioritization can be
/// recorded while never being read as a selected provider, a ranked provider, a
/// recommended provider, a certified connector, or a released provider.
class Sprint118ExpansionPriorityEntry {
  const Sprint118ExpansionPriorityEntry({
    required this.providerId,
    required this.userValue,
    required this.evidenceStrength,
    required this.feasibility,
    required this.risk,
    required this.maintenance,
    required this.supportCost,
    required this.strategicFit,
    this.prioritized = false,
    this.ranked = false,
    this.recommended = false,
    this.certified = false,
    this.released = false,
  });

  /// The registered provider identifier, drawn from the committed icon registry.
  final String providerId;

  /// The user-value reference state, drawn from the committed 118.21 feedback-log
  /// outcome vocabulary.
  final String userValue;

  /// The evidence-strength reference state, drawn from the committed 118.29
  /// inventory evidence dimensions.
  final String evidenceStrength;

  /// The feasibility reference state, drawn from the committed 114.25
  /// external-dependency signals.
  final String feasibility;

  /// The risk reference state, drawn from the committed 118.2 charter stop
  /// conditions.
  final String risk;

  /// The maintenance reference state, drawn from the committed 114.42
  /// technical-debt deferred checks.
  final String maintenance;

  /// The support-cost reference state, drawn from the committed 117.6 support
  /// incident readiness severity levels.
  final String supportCost;

  /// The strategic-fit reference state, drawn from the committed 118.2 charter
  /// stability questions.
  final String strategicFit;

  /// Whether the entry selects the provider as an expansion priority. On the
  /// delayed path this must stay `false`: a provider is never prioritized
  /// without certification evidence and an authorized release.
  final bool prioritized;

  /// Whether the entry ranks the provider. On the delayed path this must stay
  /// `false`.
  final bool ranked;

  /// Whether the entry recommends the provider. On the delayed path this must
  /// stay `false`.
  final bool recommended;

  /// Whether the entry claims a certified connector. On the delayed path this
  /// must stay `false`.
  final bool certified;

  /// Whether the entry claims a released provider. On the delayed path this must
  /// stay `false`.
  final bool released;

  /// The eight canonical fields as a name -> value map, so the gate can test
  /// blankness uniformly.
  Map<String, String> get requiredFields => <String, String>{
    'provider_id': providerId,
    'user_value': userValue,
    'evidence_strength': evidenceStrength,
    'feasibility': feasibility,
    'risk': risk,
    'maintenance': maintenance,
    'support_cost': supportCost,
    'strategic_fit': strategicFit,
  };

  /// The seven criteria as a criterion -> value map, so the gate can test
  /// grounding per criterion.
  Map<String, String> get criteriaFields => <String, String>{
    'user_value': userValue,
    'evidence_strength': evidenceStrength,
    'feasibility': feasibility,
    'risk': risk,
    'maintenance': maintenance,
    'support_cost': supportCost,
    'strategic_fit': strategicFit,
  };
}

/// The frozen expansion prioritization. `entries` is the declared reference for
/// each registered provider. On the delayed path no entry may claim a live
/// priority.
class Sprint118ExpansionPriorityRecord {
  const Sprint118ExpansionPriorityRecord({
    required this.releaseState,
    required this.entries,
  });

  final String releaseState;
  final List<Sprint118ExpansionPriorityEntry> entries;

  List<String> get providerIds => <String>[
    for (final entry in entries) entry.providerId,
  ];

  /// The providers the record selects as an expansion priority. On the delayed
  /// path this must stay empty.
  List<String> get selectedProviders => <String>[
    for (final entry in entries)
      if (entry.prioritized) entry.providerId,
  ];

  int get prioritizedCount =>
      entries.where((entry) => entry.prioritized).length;

  int get rankedCount => entries.where((entry) => entry.ranked).length;

  int get recommendedCount =>
      entries.where((entry) => entry.recommended).length;
}

/// What the committed witnesses actually say. A gate is only as honest as the
/// witnesses it is anchored to.
class Sprint118ExpansionPriorityAnchor {
  const Sprint118ExpansionPriorityAnchor({
    required this.charterState,
    required this.charterVerdict,
    required this.charterMaxNewCertified,
    required this.charterCurrentlyCertified,
    required this.charterRegisteredProviders,
    required this.charterStopMetrics,
    required this.charterStrategicAreas,
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
    required this.userValueVocabulary,
    required this.evidenceStrengthVocabulary,
    required this.feasibilityVocabulary,
    required this.maintenanceVocabulary,
    required this.supportCostVocabulary,
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

  /// The stop-condition metric ids the committed 118.2 charter declares. They
  /// ground the risk criterion.
  final List<String> charterStopMetrics;

  /// The stability-question areas the committed 118.2 charter declares. They
  /// ground the strategic-fit criterion.
  final List<String> charterStrategicAreas;

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
  /// grounds the user-value criterion.
  final List<String> userValueVocabulary;

  /// The evidence-dimension vocabulary the committed 118.29 inventory declares.
  /// It grounds the evidence-strength criterion.
  final List<String> evidenceStrengthVocabulary;

  /// The signal vocabulary the committed 114.25 external dependency health
  /// declares. It grounds the feasibility criterion.
  final List<String> feasibilityVocabulary;

  /// The deferred-check vocabulary the committed 114.42 technical-debt register
  /// declares. It grounds the maintenance criterion.
  final List<String> maintenanceVocabulary;

  /// The severity vocabulary the committed 117.6 support incident readiness
  /// declares. It grounds the support-cost criterion.
  final List<String> supportCostVocabulary;

  /// The committed evidence paths that are present and readable on disk.
  final List<String> readableSources;
}

/// The measured result. `pass` means the prioritization is a faithful freeze;
/// `blocked` means it cannot yet be trusted; `fail` means it contradicts its
/// evidence.
class Sprint118ExpansionPriorityReport {
  const Sprint118ExpansionPriorityReport({
    required this.state,
    required this.verdict,
    required this.releaseState,
    this.violations = const <String>[],
    this.blockers = const <String>[],
    this.openItems = const <String>[],
    this.declaredProviders = const <String>[],
    this.selectedProviders = const <String>[],
    this.prioritizedCount = 0,
    this.rankedCount = 0,
    this.recommendedCount = 0,
    this.expansionBudgetFrozen = false,
  });

  final Sprint118ExpansionPriorityState state;
  final String verdict;
  final String releaseState;

  final List<String> violations;
  final List<String> blockers;
  final List<String> openItems;
  final List<String> declaredProviders;
  final List<String> selectedProviders;
  final int prioritizedCount;
  final int rankedCount;
  final int recommendedCount;
  final bool expansionBudgetFrozen;

  /// Whether the prioritization may be treated as a frozen expansion-priority
  /// record. Only a genuine `pass` allows it.
  bool get prioritizationVerified =>
      state == Sprint118ExpansionPriorityState.pass;

  String get externalGates => Sprint118ExpansionPriorityContract.externalGates;
}

/// The fixed vocabulary and committed witness set for step 118.30.
abstract final class Sprint118ExpansionPriorityContract {
  const Sprint118ExpansionPriorityContract._();

  static const String canonicalStep = '118.30';
  static const String title = 'Expansion Prioritization';

  static const String manifestPath =
      'docs/planning/v1.3/sprint_118_expansion_prioritization.json';
  static const String ledgerPath =
      'docs/sprints/sprint-118-account-cloud-center-stability.md';

  /// The committed 118.2 charter that declares the frozen expansion budget, the
  /// stop conditions, and the stability questions.
  static const String charterManifestPath =
      'docs/planning/v1.3/sprint_118_stability_expansion_charter.json';

  /// The committed 118.3 certified connector snapshot this prioritization rests
  /// on.
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
  /// user-value outcome vocabulary.
  static const String feedbackLogManifestPath =
      'docs/planning/v1.3/sprint_118_feedback_adoption_evidence_log.json';

  /// The committed 118.29 provider expansion evidence inventory that declares the
  /// evidence-dimension vocabulary.
  static const String expansionInventoryManifestPath =
      'docs/planning/v1.3/sprint_118_provider_expansion_evidence_inventory.json';

  /// The committed 114.25 external dependency health that declares the
  /// feasibility signal vocabulary.
  static const String externalDependencyManifestPath =
      'docs/planning/v1.2/sprint_114_provider_external_dependency_health.json';

  /// The committed 114.42 technical debt & deferred risk register that declares
  /// the maintenance deferred-check vocabulary.
  static const String technicalDebtManifestPath =
      'docs/planning/v1.2/sprint_114_technical_debt_deferred_risk_register.json';

  /// The committed 117.6 support incident readiness that declares the
  /// support-cost severity vocabulary.
  static const String supportReadinessManifestPath =
      'docs/planning/v1.3/sprint_117_support_incident_readiness.json';

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
  /// state for a criterion. A record that uses it records an honest upstream gap
  /// rather than inventing a state.
  static const String noReferenceState = 'no_reference_state';

  /// The canonical field set each entry must carry, so a record cannot drop a
  /// field and still read as complete.
  static const List<String> requiredFields = <String>[
    'provider_id',
    'user_value',
    'evidence_strength',
    'feasibility',
    'risk',
    'maintenance',
    'support_cost',
    'strategic_fit',
  ];

  /// The seven canonical criteria named by the objective, in canonical order.
  /// `provider_id` is the key, not a criterion.
  static const List<String> requiredCriteria = <String>[
    'user_value',
    'evidence_strength',
    'feasibility',
    'risk',
    'maintenance',
    'support_cost',
    'strategic_fit',
  ];

  /// The committed evidence file each canonical criterion is anchored to, in
  /// canonical order.
  static const List<String> canonicalSources = <String>[
    feedbackLogManifestPath,
    expansionInventoryManifestPath,
    externalDependencyManifestPath,
    charterManifestPath,
    technicalDebtManifestPath,
    supportReadinessManifestPath,
    charterManifestPath,
  ];

  /// The committed evidence files every prioritization is anchored to. All must
  /// be readable.
  static const List<String> witnessSources = <String>[
    charterManifestPath,
    snapshotManifestPath,
    approvalGateManifestPath,
    iconRegistryManifestPath,
    registryReconciliationManifestPath,
    feedbackLogManifestPath,
    expansionInventoryManifestPath,
    externalDependencyManifestPath,
    technicalDebtManifestPath,
    supportReadinessManifestPath,
  ];

  /// The registered provider ids, in first-seen icon-registry order. This is the
  /// canonical prioritization key set: every id appears exactly once and no id is
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

  /// The declared reference state for the user-value criterion. No live user
  /// value is measured on the delayed path, so the honest reference is the
  /// committed 118.21 no-live-outcome marker.
  static const String userValueToken = 'no_live_outcome';

  /// The declared reference state for the evidence-strength criterion. Evidence
  /// is declared and unmeasured, so the honest reference is a committed 118.29
  /// evidence dimension.
  static const String evidenceStrengthToken = 'demand_evidence';

  /// The declared reference state for the feasibility criterion. Availability is
  /// declared and unverified, so the honest reference is the committed 114.25
  /// availability signal.
  static const String feasibilityToken = 'provider_availability';

  /// The declared reference state for the risk criterion. Risk is a declared stop
  /// condition, not a measured rate, so the honest reference is the committed
  /// 118.2 error-rate stop condition.
  static const String riskToken = 'error_rate';

  /// The declared reference state for the maintenance criterion. Maintenance is
  /// deferred, so the honest reference is the committed 114.42 hosted-CI
  /// deferred check.
  static const String maintenanceToken = 'hosted_ci_validation';

  /// The declared reference state for the support-cost criterion. Support cost is
  /// a declared severity, not a measured cost, so the honest reference is the
  /// committed 117.6 lowest severity level.
  static const String supportCostToken = 'P3';

  /// The declared reference state for the strategic-fit criterion. Strategic fit
  /// is a declared charter area, not a measured fit, so the honest reference is
  /// the committed 118.2 provider-outage-recovery area.
  static const String strategicFitToken = 'provider_outage_recovery';

  /// The committed witness vocabulary that grounds each canonical criterion, in
  /// canonical order.
  static List<List<String>> criteriaVocabularies(
    Sprint118ExpansionPriorityAnchor anchor,
  ) => <List<String>>[
    anchor.userValueVocabulary,
    anchor.evidenceStrengthVocabulary,
    anchor.feasibilityVocabulary,
    anchor.charterStopMetrics,
    anchor.maintenanceVocabulary,
    anchor.supportCostVocabulary,
    anchor.charterStrategicAreas,
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
  /// `P3`, `error_rate`), or when every underscore-separated part of a compound
  /// token is itself a witness-declared value. The vocabulary is measured from the
  /// committed witnesses, so a reference state cannot be invented into the list
  /// without a witness to ground it.
  static bool grounds(List<String> vocabulary, String token) {
    if (vocabulary.contains(token)) return true;
    final parts = token.split('_');
    if (parts.length < 2) return false;
    return parts.every(vocabulary.contains);
  }

  /// The committed witness vocabulary for a canonical criterion, or the empty
  /// list when the criterion is unknown.
  static List<String> vocabularyFor(
    Sprint118ExpansionPriorityAnchor anchor,
    String criterion,
  ) {
    final index = requiredCriteria.indexOf(criterion);
    if (index < 0) return const <String>[];
    return criteriaVocabularies(anchor)[index];
  }

  /// The committed source for a canonical criterion, or `''` if unknown.
  static String sourceFor(String criterion) {
    final index = requiredCriteria.indexOf(criterion);
    return index < 0 ? '' : canonicalSources[index];
  }

  /// The canonical frozen prioritization: every registered provider, each
  /// anchored to the committed witness vocabularies, ranking and recommending
  /// nothing and claiming nothing live.
  static Sprint118ExpansionPriorityRecord get canonicalRecord =>
      Sprint118ExpansionPriorityRecord(
        releaseState: delayedReleaseState,
        entries: <Sprint118ExpansionPriorityEntry>[
          for (final id in canonicalProviders)
            Sprint118ExpansionPriorityEntry(
              providerId: id,
              userValue: userValueToken,
              evidenceStrength: evidenceStrengthToken,
              feasibility: feasibilityToken,
              risk: riskToken,
              maintenance: maintenanceToken,
              supportCost: supportCostToken,
              strategicFit: strategicFitToken,
            ),
        ],
      );
}

/// Reads the committed witnesses for step 118.30. Never invents: an unreadable
/// witness yields `null`, which the gate reports as blocked rather than as a
/// pass.
class Sprint118ExpansionPriorityLoader {
  const Sprint118ExpansionPriorityLoader();

  Sprint118ExpansionPriorityAnchor? loadAnchor() {
    final charter = _read(
      Sprint118ExpansionPriorityContract.charterManifestPath,
    );
    final snapshot = _read(
      Sprint118ExpansionPriorityContract.snapshotManifestPath,
    );
    final approval = _read(
      Sprint118ExpansionPriorityContract.approvalGateManifestPath,
    );
    final icon = _read(
      Sprint118ExpansionPriorityContract.iconRegistryManifestPath,
    );
    final reconciliation = _read(
      Sprint118ExpansionPriorityContract.registryReconciliationManifestPath,
    );
    final feedback = _read(
      Sprint118ExpansionPriorityContract.feedbackLogManifestPath,
    );
    final inventory = _read(
      Sprint118ExpansionPriorityContract.expansionInventoryManifestPath,
    );
    final dependency = _read(
      Sprint118ExpansionPriorityContract.externalDependencyManifestPath,
    );
    final technicalDebt = _read(
      Sprint118ExpansionPriorityContract.technicalDebtManifestPath,
    );
    final support = _read(
      Sprint118ExpansionPriorityContract.supportReadinessManifestPath,
    );
    if (charter == null ||
        snapshot == null ||
        approval == null ||
        icon == null ||
        reconciliation == null ||
        feedback == null ||
        inventory == null ||
        dependency == null ||
        technicalDebt == null ||
        support == null) {
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

    final sources = Sprint118ExpansionPriorityContract.witnessSources.toSet();

    return Sprint118ExpansionPriorityAnchor(
      charterState: _text(charter['state']),
      charterVerdict: _text(charter['verdict']),
      charterMaxNewCertified: _int(budgetMap['max_new_certified_connectors']),
      charterCurrentlyCertified: _int(budgetMap['currently_certified']),
      charterRegisteredProviders: _int(budgetMap['registered_providers']),
      charterStopMetrics: _field(charter['stop_conditions'], 'metric_id'),
      charterStrategicAreas: _field(charter['stability_questions'], 'area'),
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
      userValueVocabulary: _strings(feedback['outcome_vocabulary']),
      evidenceStrengthVocabulary: _strings(inventory['required_dimensions']),
      feasibilityVocabulary: _strings(dependency['signals']),
      maintenanceVocabulary: _strings(technicalDebt['deferred_checks']),
      supportCostVocabulary: _strings(support['severity_levels']),
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

  /// Reads a named string field out of each map in a list, so a list of records
  /// (`stop_conditions`, `stability_questions`) yields its declared vocabulary.
  static List<String> _field(Object? value, String key) => value is List
      ? <String>[
          for (final item in value)
            if (item is Map && item[key] is String) item[key] as String,
        ]
      : const <String>[];

  static int _int(Object? value) => value is int ? value : 0;
}

/// The fail-closed expansion prioritization gate for step 118.30.
class Sprint118ExpansionPriorityGate {
  const Sprint118ExpansionPriorityGate();

  Sprint118ExpansionPriorityReport evaluate() => evaluateWith(
    const Sprint118ExpansionPriorityLoader().loadAnchor(),
    Sprint118ExpansionPriorityContract.canonicalRecord,
  );

  Sprint118ExpansionPriorityReport evaluateWith(
    Sprint118ExpansionPriorityAnchor? anchor,
    Sprint118ExpansionPriorityRecord record,
  ) {
    if (anchor == null) {
      return Sprint118ExpansionPriorityReport(
        state: Sprint118ExpansionPriorityState.blocked,
        verdict: 'SPRINT_118_EXPANSION_PRIORITIZATION_EVIDENCE_UNREADABLE',
        releaseState: record.releaseState,
        blockers: const <String>[
          'committed_expansion_priority_evidence_unreadable',
        ],
        openItems: const <String>[
          'committed_expansion_priority_evidence_unreadable',
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
            Sprint118ExpansionPriorityContract.requiredCharterState ||
        anchor.charterVerdict !=
            Sprint118ExpansionPriorityContract.requiredCharterVerdict) {
      blockers.add('charter_not_complete:${anchor.charterVerdict}');
    }

    // (2) The 118.3 snapshot anchor must be a genuine frozen pass.
    if (anchor.snapshotState !=
            Sprint118ExpansionPriorityContract.requiredSnapshotState ||
        anchor.snapshotVerdict !=
            Sprint118ExpansionPriorityContract.requiredSnapshotVerdict) {
      blockers.add('snapshot_not_frozen:${anchor.snapshotVerdict}');
    }

    // (3) The 117.45 approval gate must record the delay decision, read with the
    // owner's exact grammar. If it is not a delay, the anchor is untrustworthy.
    if (anchor.approvalDecision !=
        Sprint118ExpansionPriorityContract.requiredApprovalDecision) {
      blockers.add('approval_gate_not_delay:${anchor.approvalDecision}');
    }

    // (4) The registered provider set must reconcile across the icon registry,
    // the 116.3 reconciliation, the frozen snapshot, and the charter.
    if (anchor.registeredProviders.length !=
            Sprint118ExpansionPriorityContract.expectedProviderCount ||
        anchor.registryExpectedCount !=
            Sprint118ExpansionPriorityContract.expectedProviderCount ||
        anchor.snapshotRegistered !=
            Sprint118ExpansionPriorityContract.expectedProviderCount ||
        anchor.charterRegisteredProviders !=
            Sprint118ExpansionPriorityContract.expectedProviderCount) {
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
        Sprint118ExpansionPriorityContract.delayedReleaseState) {
      violations.add(
        'expansion_prioritization_not_on_delayed_path:${record.releaseState}',
      );
    }

    final delayed =
        record.releaseState ==
        Sprint118ExpansionPriorityContract.delayedReleaseState;

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
    // carry all eight canonical fields non-blank with every criterion grounded by
    // its committed witness vocabulary.
    final declared = <String, int>{};
    for (final entry in record.entries) {
      declared[entry.providerId] = (declared[entry.providerId] ?? 0) + 1;
    }
    for (final entry in record.entries) {
      final id = entry.providerId;
      if (!anchor.registeredProviders.contains(id)) {
        violations.add('expansion_provider_unknown:$id');
      }
      for (final field in Sprint118ExpansionPriorityContract.requiredFields) {
        final value = entry.requiredFields[field] ?? '';
        if (value.trim().isEmpty) {
          violations.add('entry_blank_$field:$id');
        }
      }
      for (final criterion
          in Sprint118ExpansionPriorityContract.requiredCriteria) {
        final token = entry.criteriaFields[criterion] ?? '';
        final vocabulary = Sprint118ExpansionPriorityContract.vocabularyFor(
          anchor,
          criterion,
        );
        final grounded =
            token == Sprint118ExpansionPriorityContract.noReferenceState ||
            Sprint118ExpansionPriorityContract.grounds(vocabulary, token);
        if (token.trim().isEmpty || !grounded) {
          violations.add('reference_state_invalid:$criterion:$id');
        }
        if (token == Sprint118ExpansionPriorityContract.noReferenceState) {
          openItems.add('upstream_state_vocabulary_gap:$criterion:$id');
        }
      }
      // A provider is never selected as an expansion priority without
      // certification evidence and an authorized release.
      if (entry.prioritized) {
        violations.add('expansion_priority_claimed_on_delayed_path:$id');
      }
      // A provider is never ranked without a measured priority.
      if (entry.ranked) {
        violations.add('expansion_rank_claimed_on_delayed_path:$id');
      }
      // A provider is never recommended without a measured priority.
      if (entry.recommended) {
        violations.add('expansion_recommendation_claimed_on_delayed_path:$id');
      }
      // A provider is never certified without certification evidence.
      if (entry.certified) {
        violations.add('expansion_provider_certified_claimed:$id');
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
        in Sprint118ExpansionPriorityContract.witnessSources.toSet()) {
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
      return Sprint118ExpansionPriorityReport(
        state: Sprint118ExpansionPriorityState.blocked,
        verdict: 'SPRINT_118_EXPANSION_PRIORITIZATION_BLOCKED_UPSTREAM',
        releaseState: record.releaseState,
        violations: violations,
        blockers: blockers,
        openItems: allItems,
        declaredProviders: providers,
        selectedProviders: record.selectedProviders,
        prioritizedCount: record.prioritizedCount,
        rankedCount: record.rankedCount,
        recommendedCount: record.recommendedCount,
        expansionBudgetFrozen: frozen,
      );
    }
    if (violations.isNotEmpty) {
      return Sprint118ExpansionPriorityReport(
        state: Sprint118ExpansionPriorityState.fail,
        verdict: 'SPRINT_118_EXPANSION_PRIORITIZATION_EVIDENCE_VIOLATION',
        releaseState: record.releaseState,
        violations: violations,
        blockers: blockers,
        openItems: allItems,
        declaredProviders: providers,
        selectedProviders: record.selectedProviders,
        prioritizedCount: record.prioritizedCount,
        rankedCount: record.rankedCount,
        recommendedCount: record.recommendedCount,
        expansionBudgetFrozen: frozen,
      );
    }
    return Sprint118ExpansionPriorityReport(
      state: Sprint118ExpansionPriorityState.pass,
      verdict: 'EXPANSION_PRIORITIZATION_VERIFIED_LOCAL',
      releaseState: record.releaseState,
      openItems: allItems,
      declaredProviders: providers,
      selectedProviders: record.selectedProviders,
      prioritizedCount: record.prioritizedCount,
      rankedCount: record.rankedCount,
      recommendedCount: record.recommendedCount,
      expansionBudgetFrozen: frozen,
    );
  }
}
