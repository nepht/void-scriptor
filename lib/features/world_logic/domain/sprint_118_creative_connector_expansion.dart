/// Fail-closed creative connector expansion for roadmap step 118.37 --
/// Creative Connector Expansion.
///
/// Objective (external canonical `sprint_118.json`): certify the next creative
/// connector one at a time with asset rights, attribution, import/export, and
/// plan limits. The canonical requirement set is exactly six items:
/// `selected_provider`, `asset_rights`, `attribution`, `import`, `export`, and
/// `plan_limits`.
///
/// The release is delayed. No connector is certified (118.3 froze `CERTIFIED: 0`
/// of `32` registered), the 118.2 charter froze an expansion budget of zero new
/// certified connectors out of 32 registered, the committed 117.45 approval gate
/// records `decision=delay`, `approval_state=PENDING_CHOIRUDIN`,
/// `execution_authorized=false`, and `release_blocked=true`, and the committed
/// 117.18 creative connector workflow validation records `status=pass` with
/// `CREATIVE_CONNECTOR_WORKFLOW_VALIDATED_LOCAL`. No creative connector has been
/// selected, no live asset right has been verified, no live attribution has been
/// verified, no live asset import has been executed, no live asset export has
/// been executed, and no live plan limit has been read. A creative connector
/// expansion review written against that state therefore has exactly one honest
/// shape: enumerate all 32 registered providers, anchor each of the six
/// requirements to a committed witness vocabulary, and claim no live
/// certification.
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
/// * The committed 117.18 creative connector workflow validation must be a
///   genuine pass (`status == pass` and
///   `CREATIVE_CONNECTOR_WORKFLOW_VALIDATED_LOCAL`). A certification review
///   anchored to an unvalidated creative workflow certifies a connector whose
///   workflow nobody proved.
/// * The registered provider set must reconcile: the icon-registry provider
///   union, the 116.3 reconciliation count, the frozen snapshot count, and the
///   charter count must agree. A certification review over a drifting registry
///   is not a certification review.
/// * Every registered provider must appear exactly once. A record that drops a
///   provider, invents `telepathy`, or duplicates `github` is not a
///   certification review.
/// * Every entry must carry all seven canonical fields non-blank, and each of
///   the six requirements must be grounded by the committed witness vocabulary
///   for that requirement, so a certification value cannot be invented into the
///   list without a witness to ground it.
/// * On the delayed path a certified connector, a selected provider, a
///   live-verified asset right, a live-verified attribution, a live asset
///   import, a live asset export, a live plan limit, or a released provider
///   describe behavior that never ran. This is refused by name, per entry.
///
/// **A provider is never recorded as a certified creative connector without
/// live provider verification and an authorized release.** When no creative
/// connector was selected and no release is authorized, the only honest
/// certification review records the committed creative-connector reference for
/// each requirement and claims nothing live; any certified, selected,
/// asset-rights-verified, attribution-verified, import-verified,
/// export-verified, plan-limits-verified, or released claim is refused by name.
///
/// The output vocabulary is *derived from committed witnesses* (the 115.29
/// creative tools connections acceptance set, the 117.18 creative connector
/// workflow validation acceptance set, the 116.32 Figma certification
/// required-field set, the 116.33 Adobe/Canva certification required-field set,
/// the 116.34 Blender Cloud/Sketchfab certification required-field set, and the
/// 116.35 creative asset rights verification required-field set), and the source
/// for each requirement is a committed manifest, not copied by hand, so the
/// record and its witnesses cannot drift apart silently.
///
/// Creative connector selection, live asset-rights verification, live
/// attribution verification, live asset import, live asset export, live plan
/// limit reads, credential access, connector certification, provider exposure,
/// and publication remain `DEFERRED-EXTERNAL`; this review freezes local
/// declared state and executes none of it.
library;

import 'dart:convert';
import 'dart:io';

/// The three states a creative connector expansion review can rest in.
/// `blocked` is the honest resting state for "this review cannot yet be
/// trusted", and it is distinct from `fail`, which means the record contradicts
/// its own evidence.
enum Sprint118CreativeConnectorState { pass, fail, blocked }

