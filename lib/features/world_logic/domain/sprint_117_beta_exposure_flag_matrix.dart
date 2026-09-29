import 'dart:convert';
import 'dart:io';

import '../../../core/feature_flags/feature_flag_registry.dart'
    show kVs12FeatureFlags;

/// Canonical step 117.5 — Beta Exposure & Feature Flag Matrix.
///
/// Objective (external canonical JSON): determine audience, connector flags,
/// dependency flags, defaults, kill switches, and fallback.
///
/// The seven canonical fields are not decoration. A row that names a flag no
/// manifest records, exposes a connector the rollout never staged, or claims a
/// fallback that fails open has not decided exposure — it has asserted it. Each
/// of those is caught here as a rule instead of prose, because the failure mode
/// of an exposure matrix is a beta that is wider than the evidence supports.
///
/// Two rules carry the weight:
///
/// * Exposure is *determined* per row, never assumed from the connector being
///   visible. A row is determined only when it names a flag, connector,
///   audience, OFF default, sourced dependency set, recorded kill switch, and
///   fail-closed fallback. Everything else is reported as undetermined rather
///   than quietly dropped, because an undetermined connector is a beta-exposure
///   decision still owed.
/// * Being *determined* is not the same as being *enabled*. Enabling requires a
///   verified participant consent cohort behind it. 117.3 records no verified
///   cohort, so this matrix determines two connectors and enables none. A matrix
///   that reported exposure here would be claiming a cohort that does not exist.
///
/// The shipped [FeatureFlagRegistry] is a real evidence source, and it also
/// carries the honest limit of this step: the registry knows only the thirteen
/// v1.2 wave-1 flags and rejects everything else, so the beta connector flags
/// 116 records are not yet resolvable through it. That gap is reported as a
/// limitation and an open item instead of being assumed away.
enum Sprint117ExposureState { pass, fail, blocked }

/// One determined beta exposure decision for one connector.
class Sprint117ExposureFlagRecord {
  Sprint117ExposureFlagRecord({
    required this.providerId,
    required this.connectorId,
    required this.flagKey,
    required this.flagId,
    required List<String> audience,
    required this.defaultState,
    required List<String> dependencies,
    required this.killSwitchId,
    required this.fallback,
  }) : audience = List<String>.unmodifiable(audience),
       dependencies = List<String>.unmodifiable(dependencies);

  final String providerId;
  final String connectorId;

  /// The connector flag key, 116-style (`connector.<provider>.enabled`).
  final String flagKey;

  /// The rollout flag identifier this row resolves to.
  final String flagId;

  /// The rollout stages this connector is exposed to.
  final List<String> audience;

  /// Always `OFF`: a flag that ships ON has no fallback left to return to.
  final String defaultState;

  /// Cross-flag dependencies. 113.13 records none for the shipped surface, so
  /// an empty list is the sourced answer and a named flag is unsourced.
  final List<String> dependencies;

  final String killSwitchId;

  /// The fail-closed behaviour when the flag is unavailable.
  final String fallback;

  Map<String, Object?> toJson() => <String, Object?>{
    'provider_id': providerId,
    'connector_id': connectorId,
    'flag': flagKey,
    'flag_id': flagId,
    'audience': List<String>.from(audience),
    'default': defaultState,
    'dependencies': List<String>.from(dependencies),
    'kill_switch': killSwitchId,
    'fallback': fallback,
  };
}

/// The evidence this matrix is allowed to decide from.
class Sprint117ExposureAnchor {
  Sprint117ExposureAnchor({
    required this.exposureVerdict,
    required this.cohortVerdict,
    required List<String> surfaceProviderIds,
    required List<String> consentedProviderIds,
    required List<String> committedWithoutParticipant,
    required this.rolloutDefault,
    required this.masterFlagKey,
    required Map<String, String> providerFlagKey,
    required Map<String, String> providerConnector,
    required Map<String, List<String>> providerStages,
    required Map<String, String> providerKill,
    required Map<String, String> killFlagRef,
    required List<String> undrilledKillIds,
    required this.crossDependencies,
    required List<String> carriedOpenItems,
  }) : surfaceProviderIds = List<String>.unmodifiable(surfaceProviderIds),
       consentedProviderIds = List<String>.unmodifiable(consentedProviderIds),
       committedWithoutParticipant = List<String>.unmodifiable(
         committedWithoutParticipant,
       ),
       providerFlagKey = Map<String, String>.unmodifiable(providerFlagKey),
       providerConnector = Map<String, String>.unmodifiable(providerConnector),
       providerStages = Map<String, List<String>>.unmodifiable(
         providerStages.map(
           (key, value) => MapEntry(key, List<String>.unmodifiable(value)),
         ),
       ),
       providerKill = Map<String, String>.unmodifiable(providerKill),
       killFlagRef = Map<String, String>.unmodifiable(killFlagRef),
       undrilledKillIds = List<String>.unmodifiable(undrilledKillIds),
       carriedOpenItems = List<String>.unmodifiable(carriedOpenItems);

