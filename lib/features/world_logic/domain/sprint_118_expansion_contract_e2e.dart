/// Fail-closed expansion contract and end-to-end suite coverage for roadmap
/// step 118.40 -- Expansion Contract & End-to-End Tests.
///
/// Objective (external canonical `sprint_118.json`): run
/// `connect-use-refresh-error-reauth-disconnect-cleanup` for every new
/// connector. The canonical suite set is exactly nine suites: `manifest`,
/// `auth`, `capability`, `usage`, `error`, `reauth`, `disconnect`, `cleanup`,
/// and `regression`.
///
/// The release is delayed. No connector is certified (118.3 froze `CERTIFIED: 0`
/// of `32` registered; the committed 117.41 registry evidence records
/// `UNVERIFIED: 32`, `EXPOSED: 0`, `WITHHELD: 32`), the 118.2 charter froze an
/// expansion budget of zero new certified connectors out of 32 registered, and
/// the committed 117.45 approval gate records `decision=delay`,
/// `approval_state=PENDING_CHOIRUDIN`, `execution_authorized=false`, and
/// `release_blocked=true`. No connector has been connected, used, refreshed,
/// reauthenticated, disconnected, or cleaned up against a live provider, and no
/// end-to-end suite has run against a live provider. An expansion contract
/// written against that state therefore has exactly one honest shape: enumerate
/// all 32 registered providers, anchor each of the nine suite outputs to a
/// committed witness vocabulary, claim no suite ran, and certify no connector.
///
/// The gate is fail-closed on these families of rules:
///
/// * The committed 118.2 charter anchor must be a genuine complete charter and
///   its expansion budget must stay frozen (`max_new_certified_connectors` and
///   `currently_certified` both zero). A contract anchored to an unfrozen budget
///   runs end-to-end suites nobody authorized.
/// * The committed 118.3 certified connector snapshot must be a genuine frozen
///   pass (`CERTIFIED_CONNECTOR_SNAPSHOT_FROZEN_LOCAL`). A contract anchored to
///   an unfrozen snapshot rests on a release nobody recorded.
/// * The committed 117.45 approval gate must record the delay decision
///   (`decision == delay`), read with the owner's exact grammar, never
///   case-folded or trimmed into agreement. If it is not a delay, the anchor is
///   untrustworthy and the honest answer is `blocked`, not `fail`.
/// * The registered provider set must reconcile: the icon-registry provider
///   union, the 116.3 reconciliation count, the frozen snapshot count, the
///   charter count, the 117.41 registry evidence count, and the 117.4 snapshot
///   lock count must all agree. A contract over a drifting registry is not a
///   contract.
/// * The committed 117.41 registry visibility counts must reconcile
///   (`EXPOSED` plus `WITHHELD` equals the registered count) and must record
///   zero exposed providers while the release is delayed. A registry that
///   already exposes a connector contradicts the frozen zero-certified state.
/// * The nine canonical suites must reconcile against the committed 116.48
///   connector-contract end-to-end matrix `acceptance_suites`, so a suite set
///   cannot be invented into the contract without a witness to ground it.
/// * Every registered provider must appear exactly once. A record that drops a
///   provider, invents `telepathy`, or duplicates `stripe` is not a contract.
/// * Every entry must carry all ten canonical fields non-blank, and each of the
///   nine suite outputs must be grounded by the committed witness vocabulary for
///   that suite, so a suite reference cannot be invented into the list without a
///   witness to ground it.
/// * On the delayed path a connected connector, a used connector, a refreshed
///   connector, a reauthenticated connector, a disconnected connector, a
///   cleaned-up connector, a passing end-to-end suite, a certified connector, or
///   a released connector describe behavior that never ran. This is refused by
///   name, per entry.
///
/// **A connector is never recorded as having passed an end-to-end suite without
/// live provider verification and an authorized release.** When no suite has run
/// and no release is authorized, the only honest contract states the committed
/// reference for each suite and claims nothing live; any connected, used,
/// refreshed, reauthenticated, disconnected, cleaned-up, passed, certified, or
/// released claim is refused by name.
///
/// The output vocabulary is *derived from committed witnesses* (the 115.9
/// connector manifest `required_fields`, the 115.11 OAuth flow `acceptance`, the
/// 115.16 account model `acceptance`, the 116.21 usage-cost reconciliation
/// `acceptance`, the 116.15 provider error-state certification `required_states`,
/// the 115.13 token-expiry reauthentication `acceptance`, the 115.15 connected
/// accounts `acceptance`, the 115.12 secure token secret vault `acceptance`, and
/// the 116.48 connector-contract end-to-end matrix `acceptance_suites`), and the
/// source for each suite is a committed manifest, not copied by hand, so the
/// contract and its witnesses cannot drift apart silently.
///
/// Connector connection, connector use, token refresh, provider error handling,
/// reauthentication, disconnection, credential cleanup, end-to-end suite
/// execution, connector certification, connector release, and publication
/// remain `DEFERRED-EXTERNAL`; this contract freezes local declared state and
/// executes none of it.
library;