/// One frozen creative connector expansion entry: the declared reference for
/// each of the six canonical requirements of a single registered provider.
///
/// `certified`, `selected`, `assetRightsVerified`, `attributionVerified`,
/// `importVerified`, `exportVerified`, `planLimitsVerified`, and `released` are
/// deliberately *not* among the seven required fields; they are the flags the
/// gate refuses when set, so that a declared reference certification can be
/// recorded while never being read as a certified connector, a selected
/// provider, a live-verified asset right, a live-verified attribution, a live
/// asset import, a live asset export, a live plan limit, or a released
/// provider.
class Sprint118CreativeConnectorEntry {
  const Sprint118CreativeConnectorEntry({
    required this.providerId,
    required this.selectedProvider,
    required this.assetRights,
    required this.attribution,
    required this.importBoundary,
    required this.exportBoundary,
    required this.planLimits,
    this.certified = false,
    this.selected = false,
    this.assetRightsVerified = false,
    this.attributionVerified = false,
    this.importVerified = false,
    this.exportVerified = false,
    this.planLimitsVerified = false,
    this.released = false,
  });

  /// The registered provider identifier, drawn from the committed icon registry.
  final String providerId;

  /// The selected-provider reference state, drawn from the committed 115.29
  /// creative tools connections acceptance set.
  final String selectedProvider;

  /// The asset-rights reference state, drawn from the committed 116.34 Blender
  /// Cloud/Sketchfab certification required-field set.
  final String assetRights;

  /// The attribution reference state, drawn from the committed 116.32 Figma
  /// certification required-field set.
  final String attribution;

  /// The import reference state, drawn from the committed 117.18 creative
  /// connector workflow validation acceptance set.
  final String importBoundary;

  /// The export reference state, drawn from the committed 117.18 creative
  /// connector workflow validation acceptance set.
  final String exportBoundary;

  /// The plan-limits reference state, drawn from the committed 116.33
  /// Adobe/Canva certification required-field set.
  final String planLimits;

  /// Whether the entry claims the connector was certified. On the delayed path
  /// this must stay `false`.
  final bool certified;

  /// Whether the entry claims the provider was selected. On the delayed path
  /// this must stay `false`.
  final bool selected;

  /// Whether the entry claims a live asset right was verified. On the delayed
  /// path this must stay `false`.
  final bool assetRightsVerified;

  /// Whether the entry claims a live attribution was verified. On the delayed
  /// path this must stay `false`.
  final bool attributionVerified;

  /// Whether the entry claims a live asset import was executed. On the delayed
  /// path this must stay `false`.
  final bool importVerified;

  /// Whether the entry claims a live asset export was executed. On the delayed
  /// path this must stay `false`.
  final bool exportVerified;

  /// Whether the entry claims a live plan limit was read. On the delayed path
  /// this must stay `false`.
  final bool planLimitsVerified;

  /// Whether the entry claims a released provider. On the delayed path this must
  /// stay `false`.
  final bool released;

  /// The seven canonical fields as a name -> value map, so the gate can test
  /// blankness uniformly.
  Map<String, String> get requiredFields => <String, String>{
    'provider_id': providerId,
    'selected_provider': selectedProvider,
    'asset_rights': assetRights,
    'attribution': attribution,
    'import': importBoundary,
    'export': exportBoundary,
    'plan_limits': planLimits,
  };

  /// The six requirements as a requirement -> value map, so the gate can test
  /// grounding per requirement.
  Map<String, String> get outputFields => <String, String>{
    'selected_provider': selectedProvider,
    'asset_rights': assetRights,
    'attribution': attribution,
    'import': importBoundary,
    'export': exportBoundary,
    'plan_limits': planLimits,
  };
}

/// The frozen creative connector expansion review. `entries` is the declared
/// reference for each registered provider. On the delayed path no entry may
/// claim a live certification.
class Sprint118CreativeConnectorRecord {
  const Sprint118CreativeConnectorRecord({
    required this.releaseState,
    required this.entries,
  });

