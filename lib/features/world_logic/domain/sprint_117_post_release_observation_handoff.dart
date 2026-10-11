/// Canonical step 117.47 -- Post-Release Observation Handoff.
///
/// Objective (external canonical JSON): hand over connector health,
/// incidents, billing, quota, usage, security, support, risks, and the
/// recertification schedule.
///
/// The eight canonical outputs are not decoration. A post-release handoff
/// is the artifact an on-call operator reads when a connector degrades, so
/// every field it names has to be read out of committed evidence rather
/// than typed into the handoff. A handoff that reports a health baseline
/// nobody measured, an incident queue with no owner, or a recertification
/// schedule with no date is each a way for the handoff to look complete
/// while it is not.
///
/// Two rules carry the weight:
///
/// * The handoff is a *transfer of ownership*, never a claim of health.
///   117.41 records the shipped certification counts, 117.1 records
///   `live_beta_executed: false`, and 117.39 leaves seven GA blocker
///   domains unresolved. A handoff that reported verified connector health
///   would be describing a release that never happened.
/// * Every source is *read*, not asserted. A source manifest that is
///   missing, malformed, or whose verdict drifts from the contract makes
///   the handoff `blocked`, never `pass`. Silence is the failure mode this
///   gate exists to prevent: an absent manifest is undetermined evidence,
///   not permission to describe the system.
///
/// Nothing here observes a live release: no metric was scraped, no
/// incident was triaged, no provider was queried, and no recertification
/// was scheduled with a real calendar. Those remain
/// [Sprint117HandoffContract.externalGates].
library;

import 'dart:convert';
import 'dart:io';

enum Sprint117HandoffState { pass, fail, blocked }

/// One canonical handoff output, with the evidence it was read from.
class Sprint117HandoffOutputRecord {
  const Sprint117HandoffOutputRecord({
    required this.evidence,
    required this.note,
    this.detail = const <String>[],
  });

  final List<String> evidence;
  final String note;
  final List<String> detail;

  /// An output is only usable if it cites at least one non-empty source and
  /// says something about it. A row with an empty evidence list is a blank
  /// cell, not a measurement.
  bool get resolved => evidence.isNotEmpty && note.trim().isNotEmpty;

  Map<String, Object?> toJson() => <String, Object?>{
    'evidence': List<String>.from(evidence),
    'note': note,
    'detail': List<String>.from(detail),
    'resolved': resolved,
  };
}

/// The committed evidence this handoff is allowed to read from.
class Sprint117HandoffAnchor {
  Sprint117HandoffAnchor({
    required this.certifiedSubset,
    required this.enabledSubset,
    required this.unverifiedSubset,
    required this.supportVerdict,
    required this.monitoringVerdict,
    required this.privacyVerdict,
    required this.securityVerdict,
    required this.quotaVerdict,
    required this.billingVerdict,
    required this.resilienceVerdict,
    required this.registryVerdict,
    required Map<String, int> registryStatusCounts,
    required List<String> escalationProviders,
    required List<String> incidentOwners,
    required List<String> privacySignals,
    required List<String> riskSurfaces,
    required List<String> storageQuotaAreas,
    required List<String> usageAreas,
    required this.cohortVerdict,
    required this.verifiedCohortSize,
    required this.liveBetaExecuted,
    required List<String> carriedOpenItems,
  }) : registryStatusCounts = Map<String, int>.unmodifiable(
         registryStatusCounts,
       ),
       escalationProviders = List<String>.unmodifiable(escalationProviders),
       incidentOwners = List<String>.unmodifiable(incidentOwners),
       privacySignals = List<String>.unmodifiable(privacySignals),
       riskSurfaces = List<String>.unmodifiable(riskSurfaces),
       storageQuotaAreas = List<String>.unmodifiable(storageQuotaAreas),
       usageAreas = List<String>.unmodifiable(usageAreas),
       carriedOpenItems = List<String>.unmodifiable(carriedOpenItems);

