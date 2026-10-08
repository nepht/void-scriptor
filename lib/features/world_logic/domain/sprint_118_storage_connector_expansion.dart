/// Fail-closed storage connector expansion for roadmap step 118.34 -- Storage
/// Connector Expansion.
///
/// Objective (external canonical `sprint_118.json`): certify the next storage
/// connector one at a time with quota, delta, conflict, backup, and restore
/// evidence. The canonical requirement set is exactly seven items:
/// `selected_provider`, `storage_contract`, `quota`, `delta`, `conflict`,
/// `backup`, and `restore`.
///
/// The release is delayed. No connector is certified (118.3 froze `CERTIFIED: 0`
/// of `32` registered), the 118.2 charter froze an expansion budget of zero new
/// certified connectors out of 32 registered, the committed 117.45 approval gate
/// records `decision=delay`, `approval_state=PENDING_CHOIRUDIN`,
/// `execution_authorized=false`, and `release_blocked=true`, and the committed
/// 117 cloud storage quota validation records `provider_api_values` as the sole
/// *unmet* acceptance (`status=pass`,
/// `verdict=CLOUD_STORAGE_QUOTA_VALIDATED_LOCAL`) with no live provider quota
/// adapter. No storage connector has been selected, no storage contract has been
/// verified live, no quota has been read from a live provider, no delta sync has
/// run against a live provider, no conflict has been resolved against a live
/// provider, no backup has been verified against a live destination, and no
/// restore has been verified. A storage connector expansion review written
/// against that state therefore has exactly one honest shape: enumerate all 32
/// registered providers, anchor each of the seven requirements to a committed
/// witness vocabulary, and claim no live certification.
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
/// * The committed 117 cloud storage quota validation must be a genuine pass
///   (`CLOUD_STORAGE_QUOTA_VALIDATED_LOCAL`). A certification review anchored to
///   an unvalidated storage quota surface certifies a connector whose quota
///   contract nobody proved.
/// * The registered provider set must reconcile: the icon-registry provider
///   union, the 116.3 reconciliation count, the frozen snapshot count, and the
///   charter count must agree. A certification review over a drifting registry
///   is not a certification review.
/// * Every registered provider must appear exactly once. A record that drops a
///   provider, invents `telepathy`, or duplicates `google_drive` is not a
///   certification review.
/// * Every entry must carry all eight canonical fields non-blank, and each of
///   the seven requirements must be grounded by the committed witness vocabulary
///   for that requirement, so a certification value cannot be invented into the
///   list without a witness to ground it.
/// * On the delayed path a certified connector, a selected provider, a
///   live-verified quota, a live-verified delta sync, a resolved conflict, a
///   verified backup, a verified restore, or a released provider describe
///   behavior that never ran. This is refused by name, per entry.
///
/// **A provider is never recorded as a certified storage connector without live
/// provider verification and an authorized release.** When no storage connector
/// was selected and no release is authorized, the only honest certification
/// review records the committed storage-connector reference for each requirement
/// and claims nothing live; any certified, selected, quota-verified,
/// delta-verified, conflict-resolved, backup-verified, restore-verified, or
/// released claim is refused by name.
///
/// The output vocabulary is *derived from committed witnesses* (the 117 cloud
/// storage quota validation acceptance set, the 115.16 cloud storage account
/// model acceptance set, the 115.17 provider quota adapters acceptance set, the
/// 115.21 cloud transfer & sync controls acceptance set, the 115.23 sync
/// conflict center acceptance set, and the 115.22 backup policies &
/// destinations acceptance set), and the source for each requirement is a
/// committed manifest, not copied by hand, so the record and its witnesses
/// cannot drift apart silently.
///
/// Storage connector selection, live storage-contract verification, live quota
/// reads, live delta sync, live conflict resolution, live backup verification,
/// live restore verification, credential access, connector certification,
/// provider exposure, and publication remain `DEFERRED-EXTERNAL`; this review
/// freezes local declared state and executes none of it.
library;

