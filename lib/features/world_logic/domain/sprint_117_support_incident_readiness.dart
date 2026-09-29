import 'dart:convert';
import 'dart:io';

/// Canonical step 117.6 — Support & Incident Readiness.
///
/// Objective (external canonical JSON): prepare intake, severity, owners,
/// response targets, recovery guidance, and provider escalation.
///
/// The six canonical fields are testable conditions rather than prose, because
/// the failure mode of a support plan is not being short — it is being short
/// *quietly*. A severity ladder with no owner, a recovery guide pointing at a
/// document that does not exist, or an escalation path nobody answers to all
/// look complete in a review and fail in an incident.
///
/// Three rules carry the weight:
///
/// * A field the sources never recorded is *undecided*, not wrong. 113.5 — the
///   support readiness manifest — predates the beta connector set entirely, so
///   most of the exposed surface has no recorded provider-escalation decision.
///   Those are reported as undetermined. Calling them violations would report an
///   unfinished plan as a provably broken one, which is the same confusion
///   117.5 had to fix on the exposure matrix.
/// * A field that *is* recorded and then contradicted is incoherent, and that
///   is a violation. A P0 that answers slower than it resolves, or a response
///   target that drifts from the severity record, are contradictions, not gaps.
/// * A referenced document must exist. A recovery guide is a promise to look
///   something up during an incident; a dangling path is a broken promise, and
///   the check is made against the filesystem rather than against the record.
///
/// Every field is derived from a committed manifest. Nothing here invents an
/// owner, a target, or a channel: 113.5 supplies the severity ladder, owners,
/// response targets, and recovery guides; 116.50 supplies the stop conditions
/// and kill switches a provider escalation must hang on; 117.2 supplies the
/// incident scope owner; 117.3 and 117.4 supply the surface and the honest
/// answer that no incident has ever been run.
enum Sprint117SupportState { pass, fail, blocked }

/// One severity level: what it means, who answers it, and how fast.
class Sprint117SeverityRecord implements Sprint117ReadinessRow {
  const Sprint117SeverityRecord({
    required this.level,
    required this.definition,
    required this.responseTarget,
    required this.maxResponseHours,
    required this.resolutionTargetHours,
    required this.owner,
  });

  @override
  final String level;

  /// The stable identity used to de-duplicate ladder rungs.
  @override
  String get rowId => 'severity:$level';

  final String definition;

  /// The recorded response label (`Immediate`, `Urgent`, …).
  final String responseTarget;

  /// The recorded maximum response time in hours.
  final int maxResponseHours;

  /// The recorded resolution target in hours.
  final int resolutionTargetHours;

  final String owner;

  @override
  Map<String, Object?> toJson() => <String, Object?>{
    'level': level,
    'definition': definition,
    'response_target': responseTarget,
    'max_response_hours': maxResponseHours,
    'resolution_target_hours': resolutionTargetHours,
    'owner': owner,
  };
}

/// A documented recovery route for one incident scenario.
class Sprint117RecoveryGuideRecord implements Sprint117ReadinessRow {
  const Sprint117RecoveryGuideRecord({
    required this.scenario,
    required this.guidePath,
    required this.owner,
  });

  final String scenario;
  final String guidePath;
  final String owner;

  /// The stable identity used to de-duplicate guides.
  @override
  String get rowId => 'guide:$scenario';

  @override
  String get level => 'GUIDE';

  @override
  Map<String, Object?> toJson() => <String, Object?>{
    'scenario': scenario,
    'guide_path': guidePath,
    'owner': owner,
  };
}

/// One escalation route: what triggers it, what happens, who runs it.
class Sprint117EscalationRecord implements Sprint117ReadinessRow {
  const Sprint117EscalationRecord({
    required this.trigger,
    required this.action,
    required this.owner,
    required this.communication,
  });

  final String trigger;
  final String action;
  final String owner;
  final String communication;

  @override
  String get rowId => 'escalation:$trigger';

  @override
  String get level => 'ESCALATION';

  @override
  Map<String, Object?> toJson() => <String, Object?>{
    'trigger': trigger,
    'action': action,
    'owner': owner,
    'communication': communication,
  };
}

/// Anything the readiness gate evaluates as a row.
abstract interface class Sprint117ReadinessRow {
  /// The row's identity for de-duplication and coverage.
  String get rowId;

  /// The severity level this row belongs to, or a row-kind tag.
  String get level;

  Map<String, Object?> toJson();
}

/// One provider's escalation route: what to pull, and what triggers the pull.
///
/// This is the field a v1.2 support plan cannot supply. 113.5 predates the beta
/// connector set, so an escalation route is only *decided* for a provider the
/// rollout both staged and gave a kill switch. Everything else stays undetermined.
class Sprint117ProviderEscalationRecord {
  Sprint117ProviderEscalationRecord({
    required this.providerId,
    required this.killSwitchId,
    required List<String> stopConditionIds,
    required this.owner,
  }) : stopConditionIds = List<String>.unmodifiable(stopConditionIds);

  final String providerId;

  /// The connector kill switch that contains the provider.
  final String killSwitchId;

  /// The recorded stop conditions that would trigger escalation.
  final List<String> stopConditionIds;

