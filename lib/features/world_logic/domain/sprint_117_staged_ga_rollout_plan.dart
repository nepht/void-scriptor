import 'dart:convert';
import 'dart:io';

/// Canonical step 117.44 — Staged GA Rollout Plan.
///
/// Objective (external canonical JSON): determine the stages, the certified
/// subset exposure, the health criteria, the stop conditions, the provider
/// kill switches, the rollback, and the support path.
///
/// The eight canonical fields are not decoration. A staged GA rollout is the
/// step that actually moves certified connectors in front of users, so every
/// field it names has to be read out of committed evidence rather than typed
/// into the plan. A stage that exposes a connector nobody certified, a stop
/// condition whose metric the rollout never records, a kill switch for a
/// provider the subset never stages, or a rollback that targets a stage that
/// does not exist are each a way for the plan to look complete while it is not.
///
/// Two rules carry the weight:
///
/// * The rollout may only expose the *certified subset*. The subset is the
///   intersection of the connectors 117.4 certified and the connectors 116.50
///   stages, and a stage that exposes anything outside it is a violation, not a
///   wider beta — `uncertified_connector_release_allowed` is false and this gate
///   is where that rule is enforced rather than asserted.
/// * The plan is *determined*, never *enabled*. 117.5 already determined local
///   exposure for the staged connectors and enabled none because 117.3 records
///   no verified participant cohort. A rollout plan that reported enabled
///   exposure would be claiming a cohort that does not exist.
///
/// Nothing here is a live rollout: no flag is flipped, no stage advanced, no
/// stop condition fired, no kill switch drilled, and no rollback executed. Those
/// remain [Sprint117RolloutContract.externalGates].
enum Sprint117RolloutState { pass, fail, blocked }

/// One planned stage of the staged GA rollout, derived from committed evidence.
class Sprint117RolloutStageRecord {
  Sprint117RolloutStageRecord({
    required this.stageId,
    required this.sequence,
    required this.exposurePercent,
    required List<String> exposedProviders,
    required List<String> entryCriteria,
    required List<String> exitCriteria,
    required List<String> healthMetricIds,
    required List<String> stopConditionIds,
    required List<String> killSwitchIds,
    required this.rollbackId,
    required this.supportOwner,
  }) : exposedProviders = List<String>.unmodifiable(exposedProviders),
       entryCriteria = List<String>.unmodifiable(entryCriteria),
       exitCriteria = List<String>.unmodifiable(exitCriteria),
       healthMetricIds = List<String>.unmodifiable(healthMetricIds),
       stopConditionIds = List<String>.unmodifiable(stopConditionIds),
       killSwitchIds = List<String>.unmodifiable(killSwitchIds);

  final String stageId;
  final int sequence;
  final int exposurePercent;

  /// The certified providers this stage exposes. A provider here that is not in
  /// the certified subset is a rollout wider than the certification.
  final List<String> exposedProviders;

  final List<String> entryCriteria;
  final List<String> exitCriteria;

  /// The health metrics this stage is measured by.
  final List<String> healthMetricIds;

  /// The stop conditions attached to this stage.
  final List<String> stopConditionIds;

  /// The kill switches covering this stage's exposed providers.
  final List<String> killSwitchIds;

  final String rollbackId;
  final String supportOwner;

  Map<String, Object?> toJson() => <String, Object?>{
    'stage_id': stageId,
    'sequence': sequence,
    'exposure_percent': exposurePercent,
    'exposed_providers': List<String>.from(exposedProviders),
    'entry_criteria': List<String>.from(entryCriteria),
    'exit_criteria': List<String>.from(exitCriteria),
    'health_criteria': List<String>.from(healthMetricIds),
    'stop_conditions': List<String>.from(stopConditionIds),
    'kill_switches': List<String>.from(killSwitchIds),
    'rollback': rollbackId,
    'support': supportOwner,
  };
}

