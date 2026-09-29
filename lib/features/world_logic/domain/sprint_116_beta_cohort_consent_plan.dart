library;

import 'dart:convert';
import 'dart:io';

/// Canonical contract for Sprint 116.49, Beta Cohort & Consent Plan.
///
/// A beta plan is easy to fake in two independent ways: promise consent and
/// data boundaries for providers nobody selected, or select cohorts and name
/// participants that were never enrolled. Both are caught here as joins
/// instead of prose: every beta-path provider needs a consent record that
/// actually exists, every selected cohort needs a consent design aimed at it,
/// every device-egress category needs consent and a withdrawal path, and any
/// count of real people or any `live` claim must resolve to an artifact in
/// the evidence register.
///
/// Every fixture shipped with this contract is synthetic and UNVERIFIED. No
/// participant, credential, or provider availability is asserted here.
enum Sprint116BetaPlanStatus { pass, fail, blocked }

/// One cohort the plan proposes. Metadata only — [enrolledCount] above zero
/// from a synthetic source is a fabricated participant list.
class Sprint116BetaSelectionRecord {
  Sprint116BetaSelectionRecord({
    required this.cohortId,
    required this.criteria,
    required this.selectionMethod,
    required this.targetSize,
    required this.enrolledCount,
    required this.source,
    required this.evidenceRef,
  });

  final String cohortId;
  final List<String> criteria;
  final String selectionMethod;
  final int targetSize;
  final int enrolledCount;
  final String source;
  final String? evidenceRef;
}

/// Which provider is in the beta, at which commitment stage, and which
/// consent record governs it.
class Sprint116BetaProviderCoverageRecord {
  Sprint116BetaProviderCoverageRecord({
    required this.providerId,
    required this.connectorId,
    required this.stage,
    required this.reason,
    required this.consentRef,
    required this.source,
    required this.evidenceRef,
  });

  final String providerId;
  final String connectorId;
  final String stage;
  final String reason;
  final String consentRef;
  final String source;
  final String? evidenceRef;
}

/// Consent aimed at one cohort, per purpose, with the data categories it
/// actually covers.
class Sprint116BetaConsentRecord {
  Sprint116BetaConsentRecord({
    required this.consentId,
    required this.cohortId,
    required this.purposes,
    required this.coveredCategories,
    required this.explicitOptIn,
    required this.policyVersion,
    required this.participantId,
    required this.grantedAtEpochMs,
    required this.source,
    required this.evidenceRef,
  });

  final String consentId;
  final String cohortId;
  final List<String> purposes;
  final List<String> coveredCategories;
  final bool explicitOptIn;
  final String policyVersion;
  final String participantId;
  final int grantedAtEpochMs;
  final String source;
  final String? evidenceRef;
}

/// Where one data category goes and how long it is kept.
class Sprint116BetaDataBoundaryRecord {
  Sprint116BetaDataBoundaryRecord({
    required this.boundaryId,
    required this.category,
    required this.leavesDevice,
    required this.destination,
    required this.encryptionInTransit,
    required this.retentionDays,
    required this.source,
    required this.evidenceRef,
  });

  final String boundaryId;
  final String category;
  final bool leavesDevice;
  final String destination;
  final bool encryptionInTransit;
  final int retentionDays;
  final String source;
  final String? evidenceRef;
}

/// The support channel beta participants can actually reach.
class Sprint116BetaSupportRecord {
  Sprint116BetaSupportRecord({
    required this.supportId,
    required this.channel,
    required this.scope,
    required this.responseSlaHours,
    required this.escalationPath,
    required this.source,
    required this.evidenceRef,
  });

  final String supportId;
  final String channel;
  final String scope;
  final int responseSlaHours;
  final String escalationPath;
  final String source;
  final String? evidenceRef;
}

/// How a participant gets out, within what deadline, and what it must not
/// touch: withdrawal deletes beta participation data, never local project
/// data — the manuscript belongs to the user.
class Sprint116BetaWithdrawalRecord {
  Sprint116BetaWithdrawalRecord({
    required this.withdrawalId,
    required this.mechanism,
    required this.deadlineDays,
    required this.coveredCategories,
    required this.localProjectDataDeleted,
    required this.noPenalty,
    required this.source,
    required this.evidenceRef,
  });

