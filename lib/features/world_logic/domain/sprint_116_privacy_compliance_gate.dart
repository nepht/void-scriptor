import 'dart:convert';
import 'dart:io';

/// Outcome of the step 116.46 privacy gate.
enum Sprint116PrivacyGateStatus { pass, fail, blocked }

/// One category of data on its way to a provider, together with the reason it
/// is allowed to go there.
///
/// "The app has an account" is not a lawful basis. A flow without a stated
/// purpose is a flow nobody approved, which is exactly the record that cannot
/// be shown to a regulator or to the user.
class Sprint116DataFlow {
  const Sprint116DataFlow({
    required this.flowId,
    required this.providerId,
    required this.subjectScope,
    required this.dataCategories,
    required this.purpose,
    required this.personalData,
    required this.leavesDevice,
    required this.encryptedInTransit,
    required this.fieldsRedactedInLogs,
    required this.source,
    this.evidenceRef,
  });

  final String flowId;
  final String providerId;

  /// Who the data belongs to. Empty means nobody owns this record.
  final String subjectScope;

  final List<String> dataCategories;

  /// The specific processing reason, e.g. `authenticate_user`.
  final String purpose;

  final bool personalData;

  /// Whether the bytes actually cross the process boundary. A flow marked
  /// personal but not leaving the device still has to be declared, because the
  /// local store is still a processing location.
  final bool leavesDevice;

  final bool encryptedInTransit;

  /// Redaction in logs is what keeps a debug build from becoming a copy of the
  /// user's novel.
  final bool fieldsRedactedInLogs;

  final String source;
  final String? evidenceRef;
}

/// One consent, and the two ways a checkbox stops meaning agreement.
class Sprint116ConsentRecord {
  const Sprint116ConsentRecord({
    required this.consentId,
    required this.subjectId,
    required this.purpose,
    required this.granted,
    required this.bundledOrPreTicked,
    required this.revocable,
    required this.policyVersion,
    required this.grantedAtEpochMs,
    required this.withdrawnAtEpochMs,
    required this.source,
    this.evidenceRef,
  });

  final String consentId;
  final String subjectId;
  final String purpose;

  final bool granted;

  /// Consent that is folded into the click that did something else is not a
  /// separate choice, so it is not agreement.
  final bool bundledOrPreTicked;

  /// Consent you cannot take back is not consent.
  final bool revocable;

  final String policyVersion;

  final int grantedAtEpochMs;
  final int withdrawnAtEpochMs;

  final String source;
  final String? evidenceRef;
}

/// One dataset and the fields it was actually allowed to hold.
class Sprint116MinimizationRecord {
  const Sprint116MinimizationRecord({
    required this.datasetId,
    required this.featurePurpose,
    required this.collectedFields,
    required this.purposeRequiredFields,
    required this.retainedFields,
    required this.source,
    this.evidenceRef,
  });

  final String datasetId;
  final String featurePurpose;

  final List<String> collectedFields;

  /// What the stated purpose actually needs. Anything beyond this is
  /// collection without a reason.
  final List<String> purposeRequiredFields;

  /// What survives to storage. A field that was never collected cannot be
  /// retained; if it appears here, something is keeping a copy the
  /// declaration says does not exist.
  final List<String> retainedFields;

  final String source;
  final String? evidenceRef;
}

/// One place personal data actually lands, and the law that lets it.
class Sprint116Destination {
  const Sprint116Destination({
    required this.destinationId,
    required this.providerId,
    required this.host,
    required this.scheme,
    required this.region,
    required this.dataCategories,
    required this.subprocessorListed,
    required this.crossBorderTransfer,
    required this.transferMechanism,
    required this.personalDataShared,
    required this.source,
    this.evidenceRef,
  });

  final String destinationId;
  final String providerId;
  final String host;
  final String scheme;

  /// Where the data lands legally, not where the server's ping says.
  final String region;

  final List<String> dataCategories;

  /// Sharing with an unlisted processor is sharing with a party the user
  /// never agreed to.
  final bool subprocessorListed;

  final bool crossBorderTransfer;

  /// `none_required` when no transfer leaves the origin region.
  final String transferMechanism;

  final bool personalDataShared;

  final String source;
  final String? evidenceRef;
}

/// One retention promise, and whether the store actually kept it.
class Sprint116RetentionRule {
  const Sprint116RetentionRule({
    required this.retentionId,
    required this.dataCategory,
    required this.retentionDays,
    required this.windowStartedAtEpochMs,
    required this.autoDeleteEnabled,
    required this.deletionTrigger,
    required this.legalHold,
    required this.legalHoldJustification,
    required this.recordPresent,
    required this.source,
    this.evidenceRef,
  });

  final String retentionId;
  final String dataCategory;

  /// Zero is not "keep forever", it is an unconfigured promise.
  final int retentionDays;

  final int windowStartedAtEpochMs;

  final bool autoDeleteEnabled;
  final String deletionTrigger;

  /// A legal hold is legitimate, but only with a written reason attached; an
  /// unjustified hold is indefinite retention with a nicer name.
  final bool legalHold;
  final String legalHoldJustification;

  /// Whether the record is still in the store at the reference clock.
  final bool recordPresent;

  final String source;
  final String? evidenceRef;
}

/// One erasure request, end to end.
class Sprint116DeletionRequest {
  const Sprint116DeletionRequest({
    required this.requestId,
    required this.subjectId,
    required this.scope,
    required this.requestedAtEpochMs,
    required this.completedAtEpochMs,
    required this.completed,
    required this.slaDays,
    required this.identityVerified,
    required this.cascadedToBackups,
    required this.residualCopiesDeclared,
    required this.stillConnected,
    required this.source,
    this.evidenceRef,
  });

