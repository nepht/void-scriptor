/// Fail-closed API, SDK & Terms feasibility refresh for roadmap step 118.31 --
/// API, SDK & Terms Feasibility Refresh.
///
/// Objective (external canonical `sprint_118.json`): re-verify primary
/// documentation, versions, deprecations, auth, scopes, terms, region, plans,
/// and quotas. The canonical output set is exactly seven items: `primary_sources`,
/// `verification_date`, `api_version`, `sdk_version`, `deprecations`,
/// `auth_scopes`, and `terms_limits`.
///
/// The release is delayed. No connector is certified (118.3 froze `CERTIFIED: 0`
/// of `32` registered), the 118.2 charter froze an expansion budget of zero new
/// certified connectors out of 32 registered, the committed 117.45 approval gate
/// records `decision=delay`, `approval_state=PENDING_CHOIRUDIN`,
/// `execution_authorized=false`, and `release_blocked=true`, and the committed
/// 116.4 current API & SDK verification is a fail-closed *schema fixture* that
/// claims nothing live (`primary_sources: local-contract-fixture`,
/// `api_version: not-claimed`, `sdk_version: not-claimed`, deprecation/auth/quota
/// review deferred, `external_gates: DEFERRED-EXTERNAL`). No primary provider
/// documentation has been reviewed, no version, deprecation, auth scope, term,
/// region, plan, or quota has been read against a live provider. A feasibility
/// refresh written against that state therefore has exactly one honest shape:
/// enumerate all 32 registered providers, anchor each of the seven outputs to a
/// committed witness vocabulary, and claim no live refresh.
///
/// The gate is fail-closed on these families of rules:
///
/// * The committed 118.2 charter anchor must be a genuine complete charter and
///   its expansion budget must stay frozen (`max_new_certified_connectors` and
///   `currently_certified` both zero). A refresh anchored to an unfrozen budget
///   refreshes a scope nobody authorized.
/// * The committed 118.3 certified connector snapshot must be a genuine frozen
///   pass (`CERTIFIED_CONNECTOR_SNAPSHOT_FROZEN_LOCAL`). A refresh anchored to an
///   unfrozen snapshot rests on a release nobody recorded.
/// * The committed 117.45 approval gate must record the delay decision
///   (`decision == delay`), read with the owner's exact grammar, never
///   case-folded or trimmed into agreement. If it is not a delay, the refresh
///   anchor is untrustworthy and the honest answer is `blocked`, not `fail`.
/// * The committed 116.4 current API & SDK verification must be a genuine
///   schema-ready fixture (`VERIFIED-LOCAL` / `API_SDK_VERIFICATION_SCHEMA_READY`
///   with `external_gates == DEFERRED-EXTERNAL`). A refresh anchored to an
///   unverified primary-documentation record reviews documentation nobody read.
/// * The registered provider set must reconcile: the icon-registry provider
///   union, the 116.3 reconciliation count, the frozen snapshot count, and the
///   charter count must agree. A refresh over a drifting registry is not a
///   refresh.
/// * Every registered provider must appear exactly once. A record that drops a
///   provider, invents `telepathy`, or duplicates `openai` is not a refresh.
/// * Every entry must carry all eight canonical fields non-blank, and each of
///   the seven outputs must be grounded by the committed witness vocabulary for
///   that output, so a feasibility value cannot be invented into the list
///   without a witness to ground it.
/// * On the delayed path a refreshed provider, a verified provider, a confirmed
///   deprecation, a granted scope, an accepted term, or a released provider
///   describe behavior that never ran. This is refused by name, per entry.
///
/// **A provider is never recorded as API/SDK/terms-feasible without live primary
/// documentation review and an authorized release.** When no documentation was
/// reviewed and no release is authorized, the only honest refresh records the
/// committed schema-fixture reference for each output and claims nothing live;
/// any refreshed, verified, deprecation-confirmed, scope-granted, terms-accepted,
/// or released claim is refused by name.
///
/// The output vocabulary is *derived from committed witnesses* (the 116.4 current
/// API & SDK verification record fields, the 118 oauth reauth health
/// `witness_oauth_surfaces`, and the 118.29 provider expansion inventory
/// `region_constraints_vocabulary`), and the source for each output is a
/// committed manifest, not copied by hand, so the record and its witnesses cannot
/// drift apart silently.
///
/// Primary-documentation review, version and deprecation reads, auth scope
/// grants, terms acceptance, region and plan checks, quota reads, credential
/// access, connector certification, provider exposure, and publication remain
/// `DEFERRED-EXTERNAL`; this refresh freezes local declared state and executes
/// none of it.
library;