  final String withdrawalId;
  final String mechanism;
  final int deadlineDays;
  final List<String> coveredCategories;
  final bool localProjectDataDeleted;
  final bool noPenalty;
  final String source;
  final String? evidenceRef;
}

/// One registered artifact backing a claim.
class Sprint116BetaEvidenceRecord {
  Sprint116BetaEvidenceRecord({
    required this.evidenceId,
    required this.claim,
    required this.artifact,
    required this.recordedAtEpochMs,
    required this.source,
    required this.evidenceRef,
  });

  final String evidenceId;
  final String claim;
  final String artifact;
  final int recordedAtEpochMs;
  final String source;
  final String? evidenceRef;
}

class Sprint116BetaPlanControlSet {
  Sprint116BetaPlanControlSet({
    required this.selection,
    required this.providerCoverage,
    required this.consent,
    required this.dataBoundaries,
    required this.support,
    required this.withdrawal,
    required this.evidence,
  });

  final List<Sprint116BetaSelectionRecord> selection;
  final List<Sprint116BetaProviderCoverageRecord> providerCoverage;
  final List<Sprint116BetaConsentRecord> consent;
  final List<Sprint116BetaDataBoundaryRecord> dataBoundaries;
  final List<Sprint116BetaSupportRecord> support;
  final List<Sprint116BetaWithdrawalRecord> withdrawal;
  final List<Sprint116BetaEvidenceRecord> evidence;
}

class Sprint116BetaPlanReport {
  Sprint116BetaPlanReport({
    required this.state,
    required this.invalidRecords,
    required this.coveredFields,
  });

  final Sprint116BetaPlanStatus state;
  final List<String> invalidRecords;

  /// Required fields that carry at least one record with no rule failure and
  /// a supportable source. The rest are gaps, not passes.
  final List<String> coveredFields;

  String get externalGates => Sprint116BetaCohortContract.externalGates;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'canonical_step': Sprint116BetaCohortContract.canonicalStep,
      'state': state.name,
      'invalid_records': invalidRecords,
      'covered_fields': coveredFields,
      'live_beta_execution': false,
      'no_fabricated_participants': true,
      'external_gates': externalGates,
    };
  }
}

abstract final class Sprint116BetaCohortContract {
  static const String canonicalStep = '116.49';
  static const String manifestPath =
      'docs/planning/v1.2/sprint_116_beta_cohort_consent_plan.json';
  static const String externalGates = 'DEFERRED-EXTERNAL';

  /// The seven fields canonical step 116.49 names, in canonical order.
  static const List<String> requiredFields = <String>[
    'selection',
    'provider_coverage',
    'consent',
    'data_boundaries',
    'support',
    'withdrawal',
    'evidence',
  ];

  static const List<String> supportedSources = <String>[
    'synthetic_local',
    'live',
    'local_run',
  ];

  /// Sources that may only be believed when they point at a registered
  /// evidence artifact.
  static const List<String> evidencedSources = <String>['live', 'local_run'];

  static const List<String> knownSelectionMethods = <String>[
    'invite_only',
    'open_application',
    'waitlist_transfer',
    'internal_nomination',
  ];

  /// Every commitment stage the plan may declare for a provider.
  static const List<String> knownCoverageStages = <String>[
    'committed',
    'planned',
    'deferred',
    'excluded',
  ];

  /// Stages that will touch participants: consent and support have to exist
  /// before enrolment, not after the first complaint.
  static const List<String> betaPathStages = <String>['committed', 'planned'];

  static const List<String> knownPurposes = <String>[
    'ai_inference',
    'sync_backup',
    'analytics',
    'beta_feedback',
    'identity_link',
  ];

  static const List<String> knownDataCategories = <String>[
    'novel_text',
    'character_data',
    'lore_entries',
    'project_metadata',
    'usage_telemetry',
    'account_profile',
    'connector_tokens',
  ];

  static const List<String> knownSupportChannels = <String>[
    'in_app',
    'email',
    'issue_tracker',
    'forum',
  ];

  static const List<String> knownWithdrawalMechanisms = <String>[
    'in_app_settings',
    'email_request',
    'support_ticket',
  ];