  /// The 117.4 verdict whose exposed subset defines this surface.
  final String exposureVerdict;

  /// The 117.3 verdict. An unverified cohort enables nobody.
  final String cohortVerdict;

  /// The 117.4 exposed subset this matrix inherits.
  final List<String> surfaceProviderIds;

  /// Providers with a verified participant consent behind them.
  final List<String> consentedProviderIds;

  /// Providers 117.3 recorded a consent for with no participant behind it.
  final List<String> committedWithoutParticipant;

  /// The default state 116.50 records for every beta flag.
  final String rolloutDefault;

  /// The master connector flag 116.50 records.
  final String masterFlagKey;

  final Map<String, String> providerFlagKey;
  final Map<String, String> providerConnector;
  final Map<String, List<String>> providerStages;
  final Map<String, String> providerKill;
  final Map<String, String> killFlagRef;

  /// Kill switches 116.50 records without a verified drill.
  final List<String> undrilledKillIds;

  /// The cross-dependency answer 113.13 records for the shipped surface.
  final String crossDependencies;

  final List<String> carriedOpenItems;
}

class Sprint117ExposureInput {
  const Sprint117ExposureInput({this.rows, this.anchor});

  final List<Sprint117ExposureFlagRecord>? rows;
  final Sprint117ExposureAnchor? anchor;
}

class Sprint117ExposureReport {
  Sprint117ExposureReport({
    required this.state,
    required this.verdict,
    required List<String> missingFields,
    required List<String> violations,
    required this.anchor,
    required List<Sprint117ExposureFlagRecord> rows,
    required List<String> determinedExposed,
    required List<String> undetermined,
    required List<String> enabledSubset,
    required this.consentGateVerified,
    required List<String> openItems,
    required List<String> limitations,
    required Map<String, int> fieldCoverage,
  }) : missingFields = List<String>.unmodifiable(missingFields),
       violations = List<String>.unmodifiable(violations),
       rows = List<Sprint117ExposureFlagRecord>.unmodifiable(rows),
       determinedExposed = List<String>.unmodifiable(determinedExposed),
       undetermined = List<String>.unmodifiable(undetermined),
       enabledSubset = List<String>.unmodifiable(enabledSubset),
       openItems = List<String>.unmodifiable(openItems),
       limitations = List<String>.unmodifiable(limitations),
       fieldCoverage = Map<String, int>.unmodifiable(fieldCoverage);

  final Sprint117ExposureState state;
  final String verdict;
  final List<String> missingFields;
  final List<String> violations;
  final Sprint117ExposureAnchor? anchor;
  final List<Sprint117ExposureFlagRecord> rows;

  /// Connectors whose exposure is fully determined by recorded evidence.
  final List<String> determinedExposed;

  /// Connectors that carry a beta exposure decision nobody has made yet.
  final List<String> undetermined;

  /// Determined connectors that may actually run, consent permitting.
  final List<String> enabledSubset;

  final bool consentGateVerified;
  final List<String> openItems;
  final List<String> limitations;
  final Map<String, int> fieldCoverage;

  String get externalGates => Sprint117ExposureContract.externalGates;

  int get rowCount => rows.length;

  String get masterFlag => anchor?.masterFlagKey ?? '';

  String get recordedDefault => anchor?.rolloutDefault ?? '';

  /// A matrix of locally determined exposure is never a live beta run.
  bool get liveBetaExecuted => false;

  List<String> get consentedProviderIds => List<String>.unmodifiable(
    anchor?.consentedProviderIds ?? const <String>[],
  );

  Map<String, Object?> toJson() => <String, Object?>{
    'canonical_step': Sprint117ExposureContract.canonicalStep,
    'state': state.name,
    'verdict': verdict,
    'missing_fields': List<String>.from(missingFields),
    'violations': List<String>.from(violations),
    'master_flag': masterFlag,
    'recorded_default': recordedDefault,
    'row_count': rowCount,
    'determined_exposed': List<String>.from(determinedExposed),
    'undetermined': List<String>.from(undetermined),
    'enabled_subset': List<String>.from(enabledSubset),
    'consent_gate_verified': consentGateVerified,
    'consented_provider_ids': List<String>.from(consentedProviderIds),
    'matrix': <Map<String, Object?>>[for (final row in rows) row.toJson()],
    'field_coverage': Map<String, int>.from(fieldCoverage),
    'required_fields': List<String>.from(
      Sprint117ExposureContract.requiredFields,
    ),
    'source_manifests': List<String>.from(
      Sprint117ExposureContract.sourceManifests,
    ),
    'external_gates': externalGates,
    'live_beta_executed': liveBetaExecuted,
    'open_items': List<String>.from(openItems),
    'limitations': List<String>.from(limitations),
  };
}