import 'dart:convert';
import 'dart:io';

/// The three states a storage connector expansion review can rest in.
/// `blocked` is the honest resting state for "this review cannot yet be
/// trusted", and it is distinct from `fail`, which means the record contradicts
/// its own evidence.
enum Sprint118StorageConnectorState { pass, fail, blocked }

/// One frozen storage connector expansion entry: the declared reference for each
/// of the seven canonical requirements of a single registered provider.
///
/// `certified`, `selected`, `quotaVerified`, `deltaVerified`,
/// `conflictResolved`, `backupVerified`, `restoreVerified`, and `released` are
/// deliberately *not* among the eight required fields; they are the flags the
/// gate refuses when set, so that a declared reference certification can be
/// recorded while never being read as a certified connector, a selected
/// provider, a live-verified quota, a live-verified delta sync, a resolved
/// conflict, a verified backup, a verified restore, or a released provider.
class Sprint118StorageConnectorEntry {
  const Sprint118StorageConnectorEntry({
    required this.providerId,
    required this.selectedProvider,
    required this.storageContract,
    required this.quota,
    required this.delta,
    required this.conflict,
    required this.backup,
    required this.restore,
    this.certified = false,
    this.selected = false,
    this.quotaVerified = false,
    this.deltaVerified = false,
    this.conflictResolved = false,
    this.backupVerified = false,
    this.restoreVerified = false,
    this.released = false,
  });

  /// The registered provider identifier, drawn from the committed icon registry.
  final String providerId;

  /// The selected-provider reference state, drawn from the committed 117 cloud
  /// storage quota validation acceptance set.
  final String selectedProvider;

  /// The storage-contract reference state, drawn from the committed 115.16 cloud
  /// storage account model acceptance set.
  final String storageContract;

  /// The quota reference state, drawn from the committed 115.17 provider quota
  /// adapters acceptance set.
  final String quota;

  /// The delta reference state, drawn from the committed 115.21 cloud transfer &
  /// sync controls acceptance set.
  final String delta;

  /// The conflict reference state, drawn from the committed 115.23 sync conflict
  /// center acceptance set.
  final String conflict;

  /// The backup reference state, drawn from the committed 115.22 backup policies
  /// & destinations acceptance set.
  final String backup;

  /// The restore reference state, drawn from the committed 115.22 backup
  /// policies & destinations acceptance set.
  final String restore;

  /// Whether the entry claims the connector was certified. On the delayed path
  /// this must stay `false`.
  final bool certified;

  /// Whether the entry claims the provider was selected. On the delayed path
  /// this must stay `false`.
  final bool selected;

  /// Whether the entry claims a live quota was verified. On the delayed path
  /// this must stay `false`.
  final bool quotaVerified;

  /// Whether the entry claims a live delta sync was verified. On the delayed
  /// path this must stay `false`.
  final bool deltaVerified;

  /// Whether the entry claims a conflict was resolved. On the delayed path this
  /// must stay `false`.
  final bool conflictResolved;

  /// Whether the entry claims a backup was verified live. On the delayed path
  /// this must stay `false`.
  final bool backupVerified;

  /// Whether the entry claims a restore was verified live. On the delayed path
  /// this must stay `false`.
  final bool restoreVerified;

  /// Whether the entry claims a released provider. On the delayed path this must
  /// stay `false`.
  final bool released;

  /// The eight canonical fields as a name -> value map, so the gate can test
  /// blankness uniformly.
  Map<String, String> get requiredFields => <String, String>{
    'provider_id': providerId,
    'selected_provider': selectedProvider,
    'storage_contract': storageContract,
    'quota': quota,
    'delta': delta,
    'conflict': conflict,
    'backup': backup,
    'restore': restore,
  };

  /// The seven requirements as a requirement -> value map, so the gate can test
  /// grounding per requirement.
  Map<String, String> get outputFields => <String, String>{
    'selected_provider': selectedProvider,
    'storage_contract': storageContract,
    'quota': quota,
    'delta': delta,
    'conflict': conflict,
    'backup': backup,
    'restore': restore,
  };
}