  /// A support promise slower than a week is the absence of support.
  static const int maxResponseSlaHours = 168;

  static const int minRetentionDays = 1;
  static const int maxRetentionDays = 3650;

  /// A withdrawal that needs longer than a month to take effect is a
  /// withdrawal nobody can act on.
  static const int maxWithdrawalDeadlineDays = 30;
}

class Sprint116BetaCohortPlan {
  /// Certifies the seven fields of step 116.49.
  ///
  /// The manifest fixture is consulted only when [controls] is omitted, so an
  /// explicit control set can never borrow fixture rows to pass.
  Sprint116BetaPlanReport certify({
    Sprint116BetaPlanControlSet? controls,
    int? asOfEpochMs,
    bool requireCoverage = false,
  }) {
    final usedManifest = controls == null;
    final manifest = _readManifest();
    final effective = controls ?? _controlsFromManifest(manifest);
    final effectiveAsOf =
        asOfEpochMs ?? (usedManifest ? _manifestAsOf(manifest) : null);

    if (effectiveAsOf == null || effectiveAsOf <= 0) {
      return _blocked('as_of_epoch_ms');
    }

    // An unrun field is a gap, not a pass. Naming it first keeps the report
    // honest about what was never attempted.
    final emptyFields = <String>[
      if (effective.selection.isEmpty) 'selection',
      if (effective.providerCoverage.isEmpty) 'provider_coverage',
      if (effective.consent.isEmpty) 'consent',
      if (effective.dataBoundaries.isEmpty) 'data_boundaries',
      if (effective.support.isEmpty) 'support',
      if (effective.withdrawal.isEmpty) 'withdrawal',
      if (effective.evidence.isEmpty) 'evidence',
    ];
    if (emptyFields.isNotEmpty) {
      return _blocked(emptyFields.first);
    }

    final invalid = <String>[];
    final covered = <String>{};

    final evidenceArtifacts = <String>{
      for (final row in effective.evidence) row.artifact.trim(),
    };

    // Generic per-record checks: identity, field rules, source honesty, and
    // whether a live claim resolves to a registered artifact.
    void run({
      required String field,
      required String identity,
      required Set<String> failures,
      required String source,
      required String? evidenceRef,
    }) {
      final key = identity.trim();
      if (key.isEmpty) {
        // Without an identity the row cannot be attributed, so it is
        // rejected on identity alone rather than by guessing a key.
        invalid.add('record_id:$field');
        return;
      }
      for (final failure in failures) {
        invalid.add('$failure:$key');
      }
      final trimmedSource = source.trim();
      var sourceClean = true;
      if (!Sprint116BetaCohortContract.supportedSources.contains(
        trimmedSource,
      )) {
        invalid.add('no_mock_values:$key');
        sourceClean = false;
      } else if (Sprint116BetaCohortContract.evidencedSources.contains(
            trimmedSource,
          ) &&
          (evidenceRef == null || evidenceRef.trim().isEmpty)) {
        invalid.add('no_mock_values:$key');
        sourceClean = false;
      }
      var registerClean = true;
      if (Sprint116BetaCohortContract.evidencedSources.contains(
            trimmedSource,
          ) &&
          evidenceRef != null &&
          evidenceRef.trim().isNotEmpty &&
          !evidenceArtifacts.contains(evidenceRef.trim())) {
        // A pointer into thin air is not evidence. The artifact has to be
        // registered in this plan's own evidence group.
        invalid.add('evidence_register:$field:$key');
        registerClean = false;
      }
      if (failures.isEmpty && sourceClean && registerClean) {
        covered.add(field);
      }
    }

    for (final record in effective.selection) {
      final failures = <String>{};
      _certifySelection(record, failures);
      run(
        field: 'selection',
        identity: record.cohortId,
        failures: failures,
        source: record.source,
        evidenceRef: record.evidenceRef,
      );
    }

    for (final record in effective.providerCoverage) {
      final failures = <String>{};
      _certifyCoverage(record, failures);
      run(
        field: 'provider_coverage',
        identity: record.providerId,
        failures: failures,
        source: record.source,
        evidenceRef: record.evidenceRef,
      );
    }

    for (final record in effective.consent) {
      final failures = <String>{};
      _certifyConsent(record, effectiveAsOf, failures);
      run(
        field: 'consent',
        identity: record.consentId,
        failures: failures,
        source: record.source,
        evidenceRef: record.evidenceRef,
      );
    }

    for (final record in effective.dataBoundaries) {
      final failures = <String>{};
      _certifyBoundary(record, failures);
      run(
        field: 'data_boundaries',
        identity: record.boundaryId,
        failures: failures,
        source: record.source,
        evidenceRef: record.evidenceRef,
      );
    }

    for (final record in effective.support) {
      final failures = <String>{};
      _certifySupport(record, failures);
      run(
        field: 'support',
        identity: record.supportId,
        failures: failures,
        source: record.source,
        evidenceRef: record.evidenceRef,
      );
    }

    for (final record in effective.withdrawal) {
      final failures = <String>{};
      _certifyWithdrawal(record, failures);
      run(
        field: 'withdrawal',
        identity: record.withdrawalId,
        failures: failures,
        source: record.source,
        evidenceRef: record.evidenceRef,
      );
    }

    for (final record in effective.evidence) {
      final failures = <String>{};
      _certifyEvidence(record, effectiveAsOf, failures);
      run(
        field: 'evidence',
        identity: record.evidenceId,
        failures: failures,
        source: record.source,
        evidenceRef: record.evidenceRef,
      );
    }

    invalid.addAll(_crossRecordJoins(effective));

    if (requireCoverage) {
      for (final field in Sprint116BetaCohortContract.requiredFields) {
        if (!covered.contains(field)) {
          invalid.add('area_coverage:$field');
        }
      }
    }

    final coveredFields = Sprint116BetaCohortContract.requiredFields
        .where(covered.contains)
        .toList(growable: false);
    return Sprint116BetaPlanReport(
      state: invalid.isEmpty
          ? Sprint116BetaPlanStatus.pass
          : Sprint116BetaPlanStatus.fail,
      invalidRecords: invalid.toList(growable: false),
      coveredFields: coveredFields,
    );
  }

