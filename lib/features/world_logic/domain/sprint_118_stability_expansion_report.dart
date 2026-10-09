/// Fail-closed stability & expansion report contract for roadmap step 118.44 --
/// Stability & Expansion Report.
///
/// Objective (external canonical `sprint_118.json`): summarize actual release
/// state, health, incidents, fixes, patch, certified subset, expansion
/// decisions, limitations, and risks. The canonical section set is exactly
/// nine: `release_state`, `health`, `incidents`, `fixes`, `patch`,
/// `certified_subset`, `expansion`, `limitations`, and `risks`.
///
/// The release is delayed. No connector is certified (118.3 froze `CERTIFIED: 0`
/// of `32` registered; the committed 117.41 registry evidence records
/// `UNVERIFIED: 32`, `EXPOSED: 0`, `WITHHELD: 32`), the 118.2 charter froze an
/// expansion budget of zero new certified connectors out of 32 registered, and
/// the committed 117.45 approval gate records `decision=delay`,
/// `approval_state=PENDING_CHOIRUDIN`, `execution_authorized=false`, and
/// `release_blocked=true`. No live health has been observed, no incident has
/// been triaged, no fix has been shipped, no patch has been deployed, no
/// connector has been certified, and no expansion has been authorized. A
/// stability & expansion report written against that state therefore has
/// exactly one honest shape: declare all nine sections, anchor each section's
/// reference state to a committed witness vocabulary, claim nothing live, and
/// expand nothing.
///
/// The gate is fail-closed on these families of rules:
///
/// * The committed 118.2 charter anchor must be a genuine complete charter and
///   its expansion budget must stay frozen (`max_new_certified_connectors` and
///   `currently_certified` both zero). A report anchored to an unfrozen budget
///   reports connectors nobody authorized.
/// * The committed 118.3 certified connector snapshot must be a genuine frozen
///   pass (`CERTIFIED_CONNECTOR_SNAPSHOT_FROZEN_LOCAL`). A report anchored to an
///   unfrozen snapshot rests on a release nobody recorded.
/// * The committed 117.45 approval gate must record the delay decision
///   (`decision == delay`), read with the owner's exact grammar, never
///   case-folded or trimmed into agreement. If it is not a delay, the anchor is
///   untrustworthy and the honest answer is `blocked`, not `fail`.
/// * The registered provider set must reconcile: the icon-registry provider
///   union, the 116.3 reconciliation count, the frozen snapshot count, the
///   charter count, the 117.41 registry evidence count, and the 117.4 snapshot
///   lock count must all agree. A report over a drifting registry is not a
///   report.
/// * The committed 117.41 registry visibility counts must reconcile (`EXPOSED`
///   plus `WITHHELD` equals the registered count) and must record zero exposed
///   providers while the release is delayed. A registry that already exposes a
///   connector contradicts the frozen zero-certified state.
/// * The release state must be `GA_DELAYED` and must agree with the anchor. A
///   report that reads as released rests on a release nobody recorded.
/// * On the delayed path an authorized release execution and an unblocked
///   release describe behavior that never ran. This is refused.
/// * The expansion budget must stay frozen and the frozen snapshot must declare
///   zero certified connectors. A report that certifies a connector contradicts
///   the delayed path.
/// * Every one of the nine canonical sections must appear exactly once. A report
///   that drops a section, invents `telepathy`, or duplicates `health` is not a
///   report.
/// * Every section must carry a non-blank summary and non-empty committed
///   evidence, and its reference state must be grounded by the committed witness
///   vocabulary for that section, so a reference state cannot be invented into
///   the list without a witness to ground it.
/// * On the delayed path a reported section, a published section, a verified
///   section, a complete section, a live section, a certified section, or a
///   released section describe behavior that never ran. This is refused by name,
///   per section.
///
/// **Stability is never reported and expansion is never authorized without live
/// evidence and an authorized release.** When no live health has been observed
/// and no release is authorized, the only honest report states the committed
/// reference for each section and claims nothing live; any reported, published,
/// verified, complete, live, certified, or released claim is refused by name.
///
/// The section vocabulary is *derived from committed witnesses* (the 118.3
/// certified connector snapshot `release_state`, the 118 post-release health
/// baseline `required_fields`, the 118 incident support intake `severity_levels`,
/// the 118 stability fixes `canonical_fix_areas`, the 114 severity patch triage
/// `decisions`, the 116 certification policy `certification_statuses` and
/// `limitations`, the 118 expansion prioritization `required_criteria`, and the
/// 114 technical debt deferred risk register `required_fields`), and the source
/// for each section is a committed manifest, not copied by hand, so the report
/// and its witnesses cannot drift apart silently.
///
/// Live health observation, incident response, patch deployment, connector
/// certification, connector release, and expansion remain `DEFERRED-EXTERNAL`;
/// this report freezes local declared state and executes none of it.
library;