  final String owner;

  bool get decided =>
      killSwitchId.trim().isNotEmpty && stopConditionIds.isNotEmpty;

  Map<String, Object?> toJson() => <String, Object?>{
    'provider_id': providerId,
    'kill_switch': killSwitchId,
    'stop_conditions': List<String>.from(stopConditionIds),
    'owner': owner,
  };
}

/// The evidence this readiness plan is allowed to decide from.
class Sprint117SupportAnchor {
  Sprint117SupportAnchor({
    required this.readinessVerdict,
    required this.supportVerdict,
    required this.charterVerdict,
    required this.exposureVerdict,
    required List<String> severityLevels,
    required Map<String, int> responseTargetHours,
    required Map<String, int> recordedResponseTargetHours,
    required List<String> surfaceProviderIds,
    required Map<String, String> providerKill,
    required List<String> recordedStopIds,
    required Map<String, List<String>> providerStopConditions,
    required List<String> undrilledKillIds,
    required List<Sprint117ProviderEscalationRecord> escalatedProviders,
    required List<String> undeterminedProviders,
    required this.charterIncidentOwner,
    required List<String> carriedOpenItems,
  }) : severityLevels = List<String>.unmodifiable(severityLevels),
       responseTargetHours = Map<String, int>.unmodifiable(responseTargetHours),
       recordedResponseTargetHours = Map<String, int>.unmodifiable(
         recordedResponseTargetHours,
       ),
       surfaceProviderIds = List<String>.unmodifiable(surfaceProviderIds),
       providerKill = Map<String, String>.unmodifiable(providerKill),
       recordedStopIds = List<String>.unmodifiable(recordedStopIds),
       providerStopConditions = Map<String, List<String>>.unmodifiable(
         providerStopConditions.map(
           (key, value) => MapEntry(key, List<String>.unmodifiable(value)),
         ),
       ),
       undrilledKillIds = List<String>.unmodifiable(undrilledKillIds),
       escalatedProviders =
           List<Sprint117ProviderEscalationRecord>.unmodifiable(
             escalatedProviders,
           ),
       undeterminedProviders = List<String>.unmodifiable(undeterminedProviders),
       carriedOpenItems = List<String>.unmodifiable(carriedOpenItems);

  /// The 113.5 verdict this plan inherits its severity ladder from.
  final String readinessVerdict;

  /// The 117.3 verdict. No verified cohort means no live support obligation.
  final String supportVerdict;

  /// The 117.2 verdict that assigned the `incident` scope.
  final String charterVerdict;

  /// The 117.4 verdict whose exposed subset defines the surface.
  final String exposureVerdict;

  final List<String> severityLevels;
  final Map<String, int> responseTargetHours;

  /// The response target the readiness manifest records, for drift detection.
  final Map<String, int> recordedResponseTargetHours;

  /// The 117.4 exposed subset.
  final List<String> surfaceProviderIds;

  final Map<String, String> providerKill;
  final List<String> recordedStopIds;
  final Map<String, List<String>> providerStopConditions;
  final List<String> undrilledKillIds;
  final List<Sprint117ProviderEscalationRecord> escalatedProviders;

  /// Providers with no recorded provider-escalation decision at all.
  final List<String> undeterminedProviders;

  /// The owner 117.2 gave the `incident` scope.
  final String charterIncidentOwner;

  final List<String> carriedOpenItems;
}

class Sprint117SupportInput {
  const Sprint117SupportInput({this.rows, this.anchor});

  final List<Sprint117ReadinessRow>? rows;
  final Sprint117SupportAnchor? anchor;
}

class Sprint117SupportReport {
  Sprint117SupportReport({
    required this.state,
    required this.verdict,
    required List<String> missingFields,
    required List<String> violations,
    required this.anchor,
    required List<Sprint117ReadinessRow> rows,
    required List<String> severityLevels,
    required Map<String, Sprint117SeverityRecord> severityByLevel,
    required List<Sprint117RecoveryGuideRecord> recoveryGuides,
    required List<Sprint117EscalationRecord> escalationPaths,
    required List<Sprint117ProviderEscalationRecord> providerEscalation,
    required List<String> escalatedProviders,
    required List<String> undeterminedProviders,
    required List<String> referencedDocuments,
    required List<String> owners,
    required this.charterIncidentOwner,
    required List<String> openItems,
    required List<String> limitations,
    required Map<String, int> fieldCoverage,
  }) : missingFields = List<String>.unmodifiable(missingFields),
       violations = List<String>.unmodifiable(violations),
       rows = List<Sprint117ReadinessRow>.unmodifiable(rows),
       severityLevels = List<String>.unmodifiable(severityLevels),
       severityByLevel = Map<String, Sprint117SeverityRecord>.unmodifiable(
         severityByLevel,
       ),
       recoveryGuides = List<Sprint117RecoveryGuideRecord>.unmodifiable(
         recoveryGuides,
       ),
       escalationPaths = List<Sprint117EscalationRecord>.unmodifiable(
         escalationPaths,
       ),
       providerEscalation =
           List<Sprint117ProviderEscalationRecord>.unmodifiable(
             providerEscalation,
           ),
       escalatedProviders = List<String>.unmodifiable(escalatedProviders),
       undeterminedProviders = List<String>.unmodifiable(undeterminedProviders),
       referencedDocuments = List<String>.unmodifiable(referencedDocuments),
       owners = List<String>.unmodifiable(owners),
       openItems = List<String>.unmodifiable(openItems),
       limitations = List<String>.unmodifiable(limitations),
       fieldCoverage = Map<String, int>.unmodifiable(fieldCoverage);