  void _certifySelection(
    Sprint116BetaSelectionRecord record,
    Set<String> failed,
  ) {
    final criteria = record.criteria;
    if (criteria.isEmpty ||
        criteria.any((criterion) => criterion.trim().isEmpty)) {
      // A criterion list with a blank entry admits "anyone", which is not a
      // selection rule at all.
      failed.add('selection_criteria');
    }
    if (!Sprint116BetaCohortContract.knownSelectionMethods.contains(
      record.selectionMethod.trim(),
    )) {
      failed.add('selection_method');
    }
    if (record.targetSize <= 0) {
      // A cohort that may hold nobody is not a cohort.
      failed.add('selection_target');
    }
    if (record.enrolledCount > record.targetSize) {
      failed.add('selection_enrolled');
    }
    if (record.enrolledCount > 0 &&
        !Sprint116BetaCohortContract.evidencedSources.contains(
          record.source.trim(),
        )) {
      // Real people cannot be enumerated from a synthetic fixture. This is
      // the no-fabricated-participant policy of the canonical step.
      failed.add('fabricated_participants');
    }
  }

  void _certifyCoverage(
    Sprint116BetaProviderCoverageRecord record,
    Set<String> failed,
  ) {
    if (record.connectorId.trim().isEmpty) {
      // A provider row without a connector names no integration surface.
      failed.add('coverage_connector');
    }
    if (!Sprint116BetaCohortContract.knownCoverageStages.contains(
      record.stage.trim(),
    )) {
      failed.add('coverage_stage');
    } else if (!Sprint116BetaCohortContract.betaPathStages.contains(
          record.stage.trim(),
        ) &&
        record.reason.trim().isEmpty) {
      // A provider the plan sets aside has to say why, or "deferred" is a
      // silent drop.
      failed.add('coverage_reason');
    }
  }

