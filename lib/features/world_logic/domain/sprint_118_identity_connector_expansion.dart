/// Fail-closed identity connector expansion for roadmap step 118.33 -- Identity
/// Connector Expansion.
///
/// Objective (external canonical `sprint_118.json`): certify the next identity
/// connector one at a time with minimum scopes and takeover protection. The
/// canonical requirement set is exactly six items: `selected_provider`,
/// `auth_contract`, `minimum_scopes`, `collision_tests`, `revoke`, and
/// `security_review`.
///
/// The release is delayed. No connector is certified (118.3 froze `CERTIFIED: 0`
/// of `32` registered), the 118.2 charter froze an expansion budget of zero new
/// certified connectors out of 32 registered, the committed 117.45 approval gate
/// records `decision=delay`, `approval_state=PENDING_CHOIRUDIN`,
/// `execution_authorized=false`, and `release_blocked=true`, and the committed
/// 117.12 identity workflow validation records `connect` as the sole *unmet*
/// acceptance (`NO_SHIPPED_CONNECTOR_CONNECTABLE_FLOW_COMPLETES_ON_FIXTURE`) with
/// `live_provider_result=false` for every check. No identity connector has been
/// selected, no auth contract has been verified live, no minimum scope has been
/// granted, no collision test has run against a live provider, no provider
/// revocation has been executed, and no security review has verified a live
/// connector. An identity connector expansion review written against that state
/// therefore has exactly one honest shape: enumerate all 32 registered
/// providers, anchor each of the six requirements to a committed witness
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
/// * The committed 117.12 identity workflow validation must be a genuine pass
///   (`IDENTITY_WORKFLOW_VALIDATED_LOCAL`) that still records `connect` as
///   unmet. A certification review anchored to an unvalidated identity workflow
///   certifies a connector whose workflow nobody proved.
/// * The registered provider set must reconcile: the icon-registry provider
///   union, the 116.3 reconciliation count, the frozen snapshot count, and the
///   charter count must agree. A certification review over a drifting registry
///   is not a certification review.
/// * Every registered provider must appear exactly once. A record that drops a
///   provider, invents `telepathy`, or duplicates `openai` is not a
///   certification review.
/// * Every entry must carry all seven canonical fields non-blank, and each of
///   the six requirements must be grounded by the committed witness vocabulary
///   for that requirement, so a certification value cannot be invented into the
///   list without a witness to ground it.
/// * On the delayed path a certified connector, a selected provider, a
///   connectable connector, a granted minimum scope, a live-verified takeover
///   protection, or a released provider describe behavior that never ran. This
///   is refused by name, per entry.
///
/// **A provider is never recorded as a certified identity connector without
/// live provider verification and an authorized release.** When no identity
/// connector was selected and no release is authorized, the only honest
/// certification review records the committed identity-workflow reference for
/// each requirement and claims nothing live; any certified, selected,
/// connectable, scope-granted, takeover-verified, or released claim is refused
/// by name.
///
/// The output vocabulary is *derived from committed witnesses* (the 117.12
/// identity workflow validation acceptance set, the 115.11 OAuth linked identity
/// flow acceptance set, the 116.14 identity linking & collision acceptance set,
/// and the 116.45 security certification gate acceptance areas), and the source
/// for each requirement is a committed manifest, not copied by hand, so the
/// record and its witnesses cannot drift apart silently.
///
/// Identity connector selection, live auth-contract verification, live minimum
/// scope grants, live collision tests, provider revocation, live security
/// review, credential access, connector certification, provider exposure, and
/// publication remain `DEFERRED-EXTERNAL`; this review freezes local declared
/// state and executes none of it.
library;

import 'dart:convert';
import 'dart:io';

/// The three states an identity connector expansion review can rest in.
/// `blocked` is the honest resting state for "this review cannot yet be
/// trusted", and it is distinct from `fail`, which means the record contradicts
/// its own evidence.
enum Sprint118IdentityConnectorState { pass, fail, blocked }