import 'dart:convert';
import 'dart:io';

/// The three states an API/SDK/terms feasibility refresh can rest in. `blocked`
/// is the honest resting state for "this refresh cannot yet be trusted", and it
/// is distinct from `fail`, which means the record contradicts its own evidence.
enum Sprint118ApiTermsFeasibilityState { pass, fail, blocked }

/// One frozen feasibility-refresh entry: the declared reference for each of the
/// seven canonical outputs of a single registered provider.
///
/// `refreshed`, `verified`, `deprecationsConfirmed`, `scopesGranted`,
/// `termsAccepted`, and `released` are deliberately *not* among the eight
/// required fields; they are the flags the gate refuses when set, so that a
/// declared schema-fixture refresh can be recorded while never being read as a
/// live refresh, a live verification, a confirmed deprecation, a granted auth
/// scope, an accepted term, or a released provider.
class Sprint118ApiTermsFeasibilityEntry {
  const Sprint118ApiTermsFeasibilityEntry({
    required this.providerId,
    required this.primarySources,
    required this.verificationDate,
    required this.apiVersion,
    required this.sdkVersion,
    required this.deprecations,
    required this.authScopes,
    required this.termsLimits,
    this.refreshed = false,
    this.verified = false,
    this.deprecationsConfirmed = false,
    this.scopesGranted = false,
    this.termsAccepted = false,
    this.released = false,
  });

  /// The registered provider identifier, drawn from the committed icon registry.
  final String providerId;

  /// The primary-documentation reference state, drawn from the committed 116.4
  /// current API & SDK verification record's declared primary sources.
  final String primarySources;

  /// The verification-date reference state, drawn from the committed 116.4
  /// current API & SDK verification record's declared verification date.
  final String verificationDate;

  /// The API-version reference state, drawn from the committed 116.4 current API
  /// & SDK verification record's declared API version.
  final String apiVersion;

  /// The SDK-version reference state, drawn from the committed 116.4 current API
  /// & SDK verification record's declared SDK version.
  final String sdkVersion;

  /// The deprecation reference state, drawn from the committed 116.4 current API
  /// & SDK verification record's declared deprecations.
  final String deprecations;

  /// The auth-scope reference state, drawn from the committed 118 oauth reauth
  /// health OAuth-surface vocabulary.
  final String authScopes;

  /// The terms/limits reference state, drawn from the committed 118.29 provider
  /// expansion inventory region-constraint vocabulary.
  final String termsLimits;

  /// Whether the entry claims the provider's documentation was refreshed against
  /// live sources. On the delayed path this must stay `false`.
  final bool refreshed;

  /// Whether the entry claims the provider was verified live. On the delayed path
  /// this must stay `false`.
  final bool verified;

  /// Whether the entry claims a deprecation was confirmed against live
  /// documentation. On the delayed path this must stay `false`.
  final bool deprecationsConfirmed;

  /// Whether the entry claims an auth scope was granted live. On the delayed path
  /// this must stay `false`.
  final bool scopesGranted;

  /// Whether the entry claims provider terms were accepted live. On the delayed
  /// path this must stay `false`.
  final bool termsAccepted;

  /// Whether the entry claims a released provider. On the delayed path this must
  /// stay `false`.
  final bool released;

  /// The eight canonical fields as a name -> value map, so the gate can test
  /// blankness uniformly.
  Map<String, String> get requiredFields => <String, String>{
    'provider_id': providerId,
    'primary_sources': primarySources,
    'verification_date': verificationDate,
    'api_version': apiVersion,
    'sdk_version': sdkVersion,
    'deprecations': deprecations,
    'auth_scopes': authScopes,
    'terms_limits': termsLimits,
  };

