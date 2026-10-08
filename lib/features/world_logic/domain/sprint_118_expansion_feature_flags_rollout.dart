/// Fail-closed expansion feature flags and rollout record for roadmap step
/// 118.41 -- Expansion Feature Flags & Rollout.
///
/// Objective (external canonical `sprint_118.json`): determine `audience`,
/// `defaults`, `dependencies`, `health criteria`, `kill switch`, `rollback`, and
/// `support` for the new connectors. The canonical field set is exactly eight
/// fields: `flag`, `audience`, `default`, `dependencies`, `health_criteria`,
/// `kill_switch`, `rollback`, and `support`.
///
/// The release is delayed. No connector is certified (118.3 froze `CERTIFIED: 0`
/// of `32` registered; the committed 117.41 registry evidence records
/// `UNVERIFIED: 32`, `EXPOSED: 0`, `WITHHELD: 32`), the 118.2 charter froze an
/// expansion budget of zero new certified connectors out of 32 registered, and
/// the committed 117.45 approval gate records `decision=delay`,
/// `approval_state=PENDING_CHOIRUDIN`, `execution_authorized=false`, and
/// `release_blocked=true`. No feature flag has been flipped, no rollout stage
/// has been advanced, no kill switch has been drilled against a live provider,
/// no rollback has been executed, and no support escalation has fired. A feature
/// flags and rollout record written against that state therefore has exactly one
/// honest shape: enumerate all 32 registered providers, anchor each of the eight
/// rollout outputs to a committed witness vocabulary, claim no flag flipped and
/// no rollout executed, and certify no connector.
///
/// The gate is fail-closed on these families of rules:
///
/// * The committed 118.2 charter anchor must be a genuine complete charter and
///   its expansion budget must stay frozen (`max_new_certified_connectors` and
///   `currently_certified` both zero). A rollout anchored to an unfrozen budget
///   flips flags nobody authorized.
/// * The committed 118.3 certified connector snapshot must be a genuine frozen
///   pass (`CERTIFIED_CONNECTOR_SNAPSHOT_FROZEN_LOCAL`). A rollout anchored to
///   an unfrozen snapshot rests on a release nobody recorded.
/// * The committed 117.45 approval gate must record the delay decision
///   (`decision == delay`), read with the owner's exact grammar, never
///   case-folded or trimmed into agreement. If it is not a delay, the anchor is
///   untrustworthy and the honest answer is `blocked`, not `fail`.
/// * The registered provider set must reconcile: the icon-registry provider
///   union, the 116.3 reconciliation count, the frozen snapshot count, the
///   charter count, the 117.41 registry evidence count, and the 117.4 snapshot
///   lock count must all agree. A rollout over a drifting registry is not a
///   rollout.
/// * The committed 117.41 registry visibility counts must reconcile (`EXPOSED`
///   plus `WITHHELD` equals the registered count) and must record zero exposed
///   providers while the release is delayed. A registry that already exposes a
///   connector contradicts the frozen zero-certified state.
/// * Every registered provider must appear exactly once. A record that drops a
///   provider, invents `telepathy`, or duplicates `stripe` is not a record.
/// * Every entry must carry all eight canonical fields non-blank, and each of
///   the eight rollout outputs must be grounded by the committed witness
///   vocabulary for that output, so a rollout reference cannot be invented into
///   the list without a witness to ground it.
/// * On the delayed path an enabled connector, a flipped flag, an advanced
///   rollout, a drilled kill switch, an executed rollback, an active support
///   escalation, a certified connector, or a released connector describe
///   behavior that never ran. This is refused by name, per entry.
///
/// **A connector is never recorded as enabled without live provider
/// verification and an authorized release.** When no flag has been flipped and
/// no release is authorized, the only honest record states the committed
/// reference for each rollout output and claims nothing live; any enabled,
/// flipped, rolled-out, drilled, rollback-executed, supported, certified, or
/// released claim is refused by name.
///
/// The output vocabulary is *derived from committed witnesses* (the 116.50
/// staged beta rollout monitoring `flags`/`health_metrics`/`provider_kill_switches`/
/// `rollback`, the 117.41 beta exposure flag matrix `matrix.audience`, the 112.6
/// feature flag rollout matrix `default_policy`, the 113.13 feature flag
/// dependency validation `dependency_matrix.cross_dependencies`, and the 117.44
/// staged GA rollout plan `support`/117.47 support incident readiness `owners`),
/// and the source for each output is a committed manifest, not copied by hand,
/// so the record and its witnesses cannot drift apart silently.
///
/// Connector enablement, feature-flag flipping, rollout advancement, kill-switch
/// drilling, rollback execution, support escalation, connector certification,
/// connector release, and publication remain `DEFERRED-EXTERNAL`; this record
/// freezes local declared state and executes none of it.
library;

