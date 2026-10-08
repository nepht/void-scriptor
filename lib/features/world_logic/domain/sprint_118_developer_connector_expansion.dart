/// Fail-closed developer connector expansion for roadmap step 118.36 --
/// Developer Connector Expansion.
///
/// Objective (external canonical `sprint_118.json`): certify the next developer
/// connector one at a time with resource scopes, rate limits, organization
/// policy, revoke, and audit. The canonical requirement set is exactly seven
/// items: `selected_provider`, `scopes`, `resources`, `rate_limits`,
/// `organization_policy`, `revoke`, and `audit`.
///
/// The release is delayed. No connector is certified (118.3 froze `CERTIFIED: 0`
/// of `32` registered), the 118.2 charter froze an expansion budget of zero new
/// certified connectors out of 32 registered, the committed 117.45 approval gate
/// records `decision=delay`, `approval_state=PENDING_CHOIRUDIN`,
/// `execution_authorized=false`, and `release_blocked=true`, and the committed
/// 117.17 developer connector workflow validation records `status=pass` with
/// `DEVELOPER_CONNECTOR_WORKFLOW_VALIDATED_LOCAL`. No developer connector has
/// been selected, no live repository scope has been verified, no live resource
/// access has been verified, no live rate-limit window has been observed, no
/// live organization policy has been read, no live revocation has been
/// exercised, and no live audit stream has been read. A developer connector
/// expansion review written against that state therefore has exactly one honest
/// shape: enumerate all 32 registered providers, anchor each of the seven
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
/// * The committed 117.17 developer connector workflow validation must be a
///   genuine pass (`status == pass` and
///   `DEVELOPER_CONNECTOR_WORKFLOW_VALIDATED_LOCAL`). A certification review
///   anchored to an unvalidated developer workflow certifies a connector whose
///   workflow nobody proved.
/// * The registered provider set must reconcile: the icon-registry provider
///   union, the 116.3 reconciliation count, the frozen snapshot count, and the
///   charter count must agree. A certification review over a drifting registry
///   is not a certification review.
/// * Every registered provider must appear exactly once. A record that drops a
///   provider, invents `telepathy`, or duplicates `github` is not a
///   certification review.
/// * Every entry must carry all eight canonical fields non-blank, and each of
///   the seven requirements must be grounded by the committed witness vocabulary
///   for that requirement, so a certification value cannot be invented into the
///   list without a witness to ground it.
/// * On the delayed path a certified connector, a selected provider, a
///   live-granted scope, a live-verified resource access, a live-observed
///   rate-limit window, a live-read organization policy, a live revocation, a
///   live audit stream, or a released provider describe behavior that never
///   ran. This is refused by name, per entry.
///
/// **A provider is never recorded as a certified developer connector without
/// live provider verification and an authorized release.** When no developer
/// connector was selected and no release is authorized, the only honest
/// certification review records the committed developer-connector reference for
/// each requirement and claims nothing live; any certified, selected,
/// scope-granted, resource-verified, rate-limit-verified,
/// organization-policy-verified, revoke-verified, audit-verified, or released
/// claim is refused by name.
///
/// The output vocabulary is *derived from committed witnesses* (the 115.28
/// developer tools connections acceptance set, the 117.17 developer connector
/// workflow validation acceptance set, the 116.31 Azure DevOps certification
/// required-field set, the 116.28 GitHub developer certification required-field
/// set, the 116.29 GitLab developer certification required-field set, and the
/// 116.30 Bitbucket developer certification required-field set), and the source
/// for each requirement is a committed manifest, not copied by hand, so the
/// record and its witnesses cannot drift apart silently.
///
/// Developer connector selection, live scope verification, live resource-access
/// verification, live rate-limit observation, live organization-policy reads,
/// live revocation exercises, live audit reads, credential access, connector
/// certification, provider exposure, and publication remain `DEFERRED-EXTERNAL`;
/// this review freezes local declared state and executes none of it.
library;

import 'dart:convert';
import 'dart:io';