  final String requestId;
  final String subjectId;
  final List<String> scope;

  final int requestedAtEpochMs;
  final int completedAtEpochMs;
  final bool completed;

  /// The service window the request committed to.
  final int slaDays;

  /// An erasure endpoint that cannot prove who is asking will happily erase
  /// another user's data.
  final bool identityVerified;

  final bool cascadedToBackups;

  /// Copies that legitimately remain, named. Silent leftovers are the failure
  /// mode; a named residual is the honest version of the same thing.
  final List<String> residualCopiesDeclared;

  /// Claiming erasure while the account is still linked is a contradiction.
  final bool stillConnected;

  final String source;
  final String? evidenceRef;
}

/// One unlink of a provider account.
class Sprint116AccountDisconnect {
  const Sprint116AccountDisconnect({
    required this.disconnectId,
    required this.providerId,
    required this.subjectId,
    required this.tokenRevoked,
    required this.cacheCleared,
    required this.vaultEntryRemoved,
    required this.localProjectDataDeleted,
    required this.cacheReadableAfterDisconnect,
    required this.auditRetainedMinimal,
    required this.source,
    this.evidenceRef,
  });

  final String disconnectId;
  final String providerId;
  final String subjectId;

  final bool tokenRevoked;
  final bool cacheCleared;
  final bool vaultEntryRemoved;

  /// Unlinking a cloud account must not take the user's own work with it.
  /// Over-deletion is still data loss.
  final bool localProjectDataDeleted;

  /// A cache that still answers after unlink means the data never left.
  final bool cacheReadableAfterDisconnect;

  /// Enough of a trail to answer "who unlinked this, and was it the user",
  /// without keeping the payload that was just deleted.
  final bool auditRetainedMinimal;

  final String source;
  final String? evidenceRef;
}

/// One provider's terms, as of the review date.
class Sprint116ProviderTerms {
  const Sprint116ProviderTerms({
    required this.providerId,
    required this.termsVersion,
    required this.reviewedAtEpochMs,
    required this.nextReviewAtEpochMs,
    required this.apiUsePermitted,
    required this.aiTrainingOptOutHonored,
    required this.resaleProhibited,
    required this.sandboxAccountAvailable,
    required this.sandboxAccountUsed,
    required this.regionLimitsDeclared,
    required this.source,
    this.evidenceRef,
  });

  final String providerId;
  final String termsVersion;
  final int reviewedAtEpochMs;

  /// Terms drift. A review that never comes due is a review that stopped
  /// happening, so the gate checks the date rather than the existence of a row.
  final int nextReviewAtEpochMs;

  final bool apiUsePermitted;

  /// Sending a user's manuscript to a provider's training corpus is a
  /// secondary use they did not consent to.
  final bool aiTrainingOptOutHonored;

  final bool resaleProhibited;

  /// The canonical contract requires the test account when one exists.
  final bool sandboxAccountAvailable;
  final bool sandboxAccountUsed;

  final bool regionLimitsDeclared;

  final String source;
  final String? evidenceRef;
}

/// The complete control set the gate certifies.
class Sprint116PrivacyControlSet {
  Sprint116PrivacyControlSet({
    required this.dataFlows,
    required this.consents,
    required this.datasets,
    required this.destinations,
    required this.retentions,
    required this.deletions,
    required this.disconnects,
    required this.termsReviews,
  });

  List<Sprint116DataFlow> dataFlows;
  List<Sprint116ConsentRecord> consents;
  List<Sprint116MinimizationRecord> datasets;
  List<Sprint116Destination> destinations;
  List<Sprint116RetentionRule> retentions;
  List<Sprint116DeletionRequest> deletions;
  List<Sprint116AccountDisconnect> disconnects;
  List<Sprint116ProviderTerms> termsReviews;
}

class Sprint116PrivacyReport {
  Sprint116PrivacyReport({
    required this.state,
    required this.invalidRecords,
    required this.coveredAreas,
    required this.uncoveredPurposes,
    required this.uncertifiedDestinations,
    required this.unretainedCategories,
    required this.unreviewedProviders,
  });

  final Sprint116PrivacyGateStatus state;
  final List<String> invalidRecords;
  final List<String> coveredAreas;

  /// Purposes a live flow performs that no granted consent covers.
  final List<String> uncoveredPurposes;

  /// Data that leaves the device with no declared destination behind it.
  final List<String> uncertifiedDestinations;

  /// Categories in circulation with no retention rule.
  final List<String> unretainedCategories;

  /// Destination providers whose terms were never reviewed.
  final List<String> unreviewedProviders;

  String get externalGates => Sprint116PrivacyContract.externalGates;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'canonical_step': Sprint116PrivacyContract.canonicalStep,
      'state': state.name,
      'invalid_records': invalidRecords,
      'covered_areas': coveredAreas,
      'uncovered_purposes': uncoveredPurposes,
      'uncertified_destinations': uncertifiedDestinations,
      'unretained_categories': unretainedCategories,
      'unreviewed_providers': unreviewedProviders,
      'live_privacy_verification': false,
      'external_gates': externalGates,
    };
  }
}

abstract final class Sprint116PrivacyContract {
  static const String canonicalStep = '116.46';
  static const String manifestPath =
      'docs/planning/v1.2/sprint_116_privacy_compliance_gate.json';
  static const String externalGates = 'DEFERRED-EXTERNAL';