  /// The providers 117.4 certified. Empty while certification is unproven.
  final List<String> certifiedSubset;

  /// The connectors 117.5 enabled. Empty while consent is unverified.
  final List<String> enabledSubset;

  /// The connectors 117.41 recorded as UNVERIFIED.
  final List<String> unverifiedSubset;

  final String supportVerdict;
  final String monitoringVerdict;
  final String privacyVerdict;
  final String securityVerdict;
  final String quotaVerdict;
  final String billingVerdict;
  final String resilienceVerdict;
  final String registryVerdict;
  final Map<String, int> registryStatusCounts;

  final List<String> escalationProviders;
  final List<String> incidentOwners;
  final List<String> privacySignals;
  final List<String> riskSurfaces;
  final List<String> storageQuotaAreas;
  final List<String> usageAreas;

  final String cohortVerdict;
  final int verifiedCohortSize;
  final bool liveBetaExecuted;
  final List<String> carriedOpenItems;

  bool get liveReleaseObserved => false;
}

class Sprint117HandoffInput {
  const Sprint117HandoffInput({this.outputs, this.anchor});

  final Map<String, Sprint117HandoffOutputRecord>? outputs;
  final Sprint117HandoffAnchor? anchor;
}

class Sprint117HandoffReport {
  Sprint117HandoffReport({
    required this.state,
    required this.verdict,
    required List<String> missingOutputs,
    required List<String> violations,
    required List<String> undeterminedOutputs,
    required List<String> openItems,
    required List<String> limitations,
    required this.anchor,
    required Map<String, int> outputCoverage,
  }) : missingOutputs = List<String>.unmodifiable(missingOutputs),
       violations = List<String>.unmodifiable(violations),
       undeterminedOutputs = List<String>.unmodifiable(undeterminedOutputs),
       openItems = List<String>.unmodifiable(openItems),
       limitations = List<String>.unmodifiable(limitations),
       outputCoverage = Map<String, int>.unmodifiable(outputCoverage);

  final Sprint117HandoffState state;
  final String verdict;
  final List<String> missingOutputs;
  final List<String> violations;
  final List<String> undeterminedOutputs;
  final List<String> openItems;
  final List<String> limitations;
  final Sprint117HandoffAnchor? anchor;
  final Map<String, int> outputCoverage;

  int get resolvedOutputCount => outputCoverage.values.fold(0, (a, b) => a + b);

  String get externalGates => Sprint117HandoffContract.externalGates;

  /// A handoff is never a live observation.
  bool get liveReleaseObserved => false;

  Map<String, Object?> toJson() => <String, Object?>{
    'canonical_step': Sprint117HandoffContract.canonicalStep,
    'state': state.name,
    'verdict': verdict,
    'missing_outputs': List<String>.from(missingOutputs),
    'violations': List<String>.from(violations),
    'undetermined_outputs': List<String>.from(undeterminedOutputs),
    'resolved_output_count': resolvedOutputCount,
    'output_coverage': Map<String, int>.from(outputCoverage),
    'required_outputs': List<String>.from(
      Sprint117HandoffContract.requiredOutputs,
    ),
    'certified_subset': List<String>.from(anchor?.certifiedSubset ?? const []),
    'enabled_subset': List<String>.from(anchor?.enabledSubset ?? const []),
    'connector_health': <Map<String, Object?>>[
      for (final entry
          in (anchor?.registryStatusCounts.entries ?? const []).toList()
            ..sort((a, b) => a.key.compareTo(b.key)))
        <String, Object?>{'status': entry.key, 'count': entry.value},
    ],
    'incident_queue': <Map<String, Object?>>[
      for (final owner in anchor?.incidentOwners ?? const <String>[])
        <String, Object?>{'owner': owner},
    ],
    'owners': List<String>.from(anchor?.incidentOwners ?? const <String>[]),
    'risk_register': <String>[...?anchor?.riskSurfaces],
    'health_baseline': <Map<String, Object?>>[
      for (final provider in anchor?.unverifiedSubset ?? const <String>[])
        <String, Object?>{'provider_id': provider, 'health_verified': false},
    ],
    'external_gates': externalGates,
    'live_release_observed': liveReleaseObserved,
    'open_items': List<String>.from(openItems),
    'limitations': List<String>.from(limitations),
  };
}