abstract final class Sprint117ExposureContract {
  static const String canonicalStep = '117.5';

  static const String manifestPath =
      'docs/planning/v1.3/sprint_117_beta_exposure_flag_matrix.json';

  /// 117.4 supplies the exposed subset this matrix decides exposure for.
  static const String exposureManifestPath =
      'docs/planning/v1.3/sprint_117_certification_snapshot_lock.json';

  /// 117.3 supplies the consent gate and the participant ground truth.
  static const String cohortManifestPath =
      'docs/planning/v1.3/sprint_117_beta_cohort_consent_verification.json';

  /// 116.50 supplies flags, stages, connectors, kill switches, and the default.
  static const String rolloutManifestPath =
      'docs/planning/v1.2/sprint_116_staged_beta_rollout_monitoring.json';

  /// 113.13 supplies the cross-flag dependency answer.
  static const String dependencyManifestPath =
      'docs/planning/v1.2/sprint_113_feature_flag_dependency_validation.json';

  static const String externalGates = 'DEFERRED-EXTERNAL';

  /// The 117.4 verdict this matrix inherits its surface from.
  static const String exposureVerdict = 'CERTIFICATION_SNAPSHOT_LOCKED_LOCAL';

  /// The 117.3 verdict that would permit enabling anybody.
  static const String cohortVerifiedVerdict = 'COHORT_CONSENT_VERIFIED_LOCAL';

  /// The 117.3 verdict as it stands: no verified participant exists.
  static const String cohortBlockedVerdict =
      'COHORT_CONSENT_VERIFICATION_FAILED';

  static const String passVerdict = 'BETA_EXPOSURE_MATRIX_DETERMINED_LOCAL';
  static const String blockedVerdict =
      'BETA_EXPOSURE_MATRIX_BLOCKED_NO_LOCAL_EVIDENCE';
  static const String failVerdict = 'BETA_EXPOSURE_MATRIX_INCONSISTENT';

  /// The seven fields canonical step 117.5 names, in canonical order.
  static const List<String> requiredFields = <String>[
    'flag',
    'connector',
    'audience',
    'default',
    'dependencies',
    'kill_switch',
    'fallback',
  ];

  static const List<String> sourceManifests = <String>[
    exposureManifestPath,
    cohortManifestPath,
    rolloutManifestPath,
    dependencyManifestPath,
  ];

  /// Every beta flag defaults OFF. 116.50 records the same default, and a flag
  /// that ships ON has no fallback left to fall back to.
  static const String defaultOff = 'OFF';

  /// The only fail-closed fallback this matrix accepts. A rollout flag that
  /// stops resolving must disable its connector, never expose it.
  static const String failClosedFallback = 'fail_closed_disabled';

  /// The fail-closed vocabulary. Anything else has not been decided.
  static const List<String> failClosedFallbacks = <String>[failClosedFallback];
}

class Sprint117ExposureLoader {
  const Sprint117ExposureLoader();

  Sprint117ExposureInput load() =>
      Sprint117ExposureInput(rows: _loadRows(), anchor: _loadAnchor());

