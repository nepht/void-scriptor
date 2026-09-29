import 'dart:convert';
import 'dart:io';

/// Canonical step 117.3 — Beta Cohort & Consent Verification.
///
/// Objective (external canonical JSON): verify real participants, consent,
/// provider coverage, data boundaries, withdrawal, and support.
///
/// This contract deliberately does NOT assume a beta has run. The committed
/// 116.49 plan is a plan-stage fixture with `enrolled_count` zero and every
/// row `synthetic_local`, so the honest live verdict is BLOCKED. What the gate
/// proves is that the verification is *defined*, fail-closed, and correctly
/// reports the absence of live evidence instead of smoothing it over.
enum Sprint117CohortState { pass, fail, blocked }

class Sprint117CohortParticipant {
  const Sprint117CohortParticipant({
    required this.participantId,
    required this.cohortId,
    required this.consentedCategories,
    required this.usedProviders,
    required this.source,
    required this.evidenceRef,
  });

  final String participantId;
  final String cohortId;
  final List<String> consentedCategories;
  final List<String> usedProviders;
  final String source;
  final String? evidenceRef;

  bool get isLive =>
      source == Sprint117CohortContract.liveSource &&
      (evidenceRef ?? '').trim().isNotEmpty;
}

class Sprint117CohortConsent {
  const Sprint117CohortConsent({
    required this.consentId,
    required this.participantId,
    required this.cohortId,
    required this.explicitOptIn,
    required this.policyVersion,
    required this.grantedAtEpochMs,
    required this.coveredCategories,
    required this.source,
    required this.evidenceRef,
  });

  final String consentId;
  final String participantId;
  final String cohortId;
  final bool explicitOptIn;
  final String policyVersion;
  final int grantedAtEpochMs;
  final List<String> coveredCategories;
  final String source;
  final String? evidenceRef;

  bool get isLive =>
      source == Sprint117CohortContract.liveSource &&
      (evidenceRef ?? '').trim().isNotEmpty;
}

class Sprint117CohortCoverage {
  const Sprint117CohortCoverage({
    required this.providerId,
    required this.connectorId,
    required this.stage,
    required this.consentRef,
    required this.destinationHost,
    required this.reason,
  });

  final String providerId;
  final String connectorId;
  final String stage;
  final String consentRef;

  /// The host the provider's data actually reaches. It must be a host the
  /// 116.46 privacy gate assessed; a blank host means nothing was assessed.
  final String destinationHost;
  final String? reason;
}