/// One frozen identity connector expansion entry: the declared reference for
/// each of the six canonical requirements of a single registered provider.
///
/// `certified`, `selected`, `connectable`, `scopesGranted`,
/// `takeoverProtectionVerified`, and `released` are deliberately *not* among the
/// seven required fields; they are the flags the gate refuses when set, so that
/// a declared reference certification can be recorded while never being read as
/// a certified connector, a selected provider, a connectable connector, a
/// granted minimum scope, a verified takeover protection, or a released
/// provider.
class Sprint118IdentityConnectorEntry {
  const Sprint118IdentityConnectorEntry({
    required this.providerId,
    required this.selectedProvider,
    required this.authContract,
    required this.minimumScopes,
    required this.collisionTests,
    required this.revoke,
    required this.securityReview,
    this.certified = false,
    this.selected = false,
    this.connectable = false,
    this.scopesGranted = false,
    this.takeoverProtectionVerified = false,
    this.released = false,
  });

  /// The registered provider identifier, drawn from the committed icon registry.
  final String providerId;

  /// The selected-provider reference state, drawn from the committed 117.12
  /// identity workflow validation acceptance set.
  final String selectedProvider;

  /// The auth-contract reference state, drawn from the committed 115.11 OAuth
  /// linked identity flow acceptance set.
  final String authContract;

  /// The minimum-scopes reference state, drawn from the committed 115.11 OAuth
  /// linked identity flow acceptance set.
  final String minimumScopes;

  /// The collision-tests reference state, drawn from the committed 116.14
  /// identity linking & collision acceptance set.
  final String collisionTests;

  /// The revoke reference state, drawn from the committed 115.11 OAuth linked
  /// identity flow acceptance set.
  final String revoke;

  /// The security-review reference state, drawn from the committed 116.45
  /// security certification gate acceptance areas.
  final String securityReview;

  /// Whether the entry claims the connector was certified. On the delayed path
  /// this must stay `false`.
  final bool certified;

  /// Whether the entry claims the provider was selected. On the delayed path
  /// this must stay `false`.
  final bool selected;

  /// Whether the entry claims the connector is connectable. On the delayed path
  /// this must stay `false`.
  final bool connectable;

  /// Whether the entry claims a minimum scope was granted. On the delayed path
  /// this must stay `false`.
  final bool scopesGranted;

  /// Whether the entry claims the takeover protection was verified live. On the
  /// delayed path this must stay `false`.
  final bool takeoverProtectionVerified;

  /// Whether the entry claims a released provider. On the delayed path this must
  /// stay `false`.
  final bool released;

  /// The seven canonical fields as a name -> value map, so the gate can test
  /// blankness uniformly.
  Map<String, String> get requiredFields => <String, String>{
    'provider_id': providerId,
    'selected_provider': selectedProvider,
    'auth_contract': authContract,
    'minimum_scopes': minimumScopes,
    'collision_tests': collisionTests,
    'revoke': revoke,
    'security_review': securityReview,
  };

  /// The six requirements as a requirement -> value map, so the gate can test
  /// grounding per requirement.
  Map<String, String> get outputFields => <String, String>{
    'selected_provider': selectedProvider,
    'auth_contract': authContract,
    'minimum_scopes': minimumScopes,
    'collision_tests': collisionTests,
    'revoke': revoke,
    'security_review': securityReview,
  };
}

/// The frozen identity connector expansion review. `entries` is the declared
/// reference for each registered provider. On the delayed path no entry may
/// claim a live certification.
class Sprint118IdentityConnectorRecord {
  const Sprint118IdentityConnectorRecord({
    required this.releaseState,
    required this.entries,
  });

