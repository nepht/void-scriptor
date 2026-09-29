library;

import 'dart:convert';
import 'dart:io';

/// Canonical contract for Sprint 116.50, Staged Beta Rollout & Monitoring.
///
/// A rollout plan is easy to fake in three independent ways: ship a flag that
/// is already ON so there is nothing left to turn off, describe stages that
/// cannot be advanced or stopped, and declare health metrics that nobody
/// acts on. Each of those is caught here as a rule or a join instead of
/// prose: every flag defaults OFF and names stages that exist, every stage
/// has a stop condition, a rollback path and non-shrinking exposure, every
/// health metric feeds at least one stop condition, every connector exposed
/// in a stage has a kill switch covering that stage, and every incident
/// trigger has a communication record drafted before it can fire.
///
/// Every fixture shipped with this contract is synthetic and UNVERIFIED. No
/// flag has been flipped, no stage has been advanced, and no kill switch or
/// rollback has been executed against a live provider.
enum Sprint116StagedRolloutStatus { pass, fail, blocked }

/// One beta feature flag. The default state is not decoration: a flag that
/// ships ON has no rollback left to fall back to.
class Sprint116RolloutFlagRecord {
  Sprint116RolloutFlagRecord({
    required this.flagId,
    required this.flagKey,
    required this.defaultState,
    required this.owner,
    required this.linkedStages,
    required this.source,
    required this.evidenceRef,
  });

  final String flagId;
  final String flagKey;
  final String defaultState;
  final String owner;
  final List<String> linkedStages;
  final String source;
  final String? evidenceRef;
}

/// One stage of the rollout: an ordered slice of the cohort, its entry and
/// exit criteria, and the connectors it exposes to those users.
class Sprint116RolloutStageRecord {
  Sprint116RolloutStageRecord({
    required this.stageId,
    required this.sequence,
    required this.exposurePercent,
    required this.entryCriteria,
    required this.exitCriteria,
    required this.exposedConnectors,
    required this.source,
    required this.evidenceRef,
  });

  final String stageId;
  final int sequence;
  final int exposurePercent;
  final List<String> entryCriteria;
  final List<String> exitCriteria;
  final List<String> exposedConnectors;
  final String source;
  final String? evidenceRef;
}

/// One health metric watched during the rollout, with the direction that
/// makes it worse and the window it is measured over.
class Sprint116RolloutHealthMetricRecord {
  Sprint116RolloutHealthMetricRecord({
    required this.metricId,
    required this.metricName,
    required this.metricType,
    required this.direction,
    required this.threshold,
    required this.windowMinutes,
    required this.source,
    required this.evidenceRef,
  });

  final String metricId;
  final String metricName;
  final String metricType;
  final String direction;
  final double threshold;
  final int windowMinutes;
  final String source;
  final String? evidenceRef;
}

/// The rule that turns a metric into an action on a stage.
class Sprint116RolloutStopConditionRecord {
  Sprint116RolloutStopConditionRecord({
    required this.stopId,
    required this.stageId,
    required this.metricId,
    required this.operator,
    required this.threshold,
    required this.windowMinutes,
    required this.action,
    required this.source,
    required this.evidenceRef,
  });

  final String stopId;
  final String stageId;
  final String metricId;
  final String operator;
  final double threshold;
  final int windowMinutes;
  final String action;
  final String source;
  final String? evidenceRef;
}

/// The switch that takes a provider out of the beta without shipping a new
/// build, plus whether it has actually been drilled.
class Sprint116RolloutKillSwitchRecord {
  Sprint116RolloutKillSwitchRecord({
    required this.killId,
    required this.providerId,
    required this.connectorId,
    required this.scope,
    required this.flagRef,
    required this.stages,
    required this.drillVerified,
    required this.drillAtEpochMs,
    required this.source,
    required this.evidenceRef,
  });

  final String killId;
  final String providerId;
  final String connectorId;
  final String scope;
  final String flagRef;
  final List<String> stages;
  final bool drillVerified;
  final int drillAtEpochMs;
  final String source;
  final String? evidenceRef;
}