/// The three states a developer connector expansion review can rest in.
/// `blocked` is the honest resting state for "this review cannot yet be
/// trusted", and it is distinct from `fail`, which means the record contradicts
/// its own evidence.
enum Sprint118DeveloperConnectorState { pass, fail, blocked }

/// One frozen developer connector expansion entry: the declared reference for
/// each of the seven canonical requirements of a single registered provider.
///
/// `certified`, `selected`, `scopesGranted`, `resourcesVerified`,
/// `rateLimitsVerified`, `organizationPolicyVerified`, `revokeVerified`,
/// `auditVerified`, and `released` are deliberately *not* among the eight
/// required fields; they are the flags the gate refuses when set, so that a
/// declared reference certification can be recorded while never being read as a
/// certified connector, a selected provider, a live-granted scope, a
/// live-verified resource access, a live-observed rate-limit window, a
/// live-read organization policy, a live revocation, a live audit stream, or a
/// released provider.
class Sprint118DeveloperConnectorEntry {
  const Sprint118DeveloperConnectorEntry({
    required this.providerId,
    required this.selectedProvider,
    required this.scopes,
    required this.resources,
    required this.rateLimits,
    required this.organizationPolicy,
    required this.revoke,
    required this.audit,
    this.certified = false,
    this.selected = false,
    this.scopesGranted = false,
    this.resourcesVerified = false,
    this.rateLimitsVerified = false,
    this.organizationPolicyVerified = false,
    this.revokeVerified = false,
    this.auditVerified = false,
    this.released = false,
  });

  /// The registered provider identifier, drawn from the committed icon registry.
  final String providerId;

  /// The selected-provider reference state, drawn from the committed 115.28
  /// developer tools connections acceptance set.
  final String selectedProvider;

  /// The scopes reference state, drawn from the committed 115.28 developer tools
  /// connections acceptance set.
  final String scopes;

  /// The resources reference state, drawn from the committed 117.17 developer
  /// connector workflow validation acceptance set.
  final String resources;

  /// The rate-limits reference state, drawn from the committed 116.31 Azure
  /// DevOps certification required-field set.
  final String rateLimits;

  /// The organization-policy reference state, drawn from the committed 116.28
  /// GitHub developer certification required-field set.
  final String organizationPolicy;

  /// The revoke reference state, drawn from the committed 116.29 GitLab
  /// developer certification required-field set.
  final String revoke;

  /// The audit reference state, drawn from the committed 116.30 Bitbucket
  /// developer certification required-field set.
  final String audit;

  /// Whether the entry claims the connector was certified. On the delayed path
  /// this must stay `false`.
  final bool certified;

  /// Whether the entry claims the provider was selected. On the delayed path
  /// this must stay `false`.
  final bool selected;

  /// Whether the entry claims a live scope was granted. On the delayed path this
  /// must stay `false`.
  final bool scopesGranted;

  /// Whether the entry claims a live resource access was verified. On the
  /// delayed path this must stay `false`.
  final bool resourcesVerified;

  /// Whether the entry claims a live rate-limit window was observed. On the
  /// delayed path this must stay `false`.
  final bool rateLimitsVerified;

  /// Whether the entry claims a live organization policy was read. On the
  /// delayed path this must stay `false`.
  final bool organizationPolicyVerified;

  /// Whether the entry claims a live revocation was exercised. On the delayed
  /// path this must stay `false`.
  final bool revokeVerified;

  /// Whether the entry claims a live audit stream was read. On the delayed path
  /// this must stay `false`.
  final bool auditVerified;

  /// Whether the entry claims a released provider. On the delayed path this must
  /// stay `false`.
  final bool released;

  /// The eight canonical fields as a name -> value map, so the gate can test
  /// blankness uniformly.
  Map<String, String> get requiredFields => <String, String>{
    'provider_id': providerId,
    'selected_provider': selectedProvider,
    'scopes': scopes,
    'resources': resources,
    'rate_limits': rateLimits,
    'organization_policy': organizationPolicy,
    'revoke': revoke,
    'audit': audit,
  };

  /// The seven requirements as a requirement -> value map, so the gate can test
  /// grounding per requirement.
  Map<String, String> get outputFields => <String, String>{
    'selected_provider': selectedProvider,
    'scopes': scopes,
    'resources': resources,
    'rate_limits': rateLimits,
    'organization_policy': organizationPolicy,
    'revoke': revoke,
    'audit': audit,
  };
}