  void _certifyConsent(
    Sprint116BetaConsentRecord record,
    int asOfEpochMs,
    Set<String> failed,
  ) {
    if (record.purposes.isEmpty ||
        record.purposes.any(
          (purpose) => !Sprint116BetaCohortContract.knownPurposes.contains(
            purpose.trim(),
          ),
        )) {
      failed.add('consent_purpose');
    }
    if (record.coveredCategories.isEmpty ||
        record.coveredCategories.any(
          (category) => !Sprint116BetaCohortContract.knownDataCategories
              .contains(category.trim()),
        )) {
      failed.add('consent_category');
    }
    if (!record.explicitOptIn) {
      // Bundled or pre-ticked consent is not consent.
      failed.add('consent_explicit');
    }
    if (record.policyVersion.trim().isEmpty) {
      // Nothing to withdraw against: consent without a policy version has no
      // identifiable terms.
      failed.add('consent_policy');
    }
    if (record.grantedAtEpochMs <= 0 || record.grantedAtEpochMs > asOfEpochMs) {
      failed.add('consent_timing');
    }
    if (record.participantId.trim().isNotEmpty &&
        !Sprint116BetaCohortContract.evidencedSources.contains(
          record.source.trim(),
        )) {
      // A named participant backed only by a fixture is fabricated.
      failed.add('fabricated_consent');
    }
  }

  void _certifyBoundary(
    Sprint116BetaDataBoundaryRecord record,
    Set<String> failed,
  ) {
    if (!Sprint116BetaCohortContract.knownDataCategories.contains(
      record.category.trim(),
    )) {
      failed.add('boundary_category');
    }
    if (record.leavesDevice) {
      if (!record.encryptionInTransit) {
        failed.add('boundary_encryption');
      }
      if (record.destination.trim().isEmpty) {
        // Data that leaves the device with nowhere named is unaccounted for.
        failed.add('boundary_destination');
      }
    } else if (record.destination.trim().isNotEmpty) {
      // Local-only data with a destination is a contradiction: either the
      // boundary is wrong or the destination is.
      failed.add('boundary_local_destination');
    }
    if (record.retentionDays < Sprint116BetaCohortContract.minRetentionDays ||
        record.retentionDays > Sprint116BetaCohortContract.maxRetentionDays) {
      failed.add('boundary_retention');
    }
  }

  void _certifySupport(Sprint116BetaSupportRecord record, Set<String> failed) {
    if (!Sprint116BetaCohortContract.knownSupportChannels.contains(
      record.channel.trim(),
    )) {
      failed.add('support_channel');
    }
    if (record.scope.trim().isEmpty) {
      failed.add('support_scope');
    }
    if (record.responseSlaHours <= 0 ||
        record.responseSlaHours >
            Sprint116BetaCohortContract.maxResponseSlaHours) {
      failed.add('support_sla');
    }
    if (record.escalationPath.trim().isEmpty) {
      failed.add('support_escalation');
    }
  }

  void _certifyWithdrawal(
    Sprint116BetaWithdrawalRecord record,
    Set<String> failed,
  ) {
    if (!Sprint116BetaCohortContract.knownWithdrawalMechanisms.contains(
      record.mechanism.trim(),
    )) {
      failed.add('withdrawal_mechanism');
    }
    if (record.deadlineDays < 0 ||
        record.deadlineDays >
            Sprint116BetaCohortContract.maxWithdrawalDeadlineDays) {
      failed.add('withdrawal_deadline');
    }
    if (record.coveredCategories.isEmpty ||
        record.coveredCategories.any(
          (category) => !Sprint116BetaCohortContract.knownDataCategories
              .contains(category.trim()),
        )) {
      failed.add('withdrawal_category');
    }
    if (record.localProjectDataDeleted) {
      // Over-deletion still loses data: the manuscript belongs to the user
      // and survives any beta withdrawal.
      failed.add('withdrawal_local_data');
    }
    if (!record.noPenalty) {
      failed.add('withdrawal_penalty');
    }
  }

  void _certifyEvidence(
    Sprint116BetaEvidenceRecord record,
    int asOfEpochMs,
    Set<String> failed,
  ) {
    if (record.claim.trim().isEmpty) {
      failed.add('evidence_claim');
    }
    if (record.artifact.trim().isEmpty) {
      failed.add('evidence_artifact');
    }
    if (record.recordedAtEpochMs <= 0 ||
        record.recordedAtEpochMs > asOfEpochMs) {
      // Evidence from the future describes an audit that has not happened.
      failed.add('evidence_time');
    }
  }