import 'dart:convert';
import 'dart:io';

/// The three states a stability & expansion report can rest in. `blocked` is the
/// honest resting state for "this report cannot yet be trusted", and it is
/// distinct from `fail`, which means the report contradicts its own evidence.
enum Sprint118StabilityExpansionState { pass, fail, blocked }

/// One frozen stability & expansion section: the declared reference state for a
/// single canonical section, the committed evidence that grounds it, and a
/// summary.
///
/// `reported`, `published`, `verified`, `complete`, `live`, `certified`, and
/// `released` are deliberately *not* among the required fields; they are the
/// flags the gate refuses when set, so that a declared reference section can be
/// recorded while never being read as a live report.
class Sprint118StabilityExpansionSection {
  const Sprint118StabilityExpansionSection({
    required this.section,
    required this.referenceState,
    required this.summary,
    required this.evidence,
    this.reported = false,
    this.published = false,
    this.verified = false,
    this.complete = false,
    this.live = false,
    this.certified = false,
    this.released = false,
  });

  /// The canonical section name, drawn from the objective's nine sections.
  final String section;

  /// The declared reference state for the section, grounded by the committed
  /// witness vocabulary for that section.
  final String referenceState;

  /// A human-readable summary of the section's committed state.
  final String summary;

  /// The committed evidence paths that ground the section.
  final List<String> evidence;

  /// Whether the section claims a live report was produced. On the delayed path
  /// this must stay `false`.
  final bool reported;

  /// Whether the section claims a report was published. On the delayed path this
  /// must stay `false`.
  final bool published;

  /// Whether the section claims the report was verified live. On the delayed
  /// path this must stay `false`.
  final bool verified;

  /// Whether the section claims the report is complete. On the delayed path this
  /// must stay `false`.
  final bool complete;

  /// Whether the section claims live observed state. On the delayed path this
  /// must stay `false`.
  final bool live;

  /// Whether the section claims a connector was certified. On the delayed path
  /// this must stay `false`.
  final bool certified;

  /// Whether the section claims a connector was released. On the delayed path
  /// this must stay `false`.
  final bool released;

  /// The canonical section fields as a name -> value map, so the gate can test
  /// blankness uniformly.
  Map<String, String> get requiredFields => <String, String>{
    'section': section,
    'reference_state': referenceState,
    'summary': summary,
  };

  /// The section reference-state field as a section -> value map, so the gate
  /// can test grounding per section.
  Map<String, String> get outputFields => <String, String>{
    'reference_state': referenceState,
  };
}

/// The frozen stability & expansion report. `sections` is the declared reference
/// for each canonical section. On the delayed path no section may claim a live
/// report.
class Sprint118StabilityExpansionRecord {
  const Sprint118StabilityExpansionRecord({
    required this.releaseState,
    required this.sections,
  });

  final String releaseState;
  final List<Sprint118StabilityExpansionSection> sections;

  List<String> get sectionNames => <String>[
    for (final section in sections) section.section,
  ];

  /// The sections the report claims were reported. On the delayed path this must
  /// stay empty.
  List<String> get reportedSections => <String>[
    for (final section in sections)
      if (section.reported) section.section,
  ];

  /// The sections the report claims were published. On the delayed path this
  /// must stay empty.
  List<String> get publishedSections => <String>[
    for (final section in sections)
      if (section.published) section.section,
  ];

  /// The sections the report claims were verified. On the delayed path this must
  /// stay empty.
  List<String> get verifiedSections => <String>[
    for (final section in sections)
      if (section.verified) section.section,
  ];

  /// The sections the report claims are complete. On the delayed path this must
  /// stay empty.
  List<String> get completeSections => <String>[
    for (final section in sections)
      if (section.complete) section.section,
  ];

  /// The sections the report claims are live. On the delayed path this must stay
  /// empty.
  List<String> get liveSections => <String>[
    for (final section in sections)
      if (section.live) section.section,
  ];

  /// The sections the report claims certified a connector. On the delayed path
  /// this must stay empty.
  List<String> get certifiedSections => <String>[
    for (final section in sections)
      if (section.certified) section.section,
  ];