/// The frozen developer connector expansion review. `entries` is the declared
/// reference for each registered provider. On the delayed path no entry may
/// claim a live certification.
class Sprint118DeveloperConnectorRecord {
  const Sprint118DeveloperConnectorRecord({
    required this.releaseState,
    required this.entries,
  });

  final String releaseState;
  final List<Sprint118DeveloperConnectorEntry> entries;

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
class Sprint118DeveloperConnectorAnchor {
  const Sprint118DeveloperConnectorAnchor({
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
    required this.developerWorkflowStatus,
    required this.developerWorkflowVerdict,
    required this.registeredProviders,
    required this.selectedProviderVocabulary,
    required this.scopesVocabulary,
    required this.resourcesVocabulary,
    required this.rateLimitsVocabulary,
    required this.organizationPolicyVocabulary,
    required this.revokeVocabulary,
    required this.auditVocabulary,
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

  /// The status the committed 117.17 developer connector workflow validation
  /// declares.
  final String developerWorkflowStatus;

  /// The verdict the committed 117.17 developer connector workflow validation
  /// declares.
  final String developerWorkflowVerdict;

  /// The registered provider ids, unioned from the committed 115.8 icon registry.
  final List<String> registeredProviders;

  /// The selected-provider vocabulary the committed 115.28 developer tools
  /// connections declares. It grounds the selected-provider requirement.
  final List<String> selectedProviderVocabulary;

  /// The scopes vocabulary the committed 115.28 developer tools connections
  /// declares. It grounds the scopes requirement.
  final List<String> scopesVocabulary;

  /// The resources vocabulary the committed 117.17 developer connector workflow
  /// validation declares. It grounds the resources requirement.
  final List<String> resourcesVocabulary;

  /// The rate-limits vocabulary the committed 116.31 Azure DevOps certification
  /// declares. It grounds the rate-limits requirement.
  final List<String> rateLimitsVocabulary;

  /// The organization-policy vocabulary the committed 116.28 GitHub developer
  /// certification declares. It grounds the organization-policy requirement.
  final List<String> organizationPolicyVocabulary;

  /// The revoke vocabulary the committed 116.29 GitLab developer certification
  /// declares. It grounds the revoke requirement.
  final List<String> revokeVocabulary;

  /// The audit vocabulary the committed 116.30 Bitbucket developer certification
  /// declares. It grounds the audit requirement.
  final List<String> auditVocabulary;

  /// The committed evidence paths that are present and readable on disk.
  final List<String> readableSources;
}

/// The measured result. `pass` means the review is a faithful freeze; `blocked`
/// means it cannot yet be trusted; `fail` means it contradicts its evidence.
class Sprint118DeveloperConnectorReport {
  const Sprint118DeveloperConnectorReport({
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

  final Sprint118DeveloperConnectorState state;
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
      state == Sprint118DeveloperConnectorState.pass;

  String get externalGates => Sprint118DeveloperConnectorContract.externalGates;
}

/// The fixed vocabulary and committed witness set for step 118.36.
abstract final class Sprint118DeveloperConnectorContract {
  const Sprint118DeveloperConnectorContract._();

  static const String canonicalStep = '118.36';
  static const String title = 'Developer Connector Expansion';

  static const String manifestPath =
      'docs/planning/v1.3/sprint_118_developer_connector_expansion.json';
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

  /// The committed 117.17 developer connector workflow validation that records
  /// `DEVELOPER_CONNECTOR_WORKFLOW_VALIDATED_LOCAL` and grounds the developer
  /// domain anchor.
  static const String developerWorkflowValidationManifestPath =
      'docs/evidence/sprint-117-17-manifest-20261001.json';

  /// The committed 115.28 developer tools connections that grounds the
  /// selected-provider and scopes requirements.
  static const String developerToolsConnectionsManifestPath =
      'docs/planning/v1.2/sprint_115_developer_tools_connections.json';

  /// The committed 116.28 GitHub developer certification that grounds the
  /// organization-policy requirement.
  static const String githubDeveloperCertificationManifestPath =
      'docs/planning/v1.2/sprint_116_github_developer_certification.json';

  /// The committed 116.29 GitLab developer certification that grounds the revoke
  /// requirement.
  static const String gitlabDeveloperCertificationManifestPath =
      'docs/planning/v1.2/sprint_116_gitlab_developer_certification.json';

  /// The committed 116.30 Bitbucket developer certification that grounds the
  /// audit requirement.
  static const String bitbucketDeveloperCertificationManifestPath =
      'docs/planning/v1.2/sprint_116_bitbucket_developer_certification.json';

  /// The committed 116.31 Azure DevOps certification that grounds the
  /// rate-limits requirement.
  static const String azureDevopsCertificationManifestPath =
      'docs/planning/v1.2/sprint_116_azure_devops_certification.json';

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

  /// The status and verdict the committed 117.17 developer connector workflow
  /// validation must carry to be a genuine pass.
  static const String requiredDeveloperWorkflowStatus = 'pass';
  static const String requiredDeveloperWorkflowVerdict =
      'DEVELOPER_CONNECTOR_WORKFLOW_VALIDATED_LOCAL';

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
    'scopes',
    'resources',
    'rate_limits',
    'organization_policy',
    'revoke',
    'audit',
  ];

  /// The seven canonical requirements named by the objective, in canonical
  /// order. `provider_id` is the key, not a requirement.
  static const List<String> requiredOutputs = <String>[
    'selected_provider',
    'scopes',
    'resources',
    'rate_limits',
    'organization_policy',
    'revoke',
    'audit',
  ];

  /// The committed evidence file each canonical requirement is anchored to, in
  /// canonical order.
  static const List<String> canonicalSources = <String>[
    developerToolsConnectionsManifestPath,
    developerToolsConnectionsManifestPath,
    developerWorkflowValidationManifestPath,
    azureDevopsCertificationManifestPath,
    githubDeveloperCertificationManifestPath,
    gitlabDeveloperCertificationManifestPath,
    bitbucketDeveloperCertificationManifestPath,
  ];

  /// The committed evidence files every review is anchored to. All must be
  /// readable.
  static const List<String> witnessSources = <String>[
    charterManifestPath,
    snapshotManifestPath,
    approvalGateManifestPath,
    iconRegistryManifestPath,
    registryReconciliationManifestPath,
    developerWorkflowValidationManifestPath,
    developerToolsConnectionsManifestPath,
    githubDeveloperCertificationManifestPath,
    gitlabDeveloperCertificationManifestPath,
    bitbucketDeveloperCertificationManifestPath,
    azureDevopsCertificationManifestPath,
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
  /// shipped developer connector is selected on the delayed path, so the honest
  /// reference is the committed 115.28 developer tools connections acceptance
  /// (`manifest_driven`).
  static const String selectedProviderToken = 'manifest_driven';

  /// The declared reference state for the scopes requirement. No live scope is
  /// granted on the delayed path, so the honest reference is the committed 115.28
  /// developer tools connections acceptance (`scopes`).
  static const String scopesToken = 'scopes';

  /// The declared reference state for the resources requirement. No live
  /// resource access is verified on the delayed path, so the honest reference is
  /// the committed 117.17 developer connector workflow validation acceptance
  /// (`resource_access`).
  static const String resourcesToken = 'resource_access';

  /// The declared reference state for the rate-limits requirement. No live
  /// rate-limit window is observed on the delayed path, so the honest reference
  /// is the committed 116.31 Azure DevOps certification required field
  /// (`rate_limits`).
  static const String rateLimitsToken = 'rate_limits';

  /// The declared reference state for the organization-policy requirement. No
  /// live organization policy is read on the delayed path, so the honest
  /// reference is the committed 116.28 GitHub developer certification required
  /// field (`organization_policy`).
  static const String organizationPolicyToken = 'organization_policy';

  /// The declared reference state for the revoke requirement. No live revocation
  /// is exercised on the delayed path, so the honest reference is the committed
  /// 116.29 GitLab developer certification required field (`revoke`).
  static const String revokeToken = 'revoke';

  /// The declared reference state for the audit requirement. No live audit
  /// stream is read on the delayed path, so the honest reference is the
  /// committed 116.30 Bitbucket developer certification required field
  /// (`audit`).
  static const String auditToken = 'audit';

  /// The committed witness vocabulary that grounds each canonical requirement,
  /// in canonical order.
  static List<List<String>> outputVocabularies(
    Sprint118DeveloperConnectorAnchor anchor,
  ) => <List<String>>[
    anchor.selectedProviderVocabulary,
    anchor.scopesVocabulary,
    anchor.resourcesVocabulary,
    anchor.rateLimitsVocabulary,
    anchor.organizationPolicyVocabulary,
    anchor.revokeVocabulary,
    anchor.auditVocabulary,
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
  /// A witness grounds a token when it names the token exactly (`scopes`,
  /// `revoke`, `audit`), or when every underscore-separated part of a compound
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
    Sprint118DeveloperConnectorAnchor anchor,
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
  static Sprint118DeveloperConnectorRecord get canonicalRecord =>
      Sprint118DeveloperConnectorRecord(
        releaseState: delayedReleaseState,
        entries: <Sprint118DeveloperConnectorEntry>[
          for (final id in canonicalProviders)
            Sprint118DeveloperConnectorEntry(
              providerId: id,
              selectedProvider: selectedProviderToken,
              scopes: scopesToken,
              resources: resourcesToken,
              rateLimits: rateLimitsToken,
              organizationPolicy: organizationPolicyToken,
              revoke: revokeToken,
              audit: auditToken,
            ),
        ],
      );
}

/// Reads the committed witnesses for step 118.36. Never invents: an unreadable
/// witness yields `null`, which the gate reports as blocked rather than as a
/// pass.
class Sprint118DeveloperConnectorLoader {
  const Sprint118DeveloperConnectorLoader();

  Sprint118DeveloperConnectorAnchor? loadAnchor() {
    final charter = _read(
      Sprint118DeveloperConnectorContract.charterManifestPath,
    );
    final snapshot = _read(
      Sprint118DeveloperConnectorContract.snapshotManifestPath,
    );
    final approval = _read(
      Sprint118DeveloperConnectorContract.approvalGateManifestPath,
    );
    final icon = _read(
      Sprint118DeveloperConnectorContract.iconRegistryManifestPath,
    );
    final reconciliation = _read(
      Sprint118DeveloperConnectorContract.registryReconciliationManifestPath,
    );
    final developerWorkflow = _read(
      Sprint118DeveloperConnectorContract
          .developerWorkflowValidationManifestPath,
    );
    final developerTools = _read(
      Sprint118DeveloperConnectorContract.developerToolsConnectionsManifestPath,
    );
    final github = _read(
      Sprint118DeveloperConnectorContract
          .githubDeveloperCertificationManifestPath,
    );
    final gitlab = _read(
      Sprint118DeveloperConnectorContract
          .gitlabDeveloperCertificationManifestPath,
    );
    final bitbucket = _read(
      Sprint118DeveloperConnectorContract
          .bitbucketDeveloperCertificationManifestPath,
    );
    final azure = _read(
      Sprint118DeveloperConnectorContract.azureDevopsCertificationManifestPath,
    );
    if (charter == null ||
        snapshot == null ||
        approval == null ||
        icon == null ||
        reconciliation == null ||
        developerWorkflow == null ||
        developerTools == null ||
        github == null ||
        gitlab == null ||
        bitbucket == null ||
        azure == null) {
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

    final sources = Sprint118DeveloperConnectorContract.witnessSources.toSet();
    return Sprint118DeveloperConnectorAnchor(
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
      developerWorkflowStatus: _text(developerWorkflow['status']),
      developerWorkflowVerdict: _text(developerWorkflow['verdict']),
      registeredProviders: registered,
      selectedProviderVocabulary: _strings(developerTools['acceptance']),
      scopesVocabulary: _strings(developerTools['acceptance']),
      resourcesVocabulary: _strings(developerWorkflow['acceptance_satisfied']),
      rateLimitsVocabulary: _strings(azure['required_fields']),
      organizationPolicyVocabulary: _strings(github['required_fields']),
      revokeVocabulary: _strings(gitlab['required_fields']),
      auditVocabulary: _strings(bitbucket['required_fields']),
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

/// The fail-closed developer connector expansion gate for step 118.36.
class Sprint118DeveloperConnectorGate {
  const Sprint118DeveloperConnectorGate();

  Sprint118DeveloperConnectorReport evaluate() => evaluateWith(
    const Sprint118DeveloperConnectorLoader().loadAnchor(),
    Sprint118DeveloperConnectorContract.canonicalRecord,
  );

  Sprint118DeveloperConnectorReport evaluateWith(
    Sprint118DeveloperConnectorAnchor? anchor,
    Sprint118DeveloperConnectorRecord record,
  ) {
    if (anchor == null) {
      return Sprint118DeveloperConnectorReport(
        state: Sprint118DeveloperConnectorState.blocked,
        verdict: 'SPRINT_118_DEVELOPER_CONNECTOR_EXPANSION_EVIDENCE_UNREADABLE',
        releaseState: record.releaseState,
        blockers: const <String>[
          'committed_developer_connector_evidence_unreadable',
        ],
        openItems: const <String>[
          'committed_developer_connector_evidence_unreadable',
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
            Sprint118DeveloperConnectorContract.requiredCharterState ||
        anchor.charterVerdict !=
            Sprint118DeveloperConnectorContract.requiredCharterVerdict) {
      blockers.add('charter_not_complete:${anchor.charterVerdict}');
    }

    // (2) The 118.3 snapshot anchor must be a genuine frozen pass.
    if (anchor.snapshotState !=
            Sprint118DeveloperConnectorContract.requiredSnapshotState ||
        anchor.snapshotVerdict !=
            Sprint118DeveloperConnectorContract.requiredSnapshotVerdict) {
      blockers.add('snapshot_not_frozen:${anchor.snapshotVerdict}');
    }

    // (3) The 117.45 approval gate must record the delay decision, read with the
    // owner's exact grammar. If it is not a delay, the anchor is untrustworthy.
    if (anchor.approvalDecision !=
        Sprint118DeveloperConnectorContract.requiredApprovalDecision) {
      blockers.add('approval_gate_not_delay:${anchor.approvalDecision}');
    }

    // (4) The 117.17 developer connector workflow validation must be a genuine
    // pass, or the developer anchor is untrustworthy.
    if (anchor.developerWorkflowStatus !=
            Sprint118DeveloperConnectorContract
                .requiredDeveloperWorkflowStatus ||
        anchor.developerWorkflowVerdict !=
            Sprint118DeveloperConnectorContract
                .requiredDeveloperWorkflowVerdict) {
      blockers.add(
        'developer_workflow_not_validated:${anchor.developerWorkflowStatus}:'
        '${anchor.developerWorkflowVerdict}',
      );
    }

    // (5) The registered provider set must reconcile across the icon registry,
    // the 116.3 reconciliation, the frozen snapshot, and the charter.
    if (anchor.registeredProviders.length !=
            Sprint118DeveloperConnectorContract.expectedProviderCount ||
        anchor.registryExpectedCount !=
            Sprint118DeveloperConnectorContract.expectedProviderCount ||
        anchor.snapshotRegistered !=
            Sprint118DeveloperConnectorContract.expectedProviderCount ||
        anchor.charterRegisteredProviders !=
            Sprint118DeveloperConnectorContract.expectedProviderCount) {
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
        Sprint118DeveloperConnectorContract.delayedReleaseState) {
      violations.add(
        'developer_connector_not_on_delayed_path:${record.releaseState}',
      );
    }

    final delayed =
        record.releaseState ==
        Sprint118DeveloperConnectorContract.delayedReleaseState;

    // (7) On the delayed path an authorized release execution and an unblocked
    // release are behavior that never ran.
    if (delayed && anchor.executionAuthorized) {
      violations.add(
        'developer_connector_execution_authorized_on_delayed_path',
      );
    }
    if (delayed && !anchor.releaseBlocked) {
      violations.add('developer_connector_release_not_blocked_on_delayed_path');
    }

    // (8) The expansion budget must stay frozen: no new certified connector and
    // no already-certified connector while the release is delayed.
    if (!frozen) {
      violations.add(
        'developer_connector_expansion_budget_not_frozen:max_new='
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
        violations.add('developer_connector_provider_unknown:$id');
      }
      for (final field in Sprint118DeveloperConnectorContract.requiredFields) {
        final value = entry.requiredFields[field] ?? '';
        if (value.trim().isEmpty) {
          violations.add('entry_blank_$field:$id');
        }
      }
      for (final output
          in Sprint118DeveloperConnectorContract.requiredOutputs) {
        final token = entry.outputFields[output] ?? '';
        final vocabulary = Sprint118DeveloperConnectorContract.vocabularyFor(
          anchor,
          output,
        );
        final grounded =
            token == Sprint118DeveloperConnectorContract.noReferenceState ||
            Sprint118DeveloperConnectorContract.grounds(vocabulary, token);
        if (token.trim().isEmpty || !grounded) {
          violations.add('reference_state_invalid:$output:$id');
        }
        if (token == Sprint118DeveloperConnectorContract.noReferenceState) {
          openItems.add('upstream_state_vocabulary_gap:$output:$id');
        }
      }
      // A connector is never certified without live provider verification.
      if (entry.certified) {
        violations.add(
          'developer_connector_certified_claimed_on_delayed_path:$id',
        );
      }
      // A provider is never selected without a certified connector.
      if (entry.selected) {
        violations.add(
          'developer_connector_selected_claimed_on_delayed_path:$id',
        );
      }
      // A scope is never granted without a live provider.
      if (entry.scopesGranted) {
        violations.add(
          'developer_connector_scopes_granted_on_delayed_path:$id',
        );
      }
      // A resource access is never verified without a live provider.
      if (entry.resourcesVerified) {
        violations.add(
          'developer_connector_resources_verified_on_delayed_path:$id',
        );
      }
      // A rate-limit window is never observed without a live provider.
      if (entry.rateLimitsVerified) {
        violations.add(
          'developer_connector_rate_limits_verified_on_delayed_path:$id',
        );
      }
      // An organization policy is never read without a live provider.
      if (entry.organizationPolicyVerified) {
        violations.add(
          'developer_connector_organization_policy_verified_on_delayed_path:$id',
        );
      }
      // A revocation is never exercised without a live provider.
      if (entry.revokeVerified) {
        violations.add(
          'developer_connector_revoke_verified_on_delayed_path:$id',
        );
      }
      // An audit stream is never read without a live provider.
      if (entry.auditVerified) {
        violations.add(
          'developer_connector_audit_verified_on_delayed_path:$id',
        );
      }
      // A provider is never released without an authorized release.
      if (entry.released) {
        violations.add('developer_connector_provider_released_claimed:$id');
      }
    }
    for (final id in declared.keys) {
      if (declared[id]! > 1) {
        violations.add('developer_connector_provider_duplicate:$id');
      }
    }
    for (final id in anchor.registeredProviders) {
      if (!declared.containsKey(id)) {
        violations.add('developer_connector_provider_missing:$id');
      }
    }

    // (10) Every committed evidence source must be readable.
    for (final source
        in Sprint118DeveloperConnectorContract.witnessSources.toSet()) {
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
      return Sprint118DeveloperConnectorReport(
        state: Sprint118DeveloperConnectorState.blocked,
        verdict: 'SPRINT_118_DEVELOPER_CONNECTOR_EXPANSION_BLOCKED_UPSTREAM',
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
      return Sprint118DeveloperConnectorReport(
        state: Sprint118DeveloperConnectorState.fail,
        verdict: 'SPRINT_118_DEVELOPER_CONNECTOR_EXPANSION_EVIDENCE_VIOLATION',
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
    return Sprint118DeveloperConnectorReport(
      state: Sprint118DeveloperConnectorState.pass,
      verdict: 'DEVELOPER_CONNECTOR_EXPANSION_VERIFIED_LOCAL',
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