/// The evidence this plan is allowed to decide from.
class Sprint117RolloutAnchor {
  Sprint117RolloutAnchor({
    required this.exposureVerdict,
    required this.exposureMatrixVerdict,
    required this.supportVerdict,
    required this.rollbackVerdict,
    required List<String> certifiedSubset,
    required List<String> determinedExposed,
    required List<String> enabledSubset,
    required this.recordedDefault,
    required this.masterFlagKey,
    required List<String> stagedConnectors,
    required List<String> recordedMetricIds,
    required Map<String, String> metricDirection,
    required Map<String, String> stopAction,
    required Map<String, String> stopStage,
    required Map<String, String> stopMetric,
    required Map<String, String> killProvider,
    required Map<String, String> rollbackTarget,
    required Map<String, String> supportOwnerByProvider,
    required this.charterIncidentOwner,
    required this.drillExecuted,
    required List<String> undrilledKillIds,
    required List<String> carriedOpenItems,
  }) : certifiedSubset = List<String>.unmodifiable(certifiedSubset),
       determinedExposed = List<String>.unmodifiable(determinedExposed),
       enabledSubset = List<String>.unmodifiable(enabledSubset),
       stagedConnectors = List<String>.unmodifiable(stagedConnectors),
       recordedMetricIds = List<String>.unmodifiable(recordedMetricIds),
       metricDirection = Map<String, String>.unmodifiable(metricDirection),
       stopAction = Map<String, String>.unmodifiable(stopAction),
       stopStage = Map<String, String>.unmodifiable(stopStage),
       stopMetric = Map<String, String>.unmodifiable(stopMetric),
       killProvider = Map<String, String>.unmodifiable(killProvider),
       rollbackTarget = Map<String, String>.unmodifiable(rollbackTarget),
       supportOwnerByProvider = Map<String, String>.unmodifiable(
         supportOwnerByProvider,
       ),
       undrilledKillIds = List<String>.unmodifiable(undrilledKillIds),
       carriedOpenItems = List<String>.unmodifiable(carriedOpenItems);

  /// The 117.4 verdict whose exposed subset defines the certified subset.
  final String exposureVerdict;

  /// The 117.5 verdict that determined local exposure for the staged connectors.
  final String exposureMatrixVerdict;

  /// The 117.6 verdict that defines the support path.
  final String supportVerdict;

  /// The 117.8 verdict that defines the rollback drill.
  final String rollbackVerdict;

  /// The providers 117.4 certified.
  final List<String> certifiedSubset;

  /// The connectors 117.5 determined local exposure for.
  final List<String> determinedExposed;

  /// The connectors 117.5 enabled. Empty while the cohort is unverified.
  final List<String> enabledSubset;

  /// The default state 116.50 records for every beta flag.
  final String recordedDefault;

  /// The master connector flag 116.50 records.
  final String masterFlagKey;

  /// The connectors 116.50 stages, as `conn_<provider>` ids.
  final List<String> stagedConnectors;

  /// The health metrics 116.50 records.
  final List<String> recordedMetricIds;

  final Map<String, String> metricDirection;
  final Map<String, String> stopAction;
  final Map<String, String> stopStage;
  final Map<String, String> stopMetric;
  final Map<String, String> killProvider;
  final Map<String, String> rollbackTarget;
  final Map<String, String> supportOwnerByProvider;
  final String charterIncidentOwner;
  final bool drillExecuted;
  final List<String> undrilledKillIds;
  final List<String> carriedOpenItems;
}

class Sprint117RolloutInput {
  const Sprint117RolloutInput({this.stages, this.anchor});

  final List<Sprint117RolloutStageRecord>? stages;
  final Sprint117RolloutAnchor? anchor;
}

class Sprint117RolloutReport {
  Sprint117RolloutReport({
    required this.state,
    required this.verdict,
    required List<String> missingFields,
    required List<String> violations,
    required this.anchor,
    required List<Sprint117RolloutStageRecord> stages,
    required List<String> certifiedSubset,
    required List<String> connectorSubset,
    required List<String> determinedExposed,
    required List<String> enabledSubset,
    required List<String> undeterminedFields,
    required List<String> openItems,
    required List<String> limitations,
    required Map<String, int> fieldCoverage,
  }) : missingFields = List<String>.unmodifiable(missingFields),
       violations = List<String>.unmodifiable(violations),
       stages = List<Sprint117RolloutStageRecord>.unmodifiable(stages),
       certifiedSubset = List<String>.unmodifiable(certifiedSubset),
       connectorSubset = List<String>.unmodifiable(connectorSubset),
       determinedExposed = List<String>.unmodifiable(determinedExposed),
       enabledSubset = List<String>.unmodifiable(enabledSubset),
       undeterminedFields = List<String>.unmodifiable(undeterminedFields),
       openItems = List<String>.unmodifiable(openItems),
       limitations = List<String>.unmodifiable(limitations),
       fieldCoverage = Map<String, int>.unmodifiable(fieldCoverage);

  final Sprint117RolloutState state;
  final String verdict;
  final List<String> missingFields;
  final List<String> violations;
  final Sprint117RolloutAnchor? anchor;
  final List<Sprint117RolloutStageRecord> stages;