  final String releaseState;
  final List<Sprint118IdentityConnectorEntry> entries;

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
class Sprint118IdentityConnectorAnchor {
  const Sprint118IdentityConnectorAnchor({
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
    required this.identityWorkflowStatus,
    required this.identityWorkflowVerdict,
    required this.registeredProviders,
    required this.selectedProviderVocabulary,
    required this.authContractVocabulary,
    required this.minimumScopesVocabulary,
    required this.collisionTestsVocabulary,
    required this.revokeVocabulary,
    required this.securityReviewVocabulary,
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

  /// The status the committed 117.12 identity workflow validation declares.
  final String identityWorkflowStatus;

  /// The verdict the committed 117.12 identity workflow validation declares.
  final String identityWorkflowVerdict;

  /// The registered provider ids, unioned from the committed 115.8 icon registry.
  final List<String> registeredProviders;

  /// The selected-provider vocabulary the committed 117.12 identity workflow
  /// validation declares. It grounds the selected-provider requirement.
  final List<String> selectedProviderVocabulary;

  /// The auth-contract vocabulary the committed 115.11 OAuth linked identity flow
  /// declares. It grounds the auth-contract requirement.
  final List<String> authContractVocabulary;

  /// The minimum-scopes vocabulary the committed 115.11 OAuth linked identity
  /// flow declares. It grounds the minimum-scopes requirement.
  final List<String> minimumScopesVocabulary;

  /// The collision-tests vocabulary the committed 116.14 identity linking &
  /// collision declares. It grounds the collision-tests requirement.
  final List<String> collisionTestsVocabulary;

  /// The revoke vocabulary the committed 115.11 OAuth linked identity flow
  /// declares. It grounds the revoke requirement.
  final List<String> revokeVocabulary;

  /// The security-review vocabulary the committed 116.45 security certification
  /// gate declares. It grounds the security-review requirement.
  final List<String> securityReviewVocabulary;

  /// The committed evidence paths that are present and readable on disk.
  final List<String> readableSources;
}

/// The measured result. `pass` means the review is a faithful freeze; `blocked`
/// means it cannot yet be trusted; `fail` means it contradicts its evidence.
class Sprint118IdentityConnectorReport {
  const Sprint118IdentityConnectorReport({
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

  final Sprint118IdentityConnectorState state;
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
      state == Sprint118IdentityConnectorState.pass;

  String get externalGates => Sprint118IdentityConnectorContract.externalGates;
}

/// The fixed vocabulary and committed witness set for step 118.33.
abstract final class Sprint118IdentityConnectorContract {
  const Sprint118IdentityConnectorContract._();

  static const String canonicalStep = '118.33';
  static const String title = 'Identity Connector Expansion';

  static const String manifestPath =
      'docs/planning/v1.3/sprint_118_identity_connector_expansion.json';
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

  /// The committed 117.12 identity workflow validation that records `connect` as
  /// the sole unmet acceptance and grounds the selected-provider requirement.
  static const String identityWorkflowValidationManifestPath =
      'docs/planning/v1.3/sprint_117_identity_workflow_validation.json';

  /// The committed 115.11 OAuth linked identity flow that grounds the
  /// auth-contract, minimum-scopes, and revoke requirements.
  static const String oauthLinkedIdentityFlowManifestPath =
      'docs/planning/v1.2/sprint_115_oauth_linked_identity_flow.json';

  /// The committed 116.14 identity linking & collision that grounds the
  /// collision-tests requirement.
  static const String identityLinkingCollisionManifestPath =
      'docs/planning/v1.2/sprint_116_identity_linking_collision.json';

  /// The committed 116.45 security certification gate that grounds the
  /// security-review requirement.
  static const String securityCertificationGateManifestPath =
      'docs/planning/v1.2/sprint_116_security_certification_gate.json';

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

  /// The status and verdict the committed 117.12 identity workflow validation
  /// must carry to be a genuine pass.
  static const String requiredIdentityWorkflowStatus = 'pass';
  static const String requiredIdentityWorkflowVerdict =
      'IDENTITY_WORKFLOW_VALIDATED_LOCAL';

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
    'auth_contract',
    'minimum_scopes',
    'collision_tests',
    'revoke',
    'security_review',
  ];

  /// The six canonical requirements named by the objective, in canonical order.
  /// `provider_id` is the key, not a requirement.
  static const List<String> requiredOutputs = <String>[
    'selected_provider',
    'auth_contract',
    'minimum_scopes',
    'collision_tests',
    'revoke',
    'security_review',
  ];

  /// The committed evidence file each canonical requirement is anchored to, in
  /// canonical order.
  static const List<String> canonicalSources = <String>[
    identityWorkflowValidationManifestPath,
    oauthLinkedIdentityFlowManifestPath,
    oauthLinkedIdentityFlowManifestPath,
    identityLinkingCollisionManifestPath,
    oauthLinkedIdentityFlowManifestPath,
    securityCertificationGateManifestPath,
  ];

  /// The committed evidence files every review is anchored to. All must be
  /// readable.
  static const List<String> witnessSources = <String>[
    charterManifestPath,
    snapshotManifestPath,
    approvalGateManifestPath,
    iconRegistryManifestPath,
    registryReconciliationManifestPath,
    identityWorkflowValidationManifestPath,
    oauthLinkedIdentityFlowManifestPath,
    identityLinkingCollisionManifestPath,
    securityCertificationGateManifestPath,
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
  /// shipped identity connector is connectable on the delayed path, so the
  /// honest reference is the committed 117.12 identity workflow acceptance that
  /// remains unmet (`connect`).
  static const String selectedProviderToken = 'connect';

  /// The declared reference state for the auth-contract requirement. The auth
  /// contract is declared and unverified, so the honest reference is the
  /// committed 115.11 OAuth linked identity flow acceptance (`pkce`).
  static const String authContractToken = 'pkce';

  /// The declared reference state for the minimum-scopes requirement. No scope
  /// is granted live on the delayed path, so the honest reference is the
  /// committed 115.11 scoped-consent acceptance (`scoped_consent`).
  static const String minimumScopesToken = 'scoped_consent';

  /// The declared reference state for the collision-tests requirement. Takeover
  /// protection is declared and unverified, so the honest reference is the
  /// committed 116.14 identity linking & collision acceptance
  /// (`takeover_prevention`).
  static const String collisionTestsToken = 'takeover_prevention';

  /// The declared reference state for the revoke requirement. Provider
  /// revocation is declared and unexecuted, so the honest reference is the
  /// committed 115.11 revocation acceptance (`revocation`).
  static const String revokeToken = 'revocation';

  /// The declared reference state for the security-review requirement. No live
  /// security verification ran on the delayed path, so the honest reference is
  /// the committed 116.45 security certification acceptance area
  /// (`oauth_tests`).
  static const String securityReviewToken = 'oauth_tests';

  /// The committed witness vocabulary that grounds each canonical requirement,
  /// in canonical order.
  static List<List<String>> outputVocabularies(
    Sprint118IdentityConnectorAnchor anchor,
  ) => <List<String>>[
    anchor.selectedProviderVocabulary,
    anchor.authContractVocabulary,
    anchor.minimumScopesVocabulary,
    anchor.collisionTestsVocabulary,
    anchor.revokeVocabulary,
    anchor.securityReviewVocabulary,
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
  /// A witness grounds a token when it names the token exactly (`connect`,
  /// `pkce`, `scoped_consent`), or when every underscore-separated part of a
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
    Sprint118IdentityConnectorAnchor anchor,
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
  static Sprint118IdentityConnectorRecord get canonicalRecord =>
      Sprint118IdentityConnectorRecord(
        releaseState: delayedReleaseState,
        entries: <Sprint118IdentityConnectorEntry>[
          for (final id in canonicalProviders)
            Sprint118IdentityConnectorEntry(
              providerId: id,
              selectedProvider: selectedProviderToken,
              authContract: authContractToken,
              minimumScopes: minimumScopesToken,
              collisionTests: collisionTestsToken,
              revoke: revokeToken,
              securityReview: securityReviewToken,
            ),
        ],
      );
}

/// Reads the committed witnesses for step 118.33. Never invents: an unreadable
/// witness yields `null`, which the gate reports as blocked rather than as a
/// pass.
class Sprint118IdentityConnectorLoader {
  const Sprint118IdentityConnectorLoader();

  Sprint118IdentityConnectorAnchor? loadAnchor() {
    final charter = _read(
      Sprint118IdentityConnectorContract.charterManifestPath,
    );
    final snapshot = _read(
      Sprint118IdentityConnectorContract.snapshotManifestPath,
    );
    final approval = _read(
      Sprint118IdentityConnectorContract.approvalGateManifestPath,
    );
    final icon = _read(
      Sprint118IdentityConnectorContract.iconRegistryManifestPath,
    );
    final reconciliation = _read(
      Sprint118IdentityConnectorContract.registryReconciliationManifestPath,
    );
    final identityWorkflow = _read(
      Sprint118IdentityConnectorContract.identityWorkflowValidationManifestPath,
    );
    final oauthFlow = _read(
      Sprint118IdentityConnectorContract.oauthLinkedIdentityFlowManifestPath,
    );
    final collision = _read(
      Sprint118IdentityConnectorContract.identityLinkingCollisionManifestPath,
    );
    final security = _read(
      Sprint118IdentityConnectorContract.securityCertificationGateManifestPath,
    );
    if (charter == null ||
        snapshot == null ||
        approval == null ||
        icon == null ||
        reconciliation == null ||
        identityWorkflow == null ||
        oauthFlow == null ||
        collision == null ||
        security == null) {
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

    final sources = Sprint118IdentityConnectorContract.witnessSources.toSet();

    return Sprint118IdentityConnectorAnchor(
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
      identityWorkflowStatus: _text(identityWorkflow['status']),
      identityWorkflowVerdict: _text(identityWorkflow['verdict']),
      registeredProviders: registered,
      selectedProviderVocabulary: <String>[
        ..._strings(identityWorkflow['acceptance_satisfied']),
        ..._strings(identityWorkflow['acceptance_unmet']),
      ],
      authContractVocabulary: _strings(oauthFlow['acceptance']),
      minimumScopesVocabulary: _strings(oauthFlow['acceptance']),
      collisionTestsVocabulary: _strings(collision['acceptance']),
      revokeVocabulary: _strings(oauthFlow['acceptance']),
      securityReviewVocabulary: _strings(security['acceptance_areas']),
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

/// The fail-closed identity connector expansion gate for step 118.33.
class Sprint118IdentityConnectorGate {
  const Sprint118IdentityConnectorGate();

  Sprint118IdentityConnectorReport evaluate() => evaluateWith(
    const Sprint118IdentityConnectorLoader().loadAnchor(),
    Sprint118IdentityConnectorContract.canonicalRecord,
  );

  Sprint118IdentityConnectorReport evaluateWith(
    Sprint118IdentityConnectorAnchor? anchor,
    Sprint118IdentityConnectorRecord record,
  ) {
    if (anchor == null) {
      return Sprint118IdentityConnectorReport(
        state: Sprint118IdentityConnectorState.blocked,
        verdict: 'SPRINT_118_IDENTITY_CONNECTOR_EXPANSION_EVIDENCE_UNREADABLE',
        releaseState: record.releaseState,
        blockers: const <String>[
          'committed_identity_connector_evidence_unreadable',
        ],
        openItems: const <String>[
          'committed_identity_connector_evidence_unreadable',
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
            Sprint118IdentityConnectorContract.requiredCharterState ||
        anchor.charterVerdict !=
            Sprint118IdentityConnectorContract.requiredCharterVerdict) {
      blockers.add('charter_not_complete:${anchor.charterVerdict}');
    }

    // (2) The 118.3 snapshot anchor must be a genuine frozen pass.
    if (anchor.snapshotState !=
            Sprint118IdentityConnectorContract.requiredSnapshotState ||
        anchor.snapshotVerdict !=
            Sprint118IdentityConnectorContract.requiredSnapshotVerdict) {
      blockers.add('snapshot_not_frozen:${anchor.snapshotVerdict}');
    }

    // (3) The 117.45 approval gate must record the delay decision, read with the
    // owner's exact grammar. If it is not a delay, the anchor is untrustworthy.
    if (anchor.approvalDecision !=
        Sprint118IdentityConnectorContract.requiredApprovalDecision) {
      blockers.add('approval_gate_not_delay:${anchor.approvalDecision}');
    }

    // (4) The 117.12 identity workflow validation must be a genuine pass, or the
    // identity anchor is untrustworthy.
    if (anchor.identityWorkflowStatus !=
            Sprint118IdentityConnectorContract.requiredIdentityWorkflowStatus ||
        anchor.identityWorkflowVerdict !=
            Sprint118IdentityConnectorContract
                .requiredIdentityWorkflowVerdict) {
      blockers.add(
        'identity_workflow_not_validated:${anchor.identityWorkflowStatus}:'
        '${anchor.identityWorkflowVerdict}',
      );
    }

    // (5) The registered provider set must reconcile across the icon registry,
    // the 116.3 reconciliation, the frozen snapshot, and the charter.
    if (anchor.registeredProviders.length !=
            Sprint118IdentityConnectorContract.expectedProviderCount ||
        anchor.registryExpectedCount !=
            Sprint118IdentityConnectorContract.expectedProviderCount ||
        anchor.snapshotRegistered !=
            Sprint118IdentityConnectorContract.expectedProviderCount ||
        anchor.charterRegisteredProviders !=
            Sprint118IdentityConnectorContract.expectedProviderCount) {
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
        Sprint118IdentityConnectorContract.delayedReleaseState) {
      violations.add(
        'identity_connector_not_on_delayed_path:${record.releaseState}',
      );
    }

    final delayed =
        record.releaseState ==
        Sprint118IdentityConnectorContract.delayedReleaseState;

    // (7) On the delayed path an authorized release execution and an unblocked
    // release are behavior that never ran.
    if (delayed && anchor.executionAuthorized) {
      violations.add('identity_connector_execution_authorized_on_delayed_path');
    }
    if (delayed && !anchor.releaseBlocked) {
      violations.add('identity_connector_release_not_blocked_on_delayed_path');
    }

    // (8) The expansion budget must stay frozen: no new certified connector and
    // no already-certified connector while the release is delayed.
    if (!frozen) {
      violations.add(
        'identity_connector_expansion_budget_not_frozen:max_new='
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
        violations.add('identity_connector_provider_unknown:$id');
      }
      for (final field in Sprint118IdentityConnectorContract.requiredFields) {
        final value = entry.requiredFields[field] ?? '';
        if (value.trim().isEmpty) {
          violations.add('entry_blank_$field:$id');
        }
      }
      for (final output in Sprint118IdentityConnectorContract.requiredOutputs) {
        final token = entry.outputFields[output] ?? '';
        final vocabulary = Sprint118IdentityConnectorContract.vocabularyFor(
          anchor,
          output,
        );
        final grounded =
            token == Sprint118IdentityConnectorContract.noReferenceState ||
            Sprint118IdentityConnectorContract.grounds(vocabulary, token);
        if (token.trim().isEmpty || !grounded) {
          violations.add('reference_state_invalid:$output:$id');
        }
        if (token == Sprint118IdentityConnectorContract.noReferenceState) {
          openItems.add('upstream_state_vocabulary_gap:$output:$id');
        }
      }
      // A connector is never certified without live provider verification.
      if (entry.certified) {
        violations.add(
          'identity_connector_certified_claimed_on_delayed_path:$id',
        );
      }
      // A provider is never selected without a certified connector.
      if (entry.selected) {
        violations.add(
          'identity_connector_selected_claimed_on_delayed_path:$id',
        );
      }
      // A connector is never connectable without a certified connector.
      if (entry.connectable) {
        violations.add(
          'identity_connector_connectable_claimed_on_delayed_path:$id',
        );
      }
      // A minimum scope is never granted without a live auth exchange.
      if (entry.scopesGranted) {
        violations.add('identity_connector_scopes_granted_on_delayed_path:$id');
      }
      // Takeover protection is never verified live without a live provider.
      if (entry.takeoverProtectionVerified) {
        violations.add(
          'identity_connector_takeover_protection_verified_on_delayed_path:$id',
        );
      }
      // A provider is never released without an authorized release.
      if (entry.released) {
        violations.add('identity_connector_provider_released_claimed:$id');
      }
    }
    for (final id in declared.keys) {
      if (declared[id]! > 1) {
        violations.add('identity_connector_provider_duplicate:$id');
      }
    }
    for (final id in anchor.registeredProviders) {
      if (!declared.containsKey(id)) {
        violations.add('identity_connector_provider_missing:$id');
      }
    }

    // (10) Every committed evidence source must be readable.
    for (final source
        in Sprint118IdentityConnectorContract.witnessSources.toSet()) {
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
      return Sprint118IdentityConnectorReport(
        state: Sprint118IdentityConnectorState.blocked,
        verdict: 'SPRINT_118_IDENTITY_CONNECTOR_EXPANSION_BLOCKED_UPSTREAM',
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
      return Sprint118IdentityConnectorReport(
        state: Sprint118IdentityConnectorState.fail,
        verdict: 'SPRINT_118_IDENTITY_CONNECTOR_EXPANSION_EVIDENCE_VIOLATION',
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
    return Sprint118IdentityConnectorReport(
      state: Sprint118IdentityConnectorState.pass,
      verdict: 'IDENTITY_CONNECTOR_EXPANSION_VERIFIED_LOCAL',
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