  /// The eight evidence areas canonical step 116.46 requires.
  static const List<String> requiredAreas = <String>[
    'data_flow',
    'consent',
    'minimization',
    'destinations',
    'retention',
    'deletion',
    'disconnect',
    'terms_limits',
  ];

  static const List<String> supportedSources = <String>[
    'synthetic_local',
    'live',
  ];

  /// Categories this product actually handles. An unknown category is an
  /// undeclared one, which is the thing the declaration exists to prevent.
  static const List<String> knownDataCategories = <String>[
    'account_identity',
    'contact',
    'billing',
    'usage_telemetry',
    'creative_content',
  ];

  static const List<String> knownRegions = <String>['us', 'eu', 'apac'];

  /// The mechanisms that can actually carry a cross-border transfer.
  static const List<String> transferMechanisms = <String>[
    'none_required',
    'adequacy_decision',
    'standard_contract_clauses',
    'privacy_shield',
  ];

  /// Purposes a connector may perform. Used to notice a flow whose purpose
  /// nobody has ever consented to.
  static const List<String> knownPurposes = <String>[
    'authenticate_user',
    'process_payment',
    'sync_storage',
    'improve_product',
  ];

  /// Hard ceiling on retention. Beyond this a category is being kept for
  /// convenience, and the promise in the policy is decorative.
  static const int maxRetentionDays = 3650;

  /// Erasure service window the product committed to.
  static const int deletionSlaDays = 30;
}