  /// The providers 117.4 certified.
  final List<String> certifiedSubset;

  /// The certified providers this rollout actually stages.
  final List<String> connectorSubset;

  /// The connectors 117.5 determined local exposure for.
  final List<String> determinedExposed;

  /// The connectors the rollout may actually run. Empty while consent is
  /// unverified: determined exposure is not enabled exposure.
  final List<String> enabledSubset;

  /// The canonical fields the plan could not determine from evidence.
  final List<String> undeterminedFields;

  final List<String> openItems;
  final List<String> limitations;
  final Map<String, int> fieldCoverage;

  String get externalGates => Sprint117RolloutContract.externalGates;

  int get stageCount => stages.length;

  String get masterFlag => anchor?.masterFlagKey ?? '';

  String get recordedDefault => anchor?.recordedDefault ?? '';

  /// A plan is never a live rollout.
  bool get liveRolloutExecuted => false;

  Map<String, Object?> toJson() => <String, Object?>{
    'canonical_step': Sprint117RolloutContract.canonicalStep,
    'state': state.name,
    'verdict': verdict,
    'missing_fields': List<String>.from(missingFields),
    'violations': List<String>.from(violations),
    'master_flag': masterFlag,
    'recorded_default': recordedDefault,
    'stage_count': stageCount,
    'certified_subset': List<String>.from(certifiedSubset),
    'connector_subset': List<String>.from(connectorSubset),
    'determined_exposed': List<String>.from(determinedExposed),
    'enabled_subset': List<String>.from(enabledSubset),
    'stages': <Map<String, Object?>>[for (final s in stages) s.toJson()],
    'health_criteria': <Map<String, Object?>>[
      for (final metricId in anchor?.recordedMetricIds ?? const <String>[])
        <String, Object?>{
          'metric_id': metricId,
          'direction': anchor?.metricDirection[metricId] ?? '',
        },
    ],
    'stop_conditions': <Map<String, Object?>>[
      for (final stopId
          in (anchor?.stopAction.keys ?? const <String>[]).toList()..sort())
        <String, Object?>{
          'stop_id': stopId,
          'stage_id': anchor?.stopStage[stopId] ?? '',
          'metric_id': anchor?.stopMetric[stopId] ?? '',
          'action': anchor?.stopAction[stopId] ?? '',
        },
    ],
    'kill_switches': <Map<String, Object?>>[
      for (final entry
          in (anchor?.killProvider.entries ?? const []).toList()
            ..sort((a, b) => a.key.compareTo(b.key)))
        <String, Object?>{
          'kill_id': entry.key,
          'provider_id': entry.value,
          'drilled': !(anchor?.undrilledKillIds.contains(entry.key) ?? true),
        },
    ],
    'rollback': <Map<String, Object?>>[
      for (final entry
          in (anchor?.rollbackTarget.entries ?? const []).toList()
            ..sort((a, b) => a.key.compareTo(b.key)))
        <String, Object?>{
          'rollback_id': entry.key,
          'target_id': entry.value,
          'local_project_data_touched': false,
          'verified': false,
        },
    ],
    'support': <Map<String, Object?>>[
      for (final entry
          in (anchor?.supportOwnerByProvider.entries ?? const []).toList()
            ..sort((a, b) => a.key.compareTo(b.key)))
        <String, Object?>{'provider_id': entry.key, 'owner': entry.value},
    ],
    'field_coverage': Map<String, int>.from(fieldCoverage),
    'required_fields': List<String>.from(
      Sprint117RolloutContract.requiredFields,
    ),
    'source_manifests': List<String>.from(
      Sprint117RolloutContract.sourceManifests,
    ),
    'external_gates': externalGates,
    'live_rollout_executed': liveRolloutExecuted,
    'open_items': List<String>.from(openItems),
    'limitations': List<String>.from(limitations),
  };
}

abstract final class Sprint117RolloutContract {
  static const String canonicalStep = '117.44';

  static const String manifestPath =
      'docs/planning/v1.3/sprint_117_staged_ga_rollout_plan.json';

  /// 116.50 supplies flags, stages, health metrics, stop conditions, kill
  /// switches, rollback, and the default.
  static const String rolloutManifestPath =
      'docs/planning/v1.2/sprint_116_staged_beta_rollout_monitoring.json';

  /// 117.4 supplies the certified subset this rollout may expose.
  static const String exposureManifestPath =
      'docs/planning/v1.3/sprint_117_certification_snapshot_lock.json';

  /// 117.5 supplies the connectors with determined local exposure.
  static const String matrixManifestPath =
      'docs/planning/v1.3/sprint_117_beta_exposure_flag_matrix.json';