  Sprint117ExposureAnchor? _loadAnchor() {
    final exposure = _readJsonObject(
      Sprint117ExposureContract.exposureManifestPath,
    );
    final cohort = _readJsonObject(
      Sprint117ExposureContract.cohortManifestPath,
    );
    final rollout = _readJsonObject(
      Sprint117ExposureContract.rolloutManifestPath,
    );
    final dependency = _readJsonObject(
      Sprint117ExposureContract.dependencyManifestPath,
    );
    if (exposure == null ||
        cohort == null ||
        rollout == null ||
        dependency == null) {
      return null;
    }

    final flags = _mapList(rollout['flags']);
    final stages = _mapList(rollout['stages']);
    final kills = _mapList(rollout['provider_kill_switches']);

    // A connector flag is a `connector.<provider>.enabled` flag, distinct from
    // the master `beta.connectors.enabled` gate. Reading the two apart is what
    // stops the master gate from being counted as per-connector exposure.
    final connectorFlagByProvider = <String, String>{};
    final flagIdByKey = <String, String>{};
    for (final flag in flags) {
      final key = _text(flag['flag_key']);
      final id = _text(flag['flag_id']);
      if (key.isEmpty || id.isEmpty) continue;
      flagIdByKey[key] = id;
      final provider = _providerFromConnectorFlagKey(key);
      if (provider != null) {
        connectorFlagByProvider[provider] = key;
      }
    }

    // The stages a connector is exposed to come from the stage rows, keyed by
    // the connectors they expose — not from the flag's linked stages, so the
    // audience a row declares is the audience the rollout actually stages.
    final stagesByConnector = <String, List<String>>{};
    for (final stage in stages) {
      final stageId = _text(stage['stage_id']);
      if (stageId.isEmpty) continue;
      for (final connector in _stringList(stage['exposed_connectors'])) {
        stagesByConnector.putIfAbsent(connector, () => <String>[]).add(stageId);
      }
    }

    final killByProvider = <String, String>{};
    final killFlagRef = <String, String>{};
    final undrilled = <String>[];
    for (final kill in kills) {
      final killId = _text(kill['kill_id']);
      if (killId.isEmpty) continue;
      final provider = _text(kill['provider_id']);
      final connector = _text(kill['connector_id']);
      if (provider.isNotEmpty) killByProvider[provider] = killId;
      if (connector.isNotEmpty) killByProvider[connector] = killId;
      killFlagRef[killId] = _text(kill['flag_ref']);
      if (kill['drill_verified'] != true) undrilled.add(killId);
    }

    final connectorByProvider = <String, String>{};
    for (final entry in connectorFlagByProvider.keys) {
      // connector ids are `conn_<provider>`; recover the mapping from the kill
      // switch rows, which record both, and fall back to the recorded name.
      final connector = kills
          .map((kill) => _text(kill['connector_id']))
          .firstWhere(
            (id) => id.isNotEmpty && id == 'conn_$entry',
            orElse: () => '',
          );
      if (connector.isNotEmpty) connectorByProvider[entry] = connector;
    }
    for (final kill in kills) {
      final provider = _text(kill['provider_id']);
      final connector = _text(kill['connector_id']);
      if (provider.isNotEmpty && connector.isNotEmpty) {
        connectorByProvider[provider] = connector;
      }
    }

    final dependencyMatrix = dependency['dependency_matrix'];
    final crossDependencies = dependencyMatrix is Map<String, dynamic>
        ? _text(dependencyMatrix['cross_dependencies'])
        : '';

    return Sprint117ExposureAnchor(
      exposureVerdict: _text(exposure['verdict']),
      cohortVerdict: _text(cohort['verdict']),
      surfaceProviderIds: _stringList(exposure['exposed_subset']),
      consentedProviderIds: _verifiedConsentProviders(cohort),
      committedWithoutParticipant: _committedWithoutParticipant(cohort),
      rolloutDefault: _recordedDefault(rollout),
      masterFlagKey: _masterFlagKey(flagIdByKey.keys.toList(growable: false)),
      providerFlagKey: connectorFlagByProvider,
      providerConnector: connectorByProvider,
      providerStages: stagesByConnector,
      providerKill: killByProvider,
      killFlagRef: killFlagRef,
      undrilledKillIds: undrilled,
      crossDependencies: crossDependencies,
      carriedOpenItems: _stringList(exposure['open_items']),
    );
  }

  /// 116.50 records every beta flag as defaulting OFF. That recorded value is
  /// this matrix's default, read rather than assumed.
  static String _recordedDefault(Map<String, dynamic> rollout) {
    final recorded = _text(rollout['beta_feature_flags_default']);
    return recorded.isEmpty ? '' : recorded.toUpperCase();
  }

  /// The master gate is the non-connector beta flag; a matrix whose master gate
  /// is missing has no way to turn beta exposure off at all.
  static String _masterFlagKey(List<String> flagKeys) {
    for (final key in flagKeys) {
      if (_providerFromConnectorFlagKey(key) == null) return key;
    }
    return '';
  }

  /// A consent row is a real consent only when a participant stands behind it.
  /// 117.3 records opt-ins with an empty participant id; those are carries, not
  /// permissions, and no provider is treated as consented because of them.
  static List<String> _verifiedConsentProviders(Map<String, dynamic> cohort) {
    if (_text(cohort['verdict']) !=
        Sprint117ExposureContract.cohortVerifiedVerdict) {
      return const <String>[];
    }
    final result = <String>{};
    for (final row in _mapList(cohort['provider_coverage'])) {
      final provider = _text(row['provider_id']);
      final consentRef = _text(row['consent_ref']);
      if (provider.isEmpty || consentRef.isEmpty) continue;
      final consent = _findConsent(cohort, consentRef);
      if (consent == null) continue;
      if (_text(consent['participant_id']).isEmpty) continue;
      if (consent['explicit_opt_in'] != true) continue;
      result.add(provider);
    }
    return result.toList(growable: false);
  }