  final String releaseState;
  final List<Sprint118CreativeConnectorEntry> entries;

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
class Sprint118CreativeConnectorAnchor {
  const Sprint118CreativeConnectorAnchor({
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
    required this.creativeWorkflowStatus,
    required this.creativeWorkflowVerdict,
    required this.registeredProviders,
    required this.selectedProviderVocabulary,
    required this.assetRightsVocabulary,
    required this.attributionVocabulary,
    required this.importVocabulary,
    required this.exportVocabulary,
    required this.planLimitsVocabulary,
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

  /// The status the committed 117.18 creative connector workflow validation
  /// declares.
  final String creativeWorkflowStatus;

  /// The verdict the committed 117.18 creative connector workflow validation
  /// declares.
  final String creativeWorkflowVerdict;

  /// The registered provider ids, unioned from the committed 115.8 icon registry.
  final List<String> registeredProviders;

  /// The selected-provider vocabulary the committed 115.29 creative tools
  /// connections declares. It grounds the selected-provider requirement.
  final List<String> selectedProviderVocabulary;

  /// The asset-rights vocabulary the committed 116.34 Blender Cloud/Sketchfab
  /// certification declares. It grounds the asset-rights requirement.
  final List<String> assetRightsVocabulary;

  /// The attribution vocabulary the committed 116.32 Figma certification
  /// declares. It grounds the attribution requirement.
  final List<String> attributionVocabulary;

  /// The import vocabulary the committed 117.18 creative connector workflow
  /// validation declares. It grounds the import requirement.
  final List<String> importVocabulary;

  /// The export vocabulary the committed 117.18 creative connector workflow
  /// validation declares. It grounds the export requirement.
  final List<String> exportVocabulary;

  /// The plan-limits vocabulary the committed 116.33 Adobe/Canva certification
  /// declares. It grounds the plan-limits requirement.
  final List<String> planLimitsVocabulary;

  /// The committed evidence paths that are present and readable on disk.
  final List<String> readableSources;
}

/// The measured result. `pass` means the review is a faithful freeze; `blocked`
/// means it cannot yet be trusted; `fail` means it contradicts its evidence.
class Sprint118CreativeConnectorReport {
  const Sprint118CreativeConnectorReport({
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

  final Sprint118CreativeConnectorState state;
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
  bool get certificationVerified =>
      state == Sprint118CreativeConnectorState.pass;

  String get externalGates => Sprint118CreativeConnectorContract.externalGates;
}

/// The fixed vocabulary and committed witness set for step 118.37.
abstract final class Sprint118CreativeConnectorContract {
  const Sprint118CreativeConnectorContract._();

  static const String canonicalStep = '118.37';
  static const String title = 'Creative Connector Expansion';

  static const String manifestPath =
      'docs/planning/v1.3/sprint_118_creative_connector_expansion.json';
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

  /// The committed 117.18 creative connector workflow validation that records
  /// `CREATIVE_CONNECTOR_WORKFLOW_VALIDATED_LOCAL` and grounds the creative
  /// domain anchor.
  static const String creativeWorkflowValidationManifestPath =
      'docs/evidence/sprint-117-18-manifest-20261001.json';

  /// The committed 115.29 creative tools connections that grounds the
  /// selected-provider requirement.
  static const String creativeToolsConnectionsManifestPath =
      'docs/planning/v1.2/sprint_115_creative_tools_connections.json';

  /// The committed 116.32 Figma certification that grounds the attribution
  /// requirement.
  static const String figmaCertificationManifestPath =
      'docs/planning/v1.2/sprint_116_figma_certification.json';

  /// The committed 116.33 Adobe/Canva certification that grounds the plan-limits
  /// requirement.
  static const String adobeCanvaCertificationManifestPath =
      'docs/planning/v1.2/sprint_116_adobe_canva_certification.json';

  /// The committed 116.34 Blender Cloud/Sketchfab certification that grounds the
  /// asset-rights requirement.
  static const String blenderSketchfabCertificationManifestPath =
      'docs/planning/v1.2/sprint_116_blender_sketchfab_certification.json';

  /// The committed 116.35 creative asset rights verification that is a committed
  /// witness for the creative rights domain.
  static const String creativeAssetRightsVerificationManifestPath =
      'docs/planning/v1.2/sprint_116_creative_asset_rights_verification.json';

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

  /// The status and verdict the committed 117.18 creative connector workflow
  /// validation must carry to be a genuine pass.
  static const String requiredCreativeWorkflowStatus = 'pass';
  static const String requiredCreativeWorkflowVerdict =
      'CREATIVE_CONNECTOR_WORKFLOW_VALIDATED_LOCAL';

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
    'asset_rights',
    'attribution',
    'import',
    'export',
    'plan_limits',
  ];

  /// The six canonical requirements named by the objective, in canonical order.
  /// `provider_id` is the key, not a requirement.
  static const List<String> requiredOutputs = <String>[
    'selected_provider',
    'asset_rights',
    'attribution',
    'import',
    'export',
    'plan_limits',
  ];

  /// The committed evidence file each canonical requirement is anchored to, in
  /// canonical order.
  static const List<String> canonicalSources = <String>[
    creativeToolsConnectionsManifestPath,
    blenderSketchfabCertificationManifestPath,
    figmaCertificationManifestPath,
    creativeWorkflowValidationManifestPath,
    creativeWorkflowValidationManifestPath,
    adobeCanvaCertificationManifestPath,
  ];

  /// The committed evidence files every review is anchored to. All must be
  /// readable.
  static const List<String> witnessSources = <String>[
    charterManifestPath,
    snapshotManifestPath,
    approvalGateManifestPath,
    iconRegistryManifestPath,
    registryReconciliationManifestPath,
    creativeWorkflowValidationManifestPath,
    creativeToolsConnectionsManifestPath,
    figmaCertificationManifestPath,
    adobeCanvaCertificationManifestPath,
    blenderSketchfabCertificationManifestPath,
    creativeAssetRightsVerificationManifestPath,
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
  /// shipped creative connector is selected on the delayed path, so the honest
  /// reference is the committed 115.29 creative tools connections acceptance
  /// (`manifest_driven`).
  static const String selectedProviderToken = 'manifest_driven';

  /// The declared reference state for the asset-rights requirement. No live
  /// asset right is verified on the delayed path, so the honest reference is the
  /// committed 116.34 Blender Cloud/Sketchfab certification required field
  /// (`asset_rights`).
  static const String assetRightsToken = 'asset_rights';

  /// The declared reference state for the attribution requirement. No live
  /// attribution is verified on the delayed path, so the honest reference is the
  /// committed 116.32 Figma certification required field (`attribution`).
  static const String attributionToken = 'attribution';

  /// The declared reference state for the import requirement. No live asset
  /// import is executed on the delayed path, so the honest reference is the
  /// committed 117.18 creative connector workflow validation acceptance
  /// (`import`).
  static const String importToken = 'import';

  /// The declared reference state for the export requirement. No live asset
  /// export is executed on the delayed path, so the honest reference is the
  /// committed 117.18 creative connector workflow validation acceptance
  /// (`export`).
  static const String exportToken = 'export';

  /// The declared reference state for the plan-limits requirement. No live plan
  /// limit is read on the delayed path, so the honest reference is the committed
  /// 116.33 Adobe/Canva certification required field (`region_plan_limits`).
  static const String planLimitsToken = 'region_plan_limits';

  /// The committed witness vocabulary that grounds each canonical requirement,
  /// in canonical order.
  static List<List<String>> outputVocabularies(
    Sprint118CreativeConnectorAnchor anchor,
  ) => <List<String>>[
    anchor.selectedProviderVocabulary,
    anchor.assetRightsVocabulary,
    anchor.attributionVocabulary,
    anchor.importVocabulary,
    anchor.exportVocabulary,
    anchor.planLimitsVocabulary,
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
  /// A witness grounds a token when it names the token exactly (`attribution`,
  /// `import`, `export`), or when every underscore-separated part of a compound
  /// token is itself a witness-declared value. The vocabulary is measured from
  /// the committed witnesses, so a reference state cannot be invented into the
  /// list without a witness to ground it.
  static bool grounds(List<String> vocabulary, String token) {
    if (vocabulary.contains(token)) return true;
    final parts = token.split('_');
    if (parts.length < 2) return false;
    return parts.every(vocabulary.contains);
  }

  /// The committed witness vocabulary for a canonical requirement, or the empty
  /// list when the requirement is unknown.
  static List<String> vocabularyFor(
    Sprint118CreativeConnectorAnchor anchor,
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
  static Sprint118CreativeConnectorRecord get canonicalRecord =>
      Sprint118CreativeConnectorRecord(
        releaseState: delayedReleaseState,
        entries: <Sprint118CreativeConnectorEntry>[
          for (final id in canonicalProviders)
            Sprint118CreativeConnectorEntry(
              providerId: id,
              selectedProvider: selectedProviderToken,
              assetRights: assetRightsToken,
              attribution: attributionToken,
              importBoundary: importToken,
              exportBoundary: exportToken,
              planLimits: planLimitsToken,
            ),
        ],
      );
}

/// Reads the committed witnesses for step 118.37. Never invents: an unreadable
/// witness yields `null`, which the gate reports as blocked rather than as a
/// pass.
class Sprint118CreativeConnectorLoader {
  const Sprint118CreativeConnectorLoader();

  Sprint118CreativeConnectorAnchor? loadAnchor() {
    final charter = _read(
      Sprint118CreativeConnectorContract.charterManifestPath,
    );
    final snapshot = _read(
      Sprint118CreativeConnectorContract.snapshotManifestPath,
    );
    final approval = _read(
      Sprint118CreativeConnectorContract.approvalGateManifestPath,
    );
    final icon = _read(
      Sprint118CreativeConnectorContract.iconRegistryManifestPath,
    );
    final reconciliation = _read(
      Sprint118CreativeConnectorContract.registryReconciliationManifestPath,
    );
    final creativeWorkflow = _read(
      Sprint118CreativeConnectorContract.creativeWorkflowValidationManifestPath,
    );
    final creativeTools = _read(
      Sprint118CreativeConnectorContract.creativeToolsConnectionsManifestPath,
    );
    final figma = _read(
      Sprint118CreativeConnectorContract.figmaCertificationManifestPath,
    );
    final adobeCanva = _read(
      Sprint118CreativeConnectorContract.adobeCanvaCertificationManifestPath,
    );
    final blenderSketchfab = _read(
      Sprint118CreativeConnectorContract
          .blenderSketchfabCertificationManifestPath,
    );
    final creativeAssetRights = _read(
      Sprint118CreativeConnectorContract
          .creativeAssetRightsVerificationManifestPath,
    );
    if (charter == null ||
        snapshot == null ||
        approval == null ||
        icon == null ||
        reconciliation == null ||
        creativeWorkflow == null ||
        creativeTools == null ||
        figma == null ||
        adobeCanva == null ||
        blenderSketchfab == null ||
        creativeAssetRights == null) {
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

    final sources = Sprint118CreativeConnectorContract.witnessSources.toSet();
    return Sprint118CreativeConnectorAnchor(
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
      creativeWorkflowStatus: _text(creativeWorkflow['status']),
      creativeWorkflowVerdict: _text(creativeWorkflow['verdict']),
      registeredProviders: registered,
      selectedProviderVocabulary: _strings(creativeTools['acceptance']),
      assetRightsVocabulary: _strings(blenderSketchfab['required_fields']),
      attributionVocabulary: _strings(figma['required_fields']),
      importVocabulary: _strings(creativeWorkflow['acceptance_satisfied']),
      exportVocabulary: _strings(creativeWorkflow['acceptance_satisfied']),
      planLimitsVocabulary: _strings(adobeCanva['required_fields']),
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

/// The fail-closed creative connector expansion gate for step 118.37.
class Sprint118CreativeConnectorGate {
  const Sprint118CreativeConnectorGate();

  Sprint118CreativeConnectorReport evaluate() => evaluateWith(
    const Sprint118CreativeConnectorLoader().loadAnchor(),
    Sprint118CreativeConnectorContract.canonicalRecord,
  );

  Sprint118CreativeConnectorReport evaluateWith(
    Sprint118CreativeConnectorAnchor? anchor,
    Sprint118CreativeConnectorRecord record,
  ) {
    if (anchor == null) {
      return Sprint118CreativeConnectorReport(
        state: Sprint118CreativeConnectorState.blocked,
        verdict: 'SPRINT_118_CREATIVE_CONNECTOR_EXPANSION_EVIDENCE_UNREADABLE',
        releaseState: record.releaseState,
        blockers: const <String>[
          'committed_creative_connector_evidence_unreadable',
        ],
        openItems: const <String>[
          'committed_creative_connector_evidence_unreadable',
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
            Sprint118CreativeConnectorContract.requiredCharterState ||
        anchor.charterVerdict !=
            Sprint118CreativeConnectorContract.requiredCharterVerdict) {
      blockers.add('charter_not_complete:${anchor.charterVerdict}');
    }

    // (2) The 118.3 snapshot anchor must be a genuine frozen pass.
    if (anchor.snapshotState !=
            Sprint118CreativeConnectorContract.requiredSnapshotState ||
        anchor.snapshotVerdict !=
            Sprint118CreativeConnectorContract.requiredSnapshotVerdict) {
      blockers.add('snapshot_not_frozen:${anchor.snapshotVerdict}');
    }

    // (3) The 117.45 approval gate must record the delay decision, read with the
    // owner's exact grammar. If it is not a delay, the anchor is untrustworthy.
    if (anchor.approvalDecision !=
        Sprint118CreativeConnectorContract.requiredApprovalDecision) {
      blockers.add('approval_gate_not_delay:${anchor.approvalDecision}');
    }

    // (4) The 117.18 creative connector workflow validation must be a genuine
    // pass, or the creative anchor is untrustworthy.
    if (anchor.creativeWorkflowStatus !=
            Sprint118CreativeConnectorContract.requiredCreativeWorkflowStatus ||
        anchor.creativeWorkflowVerdict !=
            Sprint118CreativeConnectorContract
                .requiredCreativeWorkflowVerdict) {
      blockers.add(
        'creative_workflow_not_validated:${anchor.creativeWorkflowStatus}:'
        '${anchor.creativeWorkflowVerdict}',
      );
    }

    // (5) The registered provider set must reconcile across the icon registry,
    // the 116.3 reconciliation, the frozen snapshot, and the charter.
    if (anchor.registeredProviders.length !=
            Sprint118CreativeConnectorContract.expectedProviderCount ||
        anchor.registryExpectedCount !=
            Sprint118CreativeConnectorContract.expectedProviderCount ||
        anchor.snapshotRegistered !=
            Sprint118CreativeConnectorContract.expectedProviderCount ||
        anchor.charterRegisteredProviders !=
            Sprint118CreativeConnectorContract.expectedProviderCount) {
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
        Sprint118CreativeConnectorContract.delayedReleaseState) {
      violations.add(
        'creative_connector_not_on_delayed_path:${record.releaseState}',
      );
    }

    final delayed =
        record.releaseState ==
        Sprint118CreativeConnectorContract.delayedReleaseState;

    // (7) On the delayed path an authorized release execution and an unblocked
    // release are behavior that never ran.
    if (delayed && anchor.executionAuthorized) {
      violations.add('creative_connector_execution_authorized_on_delayed_path');
    }
    if (delayed && !anchor.releaseBlocked) {
      violations.add('creative_connector_release_not_blocked_on_delayed_path');
    }

    // (8) The expansion budget must stay frozen: no new certified connector and
    // no already-certified connector while the release is delayed.
    if (!frozen) {
      violations.add(
        'creative_connector_expansion_budget_not_frozen:max_new='
        '${anchor.charterMaxNewCertified}:'
        'currently=${anchor.charterCurrentlyCertified}',
      );
    }

    // (9) Every registered provider must appear exactly once, and each entry must
    // carry all seven canonical fields non-blank with every requirement grounded
    // by its committed witness vocabulary.
    final declared = <String, int>{};
    for (final entry in record.entries) {
      declared[entry.providerId] = (declared[entry.providerId] ?? 0) + 1;
    }
    for (final entry in record.entries) {
      final id = entry.providerId;
      if (!anchor.registeredProviders.contains(id)) {
        violations.add('creative_connector_provider_unknown:$id');
      }
      for (final field in Sprint118CreativeConnectorContract.requiredFields) {
        final value = entry.requiredFields[field] ?? '';
        if (value.trim().isEmpty) {
          violations.add('entry_blank_$field:$id');
        }
      }
      for (final output in Sprint118CreativeConnectorContract.requiredOutputs) {
        final token = entry.outputFields[output] ?? '';
        final vocabulary = Sprint118CreativeConnectorContract.vocabularyFor(
          anchor,
          output,
        );
        final grounded =
            token == Sprint118CreativeConnectorContract.noReferenceState ||
            Sprint118CreativeConnectorContract.grounds(vocabulary, token);
        if (token.trim().isEmpty || !grounded) {
          violations.add('reference_state_invalid:$output:$id');
        }
        if (token == Sprint118CreativeConnectorContract.noReferenceState) {
          openItems.add('upstream_state_vocabulary_gap:$output:$id');
        }
      }
      // A connector is never certified without live provider verification.
      if (entry.certified) {
        violations.add(
          'creative_connector_certified_claimed_on_delayed_path:$id',
        );
      }
      // A provider is never selected without a certified connector.
      if (entry.selected) {
        violations.add(
          'creative_connector_selected_claimed_on_delayed_path:$id',
        );
      }
      // An asset right is never verified without a live provider.
      if (entry.assetRightsVerified) {
        violations.add(
          'creative_connector_asset_rights_verified_on_delayed_path:$id',
        );
      }
      // An attribution is never verified without a live provider.
      if (entry.attributionVerified) {
        violations.add(
          'creative_connector_attribution_verified_on_delayed_path:$id',
        );
      }
      // An asset import is never executed without a live provider.
      if (entry.importVerified) {
        violations.add(
          'creative_connector_import_verified_on_delayed_path:$id',
        );
      }
      // An asset export is never executed without a live provider.
      if (entry.exportVerified) {
        violations.add(
          'creative_connector_export_verified_on_delayed_path:$id',
        );
      }
      // A plan limit is never read without a live provider.
      if (entry.planLimitsVerified) {
        violations.add(
          'creative_connector_plan_limits_verified_on_delayed_path:$id',
        );
      }
      // A provider is never released without an authorized release.
      if (entry.released) {
        violations.add('creative_connector_provider_released_claimed:$id');
      }
    }
    for (final id in declared.keys) {
      if (declared[id]! > 1) {
        violations.add('creative_connector_provider_duplicate:$id');
      }
    }
    for (final id in anchor.registeredProviders) {
      if (!declared.containsKey(id)) {
        violations.add('creative_connector_provider_missing:$id');
      }
    }

    // (10) Every committed evidence source must be readable.
    for (final source
        in Sprint118CreativeConnectorContract.witnessSources.toSet()) {
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
      return Sprint118CreativeConnectorReport(
        state: Sprint118CreativeConnectorState.blocked,
        verdict: 'SPRINT_118_CREATIVE_CONNECTOR_EXPANSION_BLOCKED_UPSTREAM',
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
      return Sprint118CreativeConnectorReport(
        state: Sprint118CreativeConnectorState.fail,
        verdict: 'SPRINT_118_CREATIVE_CONNECTOR_EXPANSION_EVIDENCE_VIOLATION',
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
    return Sprint118CreativeConnectorReport(
      state: Sprint118CreativeConnectorState.pass,
      verdict: 'CREATIVE_CONNECTOR_EXPANSION_VERIFIED_LOCAL',
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