  /// Joins that a record cannot refute on its own: a provider selected
  /// without consent, a cohort without consent, egress without consent or
  /// withdrawal coverage, and support that does not reach the provider.
  List<String> _crossRecordJoins(Sprint116BetaPlanControlSet controls) {
    final invalid = <String>[];

    final consentIds = <String>{
      for (final row in controls.consent) row.consentId.trim(),
    };
    final cohortIds = <String>{
      for (final row in controls.selection) row.cohortId.trim(),
    }..remove('');
    final consentCohorts = <String>{
      for (final row in controls.consent) row.cohortId.trim(),
    }..remove('');
    final consentCategories = <String>{
      for (final row in controls.consent)
        ...row.coveredCategories.map((c) => c.trim()),
    };
    final withdrawalCategories = <String>{
      for (final row in controls.withdrawal)
        ...row.coveredCategories.map((c) => c.trim()),
    };
    final supportCovers = <String, bool>{
      for (final row in controls.support) row.scope.trim(): true,
    };

    for (final row in controls.providerCoverage) {
      final providerId = row.providerId.trim();
      if (providerId.isEmpty) continue;
      if (!Sprint116BetaCohortContract.betaPathStages.contains(
        row.stage.trim(),
      )) {
        continue;
      }
      final consentRef = row.consentRef.trim();
      if (consentRef.isEmpty || !consentIds.contains(consentRef)) {
        // The plan puts a provider on the beta path while its consent design
        // does not exist.
        invalid.add('consent_coverage:$providerId');
      }
      if (!supportCovers.containsKey('beta_global') &&
          !supportCovers.containsKey(providerId)) {
        invalid.add('support_coverage:$providerId');
      }
    }

    for (final row in controls.consent) {
      final consentId = row.consentId.trim();
      if (consentId.isEmpty) continue;
      final cohortId = row.cohortId.trim();
      if (cohortId.isEmpty || !cohortIds.contains(cohortId)) {
        // Consent aimed at a cohort the plan never selected is phantom
        // consent.
        invalid.add('consent_cohort:$consentId');
      }
    }

    for (final cohortId in cohortIds) {
      if (!consentCohorts.contains(cohortId)) {
        invalid.add('cohort_consent:$cohortId');
      }
    }

    for (final row in controls.dataBoundaries) {
      final boundaryId = row.boundaryId.trim();
      if (boundaryId.isEmpty) continue;
      if (row.leavesDevice &&
          !consentCategories.contains(row.category.trim())) {
        // Data leaves the device under no consent design.
        invalid.add('boundary_consent:$boundaryId');
      }
    }

    final uncoveredCategories = <String>{};
    for (final row in controls.dataBoundaries) {
      final category = row.category.trim();
      if (category.isEmpty) continue;
      if (!withdrawalCategories.contains(category)) {
        uncoveredCategories.add(category);
      }
    }
    for (final category in uncoveredCategories.toList()..sort()) {
      // A category with no way out is kept regardless of what the
      // participant was promised.
      invalid.add('withdrawal_coverage:$category');
    }

    return invalid;
  }

  Sprint116BetaPlanReport _blocked(String reason) {
    return Sprint116BetaPlanReport(
      state: Sprint116BetaPlanStatus.blocked,
      invalidRecords: <String>[reason],
      coveredFields: const <String>[],
    );
  }