  /// Provider coverage whose consent exists but names no participant. These are
  /// reported as an open item because they look verified in prose and are not.
  static List<String> _committedWithoutParticipant(
    Map<String, dynamic> cohort,
  ) {
    final result = <String>[];
    for (final row in _mapList(cohort['provider_coverage'])) {
      final provider = _text(row['provider_id']);
      final consentRef = _text(row['consent_ref']);
      if (provider.isEmpty || consentRef.isEmpty) continue;
      final consent = _findConsent(cohort, consentRef);
      if (consent == null) continue;
      if (_text(consent['participant_id']).isNotEmpty) continue;
      if (consent['explicit_opt_in'] != true) continue;
      result.add(provider);
    }
    return result;
  }

  static Map<String, dynamic>? _findConsent(
    Map<String, dynamic> cohort,
    String consentId,
  ) {
    for (final row in _mapList(cohort['consent'])) {
      if (_text(row['consent_id']) == consentId) return row;
    }
    return null;
  }

  /// `connector.<provider>.enabled` names exactly one provider. The master gate
  /// `beta.connectors.enabled` has no provider and is not a connector flag.
  static String? _providerFromConnectorFlagKey(String key) {
    if (!key.startsWith('connector.')) return null;
    if (!key.endsWith('.enabled')) return null;
    final provider = key.substring(
      'connector.'.length,
      key.length - '.enabled'.length,
    );
    return provider.isEmpty ? null : provider;
  }

  /// One row per connector 117.4 exposed. A connector the rollout never staged
  /// yields a row whose gating fields are empty, which the gate then reports as
  /// undetermined rather than inventing a flag, audience, or kill switch.
  List<Sprint117ExposureFlagRecord>? _loadRows() {
    final anchor = _loadAnchor();
    if (anchor == null) return null;

    final rows = <Sprint117ExposureFlagRecord>[];
    for (final providerId in anchor.surfaceProviderIds) {
      final flagKey = anchor.providerFlagKey[providerId] ?? '';
      final connectorId = anchor.providerConnector[providerId] ?? '';
      final stages = anchor.providerStages[connectorId] ?? const <String>[];
      rows.add(
        Sprint117ExposureFlagRecord(
          providerId: providerId,
          connectorId: connectorId,
          flagKey: flagKey,
          flagId: flagKey.isEmpty ? '' : _flagIdFor(anchor, flagKey),
          audience: List<String>.from(stages),
          defaultState: anchor.rolloutDefault,
          dependencies: _recordedDependencies(anchor),
          killSwitchId: anchor.providerKill[providerId] ?? '',
          fallback: Sprint117ExposureContract.failClosedFallback,
        ),
      );
    }
    return rows;
  }

  /// 113.13 records `cross_dependencies: none` for the shipped surface, so the
  /// sourced dependency set is empty. A surface that recorded real
  /// cross-dependencies would carry them here instead of being flattened.
  static List<String> _recordedDependencies(Sprint117ExposureAnchor anchor) {
    final recorded = anchor.crossDependencies.trim().toLowerCase();
    if (recorded.isEmpty || recorded == 'none') return const <String>[];
    return <String>[recorded];
  }

