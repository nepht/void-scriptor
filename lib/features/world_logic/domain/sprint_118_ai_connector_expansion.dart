/// Fail-closed AI connector expansion for roadmap step 118.35 -- AI Connector
/// Expansion.
///
/// Objective (external canonical `sprint_118.json`): certify the next AI
/// connector one at a time with models, usage, cost, privacy destination,
/// cancellation, and fallback evidence. The canonical requirement set is
/// exactly seven items: `selected_provider`, `models`, `usage`, `cost`,
/// `privacy_destination`, `cancellation`, and `fallback`.
///
/// The release is delayed. No connector is certified (118.3 froze `CERTIFIED: 0`
/// of `32` registered), the 118.2 charter froze an expansion budget of zero new
/// certified connectors out of 32 registered, the committed 117.45 approval gate
/// records `decision=delay`, `approval_state=PENDING_CHOIRUDIN`,
/// `execution_authorized=false`, and `release_blocked=true`, and the committed
/// 118.11 AI provider health review records `AI_PROVIDER_HEALTH_VERIFIED_LOCAL`
/// with every declared signal `observed=false`. No AI connector has been
/// selected, no model catalog has been verified live, no live usage has been
/// read, no live cost has been read, no live privacy destination has been
/// verified, no live cancellation has been exercised, and no live fallback has
/// been exercised. An AI connector expansion review written against that state
/// therefore has exactly one honest shape: enumerate all 32 registered
/// providers, anchor each of the seven requirements to a committed witness
/// vocabulary, and claim no live certification.
///
/// The gate is fail-closed on these families of rules:
///
/// * The committed 118.2 charter anchor must be a genuine complete charter and
///   its expansion budget must stay frozen (`max_new_certified_connectors` and
///   `currently_certified` both zero). A certification review anchored to an
///   unfrozen budget certifies a connector nobody authorized.
/// * The committed 118.3 certified connector snapshot must be a genuine frozen
///   pass (`CERTIFIED_CONNECTOR_SNAPSHOT_FROZEN_LOCAL`). A certification review
///   anchored to an unfrozen snapshot rests on a release nobody recorded.
/// * The committed 117.45 approval gate must record the delay decision
///   (`decision == delay`), read with the owner's exact grammar, never
///   case-folded or trimmed into agreement. If it is not a delay, the anchor is
///   untrustworthy and the honest answer is `blocked`, not `fail`.
/// * The committed 118.11 AI provider health review must be a genuine pass
///   (`AI_PROVIDER_HEALTH_VERIFIED_LOCAL`). A certification review anchored to
///   an unverified AI provider health surface certifies a connector whose
///   health nobody proved.
/// * The registered provider set must reconcile: the icon-registry provider
///   union, the 116.3 reconciliation count, the frozen snapshot count, and the
///   charter count must agree. A certification review over a drifting registry
///   is not a certification review.
/// * Every registered provider must appear exactly once. A record that drops a
///   provider, invents `telepathy`, or duplicates `openai` is not a
///   certification review.
/// * Every entry must carry all eight canonical fields non-blank, and each of
///   the seven requirements must be grounded by the committed witness vocabulary
///   for that requirement, so a certification value cannot be invented into the
///   list without a witness to ground it.
/// * On the delayed path a certified connector, a selected provider, a
///   live-verified model catalog, a live-verified usage, a live-verified cost, a
///   live-verified privacy destination, a live-verified cancellation, a
///   live-verified fallback, or a released provider describe behavior that never
///   ran. This is refused by name, per entry.
///
/// **A provider is never recorded as a certified AI connector without live
/// provider verification and an authorized release.** When no AI connector was
/// selected and no release is authorized, the only honest certification review
/// records the committed AI-connector reference for each requirement and claims
/// nothing live; any certified, selected, model-verified, usage-verified,
/// cost-verified, privacy-verified, cancellation-verified, fallback-verified, or
/// released claim is refused by name.
///
/// The output vocabulary is *derived from committed witnesses* (the 115.25 AI
/// connection & model settings acceptance set, the 115.24 AI provider registry
/// required-field set, the 116.21 OpenAI connector certification required-field
/// set, the 116.27 AI usage & cost reconciliation acceptance set, the 116.25
/// OpenRouter connector certification required-field set, and the 116.23
/// Anthropic connector certification required-field set), and the source for
/// each requirement is a committed manifest, not copied by hand, so the record
/// and its witnesses cannot drift apart silently.
///
/// AI connector selection, live model catalog verification, live usage reads,
/// live cost reads, live privacy-destination verification, live cancellation
/// exercises, live fallback exercises, credential access, connector
/// certification, provider exposure, and publication remain `DEFERRED-EXTERNAL`;
/// this review freezes local declared state and executes none of it.
library;