import 'dart:convert';
import 'dart:io';

/// The three states a rollout record can rest in. `blocked` is the honest
/// resting state for "this record cannot yet be trusted", and it is distinct
/// from `fail`, which means the record contradicts its own evidence.
enum Sprint118ExpansionFeatureFlagState { pass, fail, blocked }

/// One frozen rollout record entry: the declared reference for each of the eight
/// canonical rollout outputs of a single registered provider.
///
/// `enabled`, `flipped`, `rolledOut`, `killSwitchDrilled`, `rollbackExecuted`,
/// `supported`, `certified`, and `released` are deliberately *not* among the
/// eight required fields; they are the flags the gate refuses when set, so that
/// a declared reference record can be recorded while never being read as an
/// enabled connector, a flipped flag, an advanced rollout, a drilled kill
/// switch, an executed rollback, an active support escalation, a certified
/// connector, or a released connector.
class Sprint118ExpansionFeatureFlagEntry {
  const Sprint118ExpansionFeatureFlagEntry({
    required this.providerId,
    required this.flag,
    required this.audience,
    required this.defaultState,
    required this.dependencies,
    required this.healthCriteria,
    required this.killSwitch,
    required this.rollback,
    required this.support,
    this.enabled = false,
    this.flipped = false,
    this.rolledOut = false,
    this.killSwitchDrilled = false,
    this.rollbackExecuted = false,
    this.supported = false,
    this.certified = false,
    this.released = false,
  });

  /// The registered provider identifier, drawn from the committed icon registry.
  final String providerId;

  /// The flag reference state, drawn from the committed 116.50 staged beta
  /// rollout monitoring `flags[].flag_key`.
  final String flag;

  /// The audience reference state, drawn from the committed 117.41 beta exposure
  /// flag matrix `matrix[].audience`.
  final String audience;

  /// The default reference state, drawn from the committed 112.6 feature flag
  /// rollout matrix `default_policy`.
  final String defaultState;

  /// The dependency reference state, drawn from the committed 113.13 feature
  /// flag dependency validation `dependency_matrix.cross_dependencies`.
  final String dependencies;

  /// The health-criteria reference state, drawn from the committed 116.50
  /// staged beta rollout monitoring `health_metrics[].metric_id`.
  final String healthCriteria;

  /// The kill-switch reference state, drawn from the committed 116.50 staged
  /// beta rollout monitoring `provider_kill_switches[].kill_id`.
  final String killSwitch;

  /// The rollback reference state, drawn from the committed 116.50 staged beta
  /// rollout monitoring `rollback[].rollback_id`.
  final String rollback;

  /// The support reference state, drawn from the committed 117.44 staged GA
  /// rollout plan `support[].owner`.
  final String support;

  /// Whether the entry claims the connector is enabled. On the delayed path this
  /// must stay `false`.
  final bool enabled;

  /// Whether the entry claims the flag was flipped. On the delayed path this
  /// must stay `false`.
  final bool flipped;

  /// Whether the entry claims the rollout stage advanced. On the delayed path
  /// this must stay `false`.
  final bool rolledOut;

  /// Whether the entry claims a kill switch was drilled against a live provider.
  /// On the delayed path this must stay `false`.
  final bool killSwitchDrilled;

  /// Whether the entry claims a rollback was executed. On the delayed path this
  /// must stay `false`.
  final bool rollbackExecuted;

  /// Whether the entry claims an active support escalation. On the delayed path
  /// this must stay `false`.
  final bool supported;

  /// Whether the entry claims the connector was certified. On the delayed path
  /// this must stay `false`.
  final bool certified;

  /// Whether the entry claims the connector was released. On the delayed path
  /// this must stay `false`.
  final bool released;

  /// The eight canonical fields as a name -> value map, so the gate can test
  /// blankness uniformly.
  Map<String, String> get requiredFields => <String, String>{
    'flag': flag,
    'audience': audience,
    'default': defaultState,
    'dependencies': dependencies,
    'health_criteria': healthCriteria,
    'kill_switch': killSwitch,
    'rollback': rollback,
    'support': support,
  };

  /// The eight rollout outputs as an output -> value map, so the gate can test
  /// grounding per output.
  Map<String, String> get outputFields => requiredFields;
}