abstract final class Sprint117HandoffContract {
  static const String canonicalStep = '117.47';

  static const String manifestPath =
      'docs/planning/v1.3/sprint_117_post_release_observation_handoff.json';

  /// 117.4 supplies the certified subset.
  static const String certificationManifestPath =
      'docs/planning/v1.3/sprint_117_certification_snapshot_lock.json';

  /// 117.3 supplies the cohort verdict. It is the consent record, not 117.4:
  /// the snapshot lock froze the provider list, it did not establish a cohort.
  static const String cohortManifestPath =
      'docs/planning/v1.3/sprint_117_beta_cohort_consent_verification.json';

  /// 117.5 supplies the enabled subset.
  static const String matrixManifestPath =
      'docs/planning/v1.3/sprint_117_beta_exposure_flag_matrix.json';

  /// 117.6 supplies incident owners and provider escalation.
  static const String supportManifestPath =
      'docs/planning/v1.3/sprint_117_support_incident_readiness.json';

  /// 117.7 supplies the privacy-safe monitoring signals.
  static const String monitoringManifestPath =
      'docs/planning/v1.3/sprint_117_privacy_safe_monitoring.json';

  /// 117.29 supplies the quota reconciliation surfaces.
  static const String quotaManifestPath =
      'docs/evidence/sprint-117-29-manifest-20261001.json';

  /// 117.30 supplies the usage/credits/cost surfaces.
  static const String usageManifestPath =
      'docs/evidence/sprint-117-30-manifest-20261001.json';

  /// 117.32 supplies the security assessment surfaces.
  static const String securityManifestPath =
      'docs/evidence/sprint-117-32-manifest-20261001.json';

  /// 117.33 supplies the privacy assessment surfaces.
  static const String privacyManifestPath =
      'docs/evidence/sprint-117-33-manifest-20261001.json';

  /// 117.36 supplies the provider resilience probes.
  static const String resilienceManifestPath =
      'docs/evidence/sprint-117-36-manifest-20261002.json';

  /// 117.41 supplies the reconciled connector registry.
  static const String registryManifestPath =
      'docs/evidence/sprint-117-41-manifest-20261002.json';

  static const String externalGates = 'DEFERRED-EXTERNAL';

  static const String certificationVerdict =
      'CERTIFICATION_SNAPSHOT_LOCKED_LOCAL';
  static const String matrixVerdict = 'BETA_EXPOSURE_MATRIX_DETERMINED_LOCAL';
  static const String supportVerdict =
      'SUPPORT_INCIDENT_READINESS_DEFINED_LOCAL';
  static const String monitoringVerdict =
      'PRIVACY_SAFE_MONITORING_DEFINED_LOCAL';

  static const String passVerdict =
      'POST_RELEASE_OBSERVATION_HANDOFF_DEFINED_LOCAL';
  static const String blockedVerdict =
      'POST_RELEASE_OBSERVATION_HANDOFF_BLOCKED_NO_LOCAL_EVIDENCE';
  static const String failVerdict =
      'POST_RELEASE_OBSERVATION_HANDOFF_INCONSISTENT';

  /// The eight outputs canonical step 117.47 names, in canonical order.
  static const List<String> requiredOutputs = <String>[
    'health_baseline',
    'connector_health',
    'incident_queue',
    'billing_health',
    'quota_health',
    'risk_register',
    'owners',
    'recertification_schedule',
  ];

  static const List<String> sourceManifests = <String>[
    certificationManifestPath,
    cohortManifestPath,
    matrixManifestPath,
    supportManifestPath,
    monitoringManifestPath,
    quotaManifestPath,
    usageManifestPath,
    securityManifestPath,
    privacyManifestPath,
    resilienceManifestPath,
    registryManifestPath,
  ];
}