class Sprint116PrivacyCertificationGate {
  /// Certifies the eight privacy areas of step 116.46.
  ///
  /// Manifest fixtures are consulted only when [controls] is omitted, so an
  /// explicit control set can never borrow fixture data to pass.
  Sprint116PrivacyReport certify({
    Sprint116PrivacyControlSet? controls,
    int? asOfEpochMs,
    bool requireCoverage = false,
  }) {
    // Borrowed only when the caller supplies nothing, so an explicit set can
    // never pass on fixture values it did not send.
    final usedManifest = controls == null;
    final manifest = _readManifest();
    final effective = controls ?? _controlsFromManifest(manifest);
    final effectiveAsOf =
        asOfEpochMs ?? (usedManifest ? _manifestAsOf(manifest) : null);

    if (effectiveAsOf == null || effectiveAsOf <= 0) {
      return _blocked('as_of_epoch_ms');
    }

    final emptySet = <String>[
      if (effective.dataFlows.isEmpty) 'data_flow',
      if (effective.consents.isEmpty) 'consent',
      if (effective.datasets.isEmpty) 'minimization',
      if (effective.destinations.isEmpty) 'destinations',
      if (effective.retentions.isEmpty) 'retention',
      if (effective.deletions.isEmpty) 'deletion',
      if (effective.disconnects.isEmpty) 'disconnect',
      if (effective.termsReviews.isEmpty) 'terms_limits',
    ];
    if (emptySet.isNotEmpty) {
      // Absent controls are not passing controls; an unrun area is a gap.
      return _blocked(emptySet.first);
    }

    final invalid = <String>[];
    final covered = <String>[];
    final retainedCategories = <String>{};

    void collect({
      required String group,
      required int index,
      required String identity,
      required Set<String> failed,
      required Set<String> evidence,
      required String source,
      String? evidenceRef,
    }) {
      if (identity.isEmpty) {
        // Without an identity the record cannot be attributed, so it is
        // rejected on identity alone rather than by guessing a key.
        invalid.add('record_id:$group:$index');
        return;
      }
      for (final area in failed) {
        invalid.add('$area:$identity');
      }
      for (final area in evidence) {
        if (!covered.contains(area)) covered.add(area);
      }
      if (!Sprint116PrivacyContract.supportedSources.contains(source) ||
          (source == 'live' &&
              (evidenceRef == null || evidenceRef.trim().isEmpty))) {
        invalid.add('no_mock_values:$identity');
      }
    }

    for (var index = 0; index < effective.dataFlows.length; index++) {
      final flow = effective.dataFlows[index];
      final failed = <String>{};
      final evidence = <String>{};
      _certifyFlow(flow, failed, evidence);
      collect(
        group: 'data_flow',
        index: index,
        identity: flow.flowId.trim(),
        failed: failed,
        evidence: evidence,
        source: flow.source.trim(),
        evidenceRef: flow.evidenceRef,
      );
    }

    for (var index = 0; index < effective.consents.length; index++) {
      final consent = effective.consents[index];
      final failed = <String>{};
      final evidence = <String>{};
      _certifyConsent(consent, effectiveAsOf, failed, evidence);
      collect(
        group: 'consent',
        index: index,
        identity: consent.consentId.trim(),
        failed: failed,
        evidence: evidence,
        source: consent.source.trim(),
        evidenceRef: consent.evidenceRef,
      );
    }

    for (var index = 0; index < effective.datasets.length; index++) {
      final dataset = effective.datasets[index];
      final failed = <String>{};
      final evidence = <String>{};
      _certifyMinimization(dataset, failed, evidence);
      collect(
        group: 'minimization',
        index: index,
        identity: dataset.datasetId.trim(),
        failed: failed,
        evidence: evidence,
        source: dataset.source.trim(),
        evidenceRef: dataset.evidenceRef,
      );
    }

    for (var index = 0; index < effective.destinations.length; index++) {
      final destination = effective.destinations[index];
      final failed = <String>{};
      final evidence = <String>{};
      _certifyDestination(destination, failed, evidence);
      collect(
        group: 'destination',
        index: index,
        identity: destination.destinationId.trim(),
        failed: failed,
        evidence: evidence,
        source: destination.source.trim(),
        evidenceRef: destination.evidenceRef,
      );
    }

    for (var index = 0; index < effective.retentions.length; index++) {
      final retention = effective.retentions[index];
      final failed = <String>{};
      final evidence = <String>{};
      _certifyRetention(retention, effectiveAsOf, failed, evidence);
      collect(
        group: 'retention',
        index: index,
        identity: retention.retentionId.trim(),
        failed: failed,
        evidence: evidence,
        source: retention.source.trim(),
        evidenceRef: retention.evidenceRef,
      );
      if (failed.isEmpty) {
        retainedCategories.add(retention.dataCategory.trim());
      }
    }

    for (var index = 0; index < effective.deletions.length; index++) {
      final deletion = effective.deletions[index];
      final failed = <String>{};
      final evidence = <String>{};
      _certifyDeletion(deletion, effectiveAsOf, failed, evidence);
      collect(
        group: 'deletion',
        index: index,
        identity: deletion.requestId.trim(),
        failed: failed,
        evidence: evidence,
        source: deletion.source.trim(),
        evidenceRef: deletion.evidenceRef,
      );
    }

    for (var index = 0; index < effective.disconnects.length; index++) {
      final disconnect = effective.disconnects[index];
      final failed = <String>{};
      final evidence = <String>{};
      _certifyDisconnect(disconnect, failed, evidence);
      collect(
        group: 'disconnect',
        index: index,
        identity: disconnect.disconnectId.trim(),
        failed: failed,
        evidence: evidence,
        source: disconnect.source.trim(),
        evidenceRef: disconnect.evidenceRef,
      );
    }

    for (var index = 0; index < effective.termsReviews.length; index++) {
      final terms = effective.termsReviews[index];
      final failed = <String>{};
      final evidence = <String>{};
      _certifyTerms(terms, effectiveAsOf, failed, evidence);
      collect(
        group: 'terms',
        index: index,
        identity: terms.providerId.trim(),
        failed: failed,
        evidence: evidence,
        source: terms.source.trim(),
        evidenceRef: terms.evidenceRef,
      );
    }

    // --- cross-record coverage -------------------------------------------------
    // Each of these joins two groups. A record can be internally flawless and
    // still be unlawful because a second record contradicts it, which is why
    // per-record checks alone are not a privacy gate.

    // A flow may only perform a purpose somebody actually agreed to. A
    // withdrawn consent stops covering; it does not keep covering.
    final grantedPurposes = <String>{};
    for (final consent in effective.consents) {
      if (consent.granted &&
          !consent.bundledOrPreTicked &&
          consent.revocable &&
          consent.subjectId.trim().isNotEmpty &&
          consent.withdrawnAtEpochMs == 0) {
        grantedPurposes.add(consent.purpose.trim());
      }
    }
    final uncoveredPurposes = <String>[];
    for (final flow in effective.dataFlows) {
      if (!flow.leavesDevice || !flow.personalData) continue;
      final purpose = flow.purpose.trim();
      if (purpose.isEmpty || grantedPurposes.contains(purpose)) continue;
      if (!uncoveredPurposes.contains(purpose)) uncoveredPurposes.add(purpose);
    }
    for (final purpose in uncoveredPurposes) {
      invalid.add('consent_coverage:$purpose');
    }

    // Personal data that leaves the device needs a destination that declares
    // its category. A destination existing for some *other* category does not
    // cover this one, so the join is per category rather than per provider.
    final declaredCategories = <String>{};
    for (final destination in effective.destinations) {
      if (!destination.personalDataShared) continue;
      for (final category in destination.dataCategories) {
        final key = category.trim();
        if (key.isNotEmpty) declaredCategories.add(key);
      }
    }
    final uncertifiedDestinations = <String>[];
    for (final flow in effective.dataFlows) {
      if (!flow.leavesDevice) continue;
      for (final category in flow.dataCategories) {
        final key = category.trim();
        if (key.isEmpty || declaredCategories.contains(key)) continue;
        uncertifiedDestinations.add('${flow.flowId.trim()}:$key');
      }
    }
    for (final gap in uncertifiedDestinations) {
      invalid.add('destination_coverage:$gap');
    }

    // Every category actually in circulation needs a retention promise.
    // Retention is declared per category; a dataset's individual field names
    // are a finer granularity the contract does not promise, so they are
    // deliberately not treated as categories here.
    final circulating = <String>{};
    for (final flow in effective.dataFlows) {
      for (final category in flow.dataCategories) {
        final key = category.trim();
        if (key.isNotEmpty) circulating.add(key);
      }
    }
    final unretainedCategories = <String>[];
    for (final category in circulating) {
      if (!retainedCategories.contains(category)) {
        unretainedCategories.add(category);
      }
    }
    for (final category in unretainedCategories) {
      invalid.add('retention_coverage:$category');
    }

    // A destination whose provider terms were never reviewed is an
    // un-reviewed counterparty, not a vetted one. Only counterparties the
    // data actually reaches are covered: a purely local flow has no provider
    // terms to review, and demanding one would be a row nobody can fill
    // honestly.
    final reviewedProviders = <String>{};
    for (final terms in effective.termsReviews) {
      reviewedProviders.add(terms.providerId.trim());
    }
    final destinationProviders = <String>{};
    for (final destination in effective.destinations) {
      final provider = destination.providerId.trim();
      if (provider.isNotEmpty) destinationProviders.add(provider);
    }
    for (final flow in effective.dataFlows) {
      if (!flow.leavesDevice) continue;
      final provider = flow.providerId.trim();
      if (provider.isNotEmpty) destinationProviders.add(provider);
    }
    final unreviewedProviders = <String>[
      for (final provider in destinationProviders)
        if (!reviewedProviders.contains(provider)) provider,
    ];
    for (final provider in unreviewedProviders) {
      invalid.add('terms_coverage:$provider');
    }

    if (requireCoverage) {
      for (final area in Sprint116PrivacyContract.requiredAreas) {
        if (!covered.contains(area)) {
          invalid.add('area_coverage:$area');
        }
      }
    }

    return Sprint116PrivacyReport(
      state: invalid.isEmpty
          ? Sprint116PrivacyGateStatus.pass
          : Sprint116PrivacyGateStatus.fail,
      invalidRecords: invalid,
      coveredAreas: covered,
      uncoveredPurposes: uncoveredPurposes,
      uncertifiedDestinations: uncertifiedDestinations,
      unretainedCategories: unretainedCategories,
      unreviewedProviders: unreviewedProviders,
    );
  }