/// The frozen storage connector expansion review. `entries` is the declared
/// reference for each registered provider. On the delayed path no entry may
/// claim a live certification.
class Sprint118StorageConnectorRecord {
  const Sprint118StorageConnectorRecord({
    required this.releaseState,
    required this.entries,
  });

  final String releaseState;
  final List<Sprint118StorageConnectorEntry> entries;

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
class Sprint118StorageConnectorAnchor {
  const Sprint118StorageConnectorAnchor({
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
    required this.storageQuotaStatus,
    required this.storageQuotaVerdict,
    required this.registeredProviders,
    required this.selectedProviderVocabulary,
    required this.storageContractVocabulary,
    required this.quotaVocabulary,
    required this.deltaVocabulary,
    required this.conflictVocabulary,
    required this.backupVocabulary,
    required this.restoreVocabulary,
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

  /// The status the committed 117 cloud storage quota validation declares.
  final String storageQuotaStatus;

  /// The verdict the committed 117 cloud storage quota validation declares.
  final String storageQuotaVerdict;

  /// The registered provider ids, unioned from the committed 115.8 icon registry.
  final List<String> registeredProviders;

  /// The selected-provider vocabulary the committed 117 cloud storage quota
  /// validation declares. It grounds the selected-provider requirement.
  final List<String> selectedProviderVocabulary;

  /// The storage-contract vocabulary the committed 115.16 cloud storage account
  /// model declares. It grounds the storage-contract requirement.
  final List<String> storageContractVocabulary;

  /// The quota vocabulary the committed 115.17 provider quota adapters declares.
  /// It grounds the quota requirement.
  final List<String> quotaVocabulary;

  /// The delta vocabulary the committed 115.21 cloud transfer & sync controls
  /// declares. It grounds the delta requirement.
  final List<String> deltaVocabulary;

  /// The conflict vocabulary the committed 115.23 sync conflict center declares.
  /// It grounds the conflict requirement.
  final List<String> conflictVocabulary;

  /// The backup vocabulary the committed 115.22 backup policies & destinations
  /// declares. It grounds the backup requirement.
  final List<String> backupVocabulary;

  /// The restore vocabulary the committed 115.22 backup policies & destinations
  /// declares. It grounds the restore requirement.
  final List<String> restoreVocabulary;

  /// The committed evidence paths that are present and readable on disk.
  final List<String> readableSources;
}

/// The measured result. `pass` means the review is a faithful freeze; `blocked`
/// means it cannot yet be trusted; `fail` means it contradicts its evidence.
class Sprint118StorageConnectorReport {
  const Sprint118StorageConnectorReport({
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

  final Sprint118StorageConnectorState state;
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
      state == Sprint118StorageConnectorState.pass;

  String get externalGates => Sprint118StorageConnectorContract.externalGates;
}

/// The fixed vocabulary and committed witness set for step 118.34.
abstract final class Sprint118StorageConnectorContract {
  const Sprint118StorageConnectorContract._();

  static const String canonicalStep = '118.34';
  static const String title = 'Storage Connector Expansion';

  static const String manifestPath =
      'docs/planning/v1.3/sprint_118_storage_connector_expansion.json';
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

  /// The committed 117 cloud storage quota validation that records
  /// `provider_api_values` as the sole unmet acceptance and grounds the
  /// selected-provider requirement.
  static const String storageQuotaValidationManifestPath =
      'docs/planning/v1.3/sprint_117_cloud_storage_quota_validation.json';

  /// The committed 115.16 cloud storage account model that grounds the
  /// storage-contract requirement.
  static const String cloudStorageAccountModelManifestPath =
      'docs/planning/v1.2/sprint_115_cloud_storage_account_model.json';

  /// The committed 115.17 provider quota adapters that grounds the quota
  /// requirement.
  static const String providerQuotaAdaptersManifestPath =
      'docs/planning/v1.2/sprint_115_provider_quota_adapters.json';

  /// The committed 115.21 cloud transfer & sync controls that grounds the delta
  /// requirement.
  static const String cloudTransferSyncControlsManifestPath =
      'docs/planning/v1.2/sprint_115_cloud_transfer_sync_controls.json';

  /// The committed 115.23 sync conflict center that grounds the conflict
  /// requirement.
  static const String syncConflictCenterManifestPath =
      'docs/planning/v1.2/sprint_115_sync_conflict_center.json';

  /// The committed 115.22 backup policies & destinations that grounds the backup
  /// and restore requirements.
  static const String backupPoliciesDestinationsManifestPath =
      'docs/planning/v1.2/sprint_115_backup_policies_destinations.json';

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

  /// The status and verdict the committed 117 cloud storage quota validation
  /// must carry to be a genuine pass.
  static const String requiredStorageQuotaStatus = 'pass';
  static const String requiredStorageQuotaVerdict =
      'CLOUD_STORAGE_QUOTA_VALIDATED_LOCAL';

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
    'storage_contract',
    'quota',
    'delta',
    'conflict',
    'backup',
    'restore',
  ];

  /// The seven canonical requirements named by the objective, in canonical
  /// order. `provider_id` is the key, not a requirement.
  static const List<String> requiredOutputs = <String>[
    'selected_provider',
    'storage_contract',
    'quota',
    'delta',
    'conflict',
    'backup',
    'restore',
  ];

  /// The committed evidence file each canonical requirement is anchored to, in
  /// canonical order.
  static const List<String> canonicalSources = <String>[
    storageQuotaValidationManifestPath,
    cloudStorageAccountModelManifestPath,
    providerQuotaAdaptersManifestPath,
    cloudTransferSyncControlsManifestPath,
    syncConflictCenterManifestPath,
    backupPoliciesDestinationsManifestPath,
    backupPoliciesDestinationsManifestPath,
  ];

  /// The committed evidence files every review is anchored to. All must be
  /// readable.
  static const List<String> witnessSources = <String>[
    charterManifestPath,
    snapshotManifestPath,
    approvalGateManifestPath,
    iconRegistryManifestPath,
    registryReconciliationManifestPath,
    storageQuotaValidationManifestPath,
    cloudStorageAccountModelManifestPath,
    providerQuotaAdaptersManifestPath,
    cloudTransferSyncControlsManifestPath,
    syncConflictCenterManifestPath,
    backupPoliciesDestinationsManifestPath,
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
  /// shipped storage connector quota adapter reads live provider values on the
  /// delayed path, so the honest reference is the committed 117 cloud storage
  /// quota acceptance that remains unmet (`provider_api_values`).
  static const String selectedProviderToken = 'provider_api_values';

  /// The declared reference state for the storage-contract requirement. The
  /// storage contract is declared and unverified, so the honest reference is the
  /// committed 115.16 cloud storage account model acceptance (`capabilities`).
  static const String storageContractToken = 'capabilities';

  /// The declared reference state for the quota requirement. No quota is read
  /// live on the delayed path, so the honest reference is the committed 115.17
  /// provider quota adapter acceptance (`raw_bytes`).
  static const String quotaToken = 'raw_bytes';

  /// The declared reference state for the delta requirement. Delta sync is
  /// declared and unexecuted, so the honest reference is the committed 115.21
  /// cloud transfer & sync control acceptance (`delta_sync`).
  static const String deltaToken = 'delta_sync';

  /// The declared reference state for the conflict requirement. No conflict is
  /// resolved against a live provider on the delayed path, so the honest
  /// reference is the committed 115.23 sync conflict center acceptance
  /// (`conflict_detection`).
  static const String conflictToken = 'conflict_detection';

  /// The declared reference state for the backup requirement. No backup is
  /// verified against a live destination on the delayed path, so the honest
  /// reference is the committed 115.22 backup policy acceptance (`retention`).
  static const String backupToken = 'retention';

  /// The declared reference state for the restore requirement. No restore is
  /// verified on the delayed path, so the honest reference is the committed
  /// 115.22 backup policy acceptance (`restore_test`).
  static const String restoreToken = 'restore_test';

  /// The committed witness vocabulary that grounds each canonical requirement,
  /// in canonical order.
  static List<List<String>> outputVocabularies(
    Sprint118StorageConnectorAnchor anchor,
  ) => <List<String>>[
    anchor.selectedProviderVocabulary,
    anchor.storageContractVocabulary,
    anchor.quotaVocabulary,
    anchor.deltaVocabulary,
    anchor.conflictVocabulary,
    anchor.backupVocabulary,
    anchor.restoreVocabulary,
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
  /// A witness grounds a token when it names the token exactly (`raw_bytes`,
  /// `delta_sync`, `conflict_detection`), or when every underscore-separated
  /// part of a compound token is itself a witness-declared value. The vocabulary
  /// is measured from the committed witnesses, so a reference state cannot be
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
    Sprint118StorageConnectorAnchor anchor,
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
  static Sprint118StorageConnectorRecord get canonicalRecord =>
      Sprint118StorageConnectorRecord(
        releaseState: delayedReleaseState,
        entries: <Sprint118StorageConnectorEntry>[
          for (final id in canonicalProviders)
            Sprint118StorageConnectorEntry(
              providerId: id,
              selectedProvider: selectedProviderToken,
              storageContract: storageContractToken,
              quota: quotaToken,
              delta: deltaToken,
              conflict: conflictToken,
              backup: backupToken,
              restore: restoreToken,
            ),
        ],
      );
}

/// Reads the committed witnesses for step 118.34. Never invents: an unreadable
/// witness yields `null`, which the gate reports as blocked rather than as a
/// pass.
class Sprint118StorageConnectorLoader {
  const Sprint118StorageConnectorLoader();

  Sprint118StorageConnectorAnchor? loadAnchor() {
    final charter = _read(
      Sprint118StorageConnectorContract.charterManifestPath,
    );
    final snapshot = _read(
      Sprint118StorageConnectorContract.snapshotManifestPath,
    );
    final approval = _read(
      Sprint118StorageConnectorContract.approvalGateManifestPath,
    );
    final icon = _read(
      Sprint118StorageConnectorContract.iconRegistryManifestPath,
    );
    final reconciliation = _read(
      Sprint118StorageConnectorContract.registryReconciliationManifestPath,
    );
    final storageQuota = _read(
      Sprint118StorageConnectorContract.storageQuotaValidationManifestPath,
    );
    final accountModel = _read(
      Sprint118StorageConnectorContract.cloudStorageAccountModelManifestPath,
    );
    final quotaAdapters = _read(
      Sprint118StorageConnectorContract.providerQuotaAdaptersManifestPath,
    );
    final transferControls = _read(
      Sprint118StorageConnectorContract.cloudTransferSyncControlsManifestPath,
    );
    final conflictCenter = _read(
      Sprint118StorageConnectorContract.syncConflictCenterManifestPath,
    );
    final backupPolicies = _read(
      Sprint118StorageConnectorContract.backupPoliciesDestinationsManifestPath,
    );
    if (charter == null ||
        snapshot == null ||
        approval == null ||
        icon == null ||
        reconciliation == null ||
        storageQuota == null ||
        accountModel == null ||
        quotaAdapters == null ||
        transferControls == null ||
        conflictCenter == null ||
        backupPolicies == null) {
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

    final sources = Sprint118StorageConnectorContract.witnessSources.toSet();

    return Sprint118StorageConnectorAnchor(
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
      storageQuotaStatus: _text(storageQuota['status']),
      storageQuotaVerdict: _text(storageQuota['verdict']),
      registeredProviders: registered,
      selectedProviderVocabulary: <String>[
        ..._strings(storageQuota['acceptance_satisfied']),
        ..._strings(storageQuota['acceptance_unmet']),
      ],
      storageContractVocabulary: _strings(accountModel['acceptance']),
      quotaVocabulary: _strings(quotaAdapters['acceptance']),
      deltaVocabulary: _strings(transferControls['acceptance']),
      conflictVocabulary: _strings(conflictCenter['acceptance']),
      backupVocabulary: _strings(backupPolicies['acceptance']),
      restoreVocabulary: _strings(backupPolicies['acceptance']),
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

/// The fail-closed storage connector expansion gate for step 118.34.
class Sprint118StorageConnectorGate {
  const Sprint118StorageConnectorGate();

  Sprint118StorageConnectorReport evaluate() => evaluateWith(
    const Sprint118StorageConnectorLoader().loadAnchor(),
    Sprint118StorageConnectorContract.canonicalRecord,
  );

  Sprint118StorageConnectorReport evaluateWith(
    Sprint118StorageConnectorAnchor? anchor,
    Sprint118StorageConnectorRecord record,
  ) {
    if (anchor == null) {
      return Sprint118StorageConnectorReport(
        state: Sprint118StorageConnectorState.blocked,
        verdict: 'SPRINT_118_STORAGE_CONNECTOR_EXPANSION_EVIDENCE_UNREADABLE',
        releaseState: record.releaseState,
        blockers: const <String>[
          'committed_storage_connector_evidence_unreadable',
        ],
        openItems: const <String>[
          'committed_storage_connector_evidence_unreadable',
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
            Sprint118StorageConnectorContract.requiredCharterState ||
        anchor.charterVerdict !=
            Sprint118StorageConnectorContract.requiredCharterVerdict) {
      blockers.add('charter_not_complete:${anchor.charterVerdict}');
    }

    // (2) The 118.3 snapshot anchor must be a genuine frozen pass.
    if (anchor.snapshotState !=
            Sprint118StorageConnectorContract.requiredSnapshotState ||
        anchor.snapshotVerdict !=
            Sprint118StorageConnectorContract.requiredSnapshotVerdict) {
      blockers.add('snapshot_not_frozen:${anchor.snapshotVerdict}');
    }

    // (3) The 117.45 approval gate must record the delay decision, read with the
    // owner's exact grammar. If it is not a delay, the anchor is untrustworthy.
    if (anchor.approvalDecision !=
        Sprint118StorageConnectorContract.requiredApprovalDecision) {
      blockers.add('approval_gate_not_delay:${anchor.approvalDecision}');
    }

    // (4) The 117 cloud storage quota validation must be a genuine pass, or the
    // storage anchor is untrustworthy.
    if (anchor.storageQuotaStatus !=
            Sprint118StorageConnectorContract.requiredStorageQuotaStatus ||
        anchor.storageQuotaVerdict !=
            Sprint118StorageConnectorContract.requiredStorageQuotaVerdict) {
      blockers.add(
        'storage_quota_not_validated:${anchor.storageQuotaStatus}:'
        '${anchor.storageQuotaVerdict}',
      );
    }

    // (5) The registered provider set must reconcile across the icon registry,
    // the 116.3 reconciliation, the frozen snapshot, and the charter.
    if (anchor.registeredProviders.length !=
            Sprint118StorageConnectorContract.expectedProviderCount ||
        anchor.registryExpectedCount !=
            Sprint118StorageConnectorContract.expectedProviderCount ||
        anchor.snapshotRegistered !=
            Sprint118StorageConnectorContract.expectedProviderCount ||
        anchor.charterRegisteredProviders !=
            Sprint118StorageConnectorContract.expectedProviderCount) {
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
        Sprint118StorageConnectorContract.delayedReleaseState) {
      violations.add(
        'storage_connector_not_on_delayed_path:${record.releaseState}',
      );
    }

    final delayed =
        record.releaseState ==
        Sprint118StorageConnectorContract.delayedReleaseState;

    // (7) On the delayed path an authorized release execution and an unblocked
    // release are behavior that never ran.
    if (delayed && anchor.executionAuthorized) {
      violations.add('storage_connector_execution_authorized_on_delayed_path');
    }
    if (delayed && !anchor.releaseBlocked) {
      violations.add('storage_connector_release_not_blocked_on_delayed_path');
    }

    // (8) The expansion budget must stay frozen: no new certified connector and
    // no already-certified connector while the release is delayed.
    if (!frozen) {
      violations.add(
        'storage_connector_expansion_budget_not_frozen:max_new='
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
        violations.add('storage_connector_provider_unknown:$id');
      }
      for (final field in Sprint118StorageConnectorContract.requiredFields) {
        final value = entry.requiredFields[field] ?? '';
        if (value.trim().isEmpty) {
          violations.add('entry_blank_$field:$id');
        }
      }
      for (final output in Sprint118StorageConnectorContract.requiredOutputs) {
        final token = entry.outputFields[output] ?? '';
        final vocabulary = Sprint118StorageConnectorContract.vocabularyFor(
          anchor,
          output,
        );
        final grounded =
            token == Sprint118StorageConnectorContract.noReferenceState ||
            Sprint118StorageConnectorContract.grounds(vocabulary, token);
        if (token.trim().isEmpty || !grounded) {
          violations.add('reference_state_invalid:$output:$id');
        }
        if (token == Sprint118StorageConnectorContract.noReferenceState) {
          openItems.add('upstream_state_vocabulary_gap:$output:$id');
        }
      }
      // A connector is never certified without live provider verification.
      if (entry.certified) {
        violations.add(
          'storage_connector_certified_claimed_on_delayed_path:$id',
        );
      }
      // A provider is never selected without a certified connector.
      if (entry.selected) {
        violations.add(
          'storage_connector_selected_claimed_on_delayed_path:$id',
        );
      }
      // A quota is never verified without a live provider read.
      if (entry.quotaVerified) {
        violations.add('storage_connector_quota_verified_on_delayed_path:$id');
      }
      // A delta sync is never verified without a live provider.
      if (entry.deltaVerified) {
        violations.add('storage_connector_delta_verified_on_delayed_path:$id');
      }
      // A conflict is never resolved without a live provider.
      if (entry.conflictResolved) {
        violations.add(
          'storage_connector_conflict_resolved_on_delayed_path:$id',
        );
      }
      // A backup is never verified without a live destination.
      if (entry.backupVerified) {
        violations.add('storage_connector_backup_verified_on_delayed_path:$id');
      }
      // A restore is never verified without a live destination.
      if (entry.restoreVerified) {
        violations.add(
          'storage_connector_restore_verified_on_delayed_path:$id',
        );
      }
      // A provider is never released without an authorized release.
      if (entry.released) {
        violations.add('storage_connector_provider_released_claimed:$id');
      }
    }
    for (final id in declared.keys) {
      if (declared[id]! > 1) {
        violations.add('storage_connector_provider_duplicate:$id');
      }
    }
    for (final id in anchor.registeredProviders) {
      if (!declared.containsKey(id)) {
        violations.add('storage_connector_provider_missing:$id');
      }
    }

    // (10) Every committed evidence source must be readable.
    for (final source
        in Sprint118StorageConnectorContract.witnessSources.toSet()) {
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
      return Sprint118StorageConnectorReport(
        state: Sprint118StorageConnectorState.blocked,
        verdict: 'SPRINT_118_STORAGE_CONNECTOR_EXPANSION_BLOCKED_UPSTREAM',
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
      return Sprint118StorageConnectorReport(
        state: Sprint118StorageConnectorState.fail,
        verdict: 'SPRINT_118_STORAGE_CONNECTOR_EXPANSION_EVIDENCE_VIOLATION',
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
    return Sprint118StorageConnectorReport(
      state: Sprint118StorageConnectorState.pass,
      verdict: 'STORAGE_CONNECTOR_EXPANSION_VERIFIED_LOCAL',
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