  Map<String, dynamic>? _readManifest() {
    final file = File(Sprint116BetaCohortContract.manifestPath);
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

  Sprint116BetaPlanControlSet _controlsFromManifest(
    Map<String, dynamic>? manifest,
  ) {
    return Sprint116BetaPlanControlSet(
      selection: _mapList(manifest, 'selection', _selectionFrom),
      providerCoverage: _mapList(manifest, 'provider_coverage', _coverageFrom),
      consent: _mapList(manifest, 'consent', _consentFrom),
      dataBoundaries: _mapList(manifest, 'data_boundaries', _boundaryFrom),
      support: _mapList(manifest, 'support', _supportFrom),
      withdrawal: _mapList(manifest, 'withdrawal', _withdrawalFrom),
      evidence: _mapList(manifest, 'evidence', _evidenceFrom),
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
    return raw.whereType<String>().toList(growable: false);
  }

  String _string(Object? raw) => raw is String ? raw : '';
  int _int(Object? raw) => (raw as num?)?.toInt() ?? 0;
  bool _bool(Object? raw) => raw == true;

  String? _ref(Object? raw) =>
      raw is String && raw.trim().isNotEmpty ? raw : null;

  Sprint116BetaSelectionRecord _selectionFrom(Map<Object?, Object?> item) {
    return Sprint116BetaSelectionRecord(
      cohortId: _string(item['cohort_id']),
      criteria: _stringList(item['criteria']),
      selectionMethod: _string(item['selection_method']),
      targetSize: _int(item['target_size']),
      enrolledCount: _int(item['enrolled_count']),
      source: _string(item['source']),
      evidenceRef: _ref(item['evidence_ref']),
    );
  }

  Sprint116BetaProviderCoverageRecord _coverageFrom(
    Map<Object?, Object?> item,
  ) {
    return Sprint116BetaProviderCoverageRecord(
      providerId: _string(item['provider_id']),
      connectorId: _string(item['connector_id']),
      stage: _string(item['stage']),
      reason: _string(item['reason']),
      consentRef: _string(item['consent_ref']),
      source: _string(item['source']),
      evidenceRef: _ref(item['evidence_ref']),
    );
  }

  Sprint116BetaConsentRecord _consentFrom(Map<Object?, Object?> item) {
    return Sprint116BetaConsentRecord(
      consentId: _string(item['consent_id']),
      cohortId: _string(item['cohort_id']),
      purposes: _stringList(item['purposes']),
      coveredCategories: _stringList(item['covered_categories']),
      explicitOptIn: _bool(item['explicit_opt_in']),
      policyVersion: _string(item['policy_version']),
      participantId: _string(item['participant_id']),
      grantedAtEpochMs: _int(item['granted_at_epoch_ms']),
      source: _string(item['source']),
      evidenceRef: _ref(item['evidence_ref']),
    );
  }

  Sprint116BetaDataBoundaryRecord _boundaryFrom(Map<Object?, Object?> item) {
    return Sprint116BetaDataBoundaryRecord(
      boundaryId: _string(item['boundary_id']),
      category: _string(item['category']),
      leavesDevice: _bool(item['leaves_device']),
      destination: _string(item['destination']),
      encryptionInTransit: _bool(item['encryption_in_transit']),
      retentionDays: _int(item['retention_days']),
      source: _string(item['source']),
      evidenceRef: _ref(item['evidence_ref']),
    );
  }

  Sprint116BetaSupportRecord _supportFrom(Map<Object?, Object?> item) {
    return Sprint116BetaSupportRecord(
      supportId: _string(item['support_id']),
      channel: _string(item['channel']),
      scope: _string(item['scope']),
      responseSlaHours: _int(item['response_sla_hours']),
      escalationPath: _string(item['escalation_path']),
      source: _string(item['source']),
      evidenceRef: _ref(item['evidence_ref']),
    );
  }

  Sprint116BetaWithdrawalRecord _withdrawalFrom(Map<Object?, Object?> item) {
    return Sprint116BetaWithdrawalRecord(
      withdrawalId: _string(item['withdrawal_id']),
      mechanism: _string(item['mechanism']),
      deadlineDays: _int(item['deadline_days']),
      coveredCategories: _stringList(item['covered_categories']),
      localProjectDataDeleted: _bool(item['local_project_data_deleted']),
      noPenalty: _bool(item['no_penalty']),
      source: _string(item['source']),
      evidenceRef: _ref(item['evidence_ref']),
    );
  }

  Sprint116BetaEvidenceRecord _evidenceFrom(Map<Object?, Object?> item) {
    return Sprint116BetaEvidenceRecord(
      evidenceId: _string(item['evidence_id']),
      claim: _string(item['claim']),
      artifact: _string(item['artifact']),
      recordedAtEpochMs: _int(item['recorded_at_epoch_ms']),
      source: _string(item['source']),
      evidenceRef: _ref(item['evidence_ref']),
    );
  }
}