  void _certifyFlow(
    Sprint116DataFlow flow,
    Set<String> failed,
    Set<String> evidence,
  ) {
    if (flow.providerId.trim().isEmpty || flow.subjectScope.trim().isEmpty) {
      failed.add('data_flow');
      return;
    }
    if (flow.dataCategories.isEmpty) {
      failed.add('data_flow');
      return;
    }
    for (final category in flow.dataCategories) {
      final key = category.trim();
      if (key.isEmpty ||
          !Sprint116PrivacyContract.knownDataCategories.contains(key)) {
        // A category nobody can name is a category nobody is accountable for.
        failed.add('data_flow');
        return;
      }
    }
    // No purpose means no lawful basis. The data is moving regardless.
    final purpose = flow.purpose.trim();
    if (purpose.isEmpty ||
        !Sprint116PrivacyContract.knownPurposes.contains(purpose)) {
      failed.add('data_flow');
      return;
    }
    // In-transit encryption is a property of a flow that actually travels. A
    // purely local project store has no transit, and demanding TLS for it
    // would be a rule that could never be satisfied honestly.
    if (flow.personalData && flow.leavesDevice && !flow.encryptedInTransit) {
      failed.add('data_flow');
      return;
    }
    if (flow.personalData && !flow.fieldsRedactedInLogs) {
      // A debug build that prints a manuscript is a copy nobody tracked.
      failed.add('data_flow');
      return;
    }
    evidence.add('data_flow');
  }

  void _certifyConsent(
    Sprint116ConsentRecord consent,
    int asOfEpochMs,
    Set<String> failed,
    Set<String> evidence,
  ) {
    if (consent.subjectId.trim().isEmpty) {
      failed.add('consent');
      return;
    }
    final purpose = consent.purpose.trim();
    if (purpose.isEmpty ||
        !Sprint116PrivacyContract.knownPurposes.contains(purpose)) {
      failed.add('consent');
      return;
    }
    // Bundled, pre-ticked, or irrevocable: none of these is a separate
    // choice, so none of them is agreement.
    if (consent.bundledOrPreTicked || !consent.revocable) {
      failed.add('consent');
      return;
    }
    if (consent.policyVersion.trim().isEmpty) {
      failed.add('consent');
      return;
    }
    if (consent.grantedAtEpochMs <= 0 ||
        consent.grantedAtEpochMs > asOfEpochMs) {
      // A consent granted in the future is either a clock fault or a
      // pre-filled record, and neither is evidence of agreement.
      failed.add('consent');
      return;
    }
    if (!consent.granted && consent.withdrawnAtEpochMs == 0) {
      // Never granted and never withdrawn is the honest state, but it is not
      // a consent record, so it cannot certify.
      failed.add('consent');
      return;
    }
    if (consent.withdrawnAtEpochMs != 0) {
      if (consent.withdrawnAtEpochMs < consent.grantedAtEpochMs) {
        // Withdrawal predating the grant it claims to cancel is a
        // contradiction, not extra safety.
        failed.add('consent');
        return;
      }
      if (consent.withdrawnAtEpochMs > asOfEpochMs) {
        failed.add('consent');
        return;
      }
    }
    evidence.add('consent');
  }

  void _certifyMinimization(
    Sprint116MinimizationRecord dataset,
    Set<String> failed,
    Set<String> evidence,
  ) {
    if (dataset.featurePurpose.trim().isEmpty) {
      failed.add('minimization');
      return;
    }
    if (dataset.collectedFields.isEmpty ||
        dataset.purposeRequiredFields.isEmpty) {
      failed.add('minimization');
      return;
    }
    for (final field in <String>[
      ...dataset.collectedFields,
      ...dataset.purposeRequiredFields,
    ]) {
      if (field.trim().isEmpty) {
        failed.add('minimization');
        return;
      }
    }
    for (final field in dataset.collectedFields) {
      if (!dataset.purposeRequiredFields.contains(field.trim())) {
        // Collected beyond what the purpose needs is collection without a
        // reason, which is what minimization exists to stop.
        failed.add('minimization');
        return;
      }
    }
    for (final field in dataset.retainedFields) {
      if (field.trim().isEmpty) {
        failed.add('minimization');
        return;
      }
      if (!dataset.collectedFields.contains(field.trim())) {
        // A field nobody collected cannot be retained; if it is named here,
        // something is keeping a copy the declaration denies.
        failed.add('minimization');
        return;
      }
    }
    evidence.add('minimization');
  }