  final Sprint117SupportState state;
  final String verdict;
  final List<String> missingFields;
  final List<String> violations;
  final Sprint117SupportAnchor? anchor;
  final List<Sprint117ReadinessRow> rows;

  /// The severity levels, ordered from the recorded ladder.
  final List<String> severityLevels;

  final Map<String, Sprint117SeverityRecord> severityByLevel;
  final List<Sprint117RecoveryGuideRecord> recoveryGuides;
  final List<Sprint117EscalationRecord> escalationPaths;
  final List<Sprint117ProviderEscalationRecord> providerEscalation;

  /// Providers whose escalation route is decided by recorded evidence.
  final List<String> escalatedProviders;

  /// Providers carrying an escalation decision nobody has made yet.
  final List<String> undeterminedProviders;

  /// Every document this plan tells a responder to open.
  final List<String> referencedDocuments;

  final List<String> owners;
  final String charterIncidentOwner;
  final List<String> openItems;
  final List<String> limitations;
  final Map<String, int> fieldCoverage;

  String get externalGates => Sprint117SupportContract.externalGates;

  /// A readiness plan is never a record of an incident that happened.
  bool get liveIncidentExecuted => false;

  int get rowCount => rows.length;

  Map<String, Object?> toJson() => <String, Object?>{
    'canonical_step': Sprint117SupportContract.canonicalStep,
    'state': state.name,
    'verdict': verdict,
    'missing_fields': List<String>.from(missingFields),
    'violations': List<String>.from(violations),
    'row_count': rowCount,
    'severity_levels': List<String>.from(severityLevels),
    'severity_matrix': <Map<String, Object?>>[
      for (final level in severityLevels)
        severityByLevel[level]?.toJson() ?? <String, Object?>{},
    ],
    'owners': List<String>.from(owners),
    'response_targets': <String, Object?>{
      for (final level in severityLevels)
        level: anchor?.responseTargetHours[level],
    },
    'recovery_guides': <Map<String, Object?>>[
      for (final guide in recoveryGuides) guide.toJson(),
    ],
    'escalation_paths': <Map<String, Object?>>[
      for (final path in escalationPaths) path.toJson(),
    ],
    'provider_escalation': <Map<String, Object?>>[
      for (final row in providerEscalation) row.toJson(),
    ],
    'escalated_providers': List<String>.from(escalatedProviders),
    'undetermined_providers': List<String>.from(undeterminedProviders),
    'referenced_documents': List<String>.from(referencedDocuments),
    'charter_incident_owner': charterIncidentOwner,
    'field_coverage': Map<String, int>.from(fieldCoverage),
    'required_fields': List<String>.from(
      Sprint117SupportContract.requiredFields,
    ),
    'source_manifests': List<String>.from(
      Sprint117SupportContract.sourceManifests,
    ),
    'external_gates': externalGates,
    'live_incident_executed': liveIncidentExecuted,
    'open_items': List<String>.from(openItems),
    'limitations': List<String>.from(limitations),
  };
}

abstract final class Sprint117SupportContract {
  static const String canonicalStep = '117.6';

  static const String manifestPath =
      'docs/planning/v1.3/sprint_117_support_incident_readiness.json';

  /// 113.5 supplies severity, owners, response targets, recovery guides, and
  /// the escalation paths a v1.2 candidate could define.
  static const String readinessManifestPath =
      'docs/planning/v1.2/sprint_113_support_escalation_readiness.json';

  /// 116.50 supplies the stop conditions and kill switches a provider
  /// escalation has to hang on.
  static const String rolloutManifestPath =
      'docs/planning/v1.2/sprint_116_staged_beta_rollout_monitoring.json';

  /// 117.2 supplies the owner of the `incident` scope.
  static const String charterManifestPath =
      'docs/planning/v1.3/sprint_117_beta_validation_charter.json';

  /// 117.3 supplies the honest answer that no support obligation is live.
  static const String cohortManifestPath =
      'docs/planning/v1.3/sprint_117_beta_cohort_consent_verification.json';

  /// 117.4 supplies the exposed surface this plan supports.
  static const String exposureManifestPath =
      'docs/planning/v1.3/sprint_117_certification_snapshot_lock.json';

  static const String externalGates = 'DEFERRED-EXTERNAL';

  /// The 113.5 decision this plan inherits.
  static const String readinessVerdict = 'SUPPORT_READINESS_DEFINED';

  /// The 117.3 verdict that would make a support obligation live.
  static const String cohortVerifiedVerdict = 'COHORT_CONSENT_VERIFIED_LOCAL';

  /// The 113.5 verdict re-derived for the beta surface.
  static const String passVerdict = 'SUPPORT_INCIDENT_READINESS_DEFINED_LOCAL';