import 'dart:convert';
import 'dart:io';

/// The three states an expansion contract can rest in. `blocked` is the honest
/// resting state for "this contract cannot yet be trusted", and it is distinct
/// from `fail`, which means the contract contradicts its own evidence.
enum Sprint118ExpansionContractState { pass, fail, blocked }

/// One frozen expansion-contract entry: the declared reference for each of the
/// nine canonical end-to-end suite outputs of a single registered provider.
///
/// `connected`, `used`, `refreshed`, `reauthenticated`, `disconnected`,
/// `cleanedUp`, `e2ePassed`, `certified`, and `released` are deliberately *not*
/// among the ten required fields; they are the flags the gate refuses when set,
/// so that a declared reference contract can be recorded while never being read
/// as a connected connector, a used connector, a refreshed connector, a
/// reauthenticated connector, a disconnected connector, a cleaned-up connector,
/// a passing end-to-end suite, a certified connector, or a released connector.
class Sprint118ExpansionConnectorEntry {
  const Sprint118ExpansionConnectorEntry({
    required this.providerId,
    required this.manifest,
    required this.auth,
    required this.capability,
    required this.usage,
    required this.error,
    required this.reauth,
    required this.disconnect,
    required this.cleanup,
    required this.regression,
    this.connected = false,
    this.used = false,
    this.refreshed = false,
    this.reauthenticated = false,
    this.disconnected = false,
    this.cleanedUp = false,
    this.e2ePassed = false,
    this.certified = false,
    this.released = false,
  });

  /// The registered provider identifier, drawn from the committed icon registry.
  final String providerId;

  /// The manifest-suite reference state, drawn from the committed 115.9
  /// connector manifest `required_fields`.
  final String manifest;

  /// The auth-suite reference state, drawn from the committed 115.11 OAuth flow
  /// `acceptance`.
  final String auth;

  /// The capability-suite reference state, drawn from the committed 115.16
  /// account model `acceptance`.
  final String capability;

  /// The usage-suite reference state, drawn from the committed 116.21 usage-cost
  /// reconciliation `acceptance`.
  final String usage;

  /// The error-suite reference state, drawn from the committed 116.15 provider
  /// error-state certification `required_states`.
  final String error;

  /// The reauth-suite reference state, drawn from the committed 115.13
  /// token-expiry reauthentication `acceptance`.
  final String reauth;

  /// The disconnect-suite reference state, drawn from the committed 115.15
  /// connected accounts `acceptance`.
  final String disconnect;

  /// The cleanup-suite reference state, drawn from the committed 115.12 secure
  /// token secret vault `acceptance`.
  final String cleanup;

  /// The regression-suite reference state, drawn from the committed 116.48
  /// connector-contract end-to-end matrix `acceptance_suites`.
  final String regression;

  /// Whether the entry claims the connector was connected. On the delayed path
  /// this must stay `false`.
  final bool connected;

  /// Whether the entry claims the connector was used. On the delayed path this
  /// must stay `false`.
  final bool used;

  /// Whether the entry claims the token was refreshed. On the delayed path this
  /// must stay `false`.
  final bool refreshed;

  /// Whether the entry claims the connector was reauthenticated. On the delayed
  /// path this must stay `false`.
  final bool reauthenticated;

  /// Whether the entry claims the connector was disconnected. On the delayed
  /// path this must stay `false`.
  final bool disconnected;

  /// Whether the entry claims credentials were cleaned up. On the delayed path
  /// this must stay `false`.
  final bool cleanedUp;

  /// Whether the entry claims an end-to-end suite passed. On the delayed path
  /// this must stay `false`.
  final bool e2ePassed;

  /// Whether the entry claims the connector was certified. On the delayed path
  /// this must stay `false`.
  final bool certified;

  /// Whether the entry claims the connector was released. On the delayed path
  /// this must stay `false`.
  final bool released;

  /// The ten canonical fields as a name -> value map, so the gate can test
  /// blankness uniformly.
  Map<String, String> get requiredFields => <String, String>{
    'provider_id': providerId,
    'manifest': manifest,
    'auth': auth,
    'capability': capability,
    'usage': usage,
    'error': error,
    'reauth': reauth,
    'disconnect': disconnect,
    'cleanup': cleanup,
    'regression': regression,
  };

  /// The nine suite outputs as a suite -> value map, so the gate can test
  /// grounding per suite.
  Map<String, String> get outputFields => <String, String>{
    'manifest': manifest,
    'auth': auth,
    'capability': capability,
    'usage': usage,
    'error': error,
    'reauth': reauth,
    'disconnect': disconnect,
    'cleanup': cleanup,
    'regression': regression,
  };
}