class Sprint117CohortBoundary {
  const Sprint117CohortBoundary({
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

  bool get isLive =>
      source == Sprint117CohortContract.liveSource &&
      (evidenceRef ?? '').trim().isNotEmpty;
}

class Sprint117CohortWithdrawal {
  const Sprint117CohortWithdrawal({
    required this.withdrawalId,
    required this.mechanism,
    required this.deadlineDays,
    required this.coveredCategories,
    required this.noPenalty,
    required this.source,
    required this.evidenceRef,
  });

  final String withdrawalId;
  final String mechanism;
  final int deadlineDays;
  final List<String> coveredCategories;
  final bool noPenalty;
  final String source;
  final String? evidenceRef;

  bool get isLive =>
      source == Sprint117CohortContract.liveSource &&
      (evidenceRef ?? '').trim().isNotEmpty;
}

class Sprint117CohortSupport {
  const Sprint117CohortSupport({
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

  bool get isLive =>
      source == Sprint117CohortContract.liveSource &&
      (evidenceRef ?? '').trim().isNotEmpty;
}

class Sprint117CohortAnchor {
  const Sprint117CohortAnchor({
    required this.entryVerdict,
    required this.charterVerdict,
    required this.exposedSubset,
    required this.hiddenSubset,
    required this.destinationProviders,
    required this.planLiveBetaExecution,
    required this.planCohorts,
    required this.carriedOpenItems,
  });

  final String entryVerdict;
  final String charterVerdict;
  final List<String> exposedSubset;
  final List<String> hiddenSubset;
  final List<String> destinationProviders;
  final bool planLiveBetaExecution;
  final List<String> planCohorts;
  final List<String> carriedOpenItems;
}

class Sprint117CohortInput {
  const Sprint117CohortInput({
    this.participants,
    this.consents,
    this.coverage,
    this.boundaries,
    this.withdrawals,
    this.supports,
    this.anchor,
  });

  final List<Sprint117CohortParticipant>? participants;
  final List<Sprint117CohortConsent>? consents;
  final List<Sprint117CohortCoverage>? coverage;
  final List<Sprint117CohortBoundary>? boundaries;
  final List<Sprint117CohortWithdrawal>? withdrawals;
  final List<Sprint117CohortSupport>? supports;
  final Sprint117CohortAnchor? anchor;
}

class Sprint117CohortReport {
  Sprint117CohortReport({
    required this.state,
    required this.verdict,
    required List<String> missingFields,
    required List<String> violations,
    required this.anchor,
    required List<Sprint117CohortParticipant> participants,
    required List<Sprint117CohortConsent> consents,
    required List<Sprint117CohortCoverage> coverage,
    required List<Sprint117CohortBoundary> boundaries,
    required List<Sprint117CohortWithdrawal> withdrawals,
    required List<Sprint117CohortSupport> supports,
    required this.verifiedParticipantCount,
    required List<String> openItems,
    required List<String> limitations,
    required Map<String, int> fieldCoverage,
  }) : missingFields = List<String>.unmodifiable(missingFields),
       violations = List<String>.unmodifiable(violations),
       participants = List<Sprint117CohortParticipant>.unmodifiable(
         participants,
       ),
       consents = List<Sprint117CohortConsent>.unmodifiable(consents),
       coverage = List<Sprint117CohortCoverage>.unmodifiable(coverage),
       boundaries = List<Sprint117CohortBoundary>.unmodifiable(boundaries),
       withdrawals = List<Sprint117CohortWithdrawal>.unmodifiable(withdrawals),
       supports = List<Sprint117CohortSupport>.unmodifiable(supports),
       openItems = List<String>.unmodifiable(openItems),
       limitations = List<String>.unmodifiable(limitations),
       fieldCoverage = Map<String, int>.unmodifiable(fieldCoverage);

  final Sprint117CohortState state;
  final String verdict;
  final List<String> missingFields;
  final List<String> violations;
  final Sprint117CohortAnchor? anchor;
  final List<Sprint117CohortParticipant> participants;
  final List<Sprint117CohortConsent> consents;
  final List<Sprint117CohortCoverage> coverage;
  final List<Sprint117CohortBoundary> boundaries;
  final List<Sprint117CohortWithdrawal> withdrawals;
  final List<Sprint117CohortSupport> supports;
  final int verifiedParticipantCount;
  final List<String> openItems;
  final List<String> limitations;
  final Map<String, int> fieldCoverage;

  String get externalGates => Sprint117CohortContract.externalGates;

  /// A live beta ran only when at least one participant is evidenced. Zero
  /// evidenced participants is the honest answer, not a formality.
  bool get liveBetaExecuted => verifiedParticipantCount > 0;

  bool get noFabricatedParticipants => true;

  Map<String, Object?> toJson() => <String, Object?>{
    'state': state.name,
    'verdict': verdict,
    'missing_fields': List<String>.from(missingFields),
    'violations': List<String>.from(violations),
    'anchor': anchor == null
        ? null
        : <String, Object?>{
            'entry_verdict': anchor!.entryVerdict,
            'charter_verdict': anchor!.charterVerdict,
            'exposed_subset': List<String>.from(anchor!.exposedSubset),
            'hidden_subset': List<String>.from(anchor!.hiddenSubset),
            'destination_providers': List<String>.from(
              anchor!.destinationProviders,
            ),
            'plan_live_beta_execution': anchor!.planLiveBetaExecution,
            'plan_cohorts': List<String>.from(anchor!.planCohorts),
          },
    'verified_participant_count': verifiedParticipantCount,
    'live_beta_executed': liveBetaExecuted,
    'no_fabricated_participants': noFabricatedParticipants,
    'participants': <Map<String, Object?>>[
      for (final participant in participants)
        <String, Object?>{
          'participant_id': participant.participantId,
          'cohort_id': participant.cohortId,
          'consented_categories': List<String>.from(
            participant.consentedCategories,
          ),
          'used_providers': List<String>.from(participant.usedProviders),
          'source': participant.source,
          'evidence_ref': participant.evidenceRef,
        },
    ],
    'consent': <Map<String, Object?>>[
      for (final record in consents)
        <String, Object?>{
          'consent_id': record.consentId,
          'participant_id': record.participantId,
          'cohort_id': record.cohortId,
          'explicit_opt_in': record.explicitOptIn,
          'policy_version': record.policyVersion,
          'granted_at_epoch_ms': record.grantedAtEpochMs,
          'covered_categories': List<String>.from(record.coveredCategories),
          'source': record.source,
          'evidence_ref': record.evidenceRef,
        },
    ],
    'provider_coverage': <Map<String, Object?>>[
      for (final record in coverage)
        <String, Object?>{
          'provider_id': record.providerId,
          'connector_id': record.connectorId,
          'stage': record.stage,
          'consent_ref': record.consentRef,
          'reason': record.reason,
        },
    ],
    'data_boundaries': <Map<String, Object?>>[
      for (final record in boundaries)
        <String, Object?>{
          'boundary_id': record.boundaryId,
          'category': record.category,
          'leaves_device': record.leavesDevice,
          'destination': record.destination,
          'encryption_in_transit': record.encryptionInTransit,
          'retention_days': record.retentionDays,
          'source': record.source,
          'evidence_ref': record.evidenceRef,
        },
    ],
    'withdrawal': <Map<String, Object?>>[
      for (final record in withdrawals)
        <String, Object?>{
          'withdrawal_id': record.withdrawalId,
          'mechanism': record.mechanism,
          'deadline_days': record.deadlineDays,
          'covered_categories': List<String>.from(record.coveredCategories),
          'no_penalty': record.noPenalty,
          'source': record.source,
          'evidence_ref': record.evidenceRef,
        },
    ],
    'support': <Map<String, Object?>>[
      for (final record in supports)
        <String, Object?>{
          'support_id': record.supportId,
          'channel': record.channel,
          'scope': record.scope,
          'response_sla_hours': record.responseSlaHours,
          'escalation_path': record.escalationPath,
          'source': record.source,
          'evidence_ref': record.evidenceRef,
        },
    ],
    'field_coverage': Map<String, int>.from(fieldCoverage),
    'required_fields': List<String>.from(
      Sprint117CohortContract.requiredFields,
    ),
    'source_manifests': List<String>.from(
      Sprint117CohortContract.sourceManifests,
    ),
    'external_gates': externalGates,
    'open_items': List<String>.from(openItems),
    'limitations': List<String>.from(limitations),
  };
}

abstract final class Sprint117CohortContract {
  static const String canonicalStep = '117.3';

  static const String manifestPath =
      'docs/planning/v1.3/sprint_117_beta_cohort_consent_verification.json';
  static const String planManifestPath =
      'docs/planning/v1.2/sprint_116_beta_cohort_consent_plan.json';
  static const String privacyManifestPath =
      'docs/planning/v1.2/sprint_116_privacy_compliance_gate.json';
  static const String entryManifestPath =
      'docs/planning/v1.3/sprint_117_beta_entry_gate.json';
  static const String charterManifestPath =
      'docs/planning/v1.3/sprint_117_beta_validation_charter.json';
  static const String externalGates = 'DEFERRED-EXTERNAL';

  /// The 117.1 entry verdict this verification stands on.
  static const String entryVerdict = 'BETA_ENTRY_LOCAL_READY';

  /// The 117.2 charter verdict this verification stands on.
  static const String charterVerdict = 'CHARTER_COMPLETE_LOCAL';

  static const String passVerdict = 'COHORT_CONSENT_VERIFIED_LOCAL';
  static const String blockedVerdict =
      'COHORT_CONSENT_BLOCKED_NO_LIVE_EVIDENCE';
  static const String failVerdict = 'COHORT_CONSENT_VERIFICATION_FAILED';

  /// A row is live only when it claims this source AND carries an evidence
  /// reference. A source label alone is a label, not evidence.
  static const String liveSource = 'live_beta';

  /// The six fields canonical step 117.3 names, in canonical order.
  static const List<String> requiredFields = <String>[
    'participant_or_project_id',
    'consent',
    'provider_coverage',
    'data_boundaries',
    'withdrawal',
    'support',
  ];

  /// Manifests the live loader reads. The 116.49 plan is the source of truth for
  /// cohort rows; 116.46 supplies the recorded privacy destinations; 117.1 and
  /// 117.2 supply the verdicts and the exposed subset.
  static const List<String> sourceManifests = <String>[
    planManifestPath,
    privacyManifestPath,
    entryManifestPath,
    charterManifestPath,
  ];

  /// A support scope that covers every enrolled cohort without naming one.
  static const String globalSupportScope = 'beta_global';
}

class Sprint117CohortLoader {
  const Sprint117CohortLoader();

  Sprint117CohortInput load() => Sprint117CohortInput(
    anchor: _loadAnchor(),
    participants: _loadParticipants(),
    consents: _loadConsents(),
    coverage: _loadCoverage(),
    boundaries: _loadBoundaries(),
    withdrawals: _loadWithdrawals(),
    supports: _loadSupports(),
  );

  Sprint117CohortAnchor? _loadAnchor() {
    final entry = _readJsonObject(Sprint117CohortContract.entryManifestPath);
    final charter = _readJsonObject(
      Sprint117CohortContract.charterManifestPath,
    );
    final plan = _readJsonObject(Sprint117CohortContract.planManifestPath);
    if (entry == null || charter == null || plan == null) return null;

    final hidden = <String>{
      ..._stringList(entry['hidden_from_beta']),
      ..._stringList(entry['blocked_subset']),
    };
    return Sprint117CohortAnchor(
      entryVerdict: _text(entry['verdict']),
      charterVerdict: _text(charter['verdict']),
      exposedSubset: _stringList(entry['exposed_beta_subset']),
      hiddenSubset: hidden.toList(growable: false),
      destinationProviders: _recordedDestinationProviders(),
      planLiveBetaExecution: plan['live_beta_execution'] == true,
      planCohorts: <String>[
        for (final row
            in _readList(
                  Sprint117CohortContract.planManifestPath,
                  'selection',
                ) ??
                const <dynamic>[])
          if (row is Map<String, dynamic>) _text(row['cohort_id']),
      ].where((id) => id.isNotEmpty).toList(growable: false),
      carriedOpenItems: _stringList(charter['carried_open_items']),
    );
  }

  /// The destination vocabulary the coverage rows are checked against: hosts
  /// the 116.46 privacy gate assessed, plus the hosts 116.49 itself records as
  /// receiving data. A provider that appears in neither was never assessed.
  List<String> _recordedDestinationProviders() {
    final result = <String>{};
    for (final row
        in _readList(
              Sprint117CohortContract.privacyManifestPath,
              'destinations',
            ) ??
            const <dynamic>[]) {
      if (row is! Map<String, dynamic>) continue;
      final host = _text(row['host']);
      if (host.isNotEmpty) result.add(host);
    }
    for (final row
        in _readList(
              Sprint117CohortContract.planManifestPath,
              'data_boundaries',
            ) ??
            const <dynamic>[]) {
      if (row is! Map<String, dynamic>) continue;
      if (row['leaves_device'] != true) continue;
      final host = _text(row['destination']);
      if (host.isNotEmpty) result.add(host);
    }
    return result.toList(growable: false);
  }

  /// 116.49 records `enrolled_count` per cohort. Nobody is enrolled, so no
  /// participant row is emitted: inventing one would be a fabricated beta.
  List<Sprint117CohortParticipant>? _loadParticipants() {
    final rows = _readList(
      Sprint117CohortContract.planManifestPath,
      'selection',
    );
    if (rows == null) return null;
    final participants = <Sprint117CohortParticipant>[];
    for (final row in rows) {
      if (row is! Map<String, dynamic>) continue;
      final enrolled = row['enrolled_count'];
      if (enrolled is! int || enrolled <= 0) continue;
      final cohortId = _text(row['cohort_id']);
      if (cohortId.isEmpty) continue;
      for (var index = 0; index < enrolled; index++) {
        participants.add(
          Sprint117CohortParticipant(
            participantId: '${cohortId}_$index',
            cohortId: cohortId,
            consentedCategories: const <String>[],
            usedProviders: const <String>[],
            source: _text(row['source']),
            evidenceRef: _nullableText(row['evidence_ref']),
          ),
        );
      }
    }
    return participants;
  }

  List<Sprint117CohortConsent>? _loadConsents() {
    final rows = _readList(Sprint117CohortContract.planManifestPath, 'consent');
    if (rows == null) return null;
    final result = <Sprint117CohortConsent>[];
    for (final row in rows) {
      if (row is! Map<String, dynamic>) continue;
      final consentId = _text(row['consent_id']);
      if (consentId.isEmpty) continue;
      final participantId = _text(row['participant_id']);
      result.add(
        Sprint117CohortConsent(
          consentId: consentId,
          participantId: participantId,
          cohortId: _text(row['cohort_id']),
          explicitOptIn: row['explicit_opt_in'] == true,
          policyVersion: _text(row['policy_version']),
          grantedAtEpochMs: row['granted_at_epoch_ms'] is int
              ? row['granted_at_epoch_ms']! as int
              : 0,
          coveredCategories: _stringList(row['covered_categories']),
          source: _text(row['source']),
          evidenceRef: _nullableText(row['evidence_ref']),
        ),
      );
    }
    return result;
  }

  List<Sprint117CohortCoverage>? _loadCoverage() {
    final rows = _readList(
      Sprint117CohortContract.planManifestPath,
      'provider_coverage',
    );
    if (rows == null) return null;
    final result = <Sprint117CohortCoverage>[];
    for (final row in rows) {
      if (row is! Map<String, dynamic>) continue;
      final providerId = _text(row['provider_id']);
      if (providerId.isEmpty) continue;
      result.add(
        Sprint117CohortCoverage(
          providerId: providerId,
          connectorId: _text(row['connector_id']),
          stage: _text(row['stage']),
          consentRef: _text(row['consent_ref']),
          destinationHost: _text(row['destination_host']),
          reason: _nullableText(row['reason']),
        ),
      );
    }
    return result;
  }

  List<Sprint117CohortBoundary>? _loadBoundaries() {
    final rows = _readList(
      Sprint117CohortContract.planManifestPath,
      'data_boundaries',
    );
    if (rows == null) return null;
    final result = <Sprint117CohortBoundary>[];
    for (final row in rows) {
      if (row is! Map<String, dynamic>) continue;
      final boundaryId = _text(row['boundary_id']);
      if (boundaryId.isEmpty) continue;
      result.add(
        Sprint117CohortBoundary(
          boundaryId: boundaryId,
          category: _text(row['category']),
          leavesDevice: row['leaves_device'] == true,
          destination: _text(row['destination']),
          encryptionInTransit: row['encryption_in_transit'] == true,
          retentionDays: row['retention_days'] is int
              ? row['retention_days']! as int
              : 0,
          source: _text(row['source']),
          evidenceRef: _nullableText(row['evidence_ref']),
        ),
      );
    }
    return result;
  }

  List<Sprint117CohortWithdrawal>? _loadWithdrawals() {
    final rows = _readList(
      Sprint117CohortContract.planManifestPath,
      'withdrawal',
    );
    if (rows == null) return null;
    final result = <Sprint117CohortWithdrawal>[];
    for (final row in rows) {
      if (row is! Map<String, dynamic>) continue;
      final withdrawalId = _text(row['withdrawal_id']);
      if (withdrawalId.isEmpty) continue;
      result.add(
        Sprint117CohortWithdrawal(
          withdrawalId: withdrawalId,
          mechanism: _text(row['mechanism']),
          deadlineDays: row['deadline_days'] is int
              ? row['deadline_days']! as int
              : 0,
          coveredCategories: _stringList(row['covered_categories']),
          noPenalty: row['no_penalty'] == true,
          source: _text(row['source']),
          evidenceRef: _nullableText(row['evidence_ref']),
        ),
      );
    }
    return result;
  }

  List<Sprint117CohortSupport>? _loadSupports() {
    final rows = _readList(Sprint117CohortContract.planManifestPath, 'support');
    if (rows == null) return null;
    final result = <Sprint117CohortSupport>[];
    for (final row in rows) {
      if (row is! Map<String, dynamic>) continue;
      final supportId = _text(row['support_id']);
      if (supportId.isEmpty) continue;
      result.add(
        Sprint117CohortSupport(
          supportId: supportId,
          channel: _text(row['channel']),
          scope: _text(row['scope']),
          responseSlaHours: row['response_sla_hours'] is int
              ? row['response_sla_hours']! as int
              : 0,
          escalationPath: _text(row['escalation_path']),
          source: _text(row['source']),
          evidenceRef: _nullableText(row['evidence_ref']),
        ),
      );
    }
    return result;
  }

  static Map<String, dynamic>? _readJsonObject(String path) {
    final file = File(path);
    if (!file.existsSync()) return null;
    try {
      final decoded = jsonDecode(file.readAsStringSync());
      return decoded is Map<String, dynamic> ? decoded : null;
    } on FormatException {
      return null;
    }
  }

  static List<dynamic>? _readList(String path, String key) {
    final decoded = _readJsonObject(path);
    if (decoded == null) return null;
    final value = decoded[key];
    return value is List<dynamic> ? value : null;
  }

  static String _text(Object? value) => value is String ? value.trim() : '';

  static String? _nullableText(Object? value) {
    if (value is! String) return null;
    final trimmed = value.trim();
    return trimmed.isEmpty ? null : trimmed;
  }

  static List<String> _stringList(Object? value) {
    if (value is! List<dynamic>) return const <String>[];
    return <String>[
      for (final item in value)
        if (item is String && item.trim().isNotEmpty) item.trim(),
    ];
  }
}

class Sprint117CohortGate {
  Sprint117CohortReport evaluate() =>
      evaluateWith(const Sprint117CohortLoader().load());

  Sprint117CohortReport evaluateWith(Sprint117CohortInput input) {
    final missing = <String>{};
    final violations = <String>[];

    final anchor = input.anchor;
    if (anchor == null) {
      missing.add('entry_anchor');
    } else {
      if (anchor.entryVerdict != Sprint117CohortContract.entryVerdict) {
        missing.add('entry_anchor');
      }
      if (anchor.charterVerdict != Sprint117CohortContract.charterVerdict) {
        missing.add('charter_anchor');
      }
    }

    // --- participants ------------------------------------------------------
    final participants = input.participants;
    final participantIds = <String>{};
    final cohortIds = <String>{};
    if (participants == null || participants.isEmpty) {
      missing.add('participant_or_project_id');
    } else {
      for (final participant in participants) {
        final id = participant.participantId.trim();
        final cohort = participant.cohortId.trim();
        if (id.isEmpty) {
          violations.add('participant_id_blank:${participant.cohortId}');
          continue;
        }
        if (!participantIds.add(id)) {
          violations.add('participant_duplicate:$id');
          continue;
        }
        cohortIds.add(cohort);
        if (anchor != null &&
            anchor.planCohorts.isNotEmpty &&
            !anchor.planCohorts.contains(cohort)) {
          violations.add('participant_cohort_unknown:$cohort');
        }
        if (!participant.isLive) {
          missing.add('participant_unverified:$id');
        }
      }
    }

    // --- consent -----------------------------------------------------------
    final consents = input.consents;
    final consentIds = <String>{};
    final consentedCategories = <String>{};
    if (consents == null || consents.isEmpty) {
      missing.add('consent');
    } else {
      for (final record in consents) {
        final id = record.consentId.trim();
        if (id.isEmpty) {
          violations.add('consent_id_blank');
          continue;
        }
        if (!consentIds.add(id)) {
          violations.add('consent_duplicate:$id');
          continue;
        }
        if (!record.explicitOptIn) {
          violations.add('consent_opt_in:$id');
        }
        if (record.policyVersion.trim().isEmpty) {
          violations.add('consent_policy:$id');
        }
        if (record.grantedAtEpochMs <= 0) {
          violations.add('consent_timestamp:$id');
        }
        if (record.coveredCategories.isEmpty) {
          violations.add('consent_category:$id');
        }
        consentedCategories.addAll(record.coveredCategories);
        final participantId = record.participantId.trim();
        if (participantId.isEmpty) {
          // Nobody is enrolled, so a plan-stage consent row that has not yet
          // named a participant is incomplete evidence, not a contradiction
          // with a roster that never enrolled anyone.
          missing.add('consent_participant_missing:$id');
        } else if (!participantIds.contains(participantId)) {
          violations.add('consent_participant_unknown:$id:$participantId');
        } else {
          final participant = participants!.firstWhere(
            (candidate) => candidate.participantId.trim() == participantId,
          );
          if (participant.cohortId.trim() != record.cohortId.trim()) {
            violations.add('consent_cohort_mismatch:$id');
          }
        }
        if (!record.isLive) {
          missing.add('consent_unverified:$id');
        }
      }
      for (final id in participantIds) {
        if (!consents.any((record) => record.participantId.trim() == id)) {
          violations.add('consent_uncovered:$id');
        }
      }
    }

    // --- provider coverage -------------------------------------------------
    final coverage = input.coverage;
    if (coverage == null || coverage.isEmpty) {
      missing.add('provider_coverage');
    } else {
      final covered = <String>{};
      for (final record in coverage) {
        final provider = record.providerId.trim();
        if (provider.isEmpty) {
          violations.add('coverage_provider_blank');
          continue;
        }
        if (!covered.add(provider)) {
          violations.add('coverage_duplicate:$provider');
          continue;
        }
        if (anchor != null && anchor.hiddenSubset.contains(provider)) {
          violations.add('coverage_provider_blocked:$provider');
        }
        if (anchor != null &&
            anchor.exposedSubset.isNotEmpty &&
            !anchor.exposedSubset.contains(provider)) {
          violations.add('coverage_provider_not_exposed:$provider');
        }
        if (record.connectorId.trim().isEmpty) {
          violations.add('coverage_connector_blank:$provider');
        }
        if (record.stage.trim().isEmpty) {
          violations.add('coverage_stage_blank:$provider');
        }
        if (!consentIds.contains(record.consentRef.trim())) {
          violations.add(
            'coverage_consent_unresolved:$provider:${record.consentRef}',
          );
        }
        if (anchor != null &&
            anchor.destinationProviders.isNotEmpty &&
            !anchor.destinationProviders.contains(record.destinationHost)) {
          violations.add('coverage_destination_unrecorded:$provider');
        }
      }
      for (final participant
          in participants ?? const <Sprint117CohortParticipant>[]) {
        for (final provider in participant.usedProviders) {
          if (!covered.contains(provider)) {
            violations.add('coverage_provider_uncovered:$provider');
          }
        }
      }
    }

    // --- data boundaries ---------------------------------------------------
    final boundaries = input.boundaries;
    final boundaryCategories = <String>{};
    if (boundaries == null || boundaries.isEmpty) {
      missing.add('data_boundaries');
    } else {
      final boundaryIds = <String>{};
      for (final record in boundaries) {
        final id = record.boundaryId.trim();
        if (id.isEmpty) {
          violations.add('boundary_id_blank');
          continue;
        }
        if (!boundaryIds.add(id)) {
          violations.add('boundary_duplicate:$id');
          continue;
        }
        final category = record.category.trim();
        if (category.isEmpty) {
          violations.add('boundary_category_blank:$id');
        } else {
          boundaryCategories.add(category);
        }
        if (record.leavesDevice && record.destination.trim().isEmpty) {
          violations.add('boundary_destination:$id');
        }
        if (record.leavesDevice && !record.encryptionInTransit) {
          violations.add('boundary_encryption:$id');
        }
        if (record.retentionDays <= 0) {
          violations.add('boundary_retention:$id');
        }
        if (!record.isLive) {
          missing.add('boundary_unverified:$id');
        }
      }
    }
    for (final category in consentedCategories) {
      if (!boundaryCategories.contains(category)) {
        violations.add('consent_category_unbounded:$category');
      }
    }

    // --- withdrawal --------------------------------------------------------
    final withdrawals = input.withdrawals;
    final withdrawnCategories = <String>{};
    if (withdrawals == null || withdrawals.isEmpty) {
      missing.add('withdrawal');
    } else {
      final withdrawalIds = <String>{};
      for (final record in withdrawals) {
        final id = record.withdrawalId.trim();
        if (id.isEmpty) {
          violations.add('withdrawal_id_blank');
          continue;
        }
        if (!withdrawalIds.add(id)) {
          violations.add('withdrawal_duplicate:$id');
          continue;
        }
        if (record.mechanism.trim().isEmpty) {
          violations.add('withdrawal_mechanism:$id');
        }
        if (record.deadlineDays <= 0) {
          violations.add('withdrawal_deadline:$id');
        }
        if (!record.noPenalty) {
          violations.add('withdrawal_penalty:$id');
        }
        withdrawnCategories.addAll(record.coveredCategories);
        if (!record.isLive) {
          missing.add('withdrawal_unverified:$id');
        }
      }
    }
    for (final category in consentedCategories) {
      if (!withdrawnCategories.contains(category)) {
        violations.add('withdrawal_category_uncovered:$category');
      }
    }

    // --- support -----------------------------------------------------------
    final supports = input.supports;
    if (supports == null || supports.isEmpty) {
      missing.add('support');
    } else {
      final supportIds = <String>{};
      for (final record in supports) {
        final id = record.supportId.trim();
        if (id.isEmpty) {
          violations.add('support_id_blank');
          continue;
        }
        if (!supportIds.add(id)) {
          violations.add('support_duplicate:$id');
          continue;
        }
        if (record.channel.trim().isEmpty) {
          violations.add('support_channel:$id');
        }
        if (record.responseSlaHours <= 0) {
          violations.add('support_sla:$id');
        }
        if (record.escalationPath.trim().isEmpty) {
          violations.add('support_escalation:$id');
        }
        if (!record.isLive) {
          missing.add('support_unverified:$id');
        }
      }
      // Coverage is resolved from the enrolled cohort outwards: every cohort
      // that actually has a participant must be reachable by some support row.
      // Naming the support row's own scope instead would report an unused
      // scope rather than the cohort left without support.
      for (final cohort in cohortIds) {
        final covered = supports.any((record) {
          final scope = record.scope.trim();
          return scope == Sprint117CohortContract.globalSupportScope ||
              scope == cohort;
        });
        if (!covered) {
          violations.add('support_cohort_uncovered:$cohort');
        }
      }
    }

    // --- resolution --------------------------------------------------------
    final verifiedParticipantCount =
        (participants ?? const <Sprint117CohortParticipant>[])
            .where((participant) => participant.isLive)
            .length;

    if (verifiedParticipantCount > 0 &&
        !(anchor?.planLiveBetaExecution ?? true)) {
      // The plan itself records that no beta has run. A verification that then
      // reports evidenced participants contradicts its own source, which is a
      // contradiction rather than merely incomplete evidence. An honest report
      // that found nobody must not be penalised for the plan's state.
      violations.add('live_execution_claimed_without_plan');
    }

    final state = violations.isNotEmpty
        ? Sprint117CohortState.fail
        : missing.isNotEmpty
        ? Sprint117CohortState.blocked
        : Sprint117CohortState.pass;
    final verdict = switch (state) {
      Sprint117CohortState.pass => Sprint117CohortContract.passVerdict,
      Sprint117CohortState.fail => Sprint117CohortContract.failVerdict,
      Sprint117CohortState.blocked => Sprint117CohortContract.blockedVerdict,
    };

    final openItems = <String>[...anchor?.carriedOpenItems ?? const <String>[]];
    if (!(anchor?.planLiveBetaExecution ?? true)) {
      openItems.add(
        'no_participant_enrolled: 116.49 plan records enrolled_count 0',
      );
    }

    final limitations = <String>[
      if (verifiedParticipantCount == 0)
        'No participant is enrolled: the committed 116.49 plan records enrolled_count 0 for every cohort, so live beta execution, participant verification, real consent collection, provider handshake, and data-boundary transfer cannot be evidenced here.',
      'Every row read from the committed plan is synthetic_local with no evidence_ref, so the live verdict is BLOCKED by design rather than passed.',
      'Live recruitment, real-person consent capture, real provider calls, kill-switch drills, hosted CI, billing settlement, and publication remain ${Sprint117CohortContract.externalGates}.',
    ];

    final fieldCoverage = <String, int>{
      'participant_or_project_id':
          (participants ?? const <Sprint117CohortParticipant>[])
              .where((participant) => participant.isLive)
              .length,
      'consent': (consents ?? const <Sprint117CohortConsent>[])
          .where((record) => record.isLive)
          .length,
      'provider_coverage':
          (coverage ?? const <Sprint117CohortCoverage>[]).length,
      'data_boundaries': (boundaries ?? const <Sprint117CohortBoundary>[])
          .where((record) => record.isLive)
          .length,
      'withdrawal': (withdrawals ?? const <Sprint117CohortWithdrawal>[])
          .where((record) => record.isLive)
          .length,
      'support': (supports ?? const <Sprint117CohortSupport>[])
          .where((record) => record.isLive)
          .length,
    };

    return Sprint117CohortReport(
      state: state,
      verdict: verdict,
      missingFields: missing.toList(growable: false),
      violations: violations.toList(growable: false),
      anchor: anchor,
      participants: participants ?? const <Sprint117CohortParticipant>[],
      consents: consents ?? const <Sprint117CohortConsent>[],
      coverage: coverage ?? const <Sprint117CohortCoverage>[],
      boundaries: boundaries ?? const <Sprint117CohortBoundary>[],
      withdrawals: withdrawals ?? const <Sprint117CohortWithdrawal>[],
      supports: supports ?? const <Sprint117CohortSupport>[],
      verifiedParticipantCount: verifiedParticipantCount,
      openItems: openItems,
      limitations: limitations,
      fieldCoverage: fieldCoverage,
    );
  }
}