import 'dart:convert';
import 'dart:io';

/// The three states an AI connector expansion review can rest in.
/// `blocked` is the honest resting state for "this review cannot yet be
/// trusted", and it is distinct from `fail`, which means the record contradicts
/// its own evidence.
enum Sprint118AiConnectorState { pass, fail, blocked }

/// One frozen AI connector expansion entry: the declared reference for each of
/// the seven canonical requirements of a single registered provider.
///
/// `certified`, `selected`, `modelsVerified`, `usageVerified`, `costVerified`,
/// `privacyDestinationVerified`, `cancellationVerified`, `fallbackVerified`, and
/// `released` are deliberately *not* among the eight required fields; they are
/// the flags the gate refuses when set, so that a declared reference
/// certification can be recorded while never being read as a certified
/// connector, a selected provider, a live-verified model catalog, a
/// live-verified usage, a live-verified cost, a live-verified privacy
/// destination, a live-verified cancellation, a live-verified fallback, or a
/// released provider.
class Sprint118AiConnectorEntry {
  const Sprint118AiConnectorEntry({
    required this.providerId,
    required this.selectedProvider,
    required this.models,
    required this.usage,
    required this.cost,
    required this.privacyDestination,
    required this.cancellation,
    required this.fallback,
    this.certified = false,
    this.selected = false,
    this.modelsVerified = false,
    this.usageVerified = false,
    this.costVerified = false,
    this.privacyDestinationVerified = false,
    this.cancellationVerified = false,
    this.fallbackVerified = false,
    this.released = false,
  });

  /// The registered provider identifier, drawn from the committed icon registry.
  final String providerId;

  /// The selected-provider reference state, drawn from the committed 115.25 AI
  /// connection & model settings acceptance set.
  final String selectedProvider;

  /// The models reference state, drawn from the committed 115.24 AI provider
  /// registry required-field set.
  final String models;

  /// The usage reference state, drawn from the committed 116.21 OpenAI connector
  /// certification required-field set.
  final String usage;

  /// The cost reference state, drawn from the committed 116.27 AI usage & cost
  /// reconciliation acceptance set.
  final String cost;

  /// The privacy-destination reference state, drawn from the committed 116.25
  /// OpenRouter connector certification required-field set.
  final String privacyDestination;

  /// The cancellation reference state, drawn from the committed 116.23 Anthropic
  /// connector certification required-field set.
  final String cancellation;

  /// The fallback reference state, drawn from the committed 115.25 AI connection
  /// & model settings acceptance set.
  final String fallback;

  /// Whether the entry claims the connector was certified. On the delayed path
  /// this must stay `false`.
  final bool certified;

  /// Whether the entry claims the provider was selected. On the delayed path
  /// this must stay `false`.
  final bool selected;

  /// Whether the entry claims a live model catalog was verified. On the delayed
  /// path this must stay `false`.
  final bool modelsVerified;

  /// Whether the entry claims a live usage was verified. On the delayed path
  /// this must stay `false`.
  final bool usageVerified;

  /// Whether the entry claims a live cost was verified. On the delayed path this
  /// must stay `false`.
  final bool costVerified;

  /// Whether the entry claims a live privacy destination was verified. On the
  /// delayed path this must stay `false`.
  final bool privacyDestinationVerified;

  /// Whether the entry claims a live cancellation was verified. On the delayed
  /// path this must stay `false`.
  final bool cancellationVerified;

  /// Whether the entry claims a live fallback was verified. On the delayed path
  /// this must stay `false`.
  final bool fallbackVerified;

  /// Whether the entry claims a released provider. On the delayed path this must
  /// stay `false`.
  final bool released;

  /// The eight canonical fields as a name -> value map, so the gate can test
  /// blankness uniformly.
  Map<String, String> get requiredFields => <String, String>{
    'provider_id': providerId,
    'selected_provider': selectedProvider,
    'models': models,
    'usage': usage,
    'cost': cost,
    'privacy_destination': privacyDestination,
    'cancellation': cancellation,
    'fallback': fallback,
  };