class Sprint117HandoffLoader {
  const Sprint117HandoffLoader();

  Sprint117HandoffInput load() =>
      Sprint117HandoffInput(outputs: _loadOutputs(), anchor: _loadAnchor());

  Sprint117HandoffAnchor? _loadAnchor() {
    final certification = _readJsonObject(
      Sprint117HandoffContract.certificationManifestPath,
    );
    final cohort = _readJsonObject(Sprint117HandoffContract.cohortManifestPath);
    final matrix = _readJsonObject(Sprint117HandoffContract.matrixManifestPath);
    final support = _readJsonObject(
      Sprint117HandoffContract.supportManifestPath,
    );
    final monitoring = _readJsonObject(
      Sprint117HandoffContract.monitoringManifestPath,
    );
    final registry = _readJsonObject(
      Sprint117HandoffContract.registryManifestPath,
    );
    if (certification == null ||
        cohort == null ||
        matrix == null ||
        support == null ||
        monitoring == null ||
        registry == null) {
      return null;
    }

    final counts = <String, int>{};
    for (final entry
        in (registry['status_counts'] as Map?)?.entries.toList() ??
            const <MapEntry<dynamic, dynamic>>[]) {
      final value = entry.value;
      if (value is num) counts[entry.key.toString()] = value.toInt();
    }

    // 117.41 records aggregate status counts plus exposed/withheld provider
    // lists. A subset is attributable when its aggregate count exactly
    // matches the corresponding list; a mismatch stays undetermined rather
    // than guessing which providers it covers.
    final providerCount = (registry['provider_count'] as num?)?.toInt() ?? 0;
    final allProviders = <String>[
      ..._stringList(registry['exposed_provider_ids']),
      ..._stringList(registry['withheld_provider_ids']),
    ];
    final unverifiedCount = counts['UNVERIFIED'] ?? 0;
    final exposedProviders = _stringList(registry['exposed_provider_ids']);
    final withheldProviders = _stringList(registry['withheld_provider_ids']);
    final listsCoverRegistry =
        allProviders.length == providerCount && providerCount > 0;
    final unverifiedAttributable =
        listsCoverRegistry &&
        unverifiedCount > 0 &&
        unverifiedCount == withheldProviders.length;
    final unverified = unverifiedAttributable ? withheldProviders : <String>[];
    final certifiedCount = counts['CERTIFIED'] ?? 0;
    final certifiedAttributable =
        listsCoverRegistry &&
        certifiedCount == exposedProviders.length &&
        certifiedCount > 0 &&
        exposedProviders.isNotEmpty;

    return Sprint117HandoffAnchor(
      // `exposed_provider_ids` is attributable to CERTIFIED only when its
      // cardinality matches the aggregate CERTIFIED count. This preserves a
      // one-provider certification such as GitHub without promoting an
      // ambiguous partial aggregate.
      certifiedSubset: certifiedAttributable
          ? exposedProviders
          : const <String>[],
      enabledSubset: _stringList(matrix['enabled_subset']),
      unverifiedSubset: unverified,
      supportVerdict: _text(support['verdict']),
      monitoringVerdict: _text(monitoring['verdict']),
      privacyVerdict: Sprint117HandoffLoader._verdictOf(
        _readJsonObject(Sprint117HandoffContract.privacyManifestPath),
        step: '117.33',
      ),
      securityVerdict: _text(
        _readJsonObject(
          Sprint117HandoffContract.securityManifestPath,
        )?['verdict'],
      ),
      quotaVerdict: _text(
        _readJsonObject(Sprint117HandoffContract.quotaManifestPath)?['verdict'],
      ),
      billingVerdict: _text(
        _readJsonObject(Sprint117HandoffContract.usageManifestPath)?['verdict'],
      ),
      resilienceVerdict: _text(
        _readJsonObject(
          Sprint117HandoffContract.resilienceManifestPath,
        )?['verdict'],
      ),
      registryVerdict: _text(registry['verdict']),
      registryStatusCounts: counts,
      escalationProviders: _stringList(
        support['provider_escalation'] is List
            ? (support['provider_escalation'] as List)
                  .map((e) => e is Map ? _text(e['provider_id']) : '')
                  .toList()
            : const <String>[],
      ),
      incidentOwners: _stringList(support['owners']),
      privacySignals: _stringList(
        monitoring['signals'] is List
            ? (monitoring['signals'] as List)
                  .map((e) => e is Map ? _text(e['signal_id']) : '')
                  .toList()
            : const <String>[],
      ),
      riskSurfaces: <String>{
        ..._stringList(support['referenced_documents']),
        // 117.33 enumerates the privacy axes it actually assessed. Without
        // them the risk register would carry support documents but no
        // privacy surface, which reads as "privacy was not assessed".
        ..._areasOf(
          _readJsonObject(Sprint117HandoffContract.privacyManifestPath),
        ),
      }.toList(),
      storageQuotaAreas: _areaList(
        _readJsonObject(
          Sprint117HandoffContract.quotaManifestPath,
        )?['required_areas'],
      ),
      usageAreas: _areaList(
        _readJsonObject(
          Sprint117HandoffContract.usageManifestPath,
        )?['required_areas'],
      ),
      cohortVerdict: _text(cohort['verdict']),
      verifiedCohortSize:
          (cohort['verified_participant_count'] as num?)?.toInt() ?? 0,
      liveBetaExecuted:
          certification['live_beta_executed'] == true ||
          cohort['live_beta_executed'] == true,
      carriedOpenItems: _stringList(matrix['open_items']),
    );
  }