  static const String blockedVerdict =
      'SUPPORT_INCIDENT_READINESS_BLOCKED_NO_LOCAL_EVIDENCE';
  static const String failVerdict = 'SUPPORT_INCIDENT_READINESS_INCONSISTENT';

  /// The six fields canonical step 117.6 names, in canonical order.
  static const List<String> requiredFields = <String>[
    'support_playbook',
    'severity_matrix',
    'owners',
    'response_targets',
    'recovery_guides',
    'provider_escalation',
  ];

  static const List<String> sourceManifests = <String>[
    readinessManifestPath,
    rolloutManifestPath,
    charterManifestPath,
    cohortManifestPath,
    exposureManifestPath,
  ];

  /// The support playbook 113.5 points responders at.
  static const String supportPlaybookRef =
      'docs/release/v1.2.0-rc.1-support-playbook.md';

  /// The recovery guide 113.5 points responders at.
  static const String recoveryGuideRef =
      'docs/release/v1.2.0-rc.1-recovery-guide.md';

  /// The severity vocabulary 113.5 records, ordered from most to least severe.
  static const List<String> severityLevels = <String>['P0', 'P1', 'P2', 'P3'];
}

class Sprint117SupportLoader {
  const Sprint117SupportLoader();

  Sprint117SupportInput load() =>
      Sprint117SupportInput(rows: _loadRows(), anchor: _loadAnchor());

  Sprint117SupportAnchor? _loadAnchor() {
    final readiness = _readJsonObject(
      Sprint117SupportContract.readinessManifestPath,
    );
    final rollout = _readJsonObject(
      Sprint117SupportContract.rolloutManifestPath,
    );
    final charter = _readJsonObject(
      Sprint117SupportContract.charterManifestPath,
    );
    final cohort = _readJsonObject(Sprint117SupportContract.cohortManifestPath);
    final exposure = _readJsonObject(
      Sprint117SupportContract.exposureManifestPath,
    );
    if (readiness == null ||
        rollout == null ||
        charter == null ||
        cohort == null ||
        exposure == null) {
      return null;
    }

    final severityMatrix = readiness['severity_matrix'];
    final levels = severityMatrix is Map<String, dynamic>
        ? _orderedLevels(severityMatrix.keys.toList(growable: false))
        : const <String>[];

    // The response targets live in their own block and must agree with the
    // severity record: a ladder that answers P0 in two hours while the target
    // table promises nine is a contradiction, not a preference.
    final recordedTargets = <String, int>{};
    final targets = readiness['response_targets'];
    if (targets is Map<String, dynamic>) {
      for (final entry in targets.entries) {
        final level = _text(entry.key);
        final hours = entry.value is Map<String, dynamic>
            ? _int(entry.value['max_response_hours'])
            : 0;
        if (level.isNotEmpty) recordedTargets[level] = hours;
      }
    }

    final providerKill = <String, String>{};
    final undrilled = <String>[];
    for (final kill in _mapList(rollout['provider_kill_switches'])) {
      final killId = _text(kill['kill_id']);
      final provider = _text(kill['provider_id']);
      final connector = _text(kill['connector_id']);
      if (killId.isEmpty) continue;
      if (provider.isNotEmpty) providerKill[provider] = killId;
      if (connector.isNotEmpty) providerKill[connector] = killId;
      if (kill['drill_verified'] != true) undrilled.add(killId);
    }

    // Stop conditions are recorded per stage, not per provider. A provider is
    // reachable by a stop condition when one of the stages it is staged into
    // records a stop. The kill-switch stages are the recorded linkage between a
    // provider and the stages a stop condition could fire in.
    final stopByStage = <String, List<String>>{};
    for (final stop in _mapList(rollout['stop_conditions'])) {
      final stopId = _text(stop['stop_id']);
      final stageId = _text(stop['stage_id']);
      if (stopId.isEmpty || stageId.isEmpty) continue;
      stopByStage.putIfAbsent(stageId, () => <String>[]).add(stopId);
    }
    final stagesByProvider = <String, List<String>>{};
    for (final kill in _mapList(rollout['provider_kill_switches'])) {
      final provider = _text(kill['provider_id']);
      if (provider.isEmpty) continue;
      stagesByProvider[provider] = _stringList(kill['stages']);
    }
    final stopByProvider = <String, List<String>>{};
    for (final entry in stagesByProvider.entries) {
      final stops = <String>{};
      for (final stage in entry.value) {
        stops.addAll(stopByStage[stage] ?? const <String>[]);
      }
      stopByProvider[entry.key] = stops.toList(growable: false);
    }

    // An escalation route is *decided* only where the sources actually decided
    // one: a staged provider with a recorded kill switch and at least one stop
    // condition it can be reached by. Everyone else stays undetermined, because
    // 113.5 predates the beta surface and says nothing about them.
    final surface = _stringList(exposure['exposed_subset']);
    final escalated = <Sprint117ProviderEscalationRecord>[];
    final undetermined = <String>[];
    for (final providerId in surface) {
      final killId = providerKill[providerId] ?? '';
      final stops = stopByProvider[providerId] ?? const <String>[];
      if (killId.isEmpty || stops.isEmpty) {
        undetermined.add(providerId);
        continue;
      }
      escalated.add(
        Sprint117ProviderEscalationRecord(
          providerId: providerId,
          killSwitchId: killId,
          stopConditionIds: stops,
          owner: _incidentOwner(charter),
        ),
      );
    }

    return Sprint117SupportAnchor(
      readinessVerdict: _text(readiness['decision']),
      supportVerdict: _text(cohort['verdict']),
      charterVerdict: _text(charter['verdict']),
      exposureVerdict: _text(exposure['verdict']),
      severityLevels: levels,
      responseTargetHours: _severityResponseHours(readiness, levels),
      recordedResponseTargetHours: recordedTargets,
      surfaceProviderIds: surface,
      providerKill: providerKill,
      recordedStopIds: <String>[
        for (final stop in _mapList(rollout['stop_conditions']))
          _text(stop['stop_id']),
      ],
      providerStopConditions: stopByProvider,
      undrilledKillIds: undrilled,
      escalatedProviders: escalated,
      undeterminedProviders: undetermined,
      charterIncidentOwner: _incidentOwner(charter),
      carriedOpenItems: _stringList(exposure['open_items']),
    );
  }