  /// The seven requirements as a requirement -> value map, so the gate can test
  /// grounding per requirement.
  Map<String, String> get outputFields => <String, String>{
    'selected_provider': selectedProvider,
    'models': models,
    'usage': usage,
    'cost': cost,
    'privacy_destination': privacyDestination,
    'cancellation': cancellation,
    'fallback': fallback,
  };
}

/// The frozen AI connector expansion review. `entries` is the declared
/// reference for each registered provider. On the delayed path no entry may
/// claim a live certification.
class Sprint118AiConnectorRecord {
  const Sprint118AiConnectorRecord({
    required this.releaseState,
    required this.entries,
  });

  final String releaseState;
  final List<Sprint118AiConnectorEntry> entries;

  List<String> get providerIds => <String>[
    for (final entry in entries) entry.providerId,
  ];

  /// The providers the record claims were certified. On the delayed path this
  /// must stay empty.
  List<String> get certifiedProviders => <String>[
    for (final entry in entries)
      if (entry.certified) entry.providerId,
  ];

  /// The providers the record claims were selected. On the delayed path this
  /// must stay empty.
  List<String> get selectedProviders => <String>[
    for (final entry in entries)
      if (entry.selected) entry.providerId,
  ];

  int get certifiedCount => entries.where((entry) => entry.certified).length;

  int get selectedCount => entries.where((entry) => entry.selected).length;
}