  void _certifyDestination(
    Sprint116Destination destination,
    Set<String> failed,
    Set<String> evidence,
  ) {
    if (destination.providerId.trim().isEmpty ||
        destination.host.trim().isEmpty) {
      failed.add('destinations');
      return;
    }
    if (destination.scheme.trim().toLowerCase() != 'https') {
      // Plaintext leaves the device readable to anything on the path.
      failed.add('destinations');
      return;
    }
    final region = destination.region.trim().toLowerCase();
    if (region.isEmpty ||
        !Sprint116PrivacyContract.knownRegions.contains(region)) {
      // An unnameable jurisdiction is an undeclared one.
      failed.add('destinations');
      return;
    }
    if (destination.personalDataShared && !destination.subprocessorListed) {
      failed.add('destinations');
      return;
    }
    if (destination.crossBorderTransfer) {
      final mechanism = destination.transferMechanism.trim();
      if (mechanism.isEmpty ||
          !Sprint116PrivacyContract.transferMechanisms.contains(mechanism)) {
        // Transferring without a recognized mechanism is the exact gap a
        // transfer-impact assessment is supposed to close.
        failed.add('destinations');
        return;
      }
      if (mechanism == 'none_required') {
        // A cross-border transfer cannot be justified by needing no
        // mechanism.
        failed.add('destinations');
        return;
      }
    } else if (destination.transferMechanism.trim() != 'none_required') {
      // No transfer happened, so a mechanism claim is an unsupported
      // assertion rather than a passing detail.
      failed.add('destinations');
      return;
    }
    evidence.add('destinations');
  }

  void _certifyRetention(
    Sprint116RetentionRule retention,
    int asOfEpochMs,
    Set<String> failed,
    Set<String> evidence,
  ) {
    final category = retention.dataCategory.trim();
    if (category.isEmpty) {
      failed.add('retention');
      return;
    }
    // Zero is an unconfigured promise; over the cap is a promise the product
    // never made.
    if (retention.retentionDays <= 0 ||
        retention.retentionDays > Sprint116PrivacyContract.maxRetentionDays) {
      failed.add('retention');
      return;
    }
    if (retention.windowStartedAtEpochMs <= 0 ||
        retention.windowStartedAtEpochMs > asOfEpochMs) {
      failed.add('retention');
      return;
    }
    if (retention.deletionTrigger.trim().isEmpty) {
      failed.add('retention');
      return;
    }
    if (!retention.autoDeleteEnabled) {
      // Automatic deletion off means retention is a manual promise with no
      // operator behind it.
      failed.add('retention');
      return;
    }
    if (retention.legalHold &&
        retention.legalHoldJustification.trim().isEmpty) {
      // Indefinite retention wearing a legal-hold label.
      failed.add('retention');
      return;
    }
    if (retention.recordPresent) {
      final ageMs = asOfEpochMs - retention.windowStartedAtEpochMs;
      final windowMs = retention.retentionDays * 24 * 60 * 60 * 1000;
      if (ageMs >= windowMs) {
        // Still in the store past its own window: the promise was not kept.
        failed.add('retention');
        return;
      }
    }
    evidence.add('retention');
  }

  void _certifyDeletion(
    Sprint116DeletionRequest deletion,
    int asOfEpochMs,
    Set<String> failed,
    Set<String> evidence,
  ) {
    if (deletion.subjectId.trim().isEmpty || deletion.scope.isEmpty) {
      failed.add('deletion');
      return;
    }
    // Unverified erasure destroys someone else's data just as surely as a
    // verified one preserves the user's own.
    if (!deletion.identityVerified) {
      failed.add('deletion');
      return;
    }
    if (deletion.requestedAtEpochMs <= 0 ||
        deletion.requestedAtEpochMs > asOfEpochMs) {
      failed.add('deletion');
      return;
    }
    if (deletion.completedAtEpochMs != 0 &&
        deletion.completedAtEpochMs < deletion.requestedAtEpochMs) {
      // Completed before it was asked for is a contradiction.
      failed.add('deletion');
      return;
    }
    if (deletion.stillConnected) {
      // Claiming erasure while the account is still linked is the same
      // contradiction wearing different clothes.
      failed.add('deletion');
      return;
    }
    if (!deletion.cascadedToBackups) {
      // Backups are the classic place an "erased" record survives.
      failed.add('deletion');
      return;
    }
    if (!deletion.cascadedToBackups &&
        deletion.residualCopiesDeclared.isEmpty) {
      // Leaving copies behind is legitimate when the copy is *named* — the
      // failure is a leftover nobody can point at. A real cascade needs no
      // residual declaration.
      failed.add('deletion');
      return;
    }
    if (deletion.completed) {
      if (deletion.completedAtEpochMs <= 0 ||
          deletion.completedAtEpochMs > asOfEpochMs) {
        failed.add('deletion');
        return;
      }
    } else {
      // Still open. The only acceptable open state is one still inside its
      // own service window; past that the commitment has been broken.
      final ageMs = asOfEpochMs - deletion.requestedAtEpochMs;
      if (ageMs >= deletion.slaDays * 24 * 60 * 60 * 1000) {
        failed.add('deletion');
        return;
      }
    }
    evidence.add('deletion');
  }