  /// The seven outputs as an output -> value map, so the gate can test grounding
  /// per output.
  Map<String, String> get outputFields => <String, String>{
    'primary_sources': primarySources,
    'verification_date': verificationDate,
    'api_version': apiVersion,
    'sdk_version': sdkVersion,
    'deprecations': deprecations,
    'auth_scopes': authScopes,
    'terms_limits': termsLimits,
  };
}

/// The frozen feasibility refresh. `entries` is the declared reference for each
/// registered provider. On the delayed path no entry may claim a live refresh.
class Sprint118ApiTermsFeasibilityRecord {
  const Sprint118ApiTermsFeasibilityRecord({
    required this.releaseState,
    required this.entries,
  });

  final String releaseState;
  final List<Sprint118ApiTermsFeasibilityEntry> entries;

  List<String> get providerIds => <String>[
    for (final entry in entries) entry.providerId,
  ];

  /// The providers the record claims were refreshed. On the delayed path this
  /// must stay empty.
  List<String> get refreshedProviders => <String>[
    for (final entry in entries)
      if (entry.refreshed) entry.providerId,
  ];

  /// The providers the record claims were verified. On the delayed path this must
  /// stay empty.
  List<String> get verifiedProviders => <String>[
    for (final entry in entries)
      if (entry.verified) entry.providerId,
  ];

  int get refreshedCount => entries.where((entry) => entry.refreshed).length;

  int get verifiedCount => entries.where((entry) => entry.verified).length;
}