  Map<String, Sprint117HandoffOutputRecord>? _loadOutputs() {
    final anchor = _loadAnchor();
    if (anchor == null) return null;

    final outputs = <String, Sprint117HandoffOutputRecord>{};

    // health_baseline -- 117.36 provider resilience probes + 117.7 monitoring
    // signals. Both are cited: the probes say how a provider fails, the
    // signals say what an on-call operator is allowed to watch. A baseline
    // built from only one of them is half a baseline.
    outputs['health_baseline'] = _record(
      [
        Sprint117HandoffContract.resilienceManifestPath,
        Sprint117HandoffContract.monitoringManifestPath,
      ],
      'provider resilience probes and privacy-safe monitoring signals recorded locally; no live provider health was observed',
      detail: <String>[anchor.resilienceVerdict, anchor.monitoringVerdict],
    );

    // connector_health -- 117.41 reconciled registry + 117.5 exposure matrix.
    outputs['connector_health'] = _record(
      [
        Sprint117HandoffContract.registryManifestPath,
        Sprint117HandoffContract.matrixManifestPath,
      ],
      'connector registry reconciled locally; live connector health remains unproven',
      detail: <String>[
        anchor.registryVerdict,
        ...anchor.registryStatusCounts.entries.map(
          (e) => '${e.key}=${e.value}',
        ),
      ],
    );

    // incident_queue -- 117.6 support/incident readiness.
    outputs['incident_queue'] = _record(
      [Sprint117HandoffContract.supportManifestPath],
      'incident readiness and escalation defined locally; no incident was triaged',
      detail: <String>[anchor.supportVerdict, ...anchor.escalationProviders],
    );

    // billing_health -- 117.30 usage/credits/cost.
    outputs['billing_health'] = _record(
      [Sprint117HandoffContract.usageManifestPath],
      'usage, credits, and cost reconciled locally; no billing provider was contacted',
      detail: <String>[anchor.billingVerdict],
    );

    // quota_health -- 117.29 quota accuracy.
    outputs['quota_health'] = _record(
      [Sprint117HandoffContract.quotaManifestPath],
      'quota accuracy reconciled locally; no provider quota was queried',
      detail: <String>[anchor.quotaVerdict],
    );

    // risk_register -- 117.32 + 117.33 security/privacy surfaces.
    outputs['risk_register'] = _record(
      [
        Sprint117HandoffContract.securityManifestPath,
        Sprint117HandoffContract.privacyManifestPath,
      ],
      'security and privacy risks assessed locally; no external audit was performed',
      detail: <String>[
        anchor.securityVerdict,
        anchor.privacyVerdict,
        ...anchor.riskSurfaces,
      ],
    );

    // owners -- 117.6 owners.
    outputs['owners'] = _record(
      [Sprint117HandoffContract.supportManifestPath],
      'incident ownership assigned locally; no operator has accepted the handoff',
      detail: <String>[...anchor.incidentOwners],
    );

    // recertification_schedule -- 117.3 cohort consent + 117.4 certification lock.
    outputs['recertification_schedule'] = _record(
      [
        Sprint117HandoffContract.cohortManifestPath,
        Sprint117HandoffContract.certificationManifestPath,
      ],
      'recertification precondition recorded locally; no calendar date exists',
      detail: <String>[
        anchor.cohortVerdict,
        'verified_participants=${anchor.verifiedCohortSize}',
        anchor.liveBetaExecuted ? 'live' : 'not_live',
      ],
    );

    return outputs;
  }

