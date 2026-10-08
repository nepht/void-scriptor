/// Fail-closed brand & legal readiness for roadmap step 118.32 -- Brand & Legal
/// Readiness.
///
/// Objective (external canonical `sprint_118.json`): verify logo use, naming,
/// attribution, licenses, trademark requirements, and marketplace listing
/// constraints. The canonical output set is exactly six items: `asset_source`,
/// `permission`, `trademark_rules`, `attribution`, `license`, and
/// `listing_constraints`.
///
/// The release is delayed. No connector is certified (118.3 froze `CERTIFIED: 0`
/// of `32` registered), the 118.2 charter froze an expansion budget of zero new
/// certified connectors out of 32 registered, the committed 117.45 approval gate
/// records `decision=delay`, `approval_state=PENDING_CHOIRUDIN`,
/// `execution_authorized=false`, and `release_blocked=true`, and the committed
/// 116.7 brand asset & icon certification is a fail-closed *schema fixture* that
/// claims nothing live (`asset_source: synthetic fixture`,
/// `license_or_permission: not a production mark`, `review_status: UNVERIFIED`,
/// `external_gates: DEFERRED-EXTERNAL`). No provider logo use has been verified,
/// no naming has been cleared, no attribution has been published, no license has
/// been granted, no trademark has been cleared, and no marketplace listing has
/// been approved. A brand & legal readiness review written against that state
/// therefore has exactly one honest shape: enumerate all 32 registered
/// providers, anchor each of the six outputs to a committed witness vocabulary,
/// and claim no live readiness.
///
/// The gate is fail-closed on these families of rules:
///
/// * The committed 118.2 charter anchor must be a genuine complete charter and
///   its expansion budget must stay frozen (`max_new_certified_connectors` and
///   `currently_certified` both zero). A readiness review anchored to an
///   unfrozen budget clears a scope nobody authorized.
/// * The committed 118.3 certified connector snapshot must be a genuine frozen
///   pass (`CERTIFIED_CONNECTOR_SNAPSHOT_FROZEN_LOCAL`). A readiness review
///   anchored to an unfrozen snapshot rests on a release nobody recorded.
/// * The committed 117.45 approval gate must record the delay decision
///   (`decision == delay`), read with the owner's exact grammar, never
///   case-folded or trimmed into agreement. If it is not a delay, the readiness
///   anchor is untrustworthy and the honest answer is `blocked`, not `fail`.
/// * The committed 116.7 brand asset & icon certification must be a genuine
///   schema-ready fixture (`VERIFIED-LOCAL` / `BRAND_ICON_SCHEMA_READY` with
///   `external_gates == DEFERRED-EXTERNAL`). A readiness review anchored to an
///   unverified brand record reviews marks nobody licensed.
/// * The registered provider set must reconcile: the icon-registry provider
///   union, the 116.3 reconciliation count, the frozen snapshot count, and the
///   charter count must agree. A readiness review over a drifting registry is
///   not a readiness review.
/// * Every registered provider must appear exactly once. A record that drops a
///   provider, invents `telepathy`, or duplicates `openai` is not a readiness
///   review.
/// * Every entry must carry all seven canonical fields non-blank, and each of
///   the six outputs must be grounded by the committed witness vocabulary for
///   that output, so a brand or legal value cannot be invented into the list
///   without a witness to ground it.
/// * On the delayed path a verified logo use, a cleared naming, a published
///   attribution, a granted license, a cleared trademark, an approved listing,
///   or a released provider describe behavior that never ran. This is refused by
///   name, per entry.
///
/// **A provider is never recorded as brand & legally ready without live brand
/// verification and an authorized release.** When no logo use was verified and
/// no release is authorized, the only honest readiness review records the
/// committed schema-fixture reference for each output and claims nothing live;
/// any logo-use, naming, attribution, license, trademark, listing, or release
/// claim is refused by name.
///
/// The output vocabulary is *derived from committed witnesses* (the 116.7 brand
/// asset & icon certification record fields, the 115.8 provider icon registry
/// `required_fields` trademark notice, the 116.35 creative asset rights record
/// fields, and the 114.22 feature availability reconciliation marketplace
/// entitlement marker), and the source for each output is a committed manifest,
/// not copied by hand, so the record and its witnesses cannot drift apart
/// silently.
///
/// Logo-use verification, naming clearance, attribution publication, license
/// grants, trademark clearance, marketplace listing approval, mark exposure,
/// credential access, connector certification, provider exposure, and
/// publication remain `DEFERRED-EXTERNAL`; this review freezes local declared
/// state and executes none of it.
library;