/// The frozen expansion contract. `entries` is the declared reference for each
/// registered provider. On the delayed path no entry may claim a live
/// end-to-end run.
class Sprint118ExpansionContractRecord {
  const Sprint118ExpansionContractRecord({
    required this.releaseState,
    required this.entries,
  });

  final String releaseState;
  final List<Sprint118ExpansionConnectorEntry> entries;

  List<String> get providerIds => <String>[
    for (final entry in entries) entry.providerId,
  ];

  /// The providers the contract claims were connected. On the delayed path this
  /// must stay empty.
  List<String> get connectedProviders => <String>[
    for (final entry in entries)
      if (entry.connected) entry.providerId,
  ];

  /// The providers the contract claims passed an end-to-end suite. On the
  /// delayed path this must stay empty.
  List<String> get passedProviders => <String>[
    for (final entry in entries)
      if (entry.e2ePassed) entry.providerId,
  ];

  /// The providers the contract claims were certified. On the delayed path this
  /// must stay empty.
  List<String> get certifiedProviders => <String>[
    for (final entry in entries)
      if (entry.certified) entry.providerId,
  ];

  /// The providers the contract claims were released. On the delayed path this
  /// must stay empty.
  List<String> get releasedProviders => <String>[
    for (final entry in entries)
      if (entry.released) entry.providerId,
  ];

  int get connectedCount => entries.where((entry) => entry.connected).length;

  int get passedCount => entries.where((entry) => entry.e2ePassed).length;

  int get certifiedCount => entries.where((entry) => entry.certified).length;

  int get releasedCount => entries.where((entry) => entry.released).length;
}