  void _certifyDisconnect(
    Sprint116AccountDisconnect disconnect,
    Set<String> failed,
    Set<String> evidence,
  ) {
    if (disconnect.providerId.trim().isEmpty ||
        disconnect.subjectId.trim().isEmpty) {
      failed.add('disconnect');
      return;
    }
    // Token, cache, and vault are three separate copies; clearing one and
    // calling it unlinked is the usual shape of this failure.
    if (!disconnect.tokenRevoked || !disconnect.cacheCleared) {
      failed.add('disconnect');
      return;
    }
    if (!disconnect.vaultEntryRemoved) {
      failed.add('disconnect');
      return;
    }
    // Over-deletion is still data loss: the manuscript is the user's.
    if (disconnect.localProjectDataDeleted) {
      failed.add('disconnect');
      return;
    }
    if (disconnect.cacheReadableAfterDisconnect) {
      // A cache that still answers means the data never actually left.
      failed.add('disconnect');
      return;
    }
    if (!disconnect.auditRetainedMinimal) {
      // Deleting every trace removes the ability to answer "was this the user,
      // and did they ask" after the fact.
      failed.add('disconnect');
      return;
    }
    evidence.add('disconnect');
  }

  void _certifyTerms(
    Sprint116ProviderTerms terms,
    int asOfEpochMs,
    Set<String> failed,
    Set<String> evidence,
  ) {
    if (terms.termsVersion.trim().isEmpty) {
      failed.add('terms_limits');
      return;
    }
    if (terms.reviewedAtEpochMs <= 0 || terms.reviewedAtEpochMs > asOfEpochMs) {
      failed.add('terms_limits');
      return;
    }
    // Terms drift. A review whose next date has already passed is a review
    // that quietly stopped happening.
    if (terms.nextReviewAtEpochMs <= 0 ||
        terms.nextReviewAtEpochMs <= asOfEpochMs) {
      failed.add('terms_limits');
      return;
    }
    if (!terms.apiUsePermitted) {
      failed.add('terms_limits');
      return;
    }
    if (!terms.aiTrainingOptOutHonored) {
      // Feeding a user's work into a provider's training corpus is a
      // secondary use nobody consented to.
      failed.add('terms_limits');
      return;
    }
    if (!terms.resaleProhibited) {
      failed.add('terms_limits');
      return;
    }
    if (terms.sandboxAccountAvailable && !terms.sandboxAccountUsed) {
      // The canonical contract requires the test account when one exists.
      failed.add('terms_limits');
      return;
    }
    if (!terms.regionLimitsDeclared) {
      failed.add('terms_limits');
      return;
    }
    evidence.add('terms_limits');
  }

  Sprint116PrivacyReport _blocked(String reason) {
    return Sprint116PrivacyReport(
      state: Sprint116PrivacyGateStatus.blocked,
      invalidRecords: <String>[reason],
      coveredAreas: const <String>[],
      uncoveredPurposes: const <String>[],
      uncertifiedDestinations: const <String>[],
      unretainedCategories: const <String>[],
      unreviewedProviders: const <String>[],
    );
  }

  Map<String, dynamic>? _readManifest() {
    final file = File(Sprint116PrivacyContract.manifestPath);
    if (!file.existsSync()) return null;
    try {
      final decoded = jsonDecode(file.readAsStringSync());
      return decoded is Map<String, dynamic> ? decoded : null;
    } on FormatException {
      return null;
    }
  }

  int? _manifestAsOf(Map<String, dynamic>? manifest) {
    final raw = manifest?['as_of_epoch_ms'];
    return raw is num ? raw.toInt() : null;
  }

  Sprint116PrivacyControlSet _controlsFromManifest(
    Map<String, dynamic>? manifest,
  ) {
    return Sprint116PrivacyControlSet(
      dataFlows: _mapList(manifest, 'data_flows', _flowFromManifest),
      consents: _mapList(manifest, 'consents', _consentFromManifest),
      datasets: _mapList(manifest, 'datasets', _datasetFromManifest),
      destinations: _mapList(
        manifest,
        'destinations',
        _destinationFromManifest,
      ),
      retentions: _mapList(manifest, 'retention_rules', _retentionFromManifest),
      deletions: _mapList(manifest, 'deletion_requests', _deletionFromManifest),
      disconnects: _mapList(manifest, 'disconnects', _disconnectFromManifest),
      termsReviews: _mapList(manifest, 'provider_terms', _termsFromManifest),
    );
  }

  List<T> _mapList<T>(
    Map<String, dynamic>? manifest,
    String key,
    T Function(Map<Object?, Object?> item) build,
  ) {
    if (manifest == null) return <T>[];
    final raw = manifest[key];
    if (raw is! List) return <T>[];
    return raw.whereType<Map>().map(build).toList(growable: false);
  }

  List<String> _stringList(Object? raw) {
    if (raw is! List) return const <String>[];
    return raw.map((item) => item?.toString() ?? '').toList(growable: false);
  }

  int _int(Object? raw) => (raw as num?)?.toInt() ?? 0;

  Sprint116DataFlow _flowFromManifest(Map<Object?, Object?> item) {
    return Sprint116DataFlow(
      flowId: item['flow_id']?.toString() ?? '',
      providerId: item['provider_id']?.toString() ?? '',
      subjectScope: item['subject_scope']?.toString() ?? '',
      dataCategories: _stringList(item['data_categories']),
      purpose: item['purpose']?.toString() ?? '',
      personalData: item['personal_data'] == true,
      leavesDevice: item['leaves_device'] == true,
      encryptedInTransit: item['encrypted_in_transit'] == true,
      fieldsRedactedInLogs: item['fields_redacted_in_logs'] == true,
      source: item['source']?.toString() ?? '',
      evidenceRef: item['evidence_ref']?.toString(),
    );
  }