  /// 117.6 supplies the support path.
  static const String supportManifestPath =
      'docs/planning/v1.3/sprint_117_support_incident_readiness.json';

  /// 117.8 supplies the rollback drill and the kill-switch drill status.
  static const String rollbackManifestPath =
      'docs/planning/v1.3/sprint_117_provider_rollback_drill.json';

  static const String externalGates = 'DEFERRED-EXTERNAL';

  /// The 117.4 verdict the certified subset is only valid under.
  static const String exposureVerdict = 'CERTIFICATION_SNAPSHOT_LOCKED_LOCAL';

  /// The 117.5 verdict the determined exposure is only valid under.
  static const String matrixVerdict = 'BETA_EXPOSURE_MATRIX_DETERMINED_LOCAL';

  /// The 117.6 verdict the support path is only valid under.
  static const String supportVerdict =
      'SUPPORT_INCIDENT_READINESS_DEFINED_LOCAL';

  /// The 117.8 verdict the rollback path is only valid under.
  static const String rollbackVerdict = 'PROVIDER_ROLLBACK_DRILL_DEFINED_LOCAL';

  static const String passVerdict = 'STAGED_GA_ROLLOUT_PLAN_DEFINED_LOCAL';
  static const String blockedVerdict =
      'STAGED_GA_ROLLOUT_PLAN_BLOCKED_NO_LOCAL_EVIDENCE';
  static const String failVerdict = 'STAGED_GA_ROLLOUT_PLAN_INCONSISTENT';

  /// The eight fields canonical step 117.44 names, in canonical order.
  static const List<String> requiredFields = <String>[
    'stages',
    'connector_subset',
    'exposure',
    'health_criteria',
    'stop_conditions',
    'kill_switches',
    'rollback',
    'support',
  ];

  static const List<String> sourceManifests = <String>[
    rolloutManifestPath,
    exposureManifestPath,
    matrixManifestPath,
    supportManifestPath,
    rollbackManifestPath,
  ];

  /// Every beta flag defaults OFF. A stage that ships ON has no rollback left
  /// to return to.
  static const String defaultOff = 'OFF';

  /// The stop-condition action vocabulary 116.50 records. A stop whose action
  /// is outside this set is not a stop, it is a note.
  static const List<String> stopActions = <String>[
    'halt_rollout',
    'rollback_stage',
    'page_oncall',
  ];
}

class Sprint117RolloutLoader {
  const Sprint117RolloutLoader();

  Sprint117RolloutInput load() =>
      Sprint117RolloutInput(stages: _loadStages(), anchor: _loadAnchor());