  /// The severity ladder, ordered by the contract's vocabulary so a manifest
  /// that happens to serialise P3 before P0 still reads from P0 down.
  static List<String> _orderedLevels(List<String> recorded) {
    final known = Sprint117SupportContract.severityLevels
        .where((level) => recorded.contains(level))
        .toList(growable: false);
    final extra = recorded
        .where(
          (level) => !Sprint117SupportContract.severityLevels.contains(level),
        )
        .toList(growable: false);
    return <String>[...known, ...extra];
  }

  /// The authoritative response time is the severity record's own number. The
  /// separate target table is what the gate checks that number against.
  static Map<String, int> _severityResponseHours(
    Map<String, dynamic> readiness,
    List<String> levels,
  ) {
    final matrix = readiness['severity_matrix'];
    if (matrix is! Map<String, dynamic>) return const <String, int>{};
    final result = <String, int>{};
    for (final level in levels) {
      final entry = matrix[level];
      if (entry is Map<String, dynamic>) {
        result[level] = _int(entry['max_response_hours']);
      }
    }
    return result;
  }

  /// 117.2 assigned the `incident` scope to a support owner. That owner is who
  /// a provider escalation routes to, read rather than assumed.
  static String _incidentOwner(Map<String, dynamic> charter) {
    for (final owner in _mapList(charter['owners'])) {
      final scopes = _stringList(owner['scopes']);
      if (scopes.contains('incident')) {
        final ownerId = _text(owner['owner_id']);
        if (ownerId.isNotEmpty) return ownerId;
      }
    }
    return '';
  }

  List<Sprint117ReadinessRow>? _loadRows() {
    final readiness = _readJsonObject(
      Sprint117SupportContract.readinessManifestPath,
    );
    if (readiness == null) return null;

    final rows = <Sprint117ReadinessRow>[];

    final matrix = readiness['severity_matrix'];
    if (matrix is Map<String, dynamic>) {
      for (final level in _orderedLevels(matrix.keys.toList(growable: false))) {
        final entry = matrix[level];
        if (entry is! Map<String, dynamic>) continue;
        rows.add(
          Sprint117SeverityRecord(
            level: level,
            definition: _text(entry['definition']),
            responseTarget: _text(entry['response_target']),
            maxResponseHours: _int(entry['max_response_hours']),
            resolutionTargetHours: _int(entry['resolution_target_hours']),
            owner: _text(entry['owner']),
          ),
        );
      }
    }

    for (final guide in _mapList(readiness['recovery_guides'])) {
      rows.add(
        Sprint117RecoveryGuideRecord(
          scenario: _text(guide['scenario']),
          guidePath: _text(guide['guide_path']),
          owner: _text(guide['owner']),
        ),
      );
    }

    for (final path in _mapList(readiness['escalation_paths'])) {
      rows.add(
        Sprint117EscalationRecord(
          trigger: _text(path['trigger']),
          action: _text(path['action']),
          owner: _text(path['owner']),
          communication: _text(path['communication']),
        ),
      );
    }

    return rows;
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

  static List<Map<String, dynamic>> _mapList(Object? value) {
    if (value is! List<dynamic>) return const <Map<String, dynamic>>[];
    return <Map<String, dynamic>>[
      for (final item in value)
        if (item is Map<String, dynamic>) item,
    ];
  }

  static String _text(Object? value) => value is String ? value.trim() : '';

  static int _int(Object? value) =>
      value is int ? value : int.tryParse('${value ?? ''}') ?? 0;

  static List<String> _stringList(Object? value) {
    if (value is! List<dynamic>) return const <String>[];
    return <String>[
      for (final item in value)
        if (item is String && item.trim().isNotEmpty) item.trim(),
    ];
  }
}

class Sprint117SupportGate {
  const Sprint117SupportGate();

  Sprint117SupportReport evaluate() =>
      evaluateWith(const Sprint117SupportLoader().load());