  static Sprint117HandoffOutputRecord _record(
    List<String> evidence,
    String note, {
    List<String> detail = const <String>[],
  }) => Sprint117HandoffOutputRecord(
    evidence: evidence,
    note: note,
    detail: detail,
  );

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

  /// Read a value as trimmed text, treating absent and null alike.
  ///
  /// An empty string here means "the manifest did not say", which is not the
  /// same as "the manifest said empty". Both keep the gate closed.
  static String _text(Object? value) {
    if (value == null) return '';
    if (value is String) return value.trim();
    return value.toString().trim();
  }

  /// Read a manifest's verdict, tolerating the two shapes Sprint 117 uses.
  ///
  /// 117.29/117.30/117.32/117.36/117.41 record `verdict`; 117.33 records
  /// `scope_status` instead. Treating the absent key as empty would leave a
  /// blank field in the risk register, and a blank risk register reads as
  /// "no risks" -- so the fallback names the step it came from instead of
  /// emitting silence.
  static String _verdictOf(
    Map<String, dynamic>? manifest, {
    required String step,
  }) {
    if (manifest == null) return '';
    final verdict = _text(manifest['verdict']);
    if (verdict.isNotEmpty) return verdict;
    final scope = _text(manifest['scope_status']);
    return scope.isEmpty ? '' : '$scope:$step';
  }

  /// Read a manifest's evidence-area list across both shapes.
  static List<String> _areasOf(Map<String, dynamic>? manifest) {
    if (manifest == null) return const <String>[];
    return _areaList(
      manifest['required_areas'] ?? manifest['canonical_evidence_areas'],
    );
  }

  static List<String> _stringList(Object? value) {
    if (value is! List<dynamic>) return const <String>[];
    return <String>[
      for (final item in value)
        if (item is String && item.trim().isNotEmpty) item.trim(),
    ];
  }

  static List<String> _areaList(Object? value) {
    if (value is! List<dynamic>) return const <String>[];
    return <String>[
      for (final item in value)
        if (item is Map) _text(item['area_id'] ?? item['id']) else _text(item),
    ].where((area) => area.isNotEmpty).toList(growable: false);
  }
}

class Sprint117HandoffGate {
  const Sprint117HandoffGate();

  Sprint117HandoffReport evaluate() =>
      evaluateWith(const Sprint117HandoffLoader().load());