  Sprint116ConsentRecord _consentFromManifest(Map<Object?, Object?> item) {
    return Sprint116ConsentRecord(
      consentId: item['consent_id']?.toString() ?? '',
      subjectId: item['subject_id']?.toString() ?? '',
      purpose: item['purpose']?.toString() ?? '',
      granted: item['granted'] == true,
      bundledOrPreTicked: item['bundled_or_pre_ticked'] == true,
      revocable: item['revocable'] == true,
      policyVersion: item['policy_version']?.toString() ?? '',
      grantedAtEpochMs: _int(item['granted_at_epoch_ms']),
      withdrawnAtEpochMs: _int(item['withdrawn_at_epoch_ms']),
      source: item['source']?.toString() ?? '',
      evidenceRef: item['evidence_ref']?.toString(),
    );
  }

  Sprint116MinimizationRecord _datasetFromManifest(Map<Object?, Object?> item) {
    return Sprint116MinimizationRecord(
      datasetId: item['dataset_id']?.toString() ?? '',
      featurePurpose: item['feature_purpose']?.toString() ?? '',
      collectedFields: _stringList(item['collected_fields']),
      purposeRequiredFields: _stringList(item['purpose_required_fields']),
      retainedFields: _stringList(item['retained_fields']),
      source: item['source']?.toString() ?? '',
      evidenceRef: item['evidence_ref']?.toString(),
    );
  }

  Sprint116Destination _destinationFromManifest(Map<Object?, Object?> item) {
    return Sprint116Destination(
      destinationId: item['destination_id']?.toString() ?? '',
      providerId: item['provider_id']?.toString() ?? '',
      host: item['host']?.toString() ?? '',
      scheme: item['scheme']?.toString() ?? '',
      region: item['region']?.toString() ?? '',
      dataCategories: _stringList(item['data_categories']),
      subprocessorListed: item['subprocessor_listed'] == true,
      crossBorderTransfer: item['cross_border_transfer'] == true,
      transferMechanism: item['transfer_mechanism']?.toString() ?? '',
      personalDataShared: item['personal_data_shared'] == true,
      source: item['source']?.toString() ?? '',
      evidenceRef: item['evidence_ref']?.toString(),
    );
  }

  Sprint116RetentionRule _retentionFromManifest(Map<Object?, Object?> item) {
    return Sprint116RetentionRule(
      retentionId: item['retention_id']?.toString() ?? '',
      dataCategory: item['data_category']?.toString() ?? '',
      retentionDays: _int(item['retention_days']),
      windowStartedAtEpochMs: _int(item['window_started_at_epoch_ms']),
      autoDeleteEnabled: item['auto_delete_enabled'] == true,
      deletionTrigger: item['deletion_trigger']?.toString() ?? '',
      legalHold: item['legal_hold'] == true,
      legalHoldJustification:
          item['legal_hold_justification']?.toString() ?? '',
      recordPresent: item['record_present'] == true,
      source: item['source']?.toString() ?? '',
      evidenceRef: item['evidence_ref']?.toString(),
    );
  }

  Sprint116DeletionRequest _deletionFromManifest(Map<Object?, Object?> item) {
    return Sprint116DeletionRequest(
      requestId: item['request_id']?.toString() ?? '',
      subjectId: item['subject_id']?.toString() ?? '',
      scope: _stringList(item['scope']),
      requestedAtEpochMs: _int(item['requested_at_epoch_ms']),
      completedAtEpochMs: _int(item['completed_at_epoch_ms']),
      completed: item['completed'] == true,
      slaDays: _int(item['sla_days']),
      identityVerified: item['identity_verified'] == true,
      cascadedToBackups: item['cascaded_to_backups'] == true,
      residualCopiesDeclared: _stringList(item['residual_copies_declared']),
      stillConnected: item['still_connected'] == true,
      source: item['source']?.toString() ?? '',
      evidenceRef: item['evidence_ref']?.toString(),
    );
  }

  Sprint116AccountDisconnect _disconnectFromManifest(
    Map<Object?, Object?> item,
  ) {
    return Sprint116AccountDisconnect(
      disconnectId: item['disconnect_id']?.toString() ?? '',
      providerId: item['provider_id']?.toString() ?? '',
      subjectId: item['subject_id']?.toString() ?? '',
      tokenRevoked: item['token_revoked'] == true,
      cacheCleared: item['cache_cleared'] == true,
      vaultEntryRemoved: item['vault_entry_removed'] == true,
      localProjectDataDeleted: item['local_project_data_deleted'] == true,
      cacheReadableAfterDisconnect:
          item['cache_readable_after_disconnect'] == true,
      auditRetainedMinimal: item['audit_retained_minimal'] == true,
      source: item['source']?.toString() ?? '',
      evidenceRef: item['evidence_ref']?.toString(),
    );
  }

  Sprint116ProviderTerms _termsFromManifest(Map<Object?, Object?> item) {
    return Sprint116ProviderTerms(
      providerId: item['provider_id']?.toString() ?? '',
      termsVersion: item['terms_version']?.toString() ?? '',
      reviewedAtEpochMs: _int(item['reviewed_at_epoch_ms']),
      nextReviewAtEpochMs: _int(item['next_review_at_epoch_ms']),
      apiUsePermitted: item['api_use_permitted'] == true,
      aiTrainingOptOutHonored: item['ai_training_opt_out_honored'] == true,
      resaleProhibited: item['resale_prohibited'] == true,
      sandboxAccountAvailable: item['sandbox_account_available'] == true,
      sandboxAccountUsed: item['sandbox_account_used'] == true,
      regionLimitsDeclared: item['region_limits_declared'] == true,
      source: item['source']?.toString() ?? '',
      evidenceRef: item['evidence_ref']?.toString(),
    );
  }
}