  Sprint117SupportReport evaluateWith(Sprint117SupportInput input) {
    final missing = <String>{};
    final violations = <String>[];

    // --- anchor ------------------------------------------------------------
    final anchor = input.anchor;
    if (anchor == null) {
      missing.add('support_anchor');
    } else {
      if (anchor.readinessVerdict.trim().isEmpty) {
        // Absent evidence, not a contradiction: an empty verdict has not
        // decided anything, so it must not also be reported as drift.
        missing.add('readiness_verdict');
      } else if (anchor.readinessVerdict !=
          Sprint117SupportContract.readinessVerdict) {
        // A readiness source that is not the recorded decision means the ladder
        // this plan inherited is not one the source stands behind. That is a
        // contradiction to report, not a quiet re-derivation.
        violations.add('anchor_verdict_drift');
        violations.add('anchor_verdict:${anchor.readinessVerdict}');
        missing.add('support_anchor');
      }
      if (anchor.charterVerdict.trim().isEmpty) {
        missing.add('charter_anchor');
      }
      if (anchor.exposureVerdict.trim().isEmpty) {
        missing.add('exposure_anchor');
      }
      if (anchor.severityLevels.isEmpty) {
        missing.add('severity_levels');
      }
      if (anchor.surfaceProviderIds.isEmpty) {
        missing.add('exposed_surface');
      }
      // 117.2 assigned the incident scope. Without it every escalation route in
      // this plan points at nobody.
      if (anchor.charterIncidentOwner.trim().isEmpty) {
        missing.add('incident_owner');
      }
    }

    // --- rows --------------------------------------------------------------
    final rows = input.rows;
    final rowIds = <String>{};
    final severityLevels = <String>[];
    final severityByLevel = <String, Sprint117SeverityRecord>{};
    final guides = <Sprint117RecoveryGuideRecord>[];
    final escalations = <Sprint117EscalationRecord>[];
    final owners = <String>{};

    if (rows == null || rows.isEmpty) {
      missing.add('readiness_rows');
    } else {
      for (final row in rows) {
        final rowId = row.rowId.trim();
        if (rowId.isEmpty) {
          violations.add('row_id_blank');
          continue;
        }
        // A duplicated identity is one row wearing two faces, not two rows. The
        // check keys on the full row id (`severity:P0`, `guide:<scenario>`) so a
        // duplicated rung and a duplicated scenario are both caught here, once,
        // under the fault name that describes them.
        if (!rowIds.add(rowId)) {
          violations.add(
            '${_rowFaultPrefix(row)}_duplicate:${_rowFaultKey(row)}',
          );
          continue;
        }
        switch (row) {
          case Sprint117SeverityRecord():
            severityByLevel[row.level] = row;
            severityLevels.add(row.level);
            if (row.owner.trim().isNotEmpty) owners.add(row.owner.trim());
            _checkSeverity(row, anchor, missing, violations);
          case Sprint117RecoveryGuideRecord():
            guides.add(row);
            if (row.owner.trim().isNotEmpty) owners.add(row.owner.trim());
            _checkGuide(row, missing, violations);
          case Sprint117EscalationRecord():
            escalations.add(row);
            if (row.owner.trim().isNotEmpty) owners.add(row.owner.trim());
            _checkEscalation(row, missing, violations);
        }
      }

      // Every severity level the source records must appear exactly once. A
      // dropped level is a rung removed from the ladder, not a decision to
      // leave it out.
      if (anchor != null) {
        for (final level in anchor.severityLevels) {
          if (!severityByLevel.containsKey(level)) {
            violations.add('severity_unmapped:$level');
          }
        }
      }
    }

    // --- provider escalation ----------------------------------------------
    final escalatedProviders = <String>[];
    final undetermined = <String>[];
    if (anchor != null) {
      final seen = <String>{};
      for (final record in anchor.escalatedProviders) {
        final providerId = record.providerId.trim();
        if (providerId.isEmpty) {
          violations.add('provider_escalation_blank');
          continue;
        }
        if (!seen.add(providerId)) {
          violations.add('provider_escalation_duplicate:$providerId');
          continue;
        }
        // A provider that is both escalated and undetermined is one provider
        // carrying two contradictory decisions, not two decisions.
        if (anchor.undeterminedProviders.contains(providerId)) {
          violations.add('provider_escalation_overlap:$providerId');
          continue;
        }
        // An escalation route for a provider the exposed surface never staged is
        // a leak: it would page somebody about a connector nobody can reach.
        if (anchor.surfaceProviderIds.isNotEmpty &&
            !anchor.surfaceProviderIds.contains(providerId)) {
          violations.add('provider_escalation_unlisted:$providerId');
          continue;
        }

        if (record.killSwitchId.trim().isEmpty) {
          violations.add('provider_escalation_no_kill:$providerId');
          continue;
        }
        final recordedKill = anchor.providerKill[providerId] ?? '';
        if (recordedKill.isEmpty) {
          violations.add(
            'provider_kill_unsourced:$providerId:${record.killSwitchId}',
          );
          continue;
        }
        if (record.killSwitchId.trim() != recordedKill) {
          violations.add(
            'provider_kill_drift:$providerId:${record.killSwitchId}:$recordedKill',
          );
          continue;
        }

        final stops = record.stopConditionIds
            .map((entry) => entry.trim())
            .where((entry) => entry.isNotEmpty)
            .toList(growable: false);
        if (stops.isEmpty) {
          // An escalation route nothing can trigger is a promise that never
          // fires. This is a contradiction, not an unfinished decision.
          violations.add('provider_escalation_no_stop:$providerId');
          continue;
        }
        for (final stop in stops) {
          if (!anchor.recordedStopIds.contains(stop)) {
            violations.add('provider_stop_unsourced:$providerId:$stop');
            continue;
          }
          final reachable =
              anchor.providerStopConditions[providerId] ?? const <String>[];
          if (reachable.isNotEmpty && !reachable.contains(stop)) {
            violations.add('provider_stop_unreachable:$providerId:$stop');
            continue;
          }
        }
        if (record.owner.trim().isEmpty) {
          missing.add('provider_escalation_owner:$providerId');
        }
        escalatedProviders.add(providerId);
      }
      undetermined.addAll(anchor.undeterminedProviders);
    }

    // Every escalated provider must appear in the escalation report, and every
    // undetermined provider must be accounted for exactly once.
    final providerEscalation =
        anchor?.escalatedProviders ??
        const <Sprint117ProviderEscalationRecord>[];
    if (anchor != null && anchor.surfaceProviderIds.isNotEmpty) {
      final accounted = <String>{
        ...escalatedProviders,
        ...anchor.undeterminedProviders,
      };
      for (final providerId in anchor.surfaceProviderIds) {
        if (!accounted.contains(providerId)) {
          violations.add('provider_escalation_unmapped:$providerId');
        }
      }
    }

    // --- referenced documents ---------------------------------------------
    // A recovery guide is a promise to open a document during an incident. The
    // check is against the filesystem, because a dangling path is invisible in
    // a manifest review and fatal in a real one.
    final referenced = <String>{};
    if (anchor != null || rows != null) {
      referenced.add(Sprint117SupportContract.supportPlaybookRef);
      referenced.add(Sprint117SupportContract.recoveryGuideRef);
      for (final guide in guides) {
        if (guide.guidePath.trim().isNotEmpty) {
          referenced.add(guide.guidePath.trim());
        }
      }
    }
    for (final path in referenced) {
      if (!File(path).existsSync()) {
        violations.add('referenced_document_missing:$path');
      }
    }

    // --- response target coverage -----------------------------------------
    // Carried open items can already name an upstream failure this gate also
    // derives (117.4 records the cohort verdict too). Carrying a list and
    // appending to it would report the same open item twice, so the derived
    // additions are de-duplicated against what was carried in.
    final openItems = <String>[...anchor?.carriedOpenItems ?? const <String>[]];
    final openItemSet = openItems.toSet();
    void addOpenItem(String item) {
      if (openItemSet.add(item)) openItems.add(item);
    }

    if (anchor != null) {
      for (final entry in anchor.recordedResponseTargetHours.entries) {
        if (!severityByLevel.containsKey(entry.key)) {
          addOpenItem('response_target_orphan:${entry.key}');
        }
      }
      for (final killId in anchor.undrilledKillIds) {
        addOpenItem('kill_switch_not_drilled:$killId');
      }
      if (anchor.supportVerdict.trim().isNotEmpty &&
          anchor.supportVerdict !=
              Sprint117SupportContract.cohortVerifiedVerdict) {
        addOpenItem('upstream_cohort_not_verified:${anchor.supportVerdict}');
      }
    }
    for (final providerId in undetermined) {
      addOpenItem('provider_escalation_undetermined:$providerId');
    }
    if (referenced.contains(Sprint117SupportContract.supportPlaybookRef) &&
        !File(Sprint117SupportContract.supportPlaybookRef).existsSync()) {
      addOpenItem('support_playbook_missing');
    }
    addOpenItem('release_readiness_defined_not_drill_verified');

    // --- resolution --------------------------------------------------------
    final state = violations.isNotEmpty
        ? Sprint117SupportState.fail
        : missing.isNotEmpty
        ? Sprint117SupportState.blocked
        : Sprint117SupportState.pass;
    final verdict = switch (state) {
      Sprint117SupportState.pass => Sprint117SupportContract.passVerdict,
      Sprint117SupportState.fail => Sprint117SupportContract.failVerdict,
      Sprint117SupportState.blocked => Sprint117SupportContract.blockedVerdict,
    };

    final limitations = <String>[
      'This plan defines support readiness locally only. It is not a support channel, an on-call rotation, or a guarantee of resolution.',
      'Provider escalation is decided only where the rollout staged a kill switch and stop conditions; every other exposed provider carries an escalation decision nobody has made yet.',
      'No incident, page, escalation, kill switch, or support message has been executed: the committed 116.50 plan is a stage fixture and ${anchor?.supportVerdict ?? 'the cohort verdict'} records no verified participant.',
      'Severity levels, owners, and response targets are inherited from the ${Sprint117SupportContract.readinessManifestPath} decision and are not re-negotiated here; all external gates remain $externalGatesText.',
    ];

    final fieldCoverage = <String, int>{
      'support_playbook':
          File(Sprint117SupportContract.supportPlaybookRef).existsSync()
          ? 1
          : 0,
      'severity_matrix': severityLevels.length,
      'owners': owners.length,
      'response_targets': <String>[
        for (final level in severityLevels)
          if ((anchor?.responseTargetHours[level] ?? 0) > 0) level,
      ].length,
      'recovery_guides': guides.length,
      'provider_escalation': escalatedProviders.length,
    };

    return Sprint117SupportReport(
      state: state,
      verdict: verdict,
      missingFields: missing.toList(growable: false),
      violations: violations.toList(growable: false),
      anchor: anchor,
      rows: rows ?? const <Sprint117ReadinessRow>[],
      severityLevels: severityLevels,
      severityByLevel: Map<String, Sprint117SeverityRecord>.unmodifiable(
        severityByLevel,
      ),
      recoveryGuides: guides,
      escalationPaths: escalations,
      providerEscalation: providerEscalation,
      escalatedProviders: escalatedProviders,
      undeterminedProviders: undetermined,
      referencedDocuments: referenced.toList(growable: false),
      owners: owners.toList(growable: false)..sort(),
      charterIncidentOwner: anchor?.charterIncidentOwner ?? '',
      openItems: openItems,
      limitations: limitations,
      fieldCoverage: fieldCoverage,
    );
  }