import 'dart:convert';
import 'dart:io';

/// The three states a brand & legal readiness review can rest in. `blocked` is
/// the honest resting state for "this review cannot yet be trusted", and it is
/// distinct from `fail`, which means the record contradicts its own evidence.
enum Sprint118BrandLegalState { pass, fail, blocked }

/// One frozen brand & legal readiness entry: the declared reference for each of
/// the six canonical outputs of a single registered provider.
///
/// `logoUseApproved`, `namingCleared`, `attributionPublished`, `licenseGranted`,
/// `trademarkCleared`, `listingApproved`, and `released` are deliberately *not*
/// among the seven required fields; they are the flags the gate refuses when
/// set, so that a declared schema-fixture readiness can be recorded while never
/// being read as a verified logo use, a cleared naming, a published attribution,
/// a granted license, a cleared trademark, an approved marketplace listing, or a
/// released provider.
class Sprint118BrandLegalEntry {
  const Sprint118BrandLegalEntry({
    required this.providerId,
    required this.assetSource,
    required this.permission,
    required this.trademarkRules,
    required this.attribution,
    required this.license,
    required this.listingConstraints,
    this.logoUseApproved = false,
    this.namingCleared = false,
    this.attributionPublished = false,
    this.licenseGranted = false,
    this.trademarkCleared = false,
    this.listingApproved = false,
    this.released = false,
  });

  /// The registered provider identifier, drawn from the committed icon registry.
  final String providerId;

  /// The asset-source reference state, drawn from the committed 116.7 brand asset
  /// & icon certification record's declared asset source.
  final String assetSource;

  /// The permission reference state, drawn from the committed 116.7 brand asset
  /// & icon certification record's declared license or permission.
  final String permission;

  /// The trademark-rules reference state, drawn from the committed 115.8 provider
  /// icon registry trademark notice field.
  final String trademarkRules;

  /// The attribution reference state, drawn from the committed 116.35 creative
  /// asset rights record's declared attribution.
  final String attribution;

  /// The license reference state, drawn from the committed 116.35 creative asset
  /// rights record's declared license.
  final String license;

  /// The listing-constraints reference state, drawn from the committed 114.22
  /// feature availability reconciliation marketplace entitlement marker.
  final String listingConstraints;

  /// Whether the entry claims the provider's logo use was verified. On the
  /// delayed path this must stay `false`.
  final bool logoUseApproved;

  /// Whether the entry claims the provider's naming was cleared. On the delayed
  /// path this must stay `false`.
  final bool namingCleared;

  /// Whether the entry claims attribution was published. On the delayed path this
  /// must stay `false`.
  final bool attributionPublished;

  /// Whether the entry claims a license was granted. On the delayed path this
  /// must stay `false`.
  final bool licenseGranted;

  /// Whether the entry claims a trademark was cleared. On the delayed path this
  /// must stay `false`.
  final bool trademarkCleared;

  /// Whether the entry claims a marketplace listing was approved. On the delayed
  /// path this must stay `false`.
  final bool listingApproved;

  /// Whether the entry claims a released provider. On the delayed path this must
  /// stay `false`.
  final bool released;

  /// The seven canonical fields as a name -> value map, so the gate can test
  /// blankness uniformly.
  Map<String, String> get requiredFields => <String, String>{
    'provider_id': providerId,
    'asset_source': assetSource,
    'permission': permission,
    'trademark_rules': trademarkRules,
    'attribution': attribution,
    'license': license,
    'listing_constraints': listingConstraints,
  };

  /// The six outputs as an output -> value map, so the gate can test grounding
  /// per output.
  Map<String, String> get outputFields => <String, String>{
    'asset_source': assetSource,
    'permission': permission,
    'trademark_rules': trademarkRules,
    'attribution': attribution,
    'license': license,
    'listing_constraints': listingConstraints,
  };
}

/// The frozen brand & legal readiness review. `entries` is the declared
/// reference for each registered provider. On the delayed path no entry may
/// claim a live readiness.
class Sprint118BrandLegalRecord {
  const Sprint118BrandLegalRecord({
    required this.releaseState,
    required this.entries,
  });