  static String _flagIdFor(Sprint117ExposureAnchor anchor, String flagKey) {
    for (final entry in anchor.providerKill.entries) {
      if (anchor.providerFlagKey[entry.key] != flagKey) continue;
      final ref = anchor.killFlagRef[entry.value];
      if (ref != null && ref.isNotEmpty) return ref;
    }
    return '';
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

class Sprint117ExposureGate {
  const Sprint117ExposureGate();

  Sprint117ExposureReport evaluate() =>
      evaluateWith(const Sprint117ExposureLoader().load());

  Sprint117ExposureReport evaluateWith(Sprint117ExposureInput input) {
    final missing = <String>{};
    final violations = <String>[];

    // --- anchor ------------------------------------------------------------
    final anchor = input.anchor;
    if (anchor == null) {
      missing.add('exposure_anchor');
    } else {
      if (anchor.exposureVerdict != Sprint117ExposureContract.exposureVerdict) {
        // A 117.4 verdict that is not the locked one means the surface this
        // matrix inherited is not one the lock stands behind. That is a
        // contradiction to report, not a quiet re-derivation.
        violations.add('exposure_anchor_drift');
        violations.add('exposure_anchor_verdict:${anchor.exposureVerdict}');
        missing.add('exposure_anchor');
      }
      if (anchor.cohortVerdict.trim().isEmpty) {
        missing.add('cohort_anchor');
      }
      if (anchor.rolloutDefault.trim().isEmpty) {
        missing.add('recorded_default');
      }
      if (anchor.masterFlagKey.trim().isEmpty) {
        missing.add('master_flag');
      }
      if (anchor.surfaceProviderIds.isEmpty) {
        missing.add('exposed_surface');
      }
      if (anchor.crossDependencies.trim().isEmpty) {
        missing.add('dependency_answer');
      }
    }

    final consentGateVerified =
        anchor?.cohortVerdict.trim() ==
        Sprint117ExposureContract.cohortVerifiedVerdict;

    // --- rows --------------------------------------------------------------
    final rows = input.rows;
    final rowIds = <String>{};
    final flagKeys = <String>{};
    final determined = <String>[];
    final undetermined = <String>[];

    if (rows == null || rows.isEmpty) {
      missing.add('exposure_rows');
    } else {
      for (final row in rows) {
        final providerId = row.providerId.trim();
        if (providerId.isEmpty) {
          violations.add('provider_id_blank');
          continue;
        }
        if (!rowIds.add(providerId)) {
          violations.add('provider_duplicate:$providerId');
          continue;
        }

        final decision = _rowDecision(
          row: row,
          providerId: providerId,
          anchor: anchor,
          violations: violations,
        );
        var coherent = decision.coherent;

        // A flag key is the identity of the decision. Two connectors sharing
        // one key is not two decisions, it is one decision counted twice.
        final flagKey = row.flagKey.trim();
        if (flagKey.isNotEmpty && !flagKeys.add(flagKey)) {
          violations.add('flag_duplicate:$flagKey');
          coherent = false;
        }

        // A row may only decide exposure for a connector 117.4 exposed. A
        // blocked or unknown provider reaching the matrix is a leak, and it is
        // checked against the recorded surface rather than the row's own claim.
        if (anchor != null &&
            anchor.surfaceProviderIds.isNotEmpty &&
            !anchor.surfaceProviderIds.contains(providerId)) {
          violations.add('provider_unlisted:$providerId');
          coherent = false;
        }

        // Being decided and coherent means the exposure is *determined*. It
        // does not mean it is *enabled*: a cohort nobody has verified cannot
        // put a connector in front of a user, and a partially consenting cohort
        // enables only the connectors it actually covers. A determined row
        // outside the consented set is a smaller beta, not a contradiction.
        if (decision.decided && coherent) {
          determined.add(providerId);
        } else {
          undetermined.add(providerId);
        }
      }

      // Surface coherence: every connector 117.4 exposed must be accounted for
      // exactly once. A dropped connector is an exposure decision that vanished
      // rather than one that was made.
      if (anchor != null && anchor.surfaceProviderIds.isNotEmpty) {
        for (final providerId in anchor.surfaceProviderIds) {
          if (!rowIds.contains(providerId)) {
            violations.add('connector_unmapped:$providerId');
            undetermined.add(providerId);
          }
        }
      }
    }

    // --- resolution --------------------------------------------------------
    final state = violations.isNotEmpty
        ? Sprint117ExposureState.fail
        : missing.isNotEmpty
        ? Sprint117ExposureState.blocked
        : Sprint117ExposureState.pass;
    final verdict = switch (state) {
      Sprint117ExposureState.pass => Sprint117ExposureContract.passVerdict,
      Sprint117ExposureState.fail => Sprint117ExposureContract.failVerdict,
      Sprint117ExposureState.blocked =>
        Sprint117ExposureContract.blockedVerdict,
    };

    final openItems = <String>[...anchor?.carriedOpenItems ?? const <String>[]];
    for (final killId in anchor?.undrilledKillIds ?? const <String>[]) {
      openItems.add('kill_switch_not_drilled:$killId');
    }
    if (anchor != null &&
        !consentGateVerified &&
        anchor.cohortVerdict.trim().isNotEmpty) {
      openItems.add('cohort_not_verified');
    }
    for (final providerId
        in anchor?.committedWithoutParticipant ?? const <String>[]) {
      openItems.add('consent_without_participant:$providerId');
    }
    if (undetermined.isNotEmpty) {
      openItems.add('exposure_undetermined:${undetermined.length}');
    }
    // The registry gap is a real, reproducible limitation of the shipped
    // surface, not a hypothetical: the beta connector flags are not among the
    // flags it can resolve.
    if (!_shippedRegistryKnowsBetaFlags()) {
      openItems.add('beta_connector_flags_not_in_shipped_registry');
    }

    final enabled = consentGateVerified
        ? <String>[
            for (final providerId in determined)
              if ((anchor?.consentedProviderIds ?? const <String>[]).contains(
                providerId,
              ))
                providerId,
          ]
        : const <String>[];

    final limitations = <String>[
      'This matrix decides local beta exposure only. It is not live provider availability and claims no quota, cost, credential, handshake, or hosted CI evidence.',
      'Determined exposure is not enabled exposure: no connector is enabled because ${Sprint117ExposureContract.cohortBlockedVerdict} records no verified participant cohort.',
      'The shipped FeatureFlagRegistry resolves only the ${kVs12FeatureFlags.length} v1.2 wave-1 flags and rejects any other name, so the connector flags recorded here are not yet resolvable through the shipped registry.',
      'Fallbacks and kill switches are decided and recorded, but no kill switch has been drilled against a live provider; all external gates remain ${Sprint117ExposureContract.externalGates}.',
    ];

    final fieldCoverage = <String, int>{
      for (final field in Sprint117ExposureContract.requiredFields)
        field: (rows ?? const <Sprint117ExposureFlagRecord>[])
            .where(
              (row) => switch (field) {
                'flag' => row.flagKey.trim().isNotEmpty,
                'connector' => row.connectorId.trim().isNotEmpty,
                'audience' =>
                  row.audience
                      .where((entry) => entry.trim().isNotEmpty)
                      .isNotEmpty,
                'default' => row.defaultState.trim().isNotEmpty,
                'dependencies' =>
                  row.dependencies
                      .where((entry) => entry.trim().isNotEmpty)
                      .isNotEmpty,
                'kill_switch' => row.killSwitchId.trim().isNotEmpty,
                'fallback' => row.fallback.trim().isNotEmpty,
                _ => false,
              },
            )
            .length,
    };

    return Sprint117ExposureReport(
      state: state,
      verdict: verdict,
      missingFields: missing.toList(growable: false),
      violations: violations.toList(growable: false),
      anchor: anchor,
      rows: rows ?? const <Sprint117ExposureFlagRecord>[],
      determinedExposed: determined.toList(growable: false),
      undetermined: undetermined.toList(growable: false),
      enabledSubset: enabled.toList(growable: false),
      consentGateVerified: consentGateVerified,
      openItems: openItems.toList(growable: false),
      limitations: limitations,
      fieldCoverage: fieldCoverage,
    );
  }

  /// Whether one row's exposure is decided by recorded evidence.
  ///
  /// [decided] is false when a field the row needs has no recorded source at
  /// all: nothing has been decided for that connector yet. That is reported as
  /// undetermined rather than as a violation, because "no decision" and "a
  /// decision that contradicts the evidence" are different faults and a matrix
  /// must not disguise the first as the second.
  ///
  /// [coherent] is false when a field is present and contradicts what the
  /// sources record, or when a row denies evidence that exists.
  static ({bool decided, bool coherent}) _rowDecision({
    required Sprint117ExposureFlagRecord row,
    required String providerId,
    required Sprint117ExposureAnchor? anchor,
    required List<String> violations,
  }) {
    var decided = true;
    var coherent = true;

    // --- flag -------------------------------------------------------------
    // A connector flag names exactly one provider. A flag the rollout does not
    // record cannot be flipped, so it cannot gate anything.
    final flagKey = row.flagKey.trim();
    final recordedFlag = anchor?.providerFlagKey[providerId] ?? '';
    if (recordedFlag.isEmpty) {
      if (flagKey.isNotEmpty) {
        violations.add('flag_unsourced:$providerId');
        coherent = false;
      } else {
        decided = false;
      }
    } else if (flagKey.isEmpty) {
      // The source records a flag for this connector and the row denies it.
      violations.add('flag_blank:$providerId');
      coherent = false;
    } else if (flagKey != recordedFlag) {
      violations.add('flag_drift:$providerId:$flagKey:$recordedFlag');
      coherent = false;
    }
    final flagId = row.flagId.trim();

    // --- connector --------------------------------------------------------
    final connectorId = row.connectorId.trim();
    final recordedConnector = anchor?.providerConnector[providerId] ?? '';
    if (recordedConnector.isEmpty) {
      if (connectorId.isNotEmpty) {
        violations.add('connector_unsourced:$providerId:$connectorId');
        coherent = false;
      } else {
        decided = false;
      }
    } else if (connectorId.isEmpty) {
      violations.add('connector_blank:$providerId');
      coherent = false;
    } else if (connectorId != recordedConnector) {
      violations.add(
        'connector_drift:$providerId:$connectorId:$recordedConnector',
      );
      coherent = false;
    }

    // --- audience ---------------------------------------------------------
    final audience = row.audience
        .map((entry) => entry.trim())
        .where((entry) => entry.isNotEmpty)
        .toList(growable: false);
    final recordedStages =
        anchor?.providerStages[recordedConnector.isEmpty
            ? ''
            : recordedConnector] ??
        const <String>[];
    if (recordedStages.isEmpty) {
      if (audience.isNotEmpty) {
        for (final stage in audience) {
          violations.add('audience_unsourced:$providerId:$stage');
        }
        coherent = false;
      } else {
        decided = false;
      }
    } else if (audience.isEmpty) {
      violations.add('audience_blank:$providerId');
      coherent = false;
    } else {
      for (final stage in audience) {
        if (!recordedStages.contains(stage)) {
          violations.add('audience_unknown:$providerId:$stage');
          coherent = false;
        }
      }
      // A narrower or wider audience than the rollout staged is a drift: the
      // matrix would quietly move the exposure it claims to only record.
      if (!_sameSet(audience, recordedStages)) {
        violations.add('audience_drift:$providerId');
        coherent = false;
      }
    }

    // --- default ----------------------------------------------------------
    // Every beta flag defaults OFF. ON means there is nothing left to fall back
    // to, which is the entire point of a flag.
    final defaultState = row.defaultState.trim().toUpperCase();
    final recordedDefault = (anchor?.rolloutDefault ?? '').trim().toUpperCase();
    if (defaultState.isEmpty) {
      violations.add('default_blank:$providerId');
      coherent = false;
    } else if (defaultState != Sprint117ExposureContract.defaultOff) {
      if (defaultState == 'ON') {
        violations.add('default_on:$providerId');
      } else {
        violations.add('default_unknown:$providerId:$defaultState');
      }
      coherent = false;
    }
    if (recordedDefault.isNotEmpty &&
        defaultState.isNotEmpty &&
        defaultState != recordedDefault) {
      violations.add(
        'default_drift:$providerId:$defaultState:$recordedDefault',
      );
      coherent = false;
    }

    // --- dependencies -----------------------------------------------------
    // 113.13 records the cross-flag dependency answer for the shipped surface.
    // When it records `none`, any dependency a row names is unsourced: a matrix
    // cannot invent a coupling that the dependency validation never found.
    final dependencies = row.dependencies
        .map((entry) => entry.trim())
        .where((entry) => entry.isNotEmpty)
        .toList(growable: false);
    final recordedCross = (anchor?.crossDependencies ?? '')
        .trim()
        .toLowerCase();
    if (recordedCross.isEmpty || recordedCross == 'none') {
      for (final dependency in dependencies) {
        violations.add('dependency_unsourced:$providerId:$dependency');
        coherent = false;
      }
    } else if (!_sameSet(dependencies, <String>[recordedCross])) {
      violations.add('dependency_drift:$providerId');
      coherent = false;
    }

    // --- kill switch ------------------------------------------------------
    final killSwitchId = row.killSwitchId.trim();
    final recordedKill = anchor?.providerKill[providerId] ?? '';
    if (recordedKill.isEmpty) {
      if (killSwitchId.isNotEmpty) {
        violations.add('kill_switch_unsourced:$providerId:$killSwitchId');
        coherent = false;
      } else {
        decided = false;
      }
    } else if (killSwitchId.isEmpty) {
      violations.add('kill_switch_blank:$providerId');
      coherent = false;
    } else if (killSwitchId != recordedKill) {
      final known = anchor?.killFlagRef.containsKey(killSwitchId) ?? false;
      violations.add(
        known
            ? 'kill_switch_drift:$providerId:$killSwitchId:$recordedKill'
            : 'kill_switch_unsourced:$providerId:$killSwitchId',
      );
      coherent = false;
    }
    // A kill switch pointing at another provider's flag would disable the
    // wrong connector in exactly the incident it was built for.
    if (flagId.isEmpty && recordedFlag.isNotEmpty) {
      violations.add('flag_id_blank:$providerId');
      coherent = false;
    } else if (flagId.isNotEmpty) {
      final recordedRef = anchor?.killFlagRef[recordedKill] ?? '';
      if (recordedRef.isNotEmpty && flagId != recordedRef) {
        violations.add('kill_flag_mismatch:$providerId:$flagId:$recordedRef');
        coherent = false;
      }
    }

    // --- fallback ---------------------------------------------------------
    // A fallback that fails open turns a disabled connector into a surprising
    // one, so only the fail-closed vocabulary counts as a decision.
    final fallback = row.fallback.trim();
    if (fallback.isEmpty) {
      violations.add('fallback_blank:$providerId');
      coherent = false;
    } else if (!Sprint117ExposureContract.failClosedFallbacks.contains(
      fallback,
    )) {
      violations.add('fallback_not_fail_closed:$providerId:$fallback');
      coherent = false;
    }

    return (decided: decided, coherent: coherent);
  }

  /// Whether the shipped registry can resolve the beta connector flags at all.
  /// The registry rejects unknown names by throwing, so this is a real
  /// capability question and it is asked of the shipped code, not assumed.
  static bool _shippedRegistryKnowsBetaFlags() {
    const betaPrefix = 'connector.';
    for (final flag in kVs12FeatureFlags) {
      if (flag.startsWith(betaPrefix)) return true;
    }
    return false;
  }

  static bool _sameSet(List<String> left, List<String> right) {
    if (left.length != right.length) return false;
    final sortedLeft = List<String>.from(left)..sort();
    final sortedRight = List<String>.from(right)..sort();
    for (var index = 0; index < sortedLeft.length; index++) {
      if (sortedLeft[index] != sortedRight[index]) return false;
    }
    return true;
  }
}