  Sprint117RolloutAnchor? _loadAnchor() {
    final rollout = _readJsonObject(
      Sprint117RolloutContract.rolloutManifestPath,
    );
    final exposure = _readJsonObject(
      Sprint117RolloutContract.exposureManifestPath,
    );
    final matrix = _readJsonObject(Sprint117RolloutContract.matrixManifestPath);
    final support = _readJsonObject(
      Sprint117RolloutContract.supportManifestPath,
    );
    final rollback = _readJsonObject(
      Sprint117RolloutContract.rollbackManifestPath,
    );
    if (rollout == null ||
        exposure == null ||
        matrix == null ||
        support == null ||
        rollback == null) {
      return null;
    }

    final flags = _mapList(rollout['flags']);
    final stages = _mapList(rollout['stages']);
    final metrics = _mapList(rollout['health_metrics']);
    final stops = _mapList(rollout['stop_conditions']);
    final kills = _mapList(rollout['provider_kill_switches']);
    final rollbacks = _mapList(rollout['rollback']);

    final metricDirection = <String, String>{};
    final recordedMetricIds = <String>[];
    for (final metric in metrics) {
      final id = _text(metric['metric_id']);
      if (id.isEmpty) continue;
      recordedMetricIds.add(id);
      metricDirection[id] = _text(metric['direction']);
    }

    final stopAction = <String, String>{};
    final stopStage = <String, String>{};
    final stopMetric = <String, String>{};
    for (final stop in stops) {
      final id = _text(stop['stop_id']);
      if (id.isEmpty) continue;
      stopAction[id] = _text(stop['action']);
      stopStage[id] = _text(stop['stage_id']);
      stopMetric[id] = _text(stop['metric_id']);
    }

    final killProvider = <String, String>{};
    final undrilled = <String>[];
    for (final kill in kills) {
      final id = _text(kill['kill_id']);
      if (id.isEmpty) continue;
      killProvider[id] = _text(kill['provider_id']);
      if (kill['drill_verified'] != true) undrilled.add(id);
    }

    final rollbackTarget = <String, String>{};
    for (final row in rollbacks) {
      final id = _text(row['rollback_id']);
      if (id.isEmpty) continue;
      rollbackTarget[id] = _text(row['target_id']);
    }

    final supportOwnerByProvider = <String, String>{};
    for (final row in _mapList(support['provider_escalation'])) {
      final provider = _text(row['provider_id']);
      final owner = _text(row['owner']);
      if (provider.isEmpty || owner.isEmpty) continue;
      supportOwnerByProvider[provider] = owner;
    }

    final stagedConnectors = <String>{};
    for (final stage in stages) {
      for (final connector in _stringList(stage['exposed_connectors'])) {
        stagedConnectors.add(connector);
      }
    }

    return Sprint117RolloutAnchor(
      exposureVerdict: _text(exposure['verdict']),
      exposureMatrixVerdict: _text(matrix['verdict']),
      supportVerdict: _text(support['verdict']),
      rollbackVerdict: _text(rollback['verdict']),
      certifiedSubset: _stringList(exposure['exposed_subset']),
      determinedExposed: _stringList(matrix['determined_exposed']),
      enabledSubset: _stringList(matrix['enabled_subset']),
      recordedDefault: _recordedDefault(rollout),
      masterFlagKey: _masterFlagKey(
        flags.map((flag) => _text(flag['flag_key'])).toList(growable: false),
      ),
      stagedConnectors: stagedConnectors.toList(growable: false),
      recordedMetricIds: recordedMetricIds,
      metricDirection: metricDirection,
      stopAction: stopAction,
      stopStage: stopStage,
      stopMetric: stopMetric,
      killProvider: killProvider,
      rollbackTarget: rollbackTarget,
      supportOwnerByProvider: supportOwnerByProvider,
      charterIncidentOwner: _text(support['charter_incident_owner']),
      drillExecuted: rollback['drill_executed'] == true,
      undrilledKillIds: undrilled,
      carriedOpenItems: _stringList(matrix['open_items']),
    );
  }

  /// 116.50 records every beta flag as defaulting OFF. That recorded value is
  /// this plan's default, read rather than assumed.
  static String _recordedDefault(Map<String, dynamic> rollout) {
    final recorded = _text(rollout['beta_feature_flags_default']);
    return recorded.isEmpty ? '' : recorded.toUpperCase();
  }

  /// The master gate is the non-connector beta flag; a plan whose master gate is
  /// missing has no way to turn staged GA exposure off at all.
  static String _masterFlagKey(List<String> flagKeys) {
    for (final key in flagKeys) {
      if (_providerFromConnectorFlagKey(key) == null) return key;
    }
    return '';
  }

  /// `connector.<provider>.enabled` names exactly one provider.
  static String? _providerFromConnectorFlagKey(String key) {
    if (!key.startsWith('connector.')) return null;
    if (!key.endsWith('.enabled')) return null;
    final provider = key.substring(
      'connector.'.length,
      key.length - '.enabled'.length,
    );
    return provider.isEmpty ? null : provider;
  }

  /// One stage per stage row 116.50 records. A stage that names a connector no
  /// source stages yields empty exposed providers, which the gate then reports
  /// as undetermined rather than inventing exposure.
  List<Sprint117RolloutStageRecord>? _loadStages() {
    final anchor = _loadAnchor();
    if (anchor == null) return null;

    final rollout = _readJsonObject(
      Sprint117RolloutContract.rolloutManifestPath,
    );
    if (rollout == null) return null;
    final stages = _mapList(rollout['stages']);

    final rows = <Sprint117RolloutStageRecord>[];
    for (final stage in stages) {
      final stageId = _text(stage['stage_id']);
      final exposedConnectors = _stringList(stage['exposed_connectors']);
      final exposedProviders = <String>[
        for (final connector in exposedConnectors)
          ?_providerFromConnector(connector),
      ];

      final stopIds = <String>[
        for (final entry in anchor.stopStage.entries)
          if (entry.value == stageId) entry.key,
      ];

      // A stage's health criteria are the metrics its own stop conditions
      // watch. Reading them from the stops keeps the criteria tied to the
      // stage rather than to every metric the rollout records.
      final metricIds = <String>{
        for (final stopId in stopIds)
          if ((anchor.stopMetric[stopId] ?? '').isNotEmpty)
            anchor.stopMetric[stopId]!,
      }.toList(growable: false);

      final killIds = <String>[
        for (final entry in anchor.killProvider.entries)
          if (exposedProviders.contains(entry.value)) entry.key,
      ];

      final rollbackId = _rollbackIdFor(anchor, stageId);

      final owners = <String>{
        for (final provider in exposedProviders)
          ?anchor.supportOwnerByProvider[provider],
      };

      rows.add(
        Sprint117RolloutStageRecord(
          stageId: stageId,
          sequence: _intOf(stage['sequence']),
          exposurePercent: _intOf(stage['exposure_percent']),
          exposedProviders: exposedProviders,
          entryCriteria: _stringList(stage['entry_criteria']),
          exitCriteria: _stringList(stage['exit_criteria']),
          healthMetricIds: metricIds,
          stopConditionIds: stopIds,
          killSwitchIds: killIds,
          rollbackId: rollbackId,
          supportOwner: owners.length == 1 ? owners.first : '',
        ),
      );
    }
    return rows;
  }