/// How one target gets put back the way it was. Rollback touches beta
/// exposure, never the user's local project data — the manuscript belongs to
/// the user and survives any rollout.
class Sprint116RolloutRollbackRecord {
  Sprint116RolloutRollbackRecord({
    required this.rollbackId,
    required this.targetScope,
    required this.targetId,
    required this.procedure,
    required this.localProjectDataTouched,
    required this.verifiedAtEpochMs,
    required this.source,
    required this.evidenceRef,
  });

  final String rollbackId;
  final String targetScope;
  final String targetId;
  final String procedure;
  final bool localProjectDataTouched;
  final int verifiedAtEpochMs;
  final String source;
  final String? evidenceRef;
}

/// One pre-drafted message for one incident trigger and audience.
class Sprint116RolloutCommunicationRecord {
  Sprint116RolloutCommunicationRecord({
    required this.commId,
    required this.audience,
    required this.channel,
    required this.trigger,
    required this.messageTemplate,
    required this.draftedAtEpochMs,
    required this.sentAtEpochMs,
    required this.source,
    required this.evidenceRef,
  });

  final String commId;
  final String audience;
  final String channel;
  final String trigger;
  final String messageTemplate;
  final int draftedAtEpochMs;
  final int sentAtEpochMs;
  final String source;
  final String? evidenceRef;
}

/// One registered artifact backing a claim. Evidence is not a required field
/// of this step; it exists so a `live` or `local_run` row has somewhere real
/// to point.
class Sprint116RolloutEvidenceRecord {
  Sprint116RolloutEvidenceRecord({
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

class Sprint116StagedRolloutControlSet {
  Sprint116StagedRolloutControlSet({
    required this.flags,
    required this.stages,
    required this.healthMetrics,
    required this.stopConditions,
    required this.killSwitches,
    required this.rollback,
    required this.communication,
    required this.evidence,
  });

  final List<Sprint116RolloutFlagRecord> flags;
  final List<Sprint116RolloutStageRecord> stages;
  final List<Sprint116RolloutHealthMetricRecord> healthMetrics;
  final List<Sprint116RolloutStopConditionRecord> stopConditions;
  final List<Sprint116RolloutKillSwitchRecord> killSwitches;
  final List<Sprint116RolloutRollbackRecord> rollback;
  final List<Sprint116RolloutCommunicationRecord> communication;
  final List<Sprint116RolloutEvidenceRecord> evidence;
}

class Sprint116StagedRolloutReport {
  Sprint116StagedRolloutReport({
    required this.state,
    required this.invalidRecords,
    required this.coveredFields,
  });

  final Sprint116StagedRolloutStatus state;
  final List<String> invalidRecords;

  /// Required fields that carry at least one record with no rule failure and
  /// a supportable source. The rest are gaps, not passes.
  final List<String> coveredFields;

  String get externalGates => Sprint116StagedRolloutContract.externalGates;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'canonical_step': Sprint116StagedRolloutContract.canonicalStep,
      'state': state.name,
      'invalid_records': invalidRecords,
      'covered_fields': coveredFields,
      'live_rollout_executed': false,
      'beta_feature_flags_default':
          Sprint116StagedRolloutContract.defaultFlagState,
      'external_gates': externalGates,
    };
  }
}

abstract final class Sprint116StagedRolloutContract {
  static const String canonicalStep = '116.50';
  static const String manifestPath =
      'docs/planning/v1.2/sprint_116_staged_beta_rollout_monitoring.json';
  static const String externalGates = 'DEFERRED-EXTERNAL';

  /// The seven fields canonical step 116.50 names, in canonical order.
  static const List<String> requiredFields = <String>[
    'flags',
    'stages',
    'health_metrics',
    'stop_conditions',
    'provider_kill_switches',
    'rollback',
    'communication',
  ];