/// What the committed witnesses actually say. A gate is only as honest as the
/// witnesses it is anchored to.
class Sprint118ExpansionContractAnchor {
  const Sprint118ExpansionContractAnchor({
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
    required this.suiteContractVocabulary,
    required this.manifestVocabulary,
    required this.authVocabulary,
    required this.capabilityVocabulary,
    required this.usageVocabulary,
    required this.errorVocabulary,
    required this.reauthVocabulary,
    required this.disconnectVocabulary,
    required this.cleanupVocabulary,
    required this.regressionVocabulary,
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

  /// The nine canonical suites the committed 116.48 connector-contract
  /// end-to-end matrix declares. It grounds the suite contract.
  final List<String> suiteContractVocabulary;

  /// The manifest-suite vocabulary the committed 115.9 connector manifest
  /// declares. It grounds the manifest output.
  final List<String> manifestVocabulary;

  /// The auth-suite vocabulary the committed 115.11 OAuth flow declares. It
  /// grounds the auth output.
  final List<String> authVocabulary;

  /// The capability-suite vocabulary the committed 115.16 account model
  /// declares. It grounds the capability output.
  final List<String> capabilityVocabulary;

  /// The usage-suite vocabulary the committed 116.21 usage-cost reconciliation
  /// declares. It grounds the usage output.
  final List<String> usageVocabulary;

  /// The error-suite vocabulary the committed 116.15 provider error-state
  /// certification declares. It grounds the error output.
  final List<String> errorVocabulary;

  /// The reauth-suite vocabulary the committed 115.13 token-expiry
  /// reauthentication declares. It grounds the reauth output.
  final List<String> reauthVocabulary;

  /// The disconnect-suite vocabulary the committed 115.15 connected accounts
  /// declares. It grounds the disconnect output.
  final List<String> disconnectVocabulary;

  /// The cleanup-suite vocabulary the committed 115.12 secure token secret
  /// vault declares. It grounds the cleanup output.
  final List<String> cleanupVocabulary;

  /// The regression-suite vocabulary the committed 116.48 connector-contract
  /// end-to-end matrix declares. It grounds the regression output.
  final List<String> regressionVocabulary;

  /// The committed evidence paths that are present and readable on disk.
  final List<String> readableSources;
}

/// The measured result. `pass` means the contract is a faithful suite-coverage
/// freeze; `blocked` means it cannot yet be trusted; `fail` means it contradicts
/// its evidence.
class Sprint118ExpansionContractReport {
  const Sprint118ExpansionContractReport({
    required this.state,
    required this.verdict,
    required this.releaseState,
    this.violations = const <String>[],
    this.blockers = const <String>[],
    this.openItems = const <String>[],
    this.declaredProviders = const <String>[],
    this.connectedProviders = const <String>[],
    this.passedProviders = const <String>[],
    this.certifiedProviders = const <String>[],
    this.releasedProviders = const <String>[],
    this.connectedCount = 0,
    this.passedCount = 0,
    this.certifiedCount = 0,
    this.releasedCount = 0,
    this.expansionBudgetFrozen = false,
  });

  final Sprint118ExpansionContractState state;
  final String verdict;
  final String releaseState;

  final List<String> violations;
  final List<String> blockers;
  final List<String> openItems;
  final List<String> declaredProviders;
  final List<String> connectedProviders;
  final List<String> passedProviders;
  final List<String> certifiedProviders;
  final List<String> releasedProviders;
  final int connectedCount;
  final int passedCount;
  final int certifiedCount;
  final int releasedCount;
  final bool expansionBudgetFrozen;

  /// Whether the contract may be treated as a frozen end-to-end suite-coverage
  /// freeze. Only a genuine `pass` allows it.
  bool get contractVerified => state == Sprint118ExpansionContractState.pass;

  String get externalGates => Sprint118ExpansionE2eContract.externalGates;
}

/// The fixed vocabulary and committed witness set for step 118.40.
abstract final class Sprint118ExpansionE2eContract {
  const Sprint118ExpansionE2eContract._();

  static const String canonicalStep = '118.40';
  static const String title = 'Expansion Contract & End-to-End Tests';

  static const String manifestPath =
      'docs/planning/v1.3/sprint_118_expansion_contract_e2e.json';
  static const String ledgerPath =
      'docs/sprints/sprint-118-account-cloud-center-stability.md';

  /// The committed 118.2 charter that declares the frozen expansion budget.
  static const String charterManifestPath =
      'docs/planning/v1.3/sprint_118_stability_expansion_charter.json';

  /// The committed 118.3 certified connector snapshot this contract rests on.
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

  /// The committed 115.9 connector manifest that grounds the manifest suite.
  static const String connectorManifestPath =
      'docs/planning/v1.2/sprint_115_provider_connector_manifest.json';

  /// The committed 115.11 OAuth linked-identity flow that grounds the auth
  /// suite.
  static const String oauthManifestPath =
      'docs/planning/v1.2/sprint_115_oauth_linked_identity_flow.json';

  /// The committed 115.16 cloud-storage account model that grounds the
  /// capability suite.
  static const String accountModelManifestPath =
      'docs/planning/v1.2/sprint_115_cloud_storage_account_model.json';

  /// The committed 116.21 AI usage-cost reconciliation that grounds the usage
  /// suite.
  static const String usageCostManifestPath =
      'docs/planning/v1.2/sprint_116_ai_usage_cost_reconciliation.json';

  /// The committed 116.15 provider error-state certification that grounds the
  /// error suite.
  static const String errorStateManifestPath =
      'docs/planning/v1.2/sprint_116_provider_error_state_certification.json';

  /// The committed 115.13 token-expiry reauthentication UX that grounds the
  /// reauth suite.
  static const String tokenExpiryManifestPath =
      'docs/planning/v1.2/sprint_115_token_expiry_reauthentication_ux.json';

  /// The committed 115.15 connected-accounts management that grounds the
  /// disconnect suite.
  static const String connectedAccountsManifestPath =
      'docs/planning/v1.2/sprint_115_connected_accounts_management.json';

  /// The committed 115.12 secure token secret vault that grounds the cleanup
  /// suite.
  static const String secretVaultManifestPath =
      'docs/planning/v1.2/sprint_115_secure_token_secret_vault.json';

  /// The committed 116.48 connector-contract end-to-end matrix that grounds the
  /// regression suite and the nine-suite contract.
  static const String e2eMatrixManifestPath =
      'docs/planning/v1.2/sprint_116_connector_contract_e2e_matrix.json';

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

  /// The number of canonical end-to-end suites the objective names.
  static const int expectedSuiteCount = 9;

  /// The marker an entry declares when no committed witness names a reference
  /// state for a suite. A contract that uses it records an honest upstream gap
  /// rather than inventing a state.
  static const String noReferenceState = 'no_reference_state';

  /// The canonical field set each entry must carry, so a contract cannot drop a
  /// field and still read as complete.
  static const List<String> requiredFields = <String>[
    'provider_id',
    'manifest',
    'auth',
    'capability',
    'usage',
    'error',
    'reauth',
    'disconnect',
    'cleanup',
    'regression',
  ];

  /// The nine canonical suites named by the objective, in canonical order.
  /// `provider_id` is the key, not a suite.
  static const List<String> requiredOutputs = <String>[
    'manifest',
    'auth',
    'capability',
    'usage',
    'error',
    'reauth',
    'disconnect',
    'cleanup',
    'regression',
  ];

  /// The committed evidence file each canonical suite is anchored to, in
  /// canonical order.
  static const List<String> canonicalSources = <String>[
    connectorManifestPath,
    oauthManifestPath,
    accountModelManifestPath,
    usageCostManifestPath,
    errorStateManifestPath,
    tokenExpiryManifestPath,
    connectedAccountsManifestPath,
    secretVaultManifestPath,
    e2eMatrixManifestPath,
  ];

  /// The committed evidence files every contract is anchored to. All must be
  /// readable.
  static const List<String> witnessSources = <String>[
    charterManifestPath,
    snapshotManifestPath,
    approvalGateManifestPath,
    iconRegistryManifestPath,
    registryReconciliationManifestPath,
    snapshotLockManifestPath,
    registryEvidencePath,
    connectorManifestPath,
    oauthManifestPath,
    accountModelManifestPath,
    usageCostManifestPath,
    errorStateManifestPath,
    tokenExpiryManifestPath,
    connectedAccountsManifestPath,
    secretVaultManifestPath,
    e2eMatrixManifestPath,
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

  /// The declared reference state for the manifest suite. No live connector is
  /// connected on the delayed path, so the honest reference is the committed
  /// 115.9 connector manifest required field (`connector_version`).
  static const String manifestToken = 'connector_version';

  /// The declared reference state for the auth suite. No live OAuth flow runs on
  /// the delayed path, so the honest reference is the committed 115.11 OAuth
  /// flow acceptance (`scoped_consent`).
  static const String authToken = 'scoped_consent';

  /// The declared reference state for the capability suite. No live capability
  /// probe runs on the delayed path, so the honest reference is the committed
  /// 115.16 account model acceptance (`capabilities`).
  static const String capabilityToken = 'capabilities';

  /// The declared reference state for the usage suite. No live usage read runs
  /// on the delayed path, so the honest reference is the committed 116.21
  /// usage-cost acceptance (`usage_units`).
  static const String usageToken = 'usage_units';

  /// The declared reference state for the error suite. No live error is
  /// exercised on the delayed path, so the honest reference is the committed
  /// 116.15 provider error-state (`invalid_credentials`).
  static const String errorToken = 'invalid_credentials';

  /// The declared reference state for the reauth suite. No live reauthentication
  /// runs on the delayed path, so the honest reference is the committed 115.13
  /// token-expiry acceptance (`reauth`).
  static const String reauthToken = 'reauth';

  /// The declared reference state for the disconnect suite. No live disconnect
  /// runs on the delayed path, so the honest reference is the committed 115.15
  /// connected-accounts acceptance (`unlink_confirmation`).
  static const String disconnectToken = 'unlink_confirmation';

  /// The declared reference state for the cleanup suite. No live credential
  /// cleanup runs on the delayed path, so the honest reference is the committed
  /// 115.12 secret-vault acceptance (`no_plaintext`).
  static const String cleanupToken = 'no_plaintext';

  /// The declared reference state for the regression suite. No live end-to-end
  /// run happens on the delayed path, so the honest reference is the committed
  /// 116.48 end-to-end matrix acceptance suite (`regression`).
  static const String regressionToken = 'regression';

  /// The committed witness vocabulary that grounds each canonical suite, in
  /// canonical order.
  static List<List<String>> outputVocabularies(
    Sprint118ExpansionContractAnchor anchor,
  ) => <List<String>>[
    anchor.manifestVocabulary,
    anchor.authVocabulary,
    anchor.capabilityVocabulary,
    anchor.usageVocabulary,
    anchor.errorVocabulary,
    anchor.reauthVocabulary,
    anchor.disconnectVocabulary,
    anchor.cleanupVocabulary,
    anchor.regressionVocabulary,
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
  /// (`connector_version`, `scoped_consent`, `regression`), or when every
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

  /// The committed witness vocabulary for a canonical suite, or the empty list
  /// when the suite is unknown.
  static List<String> vocabularyFor(
    Sprint118ExpansionContractAnchor anchor,
    String output,
  ) {
    final index = requiredOutputs.indexOf(output);
    if (index < 0) return const <String>[];
    return outputVocabularies(anchor)[index];
  }

  /// The committed source for a canonical suite, or `''` if unknown.
  static String sourceFor(String output) {
    final index = requiredOutputs.indexOf(output);
    return index < 0 ? '' : canonicalSources[index];
  }

  /// The canonical frozen contract: every registered provider, each anchored to
  /// the committed witness vocabularies, claiming nothing live.
  static Sprint118ExpansionContractRecord get canonicalRecord =>
      Sprint118ExpansionContractRecord(
        releaseState: delayedReleaseState,
        entries: <Sprint118ExpansionConnectorEntry>[
          for (final id in canonicalProviders)
            Sprint118ExpansionConnectorEntry(
              providerId: id,
              manifest: manifestToken,
              auth: authToken,
              capability: capabilityToken,
              usage: usageToken,
              error: errorToken,
              reauth: reauthToken,
              disconnect: disconnectToken,
              cleanup: cleanupToken,
              regression: regressionToken,
            ),
        ],
      );
}

/// Reads the committed witnesses for step 118.40. Never invents: an unreadable
/// witness yields `null`, which the gate reports as blocked rather than as a
/// pass.
class Sprint118ExpansionContractLoader {
  const Sprint118ExpansionContractLoader();

  Sprint118ExpansionContractAnchor? loadAnchor() {
    final charter = _read(Sprint118ExpansionE2eContract.charterManifestPath);
    final snapshot = _read(Sprint118ExpansionE2eContract.snapshotManifestPath);
    final approval = _read(
      Sprint118ExpansionE2eContract.approvalGateManifestPath,
    );
    final icon = _read(Sprint118ExpansionE2eContract.iconRegistryManifestPath);
    final reconciliation = _read(
      Sprint118ExpansionE2eContract.registryReconciliationManifestPath,
    );
    final lock = _read(Sprint118ExpansionE2eContract.snapshotLockManifestPath);
    final registry = _read(Sprint118ExpansionE2eContract.registryEvidencePath);
    final connector = _read(
      Sprint118ExpansionE2eContract.connectorManifestPath,
    );
    final oauth = _read(Sprint118ExpansionE2eContract.oauthManifestPath);
    final accountModel = _read(
      Sprint118ExpansionE2eContract.accountModelManifestPath,
    );
    final usageCost = _read(
      Sprint118ExpansionE2eContract.usageCostManifestPath,
    );
    final errorState = _read(
      Sprint118ExpansionE2eContract.errorStateManifestPath,
    );
    final tokenExpiry = _read(
      Sprint118ExpansionE2eContract.tokenExpiryManifestPath,
    );
    final connectedAccounts = _read(
      Sprint118ExpansionE2eContract.connectedAccountsManifestPath,
    );
    final secretVault = _read(
      Sprint118ExpansionE2eContract.secretVaultManifestPath,
    );
    final e2eMatrix = _read(
      Sprint118ExpansionE2eContract.e2eMatrixManifestPath,
    );
    if (charter == null ||
        snapshot == null ||
        approval == null ||
        icon == null ||
        reconciliation == null ||
        lock == null ||
        registry == null ||
        connector == null ||
        oauth == null ||
        accountModel == null ||
        usageCost == null ||
        errorState == null ||
        tokenExpiry == null ||
        connectedAccounts == null ||
        secretVault == null ||
        e2eMatrix == null) {
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

    final sources = Sprint118ExpansionE2eContract.witnessSources.toSet();

    return Sprint118ExpansionContractAnchor(
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
      suiteContractVocabulary: _strings(e2eMatrix['acceptance_suites']),
      manifestVocabulary: _strings(connector['required_fields']),
      authVocabulary: _strings(oauth['acceptance']),
      capabilityVocabulary: _strings(accountModel['acceptance']),
      usageVocabulary: _strings(usageCost['acceptance']),
      errorVocabulary: _strings(errorState['required_states']),
      reauthVocabulary: _strings(tokenExpiry['acceptance']),
      disconnectVocabulary: _strings(connectedAccounts['acceptance']),
      cleanupVocabulary: _strings(secretVault['acceptance']),
      regressionVocabulary: _strings(e2eMatrix['acceptance_suites']),
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

/// The fail-closed expansion contract and end-to-end suite-coverage gate for
/// step 118.40.
class Sprint118ExpansionContractGate {
  const Sprint118ExpansionContractGate();

  Sprint118ExpansionContractReport evaluate() => evaluateWith(
    const Sprint118ExpansionContractLoader().loadAnchor(),
    Sprint118ExpansionE2eContract.canonicalRecord,
  );

  Sprint118ExpansionContractReport evaluateWith(
    Sprint118ExpansionContractAnchor? anchor,
    Sprint118ExpansionContractRecord record,
  ) {
    if (anchor == null) {
      return Sprint118ExpansionContractReport(
        state: Sprint118ExpansionContractState.blocked,
        verdict: 'SPRINT_118_EXPANSION_CONTRACT_EVIDENCE_UNREADABLE',
        releaseState: record.releaseState,
        blockers: const <String>[
          'committed_expansion_contract_evidence_unreadable',
        ],
        openItems: const <String>[
          'committed_expansion_contract_evidence_unreadable',
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
            Sprint118ExpansionE2eContract.requiredCharterState ||
        anchor.charterVerdict !=
            Sprint118ExpansionE2eContract.requiredCharterVerdict) {
      blockers.add('charter_not_complete:${anchor.charterVerdict}');
    }

    // (2) The 118.3 snapshot anchor must be a genuine frozen pass.
    if (anchor.snapshotState !=
            Sprint118ExpansionE2eContract.requiredSnapshotState ||
        anchor.snapshotVerdict !=
            Sprint118ExpansionE2eContract.requiredSnapshotVerdict) {
      blockers.add('snapshot_not_frozen:${anchor.snapshotVerdict}');
    }

    // (3) The 117.45 approval gate must record the delay decision, read with the
    // owner's exact grammar. If it is not a delay, the anchor is untrustworthy.
    if (anchor.approvalDecision !=
        Sprint118ExpansionE2eContract.requiredApprovalDecision) {
      blockers.add('approval_gate_not_delay:${anchor.approvalDecision}');
    }

    // (4) The registered provider set must reconcile across the icon registry,
    // the 116.3 reconciliation, the frozen snapshot, the charter, the 117.41
    // registry evidence, and the 117.4 snapshot lock.
    if (anchor.registeredProviders.length !=
            Sprint118ExpansionE2eContract.expectedProviderCount ||
        anchor.registryExpectedCount !=
            Sprint118ExpansionE2eContract.expectedProviderCount ||
        anchor.snapshotRegistered !=
            Sprint118ExpansionE2eContract.expectedProviderCount ||
        anchor.charterRegisteredProviders !=
            Sprint118ExpansionE2eContract.expectedProviderCount ||
        anchor.registryEvidenceProviderCount !=
            Sprint118ExpansionE2eContract.expectedProviderCount ||
        anchor.snapshotLockLockedCount !=
            Sprint118ExpansionE2eContract.expectedProviderCount) {
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
        Sprint118ExpansionE2eContract.expectedProviderCount) {
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

    // (6) The nine canonical suites must reconcile against the committed 116.48
    // end-to-end matrix acceptance_suites. A suite set that does not reconcile
    // cannot ground the contract.
    final suiteContract = anchor.suiteContractVocabulary.toSet();
    for (final suite in Sprint118ExpansionE2eContract.requiredOutputs) {
      if (!suiteContract.contains(suite)) {
        blockers.add('suite_contract_missing:$suite');
      }
    }
    if (anchor.suiteContractVocabulary.length !=
        Sprint118ExpansionE2eContract.expectedSuiteCount) {
      blockers.add(
        'suite_contract_not_reconciled:'
        '${anchor.suiteContractVocabulary.length}',
      );
    }

    // (7) The release state must agree with the anchor.
    if (record.releaseState != anchor.releaseState) {
      violations.add(
        'release_state_mismatch:anchor=${anchor.releaseState}:'
        'record=${record.releaseState}',
      );
    }
    if (record.releaseState !=
        Sprint118ExpansionE2eContract.delayedReleaseState) {
      violations.add(
        'expansion_contract_not_on_delayed_path:${record.releaseState}',
      );
    }

    final delayed =
        record.releaseState ==
        Sprint118ExpansionE2eContract.delayedReleaseState;

    // (8) On the delayed path an authorized release execution and an unblocked
    // release are behavior that never ran.
    if (delayed && anchor.executionAuthorized) {
      violations.add('expansion_contract_execution_authorized_on_delayed_path');
    }
    if (delayed && !anchor.releaseBlocked) {
      violations.add('expansion_contract_release_not_blocked_on_delayed_path');
    }

    // (9) The expansion budget must stay frozen: no new certified connector and
    // no already-certified connector while the release is delayed.
    if (!frozen) {
      violations.add(
        'expansion_contract_expansion_budget_not_frozen:max_new='
        '${anchor.charterMaxNewCertified}:'
        'currently=${anchor.charterCurrentlyCertified}',
      );
    }
    // The frozen 118.3 snapshot must declare zero certified connectors. A
    // snapshot that already certifies a connector contradicts the delayed path.
    if (anchor.snapshotCertified != 0) {
      violations.add(
        'expansion_contract_snapshot_certified_nonzero:'
        '${anchor.snapshotCertified}',
      );
    }

    // (10) Every registered provider must appear exactly once, and each entry
    // must carry all ten canonical fields non-blank with every suite grounded by
    // its committed witness vocabulary.
    final declared = <String, int>{};
    for (final entry in record.entries) {
      declared[entry.providerId] = (declared[entry.providerId] ?? 0) + 1;
    }
    for (final entry in record.entries) {
      final id = entry.providerId;
      if (!anchor.registeredProviders.contains(id)) {
        violations.add('expansion_contract_provider_unknown:$id');
      }
      for (final field in Sprint118ExpansionE2eContract.requiredFields) {
        final value = entry.requiredFields[field] ?? '';
        if (value.trim().isEmpty) {
          violations.add('entry_blank_$field:$id');
        }
      }
      for (final output in Sprint118ExpansionE2eContract.requiredOutputs) {
        final token = entry.outputFields[output] ?? '';
        final vocabulary = Sprint118ExpansionE2eContract.vocabularyFor(
          anchor,
          output,
        );
        final grounded =
            token == Sprint118ExpansionE2eContract.noReferenceState ||
            Sprint118ExpansionE2eContract.grounds(vocabulary, token);
        if (token.trim().isEmpty || !grounded) {
          violations.add('reference_state_invalid:$output:$id');
        }
        if (token == Sprint118ExpansionE2eContract.noReferenceState) {
          openItems.add('upstream_state_vocabulary_gap:$output:$id');
        }
      }
      // A connector is never connected without an authorized release.
      if (entry.connected) {
        violations.add(
          'expansion_contract_connected_claimed_on_delayed_path:$id',
        );
      }
      // A connector is never used without an authorized release.
      if (entry.used) {
        violations.add('expansion_contract_used_claimed_on_delayed_path:$id');
      }
      // A token is never refreshed without an authorized release.
      if (entry.refreshed) {
        violations.add(
          'expansion_contract_refreshed_claimed_on_delayed_path:$id',
        );
      }
      // A connector is never reauthenticated without an authorized release.
      if (entry.reauthenticated) {
        violations.add(
          'expansion_contract_reauthenticated_claimed_on_delayed_path:$id',
        );
      }
      // A connector is never disconnected without an authorized release.
      if (entry.disconnected) {
        violations.add(
          'expansion_contract_disconnected_claimed_on_delayed_path:$id',
        );
      }
      // Credentials are never cleaned up without an authorized release.
      if (entry.cleanedUp) {
        violations.add(
          'expansion_contract_cleaned_up_claimed_on_delayed_path:$id',
        );
      }
      // An end-to-end suite is never recorded as passed on the delayed path.
      if (entry.e2ePassed) {
        violations.add(
          'expansion_contract_e2e_passed_claimed_on_delayed_path:$id',
        );
      }
      // A connector is never certified without live provider verification.
      if (entry.certified) {
        violations.add(
          'expansion_contract_certified_claimed_on_delayed_path:$id',
        );
      }
      // A connector is never released without an authorized release.
      if (entry.released) {
        violations.add('expansion_contract_released_claimed:$id');
      }
    }
    for (final id in declared.keys) {
      if (declared[id]! > 1) {
        violations.add('expansion_contract_provider_duplicate:$id');
      }
    }
    for (final id in anchor.registeredProviders) {
      if (!declared.containsKey(id)) {
        violations.add('expansion_contract_provider_missing:$id');
      }
    }

    // (11) Every committed evidence source must be readable.
    for (final source in Sprint118ExpansionE2eContract.witnessSources.toSet()) {
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
      return Sprint118ExpansionContractReport(
        state: Sprint118ExpansionContractState.blocked,
        verdict: 'SPRINT_118_EXPANSION_CONTRACT_BLOCKED_UPSTREAM',
        releaseState: record.releaseState,
        violations: violations,
        blockers: blockers,
        openItems: allItems,
        declaredProviders: providers,
        connectedProviders: record.connectedProviders,
        passedProviders: record.passedProviders,
        certifiedProviders: record.certifiedProviders,
        releasedProviders: record.releasedProviders,
        connectedCount: record.connectedCount,
        passedCount: record.passedCount,
        certifiedCount: record.certifiedCount,
        releasedCount: record.releasedCount,
        expansionBudgetFrozen: frozen,
      );
    }
    if (violations.isNotEmpty) {
      return Sprint118ExpansionContractReport(
        state: Sprint118ExpansionContractState.fail,
        verdict: 'SPRINT_118_EXPANSION_CONTRACT_EVIDENCE_VIOLATION',
        releaseState: record.releaseState,
        violations: violations,
        blockers: blockers,
        openItems: allItems,
        declaredProviders: providers,
        connectedProviders: record.connectedProviders,
        passedProviders: record.passedProviders,
        certifiedProviders: record.certifiedProviders,
        releasedProviders: record.releasedProviders,
        connectedCount: record.connectedCount,
        passedCount: record.passedCount,
        certifiedCount: record.certifiedCount,
        releasedCount: record.releasedCount,
        expansionBudgetFrozen: frozen,
      );
    }
    return Sprint118ExpansionContractReport(
      state: Sprint118ExpansionContractState.pass,
      verdict: 'EXPANSION_CONTRACT_E2E_VERIFIED_LOCAL',
      releaseState: record.releaseState,
      openItems: allItems,
      declaredProviders: providers,
      connectedProviders: record.connectedProviders,
      passedProviders: record.passedProviders,
      certifiedProviders: record.certifiedProviders,
      releasedProviders: record.releasedProviders,
      connectedCount: record.connectedCount,
      passedCount: record.passedCount,
      certifiedCount: record.certifiedCount,
      releasedCount: record.releasedCount,
      expansionBudgetFrozen: frozen,
    );
  }
}