  static String _rollbackIdFor(Sprint117RolloutAnchor anchor, String stageId) {
    for (final entry in anchor.rollbackTarget.entries) {
      if (entry.value == stageId) return entry.key;
    }
    return '';
  }

  /// `conn_openai` names the provider `openai`.
  static String? _providerFromConnector(String connector) {
    if (!connector.startsWith('conn_')) return null;
    final provider = connector.substring('conn_'.length);
    return provider.isEmpty ? null : provider;
  }

  static int _intOf(Object? value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return -1;
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

  static List<String> _stringList(Object? value) {
    if (value is! List<dynamic>) return const <String>[];
    return <String>[
      for (final item in value)
        if (item is String && item.trim().isNotEmpty) item.trim(),
    ];
  }
}

class Sprint117RolloutGate {
  const Sprint117RolloutGate();

  Sprint117RolloutReport evaluate() =>
      evaluateWith(const Sprint117RolloutLoader().load());

  Sprint117RolloutReport evaluateWith(Sprint117RolloutInput input) {
    final missing = <String>{};
    final violations = <String>[];
    final undeterminedFields = <String>{};

    // --- anchor ------------------------------------------------------------
    final anchor = input.anchor;
    if (anchor == null) {
      missing.add('rollout_anchor');
    } else {
      if (anchor.exposureVerdict != Sprint117RolloutContract.exposureVerdict) {
        violations.add('certified_subset_drift');
        violations.add('certified_subset_verdict:${anchor.exposureVerdict}');
        missing.add('certified_subset');
      }
      if (anchor.exposureMatrixVerdict !=
          Sprint117RolloutContract.matrixVerdict) {
        violations.add('exposure_matrix_drift');
        violations.add(
          'exposure_matrix_verdict:${anchor.exposureMatrixVerdict}',
        );
        missing.add('determined_exposure');
      }
      if (anchor.supportVerdict != Sprint117RolloutContract.supportVerdict) {
        violations.add('support_anchor_drift');
        missing.add('support');
      }
      if (anchor.rollbackVerdict != Sprint117RolloutContract.rollbackVerdict) {
        violations.add('rollback_anchor_drift');
        missing.add('rollback');
      }
      if (anchor.recordedDefault.trim().isEmpty) {
        missing.add('recorded_default');
      }
      if (anchor.masterFlagKey.trim().isEmpty) {
        missing.add('master_flag');
      }
      if (anchor.certifiedSubset.isEmpty) {
        missing.add('certified_subset');
      }
      if (anchor.stagedConnectors.isEmpty) {
        missing.add('staged_connectors');
      }
      if (anchor.recordedMetricIds.isEmpty) {
        missing.add('health_criteria');
      }
    }

    // The certified subset this rollout is allowed to expose: the connectors
    // 117.4 certified that 116.50 actually stages.
    final certified = anchor?.certifiedSubset ?? const <String>[];
    final stagedProviders = <String>{
      for (final connector in anchor?.stagedConnectors ?? const <String>[])
        if (connector.startsWith('conn_')) connector.substring('conn_'.length),
    };
    final connectorSubset = <String>[
      for (final provider in certified)
        if (stagedProviders.contains(provider)) provider,
    ];

    // --- stages ------------------------------------------------------------
    // Stage checks compare each stage against the anchor. Without an anchor
    // there is nothing to compare against, so the rollout is blocked on
    // missing evidence rather than reported inconsistent: a plan with no
    // evidence is not a wrong plan, it is an undetermined one.
    final stages = input.stages;
    final stageIds = <String>{};
    final sequences = <int>{};
    var previousPercent = 0;
    var previousSequence = 0;

    final coverage = <String, int>{
      for (final field in Sprint117RolloutContract.requiredFields) field: 0,
    };

    if (stages == null || stages.isEmpty) {
      missing.add('stages');
    } else if (anchor == null) {
      // Evidence is absent; the loop would fabricate violations.
    } else {
      final ordered = List<Sprint117RolloutStageRecord>.from(stages)
        ..sort((a, b) => a.sequence.compareTo(b.sequence));

      for (final stage in ordered) {
        final stageId = stage.stageId.trim();
        if (stageId.isEmpty) {
          violations.add('stage_id_blank');
          continue;
        }
        if (!stageIds.add(stageId)) {
          violations.add('stage_duplicate:$stageId');
          continue;
        }
        if (!sequences.add(stage.sequence)) {
          violations.add('stage_sequence_duplicate:$stageId');
        }
        if (stage.sequence <= 0) {
          violations.add('stage_sequence_invalid:$stageId');
        }

        // Exposure percent must rise with the stage. A stage that exposes no
        // more than its predecessor has not advanced the rollout.
        final percent = stage.exposurePercent;
        if (percent <= 0 || percent > 100) {
          violations.add('exposure_percent_invalid:$stageId:$percent');
        } else if (stage.sequence > previousSequence &&
            percent < previousPercent) {
          violations.add('exposure_percent_regression:$stageId');
        }
        if (stage.sequence > previousSequence) {
          previousPercent = percent;
          previousSequence = stage.sequence;
        }

        // --- connector subset ---------------------------------------------
        // A stage may only expose a connector 117.4 certified. Exposing an
        // uncertified connector is a rollout wider than the certification.
        final exposed = stage.exposedProviders
            .map((provider) => provider.trim())
            .where((provider) => provider.isNotEmpty)
            .toList(growable: false);
        if (exposed.isEmpty) {
          undeterminedFields.add('connector_subset');
          violations.add('stage_exposes_nothing:$stageId');
        } else {
          var subsetOk = true;
          for (final provider in exposed) {
            if (!certified.contains(provider)) {
              violations.add('uncertified_connector:$stageId:$provider');
              subsetOk = false;
              continue;
            }
            if (!anchor.determinedExposed.contains(provider)) {
              violations.add('exposure_undetermined:$stageId:$provider');
              subsetOk = false;
            }
            if (!stagedProviders.contains(provider)) {
              violations.add('connector_unsourced:$stageId:$provider');
              subsetOk = false;
            }
          }
          if (subsetOk) {
            coverage['connector_subset'] = coverage['connector_subset']! + 1;
          }
        }

        // --- exposure ------------------------------------------------------
        if (percent > 0 && percent <= 100) {
          coverage['exposure'] = coverage['exposure']! + 1;
        }

        // --- health criteria ----------------------------------------------
        if (stage.healthMetricIds.isEmpty) {
          undeterminedFields.add('health_criteria');
        } else {
          var metricsOk = true;
          for (final metricId in stage.healthMetricIds) {
            if (!anchor.recordedMetricIds.contains(metricId)) {
              violations.add('health_metric_unsourced:$stageId:$metricId');
              metricsOk = false;
            }
          }
          if (metricsOk) {
            coverage['health_criteria'] = coverage['health_criteria']! + 1;
          }
        }

        // --- stop conditions ----------------------------------------------
        if (stage.stopConditionIds.isEmpty) {
          undeterminedFields.add('stop_conditions');
        } else {
          var stopsOk = true;
          for (final stopId in stage.stopConditionIds) {
            final action = anchor.stopAction[stopId];
            if (action == null || action.isEmpty) {
              violations.add('stop_unsourced:$stageId:$stopId');
              stopsOk = false;
              continue;
            }
            if (!Sprint117RolloutContract.stopActions.contains(action)) {
              violations.add('stop_action_unknown:$stageId:$stopId:$action');
              stopsOk = false;
            }
            if ((anchor.stopStage[stopId] ?? '') != stageId) {
              violations.add('stop_stage_mismatch:$stageId:$stopId');
              stopsOk = false;
            }
            final metricId = anchor.stopMetric[stopId] ?? '';
            if (!anchor.recordedMetricIds.contains(metricId)) {
              violations.add(
                'stop_metric_unsourced:$stageId:$stopId:$metricId',
              );
              stopsOk = false;
            }
          }
          if (stopsOk) {
            coverage['stop_conditions'] = coverage['stop_conditions']! + 1;
          }
        }

        // --- kill switches -------------------------------------------------
        // Every provider a stage exposes must have a kill switch. A kill switch
        // that covers a provider the subset does not stage is unsourced.
        if (exposed.isEmpty) {
          undeterminedFields.add('kill_switches');
        } else {
          final covered = <String>{
            for (final killId in stage.killSwitchIds)
              ?anchor.killProvider[killId],
          };
          var killsOk = true;
          for (final provider in exposed) {
            if (!covered.contains(provider)) {
              undeterminedFields.add('kill_switches');
              killsOk = false;
            }
          }
          for (final killId in stage.killSwitchIds) {
            final provider = anchor.killProvider[killId] ?? '';
            if (provider.isEmpty) {
              violations.add('kill_switch_unsourced:$stageId:$killId');
              killsOk = false;
            }
          }
          if (killsOk) {
            coverage['kill_switches'] = coverage['kill_switches']! + 1;
          }
        }

        // --- rollback ------------------------------------------------------
        final rollbackId = stage.rollbackId.trim();
        if (rollbackId.isEmpty) {
          undeterminedFields.add('rollback');
        } else if ((anchor.rollbackTarget[rollbackId] ?? '') != stageId) {
          violations.add('rollback_target_mismatch:$stageId:$rollbackId');
        } else {
          coverage['rollback'] = coverage['rollback']! + 1;
        }

        // --- support -------------------------------------------------------
        final owner = stage.supportOwner.trim();
        if (owner.isEmpty) {
          undeterminedFields.add('support');
        } else {
          coverage['support'] = coverage['support']! + 1;
        }

        // --- stages --------------------------------------------------------
        coverage['stages'] = coverage['stages']! + 1;
      }

      // Every certified-and-staged connector must appear in the rollout. A
      // connector the subset carries but no stage exposes is a subset member
      // that silently never rolls out.
      final exposedAnywhere = <String>{
        for (final stage in ordered) ...stage.exposedProviders,
      };
      for (final provider in connectorSubset) {
        if (!exposedAnywhere.contains(provider)) {
          violations.add('subset_connector_unstaged:$provider');
          undeterminedFields.add('connector_subset');
        }
      }
    }

    // --- resolution --------------------------------------------------------
    final state = violations.isNotEmpty
        ? Sprint117RolloutState.fail
        : missing.isNotEmpty
        ? Sprint117RolloutState.blocked
        : Sprint117RolloutState.pass;
    final verdict = switch (state) {
      Sprint117RolloutState.pass => Sprint117RolloutContract.passVerdict,
      Sprint117RolloutState.fail => Sprint117RolloutContract.failVerdict,
      Sprint117RolloutState.blocked => Sprint117RolloutContract.blockedVerdict,
    };

    final openItems = <String>[...anchor?.carriedOpenItems ?? const <String>[]];
    for (final killId in anchor?.undrilledKillIds ?? const <String>[]) {
      openItems.add('kill_switch_not_drilled:$killId');
    }
    if (anchor != null && !anchor.drillExecuted) {
      openItems.add('rollback_drill_not_executed');
    }
    if (anchor != null && anchor.enabledSubset.isEmpty) {
      openItems.add('cohort_not_verified');
    }
    if (undeterminedFields.isNotEmpty) {
      openItems.add('fields_undetermined:${undeterminedFields.length}');
    }
    openItems.add('live_rollout_not_executed');

    final limitations = <String>[
      'This plan determines local staged GA exposure only. It is not live provider availability and claims no quota, cost, credential, handshake, or hosted CI evidence.',
      'Determined exposure is not enabled exposure: no connector is enabled because ${Sprint117RolloutContract.matrixVerdict} records no verified participant cohort.',
      'Kill switches and rollbacks are decided and recorded, but no kill switch has been drilled against a live provider and no rollback has been executed; all external gates remain ${Sprint117RolloutContract.externalGates}.',
      'No flag has been flipped, no stage advanced, and no stop condition has fired; the rollout is a plan, and it says so.',
    ];

    return Sprint117RolloutReport(
      state: state,
      verdict: verdict,
      missingFields: missing.toList(growable: false),
      violations: violations.toList(growable: false),
      anchor: anchor,
      stages: stages ?? const <Sprint117RolloutStageRecord>[],
      certifiedSubset: certified,
      connectorSubset: connectorSubset,
      determinedExposed: anchor?.determinedExposed ?? const <String>[],
      enabledSubset: anchor?.enabledSubset ?? const <String>[],
      undeterminedFields: undeterminedFields.toList(growable: false),
      openItems: openItems.toList(growable: false),
      limitations: limitations,
      fieldCoverage: coverage,
    );
  }
}