  static const List<String> supportedSources = <String>[
    'synthetic_local',
    'live',
    'local_run',
  ];

  /// Sources that may only be believed when they point at a registered
  /// evidence artifact.
  static const List<String> evidencedSources = <String>['live', 'local_run'];

  /// Sprint 116 certification rule `beta_feature_flags_default`. A beta flag
  /// that ships ON has no rollback left to fall back to.
  static const String defaultFlagState = 'OFF';
  static const List<String> knownFlagStates = <String>['OFF', 'ON'];

  static const List<String> knownMetricTypes = <String>[
    'error_rate',
    'crash_rate',
    'latency_ms',
    'auth_success_rate',
    'quota_usage_ratio',
    'sync_failure_rate',
  ];

  static const List<String> knownMetricDirections = <String>[
    'higher_is_worse',
    'lower_is_worse',
  ];

  static const List<String> knownStopOperators = <String>[
    'gt',
    'gte',
    'lt',
    'lte',
  ];

  static const List<String> knownStopActions = <String>[
    'halt_rollout',
    'rollback_stage',
    'page_oncall',
  ];

  static const List<String> knownKillScopes = <String>[
    'connector_disable',
    'operation_block',
    'stage_exit',
  ];

  static const List<String> knownTargetScopes = <String>[
    'stage',
    'flag',
    'provider',
  ];

  static const List<String> knownAudiences = <String>[
    'beta_participants',
    'internal_oncall',
    'status_page',
    'providers',
  ];

  static const List<String> knownCommChannels = <String>[
    'in_app',
    'email',
    'status_page',
    'issue_tracker',
    'internal_alert',
  ];

  /// Every trigger here must have a communication record: an incident with
  /// no message is a silent one.
  static const List<String> knownCommTriggers = <String>[
    'stage_advance',
    'stop_condition_hit',
    'rollback_executed',
    'kill_switch_used',
  ];