  final String releaseState;
  final List<Sprint118BrandLegalEntry> entries;

  List<String> get providerIds => <String>[
    for (final entry in entries) entry.providerId,
  ];

  /// The providers the record claims had their logo use verified. On the delayed
  /// path this must stay empty.
  List<String> get logoUseApprovedProviders => <String>[
    for (final entry in entries)
      if (entry.logoUseApproved) entry.providerId,
  ];

  /// The providers the record claims had a marketplace listing approved. On the
  /// delayed path this must stay empty.
  List<String> get listingApprovedProviders => <String>[
    for (final entry in entries)
      if (entry.listingApproved) entry.providerId,
  ];

  int get logoUseApprovedCount =>
      entries.where((entry) => entry.logoUseApproved).length;

  int get listingApprovedCount =>
      entries.where((entry) => entry.listingApproved).length;
}

/// What the committed witnesses actually say. A gate is only as honest as the
/// witnesses it is anchored to.
class Sprint118BrandLegalAnchor {
  const Sprint118BrandLegalAnchor({
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
    required this.brandStatus,
    required this.brandVerdict,
    required this.brandExternalGates,
    required this.registeredProviders,
    required this.assetSourceVocabulary,
    required this.permissionVocabulary,
    required this.trademarkRulesVocabulary,
    required this.attributionVocabulary,
    required this.licenseVocabulary,
    required this.listingConstraintsVocabulary,
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

  /// The status the committed 116.7 brand asset & icon certification declares.
  final String brandStatus;

  /// The verdict the committed 116.7 brand asset & icon certification declares.
  final String brandVerdict;

  /// The external-gates marker the committed 116.7 brand asset & icon
  /// certification declares.
  final String brandExternalGates;

  /// The registered provider ids, unioned from the committed 115.8 icon registry.
  final List<String> registeredProviders;

  /// The asset-source vocabulary the committed 116.7 record declares. It grounds
  /// the asset-source output.
  final List<String> assetSourceVocabulary;

  /// The permission vocabulary the committed 116.7 record declares. It grounds
  /// the permission output.
  final List<String> permissionVocabulary;

  /// The trademark-rules vocabulary the committed 115.8 icon registry declares.
  /// It grounds the trademark-rules output.
  final List<String> trademarkRulesVocabulary;

  /// The attribution vocabulary the committed 116.35 record declares. It grounds
  /// the attribution output.
  final List<String> attributionVocabulary;

  /// The license vocabulary the committed 116.35 record declares. It grounds the
  /// license output.
  final List<String> licenseVocabulary;

  /// The listing-constraints vocabulary the committed 114.22 reconciliation
  /// declares. It grounds the listing-constraints output.
  final List<String> listingConstraintsVocabulary;

  /// The committed evidence paths that are present and readable on disk.
  final List<String> readableSources;
}

/// The measured result. `pass` means the review is a faithful freeze; `blocked`
/// means it cannot yet be trusted; `fail` means it contradicts its evidence.
class Sprint118BrandLegalReport {
  const Sprint118BrandLegalReport({
    required this.state,
    required this.verdict,
    required this.releaseState,
    this.violations = const <String>[],
    this.blockers = const <String>[],
    this.openItems = const <String>[],
    this.declaredProviders = const <String>[],
    this.logoUseApprovedProviders = const <String>[],
    this.listingApprovedProviders = const <String>[],
    this.logoUseApprovedCount = 0,
    this.listingApprovedCount = 0,
    this.expansionBudgetFrozen = false,
  });

  final Sprint118BrandLegalState state;
  final String verdict;
  final String releaseState;

  final List<String> violations;
  final List<String> blockers;
  final List<String> openItems;
  final List<String> declaredProviders;
  final List<String> logoUseApprovedProviders;
  final List<String> listingApprovedProviders;
  final int logoUseApprovedCount;
  final int listingApprovedCount;
  final bool expansionBudgetFrozen;

  /// Whether the review may be treated as a frozen readiness record. Only a
  /// genuine `pass` allows it.
  bool get readinessVerified => state == Sprint118BrandLegalState.pass;

  String get externalGates => Sprint118BrandLegalContract.externalGates;
}

/// The fixed vocabulary and committed witness set for step 118.32.
abstract final class Sprint118BrandLegalContract {
  const Sprint118BrandLegalContract._();

  static const String canonicalStep = '118.32';
  static const String title = 'Brand & Legal Readiness';

  static const String manifestPath =
      'docs/planning/v1.3/sprint_118_brand_legal_readiness.json';
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
  /// seam, the registered-provider source, and the trademark-notice vocabulary.
  static const String iconRegistryManifestPath =
      'docs/planning/v1.2/sprint_115_provider_icon_registry.json';

  /// The committed 116.3 provider registry reconciliation that declares the
  /// expected provider count.
  static const String registryReconciliationManifestPath =
      'docs/planning/v1.2/sprint_116_provider_registry_reconciliation.json';

  /// The committed 116.7 brand asset & icon certification that is the fail-closed
  /// brand schema fixture this review rests on.
  static const String brandCertificationManifestPath =
      'docs/planning/v1.2/sprint_116_brand_asset_icon_certification.json';

  /// The committed 116.35 creative asset rights verification that declares the
  /// attribution and license vocabularies.
  static const String creativeAssetRightsManifestPath =
      'docs/planning/v1.2/sprint_116_creative_asset_rights_verification.json';

  /// The committed 114.22 feature availability reconciliation that declares the
  /// marketplace entitlement marker grounding the listing-constraints output.
  static const String featureAvailabilityManifestPath =
      'docs/planning/v1.2/sprint_114_feature_availability_reconciliation.json';

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

  /// The status and verdict the committed 116.7 brand asset & icon certification
  /// must carry to be a genuine fail-closed schema fixture.
  static const String requiredBrandStatus = 'VERIFIED-LOCAL';
  static const String requiredBrandVerdict = 'BRAND_ICON_SCHEMA_READY';

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
    'asset_source',
    'permission',
    'trademark_rules',
    'attribution',
    'license',
    'listing_constraints',
  ];

  /// The six canonical outputs named by the objective, in canonical order.
  /// `provider_id` is the key, not an output.
  static const List<String> requiredOutputs = <String>[
    'asset_source',
    'permission',
    'trademark_rules',
    'attribution',
    'license',
    'listing_constraints',
  ];

  /// The committed evidence file each canonical output is anchored to, in
  /// canonical order.
  static const List<String> canonicalSources = <String>[
    brandCertificationManifestPath,
    brandCertificationManifestPath,
    iconRegistryManifestPath,
    creativeAssetRightsManifestPath,
    creativeAssetRightsManifestPath,
    featureAvailabilityManifestPath,
  ];

  /// The committed evidence files every review is anchored to. All must be
  /// readable.
  static const List<String> witnessSources = <String>[
    charterManifestPath,
    snapshotManifestPath,
    approvalGateManifestPath,
    iconRegistryManifestPath,
    registryReconciliationManifestPath,
    brandCertificationManifestPath,
    creativeAssetRightsManifestPath,
    featureAvailabilityManifestPath,
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

  /// The declared reference state for the asset-source output. No live brand
  /// asset was verified on the delayed path, so the honest reference is the
  /// committed 116.7 synthetic fixture.
  static const String assetSourceToken = 'synthetic fixture';

  /// The declared reference state for the permission output. No provider mark was
  /// licensed on the delayed path, so the honest reference is the committed 116.7
  /// not-a-production-mark marker.
  static const String permissionToken = 'not a production mark';

  /// The declared reference state for the trademark-rules output. Trademark
  /// clearance is deferred, so the honest reference is the committed 115.8
  /// trademark-notice field.
  static const String trademarkRulesToken = 'trademark_notice';

  /// The declared reference state for the attribution output. No attribution was
  /// published on the delayed path, so the honest reference is the committed
  /// 116.35 synthetic attribution fixture.
  static const String attributionToken = 'synthetic attribution fixture';

  /// The declared reference state for the license output. No license was granted
  /// on the delayed path, so the honest reference is the committed 116.35
  /// synthetic license fixture.
  static const String licenseToken = 'synthetic license fixture';

  /// The declared reference state for the listing-constraints output. Marketplace
  /// listing constraints are unverified, so the honest reference is the committed
  /// 114.22 deferred marker.
  static const String listingConstraintsToken = 'DEFERRED-EXTERNAL';

  /// The committed witness vocabulary that grounds each canonical output, in
  /// canonical order.
  static List<List<String>> outputVocabularies(
    Sprint118BrandLegalAnchor anchor,
  ) => <List<String>>[
    anchor.assetSourceVocabulary,
    anchor.permissionVocabulary,
    anchor.trademarkRulesVocabulary,
    anchor.attributionVocabulary,
    anchor.licenseVocabulary,
    anchor.listingConstraintsVocabulary,
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
  /// (`synthetic fixture`, `not a production mark`, `trademark_notice`), or when
  /// every underscore-separated part of a compound token is itself a
  /// witness-declared value. The vocabulary is measured from the committed
  /// witnesses, so a reference state cannot be invented into the list without a
  /// witness to ground it.
  static bool grounds(List<String> vocabulary, String token) {
    if (vocabulary.contains(token)) return true;
    final parts = token.split('_');
    if (parts.length < 2) return false;
    return parts.every(vocabulary.contains);
  }

  /// The committed witness vocabulary for a canonical output, or the empty list
  /// when the output is unknown.
  static List<String> vocabularyFor(
    Sprint118BrandLegalAnchor anchor,
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

  /// The canonical frozen review: every registered provider, each anchored to the
  /// committed witness vocabularies, claiming nothing live.
  static Sprint118BrandLegalRecord get canonicalRecord =>
      Sprint118BrandLegalRecord(
        releaseState: delayedReleaseState,
        entries: <Sprint118BrandLegalEntry>[
          for (final id in canonicalProviders)
            Sprint118BrandLegalEntry(
              providerId: id,
              assetSource: assetSourceToken,
              permission: permissionToken,
              trademarkRules: trademarkRulesToken,
              attribution: attributionToken,
              license: licenseToken,
              listingConstraints: listingConstraintsToken,
            ),
        ],
      );
}

/// Reads the committed witnesses for step 118.32. Never invents: an unreadable
/// witness yields `null`, which the gate reports as blocked rather than as a
/// pass.
class Sprint118BrandLegalLoader {
  const Sprint118BrandLegalLoader();

  Sprint118BrandLegalAnchor? loadAnchor() {
    final charter = _read(Sprint118BrandLegalContract.charterManifestPath);
    final snapshot = _read(Sprint118BrandLegalContract.snapshotManifestPath);
    final approval = _read(
      Sprint118BrandLegalContract.approvalGateManifestPath,
    );
    final icon = _read(Sprint118BrandLegalContract.iconRegistryManifestPath);
    final reconciliation = _read(
      Sprint118BrandLegalContract.registryReconciliationManifestPath,
    );
    final brand = _read(
      Sprint118BrandLegalContract.brandCertificationManifestPath,
    );
    final creative = _read(
      Sprint118BrandLegalContract.creativeAssetRightsManifestPath,
    );
    final availability = _read(
      Sprint118BrandLegalContract.featureAvailabilityManifestPath,
    );
    if (charter == null ||
        snapshot == null ||
        approval == null ||
        icon == null ||
        reconciliation == null ||
        brand == null ||
        creative == null ||
        availability == null) {
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

    final brandRecords = brand['records'];
    final creativeRecords = creative['records'];
    final sources = Sprint118BrandLegalContract.witnessSources.toSet();

    return Sprint118BrandLegalAnchor(
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
      brandStatus: _text(brand['status']),
      brandVerdict: _text(brand['verdict']),
      brandExternalGates: _text(brand['external_gates']),
      registeredProviders: registered,
      assetSourceVocabulary: _flatField(brandRecords, 'asset_source'),
      permissionVocabulary: _flatField(brandRecords, 'license_or_permission'),
      trademarkRulesVocabulary: _strings(icon['required_fields']),
      attributionVocabulary: _flatField(creativeRecords, 'attribution'),
      licenseVocabulary: _flatField(creativeRecords, 'license'),
      listingConstraintsVocabulary: <String>[
        if (availability['marketplace_entitlement_verification'] is String)
          availability['marketplace_entitlement_verification'] as String,
      ],
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
  /// so a list of records (`records[].asset_source`) yields its declared
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

/// The fail-closed brand & legal readiness gate for step 118.32.
class Sprint118BrandLegalGate {
  const Sprint118BrandLegalGate();

  Sprint118BrandLegalReport evaluate() => evaluateWith(
    const Sprint118BrandLegalLoader().loadAnchor(),
    Sprint118BrandLegalContract.canonicalRecord,
  );

  Sprint118BrandLegalReport evaluateWith(
    Sprint118BrandLegalAnchor? anchor,
    Sprint118BrandLegalRecord record,
  ) {
    if (anchor == null) {
      return Sprint118BrandLegalReport(
        state: Sprint118BrandLegalState.blocked,
        verdict: 'SPRINT_118_BRAND_LEGAL_READINESS_EVIDENCE_UNREADABLE',
        releaseState: record.releaseState,
        blockers: const <String>['committed_brand_legal_evidence_unreadable'],
        openItems: const <String>['committed_brand_legal_evidence_unreadable'],
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
            Sprint118BrandLegalContract.requiredCharterState ||
        anchor.charterVerdict !=
            Sprint118BrandLegalContract.requiredCharterVerdict) {
      blockers.add('charter_not_complete:${anchor.charterVerdict}');
    }

    // (2) The 118.3 snapshot anchor must be a genuine frozen pass.
    if (anchor.snapshotState !=
            Sprint118BrandLegalContract.requiredSnapshotState ||
        anchor.snapshotVerdict !=
            Sprint118BrandLegalContract.requiredSnapshotVerdict) {
      blockers.add('snapshot_not_frozen:${anchor.snapshotVerdict}');
    }

    // (3) The 117.45 approval gate must record the delay decision, read with the
    // owner's exact grammar. If it is not a delay, the anchor is untrustworthy.
    if (anchor.approvalDecision !=
        Sprint118BrandLegalContract.requiredApprovalDecision) {
      blockers.add('approval_gate_not_delay:${anchor.approvalDecision}');
    }

    // (4) The 116.7 brand asset & icon certification must be a genuine
    // schema-ready fixture, or the brand anchor is untrustworthy.
    if (anchor.brandStatus != Sprint118BrandLegalContract.requiredBrandStatus ||
        anchor.brandVerdict !=
            Sprint118BrandLegalContract.requiredBrandVerdict ||
        anchor.brandExternalGates !=
            Sprint118BrandLegalContract.externalGates) {
      blockers.add(
        'brand_certification_not_schema_ready:${anchor.brandStatus}:'
        '${anchor.brandVerdict}:${anchor.brandExternalGates}',
      );
    }

    // (5) The registered provider set must reconcile across the icon registry,
    // the 116.3 reconciliation, the frozen snapshot, and the charter.
    if (anchor.registeredProviders.length !=
            Sprint118BrandLegalContract.expectedProviderCount ||
        anchor.registryExpectedCount !=
            Sprint118BrandLegalContract.expectedProviderCount ||
        anchor.snapshotRegistered !=
            Sprint118BrandLegalContract.expectedProviderCount ||
        anchor.charterRegisteredProviders !=
            Sprint118BrandLegalContract.expectedProviderCount) {
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
        Sprint118BrandLegalContract.delayedReleaseState) {
      violations.add('brand_legal_not_on_delayed_path:${record.releaseState}');
    }

    final delayed =
        record.releaseState == Sprint118BrandLegalContract.delayedReleaseState;

    // (7) On the delayed path an authorized release execution and an unblocked
    // release are behavior that never ran.
    if (delayed && anchor.executionAuthorized) {
      violations.add('brand_legal_execution_authorized_on_delayed_path');
    }
    if (delayed && !anchor.releaseBlocked) {
      violations.add('brand_legal_release_not_blocked_on_delayed_path');
    }

    // (8) The expansion budget must stay frozen: no new certified connector and
    // no already-certified connector while the release is delayed.
    if (!frozen) {
      violations.add(
        'brand_legal_expansion_budget_not_frozen:max_new='
        '${anchor.charterMaxNewCertified}:'
        'currently=${anchor.charterCurrentlyCertified}',
      );
    }

    // (9) Every registered provider must appear exactly once, and each entry must
    // carry all seven canonical fields non-blank with every output grounded by
    // its committed witness vocabulary.
    final declared = <String, int>{};
    for (final entry in record.entries) {
      declared[entry.providerId] = (declared[entry.providerId] ?? 0) + 1;
    }
    for (final entry in record.entries) {
      final id = entry.providerId;
      if (!anchor.registeredProviders.contains(id)) {
        violations.add('brand_legal_provider_unknown:$id');
      }
      for (final field in Sprint118BrandLegalContract.requiredFields) {
        final value = entry.requiredFields[field] ?? '';
        if (value.trim().isEmpty) {
          violations.add('entry_blank_$field:$id');
        }
      }
      for (final output in Sprint118BrandLegalContract.requiredOutputs) {
        final token = entry.outputFields[output] ?? '';
        final vocabulary = Sprint118BrandLegalContract.vocabularyFor(
          anchor,
          output,
        );
        final grounded =
            token == Sprint118BrandLegalContract.noReferenceState ||
            Sprint118BrandLegalContract.grounds(vocabulary, token);
        if (token.trim().isEmpty || !grounded) {
          violations.add('reference_state_invalid:$output:$id');
        }
        if (token == Sprint118BrandLegalContract.noReferenceState) {
          openItems.add('upstream_state_vocabulary_gap:$output:$id');
        }
      }
      // A provider's logo use is never verified without live brand review.
      if (entry.logoUseApproved) {
        violations.add('brand_legal_logo_use_claimed_on_delayed_path:$id');
      }
      // A provider's naming is never cleared without live brand review.
      if (entry.namingCleared) {
        violations.add('brand_legal_naming_cleared_on_delayed_path:$id');
      }
      // Attribution is never published without live brand review.
      if (entry.attributionPublished) {
        violations.add('brand_legal_attribution_published_on_delayed_path:$id');
      }
      // A license is never granted without live legal review.
      if (entry.licenseGranted) {
        violations.add('brand_legal_license_granted_on_delayed_path:$id');
      }
      // A trademark is never cleared without live legal review.
      if (entry.trademarkCleared) {
        violations.add('brand_legal_trademark_cleared_on_delayed_path:$id');
      }
      // A marketplace listing is never approved without live brand and legal
      // review.
      if (entry.listingApproved) {
        violations.add('brand_legal_listing_approved_on_delayed_path:$id');
      }
      // A provider is never released without an authorized release.
      if (entry.released) {
        violations.add('brand_legal_provider_released_claimed:$id');
      }
    }
    for (final id in declared.keys) {
      if (declared[id]! > 1) {
        violations.add('brand_legal_provider_duplicate:$id');
      }
    }
    for (final id in anchor.registeredProviders) {
      if (!declared.containsKey(id)) {
        violations.add('brand_legal_provider_missing:$id');
      }
    }

    // (10) Every committed evidence source must be readable.
    for (final source in Sprint118BrandLegalContract.witnessSources.toSet()) {
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
      return Sprint118BrandLegalReport(
        state: Sprint118BrandLegalState.blocked,
        verdict: 'SPRINT_118_BRAND_LEGAL_READINESS_BLOCKED_UPSTREAM',
        releaseState: record.releaseState,
        violations: violations,
        blockers: blockers,
        openItems: allItems,
        declaredProviders: providers,
        logoUseApprovedProviders: record.logoUseApprovedProviders,
        listingApprovedProviders: record.listingApprovedProviders,
        logoUseApprovedCount: record.logoUseApprovedCount,
        listingApprovedCount: record.listingApprovedCount,
        expansionBudgetFrozen: frozen,
      );
    }
    if (violations.isNotEmpty) {
      return Sprint118BrandLegalReport(
        state: Sprint118BrandLegalState.fail,
        verdict: 'SPRINT_118_BRAND_LEGAL_READINESS_EVIDENCE_VIOLATION',
        releaseState: record.releaseState,
        violations: violations,
        blockers: blockers,
        openItems: allItems,
        declaredProviders: providers,
        logoUseApprovedProviders: record.logoUseApprovedProviders,
        listingApprovedProviders: record.listingApprovedProviders,
        logoUseApprovedCount: record.logoUseApprovedCount,
        listingApprovedCount: record.listingApprovedCount,
        expansionBudgetFrozen: frozen,
      );
    }
    return Sprint118BrandLegalReport(
      state: Sprint118BrandLegalState.pass,
      verdict: 'BRAND_LEGAL_READINESS_VERIFIED_LOCAL',
      releaseState: record.releaseState,
      openItems: allItems,
      declaredProviders: providers,
      logoUseApprovedProviders: record.logoUseApprovedProviders,
      listingApprovedProviders: record.listingApprovedProviders,
      logoUseApprovedCount: record.logoUseApprovedCount,
      listingApprovedCount: record.listingApprovedCount,
      expansionBudgetFrozen: frozen,
    );
  }
}