  static String get externalGatesText => Sprint117SupportContract.externalGates;

  /// The subject of a duplicate fault: the level, scenario, or trigger — not
  /// the prefixed row id, which would read as `severity_duplicate:severity:P0`.
  static String _rowFaultKey(Sprint117ReadinessRow row) => switch (row) {
    Sprint117SeverityRecord() => row.level,
    Sprint117RecoveryGuideRecord() => row.scenario,
    Sprint117EscalationRecord() => row.trigger,
    _ => row.rowId,
  };

  static String _rowFaultPrefix(Sprint117ReadinessRow row) => switch (row) {
    Sprint117SeverityRecord() => 'severity',
    Sprint117RecoveryGuideRecord() => 'recovery_guide',
    Sprint117EscalationRecord() => 'escalation',
    // A row kind that does not exist yet still needs a prefix; an unmapped
    // row must not crash the gate that is meant to report it.
    _ => 'row',
  };

  /// Severity coherence: a rung with no owner is unowned evidence, a rung that
  /// resolves before it answers is a contradiction, and a rung whose response
  /// time drifts from the target table is a disagreement between two records.
  static void _checkSeverity(
    Sprint117SeverityRecord row,
    Sprint117SupportAnchor? anchor,
    Set<String> missing,
    List<String> violations,
  ) {
    final level = row.level.trim();
    if (level.isEmpty) {
      violations.add('severity_level_blank');
      return;
    }
    if (!Sprint117SupportContract.severityLevels.contains(level)) {
      violations.add('severity_unknown_level:$level');
    }
    if (row.definition.trim().isEmpty) {
      missing.add('severity_definition:$level');
    }
    if (row.responseTarget.trim().isEmpty) {
      missing.add('severity_response_target_label:$level');
    }
    if (row.owner.trim().isEmpty) {
      // Nobody answers this rung. That is missing evidence, not a wrong row.
      missing.add('severity_owner:$level');
    }

    if (row.maxResponseHours <= 0) {
      violations.add('severity_response_not_positive:$level');
      return;
    }
    if (row.resolutionTargetHours <= 0) {
      violations.add('severity_resolution_not_positive:$level');
      return;
    }
    if (row.resolutionTargetHours < row.maxResponseHours) {
      violations.add('severity_resolution_before_response:$level');
    }

    final recorded = anchor?.recordedResponseTargetHours[level];
    if (recorded != null && recorded != row.maxResponseHours) {
      violations.add(
        'response_target_drift:$level:$recorded:${row.maxResponseHours}',
      );
    }
  }