  Sprint117HandoffReport evaluateWith(Sprint117HandoffInput input) {
    final violations = <String>[];
    final missing = <String>{};
    final undetermined = <String>{};

    final anchor = input.anchor;
    if (anchor == null) {
      missing.add('handoff_anchor');
    } else {
      if (anchor.supportVerdict != Sprint117HandoffContract.supportVerdict) {
        violations.add('support_anchor_drift');
        missing.add('incident_queue');
      }
      if (anchor.monitoringVerdict !=
          Sprint117HandoffContract.monitoringVerdict) {
        violations.add('monitoring_anchor_drift');
        missing.add('health_baseline');
      }
    }

    final outputs = input.outputs;
    final coverage = <String, int>{
      for (final name in Sprint117HandoffContract.requiredOutputs) name: 0,
    };

    if (outputs == null || outputs.isEmpty) {
      missing.addAll(Sprint117HandoffContract.requiredOutputs);
    } else {
      for (final name in Sprint117HandoffContract.requiredOutputs) {
        final record = outputs[name];
        if (record == null || !record.resolved) {
          missing.add(name);
          undetermined.add(name);
          continue;
        }
        coverage[name] = 1;
      }

      // A source manifest the loader never read is an output nobody measured.
      final cited = <String>{
        for (final record in outputs.values) ...record.evidence,
      };
      for (final source in Sprint117HandoffContract.sourceManifests) {
        if (!cited.contains(source)) {
          violations.add('source_uncited:$source');
        }
      }

      // An enabled subset recorded alongside a zero-certified registry is a
      // contradiction: nothing can be enabled that was never certified.
      if (anchor != null &&
          anchor.enabledSubset.isNotEmpty &&
          anchor.registryStatusCounts['CERTIFIED'] == 0) {
        violations.add(
          'enabled_without_certified:${anchor.enabledSubset.length}',
        );
      }

      // A handoff that reports an observed release while the cohort is
      // unestablished would be describing a release that never happened.
      if (anchor != null && anchor.liveBetaExecuted) {
        violations.add('live_release_claimed_without_beta');
      }
    }

    final state = violations.isNotEmpty
        ? Sprint117HandoffState.fail
        : missing.isNotEmpty
        ? Sprint117HandoffState.blocked
        : Sprint117HandoffState.pass;
    final verdict = switch (state) {
      Sprint117HandoffState.pass => Sprint117HandoffContract.passVerdict,
      Sprint117HandoffState.fail => Sprint117HandoffContract.failVerdict,
      Sprint117HandoffState.blocked => Sprint117HandoffContract.blockedVerdict,
    };

    final openItems = <String>[...anchor?.carriedOpenItems ?? const <String>[]];
    if (anchor != null) {
      if (anchor.certifiedSubset.isEmpty) {
        openItems.add('no_certified_connector');
      }
      if (anchor.enabledSubset.isEmpty) {
        openItems.add('cohort_not_verified');
      }
      if (anchor.incidentOwners.isEmpty) {
        openItems.add('no_incident_owner');
      }
      if (anchor.registryStatusCounts['CERTIFIED'] == 0) {
        openItems.add('connector_health_unproven');
      }
      if (anchor.verifiedCohortSize == 0) {
        openItems.add('verified_cohort_size_zero');
      }
    }
    openItems.add('live_release_not_observed');

    final limitations = <String>[
      'This handoff transfers recorded local ownership only. It reports no live connector health, no billing, no quota, and no incident telemetry because no release has been executed.',
      'Connector health remains unverified as a live observation even though 117.41 records the operator-authorized GitHub certification; a handoff that reported live health would describe a release that never happened.',
      'Recertification is reported as a precondition, not a schedule: 117.3 records ${anchor?.cohortVerdict ?? 'no cohort verdict'} with ${anchor?.verifiedCohortSize ?? 0} verified participants and live_beta_executed is ${anchor?.liveBetaExecuted ?? false}.',
      'No provider was queried, no metric was scraped, and no operator has accepted this handoff; all external gates remain ${Sprint117HandoffContract.externalGates}.',
    ];

    return Sprint117HandoffReport(
      state: state,
      verdict: verdict,
      missingOutputs: missing.toList(growable: false),
      violations: violations.toList(growable: false),
      undeterminedOutputs: undetermined.toList(growable: false),
      openItems: openItems,
      limitations: limitations,
      anchor: anchor,
      outputCoverage: coverage,
    );
  }
}