  static const int minExposurePercent = 0;
  static const int maxExposurePercent = 100;
}

class Sprint116StagedRolloutPlan {
  /// Certifies the seven fields of step 116.50.
  ///
  /// The manifest fixture is consulted only when [controls] is omitted, so an
  /// explicit control set can never borrow fixture rows to pass.
  Sprint116StagedRolloutReport certify({
    Sprint116StagedRolloutControlSet? controls,
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
      if (effective.flags.isEmpty) 'flags',
      if (effective.stages.isEmpty) 'stages',
      if (effective.healthMetrics.isEmpty) 'health_metrics',
      if (effective.stopConditions.isEmpty) 'stop_conditions',
      if (effective.killSwitches.isEmpty) 'provider_kill_switches',
      if (effective.rollback.isEmpty) 'rollback',
      if (effective.communication.isEmpty) 'communication',
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
      if (!Sprint116StagedRolloutContract.supportedSources.contains(
        trimmedSource,
      )) {
        invalid.add('no_mock_values:$key');
        sourceClean = false;
      } else if (Sprint116StagedRolloutContract.evidencedSources.contains(
            trimmedSource,
          ) &&
          (evidenceRef == null || evidenceRef.trim().isEmpty)) {
        invalid.add('no_mock_values:$key');
        sourceClean = false;
      }
      var registerClean = true;
      if (Sprint116StagedRolloutContract.evidencedSources.contains(
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

    for (final record in effective.flags) {
      final failures = <String>{};
      _certifyFlag(record, failures);
      run(
        field: 'flags',
        identity: record.flagId,
        failures: failures,
        source: record.source,
        evidenceRef: record.evidenceRef,
      );
    }

    for (final record in effective.stages) {
      final failures = <String>{};
      _certifyStage(record, failures);
      run(
        field: 'stages',
        identity: record.stageId,
        failures: failures,
        source: record.source,
        evidenceRef: record.evidenceRef,
      );
    }

    for (final record in effective.healthMetrics) {
      final failures = <String>{};
      _certifyMetric(record, failures);
      run(
        field: 'health_metrics',
        identity: record.metricId,
        failures: failures,
        source: record.source,
        evidenceRef: record.evidenceRef,
      );
    }

    for (final record in effective.stopConditions) {
      final failures = <String>{};
      _certifyStop(record, failures);
      run(
        field: 'stop_conditions',
        identity: record.stopId,
        failures: failures,
        source: record.source,
        evidenceRef: record.evidenceRef,
      );
    }

    for (final record in effective.killSwitches) {
      final failures = <String>{};
      _certifyKillSwitch(record, effectiveAsOf, failures);
      run(
        field: 'provider_kill_switches',
        identity: record.killId,
        failures: failures,
        source: record.source,
        evidenceRef: record.evidenceRef,
      );
    }

    for (final record in effective.rollback) {
      final failures = <String>{};
      _certifyRollback(record, effectiveAsOf, failures);
      run(
        field: 'rollback',
        identity: record.rollbackId,
        failures: failures,
        source: record.source,
        evidenceRef: record.evidenceRef,
      );
    }

    for (final record in effective.communication) {
      final failures = <String>{};
      _certifyCommunication(record, effectiveAsOf, failures);
      run(
        field: 'communication',
        identity: record.commId,
        failures: failures,
        source: record.source,
        evidenceRef: record.evidenceRef,
      );
    }

    invalid.addAll(_crossRecordJoins(effective));

    if (requireCoverage) {
      for (final field in Sprint116StagedRolloutContract.requiredFields) {
        if (!covered.contains(field)) {
          invalid.add('area_coverage:$field');
        }
      }
    }

    final coveredFields = Sprint116StagedRolloutContract.requiredFields
        .where(covered.contains)
        .toList(growable: false);
    return Sprint116StagedRolloutReport(
      state: invalid.isEmpty
          ? Sprint116StagedRolloutStatus.pass
          : Sprint116StagedRolloutStatus.fail,
      invalidRecords: invalid.toList(growable: false),
      coveredFields: coveredFields,
    );
  }

  void _certifyFlag(Sprint116RolloutFlagRecord record, Set<String> failed) {
    if (record.flagKey.trim().isEmpty) {
      // A flag without a key cannot be toggled from anywhere.
      failed.add('flag_key');
    }
    if (record.defaultState.trim() !=
        Sprint116StagedRolloutContract.defaultFlagState) {
      // The sprint rule is beta_feature_flags_default = OFF: a flag that
      // ships ON has nothing left to roll back to.
      failed.add('flag_default');
    }
    if (record.owner.trim().isEmpty) {
      // Nobody owns the flag, so nobody is accountable when it misbehaves.
      failed.add('flag_owner');
    }
    if (record.linkedStages.isEmpty) {
      // A flag that gates no stage is not part of a staged rollout.
      failed.add('flag_stages');
    }
  }

  void _certifyStage(Sprint116RolloutStageRecord record, Set<String> failed) {
    if (record.sequence <= 0) {
      failed.add('stage_sequence');
    }
    if (record.exposurePercent <
            Sprint116StagedRolloutContract.minExposurePercent ||
        record.exposurePercent >
            Sprint116StagedRolloutContract.maxExposurePercent) {
      failed.add('stage_range');
    }
    if (record.entryCriteria.isEmpty ||
        record.entryCriteria.any((criterion) => criterion.trim().isEmpty)) {
      // A stage with no entry criterion admits anyone.
      failed.add('stage_entry');
    }
    if (record.exitCriteria.isEmpty ||
        record.exitCriteria.any((criterion) => criterion.trim().isEmpty)) {
      // A stage with no exit criterion never ends.
      failed.add('stage_exit');
    }
    if (record.exposedConnectors.any((connector) => connector.trim().isEmpty)) {
      failed.add('stage_connector');
    }
  }

  void _certifyMetric(
    Sprint116RolloutHealthMetricRecord record,
    Set<String> failed,
  ) {
    if (!Sprint116StagedRolloutContract.knownMetricTypes.contains(
      record.metricType.trim(),
    )) {
      failed.add('metric_type');
    }
    if (!Sprint116StagedRolloutContract.knownMetricDirections.contains(
      record.direction.trim(),
    )) {
      failed.add('metric_direction');
    }
    if (!record.threshold.isFinite || record.threshold < 0) {
      // A threshold that is not a reachable number can never be breached,
      // so the metric would be watched forever without ever firing.
      failed.add('metric_threshold');
    }
    if (record.windowMinutes <= 0) {
      failed.add('metric_window');
    }
  }

  void _certifyStop(
    Sprint116RolloutStopConditionRecord record,
    Set<String> failed,
  ) {
    if (!Sprint116StagedRolloutContract.knownStopOperators.contains(
      record.operator.trim(),
    )) {
      failed.add('stop_operator');
    }
    if (!Sprint116StagedRolloutContract.knownStopActions.contains(
      record.action.trim(),
    )) {
      failed.add('stop_action');
    }
    if (!record.threshold.isFinite || record.threshold < 0) {
      failed.add('stop_threshold');
    }
    if (record.windowMinutes <= 0) {
      failed.add('stop_window');
    }
  }

  void _certifyKillSwitch(
    Sprint116RolloutKillSwitchRecord record,
    int asOfEpochMs,
    Set<String> failed,
  ) {
    if (record.providerId.trim().isEmpty) {
      failed.add('kill_provider');
    }
    if (record.connectorId.trim().isEmpty) {
      failed.add('kill_connector');
    }
    if (!Sprint116StagedRolloutContract.knownKillScopes.contains(
      record.scope.trim(),
    )) {
      failed.add('kill_scope');
    }
    if (record.stages.isEmpty) {
      // A kill switch that covers no stage disables nothing.
      failed.add('kill_stages');
    }
    if (record.stages.any((stage) => stage.trim().isEmpty)) {
      failed.add('kill_stage');
    }
    if (record.drillVerified) {
      final dated =
          record.drillAtEpochMs > 0 && record.drillAtEpochMs <= asOfEpochMs;
      if (!dated || !_evidenceBacked(record.source, record.evidenceRef)) {
        // "The kill switch works" is a claim about a past event: it needs a
        // date inside the clock and an artifact, not a fixture row.
        failed.add('kill_drill');
      }
    }
  }

  void _certifyRollback(
    Sprint116RolloutRollbackRecord record,
    int asOfEpochMs,
    Set<String> failed,
  ) {
    if (!Sprint116StagedRolloutContract.knownTargetScopes.contains(
      record.targetScope.trim(),
    )) {
      failed.add('rollback_scope');
    }
    if (record.procedure.trim().isEmpty) {
      failed.add('rollback_procedure');
    }
    if (record.localProjectDataTouched) {
      // Over-deletion still loses data: the manuscript belongs to the user
      // and survives any rollout.
      failed.add('rollback_local_data');
    }
    if (record.verifiedAtEpochMs > asOfEpochMs) {
      failed.add('rollback_time');
    }
    if (record.verifiedAtEpochMs > 0) {
      if (!_evidenceBacked(record.source, record.evidenceRef)) {
        // A rollback drill that was never run against anything real cannot
        // be certified as verified.
        failed.add('rollback_verify');
      }
    }
  }

  void _certifyCommunication(
    Sprint116RolloutCommunicationRecord record,
    int asOfEpochMs,
    Set<String> failed,
  ) {
    if (!Sprint116StagedRolloutContract.knownAudiences.contains(
      record.audience.trim(),
    )) {
      failed.add('comm_audience');
    }
    if (!Sprint116StagedRolloutContract.knownCommChannels.contains(
      record.channel.trim(),
    )) {
      failed.add('comm_channel');
    }
    if (!Sprint116StagedRolloutContract.knownCommTriggers.contains(
      record.trigger.trim(),
    )) {
      failed.add('comm_trigger_kind');
    }
    if (record.messageTemplate.trim().isEmpty) {
      // A template with no text says nothing when the incident happens.
      failed.add('comm_message');
    }
    if (record.draftedAtEpochMs <= 0 || record.draftedAtEpochMs > asOfEpochMs) {
      // The message has to exist before the trigger, not after it.
      failed.add('comm_time');
    }
    if (record.sentAtEpochMs > asOfEpochMs) {
      failed.add('comm_time');
    }
    if (record.sentAtEpochMs > 0) {
      if (!_evidenceBacked(record.source, record.evidenceRef)) {
        failed.add('comm_sent');
      }
    }
  }

  /// Joins that a record cannot refute on its own: a flag pointing at a
  /// stage that does not exist, a stage with no stop condition and no
  /// rollback, a metric nobody acts on, a stop condition aiming at nothing,
  /// an exposed connector with no kill switch covering that stage, and an
  /// incident trigger with no message.
  List<String> _crossRecordJoins(Sprint116StagedRolloutControlSet controls) {
    final invalid = <String>[];

    final stageIds = <String>{
      for (final row in controls.stages) row.stageId.trim(),
    }..remove('');
    final flagIds = <String>{
      for (final row in controls.flags) row.flagId.trim(),
    }..remove('');
    final metricIds = <String>{
      for (final row in controls.healthMetrics) row.metricId.trim(),
    }..remove('');
    final providerIds = <String>{
      for (final row in controls.killSwitches) row.providerId.trim(),
    }..remove('');
    final stopStages = <String>{
      for (final row in controls.stopConditions) row.stageId.trim(),
    };
    final stopMetrics = <String>{
      for (final row in controls.stopConditions) row.metricId.trim(),
    };

    for (final row in controls.flags) {
      final flagId = row.flagId.trim();
      if (flagId.isEmpty) continue;
      for (final stage in row.linkedStages) {
        if (!stageIds.contains(stage.trim())) {
          // The flag gates a stage that does not exist.
          invalid.add('flag_stage:$flagId');
          break;
        }
      }
    }

    // Ordering checks need the list as written: sequence and exposure must
    // only ever move forward, otherwise a "later" stage is a rollback in
    // disguise.
    var previousSequence = 0;
    var previousExposure = 0;
    var hasPrevious = false;
    for (final row in controls.stages) {
      final stageId = row.stageId.trim();
      if (stageId.isEmpty) continue;
      if (hasPrevious && row.sequence <= previousSequence) {
        invalid.add('stage_order:$stageId');
      }
      if (hasPrevious && row.exposurePercent < previousExposure) {
        invalid.add('stage_exposure:$stageId');
      }
      previousSequence = row.sequence;
      previousExposure = row.exposurePercent;
      hasPrevious = true;
    }

    for (final row in controls.stopConditions) {
      final stopId = row.stopId.trim();
      if (stopId.isEmpty) continue;
      if (!stageIds.contains(row.stageId.trim())) {
        invalid.add('stop_stage:$stopId');
      }
      if (!metricIds.contains(row.metricId.trim())) {
        invalid.add('stop_metric:$stopId');
      }
    }

    for (final stageId in stageIds) {
      if (!stopStages.contains(stageId)) {
        // A stage with no stop condition cannot be halted from anywhere.
        invalid.add('stage_stop:$stageId');
      }
      if (!controls.rollback.any(
        (row) =>
            row.targetScope.trim() == 'stage' && row.targetId.trim() == stageId,
      )) {
        invalid.add('stage_rollback:$stageId');
      }
    }

    for (final metricId in metricIds) {
      if (!stopMetrics.contains(metricId)) {
        // A metric nobody acts on is decoration, not monitoring.
        invalid.add('metric_action:$metricId');
      }
    }

    for (final row in controls.killSwitches) {
      final killId = row.killId.trim();
      if (killId.isEmpty) continue;
      final flagRef = row.flagRef.trim();
      if (flagRef.isEmpty || !flagIds.contains(flagRef)) {
        invalid.add('kill_flag:$killId');
      }
      for (final stage in row.stages) {
        if (!stageIds.contains(stage.trim())) {
          invalid.add('kill_stage:$killId');
          break;
        }
      }
    }

    // Every connector a stage hands to its users needs a switch that
    // reaches that specific stage, not just the provider in general.
    for (final stage in controls.stages) {
      final stageId = stage.stageId.trim();
      if (stageId.isEmpty) continue;
      for (final connector in stage.exposedConnectors) {
        final connectorId = connector.trim();
        if (connectorId.isEmpty) continue;
        final covered = controls.killSwitches.any(
          (row) =>
              row.connectorId.trim() == connectorId &&
              row.stages.any((candidate) => candidate.trim() == stageId),
        );
        if (!covered) {
          invalid.add('kill_switch:$connectorId:$stageId');
        }
      }
    }

    for (final row in controls.rollback) {
      final rollbackId = row.rollbackId.trim();
      if (rollbackId.isEmpty) continue;
      final known = switch (row.targetScope.trim()) {
        'stage' => stageIds.contains(row.targetId.trim()),
        'flag' => flagIds.contains(row.targetId.trim()),
        'provider' => providerIds.contains(row.targetId.trim()),
        _ => false,
      };
      if (!known) {
        invalid.add('rollback_target:$rollbackId');
      }
    }

    final coveredTriggers = <String>{
      for (final row in controls.communication) row.trigger.trim(),
    };
    for (final trigger in Sprint116StagedRolloutContract.knownCommTriggers) {
      if (!coveredTriggers.contains(trigger)) {
        // An incident with no message is a silent one.
        invalid.add('comm_trigger:$trigger');
      }
    }

    return invalid;
  }

  /// A row may only claim a real-world observation when its source can carry
  /// one and it points at an artifact. The artifact is checked separately by
  /// the register join, so this stays a cheap precondition.
  bool _evidenceBacked(String source, String? evidenceRef) {
    return Sprint116StagedRolloutContract.evidencedSources.contains(
          source.trim(),
        ) &&
        evidenceRef != null &&
        evidenceRef.trim().isNotEmpty;
  }

  Sprint116StagedRolloutReport _blocked(String reason) {
    return Sprint116StagedRolloutReport(
      state: Sprint116StagedRolloutStatus.blocked,
      invalidRecords: <String>[reason],
      coveredFields: const <String>[],
    );
  }

  Map<String, dynamic>? _readManifest() {
    final file = File(Sprint116StagedRolloutContract.manifestPath);
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

  Sprint116StagedRolloutControlSet _controlsFromManifest(
    Map<String, dynamic>? manifest,
  ) {
    return Sprint116StagedRolloutControlSet(
      flags: _mapList(manifest, 'flags', _flagFrom),
      stages: _mapList(manifest, 'stages', _stageFrom),
      healthMetrics: _mapList(manifest, 'health_metrics', _metricFrom),
      stopConditions: _mapList(manifest, 'stop_conditions', _stopFrom),
      killSwitches: _mapList(manifest, 'provider_kill_switches', _killFrom),
      rollback: _mapList(manifest, 'rollback', _rollbackFrom),
      communication: _mapList(manifest, 'communication', _commFrom),
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
  double _double(Object? raw) => raw is num ? raw.toDouble() : 0;
  bool _bool(Object? raw) => raw == true;

  String? _ref(Object? raw) =>
      raw is String && raw.trim().isNotEmpty ? raw : null;

  Sprint116RolloutFlagRecord _flagFrom(Map<Object?, Object?> item) {
    return Sprint116RolloutFlagRecord(
      flagId: _string(item['flag_id']),
      flagKey: _string(item['flag_key']),
      defaultState: _string(item['default_state']),
      owner: _string(item['owner']),
      linkedStages: _stringList(item['linked_stages']),
      source: _string(item['source']),
      evidenceRef: _ref(item['evidence_ref']),
    );
  }

  Sprint116RolloutStageRecord _stageFrom(Map<Object?, Object?> item) {
    return Sprint116RolloutStageRecord(
      stageId: _string(item['stage_id']),
      sequence: _int(item['sequence']),
      exposurePercent: _int(item['exposure_percent']),
      entryCriteria: _stringList(item['entry_criteria']),
      exitCriteria: _stringList(item['exit_criteria']),
      exposedConnectors: _stringList(item['exposed_connectors']),
      source: _string(item['source']),
      evidenceRef: _ref(item['evidence_ref']),
    );
  }

  Sprint116RolloutHealthMetricRecord _metricFrom(Map<Object?, Object?> item) {
    return Sprint116RolloutHealthMetricRecord(
      metricId: _string(item['metric_id']),
      metricName: _string(item['metric_name']),
      metricType: _string(item['metric_type']),
      direction: _string(item['direction']),
      threshold: _double(item['threshold']),
      windowMinutes: _int(item['window_minutes']),
      source: _string(item['source']),
      evidenceRef: _ref(item['evidence_ref']),
    );
  }

  Sprint116RolloutStopConditionRecord _stopFrom(Map<Object?, Object?> item) {
    return Sprint116RolloutStopConditionRecord(
      stopId: _string(item['stop_id']),
      stageId: _string(item['stage_id']),
      metricId: _string(item['metric_id']),
      operator: _string(item['operator']),
      threshold: _double(item['threshold']),
      windowMinutes: _int(item['window_minutes']),
      action: _string(item['action']),
      source: _string(item['source']),
      evidenceRef: _ref(item['evidence_ref']),
    );
  }

  Sprint116RolloutKillSwitchRecord _killFrom(Map<Object?, Object?> item) {
    return Sprint116RolloutKillSwitchRecord(
      killId: _string(item['kill_id']),
      providerId: _string(item['provider_id']),
      connectorId: _string(item['connector_id']),
      scope: _string(item['scope']),
      flagRef: _string(item['flag_ref']),
      stages: _stringList(item['stages']),
      drillVerified: _bool(item['drill_verified']),
      drillAtEpochMs: _int(item['drill_at_epoch_ms']),
      source: _string(item['source']),
      evidenceRef: _ref(item['evidence_ref']),
    );
  }

  Sprint116RolloutRollbackRecord _rollbackFrom(Map<Object?, Object?> item) {
    return Sprint116RolloutRollbackRecord(
      rollbackId: _string(item['rollback_id']),
      targetScope: _string(item['target_scope']),
      targetId: _string(item['target_id']),
      procedure: _string(item['procedure']),
      localProjectDataTouched: _bool(item['local_project_data_touched']),
      verifiedAtEpochMs: _int(item['verified_at_epoch_ms']),
      source: _string(item['source']),
      evidenceRef: _ref(item['evidence_ref']),
    );
  }

  Sprint116RolloutCommunicationRecord _commFrom(Map<Object?, Object?> item) {
    return Sprint116RolloutCommunicationRecord(
      commId: _string(item['comm_id']),
      audience: _string(item['audience']),
      channel: _string(item['channel']),
      trigger: _string(item['trigger']),
      messageTemplate: _string(item['message_template']),
      draftedAtEpochMs: _int(item['drafted_at_epoch_ms']),
      sentAtEpochMs: _int(item['sent_at_epoch_ms']),
      source: _string(item['source']),
      evidenceRef: _ref(item['evidence_ref']),
    );
  }

  Sprint116RolloutEvidenceRecord _evidenceFrom(Map<Object?, Object?> item) {
    return Sprint116RolloutEvidenceRecord(
      evidenceId: _string(item['evidence_id']),
      claim: _string(item['claim']),
      artifact: _string(item['artifact']),
      recordedAtEpochMs: _int(item['recorded_at_epoch_ms']),
      source: _string(item['source']),
      evidenceRef: _ref(item['evidence_ref']),
    );
  }
}