/// The frozen rollout record. `entries` is the declared reference for each
/// registered provider. On the delayed path no entry may claim a live rollout.
class Sprint118ExpansionFeatureFlagRecord {
  const Sprint118ExpansionFeatureFlagRecord({
    required this.releaseState,
    required this.entries,
  });

  final String releaseState;
  final List<Sprint118ExpansionFeatureFlagEntry> entries;

  List<String> get providerIds => <String>[
    for (final entry in entries) entry.providerId,
  ];

  /// The providers the record claims were enabled. On the delayed path this must
  /// stay empty.
  List<String> get enabledProviders => <String>[
    for (final entry in entries)
      if (entry.enabled) entry.providerId,
  ];

  /// The providers the record claims had a flag flipped. On the delayed path
  /// this must stay empty.
  List<String> get flippedProviders => <String>[
    for (final entry in entries)
      if (entry.flipped) entry.providerId,
  ];

  /// The providers the record claims had the rollout advanced. On the delayed
  /// path this must stay empty.
  List<String> get rolledOutProviders => <String>[
    for (final entry in entries)
      if (entry.rolledOut) entry.providerId,
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

  int get enabledCount => entries.where((entry) => entry.enabled).length;

  int get flippedCount => entries.where((entry) => entry.flipped).length;

  int get rolledOutCount => entries.where((entry) => entry.rolledOut).length;

  int get certifiedCount => entries.where((entry) => entry.certified).length;

  int get releasedCount => entries.where((entry) => entry.released).length;
}

/// What the committed witnesses actually say. A gate is only as honest as the
/// witnesses it is anchored to.
class Sprint118ExpansionFeatureFlagAnchor {
  const Sprint118ExpansionFeatureFlagAnchor({
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
    required this.flagVocabulary,
    required this.audienceVocabulary,
    required this.defaultVocabulary,
    required this.dependencyVocabulary,
    required this.healthVocabulary,
    required this.killSwitchVocabulary,
    required this.rollbackVocabulary,
    required this.supportVocabulary,
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

  /// The flag vocabulary the committed 116.50 staged beta rollout monitoring
  /// declares. It grounds the flag output.
  final List<String> flagVocabulary;

  /// The audience vocabulary the committed 117.41 beta exposure flag matrix
  /// declares. It grounds the audience output.
  final List<String> audienceVocabulary;

  /// The default vocabulary the committed 112.6 feature flag rollout matrix
  /// declares. It grounds the default output.
  final List<String> defaultVocabulary;

  /// The dependency vocabulary the committed 113.13 feature flag dependency
  /// validation declares. It grounds the dependencies output.
  final List<String> dependencyVocabulary;

  /// The health-criteria vocabulary the committed 116.50 staged beta rollout
  /// monitoring declares. It grounds the health_criteria output.
  final List<String> healthVocabulary;

  /// The kill-switch vocabulary the committed 116.50 staged beta rollout
  /// monitoring declares. It grounds the kill_switch output.
  final List<String> killSwitchVocabulary;

  /// The rollback vocabulary the committed 116.50 staged beta rollout
  /// monitoring declares. It grounds the rollback output.
  final List<String> rollbackVocabulary;

  /// The support vocabulary the committed 117.44 staged GA rollout plan and the
  /// committed 117.47 support incident readiness declare. It grounds the
  /// support output.
  final List<String> supportVocabulary;

  /// The committed evidence paths that are present and readable on disk.
  final List<String> readableSources;
}

/// The measured result. `pass` means the record is a faithful rollout freeze;
/// `blocked` means it cannot yet be trusted; `fail` means it contradicts its
/// evidence.
class Sprint118ExpansionFeatureFlagReport {
  const Sprint118ExpansionFeatureFlagReport({
    required this.state,
    required this.verdict,
    required this.releaseState,
    this.violations = const <String>[],
    this.blockers = const <String>[],
    this.openItems = const <String>[],
    this.declaredProviders = const <String>[],
    this.enabledProviders = const <String>[],
    this.flippedProviders = const <String>[],
    this.rolledOutProviders = const <String>[],
    this.certifiedProviders = const <String>[],
    this.releasedProviders = const <String>[],
    this.enabledCount = 0,
    this.flippedCount = 0,
    this.rolledOutCount = 0,
    this.certifiedCount = 0,
    this.releasedCount = 0,
    this.expansionBudgetFrozen = false,
  });

  final Sprint118ExpansionFeatureFlagState state;
  final String verdict;
  final String releaseState;

  final List<String> violations;
  final List<String> blockers;
  final List<String> openItems;
  final List<String> declaredProviders;
  final List<String> enabledProviders;
  final List<String> flippedProviders;
  final List<String> rolledOutProviders;
  final List<String> certifiedProviders;
  final List<String> releasedProviders;
  final int enabledCount;
  final int flippedCount;
  final int rolledOutCount;
  final int certifiedCount;
  final int releasedCount;
  final bool expansionBudgetFrozen;

  /// Whether the record may be treated as a frozen rollout freeze. Only a
  /// genuine `pass` allows it.
  bool get recordVerified => state == Sprint118ExpansionFeatureFlagState.pass;

  String get externalGates =>
      Sprint118ExpansionFeatureFlagContract.externalGates;
}

/// The fixed vocabulary and committed witness set for step 118.41.
abstract final class Sprint118ExpansionFeatureFlagContract {
  const Sprint118ExpansionFeatureFlagContract._();

  static const String canonicalStep = '118.41';
  static const String title = 'Expansion Feature Flags & Rollout';

  static const String manifestPath =
      'docs/planning/v1.3/sprint_118_expansion_feature_flags_rollout.json';
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

  /// The committed 117.41 beta exposure flag matrix that grounds the audience
  /// output and the provider registry evidence.
  static const String betaExposureFlagMatrixPath =
      'docs/planning/v1.3/sprint_117_beta_exposure_flag_matrix.json';

  /// The committed 112.6 feature flag rollout matrix that grounds the default
  /// output.
  static const String featureFlagRolloutMatrixPath =
      'docs/planning/v1.2/sprint_112_feature_flag_rollout_matrix.json';

  /// The committed 113.13 feature flag dependency validation that grounds the
  /// dependencies output.
  static const String featureFlagDependencyPath =
      'docs/planning/v1.2/sprint_113_feature_flag_dependency_validation.json';

  /// The committed 116.50 staged beta rollout monitoring that grounds the flag,
  /// health_criteria, kill_switch, and rollback outputs.
  static const String stagedBetaRolloutPath =
      'docs/planning/v1.2/sprint_116_staged_beta_rollout_monitoring.json';

  /// The committed 117.44 staged GA rollout plan that grounds the support
  /// output.
  static const String stagedGaRolloutPath =
      'docs/planning/v1.3/sprint_117_staged_ga_rollout_plan.json';

  /// The committed 117.47 support incident readiness that grounds the support
  /// output.
  static const String supportIncidentPath =
      'docs/planning/v1.3/sprint_117_support_incident_readiness.json';

  /// The committed 117.41 connector-registry evidence that declares the provider
  /// count and the visibility counts.
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

  /// The number of registered providers the committed witnesses reconcile to.
  static const int expectedProviderCount = 32;

  /// The number of canonical rollout outputs the objective names.
  static const int expectedOutputCount = 8;

  /// The marker an entry declares when no committed witness names a reference
  /// state for an output. A record that uses it records an honest upstream gap
  /// rather than inventing a state.
  static const String noReferenceState = 'no_reference_state';

  /// The canonical field set each entry must carry, so a record cannot drop a
  /// field and still read as complete.
  static const List<String> requiredFields = <String>[
    'flag',
    'audience',
    'default',
    'dependencies',
    'health_criteria',
    'kill_switch',
    'rollback',
    'support',
  ];

  /// The eight canonical rollout outputs named by the objective, in canonical
  /// order.
  static const List<String> requiredOutputs = requiredFields;

  /// The committed evidence file each canonical output is anchored to, in
  /// canonical order.
  static const List<String> canonicalSources = <String>[
    stagedBetaRolloutPath,
    betaExposureFlagMatrixPath,
    featureFlagRolloutMatrixPath,
    featureFlagDependencyPath,
    stagedBetaRolloutPath,
    stagedBetaRolloutPath,
    stagedBetaRolloutPath,
    stagedGaRolloutPath,
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
    betaExposureFlagMatrixPath,
    featureFlagRolloutMatrixPath,
    featureFlagDependencyPath,
    stagedBetaRolloutPath,
    stagedGaRolloutPath,
    supportIncidentPath,
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

  /// The declared reference state for the flag output. No flag is resolvable
  /// through the shipped registry on the delayed path, so the honest reference
  /// is the committed 116.50 staged beta rollout monitoring master flag
  /// (`beta.connectors.enabled`).
  static const String flagToken = 'beta.connectors.enabled';

  /// The declared reference state for the audience output. No cohort is verified
  /// on the delayed path, so the honest reference is the committed 117.41 beta
  /// exposure flag matrix first rollout stage (`stage_internal`).
  static const String audienceToken = 'stage_internal';

  /// The declared reference state for the default output. No flag is enabled on
  /// the delayed path, so the honest reference is the committed 112.6 feature
  /// flag rollout matrix default policy (`OFF`).
  static const String defaultToken = 'OFF';

  /// The declared reference state for the dependencies output. No cross-flag
  /// dependency is recorded on the delayed path, so the honest reference is the
  /// committed 113.13 feature flag dependency validation
  /// (`cross_dependencies=none`).
  static const String dependenciesToken = 'none';

  /// The declared reference state for the health_criteria output. No live
  /// rollout is measured on the delayed path, so the honest reference is the
  /// committed 116.50 staged beta rollout monitoring first health metric
  /// (`metric_error_rate`).
  static const String healthCriteriaToken = 'metric_error_rate';

  /// The declared reference state for the kill_switch output. No kill switch has
  /// been drilled against a live provider on the delayed path, so the honest
  /// reference is the committed 116.50 staged beta rollout monitoring first kill
  /// switch (`kill_openai`).
  static const String killSwitchToken = 'kill_openai';

  /// The declared reference state for the rollback output. No rollback has been
  /// executed on the delayed path, so the honest reference is the committed
  /// 116.50 staged beta rollout monitoring first rollback (`rb_internal`).
  static const String rollbackToken = 'rb_internal';

  /// The declared reference state for the support output. No support escalation
  /// has fired on the delayed path, so the honest reference is the committed
  /// 117.44 staged GA rollout plan support owner (`support-owner`).
  static const String supportToken = 'support-owner';

  /// The committed witness vocabulary that grounds each canonical output, in
  /// canonical order.
  static List<List<String>> outputVocabularies(
    Sprint118ExpansionFeatureFlagAnchor anchor,
  ) => <List<String>>[
    anchor.flagVocabulary,
    anchor.audienceVocabulary,
    anchor.defaultVocabulary,
    anchor.dependencyVocabulary,
    anchor.healthVocabulary,
    anchor.killSwitchVocabulary,
    anchor.rollbackVocabulary,
    anchor.supportVocabulary,
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
  /// (`beta.connectors.enabled`, `stage_internal`, `OFF`), or when every
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

  /// The committed witness vocabulary for a canonical output, or the empty list
  /// when the output is unknown.
  static List<String> vocabularyFor(
    Sprint118ExpansionFeatureFlagAnchor anchor,
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
  static Sprint118ExpansionFeatureFlagRecord get canonicalRecord =>
      Sprint118ExpansionFeatureFlagRecord(
        releaseState: delayedReleaseState,
        entries: <Sprint118ExpansionFeatureFlagEntry>[
          for (final id in canonicalProviders)
            Sprint118ExpansionFeatureFlagEntry(
              providerId: id,
              flag: flagToken,
              audience: audienceToken,
              defaultState: defaultToken,
              dependencies: dependenciesToken,
              healthCriteria: healthCriteriaToken,
              killSwitch: killSwitchToken,
              rollback: rollbackToken,
              support: supportToken,
            ),
        ],
      );
}

/// Reads the committed witnesses for step 118.41. Never invents: an unreadable
/// witness yields `null`, which the gate reports as blocked rather than as a
/// pass.
class Sprint118ExpansionFeatureFlagLoader {
  const Sprint118ExpansionFeatureFlagLoader();

  Sprint118ExpansionFeatureFlagAnchor? loadAnchor() {
    final charter = _read(
      Sprint118ExpansionFeatureFlagContract.charterManifestPath,
    );
    final snapshot = _read(
      Sprint118ExpansionFeatureFlagContract.snapshotManifestPath,
    );
    final approval = _read(
      Sprint118ExpansionFeatureFlagContract.approvalGateManifestPath,
    );
    final icon = _read(
      Sprint118ExpansionFeatureFlagContract.iconRegistryManifestPath,
    );
    final reconciliation = _read(
      Sprint118ExpansionFeatureFlagContract.registryReconciliationManifestPath,
    );
    final lock = _read(
      Sprint118ExpansionFeatureFlagContract.snapshotLockManifestPath,
    );
    final betaExposure = _read(
      Sprint118ExpansionFeatureFlagContract.betaExposureFlagMatrixPath,
    );
    final rolloutMatrix = _read(
      Sprint118ExpansionFeatureFlagContract.featureFlagRolloutMatrixPath,
    );
    final dependency = _read(
      Sprint118ExpansionFeatureFlagContract.featureFlagDependencyPath,
    );
    final stagedBeta = _read(
      Sprint118ExpansionFeatureFlagContract.stagedBetaRolloutPath,
    );
    final stagedGa = _read(
      Sprint118ExpansionFeatureFlagContract.stagedGaRolloutPath,
    );
    final support = _read(
      Sprint118ExpansionFeatureFlagContract.supportIncidentPath,
    );
    final registry = _read(
      Sprint118ExpansionFeatureFlagContract.registryEvidencePath,
    );
    if (charter == null ||
        snapshot == null ||
        approval == null ||
        icon == null ||
        reconciliation == null ||
        lock == null ||
        betaExposure == null ||
        rolloutMatrix == null ||
        dependency == null ||
        stagedBeta == null ||
        stagedGa == null ||
        support == null ||
        registry == null) {
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

    // Audience vocabulary: the 117.41 beta exposure flag matrix flattens each
    // row's `audience` list into rollout stage ids.
    final audience = <String>[];
    final matrix = betaExposure['matrix'];
    if (matrix is List) {
      for (final row in matrix) {
        if (row is Map<String, dynamic>) {
          final values = row['audience'];
          if (values is List) {
            for (final item in values) {
              if (item is String &&
                  item.trim().isNotEmpty &&
                  !audience.contains(item)) {
                audience.add(item);
              }
            }
          }
        }
      }
    }

    // Support vocabulary: the 117.44 staged GA rollout plan support owners and
    // the 117.47 support incident readiness owners.
    final supportVocab = <String>[];
    final supportRows = stagedGa['support'];
    if (supportRows is List) {
      for (final row in supportRows) {
        if (row is Map<String, dynamic>) {
          final owner = row['owner'];
          if (owner is String &&
              owner.trim().isNotEmpty &&
              !supportVocab.contains(owner)) {
            supportVocab.add(owner);
          }
        }
      }
    }
    for (final owner in _strings(support['owners'])) {
      if (!supportVocab.contains(owner)) supportVocab.add(owner);
    }

    final sources = Sprint118ExpansionFeatureFlagContract.witnessSources
        .toSet();

    return Sprint118ExpansionFeatureFlagAnchor(
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
      flagVocabulary: _column(stagedBeta['flags'], 'flag_key'),
      audienceVocabulary: audience,
      defaultVocabulary: _strings(rolloutMatrix['default_policy']),
      dependencyVocabulary: _nestedText(
        dependency['dependency_matrix'],
        'cross_dependencies',
      ),
      healthVocabulary: _column(stagedBeta['health_metrics'], 'metric_id'),
      killSwitchVocabulary: _column(
        stagedBeta['provider_kill_switches'],
        'kill_id',
      ),
      rollbackVocabulary: _column(stagedBeta['rollback'], 'rollback_id'),
      supportVocabulary: supportVocab,
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

  /// Read a scalar string field from a nested map, coerced to a one-element
  /// vocabulary.
  static List<String> _nestedText(Object? map, String key) {
    if (map is Map<String, dynamic>) return _strings(map[key]);
    return const <String>[];
  }

  static int _int(Object? value) => value is int ? value : 0;
}

/// The fail-closed expansion feature flags and rollout gate for step 118.41.
class Sprint118ExpansionFeatureFlagGate {
  const Sprint118ExpansionFeatureFlagGate();

  Sprint118ExpansionFeatureFlagReport evaluate() => evaluateWith(
    const Sprint118ExpansionFeatureFlagLoader().loadAnchor(),
    Sprint118ExpansionFeatureFlagContract.canonicalRecord,
  );

  Sprint118ExpansionFeatureFlagReport evaluateWith(
    Sprint118ExpansionFeatureFlagAnchor? anchor,
    Sprint118ExpansionFeatureFlagRecord record,
  ) {
    if (anchor == null) {
      return Sprint118ExpansionFeatureFlagReport(
        state: Sprint118ExpansionFeatureFlagState.blocked,
        verdict: 'SPRINT_118_FEATURE_FLAGS_ROLLOUT_EVIDENCE_UNREADABLE',
        releaseState: record.releaseState,
        blockers: const <String>[
          'committed_feature_flags_rollout_evidence_unreadable',
        ],
        openItems: const <String>[
          'committed_feature_flags_rollout_evidence_unreadable',
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
            Sprint118ExpansionFeatureFlagContract.requiredCharterState ||
        anchor.charterVerdict !=
            Sprint118ExpansionFeatureFlagContract.requiredCharterVerdict) {
      blockers.add('charter_not_complete:${anchor.charterVerdict}');
    }

    // (2) The 118.3 snapshot anchor must be a genuine frozen pass.
    if (anchor.snapshotState !=
            Sprint118ExpansionFeatureFlagContract.requiredSnapshotState ||
        anchor.snapshotVerdict !=
            Sprint118ExpansionFeatureFlagContract.requiredSnapshotVerdict) {
      blockers.add('snapshot_not_frozen:${anchor.snapshotVerdict}');
    }

    // (3) The 117.45 approval gate must record the delay decision, read with the
    // owner's exact grammar. If it is not a delay, the anchor is untrustworthy.
    if (anchor.approvalDecision !=
        Sprint118ExpansionFeatureFlagContract.requiredApprovalDecision) {
      blockers.add('approval_gate_not_delay:${anchor.approvalDecision}');
    }

    // (4) The registered provider set must reconcile across the icon registry,
    // the 116.3 reconciliation, the frozen snapshot, the charter, the 117.41
    // registry evidence, and the 117.4 snapshot lock.
    if (anchor.registeredProviders.length !=
            Sprint118ExpansionFeatureFlagContract.expectedProviderCount ||
        anchor.registryExpectedCount !=
            Sprint118ExpansionFeatureFlagContract.expectedProviderCount ||
        anchor.snapshotRegistered !=
            Sprint118ExpansionFeatureFlagContract.expectedProviderCount ||
        anchor.charterRegisteredProviders !=
            Sprint118ExpansionFeatureFlagContract.expectedProviderCount ||
        anchor.registryEvidenceProviderCount !=
            Sprint118ExpansionFeatureFlagContract.expectedProviderCount ||
        anchor.snapshotLockLockedCount !=
            Sprint118ExpansionFeatureFlagContract.expectedProviderCount) {
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
        Sprint118ExpansionFeatureFlagContract.expectedProviderCount) {
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
        Sprint118ExpansionFeatureFlagContract.delayedReleaseState) {
      violations.add(
        'expansion_feature_flags_not_on_delayed_path:${record.releaseState}',
      );
    }

    final delayed =
        record.releaseState ==
        Sprint118ExpansionFeatureFlagContract.delayedReleaseState;

    // (7) On the delayed path an authorized release execution and an unblocked
    // release are behavior that never ran.
    if (delayed && anchor.executionAuthorized) {
      violations.add(
        'expansion_feature_flags_execution_authorized_on_delayed_path',
      );
    }
    if (delayed && !anchor.releaseBlocked) {
      violations.add(
        'expansion_feature_flags_release_not_blocked_on_delayed_path',
      );
    }

    // (8) The expansion budget must stay frozen: no new certified connector and
    // no already-certified connector while the release is delayed.
    if (!frozen) {
      violations.add(
        'expansion_feature_flags_expansion_budget_not_frozen:max_new='
        '${anchor.charterMaxNewCertified}:'
        'currently=${anchor.charterCurrentlyCertified}',
      );
    }
    // The frozen 118.3 snapshot must declare zero certified connectors. A
    // snapshot that already certifies a connector contradicts the delayed path.
    if (anchor.snapshotCertified != 0) {
      violations.add(
        'expansion_feature_flags_snapshot_certified_nonzero:'
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
        violations.add('expansion_feature_flags_provider_unknown:$id');
      }
      for (final field
          in Sprint118ExpansionFeatureFlagContract.requiredFields) {
        final value = entry.requiredFields[field] ?? '';
        if (value.trim().isEmpty) {
          violations.add('entry_blank_$field:$id');
        }
      }
      for (final output
          in Sprint118ExpansionFeatureFlagContract.requiredOutputs) {
        final token = entry.outputFields[output] ?? '';
        final vocabulary = Sprint118ExpansionFeatureFlagContract.vocabularyFor(
          anchor,
          output,
        );
        final grounded =
            token == Sprint118ExpansionFeatureFlagContract.noReferenceState ||
            Sprint118ExpansionFeatureFlagContract.grounds(vocabulary, token);
        if (token.trim().isEmpty || !grounded) {
          violations.add('reference_state_invalid:$output:$id');
        }
        if (token == Sprint118ExpansionFeatureFlagContract.noReferenceState) {
          openItems.add('upstream_state_vocabulary_gap:$output:$id');
        }
      }
      // A connector is never enabled without an authorized release.
      if (entry.enabled) {
        violations.add(
          'expansion_feature_flags_enabled_claimed_on_delayed_path:$id',
        );
      }
      // A flag is never flipped without an authorized release.
      if (entry.flipped) {
        violations.add(
          'expansion_feature_flags_flipped_claimed_on_delayed_path:$id',
        );
      }
      // A rollout is never advanced without an authorized release.
      if (entry.rolledOut) {
        violations.add(
          'expansion_feature_flags_rolled_out_claimed_on_delayed_path:$id',
        );
      }
      // A kill switch is never drilled against a live provider on the delayed
      // path.
      if (entry.killSwitchDrilled) {
        violations.add(
          'expansion_feature_flags_kill_switch_drilled_claimed_on_delayed_path:'
          '$id',
        );
      }
      // A rollback is never executed on the delayed path.
      if (entry.rollbackExecuted) {
        violations.add(
          'expansion_feature_flags_rollback_executed_claimed_on_delayed_path:'
          '$id',
        );
      }
      // A support escalation never fires on the delayed path.
      if (entry.supported) {
        violations.add(
          'expansion_feature_flags_supported_claimed_on_delayed_path:$id',
        );
      }
      // A connector is never certified without live provider verification.
      if (entry.certified) {
        violations.add(
          'expansion_feature_flags_certified_claimed_on_delayed_path:$id',
        );
      }
      // A connector is never released without an authorized release.
      if (entry.released) {
        violations.add('expansion_feature_flags_released_claimed:$id');
      }
    }
    for (final id in declared.keys) {
      if (declared[id]! > 1) {
        violations.add('expansion_feature_flags_provider_duplicate:$id');
      }
    }
    for (final id in anchor.registeredProviders) {
      if (!declared.containsKey(id)) {
        violations.add('expansion_feature_flags_provider_missing:$id');
      }
    }

    // (10) Every committed evidence source must be readable.
    for (final source
        in Sprint118ExpansionFeatureFlagContract.witnessSources.toSet()) {
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
      return Sprint118ExpansionFeatureFlagReport(
        state: Sprint118ExpansionFeatureFlagState.blocked,
        verdict: 'SPRINT_118_FEATURE_FLAGS_ROLLOUT_BLOCKED_UPSTREAM',
        releaseState: record.releaseState,
        violations: violations,
        blockers: blockers,
        openItems: allItems,
        declaredProviders: providers,
        enabledProviders: record.enabledProviders,
        flippedProviders: record.flippedProviders,
        rolledOutProviders: record.rolledOutProviders,
        certifiedProviders: record.certifiedProviders,
        releasedProviders: record.releasedProviders,
        enabledCount: record.enabledCount,
        flippedCount: record.flippedCount,
        rolledOutCount: record.rolledOutCount,
        certifiedCount: record.certifiedCount,
        releasedCount: record.releasedCount,
        expansionBudgetFrozen: frozen,
      );
    }
    if (violations.isNotEmpty) {
      return Sprint118ExpansionFeatureFlagReport(
        state: Sprint118ExpansionFeatureFlagState.fail,
        verdict: 'SPRINT_118_FEATURE_FLAGS_ROLLOUT_EVIDENCE_VIOLATION',
        releaseState: record.releaseState,
        violations: violations,
        blockers: blockers,
        openItems: allItems,
        declaredProviders: providers,
        enabledProviders: record.enabledProviders,
        flippedProviders: record.flippedProviders,
        rolledOutProviders: record.rolledOutProviders,
        certifiedProviders: record.certifiedProviders,
        releasedProviders: record.releasedProviders,
        enabledCount: record.enabledCount,
        flippedCount: record.flippedCount,
        rolledOutCount: record.rolledOutCount,
        certifiedCount: record.certifiedCount,
        releasedCount: record.releasedCount,
        expansionBudgetFrozen: frozen,
      );
    }
    return Sprint118ExpansionFeatureFlagReport(
      state: Sprint118ExpansionFeatureFlagState.pass,
      verdict: 'EXPANSION_FEATURE_FLAGS_ROLLOUT_VERIFIED_LOCAL',
      releaseState: record.releaseState,
      openItems: allItems,
      declaredProviders: providers,
      enabledProviders: record.enabledProviders,
      flippedProviders: record.flippedProviders,
      rolledOutProviders: record.rolledOutProviders,
      certifiedProviders: record.certifiedProviders,
      releasedProviders: record.releasedProviders,
      enabledCount: record.enabledCount,
      flippedCount: record.flippedCount,
      rolledOutCount: record.rolledOutCount,
      certifiedCount: record.certifiedCount,
      releasedCount: record.releasedCount,
      expansionBudgetFrozen: frozen,
    );
  }
}