  /// A guide that names a document nobody can open is a broken promise made
  /// during an incident, so the path is checked against the filesystem.
  static void _checkGuide(
    Sprint117RecoveryGuideRecord row,
    Set<String> missing,
    List<String> violations,
  ) {
    final scenario = row.scenario.trim();
    if (scenario.isEmpty) {
      violations.add('recovery_guide_scenario_blank');
      return;
    }
    if (row.guidePath.trim().isEmpty) {
      missing.add('recovery_guide_path:$scenario');
    } else if (!File(row.guidePath.trim()).existsSync()) {
      violations.add('recovery_guide_missing_document:${row.guidePath.trim()}');
    }
    if (row.owner.trim().isEmpty) {
      missing.add('recovery_guide_owner:$scenario');
    }
  }

  static void _checkEscalation(
    Sprint117EscalationRecord row,
    Set<String> missing,
    List<String> violations,
  ) {
    final trigger = row.trigger.trim();
    if (trigger.isEmpty) {
      violations.add('escalation_trigger_blank');
      return;
    }
    if (row.action.trim().isEmpty) {
      // Nothing to do when this fires: the route exists but goes nowhere.
      violations.add('escalation_action_blank:$trigger');
    }
    if (row.owner.trim().isEmpty) {
      missing.add('escalation_owner:$trigger');
    }
    if (row.communication.trim().isEmpty) {
      missing.add('escalation_communication:$trigger');
    }
  }
}