/// What the committed witnesses actually say. A gate is only as honest as the
/// witnesses it is anchored to.
class Sprint118ApiTermsFeasibilityAnchor {
  const Sprint118ApiTermsFeasibilityAnchor({
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
    required this.apiSdkStatus,
    required this.apiSdkVerdict,
    required this.apiSdkExternalGates,
    required this.registeredProviders,
    required this.primarySourcesVocabulary,
    required this.verificationDateVocabulary,
    required this.apiVersionVocabulary,
    required this.sdkVersionVocabulary,
    required this.deprecationsVocabulary,
    required this.authScopesVocabulary,
    required this.termsLimitsVocabulary,
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

  /// The status the committed 116.4 current API & SDK verification declares.
  final String apiSdkStatus;

  /// The verdict the committed 116.4 current API & SDK verification declares.
  final String apiSdkVerdict;

  /// The external-gates marker the committed 116.4 current API & SDK verification
  /// declares.
  final String apiSdkExternalGates;

  /// The registered provider ids, unioned from the committed 115.8 icon registry.
  final List<String> registeredProviders;

  /// The primary-sources vocabulary the committed 116.4 record declares. It
  /// grounds the primary-sources output.
  final List<String> primarySourcesVocabulary;

  /// The verification-date vocabulary the committed 116.4 record declares. It
  /// grounds the verification-date output.
  final List<String> verificationDateVocabulary;

  /// The API-version vocabulary the committed 116.4 record declares. It grounds
  /// the API-version output.
  final List<String> apiVersionVocabulary;

  /// The SDK-version vocabulary the committed 116.4 record declares. It grounds
  /// the SDK-version output.
  final List<String> sdkVersionVocabulary;

  /// The deprecations vocabulary the committed 116.4 record declares. It grounds
  /// the deprecations output.
  final List<String> deprecationsVocabulary;

  /// The OAuth-surface vocabulary the committed 118 oauth reauth health declares.
  /// It grounds the auth-scopes output.
  final List<String> authScopesVocabulary;

  /// The region-constraint vocabulary the committed 118.29 provider expansion
  /// inventory declares. It grounds the terms-limits output.
  final List<String> termsLimitsVocabulary;

  /// The committed evidence paths that are present and readable on disk.
  final List<String> readableSources;
}

/// The measured result. `pass` means the refresh is a faithful freeze; `blocked`
/// means it cannot yet be trusted; `fail` means it contradicts its evidence.
class Sprint118ApiTermsFeasibilityReport {
  const Sprint118ApiTermsFeasibilityReport({
    required this.state,
    required this.verdict,
    required this.releaseState,
    this.violations = const <String>[],
    this.blockers = const <String>[],
    this.openItems = const <String>[],
    this.declaredProviders = const <String>[],
    this.refreshedProviders = const <String>[],
    this.verifiedProviders = const <String>[],
    this.refreshedCount = 0,
    this.verifiedCount = 0,
    this.expansionBudgetFrozen = false,
  });

  final Sprint118ApiTermsFeasibilityState state;
  final String verdict;
  final String releaseState;

  final List<String> violations;
  final List<String> blockers;
  final List<String> openItems;
  final List<String> declaredProviders;
  final List<String> refreshedProviders;
  final List<String> verifiedProviders;
  final int refreshedCount;
  final int verifiedCount;
  final bool expansionBudgetFrozen;

  /// Whether the refresh may be treated as a frozen feasibility record. Only a
  /// genuine `pass` allows it.
  bool get feasibilityVerified =>
      state == Sprint118ApiTermsFeasibilityState.pass;

  String get externalGates =>
      Sprint118ApiTermsFeasibilityContract.externalGates;
}

/// The fixed vocabulary and committed witness set for step 118.31.
abstract final class Sprint118ApiTermsFeasibilityContract {
  const Sprint118ApiTermsFeasibilityContract._();

  static const String canonicalStep = '118.31';
  static const String title = 'API, SDK & Terms Feasibility Refresh';

  static const String manifestPath =
      'docs/planning/v1.3/sprint_118_api_terms_feasibility.json';
  static const String ledgerPath =
      'docs/sprints/sprint-118-account-cloud-center-stability.md';

  /// The committed 118.2 charter that declares the frozen expansion budget.
  static const String charterManifestPath =
      'docs/planning/v1.3/sprint_118_stability_expansion_charter.json';

  /// The committed 118.3 certified connector snapshot this refresh rests on.
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

  /// The committed 116.4 current API & SDK verification that is the fail-closed
  /// primary-documentation schema fixture this refresh rests on.
  static const String apiSdkVerificationManifestPath =
      'docs/planning/v1.2/sprint_116_current_api_sdk_verification.json';

  /// The committed 118 oauth reauth health that declares the OAuth-surface
  /// vocabulary grounding the auth-scopes output.
  static const String oauthReauthHealthManifestPath =
      'docs/planning/v1.3/sprint_118_oauth_reauth_health.json';

  /// The committed 118.29 provider expansion evidence inventory that declares the
  /// region-constraint vocabulary grounding the terms-limits output.
  static const String expansionInventoryManifestPath =
      'docs/planning/v1.3/sprint_118_provider_expansion_evidence_inventory.json';

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

  /// The status and verdict the committed 116.4 current API & SDK verification
  /// must carry to be a genuine fail-closed schema fixture.
  static const String requiredApiSdkStatus = 'VERIFIED-LOCAL';
  static const String requiredApiSdkVerdict =
      'API_SDK_VERIFICATION_SCHEMA_READY';

  static const String delayedReleaseState = 'GA_DELAYED';

  /// The number of registered providers the committed witnesses reconcile to.
  static const int expectedProviderCount = 32;

  /// The marker an entry declares when no committed witness names a reference
  /// state for an output. A record that uses it records an honest upstream gap
  /// rather than inventing a state.
  static const String noReferenceState = 'no_reference_state';

  /// The canonical field set each entry must carry, so a record cannot drop a
  /// field and still read as complete.
  static const List<String> requiredFields = <String>[
    'provider_id',
    'primary_sources',
    'verification_date',
    'api_version',
    'sdk_version',
    'deprecations',
    'auth_scopes',
    'terms_limits',
  ];

  /// The seven canonical outputs named by the objective, in canonical order.
  /// `provider_id` is the key, not an output.
  static const List<String> requiredOutputs = <String>[
    'primary_sources',
    'verification_date',
    'api_version',
    'sdk_version',
    'deprecations',
    'auth_scopes',
    'terms_limits',
  ];

  /// The committed evidence file each canonical output is anchored to, in
  /// canonical order.
  static const List<String> canonicalSources = <String>[
    apiSdkVerificationManifestPath,
    apiSdkVerificationManifestPath,
    apiSdkVerificationManifestPath,
    apiSdkVerificationManifestPath,
    apiSdkVerificationManifestPath,
    oauthReauthHealthManifestPath,
    expansionInventoryManifestPath,
  ];

  /// The committed evidence files every refresh is anchored to. All must be
  /// readable.
  static const List<String> witnessSources = <String>[
    charterManifestPath,
    snapshotManifestPath,
    approvalGateManifestPath,
    iconRegistryManifestPath,
    registryReconciliationManifestPath,
    apiSdkVerificationManifestPath,
    oauthReauthHealthManifestPath,
    expansionInventoryManifestPath,
  ];

  /// The registered provider ids, in first-seen icon-registry order. This is the
  /// canonical refresh key set: every id appears exactly once and no id is
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

  /// The declared reference state for the primary-sources output. No live primary
  /// documentation is reviewed on the delayed path, so the honest reference is
  /// the committed 116.4 local contract fixture.
  static const String primarySourcesToken = 'local-contract-fixture';

  /// The declared reference state for the verification-date output. No live
  /// verification ran on the delayed path, so the honest reference is the
  /// committed 116.4 schema-fixture date.
  static const String verificationDateToken = '2026-09-27';

  /// The declared reference state for the API-version output. The version is
  /// declared and unread, so the honest reference is the committed 116.4
  /// not-claimed marker.
  static const String apiVersionToken = 'not-claimed';

  /// The declared reference state for the SDK-version output. The version is
  /// declared and unread, so the honest reference is the committed 116.4
  /// not-claimed marker.
  static const String sdkVersionToken = 'not-claimed';

  /// The declared reference state for the deprecations output. Deprecation review
  /// is deferred, so the honest reference is the committed 116.4 deferred marker.
  static const String deprecationsToken =
      'live provider documentation review deferred';

  /// The declared reference state for the auth-scopes output. Auth is declared
  /// and unverified, so the honest reference is a committed 118 OAuth surface.
  static const String authScopesToken = 'scoped_consent';

  /// The declared reference state for the terms-limits output. Terms, region, and
  /// plan limits are declared and unverified, so the honest reference is the
  /// committed 118.29 unsupported-plan constraint.
  static const String termsLimitsToken = 'unsupported_plan';

  /// The committed witness vocabulary that grounds each canonical output, in
  /// canonical order.
  static List<List<String>> outputVocabularies(
    Sprint118ApiTermsFeasibilityAnchor anchor,
  ) => <List<String>>[
    anchor.primarySourcesVocabulary,
    anchor.verificationDateVocabulary,
    anchor.apiVersionVocabulary,
    anchor.sdkVersionVocabulary,
    anchor.deprecationsVocabulary,
    anchor.authScopesVocabulary,
    anchor.termsLimitsVocabulary,
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
  /// (`local-contract-fixture`, `not-claimed`, `scoped_consent`), or when every
  /// underscore-separated part of a compound token is itself a witness-declared
  /// value. The vocabulary is measured from the committed witnesses, so a
  /// reference state cannot be invented into the list without a witness to ground
  /// it.
  static bool grounds(List<String> vocabulary, String token) {
    if (vocabulary.contains(token)) return true;
    final parts = token.split('_');
    if (parts.length < 2) return false;
    return parts.every(vocabulary.contains);
  }

  /// The committed witness vocabulary for a canonical output, or the empty list
  /// when the output is unknown.
  static List<String> vocabularyFor(
    Sprint118ApiTermsFeasibilityAnchor anchor,
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

  /// The canonical frozen refresh: every registered provider, each anchored to
  /// the committed witness vocabularies, claiming nothing live.
  static Sprint118ApiTermsFeasibilityRecord get canonicalRecord =>
      Sprint118ApiTermsFeasibilityRecord(
        releaseState: delayedReleaseState,
        entries: <Sprint118ApiTermsFeasibilityEntry>[
          for (final id in canonicalProviders)
            Sprint118ApiTermsFeasibilityEntry(
              providerId: id,
              primarySources: primarySourcesToken,
              verificationDate: verificationDateToken,
              apiVersion: apiVersionToken,
              sdkVersion: sdkVersionToken,
              deprecations: deprecationsToken,
              authScopes: authScopesToken,
              termsLimits: termsLimitsToken,
            ),
        ],
      );
}

/// Reads the committed witnesses for step 118.31. Never invents: an unreadable
/// witness yields `null`, which the gate reports as blocked rather than as a
/// pass.
class Sprint118ApiTermsFeasibilityLoader {
  const Sprint118ApiTermsFeasibilityLoader();

  Sprint118ApiTermsFeasibilityAnchor? loadAnchor() {
    final charter = _read(
      Sprint118ApiTermsFeasibilityContract.charterManifestPath,
    );
    final snapshot = _read(
      Sprint118ApiTermsFeasibilityContract.snapshotManifestPath,
    );
    final approval = _read(
      Sprint118ApiTermsFeasibilityContract.approvalGateManifestPath,
    );
    final icon = _read(
      Sprint118ApiTermsFeasibilityContract.iconRegistryManifestPath,
    );
    final reconciliation = _read(
      Sprint118ApiTermsFeasibilityContract.registryReconciliationManifestPath,
    );
    final apiSdk = _read(
      Sprint118ApiTermsFeasibilityContract.apiSdkVerificationManifestPath,
    );
    final oauth = _read(
      Sprint118ApiTermsFeasibilityContract.oauthReauthHealthManifestPath,
    );
    final inventory = _read(
      Sprint118ApiTermsFeasibilityContract.expansionInventoryManifestPath,
    );
    if (charter == null ||
        snapshot == null ||
        approval == null ||
        icon == null ||
        reconciliation == null ||
        apiSdk == null ||
        oauth == null ||
        inventory == null) {
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

    final records = apiSdk['records'];
    final sources = Sprint118ApiTermsFeasibilityContract.witnessSources.toSet();

    return Sprint118ApiTermsFeasibilityAnchor(
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
      apiSdkStatus: _text(apiSdk['status']),
      apiSdkVerdict: _text(apiSdk['verdict']),
      apiSdkExternalGates: _text(apiSdk['external_gates']),
      registeredProviders: registered,
      primarySourcesVocabulary: _flatField(records, 'primary_sources'),
      verificationDateVocabulary: _flatField(records, 'verification_date'),
      apiVersionVocabulary: _flatField(records, 'api_version'),
      sdkVersionVocabulary: _flatField(records, 'sdk_version'),
      deprecationsVocabulary: _flatField(records, 'deprecations'),
      authScopesVocabulary: _strings(oauth['witness_oauth_surfaces']),
      termsLimitsVocabulary: _strings(
        inventory['region_constraints_vocabulary'],
      ),
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

  /// Reads a named field out of each map in a list, flattening list-valued fields
  /// so a list of records (`records[].primary_sources`) yields its declared
  /// vocabulary.
  static List<String> _flatField(Object? value, String key) {
    if (value is! List) return const <String>[];
    final result = <String>[];
    for (final item in value) {
      if (item is! Map) continue;
      final field = item[key];
      if (field is List) {
        for (final entry in field) {
          if (entry is String) result.add(entry);
        }
      } else if (field is String) {
        result.add(field);
      }
    }
    return result;
  }

  static int _int(Object? value) => value is int ? value : 0;
}

/// The fail-closed API/SDK/terms feasibility gate for step 118.31.
class Sprint118ApiTermsFeasibilityGate {
  const Sprint118ApiTermsFeasibilityGate();

  Sprint118ApiTermsFeasibilityReport evaluate() => evaluateWith(
    const Sprint118ApiTermsFeasibilityLoader().loadAnchor(),
    Sprint118ApiTermsFeasibilityContract.canonicalRecord,
  );

  Sprint118ApiTermsFeasibilityReport evaluateWith(
    Sprint118ApiTermsFeasibilityAnchor? anchor,
    Sprint118ApiTermsFeasibilityRecord record,
  ) {
    if (anchor == null) {
      return Sprint118ApiTermsFeasibilityReport(
        state: Sprint118ApiTermsFeasibilityState.blocked,
        verdict: 'SPRINT_118_API_TERMS_FEASIBILITY_EVIDENCE_UNREADABLE',
        releaseState: record.releaseState,
        blockers: const <String>[
          'committed_api_terms_feasibility_evidence_unreadable',
        ],
        openItems: const <String>[
          'committed_api_terms_feasibility_evidence_unreadable',
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
            Sprint118ApiTermsFeasibilityContract.requiredCharterState ||
        anchor.charterVerdict !=
            Sprint118ApiTermsFeasibilityContract.requiredCharterVerdict) {
      blockers.add('charter_not_complete:${anchor.charterVerdict}');
    }

    // (2) The 118.3 snapshot anchor must be a genuine frozen pass.
    if (anchor.snapshotState !=
            Sprint118ApiTermsFeasibilityContract.requiredSnapshotState ||
        anchor.snapshotVerdict !=
            Sprint118ApiTermsFeasibilityContract.requiredSnapshotVerdict) {
      blockers.add('snapshot_not_frozen:${anchor.snapshotVerdict}');
    }

    // (3) The 117.45 approval gate must record the delay decision, read with the
    // owner's exact grammar. If it is not a delay, the anchor is untrustworthy.
    if (anchor.approvalDecision !=
        Sprint118ApiTermsFeasibilityContract.requiredApprovalDecision) {
      blockers.add('approval_gate_not_delay:${anchor.approvalDecision}');
    }

    // (4) The 116.4 current API & SDK verification must be a genuine schema-ready
    // fixture, or the primary-documentation anchor is untrustworthy.
    if (anchor.apiSdkStatus !=
            Sprint118ApiTermsFeasibilityContract.requiredApiSdkStatus ||
        anchor.apiSdkVerdict !=
            Sprint118ApiTermsFeasibilityContract.requiredApiSdkVerdict ||
        anchor.apiSdkExternalGates !=
            Sprint118ApiTermsFeasibilityContract.externalGates) {
      blockers.add(
        'api_sdk_verification_not_schema_ready:${anchor.apiSdkStatus}:'
        '${anchor.apiSdkVerdict}:${anchor.apiSdkExternalGates}',
      );
    }

    // (5) The registered provider set must reconcile across the icon registry,
    // the 116.3 reconciliation, the frozen snapshot, and the charter.
    if (anchor.registeredProviders.length !=
            Sprint118ApiTermsFeasibilityContract.expectedProviderCount ||
        anchor.registryExpectedCount !=
            Sprint118ApiTermsFeasibilityContract.expectedProviderCount ||
        anchor.snapshotRegistered !=
            Sprint118ApiTermsFeasibilityContract.expectedProviderCount ||
        anchor.charterRegisteredProviders !=
            Sprint118ApiTermsFeasibilityContract.expectedProviderCount) {
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
        Sprint118ApiTermsFeasibilityContract.delayedReleaseState) {
      violations.add(
        'api_terms_feasibility_not_on_delayed_path:${record.releaseState}',
      );
    }

    final delayed =
        record.releaseState ==
        Sprint118ApiTermsFeasibilityContract.delayedReleaseState;

    // (7) On the delayed path an authorized release execution and an unblocked
    // release are behavior that never ran.
    if (delayed && anchor.executionAuthorized) {
      violations.add('api_terms_execution_authorized_on_delayed_path');
    }
    if (delayed && !anchor.releaseBlocked) {
      violations.add('api_terms_release_not_blocked_on_delayed_path');
    }

    // (8) The expansion budget must stay frozen: no new certified connector and
    // no already-certified connector while the release is delayed.
    if (!frozen) {
      violations.add(
        'api_terms_expansion_budget_not_frozen:max_new='
        '${anchor.charterMaxNewCertified}:'
        'currently=${anchor.charterCurrentlyCertified}',
      );
    }

    // (9) Every registered provider must appear exactly once, and each entry must
    // carry all eight canonical fields non-blank with every output grounded by
    // its committed witness vocabulary.
    final declared = <String, int>{};
    for (final entry in record.entries) {
      declared[entry.providerId] = (declared[entry.providerId] ?? 0) + 1;
    }
    for (final entry in record.entries) {
      final id = entry.providerId;
      if (!anchor.registeredProviders.contains(id)) {
        violations.add('api_terms_provider_unknown:$id');
      }
      for (final field in Sprint118ApiTermsFeasibilityContract.requiredFields) {
        final value = entry.requiredFields[field] ?? '';
        if (value.trim().isEmpty) {
          violations.add('entry_blank_$field:$id');
        }
      }
      for (final output
          in Sprint118ApiTermsFeasibilityContract.requiredOutputs) {
        final token = entry.outputFields[output] ?? '';
        final vocabulary = Sprint118ApiTermsFeasibilityContract.vocabularyFor(
          anchor,
          output,
        );
        final grounded =
            token == Sprint118ApiTermsFeasibilityContract.noReferenceState ||
            Sprint118ApiTermsFeasibilityContract.grounds(vocabulary, token);
        if (token.trim().isEmpty || !grounded) {
          violations.add('reference_state_invalid:$output:$id');
        }
        if (token == Sprint118ApiTermsFeasibilityContract.noReferenceState) {
          openItems.add('upstream_state_vocabulary_gap:$output:$id');
        }
      }
      // A provider's documentation is never refreshed without live primary
      // documentation review.
      if (entry.refreshed) {
        violations.add('api_terms_refresh_claimed_on_delayed_path:$id');
      }
      // A provider is never verified live without live documentation review.
      if (entry.verified) {
        violations.add('api_terms_verification_claimed_on_delayed_path:$id');
      }
      // A deprecation is never confirmed without live documentation review.
      if (entry.deprecationsConfirmed) {
        violations.add('api_terms_deprecation_claimed_on_delayed_path:$id');
      }
      // An auth scope is never granted without a live authorization flow.
      if (entry.scopesGranted) {
        violations.add('api_terms_scope_grant_claimed_on_delayed_path:$id');
      }
      // Provider terms are never accepted without a live review.
      if (entry.termsAccepted) {
        violations.add('api_terms_terms_accepted_on_delayed_path:$id');
      }
      // A provider is never released without an authorized release.
      if (entry.released) {
        violations.add('api_terms_provider_released_claimed:$id');
      }
    }
    for (final id in declared.keys) {
      if (declared[id]! > 1) {
        violations.add('api_terms_provider_duplicate:$id');
      }
    }
    for (final id in anchor.registeredProviders) {
      if (!declared.containsKey(id)) {
        violations.add('api_terms_provider_missing:$id');
      }
    }

    // (10) Every committed evidence source must be readable.
    for (final source
        in Sprint118ApiTermsFeasibilityContract.witnessSources.toSet()) {
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
      return Sprint118ApiTermsFeasibilityReport(
        state: Sprint118ApiTermsFeasibilityState.blocked,
        verdict: 'SPRINT_118_API_TERMS_FEASIBILITY_BLOCKED_UPSTREAM',
        releaseState: record.releaseState,
        violations: violations,
        blockers: blockers,
        openItems: allItems,
        declaredProviders: providers,
        refreshedProviders: record.refreshedProviders,
        verifiedProviders: record.verifiedProviders,
        refreshedCount: record.refreshedCount,
        verifiedCount: record.verifiedCount,
        expansionBudgetFrozen: frozen,
      );
    }
    if (violations.isNotEmpty) {
      return Sprint118ApiTermsFeasibilityReport(
        state: Sprint118ApiTermsFeasibilityState.fail,
        verdict: 'SPRINT_118_API_TERMS_FEASIBILITY_EVIDENCE_VIOLATION',
        releaseState: record.releaseState,
        violations: violations,
        blockers: blockers,
        openItems: allItems,
        declaredProviders: providers,
        refreshedProviders: record.refreshedProviders,
        verifiedProviders: record.verifiedProviders,
        refreshedCount: record.refreshedCount,
        verifiedCount: record.verifiedCount,
        expansionBudgetFrozen: frozen,
      );
    }
    return Sprint118ApiTermsFeasibilityReport(
      state: Sprint118ApiTermsFeasibilityState.pass,
      verdict: 'API_TERMS_FEASIBILITY_VERIFIED_LOCAL',
      releaseState: record.releaseState,
      openItems: allItems,
      declaredProviders: providers,
      refreshedProviders: record.refreshedProviders,
      verifiedProviders: record.verifiedProviders,
      refreshedCount: record.refreshedCount,
      verifiedCount: record.verifiedCount,
      expansionBudgetFrozen: frozen,
    );
  }
}