  /// The sections the report claims released a connector. On the delayed path
  /// this must stay empty.
  List<String> get releasedSections => <String>[
    for (final section in sections)
      if (section.released) section.section,
  ];

  int get reportedCount => sections.where((section) => section.reported).length;

  int get publishedCount =>
      sections.where((section) => section.published).length;

  int get verifiedCount => sections.where((section) => section.verified).length;

  int get completeCount => sections.where((section) => section.complete).length;

  int get liveCount => sections.where((section) => section.live).length;

  int get certifiedCount =>
      sections.where((section) => section.certified).length;

  int get releasedCount => sections.where((section) => section.released).length;
}

/// What the committed witnesses actually say. A gate is only as honest as the
/// witnesses it is anchored to.
class Sprint118StabilityExpansionAnchor {
  const Sprint118StabilityExpansionAnchor({
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
    required this.releaseStateVocabulary,
    required this.healthVocabulary,
    required this.incidentsVocabulary,
    required this.fixesVocabulary,
    required this.patchVocabulary,
    required this.certifiedSubsetVocabulary,
    required this.expansionVocabulary,
    required this.limitationsVocabulary,
    required this.risksVocabulary,
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

  /// The release-state vocabulary the committed 118.3 snapshot declares. It
  /// grounds the release_state section.
  final List<String> releaseStateVocabulary;

  /// The health vocabulary the committed 118 post-release health baseline
  /// declares. It grounds the health section.
  final List<String> healthVocabulary;

  /// The incidents vocabulary the committed 118 incident support intake
  /// declares. It grounds the incidents section.
  final List<String> incidentsVocabulary;

  /// The fixes vocabulary the committed 118 stability fixes declare. It grounds
  /// the fixes section.
  final List<String> fixesVocabulary;

  /// The patch vocabulary the committed 114 severity patch triage declares. It
  /// grounds the patch section.
  final List<String> patchVocabulary;

  /// The certified-subset vocabulary the committed 116 certification policy
  /// declares. It grounds the certified_subset section.
  final List<String> certifiedSubsetVocabulary;

  /// The expansion vocabulary the committed 118 expansion prioritization
  /// declares. It grounds the expansion section.
  final List<String> expansionVocabulary;

  /// The limitations vocabulary the committed 116 certification policy declares.
  /// It grounds the limitations section.
  final List<String> limitationsVocabulary;

  /// The risks vocabulary the committed 114 technical debt deferred risk
  /// register declares. It grounds the risks section.
  final List<String> risksVocabulary;

  /// The committed evidence paths that are present and readable on disk.
  final List<String> readableSources;
}

/// The measured result. `pass` means the report is a faithful stability &
/// expansion freeze; `blocked` means it cannot yet be trusted; `fail` means it
/// contradicts its evidence.
class Sprint118StabilityExpansionReport {
  const Sprint118StabilityExpansionReport({
    required this.state,
    required this.verdict,
    required this.releaseState,
    this.violations = const <String>[],
    this.blockers = const <String>[],
    this.openItems = const <String>[],
    this.declaredSections = const <String>[],
    this.reportedSections = const <String>[],
    this.publishedSections = const <String>[],
    this.verifiedSections = const <String>[],
    this.completeSections = const <String>[],
    this.liveSections = const <String>[],
    this.certifiedSections = const <String>[],
    this.releasedSections = const <String>[],
    this.reportedCount = 0,
    this.publishedCount = 0,
    this.verifiedCount = 0,
    this.completeCount = 0,
    this.liveCount = 0,
    this.certifiedCount = 0,
    this.releasedCount = 0,
    this.expansionBudgetFrozen = false,
  });

  final Sprint118StabilityExpansionState state;
  final String verdict;
  final String releaseState;

  final List<String> violations;
  final List<String> blockers;
  final List<String> openItems;
  final List<String> declaredSections;
  final List<String> reportedSections;
  final List<String> publishedSections;
  final List<String> verifiedSections;
  final List<String> completeSections;
  final List<String> liveSections;
  final List<String> certifiedSections;
  final List<String> releasedSections;
  final int reportedCount;
  final int publishedCount;
  final int verifiedCount;
  final int completeCount;
  final int liveCount;
  final int certifiedCount;
  final int releasedCount;
  final bool expansionBudgetFrozen;

  /// Whether the report may be treated as a frozen stability & expansion freeze.
  /// Only a genuine `pass` allows it.
  bool get reportVerified => state == Sprint118StabilityExpansionState.pass;

  String get externalGates => Sprint118StabilityExpansionContract.externalGates;
}

/// The fixed vocabulary and committed witness set for step 118.44.
abstract final class Sprint118StabilityExpansionContract {
  const Sprint118StabilityExpansionContract._();

  static const String canonicalStep = '118.44';
  static const String title = 'Stability & Expansion Report';

  static const String manifestPath =
      'docs/planning/v1.3/sprint_118_stability_expansion_report.json';
  static const String ledgerPath =
      'docs/sprints/sprint-118-account-cloud-center-stability.md';

  /// The committed 118.2 charter that declares the frozen expansion budget.
  static const String charterManifestPath =
      'docs/planning/v1.3/sprint_118_stability_expansion_charter.json';

  /// The committed 118.3 certified connector snapshot this report rests on.
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

  /// The committed 118 post-release health baseline that grounds the health
  /// section.
  static const String healthBaselinePath =
      'docs/planning/v1.3/sprint_118_post_release_health_baseline.json';

  /// The committed 118 incident support intake that grounds the incidents
  /// section.
  static const String incidentIntakePath =
      'docs/planning/v1.3/sprint_118_incident_support_intake.json';

  /// The committed 118 stability fixes that ground the fixes section.
  static const String stabilityFixesPath =
      'docs/planning/v1.3/sprint_118_stability_fixes.json';

  /// The committed 114 severity patch triage that grounds the patch section.
  static const String patchTriagePath =
      'docs/planning/v1.2/sprint_114_severity_patch_triage.json';

  /// The committed 116 certification policy that grounds the certified_subset
  /// and limitations sections.
  static const String certificationPolicyPath =
      'docs/planning/v1.2/sprint_116_certification_policy.json';

  /// The committed 118 expansion prioritization that grounds the expansion
  /// section.
  static const String expansionPrioritizationPath =
      'docs/planning/v1.3/sprint_118_expansion_prioritization.json';

  /// The committed 114 technical debt deferred risk register that grounds the
  /// risks section.
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

  /// The number of registered providers the committed witnesses reconcile to.
  static const int expectedProviderCount = 32;

  /// The number of canonical sections the objective names.
  static const int expectedSectionCount = 9;

  /// The marker a section declares when no committed witness names a reference
  /// state for a section. A report that uses it records an honest upstream gap
  /// rather than inventing a state.
  static const String noReferenceState = 'no_reference_state';

  /// The canonical section set each report must carry, so a report cannot drop a
  /// section and still read as complete.
  static const List<String> requiredSections = <String>[
    'release_state',
    'health',
    'incidents',
    'fixes',
    'patch',
    'certified_subset',
    'expansion',
    'limitations',
    'risks',
  ];

  /// The nine canonical sections named by the objective, in canonical order.
  static const List<String> requiredOutputs = requiredSections;

  /// The per-section fields every declared section must carry a non-blank value
  /// for, so a section cannot be recorded with a blank name, state, or summary.
  static const List<String> requiredFieldsForSection = <String>[
    'section',
    'reference_state',
    'summary',
  ];

  /// The committed evidence file each canonical section is anchored to, in
  /// canonical order.
  static const List<String> canonicalSources = <String>[
    snapshotManifestPath,
    healthBaselinePath,
    incidentIntakePath,
    stabilityFixesPath,
    patchTriagePath,
    certificationPolicyPath,
    expansionPrioritizationPath,
    certificationPolicyPath,
    technicalDebtPath,
  ];

  /// The committed evidence files every report is anchored to. All must be
  /// readable.
  static const List<String> witnessSources = <String>[
    charterManifestPath,
    snapshotManifestPath,
    approvalGateManifestPath,
    iconRegistryManifestPath,
    registryReconciliationManifestPath,
    snapshotLockManifestPath,
    registryEvidencePath,
    healthBaselinePath,
    incidentIntakePath,
    stabilityFixesPath,
    patchTriagePath,
    certificationPolicyPath,
    expansionPrioritizationPath,
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

  /// The declared reference state for the release_state section. The release is
  /// delayed, so the honest reference is the committed 118.3 snapshot
  /// `release_state` (`GA_DELAYED`).
  static const String releaseStateToken = 'GA_DELAYED';

  /// The declared reference state for the health section. No live health has
  /// been observed on the delayed path, so the honest reference is the committed
  /// 118 post-release health baseline first required field (`baseline`).
  static const String healthToken = 'baseline';

  /// The declared reference state for the incidents section. No incident has
  /// been triaged live on the delayed path, so the honest reference is the
  /// committed 118 incident support intake first severity level (`P0`).
  static const String incidentsToken = 'P0';

  /// The declared reference state for the fixes section. No fix has been shipped
  /// live on the delayed path, so the honest reference is the committed 118
  /// stability fixes first canonical fix area (`auth`).
  static const String fixesToken = 'auth';

  /// The declared reference state for the patch section. No patch has been
  /// deployed live on the delayed path, so the honest reference is the committed
  /// 114 severity patch triage first decision (`DEFER`).
  static const String patchToken = 'DEFER';

  /// The declared reference state for the certified_subset section. No connector
  /// has been certified on the delayed path, so the honest reference is the
  /// committed 116 certification policy first certification status
  /// (`UNVERIFIED`).
  static const String certifiedSubsetToken = 'UNVERIFIED';

  /// The declared reference state for the expansion section. No expansion has
  /// been authorized on the delayed path, so the honest reference is the
  /// committed 118 expansion prioritization first required criterion (`risk`).
  static const String expansionToken = 'risk';

  /// The declared reference state for the limitations section. No limitation has
  /// been re-reviewed live on the delayed path, so the honest reference is the
  /// committed 116 certification policy first limitation
  /// (`live_provider_certification`).
  static const String limitationsToken = 'live_provider_certification';

  /// The declared reference state for the risks section. No risk has been
  /// re-assessed live on the delayed path, so the honest reference is the
  /// committed 114 technical debt deferred risk register first required field
  /// (`impact`).
  static const String risksToken = 'impact';

  /// The declared reference state for each canonical section, in canonical
  /// order.
  static const List<String> sectionTokens = <String>[
    releaseStateToken,
    healthToken,
    incidentsToken,
    fixesToken,
    patchToken,
    certifiedSubsetToken,
    expansionToken,
    limitationsToken,
    risksToken,
  ];

  /// The committed witness vocabulary that grounds each canonical section, in
  /// canonical order.
  static List<List<String>> outputVocabularies(
    Sprint118StabilityExpansionAnchor anchor,
  ) => <List<String>>[
    anchor.releaseStateVocabulary,
    anchor.healthVocabulary,
    anchor.incidentsVocabulary,
    anchor.fixesVocabulary,
    anchor.patchVocabulary,
    anchor.certifiedSubsetVocabulary,
    anchor.expansionVocabulary,
    anchor.limitationsVocabulary,
    anchor.risksVocabulary,
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
  /// `baseline`, `live_provider_certification`), or when every underscore-
  /// separated part of a compound token is itself a witness-declared value. The
  /// vocabulary is measured from the committed witnesses, so a reference state
  /// cannot be invented into the list without a witness to ground it.
  static bool grounds(List<String> vocabulary, String token) {
    if (vocabulary.contains(token)) return true;
    final parts = token.split('_');
    if (parts.length < 2) return false;
    return parts.every(vocabulary.contains);
  }

  /// The committed witness vocabulary for a canonical section, or the empty list
  /// when the section is unknown.
  static List<String> vocabularyFor(
    Sprint118StabilityExpansionAnchor anchor,
    String output,
  ) {
    final index = requiredOutputs.indexOf(output);
    if (index < 0) return const <String>[];
    return outputVocabularies(anchor)[index];
  }

  /// The committed source for a canonical section, or `''` if unknown.
  static String sourceFor(String output) {
    final index = requiredOutputs.indexOf(output);
    return index < 0 ? '' : canonicalSources[index];
  }

  /// The canonical frozen report: every canonical section, each anchored to the
  /// committed witness vocabularies, claiming nothing live.
  static Sprint118StabilityExpansionRecord get canonicalRecord =>
      Sprint118StabilityExpansionRecord(
        releaseState: delayedReleaseState,
        sections: <Sprint118StabilityExpansionSection>[
          for (var index = 0; index < requiredSections.length; index += 1)
            Sprint118StabilityExpansionSection(
              section: requiredSections[index],
              referenceState: sectionTokens[index],
              summary:
                  'no live ${requiredSections[index]} verified on the delayed '
                  'path; committed reference only',
              evidence: <String>[canonicalSources[index]],
            ),
        ],
      );
}

/// Reads the committed witnesses for step 118.44. Never invents: an unreadable
/// witness yields `null`, which the gate reports as blocked rather than as a
/// pass.
class Sprint118StabilityExpansionLoader {
  const Sprint118StabilityExpansionLoader();

  Sprint118StabilityExpansionAnchor? loadAnchor() {
    final charter = _read(
      Sprint118StabilityExpansionContract.charterManifestPath,
    );
    final snapshot = _read(
      Sprint118StabilityExpansionContract.snapshotManifestPath,
    );
    final approval = _read(
      Sprint118StabilityExpansionContract.approvalGateManifestPath,
    );
    final icon = _read(
      Sprint118StabilityExpansionContract.iconRegistryManifestPath,
    );
    final reconciliation = _read(
      Sprint118StabilityExpansionContract.registryReconciliationManifestPath,
    );
    final lock = _read(
      Sprint118StabilityExpansionContract.snapshotLockManifestPath,
    );
    final registry = _read(
      Sprint118StabilityExpansionContract.registryEvidencePath,
    );
    final health = _read(
      Sprint118StabilityExpansionContract.healthBaselinePath,
    );
    final incidents = _read(
      Sprint118StabilityExpansionContract.incidentIntakePath,
    );
    final fixes = _read(Sprint118StabilityExpansionContract.stabilityFixesPath);
    final patch = _read(Sprint118StabilityExpansionContract.patchTriagePath);
    final certification = _read(
      Sprint118StabilityExpansionContract.certificationPolicyPath,
    );
    final expansion = _read(
      Sprint118StabilityExpansionContract.expansionPrioritizationPath,
    );
    final technicalDebt = _read(
      Sprint118StabilityExpansionContract.technicalDebtPath,
    );
    if (charter == null ||
        snapshot == null ||
        approval == null ||
        icon == null ||
        reconciliation == null ||
        lock == null ||
        registry == null ||
        health == null ||
        incidents == null ||
        fixes == null ||
        patch == null ||
        certification == null ||
        expansion == null ||
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

    final sources = Sprint118StabilityExpansionContract.witnessSources.toSet();

    return Sprint118StabilityExpansionAnchor(
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
      releaseStateVocabulary: _strings(snapshot['release_state']),
      healthVocabulary: _strings(health['required_fields']),
      incidentsVocabulary: _strings(incidents['severity_levels']),
      fixesVocabulary: _strings(fixes['canonical_fix_areas']),
      patchVocabulary: _strings(patch['decisions']),
      certifiedSubsetVocabulary: _strings(
        certification['certification_statuses'],
      ),
      expansionVocabulary: _strings(expansion['required_criteria']),
      limitationsVocabulary: _strings(certification['limitations']),
      risksVocabulary: _strings(technicalDebt['required_fields']),
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

/// The fail-closed stability & expansion gate for step 118.44.
class Sprint118StabilityExpansionGate {
  const Sprint118StabilityExpansionGate();

  Sprint118StabilityExpansionReport evaluate() => evaluateWith(
    const Sprint118StabilityExpansionLoader().loadAnchor(),
    Sprint118StabilityExpansionContract.canonicalRecord,
  );

  Sprint118StabilityExpansionReport evaluateWith(
    Sprint118StabilityExpansionAnchor? anchor,
    Sprint118StabilityExpansionRecord record,
  ) {
    if (anchor == null) {
      return Sprint118StabilityExpansionReport(
        state: Sprint118StabilityExpansionState.blocked,
        verdict: 'SPRINT_118_STABILITY_EXPANSION_EVIDENCE_UNREADABLE',
        releaseState: record.releaseState,
        blockers: const <String>[
          'committed_stability_expansion_evidence_unreadable',
        ],
        openItems: const <String>[
          'committed_stability_expansion_evidence_unreadable',
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
            Sprint118StabilityExpansionContract.requiredCharterState ||
        anchor.charterVerdict !=
            Sprint118StabilityExpansionContract.requiredCharterVerdict) {
      blockers.add('charter_not_complete:${anchor.charterVerdict}');
    }

    // (2) The 118.3 snapshot anchor must be a genuine frozen pass.
    if (anchor.snapshotState !=
            Sprint118StabilityExpansionContract.requiredSnapshotState ||
        anchor.snapshotVerdict !=
            Sprint118StabilityExpansionContract.requiredSnapshotVerdict) {
      blockers.add('snapshot_not_frozen:${anchor.snapshotVerdict}');
    }

    // (3) The 117.45 approval gate must record the delay decision, read with the
    // owner's exact grammar. If it is not a delay, the anchor is untrustworthy.
    if (anchor.approvalDecision !=
        Sprint118StabilityExpansionContract.requiredApprovalDecision) {
      blockers.add('approval_gate_not_delay:${anchor.approvalDecision}');
    }

    // (4) The registered provider set must reconcile across the icon registry,
    // the 116.3 reconciliation, the frozen snapshot, the charter, the 117.41
    // registry evidence, and the 117.4 snapshot lock.
    if (anchor.registeredProviders.length !=
            Sprint118StabilityExpansionContract.expectedProviderCount ||
        anchor.registryExpectedCount !=
            Sprint118StabilityExpansionContract.expectedProviderCount ||
        anchor.snapshotRegistered !=
            Sprint118StabilityExpansionContract.expectedProviderCount ||
        anchor.charterRegisteredProviders !=
            Sprint118StabilityExpansionContract.expectedProviderCount ||
        anchor.registryEvidenceProviderCount !=
            Sprint118StabilityExpansionContract.expectedProviderCount ||
        anchor.snapshotLockLockedCount !=
            Sprint118StabilityExpansionContract.expectedProviderCount) {
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
        Sprint118StabilityExpansionContract.expectedProviderCount) {
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

    // (6) The release state must agree with the anchor and must be delayed.
    if (record.releaseState != anchor.releaseState) {
      violations.add(
        'release_state_mismatch:anchor=${anchor.releaseState}:'
        'record=${record.releaseState}',
      );
    }
    if (record.releaseState !=
        Sprint118StabilityExpansionContract.delayedReleaseState) {
      violations.add(
        'stability_expansion_not_on_delayed_path:${record.releaseState}',
      );
    }

    final delayed =
        record.releaseState ==
        Sprint118StabilityExpansionContract.delayedReleaseState;

    // (7) On the delayed path an authorized release execution and an unblocked
    // release are behavior that never ran.
    if (delayed && anchor.executionAuthorized) {
      violations.add(
        'stability_expansion_execution_authorized_on_delayed_path',
      );
    }
    if (delayed && !anchor.releaseBlocked) {
      violations.add('stability_expansion_release_not_blocked_on_delayed_path');
    }

    // (8) The expansion budget must stay frozen: no new certified connector and
    // no already-certified connector while the release is delayed.
    if (!frozen) {
      violations.add(
        'stability_expansion_expansion_budget_not_frozen:max_new='
        '${anchor.charterMaxNewCertified}:'
        'currently=${anchor.charterCurrentlyCertified}',
      );
    }
    // The frozen 118.3 snapshot must declare zero certified connectors. A
    // snapshot that already certifies a connector contradicts the delayed path.
    if (anchor.snapshotCertified != 0) {
      violations.add(
        'stability_expansion_snapshot_certified_nonzero:'
        '${anchor.snapshotCertified}',
      );
    }

    // (9) Every canonical section must appear exactly once, and each section
    // must carry a non-blank summary, non-empty committed evidence, and a
    // reference state grounded by its committed witness vocabulary.
    final declared = <String, int>{};
    for (final section in record.sections) {
      declared[section.section] = (declared[section.section] ?? 0) + 1;
    }
    for (final section in record.sections) {
      final name = section.section;
      if (!Sprint118StabilityExpansionContract.requiredSections.contains(
        name,
      )) {
        violations.add('stability_expansion_section_unknown:$name');
      }
      for (final field
          in Sprint118StabilityExpansionContract.requiredFieldsForSection) {
        final value = section.requiredFields[field] ?? '';
        if (value.trim().isEmpty) {
          violations.add('entry_blank_$field:$name');
        }
      }
      if (section.evidence.isEmpty ||
          section.evidence.any((item) => item.trim().isEmpty)) {
        violations.add('stability_expansion_section_evidence_missing:$name');
      } else {
        for (final item in section.evidence) {
          if (!anchor.readableSources.contains(item)) {
            violations.add(
              'stability_expansion_section_evidence_unreadable:$name:$item',
            );
          }
        }
      }
      final token = section.outputFields['reference_state'] ?? '';
      final vocabulary = Sprint118StabilityExpansionContract.vocabularyFor(
        anchor,
        name,
      );
      final grounded =
          token == Sprint118StabilityExpansionContract.noReferenceState ||
          Sprint118StabilityExpansionContract.grounds(vocabulary, token);
      if (token.trim().isEmpty || !grounded) {
        violations.add('reference_state_invalid:$name');
      }
      if (token == Sprint118StabilityExpansionContract.noReferenceState) {
        openItems.add('upstream_state_vocabulary_gap:$name');
      }
      // Stability is never reported without live evidence.
      if (section.reported) {
        violations.add(
          'stability_expansion_reported_claimed_on_delayed_path:$name',
        );
      }
      // A report is never published without an authorized release.
      if (section.published) {
        violations.add(
          'stability_expansion_published_claimed_on_delayed_path:$name',
        );
      }
      // A report is never verified live without live evidence.
      if (section.verified) {
        violations.add(
          'stability_expansion_verified_claimed_on_delayed_path:$name',
        );
      }
      // A report is never complete without live verification.
      if (section.complete) {
        violations.add(
          'stability_expansion_complete_claimed_on_delayed_path:$name',
        );
      }
      // No section observes live state on the delayed path.
      if (section.live) {
        violations.add(
          'stability_expansion_live_claimed_on_delayed_path:$name',
        );
      }
      // A connector is never certified without live provider verification.
      if (section.certified) {
        violations.add(
          'stability_expansion_certified_claimed_on_delayed_path:$name',
        );
      }
      // A connector is never released without an authorized release.
      if (section.released) {
        violations.add('stability_expansion_released_claimed:$name');
      }
    }
    for (final name in declared.keys) {
      if (declared[name]! > 1) {
        violations.add('stability_expansion_section_duplicate:$name');
      }
    }
    for (final name in Sprint118StabilityExpansionContract.requiredSections) {
      if (!declared.containsKey(name)) {
        violations.add('stability_expansion_section_missing:$name');
      }
    }

    // (10) Every committed evidence source must be readable.
    for (final source
        in Sprint118StabilityExpansionContract.witnessSources.toSet()) {
      if (!anchor.readableSources.contains(source)) {
        violations.add('required_source_unreadable:$source');
      }
    }

    final allItems = <String>[...violations, ...blockers, ...openItems];
    final names = record.sectionNames;

    // An untrustworthy anchor short-circuits: if a committed witness is not a
    // genuine pass, the section-level findings cannot be trusted either, so the
    // honest answer is `blocked`, not `fail`.
    if (blockers.isNotEmpty) {
      return Sprint118StabilityExpansionReport(
        state: Sprint118StabilityExpansionState.blocked,
        verdict: 'SPRINT_118_STABILITY_EXPANSION_BLOCKED_UPSTREAM',
        releaseState: record.releaseState,
        violations: violations,
        blockers: blockers,
        openItems: allItems,
        declaredSections: names,
        reportedSections: record.reportedSections,
        publishedSections: record.publishedSections,
        verifiedSections: record.verifiedSections,
        completeSections: record.completeSections,
        liveSections: record.liveSections,
        certifiedSections: record.certifiedSections,
        releasedSections: record.releasedSections,
        reportedCount: record.reportedCount,
        publishedCount: record.publishedCount,
        verifiedCount: record.verifiedCount,
        completeCount: record.completeCount,
        liveCount: record.liveCount,
        certifiedCount: record.certifiedCount,
        releasedCount: record.releasedCount,
        expansionBudgetFrozen: frozen,
      );
    }
    if (violations.isNotEmpty) {
      return Sprint118StabilityExpansionReport(
        state: Sprint118StabilityExpansionState.fail,
        verdict: 'SPRINT_118_STABILITY_EXPANSION_EVIDENCE_VIOLATION',
        releaseState: record.releaseState,
        violations: violations,
        blockers: blockers,
        openItems: allItems,
        declaredSections: names,
        reportedSections: record.reportedSections,
        publishedSections: record.publishedSections,
        verifiedSections: record.verifiedSections,
        completeSections: record.completeSections,
        liveSections: record.liveSections,
        certifiedSections: record.certifiedSections,
        releasedSections: record.releasedSections,
        reportedCount: record.reportedCount,
        publishedCount: record.publishedCount,
        verifiedCount: record.verifiedCount,
        completeCount: record.completeCount,
        liveCount: record.liveCount,
        certifiedCount: record.certifiedCount,
        releasedCount: record.releasedCount,
        expansionBudgetFrozen: frozen,
      );
    }
    return Sprint118StabilityExpansionReport(
      state: Sprint118StabilityExpansionState.pass,
      verdict: 'STABILITY_EXPANSION_REPORT_VERIFIED_LOCAL',
      releaseState: record.releaseState,
      openItems: allItems,
      declaredSections: names,
      reportedSections: record.reportedSections,
      publishedSections: record.publishedSections,
      verifiedSections: record.verifiedSections,
      completeSections: record.completeSections,
      liveSections: record.liveSections,
      certifiedSections: record.certifiedSections,
      releasedSections: record.releasedSections,
      reportedCount: record.reportedCount,
      publishedCount: record.publishedCount,
      verifiedCount: record.verifiedCount,
      completeCount: record.completeCount,
      liveCount: record.liveCount,
      certifiedCount: record.certifiedCount,
      releasedCount: record.releasedCount,
      expansionBudgetFrozen: frozen,
    );
  }
}