/// What the committed witnesses actually say. A gate is only as honest as the
/// witnesses it is anchored to.
class Sprint118AiConnectorAnchor {
  const Sprint118AiConnectorAnchor({
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
    required this.aiHealthState,
    required this.aiHealthVerdict,
    required this.registeredProviders,
    required this.selectedProviderVocabulary,
    required this.modelsVocabulary,
    required this.usageVocabulary,
    required this.costVocabulary,
    required this.privacyDestinationVocabulary,
    required this.cancellationVocabulary,
    required this.fallbackVocabulary,
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

  /// The state the committed 118.11 AI provider health review declares.
  final String aiHealthState;

  /// The verdict the committed 118.11 AI provider health review declares.
  final String aiHealthVerdict;

  /// The registered provider ids, unioned from the committed 115.8 icon registry.
  final List<String> registeredProviders;

  /// The selected-provider vocabulary the committed 115.25 AI connection & model
  /// settings declares. It grounds the selected-provider requirement.
  final List<String> selectedProviderVocabulary;

  /// The models vocabulary the committed 115.24 AI provider registry declares.
  /// It grounds the models requirement.
  final List<String> modelsVocabulary;

  /// The usage vocabulary the committed 116.21 OpenAI connector certification
  /// declares. It grounds the usage requirement.
  final List<String> usageVocabulary;

  /// The cost vocabulary the committed 116.27 AI usage & cost reconciliation
  /// declares. It grounds the cost requirement.
  final List<String> costVocabulary;

  /// The privacy-destination vocabulary the committed 116.25 OpenRouter
  /// connector certification declares. It grounds the privacy-destination
  /// requirement.
  final List<String> privacyDestinationVocabulary;

  /// The cancellation vocabulary the committed 116.23 Anthropic connector
  /// certification declares. It grounds the cancellation requirement.
  final List<String> cancellationVocabulary;

  /// The fallback vocabulary the committed 115.25 AI connection & model settings
  /// declares. It grounds the fallback requirement.
  final List<String> fallbackVocabulary;

  /// The committed evidence paths that are present and readable on disk.
  final List<String> readableSources;
}

/// The measured result. `pass` means the review is a faithful freeze; `blocked`
/// means it cannot yet be trusted; `fail` means it contradicts its evidence.
class Sprint118AiConnectorReport {
  const Sprint118AiConnectorReport({
    required this.state,
    required this.verdict,
    required this.releaseState,
    this.violations = const <String>[],
    this.blockers = const <String>[],
    this.openItems = const <String>[],
    this.declaredProviders = const <String>[],
    this.certifiedProviders = const <String>[],
    this.selectedProviders = const <String>[],
    this.certifiedCount = 0,
    this.selectedCount = 0,
    this.expansionBudgetFrozen = false,
  });

  final Sprint118AiConnectorState state;
  final String verdict;
  final String releaseState;

  final List<String> violations;
  final List<String> blockers;
  final List<String> openItems;
  final List<String> declaredProviders;
  final List<String> certifiedProviders;
  final List<String> selectedProviders;
  final int certifiedCount;
  final int selectedCount;
  final bool expansionBudgetFrozen;

  /// Whether the review may be treated as a frozen certification record. Only a
  /// genuine `pass` allows it.
  bool get certificationVerified => state == Sprint118AiConnectorState.pass;

  String get externalGates => Sprint118AiConnectorContract.externalGates;
}

/// The fixed vocabulary and committed witness set for step 118.35.
abstract final class Sprint118AiConnectorContract {
  const Sprint118AiConnectorContract._();

  static const String canonicalStep = '118.35';
  static const String title = 'AI Connector Expansion';

  static const String manifestPath =
      'docs/planning/v1.3/sprint_118_ai_connector_expansion.json';
  static const String ledgerPath =
      'docs/sprints/sprint-118-account-cloud-center-stability.md';

  /// The committed 118.2 charter that declares the frozen expansion budget.
  static const String charterManifestPath =
      'docs/planning/v1.3/sprint_118_stability_expansion_charter.json';

  /// The committed 118.3 certified connector snapshot this review rests on.
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

  /// The committed 118.11 AI provider health review that records
  /// `AI_PROVIDER_HEALTH_VERIFIED_LOCAL` and grounds the AI domain anchor.
  static const String aiProviderHealthManifestPath =
      'docs/planning/v1.3/sprint_118_ai_provider_health.json';

  /// The committed 115.25 AI connection & model settings that grounds the
  /// selected-provider and fallback requirements.
  static const String aiConnectionModelSettingsManifestPath =
      'docs/planning/v1.2/sprint_115_ai_connection_model_settings.json';

  /// The committed 115.24 AI provider registry that grounds the models
  /// requirement.
  static const String aiProviderRegistryManifestPath =
      'docs/planning/v1.2/sprint_115_ai_provider_registry.json';

  /// The committed 116.21 OpenAI connector certification that grounds the usage
  /// requirement.
  static const String openaiConnectorCertificationManifestPath =
      'docs/planning/v1.2/sprint_116_openai_connector_certification.json';

  /// The committed 116.27 AI usage & cost reconciliation that grounds the cost
  /// requirement.
  static const String aiUsageCostReconciliationManifestPath =
      'docs/planning/v1.2/sprint_116_ai_usage_cost_reconciliation.json';

  /// The committed 116.25 OpenRouter connector certification that grounds the
  /// privacy-destination requirement.
  static const String openrouterConnectorCertificationManifestPath =
      'docs/planning/v1.2/sprint_116_openrouter_connector_certification.json';

  /// The committed 116.23 Anthropic connector certification that grounds the
  /// cancellation requirement.
  static const String anthropicConnectorCertificationManifestPath =
      'docs/planning/v1.2/sprint_116_anthropic_connector_certification.json';

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

  /// The state and verdict the committed 118.11 AI provider health review must
  /// carry to be a genuine pass.
  static const String requiredAiHealthState = 'pass';
  static const String requiredAiHealthVerdict =
      'AI_PROVIDER_HEALTH_VERIFIED_LOCAL';

  static const String delayedReleaseState = 'GA_DELAYED';

  /// The number of registered providers the committed witnesses reconcile to.
  static const int expectedProviderCount = 32;

  /// The marker an entry declares when no committed witness names a reference
  /// state for a requirement. A record that uses it records an honest upstream
  /// gap rather than inventing a state.
  static const String noReferenceState = 'no_reference_state';

  /// The canonical field set each entry must carry, so a record cannot drop a
  /// field and still read as complete.
  static const List<String> requiredFields = <String>[
    'provider_id',
    'selected_provider',
    'models',
    'usage',
    'cost',
    'privacy_destination',
    'cancellation',
    'fallback',
  ];

  /// The seven canonical requirements named by the objective, in canonical
  /// order. `provider_id` is the key, not a requirement.
  static const List<String> requiredOutputs = <String>[
    'selected_provider',
    'models',
    'usage',
    'cost',
    'privacy_destination',
    'cancellation',
    'fallback',
  ];

  /// The committed evidence file each canonical requirement is anchored to, in
  /// canonical order.
  static const List<String> canonicalSources = <String>[
    aiConnectionModelSettingsManifestPath,
    aiProviderRegistryManifestPath,
    openaiConnectorCertificationManifestPath,
    aiUsageCostReconciliationManifestPath,
    openrouterConnectorCertificationManifestPath,
    anthropicConnectorCertificationManifestPath,
    aiConnectionModelSettingsManifestPath,
  ];

  /// The committed evidence files every review is anchored to. All must be
  /// readable.
  static const List<String> witnessSources = <String>[
    charterManifestPath,
    snapshotManifestPath,
    approvalGateManifestPath,
    iconRegistryManifestPath,
    registryReconciliationManifestPath,
    aiProviderHealthManifestPath,
    aiConnectionModelSettingsManifestPath,
    aiProviderRegistryManifestPath,
    openaiConnectorCertificationManifestPath,
    aiUsageCostReconciliationManifestPath,
    openrouterConnectorCertificationManifestPath,
    anthropicConnectorCertificationManifestPath,
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

  /// The declared reference state for the selected-provider requirement. No
  /// shipped AI connector is selected on the delayed path, so the honest
  /// reference is the committed 115.25 AI connection & model settings
  /// acceptance (`connect`).
  static const String selectedProviderToken = 'connect';

  /// The declared reference state for the models requirement. No live model
  /// catalog is verified on the delayed path, so the honest reference is the
  /// committed 115.24 AI provider registry required field (`models`).
  static const String modelsToken = 'models';

  /// The declared reference state for the usage requirement. No live usage is
  /// read on the delayed path, so the honest reference is the committed 116.21
  /// OpenAI connector certification required field (`usage_metadata`).
  static const String usageToken = 'usage_metadata';

  /// The declared reference state for the cost requirement. No live cost is read
  /// on the delayed path, so the honest reference is the committed 116.27 AI
  /// usage & cost reconciliation acceptance (`provider_cost`).
  static const String costToken = 'provider_cost';

  /// The declared reference state for the privacy-destination requirement. No
  /// live privacy destination is verified on the delayed path, so the honest
  /// reference is the committed 116.25 OpenRouter connector certification
  /// required field (`privacy_destination`).
  static const String privacyDestinationToken = 'privacy_destination';

  /// The declared reference state for the cancellation requirement. No live
  /// cancellation is exercised on the delayed path, so the honest reference is
  /// the committed 116.23 Anthropic connector certification required field
  /// (`cancellation`).
  static const String cancellationToken = 'cancellation';

  /// The declared reference state for the fallback requirement. No live fallback
  /// is exercised on the delayed path, so the honest reference is the committed
  /// 115.25 AI connection & model settings acceptance (`fallback`).
  static const String fallbackToken = 'fallback';

  /// The committed witness vocabulary that grounds each canonical requirement,
  /// in canonical order.
  static List<List<String>> outputVocabularies(
    Sprint118AiConnectorAnchor anchor,
  ) => <List<String>>[
    anchor.selectedProviderVocabulary,
    anchor.modelsVocabulary,
    anchor.usageVocabulary,
    anchor.costVocabulary,
    anchor.privacyDestinationVocabulary,
    anchor.cancellationVocabulary,
    anchor.fallbackVocabulary,
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
  /// A witness grounds a token when it names the token exactly (`models`,
  /// `cancellation`, `fallback`), or when every underscore-separated part of a
  /// compound token is itself a witness-declared value. The vocabulary is
  /// measured from the committed witnesses, so a reference state cannot be
  /// invented into the list without a witness to ground it.
  static bool grounds(List<String> vocabulary, String token) {
    if (vocabulary.contains(token)) return true;
    final parts = token.split('_');
    if (parts.length < 2) return false;
    return parts.every(vocabulary.contains);
  }

  /// The committed witness vocabulary for a canonical requirement, or the empty
  /// list when the requirement is unknown.
  static List<String> vocabularyFor(
    Sprint118AiConnectorAnchor anchor,
    String output,
  ) {
    final index = requiredOutputs.indexOf(output);
    if (index < 0) return const <String>[];
    return outputVocabularies(anchor)[index];
  }

  /// The committed source for a canonical requirement, or `''` if unknown.
  static String sourceFor(String output) {
    final index = requiredOutputs.indexOf(output);
    return index < 0 ? '' : canonicalSources[index];
  }

  /// The canonical frozen review: every registered provider, each anchored to the
  /// committed witness vocabularies, claiming nothing live.
  static Sprint118AiConnectorRecord get canonicalRecord =>
      Sprint118AiConnectorRecord(
        releaseState: delayedReleaseState,
        entries: <Sprint118AiConnectorEntry>[
          for (final id in canonicalProviders)
            Sprint118AiConnectorEntry(
              providerId: id,
              selectedProvider: selectedProviderToken,
              models: modelsToken,
              usage: usageToken,
              cost: costToken,
              privacyDestination: privacyDestinationToken,
              cancellation: cancellationToken,
              fallback: fallbackToken,
            ),
        ],
      );
}

/// Reads the committed witnesses for step 118.35. Never invents: an unreadable
/// witness yields `null`, which the gate reports as blocked rather than as a
/// pass.
class Sprint118AiConnectorLoader {
  const Sprint118AiConnectorLoader();

  Sprint118AiConnectorAnchor? loadAnchor() {
    final charter = _read(Sprint118AiConnectorContract.charterManifestPath);
    final snapshot = _read(Sprint118AiConnectorContract.snapshotManifestPath);
    final approval = _read(
      Sprint118AiConnectorContract.approvalGateManifestPath,
    );
    final icon = _read(Sprint118AiConnectorContract.iconRegistryManifestPath);
    final reconciliation = _read(
      Sprint118AiConnectorContract.registryReconciliationManifestPath,
    );
    final aiHealth = _read(
      Sprint118AiConnectorContract.aiProviderHealthManifestPath,
    );
    final modelSettings = _read(
      Sprint118AiConnectorContract.aiConnectionModelSettingsManifestPath,
    );
    final aiRegistry = _read(
      Sprint118AiConnectorContract.aiProviderRegistryManifestPath,
    );
    final openai = _read(
      Sprint118AiConnectorContract.openaiConnectorCertificationManifestPath,
    );
    final usageCost = _read(
      Sprint118AiConnectorContract.aiUsageCostReconciliationManifestPath,
    );
    final openrouter = _read(
      Sprint118AiConnectorContract.openrouterConnectorCertificationManifestPath,
    );
    final anthropic = _read(
      Sprint118AiConnectorContract.anthropicConnectorCertificationManifestPath,
    );
    if (charter == null ||
        snapshot == null ||
        approval == null ||
        icon == null ||
        reconciliation == null ||
        aiHealth == null ||
        modelSettings == null ||
        aiRegistry == null ||
        openai == null ||
        usageCost == null ||
        openrouter == null ||
        anthropic == null) {
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

    final sources = Sprint118AiConnectorContract.witnessSources.toSet();

    return Sprint118AiConnectorAnchor(
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
      aiHealthState: _text(aiHealth['state']),
      aiHealthVerdict: _text(aiHealth['verdict']),
      registeredProviders: registered,
      selectedProviderVocabulary: _strings(modelSettings['acceptance']),
      modelsVocabulary: _strings(aiRegistry['required_fields']),
      usageVocabulary: _strings(openai['required_fields']),
      costVocabulary: _strings(usageCost['acceptance']),
      privacyDestinationVocabulary: _strings(openrouter['required_fields']),
      cancellationVocabulary: _strings(anthropic['required_fields']),
      fallbackVocabulary: _strings(modelSettings['acceptance']),
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

/// The fail-closed AI connector expansion gate for step 118.35.
class Sprint118AiConnectorGate {
  const Sprint118AiConnectorGate();

  Sprint118AiConnectorReport evaluate() => evaluateWith(
    const Sprint118AiConnectorLoader().loadAnchor(),
    Sprint118AiConnectorContract.canonicalRecord,
  );

  Sprint118AiConnectorReport evaluateWith(
    Sprint118AiConnectorAnchor? anchor,
    Sprint118AiConnectorRecord record,
  ) {
    if (anchor == null) {
      return Sprint118AiConnectorReport(
        state: Sprint118AiConnectorState.blocked,
        verdict: 'SPRINT_118_AI_CONNECTOR_EXPANSION_EVIDENCE_UNREADABLE',
        releaseState: record.releaseState,
        blockers: const <String>['committed_ai_connector_evidence_unreadable'],
        openItems: const <String>['committed_ai_connector_evidence_unreadable'],
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
            Sprint118AiConnectorContract.requiredCharterState ||
        anchor.charterVerdict !=
            Sprint118AiConnectorContract.requiredCharterVerdict) {
      blockers.add('charter_not_complete:${anchor.charterVerdict}');
    }

    // (2) The 118.3 snapshot anchor must be a genuine frozen pass.
    if (anchor.snapshotState !=
            Sprint118AiConnectorContract.requiredSnapshotState ||
        anchor.snapshotVerdict !=
            Sprint118AiConnectorContract.requiredSnapshotVerdict) {
      blockers.add('snapshot_not_frozen:${anchor.snapshotVerdict}');
    }

    // (3) The 117.45 approval gate must record the delay decision, read with the
    // owner's exact grammar. If it is not a delay, the anchor is untrustworthy.
    if (anchor.approvalDecision !=
        Sprint118AiConnectorContract.requiredApprovalDecision) {
      blockers.add('approval_gate_not_delay:${anchor.approvalDecision}');
    }

    // (4) The 118.11 AI provider health review must be a genuine pass, or the
    // AI anchor is untrustworthy.
    if (anchor.aiHealthState !=
            Sprint118AiConnectorContract.requiredAiHealthState ||
        anchor.aiHealthVerdict !=
            Sprint118AiConnectorContract.requiredAiHealthVerdict) {
      blockers.add(
        'ai_health_not_verified:${anchor.aiHealthState}:'
        '${anchor.aiHealthVerdict}',
      );
    }

    // (5) The registered provider set must reconcile across the icon registry,
    // the 116.3 reconciliation, the frozen snapshot, and the charter.
    if (anchor.registeredProviders.length !=
            Sprint118AiConnectorContract.expectedProviderCount ||
        anchor.registryExpectedCount !=
            Sprint118AiConnectorContract.expectedProviderCount ||
        anchor.snapshotRegistered !=
            Sprint118AiConnectorContract.expectedProviderCount ||
        anchor.charterRegisteredProviders !=
            Sprint118AiConnectorContract.expectedProviderCount) {
      blockers.add(
        'registry_not_reconciled:icon=${anchor.registeredProviders.length}:'
        'reconciliation=${anchor.registryExpectedCount}:'
        'snapshot=${anchor.snapshotRegistered}:'
        'charter=${anchor.charterRegisteredProviders}',
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
        Sprint118AiConnectorContract.delayedReleaseState) {
      violations.add('ai_connector_not_on_delayed_path:${record.releaseState}');
    }

    final delayed =
        record.releaseState == Sprint118AiConnectorContract.delayedReleaseState;

    // (7) On the delayed path an authorized release execution and an unblocked
    // release are behavior that never ran.
    if (delayed && anchor.executionAuthorized) {
      violations.add('ai_connector_execution_authorized_on_delayed_path');
    }
    if (delayed && !anchor.releaseBlocked) {
      violations.add('ai_connector_release_not_blocked_on_delayed_path');
    }

    // (8) The expansion budget must stay frozen: no new certified connector and
    // no already-certified connector while the release is delayed.
    if (!frozen) {
      violations.add(
        'ai_connector_expansion_budget_not_frozen:max_new='
        '${anchor.charterMaxNewCertified}:'
        'currently=${anchor.charterCurrentlyCertified}',
      );
    }

    // (9) Every registered provider must appear exactly once, and each entry must
    // carry all eight canonical fields non-blank with every requirement grounded
    // by its committed witness vocabulary.
    final declared = <String, int>{};
    for (final entry in record.entries) {
      declared[entry.providerId] = (declared[entry.providerId] ?? 0) + 1;
    }
    for (final entry in record.entries) {
      final id = entry.providerId;
      if (!anchor.registeredProviders.contains(id)) {
        violations.add('ai_connector_provider_unknown:$id');
      }
      for (final field in Sprint118AiConnectorContract.requiredFields) {
        final value = entry.requiredFields[field] ?? '';
        if (value.trim().isEmpty) {
          violations.add('entry_blank_$field:$id');
        }
      }
      for (final output in Sprint118AiConnectorContract.requiredOutputs) {
        final token = entry.outputFields[output] ?? '';
        final vocabulary = Sprint118AiConnectorContract.vocabularyFor(
          anchor,
          output,
        );
        final grounded =
            token == Sprint118AiConnectorContract.noReferenceState ||
            Sprint118AiConnectorContract.grounds(vocabulary, token);
        if (token.trim().isEmpty || !grounded) {
          violations.add('reference_state_invalid:$output:$id');
        }
        if (token == Sprint118AiConnectorContract.noReferenceState) {
          openItems.add('upstream_state_vocabulary_gap:$output:$id');
        }
      }
      // A connector is never certified without live provider verification.
      if (entry.certified) {
        violations.add('ai_connector_certified_claimed_on_delayed_path:$id');
      }
      // A provider is never selected without a certified connector.
      if (entry.selected) {
        violations.add('ai_connector_selected_claimed_on_delayed_path:$id');
      }
      // A model catalog is never verified without a live provider.
      if (entry.modelsVerified) {
        violations.add('ai_connector_models_verified_on_delayed_path:$id');
      }
      // A usage is never verified without a live provider read.
      if (entry.usageVerified) {
        violations.add('ai_connector_usage_verified_on_delayed_path:$id');
      }
      // A cost is never verified without a live provider read.
      if (entry.costVerified) {
        violations.add('ai_connector_cost_verified_on_delayed_path:$id');
      }
      // A privacy destination is never verified without a live provider.
      if (entry.privacyDestinationVerified) {
        violations.add(
          'ai_connector_privacy_destination_verified_on_delayed_path:$id',
        );
      }
      // A cancellation is never verified without a live provider.
      if (entry.cancellationVerified) {
        violations.add(
          'ai_connector_cancellation_verified_on_delayed_path:$id',
        );
      }
      // A fallback is never verified without a live provider.
      if (entry.fallbackVerified) {
        violations.add('ai_connector_fallback_verified_on_delayed_path:$id');
      }
      // A provider is never released without an authorized release.
      if (entry.released) {
        violations.add('ai_connector_provider_released_claimed:$id');
      }
    }
    for (final id in declared.keys) {
      if (declared[id]! > 1) {
        violations.add('ai_connector_provider_duplicate:$id');
      }
    }
    for (final id in anchor.registeredProviders) {
      if (!declared.containsKey(id)) {
        violations.add('ai_connector_provider_missing:$id');
      }
    }

    // (10) Every committed evidence source must be readable.
    for (final source in Sprint118AiConnectorContract.witnessSources.toSet()) {
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
      return Sprint118AiConnectorReport(
        state: Sprint118AiConnectorState.blocked,
        verdict: 'SPRINT_118_AI_CONNECTOR_EXPANSION_BLOCKED_UPSTREAM',
        releaseState: record.releaseState,
        violations: violations,
        blockers: blockers,
        openItems: allItems,
        declaredProviders: providers,
        certifiedProviders: record.certifiedProviders,
        selectedProviders: record.selectedProviders,
        certifiedCount: record.certifiedCount,
        selectedCount: record.selectedCount,
        expansionBudgetFrozen: frozen,
      );
    }
    if (violations.isNotEmpty) {
      return Sprint118AiConnectorReport(
        state: Sprint118AiConnectorState.fail,
        verdict: 'SPRINT_118_AI_CONNECTOR_EXPANSION_EVIDENCE_VIOLATION',
        releaseState: record.releaseState,
        violations: violations,
        blockers: blockers,
        openItems: allItems,
        declaredProviders: providers,
        certifiedProviders: record.certifiedProviders,
        selectedProviders: record.selectedProviders,
        certifiedCount: record.certifiedCount,
        selectedCount: record.selectedCount,
        expansionBudgetFrozen: frozen,
      );
    }
    return Sprint118AiConnectorReport(
      state: Sprint118AiConnectorState.pass,
      verdict: 'AI_CONNECTOR_EXPANSION_VERIFIED_LOCAL',
      releaseState: record.releaseState,
      openItems: allItems,
      declaredProviders: providers,
      certifiedProviders: record.certifiedProviders,
      selectedProviders: record.selectedProviders,
      certifiedCount: record.certifiedCount,
      selectedCount: record.selectedCount,
      expansionBudgetFrozen: frozen,
    );
  }
}
